import boto3
import datetime
import json
import logging
import numpy as np
from pathlib import Path
import polars as pl
from polars.lazyframe.frame import LazyFrame
from resstockpostproc.utils import FsspecOutputDir, setup_fsspec_filesystem
import s3fs


from resstockpostproc.simulation_outputs import get_cached_simulation_outputs_for_upgrade

logger = logging.getLogger(__name__)

# Default seed for the random building-to-geography allocation so that identical
# inputs produce identical publications. Pass seed=None for unseeded allocation.
DEFAULT_ALLOCATION_SEED = 42

# Fraction of catalogue rows allowed to go unallocated before the run is treated as broken
DEFAULT_NULL_BUILDING_THRESHOLD = 0.005

# Characteristics that define a pool of interchangeable buildings for an occupied household
ALLOCATION_KEYS = [
    "in.sampling_region_id",
    "in.tenure",
    "in.vacancy_status",
    "in.geometry_building_type_recs",
    "in.vintage",
    "in.heating_fuel",
    "in.federal_poverty_level",
]

# ACS only surveys the fuel of occupied units, so the catalogue's vacant rows carry no
# heating fuel. Vacant rows draw across fuels instead, which reproduces the sample pool's
# conditional fuel mix within the remaining keys.
VACANT_ALLOCATION_KEYS = [key for key in ALLOCATION_KEYS if key != "in.heating_fuel"]

# Ladder of retries for catalogue rows whose shelf is empty. Each rung names the stage it
# records and the keys it releases from the join, so the row draws from a pool that has been
# widened over those characteristics. Vintage goes first because a building of the wrong
# vintage distorts the stock less than one of the wrong income bracket.
FALLBACK_LADDER = [
    ("matched_full", []),
    ("relaxed_vintage", ["in.vintage"]),
    ("relaxed_vintage_fpl", ["in.vintage", "in.federal_poverty_level"]),
]

# Stage recorded for rows the whole ladder failed to fill
UNMATCHED_STAGE = "unmatched"

# Every value the fallback_stage column can take, in ladder order
FALLBACK_STAGES = [stage for stage, _ in FALLBACK_LADDER] + [UNMATCHED_STAGE]

# Truth data (catalogue, sampling regions, CEC climate zone lookups) is downloaded
# from this bucket when not already present in the output directory. Environments
# without AWS credentials or internet access (e.g. HPC compute nodes) can pre-stage
# the files in the output directory instead; files found there are never re-downloaded.
TRUTH_DATA_BUCKET = "resstock-core"


def _download_truth_file(local_path, s3_key, file_desc: str) -> None:
    """Download a truth-data file from S3, with an actionable error on failure."""
    logger.info(f"{file_desc} not found locally, downloading from S3")
    try:
        s3_client = boto3.client("s3")
        s3_client.download_file(TRUTH_DATA_BUCKET, s3_key, str(local_path))
    except Exception as err:
        raise RuntimeError(
            f"Could not download {file_desc} from s3://{TRUTH_DATA_BUCKET}/{s3_key}. "
            f"If this machine has no AWS credentials or no internet access, pre-stage "
            f"the file at {local_path} and rerun; files already present locally are "
            f"not re-downloaded."
        ) from err
    logger.info(f"Downloaded {file_desc} to {local_path}")


def coerce_vacant_join_keys(catalogue_df: pl.DataFrame) -> pl.DataFrame:
    """Fill null tenure and federal poverty level on vacant catalogue rows with "Not Available".

    Args:
        catalogue_df: Catalogue data

    Returns:
        Catalogue data with vacant row join keys aligned to the buildstock sample's labels
    """

    is_vacant = pl.col("in.vacancy_status").eq_missing("Vacant")
    for column in ["in.tenure", "in.federal_poverty_level"]:
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


