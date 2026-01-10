"""Reference Data Loader
---------------------
Functions for loading and processing reference data (EIA, LRD, etc.) for validation
"""

from pathlib import Path

import polars as pl
import numpy as np
from resstockpostproc.shared_utils.mapping import NUM2MONTH
from resstockpostproc.shared_utils.s3_manager import get_df_from_s3
from . import truth_data_paths as s3_paths
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow
from resstockpostproc.baseline_validation.schema.recs_enduse_mapping import RECS_ENDUSE_MAP
from resstockpostproc.baseline_validation.data_processing.recs_rse import calculate_rse
from resstockpostproc.shared_utils.caching import cached
from typing import Literal
from resstockpostproc.baseline_validation.schema.plot_spec import DataKey, AggregationType, CoverageType


local_data_dir = Path(f"{workflow.output.output_dir}/data")


def _calculate_weighted_quantiles(data: np.ndarray, weights: np.ndarray, quantiles: list[float]) -> np.ndarray:
    """Calculate weighted quantiles.

    Args:
        data: Data values
        weights: Weights for each data value
        quantiles: List of quantiles to calculate (between 0 and 1)

    Returns:
        Array of quantile values
    """
    # Sort data and weights by data values
    sorted_indices = np.argsort(data)
    sorted_data = data[sorted_indices]
    sorted_weights = weights[sorted_indices]

    # Calculate cumulative weights
    cumsum_weights = np.cumsum(sorted_weights)
    total_weight = cumsum_weights[-1]

    # Normalize cumulative weights to [0, 1]
    cumsum_normalized = cumsum_weights / total_weight

    # Calculate quantiles
    result = np.zeros(len(quantiles))
    for i, q in enumerate(quantiles):
        if q == 0:
            result[i] = sorted_data[0]
        elif q == 1:
            result[i] = sorted_data[-1]
        else:
            # Find the index where cumulative weight exceeds quantile
            idx = np.searchsorted(cumsum_normalized, q)
            if idx == 0:
                result[i] = sorted_data[0]
            elif idx >= len(sorted_data):
                result[i] = sorted_data[-1]
            else:
                # Linear interpolation
                w0 = cumsum_normalized[idx - 1]
                w1 = cumsum_normalized[idx]
                v0 = sorted_data[idx - 1]
                v1 = sorted_data[idx]
                if w1 - w0 > 0:
                    result[i] = v0 + (v1 - v0) * (q - w0) / (w1 - w0)
                else:
                    result[i] = v0

    return result


