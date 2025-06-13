"""Pydantic model that fully describes how a single plot should be produced.

The aim is to pass **one** object of this class (``PlotSpec``) through the
entire pipeline - data processing, figure creation, and output saving.
"""

from __future__ import annotations

from pathlib import Path

from pydantic import BaseModel, Field, field_validator

from resstockpostproc.standard_plots.schema.workflow_schema import ComparisonTypes, QuantityGroup, UpgradeInclusion, VacancyInclusion, VizType

# Accept dicts whose values can be *either* a list[str] (for "constituents") or a
# single string (for "sum"). We don't need to be overly strict here - runtime
# code handles the logic.
QuantityType = str | QuantityGroup  # single column | {"constituents": [...], "sum": "..."}


class PlotSpec(BaseModel):
    """Single plot specification coming from YAML or programmatic source."""

    upgrade_inclusion: UpgradeInclusion = Field(..., description="all / applied_only")
    vacancy_inclusion: VacancyInclusion = Field(..., description="all / occupied_only")
    comparison_type: ComparisonTypes = Field(..., description="absolute / mean / percent_savings")
    visualization_type: VizType = Field(..., alias="visualization_type")
    group_by: str | None = Field(None, description="Column to facet/group by.")
    quantity: QuantityType = Field(..., description="Column(s) to visualise.")

    @field_validator("quantity")
    def _validate_quantity(cls, v, values):
        """Ensure quantity form is compatible with viz type (basic checks)."""
        viz = values.data.get("visualization_type")
        if viz == VizType.box and not isinstance(v, str):
            raise ValueError("Box plots cannot be generated from stacked quantities")
        return v

    def path_segments(self, quantity_group_name: str) -> Path:
        """Return path sub-segments derived from the definition."""
        path_segment = Path(f"Included Buildings = {self.upgrade_inclusion.value}")
        path_segment /= f"Vacancy = {self.vacancy_inclusion.value}"
        path_segment /= f"Comparison Type = {self.comparison_type.value}"
        path_segment /= f"Visualization Type = {self.visualization_type.value}"
        if self.group_by:
            path_segment /= f"Group By = {self.group_by}"
        else:
            path_segment /= "Group By = all"
        path_segment /= f"Quantity Group = {quantity_group_name}"
        if isinstance(self.quantity, QuantityGroup):
            path_segment /= "Quantity = all_stacked"
        else:
            path_segment /= f"Quantity = {self.quantity}"
        return path_segment
