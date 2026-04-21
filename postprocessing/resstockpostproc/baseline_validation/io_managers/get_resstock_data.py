import functools
from collections.abc import Sequence
import numpy as np

import pandas as pd
import polars as pl

import sqlalchemy as sa
from buildstock_query import BuildStockQuery, MappedColumn

from resstockpostproc.baseline_validation.io_managers.utils import apply_aggregation
from resstockpostproc.baseline_validation.io_managers.stats import ANNUAL_QUANTILES, weighted_quantiles
from resstockpostproc.baseline_validation.resstock_raw import (
    resolve_existing_char_column,
    resstock_group_expr,
    resstock_quantity_expr,
)
from .utils import add_missing_states
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow, DataSourceConfig
from resstockpostproc.baseline_validation.schema.plot_spec import Resolution, DataKey
from resstockpostproc.baseline_validation.schema.recs_chars_mapping import RECS_CHARS_MAPPING
from resstockpostproc.shared_utils.db_column_names import get_db_enduse_colnames_map, get_db_characteristics_colnames
from resstockpostproc.baseline_validation.schema.workflow_schema import DBSchema
from resstockpostproc.baseline_validation.utils import get_buildstock_query
from resstockpostproc.shared_utils.mapping import NUM2MONTH
from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.shared_utils.caching import cached
from resstockpostproc.shared_utils.timing import timed
from resstockpostproc.shared_utils.mapping import UtilityName2ID


@timed
@cached(cache_file="resstock_timeseries_data_cache")
def get_timeseries_all(
    data_key: DataKey,
    restrict_list: Sequence[str] | None = None,
    occupied_only: bool = False,
) -> pl.DataFrame | None:
    """Get timeseries data for all configured data sources.

    Args:
        data_key: DataKey containing effective_group_by, resolution, aggregation_type, and coverage
        restrict_list: Optional list of entity IDs to restrict to (e.g., eiaid list)
        occupied_only: If True, only include occupied units (for RECS comparison)

    """
    if not workflow.data_sources:
        return None

    by = data_key.effective_group_by[0]  # timeseries only supports single-column groupby
    resolution = data_key.resolution

    all_dfs = []
    for data_source in workflow.data_sources:
        df = get_timeseries(
            data_source=data_source,
            by=by,
            restrict_list=restrict_list,
            occupied_only=occupied_only,
            resolution=resolution,
        )
        annual_df = get_annual(data_source, by, occupied_only=occupied_only)
        value_cols = [col for col in df.columns if col.endswith("_value")]
        percent_users_cols = [col.replace("_value", "_percent_users") for col in value_cols]
        percent_users_cols = [col for col in percent_users_cols if col in annual_df.columns]
        nonzero_sample_cols = [col.replace("_value", "_nonzero_sample_count") for col in value_cols]
        nonzero_sample_cols = [col for col in nonzero_sample_cols if col in annual_df.columns]
        df = df.join(
            annual_df.select([by] + percent_users_cols + nonzero_sample_cols),
            on=[by], how="left", maintain_order="left_right",
        )
        df = apply_aggregation(data_key, df)
        df = df.with_columns(pl.lit(data_source.name).alias("source"))
        all_dfs.append(df)
    final_df = pl.concat(all_dfs, how="diagonal")
    return final_df


_HOUR_OF_DAY_SEASON_MONTHS = {
    Resolution.hour_of_day_summer: (6, 7, 8),
    Resolution.hour_of_day_winter: (12, 1, 2),
}


def _reshape_monthly(result: pl.DataFrame, by: str, ts_col: str) -> pl.DataFrame:
    data = result.with_columns(pl.col(ts_col).dt.month().alias("month")).sort(by=[by, "month"])
    return data.with_columns(pl.col("month").replace_strict(NUM2MONTH, default=None))


def _reshape_daily(result: pl.DataFrame, by: str, ts_col: str) -> pl.DataFrame:
    return result.with_columns(pl.col(ts_col).dt.truncate("1d").alias("day of year")).sort(by=[by, "day of year"])


