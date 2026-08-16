"""Tests for the building-to-geography allocation in resstockpostproc.allocated_weights."""

import json

import polars as pl
import pytest

from resstockpostproc.allocated_weights import (
    allocate_buildings_to_geography,
    check_allocation_misses,
    coerce_vacant_join_keys,
    get_cached_allocated_weights,
    iter_sampling_region_partitions,
    partition_catalogue_by_sampling_region,
    region_seed,
    stage_counts,
    write_allocated_weights,
)
from resstockpostproc.utils import setup_fsspec_filesystem

# Three cells with pools of different sizes, keyed only by sampling region since the other
# characteristics are held constant across the synthetic frame
CELL_POOLS = {"1": [10, 11, 12, 13], "2": [20, 21], "3": [30, 31, 32, 33, 34, 35, 36, 37]}

ROWS_PER_CELL = 100_000


def make_bs_df() -> pl.DataFrame:
    buildings = [b for pool in CELL_POOLS.values() for b in pool]
    regions = [region for region, pool in CELL_POOLS.items() for _ in pool]
    return pl.DataFrame(
        {
            "bldg_id": buildings,
            "in.sampling_region_id": regions,
            "in.tenure": "Owner",
            "in.vacancy_status": "Occupied",
            "in.geometry_building_type_recs": "Single-Family Detached",
            "in.vintage": "1980s",
            "in.heating_fuel": "Natural Gas",
            "in.federal_poverty_level": "400%+",
        }
    )


def make_geo_df(rows_per_cell: int = ROWS_PER_CELL) -> pl.DataFrame:
    regions = [region for region in CELL_POOLS for _ in range(rows_per_cell)]
    return pl.DataFrame(
        {
            "in.sampling_region_id": regions,
            "in.tenure": "Owner",
            "in.vacancy_status": "Occupied",
            "in.geometry_building_type_recs": "Single-Family Detached",
            "in.vintage": "1980s",
            "in.heating_fuel": "Natural Gas",
            "in.federal_poverty_level": "400%+",
            "in.nhgis_tract_gisjoin": "G0100010000100",
            "in.nhgis_puma_gisjoin": "G01000100",
        }
    )


def test_draws_cover_each_pool_uniformly():
    allocated_df, _ = allocate_buildings_to_geography(make_geo_df(), make_bs_df(), seed=7)

    assert allocated_df.height == ROWS_PER_CELL * len(CELL_POOLS)
    assert allocated_df["bldg_id"].null_count() == 0

    for region, pool in CELL_POOLS.items():
        drawn = allocated_df.filter(pl.col("in.sampling_region_id") == region)["bldg_id"]
        assert set(drawn.unique().to_list()) == set(pool), f"cell {region} did not use its pool"

        shares = drawn.value_counts(normalize=True)["proportion"].to_list()
        worst = max(abs(share - 1 / len(pool)) for share in shares)
        # 100k draws over a pool of at most 8 puts the standard error near 0.0015
        assert worst < 0.01, f"cell {region} draws are not uniform, worst deviation {worst}"


def test_seed_controls_the_draw():
    geo_df, bs_df = make_geo_df(rows_per_cell=1_000), make_bs_df()

    first = allocate_buildings_to_geography(geo_df, bs_df, seed=7)[0]["bldg_id"]
    repeat = allocate_buildings_to_geography(geo_df, bs_df, seed=7)[0]["bldg_id"]
    other = allocate_buildings_to_geography(geo_df, bs_df, seed=8)[0]["bldg_id"]

    assert first.to_list() == repeat.to_list()
    assert first.to_list() != other.to_list()


