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
from resstockpostproc.baseline_validation.dashboard_paths import (
    comparisons_index_data_dir,
    comparisons_index_tsv_path,
    dashboard_assets_dir,
    dashboard_html_path,
    dashboard_output_root,
    dataset_output_dir,
    relative_href_from_file,
    trace_output_path,
)
from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    FileType,
    ComparisonDataset,
    ViewType,
    Resolution,
    Metric,
    format_group_by,
    ALL_ENDUSES_DISPLAY,
)
from resstockpostproc.baseline_validation.schema.plot_definitions import (
    generate_all_templates,
    _make_spec,
)
from resstockpostproc.baseline_validation.generation.render_runner import (
    OUTPUT_COLUMNS,
    append_plot_row,
    ensure_kaleido_sync_server,
    generate_spec_plots,
    get_plotting_function,
    handle_plot_result,
    has_static_image_outputs,
    plot_output_path,
    render_key,
    stop_kaleido_sync_server_if_owned,
    worker_init,
    worker_run,
)
from resstockpostproc.baseline_validation.generation.work_items import (
    emit_layout_for_final_group,
    expand_templates,
    get_test_template_indices,
)
from resstockpostproc.baseline_validation.io_managers.output_manager import (
    ensure_plotly_asset,
    plotly_cdn_url,
)
from resstockpostproc.baseline_validation.io_managers.data_table import (
    generate_data_table_html,
)
from resstockpostproc.baseline_validation.utils import ensure_directory
from resstockpostproc.baseline_validation.data_processing.gather_data import get_plot_data
from resstockpostproc.baseline_validation.create_html import (
    init_html_index,
    append_index_row,
    finalize_html_index,
    create_html_from_rows,
)
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow
from resstockpostproc.shared_utils.timing import TimingStats, timed

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s", force=True)
for noisy_logger_name in ("kaleido", "choreographer", "browser_proc"):
    logging.getLogger(noisy_logger_name).setLevel(logging.ERROR)
logger = logging.getLogger(__name__)


class _TqdmLoggingHandler(logging.Handler):
    """Routes log output through tqdm.write() so log lines don't clobber the progress bar."""

    def emit(self, record):
        tqdm.write(self.format(record))


DEFAULT_PLOT_OUTPUT_FORMATS = [FileType.html, FileType.svg]

# When True, --test runs emit a TSV / dashboard matching a full run: every
# work item's row is present, even though only the test subset is rendered.
# Use False so that the dasboard only contains available plots from the test.
TEST_PRODUCES_FULL_INDEX = True


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
# Plotting
# ---------------------------------------------------------------------------


