"""Pure transformation functions for processing BuildStock data for baseline validation."""

from typing import Literal

import polars as pl
from functools import cache

from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    DataKey,
    Resolution,
    ViewType,
    Layout,
    ComparisonDataset,
    Metric,
    CoverageType,
)
from resstockpostproc.baseline_validation.io_managers import get_eia_data
from resstockpostproc.baseline_validation.io_managers import get_recs_data
from resstockpostproc.baseline_validation.io_managers import get_resstock_data
from resstockpostproc.baseline_validation.io_managers import get_lrd_data
from resstockpostproc.baseline_validation.data_processing.histogram_data import get_distribution_histogram_data
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow
from resstockpostproc.baseline_validation.schema.recs_enduse_mapping import RECS_ENDUSE_MAP
from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.shared_utils.mapping import UtilityName2ID, ID2UtilityName
from resstockpostproc.shared_utils.timing import timed

AggregationBy = Literal["state", "eiaid"]  # IO-layer type: raw DB column names

# Translation from config-level group_by names to raw DB column names.
# The config layer uses "utility"; the IO layer (queries, DataFrames pre-mapping) uses "eiaid".
_CONFIG_TO_IO_COL = {"utility": "eiaid"}


@timed
def get_plot_data(
    plot_spec: PlotSpec,
) -> pl.DataFrame:
    """Get the data for plotting based on the plot specification.

    This is the legacy interface that loads data and applies plot-specific operations.
    For batch processing, prefer using get_base_data() + apply_plot_spec() separately.
    """
    if plot_spec.layout == Layout.histogram:
        if not plot_spec.is_distribution_metric:
            raise ValueError("layout=histogram is only supported for distribution plots.")
        return get_distribution_histogram_data(plot_spec)

    data_key = plot_spec.data_key
    base_data = get_base_data(data_key)
    return apply_plot_spec(base_data, plot_spec)


@timed
@cache
def get_base_data(data_key: DataKey) -> pl.DataFrame:
    """Load base data for a given data key (expensive operation).

    This function loads the raw data that can be shared across multiple plots.
    It should be called once per unique DataKey.

    The returned DataFrame contains all quantities and is not filtered by plot_spec.
    Use apply_plot_spec() to apply plot-specific transformations.

    Args:
        data_key: DataKey containing comparison_dataset, group_by, resolution,
                  aggregation_type, and coverage
    """
    return _get_plot_data(data_key)


