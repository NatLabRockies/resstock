"""
Box plotting helpers for upgrade comparison plots.
"""

from __future__ import annotations

import plotly.graph_objects as go
import polars as pl

__all__ = ["create_plot"]

from resstockpostproc.shared_utils.generic_plotters.box_plotter import create_box_plot
from resstockpostproc.upgrade_comparison.schema.workflow_schema import WorkflowConfig
from resstockpostproc.upgrade_comparison.plotters import plot_utils
from resstockpostproc.upgrade_comparison.schema.plot_spec import PlotSpec


def create_plot(data: pl.DataFrame, plot_spec: PlotSpec, workflow: WorkflowConfig) -> go.Figure:
    """Create a box plot using Plotly to show distribution and outliers."""
    if isinstance(plot_spec.quantity, str):
        return create_box_plot(
            data,
            first_category_column="upgrade_name",
            first_category_title="Upgrade Scenario",
            second_category_column=plot_spec.group_by,
            second_category_title=plot_utils.format_label(plot_spec.group_by),
            quantity_title=plot_utils.get_quantity_title(plot_spec),
        )
    return create_box_plot(
        data,
        first_category_column="upgrade_name",
        first_category_title="Upgrade Scenario",
        second_category_column="End Use",
        second_category_title="End Use",
        quantity_title=plot_utils.get_quantity_title(plot_spec),
    )
