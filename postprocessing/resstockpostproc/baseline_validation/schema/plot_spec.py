"""Pydantic model that fully describes how a single plot should be produced.

The aim is to pass **one** object of this class through the
entire pipeline - data processing, figure creation, and output saving.
"""

from __future__ import annotations

from pathlib import Path
from pydantic import BaseModel, Field
from enum import StrEnum
from typing import NamedTuple
from resstockpostproc.shared_utils.db_column_names import DataCol


class NoExtraModel(BaseModel):
    """Base model that forbids extra fields and is frozen."""

    class Config:
        extra = "forbid"
        frozen = True


class AggregationType(StrEnum):
    total = "total"
    average = "average"


class CoverageType(StrEnum):
    """Population coverage for the data.
    Determines whether data includes all units or only users with non-zero consumption.
    """

    all_units = "all units"  # All units (EIA/LRD) or all occupied units (RECS)
    users_only = "users only"  # occupied units with non-zero consumption (RECS)


class ViewType(StrEnum):
    """View type for rendering plots.

    These roughly corresponds to the different visualization types in plot_definition.csv.
    value_view is the default view for most plots in visualization 1 - the plotting function
    should decide how to render it based on the plot specification.
    Other view types provide hints to the plotting function to generate a different kind of
    plot from the same data by making use of different or additional columns.
    """

    # Display modes
    value_view = "value"
    diff_view = "difference view"
    temp_view = "temperature relation"
    temp_count_view = "temperature count"
    distribution = "distribution box plot"
    penetration = "enduse penetration bar plot"


class FileType(StrEnum):
    html = "html"
    svg = "svg"
    pdf = "pdf"
    json = "json"
    parquet = "parquet"
    csv = "csv"


class TruthSource(StrEnum):
    eia = "eia"
    lrd = "lrd"
    recs = "recs"


class Resolution(StrEnum):
    hour_of_day = "hour of day"
    hour_of_day_summer = "hour of day summer"
    hour_of_day_winter = "hour of day winter"
    hour_of_day_matrix = "hour of day matrix"
    day_of_year = "day of year"
    month = "month"
    year = "year"
    hour_of_year = "hour of year"
    top_100_hours = "top 100 hours"


class DataKey(NamedTuple):
    """Key that uniquely identifies a base dataset.

    All plots with the same DataKey can share the same expensive data loading operation.
    Only these 5 parameters affect the core data loading in get_base_data().

    Other PlotSpec parameters (quantity, focus_on, view) only affect cheap post-processing.
    """

    truth_source: TruthSource
    aggregation_level: str
    resolution: Resolution
    aggregation_type: AggregationType
    coverage: CoverageType

    def __str__(self) -> str:
        return f"DataKey({self.truth_source}, {self.aggregation_level}, {self.resolution}, {self.aggregation_type}, {self.coverage})"


class PlotSpec(NoExtraModel):
    truth_source: TruthSource = Field(..., description="Truth source for comparison plots (eia, recs, lrd).")
    aggregation_type: AggregationType = Field(..., description="Aggregation method: total or average")
    coverage: CoverageType = Field(..., description="Population coverage: all_units or users_only")
    quantity: DataCol | None = Field(..., description="Column(s) to visualise.")
    resolution: Resolution = Field(..., description="Time resolution: monthly / annual / hourly")
    aggregation_level: str = Field(..., description="Grouping level, e.g. state, eiaid, vintage")
    focus_on: str | None = Field(default=None, description="Specific category to focus on. Example: CA")
    view: ViewType | None = Field(..., description="View type: diff_view, value_view, distribution, etc.")

    def get_data_key(self) -> DataKey:
        """Get the data key that uniquely identifies the base dataset for this plot.

        Returns:
            DataKey tuple of (truth_source, aggregation_level, resolution, aggregation_type, coverage)
        """
        return DataKey(
            truth_source=self.truth_source,
            aggregation_level=self.aggregation_level,
            resolution=self.resolution,
            aggregation_type=self.aggregation_type,
            coverage=self.coverage,
        )

    def get_quantity_name(self) -> str:
        if self.quantity is None:
            return f"fuel {self.aggregation_type.value}"
        else:
            return f"{self.quantity.value} {self.aggregation_type.value}"

    def _get_title_prefix(self) -> str:
        qlabel = self.get_quantity_name()
        title_prefix = f"{self.truth_source} {self.resolution} {qlabel} comparison"
        return title_prefix

    def get_title(self) -> str:
        title_prefix = self._get_title_prefix()
        if self.focus_on:
            title = title_prefix + " for " + self.focus_on
        else:
            title = title_prefix + f" by {self.aggregation_level}"
        return title

    def get_file_path_and_name(self) -> tuple[Path, str]:
        title_prefix = self._get_title_prefix()
        title = self.get_title()
        path_segment = Path(title_prefix + f" by {self.aggregation_level}")
        path_segment /= self.focus_on if self.focus_on else "All"
        return path_segment, title
