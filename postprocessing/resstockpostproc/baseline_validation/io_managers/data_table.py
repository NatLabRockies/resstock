"""Generate interactive HTML data table pages for baseline validation plots.

Each table page shows the plot's data in a pivoted, sortable format with
discrepancy metrics (MAPE) and navigation links back to the plot
and the plot index.
"""

import json
from pathlib import Path

import polars as pl

from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    CoverageType,
    Resolution,
    ViewType,
    format_group_by,
)
from resstockpostproc.baseline_validation.plotters.plot_config import (
    get_second_category_column,
    get_second_category_title,
)
from resstockpostproc.baseline_validation.plot_semantics import (
    format_source_label,
    resolve_quantity_title,
    resolve_timeseries_column,
)
from resstockpostproc.baseline_validation.io_managers.html_utils import _build_footer_html
from resstockpostproc.shared_utils.timing import timed


# Page size for client-side pagination (large tables render in chunks)
_PAGE_SIZE = 500

# Columns and suffixes to always drop from the table
_DROP_SUFFIXES = (
    "_rse",
    "_upper_bound",
    "_lower_bound",
    "_value_resolution",
    "_quartiles",           # raw list columns (pre-unnest)
    "_nonzero_quartiles",   # raw list columns (pre-unnest)
)

_DROP_EXACT = {
    "timestamp",
    "rows_per_sample",
    "customers",
    "natural_gas_total_customers",
    "outdoor_drybulb_temp_value",
    "percent_time",
    "utility_vertical",
    "eiaid",
}

_DROP_CONTAINS = (
    "_quartiles_",
    "_nonzero_quartiles_",
)

# Quartile list indices that carry semantic meaning (the 9-element list in
# stacked_plotter._add_quartile_cols uses these positions; others are unused).
_QUARTILE_INDICES = [
    (0, "min"),
    (3, "q1"),
    (4, "median"),
    (5, "q3"),
    (8, "max"),
]

# Per-enduse wide columns start with one of these fuel prefixes.
_FUEL_PREFIXES_TUPLE = ("electricity_", "natural_gas_", "propane_", "fuel_oil_")


def _melt_enduse_columns(data: pl.DataFrame) -> pl.DataFrame:
    """Melt wide per-enduse columns into tall form with an 'enduse' label column.

    Each row (entity, source) becomes N rows (entity, source, enduse). Enduse
    columns are renamed from their fuel/enduse prefix to a single ``all_`` prefix
    (matching ``DataCol.ALL.value``), so downstream logic keyed on
    ``plot_spec.quantity`` continues to work unchanged.

    Used only for ALL-quantity RECS plots.
    """
    enduse_prefixes = sorted({
        c.removesuffix("_value")
        for c in data.columns
        if c.startswith(_FUEL_PREFIXES_TUPLE) and c.endswith("_value")
    })
    if not enduse_prefixes:
        return data

    id_cols = [c for c in data.columns if not c.startswith(_FUEL_PREFIXES_TUPLE)]

    def _label(prefix: str) -> str:
        try:
            return DataCol(prefix).label
        except ValueError:
            return prefix.replace("_", " ").title()

    dfs = []
    for prefix in enduse_prefixes:
        cols = [c for c in data.columns if c.startswith(f"{prefix}_")]
        rename_map = {c: c.replace(f"{prefix}_", "all_", 1) for c in cols}
        sub = data.select(id_cols + cols).rename(rename_map)
        # Cast numeric 'all_*' columns to Float64 — sparse enduses can produce
        # Int64 nulls that break diagonal_relaxed concat schema unification.
        cast_cols = [
            c for c in sub.columns
            if c.startswith("all_") and sub[c].dtype.is_numeric()
        ]
        sub = sub.with_columns(pl.col(c).cast(pl.Float64) for c in cast_cols)
        sub = sub.with_columns(pl.lit(_label(prefix)).alias("enduse"))
        dfs.append(sub)

    return pl.concat(dfs, how="diagonal_relaxed")


def _normalize_model_count_columns(data: pl.DataFrame, plot_spec: PlotSpec) -> pl.DataFrame:
    """Align table count columns with displayed plot semantics.

    For users_only tables, model_count is the display count shown in hover/table
    labels. Non-ALL plots already normalize it upstream; ALL-enduse tables still
    carry per-enduse nonzero counts as ``all_nonzero_sample_count`` after melt.
    Normalize model_count from the appropriate nonzero count when present, then
    drop raw ``*_nonzero_sample_count`` columns so tables do not expose duplicate
    or stale count columns.

    Also scales units_count to the users-only subset (units_count * percent_users
    / 100) so "Dwelling Units" stays in sync with "Number of Models/Samples".
    """
    nonzero_cols = [c for c in data.columns if c.endswith("_nonzero_sample_count")]
    if not nonzero_cols:
        return data

    if plot_spec.coverage == CoverageType.users_only:
        quantity = plot_spec.quantity
        target_col = "all_nonzero_sample_count" if quantity == DataCol.ALL else f"{quantity}_nonzero_sample_count"
        if target_col in data.columns:
            replacement = pl.col(target_col).cast(pl.Int64, strict=False)
            if "model_count" in data.columns:
                data = data.with_columns(
                    replacement.fill_null(pl.col("model_count").cast(pl.Int64, strict=False)).alias("model_count")
                )
            else:
                data = data.with_columns(replacement.alias("model_count"))

        percent_users_col = (
            "all_percent_users" if quantity == DataCol.ALL else f"{quantity}_percent_users"
        )
        if "units_count" in data.columns and percent_users_col in data.columns:
            data = data.with_columns(
                (pl.col("units_count") * pl.col(percent_users_col) / 100.0)
                .round(0)
                .alias("units_count")
            )

    return data.drop(nonzero_cols)


