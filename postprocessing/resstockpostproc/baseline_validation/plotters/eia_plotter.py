import calendar
from typing import Any

import polars as pl
import plotly.graph_objects as go
from plotly.subplots import make_subplots

from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    AggregationType,
)
from resstockpostproc.baseline_validation.theme import apply_theme
from resstockpostproc.shared_utils.colors import QUALITATIVE_SERIES, REF_QUALITATIVE_SERIES
from resstockpostproc.baseline_validation.plotters import base_plotter

# ---------------------------------------------------------------------------
# constants
# ---------------------------------------------------------------------------
EIA_COLORS = REF_QUALITATIVE_SERIES
_RUN_PALETTE = QUALITATIVE_SERIES
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
    # Find all EIA columns (with year suffixes)
    eia_cols = [col for col in eia_annual.columns if col.startswith("eia_") and col != by]
    if not eia_cols:
        raise ValueError("No EIA columns found in annual data")
    _require_columns(eia_annual, {by} | set(eia_cols), "EIA annual")
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
    # Select by column and all EIA columns
    eia = eia_annual.select([by] + eia_cols)
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
    # Find all EIA columns (with year suffixes)
    eia_cols = [col for col in eia_monthly.columns if col.startswith("eia_") and col not in {by, "month"}]
    if not eia_cols:
        raise ValueError("No EIA columns found in monthly data")
    _require_columns(eia_monthly, needed | set(eia_cols), "EIA monthly")

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
    # Select by, month, and all EIA columns
    eia = eia_monthly.select([by, "month"] + eia_cols)
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


def _split_annual_data(
    merged: pl.DataFrame,
    by: str,
) -> tuple[pl.DataFrame, pl.DataFrame]:
    if by not in merged.columns:
        raise ValueError(f"Input data missing grouping column '{by}' for EIA plotting")

    include_cols = [by]
    seen = {by}
    rename_map: dict[str, str] = {}

    for col in merged.columns:
        if col in seen or col.startswith("eia_") or col == "month":
            continue

        new_name: str | None = None
        if col.endswith("_restock_electricity"):
            run = col[: -len("_restock_electricity")]
            new_name = f"{run}_electricity_kwh"
        elif col.endswith("_restock_natural_gas"):
            run = col[: -len("_restock_natural_gas")]
            new_name = f"{run}_natural_gas_kwh"
        elif col.endswith(("_electricity_kwh", "_natural_gas_kwh")):
            new_name = col

        if new_name:
            include_cols.append(col)
            seen.add(col)
            if new_name != col:
                rename_map[col] = new_name

    if len(include_cols) == 1:
        raise ValueError("No BuildStock energy columns found in merged dataset for EIA plotting")

    buildstock = merged.select(include_cols).rename(rename_map)

    # Collect all EIA columns (including year suffixes like eia_electricity_kwh_2018)
    eia_cols = [by]
    for col in merged.columns:
        if col.startswith("eia_") and ("electricity" in col or "natural_gas" in col) and col != by:
            eia_cols.append(col)
    
    if len(eia_cols) == 1:  # Only 'by' column found
        raise ValueError("No EIA energy columns found in merged dataset")
    
    eia_df = merged.select(eia_cols)

    return buildstock, eia_df


def _split_monthly_data(
    merged: pl.DataFrame,
    by: str,
) -> tuple[pl.DataFrame, pl.DataFrame]:
    required = {by, "month"}
    missing = required - set(merged.columns)
    if missing:
        raise ValueError(f"Input data missing required columns for monthly plotting: {', '.join(sorted(missing))}")

    include_cols = [by, "month"]
    seen = set(include_cols)
    rename_map: dict[str, str] = {}

    for col in merged.columns:
        if col in seen or col.startswith("eia_"):
            continue

        new_name: str | None = None
        if col.endswith("_restock_electricity"):
            run = col[: -len("_restock_electricity")]
            new_name = f"{run}_electricity_kwh"
        elif col.endswith("_restock_natural_gas"):
            run = col[: -len("_restock_natural_gas")]
            new_name = f"{run}_natural_gas_kwh"
        elif col.endswith(("_electricity_kwh", "_natural_gas_kwh")):
            new_name = col

        if new_name:
            include_cols.append(col)
            seen.add(col)
            if new_name != col:
                rename_map[col] = new_name

    if len(include_cols) == 2:
        raise ValueError("No BuildStock monthly energy columns found for EIA plotting")

    buildstock = merged.select(include_cols).rename(rename_map)

    # Collect all EIA columns (including year suffixes like eia_electricity_kwh_2018)
    eia_cols = [by, "month"]
    for col in merged.columns:
        if col.startswith("eia_") and ("electricity" in col or "natural_gas" in col) and col not in {by, "month"}:
            eia_cols.append(col)
    
    if len(eia_cols) == 2:  # Only 'by' and 'month' columns found
        raise ValueError("No EIA energy columns found in merged dataset")
    
    eia_df = merged.select(eia_cols)

    return buildstock, eia_df


