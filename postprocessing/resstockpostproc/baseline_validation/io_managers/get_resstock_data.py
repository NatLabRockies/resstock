import functools
from collections.abc import Sequence
import numpy as np

import pandas as pd
import polars as pl

import sqlalchemy as sa
from buildstock_query import BuildStockQuery, MappedColumn

from resstockpostproc.baseline_validation.io_managers.utils import apply_aggregation
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


_ANNUAL_QUANTILES = [0, 0.02, 0.1, 0.25, 0.5, 0.75, 0.9, 0.98, 1]


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
        df = df.join(annual_df.select([by] + percent_users_cols), on=[by], how="left")
        df = apply_aggregation(data_key, df)
        df = df.with_columns(pl.lit(data_source.name).alias("source"))
        all_dfs.append(df)
    final_df = pl.concat(all_dfs, how="diagonal")
    return final_df


@timed
def get_timeseries(
    data_source: DataSourceConfig,
    resolution: Resolution = Resolution.month,
    by: str = "state",
    restrict_list: Sequence[str] | None = None,
    occupied_only: bool = False,
) -> pl.DataFrame:
    """Aggregate monthly data from timeseries."""
    bsq = get_buildstock_query(
        workgroup=workflow.workgroup,
        config=data_source,
        skip_reports=True,
    )
    db_char_col = get_db_characteristics_colnames(data_source.db_schema)
    if by == "eiaid":
        assert not occupied_only, "occupied_only is not supported when by='eiaid'"
        assert restrict_list, "restrict_list must be provided when by='eiaid'"
        result = _get_timeseries_by_utilities(bsq, data_source, restrict_list, resolution)
    else:
        result = _get_timeseries_by_char(
            bsq, data_source, by, restrict_list, occupied_only=occupied_only, resolution=resolution
        )

    result = _transform_columns(result, data_source.db_schema)
    if resolution == Resolution.month:
        ts_data = result.with_columns(pl.col(db_char_col.TIMESTAMP).dt.month().alias("month"))
        ts_data = ts_data.sort(by=[by, "month"])
        ts_data = ts_data.with_columns(pl.col("month").replace_strict(NUM2MONTH, default=None))
    elif resolution == Resolution.day_of_year:
        # Use actual date (truncated to day) instead of ordinal day number
        ts_data = result.with_columns(pl.col(db_char_col.TIMESTAMP).dt.truncate("1d").alias("day of year"))
        ts_data = ts_data.sort(by=[by, "day of year"])
    elif resolution in {Resolution.hour_of_year, Resolution.top_100_hours}:
        ts_data = result.with_columns(
            ((pl.col(db_char_col.TIMESTAMP).dt.ordinal_day() - 1) * 24 + pl.col(db_char_col.TIMESTAMP).dt.hour()).alias(
                resolution
            )
        )
        ts_data = ts_data.sort(by=[by, resolution])
    elif resolution == Resolution.hour_of_day_summer:
        ts_data = result.with_columns(
            pl.col(db_char_col.TIMESTAMP).dt.hour().alias(Resolution.hour_of_day_summer),
            pl.col(db_char_col.TIMESTAMP).dt.month().alias("month"),
        )
        ts_data = ts_data.filter(pl.col("month").is_in([6, 7, 8]))
        ts_data = ts_data.group_by([by, Resolution.hour_of_day_summer], maintain_order=True).agg(
            [pl.col(col).mean().alias(col) for col in result.columns if col not in {by, db_char_col.TIMESTAMP, "month"}]
        )
        ts_data = ts_data.sort(by=[by, Resolution.hour_of_day_summer])
    elif resolution == Resolution.hour_of_day_winter:
        ts_data = result.with_columns(
            pl.col(db_char_col.TIMESTAMP).dt.hour().alias(Resolution.hour_of_day_winter),
            pl.col(db_char_col.TIMESTAMP).dt.month().alias("month"),
        )
        ts_data = ts_data.filter(pl.col("month").is_in([12, 1, 2]))
        ts_data = ts_data.group_by([by, Resolution.hour_of_day_winter], maintain_order=True).agg(
            [pl.col(col).mean().alias(col) for col in result.columns if col not in {by, db_char_col.TIMESTAMP, "month"}]
        )
        ts_data = ts_data.sort(by=[by, Resolution.hour_of_day_winter])
    elif resolution == Resolution.hour_of_day_matrix:
        # Add hour, month, and day_type columns
        ts_data = result.with_columns(
            pl.col(db_char_col.TIMESTAMP).dt.hour().alias("hour of day"),
            pl.col(db_char_col.TIMESTAMP).dt.month().replace_strict(NUM2MONTH, default=None).alias("month"),
            pl.when(pl.col(db_char_col.TIMESTAMP).dt.weekday() < 5)  # Mon=0..Fri=4 are weekdays
            .then(pl.lit("Weekday"))
            .otherwise(pl.lit("Weekend"))
            .alias("day_type"),
        )
        value_cols = [col for col in result.columns if col not in {by, db_char_col.TIMESTAMP}]

        # 1. Monthly by day_type (e.g., JAN + Weekday)
        monthly_by_daytype = ts_data.group_by([by, "month", "day_type", "hour of day"], maintain_order=True).agg(
            [pl.col(col).mean().alias(col) for col in value_cols]
        )

        # 2. Monthly "All Days" (aggregate across weekday/weekend)
        monthly_all_days = (
            ts_data.group_by([by, "month", "hour of day"], maintain_order=True)
            .agg([pl.col(col).mean().alias(col) for col in value_cols])
            .with_columns(pl.lit("All Days").alias("day_type"))
        )

        # 3. "All Year" by day_type
        yearly_by_daytype = (
            ts_data.group_by([by, "day_type", "hour of day"], maintain_order=True)
            .agg([pl.col(col).mean().alias(col) for col in value_cols])
            .with_columns(pl.lit("All Year").alias("month"))
        )

        # 4. "All Year" + "All Days"
        yearly_all_days = (
            ts_data.group_by([by, "hour of day"], maintain_order=True)
            .agg([pl.col(col).mean().alias(col) for col in value_cols])
            .with_columns(pl.lit("All Year").alias("month"), pl.lit("All Days").alias("day_type"))
        )

        ts_data = pl.concat(
            [monthly_by_daytype, monthly_all_days, yearly_by_daytype, yearly_all_days], how="diagonal_relaxed"
        )
        ts_data = ts_data.sort(by=[by, "month", "day_type", "hour of day"])
    else:  # hour_of_day
        assert resolution == Resolution.hour_of_day, f"Unsupported resolution: {resolution}"
        ts_data = result.with_columns(pl.col(db_char_col.TIMESTAMP).dt.hour().alias(Resolution.hour_of_day))
        ts_data = ts_data.group_by([by, Resolution.hour_of_day], maintain_order=True).agg(
            [pl.col(col).mean().alias(col) for col in result.columns if col not in {by, db_char_col.TIMESTAMP}]
        )
        ts_data = ts_data.sort(by=[by, Resolution.hour_of_day])
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


