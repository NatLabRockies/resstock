""" predict the panel size and breaker space for baseline results csv based on resstock resource files
updated: 01/13/2025

"""

from pathlib import Path
import pandas as pd
import numpy as np
import re
import matplotlib.pyplot as plt
import math
import argparse
from typing import Union
import random

import datetime


def apply_special_mapping(df):
    """Translate baseline results csv options to ResStock Argument options in resource files."""

    df["heating_fuel"] = df["build_existing_model.heating_fuel"].map(
        {
            "Electricity": "electricity",
            "Fuel Oil": "non-electricity",
            "Natural Gas": "non-electricity",
            "None": "non-electricity",
            "Other Fuel": "non-electricity",
            "Propane": "non-electricity",
            "Wood": "non-electricity", 
        }
    )
    df["clothes_dryer"] = df["build_existing_model.clothes_dryer"].map(
        {
            "Electric": "electricity",
            "Gas": "non-electricity",
            "None": "none",
            "Propane": "non-electricity",
        }
    )
    df["cooking_range"] = df["build_existing_model.cooking_range"].map(
        {
            "Electric Induction": "electricity",
            "Electric Resistance": "electricity",
            "Gas": "non-electricity",
            "None": "none",
            "Propane": "non-electricity",
        }
    )
    df["geometry_building_type_recs"] = df["build_existing_model.geometry_building_type_recs"].map(
        {
            "Mobile Home": "manufactured home",
            "Multi-Family with 2 - 4 Units": "apartment unit, 2-4",
            "Multi-Family with 5+ Units": "apartment unit, 5+",
            "Single-Family Attached": "single-family attached",
            "Single-Family Detached": "single-family detached",
        }
    )
    df["hvac_cooling_type"] = df["build_existing_model.hvac_cooling_type"].map(
        {
            "Central AC": "central air conditioner",
            "Ducted Heat Pump": "heat pump",
            "Non-Ducted Heat Pump": "heat pump",
            "None": "none",
            "Room AC": "room air conditioner",
        }
    )
    df["water_heater_fuel_type"] = df["build_existing_model.water_heater_fuel"].map(
        {
            "Electricity": "electricity",
            "Fuel Oil": "non-electricity",
            "Natural Gas": "non-electricity",
            "Other Fuel": "non-electricity",
            "Propane": "non-electricity",
        }
    )
    df["vintage_simp"] = df["build_existing_model.vintage"].map(
        {
            "<1940": "<1940",
            "1940s": "1940-69",
            "1950s": "1940-69",
            "1960s": "1940-69",
            "1970s": "1970-79",
            "1980s": "1980-89",
            "1990s": "1990+",
            "2000s": "1990+",
            "2010s": "1990+",
        }
    )
    df["geometry_unit_cfa_bin_simp"] = df["build_existing_model.geometry_floor_area"].map(
        {
            "0-499": "0-999",
            "500-749": "0-999",
            "750-999": "0-999",
            "1000-1499": "1000-1999",
            "1500-1999": "1000-1999",
            "2000-2499": "2000+",
            "2500-2999": "2000+",
            "3000-3999": "2000+",
            "4000+": "2000+",
        }
    )
    df = df.rename(
        columns={
            "build_existing_model.geometry_floor_area": "geometry_unit_cfa_bin",
            "build_existing_model.vintage": "vintage",
        }
    )
    return df


def buildstock_csv_column_renaming(df):
    df = df.rename(
        columns={
            "Heating Fuel": "build_existing_model.heating_fuel",
            "Clothes Dryer": "build_existing_model.clothes_dryer",
            "Cooking Range": "build_existing_model.cooking_range",
            "Geometry Building Type RECS": "build_existing_model.geometry_building_type_recs",
            "HVAC Cooling Type": "build_existing_model.hvac_cooling_type",
            "Water Heater Fuel": "build_existing_model.water_heater_fuel",
            "Vintage": "build_existing_model.vintage",
            "Geometry Floor Area": "build_existing_model.geometry_floor_area",
            "Has PV": "build_existing_model.has_pv",
            "HVAC Heating Type": "build_existing_model.hvac_heating_type",
            "Building": "building_id",
        }
    )
    return df

def oedi_column_renaming(df):
    df = df.rename(
        columns={
            "in.heating_fuel": "build_existing_model.heating_fuel",
            "in.clothes_dryer": "build_existing_model.clothes_dryer",
            "in.cooking_range": "build_existing_model.cooking_range",
            "in.geometry_building_type_recs": "build_existing_model.geometry_building_type_recs",
            "in.hvac_cooling_type": "build_existing_model.hvac_cooling_type",
            "in.water_heater_fuel": "build_existing_model.water_heater_fuel",
            "in.vintage": "build_existing_model.vintage",
            "in.geometry_floor_area": "build_existing_model.geometry_floor_area",
            "in.has_pv": "build_existing_model.has_pv",
            "in.hvac_heating_type": "build_existing_model.hvac_heating_type",
            "bldg_id": "building_id",
        }
    )
    return df


