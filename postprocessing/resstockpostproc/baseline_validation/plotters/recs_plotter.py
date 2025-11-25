import calendar
from typing import Any

import polars as pl
import plotly.graph_objects as go
from plotly.subplots import make_subplots

from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    AggregationType,
    ViewType,
)
from resstockpostproc.baseline_validation.schema.recs_enduse_mapping import RECS_ENDUSE_MAP
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


# ---------------------------------------------------------------------------
# annual plot helpers
# ---------------------------------------------------------------------------
def _add_annual_bar_with_rse(
    fig: go.Figure,
    df: pl.DataFrame,
    x_col: str,
    value_col: str,
    rse_col: str,
    label: str,
    color: str,
    row: int,
    col: int,
    showlegend: bool,
    y_unit: str = "kWh",
) -> None:
    """
    Add a bar plot using RSE (Relative Standard Error) to show uncertainty as error bars.
    
    Args:
        fig: Plotly figure object
        df: DataFrame containing the data (should have single annual value per entity)
        x_col: Column name for x-axis (the entity/state)
        value_col: Column name for the value
        rse_col: Column name for RSE (as a percentage)
        label: Label for the bar trace
        color: Color for the bar
        row: Subplot row position
        col: Subplot column position
        showlegend: Whether to show legend
        y_unit: Unit label for y-axis
    """
    # For annual data, we expect one row per entity (state)
    # The x is the entity name, y value is the single annual value
    x_value = df[x_col].to_list()[0] if len(df) > 0 else None
    y_value = df[value_col].to_list()[0] if len(df) > 0 else None
    rse_value = df[rse_col].to_list()[0] if rse_col in df.columns and len(df) > 0 else 0
    
    if x_value is None or y_value is None:
        return
    
    # Calculate error bar using RSE
    # RSE is relative standard error as a percentage
    # For 95% confidence interval, multiply by 1.96
    if rse_value is not None and rse_value > 0:
        error_value = y_value * (rse_value / 100.0) * 1.96
    else:
        error_value = 0
    
    # Add the bar with error bar
    fig.add_bar(
        x=[x_value],
        y=[y_value],
        name=label,
        legendgroup=label,
        marker={"color": color},
        error_y={
            "type": "data",
            "array": [error_value],
            "visible": True,
            "color": "black",
            "thickness": 1.5,
            "width": 4,
        },
        hovertemplate="%{x}<br>" + f"{label}: " + "%{y:,.0f} " + y_unit + "<br>RSE: " + f"{rse_value:.1f}%<extra></extra>",
        showlegend=showlegend,
        row=row,
        col=col,
    )


