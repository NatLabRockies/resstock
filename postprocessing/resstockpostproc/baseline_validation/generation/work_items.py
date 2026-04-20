"""Template/work-item expansion helpers for baseline validation plot generation.

Extracted from plot_generator.py in refactor plan V2 step 3.1. These helpers
turn PlotTemplates into concrete work items (PlotSpecs + focus/label tuples)
ready for rendering.
"""

from __future__ import annotations

import logging

from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    ComparisonDataset,
    Resolution,
    Layout,
    CoverageType,
)
from resstockpostproc.baseline_validation.schema.plot_definitions import (
    PlotTemplate,
    RECS_CROSS_FILTER_CHARS,
    SpecFamily,
    generate_slot_triples,
    _make_related_specs,
    _make_spec,
)
from resstockpostproc.baseline_validation.data_processing.gather_data import get_base_data

logger = logging.getLogger(__name__)


def get_test_template_indices(templates: list[PlotTemplate]) -> set[int]:
    """Return 0-based indices of templates covering unique code paths (test subset)."""
    seen: set[tuple] = set()
    test_indices: set[int] = set()
    for i, tmpl in enumerate(templates):
        sig = template_signature(tmpl)
        if sig not in seen:
            test_indices.add(i)
            seen.add(sig)
    return test_indices


def template_signature(tmpl: PlotTemplate) -> tuple:
    """Compute code-path signature for template test subset selection."""
    if tmpl.quantity == DataCol.UNITS_COUNT:
        qty_type = "units_count"
    elif tmpl.quantity == DataCol.ALL:
        qty_type = "all_enduses"
    else:
        qty_type = "regular"

    cov_type = "all" if tmpl.coverage == CoverageType.all_units else "users"

    fuel_type = None
    is_total = False
    if tmpl.quantity not in (DataCol.UNITS_COUNT, DataCol.ALL):
        val = tmpl.quantity.value
        for prefix in ("electricity", "natural_gas", "propane", "fuel_oil"):
            if val.startswith(prefix + "_"):
                fuel_type = prefix
                is_total = val == prefix + "_total"
                break

    return (
        tmpl.comparison_dataset, tmpl.resolution, tmpl.view,
        tmpl.aggregation_type, cov_type, qty_type,
        fuel_type, is_total, len(tmpl.eligible_chars),
    )


def build_spec_entries(specs: list[PlotSpec]) -> list[tuple[PlotSpec, str]]:
    """Convert a related-spec family into the spec_entries list used by the plot loop."""
    return [(spec, spec.display_viz_label) for spec in specs]


def emit_layout_for_final_group(spec: PlotSpec, final_group_by: str | None) -> bool:
    """Decide whether a spec layout should be emitted for a focused row."""
    if spec.layout == Layout.histogram:
        return spec.is_distribution_metric
    if spec.layout == Layout.two_column:
        # two_column splits a state-grouped annual bar into two columns —
        # only meaningful when the final row is actually grouped by state.
        return final_group_by == "state"
    return True


