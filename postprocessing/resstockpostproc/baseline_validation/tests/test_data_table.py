"""Tests for data_table HTML table generation."""

import json

import polars as pl
import pytest

from resstockpostproc.baseline_validation.io_managers.data_table import (
    should_generate_table,
    _filter_columns,
    _pivot_by_source,
    generate_data_table_html,
)
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
    defaults = dict(
        comparison_dataset=ComparisonDataset.eia,
        quantity=DataCol.ELECTRICITY_TOTAL,
        resolution=Resolution.year,
        aggregation_type=AggregationType.total,
        coverage=CoverageType.all_units,
        group_by="state",
        view=ViewType.value_view,
    )
    defaults.update(overrides)
    return PlotSpec(**defaults)


def _make_annual_data():
    """Create a minimal annual dataset with 2 states x 2 sources."""
    return pl.DataFrame({
        "state": ["CA", "CA", "NY", "NY"],
        "source": ["eia_2018", "resstock_2025", "eia_2018", "resstock_2025"],
        "electricity_total_value": [100.0, 130.0, 200.0, 190.0],
        "electricity_total_value_percent_difference": [None, 30.0, None, -5.0],
        "units_count": [1000.0, 1050.0, 2000.0, 1980.0],
        "model_count": [None, 500.0, None, 600.0],
        "electricity_total_value_rse": [0.5, None, 0.3, None],
        "electricity_total_value_upper_bound": [101.0, 130.0, 201.0, 190.0],
        "electricity_total_value_lower_bound": [99.0, 130.0, 199.0, 190.0],
        "electricity_total_quartiles_0": [10.0, 20.0, 30.0, 40.0],
        "electricity_total_quartiles_1": [50.0, 60.0, 70.0, 80.0],
        "electricity_total_nonzero_quartiles_0": [15.0, 25.0, 35.0, 45.0],
        "electricity_total_percent_users": [100.0, 100.0, 99.5, 99.8],
        "electricity_total_percent_users_percent_difference": [None, 0.0, None, 0.3],
    })


class TestShouldGenerateTable:
    def test_skips_all_enduse(self):
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            quantity=DataCol.ALL,
            aggregation_type=AggregationType.average,
        )
        data = pl.DataFrame({"state": ["CA"], "source": ["recs_2020"]})
        assert should_generate_table(data, spec) is False

    def test_accepts_small_annual(self):
        spec = _make_spec()
        data = _make_annual_data()
        assert should_generate_table(data, spec) is True

    def test_skips_large_hourly(self):
        """Hourly 8760 data with many entities exceeds threshold."""
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.lrd,
            quantity=DataCol.ELECTRICITY_TOTAL,
            resolution=Resolution.hour_of_year,
            aggregation_type=AggregationType.average,
            group_by="eiaid",
        )
        # 15 utilities x 8760 hours x 2 sources = 262,800 rows
        rows = []
        for uid in range(15):
            for h in range(8760):
                for src in ["lrd_2018", "resstock_2025"]:
                    rows.append({"eiaid": uid, "utility_name": f"Util{uid}", "hour of year": h,
                                 "source": src, "electricity_total_value": 1.0,
                                 "percent_time": h / 8760 * 100})
        data = pl.DataFrame(rows)
        assert should_generate_table(data, spec) is False


class TestFilterColumns:
    def test_drops_quartiles_rse_bounds(self):
        data = _make_annual_data()
        spec = _make_spec()
        filtered = _filter_columns(data, spec)

        # Quartile, RSE, and bound columns should be gone
        for col in filtered.columns:
            assert "quartiles" not in col
            assert not col.endswith("_rse")
            assert not col.endswith("_upper_bound")
            assert not col.endswith("_lower_bound")

    def test_drops_percent_users_for_all_units(self):
        data = _make_annual_data()
        spec = _make_spec(coverage=CoverageType.all_units)
        filtered = _filter_columns(data, spec)

        for col in filtered.columns:
            assert "percent_users" not in col

    def test_keeps_percent_users_for_users_only(self):
        data = _make_annual_data()
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            coverage=CoverageType.users_only,
            aggregation_type=AggregationType.average,
        )
        filtered = _filter_columns(data, spec)

        assert "electricity_total_percent_users" in filtered.columns

    def test_keeps_essential_columns(self):
        data = _make_annual_data()
        spec = _make_spec()
        filtered = _filter_columns(data, spec)

        assert "state" in filtered.columns
        assert "source" in filtered.columns
        assert "electricity_total_value" in filtered.columns
        assert "electricity_total_value_percent_difference" in filtered.columns
        assert "units_count" in filtered.columns

    def test_always_drops_eiaid(self):
        """eiaid should be dropped even without utility_name present."""
        data = pl.DataFrame({
            "eiaid": [1, 1],
            "state": ["CA", "CA"],
            "source": ["eia_2018", "resstock_2025"],
            "electricity_total_value": [100.0, 130.0],
        })
        spec = _make_spec()
        filtered = _filter_columns(data, spec)
        assert "eiaid" not in filtered.columns

    def test_drops_raw_quartile_list_columns(self):
        """Quartile list columns (pre-unnest) should be dropped by suffix match."""
        data = _make_annual_data().with_columns(
            pl.lit([1.0, 2.0]).alias("electricity_total_quartiles"),
            pl.lit([1.0, 2.0]).alias("electricity_total_nonzero_quartiles"),
        )
        spec = _make_spec()
        filtered = _filter_columns(data, spec)
        assert "electricity_total_quartiles" not in filtered.columns
        assert "electricity_total_nonzero_quartiles" not in filtered.columns


