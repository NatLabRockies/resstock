"""Shared utilities for baseline validation."""

import functools
from pathlib import Path
from typing import Dict, List

import polars as pl

from resstockpostproc.baseline_validation.schema.workflow_schema import DataSourceConfig
from buildstock_query import BuildStockQuery

NUM2MONTH: Dict[int, str] = {
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

MONTH2NUM: Dict[str, int] = {v: k for k, v in NUM2MONTH.items()}

SEASON2MONTHS: Dict[str, List[int]] = {
    "summer": [6, 7, 8],
    "winter": [12, 1, 2],
    "shoulder": [3, 4, 5, 9, 10, 11],
    "annual": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
}


CAT2COLOR: Dict[str, str] = {
    "plug_loads": "#4A4D4A",
    "refrigeration": "#29AAE7",
    "cooking": "#ff2200",
    "dishwasher": "#D3D3D3",
    "clothes": "#51e889",
    "hot_water": "#FFB239",
    "ventilation": "#FF79AD",
    "pool_pumps": "#632C94",
    "recreational_heater": "#ff7300",
    "lighting": "#F7DF10",
    "heating": "#EF1C21",
    "cooling": "#0071BD",
    "pv": "#4748a8",
    "net": "#0055ff",
    "total": "#0055ff",
}

NG_CAT2ENDUSES: Dict[str, List[str]] = {
    "clothes": ["end_use__natural_gas__clothes_dryer__kbtu"],
    "heating": [
        "end_use__natural_gas__heating__kbtu",
        "end_use__natural_gas__heating_heat_pump_backup__kbtu",
        "end_use__natural_gas__fireplace__kbtu",
    ],
    "cooking": ["end_use__natural_gas__range_oven__kbtu", "end_use__natural_gas__grill__kbtu"],
    "lighting": ["end_use__natural_gas__lighting__kbtu"],
    "recreational_heater": [
        "end_use__natural_gas__hot_tub_heater__kbtu",
        "end_use__natural_gas__pool_heater__kbtu",
    ],
    "hot_water": ["end_use__natural_gas__hot_water__kbtu"],
    "total": ["fuel_use__natural_gas__total__kbtu"],
}

ELEC_CAT2ENDUSES: Dict[str, List[str]] = {
    "plug_loads": ["end_use__electricity__plug_loads__kwh"],
    "refrigeration": ["end_use__electricity__freezer__kwh", "end_use__electricity__refrigerator__kwh"],
    "cooking": ["end_use__electricity__range_oven__kwh"],
    "dishwasher": ["end_use__electricity__dishwasher__kwh"],
    "clothes": ["end_use__electricity__clothes_dryer__kwh", "end_use__electricity__clothes_washer__kwh"],
    "hot_water": ["end_use__electricity__hot_water__kwh"],
    "ventilation": ["end_use__electricity__mech_vent__kwh"],
    "pool_pumps": [
        "end_use__electricity__hot_tub_pump__kwh",
        "end_use__electricity__pool_pump__kwh",
        "end_use__electricity__well_pump__kwh",
    ],
    "recreational_heater": [
        "end_use__electricity__hot_tub_heater__kwh",
        "end_use__electricity__pool_heater__kwh",
    ],
    "lighting": [
        "end_use__electricity__lighting_exterior__kwh",
        "end_use__electricity__lighting_garage__kwh",
        "end_use__electricity__lighting_interior__kwh",
    ],
    "heating": [
        "end_use__electricity__heating__kwh",
        "end_use__electricity__heating_fans_pumps__kwh",
        "end_use__electricity__heating_heat_pump_backup__kwh",
    ],
    "cooling": [
        "end_use__electricity__ceiling_fan__kwh",
        "end_use__electricity__cooling__kwh",
        "end_use__electricity__cooling_fans_pumps__kwh",
    ],
    "pv": ["end_use__electricity__pv__kwh"],
    "net": ["fuel_use__electricity__net__kwh"],
    "total": ["fuel_use__electricity__total__kwh"],
}

MBTU2KWH = 293.07107
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


@functools.lru_cache(maxsize=None)
def get_buildstock_query(
    workgroup: str,
    config: DataSourceConfig,
    truth_data_year: int = 2018,
    skip_reports: bool = False,
) -> BuildStockQuery:
    """Create and configure a BuildStockQuery instance."""
    bsq = BuildStockQuery(
        workgroup=workgroup,
        db_name=config.db_name,
        table_name=config.table_name,
        skip_reports=skip_reports,
        db_schema=config.db_schema,
    )
    bsq.utility.eia_mapping_year = truth_data_year
    return bsq
