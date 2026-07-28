"""Tests for the export_metadata_and_annual_results entry point contract (Phase A)."""

import json

import polars as pl
import pytest

from resstockpostproc.allocated_weights import allocate_buildings_to_geography
from resstockpostproc.process_bsb_results import export_metadata_and_annual_results
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
