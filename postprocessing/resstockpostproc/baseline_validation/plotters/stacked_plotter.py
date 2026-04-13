from resstockpostproc.shared_utils.generic_plotters import box_plotter, bar_plotter
from resstockpostproc.shared_utils.generic_plotters.range_utils import compute_axis_range
from resstockpostproc.shared_utils.generic_plotters.tilemap_plotter import filter_null_sources
from resstockpostproc.baseline_validation.io_managers.get_recs_data import get_enduse_order
from resstockpostproc.baseline_validation.schema.plot_spec import PlotSpec, Metric, CoverageType, ViewType
from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.shared_utils.timing import timed
import plotly.graph_objects as go
import polars as pl
from plotly.subplots import make_subplots


def _get_reference_source(df: pl.DataFrame) -> str:
    """Get the reference (non-resstock) data source name for sorting.

    Returns the first source that doesn't contain 'resstock' (e.g. 'recs_2020', 'lrd_2018').
    Falls back to the first source if all contain 'resstock'.
    """
    sources = df["source"].unique(maintain_order=True).to_list()
    if not sources:
        raise ValueError("No data sources found in dataframe")
    for src in sources:
        if "resstock" not in src.lower():
            return src
    return sources[0]


def _add_quartile_cols(df: pl.DataFrame, quartile_column: str) -> pl.DataFrame:
    """Helper function to get the quartile column names for a given quantity column."""
    return df.with_columns(
        [
            pl.col(quartile_column).list.get(3).cast(pl.Float64).alias("q1"),
            pl.col(quartile_column).list.get(4).cast(pl.Float64).alias("median"),
            pl.col(quartile_column).list.get(5).cast(pl.Float64).alias("q3"),
            pl.col(quartile_column).list.get(0).cast(pl.Float64).alias("lower_whisker"),
            pl.col(quartile_column).list.get(0).cast(pl.Float64).alias("min"),
            pl.col(quartile_column).list.get(8).cast(pl.Float64).alias("upper_whisker"),
            pl.col(quartile_column).list.get(8).cast(pl.Float64).alias("max"),
        ]
    )

@timed
def _prepare_box_plot_data(df: pl.DataFrame, quantity: str, coverage: CoverageType) -> pl.DataFrame:
    """Prepare the data for box plot by adding necessary columns.

    Args:
        df: Input DataFrame
        quantity: The quantity column name (without suffix)
        coverage: CoverageType.all_units uses _quartiles, CoverageType.users_only uses _nonzero_quartiles
    """
    df = df.with_columns(pl.lit([]).alias("outliers"))
    df = df.with_columns(pl.lit([]).alias("outlier_buildings"))
    df = df.with_columns(pl.col(f"{quantity}_value").alias("mean"))

    if coverage == CoverageType.all_units:
        df = df.with_columns(pl.col("model_count").alias("n_points"))
        df = _add_quartile_cols(df, f"{quantity}_quartiles")
        return df
    elif coverage == CoverageType.users_only:
        df = df.with_columns(
            (
                pl.col("model_count").fill_null(0).fill_nan(0)
                * pl.col(f"{quantity}_percent_users").fill_null(0).fill_nan(0)
                / 100
            )
            .round(0)
            .cast(pl.Int32)
            .alias("n_points")
        )
        df = _add_quartile_cols(df, f"{quantity}_nonzero_quartiles")
        return df
    else:
        raise ValueError(f"Unsupported coverage type for box plot: {coverage}")

