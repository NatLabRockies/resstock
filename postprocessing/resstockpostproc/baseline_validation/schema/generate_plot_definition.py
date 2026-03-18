#!/usr/bin/env python3
"""Generate plot_definition.tsv — the master list of baseline-validation plots.

    python generate_plot_definition.py

Writes plot_definition.tsv next to this script.
"""

import csv
from collections import Counter
from pathlib import Path

COLUMNS = [
    "Index",
    "Highlight",
    "Truth Source",
    "Quantity",
    "Metric",
    "Coverage",
    "Group By",
    "Main Visualization",
    "Extra Visualization",
    "Test",
]

EIA_QUANTITIES = [
    "Number of dwelling units",
    "Electricity Total",
    "Natural Gas Total",
]

RECS_QUANTITIES = [
    "Number of dwelling units",
    "All Enduses",
    "Electricity Total",
    "Natural Gas Total",
    "Electricity Space Cooling",
    "Electricity Space Heating",
    "Electricity Water Heating",
    "Natural Gas Space Heating",
    "Natural Gas Water Heating",
    "Electricity Plug Load",
    "Electricity Refrigerator",
    "Electricity Lighting",
    "Electricity Television",
    "Electricity Clothes Dryer",
    "Electricity Cooling Fan Pumps",
    "Electricity Heating Fans Pumps",
    "Electricity Freezer",
    "Electricity Cooking",
    "Electricity Pool Pumps",
    "Electricity Ceiling Fan",
    "Electricity Dishwasher",
    "Electricity Clothes Washer",
    "Electricity Pool Heater",
    "Electricity EV Charging",
    "Natural Gas Cooking",
    "Natural Gas Pool Heater",
    "Natural Gas Clothes Dryer",
    "Propane Total",
    "Propane Space Heating",
    "Propane Water Heating",
    "Propane Cooking",
    "Propane Clothes Dryer",
    "Fuel Oil Total",
    "Fuel Oil Space Heating",
    "Fuel Oil Water Heating",
]

LRD_QUANTITIES = ["Electricity Total"]

EIA_GROUP_BYS = ["state"]

RECS_GROUP_BYS = [
    "state",
    "census division recs",
    "geometry building type recs",
    "vintage",
    "building america climate zone",
    "heating fuel",
]

LRD_GROUP_BYS = ["utility"]

ENERGY_METRICS = [
    "total annual consumption",
    "average annual consumption",
    "total monthly consumption",
    "average monthly consumption",
]

LRD_METRICS = [
    "average annual consumption",
    "average monthly consumption",
    "average daily consumption",
    "average hourly consumption",
    "average hourly consumption (summer)",
    "average hourly consumption (winter)",
    "average hourly consumption (matrix)",
    "average hourly consumption (8760)",
    "average hourly consumption (top 100 hours)",
]

EIA_COVERAGE = "all units"
EIA_USERS = "units with non-zero consumption"
LRD_COVERAGE = "all units"
RECS_ALL = "all occupied units"
RECS_USERS = "occupied units with non-zero consumption"

# Quantities with monthly resolution in RECS
RECS_MONTHLY_QUANTITIES = {
    "Electricity Total",
    "Natural Gas Total",
    "Electricity Space Cooling",
    "Electricity Space Heating",
    "Electricity Water Heating",
    "Natural Gas Space Heating",
    "Natural Gas Water Heating",
}

# 100% penetration — users-only coverage and penetration rows are meaningless
RECS_FULL_PENETRATION = {"Electricity Total"}

# Quantities highlighted on RECS monthly + state rows
RECS_HIGHLIGHT_MONTHLY = {
    "Electricity Total",
    "Natural Gas Total",
    "Electricity Space Cooling",
    "Electricity Space Heating",
    "Electricity Water Heating",
    "Natural Gas Space Heating",
    "Natural Gas Water Heating",
}


def _path_signature(truth_source, quantity, metric, coverage, group_by):
    """Compute code-path signature — rows with the same signature exercise the same pipeline path.

    Two rows with the same signature traverse identical code paths through the
    plotting pipeline (plotter selection, config resolution, rendering dispatch).
    They differ only in the data flowing through.
    """
    if quantity == "Number of dwelling units":
        qty_type = "units_count"
    elif quantity == "All Enduses":
        qty_type = "all_enduses"
    else:
        qty_type = "regular"

    if group_by == "state":
        gb_type = "state"
    elif group_by == "utility":
        gb_type = "utility"
    else:
        gb_type = "other"

    cov_type = "all" if coverage in (EIA_COVERAGE, LRD_COVERAGE, RECS_ALL) else "users"

    return (truth_source, metric, cov_type, gb_type, qty_type)


