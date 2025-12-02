import pandas as pd
import numpy as np

# --- Create a Mock DataFrame for Demonstration ---
# This simulates the RECS data structure so the example is runnable
# In your real code, you would just load your CSV or SAS file into 'df'
N_ROWS = 5000  # Number of households in the sample
R = 60  # Number of replicates


WEIGHT_COL = "NWEIGHT"


def calculate_rse(df, variable_col, stat_type="total"):
    """
    Calculates the RSE for various statistics using the Jackknife method.
    Based on: https://www.eia.gov/consumption/residential/data/2020/pdf/microdata-guide.pdf
    RSE is verified to match published RECS values for state annual aggregation.

    Args:
        df: DataFrame with RECS data
        variable_col: Column name for the variable to analyze
        stat_type: One of 'total', 'avg', 'percent', 'min', 'max', 'q1', 'q2', 'median', 'q3'
    """
    valid_stats = ["total", "avg", "percent", "min", "max", "q1", "q2", "median", "q3"]
    if stat_type not in valid_stats:
        raise ValueError(f"stat_type must be one of {valid_stats}")

    def compute_stat(data, weights, stat):
        if stat == "total":
            return (data * weights).sum()
        elif stat == "avg":
            return (data * weights).sum() / weights.sum()
        elif stat == "percent":
            # Percent/proportion: weighted mean of binary indicator (data > 0)
            binary_indicator = (data > 0).astype(int)
            return (binary_indicator * weights).sum() / weights.sum()
        elif stat == "min":
            mask = weights > 0
            return data[mask].min()
        elif stat == "max":
            mask = weights > 0
            return data[mask].max()
        elif stat in ["q1", "q2", "median", "q3"]:
            quantile = {"q1": 0.25, "q2": 0.5, "median": 0.5, "q3": 0.75}[stat]
            # Weighted quantile calculation
            mask = weights > 0
            sorted_indices = np.argsort(data[mask])
            sorted_data = data[mask].values[sorted_indices]
            sorted_weights = weights[mask].values[sorted_indices]
            cumsum_weights = np.cumsum(sorted_weights)
            total_weight = cumsum_weights[-1]
            target = quantile * total_weight
            idx = np.searchsorted(cumsum_weights, target)
            return sorted_data[min(idx, len(sorted_data) - 1)]

    estimate = compute_stat(df[variable_col], df[WEIGHT_COL], stat_type)
    replicate_estimates = []
    rep_weight_cols = [f"{WEIGHT_COL}{i}" for i in range(1, R + 1)]

    for col in rep_weight_cols:
        rep_est = compute_stat(df[variable_col], df[col], stat_type)
        replicate_estimates.append(rep_est)

    # Formula: V(theta) = [(R-1)/R] * SUM( (theta_r - theta)^2 )
    coefficient = (R - 1) / R
    rep_estimates_arr = np.array(replicate_estimates)
    diffs = rep_estimates_arr - estimate
    diffs_sq = diffs**2
    sum_of_squared_diffs = np.sum(diffs_sq)
    variance = coefficient * sum_of_squared_diffs
    std_error = np.sqrt(variance)
    rse = (std_error / estimate) * 100 if estimate != 0 else 0
    return rse


if __name__ == "__main__":
    # --- Run the Calculation ---
    var_col = "BTUEL"
    weight_col = "NWEIGHT"  # This is the base name
    data = pd.read_csv(
        "postprocessing/resstockpostproc/baseline_validation/data_scrapping/data/recs_raw/recs2020_public_v7.csv"
    )
    data =  data[data["state_postal"].str.upper() == "CO"]
    # Calculate RSE for all statistics
    stat_types = ["total", "average", "min", "max", "q1", "q2", "median", "q3"]
    results = []

    for stat_type in stat_types:
        rse = calculate_rse(data, var_col, stat_type=stat_type)
        results.append({"statistic": stat_type, "rse": rse})

    # Sort by RSE (lowest to highest)
    results_df = pd.DataFrame(results).sort_values("rse")

    print(f"RSE values for {var_col} (sorted lowest to highest):")
    print(results_df.to_string(index=False))
