"""Synthetic All Enduses stacked-page generation helpers.

Extracted from plot_generator.py in refactor plan V2 step 3.4. These helpers
decide when to synthesize an All Enduses stacked page from per-quantity
grouped plots, reshape per-quantity data into the tall ALL-enduses schema,
assemble the combined table data, and collect deduplicated footnotes.
"""

from __future__ import annotations

import logging
from pathlib import Path

import polars as pl
from tqdm import tqdm

from resstockpostproc.baseline_validation.footnotes import (
    dedupe_note_groups,
    get_plot_notes,
    get_table_notes,
)
from resstockpostproc.baseline_validation.create_html import append_index_row
from resstockpostproc.baseline_validation.data_processing.gather_data import get_plot_data
from resstockpostproc.baseline_validation.generation.render_runner import append_plot_row, plot_output_path
from resstockpostproc.baseline_validation.schema.plot_spec import (
    ALL_ENDUSES_DISPLAY,
    ComparisonDataset,
    FileType,
    Metric,
    PlotSpec,
    Resolution,
    ViewType,
)
from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.baseline_validation.dashboard_paths import (
    dashboard_html_path,
    dataset_output_dir,
    relative_href_from_file,
)
from resstockpostproc.baseline_validation.utils import ensure_directory

logger = logging.getLogger(__name__)


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


# ---------------------------------------------------------------------------
# Pass 4 driver: synthesize "All Enduses (Stacked)" pages from per-quantity
# raw Plotly HTML written during Pass 3.
# ---------------------------------------------------------------------------


def _raw_path(output_root: Path, spec: PlotSpec, link_format: FileType) -> Path:
    """Return the `.raw.<fmt>` sibling path for a spec's Pass 3 plot output."""
    raw_path = plot_output_path(output_root, spec, link_format)
    return raw_path.with_name(f"{raw_path.stem}.raw.{link_format.value}")


def _write_stacked_view_html(
    view_spec: PlotSpec,
    paths: list[Path],
    *,
    output_root: Path,
    link_format: FileType,
    path_seg: str,
    scale_x: float,
    scale_y: float,
    plot_notes,
    source_labels,
    plotly_asset_path: Path,
) -> tuple[PlotSpec, Path]:
    """Post-process per-quantity raw HTML into a single combined stacked page file."""
    from resstockpostproc.baseline_validation.io_managers.html_utils import postprocess_plot_html
    from resstockpostproc.baseline_validation.io_managers.output_manager import plotly_cdn_url

    all_view_spec = view_spec.model_copy(update={"quantity": DataCol.ALL})
    _, grouped_title = all_view_spec.file_path_and_name
    title = stacked_title_from_grouped(grouped_title, all_view_spec.view)
    out = (
        dataset_output_dir(output_root, str(all_view_spec.comparison_dataset), "plots", link_format.value)
        / path_seg
        / f"{title}.{link_format.value}"
    )
    ensure_directory(out.parent)
    postprocess_plot_html(
        paths, output_path=out, footnotes=plot_notes,
        source_labels=source_labels, scale_x=scale_x, scale_y=scale_y,
        comparison_dataset=all_view_spec.comparison_dataset.value,
        plotly_cdn_src=plotly_cdn_url(),
        plotly_asset_path=plotly_asset_path,
    )
    return all_view_spec, out


def _build_stacked_views_for_group(
    qty_entries: list[tuple[str, list[tuple[PlotSpec, str]]]],
    *,
    output_root: Path,
    link_format: FileType,
    path_seg: str,
    scale_x: float,
    scale_y: float,
    plot_notes,
    source_labels,
    plotly_asset_path: Path,
    dashboard_path: Path,
    viz_parts: list[str],
) -> list[tuple[int, PlotSpec, str]]:
    """Build one stacked page per view position, appending viz labels and returning outputs."""
    stacked_outputs: list[tuple[int, PlotSpec, str]] = []
    for i, _ in enumerate(qty_entries[0][1]):
        view_spec = qty_entries[0][1][i][0]
        paths = [
            p for p in (_raw_path(output_root, e[i][0], link_format) for _, e in qty_entries if i < len(e))
            if p.exists()
        ]
        if len(paths) < 2:
            continue
        all_view_spec, out = _write_stacked_view_html(
            view_spec, paths,
            output_root=output_root, link_format=link_format, path_seg=path_seg,
            scale_x=scale_x, scale_y=scale_y,
            plot_notes=plot_notes, source_labels=source_labels,
            plotly_asset_path=plotly_asset_path,
        )
        rel_str = relative_href_from_file(out, dashboard_path)
        stacked_label = all_enduses_viz_label(all_view_spec, stacked=True)
        viz_parts.append(f"{stacked_label}||{rel_str}")
        stacked_outputs.append((i, all_view_spec, str(out)))
    return stacked_outputs


