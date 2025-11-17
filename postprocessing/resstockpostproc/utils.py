import boto3
from collections import defaultdict
from fsspec import register_implementation
from fsspec.core import url_to_fs
from fsspec.spec import AbstractFileSystem
import gzip
from io import BytesIO
import logging
import pathlib
import polars as pl
import polars.selectors as cs
import re
import s3fs
import tarfile
from typing import Optional, TypedDict

logger = logging.getLogger(__name__)


class FsspecOutputDir(TypedDict):
    """Type definition for output directory dict returned by setup_fsspec_filesystem."""

    fs: AbstractFileSystem
    fs_path: pathlib.Path | str
    storage_options: Optional[dict[str, str]]

def remove_all_empty_cols(df: pl.DataFrame):
    """
    Can't use LazyFrame here because the operation depends on the data.
    ',,,' catches emissions_fuel_oil_values, emissions_natural_gas_values, and emissions_propane_values.
    """
    cols_to_keep = {'upgrade', 'applicability', 'metadata_index'}  # To keep even if 0 or empty
    all_empty_str_cols = [col.name for col in df.select(pl.col(pl.Utf8).is_in(['', ',,,'])) if col.all() and col.name not in cols_to_keep]
    all_zero_numeric_cols = [col.name for col in df.select(cs.numeric() == 0) if col.all() and col.name not in cols_to_keep]
    all_empty_cols = all_empty_str_cols + all_zero_numeric_cols
    # drop the empty columns
    print(f"Dropping {len(all_empty_cols)} columns: {all_empty_cols}")
    cleaned_base = df.drop(all_empty_cols)
    return cleaned_base

def fix_site_energy_total(df: pl.LazyFrame):
    """
    We need to do this because normally site energy total includes coal and wood but we don't want to include those.
    """
    print("Removing coal and wood from energy totals")
    all_cols = df.collect_schema().names()
    updated_cols = []
    for suffix in ['', '_intensity', 'energy_consumption..kwh', 'energy_savings..kwh']:
        if f'out.electricity.total.{suffix}' not in df:
            continue
        total_energy_col = pl.lit(0)
        for fuel in ['electricity','natural_gas', 'fuel_oil', 'propane']:  # exclude other fuel types
            if (col := f'out.{fuel}.total.{suffix}') in all_cols:
                total_energy_col += pl.col(col)
        updated_cols.append(total_energy_col.alias(f'out.site_energy.total.{suffix}'))
        if (pvcol := f'out.electricity.pv.{suffix}'):
            net_energy_col = total_energy_col + pl.col(pvcol)
            net_electricity_col = pl.col(f'out.electricity.total.{suffix}') + pl.col(pvcol)
            updated_cols.append(net_energy_col.alias(f'out.site_energy.net.{suffix}'))
            updated_cols.append(net_electricity_col.alias(f'out.electricity.net.{suffix}'))
    return df.with_columns(updated_cols)

def fix_all_fuels_emissions(df: pl.LazyFrame):
    """
    Recalculate out.all_fuels.total.<scenario_name>.co2e_kg columns using
    only the subset of fuel total columns. Basically, exclude wood from the all_fuel emissions.
    """
    print("Removing coal and wood from emissions totals")
    all_cols = df.collect_schema().names()
    all_fuel_cols = []
    emissions_re = re.compile(r"^out\.emissions\.(electricity|natural_gas|fuel_oil|propane).(\w+)..co2e_kg")

    scenario2cols = defaultdict(list)
    for col in all_cols:
        if (match := re.search(emissions_re, col)):
            scenario2cols[match[2]].append(col)

    for scenario, cols in scenario2cols.items():
        new_col = f'out.emissions.total.{scenario}..co2e_kg'
        all_fuel_cols.append(pl.sum_horizontal(cols).alias(new_col))

    return df.with_columns(all_fuel_cols)


def get_col_maps():
    """
    Get the column maps from the publication list.
    """
    resources_path = pathlib.Path(__file__).parent / "resources"
    col_def_df = pl.read_csv(resources_path / "publication" / "sdr_column_definitions.csv", infer_schema_length=0)
    col_map_df = col_def_df.filter(
                    pl.col("Published Annual Name").is_not_null()
                ).select(
                    pl.col('Column Type').alias('column_type'),
                    pl.col('Import From Raw').alias('import_from_raw'),
                    pl.col('Publish In Full').alias('publish_in_full'),
                    pl.col("Annual Name").alias('column_name'),
                    pl.col("Published Annual Name").alias('published_name'),
                    pl.col("ResStock To Published Annual Unit Conversion Factor").alias("conversion_factor")
                )
    col_maps = col_map_df.to_dicts()
    return col_maps


