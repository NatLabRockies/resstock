import os
import pandas as pd

# Define directories
current_directory = os.path.dirname(os.path.abspath(__file__))
input_directory = os.path.join(current_directory, "data_/final_results")  # Directory where CSVs are stored
output_directory = os.path.join(current_directory, "data_/compiled_results")  # Directory to save compiled files
os.makedirs(output_directory, exist_ok=True)

# List of community names to process
#communities = ["detroit", "parramore","brainerd"]  #A dd more communities as needed
communities = ["brainerd"]  #A dd more communities as needed

for community_name in communities:
    print(f"Processing community: {community_name}")

    # Find all baseline and upgrade files for the community
    # community_files = [
    #     os.path.join(input_directory, f) for f in os.listdir(input_directory)
    #     if f.startswith(f"{community_name}_") and f.endswith("_downsampled_with_inflation_adj_income_and_energy_burden.csv") #_downsampled_with_inflation_adj_income_and_energy_burden_and_adjusted_income_distribution.csv
    # ]

    community_files = [
         os.path.join(input_directory, f) for f in os.listdir(input_directory)
         if f.startswith(f"{community_name}_") and f.endswith("_downsampled_with_inflation_adj_income_energy_burden_and_adjusted_income_distribution.csv") #_downsampled_with_inflation_adj_income_and_energy_burden_and_adjusted_income_distribution.csv
    ] #/Users/sphoung/resstock_sinoun/euss_cleap2.0/data_/final_downsampled_with_inflation_adj_income_energy_burden_and_adjusted_income_distribution.csv

    if not community_files:
        print(f"No files found for {community_name}. Skipping...")
        continue

    # Sort files so baseline is first, then upgrades in numerical order
    community_files.sort(key=lambda x: (not x.split(f"{community_name}_")[1].startswith("baseline"), x))

    # Read and store data while maintaining all unique columns
    compiled_data = []
    original_column_order = None  # Store column order from the first file (baseline)

    for file_path in community_files:
        print(f"Reading file: {file_path}")
        df = pd.read_csv(file_path)

        # Drop the "index" column if it exists
        if "index" in df.columns:
            df = df.drop(columns=["index"])

        # Save the original column order from the first file (assumed to be baseline)
        if original_column_order is None:
            original_column_order = df.columns.tolist()

        compiled_data.append(df)

    # Get all unique columns from all files (while maintaining order from baseline)
    all_columns = list(dict.fromkeys(original_column_order + [col for df in compiled_data for col in df.columns]))

    # Ensure all dataframes have the same columns by reindexing (keeping original order)
    for i in range(len(compiled_data)):
        compiled_data[i] = compiled_data[i].reindex(columns=all_columns)  # Retain missing columns as NaN

    # Concatenate all files for this community
    final_df = pd.concat(compiled_data, ignore_index=True)

    # Ensure the original column order is maintained
    final_df = final_df[all_columns]

    # Save compiled DataFrame for this community
    output_file = os.path.join(output_directory, f"{community_name}_compiled_results.csv")
    final_df.to_csv(output_file, index=False)  # Ensure no index column is saved
    print(f"Saved compiled file for {community_name}: {output_file}")

print("Processing complete. Compiled files saved in:", output_directory)
