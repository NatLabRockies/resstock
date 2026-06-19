"""
This script will create Athena views from raw ResStock results following
the OEDI format (with db_schema: resstock_oedi_new).

Views created:
  - Timeseries view: <table>_ts_by_state (always created)
  - Baseline view:   <table>_md_national_parquet (only with --baseline-view flag)

===================================================================================

Usage
-----
  # Create timeseries view only:
  python process_timeseries_results.py -d my_database -t my_table

  # Create both baseline and timeseries views:
  python process_timeseries_results.py -d my_database -t my_table -b

  # Force overwrite existing views:
  python process_timeseries_results.py -d my_database -t my_table -b --force

  # Create views and run validation checks:
  python process_timeseries_results.py -d my_database -t my_table -b --check

  # Use OCHRE workflow (pass-through unmapped columns, skip intensity):
  python process_timeseries_results.py -d my_database -t my_table --ochre-workflow

  # Create external tables from S3 data first:
  python process_timeseries_results.py -d my_database -t my_table \\
      --s3-location s3://bucket/path/to/data/ --workgroup my_workgroup

Flags
-----
  -d, --database        Athena/Glue database name (required).
  -t, --table           Source table name (required).
  -w, --workgroup       Athena workgroup (default: primary).
  -l, --s3-location     S3 path to raw data (for creating external tables).
  -r, --region          AWS region (default: us-west-2).
  -i, --input-format    Source data format (default: PARQUET).
  -f, --force           Overwrite existing views.
  -c, --check           Run validation checks on the timeseries view after creation.
  -o, --ochre-workflow   Use OCHRE-aligned column mapping.
  -b, --baseline-view   Also create the baseline view from <table>_pub_annual.

===================================================================================

Data Processing
-----------------
If the input table does not yet exist in the database, rerun the script by adding an S3
path to create an external table pointing to the raw data on S3 using boto3. The
script will create the view on top of that.

[1] The timeseries view definition will perform the following transformations:

- Select relevant columns from the baseline and timeseries tables, including
  building_id, county (if needed for time conversion), conditioned sqft, and all
  timeseries columns matching the expected ResStock naming convention for energy
  consumption.

- Adjust the time column to be in Eastern Standard Time (EST) and follow a
  period-beginning convention. This involves:
    - For results that do not contain a timeutc column, convert time to timeutc
      using the county-based UTC offset from options_lookup.tsv.
    - Applying the appropriate time shift to convert from UTC to EST.

- Rename columns to match the OEDI timeseries schema (e.g.
  "electricity_heating_kwh" -> "out.electricity.heating.energy_consumption").

- Calculate energy intensity columns for each fuel type and end use by dividing
  energy consumption by conditioned sqft.

- Wrap time back to the simulation year (i.e., by replacing the year of the
  timestamp with the simulation year).

- Optionally, run basic validation checks on the created timeseries view.

[2] The baseline view is a simple passthrough (SELECT *) from <table>_pub_annual.
No validation checks.

"""

import io
import re
import time
import argparse
import logging
import traceback
from typing import Optional, Union, Literal
from pathlib import Path
import pandas as pd
import boto3
from botocore.exceptions import ClientError
import pyarrow.parquet as pq

from buildstock_query import BuildStockQuery

# Configure logging for column processing traceability
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


# --- Constants and configuration ---
# postprocessing/baseline_validation db_schema = "resstock_oedi_new" 
BL_VIEW_SUFFIX = "_md_national_parquet"
TS_VIEW_SUFFIX = "_ts_by_state"
UG_VIEW_SUFFIX = BL_VIEW_SUFFIX

options_lookup_file = Path(__file__).parents[2] / "resources" / "options_lookup.tsv"
sdr_column_definitions_file = (
    Path(__file__).parents[0]
    / "resources"
    / "publication"
    / "sdr_column_definitions.csv"
)

# Mapping of raw end-use names to final (OEDI) end-use names
ENDUSE_REMAP = {
    "electric_vehicle_charging": "ev_charging",
    "heating_heat_pump_backup": "heating_hp_bkup",
    "heating_heat_pump_backup_fans_pumps": "heating_hp_bkup_fa",
    "permanent_spa_heater": "permanent_spa_heat",
}

# Unit conversions: raw_unit -> (final_unit, multiplier)
# multiplier is None for temperature (requires F→C formula)
UNIT_CONVERSIONS = {
    "kwh": ("kwh", 1.0),
    "kbtu": ("kwh", 0.293071),
    "therm": ("kwh", 29.3001),
    "mbtu": ("kwh", 293.07107),
    "btu/(hr*ft^2)": ("watt_per_m2", 3.15459),
    "mph": ("meter_per_second", 0.44704),
    "f": ("c", None),  # special: (F-32)*5/9
    "%": ("percentage", 1.0),
    "fraction": ("kgwater_per_kgdryair", 1.0),
    "kgwater/kgdryair": ("kgwater_per_kgdryair", 1.0),
    "hr": ("hour", 1.0),
    "gal": ("gal", 1.0),
}

# The EIA ID weights table is needed for the LRD comparison queries in the BSQ utility_query module.
EIAID_WEIGHTS_TABLE = "eiaid_weights"
EIAID_WEIGHTS_S3_LOCATION = (
    "s3://resstock-core/truth_data/v01/EIA/eia_processed/eiaid_weights/"
)

# --- Functions for Athena view creation and SQL generation ---

def initialize_buildstock_query(
    database: str,
    table: Union[str, tuple[str, Optional[str], Optional[str]]],
    workgroup: Optional[str] = "primary",
    buildstock_type: Literal["resstock", "comstock"] = "resstock",
    is_oedi_schema: bool = False,
    **kwargs,
) -> BuildStockQuery:
    """
    Initialize buildstockquery
    Args:
        database: name of Athena database
        table: name of table within database
        workgroup: name of workgroup
        buildstock_type: 'resstock' or 'comstock'
        is_oedi_schema: whether db_schema is for oedi
        accepts other keyword arguments for BuildStockQuery

    Returns:
        BuildStockQuery
    """
    if is_oedi_schema:
        db_schema = f"{buildstock_type}_oedi"
    else:
        db_schema = f"{buildstock_type}_default"

    logger.info(f"Initializing BuildStockQuery with database='{database}', table='{table}', workgroup='{workgroup}', db_schema='{db_schema}'")
    
    try:
        bsq = BuildStockQuery(
            workgroup=workgroup,
            db_name=database,
            table_name=table,
            buildstock_type=buildstock_type,
            db_schema=db_schema,
            sample_weight_override=1,
            skip_reports=True,
            **kwargs,
        )
        logger.info(f"Successfully initialized BuildStockQuery for table '{table}' ** ")
        return bsq
    except Exception as e:
        logger.error(f"BuildStockQuery initialization failed for database='{database}', table='{table}', workgroup='{workgroup}'")
        logger.error(f"Exception type: {type(e).__name__}")
        logger.error(f"Exception message: {str(e)}")
        logger.debug(f"Full traceback:\n{traceback.format_exc()}")
        raise


def list_views(bsq: BuildStockQuery) -> list[str]:
    """
    List all views in the Athena database associated with the BuildStockQuery instance.

    Parameters
    ----------
    bsq : BuildStockQuery
        An initialized BuildStockQuery instance.

    Returns
    -------
    list[str]
        View names in the database.
    """
    df = bsq.execute(f"SHOW VIEWS IN {bsq.db_name}")
    return df.iloc[:, 0].tolist() if not df.empty else []


