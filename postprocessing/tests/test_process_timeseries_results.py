"""
Tests for process_timeseries_results.py

Strategy: Mock BuildStockQuery to avoid AWS/Athena dependency.
Validate SQL string generation for structural correctness using
string assertions and optionally sqlglot for syntax validation.
"""

import re
from unittest.mock import MagicMock, patch
from types import SimpleNamespace

import pandas as pd
import pytest

from resstockpostproc.process_timeseries_results import (
    create_query_part_conditional_county_utc_offset,
    create_query_part_est_time,
    create_query_part_wrap_time_to_sim_year,
    create_query_oedi_timeseries,
    energy_unit_conv_to_kwh,
    get_county_utc_offset,
    read_options_lookup,
    options_lookup_file,
)


# =============================================================================
# Fixtures
# =============================================================================


@pytest.fixture
def mock_bsq_with_timeutc():
    """Mock BuildStockQuery with timeutc column (newer schema)."""
    bsq = MagicMock()
    bsq.table_name = "test_run"

    # Simulate timeseries columns
    ts_columns = [
        "building_id", "upgrade", "timeutc",
        "electricity_heating_kwh",
        "electricity_cooling_kwh",
        "natural_gas_heating_therm",
        "total_site_electricity_kwh",
        "total_site_natural_gas_therm",
        "total_site_energy_mbtu",
    ]
    bsq.ts_table.columns = [SimpleNamespace(name=c) for c in ts_columns]

    # Mock execute to return time data
    time_df = pd.DataFrame({
        "time": pd.to_datetime(["2018-01-01 01:00:00", "2018-01-01 02:00:00"])
    })
    convention_df = pd.DataFrame({"col": ["end"]})

    def mock_execute(query):
        if "timeseries_timestamp_convention" in query:
            return convention_df
        if "DISTINCT" in query and "time" in query:
            return time_df
        return pd.DataFrame()

    bsq.execute.side_effect = mock_execute
    return bsq


@pytest.fixture
def mock_bsq_without_timeutc():
    """Mock BuildStockQuery without timeutc column (older schema needing county-based offset)."""
    bsq = MagicMock()
    bsq.table_name = "test_run"

    ts_columns = [
        "building_id", "upgrade", "time",
        "electricity_heating_kwh",
        "natural_gas_heating_therm",
        "propane_heating_mbtu",
    ]
    bsq.ts_table.columns = [SimpleNamespace(name=c) for c in ts_columns]

    time_df = pd.DataFrame({
        "time": pd.to_datetime(["2018-01-01 01:00:00", "2018-01-01 02:00:00"])
    })
    convention_df = pd.DataFrame({"col": ["begin"]})

    def mock_execute(query):
        if "timeseries_timestamp_convention" in query:
            return convention_df
        if "DISTINCT" in query and "time" in query:
            return time_df
        return pd.DataFrame()

    bsq.execute.side_effect = mock_execute
    return bsq


# =============================================================================
# Tests: read_options_lookup and get_county_utc_offset
# =============================================================================


class TestOptionsLookupAndCountyUtcOffset:
    def test_options_lookup_file_exists(self):
        assert options_lookup_file.exists(), (
            f"options_lookup.tsv not found at {options_lookup_file}"
        )

    def test_read_options_lookup_returns_dataframe(self):
        df = read_options_lookup()
        assert isinstance(df, pd.DataFrame)
        assert len(df) > 0
        assert "Parameter Name" in df.columns
        assert "Option Name" in df.columns
        assert "Measure Arg 4" in df.columns

    def test_read_options_lookup_has_county_rows(self):
        df = read_options_lookup()
        county_rows = df[df["Parameter Name"] == "County"]
        assert len(county_rows) > 0, "No County rows found in options_lookup"

    def test_get_county_utc_offset_returns_dict(self):
        result = get_county_utc_offset()
        assert isinstance(result, dict)
        assert len(result) > 0

    def test_get_county_utc_offset_values_are_integers(self):
        result = get_county_utc_offset()
        for county, offset in result.items():
            assert isinstance(offset, int), (
                f"Offset for '{county}' is {type(offset)}, expected int"
            )

    def test_get_county_utc_offset_values_in_valid_range(self):
        """UTC offsets for US counties should be between -10 and -4."""
        result = get_county_utc_offset()
        for county, offset in result.items():
            assert -10 <= offset <= -4, (
                f"Offset {offset} for '{county}' outside expected range [-10, -4]"
            )

    def test_get_county_utc_offset_known_counties(self):
        """Spot-check known counties and their expected offsets."""
        result = get_county_utc_offset()
        # Eastern Time counties should be -5
        eastern_counties = [k for k in result if k.startswith("NY,")]
        assert len(eastern_counties) > 0
        for county in eastern_counties:
            assert result[county] == -5, (
                f"Expected -5 for '{county}', got {result[county]}"
            )

        # Mountain Time counties should be -7
        mountain_counties = [k for k in result if k.startswith("CO,")]
        assert len(mountain_counties) > 0
        for county in mountain_counties:
            assert result[county] == -7, (
                f"Expected -7 for '{county}', got {result[county]}"
            )

    def test_get_county_utc_offset_count(self):
        """Should have a county entry for each County row in options_lookup."""
        df = read_options_lookup()
        county_rows = df[df["Parameter Name"] == "County"]
        result = get_county_utc_offset()
        assert len(result) == len(county_rows), (
            f"Expected {len(county_rows)} entries, got {len(result)}"
        )


