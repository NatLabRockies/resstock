"""Tests for EIA validation functionality using mock data."""

import polars as pl
import pytest

from .resstockpostproc.baseline_validation.data_processing.gather_data import (
    scale_to_eia_customers,
)
from resstockpostproc.baseline_validation.plotters import eia_plotter
from resstockpostproc.baseline_validation.io_managers.get_eia_data import (
    _get_eia_annual_electricity,
    _get_eia_monthly_electricity,
)


class TestEIAValidation:
    """Tests for EIA validation data processing and plotting using mock data."""

    @pytest.fixture(scope="module")
    def eia_annual(self):
        """Load EIA annual electricity data."""
        return _get_eia_annual_electricity(year=2018)

    @pytest.fixture(scope="module")
    def eia_monthly(self):
        """Load EIA monthly electricity data."""
        return _get_eia_monthly_electricity(year=2018)

    @pytest.fixture
    def mock_buildstock_state_data(self):
        """Create mock BuildStock aggregated data by state."""
        return pl.DataFrame({
            "state": ["CA", "TX", "NY"],
            "sample_count": [100, 80, 60],
            "units_count": [5000, 4000, 3000],
            "fuel_use_electricity_total_m_btu": [10000.0, 8000.0, 6000.0],
            "fuel_use_natural_gas_total_m_btu": [5000.0, 6000.0, 4000.0],
        })

    @pytest.fixture
    def mock_buildstock_monthly_data(self):
        """Create mock BuildStock monthly data by state."""
        data = []
        states = ["CA", "TX"]
        months = ["jan", "feb", "mar"]

        for state in states:
            for month in months:
                data.append({
                    "state": state,
                    "month": month,
                    "sample_count": 100,
                    "units_count": 5000,
                    "fuel_use__electricity__total__kwh": 1000000.0,
                    "fuel_use__natural_gas__total__kbtu": 500000.0,
                })

        return pl.DataFrame(data)

    def test_scale_to_eia_customers(self, mock_buildstock_state_data, eia_annual):
        """Test scaling BuildStock data to EIA customer counts."""
        scaled = scale_to_eia_customers(mock_buildstock_state_data, eia_annual, by="state")

        assert isinstance(scaled, pl.DataFrame)
        assert "customer_factor" in scaled.columns
        assert "customers" in scaled.columns
        assert scaled.height > 0

        # Verify that customer_factor was calculated
        assert not scaled["customer_factor"].is_null().all()

    def test_plot_annual_sales_comparison(self, mock_buildstock_state_data, eia_annual):
        """Test creating annual sales comparison plot."""
        buildstock_scaled = scale_to_eia_customers(mock_buildstock_state_data, eia_annual, by="state")
        fig = eia_plotter.plot_annual_sales_comparison(buildstock_scaled, eia_annual, by="state")

        assert fig is not None
        assert len(fig.data) > 0

    def test_plot_customer_counts_comparison_state(self, mock_buildstock_state_data, eia_annual):
        """Test creating customer counts comparison plot for states."""
        # Add customers column to mock data
        eia_customers = eia_annual.group_by("state").agg(pl.col("customers").sum().alias("customers"))
        mock_with_customers = mock_buildstock_state_data.join(eia_customers, on="state", how="left")

        fig = eia_plotter.plot_customer_counts_comparison(mock_with_customers, eia_annual, by="state")

        assert fig is not None
        assert len(fig.data) > 0

    def test_plot_monthly_comparison(self, mock_buildstock_monthly_data, eia_monthly):
        """Test creating monthly comparison plot."""
        # Scale the mock data
        scaled = scale_to_eia_customers(mock_buildstock_monthly_data, eia_monthly, by="state")

        fig = eia_plotter.plot_monthly_comparison(
            scaled, eia_monthly, by="state", selected_entities=["CA"], fuel_type="electricity"
        )

        assert fig is not None
        assert len(fig.data) > 0