def test_vacant_rows_draw_across_fuels():
    bs_df = pl.concat(
        [
            make_bs_df(),
            pl.DataFrame(
                {
                    "bldg_id": [40, 41],
                    "in.sampling_region_id": ["1", "1"],
                    "in.tenure": "Not Available",
                    "in.vacancy_status": "Vacant",
                    "in.geometry_building_type_recs": "Single-Family Detached",
                    "in.vintage": "1980s",
                    "in.heating_fuel": ["Natural Gas", "Electricity"],
                    "in.federal_poverty_level": "Not Available",
                }
            ),
        ]
    )
    is_cell_one = pl.col("in.sampling_region_id") == "1"
    geo_df = make_geo_df(rows_per_cell=1_000).with_columns(
        pl.when(is_cell_one)
        .then(pl.lit("Vacant"))
        .otherwise(pl.col("in.vacancy_status"))
        .alias("in.vacancy_status"),
        # The catalogue never models these three characteristics for a vacant unit
        pl.when(is_cell_one).then(None).otherwise(pl.col("in.heating_fuel")).alias("in.heating_fuel"),
        pl.when(is_cell_one).then(None).otherwise(pl.col("in.tenure")).alias("in.tenure"),
        pl.when(is_cell_one)
        .then(None)
        .otherwise(pl.col("in.federal_poverty_level"))
        .alias("in.federal_poverty_level"),
    )

    allocated_df, _ = allocate_buildings_to_geography(coerce_vacant_join_keys(geo_df), bs_df, seed=7)

    vacant = allocated_df.filter(pl.col("in.vacancy_status") == "Vacant")
    assert vacant.height == 1_000
    assert vacant["bldg_id"].null_count() == 0
    assert set(vacant["bldg_id"].unique().to_list()) == {40, 41}


def test_unmatched_rows_raise_above_the_threshold():
    bs_df = make_bs_df().filter(pl.col("in.sampling_region_id") != "3")
    allocated_df, _ = allocate_buildings_to_geography(make_geo_df(rows_per_cell=1_000), bs_df, seed=7)

    misses = allocated_df.filter(pl.col("bldg_id").is_null())
    assert misses.height == 1_000

    assert check_allocation_misses(allocated_df, null_building_threshold=0.5).height == 1_000
    with pytest.raises(ValueError, match="found no matching building"):
        check_allocation_misses(allocated_df, null_building_threshold=0.005)


# Buildings for the ladder cases: the wealthy 1980s shelf and the poorer 1960s shelf, both on
# natural gas, so a row only reaches the second shelf once federal poverty level is released
LADDER_POOLS = {
    ("1980s", "400%+"): [1, 2, 3],
    ("1960s", "100-150%"): [4, 5, 6],
}

# One catalogue row per ladder stage, each labelled with the stage it should reach
LADDER_ROWS = {
    "matched_full": {"in.vintage": "1980s", "in.federal_poverty_level": "400%+", "in.heating_fuel": "Natural Gas"},
    "relaxed_vintage": {"in.vintage": "1900s", "in.federal_poverty_level": "400%+", "in.heating_fuel": "Natural Gas"},
    "relaxed_vintage_fpl": {
        "in.vintage": "1900s",
        "in.federal_poverty_level": "0-100%",
        "in.heating_fuel": "Natural Gas",
    },
    # No building burns fuel oil and the ladder never releases heating fuel
    "unmatched": {"in.vintage": "1900s", "in.federal_poverty_level": "0-100%", "in.heating_fuel": "Fuel Oil"},
}

ROWS_PER_STAGE = 200


def make_ladder_bs_df() -> pl.DataFrame:
    return pl.DataFrame(
        {
            "bldg_id": [b for pool in LADDER_POOLS.values() for b in pool],
            "in.vintage": [vintage for (vintage, _), pool in LADDER_POOLS.items() for _ in pool],
            "in.federal_poverty_level": [fpl for (_, fpl), pool in LADDER_POOLS.items() for _ in pool],
            "in.sampling_region_id": "1",
            "in.tenure": "Owner",
            "in.vacancy_status": "Occupied",
            "in.geometry_building_type_recs": "Single-Family Detached",
            "in.heating_fuel": "Natural Gas",
        }
    )


