"""Shared output path helpers for the standalone baseline validation dashboard."""

from __future__ import annotations

import os
from pathlib import Path


DASHBOARD_FILENAME = "comparison_dashboard.html"
DASHBOARD_DATA_DIRNAME = "dashboard_data"
COMPARISONS_INDEX_DIRNAME = "comparisons_index"
COMPARISONS_INDEX_TSV_FILENAME = "comparisons_index.tsv"
ASSETS_DIRNAME = "assets"
TRACE_FILENAME = "trace.json"


def dashboard_html_path(output_root: Path) -> Path:
    """Return the root dashboard HTML path for a run."""
    return output_root / DASHBOARD_FILENAME


def dashboard_data_dir(output_root: Path) -> Path:
    """Return the shared data directory for a run."""
    return output_root / DASHBOARD_DATA_DIRNAME


def comparisons_index_tsv_path(output_root: Path) -> Path:
    """Return the dashboard index TSV path."""
    return dashboard_data_dir(output_root) / COMPARISONS_INDEX_TSV_FILENAME


def comparisons_index_data_dir(output_root: Path) -> Path:
    """Return the sharded dashboard data directory."""
    return dashboard_data_dir(output_root) / COMPARISONS_INDEX_DIRNAME


def dashboard_assets_dir(output_root: Path) -> Path:
    """Return the vendored asset directory for a run."""
    return dashboard_data_dir(output_root) / ASSETS_DIRNAME


def trace_output_path(output_root: Path) -> Path:
    """Return the trace output path for a run."""
    return dashboard_data_dir(output_root) / TRACE_FILENAME


def dataset_output_dir(output_root: Path, dataset: str, content_kind: str, fmt: str) -> Path:
    """Return a dataset-specific output directory inside ``dashboard_data``."""
    return dashboard_data_dir(output_root) / f"{dataset} {content_kind} ({fmt})"


def relative_href_from_file(target: Path, source_file: Path) -> str:
    """Return a POSIX relative href from one file to another path."""
    return os.path.relpath(target, start=source_file.parent).replace(os.sep, "/")


def relative_href_from_dir(target: Path, source_dir: Path) -> str:
    """Return a POSIX relative href from a directory to another path."""
    return os.path.relpath(target, start=source_dir).replace(os.sep, "/")
