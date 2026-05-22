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
    _build_column_sql_expr,
    _build_county_utc_offset_case_sql_expr,
    _build_est_time_sql_expr,
    _build_intensity_columns,
    _build_renamed_columns,
    _build_wrap_time_to_sim_year_sql_expr,
    _get_column_mapping_config,
    _reformat_raw_column,
    _UNIT_CONVERSIONS,
    create_query_oedi_timeseries,
    _get_county_utc_offset,
    _read_options_lookup,
    options_lookup_file,
)

# =============================================================================
# Fixtures
# =============================================================================


def _make_col(name, partition=False):
    """Helper to create a mock column with dialect_options."""
    ns = SimpleNamespace(name=name)
    ns.dialect_options = {"awsathena": {"partition": partition}} if partition else {}
    return ns


@pytest.fixture
def mock_bsq_with_timeutc():
    """Mock BuildStockQuery with timeutc column (newer schema)."""
    bsq = MagicMock()
    bsq.table_name = "test_run"

    # Simulate timeseries columns
    ts_columns = [
        "building_id",
        "upgrade",
        "timeutc",
        "end_use__electricity__heating__kwh",
        "end_use__electricity__cooling__kwh",
        "end_use__natural_gas__heating__therm",
        "fuel_use__electricity__total__kwh",
        "fuel_use__natural_gas__total__therm",
        "energy_use__total__mbtu",
    ]
    bsq.ts_table.columns = [
        _make_col(c, partition=(c == "upgrade")) for c in ts_columns
    ]

    # Mock execute to return time data
    time_df = pd.DataFrame(
        {"time": pd.to_datetime(["2018-01-01 01:00:00", "2018-01-01 02:00:00"])}
    )
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
        "building_id",
        "upgrade",
        "time",
        "end_use__electricity__heating__kwh",
        "end_use__natural_gas__heating__therm",
        "end_use__propane__heating__mbtu",
    ]
    bsq.ts_table.columns = [
        _make_col(c, partition=(c == "upgrade")) for c in ts_columns
    ]

    time_df = pd.DataFrame(
        {"time": pd.to_datetime(["2018-01-01 01:00:00", "2018-01-01 02:00:00"])}
    )
    convention_df = pd.DataFrame({"col": ["begin"]})

    def mock_execute(query):
        if "timeseries_timestamp_convention" in query:
            return convention_df
        if "DISTINCT" in query and "time" in query:
            return time_df
        return pd.DataFrame()

    bsq.execute.side_effect = mock_execute
    return bsq

    bsq.execute.side_effect = mock_execute
    return bsq


# =============================================================================
# Tests: _read_options_lookup and _get_county_utc_offset
# =============================================================================


class TestOptionsLookupAndCountyUtcOffset:
    def test_options_lookup_file_exists(self):
        assert (
            options_lookup_file.exists()
        ), f"options_lookup.tsv not found at {options_lookup_file}"

    def test_read_options_lookup_returns_dataframe(self):
        df = _read_options_lookup()
        assert isinstance(df, pd.DataFrame)
        assert len(df) > 0
        assert "Parameter Name" in df.columns
        assert "Option Name" in df.columns
        assert "Measure Arg 4" in df.columns

    def test_read_options_lookup_has_county_rows(self):
        df = _read_options_lookup()
        county_rows = df[df["Parameter Name"] == "County"]
        assert len(county_rows) > 0, "No County rows found in options_lookup"

    def test_get_county_utc_offset_returns_dict(self):
        result = _get_county_utc_offset()
        assert isinstance(result, dict)
        assert len(result) > 0

    def test_get_county_utc_offset_values_are_integers(self):
        result = _get_county_utc_offset()
        for county, offset in result.items():
            assert isinstance(
                offset, int
            ), f"Offset for '{county}' is {type(offset)}, expected int"

    def test_get_county_utc_offset_values_in_valid_range(self):
        """UTC offsets for US counties should be between -10 and -4."""
        result = _get_county_utc_offset()
        for county, offset in result.items():
            assert (
                -10 <= offset <= -4
            ), f"Offset {offset} for '{county}' outside expected range [-10, -4]"

    def test_get_county_utc_offset_known_counties(self):
        """Spot-check known counties and their expected offsets."""
        result = _get_county_utc_offset()
        # Eastern Time counties should be -5
        eastern_counties = [k for k in result if k.startswith("NY,")]
        assert len(eastern_counties) > 0
        for county in eastern_counties:
            assert (
                result[county] == -5
            ), f"Expected -5 for '{county}', got {result[county]}"

        # Mountain Time counties should be -7
        mountain_counties = [k for k in result if k.startswith("CO,")]
        assert len(mountain_counties) > 0
        for county in mountain_counties:
            assert (
                result[county] == -7
            ), f"Expected -7 for '{county}', got {result[county]}"

    def test_get_county_utc_offset_count(self):
        """Should have a county entry for each County row in options_lookup."""
        df = _read_options_lookup()
        county_rows = df[df["Parameter Name"] == "County"]
        result = _get_county_utc_offset()
        assert len(result) == len(
            county_rows
        ), f"Expected {len(county_rows)} entries, got {len(result)}"


