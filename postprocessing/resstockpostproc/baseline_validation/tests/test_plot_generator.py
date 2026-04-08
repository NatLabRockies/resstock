"""Tests for plot_generator discrepancy math and list unnesting."""

import math

import polars as pl
import pytest

from resstockpostproc.baseline_validation.plot_generator import _compute_discrepancy, _unnest_list_columns
from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    AggregationType,
    CoverageType,
    Resolution,
    ComparisonDataset,
    ViewType,
)
from resstockpostproc.shared_utils.db_column_names import DataCol


def _make_spec(**overrides):
    defaults = dict(
        comparison_dataset=ComparisonDataset.eia,
        quantity=DataCol.ELECTRICITY_TOTAL,
        resolution=Resolution.year,
        aggregation_type=AggregationType.total,
        coverage=CoverageType.all_units,
        group_by="state",
        view=ViewType.value_view,
    )
    defaults.update(overrides)
    return PlotSpec(**defaults)


class TestComputeDiscrepancy:
    """Tests for CVRMSE/NMBE calculation."""

    def test_normal_case(self):
        """Verify CVRMSE and NMBE against hand-calculated values."""
        # ref = [100, 200], rs = [110, 190]
        # diffs = [10, -10], sum_ref = 300, mean_ref = 150
        # NMBE = (10 + -10) / 300 * 100 = 0.0
        # RMSE = sqrt((100 + 100) / 2) = sqrt(100) = 10.0
        # CVRMSE = 10.0 / 150 * 100 = 6.666...
        data = pl.DataFrame({
            "source": ["eia_2018", "eia_2018", "resstock_2024", "resstock_2024"],
            "state": ["CA", "NY", "CA", "NY"],
            "electricity_total_value": [100.0, 200.0, 110.0, 190.0],
        })
        spec = _make_spec()
        cvrmse, nmbe = _compute_discrepancy(data, spec)

        assert nmbe == pytest.approx(0.0)
        assert cvrmse == pytest.approx(10.0 / 150.0 * 100)

    def test_positive_bias(self):
        """ResStock consistently higher → positive NMBE."""
        data = pl.DataFrame({
            "source": ["eia_2018", "resstock_2024"],
            "state": ["CA", "CA"],
            "electricity_total_value": [100.0, 120.0],
        })
        spec = _make_spec()
        cvrmse, nmbe = _compute_discrepancy(data, spec)

        assert nmbe == pytest.approx(20.0)  # (120-100)/100 * 100
        assert cvrmse == pytest.approx(20.0)

    def test_returns_none_for_all_quantity(self):
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            quantity=DataCol.ALL,
            aggregation_type=AggregationType.average,
        )
        data = pl.DataFrame({"source": ["recs"], "state": ["CA"], "electricity_total_value": [1.0]})
        assert _compute_discrepancy(data, spec) == (None, None)

    def test_returns_none_for_distribution_view(self):
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            aggregation_type=AggregationType.average,
            view=ViewType.distribution,
        )
        data = pl.DataFrame({"source": ["recs"], "state": ["CA"], "electricity_total_value": [1.0]})
        assert _compute_discrepancy(data, spec) == (None, None)

    def test_returns_none_when_no_resstock_rows(self):
        data = pl.DataFrame({
            "source": ["eia_2018", "eia_2018"],
            "state": ["CA", "NY"],
            "electricity_total_value": [100.0, 200.0],
        })
        spec = _make_spec()
        assert _compute_discrepancy(data, spec) == (None, None)

    def test_returns_none_when_zero_reference(self):
        data = pl.DataFrame({
            "source": ["eia_2018", "resstock_2024"],
            "state": ["CA", "CA"],
            "electricity_total_value": [0.0, 50.0],
        })
        spec = _make_spec()
        assert _compute_discrepancy(data, spec) == (None, None)

    def test_excludes_us_total_by_default(self):
        """US Total rows should be excluded when focus_on is not 'US Total'."""
        data = pl.DataFrame({
            "source": ["eia_2018", "eia_2018", "resstock_2024", "resstock_2024"],
            "state": ["CA", "US Total", "CA", "US Total"],
            "electricity_total_value": [100.0, 999.0, 100.0, 999.0],
        })
        spec = _make_spec()
        cvrmse, nmbe = _compute_discrepancy(data, spec)

        # Only CA is used (US Total excluded) → perfect match
        assert nmbe == pytest.approx(0.0)
        assert cvrmse == pytest.approx(0.0)

    def test_includes_us_total_when_focused(self):
        """When focused on US Total, US Total rows should be included."""
        data = pl.DataFrame({
            "source": ["eia_2018", "resstock_2024"],
            "state": ["US Total", "US Total"],
            "electricity_total_value": [100.0, 120.0],
        })
        spec = _make_spec(focus_on=(("state", "US Total"),), group_by=None)
        cvrmse, nmbe = _compute_discrepancy(data, spec)

        assert nmbe == pytest.approx(20.0)

    def test_units_count_quantity(self):
        """When quantity is UNITS_COUNT, val_col should be 'units_count'."""
        data = pl.DataFrame({
            "source": ["eia_2018", "resstock_2024"],
            "state": ["CA", "CA"],
            "units_count": [1000.0, 1100.0],
        })
        spec = _make_spec(quantity=DataCol.UNITS_COUNT)
        cvrmse, nmbe = _compute_discrepancy(data, spec)

        assert nmbe == pytest.approx(10.0)

    def test_monthly_resolution_joins_on_month(self):
        """Monthly data should join on both state and month."""
        data = pl.DataFrame({
            "source": ["eia_2018", "eia_2018", "resstock_2024", "resstock_2024"],
            "state": ["CA", "CA", "CA", "CA"],
            "month": ["JAN", "FEB", "JAN", "FEB"],
            "electricity_total_value": [100.0, 200.0, 110.0, 220.0],
        })
        spec = _make_spec(resolution=Resolution.month)
        cvrmse, nmbe = _compute_discrepancy(data, spec)

        # diffs = [10, 20], sum_ref = 300, NMBE = 30/300*100 = 10%
        assert nmbe == pytest.approx(10.0)


