"""
Load Duration Curve Plotter
---------------------------
Functions for generating load duration curve validation plots
"""

import polars as pl
import plotly.graph_objects as go

from resstockpostproc.baseline_validation.theme import apply_theme, BUILDSTOCK_COLOR, REFERENCE_COLOR


def calculate_load_duration_curve(
    timeseries_df: pl.DataFrame,
    value_col: str,
    group_col: str | None = None,
) -> pl.DataFrame:
    """
    Calculate load duration curve from timeseries data.

    Args:
        timeseries_df: Timeseries data
        value_col: Column containing values to sort
        group_col: Optional grouping column (e.g., 'eiaid', 'state')

    Returns:
        DataFrame with percentile and value columns
    """
    if group_col:
        # Calculate LDC for each group
        ldc_dfs = []
        for group in timeseries_df[group_col].unique().to_list():
            group_data = timeseries_df.filter(pl.col(group_col) == group)

            # Sort values in descending order
            sorted_data = group_data.select(value_col).sort(value_col, descending=True)

            # Calculate percentile
            n = sorted_data.height
            percentiles = [(i / n) * 100 for i in range(n)]

            ldc = pl.DataFrame(
                {
                    "percentile": percentiles,
                    value_col: sorted_data[value_col].to_list(),
                    group_col: [group] * n,
                }
            )
            ldc_dfs.append(ldc)

        return pl.concat(ldc_dfs)
    else:
        # Single LDC
        sorted_data = timeseries_df.select(value_col).sort(value_col, descending=True)
        n = sorted_data.height
        percentiles = [(i / n) * 100 for i in range(n)]

        return pl.DataFrame({"percentile": percentiles, value_col: sorted_data[value_col].to_list()})


def plot_load_duration_curve(
    buildstock_ldc: pl.DataFrame,
    reference_ldc: pl.DataFrame | None = None,
    value_col: str = "kwh_per_meter",
    title: str | None = None,
    entity_name: str | None = None,
) -> go.Figure:
    """
    Create load duration curve plot.

    Args:
        buildstock_ldc: BuildStock LDC data
        reference_ldc: Optional reference LDC data (e.g., from LRD)
        value_col: Column name for y-axis values
        title: Plot title
        entity_name: Name of entity (utility, state) for title

    Returns:
        Plotly figure
    """
    fig = go.Figure()

    # Add BuildStock LDC
    fig.add_trace(
        go.Scatter(
            x=buildstock_ldc["percentile"].to_list(),
            y=buildstock_ldc[value_col].to_list(),
            mode="lines",
            name="BuildStock",
            line=dict(color=BUILDSTOCK_COLOR, width=2),
        )
    )

    # Add reference LDC if provided
    if reference_ldc is not None:
        fig.add_trace(
            go.Scatter(
                x=reference_ldc["percentile"].to_list(),
                y=reference_ldc[value_col].to_list(),
                mode="lines",
                name="Reference (LRD)",
                line=dict(color=REFERENCE_COLOR, width=2, dash="dash"),
            )
        )

    # Build title
    if title is None:
        title = "Load Duration Curve"
        if entity_name:
            title = f"{title} - {entity_name}"

    # Apply theme
    fig = apply_theme(
        fig,
        title=title,
        xaxis_title="Percentile (%)",
        yaxis_title=f"{value_col.replace('_', ' ').title()}",
    )

    return fig


