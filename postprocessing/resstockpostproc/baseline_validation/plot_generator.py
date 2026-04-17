"""Generate baseline validation plots.

Usage:
    python plot_generator.py                  # generate all plots
    python plot_generator.py --index 5        # generate only plot definition row 5
    python plot_generator.py --index 1-10     # generate rows 1 through 10
    python plot_generator.py --test           # generate test subset only
"""

import argparse
import csv
import logging
import os
import sys
from collections import defaultdict
import time
import traceback
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

from tqdm import tqdm

import polars as pl

from resstockpostproc.baseline_validation.footnotes import (
    dedupe_note_groups,
    get_plot_notes,
    get_table_notes,
)
from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.baseline_validation.plotters import lrd_plotter, recs_plotter
from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    FileType,
    ComparisonDataset,
    ViewType,
    Layout,
    Resolution,
    CoverageType,
    Metric,
    format_group_by,
    ALL_ENDUSES_DISPLAY,
)
from resstockpostproc.baseline_validation.schema.plot_definitions import (
    PlotTemplate,
    RECS_CROSS_FILTER_CHARS,
    generate_all_templates,
    generate_slot_triples,
    SpecFamily,
    _make_related_specs,
    _make_spec,
)
from resstockpostproc.baseline_validation.io_managers.output_manager import save_figure
from resstockpostproc.baseline_validation.io_managers.data_table import (
    _format_source_label,
    generate_data_table_html,
    should_generate_table,
)
from resstockpostproc.baseline_validation.plotters.plot_config import (
    get_second_category_column,
    _resolve_timeseries_column,
)
from resstockpostproc.baseline_validation.utils import ensure_directory
from resstockpostproc.baseline_validation.data_processing.gather_data import get_plot_data, get_base_data
from resstockpostproc.baseline_validation.create_html import init_html_index, append_index_row, finalize_html_index
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow
from resstockpostproc.shared_utils.timing import TimingStats, timed

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s", force=True)
logger = logging.getLogger(__name__)


class _TqdmLoggingHandler(logging.Handler):
    """Routes log output through tqdm.write() so log lines don't clobber the progress bar."""

    def emit(self, record):
        tqdm.write(self.format(record))


OUTPUT_COLUMNS = [
    "Index",
    "Comparison Dataset",
    "Quantity",
    "Metric",
    "Coverage",
    "Filter 1",
    "Filter 2",
    "Group By",
    "Comparison Plot",
    "Data",
]


_GROUPED_VIEW_SUFFIX = " (grouped view)"
_GROUPED_DIFF_VIEW_SUFFIX = " (grouped difference view)"
_STACKED_VIEW_SUFFIX = " (stacked view)"
_STACKED_DIFF_VIEW_SUFFIX = " (stacked difference view)"


def _all_enduses_viz_label(plot_spec: PlotSpec, stacked: bool) -> str:
    """Tab label for grouped/stacked All Enduses variants using standard viz terms."""
    return plot_spec.viz_label(layout="stacked" if stacked else "grouped")


def _stacked_title_from_grouped(grouped_title: str, view: ViewType) -> str:
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


def _to_all_enduses_tall_data(data: pl.DataFrame, spec: PlotSpec) -> pl.DataFrame:
    """Normalize one enduse dataframe to ALL-enduses schema with a leading enduse column."""
    prefix = f"{spec.quantity.value}_"
    rename_map = {c: c.replace(prefix, "all_", 1) for c in data.columns if c.startswith(prefix)}
    if not rename_map:
        return pl.DataFrame()

    tall = data.rename(rename_map).with_columns(pl.lit(spec.display_quantity).alias("enduse"))
    ordered_cols = ["enduse"] + [c for c in tall.columns if c != "enduse"]
    return tall.select(ordered_cols)


