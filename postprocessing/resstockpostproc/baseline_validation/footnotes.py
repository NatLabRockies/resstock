"""Python-based footnote generation for baseline validation outputs."""

from __future__ import annotations

from collections.abc import Iterable
from typing import Literal

from resstockpostproc.baseline_validation.plotters.plot_config import _resolve_rse_column
from resstockpostproc.baseline_validation.schema.plot_spec import (
    ComparisonDataset,
    PlotSpec,
    Resolution,
)
from resstockpostproc.shared_utils.db_column_names import DataCol


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
    """Return dataset-wide caveat notes."""
    if plot_spec.comparison_dataset == ComparisonDataset.recs:
        return [RECS_OCCUPIED_UNITS_NOTE]
    return None


def get_coverage_note(plot_spec: PlotSpec) -> list[str] | None:
    """Return coverage-specific notes when coverage changes interpretation."""
    _ = plot_spec
    return None


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
