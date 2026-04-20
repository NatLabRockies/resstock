"""Tests for stacked_plotter — subplot splitting, quartile extraction, and range calculation."""

import polars as pl
import pytest
import plotly.graph_objects as go

from resstockpostproc.baseline_validation.plotters.box_plot_data import (
    add_quartile_cols,
    prepare_box_plot_data,
)
from resstockpostproc.baseline_validation.plotters.graph_splitting import (
    get_reference_source,
    split_graph,
    split_graph_by_char,
    split_graph_by_state,
)
from resstockpostproc.baseline_validation.plotters.stacked_plotter import (
    create_stacked_plot,
    get_custom_range,
)
from resstockpostproc.baseline_validation.schema.plot_spec import (
    Metric,
    CoverageType,
    PlotSpec,
    Resolution,
    ComparisonDataset,
    ViewType,
    Layout,
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
        assert get_reference_source(df) == "recs_2020"

    def test_falls_back_to_first_when_all_resstock(self):
        df = pl.DataFrame({"source": ["resstock_2024", "resstock_2025"]})
        assert get_reference_source(df) == "resstock_2024"


class TestAddQuartileCols:
    def test_extracts_correct_indices(self):
        """Quartiles list: [min, p2, p10, q1, median, q3, p90, p98, max]."""
        quartiles = [0.0, 2.0, 10.0, 25.0, 50.0, 75.0, 90.0, 98.0, 100.0]
        df = pl.DataFrame({"electricity_total_quartiles": [quartiles]})
        result = add_quartile_cols(df, "electricity_total_quartiles")

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
            "model_count": [800],
        })

    def test_all_units_uses_quartiles(self):
        df = self._make_df()
        result = prepare_box_plot_data(df, "electricity_total", CoverageType.all_units)

        assert result["n_points"].item() == 800  # model_count directly
        assert result["q1"].item() == 25.0
        assert result["mean"].item() == 500.0

    def test_users_only_uses_incoming_nonzero_count_and_nonzero_quartiles(self):
        df = self._make_df()
        result = prepare_box_plot_data(df, "electricity_total", CoverageType.users_only)

        # model_count is already the exact nonzero count for the quantity upstream.
        assert result["n_points"].item() == 800
        assert result["q1"].item() == 25.0

    def test_invalid_coverage_raises(self):
        df = self._make_df()
        with pytest.raises(ValueError, match="Unsupported coverage type"):
            # Create a mock coverage that's not all_units or users_only
            # We can test this by passing a string that doesn't match
            prepare_box_plot_data(df, "electricity_total", "invalid")


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

    def test_recs_census_division_custom_order_with_us_total_first(self):
        df = pl.DataFrame({
            "source": ["recs_2020"] * 4 + ["resstock_2024"] * 4,
            "census_division_recs": [
                "Pacific",
                "Middle Atlantic",
                "US Total",
                "New England",
                "Pacific",
                "Middle Atlantic",
                "US Total",
                "New England",
            ],
            "units_count": [9000, 8000, 1000, 7000, 9100, 7900, 1000, 7100],
            "electricity_total_value": [100.0, 100.0, 100.0, 100.0, 110.0, 110.0, 110.0, 110.0],
        })
        spec = _make_spec(group_by="census_division_recs")
        _, iterator = split_graph_by_char(df, spec)
        df_out, _, _, _ = list(iterator)[0]

        ordered = df_out.filter(pl.col("source") == "recs_2020")["census_division_recs"].to_list()
        assert ordered == ["US Total", "New England", "Middle Atlantic", "Pacific"]

    def test_recs_building_type_custom_order_with_label_variants(self):
        df = pl.DataFrame({
            "source": ["recs_2020"] * 5 + ["resstock_2024"] * 5,
            "geometry_building_type_recs": [
                "Mobile Home",
                "Multi-Family with 5+ Units",
                "Single-Family Detached",
                "Multi-Family with 2 - 4 Units",
                "Single-Family Attached",
                "Mobile Home",
                "Multi-Family with 5+ Units",
                "Single-Family Detached",
                "Multi-Family with 2 - 4 Units",
                "Single-Family Attached",
            ],
            "units_count": [10000, 9000, 2000, 8000, 7000, 10010, 9010, 2010, 8010, 7010],
            "electricity_total_value": [1.0] * 10,
        })
        spec = _make_spec(group_by="geometry_building_type_recs")
        _, iterator = split_graph_by_char(df, spec)
        df_out, _, _, _ = list(iterator)[0]

        ordered = df_out.filter(pl.col("source") == "recs_2020")["geometry_building_type_recs"].to_list()
        assert ordered == [
            "Single-Family Detached",
            "Single-Family Attached",
            "Multi-Family with 2 - 4 Units",
            "Multi-Family with 5+ Units",
            "Mobile Home",
        ]

    def test_recs_vintage_human_sort_with_us_total_pinned_first(self):
        df = pl.DataFrame({
            "source": ["recs_2020"] * 5 + ["resstock_2024"] * 5,
            "vintage": [
                "2010s",
                "<1950",
                "1990s",
                "US Total",
                "1950s",
                "2010s",
                "<1950",
                "1990s",
                "US Total",
                "1950s",
            ],
            "units_count": [9000, 8000, 7000, 1000, 6000, 9010, 8010, 7010, 1000, 6010],
            "electricity_total_value": [1.0] * 10,
        })
        spec = _make_spec(group_by="vintage")
        _, iterator = split_graph_by_char(df, spec)
        df_out, _, _, _ = list(iterator)[0]

        ordered = df_out.filter(pl.col("source") == "recs_2020")["vintage"].to_list()
        assert ordered == ["US Total", "<1950", "1950s", "1990s", "2010s"]

    def test_recs_unknown_char_falls_back_to_units_count_descending(self):
        df = pl.DataFrame({
            "source": ["recs_2020"] * 3 + ["resstock_2024"] * 3,
            "custom_char": ["A", "B", "C", "A", "B", "C"],
            "units_count": [10, 30, 20, 11, 31, 21],
            "electricity_total_value": [1.0] * 6,
        })
        spec = _make_spec(group_by="custom_char")
        _, iterator = split_graph_by_char(df, spec)
        df_out, _, _, _ = list(iterator)[0]

        ordered = df_out.filter(pl.col("source") == "recs_2020")["custom_char"].to_list()
        assert ordered == ["B", "C", "A"]

    def test_non_recs_keeps_units_count_sort_even_for_semantic_chars(self):
        df = pl.DataFrame({
            "source": ["eia_2018"] * 3 + ["resstock_2024"] * 3,
            "vintage": ["<1950", "1950s", "2010s", "<1950", "1950s", "2010s"],
            "units_count": [10, 20, 30, 11, 21, 31],
            "electricity_total_value": [1.0] * 6,
        })
        spec = _make_spec(comparison_dataset=ComparisonDataset.eia, group_by="vintage")
        _, iterator = split_graph_by_char(df, spec)
        df_out, _, _, _ = list(iterator)[0]

        ordered = df_out.filter(pl.col("source") == "eia_2018")["vintage"].to_list()
        assert ordered == ["2010s", "1950s", "<1950"]


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
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            aggregation_type=Metric.distribution,
            view=ViewType.value_view,
        )
        min_val, max_val = get_custom_range(df, spec)
        assert min_val == 0  # min(0, first element)
        assert max_val == 95.0  # last element

    def test_penetration_range(self):
        df = pl.DataFrame({"electricity_total_percent_users": [20.0, 80.0, 100.0]})
        spec = _make_spec(
            aggregation_type=Metric.penetration,
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

    def test_two_column_layout_prefers_state_split_even_with_focus(self):
        """two_column layout should use state split path for state-grouped data."""
        df = pl.DataFrame({
            "source": ["recs_2020", "resstock_2024", "recs_2020", "resstock_2024"],
            "state": ["CA", "CA", "TX", "TX"],
            "vintage": ["pre-1950", "pre-1950", "pre-1950", "pre-1950"],
            "units_count": [5000, 5000, 4000, 4000],
            "electricity_total_value": [100.0, 110.0, 90.0, 95.0],
        })
        spec = _make_spec(
            group_by="state",
            quantity=DataCol.ELECTRICITY_TOTAL,
            focus_on=(("vintage", "pre-1950"),),
            layout=Layout.two_column,
        )
        _, iterator = split_graph(df, spec)
        chunks = list(iterator)
        assert chunks[0][1] == "state"


class TestHistogramLayoutRouting:
    def test_histogram_layout_routes_to_histogram_renderer(self, monkeypatch):
        calls = {"count": 0}

        def _fake_hist_renderer(df, plot_spec):
            calls["count"] += 1
            return go.Figure()

        monkeypatch.setattr(
            "resstockpostproc.baseline_validation.plotters.stacked_plotter.create_histogram_plot",
            _fake_hist_renderer,
        )

        data = pl.DataFrame({
            "source": ["RECS 2020", "ResStock 2025"],
            "bin": [0, 0],
            "bin_left": [0.0, 0.0],
            "bin_right": [1.0, 1.0],
            "count_pct": [10.0, 12.0],
        })
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            aggregation_type=Metric.distribution,
            view=ViewType.value_view,
            group_by=None,
            layout=Layout.histogram,
        )
        fig = create_stacked_plot(data, spec)
        assert isinstance(fig, go.Figure)
        assert calls["count"] == 1

    def test_histogram_overflow_tail_geometry_and_style(self):
        data = pl.DataFrame({
            "source": ["RECS 2020", "RECS 2020", "ResStock 2025", "ResStock 2025"],
            "bin": [0, 49, 0, 49],
            "bin_left": [0.0, 100.0, 0.0, 100.0],
            "bin_right": [10.0, 500.0, 10.0, 400.0],
            "count_pct": [4.0, 1.0, 3.0, 2.0],
        })
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            aggregation_type=Metric.distribution,
            view=ViewType.value_view,
            group_by=None,
            layout=Layout.histogram,
        )
        fig = create_stacked_plot(data, spec)

        assert fig.layout.barmode == "overlay"
        assert fig.layout.bargap == 0
        assert fig.layout.bargroupgap == 0

        for trace in fig.data:
            assert isinstance(trace, go.Bar)
            assert trace.opacity == pytest.approx(0.7)
            # bin 0 center is midpoint of [0,10], overflow center is p98 + core_width = 100 + 10
            assert trace.x[0] == pytest.approx(5.0)
            assert trace.x[1] == pytest.approx(110.0)
            # overflow width is 2x core width
            assert trace.width[0] == pytest.approx(10.0)
            assert trace.width[1] == pytest.approx(20.0)
            assert "%{fullData.name}" in trace.hovertemplate
            assert "Range: %{customdata[0]} to %{customdata[1]}" in trace.hovertemplate
            assert "Stock Share: %{y:.2f}%" in trace.hovertemplate
            assert trace.customdata[0][0] == "0.00"
            assert trace.customdata[1][1] in {"500.00", "400.00"}

        # right edge clipped to the synthetic tail, not raw max
        assert fig.layout.xaxis.range[0] == pytest.approx(0.0)
        assert fig.layout.xaxis.range[1] == pytest.approx(120.0)

    def test_histogram_hover_uses_compact_range_formatting(self):
        data = pl.DataFrame({
            "source": ["RECS 2020", "RECS 2020", "ResStock 2025", "ResStock 2025"],
            "bin": [0, 49, 0, 49],
            "bin_left": [1_000.0, 10_000.0, 1_000.0, 10_000.0],
            "bin_right": [2_500.0, 1_500_000.0, 2_500.0, 2_000_000_000.0],
            "count_pct": [4.0, 1.0, 3.0, 2.0],
        })
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            aggregation_type=Metric.distribution,
            view=ViewType.value_view,
            group_by=None,
            layout=Layout.histogram,
        )

        fig = create_stacked_plot(data, spec)

        assert all("%{fullData.name}" in trace.hovertemplate for trace in fig.data)
        assert any(trace.customdata[0][0] == "1.00K" for trace in fig.data)
        assert any(trace.customdata[0][1] == "2.50K" for trace in fig.data)
        assert any(trace.customdata[1][1] == "1.50M" for trace in fig.data)
        assert any(trace.customdata[1][1] == "2.00B" for trace in fig.data)

    def test_grouped_histogram_creates_faceted_subplots(self):
        """Grouped histogram produces one subplot row per group_by category."""
        data = pl.DataFrame({
            "source": ["RECS 2020", "ResStock 2025"] * 4,
            "state": ["CA", "CA", "TX", "TX", "CA", "CA", "TX", "TX"],
            "bin": [0, 0, 0, 0, 1, 1, 1, 1],
            "bin_left": [0.0, 0.0, 0.0, 0.0, 10.0, 10.0, 10.0, 10.0],
            "bin_right": [10.0, 10.0, 10.0, 10.0, 20.0, 20.0, 20.0, 20.0],
            "count_pct": [5.0, 6.0, 3.0, 4.0, 8.0, 7.0, 2.0, 3.0],
        })
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            aggregation_type=Metric.distribution,
            view=ViewType.value_view,
            group_by="state",
            layout=Layout.histogram,
        )
        fig = create_stacked_plot(data, spec)
        assert isinstance(fig, go.Figure)

        # 2 groups x 2 sources = 4 bar traces
        bar_traces = [t for t in fig.data if isinstance(t, go.Bar)]
        assert len(bar_traces) == 4

        # Only first subplot row shows legend entries
        legend_traces = [t for t in bar_traces if t.showlegend]
        no_legend_traces = [t for t in bar_traces if not t.showlegend]
        assert len(legend_traces) == 2
        assert len(no_legend_traces) == 2

        # Subplots keep a shared x-axis range, but each y-axis autoranges independently.
        assert fig.layout.xaxis.range == fig.layout.xaxis2.range
        assert fig.layout.yaxis.range is None
        assert fig.layout.yaxis2.range is None
        assert all("%{fullData.name}" in trace.hovertemplate for trace in bar_traces)
        assert all("Range: %{customdata[0]} to %{customdata[1]}" in trace.hovertemplate for trace in bar_traces)
        assert any(trace.customdata[0][0] == "0.00" for trace in bar_traces)
        assert any(trace.customdata[1][1] == "20.00" for trace in bar_traces)

    def test_grouped_histogram_single_group_uses_single_panel(self):
        """When group_by column has only one value, falls back to single panel."""
        data = pl.DataFrame({
            "source": ["RECS 2020", "ResStock 2025"],
            "state": ["CA", "CA"],
            "bin": [0, 0],
            "bin_left": [0.0, 0.0],
            "bin_right": [10.0, 10.0],
            "count_pct": [5.0, 6.0],
        })
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            aggregation_type=Metric.distribution,
            view=ViewType.value_view,
            group_by="state",
            layout=Layout.histogram,
        )
        fig = create_stacked_plot(data, spec)
        # Single group falls through to single-panel renderer (no subplots)
        assert isinstance(fig, go.Figure)
        bar_traces = [t for t in fig.data if isinstance(t, go.Bar)]
        assert len(bar_traces) == 2

    def test_grouped_histogram_rejects_inconsistent_geometry(self):
        data = pl.DataFrame({
            "source": ["RECS 2020", "ResStock 2025", "RECS 2020", "ResStock 2025"],
            "state": ["CA", "CA", "TX", "TX"],
            "bin": [0, 0, 49, 49],
            "bin_left": [0.0, 0.0, 100.0, 200.0],
            "bin_right": [10.0, 10.0, 300.0, 400.0],
            "count_pct": [5.0, 6.0, 3.0, 4.0],
        })
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            aggregation_type=Metric.distribution,
            view=ViewType.value_view,
            group_by="state",
            layout=Layout.histogram,
        )

        with pytest.raises(ValueError, match="inconsistent overflow bin placement"):
            create_stacked_plot(data, spec)


