"""
Timeseries Plotter
-----------------
Functions for generating timeseries validation plots
"""

import polars as pl
import plotly.graph_objects as go
from plotly.subplots import make_subplots

from resstockpostproc.baseline_validation.theme import apply_theme, BUILDSTOCK_COLOR, REFERENCE_COLOR
from resstockpostproc.baseline_validation.utils import ELEC_CAT2ENDUSES, NUM2MONTH, CAT2COLOR


def plot_timeseries_comparison(
    buildstock_ts: pl.DataFrame,
    reference_ts: pl.DataFrame | None = None,
    value_col: str = "fuel_use__electricity__total__kwh",
    time_col: str = "time",
    title: str | None = None,
    ylabel: str | None = None,
) -> go.Figure:
    """
    Create timeseries comparison plot.

    Args:
        buildstock_ts: BuildStock timeseries data
        reference_ts: Optional reference timeseries data
        value_col: Column to plot
        time_col: Time column name
        title: Plot title
        ylabel: Y-axis label

    Returns:
        Plotly figure
    """
    fig = go.Figure()

    # Add BuildStock line
    fig.add_trace(
        go.Scatter(
            x=buildstock_ts[time_col].to_list(),
            y=buildstock_ts[value_col].to_list(),
            mode="lines",
            name="BuildStock",
            line=dict(color=BUILDSTOCK_COLOR, width=2),
        )
    )

    # Add reference line if provided
    if reference_ts is not None and value_col in reference_ts.columns:
        fig.add_trace(
            go.Scatter(
                x=reference_ts[time_col].to_list(),
                y=reference_ts[value_col].to_list(),
                mode="lines",
                name="Reference",
                line=dict(color=REFERENCE_COLOR, width=2, dash="dash"),
            )
        )

    # Apply theme
    title = title or f"Timeseries: {value_col}"
    ylabel = ylabel or value_col.replace("_", " ").title()
    fig = apply_theme(fig, title=title, xaxis_title="Time", yaxis_title=ylabel)

    return fig


def plot_stacked_enduse_timeseries(
    buildstock_ts: pl.DataFrame,
    enduse_cols: list[str] | None = None,
    time_col: str = "time",
    title: str | None = None,
) -> go.Figure:
    """
    Create stacked area plot of end uses over time.

    Args:
        buildstock_ts: BuildStock timeseries data with end use columns
        enduse_cols: List of end use columns to stack
        time_col: Time column name
        title: Plot title

    Returns:
        Plotly figure
    """
    if enduse_cols is None:
        enduse_cols = ELEC_CAT2ENDUSES.get("all", [])
        # Filter to columns that exist in the data
        enduse_cols = [col for col in enduse_cols if col in buildstock_ts.columns]

    fig = go.Figure()

    # Add stacked areas for each end use
    for enduse in enduse_cols:
        # Get category for color
        category = None
        for cat, cols in ELEC_CAT2ENDUSES.items():
            if enduse in cols:
                category = cat
                break

        color = CAT2COLOR.get(category, "#4A4D4A") if category else "#4A4D4A"

        fig.add_trace(
            go.Scatter(
                x=buildstock_ts[time_col].to_list(),
                y=buildstock_ts[enduse].to_list(),
                mode="lines",
                name=enduse.replace("end_use__electricity__", "").replace("__kwh", "").replace("_", " ").title(),
                stackgroup="one",
                fillcolor=color,
                line=dict(width=0.5, color=color),
            )
        )

    # Apply theme
    title = title or "End Use Electricity Consumption Over Time"
    fig = apply_theme(fig, title=title, xaxis_title="Time", yaxis_title="kWh")

    return fig


