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
import math
import os
import sys
import time
import traceback
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

from tqdm import tqdm
import yaml

import polars as pl

from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.baseline_validation.plotters import lrd_plotter, recs_plotter
from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    FileType,
    TruthSource,
    ViewType,
    Resolution,
    CoverageType,
    format_aggregation_level,
)
from resstockpostproc.baseline_validation.schema.plot_definitions import (
    PlotTemplate,
    RECS_CROSS_FILTER_CHARS,
    generate_all_templates,
    generate_slot_triples,
    is_highlight,
    SpecPair,
    _make_pair,
    _make_spec,
)
from resstockpostproc.baseline_validation.io_managers.output_manager import save_figure
from resstockpostproc.baseline_validation.io_managers.data_table import (
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

SCHEMA_DIR = Path(__file__).parent / "schema"
FOOTNOTES_YAML = SCHEMA_DIR / "plot_footnotes.yaml"


def _load_footnote_rules() -> list[dict]:
    """Load cascading footnote rules from plot_footnotes.yaml."""
    if not FOOTNOTES_YAML.exists():
        return []
    with open(FOOTNOTES_YAML) as f:
        data = yaml.safe_load(f) or {}
    return data.get("notes", [])


_FOOTNOTE_MATCH_KEYS = {
    "truth_source": "Truth Source",
    "quantity": "Quantity",
    "metric": "Metric",
}


def _resolve_footnotes(footnote_rules: list[dict], row: dict, context: str | None = None) -> list[str]:
    """Collect all notes whose attribute matchers match the given row.

    Each rule specifies attribute matchers (truth_source, quantity, metric).
    A rule matches when ALL its specified attributes equal the row values.
    Unspecified attributes act as wildcards.
    """
    matched = []
    for rule in footnote_rules:
        rule_context = rule.get("context")
        if context and rule_context and rule_context != context:
            continue

        if all(
            row.get(tsv_col, "").strip() == str(rule[yaml_key])
            for yaml_key, tsv_col in _FOOTNOTE_MATCH_KEYS.items()
            if yaml_key in rule
        ):
            matched.append(rule["note"].strip())
    return matched


OUTPUT_COLUMNS = [
    "Index",
    "Highlight",
    "Truth Source",
    "Quantity",
    "Metric",
    "Filter 1",
    "Filter 2",
    "Group By",
    "Comparison Plot",
    "Data",
]


_MULTI_ENTITY_PREFIXES = ("stack of ", "tilemap ", "grouped ")


def _simplify_viz_label(viz_type: str) -> str:
    """Strip multi-entity prefixes for focused (single-entity) plots."""
    for prefix in _MULTI_ENTITY_PREFIXES:
        if viz_type.startswith(prefix):
            return viz_type[len(prefix):]
    return viz_type


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
        tmpl.truth_source, tmpl.resolution, tmpl.view,
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


def _build_spec_entries(main_spec: PlotSpec, extra_spec: PlotSpec | None) -> list[tuple[PlotSpec, str]]:
    """Convert a SpecPair into the spec_entries list used by the plot loop."""
    entries = [(main_spec, main_spec.display_viz_label)]
    if extra_spec is not None:
        entries.append((extra_spec, extra_spec.display_viz_label))
    return entries


def _build_output_row(main_spec: PlotSpec) -> dict[str, str]:
    """Build the output row dict from a main PlotSpec's display properties."""
    return {
        "Index": "",
        "Highlight": "Yes" if is_highlight(main_spec) else "",
        "Truth Source": main_spec.truth_source.value,
        "Quantity": main_spec.display_quantity,
        "Metric": main_spec.display_metric,
        "Filter 1": "",
        "Filter 2": "",
        "Group By": main_spec.display_group_by,
        "Comparison Plot": "",
        "Data": "",
    }


def _footnote_row(main_spec: PlotSpec) -> dict[str, str]:
    """Build a dict for footnote matching from a PlotSpec."""
    return {
        "Truth Source": main_spec.truth_source.value,
        "Quantity": main_spec.display_quantity,
        "Metric": main_spec.display_metric,
    }


# ---------------------------------------------------------------------------
# Unified template expansion
# ---------------------------------------------------------------------------


def _expand_templates(
    templates: list[PlotTemplate],
    test_only: bool = False,
) -> list[tuple[SpecPair, int, list, object, tuple, str | None]]:
    """Expand templates into work items using slot triples.

    For each template, generates all valid (F1, F2, agg_level) triples, then
    expands focus values for each dimension. Each work item contains everything
    needed for Pass 2 metadata and Pass 3 plotting.

    Returns list of (spec_pair, tmpl_index, spec_entries, focus_val, focus_on, agg_level).
    """
    work_items = []

    for tmpl_index, tmpl in enumerate(templates):
        allow_cross = (
            tmpl.truth_source == TruthSource.recs
            and tmpl.resolution == Resolution.year
        )
        triples = generate_slot_triples(
            tmpl.eligible_chars,
            allow_cross_filter=allow_cross,
            cross_filter_chars=RECS_CROSS_FILTER_CHARS if allow_cross else None,
        )

        for f1_char, f2_char, agg_level in triples:
            # --- Base spec construction ---
            # Build a PlotSpec with the triple's agg_level.
            # When agg_level is None (leaf or no-grouping), we still need a valid
            # PlotSpec — aggregation_level will be set to None.
            spec = _make_spec(
                truth_source=tmpl.truth_source,
                quantity=tmpl.quantity,
                resolution=tmpl.resolution,
                aggregation_type=tmpl.aggregation_type,
                coverage=tmpl.coverage,
                aggregation_level=agg_level,
                view=tmpl.view,
            )
            spec_pair = _make_pair(spec)
            main_spec, extra_spec = spec_pair
            spec_entries = _build_spec_entries(main_spec, extra_spec)

            # ALL enduses: skip any triple with agg_level set — can't
            # group a stacked enduse chart by another dimension.
            if tmpl.quantity == DataCol.ALL and agg_level is not None:
                continue

            # --- Case 1: No filters (F1=None) → overview only ---
            if f1_char is None:
                # hour_of_day_matrix requires per-utility focus; expand each
                # utility as a separate work item (LRD has no Block 2 triples).
                if tmpl.resolution == Resolution.hour_of_day_matrix:
                    data_key = main_spec.get_data_key()
                    base_data = get_base_data(data_key)
                    col = "utility_name" if agg_level == "eiaid" else agg_level
                    for val in sorted(v for v in base_data[col].unique().to_list() if v is not None):
                        work_items.append((
                            spec_pair, tmpl_index, spec_entries, val,
                            ((agg_level, val),), agg_level,
                        ))
                    continue
                # Warm the disk cache so worker processes find the data.
                get_base_data(main_spec.get_data_key())
                work_items.append((
                    spec_pair, tmpl_index, spec_entries, None, (), agg_level,
                ))
                continue

            # --- F1 is set: discover F1 values ---
            # Use any spec with agg_level=f1_char to get the data
            f1_lookup_spec = _make_spec(
                truth_source=tmpl.truth_source,
                quantity=tmpl.quantity,
                resolution=tmpl.resolution,
                aggregation_type=tmpl.aggregation_type,
                coverage=tmpl.coverage,
                aggregation_level=f1_char,
                view=tmpl.view,
            )
            f1_data = get_base_data(f1_lookup_spec.get_data_key())
            f1_col = "utility_name" if f1_char == "eiaid" else f1_char
            f1_values = sorted(
                v for v in f1_data[f1_col].unique().to_list()
                if v is not None and v != "US Total"
            )
            if test_only:
                f1_values = f1_values[:1]

            for f1_val in f1_values:
                # --- Case 2: F1 set, F2=None ---
                if f2_char is None:
                    if agg_level is not None:
                        # Cross-filter: F1 set + agg_level set → overview only
                        filtered_entries = _build_filtered_entries(
                            spec_entries, ((f1_char, f1_val),),
                        )
                        if not filtered_entries:
                            continue
                        # Warm cache for the 2-column group_by DataKey that
                        # workers will request (focus_on col + agg_level).
                        get_base_data(filtered_entries[0][0].get_data_key())
                        focus_on = ((f1_char, f1_val),)
                        work_items.append((
                            spec_pair, tmpl_index, filtered_entries, None, focus_on, agg_level,
                        ))
                    else:
                        # F1 set, no agg, no F2 → single filtered entity, no grouping
                        focus_on = ((f1_char, f1_val),)
                        filtered_entries = _build_filtered_entries(spec_entries, focus_on)
                        if filtered_entries:
                            work_items.append((
                                spec_pair, tmpl_index, filtered_entries, None, focus_on, None,
                            ))
                    continue

                # --- Case 3: F1 set, F2 set (agg_level is always None) ---
                f2_lookup_spec = _make_spec(
                    truth_source=tmpl.truth_source,
                    quantity=tmpl.quantity,
                    resolution=tmpl.resolution,
                    aggregation_type=tmpl.aggregation_type,
                    coverage=tmpl.coverage,
                    aggregation_level=f2_char,
                    view=tmpl.view,
                )
                f2_data = get_base_data(f2_lookup_spec.get_data_key())
                f2_col = "utility_name" if f2_char == "eiaid" else f2_char

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
                        spec_pair, tmpl_index, spec_entries, None, focus_on, None,
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


def get_plotting_function(truth_source):
    """Return the plotter for a truth source."""
    match truth_source:
        case TruthSource.eia:
            return recs_plotter.create_plot
        case TruthSource.recs:
            return recs_plotter.create_plot
        case TruthSource.lrd:
            return lrd_plotter.create_plot
        case _:
            raise ValueError(f"Unsupported truth source: {truth_source}")


@timed
def _compute_discrepancy(data, plot_spec):
    """Compute CVRMSE and NMBE using raw values with global normalization (ASHRAE-style).

    NMBE  = Σ(ResStock - Ref) / Σ(Ref) × 100
    CVRMSE = sqrt(Σ(ResStock - Ref)² / n) / mean(Ref) × 100
    """
    if plot_spec.quantity == DataCol.ALL:
        return None, None
    if plot_spec.view == ViewType.distribution:
        return None, None

    # Determine value column
    if plot_spec.quantity == DataCol.UNITS_COUNT:
        val_col = "units_count"
    elif plot_spec.view == ViewType.penetration:
        val_col = f"{plot_spec.quantity}_percent_users"
    else:
        val_col = f"{plot_spec.quantity}_value"

    if val_col not in data.columns:
        return None, None

    # Identify reference and ResStock rows
    truth = plot_spec.truth_source.value
    ref_rows = data.filter(pl.col("source").str.contains(truth))
    rs_rows = data.filter(pl.col("source").str.contains("resstock"))

    if len(ref_rows) == 0 or len(rs_rows) == 0:
        return None, None

    # Determine join columns for pairing
    agg_col = get_second_category_column(plot_spec)
    join_cols = [agg_col]
    # Add the timeseries column to the join (e.g., month, hour of day, percent_time)
    ts_col = _resolve_timeseries_column(plot_spec)
    if ts_col and str(ts_col) in data.columns:
        join_cols.append(str(ts_col))

    # Exclude "US Total" from multi-entity overviews to avoid double-counting.
    # Skip when focused on US Total itself (single-entity plot).
    is_us_total_focus = any(val == "US Total" for _, val in plot_spec.focus_on)
    if not is_us_total_focus:
        ref_rows = ref_rows.filter(pl.col(agg_col) != "US Total")
        rs_rows = rs_rows.filter(pl.col(agg_col) != "US Total")

    # Pair up reference and ResStock values
    ref_selected = ref_rows.select(join_cols + [pl.col(val_col).alias("ref_val")])
    rs_selected = rs_rows.select(join_cols + [pl.col(val_col).alias("rs_val")])
    paired = rs_selected.join(ref_selected, on=join_cols, how="inner")
    paired = paired.drop_nulls(["ref_val", "rs_val"])
    # NaN means no data for this enduse in a state — treat as zero consumption
    paired = paired.with_columns(
        pl.col("ref_val").fill_nan(0),
        pl.col("rs_val").fill_nan(0),
    )

    if len(paired) == 0:
        return None, None

    diffs = paired["rs_val"] - paired["ref_val"]
    sum_ref = paired["ref_val"].sum()
    mean_ref = paired["ref_val"].mean()

    if sum_ref == 0 or mean_ref == 0:
        return None, None

    nmbe = float(diffs.sum() / sum_ref * 100)
    rmse = float(math.sqrt((diffs**2).mean()))
    cvrmse = float(rmse / mean_ref * 100)

    return cvrmse, nmbe


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
    footnotes=None,
    table_footnotes=None,
    source_labels=None,
) -> tuple[str, str | None] | None:
    """Generate plots for a list of (PlotSpec, viz_type_str) entries.

    Returns (viz_parts_joined, data_rel_path) on success, or None if skipped.
    All file I/O writes to unique per-spec paths (safe for parallel execution).
    """
    # Check if data is available for this combination before generating any plots.
    first_spec = spec_entries[0][0]
    probe_data = get_plot_data(first_spec)
    sources = probe_data["source"].unique().to_list() if not probe_data.is_empty() else []
    has_reference = any("resstock" not in s for s in sources)
    has_resstock = any("resstock" in s for s in sources)
    if not has_reference or not has_resstock:
        return None

    viz_parts = []
    data_rel = None
    for plot_spec, viz_type_str in spec_entries:
        try:
            data = get_plot_data(plot_spec)
            plot_func = get_plotting_function(plot_spec.truth_source)
            fig, title = plot_func(data, plot_spec)
            save_figure(fig, plot_spec, formats=output_formats,
                        footnotes=footnotes, source_labels=source_labels)

            # Build relative path to the plot file
            path_seg, file_title = plot_spec.get_file_path_and_name()
            rel_path = (
                Path(f"{plot_spec.truth_source} plots ({link_format})") / path_seg / f"{file_title}.{link_format.value}"
            )
            rel_path_str = str(rel_path).replace("\\", "/")
            viz_parts.append(f"{viz_type_str}||{rel_path_str}")

            # For main visualization: save data CSV, compute discrepancy, generate data table
            if plot_spec.view in (ViewType.value_view, ViewType.penetration):
                data_dir = output_base / f"{plot_spec.truth_source} data (csv)" / path_seg
                ensure_directory(data_dir)
                _save_data_csv(data, data_dir, file_title)

                cvrmse, nmbe = _compute_discrepancy(data, plot_spec)

                if should_generate_table(data, plot_spec):
                    table_dir = output_base / f"{plot_spec.truth_source} data (html)" / path_seg
                    ensure_directory(table_dir)
                    table_path = table_dir / f"{file_title}.html"
                    table_depth = len(table_path.relative_to(output_base).parents) - 1
                    plot_rel_from_table = "../" * table_depth + rel_path_str
                    generate_data_table_html(
                        data=data,
                        plot_spec=plot_spec,
                        output_path=table_path,
                        plot_rel_path=plot_rel_from_table,
                        cvrmse=cvrmse,
                        nmbe=nmbe,
                        footnotes=table_footnotes,
                        source_labels=source_labels,
                    )
                    rel_table = Path(f"{plot_spec.truth_source} data (html)") / path_seg / f"{file_title}.html"
                    data_rel = f"data table||{str(rel_table).replace(chr(92), '/')}"

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
        parts = [row["Truth Source"], row["Quantity"], row["Metric"]]
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

    footnote_rules = _load_footnote_rules()
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
    from resstockpostproc.shared_utils.mapping import ABBR2STATE

    for i, (spec_pair, tmpl_index, spec_entries, focus_val, focus_on, agg_level) in enumerate(work_items, 1):
        main_spec, extra_spec = spec_pair

        # Build a unique key for this work item
        agg_suffix = f"_by_{agg_level}" if agg_level else ""
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
        if focus_val is not None and agg_level is not None:
            final_focus_tuples.append((agg_level, focus_val))
        final_focus_on = tuple(final_focus_tuples)
        final_agg = agg_level if focus_val is None else None

        # Build a concrete main_spec with the triple's agg_level for display
        display_spec = _make_spec(
            truth_source=main_spec.truth_source,
            quantity=main_spec.quantity,
            resolution=main_spec.resolution,
            aggregation_type=main_spec.aggregation_type,
            coverage=main_spec.coverage,
            aggregation_level=agg_level or (final_focus_on[0][0] if final_focus_on else "state"),
            view=main_spec.view,
        )

        results[sub_key] = _build_output_row(display_spec)
        results[sub_key]["Index"] = i
        if final_agg is None:
            results[sub_key]["Group By"] = ""
        if final_focus_on and not any(v == "US Total" for _, v in final_focus_on):
            results[sub_key]["Highlight"] = ""
        results[sub_key]["Comparison Plot"] = ""

        if final_focus_on:
            for idx, (char, value) in enumerate(final_focus_on):
                display = ABBR2STATE.get(value, value) if char == "state" else value
                category = format_aggregation_level(char)
                results[sub_key][f"Filter {idx + 1}"] = f"{category}: {display}"

        focused_entries = [
            (
                spec.model_copy(update={
                    "focus_on": final_focus_on,
                    "aggregation_level": final_agg,
                }),
                _simplify_viz_label(viz_type) if focus_val else viz_type,
            )
            for spec, viz_type in spec_entries
        ]

        fn_row = _footnote_row(display_spec)
        matched_notes = _resolve_footnotes(footnote_rules, fn_row, context="plot") or None
        table_notes = _resolve_footnotes(footnote_rules, fn_row, context="table") or None

        plot_args.append((sub_key, focused_entries, matched_notes, table_notes))

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
                for sub_key, focused_entries, matched_notes, table_notes in plot_args:
                    future = executor.submit(
                        _worker_run, focused_entries,
                        footnotes=matched_notes, table_footnotes=table_notes, **common_kwargs,
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
            for sub_key, focused_entries, matched_notes, table_notes in plot_args:
                result = _generate_spec_plots(
                    focused_entries, footnotes=matched_notes, table_footnotes=table_notes,
                    **common_kwargs,
                )
                _handle_plot_result(sub_key, result, results, csv_path, index_state)
                pbar.update(1)
    finally:
        pbar.close()
        root_logger.handlers = original_handlers

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
    eia_indices = {i + 1 for i, t in enumerate(all_tmpls) if t.truth_source == TruthSource.eia}
    generate_plots(index=eia_indices)


def generate_recs_plots():
    """Generate only RECS plots."""
    all_tmpls = generate_all_templates()
    recs_indices = {i + 1 for i, t in enumerate(all_tmpls) if t.truth_source == TruthSource.recs}
    generate_plots(index=recs_indices)


def generate_lrd_plots():
    """Generate only LRD plots."""
    all_tmpls = generate_all_templates()
    lrd_indices = {i + 1 for i, t in enumerate(all_tmpls) if t.truth_source == TruthSource.lrd}
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
