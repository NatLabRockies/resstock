"""Plot configuration derived from PlotSpec for rendering.

This module provides the PlotConfig dataclass and builder functions that
translate a PlotSpec into rendering-ready configuration.

Architecture:
    build_plot_config() composes focused resolver functions, each handling
    one aspect of the config. Each resolver internally dispatches based on
    comparison_dataset, resolution, and view_type.
"""

from dataclasses import dataclass

import polars as pl

from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    Metric,
    CoverageType,
    ViewType,
    Layout,
    ComparisonDataset,
    Resolution,
    format_group_by,
)
from resstockpostproc.shared_utils.db_column_names import DataCol


@dataclass(frozen=True)
class PlotConfig:
    """Fully resolved configuration for rendering a plot.

    This is an intermediate representation between PlotSpec (user-facing)
    and the actual rendering calls. It contains all the derived values
    needed to call the rendering functions.
    """

    # Column names
    quantity_column: str
    sidebar_column: str | None
    rse_column: str | None
    timeseries_column: str | None

    # Titles and labels
    title: str
    quantity_title: str
    sidebar_title: str

    # Axis configuration
    ts_xtick_vals: tuple | None
    ts_xtick_text: tuple | None
    x_unit: str

    # Layout dimensions
    height: float
    width: float

    # Rendering mode flags
    uses_stacked_layout: bool
    is_single_entity: bool


# ─────────────────────────────────────────────────────────────────────────────
# Main Entry Point
# ─────────────────────────────────────────────────────────────────────────────


def build_plot_config(plot_spec: PlotSpec, data: pl.DataFrame) -> PlotConfig:
    """Build a PlotConfig from a PlotSpec and data.

    Composes focused resolver functions to build each config field.
    Post-processing handles view-type swapping and monthly sidebar clearing.

    Args:
        plot_spec: The plot specification
        data: The prepared DataFrame (used to check for single-entity rendering)

    Returns:
        PlotConfig with all rendering parameters resolved
    """
    # Resolve all config fields
    quantity_column = _resolve_quantity_column(plot_spec)
    sidebar_column = _resolve_sidebar_column(plot_spec)
    rse_column = _resolve_rse_column(plot_spec)
    timeseries_column = _resolve_timeseries_column(plot_spec)
    title = plot_spec.display_title
    quantity_title = _resolve_quantity_title(plot_spec)
    comparison_label = _extract_comparison_dataset_label(plot_spec.comparison_dataset, data) if sidebar_column else ""
    sidebar_title = _resolve_sidebar_title(plot_spec, comparison_label)
    ts_xtick_vals, ts_xtick_text = _resolve_tick_config(plot_spec, data)
    x_unit = _resolve_x_unit(plot_spec)
    uses_stacked_layout = _uses_stacked_layout(plot_spec)
    is_single_entity = _check_single_entity(data, plot_spec, timeseries_column)
    height, width = _resolve_dimensions(plot_spec, is_single_entity)

    # Post-processing: diff_view swaps quantity <-> sidebar
    if plot_spec.view == ViewType.diff_view and sidebar_column:
        quantity_column, sidebar_column = sidebar_column, quantity_column
        sidebar_title = quantity_title
        quantity_title = "% diff"
        title = _resolve_diff_view_title(plot_spec, comparison_label)
        rse_column = None

    # Post-processing: monthly resolution clears sidebar (RECS/EIA only)
    if plot_spec.resolution == Resolution.month and plot_spec.comparison_dataset != ComparisonDataset.lrd:
        sidebar_column = None
        sidebar_title = ""

    return PlotConfig(
        quantity_column=quantity_column,
        sidebar_column=sidebar_column,
        rse_column=rse_column,
        timeseries_column=timeseries_column,
        title=title,
        quantity_title=quantity_title,
        sidebar_title=sidebar_title,
        ts_xtick_vals=ts_xtick_vals,
        ts_xtick_text=ts_xtick_text,
        x_unit=x_unit,
        height=height,
        width=width,
        uses_stacked_layout=uses_stacked_layout,
        is_single_entity=is_single_entity,
    )


