"""Plot configuration derived from PlotSpec for rendering.

This module provides the PlotConfig dataclass and builder functions that
translate a PlotSpec into rendering-ready configuration.

Architecture:
    build_plot_config() composes focused resolver functions, each handling
    one aspect of the config. Each resolver internally dispatches based on
    truth_source, resolution, and view_type.
"""

from dataclasses import dataclass

import polars as pl

from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    AggregationType,
    CoverageType,
    ViewType,
    TruthSource,
    Resolution,
)
from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.shared_utils.mapping import ABBR2STATE


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
    title = _resolve_title(plot_spec)
    quantity_title = _resolve_quantity_title(plot_spec)
    truth_label = _extract_truth_source_label(plot_spec.truth_source, data) if sidebar_column else ""
    sidebar_title = _resolve_sidebar_title(plot_spec, truth_label)
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
        title = _resolve_diff_view_title(plot_spec, truth_label)
        rse_column = None

    # Post-processing: monthly resolution clears sidebar (RECS/EIA only)
    if plot_spec.resolution == Resolution.month and plot_spec.truth_source != TruthSource.lrd:
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
    if plot_spec.truth_source == TruthSource.lrd:
        if plot_spec.view == ViewType.temp_count_view:
            return "temp_count"
        return f"{plot_spec.quantity}_value"

    # RECS/EIA: dwelling unit count case
    if plot_spec.quantity == DataCol.UNITS_COUNT:
        return "units_count"

    # RECS/EIA: distribution box plot uses quartiles
    if plot_spec.view == ViewType.distribution:
        if plot_spec.coverage == CoverageType.users_only:
            return f"{plot_spec.quantity}_nonzero_quartiles"
        return f"{plot_spec.quantity}_quartiles"

    # RECS/EIA: penetration bar plot uses percent_users
    if plot_spec.view == ViewType.penetration:
        return f"{plot_spec.quantity}_percent_users"

    # Default: value column
    return f"{plot_spec.quantity}_value"


def _resolve_sidebar_column(plot_spec: PlotSpec) -> str | None:
    """Resolve the sidebar column name (percent difference).

    LRD: Only shows sidebar for year resolution.
    RECS/EIA: Distribution views don't have sidebar; others get percent_difference.
    """
    # LRD: sidebar only for year resolution
    if plot_spec.truth_source == TruthSource.lrd:
        if plot_spec.resolution == Resolution.year:
            return f"{plot_spec.quantity}_value_percent_difference"
        return None

    # RECS/EIA: distribution plots don't have sidebar
    if plot_spec.view == ViewType.distribution:
        return None

    # RECS/EIA: dwelling unit count case
    if plot_spec.quantity == DataCol.UNITS_COUNT:
        return "units_count_percent_difference"

    # RECS/EIA: penetration view uses percent_users difference
    if plot_spec.view == ViewType.penetration:
        return f"{plot_spec.quantity}_percent_users_percent_difference"

    # Default: value percent difference
    return f"{plot_spec.quantity}_value_percent_difference"


def _resolve_rse_column(plot_spec: PlotSpec) -> str | None:
    """Resolve the RSE (Relative Standard Error) column name.

    Only RECS has RSE columns. Distribution views don't have RSE.
    """
    # Only RECS has RSE
    if plot_spec.truth_source != TruthSource.recs:
        return None

    # Monthly data doesn't have RSE columns
    if plot_spec.resolution == Resolution.month:
        return None

    # Distribution plots don't have RSE
    if plot_spec.view == ViewType.distribution:
        return None

    # Dwelling unit count case
    if plot_spec.quantity == DataCol.UNITS_COUNT:
        return "units_count_rse"

    # Penetration view uses percent_users RSE
    if plot_spec.view == ViewType.penetration:
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
            if plot_spec.view in [ViewType.temp_view, ViewType.temp_count_view]:
                return "resstock_temp"
            return "percent_time"

        case Resolution.hour_of_day | Resolution.hour_of_day_summer | Resolution.hour_of_day_winter:
            return plot_spec.resolution

        case Resolution.hour_of_day_matrix:
            return "hour of day"

        case _:
            return None


def _resolve_title(plot_spec: PlotSpec) -> str:
    """Resolve the plot title based on resolution, view, and aggregation.

    LRD: Resolution-driven titles about electricity consumption.
    RECS/EIA: Complex titles based on quantity, aggregation, coverage, and view.
    """
    # LRD: resolution-driven titles
    if plot_spec.truth_source == TruthSource.lrd:
        return _resolve_lrd_title(plot_spec)

    # RECS/EIA: complex title logic
    return _resolve_recs_eia_title(plot_spec)


