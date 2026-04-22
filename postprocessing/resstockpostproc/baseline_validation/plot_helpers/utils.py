"""Shared utilities for baseline validation."""

import functools
import tomllib
from pathlib import Path

from resstockpostproc.baseline_validation.schema.workflow_schema import DataSourceConfig
from buildstock_query import BuildStockQuery


KBTU2KWH = 0.29307107

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
    bsq = BuildStockQuery(
        workgroup=workgroup,
        db_name=config.db_name,
        table_name=config.table_name,
        skip_reports=skip_reports,
        db_schema=_load_db_schema(config.db_schema.value),
        cache_folder=cache_folder,
    )
    bsq.utility.eia_mapping_year = comparison_data_year
    return bsq
