"""Focused tests for Filter 1/Filter 2 tab + swap behavior in generated HTML."""

from pathlib import Path

from resstockpostproc.baseline_validation.dashboard_paths import (
    comparisons_index_data_dir,
    dashboard_html_path,
)
from resstockpostproc.baseline_validation.create_html import create_html_from_rows


def _generate_html(tmp_path: Path) -> str:
    headers = [
        "Index",
        "Comparison Dataset",
        "Quantity",
        "Metric",
        "Coverage",
        "Filter 1",
        "Filter 2",
        "Group By",
        "Comparison Plot",
        "Data",
    ]
    rows = [
        {
            "Index": "1",
            "Comparison Dataset": "RECS 2020",
            "Quantity": "All Enduses",
            "Metric": "Total Annual Consumption",
            "Coverage": "All Occupied Dwelling Units",
            "Filter 1": "State: Colorado",
            "Filter 2": "Building Type: Single-Family Detached",
            "Group By": "",
            "Comparison Plot": "bar plot||dashboard_data/recs plots (html)/example_a.html",
            "Data": "",
        },
        {
            "Index": "2",
            "Comparison Dataset": "RECS 2020",
            "Quantity": "All Enduses",
            "Metric": "Total Annual Consumption",
            "Coverage": "All Occupied Dwelling Units",
            "Filter 1": "Census Division: Mountain",
            "Filter 2": "Building Type: Single-Family Detached",
            "Group By": "",
            "Comparison Plot": "bar plot||dashboard_data/recs plots (html)/example_b.html",
            "Data": "",
        },
        {
            "Index": "3",
            "Comparison Dataset": "LRD 2018",
            "Quantity": "Electricity",
            "Metric": "Total Annual Consumption",
            "Coverage": "All Dwelling Units",
            "Filter 1": "Utility: Example Utility",
            "Filter 2": "",
            "Group By": "Month-Day",
            "Comparison Plot": "line plot||dashboard_data/lrd plots (html)/example_c.html",
            "Data": "",
        },
    ]

    html_path = dashboard_html_path(tmp_path)
    create_html_from_rows(rows, headers, html_path, data_dir=comparisons_index_data_dir(tmp_path))
    return html_path.read_text(encoding="utf-8")


def test_filter_pair_tabs_and_value_only_hooks_present(tmp_path):
    html = _generate_html(tmp_path)
    assert "const FILTER_TAB_PRIORITY = ['Building Type', 'Census Division', 'State'];" in html
    assert "function sortedFilterTabCategories(options)" in html
    assert "function parseFilterCategoryValue(raw)" in html
    assert "function filterOptionDisplayLabel(raw)" in html
    assert "item.textContent = isFilterPairCol(col) ? filterOptionDisplayLabel(val) : fmt(val);" in html
    assert "overflow: hidden;" in html
    assert "flex-wrap: wrap;" in html
    assert "border-bottom: 1px solid #bbb;" in html
    assert "background: #d2e3fc;" in html
    assert "border-bottom-color: #d2e3fc;" in html
    assert "if (previousTab !== category) {" in html
    assert "if (opts.includes('')) {" in html
    assert "selection[col] = '';" in html


def test_filter_pair_swap_logic_present_in_options(tmp_path):
    html = _generate_html(tmp_path)
    assert "function filterCombosByPrior(priorCols)" in html
    assert "function filterPairValuesForCol(col, subset, priorCols)" in html
    assert "if (isFilterPairCol(col)) {" in html
    assert "vals = filterPairValuesForCol(col, subset, priorCols);" in html
    assert "col === FILTER2_COL" in html
    assert "norm(selection[FILTER1_COL] ?? '') === ''" in html
    assert "return [''];" in html
    assert "const stickyCandidateLists = [];" in html
    assert "for (const list of stickyCandidateLists) {" in html


def test_filter_pair_swapped_lookup_fallback_present(tmp_path):
    html = _generate_html(tmp_path)
    assert "function keyFromFilterSelectionSwappedPair()" in html
    assert "if (!info && FILTER_COLS.includes(FILTER1_COL) && FILTER_COLS.includes(FILTER2_COL)) {" in html
    assert "const swappedKey = keyFromFilterSelectionSwappedPair();" in html


def test_normalizes_display_labels_in_index_rows(tmp_path):
    headers = [
        "Index",
        "Comparison Dataset",
        "Quantity",
        "Metric",
        "Coverage",
        "Filter 1",
        "Filter 2",
        "Group By",
        "Comparison Plot",
        "Data",
    ]
    rows = [
        {
            "Index": "1",
            "Comparison Dataset": "RECS 2020",
            "Quantity": "All Enduses",
            "Metric": "Average Annual Consumption",
            "Coverage": "All Occupied Dwelling Units",
            "Filter 1": "Climate Zone: Mixed-Humid",
            "Filter 2": "",
            "Group By": "Climate Zone",
            "Comparison Plot": "bar plot||dashboard_data/recs plots (html)/example.html",
            "Data": "",
        }
    ]

    html_path = dashboard_html_path(tmp_path)
    create_html_from_rows(rows, headers, html_path, data_dir=comparisons_index_data_dir(tmp_path))
    html = html_path.read_text(encoding="utf-8")

    assert "All Fuels and Enduses" in html
    assert "Building America Climate Zone" in html
