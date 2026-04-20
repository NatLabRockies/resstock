"""Render execution and worker lifecycle for baseline validation plot generation.

Extracted from plot_generator.py in refactor plan V2 step 3.2. This module
owns:
- Plot rendering per-spec (generate_spec_plots)
- Worker pool init/run helpers (worker_init, worker_run) — the names are
  pickled by ProcessPoolExecutor, so their module path must stay stable.
- Kaleido sync-server ownership (ensure_kaleido_sync_server, stop_kaleido_sync_server_if_owned)
- Output path derivation for plots and data tables
- Dispatch to the right plotter by comparison dataset
"""

from __future__ import annotations

import csv
import logging
import os
import sys
import traceback
from pathlib import Path

import polars as pl
from plotly import graph_objects as go

from resstockpostproc.baseline_validation.create_html import append_index_row
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
from resstockpostproc.baseline_validation.plot_semantics import (
    format_source_label,
    resolve_timeseries_column,
)
from resstockpostproc.baseline_validation.plotters import lrd_plotter, main_plotter
from resstockpostproc.baseline_validation.plotters.plot_config import (
    get_second_category_column,
)
from resstockpostproc.baseline_validation.schema.plot_spec import (
    ComparisonDataset,
    FileType,
    PlotSpec,
    ViewType,
)
from resstockpostproc.baseline_validation.utils import ensure_directory
from resstockpostproc.shared_utils.db_column_names import DataCol
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
    """Start the process-local Kaleido sync server if needed.

    Returns True only when this module started the server and therefore owns
    shutting it down later.
    """
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


@timed
def compute_discrepancy(data, plot_spec) -> dict[str, float]:
    """Compute MAPE (%) for each ResStock source.

    MAPE = mean(|ResStock - Ref| / |Ref|) × 100

    Rows with zero reference values are excluded. Returns a dict keyed by
    formatted source label (e.g. "ResStock 2025"), with per-source MAPE (%)
    values. Empty dict when metrics cannot be computed.
    """
    if plot_spec.is_all_enduses:
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
    ts_col = resolve_timeseries_column(plot_spec)
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

        metrics[format_source_label(rs_source)] = float(term_df["mape_term"].mean() * 100.0)

    return metrics


def plot_output_path(output_root: Path, plot_spec: PlotSpec, fmt: FileType) -> Path:
    """Return the absolute output path for a plot artifact."""
    path_seg, file_title = plot_spec.file_path_and_name
    return dataset_output_dir(output_root, str(plot_spec.comparison_dataset), "plots", fmt.value) / path_seg / f"{file_title}.{fmt.value}"


def data_output_path(output_root: Path, plot_spec: PlotSpec, fmt: FileType) -> Path:
    """Return the absolute output path for a data artifact."""
    path_seg, file_title = plot_spec.file_path_and_name
    return dataset_output_dir(output_root, str(plot_spec.comparison_dataset), "data", fmt.value) / path_seg / f"{file_title}.{fmt.value}"


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
    """Generate plots for a list of (PlotSpec, viz_type_str) entries.

    Footnotes are computed per-spec via get_plot_notes/get_table_notes so that
    layout-specific notes (e.g. histogram overflow) appear only where relevant.

    Returns (viz_parts_joined, data_rel_path) on success, or None if skipped.
    All file I/O writes to unique per-spec paths (safe for parallel execution).

    When `is_dry_run` is True, actual plotting/HTML/SVG/data-table writes are
    skipped. The row's `Comparison Plot` and `Data` columns are still populated
    with predicted paths, which lets --test runs produce a TSV byte-identical
    to a full run (the paths just don't exist on disk).
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
    """Apply a worker's result to shared state (main process only).

    When `index_state` is None, skip the incremental TSV/shard/HTML writes.
    The caller is responsible for materializing everything at the end by
    calling `_rewrite_index_in_sorted_order` from the in-memory `results`.
    """
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


def render_key(work_item: tuple) -> tuple:
    """Stable identity for a work item.

    Keys by `(tmpl_index, focus_on, focus_val, group_by)`. `tmpl_index` is
    expected to be an index into the *full* `templates` list — so the side pass
    that builds `render_keys` must translate its subset-local indices back to
    full-list positions before using this key (see generate_plots).

    Previously this used `template_signature(tmpls[tmpl_index])`. That was
    incorrect: `template_signature` deduplicates templates (e.g., collapses
    many RECS quantity/view/metric templates into one signature), so the key
    over-matched — every template sharing a subset template's signature would
    satisfy the membership check and get rendered. Using the raw tmpl_index
    restricts rendering to exactly the templates `get_test_template_indices`
    picks.
    """
    _, tmpl_index, _, focus_val, focus_on, group_by = work_item
    return (tmpl_index, focus_on, focus_val, group_by)
