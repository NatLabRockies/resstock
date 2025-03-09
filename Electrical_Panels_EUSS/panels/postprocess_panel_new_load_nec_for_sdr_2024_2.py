"""
Requires env with python >= 3.10
Formatted to work with OEDI dataset 2024.2 (AKA EUSS RR2)
-**
Electrical Panel Project: Estimate existing and new load in homes using NEC (2023)

Load Summing Method: 220.83
Maximum Demand Method: 220.87

NEC panel capacity = min. main circuit breaker size (A)

By: Lixi.Liu@nrel.gov
Date: 03/01/2025
Updated: 03/06/2025

-----------------

[220.83] - Load Summing Method
Generally, sum the following loads and then apply tiered demand load factors to the total load (see CAVEATS)
1) general lighting and receptable loads at 3 VA/sqft;
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
def _general_load_lighting(row, check_completed_status):
    """General Lighting & Receptacle Loads. NEC 220.41
    Accounts for motors < 1/8HP and connected to lighting circuit is covered by lighting load
    Dwelling footprint area MUST include garage

    Args:
        row : row of Pd.DataFrame()
        by_perimeter: bool
            Whether calculation is based on 
    """
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    garage_depth = 24 # ft
    match row[f"{bxm}.geometry_garage"]:
        case "1 Car":
            garage_width = 12
        case "2 Car":
            garage_width = 24
        case "3 Car":
            garage_width = 36
        case "None":
            garage_width = 0
        case _:
            garage_width = 0
    
    sqft = float(row[floor_area]) # already based on exterior dim (AHS)

    # calculate based on perimeter of footprint with receptables at every 6-feet
    aspect_ratio = geometry_unit_aspect_ratio[row[f"{bxm}.geometry_building_type_recs"]]
    fb_length = math.sqrt(sqft * aspect_ratio) # total as if single-story
    lr_width = sqft / fb_length

    sqft += garage_width*garage_depth

    n_receptables = 2*(fb_length+lr_width) // 6
    receptable_load = n_receptables * 20*120 # 20-Amp @ 120V
    # TODO: add other potential unit loads

    return 3 * sqft


def _general_load_kitchen(row, check_completed_status, n=2):
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
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    if n == "auto":
        n = 2  # start with min requirement
        # TODO: can expand based on building_type, vintage, and floor_area
    if n < 2:
        raise ValueError(
            f"{n=}, at least 2 small appliance/kitchen branch circuit for General Load"
        )
    return n * 1500


def _general_load_laundry(row, check_completed_status, n=1):
    """Laundry Branch Circuit(s). NEC 210-11(c)2, 220-16(b), 220-4(c)
        At least 1 laundry branch circuit must be included.

    Args:
        n: int | "auto"
            number of branches for general laundry load (exclude dryer), minimum 1
    """
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan
    if n == "auto":
        n = 1
    return 1500*n


def _general_load_washer(row, check_completed_status):
    """If washer is larger than laundry branch circuit, add
        Pecan St clothes washers: 600-1440 W (1165 wt avg)
        Pecan St gas dryers: 600-2760 W (800 wt avg)

    Args:
        n: int | "auto"
            number of branches for general laundry load (exclude dryer), minimum 1
    """
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    if row[f"{bxm}.clothes_washer_presence"] == "Yes":
        if washer_power_rating > 1500:
            return washer_power_rating
        return 0
    return 0


def _fixed_load_water_heater(row, check_completed_status):
    """
    NumberofBathrooms = NumberofBedrooms/2 + 0.5
    Bedrooms = [1, 2, 3, 4, 5]
    Bathrooms = [1, 1.5, 2, 2.5, 3]
    tankless = [1, 2, 2, 3+, 3+]
    """
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    if (row[f"{bxm}.water_heater_in_unit"] == "Yes") and ((
        row[f"{bxm}.water_heater_fuel"] == "Electricity")or(
        "Electric" in row[f"{bxm}.water_heater_efficiency"]
        )):
        if row[f"{bxm}.water_heater_efficiency"] == "Electric Tankless":
            if int(row[f"{bxm}.bedrooms"]) == 1:
                return water_heater_electric_tankless_1bath_power_rating 
            if int(row[f"{bxm}.bedrooms"]) in [2,3]:
                return water_heater_electric_tankless_2bath_power_rating
            if int(row[f"{bxm}.bedrooms"]) in [4,5]:
                return water_heater_electric_tankless_3bath_power_rating
            raise ValueError(f'Unsupported {row[f"{bxm}.bedrooms"]=}')
        if "Heat Pump" in row[f"{bxm}.water_heater_efficiency"]:
            if "120V" in row[f"{bxm}.water_heater_efficiency"] or "120 V" in row[f"{bxm}.water_heater_efficiency"]:
                return water_heater_heat_pump_120_power_rating
            return water_heater_heat_pump_power_rating
        return water_heater_electric_power_rating
    return 0


def _fixed_load_dishwasher(row, check_completed_status):
    """
    Dishwasher: 12-15A, 120V
        Amperage not super correlated with kWh rating, but will assume 12A for <=255kWh, and 15A else
    """
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    if row[f"{bxm}.dishwasher"] == "None":
        return 0
    return dishwasher_power_rating


def _fixed_load_ventilations(row, check_completed_status):
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
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    num_bathrooms = round(int(row[f"{bxm}.bedrooms"])/2+0.5) # OS-HPXML default
    bathroom_vent = num_bathrooms * ventilation_bathroom_power_rating # W

    kitchen_vent = 0
    if row[f"{bxm}.cooking_range"] != "None":
        kitchen_vent = ventilation_kitchen_power_rating # W

    return bathroom_vent + kitchen_vent # W


def _fixed_load_garage_door(row, check_completed_status):
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
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    if row[f"{bxm}.geometry_garage"] == "None":
        return 0
    if row[f"{bxm}.geometry_garage"] == "1 Car":
        return garage_door_half_hp_power_rating

    if row[f"{bxm}.geometry_garage"] == "2 Car":
        return garage_door_half_hp_power_rating*2

    if row[f"{bxm}.geometry_garage"] == "3 Car":
        return garage_door_half_hp_power_rating*3


def _fixed_load_garbage_disposal(row, check_completed_status):
    """
    garbage disposal: 0.8 - 1.5 kVA (1.2kVA avg), typically second largest motor, after AC compressor
    Insinkerator: 1/3 - 1 HP (3/4 HP avg = 912 W)
    https://insinkerator.emerson.com/en-us/insinkerator-products/garbage-disposals/standard-series

    """
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    if row["has_garbage_disposal"] == True:
        return garbage_disposal_three_quarters_hp_power_rating # .75 HP
            
    return 0


def _fixed_load_garbage_compactor(row, check_completed_status):
    """
    We do not currently model compactor
    Ownership is ~ 3% as of 2013 (AHS)
    250 W
    """
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    return 0


def _fixed_load_hot_tub_spa(row, check_completed_status):
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    if "Electric" in row[f"{bxm}.misc_hot_tub_spa"]:
        return hot_tub_spa_power_rating
    return 0


def _fixed_load_well_pump(row, check_completed_status):
    """ pump/motor nameplates taken from NEC tables based on HP, not PF needed """
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan
    
    if row[f"{bxm}.misc_well_pump"] == "Typical Efficiency":
        if int(row[f"{bxm}.bedrooms"]) in [1, 2, 3]:
            # up to 8 gpm of water need
            return well_pump_1_hp_power_rating
        if int(row[f"{bxm}.bedrooms"]) in [4, 5]:
            # 9-18 gpm
            return well_pump_1_and_half_hp_power_rating 
        raise ValueError(f'Unsupported {row[f"{bxm}.bedrooms"]=}')
    if row[f"{bxm}.misc_well_pump"] == "None":
        return 0
    raise ValueError(f'Unsupported {row[f"{bxm}.misc_well_pump"]=}')


def _special_load_dryer(row, method, check_completed_status):
    """Clothes Dryers. NEC 220-18
    Use 5000 watts or nameplate rating whichever is larger (in another version, use DF=1 for # appliance <=4)
    240V, 22/24/30A breaker (vented), 30/40A (ventless heat pump), 30A (ventless electric)
    """
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    if "Electric" not in row[f"{bxm}.clothes_dryer"] or row[f"{bxm}.clothes_dryer"] == "None":
        return 0

    if "Heat Pump" in row[f"{bxm}.clothes_dryer"]:
        if "120V" in row[f"{bxm}.clothes_dryer"] or "120 V" in row[f"{bxm}.clothes_dryer"]:
            if method == "83":
                return 0
            if method == "87":
                return dryer_heat_pump_120_power_rating
            raise ValueError(f"Unsupported {method=}")
        return dryer_heat_pump_power_rating
    if "120V" in row[f"{bxm}.clothes_dryer"] or "120 V" in row[f"{bxm}.clothes_dryer"]:
        if method == "83":
            return 0
        if method == "87":
            return dryer_elctric_120_power_rating
        raise ValueError(f"Unsupported {method=}")
    if "Ventless" in row[f"{bxm}.clothes_dryer"]:
        return dryer_elctric_ventless_power_rating
    return dryer_elctric_power_rating


def _special_load_cooking_range_oven(row, check_completed_status): 
    """ Assuming a single electric range (combined oven/stovetop) for each dwelling unit """
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    if "Electric" not in row[f"{bxm}.cooking_range"] or row[f"{bxm}.cooking_range"]=="None":
        return 0

    if "Induction" in row[f"{bxm}.cooking_range"]:
        if "120V" in row[f"{bxm}.cooking_range"] or "120 V" in row[f"{bxm}.cooking_range"]:
            return range_induction_120_power_rating
        return range_induction_power_rating 

    if "120V" in row[f"{bxm}.cooking_range"] or "120 V" in row[f"{bxm}.cooking_range"]:
        return range_elctric_120_power_rating

    return range_elctric_power_rating 


def _special_load_space_heating_no_ahu(row, check_completed_status):
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    # shared heating is not part of dwelling unit's panel
    if row[f"{bxm}.hvac_has_shared_system"] in ["Heating Only", "Heating and Cooling"]:
        return 0

    # heating load
    heating_type = get_heating_type(row[f"{bxm}.hvac_heating_efficiency"])
    secondary_heating_type = get_heating_type(row[f"{bxm}.hvac_secondary_heating_efficiency"])

    heating_cols = [
        row[f"{upgc}.size_heating_system_primary_k_btu_h"],
        row[f"{upgc}.size_heating_system_secondary_k_btu_h"],
        row[f"{upgc}.size_heat_pump_backup_primary_k_btu_h"]
        ]
    system_cols = [
        heating_type,
        secondary_heating_type,
        "Electric Resistance",
        ]

    heating_load = sum(
            [hvac_heating_conversion(x, system_type=y) for x, y in zip(heating_cols, system_cols)]
        )

    return heating_load


def _special_load_space_cooling_no_ahu(row, check_completed_status):
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    # shared cooling is not part of dwelling unit's panel
    if row[f"{bxm}.hvac_has_shared_system"] in ["Cooling Only", "Heating and Cooling"]:
        return 0

    cooling_type = get_cooling_type(row[f"{bxm}.hvac_cooling_type"])
    cooling_load = hvac_cooling_conversion(
        row[f"{upgc}.size_cooling_system_primary_k_btu_h"],
        system_type=cooling_type
    )
 
    return cooling_load


def _special_load_space_conditioning(row, check_completed_status):
    """ Not accounting for humidifier
    1 Btu/h = 0.29307103866W

    Returns:
        max(loads) : int
            special_load_for_heating_or_cooling
    """
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan
    
    heating_load = _special_load_space_heating_no_ahu(row, check_completed_status)
    cooling_load = _special_load_space_cooling_no_ahu(row, check_completed_status)

    heating_type = get_heating_type(row[f"{bxm}.hvac_heating_efficiency"])
    secondary_heating_type = get_heating_type(row[f"{bxm}.hvac_secondary_heating_efficiency"])

    # Add AHU
    heat_ahu, cool_ahu = _get_air_handlers(row, heating_type, secondary_heating_type)
    heating_load += heat_ahu
    cooling_load += cool_ahu

    return max(heating_load, cooling_load)


def _special_load_pool_heater(row, check_completed_status):
    """NEC 680.9
    https://twphamilton.com/wp/wp-content/uploads/doc033548.pdf
    """
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    if row[f"{bxm}.misc_pool_heater"] == "Electricity":
        return pool_heater_power_rating
    if row[f"{bxm}.misc_pool_heater"] in ["None", "Natural Gas", "Other Fuel"]:
        return 0
    raise ValueError(f'Unknown {row[f"{bxm}.misc_pool_heater"]=}')


def _special_load_pool_pump(row, check_completed_status):
    """NEC 680
    In ResStock, the pool pump options are 0.75-1 HP, which are erroneously coded.
    According to this BA report, a standard single-speed HP is 1.5-2 HP.
    https://www.nrel.gov/docs/fy12osti/54242.pdf
    Mapping:
        "1.0 HP Pump": 2-HP
        "0.75 HP Pump": 1.5-HP
    1HP = 746W
    """
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    if row[f"{bxm}.misc_pool_pump"] == "0.75 HP Pump":
        return pool_pump_1_and_half_hp_power_rating
    if row[f"{bxm}.misc_pool_pump"] == "1.0 HP Pump":
        return pool_pump_2_hp_power_rating
    if row[f"{bxm}.misc_pool_pump"] == "None":
        return 0
    raise ValueError(f'Unknown {row[f"{bxm}.misc_pool_pump"]=}')


def _special_load_evse(row, method, check_completed_status):
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan
    ev_col = f"{bxm}.electric_vehicle"
    if ev_col in row:
        if row[ev_col] == "None":
            return 0
        raise ValueError(f"Unsupported value {row[ev_col]}")

    ev_col = f"{bxm}.electric_vehicle_charger"
    if ev_col in row:
        if row[ev_col] == "None":
            return 0
        if "Level 1" in row[ev_col]:
            if method == "83":
                return EVSE_power_rating_level1 # 0
            if method == "87":
                return EVSE_power_rating_level1
            raise ValueError(f"Unsupported {method=}")
        if "Level 2" in row[ev_col]:
            return EVSE_power_rating_level2

    raise ValueError("Cannot find relevant EV column")


def _special_load_heat_pump_backup(row, check_completed_status):
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    heat_pump_backup = hvac_heating_conversion(
        row[f"{upgc}.size_heat_pump_backup_primary_k_btu_h"], 
        system_type="Electric Resistance"
        )
    return heat_pump_backup


### -------- [1] new load specs for normal ResStock run files --------
def _new_load_evse(row, option_columns, method, check_completed_status):
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    for opt_col in option_columns:
        if "Electric Vehicle" in row[opt_col] and "Level 1" in row[opt_col]:
            if method == "83":
                return EVSE_power_rating_level1 # 0
            if method == "87":
                return EVSE_power_rating_level1
            raise ValueError(f"Unsupported {method=}")
        if "Electric Vehicle" in row[opt_col] and "Level 2" in row[opt_col]:
            return EVSE_power_rating_level2

    return 0

def _new_load_pool_heater(row, option_columns, check_completed_status):
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    for opt_col in option_columns:
        if "Misc Pool Heater" in row[opt_col] and "Electricity" in row[opt_col]:
            return pool_heater_power_rating

    return 0


def _new_load_hot_tub_spa(row, option_columns, check_completed_status):
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    for opt_col in option_columns:
        if "Misc Hot Tub Spa" in row[opt_col] and "Electricity" in row[opt_col]:
            return hot_tub_spa_power_rating 

    return 0


def _new_load_range_oven(row, option_columns, check_completed_status):
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    for opt_col in option_columns:
        if "Cooking Range" in row[opt_col] and "Electric" in row[opt_col]:
            if "Induction" in row[opt_col]:
                if "120V" in row[opt_col] or "120 V" in row[opt_col]:
                    return range_induction_120_power_rating
                return range_induction_power_rating
            if "120V" in row[opt_col] or "120 V" in row[opt_col]:
                return range_elctric_120_power_rating
            return range_elctric_power_rating 

    return 0


def _new_load_dryer(row, option_columns, method, check_completed_status):
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    for opt_col in option_columns:
        if "Clothes Dryer" in row[opt_col] and "Electric" in row[opt_col]:
            if "Heat Pump" in row[opt_col]:
                if "120V" in row[opt_col] or "120 V" in row[opt_col]:
                    if method == "83":
                        return 0
                    if method == "87":
                        return dryer_heat_pump_120_power_rating
                    raise ValueError(f"Unsupported {method=}")
                return dryer_heat_pump_120_power_rating
            if "120V" in row[opt_col] or "120 V" in row[opt_col]:
                if method == "83":
                    return 0
                if method == "87":
                    return dryer_elctric_120_power_rating
                raise ValueError(f"Unsupported {method=}")
            if "Ventless" in row[opt_col]:
                return dryer_elctric_ventless_power_rating
            return dryer_elctric_power_rating

    return 0


def _new_load_water_heating(row, option_columns, check_completed_status):
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    for opt_col in option_columns:
        if "Water Heater Efficiency" in row[opt_col] and "Electric" in row[opt_col]: 
            if "Electric Tankless" in row[opt_col]:
                if int(row[f"{bxm}.bedrooms"]) == 1:
                    return water_heater_electric_tankless_1bath_power_rating 
                if int(row[f"{bxm}.bedrooms"]) in [2,3]:
                    return water_heater_electric_tankless_2bath_power_rating
                if int(row[f"{bxm}.bedrooms"]) in [4,5]:
                    return water_heater_electric_tankless_3bath_power_rating
                raise ValueError(f'Unsupported {row[f"{bxm}.bedrooms"]=}')
            if "Heat Pump" in row[opt_col]:
                if "120V" in row[opt_col] or "120 V" in row[opt_col]:
                    return water_heater_heat_pump_120_power_rating
                return water_heater_heat_pump_power_rating
            return water_heater_electric_power_rating

    return 0


def _new_load_space_conditioning(row, option_columns, check_completed_status):
    if check_completed_status and row["completed_status"] != "Success":
        return np.nan

    # heating load
    heating_type = None
    secondary_heating_type = None
    backup_heating_type = None
    for opt_col in option_columns:
        if ("HVAC Heating Efficiency" in row[opt_col]):
            heating_type = get_heating_type(row[opt_col])
        if ("HVAC Secondary Heating Efficiency" in row[opt_col]):
            secondary_heating_type = get_heating_type(row[opt_col])

    # TODO: this is not a fail-safe solution
    if heating_type == "Heat Pump":
        if "existing" in row[upg_name].lower():
            backup_heating_type = get_heating_type(row[f"{bxm}.hvac_heating_efficiency"])
        else:
            backup_heating_type = "Electric Resistance"

    heating_cols = [
        row[f"{upgc}.size_heating_system_primary_k_btu_h"],
        row[f"{upgc}.size_heating_system_secondary_k_btu_h"],
        row[f"{upgc}.size_heat_pump_backup_primary_k_btu_h"]
        ]
    system_cols = [
        heating_type,
        secondary_heating_type,
        backup_heating_type,
        ]

    heating_load = sum(
        [hvac_heating_conversion(x, system_type=y) for x, y in zip(heating_cols, system_cols)]
    )


    # cooling load
    cooling_type = None
    for opt_col in option_columns:
        if ("HVAC cooling Efficiency" in row[opt_col]):
            cooling_type = get_cooling_type(row[opt_col])

    cooling_load = hvac_cooling_conversion(
        row[f"{upgc}.size_cooling_system_primary_k_btu_h"],
        system_type=cooling_type
    )

    # Add AHU
    heat_ahu, cool_ahu = _get_air_handlers(row, heating_type, secondary_heating_type)
    heating_load += heat_ahu
    cooling_load += cool_ahu

    return max(heating_load, cooling_load)


### -------- [2] new load specs for oedi_data_format files --------
def _new_load_evse_oedi(row, option_columns, method):
    for opt_col in option_columns:
        if opt_col in ["upgrade.electric_vehicle", "upgrade.electric_vehicle_charger"] and row[opt_col]: 
            if "Level 1" in row[opt_col]:
                if method == "83":
                    return EVSE_power_rating_level1 # 0
                if method == "87":
                    return EVSE_power_rating_level1
                raise ValueError(f"Unsupported {method=}")
            if "Level 2" in row[opt_col]:
                return EVSE_power_rating_level2

    return 0

def _new_load_pool_heater_oedi(row, option_columns):
    for opt_col in option_columns:
        if opt_col == "upgrade.misc_pool_heater" and row[opt_col]: 
            if "Electricity" in row[opt_col]:
                return pool_heater_power_rating

    return 0


def _new_load_hot_tub_spa_oedi(row, option_columns):
    for opt_col in option_columns:
        if opt_col == "upgrade.misc_hot_tub_spa" and row[opt_col]: 
            if "Electricity" in row[opt_col]:
                return hot_tub_spa_power_rating 

    return 0


def _new_load_range_oven_oedi(row, option_columns):
    for opt_col in option_columns:
        if opt_col == "upgrade.cooking_range" and row[opt_col]: 
            if "Electric" in row[opt_col]:
                if "Induction" in row[opt_col]:
                    if "120V" in row[opt_col] or "120 V" in row[opt_col]:
                        return range_induction_120_power_rating
                    return range_induction_power_rating
                if "120V" in row[opt_col] or "120 V" in row[opt_col]:
                    return range_elctric_120_power_rating
                return range_elctric_power_rating 

    return 0


def _new_load_dryer_oedi(row, option_columns, method):
    for opt_col in option_columns:
        if opt_col == "upgrade.clothes_dryer" and row[opt_col]: 
            if "Electric" in row[opt_col]:
                if "Heat Pump" in row[opt_col]:
                    if "120V" in row[opt_col] or "120 V" in row[opt_col]:
                        if method == "83":
                            return 0
                        if method == "87":
                            return dryer_heat_pump_120_power_rating
                        raise ValueError(f"Unsupported {method=}")
                    return dryer_heat_pump_120_power_rating
                if "120V" in row[opt_col] or "120 V" in row[opt_col]:
                    if method == "83":
                        return 0
                    if method == "87":
                        return dryer_elctric_120_power_rating
                    raise ValueError(f"Unsupported {method=}")
                if "Ventless" in row[opt_col]:
                    return dryer_elctric_ventless_power_rating
                return dryer_elctric_power_rating

    return 0


def _new_load_water_heating_oedi(row, option_columns):
    for opt_col in option_columns:
        if opt_col == "upgrade.water_heater_efficiency" and row[opt_col]: 
            if "Electric" in row[opt_col]: 
                if "Electric Tankless" in row[opt_col]:
                    if int(row[f"{bxm}.bedrooms"]) == 1:
                        return water_heater_electric_tankless_1bath_power_rating 
                    if int(row[f"{bxm}.bedrooms"]) in [2,3]:
                        return water_heater_electric_tankless_2bath_power_rating
                    if int(row[f"{bxm}.bedrooms"]) in [4,5]:
                        return water_heater_electric_tankless_3bath_power_rating
                    raise ValueError(f'Unsupported {row[f"{bxm}.bedrooms"]=}')
                if "Heat Pump" in row[opt_col]:
                    if "120V" in row[opt_col] or "120 V" in row[opt_col]:
                        return water_heater_heat_pump_120_power_rating
                    return water_heater_heat_pump_power_rating
                return water_heater_electric_power_rating

    return 0


def _new_load_space_conditioning_oedi(row, option_columns):
    # heating load
    heating_type = None
    secondary_heating_type = None
    backup_heating_type = None
    for opt_col in option_columns:
        if opt_col == "upgrade.hvac_heating_efficiency" and row[opt_col]: 
            heating_type = get_heating_type(row[opt_col])
        if opt_col == "upgrade.hvac_secondary_heating_efficiency" and row[opt_col]:
            secondary_heating_type = get_heating_type(row[opt_col])

    # TODO: this is not a fail-safe solution
    if heating_type == "Heat Pump":
        if "existing" in row[upg_name].lower(): # TODO
            backup_heating_type = get_heating_type(row[f"{bxm}.hvac_heating_efficiency"])
        else:
            backup_heating_type = "Electric Resistance"

    heating_cols = [
        row[f"{upgc}.size_heating_system_primary_k_btu_h"],
        row[f"{upgc}.size_heating_system_secondary_k_btu_h"],
        row[f"{upgc}.size_heat_pump_backup_primary_k_btu_h"]
        ]
    system_cols = [
        heating_type,
        secondary_heating_type,
        backup_heating_type,
        ]

    heating_load = sum(
        [hvac_heating_conversion(x, system_type=y) for x, y in zip(heating_cols, system_cols)]
    )


    # cooling load
    cooling_type = None
    for opt_col in option_columns:
        if opt_col == "upgrade.hvac_cooling_efficiency" and row[opt_col]:
            cooling_type = get_cooling_type(row[opt_col])

    cooling_load = hvac_cooling_conversion(
        row[f"{upgc}.size_cooling_system_primary_k_btu_h"],
        system_type=cooling_type
    )

    # Add AHU
    heat_ahu, cool_ahu = _get_air_handlers(row, heating_type, secondary_heating_type)
    heating_load += heat_ahu
    cooling_load += cool_ahu

    return max(heating_load, cooling_load)


### -------- util funcs --------
def _get_heating_has_ducts(row) -> bool:
    return True if row[f"{bxm}.hvac_heating_type"] in ["Ducted Heat Pump", "Ducted Heating"] else False

def _get_cooling_has_ducts(row) -> bool:
    return True if row[f"{bxm}.hvac_cooling_type"] in ["Central AC", "Ducted Heat Pump"] else False

def _get_air_handlers(row, heating_type, secondary_heating_type) -> (float, float):
    """Typically you need more volume of air to cool the house than to heat it. 
    So the cooling requirements determine the size of the air handler. 
    However the air handler comes with the furnace. 
    So the air handler size determines the furnace size.

    Current logic: 
    - if gas furnace with CAC, use gas furnace (based on heat cap only, 120V)
    - if electric furnace with CAC, take max of heat/cool to determine AHU
    - if no ducted heating, use CAC (based on cool cap only)
    """
    if heating_type == "Heat Pump":
        if row[f"{bxm}.hvac_has_ducts"] == "Yes":
            cooling_has_ducts = heating_has_ducts = True
        else:
            cooling_has_ducts = heating_has_ducts = False
    else:
        heating_has_ducts = _get_heating_has_ducts(row)
        cooling_has_ducts = _get_cooling_has_ducts(row)

    heat_ahu, cool_ahu = 0, 0

    if heating_has_ducts:
        if heating_type == "fuel" or secondary_heating_type == "fuel":
            # if dual fuel, retain old 120V AHU
            heat_ahu = hvac_120V_air_handler(row[f"{upgc}.size_heating_system_primary_k_btu_h"])
        else:
            heat_ahu = hvac_240V_air_handler(row[f"{upgc}.size_heating_system_primary_k_btu_h"])

    if cooling_has_ducts:
        if heating_has_ducts:
            if heating_type == "fuel" or secondary_heating_type == "fuel":
                # gas furnace with CAC, use gas furnace
                cool_ahu = heat_ahu
            else:
                cool_ahu = heat_ahu = max(
                    heat_ahu, 
                    hvac_240V_air_handler(row[f"{upgc}.size_cooling_system_primary_k_btu_h"])
                    )
        else:
            cool_ahu = hvac_240V_air_handler(row[f"{upgc}.size_cooling_system_primary_k_btu_h"])

    return (heat_ahu, cool_ahu)


def get_cooling_type(cool_eff) -> Optional[str]:
    if "Room AC" in cool_eff:
        return "Room AC"
    if "AC" in cool_eff:
        return "Central AC"
    if "Heat Pump" in cool_eff:
        return "Heat Pump"
    if cool_eff in ["None", "Shared Cooling"]:
        return None
    if cool_eff == "Evaporative Cooler":
        raise ValueError(f"Unsupported: {cool_eff=}")
    raise ValueError("Unknown cooling type")
    

def get_heating_type(heat_eff) -> Optional[str]:
    if ("ASHP" in heat_eff) or ("MSHP" in heat_eff):
        return "Heat Pump"
    if ("Electric" in heat_eff):
        return "Electric Resistance"
    if ("GSHP" in heat_eff):
        raise ValueError(f"Unsupported: {heat_eff=}")
    if heat_eff in ["None", "Shared Heating"]:
        return None
    return "fuel"


def hvac_240V_air_handler(nom_cap) -> float:
    ahu_volt = get_nameplate_rating(nameplate_rating, 'space heating/cooling', 'electric air handler', parameter="voltage")
    amp_para = get_nameplate_rating(nameplate_rating, 'space heating/cooling', 'electric air handler', parameter="amperage").split(",")
    ahu_amp = max(float(amp_para[2]), float(amp_para[0])*float(nom_cap) + float(amp_para[1]))
    return ahu_volt * ahu_amp


def hvac_120V_air_handler(nom_cap) -> float:
    ahu_volt = get_nameplate_rating(nameplate_rating, 'space heating', 'fuel air handler', parameter="voltage")
    amp_para = get_nameplate_rating(nameplate_rating, 'space heating', 'fuel air handler', parameter="amperage").split(",")
    ahu_amp = max(float(amp_para[2]), float(amp_para[0])*float(nom_cap) + float(amp_para[1]))
    return ahu_volt * ahu_amp


def apply_va_linear_regression(nom_cap, load_category, appliance) -> float:
    volt = get_nameplate_rating(nameplate_rating, load_category, appliance, parameter="voltage")
    amp_para = get_nameplate_rating(nameplate_rating, load_category, appliance, parameter="amperage").split(",")
    amp = float(amp_para[0])*float(nom_cap) + float(amp_para[1])
    return volt * amp


def hvac_heating_conversion(nom_heat_cap, system_type=None) -> float:
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
    if system_type is None or system_type in ["None", "fuel"]:
        return 0

    nom_heat_cap = float(nom_heat_cap)
    if "Heat Pump" in system_type:
        return apply_va_linear_regression(nom_heat_cap, "space heating", "heat pump")
    if system_type == "Electric Resistance":
        return nom_heat_cap * KBTU_H_TO_W
    raise ValueError(f"Unknown {system_type=}")


def hvac_cooling_conversion(nom_cool_cap, system_type=None) -> float:
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
    if "Heat Pump" in system_type:
        return apply_va_linear_regression(nom_cool_cap, "space cooling", "heat pump")
    elif system_type == "Central AC":
        return apply_va_linear_regression(nom_cool_cap, "space cooling", "central ac")
    elif system_type == "Room AC":
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

    if df.index.name == bldg_id:
        df.reset_index(inplace=True)

    if sort_bldg_id:
        df = df.sort_values(by=bldg_id).reset_index(drop=True)

    return df


def bin_panel_sizes(df_column: pd.Series) -> pd.Series:
    df_out = df_column.copy()
    df_out.loc[df_column<100] = "<100"
    df_out.loc[(df_column>100) & (df_column<125)] = "101-124"
    df_out.loc[(df_column>125) & (df_column<200)] = "126-199"
    df_out.loc[df_column>200] = "200+"
    df_out = df_out.astype(str)

    return df_out



def generate_plots(df: pd.DataFrame, dfo: pd.DataFrame, output_dir: Path, sfd_only: bool = False, upgrade_num: str = ""):
    msg = " for Single-Family Detached only" if sfd_only else ""
    print(f"generating plots{msg}...")
    HC_list = [
        f"{bxm}.census_region",
        f"{bxm}.census_division",
        f"{bxm}.geometry_building_type_recs",  # dep
        f"{bxm}.state",
        # f"{bxm}.vintage",  # dep
        f"{bxm}.vintage_acs",
        f"{bxm}.federal_poverty_level",
        f"{bxm}.area_median_income",
        f"{bxm}.tenure",
        f"{bxm}.geometry_floor_area_bin",
        # f"{bxm}.geometry_floor_area",  # dep
        f"{bxm}.heating_fuel",  # dep
        f"{bxm}.water_heater_fuel",  # dep
        f"{bxm}.hvac_heating_type",
        f"{bxm}.hvac_cooling_type",  # dep
    ]
    dfo = dfo.join(df.set_index(bldg_id)[HC_list], on=bldg_id, how="left")
    upgrade_name = [x for x in dfo[upg_name].unique() if x not in [None, "", np.nan]][0]

    _plot_scatter(dfo, "amp_total_pre_upgrade_A_220_83", "amp_total_pre_upgrade_A_220_87", 
        title=f"{upgrade_name}\nPre-upgrade comparison", output_dir=output_dir, sfd_only=sfd_only, upgrade_num=upgrade_num)
    _plot_scatter(dfo, "amp_total_post_upgrade_A_220_83", "amp_total_post_upgrade_A_220_87", 
        title=f"{upgrade_name}\nPost-upgrade comparison", output_dir=output_dir, sfd_only=sfd_only, upgrade_num=upgrade_num)
    _plot_scatter(dfo, "amp_total_pre_upgrade_A_220_83", "amp_total_post_upgrade_A_220_83", 
        title=f"{upgrade_name}\nNEC 220.83", output_dir=output_dir, sfd_only=sfd_only, upgrade_num=upgrade_num)
    _plot_scatter(dfo, "amp_total_pre_upgrade_A_220_87", "amp_total_post_upgrade_A_220_87", 
        title=f"{upgrade_name}\nNEC 220.87", output_dir=output_dir, sfd_only=sfd_only, upgrade_num=upgrade_num)
    print("scatter plots completed.")
    for metric in [
        "amp_total_pre_upgrade_A_220_83", 
        "amp_total_pre_upgrade_A_220_87",
        "amp_total_post_upgrade_A_220_83", 
        "amp_total_post_upgrade_A_220_87",
        ]:
        for hc in HC_list:
            _plot_box(dfo, metric, hc, output_dir=output_dir, sfd_only=sfd_only, upgrade_num=upgrade_num)
    print(f"plots output to: {output_dir}")


def existing_load_labels() -> list[str]:
    existing_loads_labels = [
        "load_hvac",
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


def apply_existing_loads(row, method: str, check_completed_status: bool, n_kit: int = 2, n_ldr: int = 1) -> list[float]:
    """ Load summing method """
    if check_completed_status and row["completed_status"] != "Success":
        return [np.nan for x in range(15)]

    existing_loads = [
            _special_load_space_conditioning(row, check_completed_status), # max of heating or cooling
            _fixed_load_water_heater(row, check_completed_status),
            _special_load_dryer(row, method, check_completed_status),
            _special_load_cooking_range_oven(row, check_completed_status),
            _fixed_load_hot_tub_spa(row, check_completed_status),
            _special_load_pool_heater(row, check_completed_status),
            _special_load_evse(row, method, check_completed_status),

            _general_load_lighting(row, check_completed_status), # sqft
            _general_load_kitchen(row, check_completed_status, n=n_kit), # consider logic based on sqft
            _general_load_laundry(row, check_completed_status, n=n_ldr), # consider logic based on sqft (up to 2)
            _general_load_washer(row, check_completed_status),
            _fixed_load_dishwasher(row, check_completed_status),
                _fixed_load_garbage_disposal(row, check_completed_status)+
                # _fixed_load_garbage_compactor(row, check_completed_status)+
                _fixed_load_garage_door(row, check_completed_status)+
                _fixed_load_ventilations(row, check_completed_status),
            _fixed_load_well_pump(row, check_completed_status),
            _special_load_pool_pump(row, check_completed_status),
            
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


def calculate_new_loads(df: pd.DataFrame, dfu: pd.DataFrame, method: str, check_completed_status: bool, result_as_map: bool = False)-> pd.DataFrame:
    ## apply new load
    # 1 add necessary baseline HC
    HC_list = [
        f"{bxm}.hvac_heating_type",
        f"{bxm}.hvac_cooling_type",
        f"{bxm}.hvac_has_ducts",
        f"{bxm}.bedrooms",
        f"{bxm}.geometry_building_type_recs",
        f"{bxm}.hvac_heating_efficiency",
    ]
    HC_list = [x for x in HC_list if x not in dfu]
    new_load_cols = [x for x in dfu.columns if "new_load" in x]
    df_up = dfu.drop(columns=new_load_cols).copy()
    if HC_list:
        df_up = df_up.join(df.set_index([bldg_id])[HC_list], on=[bldg_id], how="left")

    # 2 obtain valid list of upgrade option columns
    option_columns = [x for x in dfu.columns if x.startswith(f"{upgc}.option") and x.endswith("name")]
    option_cols = []
    upgrade_options = []
    for opt_col in option_columns:
        upgrade_option = [x for x in dfu[opt_col].unique() if x != "" and not pd.isna(x)]
        if upgrade_option:
            assert len(upgrade_option) == 1, f"{upgrade_option=} has more than one option."
            option_cols.append(opt_col)
            upgrade_options.append(upgrade_option[0])

    # 3 convert upgrade options to nameplate power ratings
    # [1] Heating and cooling
    df_up["new_load_hvac"] = df_up.apply(lambda x: _new_load_space_conditioning(x, option_cols, check_completed_status), axis=1)

    # [2] Water heating
    wh_option_cols, _ = get_upgrade_columns_and_options(option_cols, upgrade_options, "Water Heater Efficiency")
    df_up["new_load_water_heater"] = df_up.apply(lambda x: _new_load_water_heating(x, wh_option_cols, check_completed_status), axis=1)

    # [3] Appliances
    dryer_option_cols, _ = get_upgrade_columns_and_options(option_cols, upgrade_options, "Clothes Dryer")
    df_up["new_load_dryer"] = df_up.apply(lambda x: _new_load_dryer(x, dryer_option_cols, method, check_completed_status), axis=1)

    cooking_option_cols, _ = get_upgrade_columns_and_options(option_cols, upgrade_options, "Cooking Range")
    df_up["new_load_range_oven"] = df_up.apply(lambda x: _new_load_range_oven(x, cooking_option_cols, check_completed_status), axis=1)

    hot_tub_spa_option_cols, _ = get_upgrade_columns_and_options(option_cols, upgrade_options, "Misc Hot Tub Spa")
    df_up["new_load_hot_tub_spa"] = df_up.apply(lambda x: _new_load_hot_tub_spa(x, hot_tub_spa_option_cols, check_completed_status), axis=1)

    pool_heater_option_cols, _ = get_upgrade_columns_and_options(option_cols, upgrade_options, "Misc Pool Heater")
    df_up["new_load_pool_heater"] = df_up.apply(lambda x: _new_load_pool_heater(x, pool_heater_option_cols, check_completed_status), axis=1)

    ev_option_cols, _ = get_upgrade_columns_and_options(option_cols, upgrade_options, "Electric Vehicle")
    if not ev_option_cols:
        ev_option_cols, _ = get_upgrade_columns_and_options(option_cols, upgrade_options, "Electric Vehicle Charger")
    df_up["new_load_evse"] = df_up.apply(lambda x: _new_load_evse(x, ev_option_cols, method, check_completed_status), axis=1)

    # Project-specific: add EV load explicitly (for part II of TEA)
    if EVSE_level == 0:
        print("No EVSE postprocessing")
    # if EVSE_level == 1 and method == "87":
    if EVSE_level == 1:
        print(f"Adding {EVSE_level=} for {method=}")
        cond = df_up[f"{bxm}.geometry_building_type_recs"].isin([
            "Single-Family Detached",
            "Single-Family Attached",
            "Mobile Home",
            ])
        df_up.loc[cond, "new_load_evse"] = EVSE_power_rating_level1
    if EVSE_level == 2:
        print(f"Adding {EVSE_level=} for {method=}")
        cond = df_up[f"{bxm}.geometry_building_type_recs"].isin([
            "Single-Family Detached",
            "Single-Family Attached",
            "Mobile Home",
            ])
        df_up.loc[cond, "new_load_evse"] = EVSE_power_rating_level2
    if EVSE_level not in [0, 1, 2]:
        raise ValueError(f"Unsupported {EVSE_level=}")

    # Nullify 0 values
    new_load_cols = [x for x in df_up.columns if "new_load" in x]
    df_up[new_load_cols] = df_up[new_load_cols].replace(0, np.nan)

    if result_as_map:
        df_up = df_up[[bldg_id] + new_load_cols]
    else:
        df_up = df_up.drop(columns=HC_list)

    return df_up


def calculate_new_loads_oedi(df: pd.DataFrame, dfu: pd.DataFrame, method: str, result_as_map: bool = False)-> pd.DataFrame:
    ## apply new load
    # 1 add necessary baseline HC
    HC_list = [
        f"{bxm}.hvac_heating_type",
        f"{bxm}.hvac_cooling_type",
        f"{bxm}.hvac_has_ducts",
        f"{bxm}.bedrooms",
        f"{bxm}.geometry_building_type_recs",
        f"{bxm}.hvac_heating_efficiency",
    ]
    HC_list = [x for x in HC_list if x not in dfu]
    new_load_cols = [x for x in dfu.columns if "new_load" in x]
    df_up = dfu.drop(columns=new_load_cols).copy()
    if HC_list:
        df_up = df_up.join(df.set_index([bldg_id])[HC_list], on=[bldg_id], how="left")

    # 2 obtain valid list of upgrade option columns
    option_cols = [x for x in dfu.columns if x.startswith(f"upgrade.")]

    # 3 convert upgrade options to nameplate power ratings
    # [1] Heating and cooling
    hvac_cols = [
        "upgrade.hvac_cooling_efficiency", 
        "upgrade.hvac_heating_efficiency", 
        "upgrade.hvac_secondary_heating_efficiency",
        ]
    df_up["new_load_hvac"] = df_up.apply(lambda x: _new_load_space_conditioning_oedi(x, option_cols), axis=1)

    # [2] Water heating
    df_up["new_load_water_heater"] = df_up.apply(lambda x: _new_load_water_heating_oedi(x, option_cols), axis=1)

    # [3] Appliances
    df_up["new_load_dryer"] = df_up.apply(lambda x: _new_load_dryer_oedi(x, option_cols, method), axis=1)
    df_up["new_load_range_oven"] = df_up.apply(lambda x: _new_load_range_oven_oedi(x, option_cols), axis=1)
    df_up["new_load_hot_tub_spa"] = df_up.apply(lambda x: _new_load_hot_tub_spa_oedi(x, option_cols), axis=1)
    df_up["new_load_pool_heater"] = df_up.apply(lambda x: _new_load_pool_heater_oedi(x, option_cols), axis=1)
    df_up["new_load_evse"] = df_up.apply(lambda x: _new_load_evse_oedi(x, option_cols, method), axis=1)

    # Project-specific: add EV load explicitly (for part II of TEA)
    if EVSE_level == 0:
        print("No EVSE postprocessing")
    # if EVSE_level == 1 and method == "87":
    if EVSE_level == 1:
        print(f"Adding {EVSE_level=} for {method=}")
        cond = df_up[f"{bxm}.geometry_building_type_recs"].isin([
            "Single-Family Detached",
            "Single-Family Attached",
            "Mobile Home",
            ])
        df_up.loc[cond, "new_load_evse"] = EVSE_power_rating_level1
    if EVSE_level == 2:
        print(f"Adding {EVSE_level=} for {method=}")
        cond = df_up[f"{bxm}.geometry_building_type_recs"].isin([
            "Single-Family Detached",
            "Single-Family Attached",
            "Mobile Home",
            ])
        df_up.loc[cond, "new_load_evse"] = EVSE_power_rating_level2
    if EVSE_level not in [0, 1, 2]:
        raise ValueError(f"Unsupported {EVSE_level=}")

    # Nullify 0 values
    new_load_cols = [x for x in df_up.columns if "new_load" in x]
    df_up[new_load_cols] = df_up[new_load_cols].replace(0, np.nan)

    if result_as_map:
        df_up = df_up[[bldg_id] + new_load_cols]
    else:
        df_up = df_up.drop(columns=HC_list)

    return df_up


def get_upgrade_columns_and_options(option_columns, upgrade_options, parameter):
    columns = [] # 'upgrade_costs.option_<>_name'
    options = [] # e.g., 'ASHP, SEER 15, 9.0 HSPF' if parameter = 'HVAC Heating Efficiency'
    for col, upgrade_option in zip(option_columns, upgrade_options):
        if parameter in upgrade_option:
            options.append(upgrade_option.split("|")[1])
            columns.append(col)

    return columns, options


### -------- load method calcs --------
def calculate_new_load_total_220_83(dfi: pd.DataFrame, dfu: pd.DataFrame, n_kit: int = 2, n_ldr: int = 1, explode_result: bool = False, result_as_map: bool = False, oedi_data_format: bool = False) -> pd.DataFrame:
    """
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
    if oedi_data_format:
        check_completed_status = False
    else:
        check_completed_status = True

    print("Performing NEC 220.83 (load-summing) calculations...")
    df = dfi.copy()

    ## New loads
    if oedi_data_format:
        df_new = calculate_new_loads_oedi(df, dfu, "83", result_as_map=True)
    else:
        df_new = calculate_new_loads(df, dfu, "83", check_completed_status, result_as_map=True)

    new_loads = [x for x in df_new.columns if "new_load" in x]
    # df_new_backup = dfu.apply(lambda x: _special_load_heat_pump_backup(x), axis=1).rename("new_load_hvac_hp_backup_83")

    # Existing loads
    existing_loads = existing_load_labels()
    df_existing = pd.DataFrame(
        df.apply(lambda x: apply_existing_loads(x, "83", check_completed_status, n_kit=n_kit, n_ldr=n_ldr), axis=1).to_list(),
        index = df.index, columns=existing_loads
        )

    df_loads = df_existing.copy() # for i/o accounting
    # df_backup = df.apply(lambda x: _special_load_heat_pump_backup(x), axis=1).rename("load_hvac_hp_backup")

    # Total pre-upgrade load based on no new hvac
    total_load_pre = "load_total_pre_upgrade_VA_220_83"
    total_amp_pre = "amp_total_pre_upgrade_A_220_83"
    df_existing[total_load_pre] = df_existing.apply(lambda x: apply_total_load_220_83(x, has_new_hvac_load=False), axis=1)
    df_existing[total_amp_pre] = df_existing[total_load_pre] / 240

    # remove upgraded loads from existing loads and replace with new loads
    upgradable_loads = [x.removeprefix("new_") for x in new_loads]
    df_upgraded = df_new[new_loads].rename(columns=dict(zip(new_loads, upgradable_loads)))
    cond_upgraded = df_upgraded>0
    loads_upgraded = cond_upgraded.apply(lambda x: list(x[x].index), axis=1).rename("loads_upgraded_83") # record which loads are upgraded
    # replace where upgraded with nan then update with new loads
    df_change = df_loads[upgradable_loads].mask(cond_upgraded)
    df_change.update(df_upgraded, overwrite=False)
    df_loads[upgradable_loads] = df_change

    # QC
    diff = df_existing[existing_loads].compare(df_loads)
    assert len(diff) > 0, "No difference between existing loads and updated loads"

    # Total post-upgrade load based on whether has new hvac
    total_load_post = "load_total_post_upgrade_VA_220_83"
    total_amp_post = "amp_total_post_upgrade_A_220_83"
    new_hvac = (df_new["new_load_hvac"]>0).rename("upgrade_has_new_hvac")
    df_loads.loc[new_hvac, total_load_post] = df_loads.loc[new_hvac].apply(lambda x: apply_total_load_220_83(x, has_new_hvac_load=True), axis=1)
    df_loads.loc[~new_hvac, total_load_post] = df_loads.loc[~new_hvac].apply(lambda x: apply_total_load_220_83(x, has_new_hvac_load=False), axis=1)
    df_loads[total_amp_post] = df_loads[total_load_post] / 240

    df_result = pd.concat([
        df_new[bldg_id],
        dfu[upg_name],
        new_hvac,
        df_existing,
        # df_backup,
        loads_upgraded,
        df_new[new_loads].rename(columns=lambda x: x+"_83"),
        # df_new_backup,
        df_loads[[total_load_post, total_amp_post]],
        ], axis=1)

    if explode_result:
        cols = df_result.columns
    else:
        cols = [bldg_id, upg_name, total_load_pre, total_amp_pre, total_load_post, total_amp_post]

    if result_as_map:
        return df_result[cols]

    return dfu.join(df_result[cols].drop(columns=[upg_name]).set_index(bldg_id), on=bldg_id)


def calculate_new_load_total_220_87(df: pd.DataFrame, dfu: pd.DataFrame, explode_result: bool = False, result_as_map: bool = False, oedi_data_format: bool = False) -> pd.DataFrame:
    """ Maximum demand method 
        - "report_simulation_output.peak_electricity_annual_total_w": timestep -- not available in EUSS RR1
        - "qoi_report.qoi_hourly_peak_magnitude_use_kw": peak of hourly aggregates, different from above
        - EUSS RR1 uses "qoi_report.qoi_peak_magnitude_use_kw"
    """
    if oedi_data_format:
        check_completed_status = False
    else:
        check_completed_status = True

    print("Performing NEC 220.87 (max-load) calculations...")

    # New Loads
    if oedi_data_format:
        df_new = calculate_new_loads_oedi(df, dfu, "87", result_as_map=True)
    else:
        df_new = calculate_new_loads(df, dfu, "87", check_completed_status, result_as_map=True)

    new_loads = [x for x in df_new.columns if "new_load" in x]
    # df_new_backup = dfu.apply(lambda x: _special_load_heat_pump_backup(x), axis=1).rename("new_load_hvac_hp_backup_87")

    # record loads upgraded
    upgradable_loads = [x.removeprefix("new_") for x in new_loads]
    df_upgraded = df_new[new_loads].rename(columns=dict(zip(new_loads, upgradable_loads)))
    cond_upgraded = df_upgraded>0
    loads_upgraded = cond_upgraded.apply(lambda x: list(x[x].index), axis=1).rename("loads_upgraded_87") # record which loads are upgraded
    df_new = pd.concat([loads_upgraded, df_new], axis=1) # exclude df_new_backup

    # Total pre-upgrade load
    total_load_pre = "load_total_pre_upgrade_VA_220_87"
    total_amp_pre = "amp_total_pre_upgrade_A_220_87"
    if oedi_data_format:
        peak_cols = ["out.electricity.summer.peak.kw", "out.electricity.winter.peak.kw"]
        df[total_load_pre] = df[peak_cols].astype(float).max(axis=1) * 1000 * 1.25 # VA
    else:
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

    df.loc[df[f"{bxm}.vacancy_status"]=="Vacant", total_load_pre] = np.nan
    df[total_amp_pre] = df[total_load_pre] / 240 # amp


    ## Total post-upgrade load 
    total_load_post = "load_total_post_upgrade_VA_220_87"
    total_amp_post = "amp_total_post_upgrade_A_220_87"
    cols = [
        bldg_id,
        total_load_pre,
        total_amp_pre,
    ]
    df_new = df[cols].join(
        df_new.set_index([bldg_id]), on=[bldg_id], how="right"
        )

    df_new["new_load_total_VA_220_87"] = df_new[new_loads].sum(axis=1)
    df_new[total_load_post] = df_new[total_load_pre] + df_new["new_load_total_VA_220_87"]
    df_new[total_amp_post] = df_new[total_load_post] / 240

    df_new = df_new.rename(columns={k:k+"_87" for k in new_loads})
    if explode_result:
        cols = df_new.columns # include new loads
    else:
        cols = [bldg_id, total_load_pre, total_amp_pre, total_load_post, total_amp_post]

    if result_as_map:
        return df_new[cols]

    return dfu.join(df_new[cols].set_index(bldg_id), on=bldg_id)


def assign_garbage_disposal(df):
    """ Garbage disposal was invented in 1938 (Insinkable) and is in 52% of homes as of 2013 (AHS) """
    n_samples = round(len(df)*0.52)
    df["has_garbage_disposal"] = False
    cond = df[f"{bxm}.vintage_acs"]!="<1940"
    selected = df.loc[cond, bldg_id].sample(n=n_samples, random_state=1)
    cond = df[bldg_id].isin(selected)
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
    cond = df[f"{bxm}.geometry_building_type_recs"]=="Multi-Family with 5+ Units"
    df.loc[cond, f"{bxm}.misc_well_pump"] = "None"

    return df


def main(
    baseline_filename: str | None = None, 
    upgrade_filename: str | None = None, 
    plot: bool = False, 
    sfd_only: bool = False, 
    explode_result: bool = False, 
    result_as_map: bool = False,
    oedi_data_format: bool = False,
    ):
    global bldg_id, bxm, upgc, upg_name, floor_area, EVSE_level

    # Currently it's set up such that both 83 and 87 accounts for L1 charging
    EVSE_level = 0 # <--- 0, 1, 2

    if oedi_data_format:
        bldg_id = "bldg_id"
        bxm = "in"
        upgc = "out.params"
        upg_name = "upgrade_name"
        floor_area = "out.params.floor_area_lighting_ft_2"

    else:
        bldg_id = "building_id"
        bxm = "build_existing_model"
        upgc = "upgrade_costs"
        upg_name = "apply_upgrade.upgrade_name"
        floor_area = f"{upgc}.floor_area_conditioned_ft_2"
        

    if baseline_filename is None:
        baseline_filename = (
            Path(__file__).resolve().parent
            / "test_data"
            / "euss1_2018_results_up00_100.csv" # "euss1_2018_results_up00_400plus.csv"
        )
    else:
        baseline_filename = Path(baseline_filename)


    if upgrade_filename is None:
        upgrade_filename = (
            Path(__file__).resolve().parent
            / "test_data"
            / "euss1_2018_results_up07_100.csv" # min-eff electrification package
        )
    else:
        upgrade_filename = Path(upgrade_filename)

    output_filedir = upgrade_filename.parent / "nec_calculations"
    output_filedir.mkdir(parents=True, exist_ok=True) 
    ext = ""
    if explode_result:
        ext = "_exploded"
    if result_as_map:
        output_filename = output_filedir / (upgrade_filename.stem.split(".")[0] + f"__res_map__nec_new_load{ext}" + upgrade_filename.suffix)
    else:
        output_filename = output_filedir / (upgrade_filename.stem.split(".")[0] + f"__nec_new_load{ext}" + upgrade_filename.suffix)

    upgrade_num = [x for x in 
        list(chain(*[x.split(".") for x in upgrade_filename.stem.split("_")]))
        if "up" in x][0]
    plot_dir_name = f"plots_sfd" if sfd_only else f"plots"
    output_dir = upgrade_filename.parent / plot_dir_name / "nec_calculations" / upgrade_num
    output_dir.mkdir(parents=True, exist_ok=True) 

    plot_later = False
    if plot:
        if not output_filename.exists():
            plot_later = True
        else:
            df = read_file(baseline_filename, compression="infer", low_memory=False)
            dfo = read_file(output_filename, low_memory=False)
            for col in [ 
                "amp_total_pre_upgrade_A_220_83",  
                "amp_total_pre_upgrade_A_220_87",
                "amp_total_post_upgrade_A_220_83",  
                "amp_total_post_upgrade_A_220_87",
            ]:
                dfo[col] = dfo[col].replace("", np.nan).astype(float)
            generate_plots(df, dfo, output_dir, sfd_only=sfd_only, upgrade_num=upgrade_num)
            sys.exit()
    
    if oedi_data_format and (baseline_filename.suffix != ".parquet" or upgrade_filename.suffix != ".parquet"):
        msg = "For OEDI data format, only parquet files are accepted."
        raise ValueError(msg)

    df = read_file(baseline_filename, compression="infer", low_memory=False, sort_bldg_id=True)
    dfu = read_file(upgrade_filename, compression="infer", low_memory=False, sort_bldg_id=True)
    assert bldg_id in df.columns, f"{bldg_id} column not in {baseline_filename}"
    assert bldg_id in dfu.columns, f"{bldg_id} column not in {upgrade_filename}"

    if not oedi_data_format:
        dfu = dfu[dfu["completed_status"]=="Success"].reset_index(drop=True)
        df = df[df["completed_status"]=="Success"].reset_index(drop=True)

    # Format
    columns = [x for x in df.columns if f"{bxm}" in x]
    df[columns] = df[columns].fillna("None")
    columns = [x for x in dfu.columns if x.startswith(f"{upgc}.option") and x.endswith("name")]
    dfu[columns] = dfu[columns].fillna("")

    # QC
    bldgs_no_bl = set(dfu[bldg_id]) - set(df[bldg_id])
    if bldgs_no_bl:
        print(f"WARNING: {len(bldgs_no_bl)} buildings have upgrade but no baseline: {bldgs_no_bl}")
    valid_bldgs = sorted(set(dfu[bldg_id]).intersection(set(df[bldg_id])))
    df = df[df[bldg_id].isin(valid_bldgs)].reset_index(drop=True)
    dfu = dfu[dfu[bldg_id].isin(valid_bldgs)].reset_index(drop=True)
    assert (dfu[bldg_id] == df[bldg_id]).prod() == 1, "Ordering of building_id does not match between upgrade and baseline"


    ## Assign garbage disposal to post-1940 homes randomly so ownership is 52% of dwelling units per 2013 AHS
    df = assign_garbage_disposal(df)

    ## Remove well pump from MF 5+
    df = fix_well_pump(df)

    # --- NEW LOAD calcs ---
    # NEC 220.83 - Load Summing Method
    # NEC 220.87 - Maximum Demand Method
    if result_as_map:
        df1 = calculate_new_load_total_220_83(df, dfu, n_kit=2, n_ldr=1, explode_result=explode_result, result_as_map=result_as_map, oedi_data_format=oedi_data_format)
        df2 = calculate_new_load_total_220_87(df, dfu, explode_result=explode_result, result_as_map=result_as_map, oedi_data_format=oedi_data_format)
        dfo = df1.join(df2.set_index(bldg_id), on=bldg_id)
    else:
        dfu1 = calculate_new_load_total_220_83(df, dfu, n_kit=2, n_ldr=1, explode_result=explode_result, oedi_data_format=oedi_data_format)
        dfo = calculate_new_load_total_220_87(df, dfu1, explode_result=explode_result, oedi_data_format=oedi_data_format)
    dfo = pd.concat([dfo, df["has_garbage_disposal"]], axis=1)

    # --- save to file ---
    if output_filename.suffix == ".csv":
        dfo.to_csv(output_filename, index=False)
    elif output_filename.suffix == ".parquet":
        dfo.to_parquet(output_filename)
    print(f"File output to: {output_filename}")

    if plot_later:
        generate_plots(df, dfo, output_dir, sfd_only=sfd_only, upgrade_num=upgrade_num)


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
        "upgrade_filename",
        action="store",
        default=None,
        nargs="?",
        help="Path to ResStock upgrade result file, e.g., results_up01.csv, "
        "defaults to test data: test_data/euss1_2018_results_up01_100.csv"
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
        "-o",
        "--oedi_data_format",
        action="store_true",
        default=False,
        help="Used to process Standard Dataset stored on OEDI, which has in.xxx format"
        "Default to processing normal ResStock run output, which has build_existing_model.xxx format. ",
    )

    args = parser.parse_args()
    if args.baseline_filename and not args.upgrade_filename:
        msg = "missing positional argument upgrade_filename, see --help"
        raise ValueError(msg)
    print("======================================================")
    print("New load calculation using 2023 NEC 220.83 and 220.87")
    print("======================================================")
    main(
        args.baseline_filename, args.upgrade_filename,
        plot=args.plot, sfd_only=args.sfd_only, explode_result=args.explode_result, result_as_map=args.result_as_map,
        oedi_data_format=args.oedi_data_format
        )
