"""
Heatmap plotting helpers for standard plots.
"""

from __future__ import annotations

import textwrap

import plotly.express as px
import plotly.graph_objects as go
import polars as pl
from plotly.subplots import make_subplots

__all__ = ["create_plot"]

from resstockpostproc.standard_plots.plotters import plot_utils
from resstockpostproc.standard_plots import theme
from resstockpostproc.standard_plots.schema.plot_spec import PlotSpec
from resstockpostproc.standard_plots.schema.workflow_schema import QuantityGroup


def create_plot(data: pl.DataFrame, plot_spec: PlotSpec) -> go.Figure:
    """Create and return a heatmap figure based on *plot_spec*."""
    if not isinstance(plot_spec.quantity, QuantityGroup):
        raise ValueError("Heatmaps require a QuantityGroup as the quantity definition.")

    constituent_cols: tuple[str, ...] = plot_spec.quantity.constituents
    facet_col: str | None = plot_spec.group_by if plot_spec.group_by else None

    return _create_heatmap_plot(
        data=data,
        constituent_cols=list(constituent_cols),
        x_column="upgrade_name",
        facet_column=facet_col,
    )


def _create_heatmap_plot(
    *,
    data: pl.DataFrame,
    constituent_cols: list[str],
    x_column: str = "upgrade_name",
    facet_column: str | None = None,
) -> go.Figure:
    # Ensure required columns exist and sort by facet if requested so that
    # upgrades appear in the same order across facets.
    data = plot_utils.ensure_columns_exist(data, constituent_cols)

    # --------------------------------------------------------
    # When faceting we need global z-min/max so compute before
    # sub-splitting.
    # --------------------------------------------------------
    z_values = data[constituent_cols].to_numpy().T

    # ------------------------------------------------------------------
    # Build a custom colorscale with a *neutral* gray band around zero.
    # Anything between ``-neutral_th`` and ``+neutral_th`` is mapped to
    # plain gray so that small values do not visually blend with the
    # diverging colors. Outside this range the colors jump immediately
    # to the negative (green) or positive (red) palette.
    # ------------------------------------------------------------------
    neutral_th: float = 1e-3  # ±0.001 band requested by the user
    z_min: float = float(z_values.min())
    z_max: float = float(z_values.max())

    # Guard against the (rare) case where z_min == z_max
    if z_min == z_max:
        z_min -= 1e-6
        z_max += 1e-6

    # Pre-compute tick values for colorbar to ensure the minimum,
    # zero, and maximum values are always labelled on the legend.
    tickvals: list[float] = sorted({z_min, 0.0, z_max})

    # Helper to convert a *real* z value into a 0-1 normalized position for
    # the colorscale definition expected by Plotly.
    def _norm(val: float) -> float:
        return (val - z_min) / (z_max - z_min)

    # Clip the neutral band to the available data range so that we never
    # produce invalid (<0 or >1) positions.
    neg_end = max(0.0, min(1.0, _norm(-neutral_th)))
    pos_start = max(0.0, min(1.0, _norm(neutral_th)))

    # ------------------------------------------------------------------
    # Create a *gradient* colorscale. We use multiple shades of green for
    # negative values and shades of red for positive values while keeping a
    # neutral gray band around zero. This provides more visual nuance than
    # the previous flat colors.
    # ------------------------------------------------------------------
    # Build gradients using Plotly's sequential color palettes. Dark green
    # represents the most negative change and dark red represents the most
    # positive change. Values close to zero fall in a narrow gray band.
    # Use only the more saturated 75 % of each palette so the color appears
    # quickly without the very pale tints. (Skip the lightest ~25 %.)
    greens_full: list[str] = px.colors.sequential.Greens  # dark → light
    reds_full: list[str] = px.colors.sequential.Reds  # light → dark
    trim_g: int = max(1, len(greens_full) // 4)  # ≈25 %
    trim_r: int = max(1, len(reds_full) // 4)
    greens: list[str] = greens_full[trim_g:]  # drop lightest greens
    reds: list[str] = reds_full[trim_r:]  # drop lightest reds

    colorscale: list[list[float | str]] = []

    # Negative side (red).
    reds_neg: list[str] = reds[::-1]  # darkest red at most negative
    for idx, color in enumerate(reds_neg):
        n_frac: float = idx / (len(reds_neg) - 1) if len(reds_neg) > 1 else 0
        colorscale.append([neg_end * n_frac, color])

    # Neutral gray band (flat so repeat boundaries).
    colorscale.extend(
        [
            [neg_end, "lightgray"],
            [pos_start, "lightgray"],
        ]
    )

    # Positive side (green).
    for idx, color in enumerate(greens):
        p_frac: float = idx / (len(greens) - 1) if len(greens) > 1 else 0
        colorscale.append([pos_start + (1 - pos_start) * p_frac, color])

    # Ensure colorscale is sorted by the position value (first element).
    colorscale.sort(key=lambda item: item[0])

    # --------------------------------------------------------
    # Build figure - single plot or faceted layout.
    # --------------------------------------------------------
    if facet_column and facet_column in data.columns:
        facets = data[facet_column].unique(maintain_order=True)
        n_facets = len(facets)
        fig = make_subplots(
            rows=1,
            cols=n_facets,
            shared_yaxes="all",
            shared_xaxes="all",
            x_title="",
            horizontal_spacing=0.01,
            subplot_titles=[plot_utils.format_label(str(val)) for val in facets],
        )

        # Add one heatmap per facet.
        for i, facet_val in enumerate(facets):
            sub = data.filter(pl.col(facet_column) == facet_val)
            z_sub = sub[constituent_cols].to_numpy().T
            fig.add_trace(
                go.Heatmap(
                    z=z_sub,
                    x=sub[x_column].to_list(),
                    y=constituent_cols,  # type: ignore
                    colorscale=colorscale,  # type: ignore
                    zmin=z_min,
                    zmax=z_max,
                    coloraxis="coloraxis",
                    showscale=(i == n_facets - 1),  # show color bar only once
                ),
                row=1,
                col=i + 1,
            )
            # Tilt X tick labels for clarity
            fig.update_xaxes(tickangle=-90, row=1, col=i + 1)
        # Set global coloraxis
        fig.update_layout(
            coloraxis={
                "colorscale": colorscale,
                "cmin": z_min,
                "cmax": z_max,
                "colorbar": {"title": "Value", "tickvals": tickvals},
            }
        )
        # Word-wrap long facet titles for readability (match BarPlotter behavior).
        fig.for_each_annotation(
            lambda a: a.update(
                text="<br>".join(
                    textwrap.wrap(
                        a.text.strip() if a.text else "",
                        width=theme.DEFAULT_FACET_TITLE_WIDTH,
                        break_long_words=False,
                    )
                )
            )
        )
    else:
        fig = go.Figure(
            data=go.Heatmap(
                z=z_values,
                x=data[x_column].to_list(),
                y=constituent_cols,  # type: ignore
                colorscale=colorscale,  # type: ignore
                zmin=z_min,
                zmax=z_max,
                colorbar={"title": "Value", "tickvals": tickvals},
            )
        )

    if not facet_column:
        # Add vertical grid lines
        x_values = data[x_column].to_list()
        for i in range(1, len(x_values)):
            fig.add_shape(
                type="line",
                x0=i - 0.5,
                x1=i - 0.5,
                y0=-0.5,
                y1=len(constituent_cols) - 0.5,
                line={"color": "white", "width": 1},
                layer="above",
            )

        # Add horizontal grid lines
        for i in range(1, len(constituent_cols)):
            fig.add_shape(
                type="line",
                x0=-0.5,
                x1=len(x_values) - 0.5,
                y0=i - 0.5,
                y1=i - 0.5,
                line={"color": "white", "width": 1},
                layer="above",
            )

    # Set empty axis titles
    fig.update_xaxes(title_text="")
    fig.update_yaxes(title_text="", type="category", tickmode="array", tickvals=constituent_cols)
    theme.apply_layout(fig)
    fig.update_layout(height=900)
    return fig