# =============================================================================
# Tests: _build_wrap_time_to_sim_year_sql_expr
# =============================================================================


class TestWrapTimeToSimYear:
    def test_basic_output(self):
        sql = _build_wrap_time_to_sim_year_sql_expr("timestamp", 2018)
        assert "DATE_ADD('year'" in sql
        assert "2018" in sql
        assert 'YEAR("timestamp")' in sql
        assert 'AS "timestamp"' in sql

    def test_different_year(self):
        sql = _build_wrap_time_to_sim_year_sql_expr("timestamp", 2022)
        assert "2022" in sql


# =============================================================================
# Tests: _build_county_utc_offset_case_sql_expr
# =============================================================================


class TestCountyUtcOffset:
    @patch("resstockpostproc.process_timeseries_results._get_county_utc_offset")
    def test_case_statement_structure(self, mock_offsets):
        mock_offsets.return_value = {
            "NY, Albany County": -5,
            "CO, Denver County": -7,
            "CA, Los Angeles County": -8,
            "WA, King County": -8,
        }
        sql = _build_county_utc_offset_case_sql_expr()

        assert sql.startswith("CASE")
        assert "ELSE 0 END" in sql
        assert "WHEN" in sql
        # Check that counties with same offset are grouped
        assert "'CA, Los Angeles County'" in sql
        assert "'WA, King County'" in sql
        # Both -8 counties should be in the same WHEN clause
        line_with_la = [l for l in sql.split("\n") if "Los Angeles" in l][0]
        assert "King County" in line_with_la

    @patch("resstockpostproc.process_timeseries_results._get_county_utc_offset")
    def test_single_county(self, mock_offsets):
        mock_offsets.return_value = {"NY, Albany County": -5}
        sql = _build_county_utc_offset_case_sql_expr()
        assert "WHEN" in sql
        assert "-5" in sql


# =============================================================================
# Tests: _build_est_time_sql_expr
# =============================================================================


class TestEstTime:
    def test_with_timeutc_end_convention(self, mock_bsq_with_timeutc):
        sql, sim_year = _build_est_time_sql_expr(
            mock_bsq_with_timeutc, "timestamp", has_timeutc=True
        )

        assert sim_year == 2018
        assert "timeutc" in sql
        assert "DATE_ADD" in sql
        assert 'AS "timestamp"' in sql
        # end convention with 1-hour timestep: delta_minutes = -5*60 - 60 = -360
        assert "-360" in sql

    @patch(
        "resstockpostproc.process_timeseries_results._build_county_utc_offset_case_sql_expr"
    )
    def test_without_timeutc_begin_convention(
        self, mock_county_sql, mock_bsq_without_timeutc
    ):
        mock_county_sql.return_value = "CASE WHEN 1=1 THEN -5 ELSE 0 END"
        sql, sim_year = _build_est_time_sql_expr(
            mock_bsq_without_timeutc, "timestamp", has_timeutc=False
        )

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
            pd.DataFrame({"col": ["middle"]})
            if "convention" in q
            else pd.DataFrame(
                {"time": pd.to_datetime(["2018-01-01 01:00", "2018-01-01 02:00"])}
            )
        )
        with pytest.raises(NotImplementedError, match="middle"):
            _build_est_time_sql_expr(
                mock_bsq_with_timeutc, "timestamp", has_timeutc=True
            )


