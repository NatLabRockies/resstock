import calendar
from typing import Any

import polars as pl
import plotly.graph_objects as go
from plotly.subplots import make_subplots

from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.baseline_validation.schema.plot_spec import PlotSpec, AggregationType, ViewType, TruthSource
from resstockpostproc.baseline_validation.schema.recs_enduse_mapping import RECS_ENDUSE_MAP
from resstockpostproc.shared_utils.colors import QUALITATIVE_SERIES, REF_QUALITATIVE_SERIES
from resstockpostproc.baseline_validation.plotters import base_plotter
from resstockpostproc.baseline_validation.theme import apply_theme
from resstockpostproc.shared_utils.generic_plotters import tilemap_plotter
import polars as pl
import plotly.graph_objects as go
from resstockpostproc.shared_utils.generic_plotters import box_plotter
from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.baseline_validation.schema.plot_spec import PlotSpec, Resolution, ViewType
from resstockpostproc.shared_utils.generic_plotters import tilemap_plotter
from resstockpostproc.shared_utils.generic_plotters.monthly_plotter import create_ts_plot
from resstockpostproc.baseline_validation.theme import apply_theme
from .box_plotter import create_vertical_plot

# ---------------------------------------------------------------------------
# constants
# ---------------------------------------------------------------------------
RECS_COLORS = REF_QUALITATIVE_SERIES
_RUN_PALETTE = QUALITATIVE_SERIES
MONTH_ROWS = 5
MONTH_COLS = 11
MONTH_MAX = MONTH_ROWS * MONTH_COLS

MONTH_NAME_TO_INDEX = {name.lower(): idx for idx, name in enumerate(calendar.month_name) if name}
MONTH_NAME_TO_INDEX.update({abbr.lower(): idx for idx, abbr in enumerate(calendar.month_abbr) if abbr})
MONTH_INDEX_TO_LABEL = {idx: calendar.month_abbr[idx] for idx in range(1, 13)}


def plot_all_enduses(
    data: pl.DataFrame,
    by: str,  # noqa: ARG001 - kept for consistency, currently aggregates across all values
    title: str,
    suffix: str = "_value",  # noqa: ARG001 - not used with new format but kept for compatibility
) -> go.Figure:
    """
    Create horizontal grouped bar plots organized by fuel source categories.
    Shows: Fuel Totals, Electricity End uses, Natural Gas End uses, Propane End uses, Fuel Oil End uses.
    Each subplot shows bars for each end-use within that category, grouped by state.

    Args:
        data: DataFrame with standardized tall format (source, quantity_type, quantity, value columns)
        by: Grouping column (e.g., 'state')
        title: Plot title
        suffix: Column suffix (unused in new format but kept for compatibility)
    """
    # Categorize end-uses by fuel source

    enduse_groups_2_position = {
        "Fuel Totals": (1, 1),
        "Natural Gas End uses": (2, 1),
        "Propane End uses": (2, 2),
        "Fuel Oil End uses": (3, 1),
        "Electricity End uses": (1, 2),
    }

    def _filter_quantitities(df: pl.DataFrame, quantity_group: str) -> pl.DataFrame:
        match quantity_group:
            case "Fuel Totals":
                return df.filter(pl.col("quantity").str.ends_with("_total"))
            case "Electricity End uses":
                return df.filter(
                    pl.col("quantity").str.starts_with("electricity_") & ~pl.col("quantity").str.ends_with("_total")
                )
            case "Natural Gas End uses":
                return df.filter(
                    pl.col("quantity").str.starts_with("natural_gas_") & ~pl.col("quantity").str.ends_with("_total")
                )
            case "Propane End uses":
                return df.filter(
                    pl.col("quantity").str.starts_with("propane_") & ~pl.col("quantity").str.ends_with("_total")
                )
            case "Fuel Oil End uses":
                return df.filter(
                    pl.col("quantity").str.starts_with("fuel_oil_") & ~pl.col("quantity").str.ends_with("_total")
                )
            case _:
                return df.filter(pl.lit(False))

    left_enduse_counts = [
        len(_filter_quantitities(data, group))
        for group, position in enduse_groups_2_position.items()
        if position[0] == 1
    ]

    total_left_enduses = sum(left_enduse_counts)
    row_heights = [count / total_left_enduses if total_left_enduses > 0 else 0.25 for count in left_enduse_counts]

    specs = []
    for i in range(4):
        if i == 0:
            specs.append([{"type": "bar"}, {"type": "bar", "rowspan": 4}])
        else:
            specs.append([{"type": "bar"}, None])

    subplot_titles = list(enduse_groups_2_position.keys())

    fig = make_subplots(
        rows=4,
        cols=2,
        subplot_titles=subplot_titles,
        specs=specs,
        column_widths=[0.25, 0.75],  # Left narrower, right wider
        row_heights=row_heights,  # Proportional to number of end-uses
        horizontal_spacing=0.15,
        vertical_spacing=0.05,  # Reduced spacing between rows
        shared_yaxes=False,
    )

    # Process left column categories
    for row_idx, (category_name, enduses) in enumerate(categories, start=1):
        if not enduses:
            continue

        # Filter data for this category's enduses
        category_data = data.filter(pl.col("quantity").is_in(enduses))

        if category_data.is_empty():
            continue

        # Aggregate by enduse and source across all states
        aggregated = category_data.group_by(["quantity", "source"]).agg(
            pl.col("value").cast(pl.Float64).sum().alias("total_value")
        )

        # Pivot to get sources as columns
        pivoted = aggregated.pivot(index="quantity", on="source", values="total_value").fill_null(0)

        # Add state column for box plot

        # Use base_plotter function
        box_plotter.create_box_plot(
            pivoted,
            first_category_column="source",
            second_category_column="state",
            show_kde=False,
            quantity_title=enduse,
            first_category_title="Data Source",
            second_category_title=" ",
            fig=fig,
            row=1,
            col=1,
        )

    # Update axes for all left column subplots
    for row_idx in range(1, 5):
        fig.update_xaxes(title_text="kWh", showgrid=True, row=row_idx, col=1)
        fig.update_yaxes(showticklabels=True, categoryorder="total ascending", row=row_idx, col=1)

    # Update axes for right column (large subplot)
    fig.update_xaxes(title_text="kWh", showgrid=True, row=1, col=2)
    return fig


