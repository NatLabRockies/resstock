"""Tests for data_table HTML table generation."""

import json

import polars as pl
import pytest

from resstockpostproc.baseline_validation.io_managers.data_table import (
    should_generate_table,
    _filter_columns,
    _pivot_by_source,
    _melt_enduse_columns,
    generate_data_table_html,
)
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
    def test_accepts_all_enduse(self):
        """ALL-quantity plots are now melted into tall form and get a table."""
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            quantity=DataCol.ALL,
            aggregation_type=Metric.average,
        )
        data = pl.DataFrame({"state": ["CA"], "source": ["recs_2020"]})
        assert should_generate_table(data, spec) is True

    def test_accepts_small_annual(self):
        spec = _make_spec()
        data = _make_annual_data()
        assert should_generate_table(data, spec) is True

    def test_accepts_large_hourly(self):
        """Large hourly tables are still generated — they paginate client-side."""
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.lrd,
            quantity=DataCol.ELECTRICITY_TOTAL,
            resolution=Resolution.hour_of_year,
            aggregation_type=Metric.average,
            group_by="utility",
        )
        data = pl.DataFrame({
            "utility": ["Util1"], "hour of year": [0],
            "source": ["lrd_2018"], "electricity_total_value": [1.0],
        })
        assert should_generate_table(data, spec) is True

    def test_accepts_single_row(self):
        """Single-entity annual plots still get a table for completeness."""
        spec = _make_spec()
        data = pl.DataFrame({
            "state": ["CA"], "source": ["eia_2018"],
            "electricity_total_value": [100.0],
        })
        assert should_generate_table(data, spec) is True


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
            aggregation_type=Metric.average,
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

    def test_matrix_drops_redundant_split_cols(self):
        """hour_of_day_matrix should drop utility/month/day_type — encoded in month_daytype."""
        data = pl.DataFrame({
            "month_daytype": ["JAN_Weekday", "JAN_Weekend"],
            "utility": ["AEP (OH)", "AEP (OH)"],
            "month": ["JAN", "JAN"],
            "day_type": ["Weekday", "Weekend"],
            "hour of day": [0, 0],
            "source": ["lrd_2018", "lrd_2018"],
            "electricity_total_value": [1.5, 1.8],
        })
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.lrd,
            resolution=Resolution.hour_of_day_matrix,
            aggregation_type=Metric.average,
            focus_on=(("utility", "AEP (OH)"),),
            group_by=None,
        )
        filtered = _filter_columns(data, spec)
        assert "utility" not in filtered.columns
        assert "month" not in filtered.columns
        assert "day_type" not in filtered.columns
        assert "month_daytype" in filtered.columns


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
        pivoted, ref_label, rs_labels = _pivot_by_source(filtered, spec)

        # Should have 2 rows (CA, NY) instead of 4
        assert len(pivoted) == 2
        # Should have entity column
        assert "state" in pivoted.columns
        # Should have source-prefixed value columns
        ref_cols = [c for c in pivoted.columns if c.startswith(f"{ref_label}: ")]
        assert len(ref_cols) > 0
        assert len(rs_labels) > 0
        rs_label = rs_labels[0]
        rs_cols = [c for c in pivoted.columns if c.startswith(f"{rs_label}: ")]
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
            metrics_by_source={"ResStock 2025": 11.7},
        )

        html = output_path.read_text(encoding="utf-8")

        # Title present
        assert "Electricity" in html or "electricity" in html
        # Metrics present
        assert "11.7%" in html
        assert "sMAPE" in html
        # Source label appears in the per-source banner
        assert "ResStock 2025" in html
        # Navigation links
        assert "View Plot" not in html
        assert "Download CSV" in html
        # Data is embedded as JSON
        assert "const DATA = " in html
        assert "const COLUMNS = " in html
        # Sort functionality
        assert "sortBy" in html
        # Per-source absolute difference column (e.g., "ResStock 2025 Absolute Difference (kWh)")
        assert "Absolute Difference (kWh)" in html
        assert "abs_diff" in html
        # Formula breakdown section
        assert "renderMetricsFormula" in html
        assert "RS_SOURCES" in html

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
        assert 'class="metrics-banner"' not in html

    def test_download_csv_filename_override(self, tmp_path):
        data = _make_annual_data()
        spec = _make_spec()
        output_path = tmp_path / "csv_name_override.html"

        generate_data_table_html(
            data=data,
            plot_spec=spec,
            output_path=output_path,
            csv_download_filename="Annual Enduse Consumption (stacked view).csv",
        )

        html = output_path.read_text(encoding="utf-8")
        assert 'a.download = "Annual Enduse Consumption (stacked view).csv";' in html

    def test_can_disable_discrepancy_metrics_details(self, tmp_path):
        data = _make_annual_data()
        spec = _make_spec()
        output_path = tmp_path / "no_discrepancy_details.html"

        generate_data_table_html(
            data=data,
            plot_spec=spec,
            output_path=output_path,
            metrics_by_source={"ResStock 2025": 11.7},
            include_discrepancy_metrics=False,
        )

        html = output_path.read_text(encoding="utf-8")
        assert 'id="metricsDetails"' not in html
        assert "Discrepancy Metrics Details" not in html
        assert "const RS_SOURCES = []" in html

    def test_matrix_entity_label_is_month_daytype(self, tmp_path):
        """Load Profile Matrix tables should label the entity column 'Month / Day Type'."""
        data = pl.DataFrame({
            "month_daytype": ["JAN_Weekday", "JAN_Weekend"],
            "utility": ["AEP (OH)", "AEP (OH)"],
            "month": ["JAN", "JAN"],
            "day_type": ["Weekday", "Weekend"],
            "hour of day": [0, 0],
            "source": ["lrd_2018", "lrd_2018"],
            "electricity_total_value": [1.5, 1.8],
        })
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.lrd,
            resolution=Resolution.hour_of_day_matrix,
            aggregation_type=Metric.average,
            focus_on=(("utility", "AEP (OH)"),),
            group_by=None,
        )
        output_path = tmp_path / "matrix_table.html"
        generate_data_table_html(data=data, plot_spec=spec, output_path=output_path)
        html = output_path.read_text(encoding="utf-8")

        # The entity column header should be "Month / Day Type"
        assert "Month / Day Type" in html
        # Per-source redundant split columns should not appear as headers
        assert "LRD 2018: Utility" not in html
        assert "LRD 2018: Month" not in html
        assert "LRD 2018: Day Type" not in html


