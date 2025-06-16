"""
Plotting module for standard plots
----------------------------------
Handles creation of plots using Plotly with consistent styling
"""


import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import polars as pl
from plotly.subplots import make_subplots

from resstockpostproc.standard_plots.schema.plot_spec import PlotSpec
from resstockpostproc.standard_plots.schema.workflow_schema import QuantityGroup

from .base_plotter import BasePlotter


class BarPlotter(BasePlotter):
    """Generates standardized bar / stacked bar plots with consistent styling."""

    def __init__(self, theme_cfg: dict | None = None):
        super().__init__(theme_cfg)

    def create_plot(self, data: pl.DataFrame, plot_spec: PlotSpec) -> go.Figure:
        """Create a plot based on the plot spec."""

        if isinstance(plot_spec.quantity, QuantityGroup):
            fig = self.create_stacked_bar_plot(
                data=data, constituent_cols=plot_spec.quantity.constituents, sum_col=plot_spec.quantity.sum, facet_column=plot_spec.group_by if plot_spec.group_by else None
            )
        elif plot_spec.group_by:
            fig = self.create_bar_plot(data=data, x_column=plot_spec.group_by, y_column=plot_spec.quantity, group_column="upgrade_name", title=plot_spec.quantity)
        else:
            fig = self.create_bar_plot(data=data, x_column="upgrade_name", y_column=plot_spec.quantity, title=plot_spec.quantity)
        # fig.show(renderer="browser")
        return fig

    def create_bar_plot(
        self,
        *,
        data: pl.DataFrame,
        x_column: str,
        y_column: str,
        group_column: str | None = None,
        title: str | None = None,
        x_label: str | None = None,
        y_label: str | None = None,
    ) -> go.Figure:
        """Grouped (simple) bar plot."""
        plot_data = data.to_pandas()
        fig = px.bar(
            plot_data,
            x=x_column,
            y=y_column,
            color=group_column,
            barmode="group",
            title=title,
            labels={
                x_column: x_label or x_column.replace("in.", "").replace("_", " ").title(),
                y_column: y_label or y_column.split(".")[-1].replace("_", " ").title(),
            },
            template=self.theme.template,
            color_discrete_map=self.theme.color_palette,
        )

        self.theme.apply_layout(fig)
        fig.update_layout(
            legend={
                "orientation": "v",
                "x": 1.02,
                "y": 1,
                "xanchor": "left",
                "yanchor": "top",
                "title": {"text": "Upgrade Name"},
            }
        )
        fig.update_yaxes(gridcolor="lightgray", gridwidth=0.5)
        fig.update_xaxes(tickangle=45 if x_column != "upgrade_name" else 0)
        return fig

    def create_stacked_bar_plot(
        self,
        data: pl.DataFrame,
        constituent_cols: list[str],
        *,
        sum_col: str | None = None,
        x_column: str = "upgrade_name",
        hue: str = "upgrade_name",
        facet_column: str | None = None,
        title: str | None = None,
        x_label: str | None = None,
        y_label: str | None = None,
    ) -> go.Figure:
        """Stacked (optionally faceted) bar plot."""

        plot_data = data.to_pandas()

        # -------------------------------------- helpers
        def _fuel_name(col: str) -> str:
            if "." in col:
                parts = col.split(".")
                col = parts[2] if len(parts) > 2 and parts[1] in {"bills", "emissions"} else parts[1]
            return col.replace("_", " ").title()

        legend_added: set[str] = set()

        # Faceting setup
        facet_vals: list[str | None] = [None] if facet_column is None else list(plot_data[facet_column].unique())
        if facet_column is None:
            fig = make_subplots(rows=1, cols=1)
        else:
            # Create wrapped titles for facets
            wrapped_titles = []
            for v in facet_vals:
                title_text = str(v).replace("in.", "").replace("_", " ").title()
                # Add line breaks for longer titles
                if len(title_text) > 15:
                    words = title_text.split()
                    wrapped: list[str] = []
                    line: list[str] = []
                    for word in words:
                        if len(" ".join([*line, word])) > 15 and line:
                            wrapped.append(" ".join(line))
                            line = [word]
                        else:
                            line.append(word)
                    if line:
                        wrapped.append(" ".join(line))
                    title_text = "<br>".join(wrapped)
                wrapped_titles.append(title_text)

            fig = make_subplots(
                rows=1,
                cols=len(facet_vals),
                subplot_titles=wrapped_titles,
                shared_yaxes=True,
            )

        # Nested helper to add bars and sums for a facet slice
        def _render_slice(f_df: pd.DataFrame, row: int, col_idx: int):
            x_vals = list(f_df[x_column].unique())
            hue_vals = list(f_df[hue].unique()) if hue in f_df.columns else [None]

            cluster_frac = 0.8
            bar_width = cluster_frac / max(len(hue_vals), 1)

            for h_idx, h_val in enumerate(hue_vals):
                h_df = f_df if h_val is None else f_df[f_df[hue] == h_val]
                for x_idx, x_val in enumerate(x_vals):
                    xd = h_df[h_df[x_column] == x_val]
                    if xd.empty:
                        continue

                    x_arg = [x_idx - (cluster_frac / 2) + h_idx * bar_width + (bar_width / 2) if facet_column is None else x_val]

                    for c_idx, col_name in enumerate(constituent_cols):
                        val = xd[col_name].iloc[0] if col_name in xd else 0
                        comp_name = _fuel_name(col_name)
                        show = comp_name not in legend_added
                        if show:
                            legend_added.add(comp_name)
                        fig.add_trace(
                            go.Bar(
                                x=x_arg,
                                y=[val],
                                name=comp_name,
                                marker_color=px.colors.qualitative.Plotly[c_idx % len(px.colors.qualitative.Plotly)],
                                showlegend=show,
                                legendgroup=comp_name,
                                width=bar_width if facet_column is None else None,
                            ),
                            row=row,
                            col=col_idx,
                        )

            # Sum markers
            if sum_col:
                xs, ys = [], []
                for x_val in x_vals:
                    sub = f_df[f_df[x_column] == x_val]
                    if sub.empty:
                        continue
                    xs.append(x_vals.index(x_val) if facet_column is None else x_val)
                    ys.append(sub[sum_col].iloc[0])

                comp_name = _fuel_name(sum_col)
                show = comp_name not in legend_added
                if show:
                    legend_added.add(comp_name)

                fig.add_trace(
                    go.Scatter(
                        x=xs,
                        y=ys,
                        mode="markers",
                        marker={"symbol": "diamond", "color": "black", "size": 10},
                        name=comp_name,
                        showlegend=show,
                        legendgroup=comp_name,
                    ),
                    row=row,
                    col=col_idx,
                )

        # Render each facet slice
        for f_idx, f_val in enumerate(facet_vals):
            slice_df = plot_data if f_val is None else plot_data[plot_data[facet_column] == f_val]
            _render_slice(slice_df, row=1, col_idx=(f_idx + 1) if facet_column else 1)

        # Layout tweaks
        y_axis_label = y_label or (sum_col.split(".")[-1].replace("_", " ").title() if sum_col else constituent_cols[0].split(".")[-1].replace("_", " ").title())

        fig.update_layout(
            title=title,
            barmode="stack",
            template=self.theme.template,
            font={"family": "Arial", "size": 12},
            legend={"orientation": "v", "x": 1.02, "y": 1, "xanchor": "left", "yanchor": "top"},
            margin={"l": 50, "r": 50 if facet_column else 150, "t": 80, "b": 50},
            plot_bgcolor="white",
            height=self.theme.fig_height if facet_column else None,
            width=(120 * len(facet_vals) + 150) if facet_column else None,
            yaxis_title=y_axis_label,
            xaxis_title=x_label or x_column.replace("in.", "").replace("_", " ").title(),
        )

        if facet_column is None:
            x_vals = list(plot_data[x_column].unique())
            fig.update_xaxes(
                tickmode="array",
                tickvals=list(range(len(x_vals))),
                ticktext=[str(v).replace("in.", "").replace("_", " ").title() for v in x_vals],
                tickangle=45 if x_column != "upgrade_name" else 0,
            )
        else:
            for i in range(len(facet_vals)):
                fig.update_yaxes(title=y_axis_label if i == 0 else None, gridcolor="lightgray", gridwidth=0.5, col=i + 1)
                fig.update_xaxes(title="", col=i + 1)

        fig.update_yaxes(gridcolor="lightgray", gridwidth=0.5)
        return fig
