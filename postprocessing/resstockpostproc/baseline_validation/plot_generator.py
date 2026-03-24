"""Generate baseline validation plots from plot_definition.tsv.

Usage:
    python plot_generator.py                  # generate all plots
    python plot_generator.py --index 5        # generate only plot definition row 5
    python plot_generator.py --index 1-10     # generate rows 1 through 10
"""

import argparse
import csv
import logging
import math
import sys
import time
import traceback
from pathlib import Path

import yaml

import polars as pl

from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.baseline_validation.plotters import lrd_plotter, recs_plotter
from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    AggregationType,
    CoverageType,
    FileType,
    TruthSource,
    ViewType,
    Resolution,
)
from resstockpostproc.baseline_validation.io_managers.output_manager import save_figure
from resstockpostproc.baseline_validation.plotters.plot_config import get_second_category_column
from resstockpostproc.baseline_validation.utils import ensure_directory
from resstockpostproc.baseline_validation.data_processing.gather_data import get_plot_data, get_base_data
from resstockpostproc.baseline_validation.create_html import create_html_shell, append_html_row, create_html_from_csv
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow
from resstockpostproc.shared_utils.timing import TimingStats

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

SCHEMA_DIR = Path(__file__).parent / "schema"
PLOT_DEFINITION_TSV = SCHEMA_DIR / "plot_definition.tsv"
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
    "coverage": "Coverage",
}


def _resolve_footnotes(footnote_rules: list[dict], row: dict) -> list[str]:
    """Collect all notes whose attribute matchers match the given plot definition row.

    Each rule specifies attribute matchers (truth_source, quantity, metric, coverage).
    A rule matches when ALL its specified attributes equal the row's TSV column values.
    Unspecified attributes act as wildcards.
    """
    matched = []
    for rule in footnote_rules:
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
    "Coverage",
    "Group By",
    "Focus On",
    "Main Visualization",
    "Extra Visualization",
    "Data",
    "Discrepancy (CVRMSE)",
    "Discrepancy (NMBE)",
]


# ---------------------------------------------------------------------------
# Parsers: TSV columns → PlotSpec fields
# ---------------------------------------------------------------------------

METRIC_MAP = {
    "": (Resolution.year, AggregationType.total, ViewType.value_view),
    "total annual consumption": (Resolution.year, AggregationType.total, ViewType.value_view),
    "average annual consumption": (Resolution.year, AggregationType.average, ViewType.value_view),
    "total monthly consumption": (Resolution.month, AggregationType.total, ViewType.value_view),
    "average monthly consumption": (Resolution.month, AggregationType.average, ViewType.value_view),
    "annual consumption distribution": (Resolution.year, AggregationType.average, ViewType.distribution),
    "enduse penetration": (Resolution.year, AggregationType.total, ViewType.penetration),
    "average daily consumption": (Resolution.day_of_year, AggregationType.average, ViewType.value_view),
    "average hourly consumption": (Resolution.hour_of_day, AggregationType.average, ViewType.value_view),
    "average hourly consumption (summer)": (
        Resolution.hour_of_day_summer,
        AggregationType.average,
        ViewType.value_view,
    ),
    "average hourly consumption (winter)": (
        Resolution.hour_of_day_winter,
        AggregationType.average,
        ViewType.value_view,
    ),
    "average hourly consumption (matrix)": (
        Resolution.hour_of_day_matrix,
        AggregationType.average,
        ViewType.value_view,
    ),
    "average hourly consumption (8760)": (Resolution.hour_of_year, AggregationType.average, ViewType.value_view),
    "average hourly consumption (top 100 hours)": (
        Resolution.top_100_hours,
        AggregationType.average,
        ViewType.value_view,
    ),
    "hourly consumption vs temperature": (Resolution.hour_of_year, AggregationType.average, ViewType.temp_view),
}

EXTRA_VIZ_MAP = {
    "difference view": ViewType.diff_view,
    "temperature count": ViewType.temp_count_view,
}


