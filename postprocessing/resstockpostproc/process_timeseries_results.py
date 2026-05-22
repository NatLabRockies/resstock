"""
This script will create an Athena view from raw timeseries results following
the SightGlassDataProcessing OEDI timeseries format.
===================================================================================

The view will be created in the same database as the source table, and will be
named <table_name>_timeseries_view.

If a table does not yet exist in the database, rerun the script by adding an S3
path to create an external table pointing to the raw data on S3 using boto3. The
script will create the view on top of that.

The view definition will perform the following transformations:

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
"""

import re
import time
import argparse
from typing import Optional, Union, Literal
from pathlib import Path
import pandas as pd

import boto3
from botocore.exceptions import ClientError
import pyarrow.parquet as pq
from buildstock_query import BuildStockQuery

options_lookup_file = Path(__file__).parents[2] / "resources" / "options_lookup.tsv"

energy_unit_conv_to_kwh = {
    "mbtu": 293.07107,
    "kbtu": 0.29307107,
    "therm": 29.3001,
}


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

    bsq = BuildStockQuery(
        workgroup=workgroup,
        db_name=database,
        table_name=table,
        buildstock_type=buildstock_type,
        db_schema=db_schema,
        sample_weight_override=1,
        **kwargs,
    )
    print("bsq handle initialized")

    return bsq


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

    print(f"View '{view_name}' created successfully in database '{bsq.db_name}'.")
    return state, reason


def read_options_lookup() -> pd.DataFrame:
    """
    Read the options_lookup.tsv file into a pandas dataframe
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


def get_county_utc_offset() -> dict[str, int]:
    """
    Get the UTC offset for each county from options_lookup
    """
    df = read_options_lookup()
    cond = df["Parameter Name"] == "County"
    dct = df.loc[cond].set_index("Option Name")["Measure Arg 4"].to_dict()
    dct = {k: int(v.removeprefix("site_time_zone_utc_offset=")) for k, v in dct.items()}
    return dct


def create_query_part_conditional_county_utc_offset() -> str:
    """Create a SQL CASE statement to adjust time based on county UTC offset.
    E.g., CASE WHEN county IN ('NY, Albany County', ...) THEN -5
    """
    county_utc_offsets = get_county_utc_offset()

    # group counties by their UTC offset
    offset_groups = {}
    for county, offset in county_utc_offsets.items():
        offset_groups.setdefault(offset, []).append(county)

    # create a CASE statement to adjust time based on county
    case_statements = []
    for offset, counties in offset_groups.items():
        county_list = ", ".join(f"'{c.replace(chr(39), chr(39)*2)}'" for c in counties)
        case_statements.append(f'WHEN "county" IN ({county_list}) THEN {offset}')

    case_sql = "CASE\n" + "\n".join(case_statements) + "\nELSE 0 END"
    return case_sql


def create_query_part_est_time(
    bsq: BuildStockQuery, time_col: str, has_timeutc: bool
) -> tuple[str, int]:
    """
    Create sql string to format time column to Eastern Standard Time (EST), period-beginning

    Not time-wrapping yet to simulation year

    EST is UTC-5, so direction of math is:
        -   From EST to UTC, add 5 hrs, or SUBTRACT UTC-offset value: -(-5)
        -   From UTC to EST, subtract 5 hrs, or ADD UTC-offset value: +(-5)
    """
    table_name = bsq.table_name

    try:
        time_convention = bsq.execute(f"""
            SELECT "report_simulation_output.timeseries_timestamp_convention" FROM {table_name}_baseline
            LIMIT 1
        """).iloc[0, 0]

    except Exception as e:
        print(
            f"Could not determine timeseries timestamp convention from {table_name}_baseline. Defaulting to 'end'. Error: {e}"
        )
        time_convention = "end"

    df = bsq.execute(f"""
        SELECT DISTINCT "time" FROM {table_name}_timeseries
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
        time_sql = f"""
        DATE_ADD('minute', {delta_minutes}, "timeutc") AS "{time_col}"
        """

    else:
        # additionally add conversion from local standard time to UTC
        county_utc_offset_sql = create_query_part_conditional_county_utc_offset()

        # must minus the county UTC offset (in hours) because it's going from local standard to UTC
        time_sql = f"""
        DATE_ADD('minute', {delta_minutes} - 60 * ({county_utc_offset_sql}), "time") AS "{time_col}"
        """

    return time_sql, sim_year