def create_view(
    bsq: BuildStockQuery,
    view_name: str,
    select_sql: str,
    force: bool = False,
) -> tuple[str, str]:
    """
    Create (or replace) a view in Athena from a SELECT statement.

    Parameters
    ----------
    bsq : BuildStockQuery
        An initialized BuildStockQuery instance.
    view_name : str
        Name for the new view.
    select_sql : str
        The full SELECT statement body (columns, transforms, WHERE, etc.).
        Example: "SELECT col_a, col_b FROM my_table WHERE col_a > 0"
    force : bool
        If True, overwrite an existing view. If False and the view exists,
        raises RuntimeError.

    Returns
    -------
    tuple[str, str]
        (state, reason) from the Athena execution.

    Raises
    ------
    RuntimeError
        If the view already exists (and force=False), or if creation fails.
    """
    # Check if view already exists
    existing_views = list_views(bsq)
    if view_name in existing_views and not force:
        raise RuntimeError(
            f"View '{view_name}' already exists in database '{bsq.db_name}'. "
            f"Rerun with force=True to overwrite."
        )

    ddl = f"CREATE OR REPLACE VIEW {view_name} AS {select_sql}"
    state, reason = bsq.execute_raw(ddl)

    if state != "SUCCEEDED":
        raise RuntimeError(f"View creation failed ({state}): {reason}")

    logger.info(f" ** View '{view_name}' created successfully in database '{bsq.db_name}'. ** ")
    return state, reason


def _read_options_lookup() -> pd.DataFrame:
    """Read the options_lookup.tsv file into a DataFrame.

    Handles variable-width TSV by detecting the maximum column count,
    then assigns fixed column names.

    Returns
    -------
    pd.DataFrame
        DataFrame with columns: Parameter Name, Option Name, Measure Dir,
        and Measure Arg 1..N.
    """

    # First, determine the max number of columns across all rows
    with open(options_lookup_file) as f:
        max_cols = max(line.count("\t") + 1 for line in f)

    # Generate column names: first 3 are fixed, rest are Measure Args
    col_names = ["Parameter Name", "Option Name", "Measure Dir"] + [
        f"Measure Arg {i}" for i in range(1, max_cols - 2)
    ]

    df = pd.read_csv(
        options_lookup_file,
        sep="\t",
        header=None,
        skiprows=1,  # skip the original header row
        names=col_names,
    )

    return df


def _get_county_utc_offset() -> dict[str, int]:
    """Get the UTC offset (hours) for each county from options_lookup.tsv.

    Returns
    -------
    dict[str, int]
        Mapping of county option name (e.g. 'NY, Albany County') to its
        UTC offset in hours (e.g. -5).
    """
    df = _read_options_lookup()
    cond = df["Parameter Name"] == "County"
    dct = df.loc[cond].set_index("Option Name")["Measure Arg 4"].to_dict()
    dct = {k: int(v.removeprefix("site_time_zone_utc_offset=")) for k, v in dct.items()}
    return dct


def _build_county_utc_offset_case_sql_expr() -> str:
    """Build a SQL CASE expression mapping counties to their UTC offsets.

    Groups counties by UTC offset and generates a CASE/WHEN expression
    suitable for embedding in an Athena SQL query.

    Returns
    -------
    str
        SQL CASE expression, e.g.
        ``CASE WHEN "in.county" IN ('NY, Albany County', ...) THEN -5 ... ELSE 0 END``
    """
    county_utc_offsets = _get_county_utc_offset()

    # group counties by their UTC offset
    offset_groups = {}
    for county, offset in county_utc_offsets.items():
        offset_groups.setdefault(offset, []).append(county)

    # create a CASE statement to adjust time based on county
    case_statements = []
    for offset, counties in offset_groups.items():
        county_list = ", ".join(f"'{c.replace(chr(39), chr(39)*2)}'" for c in counties)
        case_statements.append(f'WHEN "in.county" IN ({county_list}) THEN {offset}')

    case_sql_expr = "CASE\n" + "\n".join(case_statements) + "\nELSE 0 END"
    return case_sql_expr


def _build_est_time_sql_expr(
    bsq: BuildStockQuery,
    time_col: str,
    has_timeutc: bool,
    time_table: Optional[str] = None,
) -> tuple[str, int]:
    """Build a SQL expression to convert timestamps to EST period-beginning.

    Queries the baseline table to determine the timestamp convention (begin/end)
    and the simulation year. Returns a DATE_ADD expression that shifts the raw
    time column to UTC-5 (EST) with period-beginning alignment.

    Does **not** wrap time to the simulation year (see
    ``_build_wrap_time_to_sim_year_sql_expr``).

    Parameters
    ----------
    bsq : BuildStockQuery
        An initialized BuildStockQuery instance.
    time_col : str
        Desired output column name for the timestamp.
    has_timeutc : bool
        If True, the source table contains a ``timeutc`` column and no
        county-based local-to-UTC conversion is needed.
    time_table : str or None
        Time table to infer timestep/simulation year from. If None,
        defaults to ``<table_name>_timeseries``. This can be a subquery,
        e.g., hourly-resampled times.

    Returns
    -------
    tuple[str, int]
        (time_sql_expr, sim_year) — the SQL expression string and detected
        simulation year.
    """
    table_name = bsq.table_name

    try:
        time_convention = bsq.execute(f"""
            SELECT "report_simulation_output.timeseries_timestamp_convention" FROM {table_name}_baseline
            LIMIT 1
        """).iloc[0, 0]

    except Exception:
        logger.warning(f"Could not determine timeseries timestamp convention from {table_name}_baseline. Defaulting to 'end'.")
        time_convention = "end"

    if time_table is None:
        time_table = f"{table_name}_timeseries"

    df = bsq.execute(f"""
        SELECT DISTINCT "time" FROM {time_table}
        ORDER BY 1
        LIMIT 2
    """)
    sim_year = df["time"].dt.year[0]

    delta_minutes = -5 * 60  # UTC offset for EST in minutes
    match time_convention:
        case "end":
            timestep_minutes = int(
                (df["time"].iloc[1] - df["time"].iloc[0]).total_seconds() / 60
            )
            delta_minutes -= timestep_minutes
        case "begin":
            # already set for period-beginning convention, no adjustment needed
            pass
        case _:
            raise NotImplementedError(
                f"Time convention '{time_convention}' not supported."
            )

    if has_timeutc:
        # delta minutes maintains UTC offset convention
        time_sql_expr = f"""
        DATE_ADD('minute', {delta_minutes}, "timeutc") AS "{time_col}"
        """

    else:
        # additionally add conversion from local standard time to UTC
        county_utc_offset_sql_expr = _build_county_utc_offset_case_sql_expr()

        # must minus the county UTC offset (in hours) because it's going from local standard to UTC
        time_sql_expr = f"""
        DATE_ADD('minute', {delta_minutes} - 60 * ({county_utc_offset_sql_expr}), "time") AS "{time_col}"
        """

    return time_sql_expr, sim_year


def _build_wrap_time_to_sim_year_sql_expr(time_col: str, target_year: int) -> str:
    """Build a SQL expression that resets timestamps to the simulation year.

    Uses Athena/Presto DATE_ADD to shift the year component of the timestamp
    to ``target_year``, preserving month/day/time.

    Parameters
    ----------
    time_col : str
        Name of the timestamp column to wrap.
    target_year : int
        The simulation year to normalize timestamps to.

    Returns
    -------
    str
        SQL expression: ``DATE_ADD('year', <shift>, "<time_col>") AS "<time_col>"``.
    """
    time_sql_expr = f"""
    DATE_ADD('year', {target_year} - YEAR("{time_col}"), "{time_col}") AS "{time_col}"
    """
    return time_sql_expr


def _get_partition_columns(bsq: BuildStockQuery) -> list[str]:
    """
    Get partition column names from the timeseries table.

    pyathena marks partition columns with dialect_options["awsathena"]["partition"] = True
    during SQLAlchemy table reflection from the Glue catalog.
    """
    return [
        col.name
        for col in bsq.ts_table.columns
        if col.dialect_options.get("awsathena", {}).get("partition") is True
    ]


