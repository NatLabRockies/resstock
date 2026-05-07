"""
Requires env with python >= 3.10
-**
Electrical Panel Project: Estimate existing and new load in homes using NEC (2023)
Load Summing Method: 220.83
Maximum Demand Method: 220.87

NEC panel capacity = min. main circuit breaker size (A)

By: Lixi.Liu@nrel.gov, Ilan.Upfal@nrel.gov
Date: 02/01/2023
Updated: 05/07/2026
Note: 
- fixed inconsistencies in garbage assignment and parsing HVAC eq (same fixes in postprocess_panel_new_load_nec_revision_v2.py)

-----------------

[220.83] - Load Summing Method
Generally, sum the following loads and then apply tiered demand load factors to the total load (see CAVEATS)
1) general lighting and receptacle loads at 3 VA/sqft;
2) at least 2 branch circuits for kitchen and 1 branch circuit for laundry at 1.5 kVA per branch; and
3) all appliances that are fastened in place and permanently connected:
   - HVAC (taken as the larger nameplate of space heating or cooling), 
   - water heaters,
   - clothes dryers, 
   - cooking ranges/ovens, 
   - dishwashers,
   - EVSE, 
   - hot tubs, pool heaters, pool pumps, well pumps, garbage disposals, garbage compactors, and 
   - other fixed appliances with at least a 1/4 HP (500W) nameplate rating.

CAVEATS:
Part A: If NO new HVAC load is being added,
    All Load = Existing Load - Load Removed + New Load
   Total Load = 100% of first 8 kVA of All Load + 40% of remaining All Load
Part B: If new HVAC load is being added, 
   Total Load = 100% HVAC Load + 100% of first 8 kVA of Non-HVAC Load + 40% of remaining Non-HVAC load

HVAC load includes:
    - includes 120V air handler for non-electric central furnace, e.g., if HP with secondary gas furance, HP ODU + 120V handler
    - HP heating load = HP + backup (even though for integrated backup, OS-HPXML assumes one of the two can be on at a time)
does not include:
    - shared heating/cooling
    - boiler pump

[220.87] - Maximum Demand Method
Existing Load = 125% x 15_min_electricity_peak (1-full year)
Total Load = Existing Load + New Load
Note: no load is removed from existing load
"""

import pandas as pd
from pathlib import Path
import numpy as np
import math
import argparse
import sys
from itertools import chain
from typing import Optional

from plotting_functions import _plot_scatter, _plot_box
from clean_up00_file import get_housing_char_cols

# --- lookup ---
geometry_unit_aspect_ratio = {
    "Single-Family Detached": 1.8,
    "Single-Family Attached": 0.5556,
    "Multi-Family with 2 - 4 Units": 0.5556,
    "Multi-Family with 5+ Units": 0.5556,
    "Mobile Home": 1.8,
} #  = front_back_length / left_right_width #TODO: not used currently

KBTU_H_TO_W = 293.07103866

def get_nameplate_rating(df_rating, load_category, appliance, parameter="volt-amps"):
    row = df_rating.loc[(df_rating['load_category'] == load_category) & (df_rating['appliance'] == appliance)]
    return list(row[parameter])[0]

nameplate_rating = pd.read_csv("nameplate_rating_new_load.csv")
water_heater_electric_power_rating = get_nameplate_rating(nameplate_rating, 'water heater', 'electric')
water_heater_electric_tankless_1bath_power_rating = get_nameplate_rating(nameplate_rating, 'water heater', 'electric tankless, 1 bathroom')
water_heater_electric_tankless_2bath_power_rating = get_nameplate_rating(nameplate_rating, 'water heater', 'electric tankless, 2 bathrooms')
water_heater_electric_tankless_3bath_power_rating = get_nameplate_rating(nameplate_rating, 'water heater', 'electric tankless, 3+ bathrooms')
water_heater_heat_pump_power_rating = get_nameplate_rating(nameplate_rating, 'water heater', 'heat pump')
water_heater_heat_pump_120_power_rating = get_nameplate_rating(nameplate_rating, 'water heater', 'heat pump, 120V, shared')

washer_power_rating = get_nameplate_rating(nameplate_rating, "clothes washer", "electric")
dryer_elctric_ventless_power_rating = get_nameplate_rating(nameplate_rating, 'clothes dryer', 'electric ventless')
dryer_elctric_power_rating = get_nameplate_rating(nameplate_rating, 'clothes dryer', 'electric')
dryer_elctric_120_power_rating = get_nameplate_rating(nameplate_rating, 'clothes dryer', 'electric, 120V')
dryer_heat_pump_power_rating = get_nameplate_rating(nameplate_rating, 'clothes dryer', 'heat pump')
dryer_heat_pump_120_power_rating = get_nameplate_rating(nameplate_rating, 'clothes dryer', 'heat pump, 120V')

range_elctric_power_rating = get_nameplate_rating(nameplate_rating, 'range/oven', 'electric')
range_induction_power_rating = get_nameplate_rating(nameplate_rating, 'range/oven', 'induction')
range_elctric_120_power_rating = get_nameplate_rating(nameplate_rating, 'range/oven', 'electric, 120V')
range_induction_120_power_rating = get_nameplate_rating(nameplate_rating, 'range/oven', 'induction, 120V')

dishwasher_power_rating = get_nameplate_rating(nameplate_rating, "dishwasher", "standard")
hot_tub_spa_power_rating = get_nameplate_rating(nameplate_rating, 'hot tub/spa', 'electric')
pool_heater_power_rating = get_nameplate_rating(nameplate_rating, 'pool heater', 'electric, 27 kW')
pool_pump_1_and_half_hp_power_rating = get_nameplate_rating(nameplate_rating, 'pool pump', '1.5 HP')
pool_pump_2_hp_power_rating = get_nameplate_rating(nameplate_rating, 'pool pump', '2 HP')

well_pump_1_hp_power_rating = get_nameplate_rating(nameplate_rating, 'well pump', '1 HP')
well_pump_1_and_half_hp_power_rating = get_nameplate_rating(nameplate_rating, 'well pump', '1.5 HP')
ventilation_kitchen_power_rating = get_nameplate_rating(nameplate_rating, 'ventilation', 'kitchen, 300 cfm')
ventilation_bathroom_power_rating = get_nameplate_rating(nameplate_rating, 'ventilation', 'bathroom, 50 cfm')

EVSE_power_rating_level1 = get_nameplate_rating(nameplate_rating, 'electric vehicle charger', 'electric, level 1')
EVSE_power_rating_level2 = get_nameplate_rating(nameplate_rating, 'electric vehicle charger', 'electric, level 2')
garbage_disposal_three_quarters_hp_power_rating = get_nameplate_rating(nameplate_rating, 'garbage disposal', '3/4 HP')
garage_door_half_hp_power_rating = get_nameplate_rating(nameplate_rating, 'garage door opener', '1/2 HP')

# --- funcs ---