def buildstock_csv_results_column_renaming(df):
    df = df.rename(
        columns={
            "panel_capacity": "Panel Size",
            "break_space_headroom": "Break Space Headroom",
            "major_elec_load_count": "Major Elec Load Count",
            "build_existing_model.heating_fuel": "Heating Fuel",
            "build_existing_model.clothes_dryer": "Clothes Dryer",
            "build_existing_model.cooking_range": "Cooking Range",
            "build_existing_model.geometry_building_type_recs": "Geometry Building Type RECS",
            "build_existing_model.hvac_cooling_type": "HVAC Cooling Type",
            "build_existing_model.water_heater_fuel": "Water Heater Fuel",
            "vintage": "Vintage",
            "geometry_unit_cfa_bin": "Geometry Floor Area",
            "build_existing_model.has_pv": "Has PV",
            "build_existing_model.hvac_heating_type": "HVAC Heating Type",
            "building_id": "Building",
        }
    )
    return df


def oedi_results_column_renaming(df):
    df = df.rename(
        columns={
            "panel_capacity": "out.panel_capacity",
            "break_space_headroom": "out.break_space_headroom",
            "major_elec_load_count": "out.major_elec_load_count",
            "build_existing_model.heating_fuel": "in.heating_fuel",
            "build_existing_model.clothes_dryer": "in.clothes_dryer",
            "build_existing_model.cooking_range": "in.cooking_range",
            "build_existing_model.geometry_building_type_recs": "in.geometry_building_type_recs",
            "build_existing_model.hvac_cooling_type": "in.hvac_cooling_type",
            "build_existing_model.water_heater_fuel": "in.water_heater_fuel",
            "vintage": "in.vintage",
            "geometry_unit_cfa_bin": "in.geometry_floor_area",
            "build_existing_model.has_pv": "in.has_pv",
            "build_existing_model.hvac_heating_type": "in.hvac_heating_type",
            "building_id": "bldg_id",
        }
    )
    return df

    
def read_file(
    filename: Union[str, Path], low_memory: bool = True, **kwargs
) -> pd.DataFrame:
    """If file is large, use low_memory=False"""
    filename = Path(filename)
    if filename.suffix == ".csv":
        df = pd.read_csv(
            filename, low_memory=low_memory, keep_default_na=False, **kwargs
        )
    elif filename.suffix == ".parquet":
        df = pd.read_parquet(filename, **kwargs)
    else:
        raise TypeError(f"Unsupported file type, cannot read file: {filename}")
    return df


def read_probs_table(prediction_type: str, building_type: str, heating_fuel: str):
    if prediction_type == "break_space":
        return (
            electrical_panel_resources_dir
            / "electrical_panel_breaker_space.csv"
        )
    elif prediction_type == "capacity":
        if building_type == "single_family":
            # w/ simplified heating fuel
            if heating_fuel == "electricity":
                return (
                    electrical_panel_resources_dir
                    / "electrical_panel_rated_capacity__single_family_electric_heating.csv"
                )
            elif heating_fuel == "non-electricity":
                return (
                    electrical_panel_resources_dir
                    / "electrical_panel_rated_capacity__single_family_nonelectric_heating.csv"
                )
        elif building_type == "multi_family":
            return (
                    electrical_panel_resources_dir
                    / "electrical_panel_rated_capacity__multi_family.csv"
                )
    raise ValueError(f"Unknown {heating_fuel=}")


