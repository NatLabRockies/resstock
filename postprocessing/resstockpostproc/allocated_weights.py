import boto3
import datetime
import json
import logging
import numpy as np
from collections.abc import Iterator, Sequence
from pathlib import Path
import polars as pl
from resstockpostproc.utils import FsspecOutputDir, setup_fsspec_filesystem
import s3fs
import zlib


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

# Keys a vacant row falls back to when its catalogue carries no heating fuel for it.
# Releasing the fuel makes the row draw across whatever fuels the sample's vacant buildings
# happen to carry, which is the pool's design mix rather than the stock's, so it applies
# only to the rows a catalogue has left null.
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

# The catalogue is one row per US housing unit -- around 137 million of them, some 15 GB
# once it and its derived columns are in memory, and several times that again while a join
# is in flight. It is therefore never held whole: it is staged to one parquet partition per
# sampling region in a single streaming pass, and the allocation then runs a region at a
# time, so peak memory is set by the largest single region instead of by the whole country.
#
# Chunking this way is exact rather than an approximation. in.sampling_region_id is an
# allocation key, and FALLBACK_LADDER only ever releases vintage and federal poverty level,
# so no catalogue row can draw a building from outside its own sampling region however the
# work is divided up.
CATALOGUE_PARTITION_DIR = "cached_catalogue_by_sampling_region"
ALLOCATED_WEIGHTS_DIR = "cached_allocated_weights"

# Directory name for one region's partition, in both of the directories above
SAMPLING_REGION_PARTITION = "sampling_region"


def _polars_path(output_dir: FsspecOutputDir, *parts: str) -> str:
    """Join a path below the output directory into the form polars' scan/sink calls expect.

    Args:
        output_dir: Dictionary containing filesystem info from setup_fsspec_filesystem
        parts: Path segments below the output directory

    Returns:
        The joined path, carrying the s3:// scheme when the output directory is on S3
    """

    path = "/".join([str(output_dir["fs_path"]).rstrip("/"), *(p.strip("/") for p in parts)])

    return f"s3://{path}" if isinstance(output_dir["fs"], s3fs.S3FileSystem) else path


def region_seed(seed: int | None, region_id: str) -> Sequence[int] | None:
    """Derive the seed for one sampling region's draws.

    Seeding per region, rather than running one generator across the whole catalogue, keeps a
    region's allocation independent of the order the regions happen to be processed in, so the
    same inputs reproduce the same allocation however the work is chunked. crc32 is used rather
    than hash() because it is stable across processes, platforms and python versions.

    Args:
        seed: The run's seed, or None for unseeded (non-reproducible) allocation
        region_id: The sampling region the draws are for

    Returns:
        A seed for np.random.default_rng, or None when seed is None
    """

    return None if seed is None else [seed, zlib.crc32(str(region_id).encode())]


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


def _ensure_truth_file(output_dir: FsspecOutputDir, file_name: str, s3_key: str, file_desc: str) -> str:
    """Return the path to a truth-data file below the output directory, downloading it if absent.

    Args:
        output_dir: Dictionary containing filesystem info from setup_fsspec_filesystem
        file_name: Name of the file within the output directory
        s3_key: Key of the file within TRUTH_DATA_BUCKET
        file_desc: Human readable description used in log and error messages

    Returns:
        The path to the file on the output filesystem
    """

    local_path = f"{output_dir['fs_path']}/{file_name}"
    if not output_dir["fs"].exists(local_path):
        _download_truth_file(local_path, s3_key, file_desc)

    return local_path


