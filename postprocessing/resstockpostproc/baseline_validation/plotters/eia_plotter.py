import calendar
from typing import Any

import polars as pl
import plotly.graph_objects as go
from plotly.subplots import make_subplots

from resstockpostproc.baseline_validation.theme import (
    apply_theme,
    BUILDSTOCK_COLOR,
)
from resstockpostproc.shared_utils.colors import QUALITATIVE_SERIES

# ---------------------------------------------------------------------------
# constants
# ---------------------------------------------------------------------------
EIA_COLOR = QUALITATIVE_SERIES[0]
_RUN_PALETTE = QUALITATIVE_SERIES[1:] or QUALITATIVE_SERIES

MONTH_ROWS = 5
MONTH_COLS = 11
MONTH_MAX = MONTH_ROWS * MONTH_COLS

MONTH_NAME_TO_INDEX = {
    name.lower(): idx for idx, name in enumerate(calendar.month_name) if name
}
MONTH_NAME_TO_INDEX.update(
    {abbr.lower(): idx for idx, abbr in enumerate(calendar.month_abbr) if abbr}
)
MONTH_INDEX_TO_LABEL = {idx: calendar.month_abbr[idx] for idx in range(1, 13)}


# ---------------------------------------------------------------------------
# shared utilities
# ---------------------------------------------------------------------------
def _run_names(df: pl.DataFrame) -> list[str]:
    """Find run prefixes like 'baseline', 'upgrade1' from *_electricity_kwh / *_natural_gas_kwh columns."""
    names: list[str] = []
    for col in df.columns:
        if col.endswith("_electricity_kwh"):
            name = col.removesuffix("_electricity_kwh")
        elif col.endswith("_natural_gas_kwh"):
            name = col.removesuffix("_natural_gas_kwh")
        else:
            continue
        if name not in names:
            names.append(name)
    return names


def _run_colors(names: list[str]) -> dict[str, str]:
    return {name: _RUN_PALETTE[i % len(_RUN_PALETTE)] for i, name in enumerate(names)}


def _require_columns(df: pl.DataFrame, cols: set[str], label: str) -> None:
    missing = cols - set(df.columns)
    if missing:
        raise ValueError(f"{label} missing columns: {', '.join(sorted(missing))}")


def _prepare_annual(
    buildstock_annual: pl.DataFrame,
    eia_annual: pl.DataFrame,
    by: str,
) -> tuple[pl.DataFrame, list[str], dict[str, str]]:
    # check basic columns
    _require_columns(eia_annual, {by, "eia_electricity_kwh", "eia_natural_gas_kwh"}, "EIA annual")
    _require_columns(buildstock_annual, {by}, "BuildStock annual")

    runs = _run_names(buildstock_annual)
    if not runs:
        raise ValueError("No run columns (*_electricity_kwh / *_natural_gas_kwh) found in BuildStock annual")

    # keep only useful columns
    keep = [pl.col(by)]
    for r in runs:
        for fuel in ("electricity", "natural_gas"):
            col = f"{r}_{fuel}_kwh"
            if col in buildstock_annual.columns:
                keep.append(pl.col(col))

    bs = buildstock_annual.select(keep)
    eia = eia_annual.select(by, "eia_electricity_kwh", "eia_natural_gas_kwh")
    df = eia.join(bs, on=by, how="inner")
    if df.is_empty():
        raise ValueError(f"No overlap on '{by}' between EIA and BuildStock annual")

    return df, runs, _run_colors(runs)


def _month_to_index(val: Any) -> int:
    if isinstance(val, int) and 1 <= val <= 12:
        return val
    if isinstance(val, str):
        key = val.strip().lower()
        if key.isdigit():
            num = int(key)
            if 1 <= num <= 12:
                return num
        if key in MONTH_NAME_TO_INDEX:
            return MONTH_NAME_TO_INDEX[key]
    raise ValueError(f"Bad month value: {val!r}")


