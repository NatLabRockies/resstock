"""
Reference Data Loader
---------------------
Functions for loading and processing reference data (EIA, LRD, etc.) for validation
"""

from pathlib import Path

import polars as pl
from resstockpostproc.shared_utils.mapping import NUM2MONTH
from resstockpostproc.shared_utils.s3_manager import get_df_from_s3
from resstockpostproc.shared_utils.caching import cached
from resstockpostproc.shared_utils.timing import timed
from . import comparison_data_paths as s3_paths
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow
from collections.abc import Sequence
from typing import Literal
from resstockpostproc.baseline_validation.utils import KBTU2KWH
from resstockpostproc.shared_utils.db_column_names import DataCol, DBCharCol
from resstockpostproc.baseline_validation.io_managers.utils import apply_aggregation, add_us_total
from resstockpostproc.baseline_validation.schema.plot_spec import DataKey

local_data_dir = Path(f"{workflow.output.output_dir}/data")


@timed
@cached(cache_file="eia_annual_data_cache")
def get_annual_all(
    data_key: DataKey,
    years: list[int] | None = None,
) -> pl.DataFrame:
    """Get annual EIA data for multiple years, with columns suffixed by year.

    Args:
        data_key: DataKey containing aggregation_level, aggregation_type, and coverage
        years: List of years to include. Defaults to workflow.reference_years["eia"]
    """
    if years is None:
        years = workflow.reference_years.get("eia", [2018])

    by: Literal["state", "eiaid"] = "state" if "state" in data_key.group_by else "eiaid"

    dfs = []
    for year in years:
        annual_elec_df = _get_eia_annual_electricity(year=year, by=by)
        monthly_gas_df = _get_eia_monthly_gas(year=year, by=by)
        annual_monthly_gas_df = monthly_gas_df.group_by(by, maintain_order=True).agg(
            pl.col(f"{DataCol.NATURAL_GAS_TOTAL}_value").sum(), pl.col(f"{DataCol.NATURAL_GAS_TOTAL}_customers").mean()
        )
        year_df = annual_elec_df.join(annual_monthly_gas_df, on=by, how="outer", coalesce=True)
        year_df = year_df.with_columns(
            (100 * pl.col(f"{DataCol.NATURAL_GAS_TOTAL}_customers") / pl.col(DataCol.UNITS_COUNT)).alias(
                f"{DataCol.NATURAL_GAS_TOTAL}_percent_users"
            )
        )
        year_df = year_df.with_columns(pl.lit(f"eia_{year}").alias("source"))
        dfs.append(year_df)

    # Join all years together
    result = pl.concat(dfs, how="vertical")

    # Add US Total (only when aggregating by state, not eiaid)
    if by == "state":
        result = add_us_total(
            result,
            by=by,
            group_cols=["source"],
            exclude_cols=[f"{DataCol.ELECTRICITY_TOTAL}_percent_users", f"{DataCol.NATURAL_GAS_TOTAL}_percent_users"],
        )
        # Recalculate percent_users for US Total rows
        result = result.with_columns(
            [
                pl.when(pl.col(by) == "US Total")
                .then(pl.lit(100.0))
                .otherwise(pl.col(f"{DataCol.ELECTRICITY_TOTAL}_percent_users"))
                .alias(f"{DataCol.ELECTRICITY_TOTAL}_percent_users"),
                pl.when(pl.col(by) == "US Total")
                .then(100 * pl.col(f"{DataCol.NATURAL_GAS_TOTAL}_customers") / pl.col(DataCol.UNITS_COUNT))
                .otherwise(pl.col(f"{DataCol.NATURAL_GAS_TOTAL}_percent_users"))
                .alias(f"{DataCol.NATURAL_GAS_TOTAL}_percent_users"),
            ]
        )

    result = apply_aggregation(data_key, result)
    return result


