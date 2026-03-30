"""Generate baseline validation plot templates and slot triples.

PlotTemplates describe WHAT to plot (metric identity + eligible chars).
generate_slot_triples() enumerates HOW to slice it (filter_1, filter_2,
aggregation_level). The expansion loop in plot_generator.py combines these
to produce concrete PlotSpec objects for each data slice.

Usage:
    templates = generate_all_templates()
    triples = generate_slot_triples(template.eligible_chars, allow_cross_filter=True)
"""

from __future__ import annotations

from collections.abc import Iterator
from dataclasses import dataclass

from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.baseline_validation.schema.plot_spec import (
    GEOGRAPHIC_DIMENSIONS,
    PlotSpec,
    AggregationType,
    CoverageType,
    Resolution,
    TruthSource,
    ViewType,
)

# ─────────────────────────────────────────────────────────────────────────────
# Constants: what combinations are valid per truth source
# ─────────────────────────────────────────────────────────────────────────────

EIA_QUANTITIES: list[DataCol] = [
    DataCol.UNITS_COUNT,
    DataCol.ELECTRICITY_TOTAL,
    DataCol.NATURAL_GAS_TOTAL,
]

RECS_QUANTITIES: list[DataCol] = [
    DataCol.UNITS_COUNT,
    DataCol.ALL,
    DataCol.ELECTRICITY_TOTAL,
    DataCol.NATURAL_GAS_TOTAL,
    DataCol.ELECTRICITY_SPACE_COOLING,
    DataCol.ELECTRICITY_SPACE_HEATING,
    DataCol.ELECTRICITY_WATER_HEATING,
    DataCol.NATURAL_GAS_SPACE_HEATING,
    DataCol.NATURAL_GAS_WATER_HEATING,
    DataCol.ELECTRICITY_PLUG_LOADS,
    DataCol.ELECTRICITY_REFRIGERATOR,
    DataCol.ELECTRICITY_LIGHTING,
    DataCol.ELECTRICITY_TELEVISION,
    DataCol.ELECTRICITY_CLOTHES_DRYER,
    DataCol.ELECTRICITY_COOLING_FAN_PUMPS,
    DataCol.ELECTRICITY_HEATING_FANS_PUMPS,
    DataCol.ELECTRICITY_FREEZER,
    DataCol.ELECTRICITY_COOKING,
    DataCol.ELECTRICITY_POOL_PUMPS,
    DataCol.ELECTRICITY_CEILING_FANS,
    DataCol.ELECTRICITY_DISHWASHER,
    DataCol.ELECTRICITY_CLOTHES_WASHER,
    DataCol.ELECTRICITY_POOL_HEATER,
    DataCol.ELECTRICITY_EV_CHARGING,
    DataCol.NATURAL_GAS_COOKING,
    DataCol.NATURAL_GAS_POOL_HEATER,
    DataCol.NATURAL_GAS_CLOTHES_DRYER,
    DataCol.PROPANE_TOTAL,
    DataCol.PROPANE_SPACE_HEATING,
    DataCol.PROPANE_WATER_HEATING,
    DataCol.PROPANE_COOKING,
    DataCol.PROPANE_CLOTHES_DRYER,
    DataCol.FUEL_OIL_TOTAL,
    DataCol.FUEL_OIL_SPACE_HEATING,
    DataCol.FUEL_OIL_WATER_HEATING,
]

LRD_QUANTITIES: list[DataCol] = [DataCol.ELECTRICITY_TOTAL]

EIA_GROUP_BYS = ["state"]

RECS_GROUP_BYS = [
    "state",
    "census_division_recs",
    "geometry_building_type_recs",
    "vintage",
    "building_america_climate_zone",
    "heating_fuel",
]

LRD_GROUP_BYS = ["eiaid"]

# ─────────────────────────────────────────────────────────────────────────────
# Eligible chars per source / resolution
# ─────────────────────────────────────────────────────────────────────────────
# The ordering matters: Filter 2 can only use chars that come AFTER Filter 1
# in this tuple (upper-triangle dedup). Keep geographic dimensions together
# at the front so the geographic exclusion logic is transparent.

RECS_ANNUAL_CHARS = tuple(RECS_GROUP_BYS)  # all 6 chars available
RECS_MONTHLY_CHARS = ("state",)  # monthly RECS data is pre-aggregated at state level
EIA_CHARS = ("state",)  # EIA only supports state-level grouping
LRD_CHARS = ("eiaid",)  # LRD only supports utility-level grouping