### -------- existing load specs --------
def _general_load_lighting(row: pd.Series) -> float:
    """General Lighting & Receptacle Loads. NEC 220.41
    Accounts for motors < 1/8HP and connected to lighting circuit is covered by lighting load
    Dwelling footprint area MUST include garage

    Args:
        row : row of Pd.DataFrame()
        by_perimeter: bool
            Whether calculation is based on 
    """
    if row["completed_status"] != "Success":
        return np.nan

    garage_depth = 24 # ft
    match row["build_existing_model.geometry_garage"].lower():
        case "1 car":
            garage_width = 12
        case "2 car":
            garage_width = 24
        case "3 car":
            garage_width = 36
        case "none":
            garage_width = 0
        case _:
            raise ValueError(f"Unsupported {row['build_existing_model.geometry_garage']=}")
    
    floor_area = float(row["upgrade_costs.floor_area_conditioned_ft_2"]) # already based on exterior dim (AHS)

    # calculate based on perimeter of footprint with receptables at every 6-feet
    aspect_ratio = geometry_unit_aspect_ratio[row["build_existing_model.geometry_building_type_recs"]]
    fb_length = math.sqrt(floor_area * aspect_ratio) # total as if single-story
    lr_width = floor_area / fb_length

    floor_area += garage_width*garage_depth

    n_receptables = 2*(fb_length+lr_width) // 6
    receptable_load = n_receptables * 20*120 # 20-Amp @ 120V
    # TODO: add other potential unit loads

    return 3 * floor_area


def _general_load_kitchen(row: pd.Series, n: int | str = 2) -> float:
    """Small Appliance Branch Circuits. NEC 220-16(a)
        At least 2 small appliances branch circuits at 20A must be included. NEC 210-11(c)1

        NEMA 5-15 3-prong plug, max up to 72A (60% * 120V) per circuit
        bldgtype-dependent: branch up to # receptacles

        Small appliances:
            - refrigerator: 100-250W
            - freezer: 30-100W

    Args:
        n: int | "auto"
            number of branches for small appliances, minimum 2
    """
    if row["completed_status"] != "Success":
        return np.nan

    if n == "auto":
        n = 2  # start with min requirement
        # TODO: can expand based on building_type, vintage, and floor_area
    if n < 2:
        raise ValueError(
            f"{n=}, at least 2 small appliance/kitchen branch circuit for General Load"
        )
    return n * 1500


def _general_load_laundry(row: pd.Series, n: int | str = 1) -> float:
    """Laundry Branch Circuit(s). NEC 210-11(c)2, 220-16(b), 220-4(c)
        At least 1 laundry branch circuit must be included.

    Args:
        n: int | "auto"
            number of branches for general laundry load (exclude dryer), minimum 1
    """
    if row["completed_status"] != "Success":
        return np.nan
    if n == "auto":
        n = 1
    return 1500*n


def _general_load_washer(row: pd.Series) -> float:
    """If washer is larger than laundry branch circuit, add
        Pecan St clothes washers: 600-1440 W (1165 wt avg)
        Pecan St gas dryers: 600-2760 W (800 wt avg)

    Args:
        n: int | "auto"
            number of branches for general laundry load (exclude dryer), minimum 1
    """
    if row["completed_status"] != "Success":
        return np.nan

    if row["build_existing_model.clothes_washer_presence"].lower() == "yes":
        if washer_power_rating > 1500:
            return washer_power_rating
        return 0
    return 0


def _fixed_load_water_heater(row: pd.Series) -> float:
    """
    NumberofBathrooms = NumberofBedrooms/2 + 0.5
    Bedrooms = [1, 2, 3, 4, 5]
    Bathrooms = [1, 1.5, 2, 2.5, 3]
    tankless = [1, 2, 2, 3+, 3+]
    """
    if row["completed_status"] != "Success":
        return np.nan
    
    water_heater = row["build_existing_model.water_heater_efficiency"].lower()
    bedrooms = int(row["build_existing_model.bedrooms"])
    if (row["build_existing_model.water_heater_in_unit"].lower() == "yes") and ((
        row["build_existing_model.water_heater_fuel"].lower() == "electricity")or(
        "electric" in water_heater
        )):
        if water_heater == "electric tankless":
            if bedrooms == 1:
                return water_heater_electric_tankless_1bath_power_rating 
            if bedrooms in [2,3]:
                return water_heater_electric_tankless_2bath_power_rating
            if bedrooms in [4,5]:
                return water_heater_electric_tankless_3bath_power_rating
            raise ValueError(f'Unsupported {row["build_existing_model.bedrooms"]=}')
        if "heat pump" in water_heater:
            if "120v" in water_heater or "120 v" in water_heater:
                return water_heater_heat_pump_120_power_rating
            return water_heater_heat_pump_power_rating
        return water_heater_electric_power_rating
    return 0


def _fixed_load_dishwasher(row: pd.Series) -> float:
    """
    Dishwasher: 12-15A, 120V
        Amperage not super correlated with kWh rating, but will assume 12A for <=255kWh, and 15A else
    """
    if row["completed_status"] != "Success":
        return np.nan

    if row["build_existing_model.dishwasher"].lower() == "none":
        return 0
    return dishwasher_power_rating


def _fixed_load_ventilations(row: pd.Series) -> float:
    """
    Per 2010 BAHSP / OS-HPXML defaults
    Bathroom fans: (code mandate)
        - one fan per bathroom, 50 cfm per fan, 0.3 W/cfm
        - NumberofBathrooms = NumberofBedrooms / 2 + 0.5
        - NumberofBathrooms * 15 W
    Kitchen exhaust: (recommended, likely overestimated, but could offset OTR microwave, which is not counted)
        - OS-HPXML: one fan per cooking range, 100 cfm per fan, 0.3 W/cfm (checked, 180W for 600 cfm hood)
        - 100 cfm is the min recommended and modeled in ResStock, seems too low
        - generally, https://www.greenbuildingadvisor.com/article/sizing-a-kitchen-exhaust-fan
            - 1 cfm per 10 Btu of gas range
            - 10 cfm per inch width of electric range (e.g., 280 cfm for 28")
            - 300 cfm is the general recommendation
        - we do not size cooking in BTU. Instead, annual energy consumption calculated per energy rating rated home (RESNET 301 2019)
        - Finalizing, 300 cfm * 0.3 W/cfm = 90W
    """
    if row["completed_status"] != "Success":
        return np.nan

    num_bathrooms = round(int(row["build_existing_model.bedrooms"])/2+0.5) # OS-HPXML default
    bathroom_vent = num_bathrooms * ventilation_bathroom_power_rating # W

    kitchen_vent = 0
    if row["build_existing_model.cooking_range"].lower() != "none":
        kitchen_vent = ventilation_kitchen_power_rating # W

    return bathroom_vent + kitchen_vent # W


