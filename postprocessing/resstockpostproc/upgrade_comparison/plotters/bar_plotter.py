"""
Bar plotting helpers for upgrade comparison plots.
"""

from __future__ import annotations

from typing import Literal

import polars as pl
import plotly.graph_objects as go

from resstockpostproc.upgrade_comparison.plotters import plot_utils
from resstockpostproc.upgrade_comparison import theme
from resstockpostproc.upgrade_comparison.schema.plot_spec import PlotSpec, QuantityType
from resstockpostproc.upgrade_comparison.schema.workflow_schema import QuantityGroup

__all__ = ["create_plot"]


def create_plot(data: pl.DataFrame, plot_spec: PlotSpec) -> go.Figure:
    """Create a bar-style plot based on the plot specification."""
    if plot_spec.quantity_type == QuantityType.prevalence:
        upgrades = data["upgrade_name"].unique(maintain_order=True).to_list()
        upgrade_to_use = upgrades[-1]
        filtered = data.filter(pl.col("upgrade_name") == upgrade_to_use)
        return _create_bar_plot(
            data=filtered,
            quantity_column="prevalence",
            first_category_column=plot_spec.quantity_group_name,
            second_category_column=plot_spec.group_by,
            second_category_title=plot_utils.format_label(plot_spec.group_by) if plot_spec.group_by else "",
            quantity_title=plot_utils.get_quantity_title(plot_spec),
            first_category_title="",
            orientation="h",
            title_text=f"Prevalence in Upgrade Scenario: {upgrade_to_use}",
        )

    if isinstance(plot_spec.quantity, QuantityGroup):
        if plot_spec.group_by:
            return _create_bar_plot(
                data=data,
                quantity_column=list(reversed(plot_spec.quantity.constituents)),
                first_category_column="upgrade_name",
                second_category_column=plot_spec.group_by,
                second_category_title=plot_utils.format_label(plot_spec.group_by) if plot_spec.group_by else "",
                quantity_title=plot_utils.get_quantity_title(plot_spec),
                first_category_title="Upgrade Scenario",
                orientation="h",
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
        return _create_bar_plot(
            data=unpivoted,
            quantity_column="Value",
            first_category_column="upgrade_name",
            second_category_column=quantity_name,
            second_category_title=quantity_title,
            quantity_title=quantity_title,
            first_category_title="Upgrade Scenario",
            orientation="h",
        )

    return _create_bar_plot(
        data=data,
        quantity_column=plot_spec.quantity,
        first_category_column="upgrade_name",
        second_category_column=plot_spec.group_by,
        second_category_title=plot_utils.format_label(plot_spec.group_by) if plot_spec.group_by else "",
        quantity_title=plot_utils.get_quantity_title(plot_spec),
        first_category_title="Upgrade Scenario",
        orientation="h",
    )


def _create_bar_plot(
    *,
    data: pl.DataFrame,
    quantity_column: list[str] | str,
    first_category_column: str,
    second_category_column: str | None = None,
    quantity_title: str,
    first_category_title: str,
    second_category_title: str | None = None,
    orientation: Literal["h", "v"] = "h",
    title_text: str = "",
) -> go.Figure:
    """
    Creates a simple, grouped or stacked bar plot depending on the inputs.
    """
    upgrade_palette: dict[str, str] = {}
    if "upgrade_name" in data.columns:
        upgrade_palette.update(theme.build_upgrade_palette(data["upgrade_name"].unique(maintain_order=True).to_list()))
    is_stacked = not (isinstance(quantity_column, str) or second_category_column is None)
    quantity_cols = [quantity_column] if isinstance(quantity_column, str) else list(quantity_column)
    traces: list[go.Bar] = []
    xtitle: str | None = ""
    ytitle: str | None = ""
    ytickvals: list[str] | None = None

    if second_category_column is None:
        legend_title = None
        for qcol in quantity_cols[::-1]:
            if orientation == "h":
                x_data = list(reversed(data[qcol]))
                y_data = list(reversed(data[first_category_column]))
                xtitle, ytitle = quantity_title, first_category_title
                colors = [upgrade_palette.get(y, "#626D72") for y in y_data]
            else:
                x_data = list(reversed(data[first_category_column]))
                y_data = list(reversed(data[qcol]))
                xtitle, ytitle = first_category_title, quantity_title
                colors = [upgrade_palette.get(x, "#626D72") for x in x_data]

            if len(quantity_cols) > 1:
                marker_pattern_shape = theme.END_USE_TO_PATTERN.get(qcol, None)
                marker_color: list[str | None] | list[str] | str | None = theme.END_USE_TO_COLOR.get(qcol, None)
            else:
                marker_color = colors
                marker_pattern_shape = ""
            ytickvals = y_data
            traces.append(
                go.Bar(
                    name=plot_utils.format_label(qcol),
                    x=x_data,
                    y=y_data,
                    orientation=orientation,
                    marker_color=marker_color,
                    marker_pattern_shape=marker_pattern_shape,
                    marker_line_width=5,
                    showlegend=is_stacked,
                    hovertemplate="%{x}<br>%{y}" if orientation == "h" else "%{y}<br>%{x}",
                )
            )
    else:
        unique_groups = data[first_category_column].unique(maintain_order=True).to_list()
        legend_title = first_category_title if not is_stacked else quantity_title

        for q_idx, qcol in enumerate(quantity_cols[::-1]):
            for idx, group_name in enumerate(unique_groups):
                group_data = data.filter(pl.col(first_category_column) == group_name)
                if len(quantity_cols) > 1:
                    marker_pattern_shape = theme.END_USE_TO_PATTERN.get(qcol, None)
                    marker_color = theme.END_USE_TO_COLOR.get(qcol, None)
                else:
                    marker_color = upgrade_palette.get(group_name)
                    marker_pattern_shape = ""

                if orientation == "h":
                    xvals = list(reversed(group_data[qcol]))
                    yvals = list(reversed(group_data[second_category_column]))
                    model_counts = list(reversed(group_data["model_count"]))
                else:
                    xvals = group_data[second_category_column].to_list()
                    yvals = group_data[qcol].to_list()
                    model_counts = group_data["model_count"].to_list()

                text_vals = None
                if is_stacked and q_idx == 0:
                    text_vals = [""] * (len(xvals) - 1) + [group_name]
                traces.append(
                    go.Bar(
                        name=plot_utils.format_label(qcol) if is_stacked else group_name,
                        legendgroup=plot_utils.format_label(qcol),
                        offsetgroup=str(group_name),
                        x=xvals,
                        y=yvals,
                        orientation=orientation,
                        marker_color=marker_color,
                        marker_pattern_shape=marker_pattern_shape,
                        text=text_vals,
                        textposition="outside",
                        textfont={"color": "black"},
                        insidetextanchor="middle",
                        cliponaxis=False,
                        showlegend=(idx == 0) or (not is_stacked),
                        hovertext=[f"Number of models: {mc}" for mc in model_counts],
                        hoverinfo="all",
                        customdata=model_counts,
                    )
                )
                ytickvals = yvals
        xtitle, ytitle = (
            (quantity_title, second_category_title) if orientation == "h" else (second_category_title, quantity_title)
        )

    fig = go.Figure(
        data=traces[::-1] if orientation == "h" else traces,
        layout=go.Layout(
            title_text=title_text,
            barmode="relative" if is_stacked else "group",
            xaxis_title=xtitle,
            yaxis_title=ytitle,
            template=theme.DEFAULT_TEMPLATE,
        ),
    )
    fig.update_yaxes(title_text="", type="category", tickmode="array", tickvals=ytickvals)
    if orientation == "h":
        fig.update_layout(legend_traceorder="reversed")
    theme.apply_layout(fig)
    if legend_title:
        fig.update_layout(legend_title_text=legend_title, legend={"xanchor": "left", "x": 1.12})

    return fig