def _extract_quartile_columns(data: pl.DataFrame, plot_spec: PlotSpec) -> pl.DataFrame:
    """Extract scalar min/q1/median/q3/max columns from the raw quartile list column.

    Mirrors stacked_plotter._add_quartile_cols. Coverage selects which list column
    to read: all_units → ``_quartiles``; users_only → ``_nonzero_quartiles``.
    """
    quantity = plot_spec.quantity
    list_col = (
        f"{quantity}_nonzero_quartiles"
        if plot_spec.coverage == CoverageType.users_only
        else f"{quantity}_quartiles"
    )
    if list_col not in data.columns:
        return data
    return data.with_columns([
        pl.col(list_col).list.get(idx).cast(pl.Float64).alias(f"{quantity}_{name}")
        for idx, name in _QUARTILE_INDICES
    ])

@timed
def _filter_columns(data: pl.DataFrame, plot_spec: PlotSpec) -> pl.DataFrame:
    """Drop irrelevant columns, keeping only comparison-meaningful ones."""
    # Protect structural columns (join keys) from being dropped
    entity_col = get_second_category_column(plot_spec)
    ts_col = resolve_timeseries_column(plot_spec)
    structural = {entity_col, "source"}
    if ts_col:
        structural.add(str(ts_col))
    if "enduse" in data.columns:
        structural.add("enduse")

    keep_percent_users = plot_spec.is_penetration_metric or plot_spec.coverage == CoverageType.users_only
    keep_model_count = any(
        plot_spec.model_count_display_label_for_source(str(source)) is not None
        for source in data["source"].unique(maintain_order=True).to_list()
    )

    drop_cols = []
    for col in data.columns:
        if col in structural:
            continue

        # Exact matches
        if col in _DROP_EXACT:
            drop_cols.append(col)
            continue

        # Suffix matches
        if any(col.endswith(s) for s in _DROP_SUFFIXES):
            drop_cols.append(col)
            continue

        # Substring matches (quartiles)
        if any(sub in col for sub in _DROP_CONTAINS):
            drop_cols.append(col)
            continue

        # Drop percent_users columns unless relevant
        if not keep_percent_users and ("_percent_users" in col):
            drop_cols.append(col)
            continue

        if col == "model_count" and not keep_model_count:
            drop_cols.append(col)
            continue

        # Drop units_count_percent_difference unless the main quantity is dwelling units
        if col == "units_count_percent_difference" and plot_spec.quantity != DataCol.UNITS_COUNT:
            drop_cols.append(col)
            continue

        # For value_view, drop percent_users percent_difference — only the value diff matters
        if plot_spec.view == ViewType.value_view and col.endswith("_percent_users_percent_difference"):
            drop_cols.append(col)
            continue

        # For penetration views, drop _value columns — only percent_users matters
        if plot_spec.is_penetration_metric:
            if col.endswith("_value") or col.endswith("_value_percent_difference"):
                drop_cols.append(col)
                continue

        # For distribution view, drop the single percent_difference column
        # (it compares means, not distributions, and is unintuitive next to quartiles).
        if plot_spec.is_distribution_metric and col.endswith("_percent_difference"):
            drop_cols.append(col)
            continue

        # For hour_of_day_matrix, utility/month/day_type are already encoded in
        # the combined month_daytype entity column + focus_on, so per-source
        # copies of these split columns carry no new information.
        if plot_spec.resolution == Resolution.hour_of_day_matrix and col in {"utility", "month", "day_type"}:
            drop_cols.append(col)
            continue

    return data.drop(drop_cols)

