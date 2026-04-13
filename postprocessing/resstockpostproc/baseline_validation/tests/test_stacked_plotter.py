"""Tests for stacked_plotter — subplot splitting, quartile extraction, and range calculation."""

import polars as pl
import pytest

from resstockpostproc.baseline_validation.plotters.stacked_plotter import (
    _add_quartile_cols,
    _get_reference_source,
    _prepare_box_plot_data,
    get_custom_range,
    split_graph,
    split_graph_by_char,
    split_graph_by_state,
)
from resstockpostproc.baseline_validation.schema.plot_spec import (
    Metric,
    CoverageType,
    PlotSpec,
    Resolution,
    ComparisonDataset,
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


class TestGetReferenceSource:
    def test_returns_non_resstock_source(self):
        df = pl.DataFrame({"source": ["resstock_2024", "recs_2020", "resstock_2025"]})
        assert _get_reference_source(df) == "recs_2020"

    def test_falls_back_to_first_when_all_resstock(self):
        df = pl.DataFrame({"source": ["resstock_2024", "resstock_2025"]})
        assert _get_reference_source(df) == "resstock_2024"


class TestAddQuartileCols:
    def test_extracts_correct_indices(self):
        """Quartiles list: [min, p2, p10, q1, median, q3, p90, p98, max]."""
        quartiles = [0.0, 2.0, 10.0, 25.0, 50.0, 75.0, 90.0, 98.0, 100.0]
        df = pl.DataFrame({"electricity_total_quartiles": [quartiles]})
        result = _add_quartile_cols(df, "electricity_total_quartiles")

        assert result["q1"].item() == 25.0
        assert result["median"].item() == 50.0
        assert result["q3"].item() == 75.0
        assert result["min"].item() == 0.0
        assert result["max"].item() == 100.0
        assert result["lower_whisker"].item() == 0.0
        assert result["upper_whisker"].item() == 100.0


class TestPrepareBoxPlotData:
    def _make_df(self):
        quartiles = [0.0, 2.0, 10.0, 25.0, 50.0, 75.0, 90.0, 98.0, 100.0]
        return pl.DataFrame({
            "source": ["recs_2020"],
            "state": ["CA"],
            "electricity_total_value": [500.0],
            "electricity_total_quartiles": [quartiles],
            "electricity_total_nonzero_quartiles": [quartiles],
            "electricity_total_percent_users": [80.0],
            "model_count": [1000],
        })

    def test_all_units_uses_quartiles(self):
        df = self._make_df()
        result = _prepare_box_plot_data(df, "electricity_total", CoverageType.all_units)

        assert result["n_points"].item() == 1000  # model_count directly
        assert result["q1"].item() == 25.0
        assert result["mean"].item() == 500.0

    def test_users_only_uses_nonzero_quartiles(self):
        df = self._make_df()
        result = _prepare_box_plot_data(df, "electricity_total", CoverageType.users_only)

        # n_points = round(model_count * percent_users / 100) = round(1000 * 80 / 100) = 800
        assert result["n_points"].item() == 800
        assert result["q1"].item() == 25.0

    def test_invalid_coverage_raises(self):
        df = self._make_df()
        with pytest.raises(ValueError, match="Unsupported coverage type"):
            # Create a mock coverage that's not all_units or users_only
            # We can test this by passing a string that doesn't match
            _prepare_box_plot_data(df, "electricity_total", "invalid")


class TestSplitGraphByState:
    def _make_state_df(self, states, units_counts):
        """Build a DataFrame with ref + resstock sources for each state."""
        rows = []
        for state, uc in zip(states, units_counts):
            rows.append({"source": "recs_2020", "state": state, "units_count": uc, "electricity_total_value": 100.0})
            rows.append({"source": "resstock_2024", "state": state, "units_count": uc, "electricity_total_value": 110.0})
        return pl.DataFrame(rows)

    def test_multi_state_splits_into_two_columns(self):
        df = self._make_state_df(["CA", "TX", "NY", "FL"], [5000, 4000, 3000, 2000])
        fig, iterator = split_graph_by_state(df)

        chunks = list(iterator)
        assert len(chunks) == 2

        # First column: top 2 states by units_count (CA, TX)
        df1, col_name, row, col = chunks[0]
        assert col_name == "state"
        assert row == 1 and col == 1
        states_1 = df1["state"].unique().to_list()
        assert set(states_1) == {"CA", "TX"}

        # Second column: bottom 2 states (NY, FL)
        df2, col_name, row, col = chunks[1]
        assert row == 1 and col == 2
        states_2 = df2["state"].unique().to_list()
        assert set(states_2) == {"NY", "FL"}

    def test_single_state_no_split(self):
        df = self._make_state_df(["CA"], [5000])
        fig, iterator = split_graph_by_state(df)

        chunks = list(iterator)
        assert len(chunks) == 1
        _, _, row, col = chunks[0]
        assert row == 1 and col == 1

    def test_states_sorted_by_units_count_descending(self):
        """The reference source's states should be sorted by units_count descending."""
        df = self._make_state_df(["FL", "CA", "NY"], [2000, 5000, 3000])
        fig, iterator = split_graph_by_state(df)

        chunk1, chunk2 = list(iterator)
        # First column gets the top state (CA, sorted desc by units_count)
        first_state = chunk1[0]["state"].unique().to_list()[0]
        assert first_state == "CA"


class TestSplitGraphByChar:
    def test_single_column_layout(self):
        df = pl.DataFrame({
            "source": ["recs_2020", "recs_2020", "resstock_2024", "resstock_2024"],
            "vintage": ["pre-1950", "1950-1970", "pre-1950", "1950-1970"],
            "units_count": [1000, 2000, 1000, 2000],
            "electricity_total_value": [100.0, 200.0, 110.0, 220.0],
        })
        fig, iterator = split_graph_by_char(df)

        chunks = list(iterator)
        assert len(chunks) == 1
        df_out, col_name, row, col = chunks[0]
        assert col_name == "vintage"
        assert row == 1 and col == 1


class TestGetCustomRange:
    def test_units_count_range(self):
        df = pl.DataFrame({"units_count": [100, 200, 300]})
        spec = _make_spec(quantity=DataCol.UNITS_COUNT)
        min_val, max_val = get_custom_range(df, spec)
        assert min_val == 0
        assert max_val == 300.0

    def test_value_view_range(self):
        df = pl.DataFrame({"electricity_total_value": [-10.0, 50.0, 200.0]})
        spec = _make_spec(view=ViewType.value_view)
        min_val, max_val = get_custom_range(df, spec)
        assert min_val == -10.0
        assert max_val == 200.0

    def test_distribution_range_from_quartiles(self):
        """Distribution view reads min/max from quartiles list column."""
        df = pl.DataFrame({
            "electricity_total_quartiles": [[5.0, 10.0, 20.0, 30.0, 50.0, 70.0, 80.0, 90.0, 95.0]],
        })
        spec = _make_spec(view=ViewType.value_view)
        min_val, max_val = get_custom_range(df, spec)
        assert min_val == 0  # min(0, first element)
        assert max_val == 95.0  # last element

    def test_penetration_range(self):
        df = pl.DataFrame({"electricity_total_percent_users": [20.0, 80.0, 100.0]})
        spec = _make_spec(
            view=ViewType.penetration,
            aggregation_type=Metric.total,
        )
        min_val, max_val = get_custom_range(df, spec)
        assert min_val == 0
        assert max_val == 100.0

    def test_no_matching_columns_returns_default(self):
        df = pl.DataFrame({"unrelated_col": [1, 2, 3]})
        spec = _make_spec()
        min_val, max_val = get_custom_range(df, spec)
        assert min_val == 0.0
        assert max_val == 1.0


class TestSplitGraphDispatch:
    def test_state_non_all_dispatches_to_state(self):
        """state aggregation + non-ALL quantity → split_graph_by_state."""
        df = pl.DataFrame({
            "source": ["recs_2020", "resstock_2024"],
            "state": ["CA", "CA"],
            "units_count": [5000, 5000],
            "electricity_total_value": [100.0, 110.0],
        })
        spec = _make_spec(group_by="state", quantity=DataCol.ELECTRICITY_TOTAL)
        fig, iterator = split_graph(df, spec)
        chunks = list(iterator)
        # Single state → single chunk
        assert len(chunks) == 1
        assert chunks[0][1] == "state"  # second_category_column

    def test_char_aggregation_dispatches_to_char(self):
        """Non-state, non-ALL → split_graph_by_char."""
        df = pl.DataFrame({
            "source": ["recs_2020", "resstock_2024"],
            "vintage": ["pre-1950", "pre-1950"],
            "units_count": [1000, 1000],
            "electricity_total_value": [100.0, 110.0],
        })
        spec = _make_spec(group_by="vintage", quantity=DataCol.ELECTRICITY_TOTAL)
        fig, iterator = split_graph(df, spec)
        chunks = list(iterator)
        assert chunks[0][1] == "vintage"