@timed
def split_graph_by_state(df: pl.DataFrame):
    """Split the graph data into subplots if needed.

    Yields tuples of (df_subset, second_category_column, row, col) for each subplot.
    """
    # Get states sorted by their maximum mean value across all sources
    ref_source = _get_reference_source(df)
    sorted_states = df.filter(pl.col("source") == ref_source).sort("units_count", descending=True)["state"].to_list()

    # Single state: no need to split into two columns
    if len(sorted_states) <= 1:

        def _single_iterator():
            yield df, "state", 1, 1

        fig = make_subplots(rows=1, cols=1)
        return fig, _single_iterator()

    # Split states into two columns
    mid_point = len(sorted_states) // 2
    states_col1 = sorted_states[:mid_point]
    states_col2 = sorted_states[mid_point:]

    # Yield first column
    def _graph_iterator():
        df_col1 = df.filter(pl.col("state").is_in(states_col1))
        state_order = pl.DataFrame({"state": states_col1, "state_order": range(len(states_col1))})
        df_col1 = df_col1.join(state_order, on="state").sort("state_order", maintain_order=True).drop("state_order")
        yield df_col1, "state", 1, 1

        # Yield second column
        df_col2 = df.filter(pl.col("state").is_in(states_col2))
        state_order = pl.DataFrame({"state": states_col2, "state_order": range(len(states_col2))})
        df_col2 = df_col2.join(state_order, on="state").sort("state_order", maintain_order=True).drop("state_order")
        yield df_col2, "state", 1, 2

    fig = make_subplots(rows=1, cols=2)
    return fig, _graph_iterator()

@timed
def split_graph_by_char(df: pl.DataFrame):
    """Split the graph data into subplots based on a character column.

    Yields tuples of (df_subset, second_category_column, row, col) for each subplot.
    """
    # Get the characteristic column name (first column that isn't source, model_count, units_count, or a quantity)
    char_column = [
        col
        for col in df.columns
        if col not in ["source", "model_count", "units_count"]
        and not col.endswith(
            (
                "_value",
                "_quartiles",
                "_nonzero_quartiles",
                "_percent_users",
                "_percent_difference",
                "_rse",
                "_upper_bound",
                "_lower_bound",
            )
        )
    ][0]

    # Get characteristic values sorted by reference source values (descending)
    ref_source = _get_reference_source(df)
    ref_df = df.filter(pl.col("source") == ref_source)
    if "units_count" in ref_df.columns and ref_df["units_count"].null_count() < len(ref_df):
        ref_df = ref_df.sort("units_count", descending=True)
    sorted_chars = ref_df[char_column].to_list()

    # All chars fit in one column
    def _graph_iterator():
        df_col1 = df.filter(pl.col(char_column).is_in(sorted_chars))
        char_order = pl.DataFrame({char_column: sorted_chars, f"{char_column}_order": range(len(sorted_chars))})
        df_col1 = (
            df_col1.join(char_order, on=char_column)
            .sort(f"{char_column}_order", maintain_order=True)
            .drop(f"{char_column}_order")
        )
        yield df_col1, char_column, 1, 1

    fig = make_subplots(rows=1, cols=1)
    return fig, _graph_iterator()