# ---------------------------------------------------------------------------
# annual plot helpers
# ---------------------------------------------------------------------------
def _get_eia_cols_and_labels(df: pl.DataFrame, fuel: str) -> tuple[list[str], list[str], list[str]]:
    cols = [col for col in df.columns if col.startswith(f"eia_{fuel}_kwh")]
    labels = []
    colors = []
    for i, col in enumerate(cols):
        parts = col.split("_")
        year_suffix = f" {parts[-1]}" if parts[-1].isdigit() else ""
        labels.append(f"EIA{year_suffix}")
        colors.append(EIA_COLORS[i % len(EIA_COLORS)])
    return cols, labels, colors


def plot_annual_sales_comparison(
    buildstock_annual: pl.DataFrame,
    eia_annual: pl.DataFrame,
    by: str = "state",
) -> go.Figure:
    df, runs, colors = _prepare_annual(buildstock_annual, eia_annual, by)
    # Find first EIA electricity column for sorting
    eia_elec_cols = [col for col in df.columns if col.startswith("eia_electricity_kwh")]
    if eia_elec_cols:
        df = df.sort(eia_elec_cols[0], descending=False)
    entities = df[by].to_list()

    fig = make_subplots(
        rows=1,
        cols=2,
        subplot_titles=["Electricity Sales", "Natural Gas Sales"],
        shared_yaxes=True,
        horizontal_spacing=0.12,
    )

    # Electricity panel
    eia_cols, eia_labels, eia_colors = _get_eia_cols_and_labels(df, "electricity")
    bs_cols = [f"{r}_electricity_kwh" for r in runs]
    bs_labels = runs
    bs_colors = [colors[r] for r in runs]
    
    # Combine all columns, labels, and colors (EIA first, then BuildStock)
    all_cols = eia_cols + bs_cols
    all_labels = eia_labels + bs_labels
    all_colors = eia_colors + bs_colors
    
    base_plotter._add_bar_plot(
        fig, df, by, all_cols, all_labels, all_colors, 1, 1, True, "kWh"
    )

    # Natural Gas panel
    eia_cols, eia_labels, eia_colors = _get_eia_cols_and_labels(df, "natural_gas")
    bs_cols = [f"{r}_natural_gas_kwh" for r in runs]
    bs_labels = runs
    bs_colors = [colors[r] for r in runs]
    
    all_cols = eia_cols + bs_cols
    all_labels = eia_labels + bs_labels
    all_colors = eia_colors + bs_colors

    base_plotter._add_bar_plot(
        fig, df, by, all_cols, all_labels, all_colors, 1, 2, False, "kWh"
    )

    return base_plotter.finalize_annual_plot(
        fig,
        "Electricity Sales (kWh)",
        "Natural Gas Sales (kWh)",
        f"Annual Sales Comparison by {by.title()}",
        categories=entities,
    )


