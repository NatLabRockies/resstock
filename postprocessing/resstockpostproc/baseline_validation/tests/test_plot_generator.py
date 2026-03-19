"""Tests for plot_generator discrepancy math and list unnesting."""

import math

import polars as pl
import pytest

from resstockpostproc.baseline_validation.plot_generator import _compute_discrepancy, _unnest_list_columns
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
        truth_source=TruthSource.eia,
        quantity=DataCol.ELECTRICITY_TOTAL,
        resolution=Resolution.year,
        aggregation_type=AggregationType.total,
        coverage=CoverageType.all_units,
        aggregation_level="state",
        view=ViewType.value_view,
    )
    defaults.update(overrides)
    return PlotSpec(**defaults)


class TestComputeDiscrepancy:
    """Tests for CVRMSE/NMBE calculation."""

    def test_normal_case(self):
        """Verify CVRMSE and NMBE against hand-calculated values."""
        # ref = [100, 200], rs = [110, 190]
        # diffs = [10, -10], sum_ref = 300, mean_ref = 150
        # NMBE = (10 + -10) / 300 * 100 = 0.0
        # RMSE = sqrt((100 + 100) / 2) = sqrt(100) = 10.0
        # CVRMSE = 10.0 / 150 * 100 = 6.666...
        data = pl.DataFrame({
            "source": ["eia_2018", "eia_2018", "resstock_2024", "resstock_2024"],
            "state": ["CA", "NY", "CA", "NY"],
            "electricity_total_value": [100.0, 200.0, 110.0, 190.0],
        })
        spec = _make_spec()
        cvrmse, nmbe = _compute_discrepancy(data, spec)

        assert nmbe == pytest.approx(0.0)
        assert cvrmse == pytest.approx(10.0 / 150.0 * 100)

    def test_positive_bias(self):
        """ResStock consistently higher → positive NMBE."""
        data = pl.DataFrame({
            "source": ["eia_2018", "resstock_2024"],
            "state": ["CA", "CA"],
            "electricity_total_value": [100.0, 120.0],
        })
        spec = _make_spec()
        cvrmse, nmbe = _compute_discrepancy(data, spec)

        assert nmbe == pytest.approx(20.0)  # (120-100)/100 * 100
        assert cvrmse == pytest.approx(20.0)

    def test_returns_none_for_all_quantity(self):
        spec = _make_spec(
            truth_source=TruthSource.recs,
            quantity=DataCol.ALL,
            aggregation_type=AggregationType.average,
        )
        data = pl.DataFrame({"source": ["recs"], "state": ["CA"], "electricity_total_value": [1.0]})
        assert _compute_discrepancy(data, spec) == (None, None)

    def test_returns_none_for_distribution_view(self):
        spec = _make_spec(
            truth_source=TruthSource.recs,
            aggregation_type=AggregationType.average,
            view=ViewType.distribution,
        )
        data = pl.DataFrame({"source": ["recs"], "state": ["CA"], "electricity_total_value": [1.0]})
        assert _compute_discrepancy(data, spec) == (None, None)

    def test_returns_none_when_no_resstock_rows(self):
        data = pl.DataFrame({
            "source": ["eia_2018", "eia_2018"],
            "state": ["CA", "NY"],
            "electricity_total_value": [100.0, 200.0],
        })
        spec = _make_spec()
        assert _compute_discrepancy(data, spec) == (None, None)

    def test_returns_none_when_zero_reference(self):
        data = pl.DataFrame({
            "source": ["eia_2018", "resstock_2024"],
            "state": ["CA", "CA"],
            "electricity_total_value": [0.0, 50.0],
        })
        spec = _make_spec()
        assert _compute_discrepancy(data, spec) == (None, None)

    def test_excludes_us_total_by_default(self):
        """US Total rows should be excluded when focus_on is not 'US Total'."""
        data = pl.DataFrame({
            "source": ["eia_2018", "eia_2018", "resstock_2024", "resstock_2024"],
            "state": ["CA", "US Total", "CA", "US Total"],
            "electricity_total_value": [100.0, 999.0, 100.0, 999.0],
        })
        spec = _make_spec(focus_on=None)
        cvrmse, nmbe = _compute_discrepancy(data, spec)

        # Only CA is used (US Total excluded) → perfect match
        assert nmbe == pytest.approx(0.0)
        assert cvrmse == pytest.approx(0.0)

    def test_includes_us_total_when_focused(self):
        """When focus_on='US Total', US Total rows should be included."""
        data = pl.DataFrame({
            "source": ["eia_2018", "resstock_2024"],
            "state": ["US Total", "US Total"],
            "electricity_total_value": [100.0, 120.0],
        })
        spec = _make_spec(focus_on="US Total")
        cvrmse, nmbe = _compute_discrepancy(data, spec)

        assert nmbe == pytest.approx(20.0)

    def test_units_count_quantity(self):
        """When quantity is UNITS_COUNT, val_col should be 'units_count'."""
        data = pl.DataFrame({
            "source": ["eia_2018", "resstock_2024"],
            "state": ["CA", "CA"],
            "units_count": [1000.0, 1100.0],
        })
        spec = _make_spec(quantity=DataCol.UNITS_COUNT)
        cvrmse, nmbe = _compute_discrepancy(data, spec)

        assert nmbe == pytest.approx(10.0)

    def test_monthly_resolution_joins_on_month(self):
        """Monthly data should join on both state and month."""
        data = pl.DataFrame({
            "source": ["eia_2018", "eia_2018", "resstock_2024", "resstock_2024"],
            "state": ["CA", "CA", "CA", "CA"],
            "month": ["JAN", "FEB", "JAN", "FEB"],
            "electricity_total_value": [100.0, 200.0, 110.0, 220.0],
        })
        spec = _make_spec(resolution=Resolution.month)
        cvrmse, nmbe = _compute_discrepancy(data, spec)

        # diffs = [10, 20], sum_ref = 300, NMBE = 30/300*100 = 10%
        assert nmbe == pytest.approx(10.0)


class TestUnnestListColumns:
    def test_expands_list_column(self):
        df = pl.DataFrame({
            "name": ["a", "b"],
            "quartiles": [[1, 2, 3], [4, 5, 6]],
        })
        result = _unnest_list_columns(df)

        assert "quartiles" not in result.columns
        assert "quartiles_0" in result.columns
        assert "quartiles_1" in result.columns
        assert "quartiles_2" in result.columns
        assert result["quartiles_0"].to_list() == [1, 4]
        assert result["quartiles_2"].to_list() == [3, 6]

    def test_no_list_columns_unchanged(self):
        df = pl.DataFrame({"a": [1, 2], "b": ["x", "y"]})
        result = _unnest_list_columns(df)
        assert result.columns == ["a", "b"]
        assert result["a"].to_list() == [1, 2]

    def test_mixed_list_and_scalar(self):
        df = pl.DataFrame({
            "name": ["a", "b"],
            "score": [10.0, 20.0],
            "values": [[1, 2], [3, 4]],
        })
        result = _unnest_list_columns(df)

        assert "name" in result.columns
        assert "score" in result.columns
        assert "values" not in result.columns
        assert "values_0" in result.columns
        assert "values_1" in result.columns
