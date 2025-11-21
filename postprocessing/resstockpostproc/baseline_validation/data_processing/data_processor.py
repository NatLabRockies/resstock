"""Pure transformation functions for processing BuildStock data for baseline validation."""

from typing import Literal

import polars as pl
from functools import cache
from resstockpostproc.baseline_validation.utils import NUM2MONTH
from resstockpostproc.baseline_validation.schema.plot_spec import PlotSpec
from resstockpostproc.baseline_validation.io_managers import get_eia_data
from resstockpostproc.baseline_validation.io_managers import get_recs_data
from resstockpostproc.baseline_validation.io_managers import get_resstock_data
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow
from resstockpostproc.baseline_validation.schema.plot_spec import QuantityType

from . import recs_mapping

AggregationBy = Literal["state", "eiaid"]


def get_plot_data(
    plot_spec: PlotSpec,
) -> pl.DataFrame:
    """Get the data for plotting based on the plot specification."""
    if plot_spec.quantity_type in [
        QuantityType.per_unit_energy,
        QuantityType.per_unit_energy_distribution
    ]:
        aggregation = "avg"
    else:
        aggregation = "sum"

    df = _get_plot_data(plot_spec.truth_source,
                          plot_spec.aggregation_level,
                          plot_spec.resolution,
                          aggregation=aggregation)
    return df


@cache
def _get_plot_data(
        truth_source,
        aggregation_level,
        resolution,
        aggregation: Literal["sum", "avg"] = "sum"
) -> pl.DataFrame:
    groups = []
    if truth_source == "eia":
        assert aggregation_level in ['state', 'eiaid'], "EIA data only supports 'state' or 'eiaid' aggregation levels."
        by = "state" if aggregation_level == "state" else "eiaid"
        if resolution == "monthly":
            source_data = get_eia_data.get_monthly_all(years=workflow.reference_years.get("eia", [2018]), by=by)
            resstock_data = get_resstock_data.get_monthly_all(by=by, aggregation=aggregation)
            groups = [by, "month"]
        else:
            source_data = get_eia_data.get_annual_all(years=workflow.reference_years.get("eia", [2018]), by=by)
            resstock_data = get_resstock_data.get_annual_all(by=by, aggregation=aggregation)
            groups = [by]
    elif truth_source == "recs":
        if resolution == "monthly":
            assert aggregation_level in ["state"], "RECS data only supports 'state' aggregation level."
            source_data = get_recs_data.get_monthly_all(year=2020, by="state", aggregation=aggregation)
            resstock_data = get_resstock_data.get_monthly_all(by="state", occupied_only=True, aggregation=aggregation)
            groups = ["state", "month"]
        else:
            assert aggregation_level in ["state"], "RECS data only supports 'state' aggregation level."
            by = "state"
            source_data = get_recs_data.get_annual_all(year=2020, by=by, aggregation=aggregation)
            resstock_data = get_resstock_data.get_annual_all(by=by, occupied_only=True, aggregation=aggregation)
            groups = [by]
        # resstock_data = recs_mapping.add_enduse_columns(resstock_data)
        # resstock_data = recs_mapping.add_characteristic_columns(resstock_data)
    else:
        raise NotImplementedError(f"Truth source {truth_source} not implemented.")
    merged = source_data.join(resstock_data, on=groups, how="outer", coalesce=True)
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


