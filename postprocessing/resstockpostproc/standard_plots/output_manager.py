import time
from collections import defaultdict
from pathlib import Path
from typing import Literal

import polars as pl
from plotly.graph_objects import Figure
from resstockpostproc.standard_plots.schema.workflow_schema import WorkflowConfig

# Lazy import to avoid circulars

__all__ = ["OutputManager"]


class OutputManager:
    """Creates/returns output directory paths for absolute & savings plots.

    The class guarantees that all directories exist on instantiation, so the
    rest of the codebase can assume they are present.
    """

    def __init__(
        self, workflow: WorkflowConfig, output_types: list[Literal["svg", "html", "parquet", "json", "csv"]] = []
    ):
        self.base_dir = Path(workflow.output_dir).expanduser().resolve() / "plots" / workflow.run_name
        self.base_dir.mkdir(parents=True, exist_ok=True)
        self.time_spent: defaultdict[Literal["svg", "html", "parquet", "json", "csv"], float] = defaultdict(float)
        if not output_types:  # types needed by the dashboard
            output_types = ["json", "parquet", "html"]
        self.output_types = output_types
        self.write_workflow_snapshot(workflow)

    def write_workflow_snapshot(self, workflow: WorkflowConfig) -> None:
        """Writes a snapshot of the workflow used to generate the plots to a JSON file."""
        config_dir = self.base_dir / "workflow_snapshot.json"
        config_dir.write_text(workflow.model_dump_json(indent=2), encoding="utf-8")

    def get_output_dir(self, path_seg: Path) -> Path:
        full_path = self.base_dir / path_seg
        full_path.mkdir(parents=True, exist_ok=True)
        return full_path

    def save_plot(self, fig: Figure, path_seg: Path, df: pl.DataFrame, file_name: str) -> None:
        """Save a plot to the output directory."""
        output_dir = self.get_output_dir(path_seg)
        # Write files to their respective directories
        if "html" in self.output_types:
            self.write_html(fig, output_dir, file_name)
        if "svg" in self.output_types:
            self.write_svg(fig, output_dir, file_name)
        if "parquet" in self.output_types:
            self.write_parquet(df, output_dir, file_name)
        if "json" in self.output_types:
            self.write_json(fig, output_dir, file_name)
        if "csv" in self.output_types:
            self.write_csv(df, output_dir, file_name)

    def write_html(self, fig: Figure, output_dir: Path, file_name: str) -> None:
        start_time = time.time()
        html_dir = output_dir / "html"
        html_dir.mkdir(exist_ok=True)
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
        self.time_spent["html"] += time.time() - start_time

    def write_svg(self, fig: Figure, output_dir: Path, file_name: str) -> None:
        start_time = time.time()
        svg_dir = output_dir / "svg"
        svg_dir.mkdir(exist_ok=True)
        fig.write_image(svg_dir / f"{file_name}.svg")
        self.time_spent["svg"] += time.time() - start_time

    def write_parquet(self, df: pl.DataFrame, output_dir: Path, file_name: str) -> None:
        start_time = time.time()
        data_dir = output_dir / "data"
        data_dir.mkdir(exist_ok=True, parents=True)
        df.write_parquet(data_dir / f"{file_name}.parquet")
        self.time_spent["parquet"] += time.time() - start_time

    def write_json(self, fig: Figure, output_dir: Path, file_name: str) -> None:
        start_time = time.time()
        fig_dir = output_dir / "figure_json"
        fig_dir.mkdir(exist_ok=True)
        fig.write_json(fig_dir / f"{file_name}.json")
        self.time_spent["json"] += time.time() - start_time

    def write_csv(self, df: pl.DataFrame, output_dir: Path, file_name: str) -> None:
        start_time = time.time()
        data_dir = output_dir / "data"
        data_dir.mkdir(exist_ok=True, parents=True)
        df.write_csv(data_dir / f"{file_name}.csv")
        self.time_spent["csv"] += time.time() - start_time

    def get_file_path(
        self, path_seg: Path, file_name: str, file_type: Literal["html", "svg", "parquet", "json", "csv"]
    ) -> Path:
        data_dir = self.base_dir / path_seg / file_type
        data_dir.mkdir(exist_ok=True, parents=True)
        return data_dir / f"{file_name}.{file_type}"

    def print_time_spent(self) -> None:
        for file_type, time_spent in self.time_spent.items():
            if time_spent > 0:
                print(f"Time spent saving {file_type}: {time_spent:.2f} seconds")
