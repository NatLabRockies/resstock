"""Render execution and worker lifecycle for plot generation.

Owns per-spec rendering, the worker pool, the Kaleido sync server, and
plot/data output-path derivation. Worker helper names are pickled by
ProcessPoolExecutor, so their module path must stay stable.
"""

from __future__ import annotations

import contextlib
import csv
import logging
import os
import sys
import traceback
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

from plotly import graph_objects as go
from tqdm import tqdm

from resstockpostproc.baseline_validation.create_html import append_index_row
from resstockpostproc.baseline_validation.data_processing.metrics import compute_discrepancy
from resstockpostproc.baseline_validation.dashboard_paths import (
    dashboard_html_path,
    dataset_output_dir,
    relative_href_from_file,
)
from resstockpostproc.baseline_validation.data_processing.gather_data import get_plot_data
from resstockpostproc.baseline_validation.footnotes import (
    get_plot_notes,
    get_table_notes,
)
from resstockpostproc.baseline_validation.io_managers.data_table import (
    generate_data_table_html,
)
from resstockpostproc.baseline_validation.io_managers.output_manager import (
    save_figure,
    save_static_images_batch,
)
from resstockpostproc.baseline_validation.plotters import lrd_plotter, main_plotter
from resstockpostproc.baseline_validation.schema.plot_spec import (
    ComparisonDataset,
    FileType,
    PlotSpec,
    ViewType,
)
from resstockpostproc.baseline_validation.utils import ensure_directory
from resstockpostproc.shared_utils.timing import TimingStats, timed

logger = logging.getLogger(__name__)


# Column schema for the comparisons index TSV. Defined here because
# append_plot_row writes rows in this order; plot_generator imports it back
# for its own writes (header init, sorted-order rewrite, etc.).
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


_OWNS_KALEIDO_SYNC_SERVER = False


def has_static_image_outputs(output_formats: list[FileType]) -> bool:
    """Return whether a run will emit any Kaleido-backed image outputs."""
    return any(fmt in {FileType.svg, FileType.pdf} for fmt in output_formats)


def _kaleido_sync_server_options() -> dict:
    """Match Plotly's Kaleido defaults when starting a persistent sync server."""
    import plotly.io as pio

    options = {"n": 1}
    if pio.defaults.plotlyjs:
        options["plotlyjs"] = pio.defaults.plotlyjs
    if pio.defaults.mathjax:
        options["mathjax"] = pio.defaults.mathjax
    return options


def _is_kaleido_sync_server_running() -> bool:
    """Return whether the process-local Kaleido sync server is already running."""
    import kaleido

    server = getattr(kaleido, "_global_server", None)
    return bool(server and server.is_running())


def ensure_kaleido_sync_server() -> bool:
    """Start the Kaleido sync server if needed; True iff we now own shutdown."""
    global _OWNS_KALEIDO_SYNC_SERVER

    if _is_kaleido_sync_server_running():
        return False

    import kaleido

    kaleido.start_sync_server(silence_warnings=True, **_kaleido_sync_server_options())
    _OWNS_KALEIDO_SYNC_SERVER = True
    return True


def stop_kaleido_sync_server_if_owned() -> None:
    """Stop the process-local Kaleido sync server only if this module started it."""
    global _OWNS_KALEIDO_SYNC_SERVER

    if not _OWNS_KALEIDO_SYNC_SERVER:
        return

    import kaleido

    kaleido.stop_sync_server(silence_warnings=True)
    _OWNS_KALEIDO_SYNC_SERVER = False


def get_plotting_function(comparison_dataset):
    """Return the plotter for a comparison dataset."""
    match comparison_dataset:
        case ComparisonDataset.eia:
            return main_plotter.create_plot
        case ComparisonDataset.recs:
            return main_plotter.create_plot
        case ComparisonDataset.lrd:
            return lrd_plotter.create_plot
        case _:
            raise ValueError(f"Unsupported comparison dataset: {comparison_dataset}")


def plot_output_path(output_root: Path, plot_spec: PlotSpec, fmt: FileType) -> Path:
    """Return the absolute output path for a plot artifact."""
    path_seg, file_title = plot_spec.file_path_and_name
    dataset_dir = dataset_output_dir(output_root, str(plot_spec.comparison_dataset), "plots", fmt.value)
    return dataset_dir / path_seg / f"{file_title}.{fmt.value}"


def data_output_path(output_root: Path, plot_spec: PlotSpec, fmt: FileType) -> Path:
    """Return the absolute output path for a data artifact."""
    path_seg, file_title = plot_spec.file_path_and_name
    dataset_dir = dataset_output_dir(output_root, str(plot_spec.comparison_dataset), "data", fmt.value)
    return dataset_dir / path_seg / f"{file_title}.{fmt.value}"


