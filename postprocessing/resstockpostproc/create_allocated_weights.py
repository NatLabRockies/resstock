import argparse
import boto3
import json
import logging
import numpy as np
import os
from pathlib import Path
import polars as pl
from polars.lazyframe.frame import LazyFrame
from resstockpostproc.utils import FsspecOutputDir, setup_fsspec_filesystem
import s3fs

logger = logging.getLogger(__name__)

# Seed for the per-row uniform draws that pick a building out of each pool
DEFAULT_RANDOM_SEED = 1

# Fraction of catalogue rows allowed to go unallocated before the run is treated as broken
DEFAULT_NULL_BUILDING_THRESHOLD = 0.005

# Characteristics that define a pool of interchangeable buildings for an occupied household
ALLOCATION_KEYS = [
    "Sampling Region",
    "Tenure",
    "Vacancy Status",
    "Geometry Building Type RECS",
    "Vintage",
    "Heating Fuel",
    "Federal Poverty Level",
]

# ACS only surveys the fuel of occupied units, so the catalogue's vacant rows carry no
# Heating Fuel. Vacant rows draw across fuels instead, which reproduces the sample pool's
# conditional fuel mix within the remaining keys.
VACANT_ALLOCATION_KEYS = [key for key in ALLOCATION_KEYS if key != "Heating Fuel"]

# Ladder of retries for catalogue rows whose shelf is empty. Each rung names the stage it
# records and the keys it releases from the join, so the row draws from a pool that has been
# widened over those characteristics. Vintage goes first because a building of the wrong
# vintage distorts the stock less than one of the wrong income bracket.
FALLBACK_LADDER = [
    ("matched_full", []),
    ("relaxed_vintage", ["Vintage"]),
    ("relaxed_vintage_fpl", ["Vintage", "Federal Poverty Level"]),
]

# Stage recorded for rows the whole ladder failed to fill
UNMATCHED_STAGE = "unmatched"

# Every value the fallback_stage column can take, in ladder order
FALLBACK_STAGES = [stage for stage, _ in FALLBACK_LADDER] + [UNMATCHED_STAGE]


def load_catalogue_file(output_dir: FsspecOutputDir, catalogue_file_version: str) -> pl.DataFrame:
    """Load and preprocess catalogue file, downloading from S3 if necessary.

    Vacant rows are given the literal "Not Available" for Tenure and Federal Poverty Level so
    they match the buildstock sample, which labels vacant buildings that way. Heating Fuel is
    left null on vacant rows and is handled by the two stage join in
    allocate_buildings_to_geography.

    Args:
        output_dir: Dictionary containing filesystem info from setup_fsspec_filesystem
        catalogue_file_version: Version string for catalogue file (e.g., 'v0')

    Returns:
        Polars DataFrame with catalogue data including county_gisjoin column
    """

    # Construct file path for catalogue file
    catalogue_file = f"pums_2019_5yrs_acs_catalogue_{catalogue_file_version}.parquet"
    catalogue_local_path = f"{output_dir['fs_path']}/{catalogue_file}"

    # Download from S3 if not already cached locally
    if not os.path.isfile(catalogue_local_path):
        logger.info("Catalogue file not found locally, downloading from S3")
        s3_client = boto3.client("s3")
        s3_client.download_file(
            "resstock-core",
            f"truth_data/v01/StockE/{catalogue_file}",
            str(catalogue_local_path),
        )
        logger.info(f"Downloaded catalogue file to {catalogue_local_path}")

    # Read catalogue and add county_gisjoin derived from first 8 chars of tract_gisjoin
    logger.info(f"Reading catalogue file from {catalogue_local_path}")
    catalogue_df = pl.read_parquet(catalogue_local_path)
    catalogue_df = catalogue_df.with_columns(
        pl.col("tract_gisjoin").str.slice(0, 8).alias("county_gisjoin")
    )

    catalogue_df = coerce_vacant_join_keys(catalogue_df)

    return catalogue_df


