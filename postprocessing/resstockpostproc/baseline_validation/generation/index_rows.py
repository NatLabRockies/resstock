"""Dashboard index row assembly for baseline validation.

Extracted from plot_generator.py in refactor plan V2 step 3.3. These helpers
build the per-plot row dict that the dashboard index consumes, including
dataset-specific facet normalization.
"""

from __future__ import annotations

from resstockpostproc.baseline_validation.schema.plot_spec import (
    ComparisonDataset,
    PlotSpec,
    Resolution,
)


def build_output_row(main_spec: PlotSpec) -> dict[str, str]:
    """Build the output row dict from a main PlotSpec's display properties."""
    return {
        "Index": "",
        "Comparison Dataset": main_spec.display_comparison_dataset,
        "Quantity": main_spec.display_quantity,
        "Metric": main_spec.display_metric,
        "Coverage": main_spec.display_coverage,
        "Filter 1": "",
        "Filter 2": "",
        "Group By": main_spec.display_group_by,
        "Comparison Plot": "",
        "Data": "",
    }


def apply_lrd_sidebar_semantics(
    row: dict[str, str],
    display_spec: PlotSpec,
    final_focus_on: tuple[tuple[str, str], ...],
) -> None:
    """Normalize LRD index facets to the simplified Metric/Filter/Group By model."""
    if display_spec.comparison_dataset != ComparisonDataset.lrd:
        return

    # Default LRD sidebar facets are utility-grouped with no explicit filters.
    row["Filter 1"] = ""
    row["Filter 2"] = ""
    row["Group By"] = "Utility"

    if display_spec.resolution == Resolution.hour_of_day_summer:
        row["Filter 1"] = "Season: Summer"
    elif display_spec.resolution == Resolution.hour_of_day_winter:
        row["Filter 1"] = "Season: Winter"
    elif display_spec.resolution == Resolution.hour_of_day_matrix:
        utility = next((val for char, val in final_focus_on if char == "utility"), "")
        row["Filter 1"] = f"Utility: {utility}" if utility else ""
        row["Group By"] = "Month-Day"
