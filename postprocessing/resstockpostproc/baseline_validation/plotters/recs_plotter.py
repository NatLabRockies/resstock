import calendar
from typing import Any

import polars as pl
import plotly.graph_objects as go
from plotly.subplots import make_subplots

from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    QuantityType,
)
from resstockpostproc.shared_utils.colors import QUALITATIVE_SERIES, REF_QUALITATIVE_SERIES
from resstockpostproc.baseline_validation.plotters import base_plotter
from resstockpostproc.baseline_validation.theme import apply_theme


# ---------------------------------------------------------------------------
# constants
# ---------------------------------------------------------------------------
RECS_COLORS = REF_QUALITATIVE_SERIES
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


def _run_names(df: pl.DataFrame) -> list[str]:
    """Find run prefixes like 'baseline', 'upgrade1' from *_electricity_kwh / *_natural_gas_kwh columns."""
    names: list[str] = []
    for col in df.columns:
        if col.startswith("resstock_"):
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
    recs_annual: pl.DataFrame,
    by: str,
) -> tuple[pl.DataFrame, list[str], dict[str, str]]:
    # check basic columns
    # Find all RECS columns (starting with recs_)
    recs_cols = [col for col in recs_annual.columns if col.startswith("recs_") and col != by]
    if not recs_cols:
        raise ValueError("No RECS columns found in annual data")
    _require_columns(recs_annual, {by} | set(recs_cols), "RECS annual")
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
    # Select by column and all RECS columns
    recs = recs_annual.select([by] + recs_cols)
    df = recs.join(bs, on=by, how="inner")
    if df.is_empty():
        raise ValueError(f"No overlap on '{by}' between RECS and BuildStock annual")

    return df, runs, _run_colors(runs)


# ---------------------------------------------------------------------------
# annual plot helpers
# ---------------------------------------------------------------------------
def _get_recs_cols_and_labels(df: pl.DataFrame, quantity: str) -> tuple[list[str], list[str], list[str]]:
    # RECS columns are expected to be like "RECS out.electricity.total.energy_consumption Value"
    # We look for columns starting with "RECS " and ending with " Value", containing the quantity
    cols = [col for col in df.columns if col.startswith("RECS ") and col.endswith(" Value") and quantity in col]
    labels = []
    colors = []
    for i, col in enumerate(cols):
        # Show as "RECS 2020"
        labels.append("RECS 2020")
        colors.append(RECS_COLORS[i % len(RECS_COLORS)])
    return cols, labels, colors


def plot_annual_sales_comparison(
    buildstock_annual: pl.DataFrame,
    recs_annual: pl.DataFrame,
    by: str = "state",
) -> go.Figure:
    df, runs, colors = _prepare_annual(buildstock_annual, recs_annual, by)
    # Find first RECS electricity column for sorting
    recs_elec_cols = [col for col in df.columns if col.startswith("recs_electricity")]
    if recs_elec_cols:
        df = df.sort(recs_elec_cols[0], descending=False)
    entities = df[by].to_list()

    fig = make_subplots(
        rows=1,
        cols=2,
        subplot_titles=["Electricity Sales", "Natural Gas Sales"],
        shared_yaxes=True,
        horizontal_spacing=0.12,
    )

    # Electricity panel
    recs_cols, recs_labels, recs_colors = _get_recs_cols_and_labels(df, "electricity")
    bs_cols = [f"{r}_electricity_kwh" for r in runs]
    bs_labels = runs
    bs_colors = [colors[r] for r in runs]
    
    # Combine all columns, labels, and colors (RECS first, then BuildStock)
    all_cols = recs_cols + bs_cols
    all_labels = recs_labels + bs_labels
    all_colors = recs_colors + bs_colors
    
    base_plotter._add_bar_plot(
        fig, df, by, all_cols, all_labels, all_colors, 1, 1, True, "kWh"
    )

    # Natural Gas panel
    recs_cols, recs_labels, recs_colors = _get_recs_cols_and_labels(df, "natural_gas")
    bs_cols = [f"{r}_natural_gas_kwh" for r in runs]
    bs_labels = runs
    bs_colors = [colors[r] for r in runs]
    
    all_cols = recs_cols + bs_cols
    all_labels = recs_labels + bs_labels
    all_colors = recs_colors + bs_colors

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
    recs_annual: pl.DataFrame,
    by: str = "state",
) -> go.Figure:
    df, runs, colors = _prepare_annual(buildstock_annual, recs_annual, by)
    recs_elec_cols = [col for col in df.columns if col.startswith("recs_electricity")]
    if recs_elec_cols:
        df = df.sort(recs_elec_cols[0], descending=False)
    entities = df[by].to_list()

    fig = make_subplots(
        rows=1,
        cols=2,
        subplot_titles=["Electricity Sales", "Electricity: % Difference vs RECS"],
        shared_yaxes=True,
        horizontal_spacing=0.12,
    )

    # Left panel: Electricity sales
    recs_cols, recs_labels, recs_colors = _get_recs_cols_and_labels(df, "electricity")
    bs_cols = [f"{r}_electricity_kwh" for r in runs]
    bs_labels = runs
    bs_colors = [colors[r] for r in runs]
    
    all_cols = recs_cols + bs_cols
    all_labels = recs_labels + bs_labels
    all_colors = recs_colors + bs_colors

    base_plotter._add_bar_plot(
        fig, df, by, all_cols, all_labels, all_colors, 1, 1, True, "kWh"
    )
    
    # Right panel: Percent difference
    pct_min, pct_max = None, None
    if recs_cols:
        recs_col = recs_cols[0]
        pct_cols = []
        for col in bs_cols:
            pct_col = f"{col}_pct"
            df = df.with_columns(
                pl.when(pl.col(recs_col) == 0)
                .then(None)
                .otherwise((pl.col(col) - pl.col(recs_col)) / pl.col(recs_col) * 100)
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
        "% Difference vs RECS",
        f"Annual Electricity Sales vs RECS by {by.title()}",
        right_range=base_plotter.percent_axis_range(pct_min, pct_max),
        categories=entities,
    )


