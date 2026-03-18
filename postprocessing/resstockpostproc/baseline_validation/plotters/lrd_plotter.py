"""
Load Duration Curve Plotter
---------------------------
Functions for generating load duration curve validation plots
"""

import polars as pl
import plotly.graph_objects as go

from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.baseline_validation.schema.plot_spec import PlotSpec, Resolution, ViewType
from resstockpostproc.shared_utils.generic_plotters import tilemap_plotter
from resstockpostproc.shared_utils.generic_plotters.bar_plotter import create_bar_plot
from resstockpostproc.shared_utils.generic_plotters.monthly_plotter import create_ts_plot
from resstockpostproc.baseline_validation.theme import apply_theme


def create_plot(data: pl.DataFrame, plot_spec: PlotSpec) -> tuple[go.Figure, str]:
    """Create load duration curve plot based on the plot specification."""

    assert plot_spec.aggregation_level == "eiaid", "LRD plots only support aggregation level 'eiaid'"
    final_df = data.clone()
    sidebar_column = None
    ts_xtick_vals = None
    ts_xtick_text = None
    timeseries_column = None
    x_unit = ""
    quantity_title = "kWh"
    quantity_column = f"{plot_spec.quantity}_value"
    match plot_spec.resolution:
        case Resolution.year:
            timeseries_column = None
            ts_xtick_vals = ()
            ts_xtick_text = ()
            sidebar_column = f"{plot_spec.quantity}_value_percent_difference"
            title = "Annual electricity consumption per dwelling unit"
        case Resolution.month:
            timeseries_column = Resolution.month
            ts_xtick_vals = ("JAN", "DEC")
            ts_xtick_text = ("   Jan", "Dec   ")
            title = "Monthly electricity consumption per dwelling unit"
        case Resolution.day_of_year:
            timeseries_column = "day of year"  # Now contains actual dates
            ts_xtick_vals = None  # Let Plotly auto-generate date ticks
            ts_xtick_text = None
            title = "Daily electricity consumption per dwelling unit"
            # Rename utility_name to utility_vertical to match the layout key
            # final_df = final_df.rename({"utility_name": "utility_vertical"})
        case Resolution.hour_of_year | Resolution.top_100_hours:
            if plot_spec.view in [ViewType.temp_view, ViewType.temp_count_view]:
                # Data already transformed by gather_data._prepare_temperature_view()
                x_unit = "°F"
                timeseries_column = "resstock_temp"
                if plot_spec.view == ViewType.temp_view:
                    title = "Load Vs outdoor drybulb temperature"
                else:
                    quantity_title = "count"
                    quantity_column = "temp_count"
                    title = "Count of number of hours vs outdoor drybulb temperature"
            else:
                final_df = final_df.sort(
                    "source", "utility_name", f"{plot_spec.quantity}_value", descending=[False, False, True]
                ).with_columns(
                    (
                        (pl.int_range(pl.len()) + 1).over("source", "utility_name")
                        * 100
                        / (pl.len()).over("source", "utility_name")
                    )
                    .round(3)
                    .alias("percent_time")
                )
                timeseries_column = "percent_time"
                title = "Load Duration Curve of electricity consumption per dwelling unit"
                if plot_spec.resolution == Resolution.top_100_hours:
                    title += " (Top 100 Hours)"
                ts_xtick_text = ("  0%", "100%    ")
                max_val = final_df["percent_time"].max()
                min_val = final_df["percent_time"].min()
                ts_xtick_vals = (min_val, max_val)

        case Resolution.hour_of_day | Resolution.hour_of_day_summer | Resolution.hour_of_day_winter:
            timeseries_column = plot_spec.resolution
            ts_xtick_vals = (0, 23)
            ts_xtick_text = ("     Hour 1", "Hour 24       ")
            if plot_spec.resolution == Resolution.hour_of_day_summer:
                title = "Average summer day hourly electricity consumption per dwelling unit"
            elif plot_spec.resolution == Resolution.hour_of_day_winter:
                title = "Average winter day hourly electricity consumption per dwelling unit"
            else:
                title = "Average daily electricity consumption per dwelling unit"
        case Resolution.hour_of_day_matrix:
            # Filter to single utility using focus_on
            if not plot_spec.focus_on:
                raise ValueError("hour_of_day_matrix requires focus_on to specify a single utility")

            final_df = final_df.filter(pl.col("utility_name") == plot_spec.focus_on)

            # Create combined column for tilemap layout
            final_df = final_df.with_columns((pl.col("month") + "_" + pl.col("day_type")).alias("month_daytype"))

            timeseries_column = "hour of day"
            ts_xtick_vals = (0, 23)
            ts_xtick_text = ("     Hour 1", "Hour 24       ")
            title = f"Hourly load profile matrix for {plot_spec.focus_on}"
        case _:
            raise ValueError(f"Unsupported resolution '{plot_spec.resolution}' for LRD plot.")

    # Determine second_category_column based on resolution
    if plot_spec.resolution == Resolution.hour_of_day_matrix:
        second_category_column = "month_daytype"
        second_category_title = "Month / Day Type"
    elif plot_spec.resolution == Resolution.day_of_year:
        second_category_column = "utility_vertical"
        second_category_title = "Utility (State)"
    else:
        second_category_column = "utility_name"
        second_category_title = "Utility (State)"

    # Detect single-entity (focused) plots for simplified rendering
    is_single = second_category_column in final_df.columns and final_df[second_category_column].n_unique() == 1

    if is_single:
        if timeseries_column:
            fig = create_ts_plot(
                data=final_df,
                timeseries_column=timeseries_column,
                quantity_column=quantity_column,
                first_category_column="source",
                first_category_title="Data Source",
                quantity_title=quantity_title,
                title_text=title,
                show_legends=True,
                x_unit=x_unit,
                x_tick_vals=ts_xtick_vals,
                x_tick_text=ts_xtick_text,
                fill_lower_bound=True,
            )
        else:
            fig = create_bar_plot(
                data=final_df,
                quantity_column=quantity_column,
                first_category_column="source",
                quantity_title=quantity_title,
                first_category_title="Data Source",
                orientation="v",
                title_text=title,
                show_legends=True,
            )
        height = 1080 * 0.4
        width = 1920 * 0.425
    else:
        fig = tilemap_plotter.plot_tilemap(
            data=final_df,
            quantity_title=quantity_title,
            quantity_column=quantity_column,
            first_category_column="source",
            first_category_title="Data Source",
            second_category_column=second_category_column,
            second_category_title=second_category_title,
            show_legends=True,
            timeseries_column=timeseries_column,
            ts_xtick_vals=ts_xtick_vals,
            ts_xtick_text=ts_xtick_text,
            x_unit=x_unit,
            title_text=title,
        )
        if plot_spec.resolution == Resolution.hour_of_day_matrix:
            height = 1800
            width = 900
        elif plot_spec.resolution == Resolution.day_of_year:
            height = 2000
            width = 1400
        else:
            height = 1080 * 0.8
            width = 1920 * 0.7

    fig = apply_theme(fig, title=title, height=height, width=width)
    return fig, title