def get_major_elec_load_count(df):
    df.loc[df["build_existing_model.heating_fuel"] != "Electricity", "has_elec_heating_primary"] = 0
    df.loc[df["build_existing_model.heating_fuel"] == "Electricity", "has_elec_heating_primary"] = 1 
    df.loc[df["build_existing_model.hvac_cooling_type"].isin(["None","Room AC"]), "has_central_non_heat_pump_cooling"] = 0
    df.loc[df["build_existing_model.hvac_cooling_type"].isin(["Central AC","Non-Ducted Heat Pump"]), "has_central_non_heat_pump_cooling"] = 1 
    # Ducted heat pump provides heating and cooling, so no additional slots for cooling
    df.loc[((df["build_existing_model.hvac_cooling_type"] == "Ducted Heat Pump") & (df["build_existing_model.hvac_heating_type"] == "Ducted Heat Pump")), "has_central_non_heat_pump_cooling"] = 0
    df.loc[df["build_existing_model.water_heater_fuel"] != "Electricity", "has_elec_water_heater"] = 0
    df.loc[df["build_existing_model.water_heater_fuel"] == "Electricity", "has_elec_water_heater"] = 1 
    df.loc[~df["build_existing_model.clothes_dryer"].isin(['Electric']), "has_elec_drying"] = 0
    df.loc[df["build_existing_model.clothes_dryer"].isin(['Electric']), "has_elec_drying"] = 1
    df.loc[~df["build_existing_model.cooking_range"].isin(['Electric Resistance', 'Electric Induction']), "has_elec_cooking"] = 0
    df.loc[df["build_existing_model.cooking_range"].isin(['Electric Resistance','Electric Induction']), "has_elec_cooking"] = 1
    df.loc[df["build_existing_model.has_pv"] != "Yes", "has_pv"] = 0
    df.loc[df["build_existing_model.has_pv"] == "Yes", "has_pv"] = 1 
    df["has_ev_charging"] = 0

    load_vars = ['has_elec_heating_primary',
                 'has_central_non_heat_pump_cooling',
                 'has_elec_water_heater',
                 'has_elec_drying',
                 'has_elec_cooking',
                 'has_pv',
                 'has_ev_charging']
    df['major_elec_load_count'] = df[load_vars].sum(axis=1)

    return df


def get_row_headers(prob_table, lookup_array, header_size):
    length = len(lookup_array)
    column_names = prob_table.columns.tolist()
    row_headers = column_names[length:length + header_size]
    return row_headers


def get_row_probability(prob_table, lookup_array, header_size):
    length = len(lookup_array)
    row_probability = []

    # Vectorized matching
    subset = prob_table.iloc[:, :length]
    mask = (subset == lookup_array).all(axis=1)
    matching_rows = prob_table[mask]
    row_probability = [float(value) for value in matching_rows.iloc[0][length:length+ header_size]]

    if len(row_probability) != header_size:
        raise ValueError(f"ElectricalPanelSampler cannot find row_probability for keys: {lookup_array}")

    return row_probability


def weighted_random(weights, building_id):
    random.seed(building_id)
    slots = [x for x in range(0,len(weights))]
    index= random.choices(slots, weights=weights)[0]
    return index


def sample_rated_capacity_bin(prob_map, row, model_type: str):
    building_id = row["building_id"]
    if model_type == "single-family-e":
        lookup_array = [row["clothes_dryer"],
                        row["cooking_range"],
                        row["geometry_building_type_recs"],
                        row["geometry_unit_cfa_bin"],
                        row["hvac_cooling_type"],
                        row["vintage"],
                        row["water_heater_fuel_type"]]
    elif model_type == "single-family-ne":
        lookup_array = [row["geometry_building_type_recs"],
                        row["geometry_unit_cfa_bin"],
                        row["vintage"]]
    elif model_type == "multi-family":
        lookup_array = [row["geometry_unit_cfa_bin_simp"],
                        row["vintage_simp"],
                        row["heating_fuel"]]
    else:
        raise ValueError(f"Unknown model type={model_type}, valid: ['single-family-e', 'single-family-ne', 'multi-family']")
        
    capacity_bins = get_row_headers(prob_map, lookup_array, 7)
    row_probability = get_row_probability(prob_map, lookup_array, 7)
    index = weighted_random(row_probability, building_id)
    return capacity_bins[index]


def sample_breaker_space_headroom(breaker_space_headroom_prob_map, row):
    building_id = row["building_id"]
    lookup_array = [row["geometry_building_type_recs"],
                        row["geometry_unit_cfa_bin"],
                        row["major_elec_load_count"],
                        row["panel_capacity"]]
    breaker_space_headroom = get_row_headers(breaker_space_headroom_prob_map, lookup_array, 32)
    row_probability = get_row_probability(breaker_space_headroom_prob_map, lookup_array, 32)
    index = weighted_random(row_probability, building_id)
    return breaker_space_headroom[index]


