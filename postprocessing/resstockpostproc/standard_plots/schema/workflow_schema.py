"""
Configuration schema for plot generation
----------------------------------------
Defines the Pydantic models for validating plot configuration
"""

from __future__ import annotations

import asyncio
import os
import re
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Literal, cast
from uuid import UUID

import yaml
from prefect import State, flow, get_client, get_run_logger, task
from prefect.artifacts import acreate_link_artifact
from prefect.client.schemas.objects import FlowRun
from prefect.deployments import run_deployment
from prefect.runtime import flow_run
from pydantic import BaseModel, Field, ValidationInfo, field_validator
from pydantic_settings import BaseSettings

from resstockpostproc.standard_plots.schema.end_use_dicts import EnduseGroupToEnduses


class NoExtraModel(BaseModel):
    class Config:
        extra = "forbid"
        frozen = True


class NoExtraSettings(BaseSettings):
    class Config:
        extra = "forbid"
        frozen = True


class QuantityType(str, Enum):
    """Different kinds of values to use for plot."""

    absolute = "absolute"  # raw values
    savings = "savings"  # pre-aggregated mean across simulation rows
    percent_savings = "percent_savings"  # percentage savings compared to baseline
    model_count = "model_count"
    prevalence = "prevalence"  # percentage of models with given characteristic


class AggregationType(str, Enum):
    """Different kinds of aggregation to use for plot."""

    total = "total"
    average = "average"
    distribution = "distribution"


class VizType(str, Enum):
    """Supported chart templates."""

    bar = "bar"
    box = "box"
    hist = "histogram"
    heatmap = "heatmap"
    choropleth = "choropleth"


class QuantityGroup(NoExtraModel):
    """Definition of a quantity group with constituents and sum"""

    name: str = Field(description="Name of the quantity group")
    constituents: tuple[str, ...] = Field(description="List of constituent columns")
    sum: str | None = Field(None, description="Column name for the sum quantity")

    @classmethod
    def combine_quantity_groups(cls, quantity_groups: list[QuantityGroup], new_name: str) -> QuantityGroup:
        """
        Combine multiple quantity groups into a single quantity group.

        Args:
            quantity_groups: List of quantity groups to combine
            new_name: Name of the new quantity group

        Returns:
            New quantity group with combined constituents. Sum is set to None.
        """
        constituents = tuple([constituent for qg in quantity_groups for constituent in qg.constituents])
        return cls(name=new_name, constituents=constituents, sum=None)

    @classmethod
    def resolve_quantities(cls, quantities: tuple[str, ...]) -> tuple[str, ...]:
        """
        Resolve the quantities to their constituent columns using EnduseGroupToEnduses.

        Args:
            quantities: List of quantities to resolve, consisting of either the raw column names or quantity group names
                defined in EnduseGroupToEnduses

        Returns:
            List of resolved quantities, which are the raw column names available in the dataset.
        """
        resolvable_quantities: set[str] = set(EnduseGroupToEnduses.keys()).intersection(set(quantities))
        if not resolvable_quantities:
            return tuple(quantities)

        resolved_quantities = [q for q in quantities if q not in resolvable_quantities]
        for quantity in resolvable_quantities:
            resolved_quantities.extend(EnduseGroupToEnduses[quantity])

        return tuple(set(resolved_quantities))


class BuildingInclusion(str, Enum):
    """Different ways to include a quantity in a plot."""

    all = "all"
    applied_only = "applied_only"


class VacancyInclusion(str, Enum):
    """Different ways to include a quantity in a plot."""

    all = "all"
    occupied_only = "occupied_only"


class SelectionLogic(BaseModel):
    """Selection logic for plots based on upgrade apply logic rules"""

    and_: SelectionLogic | list[SelectionLogic | str] | None = Field(None, alias="and")
    or_: SelectionLogic | list[SelectionLogic | str] | None = Field(None, alias="or")
    not_: SelectionLogic | list[SelectionLogic | str] | str | None = Field(None, alias="not")


