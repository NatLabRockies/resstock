from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import polars as pl  # type: ignore

from resstockpostproc.standard_plots.input_manager import InputManager
from resstockpostproc.standard_plots.schema.workflow_schema import QuantityGroup, WorkflowConfig


@dataclass
class RunContext:
    """Holds workflow configuration and caches for the dashboard."""

    workflow_yaml: Path
    workflow: WorkflowConfig
    plots_dir: Path
    quantity_groups: dict[str, QuantityGroup]
    plots_root_folder: str | None = None
    _input_managers: dict[str, InputManager] = field(default_factory=dict)
    _workflows: dict[str, WorkflowConfig] = field(default_factory=dict)
    _combined_frames: dict[str, pl.LazyFrame] = field(default_factory=dict)
    _categorical_columns: dict[tuple[str, int], list[str]] = field(default_factory=dict)
    _quantity_categories: dict[tuple[str, int, str], list[str]] = field(default_factory=dict)

    @classmethod
    def from_environment(cls, workflow_yaml: Path, plots_root_folder: str | None = None) -> "RunContext":
        """Construct the context by loading the base workflow and applying overrides."""
        workflow = WorkflowConfig.from_yaml(str(workflow_yaml))
        workflow.add_everything_group()

        if plots_root_folder:
            workflow.set_output_dir(plots_root_folder)
            workflow.set_storage_backend("minio")

        plots_dir = Path(workflow.output_dir).expanduser().resolve() / "plots"
        quantity_groups = {group.name: group for group in workflow.quantities}

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

    def get_input_manager(self, run_folder: str) -> InputManager | None:
        """Return a cached InputManager instance for the run folder."""
        if run_folder in self._input_managers:
            return self._input_managers[run_folder]

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

        input_manager = InputManager(workflow)
        input_manager.download_data()
        self._input_managers[run_folder] = input_manager
        self._workflows[run_folder] = workflow
        return input_manager

    def get_workflow(self, run_folder: str) -> WorkflowConfig | None:
        """Return the WorkflowConfig associated with a run folder."""
        if run_folder not in self._workflows:
            self.get_input_manager(run_folder)
        return self._workflows.get(run_folder)

    def get_combined_frame(self, run_folder: str) -> pl.LazyFrame | None:
        """Return cached combined LazyFrame for the run folder."""
        if run_folder in self._combined_frames:
            return self._combined_frames[run_folder]

        input_manager = self.get_input_manager(run_folder)
        if input_manager is None:
            return None

        combined_df = input_manager.load_data()
        self._combined_frames[run_folder] = combined_df
        return combined_df

    def list_categorical_quantities(self, run_folder: str, upgrade: int) -> list[str]:
        """Return cached list of categorical columns suitable for prevalence plots."""
        if (run_folder, upgrade) in self._categorical_columns:
            return self._categorical_columns[(run_folder, upgrade)]

        input_manager = self.get_input_manager(run_folder)
        if input_manager is None:
            return []

        data = input_manager.load_data([upgrade])
        schema = data.collect_schema()

        def _is_numeric(dtype: pl.DataType) -> bool:
            return (
                dtype.is_numeric()
                if hasattr(dtype, "is_numeric")
                else pl.datatypes.is_numeric_dtype(dtype)
            )

        excluded_columns = {
            "upgrade",
            "upgrade_name",
            "bldg_id",
            "weight",
            "applicability",
        }

        candidate_cols = [
            name
            for name, dtype in schema.items()
            if name not in excluded_columns
            and not _is_numeric(dtype)
            # and dtype != pl.Boolean
        ]

        if not candidate_cols:
            self._categorical_columns[(run_folder, upgrade)] = []
            return []

        uniques = (
            data.select([pl.col(col).n_unique().alias(col) for col in candidate_cols])
            .collect()
            .row(0)
        )

        categorical_cols = [
            col
            for col, count in zip(candidate_cols, uniques)
            if isinstance(count, (int, float)) and 1 < count <= 100
        ]
        categorical_cols.sort()

        self._categorical_columns[(run_folder, upgrade)] = categorical_cols
        return categorical_cols

    def list_quantity_categories(self, run_folder: str, upgrade: int, column: str) -> list[str]:
        """Return cached list of category values for the requested column."""
        cache_key = (run_folder, upgrade, column)
        if cache_key in self._quantity_categories and self._quantity_categories[cache_key]:
            return self._quantity_categories[cache_key]

        input_manager = self.get_input_manager(run_folder)
        if input_manager is None:
            return []

        data = input_manager.load_data([upgrade])
        try:
            categories_df = (
                data.select(pl.col(column))
                .drop_nulls()
                .unique(maintain_order=True)
                .collect()
            )
            categories = categories_df[column].to_list()
        except Exception:
            categories = []

        categories = [str(cat) for cat in categories if cat is not None][:100]
        self._quantity_categories[cache_key] = categories
        return categories
