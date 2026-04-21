"""Generate interactive HTML data table pages for baseline validation plots.

Each table page shows the plot's data in a pivoted, sortable format with
discrepancy metrics (MAPE) and navigation links back to the plot
and the plot index.
"""

import json
from pathlib import Path

import polars as pl

from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.baseline_validation.schema.plot_spec import PlotSpec
from resstockpostproc.baseline_validation.plotters.plot_config import (
    get_second_category_column,
)
from resstockpostproc.baseline_validation.plot_semantics import (
    resolve_quantity_title,
    resolve_timeseries_column,
)
from resstockpostproc.baseline_validation.io_managers.html_utils import _build_footer_html
from resstockpostproc.baseline_validation.io_managers.data_table_transform import (
    extract_quartile_columns,
    filter_columns,
    melt_enduse_columns,
    normalize_model_count_columns,
    pivot_by_source,
)
from resstockpostproc.baseline_validation.io_managers.data_table_columns import (
    build_column_config,
)
from resstockpostproc.shared_utils.timing import timed


# Page size for client-side pagination (large tables render in chunks)
_PAGE_SIZE = 500


@timed
def _build_table_html(
    data: pl.DataFrame,
    col_config: list[dict],
    plot_spec: PlotSpec,
    metrics_by_source: dict[str, float],
    footnotes: list[str] | None,
    source_labels: dict | None,
    ref_label: str,
    rs_sources_js: list[dict[str, str]],
    csv_download_filename: str | None = None,
    include_discrepancy_metrics: bool = True,
) -> str:
    """Build a self-contained HTML page with an interactive data table.

    ``rs_sources_js`` items have the shape ``{label, refKey, absDiffKey}``
    and drive the per-source MAPE formula derivations rendered by the JS.
    """
    title = plot_spec.display_title

    # Serialize data to JSON for embedding
    # Convert to list of dicts, coercing non-JSON-native types (datetime, date, etc.)
    rows_json = data.to_dicts()
    for row in rows_json:
        for k, v in row.items():
            if v is None or (isinstance(v, float) and v != v):  # noqa: PLR0124 — v != v is the NaN idiom
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
        summary_html = '<span class="summary-prefix">MAPE</span>' + "".join(chips)
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
    metrics_by_source: dict[str, float] | None = None,
    footnotes: list[str] | None = None,
    source_labels: dict | None = None,
    csv_download_filename: str | None = None,
    include_discrepancy_metrics: bool = True,
) -> None:
    """Write an interactive HTML data table page for ``data`` to ``output_path``."""
    if data.is_empty():
        output_path.write_text(
            "<html><body><p>No data available.</p></body></html>",
            encoding="utf-8",
        )
        return

    metrics_by_source = metrics_by_source or {}
    if plot_spec.is_all_enduses:
        data = melt_enduse_columns(data)
    data = normalize_model_count_columns(data, plot_spec)
    if plot_spec.is_distribution_metric:
        data = extract_quartile_columns(data, plot_spec)
    filtered = filter_columns(data, plot_spec)
    pivoted, ref_label, rs_labels = pivot_by_source(filtered, plot_spec)

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
    constant_cols = [c for c in candidate_dim_cols if c in pivoted.columns and pivoted[c].n_unique() <= 1]
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
                pivoted = pivoted.with_columns((pl.col(rs_val_col) - pl.col(ref_val_col)).alias(abs_diff_key))
                rs_sources_js.append(
                    {
                        "label": rs_label,
                        "refKey": ref_val_col,
                        "absDiffKey": abs_diff_key,
                    }
                )

    # Reorder: group each source's columns together (value, abs diff, pct diff).
    # For distribution view, sort each source's stat columns canonically:
    # mean (value) → min → q1 → median → q3 → max.
    stat_order = ("_value", "_min", "_q1", "_median", "_q3", "_max")

    def _stat_sort_key(col: str) -> int:
        for i, suffix in enumerate(stat_order):
            if col.endswith(suffix):
                return i
        return len(stat_order)

    if rs_labels:
        dimension_cols = [
            c
            for c in pivoted.columns
            if not c.startswith(f"{ref_label}: ")
            and not any(c.startswith((f"{lbl}: ", f"{lbl} Difference")) for lbl in rs_labels)
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

    col_config = build_column_config(pivoted, plot_spec, ref_label, rs_labels)

    html = _build_table_html(
        pivoted,
        col_config,
        plot_spec,
        metrics_by_source,
        footnotes,
        source_labels,
        ref_label,
        rs_sources_js,
        csv_download_filename=csv_download_filename,
        include_discrepancy_metrics=include_discrepancy_metrics,
    )
    output_path.write_text(html, encoding="utf-8")
