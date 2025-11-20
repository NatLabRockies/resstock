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
from resstockpostproc.baseline_validation.schema.recs_chars_mapping import RECS_CHARS_MAPPING
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
    enduse_cols = tuple(RECS_CHARS_MAPPING.keys())
    if by:
        result_df = mdf.group_by(by).agg(
            *(pl.col(col).sum().alias(col) for col in enduse_cols)
        )
    else:
        result_df = mdf.select(
            *(pl.col(col).sum().alias(col) for col in enduse_cols)
        )
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