"""Tests for the scenario emissions totals: electricity plus natural gas, fuel oil and propane."""

import polars as pl
import pytest

from resstockpostproc.simulation_outputs import downselect_and_rename_cols, downselect_fuel_emissions_cols
from resstockpostproc.utils import fix_all_fuels_emissions, get_col_maps

LB_TO_KG = 0.45359237
FOSSIL = {"natural_gas": 100.0, "fuel_oil": 20.0, "propane": 3.0}


def _col(fuel: str, scenario: str) -> str:
    return f"out.emissions.{fuel}.{scenario}..co2e_kg"


def _fuel_scenario_outputs() -> pl.LazyFrame:
    """Two per-region electricity scenarios whose fossil fuel emissions sit on a separate "fuel"
    scenario, as in a run whose electricity scenarios carry fossil fuel factors of 0."""

    return pl.LazyFrame(
        {
            "bldg_id": [1, 2],
            _col("electricity", "lrmer_mid_case_25_nyiso"): [1000.0, None],
            _col("electricity", "lrmer_mid_case_25_pjm_east"): [None, 2000.0],
            **{_col(fuel, "fuel"): [value, value * 2] for fuel, value in FOSSIL.items()},
        }
    )


def test_fuel_scenario_is_added_to_every_electricity_total():
    out = fix_all_fuels_emissions(_fuel_scenario_outputs()).collect()
    fossil = sum(FOSSIL.values())
    assert out[_col("total", "lrmer_mid_case_25_nyiso")][0] == pytest.approx(1000.0 + fossil)
    assert out[_col("total", "lrmer_mid_case_25_pjm_east")][1] == pytest.approx(2000.0 + 2 * fossil)


def test_no_total_for_the_fossil_fuel_only_scenario():
    out = fix_all_fuels_emissions(_fuel_scenario_outputs()).collect()
    assert _col("total", "fuel") not in out.columns


def test_scenario_with_its_own_fossil_fuels_uses_them():
    lf = pl.LazyFrame(
        {
            _col("electricity", "lrmer_mid_case_25"): [1000.0],
            _col("natural_gas", "lrmer_mid_case_25"): [50.0],
            _col("electricity", "aer_mid_case_avg"): [800.0],
            _col("natural_gas", "aer_mid_case_avg"): [60.0],
        }
    )
    out = fix_all_fuels_emissions(lf).collect()
    assert out[_col("total", "lrmer_mid_case_25")][0] == pytest.approx(1050.0)
    assert out[_col("total", "aer_mid_case_avg")][0] == pytest.approx(860.0)


def test_coal_and_wood_are_left_out():
    lf = _fuel_scenario_outputs().with_columns(
        pl.lit(7.0).alias(_col("coal", "fuel")), pl.lit(9.0).alias(_col("wood_cord", "fuel"))
    )
    out = fix_all_fuels_emissions(lf).collect()
    assert out[_col("total", "lrmer_mid_case_25_nyiso")][0] == pytest.approx(1000.0 + sum(FOSSIL.values()))


def test_ambiguous_fossil_fuel_only_scenarios_raise():
    lf = pl.LazyFrame(
        {
            _col("electricity", "lrmer_mid_case_25"): [1000.0],
            _col("natural_gas", "fuel_a"): [50.0],
            _col("natural_gas", "fuel_b"): [60.0],
        }
    )
    with pytest.raises(ValueError, match="more than one"):
        fix_all_fuels_emissions(lf).collect()


def test_fuel_scenario_columns_are_published_as_fuel_totals():
    # A scenario named "fuel" must not turn fuel_oil into total_oil
    out = downselect_fuel_emissions_cols(_fuel_scenario_outputs()).collect()
    for fuel, value in FOSSIL.items():
        assert out[f"out.emissions.{fuel}.total..co2e_kg"][0] == pytest.approx(value)
        assert _col(fuel, "fuel") not in out.columns


def test_raw_fuel_scenario_flows_into_the_published_totals():
    # The raw columns of a run whose fossil fuel factors are on a scenario named "Fuel"
    raw = pl.LazyFrame(
        {
            "applicability": [True],
            "report_simulation_output.emissions_co_2_e_lrmer_mid_case_25_nyiso_electricity_net_lb": [1000.0],
            **{f"report_simulation_output.emissions_co_2_e_fuel_{fuel}_total_lb": [v] for fuel, v in FOSSIL.items()},
        }
    )
    out = downselect_and_rename_cols(raw, get_col_maps())
    out = downselect_fuel_emissions_cols(fix_all_fuels_emissions(out)).collect()
    assert out[_col("total", "lrmer_mid_case_25_nyiso")][0] == pytest.approx((1000.0 + sum(FOSSIL.values())) * LB_TO_KG)
    for fuel, value in FOSSIL.items():
        assert out[f"out.emissions.{fuel}.total..co2e_kg"][0] == pytest.approx(value * LB_TO_KG)