def load_catalogue_file(output_dir: FsspecOutputDir, catalogue_file_version: str) -> pl.DataFrame:
    """Load and preprocess catalogue file, downloading from S3 if necessary.

    Vacant rows are given the literal "Not Available" for tenure and federal poverty level so
    they match the buildstock sample, which labels vacant buildings that way. Heating fuel is
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
    if not output_dir["fs"].exists(catalogue_local_path):
        _download_truth_file(catalogue_local_path, f"truth_data/v01/StockE/{catalogue_file}", "Catalogue file")

    # Read catalogue and add county_gisjoin derived from first 8 chars of tract_gisjoin
    logger.info(f"Reading catalogue file from {catalogue_local_path}")
    catalogue_df = pl.read_parquet(catalogue_local_path)
    catalogue_df = catalogue_df.with_columns(
        pl.col("tract_gisjoin").str.slice(0, 8).alias("county_gisjoin")
    )

    # Add state_gisjoin derived from first 2 chars of tract_gisjoin
    catalogue_df = catalogue_df.with_columns(
        pl.col("tract_gisjoin").str.slice(0, 3).alias("state_gisjoin")
    )

    # Rename columns to match expected format
    catalogue_df = catalogue_df.rename(
        {
            "tract_gisjoin": "in.nhgis_tract_gisjoin",
            "puma_gisjoin": "in.nhgis_puma_gisjoin",
            "county_gisjoin": "in.nhgis_county_gisjoin",
            "state_gisjoin": "in.nhgis_state_gisjoin",
            "Tenure": "in.tenure",
            "Vacancy Status": "in.vacancy_status",
            "Geometry Building Type RECS": "in.geometry_building_type_recs",
            "Vintage": "in.vintage",
            "Heating Fuel": "in.heating_fuel",
            "Federal Poverty Level": "in.federal_poverty_level",
        }
    )

    # Load state-census region map
    state_table_file = "state_region_division_table.csv"
    state_table_local_path = f"{output_dir['fs_path']}/{state_table_file}"

    # Download from S3 if not already cached locally
    if not output_dir["fs"].exists(state_table_local_path):
        _download_truth_file(
            state_table_local_path, "truth_data/v01/EIA/CBECS/state_region_division_table.csv", "State table file"
        )

    # Read state table
    logger.info(f"Reading state table file from {state_table_local_path}")
    state_table_df = pl.read_csv(state_table_local_path)

    # Make the FIPS code a string with a "G" and leading zeros
    state_table_df = state_table_df.with_columns(
        (pl.lit("G") + pl.col("FIPS Code").cast(pl.Utf8).str.zfill(2)).alias("FIPS Code")
    )

    # Map state FIPS codes to state abbreviations
    state_table_df = state_table_df.with_columns(
        pl.col("FIPS Code").alias("in.nhgis_state_gisjoin"),
        pl.col("State Code").alias("in.state")
    )

    # Join the state abbreviations onto the catalogue
    catalogue_df = catalogue_df.join(
        state_table_df.select(["in.nhgis_state_gisjoin", "in.state"]),
        on="in.nhgis_state_gisjoin",
        how="left"
    )

    # Align vacant row join keys with how the buildstock sample labels vacant buildings
    catalogue_df = coerce_vacant_join_keys(catalogue_df)

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
    if not output_dir["fs"].exists(sample_regions_local_path):
        _download_truth_file(
            sample_regions_local_path, f"truth_data/v01/StockE/{sampling_regions_file}", "Sampling regions file"
        )

    # Load JSON file containing county to sampling region mappings
    logger.info(f"Reading sample file from {sample_regions_local_path}")
    with open(sample_regions_local_path) as f:
        sampling_regions_dict = json.load(f)

    # Manually add in Oglala Lakota County, SD which used to be Shannon county (G4601130)
    sampling_regions_dict["G4601020"] = 34

    # Convert dictionary to DataFrame
    sampling_regions_df = pl.DataFrame(
        {
            "in.nhgis_county_gisjoin": list(sampling_regions_dict.keys()),
            "in.sampling_region_id": list(sampling_regions_dict.values()),
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
    if not output_dir["fs"].exists(cec_2010_cz_lkup_local_path):
        _download_truth_file(
            cec_2010_cz_lkup_local_path, f"truth_data/v01/StockE/{cec_2010_cz_lkup_file}", "CEC 2010 CZ lookup file"
        )

    # Load JSON file containing tract to CEC climate zone mappings
    logger.info(f"Reading CEC 2010 CZ lookup file from {cec_2010_cz_lkup_local_path}")
    with open(cec_2010_cz_lkup_local_path) as f:
        cec_2010_cz_lkup_dict = json.load(f)

    # Convert to DataFrame and map CEC zones to sampling region numbers
    cec_2010_cz_lkup_df = pl.DataFrame(
        {
            "in.nhgis_tract_gisjoin": list(cec_2010_cz_lkup_dict.keys()),
            "in.sampling_region_id": list(cec_2010_cz_lkup_dict.values()),
        }
    )
    cec_2010_cz_lkup_df = cec_2010_cz_lkup_df.with_columns(
        pl.col("in.sampling_region_id").replace(ca_regions_lkup)
    )

    # This is future proofing code for the world where we upgrade to the 2020 census geographies
    # # Read cec_cz_by_tract_2020_lkup.json from local path or download from S3 if not found
    # cec_2020_cz_lkup_file = "cec_cz_by_tract_2020_lkup.json"
    # cec_2020_cz_lkup_local_path = f"{output_dir['fs_path']}/{cec_2020_cz_lkup_file}"
    # if not output_dir["fs"].exists(cec_2020_cz_lkup_local_path):
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
    #     "in.nhgis_tract_gisjoin": list(cec_2020_cz_lkup_dict.keys()),
    #     "in.sampling_region_id": list(cec_2020_cz_lkup_dict.values())
    # })
    # cec_2020_cz_lkup_df = cec_2020_cz_lkup_df.with_columns(pl.col('in.sampling_region_id').replace(ca_regions_lkup))

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
    df = catalogue_df.join(sampling_regions_df, on="in.nhgis_county_gisjoin", how="left")

    # Join with CEC climate zone-based sampling regions (covers California)
    df = df.join(cec_2010_cz_lkup_df, on="in.nhgis_tract_gisjoin", how="left", suffix="_cec2010")
    # df = df.join(cec_2020_cz_lkup_df, on="in.nhgis_tract_gisjoin", how="left", suffix="_cec2020")

    # Use county-based region, falling back to CEC climate zone region for CA tracts
    df = df.with_columns(
        pl.coalesce(
            [
                pl.col("in.sampling_region_id"),
                pl.col(
                    "in.sampling_region_id_cec2010"
                ),  # , pl.col("sampling_region_cec2020")
            ]
        )
        .cast(pl.Int64)
        .alias("in.sampling_region_id")
    )

    # Clean up temporary columns and rename to final column name
    df = df.drop(["in.sampling_region_id_cec2010"])  # , "in.sampling_region_id_cec2020"])

    # Validate that all rows have been assigned a sampling region. Only this column is checked
    # because vacant rows legitimately carry a null heating fuel.
    missing_region = df.filter(pl.col("in.sampling_region_id").is_null())
    if missing_region.shape[0] > 0:
        missing_counties = missing_region.select("in.nhgis_county_gisjoin").unique()
        missing_tracts = missing_region.select("in.nhgis_tract_gisjoin").unique()
        raise ValueError(
            f"\n{missing_region.shape[0]} rows are missing sampling regions.\n"
            f"Missing counties: {missing_counties.to_series().to_list()}.\n"
            f"Missing tracts: {missing_tracts.to_series().to_list()}"
        )
    logger.info("Successfully assigned sampling regions")

    # Convert sampling_region_id to string to match the type in bs_df
    df = df.with_columns(pl.col("in.sampling_region_id").cast(pl.Utf8))

    return df


def draw_from_pools(df: pl.DataFrame, rng: np.random.Generator) -> pl.DataFrame:
    """Replace each row's list of candidate buildings with one building drawn from it.

    Every row gets its own uniform variate, so the draw is independent row to row and uniform
    over that row's pool. Rows whose pool is null, because the join found no matching buildings,
    keep a null bldg_id.

    Args:
        df: Frame whose bldg_id column holds a list of candidate buildings per row
        rng: Seeded generator supplying one uniform variate per row

    Returns:
        Frame with bldg_id reduced to a single drawn building per row
    """

    return (
        df.with_columns(pl.Series("draw", rng.random(df.height), dtype=pl.Float64))
        .with_columns(
            pl.col("bldg_id").list.get(
                (pl.col("draw") * pl.col("bldg_id").list.len()).floor().cast(pl.Int64),
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
        The catalogue rows with a bldg_id column, null where the pool was empty
    """

    # Group buildstock buildings by the key characteristics to create pools of similar
    # buildings, then join those pools onto the catalogue rows that share them. Pool order
    # is held stable so that a given seed reproduces a given allocation.
    grouped_df = bs_df.group_by(keys).agg(pl.col("bldg_id").unique(maintain_order=True))
    joined_df = geo_subset.lazy().join(grouped_df.lazy(), on=keys, how="left").collect()

    return draw_from_pools(joined_df, rng)


