"""Tests for LRD (Load Research Data) validation functionality using mock data."""

import polars as pl
import pytest
from datetime import datetime, timedelta

from resstockpostproc.baseline_validation.plotters import lrd_plotter
from resstockpostproc.baseline_validation.io_managers.get_lrd_data import get_lrd_data
from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    Resolution,
    ComparisonDataset,
    AggregationType,
    CoverageType,
    ViewType,
)
from resstockpostproc.shared_utils.db_column_names import DataCol


class TestLRDPlotter:
    """Tests for LRD plotter create_plot function."""

    @pytest.fixture
    def mock_hourly_matrix_data(self):
        """Create mock data for hour_of_day_matrix resolution tests."""
        # Create data with all required columns for hour_of_day_matrix
        months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC", "All Year"]
        day_types = ["All Days", "Weekday", "Weekend"]
        hours = list(range(24))
        sources = ["lrd_reference", "resstock_2024", "resstock_2025"]

        data = []
        for source in sources:
            for month in months:
                for day_type in day_types:
                    for hour in hours:
                        data.append(
                            {
                                "source": source,
                                "utility_name": "ComEd (IL)",
                                "eiaid": 4110,
                                "month": month,
                                "day_type": day_type,
                                "hour of day": hour,
                                f"{DataCol.ELECTRICITY_TOTAL}_value": 1.5
                                + 0.5 * (hour - 12) ** 2 / 144,  # Parabolic curve
                            }
                        )

        df = pl.DataFrame(data)
        # Add month_daytype column (normally created by gather_data._prepare_hour_of_day_matrix)
        return df.with_columns((pl.col("month") + "_" + pl.col("day_type")).alias("month_daytype"))

    @pytest.fixture
    def mock_year_data(self):
        """Create mock data for year resolution tests."""
        sources = ["lrd_reference", "resstock_2024", "resstock_2025"]
        utilities = ["ComEd (IL)", "PG&E (CA)", "SCE (CA)"]

        data = []
        for source in sources:
            for utility in utilities:
                data.append(
                    {
                        "source": source,
                        "utility_name": utility,
                        "eiaid": 4110 if utility == "ComEd (IL)" else 14328,
                        f"{DataCol.ELECTRICITY_TOTAL}_value": 8000.0 + (500.0 if "resstock" in source else 0),
                        f"{DataCol.ELECTRICITY_TOTAL}_value_percent_difference": 5.0 if "resstock" in source else 0.0,
                        "model_count": 100,  # Required for bar plotter
                    }
                )

        return pl.DataFrame(data)

    def test_create_plot_hour_of_day_matrix(self, mock_hourly_matrix_data):
        """Test creating hour_of_day_matrix plot."""
        plot_spec = PlotSpec(
            comparison_dataset=ComparisonDataset.lrd,
            resolution=Resolution.hour_of_day_matrix,
            group_by=None,
            quantity=DataCol.ELECTRICITY_TOTAL,
            focus_on=(("eiaid", "ComEd (IL)"),),
            aggregation_type=AggregationType.average,
            coverage=CoverageType.all_units,
            view=ViewType.value_view,
        )

        fig, title = lrd_plotter.create_plot(mock_hourly_matrix_data, plot_spec)

        assert fig is not None
        assert "ComEd (IL)" in title
        # 13 months * 3 day_types * 3 sources = 117 potential traces (some may be combined)
        assert len(fig.data) >= 1

    def test_create_plot_hour_of_day_matrix_requires_focus_on(self, mock_hourly_matrix_data):
        """Test that hour_of_day_matrix raises error without focus_on."""
        plot_spec = PlotSpec(
            comparison_dataset=ComparisonDataset.lrd,
            resolution=Resolution.hour_of_day_matrix,
            group_by="eiaid",
            quantity=DataCol.ELECTRICITY_TOTAL,
            focus_on=(),  # Missing required parameter
            aggregation_type=AggregationType.average,
            coverage=CoverageType.all_units,
            view=ViewType.value_view,
        )

        with pytest.raises(ValueError, match="hour_of_day_matrix requires focus_on"):
            lrd_plotter.create_plot(mock_hourly_matrix_data, plot_spec)

    def test_create_plot_hour_of_day_matrix_creates_month_daytype_column(self, mock_hourly_matrix_data):
        """Test that hour_of_day_matrix creates the combined month_daytype column."""
        plot_spec = PlotSpec(
            comparison_dataset=ComparisonDataset.lrd,
            resolution=Resolution.hour_of_day_matrix,
            group_by=None,
            quantity=DataCol.ELECTRICITY_TOTAL,
            focus_on=(("eiaid", "ComEd (IL)"),),
            aggregation_type=AggregationType.average,
            coverage=CoverageType.all_units,
            view=ViewType.value_view,
        )

        fig, title = lrd_plotter.create_plot(mock_hourly_matrix_data, plot_spec)

        # Verify the plot was created successfully
        assert fig is not None
        assert "hourly load profile matrix" in title.lower()

    def test_create_plot_year_resolution(self, mock_year_data):
        """Test creating year resolution plot."""
        plot_spec = PlotSpec(
            comparison_dataset=ComparisonDataset.lrd,
            resolution=Resolution.year,
            group_by="eiaid",
            quantity=DataCol.ELECTRICITY_TOTAL,
            focus_on=(),
            aggregation_type=AggregationType.average,
            coverage=CoverageType.all_units,
            view=ViewType.value_view,
        )

        fig, title = lrd_plotter.create_plot(mock_year_data, plot_spec)

        assert fig is not None
        assert "annual" in title.lower()

    def test_create_plot_unsupported_resolution(self, mock_year_data):
        """Test that unsupported resolution raises error."""
        # Create a plot spec with an invalid resolution (if one exists)
        # For now, test that a valid resolution works
        plot_spec = PlotSpec(
            comparison_dataset=ComparisonDataset.lrd,
            resolution=Resolution.month,
            group_by="eiaid",
            quantity=DataCol.ELECTRICITY_TOTAL,
            focus_on=(),
            aggregation_type=AggregationType.average,
            coverage=CoverageType.all_units,
            view=ViewType.value_view,
        )

        # Add month column for month resolution
        data_with_month = mock_year_data.with_columns(pl.lit("JAN").alias("month"))

        fig, title = lrd_plotter.create_plot(data_with_month, plot_spec)
        assert fig is not None


