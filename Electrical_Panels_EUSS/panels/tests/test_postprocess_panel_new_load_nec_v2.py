"""
test results from postprocess_panel_new_load_nec_v2.py for all upgrades and revisions, with and without EVSE load, and with expected output file generated from postprocess_panel_new_load_nec__all_upgrades_v2.py
"""

from pathlib import Path
import sys
from tabnanny import check
from typing import Literal
import pandas as pd
import numpy as np

sys.path.append(str(Path(__file__).parents[2]))
from panels.postprocess_panel_new_load_nec_v2 import apply_demand_factor


def test_all_upgrades(filedir):
    filedir = Path(filedir)
    list_garbage_disposal = []
    files = sorted([x for x in sorted(filedir.glob("*results_up*"))])

    if len(files) == 0:
        raise ValueError(f"No files found in {filedir}")
    
    for file in files:
        upg = file.stem[10:12]
        print(f"Testing {upg}...")

        # if int(upg) < 10:
        #     continue

        # if int(upg) > 1:
        #     continue

        if file.suffix == ".csv":
            df = pd.read_csv(file)
        elif file.suffix == ".parquet":
            df = pd.read_parquet(file)
        else:
            raise ValueError(f"Unsupported file type: {file.suffix}")
        assert not df.empty, f"{file} is empty."

        if upg in ["01", "02", "04", "08", "09", "11", "15"]:
            check_water_heater_load(df, type="er")
            check_cooking_load(df, low_power=False)
            check_dryer_load(df, low_power=False)
        elif upg in ["03", "05", "10", "12"]:
            check_water_heater_load(df, type="240v_hpwh")
            check_cooking_load(df, low_power=False)
            check_dryer_load(df, low_power=False)
        elif upg in ["06", "07", "13", "14"]:
            check_water_heater_load(df, type="120v_hpwh")
            check_cooking_load(df, low_power=True)
            check_dryer_load(df, low_power=True)
        elif upg in ["16", "17", "18", "19"]:
            check_water_heater_load(df, type="120v_hpwh")
            check_dryer_load(df, low_power=True)

        if "no_ev" in filedir.name:
            check_ev_load(df, level=0)
        elif "ev_level1" in filedir.name:
            check_ev_load(df, level=1)
        elif "ev_level2" in filedir.name:
            check_ev_load(df, level=2)
        else:
            raise ValueError(f"Unsupported {filedir=}")

        # tests
        _test_existing_calculation(df)
        _test_83_calculation(df)
        _test_87_calculation(df)
        _test_amp_to_load(df)

        print(f"{upg}: passed all tests.")

        ## record garbage disposal
        list_garbage_disposal.append(df.set_index("building_id")["has_garbage_disposal"].rename(upg))

        
    # check garbage disposal across upgrades
    df_garbage_disposal = pd.concat(list_garbage_disposal, axis=1)
    diff_garbage_disposal = df_garbage_disposal.nunique(axis=1)
    assert (diff_garbage_disposal == 1).all(), f"garbage disposal status changed across upgrades for some buildings: {df_garbage_disposal[diff_garbage_disposal > 1]}"
    print("Garbage disposal status is consistent across upgrades for all buildings.")


def get_values(column):
    return set(column.dropna().unique())


def check_water_heater_load(df, type: Literal["120v_hpwh", "240v_hpwh", "er"]):
    match type:
        case "120v_hpwh":
            assert get_values(df["new_load_water_heater_83"]) == get_values(df["new_load_water_heater_87"]) == {1000} # HP, 120V, shared
        case "240v_hpwh":
            assert get_values(df["new_load_water_heater_83"]) == get_values(df["new_load_water_heater_87"]) == {4500} # HP, 240V
        case "er":
            # ER storage and tankless
            assert get_values(df["new_load_water_heater_83"]) == get_values(df["new_load_water_heater_87"]) == {4500, 18000, 24000, 36000}
        case _:
            raise ValueError(f"Unsupported {type=}")
        

def check_dryer_load(df, low_power):
    if low_power:
        assert get_values(df["new_load_dryer_83"]) == set()
        assert get_values(df["new_load_dryer_87"]) == {996} # HP, 120V
    else:
        assert get_values(df["new_load_dryer_83"]) == get_values(df["new_load_dryer_87"]) == {5760} # ER, 240V