# =============================================================================
# Tests: create_query_oedi_timeseries (integration of SQL generation)
# =============================================================================


class TestCreateQueryOediTimeseries:
    def test_basic_sql_structure_with_timeutc(self, mock_bsq_with_timeutc):
        sql = create_query_oedi_timeseries(mock_bsq_with_timeutc)

        # Should have CTE structure
        assert "WITH bl_table AS" in sql
        assert "renamed_table AS" in sql
        # Should have final SELECT
        assert "SELECT" in sql
        assert "FROM renamed_table" in sql
        # Should NOT have county join since timeutc is present
        assert "in.county" not in sql

    def test_includes_partition_col_from_dialect_options(self, mock_bsq_with_timeutc):
        """Partition cols detected via dialect_options should appear in SQL."""
        sql = create_query_oedi_timeseries(mock_bsq_with_timeutc)
        # 'upgrade' is marked as partition in the fixture
        assert '"upgrade"' in sql

    def test_energy_columns_renamed(self, mock_bsq_with_timeutc):
        sql = create_query_oedi_timeseries(mock_bsq_with_timeutc)

        # kwh columns should pass through (mult=1.0)
        assert "out.electricity.heating.energy_consumption..kwh" in sql
        # therm columns should have conversion factor
        assert f'{_UNIT_CONVERSIONS["therm"][1]}' in sql
        # mbtu columns should have conversion factor
        assert f'{_UNIT_CONVERSIONS["mbtu"][1]}' in sql

    def test_intensity_columns_present(self, mock_bsq_with_timeutc):
        sql = create_query_oedi_timeseries(mock_bsq_with_timeutc)

        # Intensity should reference the renamed column, not the original
        assert '/ "in.sqft"' in sql
        assert "_intensity" in sql

    @patch(
        "resstockpostproc.process_timeseries_results._build_county_utc_offset_case_sql_expr"
    )
    def test_without_timeutc_includes_county(
        self, mock_county_sql, mock_bsq_without_timeutc
    ):
        mock_county_sql.return_value = "CASE WHEN 1=1 THEN -5 ELSE 0 END"
        sql = create_query_oedi_timeseries(mock_bsq_without_timeutc)

        # Should include county in baseline CTE
        assert "in.county" in sql

    def test_no_consecutive_commas(self, mock_bsq_with_timeutc):
        """Regression: ensure no empty strings produce ', ,' in SQL."""
        sql = create_query_oedi_timeseries(mock_bsq_with_timeutc)
        assert ", ," not in sql
        assert ",," not in sql

    def test_ochre_workflow_skips_intensity(self, mock_bsq_with_timeutc):
        """ochre_workflow=True should not generate intensity columns."""
        sql = create_query_oedi_timeseries(
            mock_bsq_with_timeutc, ochre_workflow=True
        )
        assert "_intensity" not in sql
        assert '"in.sqft"' not in sql

    def test_ochre_workflow_passes_through_unmapped(self, mock_bsq_with_timeutc):
        """ochre_workflow=True should include unmapped columns."""
        # Add an unmapped column to the fixture
        mock_bsq_with_timeutc.ts_table.columns.append(
            _make_col("custom_ochre_metric")
        )
        sql = create_query_oedi_timeseries(
            mock_bsq_with_timeutc, ochre_workflow=True
        )
        assert '"custom_ochre_metric"' in sql

    def test_standard_workflow_excludes_unmapped(self, mock_bsq_with_timeutc):
        """Standard workflow should NOT include unmapped columns."""
        mock_bsq_with_timeutc.ts_table.columns.append(
            _make_col("custom_ochre_metric")
        )
        sql = create_query_oedi_timeseries(
            mock_bsq_with_timeutc, ochre_workflow=False
        )
        assert "custom_ochre_metric" not in sql

    def test_structural_cols_not_duplicated_in_ochre(self, mock_bsq_with_timeutc):
        """building_id, upgrade, time should not appear as duplicates in ochre mode."""
        sql = create_query_oedi_timeseries(
            mock_bsq_with_timeutc, ochre_workflow=True
        )
        # 'building_id' should not appear in the ts_exprs section (it's in id_cols as bldg_id)
        # Count occurrences of '"building_id"' — should only appear in the JOIN ON clause
        assert sql.count('"building_id"') <= 2  # baseline CTE alias + JOIN ON


