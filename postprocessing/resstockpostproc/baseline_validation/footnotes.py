"""Python-based footnote generation for baseline validation outputs."""

from __future__ import annotations

from collections.abc import Iterable
from typing import Literal

from resstockpostproc.baseline_validation.plotters.plot_config import _resolve_rse_column
from resstockpostproc.baseline_validation.schema.plot_spec import (
    ComparisonDataset,
    CoverageType,
    Layout,
    PlotSpec,
    Resolution,
)
from resstockpostproc.shared_utils.db_column_names import (
    DataCol,
    _ENDUSE_OVERRIDES,
    _FUEL_PREFIXES,
)


NoteContext = Literal["plot", "table"]

RECS_OCCUPIED_UNITS_NOTE = "Only occupied dwelling units are included in the comparison."
RECS_GENERIC_RSE_NOTE = (
    "Error bars represent the 95% confidence interval based on RECS relative standard "
    "error (RSE) estimates."
)
RECS_MONTHLY_CI_NOTE = (
    "The darker filled area represents RECS consumption (from the lower confidence bound "
    "to zero). The lighter band above it shows the 95% confidence interval based on RECS "
    "relative standard error (RSE) estimates."
)
RECS_UNITS_COUNT_NOTE = (
    "ResStock dwelling unit counts represent the number of dwelling units captured "
    "through the combination of models and sampling weights. On hover, the RECS reference "
    "bar shows number of samples and the ResStock bar shows number of models."
)
EIA_NATURAL_GAS_PENETRATION_NOTE = (
    "The share of dwelling units with natural gas is calculated for EIA by dividing the "
    "natural gas customer count by the electricity customer count. For ResStock, it is "
    "the percent of models that have non-zero natural gas consumption."
)
HISTOGRAM_OVERFLOW_NOTE = (
    "Values above the weighted RECS 2020 98th-percentile cutoff are grouped into an "
    "overflow bin shown at double width. Hover over the bin to see its actual range."
)


def _fuel_and_enduse(quantity: DataCol) -> tuple[str, str | None] | None:
    """Extract (fuel_name, enduse_name_or_None) from a fuel/enduse DataCol.

    Returns None for non-fuel quantities (ALL, UNITS_COUNT, etc.).
    For fuel totals: ("Natural Gas", None).
    For enduses: ("Electricity", "Space Cooling").
    """
    for prefix, fuel_name in _FUEL_PREFIXES.items():
        if quantity.value.startswith(prefix + "_"):
            enduse = quantity.value[len(prefix) + 1:]
            if enduse == "total":
                return (fuel_name, None)
            enduse_name = _ENDUSE_OVERRIDES.get(enduse, enduse.replace("_", " ").title())
            return (fuel_name, enduse_name)
    return None


def _merge_notes(*note_groups: list[str] | None) -> list[str] | None:
    """Flatten note lists, preserving order while removing duplicates."""
    deduped = list(dict.fromkeys(
        note
        for group in note_groups
        for note in (group or [])
    ))
    return deduped or None


def _has_recs_rse(plot_spec: PlotSpec) -> bool:
    """True when the plot uses RECS RSE-backed uncertainty data."""
    return (
        plot_spec.comparison_dataset == ComparisonDataset.recs
        and _resolve_rse_column(plot_spec) is not None
    )


def _uses_monthly_ci_band(plot_spec: PlotSpec) -> bool:
    """True for RECS monthly value plots rendered with the filled CI band."""
    return _has_recs_rse(plot_spec) and plot_spec.resolution == Resolution.month


def get_dataset_notes(plot_spec: PlotSpec) -> list[str] | None:
    """Return dataset-wide caveat notes.

    RECS "occupied units" note is handled by get_coverage_note() instead,
    so this function can focus on future dataset-level caveats.
    """
    _ = plot_spec
    return None


def get_coverage_note(plot_spec: PlotSpec) -> list[str] | None:
    """Return coverage-specific notes about which dwelling units are included."""
    is_recs = plot_spec.comparison_dataset == ComparisonDataset.recs
    is_users = plot_spec.coverage == CoverageType.users_only

    if not is_recs and not is_users:
        return None

    if is_recs and not is_users:
        return [RECS_OCCUPIED_UNITS_NOTE]

    # users_only: describe which consuming units are included
    prefix = "Only occupied dwelling units" if is_recs else "Only dwelling units"
    parts = _fuel_and_enduse(plot_spec.quantity)
    if parts is None:
        return [f"{prefix} with non-zero consumption are included in the comparison."]
    fuel_name, enduse_name = parts
    if enduse_name is None:
        return [f"{prefix} which consumed {fuel_name} are included in the comparison."]
    return [f"{prefix} which consumed {fuel_name} for {enduse_name} are included in the comparison."]


def get_metric_notes(plot_spec: PlotSpec, context: NoteContext) -> list[str] | None:
    """Return metric or visualization notes for a plot/table context."""
    notes: list[str] = []

    if (
        plot_spec.comparison_dataset == ComparisonDataset.eia
        and plot_spec.quantity == DataCol.NATURAL_GAS_TOTAL
        and plot_spec.is_penetration_metric
    ):
        notes.append(EIA_NATURAL_GAS_PENETRATION_NOTE)

    if context != "plot":
        return notes or None

    if _uses_monthly_ci_band(plot_spec):
        notes.append(RECS_MONTHLY_CI_NOTE)
    elif _has_recs_rse(plot_spec):
        notes.append(RECS_GENERIC_RSE_NOTE)

    if plot_spec.layout == Layout.histogram:
        notes.append(HISTOGRAM_OVERFLOW_NOTE)

    return notes or None


def get_quantity_notes(plot_spec: PlotSpec, context: NoteContext) -> list[str] | None:
    """Return quantity-specific notes for a plot/table context."""
    if (
        context == "plot"
        and plot_spec.comparison_dataset == ComparisonDataset.recs
        and plot_spec.quantity == DataCol.UNITS_COUNT
    ):
        return [RECS_UNITS_COUNT_NOTE]
    return None


def get_plot_notes(plot_spec: PlotSpec) -> list[str] | None:
    """Return ordered notes for plot pages."""
    return _merge_notes(
        get_dataset_notes(plot_spec),
        get_coverage_note(plot_spec),
        get_metric_notes(plot_spec, "plot"),
        get_quantity_notes(plot_spec, "plot"),
    )


def get_table_notes(plot_spec: PlotSpec) -> list[str] | None:
    """Return ordered notes for data-table pages."""
    return _merge_notes(
        get_dataset_notes(plot_spec),
        get_coverage_note(plot_spec),
        get_metric_notes(plot_spec, "table"),
        get_quantity_notes(plot_spec, "table"),
    )


def dedupe_note_groups(note_groups: Iterable[list[str] | None]) -> list[str] | None:
    """Combine note groups from multiple specs while preserving first-seen order."""
    return _merge_notes(*list(note_groups))