def plot_annual_sales_comparison_natural_gas(
    buildstock_annual: pl.DataFrame,
    recs_annual: pl.DataFrame,
    by: str = "state",
) -> go.Figure:
    df, runs, colors = _prepare_annual(buildstock_annual, recs_annual, by)
    recs_gas_cols = [col for col in df.columns if col.startswith("recs_natural_gas")]
    if recs_gas_cols:
        df = df.sort(recs_gas_cols[0], descending=False)
    entities = df[by].to_list()

    fig = make_subplots(
        rows=1,
        cols=2,
        subplot_titles=["Natural Gas Sales", "Natural Gas: % Difference vs RECS"],
        shared_yaxes=True,
        horizontal_spacing=0.12,
    )

    # Left panel: Natural gas sales
    recs_cols, recs_labels, recs_colors = _get_recs_cols_and_labels(df, "natural_gas")
    bs_cols = [f"{r}_natural_gas_kwh" for r in runs]
    bs_labels = runs
    bs_colors = [colors[r] for r in runs]
    
    all_cols = recs_cols + bs_cols
    all_labels = recs_labels + bs_labels
    all_colors = recs_colors + bs_colors

    base_plotter._add_bar_plot(
        fig, df, by, all_cols, all_labels, all_colors, 1, 1, True, "kWh"
    )
    
    # Right panel: Percent difference
    pct_min, pct_max = None, None
    if recs_cols:
        recs_col = recs_cols[0]
        pct_cols = []
        for col in bs_cols:
            pct_col = f"{col}_pct"
            df = df.with_columns(
                pl.when(pl.col(recs_col) == 0)
                .then(None)
                .otherwise((pl.col(col) - pl.col(recs_col)) / pl.col(recs_col) * 100)
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
        "% Difference vs RECS",
        f"Annual Natural Gas Sales vs RECS by {by.title()}",
        right_range=base_plotter.percent_axis_range(pct_min, pct_max),
        categories=entities,
    )