@timed
def generate_spec_plots(
    spec_entries,
    output_formats,
    link_format,
    output_root,
    source_labels=None,
    plotly_asset_path: Path | None = None,
    is_dry_run: bool = False,
) -> tuple[str, str | None] | None:
    """Render the (PlotSpec, viz_type) entries; return (joined_viz, data_rel) or None.

    ``is_dry_run`` skips plot/HTML/SVG/data-table writes but still populates
    predicted paths — this is what makes --test produce a TSV byte-identical
    to a full run.
    """
    # Check if data is available for this combination before generating any plots.
    first_spec = spec_entries[0][0]
    probe_data = get_plot_data(first_spec)
    sources = probe_data["source"].unique().to_list() if not probe_data.is_empty() else []
    has_reference = any("resstock" not in s.lower() for s in sources)
    has_resstock = any("resstock" in s.lower() for s in sources)
    if not has_reference or not has_resstock:
        return None

    dashboard_path = dashboard_html_path(output_root)
    viz_parts = []
    data_rel = None
    static_image_jobs: list[tuple[go.Figure, PlotSpec, FileType]] = []
    for idx, (plot_spec, viz_type_str) in enumerate(spec_entries):
        try:
            is_primary_table_candidate = idx == 0 and (
                plot_spec.view in (ViewType.value_view, ViewType.temp_view)
                or plot_spec.is_penetration_metric
                or plot_spec.is_distribution_metric
            )

            if not is_dry_run:
                data = get_plot_data(plot_spec)
                plot_func = get_plotting_function(plot_spec.comparison_dataset)
                fig, _ = plot_func(data, plot_spec)
                spec_footnotes = get_plot_notes(plot_spec)
                html_formats = [fmt for fmt in output_formats if fmt == FileType.html]
                if html_formats:
                    save_figure(
                        fig,
                        plot_spec,
                        formats=html_formats,
                        footnotes=spec_footnotes,
                        source_labels=source_labels,
                        output_root=output_root,
                        plotly_asset_path=plotly_asset_path,
                    )
                static_image_jobs.extend(
                    (fig, plot_spec, fmt) for fmt in output_formats if fmt in {FileType.svg, FileType.pdf}
                )

            # Build relative path to the enhanced plot file (pure path derivation
            # — runs whether or not the file was written).
            plot_path = plot_output_path(output_root, plot_spec, link_format)
            rel_path_str = relative_href_from_file(plot_path, dashboard_path)
            viz_parts.append(f"{viz_type_str}||{rel_path_str}")

            # Data exports and table links are anchored to the primary spec only.
            # Every primary table candidate gets a table link; the HTML is only
            # actually written when we're rendering.
            if is_primary_table_candidate:
                table_path = data_output_path(output_root, plot_spec, FileType.html)
                rel_table = relative_href_from_file(table_path, dashboard_path)
                data_rel = f"data table||{rel_table}"

                if not is_dry_run:
                    table_dir = table_path.parent
                    ensure_directory(table_dir)
                    plot_rel_from_table = relative_href_from_file(plot_path, table_path)
                    spec_table_footnotes = get_table_notes(plot_spec)
                    metrics_by_source = compute_discrepancy(data, plot_spec)
                    generate_data_table_html(
                        data=data,
                        plot_spec=plot_spec,
                        output_path=table_path,
                        plot_rel_path=plot_rel_from_table,
                        metrics_by_source=metrics_by_source,
                        footnotes=spec_table_footnotes,
                        source_labels=source_labels,
                    )

        except Exception:
            tb = traceback.format_exc()
            viz_parts.append(f"FAILED: {viz_type_str}||{tb}")

    if not is_dry_run:
        save_static_images_batch(static_image_jobs, output_root=output_root)

    return " ;; ".join(viz_parts), data_rel


def worker_init(enable_persistent_kaleido: bool = True):
    """Process initializer for worker pool — collect timing in memory, use read-only disk cache."""
    from resstockpostproc.shared_utils import caching
    TimingStats.enable_worker_mode()
    caching.CACHE_READ_ONLY = True
    # Suppress worker stdout/stderr — the main process logs progress via tqdm.
    sys.stdout = open(os.devnull, "w")
    sys.stderr = open(os.devnull, "w")
    if enable_persistent_kaleido:
        ensure_kaleido_sync_server()


def worker_run(*args, **kwargs):
    """Wrapper that runs generate_spec_plots and harvests timing data from the worker process."""
    result = generate_spec_plots(*args, **kwargs)
    timing_stats, trace_events = TimingStats.harvest_worker_stats()
    return result, timing_stats, trace_events


@timed
def append_plot_row(tsv_path, row_dict):
    """Append a single result row to the TSV index (O(1) append)."""
    with open(tsv_path, "a", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=OUTPUT_COLUMNS, delimiter="\t")
        writer.writerow(row_dict)