@timed
def _pivot_by_source(
    data: pl.DataFrame,
    plot_spec: PlotSpec,
) -> tuple[pl.DataFrame, str, list[str]]:
    """Pivot long-format data to wide format, with sources as column groups.

    Each ResStock source becomes its own column group with:
      - "{rs_label}: {value_col}"
      - "{rs_label} Difference (%)" (from the existing percent_difference column)

    The reference (e.g. EIA 2018) gets its own group: "{ref_label}: {value_col}".

    Returns:
        (pivoted_df, ref_label, rs_labels) where rs_labels is a sorted list like
        ["ResStock 2024", "ResStock 2025"].
    """
    entity_col = get_second_category_column(plot_spec)
    ts_col = resolve_timeseries_column(plot_spec)

    # Identify join columns (dimensions)
    join_cols = [entity_col]
    if ts_col and str(ts_col) in data.columns:
        join_cols.append(str(ts_col))
    if "enduse" in data.columns:
        join_cols.append("enduse")

    # Identify all source labels (source values are already human-readable
    # display labels from apply_plot_spec, e.g. "EIA 2018", "ResStock 2025").
    comparison_val = plot_spec.comparison_dataset.value
    sources = data["source"].unique().to_list()
    ref_sources = [s for s in sources if comparison_val in s.lower()]
    ref_label = ref_sources[0] if ref_sources else comparison_val.upper()
    rs_labels = sorted(s for s in sources if "resstock" in s.lower())

    # Split by source (case-insensitive matching)
    ref_df = data.filter(pl.col("source").str.to_lowercase().str.contains(comparison_val))

    # Determine value columns to pivot (everything that's not a join col or source)
    skip_cols = set(join_cols) | {"source"}
    value_cols = [c for c in data.columns if c not in skip_cols]
    diff_cols = [c for c in value_cols if c.endswith("_percent_difference")]
    non_diff_cols = [c for c in value_cols if c not in diff_cols]

    # Select and rename reference columns (no diff cols on the reference side)
    ref_available = [c for c in non_diff_cols if c in ref_df.columns]
    pivoted = ref_df.select(
        join_cols + [pl.col(c).alias(f"{ref_label}: {c}") for c in ref_available]
    )

    # Add each ResStock source as its own column group
    for rs_label in rs_labels:
        rs_df = data.filter(pl.col("source") == rs_label)
        rs_non_diff = [c for c in non_diff_cols if c in rs_df.columns]
        rs_diff_available = [c for c in diff_cols if c in rs_df.columns]

        rs_select_exprs = (
            [pl.col(c) for c in join_cols]
            + [pl.col(c).alias(f"{rs_label}: {c}") for c in rs_non_diff]
            + [pl.col(c).alias(f"{rs_label} Difference (%): {c}") for c in rs_diff_available]
        )
        rs_renamed = rs_df.select(rs_select_exprs)
        pivoted = pivoted.join(rs_renamed, on=join_cols, how="full", coalesce=True)

    return pivoted, ref_label, rs_labels


def _build_column_config(
    data: pl.DataFrame,
    plot_spec: PlotSpec,
    ref_label: str,
    rs_labels: list[str],
) -> list[dict]:
    """Build column metadata for the HTML table (header labels, formats, types)."""
    columns = data.columns
    units = resolve_quantity_title(plot_spec)
    entity_col = get_second_category_column(plot_spec)
    if entity_col == "month_daytype":
        # hour_of_day_matrix: entity column carries month_daytype strings,
        # so its header should match the plotter's second-category title.
        entity_label = get_second_category_title(plot_spec)
    else:
        agg = plot_spec.group_by or plot_spec.effective_group_by[-1]
        entity_label = format_group_by(agg)

    ts_col = resolve_timeseries_column(plot_spec)

    abs_diff_units = "percentage points" if units == "%" else units
    is_distribution = plot_spec.is_distribution_metric

    config = []
    for col in columns:
        # Dimension columns
        if col == entity_col:
            config.append({"key": col, "label": entity_label, "type": "string", "format": ""})
            continue

        if ts_col and col == str(ts_col):
            if col == "resstock_temp":
                label = "Temperature (°F)"
            else:
                label = col.replace("_", " ").title() if "_" in col else col.title()
            # Numeric ts columns (e.g. resstock_temp, hour of day) need "number"
            # type so client-side sorting compares values as numbers, not strings.
            col_type = "number" if data[col].dtype.is_numeric() else "string"
            col_format = ",.0f" if col_type == "number" else ""
            config.append({"key": col, "label": label, "type": col_type, "format": col_format})
            continue

        if col == "enduse":
            config.append({"key": col, "label": "End Use", "type": "string", "format": ""})
            continue

        # Per-source ResStock columns
        matched = False
        for rs_label in rs_labels:
            abs_diff_prefix = f"{rs_label} Difference ({abs_diff_units}): "
            pct_diff_prefix = f"{rs_label} Difference (%): "
            value_prefix = f"{rs_label}: "
            if col.startswith(abs_diff_prefix):
                config.append({
                    "key": col,
                    "label": f"{rs_label} Difference ({abs_diff_units})",
                    "type": "abs_diff",
                    "format": "+,.1f",
                })
                matched = True
                break
            if col.startswith(pct_diff_prefix):
                config.append({
                    "key": col,
                    "label": f"{rs_label} Difference (%)",
                    "type": "diff",
                    "format": "+.1f%",
                })
                matched = True
                break
            if col.startswith(value_prefix):
                raw_name = col[len(value_prefix):]
                config.append({
                    "key": col,
                    "label": _humanize_column(
                        raw_name,
                        rs_label,
                        units,
                        is_distribution,
                        plot_spec.model_count_display_label_for_source(rs_label),
                    ),
                    "type": "number",
                    "format": ",.1f",
                })
                matched = True
                break
        if matched:
            continue

        # Reference columns
        if col.startswith(f"{ref_label}: "):
            raw_name = col[len(f"{ref_label}: "):]
            config.append({
                "key": col,
                "label": _humanize_column(
                    raw_name,
                    ref_label,
                    units,
                    is_distribution,
                    plot_spec.model_count_display_label_for_source(ref_label),
                ),
                "type": "number",
                "format": ",.1f",
            })
            continue

        # Fallback
        config.append({"key": col, "label": col.replace("_", " ").title(), "type": "string", "format": ""})

    return config


