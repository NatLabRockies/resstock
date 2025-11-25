import plotly.graph_objects as go
import polars as pl

from resstockpostproc.baseline_validation.theme import apply_theme

# ---------------------------------------------------------------------------
# constants
# ---------------------------------------------------------------------------
MONTH_ROWS = 5
MONTH_COLS = 11
MONTH_MAX = MONTH_ROWS * MONTH_COLS


def _add_bar_plot(
    fig: go.Figure,
    df: pl.DataFrame,
    category_column: str,
    quantity_columns: list[str],
    column_labels: list[str],
    column_colors: list[str],
    row: int,
    col: int,
    showlegend: bool,
    x_unit: str = "kWh",
) -> None:
    """
    Adds a generic bar chart panel to the figure.
    
    Args:
        fig: Plotly figure object
        df: DataFrame containing the data
        categories: Column name for categories (shown on y-axis)
        quantity_columns: List of column names to plot
        column_labels: List of labels for each column
        column_colors: List of colors for each column
        row: Subplot row position
        col: Subplot column position
        showlegend: Whether to show legend for this panel
        x_unit: Unit label for x-axis (default: "kWh")
    """
    categories_list = df[category_column].to_list()
    
    # Plot columns in reverse order to match legend order
    for i, col_name in enumerate(reversed(quantity_columns)):
        if col_name not in df.columns:
            continue
        
        idx = len(quantity_columns) - 1 - i
        label = column_labels[idx]
        color = column_colors[idx]
        
        # Use positive legendrank for comparison data (BuildStock), negative for reference (EIA)
        # This assumes reference data is passed first in the lists
        legendrank = idx - len(quantity_columns) // 2
        
        fig.add_bar(
            x=df[col_name].to_list(),
            y=categories_list,
            orientation="h",
            name=label,
            legendgroup=label,
            legendrank=legendrank,
            marker={"color": color},
            hovertemplate="%{y}<br>" + f"{label}: " + "%{x:,.0f} " + x_unit + "<extra></extra>",
            showlegend=showlegend,
            row=row,
            col=col,
        )


def _add_monthly_line_chart(
    fig: go.Figure,
    df: pl.DataFrame,
    group_by: str,
    quantity_columns: list[str],
    column_labels: list[str],
    column_colors: list[str],
    row: int,
    col: int,
    showlegend: bool,
    y_unit: str = "kWh",
) -> None:
    """
    Adds a generic monthly line chart to the figure.
    
    Args:
        fig: Plotly figure object
        df: DataFrame containing the data (should be pre-filtered for a single entity)
        group_by: Column name for x-axis grouping (typically month labels)
        quantity_columns: List of column names to plot
        column_labels: List of labels for each column
        column_colors: List of colors for each column
        row: Subplot row position
        col: Subplot column position
        showlegend: Whether to show legend for this panel
        y_unit: Unit label for y-axis (default: "kWh")
    """
    x_values = df[group_by].to_list()
    
    for i, col_name in enumerate(quantity_columns):
        if col_name not in df.columns:
            continue
        
        label = column_labels[i]
        color = column_colors[i]
        
        # Use positive legendrank for comparison data, negative for reference
        legendrank = i - len(quantity_columns) // 2
        
        fig.add_scatter(
            x=x_values,
            y=df[col_name].to_list(),
            mode="lines+markers",
            name=label,
            legendgroup=label,
            legendrank=legendrank,
            marker={"color": color, "size": 3},
            line={"color": color, "width": 1.5},
            hovertemplate="%{x}<br>" + f"{label}: " + "%{y:,.0f} " + y_unit + "<extra></extra>",
            showlegend=showlegend,
            row=row,
            col=col,
        )


def percent_axis_range(min_v: float | None, max_v: float | None) -> list[float] | None:
    """
    Calculate appropriate axis range for percent difference plots.
    
    Args:
        min_v: Minimum value in the data
        max_v: Maximum value in the data
    
    Returns:
        List with [min, max] range or None if no valid values
    """
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


def finalize_annual_plot(
    fig: go.Figure,
    left_title: str,
    right_title: str,
    title: str,
    left_range: list[float] | None = None,
    right_range: list[float] | None = None,
    categories: list[str] | None = None,
) -> go.Figure:
    """
    Finalize layout for annual comparison plots with two panels.
    
    Args:
        fig: Plotly figure object
        left_title: X-axis title for left panel
        right_title: X-axis title for right panel
        title: Overall plot title
        left_range: Optional x-axis range for left panel
        right_range: Optional x-axis range for right panel
        categories: Optional list to enforce y-axis category order
    
    Returns:
        Finalized figure with theme applied
    """
    fig.update_layout(
        barmode="group",
    )
    fig.update_xaxes(title_text=left_title, row=1, col=1)
    if left_range:
        fig.update_xaxes(range=left_range, row=1, col=1)

    fig.update_yaxes(automargin=True, ticklabelposition="outside", row=1, col=1)

    fig.update_xaxes(title_text=right_title, row=1, col=2)
    if right_range:
        fig.update_xaxes(range=right_range, row=1, col=2)

    fig.update_yaxes(automargin=True, ticklabelposition="outside", row=1, col=2)

    fig = apply_theme(
        fig,
        title=title,
        height=820,
        width=650,
        margin={"l": 140, "r": 80, "t": 80, "b": 60},
    )

    if categories:
        fig.update_yaxes(
            categoryorder="array",
            categoryarray=categories,
            tickmode="array",
            tickvals=categories,
            ticktext=categories,
            automargin=True,
            row=1,
            col=1,
        )
        fig.update_yaxes(
            categoryorder="array",
            categoryarray=categories,
            tickmode="array",
            tickvals=categories,
            ticktext=categories,
            automargin=True,
            row=1,
            col=2,
        )

    return fig