def create_query_part_wrap_time_to_sim_year(time_col: str, target_year: int) -> str:
    """
    Create a SQL expression to wrap time back to the simulation year.

    In Athena SQL (Presto/Trino), replacing the year is done with date_add('year', target_year - year(col), col)
    """
    time_sql = f"""
    DATE_ADD('year', {target_year} - YEAR("{time_col}"), "{time_col}") AS "{time_col}"
    """
    return time_sql


def get_partition_columns(bsq: BuildStockQuery) -> list[str]:
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


def reformat_fuel_column(col: str) -> Optional[tuple[str, str]]:
    """
    Reformat fuel columns from the raw timeseries table to match OEDI schema.
    """
    m1 = re.search(
        r"^(electricity|natural_gas|fuel_oil|propane|wood)_(\w+)_(kwh|therm|mbtu)",
        col,
    )
    m2 = re.search(
        r"^total_site_(electricity|natural_gas|fuel_oil|propane|wood)_(kwh|therm|mbtu)",
        col,
    )
    m3 = re.search(r"^(total)_(site_energy)_(kwh|therm|mbtu)", col)

    if not (m1 or m2 or m3):
        return None, None

    if m1:
        fueltype, enduse, fuel_units = m1.groups()
    elif m2:
        fueltype, fuel_units = m2.groups()
        enduse = "total"
    elif m3:
        enduse, fueltype, fuel_units = m3.groups()

    new_col = f"out.{fueltype}.{enduse}.energy_consumption"
    return new_col, fuel_units


# Mapping of raw end-use names to final (OEDI) end-use names
_ENDUSE_REMAP = {
    "electric_vehicle_charging": "ev_charging",
    "heating_heat_pump_backup": "heating_hp_bkup",
    "heating_heat_pump_backup_fans_pumps": "heating_hp_bkup_fa",
    "permanent_spa_heater": "permanent_spa_heat",
}

# Unit conversions: (raw_unit, final_unit, multiplier)
# For energy columns that need kBtu → kWh conversion
_UNIT_CONVERSIONS = {
    "kbtu": ("kwh", 0.293071),
    "kwh": ("kwh", 1.0),
    "btu/(hr*ft^2)": ("watt_per_m2", 3.15459),
    "mph": ("meter_per_second", 0.44704),
    "f": ("c", None),  # special: (F-32)*5/9
    "%": ("percentage", 1.0),
    "fraction": ("kgwater_per_kgdryair", 1.0),
    "kgwater/kgdryair": ("kgwater_per_kgdryair", 1.0),
    "hr": ("hour", 1.0),
    "gal": ("gal", 1.0),
}