@timed
@cached(cache_file="eia_monthly_data_cache")
def get_monthly_all(
    data_key: DataKey,
    years: list[int] | None = None,
) -> pl.DataFrame:
    """Get monthly EIA data for multiple years, with columns suffixed by year.

    Args:
        data_key: DataKey containing aggregation_level, aggregation_type, and coverage
        years: List of years to include. Defaults to workflow.reference_years["eia"]
    """
    if years is None:
        years = workflow.reference_years.get("eia", [2018])

    by: Literal["state", "eiaid"] = "state" if "state" in data_key.group_by else "eiaid"

    dfs = []
    for year in years:
        monthly_elec_df = _get_eia_monthly_electricity(year=year, by=by)
        monthly_gas_df = _get_eia_monthly_gas(year=year, by=by)
        year_df = monthly_elec_df.join(monthly_gas_df, on=[by, "month"], how="outer", coalesce=True)
        year_df = year_df.with_columns(
            (100 * pl.col(f"{DataCol.NATURAL_GAS_TOTAL}_customers") / pl.col(DataCol.UNITS_COUNT)).alias(
                f"{DataCol.NATURAL_GAS_TOTAL}_percent_users"
            )
        )

        year_df = year_df.with_columns(pl.lit(f"eia_{year}").alias("source"))
        dfs.append(year_df)

    # Join all years together
    result = pl.concat(dfs, how="vertical")

    # Add US Total (only when aggregating by state, not eiaid)
    if by == "state":
        result = add_us_total(
            result,
            by=by,
            group_cols=["source", "month"],
            exclude_cols=[f"{DataCol.ELECTRICITY_TOTAL}_percent_users", f"{DataCol.NATURAL_GAS_TOTAL}_percent_users"],
        )
        # Recalculate percent_users for US Total rows
        result = result.with_columns(
            pl.when(pl.col(by) == "US Total")
            .then(pl.lit(100.0))
            .otherwise(pl.col(f"{DataCol.ELECTRICITY_TOTAL}_percent_users"))
            .alias(f"{DataCol.ELECTRICITY_TOTAL}_percent_users"),
            pl.when(pl.col(by) == "US Total")
            .then(100 * pl.col(f"{DataCol.NATURAL_GAS_TOTAL}_customers") / pl.col(DataCol.UNITS_COUNT))
            .otherwise(pl.col(f"{DataCol.NATURAL_GAS_TOTAL}_percent_users"))
            .alias(f"{DataCol.NATURAL_GAS_TOTAL}_percent_users"),
        )

    result = apply_aggregation(data_key, result)
    return result


def get_available_aggregation_levels() -> Sequence[Literal["state", "eiaid"]]:
    return ("state", "eiaid")


@timed
def _get_eia_annual_electricity(year: int = 2018, by: Literal["state", "eiaid"] = "state") -> pl.DataFrame:
    df = get_df_from_s3(s3_paths.EIA_ANNUAL_ELECTRICITY, local_data_dir)
    df = df.filter(pl.col("year") == year)
    df = df.group_by(by, maintain_order=True).agg(
        [
            (pl.col("sales_mwh").sum() * 1000).alias(f"{DataCol.ELECTRICITY_TOTAL}_value"),
            (pl.col("customers").sum()).alias(f"{DataCol.UNITS_COUNT}"),
            (pl.lit(100).alias(f"{DataCol.ELECTRICITY_TOTAL}_percent_users")),
        ]
    )
    return df


@timed
def _get_eia_monthly_electricity(year: int = 2018, by: Literal["state", "eiaid"] = "state") -> pl.DataFrame:
    df = get_df_from_s3(s3_paths.EIA_MONTHLY_ELECTRICITY, local_data_dir)
    df = df.filter(pl.col("year") == year)
    df = df.with_columns(pl.col("month").replace_strict(NUM2MONTH, default=None).alias("month"))
    df = df.group_by([by, "month"], maintain_order=True).agg(
        [
            (pl.col("sales_mwh").sum() * 1000).alias(f"{DataCol.ELECTRICITY_TOTAL}_value"),
            (pl.col("customers").sum()).alias(DataCol.UNITS_COUNT),
            (pl.lit(100).alias(f"{DataCol.ELECTRICITY_TOTAL}_percent_users")),
        ]
    )
    return df


@timed
def _get_eia_monthly_gas(year: int = 2018, by: Literal["state", "eiaid"] = "state") -> pl.DataFrame:
    df = get_df_from_s3(s3_paths.EIA_MONTHLY_NATURAL_GAS, local_data_dir)
    df = df.with_columns((pl.col("natural_gas_kbtu") * KBTU2KWH).alias("sales_kwh"))
    df = df.filter(pl.col("year") == year)
    df = df.with_columns(pl.col("month").replace_strict(NUM2MONTH, default=None).alias("month"))
    df = df.group_by([by, "month"], maintain_order=True).agg(
        [
            (pl.col("sales_kwh").sum()).alias(f"{DataCol.NATURAL_GAS_TOTAL}_value"),
            (pl.col("customers").sum()).alias(f"{DataCol.NATURAL_GAS_TOTAL}_customers"),
        ]
    )
    return df
