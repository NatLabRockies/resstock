"""Subplot-iteration helpers for the stacked plot family.

Splits a comparison DataFrame into (df_subset, second_category_column,
row, col) chunks for stacked rendering — state-pair columns, per-char
single column, or the 4x2 end-use layout — plus the ordering utilities
(reference source resolution, RECS semantic sort, units_count fallback)
those splitters depend on.

Extracted from stacked_plotter.py in refactor plan V2 step 6.2.
"""

import polars as pl
from plotly.subplots import make_subplots

from resstockpostproc.baseline_validation.io_managers.get_recs_data import get_enduse_order
from resstockpostproc.baseline_validation.schema.plot_spec import (
    ComparisonDataset,
    CoverageType,
    Layout,
    PlotSpec,
)
from resstockpostproc.shared_utils.sorting import human_sort
from resstockpostproc.shared_utils.timing import timed


def get_reference_source(df: pl.DataFrame) -> str:
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


@timed
def split_graph_by_state(df: pl.DataFrame):
    """Split the graph data into subplots if needed.

    Yields tuples of (df_subset, second_category_column, row, col) for each subplot.
    """
    # Get states sorted by their maximum mean value across all sources
    ref_source = get_reference_source(df)
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


_RECS_SEMANTIC_SORT_COLUMNS = {
    "vintage",
    "census_division_recs",
    "geometry_building_type_recs",
    "heating_fuel",
    "building_america_climate_zone",
}


def _dedupe_keep_order(values: list) -> list:
    """Return unique values while preserving the first-seen order."""
    return list(dict.fromkeys([v for v in values if v is not None]))


def _sort_chars_by_units_count(ref_df: pl.DataFrame, char_column: str) -> list:
    """Sort characteristic values by reference-source units_count descending."""
    sorted_ref = ref_df
    if "units_count" in sorted_ref.columns and sorted_ref["units_count"].null_count() < len(sorted_ref):
        sorted_ref = sorted_ref.sort("units_count", descending=True)
    return _dedupe_keep_order(sorted_ref[char_column].to_list())


def _sort_chars_semantically_for_recs(ref_df: pl.DataFrame, char_column: str) -> list[str]:
    """Sort RECS characteristic labels using shared human/custom sorting rules."""
    sorted_df = human_sort(
        ref_df.select(pl.col(char_column).cast(pl.String).alias(char_column)).drop_nulls().lazy(),
        char_column,
    ).collect()
    ordered = _dedupe_keep_order(sorted_df[char_column].to_list())

    # Keep U.S. total at the front for consistency with existing grouped views.
    if "US Total" in ordered:
        ordered = ["US Total"] + [v for v in ordered if v != "US Total"]
    return ordered


def resolve_sorted_chars(df: pl.DataFrame, char_column: str, plot_spec: PlotSpec | None) -> list:
    """Resolve characteristic order with RECS semantic ordering and fallback behavior."""
    ref_source = get_reference_source(df)
    ref_df = df.filter(pl.col("source") == ref_source)

    if (
        plot_spec is not None
        and plot_spec.comparison_dataset == ComparisonDataset.recs
        and char_column in _RECS_SEMANTIC_SORT_COLUMNS
    ):
        ordered = _sort_chars_semantically_for_recs(ref_df, char_column)
        return ordered if ordered else _sort_chars_by_units_count(ref_df, char_column)

    return _sort_chars_by_units_count(ref_df, char_column)


@timed
def split_graph_by_char(df: pl.DataFrame, plot_spec: PlotSpec | None = None):
    """Split the graph data into subplots based on a character column.

    Yields tuples of (df_subset, second_category_column, row, col) for each subplot.
    """
    # Get the characteristic column name (first column that isn't source, model_count, units_count, or a quantity)
    quantity_suffixes = (
        "_value",
        "_quartiles",
        "_nonzero_quartiles",
        "_percent_users",
        "_percent_difference",
        "_rse",
        "_upper_bound",
        "_lower_bound",
    )
    char_column = next(
        col
        for col in df.columns
        if col not in ("source", "model_count", "units_count")
        and not col.endswith(quantity_suffixes)
    )

    sorted_chars = resolve_sorted_chars(df, char_column, plot_spec)

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
            agg_col = plot_spec.group_by or (
                plot_spec.effective_group_by[-1] if plot_spec.effective_group_by else "state"
            )
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

            # For users_only coverage, the count shown in hover should be
            # the per-enduse nonzero sample count, not the group total.
            if (
                plot_spec.coverage == CoverageType.users_only
                and "enduse_nonzero_sample_count" in group_df.columns
            ):
                group_df = group_df.with_columns(
                    pl.col("enduse_nonzero_sample_count").alias("model_count")
                )

            # Sort enduses by canonical RECS national total order (consistent across all views)
            canonical_order = get_enduse_order().get(group_name, [])
            sort_order = [e for e in canonical_order if e in group_df["enduse"].unique().to_list()]
            # Append any enduses not in canonical order (shouldn't happen, but defensive)
            sort_order += [e for e in group_df["enduse"].unique().to_list() if e not in sort_order]

            if sort_order:
                enduse_order = pl.DataFrame({"enduse": sort_order, "enduse_order": range(len(sort_order))})
                group_df = (
                    group_df.join(enduse_order, on="enduse")
                    .sort("enduse_order", maintain_order=True)
                    .drop("enduse_order")
                )

            yield group_df, "enduse", row, col

    return fig, _graph_iterator()

@timed
def split_graph(df: pl.DataFrame, plot_spec: PlotSpec):
    """Split the graph data into subplots based on the plot specification."""
    if (
        plot_spec.layout == Layout.two_column
        and not plot_spec.is_all_enduses
        and "state" in df.columns
    ):
        return split_graph_by_state(df)
    if plot_spec.group_by == "state" and not plot_spec.is_all_enduses and not plot_spec.focus_on:
        return split_graph_by_state(df)
    elif plot_spec.is_all_enduses:
        return split_graph_by_enduse(df, plot_spec)
    else:
        return split_graph_by_char(df, plot_spec)
