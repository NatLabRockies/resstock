"""
test results from postprocess_panel_new_load_nec_revision_v2.py for all upgrades and revisions, with and without EVSE load, and with expected output file generated from postprocess_panel_new_load_nec__all_upgrades_v2.py
            file        times
17  results_up18  2690.403251
15  results_up16  2623.392355
9   results_up10  2620.571184
18  results_up19  2610.169854
6   results_up07  2603.094789
2   results_up03  2588.278425
4   results_up05  2582.901195
16  results_up17  2580.225365
11  results_up12  2575.030520
13  results_up14  2570.105863
5   results_up06  2565.150829
12  results_up13  2558.272691
8   results_up09  2299.502978
10  results_up11  2264.189128
1   results_up02  2257.784862
3   results_up04  2253.838991
14  results_up15  2193.885650
7   results_up08  2183.142486
0   results_up01  1949.202812
Total time: 46569.143228530884
"""

from pathlib import Path
import sys
from tabnanny import check
from typing import Literal
import pandas as pd
import numpy as np

sys.path.append(str(Path(__file__).parents[2]))
from panels.postprocess_panel_new_load_nec_revision_v2 import (
    apply_demand_factor,
    hvac_labels_itemized,
)

def test_all_upgrades(filedir):
    filedir = Path(filedir)
    filedir_2023 = filedir.parent / filedir.name.replace("_revision", "")
    list_garbage_disposal = []
    files = sorted([x for x in sorted(filedir.glob("*results_up*"))])

    if len(files) == 0:
        raise ValueError(f"No files found in {filedir}")
    
    for file in files:
        upg = file.stem[10:12]
        print(f"Testing {upg}...")

        file_2023 = filedir_2023 / file.name

        if file.suffix == ".csv":
            print(f"skipping {file}")
            continue

        # if int(upg) != 2:
        #     print(f"skipping {file}")
        #     continue

        # if int(upg) < 15:
        #     print(f"skipping {file}")
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

        # compare if file exists
        if file_2023.exists():
             if file_2023.suffix == ".csv":
                df_2023 = pd.read_csv(file_2023)
             elif file_2023.suffix == ".parquet":
                df_2023 = pd.read_parquet(file_2023)
             else:
                raise ValueError(f"Unsupported file type: {file_2023.suffix}")
             print("Comparing with 2023 calculation...")
             _compare_2023_and_2026(df_2023, df)

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
            assert get_values(df["new_load_water_heater"]) == {900} # HP, 120V, shared
        case "240v_hpwh":
            assert get_values(df["new_load_water_heater"]) == {5000} # HP, 240V
        case "er":
            # ER storage and tankless
            assert get_values(df["new_load_water_heater"]) == {4500, 18000, 24000, 36000}
        case _:
            raise ValueError(f"Unsupported {type=}")
        

def check_dryer_load(df, low_power):
    if low_power:
        assert get_values(df["new_load_dryer"]) == set()
    else:
        assert get_values(df["new_load_dryer"]) == {5760} # ER, 240V


def check_cooking_load(df, low_power):
    if low_power:
        assert get_values(df["new_load_range_oven"]) == {1800} # ER, 120V
    else:
        assert get_values(df["new_load_range_oven"]) == {12000} # ER, 240V
        

    
def check_ev_load(df, level: Literal[0,1,2]):
    if level == 0:
        assert get_values(df["new_load_evse"]) == set()
    elif level == 1:
        assert get_values(df["new_load_evse"]) == {1440}
    elif level == 2:
        assert get_values(df["new_load_evse"]) == {7680}
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
    

def check_hvac_load(df, check_new_load: bool = False):
    if check_new_load:
        prefix = "new_"
    else:
        prefix = ""
    
    # check there is heating ahu load if ducted electric heating
    cond = df[f"{prefix}type_primary_heat"].fillna("").str.startswith("ducted")
    cond |= df[f"{prefix}type_secondary_heat"].fillna("").str.startswith("ducted")
    cond |= df[f"{prefix}type_backup_heat"].fillna("").str.startswith("ducted")
    cond &= ~df[f"{prefix}hvac_msg"].fillna("").str.contains("expecting a AHU", case=False, na=False)
    assert (df.loc[cond, f"{prefix}load_heat_ahu"] > 0).all()
    assert (df.loc[~cond, f"{prefix}load_heat_ahu"].fillna(0) == 0).all()

    # check this is cooling ahu load if ducted cooling
    cond = df[f"{prefix}type_cool"].fillna("").str.startswith("ducted")
    cond &= ~df[f"{prefix}hvac_msg"].fillna("").str.contains("expecting a AHU", case=False, na=False)
    assert (df.loc[cond, f"{prefix}load_cool_ahu"] > 0).all()
    assert (df.loc[~cond, f"{prefix}load_cool_ahu"].fillna(0) == 0).all()

    # load_heating
    heat_load1 = df[[f"{prefix}load_primary_heat", f"{prefix}load_secondary_heat", f"{prefix}load_backup_heat", f"{prefix}load_heat_ahu"]].fillna(0).sum(axis=1)
    heat_load2 = df[f"{prefix}load_heating"].fillna(0)
    assert heat_load1.equals(heat_load2)

    # load_cooling
    cool_load1 = df[[f"{prefix}load_cool", f"{prefix}load_cool_ahu"]].fillna(0).sum(axis=1)
    cool_load2 = df[f"{prefix}load_cooling"].fillna(0)
    assert cool_load1.equals(cool_load2)

    # load_hvac is max of heating or cooling
    hvac_load1 = df[[f"{prefix}load_heating", f"{prefix}load_cooling"]].fillna(0).max(axis=1)
    hvac_load2 = df[f"{prefix}load_hvac"].fillna(0)
    assert hvac_load1.equals(hvac_load2)


