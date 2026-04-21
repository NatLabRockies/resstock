"""Histogram layout for the stacked plot family.

Computes shared bin geometry (including the synthetic overflow tail),
validates that grouped inputs share that geometry, and renders either a
single-panel or faceted-per-group histogram figure from pre-binned
``count_pct`` data.

Extracted from stacked_plotter.py in refactor plan V2 step 6.2.
"""

import plotly.graph_objects as go
import polars as pl
from plotly.subplots import make_subplots

from resstockpostproc.baseline_validation.plotters.graph_splitting import resolve_sorted_chars
from resstockpostproc.baseline_validation.schema.plot_spec import CoverageType, PlotSpec
from resstockpostproc.shared_utils.generic_plotters import theme as plot_theme
from resstockpostproc.shared_utils.generic_plotters.hover_formatting import format_compact_number


def _histogram_hover_template(count_label: str | None, count_value: int | None) -> str:
    """Build the histogram hover template, optionally appending a per-trace count row."""
    count_line = f"<br>{count_label}: {count_value:,}" if count_label and count_value is not None else ""
    return (
        "%{fullData.name}<br>"
        "Range: %{customdata[0]} to %{customdata[1]}<br>"
        f"Stock Share: %{{y:.2f}}%{count_line}<extra></extra>"
    )


def _compute_histogram_geometry(plot_df: pl.DataFrame) -> tuple[int, float, float, pl.DataFrame]:
    """Compute shared histogram bin geometry from a full (possibly grouped) DataFrame.

    Returns (overflow_bin, core_width, p98, plot_df_with_derived_cols).
    The returned DataFrame has ``_bin_center`` and ``_bar_width`` columns appended.
    """
    overflow_bin = int(plot_df["bin"].max())
    _assert_consistent_histogram_geometry(plot_df, overflow_bin)

    core_width = (
        plot_df.filter(pl.col("bin") != overflow_bin)
        .select((pl.col("bin_right") - pl.col("bin_left")).median().alias("w"))
        .item(0, 0)
    )
    if core_width is None or core_width <= 0:
        core_width = 1.0

    p98 = (
        plot_df.filter(pl.col("bin") == overflow_bin)
        .select(pl.col("bin_left").min().alias("p98"))
        .item(0, 0)
    )
    if p98 is None:
        p98 = (
            plot_df.filter(pl.col("bin") != overflow_bin)
            .select(pl.col("bin_right").max().alias("core_max"))
            .item(0, 0)
        )
    if p98 is None:
        p98 = 0.0
    p98 = float(p98)
    core_width = float(core_width)

    plot_df = plot_df.with_columns(
        pl.when(pl.col("bin") == overflow_bin)
        .then(pl.lit(p98 + core_width))
        .otherwise((pl.col("bin_left") + pl.col("bin_right")) / 2.0)
        .alias("_bin_center"),
        pl.when(pl.col("bin") == overflow_bin)
        .then(pl.lit(2.0 * core_width))
        .otherwise((pl.col("bin_right") - pl.col("bin_left")).clip(lower_bound=0.0))
        .alias("_bar_width"),
    )
    return overflow_bin, core_width, p98, plot_df


def _assert_consistent_histogram_geometry(plot_df: pl.DataFrame, overflow_bin: int) -> None:
    """Reject histogram data that cannot be drawn on a shared x-axis faithfully."""
    tolerance = 1e-9

    core_width_min, core_width_max = (
        plot_df.filter(pl.col("bin") != overflow_bin)
        .select(
            (pl.col("bin_right") - pl.col("bin_left")).min().alias("min_width"),
            (pl.col("bin_right") - pl.col("bin_left")).max().alias("max_width"),
        )
        .row(0)
    )
    if (
        core_width_min is not None
        and core_width_max is not None
        and float(core_width_max) - float(core_width_min) > tolerance
    ):
        raise ValueError(
            "Histogram input contains inconsistent core bin widths; "
            "grouped histograms must share one bin geometry."
        )

    overflow_left_min, overflow_left_max = (
        plot_df.filter(pl.col("bin") == overflow_bin)
        .select(
            pl.col("bin_left").min().alias("min_left"),
            pl.col("bin_left").max().alias("max_left"),
        )
        .row(0)
    )
    if (
        overflow_left_min is not None
        and overflow_left_max is not None
        and float(overflow_left_max) - float(overflow_left_min) > tolerance
    ):
        raise ValueError(
            "Histogram input contains inconsistent overflow bin placement; "
            "grouped histograms must share one bin geometry."
        )


