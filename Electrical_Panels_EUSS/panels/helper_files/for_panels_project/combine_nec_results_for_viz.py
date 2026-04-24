"""
Combine 2023 NEC and 2026 NEC results for Tableau visualization.
"""
from pathlib import Path
import pandas as pd

file_dir_2023 = Path("/Volumes/Lixi_Liu/panels_results_550k/nec_calculations_no_ev")
file_dir_2026 = Path("/Volumes/Lixi_Liu/panels_results_550k/nec_calculations_revision_no_ev")

output_file_dir = Path("/Volumes/Lixi_Liu/panels_results_550k__reduced/nec_calculations_2023_2026_no_ev")
output_file_dir.mkdir(exist_ok=True, parents=True)

for file_2026 in sorted(file_dir_2026.glob("results*.parquet")):
    filename_2026 = file_2026.name
    filename_2023 = filename_2026.replace("2026", "")
    file_2023 = file_dir_2023 / filename_2023
    if not file_2023.exists():
        print(f"2023 file not found for {file_2026.name}, skipping...")
        continue

    df_2026 = pd.read_parquet(file_2026)
    df_2023 = pd.read_parquet(file_2023)

    # Retain the following: 
    # - detailed new load breakdown from 2026 (works for 2023 83 + 2026 83/87)
    # - 87 load breakdown from 2023
    # - exclude detailed existing load breakdown as it is already available elsewhere

    baseline_cols = [x for x in df_2026.columns if x.startswith("load_") or x.startswith("type_") or "pre_upgrade" in x]
    itemized_cols_87 = [x for x in df_2023.columns if "87" in x and "post_upgrade" not in x]
    cols_pre_upgrade = [x for x in df_2026.columns if "pre_upgrade" in x]
    cols_post_upgrade = [x for x in df_2026.columns if "post_upgrade" in x]

    df1 = df_2026.drop(columns=baseline_cols).copy()
    df1.rename(columns={col: col+"_2026" for col in cols_post_upgrade}, inplace=True)

    df2 = df_2023.set_index("building_id")[itemized_cols_87+cols_post_upgrade].rename(
        columns=lambda col: col+"_2023").reset_index()
    
    # merge on building_id and upgrade
    df_combined = pd.merge(df1, df2, left_on=["building_id"], right_on=["building_id"], how="left")

    # save combined dataframe for visualization
    output_file = output_file_dir / filename_2023
    df_combined.to_parquet(output_file)
    print(f" - Saved combined results to {output_file}")

print("Columns in combined file:")
print(df_combined.columns.tolist())
