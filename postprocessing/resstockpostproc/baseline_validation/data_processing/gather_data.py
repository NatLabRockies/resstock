"""Pure transformation functions for processing BuildStock data for baseline validation."""

from typing import Literal

import polars as pl
from functools import cache
from resstockpostproc.baseline_validation.utils import NUM2MONTH

from resstockpostproc.baseline_validation.schema.plot_spec import PlotSpec, Resolution
from resstockpostproc.baseline_validation.io_managers import get_eia_data
from resstockpostproc.baseline_validation.io_managers import get_recs_data
from resstockpostproc.baseline_validation.io_managers import get_resstock_data
from resstockpostproc.baseline_validation.io_managers import get_lrd_data
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow
from resstockpostproc.baseline_validation.schema.plot_spec import AggregationType
from resstockpostproc.baseline_validation.schema.recs_enduse_mapping import RECS_ENDUSE_MAP
from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.shared_utils.mapping import UtilityName2ID, ID2UtilityName

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
    df = _add_95ci_bounds(df)
    df = df.with_columns(
        pl.col("units_count").mean().over(plot_spec.aggregation_level).alias("avg_units_count")
    ).sort("avg_units_count", descending=True, maintain_order=True).drop("avg_units_count")

    if "eiaid" in df.columns and plot_spec.aggregation_level == "eiaid":
        df = df.with_columns(
            pl.col("eiaid").cast(pl.Int16)
            .replace_strict(ID2UtilityName, default="Unknown Utility").alias("utility_name")
        )
    return df


#@cache
def _get_plot_data(
        truth_source,
        aggregation_level,
        resolution: Resolution,
        aggregation: Literal["sum", "per_unit_avg", "per_user_avg"] = "sum"
) -> pl.DataFrame:
    groups = []
    if truth_source == "eia":
        assert aggregation_level in ['state', 'eiaid'], "EIA data only supports 'state' or 'eiaid' aggregation levels."
        by = "state" if aggregation_level == "state" else "eiaid"
        if resolution == "month":
            source_data = get_eia_data.get_monthly_all(years=workflow.reference_years.get("eia", [2018]), by=by,
                                                       aggregation=aggregation)
            resstock_data = get_resstock_data.get_timeseries_all(by=by, aggregation=aggregation)
            groups = [by, "month"]
        else:
            assert resolution == "year", "EIA data only supports 'year' or 'month' resolutions."
            source_data = get_eia_data.get_annual_all(years=workflow.reference_years.get("eia", [2018]), by=by,
                                                      aggregation=aggregation)
            resstock_data = get_resstock_data.get_annual_all(by=by, aggregation=aggregation)
            groups = [by]
    elif truth_source == "recs":
        if resolution == "month":
            assert aggregation_level in ["state"], "RECS data only supports 'state' aggregation level for monthly."
            source_data = get_recs_data.get_monthly_all(year=2020, by="state", aggregation=aggregation)
            resstock_data = get_resstock_data.get_timeseries_all(by="state", occupied_only=True, aggregation=aggregation)
            groups = ["state", "month"]
        else:
            assert resolution == "year", "RECS data only supports 'year' or 'month' resolutions."
            source_data = get_recs_data.get_annual_all(year=2020, by=aggregation_level, aggregation=aggregation)
            resstock_data = get_resstock_data.get_annual_all(by=aggregation_level, occupied_only=True, aggregation=aggregation)
            groups = [aggregation_level]
    elif truth_source == "lrd":
        assert aggregation == "per_unit_avg", "LRD data only supports 'per_unit_avg' aggregation."
        eiaidlist = tuple([str(eiaid) for eiaid in UtilityName2ID.values()])
        source_data = get_lrd_data.get_lrd_aggregated(year=2018, resolution=resolution,
                                                      restrict_list=eiaidlist)
        if resolution == "year":
            resstock_data = get_resstock_data.get_annual_all(by="eiaid", aggregation=aggregation)
            groups = ["eiaid"]
        else:
            resstock_data = get_resstock_data.get_timeseries_all(by="eiaid", occupied_only=False,
                                                                 aggregation=aggregation,
                                                                 restrict_list=eiaidlist,
                                                                 resolution=resolution)
            groups = ["eiaid", resolution]
        # resstock_data = recs_mapping.add_enduse_columns(resstock_data)

    else:
        raise NotImplementedError(f"Truth source {truth_source} not implemented.")
    # resstock_data = recs_mapping.add_characteristic_columns(resstock_data, data_source="ResStock")
    df = pl.concat([source_data, resstock_data], how="diagonal_relaxed")
    val_columns = [col for col in df.columns if col.endswith(("_value", "_percent_users"))]
    val_columns += ["units_count"]
    ref_cols = [col for col in df["source"].unique() if truth_source in col]
    final_df = _add_percent_difference(df, join_columns=groups, value_columns=val_columns, ref_column="source",
                                       ref_val=ref_cols[0])
    final_df = final_df.rename({"sample_count": "model_count"})
    return final_df


