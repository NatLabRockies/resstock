"""Tests for Python-generated plot and table footnotes."""

from resstockpostproc.baseline_validation.footnotes import (
    EIA_NATURAL_GAS_PENETRATION_NOTE,
    HISTOGRAM_OVERFLOW_NOTE,
    RECS_GENERIC_RSE_NOTE,
    RECS_MONTHLY_CI_NOTE,
    RECS_OCCUPIED_UNITS_NOTE,
    RECS_UNITS_COUNT_NOTE,
    get_plot_notes,
    get_table_notes,
)
from resstockpostproc.baseline_validation.schema.plot_spec import (
    ComparisonDataset,
    CoverageType,
    Layout,
    Metric,
    PlotSpec,
    Resolution,
    ViewType,
)
from resstockpostproc.shared_utils.db_column_names import DataCol


def _make_spec(**overrides):
    defaults = dict(
        comparison_dataset=ComparisonDataset.recs,
        quantity=DataCol.ELECTRICITY_TOTAL,
        resolution=Resolution.year,
        aggregation_type=Metric.average,
        coverage=CoverageType.all_units,
        group_by="state",
        view=ViewType.value_view,
    )
    defaults.update(overrides)
    return PlotSpec(**defaults)


class TestPlotNotes:
    def test_recs_annual_value_plot_includes_dataset_and_rse_notes(self):
        notes = get_plot_notes(_make_spec())

        assert notes == [RECS_OCCUPIED_UNITS_NOTE, RECS_GENERIC_RSE_NOTE]

    def test_recs_distribution_plot_omits_generic_rse_note(self):
        notes = get_plot_notes(
            _make_spec(
                aggregation_type=Metric.distribution,
                quantity=DataCol.ELECTRICITY_TOTAL,
            )
        )

        assert notes == [RECS_OCCUPIED_UNITS_NOTE]
        assert RECS_GENERIC_RSE_NOTE not in notes

    def test_recs_monthly_plot_uses_ci_band_note(self):
        notes = get_plot_notes(
            _make_spec(
                resolution=Resolution.month,
                aggregation_type=Metric.average,
            )
        )

        assert notes == [RECS_OCCUPIED_UNITS_NOTE, RECS_MONTHLY_CI_NOTE]
        assert RECS_GENERIC_RSE_NOTE not in notes

    def test_recs_units_count_plot_uses_quantity_note_not_rse_note(self):
        notes = get_plot_notes(
            _make_spec(
                quantity=DataCol.UNITS_COUNT,
                aggregation_type=Metric.total,
            )
        )

        assert notes == [RECS_OCCUPIED_UNITS_NOTE, RECS_UNITS_COUNT_NOTE]
        assert RECS_GENERIC_RSE_NOTE not in notes

    def test_histogram_plot_includes_overflow_note(self):
        notes = get_plot_notes(
            _make_spec(
                aggregation_type=Metric.distribution,
                quantity=DataCol.ELECTRICITY_TOTAL,
                layout=Layout.histogram,
                group_by=None,
            )
        )
        assert HISTOGRAM_OVERFLOW_NOTE in notes
        assert "RECS 2020" in HISTOGRAM_OVERFLOW_NOTE
        assert "cutoff" in HISTOGRAM_OVERFLOW_NOTE

    def test_non_histogram_distribution_omits_overflow_note(self):
        notes = get_plot_notes(
            _make_spec(
                aggregation_type=Metric.distribution,
                quantity=DataCol.ELECTRICITY_TOTAL,
            )
        )
        assert notes is None or HISTOGRAM_OVERFLOW_NOTE not in notes

    def test_recs_diff_view_omits_rse_note(self):
        notes = get_plot_notes(_make_spec(view=ViewType.diff_view))

        assert notes is None or RECS_GENERIC_RSE_NOTE not in notes

    def test_eia_natural_gas_penetration_plot_uses_specific_note(self):
        notes = get_plot_notes(
            _make_spec(
                comparison_dataset=ComparisonDataset.eia,
                quantity=DataCol.NATURAL_GAS_TOTAL,
                aggregation_type=Metric.penetration,
            )
        )

        assert notes == [EIA_NATURAL_GAS_PENETRATION_NOTE]


class TestTableNotes:
    def test_table_notes_keep_shared_dataset_note_and_omit_plot_only_notes(self):
        notes = get_table_notes(_make_spec())

        assert notes == [RECS_OCCUPIED_UNITS_NOTE]
        assert RECS_GENERIC_RSE_NOTE not in notes

    def test_units_count_table_omits_plot_only_quantity_note(self):
        notes = get_table_notes(
            _make_spec(
                quantity=DataCol.UNITS_COUNT,
                aggregation_type=Metric.total,
            )
        )

        assert notes == [RECS_OCCUPIED_UNITS_NOTE]
        assert RECS_UNITS_COUNT_NOTE not in notes

    def test_eia_penetration_note_is_shared_with_tables(self):
        notes = get_table_notes(
            _make_spec(
                comparison_dataset=ComparisonDataset.eia,
                quantity=DataCol.NATURAL_GAS_TOTAL,
                aggregation_type=Metric.penetration,
            )
        )

        assert notes == [EIA_NATURAL_GAS_PENETRATION_NOTE]


class TestCoverageNotes:
    def test_eia_all_units_no_coverage_note(self):
        notes = get_plot_notes(
            _make_spec(
                comparison_dataset=ComparisonDataset.eia,
                quantity=DataCol.ELECTRICITY_TOTAL,
                aggregation_type=Metric.total,
            )
        )
        assert notes is None

    def test_eia_users_only_fuel_note(self):
        notes = get_plot_notes(
            _make_spec(
                comparison_dataset=ComparisonDataset.eia,
                quantity=DataCol.NATURAL_GAS_TOTAL,
                coverage=CoverageType.users_only,
            )
        )
        assert "Only dwelling units which consumed Natural Gas are included in the comparison." in notes

    def test_recs_all_units_returns_occupied_units_note(self):
        notes = get_plot_notes(_make_spec(coverage=CoverageType.all_units))
        assert RECS_OCCUPIED_UNITS_NOTE in notes

    def test_recs_users_only_fuel_level(self):
        notes = get_plot_notes(
            _make_spec(
                quantity=DataCol.NATURAL_GAS_TOTAL,
                coverage=CoverageType.users_only,
            )
        )
        expected = "Only occupied dwelling units which consumed Natural Gas are included in the comparison."
        assert expected in notes
        assert RECS_OCCUPIED_UNITS_NOTE not in notes

    def test_recs_users_only_enduse_level(self):
        notes = get_plot_notes(
            _make_spec(
                quantity=DataCol.ELECTRICITY_SPACE_COOLING,
                coverage=CoverageType.users_only,
            )
        )
        expected = (
            "Only occupied dwelling units which consumed Electricity for Space Cooling "
            "are included in the comparison."
        )
        assert expected in notes

    def test_recs_users_only_all_enduses(self):
        notes = get_plot_notes(
            _make_spec(
                quantity=DataCol.ALL,
                coverage=CoverageType.users_only,
            )
        )
        expected = "Only occupied dwelling units with non-zero consumption are included in the comparison."
        assert expected in notes

    def test_coverage_note_shared_with_tables(self):
        notes = get_table_notes(
            _make_spec(
                quantity=DataCol.NATURAL_GAS_TOTAL,
                coverage=CoverageType.users_only,
            )
        )
        expected = "Only occupied dwelling units which consumed Natural Gas are included in the comparison."
        assert expected in notes
