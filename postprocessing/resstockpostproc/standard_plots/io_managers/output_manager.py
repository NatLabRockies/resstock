"""
Functional helpers for saving plot outputs and metadata.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Iterable, Literal, Sequence

import polars as pl
from filelock import FileLock
from plotly.graph_objects import Figure

from resstockpostproc.standard_plots.schema.workflow_schema import WorkflowConfig

DEFAULT_OUTPUT_TYPES = ["json", "parquet", "html"]

__all__ = [
    "get_plot_base_dir",
    "write_workflow_snapshot",
    "save_plot",
    "get_file_path",
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
                _write_html(fig, output_dir, file_name, overwrite)
            if "svg" in types:
                _write_svg(fig, output_dir, file_name, overwrite)
            if "parquet" in types:
                _write_parquet(df, output_dir, file_name, overwrite)
            if "json" in types:
                _write_json(fig, output_dir, file_name, overwrite)
            if "csv" in types:
                _write_csv(df, output_dir, file_name, overwrite)
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
def _write_html(fig: Figure, output_dir: Path, file_name: str, overwrite: bool) -> None:
    html_dir = output_dir / "html"
    html_dir.mkdir(exist_ok=True)
    file_path = html_dir / f"{file_name}.html"
    if not overwrite and file_path.exists():
        return
    fig.write_html(
        file_path,
        include_plotlyjs="cdn",
        include_mathjax="cdn",
        config={
            "editable": True,
            "autosizable": True,
            "responsive": True,
            "displaylogo": False,
            "modeBarButtons": [["toImage"], ["zoom2d", "zoomIn2d", "zoomOut2d", "autoScale2d", "resetScale2d"]],
        },
    )


def _write_svg(fig: Figure, output_dir: Path, file_name: str, overwrite: bool) -> None:
    svg_dir = output_dir / "svg"
    svg_dir.mkdir(exist_ok=True)
    file_path = svg_dir / f"{file_name}.svg"
    if not overwrite and file_path.exists():
        return
    fig.write_image(file_path)


def _write_parquet(df: pl.DataFrame, output_dir: Path, file_name: str, overwrite: bool) -> None:
    data_dir = output_dir / "data"
    data_dir.mkdir(parents=True, exist_ok=True)
    file_path = data_dir / f"{file_name}.parquet"
    if not overwrite and file_path.exists():
        return
    df.write_parquet(file_path)


def _write_json(fig: Figure, output_dir: Path, file_name: str, overwrite: bool) -> None:
    fig_dir = output_dir / "figure_json"
    fig_dir.mkdir(exist_ok=True)
    file_path = fig_dir / f"{file_name}.json"
    if not overwrite and file_path.exists():
        return
    fig.write_json(file_path)


def _write_csv(df: pl.DataFrame, output_dir: Path, file_name: str, overwrite: bool) -> None:
    data_dir = output_dir / "data"
    data_dir.mkdir(parents=True, exist_ok=True)
    file_path = data_dir / f"{file_name}.csv"
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