def plot_annual_sales_comparison_electricity(
    buildstock_annual: pl.DataFrame,
    eia_annual: pl.DataFrame,
    by: str = "state",
) -> go.Figure:
    df, runs, colors = _prepare_annual(buildstock_annual, eia_annual, by)
    # Find first EIA electricity column for sorting
    eia_elec_cols = [col for col in df.columns if col.startswith("eia_electricity_kwh")]
    if eia_elec_cols:
        df = df.sort(eia_elec_cols[0], descending=False)
    entities = df[by].to_list()

    fig = make_subplots(
        rows=1,
        cols=2,
        subplot_titles=["Electricity Sales", "Electricity: % Difference vs EIA"],
        shared_yaxes=True,
        horizontal_spacing=0.12,
    )

    # Left panel: Electricity sales
    eia_cols, eia_labels, eia_colors = _get_eia_cols_and_labels(df, "electricity")
    bs_cols = [f"{r}_electricity_kwh" for r in runs]
    bs_labels = runs
    bs_colors = [colors[r] for r in runs]
    
    all_cols = eia_cols + bs_cols
    all_labels = eia_labels + bs_labels
    all_colors = eia_colors + bs_colors

    base_plotter._add_bar_plot(
        fig, df, by, all_cols, all_labels, all_colors, 1, 1, True, "kWh"
    )
    
    # Right panel: Percent difference
    pct_min, pct_max = None, None
    if eia_cols:
        eia_col = eia_cols[0]
        pct_cols = []
        for col in bs_cols:
            pct_col = f"{col}_pct"
            df = df.with_columns(
                pl.when(pl.col(eia_col) == 0)
                .then(None)
                .otherwise((pl.col(col) - pl.col(eia_col)) / pl.col(eia_col) * 100)
                .alias(pct_col)
            )
            pct_cols.append(pct_col)
        
        base_plotter._add_bar_plot(
            fig, df, by, pct_cols, bs_labels, bs_colors, 1, 2, False, "%"
        )
        
        # Calculate min/max for axis range
        for pct_col in pct_cols:
            clean = [v for v in df[pct_col].to_list() if isinstance(v, (int, float))]
            if clean:
                rmin, rmax = min(clean), max(clean)
                pct_min = rmin if pct_min is None else min(pct_min, rmin)
                pct_max = rmax if pct_max is None else max(pct_max, rmax)

    return base_plotter.finalize_annual_plot(
        fig,
        "Electricity Sales (kWh)",
        "% Difference vs EIA",
        f"Annual Electricity Sales vs EIA by {by.title()}",
        right_range=base_plotter.percent_axis_range(pct_min, pct_max),
        categories=entities,
    )


def plot_annual_sales_comparison_natural_gas(
    buildstock_annual: pl.DataFrame,
    eia_annual: pl.DataFrame,
    by: str = "state",
) -> go.Figure:
    df, runs, colors = _prepare_annual(buildstock_annual, eia_annual, by)
    # Find first EIA natural gas column for sorting
    eia_gas_cols = [col for col in df.columns if col.startswith("eia_natural_gas_kwh")]
    if eia_gas_cols:
        df = df.sort(eia_gas_cols[0], descending=False)
    entities = df[by].to_list()

    fig = make_subplots(
        rows=1,
        cols=2,
        subplot_titles=["Natural Gas Sales", "Natural Gas: % Difference vs EIA"],
        shared_yaxes=True,
        horizontal_spacing=0.12,
    )

    # Left panel: Natural gas sales
    eia_cols, eia_labels, eia_colors = _get_eia_cols_and_labels(df, "natural_gas")
    bs_cols = [f"{r}_natural_gas_kwh" for r in runs]
    bs_labels = runs
    bs_colors = [colors[r] for r in runs]
    
    all_cols = eia_cols + bs_cols
    all_labels = eia_labels + bs_labels
    all_colors = eia_colors + bs_colors

    base_plotter._add_bar_plot(
        fig, df, by, all_cols, all_labels, all_colors, 1, 1, True, "kWh"
    )
    
    # Right panel: Percent difference
    pct_min, pct_max = None, None
    if eia_cols:
        eia_col = eia_cols[0]
        pct_cols = []
        for col in bs_cols:
            pct_col = f"{col}_pct"
            df = df.with_columns(
                pl.when(pl.col(eia_col) == 0)
                .then(None)
                .otherwise((pl.col(col) - pl.col(eia_col)) / pl.col(eia_col) * 100)
                .alias(pct_col)
            )
            pct_cols.append(pct_col)
        
        base_plotter._add_bar_plot(
            fig, df, by, pct_cols, bs_labels, bs_colors, 1, 2, False, "%"
        )
        
        # Calculate min/max for axis range
        for pct_col in pct_cols:
            clean = [v for v in df[pct_col].to_list() if isinstance(v, (int, float))]
            if clean:
                rmin, rmax = min(clean), max(clean)
                pct_min = rmin if pct_min is None else min(pct_min, rmin)
                pct_max = rmax if pct_max is None else max(pct_max, rmax)

    return base_plotter.finalize_annual_plot(
        fig,
        "Natural Gas Sales (kWh)",
        "% Difference vs EIA",
        f"Annual Natural Gas Sales vs EIA by {by.title()}",
        right_range=base_plotter.percent_axis_range(pct_min, pct_max),
        categories=entities,
    )


