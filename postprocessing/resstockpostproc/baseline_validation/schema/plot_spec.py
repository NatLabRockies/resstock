"""Pydantic model that fully describes how a single plot should be produced.

The aim is to pass **one** object of this class through the
entire pipeline - data processing, figure creation, and output saving.

This module also contains display-label functions (titles, facet labels)
that derive human-readable strings from PlotSpec fields. These are used by
both the plotters (for figure titles) and the HTML index (for filter facets).
"""

from __future__ import annotations

from pathlib import Path
from pydantic import BaseModel, Field, model_validator
from enum import StrEnum
from typing import NamedTuple
from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.shared_utils.mapping import ABBR2STATE

GEOGRAPHIC_DIMENSIONS = {"state", "census_division_recs", "building_america_climate_zone"}
"""Dimensions that represent geographic groupings. Filtering by one geographic dimension
while grouping by another produces degenerate plots (e.g., one state → one census division)."""


class NoExtraModel(BaseModel):
    """Base model that forbids extra fields and is frozen."""

    class Config:
        extra = "forbid"
        frozen = True


class Metric(StrEnum):
    total = "total"
    average = "average"
    distribution = "distribution"
    penetration = "penetration"


class CoverageType(StrEnum):
    """Population coverage for the data.
    Determines whether data includes all units or only users with non-zero consumption.
    """

    all_units = "all units"  # All units (EIA/LRD) or all occupied units (RECS)
    users_only = "users only"  # occupied units with non-zero consumption (RECS)


class ViewType(StrEnum):
    """View type for rendering plots.

    value_view is the default view — the plotting function decides the layout
    (tilemap, stacked, etc.) based on the rest of the PlotSpec.
    Other view types hint a different visualization of the same data.
    """

    # Display modes
    value_view = "value"  # The default view for most plots - shows actual values as the main plot
    diff_view = "difference view"  # Shows percent difference with comparison dataset as the main plot
    temp_view = "temperature relation"  # Only for LRD plots - shows relationship between consumption and outdoor
    temp_distribution_view = "temperature distribution"  # Only for LRD plots - distribution of temperature


class Layout(StrEnum):
    """Layout hint for alternate rendering arrangements of the same view."""

    auto = "auto"
    two_column = "two_column"
    histogram = "histogram"


class FileType(StrEnum):
    html = "html"
    svg = "svg"
    pdf = "pdf"
    json = "json"
    parquet = "parquet"
    csv = "csv"