# ─────────────────────────────────────────────────────────────────────────────
# Resolver Functions
# ─────────────────────────────────────────────────────────────────────────────


def _resolve_quantity_column(plot_spec: PlotSpec) -> str:
    """Resolve the main quantity column name.

    LRD: Simple pattern with special case for temp_count_view.
    RECS/EIA: Handles units_count, quartiles, percent_users, and value columns.
    """
    # LRD: simple pattern
    if plot_spec.comparison_dataset == ComparisonDataset.lrd:
        if plot_spec.view == ViewType.temp_distribution_view:
            return "temp_count"
        return f"{plot_spec.quantity}_value"

    # RECS/EIA: dwelling unit count case
    if plot_spec.quantity == DataCol.UNITS_COUNT:
        return "units_count"

    # RECS/EIA: distribution box plot uses quartiles
    if plot_spec.is_distribution_metric:
        if plot_spec.coverage == CoverageType.users_only:
            return f"{plot_spec.quantity}_nonzero_quartiles"
        return f"{plot_spec.quantity}_quartiles"

    # RECS/EIA: penetration bar plot uses percent_users
    if plot_spec.is_penetration_metric:
        return f"{plot_spec.quantity}_percent_users"

    # Default: value column
    return f"{plot_spec.quantity}_value"


def _resolve_sidebar_column(plot_spec: PlotSpec) -> str | None:
    """Resolve the sidebar column name (percent difference).

    LRD: Only shows sidebar for year resolution.
    RECS/EIA: Distribution views don't have sidebar; others get percent_difference.
    """
    # LRD: sidebar only for year resolution
    if plot_spec.comparison_dataset == ComparisonDataset.lrd:
        if plot_spec.resolution == Resolution.year:
            return f"{plot_spec.quantity}_value_percent_difference"
        return None

    # RECS/EIA: distribution plots don't have sidebar
    if plot_spec.is_distribution_metric:
        return None

    # RECS/EIA: dwelling unit count case
    if plot_spec.quantity == DataCol.UNITS_COUNT:
        return "units_count_percent_difference"

    # RECS/EIA: penetration view uses percent_users difference
    if plot_spec.is_penetration_metric:
        return f"{plot_spec.quantity}_percent_users_percent_difference"

    # Default: value percent difference
    return f"{plot_spec.quantity}_value_percent_difference"


def _resolve_rse_column(plot_spec: PlotSpec) -> str | None:
    """Resolve the RSE (Relative Standard Error) column name.

    Only RECS has RSE columns. Distribution views don't have RSE.
    """
    # Only RECS has RSE
    if plot_spec.comparison_dataset != ComparisonDataset.recs:
        return None

    # Distribution plots don't have RSE
    if plot_spec.is_distribution_metric:
        return None

    # Dwelling unit counts derive from calibrated weights (raked to Census
    # control totals), so jackknife RSE is near-zero and misleading — skip.
    if plot_spec.quantity == DataCol.UNITS_COUNT:
        return None

    # Penetration view uses percent_users RSE
    if plot_spec.is_penetration_metric:
        return f"{plot_spec.quantity}_percent_users_rse"

    # Default: value RSE
    return f"{plot_spec.quantity}_value_rse"


def _resolve_timeseries_column(plot_spec: PlotSpec) -> str | None:
    """Resolve the timeseries/x-axis column name based on resolution.

    Returns the column name that provides the x-axis values for time-based plots.
    """
    match plot_spec.resolution:
        case Resolution.year:
            return None

        case Resolution.month:
            return "month"

        case Resolution.day_of_year:
            return "day of year"

        case Resolution.hour_of_year | Resolution.top_100_hours:
            if plot_spec.view in [ViewType.temp_view, ViewType.temp_distribution_view]:
                return "resstock_temp"
            return "percent_time"

        case Resolution.hour_of_day | Resolution.hour_of_day_summer | Resolution.hour_of_day_winter:
            return plot_spec.resolution

        case Resolution.hour_of_day_matrix:
            return "hour of day"

        case _:
            return None