def _make_distribution_data():
    """Minimal distribution dataset: 2 states × 2 sources, with 9-element quartile lists."""
    return pl.DataFrame({
        "state": ["CA", "CA", "NY", "NY"],
        "source": ["recs_2020", "resstock_2025", "recs_2020", "resstock_2025"],
        "electricity_total_value": [80.0, 90.0, 120.0, 130.0],
        "electricity_total_quartiles": [
            [10.0, 0.0, 0.0, 50.0, 80.0, 110.0, 0.0, 0.0, 200.0],
            [12.0, 0.0, 0.0, 55.0, 90.0, 125.0, 0.0, 0.0, 220.0],
            [20.0, 0.0, 0.0, 80.0, 120.0, 160.0, 0.0, 0.0, 300.0],
            [22.0, 0.0, 0.0, 85.0, 130.0, 175.0, 0.0, 0.0, 320.0],
        ],
        "model_count": [None, 500.0, None, 600.0],
    })


class TestDistributionTable:
    def test_distribution_table_includes_quartiles(self, tmp_path):
        """Distribution plots produce a table with mean + min/q1/median/q3/max columns per source."""
        data = _make_distribution_data()
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            view=ViewType.value_view,
            aggregation_type=Metric.distribution,
        )
        output_path = tmp_path / "dist_table.html"
        generate_data_table_html(data=data, plot_spec=spec, output_path=output_path)
        html = output_path.read_text(encoding="utf-8")

        # All 5 quartile-stat labels should appear in the rendered headers
        assert "Min" in html
        assert "Q1" in html
        assert "Median" in html
        assert "Q3" in html
        assert "Max" in html
        # The _value column should be labeled "Average" (not the default source-only label)
        assert "Average" in html

    def test_distribution_table_no_metrics_block(self, tmp_path):
        """Distribution tables do not show a discrepancy metrics banner or formula details."""
        data = _make_distribution_data()
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            view=ViewType.value_view,
            aggregation_type=Metric.distribution,
        )
        output_path = tmp_path / "dist_no_metrics.html"
        generate_data_table_html(data=data, plot_spec=spec, output_path=output_path)
        html = output_path.read_text(encoding="utf-8")

        # No populated banner (the CSS class definition is always present, but no
        # rendered <table class="metrics-banner"> wrapper should appear)
        assert '<table class="metrics-banner">' not in html
        # No per-source absolute-difference columns should be generated
        assert "Absolute Difference (kWh)" not in html
        # JS RS_SOURCES list is empty (no per-source formula derivations)
        assert "const RS_SOURCES = []" in html

    def test_distribution_uses_nonzero_quartiles_for_users_only(self, tmp_path):
        """When coverage=users_only, the helper reads `_nonzero_quartiles` instead."""
        data = pl.DataFrame({
            "state": ["CA", "CA"],
            "source": ["recs_2020", "resstock_2025"],
            "electricity_total_value": [80.0, 90.0],
            "electricity_total_nonzero_quartiles": [
                [15.0, 0.0, 0.0, 60.0, 95.0, 130.0, 0.0, 0.0, 220.0],
                [18.0, 0.0, 0.0, 65.0, 100.0, 140.0, 0.0, 0.0, 240.0],
            ],
            "electricity_total_percent_users": [98.0, 97.5],
            "model_count": [None, 500.0],
        })
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            view=ViewType.value_view,
            aggregation_type=Metric.distribution,
            coverage=CoverageType.users_only,
        )
        output_path = tmp_path / "dist_users_only.html"
        generate_data_table_html(data=data, plot_spec=spec, output_path=output_path)
        html = output_path.read_text(encoding="utf-8")
        # Median values from the nonzero quartile list should appear (95.0 and 100.0)
        assert "95" in html
        assert "100" in html