def setup_fsspec_filesystem(output_dir: str, aws_profile_name=None) -> FsspecOutputDir:
    """
    Creates fsspec filesystem to handle local or S3 output locations
    """
    # Use fsspec to enable local or S3 directories
    # if output_dir is None:
    #     current_dir = pathlib.Path(__file__).resolve().parent
    #     output_dir = current_dir.parent / "output" / self.dataset_name

    # PyAthena >2.18.0 implements an s3 filesystem that replaces s3fs but does not implement file.open()
    # Make fsspec use the s3fs s3 filesystem implementation for writing files to S3
    # This is necessary for import into SightGlassDataProcessing
    register_implementation("s3", s3fs.S3FileSystem, clobber=True)
    out_fs, out_fs_path = url_to_fs(output_dir, profile=aws_profile_name)
    output_dir = {
        'fs': out_fs,
        'fs_path': out_fs_path
    }
    if isinstance(output_dir['fs'], s3fs.S3FileSystem):
        if aws_profile_name is None:
            logger.info(f'Accessing AWS using profile: None, which uses the [default] profile in .aws/config file')
        else:
            logger.info(f'Accessing AWS using profile: {aws_profile_name}')
        session = boto3.Session(aws_profile_name)
        credentials = session.get_credentials().get_frozen_credentials()
        output_dir['storage_options'] = {
            "aws_access_key_id": credentials.access_key,
            "aws_secret_access_key": credentials.secret_key,
            "aws_region": "us-west-2",
        }
        if credentials.token:
            output_dir['storage_options']['aws_session_token'] = credentials.token
    else:
        output_dir['storage_options'] = None

    return output_dir


def write_geo_data(combo):
    """
    Writes the data to the desired location and file format.
    This function must be a global static function in order to work with parallel processing.
    """
    geo_data, out_location, file_type, file_path = combo
    if isinstance(geo_data, pl.LazyFrame):
        geo_data = geo_data.collect()
    if file_type == 'csv':
        write_polars_csv_to_s3_or_local(geo_data, out_location['fs'], file_path)
    elif file_type == 'parquet':
        with out_location['fs'].open(file_path, "wb") as f:
            geo_data.write_parquet(f, use_pyarrow=True)
    else:
        raise RuntimeError(f'Unknown file type {file_type} requested in export_metadata_and_annual_results()')


def write_polars_csv_to_s3_or_local(data: pl.DataFrame, out_fs, out_path):
    """
    Writes the data to the desired location and file format.
    This function must be a global static function in order to work with parallel processing
    """
    # If local, write uncompressed CSV
    if not isinstance(out_fs, s3fs.S3FileSystem):
        data.write_csv(out_path)
        return True

    # Get filename from full path
    file_name = out_path.split('/')[-1]

    # Create a tar archive in memory that contains the CSV
    tar_buffer = BytesIO()
    with tarfile.open(mode='w', fileobj=tar_buffer) as tar:
        # Get CSV data
        csv_buffer = BytesIO()
        data.write_csv(csv_buffer)
        csv_buffer.seek(0)

        # Create a TarInfo object with file metadata
        tarinfo = tarfile.TarInfo(name=file_name)
        tarinfo.size = len(csv_buffer.getvalue())

        # Add the CSV data to the tar archive
        tar.addfile(tarinfo, csv_buffer)

    # Compress the in memory tar archive with gzip
    tar_buffer.seek(0)
    gzip_buffer = BytesIO()
    with gzip.GzipFile(filename=f'{file_name}', mode='wb', fileobj=gzip_buffer, compresslevel=9) as gz:
        gz.write(tar_buffer.getvalue())

    # Upload directly to S3
    bucket_name = out_path.split('/')[0]
    s3_key = '/'.join(out_path.split('/')[1:]) + '.gz'
    s3_client = boto3.client('s3')
    try:
        gzip_buffer.seek(0)
        s3_client.upload_fileobj(
            gzip_buffer,      # File-like object
            bucket_name,     # Bucket name
            s3_key          # S3 object key
        )
    except Exception as e:
        logger.error(f"S3 upload failed: {str(e)}")
    finally:
        # Clean up
        csv_buffer.close()
        tar_buffer.close()
        gzip_buffer.close()

    # Clean up
    csv_buffer.close()
    tar_buffer.close()
    gzip_buffer.close()


def conversion_factor(from_unit, to_unit):
    # Constants for unit conversion
    # Created using OpenStudio unit conversion library
    unit_conversions = {
        'kwh_to_kwh' : 1,
        'kwh_to_mwh' : 1e-3,
        'mwh_to_kwh' : 1e3,
        'twh_to_kwh' : 1e9,
        'mbtu_to_kbtu' : 1000,
        'kwh_to_kbtu' : 3.412141633127942,
        'kwh_to_tbtu' : ((1.0 / 1e9) * 3.412141633127942),
        'kbtu_to_kwh': (1.0 / 3.412141633127942),
        'therm_to_kbtu' : 100,
        'therm_to_kwh' : (100 / 3.412141633127942),
        'kbtu_to_tbtu' : (1.0 / 1e9),
        'tbtu_to_kbtu' : 1e9,
        'btu_to_kbtu' : (1.0 / 1e3),
        'million_btu_to_kbtu': (1e9 / 1e6),
        'million_btu_to_kwh': (1000 / 3.412141633127942),
        'gj_to_kbtu' : 947.8171203133173,
        'gj_to_kwh' : 277.77777777777777,
        'w_per_m2_k_to_btu_per_ft2_f_hr': 0.17611,
        'pa_to_inwc': 0.004015,
        'w_per_m2_to_w_per_ft2': (1.0/10.763910416709722),
        'co2e_kg_to_co2e_mmt': (0.000000001),
        'co2e_kg_to_co2e_metric_ton': 0.001,
        'usd_to_billion_usd': 0.000000001,
        'kw_to_gw': 0.000001,
        'percent_to_percent': 1,
    }
    conv_string = f'{from_unit}_to_{to_unit}'

    if conv_string in unit_conversions:
        return unit_conversions[conv_string]
    else:
        raise KeyError(
            f"Conversion from {from_unit} to {to_unit} not defined in unit_conversions, add it there."
        )
