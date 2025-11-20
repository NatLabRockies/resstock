"""
Reference Data Loader
---------------------
Functions for loading and processing reference data (EIA, LRD, etc.) for validation
"""

from pathlib import Path

import polars as pl
from resstockpostproc.shared_utils.mapping import NUM2MONTH
from resstockpostproc.shared_utils.s3_manager import get_df_from_s3
from . import truth_data_paths as s3_paths
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow
from resstockpostproc.baseline_validation.schema.recs_enduse_mapping import RECS_ENDUSE_MAP
from resstockpostproc.baseline_validation.data_processing.recs_rse import calculate_rse
from collections.abc import Sequence
from typing import Literal
from resstockpostproc.baseline_validation.utils import KBTU2KWH
local_data_dir = Path(f"{workflow.output.output_dir}/data")


def get_annual_all(
    year: int = 2020,
    by: str | None = None) -> pl.DataFrame:
    if year != 2020:
        raise ValueError("RECS data is only available for the year 2020.")
    mdf =  get_df_from_s3(s3_paths.RECS_2020_microdata, local_data_dir)
    enduse_cols = tuple(RECS_ENDUSE_MAP.keys())
    
    if by:
        # Calculate value columns
        result_df = mdf.group_by(by).agg(
            *((pl.col(col)*pl.col("NWEIGHT")).sum().alias(f"recs_2020_{col}_value") for col in enduse_cols)
        )
        
        # Calculate RSE columns by group
        # Convert to pandas for RSE calculation
        mdf_pd = mdf.to_pandas()
        rse_results = []
        
        for group_value in mdf.select(by).unique().to_series():
            group_data = mdf_pd[mdf_pd[by] == group_value]
            rse_row = {by: group_value}
            
            for col in enduse_cols:
                try:
                    rse = calculate_rse(group_data, col, stat_type="total")
                    rse_row[f"recs_2020_{col}_rse"] = rse
                except Exception:
                    # If RSE calculation fails, set to None
                    rse_row[f"recs_2020_{col}_rse"] = None
            
            rse_results.append(rse_row)
        
        # Convert RSE results to polars and join with value results
        rse_df = pl.DataFrame(rse_results)
        result_df = result_df.join(rse_df, on=by, how="left")
    else:
        # Calculate value columns
        result_df = mdf.select(
            *((pl.col(col)*pl.col("NWEIGHT")).sum().alias(f"recs_2020_{col}_value") for col in enduse_cols)
        )
        
        # Calculate RSE columns
        # Convert to pandas for RSE calculation
        mdf_pd = mdf.to_pandas()
        rse_dict = {}
        
        for col in enduse_cols:
            try:
                rse = calculate_rse(mdf_pd, col, stat_type="total")
                rse_dict[f"recs_2020_{col}_rse"] = [rse]
            except Exception:
                # If RSE calculation fails, set to None
                rse_dict[f"recs_2020_{col}_rse"] = [None]
        
        # Add RSE columns to result
        rse_df = pl.DataFrame(rse_dict)
        result_df = pl.concat([result_df, rse_df], how="horizontal")
    
    return result_df


def get_monthly_all(
    year: int = 2020,
    by: Literal["state"] = "state") -> pl.DataFrame:
    if year != 2020:
        raise ValueError("RECS data is only available for the year 2020.")
    if by not in ("state",):
        raise ValueError("Monthly data only available aggregated by 'state'.")
    monthly_df = get_df_from_s3(s3_paths.RECS_2020_monthly, local_data_dir)
    monthly_df = monthly_df.with_columns(
        pl.col("month").replace_strict(NUM2MONTH, default=None)
    )
    return monthly_df

def get_available_aggregation_levels() -> Sequence[str]:
    return tuple(RECS_CHARS_MAPPING.keys())