def _reformat_raw_column(col: str) -> Optional[tuple[str, str, Optional[float]]]:
    """
    Reformat raw ResStock timeseries columns (double-underscore format) to OEDI schema.

    Parameters
    ----------
    col : str
        Raw column name, e.g. "end_use__electricity__hot_water__kwh"

    Returns
    -------
    tuple[str, str, float | None] or (None, None, None)
        (new_column_name, raw_unit, conversion_multiplier)
        multiplier is None for temperature (requires F→C formula), or float.
        Returns (None, None, None) if column doesn't match any known pattern.
    """
    # Pattern 1: end_use__<fuel>__<enduse>__<unit>
    m = re.match(r"^end_use__(\w+)__(\w+)__(\w+)$", col)
    if m:
        fuel, enduse, unit = m.groups()
        enduse = ENDUSE_REMAP.get(enduse, enduse)
        final_unit, mult = UNIT_CONVERSIONS.get(unit, (unit, 1.0))
        new_col = f"out.{fuel}.{enduse}.energy_consumption..{final_unit}"
        return new_col, unit, mult

    # Pattern 2: fuel_use__<fuel>__<total|net>__<unit>
    m = re.match(r"^fuel_use__(\w+)__(\w+)__(\w+)$", col)
    if m:
        fuel, agg, unit = m.groups()
        final_unit, mult = UNIT_CONVERSIONS.get(unit, (unit, 1.0))
        new_col = f"out.{fuel}.{agg}.energy_consumption..{final_unit}"
        return new_col, unit, mult

    # Pattern 3: energy_use__<total|net>__<unit>
    m = re.match(r"^energy_use__(\w+)__(\w+)$", col)
    if m:
        agg, unit = m.groups()
        final_unit, mult = UNIT_CONVERSIONS.get(unit, (unit, 1.0))
        new_col = f"out.site_energy.{agg}.energy_consumption..{final_unit}"
        return new_col, unit, mult

    # Pattern 4: hot_water__<enduse>__<unit>
    m = re.match(r"^hot_water__(\w+)__(\w+)$", col)
    if m:
        enduse, unit = m.groups()
        final_unit, mult = UNIT_CONVERSIONS.get(unit, (unit, 1.0))
        new_col = f"out.hot_water.{enduse}..{final_unit}"
        return new_col, unit, mult

    # Pattern 5: load__<type>__<subtype>__<unit>
    m = re.match(r"^load__(\w+)__(\w+)__(\w+)$", col)
    if m:
        load_type, subtype, unit = m.groups()
        final_unit, mult = UNIT_CONVERSIONS.get(unit, (unit, 1.0))
        new_col = f"out.load.{load_type}.{subtype}..{final_unit}"
        return new_col, unit, mult

    # Pattern 6: unmet_hours__<type>__<unit>
    m = re.match(r"^unmet_hours__(\w+)__(\w+)$", col)
    if m:
        utype, unit = m.groups()
        final_unit, mult = UNIT_CONVERSIONS.get(unit, (unit, 1.0))
        new_col = f"out.unmet_hours.{utype}..{final_unit}"
        return new_col, unit, mult

    # Pattern 7: Indoor environment - temperature, humidity, etc. for conditioned_space
    # temperature__<zone>__f, dewpoint_temperature__<zone>__f, etc.
    m = re.match(
        r"^(temperature|dewpoint_temperature|operative_temperature|radiant_temperature)"
        r"__(\w+(?:_-_\w+)?)__f$",
        col,
    )
    if m:
        measure, zone = m.groups()
        # Map measure names to OEDI prefix
        measure_map = {
            "temperature": "indoor_temperature",
            "dewpoint_temperature": "indoor_dewpoint_temperature",
            "operative_temperature": "indoor_operative_temperature",
            "radiant_temperature": "indoor_radiant_temperature",
        }
        oedi_measure = measure_map[measure]
        new_col = f"out.{oedi_measure}.{zone}..c"
        return new_col, "f", None  # None means F→C conversion

    # Pattern 8: relative_humidity__<zone>__%
    m = re.match(r"^relative_humidity__(\w+(?:_-_\w+)?)__\%$", col)
    if m:
        zone = m.group(1)
        new_col = f"out.indoor_relative_humidity.{zone}..percentage"
        return new_col, "%", 1.0

    # Pattern 9: humidity_ratio__<zone>__fraction
    m = re.match(r"^humidity_ratio__(\w+(?:_-_\w+)?)__fraction$", col)
    if m:
        zone = m.group(1)
        new_col = f"out.indoor_humidity_ratio.{zone}..kgwater_per_kgdryair"
        return new_col, "fraction", 1.0

    # Pattern 10: site_outdoor_air_humidity_ratio__environment__kgwater/kgdryair
    m = re.match(r"^site_outdoor_air_humidity_ratio__\w+__kgwater/kgdryair$", col)
    if m:
        new_col = "out.outdoor_humidity_ratio..kgwater_per_kgdryair"
        return new_col, "kgwater/kgdryair", 1.0

    # Pattern 11: weather columns
    m = re.match(r"^weather__(\w+)__(.+)$", col)
    if m:
        measure, unit = m.groups()
        weather_map = {
            ("drybulb_temperature", "f"): (
                "out.outdoor_air_drybulb_temp..c",
                "f",
                None,
            ),
            ("wetbulb_temperature", "f"): (
                "out.outdoor_air_wetbulb_temp..c",
                "f",
                None,
            ),
            ("relative_humidity", "%"): (
                "out.outdoor_air_relative_humidity..percentage",
                "%",
                1.0,
            ),
            ("diffuse_solar_radiation", "btu/(hr*ft^2)"): (
                "out.weather.diffuse_solar_radiation..watt_per_m2",
                "btu/(hr*ft^2)",
                3.15459,
            ),
            ("direct_solar_radiation", "btu/(hr*ft^2)"): (
                "out.weather.direct_normal_solar_radiation..watt_per_m2",
                "btu/(hr*ft^2)",
                3.15459,
            ),
            ("wind_speed", "mph"): (
                "out.weather.wind_speed..meter_per_second",
                "mph",
                0.44704,
            ),
        }
        key = (measure, unit)
        if key in weather_map:
            new_col, raw_unit, mult = weather_map[key]
            return new_col, raw_unit, mult

    return None, None, None


def _build_column_sql_expr(
    col: str, new_col: str, fuel_units: Optional[str], mult: Optional[float]
) -> str:
    """Build a single SQL column expression with appropriate unit conversion.

    Applies the correct arithmetic transformation based on the source unit
    and multiplier (e.g. F→C formula, kBtu→kWh scaling, or identity).

    Parameters
    ----------
    col : str
        Raw column name in the source table.
    new_col : str
        Desired output column alias.
    fuel_units : str or None
        Original unit string (e.g. 'kwh', 'f', 'therm'). None for passthrough.
    mult : float or None
        Conversion multiplier. None triggers F→C formula when fuel_units='f'.

    Returns
    -------
    str
        SQL expression such as ``0.293071 * "col" AS "new_col"`` or
        ``("col" - 32) * 5.0 / 9.0 AS "new_col"``.
    """
    if mult is None and fuel_units == "f":
        return f'(("{col}" - 32) * 5.0 / 9.0) AS "{new_col}"'
    elif mult is not None and mult != 1.0:
        return f'{mult} * "{col}" AS "{new_col}"'
    elif fuel_units in UNIT_CONVERSIONS:
        _, conv = UNIT_CONVERSIONS[fuel_units]
        if conv is not None and conv != 1.0:
            return f'{conv} * "{col}" AS "{new_col}"'
    return f'"{col}" AS "{new_col}"'


