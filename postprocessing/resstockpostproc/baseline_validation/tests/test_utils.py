"""Tests for data utility functions in io_managers/utils.py."""

import polars as pl
import pytest

from resstockpostproc.baseline_validation.io_managers.utils import (
    add_missing_states,
    add_us_total,
    apply_aggregation,
)
from resstockpostproc.baseline_validation.schema.plot_spec import (
    Metric,
    CoverageType,
    DataKey,
    Resolution,
    ComparisonDataset,
)


class TestAddUsTotal:
    def test_annual_sums_across_states(self):
        df = pl.DataFrame({
            "state": ["CA", "NY"],
            "electricity_total_value": [100.0, 200.0],
            "units_count": [10.0, 20.0],
        })
        result = add_us_total(df, by="state")

        us_row = result.filter(pl.col("state") == "US Total")
        assert us_row.height == 1
        assert us_row["electricity_total_value"].item() == 300.0
        assert us_row["units_count"].item() == 30.0

    def test_monthly_with_group_cols(self):
        df = pl.DataFrame({
            "state": ["CA", "NY", "CA", "NY"],
            "month": ["JAN", "JAN", "FEB", "FEB"],
            "electricity_total_value": [10.0, 20.0, 30.0, 40.0],
        })
        result = add_us_total(df, by="state", group_cols=["month"])

        us_rows = result.filter(pl.col("state") == "US Total")
        assert us_rows.height == 2  # one per month
        jan_total = us_rows.filter(pl.col("month") == "JAN")["electricity_total_value"].item()
        feb_total = us_rows.filter(pl.col("month") == "FEB")["electricity_total_value"].item()
        assert jan_total == 30.0
        assert feb_total == 70.0

    def test_idempotent_when_us_total_exists(self):
        df = pl.DataFrame({
            "state": ["CA", "US Total"],
            "electricity_total_value": [100.0, 999.0],
        })
        result = add_us_total(df, by="state")
        assert result.height == 2  # no duplicate added

    def test_exclude_cols_set_to_none(self):
        df = pl.DataFrame({
            "state": ["CA", "NY"],
            "electricity_total_value": [100.0, 200.0],
            "sample_count": [50, 60],
        })
        result = add_us_total(df, by="state", exclude_cols=["sample_count"])

        us_row = result.filter(pl.col("state") == "US Total")
        assert us_row["electricity_total_value"].item() == 300.0
        assert us_row["sample_count"].item() is None


class TestAddMissingStates:
    def test_adds_ak_hi_when_missing(self):
        df = pl.DataFrame({
            "state": ["CA", "NY"],
            "electricity_total_value": [100.0, 200.0],
        })
        result = add_missing_states(df)

        states = set(result["state"].to_list())
        assert "AK" in states
        assert "HI" in states
        assert result.height == 4

    def test_monthly_adds_ak_hi_for_all_months(self):
        months = ["JAN", "FEB"]
        df = pl.DataFrame({
            "state": ["CA", "CA"],
            "month": months,
            "electricity_total_value": [100.0, 200.0],
        })
        result = add_missing_states(df)

        ak_rows = result.filter(pl.col("state") == "AK")
        hi_rows = result.filter(pl.col("state") == "HI")
        # add_missing_states uses all 12 months from NUM2MONTH, not just input months
        assert ak_rows.height == 12
        assert hi_rows.height == 12

    def test_noop_when_both_present(self):
        df = pl.DataFrame({
            "state": ["AK", "HI", "CA"],
            "electricity_total_value": [10.0, 20.0, 30.0],
        })
        result = add_missing_states(df)
        assert result.height == 3


class TestApplyAggregation:
    def _make_key(self, agg_type, coverage):
        return DataKey(
            comparison_dataset=ComparisonDataset.eia,
            effective_group_by=("state",),
            resolution=Resolution.year,
            aggregation_type=agg_type,
            coverage=coverage,
        )

    def test_total_no_transformation(self):
        df = pl.DataFrame({
            "state": ["CA"],
            "electricity_total_value": [1000.0],
            "units_count": [10.0],
        })
        key = self._make_key(Metric.total, CoverageType.all_units)
        result = apply_aggregation(key, df)

        assert result["electricity_total_value"].item() == 1000.0

    def test_average_all_units_divides_by_count(self):
        df = pl.DataFrame({
            "state": ["CA"],
            "electricity_total_value": [1000.0],
            "units_count": [10.0],
        })
        key = self._make_key(Metric.average, CoverageType.all_units)
        result = apply_aggregation(key, df)

        assert result["electricity_total_value"].item() == pytest.approx(100.0)

    def test_average_users_only(self):
        """users_only divides by (percent_users/100 * units_count)."""
        df = pl.DataFrame({
            "state": ["CA"],
            "electricity_total_value": [1000.0],
            "electricity_total_percent_users": [50],
            "units_count": [100.0],
        })
        key = self._make_key(Metric.average, CoverageType.users_only)
        result = apply_aggregation(key, df)

        # denominator = 50/100 * 100 = 50 users → 1000/50 = 20.0
        assert result["electricity_total_value"].item() == pytest.approx(20.0)
        # percent_users should retain the real penetration rate
        assert result["electricity_total_percent_users"].item() == pytest.approx(50.0)

    def test_average_all_units_multiple_value_cols(self):
        """All _value columns should be divided, not just one."""
        df = pl.DataFrame({
            "state": ["CA"],
            "electricity_total_value": [500.0],
            "natural_gas_total_value": [200.0],
            "units_count": [10.0],
        })
        key = self._make_key(Metric.average, CoverageType.all_units)
        result = apply_aggregation(key, df)

        assert result["electricity_total_value"].item() == pytest.approx(50.0)
        assert result["natural_gas_total_value"].item() == pytest.approx(20.0)
