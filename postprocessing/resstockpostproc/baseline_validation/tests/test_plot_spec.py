"""Tests for PlotSpec Pydantic validators."""

import pytest
from pydantic import ValidationError

from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    Metric,
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
        aggregation_type=Metric.total,
        coverage=CoverageType.all_units,
        group_by="state",
        view=ViewType.value_view,
    )
    defaults.update(overrides)
    return PlotSpec(**defaults)


class TestRejectTotalDistribution:
    def test_total_distribution_raises(self):
        with pytest.raises(ValidationError, match="distribution requires Metric.average"):
            _make_spec(aggregation_type=Metric.total, view=ViewType.value_view)

    def test_average_distribution_allowed(self):
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            aggregation_type=Metric.average,
            view=ViewType.value_view,
        )
        assert spec.view == ViewType.value_view


class TestLRDConstraints:
    def test_valid_lrd_spec(self):
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.lrd,
            quantity=DataCol.ELECTRICITY_TOTAL,
            aggregation_type=Metric.average,
            coverage=CoverageType.all_units,
            group_by="utility",
        )
        assert spec.comparison_dataset == ComparisonDataset.lrd

    def test_lrd_wrong_quantity(self):
        with pytest.raises(ValidationError, match="LRD only supports quantity=ELECTRICITY_TOTAL"):
            _make_spec(
                comparison_dataset=ComparisonDataset.lrd,
                quantity=DataCol.NATURAL_GAS_TOTAL,
                aggregation_type=Metric.average,
                coverage=CoverageType.all_units,
            )

    def test_lrd_wrong_aggregation_type(self):
        with pytest.raises(ValidationError, match="LRD only supports aggregation_type=average"):
            _make_spec(
                comparison_dataset=ComparisonDataset.lrd,
                quantity=DataCol.ELECTRICITY_TOTAL,
                aggregation_type=Metric.total,
                coverage=CoverageType.all_units,
            )

    def test_lrd_wrong_coverage(self):
        with pytest.raises(ValidationError, match="LRD only supports coverage=all_units"):
            _make_spec(
                comparison_dataset=ComparisonDataset.lrd,
                quantity=DataCol.ELECTRICITY_TOTAL,
                aggregation_type=Metric.average,
                coverage=CoverageType.users_only,
            )

    def test_non_lrd_skips_lrd_constraints(self):
        """EIA/RECS specs should not be subject to LRD-specific validation."""
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.eia,
            quantity=DataCol.NATURAL_GAS_TOTAL,
            aggregation_type=Metric.total,
            coverage=CoverageType.all_units,
        )
        assert spec.comparison_dataset == ComparisonDataset.eia


class TestLRDDisplayMetricLabels:
    @staticmethod
    def _make_lrd_spec(
        resolution: Resolution,
        view: ViewType = ViewType.value_view,
        focus_on: tuple[tuple[str, str], ...] = (),
        group_by: str | None = "utility",
    ) -> PlotSpec:
        return PlotSpec(
            comparison_dataset=ComparisonDataset.lrd,
            quantity=DataCol.ELECTRICITY_TOTAL,
            resolution=resolution,
            aggregation_type=Metric.average,
            coverage=CoverageType.all_units,
            focus_on=focus_on,
            group_by=group_by,
            view=view,
        )

    @pytest.mark.parametrize(
        "resolution,view,group_by,focus_on,expected",
        [
            (Resolution.year, ViewType.value_view, "utility", (), "Average Annual Consumption"),
            (Resolution.month, ViewType.value_view, "utility", (), "Average Monthly Consumption"),
            (Resolution.day_of_year, ViewType.value_view, "utility", (), "Average Daily Consumption"),
            (Resolution.hour_of_day, ViewType.value_view, "utility", (), "Average Day Hourly Consumption"),
            (Resolution.hour_of_day_summer, ViewType.value_view, "utility", (), "Average Day Hourly Consumption"),
            (Resolution.hour_of_day_winter, ViewType.value_view, "utility", (), "Average Day Hourly Consumption"),
            (
                Resolution.hour_of_day_matrix,
                ViewType.value_view,
                None,
                (("utility", "ComEd (IL)"),),
                "Average Day Hourly Consumption",
            ),
            (Resolution.hour_of_year, ViewType.value_view, "utility", (), "Load Duration Plot"),
            (Resolution.top_100_hours, ViewType.value_view, "utility", (), "Load Duration Plot"),
            (
                Resolution.hour_of_year,
                ViewType.temp_view,
                "utility",
                (),
                "Load Vs Outdoor Drybulb Temperature",
            ),
            (
                Resolution.hour_of_year,
                ViewType.temp_distribution_view,
                "utility",
                (),
                "Load Vs Outdoor Drybulb Temperature",
            ),
        ],
    )
    def test_display_metric_label_mapping(self, resolution, view, group_by, focus_on, expected):
        spec = self._make_lrd_spec(resolution=resolution, view=view, focus_on=focus_on, group_by=group_by)
        assert spec.display_metric == expected
