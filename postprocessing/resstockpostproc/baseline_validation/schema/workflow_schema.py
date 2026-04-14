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
from pydantic import Field, field_validator, model_validator

from resstockpostproc.baseline_validation.schema.plot_spec import NoExtraModel
from resstockpostproc.shared_utils.db_column_names import DBSchema


class PlotType(str, Enum):
    """Types of validation plots to generate."""

    eia = "eia"
    lrd = "lrd"
    recs = "recs"
    timeseries = "timeseries"


class GroupByLevel(str, Enum):
    """Geographic group_by levels for validation."""

    state = "state"
    utility = "utility"


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
    db_schema: DBSchema = Field(description="Database schema", default=DBSchema.OEDI_NEW)

    def __hash__(self):
        return hash((self.name, self.db_name, self.table_name, self.db_schema))

    def __eq__(self, other):
        if not isinstance(other, DataSourceConfig):
            return False
        return (
            self.name == other.name
            and self.db_name == other.db_name
            and self.table_name == other.table_name
            and self.db_schema == other.db_schema
        )


class DataSourceEntry(NoExtraModel):
    """A single dataset within a data source."""

    description: str = Field(description="Full description of this dataset")
    url: str = Field(default="", description="URL to the dataset documentation")


class DataSourceLabel(NoExtraModel):
    """Human-readable label for a data source appearing in plot legends."""

    label: str = Field(description="Short display name (e.g. 'EIA 2018')")
    entries: list[DataSourceEntry] = Field(description="List of datasets comprising this source")


class PlotSpecification(NoExtraModel):
    """Specification for which plots to generate."""

    plot_types: tuple[PlotType, ...] = Field(
        default=(PlotType.eia, PlotType.lrd, PlotType.timeseries),
        description="Types of validation plots to generate",
    )
    group_by_levels: tuple[GroupByLevel, ...] = Field(
        default=(GroupByLevel.state, GroupByLevel.utility),
        description="Geographic group_by levels for plots",
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
    resstock_histogram_data_root: Path = Field(
        description=(
            "Root folder for exact ResStock histogram raw data. "
            "Per-source files are inferred as "
            "<root>/ResStock Data/<data_source.name>/upgrade0.parquet"
        )
    )
    data_sources: list[DataSourceConfig] = Field(
        default_factory=list,
        description="BuildStock data source configuration (optional - leave empty for EIA-only comparisons)",
    )
    reference_years: dict[str, list[int]] = Field(
        default={"eia": [2018], "recs": [2020]},
        description="Reference years per data source (e.g., {'eia': [2018, 2024], 'recs': [2020]})",
    )
    plots: PlotSpecification = Field(default_factory=PlotSpecification, description="Plot specifications")
    quantities: list[str] | None = Field(
        default=None,
        description="List of quantities to generate plots for. If None or empty, all quantities will be generated.",
    )
    output: OutputConfig = Field(description="Output configuration")
    data_source_labels: dict[str, DataSourceLabel] = Field(
        default_factory=dict,
        description="Labels for data sources in plot legends (key = source column value, e.g. 'eia_2018')",
    )

    @field_validator("data_sources", mode="before")
    @classmethod
    def convert_none_to_empty_list(cls, v):
        """Convert None to empty list when data_sources key exists but has no items."""
        if v is None:
            return []
        return v

    @field_validator("resstock_histogram_data_root", mode="before")
    @classmethod
    def expand_histogram_data_root_path(cls, v: str | Path) -> Path:
        """Expand user paths and convert to Path object."""
        return Path(v).expanduser().resolve()

    def get_resstock_histogram_raw_file(self, source_name: str) -> Path:
        """Infer the exact raw parquet path for one ResStock source."""
        return self.resstock_histogram_data_root / "ResStock Data" / source_name / "upgrade0.parquet"

    @model_validator(mode="after")
    def validate_histogram_raw_inputs(self) -> WorkflowConfig:
        """Fail fast if required exact-histogram raw files are missing."""
        missing = [
            str(self.get_resstock_histogram_raw_file(ds.name))
            for ds in self.data_sources
            if not self.get_resstock_histogram_raw_file(ds.name).exists()
        ]
        if missing:
            preview = "\n - ".join(missing[:10])
            raise ValueError(
                "Missing required ResStock histogram raw parquet files:\n"
                f" - {preview}"
            )
        return self

    @classmethod
    def from_yaml(cls, yaml_path: str | Path) -> WorkflowConfig:
        with open(yaml_path) as f:
            config_dict = yaml.safe_load(f)
        return cls.model_validate(config_dict)

    def get_names_of_data_sources(self) -> list[str]:
        return [ds.name for ds in self.data_sources]


workflow_config_path = Path(__file__).parent.parent / "workflow.yaml"
workflow = WorkflowConfig.from_yaml(workflow_config_path)
