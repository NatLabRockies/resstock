import polars as pl
import pytest

from resstockpostproc.create_allocated_weights import (
    allocate_buildings_to_geography,
    check_allocation_misses,
    coerce_vacant_join_keys,
)

# Three cells with pools of different sizes, keyed only by Sampling Region since the other
# characteristics are held constant across the synthetic frame
CELL_POOLS = {1: [10, 11, 12, 13], 2: [20, 21], 3: [30, 31, 32, 33, 34, 35, 36, 37]}

ROWS_PER_CELL = 100_000


def make_bs_df() -> pl.DataFrame:
    buildings = [b for pool in CELL_POOLS.values() for b in pool]
    regions = [region for region, pool in CELL_POOLS.items() for _ in pool]
    return pl.DataFrame(
        {
            "Building": buildings,
            "Sampling Region": regions,
            "Tenure": "Owner",
            "Vacancy Status": "Occupied",
            "Geometry Building Type RECS": "Single-Family Detached",
            "Vintage": "1980s",
            "Heating Fuel": "Natural Gas",
            "Federal Poverty Level": "400%+",
        }
    )


def make_geo_df(rows_per_cell: int = ROWS_PER_CELL) -> pl.DataFrame:
    regions = [region for region in CELL_POOLS for _ in range(rows_per_cell)]
    return pl.DataFrame(
        {
            "Sampling Region": regions,
            "Tenure": "Owner",
            "Vacancy Status": "Occupied",
            "Geometry Building Type RECS": "Single-Family Detached",
            "Vintage": "1980s",
            "Heating Fuel": "Natural Gas",
            "Federal Poverty Level": "400%+",
            "tract_gisjoin": "G0100010000100",
            "puma_gisjoin": "G01000100",
        }
    )


def test_draws_cover_each_pool_uniformly():
    allocated_df, _ = allocate_buildings_to_geography(make_geo_df(), make_bs_df(), random_seed=7)

    assert allocated_df.height == ROWS_PER_CELL * len(CELL_POOLS)
    assert allocated_df["Building"].null_count() == 0

    for region, pool in CELL_POOLS.items():
        drawn = allocated_df.filter(pl.col("Sampling Region") == region)["Building"]
        assert set(drawn.unique().to_list()) == set(pool), f"cell {region} did not use its pool"

        shares = drawn.value_counts(normalize=True)["proportion"].to_list()
        worst = max(abs(share - 1 / len(pool)) for share in shares)
        # 100k draws over a pool of at most 8 puts the standard error near 0.0015
        assert worst < 0.01, f"cell {region} draws are not uniform, worst deviation {worst}"


def test_seed_controls_the_draw():
    geo_df, bs_df = make_geo_df(rows_per_cell=1_000), make_bs_df()

    first = allocate_buildings_to_geography(geo_df, bs_df, random_seed=7)[0]["Building"]
    repeat = allocate_buildings_to_geography(geo_df, bs_df, random_seed=7)[0]["Building"]
    other = allocate_buildings_to_geography(geo_df, bs_df, random_seed=8)[0]["Building"]

    assert first.to_list() == repeat.to_list()
    assert first.to_list() != other.to_list()


def test_vacant_rows_draw_across_fuels():
    bs_df = pl.concat(
        [
            make_bs_df(),
            pl.DataFrame(
                {
                    "Building": [40, 41],
                    "Sampling Region": [1, 1],
                    "Tenure": "Not Available",
                    "Vacancy Status": "Vacant",
                    "Geometry Building Type RECS": "Single-Family Detached",
                    "Vintage": "1980s",
                    "Heating Fuel": ["Natural Gas", "Electricity"],
                    "Federal Poverty Level": "Not Available",
                }
            ),
        ]
    )
    geo_df = make_geo_df(rows_per_cell=1_000).with_columns(
        pl.when(pl.col("Sampling Region") == 1)
        .then(pl.lit("Vacant"))
        .otherwise(pl.col("Vacancy Status"))
        .alias("Vacancy Status"),
        # The catalogue never models these three characteristics for a vacant unit
        pl.when(pl.col("Sampling Region") == 1)
        .then(None)
        .otherwise(pl.col("Heating Fuel"))
        .alias("Heating Fuel"),
        pl.when(pl.col("Sampling Region") == 1)
        .then(None)
        .otherwise(pl.col("Tenure"))
        .alias("Tenure"),
        pl.when(pl.col("Sampling Region") == 1)
        .then(None)
        .otherwise(pl.col("Federal Poverty Level"))
        .alias("Federal Poverty Level"),
    )

    allocated_df, _ = allocate_buildings_to_geography(
        coerce_vacant_join_keys(geo_df), bs_df, random_seed=7
    )

    vacant = allocated_df.filter(pl.col("Vacancy Status") == "Vacant")
    assert vacant.height == 1_000
    assert vacant["Building"].null_count() == 0
    assert set(vacant["Building"].unique().to_list()) == {40, 41}


def test_unmatched_rows_raise_above_the_threshold():
    bs_df = make_bs_df().filter(pl.col("Sampling Region") != 3)
    allocated_df, _ = allocate_buildings_to_geography(
        make_geo_df(rows_per_cell=1_000), bs_df, random_seed=7
    )

    misses = allocated_df.filter(pl.col("Building").is_null())
    assert misses.height == 1_000

    assert check_allocation_misses(allocated_df, null_building_threshold=0.5).height == 1_000
    with pytest.raises(ValueError, match="found no matching building"):
        check_allocation_misses(allocated_df, null_building_threshold=0.005)


def test_coerce_vacant_join_keys_leaves_occupied_rows_alone():
    catalogue_df = pl.DataFrame(
        {
            "Vacancy Status": ["Vacant", "Occupied"],
            "Tenure": [None, "Owner"],
            "Federal Poverty Level": [None, "400%+"],
            "Heating Fuel": [None, "Natural Gas"],
        }
    )
    coerced = coerce_vacant_join_keys(catalogue_df)

    assert coerced["Tenure"].to_list() == ["Not Available", "Owner"]
    assert coerced["Federal Poverty Level"].to_list() == ["Not Available", "400%+"]
    assert coerced["Heating Fuel"].to_list() == [None, "Natural Gas"]