# =============================================================================
# Tests: create_query_part_wrap_time_to_sim_year
# =============================================================================


class TestWrapTimeToSimYear:
    def test_basic_output(self):
        sql = create_query_part_wrap_time_to_sim_year("timestamp", 2018)
        assert "DATE_ADD('year'" in sql
        assert "2018" in sql
        assert 'YEAR("timestamp")' in sql
        assert 'AS "timestamp"' in sql

    def test_different_year(self):
        sql = create_query_part_wrap_time_to_sim_year("timestamp", 2022)
        assert "2022" in sql


# =============================================================================
# Tests: create_query_part_conditional_county_utc_offset
# =============================================================================


class TestCountyUtcOffset:
    @patch("resstockpostproc.process_timeseries_results.get_county_utc_offset")
    def test_case_statement_structure(self, mock_offsets):
        mock_offsets.return_value = {
            "NY, Albany County": -5,
            "CO, Denver County": -7,
            "CA, Los Angeles County": -8,
            "WA, King County": -8,
        }
        sql = create_query_part_conditional_county_utc_offset()

        assert sql.startswith("CASE")
        assert "ELSE 0 END" in sql
        assert "WHEN" in sql
        # Check that counties with same offset are grouped
        assert "'CA, Los Angeles County'" in sql
        assert "'WA, King County'" in sql
        # Both -8 counties should be in the same WHEN clause
        line_with_la = [l for l in sql.split("\n") if "Los Angeles" in l][0]
        assert "King County" in line_with_la

    @patch("resstockpostproc.process_timeseries_results.get_county_utc_offset")
    def test_single_county(self, mock_offsets):
        mock_offsets.return_value = {"NY, Albany County": -5}
        sql = create_query_part_conditional_county_utc_offset()
        assert "WHEN" in sql
        assert "-5" in sql


# =============================================================================
# Tests: create_query_part_est_time
# =============================================================================


class TestEstTime:
    def test_with_timeutc_end_convention(self, mock_bsq_with_timeutc):
        sql, sim_year = create_query_part_est_time(mock_bsq_with_timeutc, "timestamp", has_timeutc=True)

        assert sim_year == 2018
        assert "timeutc" in sql
        assert "DATE_ADD" in sql
        assert 'AS "timestamp"' in sql
        # end convention with 1-hour timestep: delta = -5 - 1 = -6
        assert "-6" in sql

    @patch("resstockpostproc.process_timeseries_results.create_query_part_conditional_county_utc_offset")
    def test_without_timeutc_begin_convention(self, mock_county_sql, mock_bsq_without_timeutc):
        mock_county_sql.return_value = "CASE WHEN 1=1 THEN -5 ELSE 0 END"
        sql, sim_year = create_query_part_est_time(mock_bsq_without_timeutc, "timestamp", has_timeutc=False)

        assert sim_year == 2018
        assert '"time"' in sql
        assert "DATE_ADD" in sql
        assert 'AS "timestamp"' in sql
        # begin convention: delta = -5 (no timestep adjustment)
        assert "-5" in sql
        # Should include county offset subtraction
        assert "CASE WHEN" in sql

    def test_unsupported_convention_raises(self, mock_bsq_with_timeutc):
        # Override execute to return unsupported convention
        mock_bsq_with_timeutc.execute.side_effect = lambda q: (
            pd.DataFrame({"col": ["middle"]}) if "convention" in q
            else pd.DataFrame({"time": pd.to_datetime(["2018-01-01 01:00", "2018-01-01 02:00"])})
        )
        with pytest.raises(NotImplementedError, match="middle"):
            create_query_part_est_time(mock_bsq_with_timeutc, "timestamp", has_timeutc=True)