@dataclass(frozen=True)
class PlotTemplate:
    """Describes WHAT to plot, without specifying HOW to slice it.

    A PlotTemplate captures the metric identity (source, quantity, resolution,
    aggregation_type, coverage, view) and the ordered set of eligible
    characteristics available for the (F1, F2, agg_level) slot triple expansion.

    The aggregation_level and focus_on are NOT part of the template — those are
    determined by the slot triple generator and the expansion loop.
    """

    truth_source: TruthSource
    quantity: DataCol
    resolution: Resolution
    aggregation_type: AggregationType
    coverage: CoverageType
    view: ViewType
    eligible_chars: tuple[str, ...]


SlotTriple = tuple[str | None, str | None, str | None]
"""(filter_1, filter_2, aggregation_level) — None means the slot is unused."""


def _is_geo_conflict(a: str | None, b: str | None) -> bool:
    """Return True if both a and b are geographic dimensions."""
    return (a in GEOGRAPHIC_DIMENSIONS) and (b in GEOGRAPHIC_DIMENSIONS)


def generate_slot_triples(
    eligible_chars: tuple[str, ...],
    allow_cross_filter: bool = False,
) -> list[SlotTriple]:
    """Generate all valid (filter_1, filter_2, aggregation_level) triples.

    Args:
        eligible_chars: Ordered tuple of available characteristics. The ordering
            determines the upper-triangle dedup: F2 can only use chars that come
            AFTER F1 in this tuple, preventing (A,B)/(B,A) duplicates.
        allow_cross_filter: When True, allow triples where F1 is set AND
            aggregation_level is set (cross-dimension filtering). Only valid for
            sources with microdata (RECS annual).

    Returns:
        List of (F1, F2, agg_level) triples. Each value is a char name or None.

    Rules:
        - F1=None → F2 must be None; agg_level can be any char or None
        - F1=char[i], F2=None → agg_level can be any char except F1 (or None),
          subject to geographic exclusion. Requires allow_cross_filter when
          agg_level is not None.
        - F1=char[i], F2=char[j>i] → agg_level must be None.
          Requires allow_cross_filter (since F1 is a filter on a grouping dim).
        - No two geographic dimensions may appear in the same triple.
    """
    triples: list[SlotTriple] = []

    # --- Block 1: F1=None (base plots) ---
    # Overview with no grouping
    triples.append((None, None, None))
    # Grouped by each eligible char
    for char in eligible_chars:
        triples.append((None, None, char))

    if not allow_cross_filter:
        # Without cross-filter, F1 can only be used as a same-dimension
        # focus (drilling into one entity of the aggregation_level).
        # That expansion is handled by focus_val in the main loop, not here.
        return triples

    # --- Block 2: F1=char (cross-filter — requires allow_cross_filter) ---
    for i, f1 in enumerate(eligible_chars):
        # F1 set, F2=None, agg=None (filtered, no sub-grouping)
        triples.append((f1, None, None))

        # F1 set, F2=None, agg=other char (cross-filter with sub-grouping)
        for agg in eligible_chars:
            if agg == f1:
                continue
            if _is_geo_conflict(f1, agg):
                continue
            triples.append((f1, None, agg))

        # F1 set, F2=char[j>i], agg=None (two-filter drill-down)
        for j in range(i + 1, len(eligible_chars)):
            f2 = eligible_chars[j]
            if _is_geo_conflict(f1, f2):
                continue
            triples.append((f1, f2, None))

    return triples


# Quantities with monthly resolution in RECS
RECS_MONTHLY_QUANTITIES: set[DataCol] = {
    DataCol.ELECTRICITY_TOTAL,
    DataCol.NATURAL_GAS_TOTAL,
    DataCol.ELECTRICITY_SPACE_COOLING,
    DataCol.ELECTRICITY_SPACE_HEATING,
    DataCol.ELECTRICITY_WATER_HEATING,
    DataCol.NATURAL_GAS_SPACE_HEATING,
    DataCol.NATURAL_GAS_WATER_HEATING,
}

# 100% penetration — users-only coverage and penetration rows are meaningless
RECS_FULL_PENETRATION: set[DataCol] = {DataCol.ELECTRICITY_TOTAL}

# Quantities highlighted on RECS monthly + state rows
RECS_HIGHLIGHT_MONTHLY: set[DataCol] = {
    DataCol.ELECTRICITY_TOTAL,
    DataCol.NATURAL_GAS_TOTAL,
    DataCol.ELECTRICITY_SPACE_COOLING,
    DataCol.ELECTRICITY_SPACE_HEATING,
    DataCol.ELECTRICITY_WATER_HEATING,
    DataCol.NATURAL_GAS_SPACE_HEATING,
    DataCol.NATURAL_GAS_WATER_HEATING,
}

