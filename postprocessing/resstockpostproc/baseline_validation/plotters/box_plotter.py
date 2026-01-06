from resstockpostproc.shared_utils.generic_plotters import box_plotter, bar_plotter
from resstockpostproc.baseline_validation.schema.plot_spec import PlotSpec, AggregationType, ViewType
import plotly.graph_objects as go
import polars as pl
from plotly.subplots import make_subplots

def _add_quartile_cols(df: pl.DataFrame, quartile_column: str) -> pl.DataFrame:
    """Helper function to get the quartile column names for a given quantity column."""
    return df.with_columns([
        pl.col(quartile_column).list.get(3).cast(pl.Float64).alias("q1"),
        pl.col(quartile_column).list.get(4).cast(pl.Float64).alias("median"),
        pl.col(quartile_column).list.get(5).cast(pl.Float64).alias("q3"),
        pl.col(quartile_column).list.get(0).cast(pl.Float64).alias("lower_whisker"),
        pl.col(quartile_column).list.get(0).cast(pl.Float64).alias("min"),
        pl.col(quartile_column).list.get(8).cast(pl.Float64).alias("upper_whisker"),
        pl.col(quartile_column).list.get(8).cast(pl.Float64).alias("max"),
    ])

def _prepare_box_plot_data(df: pl.DataFrame, quantity: str, aggregation_type: AggregationType) -> pl.DataFrame:
    """Prepare the data for box plot by adding necessary columns."""
    
    df = df.with_columns(pl.lit([]).alias("outliers"))
    df = df.with_columns(pl.lit([]).alias("outlier_buildings"))
    df = df.with_columns(pl.col(f"{quantity}_value").alias("mean"))
    if aggregation_type == AggregationType.per_unit_distribution:
        df = df.with_columns(pl.col("model_count").alias("n_points"))
        df = _add_quartile_cols(df, f"{quantity}_quartiles")
        return df
    elif aggregation_type == AggregationType.per_user_distribution:
        df = df.with_columns((pl.col("model_count") *
                              pl.col(f"{quantity}_percent_users") / 100)
                              .round(0).cast(pl.Int32).alias("n_points")
                            )
        df = _add_quartile_cols(df, f"{quantity}_nonzero_quartiles")
        return df
    else:
        raise ValueError(f"Unsupported aggregation type for box plot: {aggregation_type}")


def split_graph_by_state(df: pl.DataFrame):
    """Split the graph data into subplots if needed.
    
    Yields tuples of (df_subset, second_category_column, row, col) for each subplot.
    """
    # Get states sorted by their maximum mean value across all sources
    sorted_states = (
        df.filter(pl.col("source") == "recs_2020")
        .sort("units_count", descending=True)["state"]
        .to_list()
    )
    
    # Split states into two columns
    mid_point = len(sorted_states) // 2
    states_col1 = sorted_states[:mid_point]
    states_col2 = sorted_states[mid_point:]
    
    # Yield first column
    def _graph_iterator():
        df_col1 = df.filter(pl.col("state").is_in(states_col1))
        state_order = pl.DataFrame({
            "state": states_col1,
            "state_order": range(len(states_col1))
        })
        df_col1 = df_col1.join(state_order, on="state").sort("state_order", maintain_order=True).drop("state_order")
        yield df_col1, "state", 1, 1
        
        # Yield second column
        df_col2 = df.filter(pl.col("state").is_in(states_col2))
        state_order = pl.DataFrame({
            "state": states_col2,
            "state_order": range(len(states_col2))
        })
        df_col2 = df_col2.join(state_order, on="state").sort("state_order", maintain_order=True).drop("state_order")
        yield df_col2, "state", 1, 2
    
    fig = make_subplots(rows=1, cols=2)
    return fig, _graph_iterator()

