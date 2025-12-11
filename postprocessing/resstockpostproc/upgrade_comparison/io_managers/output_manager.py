"""
Functional helpers for saving plot outputs and metadata.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Literal
from collections.abc import Sequence

import polars as pl
from filelock import FileLock
from plotly.graph_objects import Figure

from resstockpostproc.upgrade_comparison.schema.workflow_schema import WorkflowConfig

DEFAULT_OUTPUT_TYPES = ["json", "parquet", "html"]

__all__ = [
    "get_file_path",
    "get_plot_base_dir",
    "remove_lock_files",
    "save_plot",
    "write_csv_file",
    "write_html_file",
    "write_json_file",
    "write_parquet_file",
    "write_svg_file",
    "write_workflow_snapshot",
]


def get_plot_base_dir(workflow: WorkflowConfig) -> Path:
    """Return the base directory where plots for this workflow should be written."""
    return Path(workflow.output_dir).expanduser().resolve() / "plots" / workflow.run_name


def write_workflow_snapshot(workflow: WorkflowConfig, base_dir: Path) -> None:
    """Write a JSON snapshot of the workflow configuration once per run."""
    config_file = base_dir / "workflow_snapshot.json"
    if config_file.exists():
        existing_workflow = json.loads(config_file.read_text(encoding="utf-8"))
        if existing_workflow["s3_results_dir"] == workflow.s3_results_dir:
            return
        raise FileExistsError(f"{workflow.s3_results_dir} has results from a different s3_results_dir")
    config_file.write_text(workflow.model_dump_json(indent=2), encoding="utf-8")


def save_plot(
    *,
    base_dir: Path,
    path_seg: Path,
    file_name: str,
    fig: Figure,
    df: pl.DataFrame,
    output_types: Sequence[Literal["svg", "html", "parquet", "json", "csv"]] | None = None,
    overwrite: bool = False,
) -> None:
    """Persist a plot figure and associated data to disk according to requested types."""
    types = list(output_types or DEFAULT_OUTPUT_TYPES)
    output_dir = base_dir / path_seg
    output_dir.mkdir(parents=True, exist_ok=True)

    file_lock = FileLock(str(output_dir / f"{file_name}.lock"), timeout=15)
    try:
        with file_lock:
            if "html" in types:
                html_path = output_dir / "html" / f"{file_name}.html"
                write_html_file(fig, html_path, overwrite)
            if "svg" in types:
                svg_path = output_dir / "svg" / f"{file_name}.svg"
                write_svg_file(fig, svg_path, overwrite)
            if "parquet" in types:
                parquet_path = output_dir / "data" / f"{file_name}.parquet"
                write_parquet_file(df, parquet_path, overwrite)
            if "json" in types:
                json_path = output_dir / "figure_json" / f"{file_name}.json"
                write_json_file(fig, json_path, overwrite)
            if "csv" in types:
                csv_path = output_dir / "data" / f"{file_name}.csv"
                write_csv_file(df, csv_path, overwrite)
    except TimeoutError:
        print(f"Could not acquire lock to save {file_name}. Skipping save.")


def get_file_path(
    *,
    base_dir: Path,
    path_seg: Path,
    file_name: str,
    file_type: Literal["html", "svg", "parquet", "json", "csv"],
) -> Path:
    """Return the full path for a particular file type under the plot directory."""
    subdir = _file_type_subdir(file_type)
    data_dir = base_dir / path_seg / subdir
    data_dir.mkdir(parents=True, exist_ok=True)
    suffix = "json" if file_type == "json" else file_type
    return data_dir / f"{file_name}.{suffix}"


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------
def write_html_file(fig: Figure, file_path: Path, overwrite: bool) -> None:
    file_path.parent.mkdir(parents=True, exist_ok=True)
    if not overwrite and file_path.exists():
        return
    fig.write_html(
        file_path,
        include_plotlyjs="cdn",
        include_mathjax="cdn",
        config={
            "editable": True,
            "edits": {
                "annotationPosition": True,
                "annotationText": True,
                "axisTitleText": True,
                "legendPosition": True,
                "legendText": True,
                "shapePosition": True,
                "titleText": True,
            },
            "autosizable": True,
            "responsive": True,
            "displaylogo": False,
            "modeBarButtons": [["toImage"], ["zoom2d", "zoomIn2d", "zoomOut2d", "autoScale2d", "resetScale2d"]],
            "toImageButtonOptions": {"format": "svg"},
        },
    )


def write_svg_file(fig: Figure, file_path: Path, overwrite: bool) -> None:
    file_path.parent.mkdir(parents=True, exist_ok=True)
    if not overwrite and file_path.exists():
        return
    fig.write_image(file_path)


def write_parquet_file(df: pl.DataFrame, file_path: Path, overwrite: bool) -> None:
    file_path.parent.mkdir(parents=True, exist_ok=True)
    if not overwrite and file_path.exists():
        return
    df.write_parquet(file_path)


def write_json_file(fig: Figure, file_path: Path, overwrite: bool) -> None:
    file_path.parent.mkdir(parents=True, exist_ok=True)
    if not overwrite and file_path.exists():
        return
    fig.write_json(file_path)


def write_csv_file(df: pl.DataFrame, file_path: Path, overwrite: bool) -> None:
    file_path.parent.mkdir(parents=True, exist_ok=True)
    if not overwrite and file_path.exists():
        return
    df.write_csv(file_path)


def _file_type_subdir(file_type: str) -> str:
    return {
        "html": "html",
        "svg": "svg",
        "parquet": "data",
        "json": "figure_json",
        "csv": "data",
    }[file_type]


def remove_lock_files(output_dir: str | Path) -> None:
    """Delete any leftover file locks within the provided output directory tree."""
    base_path = Path(output_dir).expanduser()
    if not base_path.exists():
        return

    for lock_file in base_path.rglob("*.lock"):
        try:
            lock_file.unlink(missing_ok=True)
        except FileNotFoundError:
            continue
        except OSError as exc:
            print(f"Unable to delete lock file {lock_file}: {exc}")
