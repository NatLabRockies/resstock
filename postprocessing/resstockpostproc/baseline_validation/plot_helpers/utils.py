"""Shared utilities for baseline validation."""

import functools
from pathlib import Path

from resstockpostproc.baseline_validation.schema.workflow_schema import DataSourceConfig
from buildstock_query import BuildStockQuery


KBTU2KWH = 0.29307107


def ensure_directory(path: Path) -> Path:
    """Ensure a directory exists, creating it if necessary."""
    path = Path(path)
    path.mkdir(parents=True, exist_ok=True)
    return path


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
