"""Pydantic model that fully describes how a single plot should be produced.

The aim is to pass **one** object of this class (``PlotSpec``) through the
entire pipeline - data processing, figure creation, and output saving.
"""

from pathlib import Path

from pydantic import BaseModel, Field, field_validator

from resstockpostproc.standard_plots.schema.workflow_schema import (
    ComparisonTypes,
    QuantityGroup,
    BuildingInclusion,
    VacancyInclusion,
    ValueTypes,
    VizType,
)

# Accept dicts whose values can be *either* a list[str] (for "constituents") or a
# single string (for "sum"). We don't need to be overly strict here - runtime
# code handles the logic.
QuantityType = str | QuantityGroup  # single column | {"constituents": [...], "sum": "..."}


class PlotSpec(BaseModel):
    """Single plot specification coming from YAML or programmatic source."""

    building_inclusion: BuildingInclusion = Field(..., description="all / applied_only")
    vacancy_inclusion: VacancyInclusion = Field(..., description="all / occupied_only")
    comparison_type: ComparisonTypes = Field(..., description="absolute / mean / percent_savings")
    value_type: ValueTypes = Field(..., description="total or average")
    visualization_type: VizType = Field(..., alias="visualization_type")
    group_by: str | None = Field(default=None, description="Column to facet/group by.")
    quantity: QuantityType = Field(..., description="Column(s) to visualise.")
    quantity_group_name: str = Field(
        ..., description="Name of the quantity group - used when quantity is part of group"
    )
    upgrade: int | None = Field(default=None, description="Upgrade to visualise. Can be None for all.")

    @field_validator("quantity")
    @classmethod
    def _validate_quantity(cls, v, values):
        """Ensure quantity form is compatible with viz type (basic checks)."""
        viz = values.data.get("visualization_type")
        if viz == VizType.box and not isinstance(v, str):
            raise ValueError("Box plots cannot be generated from stacked quantities")
        return v

    @classmethod
    def get_valid_value_types(cls, visualization_type: VizType) -> list[str]:
        """Return list of valid value types for the given visualization type."""
        if visualization_type in [VizType.box, VizType.hist, VizType.heatmap]:
            return [ValueTypes.average]
        return [ValueTypes.total, ValueTypes.average]

    def get_error(self) -> str:
        """Return error message if the plot spec is invalid."""
        if self.value_type not in (valid_value_types := self.get_valid_value_types(self.visualization_type)):
            error = f"Invalid value type: {self.value_type} for visualization type: {self.visualization_type}"
            error += f" Valid value types: {valid_value_types}"
            return error
        # can't do total of percent_savings
        if self.value_type == ValueTypes.total and self.comparison_type == ComparisonTypes.percent_savings:
            return "Percent savings can only be aggregated as weighted average"
        if self.visualization_type == VizType.box and not isinstance(self.quantity, str):
            return "Box plots cannot be generated from stacked quantities"
        if self.visualization_type == VizType.heatmap and not isinstance(self.quantity, QuantityGroup):
            return "Heatmap cannot be generated from stacked quantities"
        return ""

    def is_valid(self) -> bool:
        """Return True if the plot spec is valid."""
        return self.get_error() == ""

    def get_path_and_name(self) -> tuple[Path, str]:
        """Return path sub-segments derived from the definition."""
        if self.building_inclusion == BuildingInclusion.applied_only:
            path_segment = Path(f"Included Buildings = Applied in {self.upgrade}")
        else:
            path_segment = Path(f"Included Buildings = {self.building_inclusion.value}")
        path_segment /= f"Vacancy = {self.vacancy_inclusion.value}"
        path_segment /= f"Comparison Type = {self.comparison_type.value}"
        path_segment /= f"Visualization Type = {self.visualization_type.value}"
        path_segment /= f"Value Type = {self.value_type.value}"
        if self.group_by:
            path_segment /= f"Group By = {self.group_by}"
        else:
            path_segment /= "Group By = all"
        path_segment /= f"Quantity Group = {self.quantity_group_name}"
        name = "all_stacked" if isinstance(self.quantity, QuantityGroup) else f"{self.quantity}"
        return path_segment, name
