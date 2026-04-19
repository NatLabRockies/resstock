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
    Layout,
    format_group_by,
    ALL_ENDUSES_DISPLAY,
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
        with pytest.raises(ValidationError, match="Metric.distribution is only supported for RECS"):
            _make_spec(
                comparison_dataset=ComparisonDataset.eia,
                aggregation_type=Metric.distribution,
                view=ViewType.value_view,
            )

    def test_average_distribution_allowed(self):
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            aggregation_type=Metric.distribution,
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
        with pytest.raises(ValidationError, match="LRD only supports average-backed metrics"):
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


class TestDisplayVizLabels:
    @pytest.mark.parametrize(
        "overrides,expected",
        [
            ({"group_by": None}, "Bar Plot"),
            ({}, "Bar Plot (grouped)"),
            ({"group_by": None, "view": ViewType.diff_view}, "Bar Plot (difference view)"),
            ({"view": ViewType.diff_view}, "Bar Plot (grouped difference view)"),
            ({"group_by": None, "resolution": Resolution.month}, "Bar Plot"),
            (
                {"group_by": None, "resolution": Resolution.month, "view": ViewType.diff_view},
                "Bar Plot (difference view)",
            ),
            ({"resolution": Resolution.month}, "Timeseries Plot (grouped)"),
            (
                {
                    "comparison_dataset": ComparisonDataset.recs,
                    "aggregation_type": Metric.distribution,
                    "view": ViewType.value_view,
                },
                "Box Plot (grouped)",
            ),
        ],
    )
    def test_display_viz_label_format(self, overrides, expected):
        spec = _make_spec(**overrides)
        assert spec.display_viz_label == expected

    def test_two_column_layout_viz_label(self):
        spec = _make_spec(layout=Layout.two_column)
        assert spec.display_viz_label == "Bar Plot (two_column)"

        diff_spec = _make_spec(view=ViewType.diff_view, layout=Layout.two_column)
        assert diff_spec.display_viz_label == "Bar Plot (two_column difference view)"

    def test_two_column_layout_file_title_suffix(self):
        auto_spec = _make_spec()
        two_col_spec = _make_spec(layout=Layout.two_column)

        _, auto_title = auto_spec.file_path_and_name
        _, two_col_title = two_col_spec.file_path_and_name

        assert auto_title != two_col_title
        assert two_col_title.endswith("(two_column layout)")

    def test_histogram_layout_viz_label(self):
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            aggregation_type=Metric.distribution,
            view=ViewType.value_view,
            group_by=None,
            layout=Layout.histogram,
        )
        assert spec.display_viz_label == "Histogram"

    def test_histogram_layout_file_title_suffix(self):
        auto_spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            aggregation_type=Metric.distribution,
            view=ViewType.value_view,
            group_by=None,
            layout=Layout.auto,
        )
        hist_spec = auto_spec.model_copy(update={"layout": Layout.histogram})

        _, auto_title = auto_spec.file_path_and_name
        _, hist_title = hist_spec.file_path_and_name

        assert auto_title != hist_title
        assert hist_title.endswith("(histogram layout)")


class TestDisplayLabels:
    def test_all_quantity_uses_clearer_display_label(self):
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            quantity=DataCol.ALL,
            aggregation_type=Metric.average,
        )
        assert spec.display_quantity == ALL_ENDUSES_DISPLAY

    def test_climate_zone_uses_full_group_label(self):
        assert format_group_by("building_america_climate_zone") == "Building America Climate Zone"
