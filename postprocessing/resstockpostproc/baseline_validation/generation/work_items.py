"""Template/work-item expansion helpers for baseline validation plot generation.

Extracted from plot_generator.py in refactor plan V2 step 3.1. These helpers
turn PlotTemplates into concrete work items (PlotSpecs + focus/label tuples)
ready for rendering.
"""

from __future__ import annotations

import logging
from collections import defaultdict

from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.shared_utils.mapping import ABBR2STATE
from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    ComparisonDataset,
    Resolution,
    Layout,
    CoverageType,
    format_group_by,
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
from resstockpostproc.baseline_validation.generation.index_rows import (
    apply_lrd_sidebar_semantics,
    build_output_row,
)
from resstockpostproc.baseline_validation.generation.render_runner import render_key
from resstockpostproc.baseline_validation.generation.stacked_pages import (
    all_enduses_viz_label,
)

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


def build_render_gate(templates: list[PlotTemplate], test_only: bool) -> set[tuple] | None:
    """Return the render-key whitelist for --test runs, or None for full runs.

    Under --test, Pass 2 still emits every TSV row (so the index matches a
    full run), but Pass 3 renders only items whose render_key is in this set.
    """
    if not test_only:
        return None
    subset_tmpl_idx = get_test_template_indices(templates)
    subset_to_full_idx = sorted(subset_tmpl_idx)
    subset_templates = [templates[i] for i in subset_to_full_idx]
    subset_items = expand_templates(subset_templates, test_only=True)
    render_keys: set[tuple] = set()
    for item in subset_items:
        _, subset_ti, _, focus_val, focus_on, group_by = item
        full_ti = subset_to_full_idx[subset_ti]
        render_keys.add((full_ti, focus_on, focus_val, group_by))
    logger.info(f"--test render gate: {len(render_keys)} items will actually render")
    return render_keys


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


# ---------------------------------------------------------------------------
# Pass 2: build per-work-item metadata + plot_args + stacking_groups
# ---------------------------------------------------------------------------


def _make_sub_key(
    focus_on: tuple,
    focus_val: object,
    tmpl_index: int,
    group_by: str | None,
) -> str:
    """Compose the unique sub_key identifying this work item in results."""
    agg_suffix = f"_by_{group_by}" if group_by else ""
    if focus_on:
        filter_parts = "_".join(f"{c}_{v}" for c, v in focus_on)
        if focus_val is None:
            return f"f_{filter_parts}_{tmpl_index}{agg_suffix}"
        return f"f_{filter_parts}_{tmpl_index}_{focus_val}"
    if focus_val is None:
        return f"{tmpl_index}{agg_suffix}"
    return f"{tmpl_index}_{focus_val}"


def _compute_final_focus(
    focus_on: tuple,
    focus_val: object,
    group_by: str | None,
) -> tuple[tuple, str | None]:
    """Return (final_focus_on, final_agg) for the leaf plot."""
    final_focus_tuples = list(focus_on)
    if focus_val is not None and group_by is not None:
        final_focus_tuples.append((group_by, focus_val))
    final_focus_on = tuple(final_focus_tuples)
    final_agg = group_by if focus_val is None else None
    return final_focus_on, final_agg


def _build_display_spec(
    main_spec: PlotSpec,
    group_by: str | None,
    final_focus_on: tuple,
) -> PlotSpec:
    """Build the concrete display PlotSpec with group_by for the index row."""
    default_group = final_focus_on[0][0] if final_focus_on else "state"
    return _make_spec(
        comparison_dataset=main_spec.comparison_dataset,
        quantity=main_spec.quantity,
        resolution=main_spec.resolution,
        aggregation_type=main_spec.aggregation_type,
        coverage=main_spec.coverage,
        group_by=group_by or default_group,
        view=main_spec.view,
    )


def _format_filter_cell(char: str, value: str) -> str:
    """Format one (char, value) focus tuple into a display filter-cell string."""
    if value == "US Total":
        return ""
    display = ABBR2STATE.get(value, value) if char == "state" else value
    return f"{format_group_by(char)}: {display}"


def _populate_filter_cells(row: dict, final_focus_on: tuple) -> None:
    """Fill row's Filter 1/2 cells from the final focus tuples."""
    for idx, (char, value) in enumerate(final_focus_on):
        row[f"Filter {idx + 1}"] = _format_filter_cell(char, value)


def _build_focused_entries(
    spec_entries: list,
    final_focus_on: tuple,
    final_agg: str | None,
) -> list[tuple[PlotSpec, str]]:
    """Build the per-work-item (focused_spec, viz_label) list for rendering."""
    focused_entries: list[tuple[PlotSpec, str]] = []
    for spec, _ in spec_entries:
        focused_spec = spec.model_copy(update={
            "focus_on": final_focus_on,
            "group_by": final_agg,
        })
        if not emit_layout_for_final_group(focused_spec, final_agg):
            continue
        viz_label = (
            all_enduses_viz_label(focused_spec, stacked=False)
            if focused_spec.is_all_enduses
            else focused_spec.display_viz_label
        )
        focused_entries.append((focused_spec, viz_label))
    return focused_entries


def _stacking_group_key(row: dict) -> tuple:
    """Return the 6-field key used to bucket rows for 'All Enduses (Stacked)'."""
    return (
        row["Comparison Dataset"],
        row["Metric"],
        row["Coverage"],
        row["Filter 1"],
        row["Filter 2"],
        row["Group By"],
    )


def build_plot_args(
    work_items: list,
    render_keys: set[tuple] | None,
) -> tuple[
    dict[str, dict[str, str]],
    list[tuple[str, list, bool]],
    dict[tuple, list],
]:
    """Build per-work-item rows, focused entries, and stacking groups.

    Returns:
        (results, plot_args, stacking_groups) — the three outputs Pass 3 and
        Pass 4 consume.

    """
    results: dict[str, dict[str, str]] = {}
    plot_args: list[tuple[str, list, bool]] = []
    stacking_groups: dict[tuple, list] = defaultdict(list)

    for i, work_item in enumerate(work_items, 1):
        spec_family, tmpl_index, spec_entries, focus_val, focus_on, group_by = work_item
        main_spec = spec_family[0]

        is_dry_run = render_keys is not None and render_key(work_item) not in render_keys

        sub_key = _make_sub_key(focus_on, focus_val, tmpl_index, group_by)
        final_focus_on, final_agg = _compute_final_focus(focus_on, focus_val, group_by)
        display_spec = _build_display_spec(main_spec, group_by, final_focus_on)

        row = build_output_row(display_spec)
        row["Index"] = i
        if final_agg is None:
            row["Group By"] = ""
        row["Comparison Plot"] = ""
        _populate_filter_cells(row, final_focus_on)
        apply_lrd_sidebar_semantics(row, display_spec, final_focus_on)
        results[sub_key] = row

        focused_entries = _build_focused_entries(spec_entries, final_focus_on, final_agg)
        if not focused_entries:
            continue

        plot_args.append((sub_key, focused_entries, is_dry_run))

        # Skip ALL (already stacked) and UNITS_COUNT (not an enduse).
        if main_spec.quantity in (DataCol.ALL, DataCol.UNITS_COUNT):
            continue
        stacking_groups[_stacking_group_key(row)].append((
            display_spec.display_quantity,
            focused_entries,
        ))

    return results, plot_args, stacking_groups