def parse_metric(metric_str):
    """Convert Metric column to (Resolution, AggregationType, ViewType)."""
    if metric_str not in METRIC_MAP:
        raise ValueError(f"Unknown metric: {metric_str!r}")
    return METRIC_MAP[metric_str]


def parse_extra_viz(viz_str):
    """Convert Extra Visualization column to ViewType or None."""
    if not viz_str:
        return None
    if viz_str not in EXTRA_VIZ_MAP:
        raise ValueError(f"Unknown extra visualization: {viz_str!r}")
    return EXTRA_VIZ_MAP[viz_str]


def parse_quantity(quantity_str):
    """Convert Quantity column to DataCol."""
    if quantity_str == "Number of dwelling units":
        return DataCol.UNITS_COUNT
    if quantity_str == "All Enduses":
        return DataCol.ALL
    normalized = quantity_str.lower().replace(" ", "_")
    return DataCol(normalized)


def parse_coverage(coverage_str):
    """Convert Coverage column to CoverageType."""
    if coverage_str in ("all units", "all occupied units"):
        return CoverageType.all_units
    if coverage_str in ("units with non-zero consumption", "occupied units with non-zero consumption"):
        return CoverageType.users_only
    raise ValueError(f"Unknown coverage: {coverage_str!r}")


def parse_group_by(group_by_str):
    """Convert Group By column to aggregation_level string."""
    if group_by_str == "utility":
        return "eiaid"
    return group_by_str.lower().replace(" ", "_")


_MULTI_ENTITY_PREFIXES = ("stack of ", "tilemap ", "grouped ")


def _simplify_viz_label(viz_type):
    """Strip multi-entity prefixes for focused (single-entity) plots."""
    for prefix in _MULTI_ENTITY_PREFIXES:
        if viz_type.startswith(prefix):
            return viz_type[len(prefix):]
    return viz_type


# ---------------------------------------------------------------------------
# TSV reading
# ---------------------------------------------------------------------------


def read_plot_definition(index=None, test_only=False):
    """Read plot_definition.tsv and return list of (row_dict, [PlotSpec, ...]) tuples.

    Each TSV row produces 1-2 PlotSpecs (main + optional extra visualization).
    If index is provided, only return rows matching that index (int or range).
    If test_only is True, only return rows where Test column is "Yes".
    """
    # Determine which indices to include
    if isinstance(index, int):
        wanted = {index}
    elif isinstance(index, (set, list)):
        wanted = set(index)
    else:
        wanted = None  # all rows

    tasks = []
    with open(PLOT_DEFINITION_TSV, newline="") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            # Skip comment lines and blank rows
            idx_str = row.get("Index", "").strip()
            if not idx_str or idx_str.startswith("#"):
                continue

            row_index = int(idx_str)
            if wanted is not None and row_index not in wanted:
                continue

            if test_only and row.get("Test", "").strip() != "Yes":
                continue

            # Parse fields
            truth_source = TruthSource(row["Truth Source"])
            quantity = parse_quantity(row["Quantity"])
            resolution, agg_type, view = parse_metric(row["Metric"])
            coverage = parse_coverage(row["Coverage"])
            group_by = parse_group_by(row["Group By"])

            # Main PlotSpec
            main_spec = PlotSpec(
                truth_source=truth_source,
                quantity=quantity,
                resolution=resolution,
                aggregation_type=agg_type,
                coverage=coverage,
                aggregation_level=group_by,
                focus_on=None,
                view=view,
            )

            spec_entries = [
                (main_spec, "Main Visualization", row["Main Visualization"]),
            ]

            # Extra visualization (if present)
            extra_view = parse_extra_viz(row.get("Extra Visualization", ""))
            if extra_view:
                extra_spec = PlotSpec(
                    truth_source=truth_source,
                    quantity=quantity,
                    resolution=resolution,
                    aggregation_type=agg_type,
                    coverage=coverage,
                    aggregation_level=group_by,
                    focus_on=None,
                    view=extra_view,
                )
                spec_entries.append((extra_spec, "Extra Visualization", row.get("Extra Visualization", "")))

            tasks.append((row, spec_entries))

    return tasks


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