def _build_stacked_table_data(
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
        normalized = _to_all_enduses_tall_data(data, spec)
        if not normalized.is_empty():
            frames.append(normalized)

    if not frames:
        return pl.DataFrame()
    return pl.concat(frames, how="diagonal_relaxed")


def _should_generate_stacked_table(
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


def _should_generate_stacked_page_group(
    qty_entries: list[tuple[str, list[tuple[PlotSpec, str]]]],
) -> bool:
    """Decide whether Pass 4 should synthesize an All Enduses stacked page for a group."""
    if len(qty_entries) < 2:
        return False
    first_spec = qty_entries[0][1][0][0]
    return first_spec.comparison_dataset != ComparisonDataset.lrd


# ---------------------------------------------------------------------------
# Spec loading
# ---------------------------------------------------------------------------


def get_test_template_indices(templates: list[PlotTemplate]) -> set[int]:
    """Return 0-based indices of templates covering unique code paths (test subset)."""
    seen: set[tuple] = set()
    test_indices: set[int] = set()
    for i, tmpl in enumerate(templates):
        sig = _template_signature(tmpl)
        if sig not in seen:
            test_indices.add(i)
            seen.add(sig)
    return test_indices


def _template_signature(tmpl: PlotTemplate) -> tuple:
    """Compute code-path signature for template test subset selection."""
    if tmpl.quantity == DataCol.UNITS_COUNT:
        qty_type = "units_count"
    elif tmpl.quantity == DataCol.ALL:
        qty_type = "all_enduses"
    else:
        qty_type = "regular"

    cov_type = "all" if tmpl.coverage == CoverageType.all_units else "users"

    fuel_type = None
    is_total = False
    if tmpl.quantity not in (DataCol.UNITS_COUNT, DataCol.ALL):
        val = tmpl.quantity.value
        for prefix in ("electricity", "natural_gas", "propane", "fuel_oil"):
            if val.startswith(prefix + "_"):
                fuel_type = prefix
                is_total = val == prefix + "_total"
                break

    return (
        tmpl.comparison_dataset, tmpl.resolution, tmpl.view,
        tmpl.aggregation_type, cov_type, qty_type,
        fuel_type, is_total, len(tmpl.eligible_chars),
    )


def _template_display_quantity(tmpl: PlotTemplate) -> str:
    """Return the display quantity name for a template (matches workflow.yaml names)."""
    if tmpl.quantity == DataCol.UNITS_COUNT:
        return "Number of dwelling units"
    if tmpl.quantity == DataCol.ALL:
        return "All Enduses"
    return tmpl.quantity.label


def _build_spec_entries(specs: list[PlotSpec]) -> list[tuple[PlotSpec, str]]:
    """Convert a related-spec family into the spec_entries list used by the plot loop."""
    return [(spec, spec.display_viz_label) for spec in specs]


def _emit_layout_for_final_group(spec: PlotSpec, final_group_by: str | None) -> bool:
    """Decide whether a spec layout should be emitted for a focused row."""
    if spec.layout == Layout.histogram:
        return spec.is_distribution_metric
    if spec.layout == Layout.two_column:
        # two_column splits a state-grouped annual bar into two columns —
        # only meaningful when the final row is actually grouped by state.
        return final_group_by == "state"
    return True


def _build_output_row(main_spec: PlotSpec) -> dict[str, str]:
    """Build the output row dict from a main PlotSpec's display properties."""
    return {
        "Index": "",
        "Comparison Dataset": main_spec.display_comparison_dataset,
        "Quantity": main_spec.display_quantity,
        "Metric": main_spec.display_metric,
        "Coverage": main_spec.display_coverage,
        "Filter 1": "",
        "Filter 2": "",
        "Group By": main_spec.display_group_by,
        "Comparison Plot": "",
        "Data": "",
    }


def _apply_lrd_sidebar_semantics(
    row: dict[str, str],
    display_spec: PlotSpec,
    final_focus_on: tuple[tuple[str, str], ...],
) -> None:
    """Normalize LRD index facets to the simplified Metric/Filter/Group By model."""
    if display_spec.comparison_dataset != ComparisonDataset.lrd:
        return

    # Default LRD sidebar facets are utility-grouped with no explicit filters.
    row["Filter 1"] = ""
    row["Filter 2"] = ""
    row["Group By"] = "Utility"

    if display_spec.resolution == Resolution.hour_of_day_summer:
        row["Filter 1"] = "Season: Summer"
    elif display_spec.resolution == Resolution.hour_of_day_winter:
        row["Filter 1"] = "Season: Winter"
    elif display_spec.resolution == Resolution.hour_of_day_matrix:
        utility = next((val for char, val in final_focus_on if char == "utility"), "")
        row["Filter 1"] = f"Utility: {utility}" if utility else ""
        row["Group By"] = "Month-Day"


def _collect_stacked_notes(
    qty_entries: list[tuple[str, list[tuple[PlotSpec, str]]]],
    note_getter,
) -> list[str] | None:
    """Collect deduplicated notes across stacked quantity entries."""
    return dedupe_note_groups(
        note_getter(entries[0][0])
        for _, entries in qty_entries
        if entries
    )


# ---------------------------------------------------------------------------
# Unified template expansion
# ---------------------------------------------------------------------------


def _expand_templates(
    templates: list[PlotTemplate],
    test_only: bool = False,
) -> list[tuple[SpecFamily, int, list, object, tuple, str | None]]:
    """Expand templates into work items using slot triples.

    For each template, generates all valid (F1, F2, group_by) triples, then
    expands focus values for each dimension. Each work item contains everything
    needed for Pass 2 metadata and Pass 3 plotting.

    Returns list of (spec_family, tmpl_index, spec_entries, focus_val, focus_on, group_by).
    """
    work_items = []

    for tmpl_index, tmpl in enumerate(templates):
        allow_cross = tmpl.comparison_dataset in (ComparisonDataset.recs, ComparisonDataset.eia)
        if allow_cross and tmpl.comparison_dataset == ComparisonDataset.recs and tmpl.resolution == Resolution.year:
            cross_chars = RECS_CROSS_FILTER_CHARS
        else:
            # Monthly RECS / EIA: only state can be a filter
            cross_chars = ("state",) if allow_cross else None
        triples = generate_slot_triples(
            tmpl.eligible_chars,
            allow_cross_filter=allow_cross,
            cross_filter_chars=cross_chars,
        )

        for f1_char, f2_char, group_by in triples:
            # --- Base spec construction ---
            # Use group_by when set, otherwise fall back to f1_char so that
            # Block 2 triples like (state, None, None) get the right
            # group_by for viz labels and data fetching.
            effective_agg = group_by or f1_char
            spec = _make_spec(
                comparison_dataset=tmpl.comparison_dataset,
                quantity=tmpl.quantity,
                resolution=tmpl.resolution,
                aggregation_type=tmpl.aggregation_type,
                coverage=tmpl.coverage,
                group_by=effective_agg,
                view=tmpl.view,
            )
            spec_family = _make_related_specs(spec)
            main_spec = spec_family[0]
            spec_entries = _build_spec_entries(spec_family)

            # ALL enduses: skip any triple with group_by set — can't
            # group a stacked enduse chart by another dimension.
            if tmpl.quantity == DataCol.ALL and group_by is not None:
                continue

            # (None, None, None) = "US Total overview" with no grouping.
            # Synthesise a single-entity spec grouped by the template's
            # primary char, focused on "US Total".  LRD has no US Total
            # concept, so skip it entirely.
            if f1_char is None and group_by is None:
                if tmpl.comparison_dataset == ComparisonDataset.lrd:
                    continue
                # "US Total overview" — fetch state-level data but focus on
                # US Total only.  group_by stays None so downstream code
                # treats this as a single-entity plot (no Group By in index).
                default_char = tmpl.eligible_chars[0]   # "state" for RECS/EIA
                spec = _make_spec(
                    comparison_dataset=tmpl.comparison_dataset,
                    quantity=tmpl.quantity,
                    resolution=tmpl.resolution,
                    aggregation_type=tmpl.aggregation_type,
                    coverage=tmpl.coverage,
                    group_by=default_char,
                    view=tmpl.view,
                )
                spec = spec.model_copy(update={
                    "focus_on": ((default_char, "US Total"),),
                })
                spec_family = _make_related_specs(spec)
                main_spec = spec_family[0]
                spec_entries = _build_spec_entries(spec_family)

            # --- Case 1: No filters (F1=None) → overview only ---
            if f1_char is None:
                # hour_of_day_matrix requires per-utility focus; expand each
                # utility as a separate work item (LRD has no Block 2 triples).
                if tmpl.resolution == Resolution.hour_of_day_matrix:
                    data_key = main_spec.data_key
                    base_data = get_base_data(data_key)
                    col = group_by
                    for val in sorted(v for v in base_data[col].unique().to_list() if v is not None):
                        work_items.append((
                            spec_family, tmpl_index, spec_entries, None,
                            ((group_by, val),), None,
                        ))
                    continue
                # Warm the disk cache so worker processes find the data.
                get_base_data(main_spec.data_key)
                # Pass focus_on from the spec so the US Total focus (set by
                # the (None,None,None) handler above) propagates to plotters.
                work_items.append((
                    spec_family, tmpl_index, spec_entries, None,
                    main_spec.focus_on, group_by,
                ))
                continue

            # --- F1 is set: discover F1 values ---
            # Use any spec with group_by=f1_char to get the data
            f1_lookup_spec = _make_spec(
                comparison_dataset=tmpl.comparison_dataset,
                quantity=tmpl.quantity,
                resolution=tmpl.resolution,
                aggregation_type=tmpl.aggregation_type,
                coverage=tmpl.coverage,
                group_by=f1_char,
                view=tmpl.view,
            )
            f1_data = get_base_data(f1_lookup_spec.data_key)
            f1_col = f1_char
            f1_values = sorted(
                v for v in f1_data[f1_col].unique().to_list()
                if v is not None and v != "US Total"
            )
            if test_only:
                f1_values = f1_values[:1]

            for f1_val in f1_values:
                # --- Case 2: F1 set, F2=None ---
                if f2_char is None:
                    if group_by is not None:
                        # Cross-filter: F1 set + group_by set → overview only
                        filtered_entries = _build_filtered_entries(
                            spec_entries, ((f1_char, f1_val),),
                        )
                        if not filtered_entries:
                            continue
                        # Warm cache for the 2-column group_by DataKey that
                        # workers will request (focus_on col + group_by).
                        get_base_data(filtered_entries[0][0].data_key)
                        focus_on = ((f1_char, f1_val),)
                        work_items.append((
                            spec_family, tmpl_index, filtered_entries, None, focus_on, group_by,
                        ))
                    else:
                        # F1 set, no agg, no F2 → single filtered entity, no grouping
                        focus_on = ((f1_char, f1_val),)
                        filtered_entries = _build_filtered_entries(spec_entries, focus_on)
                        if filtered_entries:
                            work_items.append((
                                spec_family, tmpl_index, filtered_entries, None, focus_on, None,
                            ))
                    continue

                # --- Case 3: F1 set, F2 set (group_by is always None) ---
                f2_lookup_spec = _make_spec(
                    comparison_dataset=tmpl.comparison_dataset,
                    quantity=tmpl.quantity,
                    resolution=tmpl.resolution,
                    aggregation_type=tmpl.aggregation_type,
                    coverage=tmpl.coverage,
                    group_by=f2_char,
                    view=tmpl.view,
                )
                f2_data = get_base_data(f2_lookup_spec.data_key)
                f2_col = f2_char

                if f2_col not in f2_data.columns:
                    continue

                f2_values = sorted(
                    v for v in f2_data[f2_col].unique().to_list()
                    if v is not None and v != "US Total"
                )
                if test_only:
                    f2_values = f2_values[:1]

                for f2_val in f2_values:
                    focus_on = ((f1_char, f1_val), (f2_char, f2_val))
                    work_items.append((
                        spec_family, tmpl_index, spec_entries, None, focus_on, None,
                    ))

    logger.info(f"Template expansion: {len(templates)} templates -> {len(work_items)} work items")
    return work_items


def _build_filtered_entries(
    spec_entries: list[tuple[PlotSpec, str]],
    focus_on: tuple[tuple[str, str], ...],
) -> list[tuple[PlotSpec, str]]:
    """Build spec_entries with focus_on applied (cross-filter)."""
    filtered = []
    for spec, viz_type_str in spec_entries:
        try:
            filtered_spec = spec.model_copy(update={"focus_on": focus_on})
            filtered.append((filtered_spec, viz_type_str))
        except ValueError as e:
            logger.warning(f"Skipping filtered spec: {e}")
            continue
    return filtered


# ---------------------------------------------------------------------------
# Plotting
# ---------------------------------------------------------------------------


def get_plotting_function(comparison_dataset):
    """Return the plotter for a comparison dataset."""
    match comparison_dataset:
        case ComparisonDataset.eia:
            return recs_plotter.create_plot
        case ComparisonDataset.recs:
            return recs_plotter.create_plot
        case ComparisonDataset.lrd:
            return lrd_plotter.create_plot
        case _:
            raise ValueError(f"Unsupported comparison dataset: {comparison_dataset}")


@timed
def _compute_discrepancy(data, plot_spec) -> dict[str, float]:
    """Compute MAPE (%) for each ResStock source.

    MAPE = mean(|ResStock - Ref| / |Ref|) × 100

    Rows with zero reference values are excluded. Returns a dict keyed by
    formatted source label (e.g. "ResStock 2025"), with per-source MAPE (%)
    values. Empty dict when metrics cannot be computed.
    """
    if plot_spec.quantity == DataCol.ALL:
        return {}
    if plot_spec.is_distribution_metric:
        return {}

    # Determine value column
    if plot_spec.quantity == DataCol.UNITS_COUNT:
        val_col = "units_count"
    elif plot_spec.is_penetration_metric:
        val_col = f"{plot_spec.quantity}_percent_users"
    else:
        val_col = f"{plot_spec.quantity}_value"

    if val_col not in data.columns:
        return {}

    # Identify reference and ResStock rows (case-insensitive — source values may
    # be raw like "eia_2018" or display labels like "EIA 2018").
    comparison = plot_spec.comparison_dataset.value
    ref_rows = data.filter(pl.col("source").str.to_lowercase().str.contains(comparison))
    rs_sources = sorted(s for s in data["source"].unique().to_list() if "resstock" in s.lower())

    if len(ref_rows) == 0 or not rs_sources:
        return {}

    # Determine join columns for pairing
    agg_col = get_second_category_column(plot_spec)
    join_cols = [agg_col]
    # Add the timeseries column to the join (e.g., month, hour of day, percent_time)
    ts_col = _resolve_timeseries_column(plot_spec)
    if ts_col and str(ts_col) in data.columns:
        join_cols.append(str(ts_col))

    # Exclude "US Total" from multi-entity overviews to avoid double-counting.
    is_us_total_focus = any(val == "US Total" for _, val in plot_spec.focus_on)
    if not is_us_total_focus:
        ref_rows = ref_rows.filter(pl.col(agg_col) != "US Total")

    ref_selected = ref_rows.select(join_cols + [pl.col(val_col).alias("ref_val")])

    metrics: dict[str, float] = {}
    for rs_source in rs_sources:
        rs_rows = data.filter(pl.col("source") == rs_source)
        if not is_us_total_focus:
            rs_rows = rs_rows.filter(pl.col(agg_col) != "US Total")

        rs_selected = rs_rows.select(join_cols + [pl.col(val_col).alias("rs_val")])
        paired = rs_selected.join(ref_selected, on=join_cols, how="inner")
        paired = paired.drop_nulls(["ref_val", "rs_val"])
        paired = paired.with_columns(
            pl.col("ref_val").fill_nan(0),
            pl.col("rs_val").fill_nan(0),
        )

        if len(paired) == 0:
            continue

        term_df = paired.filter(pl.col("ref_val").abs() > 0).with_columns(
            ((pl.col("rs_val") - pl.col("ref_val")).abs() / pl.col("ref_val").abs()).alias("mape_term")
        )
        if len(term_df) == 0:
            continue

        metrics[_format_source_label(rs_source)] = float(term_df["mape_term"].mean() * 100.0)

    return metrics


def _unnest_list_columns(df):
    """Expand list columns into individual scalar columns.

    E.g. a column ``electricity_total_quartiles`` containing 9-element lists
    becomes ``electricity_total_quartiles_0`` … ``electricity_total_quartiles_8``.
    """
    new_cols = []
    drop_cols = []
    for col_name in df.columns:
        if df[col_name].dtype.base_type() == pl.List:
            list_len = df[col_name].list.len().max()
            if list_len and list_len > 0:
                for i in range(list_len):
                    new_cols.append(pl.col(col_name).list.get(i).alias(f"{col_name}_{i}"))
            drop_cols.append(col_name)
    if new_cols:
        return df.with_columns(new_cols).drop(drop_cols)
    if drop_cols:
        return df.drop(drop_cols)
    return df


@timed
def _save_data_csv(data, data_dir, file_title):
    """Save plot data as CSV, expanding list columns into individual columns."""
    _unnest_list_columns(data).write_csv(data_dir / f"{file_title}.csv")


@timed
def _generate_spec_plots(
    spec_entries,
    output_formats,
    link_format,
    output_base,
    source_labels=None,
) -> tuple[str, str | None] | None:
    """Generate plots for a list of (PlotSpec, viz_type_str) entries.

    Footnotes are computed per-spec via get_plot_notes/get_table_notes so that
    layout-specific notes (e.g. histogram overflow) appear only where relevant.

    Returns (viz_parts_joined, data_rel_path) on success, or None if skipped.
    All file I/O writes to unique per-spec paths (safe for parallel execution).
    """
    # Check if data is available for this combination before generating any plots.
    first_spec = spec_entries[0][0]
    probe_data = get_plot_data(first_spec)
    sources = probe_data["source"].unique().to_list() if not probe_data.is_empty() else []
    has_reference = any("resstock" not in s.lower() for s in sources)
    has_resstock = any("resstock" in s.lower() for s in sources)
    if not has_reference or not has_resstock:
        return None

    viz_parts = []
    data_rel = None
    for idx, (plot_spec, viz_type_str) in enumerate(spec_entries):
        try:
            data = get_plot_data(plot_spec)
            plot_func = get_plotting_function(plot_spec.comparison_dataset)
            fig, title = plot_func(data, plot_spec)
            spec_footnotes = get_plot_notes(plot_spec)
            save_figure(fig, plot_spec, formats=output_formats,
                        footnotes=spec_footnotes, source_labels=source_labels)

            # Build relative path to the enhanced plot file
            path_seg, file_title = plot_spec.file_path_and_name
            rel_path = (
                Path(f"{plot_spec.comparison_dataset} plots ({link_format})") / path_seg / f"{file_title}.{link_format.value}"
            )
            rel_path_str = str(rel_path).replace("\\", "/")
            viz_parts.append(f"{viz_type_str}||{rel_path_str}")

            # Data exports and table links are anchored to the primary spec only.
            if idx == 0 and (
                plot_spec.view in (
                ViewType.value_view,
                ViewType.temp_view,
                )
                or plot_spec.is_penetration_metric
                or plot_spec.is_distribution_metric
            ):
                data_dir = output_base / f"{plot_spec.comparison_dataset} data (csv)" / path_seg
                ensure_directory(data_dir)
                _save_data_csv(data, data_dir, file_title)

                metrics_by_source = _compute_discrepancy(data, plot_spec)

                if should_generate_table(data, plot_spec):
                    table_dir = output_base / f"{plot_spec.comparison_dataset} data (html)" / path_seg
                    ensure_directory(table_dir)
                    table_path = table_dir / f"{file_title}.html"
                    table_depth = len(table_path.relative_to(output_base).parents) - 1
                    plot_rel_from_table = "../" * table_depth + rel_path_str
                    spec_table_footnotes = get_table_notes(plot_spec)
                    generate_data_table_html(
                        data=data,
                        plot_spec=plot_spec,
                        output_path=table_path,
                        plot_rel_path=plot_rel_from_table,
                        metrics_by_source=metrics_by_source,
                        footnotes=spec_table_footnotes,
                        source_labels=source_labels,
                    )
                    rel_table = Path(f"{plot_spec.comparison_dataset} data (html)") / path_seg / f"{file_title}.html"
                    rel_csv = Path(f"{plot_spec.comparison_dataset} data (csv)") / path_seg / f"{file_title}.csv"
                    data_rel = (
                        f"data table||{str(rel_table).replace(chr(92), '/')}"
                        " ;; "
                        f"download csv||{str(rel_csv).replace(chr(92), '/')}"
                    )

        except Exception:
            tb = traceback.format_exc()
            viz_parts.append(f"FAILED: {viz_type_str}||{tb}")

    return " ;; ".join(viz_parts), data_rel



def _worker_init():
    """Process initializer for worker pool — collect timing in memory, use read-only disk cache."""
    from resstockpostproc.shared_utils import caching
    TimingStats.enable_worker_mode()
    caching.CACHE_READ_ONLY = True
    # Suppress worker stdout/stderr — the main process logs progress via tqdm.
    sys.stdout = open(os.devnull, "w")
    sys.stderr = open(os.devnull, "w")


def _worker_run(*args, **kwargs):
    """Wrapper that runs _generate_spec_plots and harvests timing data from the worker process."""
    result = _generate_spec_plots(*args, **kwargs)
    timing_stats, trace_events = TimingStats.harvest_worker_stats()
    return result, timing_stats, trace_events


def _handle_plot_result(sub_key, result, results, csv_path, index_state):
    """Apply a worker's result to shared state (main process only)."""
    if result is None:
        return
    viz_parts_str, data_rel = result
    results[sub_key]["Comparison Plot"] = viz_parts_str
    if data_rel:
        results[sub_key]["Data"] = data_rel
    row = results[sub_key]
    if "FAILED:" in viz_parts_str:
        logger.error(f"FAILED [{sub_key}]: {viz_parts_str}")
    else:
        parts = [row["Comparison Dataset"], row["Quantity"], row["Metric"]]
        if row.get("Filter 1"):
            parts.append(row["Filter 1"])
        if row.get("Filter 2"):
            parts.append(row["Filter 2"])
        logger.info(" | ".join(parts))
    _append_plot_row(csv_path, row)
    append_index_row(index_state, row)


def generate_plots(index=None, test_only=False, parallel=True):
    """Generate baseline validation plots.

    Args:
        index: If provided, only generate plots for this template index (int),
               or a set/list of indices. If None, generate all plots.
        test_only: If True, only generate the test subset with limited focus expansion.
        parallel: If True, use ProcessPoolExecutor for parallel plot generation.
    """
    wall_start = time.perf_counter()
    templates = generate_all_templates()

    if workflow.quantities:
        allowed = set(workflow.quantities)
        templates = [t for t in templates if _template_display_quantity(t) in allowed]
        logger.info(f"Filtered to {len(templates)} templates matching workflow quantities: {sorted(allowed)}")

    if test_only:
        # Select templates that cover unique code paths
        test_idx = get_test_template_indices(templates)
        templates = [t for i, t in enumerate(templates) if i in test_idx]

    if index is not None:
        wanted = set(index) if isinstance(index, (set, list)) else {index}
        templates = [t for i, t in enumerate(templates) if (i + 1) in wanted]

    logger.info(f"Expanding {len(templates)} plot templates...")

    source_labels = workflow.data_source_labels

    output_formats = [FileType(fmt.value) for fmt in workflow.plots.output_formats]
    link_format = FileType.html if FileType.html in output_formats else output_formats[0]
    output_base = Path(workflow.output.output_dir) / workflow.output.run_name
    csv_path = output_base / "comparisons_index.tsv"
    html_path = output_base / "comparisons_index.html"

    # Initialize the CSV (header only) and the HTML index (shell + data dir).
    csv_path.parent.mkdir(parents=True, exist_ok=True)

    # Chrome Trace Event Format — streaming writes for Perfetto UI visualization
    trace_path = output_base / "trace.json"
    TimingStats.start_trace(trace_path)
    with open(csv_path, "w", newline="") as f:
        csv.DictWriter(f, fieldnames=OUTPUT_COLUMNS, delimiter="\t").writeheader()
    index_state = init_html_index(html_path, OUTPUT_COLUMNS)

    # Expand templates into work items via slot triples
    work_items = _expand_templates(templates, test_only=test_only)

    total = len(work_items)
    logger.info(f"Total plot groups to generate: {total}")

    # Build metadata for all work items and prepare plot arguments
    results = {}
    plot_args = []
    stacking_groups: dict[tuple, list[tuple[str, list[tuple[PlotSpec, str]]]]] = defaultdict(list)
    from resstockpostproc.shared_utils.mapping import ABBR2STATE

    for i, (spec_family, tmpl_index, spec_entries, focus_val, focus_on, group_by) in enumerate(work_items, 1):
        main_spec = spec_family[0]

        # Build a unique key for this work item
        agg_suffix = f"_by_{group_by}" if group_by else ""
        if focus_on:
            filter_parts = "_".join(f"{c}_{v}" for c, v in focus_on)
            sub_key = (
                f"f_{filter_parts}_{tmpl_index}{agg_suffix}"
                if focus_val is None
                else f"f_{filter_parts}_{tmpl_index}_{focus_val}"
            )
        else:
            sub_key = (
                f"{tmpl_index}{agg_suffix}"
                if focus_val is None
                else f"{tmpl_index}_{focus_val}"
            )

        # Compute final focus_on for the leaf plot
        final_focus_tuples = list(focus_on)
        if focus_val is not None and group_by is not None:
            final_focus_tuples.append((group_by, focus_val))
        final_focus_on = tuple(final_focus_tuples)
        final_agg = group_by if focus_val is None else None

        # Build a concrete main_spec with the triple's group_by for display
        display_spec = _make_spec(
            comparison_dataset=main_spec.comparison_dataset,
            quantity=main_spec.quantity,
            resolution=main_spec.resolution,
            aggregation_type=main_spec.aggregation_type,
            coverage=main_spec.coverage,
            group_by=group_by or (final_focus_on[0][0] if final_focus_on else "state"),
            view=main_spec.view,
        )

        results[sub_key] = _build_output_row(display_spec)
        results[sub_key]["Index"] = i
        if final_agg is None:
            results[sub_key]["Group By"] = ""
        results[sub_key]["Comparison Plot"] = ""

        if final_focus_on:
            for idx, (char, value) in enumerate(final_focus_on):
                if value == "US Total":
                    # US Total is represented as empty filter (same as "(None)")
                    # to stay consistent with overview rows that have no filter.
                    results[sub_key][f"Filter {idx + 1}"] = ""
                else:
                    display = ABBR2STATE.get(value, value) if char == "state" else value
                    category = format_group_by(char)
                    results[sub_key][f"Filter {idx + 1}"] = f"{category}: {display}"

        _apply_lrd_sidebar_semantics(results[sub_key], display_spec, final_focus_on)

        focused_entries = []
        for spec, _ in spec_entries:
            focused_spec = spec.model_copy(update={
                "focus_on": final_focus_on,
                "group_by": final_agg,
            })
            if not _emit_layout_for_final_group(focused_spec, final_agg):
                continue
            viz_label = focused_spec.display_viz_label
            if focused_spec.quantity == DataCol.ALL:
                viz_label = _all_enduses_viz_label(focused_spec, stacked=False)
            focused_entries.append((focused_spec, viz_label))

        if not focused_entries:
            continue

        plot_args.append((sub_key, focused_entries))

        # Collect spec pairs for stacking into "All Enduses (Stacked)" pages.
        # Each group entry stores (qty_label, focused_entries) — the same
        # (PlotSpec, viz_label) list used for individual plot generation,
        # so the stacker knows exactly which views exist for each quantity.
        # Skip ALL (already a stacked enduse chart) and UNITS_COUNT (not an enduse).
        if main_spec.quantity not in (DataCol.ALL, DataCol.UNITS_COUNT):
            group_key = (
                results[sub_key]["Comparison Dataset"],
                results[sub_key]["Metric"],
                results[sub_key]["Coverage"],
                results[sub_key]["Filter 1"],
                results[sub_key]["Filter 2"],
                results[sub_key]["Group By"],
            )
            stacking_groups[group_key].append((
                display_spec.display_quantity,
                focused_entries,
            ))

    # Pass 3: Generate plots — parallel or sequential
    common_kwargs = dict(output_formats=output_formats, link_format=link_format,
                         output_base=output_base, source_labels=source_labels or None)

    # Swap logging to tqdm-aware handler so log lines render above the progress bar
    root_logger = logging.getLogger()
    original_handlers = root_logger.handlers[:]
    tqdm_handler = _TqdmLoggingHandler()
    tqdm_handler.setFormatter(logging.Formatter("%(asctime)s - %(levelname)s - %(message)s"))
    root_logger.handlers = [tqdm_handler]

    pbar = tqdm(total=total, desc="Generating plots", unit="plot",
                bar_format="{desc}: {percentage:6.2f}%|{bar}| {n_fmt}/{total_fmt} [{elapsed}<{remaining}, {rate_fmt}]")
    try:
        if parallel:
            max_workers = max(2, min(8, (os.cpu_count() or 4) - 2))
            logger.info(f"Using {max_workers} worker processes")
            futures = {}
            with ProcessPoolExecutor(max_workers=max_workers, initializer=_worker_init) as executor:
                for sub_key, focused_entries in plot_args:
                    future = executor.submit(
                        _worker_run, focused_entries, **common_kwargs,
                    )
                    futures[future] = sub_key
                for future in as_completed(futures):
                    sub_key = futures[future]
                    try:
                        result, worker_stats, worker_events = future.result()
                        TimingStats.merge_worker_stats(worker_stats, worker_events)
                    except Exception:
                        logger.error(f"Worker exception for [{sub_key}]:\n{traceback.format_exc()}")
                        result = None
                    _handle_plot_result(sub_key, result, results, csv_path, index_state)
                    pbar.update(1)
        else:
            for sub_key, focused_entries in plot_args:
                result = _generate_spec_plots(
                    focused_entries, **common_kwargs,
                )
                _handle_plot_result(sub_key, result, results, csv_path, index_state)
                pbar.update(1)
    finally:
        pbar.close()
        root_logger.handlers = original_handlers

    # Pass 4: Assemble synthetic "All Enduses (Stacked)" pages by combining
    # the raw Plotly HTML files already written in Pass 3. View-agnostic: for
    # each view position in focused_entries, transpose across quantities.
    from resstockpostproc.baseline_validation.io_managers.html_utils import postprocess_plot_html
    eligible_groups = {k: v for k, v in stacking_groups.items() if _should_generate_stacked_page_group(v)}
    stacked_count = 0
    stacked_table_data_cache: dict[tuple, pl.DataFrame] = {}

    def _raw_path(spec: PlotSpec) -> Path:
        ps, ft = spec.file_path_and_name
        return output_base / f"{spec.comparison_dataset} plots ({link_format})" / ps / f"{ft}.raw.{link_format.value}"

    stacked_pbar = tqdm(
        eligible_groups.items(), total=len(eligible_groups),
        desc="Generating stacked pages", unit="page",
        bar_format="{desc}: {percentage:6.2f}%|{bar}| {n_fmt}/{total_fmt} [{elapsed}<{remaining}]",
    )
    for group_key, qty_entries in stacked_pbar:
        ds, metric, coverage, f1, f2, gb = group_key
        first_spec = qty_entries[0][1][0][0]
        path_seg = first_spec.file_path_and_name[0]
        if gb in ("State", ""):
            scale_x, scale_y = 1.0, 1.0
        else:
            scale_x, scale_y = 0.75, 0.5

        # Deduplicated footnotes across all quantities
        plot_notes = _collect_stacked_notes(qty_entries, get_plot_notes)
        table_notes = _collect_stacked_notes(qty_entries, get_table_notes)

        # One stacked page per view position (position 0 = main, 1 = extra, ...)
        viz_parts = []
        stacked_outputs: list[tuple[int, PlotSpec, str]] = []
        for i, _ in enumerate(qty_entries[0][1]):
            view_spec = qty_entries[0][1][i][0]
            paths = [p for p in (_raw_path(e[i][0]) for _, e in qty_entries if i < len(e)) if p.exists()]
            if len(paths) < 2:
                continue

            all_view_spec = view_spec.model_copy(update={"quantity": DataCol.ALL})
            _, grouped_title = all_view_spec.file_path_and_name
            title = _stacked_title_from_grouped(grouped_title, all_view_spec.view)
            ds_dir = f"{first_spec.comparison_dataset} plots ({link_format})"
            out = output_base / ds_dir / path_seg / f"{title}.{link_format.value}"
            ensure_directory(out.parent)
            postprocess_plot_html(
                paths, output_path=out, footnotes=plot_notes,
                source_labels=source_labels, scale_x=scale_x, scale_y=scale_y,
                comparison_dataset=first_spec.comparison_dataset.value,
            )
            rel = Path(ds_dir) / path_seg / f"{title}.{link_format.value}"
            rel_str = str(rel).replace("\\", "/")
            stacked_label = _all_enduses_viz_label(all_view_spec, stacked=True)
            viz_parts.append(f"{stacked_label}||{rel_str}")
            stacked_outputs.append((i, all_view_spec, rel_str))
            stacked_count += 1

        if viz_parts:
            data_rel = ""
            if stacked_outputs and _should_generate_stacked_table(
                gb, first_spec.comparison_dataset, first_spec.resolution, first_spec.aggregation_type
            ):
                # Build stacked data tables for grouped rows, plus selected
                # ungrouped rows (EIA and certain RECS cases).
                table_view_index, table_spec, table_rel_plot = next(
                    (o for o in stacked_outputs if o[1].view == ViewType.value_view),
                    stacked_outputs[0],
                )
                stacked_data = _build_stacked_table_data(
                    qty_entries, table_view_index, stacked_table_data_cache
                )
                if not stacked_data.is_empty() and should_generate_table(stacked_data, table_spec):
                    table_dir = output_base / f"{table_spec.comparison_dataset} data (html)" / path_seg
                    ensure_directory(table_dir)
                    data_dir = output_base / f"{table_spec.comparison_dataset} data (csv)" / path_seg
                    ensure_directory(data_dir)

                    table_file_title = Path(table_rel_plot).stem
                    table_path = table_dir / f"{table_file_title}.html"
                    table_depth = len(table_path.relative_to(output_base).parents) - 1
                    plot_rel_from_table = "../" * table_depth + table_rel_plot

                    _save_data_csv(stacked_data, data_dir, table_file_title)
                    generate_data_table_html(
                        data=stacked_data,
                        plot_spec=table_spec,
                        output_path=table_path,
                        plot_rel_path=plot_rel_from_table,
                        metrics_by_source={},
                        footnotes=table_notes,
                        source_labels=source_labels,
                        csv_download_filename=f"{table_file_title}.csv",
                        include_discrepancy_metrics=False,
                    )
                    rel_table = Path(f"{table_spec.comparison_dataset} data (html)") / path_seg / f"{table_file_title}.html"
                    rel_csv = Path(f"{table_spec.comparison_dataset} data (csv)") / path_seg / f"{table_file_title}.csv"
                    data_rel = (
                        f"data table||{str(rel_table).replace(chr(92), '/')}"
                        " ;; "
                        f"download csv||{str(rel_csv).replace(chr(92), '/')}"
                    )

            row = {
                "Index": "",
                "Comparison Dataset": ds,
                # Keep stacked synthetic rows under the same Quantity facet so both
                # regular and stacked variants appear together in the explorer.
                "Quantity": ALL_ENDUSES_DISPLAY,
                "Metric": metric,
                "Coverage": coverage,
                "Filter 1": f1,
                "Filter 2": f2,
                "Group By": gb,
                "Comparison Plot": " ;; ".join(viz_parts),
                "Data": data_rel,
            }
            results[f"stacked_{stacked_count}"] = row
            _append_plot_row(csv_path, row)
            append_index_row(index_state, row)

    stacked_pbar.close()
    if stacked_count:
        logger.info(f"Generated {stacked_count} synthetic 'All Enduses (Stacked)' pages")

    # Clean up raw Plotly HTML files — only the post-processed versions are needed.
    for ds in ComparisonDataset:
        plots_dir = output_base / f"{ds} plots ({link_format})"
        if plots_dir.exists():
            for raw_html in plots_dir.rglob(f"*.raw.{link_format.value}"):
                raw_html.unlink()

    # Write the final HTML with static script tags for all shards
    finalize_html_index(index_state)

    # Summary — count individual viz entries (comma-separated in "Comparison Plot")
    ok = 0
    failed = 0
    for r in results.values():
        for part in r["Comparison Plot"].split(" ;; "):
            part = part.strip()
            if not part:
                continue
            if part.startswith("FAILED:"):
                failed += 1
            else:
                ok += 1
    logger.info(f"Done: {ok} succeeded, {failed} failed, {ok + failed} total")

    # Timing profiling summary
    wall_elapsed = time.perf_counter() - wall_start
    logger.info(
        "\n=== Timing Summary ===\n%s\n%s\nTotal wall clock time: %.2fs",
        TimingStats.summary(),
        "-" * 95,
        wall_elapsed,
    )

    # Close trace file
    TimingStats.stop_trace()
    logger.info(f"Trace file: {trace_path} (open in https://ui.perfetto.dev)")


@timed
def _append_plot_row(tsv_path, row_dict):
    """Append a single result row to the TSV index (O(1) append)."""
    with open(tsv_path, "a", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=OUTPUT_COLUMNS, delimiter="\t")
        writer.writerow(row_dict)


# ---------------------------------------------------------------------------
# Convenience wrappers
# ---------------------------------------------------------------------------


def generate_eia_plots():
    """Generate only EIA plots."""
    all_tmpls = generate_all_templates()
    eia_indices = {i + 1 for i, t in enumerate(all_tmpls) if t.comparison_dataset == ComparisonDataset.eia}
    generate_plots(index=eia_indices)


def generate_recs_plots():
    """Generate only RECS plots."""
    all_tmpls = generate_all_templates()
    recs_indices = {i + 1 for i, t in enumerate(all_tmpls) if t.comparison_dataset == ComparisonDataset.recs}
    generate_plots(index=recs_indices)


def generate_lrd_plots():
    """Generate only LRD plots."""
    all_tmpls = generate_all_templates()
    lrd_indices = {i + 1 for i, t in enumerate(all_tmpls) if t.comparison_dataset == ComparisonDataset.lrd}
    generate_plots(index=lrd_indices)


def generate_test_plots():
    """Generate only test subset plots (limited focus expansion)."""
    generate_plots(test_only=True)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def parse_index_arg(index_str):
    """Parse index argument: single int, range (e.g. '1-10'), or comma-separated."""
    indices = set()
    for part in index_str.split(","):
        part = part.strip()
        if "-" in part:
            start, end = part.split("-", 1)
            indices.update(range(int(start), int(end) + 1))
        else:
            indices.add(int(part))
    return indices


def main():
    parser = argparse.ArgumentParser(description="Generate baseline validation plots")
    parser.add_argument(
        "--index", type=str, default=None, help="Plot definition index to generate (e.g. '5', '1-10', '1,3,5')"
    )
    parser.add_argument(
        "--test", action="store_true", default=False,
        help="Generate only test subset plots (limited focus expansion)",
    )
    parser.add_argument(
        "--no-parallel", action="store_true", default=False,
        help="Disable parallel plot generation (run sequentially)",
    )
    args = parser.parse_args()

    index = parse_index_arg(args.index) if args.index else None
    generate_plots(index=index, test_only=args.test, parallel=not args.no_parallel)
    return 0


if __name__ == "__main__":
    sys.exit(main())