def reformat_raw_column(col: str) -> Optional[tuple[str, str, Optional[float]]]:
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
        enduse = _ENDUSE_REMAP.get(enduse, enduse)
        final_unit, mult = _UNIT_CONVERSIONS.get(unit, (unit, 1.0))
        new_col = f"out.{fuel}.{enduse}.energy_consumption..{final_unit}"
        return new_col, unit, mult

    # Pattern 2: fuel_use__<fuel>__<total|net>__<unit>
    m = re.match(r"^fuel_use__(\w+)__(\w+)__(\w+)$", col)
    if m:
        fuel, agg, unit = m.groups()
        final_unit, mult = _UNIT_CONVERSIONS.get(unit, (unit, 1.0))
        new_col = f"out.{fuel}.{agg}.energy_consumption..{final_unit}"
        return new_col, unit, mult

    # Pattern 3: energy_use__<total|net>__<unit>
    m = re.match(r"^energy_use__(\w+)__(\w+)$", col)
    if m:
        agg, unit = m.groups()
        final_unit, mult = _UNIT_CONVERSIONS.get(unit, (unit, 1.0))
        new_col = f"out.site_energy.{agg}.energy_consumption..{final_unit}"
        return new_col, unit, mult

    # Pattern 4: hot_water__<enduse>__<unit>
    m = re.match(r"^hot_water__(\w+)__(\w+)$", col)
    if m:
        enduse, unit = m.groups()
        final_unit, mult = _UNIT_CONVERSIONS.get(unit, (unit, 1.0))
        new_col = f"out.hot_water.{enduse}..{final_unit}"
        return new_col, unit, mult

    # Pattern 5: load__<type>__<subtype>__<unit>
    m = re.match(r"^load__(\w+)__(\w+)__(\w+)$", col)
    if m:
        load_type, subtype, unit = m.groups()
        final_unit, mult = _UNIT_CONVERSIONS.get(unit, (unit, 1.0))
        new_col = f"out.load.{load_type}.{subtype}..{final_unit}"
        return new_col, unit, mult

    # Pattern 6: unmet_hours__<type>__<unit>
    m = re.match(r"^unmet_hours__(\w+)__(\w+)$", col)
    if m:
        utype, unit = m.groups()
        final_unit, mult = _UNIT_CONVERSIONS.get(unit, (unit, 1.0))
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
        zone_clean = zone.replace("_-_", " - ").replace("_", " ").replace(" ", "_")
        # Keep zone as-is with underscores (matching raw format)
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
            ("drybulb_temperature", "f"): ("out.outdoor_air_drybulb_temp..c", "f", None),
            ("wetbulb_temperature", "f"): ("out.outdoor_air_wetbulb_temp..c", "f", None),
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