@timed
def apply_plot_spec(base_data: pl.DataFrame, plot_spec: PlotSpec) -> pl.DataFrame:
    """Apply plot-specific transformations to base data (cheap operations).

    This function performs only the lightweight operations that depend on plot_spec:
    - Column filtering based on quantity
    - Adding confidence interval bounds
    - Sorting by units_count
    - Adding utility names
    - Filtering by focus_on
    - LRD-specific resolution transforms (temperature view, load duration curve, etc.)

    Args:
        base_data: DataFrame returned by get_base_data()
        plot_spec: The specific plot specification

    Returns:
        DataFrame ready for plotting
    """
    df = _keep_relevant_columns(base_data, plot_spec)
    # Sort by units_count within the primary grouping column (if any)
    sort_col = plot_spec.group_by or (plot_spec.effective_group_by[0] if plot_spec.effective_group_by else None)
    if sort_col and sort_col in df.columns:
        df = (
            df.with_columns(pl.col("units_count").mean().over(sort_col).alias("avg_units_count"))
            .sort("avg_units_count", descending=True, maintain_order=True)
            .drop("avg_units_count")
        )

    if "eiaid" in df.columns and "utility" in plot_spec.effective_group_by:
        df = df.with_columns(
            pl.col("eiaid")
            .cast(pl.Int16)
            .replace_strict(ID2UtilityName, default="Unknown Utility")
            .alias("utility")
        )

    # Apply focus_on post-filters.
    # For cross-dimension filters (multi-column group_by), drop the filtered column
    # so downstream layout logic doesn't pick the wrong grouping dimension.
    data_key = plot_spec.data_key
    is_multi_col = len(data_key.effective_group_by) > 1
    is_us_total_focus = any(val == "US Total" for _, val in plot_spec.focus_on)
    for col, val in plot_spec.focus_on:
        if col in df.columns:
            df = df.filter(pl.col(col) == val)
            if is_multi_col and plot_spec.group_by is not None and col != plot_spec.group_by:
                df = df.drop(col)

    # When focus_on filters are active (e.g. "Building Type: Mobile Home"),
    # "US Total" rows in the group_by column are actually filtered-subset
    # totals, not true US totals.  Remove them to avoid misleading labels.
    if plot_spec.focus_on and not is_us_total_focus and plot_spec.group_by and plot_spec.group_by in df.columns:
        df = df.filter(pl.col(plot_spec.group_by) != "US Total")

    # Apply LRD-specific resolution transforms
    if plot_spec.comparison_dataset == ComparisonDataset.lrd:
        df = _apply_lrd_resolution_transforms(df, plot_spec)

    # Rename source column values to human-readable labels from workflow config.
    # This makes plot legends, CSV exports, and data tables all use consistent
    # display labels (e.g. "eia_2018" → "EIA 2018", "resstock_2025" → "ResStock 2025").
    source_label_map = {k: v.label for k, v in workflow.data_source_labels.items()}
    if source_label_map and "source" in df.columns:
        df = df.with_columns(
            pl.col("source").replace_strict(source_label_map, default=pl.col("source"))
        )

    # For users_only coverage, the displayed count should reflect only nonzero
    # rows for the current quantity (not the total group size). Overwrite
    # model_count with the quantity-specific nonzero count when available.
    # ALL-enduse plots keep the total; the grouped plotter substitutes per-enduse
    # counts from {quantity}_nonzero_sample_count itself.
    if (
        plot_spec.coverage == CoverageType.users_only
        and plot_spec.quantity != DataCol.ALL
        and "model_count" in df.columns
    ):
        nonzero_col = f"{plot_spec.quantity}_nonzero_sample_count"
        if nonzero_col in df.columns:
            df = df.with_columns(pl.col(nonzero_col).alias("model_count"))

    return df


@timed
def _get_plot_data(data_key: DataKey) -> pl.DataFrame:
    """Internal function to load data based on DataKey.

    Args:
        data_key: DataKey containing comparison_dataset, effective_group_by, resolution,
                  aggregation_type, and coverage
    """
    comparison_dataset = data_key.comparison_dataset
    group_by = data_key.effective_group_by  # local alias for readability
    resolution = data_key.resolution

    # Translate config-level column names to IO-level (e.g. "utility" → "eiaid")
    io_group_by = tuple(_CONFIG_TO_IO_COL.get(c, c) for c in group_by)
    io_data_key = data_key._replace(effective_group_by=io_group_by) if io_group_by != group_by else data_key

    groups = []
    if comparison_dataset == ComparisonDataset.eia:
        by = "state" if "state" in io_group_by else "eiaid"
        assert by in ["state", "eiaid"], "EIA data only supports group_by='state' or group_by='eiaid'."
        if resolution == Resolution.month:
            source_data = get_eia_data.get_monthly_all(
                data_key=io_data_key, years=workflow.reference_years.get("eia", [2018])
            )
            resstock_data = get_resstock_data.get_timeseries_all(data_key=io_data_key)
            groups = [by, "month"]
        else:
            assert resolution == Resolution.year, "EIA data only supports 'year' or 'month' resolutions."
            source_data = get_eia_data.get_annual_all(
                data_key=io_data_key, years=workflow.reference_years.get("eia", [2018])
            )
            resstock_data = get_resstock_data.get_annual_all(data_key=io_data_key)
            groups = [by]
    elif comparison_dataset == ComparisonDataset.recs:
        if resolution == Resolution.month:
            assert len(group_by) == 1, "RECS monthly only supports single-column groupby."
            source_data = get_recs_data.get_monthly_all(data_key=io_data_key, year=2020)
            resstock_data = get_resstock_data.get_timeseries_all(data_key=io_data_key, occupied_only=True)
            groups = ["state", "month"]
        else:
            assert resolution == Resolution.year, "RECS data only supports 'year' or 'month' resolutions."
            source_data = get_recs_data.get_annual_all(data_key=io_data_key, year=2020)
            resstock_data = get_resstock_data.get_annual_all(data_key=io_data_key, occupied_only=True)
            groups = list(io_group_by)
    elif comparison_dataset == ComparisonDataset.lrd:
        assert data_key.aggregation_type == Metric.average and data_key.coverage == CoverageType.all_units, (
            "LRD data only supports 'average' aggregation with 'all_units' coverage."
        )
        eiaidlist = tuple([str(eiaid) for eiaid in UtilityName2ID.values()])
        source_data = get_lrd_data.get_lrd_aggregated(year=2018, resolution=resolution, restrict_list=eiaidlist)
        if resolution == Resolution.year:
            resstock_data = get_resstock_data.get_annual_all(data_key=io_data_key)
            groups = ["eiaid"]
        elif resolution == Resolution.hour_of_day_matrix:
            resstock_data = get_resstock_data.get_timeseries_all(data_key=io_data_key, restrict_list=eiaidlist)
            groups = ["eiaid", "month", "day_type", "hour of day"]
        else:
            resstock_data = get_resstock_data.get_timeseries_all(data_key=io_data_key, restrict_list=eiaidlist)
            groups = ["eiaid", resolution]

    else:
        raise NotImplementedError(f"Comparison dataset {comparison_dataset} not implemented.")
    if resstock_data is not None:
        df = pl.concat([source_data, resstock_data], how="diagonal_relaxed")
    else:
        df = source_data
    val_columns = [col for col in df.columns if col.endswith(("_value", "_percent_users"))]
    val_columns += ["units_count"]
    ref_cols = [col for col in df["source"].unique(maintain_order=True) if comparison_dataset in col]
    final_df = _add_percent_difference(
        df, join_columns=groups, value_columns=val_columns, ref_column="source", ref_cols=ref_cols
    )
    if "sample_count" in final_df.columns:
        final_df = final_df.rename({"sample_count": "model_count"})
    elif "model_count" not in final_df.columns:
        final_df = final_df.with_columns(pl.lit(None).cast(pl.Int64).alias("model_count"))
    return final_df


