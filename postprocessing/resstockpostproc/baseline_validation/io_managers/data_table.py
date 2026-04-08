"""Generate interactive HTML data table pages for baseline validation plots.

Each table page shows the plot's data in a pivoted, sortable format with
discrepancy metrics (CVRMSE, NMBE) and navigation links back to the plot
and the plot index.
"""

import html as html_lib
import json
from pathlib import Path

import polars as pl

from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    CoverageType,
    Resolution,
    ViewType,
    format_aggregation_level,
)
from resstockpostproc.baseline_validation.plotters.plot_config import (
    _resolve_quantity_title,
    _extract_comparison_dataset_label,
    _resolve_timeseries_column,
    get_second_category_column,
)
from resstockpostproc.baseline_validation.io_managers.html_utils import _build_footer_html
from resstockpostproc.shared_utils.timing import timed


# Maximum pivoted row count before we skip HTML table generation
_ROW_LIMIT = 10_000

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

@timed
def should_generate_table(data: pl.DataFrame, plot_spec: PlotSpec) -> bool:
    """Check whether an HTML table should be generated for this plot.

    Returns False for ALL-enduse plots, and for datasets that would produce
    more than _ROW_LIMIT rows after pivoting.
    """
    if plot_spec.quantity == DataCol.ALL:
        return False

    # Estimate pivoted row count
    entity_col = get_second_category_column(plot_spec)
    ts_col = _resolve_timeseries_column(plot_spec)

    n_entities = data[entity_col].n_unique() if entity_col in data.columns else 1
    n_time = data[str(ts_col)].n_unique() if ts_col and str(ts_col) in data.columns else 1
    # Pivot combines 2 source rows into 1
    estimated = n_entities * n_time
    if estimated <= 1:
        return False  # Single-row table (e.g., focused single-entity annual) adds no value
    return estimated <= _ROW_LIMIT