def _create_grouped_histogram_plot(
    df: pl.DataFrame, plot_spec: PlotSpec, group_col: str
) -> go.Figure:
    """Create a faceted histogram with one subplot row per group_by category."""
    group_values = resolve_sorted_chars(df, group_col, plot_spec)
    n_groups = len(group_values)

    fig = make_subplots(
        rows=n_groups,
        cols=1,
        shared_xaxes=True,
        vertical_spacing=max(0.01, 0.04 / max(1, n_groups / 5)),
        subplot_titles=[str(v) for v in group_values],
    )

    plot_df = df.sort(["source", "bin"], maintain_order=True)
    _, core_width, p98, plot_df = _compute_histogram_geometry(plot_df)

    sources = plot_df["source"].unique(maintain_order=True).to_list()
    palette = plot_theme.build_color_palette(sources)
    x_max = max(1.0, p98 + 2.0 * core_width)
    x_title = "kWh/user" if plot_spec.coverage == CoverageType.users_only else "kWh/unit"

    for row_idx, group_val in enumerate(group_values, start=1):
        group_df = plot_df.filter(pl.col(group_col) == group_val)
        for source in sources:
            sub = group_df.filter(pl.col("source") == source)
            if sub.is_empty():
                continue
            count_label = plot_spec.model_count_display_label_for_source(source)
            count_value = (
                int(sub["sample_count"][0])
                if "sample_count" in sub.columns and sub["sample_count"][0] is not None
                else None
            )
            fig.add_bar(
                x=sub["_bin_center"].to_list(),
                y=sub["count_pct"].to_list(),
                width=sub["_bar_width"].to_list(),
                name=source,
                marker_color=palette.get(source),
                opacity=0.7,
                showlegend=(row_idx == 1),
                legendgroup=source,
                customdata=[
                    (format_compact_number(left), format_compact_number(right))
                    for left, right in zip(sub["bin_left"].to_list(), sub["bin_right"].to_list(), strict=True)
                ],
                hovertemplate=_histogram_hover_template(count_label, count_value),
                row=row_idx,
                col=1,
            )

        fig.update_xaxes(range=[0, x_max], row=row_idx, col=1)
        fig.update_yaxes(title_text="Stock Share", ticksuffix="%", row=row_idx, col=1)

    # x-axis title on bottom subplot only
    fig.update_xaxes(title_text=x_title, row=n_groups, col=1)

    fig.update_layout(
        barmode="overlay",
        bargap=0.0,
        bargroupgap=0.0,
        legend_title_text="Data Source",
    )
    return fig


def create_histogram_plot(df: pl.DataFrame, plot_spec: PlotSpec) -> go.Figure:
    """Create a histogram from explicit per-bin percentages.

    When group_by is set, produces a faceted figure with one subplot row per
    group category.  Otherwise renders a single-panel histogram.
    """
    if not plot_spec.is_distribution_metric:
        raise ValueError("Histogram layout is only supported for distribution metrics.")

    required = {"source", "bin", "bin_left", "bin_right", "count_pct"}
    missing = sorted(required - set(df.columns))
    if missing:
        raise ValueError(f"Histogram input missing required columns: {missing}")
    if df.is_empty():
        return go.Figure()

    group_col = plot_spec.group_by
    if group_col and group_col in df.columns and df[group_col].n_unique() > 1:
        return _create_grouped_histogram_plot(df, plot_spec, group_col)

    plot_df = df.sort(["source", "bin"], maintain_order=True)
    _, core_width, p98, plot_df = _compute_histogram_geometry(plot_df)

    sources = plot_df["source"].unique(maintain_order=True).to_list()
    palette = plot_theme.build_color_palette(sources)
    fig = go.Figure()
    for source in sources:
        sub = plot_df.filter(pl.col("source") == source)
        count_label = plot_spec.model_count_display_label_for_source(source)
        count_value = (
            int(sub["sample_count"][0])
            if "sample_count" in sub.columns and len(sub) and sub["sample_count"][0] is not None
            else None
        )
        fig.add_bar(
            x=sub["_bin_center"].to_list(),
            y=sub["count_pct"].to_list(),
            width=sub["_bar_width"].to_list(),
            name=source,
            marker_color=palette.get(source),
            opacity=0.7,
            customdata=[
                (format_compact_number(left), format_compact_number(right))
                for left, right in zip(sub["bin_left"].to_list(), sub["bin_right"].to_list(), strict=True)
            ],
            hovertemplate=_histogram_hover_template(count_label, count_value),
        )

    x_max = max(1.0, p98 + 2.0 * core_width)
    max_pct = plot_df["count_pct"].max()
    y_max = float(max_pct) if max_pct is not None else 0.0
    y_max = max(1.0, y_max * 1.1)

    x_title = "kWh/user" if plot_spec.coverage == CoverageType.users_only else "kWh/unit"
    fig.update_layout(
        barmode="overlay",
        bargap=0.0,
        bargroupgap=0.0,
        legend_title_text="Data Source",
    )
    fig.update_xaxes(title_text=x_title, range=[0, x_max])
    fig.update_yaxes(title_text="Stock Share", ticksuffix="%", range=[0, y_max])
    return fig
