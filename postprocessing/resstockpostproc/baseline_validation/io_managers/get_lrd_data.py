from resstockpostproc.baseline_validation.io_managers import comparison_data_paths as s3_paths
from resstockpostproc.baseline_validation.schema.plot_spec import Resolution
from resstockpostproc.shared_utils.mapping import UtilityName2ID
from resstockpostproc.baseline_validation.io_managers.get_eia_data import local_data_dir
from resstockpostproc.shared_utils.s3_manager import get_df_from_s3
from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.shared_utils.caching import cached
from resstockpostproc.shared_utils.mapping import NUM2MONTH
from resstockpostproc.shared_utils.timing import timed

import polars as pl
import logging


@timed
@cached(cache_file="lrd_data_cache")
def get_lrd_data(year: int = 2018) -> pl.DataFrame:
    if year != 2018:
        raise ValueError("LRD data only available for 2018")

    df = get_df_from_s3(s3_paths.LRD_2018, local_data_dir)
    df = df.rename({"kWh per meter": f"{DataCol.ELECTRICITY_TOTAL}_value"})
    df = df.with_columns(
        pl.col("utility").replace_strict(UtilityName2ID, default=None).alias("eiaid"),
        pl.col("time").str.to_datetime(),
    )
    unmapped_count = df.filter(pl.col("eiaid").is_null()).height
    if unmapped_count > 0:
        logger = logging.getLogger(__name__)
        logger.warning(f"Filtered out {unmapped_count} rows with unmapped utilities")

    df = df.filter(pl.col("eiaid").is_not_null())

    return df


@timed
def get_lrd_aggregated(
    year: int = 2018,
    resolution: Resolution = Resolution.year,
    restrict_list: tuple[str, ...] | None = None,
) -> pl.DataFrame:
    eiaid_cols = ["eiaid", "utility"]
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
        # Use actual date (truncated to day) instead of ordinal day number
        df = df.with_columns(pl.col("time").dt.truncate("1d").alias("day of year"))
        group_cols = eiaid_cols + ["day of year"]
        result_df = df.group_by(group_cols, maintain_order=True).agg(pl.col(value_col).sum().alias(value_col))
    elif resolution == Resolution.hour_of_day:
        df = df.with_columns(pl.col("time").dt.hour().alias(Resolution.hour_of_day))
        group_cols = eiaid_cols + [Resolution.hour_of_day]
        result_df = df.group_by(group_cols, maintain_order=True).agg(pl.col(value_col).mean().alias(value_col))
        result_df = result_df.sort(by=group_cols)
    elif resolution == Resolution.hour_of_day_summer:
        df = df.with_columns(
            pl.col("time").dt.hour().alias(Resolution.hour_of_day_summer), pl.col("time").dt.month().alias("month")
        )
        df = df.filter(pl.col("month").is_in([6, 7, 8]))
        group_cols = eiaid_cols + [Resolution.hour_of_day_summer]
        result_df = df.group_by(group_cols, maintain_order=True).agg(pl.col(value_col).mean().alias(value_col))
        result_df = result_df.sort(by=group_cols)
    elif resolution == Resolution.hour_of_day_winter:
        df = df.with_columns(
            pl.col("time").dt.hour().alias(Resolution.hour_of_day_winter), pl.col("time").dt.month().alias("month")
        )
        df = df.filter(pl.col("month").is_in([12, 1, 2]))
        group_cols = eiaid_cols + [Resolution.hour_of_day_winter]
        result_df = df.group_by(group_cols, maintain_order=True).agg(pl.col(value_col).mean().alias(value_col))
        result_df = result_df.sort(by=group_cols)
    elif resolution in {Resolution.hour_of_year, Resolution.top_100_hours}:
        df = df.with_columns(((pl.col("time").dt.ordinal_day() - 1) * 24 + pl.col("time").dt.hour()).alias(resolution))
        group_cols = eiaid_cols + [resolution]
        result_df = df.group_by(group_cols, maintain_order=True).agg(pl.col(value_col).mean().alias(value_col))
        result_df = result_df.sort(by=group_cols)
    elif resolution == Resolution.hour_of_day_matrix:
        # Add hour, month, and day_type columns
        df = df.with_columns(
            pl.col("time").dt.hour().alias("hour of day"),
            pl.col("time").dt.month().replace_strict(NUM2MONTH, default=None).alias("month"),
            pl.when(pl.col("time").dt.weekday() < 5)  # Mon=0..Fri=4 are weekdays
            .then(pl.lit("Weekday"))
            .otherwise(pl.lit("Weekend"))
            .alias("day_type"),
        )

        # 1. Monthly by day_type (e.g., JAN + Weekday)
        monthly_by_daytype = df.group_by(eiaid_cols + ["month", "day_type", "hour of day"], maintain_order=True).agg(
            pl.col(value_col).mean().alias(value_col)
        )

        # 2. Monthly "All Days" (aggregate across weekday/weekend)
        monthly_all_days = (
            df.group_by(eiaid_cols + ["month", "hour of day"], maintain_order=True)
            .agg(pl.col(value_col).mean().alias(value_col))
            .with_columns(pl.lit("All Days").alias("day_type"))
        )

        # 3. "All Year" by day_type
        yearly_by_daytype = (
            df.group_by(eiaid_cols + ["day_type", "hour of day"], maintain_order=True)
            .agg(pl.col(value_col).mean().alias(value_col))
            .with_columns(pl.lit("All Year").alias("month"))
        )

        # 4. "All Year" + "All Days"
        yearly_all_days = (
            df.group_by(eiaid_cols + ["hour of day"], maintain_order=True)
            .agg(pl.col(value_col).mean().alias(value_col))
            .with_columns(pl.lit("All Year").alias("month"), pl.lit("All Days").alias("day_type"))
        )

        result_df = pl.concat(
            [monthly_by_daytype, monthly_all_days, yearly_by_daytype, yearly_all_days], how="diagonal_relaxed"
        )
        group_cols = eiaid_cols + ["month", "day_type", "hour of day"]
        result_df = result_df.sort(by=group_cols)
    else:
        raise ValueError(f"Unsupported resolution: {resolution}")

    return result_df.with_columns(pl.lit("lrd_2018").alias("source"))