def _compute_discrepancy(data, plot_spec):
    """Compute CVRMSE and NMBE using raw values with global normalization (ASHRAE-style).

    NMBE  = Σ(ResStock - Ref) / Σ(Ref) × 100
    CVRMSE = sqrt(Σ(ResStock - Ref)² / n) / mean(Ref) × 100
    """
    if plot_spec.quantity == DataCol.ALL:
        return None, None
    if plot_spec.view in (ViewType.distribution, ViewType.penetration):
        return None, None

    # Determine value column
    if plot_spec.quantity == DataCol.UNITS_COUNT:
        val_col = "units_count"
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
    # Load duration curves: join on percent_time (consumption percentile rank)
    # not the raw hour index, which differs between sources after sorting
    res_str = str(plot_spec.resolution)
    if "percent_time" in data.columns:
        join_cols.append("percent_time")
    elif res_str in data.columns:
        join_cols.append(res_str)

    # Exclude "US Total" from multi-entity overviews to avoid double-counting.
    # Skip when focused on US Total itself (single-entity plot).
    if plot_spec.focus_on != "US Total":
        ref_rows = ref_rows.filter(pl.col(agg_col) != "US Total")
        rs_rows = rs_rows.filter(pl.col(agg_col) != "US Total")

    # Pair up reference and ResStock values
    ref_selected = ref_rows.select(join_cols + [pl.col(val_col).alias("ref_val")])
    rs_selected = rs_rows.select(join_cols + [pl.col(val_col).alias("rs_val")])
    paired = rs_selected.join(ref_selected, on=join_cols, how="inner")
    paired = paired.drop_nulls(["ref_val", "rs_val"])

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


def _generate_spec_plots(
    spec_entries,
    result_key,
    row,
    results,
    output_formats,
    link_format,
    csv_path,
    html_path,
    html_suffix_size,
    output_base,
    footnotes=None,
    source_labels=None,
):
    """Generate plots for a list of (PlotSpec, viz_col, viz_type_str) entries and update results."""
    for plot_spec, viz_col, viz_type_str in spec_entries:
        label = f"[{result_key}] {plot_spec.truth_source} {row['Quantity']} {row['Metric']} ({plot_spec.view})"
        try:
            logger.info(f"  Generating: {label}")
            data = get_plot_data(plot_spec)
            plot_func = get_plotting_function(plot_spec.truth_source)
            fig, title = plot_func(data, plot_spec)
            save_figure(fig, plot_spec, formats=output_formats,
                        footnotes=footnotes, source_labels=source_labels)

            # Build relative path from csv_path's directory to the plot file
            path_seg, file_title = plot_spec.get_file_path_and_name()
            rel_path = (
                Path(f"{plot_spec.truth_source} plots ({link_format})") / path_seg / f"{file_title}.{link_format.value}"
            )
            rel_path_str = str(rel_path).replace("\\", "/")
            results[result_key][viz_col] = f"{viz_type_str}({rel_path_str})"

            # For main visualization: save data CSV and compute discrepancy metrics
            if plot_spec.view == ViewType.value_view:
                # Save data CSV (expand list columns into individual columns)
                data_dir = output_base / f"{plot_spec.truth_source} data (csv)" / path_seg
                ensure_directory(data_dir)
                _unnest_list_columns(data).write_csv(data_dir / f"{file_title}.csv")
                rel_data = Path(f"{plot_spec.truth_source} data (csv)") / path_seg / f"{file_title}.csv"
                results[result_key]["Data"] = f"csv({str(rel_data).replace(chr(92), '/')})"

                # Compute discrepancy metrics
                cvrmse, nmbe = _compute_discrepancy(data, plot_spec)
                if cvrmse is not None:
                    results[result_key]["Discrepancy (CVRMSE)"] = f"{cvrmse:.1f}%"
                    results[result_key]["Discrepancy (NMBE)"] = f"{nmbe:.1f}%"

            logger.info(f"  OK: {label}")
        except Exception:
            tb = traceback.format_exc()
            results[result_key][viz_col] = f"FAILED: {viz_type_str}({tb})"
            logger.error(f"  FAILED: {label}\n{tb}")

    # Append one CSV + HTML row when all viz columns for this result_key are done
    _append_plot_row(csv_path, results[result_key])
    append_html_row(html_path, results[result_key], OUTPUT_COLUMNS, html_suffix_size)