def _build_renamed_columns(
    columns: list[str],
    keep_unmapped_cols: bool = False,
    skip_cols: set[str] | None = None,
) -> tuple[list[str], list[tuple[str, str]]]:
    """Map raw timeseries column names to OEDI names with unit-conversion SQL.

    Iterates over ``columns``, applies ``_reformat_raw_column`` to determine
    the OEDI name and conversion, then builds the SQL expression for each.

    Parameters
    ----------
    columns : list[str]
        Raw column names from the timeseries table.
    keep_unmapped_cols : bool
        If True, columns that do not match any known pattern are passed through
        unchanged (useful for Ochre workflow).
    skip_cols : set[str] or None
        Column names to exclude entirely (e.g. structural/partition columns
        already handled elsewhere).

    Returns
    -------
    tuple[list[str], list[tuple[str, str]]]
        (sql_expressions, ts_cols) where ts_cols is [(raw_name, oedi_name), ...].
    """
    if skip_cols is None:
        skip_cols = set()
    sql_exprs = []
    ts_cols = []
    skipped_cols = []
    passed_through_cols = []
    
    for col in columns:
        if col in skip_cols:
            continue
        new_col, fuel_units, mult = _reformat_raw_column(col)

        if new_col is None:
            if keep_unmapped_cols:
                # pass through all non-standard columns
                new_col = col
                fuel_units = mult = None
                passed_through_cols.append(col)
                logger.info(f"Unmapped column (passed through): {col}")
            else:
                skipped_cols.append((col, "does not match any known pattern"))
                logger.debug(f"Dropping column (no pattern match): {col}")
                continue
        ts_cols.append((col, new_col))
        sql_exprs.append(_build_column_sql_expr(col, new_col, fuel_units, mult))
    
    # Log summary of column processing
    if skipped_cols:
        # Only log those unintentionally dropped
        logger.info(f"Total columns dropped: {len(skipped_cols)}")
        for col, reason in skipped_cols:
            logger.debug(f"  - {col}: {reason}")
    
    if passed_through_cols:
        logger.info(f"Total columns passed through (unmapped): {len(passed_through_cols)}")
    
    return sql_exprs, ts_cols


def _build_intensity_columns(
    ts_cols: list[tuple[str, str]], sqft_col: str
) -> list[str]:
    """Generate SQL expressions for energy intensity columns.

    Each expression divides an energy column by conditioned floor area.

    Parameters
    ----------
    ts_cols : list[tuple[str, str]]
        List of (raw_name, oedi_name) column pairs.
    sqft_col : str
        Name of the conditioned floor area column.

    Returns
    -------
    list[str]
        SQL expressions like ``"col" / "in.sqft" AS "col_intensity"``.
    """
    intensity_exprs = [
        f'"{new_col}" / "{sqft_col}" AS "{new_col}_intensity"' for _, new_col in ts_cols
    ]
    logger.info(f"Generated {len(intensity_exprs)} intensity column expressions from {len(ts_cols)} energy columns")
    return intensity_exprs


def _get_column_mapping_config(ochre_workflow: bool) -> tuple[bool, bool]:
    """Determine column-mapping behaviour based on workflow type.

    Parameters
    ----------
    ochre_workflow : bool
        True for OCHRE-aligned workflow, False for standard ResStock.

    Returns
    -------
    tuple[bool, bool]
        (compute_intensity_cols, keep_unmapped_cols)
        - compute_intensity_cols: whether to generate energy/sqft intensity columns.
        - keep_unmapped_cols: whether unmapped timeseries columns are passed through.
    """
    if ochre_workflow:
        # OCHRE workflow does not currently include conditioned sqft, 
        # so skip intensity columns for now if ochre_workflow is True
        compute_intensity_cols = False
        keep_unmapped_cols = True  # keep all columns for maximum flexibility in Ochre
        logger.info("Column mapping config: OCHRE workflow - pass through all unmapped columns, skip intensity calculations")
    else:
        # ResStock standard workflow
        compute_intensity_cols = True
        keep_unmapped_cols = False  # only include mapped columns for cleaner OEDI output
        logger.info("Column mapping config: ResStock standard workflow - compute intensity columns, drop unmapped columns")
    return compute_intensity_cols, keep_unmapped_cols


def create_query_oedi_timeseries(
    bsq: BuildStockQuery, ochre_workflow: bool = False
) -> str:
    """
    Create the SQL body for a view that transforms raw timeseries results into OEDI format.

    Parameters
    ----------
    bsq : BuildStockQuery
        An initialized BuildStockQuery instance.
    ochre_workflow : bool
        If True, generate OEDI timeseries columns for Ochre workflow.

    Returns
    -------
    str
        The SQL SELECT statement body for the view definition.
    """
    
    compute_intensity_cols, keep_unmapped_cols = _get_column_mapping_config(ochre_workflow)

    table_name = bsq.table_name
    columns = [c.name for c in bsq.ts_table.columns]
    partition_cols = _get_partition_columns(bsq)

    logger.info(f"Timeseries table columns ({len(columns)} total): {columns}")
    logger.info(f"Partition columns inferred from table ({len(partition_cols)} total): {partition_cols}")
    logger.info(f"Starting timeseries column processing: {len(columns)} total columns, {len(partition_cols)} partition columns")

    bldg_id_col = "bldg_id"
    upgrade_col = "upgrade"
    time_col = "timestamp"
    sqft_col = "in.sqft"
    must_have_cols = [bldg_id_col, upgrade_col, time_col]

    # CTE 1: resample timeseries to hourly
    ts_group_cols = ["building_id", "upgrade"] + [
        c for c in partition_cols if c not in {"building_id", "upgrade", "time", "timeutc"}
    ]
    ts_group_exprs = [f'"{c}"' for c in ts_group_cols]
    ts_select_exprs = [f'"{c}"' for c in ts_group_cols]

    # omit timeutc even if it exists since DATE_TRUNC may not align between two time cols
    ts_select_exprs.append('DATE_TRUNC(\'hour\', "time") AS "time"')
    ts_group_exprs.append('DATE_TRUNC(\'hour\', "time")')

    ts_agg_skip_cols = set(ts_group_cols) | {"time", "timeutc"}
    for col in columns:
        if col in ts_agg_skip_cols:
            continue
        if col.endswith("_kwh") or col.endswith("_kbtu"):
            ts_select_exprs.append(f'SUM("{col}") AS "{col}"')
        else:
            ts_select_exprs.append(f'AVG("{col}") AS "{col}"')

    cte_sql_expr = f"""
    WITH ts_table AS (
        SELECT {", ".join(ts_select_exprs)}
        FROM {table_name}_timeseries
        GROUP BY {", ".join(ts_group_exprs)}
    ),
    """

    # CTE 2: simplified baseline
    has_timeutc = False # always false because of CTE 1

    bl_cols = [f'"building_id" AS "{bldg_id_col}"']
    if not has_timeutc:
        bl_cols.append('"build_existing_model.county" AS "in.county"')
    if compute_intensity_cols:
        bl_cols.append(
            f'"upgrade_costs.floor_area_conditioned_ft_2" AS "{sqft_col}"'
        )
    
    cte_sql_expr += f"""
    bl_table AS (
        SELECT {", ".join(bl_cols)}
        FROM {table_name}_baseline
    ),
    """

    # CTE 3: renamed timeseries joined with baseline + time adjustment
    id_cols = [f'"{bldg_id_col}"', f'"{upgrade_col}"']
    if compute_intensity_cols:
        id_cols.append(f'"{sqft_col}"')
    partition_exprs = [f'"{pc}"' for pc in partition_cols if pc not in must_have_cols]
    resampled_time_table = f"""
    (
        SELECT DATE_TRUNC('hour', "time") AS "time"
        FROM {table_name}_timeseries
    )
    """
    time_sql_expr, sim_year = _build_est_time_sql_expr(
        bsq,
        time_col,
        has_timeutc,
        time_table=resampled_time_table,
    )
    skip_cols = set(partition_cols) | {"time", "timeutc", "building_id", "upgrade"}
    ts_exprs, ts_cols = _build_renamed_columns(
        columns, keep_unmapped_cols=keep_unmapped_cols, skip_cols=skip_cols,
    )

    # Identify columns that were not mapped to final table
    mapped_raw_cols = {old for old, _ in ts_cols}
    unmapped_cols = [
        c for c in columns if c not in mapped_raw_cols and c not in skip_cols
    ]
    if unmapped_cols:
        logger.debug("-" * 60)
        logger.warning(f"Unmapped columns ({len(unmapped_cols)})")
        for col in unmapped_cols:
            logger.debug(f"  - {col}")
        logger.debug("-" * 60)
        logger.warning(f"Total unmapped columns (not computed): {len(unmapped_cols)}")
        for col in unmapped_cols:
            logger.warning(f"  - Column not computed: {col}")

    columns_sql_expr = ", \n".join(
        id_cols + partition_exprs + [time_sql_expr] + ts_exprs
    )
    cte_sql_expr += f"""
    renamed_table AS (
    SELECT {columns_sql_expr} FROM bl_table JOIN
    ts_table ON "bldg_id" = "building_id"
    )
    """

    # Final SELECT: id cols + wrapped time + partitions + ts cols + intensity cols
    final_cols = (
        id_cols
        + [_build_wrap_time_to_sim_year_sql_expr(time_col, sim_year)]
        + partition_exprs
        + [f'"{new}"' for _, new in ts_cols]
    )
    if compute_intensity_cols:
        final_cols += _build_intensity_columns(ts_cols, sqft_col)

    final_columns_sql_expr = ", \n".join(final_cols)
    select_sql_expr = f"""
    {cte_sql_expr} SELECT {final_columns_sql_expr} FROM renamed_table
    """
    return select_sql_expr


