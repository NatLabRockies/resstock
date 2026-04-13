"""Generate comparisons_index.html with single-select sidebar filters and inline plot viewer.

This is an alternative index UI to comparisons_index.html.

Behavior:
- Left sidebar contains all filter dimensions, single-select only (no "All").
- Right panel shows tabbed content for available comparison plots.
- A dedicated "Data Table" tab is included when a data-table HTML exists.
"""

from __future__ import annotations

import csv
import io
import json
import os
import re
import sys
import tempfile
from collections import defaultdict
from collections.abc import Sequence
from pathlib import Path


NON_FILTER_COLUMNS = {"Index", "Comparison Plot", "Data"}
_FILTER1_COLUMN = "Filter 1"
DATA_DIR_NAME = "comparisons_index_data"
COMBINATIONS_FILENAME = "combinations.js"
_JS_SUFFIX = "\n`);\n"


class IndexState:
  """Incremental index state for O(1) shard appends and streamed combinations."""

  def __init__(self, html_path: Path, headers: Sequence[str]):
    self.html_path = html_path
    headers_list = list(headers)
    if "Coverage" not in headers_list:
      insert_at = headers_list.index("Metric") + 1 if "Metric" in headers_list else len(headers_list)
      headers_list.insert(insert_at, "Coverage")
    self.headers = headers_list
    self.data_dir = html_path.parent / DATA_DIR_NAME
    self.manifest: dict[str, str] = {}
    self.shard_suffix_sizes: dict[str, int] = {}
    self.filter_cols = [h for h in self.headers if h not in NON_FILTER_COLUMNS]
    self._combo_file = None
    self._manifest_changed = False
    self._combo_count = 0
    self._combo_flush_interval = 1000

  def _create_shard(self, filter1_value: str) -> str:
    filename = _shard_filename(filter1_value)
    shard_path = self.data_dir / filename
    shard_path.write_text("window.addRows(`\n" + _JS_SUFFIX, encoding="utf-8")
    self.shard_suffix_sizes[filename] = len(_JS_SUFFIX.encode("utf-8"))
    self.manifest[filter1_value] = filename
    self._manifest_changed = True
    return filename

  def get_or_create_shard(self, filter1_value: str) -> str:
    if filter1_value in self.manifest:
      self._manifest_changed = False
      return self.manifest[filter1_value]
    return self._create_shard(filter1_value)

  def open_combo_file(self) -> None:
    combo_path = self.data_dir / COMBINATIONS_FILENAME
    self._combo_file = open(combo_path, "a", encoding="utf-8")

  def close_combo_file(self) -> None:
    if self._combo_file:
      self._combo_file.flush()
      self._combo_file.close()
      self._combo_file = None

  def append_to_shard(self, row_dict: dict) -> None:
    self._manifest_changed = False

    row = dict(row_dict)
    row.setdefault("Coverage", "All Units")
    row = _normalize_rows([row])[0]
    row = {h: row.get(h, "") for h in self.headers}

    filter1_value = str(row.get(_FILTER1_COLUMN, "")).strip()
    filename = self.get_or_create_shard(filter1_value)
    shard_path = self.data_dir / filename
    suffix_size = self.shard_suffix_sizes[filename]
    tsv_line = _row_to_tsv_line(row, self.headers)

    with open(shard_path, "r+b") as f:
      f.seek(-suffix_size, 2)
      f.write(tsv_line.encode("utf-8"))
      f.write(_JS_SUFFIX.encode("utf-8"))

    combo = [row.get(c, "") for c in self.filter_cols]
    if self._combo_file:
      self._combo_file.write(f"window.addCombos({json.dumps(combo, ensure_ascii=False)});\n")
      self._combo_count += 1
      if self._combo_count % self._combo_flush_interval == 0:
        self._combo_file.flush()

  @property
  def needs_html_rewrite(self) -> bool:
    return self._manifest_changed


def _atomic_write(path: Path, content: str) -> None:
  fd, tmp = tempfile.mkstemp(dir=path.parent, suffix=".tmp")
  try:
    with os.fdopen(fd, "w", encoding="utf-8") as f:
      f.write(content)
    os.replace(tmp, path)
  except BaseException:
    os.unlink(tmp)
    raise