def _calculate_weighted_quantiles(data: np.ndarray, weights: np.ndarray, quantiles: list[float]) -> np.ndarray:
    """Calculate weighted quantiles for raw annual parquet aggregation."""
    sorted_indices = np.argsort(data)
    sorted_data = data[sorted_indices]
    sorted_weights = weights[sorted_indices]

    cumsum_weights = np.cumsum(sorted_weights)
    total_weight = cumsum_weights[-1]
    cumsum_normalized = cumsum_weights / total_weight

    result = np.zeros(len(quantiles))
    for i, q in enumerate(quantiles):
        if q == 0:
            result[i] = sorted_data[0]
        elif q == 1:
            result[i] = sorted_data[-1]
        else:
            idx = np.searchsorted(cumsum_normalized, q)
            if idx == 0:
                result[i] = sorted_data[0]
            elif idx >= len(sorted_data):
                result[i] = sorted_data[-1]
            else:
                w0 = cumsum_normalized[idx - 1]
                w1 = cumsum_normalized[idx]
                v0 = sorted_data[idx - 1]
                v1 = sorted_data[idx]
                if w1 - w0 > 0:
                    result[i] = v0 + (v1 - v0) * (q - w0) / (w1 - w0)
                else:
                    result[i] = v0

    return result


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

    if group_cols:
        partitions = rows.partition_by(group_cols, as_dict=True, maintain_order=True)
    else:
        partitions = {(): rows}

    result_rows = []
    for key, group in partitions.items():
        row = _partition_key_dict(group_cols, key)
        weights = group["weight"].to_numpy()
        row["units_count"] = float(weights.sum())

        for quantity_col in quantity_cols:
            values = group[quantity_col].to_numpy()
            nonzero_mask = values > 0
            nonzero_weights = weights[nonzero_mask]
            nonzero_values = values[nonzero_mask]

            row[quantity_col] = float(np.dot(values, weights))
            row[f"{quantity_col}__nonzero_units_count"] = float(nonzero_weights.sum())
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
        return [0.0] * len(_ANNUAL_QUANTILES)
    return _calculate_weighted_quantiles(values, weights, _ANNUAL_QUANTILES).tolist()


