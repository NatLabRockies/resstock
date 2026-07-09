"""Tests for baseline validation gather-data helpers."""

import polars as pl

from resstockpostproc.baseline_validation.data_processing.gather_data import _keep_relevant_columns, get_plot_data
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


class TestKeepRelevantColumns:
    def test_keeps_matching_bounds_and_drops_other_quantity_bounds(self):
        df = pl.DataFrame(
            {
                "state": ["CA"],
                "source": ["recs_2020"],
                "units_count": [100.0],
                "electricity_total_value": [10.0],
                "electricity_total_value_lower_bound": [9.0],
                "electricity_total_value_upper_bound": [11.0],
                "natural_gas_total_value": [20.0],
                "natural_gas_total_value_lower_bound": [18.0],
                "natural_gas_total_value_upper_bound": [22.0],
            }
        )
        spec = PlotSpec(
            comparison_dataset=ComparisonDataset.recs,
            quantity=DataCol.ELECTRICITY_TOTAL,
            resolution=Resolution.year,
            aggregation_type=Metric.average,
            coverage=CoverageType.all_units,
            group_by="state",
            view=ViewType.value_view,
        )

        result = _keep_relevant_columns(df, spec)

        assert "electricity_total_value_lower_bound" in result.columns
        assert "electricity_total_value_upper_bound" in result.columns
        assert "natural_gas_total_value_lower_bound" not in result.columns
        assert "natural_gas_total_value_upper_bound" not in result.columns

    def test_no_bounds_input_is_unchanged(self):
        df = pl.DataFrame({"value": [100.0], "state": ["CA"]})
        spec = PlotSpec(
            comparison_dataset=ComparisonDataset.eia,
            quantity=DataCol.ELECTRICITY_TOTAL,
            resolution=Resolution.year,
            aggregation_type=Metric.total,
            coverage=CoverageType.all_units,
            group_by="state",
            view=ViewType.value_view,
        )
        result = _keep_relevant_columns(df, spec)
        assert result.columns == ["value", "state"]


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

    def test_histogram_layout_accepts_grouped_specs(self, monkeypatch):
        expected = pl.DataFrame(
            {
                "state": ["CA", "TX"],
                "source": ["RECS 2020", "RECS 2020"],
                "bin": [0, 0],
                "bin_left": [0.0, 0.0],
                "bin_right": [1.0, 1.0],
                "count_pct": [50.0, 50.0],
            }
        )
        monkeypatch.setattr(
            "resstockpostproc.baseline_validation.data_processing.gather_data.get_distribution_histogram_data",
            lambda _spec: expected,
        )
        grouped = self._make_hist_spec().model_copy(update={"group_by": "state"})
        out = get_plot_data(grouped)
        assert out.equals(expected)