def split_graph_by_char(df: pl.DataFrame):
    """Split the graph data into subplots based on a character column.
    
    Yields tuples of (df_subset, second_category_column, row, col) for each subplot.
    """
    # Get the characteristic column name (first column that isn't source, model_count, units_count, or a quantity)
    char_column = [col for col in df.columns 
                   if col not in ["source", "model_count", "units_count"] 
                   and not col.endswith(("_value", "_quartiles", "_nonzero_quartiles", "_percent_users"))][0]
    
    # Get characteristic values sorted by their maximum mean value across all sources
    sorted_chars = (
        df.filter(pl.col("source") == "recs_2020")
        .sort("units_count", descending=True)[char_column]
        .to_list()
    )
    
    # All chars fit in one column
    def _graph_iterator():
        df_col1 = df.filter(pl.col(char_column).is_in(sorted_chars))
        char_order = pl.DataFrame({
            char_column: sorted_chars,
            f"{char_column}_order": range(len(sorted_chars))
        })
        df_col1 = df_col1.join(char_order, on=char_column).sort(f"{char_column}_order", maintain_order=True).drop(f"{char_column}_order")
        yield df_col1, char_column, 1, 1
    
    fig = make_subplots(rows=1, cols=1)
    return fig, _graph_iterator()


def split_graph_by_enduse(df: pl.DataFrame):
    """Split the graph data into subplots by end-use categories.
    
    Yields tuples of (df_subset, second_category_column, row, col) for each subplot.
    """
    # Define end-use groups and their positions
    enduse_groups_2_position = {
        "Fuel Totals": (1, 1),
        "Electricity End uses": (1, 2),
        "Natural Gas End uses": (2, 1),
        "Propane End uses": (3, 1),
        "Fuel Oil End uses": (4, 1),
    }
    
    def _get_quantity_columns(quantity_group: str) -> list[str]:
        """Get the list of quantity column names for a given group."""
        match quantity_group:
            case "Fuel Totals":
                return ["electricity_total", "natural_gas_total", "propane_total", "fuel_oil_total"]
            case "Electricity End uses":
                return [col.replace("_value", "") for col in df.columns 
                        if col.startswith("electricity_") and col.endswith("_value") 
                        and not col.endswith("_total_value")]
            case "Natural Gas End uses":
                return [col.replace("_value", "") for col in df.columns 
                        if col.startswith("natural_gas_") and col.endswith("_value") 
                        and not col.endswith("_total_value")]
            case "Propane End uses":
                return [col.replace("_value", "") for col in df.columns 
                        if col.startswith("propane_") and col.endswith("_value") 
                        and not col.endswith("_total_value")]
            case "Fuel Oil End uses":
                return [col.replace("_value", "") for col in df.columns 
                        if col.startswith("fuel_oil_") and col.endswith("_value") 
                        and not col.endswith("_total_value")]
            case _:
                return []
    
    left_enduse_counts = [len(_get_quantity_columns(group)) for group, position in enduse_groups_2_position.items()
                          if position[1] == 1]
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
        column_widths=[0.5, 0.5],  # Left narrower, right wider
        row_heights=row_heights,  # Proportional to number of end-uses
        horizontal_spacing=0.25,
        vertical_spacing=0.15,  # Reduced spacing between rows
        shared_yaxes=False,
        shared_xaxes=True
    )

    # Process each end-use group
    def _graph_iterator():
        for group_name, (row, col) in enduse_groups_2_position.items():
            quantities = _get_quantity_columns(group_name)
            
            if not quantities:
                continue
            
            # Pivot the dataframe to create a 'quantity' column
            # Keep id columns that don't vary by quantity
            id_cols = ["state", "model_count", "units_count", "source"]
            
            # Build list of columns to unpivot for each quantity
            value_cols = []
            for qty in quantities:
                # Add all related columns for this quantity
                related_cols = [c for c in df.columns if c.startswith(f"{qty}_")]
                value_cols.extend(related_cols)
            
            # Unpivot by creating a row for each quantity
            dfs_to_concat = []
            for qty in quantities:
                qty_df = df.select(
                    id_cols + 
                    [c for c in df.columns if c.startswith(f"{qty}_")]
                )
                # Rename columns to remove the quantity prefix
                rename_map = {c: c.replace(f"{qty}_", "enduse_") for c in qty_df.columns if c.startswith(f"{qty}_")}
                qty_df = qty_df.rename(rename_map)
                qty_df = qty_df.with_columns(pl.lit(qty).alias("quantity"))
                dfs_to_concat.append(qty_df)
            
            group_df = pl.concat(dfs_to_concat, how="diagonal")
            
            # Rename 'quantity' column to 'enduse' to serve as second category
            group_df = group_df.rename({"quantity": "enduse"})
            
            yield group_df, "enduse", row, col
    return fig, _graph_iterator()