def create_plot(data: pl.DataFrame, plot_spec: PlotSpec) -> tuple[go.Figure, str]:
    """Create load duration curve plot based on the plot specification."""

    final_df = data.clone()
    sidebar_column: str = ""
    sidebar_title: str = ""
    ts_xtick_vals = None
    ts_xtick_text = None
    timeseries_column = None
    rse_column: str | None = None
    x_unit = ""
    quantity_title: str = "kWh"
    quantity_column: str = ""
    title = ""
    grouping = f"in {plot_spec.focus_on}" if plot_spec.focus_on else f"by {plot_spec.aggregation_level}"
    match plot_spec.aggregation_type:
        case AggregationType.stock_total:
            quantity_title = "kWh"
            quantity_column = f"{plot_spec.quantity}_value"
            sidebar_column = f"{plot_spec.quantity}_value_percent_difference"
            rse_column = f"{plot_spec.quantity}_value_rse" if plot_spec.truth_source == TruthSource.recs else None
            sidebar_title = "Percent Difference (%)"
            quantity_name = plot_spec.quantity or "Enduse"
            grouping = f"in {plot_spec.focus_on}" if plot_spec.focus_on else f"{plot_spec.aggregation_level}"
            title = f"Annual {quantity_name} {grouping}"
        case AggregationType.percent_users:
            quantity_title = "%"
            quantity_column = f"{plot_spec.quantity}_percent_users"
            sidebar_column = f"{plot_spec.quantity}_percent_users_percent_difference"
            rse_column = (
                f"{plot_spec.quantity}_percent_users_rse" if plot_spec.truth_source == TruthSource.recs else None
            )
            sidebar_title = "Percent Difference (%)"
            title = f"Annual {plot_spec.quantity} Percent of Customers by State"
        case AggregationType.per_unit:
            quantity_title = "kWh/home"
            quantity_column = f"{plot_spec.quantity}_value"
            rse_column = f"{plot_spec.quantity}_value_rse" if plot_spec.truth_source == TruthSource.recs else None
            sidebar_column = f"{plot_spec.quantity}_value_percent_difference"
            sidebar_title = "Percent Difference (%)"
            title = f"Annual {plot_spec.quantity} per Unit by State"
        case AggregationType.per_user:
            quantity_title = "kWh/user"
            quantity_column = f"{plot_spec.quantity}_value"
            rse_column = f"{plot_spec.quantity}_value_rse" if plot_spec.truth_source == TruthSource.recs else None
            sidebar_column = f"{plot_spec.quantity}_value_percent_difference"
            sidebar_title = "Percent Difference (%)"
            title = f"Annual {plot_spec.quantity} per User by State"
        case AggregationType.per_unit_distribution | AggregationType.per_user_distribution:
            quantity_title = (
                "kWh/home" if (plot_spec.aggregation_type == AggregationType.per_unit_distribution) else "kWh/user"
            )
            quantity_column = f"{plot_spec.quantity}_quartiles"
            title = f"Annual {plot_spec.quantity} {quantity_title} distribution {grouping}"
        case AggregationType.customers:
            quantity_title = "count"
            quantity_column = "units_count"
            rse_column = "units_count_rse" if plot_spec.truth_source == TruthSource.recs else None
            sidebar_column = "units_count_percent_difference"
            sidebar_title = "Percent Difference (%)"
            title = "Number of occupied dwelling units by State"
        case _:
            raise ValueError(f"Unsupported aggregation type '{plot_spec.aggregation_type}' for RECS plot.")

    if plot_spec.resolution == Resolution.month:
        timeseries_column = "month"
        ts_xtick_vals = ("JAN", "DEC")
        ts_xtick_text = ("   Jan", "Dec   ")
        title = "Monthly " + title
        sidebar_column = ""
        sidebar_title = ""
    # match plot_spec.resolution:
    #     case Resolution.year:
    #         timeseries_column = None
    #         ts_xtick_vals = ()
    #         ts_xtick_text = ()
    #         sidebar_column = f"{plot_spec.quantity}_value_percent_difference"
    #         sidebar_title = "Percent Difference (%)"
    #         title = f"Annual {plot_spec.quantity} ({plot_spec.aggregation_type})"
    #     case Resolution.month:
    #         timeseries_column = Resolution.month
    #         ts_xtick_vals = ("JAN", "DEC")
    #         ts_xtick_text = ("   Jan", "Dec   ")
    #         title = f"Monthly {plot_spec.quantity} ({plot_spec.aggregation_type})"
    #     case _:
    #         raise ValueError(f"Unsupported resolution '{plot_spec.resolution}' for RECS plot.")

    if (
        plot_spec.aggregation_type in [AggregationType.per_unit_distribution, AggregationType.per_user_distribution]
        or plot_spec.quantity is None
        or plot_spec.aggregation_level not in [DataCol.STATE]
    ):
        fig = create_vertical_plot(final_df, plot_spec)
    else:
        if plot_spec.view == ViewType.diff_view:
            quantity_title, quantity_column, sidebar_title, sidebar_column = (
                sidebar_title,
                sidebar_column,
                quantity_title,
                quantity_column,
            )
            quantity_title = quantity_title.replace("Percent Difference (%)", r"% diff")

        # Check if we have a single entity (e.g., focus_on filters to one state)
        # In this case, use a simple timeseries plot instead of the full tilemap
        unique_entities = final_df[plot_spec.aggregation_level].unique().to_list()
        is_single_entity = len(unique_entities) == 1 and timeseries_column is not None

        if is_single_entity:
            # Single entity with timeseries - use create_ts_plot directly
            fig = create_ts_plot(
                data=final_df,
                timeseries_column=timeseries_column,
                quantity_column=quantity_column,
                first_category_column="source",
                rse_column=rse_column,
                first_category_title="Data Source",
                quantity_title=quantity_title,
                title_text=title,
                show_legends=True,
                x_unit=x_unit,
                fill_lower_bound=True,
            )
            fig = apply_theme(fig, title=title, height=1080 * 0.4, width=1920 * 0.425)
            return fig, title
        else:
            fig = tilemap_plotter.plot_tilemap(
                data=final_df,
                quantity_title=quantity_title,
                quantity_column=quantity_column,
                rse_column=rse_column,
                first_category_column="source",
                first_category_title="Data Source",
                second_category_column=plot_spec.aggregation_level,
                second_category_title=plot_spec.aggregation_level.capitalize(),
                show_legends=True,
                timeseries_column=timeseries_column,
                ts_xtick_vals=ts_xtick_vals,
                ts_xtick_text=ts_xtick_text,
                x_unit=x_unit,
                title_text=title,
                sidebar_column=sidebar_column,
                sidebar_title=sidebar_title,
            )
    fig = apply_theme(fig, title=title, height=1080 * 0.8, width=1920 * 0.85)
    return fig, title
