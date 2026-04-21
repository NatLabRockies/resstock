"""Shared utilities for baseline validation."""

import functools
from pathlib import Path

import polars as pl

from resstockpostproc.baseline_validation.schema.workflow_schema import DataSourceConfig
from buildstock_query import BuildStockQuery

NUM2MONTH: dict[int, str] = {
    1: "January",
    2: "February",
    3: "March",
    4: "April",
    5: "May",
    6: "June",
    7: "July",
    8: "August",
    9: "September",
    10: "October",
    11: "November",
    12: "December",
}

SEASON2MONTHS: dict[str, list[int]] = {
    "summer": [6, 7, 8],
    "winter": [12, 1, 2],
    "shoulder": [3, 4, 5, 9, 10, 11],
    "annual": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
}


KBTU2KWH = 0.29307107


def ensure_directory(path: Path) -> Path:
    """Ensure a directory exists, creating it if necessary."""
    path = Path(path)
    path.mkdir(parents=True, exist_ok=True)
    return path


def filter_by_season(df: pl.DataFrame, season: str | None, time_col: str = "time") -> pl.DataFrame:
    """Filter dataframe to specific season months."""
    if not season:
        return df

    if season not in SEASON2MONTHS:
        raise ValueError(f"Invalid season: {season}. Must be one of {list(SEASON2MONTHS.keys())}")

    season_months = SEASON2MONTHS[season]
    return df.filter(pl.col(time_col).dt.month().is_in(season_months))


def add_month_column(df: pl.DataFrame, time_col: str = "time", month_col: str = "month") -> pl.DataFrame:
    """Add month name column from datetime column."""
    return df.with_columns(
        pl.col(time_col).dt.month().map_elements(lambda x: NUM2MONTH[x], return_dtype=pl.Utf8).alias(month_col)
    )


def format_large_number(value: float, precision: int = 1) -> str:
    """Format large numbers with K, M, B, T suffixes."""
    abs_value = abs(value)
    sign = "-" if value < 0 else ""

    if abs_value >= 1e12:
        return f"{sign}{abs_value / 1e12:.{precision}f}T"
    elif abs_value >= 1e9:
        return f"{sign}{abs_value / 1e9:.{precision}f}B"
    elif abs_value >= 1e6:
        return f"{sign}{abs_value / 1e6:.{precision}f}M"
    elif abs_value >= 1e3:
        return f"{sign}{abs_value / 1e3:.{precision}f}K"
    else:
        return f"{sign}{abs_value:.{precision}f}"


@functools.cache
def get_buildstock_query(
    workgroup: str,
    config: DataSourceConfig,
    comparison_data_year: int = 2018,
    skip_reports: bool = False,
) -> BuildStockQuery:
    """Create and configure a BuildStockQuery instance."""
    cache_folder = str(Path(__file__).resolve().parent.parent.parent / ".bsq_cache")
    bsq = BuildStockQuery(
        workgroup=workgroup,
        db_name=config.db_name,
        table_name=config.table_name,
        skip_reports=skip_reports,
        db_schema=config.db_schema,
        cache_folder=cache_folder,
    )
    bsq.utility.eia_mapping_year = comparison_data_year
    return bsq