def _resolve_lrd_title(plot_spec: PlotSpec) -> str:
    """Build title for LRD plots based on resolution."""
    match plot_spec.resolution:
        case Resolution.year:
            return "Annual Electricity Consumption per Dwelling Unit"

        case Resolution.month:
            return "Monthly Electricity Consumption per Dwelling Unit"

        case Resolution.day_of_year:
            return "Daily Electricity Consumption per Dwelling Unit"

        case Resolution.hour_of_year | Resolution.top_100_hours:
            if plot_spec.view == ViewType.temp_view:
                return "Load vs Outdoor Drybulb Temperature"
            if plot_spec.view == ViewType.temp_count_view:
                return "Count of Number of Hours vs Outdoor Drybulb Temperature"
            title = "Load Duration Curve of Electricity Consumption per Dwelling Unit"
            if plot_spec.resolution == Resolution.top_100_hours:
                title += " (Top 100 Hours)"
            return title

        case Resolution.hour_of_day:
            return "Average Daily Electricity Consumption per Dwelling Unit"

        case Resolution.hour_of_day_summer:
            return "Average Summer Day Hourly Electricity Consumption per Dwelling Unit"

        case Resolution.hour_of_day_winter:
            return "Average Winter Day Hourly Electricity Consumption per Dwelling Unit"

        case Resolution.hour_of_day_matrix:
            return f"Hourly Load Profile Matrix for {plot_spec.focus_on}"

        case _:
            raise ValueError(f"Unsupported resolution '{plot_spec.resolution}' for LRD plot.")


def _format_quantity_name(quantity: DataCol) -> str:
    """Human-readable quantity name for plot titles.

    Examples: ELECTRICITY_TOTAL → "Electricity", NATURAL_GAS_SPACE_HEATING → "Space Heating Natural Gas"
    """
    return quantity.label


_AGGREGATION_LEVEL_LABELS = {
    "census_division_recs": "Census Division",
    "geometry_building_type_recs": "Building Type",
    "building_america_climate_zone": "Climate Zone",
    "heating_fuel": "Heating Fuel",
    "state": "State",
    "eiaid": "Utility",
}


def _format_aggregation_level(agg_level: str) -> str:
    """Convert an aggregation level column name to a display label."""
    return _AGGREGATION_LEVEL_LABELS.get(agg_level, agg_level.replace("_", " ").title())


def _format_focus_label(focus_on: str) -> str:
    """Convert a raw focus_on value to a human-readable display label.

    "US Total" → "U.S. Total", state abbreviations → full names, others pass through.
    """
    if focus_on == "US Total":
        return "U.S. Total"
    if focus_on in ABBR2STATE:
        return ABBR2STATE[focus_on]
    return focus_on


def _resolve_recs_eia_title(plot_spec: PlotSpec) -> str:
    """Build publication-quality title for RECS/EIA plots."""
    quantity_name = _format_quantity_name(plot_spec.quantity) if plot_spec.quantity != DataCol.ALL else "Enduse"
    agg_label = _format_aggregation_level(plot_spec.aggregation_level)
    grouping = f"({_format_focus_label(plot_spec.focus_on)})" if plot_spec.focus_on else f"by {agg_label}"
    is_monthly = plot_spec.resolution == Resolution.month

    # Dwelling unit count case
    if plot_spec.quantity == DataCol.UNITS_COUNT:
        return f"Number of Occupied Dwelling Units {grouping}"

    # Penetration view
    if plot_spec.view == ViewType.penetration:
        if plot_spec.quantity == DataCol.ALL:
            usage_name = "the specified End Use"
        else:
            usage_name = plot_spec.quantity.penetration_label
        return f"Share of Dwelling Units using {usage_name} {grouping}"

    # Distribution view
    if plot_spec.view == ViewType.distribution:
        per = "per Consuming Dwelling Unit" if plot_spec.coverage == CoverageType.users_only else "per Dwelling Unit"
        return f"Distribution of {quantity_name} Consumption {per} {grouping}"

    # Total aggregation
    period = "Monthly" if is_monthly else "Annual"
    if plot_spec.aggregation_type == AggregationType.total:
        return f"{period} {quantity_name} Consumption {grouping}"

    # Average aggregation
    per = "per Consuming Dwelling Unit" if plot_spec.coverage == CoverageType.users_only else "per Dwelling Unit"
    return f"Average {period} {quantity_name} Consumption {per} {grouping}"


def _resolve_diff_view_title(plot_spec: PlotSpec, truth_label: str) -> str:
    """Build the figure title for diff_view plots.

    Reuses the value_view title and wraps it with percent difference framing.
    """
    base = _resolve_recs_eia_title(plot_spec)
    return f"Percent Difference on {base}<br> Compared to {truth_label}"


