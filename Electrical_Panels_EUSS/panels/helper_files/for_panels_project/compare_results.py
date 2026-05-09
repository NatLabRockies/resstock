"""
This file compares the old and new results of NEC calculations for panels project, 
and generates summary stats for each param in the results, as well as changes between old and new results. 
The summary stats include value counts for string/bool params, and descriptive stats for numeric params. 
The output is saved in csv files for each upgrade and each folder (revision vs. no revision).

old results: panels_results_550k/old_results (generated on Sep 25, 2024, using _v1)
new results: panels_results_550k (generated on May 08, 2026, with bug fixes using _v2)
output: panels_results_550k/compare_old_new_results

date: 2026-05-08
"""
from pathlib import Path
import pandas as pd
import pandas.api.types as pd_types
from collections import defaultdict


def _get_value_counts(df_col: pd.Series, value_col: str = "param_value", suffix: str = "") -> pd.DataFrame:
    """Turn pd.Series.value_counts() into a dataframe"""
    df_out = df_col.value_counts().reset_index()
    param = df_out.columns[-1]
    col_names = [value_col, f"count{suffix}"]
    df_out.columns = col_names
    df_out["param_name"] = param
    return df_out[["param_name"] + col_names]


def _get_num_describe(df_col: pd.Series, suffix: str = "") -> pd.DataFrame:
    """Turn pd.Series.describe() into a dataframe"""
    df_out = df_col.describe().reset_index()
    param = df_out.columns[-1]
    col_names = ["num_metric", f"num_value{suffix}"]
    df_out.columns = col_names
    df_out["param_name"] = param
    return df_out[["param_name"] + col_names]


def _combine_stats(list_df: list[pd.DataFrame], aligned_cols: list[str]) -> pd.DataFrame:
    """combine old and new result stats, not changes"""
    lst = [df.set_index(aligned_cols) for df in list_df]
    return pd.concat(lst, axis=1).reset_index()


def get_stats_for_str_bool_col(dfo: pd.DataFrame, dfn: pd.DataFrame, col: str, cast_to_str: bool = False) -> pd.DataFrame:
    if cast_to_str:
        dfo_col = dfo[col].astype(str)
        dfn_col = dfn[col].astype(str)
    else:
        dfo_col = dfo[col]
        dfn_col = dfn[col]
    df1 = _get_value_counts(dfo_col, "param_value", "_old")
    df2 = _get_value_counts(dfn_col, "param_value", "_new")
    df_out = _combine_stats(
        [df1, df2],
        aligned_cols=["param_name", "param_value"]
        )

    # record changes
    col_changed = (dfo_col==dfn_col).replace({True: "same", False: "changed"})
    dfc = _get_value_counts(col_changed, "param_status", "_param_status")

    df_out = pd.concat([df_out, dfc], ignore_index=True)
    return df_out


def get_stats_for_num_col(dfo: pd.DataFrame, dfn: pd.DataFrame, col: str) -> pd.DataFrame:
    df1 = _get_num_describe(dfo[col], "_old")
    df2 = _get_num_describe(dfn[col], "_new")

    df_out = _combine_stats(
        [df1, df2],
        aligned_cols=["param_name", "num_metric"]
        )

    # record changes
    col_changed = (dfo[col]==dfn[col]).replace({True: "same", False: "changed"})
    dfc = _get_value_counts(col_changed, "param_status", "_param_status")

    df_out = pd.concat([df_out, dfc], ignore_index=True)
    return df_out


old_result_dir = Path("/Volumes/Lixi_Liu/panels_results_550k/old_results")
new_result_dir = Path("/Volumes/Lixi_Liu/panels_results_550k")
comparison_dir = Path("/Volumes/Lixi_Liu/panels_results_550k/compare_old_new_results")

folders = [
    "nec_calculations_revision_no_ev",
    "nec_calculations_revision_ev_level1",
    "nec_calculations_revision_ev_level2",
    "nec_calculations_no_ev",
    "nec_calculations_ev_level1",
    "nec_calculations_ev_level2",
]

