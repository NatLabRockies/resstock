import polars as pl
import pytest

from resstockpostproc.allocated_weights import STATE_BILL_COL_PATTERN
from resstockpostproc.metadata_and_annual_results import (
    add_weighted_cols,
    aggregate_allocated_weights_to_geography,
    drop_state_utility_bill_columns,
)
from resstockpostproc.utils import get_col_maps

TOTAL_BILL = "out.utility_bills.total_bill..usd"
TOTAL_SAVINGS = "out.utility_bills.total_bill_savings..usd"


def make_alloc_wts_plus_bills() -> pl.LazyFrame:
    """Building 1 in three housing units: two Alaska tracts and one Washington tract.

    Bills are per housing unit for the allocated state, so the two Alaska rows carry the same
    bill. The Washington rows carry a weight of 2 each, as the quota sampler's cache would.
    """
    return pl.DataFrame(
        {
            "upgrade": [1, 1, 1, 1],
            "bldg_id": [1, 1, 1, 2],
            "weight": [1, 1, 2, 2],
            "state": ["AK", "AK", "WA", "WA"],
            "in.state": ["AK", "AK", "WA", "WA"],
            "in.nhgis_tract_gisjoin": ["G0200130000100", "G0200130000200", "G5300330001100", "G5300330001200"],
            TOTAL_BILL: [1000.0, 1000.0, 400.0, 900.0],
            TOTAL_SAVINGS: [100.0, 100.0, 40.0, 90.0],
        }
    ).lazy()


def test_tract_aggregation_keeps_each_housing_units_bill():
    agg = aggregate_allocated_weights_to_geography(
        make_alloc_wts_plus_bills(), geography_filters={"state": "AK"},
        geographic_aggregation_levels=["in.nhgis_tract_gisjoin"],
    ).collect().sort("in.nhgis_tract_gisjoin")

    assert agg.columns == ["upgrade", "bldg_id", "in.nhgis_tract_gisjoin", "weight", TOTAL_BILL, TOTAL_SAVINGS]
    assert agg.select(["bldg_id", "weight", TOTAL_BILL, TOTAL_SAVINGS]).rows() == [
        (1, 1, 1000.0, 100.0),
        (1, 1, 1000.0, 100.0),
    ]


def test_state_aggregation_sums_weights_and_keeps_the_state_bill():
    agg = aggregate_allocated_weights_to_geography(
        make_alloc_wts_plus_bills(), geographic_aggregation_levels=["in.state"]
    ).collect().sort(["bldg_id", "in.state"])

    assert agg.select(["bldg_id", "in.state", "weight", TOTAL_BILL]).rows() == [
        (1, "AK", 2, 1000.0),
        (1, "WA", 2, 400.0),
        (2, "WA", 2, 900.0),
    ]


def test_national_aggregation_averages_bills_over_housing_units():
    agg = aggregate_allocated_weights_to_geography(
        make_alloc_wts_plus_bills(), geographic_aggregation_levels=["national"]
    ).collect().sort("bldg_id")

    # Building 1: two Alaska units at 1000 and a Washington unit weighing 2 at 400
    assert agg.select(["bldg_id", "weight", TOTAL_BILL, TOTAL_SAVINGS]).rows() == [
        (1, 4, (2 * 1000.0 + 2 * 400.0) / 4, (2 * 100.0 + 2 * 40.0) / 4),
        (2, 2, 900.0, 90.0),
    ]


def test_aggregation_without_bill_columns_only_sums_weights():
    alloc_wts = make_alloc_wts_plus_bills().drop([TOTAL_BILL, TOTAL_SAVINGS])
    agg = aggregate_allocated_weights_to_geography(
        alloc_wts, geographic_aggregation_levels=["in.state"]
    ).collect().sort(["bldg_id", "in.state"])

    assert agg.columns == ["upgrade", "bldg_id", "in.state", "weight"]
    assert agg["weight"].to_list() == [2, 2, 2]


def test_per_state_bill_columns_are_dropped_from_the_simulation_outputs():
    sim_outs = pl.DataFrame(
        {
            "bldg_id": [1],
            "out.utility_bills.ak_total_bill..usd": [1.0],
            "out.utility_bills.ak_total_bill_savings..usd": [0.5],
            "out.electricity.total.energy_consumption..kwh": [100.0],
        }
    ).lazy()
    kept = drop_state_utility_bill_columns(sim_outs).collect_schema().names()
    assert kept == ["bldg_id", "out.electricity.total.energy_consumption..kwh"]


def test_only_the_generic_bill_columns_are_flagged_for_publication():
    published = {m["published_name"] for m in get_col_maps() if "yes" in m["publish_in_full"]}
    state_bills = sorted(c for c in published if STATE_BILL_COL_PATTERN.match(c))
    assert state_bills == []
    assert TOTAL_BILL in published
    assert TOTAL_SAVINGS in published
    # The per-state columns must still be imported, the bills step is built on them
    imported = {m["published_name"] for m in get_col_maps() if m["import_from_raw"] == "yes"}
    assert "out.utility_bills.ak_total_bill..usd" in imported


def test_bills_are_weighted_into_billion_usd():
    joined = pl.DataFrame(
        {
            "bldg_id": [1, 2],
            "weight": [100, 50],
            TOTAL_BILL: [2000.0, 1000.0],
            TOTAL_SAVINGS: [200.0, 0.0],
            "out.electricity.total.energy_consumption..kwh": [1.0, 1.0],
        }
    ).lazy()
    weighted = add_weighted_cols(joined).collect()

    assert weighted["calc.weighted.utility_bills.total_bill..billion_usd"].to_list() == pytest.approx([2e-4, 5e-5])
    wtd_savings = weighted["calc.weighted.utility_bills.total_bill_savings..billion_usd"]
    assert wtd_savings.to_list() == pytest.approx([2e-5, 0.0])
    # The energy column is still weighted as before
    assert "calc.weighted.electricity.total.energy_consumption..tbtu" in weighted.columns


def test_weighted_bill_columns_are_defined_for_publication():
    published = {m["published_name"] for m in get_col_maps() if "yes" in m["publish_in_full"]}
    expected = {
        f"calc.weighted.utility_bills.{fuel}_bill{suffix}..billion_usd"
        for fuel in ("electricity", "fuel_oil", "natural_gas", "propane", "total")
        for suffix in ("", "_savings")
    }
    assert expected <= published