def allocate_down_the_ladder(
    geo_subset: pl.DataFrame, bs_df: pl.DataFrame, keys: list[str], rng: np.random.Generator
) -> pl.DataFrame:
    """Draw a building for every catalogue row, widening the pool for rows that find none.

    Rows are first matched on the full `keys`. Whatever finds an empty shelf is retried on each
    remaining rung of FALLBACK_LADDER, drawing from a pool widened over the keys that rung
    releases. Rows the last rung still cannot fill keep a null bldg_id. The rung that filled a
    row, or UNMATCHED_STAGE, is recorded in fallback_stage.

    Args:
        geo_subset: Catalogue rows sharing a matching regime, occupied or vacant
        bs_df: Buildstock sample data with building characteristics
        keys: Characteristics matched on the first rung
        rng: Seeded generator supplying one uniform variate per row per rung

    Returns:
        The catalogue rows with bldg_id and fallback_stage columns
    """

    filled_frames = []
    remaining = geo_subset
    # The first rung always runs, so an empty subset still yields a frame carrying the columns
    for stage, released_keys in FALLBACK_LADDER:
        stage_keys = [key for key in keys if key not in released_keys]
        drawn = draw_on_keys(remaining, bs_df, stage_keys, rng).with_columns(
            pl.lit(stage).alias("fallback_stage")
        )
        filled_frames.append(drawn.filter(pl.col("bldg_id").is_not_null()))
        remaining = drawn.filter(pl.col("bldg_id").is_null()).drop(["bldg_id", "fallback_stage"])
        if remaining.height == 0:
            break

    if remaining.height:
        filled_frames.append(
            remaining.with_columns(
                pl.lit(None, dtype=bs_df.schema["bldg_id"]).alias("bldg_id"),
                pl.lit(UNMATCHED_STAGE).alias("fallback_stage"),
            )
        )

    return pl.concat(filled_frames, how="vertical")


