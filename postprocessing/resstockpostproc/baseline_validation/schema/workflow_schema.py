"""
Configuration schema for baseline validation
--------------------------------------------
Defines Pydantic models for validating baseline validation workflow configuration
"""

from __future__ import annotations

from enum import Enum
from pathlib import Path
from typing import Literal

import yaml
from pydantic import Field, field_validator

from resstockpostproc.baseline_validation.schema.plot_spec import NoExtraModel


class PlotType(str, Enum):
    """Types of validation plots to generate."""

    eia = "eia"
    lrd = "load_duration"
    timeseries = "timeseries"


class AggregationLevel(str, Enum):
    """Geographic aggregation levels for validation."""

    state = "state"
    eiaid = "eiaid"


class OutputFormat(str, Enum):
    """Supported output formats."""

    html = "html"
    svg = "svg"
    json = "json"
    parquet = "parquet"
    csv = "csv"


class DataSourceConfig(NoExtraModel):
    """Configuration for BuildStock data source."""
    name: str = Field(description="Name for this data source")
    db_name: str = Field(description="Athena database name")
    table_name: str = Field(description="Athena table name")
    db_schema: str = Field(description="Database schema", default='resstock_oedi_new')


class PlotSpecification(NoExtraModel):
    """Specification for which plots to generate."""

    plot_types: tuple[PlotType, ...] = Field(
        default=(PlotType.eia, PlotType.lrd, PlotType.timeseries),
        description="Types of validation plots to generate",
    )
    aggregation_levels: tuple[AggregationLevel, ...] = Field(
        default=(AggregationLevel.state, AggregationLevel.eiaid),
        description="Geographic aggregation levels for plots",
    )
    output_formats: tuple[OutputFormat, ...] = Field(
        default=(OutputFormat.html, OutputFormat.svg, OutputFormat.parquet),
        description="Output file formats",
    )


class OutputConfig(NoExtraModel):
    """Configuration for output paths and behavior."""

    output_dir: Path = Field(description="Root directory for all outputs")
    run_name: str = Field(description="Name for this validation run (used in output paths)")

    @field_validator("output_dir", mode="before")
    @classmethod
    def expand_path(cls, v: str | Path) -> Path:
        """Expand user paths and convert to Path object."""
        return Path(v).expanduser().resolve()


class WorkflowConfig(NoExtraModel):
    workgroup: str = Field(description="Athena workgroup")
    data_sources: list[DataSourceConfig] = Field(description="BuildStock data source configuration")
    reference_year: int = Field(
        default=2018, description="Year of reference data to compare against"
    )
    plots: PlotSpecification = Field(default_factory=PlotSpecification, description="Plot specifications")
    output: OutputConfig = Field(description="Output configuration")

    @classmethod
    def from_yaml(cls, yaml_path: str | Path) -> WorkflowConfig:
        with open(yaml_path) as f:
            config_dict = yaml.safe_load(f)
        return cls.model_validate(config_dict)

    def get_names_of_data_sources(self) -> list[str]:
        return [ds.name for ds in self.data_sources]

workflow_config_path = Path(__file__).parent.parent / "workflow.yaml"
workflow = WorkflowConfig.from_yaml(workflow_config_path)