def _reshape_hourly(result: pl.DataFrame, by: str, ts_col: str, resolution: Resolution) -> pl.DataFrame:
    hour_index = (pl.col(ts_col).dt.ordinal_day() - 1) * 24 + pl.col(ts_col).dt.hour()
    return result.with_columns(hour_index.alias(resolution)).sort(by=[by, resolution])


def _reshape_hour_of_day(result: pl.DataFrame, by: str, ts_col: str) -> pl.DataFrame:
    value_cols = [col for col in result.columns if col not in {by, ts_col}]
    return (
        result.with_columns(pl.col(ts_col).dt.hour().alias(Resolution.hour_of_day))
        .group_by([by, Resolution.hour_of_day], maintain_order=True)
        .agg(pl.col(c).mean().alias(c) for c in value_cols)
        .sort(by=[by, Resolution.hour_of_day])
    )


def _reshape_hour_of_day_season(
    result: pl.DataFrame, by: str, ts_col: str, resolution: Resolution
) -> pl.DataFrame:
    months = _HOUR_OF_DAY_SEASON_MONTHS[resolution]
    value_cols = [col for col in result.columns if col not in {by, ts_col, "month"}]
    return (
        result.with_columns(
            pl.col(ts_col).dt.hour().alias(resolution),
            pl.col(ts_col).dt.month().alias("month"),
        )
        .filter(pl.col("month").is_in(list(months)))
        .group_by([by, resolution], maintain_order=True)
        .agg(pl.col(c).mean().alias(c) for c in value_cols)
        .sort(by=[by, resolution])
    )


def _reshape_hour_of_day_matrix(result: pl.DataFrame, by: str, ts_col: str) -> pl.DataFrame:
    with_keys = result.with_columns(
        pl.col(ts_col).dt.hour().alias("hour of day"),
        pl.col(ts_col).dt.month().replace_strict(NUM2MONTH, default=None).alias("month"),
        pl.when(pl.col(ts_col).dt.weekday() < 5)
        .then(pl.lit("Weekday"))
        .otherwise(pl.lit("Weekend"))
        .alias("day_type"),
    )
    value_cols = [col for col in result.columns if col not in {by, ts_col}]

    def _mean_agg(keys: list[str], month_override: str | None = None, day_override: str | None = None):
        df = with_keys.group_by(keys, maintain_order=True).agg(pl.col(c).mean().alias(c) for c in value_cols)
        overrides = []
        if month_override is not None:
            overrides.append(pl.lit(month_override).alias("month"))
        if day_override is not None:
            overrides.append(pl.lit(day_override).alias("day_type"))
        return df.with_columns(overrides) if overrides else df

    frames = [
        _mean_agg([by, "month", "day_type", "hour of day"]),
        _mean_agg([by, "month", "hour of day"], day_override="All Days"),
        _mean_agg([by, "day_type", "hour of day"], month_override="All Year"),
        _mean_agg([by, "hour of day"], month_override="All Year", day_override="All Days"),
    ]
    return pl.concat(frames, how="diagonal_relaxed").sort(by=[by, "month", "day_type", "hour of day"])


def _reshape_timeseries(result: pl.DataFrame, by: str, ts_col: str, resolution: Resolution) -> pl.DataFrame:
    if resolution == Resolution.month:
        return _reshape_monthly(result, by, ts_col)
    if resolution == Resolution.day_of_year:
        return _reshape_daily(result, by, ts_col)
    if resolution in {Resolution.hour_of_year, Resolution.top_100_hours}:
        return _reshape_hourly(result, by, ts_col, resolution)
    if resolution in _HOUR_OF_DAY_SEASON_MONTHS:
        return _reshape_hour_of_day_season(result, by, ts_col, resolution)
    if resolution == Resolution.hour_of_day_matrix:
        return _reshape_hour_of_day_matrix(result, by, ts_col)
    assert resolution == Resolution.hour_of_day, f"Unsupported resolution: {resolution}"
    return _reshape_hour_of_day(result, by, ts_col)


