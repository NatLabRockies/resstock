from __future__ import annotations

from pathlib import Path
import time
from plotly.graph_objects import Figure
import polars as pl

# Lazy import to avoid circulars

__all__ = ["OutputManager"]


class OutputManager:
    """Creates/returns output directory paths for absolute & savings plots.

    The class guarantees that all directories exist on instantiation, so the
    rest of the codebase can assume they are present.
    """

    def __init__(self, base_output_dir: str | Path, should_save_image: bool = False, should_save_data: bool = False):
        self.base_dir = Path(base_output_dir).expanduser().resolve()
        self.svg_time_spent: float = 0
        self.html_time_spent: float = 0
        self.data_time_spent: float = 0
        self.should_save_image = should_save_image
        self.should_save_data = should_save_data

    def get_output_dir(self, path_seg: Path) -> Path:
        full_path = self.base_dir / path_seg
        full_path.mkdir(parents=True, exist_ok=True)
        return full_path

    def save_plot(self, fig: Figure, path_seg: Path, df: pl.DataFrame, file_name: str) -> None:
        """Save a plot to the output directory."""
        output_dir = self.get_output_dir(path_seg)

        # Create separate directories for HTML and SVG outputs
        html_dir = output_dir / "html"
        html_dir.mkdir(exist_ok=True)

        # Write files to their respective directories
        start_time = time.time()
        fig.write_html(
            html_dir / f"{file_name}.html",
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
        self.html_time_spent += time.time() - start_time

        if self.should_save_image:
            svg_dir = output_dir / "svg"
            svg_dir.mkdir(exist_ok=True)
            start_time = time.time()
            fig.write_image(svg_dir / f"{file_name}.svg")
            self.svg_time_spent += time.time() - start_time

        if self.should_save_data:
            data_dir = output_dir / "data"
            start_time = time.time()
            self.save_data(data_dir, df, file_name)
            self.data_time_spent += time.time() - start_time

    def save_data(self, data_dir: Path, df: pl.DataFrame, file_name: str) -> None:
        data_dir.mkdir(exist_ok=True)
        data_file = data_dir / f"{file_name}.parquet"
        df.write_parquet(data_file)

    def print_time_spent(self) -> None:
        if self.should_save_image:
            print(f"Time spent saving SVGs: {self.svg_time_spent:.2f} seconds")
        if self.should_save_data:
            print(f"Time spent saving data: {self.data_time_spent:.2f} seconds")
        print(f"Time spent saving HTMLs: {self.html_time_spent:.2f} seconds")
