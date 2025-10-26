from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import polars as pl  # type: ignore

from resstockpostproc.standard_plots.io_managers.input_manager import download_data, load_data
from resstockpostproc.standard_plots.schema.workflow_schema import QuantityGroup, WorkflowConfig


@dataclass
class RunContext:
    """Holds workflow configuration and caches for the dashboard."""

    workflow_yaml: Path
    workflow: WorkflowConfig
    plots_dir: Path
    quantity_groups: dict[str, QuantityGroup]
    plots_root_folder: str | None = None
    _workflows: dict[str, WorkflowConfig] = field(default_factory=dict)
    _combined_frames: dict[str, pl.LazyFrame] = field(default_factory=dict)
    _categorical_columns: dict[tuple[str, int], list[str]] = field(default_factory=dict)
    _quantity_categories: dict[tuple[str, int, str], list[str]] = field(default_factory=dict)
    _downloaded_runs: set[str] = field(default_factory=set)

    @classmethod
    def from_environment(cls, workflow_yaml: Path, plots_root_folder: str | None = None) -> RunContext:
        """Construct the context by loading the base workflow and applying overrides."""
        workflow = WorkflowConfig.from_yaml(str(workflow_yaml))
        workflow.add_everything_group()

        if plots_root_folder:
            workflow.set_output_dir(plots_root_folder)
            workflow.set_storage_backend("minio")

        plots_dir = Path(workflow.output_dir).expanduser().resolve() / "plots"
        quantity_groups = {group.name: group for group in workflow.numerical_quantities}

        return cls(
            workflow_yaml=workflow_yaml,
            workflow=workflow,
            plots_dir=plots_dir,
            quantity_groups=quantity_groups,
            plots_root_folder=plots_root_folder,
        )

    def list_run_folders(self) -> list[str]:
        """Return the available run folders on disk."""
        if not self.plots_dir.exists():
            return []
        return sorted([path.name for path in self.plots_dir.iterdir() if path.is_dir()])

    def load_snapshot(self, run_folder: str) -> dict[str, Any] | None:
        """Load the workflow snapshot for a run folder, if present."""
        snapshot_path = self.plots_dir / run_folder / "workflow_snapshot.json"
        if not snapshot_path.exists():
            return None

        with snapshot_path.open() as fh:
            return json.load(fh)

    def _get_workflow(self, run_folder: str) -> WorkflowConfig | None:
        if run_folder in self._workflows:
            return self._workflows[run_folder]
        snapshot = self.load_snapshot(run_folder)
        if snapshot is None:
            return None

        workflow = WorkflowConfig.from_yaml(str(self.workflow_yaml))
        workflow.set_run_name(run_folder)
        workflow.add_everything_group()
        workflow.set_s3_results_dir(snapshot["s3_results_dir"])
        workflow.set_upgrades(snapshot["upgrades"])
        workflow.set_upgrade_names(snapshot["upgrade_names"])

        if self.plots_root_folder:
            workflow.set_output_dir(self.plots_root_folder)
            workflow.set_storage_backend("minio")

        self._workflows[run_folder] = workflow
        return workflow

    def _ensure_data_ready(self, run_folder: str) -> WorkflowConfig | None:
        workflow = self._get_workflow(run_folder)
        if workflow is None:
            return None
        if run_folder not in self._downloaded_runs:
            download_data(workflow)
            self._downloaded_runs.add(run_folder)
        return workflow

    def ensure_data_ready(self, run_folder: str) -> WorkflowConfig | None:
        """Ensure the workflow is prepared and data downloaded for the run."""
        return self._ensure_data_ready(run_folder)

    def get_workflow(self, run_folder: str) -> WorkflowConfig | None:
        """Return the WorkflowConfig associated with a run folder."""
        return self._get_workflow(run_folder)

    def get_combined_frame(self, run_folder: str) -> pl.LazyFrame | None:
        """Return cached combined LazyFrame for the run folder."""
        if run_folder in self._combined_frames:
            return self._combined_frames[run_folder]

        workflow = self._ensure_data_ready(run_folder)
        if workflow is None:
            return None

        combined_df = load_data(workflow)
        self._combined_frames[run_folder] = combined_df
        return combined_df

    def list_categorical_quantities(self, run_folder: str, upgrade: int) -> list[str]:
        """Return cached list of categorical columns suitable for prevalence plots."""
        if (run_folder, upgrade) in self._categorical_columns:
            return self._categorical_columns[(run_folder, upgrade)]

        workflow = self._ensure_data_ready(run_folder)
        if workflow is None:
            return []

        data = load_data(workflow, [upgrade])
        schema = data.collect_schema()

        excluded_columns = {
            "upgrade",
            "upgrade_name",
            "bldg_id",
            "weight",
        }

        candidate_cols = [
            name
            for name, dtype in schema.items()
            if name not in excluded_columns and not dtype.is_numeric()
        ]

        if not candidate_cols:
            self._categorical_columns[(run_folder, upgrade)] = []
            return []

        uniques = data.select([pl.col(col).n_unique().alias(col) for col in candidate_cols]).collect().row(0)

        categorical_cols = [
            col for col, count in zip(candidate_cols, uniques) if isinstance(count, int | float) and 1 <= count <= 100
        ]
        categorical_cols.sort()

        self._categorical_columns[(run_folder, upgrade)] = categorical_cols
        return categorical_cols

    def list_quantity_categories(self, run_folder: str, upgrade: int, column: str) -> list[str]:
        """Return cached list of category values for the requested column."""
        cache_key = (run_folder, upgrade, column)
        if self._quantity_categories.get(cache_key):
            return self._quantity_categories[cache_key]

        workflow = self._ensure_data_ready(run_folder)
        if workflow is None:
            return []

        data = load_data(workflow, [upgrade])
        try:
            categories_df = data.select(pl.col(column)).drop_nulls().unique(maintain_order=True).collect()
            categories = categories_df[column].to_list()
        except Exception:
            categories = []

        categories = [str(cat) for cat in categories if cat is not None][:100]
        self._quantity_categories[cache_key] = categories
        return categories
