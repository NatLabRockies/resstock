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

    value_view is the default view — the plotting function decides the layout
    (tilemap, stacked, etc.) based on the rest of the PlotSpec.
    Other view types hint a different visualization of the same data.
    """

    # Display modes
    value_view = "value"  # The default view for most plots - shows actual values as the main plot
    diff_view = "difference view"  # Shows percent difference with comparison dataset as the main plot
    temp_view = "temperature relation"  # Only for LRD plots - shows relationship between consumption and outdoor
    temp_distribution_view = "temperature distribution"  # Only for LRD plots - distribution of temperature
    distribution = "distribution box plot" # RECS only - shows distribution of per-unit/per-user values with box plot
    penetration = "enduse penetration bar plot"  # Only for RECS - shows % of units with non-zero consumption for each


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
    aggregation_type: AggregationType
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
    aggregation_type: AggregationType = Field(..., description="Aggregation method: total or average")
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
    view: ViewType | None = Field(..., description="View type: diff_view, value_view, distribution, etc.")

    @model_validator(mode="after")
    def _reject_total_distribution(self) -> PlotSpec:
        if self.aggregation_type == AggregationType.total and self.view == ViewType.distribution:
            raise ValueError(
                "ViewType.distribution requires AggregationType.average (not total). "
                "Distribution box plots show per-unit/per-user quartiles, which are "
                "incompatible with stock total values."
            )
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
        if self.aggregation_type != AggregationType.average:
            raise ValueError(
                f"LRD only supports aggregation_type=average (got {self.aggregation_type}). "
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
            aggregation_type=self.aggregation_type,
            coverage=self.coverage,
        )

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
            grouping = f"({focus_display} only) by {agg_label}"
        elif focus_display:
            grouping = f"({focus_display})"
        elif agg_label:
            grouping = f"by {agg_label}"
        else:
            grouping = "(US Total)"

        # ── Special RECS/EIA view types ──
        quantity_name = self.quantity.label if self.quantity != DataCol.ALL else "Enduse"

        if self.quantity == DataCol.UNITS_COUNT:
            return f"Number of Occupied Dwelling Units {grouping}"

        if self.view == ViewType.penetration:
            usage_name = "the specified End Use" if self.quantity == DataCol.ALL else self.quantity.penetration_label
            return f"Share of Dwelling Units using {usage_name} {grouping}"

        if self.view == ViewType.distribution:
            return f"Distribution of {quantity_name} Consumption {self._per_unit_label} {grouping}"

        # ── Common pattern: "{Period} {Quantity} Consumption {Per} {Grouping}" ──
        period = _PERIOD_LABEL.get(self.resolution, "Annual")

        if self.aggregation_type == AggregationType.total:
            return f"{period} {quantity_name} Consumption {grouping}"

        return f"Average {period} {quantity_name} Consumption {self._per_unit_label} {grouping}"

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
    def display_metric(self) -> str:
        """Metric facet label — title-aligned, without quantity name or grouping.

        Examples:
            "Annual Consumption" (total, year)
            "Average Monthly Consumption per Dwelling Unit" (average, month, all_units)
            "Distribution of Consumption per Dwelling Unit" (distribution)
            "Load Duration Curve of Electricity Consumption per Dwelling Unit" (LRD)
        """
        if self.comparison_dataset == ComparisonDataset.lrd:
            # LRD metric IS the full display_title (no grouping to strip)
            return self.display_title

        if self.quantity == DataCol.UNITS_COUNT:
            return "Number of Occupied Dwelling Units"

        if self.view == ViewType.penetration:
            return "Enduse Penetration"

        if self.view == ViewType.distribution:
            return f"Distribution of Consumption {self._per_unit_label}"

        period = _PERIOD_LABEL.get(self.resolution, "Annual")
        if self.aggregation_type == AggregationType.total:
            return f"{period} Consumption"

        return f"Average {period} Consumption {self._per_unit_label}"

    @property
    def display_group_by(self) -> str:
        """Group-by facet label: 'State', 'Census Division', 'Utility', etc."""
        if not self.group_by:
            return ""
        return format_group_by(self.group_by)

    @property
    def display_viz_label(self) -> str:
        """Visualization type label for the HTML index.

        Examples: 'tilemap bar plot', 'grouped bar plot (difference)', 'daily load shape'
        """
        label = self._base_viz_label
        if self.view == ViewType.diff_view:
            label += " (difference)"
        return label

    @property
    def _base_viz_label(self) -> str:
        """Base visualization type label before view-type suffixes."""
        if self.view == ViewType.distribution:
            return "grouped box plot"

        if self.quantity == DataCol.ALL:
            return "grouped bar plot"

        # LRD-specific resolutions (year/month fall through to shared tilemap block)
        if self.comparison_dataset == ComparisonDataset.lrd:
            if self.resolution == Resolution.day_of_year:
                return "stack of timeseries plot"
            if self.resolution == Resolution.hour_of_day_matrix:
                return "daily load shape matrix"
            if self.resolution in (Resolution.hour_of_day, Resolution.hour_of_day_summer, Resolution.hour_of_day_winter):
                return "daily load shape"
            if self.resolution in (Resolution.hour_of_year, Resolution.top_100_hours):
                if self.view == ViewType.temp_view:
                    return "temperature relation"
                if self.view == ViewType.temp_distribution_view:
                    return "temperature distribution"
                return "load duration curve"

        # Tilemap layouts for state/utility grouping (shared by EIA, RECS, LRD)
        if self.group_by in (DataCol.STATE, DataCol.UTILITY):
            if self.resolution == Resolution.year:
                return "tilemap bar plot"
            if self.resolution == Resolution.month:
                return "tilemap timeseries plot"

        return "grouped bar plot"

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
        # Append coverage and view to filename so different specs don't overwrite each other
        if self.coverage != CoverageType.all_units:
            title = title + f" ({self.coverage})"
        if self.view != ViewType.value_view:
            title = title + f" ({self.view})"
        # Focus entries go at the top of the path hierarchy
        filter_dir = Path()
        for char, value in self.focus_on:
            filter_dir /= f"By {format_group_by(char)}"
            filter_dir /= format_focus_label(value)
        if self.group_by:
            path_segment = filter_dir / f"By {format_group_by(self.group_by)}"
            path_segment /= "All"  # overview within the aggregation
        else:
            path_segment = filter_dir
        return path_segment, title