def create_view_oedi_timeseries(
    bsq: BuildStockQuery,
    view_name: str,
    ochre_workflow: bool = False,
    force: bool = False,
) -> None:
    """Create an Athena view with OEDI timeseries schema.

    Generates the full SELECT SQL via ``create_query_oedi_timeseries`` and
    executes ``create_view`` to register it in the database.

    Parameters
    ----------
    bsq : BuildStockQuery
        An initialized BuildStockQuery instance.
    view_name : str
        Name for the new view.
    ochre_workflow : bool
        If True, use Ochre-aligned column mapping (pass-through unmapped
        columns, skip intensity columns).
    force : bool
        If True, overwrite an existing view with the same name.
    """
    select_sql = create_query_oedi_timeseries(bsq, ochre_workflow=ochre_workflow)
    # logger.info("=" * 60)
    # logger.info("GENERATED SQL:")
    # logger.info("=" * 60)
    # logger.info(select_sql)
    # logger.info("=" * 60)
    create_view(bsq, view_name, select_sql, force)


def _reformat_baseline_column(col: str) -> Optional[str]:
    """Reformat a baseline column name to OEDI double-dot convention.

    For ``out.*`` columns (excluding ``out.params.*``), inserts an extra dot
    before the unit segment to match the timeseries convention.

    Examples
    --------
    >>> _reformat_baseline_column("out.electricity.total.energy_consumption.kwh")
    'out.electricity.total.energy_consumption..kwh'
    >>> _reformat_baseline_column("out.load.cooling.energy_delivered.kbtu")
    'out.load.cooling.energy_delivered..kbtu'
    >>> _reformat_baseline_column("in.sqft")
    None
    >>> _reformat_baseline_column("out.params.door_area_ft_2")
    None

    Parameters
    ----------
    col : str
        Raw column name from the pub_annual table.

    Returns
    -------
    str or None
        Reformatted column name with double-dot, or None if the column
        should not be renamed.
    """
    if not col.startswith("out.") or col.startswith("out.params."):
        return None
    # Insert extra dot before the last segment (the unit)
    last_dot = col.rfind(".")
    if last_dot <= 0:
        return None
    return col[:last_dot] + "." + col[last_dot:]


def create_query_oedi_baseline(bsq: BuildStockQuery) -> str:
    """Build a SELECT statement that renames baseline columns to OEDI convention.

    Queries the pub_annual table schema, then for each ``out.*`` column
    (excluding ``out.params.*``) renames it using the double-dot convention.
    All other columns are passed through unchanged.

    Parameters
    ----------
    bsq : BuildStockQuery
        An initialized BuildStockQuery instance.

    Returns
    -------
    str
        SQL SELECT statement with column aliases.
    """
    source_table = f"{bsq.table_name}_pub_annual"

    # Get column names from the table
    df = bsq.execute(f"SELECT * FROM {source_table} LIMIT 0")
    columns = list(df.columns)

    col_exprs = []
    for col in columns:
        new_col = _reformat_baseline_column(col)
        if new_col is not None:
            col_exprs.append(f'"{col}" AS "{new_col}"')
        else:
            col_exprs.append(f'"{col}"')

    select_sql = f"SELECT {', '.join(col_exprs)} FROM {source_table}"
    return select_sql


def create_view_oedi_baseline(
    bsq: BuildStockQuery,
    view_name: str,
    force: bool = False,
) -> None:
    """Create an Athena view with OEDI baseline schema.

    Renames energy columns in ``<table_name>_pub_annual`` to use the OEDI
    double-dot convention (e.g. ``out.electricity.total.energy_consumption..kwh``)
    and creates the view as ``<table_name>{BL_VIEW_SUFFIX}``.

    Parameters
    ----------
    bsq : BuildStockQuery
        An initialized BuildStockQuery instance.
    view_name : str
        Name for the new view.
    force : bool
        If True, overwrite an existing view with the same name.
    """
    select_sql = create_query_oedi_baseline(bsq)
    create_view(bsq, view_name, select_sql, force)


def check_view_oedi_timeseries(
    bsq: BuildStockQuery,
    view_name: str,
    ochre_workflow: bool = False,
    limit_rows: int = 10,
) -> None:
    """Run basic validation checks on a created timeseries view.

    Queries the view and verifies:
    1. Expected columns are present (timestamp, energy_consumption, intensity).
    2. All timestamps share a single simulation year.
    3. The number of distinct timestamps matches a full year at the detected
       timestep resolution.

    A sample CSV of the first ``limit_rows`` rows is saved to the working
    directory.

    Parameters
    ----------
    bsq : BuildStockQuery
        An initialized BuildStockQuery instance.
    view_name : str
        Name of the view to check.
    ochre_workflow : bool
        If True, skip intensity-column checks.
    limit_rows : int
        Number of sample rows to fetch for the CSV export.

    Raises
    ------
    ValueError
        If expected column types are missing from the view.
    AssertionError
        If timestamps span multiple years or the count is unexpected.
    """
    compute_intensity_cols, _ = _get_column_mapping_config(ochre_workflow)

    logger.debug("-" * 60)
    logger.info(f"Checking results of view '{view_name}', this may take a few moments...")
    logger.debug("-" * 60)
    t0 = time.time()
    # 1. Check that expected columns are present
    df = bsq.execute(f"SELECT * FROM {view_name} LIMIT {limit_rows}")

    logger.info(f"Columns in view '{view_name}' ({len(df.columns)} total): {list(df.columns)}")

    filename = f"{view_name}_sample_output.csv"
    df.to_csv(filename, index=False)
    logger.info(f"Sample view output saved to: {filename}")

    missing_cols = []
    if "timestamp" not in df.columns:
        missing_cols.append("timestamp")
    if compute_intensity_cols:
        has_intensity = any("intensity" in c for c in df.columns)
        if not has_intensity:
            missing_cols.append("*intensity*")
    has_energy_consumption = any("energy_consumption" in c for c in df.columns)
    if not has_energy_consumption:
        missing_cols.append("*energy_consumption*")

    if missing_cols:
        raise ValueError(
            f"Expected {missing_cols} column type(s) not found in view results. Check printed columns above."
        )

    # 2. Check timestamps are in simulation-year and has expected number of unique timestamps
    df2 = bsq.execute(f"""SELECT DISTINCT timestamp FROM {view_name} ORDER BY 1""")
    assert (
        df2["timestamp"].dt.year.nunique() == 1
    ), "Timestamps are not all in the same year."

    year = df2["timestamp"].dt.year[0]
    timestep_hours = (
        df2["timestamp"].iloc[1] - df2["timestamp"].iloc[0]
    ).total_seconds() / 3600
    expected_hours = (
        pd.Timestamp(year=year + 1, month=1, day=1, hour=0)
        - pd.Timestamp(year=year, month=1, day=1, hour=0)
    ).total_seconds() / 3600
    expected_timesteps = int(expected_hours / timestep_hours)
    assert (
        len(df2) == expected_timesteps
    ), f"Expected {expected_timesteps} unique timestamps for a full simulation year with {timestep_hours}-hour timesteps, but found {len(df2)}."
    
    logger.info(f"View '{view_name}' passed basic checks on column names and timestamps.")
    logger.info(f"check_view_result completed in {time.time() - t0:.1f}s")


