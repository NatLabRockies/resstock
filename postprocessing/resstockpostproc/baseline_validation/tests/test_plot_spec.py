"""Tests for PlotSpec Pydantic validators."""

import pytest
from pydantic import ValidationError

from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    AggregationType,
    CoverageType,
    Resolution,
    ComparisonDataset,
    ViewType,
)
from resstockpostproc.shared_utils.db_column_names import DataCol


def _make_spec(**overrides):
    """Build a valid EIA PlotSpec, then apply overrides."""
    defaults = dict(
        comparison_dataset=ComparisonDataset.eia,
        quantity=DataCol.ELECTRICITY_TOTAL,
        resolution=Resolution.year,
        aggregation_type=AggregationType.total,
        coverage=CoverageType.all_units,
        aggregation_level="state",
        view=ViewType.value_view,
    )
    defaults.update(overrides)
    return PlotSpec(**defaults)


class TestRejectTotalDistribution:
    def test_total_distribution_raises(self):
        with pytest.raises(ValidationError, match="distribution requires AggregationType.average"):
            _make_spec(aggregation_type=AggregationType.total, view=ViewType.distribution)

    def test_average_distribution_allowed(self):
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            aggregation_type=AggregationType.average,
            view=ViewType.distribution,
        )
        assert spec.view == ViewType.distribution


class TestLRDConstraints:
    def test_valid_lrd_spec(self):
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.lrd,
            quantity=DataCol.ELECTRICITY_TOTAL,
            aggregation_type=AggregationType.average,
            coverage=CoverageType.all_units,
            aggregation_level="eiaid",
        )
        assert spec.comparison_dataset == ComparisonDataset.lrd

    def test_lrd_wrong_quantity(self):
        with pytest.raises(ValidationError, match="LRD only supports quantity=ELECTRICITY_TOTAL"):
            _make_spec(
                comparison_dataset=ComparisonDataset.lrd,
                quantity=DataCol.NATURAL_GAS_TOTAL,
                aggregation_type=AggregationType.average,
                coverage=CoverageType.all_units,
            )

    def test_lrd_wrong_aggregation_type(self):
        with pytest.raises(ValidationError, match="LRD only supports aggregation_type=average"):
            _make_spec(
                comparison_dataset=ComparisonDataset.lrd,
                quantity=DataCol.ELECTRICITY_TOTAL,
                aggregation_type=AggregationType.total,
                coverage=CoverageType.all_units,
            )

    def test_lrd_wrong_coverage(self):
        with pytest.raises(ValidationError, match="LRD only supports coverage=all_units"):
            _make_spec(
                comparison_dataset=ComparisonDataset.lrd,
                quantity=DataCol.ELECTRICITY_TOTAL,
                aggregation_type=AggregationType.average,
                coverage=CoverageType.users_only,
            )

    def test_non_lrd_skips_lrd_constraints(self):
        """EIA/RECS specs should not be subject to LRD-specific validation."""
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.eia,
            quantity=DataCol.NATURAL_GAS_TOTAL,
            aggregation_type=AggregationType.total,
            coverage=CoverageType.all_units,
        )
        assert spec.comparison_dataset == ComparisonDataset.eia