class WorkflowConfig(NoExtraSettings):
    """Configuration for plot generation"""

    s3_results_dir: str = Field(description="Path to s3 results directory")
    output_dir: str = Field(title="Output Directory", description="Path to output directory")
    run_name: str = Field(description="Name of the run to identify it later")
    upgrades: tuple[int, ...] = Field(description="List of upgrade indices to include")
    upgrade_names: tuple[str, ...] = Field(description="List of upgrade names to include")
    selection_logic: SelectionLogic | list[SelectionLogic] | list[str] | None = Field(
        None, description="Selection logic for"
    )
    quantities: tuple[QuantityGroup, ...] = Field(description="List of quantity groups to generate plots for")
    group_by: tuple[str, ...] = Field(description="List of grouping columns")
    visualization_types: tuple[VizType, ...] = Field(description="List of visualization types to generate")
    quantity_types: tuple[QuantityType, ...] = Field(description="List of quantity types to generate")
    aggregation_types: tuple[AggregationType, ...] = Field(description="List of aggregation types to generate")
    building_inclusion: tuple[BuildingInclusion, ...] = Field(description="Building inclusion type")
    vacancy_inclusion: tuple[VacancyInclusion, ...] = Field(description="Vacancy inclusion type")
    storage_backend: Literal["minio", "filesystem"] = Field(description="Storage backend", default="filesystem")

    def set_s3_results_dir(self, s3_results_dir: str):
        object.__setattr__(self, "s3_results_dir", s3_results_dir)

    def set_output_dir(self, output_dir: str):
        object.__setattr__(self, "output_dir", output_dir)

    def set_run_name(self, run_name: str):
        object.__setattr__(self, "run_name", run_name)

    def set_upgrades(self, upgrades: tuple[int, ...]):
        object.__setattr__(self, "upgrades", upgrades)

    def set_storage_backend(self, storage_backend: Literal["minio", "filesystem"]):
        object.__setattr__(self, "storage_backend", storage_backend)

    def set_upgrade_names(self, upgrade_names: tuple[str, ...]):
        object.__setattr__(self, "upgrade_names", upgrade_names)

    def set_quantities(self, quantities: tuple[QuantityGroup, ...]):
        object.__setattr__(self, "quantities", quantities)

    @classmethod
    def from_yaml(cls, yaml_path: str) -> WorkflowConfig:
        """
        Load configuration from a YAML file

        Args:
            yaml_path: Path to the YAML configuration file

        Returns:
            WorkflowConfig instance
        """
        with open(yaml_path) as f:
            config_data = yaml.safe_load(f)

        if os.environ.get("PLOTS_ROOT_FOLDER"):
            config_data["output_dir"] = os.environ.get("PLOTS_ROOT_FOLDER")
        elif not os.path.isabs(config_data["output_dir"]):
            config_data["output_dir"] = str(Path(yaml_path).parent / config_data["output_dir"])
        return cls(**config_data)

    @field_validator("upgrades")
    @classmethod
    def ensure_zero_in_upgrades(cls, v) -> list[int]:
        """Ensure that upgrade 0 (baseline) is always included and first in the list of upgrades."""
        if v[0] != 0:
            raise ValueError("Upgrade 0 (baseline) must be first in the list of upgrades")
        return v

    @field_validator("upgrade_names")
    @classmethod
    def ensure_upgrade_names(cls, v, info: ValidationInfo) -> list[str]:
        """Verify the number of upgrade names matches the number of upgrades"""
        if len(v) != len(info.data["upgrades"]):
            raise ValueError("Number of upgrade names must match number of upgrades")
        return v

    def add_everything_group(self):
        """Add an "Everything" quantity group to the workflow. This is used by the
        dynamic dashboard to generate plots for all quantities together for diagnostic
        purposes."""
        # Add an "Everything" quantity group if it doesn't exist already
        if not any(q.name == "Everything" for q in self.quantities):
            everything = QuantityGroup.combine_quantity_groups(list(self.quantities), "Everything")
            resolved_quantities = QuantityGroup.resolve_quantities(everything.constituents)
            object.__setattr__(everything, "constituents", resolved_quantities)
            object.__setattr__(self, "quantities", [*self.quantities, everything])


default_config_path = str(Path(__file__).resolve().parents[1] / "workflow.yaml")
default_config = WorkflowConfig.from_yaml(default_config_path)


class FlowConfigBase(BaseModel):
    """Base configuration for plot generation"""

    username: str = Field(
        description="Name to help identify runs that you've initiated", json_schema_extra={"position": 0}
    )
    run_name: str = Field(
        default="Generate Plots",
        description="Name of the run to identify it later",
        json_schema_extra={"position": 1},
    )
    s3_results_dir: str = Field(
        default="s3://res-sdr/testing-sdr-fy25/envelop_package_30k/",
        description="S3 URL to directory containing annual results using the s3:// protocol",
        # Bucket names may only contain lowercase letters, numbers, dots and hyphens,
        # and must start and end with a letter or number. Then at least one "/..." path.
        pattern=r"^s3://[a-z0-9](?:[a-z0-9\-\.]{1,61}[a-z0-9])?/.+",
        json_schema_extra={"position": 2},
    )
    s3_filename_filter: str | None = Field(
        default=None,
        description="Optionally filter S3 files that contain a substring (e.g. 'metadata_and_annual_results')",
        json_schema_extra={"position": 3},
    )