# =============================================================================
# Tests: create_query_oedi_timeseries (integration of SQL generation)
# =============================================================================


class TestCreateQueryOediTimeseries:
    def test_basic_sql_structure_with_timeutc(self, mock_bsq_with_timeutc):
        sql = create_query_oedi_timeseries(mock_bsq_with_timeutc, partition_col=None)

        # Should have CTE structure
        assert "WITH bl_table AS" in sql
        assert "renamed_table AS" in sql
        # Should have final SELECT
        assert "SELECT" in sql
        assert "FROM renamed_table" in sql
        # Should NOT have county join since timeutc is present
        assert "in.county" not in sql

    def test_includes_partition_col(self, mock_bsq_with_timeutc):
        sql = create_query_oedi_timeseries(mock_bsq_with_timeutc, partition_col="upgrade")
        assert '"upgrade"' in sql

    def test_invalid_partition_col_raises(self, mock_bsq_with_timeutc):
        with pytest.raises(AssertionError, match="not found in table schema"):
            create_query_oedi_timeseries(mock_bsq_with_timeutc, partition_col="nonexistent_col")

    def test_energy_columns_renamed(self, mock_bsq_with_timeutc):
        sql = create_query_oedi_timeseries(mock_bsq_with_timeutc)

        # kwh columns should pass through
        assert '"electricity_heating_kwh" AS "out.electricity.heating.energy_consumption"' in sql
        # therm columns should have conversion factor
        assert f'{energy_unit_conv_to_kwh["therm"]} * "natural_gas_heating_therm"' in sql
        # mbtu columns should have conversion factor
        assert f'{energy_unit_conv_to_kwh["mbtu"]} * "total_site_energy_mbtu"' in sql

    def test_intensity_columns_use_renamed_cols(self, mock_bsq_with_timeutc):
        sql = create_query_oedi_timeseries(mock_bsq_with_timeutc)

        # Intensity should reference the renamed column, not the original
        assert '"out.electricity.heating.energy_consumption" / "in.sqft"' in sql
        assert '"out.electricity.heating.energy_consumption_intensity"' in sql
        # Should NOT reference original column names in intensity calc
        assert '"electricity_heating_kwh" / "in.sqft"' not in sql

    @patch("resstockpostproc.process_timeseries_results.create_query_part_conditional_county_utc_offset")
    def test_without_timeutc_includes_county(self, mock_county_sql, mock_bsq_without_timeutc):
        mock_county_sql.return_value = "CASE WHEN 1=1 THEN -5 ELSE 0 END"
        sql = create_query_oedi_timeseries(mock_bsq_without_timeutc)

        # Should include county in baseline CTE
        assert "in.county" in sql

    def test_no_consecutive_commas(self, mock_bsq_with_timeutc):
        """Regression: ensure no empty strings produce ', ,' in SQL."""
        sql = create_query_oedi_timeseries(mock_bsq_with_timeutc, partition_col=None)
        assert ", ," not in sql
        assert ",," not in sql

    def test_total_site_columns(self, mock_bsq_with_timeutc):
        """Test that total_site_* pattern is matched correctly."""
        sql = create_query_oedi_timeseries(mock_bsq_with_timeutc)
        assert "out.electricity.total.energy_consumption" in sql
        assert "out.natural_gas.total.energy_consumption" in sql

    def test_total_site_energy_column(self, mock_bsq_with_timeutc):
        """Test that total_site_energy_* pattern is matched correctly."""
        sql = create_query_oedi_timeseries(mock_bsq_with_timeutc)
        assert "out.total.site_energy.energy_consumption" in sql


# =============================================================================
# Tests: SQL syntax validation (optional, requires sqlglot)
# =============================================================================


class TestSqlSyntax:
    @pytest.fixture(autouse=True)
    def _check_sqlglot(self):
        pytest.importorskip("sqlglot")

    def test_wrap_time_parses(self):
        import sqlglot
        sql = create_query_part_wrap_time_to_sim_year("timestamp", 2018)
        # Wrap in a SELECT to make it a complete statement
        full_sql = f"SELECT {sql} FROM t"
        # Should parse without error (using trino dialect for Athena)
        sqlglot.parse_one(full_sql, dialect="trino")

    def test_full_query_parses(self, mock_bsq_with_timeutc):
        import sqlglot
        sql = create_query_oedi_timeseries(mock_bsq_with_timeutc)
        # Should parse as valid Trino/Presto SQL
        sqlglot.parse_one(sql, dialect="trino")