# =============================================================================
# Tests: SQL syntax validation (optional, requires sqlglot)
# =============================================================================


class TestSqlSyntax:
    @pytest.fixture(autouse=True)
    def _check_sqlglot(self):
        pytest.importorskip("sqlglot")

    def test_wrap_time_parses(self):
        import sqlglot

        sql = _build_wrap_time_to_sim_year_sql_expr("timestamp", 2018)
        # Wrap in a SELECT to make it a complete statement
        full_sql = f"SELECT {sql} FROM t"
        # Should parse without error (using trino dialect for Athena)
        sqlglot.parse_one(full_sql, dialect="trino")

    def test_full_query_parses(self, mock_bsq_with_timeutc):
        import sqlglot

        sql = create_query_oedi_timeseries(mock_bsq_with_timeutc)
        # Should parse as valid Trino/Presto SQL
        sqlglot.parse_one(sql, dialect="trino")


# =============================================================================
# Tests: _build_column_sql_expr (unit conversion SQL generation)
# =============================================================================


class TestBuildColumnSqlExpr:
    def test_kwh_passthrough(self):
        """kwh columns should pass through without multiplication."""
        result = _build_column_sql_expr(
            "electricity_heating_kwh",
            "out.electricity.heating.energy_consumption",
            "kwh",
            1.0,
        )
        assert (
            result
            == '"electricity_heating_kwh" AS "out.electricity.heating.energy_consumption"'
        )

    def test_therm_conversion(self):
        """therm columns should be multiplied by the therm->kwh factor."""
        result = _build_column_sql_expr(
            "natural_gas_heating_therm",
            "out.natural_gas.heating.energy_consumption",
            "therm",
            None,
        )
        expected_factor = _UNIT_CONVERSIONS["therm"][1]
        assert f'{expected_factor} * "natural_gas_heating_therm"' in result
        assert 'AS "out.natural_gas.heating.energy_consumption"' in result

    def test_mbtu_conversion(self):
        """mbtu columns should be multiplied by the mbtu->kwh factor."""
        result = _build_column_sql_expr(
            "total_site_energy_mbtu",
            "out.total.site_energy.energy_consumption",
            "mbtu",
            None,
        )
        expected_factor = _UNIT_CONVERSIONS["mbtu"][1]
        assert f'{expected_factor} * "total_site_energy_mbtu"' in result

    def test_kbtu_conversion_with_mult(self):
        """kbtu columns with explicit mult should use mult."""
        mult = _UNIT_CONVERSIONS["kbtu"][1]
        result = _build_column_sql_expr(
            "end_use__electricity__heating__kbtu",
            "out.electricity.heating.energy_consumption..kwh",
            "kbtu",
            mult,
        )
        assert f'{mult} * "end_use__electricity__heating__kbtu"' in result

    def test_fahrenheit_to_celsius(self):
        """F columns should use (col - 32) * 5/9 formula."""
        result = _build_column_sql_expr(
            "temperature__conditioned_space__f",
            "out.indoor_temperature.conditioned_space..c",
            "f",
            None,
        )
        assert '("temperature__conditioned_space__f" - 32) * 5.0 / 9.0' in result
        assert 'AS "out.indoor_temperature.conditioned_space..c"' in result

    def test_btu_per_hr_ft2_conversion(self):
        """btu/(hr*ft^2) should use 3.15459 multiplier."""
        mult = _UNIT_CONVERSIONS["btu/(hr*ft^2)"][1]
        result = _build_column_sql_expr(
            "weather__diffuse_solar_radiation__btu/(hr*ft^2)",
            "out.weather.diffuse_solar_radiation..watt_per_m2",
            "btu/(hr*ft^2)",
            mult,
        )
        assert f"{mult} * " in result

    def test_percentage_passthrough(self):
        """Percentage columns (mult=1.0) should pass through."""
        result = _build_column_sql_expr(
            "relative_humidity__conditioned_space__%",
            "out.indoor_relative_humidity.conditioned_space..percentage",
            "%",
            1.0,
        )
        assert (
            result
            == '"relative_humidity__conditioned_space__%" AS "out.indoor_relative_humidity.conditioned_space..percentage"'
        )


