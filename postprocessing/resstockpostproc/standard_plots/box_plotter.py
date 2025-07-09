"""
Box Plotting module for standard plots
--------------------------------------
Handles creation of box plots using Plotly with consistent styling
"""

import plotly.express as px
import plotly.graph_objects as go
import polars as pl
from plotly.subplots import make_subplots
import textwrap
from resstockpostproc.standard_plots.schema.plot_spec import PlotSpec
from resstockpostproc.standard_plots.schema.workflow_schema import QuantityGroup

from .base_plotter import BasePlotter


class BoxPlotter(BasePlotter):
    """Generates standardized box plots with consistent styling."""

    def __init__(self, theme_cfg: dict | None = None):
        """Initialize with shared ThemeManager."""

        super().__init__(theme_cfg)

    def create_plot(self, data: pl.DataFrame, plot_spec: PlotSpec) -> go.Figure:
        """Create a box plot using Plotly to show distribution and outliers"""
        if isinstance(plot_spec.quantity, QuantityGroup):
            raise ValueError("QuantityGroup is not supported for box plots")
        if plot_spec.group_by:
            fig = self.create_faceted_box_plot(
                data, x_column="upgrade_name", y_column=plot_spec.quantity, facet_column=plot_spec.group_by
            )
        else:
            fig = self.create_box_plot(
                data,
                x_column="upgrade_name",
                y_column=plot_spec.quantity,
            )
        return fig

    def create_box_plot(
        self,
        data: pl.DataFrame,
        x_column: str,
        y_column: str,
    ) -> go.Figure:
        """
        Create a box plot using Plotly to show distribution and outliers

        Args:
            data: Polars DataFrame with the data to plot
            x_column: Name of the column to use for x-axis categories
            y_column: Name of the column to use for y-axis values (distribution)
            hue: Name of the column to use for color grouping
            title: Optional plot title
            x_label: Optional x-axis label
            y_label: Optional y-axis label
            show_outliers: Whether to show outliers as individual points (default: True)
            notched: Whether to create notched box plots (notches represent 95% confidence interval)
            point_position: Control the horizontal position of points for multiple boxes (jitter)

        Returns:
            Plotly figure object with tooltips showing number of datapoints and outliers displayed
        """
        # Build traces
        fig = go.Figure()
        for row in data.to_dicts():
            # Build the Box trace from summary only
            box_trace = go.Box(
                q1=[row["q1"]],
                median=[row["median"]],
                q3=[row["q3"]],
                lowerfence=[row["lowerfence"]],
                upperfence=[row["upperfence"]],
                boxpoints=False,
                legendgroup=row[x_column],
            )
            fig.add_trace(box_trace)

        # Apply theme defaults and axis labels
        self.theme.apply_layout(fig)
        fig.update_layout(boxmode="group")
        fig.update_xaxes(title_text=x_column.replace("_", " ").title())
        fig.update_yaxes(title_text=y_column.replace("_", " ").title())
        fig.update_yaxes(gridcolor="lightgrey")

        return fig

    def create_faceted_box_plot(
        self,
        data: pl.DataFrame,
        x_column: str,
        y_column: str,
        facet_column: str = "in.building_type",
        hue: str | None = "upgrade_name",
        y_label: str | None = None,
        show_outliers: bool = True,  # This ensures outliers are shown by default
        notched: bool = False,
    ) -> go.Figure:
        """
        Create a faceted box plot showing distributions across different categories

        Args:
            data: Polars DataFrame with the data to plot
            x_column: Name of the column to use for x-axis categories
            y_column: Name of the column to use for y-axis values (distribution)
            facet_column: Name of the column to use for faceting
            hue: Name of the column to use for color grouping (set to None for no color grouping)
            title: Optional plot title
            x_label: Optional x-axis label
            y_label: Optional y-axis label
            show_outliers: Whether to show outliers as individual points (default: True)
            notched: Whether to create notched box plots (notches represent 95% confidence interval)

        Returns:
            Plotly figure object with tooltips showing number of datapoints and outliers displayed
        """
        # Convert Polars DataFrame to pandas for easier manipulation
        plot_data = data.to_pandas()

        # Get unique facet values
        facet_values = list(plot_data[facet_column].unique())

        # Create subplots - one for each facet value
        fig = make_subplots(
            rows=1,
            cols=len(facet_values),
            subplot_titles=[str(val).replace("in.", "").replace("_", " ").title() for val in facet_values],
            shared_yaxes=True,
        )

        # Track which categories have already been added to the legend
        legend_added = set()

        # Compute quartiles and stats for each group
        group_cols = [facet_column, x_column]
        if hue:
            group_cols.append(hue)
        group_cols = list(set(group_cols))
        # Precompute statistics for all groups
        stats = data.to_pandas()
        x_values = []
        # For each facet value
        for facet_idx, facet_val in enumerate(facet_values):
            # Filter stats for this facet
            facet_stats = stats[stats[facet_column] == facet_val]

            # Get unique x-values and hue values if applicable
            x_values = list(facet_stats[x_column].unique())
            hue_values = list(facet_stats[hue].unique()) if hue else [None]

            # For each x-value in this facet
            for x_idx, x_val in enumerate(x_values):
                x_stats = facet_stats[facet_stats[x_column] == x_val]

                # For each hue value if applicable
                for hue_idx, hue_val in enumerate(hue_values):
                    if hue_val is not None:
                        hue_stats = x_stats[x_stats[hue] == hue_val]
                        trace_name = str(hue_val)
                    else:
                        hue_stats = x_stats
                        trace_name = str(x_val)

                    if len(hue_stats) == 0:
                        continue

                    # Determine if this category should be shown in the legend
                    show_in_legend = trace_name not in legend_added
                    if show_in_legend:
                        legend_added.add(trace_name)

                    # Get row with stats
                    row_stats = hue_stats.iloc[0]

                    # Position for boxes
                    x_position: float = x_idx
                    box_width = 0.8
                    if hue:
                        box_width = 0.8 / len(hue_values)
                        x_position = x_idx + (hue_idx - (len(hue_values) - 1) / 2) * box_width

                    # Color index
                    color_idx = hue_values.index(hue_val) if hue_val is not None else x_idx

                    # Add the box trace using precomputed statistics
                    fig.add_trace(
                        go.Box(
                            name=trace_name,
                            q1=[row_stats["q1"]],
                            median=[row_stats["median"]],
                            q3=[row_stats["q3"]],
                            lowerfence=[row_stats["lowerfence"]],
                            upperfence=[row_stats["upperfence"]],
                            marker_color=px.colors.qualitative.Plotly[color_idx % len(px.colors.qualitative.Plotly)],
                            showlegend=show_in_legend,
                            legendgroup=trace_name,
                            boxpoints="outliers" if show_outliers else False,
                            notched=notched,
                            x=[x_position],  # Position boxes side by side
                            width=box_width if hue else 0.8,
                            hovertemplate=(
                                f"{trace_name}<br>Count: {row_stats['n_points']}"
                                f"<br>Median: {row_stats['median']:.2f}<extra></extra>"
                            ),
                        ),
                        row=1,
                        col=facet_idx + 1,
                    )

        # Apply theme then customise facet-specific sizing
        self.theme.apply_layout(fig)
        fig.update_layout(
            legend={"orientation": "v", "x": 1.02, "y": 1, "xanchor": "left", "yanchor": "top"},
            boxmode="group",
            width=250 * len(facet_values) + 150,
        )
        num_facets = len(data[facet_column].unique())
        fig.update_layout(width=max(1000, min(1920, num_facets * self.theme.facet_width)))

        # Format Y-axis - only show title on the far left facet
        for i in range(len(facet_values)):
            title_text = y_label if y_label else y_column.split(".")[-1].replace("_", " ").title()
            fig.update_yaxes(
                title=title_text if i == 0 else None,
                gridcolor="lightgray",
                gridwidth=0.5,
                zeroline=True,
                zerolinecolor="darkgray",
                zerolinewidth=1,
                col=i + 1,
            )

        # Format X-axis for each facet
        for i in range(len(facet_values)):
            fig.update_xaxes(
                title="", tickvals=list(range(len(x_values))), ticktext=[str(val) for val in x_values], col=i + 1
            )

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
