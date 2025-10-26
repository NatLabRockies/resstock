import math
import textwrap

import plotly.graph_objects as go
import polars as pl
from plotly.subplots import make_subplots

__all__ = ["create_plot"]

from resstockpostproc.standard_plots.plotters import plot_utils
from resstockpostproc.standard_plots import theme
from resstockpostproc.standard_plots.schema.plot_spec import PlotSpec
from resstockpostproc.standard_plots.schema.workflow_schema import QuantityGroup


def create_plot(data: pl.DataFrame, plot_spec: PlotSpec) -> go.Figure:
    """Create and return a histogram figure based on *plot_spec*."""
    if isinstance(plot_spec.quantity, QuantityGroup):
        raise ValueError("Histogram plots require a single quantity, not a QuantityGroup.")

    facet_col: str | None = plot_spec.group_by if plot_spec.group_by else None
    assert isinstance(plot_spec.quantity, str)
    return _create_histogram_plot(
        data=data,
        name=plot_utils.get_quantity_title(plot_spec),
        facet_column=facet_col,
    )


def _create_histogram_plot(
    *,
    data: pl.DataFrame,
    name: str,
    facet_column: str | None = None,
) -> go.Figure:
    """
    Visualise an explicit frequency table with a bar chart.

    Parameters
    ----------
    data :
        Polars DataFrame produced by `prepare_data_for_histogram_plot` and
        therefore expected to contain at least
        ['bin', 'bin_left', 'bin_right', 'count', 'upgrade_name']
        plus an optional `facet_column`.
    name :
        Human-readable label for X-axis (will be run through `format_label`).
    facet_column :
        Optional column to facet by (creates additional columns of sub-plots).

    Returns
    -------
    go.Figure
    """
    # ------------------------------------------------------------------
    # 1. Derive helper columns (centre & bar-width)
    # ------------------------------------------------------------------
    core_w = (
        data.filter((pl.col("bin") >= 0) & (pl.col("bin") < 100))
        .select((pl.col("bin_right") - pl.col("bin_left")).alias("w"))
        .get_column("w")[0]  # <- one scalar, no shape error
    )

    # 1b.  Finite bounds of the 1%-to-99% range
    q1 = data.filter(pl.col("bin") == 0).select(pl.col("bin_left").alias("q1")).get_column("q1")[0]
    q99 = data.filter(pl.col("bin") == 99).select(pl.col("bin_right").alias("q99")).get_column("q99")[0]

    # 1c.  Finite bar centres
    df = data.with_columns(
        pl.when(pl.col("bin") == -1)
        .then(q1 - core_w)  # centre left-tail
        .when(pl.col("bin") == 100)
        .then(q99 + core_w)  # centre right-tail
        .otherwise((pl.col("bin_left") + pl.col("bin_right")) / 2.0)
        .alias("_bin_center"),
        pl.when(pl.col("bin").is_in([-1, 100]))
        .then(core_w * 2)  # wider tail bars
        .otherwise(core_w)
        .alias("_bar_width"),
    )

    # ------------------------------------------------------------------
    # 2. Prepare facet grid (rows = facets, columns = upgrades)
    # ------------------------------------------------------------------
    upgrades = df["upgrade_name"].unique(maintain_order=True).to_list()
    upgrade_palette = theme.build_upgrade_palette(upgrades)
    facet_values = df[facet_column].unique(maintain_order=True).to_list() if facet_column else [None]

    n_rows, n_cols = len(facet_values), len(upgrades)
    h_spacing = 0.1 * (1 / max(n_cols, 1))
    v_spacing = 0.1 * (1 / max(n_rows, 1))
    fig = make_subplots(
        rows=n_rows,
        cols=n_cols,
        shared_yaxes="all",
        shared_xaxes="all",
        row_titles=[str(f) for f in facet_values] if facet_column else None,
        column_titles=[str(u) for u in upgrades],
        horizontal_spacing=h_spacing,
        vertical_spacing=v_spacing,
    )

    # ------------------------------------------------------------------
    # 3. Add one Bar trace per upgrade *and* facet
    # ------------------------------------------------------------------
    for r, facet_val in enumerate(facet_values, start=1):
        for c, upgrade in enumerate(upgrades, start=1):
            mask = pl.col("upgrade_name") == upgrade
            if facet_column:
                mask &= pl.col(facet_column) == facet_val

            sub = df.filter(mask)
            if sub.is_empty():
                continue

            fig.add_bar(
                x=sub["_bin_center"].to_list(),
                y=sub["count_pct"].to_list(),
                width=sub["_bar_width"].to_list(),
                name=upgrade,
                marker_color=upgrade_palette.get(upgrade),
                showlegend=(r == 1),  # one legend entry per upgrade
                legendgroup=upgrade,
                customdata=list(zip(sub["bin_left"].to_list(), sub["bin_right"].to_list())),  # type: ignore[arg-type]
                hovertemplate="%{customdata[0]:.1f} to %{customdata[1]:.1f}<br>%{y:.1f}%<extra></extra>",
                row=r,
                col=c,
            )

            if n_rows == 1:
                subplot_index = (r - 1) * n_cols + c
                axis_suffix = "" if subplot_index == 1 else str(subplot_index)
                xref = f"x{axis_suffix}"
                yref = f"y{axis_suffix}"
                arrow_offset = 22
                tail_arrow_offset = 52
                shared_annot_kwargs = {
                    "xref": xref,
                    "yref": yref,
                    "showarrow": True,
                    "arrowhead": 2,
                    "arrowsize": 1,
                    "arrowwidth": 1,
                    "arrowcolor": "rgba(58,71,80,0.8)",
                    "ax": 0,
                    "bgcolor": "rgba(255,255,255,0.85)",
                    "bordercolor": "rgba(58,71,80,0.3)",
                    "borderwidth": 1,
                    "font": {"size": 12},
                }

                def _add_annotation_if_valid(*, text: str, x: float, y: float, **kwargs) -> None:
                    if not math.isfinite(x) or not math.isfinite(y):
                        return
                    arrow_len = kwargs.pop("ay", arrow_offset)
                    fig.add_annotation(
                        y=y,
                        text=text,
                        ay=arrow_len,
                        **shared_annot_kwargs,  # type: ignore[arg-type]  # Plotly typing excludes many valid kwargs
                        x=x,
                        **kwargs,
                    )

                def _format_range(left: float, right: float) -> str:
                    def _format_single(val: float) -> str:
                        text = f"{val:.1f}"
                        # Use non-breaking hyphen so Plotly doesn't wrap after the minus sign.
                        return text.replace("-", "&#8209;")

                    return f"{_format_single(left)}&nbsp;to&nbsp;{_format_single(right)}"

                def _tail_annotation_text(label: str, left: float, right: float) -> str:
                    return f"{label}<br>Bin<br>{_format_range(left, right)}"

                underflow = sub.filter(pl.col("bin") == -1)
                if not underflow.is_empty() and underflow["count"][0] > 0:
                    uf_left = float(underflow["bin_left"][0])
                    uf_right = float(underflow["bin_right"][0])
                    uf_text = _tail_annotation_text("Underflow", uf_left, uf_right)
                    _add_annotation_if_valid(
                        text=uf_text,
                        x=float(underflow["_bin_center"][0]),
                        y=0.0,
                        align="center",
                        xanchor="center",
                        ay=tail_arrow_offset,
                    )

                overflow = sub.filter(pl.col("bin") == 100)
                if not overflow.is_empty() and overflow["count"][0] > 0:
                    of_left = float(overflow["bin_left"][0])
                    of_right = float(overflow["bin_right"][0])
                    of_text = _tail_annotation_text("Overflow", of_left, of_right)
                    _add_annotation_if_valid(
                        text=of_text,
                        x=float(overflow["_bin_center"][0]),
                        y=0.0,
                        align="center",
                        xanchor="center",
                        ay=tail_arrow_offset,
                    )

                mean_value = float(sub["value_mean"][0]) if "value_mean" in sub.columns else float("nan")
                median_value = float(sub["value_median"][0]) if "value_median" in sub.columns else float("nan")
                if math.isfinite(mean_value) and math.isfinite(median_value):
                    if mean_value >= median_value:
                        mean_align = {"align": "left", "xanchor": "left", "xshift": 10}
                        median_align = {"align": "right", "xanchor": "right", "xshift": -10}
                    else:
                        mean_align = {"align": "right", "xanchor": "right", "xshift": -10}
                        median_align = {"align": "left", "xanchor": "left", "xshift": 10}

                    _add_annotation_if_valid(
                        text=f"Mean {mean_value:.1f}",
                        x=mean_value,
                        y=0.0,
                        **mean_align,
                    )
                    _add_annotation_if_valid(
                        text=f"Median {median_value:.1f}",
                        x=median_value,
                        y=0.0,
                        **median_align,
                    )
                else:
                    if math.isfinite(mean_value):
                        _add_annotation_if_valid(
                            text=f"Mean {mean_value:.1f}",
                            x=mean_value,
                            y=0.0,
                            align="left",
                            xanchor="left",
                            xshift=10,
                        )
                    if math.isfinite(median_value):
                        _add_annotation_if_valid(
                            text=f"Median {median_value:.1f}",
                            x=median_value,
                            y=0.0,
                            align="right",
                            xanchor="right",
                            xshift=-10,
                        )

    # ------------------------------------------------------------------
    # 4. Layout & styling
    # ------------------------------------------------------------------
    # No gaps between grouped bars
    x_min = q1 - 2 * core_w  # left-tail bar starts here
    x_max = q99 + 2 * core_w  # right-tail bar ends here
    max_val = df["count_pct"].max() or 0.0
    y_max = float(max_val) if isinstance(max_val, float | int) else 0.0
    y_max = y_max if y_max > 0 else 1.0

    fig.update_xaxes(range=[x_min, x_max])
    fig.update_yaxes(range=[0, y_max])

    # No gaps between grouped bars
    fig.update_layout(
        barmode="group",
        bargap=0,
        bargroupgap=0,
        template=theme.DEFAULT_TEMPLATE,
        legend_title_text="Upgrade",
    )
    # Apply theme before axis tweaks (so theme rules don't overwrite them)
    theme.apply_layout(fig)

    # ── 4 b.  Axis styling & titles ─────────────────────────────────────
    # grid on all y-axes
    fig.update_yaxes(gridcolor="lightgray", gridwidth=0.5)

    #  Same numeric ranges everywhere
    fig.update_xaxes(range=[x_min, x_max])
    fig.update_yaxes(range=[0, y_max])

    # Put Y-axis title and ticks only on the left column
    y_axis_title = "Percentage of models in bin" if n_rows == 1 else "%"
    for r in range(1, n_rows + 1):
        fig.update_yaxes(title_text=y_axis_title, ticksuffix="%", row=r, col=1)
        for c in range(2, n_cols + 1):
            fig.update_yaxes(title_text="", showticklabels=False, row=r, col=c)

    # Put X-axis title only on the bottom row
    for c in range(1, n_cols + 1):
        for r in range(1, n_rows + 1):
            fig.update_xaxes(title_text="", row=r, col=c)
    # ── 4c.  Facet annotation wrapping & overall width ─────────────────
    if facet_column:
        wrap = theme.DEFAULT_FACET_TITLE_WIDTH
        fig.for_each_annotation(
            lambda a: a.update(
                text="<br>".join(
                    textwrap.wrap(
                        a.text.split("=")[-1].strip() if a.text is not None else "",
                        width=wrap,
                        break_long_words=False,
                    )
                )
            )
        )
    x_title_y = -0.14 if n_rows == 1 else -0.07
    fig.add_annotation(
        text=name,
        xref="paper",
        yref="paper",
        x=0.5,
        y=x_title_y,  # center at bottom
        xanchor="center",
        yanchor="top",
        showarrow=False,
        font={"size": 14},
        name="xtitle",
    )
    #  Adjust figure width
    bottom_margin = 165 if n_rows == 1 else 100
    fig.update_layout(width=max(1000, min(1920, n_cols * theme.DEFAULT_FACET_WIDTH)), margin={"b": bottom_margin})
    return fig
