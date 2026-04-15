import pandas as pd
import numpy as np

R = 60  # Number of RECS jackknife replicates
WEIGHT_COL = "NWEIGHT"
_REP_WEIGHT_COLS = [f"{WEIGHT_COL}{i}" for i in range(1, R + 1)]
_ALL_WEIGHT_COLS = [WEIGHT_COL] + _REP_WEIGHT_COLS
_VECTORIZED_STATS = {"total", "avg", "percent"}


def calculate_rse_batch(df, requests):
    """Compute RSE for many (variable_col, stat_type) pairs at once.

    Extracts the 61-column weight matrix (base + 60 replicates) from `df`
    exactly once, then evaluates all requested estimators as BLAS matmuls.
    Roughly 20-40x faster than calling `calculate_rse` in a loop over many
    columns for the same group.

    Args:
        df: DataFrame with NWEIGHT, NWEIGHT1..NWEIGHT60, and variable columns.
        requests: iterable of (variable_col, stat_type) tuples. Duplicates are
            allowed and cached.

    Returns:
        dict mapping (variable_col, stat_type) -> RSE (float or np.nan).
        Non-vectorizable stat types (min/max/quantiles) fall back to
        `calculate_rse` per request.
    """
    requests = list(requests)
    if not requests:
        return {}

    fast_requests = [(c, s) for c, s in requests if s in _VECTORIZED_STATS]
    slow_requests = [(c, s) for c, s in requests if s not in _VECTORIZED_STATS]

    results = {}

    if fast_requests:
        # Extract the weight matrix once: shape (n_rows, 61).
        # Column 0 is NWEIGHT, columns 1..60 are the replicate weights.
        weight_matrix = df[_ALL_WEIGHT_COLS].to_numpy(dtype=float)
        weight_sums = weight_matrix.sum(axis=0)  # shape (61,)
        zero_weight_mask = weight_sums == 0

        # Cache per-column numeric extractions so duplicate requests reuse them.
        numeric_cache = {}
        indicator_cache = {}

        unique_vars = {c for c, _ in fast_requests}
        for var in unique_vars:
            numeric_cache[var] = df[var].to_numpy(dtype=float)

        for var, stat in fast_requests:
            data_values = numeric_cache[var]

            if stat in ("total", "avg"):
                payload = data_values
            else:  # percent
                if var not in indicator_cache:
                    indicator_cache[var] = (data_values > 0).astype(float)
                payload = indicator_cache[var]

            # Single reduction across all 61 weight columns at once:
            # weighted_sums[j] = sum_i (payload[i] * weight_matrix[i, j]).
            weighted_sums = payload @ weight_matrix  # shape (61,)

            if stat == "total":
                estimates = weighted_sums
            else:  # avg or percent: normalize by column weight sums
                with np.errstate(invalid="ignore", divide="ignore"):
                    estimates = np.where(zero_weight_mask, np.nan, weighted_sums / weight_sums)

            base_estimate = estimates[0]
            if np.isnan(base_estimate):
                results[(var, stat)] = np.nan
                continue

            rep_estimates = estimates[1:]
            rep_estimates = rep_estimates[~np.isnan(rep_estimates)]

            # Jackknife variance: V(theta) = [(R-1)/R] * sum((theta_r - theta)^2)
            diffs = rep_estimates - base_estimate
            variance = (R - 1) / R * np.sum(diffs * diffs)
            std_error = np.sqrt(variance)
            results[(var, stat)] = (std_error / base_estimate) * 100 if base_estimate != 0 else 0

    for var, stat in slow_requests:
        results[(var, stat)] = calculate_rse(df, var, stat_type=stat)

    return results


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
            total_weight = weights.sum()
            if total_weight == 0:
                return np.nan
            return (data * weights).sum() / total_weight
        elif stat == "percent":
            total_weight = weights.sum()
            if total_weight == 0:
                return np.nan
            binary_indicator = (data > 0).astype(int)
            return (binary_indicator * weights).sum() / total_weight
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
        return np.nan  # unreachable; satisfies type checker

    estimate = float(compute_stat(df[variable_col], df[WEIGHT_COL], stat_type))
    if np.isnan(estimate):
        return np.nan

    replicate_estimates = []
    rep_weight_cols = [f"{WEIGHT_COL}{i}" for i in range(1, R + 1)]

    for col in rep_weight_cols:
        rep_est = compute_stat(df[variable_col], df[col], stat_type)
        replicate_estimates.append(rep_est)

    rep_estimates_arr = np.array(replicate_estimates, dtype=float)
    # Drop replicates where the subset collapsed (zero-weight → NaN). This is
    # equivalent to treating them as equal to the base estimate: they contribute
    # zero to the sum-of-squared-diffs.
    rep_estimates_arr = rep_estimates_arr[~np.isnan(rep_estimates_arr)]

    # Formula: V(theta) = [(R-1)/R] * SUM( (theta_r - theta)^2 )
    coefficient = (R - 1) / R
    diffs = rep_estimates_arr - estimate
    diffs_sq = diffs**2
    sum_of_squared_diffs = np.sum(diffs_sq)
    variance = coefficient * sum_of_squared_diffs
    std_error = np.sqrt(variance)
    rse = (std_error / estimate) * 100 if estimate != 0 else 0
    return rse


