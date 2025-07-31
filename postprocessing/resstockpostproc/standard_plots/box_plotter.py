"""
Box Plotting module for standard plots
--------------------------------------
Handles creation of box plots using Plotly with consistent styling
"""

import numpy as np
import plotly.graph_objects as go
import polars as pl

from resstockpostproc.standard_plots.base_plotter import BasePlotter
from resstockpostproc.standard_plots.schema.plot_spec import PlotSpec


class BoxPlotter(BasePlotter):
    def create_plot(self, data: pl.DataFrame, plot_spec: PlotSpec) -> go.Figure:
        """Create a box plot using Plotly to show distribution and outliers"""
        if isinstance(plot_spec.quantity, str):
            fig = self.create_box_plot(
                data,
                first_category_column="upgrade_name",
                first_category_title="Upgrade Scenario",
                second_category_column=plot_spec.group_by,
                second_category_title=self.format_label(plot_spec.group_by),
                quantity_title=self.get_quantity_title(plot_spec),
            )
        else:
            fig = self.create_box_plot(
                data,
                first_category_column="upgrade_name",
                first_category_title="Upgrade Scenario",
                second_category_column="End Use",
                second_category_title="End Use",
                quantity_title=self.get_quantity_title(plot_spec),
            )
        return fig

    def create_box_plot(
        self,
        data: pl.DataFrame,
        *,
        first_category_column: str = "upgrade_name",  # which column becomes the categorical axis
        second_category_column: str | None = None,
        first_category_title: str | None = None,
        second_category_title: str | None = None,
        quantity_title: str,
        show_kde: bool = True,
        violin_width: float = 0.5,  # relative width for the half-violin overlay
    ) -> go.Figure:
        """
        Render an aggregated box-and-violin plot from the summary produced by
        `prepare_data_for_box_plot`.

        Parameters
        ----------
        data : pl.DataFrame
            Must contain at least:
                q1, median, q3, lower_whisker, upper_whisker, n_points
            and optionally:
                outliers (List[float]), mean, kde_x / kde_y (List columns)
        x_column : str
            Categorical label column (e.g. 'upgrade_name', 'fuel', …).
        y_title : str
            Y-axis title for the numeric quantity.
        show_mean : bool
            If True, places an “x” marker at the arithmetic mean.
        show_outliers : bool
            If True, plots individual outliers as hollow circles.
        show_kde : bool
            If True and the DataFrame has `kde_x` / `kde_y`, draws a half-violin
            density overlay.
        violin_width : float
            Horizontal spread of the violin curve (in axis fraction).

        Returns
        -------
        go.Figure
            A fully styled Plotly figure.
        """

        # ─── Build traces per group ───────────────────────────────────────────────
        fig = go.Figure()

        first_cats = list(reversed(data[first_category_column].unique(maintain_order=True).to_list()))  # preserve order
        firstcat2pos = {cat: i for i, cat in enumerate(first_cats)}

        # ------------------------------------------------------------------
        # Handle optional second-level category
        if has_second_cat := second_category_column is not None:
            second_cats = list(reversed(data[second_category_column].unique(maintain_order=True).to_list()))
            group_gap = 0.1 if len(first_cats) <= 1 else 0.5
            group_spacing = len(first_cats) + group_gap
            centre_offset = (len(first_cats) - 1) / 2
            tickvals = [centre_offset + i * group_spacing for i in range(len(second_cats))]
        else:
            # Treat the first-category itself as the y-axis category list
            second_cats = first_cats
            # Use a unit spacing so each category occupies its own full slot on the y-axis
            # (mirrors the implicit spacing when a second categorical axis is present).
            group_spacing = 1
            tickvals = list(range(len(first_cats)))

        box_thickness = 0.2
        fig.update_layout(
            yaxis={"title": second_category_title},
            xaxis={"title": quantity_title},
            legend_traceorder="reversed",  # display items top-to-bottom in plotting order
        )
        fig.update_layout(
            yaxis={
                "range": [-0.5, len(second_cats) * group_spacing - 0.5],
                "type": "linear",
                "tickmode": "array",
                "tickvals": tickvals,
                "ticktext": second_cats,
                "title": second_category_title or (second_category_column if has_second_cat else first_category_title),
                "showticklabels": True,
                "ticklabelstandoff": 70,
                "tickfont": {"size": 14},
            }
        )
        for category in first_cats:
            fdata = data.filter(pl.col(first_category_column) == category)
            pos = firstcat2pos[category]
            counts = list(reversed(fdata["n_points"].to_list()))
            for j, ct in enumerate(counts):
                # compute the exact y-center you used for your box/KDE
                y_center = firstcat2pos[category] + j * group_spacing
                fig.add_annotation(
                    x=0,
                    y=y_center,
                    text=f"n={ct}  ",
                    showarrow=False,
                    xanchor="right",
                    yanchor="middle",
                    font={"size": 10},
                    xref="paper",
                    # optional pixel offset if you want a little breathing room:
                    xshift=5,
                )
            fig.add_trace(
                go.Box(
                    q1=list(reversed(fdata["q1"].to_list())),
                    median=list(reversed(fdata["median"].to_list())),
                    q3=list(reversed(fdata["q3"].to_list())),
                    lowerfence=list(reversed(fdata["lower_whisker"].to_list())),
                    upperfence=list(reversed(fdata["upper_whisker"].to_list())),
                    mean=list(reversed(fdata["mean"].to_list())),
                    marker_color=self.theme.upgrade_palette.get(category),
                    marker_size=2,  # Make outlier point size small
                    marker_opacity=0.8,  # Make outlier points partially transparent
                    orientation="h",
                    y0=pos,
                    dy=group_spacing,
                    width=box_thickness,
                    whiskerwidth=0.6,
                    x=[lst if lst else [np.nan] for lst in list(reversed(fdata["outliers"].to_list()))],  # type: ignore
                    customdata=list(reversed(fdata["outlier_buildings"].to_list())),
                    boxpoints="all",
                    boxmean=True,
                    hoveron="boxes+points",
                    hovertemplate=f"<b>{category}</b><br>Building = %{{customdata}}<br>Value = %{{x:.2f}}<br>",
                    name=category,
                    legendgroup=category,
                    showlegend=has_second_cat,  # hide legend if only one categorical axis
                )
            )

            # ---------------- KDE trace(s) ---------------------------------------
            if show_kde and ("kde_x" in fdata.columns) and ("kde_y" in fdata.columns):
                # Each row of fdata corresponds to one second-category entry; both
                # `kde_x` and `kde_y` are stored as list columns.
                for j, (x_kde, y_kde) in enumerate(
                    zip(list(reversed(fdata["kde_x"].to_list())), list(reversed(fdata["kde_y"].to_list())))
                ):
                    if x_kde is None or y_kde is None or len(x_kde) == 0:
                        continue  # nothing to draw

                    x_arr = np.asarray(x_kde)
                    y_arr = np.asarray(y_kde)
                    dens = y_arr / y_arr.max() * violin_width  # scale to desired width

                    # Build closed polygon around the density curve
                    x_v = np.concatenate([x_arr, x_arr[::-1]])
                    y_center = pos + j * group_spacing
                    y_v = np.concatenate([y_center + dens, y_center - dens[::-1]])

                    fig.add_trace(
                        go.Scatter(
                            x=x_v,
                            y=y_v,
                            zorder=-1,
                            mode="lines",
                            fill="toself",
                            line_color="rgba(0,0,0,0.6)",
                            line_width=1,
                            fillcolor="rgba(240,242,241,0.8)",  # transparent fill
                            hoverinfo="skip",
                            legendgroup=category,
                            showlegend=False,  # legend handled by the box trace
                        )
                    )
        self.theme.apply_layout(fig)
        return fig