class ComparisonDataset(StrEnum):
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

    effective_group_by is a sorted tuple of column names the data must be grouped by.
    For single-dimension plots: ("state",) or ("utility",).
    For cross-dimension plots: ("census_division_recs", "state"). The plotter may use the 
    data differently than how it is queried but making a single grouped query reduces number
    of queries needed.

    focus_on values are NOT included here — they are cheap post-aggregation
    filters applied after data loading.
    """

    comparison_dataset: ComparisonDataset
    effective_group_by: tuple[str, ...]
    resolution: Resolution
    aggregation_type: Metric
    coverage: CoverageType

    def __str__(self) -> str:
        return f"DataKey({self.comparison_dataset}, {self.effective_group_by}, {self.resolution}, {self.aggregation_type}, {self.coverage})"


def format_group_by(group_by: str) -> str:
    """Convert a group_by column name to a display label.

    Uses DataCol enum member names for known columns, falls back to title-casing
    the raw string for unknown values.

    Examples: "census_division_recs" → "Census Division", "state" → "State"
    """
    try:
        return DataCol(group_by).name.replace("_", " ").title()
    except ValueError:
        return group_by.replace("_", " ").title()


def format_focus_label(value: str) -> str:
    """Convert a raw focus_on value to a human-readable display label.

    "US Total" → "U.S. Total", state abbreviations → full names, others pass through.
    """
    if value == "US Total":
        return "U.S. Total"
    if value in ABBR2STATE:
        return ABBR2STATE[value]
    return value


_PERIOD_LABEL = {
    Resolution.year: "Annual",
    Resolution.month: "Monthly",
    Resolution.day_of_year: "Daily",
    Resolution.hour_of_day: "Average Daily",
    Resolution.hour_of_day_summer: "Average Summer Day Hourly",
    Resolution.hour_of_day_winter: "Average Winter Day Hourly",
}


class PlotSpec(NoExtraModel):
    comparison_dataset: ComparisonDataset = Field(..., description="Comparison dataset for validation plots (eia, recs, lrd).")
    aggregation_type: Metric = Field(..., description="Metric: total, average, distribution, or penetration")
    coverage: CoverageType = Field(..., description="Population coverage: all_units or users_only")
    quantity: DataCol = Field(..., description="Column(s) to visualise. Use DataCol.ALL for all enduses.")
    resolution: Resolution = Field(..., description="Time resolution: monthly / annual / hourly")
    group_by: str | None = Field(
        default=None,
        description="Optional sub-grouping dimension (e.g. state, vintage). "
                    "When None, data is grouped only by focus_on columns.",
    )
    focus_on: tuple[tuple[str, str], ...] = Field(
        default=(),
        description="Filter tuples: ((column, value), ...). Max 2 tuples. "
                    "Each restricts the data to that column=value. "
                    "Example: (('state', 'AK'),) focuses on Alaska. "
                    "(('state', 'AK'), ('vintage', '1990s')) focuses on AK 1990s homes.",
    )
    view: ViewType | None = Field(..., description="View type: diff_view, value_view, temp_view, etc.")
    layout: Layout = Field(default=Layout.auto, description="Layout hint: auto, two_column, or histogram")

    @model_validator(mode="after")
    def _validate_metric_constraints(self) -> PlotSpec:
        if self.aggregation_type == Metric.distribution and self.comparison_dataset != ComparisonDataset.recs:
            raise ValueError("Metric.distribution is only supported for RECS.")
        if self.aggregation_type == Metric.distribution and self.quantity in (DataCol.UNITS_COUNT, DataCol.ALL):
            raise ValueError("Metric.distribution requires an end-use quantity (not UNITS_COUNT or ALL).")
        if self.aggregation_type == Metric.penetration:
            if self.comparison_dataset not in (ComparisonDataset.recs, ComparisonDataset.eia):
                raise ValueError("Metric.penetration is only supported for RECS and EIA.")
            if self.coverage != CoverageType.all_units:
                raise ValueError("Metric.penetration requires coverage=all_units.")
            if self.quantity in (DataCol.UNITS_COUNT,):
                raise ValueError("Metric.penetration does not apply to UNITS_COUNT.")
        if self.view == ViewType.diff_view and self.aggregation_type == Metric.distribution:
            raise ValueError("Metric.distribution does not support diff_view.")
        return self

    @model_validator(mode="after")
    def _validate_lrd_constraints(self) -> PlotSpec:
        if self.comparison_dataset != ComparisonDataset.lrd:
            return self
        if self.quantity not in (DataCol.ELECTRICITY_TOTAL,):
            raise ValueError(
                f"LRD only supports quantity=ELECTRICITY_TOTAL (got {self.quantity}). "
                "LRD data contains only hourly electricity consumption."
            )
        if self.data_aggregation_type != Metric.average:
            raise ValueError(
                f"LRD only supports average-backed metrics (got {self.aggregation_type}). "
                "LRD data is per-meter, not stock total."
            )
        if self.coverage != CoverageType.all_units:
            raise ValueError(
                f"LRD only supports coverage=all_units (got {self.coverage}). "
                "LRD data does not distinguish between users and non-users."
            )
        return self

    @model_validator(mode="after")
    def _sort_focus_on(self) -> PlotSpec:
        """Normalize focus_on order by sorting on column name.

        Ensures consistent file paths and titles regardless of construction order.
        """
        if len(self.focus_on) > 1:
            self.focus_on = tuple(sorted(self.focus_on, key=lambda x: x[0]))
        return self

    @model_validator(mode="after")
    def _validate_focus_on(self) -> PlotSpec:
        if len(self.focus_on) > 2:
            raise ValueError(
                f"focus_on supports at most 2 filter tuples (got {len(self.focus_on)}). "
                "Data becomes too thin with more than 2 filters for meaningful plots."
            )
        seen_cols = set()
        for col, _ in self.focus_on:
            if col in seen_cols:
                raise ValueError(
                    f"focus_on contains duplicate column '{col}'. "
                    "Each column can appear at most once."
                )
            seen_cols.add(col)

        if len(self.focus_on) == 2 and self.group_by is not None:
            raise ValueError(
                "group_by must be None when focus_on has 2 filters. "
                "Data is too thin for meaningful sub-grouping with 2 filters applied."
            )

        if self.group_by is not None and self.group_by in seen_cols:
            raise ValueError(
                "group_by cannot also appear in focus_on. "
                "To select one entity from the aggregation, set group_by=None and "
                "add (column, value) to focus_on instead."
            )

        if self.focus_on and self.group_by is not None:
            if self.comparison_dataset != ComparisonDataset.recs:
                raise ValueError(
                    f"Cross-dimension focus_on filters are only supported for RECS "
                    f"(got comparison_dataset={self.comparison_dataset}). "
                    "EIA and LRD data lack building-level characteristics for filtering."
                )
            if self.resolution != Resolution.year:
                raise ValueError(
                    f"Cross-dimension focus_on filters are only supported for annual resolution "
                    f"(got {self.resolution}). "
                    "Monthly RECS data is pre-aggregated and cannot be further broken down."
                )

        geo_cols = {col for col, _ in self.focus_on if col in GEOGRAPHIC_DIMENSIONS}
        if self.group_by in GEOGRAPHIC_DIMENSIONS:
            geo_cols.add(self.group_by)
        if len(geo_cols) > 1:
            raise ValueError(
                f"Multiple geographic dimensions found: {geo_cols}. "
                "Mixing geographic dimensions produces degenerate plots."
            )

        return self

    @property
    def _per_unit_label(self) -> str:
        """'per Consuming Dwelling Unit' or 'per Dwelling Unit'."""
        return "per Consuming Dwelling Unit" if self.coverage == CoverageType.users_only else "per Dwelling Unit"

    @property
    def data_key(self) -> DataKey:
        """Data key that uniquely identifies the base dataset for this plot.

        Uses effective_group_by (sorted union of focus_on columns + group_by)
        to determine which columns the data must be grouped by.
        """
        return DataKey(
            comparison_dataset=self.comparison_dataset,
            effective_group_by=self.effective_group_by or ("state",),
            resolution=self.resolution,
            aggregation_type=self.data_aggregation_type,
            coverage=self.coverage,
        )

    @property
    def data_aggregation_type(self) -> Metric:
        """Aggregation used for base data fetching (total/average only)."""
        if self.aggregation_type == Metric.distribution:
            return Metric.average
        if self.aggregation_type == Metric.penetration:
            return Metric.total
        return self.aggregation_type

    @property
    def is_distribution_metric(self) -> bool:
        return self.aggregation_type == Metric.distribution

    @property
    def is_penetration_metric(self) -> bool:
        return self.aggregation_type == Metric.penetration

    @property
    def effective_group_by(self) -> tuple[str, ...]:
        """Sorted tuple of all columns the data handler must group by.

        This is the union of focus_on columns and group_by, sorted
        alphabetically so that ("state", "vintage") and ("vintage", "state")
        produce the same DataKey for cache consistency.
        """
        cols = {col for col, _ in self.focus_on}
        if self.group_by is not None:
            cols.add(self.group_by)
        return tuple(sorted(cols))

    @property
    def display_title(self) -> str:
        """Publication-quality title for the plot figure and HTML index.

        Handles all comparison datasets (EIA, RECS, LRD) in a single method.
        LRD-specific resolutions (load duration curves, temperature plots, hourly
        matrices) get unique titles; everything else follows the common pattern:
        "{Period} {Quantity} Consumption {Per} {Grouping}"

        Examples:
            "Average Monthly Electricity Consumption per Dwelling Unit by State"
            "Annual Electricity Consumption per Dwelling Unit"
            "Load Duration Curve of Electricity Consumption per Dwelling Unit"
        """
        # ── LRD-specific resolutions with unique title patterns ──
        if self.comparison_dataset == ComparisonDataset.lrd:
            match self.resolution:
                case Resolution.hour_of_year | Resolution.top_100_hours:
                    if self.view == ViewType.temp_view:
                        return "Load vs Outdoor Drybulb Temperature"
                    if self.view == ViewType.temp_distribution_view:
                        return "Count of Number of Hours vs Outdoor Drybulb Temperature"
                    title = "Load Duration Curve of Electricity Consumption per Dwelling Unit"
                    if self.resolution == Resolution.top_100_hours:
                        title += " (Top 100 Hours)"
                    return title
                case Resolution.hour_of_day_matrix:
                    focus_display = ", ".join(v for _, v in self.focus_on)
                    return f"Hourly Load Profile Matrix for {focus_display}"

        # ── Grouping suffix (shared by all common-pattern titles) ──
        agg_label = format_group_by(self.group_by) if self.group_by else ""
        focus_display = self.filter_display_name
        if focus_display and agg_label:
            grouping = f"by {agg_label} ({focus_display})"
        elif focus_display:
            grouping = f"({focus_display})"
        elif agg_label:
            grouping = f"by {agg_label}"
        else:
            grouping = "(U.S. Total)"

        # ── Special RECS/EIA view types ──
        quantity_name = self.quantity.label if self.quantity != DataCol.ALL else "Enduse"

        if self.quantity == DataCol.UNITS_COUNT:
            du_label = "Occupied Dwelling Units" if self.comparison_dataset == ComparisonDataset.recs else "Dwelling Units"
            return f"Number of {du_label} {grouping}"

        if self.is_penetration_metric:
            usage_name = "the specified End Use" if self.quantity == DataCol.ALL else self.quantity.penetration_label
            return f"Share of Dwelling Units using {usage_name} {grouping}"

        if self.is_distribution_metric:
            return f"Distribution of {quantity_name} Consumption {self._per_unit_label} {grouping}"

        # ── Common pattern: "{Period} {Quantity} Consumption {Per} {Grouping}" ──
        period = _PERIOD_LABEL.get(self.resolution, "Annual")

        if self.aggregation_type == Metric.total:
            return f"{period} {quantity_name} Consumption {grouping}"

        return f"Average {period} {quantity_name} Consumption {self._per_unit_label} {grouping}"

    @property
    def display_comparison_dataset(self) -> str:
        """Human-readable label for the comparison dataset (e.g. 'EIA 2018', 'RECS 2020').

        Resolves from workflow.data_source_labels by finding the first key that
        starts with the comparison_dataset value. Falls back to uppercase enum value.
        """
        from resstockpostproc.baseline_validation.schema.workflow_schema import workflow
        ds = self.comparison_dataset.value
        for key, label_obj in workflow.data_source_labels.items():
            if key.startswith(ds):
                return label_obj.label
        return ds.upper()

    @property
    def display_quantity(self) -> str:
        """Quantity facet label for the HTML index.

        Examples: "Electricity", "Space Heating Natural Gas",
                  "Number of dwelling units", "All Enduses"
        """
        if self.quantity == DataCol.UNITS_COUNT:
            return "Number of dwelling units"
        if self.quantity == DataCol.ALL:
            return "All Enduses"
        return self.quantity.label

    @property
    def display_coverage(self) -> str:
        return "All Units" if self.coverage == CoverageType.all_units else "Consuming Units Only"

    @property
    def display_metric(self) -> str:
        """Metric facet label — title-aligned, without quantity name or grouping.

        Examples:
            "Total Annual Consumption" (total, year)
            "Average Monthly Consumption" (average, month)
            "Distribution of Annual Consumption" (distribution)
            "Load Duration Plot" (LRD)
        """
        if self.comparison_dataset == ComparisonDataset.lrd:
            if self.view in (ViewType.temp_view, ViewType.temp_distribution_view):
                return "Load Vs Outdoor Drybulb Temperature"
            if self.resolution == Resolution.year:
                return "Average Annual Consumption"
            if self.resolution == Resolution.month:
                return "Average Monthly Consumption"
            if self.resolution == Resolution.day_of_year:
                return "Average Daily Consumption"
            if self.resolution in (
                Resolution.hour_of_day,
                Resolution.hour_of_day_summer,
                Resolution.hour_of_day_winter,
                Resolution.hour_of_day_matrix,
            ):
                return "Average Day Hourly Consumption"
            if self.resolution in (Resolution.hour_of_year, Resolution.top_100_hours):
                return "Load Duration Plot"
            return self.display_title

        if self.quantity == DataCol.UNITS_COUNT:
            du_label = "Occupied Dwelling Units" if self.comparison_dataset == ComparisonDataset.recs else "Dwelling Units"
            return f"Number of {du_label}"

        if self.is_penetration_metric:
            return "Enduse Penetration"

        period = _PERIOD_LABEL.get(self.resolution, "Annual")

        if self.is_distribution_metric:
            return f"Distribution of {period} Consumption"

        if self.aggregation_type == Metric.total:
            return f"Total {period} Consumption"

        return f"Average {period} Consumption"

    @property
    def display_group_by(self) -> str:
        """Group-by facet label: 'State', 'Census Division', 'Utility', etc."""
        if not self.group_by:
            return ""
        return format_group_by(self.group_by)

    def viz_label(self, layout: str | None = None) -> str:
        """Normalized visualization label for explorer/index tabs.

        Base labels are constrained to:
        - Bar Plot
        - Box Plot
        - Timeseries Plot

        Optional suffixes:
        - (grouped)
        - (stacked)
        - (difference view)
        - (grouped difference view)
        - (stacked difference view)
        """
        base = self._base_viz_label
        layout_label = self._default_viz_layout if layout is None else layout

        if self.layout == Layout.histogram:
            return "Histogram"

        if self.layout != Layout.auto:
            if self.view == ViewType.diff_view:
                return f"{base} ({self.layout.value} difference view)"
            return f"{base} ({self.layout.value})"

        if self.view == ViewType.diff_view:
            if layout_label == "grouped":
                suffix = "grouped difference view"
            elif layout_label == "stacked":
                suffix = "stacked difference view"
            else:
                suffix = "difference view"
        elif layout_label in ("grouped", "stacked"):
            suffix = layout_label
        else:
            suffix = None

        return f"{base} ({suffix})" if suffix else base

    @property
    def display_viz_label(self) -> str:
        """Visualization type label for the HTML index.

        Examples: 'Bar Plot', 'Bar Plot (grouped)', 'Timeseries Plot (difference view)'
        """
        return self.viz_label()

    @property
    def _default_viz_layout(self) -> str | None:
        """Default layout qualifier used in display_viz_label."""
        if self.quantity == DataCol.ALL:
            return "grouped"
        if self.group_by:
            return "grouped"
        return None

    @property
    def _base_viz_label(self) -> str:
        """Base visualization type label before any optional suffix."""
        if self.layout == Layout.histogram:
            return "Histogram"
        if self.is_distribution_metric:
            return "Box Plot"
        if self.resolution == Resolution.year:
            return "Bar Plot"
        return "Timeseries Plot"

    @property
    def filter_display_name(self) -> str:
        """Human-readable label for the focus_on filters.

        State abbreviations → full names, others pass through.
        Returns '' if focus_on is empty.

        Examples: 'Alaska', 'Alaska, Single-Family Detached'
        """
        return ", ".join(format_focus_label(v) for _, v in self.focus_on)

    @property
    def file_path_and_name(self) -> tuple[Path, str]:
        """Build the output file path and filename from display-quality labels.

        Returns (path_segment, filename) where:
        - path_segment uses human-readable directory names (e.g. "By State/Alaska")
        - filename is the display_title with coverage/view suffixes
        """
        title = self.display_title
        if self.layout != Layout.auto:
            title = title + f" ({self.layout.value} layout)"
        if self.quantity == DataCol.ALL and self.view == ViewType.value_view:
            title = title + " (grouped view)"
        elif self.quantity == DataCol.ALL and self.view == ViewType.diff_view:
            title = title + " (grouped symmetric percent difference view)"
        elif self.view == ViewType.diff_view:
            title = title + " (symmetric percent difference view)"
        # Focus entries go at the top of the path hierarchy.
        # "US Total" is a sibling of "By State", not a child.
        filter_dir = Path()
        for char, value in self.focus_on:
            if value == "US Total":
                filter_dir /= "U.S. Total"
            else:
                filter_dir /= f"By {format_group_by(char)}"
                filter_dir /= format_focus_label(value)
        path_segment = filter_dir / f"By {format_group_by(self.group_by)}" if self.group_by else filter_dir
        return path_segment, title
