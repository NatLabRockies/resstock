import argparse
import boto3
import json
import logging
import os
from pathlib import Path
import polars as pl
from polars.lazyframe.frame import LazyFrame
from resstockpostproc.utils import FsspecOutputDir, setup_fsspec_filesystem
import s3fs

logger = logging.getLogger(__name__)


def load_catalogue_file(output_dir: FsspecOutputDir, catalogue_file_version: str) -> pl.DataFrame:
    """Load and preprocess catalogue file, downloading from S3 if necessary.

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

    # Validate that all rows have been assigned a sampling region
    if df.filter(pl.any_horizontal(pl.all().is_null())).shape[0] > 0:
        missing_counties = (
            df.filter(pl.col("Sampling Region").is_null())
            .select("county_gisjoin")
            .unique()
        )
        missing_tracts = (
            df.filter(pl.col("Sampling Region").is_null())
            .select("tract_gisjoin")
            .unique()
        )
        raise ValueError(
            f"\n{df.filter(pl.any_horizontal(pl.all().is_null())).shape[0]} rows are missing sampling regions.\n"
            + f"Missing counties: {missing_counties.to_series().to_list()}.\n"
            + f"Missing tracts: {missing_tracts.to_series().to_list()}"
        )
    logger.info("Successfully assigned sampling regions")

    return df


def allocate_buildings_to_geography(geo_df: pl.DataFrame, bs_df: pl.DataFrame) -> tuple[pl.DataFrame, pl.DataFrame]:
    """Allocate buildings from sample to geographical units.

    Groups buildings by key characteristics, then randomly samples one building
    for each row in the geographical catalogue.

    Args:
        geo_df: Geographical data with sampling regions assigned
        bs_df: Buildstock sample data with building characteristics

    Returns:
        Tuple of (allocated_df, fkt) where:
            - allocated_df: Full allocation with all columns
            - fkt: Foreign key table with Building, tract_gisjoin, and puma_gisjoin
    """

    logger.info("Processing allocated weights")

    # Group buildstock buildings by their key characteristics to create pools of similar buildings
    grouped_df = bs_df.group_by(
        [
            "Sampling Region",
            "Tenure",
            "Vacancy Status",
            "Geometry Building Type RECS",
            "Vintage",
            "Heating Fuel",
            "Federal Poverty Level",
        ]
    ).agg(pl.col("Building").unique())

    # Join geography with building pools and randomly sample one building per geography row
    allocated_df = (
        geo_df.lazy()
        .join(
            grouped_df.lazy(),
            on=[
                "Sampling Region",
                "Tenure",
                "Vacancy Status",
                "Geometry Building Type RECS",
                "Vintage",
                "Heating Fuel",
                "Federal Poverty Level",
            ],
            how="left",
        )
        .with_columns(pl.col("Building").list.sample(n=1).list.first())
        .collect()
    )

    # Extract foreign key table with building-to-geography mappings
    fkt = allocated_df.select(
        [pl.col("Building"), pl.col("tract_gisjoin"), pl.col("puma_gisjoin")]
    )

    return allocated_df, fkt


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

    # Construct file path for fkt output and handle S3 vs local paths
    logger.info(f"Writing fkt to {output_dir}")
    file_path = Path(output_dir["fs_path"]) / "fkt.parquet"
    if isinstance(output_dir["fs"], s3fs.S3FileSystem):
        file_path = f"s3://{Path(output_dir['fs_path']).as_posix()}"

    # Write fkt DataFrame to parquet format
    with output_dir["fs"].open(str(file_path), "wb") as f:
        LazyFrame(fkt).sink_parquet(f)
    logger.info("Finished writing fkt")

    # Construct file path for allocated weights output and handle S3 vs local paths
    logger.info(f"Writing allocated weights to {output_dir}")
    file_path = Path(output_dir["fs_path"]) / "allocated_weights.parquet"
    if isinstance(output_dir["fs"], s3fs.S3FileSystem):
        file_path = f"s3://{Path(output_dir['fs_path']).as_posix()}"

    # Write allocated weights DataFrame to parquet format
    with output_dir["fs"].open(str(file_path), "wb") as f:
        LazyFrame(allocated_df).sink_parquet(f)
    logger.info("Finished writing allocated weights")
    logger.info("Completed creating allocated weights artifacts")

def create_allocated_weights(
    bs_file: str, output_dir: str, aws_profile_name=None, catalogue_file_version="v0", sampling_region_version="v1"
) -> None:
    """Create allocated weights table from raw sample file and write to output parquet.

    This is the top-level orchestration function that:
    1. Sets up the filesystem
    2. Loads reference data (catalogue, sampling regions, climate zones)
    3. Merges geographical data with sampling regions
    4. Loads buildstock sample data
    5. Allocates buildings to geographical units
    6. Writes output files

    Args:
        bs_file: Path to the buildstock sample CSV file
        output_dir: Path to write output parquet files (local or S3)
        aws_profile_name: Optional AWS profile name for S3 access
        catalogue_file_version: Version of catalogue file to use (default 'v0')
        sampling_region_version: Version of sampling regions file to use (default 'v1')
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
    allocated_df, fkt = allocate_buildings_to_geography(geo_df, bs_df)

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

    # Parse command-line arguments and call the create_allocated_weights function
    args = parser.parse_args()
    create_allocated_weights(args.sample_file, args.output_dir)
