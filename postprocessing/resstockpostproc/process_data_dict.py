"""
Process data dictionary to create a schema for polars / pyarrow.
The number of columns and their datatype is based on the data dictionary and
the project yaml file used in the simulation.
"""

import pathlib
import polars as pl
import re

dict_path = pathlib.Path(__file__).parent / "resources" / "dictionary"
polar_dtypes = {
        "bool": pl.Boolean,
        "int": pl.Int32,
        "float": pl.Float32,
        "string": pl.String,
        "datetime": pl.Datetime(time_unit="ms"),
    }

resstock_timeseries_ouput_variables_map = {
    "People Sensible Heating Rate": ["People Sensible Heating Rate: Occupants"],
    "People Total Heating Rate": ["People Total Heating Rate: Occupants"],
    "Site Outdoor Air Humidity Ratio": ["Site Outdoor Air Humidity Ratio: Environment"],
}
bsb_timeseries_ouput_variables_map = {
    "People Sensible Heating Rate": ["people_sensible_heating_rate__occupants__w"],
    "People Total Heating Rate": ["people_total_heating_rate__occupants__w"],
    "Site Outdoor Air Humidity Ratio": ["site_outdoor_air_humidity_ratio__environment__kgwater/kgdryair"],
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

def reorder_annual_schema(annual_schema: dict):
    first_few_cols = [
        "building_id",
        "started_at",
        "completed_at",
        "completed_status",
        "apply_upgrade.applicable",
        "apply_upgrade.upgrade_name",
        "apply_upgrade.reference_scenario",
    ]
    all_cols = annual_schema.keys()
    if "job_id" in all_cols:
        first_few_cols.insert(2, "job_id")

    build_existing_model_cols = sorted([col for col in all_cols if col.startswith("build_existing_model")])
    sim_output_report_cols = sorted([col for col in all_cols if col.startswith("simulation_output_report")])
    report_sim_output_cols = sorted([col for col in all_cols if col.startswith("report_simulation_output")])
    upgrade_costs_cols = sorted([col for col in all_cols if col.startswith("upgrade_costs")])
    last_cols = ["step_failures", "eplusout_err", "upgrade"]
    sorted_cols = (
        first_few_cols
        + build_existing_model_cols
        + sim_output_report_cols
        + report_sim_output_cols
        + upgrade_costs_cols
    )

    remaining_cols = sorted(set(all_cols).difference(sorted_cols + last_cols))
    sorted_cols += remaining_cols
    sorted_cols += last_cols
    return {col: annual_schema[col] for col in sorted_cols}

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
        output_cols.remove(col)
        if "_total_" not in col and "_net_" not in col:
            # we are not producing per-enduse emissions currently. If we later add settings in cfg to 
            # conditionally produce them, we can handle them here. Otherwise TODO: remove from data dictionary
            continue
        for emission_scenario in emission_scenarios:
            output_cols.append(col.replace("<type>_<scenario_name>", emission_scenario))
    
    # Handle bills
    bill_scenarios = [to_underscore_case(scn['scenario_name']) 
                          for scn in cfg["workflow_generator"]["args"].get("utility_bills", [])]
    bill_cols = [col for col in output_cols if "report_utility_bills.<scenario_name>" in col]
    include_monthly_bill = cfg["workflow_generator"]["args"].get("simulation_output_report", {}).get("include_monthly_bill", False)
    for col in bill_cols:
        output_cols.remove(col)
        if col.endswith("usd") or include_monthly_bill:  # monthly col looks like: electricity_total_usd_2007_01_01
            for bill_scenario in bill_scenarios:
                output_cols.append(col.replace("<scenario_name>", bill_scenario))

    # handle panels
    panel_types = ["2023_existing_dwelling_load_based"]
    panel_cols = [col for col in output_cols if "electric_panel_load_<type>" in col]
    for col in panel_cols:
        output_cols.remove(col)
        for panel_type in panel_types:
            output_cols.append(col.replace("<type>", panel_type))
    output_schema_dict = {col: pl.Float32 for col in output_cols}
    
    all_schema_dict = input_schema_dict | output_schema_dict
    all_schema_dict = reorder_annual_schema(all_schema_dict)
    return all_schema_dict

def get_bsb_timeseries_schema(cfg: dict):
    output_dict_df = pl.read_csv(dict_path / "outputs.csv")
    output_cols = [col for col in output_dict_df["Timeseries BuildStockBatch Name"].to_list() if col is not None]
    
    # Handle emissions
    emission_scenarios = [f"{scn['type'].lower()}__{scn['scenario_name'].lower()}" 
                          for scn in cfg["workflow_generator"]["args"].get("emissions", [])]
    emission_cols = [col for col in output_cols if "emissions__<type>__<scenario_name>" in col]
    for col in emission_cols:
        output_cols.remove(col)
        if ("total__lb" not in col) and ("net__lb" not in col):
             # we are not producing per-enduse emissions timeseries currently. If we later add settings in cfg to 
             # conditionally produce them, we can handle them here. Otherwise TODO: remove from data dictionary
            continue
        for emission_scenario in emission_scenarios:
            output_cols.append(col.replace("<type>__<scenario_name>", emission_scenario))

    # Handle ouput variables
    for output_var in cfg["workflow_generator"]["args"].get("simulation_output_report", {}).get("output_variables", []):
        output_cols.extend(bsb_timeseries_ouput_variables_map.get(output_var.get("name"), []))

    output_schema_dict = {col: pl.Float32 for col in output_cols}
    time_cols = [col for col in output_cols if "time" in col.lower()]
    output_schema_dict |= {col: pl.Datetime(time_unit="ms") for col in time_cols}

    component_load_cols = [col for col in output_cols if "component_load_" in col]
    energy_cols = [col for col in output_cols if "enduse_" in col or "energy_" in col or 'fuel_use' in col]
    emission_cols = [col for col in output_cols if "emissions_" in col]
    schedule_cols = [col for col in output_cols if "schedule_" in col]
    listed_cols = set(component_load_cols + energy_cols + emission_cols + schedule_cols)
    other_cols = [col for col in output_cols if col not in listed_cols]
    new_order = time_cols + energy_cols + component_load_cols + emission_cols + other_cols + schedule_cols
    output_schema_dict = {col: output_schema_dict[col] for col in new_order}
    return output_schema_dict   

def get_resstock_timeseries_schema(cfg: dict):
    output_dict_df = pl.read_csv(dict_path / "outputs.csv")
    output_cols = [col for col in output_dict_df["Timeseries ResStock Name"].to_list() if col is not None]
   
    # Handle emissions
    emission_scenarios = [f"{scn['type']}: {scn['scenario_name']}" 
                          for scn in cfg["workflow_generator"]["args"].get("emissions", [])]
    emission_cols = [col for col in output_cols if "Emissions: <type>: <scenario_name>:" in col]
    for col in emission_cols:
        output_cols.remove(col)
        if " Total" not in col and " Net" not in col:
             # we are not producing per-enduse emissions timeseries currently. If we later add settings in cfg to 
             # conditionally produce them, we can handle them here. Otherwise TODO: remove from data dictionary
            continue
        for emission_scenario in emission_scenarios:
            output_cols.append(col.replace("<type>: <scenario_name>", emission_scenario))
    
    # Handle component loads
    include_ts_comp_load = (
        cfg["workflow_generator"]["args"]
        .get("simulation_output_report", {})
        .get("include_timeseries_component_loads", False)
    )
    if not include_ts_comp_load:
        component_load_cols = [col for col in output_cols if "Component Load: <type>: <scenario_name>" in col]
        for col in component_load_cols:
            output_cols.remove(col)

    # Handle ouput variables
    for output_var in cfg["workflow_generator"]["args"].get("simulation_output_report", {}).get("output_variables", []):
        output_cols.extend(resstock_timeseries_ouput_variables_map.get(output_var.get("name"), []))

    output_schema_dict = {col: pl.Float32 for col in output_cols}
    time_cols = [col for col in output_cols if "time" in col.lower()]
    output_schema_dict |= {col: pl.Datetime(time_unit="ms") for col in time_cols}
    return output_schema_dict