@timed
def get_timeseries(
    data_source: DataSourceConfig,
    resolution: Resolution = Resolution.month,
    by: str = "state",
    restrict_list: Sequence[str] | None = None,
    occupied_only: bool = False,
) -> pl.DataFrame:
    """Fetch and reshape timeseries data from BuildStockQuery."""
    bsq = get_buildstock_query(
        workgroup=workflow.workgroup,
        config=data_source,
        skip_reports=True,
    )
    ts_col = get_db_characteristics_colnames(data_source.db_schema).TIMESTAMP

    if by == "eiaid":
        assert not occupied_only, "occupied_only is not supported when by='eiaid'"
        assert restrict_list, "restrict_list must be provided when by='eiaid'"
        result = _get_timeseries_by_utilities(bsq, data_source, restrict_list, resolution)
    else:
        result = _get_timeseries_by_char(
            bsq, data_source, by, restrict_list, occupied_only=occupied_only, resolution=resolution
        )

    result = _transform_columns(result, data_source.db_schema)
    ts_data = _reshape_timeseries(result, by, ts_col, resolution)
    if by == "state":
        ts_data = add_missing_states(ts_data)
    return ts_data


@timed
def _get_timeseries_by_char(
    bsq: BuildStockQuery,
    data_source: DataSourceConfig,
    by: str,
    restrict_list: Sequence[str] | None = None,
    occupied_only: bool = False,
    resolution: str = "month",
):
    db_char_col = get_db_characteristics_colnames(data_source.db_schema)
    enduses = _get_db_enduses(bsq, data_source.db_schema, table="timeseries")
    restrict = [(db_char_col.VACANCY, ["Occupied"])] if occupied_only else []
    if restrict_list:
        restrict += [(db_char_col.STATE, restrict_list)]
    result_df = bsq.query(
        enduses=tuple(enduses),
        group_by=["time", by],
        restrict=restrict,
        annual_only=False,
        timestamp_grouping_func=resolution,
    )
    bsq.save_cache()
    if by == "state":
        result_us_total = bsq.query(
            enduses=tuple(enduses),
            group_by=["time"],
            restrict=restrict,
            annual_only=False,
            timestamp_grouping_func=resolution,
        )
        bsq.save_cache()
        result_us_total["state"] = "US Total"
        result_us_total = result_us_total[result_df.columns]
        result_df = pd.concat([result_df, result_us_total], ignore_index=True)
    result = pl.from_pandas(result_df)
    return result


@timed
def _get_timeseries_by_utilities(
    bsq: BuildStockQuery,
    data_source: DataSourceConfig,
    eiaid_list: Sequence[str],
    resolution: Resolution = Resolution.month,
):
    db_char_col = get_db_characteristics_colnames(data_source.db_schema)
    enduses = _get_db_enduses(bsq, data_source.db_schema, table="timeseries")
    timestamp_grouping_func = _get_timestamp_grouping_func(resolution)
    ercot_pd = bsq.query(
        enduses=enduses,
        restrict=[(db_char_col.STATE, ["TX"]), (db_char_col.ISO_RTO_REGION, ["ERCOT"])],
        annual_only=False,
        timestamp_grouping_func=timestamp_grouping_func,
    )
    bsq.save_cache()
    # .with_columns(pl.lit(str(UtilityName2ID["ERCOT"])).alias("eiaid"))
    ercot_pd["eiaid"] = str(UtilityName2ID["ERCOT"])

    relevant_counties = bsq.utility.get_locations_by_eiaids(eiaid_list)
    restrict = [(db_char_col.COUNTY, relevant_counties)]
    result_pd = bsq.utility.aggregate_ts_by_eiaid(
        enduses=enduses,
        eiaid_list=eiaid_list,
        restrict=restrict,
        timestamp_grouping_func=timestamp_grouping_func,
    )
    bsq.save_cache()

    result = pl.concat([pl.from_pandas(result_pd), pl.from_pandas(ercot_pd)], how="diagonal_relaxed")
    if "query_id" in result.columns:
        result = result.drop("query_id")
    if "eiaid" in result.columns:
        result = result.with_columns(pl.col("eiaid").cast(pl.Int64))
    return result


