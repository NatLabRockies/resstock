import pandas as pd
import numpy as np
''' _hvac_delivered_to_nameplate_
take EIR as input?

efficiency metric conversions:
    EIR = 1/COP (definition)
    COP = EER/3.41214 (exact)
    EER = 0.875*SEER (estimate)
    EER = -0.02*SEER^2 + 1.12*SEER (better estimate)

    ** Note: utils_equipment assumes EER = SEER = HSPF 

number of speeds:
    Multi-split heat pump: always variable speed
    SEER <= 15 : assume single speed
    15 < SEER <= 21 : assume two speed
    21 < SEER: assume variable speed


'''


# _hvac_delivered_to_nameplate_: 
# Input:
# - delivered capacity (Btu/hour)
# - efficiency rating (EIR)
# - speed_idx ('single speed', 'two speed', or 'variable speed')
# - biquad params (dataframe with biquadratic parameters)
# - weather file location (str)
# - heating setpoint (float)
# - cooling setpoint (float)


h_set_pt = row['building_existing_model.heating_setpoint']
c_set_pt = row['building_existing_model.cooling_setpoint']

def _hvac_delivered_to_nameplate_(delivered_capacity, eff_rating, speed_opts,
                                   biquad_params, weather_file_loc, h_set_pt,
                                   c_set_pt, is_heating):
    design_conds = pd.read_csv('C:/Users/iupfal/restock/Electrical_Panels_EUSS')

    match speed_opts:
        case 'single speed':
            speed_idx = 'Single_1'
        case 'two speed':
            speed_idx = 'Double 2'
        case 'variable speed':
            speed_idx = 'Variable 4'

    t_set = h_set_pt if is_heating else c_set_pt # setpoint temperature
    t_otdr = design_conds[ # outdoor air temperature
        'Heating Dry Bulb Temperature 99%'][weather_file_loc] if is_heating else design_conds[
        'Cooling Dry Bulb Temperature 1%'][weather_file_loc]
    t_list = np.array([1, t_otdr, t_otdr ** 2, t_set, t_set ** 2, t_otdr * t_set], dtype=float)
    t_ratio = np.dot(biquad_params[speed_idx],t_list)
    return delivered_capacity*(eff_rating/t_ratio)