def check_83_existing_and_new_hvac_evse_separation(df):
    """Check that existing and new HVAC and EVSEloads are correctly identified"""
    cond = df["upgrade_has_new_hvac"]==True
    assert (df.loc[cond, "post_upg_load_existing_hvac"] == 0).all()
    f1 = (df.loc[cond, ["post_upg_load_new_hvac_er", "post_upg_load_new_hvac_non_er"]].sum(axis=1)).fillna(0)
    f2 = df.loc[cond, "new_load_hvac"].fillna(0)
    assert np.isclose(f1, f2, atol=1e-2).all()

    # new HVAC is cooling-dominant
    cond_cool = df["new_load_cooling"].fillna(0) > df["new_load_heating"].fillna(0)
    f1 = df.loc[cond & cond_cool, "post_upg_load_new_hvac_non_er"].fillna(0)
    f2 = df.loc[cond & cond_cool, "new_load_cooling"].fillna(0)
    assert np.isclose(f1, f2, atol=1e-2).all()

    # new HVAC is heating-dominant
    f1 = df.loc[cond & ~cond_cool, ["post_upg_load_new_hvac_er", "post_upg_load_new_hvac_non_er"]].fillna(0).sum(axis=1)
    f2 = df.loc[cond & ~cond_cool, "new_load_heating"].fillna(0)
    assert np.isclose(f1, f2, atol=1e-2).all()

    # hvac is existing
    f1 = df.loc[~cond, "post_upg_load_existing_hvac"].fillna(0)
    f2 = df.loc[~cond, "new_load_hvac"].fillna(0)
    assert np.isclose(f1, f2, atol=1e-2).all()
    assert (df.loc[~cond, ["post_upg_load_new_hvac_er", "post_upg_load_new_hvac_non_er"]].sum(axis=1) == 0).all()

    # new EVSE
    f1 = df.loc[df["new_load_evse"]>0, "post_upg_load_new_evse"].fillna(0)
    f2 = df.loc[df["new_load_evse"]>0, "new_load_evse"].fillna(0)
    assert np.isclose(f1, f2, atol=1e-2).all()

def check_83_post_upg_load_calculation(df):
    """ Check that total load is correct from calculation using post_upg_load cols
        Total post-upgrade load: 
        -> 100% of 1st 8 kVA existing +
        -> 40% remaining existing +
        -> 80% new (EVSE | ER heating) +
        -> 50% new others
    """
    existing_load_cols = [col for col in df.columns if col.startswith("post_upg_load_existing")]
    adj_existing_load = df[existing_load_cols].fillna(0).sum(axis=1).apply(apply_demand_factor)

    new_load_80_cols = ["post_upg_load_new_hvac_er", "post_upg_load_new_evse"]
    new_load_50_cols = [col for col in df.columns if col.startswith("post_upg_load_new_") and col not in new_load_80_cols]
    adj_new_load = df[new_load_80_cols].fillna(0).sum(axis=1)*0.8 + df[new_load_50_cols].fillna(0).sum(axis=1)*0.5

    total_load1 = adj_existing_load + adj_new_load
    total_load2 = df["load_total_post_upgrade_VA_220_83"]
    assert np.isclose(total_load1, total_load2, atol=1e-2).all()


def _test_existing_calculation(df):
    check_hvac_load(df, check_new_load=False)

    load_cols = [col for col in df.columns if col.startswith("load_")]
    excluded_hvac_cols = [x for x in hvac_labels_itemized() if x != "load_hvac"]
    existing_load_cols = [col for col in load_cols if col not in excluded_hvac_cols and "upgrade" not in col] 
    gross_load1 = df[existing_load_cols].sum(axis=1)
    gross_load2 = df["load_total_pre_upgrade_VA_220_83"].apply(get_total_gross_load)

    assert np.isclose(gross_load1, gross_load2, atol=1e-2).all()


