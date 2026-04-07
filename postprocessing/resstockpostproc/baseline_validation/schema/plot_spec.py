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
    diff_view = "difference view"  # Shows percent difference with truth source as the main plot
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

    group_by is a sorted tuple of column names the data must be grouped by.
    For single-dimension plots: ("state",) or ("eiaid",).
    For cross-dimension plots: ("census_division_recs", "state").

    focus_on values are NOT included here — they are cheap post-aggregation
    filters applied after data loading.
    """

    truth_source: TruthSource
    group_by: tuple[str, ...]
    resolution: Resolution
    aggregation_type: AggregationType
    coverage: CoverageType

    def __str__(self) -> str:
        return f"DataKey({self.truth_source}, {self.group_by}, {self.resolution}, {self.aggregation_type}, {self.coverage})"


# Map characteristic keys to human-readable directory names for focus_on output paths
FILTER_CHAR_DISPLAY = {
    "state": "By State",
    "geometry_building_type_recs": "By Building Type",
    "vintage": "By Vintage",
    "census_division_recs": "By Census Division",
    "heating_fuel": "By Heating Fuel",
    "building_america_climate_zone": "By Climate Zone",
}


# ─────────────────────────────────────────────────────────────────────────────
# Display label functions
#
# These derive human-readable strings from PlotSpec fields. Used by both the
# plotters (figure titles) and the HTML index (filter facets / column values).
# ─────────────────────────────────────────────────────────────────────────────

AGGREGATION_LEVEL_LABELS = {
    "census_division_recs": "Census Division",
    "geometry_building_type_recs": "Building Type",
    "building_america_climate_zone": "Climate Zone",
    "heating_fuel": "Heating Fuel",
    "state": "State",
    "eiaid": "Utility",
}


def format_aggregation_level(agg_level: str) -> str:
    """Convert an aggregation level column name to a display label.

    Examples: "census_division_recs" → "Census Division", "state" → "State"
    """
    return AGGREGATION_LEVEL_LABELS.get(agg_level, agg_level.replace("_", " ").title())


def format_focus_label(value: str) -> str:
    """Convert a raw focus_on value to a human-readable display label.

    "US Total" → "U.S. Total", state abbreviations → full names, others pass through.
    """
    from resstockpostproc.shared_utils.mapping import ABBR2STATE
    if value == "US Total":
        return "U.S. Total"
    if value in ABBR2STATE:
        return ABBR2STATE[value]
    return value


def _build_recs_eia_display_title(spec: PlotSpec) -> str:
    """Build publication-quality title for RECS/EIA plots.

    Examples:
        "Average Monthly Electricity Consumption per Dwelling Unit by State"
        "Distribution of Electricity Consumption per Consuming Dwelling Unit by State"
        "Share of Dwelling Units using Refrigerator by State"
        "Number of Occupied Dwelling Units by State"
    """
    quantity_name = spec.quantity.label if spec.quantity != DataCol.ALL else "Enduse"
    agg_label = format_aggregation_level(spec.aggregation_level) if spec.aggregation_level else ""
    # Build grouping label from focus_on display and aggregation_level
    focus_display = spec.get_filter_display_name()
    if focus_display and agg_label:
        grouping = f"({focus_display} only) by {agg_label}"
    elif focus_display:
        grouping = f"({focus_display})"
    elif agg_label:
        grouping = f"by {agg_label}"
    else:
        grouping = "(US Total)"
    is_monthly = spec.resolution == Resolution.month

    # Dwelling unit count case
    if spec.quantity == DataCol.UNITS_COUNT:
        return f"Number of Occupied Dwelling Units {grouping}"

    # Penetration view
    if spec.view == ViewType.penetration:
        if spec.quantity == DataCol.ALL:
            usage_name = "the specified End Use"
        else:
            usage_name = spec.quantity.penetration_label
        return f"Share of Dwelling Units using {usage_name} {grouping}"

    # Distribution view
    if spec.view == ViewType.distribution:
        per = "per Consuming Dwelling Unit" if spec.coverage == CoverageType.users_only else "per Dwelling Unit"
        return f"Distribution of {quantity_name} Consumption {per} {grouping}"

    # Total aggregation
    period = "Monthly" if is_monthly else "Annual"
    if spec.aggregation_type == AggregationType.total:
        return f"{period} {quantity_name} Consumption {grouping}"

    # Average aggregation
    per = "per Consuming Dwelling Unit" if spec.coverage == CoverageType.users_only else "per Dwelling Unit"
    return f"Average {period} {quantity_name} Consumption {per} {grouping}"


def _build_lrd_display_title(spec: PlotSpec) -> str:
    """Build title for LRD plots based on resolution."""
    match spec.resolution:
        case Resolution.year:
            return "Annual Electricity Consumption per Dwelling Unit"
        case Resolution.month:
            return "Monthly Electricity Consumption per Dwelling Unit"
        case Resolution.day_of_year:
            return "Daily Electricity Consumption per Dwelling Unit"
        case Resolution.hour_of_year | Resolution.top_100_hours:
            if spec.view == ViewType.temp_view:
                return "Load vs Outdoor Drybulb Temperature"
            if spec.view == ViewType.temp_distribution_view:
                return "Count of Number of Hours vs Outdoor Drybulb Temperature"
            title = "Load Duration Curve of Electricity Consumption per Dwelling Unit"
            if spec.resolution == Resolution.top_100_hours:
                title += " (Top 100 Hours)"
            return title
        case Resolution.hour_of_day:
            return "Average Daily Electricity Consumption per Dwelling Unit"
        case Resolution.hour_of_day_summer:
            return "Average Summer Day Hourly Electricity Consumption per Dwelling Unit"
        case Resolution.hour_of_day_winter:
            return "Average Winter Day Hourly Electricity Consumption per Dwelling Unit"
        case Resolution.hour_of_day_matrix:
            focus_display = ", ".join(v for _, v in spec.focus_on)
            return f"Hourly Load Profile Matrix for {focus_display}"
        case _:
            raise ValueError(f"Unsupported resolution '{spec.resolution}' for LRD plot.")


def _build_recs_eia_metric_label(spec: PlotSpec) -> str:
    """Build the metric facet label — the title without quantity name and grouping.

    This is the "shape" of the comparison, aligned with the plot title vocabulary.

    Examples:
        "Annual Consumption" (total, year)
        "Average Monthly Consumption per Dwelling Unit" (average, month, all_units)
        "Average Annual Consumption per Consuming Dwelling Unit" (average, year, users_only)
        "Distribution of Consumption per Dwelling Unit" (distribution)
        "Enduse Penetration" (penetration)
    """
    if spec.quantity == DataCol.UNITS_COUNT:
        return "Number of Occupied Dwelling Units"

    if spec.view == ViewType.penetration:
        return "Enduse Penetration"

    if spec.view == ViewType.distribution:
        per = "per Consuming Dwelling Unit" if spec.coverage == CoverageType.users_only else "per Dwelling Unit"
        return f"Distribution of Consumption {per}"

    period = "Monthly" if spec.resolution == Resolution.month else "Annual"
    if spec.aggregation_type == AggregationType.total:
        return f"{period} Consumption"

    per = "per Consuming Dwelling Unit" if spec.coverage == CoverageType.users_only else "per Dwelling Unit"
    return f"Average {period} Consumption {per}"


class PlotSpec(NoExtraModel):
    truth_source: TruthSource = Field(..., description="Truth source for comparison plots (eia, recs, lrd).")
    aggregation_type: AggregationType = Field(..., description="Aggregation method: total or average")
    coverage: CoverageType = Field(..., description="Population coverage: all_units or users_only")
    quantity: DataCol = Field(..., description="Column(s) to visualise. Use DataCol.ALL for all enduses.")
    resolution: Resolution = Field(..., description="Time resolution: monthly / annual / hourly")
    aggregation_level: str | None = Field(
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

    @property
    def effective_group_by(self) -> tuple[str, ...]:
        """Sorted tuple of all columns the data handler must group by.

        This is the union of focus_on columns and aggregation_level, sorted
        alphabetically so that ("state", "vintage") and ("vintage", "state")
        produce the same DataKey for cache consistency.
        """
        cols = {col for col, _ in self.focus_on}
        if self.aggregation_level is not None:
            cols.add(self.aggregation_level)
        return tuple(sorted(cols))

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
        if self.truth_source != TruthSource.lrd:
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

        if len(self.focus_on) == 2 and self.aggregation_level is not None:
            raise ValueError(
                "aggregation_level must be None when focus_on has 2 filters. "
                "Data is too thin for meaningful sub-grouping with 2 filters applied."
            )

        if self.aggregation_level is not None and self.aggregation_level in seen_cols:
            raise ValueError(
                f"aggregation_level '{self.aggregation_level}' cannot also appear in focus_on. "
                "To select one entity from the aggregation, set aggregation_level=None and "
                "add (column, value) to focus_on instead."
            )

        # When focus_on is used with an aggregation_level, the focus_on columns are
        # cross-dimension filters that require microdata → RECS annual only.
        # When aggregation_level is None, focus_on columns ARE the grouping dimension
        # (same-dimension selection) and work for any truth source.
        if self.focus_on and self.aggregation_level is not None:
            if self.truth_source != TruthSource.recs:
                raise ValueError(
                    f"Cross-dimension focus_on filters are only supported for RECS "
                    f"(got truth_source={self.truth_source}). "
                    "EIA and LRD data lack building-level characteristics for filtering."
                )
            if self.resolution != Resolution.year:
                raise ValueError(
                    f"Cross-dimension focus_on filters are only supported for annual resolution "
                    f"(got {self.resolution}). "
                    "Monthly RECS data is pre-aggregated and cannot be filtered."
                )

        # No geographic-to-geographic conflicts across all group dimensions
        geo_cols = {col for col, _ in self.focus_on if col in GEOGRAPHIC_DIMENSIONS}
        if self.aggregation_level in GEOGRAPHIC_DIMENSIONS:
            geo_cols.add(self.aggregation_level)
        if len(geo_cols) > 1:
            raise ValueError(
                f"Multiple geographic dimensions found: {geo_cols}. "
                "Mixing geographic dimensions produces degenerate plots."
            )

        return self

    def get_data_key(self) -> DataKey:
        """Get the data key that uniquely identifies the base dataset for this plot.

        Uses effective_group_by (sorted union of focus_on columns + aggregation_level)
        to determine which columns the data must be grouped by.
        """
        group_by = self.effective_group_by or ("state",)
        return DataKey(
            truth_source=self.truth_source,
            group_by=group_by,
            resolution=self.resolution,
            aggregation_type=self.aggregation_type,
            coverage=self.coverage,
        )

    # ── Display labels ──────────────────────────────────────────────────
    # These derive human-readable strings for the plot figure and the HTML
    # index.  The same building blocks produce both the full title and the
    # individual facet labels (Quantity, Metric, Group By).

    def get_display_title(self) -> str:
        """Publication-quality title for the plot figure and HTML index.

        Examples:
            "Average Monthly Electricity Consumption per Dwelling Unit by State"
            "Annual Electricity Consumption per Dwelling Unit"  (LRD)
        """
        if self.truth_source == TruthSource.lrd:
            return _build_lrd_display_title(self)
        return _build_recs_eia_display_title(self)

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

        For RECS/EIA: uses _build_recs_eia_metric_label().
        For LRD: uses the full LRD title (which already excludes grouping).
        """
        if self.truth_source == TruthSource.lrd:
            return _build_lrd_display_title(self)
        return _build_recs_eia_metric_label(self)

    @property
    def display_group_by(self) -> str:
        """Group-by facet label: 'State', 'Census Division', 'Utility', etc."""
        if not self.aggregation_level:
            return ""
        return format_aggregation_level(self.aggregation_level)

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
        if self.quantity == DataCol.ALL:
            return "grouped bar plot"

        if self.truth_source == TruthSource.lrd:
            if self.resolution == Resolution.year:
                return "tilemap bar plot"
            if self.resolution == Resolution.month:
                return "tilemap timeseries plot"
            if self.resolution == Resolution.day_of_year:
                return "stack of timeseries plot"
            if self.resolution == Resolution.hour_of_day_matrix:
                return "daily load shape matrix"
            if self.resolution in (Resolution.hour_of_day_summer, Resolution.hour_of_day_winter):
                return "daily load shape"
            if self.resolution in (Resolution.hour_of_year, Resolution.top_100_hours):
                if self.view == ViewType.temp_view:
                    return "temperature relation"
                if self.view == ViewType.temp_distribution_view:
                    return "temperature distribution"
                return "load duration curve"
            if self.resolution == Resolution.hour_of_day:
                return "daily load shape"

        if self.aggregation_level in ("state", "eiaid"):
            if self.resolution == Resolution.year:
                return "tilemap bar plot"
            if self.resolution == Resolution.month:
                return "tilemap timeseries plot"

        if self.view == ViewType.distribution:
            return "grouped box plot"

        return "grouped bar plot"

    # ── File-path-style labels (for file naming) ─────────────────────────

    def get_quantity_name(self) -> str:
        if self.quantity == DataCol.ALL:
            return f"fuel {self.aggregation_type.value}"
        return f"{self.quantity.value} {self.aggregation_type.value}"

    def _get_title_prefix(self) -> str:
        qlabel = self.get_quantity_name()
        title_prefix = f"{self.truth_source} {self.resolution} {qlabel} comparison"
        return title_prefix

    def _format_focus_display(self) -> str:
        """Format focus_on entries for display in titles.

        Returns a human-readable string like 'Alaska' or 'Alaska, Single-Family Detached'.
        Returns '' if focus_on is empty.
        """
        if not self.focus_on:
            return ""
        from resstockpostproc.shared_utils.mapping import ABBR2STATE
        parts = []
        for col, value in self.focus_on:
            if col == "state":
                parts.append(ABBR2STATE.get(value, value))
            else:
                parts.append(value)
        return ", ".join(parts)

    def get_filter_suffix(self) -> str:
        """Return filter suffix for titles, e.g. ' (Alaska only)' or ''."""
        display = self._format_focus_display()
        if not display:
            return ""
        return f" ({display} only)"

    def get_filter_display_name(self) -> str:
        """Full display name for the focus_on filters.

        For state abbreviations, returns the full state name.
        For other characteristics, the value is already human-readable.
        """
        return self._format_focus_display()

    def get_title(self) -> str:
        title_prefix = self._get_title_prefix()
        focus_display = self._format_focus_display()
        if focus_display and self.aggregation_level:
            title = title_prefix + f" ({focus_display} only) by {self.aggregation_level}"
        elif focus_display:
            title = title_prefix + " for " + focus_display
        elif self.aggregation_level:
            title = title_prefix + f" by {self.aggregation_level}"
        else:
            title = title_prefix
        return title

    def get_file_path_and_name(self) -> tuple[Path, str]:
        title_prefix = self._get_title_prefix()
        title = self.get_title()
        # Append coverage and view to filename so different specs don't overwrite each other
        if self.coverage != CoverageType.all_units:
            title = title + f" ({self.coverage})"
        if self.view != ViewType.value_view:
            title = title + f" ({self.view})"
        # Focus entries go at the top of the path hierarchy
        filter_dir = Path()
        for char, value in self.focus_on:
            filter_dir /= FILTER_CHAR_DISPLAY.get(char, f"By {char}")
            filter_dir /= value
        if self.aggregation_level:
            path_segment = filter_dir / Path(title_prefix + f" by {self.aggregation_level}")
            path_segment /= "All"  # overview within the aggregation
        else:
            path_segment = filter_dir / Path(title_prefix)
        return path_segment, title