def is_highlight(truth_source, quantity, group_by, metric):
    if truth_source == "eia" and quantity == "Number of dwelling units" and group_by == "state":
        return True
    if truth_source == "recs" and quantity == "Number of dwelling units" and group_by in ("state", "vintage"):
        return True
    if truth_source == "recs" and quantity == "All Enduses" and "annual" in metric:
        return True
    if truth_source == "eia" and quantity in ("Electricity Total", "Natural Gas Total") and group_by == "state" and "monthly" in metric:
        return True
    if truth_source == "recs" and quantity in RECS_HIGHLIGHT_MONTHLY and group_by == "state" and "monthly" in metric:
        return True
    if truth_source == "lrd" and metric in ("average monthly consumption", "average daily consumption", "average hourly consumption (8760)"):
        return True
    if truth_source == "lrd" and metric == "hourly consumption vs temperature":
        return True
    return False


def get_viz(truth_source, group_by, metric, quantity):
    """Return (main_visualization, extra_visualization)."""
    if quantity == "All Enduses":
        return "grouped bar plot", "difference view"

    if truth_source == "lrd":
        if "annual" in metric:
            return "tilemap bar plot", "difference view"
        if "monthly" in metric:
            return "tilemap timeseries", ""
        if "daily" in metric:
            return "stack of timeseries", ""
        if "(matrix)" in metric:
            return "daily load shape matrix", ""
        if "(summer)" in metric or "(winter)" in metric:
            return "daily load shape", ""
        if "(8760)" in metric:
            return "load duration curve", ""
        if "(top 100" in metric:
            return "load duration curve", ""
        if "hourly" in metric:
            return "daily load shape", ""

    if group_by in ("state", "utility"):
        if "annual" in metric or metric == "":
            return "tilemap bar plot", "difference view"
        if "monthly" in metric:
            return "tilemap timeseries", ""

    return "grouped bar plot", "difference view"


def make_row(truth_source, quantity, metric, coverage, group_by, main_viz, extra_viz=""):
    highlight = "Yes" if is_highlight(truth_source, quantity, group_by, metric) else ""
    return {
        "Highlight": highlight,
        "Truth Source": truth_source,
        "Quantity": quantity,
        "Metric": metric,
        "Coverage": coverage,
        "Group By": group_by,
        "Main Visualization": main_viz,
        "Extra Visualization": extra_viz,
    }


def generate_eia_rows():
    rows = []
    for quantity in EIA_QUANTITIES:
        if quantity == "Number of dwelling units":
            for gb in EIA_GROUP_BYS:
                mv, ev = get_viz("eia", gb, "", quantity)
                rows.append(make_row("eia", quantity, "", EIA_COVERAGE, gb, mv, ev))
            continue

        for gb in EIA_GROUP_BYS:
            for metric in ENERGY_METRICS:
                mv, ev = get_viz("eia", gb, metric, quantity)
                rows.append(make_row("eia", quantity, metric, EIA_COVERAGE, gb, mv, ev))

            if quantity == "Natural Gas Total":
                for avg_m in ("average annual consumption", "average monthly consumption"):
                    mv, ev = get_viz("eia", gb, avg_m, quantity)
                    rows.append(make_row("eia", quantity, avg_m, EIA_USERS, gb, mv, ev))
                rows.append(make_row("eia", quantity, "enduse penetration", EIA_COVERAGE, gb, "grouped bar plot"))

    return rows


def generate_recs_rows():
    rows = []
    for quantity in RECS_QUANTITIES:
        if quantity == "Number of dwelling units":
            for gb in RECS_GROUP_BYS:
                mv, ev = get_viz("recs", gb, "", quantity)
                rows.append(make_row("recs", quantity, "", RECS_ALL, gb, mv, ev))

        elif quantity == "All Enduses":
            for gb in RECS_GROUP_BYS:
                _emit_all_enduses(rows, gb)

        else:
            _emit_recs_energy(rows, quantity)

    return rows


def _emit_all_enduses(rows, group_by):
    """Emit the 6 All Enduses rows for one group_by."""
    bar = "grouped bar plot"
    box = "grouped box plot"
    diff = "difference view"
    rows.append(make_row("recs", "All Enduses", "total annual consumption", RECS_ALL, group_by, bar, diff))
    rows.append(make_row("recs", "All Enduses", "average annual consumption", RECS_ALL, group_by, bar, diff))
    rows.append(make_row("recs", "All Enduses", "average annual consumption", RECS_USERS, group_by, bar, diff))
    rows.append(make_row("recs", "All Enduses", "annual consumption distribution", RECS_ALL, group_by, box))
    rows.append(make_row("recs", "All Enduses", "annual consumption distribution", RECS_USERS, group_by, box))
    rows.append(make_row("recs", "All Enduses", "enduse penetration", RECS_ALL, group_by, bar))