def coerce_vacant_join_keys(catalogue_df: pl.DataFrame) -> pl.DataFrame:
    """Fill null Tenure and Federal Poverty Level on vacant catalogue rows with "Not Available".

    Args:
        catalogue_df: Catalogue data

    Returns:
        Catalogue data with vacant row join keys aligned to the buildstock sample's labels
    """

    is_vacant = pl.col("Vacancy Status").eq_missing("Vacant")
    for column in ["Tenure", "Federal Poverty Level"]:
        coerced = catalogue_df.filter(is_vacant & pl.col(column).is_null()).height
        if coerced:
            logger.info(f"Coercing {column} to 'Not Available' on {coerced} vacant catalogue rows")
            catalogue_df = catalogue_df.with_columns(
                pl.when(is_vacant & pl.col(column).is_null())
                .then(pl.lit("Not Available"))
                .otherwise(pl.col(column))
                .alias(column)
            )

    return catalogue_df

def load_sampling_regions(output_dir: FsspecOutputDir, sampling_region_version: str) -> pl.DataFrame:
    """Load sampling regions mapping, downloading from S3 if necessary.

    Args:
        output_dir: Dictionary containing filesystem info from setup_fsspec_filesystem
        sampling_region_version: Version string for sampling regions file (e.g., 'v1')

    Returns:
        Polars DataFrame with county_gisjoin to sampling_region mapping
    """

    # Construct file path for sampling regions JSON file
    sampling_regions_file = f"sampling_regions_{sampling_region_version}.json"
    sample_regions_local_path = f"{output_dir['fs_path']}/{sampling_regions_file}"

    # Download from S3 if not already cached locally
    if not os.path.isfile(sample_regions_local_path):
        logger.info("Sampling regions file not found locally, downloading from S3")
        s3_client = boto3.client("s3")
        s3_client.download_file(
            "resstock-core",
            f"truth_data/v01/StockE/{sampling_regions_file}",
            str(sample_regions_local_path),
        )
        logger.info(f"Downloaded sampling regions file to {sample_regions_local_path}")

    # Load JSON file containing county to sampling region mappings
    logger.info(f"Reading sample file from {sample_regions_local_path}")
    with open(sample_regions_local_path, "r") as f:
        sampling_regions_dict = json.load(f)

    # Manually add in Oglala Lakota County, SD which used to be Shannon county (G4601130)
    sampling_regions_dict["G4601020"] = 34

    # Convert dictionary to DataFrame
    sampling_regions_df = pl.DataFrame(
        {
            "county_gisjoin": list(sampling_regions_dict.keys()),
            "sampling_region": list(sampling_regions_dict.values()),
        }
    )

    return sampling_regions_df

