from __future__ import annotations

import os
from pathlib import Path
from typing import Tuple
from plotly.graph_objects import Figure

# Lazy import to avoid circulars
from resstockpostproc.standard_plots.schema.plot_spec import PlotSpec

__all__ = ["OutputManager"]


class OutputManager:
    """Creates/returns output directory paths for absolute & savings plots.

    The class guarantees that all directories exist on instantiation, so the
    rest of the codebase can assume they are present.
    """

    def __init__(self, base_output_dir: str | Path):
        self.base_dir = Path(base_output_dir).expanduser().resolve()

    def get_output_dir(self, path_seg: Path) -> Path:
        full_path = self.base_dir / path_seg
        full_path.mkdir(parents=True, exist_ok=True)
        return full_path
    
    def save_plot(self, fig: Figure, path_seg: Path) -> None:
        """Save a plot to the output directory."""
        output_dir = self.get_output_dir(path_seg)

        # Create separate directories for HTML and SVG outputs
        html_dir = output_dir / "html"
        svg_dir = output_dir / "svg"
        html_dir.mkdir(exist_ok=True)
        svg_dir.mkdir(exist_ok=True)
        
        # Write files to their respective directories
        fig.write_html(html_dir / "plot.html")
        fig.write_image(svg_dir / "plot.svg")