# =============================================================================
# boto3 fallback — used when BuildStockQuery cannot initialize (e.g. table
# does not yet exist in Athena/Glue).
# =============================================================================


def get_athena_client(region_name: str = "us-west-2"):
    """Create a boto3 Athena client.

    Parameters
    ----------
    region_name : str
        AWS region (default: us-west-2).

    Returns
    -------
    botocore.client.Athena
        A boto3 Athena service client.
    """
    return boto3.client("athena", region_name=region_name)


def wait_for_query(client, execution_id: str, max_wait: int = 300) -> dict:
    """Poll until an Athena query completes or fails.

    Parameters
    ----------
    client : botocore.client.Athena
        boto3 Athena client.
    execution_id : str
        The Athena query execution ID to monitor.
    max_wait : int
        Maximum seconds to wait before raising TimeoutError.

    Returns
    -------
    dict
        Full GetQueryExecution response once the query reaches a terminal state.

    Raises
    ------
    TimeoutError
        If the query does not complete within ``max_wait`` seconds.
    """
    elapsed = 0
    while elapsed < max_wait:
        response = client.get_query_execution(QueryExecutionId=execution_id)
        state = response["QueryExecution"]["Status"]["State"]
        if state in ("SUCCEEDED", "FAILED", "CANCELLED"):
            return response
        time.sleep(2)
        elapsed += 2
    raise TimeoutError(f"Query {execution_id} did not complete within {max_wait}s")


def _start_query(
    client,
    query_string: str,
    database: str,
    workgroup: str,
    s3_output: Optional[str] = None,
) -> str:
    """
    Start an Athena query, defaulting to workgroup-managed output location.

    If the workgroup does not have an output location configured and no
    s3_output is provided, raises a RuntimeError with guidance.
    """
    kwargs = {
        "QueryString": query_string,
        "QueryExecutionContext": {"Database": database},
        "WorkGroup": workgroup,
    }
    if s3_output:
        kwargs["ResultConfiguration"] = {"OutputLocation": s3_output}

    try:
        response = client.start_query_execution(**kwargs)
    except ClientError as e:
        error_code = e.response["Error"]["Code"]
        error_msg = e.response["Error"]["Message"]
        if (
            error_code == "InvalidRequestException"
            and "output location" in error_msg.lower()
        ):
            raise RuntimeError(
                f"Workgroup '{workgroup}' does not have a default output location configured. "
                f"Either configure the workgroup's output location in the AWS console, or "
                f"pass an explicit s3_output parameter."
            ) from e
        raise
    return response["QueryExecutionId"]


def list_tables_boto3(
    database: str,
    workgroup: str = "primary",
    s3_output: Optional[str] = None,
    region_name: str = "us-west-2",
) -> list[str]:
    """
    List all tables in an Athena database using boto3 directly.

    Defaults to workgroup-managed query result location. Pass s3_output
    explicitly if the workgroup does not have one configured.

    Parameters
    ----------
    database : str
        The Athena/Glue database name.
    workgroup : str
        Athena workgroup name.
    s3_output : str, optional
        S3 path for Athena query results. If None, uses workgroup default.
    region_name : str
        AWS region.

    Returns
    -------
    list[str]
        Table names in the database.
    """
    client = get_athena_client(region_name)
    execution_id = _start_query(
        client, f"SHOW TABLES IN {database}", database, workgroup, s3_output
    )
    wait_for_query(client, execution_id)

    results = client.get_query_results(QueryExecutionId=execution_id)
    tables = [row["Data"][0]["VarCharValue"] for row in results["ResultSet"]["Rows"]]
    return tables


def _infer_parquet_schema_from_s3(
    s3_location: str, region_name: str = "us-west-2"
) -> list[dict]:
    """
    Read schema from the first Parquet file found at an S3 location.

    Returns a list of dicts: [{"Name": col_name, "Type": athena_type}, ...]
    """
    s3 = boto3.client("s3", region_name=region_name)
    path = s3_location[5:]  # strip "s3://"
    bucket, _, prefix = path.partition("/")
    if prefix and not prefix.endswith("/"):
        prefix += "/"

    # Find first .parquet file (prefer smaller files for faster schema read)
    response = s3.list_objects_v2(Bucket=bucket, Prefix=prefix, MaxKeys=100)
    parquet_key = None
    parquet_size = float("inf")
    for obj in response.get("Contents", []):
        key = obj["Key"]
        if key.endswith(".parquet") or key.endswith(".snappy.parquet"):
            if obj["Size"] < parquet_size:
                parquet_key = key
                parquet_size = obj["Size"]

    if not parquet_key:
        raise FileNotFoundError(f"No Parquet files found at s3://{bucket}/{prefix}")

    # Read schema via boto3 (handles keys with special characters like commas/spaces)
    obj = s3.get_object(Bucket=bucket, Key=parquet_key)
    buf = io.BytesIO(obj["Body"].read())
    schema = pq.read_schema(buf)

    # Map pyarrow types to Athena/Hive types
    type_map = {
        "int8": "tinyint",
        "int16": "smallint",
        "int32": "int",
        "int64": "bigint",
        "float": "float",
        "double": "double",
        "bool": "boolean",
        "string": "string",
        "large_string": "string",
        "binary": "binary",
        "date32[day]": "date",
    }

    columns = []
    for field in schema:
        pa_type = str(field.type)
        if pa_type.startswith("timestamp"):
            athena_type = "timestamp"
        elif pa_type.startswith("decimal"):
            athena_type = pa_type  # e.g. "decimal(10,2)"
        elif pa_type.startswith("list"):
            athena_type = "string"  # simplified fallback
        else:
            athena_type = type_map.get(pa_type, "string")
        columns.append({"Name": field.name, "Type": athena_type})

    return columns


