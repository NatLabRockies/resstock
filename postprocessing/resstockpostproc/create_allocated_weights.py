import argparse
import boto3
import json
import logging
import os
import polars as pl
import random
import s3fs
from utils import setup_fsspec_filesystem

logger = logging.getLogger(__name__)

def create_allocated_weights(
        bs_file: str, output_dir: str, aws_profile_name = None, catalogue_file_version='v0',
        sampling_region_version='v1'
    ) -> None:
    """
    Create allocated weights table from raw sample file and write to output parquet.
    """

    # Set up filesystem for local or S3 for output file
    logger.debug(f"Setting up filesystem for output directory: {output_dir}")
    output_dir = setup_fsspec_filesystem(output_dir, aws_profile_name)

    # Read catalogue file from local path or download from S3 if not found
    catalogue_file = f"pums_2019_5yrs_acs_catalogue_{catalogue_file_version}.parquet"
    catalogue_local_path = f"{output_dir['fs_path']}/{catalogue_file}"
    if not os.path.isfile(catalogue_local_path):
        logger.info(f"Catalogue file not found locally, downloading from S3")
        s3_client = boto3.client('s3')
        s3_client.download_file('resstock-core', f'truth_data/v01/StockE/{catalogue_file}', str(catalogue_local_path))
        logger.info(f"Downloaded catalogue file to {catalogue_local_path}")
    logger.info(f"Reading catalogue file from {catalogue_local_path}")
    catalogue_df = pl.read_parquet(catalogue_local_path)
    catalogue_df = catalogue_df.with_columns(pl.col("tract_gisjoin").str.slice(0, 8).alias("county_gisjoin"))

    # Read sampling_regions_vN.json from local path or download from S3 if not found
    sampling_regions_file = f"sampling_regions_{sampling_region_version}.json"
    sample_regions_local_path = f"{output_dir['fs_path']}/{sampling_regions_file}"
    if not os.path.isfile(sample_regions_local_path):
        logger.info(f"Sampling regions file not found locally, downloading from S3")
        s3_client = boto3.client('s3')
        s3_client.download_file(
            'resstock-core', f'truth_data/v01/StockE/{sampling_regions_file}', str(sample_regions_local_path)
        )
        logger.info(f"Downloaded sampling regions file to {sample_regions_local_path}")
    logger.info(f"Reading sample file from {sample_regions_local_path}")
    with open(sample_regions_local_path, 'r') as f:
        sampling_regions_dict = json.load(f)
    # Manually add in Oglala Lakota County, SD which used to be Shannon county (G4601130)
    sampling_regions_dict['G4601020'] = 34
    sampling_regions_df = pl.DataFrame({
        "county_gisjoin": list(sampling_regions_dict.keys()),
        "sampling_region": list(sampling_regions_dict.values())
    })
    
    # Define which CEC climate zones map to which sampling regions
    ca_regions_lkup = {
        'CEC1': 100, 'CEC2': 100, 'CEC3': 101, 'CEC4': 102, 'CEC5': 102, 'CEC6': 103, 'CEC7': 103, 'CEC8': 104,
        'CEC9': 105, 'CEC10': 106, 'CEC11': 107, 'CEC12': 107, 'CEC13': 108, 'CEC14': 109, 'CEC15': 109, 'CEC16': 110
    }

    # Read cec_cz_by_tract_2010_lkup.json from local path or download from S3 if not found
    cec_2010_cz_lkup_file = "cec_cz_by_tract_2010_lkup.json"
    cec_2010_cz_lkup_local_path = f"{output_dir['fs_path']}/{cec_2010_cz_lkup_file}"
    if not os.path.isfile(cec_2010_cz_lkup_local_path):
        logger.info(f"CEC 2010 CZ lookup file not found locally, downloading from S3")
        s3_client = boto3.client('s3')
        s3_client.download_file(
            'resstock-core', f'truth_data/v01/StockE/{cec_2010_cz_lkup_file}', str(cec_2010_cz_lkup_local_path)
        )
        logger.info(f"Downloaded CEC 2010 CZ lookup file to {cec_2010_cz_lkup_local_path}")
    logger.info(f"Reading CEC 2010 CZ lookup file from {cec_2010_cz_lkup_local_path}")
    with open(cec_2010_cz_lkup_local_path, 'r') as f:
        cec_2010_cz_lkup_dict = json.load(f)
    cec_2010_cz_lkup_df = pl.DataFrame({
        "tract_gisjoin": list(cec_2010_cz_lkup_dict.keys()),
        "sampling_region": list(cec_2010_cz_lkup_dict.values())
    })
    cec_2010_cz_lkup_df = cec_2010_cz_lkup_df.with_columns(pl.col('sampling_region').replace(ca_regions_lkup)) 

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

    # Merge catalogue and sampling regions data using county assignmnents outside of CA and CEC climate zones in CA
    logger.info("Merging catalogue and sample regions data")
    df = catalogue_df.join(sampling_regions_df, on="county_gisjoin", how="left")
    df = df.join(cec_2010_cz_lkup_df, on="tract_gisjoin", how="left", suffix="_cec2010")
    # df = df.join(cec_2020_cz_lkup_df, on="tract_gisjoin", how="left", suffix="_cec2020")
    df = df.with_columns(pl.coalesce([
            pl.col("sampling_region"), pl.col("sampling_region_cec2010")# , pl.col("sampling_region_cec2020")
        ]).cast(pl.Int64).alias("sampling_region"))
    df = df.drop(["sampling_region_cec2010"])# , "sampling_region_cec2020"])
    df = df.rename({"sampling_region": "Sampling Region"})

    # Check for any missing sampling regions:
    if df.filter(pl.any_horizontal(pl.all().is_null())).shape[0] > 0:
        missing_counties = df.filter(pl.col("Sampling Region").is_null()).select("county_gisjoin").unique()
        missing_tracts = df.filter(pl.col("Sampling Region").is_null()).select("tract_gisjoin").unique()
        raise ValueError(
            f"{df.filter(pl.any_horizontal(pl.all().is_null())).shape[0]} rows are missing sampling regions.\n"
            f"Missing counties: {missing_counties.to_series().to_list()}.\n"
            f"Missing tracts: {missing_tracts.to_series().to_list()}"
        )
    logger.info("Successfully assigned sampling regions")

    # Loading the sample data to allocation weights with
    logger.info(f"Reading buildstock file from {bs_file}")
    bs_df = pl.read_csv(bs_file, infer_schema_length=10000)

    # Create allocated weights by sampling one building per row in the catalogue df
    logger.info("Processing allocated weights")
    grouped_df = bs_df.group_by([
        'Sampling Region', 'Tenure', 'Vacancy Status', 'Geometry Building Type RECS', 'Vintage', 'Heating Fuel',
        'Federal Poverty Level'
    ]).agg(pl.col('Building').unique())
    allocated_df = df.lazy().join(grouped_df.lazy(), on=[
        'Sampling Region', 'Tenure', 'Vacancy Status', 'Geometry Building Type RECS', 'Vintage', 'Heating Fuel',
        'Federal Poverty Level'
    ], how='left').with_columns(pl.col('Building').list.sample(n=1).list.first()).collect()
    fkt = allocated_df.select([pl.col('Building'), pl.col('tract_gisjoin'), pl.col('puma_gisjoin')])

    logger.info(f"Writing fkt to {output_dir}")
    file_path = output_dir['fs_path'] + '/fkt.parquet'
    if isinstance(output_dir['fs'], s3fs.S3FileSystem):
        file_path = f"s3://{output_dir['fs_path'].as_posix()}"
    with output_dir['fs'].open(str(file_path), "wb") as f:
        fkt.write_parquet(f)
    logger.info("Finished writing fkt")

    logger.info(f"Writing allocated weights to {output_dir}")
    file_path = output_dir['fs_path'] + '/allocated_weights.parquet'
    if isinstance(output_dir['fs'], s3fs.S3FileSystem):
        file_path = f"s3://{output_dir['fs_path'].as_posix()}"
    with output_dir['fs'].open(str(file_path), "wb") as f:
        allocated_df.write_parquet(f)
    logger.info("Finished writing allocated weights")
    logger.info("Completed creating allocated weights artifacts")

if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    logger.info('hi')
    logger.debug('hejhej')

    parser = argparse.ArgumentParser(
        description="Process raw sample file and write allocation weights table"
    )
    parser.add_argument(
        "sample_file",
        default="./geo_samples.csv",
        help="Path to the raw sample csv file",
    )
    parser.add_argument(
        "output_dir",
        default="./../output/",
        help="Path to write the allocated weights output parquet to",
    )
    args = parser.parse_args()
    create_allocated_weights(args.sample_file, args.output_dir)
