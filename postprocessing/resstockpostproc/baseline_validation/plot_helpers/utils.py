"""Shared utilities for baseline validation."""

import functools
import logging
import tomllib
from pathlib import Path

from resstockpostproc.baseline_validation.schema.workflow_schema import DataSourceConfig
from buildstock_query import BuildStockQuery


KBTU2KWH = 0.29307107
logger = logging.getLogger(__name__)

# Bundle our own copies of the BSQ db_schema TOMLs so the pipeline doesn't
# depend on the buildstock_query package shipping them as data files.
_DB_SCHEMA_DIR = Path(__file__).resolve().parent.parent / "db_schemas"


def ensure_directory(path: Path) -> Path:
    """Ensure a directory exists, creating it if necessary."""
    path = Path(path)
    path.mkdir(parents=True, exist_ok=True)
    return path


def _load_db_schema(name: str) -> dict:
    schema_path = _DB_SCHEMA_DIR / f"{name}.toml"
    with open(schema_path, "rb") as f:
        return tomllib.load(f)


@functools.cache
def get_buildstock_query(
    workgroup: str,
    config: DataSourceConfig,
    comparison_data_year: int = 2018,
    skip_reports: bool = False,
) -> BuildStockQuery:
    """Create and configure a BuildStockQuery instance."""
    cache_folder = str(Path(__file__).resolve().parent.parent.parent / ".bsq_cache")
    query_unload_s3_bucket = config.query_unload_s3_bucket or workgroup
    if config.query_unload_s3_bucket is None:
        logger.warning(
            "BuildStockQuery using workgroup as default "
            "query_unload_s3_bucket. source=%s workgroup=%s bucket=%s",
            config.name,
            workgroup,
            query_unload_s3_bucket,
        )
    db_schema = _load_db_schema(config.db_schema.value)
    if config.has_upgrades:
        table_name = config.table_name
    else:
        # Pass a tuple to BSQ: (baseline, timeseries, None) to skip the upgrades table
        baseline_suffix = db_schema["table_suffix"]["baseline"]
        ts_suffix = db_schema["table_suffix"]["timeseries"]
        table_name = (f"{config.table_name}{baseline_suffix}", f"{config.table_name}{ts_suffix}", None)
        logger.warning(
            "BuildStockQuery configured without upgrades table; upgrades will be skipped. "
            "source=%s baseline_table=%s timeseries_table=%s",
            config.name,
            table_name[0],
            table_name[1],
        )
    bsq = BuildStockQuery(
        workgroup=workgroup,
        db_name=config.db_name,
        table_name=table_name,
        skip_reports=skip_reports,
        db_schema=db_schema,
        cache_folder=cache_folder,
        query_unload_s3_bucket=query_unload_s3_bucket,
    )
    bsq.utility.eia_mapping_year = comparison_data_year
    return bsq