def _fixed_load_garage_door(row: pd.Series) -> float:
    """
    Garage door opener invented in 1926, did not rise in popularity until 1970s
    Per Kitsap, 35 million homes have garage door openers
    Number of attached garages modeled in ResStock: 44 million homes

    Assume all garages have a garage door opener

    https://www.google.com/search?q=how+many+garage+has+door+opener&client=safari&sca_esv=1e424f4fdf06d354&sca_upv=
    1&rls=en&ei=gxXvZsbZIci0wN4P6tC0uQw&oq=how+many+garage+has+do&gs_lp=Egxnd3Mtd2l6LXNlcnAiFmhvdyBtYW55IGdhcmFnZSB
    oYXMgZG8qAggAMgUQIRigATIFECEYoAEyBRAhGKABMgUQIRigATIFECEYoAEyBRAhGKsCMgUQIRirAjIFECEYqwIyBRAhGJ8FMgUQIRifBUi0gQ
    FQvAZYj3NwCngBkAECmAHyAaABpx6qAQY1LjIyLjK4AQPIAQD4AQGYAiWgAoUcwgIKEAAYsAMY1gQYR8ICCxAAGIAEGJECGIoFwgIKEAAYgAQYQ
    xiKBcICERAuGIAEGLEDGNEDGIMBGMcBwgILEAAYgAQYsQMYgwHCAg4QLhiABBixAxiDARiKBcICExAuGIAEGLEDGNEDGEMYxwEYigXCAg0QLhiA
    BBhDGOUEGIoFwgIFEAAYgATCAgsQABiABBixAxiKBcICCBAuGIAEGLEDwgILEC4YgAQYsQMY1ALCAg4QABiABBixAxiDARiKBcICCBAAGIAEGLE
    DwgIKEAAYgAQYRhj7AcICFhAAGIAEGEYY-wEYlwUYjAUY3QTYAQHCAgsQABiABBiGAxiKBcICBhAAGBYYHsICCBAAGIAEGKIEwgIIEAAYogQYiQ
    XCAggQABgWGAoYHpgDAIgGAZAGCLoGBggBEAEYE5IHBTE0LjIzoAex1AE&sclient=gws-wiz-serp
    """
    if row["completed_status"] != "Success":
        return np.nan

    match row["build_existing_model.geometry_garage"].lower():
        case "none":
            return 0
        case "1 car":
            return garage_door_half_hp_power_rating
        case "2 car":
            return garage_door_half_hp_power_rating*2
        case "3 car":
            return garage_door_half_hp_power_rating*3
        case _:
            raise ValueError(f"Unsupported {row['build_existing_model.geometry_garage']=}")


def _fixed_load_garbage_disposal(row: pd.Series) -> float:
    """
    garbage disposal: 0.8 - 1.5 kVA (1.2kVA avg), typically second largest motor, after AC compressor
    Insinkerator: 1/3 - 1 HP (3/4 HP avg = 912 W)
    https://insinkerator.emerson.com/en-us/insinkerator-products/garbage-disposals/standard-series

    """
    if row["completed_status"] != "Success":
        return np.nan

    if row["has_garbage_disposal"] == True:
        return garbage_disposal_three_quarters_hp_power_rating  # .75 HP
            
    return 0


def _fixed_load_garbage_compactor(row: pd.Series) -> float:
    """
    We do not currently model compactor
    Ownership is ~ 3% as of 2013 (AHS)
    250 W
    """
    if row["completed_status"] != "Success":
        return np.nan

    return 0


def _fixed_load_hot_tub_spa(row: pd.Series) -> float:
    if row["completed_status"] != "Success":
        return np.nan

    if "electric" in row["build_existing_model.misc_hot_tub_spa"].lower():
        return hot_tub_spa_power_rating
    return 0


def _fixed_load_well_pump(row: pd.Series) -> float:
    """ pump/motor nameplates taken from NEC tables based on HP, not PF needed """
    if row["completed_status"] != "Success":
        return np.nan
    
    well_pump = row["build_existing_model.misc_well_pump"].lower()
    bedrooms = int(row["build_existing_model.bedrooms"])
    if well_pump == "typical efficiency":
        if bedrooms in [1, 2, 3]:
            # up to 8 gpm of water need
            return well_pump_1_hp_power_rating
        if bedrooms in [4, 5]:
            # 9-18 gpm
            return well_pump_1_and_half_hp_power_rating 
        raise ValueError(f'Unsupported {row["build_existing_model.bedrooms"]=}')
    if well_pump == "none":
        return 0
    raise ValueError(f'Unsupported {row["build_existing_model.misc_well_pump"]=}')


def _special_load_dryer(row: pd.Series, method: str) -> float:
    """Clothes Dryers. NEC 220-18
    Use 5000 watts or nameplate rating whichever is larger (in another version, use DF=1 for # appliance <=4)
    240V, 22/24/30A breaker (vented), 30/40A (ventless heat pump), 30A (ventless electric)
    """
    dryer = row["build_existing_model.clothes_dryer"].lower()
    if row["completed_status"] != "Success":
        return np.nan

    if "electric" not in dryer:
        return 0
    
    if "none" in dryer:
        return 0

    if "heat pump" in dryer:
        if "120v" in dryer or "120 v" in dryer:
            if method == "83":
                return 0
            if method == "87":
                return dryer_heat_pump_120_power_rating
            raise ValueError(f"Unsupported {method=}")
        return dryer_heat_pump_power_rating
    if "120v" in dryer or "120 v" in dryer:
        if method == "83":
            return 0
        if method == "87":
            return dryer_elctric_120_power_rating
        raise ValueError(f"Unsupported {method=}")
    if "ventless" in dryer:
        return dryer_elctric_ventless_power_rating
    return dryer_elctric_power_rating


def _special_load_cooking_range_oven(row: pd.Series) -> float: 
    """ Assuming a single electric range (combined oven/stovetop) for each dwelling unit """
    if row["completed_status"] != "Success":
        return np.nan

    cooking_range = row["build_existing_model.cooking_range"].lower()
    if "electric" not in cooking_range:
        return 0
    
    if "none" in cooking_range:
        return 0

    if "induction" in cooking_range:
        if "120v" in cooking_range or "120 v" in cooking_range:
            return range_induction_120_power_rating
        return range_induction_power_rating 

    if "120v" in cooking_range or "120 v" in cooking_range:
        return range_elctric_120_power_rating

    return range_elctric_power_rating 


def _special_load_space_heating_no_ahu(row: pd.Series) -> tuple[list[Optional[str]], list[float]]:
    if row["completed_status"] != "Success":
        return [None for _ in range(3)], [np.nan for _ in range(3)]

    # shared heating is not part of dwelling unit's panel
    if row["build_existing_model.hvac_has_shared_system"] in ["Heating Only", "Heating and Cooling"]:
        return [None, None, None], [0, 0, 0]

    # heating load
    heating_type = get_heating_type(row["build_existing_model.hvac_heating_efficiency"])
    secondary_heating_type = get_heating_type(row["build_existing_model.hvac_secondary_heating_efficiency"])

    heating_cols = [
        row["upgrade_costs.size_heating_system_primary_k_btu_h"],
        row["upgrade_costs.size_heating_system_secondary_k_btu_h"],
        row["upgrade_costs.size_heat_pump_backup_primary_k_btu_h"]
        ]
    system_cols = [
        heating_type,
        secondary_heating_type,
        "er" if row["upgrade_costs.size_heat_pump_backup_primary_k_btu_h"] > 0 else None,
        ]

    heating_loads = [hvac_heating_conversion(x, system_type=y) for x, y in zip(heating_cols, system_cols)]


    return system_cols, heating_loads