def _prepare_monthly(
    buildstock_monthly: pl.DataFrame,
    eia_monthly: pl.DataFrame,
    by: str,
) -> tuple[pl.DataFrame, list[str], dict[str, str]]:
    needed = {by, "month"}
    _require_columns(buildstock_monthly, needed, "BuildStock monthly")
    _require_columns(eia_monthly, needed | {"eia_electricity_kwh", "eia_natural_gas_kwh"}, "EIA monthly")

    runs = _run_names(buildstock_monthly)
    if not runs:
        raise ValueError("No run columns in monthly BuildStock dataframe")

    # select run columns that actually exist
    bs_cols = [pl.col(by), pl.col("month")]
    for r in runs:
        for fuel in ("electricity", "natural_gas"):
            col = f"{r}_{fuel}_kwh"
            if col in buildstock_monthly.columns:
                bs_cols.append(pl.col(col))

    bs = buildstock_monthly.select(bs_cols)
    eia = eia_monthly.select(by, "month", "eia_electricity_kwh", "eia_natural_gas_kwh")
    df = eia.join(bs, on=[by, "month"], how="inner").drop_nulls(["month"])
    if df.is_empty():
        raise ValueError(f"No monthly overlap for '{by}'")

    df = df.with_columns(
        pl.col("month").map_elements(_month_to_index, return_dtype=pl.Int16).alias("_month_order"),
        pl.col("month").map_elements(lambda m: MONTH_INDEX_TO_LABEL[_month_to_index(m)], return_dtype=pl.Utf8).alias(
            "_month_label"
        ),
    )
    return df, runs, _run_colors(runs)


# ---------------------------------------------------------------------------
# annual plot helpers
# ---------------------------------------------------------------------------
def _add_annual_consumption_panel(
    fig: go.Figure,
    df: pl.DataFrame,
    entities: list[str],
    runs: list[str],
    colors: dict[str, str],
    fuel: str,
    row: int,
    col: int,
    showlegend: bool,
) -> None:
    eia_col = f"eia_{fuel}_kwh"
    if eia_col not in df.columns:
        return
    # runs
    for i, r in enumerate(reversed(runs)):
        colname = f"{r}_{fuel}_kwh"
        if colname not in df.columns:
            continue
        fig.add_bar(
            x=df[colname].to_list(),
            y=entities,
            orientation="h",
            name=r,
            legendgroup=r,
            legendrank=100 - i,
            marker=dict(color=colors[r]),
            hovertemplate="%{y}<br>" + f"{r}: " + "%{x:,.0f} kWh<extra></extra>",
            showlegend=showlegend,
            row=row,
            col=col,
        )
    fig.add_bar(
        x=df[eia_col].to_list(),
        y=entities,
        orientation="h",
        name="EIA",
        legendgroup="EIA",
        legendrank=0,
        marker=dict(color=EIA_COLOR),
        hovertemplate="%{y}<br>EIA: %{x:,.0f} kWh<extra></extra>",
        showlegend=showlegend,
        row=row,
        col=col,
    )


def _add_annual_percent_panel(
    fig: go.Figure,
    df: pl.DataFrame,
    entities: list[str],
    runs: list[str],
    colors: dict[str, str],
    fuel: str,
    row: int,
    col: int,
    showlegend: bool,
) -> tuple[float | None, float | None]:
    eia_col = f"eia_{fuel}_kwh"
    if eia_col not in df.columns:
        return None, None

    min_v, max_v = None, None
    for i, r in enumerate(reversed(runs)):
        run_col = f"{r}_{fuel}_kwh"
        if run_col not in df.columns:
            continue

        pct = df.select(
            pl.when(pl.col(eia_col) == 0)
            .then(None)
            .otherwise((pl.col(run_col) - pl.col(eia_col)) / pl.col(eia_col) * 100)
            .alias("pct")
        )["pct"].to_list()

        fig.add_bar(
            x=pct,
            y=entities,
            orientation="h",
            name=r,
            legendgroup=r,
            legendrank=100 - i,
            marker=dict(color=colors[r]),
            hovertemplate="%{y}<br>" + f"{r}: " + "%{x:,.1f}%<extra></extra>",
            showlegend=showlegend,
            row=row,
            col=col,
        )

        clean = [v for v in pct if isinstance(v, (int, float))]
        if clean:
            rmin, rmax = min(clean), max(clean)
            min_v = rmin if min_v is None else min(min_v, rmin)
            max_v = rmax if max_v is None else max(max_v, rmax)

    return min_v, max_v


def _percent_axis_range(min_v: float | None, max_v: float | None) -> list[float] | None:
    vals = [v for v in (min_v, max_v) if isinstance(v, (int, float))]
    if not vals:
        return None

    lo = min_v if isinstance(min_v, (int, float)) else min(vals)
    hi = max_v if isinstance(max_v, (int, float)) else max(vals)

    if lo >= 0:
        pad = max(hi * 0.1, 1)
        return [0, hi + pad]
    if hi <= 0:
        pad = max(abs(lo) * 0.1, 1)
        return [lo - pad, 0]

    span = max(abs(lo), abs(hi))
    pad = max(span * 0.1, 1)
    return [-span - pad, span + pad]


