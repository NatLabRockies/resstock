"""Generate comparisons_index.html with sharded JS data files for scalable browsing.

This module produces an HTML page that loads data from JS shard files in a
``comparisons_index_data/`` sibling directory via static ``<script src>`` tags.
Each shard corresponds to one ``Filter 1`` value (e.g. a state, utility, or
RECS characteristic value).  Rows with no Filter 1 go into
``data-_none_.js``.

The shard files and manifest are embedded as static ``<script>`` tags in the
HTML source so the page works from ``file://`` without a local server.
Client-side pagination (100 rows at a time) keeps DOM rendering fast even
with hundreds of thousands of total rows.

Modes of operation
------------------

1. **Incremental (used by plot_generator during a run):**
   - ``init_html_index()`` creates the data directory.
   - ``append_index_row()`` appends a single CSV row to the correct
     shard file (based on Filter 1) in O(1) time.  When the append
     creates a new shard (new Filter 1 value), the HTML is atomically
     rewritten so the index is always browsable mid-run.
   - ``finalize_html_index()`` does a final atomic HTML rewrite to
     guarantee a clean end-state.

2. **Batch (CLI / backward-compatible):**
   - ``create_html_from_csv()`` reads a finished CSV and produces the
     same HTML + data directory in one shot.

Shard file format
-----------------
Each ``.js`` file wraps plain CSV text in a ``window.addRows()`` call
using a template literal::

    window.addRows(`
    1,Yes,eia,"Number of dwelling units",...
    2,,eia,"Number of dwelling units",...
    `);

The O(1) append works by seeking back over the closing backtick+``);``
and writing the new CSV line before rewriting that suffix.

Combinations index
------------------
A companion ``combinations.js`` in the data directory provides a compact
set of unique filter-column tuples.  The HTML filter panels use this
small array (typically a few hundred entries) instead of scanning all
row data (potentially thousands of entries), making filter clicks instant.
"""

import csv
import io
import json
import os
import re
import sys
import tempfile
from pathlib import Path
from collections.abc import Sequence

from resstockpostproc.shared_utils.timing import timed

# Visualization column names (HTML uses merged "Comparison Plot" column)
VIZ_COLUMNS = ["Comparison Plot", "Data"]

# Column name for the sharding key
_FILTER1_COLUMN = "Filter 1"

# Columns to exclude from filter dropdowns
_NO_FILTER_COLUMNS = frozenset(VIZ_COLUMNS) | {"Index"}

# Suffix that closes each shard JS file.
_JS_SUFFIX = "\n`);\n"

# Data directory name (sibling to comparisons_index.html)
DATA_DIR_NAME = "comparisons_index_data"

# Filename for the combinations index (sibling to shard files)
COMBINATIONS_FILENAME = "combinations.js"


def _sanitize_filename(value: str) -> str:
    """Convert a Filter 1 value to a safe filename component."""
    safe = value.replace(" ", "_")
    safe = re.sub(r"[^\w\-.]", "_", safe)
    return safe


def _shard_filename(filter1_value: str) -> str:
    """Return the JS shard filename for a given Filter 1 value."""
    if not filter1_value or not filter1_value.strip():
        return "data-_none_.js"
    return f"data-{_sanitize_filename(filter1_value)}.js"


def parse_viz_cell(cell_value: str) -> tuple[str, str | None]:
    """Parse 'viz_type||path' format into (display_text, url_or_traceback) tuple.

    Returns:
        Tuple of (display_text, url_or_traceback):
        - ("viz_type", "path") for success
        - ("FAILED", "traceback...") for failure with traceback
        - ("FAILED", None) for failure without traceback
        - ("", None) for empty cells
    """
    if not cell_value or not cell_value.strip():
        return ("", None)

    cell_value = cell_value.strip()

    if cell_value.startswith("FAILED:"):
        after = cell_value[len("FAILED:"):].strip()
        parts = after.split("||", 1)
        if len(parts) == 2:
            return ("FAILED", parts[1].strip())
        return ("FAILED", None)

    parts = cell_value.split("||", 1)
    if len(parts) == 2:
        return (parts[0].strip(), parts[1].strip())

    return (cell_value, None)


# ---------------------------------------------------------------------------
# HTML generation
# ---------------------------------------------------------------------------


_HTML_COLUMN_WIDTHS = {
    "Index": "3%",
    "Highlight": "4%",
    "Truth Source": "7%",
    "Quantity": "13%",
    "Metric": "18%",
    "Filter 1": "10%",
    "Filter 2": "10%",
    "Group By": "8%",
    "Comparison Plot": "18%",
    "Data": "9%",
}