_QUARTILE_SUFFIX_LABELS = {
    "_min": "Min",
    "_q1": "Q1",
    "_median": "Median",
    "_q3": "Q3",
    "_max": "Max",
}


def _humanize_column(
    raw_name: str,
    source_prefix: str,
    units: str,
    is_distribution: bool = False,
    model_count_label: str | None = None,
) -> str:
    """Convert a raw column name like 'electricity_total_value' into a human-readable header.

    When ``is_distribution`` is True, ``_value`` columns are labeled "Average"
    so they sit naturally alongside the Min/Q1/Median/Q3/Max quartile columns.
    """
    if raw_name == "units_count":
        return f"{source_prefix}: Dwelling Units"
    if raw_name == "model_count":
        label = model_count_label or "Model Count"
        return f"{source_prefix}: {label}"
    if raw_name == "temp_count":
        return f"{source_prefix}: Hour Count"
    if "percent_users" in raw_name and "percent_difference" not in raw_name:
        return f"{source_prefix}: % Users"
    if raw_name.endswith("_value"):
        if is_distribution:
            return f"{source_prefix}: Average ({units})"
        return f"{source_prefix} ({units})"
    for suffix, label in _QUARTILE_SUFFIX_LABELS.items():
        if raw_name.endswith(suffix):
            return f"{source_prefix}: {label} ({units})"

    # Fallback: clean up the raw name
    clean = raw_name.replace("_", " ").title()
    return f"{source_prefix}: {clean}"