class TestStackedHoverFormatting:
    def test_grouped_bar_hover_uses_compact_values_and_source_specific_count_labels(self):
        data = pl.DataFrame({
            "source": ["RECS 2020", "ResStock 2025", "RECS 2020", "ResStock 2025"],
            "state": ["CA", "CA", "TX", "TX"],
            "units_count": [5000, 5000, 4000, 4000],
            "electricity_total_value": [1_223_232_232.22, 1_101_987_600.0, 98_765_432.0, 45_678_901.0],
            "electricity_total_value_rse": [5.0, None, 7.0, None],
            "model_count": [240.1234, 500.0, 321.0, 654.0],
        })
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            quantity=DataCol.ELECTRICITY_TOTAL,
            group_by="state",
            aggregation_type=Metric.average,
            coverage=CoverageType.all_units,
            view=ViewType.value_view,
        )

        fig = create_stacked_plot(data, spec)

        recs_traces = [trace for trace in fig.data if trace.name == "RECS 2020"]
        resstock_traces = [trace for trace in fig.data if trace.name == "ResStock 2025"]

        assert recs_traces
        assert resstock_traces
        assert all("Value: %{customdata[0]}" in trace.hovertemplate for trace in fig.data)
        assert all("%{customdata[1]}" in trace.hovertemplate for trace in fig.data)
        assert all("kWh" not in trace.customdata[0][0] for trace in fig.data)
        assert any(trace.customdata[0][0] == "1.22B" for trace in recs_traces)
        assert all(trace.customdata[0][1].startswith("Number of Samples:") for trace in recs_traces)
        assert any(trace.customdata[0][0] == "1.10B" for trace in resstock_traces)
        assert all(trace.customdata[0][1].startswith("Number of Models:") for trace in resstock_traces)
