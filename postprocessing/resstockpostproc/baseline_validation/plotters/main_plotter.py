"""Main plotter for baseline validation.

This module provides a single entry point for creating all validation plots,
regardless of truth source (RECS, EIA, LRD) or visualization type.
"""

import polars as pl
import plotly.graph_objects as go

from resstockpostproc.baseline_validation.schema.plot_spec import PlotSpec, Resolution
from resstockpostproc.baseline_validation.theme import apply_theme
from resstockpostproc.baseline_validation.plotters.plot_config import (
    build_plot_config,
    PlotConfig,
    get_second_category_column,
    get_second_category_title,
)
from resstockpostproc.baseline_validation.plotters.box_plotter import create_vertical_plot
from resstockpostproc.shared_utils.generic_plotters import tilemap_plotter
from resstockpostproc.shared_utils.generic_plotters.monthly_plotter import create_ts_plot


def create_plot(data: pl.DataFrame, plot_spec: PlotSpec) -> tuple[go.Figure, str]:
    """Create a validation plot from data and specification.

    This is the single entry point for all plot types in baseline validation.
    Handles RECS, EIA, and LRD truth sources with various resolutions and aggregations.

    Args:
        data: Pre-processed DataFrame from apply_plot_spec()
        plot_spec: Plot specification defining what to render

    Returns:
        Tuple of (Plotly figure, title string)
    """
    config = build_plot_config(plot_spec, data)
    fig = _render(data, config, plot_spec)
    fig = apply_theme(fig, title=config.title, height=config.height, width=config.width)
    return fig, config.title


def _render(data: pl.DataFrame, config: PlotConfig, plot_spec: PlotSpec) -> go.Figure:
    """Select appropriate renderer and create the figure."""
    if config.use_distribution_plot:
        return _render_distribution(data, plot_spec)
    elif config.is_single_entity:
        return _render_single_entity_timeseries(data, config)
    else:
        return _render_tilemap(data, config, plot_spec)


def _render_tilemap(data: pl.DataFrame, config: PlotConfig, plot_spec: PlotSpec) -> go.Figure:
    """Render using tilemap layout with bar or timeseries subplots."""
    second_category_column = get_second_category_column(plot_spec)
    second_category_title = get_second_category_title(plot_spec)

    return tilemap_plotter.plot_tilemap(
        data=data,
        quantity_title=config.quantity_title,
        quantity_column=config.quantity_column,
        rse_column=config.rse_column,
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
    )


def _render_single_entity_timeseries(data: pl.DataFrame, config: PlotConfig) -> go.Figure:
    """Render a simple timeseries for single-entity (focused) plots."""
    return create_ts_plot(
        data=data,
        timeseries_column=config.timeseries_column,
        quantity_column=config.quantity_column,
        first_category_column="source",
        rse_column=config.rse_column,
        first_category_title="Data Source",
        quantity_title=config.quantity_title,
        title_text=config.title,
        show_legends=True,
        x_unit=config.x_unit,
        fill_lower_bound=True,
    )


def _render_distribution(data: pl.DataFrame, plot_spec: PlotSpec) -> go.Figure:
    """Render distribution/box plots."""
    return create_vertical_plot(data, plot_spec)
