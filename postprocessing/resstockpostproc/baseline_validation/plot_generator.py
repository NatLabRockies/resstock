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
import sys
from collections import defaultdict
import time
from pathlib import Path


from resstockpostproc.baseline_validation.dashboard_paths import (
    comparisons_index_data_dir,
    comparisons_index_tsv_path,
    dashboard_assets_dir,
    dashboard_html_path,
    dashboard_output_root,
    dataset_output_dir,
    trace_output_path,
)
from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    FileType,
    ComparisonDataset,
    format_group_by,
)
from resstockpostproc.baseline_validation.schema.plot_definitions import (
    generate_all_templates,
    _make_spec,
)
from resstockpostproc.baseline_validation.generation.render_runner import (
    OUTPUT_COLUMNS,
    has_static_image_outputs,
    render_all_work_items,
    render_key,
)
from resstockpostproc.baseline_validation.generation.work_items import (
    emit_layout_for_final_group,
    expand_templates,
    get_test_template_indices,
)
from resstockpostproc.baseline_validation.generation.index_rows import (
    apply_lrd_sidebar_semantics,
    build_output_row,
)
from resstockpostproc.baseline_validation.generation.stacked_pages import (
    all_enduses_viz_label,
    generate_stacked_pages,
)
from resstockpostproc.baseline_validation.io_managers.output_manager import (
    ensure_plotly_asset,
)
from resstockpostproc.baseline_validation.create_html import (
    init_html_index,
    finalize_html_index,
    create_html_from_rows,
)
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow
from resstockpostproc.shared_utils.timing import TimingStats, timed

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s", force=True)
for noisy_logger_name in ("kaleido", "choreographer", "browser_proc"):
    logging.getLogger(noisy_logger_name).setLevel(logging.ERROR)
logger = logging.getLogger(__name__)


DEFAULT_PLOT_OUTPUT_FORMATS = [FileType.html, FileType.svg]

# When True, --test runs emit a TSV / dashboard matching a full run: every
# work item's row is present, even though only the test subset is rendered.
# Use False so that the dasboard only contains available plots from the test.
TEST_PRODUCES_FULL_INDEX = True


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
    # `write_canonical_index` pass materializes everything in one shot.
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

        results[sub_key] = build_output_row(display_spec)
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

        apply_lrd_sidebar_semantics(results[sub_key], display_spec, final_focus_on)

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
                viz_label = all_enduses_viz_label(focused_spec, stacked=False)
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

    # Pass 3: Generate plots — parallel or sequential
    render_all_work_items(
        plot_args,
        parallel=parallel,
        output_formats=output_formats,
        link_format=link_format,
        output_root=output_root,
        source_labels=source_labels or None,
        plotly_asset_path=plotly_asset_path,
        needs_persistent_kaleido=needs_persistent_kaleido,
        results=results,
        index_state=index_state,
        csv_path=csv_path,
    )

    # Pass 4: Assemble synthetic "All Enduses (Stacked)" pages by combining
    # the raw Plotly HTML files already written in Pass 3. View-agnostic: for
    # each view position in focused_entries, transpose across quantities.
    stacked_count = generate_stacked_pages(
        stacking_groups,
        output_root=output_root,
        link_format=link_format,
        source_labels=source_labels,
        plotly_asset_path=plotly_asset_path,
        results=results,
        index_state=index_state,
        csv_path=csv_path,
    )
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
        # results so write_canonical_index has something to rewrite.
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
    write_canonical_index(csv_path, html_path, index_data_dir)

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
def write_canonical_index(tsv_path: Path, html_path: Path, data_dir: Path) -> None:
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