def create_query_oedi_timeseries(bsq: BuildStockQuery) -> str:
    """
    Create the SQL body for a view that transforms raw timeseries results into OEDI format.

    Parameters
    ----------
    bsq : BuildStockQuery
        An initialized BuildStockQuery instance.
    partition_cols : Optional[list[str]]
        Partition column names. If None, auto-detected from table metadata.

    Returns
    -------
    str
        The SQL SELECT statement body for the view definition.
    """
    table_name = bsq.table_name
    columns = [c.name for c in bsq.ts_table.columns]

    # Auto-detect partition columns from table metadata
    partition_cols = get_partition_columns(bsq)

    print(f"Timeseries table columns ({len(columns)} total): {columns}")
    print(f"Partition columns: {partition_cols}")

    bldg_id_col = "bldg_id"
    upgrade_col = "upgrade"
    time_col = "timestamp"
    sqft_col = "in.sqft"

    must_have_cols = [
        bldg_id_col,
        upgrade_col,
        time_col,
    ]  # these columns are called out explicitly in the SQL

    # CTE table 1: simplified baseline
    if "timeutc" in columns:
        county_sql = ""
        has_timeutc = True
    else:
        county_sql = '"build_existing_model.county" AS "in.county",'
        has_timeutc = False

    cte_sql = f"""
    WITH bl_table AS (
        SELECT "building_id" AS "{bldg_id_col}", {county_sql}
        "upgrade_costs.floor_area_conditioned_ft_2" AS "{sqft_col}"
        FROM {table_name}_baseline
        ),
    """

    # CTE table 2: timeseries table with renamed columns joined with simplified baseline table and time adjustment to EST
    columns_sql_list = [
        f'"{bldg_id_col}"',
        f'"{upgrade_col}"',
        f'"{sqft_col}"',
    ]
    for pc in partition_cols:
        if (
            pc not in must_have_cols
        ):  # avoid duplicating partition columns that are already called out explicitly
            columns_sql_list.append(f'"{pc}"')
    time_sql, sim_year = create_query_part_est_time(
        bsq, time_col, has_timeutc
    )  # use sim_year to wrap time in the final select statement
    columns_sql_list.append(time_sql)
    ts_cols = []
    for col in columns:
        new_col = None
        fuel_units = None
        mult = None

        # ResStock timeseries columns (sightglass format)
        # Examples: electricity_hot_water_kwh, total_site_energy_kwh
        new_col, fuel_units = reformat_fuel_column(col)

        # ResStock timeseries columns (raw double-underscore format)
        # Examples: end_use__electricity__hot_water__kwh
        if new_col is None:
            new_col, fuel_units, mult = reformat_raw_column(col)

        # OCHRE timeseries columns — skip for now
        if new_col is None:
            continue

        ts_cols.append((col, new_col))

        # Build the SQL expression with appropriate unit conversion
        if mult is None and fuel_units == "f":
            # Fahrenheit → Celsius: (F - 32) * 5.0 / 9.0
            columns_sql_list.append(
                f'(("{col}" - 32) * 5.0 / 9.0) AS "{new_col}"'
            )
        elif fuel_units in energy_unit_conv_to_kwh:
            columns_sql_list.append(
                f'{energy_unit_conv_to_kwh[fuel_units]} * "{col}" AS "{new_col}"'
            )
        elif mult is not None and mult != 1.0:
            columns_sql_list.append(
                f'{mult} * "{col}" AS "{new_col}"'
            )
        else:
            columns_sql_list.append(f'"{col}" AS "{new_col}"')

    columns_sql = ", \n".join(columns_sql_list)
    cte_sql += f"""
    renamed_table AS (
    SELECT {columns_sql} FROM bl_table JOIN
    {table_name}_timeseries ON "bldg_id" = "building_id"
    )
    """

    # Final table: renamed table + energy intensity columns + time wrapped to sim year
    final_columns_sql_list = [
        f'"{bldg_id_col}"',
        f'"{upgrade_col}"',
        f'"{sqft_col}"',
        create_query_part_wrap_time_to_sim_year(time_col, sim_year),
    ]
    for pc in partition_cols:
        if pc not in must_have_cols:
            final_columns_sql_list.append(f'"{pc}"')
    final_columns_sql_list += [f'"{col[1]}"' for col in ts_cols]

    # Calculate energy intensity
    for old_col, new_col in ts_cols:
        intensity_col = f"{new_col}_intensity"
        final_columns_sql_list.append(
            f'"{new_col}" / "{sqft_col}" AS "{intensity_col}"'
        )

    # Final statement
    final_columns_sql = ", \n".join(final_columns_sql_list)
    select_sql = f"""
    {cte_sql} SELECT {final_columns_sql} FROM renamed_table
    """
    return select_sql


def create_view_oedi_timeseries(
    bsq: BuildStockQuery,
    view_name: str,
    force: bool = False,
):
    """
    Create a view with OEDI timeseries schema using create_view
    """
    select_sql = create_query_oedi_timeseries(bsq)
    # print("=" * 60)
    # print("GENERATED SQL:")
    # print("=" * 60)
    # print(select_sql)
    # print("=" * 60)
    create_view(bsq, view_name, select_sql, force)


