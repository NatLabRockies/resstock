"""RECS / EIA plotter – thin wrapper around the unified main_plotter.

All column-resolution, title-generation, and rendering logic now lives in
plot_config.py and main_plotter.py.  This module exists so that
plot_generator.py can continue to call ``recs_plotter.create_plot``.
"""

import polars as pl
import plotly.graph_objects as go

from resstockpostproc.shared_utils.timing import timed
from resstockpostproc.baseline_validation.schema.plot_spec import PlotSpec
from resstockpostproc.baseline_validation.plotters.main_plotter import create_plot as _create_plot

@timed
def create_plot(data: pl.DataFrame, plot_spec: PlotSpec) -> tuple[go.Figure, str]:
    """Create a RECS or EIA validation plot.

    Delegates entirely to :func:`main_plotter.create_plot`, which builds a
    ``PlotConfig`` from the spec and dispatches to the appropriate renderer
    (tilemap, single-entity timeseries, or distribution/box plot).

    Args:
        data: Pre-processed DataFrame from ``apply_plot_spec()``.
        plot_spec: Plot specification defining what to render.

    Returns:
        Tuple of (Plotly figure, title string).
    """
    return _create_plot(data, plot_spec)