def plot_annual_sales_comparison_percent_diff(
    buildstock_annual: pl.DataFrame,
    eia_annual: pl.DataFrame,
    by: str = "state",
) -> go.Figure:
    df, runs, colors = _prepare_annual(buildstock_annual, eia_annual, by)

    # Find first EIA electricity column for percent diff sorting
    eia_elec_cols = [col for col in df.columns if col.startswith("eia_electricity_kwh")]
    
    # sort by first run electricity pct diff if possible
    first_run = next((r for r in runs if f"{r}_electricity_kwh" in df.columns), None)
    if first_run and eia_elec_cols:
        eia_elec_col = eia_elec_cols[0]
        df = df.with_columns(
            pl.when(pl.col(eia_elec_col) == 0)
            .then(None)
            .otherwise(
                (pl.col(f"{first_run}_electricity_kwh") - pl.col(eia_elec_col))
                / pl.col(eia_elec_col)
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

    # Electricity percent difference
    e_min, e_max = None, None
    eia_cols, _, _ = _get_eia_cols_and_labels(df, "electricity")
    bs_cols = [f"{r}_electricity_kwh" for r in runs]
    bs_labels = runs
    bs_colors = [colors[r] for r in runs]
    
    if eia_cols:
        eia_col = eia_cols[0]
        pct_cols = []
        for col in bs_cols:
            pct_col = f"{col}_pct"
            df = df.with_columns(
                pl.when(pl.col(eia_col) == 0)
                .then(None)
                .otherwise((pl.col(col) - pl.col(eia_col)) / pl.col(eia_col) * 100)
                .alias(pct_col)
            )
            pct_cols.append(pct_col)
        
        base_plotter._add_bar_plot(
            fig, df, by, pct_cols, bs_labels, bs_colors, 1, 1, True, "%"
        )
        
        for pct_col in pct_cols:
            clean = [v for v in df[pct_col].to_list() if isinstance(v, (int, float))]
            if clean:
                rmin, rmax = min(clean), max(clean)
                e_min = rmin if e_min is None else min(e_min, rmin)
                e_max = rmax if e_max is None else max(e_max, rmax)

    # Natural gas percent difference
    g_min, g_max = None, None
    eia_cols, _, _ = _get_eia_cols_and_labels(df, "natural_gas")
    bs_cols = [f"{r}_natural_gas_kwh" for r in runs]
    bs_labels = runs
    bs_colors = [colors[r] for r in runs]
    
    if eia_cols:
        eia_col = eia_cols[0]
        pct_cols = []
        for col in bs_cols:
            pct_col = f"{col}_pct"
            df = df.with_columns(
                pl.when(pl.col(eia_col) == 0)
                .then(None)
                .otherwise((pl.col(col) - pl.col(eia_col)) / pl.col(eia_col) * 100)
                .alias(pct_col)
            )
            pct_cols.append(pct_col)
        
        base_plotter._add_bar_plot(
            fig, df, by, pct_cols, bs_labels, bs_colors, 1, 2, False, "%"
        )
        
        for pct_col in pct_cols:
            clean = [v for v in df[pct_col].to_list() if isinstance(v, (int, float))]
            if clean:
                rmin, rmax = min(clean), max(clean)
                g_min = rmin if g_min is None else min(g_min, rmin)
                g_max = rmax if g_max is None else max(g_max, rmax)

    return base_plotter.finalize_annual_plot(
        fig,
        "% Difference vs EIA",
        "% Difference vs EIA",
        f"Annual % Difference vs EIA by {by.title()}",
        left_range=base_plotter.percent_axis_range(e_min, e_max),
        right_range=base_plotter.percent_axis_range(g_min, g_max),
        categories=entities,
    )


def plot_monthly_sales_comparison_electricity(
    buildstock_monthly: pl.DataFrame,
    eia_monthly: pl.DataFrame,
    by: str = "state",
    use_shared_axis: bool = True,
) -> go.Figure:
    df, runs, colors = _prepare_monthly(buildstock_monthly, eia_monthly, by)
    eia_cols, eia_labels, eia_colors = _get_eia_cols_and_labels(df, "electricity")
    bs_cols = [f"{r}_electricity_kwh" for r in runs]
    bs_labels = runs
    bs_colors = [colors[r] for r in runs]

    # Combine all columns, labels, and colors
    all_cols = eia_cols + bs_cols
    all_labels = eia_labels + bs_labels
    all_colors = eia_colors + bs_colors

    # Order entities by first EIA column if available
    ref_col = eia_cols[0] if eia_cols else bs_cols[0]
    order_df = (
        df.group_by(by)
        .agg(pl.col(ref_col).sum().alias("_total"))
        .sort("_total", descending=True)
    )
    entities = order_df[by].to_list()

    # Compute axis ranges
    df = df.with_columns(
        pl.max_horizontal(pl.col(all_cols)).alias("_entity_max")
    )
    global_max = df["_entity_max"].max()
    shared_range = [0, global_max * 1.05] if isinstance(global_max, (int, float)) else None

    # Create subplot grid
    subplot_titles = [entities[i] if i < len(entities) else "" for i in range(MONTH_MAX)]
    fig = make_subplots(
        rows=MONTH_ROWS,
        cols=MONTH_COLS,
        subplot_titles=subplot_titles,
        horizontal_spacing=0.015,
        vertical_spacing=0.08,
    )

    visible_entities = entities[:MONTH_MAX]
    for idx, entity in enumerate(visible_entities, start=1):
        row = (idx - 1) // MONTH_COLS + 1
        col = (idx - 1) % MONTH_COLS + 1

        entity_df = df.filter(pl.col(by) == entity).sort("_month_order")
        
        base_plotter._add_monthly_line_chart(
            fig, entity_df, "_month_label", all_cols, all_labels, all_colors,
            row, col, (idx == 1), "kWh"
        )

        # Configure axes
        months = entity_df["_month_label"].to_list()
        fig.update_xaxes(
            categoryorder="array",
            categoryarray=months,
            tickfont={"size": 8},
            automargin=True,
            showticklabels=True,
            row=row,
            col=col,
        )
        
        entity_max = entity_df["_entity_max"].max()
        per_range = [0, entity_max * 1.05] if isinstance(entity_max, (int, float)) else None
        fig.update_yaxes(
            title_text="Electricity Sales (kWh)" if col == 1 else "",
            range=(shared_range if (use_shared_axis and shared_range) else per_range),
            tickfont={"size": 8},
            automargin=True,
            row=row,
            col=col,
        )

    # Fill empty panels
    for idx in range(len(visible_entities) + 1, MONTH_MAX + 1):
        row = (idx - 1) // MONTH_COLS + 1
        col = (idx - 1) % MONTH_COLS + 1
        fig.update_xaxes(visible=False, row=row, col=col)
        fig.update_yaxes(visible=False, row=row, col=col)

    fig.update_layout(showlegend=True)
    fig = apply_theme(
        fig,
        title=f"Monthly Electricity Sales by {by.title()}",
        height=1100,
        width=1950,
        legend={"orientation": "v", "x": 0.92, "y": 0.02, "xanchor": "left", "yanchor": "bottom"},
        margin={"l": 45, "r": 20, "t": 60, "b": 55},
    )
    return fig


def plot_monthly_sales_comparison_natural_gas(
    buildstock_monthly: pl.DataFrame,
    eia_monthly: pl.DataFrame,
    by: str = "state",
    use_shared_axis: bool = True,
) -> go.Figure:
    df, runs, colors = _prepare_monthly(buildstock_monthly, eia_monthly, by)
    eia_cols, eia_labels, eia_colors = _get_eia_cols_and_labels(df, "natural_gas")
    bs_cols = [f"{r}_natural_gas_kwh" for r in runs]
    bs_labels = runs
    bs_colors = [colors[r] for r in runs]

    # Combine all columns, labels, and colors
    all_cols = eia_cols + bs_cols
    all_labels = eia_labels + bs_labels
    all_colors = eia_colors + bs_colors

    # Order entities by first EIA column if available
    ref_col = eia_cols[0] if eia_cols else bs_cols[0]
    order_df = (
        df.group_by(by)
        .agg(pl.col(ref_col).sum().alias("_total"))
        .sort("_total", descending=True)
    )
    entities = order_df[by].to_list()

    # Compute axis ranges
    df = df.with_columns(
        pl.max_horizontal(pl.col(all_cols)).alias("_entity_max")
    )
    global_max = df["_entity_max"].max()
    shared_range = [0, global_max * 1.05] if isinstance(global_max, (int, float)) else None

    # Create subplot grid
    subplot_titles = [entities[i] if i < len(entities) else "" for i in range(MONTH_MAX)]
    fig = make_subplots(
        rows=MONTH_ROWS,
        cols=MONTH_COLS,
        subplot_titles=subplot_titles,
        horizontal_spacing=0.015,
        vertical_spacing=0.08,
    )

    visible_entities = entities[:MONTH_MAX]
    for idx, entity in enumerate(visible_entities, start=1):
        row = (idx - 1) // MONTH_COLS + 1
        col = (idx - 1) % MONTH_COLS + 1

        entity_df = df.filter(pl.col(by) == entity).sort("_month_order")
        
        base_plotter._add_monthly_line_chart(
            fig, entity_df, "_month_label", all_cols, all_labels, all_colors,
            row, col, (idx == 1), "kWh"
        )

        # Configure axes
        months = entity_df["_month_label"].to_list()
        fig.update_xaxes(
            categoryorder="array",
            categoryarray=months,
            tickfont={"size": 8},
            automargin=True,
            showticklabels=True,
            row=row,
            col=col,
        )
        
        entity_max = entity_df["_entity_max"].max()
        per_range = [0, entity_max * 1.05] if isinstance(entity_max, (int, float)) else None
        fig.update_yaxes(
            title_text="Natural Gas Sales (kWh)" if col == 1 else "",
            range=(shared_range if (use_shared_axis and shared_range) else per_range),
            tickfont={"size": 8},
            automargin=True,
            row=row,
            col=col,
        )

    # Fill empty panels
    for idx in range(len(visible_entities) + 1, MONTH_MAX + 1):
        row = (idx - 1) // MONTH_COLS + 1
        col = (idx - 1) % MONTH_COLS + 1
        fig.update_xaxes(visible=False, row=row, col=col)
        fig.update_yaxes(visible=False, row=row, col=col)

    fig.update_layout(showlegend=True)
    fig = apply_theme(
        fig,
        title=f"Monthly Natural Gas Sales by {by.title()}",
        height=1100,
        width=1950,
        legend={"orientation": "v", "x": 0.92, "y": 0.02, "xanchor": "left", "yanchor": "bottom"},
        margin={"l": 45, "r": 20, "t": 60, "b": 55},
    )
    return fig


def create_plot(data: pl.DataFrame, plot_spec: PlotSpec) -> go.Figure:
    if plot_spec.resolution == "year":
        buildstock, eia_df = _split_annual_data(data, plot_spec.aggregation_level)

        if plot_spec.aggregation_type == AggregationType.stock_total:
            match plot_spec.quantity:
                case DataCol.ALL:
                    return plot_annual_sales_comparison(buildstock, eia_df, by=plot_spec.aggregation_level)
                case DataCol.ELECTRICITY_TOTAL:
                    return plot_annual_sales_comparison_electricity(buildstock, eia_df, by=plot_spec.aggregation_level)
                case DataCol.NATURAL_GAS_TOTAL:
                    return plot_annual_sales_comparison_natural_gas(buildstock, eia_df, by=plot_spec.aggregation_level)
        elif plot_spec.aggregation_type == AggregationType.percent_difference and plot_spec.quantity == DataCol.ALL:
            return plot_annual_sales_comparison_percent_diff(buildstock, eia_df, by=plot_spec.aggregation_level)
    elif plot_spec.resolution == "month":
        buildstock, eia_df = _split_monthly_data(data, plot_spec.aggregation_level)
        fuel: str
        if plot_spec.quantity == DataCol.ELECTRICITY_TOTAL:
            fuel = "electricity"
        elif plot_spec.quantity == DataCol.NATURAL_GAS_TOTAL:
            fuel = "natural_gas"
        else:
            raise NotImplementedError(
                "Monthly EIA plotting requires quantity to be electricity or natural_gas"
            )

        if plot_spec.aggregation_type == AggregationType.stock_total:
            if fuel == "electricity":
                return plot_monthly_sales_comparison_electricity(
                    buildstock, eia_df, by=plot_spec.aggregation_level
                )
            if fuel == "natural_gas":
                return plot_monthly_sales_comparison_natural_gas(
                    buildstock, eia_df, by=plot_spec.aggregation_level
                )
        elif plot_spec.aggregation_type == AggregationType.percent_difference:
            df, runs, colors = _prepare_monthly(buildstock, eia_df, plot_spec.aggregation_level)
            eia_cols, _, _ = _get_eia_cols_and_labels(df, fuel)
            bs_cols = [f"{r}_{fuel}_kwh" for r in runs]
            bs_labels = runs
            bs_colors = [colors[r] for r in runs]
            
            if not eia_cols:
                raise ValueError(f"No EIA {fuel} columns found")

            eia_col = eia_cols[0]
            
            # Compute percent difference columns
            pct_cols = []
            for col in bs_cols:
                pct_col = f"{col}_pct"
                df = df.with_columns(
                    pl.when(pl.col(eia_col) == 0)
                    .then(None)
                    .otherwise((pl.col(col) - pl.col(eia_col)) / pl.col(eia_col) * 100)
                    .alias(pct_col)
                )
                pct_cols.append(pct_col)

            # Order entities
            order_df = (
                df.group_by(plot_spec.aggregation_level)
                .agg(pl.col(eia_col).sum().alias("_total"))
                .sort("_total", descending=False)
            )
            entities = order_df[plot_spec.aggregation_level].to_list()

            # Calculate global min/max for axis range
            global_min, global_max = None, None
            for col in pct_cols:
                clean = [v for v in df[col].to_list() if isinstance(v, (int, float))]
                if not clean:
                    continue
                cmin, cmax = min(clean), max(clean)
                global_min = cmin if global_min is None else min(global_min, cmin)
                global_max = cmax if global_max is None else max(global_max, cmax)

            shared_range = base_plotter.percent_axis_range(global_min, global_max)

            # Create subplot grid
            subplot_titles = [entities[i] if i < len(entities) else "" for i in range(MONTH_MAX)]
            fig = make_subplots(
                rows=MONTH_ROWS,
                cols=MONTH_COLS,
                subplot_titles=subplot_titles,
                horizontal_spacing=0.015,
                vertical_spacing=0.08,
            )

            visible_entities = entities[:MONTH_MAX]
            for idx, entity in enumerate(visible_entities, start=1):
                row = (idx - 1) // MONTH_COLS + 1
                col = (idx - 1) % MONTH_COLS + 1

                entity_df = df.filter(pl.col(plot_spec.aggregation_level) == entity).sort("_month_order")
                
                base_plotter._add_monthly_line_chart(
                    fig, entity_df, "_month_label", pct_cols, bs_labels, bs_colors,
                    row, col, (idx == 1), "%"
                )

                # Configure axes
                months = entity_df["_month_label"].to_list()
                fig.update_xaxes(
                    categoryorder="array",
                    categoryarray=months,
                    tickfont={"size": 8},
                    automargin=True,
                    row=row,
                    col=col,
                )
                
                # Calculate entity-specific range
                entity_min, entity_max = None, None
                for pct_col in pct_cols:
                    clean = [v for v in entity_df[pct_col].to_list() if isinstance(v, (int, float))]
                    if clean:
                        cmin, cmax = min(clean), max(clean)
                        entity_min = cmin if entity_min is None else min(entity_min, cmin)
                        entity_max = cmax if entity_max is None else max(entity_max, cmax)
                
                entity_range = base_plotter.percent_axis_range(entity_min, entity_max)
                fig.update_yaxes(
                    tickfont={"size": 8},
                    automargin=True,
                    showticklabels=True,
                    title_text="% Difference" if col == 1 else "",
                    row=row,
                    col=col,
                    range=(shared_range if (True and shared_range) else entity_range),
                )

            # Fill empty panels
            for idx in range(len(visible_entities) + 1, MONTH_MAX + 1):
                row = (idx - 1) // MONTH_COLS + 1
                col = (idx - 1) % MONTH_COLS + 1
                fig.update_xaxes(visible=False, row=row, col=col)
                fig.update_yaxes(visible=False, row=row, col=col)

            fig.update_layout(showlegend=True)
            fig = apply_theme(
                fig,
                title=f"Monthly {fuel.replace('_', ' ').title()} % Difference by {plot_spec.aggregation_level.title()}",
                height=1100,
                width=1950,
                legend={"orientation": "v", "x": 0.92, "y": 0.02, "xanchor": "left", "yanchor": "bottom"},
                margin={"l": 45, "r": 20, "t": 60, "b": 55},
            )
            return fig

    qty = plot_spec.quantity.value if plot_spec.quantity else "all"
    raise NotImplementedError(
        f"EIA plot for resolution='{plot_spec.resolution}', "
        f"quantity_type='{plot_spec.aggregation_type.value}', and quantity='{qty}' is not supported"
    )