def make_ladder_geo_df(rows_per_stage: int = ROWS_PER_STAGE) -> pl.DataFrame:
    return pl.DataFrame(
        {
            "expected_stage": [stage for stage in LADDER_ROWS for _ in range(rows_per_stage)],
            "in.vintage": [row["in.vintage"] for row in LADDER_ROWS.values() for _ in range(rows_per_stage)],
            "in.federal_poverty_level": [
                row["in.federal_poverty_level"] for row in LADDER_ROWS.values() for _ in range(rows_per_stage)
            ],
            "in.heating_fuel": [
                row["in.heating_fuel"] for row in LADDER_ROWS.values() for _ in range(rows_per_stage)
            ],
            "in.sampling_region_id": "1",
            "in.tenure": "Owner",
            "in.vacancy_status": "Occupied",
            "in.geometry_building_type_recs": "Single-Family Detached",
            "in.nhgis_tract_gisjoin": "G0100010000100",
            "in.nhgis_puma_gisjoin": "G01000100",
        }
    )


def test_ladder_fills_rows_at_the_stage_that_can_reach_them():
    allocated_df, _ = allocate_buildings_to_geography(make_ladder_geo_df(), make_ladder_bs_df(), seed=7)

    assert allocated_df.height == ROWS_PER_STAGE * len(LADDER_ROWS)
    for expected_stage in LADDER_ROWS:
        reached = allocated_df.filter(pl.col("expected_stage") == expected_stage)["fallback_stage"]
        assert reached.unique().to_list() == [expected_stage]

    # A released key widens the pool rather than picking a fixed stand-in
    full = allocated_df.filter(pl.col("fallback_stage") == "matched_full")["bldg_id"]
    assert set(full.unique().to_list()) == set(LADDER_POOLS[("1980s", "400%+")])

    vintage_only = allocated_df.filter(pl.col("fallback_stage") == "relaxed_vintage")["bldg_id"]
    assert set(vintage_only.unique().to_list()) == set(LADDER_POOLS[("1980s", "400%+")])

    both_released = allocated_df.filter(pl.col("fallback_stage") == "relaxed_vintage_fpl")["bldg_id"]
    assert set(both_released.unique().to_list()) == {b for pool in LADDER_POOLS.values() for b in pool}

    unmatched = allocated_df.filter(pl.col("fallback_stage") == "unmatched")
    assert unmatched.height == ROWS_PER_STAGE
    assert unmatched["bldg_id"].null_count() == ROWS_PER_STAGE

    assert stage_counts(allocated_df) == dict.fromkeys(LADDER_ROWS, ROWS_PER_STAGE)


def test_rows_the_ladder_cannot_fill_reach_the_miss_report_with_their_stage():
    allocated_df, _ = allocate_buildings_to_geography(make_ladder_geo_df(), make_ladder_bs_df(), seed=7)

    misses = check_allocation_misses(allocated_df, null_building_threshold=0.5)

    assert misses.height == ROWS_PER_STAGE
    assert misses["fallback_stage"].unique().to_list() == ["unmatched"]
    assert misses["in.heating_fuel"].unique().to_list() == ["Fuel Oil"]

    # The threshold judges the residue the ladder left, a quarter of the frame here
    with pytest.raises(ValueError, match="after releasing vintage and federal poverty level"):
        check_allocation_misses(allocated_df, null_building_threshold=0.2)


def test_ladder_draws_are_reproducible_under_the_seed():
    geo_df, bs_df = make_ladder_geo_df(), make_ladder_bs_df()

    first = allocate_buildings_to_geography(geo_df, bs_df, seed=7)[0]
    repeat = allocate_buildings_to_geography(geo_df, bs_df, seed=7)[0]
    other = allocate_buildings_to_geography(geo_df, bs_df, seed=8)[0]

    assert first["bldg_id"].to_list() == repeat["bldg_id"].to_list()
    assert first["fallback_stage"].to_list() == repeat["fallback_stage"].to_list()
    assert first["bldg_id"].to_list() != other["bldg_id"].to_list()
    # The stage a row reaches is set by the keys, not by the draw
    assert first["fallback_stage"].to_list() == other["fallback_stage"].to_list()


