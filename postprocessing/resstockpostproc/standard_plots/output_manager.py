import json
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
        self,
        workflow: WorkflowConfig,
        output_types: list[Literal["svg", "html", "parquet", "json", "csv"]] = [],
        overwrite: bool = False,
    ):
        self.base_dir = Path(workflow.output_dir).expanduser().resolve() / "plots" / workflow.run_name
        self.base_dir.mkdir(parents=True, exist_ok=True)
        self.time_spent: defaultdict[Literal["svg", "html", "parquet", "json", "csv"], float] = defaultdict(float)
        if not output_types:  # types needed by the dashboard
            output_types = ["json", "parquet", "html"]
        self.output_types = output_types
        self.overwrite = overwrite
        self.write_workflow_snapshot(workflow)

    def write_workflow_snapshot(self, workflow: WorkflowConfig) -> None:
        """Writes a snapshot of the workflow used to generate the plots to a JSON file."""
        config_file = self.base_dir / "workflow_snapshot.json"
        if config_file.exists():  # never overwrite the snapshot
            with config_file.open("r") as f:
                existing_workflow = json.load(f)
            if existing_workflow["s3_results_dir"] == workflow.s3_results_dir:
                return
            raise FileExistsError(f"{workflow.s3_results_dir} has results from a different s3_results_dir")
        config_file.write_text(workflow.model_dump_json(indent=2), encoding="utf-8")

    def get_output_dir(self, path_seg: Path) -> Path:
        full_path = self.base_dir / path_seg
        full_path.mkdir(parents=True, exist_ok=True)
        return full_path

    def save_plot(self, fig: Figure, path_seg: Path, df: pl.DataFrame, file_name: str) -> None:
        """Save a plot to the output directory with automatic retry."""
        max_retries = 3
        delay_seconds = 3
        # Might collide with generate_plots flow parallelly writing this
        # So retry a few times if it fails
        for attempt in range(max_retries):
            try:
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
                break
            except Exception as e:
                if attempt < max_retries - 1:
                    time.sleep(delay_seconds)
                else:
                    raise e
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
        file_path = html_dir / f"{file_name}.html"
        if not self.overwrite and file_path.exists():
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
        self.time_spent["html"] += time.time() - start_time

    def write_svg(self, fig: Figure, output_dir: Path, file_name: str) -> None:
        start_time = time.time()
        svg_dir = output_dir / "svg"
        svg_dir.mkdir(exist_ok=True)
        file_path = svg_dir / f"{file_name}.svg"
        if not self.overwrite and file_path.exists():
            return
        fig.write_image(file_path)
        self.time_spent["svg"] += time.time() - start_time

    def write_parquet(self, df: pl.DataFrame, output_dir: Path, file_name: str) -> None:
        start_time = time.time()
        data_dir = output_dir / "data"
        data_dir.mkdir(exist_ok=True, parents=True)
        file_path = data_dir / f"{file_name}.parquet"
        if not self.overwrite and file_path.exists():
            return
        df.write_parquet(file_path)
        self.time_spent["parquet"] += time.time() - start_time

    def write_json(self, fig: Figure, output_dir: Path, file_name: str) -> None:
        start_time = time.time()
        fig_dir = output_dir / "figure_json"
        fig_dir.mkdir(exist_ok=True)
        file_path = fig_dir / f"{file_name}.json"
        if not self.overwrite and file_path.exists():
            return
        fig.write_json(file_path)
        self.time_spent["json"] += time.time() - start_time

    def write_csv(self, df: pl.DataFrame, output_dir: Path, file_name: str) -> None:
        start_time = time.time()
        data_dir = output_dir / "data"
        data_dir.mkdir(exist_ok=True, parents=True)
        file_path = data_dir / f"{file_name}.csv"
        if not self.overwrite and file_path.exists():
            return
        df.write_csv(file_path)
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