class TestAllEnduseTable:
    def test_melt_produces_enduse_column(self):
        """The melt helper should rename per-enduse columns to 'all_*' and add an 'enduse' column."""
        data = pl.DataFrame({
            "state": ["CA", "CA"],
            "source": ["recs_2020", "resstock_2025"],
            "electricity_total_value": [5000.0, 5200.0],
            "electricity_space_heating_value": [1200.0, 1250.0],
            "natural_gas_total_value": [2000.0, 2100.0],
        })
        melted = _melt_enduse_columns(data)
        assert "enduse" in melted.columns
        assert "all_value" in melted.columns
        # 3 enduses × 2 sources = 6 rows (one state)
        assert len(melted) == 6
        labels = set(melted["enduse"].unique().to_list())
        assert "Electricity" in labels  # electricity_total fuel total
        assert "Space Heating Electricity" in labels
        assert "Natural Gas" in labels

    def test_all_enduse_table_end_to_end(self, tmp_path):
        """ALL-quantity RECS value tables should render with an End Use column."""
        data = pl.DataFrame({
            "state": ["CA", "CA", "NY", "NY"],
            "source": ["recs_2020", "resstock_2025"] * 2,
            "electricity_total_value": [5000.0, 5200.0, 6000.0, 6300.0],
            "electricity_total_value_percent_difference": [None, 4.0, None, 5.0],
            "electricity_space_heating_value": [1200.0, 1250.0, 1500.0, 1550.0],
            "electricity_space_heating_value_percent_difference": [None, 4.2, None, 3.3],
            "units_count": [1000.0, 1050.0, 2000.0, 2050.0],
            "model_count": [None, 500.0, None, 600.0],
        })
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            quantity=DataCol.ALL,
            aggregation_type=Metric.average,
        )
        output_path = tmp_path / "all_table.html"
        generate_data_table_html(data=data, plot_spec=spec, output_path=output_path)
        html = output_path.read_text(encoding="utf-8")
        assert "End Use" in html
        assert "Electricity" in html
        assert "Space Heating Electricity" in html

    def test_all_enduse_drops_constant_entity_column(self, tmp_path):
        """For focused single-entity ALL plots, the state column is dropped as redundant."""
        # US Total overview: all rows have state="US Total"
        data = pl.DataFrame({
            "state": ["US Total", "US Total"],
            "source": ["recs_2020", "resstock_2025"],
            "electricity_total_value": [5000.0, 5200.0],
            "electricity_space_heating_value": [1200.0, 1250.0],
            "model_count": [None, 500.0],
        })
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            quantity=DataCol.ALL,
            aggregation_type=Metric.average,
            focus_on=(("state", "US Total"),),
            group_by=None,
        )
        output_path = tmp_path / "all_us_total.html"
        generate_data_table_html(data=data, plot_spec=spec, output_path=output_path)
        html = output_path.read_text(encoding="utf-8")
        # The End Use column should still be present (it has multiple values)
        assert "End Use" in html
        # But the State column header should NOT appear — it was dropped as constant
        # (Using the escaped JSON check for the label "State")
        assert '"label": "State"' not in html

    def test_all_enduse_distribution_table(self, tmp_path):
        """ALL-quantity distribution specs are invalid under the Metric-based schema."""
        data = pl.DataFrame({
            "state": ["CA", "CA"],
            "source": ["recs_2020", "resstock_2025"],
            "electricity_total_value": [5000.0, 5200.0],
            "electricity_total_quartiles": [
                [10.0, 0.0, 0.0, 25.0, 50.0, 75.0, 0.0, 0.0, 100.0],
                [12.0, 0.0, 0.0, 28.0, 55.0, 80.0, 0.0, 0.0, 110.0],
            ],
            "model_count": [None, 500.0],
        })
        with pytest.raises(Exception):
            _make_spec(
                comparison_dataset=ComparisonDataset.recs,
                quantity=DataCol.ALL,
                view=ViewType.value_view,
                aggregation_type=Metric.distribution,
            )