def load_cec_climate_zones(output_dir: FsspecOutputDir) -> pl.DataFrame:
    """Load CEC climate zone to sampling region mapping.

    Args:
        output_dir: Dictionary containing filesystem info from setup_fsspec_filesystem

    Returns:
        Polars DataFrame with tract_gisjoin to sampling_region mapping for California
    """

    # Define which CEC climate zones map to which sampling regions
    # California uses climate zone-based sampling instead of county-based
    ca_regions_lkup = {
        "CEC1": 100,
        "CEC2": 100,
        "CEC3": 101,
        "CEC4": 102,
        "CEC5": 102,
        "CEC6": 103,
        "CEC7": 103,
        "CEC8": 104,
        "CEC9": 105,
        "CEC10": 106,
        "CEC11": 107,
        "CEC12": 107,
        "CEC13": 108,
        "CEC14": 109,
        "CEC15": 109,
        "CEC16": 110,
    }

    # Construct file path for CEC climate zone lookup file
    cec_2010_cz_lkup_file = "cec_cz_by_tract_2010_lkup.json"
    cec_2010_cz_lkup_local_path = f"{output_dir['fs_path']}/{cec_2010_cz_lkup_file}"

    # Download from S3 if not already cached locally
    if not os.path.isfile(cec_2010_cz_lkup_local_path):
        logger.info("CEC 2010 CZ lookup file not found locally, downloading from S3")
        s3_client = boto3.client("s3")
        s3_client.download_file(
            "resstock-core",
            f"truth_data/v01/StockE/{cec_2010_cz_lkup_file}",
            str(cec_2010_cz_lkup_local_path),
        )
        logger.info(
            f"Downloaded CEC 2010 CZ lookup file to {cec_2010_cz_lkup_local_path}"
        )

    # Load JSON file containing tract to CEC climate zone mappings
    logger.info(f"Reading CEC 2010 CZ lookup file from {cec_2010_cz_lkup_local_path}")
    with open(cec_2010_cz_lkup_local_path, "r") as f:
        cec_2010_cz_lkup_dict = json.load(f)

    # Convert to DataFrame and map CEC zones to sampling region numbers
    cec_2010_cz_lkup_df = pl.DataFrame(
        {
            "tract_gisjoin": list(cec_2010_cz_lkup_dict.keys()),
            "sampling_region": list(cec_2010_cz_lkup_dict.values()),
        }
    )
    cec_2010_cz_lkup_df = cec_2010_cz_lkup_df.with_columns(
        pl.col("sampling_region").replace(ca_regions_lkup)
    )

    # This is future proofing code for the world where we upgrade to the 2020 census geographies
    # # Read cec_cz_by_tract_2020_lkup.json from local path or download from S3 if not found
    # cec_2020_cz_lkup_file = "cec_cz_by_tract_2020_lkup.json"
    # cec_2020_cz_lkup_local_path = f"{output_dir['fs_path']}/{cec_2020_cz_lkup_file}"
    # if not os.path.isfile(cec_2020_cz_lkup_local_path):
    #     logger.info(f"CEC 2020 CZ lookup file not found locally, downloading from S3")
    #     s3_client = boto3.client('s3')
    #     s3_client.download_file(
    #         'resstock-core', f'truth_data/v01/StockE/{cec_2020_cz_lkup_file}', str(cec_2020_cz_lkup_local_path)
    #     )
    #     logger.info(f"Downloaded CEC 2020 CZ lookup file to {cec_2020_cz_lkup_local_path}")
    # logger.info(f"Reading CEC 2020 CZ lookup file from {cec_2020_cz_lkup_local_path}")
    # with open(cec_2020_cz_lkup_local_path, 'r') as f:
    #     cec_2020_cz_lkup_dict = json.load(f)
    # cec_2020_cz_lkup_df = pl.DataFrame({
    #     "tract_gisjoin": list(cec_2020_cz_lkup_dict.keys()),
    #     "sampling_region": list(cec_2020_cz_lkup_dict.values())
    # })
    # cec_2020_cz_lkup_df = cec_2020_cz_lkup_df.with_columns(pl.col('sampling_region').replace(ca_regions_lkup))

    return cec_2010_cz_lkup_df