def create_external_table(
    database: str,
    table_name: str,
    s3_location: str,
    workgroup: str = "primary",
    s3_output: Optional[str] = None,
    input_format: str = "PARQUET",
    region_name: str = "us-west-2",
) -> None:
    """
    Create an external table in Athena/Glue pointing to existing data on S3.

    For Parquet/ORC, infers the schema from the data files and registers the
    table via the Glue API directly (avoids Athena DDL column-list requirement).

    Parameters
    ----------
    database : str
        The Athena/Glue database name.
    table_name : str
        Name for the new external table.
    s3_location : str
        S3 path where the data lives (e.g. "s3://bucket/path/to/data/").
    workgroup : str
        Athena workgroup name.
    s3_output : str, optional
        S3 path for Athena query results/logs. If None, uses workgroup default.
    input_format : str
        Storage format of the source data (PARQUET, ORC, JSON, CSV).
    region_name : str
        AWS region.

    Raises
    ------
    RuntimeError
        If table creation fails.
    """
    fmt = input_format.upper()

    # For self-describing formats, use Glue API with inferred schema
    if fmt in ("PARQUET", "ORC"):
        format_configs = {
            "PARQUET": {
                "InputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat",
                "OutputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat",
                "SerdeInfo": {
                    "SerializationLibrary": "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe",
                },
            },
            "ORC": {
                "InputFormat": "org.apache.hadoop.hive.ql.io.orc.OrcInputFormat",
                "OutputFormat": "org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat",
                "SerdeInfo": {
                    "SerializationLibrary": "org.apache.hadoop.hive.ql.io.orc.OrcSerde",
                },
            },
        }

        logger.info(f"Inferring schema from Parquet files at '{s3_location}'...")
        columns = _infer_parquet_schema_from_s3(s3_location, region_name)
        logger.info(f"Found {len(columns)} columns.")

        # Ensure trailing slash for Location
        location = s3_location if s3_location.endswith("/") else s3_location + "/"

        storage_descriptor = {
            "Columns": columns,
            "Location": location,
            "InputFormat": format_configs[fmt]["InputFormat"],
            "OutputFormat": format_configs[fmt]["OutputFormat"],
            "SerdeInfo": format_configs[fmt]["SerdeInfo"],
        }

        glue = boto3.client("glue", region_name=region_name)
        try:
            glue.create_table(
                DatabaseName=database,
                TableInput={
                    "Name": table_name,
                    "TableType": "EXTERNAL_TABLE",
                    "Parameters": {
                        "classification": fmt.lower(),
                        "EXTERNAL": "TRUE",
                    },
                    "StorageDescriptor": storage_descriptor,
                },
            )
        except ClientError as e:
            if e.response["Error"]["Code"] == "AlreadyExistsException":
                logger.info(f"Table '{table_name}' already exists.")
                return
            raise RuntimeError(
                f"Glue create_table failed: {e.response['Error']['Message']}"
            ) from e

        logger.info(f"External table '{table_name}' created via Glue pointing to '{s3_location}'.")
        return

    # For non-self-describing formats, fall back to Athena DDL
    format_configs = {
        "JSON": (
            "org.openx.data.jsonserde.JsonSerDe",
            "org.apache.hadoop.mapred.TextInputFormat",
            "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
        ),
        "CSV": (
            "org.apache.hadoop.hive.serde2.OpenCSVSerde",
            "org.apache.hadoop.mapred.TextInputFormat",
            "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
        ),
    }

    if fmt not in format_configs:
        raise ValueError(
            f"Unsupported format '{input_format}'. Use one of: PARQUET, ORC, JSON, CSV"
        )

    serde, input_fmt, output_fmt = format_configs[fmt]
    ddl = (
        f"CREATE EXTERNAL TABLE IF NOT EXISTS {table_name} "
        f"ROW FORMAT SERDE '{serde}' "
        f"STORED AS INPUTFORMAT '{input_fmt}' "
        f"OUTPUTFORMAT '{output_fmt}' "
        f"LOCATION '{s3_location}' "
        f"TBLPROPERTIES ('classification'='{fmt.lower()}')"
    )

    client = get_athena_client(region_name)
    execution_id = _start_query(client, ddl, database, workgroup, s3_output)
    result = wait_for_query(client, execution_id)

    state = result["QueryExecution"]["Status"]["State"]
    if state != "SUCCEEDED":
        reason = result["QueryExecution"]["Status"].get("StateChangeReason", "unknown")
        raise RuntimeError(f"CREATE EXTERNAL TABLE failed ({state}): {reason}")

    logger.info(f"External table '{table_name}' created pointing to '{s3_location}'.")


def _list_s3_subfolders(s3_location: str, region_name: str = "us-west-2") -> list[str]:
    """
    List immediate subfolder names under an S3 prefix.

    Parameters
    ----------
    s3_location : str
        S3 path (e.g. "s3://bucket/prefix/").
    region_name : str
        AWS region.

    Returns
    -------
    list[str]
        Subfolder names (without trailing slash).
    """
    s3 = boto3.client("s3", region_name=region_name)
    path = s3_location[5:]  # strip "s3://"
    bucket, _, prefix = path.partition("/")
    if prefix and not prefix.endswith("/"):
        prefix += "/"

    response = s3.list_objects_v2(Bucket=bucket, Prefix=prefix, Delimiter="/")
    subfolders = []
    for cp in response.get("CommonPrefixes", []):
        # cp["Prefix"] is like "prefix/subfolder/"
        folder_name = cp["Prefix"][len(prefix) :].rstrip("/")
        if folder_name:
            subfolders.append(folder_name)
    return subfolders


def ensure_table_exists(
    database: str,
    table: str,
    workgroup: str = "primary",
    s3_location: Optional[str] = None,
    s3_output: Optional[str] = None,
    input_format: str = "PARQUET",
    region_name: str = "us-west-2",
) -> None:
    """
    Ensure tables exist in Athena for each subfolder under the S3 location.

    For each immediate subfolder under s3_location (e.g. baseline/, timeseries/,
    upgrades/), creates an external table named <table>_<subfolder_name> if it
    does not already exist. This matches BuildStockQuery's naming convention.

    Parameters
    ----------
    database : str
        The Athena/Glue database name.
    table : str
        The base table name prefix.
    workgroup : str
        Athena workgroup name.
    s3_location : str, optional
        S3 path to raw data root. Required if tables do not already exist.
    s3_output : str, optional
        S3 path for query results. If None, uses workgroup default.
    input_format : str
        Source data format (PARQUET, ORC, JSON, CSV).
    region_name : str
        AWS region.

    Raises
    ------
    SystemExit
        If tables do not exist and no s3_location is provided.
    """
    tables = list_tables_boto3(
        database, workgroup=workgroup, s3_output=s3_output, region_name=region_name
    )
    logger.info(f"Available tables for database='{database}': {tables}")
    logger.debug("-" * 40)

    if not s3_location:
        # Check if any expected sub-tables exist
        if table in tables or any(t.startswith(f"{table}_") for t in tables):
            logger.info(f"Table(s) for '{table}' already exist.")
            return
        raise SystemExit(
            f"Table '{table}' not found and --s3-location not provided. "
            f"Pass --s3-location to create the external table(s)."
        )

    logger.info(f"Table '{table}' not found. Creating external table(s) using Glue API...")
    # Discover subfolders under the S3 location
    s3_loc = s3_location if s3_location.endswith("/") else s3_location + "/"
    subfolders = _list_s3_subfolders(s3_loc, region_name)

    if not subfolders:
        # No subfolders — create a single table at the root location
        if table not in tables:
            create_external_table(
                database=database,
                table_name=table,
                s3_location=s3_loc,
                workgroup=workgroup,
                s3_output=s3_output,
                input_format=input_format,
                region_name=region_name,
            )
        else:
            logger.info(f"Table '{table_name}' already exists.")
        return

    # Create a table for each subfolder: <table>_<subfolder_name>
    logger.info(f"Found subfolders: {subfolders}")
    for subfolder in subfolders:
        sub_table_name = f"{table}_{subfolder}"
        sub_s3_location = f"{s3_loc}{subfolder}/"
        if sub_table_name in tables:
            logger.info(f"Table '{table_name}' already exists.")
            continue
        logger.info(f"Creating external table '{sub_table_name}' -> '{sub_s3_location}'...")
        try:
            create_external_table(
                database=database,
                table_name=sub_table_name,
                s3_location=sub_s3_location,
                workgroup=workgroup,
                s3_output=s3_output,
                input_format=input_format,
                region_name=region_name,
            )
        except FileNotFoundError as e:
            logger.warning(f"  Skipping '{sub_table_name}': {e}")
            continue
        logger.info(f"Table '{sub_table_name}' created.")
        logger.debug("-" * 40)