# =============================================================================
# Tests: _reformat_raw_column (column name mapping)
# =============================================================================


class TestReformatRawColumn:
    """Test the unified column name reformatter."""

    # --- Pattern 1: end_use__<fuel>__<enduse>__<unit> ---
    def test_end_use_electricity_kwh(self):
        new_col, unit, mult = _reformat_raw_column(
            "end_use__electricity__heating__kbtu"
        )
        assert new_col == "out.electricity.heating.energy_consumption..kwh"
        assert unit == "kbtu"
        assert mult == pytest.approx(0.293071)

    def test_end_use_natural_gas(self):
        new_col, unit, mult = _reformat_raw_column(
            "end_use__natural_gas__hot_water__kbtu"
        )
        assert new_col == "out.natural_gas.hot_water.energy_consumption..kwh"
        assert unit == "kbtu"

    def test_end_use_remap_ev_charging(self):
        new_col, _, _ = _reformat_raw_column(
            "end_use__electricity__electric_vehicle_charging__kbtu"
        )
        assert "ev_charging" in new_col

    def test_end_use_remap_hp_backup(self):
        new_col, _, _ = _reformat_raw_column(
            "end_use__electricity__heating_heat_pump_backup__kbtu"
        )
        assert "heating_hp_bkup" in new_col

    # --- Pattern 2: fuel_use__<fuel>__<agg>__<unit> ---
    def test_fuel_use_total(self):
        new_col, unit, mult = _reformat_raw_column("fuel_use__electricity__total__kbtu")
        assert new_col == "out.electricity.total.energy_consumption..kwh"
        assert unit == "kbtu"

    def test_fuel_use_net(self):
        new_col, unit, mult = _reformat_raw_column("fuel_use__natural_gas__net__kbtu")
        assert new_col == "out.natural_gas.net.energy_consumption..kwh"

    # --- Pattern 3: energy_use__<agg>__<unit> ---
    def test_energy_use_total(self):
        new_col, unit, mult = _reformat_raw_column("energy_use__total__kbtu")
        assert new_col == "out.site_energy.total.energy_consumption..kwh"

    def test_energy_use_net(self):
        new_col, unit, mult = _reformat_raw_column("energy_use__net__kbtu")
        assert new_col == "out.site_energy.net.energy_consumption..kwh"

    # --- Pattern 4: hot_water__<enduse>__<unit> ---
    def test_hot_water(self):
        new_col, unit, mult = _reformat_raw_column("hot_water__delivered__gal")
        assert new_col == "out.hot_water.delivered..gal"
        assert unit == "gal"
        assert mult == 1.0

    # --- Pattern 5: load__<type>__<subtype>__<unit> ---
    def test_load(self):
        new_col, unit, mult = _reformat_raw_column("load__heating__total__kbtu")
        assert new_col == "out.load.heating.total..kwh"
        assert unit == "kbtu"

    # --- Pattern 6: unmet_hours__<type>__<unit> ---
    def test_unmet_hours(self):
        new_col, unit, mult = _reformat_raw_column("unmet_hours__heating__hr")
        assert new_col == "out.unmet_hours.heating..hour"
        assert unit == "hr"
        assert mult == 1.0

    # --- Pattern 7: temperature columns ---
    def test_temperature_conditioned_space(self):
        new_col, unit, mult = _reformat_raw_column("temperature__conditioned_space__f")
        assert new_col == "out.indoor_temperature.conditioned_space..c"
        assert unit == "f"
        assert mult is None  # F→C special

    def test_dewpoint_temperature(self):
        new_col, unit, mult = _reformat_raw_column(
            "dewpoint_temperature__conditioned_space__f"
        )
        assert new_col == "out.indoor_dewpoint_temperature.conditioned_space..c"

    # --- Pattern 8: relative_humidity ---
    def test_relative_humidity(self):
        new_col, unit, mult = _reformat_raw_column(
            "relative_humidity__conditioned_space__%"
        )
        assert new_col == "out.indoor_relative_humidity.conditioned_space..percentage"
        assert mult == 1.0

    # --- Pattern 9: humidity_ratio ---
    def test_humidity_ratio(self):
        new_col, unit, mult = _reformat_raw_column(
            "humidity_ratio__conditioned_space__fraction"
        )
        assert (
            new_col
            == "out.indoor_humidity_ratio.conditioned_space..kgwater_per_kgdryair"
        )

    # --- Pattern 10: outdoor humidity ratio ---
    def test_outdoor_humidity_ratio(self):
        new_col, unit, mult = _reformat_raw_column(
            "site_outdoor_air_humidity_ratio__environment__kgwater/kgdryair"
        )
        assert new_col == "out.outdoor_humidity_ratio..kgwater_per_kgdryair"

    # --- Pattern 11: weather columns ---
    def test_weather_drybulb(self):
        new_col, unit, mult = _reformat_raw_column("weather__drybulb_temperature__f")
        assert new_col == "out.outdoor_air_drybulb_temp..c"
        assert mult is None

    def test_weather_wind_speed(self):
        new_col, unit, mult = _reformat_raw_column("weather__wind_speed__mph")
        assert new_col == "out.weather.wind_speed..meter_per_second"
        assert mult == pytest.approx(0.44704)

    def test_weather_diffuse_solar(self):
        new_col, unit, mult = _reformat_raw_column(
            "weather__diffuse_solar_radiation__btu/(hr*ft^2)"
        )
        assert new_col == "out.weather.diffuse_solar_radiation..watt_per_m2"
        assert mult == pytest.approx(3.15459)

    # --- Unmatched columns ---
    def test_unmatched_returns_none(self):
        new_col, unit, mult = _reformat_raw_column("building_id")
        assert new_col is None
        assert unit is None
        assert mult is None

    def test_unmatched_time_col(self):
        new_col, _, _ = _reformat_raw_column("time")
        assert new_col is None

    def test_unmatched_upgrade(self):
        new_col, _, _ = _reformat_raw_column("upgrade")
        assert new_col is None