@timed
def _filter_columns(data: pl.DataFrame, plot_spec: PlotSpec) -> pl.DataFrame:
    """Drop irrelevant columns, keeping only comparison-meaningful ones."""
    # Protect structural columns (join keys) from being dropped
    entity_col = get_second_category_column(plot_spec)
    ts_col = _resolve_timeseries_column(plot_spec)
    structural = {entity_col, "source"}
    if ts_col:
        structural.add(str(ts_col))

    keep_percent_users = (
        plot_spec.view == ViewType.penetration
        or plot_spec.coverage == CoverageType.users_only
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

        # Drop units_count_percent_difference unless the main quantity is dwelling units
        if col == "units_count_percent_difference" and plot_spec.quantity != DataCol.UNITS_COUNT:
            drop_cols.append(col)
            continue

        # For value_view, drop percent_users percent_difference — only the value diff matters
        if plot_spec.view == ViewType.value_view and col.endswith("_percent_users_percent_difference"):
            drop_cols.append(col)
            continue

        # For penetration views, drop _value columns — only percent_users matters
        if plot_spec.view == ViewType.penetration:
            if col.endswith("_value") or col.endswith("_value_percent_difference"):
                drop_cols.append(col)
                continue

    return data.drop(drop_cols)

@timed
def _pivot_by_source(
    data: pl.DataFrame,
    plot_spec: PlotSpec,
) -> tuple[pl.DataFrame, str, str]:
    """Pivot long-format data to wide format, with sources as column groups.

    Returns:
        (pivoted_df, ref_label, rs_label) where labels are like "RECS 2020", "ResStock 2025".
    """
    entity_col = get_second_category_column(plot_spec)
    ts_col = _resolve_timeseries_column(plot_spec)

    # Identify join columns (dimensions)
    join_cols = [entity_col]
    if ts_col and str(ts_col) in data.columns:
        join_cols.append(str(ts_col))

    # Identify the two source labels
    ref_label = _extract_comparison_dataset_label(plot_spec.comparison_dataset, data)
    sources = data["source"].unique().to_list()
    rs_sources = [s for s in sources if "resstock" in s]
    rs_label = _format_source_label(rs_sources[0]) if rs_sources else "ResStock"

    # Split by source
    comparison_val = plot_spec.comparison_dataset.value
    ref_df = data.filter(pl.col("source").str.contains(comparison_val))
    rs_df = data.filter(pl.col("source").str.contains("resstock"))

    # Determine value columns to pivot (everything that's not a join col or source)
    skip_cols = set(join_cols) | {"source"}
    value_cols = [c for c in data.columns if c not in skip_cols]

    # Identify the percent_difference column(s) — these belong to ResStock only
    diff_cols = [c for c in value_cols if c.endswith("_percent_difference")]
    non_diff_cols = [c for c in value_cols if c not in diff_cols]

    # Select and rename reference columns
    ref_available = [c for c in non_diff_cols if c in ref_df.columns]
    ref_renamed = ref_df.select(
        join_cols + [pl.col(c).alias(f"{ref_label}: {c}") for c in ref_available]
    )

    # Select and rename ResStock columns (non-diff)
    rs_non_diff = [c for c in non_diff_cols if c in rs_df.columns]
    rs_diff_available = [c for c in diff_cols if c in rs_df.columns]

    rs_select_exprs = (
        [pl.col(c) for c in join_cols]
        + [pl.col(c).alias(f"{rs_label}: {c}") for c in rs_non_diff]
        + [pl.col(c).alias(f"Difference: {c}") for c in rs_diff_available]
    )
    rs_renamed = rs_df.select(rs_select_exprs)

    # Join on dimension columns
    pivoted = ref_renamed.join(rs_renamed, on=join_cols, how="full", coalesce=True)

    return pivoted, ref_label, rs_label


def _format_source_label(source_str: str) -> str:
    """Format a raw source string like 'resstock_2025' into 'ResStock 2025'."""
    parts = source_str.split("_")
    if parts[0].lower() == "resstock":
        parts[0] = "ResStock"
    else:
        parts[0] = parts[0].upper()
    return " ".join(parts)


def _build_column_config(
    columns: list[str],
    plot_spec: PlotSpec,
    ref_label: str,
    rs_label: str,
) -> list[dict]:
    """Build column metadata for the HTML table (header labels, formats, types)."""
    units = _resolve_quantity_title(plot_spec)
    entity_col = get_second_category_column(plot_spec)
    agg = plot_spec.aggregation_level or plot_spec.effective_group_by[-1]
    entity_label = format_aggregation_level(agg)

    ts_col = _resolve_timeseries_column(plot_spec)

    config = []
    for col in columns:
        # Dimension columns
        if col == entity_col:
            config.append({"key": col, "label": entity_label, "type": "string", "format": ""})
            continue

        if ts_col and col == str(ts_col):
            label = col.replace("_", " ").title() if "_" in col else col.title()
            config.append({"key": col, "label": label, "type": "string", "format": ""})
            continue

        # Source-prefixed value columns
        is_abs_diff = col.startswith("Abs Difference: ")
        is_diff = col.startswith("Difference: ")
        is_ref = col.startswith(f"{ref_label}: ")
        is_rs = col.startswith(f"{rs_label}: ")

        if is_abs_diff:
            abs_diff_units = "percentage points" if units == "%" else units
            config.append({"key": col, "label": f"Difference ({abs_diff_units})", "type": "abs_diff", "format": "+,.1f"})
        elif is_diff:
            raw_name = col[len("Difference: "):]
            label = _humanize_column(raw_name, "Difference", units, is_diff=True)
            config.append({"key": col, "label": label, "type": "diff", "format": "+.1f%"})
        elif is_ref:
            raw_name = col[len(f"{ref_label}: "):]
            label = _humanize_column(raw_name, ref_label, units)
            config.append({"key": col, "label": label, "type": "number", "format": ",.1f"})
        elif is_rs:
            raw_name = col[len(f"{rs_label}: "):]
            label = _humanize_column(raw_name, rs_label, units)
            config.append({"key": col, "label": label, "type": "number", "format": ",.1f"})
        else:
            # Fallback
            config.append({"key": col, "label": col.replace("_", " ").title(), "type": "string", "format": ""})

    return config


def _humanize_column(raw_name: str, source_prefix: str, units: str, is_diff: bool = False) -> str:
    """Convert a raw column name like 'electricity_total_value' into a human-readable header."""
    if is_diff:
        return "Difference (%)"

    if raw_name == "units_count":
        return f"{source_prefix}: Dwelling Units"
    if raw_name == "model_count":
        return f"{source_prefix}: Model Count"
    if "percent_users" in raw_name and "percent_difference" not in raw_name:
        return f"{source_prefix}: % Users"
    if raw_name.endswith("_value"):
        return f"{source_prefix} ({units})"

    # Fallback: clean up the raw name
    clean = raw_name.replace("_", " ").title()
    return f"{source_prefix}: {clean}"

@timed
def _build_table_html(
    data: pl.DataFrame,
    col_config: list[dict],
    plot_spec: PlotSpec,
    plot_rel_path: str | None,
    cvrmse: float | None,
    nmbe: float | None,
    footnotes: list[str] | None,
    source_labels: dict | None,
    ref_label: str = "",
    ref_val_col: str = "",
) -> str:
    """Build a self-contained HTML page with an interactive data table."""
    title = html_lib.escape(plot_spec.get_display_title())
    units = html_lib.escape(_resolve_quantity_title(plot_spec))

    # Subtitle: focused entity or aggregation level
    focus_display = plot_spec.get_filter_display_name()
    if focus_display:
        subtitle = html_lib.escape(focus_display)
    elif plot_spec.aggregation_level:
        subtitle = html_lib.escape(f"by {format_aggregation_level(plot_spec.aggregation_level)}")
    else:
        subtitle = ""

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
    csv_filename_js = json.dumps(_csv_filename(plot_spec))  # safe for JS embedding

    # Build metrics HTML (NMBE first, then CVRMSE)
    metrics_html = ""
    if cvrmse is not None or nmbe is not None:
        parts = []
        if nmbe is not None:
            parts.append(f'<span class="metric"><strong>NMBE:</strong> {nmbe:.1f}%</span>')
        if cvrmse is not None:
            parts.append(f'<span class="metric"><strong>CV(RMSE):</strong> {cvrmse:.1f}%</span>')
        metrics_html = '<div class="metrics-banner">' + " ".join(parts) + "</div>"

    # Build navigation links
    nav_parts = []
    if plot_rel_path:
        nav_parts.append(f'<a href="{plot_rel_path}" target="_blank">View Plot</a>')
    nav_parts.append('<a href="#" onclick="downloadCSV(); return false;">Download CSV</a>')
    # Navigate up to find plot_index.html: data tables are in "{ts} data (html)/metric/focus/"
    nav_parts.append('<a href="../../../plot_index.html">Back to Plot Index</a>')
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
      display: flex; gap: 24px; padding: 12px 20px; margin: 12px 0;
      background: #f0f4f8; border: 1px solid #d0d7de; border-radius: 6px;
    }}
    .metric {{ font-size: 15px; }}
    .metric strong {{ color: #1a1a1a; }}
    .nav-links {{ margin: 12px 0 16px; font-size: 14px; }}
    .nav-links a {{ color: #1a73e8; text-decoration: none; }}
    .nav-links a:hover {{ text-decoration: underline; }}
    table {{ border-collapse: collapse; width: auto; max-width: 100%; margin-top: 8px; }}
    th, td {{ border: 1px solid #ddd; padding: 8px 10px; text-align: right; font-size: 13px; white-space: nowrap; }}
    th {{
      background-color: #D3D3D3; font-weight: bold; cursor: pointer;
      position: sticky; top: 0; user-select: none; white-space: nowrap;
    }}
    th:hover {{ background-color: #c0c0c0; }}
    th .sort-arrow {{ font-size: 10px; margin-left: 4px; opacity: 0.6; }}
    th.sorted .sort-arrow {{ opacity: 1; }}
    td:first-child, th:first-child {{ text-align: left; }}
    tbody tr:nth-child(even) {{ background-color: #f9f9f9; }}
    tbody tr:hover {{ background-color: #e8f0fe; }}
    .diff-pos {{ color: #c62828; }}
    .diff-neg {{ color: #1565c0; }}
    .metrics-formula {{
      margin: 20px 0; padding: 16px 20px;
      background: #f8f9fa; border: 1px solid #e0e0e0; border-radius: 6px;
      font-family: 'Courier New', Courier, monospace; font-size: 13px;
      line-height: 1.7; white-space: pre-wrap; color: #333;
    }}
    .metrics-formula h3 {{ font-family: Arial, sans-serif; font-size: 15px; margin: 0 0 10px; }}
    .metrics-formula .result {{ font-weight: bold; }}
    .metrics-formula .note {{ font-family: Arial, sans-serif; font-style: italic; font-size: 12px; color: #666; margin-top: 8px; }}
    .plot-footer {{ margin-top: 24px; }}
  </style>
</head>
<body>
  <h1>{title}</h1>
  {metrics_html}
  {nav_html}
  <table id="dataTable">
    <thead><tr id="headerRow"></tr></thead>
    <tbody id="tableBody"></tbody>
  </table>
  <div id="metricsFormula"></div>
  {footer_html}
  <script>
    const DATA = {data_json};
    const COLUMNS = {config_json};
    const HAS_METRICS = {json.dumps(cvrmse is not None)};
    const FOCUS_ON = {json.dumps(plot_spec.focus_on)};
    const REF_LABEL = {json.dumps(ref_label)};
    const REF_VAL_KEY = {json.dumps(ref_val_col)};

    let sortCol = null;
    let sortAsc = true;

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

      // Body
      const tb = document.getElementById('tableBody');
      tb.innerHTML = '';
      DATA.forEach(row => {{
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
      }});
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
      if (!HAS_METRICS) return;
      const div = document.getElementById('metricsFormula');

      // Find the ref value column and abs diff column
      const refCol = COLUMNS.find(c => c.key === REF_VAL_KEY);
      const absDiffCol = COLUMNS.find(c => c.type === 'abs_diff');
      const entityCol = COLUMNS.find(c => c.type === 'string');

      if (!refCol || !absDiffCol) return;

      // Filter rows: exclude "US Total" for multi-entity views (avoids double-counting)
      const rows = FOCUS_ON === 'US Total' ? DATA :
        DATA.filter(r => entityCol ? String(r[entityCol.key]) !== 'US Total' : true);

      let sumRef = 0, sumDiff = 0, sumDiffSq = 0, n = 0;
      rows.forEach(r => {{
        const ref = r[refCol.key];
        const diff = r[absDiffCol.key];
        if (ref !== null && ref !== undefined && diff !== null && diff !== undefined) {{
          sumRef += Number(ref);
          sumDiff += Number(diff);
          sumDiffSq += Number(diff) * Number(diff);
          n++;
        }}
      }});

      if (n === 0 || sumRef === 0) return;

      const meanRef = sumRef / n;
      const nmbe = (sumDiff / sumRef) * 100;
      const rmse = Math.sqrt(sumDiffSq / n);
      const cvrmse = (rmse / meanRef) * 100;

      const fmt = (v) => v.toLocaleString('en-US', {{maximumFractionDigits: 1}});
      const fmtInt = (v) => Math.round(v).toLocaleString('en-US');

      let html = '<div class="metrics-formula">';
      html += '<h3>Discrepancy Metrics</h3>';
      html += `<strong>NMBE</strong> (Normalized Mean Bias Error)\\n`;
      html += `  = \\u03A3(ResStock \\u2212 Reference) / \\u03A3(Reference) \\u00D7 100\\n`;
      html += `  = ${{fmt(sumDiff)}} / ${{fmt(sumRef)}} \\u00D7 100\\n`;
      html += `  = <span class="result">${{fmt(nmbe)}}%</span>\\n\\n`;
      html += `<strong>CV(RMSE)</strong> (Coefficient of Variation of Root Mean Square Error)\\n`;
      html += `  = \\u221A[\\u03A3(ResStock \\u2212 Reference)\\u00B2 / n] / mean(Reference) \\u00D7 100\\n`;
      html += `  = \\u221A[${{fmt(sumDiffSq)}} / ${{fmtInt(n)}}] / ${{fmt(meanRef)}} \\u00D7 100\\n`;
      html += `  = ${{fmt(rmse)}} / ${{fmt(meanRef)}} \\u00D7 100\\n`;
      html += `  = <span class="result">${{fmt(cvrmse)}}%</span>`;
      if (FOCUS_ON !== 'US Total' && DATA.some(r => entityCol && String(r[entityCol.key]) === 'US Total')) {{
        html += '\\n\\n<div class="note">Note: "US Total" is excluded from these calculations to avoid double-counting.</div>';
      }}
      html += '</div>';
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
    _, title = plot_spec.get_file_path_and_name()
    return f"{title}.csv"


@timed
def generate_data_table_html(
    data: pl.DataFrame,
    plot_spec: PlotSpec,
    output_path: Path,
    plot_rel_path: str | None = None,
    cvrmse: float | None = None,
    nmbe: float | None = None,
    footnotes: list[str] | None = None,
    source_labels: dict | None = None,
) -> None:
    """Generate an interactive HTML data table page.

    Args:
        data: The raw plot data DataFrame (same data used for the plot).
        plot_spec: The plot specification.
        output_path: Where to write the HTML file.
        plot_rel_path: Relative path to the corresponding plot HTML (for navigation).
        cvrmse: Precomputed CV(RMSE) value, or None.
        nmbe: Precomputed NMBE value, or None.
        footnotes: Footnotes for the footer.
        source_labels: Data source labels for the footer.
    """
    if data.is_empty():
        output_path.write_text(
            "<html><body><p>No data available.</p></body></html>",
            encoding="utf-8",
        )
        return

    filtered = _filter_columns(data, plot_spec)
    pivoted, ref_label, rs_label = _pivot_by_source(filtered, plot_spec)

    # Drop columns that are entirely null (e.g., reference model_count, unused diff columns)
    all_null_cols = [c for c in pivoted.columns if pivoted[c].is_null().all()]
    if all_null_cols:
        pivoted = pivoted.drop(all_null_cols)

    # Add absolute difference column (ResStock - Reference) for the main value
    if plot_spec.quantity == DataCol.UNITS_COUNT:
        val_suffix = "units_count"
    elif plot_spec.view == ViewType.penetration:
        val_suffix = f"{plot_spec.quantity}_percent_users"
    else:
        val_suffix = f"{plot_spec.quantity}_value"
    ref_val_col = f"{ref_label}: {val_suffix}"
    rs_val_col = f"{rs_label}: {val_suffix}"
    abs_diff_key = f"Abs Difference: {val_suffix}"
    if ref_val_col in pivoted.columns and rs_val_col in pivoted.columns:
        # NaN means no data for this enduse — treat as zero consumption
        pivoted = pivoted.with_columns(
            pl.col(ref_val_col).fill_nan(0),
            pl.col(rs_val_col).fill_nan(0),
        )
        # Insert the absolute diff column right before the percent diff column
        pivoted = pivoted.with_columns(
            (pl.col(rs_val_col) - pl.col(ref_val_col)).alias(abs_diff_key)
        )
        # Reorder: move abs_diff before the Difference: (percent) column
        pct_diff_cols = [c for c in pivoted.columns if c.startswith("Difference: ")]
        if pct_diff_cols:
            ordered = [c for c in pivoted.columns if c != abs_diff_key and c not in pct_diff_cols]
            ordered.append(abs_diff_key)
            ordered.extend(pct_diff_cols)
            pivoted = pivoted.select(ordered)

    col_config = _build_column_config(pivoted.columns, plot_spec, ref_label, rs_label)

    html = _build_table_html(
        pivoted, col_config, plot_spec, plot_rel_path,
        cvrmse, nmbe, footnotes, source_labels, ref_label, ref_val_col,
    )
    output_path.write_text(html, encoding="utf-8")