def _build_html_shell(headers: Sequence[str], manifest: dict[str, str]) -> str:
    """Return the complete HTML page with static script tags for all shards.

    Args:
        headers: HTML column names (already merged — no "Extra Visualization").
        manifest: Mapping of Filter 1 display values to shard filenames.
    """
    html_headers = list(headers)

    viz_columns_js = ", ".join(f"'{h}'" for h in VIZ_COLUMNS)
    headers_js = json.dumps(html_headers)
    manifest_js = json.dumps(manifest, ensure_ascii=False)

    # Indices of filterable columns
    filter_col_indices = [i for i, h in enumerate(html_headers) if h not in _NO_FILTER_COLUMNS]
    filter_col_indices_js = json.dumps(filter_col_indices)

    # Filter panel order: Quantity(3), Truth Source(2), Metric(4),
    #   Filter 1(5), Filter 2(6), Group By(7)
    filter_order = [
        (3, "Quantity"), (2, "Truth Source"), (4, "Metric"),
        (5, "Filter 1"), (6, "Filter 2"), (7, "Group By"),
    ]
    # Only include columns that actually exist in the headers
    filter_order = [(idx, name) for idx, name in filter_order if idx < len(html_headers)]
    filter_order_js = json.dumps([idx for idx, _ in filter_order])

    # Mandatory filters (no "(All)" option — user must pick a value)
    mandatory_filters_js = json.dumps([3])  # Quantity

    # Quantity sort order: Number of dwelling units, All Enduses, then fuel/enduse order
    quantity_order = [
        "Number of dwelling units",
        "All Enduses",
        "Electricity", "Natural Gas",
        "Space Cooling Electricity", "Space Heating Electricity",
        "Water Heating Electricity", "Space Heating Natural Gas",
        "Water Heating Natural Gas",
        "Plug Loads Electricity", "Refrigerator Electricity",
        "Lighting Electricity", "Television Electricity",
        "Clothes Dryer Electricity",
        "Cooling Fans & Pumps Electricity", "Heating Fans & Pumps Electricity",
        "Freezer Electricity", "Cooking Electricity",
        "Pool Pumps Electricity", "Ceiling Fans Electricity",
        "Dishwasher Electricity", "Clothes Washer Electricity",
        "Pool Heater Electricity", "EV Charging Electricity",
        "Cooking Natural Gas", "Pool Heater Natural Gas",
        "Clothes Dryer Natural Gas",
        "Propane", "Space Heating Propane", "Water Heating Propane",
        "Cooking Propane", "Clothes Dryer Propane",
        "Fuel Oil", "Space Heating Fuel Oil", "Water Heating Fuel Oil",
    ]
    quantity_order_js = json.dumps(quantity_order)

    # Build filter panel HTML containers (content populated by JS)
    panel_html_parts = []
    for col_idx, label in filter_order:
        # Filter 1/2 get a category dropdown above the value list
        if col_idx in (5, 6):
            panel_html_parts.append(
                f"      <div class='fp' id='fp-{col_idx}'>\n"
                f"        <div class='fp-label'>{label}</div>\n"
                f"        <select class='fp-category' id='fp-cat-{col_idx}' onchange='onCategoryChange({col_idx})'></select>\n"
                f"        <div class='fp-list' id='fp-list-{col_idx}'></div>\n"
                f"      </div>"
            )
        else:
            panel_html_parts.append(
                f"      <div class='fp' id='fp-{col_idx}'>\n"
                f"        <div class='fp-label'>{label}</div>\n"
                f"        <div class='fp-list' id='fp-list-{col_idx}'></div>\n"
                f"      </div>"
            )
    panels_html = "\n".join(panel_html_parts)

    # Build <thead> with per-column widths
    th_parts = []
    for h in html_headers:
        w = _HTML_COLUMN_WIDTHS.get(h, "")
        style = f" style='width:{w}'" if w else ""
        th_parts.append(f"          <th{style}>{h}</th>")
    th_cells = "\n".join(th_parts)

    # Build static <script src> tags: combinations first, then shard files
    data_script_tags: list[str] = [
        f'  <script src="{DATA_DIR_NAME}/{COMBINATIONS_FILENAME}" defer></script>',
    ]
    if "" in manifest:
        data_script_tags.append(
            f'  <script src="{DATA_DIR_NAME}/{manifest[""]}" defer></script>'
        )
    for key in sorted(k for k in manifest if k != ""):
        data_script_tags.append(
            f'  <script src="{DATA_DIR_NAME}/{manifest[key]}" defer></script>'
        )
    data_scripts_html = "\n".join(data_script_tags)

    return f"""<!DOCTYPE html>
<html>
<head>
  <meta charset='UTF-8'>
  <title>Comparisons Index</title>
  <style>
    *, *::before, *::after {{ box-sizing: border-box; }}
    body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; margin: 0; padding: 0; color: #1a1a1a; background: #fff; }}

    /* --- Sticky header --- */
    .sticky-header {{ position: sticky; top: 0; z-index: 10; background: #fff; padding: 10px 20px 0; border-bottom: 1px solid #d0d0d0; }}

    /* --- Top bar: title + checkbox + reset + stats + pagination --- */
    .top-bar {{ display: flex; align-items: center; gap: 16px; margin-bottom: 8px; flex-wrap: wrap; }}
    .top-bar h1 {{ margin: 0; font-size: 18px; font-weight: 700; white-space: nowrap; }}
    .highlight-toggle {{ display: flex; align-items: center; gap: 5px; font-size: 13px; cursor: pointer; user-select: none; white-space: nowrap; }}
    .highlight-toggle input {{ cursor: pointer; }}
    .reset-btn {{ padding: 4px 10px; background: #fff; color: #1a1a1a; border: 1px solid #aaa; cursor: pointer; border-radius: 3px; font-size: 12px; }}
    .reset-btn:hover {{ background: #f0f0f0; }}
    .stats {{ font-size: 13px; color: #555; font-weight: 500; white-space: nowrap; }}
    .spacer {{ flex: 1; }}
    .pagination {{ display: flex; align-items: center; gap: 4px; }}
    .pagination button {{ padding: 3px 8px; border: 1px solid #bbb; background: #fff; cursor: pointer; border-radius: 3px; font-size: 12px; color: #333; }}
    .pagination button:hover:not(:disabled) {{ background: #f0f0f0; border-color: #999; }}
    .pagination button:disabled {{ opacity: 0.3; cursor: default; }}
    .pagination .page-info {{ font-size: 12px; color: #555; padding: 0 4px; }}
    .pagination select {{ padding: 2px 4px; font-size: 12px; border: 1px solid #bbb; border-radius: 3px; }}
    .pagination label {{ font-size: 12px; color: #555; }}

    /* --- Filter panels --- */
    .filter-panels {{ display: flex; gap: 6px; margin-bottom: 8px; }}
    .fp {{ flex: 1; min-width: 100px; display: flex; flex-direction: column; }}
    .fp-label {{ font-size: 11px; font-weight: 700; color: #1a1a1a; text-transform: uppercase; letter-spacing: 0.3px; padding: 4px 6px; background: #f5f5f5; border: 1px solid #ccc; border-bottom: none; border-radius: 3px 3px 0 0; }}
    .fp-list {{ height: 120px; overflow-y: auto; border: 1px solid #ccc; border-radius: 0 0 3px 3px; background: #fff; }}
    .fp-item {{ padding: 3px 8px; font-size: 13px; cursor: pointer; border-bottom: 1px solid #f0f0f0; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }}
    .fp-item:last-child {{ border-bottom: none; }}
    .fp-item:hover {{ background: #e8f0fe; }}
    .fp-item.selected {{ background: #d2e3fc; font-weight: 600; }}
    .fp-item.all-item {{ color: #555; font-style: italic; }}
    .fp-category {{ width: 100%; padding: 3px 4px; font-size: 12px; border: 1px solid #ccc; border-bottom: none; background: #fafafa; }}

    /* --- Table --- */
    .table-wrap {{ padding: 0 20px 20px; }}
    .table-wrap table {{ border-collapse: collapse; width: 100%; table-layout: fixed; }}
    th {{ padding: 7px 10px; text-align: left; font-size: 11px; font-weight: 700; color: #1a1a1a; text-transform: uppercase; letter-spacing: 0.3px; border-bottom: 2px solid #bbb; border-right: 1px solid #e0e0e0; background: #f7f7f7; }}
    th:last-child {{ border-right: none; }}
    td {{ padding: 6px 10px; font-size: 13px; border-bottom: 1px solid #ddd; border-right: 1px solid #eee; color: #1a1a1a; word-wrap: break-word; overflow-wrap: break-word; white-space: normal; }}
    td:last-child {{ border-right: none; }}
    tbody tr:hover {{ background: #eef3ff; }}
    tbody tr:nth-child(even) {{ background: #f9f9f9; }}
    tbody tr:nth-child(even):hover {{ background: #eef3ff; }}

    /* --- Links --- */
    a {{ color: #0b57d0; text-decoration: none; font-weight: 500; }}
    a:hover {{ text-decoration: underline; }}
    .failed {{ color: #b3261e; }}
    .failed a {{ color: #b3261e; cursor: pointer; font-weight: 500; }}

    /* --- Bottom pagination --- */
    .bottom-bar {{ display: flex; align-items: center; gap: 16px; padding: 8px 20px; border-top: 1px solid #ddd; }}
  </style>
</head>
<body>
  <div class='sticky-header'>
    <div class='top-bar'>
      <h1>Comparisons Index</h1>
      <label class='highlight-toggle'><input type='checkbox' id='highlight-cb' checked onchange='onHighlightChange()'>Highlighted only</label>
      <button class='reset-btn' onclick='resetFilters()'>Reset</button>
      <span class='stats' id='stats'>Loading data...</span>
      <span class='spacer'></span>
      <div class='pagination' id='pagination'>
        <button id='btn-first' onclick='goToPage(0)'>&laquo;</button>
        <button id='btn-prev' onclick='goToPage(currentPage-1)'>&lsaquo;</button>
        <span class='page-info' id='page-info'></span>
        <button id='btn-next' onclick='goToPage(currentPage+1)'>&rsaquo;</button>
        <button id='btn-last' onclick='goToPage(totalPages-1)'>&raquo;</button>
        <label>Per page
          <select id='page-size-select' onchange='changePageSize(this.value)'>
            <option value='100'>100</option>
            <option value='250'>250</option>
            <option value='500'>500</option>
            <option value='1000'>1000</option>
          </select>
        </label>
      </div>
    </div>
    <div class='filter-panels' id='filter-panels'>
{panels_html}
    </div>
  </div>
  <div class='table-wrap'>
    <table>
      <thead>
        <tr>
{th_cells}
        </tr>
      </thead>
      <tbody id='tbody'>
      </tbody>
    </table>
  </div>
  <div class='bottom-bar'>
    <div class='pagination' id='pagination-bottom'>
      <button onclick='goToPage(0)'>&laquo;</button>
      <button onclick='goToPage(currentPage-1)'>&lsaquo;</button>
      <span class='page-info' id='page-info-bottom'></span>
      <button onclick='goToPage(currentPage+1)'>&rsaquo;</button>
      <button onclick='goToPage(totalPages-1)'>&raquo;</button>
    </div>
  </div>

  <!-- Inline manifest -->
  <script>window.shardManifest = {manifest_js};</script>

  <!-- App logic -->
  <script>
    const HEADERS = {headers_js};
    const VIZ_COLUMNS = [{viz_columns_js}];
    const FILTER_ORDER = {filter_order_js};
    const MANDATORY_FILTERS = new Set({mandatory_filters_js});
    const QUANTITY_ORDER = {quantity_order_js};
    const HIGHLIGHT_COL = 1;
    const FILTER1_COL = 5;
    const QUANTITY_COL = 3;
    const PAGE_SIZE_DEFAULT = 100;

    // Maps combo tuple position → header column index for filter panels.
    const FILTER_COL_INDICES = {filter_col_indices_js};
    // Reverse lookup: header column index → combo tuple position.
    const COL_TO_COMBO = {{}};
    FILTER_COL_INDICES.forEach((colIdx, pos) => COL_TO_COMBO[colIdx] = pos);

    let allDataRows = [];
    let allCombos = [];      // unique filter-column tuples from combinations.js
    let filteredIndices = [];
    let filterSelections = {{}};  // colIdx -> selected value
    let highlightOnly = true;
    let currentPage = 0;
    let pageSize = PAGE_SIZE_DEFAULT;
    let totalPages = 0;

    // ---- "Category: Value" helpers for Filter columns ----
    const FILTER_COLS = new Set([FILTER1_COL, FILTER1_COL + 1]);
    let categorySelections = {{}};  // colIdx -> selected category string

    function parseCategory(raw) {{
      const idx = raw.indexOf(': ');
      if (idx < 0) return ['', raw];
      return [raw.slice(0, idx), raw.slice(idx + 2)];
    }}

    function stripCategory(raw) {{
      const idx = raw.indexOf(': ');
      return idx < 0 ? raw : raw.slice(idx + 2);
    }}

    function onCategoryChange(colIdx) {{
      const sel = document.getElementById('fp-cat-' + colIdx);
      categorySelections[colIdx] = sel.value;
      delete filterSelections[colIdx];
      rebuildFilters();
      applyFilters();
    }}

    // ---- TSV parsing ----
    function parseTSV(text) {{
      const rows = [];
      for (const line of text.split('\\n')) {{
        if (!line.trim()) continue;
        rows.push(line.split('\\t'));
      }}
      return rows;
    }}

    window.addRows = function(tsvText) {{
      const rows = parseTSV(tsvText.trim());
      for (const row of rows) allDataRows.push(row);
    }};

    window.setCombinations = function(combos) {{
      allCombos = combos;
    }};

    window.addCombos = function(combo) {{
      allCombos.push(combo);
    }};

    // ---- Viz cell rendering ----
    function parseVizCell(value) {{
      if (!value || !value.trim()) return ['', null];
      value = value.trim();
      if (value.startsWith('FAILED:')) {{
        const after = value.slice('FAILED:'.length).trim();
        const parts = after.split('||', 2);
        if (parts.length === 2) return ['FAILED', parts[1].trim()];
        return ['FAILED', null];
      }}
      const parts = value.split('||', 2);
      if (parts.length === 2) return [parts[0].trim(), parts[1].trim()];
      return [value, null];
    }}

    function escapeHtml(s) {{
      const el = document.createElement('span');
      el.textContent = s;
      return el.innerHTML;
    }}

    function renderVizLink(value) {{
      const [display, url] = parseVizCell(value);
      if (display === 'FAILED' && url) {{
        const escaped = escapeHtml(url).replace(/"/g, '&quot;');
        return `<a class='failed' href='#' data-traceback="${{escaped}}" onclick='showTraceback(this); return false;'>FAILED</a>`;
      }}
      if (display === 'FAILED') return "<span class='failed'>FAILED</span>";
      if (url) return `<a href='${{url}}' target='_blank'>${{display}}</a>`;
      return '';
    }}

    function renderVizCell(value) {{
      if (!value || !value.trim()) return '<td></td>';
      const parts = value.split(' ;; ').map(v => renderVizLink(v)).filter(Boolean);
      if (parts.length === 0) return '<td></td>';
      return `<td>${{parts.join(', ')}}</td>`;
    }}

    function showTraceback(el) {{
      const tb = el.dataset.traceback;
      const w = window.open('', '_blank');
      w.document.write('<html><head><title>Traceback</title></head>');
      w.document.write('<body style="font-family:monospace;padding:20px;background:#1e1e1e;color:#d4d4d4">');
      w.document.write('<h2 style="color:#f44336">Plot Generation Traceback</h2>');
      const pre = w.document.createElement('pre');
      pre.style.cssText = 'white-space:pre-wrap;word-wrap:break-word';
      pre.textContent = tb;
      w.document.body.appendChild(pre);
      w.document.write('</body></html>');
      w.document.close();
    }}

    // ---- Cascading filter logic (uses compact combinations index) ----

    // Position of the Highlight column within a combo tuple
    const HIGHLIGHT_COMBO_POS = COL_TO_COMBO[HIGHLIGHT_COL];

    function getBaseCombos() {{
      // Start with all combos, optionally filtered by Highlight
      if (!highlightOnly) return allCombos;
      return allCombos.filter(c => (c[HIGHLIGHT_COMBO_POS] || '').trim() === 'Yes');
    }}

    function getBaseRows() {{
      // Start with all rows, optionally filtered by Highlight
      if (!highlightOnly) return allDataRows.map((_, i) => i);
      return allDataRows.reduce((acc, row, i) => {{
        if ((row[HIGHLIGHT_COL] || '').trim() === 'Yes') acc.push(i);
        return acc;
      }}, []);
    }}

    function sortValues(arr, colIdx) {{
      if (colIdx === QUANTITY_COL) {{
        const orderMap = {{}};
        QUANTITY_ORDER.forEach((q, i) => orderMap[q] = i);
        arr.sort((a, b) => {{
          const ia = orderMap.hasOwnProperty(a) ? orderMap[a] : 9999;
          const ib = orderMap.hasOwnProperty(b) ? orderMap[b] : 9999;
          return ia - ib || a.localeCompare(b);
        }});
      }} else {{
        arr.sort();
      }}
      return arr;
    }}

    function narrowRows(rowIndices, colIdx, value) {{
      return rowIndices.filter(i => (allDataRows[i][colIdx] || '').trim() === value);
    }}

    function rebuildFilters() {{
      let combos = getBaseCombos();

      for (const colIdx of FILTER_ORDER) {{
        const listEl = document.getElementById('fp-list-' + colIdx);
        if (!listEl) continue;

        const comboPos = COL_TO_COMBO[colIdx];
        // Extract unique non-empty values from the combos array
        const vals = new Set();
        for (const c of combos) {{
          const v = (c[comboPos] || '').trim();
          if (v) vals.add(v);
        }}
        const values = sortValues(Array.from(vals), colIdx);
        const selected = filterSelections[colIdx];
        const isFilterCol = FILTER_COLS.has(colIdx);
        const isMandatory = MANDATORY_FILTERS.has(colIdx);
        listEl.innerHTML = '';

        // Check if any combos have empty values in this column
        const hasEmpty = isFilterCol && combos.some(c => !(c[comboPos] || '').trim());

        // For Filter columns: populate category dropdown and filter values
        let displayValues = values;
        if (isFilterCol) {{
          const catEl = document.getElementById('fp-cat-' + colIdx);
          if (catEl) {{
            const cats = new Set();
            for (const v of values) {{ const [cat] = parseCategory(v); if (cat) cats.add(cat); }}
            const catList = Array.from(cats).sort();
            const curCat = categorySelections[colIdx] || '';
            catEl.innerHTML = '';
            const allOpt = document.createElement('option');
            allOpt.value = '';
            allOpt.textContent = '(All categories)';
            catEl.appendChild(allOpt);
            for (const cat of catList) {{
              const opt = document.createElement('option');
              opt.value = cat;
              opt.textContent = cat;
              if (cat === curCat) opt.selected = true;
              catEl.appendChild(opt);
            }}
            if (curCat && catList.includes(curCat)) {{
              displayValues = values.filter(v => v.startsWith(curCat + ': '));
            }} else {{
              categorySelections[colIdx] = '';
            }}
          }}
          if (hasEmpty) {{
            const noneDiv = document.createElement('div');
            noneDiv.className = 'fp-item all-item' + (selected === '' ? ' selected' : '');
            noneDiv.textContent = '(None)';
            noneDiv.onclick = function() {{ selectFilter(colIdx, ''); }};
            listEl.appendChild(noneDiv);
          }}
        }} else if (isMandatory) {{
          // Mandatory filters (e.g. Quantity): no "(All)" — must pick a value
        }} else {{
          if (values.length > 1) {{
            const allDiv = document.createElement('div');
            allDiv.className = 'fp-item all-item' + (!selected ? ' selected' : '');
            allDiv.textContent = '(All)';
            allDiv.onclick = function() {{ selectFilter(colIdx, null); }};
            listEl.appendChild(allDiv);
          }} else if (values.length === 1 && !selected) {{
            filterSelections[colIdx] = values[0];
          }}
        }}

        // Value items
        const effectiveSel = filterSelections[colIdx];
        for (const val of displayValues) {{
          const div = document.createElement('div');
          div.className = 'fp-item' + (val === effectiveSel ? ' selected' : '');
          const displayText = isFilterCol ? stripCategory(val) : val;
          div.textContent = displayText;
          div.title = val;
          div.onclick = (function(v) {{ return function() {{ selectFilter(colIdx, v); }}; }})(val);
          listEl.appendChild(div);
        }}

        // Narrow combos for next filter panel
        if (effectiveSel != null && effectiveSel !== '' && values.includes(effectiveSel)) {{
          combos = combos.filter(c => (c[comboPos] || '').trim() === effectiveSel);
        }} else if (effectiveSel === '' && isFilterCol) {{
          combos = combos.filter(c => !(c[comboPos] || '').trim());
        }} else if (effectiveSel && !values.includes(effectiveSel)) {{
          delete filterSelections[colIdx];
        }}
      }}
    }}

    function selectFilter(colIdx, value) {{
      if (value === null) {{
        delete filterSelections[colIdx];
      }} else {{
        filterSelections[colIdx] = value;
      }}
      // Clear all selections to the RIGHT of this filter
      const pos = FILTER_ORDER.indexOf(colIdx);
      if (pos >= 0) {{
        for (let j = pos + 1; j < FILTER_ORDER.length; j++) {{
          delete filterSelections[FILTER_ORDER[j]];
        }}
      }}
      rebuildFilters();
      applyFilters();
    }}

    function onHighlightChange() {{
      highlightOnly = document.getElementById('highlight-cb').checked;
      rebuildFilters();
      applyFilters();
    }}

    // ---- Apply filters + render ----
    function applyFilters() {{
      let rows = getBaseRows();
      for (const colIdx of FILTER_ORDER) {{
        const val = filterSelections[colIdx];
        if (val != null && val !== '') {{
          rows = narrowRows(rows, colIdx, val);
        }} else if (val === '' && (colIdx === 5 || colIdx === 6)) {{
          // "(None)" for Filter 1/2 — match empty values
          rows = rows.filter(i => !(allDataRows[i][colIdx] || '').trim());
        }}
      }}
      filteredIndices = rows;
      currentPage = 0;
      renderPage();
    }}

    function renderPage() {{
      const tbody = document.getElementById('tbody');
      tbody.innerHTML = '';
      const vizSet = new Set(VIZ_COLUMNS);
      const frag = document.createDocumentFragment();
      const start = currentPage * pageSize;
      const end = Math.min(start + pageSize, filteredIndices.length);

      for (let i = start; i < end; i++) {{
        const dataRow = allDataRows[filteredIndices[i]];
        const tr = document.createElement('tr');
        for (let c = 0; c < HEADERS.length; c++) {{
          const val = dataRow[c] || '';
          if (vizSet.has(HEADERS[c])) {{
            const tmp = document.createElement('template');
            tmp.innerHTML = renderVizCell(val);
            tr.appendChild(tmp.content.firstChild);
          }} else {{
            const td = document.createElement('td');
            td.textContent = FILTER_COLS.has(c) ? stripCategory(val) : val;
            tr.appendChild(td);
          }}
        }}
        frag.appendChild(tr);
      }}
      tbody.appendChild(frag);
      updatePagination();
    }}

    function updatePagination() {{
      totalPages = Math.max(1, Math.ceil(filteredIndices.length / pageSize));
      if (currentPage >= totalPages) currentPage = totalPages - 1;
      if (currentPage < 0) currentPage = 0;
      const start = currentPage * pageSize + 1;
      const end = Math.min((currentPage + 1) * pageSize, filteredIndices.length);
      const info = filteredIndices.length > 0
        ? `Page ${{currentPage + 1}} of ${{totalPages}} (${{start}}\\u2013${{end}} of ${{filteredIndices.length}})`
        : 'No rows';
      document.getElementById('page-info').textContent = info;
      document.getElementById('page-info-bottom').textContent = info;

      document.getElementById('btn-first').disabled = currentPage === 0;
      document.getElementById('btn-prev').disabled = currentPage === 0;
      document.getElementById('btn-next').disabled = currentPage >= totalPages - 1;
      document.getElementById('btn-last').disabled = currentPage >= totalPages - 1;

      const bb = document.getElementById('pagination-bottom').querySelectorAll('button');
      bb[0].disabled = currentPage === 0;
      bb[1].disabled = currentPage === 0;
      bb[2].disabled = currentPage >= totalPages - 1;
      bb[3].disabled = currentPage >= totalPages - 1;

      document.getElementById('stats').textContent =
        `${{filteredIndices.length}} of ${{allDataRows.length}} rows`;
    }}

    function goToPage(page) {{
      if (page < 0 || page >= totalPages) return;
      currentPage = page;
      renderPage();
    }}

    function changePageSize(newSize) {{
      pageSize = parseInt(newSize) || PAGE_SIZE_DEFAULT;
      currentPage = 0;
      renderPage();
    }}

    function resetFilters() {{
      filterSelections = {{}};
      categorySelections = {{}};
      highlightOnly = true;
      document.getElementById('highlight-cb').checked = true;
      rebuildFilters();
      applyFilters();
    }}

    // ---- Init ----
    function initPage() {{
      rebuildFilters();
      applyFilters();
    }}

    document.addEventListener('DOMContentLoaded', initPage);
  </script>

  <!-- Combinations index + shard data files (static tags for file:// compatibility) -->
{data_scripts_html}
</body>
</html>
"""