class TestDropAllNullColumns:
    def test_drops_all_null_columns_after_pivot(self, tmp_path):
        """Columns that are entirely null after pivoting should not appear in the table."""
        data = pl.DataFrame({
            "state": ["CA", "CA"],
            "source": ["eia_2018", "resstock_2025"],
            "electricity_total_value": [100.0, 130.0],
            "electricity_total_value_percent_difference": [None, 30.0],
            "units_count": [1000.0, 1050.0],
            "model_count": [None, 500.0],  # EIA has no model_count → all null for ref side
        })
        spec = _make_spec()
        output_path = tmp_path / "test_null.html"
        generate_data_table_html(data=data, plot_spec=spec, output_path=output_path)

        html = output_path.read_text(encoding="utf-8")
        # The EIA 2018 model_count column should be dropped (all null for EIA)
        assert "EIA 2018: Model Count" not in html


class TestPivotBySource:
    def test_annual_pivot(self):
        data = _make_annual_data()
        spec = _make_spec()
        filtered = _filter_columns(data, spec)
        pivoted, ref_label, rs_label = _pivot_by_source(filtered, spec)

        # Should have 2 rows (CA, NY) instead of 4
        assert len(pivoted) == 2
        # Should have entity column
        assert "state" in pivoted.columns
        # Should have source-prefixed value columns
        ref_cols = [c for c in pivoted.columns if c.startswith(f"{ref_label}: ")]
        rs_cols = [c for c in pivoted.columns if c.startswith(f"{rs_label}: ")]
        assert len(ref_cols) > 0
        assert len(rs_cols) > 0
        # Labels should be human-readable
        assert "EIA" in ref_label.upper()

    def test_monthly_preserves_month(self):
        """Monthly data should keep month as a row dimension."""
        data = pl.DataFrame({
            "state": ["CA", "CA", "CA", "CA"],
            "month": ["JAN", "JAN", "FEB", "FEB"],
            "source": ["eia_2018", "resstock_2025", "eia_2018", "resstock_2025"],
            "electricity_total_value": [100.0, 120.0, 90.0, 105.0],
            "electricity_total_value_percent_difference": [None, 20.0, None, 16.7],
            "units_count": [1000.0, 1050.0, 1000.0, 1050.0],
        })
        spec = _make_spec(resolution=Resolution.month)
        pivoted, _, _ = _pivot_by_source(data, spec)

        # Should have 2 rows (JAN, FEB) for the single entity
        assert len(pivoted) == 2
        assert "month" in pivoted.columns


class TestGenerateDataTableHtml:
    def test_html_output_structure(self, tmp_path):
        data = _make_annual_data()
        spec = _make_spec()
        output_path = tmp_path / "test_table.html"

        generate_data_table_html(
            data=data,
            plot_spec=spec,
            output_path=output_path,
            plot_rel_path="../plots/test_plot.html",
            cvrmse=19.1,
            nmbe=11.7,
        )

        html = output_path.read_text(encoding="utf-8")

        # Title present
        assert "Electricity" in html or "electricity" in html
        # Metrics present
        assert "19.1%" in html
        assert "11.7%" in html
        assert "CV(RMSE)" in html
        assert "NMBE" in html
        # Navigation links
        assert "View Plot" in html
        assert "Download CSV" in html
        assert "Back to Plot Index" in html
        # Data is embedded as JSON
        assert "const DATA = " in html
        assert "const COLUMNS = " in html
        # Sort functionality
        assert "sortBy" in html
        # Absolute difference column
        assert "Difference (kWh)" in html
        assert "abs_diff" in html
        # Formula breakdown section
        assert "renderMetricsFormula" in html
        assert "HAS_METRICS = true" in html

    def test_empty_data(self, tmp_path):
        spec = _make_spec()
        output_path = tmp_path / "empty_table.html"
        empty_data = pl.DataFrame({"state": [], "source": [], "electricity_total_value": []}).cast(
            {"electricity_total_value": pl.Float64}
        )

        generate_data_table_html(data=empty_data, plot_spec=spec, output_path=output_path)

        html = output_path.read_text(encoding="utf-8")
        assert "No data available" in html

    def test_no_metrics(self, tmp_path):
        data = _make_annual_data()
        spec = _make_spec()
        output_path = tmp_path / "no_metrics.html"

        generate_data_table_html(data=data, plot_spec=spec, output_path=output_path)

        html = output_path.read_text(encoding="utf-8")
        # The metrics banner div should not appear (CSS class definition is always present)
        assert '<div class="metrics-banner">' not in html
        assert "HAS_METRICS = false" in html


