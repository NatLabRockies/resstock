"""Pydantic model that fully describes how a single plot should be produced.

The aim is to pass **one** object of this class through the
entire pipeline - data processing, figure creation, and output saving.
"""

from __future__ import annotations

from pathlib import Path
from pydantic import BaseModel, Field
from enum import StrEnum
from typing import Literal
from resstockpostproc.shared_utils.db_column_names import DataCol


class NoExtraModel(BaseModel):
    """Base model that forbids extra fields and is frozen."""
    class Config:
        extra = "forbid"
        frozen = True

class AggregationType(StrEnum):
    stock_total = "stock total"
    per_unit = "per unit"
    per_unit_distribution = "per unit distribution"
    per_user = "per user"
    monthly_per_user = "monthly per user"
    per_user_distribution = "per user distribution"
    percent_users = "percent users"


class ViewType(StrEnum):
    """
    Whether the plot should focus on the values or the % difference between
    reference and ResStock.
    """
    diff_view = "diff"
    value_view = "value"


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


class QuantityGroup(NoExtraModel):
    """Definition of a quantity group with constituents and sum"""

    name: str = Field(description="Name of the quantity group")
    constituents: tuple[DataCol, ...] = Field(description="List of constituent columns")
    sum: str | None = Field(None, description="Column name for the sum quantity")


class PlotSpec(NoExtraModel):
    truth_source: TruthSource = Field(..., description="Optional truth source for comparison plots.")
    aggregation_type: AggregationType = Field(..., description="stock / per_unit etc")
    quantity: DataCol | None = Field(..., description="Column(s) to visualise.")
    resolution: Literal["monthly", "annual"] = Field(..., description="monthly / annual")
    visualization_type: Literal["bar", "choropleth"] = Field(..., alias="visualization_type")
    shared_axis_range: bool = Field(
        default=False, description="Whether to use shared axis range across subplots."
    )
    aggregation_level: str = Field(..., description="Eg. state, eiaid")
    focus_on: str | None = Field(default=None, description="Specific category to focus on. Example: CA")
    view: ViewType = Field(..., description="diff / value")

    def get_quantity_name(self) -> str:
        if self.quantity is None:
            return f"fuel {self.aggregation_type.value}"
        else:
            return f"{self.quantity.value} {self.aggregation_type.value}"

    def _get_title_prefix(self) -> str:
        qlabel = self.get_quantity_name()
        if self.aggregation_type != AggregationType.percent_users:
            title_prefix = f"{self.truth_source} {self.resolution} {qlabel} comparison"
        else:
            title_prefix = f"{self.truth_source} customer count comparison"
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