def _special_load_space_cooling_no_ahu(row: pd.Series) -> tuple[Optional[str], float]:
    if row["completed_status"] != "Success":
        return None, np.nan

    # shared cooling is not part of dwelling unit's panel
    if row["build_existing_model.hvac_has_shared_system"] in ["Cooling Only", "Heating and Cooling"]:
        return None, 0

    cooling_type = get_cooling_type(row["build_existing_model.hvac_cooling_efficiency"])
    cooling_load = hvac_cooling_conversion(
        row["upgrade_costs.size_cooling_system_primary_k_btu_h"],
        system_type=cooling_type
    )
 
    return cooling_type, cooling_load


def _special_load_space_conditioning(row: pd.Series) -> tuple[float, float, float, Optional[str]]:
    """ Not accounting for humidifier
    assume secondary heating is separately controlled from primary heating
    1 Btu/h = 0.29307103866W

    Returns:
        max(loads) : int
            special_load_for_heating_or_cooling
    """
    if row["completed_status"] != "Success":
        return np.nan, np.nan, np.nan, None
    
    heating_types, heating_loads,  = _special_load_space_heating_no_ahu(row) # combines primary, secondary, and backup
    cooling_type, cooling_load = _special_load_space_cooling_no_ahu(row)

    # Add AHU
    heat_ahu, cool_ahu, error_msg = _get_air_handlers(row, heating_types, cooling_type, apply_check=False)
    heating_load = sum(heating_loads) + heat_ahu
    cooling_load += cool_ahu
    return heating_load, cooling_load, max(heating_load, cooling_load), error_msg


def _special_load_space_conditioning_itemized(row) -> tuple[
        Optional[str], Optional[str], Optional[str],
        float, float, float, float, float, float,
        Optional[str]
]:
    """ Not accounting for humidifier
    assume secondary heating is separately controlled from primary heating
    1 Btu/h = 0.29307103866W

    """
    if row["completed_status"] != "Success":
        outputs = [np.nan for _ in range(3)] + [None for _ in range(5)] + [np.nan for _ in range(6)]
        return tuple(outputs)
    
    heating_types, heat_loads = _special_load_space_heating_no_ahu(row) # combines primary, secondary, and backup
    cooling_type, cool_load = _special_load_space_cooling_no_ahu(row)

    heating_load = sum(heat_loads)
    cooling_load = cool_load

    # AHU
    heat_ahu, cool_ahu, error_msg = _get_air_handlers(row, heating_types, cooling_type, apply_check=False)

    # Get final loads
    heating_load += heat_ahu
    cooling_load += cool_ahu
    hvac_load = max(heating_load, cooling_load) 

    outputs = [heating_load, cooling_load, hvac_load, error_msg]
    outputs += heating_types + [cooling_type] + heat_loads + [cool_load, heat_ahu, cool_ahu]

    return tuple(outputs)


def _special_load_pool_heater(row: pd.Series) -> float:
    """NEC 680.9
    https://twphamilton.com/wp/wp-content/uploads/doc033548.pdf
    """
    if row["completed_status"] != "Success":
        return np.nan

    pool_heater = row["build_existing_model.misc_pool_heater"].lower()
    if pool_heater == "electricity":
        return pool_heater_power_rating
    if pool_heater in ["none", "natural gas", "other fuel"]:
        return 0
    raise ValueError(f'Unknown {row["build_existing_model.misc_pool_heater"]=}')


def _special_load_pool_pump(row: pd.Series) -> float:
    """NEC 680
    In ResStock, the pool pump options are 0.75-1 HP, which are erroneously coded.
    According to this BA report, a standard single-speed HP is 1.5-2 HP.
    https://www.nrel.gov/docs/fy12osti/54242.pdf
    Mapping:
        "1.0 HP Pump": 2-HP
        "0.75 HP Pump": 1.5-HP
    1HP = 746W
    """
    if row["completed_status"] != "Success":
        return np.nan

    pool_pump = row["build_existing_model.misc_pool_pump"].lower()
    if pool_pump == "0.75 hp pump":
        return pool_pump_1_and_half_hp_power_rating
    if pool_pump == "1.0 hp pump":
        return pool_pump_2_hp_power_rating
    if pool_pump == "none":
        return 0
    raise ValueError(f'Unknown {row["build_existing_model.misc_pool_pump"]=}')


def _special_load_evse(row: pd.Series, method: str) -> float:
    if row["completed_status"] != "Success":
        return np.nan

    ev = row["build_existing_model.electric_vehicle"].lower()
    if ev == "none":
        return 0
    if "level 1" in ev:
        if method == "83":
            return 0
        if method == "87":
            return EVSE_power_rating_level1
        raise ValueError(f"Unsupported {method=}")
    if "level 2" in ev:
        return EVSE_power_rating_level2
    raise ValueError(f"Unsupported {row['build_existing_model.electric_vehicle']=}")


def _special_load_heat_pump_backup(row):
    if row["completed_status"] != "Success":
        return np.nan

    heat_pump_backup = hvac_heating_conversion(
        row["upgrade_costs.size_heat_pump_backup_primary_k_btu_h"], 
        system_type="Electric Resistance"
        )
    return heat_pump_backup


### -------- util funcs --------
def _is_ducted(hvac_type: Optional[str]) -> bool | None:
    if hvac_type:
        # non-ducted uses "non-ducted"
        return "ducted" in hvac_type and "non-ducted" not in hvac_type
    return None


def _is_heat_pump(hvac_type: Optional[str]) -> bool | None:
    if hvac_type:
        return "hp" in hvac_type
    return None


def _is_fuel(heating_type: Optional[str]) -> bool | None:
    if heating_type:
        return "fuel" in heating_type
    return None


def _check_hvac_consistency(heating_type: Optional[str], secondary_heating_type: Optional[str], cooling_type: Optional[str]) -> None:
    if _is_heat_pump(heating_type):
        assert heating_type == cooling_type, f"expecting {cooling_type=} of a {heating_type=} to be a heat pump"
        assert _is_ducted(heating_type) == _is_ducted(cooling_type), f"expecting consistent duct type between {heating_type=} and {cooling_type=}"

    assert not _is_heat_pump(secondary_heating_type), "secondary heating cannot be a heat pump"


def _get_air_handler_for_heating(capacity: float, heating_type: Optional[str], apply_check: bool = True) -> tuple[float, Optional[str]]:
    if not heating_type:
        return 0, None

    if not _is_ducted(heating_type):
        return 0, None

    if _is_fuel(heating_type):
        heat_ahu = hvac_120V_air_handler(capacity)
    else:
        heat_ahu = hvac_240V_air_handler(capacity)

    msg = ""
    if apply_check:
        if heat_ahu == 0:
            msg += f"expecting a AHU load for {heating_type=}"
    msg = msg if msg else None
    return heat_ahu, msg