def generate_plots(index=None, test_only=False, parallel=True, no_svg=False):
    """Generate baseline validation plots.

    Args:
        index: If provided, only generate plots for this template index (int),
               or a set/list of indices. If None, generate all plots.
        test_only: If True, only generate the test subset with limited focus expansion.
        parallel: If True, use ProcessPoolExecutor for parallel plot generation.
        no_svg: If True, skip SVG output (faster for test/determinism checks).
    """
    wall_start = time.perf_counter()
    templates = generate_all_templates()

    if index is not None:
        wanted = set(index) if isinstance(index, (set, list)) else {index}
        templates = [t for i, t in enumerate(templates) if (i + 1) in wanted]

    # When --test is active, every work item still flows through Pass 2 + TSV
    # emission so that `comparisons_index.tsv` matches a full run. Only the
    # actual render work (plotly/kaleido/data-table HTML) is suppressed for
    # items outside the "test subset" the old --test logic would have picked.
    render_keys: set[tuple] | None = None
    if test_only:
        subset_tmpl_idx = get_test_template_indices(templates)
        # Deterministic mapping from subset-local tmpl_index back to the
        # full-templates index that the main pass will emit on work items.
        subset_to_full_idx = sorted(subset_tmpl_idx)
        subset_templates = [templates[i] for i in subset_to_full_idx]
        subset_items = expand_templates(subset_templates, test_only=True)
        render_keys = set()
        for item in subset_items:
            spec_family, subset_ti, spec_entries, focus_val, focus_on, group_by = item
            full_ti = subset_to_full_idx[subset_ti]
            render_keys.add((full_ti, focus_on, focus_val, group_by))
        logger.info(f"--test render gate: {len(render_keys)} items will actually render")

    logger.info(f"Expanding {len(templates)} plot templates...")

    source_labels = workflow.data_source_labels

    output_formats = [fmt for fmt in DEFAULT_PLOT_OUTPUT_FORMATS if not (no_svg and fmt == FileType.svg)]
    needs_persistent_kaleido = has_static_image_outputs(output_formats)
    link_format = FileType.html if FileType.html in output_formats else output_formats[0]
    output_root = dashboard_output_root(workflow)
    csv_path = comparisons_index_tsv_path(output_root)
    html_path = dashboard_html_path(output_root)
    index_data_dir = comparisons_index_data_dir(output_root)
    plotly_asset_path = ensure_plotly_asset(dashboard_assets_dir(output_root))

    # Initialize the CSV (header only) and the HTML index (shell + data dir).
    csv_path.parent.mkdir(parents=True, exist_ok=True)

    # Chrome Trace Event Format — streaming writes for Perfetto UI visualization
    trace_path = trace_output_path(output_root)
    TimingStats.start_trace(trace_path)

    # Incremental appends (TSV/shard/combo/dashboard-HTML) let users preview
    # partial output on a full run. They're dead weight on --test since every
    # item goes through handle_plot_result but most are dry-run-only (path
    # strings only, no real files to show). Skip them under --test; the final
    # `_rewrite_index_in_sorted_order` pass materializes everything in one shot.
    stream_incremental = not test_only
    index_state = None
    if stream_incremental:
        with open(csv_path, "w", newline="") as f:
            csv.DictWriter(f, fieldnames=OUTPUT_COLUMNS, delimiter="\t").writeheader()
        index_state = init_html_index(html_path, OUTPUT_COLUMNS, data_dir=index_data_dir)

    # Expand templates into work items via slot triples. Always fully expand —
    # `--test` gating happens per-work-item downstream (via `render_keys`),
    # not at expansion time.
    work_items = expand_templates(templates, test_only=False)

    total = len(work_items)
    logger.info(f"Total plot groups to generate: {total}")

    # Build metadata for all work items and prepare plot arguments
    results = {}
    plot_args = []
    stacking_groups: dict[tuple, list[tuple[str, list[tuple[PlotSpec, str]]]]] = defaultdict(list)
    from resstockpostproc.shared_utils.mapping import ABBR2STATE

    for i, work_item in enumerate(work_items, 1):
        spec_family, tmpl_index, spec_entries, focus_val, focus_on, group_by = work_item
        main_spec = spec_family[0]

        # --test render gate: only a representative subset actually renders.
        # Non-render items still produce TSV rows (probe + path assembly + table
        # decision) so the index matches what a full run would emit.
        is_dry_run = render_keys is not None and render_key(work_item) not in render_keys
        if is_dry_run and not TEST_PRODUCES_FULL_INDEX:
            # Legacy --test mode: skip dry-run items entirely. No row in the TSV,
            # no entry in `plot_args`, no `stacking_groups` contribution. The
            # downstream code is the same as a full run; it just sees fewer items.
            continue

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
            if not emit_layout_for_final_group(focused_spec, final_agg):
                continue
            viz_label = focused_spec.display_viz_label
            if focused_spec.is_all_enduses:
                viz_label = _all_enduses_viz_label(focused_spec, stacked=False)
            focused_entries.append((focused_spec, viz_label))

        if not focused_entries:
            continue

        plot_args.append((sub_key, focused_entries, is_dry_run))

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

    total = len(plot_args)

    # Pass 3: Generate plots — parallel or sequential
    common_kwargs = dict(
        output_formats=output_formats,
        link_format=link_format,
        output_root=output_root,
        source_labels=source_labels or None,
        plotly_asset_path=plotly_asset_path,
    )

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
            with ProcessPoolExecutor(
                max_workers=max_workers,
                initializer=worker_init,
                initargs=(needs_persistent_kaleido,),
            ) as executor:
                for sub_key, focused_entries, is_dry_run in plot_args:
                    future = executor.submit(
                        worker_run, focused_entries, is_dry_run=is_dry_run, **common_kwargs,
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
                    handle_plot_result(sub_key, result, results, csv_path, index_state)
                    pbar.update(1)
        else:
            if needs_persistent_kaleido:
                ensure_kaleido_sync_server()
            for sub_key, focused_entries, is_dry_run in plot_args:
                result = generate_spec_plots(
                    focused_entries, is_dry_run=is_dry_run, **common_kwargs,
                )
                handle_plot_result(sub_key, result, results, csv_path, index_state)
                pbar.update(1)
    finally:
        stop_kaleido_sync_server_if_owned()
        pbar.close()
        root_logger.handlers = original_handlers

    # Pass 4: Assemble synthetic "All Enduses (Stacked)" pages by combining
    # the raw Plotly HTML files already written in Pass 3. View-agnostic: for
    # each view position in focused_entries, transpose across quantities.
    from resstockpostproc.baseline_validation.io_managers.html_utils import postprocess_plot_html
    eligible_groups = {k: v for k, v in stacking_groups.items() if _should_generate_stacked_page_group(v)}
    stacked_count = 0
    stacked_table_data_cache: dict[tuple, pl.DataFrame] = {}
    dashboard_path = dashboard_html_path(output_root)

    def _raw_path(spec: PlotSpec) -> Path:
        raw_path = plot_output_path(output_root, spec, link_format)
        return raw_path.with_name(f"{raw_path.stem}.raw.{link_format.value}")

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
            out = dataset_output_dir(output_root, str(first_spec.comparison_dataset), "plots", link_format.value) / path_seg / f"{title}.{link_format.value}"
            ensure_directory(out.parent)
            postprocess_plot_html(
                paths, output_path=out, footnotes=plot_notes,
                source_labels=source_labels, scale_x=scale_x, scale_y=scale_y,
                comparison_dataset=first_spec.comparison_dataset.value,
                plotly_cdn_src=plotly_cdn_url(),
                plotly_asset_path=plotly_asset_path,
            )
            rel_str = relative_href_from_file(out, dashboard_path)
            stacked_label = _all_enduses_viz_label(all_view_spec, stacked=True)
            viz_parts.append(f"{stacked_label}||{rel_str}")
            stacked_outputs.append((i, all_view_spec, str(out)))
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
                stacked_plot_path = Path(table_rel_plot)
                stacked_data = _build_stacked_table_data(
                    qty_entries, table_view_index, stacked_table_data_cache
                )
                if not stacked_data.is_empty():
                    table_dir = dataset_output_dir(output_root, str(table_spec.comparison_dataset), "data", FileType.html.value) / path_seg
                    ensure_directory(table_dir)

                    table_file_title = stacked_plot_path.stem
                    table_path = table_dir / f"{table_file_title}.html"
                    plot_rel_from_table = relative_href_from_file(stacked_plot_path, table_path)

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
                    rel_table = relative_href_from_file(table_path, dashboard_path)
                    data_rel = f"data table||{rel_table}"

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
            if index_state is not None:
                append_plot_row(csv_path, row)
                append_index_row(index_state, row)

    stacked_pbar.close()
    if stacked_count:
        logger.info(f"Generated {stacked_count} synthetic 'All Enduses (Stacked)' pages")

    # Clean up raw Plotly HTML files — only the post-processed versions are needed.
    for ds in ComparisonDataset:
        plots_dir = dataset_output_dir(output_root, str(ds), "plots", link_format.value)
        if plots_dir.exists():
            for raw_html in plots_dir.rglob(f"*.raw.{link_format.value}"):
                raw_html.unlink()

    if stream_incremental:
        # Finalize the streaming index (closes combo file, writes dashboard HTML).
        finalize_html_index(index_state)
    else:
        # No incremental writes happened. Materialize the TSV from in-memory
        # results so _rewrite_index_in_sorted_order has something to rewrite.
        with open(csv_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=OUTPUT_COLUMNS, delimiter="\t")
            writer.writeheader()
            writer.writerows(results.values())

    # Rows were appended in worker-completion order, which is non-deterministic.
    # Re-read the TSV, sort by Index (stacked rows with empty Index go last in
    # their original write order), and rewrite TSV + shards + combinations.js +
    # dashboard HTML so repeat runs produce byte-identical output. Also handles
    # the non-streaming case: it's still the single place that writes shards
    # and dashboard HTML from the materialized TSV.
    _rewrite_index_in_sorted_order(csv_path, html_path, index_data_dir)

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
def _rewrite_index_in_sorted_order(tsv_path: Path, html_path: Path, data_dir: Path) -> None:
    """Rewrite TSV, shards, combinations.js, and dashboard HTML in canonical order.

    The streaming append path lets users preview partial output while plots are
    still being generated, but the write order is non-deterministic. This pass
    re-reads the TSV, sorts rows by numeric Index (stacked rows with empty Index
    preserved at the end in append order), and rewrites every consumer of that
    row order so repeat runs produce byte-identical output.
    """
    with open(tsv_path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter="\t")
        headers = reader.fieldnames or list(OUTPUT_COLUMNS)
        rows = list(reader)

    def _sort_key(row: dict) -> tuple[int, int]:
        idx = str(row.get("Index", "")).strip()
        # Numeric indices first (ascending), then stacked/empty-index rows after.
        return (0, int(idx)) if idx.isdigit() else (1, 0)

    sorted_rows = sorted(enumerate(rows), key=lambda pair: (_sort_key(pair[1]), pair[0]))
    rows_in_order = [r for _, r in sorted_rows]

    with open(tsv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=headers, delimiter="\t")
        writer.writeheader()
        writer.writerows(rows_in_order)

    create_html_from_rows(rows_in_order, headers, html_path, data_dir=data_dir)


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
        "--test", action="store_true", default=True,
        help="Generate only test subset plots (limited focus expansion)",
    )
    parser.add_argument(
        "--no-parallel", action="store_true", default=False,
        help="Disable parallel plot generation (run sequentially)",
    )
    parser.add_argument(
        "--no-svg", action="store_true", default=True,
        help="Skip SVG output (faster; useful for determinism checks and test runs)",
    )
    args = parser.parse_args()

    index = parse_index_arg(args.index) if args.index else None
    generate_plots(
        index=index,
        test_only=args.test,
        parallel=not args.no_parallel,
        no_svg=args.no_svg,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
