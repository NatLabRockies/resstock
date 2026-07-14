"""Public semantic helpers shared across plotting, table, and orchestration code.

These helpers formerly lived as private (`_`-prefixed) names in
plot_config.py and data_table.py and were imported across modules.
Promoting them to a public module keeps cross-module imports on
stable public names.
"""

from __future__ import annotations

import polars as pl

from resstockpostproc.baseline_validation.schema.plot_spec import (
    ComparisonDataset,
    CoverageType,
    Metric,
    PlotSpec,
    Resolution,
    ViewType,
)
from resstockpostproc.baseline_validation.schema.workflow_schema import DataSourceLabel
from resstockpostproc.shared_utils.db_column_names import DataCol


def resolve_timeseries_column(plot_spec: PlotSpec) -> str | None:
    """Resolve the timeseries/x-axis column name based on resolution.

    Returns the column name that provides the x-axis values for time-based plots.
    """
    match plot_spec.resolution:
        case Resolution.year:
            return None

        case Resolution.month:
            return "month"

        case Resolution.day_of_year:
            return "day of year"

        case Resolution.hour_of_year | Resolution.top_100_hours:
            if plot_spec.view in [ViewType.temp_view, ViewType.temp_distribution_view]:
                return "resstock_temp"
            return "percent_time"

        case Resolution.hour_of_day | Resolution.hour_of_day_summer | Resolution.hour_of_day_winter:
            return plot_spec.resolution

        case Resolution.hour_of_day_matrix:
            return "hour of day"

        case _:
            return None


def resolve_quantity_title(plot_spec: PlotSpec) -> str:
    """Resolve the y-axis label (quantity units).

    Returns units like kWh, kWh/unit, kWh/user, %, or count.
    """
    # LRD: always per-meter (per dwelling unit), except the temperature distribution count
    if plot_spec.comparison_dataset == ComparisonDataset.lrd:
        if plot_spec.view == ViewType.temp_distribution_view:
            return "count"
        return "kWh/unit"

    # RECS/EIA: dwelling unit count case
    if plot_spec.quantity == DataCol.UNITS_COUNT:
        return "count"

    # RECS/EIA: penetration view shows percentages
    if plot_spec.is_penetration_metric:
        return "%"

    # RECS/EIA: total aggregation
    if plot_spec.aggregation_type == Metric.total:
        return "kWh"

    # RECS/EIA: average aggregation - depends on coverage
    if plot_spec.aggregation_type in (Metric.average, Metric.distribution):
        if plot_spec.coverage == CoverageType.users_only:
            return "kWh/user"
        return "kWh/unit"

    return "kWh"


def format_source_label(source_str: str) -> str:
    """Format a raw source string like 'resstock_2025' into 'ResStock 2025'."""
    parts = source_str.split("_")
    if parts[0].lower() == "resstock":
        parts[0] = "ResStock"
    else:
        parts[0] = parts[0].upper()
    return " ".join(parts)


QUARTILE_INDICES: tuple[tuple[int, str], ...] = (
    (0, "min"),
    (3, "q1"),
    (4, "median"),
    (5, "q3"),
    (8, "max"),
)
"""List-index positions carrying semantic meaning in a 9-element quartile list."""


def quartile_list_column(quantity: str, coverage: CoverageType) -> str:
    """Return the quartile list column for ``quantity`` given coverage.

    all_units coverage reads from ``{quantity}_quartiles``; users_only
    reads from ``{quantity}_nonzero_quartiles``.
    """
    if coverage == CoverageType.users_only:
        return f"{quantity}_nonzero_quartiles"
    return f"{quantity}_quartiles"


def apply_source_labels(
    df: pl.DataFrame,
    data_source_labels: dict[str, DataSourceLabel],
) -> pl.DataFrame:
    """Rename raw source keys to human-readable display labels.

    ``data_source_labels`` is typically ``workflow.data_source_labels`` from
    the caller's module — passed explicitly so tests can monkeypatch the
    caller's ``workflow`` without reaching into this helper. No-op when the
    map is empty or the frame has no ``source`` column.
    """
    label_map = {k: v.label for k, v in data_source_labels.items()}
    if not label_map or "source" not in df.columns:
        return df
    return df.with_columns(pl.col("source").replace_strict(label_map, default=pl.col("source")))