def capacity_prediction(dfb):
    sf_e_file = read_probs_table("capacity", "single_family", "electricity")
    sf_ne_file = read_probs_table("capacity", "single_family", "non-electricity")
    mf_file = read_probs_table("capacity", "multi_family", "all")
    df_prob_table_sf_e = read_file(sf_e_file)
    df_prob_table_sf_ne = read_file(sf_ne_file)
    df_prob_table_mf = read_file(mf_file)

    # process baseline results data
    dfb_sf = dfb.loc[dfb['geometry_building_type_recs'].isin(["manufactured home",
                                                              "single-family attached",
                                                              "single-family detached",])]
    dfb_mf = dfb.loc[dfb['geometry_building_type_recs'].isin(["apartment unit, 2-4",
                                                              "apartment unit, 5+",])]
    dfb_sf_e = dfb_sf.loc[dfb_sf['heating_fuel'] == "electricity"]
    dfb_sf_ne = dfb_sf.loc[dfb_sf['heating_fuel'] == "non-electricity"]

    for index, row in dfb_sf_e.iterrows():
        dfb_sf_e.at[index, "panel_capacity"] = sample_rated_capacity_bin(df_prob_table_sf_e, row, "single-family-e")
    for index, row in dfb_sf_ne.iterrows():
        dfb_sf_ne.at[index, "panel_capacity"] = sample_rated_capacity_bin(df_prob_table_sf_ne, row, "single-family-ne")
    for index, row in dfb_mf.iterrows():
        dfb_mf.at[index, "panel_capacity"] = sample_rated_capacity_bin(df_prob_table_mf, row, "multi-family")

    df_capacity = pd.concat([dfb_sf_e, dfb_sf_ne, dfb_mf], ignore_index=True)

    return df_capacity


def breaker_space_prediction(dfb):
    file = read_probs_table("break_space", "all", "all")
    df_prob_table = read_file(file)

    # breaker space prediction
    for index, row in dfb.iterrows(): 
        dfb.at[index,"break_space_headroom"] = sample_breaker_space_headroom(df_prob_table, row)
    return dfb

def drop_columns(df):
    df.drop(['has_elec_heating_primary',
              'has_central_non_heat_pump_cooling',
              'has_elec_water_heater',
              'has_elec_drying',
              'has_elec_cooking',
              'has_pv',
              'has_ev_charging',
              'heating_fuel',
              'clothes_dryer',
              'cooking_range',
              'geometry_building_type_recs',
              'hvac_cooling_type',
              'water_heater_fuel_type',
              'vintage_simp',
              'geometry_unit_cfa_bin_simp'], axis=1, inplace=True)
    return df

def main(
        filename: str | None = None,
        buildstock_csv: bool = False,
        oedi_baseline_results: bool = False,
        ):
    global data_dir, electrical_panel_resources_dir

    local_dir = Path(__file__).resolve().parent
    data_dir = local_dir / "test_data"
    electrical_panel_resources_dir = local_dir / "test_data" / "electrical_panel_resources"

    if filename is None:
        filename = local_dir / "test_data" / "panels_30k_results_up00_100.csv"
    else:
        filename = Path(filename)

    ext = "panel_prediction"
    output_filename = data_dir / (filename.stem + "__" + ext + ".csv")
    
    dfb = read_file(filename, low_memory=False)
    if buildstock_csv:
        print("process data for buildstock csv data format")
        dfb = buildstock_csv_column_renaming(dfb)
    elif oedi_baseline_results:
        print("process data for oedi data format")
        dfb.reset_index(inplace=True)
        dfb = oedi_column_renaming(dfb)

    dfb["panel_capacity"] = 0
    dfb["break_space_headroom"] = 0
    dfb = get_major_elec_load_count(dfb)
    dfb = apply_special_mapping(dfb)
    print("capacity prediction") 
    current_time = datetime.datetime.now()
    print(current_time.strftime("%Y-%m-%d %H:%M:%S"))
    dfb = capacity_prediction(dfb)
    print("breaker space prediction") 
    current_time = datetime.datetime.now()
    print(current_time.strftime("%Y-%m-%d %H:%M:%S"))
    dfb = breaker_space_prediction(dfb)
    print("prediction finished") 
    current_time = datetime.datetime.now()
    print(current_time.strftime("%Y-%m-%d %H:%M:%S"))
    dfb = drop_columns(dfb)

    if buildstock_csv:
        dfb = buildstock_csv_results_column_renaming(dfb)
    elif oedi_baseline_results:
        dfb = oedi_results_column_renaming(dfb)

    dfb.to_csv(output_filename, index=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "filename",
        action="store",
        default=None,
        nargs="?",
        help="Path to ResStock baseline result file, e.g., results_up00.csv"
        "defaults to test data: test_data/panels_30k_results_up00_100.csv",
    )

    parser.add_argument(
        "-b",
        "--buildstock_csv",
        action="store_true",
        default=False,
        help="The input file is buildstock csv file instead of ResStock baseline result file"
        "e.g., buildstock.csv",
    )

    parser.add_argument(
        "-o",
        "--oedi_baseline_results",
        action="store_true",
        default=False,
        help="The input file is OEDI baseline result file instead of ResStock baseline result file"
        "e.g., baseline_metadata_and_annual_results.csv",
    )

    args = parser.parse_args()
    main(
        args.filename,
        buildstock_csv=args.buildstock_csv,
        oedi_baseline_results=args.oedi_baseline_results,
    )