# LRD metric tuples: (Resolution, ViewType)
# All LRD metrics are average + all_units (enforced by PlotSpec validators)
_LRD_METRICS: list[tuple[Resolution, ViewType]] = [
    (Resolution.year, ViewType.value_view),
    (Resolution.month, ViewType.value_view),
    (Resolution.day_of_year, ViewType.value_view),
    (Resolution.hour_of_day, ViewType.value_view),
    (Resolution.hour_of_day_summer, ViewType.value_view),
    (Resolution.hour_of_day_winter, ViewType.value_view),
    (Resolution.hour_of_day_matrix, ViewType.value_view),
    (Resolution.hour_of_year, ViewType.value_view),
    (Resolution.top_100_hours, ViewType.value_view),
]

SpecPair = tuple[PlotSpec, PlotSpec | None]


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

def _extra_view_for(spec: PlotSpec) -> ViewType | None:
    """Determine the companion extra-view for a main spec, or None."""
    if spec.quantity == DataCol.ALL:
        return ViewType.diff_view

    if spec.truth_source == TruthSource.lrd:
        if spec.resolution == Resolution.year:
            return ViewType.diff_view
        if spec.resolution == Resolution.hour_of_year and spec.view == ViewType.value_view:
            # 8760 load duration curve does NOT get diff_view;
            # temperature views are separate specs, not extras
            return None
        if spec.view == ViewType.temp_view:
            return ViewType.temp_distribution_view
        return None

    # EIA/RECS state or utility with annual resolution → diff view
    if spec.aggregation_level in ("state", "eiaid"):
        if spec.resolution == Resolution.year:
            return ViewType.diff_view
        return None  # monthly tilemaps don't get diff view

    # Non-state grouped bars → diff view
    if spec.view in (ViewType.value_view, ViewType.penetration):
        return ViewType.diff_view

    return None


def _make_pair(spec: PlotSpec) -> SpecPair:
    """Build a (main_spec, extra_spec_or_None) pair."""
    extra_view = _extra_view_for(spec)
    if extra_view:
        extra = spec.model_copy(update={"view": extra_view})
        return (spec, extra)
    return (spec, None)


def _make_spec(
    truth_source: TruthSource,
    quantity: DataCol,
    resolution: Resolution,
    aggregation_type: AggregationType,
    coverage: CoverageType,
    aggregation_level: str | None,
    view: ViewType = ViewType.value_view,
) -> PlotSpec:
    return PlotSpec(
        truth_source=truth_source,
        quantity=quantity,
        resolution=resolution,
        aggregation_type=aggregation_type,
        coverage=coverage,
        aggregation_level=aggregation_level,
        view=view,
    )


# ─────────────────────────────────────────────────────────────────────────────
# Highlight
# ─────────────────────────────────────────────────────────────────────────────

def is_highlight(spec: PlotSpec) -> bool:
    """Return True if this spec is a key summary plot to feature prominently."""
    ts = spec.truth_source
    q = spec.quantity
    agg = spec.aggregation_level
    res = spec.resolution

    if ts == TruthSource.eia and q == DataCol.UNITS_COUNT and agg == "state":
        return True
    if ts == TruthSource.recs and q == DataCol.UNITS_COUNT and agg in ("state", "vintage"):
        return True
    if ts == TruthSource.recs and q == DataCol.ALL and res == Resolution.year and spec.view != ViewType.penetration:
        return True
    if ts == TruthSource.eia and q in (DataCol.ELECTRICITY_TOTAL, DataCol.NATURAL_GAS_TOTAL) and agg == "state" and res == Resolution.month:
        return True
    if ts == TruthSource.recs and q in RECS_HIGHLIGHT_MONTHLY and agg == "state" and res == Resolution.month:
        return True
    if ts == TruthSource.lrd and res in (Resolution.month, Resolution.day_of_year, Resolution.hour_of_year):
        if spec.view == ViewType.value_view:
            return True
    if ts == TruthSource.lrd and spec.view == ViewType.temp_view:
        return True
    return False


# ─────────────────────────────────────────────────────────────────────────────
# Template generators
# ─────────────────────────────────────────────────────────────────────────────

def _eia_templates() -> Iterator[PlotTemplate]:
    """Generate EIA plot templates (no aggregation_level baked in)."""
    mk = lambda q, res, agg_type, cov, view=ViewType.value_view: PlotTemplate(
        truth_source=TruthSource.eia, quantity=q, resolution=res,
        aggregation_type=agg_type, coverage=cov, view=view,
        eligible_chars=EIA_CHARS,
    )
    for quantity in EIA_QUANTITIES:
        if quantity == DataCol.UNITS_COUNT:
            yield mk(DataCol.UNITS_COUNT, Resolution.year, AggregationType.total, CoverageType.all_units)
            continue

        for res, agg_type in [
            (Resolution.year, AggregationType.total),
            (Resolution.year, AggregationType.average),
            (Resolution.month, AggregationType.total),
            (Resolution.month, AggregationType.average),
        ]:
            yield mk(quantity, res, agg_type, CoverageType.all_units)

        if quantity == DataCol.NATURAL_GAS_TOTAL:
            for res in (Resolution.year, Resolution.month):
                yield mk(quantity, res, AggregationType.average, CoverageType.users_only)
            yield mk(quantity, Resolution.year, AggregationType.total,
                     CoverageType.all_units, ViewType.penetration)


