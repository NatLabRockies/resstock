"""
This script will create Athena views from raw ResStock results following
the OEDI format (with db_schema: resstock_oedi_new).

For OCHRE workflow, use the --reduced-workflow (-r) flag to pass through unmapped columns and skip intensity calculations for timeseries views.

Views created:
  - Timeseries view: <table>_ts_by_state (default, omitted when --baseline-view flag is used)
    - Baseline view:   <table>_md_national_parquet (only with --baseline-view flag)
        - Includes an "upgrade" column: 0 for baseline rows and source upgrade
          values for any processed <table>_upgrade rows.
        - With --baseline-view and --materialize-final, a baseline table named
                <table>_md_national_parquet is created instead and partitioned by upgrade.

===================================================================================

Usage
-----
    # Create timeseries view only:
    python create_athena_views_from_results.py -d my_database -t my_table

    # Create the baseline view only:
    python create_athena_views_from_results.py -d my_database -t my_table -b

    # Materialize the baseline as a table partitioned by upgrade=0:
    python create_athena_views_from_results.py -d my_database -t my_table -b \
        -m s3://bucket/path/to/my_table_md_national_parquet/

    # Export a baseline view or materialized baseline table as one Parquet file:
    python create_athena_views_from_results.py -d my_database -t my_table -b \
        --export-baseline-parquet ./results_up00.parquet

    # Create both timeseries and baseline views:
    run both commands above separately.

    # Force overwrite an existing view:
    python create_athena_views_from_results.py -d my_database -t my_table --force

    # Create view and run validation check:
    # Note: Validation check on timeseries views can be slow.
    python create_athena_views_from_results.py -d my_database -t my_table --check

    # Create external Athena tables from S3 data first:
    python create_athena_views_from_results.py -d my_database -t my_table \\
      --s3-location s3://bucket/path/to/data/ --workgroup my_workgroup

      
    ## Useful for large dataset processing
    # [1] Use reduced workflow (pass-through unmapped columns, skip intensity in timeseries views):
    python create_athena_views_from_results.py -d my_database -t my_table --reduced-workflow

    # [2] Skip the EST/period-beginning timestamp adjustment and keep the source timestamps as-is:
    python create_athena_views_from_results.py -d my_database -t my_table -s

    # [3] Pre-aggregate raw timeseries to hourly, materialize, and build view on top of it:
    # useful for large sample datasets. Without -f, an existing hourly table is reused.
    python create_athena_views_from_results.py -d my_database -t my_table \\
        --materialize-intermediate s3://bucket/path/to/my_table_timeseries_hourly/

        # Note: run above code with a --check-intermediate flag to validate
        # the hourly materialized table before creating the view:
        python create_athena_views_from_results.py -d my_database -t my_table \\
            --materialize-intermediate s3://bucket/path/to/my_table_timeseries_hourly/ --check-intermediate

    # [4] Materialize the final transformed OEDI timeseries output to a previewable Athena table:
    # without -f, an existing final table is reused and no missing partitions are added.
    python create_athena_views_from_results.py -d my_database -t my_table \\
        --materialize-final s3://bucket/path/to/my_table_ts_by_state/

    # Resume an interrupted materialized workflow:
    # use -f with --materialize-intermediate and/or --materialize-final. The flag does
    # not drop existing materialized tables; it compares target partition values to
    # expected source partitions, preserves finished partitions, and appends only
    # unfinished partitions with INSERT INTO. If the Glue table was dropped but the
    # requested S3 output folder still has Parquet files, the script attempts to
    # recreate the table over those files and repair partitions before resuming.
    # If that recovery fails, manually delete the S3 output folder before retrying.
    # For views, -f still means overwrite.
    # Example of resuming an interrupted final table materialization:
    python create_athena_views_from_results.py -d my_database -t my_table -f \
        --materialize-final s3://bucket/path/to/my_table_ts_by_state/

    # Example of resuming an interrupted intermediate materialization:
    python create_athena_views_from_results.py -d my_database -t my_table -f \\
        --materialize-intermediate s3://bucket/path/to/my_table_timeseries_hourly/

        
Note on S3_LOCATION
-------------
  S3_LOCATION refers to the S3 path where the materialized Parquet files will be stored.
  Some workgroups (e.g., rescore) enforce specific S3 locations for query results. In such cases, 
  the input S3_LOCATION is overridden by the workgroup's enforced location's "tables" subdirectory.

Flags
-----
  -d, --database                Athena/Glue database name (required).
  -t, --table                   Source table name (required).
  -w, --workgroup               Athena workgroup (default: primary).
  -l, --s3-location             S3 path to raw data (for creating Athena/external tables).
  --region                     AWS region (default: us-west-2).
  -i, --input-format            Source data format (default: PARQUET).
    -f, --force                   Overwrite existing views. With --materialize-intermediate
                                                                and/or --materialize-final, resume existing materialized
                                                                tables by preserving finished partitions and appending only
                                    missing partitions. If the table metadata is gone but the
                                    requested S3 output contains Parquet files, recreate the table
                                    over those files and repair partitions before resuming. If
                                    recovery fails, manually delete the S3 output folder before
                                    retrying. Without -f, existing materialized tables are reused
                                    as-is and no partition backfill is attempted.
  -c, --check                   Run validation checks on the timeseries view after creation.
  -r, --reduced-workflow        Use reduced column mapping (pass-through unmapped columns, skip intensity calculations).
  -s, --skip-period-adjustment  Skip the EST/period-beginning timestamp adjustment and keep source timestamps as-is.
  -b, --baseline-view           Create only the baseline view from <table>_pub_annual or <table>_baseline.
  --export-baseline-parquet LOCAL_PATH
                                With --baseline-view, export the resulting baseline view or
                                table's upgrade=0 rows as exactly one local Parquet file at
                                LOCAL_PATH. If LOCAL_PATH is a directory, a default filename
                                ("results_up00.parquet") will be appended to it.
  --materialize-intermediate S3_LOCATION
                                Arg for timeseries view creation only.
                                Pre-aggregate the raw timeseries to hourly via Athena CTAS,
                                writing Parquet to S3_LOCATION and registering a Glue table
                                <table>_timeseries_hourly.  The view is then built on top of
                                this materialized table instead of the raw timeseries, so the
                                expensive GROUP BY runs once rather than at every query.
                                Without -f, an existing hourly table is reused as-is. With -f,
                                finished hourly partitions are preserved and only missing
                                hourly partitions are appended; if only S3 files remain, the
                                table is recreated over those files before resuming.
  --check-intermediate          Arg for timeseries view creation only.
                                Run validation checks on the materialized table after creation.
                                Empty validation samples are retried to allow Athena/Glue/S3
                                visibility to settle. If validation still fails, the table is
                                preserved for Athena inspection or -f resume.
                                If the materialized table does not exist, it will be created
                                and validated before creating the view or final table.
  -m, --materialize-final S3_LOCATION
                                Arg for timeseries view creation only.
                                Materialize the final transformed OEDI timeseries query into a partitioned
                                Athena table named <table>_ts_by_state for previewability. If omitted,
                                the workgroup default output location is used. Without -f, an
                                existing final table is reused as-is. With -f, finished final
                                partitions are preserved and only missing final partitions are
                                appended; if only S3 files remain, the table is recreated over
                                those files before resuming. With --baseline-view, materialize
                                a <table>_md_national_parquet baseline table partitioned by upgrade instead.
    -u, --upgrade-filter <FILTER> Filter upgrades for timeseries and baseline view creation.
                                Apply an upgrade filter to the materialized table, if needed.
                                Default to all, meaning no filter is applied.
                                To preserve only the baseline (upgrade=0), use --upgrade-filter 0.

===================================================================================

Data Processing
-----------------
If the input table does not yet exist in Athena database, rerun the script by adding an S3
path to create an external table pointing to the raw data on S3 using boto3. The
script will create the view on top of that.

[1] The timeseries view definition will perform the following transformations:

Optional steps for handling large datasets:
- Apply an upgrade filter to the materialized table (e.g., --upgrade-filter 0 
  for baseline only), if needed, to reduce the amount of data processed.

- Pre-aggregate the raw timeseries to hourly via Athena CTAS, writing Parquet 
    to S3 and registering a Glue table. If the hourly table exists and -f is not
    supplied, the table is reused as-is.

- Materialize the final transformed OEDI timeseries result to a previewable Athena
    table via --materialize-final when a final materialized output is desired. If
    the final table exists and -f is not supplied, the table is reused as-is.

- Resume interrupted hourly or final materialization with -f. The script checks
    expected source partitions against partitions already present in the target
    materialized table and appends only unfinished partitions with INSERT INTO.
    If the target table was dropped but the requested S3 output folder still has
    Parquet files, the script attempts to recreate the table from those files,
    repair partitions, and then resume. If that recovery fails, manually delete
    the S3 output folder before retrying.

- Run validation checks on the materialized table after creation or if table exists 
    to ensure data integrity. Empty intermediate validation samples are retried.
    If validation still fails, intermediate hourly tables are preserved so the
    user can inspect them in Athena or rerun the script with -f to resume.


Main steps for timeseries view creation:

- Select relevant columns from the baseline and timeseries tables, including
  building_id, county (if needed for time conversion), conditioned sqft, and all
  timeseries columns matching the expected ResStock naming convention for energy
  consumption.

- Adjust the time column to be in Eastern Standard Time (EST) and follow a
  period-beginning convention, unless --skip-period-adjustment is set to keep the
  source timestamps unchanged. This involves:
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

[2] The baseline view/table is built from the processed baseline annual rows
(upgrade=0) and, when present, the processed <table>_upgrade or
<table>_upgrades rows. The materialized baseline table is partitioned by
upgrade.

===================================================================================
OCHRE-defrost project cmd for reference:
# create materialized timeseries table for baseline comparison dashboard workflow
uv run resstockpostproc/create_athena_views_from_results.py -w resstock-panels -d resstock_panels \
    -t sdr2025_r1_full_nodefco_15min_aug8 --reduced-workflow -f --check \
        --materialize-intermediate s3://resstock-panels/ochre_runs/sdr2025_r1_full_nodefco_15min_aug8/timeseries_hourly/ --check-intermediate \
            -m s3://resstock-panels/ochre_runs/sdr2025_r1_full_nodefco_15min_aug8/timeseries_oedi/

# create baseline table for baseline comparison dashboard workflow + export baseline parquet to local
uv run resstockpostproc/create_athena_views_from_results.py -w resstock-panels -d resstock_panels \
    -t sdr2025_r1_full_nodefco_15min_aug8 --reduced-workflow -f --check -b \
    --export-baseline-parquet '/Users/lliu2/baseline_dashboards/ochre_baseline_validation_outputs/data/ResStock Data/ochre_sdr2025_r1_nodefco/'

===================================================================================
ResStock Heating Calibration project cmd for reference:
# [1] create baseline view, baseline pub annual parquet file for baseline comparison dashboard workflow
uv run resstockpostproc/create_athena_views_from_results.py \
  -w rescore \
  -d resstock_core \
  -t post_sdr_baseline_sheltered_flue_090426 \
  --reduced-workflow \
  -f \
  --check \
  -b --export-baseline-parquet '/Users/lliu2/baseline_dashboards/heating_calibration/data/ResStock Data/ob_resstock_sheltered_flue/'

# [2] create materialized timeseries table for baseline comparison dashboard workflow
uv run resstockpostproc/create_athena_views_from_results.py \
  -w rescore \
  -d resstock_core \
  -t post_sdr_baseline_sheltered_flue_090426 \
  --reduced-workflow \
  -f \
  --check \
  -m s3://resstock-core/heating_calibration/post_sdr_baseline_sheltered_flue_090426/timeseries_oedi/ # gets overriden by workground query location

===================================================================================

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
import pyarrow as pa
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

    Uses the Glue API to avoid Athena query restrictions and metadata issues
    (e.g. invalid column types in existing tables breaking information_schema).

    Parameters
    ----------
    bsq : BuildStockQuery
        An initialized BuildStockQuery instance.

    Returns
    -------
    list[str]
        View names in the database.
    """
    glue = boto3.client("glue", region_name=bsq.run_params.region_name)
    views = []
    paginator = glue.get_paginator("get_tables")
    for page in paginator.paginate(DatabaseName=bsq.db_name):
        for table in page["TableList"]:
            if table.get("TableType") == "VIRTUAL_VIEW":
                views.append(table["Name"])
    return views