def _empty_raw_annual_frame(group_cols: list[str], quantity_cols: list[str]) -> pl.DataFrame:
    schema: dict[str, pl.DataType] = {col: pl.String for col in group_cols}
    schema["units_count"] = pl.Float64
    for quantity_col in quantity_cols:
        schema[quantity_col] = pl.Float64
        schema[f"{quantity_col}__nonzero_units_count"] = pl.Float64
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


@functools.lru_cache(maxsize=None)
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
    return _get_annual_by_two_chars(bsq, by, filter_char, data_source, occupied_only)


@timed
@functools.lru_cache(maxsize=None)
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
    df = _get_annual_by_char(bsq, by, data_source, occupied_only)
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


@timed
def _get_annual_by_char(
    bsq: BuildStockQuery, by: str, data_source: DataSourceConfig, occupied_only: bool
) -> pl.DataFrame:
    char_cols = get_db_characteristics_colnames(data_source.db_schema)
    enduses = _get_db_enduses(bsq, data_source.db_schema, table="baseline")
    restrict = [(char_cols.VACANCY, ["Occupied"])] if occupied_only else []
    by_col = _get_by_col(by, bsq)
    result_df = bsq.query(
        enduses=enduses,
        get_nonzero_count=True,
        get_quartiles=True,
        group_by=[by_col],
        annual_only=True,
        restrict=restrict,
    )
    bsq.save_cache()
    result_us_total = bsq.query(
        enduses=enduses,
        annual_only=True,
        get_nonzero_count=True,
        get_quartiles=True,
        restrict=restrict,
    )
    bsq.save_cache()
    result_us_total[by] = "US Total"
    result_us_total = result_us_total[result_df.columns]
    result_df = pd.concat([result_df, result_us_total], ignore_index=True)

    df = pl.from_pandas(result_df)
    char_cols = get_db_characteristics_colnames(data_source.db_schema)
    enduses = _get_db_enduses(bsq, data_source.db_schema, table="baseline")
    df = _transform_columns(df, data_source.db_schema)
    return df


@timed
def _get_annual_by_two_chars(
    bsq: BuildStockQuery, by: str, filter_char: str, data_source: DataSourceConfig, occupied_only: bool
) -> pl.DataFrame:
    """Load annual data grouped by TWO characteristics (by + filter_char).

    Used for pre-filtered plots: the 2-column groupby produces per-cell values,
    which can then be cheaply filtered to a specific filter_char value.
    BSQ computes correct per-cell totals, averages, quartiles, and nonzero counts.
    """
    char_cols = get_db_characteristics_colnames(data_source.db_schema)
    enduses = _get_db_enduses(bsq, data_source.db_schema, table="baseline")
    restrict = [(char_cols.VACANCY, ["Occupied"])] if occupied_only else []
    by_col = _get_by_col(by, bsq)
    filter_col = _get_by_col(filter_char, bsq)
    result_df = bsq.query(
        enduses=enduses,
        get_nonzero_count=True,
        get_quartiles=True,
        group_by=[by_col, filter_col],
        annual_only=True,
        restrict=restrict,
    )
    bsq.save_cache()

    # Add US Total per filter_value: group by filter_col only (sums across all `by` values)
    result_us_total = bsq.query(
        enduses=enduses,
        annual_only=True,
        get_nonzero_count=True,
        get_quartiles=True,
        group_by=[filter_col],
        restrict=restrict,
    )
    bsq.save_cache()
    result_us_total[by] = "US Total"
    result_us_total = result_us_total[result_df.columns]
    result_df = pd.concat([result_df, result_us_total], ignore_index=True)

    df = pl.from_pandas(result_df)
    df = _transform_columns(df, data_source.db_schema)
    return df


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
    This is needed because sometimes BSQ removes the in. prefix from characteristic columns."""
    if column_name in df.columns:
        return column_name
    if column_name.startswith("in."):
        stripped = column_name.removeprefix("in.")
        if stripped in df.columns:
            return stripped
    return column_name