def _all_enduses_templates() -> Iterator[PlotTemplate]:
    """Emit the 6 All Enduses templates."""
    mk = lambda agg, cov, view: PlotTemplate(
        truth_source=TruthSource.recs, quantity=DataCol.ALL, resolution=Resolution.year,
        aggregation_type=agg, coverage=cov, view=view,
        eligible_chars=RECS_ANNUAL_CHARS,
    )
    yield mk(AggregationType.total, CoverageType.all_units, ViewType.value_view)
    yield mk(AggregationType.average, CoverageType.all_units, ViewType.value_view)
    yield mk(AggregationType.average, CoverageType.users_only, ViewType.value_view)
    yield mk(AggregationType.average, CoverageType.all_units, ViewType.distribution)
    yield mk(AggregationType.average, CoverageType.users_only, ViewType.distribution)
    yield mk(AggregationType.total, CoverageType.all_units, ViewType.penetration)


def _recs_energy_templates(quantity: DataCol) -> Iterator[PlotTemplate]:
    """Emit all templates for one RECS energy quantity."""
    has_monthly = quantity in RECS_MONTHLY_QUANTITIES
    skip_users = quantity in RECS_FULL_PENETRATION

    mk = lambda res, agg_type, cov, view=ViewType.value_view, chars=RECS_ANNUAL_CHARS: PlotTemplate(
        truth_source=TruthSource.recs, quantity=quantity, resolution=res,
        aggregation_type=agg_type, coverage=cov, view=view,
        eligible_chars=chars,
    )

    # Annual templates (all 6 chars eligible)
    yield mk(Resolution.year, AggregationType.total, CoverageType.all_units)
    yield mk(Resolution.year, AggregationType.average, CoverageType.all_units)
    if not skip_users:
        yield mk(Resolution.year, AggregationType.average, CoverageType.users_only)
    yield mk(Resolution.year, AggregationType.average, CoverageType.all_units, ViewType.distribution)
    if not skip_users:
        yield mk(Resolution.year, AggregationType.average, CoverageType.users_only, ViewType.distribution)
        yield mk(Resolution.year, AggregationType.total, CoverageType.all_units, ViewType.penetration)

    # Monthly templates (only state eligible)
    if has_monthly:
        yield mk(Resolution.month, AggregationType.total, CoverageType.all_units, chars=RECS_MONTHLY_CHARS)
        yield mk(Resolution.month, AggregationType.average, CoverageType.all_units, chars=RECS_MONTHLY_CHARS)
        if not skip_users:
            yield mk(Resolution.month, AggregationType.average, CoverageType.users_only, chars=RECS_MONTHLY_CHARS)


def _recs_templates() -> Iterator[PlotTemplate]:
    """Generate all RECS plot templates."""
    for quantity in RECS_QUANTITIES:
        if quantity == DataCol.UNITS_COUNT:
            yield PlotTemplate(
                truth_source=TruthSource.recs, quantity=DataCol.UNITS_COUNT,
                resolution=Resolution.year, aggregation_type=AggregationType.total,
                coverage=CoverageType.all_units, view=ViewType.value_view,
                eligible_chars=RECS_ANNUAL_CHARS,
            )
        elif quantity == DataCol.ALL:
            yield from _all_enduses_templates()
        else:
            yield from _recs_energy_templates(quantity)


def _lrd_templates() -> Iterator[PlotTemplate]:
    """Generate all LRD plot templates."""
    for quantity in LRD_QUANTITIES:
        for resolution, view in _LRD_METRICS:
            yield PlotTemplate(
                truth_source=TruthSource.lrd, quantity=quantity,
                resolution=resolution, aggregation_type=AggregationType.average,
                coverage=CoverageType.all_units, view=view,
                eligible_chars=LRD_CHARS,
            )
            if resolution == Resolution.hour_of_year:
                yield PlotTemplate(
                    truth_source=TruthSource.lrd, quantity=quantity,
                    resolution=resolution, aggregation_type=AggregationType.average,
                    coverage=CoverageType.all_units, view=ViewType.temp_view,
                    eligible_chars=LRD_CHARS,
                )


def generate_all_templates() -> list[PlotTemplate]:
    """Generate the complete ordered list of plot templates.

    Each template describes a metric to plot (source, quantity, resolution, etc.)
    along with the eligible characteristics for slot triple expansion.
    The aggregation_level and focus_on are NOT baked in — those are determined
    by generate_slot_triples() in the expansion loop.
    """
    from itertools import chain
    return list(chain(_eia_templates(), _recs_templates(), _lrd_templates()))