def split_graph(df: pl.DataFrame, plot_spec: PlotSpec):
    """Split the graph data into subplots based on the plot specification."""
    if plot_spec.aggregation_level == "state" and plot_spec.quantity is not None:
        return split_graph_by_state(df)
    elif plot_spec.quantity is None:
        return split_graph_by_enduse(df)
    else:
        return split_graph_by_char(df)


def get_custom_range(df: pl.DataFrame, quantity: str, aggregation_type: AggregationType, view: ViewType) -> tuple[float, float]:
    if aggregation_type == AggregationType.customers:
        return 0, df["units_count"].max()
    is_dist = "distribution" in aggregation_type.name.lower()
    col_suffix = "_value" if not is_dist else "_quartiles"
    col_suffix += "_percent_difference" if view == ViewType.diff_view else ""
    all_quantities = (
        [c for c in df.columns if c.endswith(col_suffix)]
        if quantity is None
        else [f"{quantity}{col_suffix}"]
    )
    all_min_val, all_max_val = float("inf"), float("-inf")
    for quantity_col in all_quantities:
        min_val = df[quantity_col].fill_null(0).list.get(0).min() if is_dist else df[quantity_col].fill_null(0).min()
        min_val = min(0, min_val)
        max_val = df[quantity_col].fill_null(0).list.get(-1).max() if is_dist else df[quantity_col].fill_null(0).max()
        all_min_val = min(all_min_val, min_val)
        all_max_val = max(all_max_val, max_val)
    return all_min_val, all_max_val

def create_vertical_plot(df: pl.DataFrame, plot_spec: PlotSpec) -> go.Figure:
    """Create a box plot or bar comparing data sources across states."""
    quantity_title = (
        "count" if plot_spec.aggregation_type == AggregationType.customers
        else "kWh/home" if plot_spec.aggregation_type == AggregationType.per_unit_distribution 
        else "kWh/user" if plot_spec.aggregation_type == AggregationType.per_user_distribution
        else "kWh" if plot_spec.view == ViewType.value_view
        else "Percent Difference" if plot_spec.view == ViewType.diff_view
        else ""
    )
    if plot_spec.quantity is None:
        if plot_spec.focus_on is None:
            raise ValueError("When quantity is None, focus_on must be specified")
        df = df.filter(pl.col(plot_spec.aggregation_level) == plot_spec.focus_on)

    show_legends = True
    assert plot_spec is not None
    fig, graph_iterator = split_graph(df, plot_spec)
    custom_range = get_custom_range(df, plot_spec.quantity, plot_spec.aggregation_type, plot_spec.view)
    for df_subset, second_cat_column, row, col in graph_iterator:
        quantity_col = plot_spec.quantity or "enduse"
        if plot_spec.aggregation_type in [AggregationType.per_user_distribution, AggregationType.per_unit_distribution]:
            plot_df = _prepare_box_plot_data(df_subset.clone(),quantity_col, plot_spec.aggregation_type)
            box_plotter.create_box_plot(
                plot_df,
                first_category_column="source",
                second_category_column=second_cat_column,
                show_kde=False,
                quantity_title=quantity_title,
                first_category_title="Data Source",
                second_category_title=" ",
                fig=fig,
                row=row,
                col=col,
                show_legends=show_legends,
                custom_range=custom_range
            )
        else:
            if plot_spec.aggregation_type == AggregationType.customers:
                quantity_col = "units_count"
            else:
                quantity_col = f"{quantity_col}_value"
                quantity_col += "_percent_difference" if plot_spec.view == ViewType.diff_view else ""
            bar_plotter.create_bar_plot(
                data=df_subset,
                quantity_column=quantity_col,
                first_category_column="source",
                second_category_column=second_cat_column,
                quantity_title=quantity_title,
                first_category_title="Data Source",
                second_category_title=" ",
                fig=fig,
                row=row,
                col=col,
                show_legends=show_legends,
                custom_range=custom_range
            )
        show_legends = False  # Only show legends for the first subplot
    
    return fig