def _add_annual_box_with_quartiles(
    fig: go.Figure,
    df: pl.DataFrame,
    x_col: str,
    quartiles_col: str,
    label: str,
    color: str,
    row: int,
    col: int,
    showlegend: bool,
    y_unit: str = "kWh",
    mean_col: str = None,
) -> None:
    """
    Add a box plot using pre-calculated quartiles.
    
    Args:
        fig: Plotly figure object
        df: DataFrame containing the data (should have single annual value per entity)
        x_col: Column name for x-axis (the entity/state) - not used, kept for signature compatibility
        quartiles_col: Column name for the quartiles column (string array format)
        label: Label for the box trace
        color: Color for the box
        row: Subplot row position
        col: Subplot column position
        showlegend: Whether to show legend
        y_unit: Unit label for y-axis
        mean_col: Optional column name for the mean value
    """
    # For annual data, we expect one row per entity (state)
    quartiles_str = df[quartiles_col].to_list()[0] if quartiles_col in df.columns and len(df) > 0 else None
    
    if quartiles_str is None:
        return
    
    # Parse quartiles string: '[0.0, 0.0, 0.0, 7.02, 81.77, 81.77, 97.34, 109.02, 109.02]'
    try:
        import ast
        quartiles = ast.literal_eval(quartiles_str)
        if len(quartiles) != 9:
            return
        
        # Quartiles represent: [0, 0.02, 0.1, 0.25, 0.5, 0.75, 0.9, 0.98, 1]
        min_val, q02, q10, q25, median, q75, q90, q98, max_val = quartiles
        min_val = q02
        # max_val = q98
        
        # Get mean value if available
        mean_val = None
        if mean_col and mean_col in df.columns:
            mean_val = df[mean_col].to_list()[0] if len(df) > 0 else None
        
        # Add box plot using custom box specifications
        # Use label as x value so boxes are grouped properly but span the subplot
        fig.add_box(
            x=[label],
            q1=[q25],
            median=[median],
            q3=[q75],
            lowerfence=[min_val],
            upperfence=[max_val],
            name=label,
            legendgroup=label,
            marker={"color": color},
            line={"color": color},
            fillcolor=color,
            width=0.6,  # Make boxes wider to fill more space
            hovertemplate=(
                f"{label}<br>"
                f"Min: %{{lowerfence:,.1f}} {y_unit}<br>"
                f"Q1: %{{q1:,.1f}} {y_unit}<br>"
                f"Median: %{{median:,.1f}} {y_unit}<br>"
                f"Mean: {mean_val:,.1f} {y_unit}<br>" if mean_val is not None else "" +
                f"Q3: %{{q3:,.1f}} {y_unit}<br>"
                f"Max: %{{upperfence:,.1f}} {y_unit}<extra></extra>"
            ),
            showlegend=showlegend,
            row=row,
            col=col,
        )
        
        # Add scatter point for mean if available
        if mean_val is not None:
            fig.add_scatter(
                x=[label],
                y=[mean_val],
                mode="markers",
                marker=dict(
                    symbol="diamond",
                    size=3,
                    color="yellow",
                ),
                name="Mean",
                legendgroup="mean_marker",
                showlegend=False,
                hovertemplate=f"{label}<br>Mean: {mean_val:,.1f} {y_unit}<extra></extra>",
                row=row,
                col=col,
            )
        
        # Add scatter point for median (to make it more visible)
        fig.add_scatter(
            x=[label],
            y=[median],
            mode="markers",
            marker=dict(
                symbol="line-ew",
                size=12,
                color=color,
                line=dict(color="white", width=1),
            ),
            name="Median",
            legendgroup="median_marker",
            showlegend=False,
            hovertemplate=f"{label}<br>Median: {median:,.1f} {y_unit}<extra></extra>",
            row=row,
            col=col,
        )
    except Exception as e:
        # If parsing fails, skip this box plot
        print(f"Failed to parse quartiles for {label}: {e}")
        return


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