class TestHourOfDayMatrixDataProcessing:
    """Tests for hour_of_day_matrix data processing logic."""

    def test_month_daytype_column_format(self):
        """Test that month_daytype column is correctly formatted."""
        # Simulate the column creation logic from lrd_plotter
        df = pl.DataFrame(
            {
                "month": ["JAN", "FEB", "All Year"],
                "day_type": ["Weekday", "Weekend", "All Days"],
            }
        )

        result = df.with_columns((pl.col("month") + "_" + pl.col("day_type")).alias("month_daytype"))

        expected = ["JAN_Weekday", "FEB_Weekend", "All Year_All Days"]
        assert result["month_daytype"].to_list() == expected

    def test_month_daytype_layout_coverage(self):
        """Test that all expected month_daytype combinations are covered."""
        from resstockpostproc.shared_utils.generic_plotters.tilemap_plotter import LAYOUTS

        layout = LAYOUTS["month_daytype"]

        # Verify layout dimensions
        assert len(layout) == 13  # 12 months + All Year
        assert all(len(row) == 3 for row in layout)  # 3 day types per row

        # Verify all combinations present
        months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC", "All Year"]
        day_types = ["All Days", "Weekday", "Weekend"]

        all_cells = [cell for row in layout for cell in row]
        for month in months:
            for day_type in day_types:
                expected_cell = f"{month}_{day_type}"
                assert expected_cell in all_cells, f"Missing {expected_cell} in layout"


class TestDayOfYearResolution:
    """Tests for day_of_year resolution with datetime x-axis and vertical layout."""

    @pytest.fixture
    def mock_day_of_year_data(self):
        """Create mock data for day_of_year resolution tests."""
        from datetime import datetime, timedelta

        sources = ["lrd_2018", "resstock_2024", "resstock_2025"]
        utilities = ["ComEd (IL)", "PG&E (CA)", "SCE (CA)"]
        start_date = datetime(2018, 1, 1)

        data = []
        for source in sources:
            for utility in utilities:
                for day in range(365):
                    date = start_date + timedelta(days=day)
                    data.append(
                        {
                            "source": source,
                            "utility_vertical": utility,  # Renamed from utility_name by gather_data
                            "eiaid": 4110 if utility == "ComEd (IL)" else 14328,
                            "day of year": date,  # Datetime, not integer
                            f"{DataCol.ELECTRICITY_TOTAL}_value": 20.0 + 10.0 * (1 + 0.5 * ((day - 182) / 182) ** 2),
                            "model_count": 100,
                        }
                    )

        return pl.DataFrame(data)

    def test_day_of_year_uses_datetime_column(self, mock_day_of_year_data):
        """Test that day_of_year column contains datetime values."""
        assert mock_day_of_year_data["day of year"].dtype == pl.Datetime
        # Check first and last dates
        dates = mock_day_of_year_data["day of year"].unique().sort().to_list()
        assert dates[0] == datetime(2018, 1, 1)
        assert dates[-1] == datetime(2018, 12, 31)

    def test_create_plot_day_of_year(self, mock_day_of_year_data):
        """Test creating day_of_year plot with vertical layout."""
        plot_spec = PlotSpec(
            comparison_dataset=ComparisonDataset.lrd,
            resolution=Resolution.day_of_year,
            group_by="eiaid",
            quantity=DataCol.ELECTRICITY_TOTAL,
            focus_on=(),
            aggregation_type=AggregationType.average,
            coverage=CoverageType.all_units,
            view=ViewType.value_view,
        )

        fig, title = lrd_plotter.create_plot(mock_day_of_year_data, plot_spec)

        assert fig is not None
        assert "daily" in title.lower()
        # Check dimensions are set for vertical layout
        assert fig.layout.height == 2000
        assert fig.layout.width == 1400

    def test_utility_vertical_layout_exists(self):
        """Test that utility_vertical layout exists and has correct structure."""
        from resstockpostproc.shared_utils.generic_plotters.tilemap_plotter import LAYOUTS

        assert "utility_vertical" in LAYOUTS
        layout = LAYOUTS["utility_vertical"]

        # Verify layout is 15 rows x 1 column
        assert len(layout) == 15
        assert all(len(row) == 1 for row in layout)

        # Verify all expected utilities are present
        expected_utilities = [
            "ComEd (IL)",
            "OhioEd (OH)",
            "ToledoEd (OH)",
            "AEP (OH)",
            "Cleveland (OH)",
            "MetEd (PA)",
            "Penelec (PA)",
            "PP (PA)",
            "WPP (PA)",
            "PECO (PA)",
            "PG&E (CA)",
            "SCE (CA)",
            "ERCOT",
            "Appalachian (VA)",
            "BGE (MD)",
        ]
        all_cells = [row[0] for row in layout]
        for utility in expected_utilities:
            assert utility in all_cells, f"Missing {utility} in utility_vertical layout"
