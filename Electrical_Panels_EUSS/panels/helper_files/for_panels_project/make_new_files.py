import pandas as pd
from pathlib import Path

data_dir = Path("/Volumes/Lixi_Liu/panels_results_550k")
# ouput_dir = Path("/Volumes/Lixi_Liu/panels_results_550k/results_to_fix")
ouput_dir = Path("/Volumes/Lixi_Liu/panels_results_550k/test_result_files")
ouput_dir.mkdir(exist_ok=True, parents=True)

### Section 1: filter results files to problematic bldgs
filename = "results_up00.parquet"
dfb = pd.read_parquet(data_dir / filename)

# filter to all unique HVAC combo
cond = dfb[[
    "build_existing_model.hvac_heating_efficiency", 
    "build_existing_model.hvac_secondary_heating_efficiency",
    "build_existing_model.hvac_cooling_efficiency",
    ]].drop_duplicates().index

# fix 1: ducted secondary heating
# cond = dfb["build_existing_model.hvac_secondary_heating_efficiency"].fillna("").str.lower().str.contains("furnace")

# fix 2: non-ducted secondary heating
# cond = dfb["build_existing_model.hvac_secondary_heating_efficiency"].fillna("").str.lower().str.contains("boiler")

bldg_ids = dfb.loc[cond, "building_id"].to_list()
print("Number of problematic buildings:", len(bldg_ids))
print(bldg_ids)

# add bldg 12 so at least one bldg will have results
bldg_ids.append(12)

cond = dfb["building_id"].isin(bldg_ids)
dfb.loc[cond].reset_index(drop=True).to_parquet(ouput_dir / filename)
del dfb

for file in data_dir.glob("results*.parquet"):
    if "up00" in file.stem:
        continue

    df = pd.read_parquet(file)
    # filter to problematic buildings (non-ducted primary and ducted secondary heating)
    cond = df["building_id"].isin(bldg_ids)
    df.loc[cond].reset_index(drop=True).to_parquet(ouput_dir / file.name)

print(f"Finished processing all files in: {ouput_dir}")

### Section 2: rerun NEC calculations

### Section 3: fix results files
# results_folders = [
#     "nec_calculations_ev_level1",
#     "nec_calculations_ev_level2",
#     "nec_calculations_no_ev",
#     "nec_calculations_revision_ev_level1",
#     "nec_calculations_revision_ev_level2",
#     "nec_calculations_revision_no_ev"
# ]
# for folder in results_folders:
#     result_dir = data_dir / folder
#     fixed_result_dir = ouput_dir / folder

#     for file in result_dir.glob("results*.parquet"):
#         df = pd.read_parquet(file)
#         df_fixed = pd.read_parquet(fixed_result_dir / file.name)
        
#         size1 = len(df)
#         bldgs_fixed = df_fixed["building_id"].to_list()
#         df2 = pd.concat([
#             df.loc[~df["building_id"].isin(bldgs_fixed)],
#             df_fixed,
#         ]).sort_values("building_id").reset_index(drop=True)
#         size2 = len(df2)
#         assert size1 == size2, f"Size mismatch after fixing {file.name}: {size1} vs {size2}"
#         df2.to_parquet(file)
#         print(f"Finished fixing {file}")