def handle_plot_result(sub_key, result, results, csv_path, index_state):
    """Apply a worker's result to shared state; ``index_state=None`` defers all writes to the canonical pass."""
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
    if index_state is not None:
        append_plot_row(csv_path, row)
        append_index_row(index_state, row)


class _TqdmLoggingHandler(logging.Handler):
    """Routes log output through tqdm.write() so log lines don't clobber the progress bar."""

    def emit(self, record):
        tqdm.write(self.format(record))


@contextlib.contextmanager
def _tqdm_logging_context(total: int):
    """Yield a tqdm progress bar with logging routed through tqdm.write()."""
    root_logger = logging.getLogger()
    original_handlers = root_logger.handlers[:]
    tqdm_handler = _TqdmLoggingHandler()
    tqdm_handler.setFormatter(logging.Formatter("%(asctime)s - %(levelname)s - %(message)s"))
    root_logger.handlers = [tqdm_handler]
    pbar = tqdm(
        total=total,
        desc="Generating plots",
        unit="plot",
        bar_format="{desc}: {percentage:6.2f}%|{bar}| {n_fmt}/{total_fmt} [{elapsed}<{remaining}, {rate_fmt}]",
    )
    try:
        yield pbar
    finally:
        stop_kaleido_sync_server_if_owned()
        pbar.close()
        root_logger.handlers = original_handlers


def _submit_all(executor, plot_args, common_kwargs) -> dict:
    """Submit every plot_args entry to the executor and return {future: sub_key}."""
    futures: dict = {}
    for sub_key, focused_entries, is_dry_run in plot_args:
        future = executor.submit(
            worker_run, focused_entries, is_dry_run=is_dry_run, **common_kwargs,
        )
        futures[future] = sub_key
    return futures


def _consume_result(future, sub_key):
    """Collect one worker result or log its traceback; return result or None."""
    try:
        result, worker_stats, worker_events = future.result()
    except Exception:
        logger.error(f"Worker exception for [{sub_key}]:\n{traceback.format_exc()}")
        return None
    TimingStats.merge_worker_stats(worker_stats, worker_events)
    return result


def _render_parallel(plot_args, pbar, common_kwargs, needs_persistent_kaleido, handle_result) -> None:
    """Run plot_args in a ProcessPoolExecutor, calling handle_result on each completion."""
    max_workers = max(2, min(8, (os.cpu_count() or 4) - 2))
    logger.info(f"Using {max_workers} worker processes")
    with ProcessPoolExecutor(
        max_workers=max_workers,
        initializer=worker_init,
        initargs=(needs_persistent_kaleido,),
    ) as executor:
        futures = _submit_all(executor, plot_args, common_kwargs)
        for future in as_completed(futures):
            sub_key = futures[future]
            result = _consume_result(future, sub_key)
            handle_result(sub_key, result)
            pbar.update(1)


def _render_sequential(plot_args, pbar, common_kwargs, needs_persistent_kaleido, handle_result) -> None:
    """Run plot_args in-process, calling handle_result on each completion."""
    if needs_persistent_kaleido:
        ensure_kaleido_sync_server()
    for sub_key, focused_entries, is_dry_run in plot_args:
        result = generate_spec_plots(
            focused_entries, is_dry_run=is_dry_run, **common_kwargs,
        )
        handle_result(sub_key, result)
        pbar.update(1)


def render_all_work_items(
    plot_args,
    *,
    parallel: bool,
    output_formats,
    link_format,
    output_root: Path,
    source_labels,
    plotly_asset_path: Path,
    needs_persistent_kaleido: bool,
    results: dict,
    index_state,
    csv_path: Path,
) -> None:
    """Render every work item — parallel or sequential — into results and TSV index."""
    common_kwargs = {
        "output_formats": output_formats,
        "link_format": link_format,
        "output_root": output_root,
        "source_labels": source_labels,
        "plotly_asset_path": plotly_asset_path,
    }

    def handle_result(sub_key, result):
        handle_plot_result(sub_key, result, results, csv_path, index_state)

    with _tqdm_logging_context(len(plot_args)) as pbar:
        if parallel:
            _render_parallel(plot_args, pbar, common_kwargs, needs_persistent_kaleido, handle_result)
        else:
            _render_sequential(plot_args, pbar, common_kwargs, needs_persistent_kaleido, handle_result)


def render_key(work_item: tuple) -> tuple:
    """Stable (tmpl_index, focus_on, focus_val, group_by) identity for a work item.

    ``tmpl_index`` must index into the *full* templates list; subset callers
    must translate back. NOT ``template_signature`` — that dedup collapses
    many templates into one, which over-matches and breaks --test filtering.
    """
    _, tmpl_index, _, focus_val, focus_on, group_by = work_item
    return (tmpl_index, focus_on, focus_val, group_by)
