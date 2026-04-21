"""Tests for confidence-bound column resolution logic."""

from resstockpostproc.baseline_validation.plotters.plot_config import _resolve_bound_columns
from resstockpostproc.baseline_validation.schema.plot_spec import (
    ComparisonDataset,
    Metric,
    Resolution,
    ViewType,
)
from resstockpostproc.shared_utils.db_column_names import DataCol


from resstockpostproc.baseline_validation.tests._helpers import make_recs_spec as _make_spec


class TestResolveBoundColumns:
    def test_non_recs_returns_none(self):
        assert _resolve_bound_columns(_make_spec(comparison_dataset=ComparisonDataset.eia)) == (None, None)
        assert _resolve_bound_columns(
            _make_spec(comparison_dataset=ComparisonDataset.lrd, group_by="utility")
        ) == (None, None)

    def test_monthly_resolution_has_value_bounds(self):
        assert _resolve_bound_columns(_make_spec(resolution=Resolution.month)) == (
            "electricity_total_value_lower_bound",
            "electricity_total_value_upper_bound",
        )

    def test_distribution_view_returns_none(self):
        assert _resolve_bound_columns(
            _make_spec(aggregation_type=Metric.distribution, view=ViewType.value_view)
        ) == (None, None)

    def test_units_count_has_no_bounds(self):
        assert _resolve_bound_columns(_make_spec(quantity=DataCol.UNITS_COUNT)) == (None, None)

    def test_penetration_view_uses_percent_users_bounds(self):
        spec = _make_spec(quantity=DataCol.ELECTRICITY_TOTAL, aggregation_type=Metric.penetration)
        assert _resolve_bound_columns(spec) == (
            "electricity_total_percent_users_lower_bound",
            "electricity_total_percent_users_upper_bound",
        )

    def test_default_value_bounds(self):
        assert _resolve_bound_columns(_make_spec()) == (
            "electricity_total_value_lower_bound",
            "electricity_total_value_upper_bound",
        )

    def test_different_quantity(self):
        spec = _make_spec(quantity=DataCol.NATURAL_GAS_TOTAL)
        assert _resolve_bound_columns(spec) == (
            "natural_gas_total_value_lower_bound",
            "natural_gas_total_value_upper_bound",
        )
