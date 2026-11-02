"""Shared utilities for baseline validation."""

import functools
import os
import tomllib
from pathlib import Path

from resstockpostproc.baseline_validation.schema.workflow_schema import DataSourceConfig
from buildstock_query import BuildStockQuery


KBTU2KWH = 0.29307107

# Bundle our own copies of the BSQ db_schema TOMLs so the pipeline doesn't
# depend on the buildstock_query package shipping them as data files.
_DB_SCHEMA_DIR = Path(__file__).resolve().parent.parent / "db_schemas"


_EXTENDED_PATH_PREFIX = "\\\\?\\"


def os_path(path: Path) -> Path:
    """Return `path` in the form the OS needs for file I/O.

    Windows refuses a path beyond 260 characters unless it carries the extended-length
    prefix, and this dashboard nests a long plot title under several filter directories, so
    the deepest panels cross that limit. The prefix only works on an absolute, normalised
    path, and it is meaningless elsewhere, so this is a no-op off Windows.

    Use it at the point of I/O only. A prefixed path is not comparable with a plain one and
    `os.path.relpath` will not produce a usable href from it, so the paths recorded in the
    dashboard index stay plain.
    """
    if os.name != "nt":
        return path
    text = os.path.abspath(path)
    return Path(text if text.startswith(_EXTENDED_PATH_PREFIX) else _EXTENDED_PATH_PREFIX + text)


def ensure_directory(path: Path) -> Path:
    """Ensure a directory exists, creating it if necessary."""
    path = Path(path)
    os_path(path).mkdir(parents=True, exist_ok=True)
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