def merge_geographical_data(
    catalogue_df: pl.DataFrame, sampling_regions_df: pl.DataFrame, cec_2010_cz_lkup_df: pl.DataFrame,
) -> pl.DataFrame:
    """Merge catalogue with sampling region assignments.

    Uses county-based sampling regions for most of the US and CEC climate zone-based
    sampling regions for California tracts.

    Args:
        catalogue_df: Catalogue data with tract and county information
        sampling_regions_df: County to sampling region mapping
        cec_2010_cz_lkup_df: California tract to sampling region mapping via CEC climate zones

    Returns:
        Merged DataFrame with 'Sampling Region' column assigned for all rows

    Raises:
        ValueError: If any rows are missing sampling region assignments
    """

    # Join catalogue with county-based sampling regions (covers most of US)
    logger.info("Merging catalogue and sample regions data")
    df = catalogue_df.join(sampling_regions_df, on="county_gisjoin", how="left")

    # Join with CEC climate zone-based sampling regions (covers California)
    df = df.join(cec_2010_cz_lkup_df, on="tract_gisjoin", how="left", suffix="_cec2010")
    # df = df.join(cec_2020_cz_lkup_df, on="tract_gisjoin", how="left", suffix="_cec2020")

    # Use county-based region, falling back to CEC climate zone region for CA tracts
    df = df.with_columns(
        pl.coalesce(
            [
                pl.col("sampling_region"),
                pl.col(
                    "sampling_region_cec2010"
                ),  # , pl.col("sampling_region_cec2020")
            ]
        )
        .cast(pl.Int64)
        .alias("sampling_region")
    )

    # Clean up temporary columns and rename to final column name
    df = df.drop(["sampling_region_cec2010"])  # , "sampling_region_cec2020"])
    df = df.rename({"sampling_region": "Sampling Region"})

    # Validate that all rows have been assigned a sampling region. Only this column is checked
    # because vacant rows legitimately carry a null Heating Fuel.
    missing_region = df.filter(pl.col("Sampling Region").is_null())
    if missing_region.shape[0] > 0:
        missing_counties = missing_region.select("county_gisjoin").unique()
        missing_tracts = missing_region.select("tract_gisjoin").unique()
        raise ValueError(
            f"\n{missing_region.shape[0]} rows are missing sampling regions.\n"
            + f"Missing counties: {missing_counties.to_series().to_list()}.\n"
            + f"Missing tracts: {missing_tracts.to_series().to_list()}"
        )
    logger.info("Successfully assigned sampling regions")

    return df


def draw_from_pools(df: pl.DataFrame, rng: np.random.Generator) -> pl.DataFrame:
    """Replace each row's list of candidate buildings with one building drawn from it.

    Every row gets its own uniform variate, so the draw is independent row to row and uniform
    over that row's pool. Rows whose pool is null, because the join found no matching buildings,
    keep a null Building.

    Args:
        df: Frame whose Building column holds a list of candidate buildings per row
        rng: Seeded generator supplying one uniform variate per row

    Returns:
        Frame with Building reduced to a single drawn building per row
    """

    return (
        df.with_columns(pl.Series("draw", rng.random(df.height), dtype=pl.Float64))
        .with_columns(
            pl.col("Building").list.get(
                (pl.col("draw") * pl.col("Building").list.len()).floor().cast(pl.Int64),
                null_on_oob=True,
            )
        )
        .drop("draw")
    )


def draw_on_keys(
    geo_subset: pl.DataFrame, bs_df: pl.DataFrame, keys: list[str], rng: np.random.Generator
) -> pl.DataFrame:
    """Draw one building per catalogue row out of the pool sharing its values of `keys`.

    Args:
        geo_subset: Catalogue rows still needing a building
        bs_df: Buildstock sample data with building characteristics
        keys: Characteristics that must agree between a catalogue row and its building
        rng: Seeded generator supplying one uniform variate per row

    Returns:
        The catalogue rows with a Building column, null where the pool was empty
    """

    # Group buildstock buildings by the key characteristics to create pools of similar
    # buildings, then join those pools onto the catalogue rows that share them
    grouped_df = bs_df.group_by(keys).agg(pl.col("Building").unique())
    joined_df = geo_subset.lazy().join(grouped_df.lazy(), on=keys, how="left").collect()

    return draw_from_pools(joined_df, rng)


