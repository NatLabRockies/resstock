import os
import pandas as pd

current_directory = os.path.dirname(os.path.abspath(__file__))
output_directory = os.path.join(current_directory, "data_/final_AMY2018_EUSSRR2")  # Directory for Parquet or CSV files
csv_output_directory = os.path.join(current_directory, "data_/final_results")  # Directory to save CSV files
os.makedirs(csv_output_directory, exist_ok=True)

# Define community-specific electricity rates based on "applicability"
community_rates = {
    "detroit": {
        False: {"electricity_fix_rate": 120, "electricity_volumetric_rate": 0.174115791},  # Applicability = False
        True: {"electricity_fix_rate": 144, "electricity_volumetric_rate": 0.160},  # Applicability = True
    },
    "parramore": {
        False: {"electricity_fix_rate": 120, "electricity_volumetric_rate": 0.118232586},  # Applicability = False
        True: {"electricity_fix_rate": 144, "electricity_volumetric_rate": 0.129},  # Applicability = True
    },
    "brainerd": {
        False: {"electricity_fix_rate": 120, "electricity_volumetric_rate": 0.133928744},  # Applicability = False
        True: {"electricity_fix_rate": 144, "electricity_volumetric_rate": 0.127},  # Applicability = True
    },
    # TODO: Add more communities as needed
}

# List of community names to process
communities = ["detroit", "parramore","brainerd"] #TODO: Add more communities here

for community_name in communities:
    print(f"Processing community: {community_name}")

    # Filter relevant CSV files for the community (including both baseline and upgrade files)
    community_files = [
        f for f in os.listdir(output_directory)
        if f.startswith(f"{community_name}_inflation_adjusted_income") and f.endswith(".csv")
    ]
    
    if not community_files:
        print(f"No files found for {community_name}. Skipping...")
        continue
    
    for file_name in community_files:
        file_path = os.path.join(output_directory, file_name)
        print(f"Reading file: {file_path}")
        df = pd.read_csv(file_path)

        # Extract file type (e.g., "baseline" or "upgradeXX") from filename
        file_type = file_name.split("_inflation_adjusted_income_")[1].replace(".csv", "")

        # Ensure 'applicability' column exists, otherwise default to False
        if "applicability" not in df.columns:
            df["applicability"] = False  # Default to False if column is missing

        # Convert 'applicability' to boolean (ensure values are either True or False)
        df["applicability"] = df["applicability"].astype(str).str.lower().map({"true": True, "false": False}).fillna(False)

        # Apply electricity rate adjustments based on 'applicability'
        if "out.electricity.total.energy_consumption.kwh" in df.columns:
            df["out.recalculated_bills.electricity.usd"] = df.apply(
                lambda x: (
                    community_rates[community_name][x["applicability"]]["electricity_fix_rate"] +
                    (community_rates[community_name][x["applicability"]]["electricity_volumetric_rate"] * x["out.electricity.total.energy_consumption.kwh"])
                ), axis=1
            )

        # Recalculate all fuels cost (applies to both baseline and upgrade files)
        fuel_columns = [
            "out.recalculated_bills.electricity.usd",  # Recalculated electricity bills
            "out.bills.fuel_oil.usd",
            "out.bills.natural_gas.usd",
            "out.bills.propane.usd"
        ]

        # Use only columns that exist in the DataFrame
        existing_fuel_columns = [col for col in fuel_columns if col in df.columns]
        df["out.2022_inflation_adj_bills.all_fuels.usd"] = df[existing_fuel_columns].sum(axis=1, skipna=True)

        # Calculate energy burden using the new all-fuels column (applies to both file types)
        if "in.2022_inflation_adjusted_representative_income" in df.columns:
            income_column = "in.2022_inflation_adjusted_representative_income"
            df["out.2022_inflation_adj_energy_burden"] = df.apply(
                lambda x: x["out.2022_inflation_adj_bills.all_fuels.usd"] / x[income_column]
                if x[income_column] > 0 else None,
                axis=1
            )

        # **Check if file is an upgrade** (fix: now checks if "upgrade" is anywhere in the file name)
        if "upgrade" in file_type.lower() and "out.electricity.net.energy_consumption.kwh.savings" in df.columns:
            # Recalculate electricity bill savings
            df["out.recalculated.bills.electricity.usd.savings"] = df["out.electricity.net.energy_consumption.kwh.savings"] * community_rates[community_name][True]["electricity_volumetric_rate"]

            # Recalculate all-fuels bill savings
            df["out.recalculated.bills.all_fuels.usd.savings"] = (
                df["out.recalculated.bills.electricity.usd.savings"].fillna(0) +
                df["out.bills.fuel_oil.usd.savings"].fillna(0) +
                df["out.bills.natural_gas.usd.savings"].fillna(0) +
                df["out.bills.propane.usd.savings"].fillna(0)
            )

            # Recalculate energy burden savings
            if "in.2022_inflation_adjusted_representative_income" in df.columns:
                df["out.recalculated_energy_burden.percentage.savings"] = df.apply(
                    lambda x: x["out.recalculated.bills.all_fuels.usd.savings"] / x["in.2022_inflation_adjusted_representative_income"]
                    if x["in.2022_inflation_adjusted_representative_income"] > 0 else None,
                    axis=1
                )

        # Save the results for this file as a CSV with correct naming
        output_csv_file = os.path.join(csv_output_directory, f"{community_name}_{file_type}_downsampled_with_inflation_adj_income_and_energy_burden.csv")
        df.to_csv(output_csv_file, index=False)
        print(f"Saved CSV for {community_name} ({file_type}): {output_csv_file}")

print("Processing complete. CSV files saved to:", csv_output_directory)