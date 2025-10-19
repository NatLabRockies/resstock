"""Pydantic model that fully describes how a single plot should be produced.

The aim is to pass **one** object of this class (``PlotSpec``) through the
entire pipeline - data processing, figure creation, and output saving.
"""

from pathlib import Path

from pydantic import BaseModel, Field, field_validator

from resstockpostproc.standard_plots.schema.workflow_schema import (
    QuantityType,
    QuantityGroup,
    BuildingInclusion,
    VacancyInclusion,
    AggregationType,
    VizType,
)


class PlotSpec(BaseModel):
    """Single plot specification coming from YAML or programmatic source."""

    building_inclusion: BuildingInclusion = Field(..., description="all / applied_only")
    vacancy_inclusion: VacancyInclusion = Field(..., description="all / occupied_only")
    quantity_type: QuantityType = Field(
        ..., description="absolute / savings / percent_savings / model_count / prevalence"
    )
    aggregation_type: AggregationType = Field(..., description="total or average")
    visualization_type: VizType = Field(..., alias="visualization_type")
    group_by: str | None = Field(default=None, description="Column to facet/group by.")
    quantity: str | QuantityGroup = Field(..., description="Column(s) to visualise.")
    quantity_group_name: str = Field(..., description="Name of the quantity group - used when quantity is part of group")
    upgrade: int | None = Field(default=None, description="Upgrade to visualise. Can be None for all.")

    @field_validator("quantity")
    @classmethod
    def set_quantity_for_model_count(cls, v, info):
        values = info.data
        if values.get("quantity_type") == QuantityType.model_count:
            return "bldg_id"
        return v

    @classmethod
    def get_valid_visualization_types(
        cls, quantity_type: QuantityType, aggregation_type: AggregationType
    ) -> list[VizType]:
        """Return list of valid value types for the given visualization type."""
        if quantity_type in [QuantityType.model_count, QuantityType.prevalence]:
            return [VizType.bar, VizType.choropleth]
        if aggregation_type in [AggregationType.distribution]:
            return [VizType.box, VizType.hist]
        return [VizType.bar, VizType.heatmap, VizType.choropleth]

    @classmethod
    def get_valid_aggregation_types(cls, quantity_type: QuantityType) -> list[AggregationType]:
        if quantity_type in [QuantityType.model_count, QuantityType.prevalence]:
            return [AggregationType.total]
        if quantity_type in [QuantityType.percent_savings]:
            return [AggregationType.average, AggregationType.distribution]
        return [AggregationType.total, AggregationType.average, AggregationType.distribution]

    def get_error(self) -> str:
        """Return error message if the plot spec is invalid."""
        valid_agg_type = self.get_valid_aggregation_types(self.quantity_type)
        if self.aggregation_type not in valid_agg_type:
            error = f"Invalid aggregation type: {self.aggregation_type} for quantity type: {self.quantity_type}"
            error += f" Valid aggregation types: {valid_agg_type}"
            return error
        valid_viz_type = self.get_valid_visualization_types(self.quantity_type, self.aggregation_type)
        if self.visualization_type not in valid_viz_type:
            error = f"Invalid visualization: {self.visualization_type} for aggregation type: {self.aggregation_type}"
            error += f" Valid visualization types: {valid_viz_type}"
            return error
        if self.aggregation_type == AggregationType.total and self.quantity_type == QuantityType.percent_savings:
            return "Percent savings can only be aggregated as weighted average"
        if self.visualization_type == VizType.box and not isinstance(self.quantity, str) and self.group_by:
            return "Box plot can only be generated from stacked quantities when group_by is None."
        if self.visualization_type == VizType.heatmap and not isinstance(self.quantity, QuantityGroup):
            return "Heatmap can only be generated from stacked quantities"
        if self.visualization_type == VizType.hist and isinstance(self.quantity, QuantityGroup):
            return "Histogram cannot be generated from stacked quantities"
        if self.visualization_type == VizType.choropleth:
            if self.aggregation_type == AggregationType.distribution:
                return "Choropleth cannot be generated for distribution aggregation."
            if isinstance(self.quantity, QuantityGroup):
                return "Choropleth plots require a single quantity column."
        if self.upgrade == 0 and self.building_inclusion == BuildingInclusion.applied_only:
            return "Baseline can't be passed as an upgrade to plot when building_inclusion is applied_only."
        if self.upgrade == 0 and self.quantity_type in [QuantityType.percent_savings, QuantityType.savings]:
            return "Baseline can't be used for savings comparison."
        return ""

    def is_valid(self) -> bool:
        """Return True if the plot spec is valid."""
        return self.get_error() == ""

    def get_path_and_name(self, selected_upgrades: list[int] | None = None) -> tuple[Path, str]:
        """selected_upgrades is passed by the dynamic dashboard when only including
        a subset of upgrades than that is defined in the workflow yaml file.
        """
        if self.building_inclusion == BuildingInclusion.applied_only:
            path_segment = Path(f"Included Buildings = Applied only")
        else:
            path_segment = Path("Included Buildings = All")
        if self.upgrade is None:
            if selected_upgrades:
                path_segment /= f"Upgrade = {','.join(map(str, sorted(selected_upgrades)))}"
            else:
                path_segment /= f"Upgrade = All"
        else:
            path_segment /= f"Upgrade = {self.upgrade}"
        path_segment /= f"Vacancy = {self.vacancy_inclusion.value}"
        path_segment /= f"Quantity Type = {self.quantity_type.value}"
        path_segment /= f"Aggregation Type = {self.aggregation_type.value}"
        path_segment /= f"Visualization Type = {self.visualization_type.value}"
        if self.group_by:
            path_segment /= f"Grouped By = {self.group_by}"
        else:
            path_segment /= "Grouped By = No grouping"
        path_segment /= f"Quantity Group = {self.quantity_group_name}"
        name = "all_together" if isinstance(self.quantity, QuantityGroup) else f"{self.quantity}"
        return path_segment, name
