import polars as pl
import pandas as pd
from collections.abc import Sequence
from typing import Literal
from .utils import add_us_total, add_missing_states
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow, DataSourceConfig
from resstockpostproc.shared_utils.db_column_names import get_db_enduse_colnames_map, get_db_characteristics_colnames
from buildstock_query import BuildStockQuery
from resstockpostproc.baseline_validation.schema.workflow_schema import DBSchema
from resstockpostproc.baseline_validation.utils import get_buildstock_query
from resstockpostproc.shared_utils.mapping import NUM2MONTH
from resstockpostproc.shared_utils.db_column_names import DataCol, DBCharCol
import sqlalchemy as sa


def get_monthly_all(
    by: Literal['state', 'eiaid'] = "state",
    restrict_list: Sequence[str] | None = None,
    occupied_only: bool = False,
    aggregation: Literal["sum", "per_unit_avg", "per_user_avg"] = "sum"
) -> pl.DataFrame:
    all_dfs = []
    for data_source in workflow.data_sources:
        df = get_monthly(data_source, by, restrict_list, occupied_only)
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
    final_df = pl.concat(all_dfs, how="diagonal")
    return final_df


def get_monthly(
    data_source: DataSourceConfig,
    by: Literal['state', 'eiaid'] = "state",
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
    enduses = _get_db_enduses(bsq, data_source.db_schema, table="timeseries")
    if by == "eiaid":
        if not restrict_list:
            raise ValueError("Monthly aggregation for all utilities is not yet supported. Provide restrict_list.")
        relevant_counties = bsq.utility.get_locations_by_eiaids(restrict_list)
        result_pd = bsq.utility.aggregate_ts_by_eiaid(
            enduses=enduses,
            eiaid_list=restrict_list,
            restrict=[(db_char_col.COUNTY, relevant_counties)],
            group_by=(db_char_col.VACANCY,),
            timestamp_grouping_func="month"
        )
        bsq.save_cache()
        result = pl.from_pandas(result_pd)
        if "query_id" in result.columns:
            result = result.drop("query_id")
        if "eiaid" in result.columns:
            result = result.with_columns(pl.col("eiaid").cast(pl.Int64))
    else:
        restrict = []
        if restrict_list:
            restrict = [(db_char_col.STATE, restrict_list)]
        result_pd = bsq.query(enduses=tuple(enduses), group_by=["time", db_char_col.VACANCY, by],
                              restrict=restrict, annual_only=False,
                              timestamp_grouping_func="month")
        bsq.save_cache()
        result = pl.from_pandas(result_pd)
    if occupied_only:
        col = _resolve_characteristic_column_name(result, db_char_col.VACANCY)
        result = result.filter(pl.col(col).str.to_lowercase() == "occupied")
    result = _transform_columns(result, data_source.db_schema)
    ts_data = result.with_columns(pl.col(db_char_col.TIMESTAMP).dt.month().alias("month"))
    ts_data = ts_data.with_columns(pl.col("month").replace_strict(NUM2MONTH, default=None))
    result = add_us_total(ts_data, by=by, group_cols=["month"])
    if by == "state":
        result = add_missing_states(result)
    return result


def get_annual_all(
    by: Literal['state', 'eiaid'] = "state",
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
    by: Literal['state', 'eiaid'] = "state",
    occupied_only: bool = False,
) -> pl.DataFrame:
    """Get annual retail sales aggregated by geography and scaled to EIA customer counts."""
    bsq = get_buildstock_query(
            workgroup=workflow.workgroup,
            config=data_source,
            skip_reports=True,
        )
    if by == "eiaid":
       return _get_annual_by_eiaid(bsq, data_source, occupied_only)
    df = _get_annual_by_char(bsq, by, data_source, occupied_only)
    if by == "state":
        df = add_missing_states(df)
    return df


def _get_annual_by_char(bsq: BuildStockQuery, by: str, data_source: DataSourceConfig, occupied_only: bool) -> pl.DataFrame:
    char_cols = get_db_characteristics_colnames(data_source.db_schema)
    enduses = _get_db_enduses(bsq, data_source.db_schema, table="baseline")
    result_us_total = bsq.query(enduses=enduses,
                                get_nonzero_count=True,
                                get_quartiles=True,
                                group_by=[char_cols.VACANCY])
    result_pd = bsq.query(enduses=enduses,
                          get_nonzero_count=True,
                          get_quartiles=True,
                          group_by=[by, char_cols.VACANCY])
    bsq.save_cache()
    result_us_total["state"] = "US Total"
    result_us_total = result_us_total[result_pd.columns]
    result_df = pd.concat([result_pd, result_us_total], ignore_index=True)
    
    df = pl.from_pandas(result_df)
    char_cols = get_db_characteristics_colnames(data_source.db_schema)
    enduses = _get_db_enduses(bsq, data_source.db_schema, table="baseline")
    if occupied_only:
        col = _resolve_characteristic_column_name(df, char_cols.VACANCY)
        df = df.filter(pl.col(col).str.to_lowercase() == "occupied").drop(col)
    df = _transform_columns(df, data_source.db_schema)
    return df


def _get_annual_by_eiaid(bsq, data_source, occupied_only):
    char_cols = get_db_characteristics_colnames(data_source.db_schema)
    enduses = _get_db_enduses(bsq, data_source.db_schema, table="baseline")
    enduses = _get_db_enduses(bsq, data_source.db_schema, table="baseline")
    result_pd = bsq.utility.aggregate_annual_by_eiaid(
            enduses=enduses,
            group_by=(char_cols.VACANCY,)
        )
    resstock_sales = pl.from_pandas(result_pd)
    resstock_sales = resstock_sales.with_columns(pl.col("eiaid").cast(pl.Int64))
    if occupied_only:
        col = _resolve_characteristic_column_name(resstock_sales, char_cols.VACANCY)
        resstock_sales = resstock_sales.filter(pl.col(col).str.to_lowercase() == "occupied")
    resstock_sales = resstock_sales.rename(enduses).group_by("eiaid").sum()
    bsq.save_cache()
    return resstock_sales


def get_customer_counts_all(
    by: Literal['state', 'eiaid'] = "state",
) -> pl.DataFrame:
    final_df = None
    for data_source in workflow.data_sources:

        df = _get_customer_counts(data_source, by)
        df = df.rename({col: f"{data_source.name}_{col}" for col in df.columns if col != by})
        final_df = df if final_df is None else final_df.join(df, on=[by], how="outer")
    assert final_df is not None
    return final_df


def _get_customer_counts(data_source: DataSourceConfig, by: Literal['state', 'eiaid'] = "state") -> pl.DataFrame:
    """Get customer counts from both BuildStock and EIA data."""
    bsq = get_buildstock_query(
            workgroup=workflow.workgroup,
            config=data_source,
            skip_reports=True,
        )
    db_char_col = get_db_characteristics_colnames(data_source.db_schema)
    if by == "eiaid":
        res_counts = pl.from_pandas(
            bsq.utility.aggregate_unit_counts_by_eiaid(group_by=(db_char_col.VACANCY,))
            )
        res_counts = res_counts.with_columns(pl.col("eiaid").cast(pl.Int64))
    else:
        res_counts = pl.from_pandas(
            bsq.query(enduses=[], group_by=["state", db_char_col.VACANCY], get_query_only=False)
            )
    return res_counts


def _get_db_enduses(bsq: BuildStockQuery, db_schema: DBSchema, table: str) -> tuple[str, ...]:
    data_col_to_db_col = get_db_enduse_colnames_map(db_schema)
    enduses = []
    for new_name, dbcols in data_col_to_db_col.items():
        if dbcols is None:
            continue
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
        else:
            new_cols_expr.append(pl.lit(0).alias(percent_users_col_name))
        
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
