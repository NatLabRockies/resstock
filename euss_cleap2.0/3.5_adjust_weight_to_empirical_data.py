import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

csv_output_directory = "data_/final_results"  # Change as needed
community_name = "parramore"  # Change as needed

# Baseline file name and output file name.
baseline_filename = f"{community_name}_baseline_metadata_and_annual_results_downsampled_with_inflation_adj_income_and_energy_burden.csv"
baseline_output_filename = f"{community_name}_baseline_metadata_and_annual_results_downsampled_with_inflation_adj_income_energy_burden_and_adjusted_income_distribution.csv"
baseline_input_file = os.path.join(csv_output_directory, baseline_filename)
baseline_output_file = os.path.join(csv_output_directory, baseline_output_filename)

df = pd.read_csv(baseline_input_file)

# DEFINE EMPIRICAL INCOME DISTRIBUTION (average of two estimates)
empirical_income_distribution = {
    "Less than $10,000": (19.1 + 27.0) / 2,
    "$10,000 to $14,999": (20.6 + 9.7) / 2,
    "$15,000 to $24,999": (28.2 + 22.3) / 2,
    "$25,000 to $34,999": (12.8 + 26.0) / 2,
    "$35,000 to $49,999": (3.3 + 5.9) / 2,
    "$50,000 to $74,999": (8.7 + 9.1) / 2,
    "$75,000 to $99,999": (2.4 + 0.0) / 2,
    "$100,000 to $149,999": (3.0 + 0.0) / 2,
    "$150,000 to $199,999": (0.0 + 0.0) / 2,
    "$200,000 or more": (2.0 + 0.0) / 2
}
# Normalize so the weights sum to 1.0
total_empirical_weight = sum(empirical_income_distribution.values())
empirical_income_distribution = {k: v / total_empirical_weight for k, v in empirical_income_distribution.items()}

# MAP ResStock income bins to empirical bins
income_mapping = {
    "<10000": "Less than $10,000",
    "10000-14999": "$10,000 to $14,999",
    "15000-19999": "$15,000 to $24,999",
    "20000-24999": "$15,000 to $24,999",
    "25000-29999": "$25,000 to $34,999",
    "30000-34999": "$25,000 to $34,999",
    "35000-39999": "$35,000 to $49,999",
    "40000-44999": "$35,000 to $49,999",
    "45000-49999": "$35,000 to $49,999",
    "50000-59999": "$50,000 to $74,999",
    "60000-69999": "$50,000 to $74,999",
    "70000-79999": "$50,000 to $74,999",
    "80000-99999": "$75,000 to $99,999",
    "100000-119999": "$100,000 to $149,999",
    "120000-139999": "$100,000 to $149,999",
    "140000-159999": "$100,000 to $149,999",
    "160000-179999": "$150,000 to $199,999",
    "180000-199999": "$150,000 to $199,999",
    "200000+": "$200,000 or more"
}
df["mapped_income_bin"] = df["in.income"].map(income_mapping)

# IDENTIFY "NOT AVAILABLE" ROWS (for puma G12009505)
not_available_mask = df["in.income"].str.lower().str.contains("not available", na=False) & (df["in.puma"] == "G12009505")

# Calculate the fraction of the total that these rows represent.
na_count = not_available_mask.sum()
total_count = len(df)
na_fraction = na_count / total_count  # e.g., 0.13 if 13% of the data

# Evenly assign the NA fraction to those rows.
if na_count > 0:
    df.loc[not_available_mask, "bldg_reweighed_percent"] = na_fraction / na_count

# DISTRIBUTE THE REMAINING WEIGHT BASED ON EMPIRICAL DATA
available_mask = ~not_available_mask
remaining_weight = 1.0 - na_fraction

# For available rows, fill missing mapped bins as "Unknown"
df.loc[available_mask, "mapped_income_bin"] = df.loc[available_mask, "mapped_income_bin"].fillna("Unknown")

# Prepare a Series to store new weights for available rows.
new_available_weights = pd.Series(0.0, index=df.index)

np.random.seed(42)  # For reproducibility

# Distribute weight for available rows whose income bin is in the empirical distribution.
for emp_bin, target_frac in empirical_income_distribution.items():
    group_mask = available_mask & (df["mapped_income_bin"] == emp_bin)
    group_count = group_mask.sum()
    if group_count > 0:
        group_target_weight = target_frac * remaining_weight
        # Introduce controlled randomness.
        random_factors = np.random.uniform(0.7, 1.3, size=group_count)
        group_weights = group_target_weight * random_factors / random_factors.sum()
        new_available_weights.loc[group_mask] = group_weights

# For any available rows with bins not in the empirical distribution (e.g., "Unknown"),
# allocate any leftover weight.
assigned_weight = new_available_weights.loc[available_mask].sum()
leftover_weight = remaining_weight - assigned_weight
if leftover_weight > 0:
    unknown_mask = available_mask & (~df["mapped_income_bin"].isin(empirical_income_distribution.keys()))
    unknown_count = unknown_mask.sum()
    if unknown_count > 0:
        random_factors = np.random.uniform(0.7, 1.3, size=unknown_count)
        group_weights = leftover_weight * random_factors / random_factors.sum()
        new_available_weights.loc[unknown_mask] = group_weights