def _maybe_build_stacked_table(
    stacked_outputs: list[tuple[int, PlotSpec, str]],
    qty_entries: list[tuple[str, list[tuple[PlotSpec, str]]]],
    first_spec: PlotSpec,
    group_by_label: str,
    *,
    output_root: Path,
    path_seg: str,
    dashboard_path: Path,
    table_notes,
    source_labels,
    cache: dict[tuple, pl.DataFrame],
) -> str:
    """Build the stacked data-table HTML when eligible; return its `data table||<rel>` string."""
    if not stacked_outputs:
        return ""
    if not should_generate_stacked_table(
        group_by_label, first_spec.comparison_dataset, first_spec.resolution, first_spec.aggregation_type
    ):
        return ""
    from resstockpostproc.baseline_validation.io_managers.data_table import generate_data_table_html

    table_view_index, table_spec, table_rel_plot = next(
        (o for o in stacked_outputs if o[1].view == ViewType.value_view),
        stacked_outputs[0],
    )
    stacked_data = build_stacked_table_data(qty_entries, table_view_index, cache)
    if stacked_data.is_empty():
        return ""

    stacked_plot_path = Path(table_rel_plot)
    table_dir = (
        dataset_output_dir(output_root, str(table_spec.comparison_dataset), "data", FileType.html.value)
        / path_seg
    )
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
    return f"data table||{rel_table}"


def _build_stacked_row(
    group_key: tuple,
    viz_parts: list[str],
    data_rel: str,
) -> dict[str, str]:
    """Construct the TSV row dict for a synthetic stacked page group."""
    ds, metric, coverage, f1, f2, gb = group_key
    return {
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


def generate_stacked_pages(
    stacking_groups: dict[tuple, list[tuple[str, list[tuple[PlotSpec, str]]]]],
    *,
    output_root: Path,
    link_format: FileType,
    source_labels,
    plotly_asset_path: Path,
    results: dict,
    index_state,
    csv_path: Path,
) -> int:
    """Synthesize All Enduses (Stacked) pages across eligible quantity groups."""
    eligible_groups = {k: v for k, v in stacking_groups.items() if should_generate_stacked_page_group(v)}
    dashboard_path = dashboard_html_path(output_root)
    table_data_cache: dict[tuple, pl.DataFrame] = {}
    stacked_count = 0

    stacked_pbar = tqdm(
        eligible_groups.items(), total=len(eligible_groups),
        desc="Generating stacked pages", unit="page",
        bar_format="{desc}: {percentage:6.2f}%|{bar}| {n_fmt}/{total_fmt} [{elapsed}<{remaining}]",
    )
    for group_key, qty_entries in stacked_pbar:
        _ds, _metric, _coverage, _f1, _f2, gb = group_key
        first_spec = qty_entries[0][1][0][0]
        path_seg = first_spec.file_path_and_name[0]
        scale_x, scale_y = (1.0, 1.0) if gb in ("State", "") else (0.75, 0.5)

        plot_notes = collect_stacked_notes(qty_entries, get_plot_notes)
        table_notes = collect_stacked_notes(qty_entries, get_table_notes)

        viz_parts: list[str] = []
        stacked_outputs = _build_stacked_views_for_group(
            qty_entries,
            output_root=output_root, link_format=link_format, path_seg=path_seg,
            scale_x=scale_x, scale_y=scale_y,
            plot_notes=plot_notes, source_labels=source_labels,
            plotly_asset_path=plotly_asset_path, dashboard_path=dashboard_path,
            viz_parts=viz_parts,
        )
        stacked_count += len(stacked_outputs)
        if not viz_parts:
            continue

        data_rel = _maybe_build_stacked_table(
            stacked_outputs, qty_entries, first_spec, gb,
            output_root=output_root, path_seg=path_seg, dashboard_path=dashboard_path,
            table_notes=table_notes, source_labels=source_labels, cache=table_data_cache,
        )
        row = _build_stacked_row(group_key, viz_parts, data_rel)
        results[f"stacked_{stacked_count}"] = row
        if index_state is not None:
            append_plot_row(csv_path, row)
            append_index_row(index_state, row)

    stacked_pbar.close()
    return stacked_count
