import polars as pl

from resstockpostproc.baseline_validation.data_processing.data_processor import scale_to_eia_customers
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow, DataSourceConfig
from resstockpostproc.shared_utils.db_column_names import get_db_column_names
from buildstock_query import BuildStockQuery
from typing import Literal, Sequence
from resstockpostproc.baseline_validation.utils import get_buildstock_query
from resstockpostproc.shared_utils.mapping import NUM2MONTH



def get_timeseries(
    data_source: DataSourceConfig,
    by: Literal['state', 'eiaid'] = 'state',
    restrict_list: Sequence[str] | None = None,
) -> pl.DataFrame:
    """Aggregate timeseries data by geographic level."""
    bsq = get_buildstock_query(
            workgroup=workflow.workgroup,
            config=data_source,
            truth_data_year=workflow.reference_data.truth_data_year,
            eia_mapping_version=workflow.reference_data.eia_mapping_version,
            skip_reports=True,
        )
    db_cols = get_db_column_names(data_source.db_schema)
    enduses = {db_cols.ELECTRICITY_TOTAL: 'electricity_kwh',
           db_cols.NATURAL_GAS_TOTAL: 'natural_gas_kwh'}
    if by == "eiaid":
        if not restrict_list:
            raise ValueError("Monthly aggregation for all utilities is not yet supported. Provide restrict_list.")

        relevant_counties = bsq.utility.get_locations_by_eiaids(restrict_list)
        result_pd = bsq.utility.aggregate_ts_by_eiaid(
            enduses=tuple(enduses.keys()),
            eiaid_list=restrict_list,
            restrict=[(db_cols.COUNTY, relevant_counties)],
        )
        result = pl.from_pandas(result_pd).rename(enduses)
        if "query_id" in result.columns:
            result = result.drop("query_id")
        if "eiaid" in result.columns:
            result = result.with_columns(pl.col("eiaid").cast(pl.Int64))
    else:
        restrict = []
        if restrict_list:
            restrict = [(db_cols.STATE, restrict_list)]
        result_pd = bsq.query(enduses=tuple(enduses.keys()), group_by=["time", by], restrict=restrict, annual_only=False)
        result = pl.from_pandas(result_pd).rename(enduses)
    bsq.save_cache()
    return result.fill_null(0)


def get_monthly_all(
    by: Literal['state', 'eiaid'] = "state",
    restrict_list: Sequence[str] | None = None) -> pl.DataFrame:
    final_df = None
    for data_source in workflow.data_sources:
        df = get_monthly(data_source, by, restrict_list)
        df = df.rename({col: f"{data_source.name}_{col}" for col in df.columns if col not in {by, "month"}})
        final_df = df if final_df is None else final_df.join(df, on=[by, "month"], how="outer")
    assert final_df is not None
    return final_df


def get_monthly(
    data_source: DataSourceConfig,
    by: Literal['state', 'eiaid'] = "state",
    restrict_list: Sequence[str] | None = None,
) -> pl.DataFrame:
    """Aggregate monthly data from timeseries."""
    ts_data = get_timeseries(data_source, by, restrict_list)
    db_cols = get_db_column_names(data_source.db_schema)
    enduses = {db_cols.ELECTRICITY_TOTAL: 'electricity_kwh',
               db_cols.NATURAL_GAS_TOTAL: 'natural_gas_kwh'}
    ts_data = ts_data.with_columns(pl.col(db_cols.TIMESTAMP).dt.month().alias("month"))
    ts_data = ts_data.with_columns(pl.col("month").replace_strict(NUM2MONTH, default=None))
    group_cols = [by, "month"]
    agg_exprs = [pl.col(e).sum().alias(e) for e in enduses.values()]

    if "sample_count" in ts_data.columns:
        agg_exprs.append(pl.col("sample_count").first().alias("sample_count"))
    if "units_count" in ts_data.columns:
        agg_exprs.append(pl.col("units_count").first().alias("units_count"))

    return ts_data.group_by(group_cols).agg(agg_exprs)


def get_annual_all(
    by: Literal['state', 'eiaid'] = "state",
) -> pl.DataFrame:
    final_df = None
    for data_source in workflow.data_sources:
        df = get_annual(data_source, by)
        df = df.rename({col: f"{data_source.name}_{col}" for col in df.columns if col != by})
        final_df = df if final_df is None else final_df.join(df, on=[by], how="outer")
    assert final_df is not None
    return final_df

def get_annual(
    data_source: DataSourceConfig,
    by: Literal['state', 'eiaid'] = "state",
    year: int = 2018,
) -> pl.DataFrame:
    """Get annual retail sales aggregated by geography and scaled to EIA customer counts."""
    bsq = get_buildstock_query(
            workgroup=workflow.workgroup,
            config=data_source,
            truth_data_year=workflow.reference_data.truth_data_year,
            eia_mapping_version=workflow.reference_data.eia_mapping_version,
            skip_reports=True,
        )
    db_cols = get_db_column_names(data_source.db_schema)
    enduses = {db_cols.ELECTRICITY_TOTAL: 'electricity_kwh',
               db_cols.NATURAL_GAS_TOTAL: 'natural_gas_kwh'}
    if by == "eiaid":
        result_pd = bsq.utility.aggregate_annual_by_eiaid(enduses=tuple(enduses.keys()))
        resstock_sales = pl.from_pandas(result_pd)
        if "eiaid" in resstock_sales.columns:
            resstock_sales = resstock_sales.with_columns(pl.col("eiaid").cast(pl.Int64))
        resstock_sales = resstock_sales.rename(enduses).group_by("eiaid").sum()
    else:
        result_pd = bsq.query(enduses=tuple(enduses.keys()), group_by=[db_cols.STATE])
        resstock_sales = pl.from_pandas(result_pd).rename(enduses).group_by('state').sum()

    return resstock_sales


def get_customer_counts_all(
    by: Literal['state', 'eiaid'] = "state",
) -> pl.DataFrame:
    final_df = None
    for data_source in workflow.data_sources:
        bsq = get_buildstock_query(
            data_source,
            truth_data_year=workflow.reference_data.truth_data_year,
            eia_mapping_version=workflow.reference_data.eia_mapping_version,
            skip_reports=True,
        )
        df = get_customer_counts(bsq, by)
        df = df.rename({col: f"{data_source.name}_{col}" for col in df.columns if col != by})
        final_df = df if final_df is None else final_df.join(df, on=[by], how="outer")
    assert final_df is not None
    return final_df


def get_customer_counts(bsq: BuildStockQuery, by: Literal['state', 'eiaid'] = "state") -> pl.DataFrame:
    """Get customer counts from both BuildStock and EIA data."""
    if by == "eiaid":
        res_counts = pl.from_pandas(bsq.utility.aggregate_unit_counts_by_eiaid())
        res_counts = res_counts.with_columns(pl.col("eiaid").cast(pl.Int64))
    else:
        res_counts = pl.from_pandas(bsq.query(enduses=[], group_by=["state"], get_query_only=False))
    return res_counts
