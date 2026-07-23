from functools import lru_cache

import boto3
import gzip
from io import BytesIO
import logging
import pathlib
import re
from collections import defaultdict
from fsspec import AbstractFileSystem, register_implementation, url_to_fs
import polars as pl
import polars.selectors as cs
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
    cols_to_keep = {"upgrade", "applicability", "metadata_index"}  # To keep even if 0 or empty
    all_empty_str_cols = [
        col.name for col in df.select(pl.col(pl.Utf8).is_in(["", ",,,"])) if col.all() and col.name not in cols_to_keep
    ]
    all_zero_numeric_cols = [
        col.name for col in df.select(cs.numeric() == 0) if col.all() and col.name not in cols_to_keep
    ]
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
        if match := re.search(emissions_re, col):
            scenario2cols[match[2]].append(col)

    for scenario, cols in scenario2cols.items():
        new_col = f'out.emissions.total.{scenario}..co2e_kg'
        all_fuel_cols.append(pl.sum_horizontal(cols).alias(new_col))

    return df.with_columns(all_fuel_cols)

@lru_cache(maxsize=1)
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


def conversion_factor(from_unit, to_unit):
    # Constants for unit conversion
    # Created using OpenStudio unit conversion library
    unit_conversions = {
        "kwh_to_kwh" : 1,
        "kwh_to_mwh" : 1e-3,
        "mwh_to_kwh" : 1e3,
        "twh_to_kwh" : 1e9,
        "mbtu_to_kbtu" : 1000,
        "kwh_to_kbtu" : 3.412141633127942,
        "kwh_to_tbtu" : ((1.0 / 1e9) * 3.412141633127942),
        "kbtu_to_kwh": (1.0 / 3.412141633127942),
        "therm_to_kbtu" : 100,
        "therm_to_kwh" : (100 / 3.412141633127942),
        "kbtu_to_tbtu" : (1.0 / 1e9),
        "tbtu_to_kbtu" : 1e9,
        "btu_to_kbtu" : (1.0 / 1e3),
        "million_btu_to_kbtu": (1e9 / 1e6),
        "million_btu_to_kwh": (1000 / 3.412141633127942),
        "gj_to_kbtu" : 947.8171203133173,
        "gj_to_kwh" : 277.77777777777777,
        "w_per_m2_k_to_btu_per_ft2_f_hr": 0.17611,
        "pa_to_inwc": 0.004015,
        "w_per_m2_to_w_per_ft2": (1.0/10.763910416709722),
        "co2e_kg_to_co2e_mmt": (0.000000001),
        "co2e_kg_to_co2e_metric_ton": 0.001,
        "usd_to_billion_usd": 0.000000001,
        "kw_to_gw": 0.000001,
        "percent_to_percent": 1,
    }
    conv_string = f"{from_unit}_to_{to_unit}"

    if conv_string in unit_conversions:
        return unit_conversions[conv_string]
    else:
        raise KeyError(
            f"Conversion from {from_unit} to {to_unit} not defined in unit_conversions, add it there."
        )
    

def col_name_to_percent_savings(col_name, new_units=None):
    col_name = col_name.replace("out.", "calc.")
    col_name = col_name.replace("calc.", "calc.percent_savings.")
    if new_units is not None:
        old_units = units_from_col_name(col_name)
        col_name = col_name.replace(f"..{old_units}", f"..{new_units}")

    return col_name    


def units_from_col_name(col_name: str) -> str:
    # Extract the units from the column name
    match = re.search(r"\.\.(.*)", col_name)
    units = match.group(1) if match else ""

    return units


def col_name_to_weighted(col_name: str, new_units=None) -> str:
    col_name = col_name.replace("out.", "calc.")
    col_name = col_name.replace("calc.", "calc.weighted.")
    if new_units is not None:
        old_units = units_from_col_name(col_name)
        col_name = col_name.replace(f"..{old_units}", f"..{new_units}")

    return col_name


def col_name_to_intensity(col_name: str, new_units=None) -> str:
    col_name = col_name.replace("energy_consumption", "energy_consumption_intensity")
    col_name = col_name.replace("energy_savings", "energy_savings_intensity")
    if new_units is not None:
        old_units = units_from_col_name(col_name)
        col_name = col_name.replace(f"..{old_units}", f"..{new_units}")

    return col_name


def col_name_to_savings(col_name: str) -> str:
    converted_col_name = str(col_name)
    svg_renames = {
        ".energy_consumption": ".energy_savings",
        "_bill..": "_bill_savings..",
        "_daily_peak_": "_daily_peak_savings_",
        ".peak_": ".peak_savings_",
        ".energy_burden": ".energy_burden_savings",
        ".unmet_hours": ".unmet_hours_reduction",
        "out.hot_water": "out.hot_water_savings",
        ".load.cooling.peak": ".load.cooling.peak_savings",
        ".load.heating.peak": ".load.heating.peak_savings",
        ".energy_delivered": ".energy_delivered_savings",
        ".energy_solar_thermal": ".energy_solar_thermal_savings",
        ".energy_tank_losses": ".energy_tank_losses_savings",
        ".emissions.": ".emissions_reduction.",
        "panel_load_total_load": "panel_load_total_load_savings",
        "panel_load_occupied_capacity": "panel_load_occupied_capacity_savings",
        "panel_breaker_space_occupied": "panel_breaker_space_occupied_savings",
        "component_load": "component_load_savings"
    }
    for bef, aft in svg_renames.items():
        converted_col_name = converted_col_name.replace(bef, aft)

    if converted_col_name == col_name:
        raise ValueError(f"Cannot convert column name {col_name} to savings column")

    return converted_col_name