def _finalize_annual(
    fig: go.Figure,
    left_title: str,
    right_title: str,
    title: str,
    left_range: list[float] | None = None,
    right_range: list[float] | None = None,
) -> go.Figure:
    fig.update_layout(
        barmode="group",
    )
    fig.update_xaxes(title_text=left_title, row=1, col=1)
    if left_range:
        fig.update_xaxes(range=left_range, row=1, col=1)

    fig.update_xaxes(title_text=right_title, row=1, col=2)
    if right_range:
        fig.update_xaxes(range=right_range, row=1, col=2)

    return apply_theme(fig, title=title, height=800, width=600)


# ---------------------------------------------------------------------------
# monthly plot helper
# ---------------------------------------------------------------------------
def _plot_monthly_generic(
    buildstock_monthly: pl.DataFrame,
    eia_monthly: pl.DataFrame,
    by: str,
    fuel: str,
    use_shared_axis: bool,
    title_prefix: str,
) -> go.Figure:
    df, runs, colors = _prepare_monthly(buildstock_monthly, eia_monthly, by)

    # order entities by total EIA for this fuel
    eia_fuel_col = f"eia_{fuel}_kwh"
    order_df = (
        df.group_by(by)
        .agg(pl.col(eia_fuel_col).sum().alias("_total"))
        .sort("_total", descending=False)
    )
    entities = order_df[by].to_list()

    # compute per-entity max for axis
    run_cols = [f"{r}_{fuel}_kwh" for r in runs if f"{r}_{fuel}_kwh" in df.columns]
    df = df.with_columns(
        pl.max_horizontal(pl.col(run_cols + [eia_fuel_col])).alias("_entity_max")
    )
    global_max = df["_entity_max"].max()
    shared_range = [0, global_max * 1.05] if isinstance(global_max, (int, float)) else None

    # make grid
    subplot_titles = [entities[i] if i < len(entities) else "" for i in range(MONTH_MAX)]
    fig = make_subplots(
        rows=MONTH_ROWS,
        cols=MONTH_COLS,
        subplot_titles=subplot_titles,
        horizontal_spacing=0.015,
        vertical_spacing=0.03,
    )

    axis_names = []
    individual_ranges: dict[str, list[float] | None] = {}

    visible_entities = entities[:MONTH_MAX]
    for idx, entity in enumerate(visible_entities, start=1):
        row = (idx - 1) // MONTH_COLS + 1
        col = (idx - 1) % MONTH_COLS + 1
        axis_name = "xaxis" if idx == 1 else f"xaxis{idx}"
        axis_names.append(axis_name)

        entity_df = df.filter(pl.col(by) == entity).sort("_month_order")
        months = entity_df["_month_label"].to_list()

        # runs
        for i, r in enumerate(runs):
            colname = f"{r}_{fuel}_kwh"
            if colname not in entity_df.columns:
                continue
            fig.add_bar(
                x=entity_df[colname].to_list(),
                y=months,
                orientation="h",
                name=r,
                legendgroup=r,
                legendrank=i + 1,
                marker=dict(color=colors[r]),
                hovertemplate="%{y}<br>" + f"{r}: " + "%{x:,.0f} kWh<extra></extra>",
                showlegend=(idx == 1),
                row=row,
                col=col,
            )

        # eia
        fig.add_bar(
            x=entity_df[eia_fuel_col].to_list(),
            y=months,
            orientation="h",
            name="EIA",
            legendgroup="EIA",
            legendrank=0,
            marker=dict(color=EIA_COLOR),
            hovertemplate="%{y}<br>EIA: %{x:,.0f} kWh<extra></extra>",
            showlegend=(idx == 1),
            row=row,
            col=col,
        )

        # y-axis per panel
        fig.update_yaxes(
            categoryorder="array",
            categoryarray=months,
            autorange="reversed",
            tickfont=dict(size=8),
            automargin=True,
            row=row,
            col=col,
        )

        entity_max = entity_df["_entity_max"].max()
        per_range = [0, entity_max * 1.05] if isinstance(entity_max, (int, float)) else None
        individual_ranges[axis_name] = per_range

        fig.update_xaxes(
            tickfont=dict(size=8),
            automargin=True,
            showticklabels=True,
            title_text=f"{title_prefix} (kWh)" if row == MONTH_ROWS else "",
            row=row,
            col=col,
            range=(shared_range if (use_shared_axis and shared_range) else per_range),
        )

    # fill empty panels
    for idx in range(len(visible_entities) + 1, MONTH_MAX + 1):
        row = (idx - 1) // MONTH_COLS + 1
        col = (idx - 1) % MONTH_COLS + 1
        axis_name = "xaxis" if idx == 1 else f"xaxis{idx}"
        axis_names.append(axis_name)
        individual_ranges[axis_name] = None
        fig.update_xaxes(visible=False, row=row, col=col)
        fig.update_yaxes(visible=False, row=row, col=col)

    # layout + toggle
    fig.update_layout(
        barmode="group",
        showlegend=True,
    )
    fig = apply_theme(
        fig,
        title=f"Monthly {title_prefix} by {by.title()}",
        height=1100,
        width=1950,
        legend=dict(orientation="v", x=0.02, y=0.02, xanchor="left", yanchor="bottom"),
        margin=dict(l=45, r=20, t=60, b=55),
    )

    # toggle shared vs auto
    if axis_names:
        shared_updates = {}
        for name in axis_names:
            if shared_range:
                shared_updates[f"{name}.range"] = shared_range
                shared_updates[f"{name}.autorange"] = False
            else:
                shared_updates[f"{name}.range"] = None
                shared_updates[f"{name}.autorange"] = True

        auto_updates = {}
        for name in axis_names:
            rng = individual_ranges.get(name)
            if rng:
                auto_updates[f"{name}.range"] = rng
                auto_updates[f"{name}.autorange"] = False
            else:
                auto_updates[f"{name}.range"] = None
                auto_updates[f"{name}.autorange"] = True

        fig.update_layout(
            updatemenus=[
                dict(
                    type="buttons",
                    direction="left",
                    showactive=True,
                    active=0 if use_shared_axis else 1,
                    buttons=[
                        dict(label="Shared Axis", method="relayout", args=[shared_updates]),
                        dict(label="Auto Axis", method="relayout", args=[auto_updates]),
                    ],
                    x=0.5,
                    xanchor="center",
                    y=1.06,
                    yanchor="bottom",
                    pad=dict(t=0, r=10),
                )
            ]
        )

    return fig