def plot_hourly_profiles(
    buildstock_ts: pl.DataFrame,
    value_col: str = "fuel_use__electricity__total__kwh",
    time_col: str = "time",
    by_month: bool = True,
) -> go.Figure:
    """
    Create hourly load profile plot (average by hour of day).

    Args:
        buildstock_ts: BuildStock hourly timeseries data
        value_col: Column to average
        time_col: Time column name
        by_month: Whether to create separate profiles by month

    Returns:
        Plotly figure
    """
    # Extract hour and optionally month
    df = buildstock_ts.with_columns(
        pl.col(time_col).dt.hour().alias("hour"),
    )

    if by_month:
        df = df.with_columns(pl.col(time_col).dt.month().replace(NUM2MONTH).alias("month"))

        # Calculate average by hour and month
        hourly_avg = df.group_by(["hour", "month"]).agg(pl.col(value_col).mean().alias("avg_value"))

        # Create subplot for each month
        months = sorted(hourly_avg["month"].unique().to_list(), key=lambda x: list(NUM2MONTH.values()).index(x))

        fig = make_subplots(
            rows=3,
            cols=4,
            subplot_titles=months,
            vertical_spacing=0.08,
            horizontal_spacing=0.06,
        )

        for idx, month in enumerate(months):
            row = idx // 4 + 1
            col = idx % 4 + 1

            month_data = hourly_avg.filter(pl.col("month") == month).sort("hour")

            fig.add_trace(
                go.Scatter(
                    x=month_data["hour"].to_list(),
                    y=month_data["avg_value"].to_list(),
                    mode="lines+markers",
                    name=month,
                    showlegend=False,
                    line=dict(color=BUILDSTOCK_COLOR, width=2),
                ),
                row=row,
                col=col,
            )

        # Update axes
        for row in range(1, 4):
            for col in range(1, 5):
                fig.update_xaxes(title_text="Hour of Day" if row == 3 else "", row=row, col=col)
                fig.update_yaxes(title_text="kWh" if col == 1 else "", row=row, col=col)

        fig = apply_theme(fig, title="Hourly Load Profiles by Month", height=800, width=1200)

    else:
        # Calculate average by hour (all months combined)
        hourly_avg = df.group_by("hour").agg(pl.col(value_col).mean().alias("avg_value")).sort("hour")

        fig = go.Figure()

        fig.add_trace(
            go.Scatter(
                x=hourly_avg["hour"].to_list(),
                y=hourly_avg["avg_value"].to_list(),
                mode="lines+markers",
                line=dict(color=BUILDSTOCK_COLOR, width=2),
                marker=dict(size=8),
            )
        )

        fig = apply_theme(
            fig,
            title="Average Hourly Load Profile",
            xaxis_title="Hour of Day",
            yaxis_title="kWh",
        )

    return fig


def plot_daily_aggregate(
    buildstock_ts: pl.DataFrame,
    reference_ts: pl.DataFrame | None = None,
    value_col: str = "fuel_use__electricity__total__kwh",
    time_col: str = "time",
    title: str | None = None,
) -> go.Figure:
    """
    Create daily aggregate timeseries plot.

    Args:
        buildstock_ts: BuildStock hourly timeseries data
        reference_ts: Optional reference hourly data
        value_col: Column to aggregate
        time_col: Time column name
        title: Plot title

    Returns:
        Plotly figure
    """
    # Aggregate to daily
    buildstock_daily = buildstock_ts.group_by(pl.col(time_col).dt.date().alias("date")).agg(
        pl.col(value_col).sum().alias("daily_value")
    )

    fig = go.Figure()

    # Add BuildStock daily line
    fig.add_trace(
        go.Scatter(
            x=buildstock_daily["date"].to_list(),
            y=buildstock_daily["daily_value"].to_list(),
            mode="lines",
            name="BuildStock (Daily)",
            line=dict(color=BUILDSTOCK_COLOR, width=1.5),
        )
    )

    # Add reference daily line if provided
    if reference_ts is not None:
        reference_daily = reference_ts.group_by(pl.col(time_col).dt.date().alias("date")).agg(
            pl.col(value_col).sum().alias("daily_value")
        )

        fig.add_trace(
            go.Scatter(
                x=reference_daily["date"].to_list(),
                y=reference_daily["daily_value"].to_list(),
                mode="lines",
                name="Reference (Daily)",
                line=dict(color=REFERENCE_COLOR, width=1.5, dash="dash"),
            )
        )

    # Apply theme
    title = title or f"Daily {value_col.replace('_', ' ').title()}"
    fig = apply_theme(fig, title=title, xaxis_title="Date", yaxis_title="kWh/day")

    return fig