def check_cooking_load(df, low_power):
    if low_power:
        assert get_values(df["new_load_range_oven_83"]) == get_values(df["new_load_range_oven_87"]) == {1800} # ER, 120V
    else:
        assert get_values(df["new_load_range_oven_83"]) == get_values(df["new_load_range_oven_87"]) == {12000} # ER, 240V
        

    
def check_ev_load(df, level: Literal[0,1,2]):
    if level == 0:
        assert get_values(df["new_load_evse_83"]) == get_values(df["new_load_evse_87"]) == set()
    elif level == 1:
        assert get_values(df["new_load_evse_83"]) == get_values(df["new_load_evse_87"]) == {1650}
    elif level == 2:
        assert get_values(df["new_load_evse_83"]) == get_values(df["new_load_evse_87"]) == {7680}
    else:
        raise ValueError(f"Unsupported {level=}")
    

def get_total_gross_load(x, threshold=8000):
    """ Reverse of demand factor calculation
    y = total_gross_load
    x = total_load
    x = (
        1 * min(threshold, y) +
        0.4 * max(0, y - threshold)
    )  # apply_demand_factor()

    y = (x - threshold) / 0.4 + threshold if x > threshold else x
    """
    if x > threshold:
        return (x - threshold) / 0.4 + threshold
    else:
        return x


def _test_amp_to_load(df):
    amp_cols = [col for col in df.columns if col.startswith(f"amp_total_")]
    for amp_col in amp_cols:
        load_col = amp_col.replace("amp_total_", "load_total_").replace("_A_", "_VA_")
        assert np.isclose(df[amp_col].fillna(0)*240, df[load_col].fillna(0), atol=1e-2).all()


def _test_existing_calculation(df):
    load_cols = [col for col in df.columns if col.startswith("load_")]
    existing_load_cols = [col for col in load_cols if col not in ["load_heating", "load_cooling"] and "upgrade" not in col] 
    gross_load1 = df[existing_load_cols].sum(axis=1)
    gross_load2 = df["load_total_pre_upgrade_VA_220_83"].apply(get_total_gross_load)
    assert np.isclose(gross_load1, gross_load2, atol=1e-2).all()


def _test_83_calculation(df):
    # check upgrade_has_new_hvac
    assert set(df.loc[df["new_load_hvac_83"] > df["load_hvac"], "upgrade_has_new_hvac"].unique()) == {True}
    assert set(df.loc[df["new_load_hvac_83"] <= df["load_hvac"], "upgrade_has_new_hvac"].unique()) == {False}

    new_load_cols = [col for col in df.columns if col.startswith("new_load_") and "83" in col]
    non_hvac_new_load_cols = [col for col in new_load_cols if col not in ["new_load_heating_83", "new_load_cooling_83", "new_load_hvac_83"]]
    non_hvac_ext_load_cols = [col.removeprefix("new_").removesuffix("_83") for col in non_hvac_new_load_cols]
    loads_upgraded = df["loads_upgraded_83"].astype(str)

    # check loads_upgraded for non-hvac loads:
    for col in non_hvac_new_load_cols:
        label = col.removeprefix("new_").removesuffix("_83")
        cond = loads_upgraded.str.contains(label)
        assert df.loc[cond, col].isna().sum() == 0
        assert (~df.loc[~cond, col].isna()).sum() == 0
    
    # check loads_upgraded for hvac load:
    # load can stay the same even if equipment has changed
    cond = ~loads_upgraded.str.contains("load_hvac")
    assert set(df.loc[cond, "upgrade_has_new_hvac"].unique()) == {False}

    # check loads_upgraded for hvac and post-upgrade load
    gross_load = df["load_total_pre_upgrade_VA_220_83"].apply(get_total_gross_load)

    # from pre-upgrade gross load, subtract old non-hvac load, add new non-hvac load
    df_non_hvac = df[non_hvac_new_load_cols].rename(columns=dict(zip(non_hvac_new_load_cols, non_hvac_ext_load_cols)))
    df_non_hvac_new = df_non_hvac.fillna(0).sum(axis=1)
    df_non_hvac_old = df[non_hvac_ext_load_cols][~df_non_hvac.isna()].fillna(0).sum(axis=1)
    gross_load_adj = gross_load - df_non_hvac_old + df_non_hvac_new 

    # 1. check those without new HVAC
    cond = df["upgrade_has_new_hvac"] == False
    total_load1 = (gross_load_adj.loc[cond] - df.loc[cond, "load_hvac"].fillna(0) + df.loc[cond, "new_load_hvac_83"].fillna(0)).apply(apply_demand_factor)
    total_load2 = df.loc[cond, "load_total_post_upgrade_VA_220_83"]
    assert np.isclose(total_load1, total_load2, atol=1e-2).all()

    # 2. check those with new HVAC
    cond = df["upgrade_has_new_hvac"] == True
    total_load1 = (gross_load_adj.loc[cond] - df.loc[cond, "load_hvac"].fillna(0)).apply(apply_demand_factor) + df.loc[cond, "new_load_hvac_83"].fillna(0)
    total_load2 = df.loc[cond, "load_total_post_upgrade_VA_220_83"]
    assert np.isclose(total_load1, total_load2, atol=1e-2).all()