class FlowConfig(FlowConfigBase):
    """Configuration for plot generation"""

    upgrades: tuple[int, ...] = Field(
        default=default_config.upgrades,
        description=WorkflowConfig.model_fields["upgrades"].description,
        json_schema_extra={"position": 4},
    )
    upgrade_names: tuple[str, ...] = Field(
        default=default_config.upgrade_names,
        description=WorkflowConfig.model_fields["upgrade_names"].description,
        json_schema_extra={"position": 5},
    )


class AdvancedConfig(BaseModel):
    group_by: tuple[str, ...] = Field(default=default_config.group_by, description="List of grouping columns")


async def _execute_plot_flow(
    workflow: WorkflowConfig,
    username: str,
    s3_results_dir: str,
    s3_filename_filter: str | None,
) -> None:
    logger = get_run_logger()

    workflow.set_run_name(f"{flow_run.get_name()}")
    workflow.set_s3_results_dir(s3_results_dir)
    workflow.set_storage_backend("minio")

    run_id = cast(UUID, flow_run.get_id())
    async with get_client() as client:
        await client.update_flow_run(flow_run_id=run_id, tags=[username])

    logger.info(f"Workflow Configuration:\n{workflow.model_dump_json(indent=2)}")

    await run_deployment(
        name="Sync S3 to MinIO/Sync S3 to MinIO",
        parameters={"s3_url": workflow.s3_results_dir, "filename_filter": s3_filename_filter},
    )

    try:
        run_orchestrator(workflow, output_types=["csv", "html", "json", "parquet"])
    except Exception as e:
        logger.error(f"Error running orchestrator: {e}")
        raise

    await acreate_link_artifact(
        key="dashboard",
        link="http://bball-130449.nrel.gov:8050/",
        description="Plot dashboard",
    )


def crash_handler(flow, flow_run: FlowRun, state: State):  # noqa: ARG001
    print(f"💥 Flow {flow_run.name!r} crashed with state {state!r}")


def check_s3_results_dir(s3_results_dir: str):
    """Ensure that "pub_annual" is selected rather than the root"""
    pattern = r"^s3://res-sdr/testing-sdr-fy25/([^/]+)/?$"
    match = re.match(pattern, s3_results_dir)
    if match:
        dir_name = match.group(1)
        return f"s3://res-sdr/testing-sdr-fy25/{dir_name}/pub_annual/"
    return s3_results_dir


def flow_run_name() -> str:
    return (
        f"[{flow_run.parameters['config'].username}] {flow_run.parameters['config'].run_name} "
        f"({datetime.now().isoformat(timespec='seconds').replace(':', '-')})"
    )


@flow(
    name="Generate Plots",
    flow_run_name=flow_run_name,
    log_prints=True,
    on_crashed=[crash_handler],
)
async def generate_plots(
    config: FlowConfig,
    advanced_config: AdvancedConfig = AdvancedConfig(),
):
    update = {
        "group_by": advanced_config.group_by,
        "upgrades": config.upgrades,
        "upgrade_names": config.upgrade_names,
    }
    workflow = default_config.model_copy(update=update, deep=True)

    await _execute_plot_flow(
        workflow,
        username=config.username,
        s3_results_dir=config.s3_results_dir,
        s3_filename_filter=config.s3_filename_filter,
    )


@flow(
    name="Generate Plots",
    flow_run_name=flow_run_name,
    log_prints=True,
    on_crashed=[crash_handler],
)
async def generate_plots_full_schema(
    config: FlowConfigBase,
    workflow: WorkflowConfig = WorkflowConfig(**default_config.model_dump()),
):
    await _execute_plot_flow(
        workflow,
        username=config.username,
        s3_results_dir=config.s3_results_dir,
        s3_filename_filter=config.s3_filename_filter,
    )


@task(
    name="Run Orchestrator",
    task_run_name="Run Orchestrator",
)
def run_orchestrator(
    workflow: WorkflowConfig,
    output_types: list[Literal["csv", "html", "json", "parquet", "svg"]],
):
    from resstockpostproc.standard_plots.all_plots_generator import generate_all_plots  # noqa: PLC0415

    generate_all_plots(workflow.model_dump(), output_types=output_types, print_stats=True)


if __name__ == "__main__":

    async def main():
        await generate_plots(
            FlowConfig(
                username="alex",
                run_name="Test Run",
                s3_results_dir="s3://res-sdr/testing-sdr-fy25/envelop_package_30k/",
            ),
            AdvancedConfig(group_by=["in.vintage"]),
        )

        # await generate_plots_full_schema(
        #     FlowConfigBase(
        #         username="alex",
        #         run_name="Test Run",
        #         s3_results_dir="s3://res-sdr/testing-sdr-fy25/envelop_package_30k/",
        #     ),
        #     WorkflowConfig(**{**default_config.model_dump(), "group_by": ["in.vintage"]})
        # )

    asyncio.run(main())