def _resolve_diff_view_title(plot_spec: PlotSpec, comparison_label: str) -> str:
    """Build the figure title for diff_view plots.

    Reuses the value_view title and wraps it with symmetric percent difference framing.
    """
    base = plot_spec.display_title
    return f"Symmetric Percent Difference on {base}<br> Compared to {comparison_label}"


def _resolve_quantity_title(plot_spec: PlotSpec) -> str:
    """Resolve the y-axis label (quantity units).

    Returns units like kWh, kWh/unit, kWh/user, %, or count.
    """
    # LRD: always per-meter (per dwelling unit), except the temperature distribution count
    if plot_spec.comparison_dataset == ComparisonDataset.lrd:
        if plot_spec.view == ViewType.temp_distribution_view:
            return "count"
        return "kWh/unit"

    # RECS/EIA: dwelling unit count case
    if plot_spec.quantity == DataCol.UNITS_COUNT:
        return "count"

    # RECS/EIA: penetration view shows percentages
    if plot_spec.is_penetration_metric:
        return "%"

    # RECS/EIA: total aggregation
    if plot_spec.aggregation_type == Metric.total:
        return "kWh"

    # RECS/EIA: average aggregation - depends on coverage
    if plot_spec.aggregation_type in (Metric.average, Metric.distribution):
        if plot_spec.coverage == CoverageType.users_only:
            return "kWh/user"
        return "kWh/unit"

    return "kWh"


def _resolve_sidebar_title(plot_spec: PlotSpec, comparison_label: str) -> str:
    """Resolve the sidebar subplot title.

    Returns a full description like 'Symmetric percent difference compared to RECS 2020'.
    """
    if plot_spec.is_distribution_metric:
        return ""
    return f"Symmetric Percent Difference<br>Compared to {comparison_label}"


def _resolve_tick_config(plot_spec: PlotSpec, data: pl.DataFrame) -> tuple[tuple | None, tuple | None]:
    """Resolve x-axis tick values and labels based on resolution.

    Returns (tick_vals, tick_text) tuples or (None, None) for auto-ticks.
    """
    match plot_spec.resolution:
        case Resolution.month:
            return ("JAN", "DEC"), ("   Jan", "Dec   ")

        case Resolution.day_of_year:
            # Let Plotly auto-generate date ticks
            return None, None

        case Resolution.hour_of_year | Resolution.top_100_hours:
            if plot_spec.view in [ViewType.temp_view, ViewType.temp_distribution_view]:
                # Temperature plots use auto-ticks
                return None, None
            # Load duration curve: compute ticks from data
            return _compute_percent_time_ticks(data, plot_spec)

        case Resolution.hour_of_day | Resolution.hour_of_day_summer | Resolution.hour_of_day_winter:
            return (0, 23), ("     Hour 1", "Hour 24       ")

        case Resolution.hour_of_day_matrix:
            return (0, 23), ("     Hour 1", "Hour 24       ")

        case _:
            return None, None


def _compute_percent_time_ticks(data: pl.DataFrame, plot_spec: PlotSpec) -> tuple[tuple | None, tuple | None]:
    """Compute tick values for load duration curve from data."""
    if "percent_time" not in data.columns:
        return None, None

    min_val = data["percent_time"].min()
    max_val = data["percent_time"].max()

    if plot_spec.resolution == Resolution.top_100_hours:
        ts_xtick_text = ("  0%", f"{max_val:.1f}%    ")
    else:
        ts_xtick_text = ("  0%", "100%    ")

    return (min_val, max_val), ts_xtick_text


def _resolve_x_unit(plot_spec: PlotSpec) -> str:
    """Resolve the x-axis unit label.

    Returns '°F' for temperature views, empty string otherwise.
    """
    if plot_spec.view in [ViewType.temp_view, ViewType.temp_distribution_view]:
        return "°F"
    return ""


