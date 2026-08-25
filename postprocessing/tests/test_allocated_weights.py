import logging

import polars as pl
from resstockpostproc.allocated_weights import report_buildstock_regions_without_a_partition


def make_buildstock(region_by_building: dict[int, str]) -> pl.DataFrame:
    """Buildstock allocation keys, one row per building, carrying only the region label."""
    return pl.DataFrame(
        {
            "bldg_id": list(region_by_building.keys()),
            "in.sampling_region_id": list(region_by_building.values()),
        }
    )


def test_a_buildstock_region_with_no_catalogue_partition_is_reported(caplog):
    # Region 9 is what a new region, a type mismatch, or a failed sim leaves behind: the
    # allocation walks catalogue partitions, so these three buildings are offered to no pool
    bs_df = make_buildstock({1: "3", 2: "3", 3: "9", 4: "9", 5: "9"})

    with caplog.at_level(logging.WARNING):
        orphans = report_buildstock_regions_without_a_partition(bs_df, ["3", "7"])

    assert orphans.to_dicts() == [{"in.sampling_region_id": "9", "buildings": 3}]
    assert "3 of 5 buildings" in caplog.text
    assert "'9': 3" in caplog.text


def test_a_buildstock_inside_the_partitions_reports_nothing(caplog):
    bs_df = make_buildstock({1: "3", 2: "7"})

    with caplog.at_level(logging.WARNING):
        orphans = report_buildstock_regions_without_a_partition(bs_df, ["3", "7", "11"])

    # A partition with no buildings is ordinary; the guard only looks the other way
    assert orphans.height == 0
    assert caplog.text == ""


def test_every_orphan_region_is_named_and_the_largest_leads(caplog):
    bs_df = make_buildstock({1: "3", 2: "9", 3: "12", 4: "12"})

    with caplog.at_level(logging.WARNING):
        orphans = report_buildstock_regions_without_a_partition(bs_df, ["3"])

    assert orphans["in.sampling_region_id"].to_list() == ["12", "9"]
    assert orphans["buildings"].to_list() == [2, 1]
    assert "3 of 4 buildings" in caplog.text
