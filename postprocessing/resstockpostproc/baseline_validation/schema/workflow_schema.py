"""Configuration schema for baseline validation
--------------------------------------------
Defines Pydantic models for validating baseline validation workflow configuration
"""

from __future__ import annotations

from pathlib import Path

import yaml
from pydantic import Field, field_validator

from resstockpostproc.baseline_validation.schema.plot_spec import NoExtraModel
from resstockpostproc.shared_utils.db_column_names import DBSchema
from resstockpostproc.shared_utils.s3_manager import download_s3_file


class DataSourceConfig(NoExtraModel):
    """Configuration for BuildStock data source."""

    name: str = Field(description="Name for this data source")
    db_name: str = Field(description="Athena database name")
    table_name: str = Field(description="Athena table name")
    db_schema: DBSchema = Field(description="Database schema", default=DBSchema.OEDI_NEW)
    baseline_metadata_and_annual_results_parquet_url: str | None = Field(
        default=None,
        description=(
            "Optional S3 URL for the baseline metadata-and-annual-results parquet cached locally for fast reads."
        ),
    )
    skip_missing_enduses: bool = Field(
        default=False,
        description="If True, silently skip end-use columns not present in the Athena table instead of raising.",
    )
    query_unload_s3_bucket: str | None = Field(
        default=None,
        description="S3 bucket for Athena query unload results. Defaults to the workgroup name if not set.",
    )
    has_upgrades: bool = Field(
        default=True,
        description="If False, tells BSQ that no upgrades table exists for this data source.",
    )

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
    data_sources: list[DataSourceConfig] = Field(
        default_factory=list,
        description="BuildStock data source configuration (optional - leave empty for EIA-only comparisons)",
    )
    reference_years: dict[str, list[int]] = Field(
        default={"eia": [2018], "recs": [2020]},
        description="Reference years per data source (e.g., {'eia': [2018, 2024], 'recs': [2020]})",
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

    @property
    def resstock_data_root(self) -> Path:
        """Local cache root for downloaded ResStock baseline parquet data."""
        return self.output.output_dir / "data"

    def get_resstock_data_dir(self, source_name: str) -> Path:
        """Return the local per-source cache directory for one ResStock data source."""
        return self.resstock_data_root / "ResStock Data" / source_name

    def get_resstock_data_file_path(self, source_name: str) -> Path:
        """Return the expected local baseline parquet path for one ResStock data source."""
        return self.get_resstock_data_dir(source_name) / "upgrade0.parquet"

    def _get_data_source_config(self, source_name: str) -> DataSourceConfig:
        for data_source in self.data_sources:
            if data_source.name == source_name:
                return data_source
        raise KeyError(f"Unknown ResStock data source '{source_name}'")

    def ensure_resstock_data_file(self, source_name: str) -> Path:
        """Ensure the cached local baseline parquet exists for one ResStock data source."""
        local_path = self.get_resstock_data_file_path(source_name)
        if local_path.exists():
            return local_path

        data_source = self._get_data_source_config(source_name)
        parquet_url = data_source.baseline_metadata_and_annual_results_parquet_url
        if not parquet_url:
            raise ValueError(
                "Missing local ResStock baseline parquet and no "
                "`baseline_metadata_and_annual_results_parquet_url` was configured "
                f"for data source '{source_name}'. Expected local file: {local_path}"
            )
        return download_s3_file(parquet_url, local_path)

    def ensure_resstock_data_files(self) -> None:
        """Ensure all configured ResStock baseline parquet files are present locally."""
        for data_source in self.data_sources:
            self.ensure_resstock_data_file(data_source.name)

    def get_resstock_data_file(self, source_name: str) -> Path:
        """Return the local baseline parquet path, downloading it on demand if needed."""
        return self.ensure_resstock_data_file(source_name)

    @classmethod
    def from_yaml(cls, yaml_path: str | Path) -> WorkflowConfig:
        with open(yaml_path) as f:
            config_dict = yaml.safe_load(f)
        return cls.model_validate(config_dict)

    def get_names_of_data_sources(self) -> list[str]:
        return [ds.name for ds in self.data_sources]


workflow_config_path = Path(__file__).parent.parent / "workflow.yaml"
workflow = WorkflowConfig.from_yaml(workflow_config_path)