def allocate_down_the_ladder(
    geo_subset: pl.DataFrame, bs_df: pl.DataFrame, keys: list[str], rng: np.random.Generator
) -> pl.DataFrame:
    """Draw a building for every catalogue row, widening the pool for rows that find none.

    Rows are first matched on the full `keys`. Whatever finds an empty shelf is retried on each
    remaining rung of FALLBACK_LADDER, drawing from a pool widened over the keys that rung
    releases. Rows the last rung still cannot fill keep a null Building. The rung that filled a
    row, or UNMATCHED_STAGE, is recorded in fallback_stage.

    Args:
        geo_subset: Catalogue rows sharing a matching regime, occupied or vacant
        bs_df: Buildstock sample data with building characteristics
        keys: Characteristics matched on the first rung
        rng: Seeded generator supplying one uniform variate per row per rung

    Returns:
        The catalogue rows with Building and fallback_stage columns
    """

    filled_frames = []
    remaining = geo_subset
    # The first rung always runs, so an empty subset still yields a frame carrying the columns
    for stage, released_keys in FALLBACK_LADDER:
        stage_keys = [key for key in keys if key not in released_keys]
        drawn = draw_on_keys(remaining, bs_df, stage_keys, rng).with_columns(
            pl.lit(stage).alias("fallback_stage")
        )
        filled_frames.append(drawn.filter(pl.col("Building").is_not_null()))
        remaining = drawn.filter(pl.col("Building").is_null()).drop(
            ["Building", "fallback_stage"]
        )
        if remaining.height == 0:
            break

    if remaining.height:
        filled_frames.append(
            remaining.with_columns(
                pl.lit(None, dtype=bs_df.schema["Building"]).alias("Building"),
                pl.lit(UNMATCHED_STAGE).alias("fallback_stage"),
            )
        )

    return pl.concat(filled_frames, how="vertical")


def allocate_buildings_to_geography(
    geo_df: pl.DataFrame,
    bs_df: pl.DataFrame,
    random_seed: int = DEFAULT_RANDOM_SEED,
) -> tuple[pl.DataFrame, pl.DataFrame]:
    """Allocate buildings from sample to geographical units.

    Groups buildings by key characteristics, then draws one building uniformly at random for
    each row in the geographical catalogue. Occupied rows match on all of ALLOCATION_KEYS;
    vacant rows match on VACANT_ALLOCATION_KEYS and so draw across the fuels present in the
    sample's vacant buildings. Rows that match no building on those keys walk the
    FALLBACK_LADDER, which releases Vintage and then Federal Poverty Level as well.

    Args:
        geo_df: Geographical data with sampling regions assigned
        bs_df: Buildstock sample data with building characteristics
        random_seed: Seed making the draws reproducible

    Returns:
        Tuple of (allocated_df, fkt) where:
            - allocated_df: Full allocation with all columns, including fallback_stage
            - fkt: Foreign key table with Building, tract_gisjoin, and puma_gisjoin
    """

    logger.info("Processing allocated weights")
    rng = np.random.default_rng(random_seed)
    is_vacant = pl.col("Vacancy Status").eq_missing("Vacant")

    allocated_frames = [
        allocate_down_the_ladder(geo_subset, bs_df, keys, rng)
        for keys, geo_subset in [
            (ALLOCATION_KEYS, geo_df.filter(~is_vacant)),
            (VACANT_ALLOCATION_KEYS, geo_df.filter(is_vacant)),
        ]
    ]

    allocated_df = pl.concat(allocated_frames, how="vertical")
    log_fallback_stages(allocated_df)

    # Extract foreign key table with building-to-geography mappings
    fkt = allocated_df.select(
        [pl.col("Building"), pl.col("tract_gisjoin"), pl.col("puma_gisjoin")]
    )

    return allocated_df, fkt


def stage_counts(allocated_df: pl.DataFrame) -> dict[str, int]:
    """Count allocated rows by the ladder rung that filled them.

    Args:
        allocated_df: Allocation carrying a fallback_stage column

    Returns:
        Row count per stage, in ladder order and omitting stages no row reached
    """

    counts = dict(allocated_df.group_by("fallback_stage").len().iter_rows())

    return {stage: counts[stage] for stage in FALLBACK_STAGES if stage in counts}


