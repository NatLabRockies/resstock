"""
Bar plotting helpers for upgrade comparison plots.
"""

from __future__ import annotations


import polars as pl
import plotly.graph_objects as go

from resstockpostproc.shared_utils.generic_plotters.bar_plotter import create_bar_plot
from resstockpostproc.upgrade_comparison.plotters import plot_utils
from resstockpostproc.upgrade_comparison.schema.plot_spec import PlotSpec, QuantityType
from resstockpostproc.upgrade_comparison.schema.workflow_schema import QuantityGroup
from resstockpostproc.upgrade_comparison.schema.workflow_schema import WorkflowConfig

__all__ = ["create_plot"]


def create_plot(data: pl.DataFrame, plot_spec: PlotSpec, workflow: WorkflowConfig) -> go.Figure:
    """Create a bar-style plot based on the plot specification."""
    if plot_spec.quantity_type == QuantityType.prevalence:
        upgrades = data["upgrade_name"].unique(maintain_order=True).to_list()
        upgrade_to_use = upgrades[-1]
        filtered = data.filter(pl.col("upgrade_name") == upgrade_to_use)
        return create_bar_plot(
            data=filtered,
            quantity_column="prevalence",
            first_category_column=plot_spec.quantity_group_name,
            second_category_column=plot_spec.group_by,
            second_category_title=plot_utils.format_label(plot_spec.group_by) if plot_spec.group_by else "",
            quantity_title=plot_utils.get_quantity_title(plot_spec),
            first_category_title="",
            orientation="h",
            title_text=f"Prevalence in Upgrade Scenario: {upgrade_to_use}",
            label_formatter=plot_utils.format_label,
        )

    if isinstance(plot_spec.quantity, QuantityGroup):
        if plot_spec.group_by:
            return create_bar_plot(
                data=data,
                quantity_column=list(reversed(plot_spec.quantity.constituents)),
                first_category_column="upgrade_name",
                second_category_column=plot_spec.group_by,
                second_category_title=plot_utils.format_label(plot_spec.group_by) if plot_spec.group_by else "",
                quantity_title=plot_utils.get_quantity_title(plot_spec),
                first_category_title="Upgrade Scenario",
                orientation="h",
                label_formatter=plot_utils.format_label,
            )
        quantities = list(plot_spec.quantity.constituents)
        if plot_spec.quantity.sum:
            quantities.append(plot_spec.quantity.sum)
        quantity_name = plot_utils.get_quantity_name(plot_spec.quantity)
        quantity_title = plot_utils.get_quantity_title(plot_spec)
        unpivoted = data.unpivot(
            quantities,
            index=["upgrade", "upgrade_name", "model_count"],
            variable_name=quantity_name,
            value_name="Value",
        )
        return create_bar_plot(
            data=unpivoted,
            quantity_column="Value",
            first_category_column="upgrade_name",
            second_category_column=quantity_name,
            second_category_title=quantity_title,
            quantity_title=quantity_title,
            first_category_title="Upgrade Scenario",
            orientation="h",
            label_formatter=plot_utils.format_label,
        )

    return create_bar_plot(
        data=data,
        quantity_column=plot_spec.quantity,
        first_category_column="upgrade_name",
        second_category_column=plot_spec.group_by,
        second_category_title=plot_utils.format_label(plot_spec.group_by) if plot_spec.group_by else "",
        quantity_title=plot_utils.get_quantity_title(plot_spec),
        first_category_title="Upgrade Scenario",
        orientation="h",
        label_formatter=plot_utils.format_label,
    )