print("Comparing NEC calculation results:")
print(" [1] ", old_result_dir)
print(" [2] ", new_result_dir)
print()
for i, folder in enumerate(folders, 1):
    old_file_dir = old_result_dir / folder
    new_file_dir = new_result_dir / folder
    out_file_dir = comparison_dir / folder
    out_file_dir.mkdir(parents=True, exist_ok=True)
    print(f"Processing {i}: {folder}...")
    for ofile in old_file_dir.glob("results*.parquet"):
        nfile = new_file_dir / ofile.name
        upg_name = "_".join(ofile.name.split("_")[:2])
        print(f" -> processing {upg_name}...")

        dfo = pd.read_parquet(ofile)
        dfn = pd.read_parquet(nfile)

        if "revision" in folder:
            # map old cols with new as much as possible
            cols_renamed = {
                # "load_hvac_primary_heating_heat_pump": "load_primary_heat",
                # "load_hvac_primary_heating_electric_resistance": "load_primary_heat",
                # "load_hvac_secondary_heating_heat_pump": "load_secondary_heat",
                # "load_hvac_secondary_heating_electric_resistance": "load_secondary_heat",
                "load_hvac_heat_pump_backup": "load_backup_heat",
                "load_hvac_heating_air_handler": "load_heat_ahu",
                "load_hvac_cooling": "load_cool",
                "load_hvac_cooling_air_handler": "load_cool_ahu",
                "load_hvac_determinant": "hvac_dominance", # add to dfn
                "loads_upgraded_83": "loads_upgraded",
                # "new_load_hvac_primary_heating_heat_pump_83": "new_load_primary_heat",
                # "new_load_hvac_primary_heating_electric_resistance_83": "new_load_primary_heat",
                # "new_load_hvac_secondary_heating_heat_pump_83": "new_load_secondary_heat",
                # "new_load_hvac_secondary_heating_electric_resistance_83": "new_load_secondary_heat",
                "new_load_hvac_heat_pump_backup_83": "new_load_backup_heat",
                "new_load_hvac_heating_air_handler_83": "new_load_heat_ahu",
                "new_load_hvac_cooling_83": "new_load_cool",
                "new_load_hvac_cooling_air_handler_83": "new_load_cool_ahu",
                # "new_load_hvac_heating_has_ducts_83", # not mapped
                # "new_load_hvac_cooling_has_ducts_83", # not mapped
                "new_load_water_heater_83": "new_load_water_heater",
                "new_load_dryer_83": "new_load_dryer",
                "new_load_range_oven_83": "new_load_range_oven",
                "new_load_hot_tub_spa_83": "new_load_hot_tub_spa",
                "new_load_pool_heater_83": "new_load_pool_heater",
                "new_load_evse_83": "new_load_evse",
                "post_load_hvac_determinant_83": "new_hvac_dominance", # add to dfn
            }
            dfo.rename(columns=cols_renamed, inplace=True)

            # add new cols to old results
            dfo["load_primary_heat"] = dfo[["load_hvac_primary_heating_heat_pump", "load_hvac_primary_heating_electric_resistance"]].fillna(0).sum(axis=1)
            dfo["load_secondary_heat"] = dfo[["load_hvac_secondary_heating_heat_pump", "load_hvac_secondary_heating_electric_resistance"]].fillna(0).sum(axis=1)
            dfo["load_heating"] = dfo[["load_primary_heat", "load_secondary_heat", "load_backup_heat", "load_heat_ahu"]].fillna(0).sum(axis=1)
            dfo["load_cooling"] = dfo[["load_cool", "load_cool_ahu"]].fillna(0).sum(axis=1)

            dfo["new_load_primary_heat"] = dfo[["new_load_hvac_primary_heating_heat_pump_83", "new_load_hvac_primary_heating_electric_resistance_83"]].fillna(0).sum(axis=1)
            dfo["new_load_secondary_heat"] = dfo[["new_load_hvac_secondary_heating_heat_pump_83", "new_load_hvac_secondary_heating_electric_resistance_83"]].fillna(0).sum(axis=1)
            dfo["new_load_heating"] = dfo[["new_load_primary_heat", "new_load_secondary_heat", "new_load_backup_heat", "new_load_heat_ahu"]].fillna(0).sum(axis=1)
            dfo["new_load_cooling"] = dfo[["new_load_cool", "new_load_cool_ahu"]].fillna(0).sum(axis=1)

            # add old cols to new results
            dfn["hvac_dominance"] = "heating/cooling"
            dfn.loc[dfn["load_heating"].fillna(0)>dfn["load_cooling"].fillna(0), "hvac_dominance"] = "heating"
            dfn.loc[dfn["load_heating"].fillna(0)<dfn["load_cooling"].fillna(0), "hvac_dominance"] = "cooling"

            dfn["new_hvac_dominance"] = "heating/cooling"
            dfn.loc[dfn["new_load_heating"].fillna(0)>dfn["new_load_cooling"].fillna(0), "new_hvac_dominance"] = "heating"
            dfn.loc[dfn["new_load_heating"].fillna(0)<dfn["new_load_cooling"].fillna(0), "new_hvac_dominance"] = "cooling"

            notes_dict1 = {v: "Param_name in old results: "+k+"." for k, v in cols_renamed.items()}
            notes_dict2 = {
                "load_primary_heat": "Sum of param_names in old results: [load_hvac_primary_heating_heat_pump, load_hvac_primary_heating_electric_resistance].",
                "load_secondary_heat": "Sum of param_names in old results: [load_hvac_secondary_heating_heat_pump, load_hvac_secondary_heating_electric_resistance].",
                "load_heating": "Sum of [load_primary_heat, load_secondary_heat, load_backup_heat, load_heat_ahu].",
                "load_cooling": "Sum of [load_cool, load_cool_ahu].",
                "load_hvac": "Max of [load_heating, load_cooling].",
            }
            notes_dict3 = {k.replace("load", "new_load"): v.replace("load", "new_load") for k, v in notes_dict2.items()}
            notes_dict4 = {
                "hvac_dominance": "Not in new results, but can be obtained by comparing between load_heating vs. load_cooling."
            }
            
            notes_dict = defaultdict(str)
            for dct in [notes_dict1, notes_dict2, notes_dict3]:
                for key, val in dct.items():
                    notes_dict[key] += " " if len(notes_dict[key]) > 0 else "" + val
            
        # get summary    
        res_lst = []
        print(f"Columns: {len(dfo.columns)} in old results vs. {len(dfn.columns)} in new results")
        for col in dfo.columns:
            if col not in dfn.columns:
                print(f" - {col} no longer in new results")
                continue

            if col == "building_id":
                continue

            if col == "apply_upgrade.upgrade_name":
                df_out = pd.DataFrame({
                    "param_name":[col], 
                    "param_value": dfo[col].unique(),
                    "count_old": dfo["building_id"].nunique(), 
                    "count_new": dfn["building_id"].nunique()
                    })
                res_lst.append(df_out)
                continue
            
            if pd_types.is_bool_dtype(dfo[col]):
                df_out = get_stats_for_str_bool_col(dfo, dfn, col)
                res_lst.append(df_out)
                continue
            
            if pd_types.is_object_dtype(dfo[col]):
                df_out = get_stats_for_str_bool_col(dfo, dfn, col, cast_to_str=True)
                res_lst.append(df_out)
                continue
            
            if pd_types.is_float_dtype(dfo[col]):
                df_out = get_stats_for_num_col(dfo, dfn, col)
                res_lst.append(df_out)
                continue
        
        # get summary of HVAC msg
        for col in dfn.columns:
            if not "msg" in col:
                continue
            df_out = _get_value_counts(dfn[col], "param_value", "_new")
            res_lst.append(df_out)
        

        # finalize result_summary
        df_out = pd.concat(res_lst, ignore_index=True)
        df_out["num_value_diff"] = df_out["num_value_new"] - df_out["num_value_old"]
        df_out["num_value_diff_pct"] = df_out["num_value_diff"].div(df_out["num_value_new"])*100

        # add notes as needed
        if "revision" in folder:
            df_out["notes"] = df_out["param_name"].map(notes_dict)

        # rearrange cols
        last_cols = ["param_status", "count_param_status"] + ["notes"] if "notes" in df_out.columns else []
        ordered_cols = [x for x in df_out.columns if x not in last_cols] + last_cols
        df_out = df_out[ordered_cols]

        # save to file
        filename = out_file_dir / (upg_name + ".csv")
        df_out.to_csv(filename, index=False)
    
    print(f"Comparison {i} exported to: {out_file_dir}")
            