def scan_catalogue(output_dir: FsspecOutputDir, catalogue_file_version: str) -> pl.LazyFrame:
    """Scan the catalogue file, downloading it if necessary, and derive its geography columns.

    Returned lazily: the catalogue is one row per US housing unit, so reading it whole costs
    more memory than the rest of the pipeline put together. Callers that only need part of it,
    or that stream it out again, should never materialise it.

    Vacant row join keys are NOT coerced here, because doing so needs a row count to log and so
    would force the frame. coerce_vacant_join_keys is applied per partition instead, once the
    catalogue has been split into pieces small enough to hold.

    Args:
        output_dir: Dictionary containing filesystem info from setup_fsspec_filesystem
        catalogue_file_version: Version string for catalogue file (e.g., 'v2')

    Returns:
        Polars LazyFrame over the catalogue, with the gisjoin and state columns derived
    """

    # Construct file path for catalogue file, downloading it if it isn't staged already
    catalogue_file = f"pums_2019_5yrs_acs_catalogue_{catalogue_file_version}.parquet"
    catalogue_path = _ensure_truth_file(
        output_dir, catalogue_file, f"truth_data/v01/StockE/{catalogue_file}", "Catalogue file"
    )

    # Scan the catalogue and add county_gisjoin and state_gisjoin, the leading 8 and 3
    # characters of the tract gisjoin respectively
    logger.info(f"Scanning catalogue file from {catalogue_path}")
    catalogue_lf = pl.scan_parquet(
        _polars_path(output_dir, catalogue_file), storage_options=output_dir["storage_options"]
    ).with_columns(
        pl.col("tract_gisjoin").str.slice(0, 8).alias("county_gisjoin"),
        pl.col("tract_gisjoin").str.slice(0, 3).alias("state_gisjoin"),
    )

    # Rename columns to match expected format
    catalogue_lf = catalogue_lf.rename(
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
    state_table_path = _ensure_truth_file(
        output_dir,
        "state_region_division_table.csv",
        "truth_data/v01/EIA/CBECS/state_region_division_table.csv",
        "State table file",
    )

    # Read state table
    logger.info(f"Reading state table file from {state_table_path}")
    state_table_df = pl.read_csv(state_table_path)

    # Make the FIPS code a string with a "G" and leading zeros, and map it to state abbreviations
    state_table_df = state_table_df.with_columns(
        (pl.lit("G") + pl.col("FIPS Code").cast(pl.Utf8).str.zfill(2)).alias("in.nhgis_state_gisjoin"),
        pl.col("State Code").alias("in.state"),
    )

    # Join the state abbreviations onto the catalogue
    catalogue_lf = catalogue_lf.join(
        state_table_df.select(["in.nhgis_state_gisjoin", "in.state"]).lazy(),
        on="in.nhgis_state_gisjoin",
        how="left",
    )

    return catalogue_lf


def load_catalogue_file(output_dir: FsspecOutputDir, catalogue_file_version: str) -> pl.DataFrame:
    """Load and preprocess catalogue file, downloading from S3 if necessary.

    Vacant rows are given the literal "Not Available" for tenure and federal poverty level so
    they match the buildstock sample, which labels vacant buildings that way. Heating fuel
    needs no such coercion: the catalogue carries a real fuel on a vacant row, and a null
    left in one is handled by allocate_buildings_to_geography's released join.

    This reads the whole catalogue into memory, which for the national catalogue is around
    15 GB. create_allocated_weights does not use it; it streams through scan_catalogue
    instead. It remains for callers working with a catalogue small enough to hold.

    Args:
        output_dir: Dictionary containing filesystem info from setup_fsspec_filesystem
        catalogue_file_version: Version string for catalogue file (e.g., 'v2')

    Returns:
        Polars DataFrame with catalogue data including county_gisjoin column
    """

    catalogue_df = scan_catalogue(output_dir, catalogue_file_version).collect()

    # Align vacant row join keys with how the buildstock sample labels vacant buildings
    return coerce_vacant_join_keys(catalogue_df)

def load_sampling_regions(output_dir: FsspecOutputDir, sampling_region_version: str) -> pl.DataFrame:
    """Load sampling regions mapping, downloading from S3 if necessary.

    Args:
        output_dir: Dictionary containing filesystem info from setup_fsspec_filesystem
        sampling_region_version: Version string for sampling regions file (e.g., 'v1')

    Returns:
        Polars DataFrame with county_gisjoin to sampling_region mapping
    """

    # Construct file path for sampling regions JSON file, downloading it if it isn't staged already
    sampling_regions_file = f"sampling_regions_{sampling_region_version}.json"
    sample_regions_local_path = _ensure_truth_file(
        output_dir,
        sampling_regions_file,
        f"truth_data/v01/StockE/{sampling_regions_file}",
        "Sampling regions file",
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

    # Construct file path for CEC climate zone lookup file, downloading it if it isn't staged already
    cec_2010_cz_lkup_file = "cec_cz_by_tract_2010_lkup.json"
    cec_2010_cz_lkup_local_path = _ensure_truth_file(
        output_dir,
        cec_2010_cz_lkup_file,
        f"truth_data/v01/StockE/{cec_2010_cz_lkup_file}",
        "CEC 2010 CZ lookup file",
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

def assign_sampling_regions(
    catalogue: pl.LazyFrame, sampling_regions_df: pl.DataFrame, cec_2010_cz_lkup_df: pl.DataFrame,
) -> pl.LazyFrame:
    """Attach the sampling region each catalogue row falls in.

    Uses county-based sampling regions for most of the US and CEC climate zone-based
    sampling regions for California tracts.

    The assignment depends only on the tract and county gisjoins, so it can be applied
    to the catalogue itself or to just its distinct geographies. Rows in neither lookup
    keep a null region; validate_sampling_region_coverage is what rejects those.

    Args:
        catalogue: Catalogue data with tract and county information
        sampling_regions_df: County to sampling region mapping
        cec_2010_cz_lkup_df: California tract to sampling region mapping via CEC climate zones

    Returns:
        LazyFrame with an in.sampling_region_id column, as a string to match the type in bs_df
    """

    # Join catalogue with county-based sampling regions (covers most of US)
    lf = catalogue.join(sampling_regions_df.lazy(), on="in.nhgis_county_gisjoin", how="left")

    # Join with CEC climate zone-based sampling regions (covers California)
    lf = lf.join(cec_2010_cz_lkup_df.lazy(), on="in.nhgis_tract_gisjoin", how="left", suffix="_cec2010")
    # lf = lf.join(cec_2020_cz_lkup_df.lazy(), on="in.nhgis_tract_gisjoin", how="left", suffix="_cec2020")

    # Use county-based region, falling back to CEC climate zone region for CA tracts.
    # Cast to string to match the type in bs_df, via Int64 so the label is "34" not "34.0".
    lf = lf.with_columns(
        pl.coalesce(
            [
                pl.col("in.sampling_region_id"),
                pl.col(
                    "in.sampling_region_id_cec2010"
                ),  # , pl.col("sampling_region_cec2020")
            ]
        )
        .cast(pl.Int64)
        .cast(pl.Utf8)
        .alias("in.sampling_region_id")
    )

    # Clean up temporary columns
    return lf.drop(["in.sampling_region_id_cec2010"])  # , "in.sampling_region_id_cec2020"])


def validate_sampling_region_coverage(
    catalogue: pl.LazyFrame, sampling_regions_df: pl.DataFrame, cec_2010_cz_lkup_df: pl.DataFrame,
) -> None:
    """Check that every geography in the catalogue maps to a sampling region.

    The check runs over the catalogue's distinct tract/county pairs rather than its rows.
    A region is a function of those two columns alone, so this reaches the same verdict as
    checking every row while reading two columns of the catalogue instead of all of them.

    Args:
        catalogue: Catalogue data with tract and county information
        sampling_regions_df: County to sampling region mapping
        cec_2010_cz_lkup_df: California tract to sampling region mapping via CEC climate zones

    Raises:
        ValueError: If any geography is missing a sampling region assignment
    """

    logger.info("Checking that every catalogue geography maps to a sampling region")
    geographies = catalogue.select(
        pl.col("in.nhgis_tract_gisjoin"), pl.col("in.nhgis_county_gisjoin")
    ).unique()
    assigned = assign_sampling_regions(geographies, sampling_regions_df, cec_2010_cz_lkup_df)

    # Only the region column is checked; this frame carries the two geography columns alone
    missing_region = assigned.filter(pl.col("in.sampling_region_id").is_null()).collect(engine="streaming")
    if missing_region.height > 0:
        missing_counties = missing_region["in.nhgis_county_gisjoin"].unique().to_list()
        missing_tracts = missing_region["in.nhgis_tract_gisjoin"].unique().to_list()
        raise ValueError(
            f"\n{missing_region.height} census tracts are missing sampling regions.\n"
            f"Missing counties: {missing_counties}.\n"
            f"Missing tracts: {missing_tracts}"
        )
    logger.info("Successfully assigned sampling regions")


def merge_geographical_data(
    catalogue_df: pl.DataFrame, sampling_regions_df: pl.DataFrame, cec_2010_cz_lkup_df: pl.DataFrame,
) -> pl.DataFrame:
    """Merge catalogue with sampling region assignments, in memory.

    create_allocated_weights does not use this; it streams the same assignment through
    partition_catalogue_by_sampling_region instead. It remains for callers working with a
    catalogue small enough to hold.

    Args:
        catalogue_df: Catalogue data with tract and county information
        sampling_regions_df: County to sampling region mapping
        cec_2010_cz_lkup_df: California tract to sampling region mapping via CEC climate zones

    Returns:
        Merged DataFrame with an in.sampling_region_id column assigned for all rows

    Raises:
        ValueError: If any rows are missing sampling region assignments
    """

    logger.info("Merging catalogue and sample regions data")
    validate_sampling_region_coverage(catalogue_df.lazy(), sampling_regions_df, cec_2010_cz_lkup_df)

    return assign_sampling_regions(catalogue_df.lazy(), sampling_regions_df, cec_2010_cz_lkup_df).collect()


def _region_partition_path(region_id: str) -> str:
    """Return the path of one region's partition, relative to the partition directory."""

    return f"{SAMPLING_REGION_PARTITION}={region_id}/{SAMPLING_REGION_PARTITION}_{region_id}.parquet"


def partition_catalogue_by_sampling_region(
    output_dir: FsspecOutputDir,
    catalogue_file_version: str = "v2",
    sampling_region_version: str = "v1",
    rewrite: bool = False,
) -> str:
    """Stage the catalogue as one parquet file per sampling region.

    A single streaming pass, so the whole catalogue is never resident: only the morsels in
    flight and one open writer per region are held. The result is the working set for the
    allocation, which then reads a region at a time.

    The pass is skipped when the partitions are already staged, so a rerun after a failure
    later in the pipeline does not repeat it. Pass rewrite=True to force it, which is needed
    if the catalogue version or the sampling region version changes.

    Args:
        output_dir: Dictionary containing filesystem info from setup_fsspec_filesystem
        catalogue_file_version: Version of catalogue file to use
        sampling_region_version: Version of sampling regions file to use
        rewrite: Rebuild the partitions even when they are already present

    Returns:
        The path of the partition directory
    """

    partition_dir = _polars_path(output_dir, CATALOGUE_PARTITION_DIR)
    existing = output_dir["fs"].glob(f"{partition_dir}/*/*.parquet")
    if existing and not rewrite:
        logger.info(f"Reusing {len(existing)} staged catalogue partitions in {partition_dir}")
        return partition_dir

    catalogue_lf = scan_catalogue(output_dir, catalogue_file_version)
    sampling_regions_df = load_sampling_regions(output_dir, sampling_region_version)
    cec_2010_cz_lkup_df = load_cec_climate_zones(output_dir)

    # Reject a catalogue with geographies outside the lookups before spending a pass on it
    validate_sampling_region_coverage(catalogue_lf, sampling_regions_df, cec_2010_cz_lkup_df)

    logger.info(f"Staging the catalogue by sampling region to {partition_dir}")
    tstart = datetime.datetime.now()
    assign_sampling_regions(catalogue_lf, sampling_regions_df, cec_2010_cz_lkup_df).sink_parquet(
        pl.PartitionBy(
            f"{partition_dir}/",
            key="in.sampling_region_id",
            include_key=True,
            file_path_provider=lambda args: _region_partition_path(args.partition_keys.row(0)[0]),
        ),
        compression="zstd",
        storage_options=output_dir["storage_options"],
        mkdir=True,
    )
    n_partitions = len(output_dir["fs"].glob(f"{partition_dir}/*/*.parquet"))
    logger.info(
        f"Staged the catalogue as {n_partitions} sampling region partitions in "
        f"{(datetime.datetime.now() - tstart).total_seconds():.0f} seconds"
    )

    return partition_dir


def iter_sampling_region_partitions(
    output_dir: FsspecOutputDir, partition_dir: str
) -> Iterator[tuple[str, pl.DataFrame]]:
    """Yield each sampling region's catalogue rows in turn.

    Only one region is held at a time, and the caller is expected to drop it before the next
    is read. Regions are yielded in a stable order so a run's logs line up between reruns; the
    allocation itself does not depend on the order, because each region draws off its own seed.

    Args:
        output_dir: Dictionary containing filesystem info from setup_fsspec_filesystem
        partition_dir: Partition directory from partition_catalogue_by_sampling_region

    Yields:
        Tuples of (sampling region id, that region's catalogue rows)
    """

    # One directory per region, holding one or more parquet files
    region_dirs = sorted({Path(p).parent.name for p in output_dir["fs"].glob(f"{partition_dir}/*/*.parquet")})
    if not region_dirs:
        raise FileNotFoundError(
            f"No catalogue partitions found in {partition_dir}, "
            f"call partition_catalogue_by_sampling_region() first."
        )

    for region_dir in region_dirs:
        region_id = region_dir.split("=", 1)[1]
        region_glob = f"{partition_dir}/{region_dir}/*.parquet"
        # hive_partitioning is off so the region only ever arrives as the column inside the
        # files, rather than also being parsed a second time out of the directory name
        geo_df = pl.read_parquet(
            region_glob, hive_partitioning=False, storage_options=output_dir["storage_options"]
        )
        yield region_id, geo_df


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
    geo_df: pl.DataFrame,
    bs_df: pl.DataFrame,
    seed: int | Sequence[int] | None = DEFAULT_ALLOCATION_SEED,
    log_stages: bool = True,
) -> tuple[pl.DataFrame, pl.DataFrame]:
    """Allocate buildings from sample to geographical units.

    Groups buildings by key characteristics, then draws one building uniformly at random for
    each row in the geographical catalogue. Every row carrying a heating fuel matches on all
    of ALLOCATION_KEYS, vacant and occupied alike: heating fuel is a property of the dwelling,
    so a vacant unit has one and the catalogue supplies it. Only a vacant row whose fuel is
    null matches on VACANT_ALLOCATION_KEYS instead, drawing across the fuels the sample's
    vacant buildings happen to carry. Rows that match no building on those keys walk the
    FALLBACK_LADDER, which releases vintage and then federal poverty level as well.

    The occupied subset is allocated first and off the same generator, so a catalogue whose
    vacant rows have changed reproduces its occupied allocation building for building.

    The frame passed in is held for the duration, and the join against the candidate pools
    needs several times its size again while it runs, so callers with a national catalogue
    should pass one sampling region at a time rather than the whole thing. See
    CATALOGUE_PARTITION_DIR.

    Args:
        geo_df: Geographical data with sampling regions assigned
        bs_df: Buildstock sample data with building characteristics
        seed: Seed for the random draws so identical inputs produce identical
            allocations. Pass None for unseeded (non-reproducible) allocation, or the
            output of region_seed() when allocating a single sampling region.
        log_stages: Log the fallback stage breakdown for this allocation. Callers running
            a region at a time set this False and report the totals across regions instead.

    Returns:
        Tuple of (allocated_df, fkt) where:
            - allocated_df: Full allocation with all columns, including fallback_stage
            - fkt: Foreign key table with bldg_id, tract_gisjoin, and puma_gisjoin
    """

    logger.info(f"Allocating simulated buildings to geographical units (seed={seed})")
    rng = np.random.default_rng(seed)
    is_vacant = pl.col("in.vacancy_status").eq_missing("Vacant")
    has_fuel = pl.col("in.heating_fuel").is_not_null()

    # A catalogue that supplies every vacant fuel leaves the third subset empty and never
    # exercises the released join. It is kept for one that does not, so a null reaching here
    # still places its row instead of dropping it — the same belt-and-braces
    # coerce_vacant_join_keys applies to tenure and federal poverty level. Only vacant rows
    # are eligible for it: an occupied row is expected to carry a fuel, and one that does not
    # should surface as a miss rather than quietly draw from a wider pool.
    fuelless_rows = geo_df.filter(is_vacant & ~has_fuel).height
    if fuelless_rows:
        logger.info(
            f"Releasing in.heating_fuel from the join on {fuelless_rows} vacant catalogue "
            f"rows that carry none"
        )

    # Built one at a time, and the subset dropped as soon as it has been allocated, so that
    # only one subset of the catalogue is ever resident alongside geo_df itself
    allocated_frames = []
    subsets = [
        (ALLOCATION_KEYS, ~is_vacant),
        (ALLOCATION_KEYS, is_vacant & has_fuel),
        (VACANT_ALLOCATION_KEYS, is_vacant & ~has_fuel),
    ]
    for keys, row_filter in subsets:
        geo_subset = geo_df.filter(row_filter)
        allocated_frames.append(allocate_down_the_ladder(geo_subset, bs_df, keys, rng))
        del geo_subset

    allocated_df = pl.concat(allocated_frames, how="vertical")
    del allocated_frames
    if log_stages:
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


def report_allocation_misses(
    misses: pl.DataFrame,
    allocated_rows: int,
    by_stage: dict[str, int],
    output_dir: FsspecOutputDir | None = None,
    null_building_threshold: float = DEFAULT_NULL_BUILDING_THRESHOLD,
) -> pl.DataFrame:
    """Report the catalogue rows the fallback ladder left without a building.

    Takes the misses and the counts rather than the whole allocation, so that a run allocating
    one sampling region at a time can hand over the misses it accumulated without ever holding
    the full allocation. check_allocation_misses is the whole-frame form of this.

    The threshold is applied to the residue left after the ladder, not to the rows that missed
    on the full keys, so it measures the stock that genuinely has nothing to stand in for it.
    The miss report is written before the threshold is applied so the rows are on disk to
    inspect even when the run is rejected, each carrying the fallback_stage it reached.

    Args:
        misses: The unallocated rows, carrying a fallback_stage column
        allocated_rows: Total rows allocated, the denominator for the miss fraction
        by_stage: Row count per fallback stage across the whole allocation
        output_dir: Dictionary containing filesystem info from setup_fsspec_filesystem, or
            None to skip writing the miss report
        null_building_threshold: Fraction of unallocated rows tolerated before raising

    Returns:
        The unallocated rows

    Raises:
        ValueError: If the unallocated fraction exceeds null_building_threshold
    """

    miss_fraction = misses.height / allocated_rows if allocated_rows else 0.0
    by_status = dict(misses.group_by("in.vacancy_status").len().iter_rows())
    logger.info(
        f"{misses.height} of {allocated_rows} rows ({miss_fraction:.4%}) found no "
        f"matching building after the fallback ladder. By vacancy status: {by_status}. "
        f"Rows by stage: {by_stage}"
    )

    if output_dir is not None:
        write_parquet_file(output_dir, misses, "allocation_miss_report.parquet")

    if miss_fraction > null_building_threshold:
        missing_regions = misses.select("in.sampling_region_id").unique()
        raise ValueError(
            f"\n{misses.height} rows ({miss_fraction:.4%}) found no matching building even "
            f"after releasing vintage and federal poverty level, above the "
            f"{null_building_threshold:.4%} threshold.\n"
            f"By vacancy status: {by_status}.\n"
            f"Rows by stage: {by_stage}.\n"
            f"Affected sampling regions: {missing_regions.to_series().to_list()}"
        )

    return misses


def check_allocation_misses(
    allocated_df: pl.DataFrame,
    output_dir: FsspecOutputDir | None = None,
    null_building_threshold: float = DEFAULT_NULL_BUILDING_THRESHOLD,
) -> pl.DataFrame:
    """Report catalogue rows the fallback ladder still left without a building.

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

    return report_allocation_misses(
        allocated_df.filter(pl.col("bldg_id").is_null()),
        allocated_df.height,
        stage_counts(allocated_df),
        output_dir,
        null_building_threshold,
    )


def write_parquet_file(output_dir: FsspecOutputDir, df: pl.DataFrame, file_name: str) -> None:
    """Write a DataFrame to parquet under the output directory, local or S3.

    Args:
        output_dir: Dictionary containing filesystem info from setup_fsspec_filesystem
        df: DataFrame to write
        file_name: Name of the parquet file within the output directory
    """

    logger.info(f"Writing {file_name} to {output_dir['fs_path']}")
    file_path = Path(output_dir["fs_path"]) / file_name
    if isinstance(output_dir["fs"], s3fs.S3FileSystem):
        file_path = f"s3://{file_path.as_posix()}"

    with output_dir["fs"].open(str(file_path), "wb") as f:
        df.lazy().sink_parquet(f)


def write_allocated_weights_partition(
    output_dir: FsspecOutputDir, allocated_df: pl.DataFrame, region_id: str
) -> None:
    """Write one sampling region's allocation to the allocated weights cache.

    Args:
        output_dir: Dictionary containing filesystem info from setup_fsspec_filesystem
        allocated_df: That region's allocation, including its fallback_stage and weight columns
        region_id: The sampling region the rows belong to
    """

    file_path = _polars_path(output_dir, ALLOCATED_WEIGHTS_DIR, _region_partition_path(region_id))
    if not isinstance(output_dir["fs"], s3fs.S3FileSystem):
        output_dir["fs"].mkdirs(str(Path(file_path).parent), exist_ok=True)

    with output_dir["fs"].open(file_path, "wb") as f:
        allocated_df.write_parquet(f, compression="zstd")


def write_allocated_weights(output_dir: FsspecOutputDir, allocated_df: pl.DataFrame) -> None:
    """Write a whole allocation to the allocated weights cache, split by sampling region.

    For allocations small enough to hold, such as the quota sampler's one row per simulated
    building. create_allocated_weights writes each region as it finishes it instead.

    Args:
        output_dir: Dictionary containing filesystem info from setup_fsspec_filesystem
        allocated_df: Full allocation DataFrame
    """

    partitions = allocated_df.partition_by("in.sampling_region_id", as_dict=True)
    for (region_id,), region_df in partitions.items():
        write_allocated_weights_partition(output_dir, region_df, region_id)
    logger.info(f"Wrote allocated weights for {len(partitions)} sampling regions")


def write_foreign_key_table(output_dir: FsspecOutputDir) -> None:
    """Write the building-to-geography foreign key table from the cached allocated weights.

    Streamed straight from the partitioned cache rather than assembled in memory: at one row
    per US housing unit the table is far too long to hold, and nothing needs it in memory.

    Args:
        output_dir: Dictionary containing filesystem info from setup_fsspec_filesystem
    """

    logger.info(f"Writing fkt.parquet to {output_dir['fs_path']}")
    fkt = get_cached_allocated_weights(output_dir).select(
        [pl.col("bldg_id"), pl.col("in.nhgis_tract_gisjoin"), pl.col("in.nhgis_puma_gisjoin")]
    )
    fkt.sink_parquet(
        _polars_path(output_dir, "fkt.parquet"),
        compression="zstd",
        storage_options=output_dir["storage_options"],
        mkdir=True,
    )


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

    # Write output parquet files. The quota sampler's simulation outputs carry no tract or
    # puma gisjoin, so there is no building-to-geography mapping to write a real fkt from.
    write_allocated_weights(output_dir, alloc_wts)
    write_parquet_file(output_dir, alloc_wts, "fkt.parquet")
    logger.info("Completed creating allocated weights artifacts")


def create_allocated_weights(
    simulation_outputs_file: str,
    output_dir: str,
    aws_profile_name=None,
    catalogue_file_version="v2",
    sampling_region_version="v1",
    seed: int | None = DEFAULT_ALLOCATION_SEED,
    null_building_threshold: float = DEFAULT_NULL_BUILDING_THRESHOLD,
) -> None:
    """Create allocated weights table from raw sample file and write to output parquet.

    This is the top-level orchestration function that:
    1. Sets up the filesystem
    2. Stages the catalogue as one parquet partition per sampling region
    3. Loads the allocation keys of the buildstock sample
    4. For each sampling region, allocates its buildings to its geographical units, walking
       the fallback ladder for empty shelves, and writes that region's weights
    5. Writes the miss report and checks the fraction the ladder still left unallocated
    6. Writes the foreign key table

    The catalogue is never held whole. Peak memory is set by the largest single sampling
    region, so it does not grow with the size of the country covered; see
    CATALOGUE_PARTITION_DIR for why splitting the work this way is exact.

    Because each region's weights are written as that region finishes, a run rejected by
    null_building_threshold leaves a complete allocation on disk alongside the miss report
    that explains why it was rejected. The rejection is still raised, so nothing downstream
    consumes it by accident.

    Args:
        simulation_outputs_file: Path to the simulation outputs Parquet file
        output_dir: Path to write output parquet files (local or S3)
        aws_profile_name: Optional AWS profile name for S3 access
        catalogue_file_version: Version of catalogue file to use (default 'v2')
        sampling_region_version: Version of sampling regions file to use (default 'v1')
        seed: Seed for the random building-to-geography allocation so identical
            inputs produce identical publications. Each region draws off a seed derived
            from this one, see region_seed(). Pass None for unseeded allocation.
        null_building_threshold: Fraction of unallocated rows tolerated before raising
    """

    # Set up filesystem for local or S3 for output file
    logger.debug(f"Setting up filesystem for output directory: {output_dir}")
    output_dir = setup_fsspec_filesystem(output_dir, aws_profile_name)

    # Stage the catalogue as one partition per sampling region, so the allocation can run a
    # region at a time. Reused if a previous run already staged it.
    partition_dir = partition_catalogue_by_sampling_region(
        output_dir, catalogue_file_version, sampling_region_version
    )

    # Load the simulation outputs' allocation keys. Only these columns take part in the
    # allocation, and the full table runs to well over a thousand columns of results.
    logger.info(f"Reading allocation keys from {simulation_outputs_file}")
    bs_df = pl.read_parquet(
        simulation_outputs_file,
        columns=ALLOCATION_KEYS + ["bldg_id"],
        storage_options=output_dir["storage_options"],
    )

    # Allocate one sampling region at a time, keeping only the misses and the counts
    logger.info(f"Allocating buildings to geographical units by sampling region (seed={seed})")
    tstart = datetime.datetime.now()
    miss_frames = []
    allocated_rows = 0
    by_stage = dict.fromkeys(FALLBACK_STAGES, 0)
    for region_id, region_partition in iter_sampling_region_partitions(output_dir, partition_dir):
        # Align vacant row join keys with how the buildstock sample labels vacant buildings
        geo_df = coerce_vacant_join_keys(region_partition)
        del region_partition

        # Only this region's buildings can be drawn, so the pools are built from them alone
        bs_region_df = bs_df.filter(pl.col("in.sampling_region_id") == region_id)
        allocated_df, _ = allocate_buildings_to_geography(
            geo_df, bs_region_df, seed=region_seed(seed, region_id), log_stages=False
        )
        del geo_df, bs_region_df

        # Accumulate what the miss report needs, which is far smaller than the allocation
        allocated_rows += allocated_df.height
        for stage, count in stage_counts(allocated_df).items():
            by_stage[stage] += count
        miss_frames.append(allocated_df.filter(pl.col("bldg_id").is_null()))

        # Add weight column (each row represents one housing unit) and write this region out
        allocated_df = allocated_df.with_columns(pl.lit(1).alias("weight"))
        write_allocated_weights_partition(output_dir, allocated_df, region_id)
        logger.info(f"Allocated sampling region {region_id}: {allocated_df.height:,} rows")
        del allocated_df

    logger.info(
        f"Allocated {allocated_rows:,} rows in "
        f"{(datetime.datetime.now() - tstart).total_seconds():.0f} seconds"
    )

    # Report the ladder rungs across all regions, the same breakdown log_fallback_stages
    # gives for an allocation done in one piece. Stages no row reached are omitted.
    reached = {stage: count for stage, count in by_stage.items() if count}
    for stage, count in reached.items():
        share = count / allocated_rows if allocated_rows else 0.0
        logger.info(f"Fallback stage {stage}: {count} rows ({share:.4%})")

    # Surface catalogue rows that matched no building. Raises if too many did.
    report_allocation_misses(
        pl.concat(miss_frames, how="vertical"),
        allocated_rows,
        reached,
        output_dir,
        null_building_threshold,
    )

    # Write the building-to-geography foreign key table
    write_foreign_key_table(output_dir)
    logger.info("Completed creating allocated weights artifacts")


def get_cached_allocated_weights(output_dir) -> pl.LazyFrame:
    """Scan the allocated weights cache, which holds one parquet partition per sampling region.

    Args:
        output_dir: Dictionary containing filesystem info from setup_fsspec_filesystem

    Returns:
        LazyFrame over the whole allocation, one row per housing unit in the catalogue
    """

    # Read the cached allocated weights
    cached_wts_dir = _polars_path(output_dir, ALLOCATED_WEIGHTS_DIR)
    if not output_dir["fs"].glob(f"{cached_wts_dir}/*/*.parquet"):
        raise FileNotFoundError(
            f"Cannot load allocated weights from {cached_wts_dir}, call create_allocated_weights() first."
        )
    # hive_partitioning is off so the region only ever arrives as the column inside the files,
    # rather than also being parsed a second time out of the directory name
    alloc_weights = pl.scan_parquet(
        f"{cached_wts_dir}/*/*.parquet",
        hive_partitioning=False,
        storage_options=output_dir["storage_options"],
    )

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

    # Read the cached allocated weights. Kept lazy: at one row per housing unit this is
    # around 18 GB in memory, and the only thing done to it here is a repartition by state.
    # The upgrade id is not added as a column, it is read back off the upgrade= directory.
    alloc_wts = get_cached_allocated_weights(output_dir)

    # Where the results will be cached
    alloc_wts_bills_dir = _polars_path(
        output_dir, f"cached_allocated_weights_plus_bills/upgrade={upgrade_id}"
    )
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

    # Write to parquet, hive partitioned on upgrade and state to make later processing faster.
    # Streamed rather than collected and grouped: collecting would hold the whole allocation
    # and grouping it would hold a second copy of it alongside, for what is a repartition.
    # The upgrade and state columns are recovered from the directory names on read.
    logger.info(f"Caching allocated weights plus bills for upgrade {upgrade_id} to: {alloc_wts_bills_dir}")
    tstart = datetime.datetime.now()

    def state_file_path(args) -> str:
        state_abbv = args.partition_keys.row(0)[0]
        return (
            f"state={state_abbv}/"
            f"cached_allocated_weights_plus_bills_upgrade{upgrade_id}_{state_abbv}.parquet"
        )

    alloc_wts.sink_parquet(
        pl.PartitionBy(
            f"{alloc_wts_bills_dir}/",
            key="in.state",
            include_key=True,
            file_path_provider=state_file_path,
        ),
        compression="zstd",
        storage_options=output_dir["storage_options"],
        mkdir=True,
    )
    logger.info(
        f"Cached allocated weights plus bills for upgrade {upgrade_id} in "
        f"{(datetime.datetime.now() - tstart).total_seconds():.0f} seconds"
    )


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
