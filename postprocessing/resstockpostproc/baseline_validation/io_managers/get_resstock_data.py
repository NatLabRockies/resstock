import polars as pl
import functools
import pandas as pd
from collections.abc import Sequence


from resstockpostproc.baseline_validation.io_managers.utils import apply_aggregation
from .utils import add_us_total, add_missing_states
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow, DataSourceConfig
from resstockpostproc.baseline_validation.schema.plot_spec import Resolution, DataKey
from resstockpostproc.baseline_validation.schema.recs_chars_mapping import RECS_CHARS_MAPPING
from resstockpostproc.shared_utils.db_column_names import get_db_enduse_colnames_map, get_db_characteristics_colnames
from buildstock_query import BuildStockQuery
from resstockpostproc.baseline_validation.schema.workflow_schema import DBSchema
from resstockpostproc.baseline_validation.utils import get_buildstock_query
from resstockpostproc.shared_utils.mapping import NUM2MONTH
from resstockpostproc.shared_utils.db_column_names import DataCol, DBCharCol
from resstockpostproc.shared_utils.caching import cached
from resstockpostproc.shared_utils.timing import timed
from resstockpostproc.shared_utils.mapping import UtilityName2ID
import sqlalchemy as sa
from buildstock_query import MappedColumn


@timed
@cached(cache_file="resstock_timeseries_data_cache")
def get_timeseries_all(
    data_key: DataKey,
    restrict_list: Sequence[str] | None = None,
    occupied_only: bool = False,
) -> pl.DataFrame | None:
    """Get timeseries data for all configured data sources.

    Args:
        data_key: DataKey containing group_by, resolution, aggregation_type, and coverage
        restrict_list: Optional list of entity IDs to restrict to (e.g., eiaid list)
        occupied_only: If True, only include occupied units (for RECS comparison)
    """
    if not workflow.data_sources:
        return None

    by = data_key.group_by[0]  # timeseries only supports single-column groupby
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


@timed
@cached(cache_file="resstock_annual_data_cache")
def get_annual_all(
    data_key: DataKey,
    occupied_only: bool = False,
) -> pl.DataFrame | None:
    """Get annual data for all configured data sources.

    Args:
        data_key: DataKey containing group_by, aggregation_type, and coverage
        occupied_only: If True, only include occupied units (for RECS comparison)
    """
    if not workflow.data_sources:
        return None

    by_cols = list(data_key.group_by)

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