def sum_87_loads(row):
    """row-based operation (slow)"""
    loads_upgraded = row["loads_upgraded_87"]
    new_load_cols = ["new_"+col+"_87" for col in loads_upgraded]
    return row[new_load_cols].sum()

def sum_87_loads_vector(df, columns):
    """Vectorized: sum new_load columns based on per-row loads_upgraded_87 list."""

    total = pd.Series(0.0, index=df.index)
    for col in columns:
        label = col.removeprefix("new_").removesuffix("_87")
        mask = df["loads_upgraded_87"].apply(lambda x: label in x)
        total += df[col].fillna(0) * mask

    return total

def _test_87_calculation(df):
    # check post-upgrade load
    new_load_cols = [col for col in df.columns if col.startswith("new_load_") and "87" in col]
    non_hvac_new_load_cols = [col for col in new_load_cols if col not in ["new_load_heating_87", "new_load_cooling_87", "new_load_hvac_87", "new_load_total_VA_220_87"]]
    loads_upgraded = df["loads_upgraded_87"].astype(str)

    # check loads_upgraded for non-hvac loads
    for col in non_hvac_new_load_cols:
        label = col.removeprefix("new_").removesuffix("_87")
        cond = loads_upgraded.str.contains(label)
        assert df.loc[cond, col].isna().sum() == 0
        # those not chosen will be <= than baseline load
        assert (df.loc[~cond, col].fillna(0) > df.loc[~cond, label].fillna(0)).sum() == 0
    
    # check loads_upgraded for hvac and total new load
    # 1. check those without new HVAC
    cond = df["upgrade_has_new_hvac"] == False
    # check that load_hvac is not included in loads_upgraded for those without new hvac load
    assert set(loads_upgraded.loc[cond].apply(lambda x: "load_hvac" not in x).unique()) == {True}

    new_load1 = sum_87_loads_vector(df.loc[cond], non_hvac_new_load_cols)
    new_load2 = df.loc[cond, "new_load_total_VA_220_87"]
    assert np.isclose(new_load1, new_load2, atol=1e-2).all()

    # 2. check those with new HVAC
    cond = df["upgrade_has_new_hvac"] == True
    # check that load_hvac is included in loads_upgraded for those with new hvac load
    assert set(loads_upgraded.loc[cond].apply(lambda x: "load_hvac" in x).unique()) == {True}

    new_load1 = sum_87_loads_vector(df.loc[cond], non_hvac_new_load_cols+["new_load_hvac_87"])
    new_load2 = df.loc[cond, "new_load_total_VA_220_87"]
    assert np.isclose(new_load1, new_load2, atol=1e-2).all()

    # check post-upgrade load
    total_load1 = df[["load_total_pre_upgrade_VA_220_87", "new_load_total_VA_220_87"]].sum(axis=1)
    total_load2 = df["load_total_post_upgrade_VA_220_87"]
    assert np.isclose(total_load1, total_load2, atol=1e-2).all()


if __name__ == "__main__":
    output_dir = "/Volumes/Lixi_Liu/panels_results_550k"
    output_folder = "test_result_files/nec_calculations_no_ev"

    test_all_upgrades(filedir=f"{output_dir}/{output_folder}")
