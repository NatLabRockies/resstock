"""Data-shaping helpers for baseline validation data tables.

Extracted from data_table.py in refactor plan V2 step 4.1. This module owns
the transformation pipeline that turns a raw plot DataFrame into the pivoted
shape consumed by the HTML page builder.
"""

from __future__ import annotations

import polars as pl

from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    CoverageType,
    Resolution,
    ViewType,
)
from resstockpostproc.baseline_validation.plotters.plot_config import (
    get_second_category_column,
)
from resstockpostproc.baseline_validation.plot_semantics import (
    QUARTILE_INDICES,
    quartile_list_column,
    resolve_timeseries_column,
)
from resstockpostproc.shared_utils.timing import timed


# Columns and suffixes to always drop from the table
_DROP_SUFFIXES = (
    "_rse",
    "_upper_bound",
    "_lower_bound",
    "_value_resolution",
    "_quartiles",           # raw list columns (pre-unnest)
    "_nonzero_quartiles",   # raw list columns (pre-unnest)
)

_DROP_EXACT = {
    "timestamp",
    "rows_per_sample",
    "customers",
    "natural_gas_total_customers",
    "outdoor_drybulb_temp_value",
    "percent_time",
    "utility_vertical",
    "eiaid",
}

_DROP_CONTAINS = (
    "_quartiles_",
    "_nonzero_quartiles_",
)

# Per-enduse wide columns start with one of these fuel prefixes.
_FUEL_PREFIXES_TUPLE = ("electricity_", "natural_gas_", "propane_", "fuel_oil_")


def melt_enduse_columns(data: pl.DataFrame) -> pl.DataFrame:
    """Melt wide per-enduse columns into tall form with an 'enduse' label column.

    Each row (entity, source) becomes N rows (entity, source, enduse). Enduse
    columns are renamed from their fuel/enduse prefix to a single ``all_`` prefix
    (matching ``DataCol.ALL.value``), so downstream logic keyed on
    ``plot_spec.quantity`` continues to work unchanged.

    Used only for ALL-quantity RECS plots.
    """
    enduse_prefixes = sorted({
        c.removesuffix("_value")
        for c in data.columns
        if c.startswith(_FUEL_PREFIXES_TUPLE) and c.endswith("_value")
    })
    if not enduse_prefixes:
        return data

    id_cols = [c for c in data.columns if not c.startswith(_FUEL_PREFIXES_TUPLE)]

    def _label(prefix: str) -> str:
        try:
            return DataCol(prefix).label
        except ValueError:
            return prefix.replace("_", " ").title()

    dfs = []
    for prefix in enduse_prefixes:
        cols = [c for c in data.columns if c.startswith(f"{prefix}_")]
        rename_map = {c: c.replace(f"{prefix}_", "all_", 1) for c in cols}
        sub = data.select(id_cols + cols).rename(rename_map)
        # Cast numeric 'all_*' columns to Float64 — sparse enduses can produce
        # Int64 nulls that break diagonal_relaxed concat schema unification.
        cast_cols = [
            c for c in sub.columns
            if c.startswith("all_") and sub[c].dtype.is_numeric()
        ]
        sub = sub.with_columns(pl.col(c).cast(pl.Float64) for c in cast_cols)
        sub = sub.with_columns(pl.lit(_label(prefix)).alias("enduse"))
        dfs.append(sub)

    return pl.concat(dfs, how="diagonal_relaxed")