def _resolve_quantity_title(plot_spec: PlotSpec) -> str:
    """Resolve the y-axis label (quantity units).

    Returns units like kWh, kWh/home, kWh/user, %, or count.
    """
    # LRD: mostly kWh, with special case for temp_count
    if plot_spec.truth_source == TruthSource.lrd:
        if plot_spec.view == ViewType.temp_count_view:
            return "count"
        return "kWh"

    # RECS/EIA: dwelling unit count case
    if plot_spec.quantity == DataCol.UNITS_COUNT:
        return "count"

    # RECS/EIA: penetration view shows percentages
    if plot_spec.view == ViewType.penetration:
        return "%"

    # RECS/EIA: total aggregation
    if plot_spec.aggregation_type == AggregationType.total:
        return "kWh"

    # RECS/EIA: average aggregation - depends on coverage
    if plot_spec.aggregation_type == AggregationType.average:
        if plot_spec.coverage == CoverageType.users_only:
            return "kWh/user"
        return "kWh/home"

    return "kWh"


def _resolve_sidebar_title(plot_spec: PlotSpec, truth_label: str) -> str:
    """Resolve the sidebar subplot title.

    Returns a full description like 'Percent difference compared to RECS 2020'.
    """
    if plot_spec.view == ViewType.distribution:
        return ""
    return f"Percent Difference Compared to {truth_label}"


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
            if plot_spec.view in [ViewType.temp_view, ViewType.temp_count_view]:
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
    if plot_spec.view in [ViewType.temp_view, ViewType.temp_count_view]:
        return "°F"
    return ""


def _extract_truth_source_label(truth_source: TruthSource, data: pl.DataFrame) -> str:
    """Extract a human-readable truth source label like 'EIA 2018' from data."""
    if "source" not in data.columns:
        return truth_source.value.upper()
    sources = data["source"].unique().to_list()
    ref_sources = [s for s in sources if truth_source.value in s]
    if ref_sources:
        # "eia_2018" → "EIA 2018", "recs_2020" → "RECS 2020"
        return ref_sources[0].replace("_", " ").upper()
    return truth_source.value.upper()


def _resolve_dimensions(plot_spec: PlotSpec, is_single_entity: bool) -> tuple[float, float]:
    """Resolve plot height and width based on resolution and entity count.

    Returns (height, width) in pixels.
    """
    # LRD: resolution-specific dimensions
    if plot_spec.truth_source == TruthSource.lrd:
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
        return 1080 * 0.4, 1920 * 0.425

    return 1080 * 0.8, 1920 * 0.85


# ─────────────────────────────────────────────────────────────────────────────
# Shared Helpers
# ─────────────────────────────────────────────────────────────────────────────


def _uses_stacked_layout(plot_spec: PlotSpec) -> bool:
    """Check if this plot should use stacked subplot layout (one row per entity).

    Returns True for:
    - ViewType.distribution (box plots)
    - quantity=ALL (enduse bar layout via split_graph_by_enduse)
    - non-state aggregation levels (grouped bar/box charts)
    """
    if plot_spec.view == ViewType.distribution:
        return True
    if plot_spec.quantity == DataCol.ALL:
        return True
    if plot_spec.aggregation_level not in [DataCol.STATE]:
        return True
    return False


def _check_single_entity(data: pl.DataFrame, plot_spec: PlotSpec, timeseries_column: str | None) -> bool:
    """Check if data contains a single entity (triggers simplified rendering)."""
    if plot_spec.aggregation_level not in data.columns:
        return False

    unique_entities = data[plot_spec.aggregation_level].unique().to_list()
    return len(unique_entities) == 1


# ─────────────────────────────────────────────────────────────────────────────
# Public Utilities
# ─────────────────────────────────────────────────────────────────────────────


def get_second_category_column(plot_spec: PlotSpec) -> str:
    """Get the column name for the second category (layout grouping).

    This determines which column is used for the tilemap layout.
    """
    match plot_spec.resolution:
        case Resolution.hour_of_day_matrix:
            return "month_daytype"
        case Resolution.day_of_year:
            return "utility_vertical"
        case _:
            if plot_spec.aggregation_level == "eiaid":
                return "utility_name"
            return plot_spec.aggregation_level


def get_second_category_title(plot_spec: PlotSpec) -> str:
    """Get the title for the second category axis."""
    match plot_spec.resolution:
        case Resolution.hour_of_day_matrix:
            return "Month / Day Type"
        case _:
            if plot_spec.aggregation_level == "eiaid":
                return "Utility (State)"
            return _format_aggregation_level(plot_spec.aggregation_level)
