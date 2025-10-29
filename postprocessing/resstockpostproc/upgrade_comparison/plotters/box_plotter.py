"""
Box plotting helpers for upgrade comparison plots.
"""

from __future__ import annotations

import numpy as np
import plotly.graph_objects as go
import polars as pl

__all__ = ["create_plot"]

from resstockpostproc.upgrade_comparison.plotters import plot_utils
from resstockpostproc.upgrade_comparison import theme
from resstockpostproc.upgrade_comparison.schema.plot_spec import PlotSpec


def create_plot(data: pl.DataFrame, plot_spec: PlotSpec) -> go.Figure:
    """Create a box plot using Plotly to show distribution and outliers."""
    if isinstance(plot_spec.quantity, str):
        return _create_box_plot(
            data,
            first_category_column="upgrade_name",
            first_category_title="Upgrade Scenario",
            second_category_column=plot_spec.group_by,
            second_category_title=plot_utils.format_label(plot_spec.group_by),
            quantity_title=plot_utils.get_quantity_title(plot_spec),
        )
    return _create_box_plot(
        data,
        first_category_column="upgrade_name",
        first_category_title="Upgrade Scenario",
        second_category_column="End Use",
        second_category_title="End Use",
        quantity_title=plot_utils.get_quantity_title(plot_spec),
    )


def _create_box_plot(
    data: pl.DataFrame,
    *,
    first_category_column: str = "upgrade_name",
    second_category_column: str | None = None,
    first_category_title: str | None = None,
    second_category_title: str | None = None,
    quantity_title: str,
    show_kde: bool = True,
    violin_width: float = 0.5,
) -> go.Figure:
    """Render a box-and-violin plot from the summary produced upstream."""
    fig = go.Figure()

    first_cats = list(reversed(data[first_category_column].unique(maintain_order=True).to_list()))
    upgrade_palette = theme.build_upgrade_palette(first_cats)
    firstcat2pos = {cat: i for i, cat in enumerate(first_cats)}

    if second_category_column is not None:
        second_cats = list(reversed(data[second_category_column].unique(maintain_order=True).to_list()))
        group_gap = 0.1 if len(first_cats) <= 1 else 0.5
        group_spacing = len(first_cats) + group_gap
        centre_offset = (len(first_cats) - 1) / 2
        tickvals = [centre_offset + i * group_spacing for i in range(len(second_cats))]
        has_second_cat = True
    else:
        second_cats = first_cats
        group_spacing = 1
        tickvals = list(range(len(first_cats)))
        has_second_cat = False

    box_thickness = 0.2
    fig.update_layout(
        yaxis={"title": second_category_title},
        xaxis={"title": quantity_title},
        legend_traceorder="reversed",
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
                marker_color=upgrade_palette.get(category),
                marker_size=2,
                marker_opacity=0.8,
                orientation="h",
                y0=pos,
                dy=group_spacing,
                width=box_thickness,
                whiskerwidth=0.6,
                x=[lst if lst else [np.nan] for lst in list(reversed(fdata["outliers"].to_list()))],  # type: ignore[arg-type]
                customdata=list(reversed(fdata["outlier_buildings"].to_list())),
                boxpoints="outliers",
                pointpos=0.2,
                boxmean=True,
                hoveron="boxes+points",
                hovertemplate=f"<b>{category}</b><br>Building = %{{customdata}}<br>Value = %{{x:.2f}}<br>",
                name=category,
                legendgroup=category,
                showlegend=has_second_cat,
            )
        )

        if show_kde and ("kde_x" in fdata.columns) and ("kde_y" in fdata.columns):
            for j, (x_kde, y_kde) in enumerate(
                zip(
                    list(reversed(fdata["kde_x"].to_list())),
                    list(reversed(fdata["kde_y"].to_list())),
                )
            ):
                if not x_kde or not y_kde:
                    continue
                x_arr = np.asarray(x_kde)
                y_arr = np.asarray(y_kde)
                dens = y_arr / y_arr.max() * violin_width
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
                        fillcolor="rgba(240,242,241,0.8)",
                        hoverinfo="skip",
                        legendgroup=category,
                        showlegend=False,
                    )
                )

    min_val = data["min"].min()
    max_val = data["max"].max()
    fig.update_xaxes(tick0=min_val, range=[min_val, max_val])
    theme.apply_layout(fig)
    return fig
