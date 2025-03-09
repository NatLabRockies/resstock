"""
# https://github.nrel.gov/Customer-Modeling/ochre/blob/623a075cc9dd517336a1677ef96cb1a39e28486c/ochre/utils_equipment.py
Nomenclature:
    cap: capacity
    eir: energy input ratio (1/efficiency)
    t: temperature
    ff: flow fraction
    plr: partial load ratio
"""
import numpy as np
import pandas as pd
from pathlib import Path

ochre_dir = Path(".").resolve().parents[1] / "ochre" / "defaults"

file_cac = ochre_dir / "HVAC Cooling/Biquadratic Air Conditioner.csv"
bi_cac = pd.read_csv(file_cac).set_index(["Name"])

def calculate_derate(speed_idx, t_in, t_ext_db, biquad_params, flow_fraction=1, part_load_ratio=1):
    """ runs biquadratic equation for EIR or capacity given the speed index 
    return derate factor
    """

    params = biquad_params[speed_idx]
    
    # use coil input wet bulb for cooling, dry bulb for heating; ambient dry bulb for both
    # t_in = self.coil_input_db if self.is_heater else self.coil_input_wb # use input_db if heating else input_wb
    # t_ext_db = self.current_schedule['Ambient Dry Bulb (C)']

    # clip temperatures, flow fraction, part load ratio to stay within bounds
    if "min_Twb" in params.index:
        t_in = min(max(t_in, params['min_Twb']), params['max_Twb'])
    if "min_Tdb" in params.index:
        t_ext_db = min(max(t_ext_db, params['min_Tdb']), params['max_Tdb'])
    if "min_ff" in params.index:
        flow_fraction = min(max(flow_fraction, params['min_ff']), params['max_ff'])

    # create vectors based on temperature, flow fraction, and plr
    
    param = "cap" # cap or eir

    t_list = np.array([1, t_in, t_in ** 2, t_ext_db, t_ext_db ** 2, t_in * t_ext_db], dtype=float)
    t_param = get_biquadratic_params("cap_t", params)
    t_ratio = np.dot(t_list, t_param)

    ff_list = np.array([1, flow_fraction, flow_fraction ** 2], dtype=float)
    ff_param = get_biquadratic_params("cap_ff", params)
    ff_ratio = np.dot(ff_list, ff_param)

    plf_list = np.array([1, part_load_ratio, part_load_ratio ** 2], dtype=float)
    plf_param = get_biquadratic_params("cap_plr", params)
    if len(plf_param) == 0:
        plf_ratio = 1
    else:
        plf_ratio = np.dot(plf_list, plf_param)
    if "min_plf" in params.index:
        plf_ratio = min(max(plf_ratio, params['min_plf']), params['max_plf'])

    return t_ratio * ff_ratio / plf_ratio

def get_biquadratic_params(type_idx, params):
    coeff = ["a", "b", "c", "d", "e", "f"]
    para = [params.get(f"{x}_{type_idx}", None) for x in coeff]
    para = [x for x in para if x is not None]
    return np.array(para, dtype=float)


adjustment = calculate_derate("Single_1", 14, 30, bi_cac, flow_fraction=1, part_load_ratio=1)
print(adjustment)
