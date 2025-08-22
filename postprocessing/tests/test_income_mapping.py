import polars as pl
from pathlib import Path
import re

from resstockpostproc.income_mapper import assign_representative_income


def test_income_mapping():
    test_df = pl.DataFrame(
        {
            "in.occupants": ["1", "2", "3", "4"],
            "in.federal_poverty_level": ["0-100%", "0-100%", "400%+", "Not Available"],
            "in.income": ["<10000", "10000-14999", "200000+", "Not Available"],
            "in.tenure": ["Owner", "NA", "Renter", "Not Available"],
            "in.geometry_building_type_recs": [
                "Mobile Home",
                "NA",
                "Single Family Detached",
                "Multi-Family with 2 - 4 Units",
            ],
            "in.county_and_puma": [
                "G0100030, G01002600",
                "NA",
                "G5501390, G55001501",
                "G3600750, G36000600",
            ],
            "in.puma": ["AK, 00101", "NA", "WY, 00500", "NY, 00600"],
            "in.state": ["AK", "NA", "WY", "NY"],
            "in.census_division": ["Pacific", "NA", "Mountain", "Middle Atlantic"],
            "in.census_region": ["West", "NA", "West", "Northeast"],
            "some_column": [1, 2, 3, 4],
            "bldg_id": [1, 2, 3, 4],
        }
    )
    test_df2 = assign_representative_income(test_df)

    assert test_df2["bldg_id"].to_list() == test_df["bldg_id"].to_list(), "unexpected bldg_id"
    assert set(test_df2.columns) == set(test_df.columns + ["in.representative_income"]), "unexpected cols"
    assert assign_representative_income(test_df, return_map_only=True).columns == [
        "bldg_id",
        "in.representative_income",
    ], "unexpected cols"

    inc_bins = test_df2["in.income"].to_list()
    rep_incs = test_df2["in.representative_income"].to_list()
    for inc_bin, val in zip(inc_bins, rep_incs):
        if inc_bin == "Not Available":
            assert val is None
        elif "-" in inc_bin:
            [lb, ub] = [int(x) for x in inc_bin.split("-")]
            assert (val >= lb) and (val <= ub)
        elif inc_bin.startswith("<"):
            assert val < int(inc_bin.removeprefix("<"))
        elif inc_bin.endswith("+"):
            assert val >= int(inc_bin.removesuffix("+"))
        else:
            raise ValueError(f"Unexpected {inc_bin}")