# ---------------------------------------------------------------------------
# monthly plot helpers
# ---------------------------------------------------------------------------
CENSUS_LAYOUT = [
    ["Pacific", "Mountain North", "West North Central", "East North Central", "Middle Atlantic", "New England"],
    [None, "Mountain South", "West South Central", "East South Central", "South Atlantic", None],
    [None, None, "US Total", None, None, None],
    [None, None, None, None, None, None],
]
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
    ["AK", "HI", None, "TX", None, "US Total", None, "FL", None, None, None],
    [None, None, None, None, None, None, None, None, None, None, None],  # Extra row for US Total to grow downward
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
    resstock_cols = [col for col in quantity_cols if col.startswith("resstock_") and col.endswith("_value")]
    
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
    
    # Add the center line first (for legend order)
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
    
    # Add the RSE band (filled area between upper and lower bounds)
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
    
    # Add filled area from x-axis to lower bound (more opaque than RSE band)
    fig.add_scatter(
        x=x_values + x_values[::-1],
        y=lower_bounds + [0] * len(lower_bounds),
        fill="toself",
        fillcolor=color,
        opacity=0.5,
        line={"color": "rgba(255,255,255,0)"},
        showlegend=showlegend,
        name="RECS 2020 (95% CI lower bound)",
        legendgroup="RECS_lower_bound",
        hoverinfo="skip",
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
    suffix: str = "_value",
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
        suffix: Column suffix to use (e.g., '_value' or '_customers')
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
        if quantity in col and col.endswith(suffix)
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
        rse_col = col.replace(suffix, "_rse")
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
    
    # Calculate max for axis ranges
    padding = 1.25
    df = data.with_columns(
        pl.max_horizontal(pl.col(upper_bound_cols + resstock_cols)).alias("_entity_max")
    )
    # For shared range, exclude US Total
    global_max = df.filter(pl.col(by) != "US Total")["_entity_max"].max()
    shared_range = [0, global_max * padding] if isinstance(global_max, (int, float)) else None
    
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
        shared_yaxes=False,  # Don't share y-axes so US Total can be independent
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
            showgrid=False,
            row=row + 1,
            col=col + 1,
        )
        # Calculate per-entity range using monthly max
        entity_max = entity_df["_entity_max"].max()
        per_range = [0, entity_max * padding] if isinstance(entity_max, (int, float)) else None
        
        # Show y-axis label for first non-None plot in each row (always)
        is_first_in_row = col == 0 or (col > 0 and GEOGRAPHIC_STATE_LAYOUT[row][col - 1] is None)
        
        # US Total always uses its own scale and shows ticks
        is_us_total = (entity == "US Total")
        
        # Show ticklabels based on use_shared_axis
        # If use_shared_axis is False, show ticks on all subplots
        # If use_shared_axis is True, show ticks only on first in row or after empty subplot
        # US Total always shows ticks
        show_ticks = is_us_total or not use_shared_axis or is_first_in_row
        
        fig.update_yaxes(
            title_text="kWh" if is_first_in_row or is_us_total else "",
            title_font={"size": 12},
            range=(per_range if is_us_total else (shared_range if use_shared_axis else per_range)),
            tickfont={"size": 12},
            automargin=True,
            showticklabels=show_ticks,
            showgrid=False,
            showline=show_ticks,
            row=row + 1,
            col=col + 1,
        )
        
        # Make US Total subplot 1.5x larger (both width and height) by adjusting domain
        if is_us_total:
            # Get the current domain for this subplot
            axis_num = row * GRID_COLS + col + 1
            xaxis_key = f"xaxis{axis_num}" if axis_num > 1 else "xaxis"
            yaxis_key = f"yaxis{axis_num}" if axis_num > 1 else "yaxis"
            
            # Get current domain
            x_domain = fig.layout[xaxis_key].domain
            y_domain = fig.layout[yaxis_key].domain
            
            # Calculate center and new width (1.5x)
            x_center = (x_domain[0] + x_domain[1]) / 2
            x_width = (x_domain[1] - x_domain[0]) * 1.5
            
            # For height, grow downward - keep top fixed, extend bottom
            y_top = y_domain[1]
            y_height = (y_domain[1] - y_domain[0]) * 1.8
            y_bottom = y_top - y_height
            
            # Set new domain (allow extending beyond current row)
            fig.update_xaxes(
                domain=[max(0, x_center - x_width / 2), min(1, x_center + x_width / 2)],
                row=row + 1,
                col=col + 1,
            )
            fig.update_yaxes(
                domain=[y_bottom, y_top],  # Don't constrain with max(0, ...) to allow full extension
                row=row + 1,
                col=col + 1,
            )
            
            # Add border around US Total subplot
            fig.add_shape(
                type="rect",
                xref="paper",
                yref="paper",
                x0=max(0, x_center - x_width / 2),
                y0=y_bottom,
                x1=min(1, x_center + x_width / 2),
                y1=y_top,
                line=dict(color="black", width=2),
                layer="below",
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

    fig.update_layout(
        showlegend=True,
        xaxis=dict(showgrid=False),
        yaxis=dict(showgrid=False),
    )

    fig = apply_theme(
        fig,
        title=f"{title}<br>(Boats Plot)",
        height=1080 * 0.8,
        width=1920 * 0.7,
        font={"size": 14},
        legend={
            "orientation": "v",
            "x": 0.99,
            "y": 0.11,
            "xanchor": "right",
            "yanchor": "bottom",
            "font": {"size": 14},
            "bgcolor": "rgba(255, 255, 255, 0.8)",
        },
        margin={"l": 60, "r": 60, "t": 100, "b": 60},
    )
    return fig


def plot_all_enduses(
    data: pl.DataFrame,
    by: str,  # noqa: ARG001 - kept for consistency, currently aggregates across all values
    title: str,
    suffix: str = "_value",  # noqa: ARG001 - not used with new format but kept for compatibility
) -> go.Figure:
    """
    Create horizontal grouped bar plots organized by fuel source categories.
    Shows: Fuel Totals, Electricity End uses, Natural Gas End uses, Propane End uses, Fuel Oil End uses.
    Each subplot shows bars for each end-use within that category, grouped by state.
    
    Args:
        data: DataFrame with standardized tall format (source, quantity_type, quantity, value columns)
        by: Grouping column (e.g., 'state')
        title: Plot title
        suffix: Column suffix (unused in new format but kept for compatibility)
    """
    # Categorize end-uses by fuel source

    enduse_groups_2_position = {
        "Fuel Totals": (1, 1),
        "Natural Gas End uses": (2, 1),
        "Propane End uses": (2, 2),
        "Fuel Oil End uses": (3, 1),
        "Electricity End uses": (1, 2),
    }
    
    def _filter_quantitities(df: pl.DataFrame, quantity_group: str) -> pl.DataFrame:
        match quantity_group:
            case "Fuel Totals":
                return df.filter(pl.col("quantity").str.ends_with("_total"))
            case "Electricity End uses":
                return df.filter(
                    pl.col("quantity").str.starts_with("electricity_") & ~pl.col("quantity").str.ends_with("_total")
                )
            case "Natural Gas End uses":
                return df.filter(
                    pl.col("quantity").str.starts_with("natural_gas_") & ~pl.col("quantity").str.ends_with("_total")
                )
            case "Propane End uses":
                return df.filter(
                    pl.col("quantity").str.starts_with("propane_") & ~pl.col("quantity").str.ends_with("_total")
                )
            case "Fuel Oil End uses":
                return df.filter(
                    pl.col("quantity").str.starts_with("fuel_oil_") & ~pl.col("quantity").str.ends_with("_total")
                )
            case _:
                return df.filter(pl.lit(False))

    left_enduse_counts = [len(_filter_quantitities(data, group)) for group, position in enduse_groups_2_position.items()
                          if position[0] == 1]

    total_left_enduses = sum(left_enduse_counts)
    row_heights = [count / total_left_enduses if total_left_enduses > 0 else 0.25 for count in left_enduse_counts]
    
    specs = []
    for i in range(4):
        if i == 0:
            specs.append([{"type": "bar"}, {"type": "bar", "rowspan": 4}])
        else:
            specs.append([{"type": "bar"}, None])
    
    subplot_titles = list(enduse_groups_2_position.keys())
    
    fig = make_subplots(
        rows=4,
        cols=2,
        subplot_titles=subplot_titles,
        specs=specs,
        column_widths=[0.25, 0.75],  # Left narrower, right wider
        row_heights=row_heights,  # Proportional to number of end-uses
        horizontal_spacing=0.15,
        vertical_spacing=0.05,  # Reduced spacing between rows
        shared_yaxes=False,
    )
    
    # Get unique sources and create color mapping
    unique_sources = value_data["source"].unique(maintain_order=True).to_list()
    source_colors = {}
    source_labels = {}
    
    for i, source in enumerate(unique_sources):
        if source == "recs_2020":
            source_colors[source] = RECS_COLORS[0]
            source_labels[source] = "RECS 2020"
        else:
            # ResStock sources
            source_colors[source] = _RUN_PALETTE[i % len(_RUN_PALETTE)]
            # Convert source name like "resstock_2025" to "ResStock 2025"
            if source.startswith("resstock_"):
                label = source.replace("resstock_", "ResStock ")
            else:
                label = source
            source_labels[source] = label
    
    legend_shown = set()
    
    # Process left column categories
    for row_idx, (category_name, enduses) in enumerate(categories, start=1):
        if not enduses:
            continue
            
        # Filter data for this category's enduses
        category_data = value_data.filter(pl.col("quantity").is_in(enduses))
        
        if category_data.is_empty():
            continue
        
        # Aggregate by enduse and source across all states
        aggregated = category_data.group_by(["quantity", "source"]).agg(
            pl.col("value").cast(pl.Float64).sum().alias("total_value")
        )
        
        # Pivot to get sources as columns
        pivoted = aggregated.pivot(
            index="quantity", 
            columns="source", 
            values="total_value"
        ).fill_null(0)
        
        # Prepare columns for plotting
        plot_cols = []
        plot_labels = []
        plot_colors = []
        
        for source in unique_sources:
            if source in pivoted.columns:
                plot_cols.append(source)
                plot_labels.append(source_labels[source])
                plot_colors.append(source_colors[source])
        
        # Only show legend for first subplot
        show_legend = row_idx == 1 and len(legend_shown) == 0
        if show_legend:
            legend_shown.update(plot_labels)
        
        # Use base_plotter function
        base_plotter._add_bar_plot(
            fig=fig, df=pivoted, categories_list="quantity", quantity_columns=plot_cols,
            column_labels=plot_labels, column_colors=plot_colors,
            row=row_idx, col=1, showlegend=show_legend, 
        )
    
    # Update axes for all left column subplots
    for row_idx in range(1, 5):
        fig.update_xaxes(title_text="kWh", showgrid=True, row=row_idx, col=1)
        fig.update_yaxes(showticklabels=True, categoryorder="total ascending", row=row_idx, col=1)
    
    # Update axes for right column (large subplot)
    fig.update_xaxes(title_text="kWh", showgrid=True, row=1, col=2)
    fig.update_yaxes(showticklabels=True, categoryorder="total ascending", row=1, col=2)
    
    fig.update_layout(
        barmode="group",
        showlegend=True,
    )
    
    fig = apply_theme(
        fig,
        title=title,
        height=1080 * 0.8,
        width=1920 * 0.7,
        font={"size": 11},
        legend={
            "orientation": "h",
            "x": 0.5,
            "y": -0.02,
            "xanchor": "center",
            "yanchor": "top",
            "font": {"size": 12},
        },
        margin={"l": 200, "r": 40, "t": 80, "b": 60},
    )
    
    return fig


def plot_annual_sales(
    data: pl.DataFrame,
    by: str,
    quantity: str,
    title: str,
    y_label: str,
    use_shared_axis: bool = True,
    suffix: str = "_value",
    quantity_type: AggregationType = AggregationType.stock_total,
) -> go.Figure:
    """
    Generic annual sales plotting function with geographic layout and size-proportional subplots.
    Uses bar charts with one value per state (or box plots for distributions), and error bars for RECS RSE.
    
    Args:
        data: DataFrame with all columns (both reference and resstock)
        by: Grouping column (e.g., 'state')
        quantity: Quantity to plot (e.g., 'electricity', 'natural_gas')
        title: Plot title
        y_label: Y-axis label
        use_shared_axis: Whether to use shared y-axis scaling
        suffix: Column suffix to use (e.g., '_value', '_customers', or '_quartiles')
        quantity_type: Type of quantity being plotted
    """
    is_box_plot = (quantity_type == AggregationType.per_unit_distribution)
    
    # Filter columns based on quantity
    quantity_cols = [
        col for col in data.columns
        if quantity in col and col.endswith(suffix)
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
    for col in ref_cols:
        rse_col = col.replace(suffix, "_rse")
        if rse_col in data.columns:
            ref_cols_with_rse.append(col)
            ref_rse_cols.append(rse_col)
            ref_labels.append("RECS 2020 (estimate)")
        else:
            ref_cols_with_rse.append(col)
            ref_rse_cols.append(None)
            ref_labels.append("RECS 2020")
    
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
    
    # Compute axis ranges - account for RSE error bars or quartiles
    if is_box_plot:
        # For box plots, parse quartiles to get max values
        max_vals = []
        for col in quantity_cols:
            # Parse the quartiles string to get the max value (last element)
            try:
                import ast
                quartile_vals = data[col].map_elements(lambda x: ast.literal_eval(x)[-1] if x else 0, return_dtype=pl.Float64)
                max_vals.append(quartile_vals.alias(f"{col}_max"))
            except Exception:
                pass
        if max_vals:
            df = data.with_columns(max_vals)
            df = df.with_columns(
                pl.max_horizontal([pl.col(f"{col}_max") for col in quantity_cols]).alias("_entity_max")
            )
        else:
            df = data.with_columns(pl.lit(100.0).alias("_entity_max"))
    else:
        # Calculate upper bounds for RECS columns with RSE (without 1.96 multiplier, that's applied in _add_annual_bar_with_rse)
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
        
        # Compute max including upper bounds of error bars (exclude US Total)
        df = data.with_columns(
            pl.max_horizontal(pl.col(quantity_cols)).alias("_entity_max")
        )
    global_max = df.filter(pl.col(by) != "US Total")["_entity_max"].max()
    shared_range = [0, global_max * 1.25] if isinstance(global_max, (int, float)) else None
    
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
        shared_yaxes=False,  # Don't share y-axes so US Total can be independent
        horizontal_spacing=0.02,
        vertical_spacing=0.1,
    )

    # Add traces for each state
    for entity in entities:
        if entity not in state_positions:
            continue
            
        row, col = state_positions[entity]
        entity_df = df.filter(pl.col(by) == entity)
        
        if entity_df.is_empty():
            continue
        
        # Choose between bar plots and box plots based on quantity type
        if is_box_plot:
            # Add ResStock box plots first (so RECS appears last in legend)
            for i, col_name in enumerate(resstock_cols):
                mean_col_name = col_name.replace("_quartiles", "_value")
                _add_annual_box_with_quartiles(
                    fig, entity_df, by, col_name,
                    resstock_labels[i], resstock_colors[i],
                    row + 1, col + 1, (entity == entities[0]), y_label,
                    mean_col=mean_col_name
                )
            
            # Add RECS box plots last (so they appear last in legend)
            for i, value_col in enumerate(ref_cols_with_rse):
                mean_col_name = value_col.replace("_quartiles", "_value")
                _add_annual_box_with_quartiles(
                    fig, entity_df, by, value_col,
                    ref_labels[i], ref_colors[i],
                    row + 1, col + 1, (entity == entities[0]), y_label,
                    mean_col=mean_col_name
                )
        else:
            # Add ResStock bars first (so RECS appears last in legend)
            for i, col_name in enumerate(resstock_cols):
                x_value = entity_df[by].to_list()[0] if len(entity_df) > 0 else None
                y_value = entity_df[col_name].to_list()[0] if len(entity_df) > 0 else None
                if x_value is not None and y_value is not None:
                    fig.add_bar(
                        x=[x_value],
                        y=[y_value],
                        name=resstock_labels[i],
                        legendgroup=resstock_labels[i],
                        marker={"color": resstock_colors[i]},
                        hovertemplate="%{x}<br>" + f"{resstock_labels[i]}: " + "%{y:,.0f} kWh<extra></extra>",
                        showlegend=(entity == entities[0]),
                        row=row + 1,
                        col=col + 1,
                    )
            
            # Add RECS bars (with RSE error bars) last (so they appear last in legend)
            for i, (value_col, rse_col) in enumerate(zip(ref_cols_with_rse, ref_rse_cols)):
                if rse_col is not None and rse_col in entity_df.columns:
                    _add_annual_bar_with_rse(
                        fig, entity_df, by, value_col, rse_col,
                        ref_labels[i], ref_colors[i],
                        row + 1, col + 1, (entity == entities[0]), "kWh"
                    )
                else:
                    # If no RSE, plot as regular bar without error
                    x_value = entity_df[by].to_list()[0] if len(entity_df) > 0 else None
                    y_value = entity_df[value_col].to_list()[0] if len(entity_df) > 0 else None
                    if x_value is not None and y_value is not None:
                        fig.add_bar(
                            x=[x_value],
                            y=[y_value],
                            name=ref_labels[i],
                            legendgroup=ref_labels[i],
                            marker={"color": ref_colors[i]},
                            hovertemplate="%{x}<br>" + f"{ref_labels[i]}: " + "%{y:,.0f} kWh<extra></extra>",
                            showlegend=(entity == entities[0]),
                            row=row + 1,
                            col=col + 1,
                        )
        
        # Configure axes
        entity_max = entity_df["_entity_max"].max()
        per_range = [0, entity_max * 1.05] if isinstance(entity_max, (int, float)) else None
        
        # Show y-axis label for first non-None plot in each row
        is_first_in_row = col == 0 or (col > 0 and GEOGRAPHIC_STATE_LAYOUT[row][col - 1] is None)
        
        # US Total always uses its own scale and shows ticks
        is_us_total = (entity == "US Total")
        
        # Show ticklabels based on use_shared_axis
        # US Total always shows ticks
        show_ticks = is_us_total or not use_shared_axis or is_first_in_row
        
        fig.update_yaxes(
            title_text=y_label if is_first_in_row or is_us_total else "",
            title_font={"size": 12},
            range=(per_range if is_us_total else (shared_range if use_shared_axis else per_range)),
            tickfont={"size": 12},
            automargin=True,
            showticklabels=show_ticks,
            showgrid=False,
            showline=show_ticks,
            row=row + 1,
            col=col + 1,
        )
        
        # X-axis: hide the state name since it's in the subplot title
        fig.update_xaxes(
            showticklabels=False,
            tickfont={"size": 12},
            automargin=True,
            showgrid=False,
            row=row + 1,
            col=col + 1,
        )
        
        # Make US Total subplot 1.5x larger (both width and height) by adjusting domain
        if is_us_total:
            # Get the current domain for this subplot
            axis_num = row * GRID_COLS + col + 1
            xaxis_key = f"xaxis{axis_num}" if axis_num > 1 else "xaxis"
            yaxis_key = f"yaxis{axis_num}" if axis_num > 1 else "yaxis"
            
            # Get current domain
            x_domain = fig.layout[xaxis_key].domain
            y_domain = fig.layout[yaxis_key].domain
            
            # Calculate center and new width (1.5x)
            x_center = (x_domain[0] + x_domain[1]) / 2
            x_width = (x_domain[1] - x_domain[0]) * 1.5
            
            # For height, grow downward - keep top fixed, extend bottom
            y_top = y_domain[1]
            y_height = (y_domain[1] - y_domain[0]) * 1.8
            y_bottom = y_top - y_height
            
            # Set new domain (allow extending beyond current row)
            fig.update_xaxes(
                domain=[max(0, x_center - x_width / 2), min(1, x_center + x_width / 2)],
                row=row + 1,
                col=col + 1,
            )
            fig.update_yaxes(
                domain=[y_bottom, y_top],  # Don't constrain with max(0, ...) to allow full extension
                row=row + 1,
                col=col + 1,
            )
            
            # Add border around US Total subplot
            fig.add_shape(
                type="rect",
                xref="paper",
                yref="paper",
                x0=max(0, x_center - x_width / 2),
                y0=y_bottom,
                x1=min(1, x_center + x_width / 2),
                y1=y_top,
                line=dict(color="black", width=2),
                layer="below",
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

    layout_kwargs: dict[str, Any] = {"showlegend": True}
    if is_box_plot:
        layout_kwargs["boxmode"] = "group"
    else:
        layout_kwargs["barmode"] = "group"
    
    fig.update_layout(**layout_kwargs)

    # Add suffix to title for box plots
    if is_box_plot:
        title_with_suffix = f"{title}<br>(Ships Plot)"
    else:
        title_with_suffix = title
    
    fig = apply_theme(
        fig,
        title=title_with_suffix,
        height=1080 * 0.8,
        width=1920 * 0.7,
        font={"size": 14},
        legend={
            "orientation": "v",
            "x": 0.99,
            "y": 0.11,
            "xanchor": "right",
            "yanchor": "bottom",
            "font": {"size": 14},
            "bgcolor": "rgba(255, 255, 255, 0.8)",
        },
        margin={"l": 60, "r": 60, "t": 100, "b": 60},
    )
    return fig


def create_plot(data: pl.DataFrame, plot_spec: PlotSpec) -> go.Figure:
    # Determine suffix based on quantity_type
    if plot_spec.aggregation_type == AggregationType.percent_users:
        suffix = "_customers"
    elif plot_spec.aggregation_type == AggregationType.per_unit_distribution:
        suffix = "_quartiles"
    else:
        suffix = "_value"
    
    if plot_spec.resolution == "annual":
        if plot_spec.quantity is None:
            # Create horizontal grouped bar plot by fuel source
            return plot_all_enduses(
                data,
                by=plot_spec.aggregation_level,
                title=f"Annual Energy Consumption by Fuel Source and {plot_spec.aggregation_level.title()}",
                suffix=suffix,
            )
        
        quantity = plot_spec.quantity.value
        
        # Handle percent difference by computing it first
        if plot_spec.view == ViewType.diff_view:
            # Filter columns based on quantity
            quantity_cols = [
                col for col in data.columns
                if quantity in col and col not in {plot_spec.aggregation_level}
            ]
            
            # Compute percent difference (reuse monthly function, works for annual too)
            data, pct_cols = _compute_monthly_percent_diff(data, quantity_cols)
            
            # Create a temporary dataframe with only percent columns for plotting
            keep_cols = [plot_spec.aggregation_level] + pct_cols
            plot_data = data.select(keep_cols)
            
            # Rename percent columns to remove _pct suffix for plotting
            rename_map = {col: col.replace("_pct", "") for col in pct_cols}
            plot_data = plot_data.rename(rename_map)
            
            return plot_annual_sales(
                plot_data,
                by=plot_spec.aggregation_level,
                quantity=quantity,
                title=f"Annual {quantity} % Difference by {plot_spec.aggregation_level.title()}",
                y_label="% Difference",
                use_shared_axis=True,
                suffix=suffix,
            )
        else:
            # Stock energy, number of customers, or per unit energy distribution case
            if plot_spec.aggregation_type == AggregationType.percent_users:
                title = f"Annual {quantity} customers by {plot_spec.aggregation_level.title()}"
                y_label = "count"
            elif plot_spec.aggregation_type == AggregationType.per_unit_distribution:
                title = f"Annual {quantity} distribution by {plot_spec.aggregation_level.title()}"
                y_label = "kWh"
            elif plot_spec.aggregation_type == AggregationType.per_unit:
                title = f"Annual {quantity} per dwelling unit energy by {plot_spec.aggregation_level.title()}"
                y_label = "kWh/unit"
            else:
                title = f"Annual {quantity} by {plot_spec.aggregation_level.title()}"
                y_label = "kWh"
            
            return plot_annual_sales(
                data,
                by=plot_spec.aggregation_level,
                quantity=quantity,
                title=title,
                y_label=y_label,
                use_shared_axis=True,
                suffix=suffix,
                quantity_type=plot_spec.aggregation_type,
            )
    
    elif plot_spec.resolution == "monthly":
        if plot_spec.quantity is None:
            raise ValueError("Monthly plotting requires a quantity to be specified")
        
        quantity = plot_spec.quantity.value
        
        # Handle percent difference by computing it first
        if plot_spec.view == ViewType.diff_view:
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
                suffix=suffix,
            )
        else:
            # Stock energy or number of customers case
            if plot_spec.aggregation_type == AggregationType.percent_users:
                title = f"Monthly {quantity} customers by {plot_spec.aggregation_level.title()}"
                y_label = "count"
            elif plot_spec.aggregation_type == AggregationType.per_unit:
                title = f"Monthly {quantity} per dwelling unit energy by {plot_spec.aggregation_level.title()}"
                y_label = "kWh/unit"
            else:
                title = f"Monthly {quantity} by {plot_spec.aggregation_level.title()}"
                y_label = "kWh"
            
            return plot_monthly_sales(
                data,
                by=plot_spec.aggregation_level,
                quantity=quantity,
                title=title,
                y_label=y_label,
                use_shared_axis=True,
                suffix=suffix,
            )

    qty = plot_spec.quantity.value if plot_spec.quantity else "all"
    raise NotImplementedError(
        f"RECS plot for resolution='{plot_spec.resolution}', "
        f"quantity_type='{plot_spec.aggregation_type.value}', and quantity='{qty}' is not supported"
    )
