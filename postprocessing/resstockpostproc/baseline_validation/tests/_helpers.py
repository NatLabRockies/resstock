"""Shared test helpers. Not a test module — name starts with ``_`` so pytest skips it."""

from resstockpostproc.baseline_validation.schema.plot_spec import (
    ComparisonDataset,
    CoverageType,
    Metric,
    PlotSpec,
    Resolution,
    ViewType,
)
from resstockpostproc.shared_utils.db_column_names import DataCol


def make_eia_spec(**overrides) -> PlotSpec:
    """Build a valid EIA PlotSpec; override any field via kwargs."""
    defaults = dict(
        comparison_dataset=ComparisonDataset.eia,
        quantity=DataCol.ELECTRICITY_TOTAL,
        resolution=Resolution.year,
        aggregation_type=Metric.total,
        coverage=CoverageType.all_units,
        group_by="state",
        view=ViewType.value_view,
    )
    defaults.update(overrides)
    return PlotSpec(**defaults)


def make_recs_spec(**overrides) -> PlotSpec:
    """Build a valid RECS PlotSpec; override any field via kwargs."""
    defaults = dict(
        comparison_dataset=ComparisonDataset.recs,
        quantity=DataCol.ELECTRICITY_TOTAL,
        resolution=Resolution.year,
        aggregation_type=Metric.average,
        coverage=CoverageType.all_units,
        group_by="state",
        view=ViewType.value_view,
    )
    defaults.update(overrides)
    return PlotSpec(**defaults)
