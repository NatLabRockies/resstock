"""Tests for the export_metadata_and_annual_results entry point contract (Phase A)."""

import json
import re

import polars as pl
import pytest

from resstockpostproc.allocated_weights import allocate_buildings_to_geography
from resstockpostproc.process_bsb_results import (
    RESULTS_FILE_GLOB,
    export_metadata_and_annual_results,
    parse_upgrade_id,
)
from resstockpostproc.simulation_outputs import get_upgrade_rename_dict
from resstockpostproc.utils import setup_fsspec_filesystem

ALLOCATION_GROUP_COLS = [
    "in.sampling_region_id",
    "in.tenure",
    "in.vacancy_status",
    "in.geometry_building_type_recs",
    "in.vintage",
    "in.heating_fuel",
    "in.federal_poverty_level",
]


def test_missing_baseline_raises(tmp_path):
    (tmp_path / "raw").mkdir()
    with pytest.raises(FileNotFoundError, match="results_up00"):
        export_metadata_and_annual_results(str(tmp_path / "raw"), str(tmp_path / "out"))


def test_upgrade_files_without_baseline_raises(tmp_path):
    with pytest.raises(ValueError, match="baseline_file must be provided"):
        export_metadata_and_annual_results(
            str(tmp_path), str(tmp_path / "out"), upgrade_files=["results_up01.parquet"]
        )


def test_unsupported_sampler_type_raises(tmp_path):
    with pytest.raises(ValueError, match="sampler_type"):
        export_metadata_and_annual_results(str(tmp_path), str(tmp_path / "out"), sampler_type="bogus")


def test_explicit_missing_files_raise(tmp_path):
    with pytest.raises(FileNotFoundError, match="not found"):
        export_metadata_and_annual_results(
            str(tmp_path),
            str(tmp_path / "out"),
            baseline_file=str(tmp_path / "nope" / "results_up00.parquet"),
        )


@pytest.mark.parametrize(
    "file_name, expected",
    [
        ("results_up00.parquet", 0),
        ("results_up0.parquet", 0),
        ("results_up01.parquet", 1),
        ("results_up13.parquet", 13),
        ("results_upgrade02.parquet", 2),
        # Timeseries partition files: "group0" contains "up0", "group00" contains "up00"
        ("group0.parquet", None),
        ("group00.parquet", None),
        ("group10.parquet", None),
        ("buildstock.csv", None),
    ],
)
def test_parse_upgrade_id(file_name, expected):
    assert parse_upgrade_id(file_name) == expected
    assert parse_upgrade_id(f"s3://bucket/run/timeseries/upgrade=0/{file_name}") == expected


def _write_timeseries_partitions(raw_dir):
    """The layout BuildStockBatch writes alongside the results files."""
    part_dir = raw_dir / "timeseries" / "upgrade=0" / "state=AK" / "county=AK, Anchorage Municipality"
    part_dir.mkdir(parents=True)
    for name in ("group0.parquet", "group00.parquet", "group10.parquet"):
        (part_dir / name).touch()
    return part_dir


def test_timeseries_files_are_not_mistaken_for_results(tmp_path):
    """A run with only timeseries parquet files has no baseline, and must say so."""
    raw_dir = tmp_path / "raw"
    raw_dir.mkdir()
    _write_timeseries_partitions(raw_dir)
    with pytest.raises(FileNotFoundError, match="results_up00"):
        export_metadata_and_annual_results(str(raw_dir), str(tmp_path / "out"))


def test_timeseries_subtree_is_never_listed(tmp_path, monkeypatch):
    """Discovery must not walk timeseries/ -- on a full run that listing takes minutes."""
    raw_dir = tmp_path / "raw"
    (raw_dir / "baseline").mkdir(parents=True)
    (raw_dir / "baseline" / "results_up00.parquet").touch()
    _write_timeseries_partitions(raw_dir)

    fs_cls = type(setup_fsspec_filesystem(str(raw_dir))["fs"])
    listed = []
    real_glob = fs_cls.glob
    monkeypatch.setattr(fs_cls, "glob", lambda self, path, **kw: listed.append(path) or real_glob(self, path, **kw))

    # Fails later (the touched file isn't real parquet); discovery itself is what's asserted.
    with pytest.raises(Exception):
        export_metadata_and_annual_results(str(raw_dir), str(tmp_path / "out"))

    assert listed, "expected discovery to glob for results files"
    # Relative to raw_dir -- tmp_path itself is named after this test.
    globbed = [path.split("/raw/", 1)[-1] for path in listed]
    assert not any("timeseries" in pattern for pattern in globbed), globbed
    assert all("*" not in pattern.split("results_up")[0] for pattern in globbed), (
        f"discovery must not use a recursive wildcard: {globbed}"
    )


