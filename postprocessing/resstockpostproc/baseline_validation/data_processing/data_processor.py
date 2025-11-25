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
from resstockpostproc.baseline_validation.schema.plot_spec import AggregationType
from resstockpostproc.baseline_validation.schema.recs_enduse_mapping import RECS_ENDUSE_MAP
from resstockpostproc.shared_utils.db_column_names import DataCol

from . import recs_mapping

AggregationBy = Literal["state", "eiaid"]


def get_plot_data(
    plot_spec: PlotSpec,
) -> pl.DataFrame:
    """Get the data for plotting based on the plot specification."""
    if plot_spec.aggregation_type in [AggregationType.per_unit,
                                    AggregationType.per_unit_distribution]:
        aggregation = "per_unit_avg"
    elif plot_spec.aggregation_type in [AggregationType.per_user,
                                     AggregationType.per_user_distribution]:
        aggregation = "per_user_avg"
    else:
        aggregation = "sum"

    df = _get_plot_data(plot_spec.truth_source,
                          plot_spec.aggregation_level,
                          plot_spec.resolution,
                          aggregation=aggregation)
    df = _keep_relevant_columns(df, plot_spec)
    return df


@cache
def _get_plot_data(
        truth_source,
        aggregation_level,
        resolution,
        aggregation: Literal["sum", "per_unit_avg", "per_user_avg"] = "sum"
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
    merged = pl.concat([source_data, resstock_data], how="diagonal_relaxed").fill_null(0)
    df = _pivot_enduse_columns(merged, groups)
    return df


def _pivot_enduse_columns(df: pl.DataFrame, groups: list) -> pl.DataFrame:
    """Pivot enduse columns to have unified column names."""
    index_cols = groups + ["units_count", "sample_count", "source", "quantity_type"]
    df = df.unpivot(
        index=index_cols,
        variable_name="quantity",
        value_name="value"
    )
    return df

def _keep_relevant_columns(
    df: pl.DataFrame,
    plot_spec: PlotSpec,
) -> pl.DataFrame:
    """Keep only the relevant columns for the given plot specification."""
    all_output_columns = [col for col in df.columns if col.endswith(("_value", "_customers", "_quartiles"))]
    if plot_spec.quantity is not None:
        drop_columns = [col for col in all_output_columns if plot_spec.quantity.value not in col]
        df = df.drop(drop_columns)
        return df
    if plot_spec.truth_source == "eia":
        relevant_quatities = [
            DataCol.ELECTRICITY_TOTAL,
            DataCol.NATURAL_GAS_TOTAL,
        ]
    elif plot_spec.truth_source == "recs":
        relevant_quatities = list(RECS_ENDUSE_MAP.keys())
    else:
        raise NotImplementedError(f"Truth source {plot_spec.truth_source} not implemented.")
    to_drop_columns = []
    for col in all_output_columns:
        if not any(q.value in col for q in relevant_quatities):
            to_drop_columns.append(col)
    df = df.drop(to_drop_columns)
    return df


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