def test_allocating_region_by_region_matches_allocating_in_one_pass():
    """The national catalogue is allocated a sampling region at a time to bound memory.

    That is only sound because in.sampling_region_id is an allocation key the ladder never
    releases, so splitting the catalogue on it cannot change which shelf a row reaches.
    """

    geo_df, bs_df = make_geo_df(rows_per_cell=1_000), make_bs_df()

    whole = allocate_buildings_to_geography(geo_df, bs_df, seed=7)[0]
    by_region = pl.concat(
        [
            allocate_buildings_to_geography(
                geo_df.filter(pl.col("in.sampling_region_id") == region),
                bs_df.filter(pl.col("in.sampling_region_id") == region),
                seed=region_seed(7, region),
            )[0]
            for region in CELL_POOLS
        ],
        how="vertical",
    )

    assert by_region.height == whole.height
    assert stage_counts(by_region) == stage_counts(whole)
    # Every row still draws from its own region's pool, whichever way the work was divided
    for region, pool in CELL_POOLS.items():
        drawn = by_region.filter(pl.col("in.sampling_region_id") == region)["bldg_id"]
        assert set(drawn.unique().to_list()) == set(pool)


def test_region_seed_is_reproducible_and_specific_to_the_region():
    assert region_seed(42, "34") == region_seed(42, "34")
    assert region_seed(42, "34") != region_seed(42, "35")
    assert region_seed(42, "34") != region_seed(43, "34")
    assert region_seed(None, "34") is None


def test_allocation_of_a_region_does_not_depend_on_when_it_is_allocated():
    """Per-region seeding is what makes the allocation independent of the chunking order."""

    geo_df, bs_df = make_geo_df(rows_per_cell=1_000), make_bs_df()

    def allocate(region):
        return allocate_buildings_to_geography(
            geo_df.filter(pl.col("in.sampling_region_id") == region),
            bs_df.filter(pl.col("in.sampling_region_id") == region),
            seed=region_seed(7, region),
        )[0]["bldg_id"].to_list()

    forwards = {region: allocate(region) for region in CELL_POOLS}
    backwards = {region: allocate(region) for region in reversed(list(CELL_POOLS))}

    assert forwards == backwards


# A catalogue small enough to write to disk, covering both the county-based regions used for
# most of the country and the CEC climate zone regions California is assigned through
CATALOGUE_ROWS = {
    "G0100010000100": {"county": "G0100010", "region": "7"},
    "G0100010000200": {"county": "G0100010", "region": "7"},
    "G3600610000100": {"county": "G3600610", "region": "12"},
    # A California tract, in no county-based region, reaching 101 via CEC3
    "G0600010000100": {"county": "G0600010", "region": "101"},
}


def write_catalogue_files(output_path, rows_per_tract: int = 3) -> None:
    """Stage a small catalogue and its lookups, so nothing is downloaded from S3."""

    tracts = [tract for tract in CATALOGUE_ROWS for _ in range(rows_per_tract)]
    pl.DataFrame(
        {
            "tract_gisjoin": tracts,
            "puma_gisjoin": [f"{tract[:8]}0" for tract in tracts],
            "household_id": [str(i) for i in range(len(tracts))],
            "Tenure": "Owner",
            "Vacancy Status": "Occupied",
            "Geometry Building Type RECS": "Single-Family Detached",
            "Vintage": "1980s",
            "Heating Fuel": "Natural Gas",
            "Federal Poverty Level": "400%+",
        }
    ).write_parquet(output_path / "pums_2019_5yrs_acs_catalogue_test.parquet")

    pl.DataFrame(
        {"FIPS Code": [1, 36, 6], "State Code": ["AL", "NY", "CA"]}
    ).write_csv(output_path / "state_region_division_table.csv")

    # California's counties are deliberately absent, so those tracts fall through to CEC
    (output_path / "sampling_regions_test.json").write_text(
        json.dumps({"G0100010": 7, "G3600610": 12})
    )
    (output_path / "cec_cz_by_tract_2010_lkup.json").write_text(
        json.dumps({"G0600010000100": "CEC3"})
    )