@pytest.mark.parametrize("layout_dir", ["baseline", "upgrades", ""])
def test_baseline_found_in_each_supported_layout(tmp_path, layout_dir):
    raw_dir = tmp_path / "raw"
    results_dir = raw_dir / layout_dir if layout_dir else raw_dir
    results_dir.mkdir(parents=True)
    (results_dir / "results_up00.parquet").touch()
    _write_timeseries_partitions(raw_dir)

    # Discovery finds the baseline, so this gets past the FileNotFoundError and fails
    # later on the empty file instead.
    with pytest.raises(Exception) as exc_info:
        export_metadata_and_annual_results(str(raw_dir), str(tmp_path / "out"))
    assert not isinstance(exc_info.value, FileNotFoundError), "baseline should have been discovered"


def test_explicit_upgrade_file_with_unparseable_name_raises(tmp_path):
    baseline = tmp_path / "results_up00.parquet"
    baseline.touch()
    bad = tmp_path / "group0.parquet"
    bad.touch()
    with pytest.raises(ValueError, match=re.escape(f"{RESULTS_FILE_GLOB} naming convention")):
        export_metadata_and_annual_results(
            str(tmp_path),
            str(tmp_path / "out"),
            baseline_file=str(baseline),
            upgrade_files=[str(bad)],
        )


def test_baseline_passed_as_upgrade_raises(tmp_path):
    baseline = tmp_path / "results_up00.parquet"
    baseline.touch()
    with pytest.raises(ValueError, match="is upgrade 0"):
        export_metadata_and_annual_results(
            str(tmp_path),
            str(tmp_path / "out"),
            baseline_file=str(baseline),
            upgrade_files=[str(baseline)],
        )


def test_duplicate_upgrade_ids_raise(tmp_path):
    baseline = tmp_path / "results_up00.parquet"
    baseline.touch()
    first = tmp_path / "a"
    second = tmp_path / "b"
    first.mkdir()
    second.mkdir()
    (first / "results_up01.parquet").touch()
    (second / "results_up01.parquet").touch()
    with pytest.raises(ValueError, match="claim upgrade 1"):
        export_metadata_and_annual_results(
            str(tmp_path),
            str(tmp_path / "out"),
            baseline_file=str(baseline),
            upgrade_files=[str(first / "results_up01.parquet"), str(second / "results_up01.parquet")],
        )


def _make_allocation_frames():
    """Small geo catalogue and buildstock sample sharing one characteristic group."""
    group_vals = {
        "in.sampling_region_id": "1",
        "in.tenure": "Owner",
        "in.vacancy_status": "Occupied",
        "in.geometry_building_type_recs": "Single-Family Detached",
        "in.vintage": "1990s",
        "in.heating_fuel": "Natural Gas",
        "in.federal_poverty_level": "200-300%",
    }
    n_geo_rows = 50
    geo_df = pl.DataFrame(
        {
            **{col: [val] * n_geo_rows for col, val in group_vals.items()},
            "in.nhgis_tract_gisjoin": [f"G0100010{i:06d}" for i in range(n_geo_rows)],
            "in.nhgis_puma_gisjoin": ["G01000100"] * n_geo_rows,
        }
    )
    bs_df = pl.DataFrame(
        {
            **{col: [val] * 20 for col, val in group_vals.items()},
            "bldg_id": list(range(1, 21)),
        }
    )
    return geo_df, bs_df


def test_allocation_is_reproducible_with_seed():
    geo_df, bs_df = _make_allocation_frames()
    allocated_1, fkt_1 = allocate_buildings_to_geography(geo_df, bs_df, seed=123)
    allocated_2, fkt_2 = allocate_buildings_to_geography(geo_df, bs_df, seed=123)
    assert allocated_1.equals(allocated_2)
    assert fkt_1.equals(fkt_2)


def test_allocation_differs_across_seeds():
    geo_df, bs_df = _make_allocation_frames()
    fkt_a = allocate_buildings_to_geography(geo_df, bs_df, seed=1)[1]
    fkt_b = allocate_buildings_to_geography(geo_df, bs_df, seed=2)[1]
    # 50 draws from a 20-building pool: identical results across seeds would
    # mean the seed isn't reaching the sampler
    assert not fkt_a.equals(fkt_b)


def test_get_upgrade_rename_dict_explicit_path(tmp_path):
    rename_file = tmp_path / "custom_renames.json"
    rename_file.write_text(json.dumps({"old_name": "New Name"}))
    result = get_upgrade_rename_dict(None, rename_upgrades_path=str(rename_file))
    assert result == {"old_name": "New Name"}


def test_get_upgrade_rename_dict_explicit_path_missing_raises(tmp_path):
    with pytest.raises(FileNotFoundError, match="rename_upgrades"):
        get_upgrade_rename_dict(None, rename_upgrades_path=str(tmp_path / "nope.json"))


def test_get_upgrade_rename_dict_default_missing_returns_empty(tmp_path):
    raw_results_dir = setup_fsspec_filesystem(str(tmp_path))
    assert get_upgrade_rename_dict(raw_results_dir) == {}
