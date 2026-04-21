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
import time
from pathlib import Path


from resstockpostproc.baseline_validation.dashboard.dashboard_paths import (
    comparisons_index_data_dir,
    comparisons_index_tsv_path,
    dashboard_assets_dir,
    dashboard_html_path,
    dashboard_output_root,
    dataset_output_dir,
    trace_output_path,
)
from resstockpostproc.baseline_validation.schema.plot_spec import (
    FileType,
    ComparisonDataset,
)
from resstockpostproc.baseline_validation.schema.plot_definitions import (
    generate_all_templates,
)
from resstockpostproc.baseline_validation.generation.render_runner import (
    OUTPUT_COLUMNS,
    has_static_image_outputs,
    render_all_work_items,
)
from resstockpostproc.baseline_validation.generation.work_items import (
    build_plot_args,
    build_render_gate,
    expand_templates,
)
from resstockpostproc.baseline_validation.generation.stacked_pages import (
    generate_stacked_pages,
)
from resstockpostproc.baseline_validation.io_managers.output_manager import (
    ensure_plotly_asset,
)
from resstockpostproc.baseline_validation.dashboard.create_html import (
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
        wanted = set(index) if isinstance(index, set | list) else {index}
        templates = [t for i, t in enumerate(templates) if (i + 1) in wanted]

    render_keys = build_render_gate(templates, test_only)
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

    results, plot_args, stacking_groups = build_plot_args(work_items, render_keys)

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

    _cleanup_raw_plot_html(output_root, link_format)

    if stream_incremental:
        finalize_html_index(index_state)
    else:
        # No incremental writes happened. Materialize the TSV from in-memory
        # results so write_canonical_index has something to rewrite.
        _write_results_tsv(csv_path, results)

    # Rows were appended in worker-completion order, which is non-deterministic.
    # Re-read the TSV, sort by Index (stacked rows with empty Index go last in
    # their original write order), and rewrite TSV + shards + combinations.js +
    # dashboard HTML so repeat runs produce byte-identical output. Also handles
    # the non-streaming case: it's still the single place that writes shards
    # and dashboard HTML from the materialized TSV.
    write_canonical_index(csv_path, html_path, index_data_dir)

    ok, failed = _count_plot_outcomes(results)
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


def _cleanup_raw_plot_html(output_root: Path, link_format: FileType) -> None:
    """Delete the raw Plotly HTML files that Pass 3 wrote; only postprocessed outputs survive."""
    for ds in ComparisonDataset:
        plots_dir = dataset_output_dir(output_root, str(ds), "plots", link_format.value)
        if not plots_dir.exists():
            continue
        for raw_html in plots_dir.rglob(f"*.raw.{link_format.value}"):
            raw_html.unlink()


def _write_results_tsv(csv_path: Path, results: dict[str, dict[str, str]]) -> None:
    """Materialize the in-memory results dict as the comparisons_index TSV."""
    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=OUTPUT_COLUMNS, delimiter="\t")
        writer.writeheader()
        writer.writerows(results.values())


def _count_plot_outcomes(results: dict[str, dict[str, str]]) -> tuple[int, int]:
    """Return (ok, failed) counts across all viz entries in all result rows."""
    ok = failed = 0
    for row in results.values():
        for raw_part in row["Comparison Plot"].split(" ;; "):
            part = raw_part.strip()
            if not part:
                continue
            if part.startswith("FAILED:"):
                failed += 1
            else:
                ok += 1
    return ok, failed


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


def parse_index_arg(index_str: str) -> set[int]:
    """Parse index argument: single int, range (e.g. '1-10'), or comma-separated."""
    indices: set[int] = set()
    for raw_part in index_str.split(","):
        part = raw_part.strip()
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
        "--test",
        action="store_true",
        default=True,
        help="Generate only test subset plots (limited focus expansion)",
    )
    parser.add_argument(
        "--no-parallel",
        action="store_true",
        default=False,
        help="Disable parallel plot generation (run sequentially)",
    )
    parser.add_argument(
        "--no-svg",
        action="store_true",
        default=True,
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