@timed
def split_graph_by_enduse(df: pl.DataFrame, plot_spec: PlotSpec):
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
                return [
                    col.replace("_value", "")
                    for col in df.columns
                    if col.startswith("electricity_") and col.endswith("_value") and not col.endswith("_total_value")
                ]
            case "Natural Gas End uses":
                return [
                    col.replace("_value", "")
                    for col in df.columns
                    if col.startswith("natural_gas_") and col.endswith("_value") and not col.endswith("_total_value")
                ]
            case "Propane End uses":
                return [
                    col.replace("_value", "")
                    for col in df.columns
                    if col.startswith("propane_") and col.endswith("_value") and not col.endswith("_total_value")
                ]
            case "Fuel Oil End uses":
                return [
                    col.replace("_value", "")
                    for col in df.columns
                    if col.startswith("fuel_oil_") and col.endswith("_value") and not col.endswith("_total_value")
                ]
            case _:
                return []

    left_enduse_counts = [
        len(_get_quantity_columns(group)) for group, position in enduse_groups_2_position.items() if position[1] == 1
    ]
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
        shared_xaxes=True,
    )

    # Process each end-use group
    def _graph_iterator():
        for group_name, (row, col) in enduse_groups_2_position.items():
            quantities = _get_quantity_columns(group_name)

            if not quantities:
                continue

            # Pivot the dataframe to create a 'quantity' column
            # Keep id columns that don't vary by quantity
            agg_col = plot_spec.group_by or (plot_spec.effective_group_by[-1] if plot_spec.effective_group_by else "state")
            id_cols = [agg_col, "model_count", "units_count", "source"]

            # Build list of columns to unpivot for each quantity
            value_cols = []
            for qty in quantities:
                # Add all related columns for this quantity
                related_cols = [c for c in df.columns if c.startswith(f"{qty}_")]
                value_cols.extend(related_cols)

            # Unpivot by creating a row for each quantity
            dfs_to_concat = []
            for qty in quantities:
                qty_df = df.select(id_cols + [c for c in df.columns if c.startswith(f"{qty}_")])
                # Rename columns to remove the quantity prefix
                rename_map = {c: c.replace(f"{qty}_", "enduse_") for c in qty_df.columns if c.startswith(f"{qty}_")}
                qty_df = qty_df.rename(rename_map)
                # Cast scalar numeric enduse columns to Float64 to avoid SchemaError
                # when sparse data produces Int64 nulls for some enduses.
                # Skip list columns (e.g. _quartiles) which are already List[Float64].
                enduse_cols = [
                    c for c in qty_df.columns
                    if c.startswith("enduse_") and qty_df[c].dtype.is_numeric()
                ]
                qty_df = qty_df.with_columns(pl.col(c).cast(pl.Float64) for c in enduse_cols)
                qty_df = qty_df.with_columns(pl.lit(qty).alias("quantity"))
                dfs_to_concat.append(qty_df)

            group_df = pl.concat(dfs_to_concat, how="diagonal")

            # Rename 'quantity' column to 'enduse' to serve as second category
            group_df = group_df.rename({"quantity": "enduse"})

            # Sort enduses by canonical RECS national total order (consistent across all views)
            canonical_order = get_enduse_order().get(group_name, [])
            sort_order = [e for e in canonical_order if e in group_df["enduse"].unique().to_list()]
            # Append any enduses not in canonical order (shouldn't happen, but defensive)
            sort_order += [e for e in group_df["enduse"].unique().to_list() if e not in sort_order]

            if sort_order:
                enduse_order = pl.DataFrame({"enduse": sort_order, "enduse_order": range(len(sort_order))})
                group_df = (
                    group_df.join(enduse_order, on="enduse").sort("enduse_order", maintain_order=True).drop("enduse_order")
                )

            yield group_df, "enduse", row, col

    return fig, _graph_iterator()

@timed
def split_graph(df: pl.DataFrame, plot_spec: PlotSpec):
    """Split the graph data into subplots based on the plot specification."""
    if plot_spec.group_by == "state" and plot_spec.quantity != DataCol.ALL and not plot_spec.focus_on:
        return split_graph_by_state(df)
    elif plot_spec.quantity == DataCol.ALL:
        return split_graph_by_enduse(df, plot_spec)
    else:
        return split_graph_by_char(df)

@timed
def get_custom_range(df: pl.DataFrame, plot_spec: PlotSpec) -> tuple[float, float]:
    """Get custom y-axis range for the plot.

    Args:
        df: Input DataFrame
        plot_spec: The plot specification

    Returns:
        Tuple of (min_val, max_val) for y-axis range
    """
    quantity = plot_spec.quantity
    view = plot_spec.view

    # Dwelling unit count case
    if quantity == DataCol.UNITS_COUNT:
        col = "units_count_percent_difference" if view == ViewType.diff_view else "units_count"
        return compute_axis_range(df, col)

    # Determine if this is a distribution (box) plot and get column suffix
    is_dist = plot_spec.is_distribution_metric
    if is_dist:
        if plot_spec.coverage == CoverageType.users_only:
            col_suffix = "_nonzero_quartiles"
        else:
            col_suffix = "_quartiles"
    elif plot_spec.is_penetration_metric:
        col_suffix = "_percent_users"
    else:
        col_suffix = "_value"

    col_suffix += "_percent_difference" if view == ViewType.diff_view else ""
    all_quantities = (
        [c for c in df.columns if c.endswith(col_suffix)] if quantity == DataCol.ALL else [f"{quantity}{col_suffix}"]
    )
    all_min_val, all_max_val = float("inf"), float("-inf")
    for quantity_col in all_quantities:
        if quantity_col not in df.columns:
            continue
        if is_dist:
            raw_min = df[quantity_col].fill_null([0]).list.get(0).min()
            raw_max = df[quantity_col].fill_null([0]).list.get(-1).max()
            min_val = min(0, float(raw_min) if raw_min is not None else 0.0)
            max_val = max(0, float(raw_max) if raw_max is not None else 0.0)
        else:
            min_val, max_val = compute_axis_range(df, quantity_col)
        all_min_val = min(all_min_val, min_val)
        all_max_val = max(all_max_val, max_val)

    # Handle case where no quantities were found
    if all_min_val == float("inf"):
        all_min_val = 0.0
    if all_max_val == float("-inf"):
        all_max_val = 1.0

    return all_min_val, all_max_val


