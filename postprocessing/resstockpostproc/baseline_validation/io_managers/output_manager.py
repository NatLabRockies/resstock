"""Functions for saving plots and data."""

from pathlib import Path
from typing import Literal

import plotly.graph_objects as go
import polars as pl

from resstockpostproc.baseline_validation.utils import ensure_directory


def save_figure(
    fig: go.Figure,
    output_dir: Path,
    filename: str,
    formats: tuple[Literal["html", "svg", "json"], ...] = ("html", "svg"),
) -> None:
    """Save a Plotly figure in multiple formats."""
    for fmt in formats:
        format_dir = ensure_directory(output_dir / fmt)
        filepath = format_dir / f"{filename}.{fmt}"

        if fmt == "html":
            fig.write_html(str(filepath), include_plotlyjs="cdn")
        elif fmt == "svg":
            fig.write_image(str(filepath))
        elif fmt == "json":
            fig.write_json(str(filepath))

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
