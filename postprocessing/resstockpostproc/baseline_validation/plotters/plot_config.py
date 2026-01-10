"""Plot configuration derived from PlotSpec for rendering.

This module provides the PlotConfig dataclass and builder functions that
translate a PlotSpec into rendering-ready configuration.
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

    # Layout dimensions
    height: float
    width: float

    # Rendering mode flags
    use_distribution_plot: bool
    is_single_entity: bool


def build_plot_config(plot_spec: PlotSpec, data: pl.DataFrame) -> PlotConfig:
    """Build a PlotConfig from a PlotSpec and data.

    Args:
        plot_spec: The plot specification
        data: The prepared DataFrame (used to check for single-entity rendering)

    Returns:
        PlotConfig with all rendering parameters resolved
    """
    if plot_spec.truth_source == TruthSource.lrd:
        return _build_lrd_config(plot_spec, data)
    else:
        return _build_recs_eia_config(plot_spec, data)


# ─────────────────────────────────────────────────────────────────────────────
# RECS/EIA Config Builder
# ─────────────────────────────────────────────────────────────────────────────


def _build_recs_eia_config(plot_spec: PlotSpec, data: pl.DataFrame) -> PlotConfig:
    """Build config for RECS and EIA plots."""
    quantity_column = _get_recs_quantity_column(plot_spec)
    sidebar_column = _get_recs_sidebar_column(plot_spec)
    rse_column = _get_recs_rse_column(plot_spec)
    quantity_title = _get_recs_quantity_title(plot_spec)
    sidebar_title = "Percent Difference (%)"
    title = _build_recs_title(plot_spec)
    timeseries_column = _get_recs_timeseries_column(plot_spec)
    ts_xtick_vals, ts_xtick_text = _get_recs_tick_config(plot_spec)

    # Handle view type swapping (diff_view swaps main quantity with sidebar)
    if plot_spec.view == ViewType.diff_view and sidebar_column:
        quantity_title, quantity_column, sidebar_title, sidebar_column = (
            sidebar_title,
            sidebar_column,
            quantity_title,
            quantity_column,
        )
        quantity_title = quantity_title.replace("Percent Difference (%)", r"% diff")

    # Clear sidebar for monthly resolution
    if plot_spec.resolution == Resolution.month:
        sidebar_column = None
        sidebar_title = ""

    # Determine if this is a distribution plot
    use_distribution_plot = _is_distribution_plot(plot_spec)

    # Determine if single entity (for simplified timeseries rendering)
    is_single_entity = _check_single_entity(data, plot_spec, timeseries_column)

    # Get dimensions
    height, width = _get_recs_dimensions(plot_spec, is_single_entity)

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
        x_unit="",
        height=height,
        width=width,
        use_distribution_plot=use_distribution_plot,
        is_single_entity=is_single_entity,
    )


def _get_recs_quantity_column(plot_spec: PlotSpec) -> str:
    """Determine the quantity column name based on aggregation type and view.

    For distribution views, returns quartiles column. For penetration views,
    returns percent_users column. Otherwise returns value column.
    """
    # Customer count case (no quantity specified with total aggregation)
    if plot_spec.quantity is None and plot_spec.aggregation_type == AggregationType.total:
        return "units_count"

    # Distribution box plot uses quartiles
    if plot_spec.view == ViewType.distribution:
        if plot_spec.coverage == CoverageType.users_only:
            return f"{plot_spec.quantity}_nonzero_quartiles"
        return f"{plot_spec.quantity}_quartiles"

    # Penetration bar plot uses percent_users
    if plot_spec.view == ViewType.penetration:
        return f"{plot_spec.quantity}_percent_users"

    # Default: value column
    return f"{plot_spec.quantity}_value"


def _get_recs_sidebar_column(plot_spec: PlotSpec) -> str | None:
    """Determine the sidebar column name (percent difference).

    Distribution views don't have a sidebar (no percent difference for box plots).
    """
    # Distribution plots don't have sidebar
    if plot_spec.view == ViewType.distribution:
        return None

    # Customer count case
    if plot_spec.quantity is None and plot_spec.aggregation_type == AggregationType.total:
        return "units_count_percent_difference"

    # Penetration view uses percent_users difference
    if plot_spec.view == ViewType.penetration:
        return f"{plot_spec.quantity}_percent_users_percent_difference"

    # Default: value percent difference
    return f"{plot_spec.quantity}_value_percent_difference"


def _get_recs_rse_column(plot_spec: PlotSpec) -> str | None:
    """Determine the RSE column name (RECS only).

    Distribution views don't have RSE. Penetration views use percent_users RSE.
    """
    if plot_spec.truth_source != TruthSource.recs:
        return None

    # Distribution plots don't have RSE
    if plot_spec.view == ViewType.distribution:
        return None

    # Customer count case
    if plot_spec.quantity is None and plot_spec.aggregation_type == AggregationType.total:
        return "units_count_rse"

    # Penetration view uses percent_users RSE
    if plot_spec.view == ViewType.penetration:
        return f"{plot_spec.quantity}_percent_users_rse"

    # Default: value RSE
    return f"{plot_spec.quantity}_value_rse"


def _get_recs_quantity_title(plot_spec: PlotSpec) -> str:
    """Get the y-axis label based on aggregation type, coverage, and view.

    - total aggregation: kWh (or count for customer plots)
    - average aggregation: kWh/home or kWh/user depending on coverage
    - penetration view: %
    """
    # Customer count case
    if plot_spec.quantity is None and plot_spec.aggregation_type == AggregationType.total:
        return "count"

    # Penetration view shows percentages
    if plot_spec.view == ViewType.penetration:
        return "%"

    # Total aggregation
    if plot_spec.aggregation_type == AggregationType.total:
        return "kWh"

    # Average aggregation - depends on coverage
    if plot_spec.aggregation_type == AggregationType.average:
        if plot_spec.coverage == CoverageType.users_only:
            return "kWh/user"
        return "kWh/home"

    return "kWh"


def _build_recs_title(plot_spec: PlotSpec) -> str:
    """Build the plot title for RECS/EIA plots.

    Title format depends on aggregation_type, coverage, and view type.
    """
    quantity_name = plot_spec.quantity or "Enduse"
    grouping = f"in {plot_spec.focus_on}" if plot_spec.focus_on else f"by {plot_spec.aggregation_level}"

    # Customer count case (quantity=None with total aggregation)
    if plot_spec.quantity is None and plot_spec.aggregation_type == AggregationType.total:
        base_title = "Number of occupied dwelling units by State"
    # Penetration view
    elif plot_spec.view == ViewType.penetration:
        base_title = f"Annual {plot_spec.quantity} Percent of Customers by State"
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
            base_title = f"Annual {plot_spec.quantity} per User by State"
        else:
            base_title = f"Annual {plot_spec.quantity} per Unit by State"
    else:
        base_title = f"Annual {quantity_name} {grouping}"

    # Add monthly prefix if applicable
    if plot_spec.resolution == Resolution.month:
        base_title = "Monthly " + base_title

    return base_title


def _get_recs_timeseries_column(plot_spec: PlotSpec) -> str | None:
    """Get the timeseries column for RECS/EIA plots."""
    if plot_spec.resolution == Resolution.month:
        return "month"
    return None


def _get_recs_tick_config(plot_spec: PlotSpec) -> tuple:
    """Get tick values and text for RECS/EIA plots."""
    if plot_spec.resolution == Resolution.month:
        return ("JAN", "DEC"), ("   Jan", "Dec   ")
    return None, None


def _get_recs_dimensions(plot_spec: PlotSpec, is_single_entity: bool) -> tuple[float, float]:
    """Get height and width for RECS/EIA plots."""
    if is_single_entity:
        return 1080 * 0.4, 1920 * 0.425
    return 1080 * 0.8, 1920 * 0.85


# ─────────────────────────────────────────────────────────────────────────────
# LRD Config Builder
# ─────────────────────────────────────────────────────────────────────────────


def _build_lrd_config(plot_spec: PlotSpec, data: pl.DataFrame) -> PlotConfig:
    """Build config for LRD (Load Research Data) plots."""
    quantity_column = f"{plot_spec.quantity}_value"
    quantity_title = "kWh"
    sidebar_column = None
    sidebar_title = ""
    x_unit = ""
    timeseries_column = None
    ts_xtick_vals = None
    ts_xtick_text = None
    title = ""

    match plot_spec.resolution:
        case Resolution.year:
            timeseries_column = None
            sidebar_column = f"{plot_spec.quantity}_value_percent_difference"
            sidebar_title = "Percent Difference (%)"
            title = "Annual electricity consumption per dwelling unit"

        case Resolution.month:
            timeseries_column = Resolution.month
            ts_xtick_vals = ("JAN", "DEC")
            ts_xtick_text = ("   Jan", "Dec   ")
            title = "Monthly electricity consumption per dwelling unit"

        case Resolution.day_of_year:
            timeseries_column = "day of year"
            ts_xtick_vals = None  # Let Plotly auto-generate date ticks
            ts_xtick_text = None
            title = "Daily electricity consumption per dwelling unit"

        case Resolution.hour_of_year | Resolution.top_100_hours:
            if plot_spec.view in [ViewType.temp_view, ViewType.temp_count_view]:
                x_unit = "°F"
                timeseries_column = "resstock_temp"
                if plot_spec.view == ViewType.temp_view:
                    title = "Load Vs outdoor drybulb temperature"
                else:
                    quantity_title = "count"
                    quantity_column = "temp_count"
                    title = "Count of number of hours vs outdoor drybulb temperature"
            else:
                timeseries_column = "percent_time"
                title = "Load Duration Curve of electricity consumption per dwelling unit"
                if plot_spec.resolution == Resolution.top_100_hours:
                    title += " (Top 100 Hours)"
                # Tick values are computed from data
                ts_xtick_vals, ts_xtick_text = _get_lrd_percent_time_ticks(data, plot_spec)

        case Resolution.hour_of_day | Resolution.hour_of_day_summer | Resolution.hour_of_day_winter:
            timeseries_column = plot_spec.resolution
            ts_xtick_vals = (0, 23)
            ts_xtick_text = ("     Hour 1", "Hour 24       ")
            if plot_spec.resolution == Resolution.hour_of_day_summer:
                title = "Average summer day hourly electricity consumption per dwelling unit"
            elif plot_spec.resolution == Resolution.hour_of_day_winter:
                title = "Average winter day hourly electricity consumption per dwelling unit"
            else:
                title = "Average daily electricity consumption per dwelling unit"

        case Resolution.hour_of_day_matrix:
            timeseries_column = "hour of day"
            ts_xtick_vals = (0, 23)
            ts_xtick_text = ("     Hour 1", "Hour 24       ")
            title = f"Hourly load profile matrix for {plot_spec.focus_on}"

        case _:
            raise ValueError(f"Unsupported resolution '{plot_spec.resolution}' for LRD plot.")

    height, width = _get_lrd_dimensions(plot_spec)

    return PlotConfig(
        quantity_column=quantity_column,
        sidebar_column=sidebar_column,
        rse_column=None,  # LRD doesn't have RSE
        timeseries_column=timeseries_column,
        title=title,
        quantity_title=quantity_title,
        sidebar_title=sidebar_title,
        ts_xtick_vals=ts_xtick_vals,
        ts_xtick_text=ts_xtick_text,
        x_unit=x_unit,
        height=height,
        width=width,
        use_distribution_plot=False,  # LRD doesn't use distribution plots
        is_single_entity=False,  # LRD always uses tilemap
    )


def _get_lrd_percent_time_ticks(data: pl.DataFrame, plot_spec: PlotSpec) -> tuple:
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


def _get_lrd_dimensions(plot_spec: PlotSpec) -> tuple[float, float]:
    """Get height and width for LRD plots."""
    match plot_spec.resolution:
        case Resolution.hour_of_day_matrix:
            return 1800, 900  # Taller for 13 rows
        case Resolution.day_of_year:
            return 2000, 1400  # Tall for 15 rows, wide for date axis
        case _:
            return 1080 * 0.8, 1920 * 0.7


# ─────────────────────────────────────────────────────────────────────────────
# Shared Helpers
# ─────────────────────────────────────────────────────────────────────────────


def _is_distribution_plot(plot_spec: PlotSpec) -> bool:
    """Check if this plot should use distribution/box rendering.

    Returns True for:
    - ViewType.distribution (explicit distribution box plot)
    - quantity=None (enduse penetration plots use bar layout via split_graph_by_enduse)
    - non-state aggregation levels (use grouped bar chart)
    """
    if plot_spec.view == ViewType.distribution:
        return True
    if plot_spec.quantity is None:
        return True
    if plot_spec.aggregation_level not in [DataCol.STATE]:
        return True
    return False


def _check_single_entity(data: pl.DataFrame, plot_spec: PlotSpec, timeseries_column: str | None) -> bool:
    """Check if data contains a single entity (triggers simplified rendering)."""
    if timeseries_column is None:
        return False

    if plot_spec.aggregation_level not in data.columns:
        return False

    unique_entities = data[plot_spec.aggregation_level].unique().to_list()
    return len(unique_entities) == 1


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
