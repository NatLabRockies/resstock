"""Main plotter for baseline validation.

This module provides a single entry point for creating all validation plots,
regardless of comparison dataset (RECS, EIA, LRD) or visualization type.
"""

import polars as pl
import plotly.graph_objects as go

from resstockpostproc.baseline_validation.schema.plot_spec import PlotSpec, Metric, ViewType, Layout, Resolution
from resstockpostproc.baseline_validation.theme import apply_theme
from resstockpostproc.baseline_validation.plotters.plot_config import (
    build_plot_config,
    PlotConfig,
    get_second_category_column,
    get_second_category_title,
    resolve_percent_difference_column,
)
from resstockpostproc.baseline_validation.plotters.stacked_plotter import create_stacked_plot
from resstockpostproc.shared_utils.generic_plotters import tilemap_plotter
from resstockpostproc.shared_utils.generic_plotters.tilemap_plotter import filter_null_sources
from resstockpostproc.shared_utils.generic_plotters.bar_plotter import create_bar_plot
from resstockpostproc.shared_utils.generic_plotters.monthly_plotter import create_ts_plot, create_ts_bar_plot
from resstockpostproc.shared_utils.timing import timed


@timed
def create_plot(data: pl.DataFrame, plot_spec: PlotSpec) -> tuple[go.Figure, str]:
    """Render ``plot_spec`` against ``data``; single entry point for RECS/EIA/LRD."""
    config = build_plot_config(plot_spec, data)
    fig = _render(data, config, plot_spec)
    fig = apply_theme(fig, title=config.title, height=config.height, width=config.width)
    return fig, config.title

@timed
def _get_null_sources(data: pl.DataFrame, source_column: str, quantity_column: str) -> list[str]:
    """Identify sources where the quantity column is entirely null."""
    if quantity_column not in data.columns:
        return []
    return (
        data.group_by(source_column, maintain_order=True)
        .agg(pl.col(quantity_column).is_null().all().alias("all_null"))
        .filter(pl.col("all_null"))
        .select(source_column)
        .to_series()
        .to_list()
    )

def _needs_stacked_plotter(plot_spec: PlotSpec) -> bool:
    """True for distribution box plots and ALL-enduse plots that need split_graph."""
    return (
        plot_spec.is_distribution_metric
        or plot_spec.is_all_enduses
        or plot_spec.layout in (Layout.two_column, Layout.histogram)
    )


def _drop_reference_source_in_diff_view(data: pl.DataFrame, plot_spec: PlotSpec, config: PlotConfig) -> pl.DataFrame:
    """In diff_view, drop sources whose quantity column is entirely null (the reference)."""
    if plot_spec.view != ViewType.diff_view:
        return data
    return filter_null_sources(data, "source", config.quantity_column)


def _shared_plot_kwargs(data: pl.DataFrame, config: PlotConfig, plot_spec: PlotSpec) -> dict:
    """Kwargs every plotter takes for source labels, percent-diff hover, and compact values."""
    return {
        "count_label_resolver": plot_spec.model_count_display_label_for_source,
        "compact_hover_values": True,
        "percent_difference_column": resolve_percent_difference_column(config.quantity_column, data),
    }


@timed
def _render(data: pl.DataFrame, config: PlotConfig, plot_spec: PlotSpec) -> go.Figure:
    """Select appropriate renderer and create the figure."""
    if config.is_single_entity and not _needs_stacked_plotter(plot_spec):
        if config.timeseries_column:
            if plot_spec.resolution == Resolution.month:
                return _render_single_entity_monthly_bar(data, config, plot_spec)
            return _render_single_entity_timeseries(data, config, plot_spec)
        else:
            return _render_single_entity_bar(data, config, plot_spec)
    elif config.uses_stacked_layout:
        return _render_stacked(data, plot_spec)
    else:
        return _render_tilemap(data, config, plot_spec)