def _extract_comparison_dataset_label(comparison_dataset: ComparisonDataset, data: pl.DataFrame) -> str:
    """Extract a human-readable comparison dataset label like 'EIA 2018' from data."""
    if "source" not in data.columns:
        return comparison_dataset.value.upper()
    sources = data["source"].unique(maintain_order=True).to_list()
    ref_sources = [s for s in sources if comparison_dataset.value in s.lower()]
    if ref_sources:
        # First match is the primary reference (same insertion order used by _add_percent_difference).
        # Already human-readable after source renaming (e.g. "EIA 2018", "RECS 2020").
        return ref_sources[0]
    return comparison_dataset.value.upper()


def _resolve_dimensions(plot_spec: PlotSpec, is_single_entity: bool) -> tuple[float, float]:
    """Resolve plot height and width based on resolution and entity count.

    Returns (height, width) in pixels.
    """
    # LRD: resolution-specific dimensions
    if plot_spec.comparison_dataset == ComparisonDataset.lrd:
        match plot_spec.resolution:
            case Resolution.hour_of_day_matrix:
                return 1800, 900  # Taller for 13 rows
            case Resolution.day_of_year:
                return 2000, 1400  # Tall for 15 rows, wide for date axis
            case _:
                return 1080 * 0.8, 1920 * 0.7

    # RECS/EIA: single entity gets smaller dimensions (except ALL enduse plots
    # which contain all fuel/enduse combos and need full size)
    if is_single_entity and plot_spec.quantity != DataCol.ALL:
        return 1080 * 0.34, 1920 * 0.4

    return 1080 * 0.75, 1920 * 0.75


# ─────────────────────────────────────────────────────────────────────────────
# Shared Helpers
# ─────────────────────────────────────────────────────────────────────────────


def _uses_stacked_layout(plot_spec: PlotSpec) -> bool:
    """Check if this plot should use stacked subplot layout (one row per entity).

    Returns True for:
    - layout=two_column (forces stacked/two-panel state rendering)
    - ViewType.distribution (box plots)
    - quantity=ALL (enduse bar layout via split_graph_by_enduse)
    - non-state group_by levels (grouped bar/box charts)
    """
    if plot_spec.layout == Layout.two_column:
        return True
    if plot_spec.is_distribution_metric:
        return True
    if plot_spec.quantity == DataCol.ALL:
        return True
    if plot_spec.group_by is None or plot_spec.group_by not in [DataCol.STATE]:
        return True
    return False


def _check_single_entity(data: pl.DataFrame, plot_spec: PlotSpec, timeseries_column: str | None) -> bool:
    """Check if data contains a single entity (triggers simplified rendering)."""
    if plot_spec.group_by is None or plot_spec.group_by not in data.columns:
        return True  # No aggregation = single entity

    unique_entities = data[plot_spec.group_by].unique().to_list()
    return len(unique_entities) == 1


# ─────────────────────────────────────────────────────────────────────────────
# Public Utilities
# ─────────────────────────────────────────────────────────────────────────────


def get_second_category_column(plot_spec: PlotSpec) -> str:
    """Get the column name for the second category (layout grouping).

    This determines which column is used for the tilemap layout.
    Uses group_by if set, otherwise falls back to the DataKey's
    group_by (derived from focus_on columns).
    """
    match plot_spec.resolution:
        case Resolution.hour_of_day_matrix:
            return "month_daytype"
        case Resolution.day_of_year:
            return "utility_vertical"
        case _:
            return plot_spec.group_by or plot_spec.effective_group_by[-1]


def get_second_category_title(plot_spec: PlotSpec) -> str:
    """Get the title for the second category axis."""
    match plot_spec.resolution:
        case Resolution.hour_of_day_matrix:
            return "Month / Day Type"
        case _:
            agg = plot_spec.group_by or plot_spec.effective_group_by[-1]
            if agg == "utility":
                return "Utility (State)"
            return format_group_by(agg)
