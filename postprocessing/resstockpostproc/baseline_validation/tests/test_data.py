"""Tests for reference data loading."""

import polars as pl
import pytest

from resstockpostproc.baseline_validation.io_managers.get_eia_data import (
    _get_eia_annual_electricity,
    _get_eia_monthly_electricity,
    _get_eia_monthly_gas,
)
from resstockpostproc.baseline_validation.io_managers.get_lrd_data import get_lrd_data


class TestData:
    """Tests for EIA and LRD data loading functions."""

    def test_eia_annual_electricity(self):
        """Test loading EIA annual electricity data."""
        eia_annual = _get_eia_annual_electricity(year=2018)
        assert isinstance(eia_annual, pl.DataFrame)
        assert eia_annual.height > 0
        assert "units_count" in eia_annual.columns
        assert "electricity_total_value" in eia_annual.columns
        assert "state" in eia_annual.columns or "eiaid" in eia_annual.columns

    def test_eia_monthly_electricity(self):
        """Test loading EIA monthly electricity data."""
        eia_monthly_elec = _get_eia_monthly_electricity(year=2018)
        assert isinstance(eia_monthly_elec, pl.DataFrame)
        assert eia_monthly_elec.height > 0
        assert "month" in eia_monthly_elec.columns
        assert "units_count" in eia_monthly_elec.columns
        assert "electricity_total_value" in eia_monthly_elec.columns

    def test_eia_monthly_gas(self):
        """Test loading EIA monthly natural gas data."""
        eia_monthly_gas = _get_eia_monthly_gas(year=2018)
        assert isinstance(eia_monthly_gas, pl.DataFrame)
        assert eia_monthly_gas.height > 0
        assert "month" in eia_monthly_gas.columns
        assert "natural_gas_total_customers" in eia_monthly_gas.columns

    def test_lrd_data(self):
        """Test loading LRD data."""
        lrd_data = get_lrd_data(year=2018)
        assert isinstance(lrd_data, pl.DataFrame)
        assert lrd_data.height > 0
        assert "eiaid" in lrd_data.columns
        assert "electricity_total_value" in lrd_data.columns
        assert "time" in lrd_data.columns

    def test_lrd_data_invalid_year(self):
        """Test that loading LRD data for invalid year raises error."""
        with pytest.raises(ValueError, match="LRD data only available for 2018"):
            get_lrd_data(year=2019)
    