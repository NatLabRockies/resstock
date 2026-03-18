"""Functions for saving plots and data."""

from pathlib import Path
from typing import Literal

import plotly.graph_objects as go
import polars as pl

from resstockpostproc.baseline_validation.schema.plot_spec import PlotSpec, FileType
from resstockpostproc.baseline_validation.utils import ensure_directory
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow
from resstockpostproc.shared_utils.timing import timed


FIGURE_FORMATS = {FileType.html, FileType.svg, FileType.pdf}


@timed
def save_figure(
    fig: go.Figure,
    plot_spec: PlotSpec,
    formats: list[FileType] = [FileType.html],
) -> None:
    """Save a Plotly figure in multiple formats."""

    for fmt in formats:
        if fmt not in FIGURE_FORMATS:
            continue
        output_dir = workflow.output.output_dir / workflow.output.run_name / f"{plot_spec.truth_source} plots ({fmt})"
        path_seg, title = plot_spec.get_file_path_and_name()
        filepath = output_dir / path_seg
        ensure_directory(filepath)
        fullpath = filepath / f"{title}.{fmt.value}"
        if fmt == FileType.html:
            fig.write_html(fullpath, include_plotlyjs="cdn")
        else:
            # For PDF/SVG, use larger scale and ensure proper dimensions
            # Get dimensions from figure layout, or use defaults
            width = fig.layout.width if fig.layout.width else 1950
            height = fig.layout.height if fig.layout.height else 1100

            # Use scale=2 for better quality and proper sizing
            fig.write_image(fullpath, width=width, height=height, scale=2)
        print(f"Saved: {filepath}")


def save_dataframe(
    df: pl.DataFrame,
    output_dir: Path,
    filename: str,
    formats: tuple[Literal["parquet", "csv"], ...] = ("parquet",),
) -> None:
    """Save a Polars DataFrame in multiple formats."""
    data_dir = ensure_directory(output_dir / "data")

    for fmt in formats:
        filepath = data_dir / f"{filename}.{fmt}"

        if fmt == "parquet":
            df.write_parquet(filepath)
        elif fmt == "csv":
            df.write_csv(filepath)

        print(f"Saved: {filepath}")