# @cached(cache_file="recs_annual_data_cache")
def get_annual_all(
    data_key: DataKey,
    year: int = 2020,
) -> pl.DataFrame:
    """Get annual RECS data aggregated by the specified level.

    Args:
        data_key: DataKey containing aggregation_level, aggregation_type, and coverage
        year: Year of RECS data (only 2020 supported)
    """
    if year != 2020:
        raise ValueError("RECS data is only available for the year 2020.")

    by = data_key.aggregation_level
    mdf = get_df_from_s3(s3_paths.RECS_2020_microdata, local_data_dir)
    enduse_cols = tuple(RECS_ENDUSE_MAP.keys())

    if by:
        # Calculate value columns based on aggregation type
        if data_key.aggregation_type == AggregationType.total:
            # Stock energy: weighted sum
            result_df = mdf.group_by(by).agg(
                pl.len().alias("sample_count"),
                pl.col("NWEIGHT").sum().alias("units_count"),
                *((pl.col(col) * pl.col("NWEIGHT")).sum().alias(f"{col}_value") for col in enduse_cols),
                *(
                    (
                        ((pl.col(col) > 0).cast(pl.Int64) * pl.col("NWEIGHT")).sum() / pl.col("NWEIGHT").sum() * 100
                    ).alias(f"{col}_percent_users")
                    for col in enduse_cols
                ),
            )
        elif data_key.coverage == CoverageType.all_units:
            # Per-unit energy: weighted mean (sum of weighted values / sum of all weights)
            result_df = mdf.group_by(by).agg(
                pl.len().alias("sample_count"),
                pl.col("NWEIGHT").sum().alias("units_count"),
                *(
                    ((pl.col(col) * pl.col("NWEIGHT")).sum() / pl.col("NWEIGHT").sum()).alias(f"{col}_value")
                    for col in enduse_cols
                ),
                *(
                    (
                        ((pl.col(col) > 0).cast(pl.Int64) * pl.col("NWEIGHT")).sum() / pl.col("NWEIGHT").sum() * 100
                    ).alias(f"{col}_percent_users")
                    for col in enduse_cols
                ),
            )
        else:
            # Per-user energy: weighted mean (sum of weighted values / sum of weights for non-zero values only)
            result_df = mdf.group_by(by).agg(
                pl.len().alias("sample_count"),
                pl.col("NWEIGHT").sum().alias("units_count"),
                *(
                    (
                        (pl.col(col) * pl.col("NWEIGHT")).sum()
                        / ((pl.col(col) > 0).cast(pl.Int64) * pl.col("NWEIGHT")).sum()
                    ).alias(f"{col}_value")
                    for col in enduse_cols
                ),
                *(
                    (
                        ((pl.col(col) > 0).cast(pl.Int64) * pl.col("NWEIGHT")).sum() / pl.col("NWEIGHT").sum() * 100
                    ).alias(f"{col}_percent_users")
                    for col in enduse_cols
                ),
            )

        # Calculate RSE and quartiles by group
        # Convert to pandas for RSE calculation
        mdf_pd = mdf.to_pandas()
        rse_results = []
        quartile_results = []
        nonzero_quartile_results = []

        # Determine RSE stat type based on aggregation
        rse_stat_type = "total" if aggregation == "sum" else "avg"

        for group_value in mdf.select(by).unique().to_series():
            group_data = mdf_pd[mdf_pd[by] == group_value]
            rse_row = {by: group_value}
            quartile_row = {by: group_value}
            nonzero_quartile_row = {by: group_value}

            # Calculate units_count_rse (RSE of the sum of weights)
            # Create a constant column of 1s to calculate RSE of weight sum
            try:
                # For units_count RSE, we treat it as a "total" of a constant (1) variable
                group_data_temp = group_data.copy()
                group_data_temp["_constant_"] = 1
                units_count_rse = calculate_rse(group_data_temp, "_constant_", stat_type="total")
                rse_row["units_count_rse"] = units_count_rse
            except Exception:
                rse_row["units_count_rse"] = None

            for col in enduse_cols:
                try:
                    rse = calculate_rse(group_data, col, stat_type=rse_stat_type)
                    rse_row[f"{col}_value_rse"] = rse
                except Exception:
                    # If RSE calculation fails, set to None
                    rse_row[f"{col}_value_rse"] = None

                # Calculate RSE for percent_users (binary indicator: col > 0)
                try:
                    # For percent_users, we calculate RSE of the proportion/mean of the binary indicator
                    rse_percent_users = calculate_rse(group_data, col, stat_type="percent")
                    rse_row[f"{col}_percent_users_rse"] = rse_percent_users
                except Exception:
                    rse_row[f"{col}_percent_users_rse"] = None

                # Calculate quartiles for the column
                try:
                    data_values = group_data[col].values
                    weights = group_data["NWEIGHT"].values
                    if len(data_values) > 0:
                        # Calculate weighted quartiles
                        quantiles = [0, 0.02, 0.1, 0.25, 0.5, 0.75, 0.9, 0.98, 1]
                        quartiles = _calculate_weighted_quantiles(data_values, weights, quantiles)
                        quartile_row[f"{col}_quartiles"] = quartiles.tolist()
                    else:
                        quartile_row[f"{col}_quartiles"] = [0.0] * 9
                except Exception:
                    quartile_row[f"{col}_quartiles"] = [0.0] * 9

                # Calculate nonzero quartiles for the column (exclude zeros)
                try:
                    data_values = group_data[col].values
                    weights = group_data["NWEIGHT"].values
                    non_zero_mask = data_values > 0
                    data_values_nonzero = data_values[non_zero_mask]
                    weights_nonzero = weights[non_zero_mask]
                    if len(data_values_nonzero) > 0:
                        # Calculate weighted quartiles for non-zero values
                        quantiles = [0, 0.02, 0.1, 0.25, 0.5, 0.75, 0.9, 0.98, 1]
                        nonzero_quartiles = _calculate_weighted_quantiles(
                            data_values_nonzero, weights_nonzero, quantiles
                        )
                        nonzero_quartile_row[f"{col}_nonzero_quartiles"] = nonzero_quartiles.tolist()
                    else:
                        nonzero_quartile_row[f"{col}_nonzero_quartiles"] = [0.0] * 9
                except Exception:
                    nonzero_quartile_row[f"{col}_nonzero_quartiles"] = [0.0] * 9

            rse_results.append(rse_row)
            quartile_results.append(quartile_row)
            nonzero_quartile_results.append(nonzero_quartile_row)

        # Convert RSE and quartile results to polars and join with value results
        rse_df = pl.DataFrame(rse_results)
        quartile_df = pl.DataFrame(quartile_results)
        nonzero_quartile_df = pl.DataFrame(nonzero_quartile_results)
        result_df = result_df.join(rse_df, on=by, how="left")
        result_df = result_df.join(quartile_df, on=by, how="left")
        result_df = result_df.join(nonzero_quartile_df, on=by, how="left")

        # Add US Total values
        if aggregation == "sum":
            # For sum: calculate US Total from full microdata
            us_total_values = {}
            us_total_values[by] = "US Total"
            us_total_values["sample_count"] = len(mdf)
            us_total_values["units_count"] = mdf["NWEIGHT"].sum()
            for col in enduse_cols:
                # Calculate weighted sum from full microdata
                weighted_sum = (mdf[col] * mdf["NWEIGHT"]).sum()
                us_total_values[f"{col}_value"] = weighted_sum

                weight_sum = mdf["NWEIGHT"].sum()
                nonzero_weight_sum = ((mdf[col] > 0).cast(pl.Int64) * mdf["NWEIGHT"]).sum()
                us_total_values[f"{col}_percent_users"] = (
                    (nonzero_weight_sum / weight_sum * 100) if weight_sum > 0 else 0
                )

            # Add US Total row to result_df
            us_total_df = pl.DataFrame([us_total_values])
            result_df = pl.concat([result_df, us_total_df], how="diagonal_relaxed")
        elif aggregation == "per_unit_avg":
            # For per_unit_avg: calculate US Total from full microdata (can't sum averages)
            us_total_values = {}
            us_total_values[by] = "US Total"
            us_total_values["sample_count"] = len(mdf)
            us_total_values["units_count"] = mdf["NWEIGHT"].sum()
            for col in enduse_cols:
                # Calculate weighted mean from full microdata (all units)
                weighted_sum = (mdf[col] * mdf["NWEIGHT"]).sum()
                weight_sum = (mdf["NWEIGHT"]).sum()
                avg_value = weighted_sum / weight_sum if weight_sum > 0 else 0
                us_total_values[f"{col}_value"] = avg_value
                nonzero_weight_sum = ((mdf[col] > 0).cast(pl.Int64) * mdf["NWEIGHT"]).sum()
                us_total_values[f"{col}_percent_users"] = (
                    (nonzero_weight_sum / weight_sum * 100) if weight_sum > 0 else 0
                )

            # Add US Total row to result_df
            us_total_df = pl.DataFrame([us_total_values])
            result_df = pl.concat([result_df, us_total_df], how="diagonal_relaxed")
        else:  # aggregation == "per_user_avg"
            # For per_user_avg: calculate US Total from full microdata (only non-zero values)
            us_total_values = {}
            us_total_values[by] = "US Total"
            us_total_values["sample_count"] = len(mdf)
            us_total_values["units_count"] = mdf["NWEIGHT"].sum()
            for col in enduse_cols:
                # Calculate weighted mean from full microdata (non-zero values only)
                weighted_sum = (mdf[col] * mdf["NWEIGHT"]).sum()
                customer_weight_sum = ((mdf[col] > 0).cast(pl.Int64) * mdf["NWEIGHT"]).sum()
                total_weight_sum = mdf["NWEIGHT"].sum()
                avg_value = weighted_sum / customer_weight_sum if customer_weight_sum > 0 else 0
                us_total_values[f"{col}_value"] = avg_value
                us_total_values[f"{col}_percent_users"] = (
                    customer_weight_sum / total_weight_sum * 100 if total_weight_sum > 0 else 0
                )

            # Add US Total row to result_df
            us_total_df = pl.DataFrame([us_total_values])
            result_df = pl.concat([result_df, us_total_df], how="diagonal_relaxed")

        # Calculate RSE and quartiles for US Total from full microdata
        # (must be done AFTER calculating US Total values to avoid overwriting)
        us_total_rse_dict = {}
        us_total_quartile_dict = {}
        us_total_nonzero_quartile_dict = {}

        # Calculate units_count_rse for US Total
        try:
            mdf_pd_temp = mdf_pd.copy()
            mdf_pd_temp["_constant_"] = 1
            units_count_rse = calculate_rse(mdf_pd_temp, "_constant_", stat_type="total")
            us_total_rse_dict["units_count_rse"] = units_count_rse
        except Exception:
            us_total_rse_dict["units_count_rse"] = None

        for col in enduse_cols:
            try:
                rse = calculate_rse(mdf_pd, col, stat_type=rse_stat_type)
                us_total_rse_dict[f"{col}_value_rse"] = rse
            except Exception:
                # If RSE calculation fails, set to None
                us_total_rse_dict[f"{col}_value_rse"] = None

            # Calculate RSE for percent_users
            try:
                rse_percent_users = calculate_rse(mdf_pd, col, stat_type="percent")
                us_total_rse_dict[f"{col}_percent_users_rse"] = rse_percent_users
            except Exception:
                us_total_rse_dict[f"{col}_percent_users_rse"] = None

            # Calculate quartiles for US Total
            try:
                data_values = mdf_pd[col].values
                weights = mdf_pd["NWEIGHT"].values
                if len(data_values) > 0:
                    quantiles = [0, 0.02, 0.1, 0.25, 0.5, 0.75, 0.9, 0.98, 1]
                    quartiles = _calculate_weighted_quantiles(data_values, weights, quantiles)
                    us_total_quartile_dict[f"{col}_quartiles"] = quartiles.tolist()
                else:
                    us_total_quartile_dict[f"{col}_quartiles"] = [0.0] * 9
            except Exception:
                us_total_quartile_dict[f"{col}_quartiles"] = [0.0] * 9

            # Calculate nonzero quartiles for US Total
            try:
                data_values = mdf_pd[col].values
                weights = mdf_pd["NWEIGHT"].values
                non_zero_mask = data_values > 0
                data_values_nonzero = data_values[non_zero_mask]
                weights_nonzero = weights[non_zero_mask]
                if len(data_values_nonzero) > 0:
                    quantiles = [0, 0.02, 0.1, 0.25, 0.5, 0.75, 0.9, 0.98, 1]
                    nonzero_quartiles = _calculate_weighted_quantiles(data_values_nonzero, weights_nonzero, quantiles)
                    us_total_nonzero_quartile_dict[f"{col}_nonzero_quartiles"] = nonzero_quartiles.tolist()
                else:
                    us_total_nonzero_quartile_dict[f"{col}_nonzero_quartiles"] = [0.0] * 9
            except Exception:
                us_total_nonzero_quartile_dict[f"{col}_nonzero_quartiles"] = [0.0] * 9

        # Update the US Total row with correct RSE and quartile values
        for col, rse_value in us_total_rse_dict.items():
            result_df = result_df.with_columns(
                pl.when(pl.col(by) == "US Total").then(pl.lit(rse_value)).otherwise(pl.col(col)).alias(col)
            )
        for col, quartile_value in us_total_quartile_dict.items():
            result_df = result_df.with_columns(
                pl.when(pl.col(by) == "US Total").then(pl.lit(quartile_value)).otherwise(pl.col(col)).alias(col)
            )
        for col, nonzero_quartile_value in us_total_nonzero_quartile_dict.items():
            result_df = result_df.with_columns(
                pl.when(pl.col(by) == "US Total").then(pl.lit(nonzero_quartile_value)).otherwise(pl.col(col)).alias(col)
            )
    else:
        # Calculate value columns based on aggregation type
        if aggregation == "sum":
            # Stock energy: weighted sum
            result_df = mdf.select(
                pl.len().alias("sample_count"),
                pl.col("NWEIGHT").sum().alias("units_count"),
                *((pl.col(col) * pl.col("NWEIGHT")).sum().alias(f"{col}_value") for col in enduse_cols),
            )
        elif aggregation == "per_unit_avg":
            # Per-unit energy: weighted mean (sum of weighted values / sum of all weights)
            result_df = mdf.select(
                pl.len().alias("sample_count"),
                pl.col("NWEIGHT").sum().alias("units_count"),
                *(
                    ((pl.col(col) * pl.col("NWEIGHT")).sum() / pl.col("NWEIGHT").sum()).alias(f"{col}_value")
                    for col in enduse_cols
                ),
            )
        else:  # aggregation == "per_user_avg"
            # Per-user energy: weighted mean (sum of weighted values / sum of weights for non-zero values only)
            result_df = mdf.select(
                pl.len().alias("sample_count"),
                pl.col("NWEIGHT").sum().alias("units_count"),
                *(
                    (
                        (pl.col(col) * pl.col("NWEIGHT")).sum()
                        / ((pl.col(col) > 0).cast(pl.Int64) * pl.col("NWEIGHT")).sum()
                    ).alias(f"{col}_value")
                    for col in enduse_cols
                ),
            )

        # Calculate RSE and quartiles
        # Convert to pandas for RSE calculation
        mdf_pd = mdf.to_pandas()
        rse_dict = {}
        quartile_dict = {}
        nonzero_quartile_dict = {}

        # Determine RSE stat type based on aggregation
        rse_stat_type = "total" if aggregation == "sum" else "mean"

        # Calculate units_count_rse
        try:
            mdf_pd_temp = mdf_pd.copy()
            mdf_pd_temp["_constant_"] = 1
            units_count_rse = calculate_rse(mdf_pd_temp, "_constant_", stat_type="total")
            rse_dict["units_count_rse"] = [units_count_rse]
        except Exception:
            rse_dict["units_count_rse"] = [None]

        for col in enduse_cols:
            try:
                rse = calculate_rse(mdf_pd, col, stat_type=rse_stat_type)
                rse_dict[f"{col}_value_rse"] = [rse]
            except Exception:
                # If RSE calculation fails, set to None
                rse_dict[f"{col}_value_rse"] = [None]

            # Calculate RSE for percent_users
            try:
                rse_percent_users = calculate_rse(mdf_pd, col, stat_type="percent")
                rse_dict[f"{col}_percent_users_rse"] = [rse_percent_users]
            except Exception:
                rse_dict[f"{col}_percent_users_rse"] = [None]

            # Calculate quartiles (including all values)
            try:
                data_values = mdf_pd[col].values
                weights = mdf_pd["NWEIGHT"].values

                if len(data_values) > 0:
                    quantiles = [0, 0.02, 0.1, 0.25, 0.5, 0.75, 0.9, 0.98, 1]
                    quartiles = _calculate_weighted_quantiles(data_values, weights, quantiles)
                    quartile_dict[f"{col}_quartiles"] = quartiles.tolist()
                else:
                    quartile_dict[f"{col}_quartiles"] = [0.0] * 9
            except Exception:
                quartile_dict[f"{col}_quartiles"] = [0.0] * 9

            # Calculate nonzero quartiles (exclude zeros)
            try:
                data_values = mdf_pd[col].values
                weights = mdf_pd["NWEIGHT"].values
                non_zero_mask = data_values > 0
                data_values_nonzero = data_values[non_zero_mask]
                weights_nonzero = weights[non_zero_mask]

                if len(data_values_nonzero) > 0:
                    quantiles = [0, 0.02, 0.1, 0.25, 0.5, 0.75, 0.9, 0.98, 1]
                    nonzero_quartiles = _calculate_weighted_quantiles(data_values_nonzero, weights_nonzero, quantiles)
                    nonzero_quartile_dict[f"{col}_nonzero_quartiles"] = nonzero_quartiles.tolist()
                else:
                    nonzero_quartile_dict[f"{col}_nonzero_quartiles"] = [0.0] * 9
            except Exception:
                nonzero_quartile_dict[f"{col}_nonzero_quartiles"] = [0.0] * 9

        # Add RSE and quartile columns to result
        rse_df = pl.DataFrame(rse_dict)
        quartile_df = pl.DataFrame(quartile_dict)
        nonzero_quartile_df = pl.DataFrame(nonzero_quartile_dict)
        result_df = pl.concat([result_df, rse_df, quartile_df, nonzero_quartile_df], how="horizontal")

    # Note: US Total is only added when grouped by a column (e.g., state)
    # For ungrouped data, the result is already the US total
    result_df = result_df.with_columns(pl.lit("recs_2020").alias("source"))
    return result_df