def allocate_buildings_to_geography(
    geo_df: pl.DataFrame, bs_df: pl.DataFrame, seed: int | None = DEFAULT_ALLOCATION_SEED
) -> tuple[pl.DataFrame, pl.DataFrame]:
    """Allocate buildings from sample to geographical units.

    Groups buildings by key characteristics, then draws one building uniformly at random for
    each row in the geographical catalogue. Occupied rows match on all of ALLOCATION_KEYS;
    vacant rows match on VACANT_ALLOCATION_KEYS and so draw across the fuels present in the
    sample's vacant buildings. Rows that match no building on those keys walk the
    FALLBACK_LADDER, which releases vintage and then federal poverty level as well.

    Args:
        geo_df: Geographical data with sampling regions assigned
        bs_df: Buildstock sample data with building characteristics
        seed: Seed for the random draws so identical inputs produce identical
            allocations. Pass None for unseeded (non-reproducible) allocation.

    Returns:
        Tuple of (allocated_df, fkt) where:
            - allocated_df: Full allocation with all columns, including fallback_stage
            - fkt: Foreign key table with bldg_id, tract_gisjoin, and puma_gisjoin
    """

    logger.info(f"Allocating simulated buildings to geographical units (seed={seed})")
    rng = np.random.default_rng(seed)
    is_vacant = pl.col("in.vacancy_status").eq_missing("Vacant")

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
        [pl.col("bldg_id"), pl.col("in.nhgis_tract_gisjoin"), pl.col("in.nhgis_puma_gisjoin")]
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

    misses = allocated_df.filter(pl.col("bldg_id").is_null())
    miss_fraction = misses.shape[0] / allocated_df.shape[0] if allocated_df.shape[0] else 0.0
    by_status = dict(misses.group_by("in.vacancy_status").len().iter_rows())
    by_stage = stage_counts(allocated_df)
    logger.info(
        f"{misses.shape[0]} of {allocated_df.shape[0]} rows ({miss_fraction:.4%}) found no "
        f"matching building after the fallback ladder. By vacancy status: {by_status}. "
        f"Rows by stage: {by_stage}"
    )

    if output_dir is not None:
        write_parquet_file(output_dir, misses, "allocation_miss_report.parquet")

    if miss_fraction > null_building_threshold:
        missing_regions = misses.select("in.sampling_region_id").unique()
        raise ValueError(
            f"\n{misses.shape[0]} rows ({miss_fraction:.4%}) found no matching building even "
            f"after releasing vintage and federal poverty level, above the "
            f"{null_building_threshold:.4%} threshold.\n"
            f"By vacancy status: {by_status}.\n"
            f"Rows by stage: {by_stage}.\n"
            f"Affected sampling regions: {missing_regions.to_series().to_list()}"
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
        - cached_allocated_weights.parquet: Full allocation data

    Args:
        output_dir: Dictionary containing filesystem info from setup_fsspec_filesystem
        allocated_df: Full allocation DataFrame
        fkt: Foreign key table DataFrame
    """

    write_parquet_file(output_dir, fkt, "fkt.parquet")
    write_parquet_file(output_dir, allocated_df, "cached_allocated_weights.parquet")
    logger.info("Completed creating allocated weights artifacts")


def create_allocated_weights_for_quota_sampler(
    simulation_outputs_file: str, output_dir: str, aws_profile_name=None
) -> None:
    """Create allocated weights specifically for the quota sampler.
    This version of the method simply uses the `weight` column already present
    in the simulation outputs from buildstockbatch.
    
    Args:
        simulation_outputs_file: Path to the simulation outputs Parquet file
        output_dir: Path to write output parquet files (local or S3)
        aws_profile_name: Optional AWS profile name for S3 access
    """

    # Set up filesystem for local or S3 for output file
    logger.debug(f"Setting up filesystem for output directory: {output_dir}")
    output_dir = setup_fsspec_filesystem(output_dir, aws_profile_name)

    # Load simulation outputs
    logger.info(f"Reading simulation outputs from {simulation_outputs_file}")
    sim_outs = pl.read_parquet(simulation_outputs_file)

    # Rename the "as-simulated" geography columns
    sim_outs = sim_outs.rename({"in.as_simulated_state": "in.state"})

    # Downselect to just the columns expected in allocated weights
    alloc_wts = sim_outs.select(
        [
            "bldg_id",
            "weight",
            "in.sampling_region_id",
            "in.tenure",
            "in.vacancy_status",
            "in.geometry_building_type_recs",
            "in.vintage",
            "in.heating_fuel",
            "in.federal_poverty_level",
            "in.state"            
        ]
    )

    # Write output parquet files
    write_parquet_outputs(output_dir, alloc_wts, alloc_wts)


def create_allocated_weights(
    simulation_outputs_file: str,
    output_dir: str,
    aws_profile_name=None,
    catalogue_file_version="v0",
    sampling_region_version="v1",
    seed: int | None = DEFAULT_ALLOCATION_SEED,
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
        simulation_outputs_file: Path to the simulation outputs Parquet file
        output_dir: Path to write output parquet files (local or S3)
        aws_profile_name: Optional AWS profile name for S3 access
        catalogue_file_version: Version of catalogue file to use (default 'v0')
        sampling_region_version: Version of sampling regions file to use (default 'v1')
        seed: Seed for the random building-to-geography allocation so identical
            inputs produce identical publications. Pass None for unseeded allocation.
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

    # Load simulation outputs
    logger.info(f"Reading simulation outputs from {simulation_outputs_file}")
    sim_outs = pl.read_parquet(simulation_outputs_file)

    # Allocate buildings to geographical units
    allocated_df, fkt = allocate_buildings_to_geography(geo_df, sim_outs, seed=seed)

    # Surface catalogue rows that matched no building before writing the allocation itself
    check_allocation_misses(allocated_df, output_dir, null_building_threshold)

    # Add weight column (each row represents one housing unit)
    allocated_df = allocated_df.with_columns(pl.lit(1).alias("weight"))

    # Write output parquet files
    write_parquet_outputs(output_dir, allocated_df, fkt)


def get_cached_allocated_weights(output_dir) -> pl.LazyFrame:

    # Read the cached allocated weights
    cached_wts_path = f"{output_dir['fs_path']}/cached_allocated_weights.parquet"
    if isinstance(output_dir["fs"], s3fs.S3FileSystem):
        cached_wts_path = f"s3://{Path(cached_wts_path).as_posix()}"
    if not output_dir["fs"].exists(cached_wts_path):
        raise FileNotFoundError(
        f"Cannot load allocated weights from {cached_wts_path}, call create_allocated_weights() first.")
    alloc_weights = pl.scan_parquet(cached_wts_path, storage_options=output_dir["storage_options"])

    return alloc_weights


def create_allocated_weights_plus_util_bills_for_upgrade(output_dir, upgrade_id) -> None:
    """

    Each building is simulated in only one location, so the energy consumption results are the
    same regardless of where this building is allocated. However, utility rates are calculated
    for each of the possible locations where a building could be allocated. For each building,
    this step pulls the utility bills for the assigned location.

    The simulation outputs have a set of utility bill results columns for each state. e.g.
    bldg_id | electric_bill_AK | gas_bill_AK | electric_bill_WA | gas_bill_WA | electric_bill_OR | gas_bill_OR
    1234    | 1000             | 500         | 500              | 200         | 300              | 100    
    Unpivot the utility bill columns so that each row corresponds to a single utility bill/state pair. e.g.
    bldg_id | state | electric_bill | gas_bill | ...
    1234    | AK    | 1000          | 500      |
    1234    | WA    | 500           | 200      |
    1234    | OR    | 300           | 100      |

    After unpivoting, the utility bills can be joined with the allocated weights to determine the
    utility costs for the assigned location of each building.

    """
    # # Late import to avoid circular dependency
    # from resstockpostproc.simulation_outputs import get_cached_simulation_outputs_for_upgrade
    
    logger.warning("TODO Setting utility bills for each building based on the allocated location.")
    # Read the cached simulation results
    sim_outs = get_cached_simulation_outputs_for_upgrade(output_dir, upgrade_id)

    # Read the cached allocated weights
    alloc_wts = get_cached_allocated_weights(output_dir)

    # Add the upgrade ID to the allocated weights
    alloc_wts = alloc_wts.with_columns([
            pl.lit(upgrade_id).cast(pl.Int64).alias("upgrade")
        ])

    # Where the results will be cached
    alloc_wts_bills_dir = f'{output_dir["fs_path"]}/cached_allocated_weights_plus_bills/upgrade={upgrade_id}'
    logger.info(f"Creating allocated weights plus bills for upgrade {upgrade_id}")
    
    logger.warning("TODO Calculate the bills once the per-state bill columns are availble")
    # # Unpivot the utility bill columns so that each row corresponds to a single utility bill/state pair
    # sim_outs = sim_outs.unpivot(
    #     id_vars=["bldg_id", "state"],
    #     value_vars="COLS_UTIL_BILLS",
    #     variable_name="UTIL_BILL_TYPE",
    #     value_name="UTIL_BILL_AMOUNT"
    # )

    # # Join the utility bills onto each building based on building ID and state
    # alloc_wts = alloc_wts.join(sim_outs, on=["bldg_id", "state"], how="left")

    # Calculate weighted utility bill columns based on the allocated weights TODO
    # conv_fact = conv_fact('usd', weighted_utility_units)
    # cost_cols = (UTIL_ELEC_BILL_COSTS + COST_STATE_UTIL_COSTS + [UTIL_BILL_TOTAL_MEAN])
    # for col in cost_cols:
    #     weighted_col_name = col_name_to_weighted(col, weighted_utility_units)
    #     unweighted_weighted_map.update({col: weighted_col_name})

    # TODO calculate the unweighted utility cost savings here?
    # would require doing the baseline and upgrade.

    # TODO consider if we want to calculate the weighted utility costs here
    # or in the next step after we aggregate to a specific geography.
    # Calculate weighted utility costs
    # alloc_wts = alloc_wts.with_columns(
    #     [pl.col(col)
    #         .cast(pl.Int64)
    #         .mul(pl.col(BLDG_WEIGHT))
    #         .mul(conv_fact)
    #         .alias(col_name_to_weighted(col, weighted_utility_units))
    #         for col in cost_cols
    #     ]
    # )

    # Write to parquet file, hive partition on upgrade to make later processing faster
    if not isinstance(output_dir["fs"], s3fs.S3FileSystem):
        output_dir["fs"].mkdirs(alloc_wts_bills_dir, exist_ok=True)
    collect_tstart = datetime.datetime.now()
    alloc_wts = alloc_wts.collect()
    collect_tend = datetime.datetime.now()
    elapsed_time = (collect_tend - collect_tstart).total_seconds()
    logger.info(f"Collect time for upgrade {upgrade_id}: {elapsed_time} seconds")
    alloc_wts = alloc_wts.drop("upgrade")  # upgrade column will be read from hive partition dir name
    logger.info(f"Caching allocated weights plus bills for upgrade {upgrade_id} to: {alloc_wts_bills_dir}")
    # Cache by state to enable faster reading
    for state_abbv_tuple, state_alloc_wts in alloc_wts.group_by("in.state"):
        state_abbv = state_abbv_tuple[0]
        cached_file_name = f"cached_allocated_weights_plus_bills_upgrade{upgrade_id}_{state_abbv}.parquet"
        logger.info(f"Caching {cached_file_name}")
        alloc_wts_bills_state_dir = f"{alloc_wts_bills_dir}/state={state_abbv}"
        if not isinstance(output_dir["fs"], s3fs.S3FileSystem):
            output_dir["fs"].mkdirs(alloc_wts_bills_state_dir, exist_ok=True)
        cached_file_path = f"{alloc_wts_bills_state_dir}/{cached_file_name}"
        with output_dir["fs"].open(cached_file_path, "wb") as f:
            state_alloc_wts.write_parquet(f)


def get_allocated_weights_plus_util_bills_for_upgrade(output_dir, upgrade_id) -> pl.LazyFrame:
    """
    Get the allocated weights plus utility bills for a specific upgrade.
    Files must have already been written to disk
    by calling create_allocated_weights_plus_util_bills_for_upgrade().

    Parameters:
    output_dir (dict): Dictionary containing the output directory information.
    upgrade_id (int): The ID of the upgrade.

    Returns:
    pl.LazyFrame: A long (~120M rows) Polars LazyFrame containing the allocated weights plus utility bills.
    """

    # Check if the allocated weights plus bills directory exists for the given upgrade
    alloc_wts_bills_dir = f"{output_dir['fs_path']}/cached_allocated_weights_plus_bills/upgrade={upgrade_id}"
    if isinstance(output_dir["fs"], s3fs.S3FileSystem):
        alloc_wts_bills_dir = f"s3://{alloc_wts_bills_dir}"
    if not output_dir["fs"].exists(alloc_wts_bills_dir):
        logger.error(f"Allocated weights plus bills directory does not exist: {alloc_wts_bills_dir}")
        raise FileNotFoundError(
            f"Cannot load allocated weights plus bills for upgrade {upgrade_id} from "
            f"{alloc_wts_bills_dir}, call create_allocated_weights_plus_util_bills_for_upgrade() first."
        )

    # Find the existing parquet files
    state_pqts = []
    pqt_glob = f"{alloc_wts_bills_dir}/**/cached_allocated_weights_plus_bills_*.parquet"
    for p in output_dir["fs"].glob(pqt_glob):
        if isinstance(output_dir["fs"], s3fs.S3FileSystem):
            state_pqts.append(f"s3://{p}")
        else:
            state_pqts.append(p)
    if state_pqts:
        logger.info(f"Reloading allocated weights plus bills from: {alloc_wts_bills_dir}")
    else:
        logger.error(f"No cached parquet files were found in {alloc_wts_bills_dir}")
        raise FileNotFoundError(
            f"Cannot load allocated weights plus bills for upgrade {upgrade_id} from "
            f"{alloc_wts_bills_dir}, call create_allocated_weights_plus_util_bills_for_upgrade() first."
        )

    # Scan and return existing parquet files as a LazyFrame
    alloc_wts = pl.scan_parquet(state_pqts, hive_partitioning=True, storage_options=output_dir["storage_options"])

    return alloc_wts