def _trim_focus_for_test(focus_values):
    """Trim focus values to a minimal set for test mode.

    Keeps at most 3 values covering each distinct code path:
    - None (overview/multi-entity plot)
    - "US Total" (single-entity with special Group By handling)
    - One regular entity (single-entity with label simplification)
    """
    trimmed = []
    has_regular = False
    for v in focus_values:
        if v is None:
            trimmed.append(v)
        elif v == "US Total":
            trimmed.append(v)
        elif not has_regular:
            trimmed.append(v)
            has_regular = True
    return trimmed


def generate_plots(index=None, test_only=False):
    """Generate plots from plot_definition.tsv.

    Args:
        index: If provided, only generate plots for this row index (int),
               or a set/list of indices. If None, generate all plots.
        test_only: If True, only generate the test subset (Test=Yes rows)
                   with limited focus expansion.
    """
    wall_start = time.perf_counter()
    tasks = read_plot_definition(index, test_only=test_only)
    logger.info(f"Generating {len(tasks)} plot definition rows ({sum(len(s) for _, s in tasks)} total plots)...")

    footnote_rules = _load_footnote_rules()
    source_labels = workflow.data_source_labels

    output_formats = [FileType(fmt.value) for fmt in workflow.plots.output_formats]
    link_format = FileType.html if FileType.html in output_formats else output_formats[0]
    output_base = Path(workflow.output.output_dir) / workflow.output.run_name
    csv_path = output_base / "plot_index.csv"
    html_path = output_base / "plot_index.html"

    # Initialize the CSV (header only) and the HTML shell once up front.
    # The HTML embeds CSV data in a <script type="text/csv"> block at the
    # end of the file; append_html_row() performs O(1) appends there.
    csv_path.parent.mkdir(parents=True, exist_ok=True)
    with open(csv_path, "w", newline="") as f:
        csv.DictWriter(f, fieldnames=OUTPUT_COLUMNS).writeheader()
    html_suffix_size = create_html_shell(html_path, OUTPUT_COLUMNS)

    # Pass 1: Expand all focus values to determine total work items
    work_items = []
    for row, spec_entries in tasks:
        row_index = row["Index"]
        sample_spec = spec_entries[0][0]

        data_key = sample_spec.get_data_key()
        base_data = get_base_data(data_key)
        expand_col = "utility_name" if sample_spec.aggregation_level == "eiaid" else sample_spec.aggregation_level
        focus_values = sorted(v for v in base_data[expand_col].unique().to_list() if v is not None)

        # Skip "US Total" for non-state aggregations; put it first for state
        if sample_spec.aggregation_level != "state":
            focus_values = [v for v in focus_values if v != "US Total"]
        elif "US Total" in focus_values:
            focus_values.remove("US Total")
            focus_values.insert(0, "US Total")

        # Prepend None for the unfocused overview plot (skip for plots that
        # require a specific focus entity: ALL enduse plots and matrix layout)
        if sample_spec.quantity != DataCol.ALL and sample_spec.resolution != Resolution.hour_of_day_matrix:
            focus_values.insert(0, None)

        if test_only:
            focus_values = _trim_focus_for_test(focus_values)

        for focus_val in focus_values:
            work_items.append((row, spec_entries, row_index, focus_val))

    total = len(work_items)
    logger.info(f"Total plot groups to generate: {total}")

    # Pass 2: Generate plots with progress tracking
    results = {}
    for i, (row, spec_entries, row_index, focus_val) in enumerate(work_items, 1):
        if focus_val is None:
            sub_key = row_index
        else:
            sub_key = f"{row_index}_{focus_val}"

        results[sub_key] = {col: row.get(col, "") for col in OUTPUT_COLUMNS}
        results[sub_key]["Index"] = i
        results[sub_key]["Focus On"] = focus_val or ""
        if focus_val == "US Total":
            results[sub_key]["Group By"] = ""
        # Only highlight the summary row (unfocused overview, or US Total when overview is skipped)
        if focus_val is not None and focus_val != "US Total":
            results[sub_key]["Highlight"] = ""
        results[sub_key]["Main Visualization"] = ""
        results[sub_key]["Extra Visualization"] = ""

        focused_entries = [
            (spec.model_copy(update={"focus_on": focus_val}), viz_col,
             _simplify_viz_label(viz_type) if focus_val else viz_type)
            for spec, viz_col, viz_type in spec_entries
        ]

        matched_notes = _resolve_footnotes(footnote_rules, row)

        logger.info(f"[{i}/{total}] ({i * 100 // total}%)")
        _generate_spec_plots(
            focused_entries,
            sub_key,
            row,
            results,
            output_formats,
            link_format,
            csv_path,
            html_path,
            html_suffix_size,
            output_base,
            footnotes=matched_notes or None,
            source_labels=source_labels or None,
        )

    # Summary
    ok = sum(
        1
        for r in results.values()
        for col in ("Main Visualization", "Extra Visualization")
        if r[col] and not r[col].startswith("FAILED:")
    )
    failed = sum(
        1
        for r in results.values()
        for col in ("Main Visualization", "Extra Visualization")
        if r[col].startswith("FAILED:")
    )
    logger.info(f"Done: {ok} succeeded, {failed} failed, {ok + failed} total")

    # Timing profiling summary
    wall_elapsed = time.perf_counter() - wall_start
    logger.info(
        "\n=== Timing Summary ===\n%s\n%s\nTotal wall clock time: %.2fs",
        TimingStats.summary(),
        "-" * 95,
        wall_elapsed,
    )