def _get_air_handlers(row, heating_types, cooling_type, apply_check=True) -> tuple[float, float, Optional[str]]:
    """Typically you need more volume of air to cool the house than to heat it. 
    So the cooling requirements determine the size of the air handler. 
    However the air handler comes with the furnace. 
    So the air handler size is determined by the furnace size and voltage

    Current logic: 
    - if HP with secondary furnace, use secondary furnace, else use 240V AHU
    - if gas furnace with CAC, use gas furnace (based on heat cap only, 120V)
    - if electric furnace with CAC, 240V, take max of heat/cool to determine AHU
    - if no ducted heating, use CAC (based on cool cap only)
    """
    [heating_type, secondary_heating_type, backup_heating_type] = heating_types

    # _check_hvac_consistency(heating_type, secondary_heating_type, cooling_type)
    error_msg = ""
    if _is_heat_pump(heating_type):
        if _is_ducted(secondary_heating_type):
            # HP coil is added to existing furnace
            heat_ahu, msg = _get_air_handler_for_heating(row["upgrade_costs.size_heating_system_secondary_k_btu_h"], secondary_heating_type, apply_check=apply_check)
            if msg:
                error_msg += f"Secondary heating error: {msg} "
            cool_ahu = heat_ahu
        else:
            if _is_ducted(heating_type):
                if _is_fuel(backup_heating_type) and _is_ducted(backup_heating_type):
                    # use backup fuel furnace
                    heat_ahu, msg = _get_air_handler_for_heating(row['upgrade_costs.size_heat_pump_backup_primary_k_btu_h'], backup_heating_type, apply_check=apply_check)
                    if msg:
                        error_msg += f"Backup heating error: {msg} "
                else:
                    # regular with or without integrated electric backup
                    heat_ahu = hvac_240V_air_handler(row["upgrade_costs.size_heating_system_primary_k_btu_h"])
                    if apply_check:
                        if heat_ahu == 0:
                            error_msg += f"Primary HP heating error: expecting a AHU load for {heating_type=} "
                cool_ahu = heat_ahu
            else:
                # non-ducted HP
                if _is_ducted(backup_heating_type):
                    # non-ducted HP with ducted backup, use backup furnace
                    heat_ahu, msg = _get_air_handler_for_heating(row['upgrade_costs.size_heat_pump_backup_primary_k_btu_h'], backup_heating_type, apply_check=apply_check)
                    if msg:
                        error_msg += f"Backup heating error: {msg} "
                    cool_ahu = 0
                else:
                    heat_ahu = cool_ahu = 0

    else:
        # not heat pump
        heat_ahu1, msg = _get_air_handler_for_heating(row["upgrade_costs.size_heating_system_primary_k_btu_h"], heating_type, apply_check=apply_check)
        if msg:
            error_msg += f"Primary non-HP heating error: {msg} "

        heat_ahu2, msg = _get_air_handler_for_heating(row["upgrade_costs.size_heating_system_secondary_k_btu_h"], secondary_heating_type, apply_check=apply_check)
        if msg:
            error_msg += f"Secondary non-HP heating error: {msg} "

        # assume if both primary and secondary heating are ducted, they use the same AHU, so take the max load of either to determine AHU load
        heat_ahu = max(heat_ahu1, heat_ahu2)

        # cooling
        if _is_ducted(cooling_type):
            cool_ahu = hvac_240V_air_handler(row["upgrade_costs.size_cooling_system_primary_k_btu_h"])
            if apply_check:
                if cool_ahu == 0:
                    error_msg += f"Cooling error: expecting a AHU load for {cooling_type=} "
        else:
            cool_ahu = 0

        if _is_ducted(heating_type) and _is_ducted(cooling_type):
            if _is_fuel(heating_type):
                # gas furnace with CAC, use gas furnace
                cool_ahu = heat_ahu
            else:
                # electric furance with CAC, use max of either
                final_ahu = max(heat_ahu, cool_ahu)
                cool_ahu = heat_ahu = final_ahu

    error_msg = error_msg if error_msg else None
    return heat_ahu, cool_ahu, error_msg


def get_cooling_type(cool_eff: str) -> Optional[str]:
    """
    Take "build_existing_model.hvac_cooling_efficiency" NOT "build_existing_model.hvac_cooling_type"
    """
    ct = cool_eff.lower()
    if "room ac" in ct:
        return "non-ducted cooling"
    if "ac" in ct:
        return "ducted cooling" # must come after room AC
    if "non-ducted heat pump" in ct:
        return "non-ducted hp"
    if "ducted heat pump" in ct:
        return "ducted hp" # must come after non-ducted
    if ct in ["none", "shared cooling"]:
        return None
    raise ValueError(f"Unknown cooling type {cool_eff}")
    

def get_heating_type(heat_eff: str) -> Optional[str]:
    ht = heat_eff.lower()
    if "ashp" in ht:
        return "ducted hp"
    if "mshp" in ht:
        return "non-ducted hp"
    if "electric" in ht:
        if ("boiler" in ht) or ("wall/floor furnace" in ht) or ("baseboard" in ht):
            return "non-ducted er"
        elif "furnace" in ht:
            return "ducted er"
        else:
            raise ValueError(f"Unsupported: {heat_eff=}")
    if "fuel" in ht:
        if ("boiler" in ht) or ("wall/floor furnace" in ht) or ("baseboard" in ht):
            return "non-ducted fuel"
        elif "furnace" in ht:
            return "ducted fuel"
        else:
            raise ValueError(f"Unsupported: {heat_eff=}")

    if ht in ["none", "shared heating"]:
        return None
    raise ValueError(f"Unsupported: {heat_eff=}")


def hvac_240V_air_handler(nom_cap: float) -> float:
    ahu_volt = get_nameplate_rating(nameplate_rating, 'space heating/cooling', 'electric air handler', parameter="voltage")
    amp_para = get_nameplate_rating(nameplate_rating, 'space heating/cooling', 'electric air handler', parameter="amperage").split(",")
    ahu_amp = max(float(amp_para[2]), float(amp_para[0])*float(nom_cap) + float(amp_para[1]))
    return ahu_volt * ahu_amp if nom_cap > 0 else 0


def hvac_120V_air_handler(nom_cap: float) -> float:
    ahu_volt = get_nameplate_rating(nameplate_rating, 'space heating', 'fuel air handler', parameter="voltage")
    amp_para = get_nameplate_rating(nameplate_rating, 'space heating', 'fuel air handler', parameter="amperage").split(",")
    ahu_amp = max(float(amp_para[2]), float(amp_para[0])*float(nom_cap) + float(amp_para[1]))
    return ahu_volt * ahu_amp if nom_cap > 0 else 0


def apply_va_linear_regression(nom_cap: float, load_category: str, appliance: str) -> float:
    volt = get_nameplate_rating(nameplate_rating, load_category, appliance, parameter="voltage")
    amp_para = get_nameplate_rating(nameplate_rating, load_category, appliance, parameter="amperage").split(",")
    amp = float(amp_para[0])*float(nom_cap) + float(amp_para[1])
    return volt * amp if nom_cap > 0 else 0


