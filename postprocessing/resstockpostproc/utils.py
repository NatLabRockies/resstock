import polars as pl
from typing import List
import polars.selectors as cs
from collections import defaultdict
import re
import pathlib

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

def fix_site_energy_total(df: pl.LazyFrame, all_cols: List[str]):
    """
    We need to do this because normally site energy total includes coal and wood but we don't want to include those.
    """
    updated_cols = []
    for suffix in ['', '_intensity', '.kwh', '.kwh.savings']:
        if f'out.electricity.total.energy_consumption{suffix}' not in df:
            continue
        total_energy_col = pl.lit(0)
        for fuel in ['electricity','natural_gas', 'fuel_oil', 'propane']:  # exclude other fuel types
            if (col := f'out.{fuel}.total.energy_consumption{suffix}') in all_cols:
                total_energy_col += pl.col(col)
        updated_cols.append(total_energy_col.alias(f'out.site_energy.total.energy_consumption{suffix}'))
        if (pvcol := f'out.electricity.pv.energy_consumption{suffix}'):
            net_energy_col = total_energy_col + pl.col(pvcol)
            net_electricity_col = pl.col(f'out.electricity.total.energy_consumption{suffix}') + pl.col(pvcol)
            updated_cols.append(net_energy_col.alias(f'out.site_energy.net.energy_consumption{suffix}'))
            updated_cols.append(net_electricity_col.alias(f'out.electricity.net.energy_consumption{suffix}'))
    return df.with_columns(updated_cols)

def fix_all_fuels_emissions(df: pl.LazyFrame, all_cols: List[str]):
    """
    Recalculate out.all_fuels.total.<scenario_name>.co2e_kg columns using
    only the subset of fuel total columns. Basically, exclude wood from the all_fuel emissions.
    """
    all_fuel_cols = []
    emissions_re = re.compile(r"^out\.(electricity|natural_gas|fuel_oil|propane).total.(\w+).co2e_kg$")

    scenario2cols = defaultdict(list)
    for col in all_cols:
        if (match := re.search(emissions_re, col)):
            scenario2cols[match[2]].append(col)

    for scenario, cols in scenario2cols.items():
        new_col = f'out.all_fuels.total.{scenario}.co2e_kg'
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
                pl.col("Annual Name").alias('column_name'),
                pl.col("Published Annual Name").alias('published_name'),
                pl.col("ResStock To Published Annual Unit Conversion Factor").alias("conversion_factor")
            )
    col_maps = col_map_df.to_dicts()
    return col_maps

def get_polars_schema_from_data_dictionary(all_cols: List[str]) -> dict[str, pl.DataType]:
    """
     Returns a dictionary of column name: dtype for all provided columns, making use of the data dictionary.
     Currently, only the columns defined in input dictionary is assigned dtypes based on the data dictionary.
     All other columns, including those defined in the output dictionary, are assigned float64 dtype.
    """
    resources_path = pathlib.Path(__file__).parent / "resources"
    polar_dtypes = {
        "bool": pl.Boolean,
        "int": pl.Int64,
        "float": pl.Float64,
        "string": pl.String,
        "datetime": pl.Datetime(time_unit="ms"),
    }
    input_dict_df = pl.read_csv(resources_path / "dictionary" / "inputs.csv")
    input_schema_dict = dict(zip(input_dict_df["Input Name"].to_list(), [polar_dtypes[x] for x in input_dict_df["Data Type"].to_list()]))
    # since there are multiple of upgrade_costs.option_ columns, this definition is currently not in the dictionary
    input_schema_dict |= {col: pl.String for col in all_cols if col.startswith("upgrade_costs.option_") and col.endswith("_name")}
    # This is also not in the dictionary
    input_schema_dict |= {"step_failures":pl.String}
    
    matching_schema = {k: v for k, v in input_schema_dict.items() if k in set(all_cols)}
    full_schema = {k: pl.Float64 for k in all_cols if k not in matching_schema} | matching_schema
    return full_schema
