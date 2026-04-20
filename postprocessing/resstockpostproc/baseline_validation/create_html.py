"""Generate a standalone dashboard with single-select sidebar filters and an inline plot viewer.

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

from resstockpostproc.baseline_validation.create_html_viewer import (
    COMBINATIONS_FILENAME,
    NON_FILTER_COLUMNS,
    build_html,
)
from resstockpostproc.baseline_validation.dashboard_paths import (
    COMPARISONS_INDEX_DIRNAME,
    relative_href_from_file,
)
from resstockpostproc.baseline_validation.schema.plot_spec import ALL_ENDUSES_DISPLAY


_FILTER1_COLUMN = "Filter 1"
DATA_DIR_NAME = COMPARISONS_INDEX_DIRNAME
_JS_SUFFIX = "\n`);\n"


class IndexState:
  """Incremental index state for O(1) shard appends and streamed combinations."""

  def __init__(
      self,
      html_path: Path,
      headers: Sequence[str],
      data_dir: Path | None = None,
      data_dir_href: str | None = None,
  ):
    self.html_path = html_path
    headers_list = list(headers)
    if "Coverage" not in headers_list:
      insert_at = headers_list.index("Metric") + 1 if "Metric" in headers_list else len(headers_list)
      headers_list.insert(insert_at, "Coverage")
    self.headers = headers_list
    self.data_dir = data_dir or (html_path.parent / DATA_DIR_NAME)
    self.data_dir_href = data_dir_href or relative_href_from_file(self.data_dir, html_path)
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
    _is_recs = "RECS" in str(row.get("Comparison Dataset", "")).upper()
    row.setdefault("Coverage", "All Occupied Dwelling Units" if _is_recs else "All Dwelling Units")
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
        if r.get("Quantity") == "All Enduses":
            r["Quantity"] = ALL_ENDUSES_DISPLAY
        for col in ("Filter 1", "Filter 2", "Group By"):
            value = str(r.get(col, ""))
            if value == "Climate Zone":
                r[col] = "Building America Climate Zone"
            elif value.startswith("Climate Zone: "):
                r[col] = value.replace("Climate Zone: ", "Building America Climate Zone: ", 1)
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


def parse_viz_cell(cell_value: str) -> tuple[str, str | None]:
  """Parse 'viz_type||path' format into (display_text, url_or_traceback).

  Returns:
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


def _row_to_tsv_line(row: dict[str, str], headers: Sequence[str]) -> str:
    buf = io.StringIO()
    writer = csv.DictWriter(buf, fieldnames=headers, delimiter="\t", lineterminator="\n")
    writer.writerow(row)
    line = buf.getvalue()
    return line.replace("\\", "\\\\").replace("`", "\\`").replace("${", "\\${")


def create_html_from_rows(
    rows: list[dict[str, str]],
    headers: Sequence[str],
    html_path: Path,
    data_dir: Path | None = None,
) -> None:
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
        _is_recs = "RECS" in str(rr.get("Comparison Dataset", "")).upper()
        rr.setdefault("Coverage", "All Occupied Dwelling Units" if _is_recs else "All Dwelling Units")
        row_list.append(rr)

    html_path.parent.mkdir(parents=True, exist_ok=True)
    data_dir = data_dir or (html_path.parent / DATA_DIR_NAME)
    data_dir.mkdir(parents=True, exist_ok=True)
    data_dir_href = relative_href_from_file(data_dir, html_path)

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

    html_path.write_text(build_html(headers_list, manifest, data_dir_href), encoding="utf-8")
    print(f"HTML file created: {html_path} ({len(row_list)} rows, {len(manifest)} shards)")


def create_html_from_csv(csv_path: Path, html_path: Path, data_dir: Path | None = None) -> None:
    with open(csv_path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter="\t")
        headers = reader.fieldnames or []
        rows = list(reader)
    create_html_from_rows(rows, headers, html_path, data_dir=data_dir)


def init_html_index(
    html_path: Path,
    headers: Sequence[str],
    data_dir: Path | None = None,
) -> IndexState:
    """Initialize disk-backed index state for incremental row append."""
    html_path.parent.mkdir(parents=True, exist_ok=True)
    data_dir = data_dir or (html_path.parent / DATA_DIR_NAME)
    data_dir.mkdir(parents=True, exist_ok=True)

    state = IndexState(html_path=html_path, headers=headers, data_dir=data_dir)
    (data_dir / COMBINATIONS_FILENAME).write_text("", encoding="utf-8")
    state.open_combo_file()
    return state


def append_index_row(state: IndexState, row_dict: dict) -> None:
    """Append one row to disk shards/combinations in O(1)."""
    state.append_to_shard(row_dict)
    if state.needs_html_rewrite:
        _atomic_write(state.html_path, build_html(state.headers, state.manifest, state.data_dir_href))


def finalize_html_index(state: IndexState) -> None:
    """Close streams and write the final dashboard HTML."""
    state.close_combo_file()
    _atomic_write(state.html_path, build_html(state.headers, state.manifest, state.data_dir_href))


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
