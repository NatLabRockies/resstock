"""Guards against allocating with a different sampling region version than the sample was drawn with."""
import json

import polars as pl
import pytest

from resstockpostproc import allocated_weights as aw
from resstockpostproc.utils import setup_fsspec_filesystem

# Two counties, labelled as two versions of the sampling regions would label them
REGIONS = {"v1": {"G0100010": 5, "G0100030": 5}, "v3": {"G0100010": 10505, "G0100030": 10605}}


@pytest.fixture
def staged(tmp_path, monkeypatch):
    """An output directory with a tiny catalogue and both region versions available."""

    catalogue = pl.DataFrame({
        "in.nhgis_county_gisjoin": ["G0100010", "G0100010", "G0100030"],
        "in.nhgis_tract_gisjoin": ["G01000100201", "G01000100202", "G01000300101"],
        "in.vintage": ["1950s", "1990s", "2000s"],
    })
    monkeypatch.setattr(aw, "scan_catalogue", lambda *_: catalogue.lazy())
    monkeypatch.setattr(aw, "load_sampling_regions", lambda _output_dir, version: pl.DataFrame({
        "in.nhgis_county_gisjoin": list(REGIONS[version]),
        "in.sampling_region_id": list(REGIONS[version].values()),
    }))
    monkeypatch.setattr(aw, "load_cec_climate_zones", lambda *_: pl.DataFrame(
        {"in.nhgis_tract_gisjoin": [], "in.sampling_region_id": []},
        schema={"in.nhgis_tract_gisjoin": pl.String, "in.sampling_region_id": pl.Int64},
    ))
    return setup_fsspec_filesystem(str(tmp_path))


def test_partitions_record_their_versions(staged):
    partition_dir = aw.partition_catalogue_by_sampling_region(staged, "v3", "v3")

    assert aw.staged_region_ids(staged, partition_dir) == {"10505", "10605"}
    with open(f"{partition_dir}/{aw.STAGING_RECORD}") as f:
        assert json.load(f) == {"catalogue_file_version": "v3", "sampling_region_version": "v3"}


def test_partitions_are_reused_only_for_the_same_versions(staged, monkeypatch):
    partition_dir = aw.partition_catalogue_by_sampling_region(staged, "v3", "v1")
    assert aw.staged_region_ids(staged, partition_dir) == {"5"}

    # Same versions: reused without reading the catalogue again
    monkeypatch.setattr(aw, "scan_catalogue", lambda *_: pytest.fail("catalogue re-read on reuse"))
    aw.partition_catalogue_by_sampling_region(staged, "v3", "v1")


def test_partitions_from_another_version_are_rebuilt_not_mixed(staged):
    partition_dir = aw.partition_catalogue_by_sampling_region(staged, "v3", "v1")

    aw.partition_catalogue_by_sampling_region(staged, "v3", "v3")

    # The v1 partition is gone, not left alongside the v3 ones
    assert aw.staged_region_ids(staged, partition_dir) == {"10505", "10605"}


def test_partitions_with_no_record_are_rebuilt(staged):
    partition_dir = aw.partition_catalogue_by_sampling_region(staged, "v3", "v1")
    staged["fs"].rm(f"{partition_dir}/{aw.STAGING_RECORD}")

    aw.partition_catalogue_by_sampling_region(staged, "v3", "v3")

    assert aw.staged_region_ids(staged, partition_dir) == {"10505", "10605"}


def test_buildings_in_staged_regions_pass():
    bs_df = pl.DataFrame({"bldg_id": [1, 2, 3], "in.sampling_region_id": ["10505", "10605", "10605"]})

    aw.check_building_sampling_regions(bs_df, {"10505", "10605", "300615"}, "v3")


def test_buildings_outside_staged_regions_are_refused():
    # A v3 sample allocated against v1 partitions: only the California ids are shared
    bs_df = pl.DataFrame({"bldg_id": [1, 2, 3, 4], "in.sampling_region_id": ["10505", "10605", "10605", "100"]})

    with pytest.raises(ValueError, match=r"3 of 4 buildings .* version 'v1'.*\['10605', '10505'\]"):
        aw.check_building_sampling_regions(bs_df, {"5", "100"}, "v1")