# --- EIA ID weights table ---
def ensure_eiaid_weights_table(
    database: str,
    workgroup: str = "primary",
    region_name: str = "us-west-2",
) -> None:
    """
    Ensure the eiaid_weights table exists in the given Athena database.

    This table maps county FIPS codes to EIA utility IDs with associated weights.
    It is required by BuildStockQuery's utility_query module for LRD comparisons.
    If the table does not exist, it is created as a CSV external table pointing
    to the canonical S3 location.

    Parameters
    ----------
    database : str
        The Athena/Glue database name.
    workgroup : str
        Athena workgroup name.
    region_name : str
        AWS region.
    """
    tables = list_tables_boto3(
        database, workgroup=workgroup, region_name=region_name
    )
    if EIAID_WEIGHTS_TABLE in tables:
        logger.info(f"Table '{EIAID_WEIGHTS_TABLE}' already exists (race condition).")
        return

    logger.info(f"Table '{EIAID_WEIGHTS_TABLE}' not found in '{database}'. Creating...")
    glue = boto3.client("glue", region_name=region_name)
    try:
        glue.create_table(
            DatabaseName=database,
            TableInput={
                "Name": EIAID_WEIGHTS_TABLE,
                "TableType": "EXTERNAL_TABLE",
                "Parameters": {
                    "EXTERNAL": "TRUE",
                    "skip.header.line.count": "1",
                },
                "StorageDescriptor": {
                    "Columns": [
                        {"Name": "county", "Type": "string"},
                        {"Name": "eiaid", "Type": "string"},
                        {"Name": "weight", "Type": "double"},
                        {"Name": "gisjoin", "Type": "string"},
                    ],
                    "Location": EIAID_WEIGHTS_S3_LOCATION,
                    "InputFormat": "org.apache.hadoop.mapred.TextInputFormat",
                    "OutputFormat": "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
                    "SerdeInfo": {
                        "SerializationLibrary": "org.apache.hadoop.hive.serde2.OpenCSVSerde",
                        "Parameters": {
                            "quoteChar": '"',
                            "separatorChar": ",",
                            "serialization.format": "1",
                        },
                    },
                },
            },
        )
    except ClientError as e:
        if e.response["Error"]["Code"] == "AlreadyExistsException":
            logger.info(f"Table '{EIAID_WEIGHTS_TABLE}' already exists (race condition).")
            return
        raise RuntimeError(
            f"Failed to create '{EIAID_WEIGHTS_TABLE}': {e.response['Error']['Message']}"
        ) from e

    logger.info(f"Table '{EIAID_WEIGHTS_TABLE}' created in '{database}' pointing to '{EIAID_WEIGHTS_S3_LOCATION}'.")


def main() -> None:
    """CLI entry point for creating OEDI timeseries views from ResStock results.

    Parses command-line arguments, initializes a BuildStockQuery connection
    (falling back to boto3 table creation if needed), and creates an Athena
    view with the OEDI timeseries schema. Optionally runs basic validation
    checks on the resulting view.
    """
    # Configure logging with both console and file handlers
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler('process_timeseries_results.log'),
            logging.StreamHandler()
        ]
    )
    logger.info("Starting process_timeseries_results script")
    parser = argparse.ArgumentParser(
        description="Create an Athena view from raw timeseries results."
    )
    parser.add_argument(
        "-d", "--database", required=True, help="Athena/Glue database name."
    )
    parser.add_argument("-t", "--table", required=True, help="Source table name.")
    parser.add_argument(
        "-w",
        "--workgroup",
        default="primary",
        help="Athena workgroup (default: primary).",
    )
    parser.add_argument(
        "-l",
        "--s3-location",
        default=None,
        help="S3 path to raw data (for creating external table).",
    )
    parser.add_argument(
        "-r", "--region", default="us-west-2", help="AWS region (default: us-west-2)."
    )
    parser.add_argument(
        "-i",
        "--input-format",
        default="PARQUET",
        help="Source data format (default: PARQUET).",
    )
    parser.add_argument(
        "-f",
        "--force",
        action="store_true",
        help="Overwrite existing view if it already exists.",
    )
    parser.add_argument(
        "-c",
        "--check",
        action="store_true",
        help="Run check_view_result after creating the view.",
    )
    parser.add_argument(
        "-o",
        "--ochre-workflow",
        action="store_true",
        help="Whether output results are from OCHRE.",
    )
    parser.add_argument(
        "-b",
        "--baseline-view",
        action="store_true",
        help="Also create the baseline view (SELECT * FROM <table>_pub_annual).",
    )
    args = parser.parse_args()

    logger.info("=" * 60)
    logger.info("Processing timeseries result to OEDI/sightglass format (per resstock_oedi_new db_schema) with the following input parameters:")
    logger.debug("-" * 60)
    logger.info(f"  database:      {args.database}")
    logger.info(f"  table:         {args.table}")
    logger.info(f"  workgroup:     {args.workgroup}")
    logger.info(f"  s3-location:   {args.s3_location}")
    logger.info(f"  region:        {args.region}")
    logger.info(f"  input-format:  {args.input_format}")
    logger.info(f"  force:         {args.force}")
    logger.info(f"  check:         {args.check}")
    logger.info(f"  ochre-workflow: {args.ochre_workflow}")
    logger.info(f"  baseline-view: {args.baseline_view}")
    logger.info("=" * 60)
    
    # Log execution parameters
    logger.info("Processing parameters:")
    logger.info(f"  database={args.database}, table={args.table}, workgroup={args.workgroup}")
    logger.info(f"  ochre_workflow={args.ochre_workflow}, baseline_view={args.baseline_view}")
    logger.info(f"  force={args.force}, check={args.check}")

    # --- Try BuildStockQuery path first; fall back to boto3 if table missing ---
    try:
        bsq = initialize_buildstock_query(
            database=args.database, table=args.table, workgroup=args.workgroup
        )

    except Exception as e:
        logger.info("=" * 60)
        logger.error("BuildStockQuery initialization failed")
        logger.info("=" * 60)
        logger.error(f"Exception type: {type(e).__name__}")
        logger.error(f"Exception message: {e}")
        logger.error("For detailed diagnostic information, check process_timeseries_results.log")
        logger.info("=" * 60)
        logger.error("Falling back to boto3 workflow to ingest S3 data first into Athena...")
        logger.error(f"Caught exception during initialize_buildstock_query fallback:")
        logger.error(f"  Exception type: {type(e).__name__}")
        logger.error(f"  Exception message: {str(e)}")
        logger.debug(f"  Full traceback:\n{traceback.format_exc()}")

        # Validate required inputs for the boto3 fallback path
        missing = []
        if not args.s3_location:
            missing.append("--s3-location")
        if not args.workgroup:
            missing.append("--workgroup")
        if missing:
            raise SystemExit(
                f"The boto3 fallback requires additional arguments: {', '.join(missing)}.\n"
                f"Usage example:\n"
                f"  python process_timeseries_results.py \\\n"
                f"    --database <db_name> \\\n"
                f"    --table <table_name> \\\n"
                f"    --workgroup <workgroup_name> \\\n"
                f"    --s3-location s3://bucket/path/to/data/ \\\n"
                f"    [--s3-output s3://bucket/query-results/] \\\n"
                f"    [--input-format PARQUET] \\\n"
                f"    [--region us-west-2]"
            )

        ensure_table_exists(
            database=args.database,
            table=args.table,
            workgroup=args.workgroup,
            s3_location=args.s3_location,
            input_format=args.input_format,
            region_name=args.region,
        )

        bsq = initialize_buildstock_query(
            database=args.database, table=args.table, workgroup=args.workgroup
        )

    # --- resume with BuildStockQuery path (will succeed now if we had to create the external table) ---

    # Ensure the eiaid_weights table exists (needed by BSQ utility_query for LRD comparisons)
    ensure_eiaid_weights_table(
        database=args.database,
        workgroup=args.workgroup,
        region_name=args.region,
    )

    logger.debug("-" * 60)
    logger.info("Creating view from raw timeseries results...")
    logger.debug("-" * 60)

    if args.baseline_view:
        bl_view_name = f"{args.table}{BL_VIEW_SUFFIX}"
        logger.info(f"Creating baseline view: {bl_view_name}")
        create_view_oedi_baseline(bsq, view_name=bl_view_name, force=args.force)
        logger.info(f"Successfully created baseline view: {bl_view_name}")

    ts_view_name = f"{args.table}{TS_VIEW_SUFFIX}"
    logger.info(f"Creating timeseries view: {ts_view_name}")
    create_view_oedi_timeseries(
        bsq,
        view_name=ts_view_name,
        ochre_workflow=args.ochre_workflow,
        force=args.force,
    )
    logger.info(f"Successfully created timeseries view: {ts_view_name}")
    
    if args.check:
        logger.info(f"Running validation checks on view: {ts_view_name}")
        check_view_oedi_timeseries(bsq, view_name=ts_view_name, ochre_workflow=args.ochre_workflow)
        logger.info(f"Validation checks completed for view: {ts_view_name}")
    
    logger.info("process_timeseries_results script completed successfully")
    logger.info("=" * 60)
    logger.info("Processing completed. Check process_timeseries_results.log for detailed traceability.")
    logger.info("=" * 60)

if __name__ == "__main__":
    main()
