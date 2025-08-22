"""
Process data dictionary to create a schema for polars / pyarrow.
The number of columns and their datatype is based on the data dictionary and
the project yaml file used in the simulation.
"""

import pathlib
import polars as pl
from typing import List
import re

dict_path = pathlib.Path(__file__).parent / "resources" / "dictionary"
polar_dtypes = {
        "bool": pl.Boolean,
        "int": pl.Int32,
        "float": pl.Float32,
        "string": pl.String,
        "datetime": pl.Datetime(time_unit="ms"),
    }

timeseries_ouput_variables_map = {
    "People Sensible Heating Rate": ["People Sensible Heating Rate: Occupants"],
    "People Total Heating Rate": ["People Total Heating Rate: Occupants"],
    "Site Outdoor Air Humidity Ratio": ["Site Outdoor Air Humidity Ratio: Environment"],
}

def to_underscore_case(s: str) -> str:
    # based on: https://github.com/NREL/OpenStudio/blob/af19df2c59c092e1f6e69b8d040f2804e9ac66d3/src/utilities/core/StringHelpers.cpp#L36
    # Special-case brand names to avoid splitting "Studio" and "Plus"
    r = s.replace("OpenStudio", "Openstudio")
    r = r.replace("EnergyPlus", "Energyplus")
    r = re.sub(r"[^a-zA-Z0-9]", " ", r)
    r = re.sub(r"([\-]+)", "_", r)
    r = re.sub(r"([\s]+)", "_", r)
    r = re.sub(r"([A-Za-z])([0-9])", r"\1_\2", r)
    r = re.sub(r"([0-9]+)([A-Za-z])", r"\1_\2", r)
    r = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", r)
    r = re.sub(r"([a-z])([A-Z])", r"\1_\2", r)
    return r.lower()

def get_annual_results_schema(cfg: dict):
    input_dict_df = pl.read_csv(dict_path / "inputs.csv")
    output_dict_df = pl.read_csv(dict_path / "outputs.csv")
    input_schema_dict = dict(zip(input_dict_df["Input Name"].to_list(), [polar_dtypes[x] for x in input_dict_df["Data Type"].to_list()]))
    output_cols = [col for col in output_dict_df["Annual Name"].to_list() if col is not None]

    input_schema_dict |= {"step_failures":pl.String}

    # Handle upgrade_costs.option_<option_number>_name
    max_num_options = max(len(upgrade.get("options", [])) for upgrade in cfg.get("upgrades", []))
    del input_schema_dict["upgrade_costs.option_<option_number>_name"]
    for i in range(1, max_num_options + 1):
        input_schema_dict[f"upgrade_costs.option_{i:02}_name"] = pl.String
    
    # Handle emissions
    emission_scenarios = [to_underscore_case(f"{scn['type']}_{scn['scenario_name']}") 
                          for scn in cfg["workflow_generator"]["args"].get("emissions", [])]
    emission_cols = [col for col in output_cols if "emissions_<type>_<scenario_name>" in col]
    for col in emission_cols:
        if "_total_" not in col:
             # we are not producing per-enduse emissions currently. If we later add settings in cfg to 
             # conditionally produce them, we can handle them here. Otherwise TODO: remove from data dictionary
            continue
        for emission_scenario in emission_scenarios:
            output_cols.append(col.replace("<type>_<scenario_name>", emission_scenario))
        output_cols.remove(col)
    
    # Handle bills
    bill_scenarios = [to_underscore_case(scn['scenario_name']) 
                          for scn in cfg["workflow_generator"]["args"].get("utility_bills", [])]
    bill_cols = [col for col in output_cols if "report_utility_bills.<scenario_name>" in col]
    include_monthly_bill = cfg["workflow_generator"]["args"].get("simulation_output_report", {}).get("include_monthly_bill", False)
    for col in bill_cols:
        if col.endswith("usd") or include_monthly_bill:  # monthly col looks like: electricity_total_usd_2007_01_01
            for bill_scenario in bill_scenarios:
                output_cols.append(col.replace("<scenario_name>", bill_scenario))
            output_cols.remove(col)

    # handle panels
    panel_types = ["2023_existing_dwelling_load_based"]
    panel_cols = [col for col in output_cols if "electric_panel_load_<type>" in col]
    for col in panel_cols:
        for panel_type in panel_types:
            output_cols.append(col.replace("<type>", panel_type))
        output_cols.remove(col)
    output_schema_dict = {col: pl.Float32 for col in output_cols}
    
    return input_schema_dict | output_schema_dict

def get_timeseries_results_schema(cfg: dict, type: str):
    output_dict_df = pl.read_csv(dict_path / "outputs.csv")
    if type == "resstock":
        output_cols = [col for col in output_dict_df["Timeseries ResStock Name"].to_list() if col is not None]
    elif type == "buildstockbatch":
        output_cols = [col for col in output_dict_df["Timeseries BuildStockBatch Name"].to_list() if col is not None]
    else:
        raise ValueError(f"Invalid type: {type}. Valid types are 'resstock' and 'buildstockbatch'.")
    
    # Handle emissions
    emission_scenarios = [f"{scn['type']}: {scn['scenario_name']}" 
                          for scn in cfg["workflow_generator"]["args"].get("emissions", [])]
    emission_cols = [col for col in output_cols if "Emissions: <type>: <scenario_name>:" in col]
    for col in emission_cols:
        if " Total" not in col:
             # we are not producing per-enduse emissions timeseries currently. If we later add settings in cfg to 
             # conditionally produce them, we can handle them here. Otherwise TODO: remove from data dictionary
            continue
        for emission_scenario in emission_scenarios:
            output_cols.append(col.replace("<type>: <scenario_name>", emission_scenario))
        output_cols.remove(col)

    # Handle ouput variables
    for output_var in cfg["workflow_generator"]["args"].get("simulation_output_report", {}).get("output_variables", []):
        output_cols.extend(timeseries_ouput_variables_map.get(output_var.get("name"), []))

    output_schema_dict = {col: pl.Float32 for col in output_cols}
    return output_schema_dict