def plot_multi_utility_ldc(
    buildstock_ldc: pl.DataFrame,
    reference_ldc: pl.DataFrame | None = None,
    group_col: str = "eiaid",
    value_col: str = "kwh_per_meter",
    max_utilities: int = 10,
) -> go.Figure:
    """
    Create plot comparing LDCs for multiple utilities.

    Args:
        buildstock_ldc: BuildStock LDC data with grouping column
        reference_ldc: Optional reference LDC data
        group_col: Column to group by (e.g., 'eiaid', 'utility_name')
        value_col: Column name for y-axis values
        max_utilities: Maximum number of utilities to plot

    Returns:
        Plotly figure
    """
    fig = go.Figure()

    # Get unique entities
    entities = buildstock_ldc[group_col].unique().to_list()[:max_utilities]

    # Plot BuildStock LDC for each entity
    for entity in entities:
        entity_data = buildstock_ldc.filter(pl.col(group_col) == entity)

        fig.add_trace(
            go.Scatter(
                x=entity_data["percentile"].to_list(),
                y=entity_data[value_col].to_list(),
                mode="lines",
                name=f"{entity} (BuildStock)",
                line=dict(width=2),
            )
        )

        # Add reference data if available
        if reference_ldc is not None:
            ref_entity_data = reference_ldc.filter(pl.col(group_col) == entity)
            if ref_entity_data.height > 0:
                fig.add_trace(
                    go.Scatter(
                        x=ref_entity_data["percentile"].to_list(),
                        y=ref_entity_data[value_col].to_list(),
                        mode="lines",
                        name=f"{entity} (Reference)",
                        line=dict(width=2, dash="dash"),
                    )
                )

    # Apply theme
    fig = apply_theme(
        fig,
        title="Load Duration Curves - Multiple Utilities",
        xaxis_title="Percentile (%)",
        yaxis_title=f"{value_col.replace('_', ' ').title()}",
    )

    return fig


def prepare_buildstock_ldc_data(
    timeseries_df: pl.DataFrame,
    per_unit: bool = True,
    group_col: str | None = None,
) -> pl.DataFrame:
    """
    Prepare BuildStock timeseries data for LDC plotting.

    Args:
        timeseries_df: BuildStock timeseries data with electricity usage
        per_unit: Whether to normalize by unit count
        group_col: Optional grouping column

    Returns:
        DataFrame ready for LDC plotting
    """
    value_col = "fuel_use__electricity__total__kwh"

    if per_unit and "units_count" in timeseries_df.columns:
        # Calculate per-unit consumption
        timeseries_df = timeseries_df.with_columns(
            (pl.col(value_col) / pl.col("units_count")).alias("kwh_per_unit")
        )
        value_col = "kwh_per_unit"

    # Calculate LDC
    ldc = calculate_load_duration_curve(timeseries_df, value_col=value_col, group_col=group_col)

    return ldc


def plot_seasonal_ldc_comparison(
    buildstock_df: pl.DataFrame,
    reference_df: pl.DataFrame | None = None,
    time_col: str = "time",
    value_col: str = "kwh_per_meter",
) -> go.Figure:
    """
    Create seasonal comparison of load duration curves.

    Args:
        buildstock_df: BuildStock timeseries data
        reference_df: Optional reference timeseries data
        time_col: Name of time column
        value_col: Column for y-axis values

    Returns:
        Plotly figure with seasonal LDCs
    """
    from resstockpostproc.baseline_validation.utils import SEASON2MONTHS

    fig = go.Figure()

    for season, months in SEASON2MONTHS.items():
        if season == "annual":
            continue

        # Filter to season
        season_data = buildstock_df.filter(pl.col(time_col).dt.month().is_in(months))

        # Calculate LDC
        ldc = calculate_load_duration_curve(season_data, value_col=value_col)

        # Plot
        fig.add_trace(
            go.Scatter(
                x=ldc["percentile"].to_list(),
                y=ldc[value_col].to_list(),
                mode="lines",
                name=f"{season.title()} (BuildStock)",
                line=dict(width=2),
            )
        )

        # Add reference if provided
        if reference_df is not None:
            ref_season_data = reference_df.filter(pl.col(time_col).dt.month().is_in(months))
            ref_ldc = calculate_load_duration_curve(ref_season_data, value_col=value_col)

            fig.add_trace(
                go.Scatter(
                    x=ref_ldc["percentile"].to_list(),
                    y=ref_ldc[value_col].to_list(),
                    mode="lines",
                    name=f"{season.title()} (Reference)",
                    line=dict(width=2, dash="dash"),
                )
            )

    # Apply theme
    fig = apply_theme(
        fig,
        title="Seasonal Load Duration Curves",
        xaxis_title="Percentile (%)",
        yaxis_title=f"{value_col.replace('_', ' ').title()}",
    )

    return fig