# ---------------------------------------------------------------------------
# Index state — tracks shard files for O(1) appends
# ---------------------------------------------------------------------------


class IndexState:
    """Tracks state for incremental HTML index generation.

    Manages the data directory, manifest, and per-shard suffix sizes.
    Filter-column combinations are streamed to ``combinations.js`` in
    append-only mode (one ``window.addCombos(...)`` call per row) so
    that each append is O(1).  Deduplication happens client-side in JS.
    """

    _COMBO_FLUSH_INTERVAL: int = 100  # flush combinations.js every N rows

    def __init__(self, html_path: Path, headers: Sequence[str]):
        self.html_path = html_path
        self.headers = list(headers)
        self.data_dir = html_path.parent / DATA_DIR_NAME
        self.manifest: dict[str, str] = {}
        self.shard_suffix_sizes: dict[str, int] = {}
        self._manifest_changed = False
        # Columns used for filter panels (everything except Index and viz columns)
        self._filter_col_indices = [
            i for i, h in enumerate(self.headers) if h not in _NO_FILTER_COLUMNS
        ]
        self._combo_file: io.TextIOWrapper | None = None
        self._combo_count: int = 0

    def _create_shard(self, filter1_value: str) -> str:
        """Create a new shard JS file and return its filename."""
        filename = _shard_filename(filter1_value)
        shard_path = self.data_dir / filename
        content = "window.addRows(`\n" + _JS_SUFFIX
        shard_path.write_text(content, encoding="utf-8")
        self.shard_suffix_sizes[filename] = len(_JS_SUFFIX.encode("utf-8"))
        return filename

    def get_or_create_shard(self, filter1_value: str) -> str:
        """Get (or create) the shard filename for a Filter 1 value."""
        if filter1_value in self.manifest:
            return self.manifest[filter1_value]
        filename = self._create_shard(filter1_value)
        self.manifest[filter1_value] = filename
        self._manifest_changed = True
        return filename

    def open_combo_file(self) -> None:
        """Open combinations.js for append-mode streaming."""
        combo_path = self.data_dir / COMBINATIONS_FILENAME
        self._combo_file = open(combo_path, "a", encoding="utf-8")

    def close_combo_file(self) -> None:
        """Flush and close the combinations.js file handle."""
        if self._combo_file:
            self._combo_file.flush()
            self._combo_file.close()
            self._combo_file = None

    def append_to_shard(self, filter1_value: str, row_dict: dict) -> None:
        """Append a CSV row to the appropriate shard file in O(1) time."""
        self._manifest_changed = False
        filename = self.get_or_create_shard(filter1_value)
        shard_path = self.data_dir / filename
        suffix_size = self.shard_suffix_sizes[filename]

        # Serialize the row as a TSV line
        buf = io.StringIO()
        writer = csv.DictWriter(buf, fieldnames=self.headers, delimiter="\t")
        writer.writerow(row_dict)
        csv_line = buf.getvalue()  # includes trailing \n

        # Escape characters that are special inside JS template literals.
        # Order matters: escape backslashes first, then backticks and ${.
        csv_line = csv_line.replace("\\", "\\\\").replace("`", "\\`").replace("${", "\\${")

        with open(shard_path, "r+b") as f:
            f.seek(-suffix_size, 2)  # SEEK_END
            f.write(csv_line.encode("utf-8"))
            f.write(_JS_SUFFIX.encode("utf-8"))

        # Append filter-column combination to combinations.js (O(1) per row).
        # Duplicates are expected — JS deduplicates via Set at page load.
        combo = [row_dict.get(self.headers[i], "") for i in self._filter_col_indices]
        if self._combo_file:
            self._combo_file.write(f"window.addCombos({json.dumps(combo)});\n")
            self._combo_count += 1
            if self._combo_count % self._COMBO_FLUSH_INTERVAL == 0:
                self._combo_file.flush()

    @property
    def needs_html_rewrite(self) -> bool:
        """True if the last append created a new shard (new manifest entry)."""
        return self._manifest_changed


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