@timed
def create_stacked_plot(df: pl.DataFrame, plot_spec: PlotSpec) -> go.Figure:
    """Create a box plot or bar comparing data sources across states.

    Uses distribution metric for box plots, otherwise bar plots.
    """
    # Determine quantity title based on view type, aggregation type, and coverage
    if plot_spec.quantity == DataCol.UNITS_COUNT:
        # Dwelling unit count case
        quantity_title = "count"
    elif plot_spec.is_distribution_metric:
        # Distribution box plot
        if plot_spec.coverage == CoverageType.users_only:
            quantity_title = "kWh/user"
        else:
            quantity_title = "kWh/unit"
    elif plot_spec.is_penetration_metric:
        quantity_title = "%"
    elif plot_spec.view == ViewType.diff_view:
        quantity_title = "Symmetric Percent Difference"
    elif plot_spec.view == ViewType.value_view:
        quantity_title = "kWh"
    else:
        quantity_title = ""

    agg_col = plot_spec.group_by or (plot_spec.effective_group_by[-1] if plot_spec.effective_group_by else "state")
    if plot_spec.quantity == DataCol.ALL:
        if plot_spec.focus_on:
            for col, val in plot_spec.focus_on:
                filter_col = col
                if filter_col in df.columns:
                    df = df.filter(pl.col(filter_col) == val)

    # Exclude US Total from total-aggregation value_view plots to prevent scale domination
    # (only when showing all entities, not when focused on a single entity like US Total)
    if (plot_spec.aggregation_type == Metric.total
            and plot_spec.view == ViewType.value_view
            and not plot_spec.focus_on
            and agg_col in df.columns
            and df[agg_col].n_unique() > 1):
        df = df.filter(pl.col(agg_col) != "US Total")

    show_legends = True
    assert plot_spec is not None
    fig, graph_iterator = split_graph(df, plot_spec)
    custom_range = get_custom_range(df, plot_spec)

    for df_subset, second_cat_column, row, col in graph_iterator:
        quantity_col = "enduse" if plot_spec.quantity == DataCol.ALL else plot_spec.quantity

        # Use box plot for distribution view
        if plot_spec.is_distribution_metric:
            plot_df = _prepare_box_plot_data(df_subset.clone(), quantity_col, plot_spec.coverage)
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
                custom_range=custom_range,
            )
        else:
            # Bar plot for other view types
            if plot_spec.quantity == DataCol.UNITS_COUNT:
                quantity_col = "units_count"
            elif plot_spec.is_penetration_metric:
                quantity_col = f"{quantity_col}_percent_users"
            else:
                quantity_col = f"{quantity_col}_value"
            quantity_col += "_percent_difference" if plot_spec.view == ViewType.diff_view else ""
            if plot_spec.view == ViewType.diff_view:
                df_subset = filter_null_sources(df_subset, "source", quantity_col)
            rse_col = f"{quantity_col}_rse"
            bar_plotter.create_bar_plot(
                data=df_subset,
                quantity_column=quantity_col,
                rse_column=rse_col if rse_col in df_subset.columns else None,
                first_category_column="source",
                second_category_column=second_cat_column,
                quantity_title=quantity_title,
                first_category_title="Data Source",
                second_category_title=" ",
                fig=fig,
                row=row,
                col=col,
                show_legends=show_legends,
                custom_range=custom_range,
            )
        show_legends = False  # Only show legends for the first subplot

    return fig
