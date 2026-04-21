from resstockpostproc.shared_utils.generic_plotters import box_plotter, bar_plotter
from resstockpostproc.shared_utils.generic_plotters.range_utils import compute_axis_range
from resstockpostproc.shared_utils.generic_plotters.tilemap_plotter import filter_null_sources
from resstockpostproc.baseline_validation.plotters.box_plot_data import prepare_box_plot_data
from resstockpostproc.baseline_validation.plotters.graph_splitting import split_graph
from resstockpostproc.baseline_validation.plotters.histogram_plot import create_histogram_plot
from resstockpostproc.baseline_validation.plotters.plot_config import resolve_percent_difference_column
from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    Metric,
    CoverageType,
    ViewType,
    Layout,
)
from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.shared_utils.timing import timed
import plotly.graph_objects as go
import polars as pl


@timed
def get_custom_range(df: pl.DataFrame, plot_spec: PlotSpec) -> tuple[float, float]:
    """Get custom y-axis range for the plot.

    Args:
        df: Input DataFrame
        plot_spec: The plot specification

    Returns:
        Tuple of (min_val, max_val) for y-axis range
    """
    quantity = plot_spec.quantity
    view = plot_spec.view

    # Dwelling unit count case
    if quantity == DataCol.UNITS_COUNT:
        col = "units_count_percent_difference" if view == ViewType.diff_view else "units_count"
        return compute_axis_range(df, col)

    # Determine if this is a distribution (box) plot and get column suffix
    is_dist = plot_spec.is_distribution_metric
    if is_dist:
        col_suffix = "_nonzero_quartiles" if plot_spec.coverage == CoverageType.users_only else "_quartiles"
    elif plot_spec.is_penetration_metric:
        col_suffix = "_percent_users"
    else:
        col_suffix = "_value"

    col_suffix += "_percent_difference" if view == ViewType.diff_view else ""
    all_quantities = (
        [c for c in df.columns if c.endswith(col_suffix)] if plot_spec.is_all_enduses else [f"{quantity}{col_suffix}"]
    )
    all_min_val, all_max_val = float("inf"), float("-inf")
    for quantity_col in all_quantities:
        if quantity_col not in df.columns:
            continue
        if is_dist:
            raw_min = df[quantity_col].fill_null([0]).list.get(0).min()
            raw_max = df[quantity_col].fill_null([0]).list.get(-1).max()
            min_val = min(0, float(raw_min) if raw_min is not None else 0.0)
            max_val = max(0, float(raw_max) if raw_max is not None else 0.0)
        else:
            lower_col = f"{quantity_col}_lower_bound"
            upper_col = f"{quantity_col}_upper_bound"
            if lower_col not in df.columns or upper_col not in df.columns:
                lower_col, upper_col = None, None
            min_val, max_val = compute_axis_range(df, quantity_col, lower_col, upper_col)
        all_min_val = min(all_min_val, min_val)
        all_max_val = max(all_max_val, max_val)

    # Handle case where no quantities were found
    if all_min_val == float("inf"):
        all_min_val = 0.0
    if all_max_val == float("-inf"):
        all_max_val = 1.0

    return all_min_val, all_max_val


def _stacked_quantity_title(plot_spec: PlotSpec) -> str:
    if plot_spec.quantity == DataCol.UNITS_COUNT:
        return "count"
    if plot_spec.is_distribution_metric:
        return "kWh/user" if plot_spec.coverage == CoverageType.users_only else "kWh/unit"
    if plot_spec.is_penetration_metric:
        return "%"
    if plot_spec.view == ViewType.diff_view:
        return "Percent Difference"
    if plot_spec.view == ViewType.value_view:
        return "kWh"
    return ""


@timed
def create_stacked_plot(df: pl.DataFrame, plot_spec: PlotSpec) -> go.Figure:
    """Create a box plot or bar comparing data sources across states.

    Uses distribution metric for box plots, otherwise bar plots.
    """
    if plot_spec.layout == Layout.histogram:
        return create_histogram_plot(df, plot_spec)

    quantity_title = _stacked_quantity_title(plot_spec)

    agg_col = plot_spec.group_by or (plot_spec.effective_group_by[-1] if plot_spec.effective_group_by else "state")
    if plot_spec.is_all_enduses and plot_spec.focus_on:
        for col, val in plot_spec.focus_on:
            if col in df.columns:
                df = df.filter(pl.col(col) == val)

    # Exclude US Total from total-aggregation value_view plots to prevent scale domination
    # (only when showing all entities, not when focused on a single entity like US Total)
    if (plot_spec.aggregation_type == Metric.total
            and plot_spec.view == ViewType.value_view
            and not plot_spec.focus_on
            and agg_col in df.columns
            and df[agg_col].n_unique() > 1):
        df = df.filter(pl.col(agg_col) != "US Total")

    show_legends = True
    assert plot_spec is not None
    fig, graph_iterator = split_graph(df, plot_spec)
    custom_range = get_custom_range(df, plot_spec)

    for df_subset, second_cat_column, row, col in graph_iterator:
        quantity_col = "enduse" if plot_spec.is_all_enduses else plot_spec.quantity

        # Use box plot for distribution view
        if plot_spec.is_distribution_metric:
            plot_df = prepare_box_plot_data(df_subset.clone(), quantity_col, plot_spec.coverage)
            box_plotter.create_box_plot(
                plot_df,
                first_category_column="source",
                second_category_column=second_cat_column,
                show_kde=False,
                quantity_title=quantity_title,
                first_category_title="Data Source",
                second_category_title=" ",
                fig=fig,
                row=row,
                col=col,
                show_legends=show_legends,
                custom_range=custom_range,
            )
        else:
            # Bar plot for other view types
            if plot_spec.quantity == DataCol.UNITS_COUNT:
                quantity_col = "units_count"
            elif plot_spec.is_penetration_metric:
                quantity_col = f"{quantity_col}_percent_users"
            else:
                quantity_col = f"{quantity_col}_value"
            quantity_col += "_percent_difference" if plot_spec.view == ViewType.diff_view else ""
            plot_df = (
                filter_null_sources(df_subset, "source", quantity_col)
                if plot_spec.view == ViewType.diff_view
                else df_subset
            )
            lower_col = f"{quantity_col}_lower_bound"
            upper_col = f"{quantity_col}_upper_bound"
            bar_plotter.create_bar_plot(
                data=plot_df,
                quantity_column=quantity_col,
                lower_bound_column=lower_col if lower_col in plot_df.columns else None,
                upper_bound_column=upper_col if upper_col in plot_df.columns else None,
                first_category_column="source",
                second_category_column=second_cat_column,
                quantity_title=quantity_title,
                first_category_title="Data Source",
                second_category_title=" ",
                fig=fig,
                row=row,
                col=col,
                show_legends=show_legends,
                custom_range=custom_range,
                count_label_resolver=plot_spec.model_count_display_label_for_source,
                compact_hover_values=True,
                percent_difference_column=resolve_percent_difference_column(quantity_col, plot_df),
            )
        show_legends = False  # Only show legends for the first subplot

    return fig