@timed
def _build_table_html(
    data: pl.DataFrame,
    col_config: list[dict],
    plot_spec: PlotSpec,
    plot_rel_path: str | None,
    metrics_by_source: dict[str, float],
    footnotes: list[str] | None,
    source_labels: dict | None,
    ref_label: str,
    rs_sources_js: list[dict[str, str]],
    csv_download_filename: str | None = None,
    include_discrepancy_metrics: bool = True,
) -> str:
    """Build a self-contained HTML page with an interactive data table.

    Args:
        metrics_by_source: Mapping of ResStock label → MAPE (%).
        rs_sources_js: List of {label, refKey, absDiffKey} dicts used by the JS
            to compute per-source formula derivations at render time.
    """
    title = plot_spec.display_title

    # Serialize data to JSON for embedding
    # Convert to list of dicts, coercing non-JSON-native types (datetime, date, etc.)
    rows_json = data.to_dicts()
    for row in rows_json:
        for k, v in row.items():
            if v is None or (isinstance(v, float) and v != v):  # NaN check
                row[k] = None
            elif hasattr(v, "isoformat"):  # datetime, date, time
                row[k] = str(v)

    data_json = json.dumps(rows_json)
    config_json = json.dumps(col_config)
    csv_filename_js = json.dumps(csv_download_filename or _csv_filename(plot_spec))  # safe for JS embedding

    summary_html = "Discrepancy Metrics Details"
    if metrics_by_source:
        chips = []
        for label, mape in metrics_by_source.items():
            chips.append(
                f'<span class="metric-chip">'
                f'<span class="metric-chip-label">{label}</span>'
                f'<span class="metric-chip-value">{mape:.1f}%</span>'
                f"</span>"
            )
        summary_html = (
            '<span class="summary-prefix">MAPE</span>'
            + "".join(chips)
        )
    metrics_details_html = ""
    if include_discrepancy_metrics:
        metrics_details_html = (
            '<details id="metricsDetails" class="metrics-details">'
            f"<summary>{summary_html}</summary>"
            '<div id="metricsFormula" class="metrics-formula"></div>'
            "</details>"
        )

    # Build navigation links
    nav_parts = []
    nav_parts.append('<a href="#" onclick="downloadCSV(); return false;">Download CSV</a>')
    nav_html = '<div class="nav-links">' + " | ".join(nav_parts) + "</div>"

    # Build footer
    footer_html = _build_footer_html(source_labels, plot_spec.comparison_dataset.value, footnotes)

    return f"""<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>{title}</title>
  <style>
    body {{ font-family: Arial, sans-serif; margin: 20px; color: #333; }}
    h1 {{ font-size: 22px; margin-bottom: 4px; }}
    .subtitle {{ font-size: 15px; color: #666; margin-bottom: 12px; }}
    .metrics-banner {{
      margin: 16px 0; background: #f0f4f8; border: 1px solid #d0d7de;
      border-radius: 6px; border-collapse: collapse;
    }}
    .metrics-banner td {{
      border: none; padding: 8px 20px; font-size: 14px; text-align: left;
      white-space: nowrap;
    }}
    .metrics-banner td.metric-label {{ font-weight: bold; color: #1a1a1a; }}
    .metrics-banner td strong {{ color: #1a1a1a; }}
    .nav-links {{ margin: 12px 0 16px; font-size: 14px; }}
    .nav-links a {{ color: #1a73e8; text-decoration: none; }}
    .nav-links a:hover {{ text-decoration: underline; }}
    table {{ border-collapse: collapse; width: auto; max-width: 100%; margin-top: 8px; table-layout: auto; }}
    th, td {{ border: 1px solid #ddd; padding: 8px 10px; text-align: right; font-size: 13px; white-space: nowrap; }}
    th {{
      background-color: #D3D3D3; font-weight: bold; cursor: pointer;
      position: sticky; top: 0; user-select: none;
      white-space: normal; word-wrap: break-word; max-width: 140px;
      z-index: 3; background-clip: padding-box;
    }}
    th:hover {{ background-color: #c0c0c0; }}
    th .sort-arrow {{ font-size: 10px; margin-left: 4px; opacity: 0.6; }}
    th.sorted .sort-arrow {{ opacity: 1; }}
    td:first-child, th:first-child {{ text-align: left; }}
    tbody tr:nth-child(even) {{ background-color: #f9f9f9; }}
    tbody tr:hover {{ background-color: #e8f0fe; }}
    .diff-pos {{ color: #c62828; }}
    .diff-neg {{ color: #1565c0; }}
    .metrics-details {{
      margin: 20px 0; background: #f8f9fa; border: 1px solid #e0e0e0; border-radius: 6px;
    }}
    .metrics-details > summary {{
      cursor: pointer; padding: 12px 20px; font-size: 15px; font-weight: bold;
      font-family: Arial, sans-serif; user-select: none; list-style: revert;
      display: flex; align-items: center; gap: 8px; flex-wrap: wrap;
    }}
    .metrics-details > summary:hover {{ background: #eef1f5; }}
    .metrics-details[open] > summary {{ border-bottom: 1px solid #e0e0e0; }}
    .summary-prefix {{
      font-weight: 700; color: #1a1a1a; margin-right: 4px;
    }}
    .metric-chip {{
      display: inline-flex; align-items: center; gap: 6px;
      background: #ffffff; border: 1px solid #d0d7de; border-radius: 999px;
      padding: 2px 8px; font-size: 13px; font-weight: 600;
    }}
    .metric-chip-label {{ color: #555; font-weight: 600; }}
    .metric-chip-value {{ color: #1a1a1a; font-weight: 700; }}
    .metrics-formula {{
      padding: 16px 20px;
      font-family: 'Courier New', Courier, monospace; font-size: 13px;
      line-height: 1.7; white-space: pre-wrap; color: #333;
    }}
    .metrics-formula .result {{ font-weight: bold; }}
    .metrics-formula .note {{ font-family: Arial, sans-serif; font-style: italic; font-size: 12px; color: #666; margin-top: 8px; }}
    .pagination {{
      margin: 12px 0; font-size: 13px; display: flex; gap: 8px; align-items: center;
    }}
    .pagination button {{
      padding: 4px 10px; border: 1px solid #ccc; background: #fff; cursor: pointer;
      border-radius: 3px; font-size: 13px;
    }}
    .pagination button:hover:not(:disabled) {{ background: #f0f0f0; }}
    .pagination button:disabled {{ opacity: 0.4; cursor: not-allowed; }}
    .pagination .info {{ color: #666; }}
    .plot-footer {{ margin-top: 24px; }}
  </style>
</head>
<body>
  <h1>{title}</h1>
  {nav_html}
  <div id="pagination" class="pagination"></div>
  <table id="dataTable">
    <thead><tr id="headerRow"></tr></thead>
    <tbody id="tableBody"></tbody>
  </table>
  {metrics_details_html}
  {footer_html}
  <script>
    const DATA = {data_json};
    const COLUMNS = {config_json};
    const RS_SOURCES = {json.dumps(rs_sources_js)};
    const FOCUS_ON = {json.dumps(plot_spec.focus_on)};
    const REF_LABEL = {json.dumps(ref_label)};
    const PAGE_SIZE = {_PAGE_SIZE};

    let sortCol = null;
    let sortAsc = true;
    let currentPage = 0;

    function render() {{
      // Header
      const hr = document.getElementById('headerRow');
      hr.innerHTML = '';
      COLUMNS.forEach((col, i) => {{
        const th = document.createElement('th');
        let arrow = '';
        if (sortCol === i) {{
          th.className = 'sorted';
          arrow = sortAsc ? ' \\u25B2' : ' \\u25BC';
        }}
        th.innerHTML = escapeHtml(col.label) + '<span class="sort-arrow">' + arrow + '</span>';
        th.onclick = () => sortBy(i);
        hr.appendChild(th);
      }});

      // Body — only render rows for the current page
      const start = currentPage * PAGE_SIZE;
      const end = Math.min(start + PAGE_SIZE, DATA.length);
      const tb = document.getElementById('tableBody');
      tb.innerHTML = '';
      for (let i = start; i < end; i++) {{
        const row = DATA[i];
        const tr = document.createElement('tr');
        COLUMNS.forEach(col => {{
          const td = document.createElement('td');
          const val = row[col.key];
          if (val === null || val === undefined) {{
            td.textContent = '';
          }} else if (col.type === 'diff') {{
            td.textContent = formatDiff(val);
            td.className = val > 0 ? 'diff-pos' : val < 0 ? 'diff-neg' : '';
          }} else if (col.type === 'abs_diff') {{
            td.textContent = formatAbsDiff(val, col.format);
            td.className = val > 0 ? 'diff-pos' : val < 0 ? 'diff-neg' : '';
          }} else if (col.type === 'number') {{
            td.textContent = formatNumber(val, col.format);
          }} else {{
            td.textContent = String(val);
            td.style.textAlign = 'left';
          }}
          tr.appendChild(td);
        }});
        tb.appendChild(tr);
      }}

      renderPagination();
    }}

    function renderPagination() {{
      const div = document.getElementById('pagination');
      const totalPages = Math.max(1, Math.ceil(DATA.length / PAGE_SIZE));
      if (totalPages <= 1) {{
        div.innerHTML = '';
        return;
      }}
      const start = currentPage * PAGE_SIZE + 1;
      const end = Math.min((currentPage + 1) * PAGE_SIZE, DATA.length);
      div.innerHTML = '';

      const first = document.createElement('button');
      first.textContent = '\\u00AB First';
      first.disabled = currentPage === 0;
      first.onclick = () => {{ currentPage = 0; render(); }};
      div.appendChild(first);

      const prev = document.createElement('button');
      prev.textContent = '\\u2039 Prev';
      prev.disabled = currentPage === 0;
      prev.onclick = () => {{ currentPage--; render(); }};
      div.appendChild(prev);

      const info = document.createElement('span');
      info.className = 'info';
      info.textContent = `Rows ${{start.toLocaleString()}}\\u2013${{end.toLocaleString()}} of ${{DATA.length.toLocaleString()}} (page ${{currentPage + 1}} / ${{totalPages}})`;
      div.appendChild(info);

      const next = document.createElement('button');
      next.textContent = 'Next \\u203A';
      next.disabled = currentPage >= totalPages - 1;
      next.onclick = () => {{ currentPage++; render(); }};
      div.appendChild(next);

      const last = document.createElement('button');
      last.textContent = 'Last \\u00BB';
      last.disabled = currentPage >= totalPages - 1;
      last.onclick = () => {{ currentPage = totalPages - 1; render(); }};
      div.appendChild(last);
    }}

    function formatNumber(val, fmt) {{
      if (val === null || val === undefined) return '';
      const n = Number(val);
      if (isNaN(n)) return String(val);
      // Determine decimals from format string
      const m = fmt.match(/\\.(\\d+)f/);
      const decimals = m ? parseInt(m[1]) : 1;
      // Large integers (dwelling units, model count) — no decimals
      if (fmt.includes(',') && Math.abs(n) >= 1 && n === Math.floor(n) && Math.abs(n) > 100) {{
        return n.toLocaleString('en-US', {{maximumFractionDigits: 0}});
      }}
      return n.toLocaleString('en-US', {{minimumFractionDigits: decimals, maximumFractionDigits: decimals}});
    }}

    function formatDiff(val) {{
      if (val === null || val === undefined) return '';
      const n = Number(val);
      if (isNaN(n)) return String(val);
      const sign = n > 0 ? '+' : '';
      return sign + n.toFixed(1) + '%';
    }}

    function formatAbsDiff(val, fmt) {{
      if (val === null || val === undefined) return '';
      const n = Number(val);
      if (isNaN(n)) return String(val);
      const sign = n > 0 ? '+' : '';
      const m = fmt.match(/\\.(\\d+)f/);
      const decimals = m ? parseInt(m[1]) : 1;
      if (Math.abs(n) >= 1 && n === Math.floor(n) && Math.abs(n) > 100) {{
        return sign + n.toLocaleString('en-US', {{maximumFractionDigits: 0}});
      }}
      return sign + n.toLocaleString('en-US', {{minimumFractionDigits: decimals, maximumFractionDigits: decimals}});
    }}

    function escapeHtml(s) {{
      const el = document.createElement('span');
      el.textContent = s;
      return el.innerHTML;
    }}

    function sortBy(colIdx) {{
      if (sortCol === colIdx) {{
        sortAsc = !sortAsc;
      }} else {{
        sortCol = colIdx;
        sortAsc = true;
      }}
      const key = COLUMNS[colIdx].key;
      const type = COLUMNS[colIdx].type;
      DATA.sort((a, b) => {{
        let va = a[key], vb = b[key];
        if (va === null || va === undefined) va = type === 'string' ? '' : -Infinity;
        if (vb === null || vb === undefined) vb = type === 'string' ? '' : -Infinity;
        let cmp;
        if (type === 'string') {{
          cmp = String(va).localeCompare(String(vb));
        }} else {{
          cmp = Number(va) - Number(vb);
        }}
        return sortAsc ? cmp : -cmp;
      }});
      currentPage = 0;
      render();
    }}

    function downloadCSV() {{
      const headers = COLUMNS.map(c => c.label);
      const rows = DATA.map(row =>
        COLUMNS.map(col => {{
          const val = row[col.key];
          if (val === null || val === undefined) return '';
          return String(val);
        }})
      );
      let csv = headers.map(h => '"' + h.replace(/"/g, '""') + '"').join(',') + '\\n';
      rows.forEach(r => {{
        csv += r.map(v => '"' + String(v).replace(/"/g, '""') + '"').join(',') + '\\n';
      }});
      const blob = new Blob([csv], {{type: 'text/csv;charset=utf-8;'}});
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = {csv_filename_js};
      a.click();
      URL.revokeObjectURL(url);
    }}

    function renderMetricsFormula() {{
      const details = document.getElementById('metricsDetails');
      if (!details) {{
        return;
      }}
      const div = document.getElementById('metricsFormula');
      if (!RS_SOURCES || RS_SOURCES.length === 0) {{
        details.style.display = 'none';
        return;
      }}
      const entityCol = COLUMNS.find(c => c.type === 'string');

      // Filter rows: exclude "US Total" for multi-entity views (avoids double-counting)
      const focusedOnUsTotal = Array.isArray(FOCUS_ON) &&
        FOCUS_ON.some(t => Array.isArray(t) && t[1] === 'US Total');
      const rows = focusedOnUsTotal ? DATA :
        DATA.filter(r => entityCol ? String(r[entityCol.key]) !== 'US Total' : true);

      const fmt = (v) => v.toLocaleString('en-US', {{maximumFractionDigits: 1}});
      const fmtInt = (v) => Math.round(v).toLocaleString('en-US');

      let html = '';
      let anyDerivation = false;
      RS_SOURCES.forEach(src => {{
        const refKey = src.refKey;
        const absDiffKey = src.absDiffKey;
        if (!refKey || !absDiffKey) return;

        let sumTerms = 0, n = 0, zeroRefRows = 0;
        rows.forEach(r => {{
          const ref = r[refKey];
          const diff = r[absDiffKey];
          if (ref !== null && ref !== undefined && diff !== null && diff !== undefined) {{
            const refNum = Number(ref);
            if (refNum === 0) {{
              zeroRefRows++;
              return;
            }}
            const diffNum = Number(diff);
            sumTerms += Math.abs(diffNum) / Math.abs(refNum);
            n++;
          }}
        }});
        if (n === 0) return;

        const mape = (sumTerms / n) * 100;

        anyDerivation = true;
        html += `<strong>${{escapeHtml(src.label)}}</strong>\\n\\n`;
        html += `<strong>MAPE</strong> (Mean Absolute Percentage Error)\\n`;
        html += `  = mean(\\u007CResStock \\u2212 Reference\\u007C / \\u007CReference\\u007C) \\u00D7 100\\n`;
        html += `  = (${{fmt(sumTerms)}} / ${{fmtInt(n)}}) \\u00D7 100\\n`;
        html += `  = <span class="result">${{fmt(mape)}}%</span>\\n`;
        if (zeroRefRows > 0) {{
          html += `\\n<div class="note">${{fmtInt(zeroRefRows)}} row(s) with zero reference were excluded from MAPE.</div>\\n`;
        }}
        html += `\\n`;
      }});

      if (!anyDerivation) {{
        details.style.display = 'none';
        return;
      }}

      html += '<div class="note">Rows with zero reference are excluded from MAPE.</div>';
      if (!focusedOnUsTotal && DATA.some(r => entityCol && String(r[entityCol.key]) === 'US Total')) {{
        html += '<div class="note">Note: "U.S. Total" is excluded from these calculations to avoid double-counting.</div>';
      }}
      div.innerHTML = html;
    }}

    render();
    renderMetricsFormula();
  </script>
</body>
</html>
"""


