import polars as pl
from pathlib import Path
import re
from resstockpostproc.income_mapper import assign_representative_income

def test_income_mapping():
    test_df = pl.DataFrame({
        "in.occupants": ["1", "2", "3"],
        "in.federal_poverty_level": ["0-100%", "0-100%", "200%+"],
        "in.income": ["<10000", "10000-14999", "150000+"],
        "in.tenure": ["Owner", "Renter", "Renter"],
        "in.geometry_building_type_recs": ["Mobile Home", "Single Family", "Single Family"],
        "in.county_and_puma": ["G0100030, G01002600", "G0100030, G01002600", "G5501390, G55001501"],
        "in.puma": ["AK, 00101", "AK, 00102", "WY, 00500"],
        "in.state": ["AK", "AK", "WY"],
        "in.census_division": ["Southeast", "Southeast", "Southeast"],
        "in.census_region": ["South", "South", "South"],
        "building_id": [1, 2, 3],
    })
    test_df = assign_representative_income(test_df)
    assert test_df["rep_income"].to_list() == [1, 2, 3]
