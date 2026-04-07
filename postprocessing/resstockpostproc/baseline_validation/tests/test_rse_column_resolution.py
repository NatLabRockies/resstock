"""Tests for RSE column name resolution logic."""

import pytest

from resstockpostproc.baseline_validation.plotters.plot_config import _resolve_rse_column
from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    AggregationType,
    CoverageType,
    Resolution,
    TruthSource,
    ViewType,
)
from resstockpostproc.shared_utils.db_column_names import DataCol


def _make_spec(**overrides):
    defaults = dict(
        truth_source=TruthSource.recs,
        quantity=DataCol.ELECTRICITY_TOTAL,
        resolution=Resolution.year,
        aggregation_type=AggregationType.average,
        coverage=CoverageType.all_units,
        aggregation_level="state",
        view=ViewType.value_view,
    )
    defaults.update(overrides)
    return PlotSpec(**defaults)


class TestResolveRSEColumn:
    def test_non_recs_returns_none(self):
        """EIA and LRD sources have no RSE data."""
        assert _resolve_rse_column(_make_spec(truth_source=TruthSource.eia)) is None
        assert _resolve_rse_column(
            _make_spec(
                truth_source=TruthSource.lrd,
                aggregation_level="eiaid",
            )
        ) is None

    def test_monthly_resolution_returns_none(self):
        """Monthly RECS data has no RSE columns."""
        assert _resolve_rse_column(_make_spec(resolution=Resolution.month)) is None

    def test_distribution_view_returns_none(self):
        """Distribution box plots use quartiles, not RSE."""
        assert _resolve_rse_column(_make_spec(view=ViewType.distribution)) is None

    def test_units_count_has_no_rse(self):
        """Unit counts derive from calibrated weights — RSE is meaningless."""
        assert _resolve_rse_column(_make_spec(quantity=DataCol.UNITS_COUNT)) is None

    def test_penetration_view(self):
        spec = _make_spec(
            quantity=DataCol.ELECTRICITY_TOTAL,
            view=ViewType.penetration,
            aggregation_type=AggregationType.total,
        )
        assert _resolve_rse_column(spec) == "electricity_total_percent_users_rse"

    def test_default_value_rse(self):
        assert _resolve_rse_column(_make_spec()) == "electricity_total_value_rse"

    def test_different_quantity(self):
        spec = _make_spec(quantity=DataCol.NATURAL_GAS_TOTAL)
        assert _resolve_rse_column(spec) == "natural_gas_total_value_rse"