def _add_percent_difference(df: pl.DataFrame, join_columns: list[str], value_columns: list[str], ref_column: str, ref_val: str) -> pl.DataFrame:
    ref_df = df.filter(pl.col(ref_column) == ref_val).select(join_columns + value_columns)
    full_df = df.join(ref_df, on=join_columns, suffix="_ref")
    result = full_df.with_columns(
        pl.when(pl.col(ref_column) != ref_val)
        .then((pl.col(f"{value_column}") - pl.col(f"{value_column}_ref")) / pl.col(f"{value_column}_ref") * 100)
        .otherwise(None)
        .alias(f"{value_column}_percent_difference")
        for value_column in value_columns
    )
    # Drop the reference columns
    ref_columns_to_drop = [f"{value_column}_ref" for value_column in value_columns]
    return result.drop(ref_columns_to_drop)

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
    all_output_columns = [
        col for col in df.columns 
        if col.endswith(("_value", "_percent_users", "_quartiles", "_percent_difference",
                                                    "_resoluition", "_rse")) 
        and not col.startswith("units_count")
    ]
    if plot_spec.quantity is not None:
        drop_columns = [col for col in all_output_columns if plot_spec.quantity.value not in col]
        if DataCol.OUTDOOR_DRYBULB_TEMP + "_value" in drop_columns:
            drop_columns.remove(DataCol.OUTDOOR_DRYBULB_TEMP + "_value")  # Keep temperature column for LRD plots
        df = df.drop(drop_columns)
        return df
    if plot_spec.truth_source == "eia":
        relevant_quatities = [
            DataCol.ELECTRICITY_TOTAL,
            DataCol.NATURAL_GAS_TOTAL,
        ]
    elif plot_spec.truth_source == "recs":
        relevant_quatities = list(RECS_ENDUSE_MAP.keys())
    elif plot_spec.truth_source == "lrd":
        relevant_quatities = [DataCol.ELECTRICITY_TOTAL, DataCol.OUTDOOR_DRYBULB_TEMP]
    else:
        raise NotImplementedError(f"Truth source {plot_spec.truth_source} not implemented.")
    to_drop_columns = []
    for col in all_output_columns:
        if not any(q.value in col for q in relevant_quatities):
            to_drop_columns.append(col)
    df = df.drop(to_drop_columns)
    return df


def _add_95ci_bounds(
    df: pl.DataFrame,
) -> pl.DataFrame:
    """Add RSE-based upper and lower 95% confidence intervals to the DataFrame."""
    rse_columns = [col for col in df.columns if col.endswith("_rse")]
    for rse_col in rse_columns:
        base_col = rse_col.removesuffix("_rse")
        upper_col = rse_col.replace("_rse", "_upper_bound")
        lower_col = rse_col.replace("_rse", "_lower_bound")
        df = df.with_columns(
            (
                pl.col(base_col) + (pl.col(base_col) * pl.col(rse_col).fill_null(0).abs() / 100.0 * 1.96)
            ).alias(upper_col),
            (
                pl.col(base_col) - (pl.col(base_col) * pl.col(rse_col).fill_null(0).abs() / 100.0 * 1.96)
            ).alias(lower_col),
        )
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


