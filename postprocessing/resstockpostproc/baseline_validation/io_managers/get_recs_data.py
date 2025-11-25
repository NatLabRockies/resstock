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
from .utils import add_us_total, _stack_quantity_types
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow
from resstockpostproc.baseline_validation.schema.recs_enduse_mapping import RECS_ENDUSE_MAP
from resstockpostproc.baseline_validation.data_processing.recs_rse import calculate_rse
from collections.abc import Sequence
from typing import Literal
from resstockpostproc.baseline_validation.utils import KBTU2KWH
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


def get_annual_all(
    year: int = 2020,
    by: str | None = None,
    aggregation: Literal["sum", "per_unit_avg", "per_user_avg"] = "sum") -> pl.DataFrame:
    if year != 2020:
        raise ValueError("RECS data is only available for the year 2020.")
    mdf =  get_df_from_s3(s3_paths.RECS_2020_microdata, local_data_dir)
    enduse_cols = tuple(RECS_ENDUSE_MAP.keys())
    
    if by:
        # Calculate value columns based on aggregation type
        if aggregation == "sum":
            # Stock energy: weighted sum
            result_df = mdf.group_by(by).agg(
                *((pl.col(col)*pl.col("NWEIGHT")).sum().alias(f"{col}_value") 
                  for col in enduse_cols),
                *(((pl.col(col) > 0).cast(pl.Int64)*pl.col("NWEIGHT")).sum().alias(f"{col}_customers") 
                  for col in enduse_cols)
            )
        elif aggregation == "per_unit_avg":
            # Per-unit energy: weighted mean (sum of weighted values / sum of all weights)
            result_df = mdf.group_by(by).agg(
                *(((pl.col(col)*pl.col("NWEIGHT")).sum() / 
                   pl.col("NWEIGHT").sum())
                  .alias(f"{col}_value") 
                  for col in enduse_cols),
                *(((pl.col(col) > 0).cast(pl.Int64)*pl.col("NWEIGHT")).sum().alias(f"{col}_customers") 
                  for col in enduse_cols)
            )
        else:  # aggregation == "per_user_avg"
            # Per-user energy: weighted mean (sum of weighted values / sum of weights for non-zero values only)
            result_df = mdf.group_by(by).agg(
                *(((pl.col(col)*pl.col("NWEIGHT")).sum() / 
                   ((pl.col(col) > 0).cast(pl.Int64)*pl.col("NWEIGHT")).sum())
                  .alias(f"{col}_value") 
                  for col in enduse_cols),
                *(((pl.col(col) > 0).cast(pl.Int64)*pl.col("NWEIGHT")).sum().alias(f"{col}_customers") 
                  for col in enduse_cols)
            )
        
        # Calculate RSE and quartiles by group
        # Convert to pandas for RSE calculation
        mdf_pd = mdf.to_pandas()
        rse_results = []
        quartile_results = []
        
        # Determine RSE stat type based on aggregation
        rse_stat_type = "total" if aggregation == "sum" else "avg"
        
        for group_value in mdf.select(by).unique().to_series():
            group_data = mdf_pd[mdf_pd[by] == group_value]
            rse_row = {by: group_value}
            quartile_row = {by: group_value}
            
            for col in enduse_cols:
                try:
                    rse = calculate_rse(group_data, col, stat_type=rse_stat_type)
                    rse_row[f"{col}_rse"] = rse
                except Exception:
                    # If RSE calculation fails, set to None
                    rse_row[f"{col}_rse"] = None
                
                # Calculate quartiles for the column
                try:
                    data_values = group_data[col].values
                    weights = group_data["NWEIGHT"].values
                    if len(data_values) > 0:
                        # Calculate weighted quartiles
                        quantiles = [0, 0.02, 0.1, 0.25, 0.5, 0.75, 0.9, 0.98, 1]
                        quartiles = _calculate_weighted_quantiles(data_values, weights, quantiles)
                        quartile_row[f"{col}_quartiles"] = str(quartiles.tolist())
                    else:
                        quartile_row[f"{col}_quartiles"] = str([0.0] * 9)
                except Exception:
                    quartile_row[f"{col}_quartiles"] = str([0.0] * 9)
            
            rse_results.append(rse_row)
            quartile_results.append(quartile_row)
        
        # Convert RSE and quartile results to polars and join with value results
        rse_df = pl.DataFrame(rse_results)
        quartile_df = pl.DataFrame(quartile_results)
        result_df = result_df.join(rse_df, on=by, how="left")
        result_df = result_df.join(quartile_df, on=by, how="left")
        
        # Add US Total values
        if aggregation == "sum":
            # For sum: add US Total by summing all states
            result_df = add_us_total(result_df, by=by, group_cols=None)
        elif aggregation == "per_unit_avg":
            # For per_unit_avg: calculate US Total from full microdata (can't sum averages)
            us_total_values = {}
            us_total_values[by] = "US Total"
            for col in enduse_cols:
                # Calculate weighted mean from full microdata (all units)
                weighted_sum = (mdf[col] * mdf["NWEIGHT"]).sum()
                weight_sum = (mdf["NWEIGHT"]).sum()
                avg_value = weighted_sum / weight_sum if weight_sum > 0 else 0
                us_total_values[f"{col}_value"] = avg_value
                us_total_values[f"{col}_customers"] = ((mdf[col] > 0).cast(pl.Int64) * mdf["NWEIGHT"]).sum()
            
            # Add US Total row to result_df
            us_total_df = pl.DataFrame([us_total_values])
            result_df = pl.concat([result_df, us_total_df], how="diagonal_relaxed")
        else:  # aggregation == "per_user_avg"
            # For per_user_avg: calculate US Total from full microdata (only non-zero values)
            us_total_values = {}
            us_total_values[by] = "US Total"
            for col in enduse_cols:
                # Calculate weighted mean from full microdata (non-zero values only)
                weighted_sum = (mdf[col] * mdf["NWEIGHT"]).sum()
                customer_weight_sum = ((mdf[col] > 0).cast(pl.Int64) * mdf["NWEIGHT"]).sum()
                avg_value = weighted_sum / customer_weight_sum if customer_weight_sum > 0 else 0
                us_total_values[f"{col}_value"] = avg_value
                us_total_values[f"{col}_customers"] = customer_weight_sum
            
            # Add US Total row to result_df
            us_total_df = pl.DataFrame([us_total_values])
            result_df = pl.concat([result_df, us_total_df], how="diagonal_relaxed")
        
        # Calculate RSE and quartiles for US Total from full microdata (must be done AFTER add_us_total to avoid overwriting)
        us_total_rse_dict = {}
        us_total_quartile_dict = {}
        for col in enduse_cols:
            try:
                rse = calculate_rse(mdf_pd, col, stat_type=rse_stat_type)
                us_total_rse_dict[f"{col}_rse"] = rse
            except Exception:
                # If RSE calculation fails, set to None
                us_total_rse_dict[f"{col}_rse"] = None
            
            # Calculate quartiles for US Total
            try:
                data_values = mdf_pd[col].values
                weights = mdf_pd["NWEIGHT"].values
                if len(data_values) > 0:
                    quantiles = [0, 0.02, 0.1, 0.25, 0.5, 0.75, 0.9, 0.98, 1]
                    quartiles = _calculate_weighted_quantiles(data_values, weights, quantiles)
                    us_total_quartile_dict[f"{col}_quartiles"] = str(quartiles.tolist())
                else:
                    us_total_quartile_dict[f"{col}_quartiles"] = str([0.0] * 9)
            except Exception:
                us_total_quartile_dict[f"{col}_quartiles"] = str([0.0] * 9)
        
        # Update the US Total row with correct RSE and quartile values
        for col, rse_value in us_total_rse_dict.items():
            result_df = result_df.with_columns(
                pl.when(pl.col(by) == "US Total")
                .then(pl.lit(rse_value))
                .otherwise(pl.col(col))
                .alias(col)
            )
        for col, quartile_value in us_total_quartile_dict.items():
            result_df = result_df.with_columns(
                pl.when(pl.col(by) == "US Total")
                .then(pl.lit(quartile_value))
                .otherwise(pl.col(col))
                .alias(col)
            )
    else:
        # Calculate value columns based on aggregation type
        if aggregation == "sum":
            # Stock energy: weighted sum
            result_df = mdf.select(
                *((pl.col(col)*pl.col("NWEIGHT")).sum().alias(f"{col}_value") for col in enduse_cols)
            )
        elif aggregation == "per_unit_avg":
            # Per-unit energy: weighted mean (sum of weighted values / sum of all weights)
            result_df = mdf.select(
                *(((pl.col(col)*pl.col("NWEIGHT")).sum() / 
                   pl.col("NWEIGHT").sum())
                  .alias(f"{col}_value") 
                  for col in enduse_cols)
            )
        else:  # aggregation == "per_user_avg"
            # Per-user energy: weighted mean (sum of weighted values / sum of weights for non-zero values only)
            result_df = mdf.select(
                *(((pl.col(col)*pl.col("NWEIGHT")).sum() / 
                   ((pl.col(col) > 0).cast(pl.Int64)*pl.col("NWEIGHT")).sum())
                  .alias(f"{col}_value") 
                  for col in enduse_cols)
            )
        
        # Calculate RSE and quartiles
        # Convert to pandas for RSE calculation
        mdf_pd = mdf.to_pandas()
        rse_dict = {}
        quartile_dict = {}
        
        # Determine RSE stat type based on aggregation
        rse_stat_type = "total" if aggregation == "sum" else "mean"
        
        for col in enduse_cols:
            try:
                rse = calculate_rse(mdf_pd, col, stat_type=rse_stat_type)
                rse_dict[f"{col}_rse"] = [rse]
            except Exception:
                # If RSE calculation fails, set to None
                rse_dict[f"{col}_rse"] = [None]
            
            # Calculate quartiles
            try:
                data_values = mdf_pd[col].values
                weights = mdf_pd["NWEIGHT"].values
                non_zero_mask = data_values > 0
                data_values = data_values[non_zero_mask]
                weights = weights[non_zero_mask]
                
                if len(data_values) > 0:
                    quantiles = [0, 0.02, 0.1, 0.25, 0.5, 0.75, 0.9, 0.98, 1]
                    quartiles = _calculate_weighted_quantiles(data_values, weights, quantiles)
                    quartile_dict[f"{col}_quartiles"] = [str(quartiles.tolist())]
                else:
                    quartile_dict[f"{col}_quartiles"] = [str([0.0] * 9)]
            except Exception:
                quartile_dict[f"{col}_quartiles"] = [str([0.0] * 9)]
        
        # Add RSE and quartile columns to result
        rse_df = pl.DataFrame(rse_dict)
        quartile_df = pl.DataFrame(quartile_dict)
        result_df = pl.concat([result_df, rse_df, quartile_df], how="horizontal")
    
    # Note: US Total is only added when grouped by a column (e.g., state)
    # For ungrouped data, the result is already the US total
    result_df = result_df.with_columns(
        pl.lit("recs_2020").alias("source")
    )
    result_df = _stack_quantity_types(result_df, result_df.columns)
    return result_df