def _add_percent_difference(
    df: pl.DataFrame, join_columns: list[str], value_columns: list[str], ref_column: str, ref_cols: list[str]
) -> pl.DataFrame:
    """Add signed percent difference columns against the reference source."""
    ref_val = ref_cols[0]
    ref_df = df.filter(pl.col(ref_column) == ref_val).select(join_columns + value_columns)
    full_df = df.join(ref_df, on=join_columns, suffix="_ref")
    result = full_df.with_columns(
        pl.when(~pl.col(ref_column).is_in(ref_cols[:1]))
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
    df = df.unpivot(index=index_cols, variable_name="quantity", value_name="value")
    return df


def _keep_relevant_columns(
    df: pl.DataFrame,
    plot_spec: PlotSpec,
) -> pl.DataFrame:
    """Keep only the relevant columns for the given plot specification."""
    all_output_columns = [
        col
        for col in df.columns
        if col.endswith(
            (
                "_value",
                "_percent_users",
                "_quartiles",
                "_percent_difference",
                "_value_resolution",
                "_upper_bound",
                "_lower_bound",
            )
        )
        and not col.startswith("units_count")
    ]
    if plot_spec.quantity != DataCol.ALL:
        drop_columns = [col for col in all_output_columns if plot_spec.quantity.value not in col]
        if DataCol.OUTDOOR_DRYBULB_TEMP + "_value" in drop_columns:
            drop_columns.remove(DataCol.OUTDOOR_DRYBULB_TEMP + "_value")  # Keep temperature column for LRD plots
        df = df.drop(drop_columns)
        return df
    if plot_spec.comparison_dataset == "eia":
        relevant_quatities = [
            DataCol.ELECTRICITY_TOTAL,
            DataCol.NATURAL_GAS_TOTAL,
        ]
    elif plot_spec.comparison_dataset == "recs":
        relevant_quatities = list(RECS_ENDUSE_MAP.keys())
    elif plot_spec.comparison_dataset == "lrd":
        relevant_quatities = [DataCol.ELECTRICITY_TOTAL, DataCol.OUTDOOR_DRYBULB_TEMP]
    else:
        raise NotImplementedError(f"Comparison dataset {plot_spec.comparison_dataset} not implemented.")
    to_drop_columns = []
    for col in all_output_columns:
        if not any(q.value in col for q in relevant_quatities):
            to_drop_columns.append(col)
    df = df.drop(to_drop_columns)
    return df


@timed
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


# ─────────────────────────────────────────────────────────────────────────────
# LRD-specific data transforms
# ─────────────────────────────────────────────────────────────────────────────


def _apply_lrd_resolution_transforms(df: pl.DataFrame, plot_spec: PlotSpec) -> pl.DataFrame:
    """Apply LRD-specific transforms based on resolution and view.

    These transforms prepare the data for specific LRD plot types:
    - Temperature view: aggregate by temperature bins
    - Load duration curve: sort and add percent_time column
    - Day of year: rename column for vertical layout
    - Hour of day matrix: create combined month_daytype column
    """
    match plot_spec.resolution:
        case Resolution.hour_of_year | Resolution.top_100_hours:
            if plot_spec.view in [ViewType.temp_view, ViewType.temp_distribution_view]:
                return _prepare_temperature_view(df, plot_spec)
            else:
                return _prepare_load_duration_curve(df, plot_spec)
        case Resolution.day_of_year:
            return _prepare_day_of_year_layout(df)
        case Resolution.hour_of_day_matrix:
            return _prepare_hour_of_day_matrix(df)
        case _:
            return df


def _prepare_temperature_view(df: pl.DataFrame, plot_spec: PlotSpec) -> pl.DataFrame:
    """Transform hourly data for temperature-based plotting.

    Converts temperature from C*4 to F, joins with ResStock reference temperature,
    and aggregates by temperature bins.
    """
    from resstockpostproc.shared_utils.db_column_names import DataCol

    temp_col = f"{DataCol.OUTDOOR_DRYBULB_TEMP}_value"

    # Convert from C*4 to Fahrenheit
    df = df.with_columns((pl.col(temp_col) / 4 * 9 / 5 + 32).round(0).cast(pl.Int32))

    # Get ResStock source for reference temperature
    resstock_src = next(src for src in df["source"].unique(maintain_order=True) if "resstock" in src.lower())

    # Create reference temperature from ResStock data
    ref_temp = df.filter(pl.col("source") == resstock_src).select(
        "utility", pl.col(plot_spec.resolution), pl.col(temp_col).alias("resstock_temp")
    )

    # Join reference temperature to all rows
    df = df.join(ref_temp, on=("utility", plot_spec.resolution), how="left")

    # Sort by temperature
    df = df.sort("source", "utility", "resstock_temp", descending=[False, False, False], maintain_order=True)

    # Aggregate by temperature bins
    df = df.group_by(["source", "utility", "resstock_temp"], maintain_order=True).agg(
        pl.col(f"{plot_spec.quantity}_value").mean(), pl.count().alias("temp_count")
    )

    return df.sort("source", "utility", "resstock_temp", descending=[False, False, False])


def _prepare_load_duration_curve(df: pl.DataFrame, plot_spec: PlotSpec) -> pl.DataFrame:
    """Sort by value (descending) and add percent_time column for load duration curves."""
    quantity_col = f"{plot_spec.quantity}_value"

    # Sort by value descending within each source/utility
    df = df.sort("source", "utility", quantity_col, descending=[False, False, True])

    # Add percent_time column (percentage of hours at or above this load)
    df = df.with_columns(
        ((pl.int_range(pl.len()) + 1).over("source", "utility") * 100 / (pl.len()).over("source", "utility"))
        .round(3)
        .alias("percent_time")
    )

    # Filter to top 100 hours if requested
    if plot_spec.resolution == Resolution.top_100_hours:
        df = df.filter(pl.col("percent_time") <= 100 * 100 / 8760)

    return df


def _prepare_day_of_year_layout(df: pl.DataFrame) -> pl.DataFrame:
    """Rename utility to utility_vertical for vertical layout."""
    return df.rename({"utility": "utility_vertical"})


def _prepare_hour_of_day_matrix(df: pl.DataFrame) -> pl.DataFrame:
    """Create combined month_daytype column for matrix layout."""
    return df.with_columns((pl.col("month") + "_" + pl.col("day_type")).alias("month_daytype"))