def _get_timestamp_grouping_func(resolution: Resolution):
    match resolution:
        case (
            Resolution.hour_of_day
            | Resolution.hour_of_year
            | Resolution.hour_of_day_summer
            | Resolution.hour_of_day_winter
            | Resolution.top_100_hours
            | Resolution.hour_of_day_matrix
        ):
            timestamp_grouping_func = "hour"
        case Resolution.day_of_year:
            timestamp_grouping_func = "day"
        case Resolution.month:
            timestamp_grouping_func = "month"
        case _:
            raise ValueError(f"Unsupported resolution: {resolution}")
    return timestamp_grouping_func


def _build_quantity_exprs_for_raw(
    db_schema: DBSchema,
    available_cols: set[str],
) -> list[pl.Expr]:
    exprs: list[pl.Expr] = []
    for quantity, mapped in get_db_enduse_colnames_map(db_schema).items():
        if mapped is None or quantity == DataCol.OUTDOOR_DRYBULB_TEMP:
            continue
        expr = resstock_quantity_expr(quantity, db_schema, available_cols).fill_null(0.0)
        exprs.append(expr.alias(str(quantity)))
    return exprs


def _get_raw_annual_data(
    data_source: DataSourceConfig,
    group_cols: Sequence[str],
    occupied_only: bool,
) -> pl.DataFrame | None:
    """Aggregate annual non-utility data directly from the downloaded raw parquet."""
    if not group_cols or any(col == "eiaid" for col in group_cols):
        return None

    raw_path = workflow.get_resstock_data_file(data_source.name)
    lf = pl.scan_parquet(raw_path)
    schema = lf.collect_schema()
    available_cols = set(schema.names())
    if "weight" not in available_cols:
        return None

    try:
        group_exprs = [resstock_group_expr(col, available_cols) for col in group_cols]
        quantity_exprs = _build_quantity_exprs_for_raw(data_source.db_schema, available_cols)
        if occupied_only:
            vacancy_col = resolve_existing_char_column(
                get_db_characteristics_colnames(data_source.db_schema).VACANCY,
                available_cols,
            )
            lf = lf.filter(pl.col(vacancy_col) == "Occupied")
    except ValueError:
        return None

    if not quantity_exprs:
        return None

    raw_rows = lf.select(
        *group_exprs,
        pl.col("weight").cast(pl.Float64).alias("weight"),
        *quantity_exprs,
    ).collect()

    annual_raw = _aggregate_raw_annual_rows(raw_rows, list(group_cols))
    annual = _transform_columns(annual_raw, data_source.db_schema)
    if list(group_cols) == ["state"]:
        annual = add_missing_states(annual)
    return annual


def _aggregate_raw_annual_rows(rows: pl.DataFrame, group_cols: list[str]) -> pl.DataFrame:
    """Aggregate weighted annual values, user counts, and quartiles from raw rows."""
    quantity_cols = [col for col in rows.columns if col not in {*group_cols, "weight"}]
    grouped = _aggregate_raw_annual_groups(rows, group_cols, quantity_cols)

    secondary_cols = group_cols[1:]
    us_total = _aggregate_raw_annual_groups(rows, secondary_cols, quantity_cols).with_columns(
        pl.lit("US Total").alias(group_cols[0])
    )
    ordered_cols = group_cols + [col for col in grouped.columns if col not in group_cols]
    us_total = us_total.select(ordered_cols)
    return pl.concat([grouped, us_total], how="diagonal_relaxed")


