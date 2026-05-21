import pandas as pd
from pathlib import Path

data_dir = Path("/Volumes/Lixi_Liu/panels_results_550k")
file_folders = [
    "nec_calculations_revision_no_ev",
    "nec_calculations_revision_ev_level1",
    "nec_calculations_revision_ev_level2",
]

for file_folder in file_folders:
    file_dir = data_dir / file_folder

    output_dir = data_dir / "new_results_with_aligned_columns" / file_folder
    output_dir.mkdir(parents=True, exist_ok=True)

    print("Processing: ", file_dir)
    for file in sorted([x for x in sorted(file_dir.glob("*results_up*"))]):
        df = pd.read_parquet(file)
        new_cols = [
            'new_load_heating',
            'new_load_cooling', 
            'new_load_hvac', 
            # 'new_load_primary_heat',
            # 'new_load_secondary_heat', 
            # 'new_load_backup_heat', 
            # 'new_load_cool',
            # 'new_load_heat_ahu', 
            # 'new_load_cool_ahu', 
            'new_load_water_heater',
            'new_load_dryer', 
            'new_load_range_oven', 
            'new_load_hot_tub_spa',
            'new_load_pool_heater', 
            'new_load_evse', 
        ]
        for col in new_cols:
            df[col+"_87"] = df[col]
        df.rename(columns={col: col+"_83" for col in new_cols}, inplace=True)

        df.to_parquet(output_dir / file.name)

    print("Processing complete, files saved to:", output_dir)

