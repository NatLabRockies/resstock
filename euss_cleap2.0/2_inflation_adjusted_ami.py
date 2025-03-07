import pandas as pd
import os


#TODO: This code uses national data files but it is missing energy burden percent for upgrade 12.

current_directory = os.path.dirname(os.path.abspath(__file__)) 
downsampled_community_file = os.path.join(current_directory, "data_/downsampled_buildings_id") #Directory containing community CSV files
csv_directory = os.path.join(current_directory,"data_/final_AMY2018_EUSSRR2")  # Directory to Parquet files
output_directory = os.path.join(current_directory,"data_/final_AMY2018_EUSSRR2")  # Directory to save output Parquet files
os.makedirs(output_directory, exist_ok=True)

#TODO: Change community names and CPI values here (Consumer Price Index taken from https://fred.stlouisfed.org)
#Since utility bills are reported for 2021 and 2022 year, we decided to go with 2022 CPI because ..... 
community_files = {
    "detroit": {
        "file": os.path.join(downsampled_community_file, "baseline_metadata_and_annual_results__downsampled_method1__detroit.csv"),
        "cpi_values": {"2019": 235.703, "2022": 269.071},
    }, # For Detroit, since the CPI is reported as monthly values, to get annual CPI, find the average of all the months 
    "parramore": {
        "file": os.path.join(downsampled_community_file, "baseline_metadata_and_annual_results__downsampled_method1__parramore.csv"),
        "cpi_values": {"2019": 228.134, "2022": 273.597},
    }, #Note that Tampa-St. Petersburg-Clearwater, FL's CPI was used instead of Parramore due to lack of data
    "brainerd": {
        "file": os.path.join(downsampled_community_file, "baseline_metadata_and_annual_results__downsampled_method1__brainerd.csv"),
        "cpi_values": {"2019": 250.106, "2022": 285.008}, #Using CPI for Minneapolis-St.Paul-Bloomington, MN-WI https://fred.stlouisfed.org/series/CUUSA211SA0
    }
}

#TODO: either use csv or parque files for the data
# Resstock data release from OEDI
csv_files = [
    os.path.join(csv_directory, "baseline_metadata_and_annual_results.csv"),
    os.path.join(csv_directory, "upgrade01_metadata_and_annual_results.csv"),
    os.path.join(csv_directory, "upgrade02_metadata_and_annual_results.csv"),
    os.path.join(csv_directory, "upgrade03_metadata_and_annual_results.csv"),
    os.path.join(csv_directory, "upgrade04_metadata_and_annual_results.csv"),
    os.path.join(csv_directory, "upgrade05_metadata_and_annual_results.csv"),
    os.path.join(csv_directory, "upgrade06_metadata_and_annual_results.csv"),
    os.path.join(csv_directory, "upgrade07_metadata_and_annual_results.csv"),
    os.path.join(csv_directory, "upgrade08_metadata_and_annual_results.csv"),
    os.path.join(csv_directory, "upgrade09_metadata_and_annual_results.csv"),
    os.path.join(csv_directory, "upgrade10_metadata_and_annual_results.csv"),
    os.path.join(csv_directory, "upgrade11_metadata_and_annual_results.csv"),
    os.path.join(csv_directory, "upgrade12_metadata_and_annual_results.csv"),
    os.path.join(csv_directory, "upgrade13_metadata_and_annual_results.csv"),
    os.path.join(csv_directory, "upgrade14_metadata_and_annual_results.csv"),
    os.path.join(csv_directory, "upgrade15_metadata_and_annual_results.csv"),
    os.path.join(csv_directory, "upgrade16_metadata_and_annual_results.csv")
]


for community_name, info in community_files.items():
    community_file = info["file"]
    cpi_values = info["cpi_values"]
    
    inflation_rate = cpi_values["2022"] / cpi_values["2019"] # Calculate inflation rate for each community

    community_data = pd.read_csv(community_file)
    community_bldgs = community_data["bldg_id"] # Extract building IDs from the community file
    
    
    for csv_file in csv_files:
        df = pd.read_csv(csv_file)
        df.reset_index(inplace=True)
        filtered_df = df[df["bldg_id"].isin(community_bldgs)]
        
        # Apply inflation adjustment
        if "in.representative_income" in filtered_df.columns:
            if "in.2022_inflation_adjusted_representative_income" in filtered_df.columns:
                filtered_df.drop(columns=["in.2022_inflation_adjusted_representative_income"], inplace=True) # Remove the existing column if it exists

            filtered_df["in.2022_inflation_adjusted_representative_income"] = (
                filtered_df["in.representative_income"] * inflation_rate
            ) # Add the income adjusted column

        # Save the filtered and updated data back to a new Parquet file
        output_file = os.path.join(output_directory, f"{community_name}_inflation_adjusted_income_{os.path.basename(csv_file)}")
        filtered_df.to_csv(output_file, index=False)

print(f"Processing complete. Files saved to {output_directory}.")