def hvac_heating_conversion(nom_heat_cap: float, system_type: Optional[str] = None) -> float:
    """ 
    Relationship between either minimum breaker or minimum circuit amp (x voltage) and nameplate capacity
    nominal conditions refer to AHRI standard conditions: 47F?
    Args :
        nom_heat_cap : float
            nominal heating capacity in kbtu/h
        system_type : str
            system type
        heating_eff : str
            heating efficiency
    Returns : 
        W = Amp*V
    """ 
    if system_type is None or "fuel" in system_type:
        return 0

    nom_heat_cap = float(nom_heat_cap)
    if "hp" in system_type:
        return apply_va_linear_regression(nom_heat_cap, "space heating", "heat pump")
    if "er" in system_type:
        return nom_heat_cap * KBTU_H_TO_W
    raise ValueError(f"Unknown {system_type=}")


def hvac_cooling_conversion(nom_cool_cap: float, system_type: Optional[str] = None) -> float:
    """ 
    Relationship between either minimum breaker or minimum circuit amp (x voltage) and nameplate capacity
    nominal conditions refer to AHRI standard conditions: 95F?
    Args :
        nom_cool_cap : float
            nominal cooling capacity in kbtu/h
        system_type : str
            system type
    Returns : 
        W = Amp*V
    """
    if system_type is None or system_type == "None":
        return 0

    nom_cool_cap = float(nom_cool_cap)
    if "hp" in system_type:
        return apply_va_linear_regression(nom_cool_cap, "space cooling", "heat pump")
    elif system_type == "ducted cooling":
        return apply_va_linear_regression(nom_cool_cap, "space cooling", "central ac")
    elif system_type == "non-ducted cooling":
        return apply_va_linear_regression(nom_cool_cap, "space cooling", "room ac")
    else:
        raise ValueError(f"Unknown {system_type=}")


def standard_amperage(x: float) -> int:
    """Convert min_amp_col into standard panel size
    http://www.naffainc.com/x/CB2/Elect/EHtmFiles/StdPanelSizes.htm
    """
    if pd.isnull(x):
        return np.nan

    # TODO: refine
    standard_sizes = np.array([
        50, 100, 125, 150, 200, 225,
        250])
    standard_sizes = np.append(standard_sizes, np.arange(300, 1250, 50))
    factors = standard_sizes / x

    cond = standard_sizes[factors >= 1]
    if len(cond) == 0:
        print(
            f"WARNING: {x} is higher than the largest standard_sizes={standard_sizes[-1]}, "
            "double-check NEC calculations"
        )
        return math.ceil(x / 100) * 100

    return cond[0]


def read_file(filename: str, low_memory: bool =True, sort_bldg_id: bool = False, **kwargs) -> pd.DataFrame:
    """ If file is large, use low_memory=False"""
    filename = Path(filename)
    if filename.suffix in [".csv", ".gz"]:
        df = pd.read_csv(filename, low_memory=low_memory, keep_default_na=False, **kwargs)
    elif filename.suffix == ".parquet":
        df = pd.read_parquet(filename)
    else:
        raise TypeError(f"Unsupported file type, cannot read file: {filename}")

    if sort_bldg_id:
        df = df.sort_values(by="building_id").reset_index(drop=True)

    return df


def bin_panel_sizes(df_column: pd.Series) -> pd.Series:
    df_out = df_column.copy()
    df_out.loc[df_column<100] = "<100"
    df_out.loc[(df_column>100) & (df_column<125)] = "101-124"
    df_out.loc[(df_column>125) & (df_column<200)] = "126-199"
    df_out.loc[df_column>200] = "200+"
    df_out = df_out.astype(str)

    return df_out


def generate_plots(df: pd.DataFrame, output_dir: Path, sfd_only: bool = False):
    msg = " for Single-Family Detached only" if sfd_only else ""
    print(f"generating plots{msg}...")
    _plot_scatter(df, "amp_total_pre_upgrade_A_220_83", "amp_total_pre_upgrade_A_220_87", 
        title=None, output_dir=output_dir, sfd_only=sfd_only)
    for metric in ["amp_total_pre_upgrade_A_220_83", "amp_total_pre_upgrade_A_220_87"]:
        for hc in [
        "build_existing_model.census_region",
        "build_existing_model.census_division",
        "build_existing_model.ashrae_iecc_climate_zone_2004",
        "build_existing_model.geometry_building_type_recs",  # dep
        "build_existing_model.state",
        # "build_existing_model.vintage",  # dep
        "build_existing_model.vintage_acs",
        "build_existing_model.federal_poverty_level",
        "build_existing_model.area_median_income",
        "build_existing_model.tenure",
        "build_existing_model.geometry_floor_area_bin",
        # "build_existing_model.geometry_floor_area",  # dep
        "build_existing_model.heating_fuel",  # dep
        "build_existing_model.water_heater_fuel",  # dep
        "build_existing_model.hvac_heating_type",
        "build_existing_model.hvac_cooling_type",  # dep
        ]:
            _plot_box(df, metric, hc, output_dir=output_dir, sfd_only=sfd_only)
    print(f"plots output to: {output_dir}")


def existing_load_labels_limited() -> list[str]:
    existing_loads_labels = ["load_heating", "load_cooling", "load_hvac", "hvac_msg",]
    existing_loads_labels += [
        "load_water_heater",
        "load_dryer",
        "load_range_oven",
        "load_hot_tub_spa",
        "load_pool_heater",
        "load_evse",
    ]
    return existing_loads_labels


def existing_load_labels() -> list[str]:
    existing_loads_labels = existing_load_labels_limited()
    existing_loads_labels += [
        "load_lighting",
        "load_kitchen",
        "load_laundry",
        "load_washer",
        "load_dishwasher",
        "load_others", # disposal, garage doors, ventilations, 
        "load_well_pump",
        "load_pool_pump",
        
    ]
    return existing_loads_labels


def hvac_labels_itemized() -> list[str]:
    return [
        "load_heating", "load_cooling", "load_hvac", "hvac_msg",
        "type_primary_heat", "type_secondary_heat", "type_backup_heat", "type_cool",
        "load_primary_heat", "load_secondary_heat", "load_backup_heat", "load_cool", # does not include AHU
        "load_heat_ahu",
        "load_cool_ahu",
    ]

def existing_load_labels_detailed() -> list[str]:
    existing_loads_labels = hvac_labels_itemized()
    existing_loads_labels += [
        "load_water_heater",
        "load_dryer",
        "load_range_oven",
        "load_hot_tub_spa",
        "load_pool_heater",
        "load_evse",
        "load_lighting",
        "load_kitchen",
        "load_laundry",
        "load_washer",
        "load_dishwasher",
        "load_others", # disposal, garage doors, ventilations, 
        "load_well_pump",
        "load_pool_pump",
        
    ]
    return existing_loads_labels


def apply_existing_loads_limited(row: pd.Series, method: str) -> list:
    """ breakdown of existing load for limited load categories """

    existing_loads = list(_special_load_space_conditioning(row)) # (heating_load, cooling_load, hvac_load, error_msg)
    existing_loads += [ 
            _fixed_load_water_heater(row),
            _special_load_dryer(row, method),
            _special_load_cooking_range_oven(row),
            _fixed_load_hot_tub_spa(row),
            _special_load_pool_heater(row),
            _special_load_evse(row, method),
        ]

    return existing_loads


