from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from resstockpostproc.standard_plots.orchestrator import PlotOrchestrator
from resstockpostproc.standard_plots.schema.workflow_schema import QuantityGroup, WorkflowConfig


@dataclass
class RunContext:
    """Holds workflow configuration and orchestrator cache for the dashboard."""

    workflow_yaml: Path
    workflow: WorkflowConfig
    plots_dir: Path
    quantity_groups: dict[str, QuantityGroup]
    plots_root_folder: str | None = None
    _orchestrators: dict[str, PlotOrchestrator] = field(default_factory=dict)

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

    def get_orchestrator(self, run_folder: str) -> PlotOrchestrator | None:
        """Return a cached PlotOrchestrator instance for the run folder."""
        if run_folder in self._orchestrators:
            return self._orchestrators[run_folder]

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

        self._orchestrators[run_folder] = PlotOrchestrator(workflow, overwrite=False)
        return self._orchestrators[run_folder]