# =============================================================================
# Tests: _build_renamed_columns and _build_intensity_columns
# =============================================================================


class TestBuildRenamedAndIntensityColumns:
    def test_build_renamed_columns_filters_unmapped(self):
        """Non-matching columns should be excluded."""
        columns = ["building_id", "time", "end_use__electricity__heating__kbtu"]
        sql_exprs, ts_cols = _build_renamed_columns(columns)
        assert len(sql_exprs) == 1
        assert len(ts_cols) == 1
        assert ts_cols[0][0] == "end_use__electricity__heating__kbtu"

    def test_build_renamed_columns_multiple(self):
        """Multiple energy columns should all be mapped."""
        columns = [
            "end_use__electricity__heating__kbtu",
            "end_use__natural_gas__hot_water__kbtu",
            "fuel_use__electricity__total__kbtu",
        ]
        sql_exprs, ts_cols = _build_renamed_columns(columns)
        assert len(sql_exprs) == 3
        assert len(ts_cols) == 3

    def test_build_intensity_columns(self):
        """Intensity columns should divide by sqft col."""
        ts_cols = [
            ("orig_a", "out.electricity.heating.energy_consumption..kwh"),
            ("orig_b", "out.natural_gas.hot_water.energy_consumption..kwh"),
        ]
        result = _build_intensity_columns(ts_cols, "in.sqft")
        assert len(result) == 2
        assert (
            '"out.electricity.heating.energy_consumption..kwh" / "in.sqft"' in result[0]
        )
        assert "_intensity" in result[0]

    def test_build_intensity_columns_empty(self):
        """Empty ts_cols should return empty list."""
        result = _build_intensity_columns([], "in.sqft")
        assert result == []

    def test_build_renamed_columns_skip_cols(self):
        """Columns in skip_cols should be excluded entirely."""
        columns = [
            "building_id",
            "upgrade",
            "time",
            "end_use__electricity__heating__kwh",
            "end_use__natural_gas__cooling__therm",
        ]
        skip = {"building_id", "upgrade", "time"}
        sql_exprs, ts_cols = _build_renamed_columns(columns, skip_cols=skip)
        assert len(ts_cols) == 2
        raw_names = [old for old, _ in ts_cols]
        assert "building_id" not in raw_names
        assert "upgrade" not in raw_names
        assert "time" not in raw_names

    def test_build_renamed_columns_keep_unmapped(self):
        """keep_unmapped_cols=True should pass through unrecognized columns."""
        columns = [
            "end_use__electricity__heating__kwh",
            "custom_ochre_metric",
        ]
        sql_exprs, ts_cols = _build_renamed_columns(
            columns, keep_unmapped_cols=True
        )
        assert len(ts_cols) == 2
        # The custom column should be passed through with its own name
        assert ts_cols[1] == ("custom_ochre_metric", "custom_ochre_metric")

    def test_build_renamed_columns_keep_unmapped_false(self):
        """keep_unmapped_cols=False (default) should skip unrecognized columns."""
        columns = [
            "end_use__electricity__heating__kwh",
            "custom_ochre_metric",
        ]
        sql_exprs, ts_cols = _build_renamed_columns(
            columns, keep_unmapped_cols=False
        )
        assert len(ts_cols) == 1
        assert ts_cols[0][0] == "end_use__electricity__heating__kwh"

    def test_build_renamed_columns_skip_and_keep_unmapped(self):
        """skip_cols takes priority even when keep_unmapped_cols=True."""
        columns = ["building_id", "upgrade", "custom_metric"]
        sql_exprs, ts_cols = _build_renamed_columns(
            columns,
            keep_unmapped_cols=True,
            skip_cols={"building_id", "upgrade"},
        )
        assert len(ts_cols) == 1
        assert ts_cols[0] == ("custom_metric", "custom_metric")