def get_monthly_all(
    year: int = 2020,
    by: Literal["state"] = "state",
    aggregation: Literal["sum", "per_unit_avg", "per_user_avg"] = "sum") -> pl.DataFrame:
    if year != 2020:
        raise ValueError("RECS data is only available for the year 2020.")
    if by not in ("state",):
        raise ValueError("Monthly data only available aggregated by 'state'.")
    monthly_df = get_df_from_s3(s3_paths.RECS_2020_monthly, local_data_dir)
    
    # Rename "geography" column to "state" for backward compatibility
    monthly_df = monthly_df.rename({"geography": "state"})
    
    # Define valid state abbreviations (50 states + DC)
    valid_states = {
        "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
        "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
        "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
        "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
        "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY", "DC"
    }
    
    # Filter to keep only US Total and valid state abbreviations
    monthly_df = monthly_df.filter(
        (pl.col("state") == "US Total") | 
        (pl.col("state").is_in(valid_states))
    )
    
    monthly_df = monthly_df.with_columns(
        pl.col("month").replace_strict(NUM2MONTH, default=None)
    )
    
    # Apply aggregation transformation if needed
    if aggregation == "per_unit_avg":
        # For per-unit energy, divide value columns by units_count
        value_cols = [col for col in monthly_df.columns if col.endswith("_value")]
        avg_exprs = []
        if "units_count" in monthly_df.columns:
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
    elif aggregation == "per_user_avg":
        # For per-user energy, divide value columns by customer columns
        value_cols = [col for col in monthly_df.columns if col.endswith("_value")]
        avg_exprs = []
        for val_col in value_cols:
            # Find corresponding customer column
            customer_col = val_col.replace("_value", "_customers")
            if customer_col in monthly_df.columns:
                # Divide value by customers, handle division by zero
                avg_exprs.append(
                    pl.when(pl.col(customer_col) > 0)
                    .then(pl.col(val_col) / pl.col(customer_col))
                    .otherwise(0)
                    .alias(val_col)
                )
        if avg_exprs:
            monthly_df = monthly_df.with_columns(avg_exprs)
    
    # Data already contains US Total and Census regions from the Excel files
    monthly_df = monthly_df.with_columns(
        pl.lit("recs_2020").alias("source")
    )
    monthly_df = _stack_quantity_types(monthly_df, monthly_df.columns)
    return monthly_df

def get_available_aggregation_levels() -> Sequence[str]:
    return tuple(RECS_CHARS_MAPPING.keys())