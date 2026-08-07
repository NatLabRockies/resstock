import polars as pl

from resstockpostproc.create_allocated_weights import allocate_buildings_to_geography

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