# ---------------------------------------------------------------------------
# public API (unchanged signatures)
# ---------------------------------------------------------------------------
def plot_state_comparison_scatter(
    buildstock_df: pl.DataFrame,
    eia_df: pl.DataFrame,
    value_col: str,
    title: str | None = None,
) -> go.Figure:
    comparison = buildstock_df.join(eia_df.select(["state", value_col]), on="state", suffix="_eia")
    bs_col = value_col
    eia_col = f"{value_col}_eia"

    fig = go.Figure()
    fig.add_scatter(
        x=comparison[eia_col].to_list(),
        y=comparison[bs_col].to_list(),
        mode="markers+text",
        marker=dict(size=10, color=BUILDSTOCK_COLOR, line=dict(width=1, color="white")),
        text=comparison["state"].to_list(),
        textposition="top center",
        textfont=dict(size=8),
        name="States",
    )

    max_val = max(comparison[eia_col].max() or 0, comparison[bs_col].max() or 0)
    min_val = min(comparison[eia_col].min() or 0, comparison[bs_col].min() or 0)

    fig.add_scatter(
        x=[min_val, max_val],
        y=[min_val, max_val],
        mode="lines",
        line=dict(color="gray", width=2, dash="dash"),
        name="1:1 Line",
        showlegend=True,
    )

    return apply_theme(
        fig,
        title=title or f"BuildStock vs EIA: {value_col}",
        xaxis_title=f"EIA {value_col}",
        yaxis_title=f"BuildStock {value_col}",
    )


def plot_annual_sales_comparison(
    buildstock_annual: pl.DataFrame,
    eia_annual: pl.DataFrame,
    by: str = "state",
) -> go.Figure:
    df, runs, colors = _prepare_annual(buildstock_annual, eia_annual, by)
    df = df.sort("eia_electricity_kwh", descending=False)
    entities = df[by].to_list()

    fig = make_subplots(
        rows=1,
        cols=2,
        subplot_titles=["Electricity Sales", "Natural Gas Sales"],
        shared_yaxes=True,
        horizontal_spacing=0.12,
    )

    _add_annual_consumption_panel(fig, df, entities, runs, colors, "electricity", 1, 1, True)
    _add_annual_consumption_panel(fig, df, entities, runs, colors, "natural_gas", 1, 2, False)

    return _finalize_annual(
        fig,
        "Electricity Sales (kWh)",
        "Natural Gas Sales (kWh)",
        f"Annual Sales Comparison by {by.title()}",
    )