def _aggregate_raw_annual_groups(
    rows: pl.DataFrame,
    group_cols: list[str],
    quantity_cols: list[str],
) -> pl.DataFrame:
    if rows.is_empty():
        return _empty_raw_annual_frame(group_cols, quantity_cols)

    partitions = rows.partition_by(group_cols, as_dict=True, maintain_order=True) if group_cols else {(): rows}

    result_rows = []
    for key, group in partitions.items():
        row = _partition_key_dict(group_cols, key)
        weights = group["weight"].to_numpy()
        row["units_count"] = float(weights.sum())
        row["sample_count"] = len(group)

        for quantity_col in quantity_cols:
            values = group[quantity_col].to_numpy()
            nonzero_mask = values > 0
            nonzero_weights = weights[nonzero_mask]
            nonzero_values = values[nonzero_mask]

            row[quantity_col] = float(np.dot(values, weights))
            row[f"{quantity_col}__nonzero_units_count"] = float(nonzero_weights.sum())
            row[f"{quantity_col}__nonzero_sample_count"] = int(nonzero_mask.sum())
            row[f"{quantity_col}__upgrade__quartiles"] = _weighted_quantiles_or_zeros(values, weights)
            row[f"{quantity_col}__upgrade__nonzero_quartiles"] = _weighted_quantiles_or_zeros(
                nonzero_values,
                nonzero_weights,
            )

        result_rows.append(row)

    return pl.DataFrame(result_rows)


def _partition_key_dict(group_cols: list[str], key: object) -> dict[str, object]:
    if not group_cols:
        return {}
    if not isinstance(key, tuple):
        key = (key,)
    return dict(zip(group_cols, key, strict=True))


def _weighted_quantiles_or_zeros(values: np.ndarray, weights: np.ndarray) -> list[float]:
    if len(values) == 0 or weights.sum() <= 0:
        return [0.0] * len(ANNUAL_QUANTILES)
    return weighted_quantiles(values, weights, ANNUAL_QUANTILES).tolist()


def _empty_raw_annual_frame(group_cols: list[str], quantity_cols: list[str]) -> pl.DataFrame:
    schema: dict[str, pl.DataType] = dict.fromkeys(group_cols, pl.String)
    schema["units_count"] = pl.Float64
    schema["sample_count"] = pl.Int64
    for quantity_col in quantity_cols:
        schema[quantity_col] = pl.Float64
        schema[f"{quantity_col}__nonzero_units_count"] = pl.Float64
        schema[f"{quantity_col}__nonzero_sample_count"] = pl.Int64
        schema[f"{quantity_col}__upgrade__quartiles"] = pl.List(pl.Float64)
        schema[f"{quantity_col}__upgrade__nonzero_quartiles"] = pl.List(pl.Float64)
    return pl.DataFrame(schema=schema)


@timed
@cached(cache_file="resstock_annual_data_cache")
def get_annual_all(
    data_key: DataKey,
    occupied_only: bool = False,
) -> pl.DataFrame | None:
    """Get annual data for all configured data sources.

    Args:
        data_key: DataKey containing effective_group_by, aggregation_type, and coverage
        occupied_only: If True, only include occupied units (for RECS comparison)

    """
    if not workflow.data_sources:
        return None

    by_cols = list(data_key.effective_group_by)

    all_dfs = []
    for data_source in workflow.data_sources:
        if len(by_cols) == 1:
            df = get_annual(data_source, by_cols[0], occupied_only=occupied_only)
        else:
            df = _get_annual_two_char_cached(data_source, by_cols[0], by_cols[1], occupied_only)
        df = apply_aggregation(data_key, df)
        df = df.with_columns(pl.lit(data_source.name).alias("source"))
        all_dfs.append(df)
    final_df = pl.concat(all_dfs, how="diagonal_relaxed")
    return final_df


@functools.cache
def _get_annual_two_char_cached(
    data_source: DataSourceConfig,
    by: str,
    filter_char: str,
    occupied_only: bool,
) -> pl.DataFrame:
    """Cached 2-column annual query. Multiple filter_values share this cache."""
    raw_df = _get_raw_annual_data(data_source, (by, filter_char), occupied_only)
    if raw_df is not None:
        return raw_df
    bsq = get_buildstock_query(
        workgroup=workflow.workgroup,
        config=data_source,
        skip_reports=True,
    )
    return _get_annual_by_chars(bsq, by, data_source, occupied_only, filter_char=filter_char)