def test_catalogue_partitions_round_trip_through_the_sampling_region_cache(tmp_path):
    write_catalogue_files(tmp_path)
    output_dir = setup_fsspec_filesystem(str(tmp_path))

    partition_dir = partition_catalogue_by_sampling_region(
        output_dir, catalogue_file_version="test", sampling_region_version="test"
    )
    partitions = dict(iter_sampling_region_partitions(output_dir, partition_dir))

    expected = {row["region"] for row in CATALOGUE_ROWS.values()}
    assert set(partitions) == expected
    assert sum(df.height for df in partitions.values()) == len(CATALOGUE_ROWS) * 3

    # Each partition holds exactly the tracts assigned to that region, and says so in its rows
    for region, df in partitions.items():
        assert df["in.sampling_region_id"].unique().to_list() == [region]
        assert set(df["in.nhgis_tract_gisjoin"].unique().to_list()) == {
            tract for tract, row in CATALOGUE_ROWS.items() if row["region"] == region
        }

    # The derived geography columns survive the round trip
    alabama = partitions["7"]
    assert alabama["in.nhgis_county_gisjoin"].unique().to_list() == ["G0100010"]
    assert alabama["in.state"].unique().to_list() == ["AL"]


def test_staged_catalogue_partitions_are_reused_rather_than_rebuilt(tmp_path):
    write_catalogue_files(tmp_path)
    output_dir = setup_fsspec_filesystem(str(tmp_path))
    kwargs = {"catalogue_file_version": "test", "sampling_region_version": "test"}

    partition_dir = partition_catalogue_by_sampling_region(output_dir, **kwargs)

    # A rerun after a later failure must not repeat the pass over the whole catalogue
    (marker := tmp_path / "marker.txt").write_text("kept")
    partition_catalogue_by_sampling_region(output_dir, **kwargs)
    assert marker.exists()

    # Removing the catalogue leaves the staged partitions readable, proving they were reused
    (tmp_path / "pums_2019_5yrs_acs_catalogue_test.parquet").unlink()
    reused = partition_catalogue_by_sampling_region(output_dir, **kwargs)
    assert reused == partition_dir
    assert len(dict(iter_sampling_region_partitions(output_dir, reused))) == 3


def test_allocated_weights_cache_round_trips_by_sampling_region(tmp_path):
    output_dir = setup_fsspec_filesystem(str(tmp_path))
    allocated_df, _ = allocate_buildings_to_geography(
        make_geo_df(rows_per_cell=100), make_bs_df(), seed=7
    )
    allocated_df = allocated_df.with_columns(pl.lit(1).alias("weight"))

    write_allocated_weights(output_dir, allocated_df)
    reloaded = get_cached_allocated_weights(output_dir).collect()

    assert reloaded.height == allocated_df.height
    assert sorted(reloaded.columns) == sorted(allocated_df.columns)
    # The region is read back off the rows, not duplicated out of the directory name
    assert reloaded["in.sampling_region_id"].value_counts().sort("in.sampling_region_id").rows() == [
        (region, 100) for region in sorted(CELL_POOLS)
    ]


def test_reading_allocated_weights_before_they_are_written_says_so(tmp_path):
    with pytest.raises(FileNotFoundError, match="call create_allocated_weights"):
        get_cached_allocated_weights(setup_fsspec_filesystem(str(tmp_path)))


def test_coerce_vacant_join_keys_leaves_occupied_rows_alone():
    catalogue_df = pl.DataFrame(
        {
            "in.vacancy_status": ["Vacant", "Occupied"],
            "in.tenure": [None, "Owner"],
            "in.federal_poverty_level": [None, "400%+"],
            "in.heating_fuel": [None, "Natural Gas"],
        }
    )
    coerced = coerce_vacant_join_keys(catalogue_df)

    assert coerced["in.tenure"].to_list() == ["Not Available", "Owner"]
    assert coerced["in.federal_poverty_level"].to_list() == ["Not Available", "400%+"]
    assert coerced["in.heating_fuel"].to_list() == [None, "Natural Gas"]
