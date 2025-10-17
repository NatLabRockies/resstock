"""
Plotting module for standard plots
----------------------------------
Handles creation of plots using Plotly with consistent styling
"""

import plotly.graph_objects as go
import polars as pl

from resstockpostproc.standard_plots.base_plotter import BasePlotter
from resstockpostproc.standard_plots.schema.plot_spec import PlotSpec, QuantityType
from resstockpostproc.standard_plots.schema.workflow_schema import QuantityGroup
from typing import Literal


class BarPlotter(BasePlotter):
    def create_plot(self, data: pl.DataFrame, plot_spec: PlotSpec) -> go.Figure:
        """Create a plot based on the plot spec."""
        if isinstance(plot_spec.quantity, QuantityGroup):
            if plot_spec.group_by:  # show as stacked bar plot
                return self.create_bar_plot(
                    data=data,
                    quantity_column=list(reversed(plot_spec.quantity.constituents)),
                    first_category_column="upgrade_name",
                    second_category_column=plot_spec.group_by,
                    second_category_title=self.format_label(plot_spec.group_by) if plot_spec.group_by else "",
                    quantity_title=self.get_quantity_title(plot_spec),
                    first_category_title="Upgrade Scenario",
                    orientation="h",
                )
            else:  # show as grouped bar plot where y-axis is various constituents of the quantity group
                quantities = list(plot_spec.quantity.constituents)
                quantities += [plot_spec.quantity.sum] if plot_spec.quantity.sum else []
                quantity_name = self.get_quantity_name(plot_spec.quantity)
                quantity_title = self.get_quantity_title(plot_spec)
                data = data.unpivot(
                    quantities,
                    index=["upgrade", "upgrade_name", "model_count"],
                    variable_name=quantity_name,
                    value_name="Value",
                )
                return self.create_bar_plot(
                    data=data,
                    quantity_column="Value",
                    first_category_column="upgrade_name",
                    second_category_column=quantity_name,
                    second_category_title=quantity_title,
                    quantity_title=quantity_title,
                    first_category_title="Upgrade Scenario",
                    orientation="h",
                )
        elif plot_spec.quantity_type == QuantityType.prevalence:
            return self.create_bar_plot(
                data=data,
                quantity_column="prevalence",
                first_category_column=plot_spec.quantity,
                second_category_column=plot_spec.group_by,
                second_category_title=self.format_label(plot_spec.group_by) if plot_spec.group_by else "",
                quantity_title=self.get_quantity_title(plot_spec),
                first_category_title=plot_spec.quantity,
                orientation="h",
            )

        # For simple bars, the quantity is the x-axis
        return self.create_bar_plot(
            data=data,
            quantity_column=plot_spec.quantity,
            first_category_column="upgrade_name",
            second_category_column=plot_spec.group_by,
            second_category_title=self.format_label(plot_spec.group_by) if plot_spec.group_by else "",
            quantity_title=self.get_quantity_title(plot_spec),
            first_category_title="Upgrade Scenario",
            orientation="h",
        )

    def create_bar_plot(
        self,
        *,
        data: pl.DataFrame,
        quantity_column: list[str] | str,  # <- now Union
        first_category_column: str,
        second_category_column: str | None = None,
        quantity_title: str,
        first_category_title: str,
        second_category_title: str | None = None,
        orientation: Literal["h", "v"] = "h",
    ) -> go.Figure:
        """
        Creates a simple, grouped or stacked bar plot.

        * If ``quantity_column`` is a single string (as before) → 1 trace /
        group (“simple” or “grouped”).
        * If ``quantity_column`` is a list of strings → stacked bars whose
        segments correspond to those columns, using the order given in the
        list (last item plotted first so it ends up on top).
        """
        # ------------------------------------------------------------------ #
        # NORMALISE INPUT                                                    #
        # ------------------------------------------------------------------ #
        is_stacked = not (isinstance(quantity_column, str) or second_category_column is None)
        quantity_cols = (
            [quantity_column]
            if isinstance(quantity_column, str)  # old behaviour
            else list(quantity_column)  # keep caller order
        )
        traces: list[go.Bar] = []
        xtitle: str | None = ""
        ytitle: str | None = ""
        ytickvals: list[str] | None = None
        # ------------------------------------------------------------------ #
        # NO SECOND-LEVEL CATEGORY  →  ONE STACK (OR ONE TRACE)              #
        # ------------------------------------------------------------------ #
        if second_category_column is None:
            legend_title = None
            for qcol in quantity_cols[::-1]:  # reverse so first col is at bottom
                if orientation == "h":
                    x_data = list(reversed(data[qcol]))
                    y_data = list(reversed(data[first_category_column]))
                    xtitle, ytitle = quantity_title, first_category_title
                    colors = [self.theme.upgrade_palette.get(y, "#626D72") for y in y_data]
                else:
                    x_data = list(reversed(data[first_category_column]))
                    y_data = list(reversed(data[qcol]))
                    xtitle, ytitle = first_category_title, quantity_title
                    colors = [self.theme.upgrade_palette.get(x, "#626D72") for x in x_data]

                if len(quantity_cols) > 1:
                    marker_pattern_shape = self.theme.end_use_to_pattern.get(qcol, None)
                    marker_color: list[str | None] | str | None = self.theme.end_use_to_color.get(qcol, None)
                else:
                    marker_color = colors
                    marker_pattern_shape = ""
                ytickvals = y_data
                traces.append(
                    go.Bar(
                        name=self.format_label(qcol),
                        x=x_data,
                        y=y_data,
                        orientation=orientation,
                        marker_color=marker_color,
                        marker_pattern_shape=marker_pattern_shape,
                        marker_line_width=5,
                        showlegend=is_stacked,  # hide legend when single trace
                        hovertemplate="%{x}<br>%{y}" if orientation == "h" else "%{y}<br>%{x}",
                    )
                )
        # ------------------------------------------------------------------ #
        # SECOND-LEVEL CATEGORY  →  GROUPED (AND *OPTIONALLY* STACKED)       #
        # ------------------------------------------------------------------ #
        else:
            unique_groups = data[first_category_column].unique(maintain_order=True).to_list()
            legend_title = first_category_title if not is_stacked else quantity_title

            for q_idx, qcol in enumerate(quantity_cols[::-1]):  # stack order inside each offsetgroup
                for idx, group_name in enumerate(unique_groups):
                    group_data = data.filter(pl.col(first_category_column) == group_name)
                    if len(quantity_cols) > 1:
                        marker_pattern_shape = self.theme.end_use_to_pattern.get(qcol, None)
                        marker_color = self.theme.end_use_to_color.get(qcol, None)
                    else:
                        marker_color = self.theme.upgrade_palette.get(group_name, None)
                        marker_pattern_shape = ""

                    if orientation == "h":  # reverse for visual top-to-bottom
                        xvals = list(reversed(group_data[qcol]))
                        yvals = list(reversed(group_data[second_category_column]))
                        model_counts = list(reversed(group_data["model_count"]))
                    else:
                        xvals = group_data[second_category_column].to_list()
                        yvals = group_data[qcol].to_list()
                        model_counts = group_data["model_count"].to_list()

                    # Include upgrade label only on the topmost segment of each stack
                    text_vals = None
                    if is_stacked and q_idx == 0:
                        text_vals = [""] * (len(xvals) - 1) + [group_name]
                    traces.append(
                        go.Bar(
                            name=self.format_label(qcol) if is_stacked else group_name,
                            legendgroup=self.format_label(qcol),  # one legend per qcol
                            offsetgroup=str(group_name),  # separate clusters per group
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
                (quantity_title, second_category_title)
                if orientation == "h"
                else (second_category_title, quantity_title)
            )

        # ------------------------------------------------------------------ #
        # FIGURE ASSEMBLY                                                    #
        # ------------------------------------------------------------------ #
        fig = go.Figure(
            data=traces[::-1] if orientation == "h" else traces,
            layout=go.Layout(
                title_text="",
                barmode="relative" if is_stacked else "group",  # <-- key change
                xaxis_title=xtitle,
                yaxis_title=ytitle,
                template=self.theme.template,
            ),
        )
        fig.update_yaxes(title_text="", type="category", tickmode="array", tickvals=ytickvals)
        if orientation == "h":
            fig.update_layout(legend_traceorder="reversed")
        self.theme.apply_layout(fig)
        if legend_title:
            fig.update_layout(legend_title_text=legend_title, legend={"xanchor": "left", "x": 1.12})

        return fig