def normalize_model_count_columns(data: pl.DataFrame, plot_spec: PlotSpec) -> pl.DataFrame:
    """Align table count columns with displayed plot semantics.

    For users_only tables, model_count is the display count shown in hover/table
    labels. Non-ALL plots already normalize it upstream; ALL-enduse tables still
    carry per-enduse nonzero counts as ``all_nonzero_sample_count`` after melt.
    Normalize model_count from the appropriate nonzero count when present, then
    drop raw ``*_nonzero_sample_count`` columns so tables do not expose duplicate
    or stale count columns.

    Also scales units_count to the users-only subset (units_count * percent_users
    / 100) so "Dwelling Units" stays in sync with "Number of Models/Samples".
    """
    nonzero_cols = [c for c in data.columns if c.endswith("_nonzero_sample_count")]
    if not nonzero_cols:
        return data

    if plot_spec.coverage == CoverageType.users_only:
        quantity = plot_spec.quantity
        target_col = "all_nonzero_sample_count" if plot_spec.is_all_enduses else f"{quantity}_nonzero_sample_count"
        if target_col in data.columns:
            replacement = pl.col(target_col).cast(pl.Int64, strict=False)
            if "model_count" in data.columns:
                data = data.with_columns(
                    replacement.fill_null(pl.col("model_count").cast(pl.Int64, strict=False)).alias("model_count")
                )
            else:
                data = data.with_columns(replacement.alias("model_count"))

        percent_users_col = (
            "all_percent_users" if plot_spec.is_all_enduses else f"{quantity}_percent_users"
        )
        if "units_count" in data.columns and percent_users_col in data.columns:
            data = data.with_columns(
                (pl.col("units_count") * pl.col(percent_users_col) / 100.0)
                .round(0)
                .alias("units_count")
            )

    return data.drop(nonzero_cols)


def extract_quartile_columns(data: pl.DataFrame, plot_spec: PlotSpec) -> pl.DataFrame:
    """Extract scalar min/q1/median/q3/max columns from the raw quartile list column.

    Uses QUARTILE_INDICES from plot_semantics; parallels
    box_plot_data.add_quartile_cols which emits a different column shape.
    Coverage selects which list column to read: all_units → ``_quartiles``;
    users_only → ``_nonzero_quartiles``.
    """
    quantity = plot_spec.quantity
    list_col = quartile_list_column(quantity, plot_spec.coverage)
    if list_col not in data.columns:
        return data
    return data.with_columns([
        pl.col(list_col).list.get(idx).cast(pl.Float64).alias(f"{quantity}_{name}")
        for idx, name in QUARTILE_INDICES
    ])

@timed
def filter_columns(data: pl.DataFrame, plot_spec: PlotSpec) -> pl.DataFrame:
    """Drop irrelevant columns, keeping only comparison-meaningful ones."""
    # Protect structural columns (join keys) from being dropped
    entity_col = get_second_category_column(plot_spec)
    ts_col = resolve_timeseries_column(plot_spec)
    structural = {entity_col, "source"}
    if ts_col:
        structural.add(str(ts_col))
    if "enduse" in data.columns:
        structural.add("enduse")

    keep_percent_users = plot_spec.is_penetration_metric or plot_spec.coverage == CoverageType.users_only
    keep_model_count = any(
        plot_spec.model_count_display_label_for_source(str(source)) is not None
        for source in data["source"].unique(maintain_order=True).to_list()
    )

    drop_cols = []
    for col in data.columns:
        if col in structural:
            continue

        # Exact matches
        if col in _DROP_EXACT:
            drop_cols.append(col)
            continue

        # Suffix matches
        if any(col.endswith(s) for s in _DROP_SUFFIXES):
            drop_cols.append(col)
            continue

        # Substring matches (quartiles)
        if any(sub in col for sub in _DROP_CONTAINS):
            drop_cols.append(col)
            continue

        # Drop percent_users columns unless relevant
        if not keep_percent_users and ("_percent_users" in col):
            drop_cols.append(col)
            continue

        if col == "model_count" and not keep_model_count:
            drop_cols.append(col)
            continue

        # Drop units_count_percent_difference unless the main quantity is dwelling units
        if col == "units_count_percent_difference" and plot_spec.quantity != DataCol.UNITS_COUNT:
            drop_cols.append(col)
            continue

        # For value_view, drop percent_users percent_difference — only the value diff matters
        if plot_spec.view == ViewType.value_view and col.endswith("_percent_users_percent_difference"):
            drop_cols.append(col)
            continue

        # For penetration views, drop _value columns — only percent_users matters
        if plot_spec.is_penetration_metric and col.endswith(("_value", "_value_percent_difference")):
            drop_cols.append(col)
            continue

        # For distribution view, drop the single percent_difference column
        # (it compares means, not distributions, and is unintuitive next to quartiles).
        if plot_spec.is_distribution_metric and col.endswith("_percent_difference"):
            drop_cols.append(col)
            continue

        # For hour_of_day_matrix, utility/month/day_type are already encoded in
        # the combined month_daytype entity column + focus_on, so per-source
        # copies of these split columns carry no new information.
        if plot_spec.resolution == Resolution.hour_of_day_matrix and col in {"utility", "month", "day_type"}:
            drop_cols.append(col)
            continue

    return data.drop(drop_cols)