def plot_annual_sales_comparison_percent_diff(
    buildstock_annual: pl.DataFrame,
    recs_annual: pl.DataFrame,
    by: str = "state",
) -> go.Figure:
    df, runs, colors = _prepare_annual(buildstock_annual, recs_annual, by)

    # Find first RECS electricity column for percent diff sorting
    recs_elec_cols = [col for col in df.columns if col.startswith("recs_electricity")]
    
    # sort by first run electricity pct diff if possible
    first_run = next((r for r in runs if f"{r}_electricity_kwh" in df.columns), None)
    if first_run and recs_elec_cols:
        recs_elec_col = recs_elec_cols[0]
        df = df.with_columns(
            pl.when(pl.col(recs_elec_col) == 0)
            .then(None)
            .otherwise(
                (pl.col(f"{first_run}_electricity_kwh") - pl.col(recs_elec_col))
                / pl.col(recs_elec_col)
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
    recs_cols, _, _ = _get_recs_cols_and_labels(df, "electricity")
    bs_cols = [f"{r}_electricity_kwh" for r in runs]
    bs_labels = runs
    bs_colors = [colors[r] for r in runs]
    
    if recs_cols:
        recs_col = recs_cols[0]
        pct_cols = []
        for col in bs_cols:
            pct_col = f"{col}_pct"
            df = df.with_columns(
                pl.when(pl.col(recs_col) == 0)
                .then(None)
                .otherwise((pl.col(col) - pl.col(recs_col)) / pl.col(recs_col) * 100)
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
    recs_cols, _, _ = _get_recs_cols_and_labels(df, "natural_gas")
    bs_cols = [f"{r}_natural_gas_kwh" for r in runs]
    bs_labels = runs
    bs_colors = [colors[r] for r in runs]
    
    if recs_cols:
        recs_col = recs_cols[0]
        pct_cols = []
        for col in bs_cols:
            pct_col = f"{col}_pct"
            df = df.with_columns(
                pl.when(pl.col(recs_col) == 0)
                .then(None)
                .otherwise((pl.col(col) - pl.col(recs_col)) / pl.col(recs_col) * 100)
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
        "% Difference vs RECS",
        "% Difference vs RECS",
        f"Annual % Difference vs RECS by {by.title()}",
        left_range=base_plotter.percent_axis_range(e_min, e_max),
        right_range=base_plotter.percent_axis_range(g_min, g_max),
        categories=entities,
    )


# ---------------------------------------------------------------------------
# monthly plot helpers
# ---------------------------------------------------------------------------

# Geographic layout for states - list of lists
# Each inner list is a row, position in that list determines the column
# None represents an empty cell in the grid
# Grid arranged to roughly match US geography
GEOGRAPHIC_STATE_LAYOUT = [
    ["WA", "ID", "MT", "ND", "MN", "WI", "MI", "NY", "VT", "NH", "ME"],
    ["OR", "NV", "WY", "SD", "IA", "IL", "IN", "OH", "PA", "NJ", "MA"],
    ["CA", "UT", "CO", "NE", "MO", "KY", "WV", "VA", "MD", "CT", "RI"],
    [None, "AZ", "NM", "KS", "AR", "TN", "NC", "SC", "DC", "DE", None],
    [None, None, None, "OK", "LA", "MS", "AL", "GA", None, None, None],
    ["AK", "HI", None, "TX", None, None, None, "FL", None, None, None],
]

GRID_ROWS = len(GEOGRAPHIC_STATE_LAYOUT)
GRID_COLS = max(len(row) for row in GEOGRAPHIC_STATE_LAYOUT)

def _compute_monthly_percent_diff(
    df: pl.DataFrame,
    quantity_cols: list[str],
) -> tuple[pl.DataFrame, list[str]]:
    """
    Compute percent difference columns for monthly data.
    Uses the first non-resstock column as the reference.
    
    Args:
        df: DataFrame with quantity columns
        quantity_cols: List of column names (both reference and resstock)
    
    Returns:
        Tuple of (updated dataframe with pct columns, list of pct column names)
    """
    # Find reference column (first non-resstock column)
    ref_col = next((col for col in quantity_cols if not col.startswith("resstock_")), None)
    if not ref_col:
        raise ValueError("No reference column found for percent difference calculation")
    
    # Find resstock columns
    resstock_cols = [col for col in quantity_cols if col.startswith("resstock_")]
    
    pct_cols = []
    for col in resstock_cols:
        pct_col = f"{col}_pct"
        df = df.with_columns(
            pl.when(pl.col(ref_col) == 0)
            .then(None)
            .otherwise((pl.col(col) - pl.col(ref_col)) / pl.col(ref_col) * 100)
            .alias(pct_col)
        )
        pct_cols.append(pct_col)
    
    return df, pct_cols


def _add_monthly_band_with_rse(
    fig: go.Figure,
    df: pl.DataFrame,
    x_col: str,
    value_col: str,
    rse_col: str,
    label: str,
    label_band: str,
    color: str,
    row: int,
    col: int,
    showlegend: bool,
    y_unit: str = "kWh",
) -> None:
    """
    Add a band plot using RSE (Relative Standard Error) to show uncertainty.
    
    Args:
        fig: Plotly figure object
        df: DataFrame containing the data
        x_col: Column name for x-axis
        value_col: Column name for the value
        rse_col: Column name for RSE (as a percentage)
        label: Label for the center line trace
        label_band: Label for the band trace
        color: Color for the band
        row: Subplot row position
        col: Subplot column position
        showlegend: Whether to show legend
        y_unit: Unit label for y-axis
    """
    x_values = df[x_col].to_list()
    y_values = df[value_col].to_list()
    rse_values = df[rse_col].to_list() if rse_col in df.columns else [0] * len(y_values)
    
    # Calculate upper and lower bounds using RSE
    # RSE is relative standard error as a percentage
    # For 95% confidence interval, multiply by 1.96
    upper_bounds = []
    lower_bounds = []
    for y, rse in zip(y_values, rse_values):
        if y is None or rse is None:
            upper_bounds.append(None)
            lower_bounds.append(None)
        else:
            # RSE is in percentage, so convert to decimal and calculate bounds
            # 1.96 is the z-score for 95% confidence interval
            error = y * (rse / 100.0) * 1.96
            upper_bounds.append(y + error)
            lower_bounds.append(max(0, y - error))  # Don't go below 0
    
    # Add the band (filled area)
    fig.add_scatter(
        x=x_values + x_values[::-1],
        y=upper_bounds + lower_bounds[::-1],
        fill="toself",
        fillcolor=color,
        opacity=0.3,
        line={"color": "rgba(255,255,255,0)"},
        showlegend=showlegend,
        name=label_band,
        legendgroup=label,
        hoverinfo="skip",
        row=row,
        col=col,
    )
    
    # Add the center line
    fig.add_scatter(
        x=x_values,
        y=y_values,
        mode="lines+markers",
        name=label,
        legendgroup=label,
        marker={"color": color, "size": 3},
        line={"color": color, "width": 1.5},
        hovertemplate="%{x}<br>" + f"{label}: " + "%{y:,.0f} " + y_unit + "<extra></extra>",
        showlegend=showlegend,
        row=row,
        col=col,
    )


def plot_monthly_sales(
    data: pl.DataFrame,
    by: str,
    quantity: str,
    title: str,
    y_label: str,
    use_shared_axis: bool = True,
) -> go.Figure:
    """
    Generic monthly sales plotting function with geographic layout and size-proportional subplots.
    
    Args:
        data: DataFrame with all columns (both reference and resstock)
        by: Grouping column (e.g., 'state')
        quantity: Quantity to plot (e.g., 'electricity', 'natural_gas')
        title: Plot title
        y_label: Y-axis label
        use_shared_axis: Whether to use shared y-axis scaling
    """
    # Add month columns if not present
    if "_month_order" not in data.columns:
        data = data.with_columns(
            pl.col("month").map_elements(_month_to_index, return_dtype=pl.Int16).alias("_month_order"),
            pl.col("month").map_elements(
                lambda m: MONTH_INDEX_TO_LABEL[_month_to_index(m)], return_dtype=pl.Utf8
            ).alias("_month_label"),
        )
    
    
    # Filter columns based on quantity
    quantity_cols = [
        col for col in data.columns
        if quantity in col and col.endswith("_value")
    ]
    if not quantity_cols:
        raise ValueError(f"No columns found containing '{quantity}'")
    
    # Separate reference and resstock columns
    ref_cols = [col for col in quantity_cols if not col.startswith("resstock_")]
    resstock_cols = [col for col in quantity_cols if col.startswith("resstock_")]
    
    # Check which RECS columns have RSE
    ref_cols_with_rse = []
    ref_rse_cols = []
    ref_labels = []
    ref_labels_band = []
    for col in ref_cols:
        rse_col = col.replace("_value", "_rse")
        if rse_col in data.columns:
            ref_cols_with_rse.append(col)
            ref_rse_cols.append(rse_col)
            ref_labels.append("RECS 2020 (estimate)")
            ref_labels_band.append("RECS 2020 (95% CI band)")
        else:
            ref_cols_with_rse.append(col)
            ref_rse_cols.append(None)
            ref_labels.append("RECS 2020")
            ref_labels_band.append("RECS 2020")
    
    ref_colors = [RECS_COLORS[i % len(RECS_COLORS)] for i in range(len(ref_cols))]
    
    # Get run names and colors for resstock columns
    resstock_labels = [col.replace("resstock_", "").replace(f"_{quantity}_kwh", "") for col in resstock_cols]
    resstock_colors = [_RUN_PALETTE[i % len(_RUN_PALETTE)] for i in range(len(resstock_labels))]
    
    # Order entities geographically based on their position in the layout
    all_entities = data[by].unique().sort().to_list()
    
    # Build a dict mapping state to (row, col) for sorting
    state_positions = {}
    for row_idx, row in enumerate(GEOGRAPHIC_STATE_LAYOUT):
        for col_idx, state in enumerate(row):
            if state is not None:
                state_positions[state] = (row_idx, col_idx)
    
    # Sort states by their geographic position (row, col)
    entities = sorted(
        [state for state in all_entities if state in state_positions],
        key=lambda s: state_positions[s]
    )
    
    # Add any states not in the geographic layout at the end
    for state in all_entities:
        if state not in entities:
            entities.append(state)
    
    # Compute axis ranges - account for RSE bands
    # Calculate upper bounds for RECS columns with RSE
    upper_bound_cols = []
    for value_col, rse_col in zip(ref_cols_with_rse, ref_rse_cols):
        if rse_col is not None and rse_col in data.columns:
            upper_col = f"{value_col}_upper"
            df = data.with_columns(
                (pl.col(value_col) + pl.col(value_col) * pl.col(rse_col) / 100.0).alias(upper_col)
            )
            upper_bound_cols.append(upper_col)
            data = df
        else:
            upper_bound_cols.append(value_col)
    
    # Compute max including upper bounds of bands
    df = data.with_columns(
        pl.max_horizontal(pl.col(upper_bound_cols + resstock_cols)).alias("_entity_max")
    )
    global_max = df["_entity_max"].max()
    shared_range = [0, global_max * 1.05] if isinstance(global_max, (int, float)) else None
    
    # Create figure with all possible subplots
    subplot_titles = []
    for row in range(GRID_ROWS):
        for col in range(GRID_COLS):
            if (
                row < len(GEOGRAPHIC_STATE_LAYOUT)
                and col < len(GEOGRAPHIC_STATE_LAYOUT[row])
                and GEOGRAPHIC_STATE_LAYOUT[row][col] is not None
            ):
                subplot_titles.append(GEOGRAPHIC_STATE_LAYOUT[row][col])
            else:
                subplot_titles.append("")
    
    fig = make_subplots(
        rows=GRID_ROWS,
        cols=GRID_COLS,
        subplot_titles=subplot_titles,
        shared_yaxes=use_shared_axis,
        horizontal_spacing=0.02,
        vertical_spacing=0.1,
    )

    # Add traces for each state and update titles
    for entity in entities:
        if entity not in state_positions:
            continue
            
        row, col = state_positions[entity]
        entity_df = df.filter(pl.col(by) == entity).sort("_month_order")
        
        if entity_df.is_empty():
            continue
        
        months = entity_df["_month_label"].to_list()
        
        # Add RECS bands (with RSE) first
        for i, (value_col, rse_col) in enumerate(zip(ref_cols_with_rse, ref_rse_cols)):
            if rse_col is not None and rse_col in entity_df.columns:
                _add_monthly_band_with_rse(
                    fig, entity_df, "_month_label", value_col, rse_col,
                    ref_labels[i], ref_labels_band[i], ref_colors[i],
                    row + 1, col + 1, (entity == entities[0]), "kWh"
                )
            else:
                # If no RSE, plot as regular line
                base_plotter._add_monthly_line_chart(
                    fig, entity_df, "_month_label", [value_col], [ref_labels[i]], [ref_colors[i]],
                    row + 1, col + 1, (entity == entities[0]), "kWh"
                )
        
        # Add ResStock lines (no RSE)
        if resstock_cols:
            base_plotter._add_monthly_line_chart(
                fig, entity_df, "_month_label", resstock_cols, resstock_labels, resstock_colors,
                row + 1, col + 1, (entity == entities[0]), "kWh"
            )
        
        # Configure axes - ensure all 12 months are always shown
        all_months = [MONTH_INDEX_TO_LABEL[i] for i in range(1, 13)]
        # Show labels only for Jan, Mar, Jun, Aug, Dec
        display_months = ["Jan", "Dec"]
        ticktext = [month if month in display_months else "" for month in all_months]
        fig.update_xaxes(
            categoryorder="array",
            categoryarray=all_months,
            tickmode="array",
            tickvals=all_months,
            ticktext=ticktext,
            tickfont={"size": 12},
            automargin=True,
            showticklabels=True,
            row=row + 1,
            col=col + 1,
        )
        
        entity_max = entity_df["_entity_max"].max()
        per_range = [0, entity_max * 1.05] if isinstance(entity_max, (int, float)) else None
        
        # Show y-axis label for first non-None plot in each row (always)
        is_first_in_row = col == 0 or (col > 0 and GEOGRAPHIC_STATE_LAYOUT[row][col - 1] is None)
        
        # Show ticklabels based on use_shared_axis
        # If use_shared_axis is False, show ticks on all subplots
        # If use_shared_axis is True, show ticks only on first in row or after empty subplot
        show_ticks = not use_shared_axis or is_first_in_row
        
        fig.update_yaxes(
            title_text="kWh" if is_first_in_row else "",
            title_font={"size": 12},
            range=(shared_range if (use_shared_axis and shared_range) else per_range),
            tickfont={"size": 12},
            automargin=True,
            showticklabels=show_ticks,
            row=row + 1,
            col=col + 1,
        )
        
    # Hide axes for empty subplots
    for row in range(GRID_ROWS):
        for col in range(GRID_COLS):
            # Check if this position has a state
            has_state = (
                row < len(GEOGRAPHIC_STATE_LAYOUT) and
                col < len(GEOGRAPHIC_STATE_LAYOUT[row]) and
                GEOGRAPHIC_STATE_LAYOUT[row][col] is not None
            )
            if not has_state:
                fig.update_xaxes(visible=False, row=row + 1, col=col + 1)
                fig.update_yaxes(visible=False, row=row + 1, col=col + 1)

    fig.update_layout(showlegend=True)

    fig = apply_theme(
        fig,
        title=title,
        height=1080 * 0.8,
        width=1920 * 0.8,
        font={"size": 14},
        legend={
            "orientation": "v",
            "x": 0.99,
            "y": 0.01,
            "xanchor": "right",
            "yanchor": "bottom",
            "font": {"size": 14},
            "bgcolor": "rgba(255, 255, 255, 0.8)",
        },
        margin={"l": 60, "r": 60, "t": 100, "b": 60},
    )
    return fig


def create_plot(data: pl.DataFrame, plot_spec: PlotSpec) -> go.Figure:
    if plot_spec.resolution == "annual":
        if plot_spec.quantity_type == QuantityType.stock_energy:
            match plot_spec.quantity:
                case None:
                    return plot_annual_sales_comparison(data, data, by=plot_spec.aggregation_level)
                case DataCol.ELECTRICITY_TOTAL:
                    return plot_annual_sales_comparison_electricity(data, data, by=plot_spec.aggregation_level)
                case DataCol.NATURAL_GAS_TOTAL:
                    return plot_annual_sales_comparison_natural_gas(data, data, by=plot_spec.aggregation_level)
        elif plot_spec.quantity_type == QuantityType.percent_difference and plot_spec.quantity is None:
            return plot_annual_sales_comparison_percent_diff(data, data, by=plot_spec.aggregation_level)
    
    elif plot_spec.resolution == "monthly":
        if plot_spec.quantity is None:
            raise ValueError("Monthly plotting requires a quantity to be specified")
        
        quantity = plot_spec.quantity.value
        
        # Handle percent difference by computing it first
        if plot_spec.quantity_type == QuantityType.percent_difference:
            # Filter columns based on quantity
            quantity_cols = [
                col for col in data.columns
                if quantity in col and col not in {plot_spec.aggregation_level, "month"}
            ]
            
            # Compute percent difference
            data, pct_cols = _compute_monthly_percent_diff(data, quantity_cols)
            
            # Create a temporary dataframe with only percent columns for plotting
            keep_cols = [plot_spec.aggregation_level, "month"] + pct_cols
            plot_data = data.select(keep_cols)
            
            # Rename percent columns to remove _pct suffix for plotting
            rename_map = {col: col.replace("_pct", "") for col in pct_cols}
            plot_data = plot_data.rename(rename_map)
            
            return plot_monthly_sales(
                plot_data,
                by=plot_spec.aggregation_level,
                quantity=quantity,
                title=f"Monthly {quantity} % Difference by {plot_spec.aggregation_level.title()}",
                y_label="kWh",
                use_shared_axis=True,
            )
        else:
            # Stock energy case
            return plot_monthly_sales(
                data,
                by=plot_spec.aggregation_level,
                quantity=quantity,
                title=f"Monthly {quantity} by {plot_spec.aggregation_level.title()}",
                y_label="kWh",
                use_shared_axis=True,
            )

    qty = plot_spec.quantity.value if plot_spec.quantity else "all"
    raise NotImplementedError(
        f"RECS plot for resolution='{plot_spec.resolution}', "
        f"quantity_type='{plot_spec.quantity_type.value}', and quantity='{qty}' is not supported"
    )