def _append_plot_row(csv_path, row_dict):
    """Append a single result row to plot_index.csv (O(1) append)."""
    with open(csv_path, "a", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=OUTPUT_COLUMNS)
        writer.writerow(row_dict)


# ---------------------------------------------------------------------------
# Convenience wrappers
# ---------------------------------------------------------------------------


def generate_eia_plots():
    """Generate only EIA plots."""
    tasks = read_plot_definition()
    eia_indices = {int(row["Index"]) for row, _ in tasks if row["Truth Source"] == "eia"}
    generate_plots(index=eia_indices)


def generate_recs_plots():
    """Generate only RECS plots."""
    tasks = read_plot_definition()
    recs_indices = {int(row["Index"]) for row, _ in tasks if row["Truth Source"] == "recs"}
    generate_plots(index=recs_indices)


def generate_lrd_plots():
    """Generate only LRD plots."""
    tasks = read_plot_definition()
    lrd_indices = {int(row["Index"]) for row, _ in tasks if row["Truth Source"] == "lrd"}
    generate_plots(index=lrd_indices)


def generate_test_plots():
    """Generate only test subset plots (rows with Test=Yes, limited focus expansion)."""
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
    parser = argparse.ArgumentParser(description="Generate baseline validation plots from plot_definition.tsv")
    parser.add_argument(
        "--index", type=str, default=None, help="Plot definition index to generate (e.g. '5', '1-10', '1,3,5')"
    )
    parser.add_argument(
        "--test", action="store_true", default=True,
        help="Generate only test subset plots (rows with Test=Yes, limited focus expansion)",
    )
    args = parser.parse_args()

    index = parse_index_arg(args.index) if args.index else None
    generate_plots(index=index, test_only=args.test)
    return 0


if __name__ == "__main__":
    sys.exit(main())
