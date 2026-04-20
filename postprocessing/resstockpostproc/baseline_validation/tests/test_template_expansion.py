"""Characterization tests for template/work-item expansion helpers."""

import polars as pl

import resstockpostproc.baseline_validation.generation.work_items as work_items_module
from resstockpostproc.baseline_validation.generation.work_items import (
    build_filtered_entries,
    build_spec_entries,
    expand_templates,
)
from resstockpostproc.baseline_validation.plot_generator import _render_key
from resstockpostproc.baseline_validation.schema.plot_definitions import (
    PlotTemplate,
    RECS_CROSS_FILTER_CHARS,
    _make_related_specs,
    _make_spec,
)
from resstockpostproc.baseline_validation.schema.plot_spec import (
    ComparisonDataset,
    CoverageType,
    Metric,
    Resolution,
    ViewType,
)
from resstockpostproc.shared_utils.db_column_names import DataCol


def _make_template(**overrides):
    defaults = dict(
        comparison_dataset=ComparisonDataset.recs,
        quantity=DataCol.ELECTRICITY_TOTAL,
        resolution=Resolution.year,
        aggregation_type=Metric.average,
        coverage=CoverageType.all_units,
        view=ViewType.value_view,
        eligible_chars=("state", "geometry_building_type_recs", "vintage"),
    )
    defaults.update(overrides)
    return PlotTemplate(**defaults)


def _install_expansion_stubs(monkeypatch, triples):
    def fake_generate_slot_triples(eligible_chars, allow_cross_filter=False, cross_filter_chars=None):
        assert eligible_chars == ("state", "geometry_building_type_recs", "vintage")
        assert allow_cross_filter is True
        assert cross_filter_chars == RECS_CROSS_FILTER_CHARS
        return triples

    base_data = {
        ("state",): pl.DataFrame({"state": ["NY", "CA", "US Total"]}),
        ("geometry_building_type_recs",): pl.DataFrame({
            "geometry_building_type_recs": ["Single-Family Detached", "Mobile Home"],
        }),
        ("state", "vintage"): pl.DataFrame({
            "state": ["CA", "NY"],
            "vintage": ["1990s", "2000s"],
        }),
    }

    def fake_get_base_data(data_key):
        key = data_key.effective_group_by
        if key not in base_data:
            raise AssertionError(f"Unexpected DataKey request: {data_key}")
        return base_data[key]

    monkeypatch.setattr(work_items_module, "generate_slot_triples", fake_generate_slot_triples)
    monkeypatch.setattr(work_items_module, "get_base_data", fake_get_base_data)


def _focus_and_group(work_items):
    return [(focus_on, group_by) for _, _, _, _, focus_on, group_by in work_items]


def test_expand_templates_characterizes_overview_and_cross_filter_items(monkeypatch):
    template = _make_template()
    _install_expansion_stubs(
        monkeypatch,
        [
            (None, None, None),
            (None, None, "state"),
            ("state", None, None),
            ("state", None, "vintage"),
            ("state", "geometry_building_type_recs", None),
        ],
    )

    work_items = expand_templates([template], test_only=False)

    assert _focus_and_group(work_items) == [
        ((("state", "US Total"),), None),
        ((), "state"),
        ((("state", "CA"),), None),
        ((("state", "NY"),), None),
        ((("state", "CA"),), "vintage"),
        ((("state", "NY"),), "vintage"),
        ((("state", "CA"), ("geometry_building_type_recs", "Mobile Home")), None),
        ((("state", "CA"), ("geometry_building_type_recs", "Single-Family Detached")), None),
        ((("state", "NY"), ("geometry_building_type_recs", "Mobile Home")), None),
        ((("state", "NY"), ("geometry_building_type_recs", "Single-Family Detached")), None),
    ]

    us_total_item = work_items[0]
    assert us_total_item[0][0].group_by == "state"
    assert us_total_item[0][0].focus_on == (("state", "US Total"),)
    assert us_total_item[2][0][0].focus_on == (("state", "US Total"),)

    grouped_overview = work_items[1]
    assert grouped_overview[0][0].group_by == "state"
    assert grouped_overview[0][0].focus_on == ()
    assert grouped_overview[2][0][0].focus_on == ()

    cross_filtered_group = work_items[4]
    assert all(spec.focus_on == (("state", "CA"),) for spec, _ in cross_filtered_group[2])
    assert all(spec.group_by == "vintage" for spec, _ in cross_filtered_group[2])

    same_dimension_drilldown = work_items[2]
    assert all(spec.focus_on == (("state", "CA"),) for spec, _ in same_dimension_drilldown[2])
    assert all(spec.group_by == "state" for spec, _ in same_dimension_drilldown[2])
    assert same_dimension_drilldown[5] is None


def test_expand_templates_test_only_limits_focus_value_expansion(monkeypatch):
    template = _make_template()
    _install_expansion_stubs(
        monkeypatch,
        [
            (None, None, None),
            (None, None, "state"),
            ("state", None, "vintage"),
            ("state", "geometry_building_type_recs", None),
        ],
    )

    work_items = expand_templates([template], test_only=True)

    assert _focus_and_group(work_items) == [
        ((("state", "US Total"),), None),
        ((), "state"),
        ((("state", "CA"),), "vintage"),
        ((("state", "CA"), ("geometry_building_type_recs", "Mobile Home")), None),
    ]


def test_build_filtered_entries_preserves_labels_and_applies_focus_on():
    base_spec = _make_spec(
        comparison_dataset=ComparisonDataset.recs,
        quantity=DataCol.ELECTRICITY_TOTAL,
        resolution=Resolution.year,
        aggregation_type=Metric.average,
        coverage=CoverageType.all_units,
        group_by="vintage",
        view=ViewType.value_view,
    )
    spec_entries = build_spec_entries(_make_related_specs(base_spec))
    focus_on = (("state", "CA"),)

    filtered_entries = build_filtered_entries(spec_entries, focus_on)

    assert [label for _, label in filtered_entries] == [label for _, label in spec_entries]
    assert all(spec.focus_on == focus_on for spec, _ in filtered_entries)
    assert all(spec.group_by == "vintage" for spec, _ in filtered_entries)


def test_render_key_is_stable_for_equivalent_items_and_distinguishes_focus_group_cases():
    base_item = (["family-a"], 7, [("entry-a", "Bar Plot")], None, (("state", "CA"),), "vintage")
    same_identity = (["family-b"], 7, [("entry-b", "Timeseries Plot")], None, (("state", "CA"),), "vintage")
    different_focus = (["family-c"], 7, [("entry-c", "Bar Plot")], None, (("state", "NY"),), "vintage")
    different_group = (["family-d"], 7, [("entry-d", "Bar Plot")], None, (("state", "CA"),), None)
    different_focus_val = (["family-e"], 7, [("entry-e", "Bar Plot")], "state:CA", (("state", "CA"),), "vintage")

    assert _render_key(base_item) == _render_key(same_identity)
    assert _render_key(base_item) != _render_key(different_focus)
    assert _render_key(base_item) != _render_key(different_group)
    assert _render_key(base_item) != _render_key(different_focus_val)