# =============================================================================
# Tests: _get_column_mapping_config
# =============================================================================


class TestGetColumnMappingConfig:
    def test_standard_workflow(self):
        """Standard ResStock: intensity=True, keep_unmapped=False."""
        compute_intensity, keep_unmapped = _get_column_mapping_config(
            ochre_workflow=False
        )
        assert compute_intensity is True
        assert keep_unmapped is False

    def test_ochre_workflow(self):
        """Ochre workflow: intensity=False, keep_unmapped=True."""
        compute_intensity, keep_unmapped = _get_column_mapping_config(
            ochre_workflow=True
        )
        assert compute_intensity is False
        assert keep_unmapped is True


# =============================================================================
# Tests: _UNIT_CONVERSIONS dict integrity
# =============================================================================


class TestUnitConversionsDict:
    def test_all_values_are_tuples(self):
        for key, val in _UNIT_CONVERSIONS.items():
            assert isinstance(val, tuple), f"Value for '{key}' is not a tuple"
            assert len(val) == 2, f"Value for '{key}' should be (final_unit, mult)"

    def test_multipliers_are_positive_or_none(self):
        for key, (final_unit, mult) in _UNIT_CONVERSIONS.items():
            if mult is not None:
                assert (
                    mult > 0
                ), f"Multiplier for '{key}' should be positive, got {mult}"

    def test_final_units_are_strings(self):
        for key, (final_unit, mult) in _UNIT_CONVERSIONS.items():
            assert isinstance(final_unit, str), f"Final unit for '{key}' should be str"

    def test_expected_keys_present(self):
        expected = {"kwh", "kbtu", "therm", "mbtu", "f", "%", "mph", "btu/(hr*ft^2)"}
        for k in expected:
            assert (
                k in _UNIT_CONVERSIONS
            ), f"Expected key '{k}' missing from _UNIT_CONVERSIONS"
