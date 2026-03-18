"""Convert plot_index.csv to plot_index.html with interactive filtering.

This module provides two modes of operation:

1. **Incremental (used by plot_generator during a run):**
   - ``create_html_shell()`` writes a static HTML page whose JavaScript
     dynamically renders a table from CSV data embedded in a
     ``<script type="text/csv">`` block at the very end of the file.
   - ``append_html_row()`` performs an O(1) append of a single CSV row
     by seeking to the end of the embedded data and overwriting only the
     small constant HTML suffix.

2. **Batch (CLI / backward-compatible):**
   - ``create_html_from_csv()`` reads a finished CSV and produces the
     same HTML in one shot.

The CSV file is expected to have visualization columns in the format:
    - Success: "viz_type(relative/path/to/file.html)"
    - Failed: "FAILED: viz_type" or "FAILED: viz_type(traceback...)"
    - Empty: ""
"""

import csv
import io
import re
import sys
from pathlib import Path
from collections.abc import Sequence

# Visualization column names
VIZ_COLUMNS = ["Main Visualization", "Extra Visualization", "Data"]

# Constant HTML suffix that follows the embedded CSV data.
# append_html_row() overwrites this on every append.
_HTML_SUFFIX = "\n</script>\n</body>\n</html>\n"


def parse_viz_cell(cell_value: str) -> tuple[str, str | None]:
    """Parse 'viz_type(path)' format into (display_text, url_or_traceback) tuple.

    Args:
        cell_value: The cell content from CSV

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

    # Check for failed plot — may contain "FAILED: viz_type(traceback...)"
    if cell_value.startswith("FAILED:"):
        match = re.match(r"^FAILED:\s*.+?\((.+)\)$", cell_value, re.DOTALL)
        if match:
            traceback_text = match.group(1).strip()
            return ("FAILED", traceback_text)
        return ("FAILED", None)

    # Try to parse "viz_type(path)" format
    match = re.match(r"^(.+?)\((.+)\)$", cell_value)
    if match:
        viz_type = match.group(1).strip()
        path = match.group(2).strip()
        return (viz_type, path)

    # Fallback: treat as plain text (no link)
    return (cell_value, None)


# ---------------------------------------------------------------------------
# HTML shell (static page with JS-rendered table)
# ---------------------------------------------------------------------------


def _build_html_shell(headers: Sequence[str]) -> str:
    """Return the static HTML/CSS/JS portion of the page (everything before the CSV data)."""
    viz_columns_js = ", ".join(f"'{h}'" for h in VIZ_COLUMNS)

    # Build filter dropdowns for non-viz columns
    filter_html_parts: list[str] = []
    for col_idx, header in enumerate(headers):
        if header not in VIZ_COLUMNS:
            filter_html_parts.append(
                f"      <div class='filter-group'>\n"
                f"        <label for='filter-{col_idx}'>{header}</label>\n"
                f"        <select id='filter-{col_idx}' data-column='{col_idx}' onchange='applyFilters()'>\n"
                f"          <option value=''>All</option>\n"
                f"        </select>\n"
                f"      </div>"
            )
    filter_html = "\n".join(filter_html_parts)

    # Build <thead>
    th_cells = "\n".join(f"        <th>{h}</th>" for h in headers)

    return f"""<!DOCTYPE html>