@timed
def pivot_by_source(
    data: pl.DataFrame,
    plot_spec: PlotSpec,
) -> tuple[pl.DataFrame, str, list[str]]:
    """Pivot long-format data to wide format, with sources as column groups.

    Each ResStock source becomes its own column group with:
      - "{rs_label}: {value_col}"
      - "{rs_label} Difference (%)" (from the existing percent_difference column)

    The reference (e.g. EIA 2018) gets its own group: "{ref_label}: {value_col}".

    Returns:
        (pivoted_df, ref_label, rs_labels) where rs_labels is a sorted list like
        ["ResStock 2024", "ResStock 2025"].

    """
    entity_col = get_second_category_column(plot_spec)
    ts_col = resolve_timeseries_column(plot_spec)

    # Identify join columns (dimensions)
    join_cols = [entity_col]
    if ts_col and str(ts_col) in data.columns:
        join_cols.append(str(ts_col))
    if "enduse" in data.columns:
        join_cols.append("enduse")

    # Identify all source labels (source values are already human-readable
    # display labels from apply_plot_spec, e.g. "EIA 2018", "ResStock 2025").
    comparison_val = plot_spec.comparison_dataset.value
    sources = data["source"].unique(maintain_order=True).to_list()
    ref_sources = [s for s in sources if comparison_val in s.lower()]
    ref_label = ref_sources[0] if ref_sources else comparison_val.upper()
    rs_labels = sorted(s for s in sources if "resstock" in s.lower())

    # Split by source (case-insensitive matching)
    ref_df = data.filter(pl.col("source").str.to_lowercase().str.contains(comparison_val))

    # Determine value columns to pivot (everything that's not a join col or source)
    skip_cols = set(join_cols) | {"source"}
    value_cols = [c for c in data.columns if c not in skip_cols]
    diff_cols = [c for c in value_cols if c.endswith("_percent_difference")]
    non_diff_cols = [c for c in value_cols if c not in diff_cols]

    # Select and rename reference columns (no diff cols on the reference side)
    ref_available = [c for c in non_diff_cols if c in ref_df.columns]
    pivoted = ref_df.select(
        join_cols + [pl.col(c).alias(f"{ref_label}: {c}") for c in ref_available]
    )

    # Add each ResStock source as its own column group
    for rs_label in rs_labels:
        rs_df = data.filter(pl.col("source") == rs_label)
        rs_non_diff = [c for c in non_diff_cols if c in rs_df.columns]
        rs_diff_available = [c for c in diff_cols if c in rs_df.columns]

        rs_select_exprs = (
            [pl.col(c) for c in join_cols]
            + [pl.col(c).alias(f"{rs_label}: {c}") for c in rs_non_diff]
            + [pl.col(c).alias(f"{rs_label} Difference (%): {c}") for c in rs_diff_available]
        )
        rs_renamed = rs_df.select(rs_select_exprs)
        pivoted = pivoted.join(rs_renamed, on=join_cols, how="full", coalesce=True, maintain_order="left_right")

    return pivoted, ref_label, rs_labels