@timed
@functools.cache
def get_annual(
    data_source: DataSourceConfig,
    by: str = "state",
    occupied_only: bool = False,
) -> pl.DataFrame:
    """Get annual retail sales aggregated by geography and scaled to EIA customer counts."""
    raw_df = _get_raw_annual_data(data_source, (by,), occupied_only)
    if raw_df is not None:
        return raw_df
    bsq = get_buildstock_query(
        workgroup=workflow.workgroup,
        config=data_source,
        skip_reports=True,
    )
    if by == "eiaid":
        assert not occupied_only, "occupied_only is not supported when by='eiaid'"
        return _get_annual_by_eiaid(bsq, data_source)
    df = _get_annual_by_chars(bsq, by, data_source, occupied_only)
    if by == "state":
        df = add_missing_states(df)
    return df


def _get_by_col(by: str, bsq: BuildStockQuery):
    col_map = RECS_CHARS_MAPPING[by]["ResStock"]["mapping"]
    col_name = RECS_CHARS_MAPPING[by]["ResStock"]["column_name"]
    if not col_map:  # if empty, just return original by col
        return sa.Column(col_name).label(by)
    original_col = bsq._get_column(col_name, annual_only=True)
    by_col = MappedColumn(bsq=bsq, name=by, mapping_dict=col_map, key=original_col)
    return by_col


def _bsq_annual_query(bsq: BuildStockQuery, enduses, group_by: list, restrict: list) -> pd.DataFrame:
    """Run a single annual BSQ query with the common flags used by annual loaders."""
    result = bsq.query(
        enduses=enduses,
        get_nonzero_count=True,
        get_quartiles=True,
        group_by=group_by,
        annual_only=True,
        restrict=restrict,
    )
    bsq.save_cache()
    return result


@timed
def _get_annual_by_chars(
    bsq: BuildStockQuery,
    by: str,
    data_source: DataSourceConfig,
    occupied_only: bool,
    filter_char: str | None = None,
) -> pl.DataFrame:
    """Load annual BSQ data grouped by `by` (and optionally `filter_char`).

    With filter_char set, BSQ computes per-cell (by × filter_char) totals,
    averages, quartiles, and nonzero counts — cheap to filter downstream.
    The US-Total row is computed by dropping `by` from the group_by.
    """
    char_cols = get_db_characteristics_colnames(data_source.db_schema)
    enduses = _get_db_enduses(bsq, data_source.db_schema, table="baseline")
    restrict = [(char_cols.VACANCY, ["Occupied"])] if occupied_only else []

    by_col = _get_by_col(by, bsq)
    extra_cols = [_get_by_col(filter_char, bsq)] if filter_char else []

    main = _bsq_annual_query(bsq, enduses, [by_col, *extra_cols], restrict)
    us_total = _bsq_annual_query(bsq, enduses, extra_cols, restrict)
    us_total[by] = "US Total"
    us_total = us_total[main.columns]
    combined = pd.concat([main, us_total], ignore_index=True)

    df = pl.from_pandas(combined)
    return _transform_columns(df, data_source.db_schema)


def _get_annual_by_eiaid(bsq, data_source):
    enduses = _get_db_enduses(bsq, data_source.db_schema, table="baseline")
    db_char_col = get_db_characteristics_colnames(data_source.db_schema)
    ercot_pd = bsq.query(
        enduses=enduses,
        restrict=[(db_char_col.STATE, ["TX"]), (db_char_col.ISO_RTO_REGION, ["ERCOT"])],
        get_nonzero_count=True,
    )
    bsq.save_cache()
    ercot_pd["eiaid"] = str(UtilityName2ID["ERCOT"])
    result_pd = bsq.utility.aggregate_annual_by_eiaid(
        enduses=enduses,
        get_nonzero_count=True,
    )
    bsq.save_cache()
    df = pl.concat([pl.from_pandas(ercot_pd), pl.from_pandas(result_pd)], how="diagonal_relaxed")
    df = df.with_columns(pl.col("eiaid").cast(pl.Int64))
    df = _transform_columns(df, data_source.db_schema)
    return df


