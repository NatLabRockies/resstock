"""
Plotting module for standard plots
----------------------------------
Handles creation of plots using Plotly with consistent styling
"""

import plotly.express as px
import plotly.graph_objects as go
import textwrap
import polars as pl
from resstockpostproc.standard_plots.schema.plot_spec import PlotSpec
from resstockpostproc.standard_plots.schema.workflow_schema import QuantityGroup
from resstockpostproc.standard_plots.base_plotter import BasePlotter


class BarPlotter(BasePlotter):
    """Generates standardized bar / stacked bar plots with consistent styling."""

    def __init__(self, theme_cfg: dict | None = None):
        super().__init__(theme_cfg)

    def _format_label(self, label: str) -> str:
        """Cleans up a column name to be a human-readable label."""
        # Handle cases like 'bills.electricity' -> 'Electricity'
        if "." in label:
            label = label.split(".")[-1]
        return label.replace("in.", "").replace("_", " ").title()

    def create_plot(self, data: pl.DataFrame, plot_spec: PlotSpec) -> go.Figure:
        """Create a plot based on the plot spec."""
        if isinstance(plot_spec.quantity, QuantityGroup):
            # For stacked bars, the quantity group defines what to stack
            return self.create_stacked_bar_plot(
                data=data,
                constituent_cols=plot_spec.quantity.constituents,
                sum_col=plot_spec.quantity.sum,
                facet_column=plot_spec.group_by,
            )

        # For simple bars, the quantity is the y-axis
        return self.create_bar_plot(
            data=data,
            x_column=plot_spec.group_by or "upgrade_name",
            y_column=plot_spec.quantity,
            group_column="upgrade_name" if plot_spec.group_by else None,
            title=self._format_label(plot_spec.quantity),
        )

    def create_bar_plot(
        self,
        *,
        data: pl.DataFrame,
        x_column: str,
        y_column: str,
        group_column: str | None = None,
        title: str | None = None,
    ) -> go.Figure:
        """Creates a simple or grouped bar plot using Plotly Express."""
        fig = px.bar(
            data,  # Use Polars DataFrame directly
            x=x_column,
            y=y_column,
            color=group_column,
            barmode="group",
            title=title,
            labels={col: self._format_label(col) for col in [x_column, y_column, group_column] if col},
            template=self.theme.template,
            color_discrete_map=self.theme.color_palette,
        )

        self.theme.apply_layout(fig)
        fig.update_layout(
            legend_title_text=self._format_label(group_column or ""),
            xaxis_tickangle=45 if x_column != "upgrade_name" else 0,
        )
        fig.update_yaxes(gridcolor="lightgray", gridwidth=0.5)
        return fig

    def create_stacked_bar_plot(
        self,
        *,
        data: pl.DataFrame,
        constituent_cols: list[str],
        sum_col: str | None = None,
        x_column: str = "upgrade_name",
        facet_column: str | None = None,
    ) -> go.Figure:
        """Creates a stacked, optionally faceted bar plot by first reshaping the data."""
        id_cols = ["upgrade", "upgrade_name"]
        if facet_column:
            id_cols.append(facet_column)
        if sum_col:
            melted_data = data.drop(sum_col).unpivot(index=id_cols, variable_name="enduse")
        else:
            melted_data = data.unpivot(index=id_cols, variable_name="enduse")

        fig = px.bar(
            melted_data,
            x=x_column,
            y="value",
            color="enduse",
            color_discrete_map=self.theme.end_use_to_color,
            facet_col=facet_column,
            template=self.theme.template,
            pattern_shape="enduse",
            pattern_shape_map=self.theme.end_use_to_pattern,
            category_orders={"enduse": constituent_cols[::-1]},
        )

        if sum_col and sum_col in data.columns:
            # If there are no facets, add the trace directly
            if not facet_column:
                fig.add_trace(
                    go.Scatter(
                        x=data[x_column].to_list(),
                        y=data[sum_col].to_list(),
                        mode="markers",
                        marker={"symbol": "diamond", "color": "black", "size": 10},
                        name=sum_col,
                        legendgroup=sum_col,
                        showlegend=True,
                    )
                )
            # If there are facets, iterate and add a trace to each subplot
            else:
                facets = data[facet_column].unique().sort()
                for i, facet_value in enumerate(facets):
                    facet_data = data.filter(pl.col(facet_column) == facet_value)
                    fig.add_trace(
                        go.Scatter(
                            x=facet_data[x_column].to_list(),
                            y=facet_data[sum_col].to_list(),
                            mode="markers",
                            marker={"symbol": "diamond", "color": "black", "size": 10},
                            name=sum_col,
                            legendgroup=sum_col,
                            showlegend=(i == 0),  # Only show legend for the first trace
                        ),
                        row=1,
                        col=i + 1,
                    )  # Specify row and column for the trace

        self.theme.apply_layout(fig)
        # Use "relative" barmode so that negative values are stacked below the zero line
        fig.update_layout(barmode="relative", legend={"traceorder": "reversed"})
        fig.update_yaxes(gridcolor="lightgray", gridwidth=0.5, title_text="Energy Consumption (kWh)")
        fig.update_xaxes(title_text="")
        if facet_column and facet_column in data.columns:
            num_facets = len(data[facet_column].unique())
            for i in range(2, num_facets + 1):  # Remove y-axis titles for all but the first facet
                fig.update_yaxes(title_text="", row=1, col=i)
            fig.update_layout(width=max(1000, min(1920, num_facets * self.theme.facet_width)))
        # Show only the facet value and wrap long text based on theme's facet_title_width
        fig.for_each_annotation(
            lambda a: a.update(
                text="<br>".join(
                    textwrap.wrap(
                        a.text.split("=")[-1].strip() if a.text is not None else "",
                        width=self.theme.facet_title_width,
                        break_long_words=False,
                    )
                )
            )
        )
        return fig