def apply_existing_loads(row: pd.Series, method: str, n_kit: int = 2, n_ldr: int = 1) -> list:
    """ Load summing method """

    existing_loads = apply_existing_loads_limited(row, method) 
    existing_loads += [
            _general_load_lighting(row), # sqft
            _general_load_kitchen(row, n=n_kit), # consider logic based on sqft
            _general_load_laundry(row, n=n_ldr), # consider logic based on sqft (up to 2)
            _general_load_washer(row),
            _fixed_load_dishwasher(row),
                _fixed_load_garbage_disposal(row)+
                # _fixed_load_garbage_compactor(row)+
                _fixed_load_garage_door(row)+
                _fixed_load_ventilations(row),
            _fixed_load_well_pump(row),
            _special_load_pool_pump(row),
            
        ]

    return existing_loads


def apply_existing_loads_detailed(row, method: str, n_kit: int = 2, n_ldr: int = 1) -> list[float]:
    """ Load summing method """
    
    # order of hvac_loads: pri_heat_sys, sec_heat_sys, bkup_heat_sys, pri_heat_load, sec_heat_load, bkup_heat_load, cool_load, heat_ahu, cool_ahu, hvac_error_msg
    existing_loads = list(_special_load_space_conditioning_itemized(row)) 
    existing_loads += [
            _fixed_load_water_heater(row),
            _special_load_dryer(row, method),
            _special_load_cooking_range_oven(row),
            _fixed_load_hot_tub_spa(row),
            _special_load_pool_heater(row),
            _special_load_evse(row, method),
        ]

    existing_loads += [
            _general_load_lighting(row), # sqft
            _general_load_kitchen(row, n=n_kit), # consider logic based on sqft
            _general_load_laundry(row, n=n_ldr), # consider logic based on sqft (up to 2)
            _general_load_washer(row),
            _fixed_load_dishwasher(row),
                _fixed_load_garbage_disposal(row)+
                # _fixed_load_garbage_compactor(row)+
                _fixed_load_garage_door(row)+
                _fixed_load_ventilations(row),
            _fixed_load_well_pump(row),
            _special_load_pool_pump(row),
            
        ]

    return existing_loads


def apply_demand_factor(x, threshold=8000):
    """
    Split load into the following tiers and apply associated multiplier factor
        If threshold == 8000:
            <= 8kVA : 1.00
            > 8kVA : 0.4
    """
    return (
        1 * min(threshold, x) +
        0.4 * max(0, x - threshold)
    )


def apply_total_load_220_83(row, has_new_hvac_load: bool) -> float | list[float]:
    """Apply demand factor to existing loads per 220.83"""
    threshold = 8000 # VA
    if has_new_hvac_load:
        # 220.83 [B]: 100% HVAC load + 100% of 1st 8kVA other_loads + 40% of remainder other_loads
        hvac_load = row["load_hvac"]
        other_load = row.sum() - hvac_load
        total_load = hvac_load + apply_demand_factor(other_load, threshold=threshold)

    else:
        # 220.83 [A]: 100% of 1st 8kVA all loads + 40% of remainder loads
        total_load = apply_demand_factor(row.sum(), threshold=threshold)

    return total_load


### -------- load method calcs --------
def calculate_existing_load_total_220_83(dfi: pd.DataFrame, n_kit: int = 2, n_ldr: int = 1, explode_result: bool = False, result_as_map: bool = False) -> pd.DataFrame:
    """
    Calculate existing load using 220.83(A)
    NEC 220.83 - Load summing method
        Total loads = existing loads - loads removed + new loads
        Total loads get discounted based on whether additional space conditioning is added: (A)=No or (B)=Yes

    NEC 220.83 (A) where additional AC or space-heating IS NOT being installed
        - Total load = existing + new loads, 100% 1st 8kVA of total, 40% remainder of total
        - Used if upgrade has no electric space conditioning
    
    NEC 220.83 (B) where additional AC or space-heating IS being installed
        - 100% HVAC load + 100% 1st 8kVA other loads + 40% remainder of other
        - Used if upgrade has electric space conditioning, includes ER heating -> HP

    """
    print("Performing NEC 220.83 (load-summing) (A) calculations...")
    df = dfi.copy()
    hvac_itemized_cols = hvac_labels_itemized()

    # Existing loads
    existing_loads_detailed = existing_load_labels_detailed()
    df_existing = pd.DataFrame(
        df.apply(lambda x: apply_existing_loads_detailed(x, "83", n_kit=n_kit, n_ldr=n_ldr), axis=1).to_list(),
        index = df.index, columns=existing_loads_detailed
        )
    existing_loads_nonhvac = [x for x in existing_loads_detailed if x not in hvac_itemized_cols]
    # df_backup = df.apply(lambda x: _special_load_heat_pump_backup(x), axis=1).rename("load_hvac_hp_backup")

    # Total pre-upgrade load based on no new hvac
    total_load_pre = "load_total_pre_upgrade_VA_220_83"
    total_amp_pre = "amp_total_pre_upgrade_A_220_83"
    df_existing[total_load_pre] = df_existing[existing_loads_nonhvac+["load_hvac"]].apply(lambda x: apply_total_load_220_83(x, has_new_hvac_load=False), axis=1)
    df_existing[total_amp_pre] = df_existing[total_load_pre] / 240

    df_result = pd.concat([
        df["building_id"],
        df_existing,
        # df_backup,
        ], axis=1)

    if explode_result:
        cols = df_result.columns
    else:
        cols = ["building_id", total_load_pre, total_amp_pre]

    if result_as_map:
        return df_result[cols]

    return df.join(df_result[cols].set_index("building_id"), on="building_id")


def calculate_existing_load_total_220_87(dfi: pd.DataFrame, result_as_map: bool = False) -> pd.DataFrame:
    """ Maximum demand method 
        - "report_simulation_output.peak_electricity_annual_total_w": timestep -- not available in EUSS RR1
        - "qoi_report.qoi_hourly_peak_magnitude_use_kw": peak of hourly aggregates, different from above
        - EUSS RR1 uses "qoi_report.qoi_peak_magnitude_use_kw"
    """
    print("Performing NEC 220.87 (max-load) calculations...")
    df = dfi.copy()

    # Total pre-upgrade load
    total_load_pre = "load_total_pre_upgrade_VA_220_87"
    total_amp_pre = "amp_total_pre_upgrade_A_220_87"
    peak_col = "report_simulation_output.peak_electricity_annual_total_w"
    if peak_col in df.columns:
        conversion = 1
    else:
        peak_col = "qoi_report.qoi_peak_magnitude_use_kw"
        if peak_col in df.columns:
            conversion = 1000
        else:
            raise ValueError("No suitable electricity peak column found.")
    print(f"Peak electricity column used: {peak_col}")

    df[total_load_pre] = df[peak_col].astype(float) * conversion * 1.25 # VA
    df.loc[df["build_existing_model.vacancy_status"]=="Vacant", total_load_pre] = np.nan
    df[total_amp_pre] = df[total_load_pre] / 240 # amp

    if result_as_map:
        cols = ["building_id", total_load_pre, total_amp_pre]
        return df[cols]

    return df