<html>
<head>
  <meta charset='UTF-8'>
  <title>Plot Index</title>
  <style>
    body {{ font-family: Arial, sans-serif; margin: 20px; }}
    .controls {{ margin-bottom: 20px; }}
    .filter-row {{ display: flex; flex-wrap: wrap; gap: 10px; margin-bottom: 10px; }}
    .filter-group {{ display: flex; flex-direction: column; }}
    .filter-group label {{ font-size: 12px; font-weight: bold; margin-bottom: 3px; }}
    .filter-group select {{ padding: 5px; font-size: 13px; }}
    .stats {{ font-size: 14px; color: #666; margin-top: 10px; }}
    .reset-btn {{ padding: 8px 16px; background-color: #f44336; color: white; border: none; cursor: pointer; border-radius: 4px; }}
    .reset-btn:hover {{ background-color: #d32f2f; }}
    table {{ border-collapse: collapse; width: 100%; margin-top: 10px; }}
    th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; font-size: 13px; }}
    th {{ background-color: #D3D3D3; font-weight: bold; position: sticky; top: 0; }}
    tbody tr:nth-child(even) {{ background-color: #f9f9f9; }}
    tbody tr.hidden {{ display: none; }}
    a {{ color: blue; text-decoration: none; }}
    a:hover {{ text-decoration: underline; }}
    .failed {{ color: red; }}
    .failed a {{ color: red; cursor: pointer; }}
    .failed a:hover {{ text-decoration: underline; }}
  </style>
</head>
<body>
  <h1>Plot Index</h1>
  <div class='controls'>
    <div class='filter-row' id='filters'>
{filter_html}
    </div>
    <button class='reset-btn' onclick='resetFilters()'>Reset All Filters</button>
    <div class='stats' id='stats'></div>
  </div>
  <table id='plotTable'>
    <thead>
      <tr>
{th_cells}
      </tr>
    </thead>
    <tbody id='tbody'>
    </tbody>
  </table>
  <script>
    const VIZ_COLUMNS = [{viz_columns_js}];

    // ---- CSV parsing ----
    function parseCSV(text) {{
      // Simple RFC-4180-ish parser that handles quoted fields with embedded
      // commas, double-quotes, and newlines.
      const rows = [];
      let i = 0;
      while (i < text.length) {{
        const row = [];
        while (true) {{
          let field = '';
          if (text[i] === '"') {{
            // Quoted field
            i++; // skip opening quote
            while (i < text.length) {{
              if (text[i] === '"') {{
                if (text[i + 1] === '"') {{
                  field += '"';
                  i += 2;
                }} else {{
                  i++; // skip closing quote
                  break;
                }}
              }} else {{
                field += text[i];
                i++;
              }}
            }}
          }} else {{
            // Unquoted field
            while (i < text.length && text[i] !== ',' && text[i] !== '\\n' && text[i] !== '\\r') {{
              field += text[i];
              i++;
            }}
          }}
          row.push(field);
          if (i >= text.length || text[i] === '\\n' || text[i] === '\\r') {{
            // End of row — skip newline chars
            if (text[i] === '\\r') i++;
            if (text[i] === '\\n') i++;
            break;
          }}
          if (text[i] === ',') i++; // skip comma
        }}
        if (row.length > 1 || (row.length === 1 && row[0] !== '')) {{
          rows.push(row);
        }}
      }}
      return rows;
    }}

    // ---- Visualization cell rendering ----
    function parseVizCell(value) {{
      if (!value || !value.trim()) return ['', null];
      value = value.trim();
      if (value.startsWith('FAILED:')) {{
        const m = value.match(/^FAILED:\\s*.+?\\(([\\s\\S]+)\\)$/);
        if (m) return ['FAILED', m[1].trim()];
        return ['FAILED', null];
      }}
      const m = value.match(/^(.+?)\\((.+)\\)$/);
      if (m) return [m[1].trim(), m[2].trim()];
      return [value, null];
    }}

    function escapeHtml(s) {{
      const el = document.createElement('span');
      el.textContent = s;
      return el.innerHTML;
    }}

    function renderVizCell(value) {{
      const [display, url] = parseVizCell(value);
      if (display === 'FAILED' && url) {{
        const escaped = escapeHtml(url).replace(/"/g, '&quot;');
        return `<td class='failed'><a href='#' data-traceback="${{escaped}}" onclick='showTraceback(this); return false;'>FAILED</a></td>`;
      }}
      if (display === 'FAILED') return "<td class='failed'>FAILED</td>";
      if (url) return `<td><a href='${{url}}' target='_blank'>${{display}}</a></td>`;
      return '<td></td>';
    }}

    // ---- Table rendering ----
    function renderTable() {{
      const raw = document.getElementById('csvdata').textContent;
      const allRows = parseCSV(raw);
      if (allRows.length < 2) return; // header only
      const headers = allRows[0];
      const tbody = document.getElementById('tbody');
      const vizSet = new Set(VIZ_COLUMNS);
      const frag = document.createDocumentFragment();

      for (let r = 1; r < allRows.length; r++) {{
        const tr = document.createElement('tr');
        for (let c = 0; c < headers.length; c++) {{
          const val = allRows[r][c] || '';
          if (vizSet.has(headers[c])) {{
            // Use innerHTML for viz cells (they contain links)
            const tmp = document.createElement('template');
            tmp.innerHTML = renderVizCell(val);
            tr.appendChild(tmp.content.firstChild);
          }} else {{
            const td = document.createElement('td');
            td.textContent = val;
            tr.appendChild(td);
          }}
        }}
        frag.appendChild(tr);
      }}
      tbody.appendChild(frag);
    }}

    // ---- Traceback popup ----
    function showTraceback(el) {{
      const tb = el.dataset.traceback;
      const w = window.open('', '_blank');
      w.document.write('<html><head><title>Plot Traceback</title></head>');
      w.document.write('<body style="font-family:monospace;padding:20px;background:#1e1e1e;color:#d4d4d4">');
      w.document.write('<h2 style="color:#f44336">Plot Generation Traceback</h2>');
      const pre = w.document.createElement('pre');
      pre.style.whiteSpace = 'pre-wrap';
      pre.style.wordWrap = 'break-word';
      pre.textContent = tb;
      w.document.body.appendChild(pre);
      w.document.write('</body></html>');
      w.document.close();
    }}

    // ---- Filters ----
    function populateFilters() {{
      const table = document.getElementById('plotTable');
      const rows = table.querySelectorAll('tbody tr');
      const filters = document.querySelectorAll('[data-column]');
      filters.forEach(filter => {{
        const colIdx = parseInt(filter.dataset.column);
        const values = new Set();
        rows.forEach(row => {{
          const cell = row.cells[colIdx];
          if (cell) {{
            const text = cell.textContent.trim();
            if (text && text !== 'FAILED' && !text.startsWith('FAILED:')) values.add(text);
          }}
        }});
        Array.from(values).sort().forEach(value => {{
          const option = document.createElement('option');
          option.value = value;
          option.textContent = value;
          filter.appendChild(option);
        }});
      }});
      updateStats();
    }}

    function applyFilters() {{
      const table = document.getElementById('plotTable');
      const rows = table.querySelectorAll('tbody tr');
      const filters = document.querySelectorAll('[data-column]');
      const activeFilters = {{}};
      filters.forEach(f => {{ if (f.value) activeFilters[f.dataset.column] = f.value; }});
      rows.forEach(row => {{
        let show = true;
        for (const [colIdx, fv] of Object.entries(activeFilters)) {{
          const cell = row.cells[parseInt(colIdx)];
          if (cell && cell.textContent.trim() !== fv) {{ show = false; break; }}
        }}
        row.classList.toggle('hidden', !show);
      }});
      updateStats();
    }}

    function resetFilters() {{
      document.querySelectorAll('[data-column]').forEach(f => f.value = '');
      applyFilters();
    }}

    function updateStats() {{
      const table = document.getElementById('plotTable');
      const rows = table.querySelectorAll('tbody tr');
      const visibleRows = table.querySelectorAll('tbody tr:not(.hidden)');
      document.getElementById('stats').textContent = `Showing ${{visibleRows.length}} of ${{rows.length}} rows`;
    }}

    // ---- Init ----
    function initPage() {{
      renderTable();
      populateFilters();
      const filters = document.querySelectorAll('[data-column]');
      const highlightFilter = filters[0];
      if (highlightFilter) {{
        highlightFilter.value = 'Yes';
        applyFilters();
      }}
    }}
    document.addEventListener('DOMContentLoaded', initPage);
  </script>
  <script id="csvdata" type="text/csv">
"""


def create_html_shell(html_path: Path, headers: Sequence[str]) -> int:
    """Write the HTML shell and return the byte size of the constant suffix.

    The file ends with a ``<script id="csvdata" type="text/csv">`` block
    containing just the CSV header row, followed by ``_HTML_SUFFIX``.

    Args:
        html_path: Where to write the HTML file.
        headers: Column names (used for both ``<thead>`` and the embedded CSV header row).

    Returns:
        The byte length of ``_HTML_SUFFIX`` (callers need this for ``append_html_row``).
    """
    html_path.parent.mkdir(parents=True, exist_ok=True)
    shell = _build_html_shell(headers)

    # Build CSV header line
    buf = io.StringIO()
    writer = csv.writer(buf)
    writer.writerow(headers)
    csv_header_line = buf.getvalue()  # includes trailing \n

    content = shell + csv_header_line + _HTML_SUFFIX
    html_path.write_text(content, encoding="utf-8")

    return len(_HTML_SUFFIX.encode("utf-8"))


def append_html_row(html_path: Path, row_dict: dict, headers: Sequence[str], suffix_size: int) -> None:
    """Append a single CSV row to the embedded data block in O(1) time.

    Seeks to ``file_size - suffix_size``, writes the new CSV row,
    then rewrites the constant HTML suffix.

    Args:
        html_path: Path to the HTML file created by ``create_html_shell``.
        row_dict: Dict mapping column names to values (same keys as *headers*).
        headers: Column names in order.
        suffix_size: Byte length of ``_HTML_SUFFIX`` (returned by ``create_html_shell``).
    """
    # Serialize the row as one CSV line
    buf = io.StringIO()
    writer = csv.DictWriter(buf, fieldnames=headers)
    writer.writerow(row_dict)
    csv_line = buf.getvalue()  # includes trailing \n

    with open(html_path, "r+b") as f:
        # Seek to just before the suffix
        f.seek(-suffix_size, 2)  # 2 = SEEK_END
        f.write(csv_line.encode("utf-8"))
        f.write(_HTML_SUFFIX.encode("utf-8"))


# ---------------------------------------------------------------------------
# Backward-compatible batch interface
# ---------------------------------------------------------------------------


def create_html_from_csv(csv_path: Path, html_path: Path) -> None:
    """Convert plot_index.csv to plot_index.html with interactive filtering.

    This is the batch/CLI interface.  It reads the entire CSV and produces
    the full HTML in one shot by writing the shell and appending every row.

    Args:
        csv_path: Path to the input CSV file
        html_path: Path to write the output HTML file
    """
    with open(csv_path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        headers = reader.fieldnames
        if not headers:
            html_path.write_text("<html><body><p>Empty CSV file</p></body></html>")
            return
        rows = list(reader)

    if not rows:
        html_path.write_text("<html><body><p>No data rows in CSV</p></body></html>")
        return

    suffix_size = create_html_shell(html_path, headers)
    for row in rows:
        append_html_row(html_path, row, headers, suffix_size)

    print(f"HTML file created: {html_path} ({len(rows)} rows)")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python create_html.py <input.csv> <output.html>")
        print("Example: python create_html.py plot_index.csv plot_index.html")
        sys.exit(1)

    csv_path = Path(sys.argv[1])
    html_path = Path(sys.argv[2])

    if not csv_path.exists():
        print(f"Error: Input file not found: {csv_path}")
        sys.exit(1)

    create_html_from_csv(csv_path, html_path)