def _emit_recs_energy(rows, quantity):
    """Emit all rows for one RECS energy quantity across all group_bys."""
    has_monthly = quantity in RECS_MONTHLY_QUANTITIES
    skip_users = quantity in RECS_FULL_PENETRATION

    for gb in RECS_GROUP_BYS:
        resolutions = ["annual", "monthly"] if (gb == "state" and has_monthly) else ["annual"]

        for res in resolutions:
            total_m = f"total {res} consumption"
            avg_m = f"average {res} consumption"

            mv, ev = get_viz("recs", gb, total_m, quantity)
            rows.append(make_row("recs", quantity, total_m, RECS_ALL, gb, mv, ev))

            mv, ev = get_viz("recs", gb, avg_m, quantity)
            rows.append(make_row("recs", quantity, avg_m, RECS_ALL, gb, mv, ev))
            if not skip_users:
                rows.append(make_row("recs", quantity, avg_m, RECS_USERS, gb, mv, ev))

        rows.append(make_row("recs", quantity, "annual consumption distribution", RECS_ALL, gb, "grouped box plot"))
        if not skip_users:
            rows.append(make_row("recs", quantity, "annual consumption distribution", RECS_USERS, gb, "grouped box plot"))
            rows.append(make_row("recs", quantity, "enduse penetration", RECS_ALL, gb, "grouped bar plot"))


def generate_lrd_rows():
    rows = []
    for quantity in LRD_QUANTITIES:
        for gb in LRD_GROUP_BYS:
            for metric in LRD_METRICS:
                mv, ev = get_viz("lrd", gb, metric, quantity)
                rows.append(make_row("lrd", quantity, metric, LRD_COVERAGE, gb, mv, ev))

                if metric == "average hourly consumption (8760)":
                    rows.append(make_row(
                        "lrd", quantity, "hourly consumption vs temperature",
                        LRD_COVERAGE, gb, "temperature relation", "temperature count",
                    ))
    return rows


def main():
    rows = generate_eia_rows() + generate_recs_rows() + generate_lrd_rows()

    for i, row in enumerate(rows, start=1):
        row["Index"] = i

    # Mark minimal test subset: first row for each unique code-path signature
    seen_signatures = set()
    for row in rows:
        sig = _path_signature(
            row["Truth Source"], row["Quantity"], row["Metric"],
            row["Coverage"], row["Group By"],
        )
        if sig not in seen_signatures:
            row["Test"] = "Yes"
            seen_signatures.add(sig)
        else:
            row["Test"] = ""

    file_comments = [
        "# Created by: generate_plot_definition.py",
        "#",
        "# Highlight: 'Yes' marks key summary plots to feature prominently.",
        "# Truth Source: External data source to compare against."
        " Values: eia (EIA state-level), recs (RECS survey), lrd (utility load research).",
        "# Quantity: What to plot. 'Number of dwelling units' = housing stock count."
        " 'All Enduses' = all fuel/enduse combos together. Others = specific fuel+enduse.",
        "# Metric: How consumption is aggregated."
        " 'total annual consumption' = stock-wide yearly sum."
        " 'average monthly consumption' = per-unit monthly mean."
        " 'annual consumption distribution' = per-unit quartile box plots."
        " 'enduse penetration' = % of units with non-zero consumption."
        " LRD adds: 'average daily consumption', 'average hourly consumption (8760)',"
        " 'hourly consumption vs temperature', etc.",
        "# Coverage: Population scope."
        " 'all units'/'all occupied units' = every unit."
        " 'units with non-zero consumption'/'occupied units with non-zero consumption'"
        " = only units that use that fuel.",
        "# Group By: Grouping dimension."
        " 'state'/'utility' produce tilemap layouts."
        " Others (census division recs, vintage, heating fuel, etc.) produce grouped bar charts.",
        "# Main Visualization: Primary chart type."
        " tilemap bar plot, tilemap timeseries, grouped bar plot, grouped box plot,"
        " stack of timeseries, daily load shape, daily load shape matrix,"
        " load duration curve, temperature relation.",
        "# Extra Visualization: Secondary chart alongside the main one."
        " 'difference view' = percent difference vs truth source."
        " 'temperature count' = temperature observation distribution."
        " Blank = no extra visualization.",
        "# Test: 'Yes' marks one row per unique code-path signature."
        " Use --test in plot_generator.py to generate only these rows.",
    ]

    output_path = Path(__file__).parent / "plot_definition.tsv"
    with open(output_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=COLUMNS, delimiter="\t")
        writer.writeheader()
        writer.writerows(rows)
        f.write("\n")
        for line in file_comments:
            f.write(line + "\n")

    print(f"Written {len(rows)} rows to {output_path.name}")
    by_source = Counter(r["Truth Source"] for r in rows)
    for s in ["eia", "recs", "lrd"]:
        print(f"  {s}: {by_source[s]} rows")
    print(f"  Highlighted: {sum(1 for r in rows if r['Highlight'] == 'Yes')}")
    print(f"  Test subset: {sum(1 for r in rows if r['Test'] == 'Yes')}")
    print(f"  Unique quantities: {len(set(r['Quantity'] for r in rows))}")


if __name__ == "__main__":
    main()