# Assign the computed weights to available rows.
df.loc[available_mask, "bldg_reweighed_percent"] = new_available_weights.loc[available_mask]

# ENSURE ALL WEIGHTS ARE GREATER THAN 0
min_positive = 1e-4
df["bldg_reweighed_percent"] = df["bldg_reweighed_percent"].apply(lambda x: max(x, min_positive))

# FINAL NORMALIZATION & CALCULATIONS
# Final normalization (to ensure the sum is exactly 1.0)
df["bldg_reweighed_percent"] = df["bldg_reweighed_percent"] / df["bldg_reweighed_percent"].sum()

# Compute building reweighed units using the fixed scaling factor.
SCALING_FACTOR = 252.30163873025225 * len(df)
df["bldg_reweighed_units"] = df["bldg_reweighed_percent"] * SCALING_FACTOR  

# Drop the helper column.
df.drop(columns=["mapped_income_bin"], inplace=True)
if "index" in df.columns:
    df.drop(columns=["index"], inplace=True)

df.to_csv(baseline_output_file, index=False)
print(f"Baseline processing complete. Adjusted income distribution saved to: {baseline_output_file}")

# ---------------------------
# LINKING BASELINE WEIGHTS TO UPGRADE FILES
for i in range(1, 17):
    # Construct the upgrade filename (using 2-digit numbering, e.g. upgrade01)
    upgrade_filename = f"{community_name}_upgrade{str(i).zfill(2)}_metadata_and_annual_results_downsampled_with_inflation_adj_income_and_energy_burden.csv"
    upgrade_filepath = os.path.join(csv_output_directory, upgrade_filename)
    
    if os.path.exists(upgrade_filepath):
        df_upgrade = pd.read_csv(upgrade_filepath)
        
        # Merge the baseline's weights into the upgrade file using "bldg_id"
        df_upgrade = df_upgrade.merge(
            df[['bldg_id', 'bldg_reweighed_percent', 'bldg_reweighed_units']],
            on='bldg_id',
            how='left'
        )

        # Drop the "index" column if it exists in the upgrade DataFrame
        if "index" in df_upgrade.columns:
            df_upgrade.drop(columns=["index"], inplace=True)
        
        # Define an output filename for the upgraded file with linked weights.
        upgrade_output_filename = f"{community_name}_upgrade{str(i).zfill(2)}_metadata_and_annual_results_downsampled_with_inflation_adj_income_energy_burden_and_adjusted_income_distribution.csv"
        upgrade_output_filepath = os.path.join(csv_output_directory, upgrade_output_filename)
        
        df_upgrade.to_csv(upgrade_output_filepath, index=False)
        print(f"Linked upgrade file saved to: {upgrade_output_filepath}")
    else:
        print(f"Upgrade file not found: {upgrade_filepath}")


# ========================================================
# # PLOTTING THE INCOME DISTRIBUTION FROM THE BASELINE FILE
# ========================================================
distribution_plots_dir = os.path.join(csv_output_directory, "distribution_plots")
if not os.path.exists(distribution_plots_dir):
    os.makedirs(distribution_plots_dir)

# PLOTTING: Income Distribution Plot
# For income, we use a predefined order and labels.
ordered_income_keys = [
    "<10000", "10000-14999", "15000-19999", "20000-24999", "25000-29999",
    "30000-34999", "35000-39999", "40000-44999", "45000-49999", "50000-59999",
    "60000-69999", "70000-79999", "80000-99999", "100000-119999", "120000-139999",
    "140000-159999", "160000-179999", "180000-199999", "200000+", "Not Available"
]

income_labels = {
    "<10000": "Less than $10,000",
    "10000-14999": "$10,000 to $14,999",
    "15000-19999": "$15,000 to $24,999",
    "20000-24999": "$15,000 to $24,999",
    "25000-29999": "$25,000 to $34,999",
    "30000-34999": "$25,000 to $34,999",
    "35000-39999": "$35,000 to $49,999",
    "40000-44999": "$35,000 to $49,999",
    "45000-49999": "$35,000 to $49,999",
    "50000-59999": "$50,000 to $74,999",
    "60000-69999": "$50,000 to $74,999",
    "70000-79999": "$50,000 to $74,999",
    "80000-99999": "$75,000 to $99,999",
    "100000-119999": "$100,000 to $149,999",
    "120000-139999": "$100,000 to $149,999",
    "140000-159999": "$100,000 to $149,999",
    "160000-179999": "$150,000 to $199,999",
    "180000-199999": "$150,000 to $199,999",
    "200000+": "$200,000 or more",
    "Not Available": "Not Available"
}

# Compute distributions for in.income:
orig_counts = df.groupby('in.income').size()
orig_percent = 100 * orig_counts / orig_counts.sum()

reweighted_units = df.groupby('in.income')['bldg_reweighed_units'].sum()
reweighted_percent = 100 * reweighted_units / reweighted_units.sum()