def _csv_filename(plot_spec: PlotSpec) -> str:
    """Generate a filename for the downloadable CSV."""
    _, title = plot_spec.file_path_and_name
    return f"{title}.csv"


@timed
def generate_data_table_html(
    data: pl.DataFrame,
    plot_spec: PlotSpec,
    output_path: Path,
    plot_rel_path: str | None = None,
    metrics_by_source: dict[str, float] | None = None,
    footnotes: list[str] | None = None,
    source_labels: dict | None = None,
    csv_download_filename: str | None = None,
    include_discrepancy_metrics: bool = True,
) -> None:
    """Generate an interactive HTML data table page.

    Args:
        data: The raw plot data DataFrame (same data used for the plot).
        plot_spec: The plot specification.
        output_path: Where to write the HTML file.
        plot_rel_path: Relative path to the corresponding plot HTML (for navigation).
        metrics_by_source: Per-source MAPE (%) keyed by source label.
        footnotes: Footnotes for the footer.
        source_labels: Data source labels for the footer.
        csv_download_filename: Optional filename used by the in-page Download CSV action.
        include_discrepancy_metrics: Whether to include discrepancy formula details.
    """
    if data.is_empty():
        output_path.write_text(
            "<html><body><p>No data available.</p></body></html>",
            encoding="utf-8",
        )
        return

    metrics_by_source = metrics_by_source or {}
    if plot_spec.quantity == DataCol.ALL:
        data = _melt_enduse_columns(data)
    data = _normalize_model_count_columns(data, plot_spec)
    if plot_spec.is_distribution_metric:
        data = _extract_quartile_columns(data, plot_spec)
    filtered = _filter_columns(data, plot_spec)
    pivoted, ref_label, rs_labels = _pivot_by_source(filtered, plot_spec)

    # Drop columns that are entirely null (e.g., reference model_count, unused diff columns)
    all_null_cols = [c for c in pivoted.columns if pivoted[c].is_null().all()]
    if all_null_cols:
        pivoted = pivoted.drop(all_null_cols)

    # Drop dimension columns that are constant across all rows — they're
    # redundant with the title/subtitle (e.g. "State" showing "US Total" in
    # every row of an ALL-enduse US Total overview).
    entity_col = get_second_category_column(plot_spec)
    ts_col = resolve_timeseries_column(plot_spec)
    candidate_dim_cols = [entity_col]
    if ts_col and str(ts_col) in pivoted.columns:
        candidate_dim_cols.append(str(ts_col))
    constant_cols = [
        c for c in candidate_dim_cols
        if c in pivoted.columns and pivoted[c].n_unique() <= 1
    ]
    if constant_cols:
        pivoted = pivoted.drop(constant_cols)

    # Determine the value column suffix
    if plot_spec.quantity == DataCol.UNITS_COUNT:
        val_suffix = "units_count"
    elif plot_spec.is_penetration_metric:
        val_suffix = f"{plot_spec.quantity}_percent_users"
    else:
        val_suffix = f"{plot_spec.quantity}_value"
    ref_val_col = f"{ref_label}: {val_suffix}"

    units = resolve_quantity_title(plot_spec)
    abs_diff_units = "percentage points" if units == "%" else units

    # Add per-source difference columns and gather (refKey, absDiffKey) for JS.
    # Distribution plots compare entire quartile distributions, not single values,
    # so per-source diff columns and discrepancy formulas don't apply.
    rs_sources_js: list[dict[str, str]] = []
    if include_discrepancy_metrics and not plot_spec.is_distribution_metric:
        for rs_label in rs_labels:
            rs_val_col = f"{rs_label}: {val_suffix}"
            abs_diff_key = f"{rs_label} Difference ({abs_diff_units}): {val_suffix}"
            if ref_val_col in pivoted.columns and rs_val_col in pivoted.columns:
                pivoted = pivoted.with_columns(
                    pl.col(ref_val_col).fill_nan(0),
                    pl.col(rs_val_col).fill_nan(0),
                )
                pivoted = pivoted.with_columns(
                    (pl.col(rs_val_col) - pl.col(ref_val_col)).alias(abs_diff_key)
                )
                rs_sources_js.append({
                    "label": rs_label,
                    "refKey": ref_val_col,
                    "absDiffKey": abs_diff_key,
                })

    # Reorder: group each source's columns together (value, abs diff, pct diff).
    # For distribution view, sort each source's stat columns canonically:
    # mean (value) → min → q1 → median → q3 → max.
    _STAT_ORDER = ("_value", "_min", "_q1", "_median", "_q3", "_max")

    def _stat_sort_key(col: str) -> int:
        for i, suffix in enumerate(_STAT_ORDER):
            if col.endswith(suffix):
                return i
        return len(_STAT_ORDER)

    if rs_labels:
        dimension_cols = [
            c for c in pivoted.columns
            if not c.startswith(f"{ref_label}: ")
            and not any(
                c.startswith(f"{lbl}: ")
                or c.startswith(f"{lbl} Difference")
                for lbl in rs_labels
            )
        ]
        ref_cols = sorted(
            [c for c in pivoted.columns if c.startswith(f"{ref_label}: ")],
            key=_stat_sort_key,
        )
        ordered = list(dimension_cols) + list(ref_cols)
        for rs_label in rs_labels:
            value_cols = sorted(
                [c for c in pivoted.columns if c.startswith(f"{rs_label}: ")],
                key=_stat_sort_key,
            )
            abs_diff_cols = [c for c in pivoted.columns if c.startswith(f"{rs_label} Difference ({abs_diff_units}): ")]
            pct_diff_cols = [c for c in pivoted.columns if c.startswith(f"{rs_label} Difference (%): ")]
            ordered.extend(value_cols + abs_diff_cols + pct_diff_cols)
        pivoted = pivoted.select(ordered)

    col_config = _build_column_config(pivoted, plot_spec, ref_label, rs_labels)

    html = _build_table_html(
        pivoted, col_config, plot_spec, plot_rel_path,
        metrics_by_source, footnotes, source_labels, ref_label, rs_sources_js,
        csv_download_filename=csv_download_filename,
        include_discrepancy_metrics=include_discrepancy_metrics,
    )
    output_path.write_text(html, encoding="utf-8")