@timed
def _render_tilemap(data: pl.DataFrame, config: PlotConfig, plot_spec: PlotSpec) -> go.Figure:
    """Render using tilemap layout with bar or timeseries subplots."""
    second_category_column = get_second_category_column(plot_spec)
    second_category_title = get_second_category_title(plot_spec)

    exclude_from_sidebar = (
        ["US Total"]
        if plot_spec.aggregation_type == Metric.total and plot_spec.view == ViewType.diff_view
        else None
    )

    # In diff_view, exclude reference source from subplots (it always has 0% diff)
    exclude_sources = (
        _get_null_sources(data, "source", config.quantity_column)
        if plot_spec.view == ViewType.diff_view
        else None
    )

    return tilemap_plotter.plot_tilemap(
        data=data,
        quantity_title=config.quantity_title,
        quantity_column=config.quantity_column,
        lower_bound_column=config.lower_bound_column,
        upper_bound_column=config.upper_bound_column,
        first_category_column="source",
        first_category_title="Data Source",
        second_category_column=second_category_column,
        second_category_title=second_category_title,
        show_legends=True,
        timeseries_column=config.timeseries_column,
        ts_xtick_vals=config.ts_xtick_vals,
        ts_xtick_text=config.ts_xtick_text,
        x_unit=config.x_unit,
        title_text=config.title,
        sidebar_column=config.sidebar_column,
        sidebar_title=config.sidebar_title,
        exclude_from_sidebar=exclude_from_sidebar,
        exclude_sources=exclude_sources,
        separate_us_total_scale=(
            plot_spec.aggregation_type == Metric.total
            and plot_spec.view == ViewType.value_view
        ),
        **_shared_plot_kwargs(data, config, plot_spec),
    )

@timed
def _render_single_entity_timeseries(data: pl.DataFrame, config: PlotConfig, plot_spec: PlotSpec) -> go.Figure:
    """Render a simple timeseries for single-entity (focused) plots."""
    return create_ts_plot(
        data=data,
        timeseries_column=config.timeseries_column,
        quantity_column=config.quantity_column,
        first_category_column="source",
        lower_bound_column=config.lower_bound_column,
        upper_bound_column=config.upper_bound_column,
        first_category_title="Data Source",
        quantity_title=config.quantity_title,
        title_text=config.title,
        show_legends=True,
        x_unit=config.x_unit,
        fill_lower_bound=True,
        **_shared_plot_kwargs(data, config, plot_spec),
    )

@timed
def _render_single_entity_monthly_bar(data: pl.DataFrame, config: PlotConfig, plot_spec: PlotSpec) -> go.Figure:
    """Render a grouped bar chart for single-entity monthly plots.

    One bar per source at each month tick; reference source is dropped in
    diff_view so only ResStock source(s) render (matches _render_single_entity_bar).
    """
    data = _drop_reference_source_in_diff_view(data, plot_spec, config)
    return create_ts_bar_plot(
        data=data,
        timeseries_column=config.timeseries_column,
        quantity_column=config.quantity_column,
        first_category_column="source",
        lower_bound_column=config.lower_bound_column,
        upper_bound_column=config.upper_bound_column,
        first_category_title="Data Source",
        quantity_title=config.quantity_title,
        title_text=config.title,
        show_legends=True,
        x_unit=config.x_unit,
        **_shared_plot_kwargs(data, config, plot_spec),
    )


@timed
def _render_single_entity_bar(data: pl.DataFrame, config: PlotConfig, plot_spec: PlotSpec) -> go.Figure:
    """Render a bar chart for single-entity (focused) plots without timeseries.

    Uses the same grouped-by-source pattern as tilemap subplots so that RSE
    error bars are correctly skipped for sources without RSE data.
    """
    data = _drop_reference_source_in_diff_view(data, plot_spec, config)
    return create_bar_plot(
        data=data,
        quantity_column=config.quantity_column,
        lower_bound_column=config.lower_bound_column,
        upper_bound_column=config.upper_bound_column,
        first_category_column="source",
        second_category_column=get_second_category_column(plot_spec),
        quantity_title=config.quantity_title,
        first_category_title="",
        second_category_title="",
        orientation="v",
        title_text=config.title,
        show_legends=True,
        **_shared_plot_kwargs(data, config, plot_spec),
    )

@timed
def _render_stacked(data: pl.DataFrame, plot_spec: PlotSpec) -> go.Figure:
    """Render using stacked subplot layout (grouped bars or box plots)."""
    return create_stacked_plot(data, plot_spec)
