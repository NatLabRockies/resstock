"""Column presentation helpers for baseline validation data tables.

Owns the mapping from raw DataFrame column names to the user-facing column
config consumed by the HTML table renderer.
"""

from __future__ import annotations

import polars as pl

from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    format_group_by,
)
from resstockpostproc.baseline_validation.plotters.plot_config import (
    get_second_category_column,
    get_second_category_title,
)
from resstockpostproc.baseline_validation.plot_helpers.plot_semantics import (
    resolve_quantity_title,
    resolve_timeseries_column,
)


_QUARTILE_SUFFIX_LABELS = {
    "_min": "Min",
    "_q1": "Q1",
    "_median": "Median",
    "_q3": "Q3",
    "_max": "Max",
}


def _humanize_column(
    raw_name: str,
    source_prefix: str,
    units: str,
    is_distribution: bool = False,
    model_count_label: str | None = None,
) -> str:
    """Convert a raw column name like 'electricity_total_value' into a human-readable header.

    When ``is_distribution`` is True, ``_value`` columns are labeled "Average"
    so they sit naturally alongside the Min/Q1/Median/Q3/Max quartile columns.
    """
    if raw_name == "units_count":
        return f"{source_prefix}: Dwelling Units"
    if raw_name == "model_count":
        label = model_count_label or "Model Count"
        return f"{source_prefix}: {label}"
    if raw_name == "temp_count":
        return f"{source_prefix}: Hour Count"
    if "percent_users" in raw_name and "percent_difference" not in raw_name:
        return f"{source_prefix}: % Users"
    if raw_name.endswith("_value"):
        if is_distribution:
            return f"{source_prefix}: Average ({units})"
        return f"{source_prefix} ({units})"
    for suffix, label in _QUARTILE_SUFFIX_LABELS.items():
        if raw_name.endswith(suffix):
            return f"{source_prefix}: {label} ({units})"

    # Fallback: clean up the raw name
    clean = raw_name.replace("_", " ").title()
    return f"{source_prefix}: {clean}"


def build_column_config(
    data: pl.DataFrame,
    plot_spec: PlotSpec,
    ref_label: str,
    rs_labels: list[str],
) -> list[dict]:
    """Build column metadata for the HTML table (header labels, formats, types)."""
    columns = data.columns
    units = resolve_quantity_title(plot_spec)
    entity_col = get_second_category_column(plot_spec)
    if entity_col == "month_daytype":
        # hour_of_day_matrix: entity column carries month_daytype strings,
        # so its header should match the plotter's second-category title.
        entity_label = get_second_category_title(plot_spec)
    else:
        agg = plot_spec.group_by or plot_spec.effective_group_by[-1]
        entity_label = format_group_by(agg)

    ts_col = resolve_timeseries_column(plot_spec)

    abs_diff_units = "percentage points" if units == "%" else units
    is_distribution = plot_spec.is_distribution_metric

    config = []
    for col in columns:
        # Dimension columns
        if col == entity_col:
            config.append({"key": col, "label": entity_label, "type": "string", "format": ""})
            continue

        if ts_col and col == str(ts_col):
            if col == "resstock_temp":
                label = "Temperature (°F)"
            else:
                label = col.replace("_", " ").title() if "_" in col else col.title()
            # Numeric ts columns (e.g. resstock_temp, hour of day) need "number"
            # type so client-side sorting compares values as numbers, not strings.
            col_type = "number" if data[col].dtype.is_numeric() else "string"
            col_format = ",.0f" if col_type == "number" else ""
            config.append({"key": col, "label": label, "type": col_type, "format": col_format})
            continue

        if col == "enduse":
            config.append({"key": col, "label": "End Use", "type": "string", "format": ""})
            continue

        # Per-source ResStock columns
        matched = False
        for rs_label in rs_labels:
            abs_diff_prefix = f"{rs_label} Difference ({abs_diff_units}): "
            pct_diff_prefix = f"{rs_label} Difference (%): "
            value_prefix = f"{rs_label}: "
            if col.startswith(abs_diff_prefix):
                config.append(
                    {
                        "key": col,
                        "label": f"{rs_label} Difference ({abs_diff_units})",
                        "type": "abs_diff",
                        "format": "+,.1f",
                    }
                )
                matched = True
                break
            if col.startswith(pct_diff_prefix):
                config.append(
                    {
                        "key": col,
                        "label": f"{rs_label} Difference (%)",
                        "type": "diff",
                        "format": "+.1f%",
                    }
                )
                matched = True
                break
            if col.startswith(value_prefix):
                raw_name = col[len(value_prefix) :]
                config.append(
                    {
                        "key": col,
                        "label": _humanize_column(
                            raw_name,
                            rs_label,
                            units,
                            is_distribution,
                            plot_spec.model_count_display_label_for_source(rs_label),
                        ),
                        "type": "number",
                        "format": ",.1f",
                    }
                )
                matched = True
                break
        if matched:
            continue

        # Reference columns
        if col.startswith(f"{ref_label}: "):
            raw_name = col[len(f"{ref_label}: ") :]
            config.append(
                {
                    "key": col,
                    "label": _humanize_column(
                        raw_name,
                        ref_label,
                        units,
                        is_distribution,
                        plot_spec.model_count_display_label_for_source(ref_label),
                    ),
                    "type": "number",
                    "format": ",.1f",
                }
            )
            continue

        # Fallback
        config.append({"key": col, "label": col.replace("_", " ").title(), "type": "string", "format": ""})

    return config