def _atomic_write(path: Path, content: str) -> None:
    """Write *content* to *path* atomically via temp-file + rename."""
    fd, tmp = tempfile.mkstemp(dir=path.parent, suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(content)
        os.replace(tmp, path)
    except BaseException:
        os.unlink(tmp)
        raise


def init_html_index(html_path: Path, headers: Sequence[str]) -> IndexState:
    """Create the data directory and prepare for row appending.

    Args:
        html_path: Where comparisons_index.html will be written.
        headers: Column names for the table.

    Returns:
        An ``IndexState`` that callers pass to ``append_index_row``.
    """
    html_path.parent.mkdir(parents=True, exist_ok=True)
    data_dir = html_path.parent / DATA_DIR_NAME
    data_dir.mkdir(parents=True, exist_ok=True)

    state = IndexState(html_path, headers)
    # Truncate combinations.js and open for append-mode streaming
    (data_dir / COMBINATIONS_FILENAME).write_text("", encoding="utf-8")
    state.open_combo_file()
    return state


@timed
def append_index_row(state: IndexState, row_dict: dict) -> None:
    """Append a single row to the correct shard file.

    Routes the row to a shard based on its ``Filter 1`` value.
    Combinations are streamed to ``combinations.js`` in O(1) per row.
    The HTML shell is only rewritten when a new shard is created
    (new ``Filter 1`` value), which happens ~100 times, not 250K.
    """
    filter1_value = row_dict.get(_FILTER1_COLUMN, "").strip()
    state.append_to_shard(filter1_value, row_dict)
    if state.needs_html_rewrite:
        _atomic_write(
            state.html_path,
            _build_html_shell(state.headers, state.manifest),
        )


def finalize_html_index(state: IndexState) -> None:
    """Write the final HTML and close the combinations file.

    Always rewrites the HTML to guarantee a clean final version.
    """
    state.close_combo_file()
    _atomic_write(
        state.html_path,
        _build_html_shell(state.headers, state.manifest),
    )


# ---------------------------------------------------------------------------
# Batch interface
# ---------------------------------------------------------------------------


def create_html_from_csv(csv_path: Path, html_path: Path) -> None:
    """Convert a TSV index to an HTML index with sharded data files.

    Args:
        csv_path: Path to the input TSV file
        html_path: Path to write the output HTML file
    """
    with open(csv_path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter="\t")
        headers = reader.fieldnames
        if not headers:
            html_path.write_text("<html><body><p>Empty file</p></body></html>")
            return
        rows = list(reader)

    if not rows:
        html_path.write_text("<html><body><p>No data rows</p></body></html>")
        return

    state = init_html_index(html_path, headers)
    for row in rows:
        append_index_row(state, row)
    finalize_html_index(state)

    total_shards = len(state.manifest)
    print(f"HTML file created: {html_path} ({len(rows)} rows, {total_shards} shards)")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python create_html.py <input.tsv> <output.html>")
        print("Example: python create_html.py comparisons_index.tsv comparisons_index.html")
        sys.exit(1)

    csv_path = Path(sys.argv[1])
    html_path = Path(sys.argv[2])

    if not csv_path.exists():
        print(f"Error: Input file not found: {csv_path}")
        sys.exit(1)

    create_html_from_csv(csv_path, html_path)