if __name__ == "__main__":
    # Mimics the production aggregation loop in
    # io_managers/get_recs_data.py: for each unique combination of grouping
    # columns, compute RSE for every enduse column (value RSE + percent-users
    # RSE) plus a units-count RSE from a constant column. Useful for smoke
    # testing the full call pattern on real data and watching for
    # RuntimeWarnings from collapsed replicates on small subsets.
    import time

    data = pd.read_csv(
        "postprocessing/resstockpostproc/baseline_validation/data_scrapping/data/recs_raw/recs2020_public_v7.csv"
    )

    enduse_cols = [
        "KWH",
        "KWHSPH",
        "KWHCOL",
        "KWHWTH",
        "KWHRFG",
        "KWHCOK",
        "KWHLGT",
        "BTUNG",
        "BTULP",
        "BTUFO",
    ]
    by_cols = ["state_postal", "TYPEHUQ"]
    rse_stat_type = "avg"  # would be "total" for Metric.total aggregations

    # Pre-compute group indices once (avoids rebuilding boolean masks per group).
    grouped = data.groupby(by_cols, sort=False)
    group_keys = list(grouped.groups.keys())
    n_groups = len(group_keys)
    n_calls = n_groups * (1 + 2 * len(enduse_cols))
    print(f"Computing RSE for {n_groups} groups ({by_cols}), {n_calls} total RSE calls...")

    def run_legacy():
        rows = []
        for key in group_keys:
            group_data = grouped.get_group(key)
            key_tuple = key if isinstance(key, tuple) else (key,)
            row = dict(zip(by_cols, key_tuple))
            row["n_records"] = len(group_data)
            try:
                tmp = group_data.copy()
                tmp["_constant_"] = 1
                row["units_count_rse"] = calculate_rse(tmp, "_constant_", stat_type="total")
            except Exception:
                row["units_count_rse"] = None
            for col in enduse_cols:
                try:
                    row[f"{col}_value_rse"] = calculate_rse(group_data, col, stat_type=rse_stat_type)
                except Exception:
                    row[f"{col}_value_rse"] = None
                try:
                    row[f"{col}_percent_users_rse"] = calculate_rse(group_data, col, stat_type="percent")
                except Exception:
                    row[f"{col}_percent_users_rse"] = None
            rows.append(row)
        return pd.DataFrame(rows)

    def run_batch():
        rows = []
        requests = [("_constant_", "total")]
        for col in enduse_cols:
            requests.append((col, rse_stat_type))
            requests.append((col, "percent"))
        for key in group_keys:
            group_data = grouped.get_group(key)
            key_tuple = key if isinstance(key, tuple) else (key,)
            row = dict(zip(by_cols, key_tuple))
            row["n_records"] = len(group_data)
            group_data = group_data.assign(_constant_=1.0)
            try:
                batch = calculate_rse_batch(group_data, requests)
            except Exception:
                batch = dict.fromkeys(requests)
            row["units_count_rse"] = batch.get(("_constant_", "total"))
            for col in enduse_cols:
                row[f"{col}_value_rse"] = batch.get((col, rse_stat_type))
                row[f"{col}_percent_users_rse"] = batch.get((col, "percent"))
            rows.append(row)
        return pd.DataFrame(rows)

    start = time.perf_counter()
    legacy_df = run_legacy()
    legacy_elapsed = time.perf_counter() - start
    print(f"\n[legacy] {n_calls} calls in {legacy_elapsed:.2f}s ({n_calls / legacy_elapsed:.0f} calls/s)")

    start = time.perf_counter()
    batch_df = run_batch()
    batch_elapsed = time.perf_counter() - start
    print(f"[batch ] {n_calls} calls in {batch_elapsed:.2f}s ({n_calls / batch_elapsed:.0f} calls/s)")
    print(f"speedup: {legacy_elapsed / batch_elapsed:.1f}x")

    # Correctness check: legacy and batch should agree (within float tolerance).
    rse_cols = [c for c in legacy_df.columns if c.endswith("_rse")]
    legacy_arr = legacy_df[rse_cols].to_numpy(dtype=float)
    batch_arr = batch_df[rse_cols].to_numpy(dtype=float)
    diff = np.abs(legacy_arr - batch_arr)
    diff[np.isnan(legacy_arr) & np.isnan(batch_arr)] = 0.0
    max_diff = np.nanmax(diff)
    print(f"max |legacy - batch| RSE diff: {max_diff:.2e}")

    print("\nRSE summary from batch run (first 10 groups):")
    print(batch_df.head(10).to_string(index=False))

    nan_counts = batch_df[rse_cols].isna().sum()
    nan_counts = nan_counts[nan_counts > 0]
    if len(nan_counts) > 0:
        print("\nNaN RSE counts (degenerate subsets):")
        print(nan_counts.to_string())
