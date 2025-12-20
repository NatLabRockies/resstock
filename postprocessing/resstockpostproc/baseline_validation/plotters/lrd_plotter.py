"""
Load Duration Curve Plotter
---------------------------
Functions for generating load duration curve validation plots
"""
import polars as pl
import plotly.graph_objects as go

from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    Resolution,
    ViewType
)
from resstockpostproc.shared_utils.generic_plotters import tilemap_plotter
from resstockpostproc.baseline_validation.theme import apply_theme

def create_plot(
        data: pl.DataFrame,
        plot_spec: PlotSpec

) -> tuple[go.Figure, str]:
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
            timeseries_column = Resolution.day_of_year
            ts_xtick_vals = (1, 365)
            ts_xtick_text = ("     Jan 1", "Dec 31     ")
            title = "Daily electricity consumption per dwelling unit"
        case Resolution.hour_of_year | Resolution.top_100_hours:
            if plot_spec.view in [ViewType.temp_view, ViewType.temp_count_view]:
                temp_col = f"{DataCol.OUTDOOR_DRYBULB_TEMP}_value"
                final_df = final_df.with_columns(
                    (pl.col(temp_col) / 4 * 9 / 5 + 32).round(0).cast(pl.Int32)  # Convert from daily total to daily average F
                )
                resstock_src = next(src for src in final_df["source"].unique(maintain_order=True) if "resstock" in src)
                ref_temp = final_df.filter(pl.col("source") == resstock_src).select(
                    "utility_name", pl.col(plot_spec.resolution), pl.col(temp_col).alias("resstock_temp")
                )
                final_df = final_df.join(ref_temp, on=("utility_name", plot_spec.resolution), how="left")
                final_df = final_df.sort("source", "utility_name", "resstock_temp",
                                        descending=[False, False, False], maintain_order=True)
                final_df = final_df.group_by(["source", "utility_name", "resstock_temp"], maintain_order=True).agg(
                    pl.col(f"{plot_spec.quantity}_value").mean(), pl.count().alias("temp_count")
                )
                final_df = final_df.sort("source", "utility_name", "resstock_temp", descending=[False, False, False])
                x_unit = "°F"
                timeseries_column = "resstock_temp"
                if plot_spec.view == ViewType.temp_view:
                    timeseries_column = "resstock_temp"
                    title = "Load Vs outdoor drybulb temperature"
                else:
                    quantity_title = "count"
                    quantity_column = "temp_count"
                    title = "Count of number of hours vs outdoor drybulb temperature"
            else:
                final_df = final_df.sort("source", "utility_name", f"{plot_spec.quantity}_value",
                                        descending=[False, False, True]).with_columns(
                    ((pl.int_range(pl.len()) + 1).over("source", "utility_name") * 100 /
                    (pl.len()).over("source", "utility_name")).round(3).alias("percent_time")
                )
                timeseries_column = "percent_time"
                title = "Load Duration Curve of electricity consumption per dwelling unit"
                if plot_spec.resolution == Resolution.top_100_hours:
                    final_df = final_df.filter(pl.col("percent_time") <= 100 * 100 / 8760)
                    max_val = final_df["percent_time"].max()
                    ts_xtick_text = ("  0%", f"{max_val:.1f}%    ")
                    title += " (Top 100 Hours)"
                else:
                    ts_xtick_text=("  0%", "100%    ")
                    max_val = final_df["percent_time"].max()
                min_val = final_df["percent_time"].min()
                ts_xtick_vals=(min_val, max_val)

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
        case _:
            raise ValueError(f"Unsupported resolution '{plot_spec.resolution}' for LRD plot.")
    

    fig = tilemap_plotter.plot_tilemap(
        data=final_df,
        quantity_title=quantity_title,
        quantity_column=quantity_column,
        first_category_column="source",
        first_category_title="Data Source",
        second_category_column="utility_name",
        second_category_title="Utility (State)",
        show_legends=True,
        timeseries_column=timeseries_column,
        ts_xtick_vals=ts_xtick_vals,
        ts_xtick_text=ts_xtick_text,
        x_unit=x_unit,
        title_text=title,
    )
    fig = apply_theme(fig,
                      title=title,
                      height=1080 * 0.8,
                      width=1920 * 0.7)
    return fig, title