def expand_templates(
    templates: list[PlotTemplate],
    test_only: bool = False,
) -> list[tuple[SpecFamily, int, list, object, tuple, str | None]]:
    """Expand templates into work items using slot triples.

    For each template, generates all valid (F1, F2, group_by) triples, then
    expands focus values for each dimension. Each work item contains everything
    needed for Pass 2 metadata and Pass 3 plotting.

    Returns list of (spec_family, tmpl_index, spec_entries, focus_val, focus_on, group_by).
    """
    work_items = []

    for tmpl_index, tmpl in enumerate(templates):
        allow_cross = tmpl.comparison_dataset in (ComparisonDataset.recs, ComparisonDataset.eia)
        if allow_cross and tmpl.comparison_dataset == ComparisonDataset.recs and tmpl.resolution == Resolution.year:
            cross_chars = RECS_CROSS_FILTER_CHARS
        else:
            # Monthly RECS / EIA: only state can be a filter
            cross_chars = ("state",) if allow_cross else None
        triples = generate_slot_triples(
            tmpl.eligible_chars,
            allow_cross_filter=allow_cross,
            cross_filter_chars=cross_chars,
        )

        for f1_char, f2_char, group_by in triples:
            # --- Base spec construction ---
            # Use group_by when set, otherwise fall back to f1_char so that
            # Block 2 triples like (state, None, None) get the right
            # group_by for viz labels and data fetching.
            effective_agg = group_by or f1_char
            spec = _make_spec(
                comparison_dataset=tmpl.comparison_dataset,
                quantity=tmpl.quantity,
                resolution=tmpl.resolution,
                aggregation_type=tmpl.aggregation_type,
                coverage=tmpl.coverage,
                group_by=effective_agg,
                view=tmpl.view,
            )
            spec_family = _make_related_specs(spec)
            main_spec = spec_family[0]
            spec_entries = build_spec_entries(spec_family)

            # ALL enduses: skip any triple with group_by set — can't
            # group a stacked enduse chart by another dimension.
            if tmpl.quantity == DataCol.ALL and group_by is not None:
                continue

            # (None, None, None) = "US Total overview" with no grouping.
            # Synthesise a single-entity spec grouped by the template's
            # primary char, focused on "US Total".  LRD has no US Total
            # concept, so skip it entirely.
            if f1_char is None and group_by is None:
                if tmpl.comparison_dataset == ComparisonDataset.lrd:
                    continue
                # "US Total overview" — fetch state-level data but focus on
                # US Total only.  group_by stays None so downstream code
                # treats this as a single-entity plot (no Group By in index).
                default_char = tmpl.eligible_chars[0]   # "state" for RECS/EIA
                spec = _make_spec(
                    comparison_dataset=tmpl.comparison_dataset,
                    quantity=tmpl.quantity,
                    resolution=tmpl.resolution,
                    aggregation_type=tmpl.aggregation_type,
                    coverage=tmpl.coverage,
                    group_by=default_char,
                    view=tmpl.view,
                )
                spec = spec.model_copy(update={
                    "focus_on": ((default_char, "US Total"),),
                })
                spec_family = _make_related_specs(spec)
                main_spec = spec_family[0]
                spec_entries = build_spec_entries(spec_family)

            # --- Case 1: No filters (F1=None) → overview only ---
            if f1_char is None:
                # hour_of_day_matrix requires per-utility focus; expand each
                # utility as a separate work item (LRD has no Block 2 triples).
                if tmpl.resolution == Resolution.hour_of_day_matrix:
                    data_key = main_spec.data_key
                    base_data = get_base_data(data_key)
                    col = group_by
                    for val in sorted(v for v in base_data[col].unique().to_list() if v is not None):
                        work_items.append((
                            spec_family, tmpl_index, spec_entries, None,
                            ((group_by, val),), None,
                        ))
                    continue
                # Warm the disk cache so worker processes find the data.
                get_base_data(main_spec.data_key)
                # Pass focus_on from the spec so the US Total focus (set by
                # the (None,None,None) handler above) propagates to plotters.
                work_items.append((
                    spec_family, tmpl_index, spec_entries, None,
                    main_spec.focus_on, group_by,
                ))
                continue

            # --- F1 is set: discover F1 values ---
            # Use any spec with group_by=f1_char to get the data
            f1_lookup_spec = _make_spec(
                comparison_dataset=tmpl.comparison_dataset,
                quantity=tmpl.quantity,
                resolution=tmpl.resolution,
                aggregation_type=tmpl.aggregation_type,
                coverage=tmpl.coverage,
                group_by=f1_char,
                view=tmpl.view,
            )
            f1_data = get_base_data(f1_lookup_spec.data_key)
            f1_col = f1_char
            f1_values = sorted(
                v for v in f1_data[f1_col].unique().to_list()
                if v is not None and v != "US Total"
            )
            if test_only:
                f1_values = f1_values[:1]

            for f1_val in f1_values:
                # --- Case 2: F1 set, F2=None ---
                if f2_char is None:
                    if group_by is not None:
                        # Cross-filter: F1 set + group_by set → overview only
                        filtered_entries = build_filtered_entries(
                            spec_entries, ((f1_char, f1_val),),
                        )
                        if not filtered_entries:
                            continue
                        # Warm cache for the 2-column group_by DataKey that
                        # workers will request (focus_on col + group_by).
                        get_base_data(filtered_entries[0][0].data_key)
                        focus_on = ((f1_char, f1_val),)
                        work_items.append((
                            spec_family, tmpl_index, filtered_entries, None, focus_on, group_by,
                        ))
                    else:
                        # F1 set, no agg, no F2 → single filtered entity, no grouping
                        focus_on = ((f1_char, f1_val),)
                        filtered_entries = build_filtered_entries(spec_entries, focus_on)
                        if filtered_entries:
                            work_items.append((
                                spec_family, tmpl_index, filtered_entries, None, focus_on, None,
                            ))
                    continue

                # --- Case 3: F1 set, F2 set (group_by is always None) ---
                f2_lookup_spec = _make_spec(
                    comparison_dataset=tmpl.comparison_dataset,
                    quantity=tmpl.quantity,
                    resolution=tmpl.resolution,
                    aggregation_type=tmpl.aggregation_type,
                    coverage=tmpl.coverage,
                    group_by=f2_char,
                    view=tmpl.view,
                )
                f2_data = get_base_data(f2_lookup_spec.data_key)
                f2_col = f2_char

                if f2_col not in f2_data.columns:
                    continue

                f2_values = sorted(
                    v for v in f2_data[f2_col].unique().to_list()
                    if v is not None and v != "US Total"
                )
                if test_only:
                    f2_values = f2_values[:1]

                for f2_val in f2_values:
                    focus_on = ((f1_char, f1_val), (f2_char, f2_val))
                    work_items.append((
                        spec_family, tmpl_index, spec_entries, None, focus_on, None,
                    ))

    logger.info(f"Template expansion: {len(templates)} templates -> {len(work_items)} work items")
    return work_items


def build_filtered_entries(
    spec_entries: list[tuple[PlotSpec, str]],
    focus_on: tuple[tuple[str, str], ...],
) -> list[tuple[PlotSpec, str]]:
    """Build spec_entries with focus_on applied (cross-filter)."""
    filtered = []
    for spec, viz_type_str in spec_entries:
        try:
            filtered_spec = spec.model_copy(update={"focus_on": focus_on})
            filtered.append((filtered_spec, viz_type_str))
        except ValueError as e:
            logger.warning(f"Skipping filtered spec: {e}")
            continue
    return filtered