def _test_83_calculation(df):
    check_hvac_load(df, check_new_load=True)
    check_83_existing_and_new_hvac_evse_separation(df)
    check_83_post_upg_load_calculation(df)
    
    # check upgrade_has_new_hvac
    assert set(df.loc[df["new_load_hvac"] > df["load_hvac"], "upgrade_has_new_hvac"].unique()) == {True}
    assert set(df.loc[df["new_load_hvac"] <= df["load_hvac"], "upgrade_has_new_hvac"].unique()) == {False}

    new_load_cols = [col for col in df.columns if col.startswith("new_load_")]
    excluded_hvac_cols = ["new_"+x for x in hvac_labels_itemized()] + ["new_load_total_VA_220_87"]
    non_hvac_new_load_cols = [col for col in new_load_cols if col not in excluded_hvac_cols]
    non_hvac_ext_load_cols = [col.removeprefix("new_") for col in non_hvac_new_load_cols]
    loads_upgraded = df["loads_upgraded"].astype(str)

    # check loads_upgraded for non-hvac loads:
    for col in non_hvac_new_load_cols:
        label = col.removeprefix("new_")
        cond = loads_upgraded.str.contains(label)
        assert df.loc[cond, col].isna().sum() == 0
        assert (~df.loc[~cond, col].isna()).sum() == 0
    
    # check loads_upgraded for hvac load:
    # load can stay the same even if equipment has changed
    cond = ~loads_upgraded.str.contains("load_hvac")
    assert set(df.loc[cond, "upgrade_has_new_hvac"].unique()) == {False}

    # check post-upgrade gross load
    pre_upg_gross_load = df["load_total_pre_upgrade_VA_220_83"].apply(get_total_gross_load)

    # post-upgrade gross load calculated from pre-upgrade gross load, subtract old loads, add new loads
    df_non_hvac = df[non_hvac_new_load_cols].rename(columns=dict(zip(non_hvac_new_load_cols, non_hvac_ext_load_cols)))
    df_non_hvac_new = df_non_hvac.fillna(0).sum(axis=1)
    df_non_hvac_old = df[non_hvac_ext_load_cols][~df_non_hvac.isna()].fillna(0).sum(axis=1)
    post_upg_gross_load1 = pre_upg_gross_load - df_non_hvac_old + df_non_hvac_new - df["load_hvac"].fillna(0) + df["new_load_hvac"].fillna(0)

    # post-upgrade gross load calculated from post_upg_load cols
    post_upg_cols = [col for col in df.columns if col.startswith("post_upg_load_")]
    post_upg_gross_load2 = df[post_upg_cols].fillna(0).sum(axis=1)
    assert np.isclose(post_upg_gross_load1, post_upg_gross_load2, atol=1e-2).all()


def _test_87_calculation(df):
    """Check total load delta is the same with 83 calculation"""

    # check load delta from pre-upgrade to post-upgrade is the same between 83 and 87 calculations
    load_delta_83 = (df["load_total_post_upgrade_VA_220_83"] - df["load_total_pre_upgrade_VA_220_83"]).fillna(0)
    load_delta_87 = df["new_load_total_VA_220_87"].fillna(0)
    assert np.isclose(load_delta_83, load_delta_87, atol=1e-2).all()

    # check post-upgrade load
    total_load1 = df[["load_total_pre_upgrade_VA_220_87", "new_load_total_VA_220_87"]].sum(axis=1)
    total_load2 = df["load_total_post_upgrade_VA_220_87"]
    assert np.isclose(total_load1, total_load2, atol=1e-2).all()


def _compare_2023_and_2026(df_2023, df_2026):
    """Compare the 2023 and 2026 calculations for the same upgrade and same set of buildings, to check if the changes in 2026 calculation are reasonable"""

    # check same set of buildings
    assert set(df_2023["building_id"]) == set(df_2026["building_id"])

    # get columns
    bl_cols = [x for x in df_2023.columns if x.startswith("load_") and "post_upgrade" not in x]
    upg_83_cols = [x for x in df_2023.columns if x.startswith("new_load_") and "83" in x]

    # check that existing load cols and pre-upgrade totals are the same
    for col in bl_cols:
        assert np.isclose(df_2023[col].fillna(0), df_2026[col].fillna(0), atol=1e-2).all()
    
    # check that new load cols are the same
    for col in upg_83_cols:
        col2 = col.replace("_83", "")
        assert np.isclose(df_2023[col].fillna(0), df_2026[col2].fillna(0), atol=1e-2).all()


if __name__ == "__main__":
    output_dir = "/Volumes/Lixi_Liu/panels_results_550k"
    output_folder = "nec_calculations_revision_no_ev"

    test_all_upgrades(filedir=f"{output_dir}/{output_folder}")