def _get_db_enduses(bsq: BuildStockQuery, db_schema: DBSchema, table: str) -> tuple[str, ...]:
    data_col_to_db_col = get_db_enduse_colnames_map(db_schema)
    enduses = []
    for new_name, dbcols in data_col_to_db_col.items():
        if dbcols is None:
            continue
        if new_name in [DataCol.OUTDOOR_DRYBULB_TEMP] and table == "baseline":
            continue  # temperature - only available in timeseries table
        enduse_expr = " + ".join(dbcols) if isinstance(dbcols, tuple) else dbcols
        col = bsq.get_calculated_column(column_name=new_name, column_expr=enduse_expr, table=table)
        enduses.append(col)

    return tuple(enduses)


def _transform_columns(df: pl.DataFrame, db_schema: DBSchema) -> pl.DataFrame:
    """Transform BSQ column names to add _value and _percent_users suffixes.

    BSQ now returns columns with the new_name already (e.g., 'electricity_total'),
    so we just need to rename them to add the suffixes and handle associated metadata columns.
    """
    db_enduse_colmap = get_db_enduse_colnames_map(db_schema)
    new_cols_expr = []
    to_drop_cols = []

    for new_name, db_name in db_enduse_colmap.items():
        # Skip if this enduse is not mapped (db_name is None)
        if db_name is None:
            continue

        # BSQ returns columns with new_name already
        if new_name not in df.columns:
            continue

        value_col_name = new_name + "_value"
        percent_users_col_name = new_name + "_percent_users"
        quartiles_col_name = new_name + "_quartiles"
        nonzero_quartiles_col_name = new_name + "_nonzero_quartiles"

        # Rename the value column
        new_cols_expr.append(pl.col(new_name).alias(value_col_name))
        to_drop_cols.append(new_name)

        # Handle nonzero_units_count column
        nonzero_col = new_name + "__nonzero_units_count"
        if nonzero_col in df.columns:
            new_cols_expr.append((pl.col(nonzero_col) / pl.col("units_count") * 100).alias(percent_users_col_name))
            to_drop_cols.append(nonzero_col)

        # Handle nonzero_sample_count column (per-quantity raw row count)
        nonzero_sample_col = new_name + "__nonzero_sample_count"
        if nonzero_sample_col in df.columns:
            new_cols_expr.append(pl.col(nonzero_sample_col).alias(f"{new_name}_nonzero_sample_count"))
            to_drop_cols.append(nonzero_sample_col)

        # Handle quartiles column
        quartiles_db_col = new_name + "__upgrade__quartiles"
        if quartiles_db_col in df.columns:
            new_cols_expr.append(pl.col(quartiles_db_col).alias(quartiles_col_name))
            to_drop_cols.append(quartiles_db_col)

        # Handle nonzero_quartiles column
        nonzero_quartiles_db_col = new_name + "__upgrade__nonzero_quartiles"
        if nonzero_quartiles_db_col in df.columns:
            new_cols_expr.append(pl.col(nonzero_quartiles_db_col).alias(nonzero_quartiles_col_name))
            to_drop_cols.append(nonzero_quartiles_db_col)

    df = df.with_columns(new_cols_expr)
    df = df.drop(to_drop_cols)
    return df


def _resolve_characteristic_column_name(df: pl.DataFrame, column_name: str) -> str:
    """Return the characteristic column name as present in BuildStockQuery results.
    This is needed because sometimes BSQ removes the in. prefix from characteristic columns.
    """
    if column_name in df.columns:
        return column_name
    if column_name.startswith("in."):
        stripped = column_name.removeprefix("in.")
        if stripped in df.columns:
            return stripped
    return column_name
