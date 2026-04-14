"""Tests for 95% CI bound generation from RSE values."""

import polars as pl
import pytest

from resstockpostproc.baseline_validation.data_processing.gather_data import _add_95ci_bounds, get_plot_data
from resstockpostproc.baseline_validation.schema.plot_spec import (
    ComparisonDataset,
    CoverageType,
    Layout,
    Metric,
    PlotSpec,
    Resolution,
    ViewType,
)
from resstockpostproc.shared_utils.db_column_names import DataCol


class TestAdd95CIBounds:
    def test_normal_case(self):
        """value=100, RSE=10 → upper = 100 + 100*10/100*1.96 = 119.6, lower = 80.4."""
        df = pl.DataFrame({
            "electricity_total_value": [100.0],
            "electricity_total_value_rse": [10.0],
        })
        result = _add_95ci_bounds(df)

        assert "electricity_total_value_upper_bound" in result.columns
        assert "electricity_total_value_lower_bound" in result.columns
        assert result["electricity_total_value_upper_bound"].item() == pytest.approx(119.6)
        assert result["electricity_total_value_lower_bound"].item() == pytest.approx(80.4)

    def test_null_rse_treated_as_zero(self):
        """Null RSE → bounds equal the value (no error margin)."""
        df = pl.DataFrame({
            "electricity_total_value": [200.0],
            "electricity_total_value_rse": [None],
        }).cast({"electricity_total_value_rse": pl.Float64})
        result = _add_95ci_bounds(df)

        assert result["electricity_total_value_upper_bound"].item() == pytest.approx(200.0)
        assert result["electricity_total_value_lower_bound"].item() == pytest.approx(200.0)

    def test_multiple_rse_columns(self):
        """Each _rse column should generate its own _upper_bound and _lower_bound."""
        df = pl.DataFrame({
            "electricity_total_value": [100.0],
            "electricity_total_value_rse": [10.0],
            "natural_gas_total_value": [50.0],
            "natural_gas_total_value_rse": [20.0],
        })
        result = _add_95ci_bounds(df)

        assert result["electricity_total_value_upper_bound"].item() == pytest.approx(119.6)
        # 50 + 50*20/100*1.96 = 50 + 19.6 = 69.6
        assert result["natural_gas_total_value_upper_bound"].item() == pytest.approx(69.6)
        # 50 - 19.6 = 30.4
        assert result["natural_gas_total_value_lower_bound"].item() == pytest.approx(30.4)

    def test_no_rse_columns_unchanged(self):
        """DataFrame with no _rse columns should be returned unchanged."""
        df = pl.DataFrame({"value": [100.0], "state": ["CA"]})
        result = _add_95ci_bounds(df)
        assert result.columns == ["value", "state"]

    def test_zero_rse_bounds_equal_value(self):
        """RSE=0 → bounds equal the value."""
        df = pl.DataFrame({
            "electricity_total_value": [100.0],
            "electricity_total_value_rse": [0.0],
        })
        result = _add_95ci_bounds(df)

        assert result["electricity_total_value_upper_bound"].item() == pytest.approx(100.0)
        assert result["electricity_total_value_lower_bound"].item() == pytest.approx(100.0)

    def test_large_rse_negative_lower_bound(self):
        """Very large RSE can produce negative lower bounds (valid — represents uncertainty)."""
        df = pl.DataFrame({
            "electricity_total_value": [10.0],
            "electricity_total_value_rse": [100.0],  # 100% RSE
        })
        result = _add_95ci_bounds(df)

        # upper = 10 + 10*100/100*1.96 = 10 + 19.6 = 29.6
        assert result["electricity_total_value_upper_bound"].item() == pytest.approx(29.6)
        # lower = 10 - 19.6 = -9.6
        assert result["electricity_total_value_lower_bound"].item() == pytest.approx(-9.6)


class TestGetPlotDataRouting:
    @staticmethod
    def _make_hist_spec() -> PlotSpec:
        return PlotSpec(
            comparison_dataset=ComparisonDataset.recs,
            quantity=DataCol.ELECTRICITY_TOTAL,
            resolution=Resolution.year,
            aggregation_type=Metric.distribution,
            coverage=CoverageType.all_units,
            group_by=None,
            view=ViewType.value_view,
            layout=Layout.histogram,
        )

    def test_histogram_layout_uses_exact_histogram_pipeline(self, monkeypatch):
        expected = pl.DataFrame(
            {
                "source": ["RECS 2020"],
                "bin": [0],
                "bin_left": [0.0],
                "bin_right": [1.0],
                "count_pct": [100.0],
            }
        )
        monkeypatch.setattr(
            "resstockpostproc.baseline_validation.data_processing.gather_data.get_distribution_histogram_data",
            lambda _spec: expected,
        )
        monkeypatch.setattr(
            "resstockpostproc.baseline_validation.data_processing.gather_data.get_base_data",
            lambda _key: (_ for _ in ()).throw(AssertionError("get_base_data should not be called for histogram")),
        )
        out = get_plot_data(self._make_hist_spec())
        assert out.equals(expected)

    def test_histogram_layout_rejects_grouped_specs(self):
        grouped = self._make_hist_spec().model_copy(update={"group_by": "state"})
        with pytest.raises(ValueError, match="group_by=None"):
            get_plot_data(grouped)
