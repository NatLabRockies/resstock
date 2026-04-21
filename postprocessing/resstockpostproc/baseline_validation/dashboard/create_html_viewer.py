"""Dashboard viewer HTML shell for the baseline validation index.

Extracted from create_html.py in refactor plan V2 step 4.2. This module
owns the self-contained HTML shell (inline CSS + JS + filter UI) that
wraps the sharded dashboard data. Data writing and IndexState lifecycle
stay in create_html.py.
"""

from __future__ import annotations

import json
from collections.abc import Sequence

from resstockpostproc.baseline_validation.schema.plot_spec import ALL_ENDUSES_DISPLAY


NON_FILTER_COLUMNS = {"Index", "Comparison Plot", "Data"}
COMBINATIONS_FILENAME = "combinations.js"
METRIC_ORDER = [
    "Total Annual Consumption",
    "Total Monthly Consumption",
    "Average Annual Consumption",
    "Average Monthly Consumption",
    "Average Daily Consumption",
    "Average Day Hourly Consumption",
    "Load Duration Plot",
    "Load Vs Outdoor Drybulb Temperature",
    "Distribution of Annual Consumption",
    "Enduse Penetration",
]


def build_html(headers: Sequence[str], manifest: dict[str, str], data_dir_href: str) -> str:
    filter_cols = [h for h in headers if h not in NON_FILTER_COLUMNS]
    headers_json = json.dumps(list(headers), ensure_ascii=False)
    filter_cols_json = json.dumps(filter_cols, ensure_ascii=False)
    metric_order_json = json.dumps(METRIC_ORDER, ensure_ascii=False)
    manifest_json = json.dumps(manifest, ensure_ascii=False)

    data_script_tags = [
        f'  <script src="{data_dir_href}/{COMBINATIONS_FILENAME}" defer></script>',
    ]
    if "" in manifest:
        data_script_tags.append(f'  <script src="{data_dir_href}/{manifest[""]}" defer></script>')
    for key in sorted(k for k in manifest if k != ""):
        data_script_tags.append(f'  <script src="{data_dir_href}/{manifest[key]}" defer></script>')
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
    .filter-tabs {{
      display: flex;
      gap: 4px;
      align-items: center;
      padding: 0 4px 0;
      margin-bottom: 0;
      border: none;
      border-bottom: 1px solid #bbb;
      border-radius: 0;
      background: transparent;
      overflow: hidden;
      flex-wrap: wrap;
    }}
    .filter-tab {{
      margin-bottom: -1px;
      border: 1px solid #b8b8b8;
      border-bottom-color: #bbb;
      border-radius: 7px 7px 0 0;
      background: #efefef;
      color: #555;
      padding: 5px 10px;
      cursor: pointer;
      font-size: 12px;
      line-height: 1;
      white-space: nowrap;
    }}
    .filter-tab:hover {{ background: #e8f0fe; }}
    .filter-tab.active {{
      background: #d2e3fc;
      border-color: #8ab4f8;
      border-bottom-color: #d2e3fc;
      color: #0b57d0;
      font-weight: 700;
    }}
    .filter-list {{
      border: 1px solid #bbb;
      border-radius: 4px;
      background: #fff;
      overflow-y: auto;
      min-height: 0;
      flex: 1 1 auto;
    }}
    .filter-list.with-tabs {{
      border-top: none;
      border-top-left-radius: 0;
      border-top-right-radius: 0;
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
    const METRIC_ORDER = {metric_order_json};
    window.shardManifest = {manifest_json};
    const QUANTITY_PRIORITY = {{
      'Number of dwelling units': 0,
      {json.dumps(ALL_ENDUSES_DISPLAY)}: 1,
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
    const FILTER1_COL = 'Filter 1';
    const FILTER2_COL = 'Filter 2';
    const FILTER_TAB_PRIORITY = ['Building Type', 'Census Division', 'State'];
    const FILTER_TAB_PRIORITY_MAP = Object.create(null);
    FILTER_TAB_PRIORITY.forEach((label, idx) => FILTER_TAB_PRIORITY_MAP[label] = idx);
    const filterTabSelection = Object.create(null);

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

    function isFilterPairCol(col) {{
      return col === FILTER1_COL || col === FILTER2_COL;
    }}

    function otherFilterPairCol(col) {{
      return col === FILTER1_COL ? FILTER2_COL : FILTER1_COL;
    }}

    function parseFilterCategoryValue(raw) {{
      const text = norm(raw);
      const idx = text.indexOf(': ');
      if (idx < 0) return {{ category: '', value: text }};
      return {{
        category: text.slice(0, idx),
        value: text.slice(idx + 2),
      }};
    }}

    function filterOptionDisplayLabel(raw) {{
      const text = norm(raw);
      if (!text) return fmt(text);
      const parsed = parseFilterCategoryValue(text);
      return parsed.value || text;
    }}

    function sortedFilterTabCategories(options) {{
      const cats = Array.from(new Set(
        options
          .map(v => parseFilterCategoryValue(v).category)
          .filter(Boolean),
      ));
      cats.sort((a, b) => {{
        const ia = Object.prototype.hasOwnProperty.call(FILTER_TAB_PRIORITY_MAP, a)
          ? FILTER_TAB_PRIORITY_MAP[a]
          : FILTER_TAB_PRIORITY.length;
        const ib = Object.prototype.hasOwnProperty.call(FILTER_TAB_PRIORITY_MAP, b)
          ? FILTER_TAB_PRIORITY_MAP[b]
          : FILTER_TAB_PRIORITY.length;
        return ia - ib || a.localeCompare(b);
      }});
      return cats;
    }}

    function resolveFilterTab(col, opts) {{
      const categories = sortedFilterTabCategories(opts);
      if (!categories.length) {{
        delete filterTabSelection[col];
        return '';
      }}
      const selected = norm(selection[col] ?? '');
      const selectedCategory = parseFilterCategoryValue(selected).category;
      let active = filterTabSelection[col] || '';
      if (selected && selectedCategory && categories.includes(selectedCategory)) {{
        active = selectedCategory;
      }}
      if (!categories.includes(active)) {{
        active = categories[0];
      }}
      filterTabSelection[col] = active;
      return active;
    }}

    function firstOptionInFilterTab(opts, category) {{
      if (!category) return '';
      for (const val of opts) {{
        const text = norm(val);
        if (!text) continue;
        if (parseFilterCategoryValue(text).category === category) {{
          return text;
        }}
      }}
      return '';
    }}

    function sortFilterPairValues(vals) {{
      vals.sort((a, b) => {{
        const ap = parseFilterCategoryValue(a);
        const bp = parseFilterCategoryValue(b);
        const aCategory = ap.category;
        const bCategory = bp.category;
        const ia = Object.prototype.hasOwnProperty.call(FILTER_TAB_PRIORITY_MAP, aCategory)
          ? FILTER_TAB_PRIORITY_MAP[aCategory]
          : FILTER_TAB_PRIORITY.length;
        const ib = Object.prototype.hasOwnProperty.call(FILTER_TAB_PRIORITY_MAP, bCategory)
          ? FILTER_TAB_PRIORITY_MAP[bCategory]
          : FILTER_TAB_PRIORITY.length;
        return ia - ib
          || aCategory.localeCompare(bCategory)
          || ap.value.localeCompare(bp.value);
      }});
    }}

    function filterCombosByPrior(priorCols) {{
      let subset = COMBOS;
      for (const p of priorCols) {{
        if (isFilterPairCol(p)) continue;
        const pPos = comboPos(p);
        subset = subset.filter(c => norm(c[pPos]) === norm(selection[p] ?? ''));
      }}

      const applyF1 = priorCols.includes(FILTER1_COL);
      const applyF2 = priorCols.includes(FILTER2_COL);
      if (!(applyF1 || applyF2)) {{
        return subset;
      }}

      const f1Sel = norm(selection[FILTER1_COL] ?? '');
      const f2Sel = norm(selection[FILTER2_COL] ?? '');
      const f1Pos = comboPos(FILTER1_COL);
      const f2Pos = comboPos(FILTER2_COL);
      return subset.filter(c => {{
        const f1 = norm(c[f1Pos]);
        const f2 = norm(c[f2Pos]);
        if (applyF1 && applyF2) {{
          return (f1 === f1Sel && f2 === f2Sel)
            || (f1 === f2Sel && f2 === f1Sel);
        }}
        if (applyF1) return f1 === f1Sel || f2 === f1Sel;
        return f1 === f2Sel || f2 === f2Sel;
      }});
    }}

    function filterPairValuesForCol(col, subset, priorCols) {{
      const selfPos = comboPos(col);
      const otherCol = otherFilterPairCol(col);
      const otherPos = comboPos(otherCol);
      const applyOther = priorCols.includes(otherCol);
      const otherSel = norm(selection[otherCol] ?? '');
      const vals = new Set();

      for (const combo of subset) {{
        const selfVal = norm(combo[selfPos]);
        const otherVal = norm(combo[otherPos]);
        if (applyOther) {{
          if (selfVal === otherSel) vals.add(otherVal);
          if (otherVal === otherSel) vals.add(selfVal);
        }} else {{
          vals.add(selfVal);
          vals.add(otherVal);
        }}
      }}

      const hasNone = vals.has('');
      vals.delete('');
      const ordered = Array.from(vals);
      sortFilterPairValues(ordered);
      if (hasNone) ordered.unshift('');
      return ordered;
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

    function keyFromFilterSelectionSwappedPair() {{
      return FILTER_COLS.map(c => {{
        if (c === FILTER1_COL) return norm(selection[FILTER2_COL]);
        if (c === FILTER2_COL) return norm(selection[FILTER1_COL]);
        return norm(selection[c]);
      }}).join(KEY_SEP);
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

    let suppressHistoryPush = false;

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
      const currentUrl = `${{window.location.pathname}}${{window.location.search}}${{window.location.hash}}`;
      if (newUrl === currentUrl) return;
      if (suppressHistoryPush) {{
        window.history.replaceState(null, '', newUrl);
      }} else {{
        window.history.pushState(null, '', newUrl);
      }}
    }}

    function optionsFor(col, priorCols) {{
      if (
        col === FILTER2_COL
        && priorCols.includes(FILTER1_COL)
        && norm(selection[FILTER1_COL] ?? '') === ''
      ) {{
        return [''];
      }}

      const subset = filterCombosByPrior(priorCols);
      let vals;
      if (isFilterPairCol(col)) {{
        vals = filterPairValuesForCol(col, subset, priorCols);
        return vals;
      }}

      const cPos = comboPos(col);
      vals = Array.from(new Set(subset.map(c => norm(c[cPos]))));
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

    function pickDefaultOptionForCol(col, opts) {{
      if (!opts.length) return '';
      // Prefer the empty option ("no filter" / "no grouping") whenever it
      // exists, so Filter 1, Filter 2, and Group By all start out unset
      // rather than defaulting to the first concrete value.
      if (opts.includes('')) return '';
      if (!isFilterPairCol(col)) return opts[0];

      const activeTab = resolveFilterTab(col, opts);
      const tabFirst = firstOptionInFilterTab(opts, activeTab);
      if (tabFirst) return tabFirst;
      return opts[0];
    }}

    function onFilterTabClick(col, category) {{
      const previousTab = filterTabSelection[col] || '';
      filterTabSelection[col] = category;
      const idx = FILTER_COLS.indexOf(col);
      const opts = optionsFor(col, FILTER_COLS.slice(0, idx));
      if (previousTab !== category) {{
        if (opts.includes('')) {{
          selection[col] = '';
        }} else {{
          const tabFirst = firstOptionInFilterTab(opts, category);
          selection[col] = tabFirst || (opts[0] || '');
        }}
      }} else if (!opts.includes(norm(selection[col] ?? ''))) {{
        const tabFirst = firstOptionInFilterTab(opts, category);
        selection[col] = opts.includes('') ? '' : (tabFirst || (opts[0] || ''));
      }}
      rebuildFilters(col);
    }}

    function rebuildFilters(changedCol) {{
      const startIdx = changedCol ? FILTER_COLS.indexOf(changedCol) : 0;
      for (let i = Math.max(0, startIdx); i < FILTER_COLS.length; i++) {{
        const col = FILTER_COLS[i];
        const prior = FILTER_COLS.slice(0, i);
        const opts = optionsFor(col, prior);
        if (!opts.includes(norm(selection[col] ?? ''))) {{
          selection[col] = pickDefaultOptionForCol(col, opts);
        }}
        if (isFilterPairCol(col)) {{
          resolveFilterTab(col, opts);
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
      const stickyCandidateLists = [];
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

        let shownOpts = opts;
        let hasFilterTabs = false;
        if (isFilterPairCol(col)) {{
          const categories = sortedFilterTabCategories(opts);
          const activeTab = resolveFilterTab(col, opts);
          if (categories.length) {{
            const tabs = document.createElement('div');
            tabs.className = 'filter-tabs';
            hasFilterTabs = true;
            categories.forEach(category => {{
              const tabBtn = document.createElement('button');
              tabBtn.type = 'button';
              tabBtn.className = 'filter-tab' + (category === activeTab ? ' active' : '');
              tabBtn.textContent = category;
              tabBtn.onclick = () => onFilterTabClick(col, category);
              tabs.appendChild(tabBtn);
            }});
            block.appendChild(tabs);
          }}
          shownOpts = opts.filter(v => {{
            const text = norm(v);
            if (!text) return true;
            if (!activeTab) return true;
            return parseFilterCategoryValue(text).category === activeTab;
          }});
        }}

        const list = document.createElement('div');
        list.className = 'filter-list';
        if (hasFilterTabs) {{
          list.classList.add('with-tabs');
        }}

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
          const visibleCount = Math.max(1, Math.min(shownOpts.length, 6));
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

        for (const val of shownOpts) {{
          const item = document.createElement('div');
          item.className = 'filter-item' + (norm(selection[col]) === val ? ' selected' : '');
          item.textContent = isFilterPairCol(col) ? filterOptionDisplayLabel(val) : fmt(val);
          item.onclick = () => {{
            selection[col] = val;
            rebuildFilters(col);
          }};
          list.appendChild(item);
        }}

        block.appendChild(list);
        host.appendChild(block);
        stickyCandidateLists.push(list);
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

      // Enable sticky pinning after final compaction so overflow detection is accurate.
      for (const list of stickyCandidateLists) {{
        const selectedItem = list.querySelector('.filter-item.selected');
        if (!selectedItem) continue;
        const hasOverflow = list.scrollHeight > list.clientHeight + 1;
        if (hasOverflow) {{
          selectedItem.classList.add('sticky-selected');
          list.prepend(selectedItem);
        }} else {{
          selectedItem.classList.remove('sticky-selected');
        }}
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
      let info = KEY_INFO.get(key) || null;
      if (!info && FILTER_COLS.includes(FILTER1_COL) && FILTER_COLS.includes(FILTER2_COL)) {{
        const swappedKey = keyFromFilterSelectionSwappedPair();
        if (swappedKey !== key) {{
          info = KEY_INFO.get(swappedKey) || null;
        }}
      }}
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
          selection[col] = pickDefaultOptionForCol(col, opts);
        }}
        if (isFilterPairCol(col)) {{
          resolveFilterTab(col, opts);
        }}
      }});

      suppressHistoryPush = true;
      try {{
        rebuildFilters();
      }} finally {{
        suppressHistoryPush = false;
      }}
    }}

    window.addEventListener('popstate', () => {{
      FILTER_COLS.forEach(col => {{ selection[col] = ''; }});
      loadStateFromUrl();
      suppressHistoryPush = true;
      try {{
        rebuildFilters();
      }} finally {{
        suppressHistoryPush = false;
      }}
    }});

    document.addEventListener('DOMContentLoaded', initPage);
  </script>

{data_scripts_html}
</body>
</html>
"""
