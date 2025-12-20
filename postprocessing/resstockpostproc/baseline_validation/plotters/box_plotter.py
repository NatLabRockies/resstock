from resstockpostproc.shared_utils.generic_plotters import box_plotter
from resstockpostproc.baseline_validation.schema.plot_spec import PlotSpec, AggregationType
import plotly.graph_objects as go
import polars as pl
from plotly.subplots import make_subplots

def _add_quartile_cols(df: pl.DataFrame, quartile_column: str) -> pl.DataFrame:
    """Helper function to get the quartile column names for a given quantity column."""
    return df.with_columns([
        pl.col(quartile_column).str.strip_chars("[]").str.split(", ").list.get(3).cast(pl.Float64).alias("q1"),
        pl.col(quartile_column).str.strip_chars("[]").str.split(", ").list.get(4).cast(pl.Float64).alias("median"),
        pl.col(quartile_column).str.strip_chars("[]").str.split(", ").list.get(5).cast(pl.Float64).alias("q3"),
        pl.col(quartile_column).str.strip_chars("[]").str.split(", ").list.get(0).cast(pl.Float64).alias("lower_whisker"),
        pl.col(quartile_column).str.strip_chars("[]").str.split(", ").list.get(0).cast(pl.Float64).alias("min"),
        pl.col(quartile_column).str.strip_chars("[]").str.split(", ").list.get(8).cast(pl.Float64).alias("upper_whisker"),
        pl.col(quartile_column).str.strip_chars("[]").str.split(", ").list.get(8).cast(pl.Float64).alias("max"),
    ])

def _prepare_box_plot_data(df: pl.DataFrame, plot_spec: PlotSpec) -> pl.DataFrame:
    """Prepare the data for box plot by adding necessary columns."""
    
    df = df.with_columns(pl.lit([]).alias("outliers"))
    df = df.with_columns(pl.lit([]).alias("outlier_buildings"))
    df = df.with_columns(pl.col(f"{plot_spec.quantity}_value").alias("mean"))
    if plot_spec.aggregation_type == AggregationType.per_unit_distribution:
        df = df.with_columns(pl.col("model_count").alias("n_points"))
        df = _add_quartile_cols(df, f"{plot_spec.quantity}_quartiles")
        return df
    elif plot_spec.aggregation_type == AggregationType.per_user_distribution:
        df = df.with_columns((pl.col("model_count") *
                              pl.col(f"{plot_spec.quantity}_percent_users") / 100)
                              .round(0).cast(pl.Int32).alias("n_points")
                            )
        df = _add_quartile_cols(df, f"{plot_spec.quantity}_nonzero_quartiles")
        return df
    else:
        raise ValueError(f"Unsupported aggregation type for box plot: {plot_spec.aggregation_type}")

def create_box_plot(df: pl.DataFrame, plot_spec: PlotSpec) -> go.Figure:
    df = _prepare_box_plot_data(df, plot_spec)
    
    # Get states sorted by their maximum mean value across all sources
    sorted_states = df.filter(pl.col("source")=="recs_2020").sort("units_count", descending=True)["state"].to_list()
    state_order = pl.DataFrame({
        "state": sorted_states,
        "state_order": range(len(sorted_states))
    })
    df = df.join(state_order, on="state").sort("state_order", maintain_order=True).drop("state_order")
    half_states = sorted_states[:len(sorted_states)//2]

    fig = make_subplots(rows=1, cols=2, subplot_titles=["States", "States"])
    # First panel - first half of states
    df_first_half = df.filter(pl.col("state").is_in(half_states))
    plot_df = _prepare_box_plot_data(df_first_half.clone(), plot_spec)
    box_plotter.create_box_plot(
        plot_df,
        first_category_column="source",
        second_category_column="state",
        show_kde=False,
        quantity_title="Natural Gas Consumption (kWh)",
        first_category_title="Data Source",
        second_category_title=None,
        fig=fig,
        row=1,
        col=1
    )

    # Second panel - second half of states
    second_half_states = sorted_states[len(sorted_states)//2:]
    df_second_half = df.filter(pl.col("state").is_in(second_half_states))
    plot_df = _prepare_box_plot_data(df_second_half.clone(), plot_spec)
    box_plotter.create_box_plot(
        plot_df,
        first_category_column="source",
        second_category_column="state",
        show_kde=False,
        quantity_title="Natural Gas Consumption (kWh)",
        first_category_title="Data Source",
        second_category_title=None,
        fig=fig,
        row=1,
        col=2,
        show_legends=False
    )
    fig.update_layout(
        title="Natural Gas Consumption Vs RECS2020 by State",
        height=1080 * 0.8,
        width=1920 * 0.6,
        font={"size": 12},
        legend={
            "orientation": "v",
            "x": 0.99,
            "y": 0.11,
            "xanchor": "right",
            "yanchor": "bottom",
            "font": {"size": 12},
            "bgcolor": "rgba(255, 255, 255, 0.8)",
        },
        margin={"l": 100, "r": 60, "t": 100, "b": 60},
    )
    fig.show(renderer="browser")
    return fig