class TestUnnestListColumns:
    def test_expands_list_column(self):
        df = pl.DataFrame({
            "name": ["a", "b"],
            "quartiles": [[1, 2, 3], [4, 5, 6]],
        })
        result = _unnest_list_columns(df)

        assert "quartiles" not in result.columns
        assert "quartiles_0" in result.columns
        assert "quartiles_1" in result.columns
        assert "quartiles_2" in result.columns
        assert result["quartiles_0"].to_list() == [1, 4]
        assert result["quartiles_2"].to_list() == [3, 6]

    def test_no_list_columns_unchanged(self):
        df = pl.DataFrame({"a": [1, 2], "b": ["x", "y"]})
        result = _unnest_list_columns(df)
        assert result.columns == ["a", "b"]
        assert result["a"].to_list() == [1, 2]

    def test_mixed_list_and_scalar(self):
        df = pl.DataFrame({
            "name": ["a", "b"],
            "score": [10.0, 20.0],
            "values": [[1, 2], [3, 4]],
        })
        result = _unnest_list_columns(df)

        assert "name" in result.columns
        assert "score" in result.columns
        assert "values" not in result.columns
        assert "values_0" in result.columns
        assert "values_1" in result.columns


# ---------------------------------------------------------------------------
# generate_slot_triples tests
# ---------------------------------------------------------------------------

from resstockpostproc.baseline_validation.schema.plot_definitions import (
    generate_slot_triples,
    RECS_ANNUAL_CHARS,
    RECS_CROSS_FILTER_CHARS,
    RECS_MONTHLY_CHARS,
    EIA_CHARS,
    LRD_CHARS,
)
from resstockpostproc.baseline_validation.schema.plot_spec import GEOGRAPHIC_DIMENSIONS


