"""Tests for LRD (Load Research Data) validation functionality using mock data."""

import polars as pl
import pytest
from datetime import datetime, timedelta

from resstockpostproc.baseline_validation.plotters import lrd_plotter
from resstockpostproc.baseline_validation.io_managers.get_lrd_data import get_lrd_data


class TestLRDValidation:
    """Tests for LRD validation data processing and plotting using mock data."""

    @pytest.fixture(scope="module")
    def lrd_ref(self):
        """Load LRD reference data."""
        return get_lrd_data(year=2018)

    @pytest.fixture
    def mock_buildstock_timeseries(self):
        """Create mock BuildStock timeseries data."""
        # Create hourly data for a few days
        data = []
        start_time = datetime(2018, 1, 1)
        eiaids = [7451, 7159, 10200]  # Sample EIA IDs from LRD data

        for eiaid in eiaids:
            for hour in range(24 * 7):  # 7 days of hourly data
                time = start_time + timedelta(hours=hour)
                data.append({
                    "eiaid": eiaid,
                    "time": time,
                    "fuel_use__electricity__total__kwh": 1000.0 + hour * 10,  # Varying load
                    "sample_count": 100,
                    "units_count": 5000,
                })

        return pl.DataFrame(data)

    def test_calculate_load_duration_curve(self, mock_buildstock_timeseries):
        """Test calculating load duration curve from timeseries."""
        # Filter to single utility for simplicity
        single_utility = mock_buildstock_timeseries.filter(
            pl.col("eiaid") == mock_buildstock_timeseries["eiaid"].unique()[0]
        )

        ldc = lrd_plotter.calculate_load_duration_curve(
            single_utility, value_col="fuel_use__electricity__total__kwh", group_col=None
        )

        assert isinstance(ldc, pl.DataFrame)
        assert "percentile" in ldc.columns
        assert "fuel_use__electricity__total__kwh" in ldc.columns
        assert ldc.height > 0

        # Check percentiles are in ascending order
        percentiles = ldc["percentile"].to_list()
        assert percentiles == sorted(percentiles)

    def test_prepare_buildstock_ldc_data(self, mock_buildstock_timeseries):
        """Test preparing BuildStock LDC data."""
        ldc = lrd_plotter.prepare_buildstock_ldc_data(
            mock_buildstock_timeseries, per_unit=True, group_col="eiaid"
        )

        assert isinstance(ldc, pl.DataFrame)
        assert "percentile" in ldc.columns
        assert "eiaid" in ldc.columns
        assert ldc.height > 0

    def test_plot_load_duration_curve(self, mock_buildstock_timeseries, lrd_ref):
        """Test plotting load duration curve."""
        # Prepare data for single utility
        single_eiaid = mock_buildstock_timeseries["eiaid"].unique()[0]
        bs_single = mock_buildstock_timeseries.filter(pl.col("eiaid") == single_eiaid)
        lrd_single = lrd_ref.filter(pl.col("eiaid") == single_eiaid)

        # Calculate LDCs
        bs_ldc = lrd_plotter.prepare_buildstock_ldc_data(bs_single, per_unit=True, group_col=None)
        lrd_ldc = lrd_plotter.calculate_load_duration_curve(lrd_single, value_col="kwh_per_meter", group_col=None)

        # Create plot
        fig = lrd_plotter.plot_load_duration_curve(
            bs_ldc, lrd_ldc, value_col="kwh_per_unit", entity_name=f"Utility {single_eiaid}"
        )

        assert fig is not None
        assert len(fig.data) >= 1  # At least BuildStock trace

    def test_plot_multi_utility_ldc(self, mock_buildstock_timeseries, lrd_ref):
        """Test plotting LDCs for multiple utilities."""
        # Prepare BuildStock LDC data
        bs_ldc = lrd_plotter.prepare_buildstock_ldc_data(mock_buildstock_timeseries, per_unit=True, group_col="eiaid")

        # Get utilities that exist in both datasets
        bs_utilities = mock_buildstock_timeseries["eiaid"].unique().to_list()
        lrd_ldc = lrd_plotter.calculate_load_duration_curve(
            lrd_ref.filter(pl.col("eiaid").is_in(bs_utilities)), value_col="kwh_per_meter", group_col="eiaid"
        )

        # Create plot (limit to 3 utilities)
        fig = lrd_plotter.plot_multi_utility_ldc(bs_ldc, lrd_ldc, group_col="eiaid", max_utilities=3)

        assert fig is not None
        assert len(fig.data) >= 1