puma_df = df[df['in.puma'] == "G12009505"]
puma_counts = puma_df.groupby('in.income').size()
puma_percent = 100 * puma_counts / puma_counts.sum()

# Reindex using our ordered keys:
orig_percent = orig_percent.reindex(ordered_income_keys, fill_value=0)
reweighted_percent = reweighted_percent.reindex(ordered_income_keys, fill_value=0)
puma_percent = puma_percent.reindex(ordered_income_keys, fill_value=0)

x = np.arange(len(ordered_income_keys))
width = 0.25

fig, ax = plt.subplots(figsize=(14, 8))
bars_orig = ax.bar(x - width, orig_percent.values, width, label='Original Count (All Data)', color='skyblue', alpha=0.8)
bars_reweighted = ax.bar(x, reweighted_percent.values, width, label='Reweighted (All Data)', color='salmon', alpha=0.8)
bars_puma = ax.bar(x + width, puma_percent.values, width, label='Count (PUMA G12009505)', color='mediumseagreen', alpha=0.8)

ax.set_ylabel('Percentage (%)')
ax.set_title('Income Distribution Comparison')
ax.set_xticks(x)
ax.set_xticklabels([income_labels[k] for k in ordered_income_keys], rotation=45, ha='right')
ax.legend()

def autolabel(bars):
    for bar in bars:
        height = bar.get_height()
        ax.annotate(f'{height:.1f}%',
                    xy=(bar.get_x() + bar.get_width()/2, height),
                    xytext=(0, 3), textcoords="offset points",
                    ha='center', va='bottom', fontsize=8)

autolabel(bars_orig)
autolabel(bars_reweighted)
autolabel(bars_puma)

plt.tight_layout()

plot_output_filepath = os.path.join(distribution_plots_dir, "income_distribution_comparison.png")
plt.savefig(plot_output_filepath)
print(f"Income distribution plot saved to: {plot_output_filepath}")
plt.close(fig)

# ============================
# PLOTTING: Other Columns Distribution Plots
# ============================
# List of additional columns (excluding 'in.income' since it's already plotted)
columns_to_plot = [
    'in.ashrae_iecc_climate_zone_2004',
    'in.state',
    'in.geometry_building_type_recs',
    'in.heating_fuel',
    'in.hvac_cooling_type',
    'in.tenure',
    'in.water_heater_fuel',
    'in.vintage_acs',
    'in.geometry_floor_area_bin',
    'in.hvac_heating_type',
    'in.federal_poverty_level',
    'in.vacancy_status'
]

for col in columns_to_plot:
    # Replace missing values with "Not Available"
    df[col] = df[col].fillna("Not Available")
    # Determine sorted categories (alphabetically)
    categories = sorted(df[col].unique())
    
    # 1. Original Count Distribution
    orig_counts = df.groupby(col).size()
    orig_percent = 100 * orig_counts / orig_counts.sum()
    
    # 2. Reweighted Distribution (using bldg_reweighed_units)
    reweighted_units = df.groupby(col)['bldg_reweighed_units'].sum()
    reweighted_percent = 100 * reweighted_units / reweighted_units.sum()
    
    # 3. Count Distribution for PUMA G12009505
    puma_df = df[df['in.puma'] == "G12009505"]
    puma_counts = puma_df.groupby(col).size()
    puma_percent = 100 * puma_counts / puma_counts.sum()
    
    # Reindex to ensure all categories are present
    orig_percent = orig_percent.reindex(categories, fill_value=0)
    reweighted_percent = reweighted_percent.reindex(categories, fill_value=0)
    puma_percent = puma_percent.reindex(categories, fill_value=0)
    
    x = np.arange(len(categories))
    width = 0.25
    
    fig, ax = plt.subplots(figsize=(14, 8))
    bars_orig = ax.bar(x - width, orig_percent.values, width, label='Original Count (All Data)', color='skyblue', alpha=0.8)
    bars_reweighted = ax.bar(x, reweighted_percent.values, width, label='Reweighted (All Data)', color='salmon', alpha=0.8)
    bars_puma = ax.bar(x + width, puma_percent.values, width, label='Count (PUMA G12009505)', color='mediumseagreen', alpha=0.8)
    
    ax.set_ylabel('Percentage (%)')
    ax.set_title(f'Distribution Comparison for {col}')
    ax.set_xticks(x)
    ax.set_xticklabels(categories, rotation=45, ha='right')
    ax.legend()
    
    def autolabel(bars):
        for bar in bars:
            height = bar.get_height()
            ax.annotate(f'{height:.1f}%',
                        xy=(bar.get_x() + bar.get_width()/2, height),
                        xytext=(0, 3), textcoords="offset points",
                        ha='center', va='bottom', fontsize=8)
    
    autolabel(bars_orig)
    autolabel(bars_reweighted)
    autolabel(bars_puma)
    
    plt.tight_layout()
    # Save the figure, replacing dots in column name with underscores.
    plot_filename = f"{col.replace('.', '_')}_distribution_comparison.png"
    plot_filepath = os.path.join(distribution_plots_dir, plot_filename)
    plt.savefig(plot_filepath)
    print(f"Plot for {col} saved to: {plot_filepath}")
    plt.close(fig)