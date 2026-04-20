"""Functions for saving plots and data."""

import hashlib
import re
from functools import lru_cache
from pathlib import Path
from typing import Literal

import plotly.graph_objects as go
import plotly.io as pio
import polars as pl
from plotly.offline import get_plotlyjs

from resstockpostproc.baseline_validation.dashboard_paths import dashboard_output_root, dataset_output_dir
from resstockpostproc.baseline_validation.schema.plot_spec import PlotSpec, FileType
from resstockpostproc.baseline_validation.utils import ensure_directory
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow
from resstockpostproc.baseline_validation.io_managers.html_utils import postprocess_plot_html
from resstockpostproc.shared_utils.timing import timed


FIGURE_FORMATS = {FileType.html, FileType.svg, FileType.pdf}
STATIC_IMAGE_FORMATS = {FileType.svg, FileType.pdf}

# Plotly HTML config: editable titles/labels + custom download buttons
# Use granular "edits" instead of blanket "editable: True" so shapes stay non-interactive
PLOTLY_HTML_CONFIG: dict = {
    "edits": {
        "annotationPosition": False,
        "annotationText": True,
        "axisTitleText": True,
        "legendPosition": True,
        "legendText": False,
        "shapePosition": False,
        "titleText": True,
    },
    "modeBarButtonsToRemove": ["toImage"],
}


@lru_cache(maxsize=1)
def _plotly_bundle() -> tuple[str, str]:
    """Return the installed Plotly.js bundle version and source."""
    js = get_plotlyjs()
    match = re.search(r"plotly\.js v([0-9][^ \n*]+)", js)
    if not match:
        raise ValueError("Could not determine bundled plotly.js version.")
    return match.group(1), js


def plotly_asset_filename() -> str:
    """Return the vendored filename for the installed Plotly.js bundle."""
    version, _ = _plotly_bundle()
    return f"plotly-{version}.min.js"


def plotly_cdn_url() -> str:
    """Return the CDN URL matching the installed Plotly.js bundle."""
    version, _ = _plotly_bundle()
    return f"https://cdn.plot.ly/plotly-{version}.min.js"


def ensure_plotly_asset(asset_dir: Path) -> Path:
    """Write the installed Plotly.js bundle into the dashboard asset directory."""
    _, js = _plotly_bundle()
    ensure_directory(asset_dir)
    asset_path = asset_dir / plotly_asset_filename()
    asset_path.write_text(js, encoding="utf-8")
    return asset_path


def _figure_dimensions(fig: go.Figure) -> tuple[int, int]:
    """Return export dimensions for a figure."""
    width = int(fig.layout.width) if fig.layout.width else 1950
    height = int(fig.layout.height) if fig.layout.height else 1100
    return width, height


def _figure_output_path(output_root: Path, plot_spec: PlotSpec, fmt: FileType) -> Path:
    """Resolve the per-plot output file path and ensure its parent directory exists."""
    output_dir = dataset_output_dir(output_root, str(plot_spec.comparison_dataset), "plots", fmt.value)
    path_seg, title = plot_spec.file_path_and_name
    filepath = output_dir / path_seg
    ensure_directory(filepath)
    return filepath / f"{title}.{fmt.value}"


def _write_static_image(fig: go.Figure, fullpath: Path) -> None:
    """Write one static image with Plotly/Kaleido."""
    width, height = _figure_dimensions(fig)
    fig.write_image(fullpath, width=width, height=height, scale=2)


@timed
def save_static_images_batch(
    jobs: list[tuple[go.Figure, PlotSpec, FileType]],
    output_root: Path | None = None,
) -> None:
    """Write multiple static images in a single Kaleido batch when possible."""
    if not jobs:
        return

    output_root = output_root or dashboard_output_root(workflow)
    normalized_jobs: list[tuple[go.Figure, Path, str, int, int]] = []
    for fig, plot_spec, fmt in jobs:
        fullpath = _figure_output_path(output_root, plot_spec, fmt)
        width, height = _figure_dimensions(fig)
        normalized_jobs.append((fig, fullpath, fmt.value, width, height))

    try:
        pio.write_images(
            fig=[fig for fig, _, _, _, _ in normalized_jobs],
            file=[fullpath for _, fullpath, _, _, _ in normalized_jobs],
            format=[fmt for _, _, fmt, _, _ in normalized_jobs],
            width=[width for _, _, _, width, _ in normalized_jobs],
            height=[height for _, _, _, _, height in normalized_jobs],
            scale=[2] * len(normalized_jobs),
            validate=True,
        )
    except Exception:
        for fig, fullpath, _, _, _ in normalized_jobs:
            _write_static_image(fig, fullpath)

    for _, fullpath, _, _, _ in normalized_jobs:
        print(f"Saved: {fullpath.parent}")


@timed
def save_figure(
    fig: go.Figure,
    plot_spec: PlotSpec,
    formats: list[FileType] = [FileType.html],
    footnotes: list[str] | None = None,
    source_labels: dict | None = None,
    output_root: Path | None = None,
    plotly_asset_path: Path | None = None,
) -> None:
    """Save a Plotly figure in multiple formats."""
    output_root = output_root or dashboard_output_root(workflow)

    for fmt in formats:
        if fmt not in FIGURE_FORMATS:
            continue
        fullpath = _figure_output_path(output_root, plot_spec, fmt)
        if fmt == FileType.html:
            raw_path = fullpath.with_name(f"{fullpath.stem}.raw{fullpath.suffix}")
            div_id = "fig-" + hashlib.md5(str(fullpath).encode()).hexdigest()
            fig.write_html(raw_path, include_plotlyjs="cdn", config=PLOTLY_HTML_CONFIG, div_id=div_id)
            postprocess_plot_html(
                raw_path,
                output_path=fullpath,
                footnotes=footnotes,
                source_labels=source_labels,
                comparison_dataset=plot_spec.comparison_dataset.value,
                plotly_cdn_src=plotly_cdn_url(),
                plotly_asset_path=plotly_asset_path,
            )
        else:
            _write_static_image(fig, fullpath)
        print(f"Saved: {fullpath.parent}")


@timed
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