@cached(cache_file="recs_monthly_data_cache")
def get_monthly_all(
    data_key: DataKey,
    year: int = 2020,
) -> pl.DataFrame:
    """Get monthly RECS data aggregated by state.

    Args:
        data_key: DataKey containing aggregation_level, aggregation_type, and coverage
        year: Year of RECS data (only 2020 supported)
    """
    if year != 2020:
        raise ValueError("RECS data is only available for the year 2020.")

    by = data_key.aggregation_level

    if by not in ("state",):
        raise ValueError("Monthly data only available aggregated by 'state'.")
    monthly_df = get_df_from_s3(s3_paths.RECS_2020_monthly, local_data_dir)

    # Rename "geography" column to "state" for backward compatibility
    monthly_df = monthly_df.rename({"geography": "state"})
    # Define valid state abbreviations (50 states + DC)
    valid_states = {
        "AL",
        "AK",
        "AZ",
        "AR",
        "CA",
        "CO",
        "CT",
        "DE",
        "FL",
        "GA",
        "HI",
        "ID",
        "IL",
        "IN",
        "IA",
        "KS",
        "KY",
        "LA",
        "ME",
        "MD",
        "MA",
        "MI",
        "MN",
        "MS",
        "MO",
        "MT",
        "NE",
        "NV",
        "NH",
        "NJ",
        "NM",
        "NY",
        "NC",
        "ND",
        "OH",
        "OK",
        "OR",
        "PA",
        "RI",
        "SC",
        "SD",
        "TN",
        "TX",
        "UT",
        "VT",
        "VA",
        "WA",
        "WV",
        "WI",
        "WY",
        "DC",
    }

    # Filter to keep only US Total and valid state abbreviations
    monthly_df = monthly_df.filter((pl.col("state") == "US Total") | (pl.col("state").is_in(valid_states)))

    monthly_df = monthly_df.with_columns(pl.col("month").replace_strict(NUM2MONTH, default=None))
    percent_users_cols = [
        f"{col.replace('_value', '_percent_users')}" for col in monthly_df.columns if col.endswith("_value")
    ]
    annual_df = get_annual_all(data_key=data_key, year=year)
    monthly_df = monthly_df.join(annual_df.select([by] + percent_users_cols + ["units_count"]), on=by, how="left")

    # Apply aggregation transformation if needed
    if data_key.coverage == CoverageType.all_units and data_key.aggregation_type == AggregationType.average:
        # For per-unit energy, divide value columns by units_count
        value_cols = [col for col in monthly_df.columns if col.endswith("_value")]
        avg_exprs = []
        for val_col in value_cols:
            # Divide value by units_count, handle division by zero
            avg_exprs.append(
                pl.when(pl.col("units_count") > 0)
                .then(pl.col(val_col) / pl.col("units_count"))
                .otherwise(0)
                .alias(val_col)
            )
        if avg_exprs:
            monthly_df = monthly_df.with_columns(avg_exprs)
    elif data_key.coverage == CoverageType.users_only and data_key.aggregation_type == AggregationType.average:
        # For per-user energy, divide value columns by customer columns
        value_cols = [col for col in monthly_df.columns if col.endswith("_value")]
        avg_exprs = []
        for val_col in value_cols:
            percent_users_col = val_col.replace("_value", "_percent_users")
            avg_exprs.append(
                pl.when(pl.col(percent_users_col) > 0)
                .then(pl.col(val_col) / (pl.col("units_count") * pl.col(percent_users_col) / 100))
                .otherwise(0)
                .alias(val_col)
            )
        if avg_exprs:
            monthly_df = monthly_df.with_columns(avg_exprs)

    monthly_df = monthly_df.with_columns(pl.lit("recs_2020").alias("source"))
    return monthly_df