class TestTemperatureViewTable:
    def test_temp_view_table_includes_energy_and_hour_count(self, tmp_path):
        """Temperature relation plots render a combined energy + hour-count table."""
        # Shape mirrors gather_data._prepare_temperature_view output: one row per
        # (source, utility, resstock_temp) with the mean energy and the count of hours.
        data = pl.DataFrame({
            "utility": ["AEP (OH)"] * 6 + ["PG&E (CA)"] * 6,
            "source": ["lrd_2018", "lrd_2018", "lrd_2018", "resstock_2025", "resstock_2025", "resstock_2025"] * 2,
            "resstock_temp": [30, 50, 70, 30, 50, 70] * 2,
            "electricity_total_value": [2.5, 1.8, 2.2, 2.6, 1.7, 2.3, 3.0, 1.5, 1.8, 3.1, 1.4, 1.9],
            "temp_count": [120, 300, 180, 118, 302, 182, 100, 350, 200, 99, 351, 201],
        })
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.lrd,
            quantity=DataCol.ELECTRICITY_TOTAL,
            resolution=Resolution.hour_of_year,
            aggregation_type=Metric.average,
            view=ViewType.temp_view,
            group_by="utility",
        )
        output_path = tmp_path / "temp_view.html"
        generate_data_table_html(data=data, plot_spec=spec, output_path=output_path)
        html = output_path.read_text(encoding="utf-8")

        # Temperature column should use the human label (° encoded as \u00b0 by json.dumps)
        assert "Temperature" in html
        assert "\\u00b0F" in html or "°F" in html
        # Hour-count column should use the custom humanized label
        assert "Hour Count" in html
        # Energy values are present (kWh/unit for LRD)
        assert "kWh/unit" in html
        # The Utility column has 2 distinct values so it stays
        assert "AEP (OH)" in html
        assert "PG&amp;E (CA)" in html or "PG&E (CA)" in html