class TestGenerateSlotTriples:
    """Tests for the slot triple generator."""

    def test_single_char_no_cross_filter(self):
        """Single-char sources produce only base triples."""
        for chars in [EIA_CHARS, LRD_CHARS, RECS_MONTHLY_CHARS]:
            triples = generate_slot_triples(chars, allow_cross_filter=False)
            assert len(triples) == 2
            assert (None, None, None) in triples
            assert (None, None, chars[0]) in triples

    def test_single_char_with_cross_filter(self):
        """Single-char sources with cross_filter add (char, None, None)."""
        triples = generate_slot_triples(("state",), allow_cross_filter=True)
        assert len(triples) == 3
        assert (None, None, None) in triples
        assert (None, None, "state") in triples
        assert ("state", None, None) in triples

    def test_no_cross_filter_returns_only_base(self):
        """Without allow_cross_filter, only (None, None, *) triples are returned."""
        triples = generate_slot_triples(RECS_ANNUAL_CHARS, allow_cross_filter=False)
        assert len(triples) == 7  # 1 + 6 chars
        for f1, f2, _ in triples:
            assert f1 is None
            assert f2 is None

    def test_recs_annual_count(self):
        """RECS annual with 6 chars produces exactly 49 triples."""
        triples = generate_slot_triples(RECS_ANNUAL_CHARS, allow_cross_filter=True)
        assert len(triples) == 49

    def test_no_geo_geo_conflict(self):
        """No triple has two geographic dimensions."""
        triples = generate_slot_triples(RECS_ANNUAL_CHARS, allow_cross_filter=True)
        for f1, f2, agg in triples:
            dims = [d for d in (f1, f2, agg) if d is not None]
            geo_count = sum(1 for d in dims if d in GEOGRAPHIC_DIMENSIONS)
            assert geo_count <= 1, f"Geo conflict in {(f1, f2, agg)}"

    def test_upper_triangle_dedup(self):
        """(A, B, None) exists but (B, A, None) does not for any pair."""
        triples = generate_slot_triples(RECS_ANNUAL_CHARS, allow_cross_filter=True)
        f1f2_pairs = {(f1, f2) for f1, f2, agg in triples if f1 and f2 and agg is None}
        for f1, f2 in f1f2_pairs:
            assert (f2, f1) not in f1f2_pairs, f"Both ({f1},{f2}) and ({f2},{f1}) present"

    def test_f2_requires_f1(self):
        """No triple has F2 set but F1 unset."""
        triples = generate_slot_triples(RECS_ANNUAL_CHARS, allow_cross_filter=True)
        for f1, f2, _ in triples:
            if f2 is not None:
                assert f1 is not None, f"F2={f2} without F1"

    def test_f2_and_group_by_mutually_exclusive(self):
        """When F2 is set, group_by must be None."""
        triples = generate_slot_triples(RECS_ANNUAL_CHARS, allow_cross_filter=True)
        for f1, f2, group_by in triples:
            if f2 is not None:
                assert group_by is None, f"F2={f2} with group_by={group_by}"

    def test_f1_not_equal_to_group_by(self):
        """F1 never equals group_by."""
        triples = generate_slot_triples(RECS_ANNUAL_CHARS, allow_cross_filter=True)
        for f1, _, group_by in triples:
            if f1 is not None and group_by is not None:
                assert f1 != group_by, f"F1=group_by={f1}"

    def test_all_triples_unique(self):
        """No duplicate triples."""
        triples = generate_slot_triples(RECS_ANNUAL_CHARS, allow_cross_filter=True)
        assert len(triples) == len(set(triples))

    def test_two_non_geo_chars(self):
        """Two non-geographic chars produce all valid combos."""
        triples = generate_slot_triples(("vintage", "heating_fuel"), allow_cross_filter=True)
        expected = [
            (None, None, None),
            (None, None, "vintage"),
            (None, None, "heating_fuel"),
            ("vintage", None, None),
            ("vintage", None, "heating_fuel"),
            ("vintage", "heating_fuel", None),
            ("heating_fuel", None, None),
            ("heating_fuel", None, "vintage"),
        ]
        assert triples == expected

    def test_two_geo_chars(self):
        """Two geographic chars — cross-filter combos blocked by geo constraint."""
        triples = generate_slot_triples(
            ("state", "census_division_recs"), allow_cross_filter=True
        )
        expected = [
            (None, None, None),
            (None, None, "state"),
            (None, None, "census_division_recs"),
            ("state", None, None),
            ("census_division_recs", None, None),
            # No (state, None, census_div), (census_div, None, state), or (state, census_div, None)
        ]
        assert triples == expected

    # --- Tests for cross_filter_chars restriction ---

    def test_cross_filter_chars_count(self):
        """RECS annual with cross_filter_chars produces exactly 23 triples."""
        triples = generate_slot_triples(
            RECS_ANNUAL_CHARS, allow_cross_filter=True,
            cross_filter_chars=RECS_CROSS_FILTER_CHARS,
        )
        assert len(triples) == 23

    def test_cross_filter_chars_restricts_f1(self):
        """F1 only appears for chars in cross_filter_chars."""
        triples = generate_slot_triples(
            RECS_ANNUAL_CHARS, allow_cross_filter=True,
            cross_filter_chars=RECS_CROSS_FILTER_CHARS,
        )
        f1_chars = {f1 for f1, _, _ in triples if f1 is not None}
        assert f1_chars == set(RECS_CROSS_FILTER_CHARS)

    def test_cross_filter_chars_restricts_f2(self):
        """F2 only appears for chars in cross_filter_chars."""
        triples = generate_slot_triples(
            RECS_ANNUAL_CHARS, allow_cross_filter=True,
            cross_filter_chars=RECS_CROSS_FILTER_CHARS,
        )
        f2_chars = {f2 for _, f2, _ in triples if f2 is not None}
        assert f2_chars == {"geometry_building_type_recs"}

    def test_cross_filter_chars_block1_unchanged(self):
        """Block 1 (None, None, agg) triples still include all 6 chars."""
        triples = generate_slot_triples(
            RECS_ANNUAL_CHARS, allow_cross_filter=True,
            cross_filter_chars=RECS_CROSS_FILTER_CHARS,
        )
        block1_aggs = {agg for f1, f2, agg in triples if f1 is None and f2 is None and agg is not None}
        assert block1_aggs == set(RECS_ANNUAL_CHARS)

    def test_cross_filter_chars_agg_uses_all_eligible(self):
        """(f1, None, agg) triples still use all eligible non-conflicting chars for agg."""
        triples = generate_slot_triples(
            RECS_ANNUAL_CHARS, allow_cross_filter=True,
            cross_filter_chars=RECS_CROSS_FILTER_CHARS,
        )
        # For F1=building_type (non-geo), agg should include all 5 other chars
        bt_aggs = {agg for f1, f2, agg in triples
                   if f1 == "geometry_building_type_recs" and f2 is None and agg is not None}
        expected = set(RECS_ANNUAL_CHARS) - {"geometry_building_type_recs"}
        assert bt_aggs == expected

    def test_cross_filter_chars_none_is_backward_compatible(self):
        """cross_filter_chars=None preserves original 49-triple behavior."""
        triples = generate_slot_triples(
            RECS_ANNUAL_CHARS, allow_cross_filter=True,
            cross_filter_chars=None,
        )
        assert len(triples) == 49
