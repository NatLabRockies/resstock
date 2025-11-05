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
from resstockpostproc.shared_utils.s3_manager import get_df_from_s3
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow
from typing import Literal
from resstockpostproc.baseline_validation.utils import KBTU2KWH
local_data_dir = Path(f"{workflow.output.output_dir}/{workflow.output.run_name}/data")


def get_annual_all(
    year: int = 2018,
    by: Literal['state', 'eiaid'] = "state") -> pl.DataFrame:
    annual_elec_df = _get_eia_annual_electricity(year=year, by=by)
    monthly_gas_df = _get_eia_monthly_gas(year=year, by=by)
    annual_monthly_gas_df = monthly_gas_df.group_by(by).agg(pl.col("eia_natural_gas_kwh").sum(),
                                                            pl.col("eia_natural_gas_customers").sum())
    final_df = annual_elec_df.join(annual_monthly_gas_df, on=by, how="outer")
    return final_df


def get_monthly_all(
    year: int = 2018,
    by: Literal['state', 'eiaid'] = "state") -> pl.DataFrame:
    monthly_elec_df = _get_eia_monthly_electricity(year=year, by=by)
    monthly_gas_df = _get_eia_monthly_gas(year=year, by=by)
    final_df = monthly_elec_df.join(monthly_gas_df, on=[by, "month"], how="outer")
    return final_df


def _get_eia_annual_electricity(year: int = 2018,
                               by: Literal['state', 'eiaid'] = "state") -> pl.DataFrame:
    df = get_df_from_s3(s3_paths.EIA_ANNUAL_ELECTRICITY, local_data_dir)
    df = df.filter(pl.col("year") == year)
    df = df.group_by(by).agg([
        (pl.col("sales_mwh").sum() * 1000).alias("eia_electricity_kwh"),
        (pl.col("customers").sum()).alias("eia_electricity_customers"),
    ])
    return df


def _get_eia_monthly_electricity(year: int = 2018,
                                by: Literal['state', 'eiaid'] = "state") -> pl.DataFrame:
    df = get_df_from_s3(s3_paths.EIA_MONTHLY_ELECTRICITY, local_data_dir)
    df = df.filter(pl.col("year") == year)
    df = df.with_columns(pl.col("month").replace_strict(NUM2MONTH, default=None).alias("month"))
    df = df.group_by([by, "month"]).agg([
        (pl.col("sales_mwh").sum() * 1000).alias("eia_electricity_kwh"),
        (pl.col("customers").sum()).alias("eia_electricity_customers"),
    ])
    return df


def _get_eia_monthly_gas(year: int = 2018,
                         by: Literal['state', 'eiaid'] = "state") -> pl.DataFrame:
    df = get_df_from_s3(s3_paths.EIA_MONTHLY_NATURAL_GAS, local_data_dir)
    df = df.with_columns((pl.col("natural_gas_kbtu") * KBTU2KWH).alias("sales_kwh"))
    df = df.filter(pl.col("year") == year)
    df = df.with_columns(pl.col("month").replace_strict(NUM2MONTH, default=None).alias("month"))
    df = df.group_by([by, "month"]).agg([
        (pl.col("sales_kwh").sum()).alias("eia_natural_gas_kwh"),
        (pl.col("customers").sum()).alias("eia_natural_gas_customers"),
    ])
    return df

