from resstockpostproc.baseline_validation.io_managers import truth_data_paths as s3_paths
from resstockpostproc.baseline_validation.schema.plot_spec import Resolution
from resstockpostproc.shared_utils.mapping import UtilityName2ID
from resstockpostproc.baseline_validation.io_managers.get_eia_data import local_data_dir
from resstockpostproc.shared_utils.s3_manager import get_df_from_s3
from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.shared_utils.caching import cached
from resstockpostproc.shared_utils.mapping import NUM2MONTH
from typing import Literal

import polars as pl
import logging

@cached(cache_file="lrd_data_cache")
def get_lrd_data(year: int = 2018) -> pl.DataFrame:
    if year != 2018:
        raise ValueError("LRD data only available for 2018")

    df = get_df_from_s3(s3_paths.LRD_2018, local_data_dir)
    df = df.rename({"utility": "utility_name", "kWh per meter": f"{DataCol.ELECTRICITY_TOTAL}_value"})
    df = df.with_columns(
        pl.col("utility_name").replace_strict(UtilityName2ID, default=None).alias("eiaid"),
        pl.col("time").str.to_datetime(),
    )
    unmapped_count = df.filter(pl.col("eiaid").is_null()).height
    if unmapped_count > 0:
        logger = logging.getLogger(__name__)
        logger.warning(f"Filtered out {unmapped_count} rows with unmapped utilities")

    df = df.filter(pl.col("eiaid").is_not_null())

    return df


def get_lrd_aggregated(
    year: int = 2018,
    resolution: Resolution = Resolution.year,
    restrict_list: tuple[str, ...] | None = None,
    ) -> pl.DataFrame:
    eiaid_cols = ["eiaid", "utility_name"]
    if year != 2018:
        raise ValueError("LRD data only available for 2018")
    df = get_lrd_data(year=year)
    if restrict_list is not None:
        df = df.filter(pl.col("eiaid").is_in({int(eiaid) for eiaid in restrict_list}))
    value_col = f"{DataCol.ELECTRICITY_TOTAL}_value"
    
    if resolution == Resolution.year:
        group_cols = eiaid_cols
        result_df = df.group_by(group_cols, maintain_order=True).agg(pl.col(value_col).sum().alias(value_col))
    elif resolution == Resolution.month:
        df = df.with_columns(pl.col("time").dt.month().replace_strict(NUM2MONTH, default=None).alias("month"))
        group_cols = eiaid_cols + ["month"]
        result_df = df.group_by(group_cols, maintain_order=True).agg(pl.col(value_col).sum().alias(value_col))
    elif resolution == Resolution.day_of_year:
        df = df.with_columns(pl.col("time").dt.ordinal_day().alias(Resolution.day_of_year))
        group_cols = eiaid_cols + ["day_of_year"]
        result_df = df.group_by(group_cols, maintain_order=True).agg(pl.col(value_col).sum().alias(value_col))
    elif resolution == Resolution.hour_of_day:
        df = df.with_columns(pl.col("time").dt.hour().alias(Resolution.hour_of_day))
        group_cols = eiaid_cols + [Resolution.hour_of_day]
        result_df = df.group_by(group_cols, maintain_order=True).agg(pl.col(value_col).mean().alias(value_col))
        result_df = result_df.sort(by=group_cols)
    elif resolution == Resolution.hour_of_day_summer:
        df = df.with_columns(pl.col("time").dt.hour().alias(Resolution.hour_of_day_summer),
                             pl.col("time").dt.month().alias("month"))
        df = df.filter(pl.col("month").is_in([6, 7, 8]))
        group_cols = eiaid_cols + [Resolution.hour_of_day_summer]
        result_df = df.group_by(group_cols, maintain_order=True).agg(pl.col(value_col).mean().alias(value_col))
        result_df = result_df.sort(by=group_cols)
    elif resolution == Resolution.hour_of_day_winter:
        df = df.with_columns(pl.col("time").dt.hour().alias(Resolution.hour_of_day_winter),
                             pl.col("time").dt.month().alias("month"))
        df = df.filter(pl.col("month").is_in([12, 1, 2]))
        group_cols = eiaid_cols + [Resolution.hour_of_day_winter]
        result_df = df.group_by(group_cols, maintain_order=True).agg(pl.col(value_col).mean().alias(value_col))
        result_df = result_df.sort(by=group_cols)
    elif resolution in {Resolution.hour_of_year, Resolution.top_100_hours}:
        df = df.with_columns(
            ((pl.col("time").dt.ordinal_day() - 1) * 24 + pl.col("time").dt.hour())
            .alias(resolution)
        )
        group_cols = eiaid_cols + [resolution]
        result_df = df.group_by(group_cols, maintain_order=True).agg(pl.col(value_col).mean().alias(value_col))
        result_df = result_df.sort(by=group_cols)
    else:
        raise ValueError(f"Unsupported resolution: {resolution}")
   
    return result_df.with_columns(pl.lit("lrd_2018").alias("source"))