def _canonical_metric_label(metric: str) -> str:
  """Normalize metric labels for index filter display."""
  m = (metric or "").strip()
  if not m:
    return m

  if m in {
    "Total Annual Consumption",
    "Total Monthly Consumption",
    "Average Annual Consumption",
    "Average Monthly Consumption",
    "Distribution of Annual Consumption",
    "Enduse Penetration",
  }:
    return m

  if m == "Annual Consumption":
    return "Total Annual Consumption"
  if m == "Monthly Consumption":
    return "Total Monthly Consumption"
  if m.startswith("Average Annual Consumption"):
    return "Average Annual Consumption"
  if m.startswith("Average Monthly Consumption"):
    return "Average Monthly Consumption"
  if m.startswith("Distribution"):
    return "Distribution of Annual Consumption"
  return m


def _normalize_rows(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    """Normalize rows for UI display while preserving original dataset paths."""
    norm_rows: list[dict[str, str]] = []
    for row in rows:
        r = dict(row)
        ds = str(r.get("Comparison Dataset", "")).strip().upper()
        if "Metric" in r and not ds.startswith("LRD"):
            r["Metric"] = _canonical_metric_label(str(r.get("Metric", "")))
        norm_rows.append(r)
    return norm_rows


def _sanitize_filename(value: str) -> str:
    safe = value.replace(" ", "_")
    safe = re.sub(r"[^\w\-.]", "_", safe)
    return safe


def _shard_filename(filter1_value: str) -> str:
    if not filter1_value or not filter1_value.strip():
        return "data-_none_.js"
    return f"data-{_sanitize_filename(filter1_value)}.js"


def _row_to_tsv_line(row: dict[str, str], headers: Sequence[str]) -> str:
    buf = io.StringIO()
    writer = csv.DictWriter(buf, fieldnames=headers, delimiter="\t", lineterminator="\n")
    writer.writerow(row)
    line = buf.getvalue()
    return line.replace("\\", "\\\\").replace("`", "\\`").replace("${", "\\${")


def _build_html(headers: Sequence[str], manifest: dict[str, str]) -> str:
    filter_cols = [h for h in headers if h not in NON_FILTER_COLUMNS]
    headers_json = json.dumps(list(headers), ensure_ascii=False)
    filter_cols_json = json.dumps(filter_cols, ensure_ascii=False)

    data_script_tags = [
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
  <title>ResStock Comparison Explorer</title>
  <style>
    * {{ box-sizing: border-box; }}
    html, body {{ height: 100%; overflow: hidden; }}
    body {{ margin: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #1a1a1a; }}
    .app {{ display: grid; grid-template-columns: 322px 1fr; height: 100vh; height: 100dvh; }}
    .sidebar {{
      border-right: 1px solid #ddd;
      padding: 12px;
      overflow: hidden;
      background: #fafafa;
      display: flex;
      flex-direction: column;
      min-height: 0;
    }}
    .title {{ font-size: 20px; font-weight: 700; margin: 4px 0 12px; }}
    #filters {{
      flex: 1 1 auto;
      min-height: 0;
      display: flex;
      flex-direction: column;
      gap: 8px;
    }}
    .filter-block {{
      margin-bottom: 0;
      min-height: 0;
      display: flex;
      flex-direction: column;
      flex: 1 1 0;
    }}
    .filter-label {{ font-size: 12px; color: #555; margin-bottom: 4px; font-weight: 600; }}
    .filter-list {{
      border: 1px solid #bbb;
      border-radius: 4px;
      background: #fff;
      overflow-y: auto;
      min-height: 0;
      flex: 1 1 auto;
    }}
    .filter-item {{ padding: 5px 7px; font-size: 13px; cursor: pointer; border-bottom: 1px solid #eee; }}
    .filter-item:last-child {{ border-bottom: none; }}
    .filter-item:hover {{ background: #e8f0fe; }}
    .filter-item.selected {{
      background: #d2e3fc;
      font-weight: 600;
    }}
    .filter-item.selected.sticky-selected {{
      position: sticky;
      top: 0;
      z-index: 1;
    }}
    .main {{ display: grid; grid-template-rows: auto auto 1fr; min-width: 0; }}
    .tabs {{
      display: flex;
      gap: 4px;
      align-items: center;
      padding: 8px 10px 0;
      border-bottom: 1px solid #c6c6c6;
      background: #f6f6f6;
    }}
    .tab {{
      margin-bottom: -1px;
      border: 1px solid #b8b8b8;
      border-bottom-color: #c6c6c6;
      border-radius: 7px 7px 0 0;
      background: #efefef;
      color: #555;
      padding: 6px 12px;
      cursor: pointer;
      font-size: 13px;
    }}
    .tab.active {{
      background: #fff;
      border-color: #b8b8b8;
      border-bottom-color: #fff;
      color: #0b57d0;
      font-weight: 700;
    }}
    .tab-tools {{
      display: flex;
      justify-content: flex-end;
      align-items: center;
      min-height: 22px;
      padding: 2px 10px 4px;
      background: #fff;
      border: none;
    }}
    .open-tab-link {{
      font-size: 12px;
      color: #0b57d0;
      text-decoration: none;
      white-space: nowrap;
    }}
    .open-tab-link:hover {{
      text-decoration: underline;
    }}
    .viewer {{
      position: relative;
      min-height: 0;
      border: 1px solid #c6c6c6;
      border-top: none;
      border-left: none;
      background: #fff;
    }}
    iframe {{ width: 100%; height: 100%; border: 0; }}
    .empty {{ padding: 14px; color: #b3261e; }}
  </style>
</head>
<body>
  <div class='app'>
    <aside class='sidebar'>
      <div class='title'>ResStock Comparison Explorer</div>
      <div id='filters'></div>
    </aside>
    <main class='main'>
      <div class='tabs' id='tabs'></div>
      <div class='tab-tools' id='tabTools'></div>
      <div class='viewer' id='viewer'></div>
    </main>
  </div>

  <script>
    const HEADERS = {headers_json};
    const FILTER_COLS = {filter_cols_json};
    const METRIC_ORDER = [
      'Total Annual Consumption',
      'Total Monthly Consumption',
      'Average Annual Consumption',
      'Average Monthly Consumption',
      'Distribution of Annual Consumption',
      'Enduse Penetration',
    ];
    const QUANTITY_PRIORITY = {{
      'Number of dwelling units': 0,
      'All Enduses': 1,
      'All Enduses (Stacked)': 1,
      'Electricity': 2,
      'Natural Gas': 3,
      'Propane': 4,
      'Fuel Oil': 5,
      // Defensive aliases in case alternate labels appear in future rows.
      'Electricity Total': 2,
      'Natural Gas Total': 3,
      'Propane Total': 4,
      'Fuel Oil Total': 5,
    }};
    const FUEL_GROUP_ORDER = {{
      'Electricity': 0,
      'Natural Gas': 1,
      'Propane': 2,
      'Fuel Oil': 3,
    }};

    const COL_IDX = Object.create(null);
    HEADERS.forEach((h, i) => COL_IDX[h] = i);

    const ROWS = [];
    let COMBOS = [];
    const selection = Object.create(null);
    let currentTabs = [];
    let activeTabIdx = 0;
    let requestedTabIdx = null;
    const KEY_INFO = new Map();
    const NL = String.fromCharCode(10);
    const TAB = String.fromCharCode(9);
    const KEY_SEP = String.fromCharCode(31);

    function norm(v) {{
      return (v ?? '').toString().trim();
    }}

    function fmt(v) {{
      return norm(v) === '' ? '(None)' : v;
    }}

    function parseTSV(text) {{
      const rows = [];
      for (const line of text.split(NL)) {{
        if (!line.trim()) continue;
        rows.push(line.split(TAB));
      }}
      return rows;
    }}

    window.addRows = function(tsvText) {{
      const rows = parseTSV(tsvText.trim());
      for (const row of rows) ROWS.push(row);
    }};

    window.setCombinations = function(combos) {{
      COMBOS = combos;
    }};

    window.addCombos = function(combo) {{
      COMBOS.push(combo);
    }};

    function comboPos(col) {{
      return FILTER_COLS.indexOf(col);
    }}

    function quantityFuelGroup(value) {{
      if (value.endsWith(' Electricity')) return 'Electricity';
      if (value.endsWith(' Natural Gas')) return 'Natural Gas';
      if (value.endsWith(' Propane')) return 'Propane';
      if (value.endsWith(' Fuel Oil')) return 'Fuel Oil';
      return null;
    }}

    function quantitySortKey(value) {{
      if (Object.prototype.hasOwnProperty.call(QUANTITY_PRIORITY, value)) {{
        return [QUANTITY_PRIORITY[value], value];
      }}
      const group = quantityFuelGroup(value);
      if (group != null) {{
        return [10 + FUEL_GROUP_ORDER[group], value];
      }}
      return [9999, value];
    }}

    function keyFromFilterSelection() {{
      return FILTER_COLS.map(c => norm(selection[c])).join(KEY_SEP);
    }}

    function keyFromRow(rowArr) {{
      return FILTER_COLS.map(c => norm(rowArr[COL_IDX[c]])).join(KEY_SEP);
    }}

    function buildLookup() {{
      KEY_INFO.clear();
      for (let i = 0; i < ROWS.length; i++) {{
        const key = keyFromRow(ROWS[i]);
        const info = KEY_INFO.get(key);
        if (info) {{
          info.rowIdxs.push(i);
        }} else {{
          KEY_INFO.set(key, {{ rowIdxs: [i] }});
        }}
      }}
    }}

    function parseEntries(cellValue) {{
      if (!cellValue || !cellValue.trim()) return [];
      return cellValue
        .split(' ;; ')
        .map(s => s.trim())
        .filter(Boolean)
        .filter(s => !s.startsWith('FAILED:'))
        .map(s => s.split('||', 2))
        .filter(parts => parts.length === 2 && parts[1].trim())
        .map(parts => ({{ label: parts[0].trim(), path: parts[1].trim() }}));
    }}

    function loadStateFromUrl() {{
      const params = new URLSearchParams(window.location.search);
      FILTER_COLS.forEach((col, i) => {{
        const key = `f${{i}}`;
        if (params.has(key)) {{
          selection[col] = params.get(key) ?? '';
        }}
      }});
      if (params.has('tab')) {{
        const parsed = Number.parseInt(params.get('tab') || '0', 10);
        if (Number.isFinite(parsed) && parsed >= 0) {{
          requestedTabIdx = parsed;
        }}
      }}
    }}

    function writeStateToUrl() {{
      const params = new URLSearchParams();
      FILTER_COLS.forEach((col, i) => {{
        params.set(`f${{i}}`, norm(selection[col]));
      }});
      params.set('tab', String(activeTabIdx));
      const qs = params.toString();
      const newUrl = qs
        ? `${{window.location.pathname}}?${{qs}}${{window.location.hash}}`
        : window.location.pathname;
      window.history.replaceState(null, '', newUrl);
    }}

    function optionsFor(col, priorCols) {{
      let subset = COMBOS;
      for (const p of priorCols) {{
        const pPos = comboPos(p);
        subset = subset.filter(c => norm(c[pPos]) === norm(selection[p] ?? ''));
      }}
      const cPos = comboPos(col);
      const vals = Array.from(new Set(subset.map(c => norm(c[cPos]))));
      if (col === 'Metric') {{
        const orderMap = {{}};
        METRIC_ORDER.forEach((m, i) => orderMap[m] = i);
        vals.sort((a, b) => {{
          const ia = Object.prototype.hasOwnProperty.call(orderMap, a) ? orderMap[a] : 9999;
          const ib = Object.prototype.hasOwnProperty.call(orderMap, b) ? orderMap[b] : 9999;
          return ia - ib || a.localeCompare(b);
        }});
      }} else if (col === 'Quantity') {{
        vals.sort((a, b) => {{
          const [pa, la] = quantitySortKey(a);
          const [pb, lb] = quantitySortKey(b);
          return pa - pb || la.localeCompare(lb);
        }});
      }} else {{
        vals.sort((a, b) => a.localeCompare(b));
      }}
      return vals;
    }}

    function rebuildFilters(changedCol) {{
      const startIdx = changedCol ? FILTER_COLS.indexOf(changedCol) : 0;
      for (let i = Math.max(0, startIdx); i < FILTER_COLS.length; i++) {{
        const col = FILTER_COLS[i];
        const prior = FILTER_COLS.slice(0, i);
        const opts = optionsFor(col, prior);
        if (!opts.includes(norm(selection[col] ?? ''))) {{
          selection[col] = opts.length ? opts[0] : '';
        }}
      }}
      renderFilters();
      renderMain();
    }}

    function renderFilters() {{
      const host = document.getElementById('filters');
      host.innerHTML = '';
      const rowPx = 27;
      const compactableLists = [];
      FILTER_COLS.forEach(col => {{
        const i = FILTER_COLS.indexOf(col);
        const prior = FILTER_COLS.slice(0, i);
        const opts = optionsFor(col, prior);

        const block = document.createElement('div');
        block.className = 'filter-block';

        const label = document.createElement('div');
        label.className = 'filter-label';
        label.textContent = col;
        block.appendChild(label);

        const list = document.createElement('div');
        list.className = 'filter-list';

        if (col === 'Quantity') {{
          // Keep Quantity selector stable, but allow adaptive compaction if needed.
          const visibleCount = 5;
          list.style.flex = '0 0 auto';
          list.style.maxHeight = `${{visibleCount * rowPx + 2}}px`;
          block.style.flex = '0 0 auto';
          list.dataset.currentRows = String(visibleCount);
          list.dataset.minRows = '3';
          compactableLists.push(list);
        }}

        if (col === 'Metric') {{
          // Show all metric options at all times (no internal scrollbar).
          const visibleCount = Math.max(1, opts.length);
          list.style.flex = '0 0 auto';
          list.style.maxHeight = `${{visibleCount * rowPx + 2}}px`;
          block.style.flex = '0 0 auto';
        }}

        if (col === 'Filter 1' || col === 'Filter 2' || col === 'Group By') {{
          // Make these lists adapt to content so they don't reserve excess space.
          const visibleCount = Math.max(1, Math.min(opts.length, 6));
          list.style.flex = '0 0 auto';
          list.style.maxHeight = `${{visibleCount * rowPx + 2}}px`;
          block.style.flex = '0 0 auto';
          if (col === 'Filter 1' || col === 'Filter 2') {{
            list.dataset.currentRows = String(visibleCount);
            list.dataset.minRows = '2';
            compactableLists.push(list);
          }}
        }}
        if (col === 'Coverage') {{
          // Coverage has only two options; keep it compact.
          list.style.flex = '0 0 auto';
          list.style.maxHeight = `${{2 * rowPx + 2}}px`;
          block.style.flex = '0 0 auto';
        }}
        if (col === 'Comparison Dataset') {{
          // Keep dataset selector compact to exactly three visible entries.
          list.style.flex = '0 0 auto';
          list.style.maxHeight = `${{3 * rowPx + 2}}px`;
          block.style.flex = '0 0 auto';
        }}

        for (const val of opts) {{
          const item = document.createElement('div');
          item.className = 'filter-item' + (norm(selection[col]) === val ? ' selected' : '');
          item.textContent = fmt(val);
          item.onclick = () => {{
            selection[col] = val;
            rebuildFilters(col);
          }};
          list.appendChild(item);
        }}

        block.appendChild(list);
        host.appendChild(block);

        // Enable sticky pinning only when the list actually overflows.
        // Must run after mount, because clientHeight is unreliable before DOM layout.
        const selectedItem = list.querySelector('.filter-item.selected');
        if (selectedItem) {{
          const hasOverflow = list.scrollHeight > list.clientHeight + 1;
          if (hasOverflow) {{
            selectedItem.classList.add('sticky-selected');
            list.prepend(selectedItem);
          }} else {{
            selectedItem.classList.remove('sticky-selected');
          }}
        }}
      }});

      // If the stack is too tall, compact key lists so Group By remains visible.
      // Shrinks Quantity/Metric/Filter 1/Filter 2 one row at a time to their mins.
      while (host.scrollHeight > host.clientHeight + 1) {{
        const candidates = compactableLists
          .filter(l => Number(l.dataset.currentRows || '0') > Number(l.dataset.minRows || '0'))
          .sort((a, b) => Number(b.dataset.currentRows || '0') - Number(a.dataset.currentRows || '0'));
        if (!candidates.length) break;
        const list = candidates[0];
        const nextRows = Number(list.dataset.currentRows || '0') - 1;
        list.dataset.currentRows = String(nextRows);
        list.style.maxHeight = `${{nextRows * rowPx + 2}}px`;
      }}
    }}

    function getDataTableTabs(row) {{
      const entries = parseEntries(row?.[COL_IDX['Data']] || '');
      if (!entries.length) return [];
      const lower = s => (s || '').toLowerCase();
      return entries
        .filter(e => lower(e.path).endsWith('.html') || lower(e.path).endsWith('.htm'))
        .map(e => ({{
          label: e.label && e.label.toLowerCase() === 'data table' ? 'Data Table' : (e.label || 'Data Table'),
          path: e.path,
        }}));
    }}

    function uniquifyTabLabels(tabs) {{
      const counts = Object.create(null);
      return tabs.map(tab => {{
        const base = tab.label || 'Plot';
        const next = (counts[base] || 0) + 1;
        counts[base] = next;
        return next === 1 ? tab : {{ ...tab, label: `${{base}} (${{next}})` }};
      }});
    }}

    function collectTabsForRows(rowIdxs) {{
      const plotTabs = [];
      const dataTabs = [];
      for (const rowIdx of rowIdxs) {{
        const row = ROWS[rowIdx];
        plotTabs.push(...parseEntries(row?.[COL_IDX['Comparison Plot']] || ''));
        dataTabs.push(...getDataTableTabs(row));
      }}
      return uniquifyTabLabels([...plotTabs, ...dataTabs]);
    }}

    function renderTabs() {{
      const host = document.getElementById('tabs');
      host.innerHTML = '';
      currentTabs.forEach((p, idx) => {{
        const b = document.createElement('button');
        b.className = 'tab' + (idx === activeTabIdx ? ' active' : '');
        b.textContent = p.label || `Plot ${{idx + 1}}`;
        b.onclick = () => {{
          activeTabIdx = idx;
          renderTabs();
          renderOpenTabLink();
          renderViewer();
          writeStateToUrl();
        }};
        host.appendChild(b);
      }});
    }}

    function renderOpenTabLink() {{
      const host = document.getElementById('tabTools');
      host.innerHTML = '';
      if (!currentTabs.length) return;
      const openLink = document.createElement('a');
      openLink.className = 'open-tab-link';
      openLink.textContent = 'Open in a new tab';
      openLink.target = '_blank';
      openLink.rel = 'noopener noreferrer';
      openLink.href = currentTabs[activeTabIdx].path;
      host.appendChild(openLink);
    }}

    function renderViewer() {{
      const host = document.getElementById('viewer');
      host.innerHTML = '';
      if (!currentTabs.length) {{
        const d = document.createElement('div');
        d.className = 'empty';
        d.textContent = 'No content available for this selection.';
        host.appendChild(d);
        return;
      }}
      const iframe = document.createElement('iframe');
      iframe.src = currentTabs[activeTabIdx].path;
      host.appendChild(iframe);
    }}

    function renderMain() {{
      const key = keyFromFilterSelection();
      const info = KEY_INFO.get(key) || null;
      const rowIdxs = info ? info.rowIdxs : [];
      currentTabs = collectTabsForRows(rowIdxs);
      if (requestedTabIdx != null) {{
        activeTabIdx = Math.max(
          0,
          Math.min(requestedTabIdx, Math.max(0, currentTabs.length - 1)),
        );
        requestedTabIdx = null;
      }} else if (activeTabIdx >= currentTabs.length) {{
        activeTabIdx = 0;
      }}

      renderTabs();
      renderOpenTabLink();
      renderViewer();
      writeStateToUrl();
    }}

    function initPage() {{
      buildLookup();
      loadStateFromUrl();

      FILTER_COLS.forEach((col, i) => {{
        const opts = optionsFor(col, FILTER_COLS.slice(0, i));
        if (!(col in selection)) {{
          selection[col] = opts.length ? opts[0] : '';
        }}
      }});

      rebuildFilters();
    }}

    document.addEventListener('DOMContentLoaded', initPage);
  </script>

{data_scripts_html}
</body>
</html>
"""


def create_html_from_rows(rows: list[dict[str, str]], headers: Sequence[str], html_path: Path) -> None:
    if not headers:
        html_path.write_text("<html><body><p>Empty file</p></body></html>", encoding="utf-8")
        return

    headers_list = list(headers)
    if "Coverage" not in headers_list:
        insert_at = headers_list.index("Metric") + 1 if "Metric" in headers_list else len(headers_list)
        headers_list.insert(insert_at, "Coverage")

    row_list = []
    for r in rows:
        rr = dict(r)
        rr.setdefault("Coverage", "All Units")
        row_list.append(rr)

    html_path.parent.mkdir(parents=True, exist_ok=True)
    data_dir = html_path.parent / DATA_DIR_NAME
    data_dir.mkdir(parents=True, exist_ok=True)

    shard_rows: dict[str, list[dict[str, str]]] = defaultdict(list)
    combinations_set: set[tuple[str, ...]] = set()
    filter_cols = [h for h in headers_list if h not in NON_FILTER_COLUMNS]

    for raw in _normalize_rows(row_list):
        filter1 = raw.get(_FILTER1_COLUMN, "").strip()
        shard_rows[filter1].append(raw)
        combinations_set.add(tuple(raw.get(c, "") for c in filter_cols))

    manifest: dict[str, str] = {}
    for filter1, shard in shard_rows.items():
        filename = _shard_filename(filter1)
        manifest[filter1] = filename
        shard_path = data_dir / filename
        content = ["window.addRows(`\n"]
        content.extend(_row_to_tsv_line(r, headers_list) for r in shard)
        content.append(_JS_SUFFIX)
        shard_path.write_text("".join(content), encoding="utf-8")

    combos = [list(t) for t in sorted(combinations_set)]
    combo_path = data_dir / COMBINATIONS_FILENAME
    combo_path.write_text(
        f"window.setCombinations({json.dumps(combos, ensure_ascii=False)});\n",
        encoding="utf-8",
    )

    html_path.write_text(_build_html(headers_list, manifest), encoding="utf-8")
    print(f"HTML file created: {html_path} ({len(row_list)} rows, {len(manifest)} shards)")


def create_html_from_csv(csv_path: Path, html_path: Path) -> None:
    with open(csv_path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter="\t")
        headers = reader.fieldnames or []
        rows = list(reader)
    create_html_from_rows(rows, headers, html_path)


# Backward-compatible alias if older callers still reference this name.
create_html2_from_csv = create_html_from_csv


def init_html_index(html_path: Path, headers: Sequence[str]) -> IndexState:
    """Initialize disk-backed index state for incremental row append."""
    html_path.parent.mkdir(parents=True, exist_ok=True)
    data_dir = html_path.parent / DATA_DIR_NAME
    data_dir.mkdir(parents=True, exist_ok=True)

    state = IndexState(html_path=html_path, headers=headers)
    (data_dir / COMBINATIONS_FILENAME).write_text("", encoding="utf-8")
    state.open_combo_file()
    return state


def append_index_row(state: IndexState, row_dict: dict) -> None:
    """Append one row to disk shards/combinations in O(1)."""
    state.append_to_shard(row_dict)
    if state.needs_html_rewrite:
        _atomic_write(state.html_path, _build_html(state.headers, state.manifest))


def finalize_html_index(state: IndexState) -> None:
    """Close streams and write final comparisons_index.html."""
    state.close_combo_file()
    _atomic_write(state.html_path, _build_html(state.headers, state.manifest))


def main() -> int:
  if len(sys.argv) != 3:
    print("Usage: python -m resstockpostproc.baseline_validation.create_html <input.tsv> <output.html>")
    return 1

  csv_path = Path(sys.argv[1])
  html_path = Path(sys.argv[2])

  if not csv_path.exists():
    print(f"Error: Input file not found: {csv_path}")
    return 1

  create_html_from_csv(csv_path, html_path)
  return 0


if __name__ == "__main__":
    raise SystemExit(main())