def create_view(
    bsq: BuildStockQuery,
    view_name: str,
    select_sql: str,
    force: bool = False,
    columns: list[dict] | None = None,
) -> None:
    """
    Create (or replace) a view in Athena from a SELECT statement.

    Uses the Glue API directly to register the view as a VIRTUAL_VIEW table,
    which avoids Athena DDL restrictions that some workgroups enforce.
    Column names and types are inferred by executing the SELECT with LIMIT 0.

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

    Raises
    ------
    RuntimeError
        If the view already exists (and force=False), or if creation fails.
    """
    import base64
    import json as _json

    # Check if view already exists
    existing_views = list_views(bsq)

    if view_name in existing_views and not force:
        raise RuntimeError(
            f"View '{view_name}' already exists in database '{bsq.db_name}'. "
            f"Rerun with force=True to overwrite."
        )

    # Athena stores views in Glue as VIRTUAL_VIEW tables. The SQL is encoded in
    # ViewOriginalText as: /* Presto View: <base64(json)> */
    # Athena requires the "columns" list in the JSON to be populated for the
    # view to appear in the console.  We run the SELECT via execute_raw (no
    # UNLOAD wrapping) and read column metadata from get_query_results.
    if columns is not None:
        # Caller supplied pre-computed column metadata (e.g. from
        # create_query_oedi_timeseries).  Skip the schema-inference query
        # entirely — it would run a full aggregation over the dataset which
        # can time out on large tables.
        view_columns: list[dict] = columns
        logger.info(
            "Using pre-computed columns for view '%s': %d columns",
            view_name, len(view_columns),
        )
    else:
        schema_sql = select_sql if select_sql.lstrip().upper().startswith("WITH") else (
            f"SELECT * FROM ({select_sql})"
        )
        schema_sql = schema_sql + " LIMIT 1"
        exe_id = str(bsq.execute_raw(schema_sql, run_async=True))
        while True:
            stat = bsq._aws_athena.get_query_execution(QueryExecutionId=exe_id)
            state = stat["QueryExecution"]["Status"]["State"]
            if state in ("SUCCEEDED", "FAILED", "CANCELLED"):
                break
            time.sleep(1)
        if state != "SUCCEEDED":
            reason = stat["QueryExecution"]["Status"].get("StateChangeReason", "")
            msg = (
                f"Schema inference query for view '{view_name}' {state}: {reason}. "
                "Pass `columns` to skip schema inference for complex queries."
            )
            raise RuntimeError(msg)
        col_info = bsq._aws_athena.get_query_results(
            QueryExecutionId=exe_id, MaxResults=1
        )["ResultSet"]["ResultSetMetadata"]["ColumnInfo"]
        view_columns = [{"name": c["Name"], "type": c["Type"].lower()} for c in col_info]
        logger.info("Schema inference succeeded: %d columns inferred for view '%s'", len(view_columns), view_name)
        logger.debug("View columns: %s", view_columns)

    view_json = _json.dumps({
        "originalSql": select_sql,
        "catalog": "awsdatacatalog",
        "schema": bsq.db_name,
        "columns": view_columns,
        # runAsInvoker and path are required by Trino's ConnectorViewDefinition
        # JSON codec (Athena engine v3).  Omitting them causes
        # GENERIC_INTERNAL_ERROR: Invalid JSON bytes.
        "runAsInvoker": False,
        "path": [],
    })
    view_text = "/* Presto View: " + base64.b64encode(view_json.encode()).decode() + " */"

    table_input = {
        "Name": view_name,
        "TableType": "VIRTUAL_VIEW",
        "ViewOriginalText": view_text,
        "ViewExpandedText": "/* Presto View */",
        # "presto_view": "true" is required for Athena engine v3 (Trino) to
        # recognise this as an Athena-managed view instead of a Hive view.
        # Without it, Athena falls back to Hive view translation, which fails
        # and causes the view to be invisible in the Athena console.
        "Parameters": {"presto_view": "true"},
        "StorageDescriptor": {
            "Columns": [],
            "Location": "",
            "InputFormat": "",
            "OutputFormat": "",
            "SerdeInfo": {"SerializationLibrary": "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"},
        },
        "PartitionKeys": [],
    }

    glue = boto3.client("glue", region_name=bsq.run_params.region_name)
    try:
        if view_name in existing_views:
            glue.update_table(DatabaseName=bsq.db_name, TableInput=table_input)
        else:
            glue.create_table(DatabaseName=bsq.db_name, TableInput=table_input)
    except ClientError as e:
        if e.response["Error"]["Code"] == "AlreadyExistsException":
            # The view exists in Glue but wasn't found via information_schema
            # (e.g. created via Glue API directly). Update it instead.
            if not force:
                msg = (
                    f"View '{view_name}' already exists in database '{bsq.db_name}'. "
                    f"Rerun with force=True to overwrite."
                )
                raise RuntimeError(msg) from e
            glue.update_table(DatabaseName=bsq.db_name, TableInput=table_input)
        else:
            msg = f"View creation via Glue failed: {e.response['Error']['Message']}"
            raise RuntimeError(msg) from e

    logger.info(f" ** View '{view_name}' created successfully in database '{bsq.db_name}'. ** ")



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
    skip_period_adjustment: bool = False,
) -> tuple[str, int]:
    """Build a SQL expression for the output timestamp column.

    By default, this converts timestamps to EST period-beginning alignment.
    If ``skip_period_adjustment`` is True, it leaves the source timestamps
    unchanged and simply returns the raw ``time`` or ``timeutc`` column.

    Queries the baseline table to determine the timestamp convention (begin/end)
    and the simulation year. Returns a DATE_ADD expression that shifts the raw
    time column to UTC-5 (EST) with period-beginning alignment when enabled.

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
        unchanged (useful for simple workflow).
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


def _get_column_mapping_config(simple_workflow: bool) -> tuple[bool, bool]:
    """Determine column-mapping behaviour based on workflow type.

    Parameters
    ----------
    simple_workflow : bool
        True for simple workflow, False for standard ResStock.

    Returns
    -------
    tuple[bool, bool]
        (compute_intensity_cols, keep_unmapped_cols)
        - compute_intensity_cols: whether to generate energy/sqft intensity columns.
        - keep_unmapped_cols: whether unmapped timeseries columns are passed through.
    """
    if simple_workflow:
        # simple workflow does not currently include conditioned sqft, 
        # so skip intensity columns for now if simple_workflow is True
        compute_intensity_cols = False
        keep_unmapped_cols = True  # keep all columns for maximum flexibility in simple workflow
        logger.info("Column mapping config: simple workflow - pass through all unmapped columns, skip intensity calculations")
    else:
        # ResStock standard workflow
        compute_intensity_cols = True
        keep_unmapped_cols = False  # only include mapped columns for cleaner OEDI output
        logger.info("Column mapping config: ResStock standard workflow - compute intensity columns, drop unmapped columns")
    return compute_intensity_cols, keep_unmapped_cols


def create_query_oedi_timeseries(
    bsq: BuildStockQuery,
    simple_workflow: bool = False,
    hourly_table: Optional[str] = None,
    skip_period_adjustment: bool = False,
) -> tuple[str, list[dict]]:
    """
    Create the SQL body for a view that transforms raw timeseries results into OEDI format.

    Parameters
    ----------
    bsq : BuildStockQuery
        An initialized BuildStockQuery instance.
    simple_workflow : bool
        If True, generate OEDI timeseries columns for simple workflow.
    hourly_table : str or None
        If provided, the view's ``ts_table`` CTE is a plain passthrough
        ``SELECT * FROM <hourly_table>`` rather than a GROUP BY aggregation
        over the raw timeseries.  Use this when the hourly aggregation has
        already been materialised via ``create_materialized_hourly_timeseries_table``.

    Returns
    -------
    tuple[str, list[dict]]
        (select_sql, output_columns) — the SQL SELECT statement body for the
        view definition, and the list of output column dicts
        ``[{"name": ..., "type": ...}, ...]`` derived from the SQL structure.
        Passing these directly to ``create_view`` avoids a slow schema-inference
        query on the full aggregated dataset.
    """
    
    compute_intensity_cols, keep_unmapped_cols = _get_column_mapping_config(simple_workflow)

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

    # CTE 1: ts_table — either a passthrough from a pre-materialised table or an
    # inline aggregation to hourly resolution from the raw timeseries.
    ts_group_cols = ["building_id", "upgrade"] + [
        c for c in partition_cols if c not in {"building_id", "upgrade", "time", "timeutc"}
    ]
    ts_group_exprs = [f'"{c}"' for c in ts_group_cols]
    ts_select_exprs = [f'"{c}"' for c in ts_group_cols]

    # Skip all time-prefixed columns: they are timestamps and avg() rejects them.
    # "time" and "timeutc" are already in ts_group_cols / the explicit set;
    # "timedst" (and any future timestamp column whose name starts with "time")
    # must also be excluded to avoid FUNCTION_NOT_FOUND errors in Athena.
    ts_agg_skip_cols = set(ts_group_cols) | {c for c in columns if c.lower().startswith("time")}

    if hourly_table is not None:
        # The hourly materializer retains only mapped metrics. Mirror that
        # reduced schema here so the view does not request dropped columns.
        _, mapped_columns = _build_renamed_columns(columns, skip_cols=ts_agg_skip_cols)
        mapped_column_names = {col for col, _ in mapped_columns}
        columns = [
            col for col in columns
            if col in ts_agg_skip_cols or col in mapped_column_names
        ]
        # Pre-materialised hourly table: simple passthrough, no aggregation.
        # The GROUP BY was already paid for by create_materialized_hourly_timeseries_table;
        # the view is a lightweight rename/join with no full-table scan at query time.
        need_resample = False
        ts_select_exprs.append('"time"')
        for col in columns:
            if col in ts_agg_skip_cols:
                continue
            ts_select_exprs.append(f'"{col}"')
        cte_sql_expr = f"""
    WITH ts_table AS (
        SELECT {", ".join(ts_select_exprs)}
        FROM {hourly_table}
    ),
    """
        logger.info("Using pre-materialised hourly table '%s' as ts_table source.", hourly_table)
    else:
        # No pre-materialised table: probe the raw timeseries to decide whether
        # a GROUP BY resampling is needed.  This lightweight LIMIT 2 query runs
        # once at view-creation time and is not part of the view definition.
        df_ts_probe = bsq.execute(
            f'SELECT DISTINCT "time" FROM {table_name}_timeseries ORDER BY 1 LIMIT 2'
        )
        timestep_minutes = int(
            (df_ts_probe["time"].iloc[1] - df_ts_probe["time"].iloc[0]).total_seconds() / 60
        )
        need_resample = timestep_minutes != 60
        logger.info(
            "Timeseries timestep: %d min — %s",
            timestep_minutes,
            "will resample to hourly via GROUP BY" if need_resample else "data is already hourly, skipping GROUP BY aggregation",
        )

        if need_resample:
            # omit timeutc even if it exists since DATE_TRUNC may not align between two time cols
            ts_select_exprs.append('DATE_TRUNC(\'hour\', "time") AS "time"')
            ts_group_exprs.append('DATE_TRUNC(\'hour\', "time")')
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
        else:
            # Data is already hourly: plain passthrough, no aggregation.
            # Athena can push LIMIT through a simple SELECT, so previews are fast.
            ts_select_exprs.append('"time"')
            for col in columns:
                if col in ts_agg_skip_cols:
                    continue
                ts_select_exprs.append(f'"{col}"')
            cte_sql_expr = f"""
    WITH ts_table AS (
        SELECT {", ".join(ts_select_exprs)}
        FROM {table_name}_timeseries
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
    # Choose the time_table argument for _build_est_time_sql_expr:
    # - Materialised table: query it directly (already hourly).
    # - Sub-hourly raw data: wrap with DATE_TRUNC so the function sees 60-min steps.
    # - Already-hourly raw data: pass None to use the default raw timeseries.
    if hourly_table is not None:
        resampled_time_table = hourly_table
    elif need_resample:
        resampled_time_table = (
            f"(SELECT DATE_TRUNC('hour', \"time\") AS \"time\" FROM {table_name}_timeseries)"
        )
    else:
        resampled_time_table = None
    time_sql_expr, sim_year = _build_est_time_sql_expr(
        bsq,
        time_col,
        has_timeutc,
        time_table=resampled_time_table,
        skip_period_adjustment=skip_period_adjustment,
    )
    # skip_cols must be a superset of ts_agg_skip_cols: any column excluded from
    # the ts_table CTE (e.g. time-prefixed timestamp columns like "timedst") must
    # also be excluded from the renamed_table SELECT.  Without this, simple
    # workflow's keep_unmapped_cols=True would pass them through and cause a
    # COLUMN_NOT_FOUND error because ts_table doesn't carry those columns.
    skip_cols = ts_agg_skip_cols
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

    # Derive output column metadata from the SQL structure we just built.
    # All aggregated timeseries values come out of AVG/SUM → double.
    # Partition-derived and id columns use their natural Glue/Athena types.
    # Passing this to create_view avoids a slow full-dataset schema-inference
    # query that aggregates the entire timeseries table.
    output_columns: list[dict] = []
    output_columns.append({"name": bldg_id_col, "type": "bigint"})
    output_columns.append({"name": upgrade_col, "type": "varchar"})
    if compute_intensity_cols:
        output_columns.append({"name": sqft_col, "type": "double"})
    output_columns.append({"name": time_col, "type": "timestamp"})
    for pc in partition_cols:
        if pc not in must_have_cols:
            output_columns.append({"name": pc, "type": "varchar"})
    for _, new_col in ts_cols:
        output_columns.append({"name": new_col, "type": "double"})
    if compute_intensity_cols:
        for _, new_col in ts_cols:
            output_columns.append({"name": f"{new_col}_intensity", "type": "double"})

    return select_sql_expr, output_columns


def _resolve_materialization_location(
    bsq: BuildStockQuery,
    requested_location: Optional[str],
    table_name: str,
    materialization_kind: str,
) -> Optional[str]:
    """Normalize a requested materialization location.

    A caller-supplied materialization location is used as the CTAS
    ``external_location`` unless the Athena workgroup enforces its centralized
    output configuration. For an enforcing workgroup, return ``None`` so Athena
    selects the destination; the actual Glue table location is logged after CTAS.
    """
    normalized = (
        (requested_location if requested_location.endswith("/") else requested_location + "/")
        if requested_location
        else None
    )
    if normalized is None:
        return None

    try:
        workgroup_info = bsq._aws_athena.get_work_group(WorkGroup=bsq.workgroup)
        configuration = workgroup_info["WorkGroup"]["Configuration"]
        default_location = configuration["ResultConfiguration"].get("OutputLocation")
        if (
            configuration.get("EnforceWorkGroupConfiguration", False)
            and default_location
            and default_location.rstrip("/") != normalized.rstrip("/")
        ):
            logger.warning(
                "Workgroup '%s' enforces centralized output at '%s'; overriding "
                "requested %s materialization location '%s'. Athena will choose the "
                "materialized table location, which will be reported from Glue after CTAS.",
                bsq.workgroup,
                default_location,
                materialization_kind,
                normalized,
            )
            return None
    except (KeyError, ClientError) as exc:
        logger.warning(
            "Could not determine workgroup output location for %s materialization '%s'; using the requested location when possible: %s",
            materialization_kind,
            table_name,
            exc,
        )

    return normalized


def _log_materialized_table_location(
    bsq: BuildStockQuery,
    table_name: str,
    materialization_kind: str,
) -> None:
    """Log the S3 location registered for a materialized Glue table."""
    try:
        glue = boto3.client("glue", region_name=bsq.run_params.region_name)
        table_info = glue.get_table(DatabaseName=bsq.db_name, Name=table_name)
        location = table_info["Table"]["StorageDescriptor"]["Location"]
    except (ClientError, KeyError) as exc:
        logger.warning(
            "Could not determine S3 location for materialized %s table '%s': %s",
            materialization_kind,
            table_name,
            exc,
        )
        return
    logger.info(
        "Materialized %s table location: '%s'",
        materialization_kind,
        location,
    )


def _run_athena_query_and_wait(
    bsq: BuildStockQuery,
    query_string: str,
    label: str,
    poll_seconds: int = 5,
) -> None:
    exe_id = bsq._aws_athena.start_query_execution(
        QueryString=query_string,
        QueryExecutionContext={"Database": bsq.db_name},
        WorkGroup=bsq.workgroup,
    )["QueryExecutionId"]
    while True:
        stat = bsq._aws_athena.get_query_execution(QueryExecutionId=exe_id)
        state = stat["QueryExecution"]["Status"]["State"]
        if state in ("SUCCEEDED", "FAILED", "CANCELLED"):
            break
        time.sleep(poll_seconds)
    if state != "SUCCEEDED":
        reason = stat["QueryExecution"]["Status"].get("StateChangeReason", "")
        msg = f"{label} {state}: {reason}"
        raise RuntimeError(msg)


def _register_materialized_table_from_s3(
    bsq: BuildStockQuery,
    table_name: str,
    s3_location: Optional[str],
    partition_columns: list[str],
    output_columns: Optional[list[dict]] = None,
) -> bool:
    """Register a dropped materialized table over reusable CTAS output files."""
    if s3_location is None:
        return False

    try:
        inferred_columns = _infer_parquet_schema_from_s3(
            s3_location,
            region_name=bsq.run_params.region_name,
        )
    except FileNotFoundError:
        return False

    try:
        source_columns = output_columns if output_columns is not None else inferred_columns
        partition_names = set(partition_columns)
        table_columns = []
        for column in source_columns:
            name = column.get("name", column.get("Name"))
            col_type = column.get("type", column.get("Type"))
            if name in partition_names:
                continue
            table_columns.append({"Name": name, "Type": col_type})

        glue = boto3.client("glue", region_name=bsq.run_params.region_name)
        table_input = {
            "Name": table_name,
            "TableType": "EXTERNAL_TABLE",
            "Parameters": {"classification": "parquet", "EXTERNAL": "TRUE"},
            "StorageDescriptor": {
                "Columns": table_columns,
                "Location": s3_location,
                "InputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat",
                "OutputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat",
                "SerdeInfo": {
                    "SerializationLibrary": "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
                },
            },
            "PartitionKeys": [
                {"Name": column, "Type": "string"} for column in partition_columns
            ],
        }
        logger.info(
            "Recreating materialized table '%s' from existing S3 output at '%s'.",
            table_name,
            s3_location,
        )
        try:
            glue.create_table(DatabaseName=bsq.db_name, TableInput=table_input)
        except ClientError as exc:
            if exc.response["Error"]["Code"] != "AlreadyExistsException":
                raise
        _run_athena_query_and_wait(
            bsq,
            f"MSCK REPAIR TABLE {bsq.db_name}.{table_name}",
            "MSCK REPAIR TABLE for existing materialized output",
        )
    except Exception as exc:
        msg = (
            f"Existing materialized output files were found at '{s3_location}', "
            f"but table '{table_name}' could not be recreated from them: {exc}. "
            "Manually delete the S3 output folder before retrying if these files "
            "are incomplete or cannot be reused."
        )
        raise RuntimeError(msg) from exc

    logger.info(
        "Materialized table '%s' was recreated from existing S3 files; resuming missing partitions.",
        table_name,
    )
    return True


def create_materialized_hourly_timeseries_table(
    bsq: BuildStockQuery,
    s3_output_location: Optional[str] = None,
    upgrade_filter: Optional[str] = None,
    force: bool = False,
) -> str:
    """Pre-aggregate the raw timeseries to hourly resolution via Athena CTAS.

    Runs a one-time ``CREATE TABLE AS SELECT`` that writes the hourly-aggregated
    timeseries to ``s3_output_location`` as Parquet and registers a Glue table
    named ``<table>_timeseries_hourly``.  Downstream views built on top of this
    table avoid the expensive ``GROUP BY`` aggregation at query time, making
    them trivially previewable even on very large datasets.

    By default, all upgrades are materialized. Set ``upgrade_filter`` to a value
    such as ``"0"`` to materialize only that upgrade. Energy columns (``*_kwh``, ``*_kbtu``)
    are summed; all other mapped numeric columns are averaged.

    Parameters
    ----------
    bsq : BuildStockQuery
        An initialized BuildStockQuery instance.
    s3_output_location : str
        S3 path where materialized Parquet files will be written.
        e.g. ``"s3://bucket/path/<table>_timeseries_hourly/"``
    Returns
    -------
    str
        Name of the newly created (or pre-existing) Glue table.

    When ``force`` is True and the target table already exists, the workflow
    resumes by inserting only unfinished partitions.

    Raises
    ------
    RuntimeError
        If the Athena CTAS query fails or is cancelled.
    """
    table_name = bsq.table_name
    hourly_table = f"{table_name}_timeseries_hourly"

    table_exists = hourly_table in list_tables_boto3(
        bsq.db_name, bsq.workgroup, region_name=bsq.run_params.region_name
    )
    if table_exists and not force:
        logger.info(
            "Materialized table '%s' already exists — skipping CTAS. Use -f to resume missing partitions.",
            hourly_table,
        )
        return hourly_table

    columns = [c.name for c in bsq.ts_table.columns]
    has_upgrade = "upgrade" in columns
    partition_cols = _get_partition_columns(bsq)
    materialized_partition_cols = [
        col for col in partition_cols if col not in {"building_id", "time", "timeutc"}
    ]
    if "upgrade" not in materialized_partition_cols:
        materialized_partition_cols.append("upgrade")
    split_partition_cols = [
        col
        for col in materialized_partition_cols
        if has_upgrade and upgrade_filter is None or col != "upgrade"
    ]
    ts_group_cols = ["building_id"] + (["upgrade"] if has_upgrade else []) + [
        c for c in partition_cols if c not in {"building_id", "upgrade", "time", "timeutc"}
    ]
    ts_agg_skip = set(ts_group_cols) | {c for c in columns if c.lower().startswith("time")}
    _, mapped_columns = _build_renamed_columns(columns, skip_cols=ts_agg_skip)
    mapped_column_names = {col for col, _ in mapped_columns}

    # Athena CTAS requires partition keys to be the last columns in the SELECT
    # list (HIVE_COLUMN_ORDER_MISMATCH otherwise).
    select_exprs = ['"building_id"']
    time_df = bsq.execute(
        f'SELECT DISTINCT "time" FROM {table_name}_timeseries ORDER BY 1 LIMIT 2'
    )
    timestep_minutes = int(
        (time_df["time"].iloc[1] - time_df["time"].iloc[0]).total_seconds() / 60
    )
    needs_resample = timestep_minutes != 60
    if needs_resample:
        select_exprs.append('DATE_TRUNC(\'hour\', "time") AS "time"')
        group_exprs = [f'"{c}"' for c in ts_group_cols] + [
            'DATE_TRUNC(\'hour\', "time")'
        ]
    else:
        select_exprs.append('"time"')
        group_exprs = []
    logger.info(
        "Timeseries timestep: %d min - %s for hourly materialization.",
        timestep_minutes,
        "resampling" if needs_resample else "using projection-only CTAS",
    )

    for col in columns:
        if col not in mapped_column_names:
            continue
        if not needs_resample:
            select_exprs.append(f'"{col}"')
            continue
        _, raw_unit, _ = _reformat_raw_column(col)
        if raw_unit in {"kwh", "kbtu", "therm", "mbtu"}:
            select_exprs.append(f'SUM("{col}") AS "{col}"')
        else:
            select_exprs.append(f'AVG("{col}") AS "{col}"')

    # Partition keys last — required by Hive/Athena. Older datasets do not have
    # an upgrade column, so give their single baseline partition an integer 0.
    for partition_col in materialized_partition_cols:
        if partition_col == "upgrade" and not has_upgrade:
            select_exprs.append('CAST(0 AS INTEGER) AS "upgrade"')
        else:
            select_exprs.append(f'"{partition_col}"')

    s3_loc = _resolve_materialization_location(
        bsq,
        s3_output_location,
        hourly_table,
        "hourly",
    )
    if s3_loc is None and s3_output_location is None:
        try:
            workgroup_info = bsq._aws_athena.get_work_group(
                WorkGroup=bsq.workgroup
            )
            default_location = workgroup_info["WorkGroup"]["Configuration"][
                "ResultConfiguration"
            ].get("OutputLocation")
            if default_location:
                s3_loc = (
                    default_location.rstrip("/")
                    + "/tables/"
                    + hourly_table
                    + "/"
                )
                logger.info(
                    "Using workgroup default output location for materialized table: '%s'.",
                    s3_loc,
                )
        except (KeyError, ClientError) as exc:
            logger.warning(
                "Could not determine workgroup default output location; "
                "using Athena workgroup-managed output: %s",
                exc,
            )

    def _sql_literal(value: object) -> str:
        """Return an Athena SQL string literal."""
        return "'" + str(value).replace("'", "''") + "'"

    def _select_for_partition(partition_values: tuple[object, ...]) -> str:
        """Return the SELECT fragment for upgrade 0 and one source partition."""
        sql = (
            f'SELECT {", ".join(select_exprs)}\n'
            f'    FROM {table_name}_timeseries\n'
        )
        filters = []
        if has_upgrade and upgrade_filter is not None and "upgrade" not in split_partition_cols:
            filters.append(f'"upgrade" = {_sql_literal(upgrade_filter)}')
        filters.extend(
            f'"{col}" = {_sql_literal(value)}'
            for col, value in zip(split_partition_cols, partition_values)
        )
        if filters:
            sql += f"    WHERE {' AND '.join(filters)}\n"
        if group_exprs:
            sql += f'    GROUP BY {", ".join(group_exprs)}'
        return sql

    if split_partition_cols:
        partition_select = ", ".join(f'"{col}"' for col in split_partition_cols)
        upgrade_predicate = (
            f' WHERE "upgrade" = {_sql_literal(upgrade_filter)}'
            if has_upgrade and upgrade_filter is not None and "upgrade" not in split_partition_cols
            else ""
        )
        partitions_df = bsq.execute(
            f"SELECT DISTINCT {partition_select} FROM {table_name}_timeseries{upgrade_predicate}"
        )
        partition_values = list(partitions_df.itertuples(index=False, name=None))
        logger.info(
            "Materializing %d source partition(s): %s",
            len(partition_values),
            split_partition_cols,
        )
    else:
        partition_values = [()]

    if not table_exists and force:
        table_exists = _register_materialized_table_from_s3(
            bsq,
            hourly_table,
            s3_loc,
            materialized_partition_cols,
        )

    if table_exists:
        if split_partition_cols:
            existing_partition_values = list(
                bsq.execute(
                    f"SELECT DISTINCT {partition_select} FROM {hourly_table}"
                ).itertuples(index=False, name=None)
            )
            existing_partition_keys = {
                tuple(str(value) for value in values)
                for values in existing_partition_values
            }
            missing_partition_values = [
                values
                for values in partition_values
                if tuple(str(value) for value in values) not in existing_partition_keys
            ]
            logger.info(
                "Resuming materialized hourly table '%s': %d finished partition(s), %d unfinished partition(s).",
                hourly_table,
                len(existing_partition_values),
                len(missing_partition_values),
            )
        else:
            missing_partition_values = [()]
            logger.info(
                "Resuming unpartitioned materialized hourly table '%s' with INSERT INTO.",
                hourly_table,
            )

        if not missing_partition_values:
            logger.info("Materialized hourly table '%s' already has all expected partitions.", hourly_table)
            return hourly_table
    else:
        missing_partition_values = partition_values

    def _run_query(query_string: str, label: str) -> None:
        """Submit an Athena query, wait for completion, raise on failure."""
        exe_id = bsq._aws_athena.start_query_execution(
            QueryString=query_string,
            QueryExecutionContext={"Database": bsq.db_name},
            WorkGroup=bsq.workgroup,
        )["QueryExecutionId"]
        while True:
            stat  = bsq._aws_athena.get_query_execution(QueryExecutionId=exe_id)
            state = stat["QueryExecution"]["Status"]["State"]
            if state in ("SUCCEEDED", "FAILED", "CANCELLED"):
                break
            time.sleep(5)
        if state != "SUCCEEDED":
            reason = stat["QueryExecution"]["Status"].get("StateChangeReason", "")
            msg = f"{label} {state}: {reason}"
            raise RuntimeError(msg)

    partitioned_by = ", ".join(f"'{col}'" for col in materialized_partition_cols)
    with_loc = (
        f"format = 'PARQUET',\n        external_location = '{s3_loc}',\n        partitioned_by = ARRAY[{partitioned_by}]"
        if s3_loc
        else f"format = 'PARQUET',\n        partitioned_by = ARRAY[{partitioned_by}]"
    )
    if not table_exists:
        ctas_sql = (
            f"CREATE TABLE {bsq.db_name}.{hourly_table}\n"
            f"    WITH (\n        {with_loc}\n    )\n"
            f"    AS\n    {_select_for_partition(missing_partition_values[0])}"
        )
        logger.info(
            "CTAS [1/%d] upgrade=%s%s",
            len(missing_partition_values),
            upgrade_filter if upgrade_filter is not None else "all",
            f" at '{s3_loc}'" if s3_loc else " (workgroup default output location)",
        )
        try:
            _run_query(ctas_sql, "CTAS materialization")
        except ClientError as e:
            if (
                e.response["Error"]["Code"] == "InvalidRequestException"
                and "external_location" in e.response["Error"]["Message"]
                and s3_loc is not None
            ):
                msg = (
                    f"Athena rejected requested hourly materialization location '{s3_loc}': "
                    f"{e.response['Error']['Message']}. The requested destination takes precedence; "
                    "delete or fix that S3 output folder before retrying."
                )
                raise RuntimeError(msg) from e
            else:
                raise

    insert_values = missing_partition_values if table_exists else missing_partition_values[1:]
    for index, values in enumerate(insert_values, start=1 if table_exists else 2):
        insert_sql = (
            f"INSERT INTO {bsq.db_name}.{hourly_table}\n"
            f"    {_select_for_partition(values)}"
        )
        logger.info("INSERT [%d/%d] upgrade=%s", index, len(missing_partition_values), upgrade_filter or "all")
        _run_query(insert_sql, "INSERT materialization")

    # Resolve and log the actual S3 location from Glue.
    glue = boto3.client("glue", region_name=bsq.run_params.region_name)
    table_info = glue.get_table(DatabaseName=bsq.db_name, Name=hourly_table)
    actual_location = table_info["Table"]["StorageDescriptor"]["Location"]
    if s3_output_location is not None and s3_loc is None:
        logger.warning(
            "Requested hourly materialization location '%s' was overridden by "
            "workgroup '%s'. Athena created '%s'.",
            s3_output_location,
            bsq.workgroup,
            actual_location,
        )
    elif s3_loc and actual_location.rstrip("/") != s3_loc.rstrip("/"):
        logger.warning(
            "Materialized table '%s' location is '%s', which differs from the requested location '%s'.",
            hourly_table, actual_location, s3_loc,
        )
    else:
        logger.info(
            "Materialized table '%s' created successfully at '%s'.",
            hourly_table, actual_location,
        )
    return hourly_table


def create_materialized_final_timeseries_table(
    bsq: BuildStockQuery,
    s3_output_location: Optional[str] = None,
    upgrade_filter: Optional[str] = None,
    hourly_table: Optional[str] = None,
    simple_workflow: bool = False,
    skip_period_adjustment: bool = False,
    force: bool = False,
) -> str:
    """Materialize the final transformed timeseries SQL as a partitioned table.

    This creates a preview-friendly Athena table named
    ``<table>_ts_by_state`` from the final OEDI transform. It works whether
    the input is the raw timeseries table or a previously materialized hourly
    table, and it can be restricted to a single upgrade value using
    ``upgrade_filter``. When ``force`` is True and the target table already
    exists, the workflow resumes by inserting only unfinished partitions.
    """
    table_name = bsq.table_name
    final_table = f"{table_name}_ts_by_state"

    table_exists = final_table in list_tables_boto3(
        bsq.db_name, bsq.workgroup, region_name=bsq.run_params.region_name
    )
    if table_exists and not force:
        logger.info(
            "Materialized final table '%s' already exists — skipping CTAS. Use -f to resume missing partitions.",
            final_table,
        )
        return final_table

    columns = [c.name for c in bsq.ts_table.columns]
    has_upgrade = "upgrade" in columns
    partition_cols = _get_partition_columns(bsq)
    materialized_partition_cols = [
        col for col in partition_cols if col not in {"building_id", "time", "timeutc"}
    ]
    if has_upgrade and "upgrade" not in materialized_partition_cols:
        materialized_partition_cols.append("upgrade")

    source_table = hourly_table if hourly_table is not None else f"{table_name}_timeseries"
    final_select_sql, output_columns = create_query_oedi_timeseries(
        bsq,
        simple_workflow=simple_workflow,
        hourly_table=hourly_table,
        skip_period_adjustment=skip_period_adjustment,
    )
    final_output_cols = [col["name"] for col in output_columns]
    partition_cols_set = set(materialized_partition_cols)
    ordered_final_cols = [
        name for name in final_output_cols if name not in partition_cols_set
    ] + [name for name in final_output_cols if name in partition_cols_set]

    def _sql_literal(value: object) -> str:
        return "'" + str(value).replace("'", "''") + "'"

    if materialized_partition_cols:
        partition_select = ", ".join(f'"{col}"' for col in materialized_partition_cols)
        filters = []
        if has_upgrade and upgrade_filter is not None and str(upgrade_filter).lower() != "all":
            upgrade_literal = _sql_literal(upgrade_filter)
            filters.append(f'"upgrade" = {upgrade_literal}')
        where_sql = f" WHERE {' AND '.join(filters)}" if filters else ""
        partition_values = list(
            bsq.execute(
                f"SELECT DISTINCT {partition_select} FROM {source_table}{where_sql}"
            ).itertuples(index=False, name=None)
        )
    else:
        partition_values = [()]

    if not partition_values:
        partition_values = [()]

    s3_loc = _resolve_materialization_location(
        bsq,
        s3_output_location,
        final_table,
        "final",
    )
    if s3_loc is None and s3_output_location is None:
        try:
            workgroup_info = bsq._aws_athena.get_work_group(WorkGroup=bsq.workgroup)
            default_location = workgroup_info["WorkGroup"]["Configuration"]["ResultConfiguration"].get("OutputLocation")
            if default_location:
                s3_loc = default_location.rstrip("/") + "/tables/" + final_table + "/"
                logger.info(
                    "Using workgroup default output location for final materialized table: '%s'.",
                    s3_loc,
                )
        except (KeyError, ClientError) as exc:
            logger.warning(
                "Could not determine workgroup default output location for final materialized table; using Athena-managed location: %s",
                exc,
            )

    if not table_exists and force:
        table_exists = _register_materialized_table_from_s3(
            bsq,
            final_table,
            s3_loc,
            materialized_partition_cols,
            output_columns=output_columns,
        )

    if table_exists:
        if materialized_partition_cols:
            existing_partition_values = list(
                bsq.execute(
                    f"SELECT DISTINCT {partition_select} FROM {final_table}"
                ).itertuples(index=False, name=None)
            )
            existing_partition_keys = {
                tuple(str(value) for value in values)
                for values in existing_partition_values
            }
            missing_partition_values = [
                values
                for values in partition_values
                if tuple(str(value) for value in values) not in existing_partition_keys
            ]
            logger.info(
                "Resuming materialized final table '%s': %d finished partition(s), %d unfinished partition(s).",
                final_table,
                len(existing_partition_values),
                len(missing_partition_values),
            )
        else:
            missing_partition_values = [()]
            logger.info(
                "Resuming unpartitioned materialized final table '%s' with INSERT INTO.",
                final_table,
            )

        if not missing_partition_values:
            logger.info("Materialized final table '%s' already has all expected partitions.", final_table)
            return final_table
    else:
        missing_partition_values = partition_values

    def _select_for_partition(partition_values_tuple: tuple[object, ...]) -> str:
        ordered_cols_sql = ", ".join(f'"{col}"' for col in ordered_final_cols)
        sql = (
            f"SELECT {ordered_cols_sql} FROM ({final_select_sql}) AS final_data"
        )
        where_filters = []
        for col, value in zip(materialized_partition_cols, partition_values_tuple):
            where_filters.append(f'"{col}" = {_sql_literal(value)}')
        if where_filters:
            sql += f" WHERE {' AND '.join(where_filters)}"
        return sql

    def _run_query(query_string: str, label: str) -> None:
        exe_id = bsq._aws_athena.start_query_execution(
            QueryString=query_string,
            QueryExecutionContext={"Database": bsq.db_name},
            WorkGroup=bsq.workgroup,
        )["QueryExecutionId"]
        while True:
            stat = bsq._aws_athena.get_query_execution(QueryExecutionId=exe_id)
            state = stat["QueryExecution"]["Status"]["State"]
            if state in ("SUCCEEDED", "FAILED", "CANCELLED"):
                break
            time.sleep(5)
        if state != "SUCCEEDED":
            reason = stat["QueryExecution"]["Status"].get("StateChangeReason", "")
            msg = f"{label} {state}: {reason}"
            raise RuntimeError(msg)

    partitioned_by = ", ".join(f"'{col}'" for col in materialized_partition_cols)
    with_loc = (
        f"format = 'PARQUET',\n        external_location = '{s3_loc}',\n        partitioned_by = ARRAY[{partitioned_by}]"
        if s3_loc
        else f"format = 'PARQUET',\n        partitioned_by = ARRAY[{partitioned_by}]"
    )
    if not table_exists:
        ctas_sql = (
            f"CREATE TABLE {bsq.db_name}.{final_table}\n"
            f"    WITH (\n        {with_loc}\n    )\n"
            f"    AS\n    {_select_for_partition(missing_partition_values[0])}"
        )
        logger.info(
            "CTAS final materialization [1/%d] upgrade=%s%s",
            len(missing_partition_values),
            upgrade_filter if upgrade_filter is not None else "all",
            f" at '{s3_loc}'" if s3_loc else " (workgroup default output location)",
        )
        try:
            _run_query(ctas_sql, "CTAS final materialization")
        except ClientError as e:
            if (
                e.response["Error"]["Code"] == "InvalidRequestException"
                and "external_location" in e.response["Error"]["Message"]
                and s3_loc is not None
            ):
                msg = (
                    f"Athena rejected requested final materialization location '{s3_loc}': "
                    f"{e.response['Error']['Message']}. The requested destination takes precedence; "
                    "delete or fix that S3 output folder before retrying."
                )
                raise RuntimeError(msg) from e
            else:
                raise

    insert_values = missing_partition_values if table_exists else missing_partition_values[1:]
    for index, values in enumerate(insert_values, start=1 if table_exists else 2):
        insert_sql = (
            f"INSERT INTO {bsq.db_name}.{final_table}\n"
            f"    {_select_for_partition(values)}"
        )
        logger.info(
            "INSERT final materialization [%d/%d] upgrade=%s",
            index,
            len(missing_partition_values),
            upgrade_filter or "all",
        )
        _run_query(insert_sql, "INSERT final materialization")

    glue = boto3.client("glue", region_name=bsq.run_params.region_name)
    table_info = glue.get_table(DatabaseName=bsq.db_name, Name=final_table)
    actual_location = table_info["Table"]["StorageDescriptor"]["Location"]
    if s3_output_location is not None and s3_loc is None:
        logger.warning(
            "Requested final materialization location '%s' was overridden by "
            "workgroup '%s'. Athena created '%s'.",
            s3_output_location,
            bsq.workgroup,
            actual_location,
        )
    else:
        logger.info(
            "Materialized final table '%s' created successfully at '%s'.",
            final_table,
            actual_location,
        )
    return final_table


def _drop_materialized_hourly_table(bsq: BuildStockQuery, hourly_table: str) -> None:
    """Drop a materialized hourly table after validation failure."""
    query_id = bsq._aws_athena.start_query_execution(
        QueryString=f"DROP TABLE IF EXISTS {bsq.db_name}.{hourly_table}",
        QueryExecutionContext={"Database": bsq.db_name},
        WorkGroup=bsq.workgroup,
    )["QueryExecutionId"]
    while True:
        stat = bsq._aws_athena.get_query_execution(QueryExecutionId=query_id)
        state = stat["QueryExecution"]["Status"]["State"]
        if state in ("SUCCEEDED", "FAILED", "CANCELLED"):
            break
        time.sleep(2)
    if state != "SUCCEEDED":
        reason = stat["QueryExecution"]["Status"].get("StateChangeReason", "")
        msg = f"Failed to delete materialized table '{hourly_table}': {reason}"
        raise RuntimeError(msg)


def check_intermediate_hourly_table(
    bsq: BuildStockQuery,
    hourly_table: str,
    expected_upgrade: Optional[str] = "0",
    limit_rows: int = 10,
    retry_attempts: int = 6,
    retry_wait_seconds: int = 10,
) -> None:
    """Validate the schema and baseline hourly data in a materialized table."""
    logger.info("Checking materialized hourly table '%s'...", hourly_table)

    def _sql_literal(value: object) -> str:
        return "'" + str(value).replace("'", "''") + "'"

    where_sql = (
        f" WHERE \"upgrade\" = {_sql_literal(expected_upgrade)}"
        if expected_upgrade is not None
        else ""
    )
    sample = pd.DataFrame()
    for attempt in range(1, retry_attempts + 1):
        sample = bsq.execute(f"SELECT * FROM {hourly_table}{where_sql} LIMIT {limit_rows}")
        if not sample.empty:
            break
        if attempt < retry_attempts:
            logger.warning(
                "Materialized hourly table '%s' returned no rows on validation attempt %d/%d; retrying in %d seconds.",
                hourly_table,
                attempt,
                retry_attempts,
                retry_wait_seconds,
            )
            time.sleep(retry_wait_seconds)

    required = {"building_id", "time", "upgrade"}
    missing = required.difference(sample.columns)
    if missing:
        msg = f"Materialized table '{hourly_table}' is missing columns: {sorted(missing)}"
        raise ValueError(msg)
    if sample.empty:
        msg = (
            f"Materialized table '{hourly_table}' returned no rows after "
            f"{retry_attempts} validation attempt(s). The table was not deleted; "
            "rerun with -f to resume or inspect the materialized output in Athena."
        )
        raise ValueError(msg)

    upgrade_values = sample["upgrade"].dropna().astype(str).unique().tolist()
    if expected_upgrade is not None:
        expected_numeric = float(expected_upgrade)
        actual_numeric = [float(value) for value in upgrade_values]
        valid_upgrade_scope = actual_numeric == [expected_numeric]
    else:
        valid_upgrade_scope = bool(upgrade_values)
    if not valid_upgrade_scope:
        msg = (
            f"Materialized table '{hourly_table}' contains unexpected upgrade values: "
            f"{upgrade_values}"
        )
        raise ValueError(msg)

    timestamps = bsq.execute(
        f'SELECT DISTINCT "time" FROM {hourly_table} ORDER BY 1 LIMIT 3'
    )
    if len(timestamps) >= 2:
        intervals = timestamps["time"].diff().dropna().dt.total_seconds() / 60
        if not (intervals == 60).all():
            msg = f"Materialized table '{hourly_table}' is not hourly: {intervals.tolist()}"
            raise ValueError(msg)
    logger.info("Materialized hourly table '%s' passed validation.", hourly_table)


def create_view_oedi_timeseries(
    bsq: BuildStockQuery,
    view_name: str,
    simple_workflow: bool = False,
    force: bool = False,
    hourly_table: Optional[str] = None,
    skip_period_adjustment: bool = False,
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
    simple_workflow : bool
        If True, use simple column mapping (pass-through unmapped
        columns, skip intensity columns).
    force : bool
        If True, overwrite an existing view with the same name.
    hourly_table : str or None
        If provided, the view is built on top of this pre-materialised
        hourly table rather than aggregating the raw timeseries inline.
        See ``create_materialized_hourly_timeseries_table``.
    """
    select_sql, output_columns = create_query_oedi_timeseries(
        bsq,
        simple_workflow=simple_workflow,
        hourly_table=hourly_table,
        skip_period_adjustment=skip_period_adjustment,
    )
    # logger.info("=" * 60)
    # logger.info("GENERATED SQL:")
    # logger.info("=" * 60)
    # logger.info(select_sql)
    # logger.info("=" * 60)
    create_view(bsq, view_name, select_sql, force, columns=output_columns)


def _reformat_baseline_column_pub_annual_schema(col: str) -> Optional[str]:
    """Reformat a baseline column name to OEDI double-dot convention.

    For ``out.*`` columns (excluding ``out.params.*``), inserts an extra dot
    before the unit segment to match the timeseries convention.

    Examples
    --------
    >>> _reformat_baseline_column_pub_annual_schema("out.electricity.total.energy_consumption.kwh")
    'out.electricity.total.energy_consumption..kwh'
    >>> _reformat_baseline_column_pub_annual_schema("out.load.cooling.energy_delivered.kbtu")
    'out.load.cooling.energy_delivered..kbtu'
    >>> _reformat_baseline_column_pub_annual_schema("in.sqft")
    None
    >>> _reformat_baseline_column_pub_annual_schema("out.params.door_area_ft_2")
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


def _get_supported_baseline_columns(bsq: BuildStockQuery, source_table: str) -> list[str]:
    """Return baseline columns whose Glue types Athena views can represent."""
    glue = boto3.client("glue", region_name=bsq.run_params.region_name)
    table_info = glue.get_table(DatabaseName=bsq.db_name, Name=source_table)
    supported = []
    skipped = []
    table = table_info["Table"]
    columns = table["StorageDescriptor"]["Columns"] + table.get(
        "PartitionKeys", []
    )
    for column in columns:
        column_name = column["Name"]
        col_type = str(column["Type"]).lower()
        if (
            column_name == "in.representative_income"
            or col_type.startswith(("array", "map", "struct", "list", "type:"))
            or "[" in col_type
        ):
            skipped.append((column_name, col_type))
            continue
        supported.append(column_name)
    if skipped:
        logger.warning(
            "Skipping unsupported baseline columns from '%s': %s",
            source_table,
            skipped,
        )
    return supported


def _get_upgrade_table_name(bsq: BuildStockQuery) -> Optional[str]:
    """Return the run upgrade table name, if one exists."""
    tables = list_tables_boto3(
        database=bsq.db_name,
        workgroup=bsq.workgroup,
        region_name=bsq.run_params.region_name,
    )
    for table_name in (f"{bsq.table_name}_upgrade", f"{bsq.table_name}_upgrades"):
        if table_name in tables:
            return table_name
    return None


def _sql_literal(value: str) -> str:
    """Return a safely escaped SQL string literal."""
    return f"'{str(value).replace(chr(39), chr(39) * 2)}'"


def _build_select_from_expr_map(
    source_table: str,
    aliases: list[str],
    expr_by_alias: dict[str, str],
    upgrade_expr: str,
    where_sql: Optional[str] = None,
) -> str:
    """Build a SELECT with aligned aliases and upgrade last for CTAS partitioning."""
    col_exprs = [
        f'{expr_by_alias.get(alias, "NULL")} AS "{alias}"'
        for alias in aliases
    ]
    col_exprs.append(f'{upgrade_expr} AS "upgrade"')
    query = f"SELECT {', '.join(col_exprs)} FROM {source_table}"
    if where_sql is not None:
        query += f" WHERE {where_sql}"
    return query


def _build_raw_annual_expr_map(
    bsq: BuildStockQuery,
    source_table: str,
    source_label: str,
) -> dict[str, str]:
    """Build {published_column: SQL expression} for raw annual result tables."""
    columns = _get_supported_baseline_columns(bsq, source_table)
    baseline_to_pub = _load_baseline_to_pub_annual_mapping()

    expr_by_alias: dict[str, str] = {}
    mapped_cols: list[tuple[str, str]] = []
    skipped_cols: list[str] = []

    for col in columns:
        if col == "upgrade":
            continue
        if col not in baseline_to_pub:
            skipped_cols.append(col)
            logger.debug("%s column not in SDR mapping (skipping): %s", source_label, col)
            continue

        pub_col, factor = baseline_to_pub[col]
        mapped_cols.append((col, pub_col))

        if factor != 1.0:
            expr_by_alias[pub_col] = f'{factor} * "{col}"'
        else:
            expr_by_alias[pub_col] = f'"{col}"'

    logger.info(
        "%s → pub_annual mapping: %d mapped, %d skipped",
        source_label,
        len(mapped_cols),
        len(skipped_cols),
    )
    logger.debug("Skipped %s columns: %s", source_label, skipped_cols)

    if not expr_by_alias:
        msg = (
            f"No {source_label} columns matched the SDR mapping. "
            f"Table '{source_table}' has {len(columns)} columns but none matched "
            f"the {len(baseline_to_pub)} entries in {sdr_column_definitions_file}. "
            f"First 10 table columns: {columns[:10]}"
        )
        raise ValueError(msg)

    return expr_by_alias


def _combine_baseline_with_upgrade_rows(
    bsq: BuildStockQuery,
    baseline_source_table: str,
    baseline_expr_by_alias: dict[str, str],
    baseline_where_sql: Optional[str] = None,
    upgrade_filter: Optional[str] = None,
) -> str:
    """Union processed baseline rows with processed upgrade rows when available."""
    if upgrade_filter is not None and str(upgrade_filter) != "0":
        baseline_where_sql = "FALSE"

    upgrade_table = _get_upgrade_table_name(bsq)
    if upgrade_table is None:
        aliases = list(baseline_expr_by_alias)
        return _build_select_from_expr_map(
            baseline_source_table,
            aliases,
            baseline_expr_by_alias,
            "CAST(0 AS INTEGER)",
            where_sql=baseline_where_sql,
        )

    upgrade_expr_by_alias = _build_raw_annual_expr_map(
        bsq,
        upgrade_table,
        "Upgrade",
    )
    aliases = list(baseline_expr_by_alias)
    aliases.extend(
        alias for alias in upgrade_expr_by_alias if alias not in baseline_expr_by_alias
    )
    baseline_select = _build_select_from_expr_map(
        baseline_source_table,
        aliases,
        baseline_expr_by_alias,
        "CAST(0 AS INTEGER)",
        where_sql=baseline_where_sql,
    )
    upgrade_select = _build_select_from_expr_map(
        upgrade_table,
        aliases,
        upgrade_expr_by_alias,
        'CAST("upgrade" AS INTEGER)',
        where_sql=(
            f'CAST("upgrade" AS VARCHAR) = {_sql_literal(upgrade_filter)}'
            if upgrade_filter is not None
            else None
        ),
    )
    logger.info(
        "Combining baseline source '%s' with upgrade table '%s'.",
        baseline_source_table,
        upgrade_table,
    )
    return f"{baseline_select} UNION ALL {upgrade_select}"


def create_query_oedi_baseline_from_pub_annual(
    bsq: BuildStockQuery,
    upgrade_filter: Optional[str] = None,
) -> str:
    """Build a SELECT statement that renames baseline columns in _pub_annual table to OEDI convention.

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

    columns = _get_supported_baseline_columns(bsq, source_table)

    expr_by_alias: dict[str, str] = {}
    for col in columns:
        if col == "upgrade":
            continue
        new_col = _reformat_baseline_column_pub_annual_schema(col)
        if new_col is not None:
            expr_by_alias[new_col] = f'"{col}"'
        else:
            expr_by_alias[col] = f'"{col}"'

    upgrade_expr = (
        'CAST("upgrade" AS INTEGER)'
        if "upgrade" in columns
        else "CAST(0 AS INTEGER)"
    )
    where_sql = (
        f'CAST("upgrade" AS VARCHAR) = {_sql_literal(upgrade_filter)}'
        if upgrade_filter is not None and "upgrade" in columns
        else None
    )
    return _build_select_from_expr_map(
        source_table,
        list(expr_by_alias),
        expr_by_alias,
        upgrade_expr,
        where_sql=where_sql,
    )


def _load_baseline_to_pub_annual_mapping() -> dict[str, tuple[str, float]]:
    """Build a {baseline_col: (pub_annual_col, factor)} mapping from the SDR definitions file.

    Reads ``Annual Name``, ``Published Annual Name``, and
    ``ResStock To Published Annual Unit Conversion Factor`` from the SDR column
    definitions CSV.  Only rows where both names are non-empty are included.

    Returns
    -------
    dict[str, tuple[str, float]]
        Mapping ``{baseline_col: (pub_annual_col, conversion_factor)}``.
    """
    import csv as _csv

    mapping: dict[str, tuple[str, float]] = {}
    with open(sdr_column_definitions_file) as f:
        reader = _csv.DictReader(f)
        for row in reader:
            ann = row["Annual Name"].strip()
            pub = row["Published Annual Name"].strip()
            if not ann or not pub:
                continue
            factor_str = row["ResStock To Published Annual Unit Conversion Factor"].strip()
            try:
                factor = float(factor_str) if factor_str else 1.0
            except ValueError:
                factor = 1.0
            if ann not in mapping:
                mapping[ann] = (pub, factor)
    return mapping


def create_query_oedi_baseline_from_baseline(
    bsq: BuildStockQuery,
    upgrade_filter: Optional[str] = None,
) -> str:
    """Build a SELECT that converts _baseline columns to _pub_annual naming.

    Uses the SDR column definitions CSV to map raw ``build_existing_model.*``,
    ``report_simulation_output.*``, and ``upgrade_costs.*`` column names
    (``Annual Name``) to their published equivalents (``Published Annual Name``),
    applying unit conversion factors where required.

    The resulting query can serve as a drop-in substitute for selecting from
    ``_pub_annual`` when that table does not yet exist.  Columns present in the
    baseline table but absent from the SDR mapping are silently skipped.

    Parameters
    ----------
    bsq : BuildStockQuery
        An initialized BuildStockQuery instance.

    Returns
    -------
    str
        SQL SELECT statement with column aliases and unit conversions.
    """
    source_table = f"{bsq.table_name}_baseline"

    expr_by_alias = _build_raw_annual_expr_map(bsq, source_table, "Baseline")
    return _combine_baseline_with_upgrade_rows(
        bsq,
        source_table,
        expr_by_alias,
        upgrade_filter=upgrade_filter,
    )


def create_view_oedi_baseline(
    bsq: BuildStockQuery,
    view_name: str,
    force: bool = False,
    upgrade_filter: Optional[str] = None,
) -> None:
    """Create an Athena view with OEDI baseline schema.

    [1] Use _pub_annual if exists 

    Renames energy columns in ``<table_name>_pub_annual`` to use the OEDI
    double-dot convention (e.g. ``out.electricity.total.energy_consumption..kwh``)
    and creates the view as ``<table_name>{BL_VIEW_SUFFIX}``.

    [2] If the _pub_annual table does not exist, falls back to the _baseline table
    and renames columns to OEDI convention.

    Parameters
    ----------
    bsq : BuildStockQuery
        An initialized BuildStockQuery instance.
    view_name : str
        Name for the new view.
    force : bool
        If True, overwrite an existing view with the same name.
    """
    pub_annual_table = f"{bsq.table_name}_pub_annual"
    if pub_annual_table in list_tables_boto3(
        database=bsq.db_name, 
        workgroup=bsq.workgroup, 
        region_name=bsq.region_name
        ):
        select_sql = create_query_oedi_baseline_from_pub_annual(bsq, upgrade_filter)
    else:
        select_sql = create_query_oedi_baseline_from_baseline(bsq, upgrade_filter)
    create_view(bsq, view_name, select_sql, force)


def export_baseline_to_single_parquet(
    bsq: BuildStockQuery,
    source_name: str,
    output_path: str,
) -> None:
    """Export upgrade 0 from a baseline Athena view or table in Athena result pages.

    Each result page is appended to one local Parquet file, avoiding a full
    result DataFrame and the S3 connection pool used by ``bsq.execute``.
    """
    if output_path.startswith("s3://"):
        msg = "--export-baseline-parquet only accepts a local file or directory path."
        raise ValueError(msg)

    path = Path(output_path).expanduser()
    if output_path.endswith("/") or path.suffix == "":
        path = path / "results_up00.parquet"
    elif path.suffix.lower() != ".parquet":
        msg = (
            "--export-baseline-parquet must be a directory or a local file path "
            "ending in .parquet."
        )
        raise ValueError(msg)
    path.parent.mkdir(parents=True, exist_ok=True)

    logger.info("Exporting baseline '%s' to one local Parquet file at '%s'.", source_name, path)
    execution_id = bsq._aws_athena.start_query_execution(
        QueryString=f'SELECT * FROM {source_name} WHERE "upgrade" = 0',
        QueryExecutionContext={"Database": bsq.db_name},
        WorkGroup=bsq.workgroup,
    )["QueryExecutionId"]
    while True:
        execution = bsq._aws_athena.get_query_execution(
            QueryExecutionId=execution_id
        )
        status = execution["QueryExecution"]["Status"]
        state = status["State"]
        if state in ("SUCCEEDED", "FAILED", "CANCELLED"):
            break
        time.sleep(1)
    if state != "SUCCEEDED":
        reason = status.get("StateChangeReason", "")
        msg = f"Baseline export query {state}: {reason}"
        raise RuntimeError(msg)

    next_token = None
    writer = None
    row_count = 0
    try:
        while True:
            kwargs = {"QueryExecutionId": execution_id, "MaxResults": 1000}
            if next_token is not None:
                kwargs["NextToken"] = next_token
            result = bsq._aws_athena.get_query_results(**kwargs)
            result_set = result["ResultSet"]
            column_names = [
                column["Name"]
                for column in result_set["ResultSetMetadata"]["ColumnInfo"]
            ]
            rows = result_set["Rows"]
            if next_token is None and rows:
                rows = rows[1:]
            values = []
            for row in rows:
                row_values = [cell.get("VarCharValue") for cell in row["Data"]]
                row_values.extend([None] * (len(column_names) - len(row_values)))
                values.append(row_values)
            if values:
                dataframe = pd.DataFrame(values, columns=column_names)
                if writer is None:
                    parquet_table = pa.Table.from_pandas(
                        dataframe,
                        preserve_index=False,
                    )
                    writer = pq.ParquetWriter(path, parquet_table.schema)
                else:
                    parquet_table = pa.Table.from_pandas(
                        dataframe,
                        schema=writer.schema,
                        preserve_index=False,
                    )
                writer.write_table(parquet_table)
                row_count += len(dataframe)
            next_token = result.get("NextToken")
            if next_token is None:
                break
    finally:
        if writer is not None:
            writer.close()

    if writer is None:
        msg = f"Baseline source '{source_name}' returned no rows; no Parquet file was written."
        raise ValueError(msg)
    logger.info("Exported %d baseline row(s) to '%s'.", row_count, path)


def _delete_s3_prefix(s3_location: str, region_name: str) -> None:
    """Delete all objects at an S3 location before replacing a CTAS table."""
    if not s3_location.startswith("s3://"):
        msg = f"Expected an S3 location, got '{s3_location}'."
        raise ValueError(msg)

    bucket_and_prefix = s3_location.removeprefix("s3://")
    bucket, _, prefix = bucket_and_prefix.partition("/")
    s3 = boto3.client("s3", region_name=region_name)
    paginator = s3.get_paginator("list_objects_v2")
    for page in paginator.paginate(Bucket=bucket, Prefix=prefix):
        objects = [{"Key": obj["Key"]} for obj in page.get("Contents", [])]
        for start in range(0, len(objects), 1000):
            s3.delete_objects(
                Bucket=bucket,
                Delete={"Objects": objects[start : start + 1000], "Quiet": True},
            )


def create_materialized_baseline_table(
    bsq: BuildStockQuery,
    s3_output_location: Optional[str] = None,
    force: bool = False,
    upgrade_filter: Optional[str] = None,
) -> str:
    """Materialize the OEDI baseline as an upgrade-partitioned Athena table.

    The table is named ``<table>_md_national_parquet`` and partitioned by the
    ``upgrade`` column. Published annual sources are converted directly;
    otherwise baseline and upgrade source tables are combined. Athena controls
    the number and names of CTAS output objects.
    """
    baseline_table = f"{bsq.table_name}{BL_VIEW_SUFFIX}"
    table_exists = baseline_table in list_tables_boto3(
        bsq.db_name, bsq.workgroup, region_name=bsq.run_params.region_name
    )
    if table_exists:
        glue = boto3.client("glue", region_name=bsq.run_params.region_name)
        table_info = glue.get_table(DatabaseName=bsq.db_name, Name=baseline_table)
        table_type = table_info["Table"].get("TableType")
        if force:
            if table_type == "VIRTUAL_VIEW":
                logger.info("Deleting existing baseline view '%s' before CTAS materialization.", baseline_table)
            else:
                location = table_info["Table"]["StorageDescriptor"].get("Location")
                if location:
                    logger.info("Deleting existing baseline table output at '%s'.", location)
                    _delete_s3_prefix(location, bsq.run_params.region_name)
                logger.info("Deleting existing baseline table '%s' before CTAS materialization.", baseline_table)
            glue.delete_table(DatabaseName=bsq.db_name, Name=baseline_table)
        else:
            logger.info("Materialized baseline table '%s' already exists; reusing it.", baseline_table)
            return baseline_table

    pub_annual_table = f"{bsq.table_name}_pub_annual"
    if pub_annual_table in list_tables_boto3(
        database=bsq.db_name,
        workgroup=bsq.workgroup,
        region_name=bsq.run_params.region_name,
    ):
        select_sql = create_query_oedi_baseline_from_pub_annual(bsq, upgrade_filter)
    else:
        select_sql = create_query_oedi_baseline_from_baseline(bsq, upgrade_filter)

    s3_loc = _resolve_materialization_location(
        bsq,
        s3_output_location,
        baseline_table,
        "baseline",
    )
    if s3_loc is None and s3_output_location is None:
        try:
            workgroup_info = bsq._aws_athena.get_work_group(WorkGroup=bsq.workgroup)
            default_location = workgroup_info["WorkGroup"]["Configuration"][
                "ResultConfiguration"
            ].get("OutputLocation")
            if default_location:
                s3_loc = default_location.rstrip("/") + f"/tables/{baseline_table}/"
        except (KeyError, ClientError) as exc:
            logger.warning(
                "Could not determine a default output location for baseline materialization: %s",
                exc,
            )
    table_properties = ["format = 'PARQUET'"]
    if s3_loc is not None:
        table_properties.append(f"external_location = '{s3_loc}'")
    table_properties.append("partitioned_by = ARRAY['upgrade']")
    table_properties_sql = ",\n        ".join(table_properties)
    ctas_sql = (
        f"CREATE TABLE {bsq.db_name}.{baseline_table}\n"
        f"    WITH (\n        {table_properties_sql}\n    )\n"
        f"    AS\n    {select_sql}"
    )
    _run_athena_query_and_wait(bsq, ctas_sql, "CTAS baseline materialization")
    glue = boto3.client("glue", region_name=bsq.run_params.region_name)
    actual_location = glue.get_table(
        DatabaseName=bsq.db_name,
        Name=baseline_table,
    )["Table"]["StorageDescriptor"]["Location"]
    if s3_output_location is not None and s3_loc is None:
        logger.warning(
            "Requested baseline materialization location '%s' was overridden by "
            "workgroup '%s'. Athena created '%s'.",
            s3_output_location,
            bsq.workgroup,
            actual_location,
        )
    else:
        logger.info("Materialized baseline table '%s' created at '%s'.", baseline_table, actual_location)
    return baseline_table


def check_view_table_oedi_timeseries(
    bsq: BuildStockQuery,
    view_name: str,
    simple_workflow: bool = False,
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
    simple_workflow : bool
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
    compute_intensity_cols, _ = _get_column_mapping_config(simple_workflow)

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
    df2["timestamp"] = pd.to_datetime(df2["timestamp"])
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
    logger.info(f"check_view_table_result completed in {time.time() - t0:.1f}s")


def check_view_table_oedi_baseline(
    bsq: BuildStockQuery,
    view_name: str,
    limit_rows: int = 10,
) -> None:
    """Run a basic validation query against the national baseline view."""
    logger.info("Checking baseline view '%s'...", view_name)
    df = bsq.execute(f"SELECT * FROM {view_name} LIMIT {limit_rows}")
    if not df.columns.tolist():
        msg = f"Baseline view '{view_name}' returned no columns."
        raise ValueError(msg)
    if df.empty:
        msg = f"Baseline view '{view_name}' returned no rows."
        raise ValueError(msg)
    if "upgrade" not in df.columns:
        msg = f"Baseline view '{view_name}' is missing required 'upgrade' column."
        raise ValueError(msg)
    logger.info(
        "Baseline view '%s' passed validation with %d columns and %d sampled rows.",
        view_name,
        len(df.columns),
        len(df),
    )


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

    parquet_key = None
    parquet_size = float("inf")
    paginator = s3.get_paginator("list_objects_v2")
    for page in paginator.paginate(Bucket=bucket, Prefix=prefix):
        for obj in page.get("Contents", []):
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
            logger.info(f"Table '{table}' already exists.")
        return

    # Create a table for each subfolder: <table>_<subfolder_name>
    logger.info(f"Found subfolders: {subfolders}")
    for subfolder in subfolders:
        sub_table_name = f"{table}_{subfolder}"
        sub_s3_location = f"{s3_loc}{subfolder}/"
        if sub_table_name in tables:
            logger.info(f"Table '{sub_table_name}' already exists.")
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
    # Configure logging with both console and file handlers.
    # force=True is required because imported modules (e.g. buildstock_query)
    # often add handlers to the root logger before main() is called, which
    # makes basicConfig a no-op without it.
    log_file = Path(__file__).parent / "create_athena_views_from_results.log"
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ],
        force=True,
    )
    logger.info("Starting create_athena_views_from_results script")
    parser = argparse.ArgumentParser(
        description=(
            "Create OEDI Athena views or partitioned materialized timeseries tables. "
            "With -b -m, create a baseline table partitioned by upgrade. Use "
            "--export-baseline-parquet with -b to create one local Parquet file."
        )
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
        "--region", default="us-west-2", help="AWS region (default: us-west-2)."
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
        help=(
            "Overwrite existing views. With --materialize-intermediate or "
            "--materialize-final, resume an existing materialized table by "
            "preserving finished partitions and inserting only missing partitions. "
            "If table metadata was dropped but S3 output files remain, recreate "
            "the table over those files and repair partitions before resuming. "
            "Without -f, existing materialized tables are reused as-is."
        ),
    )
    parser.add_argument(
        "-c",
        "--check",
        action="store_true",
        help="Run check_view_table_result after creating the view.",
    )
    parser.add_argument(
        "-r",
        "--reduced-workflow",
        action="store_true",
        help="Use reduced column mapping (pass-through unmapped columns, skip intensity columns).",
    )
    parser.add_argument(
        "-s",
        "--skip-period-adjustment",
        action="store_true",
        help="Skip the EST/period-beginning timestamp adjustment and keep source timestamps as-is.",
    )
    parser.add_argument(
        "-b",
        "--baseline-view",
        action="store_true",
        help=(
            "Create only the baseline view. Combine with --materialize-final to "
            "create a baseline table partitioned by upgrade instead."
        ),
    )
    parser.add_argument(
        "--export-baseline-parquet",
        metavar="LOCAL_PATH",
        default=None,
        help=(
            "With --baseline-view, export the resulting baseline view or table "
            "as exactly one local Parquet file. Accepts a .parquet file path or a "
            "directory path, which receives the default results_up00.parquet name."
        ),
    )
    parser.add_argument(
        "--materialize-intermediate",
        nargs="?",
        const=True,
        metavar="S3_LOCATION",
        default=None,
        help=(
            "Before creating the view, pre-aggregate the raw timeseries to hourly "
            "resolution via Athena CTAS and register a Glue table "
            "<table>_timeseries_hourly.  The view is then built on top of this "
            "materialized table instead of the raw timeseries, eliminating the "
            "GROUP BY aggregation at every query and making the view instantly "
            "previewable.  S3_LOCATION is optional: when omitted the workgroup's "
            "default output path is used. All upgrades are materialized by default; use "
            "--upgrade-filter 0 to select only upgrade 0. Without -f, an existing "
            "hourly table is reused as-is. Use -f to resume missing partitions in "
            "an existing hourly table, or to recreate the table from existing S3 "
            "output files if only the files remain."
        ),
    )
    parser.add_argument(
        "-m",
        "--materialize-final",
        nargs="?",
        const=True,
        metavar="S3_LOCATION",
        default=None,
        help=(
            "Materialize the final transformed OEDI timeseries query as a partitioned "
            "Athena table named <table>_ts_by_state. This provides a previewable "
            "final table even when the final view is too expensive to scan repeatedly. "
            "When omitted, the workgroup default output location is used. Without -f, "
            "an existing final table is reused as-is. Use -f to resume missing "
            "partitions in an existing final table, or to recreate the table from "
            "existing S3 output files if only the files remain. With --baseline-view, "
            "materialize a baseline table partitioned by upgrade instead."
        ),
    )
    parser.add_argument(
        "--check-intermediate",
        action="store_true",
        help=(
            "Validate an existing or newly created materialized hourly table "
            "before creating the timeseries view or final table. Empty validation "
            "samples are retried; if validation still fails, the table is preserved "
            "for Athena inspection or -f resume. Combine with -f to resume missing "
            "hourly partitions before validation."
        ),
    )
    parser.add_argument(
        "-u",
        "--upgrade-filter",
        default=None,
        metavar="UPGRADE",
        help=(
            "Upgrade value to materialize (default: all upgrades). Use '0' to "
            "materialize only upgrade 0."
        ),
    )
    args = parser.parse_args()

    if args.export_baseline_parquet is not None and not args.baseline_view:
        msg = "--export-baseline-parquet can only be used with --baseline-view."
        parser.error(msg)

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
    logger.info(f"  reduced-workflow: {args.reduced_workflow}")
    logger.info(f"  skip-period-adjustment: {args.skip_period_adjustment}")
    logger.info(f"  baseline-view: {args.baseline_view}")
    logger.info(f"  export-baseline-parquet: {args.export_baseline_parquet}")
    logger.info(f"  materialize-intermediate: {args.materialize_intermediate}")
    logger.info(f"  materialize-final: {args.materialize_final}")
    logger.info(f"  check-intermediate: {args.check_intermediate}")
    logger.info("=" * 60)
    
    # Log execution parameters
    logger.info("Processing parameters:")
    logger.info(f"  database={args.database}, table={args.table}, workgroup={args.workgroup}")
    logger.info(f"  reduced_workflow={args.reduced_workflow}, baseline_view={args.baseline_view}, skip_period_adjustment={args.skip_period_adjustment}")
    logger.info(f"  force={args.force}, check={args.check}")
    logger.info(f"  export_baseline_parquet={args.export_baseline_parquet}")
    logger.info(f"  materialize_intermediate={args.materialize_intermediate}")
    logger.info(f"  materialize_final={args.materialize_final}")
    logger.info(f"  check_intermediate={args.check_intermediate}")
    logger.info(f"  upgrade_filter={args.upgrade_filter}")

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
        logger.error("For detailed diagnostic information, check create_athena_views_from_results.log")
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
                f"  python create_athena_views_from_results.py \\\n"
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

    ts_output_type = "table" if args.materialize_final else "view"
    logger.debug("-" * 60)
    logger.info(f"Creating {ts_output_type} from raw result tables...")
    logger.debug("-" * 60)

    if args.baseline_view:
        bl_view_name = f"{args.table}{BL_VIEW_SUFFIX}"
        baseline_upgrade_filter = (
            None
            if args.upgrade_filter is None or args.upgrade_filter.lower() == "all"
            else args.upgrade_filter
        )
        if args.materialize_final is not None:
            baseline_s3_loc = (
                args.materialize_final
                if isinstance(args.materialize_final, str)
                else None
            )
            logger.info("Creating materialized baseline table: %s", bl_view_name)
            baseline_table = create_materialized_baseline_table(
                bsq,
                s3_output_location=baseline_s3_loc,
                force=args.force,
                upgrade_filter=baseline_upgrade_filter,
            )
            logger.info("Materialized baseline table ready: '%s'", baseline_table)
            _log_materialized_table_location(bsq, baseline_table, "baseline")
            if args.check:
                check_view_table_oedi_baseline(bsq, view_name=baseline_table)
            if args.export_baseline_parquet is not None:
                export_baseline_to_single_parquet(
                    bsq,
                    baseline_table,
                    args.export_baseline_parquet,
                )
        else:
            logger.info(f"Creating baseline view: {bl_view_name}")
            create_view_oedi_baseline(
                bsq,
                view_name=bl_view_name,
                force=args.force,
                upgrade_filter=baseline_upgrade_filter,
            )
            logger.info(f"Successfully created baseline view: {bl_view_name}")
            if args.check:
                check_view_table_oedi_baseline(bsq, view_name=bl_view_name)
            if args.export_baseline_parquet is not None:
                export_baseline_to_single_parquet(
                    bsq,
                    bl_view_name,
                    args.export_baseline_parquet,
                )
        logger.info(f"Baseline-only mode enabled; skipping timeseries {ts_output_type} creation.")
        return

    ts_view_name = f"{args.table}{TS_VIEW_SUFFIX}"
    logger.info(f"Creating timeseries {ts_output_type}: {ts_view_name}")

    hourly_table = None
    if args.materialize_intermediate is not None or args.check_intermediate:
        # args.materialize_intermediate is either a string (S3 path supplied) or
        # True (flag given without a value — let the workgroup decide output path).
        s3_loc_arg = (
            args.materialize_intermediate
            if isinstance(args.materialize_intermediate, str)
            else None
        )
        logger.info(
            "Materializing intermediate hourly table%s…",
            f" at '{s3_loc_arg}'" if s3_loc_arg else " (workgroup default output location)",
        )
        hourly_table_name = f"{args.table}_timeseries_hourly"
        existing_hourly = hourly_table_name in list_tables_boto3(
            bsq.db_name,
            bsq.workgroup,
            region_name=bsq.run_params.region_name,
        )
        hourly_table = create_materialized_hourly_timeseries_table(
            bsq,
            s3_output_location=s3_loc_arg,
            upgrade_filter=(
                None
                if args.upgrade_filter is None or args.upgrade_filter.lower() == "all"
                else args.upgrade_filter
            ),
            force=args.force,
        )
        if args.check_intermediate:
            try:
                expected_upgrade = (
                    None
                    if args.upgrade_filter is None or args.upgrade_filter.lower() == "all"
                    else args.upgrade_filter
                )
                check_intermediate_hourly_table(
                    bsq,
                    hourly_table,
                    expected_upgrade=expected_upgrade,
                )
            except Exception:
                logger.exception(
                    "Materialized hourly table '%s' failed validation; preserving it for inspection or -f resume.",
                    hourly_table,
                )
                if existing_hourly:
                    msg = (
                        f"Existing materialized table '{hourly_table}' failed validation "
                        "and was preserved. Inspect it in Athena or rerun with -f to resume."
                    )
                else:
                    msg = (
                        f"New materialized table '{hourly_table}' failed validation "
                        "and was preserved. Inspect it in Athena or rerun with -f to resume."
                    )
                raise RuntimeError(msg) from None
        logger.info("Intermediate table ready: '%s'", hourly_table)
        _log_materialized_table_location(bsq, hourly_table, "hourly")

    if args.materialize_final is not None:
        final_s3_loc = (
            args.materialize_final
            if isinstance(args.materialize_final, str)
            else None
        )
        final_table = create_materialized_final_timeseries_table(
            bsq,
            s3_output_location=final_s3_loc,
            upgrade_filter=(
                None
                if args.upgrade_filter is None or args.upgrade_filter.lower() == "all"
                else args.upgrade_filter
            ),
            hourly_table=hourly_table,
            simple_workflow=args.reduced_workflow,
            skip_period_adjustment=args.skip_period_adjustment,
            force=args.force,
        )
        logger.info("Final materialized table ready: '%s'", final_table)
        _log_materialized_table_location(bsq, final_table, "final")

        if args.check:
            logger.info("Running validation checks on materialized final table: %s", final_table)
            check_view_table_oedi_timeseries(
                bsq,
                view_name=final_table,
                simple_workflow=args.reduced_workflow,
            )
            logger.info("Validation checks completed for materialized final table: %s", final_table)
    else:
        create_view_oedi_timeseries(
            bsq,
            view_name=ts_view_name,
            simple_workflow=args.reduced_workflow,
            force=args.force,
            hourly_table=hourly_table,
            skip_period_adjustment=args.skip_period_adjustment,
        )
        logger.info(f"Successfully created timeseries view: {ts_view_name}")

        if args.check:
            logger.info(f"Running validation checks on view: {ts_view_name}")
            check_view_table_oedi_timeseries(
                bsq,
                view_name=ts_view_name,
                simple_workflow=args.reduced_workflow,
            )
            logger.info(f"Validation checks completed for view: {ts_view_name}")
    
    logger.info("create_athena_views_from_results script completed successfully")
    logger.info("=" * 60)
    logger.info("Processing completed. Check create_athena_views_from_results.log for detailed traceability.")
    logger.info("=" * 60)

if __name__ == "__main__":
    main()
