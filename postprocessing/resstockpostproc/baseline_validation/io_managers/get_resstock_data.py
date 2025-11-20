import polars as pl

from resstockpostproc.baseline_validation.data_processing.data_processor import scale_to_eia_customers
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow, DataSourceConfig
from resstockpostproc.shared_utils.db_column_names import get_db_enduse_colnames_map, get_db_characteristics_colnames
from buildstock_query import BuildStockQuery
from resstockpostproc.baseline_validation.schema.workflow_schema import DBSchema
from resstockpostproc.baseline_validation.utils import get_buildstock_query
from resstockpostproc.shared_utils.mapping import NUM2MONTH
from resstockpostproc.shared_utils.db_column_names import DataCol, DBCharCol
from typing import Literal, Sequence


def get_monthly_all(
    by: Literal['state', 'eiaid'] = "state",
    restrict_list: Sequence[str] | None = None,
    occupied_only: bool = False,
) -> pl.DataFrame:
    final_df = None
    for data_source in workflow.data_sources:
        df = get_monthly(data_source, by, restrict_list, occupied_only)
        df = df.rename({col: f"{data_source.name}_{col}" for col in df.columns if col not in {by, "month"}})
        final_df = df if final_df is None else final_df.join(df, on=[by, "month"], how="outer", coalesce=True)
    assert final_df is not None
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
    enduses = _get_db_enduses(data_source.db_schema)
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
    result, enduse_datacols = _transform_columns(result, data_source.db_schema)
    ts_data = result.with_columns(pl.col(db_char_col.TIMESTAMP).dt.month().alias("month"))
    ts_data = ts_data.with_columns(pl.col("month").replace_strict(NUM2MONTH, default=None))
    group_cols = [by, "month"]
    agg_exprs = [pl.col(e).sum().alias(e) for e in enduse_datacols]

    if "sample_count" in ts_data.columns:
        agg_exprs.append(pl.col("sample_count").first().alias("sample_count"))
    if "units_count" in ts_data.columns:
        agg_exprs.append(pl.col("units_count").first().alias("units_count"))

    return ts_data.group_by(group_cols).agg(agg_exprs)


def get_annual_all(
    by: Literal['state', 'eiaid'] = "state",
    occupied_only: bool = False,
) -> pl.DataFrame:
    final_df = None
    for data_source in workflow.data_sources:
        df = get_annual(data_source, by, occupied_only=occupied_only)
        df = df.rename({col: f"{data_source.name}_{col}" for col in df.columns if col != by})
        final_df = df if final_df is None else final_df.join(df, on=[by], how="outer", coalesce=True)
    assert final_df is not None
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
    return _get_annual_by_char(bsq, by, data_source, occupied_only)


def _get_annual_by_char(bsq, by: str, data_source: DataSourceConfig, occupied_only: bool) -> pl.DataFrame:
    char_cols = get_db_characteristics_colnames(data_source.db_schema)
    enduses = _get_db_enduses(data_source.db_schema)
    result_pd = bsq.query(enduses=enduses,
                          group_by=[by, char_cols.VACANCY])
    bsq.save_cache()
    df = pl.from_pandas(result_pd)
    char_cols = get_db_characteristics_colnames(data_source.db_schema)
    enduses = _get_db_enduses(data_source.db_schema)
    if occupied_only:
        col = _resolve_characteristic_column_name(result_pd, char_cols.VACANCY)
        df = df.filter(pl.col(col).str.to_lowercase() == "occupied")
    df, enduse_datacols = _transform_columns(df, data_source.db_schema)
    group_cols = [by]
    agg_exprs = [pl.col(e).sum().alias(e) for e in enduse_datacols]
    return df.group_by(group_cols).agg(agg_exprs)


def _get_annual_by_eiaid(bsq, data_source, occupied_only):
    char_cols = get_db_characteristics_colnames(data_source.db_schema)
    enduses = _get_db_enduses(data_source.db_schema)
    enduses = _get_db_enduses(data_source.db_schema)
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


def _get_db_enduses(db_schema: DBSchema) -> tuple[str, ...]:
    data_col_to_db_col = get_db_enduse_colnames_map(db_schema)
    enduses: list[str] = []
    for dbcols in data_col_to_db_col.values():
        if dbcols is None:
            continue
        if isinstance(dbcols, tuple):
            enduses.extend(dbcols)
            continue
        enduses.append(dbcols)
    return tuple(enduses)


def _transform_columns(df: pl.DataFrame, db_schema: DBSchema) -> tuple[pl.DataFrame, Sequence[str]]:
    db_enduse_colmap = get_db_enduse_colnames_map(db_schema)
    new_cols_expr = []
    new_cols = []
    to_drop_cols = []
    for new_name, db_name in db_enduse_colmap.items():
        df_new_name = new_name + "_value"
        if isinstance(db_name, tuple):
            new_cols_expr.append(
                pl.sum_horizontal([pl.col(col) for col in db_name]).alias(df_new_name)
            )
            to_drop_cols.extend(db_name)
        elif db_name is not None:
            new_cols_expr.append(
                pl.col(db_name).alias(df_new_name)
            )
            to_drop_cols.append(db_name)
        else:
            new_cols_expr.append(
                pl.lit(0).alias(df_new_name)
            )
        new_cols.append(df_new_name)
    df = df.with_columns(new_cols_expr)
    df = df.drop(to_drop_cols)
    return df, new_cols


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