def log_fallback_stages(allocated_df: pl.DataFrame) -> None:
    """Log how many rows each rung of the fallback ladder filled.

    Args:
        allocated_df: Allocation carrying a fallback_stage column
    """

    total = allocated_df.height
    for stage, count in stage_counts(allocated_df).items():
        share = count / total if total else 0.0
        logger.info(f"Fallback stage {stage}: {count} rows ({share:.4%})")


def check_allocation_misses(
    allocated_df: pl.DataFrame,
    output_dir: FsspecOutputDir | None = None,
    null_building_threshold: float = DEFAULT_NULL_BUILDING_THRESHOLD,
) -> pl.DataFrame:
    """Report catalogue rows the fallback ladder still left without a building.

    The threshold is applied to the residue left after the ladder, not to the rows that missed
    on the full keys, so it measures the stock that genuinely has nothing to stand in for it.
    The miss report is written before the threshold is applied so the rows are on disk to
    inspect even when the run is rejected, each carrying the fallback_stage it reached.

    Args:
        allocated_df: Full allocation DataFrame carrying a fallback_stage column
        output_dir: Dictionary containing filesystem info from setup_fsspec_filesystem, or
            None to skip writing the miss report
        null_building_threshold: Fraction of unallocated rows tolerated before raising

    Returns:
        The unallocated rows

    Raises:
        ValueError: If the unallocated fraction exceeds null_building_threshold
    """

    misses = allocated_df.filter(pl.col("Building").is_null())
    miss_fraction = misses.shape[0] / allocated_df.shape[0] if allocated_df.shape[0] else 0.0
    by_status = dict(misses.group_by("Vacancy Status").len().iter_rows())
    by_stage = stage_counts(allocated_df)
    logger.info(
        f"{misses.shape[0]} of {allocated_df.shape[0]} rows ({miss_fraction:.4%}) found no "
        + f"matching building after the fallback ladder. By vacancy status: {by_status}. "
        + f"Rows by stage: {by_stage}"
    )

    if output_dir is not None:
        write_parquet_file(output_dir, misses, "allocation_miss_report.parquet")

    if miss_fraction > null_building_threshold:
        missing_regions = misses.select("Sampling Region").unique()
        raise ValueError(
            f"\n{misses.shape[0]} rows ({miss_fraction:.4%}) found no matching building even "
            + f"after releasing Vintage and Federal Poverty Level, above the "
            + f"{null_building_threshold:.4%} threshold.\n"
            + f"By vacancy status: {by_status}.\n"
            + f"Rows by stage: {by_stage}.\n"
            + f"Affected sampling regions: {missing_regions.to_series().to_list()}"
        )

    return misses


def write_parquet_file(output_dir: FsspecOutputDir, df: pl.DataFrame, file_name: str) -> None:
    """Write a DataFrame to parquet under the output directory, local or S3.

    Args:
        output_dir: Dictionary containing filesystem info from setup_fsspec_filesystem
        df: DataFrame to write
        file_name: Name of the parquet file within the output directory
    """

    logger.info(f"Writing {file_name} to {output_dir}")
    file_path = Path(output_dir["fs_path"]) / file_name
    if isinstance(output_dir["fs"], s3fs.S3FileSystem):
        file_path = f"s3://{file_path.as_posix()}"

    with output_dir["fs"].open(str(file_path), "wb") as f:
        LazyFrame(df).sink_parquet(f)
    logger.info(f"Finished writing {file_name}")


def write_parquet_outputs(output_dir: FsspecOutputDir, allocated_df: pl.DataFrame, fkt: pl.DataFrame) -> None:
    """Write allocation outputs to parquet files.

    Writes two files:
        - fkt.parquet: Foreign key table mapping buildings to geography
        - allocated_weights.parquet: Full allocation data

    Args:
        output_dir: Dictionary containing filesystem info from setup_fsspec_filesystem
        allocated_df: Full allocation DataFrame
        fkt: Foreign key table DataFrame
    """

    write_parquet_file(output_dir, fkt, "fkt.parquet")
    write_parquet_file(output_dir, allocated_df, "allocated_weights.parquet")
    logger.info("Completed creating allocated weights artifacts")