def plot_annual_sales_comparison_electricity(
    buildstock_annual: pl.DataFrame,
    eia_annual: pl.DataFrame,
    by: str = "state",
) -> go.Figure:
    df, runs, colors = _prepare_annual(buildstock_annual, eia_annual, by)
    df = df.sort("eia_electricity_kwh", descending=False)
    entities = df[by].to_list()

    fig = make_subplots(
        rows=1,
        cols=2,
        subplot_titles=["Electricity Sales", "Electricity: % Difference vs EIA"],
        shared_yaxes=True,
        horizontal_spacing=0.12,
    )

    _add_annual_consumption_panel(fig, df, entities, runs, colors, "electricity", 1, 1, True)
    pct_min, pct_max = _add_annual_percent_panel(fig, df, entities, runs, colors, "electricity", 1, 2, False)

    return _finalize_annual(
        fig,
        "Electricity Sales (kWh)",
        "% Difference vs EIA",
        f"Annual Electricity Sales vs EIA by {by.title()}",
        right_range=_percent_axis_range(pct_min, pct_max),
    )


def plot_annual_sales_comparison_natural_gas(
    buildstock_annual: pl.DataFrame,
    eia_annual: pl.DataFrame,
    by: str = "state",
) -> go.Figure:
    df, runs, colors = _prepare_annual(buildstock_annual, eia_annual, by)
    df = df.sort("eia_natural_gas_kwh", descending=False)
    entities = df[by].to_list()

    fig = make_subplots(
        rows=1,
        cols=2,
        subplot_titles=["Natural Gas Sales", "Natural Gas: % Difference vs EIA"],
        shared_yaxes=True,
        horizontal_spacing=0.12,
    )

    _add_annual_consumption_panel(fig, df, entities, runs, colors, "natural_gas", 1, 1, True)
    pct_min, pct_max = _add_annual_percent_panel(fig, df, entities, runs, colors, "natural_gas", 1, 2, False)

    return _finalize_annual(
        fig,
        "Natural Gas Sales (kWh)",
        "% Difference vs EIA",
        f"Annual Natural Gas Sales vs EIA by {by.title()}",
        right_range=_percent_axis_range(pct_min, pct_max),
    )


def plot_annual_sales_comparison_percent_diff(
    buildstock_annual: pl.DataFrame,
    eia_annual: pl.DataFrame,
    by: str = "state",
) -> go.Figure:
    df, runs, colors = _prepare_annual(buildstock_annual, eia_annual, by)

    # sort by first run electricity pct diff if possible
    first_run = next((r for r in runs if f"{r}_electricity_kwh" in df.columns), None)
    if first_run:
        df = df.with_columns(
            pl.when(pl.col("eia_electricity_kwh") == 0)
            .then(None)
            .otherwise(
                (pl.col(f"{first_run}_electricity_kwh") - pl.col("eia_electricity_kwh"))
                / pl.col("eia_electricity_kwh")
                * 100
            )
            .alias("_sort")
        ).sort("_sort", descending=False)
    entities = df[by].to_list()

    fig = make_subplots(
        rows=1,
        cols=2,
        subplot_titles=["Electricity", "Natural Gas"],
        shared_yaxes=True,
        horizontal_spacing=0.12,
    )

    e_min, e_max = _add_annual_percent_panel(fig, df, entities, runs, colors, "electricity", 1, 1, True)
    g_min, g_max = _add_annual_percent_panel(fig, df, entities, runs, colors, "natural_gas", 1, 2, False)

    return _finalize_annual(
        fig,
        "% Difference vs EIA",
        "% Difference vs EIA",
        f"Annual % Difference vs EIA by {by.title()}",
        left_range=_percent_axis_range(e_min, e_max),
        right_range=_percent_axis_range(g_min, g_max),
    )


def plot_monthly_sales_comparison_electricity(
    buildstock_monthly: pl.DataFrame,
    eia_monthly: pl.DataFrame,
    by: str = "state",
    use_shared_axis: bool = True,
) -> go.Figure:
    return _plot_monthly_generic(
        buildstock_monthly,
        eia_monthly,
        by=by,
        fuel="electricity",
        use_shared_axis=use_shared_axis,
        title_prefix="Electricity Sales",
    )


def plot_monthly_sales_comparison_natural_gas(
    buildstock_monthly: pl.DataFrame,
    eia_monthly: pl.DataFrame,
    by: str = "state",
    use_shared_axis: bool = True,
) -> go.Figure:
    return _plot_monthly_generic(
        buildstock_monthly,
        eia_monthly,
        by=by,
        fuel="natural_gas",
        use_shared_axis=use_shared_axis,
        title_prefix="Natural Gas Sales",
    )
