from resstockpostproc.baseline_validation.io_managers import truth_data_paths as s3_paths
from resstockpostproc.baseline_validation.io_managers.eiaid_mapping import LRD_UTILITY2EIAID
from resstockpostproc.baseline_validation.io_managers.get_eia_data import local_data_dir
from resstockpostproc.shared_utils.s3_manager import get_df_from_s3


import polars as pl


import logging


def get_lrd_data(year: int = 2018) -> pl.DataFrame:
    if year != 2018:
        raise ValueError("LRD data only available for 2018")

    df = get_df_from_s3(s3_paths.LRD_2018, local_data_dir)
    df = df.rename({"utility": "utility_name", "kWh per meter": "kwh_per_meter"})
    df = df.with_columns(
        pl.col("utility_name").replace_strict(LRD_UTILITY2EIAID, default=None).alias("eiaid"),
        pl.col("time").str.to_datetime(),
    )
    unmapped_count = df.filter(pl.col("eiaid").is_null()).height
    if unmapped_count > 0:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Filtered out {unmapped_count} rows with unmapped utilities")

    df = df.filter(pl.col("eiaid").is_not_null())

    return df