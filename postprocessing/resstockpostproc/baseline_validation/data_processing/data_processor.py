"""Pure transformation functions for processing BuildStock data for baseline validation."""

from typing import Literal

import polars as pl

from resstockpostproc.baseline_validation.utils import NUM2MONTH
from resstockpostproc.baseline_validation.schema.plot_spec import PlotSpec
from resstockpostproc.baseline_validation.io_managers import get_eia_data as eia_data
from resstockpostproc.baseline_validation.io_managers import get_resstock_data as res_data
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow

AggregationBy = Literal["state", "eiaid"]

def get_plot_data(
        plot_spec: PlotSpec,
) -> pl.DataFrame:
    """Get the data for plotting based on the plot specification."""
    groups = []
    if plot_spec.truth_source == "eia":
        assert plot_spec.aggregation_level in ['state', 'eiaid'], "EIA data only supports 'state' or 'eiaid' aggregation levels."
        by = "state" if plot_spec.aggregation_level == "state" else "eiaid"
        if plot_spec.resolution == "monthly":
            source_data = eia_data.get_monthly_all(year=workflow.reference_year, by=by)
            resstock_data = res_data.get_monthly_all(by=by)
            groups = [by, "month"]
        else:
            source_data = eia_data.get_annual_all(year=workflow.reference_year, by=by)
            resstock_data = res_data.get_annual_all(by=by)
            groups = [by]
    else:
        raise NotImplementedError(f"Truth source {plot_spec.truth_source} not implemented.")
    merged = resstock_data.join(source_data, on=groups, how="outer", suffix="_eia")
    return merged.fill_null(0)
    
def scale_to_eia_customers(
    buildstock_df: pl.DataFrame,
    eia_df: pl.DataFrame,
    by: AggregationBy = "state",
) -> pl.DataFrame:
    """Scale BuildStock data to match EIA customer counts."""
    eia_customers = eia_df.group_by(by).agg(pl.col("customers").sum().alias("customers"))
    scaled = buildstock_df.join(eia_customers, on=by, how="left")
    scaled = scaled.with_columns((pl.col("customers") / pl.col("units_count")).alias("customer_factor"))

    exclude_cols = {by, "sample_count", "units_count", "customers", "customer_factor", "month", "time"}
    numeric_cols = [col for col in scaled.columns if col not in exclude_cols and scaled[col].dtype.is_numeric()]

    scale_exprs = [
        pl.when(pl.col("customer_factor").is_not_null())
        .then(pl.col(col) * pl.col("customer_factor"))
        .otherwise(pl.col(col))
        .alias(col)
        for col in numeric_cols
    ]

    return scaled.with_columns(scale_exprs)