def check_view_result(
    bsq: BuildStockQuery,
    view_name: str,
    limit_rows: int = 10,
):
    """
    Run a simple query against the created view to check results
    """
    # 1. Check that expected columns are present
    df = bsq.execute(f"SELECT * FROM {view_name} LIMIT {limit_rows}")

    has_timestamp = "timestamp" in df.columns
    has_intensity = any("intensity" in c for c in df.columns)
    has_energy_consumption = any("energy_consumption" in c for c in df.columns)
    if not (has_timestamp and has_intensity and has_energy_consumption):
        raise ValueError(
            f"Expected 'timestamp', '*intensity*', and '*energy_consumption*' columns not found in view results. Found columns: {list(df.columns)}"
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

    breakpoint()

# =============================================================================
# boto3 fallback — used when BuildStockQuery cannot initialize (e.g. table
# does not yet exist in Athena/Glue).
# =============================================================================


def get_athena_client(region_name: str = "us-west-2"):
    """Create a boto3 Athena client."""
    return boto3.client("athena", region_name=region_name)


def wait_for_query(client, execution_id: str, max_wait: int = 300) -> dict:
    """Poll until an Athena query completes or fails."""
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


def _infer_parquet_schema_from_s3(s3_location: str, region_name: str = "us-west-2") -> list[dict]:
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
        raise FileNotFoundError(
            f"No Parquet files found at s3://{bucket}/{prefix}"
        )

    # Read schema via boto3 (handles keys with special characters like commas/spaces)
    import io

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

        print(f"Inferring schema from Parquet files at '{s3_location}'...")
        columns = _infer_parquet_schema_from_s3(s3_location, region_name)
        print(f"  Found {len(columns)} columns.")

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
                print(f"Table '{table_name}' already exists.")
                return
            raise RuntimeError(
                f"Glue create_table failed: {e.response['Error']['Message']}"
            ) from e

        print(f"External table '{table_name}' created via Glue pointing to '{s3_location}'.")
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

    print(f"External table '{table_name}' created pointing to '{s3_location}'.")


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

    response = s3.list_objects_v2(
        Bucket=bucket, Prefix=prefix, Delimiter="/"
    )
    subfolders = []
    for cp in response.get("CommonPrefixes", []):
        # cp["Prefix"] is like "prefix/subfolder/"
        folder_name = cp["Prefix"][len(prefix):].rstrip("/")
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
    print(f"\nAvailable tables for database='{database}': {tables}")
    print("-" * 40)
    print()

    if not s3_location:
        # Check if any expected sub-tables exist
        if table in tables or any(t.startswith(f"{table}_") for t in tables):
            print(f"Table(s) for '{table}' already exist.")
            return
        raise SystemExit(
            f"Table '{table}' not found and --s3-location not provided. "
            f"Pass --s3-location to create the external table(s)."
        )

    print(f"Table '{table}' not found. Creating external table(s) using Glue API...")
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
            print(f"Table '{table}' already exists.")
        return

    # Create a table for each subfolder: <table>_<subfolder_name>
    print(f"Found subfolders: {subfolders}")
    for subfolder in subfolders:
        sub_table_name = f"{table}_{subfolder}"
        sub_s3_location = f"{s3_loc}{subfolder}/"
        if sub_table_name in tables:
            print(f"Table '{sub_table_name}' already exists. Skipping.")
            continue
        print(f"Creating external table '{sub_table_name}' -> '{sub_s3_location}'...")
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
            print(f"  Skipping '{sub_table_name}': {e}")
            continue
        print(f"Table '{sub_table_name}' created.")
        print("-" * 40)
        print()


if __name__ == "__main__":
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
    args = parser.parse_args()

    # --- Try BuildStockQuery path first; fall back to boto3 if table missing ---
    try:
        bsq = initialize_buildstock_query(
            database=args.database, table=args.table, workgroup=args.workgroup
        )

    except Exception as e:
        print(f"BuildStockQuery initialization failed: {e}")
        print("Falling back to boto3 workflow to ingest S3 data first into Athena...")

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

    # --- resume with BuildStockQuery path (will succeed now if we had to create the external table) ---
    bsq = initialize_buildstock_query(
        database=args.database, table=args.table, workgroup=args.workgroup
    )
    print()
    print("-" * 60)
    print("Creating view from raw timeseries results...")
    view_name = f"{args.table}_timeseries_view"
    create_view_oedi_timeseries(
        bsq,
        view_name=view_name,
        force=args.force,
    )
    check_view_result(bsq, view_name=view_name)
    print("View creation complete.")