def create_allocated_weights(
    bs_file: str,
    output_dir: str,
    aws_profile_name=None,
    catalogue_file_version="v0",
    sampling_region_version="v1",
    random_seed: int = DEFAULT_RANDOM_SEED,
    null_building_threshold: float = DEFAULT_NULL_BUILDING_THRESHOLD,
) -> None:
    """Create allocated weights table from raw sample file and write to output parquet.

    This is the top-level orchestration function that:
    1. Sets up the filesystem
    2. Loads reference data (catalogue, sampling regions, climate zones)
    3. Merges geographical data with sampling regions
    4. Loads buildstock sample data
    5. Allocates buildings to geographical units, walking the fallback ladder for empty shelves
    6. Writes the miss report and checks the fraction the ladder still left unallocated
    7. Writes output files

    Args:
        bs_file: Path to the buildstock sample CSV file
        output_dir: Path to write output parquet files (local or S3)
        aws_profile_name: Optional AWS profile name for S3 access
        catalogue_file_version: Version of catalogue file to use (default 'v0')
        sampling_region_version: Version of sampling regions file to use (default 'v1')
        random_seed: Seed making the building draws reproducible
        null_building_threshold: Fraction of unallocated rows tolerated before raising
    """

    # Set up filesystem for local or S3 for output file
    logger.debug(f"Setting up filesystem for output directory: {output_dir}")
    output_dir = setup_fsspec_filesystem(output_dir, aws_profile_name)

    # Load reference data files
    catalogue_df = load_catalogue_file(output_dir, catalogue_file_version)
    sampling_regions_df = load_sampling_regions(output_dir, sampling_region_version)
    cec_2010_cz_lkup_df = load_cec_climate_zones(output_dir)

    # Merge geographical data with sampling region assignments
    geo_df = merge_geographical_data(
        catalogue_df, sampling_regions_df, cec_2010_cz_lkup_df
    )

    # Load buildstock sample data
    logger.info(f"Reading buildstock file from {bs_file}")
    bs_df = pl.read_csv(bs_file, infer_schema_length=10000)

    # Allocate buildings to geographical units
    allocated_df, fkt = allocate_buildings_to_geography(geo_df, bs_df, random_seed)

    # Surface catalogue rows that matched no building before writing the allocation itself
    check_allocation_misses(allocated_df, output_dir, null_building_threshold)

    # Write output parquet files
    write_parquet_outputs(output_dir, allocated_df, fkt)


if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    logger.info("hejhej")

    # Initialize argument parser
    parser = argparse.ArgumentParser(
        description="Process raw sample file and write allocation weights table"
    )
    parser.add_argument(
        "-s",
        "--sample_file",
        default="./geo_samples.csv",
        help="Path to the raw sample csv file",
    )
    parser.add_argument(
        "-o",
        "--output_dir",
        default="./../output/",
        help="Path to write the allocated weights output parquet to",
    )
    parser.add_argument(
        "--random_seed",
        type=int,
        default=DEFAULT_RANDOM_SEED,
        help="Seed for the building draws",
    )
    parser.add_argument(
        "--null_building_threshold",
        type=float,
        default=DEFAULT_NULL_BUILDING_THRESHOLD,
        help="Fraction of catalogue rows allowed to match no building before raising",
    )

    # Parse command-line arguments and call the create_allocated_weights function
    args = parser.parse_args()
    create_allocated_weights(
        args.sample_file,
        args.output_dir,
        random_seed=args.random_seed,
        null_building_threshold=args.null_building_threshold,
    )
