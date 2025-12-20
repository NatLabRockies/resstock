import polars as pl
import pandas as pd
from collections.abc import Sequence
from typing import Literal
from .utils import add_us_total, add_missing_states
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow, DataSourceConfig
from resstockpostproc.baseline_validation.schema.plot_spec import Resolution
from resstockpostproc.shared_utils.db_column_names import get_db_enduse_colnames_map, get_db_characteristics_colnames
from buildstock_query import BuildStockQuery
from resstockpostproc.baseline_validation.schema.workflow_schema import DBSchema
from resstockpostproc.baseline_validation.utils import get_buildstock_query
from resstockpostproc.shared_utils.mapping import NUM2MONTH
from resstockpostproc.shared_utils.db_column_names import DataCol, DBCharCol
from resstockpostproc.shared_utils.caching import cached
from resstockpostproc.shared_utils.mapping import UtilityName2ID
import sqlalchemy as sa


def get_timeseries_all(
    by: Literal["state", "eiaid"] = "state",
    restrict_list: Sequence[str] | None = None,
    occupied_only: bool = False,
    aggregation: Literal["sum", "per_unit_avg", "per_user_avg"] = "sum",
    resolution: Resolution = Resolution.month,
) -> pl.DataFrame:
    all_dfs = []
    for data_source in workflow.data_sources:
        df = get_timeseries(data_source=data_source,
                            by=by,
                            restrict_list=restrict_list,
                            occupied_only=occupied_only,
                            resolution=resolution)
        annual_df = get_annual(data_source, by, occupied_only=occupied_only)
        value_cols = [col for col in df.columns if col.endswith("_value")]
        percent_users_cols = [col.replace("_value", "_percent_users") for col in value_cols]
        percent_users_cols = [col for col in percent_users_cols if col in df.columns]
        df = df.join(annual_df.select([by] + percent_users_cols), on=[by], how="left")
        if aggregation == "per_unit_avg":
            df = df.with_columns([
                (pl.col(col) / pl.col("units_count")).alias(col) for col in value_cols
            ])
        elif aggregation == "per_user_avg":
            df = df.with_columns([
                (pl.col(value_col) / (pl.col("units_count") * pl.col(percent_users_col) / 100)).alias(value_col) 
                for value_col, percent_users_col in zip(value_cols, percent_users_cols)
                if percent_users_col in df.columns
            ])
        df = df.with_columns(pl.lit(data_source.name).alias("source"))
        all_dfs.append(df)
    final_df = pl.concat(all_dfs, how="diagonal")
    return final_df


