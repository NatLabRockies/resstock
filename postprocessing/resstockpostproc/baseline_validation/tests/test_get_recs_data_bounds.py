"""Tests for RECS loader uncertainty-bound helpers."""

import polars as pl
import pytest

from resstockpostproc.baseline_validation.io_managers.get_recs_data import (
    _add_symmetric_bounds_from_rse,
    _build_bounds_row,
    _resolve_recs_value_stat_type,
)
from resstockpostproc.baseline_validation.schema.plot_spec import (
    ComparisonDataset,
    CoverageType,
    DataKey,
    Metric,
    Resolution,
)
from resstockpostproc.shared_utils.db_column_names import DataCol


class TestMonthlyPublishedRSEConversion:
    def test_converts_monthly_rse_to_same_numeric_bounds(self):
        df = pl.DataFrame(
            {
                "electricity_total_value": [10.0],
                "electricity_total_value_rse": [100.0],
            }
        )
        result = _add_symmetric_bounds_from_rse(df)

        assert "electricity_total_value_rse" not in result.columns
        assert result["electricity_total_value_upper_bound"].item() == pytest.approx(29.6)
        assert result["electricity_total_value_lower_bound"].item() == pytest.approx(-9.6)


class TestAnnualBoundHelpers:
    def test_users_only_average_uses_nonzero_estimator(self):
        data_key = DataKey(
            comparison_dataset=ComparisonDataset.recs,
            effective_group_by=("state",),
            resolution=Resolution.year,
            aggregation_type=Metric.average,
            coverage=CoverageType.users_only,
        )
        assert _resolve_recs_value_stat_type(data_key) == "avg_nonzero"

    def test_build_bounds_row_maps_value_and_percent_columns(self):
        bounds = {
            (DataCol.ELECTRICITY_TOTAL, "avg"): (9.0, 11.0),
            (DataCol.ELECTRICITY_TOTAL, "percent"): (40.0, 60.0),
        }
        row = _build_bounds_row(bounds, (DataCol.ELECTRICITY_TOTAL,), "avg")

        assert row["electricity_total_value_lower_bound"] == pytest.approx(9.0)
        assert row["electricity_total_value_upper_bound"] == pytest.approx(11.0)
        assert row["electricity_total_percent_users_lower_bound"] == pytest.approx(40.0)
        assert row["electricity_total_percent_users_upper_bound"] == pytest.approx(60.0)