def assign_garbage_disposal(df):
    """ Garbage disposal was invented in 1938 (Insinkable) and is in 52% of homes as of 2013 (AHS) """
    n_samples = round(len(df)*0.52)
    df["has_garbage_disposal"] = False
    cond = df["build_existing_model.vintage_acs"]!="<1940"
    selected = df.loc[cond, "building_id"].sample(n=n_samples, random_state=1)
    cond = df["building_id"].isin(selected)
    df.loc[cond, "has_garbage_disposal"] = True

    return df


def fix_well_pump(df):
    """ ResStock version specific 
    Currently well pump (12.7%) is randomly assigned to units.
    In 2013 AHS, well pump is said to serve up to 5 units.
    Well water is more common in SF, and actually in metro area
    https://onlinelibrary.wiley.com/doi/full/10.1111/1752-1688.13135
    Removing assignment from multi-family 5+ units (this would drop saturation by about 2.3%)
    """
    cond = df["build_existing_model.geometry_building_type_recs"]=="Multi-Family with 5+ Units"
    df.loc[cond, "build_existing_model.misc_well_pump"] = "None"

    return df


def main(
    baseline_filename: str | None = None, 
    plot: bool = False, sfd_only: bool = False, 
    explode_result: bool = False, 
    result_as_map: bool = False,
    building_id: int | None = None,
    ):
    if baseline_filename is None:
        baseline_filename = (
            Path(__file__).resolve().parent
            / "test_data"
            / "euss1_2018_results_up00_100.csv" # "euss1_2018_results_up00_400plus.csv"
        )
    else:
        baseline_filename = Path(baseline_filename)

    output_filedir = baseline_filename.parent / "nec_calculations_existing_load"
    output_filedir.mkdir(parents=True, exist_ok=True) 
    ext = ""
    if explode_result:
        ext = "_exploded"
    if result_as_map:
        output_filename = output_filedir / (baseline_filename.stem.split(".")[0] + f"__res_map__nec_existing_load{ext}" + baseline_filename.suffix)
    else:
        output_filename = output_filedir / (baseline_filename.stem.split(".")[0] + f"__nec_existing_load{ext}" + baseline_filename.suffix)

    plot_dir_name = f"plots_sfd" if sfd_only else f"plots"
    output_dir = baseline_filename.parent / plot_dir_name / "nec_calculations" / "existing_load"
    output_dir.mkdir(parents=True, exist_ok=True) 

    plot_later = False
    if plot:
        if not output_filename.exists():
            plot_later = True
        else:
            dfo = read_file(output_filename, low_memory=False)
            for col in [ 
                "amp_total_pre_upgrade_A_220_83",  
                "amp_total_pre_upgrade_A_220_87",
            ]:
                dfo[col] = dfo[col].replace("", np.nan).astype(float)
            generate_plots(dfo, output_dir, sfd_only=sfd_only)
            sys.exit()
        
    df = read_file(baseline_filename, compression="infer", low_memory=False, sort_bldg_id=True)
    df = df[df["completed_status"]=="Success"].reset_index(drop=True)

    ## Assign garbage disposal to post-1940 homes randomly so ownership is 52% of dwelling units per 2013 AHS
    garbage_disposal_assignment_file = Path(baseline_filename).parent / "garbage_disposal_assignment.csv"

    if not garbage_disposal_assignment_file.exists():
        assert len(df) == 483063, "baseline has changed, update this as needed"

        df = assign_garbage_disposal(df) # note: assign this before baseline is filtered to match upgrade or it will lead to changing assignment
        df[["building_id", "has_garbage_disposal"]].to_csv(garbage_disposal_assignment_file, index=False) # save assignment for reference and reproducibility
    else:
        df_gd = pd.read_csv(garbage_disposal_assignment_file)
        assert set(df["building_id"]).issubset(set(df_gd["building_id"])), "Garbage disposal assignment file does not match baseline building_id"
        df = df.merge(df_gd, on="building_id", how="left")
    
    # apply building_id filter
    if building_id:
        dfu = dfu.loc[dfu["building_id"]==int(building_id)].reset_index(drop=True)
        df = df.loc[df["building_id"]==int(building_id)].reset_index(drop=True)

    # Format
    columns = [x for x in df.columns if "build_existing_model" in x]
    df[columns] = df[columns].fillna("None")

    ## Remove well pump from MF 5+
    df = fix_well_pump(df)


    # --- NEW LOAD calcs ---
    # NEC 220.83 - Load Summing Method
    # NEC 220.87 - Maximum Demand Method
    if result_as_map:
        df1 = calculate_existing_load_total_220_83(df, n_kit=2, n_ldr=1, explode_result=explode_result, result_as_map=result_as_map)
        df2 = calculate_existing_load_total_220_87(df, result_as_map=result_as_map)
        dfo = df1.join(df2.set_index("building_id"), on="building_id")
        dfo = pd.concat([dfo, df["has_garbage_disposal"]], axis=1)
    else:
        df1 = calculate_existing_load_total_220_83(df, n_kit=2, n_ldr=1, explode_result=explode_result)
        dfo = calculate_existing_load_total_220_87(df1)

    # --- save to file ---
    if output_filename.suffix == ".csv":
        dfo.to_csv(output_filename, index=False)
    elif output_filename.suffix == ".parquet":
        dfo.to_parquet(output_filename)
    print(f"File output to: {output_filename}")

    if plot_later:
        generate_plots(dfo, output_dir, sfd_only=sfd_only)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "baseline_filename",
        action="store",
        default=None,
        nargs="?",
        help="Path to ResStock baseline result file, e.g., results_up00.csv, "
        "defaults to test data: test_data/euss1_2018_results_up00_100.csv"
        )
    parser.add_argument(
        "-p",
        "--plot",
        action="store_true",
        default=False,
        help="Make plots based on expected output file without regenerating output_file",
    )
    parser.add_argument(
        "-d",
        "--sfd_only",
        action="store_true",
        default=False,
        help="Apply calculation to Single-Family Detached only (this is only on plotting for now)",
    )
    parser.add_argument(
        "-x",
        "--explode_result",
        action="store_true",
        default=False,
        help="Whether to export intermediate calculations as part of the results (useful for debugging)",
    )
    parser.add_argument(
        "-m",
        "--result_as_map",
        action="store_true",
        default=False,
        help="Whether to export NEC calculation result as a building_id map only. "
        "Default to appending NEC result as new column(s) to input result file. ",
    )
    parser.add_argument(
        "-b",
        "--building_id",
        action="store",
        default=None,
        nargs="?",
        help="limit calculation to the specified building_id"
    )

    args = parser.parse_args()
    msg = ""
    if not args.baseline_filename:
        msg = "Using test data files"
    print("======================================================")
    print(f"Existing load calculation using 2023 NEC 220.83 and 220.87\n{msg}")
    print("======================================================")
    main(
        args.baseline_filename,
        plot=args.plot, sfd_only=args.sfd_only, explode_result=args.explode_result, result_as_map=args.result_as_map, building_id=args.building_id
        )