def get_timeseries(
    data_source: DataSourceConfig,
    resolution: Resolution = Resolution.month,
    by: Literal["state", "eiaid"] = "state",
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
        result = _get_timeseries_by_char(bsq, data_source, by, restrict_list,
                                         occupied_only=occupied_only, resolution=resolution)

    result = _transform_columns(result, data_source.db_schema)
    if resolution == Resolution.month:
        ts_data = result.with_columns(pl.col(db_char_col.TIMESTAMP).dt.month().alias("month"))
        ts_data = ts_data.sort(by=[by, "month"])
        ts_data = ts_data.with_columns(pl.col("month").replace_strict(NUM2MONTH, default=None))
    elif resolution == Resolution.day_of_year:
        ts_data = result.with_columns(pl.col(db_char_col.TIMESTAMP).dt.ordinal_day().alias("day_of_year"))
        ts_data = ts_data.sort(by=[by, resolution])
    elif resolution in {Resolution.hour_of_year, Resolution.top_100_hours}:
        ts_data = result.with_columns(
            ((pl.col(db_char_col.TIMESTAMP).dt.ordinal_day() - 1) * 24 + pl.col(db_char_col.TIMESTAMP).dt.hour())
            .alias(resolution)
        )
        ts_data = ts_data.sort(by=[by, resolution])
    elif resolution == Resolution.hour_of_day_summer:
        ts_data = result.with_columns(pl.col(db_char_col.TIMESTAMP).dt.hour().alias(Resolution.hour_of_day_summer),
                                      pl.col(db_char_col.TIMESTAMP).dt.month().alias("month"))
        ts_data = ts_data.filter(pl.col("month").is_in([6, 7, 8]))
        ts_data = ts_data.group_by([by, Resolution.hour_of_day_summer], maintain_order=True).agg(
            [pl.col(col).mean().alias(col) for col in result.columns if col not in {by, db_char_col.TIMESTAMP, "month"}]
        )
        ts_data = ts_data.sort(by=[by, Resolution.hour_of_day_summer])
    elif resolution == Resolution.hour_of_day_winter:
        ts_data = result.with_columns(pl.col(db_char_col.TIMESTAMP).dt.hour().alias(Resolution.hour_of_day_winter),
                                      pl.col(db_char_col.TIMESTAMP).dt.month().alias("month"))
        ts_data = ts_data.filter(pl.col("month").is_in([12, 1, 2]))
        ts_data = ts_data.group_by([by, Resolution.hour_of_day_winter], maintain_order=True).agg(
            [pl.col(col).mean().alias(col) for col in result.columns if col not in {by, db_char_col.TIMESTAMP, "month"}]
        )
        ts_data = ts_data.sort(by=[by, Resolution.hour_of_day_winter])
    else:  # hour
        assert resolution == Resolution.hour_of_day, f"Unsupported resolution: {resolution}"
        ts_data = result.with_columns(pl.col(db_char_col.TIMESTAMP).dt.hour().alias(Resolution.hour_of_day))
        ts_data = ts_data.group_by([by, Resolution.hour_of_day], maintain_order=True).agg(
            [pl.col(col).mean().alias(col) for col in result.columns if col not in {by, db_char_col.TIMESTAMP}]
        )
        ts_data = ts_data.sort(by=[by, Resolution.hour_of_day])
    if by == "state":
        result = add_missing_states(result)
    return ts_data


def _get_timeseries_by_char(bsq: BuildStockQuery, data_source: DataSourceConfig,
                            by: str, restrict_list: Sequence[str] | None = None, 
                            occupied_only: bool = False, resolution: str = "month"):
    db_char_col = get_db_characteristics_colnames(data_source.db_schema)
    enduses = _get_db_enduses(bsq, data_source.db_schema, table="timeseries")
    restrict = [(db_char_col.VACANCY, ["Occupied"])] if occupied_only else []
    if restrict_list:
        restrict += [(db_char_col.STATE, restrict_list)]
    result_df = bsq.query(enduses=tuple(enduses), group_by=["time", by],
                              restrict=restrict, annual_only=False,
                              timestamp_grouping_func=resolution)
    bsq.save_cache()
    if by == "state":
        result_us_total = bsq.query(enduses=tuple(enduses), group_by=["time"],
                                    restrict=restrict, annual_only=False,
                                    timestamp_grouping_func=resolution)
        bsq.save_cache()
        result_us_total["state"] = "US Total"
        result_us_total = result_us_total[result_df.columns]
        result_df = pd.concat([result_df, result_us_total], ignore_index=True)
    result = pl.from_pandas(result_df)
    return result


def _get_timeseries_by_utilities(bsq: BuildStockQuery, data_source: DataSourceConfig,
                                 eiaid_list: Sequence[str],
                                 resolution: Resolution = Resolution.month):
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
    #.with_columns(pl.lit(str(UtilityName2ID["ERCOT"])).alias("eiaid"))
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
        case Resolution.hour_of_day | Resolution.hour_of_year | Resolution.hour_of_day_summer | \
             Resolution.hour_of_day_winter | Resolution.top_100_hours:
            timestamp_grouping_func = "hour"
        case Resolution.day_of_year:
            timestamp_grouping_func = "day"
        case Resolution.month:
            timestamp_grouping_func = "month"
        case _:
            raise ValueError(f"Unsupported resolution: {resolution}")
    return timestamp_grouping_func


def get_annual_all(
    by: Literal["state", "eiaid"] = "state",
    occupied_only: bool = False,
    aggregation: Literal["sum", "per_unit_avg", "per_user_avg"] = "sum"
) -> pl.DataFrame:
    all_dfs = []
    for data_source in workflow.data_sources:
        df = get_annual(data_source, by, occupied_only=occupied_only)
        if aggregation == "per_unit_avg":
            value_cols = [col for col in df.columns if col.endswith("_value")]
            df = df.with_columns([
                (pl.col(col) / pl.col("units_count")).alias(col) for col in value_cols
            ])
        elif aggregation == "per_user_avg":
            value_cols = [col for col in df.columns if col.endswith("_value")]
            percent_users_cols = [col.replace("_value", "_percent_users") for col in value_cols]
            df = df.with_columns([
                (pl.col(value_col) / (pl.col(percent_users_col) / 100 * pl.col("units_count"))).alias(value_col) 
                for value_col, percent_users_col in zip(value_cols, percent_users_cols)
                if percent_users_col in df.columns
            ])
        
        df = df.with_columns(pl.lit(data_source.name).alias("source"))
        all_dfs.append(df)
    final_df = pl.concat(all_dfs, how="diagonal_relaxed")
    return final_df


def get_annual(
    data_source: DataSourceConfig,
    by: Literal["state", "eiaid"] = "state",
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


def _get_annual_by_char(bsq: BuildStockQuery, by: str,
                        data_source: DataSourceConfig,
                        occupied_only: bool) -> pl.DataFrame:
    char_cols = get_db_characteristics_colnames(data_source.db_schema)
    enduses = _get_db_enduses(bsq, data_source.db_schema, table="baseline")
    restrict = [(char_cols.VACANCY, ["Occupied"])] if occupied_only else []
    result_df = bsq.query(enduses=enduses,
                          get_nonzero_count=True,
                          get_quartiles=True,
                          group_by=[by],
                          annual_only=True,
                          restrict=restrict)
    bsq.save_cache()
    if by == "state":
        result_us_total = bsq.query(enduses=enduses,
                                    annual_only=True,
                                    get_nonzero_count=True,
                                    get_quartiles=True,
                                    restrict=restrict,
                                    )
        bsq.save_cache()
        result_us_total["state"] = "US Total"
        result_us_total = result_us_total[result_df.columns]
        result_df = pd.concat([result_df, result_us_total], ignore_index=True)
    
    df = pl.from_pandas(result_df)
    char_cols = get_db_characteristics_colnames(data_source.db_schema)
    enduses = _get_db_enduses(bsq, data_source.db_schema, table="baseline")
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
        col = bsq.get_calculated_column(column_name=new_name,
                                        column_expr=enduse_expr,
                                        table=table)
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
            new_cols_expr.append(
                (pl.col(nonzero_col) / pl.col("units_count") * 100).alias(percent_users_col_name)
            )
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
