"""Synthetic All Enduses stacked-page generation helpers.

Extracted from plot_generator.py in refactor plan V2 step 3.4. These helpers
decide when to synthesize an All Enduses stacked page from per-quantity
grouped plots, reshape per-quantity data into the tall ALL-enduses schema,
assemble the combined table data, and collect deduplicated footnotes.
"""

from __future__ import annotations

import polars as pl

from resstockpostproc.baseline_validation.footnotes import dedupe_note_groups
from resstockpostproc.baseline_validation.data_processing.gather_data import get_plot_data
from resstockpostproc.baseline_validation.schema.plot_spec import (
    ComparisonDataset,
    Metric,
    PlotSpec,
    Resolution,
    ViewType,
)


_GROUPED_VIEW_SUFFIX = " (grouped view)"
_GROUPED_DIFF_VIEW_SUFFIX = " (grouped difference view)"
_STACKED_VIEW_SUFFIX = " (stacked view)"
_STACKED_DIFF_VIEW_SUFFIX = " (stacked difference view)"


def all_enduses_viz_label(plot_spec: PlotSpec, stacked: bool) -> str:
    """Tab label for grouped/stacked All Enduses variants using standard viz terms."""
    return plot_spec.viz_label(layout="stacked" if stacked else "grouped")


def stacked_title_from_grouped(grouped_title: str, view: ViewType) -> str:
    """Convert an ALL-enduses grouped filename title into stacked title."""
    if view == ViewType.diff_view:
        if grouped_title.endswith(_GROUPED_DIFF_VIEW_SUFFIX):
            return grouped_title.removesuffix(_GROUPED_DIFF_VIEW_SUFFIX) + _STACKED_DIFF_VIEW_SUFFIX
        if grouped_title.endswith(" (difference view)"):
            return grouped_title.removesuffix(" (difference view)") + _STACKED_DIFF_VIEW_SUFFIX
        return grouped_title + _STACKED_DIFF_VIEW_SUFFIX
    if grouped_title.endswith(_GROUPED_VIEW_SUFFIX):
        return grouped_title.removesuffix(_GROUPED_VIEW_SUFFIX) + _STACKED_VIEW_SUFFIX
    return grouped_title + _STACKED_VIEW_SUFFIX


def _stacked_table_cache_key(spec: PlotSpec) -> tuple:
    """Hashable key for caching stacked-table source data per PlotSpec."""
    return (
        spec.comparison_dataset.value,
        spec.quantity.value,
        spec.resolution.value,
        spec.aggregation_type.value,
        spec.coverage.value,
        spec.group_by,
        spec.focus_on,
        spec.view.value if spec.view else "",
    )


def to_all_enduses_tall_data(data: pl.DataFrame, spec: PlotSpec) -> pl.DataFrame:
    """Normalize one enduse dataframe to ALL-enduses schema with a leading enduse column."""
    prefix = f"{spec.quantity.value}_"
    rename_map = {c: c.replace(prefix, "all_", 1) for c in data.columns if c.startswith(prefix)}
    if not rename_map:
        return pl.DataFrame()

    tall = data.rename(rename_map).with_columns(pl.lit(spec.display_quantity).alias("enduse"))
    ordered_cols = ["enduse"] + [c for c in tall.columns if c != "enduse"]
    return tall.select(ordered_cols)


def build_stacked_table_data(
    qty_entries: list[tuple[str, list[tuple[PlotSpec, str]]]],
    view_index: int,
    data_cache: dict[tuple, pl.DataFrame],
) -> pl.DataFrame:
    """Build stacked ALL-enduses table data by concatenating quantity data vertically."""
    frames: list[pl.DataFrame] = []
    for _, entries in qty_entries:
        if view_index >= len(entries):
            continue
        spec = entries[view_index][0]
        cache_key = _stacked_table_cache_key(spec)
        data = data_cache.get(cache_key)
        if data is None:
            data = get_plot_data(spec)
            data_cache[cache_key] = data
        if data.is_empty():
            continue
        normalized = to_all_enduses_tall_data(data, spec)
        if not normalized.is_empty():
            frames.append(normalized)

    if not frames:
        return pl.DataFrame()
    return pl.concat(frames, how="diagonal_relaxed")


def should_generate_stacked_table(
    group_by_label: str,
    comparison_dataset: ComparisonDataset,
    resolution: Resolution,
    aggregation_type: Metric,
) -> bool:
    """Decide whether synthetic stacked All Enduses rows should include table data."""
    # Always include for grouped rows.
    if bool(group_by_label):
        return True

    # For EIA, include ungrouped (U.S. Total / no group_by) stacked rows.
    if comparison_dataset == ComparisonDataset.eia:
        return True

    # For RECS, include ungrouped rows when:
    # - resolution is not annual, or
    # - metric is distribution.
    if comparison_dataset == ComparisonDataset.recs:
        return resolution != Resolution.year or aggregation_type == Metric.distribution

    return False


def should_generate_stacked_page_group(
    qty_entries: list[tuple[str, list[tuple[PlotSpec, str]]]],
) -> bool:
    """Decide whether Pass 4 should synthesize an All Enduses stacked page for a group."""
    if len(qty_entries) < 2:
        return False
    first_spec = qty_entries[0][1][0][0]
    return first_spec.comparison_dataset != ComparisonDataset.lrd


def collect_stacked_notes(
    qty_entries: list[tuple[str, list[tuple[PlotSpec, str]]]],
    note_getter,
) -> list[str] | None:
    """Collect deduplicated notes across stacked quantity entries."""
    return dedupe_note_groups(
        note_getter(entries[0][0])
        for _, entries in qty_entries
        if entries
    )
