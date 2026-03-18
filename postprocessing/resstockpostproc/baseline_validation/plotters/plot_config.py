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

    # Section titles (for tilemap grid and sidebar headers)
    main_section_title: str
    sidebar_section_title: str

    # Layout dimensions
    height: float
    width: float

    # Rendering mode flags
    use_distribution_plot: bool
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
    sidebar_title = _resolve_sidebar_title(plot_spec)
    ts_xtick_vals, ts_xtick_text = _resolve_tick_config(plot_spec, data)
    x_unit = _resolve_x_unit(plot_spec)
    use_distribution_plot = _is_distribution_plot(plot_spec)
    is_single_entity = _check_single_entity(data, plot_spec, timeseries_column)
    height, width = _resolve_dimensions(plot_spec, is_single_entity)

    # Resolve section titles (before view-type swapping)
    main_section_title, sidebar_section_title = _resolve_section_titles(plot_spec, data, quantity_title, sidebar_column)

    # Post-processing: diff_view swaps quantity <-> sidebar
    if plot_spec.view == ViewType.diff_view and sidebar_column:
        quantity_title, quantity_column, sidebar_title, sidebar_column = (
            sidebar_title,
            sidebar_column,
            quantity_title,
            quantity_column,
        )
        quantity_title = quantity_title.replace("Percent Difference (%)", r"% diff")
        main_section_title, sidebar_section_title = sidebar_section_title, main_section_title
        # RSE bounds are for the original values, not the percent differences
        rse_column = None

    # Post-processing: monthly resolution clears sidebar (RECS/EIA only)
    if plot_spec.resolution == Resolution.month and plot_spec.truth_source != TruthSource.lrd:
        sidebar_column = None
        sidebar_title = ""
        main_section_title = ""
        sidebar_section_title = ""

    return PlotConfig(
        quantity_column=quantity_column,
        sidebar_column=sidebar_column,
        rse_column=rse_column,
        timeseries_column=timeseries_column,
        title=title,
        quantity_title=quantity_title,
        sidebar_title=sidebar_title,
        main_section_title=main_section_title,
        sidebar_section_title=sidebar_section_title,
        ts_xtick_vals=ts_xtick_vals,
        ts_xtick_text=ts_xtick_text,
        x_unit=x_unit,
        height=height,
        width=width,
        use_distribution_plot=use_distribution_plot,
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
            return "Annual electricity consumption per dwelling unit"

        case Resolution.month:
            return "Monthly electricity consumption per dwelling unit"

        case Resolution.day_of_year:
            return "Daily electricity consumption per dwelling unit"

        case Resolution.hour_of_year | Resolution.top_100_hours:
            if plot_spec.view == ViewType.temp_view:
                return "Load Vs outdoor drybulb temperature"
            if plot_spec.view == ViewType.temp_count_view:
                return "Count of number of hours vs outdoor drybulb temperature"
            title = "Load Duration Curve of electricity consumption per dwelling unit"
            if plot_spec.resolution == Resolution.top_100_hours:
                title += " (Top 100 Hours)"
            return title

        case Resolution.hour_of_day:
            return "Average daily electricity consumption per dwelling unit"

        case Resolution.hour_of_day_summer:
            return "Average summer day hourly electricity consumption per dwelling unit"

        case Resolution.hour_of_day_winter:
            return "Average winter day hourly electricity consumption per dwelling unit"

        case Resolution.hour_of_day_matrix:
            return f"Hourly load profile matrix for {plot_spec.focus_on}"

        case _:
            raise ValueError(f"Unsupported resolution '{plot_spec.resolution}' for LRD plot.")


def _resolve_recs_eia_title(plot_spec: PlotSpec) -> str:
    """Build title for RECS/EIA plots based on quantity, aggregation, coverage, and view."""
    quantity_name = "Enduse" if plot_spec.quantity == DataCol.ALL else plot_spec.quantity
    grouping = f"in {plot_spec.focus_on}" if plot_spec.focus_on else f"by {plot_spec.aggregation_level}"

    # Dwelling unit count case
    if plot_spec.quantity == DataCol.UNITS_COUNT:
        base_title = f"Number of occupied dwelling units {grouping}"

    # Penetration view
    elif plot_spec.view == ViewType.penetration:
        base_title = f"Annual {plot_spec.quantity} Percent of Customers {grouping}"

    # Distribution view
    elif plot_spec.view == ViewType.distribution:
        unit = "kWh/user" if plot_spec.coverage == CoverageType.users_only else "kWh/home"
        base_title = f"Annual {plot_spec.quantity} {unit} distribution {grouping}"

    # Total aggregation
    elif plot_spec.aggregation_type == AggregationType.total:
        base_title = f"Annual {quantity_name} {grouping}"

    # Average aggregation
    elif plot_spec.aggregation_type == AggregationType.average:
        if plot_spec.coverage == CoverageType.users_only:
            base_title = f"Annual {plot_spec.quantity} per User {grouping}"
        else:
            base_title = f"Annual {plot_spec.quantity} per Unit {grouping}"

    else:
        base_title = f"Annual {quantity_name} {grouping}"

    # Add monthly prefix if applicable
    if plot_spec.resolution == Resolution.month:
        base_title = "Monthly " + base_title

    return base_title


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


def _resolve_sidebar_title(plot_spec: PlotSpec) -> str:
    """Resolve the sidebar axis title.

    Returns 'Percent Difference (%)' when sidebar is applicable, empty otherwise.
    """
    # LRD: sidebar only for year resolution
    if plot_spec.truth_source == TruthSource.lrd:
        if plot_spec.resolution == Resolution.year:
            return "Percent Difference (%)"
        return ""

    # RECS/EIA: distribution plots don't have sidebar
    if plot_spec.view == ViewType.distribution:
        return ""

    return "Percent Difference (%)"


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


def _resolve_section_titles(
    plot_spec: PlotSpec, data: pl.DataFrame, quantity_title: str, sidebar_column: str | None
) -> tuple[str, str]:
    """Resolve descriptive section titles for the main grid and sidebar.

    Returns (main_section_title, sidebar_section_title) before any view-type swapping.
    In value_view: main shows quantity, sidebar shows percent difference description.
    The caller handles swapping these for diff_view.
    """
    if sidebar_column is None:
        return "", ""

    truth_label = _extract_truth_source_label(plot_spec.truth_source, data)
    sidebar_desc = f"Percent difference compared to {truth_label}"
    return quantity_title, sidebar_desc


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


def _is_distribution_plot(plot_spec: PlotSpec) -> bool:
    """Check if this plot should use distribution/box rendering.

    Returns True for:
    - ViewType.distribution (explicit distribution box plot)
    - quantity=ALL (enduse penetration plots use bar layout via split_graph_by_enduse)
    - non-state aggregation levels (use grouped bar chart)
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
            return plot_spec.aggregation_level.capitalize()
