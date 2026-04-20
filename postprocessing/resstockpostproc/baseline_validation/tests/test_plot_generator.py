"""Tests for plot_generator discrepancy math and list unnesting."""

import sys
from types import SimpleNamespace

import polars as pl
import pytest
import plotly.graph_objects as go

import resstockpostproc.baseline_validation.plot_generator as plot_generator_module
from resstockpostproc.baseline_validation.dashboard_paths import relative_href_from_file
from resstockpostproc.baseline_validation.footnotes import (
    RECS_ANNUAL_CI_NOTE,
    RECS_OCCUPIED_UNITS_NOTE,
    get_plot_notes,
)
from resstockpostproc.baseline_validation.plot_generator import (
    DEFAULT_PLOT_OUTPUT_FORMATS,
    _all_enduses_viz_label,
    _apply_lrd_sidebar_semantics,
    _build_spec_entries,
    _collect_stacked_notes,
    _compute_discrepancy,
    _ensure_kaleido_sync_server,
    _emit_layout_for_final_group,
    _generate_spec_plots,
    _has_static_image_outputs,
    _plot_output_path,
    _data_output_path,
    _should_generate_stacked_page_group,
    _should_generate_stacked_table,
    _stop_kaleido_sync_server_if_owned,
    _stacked_title_from_grouped,
    _to_all_enduses_tall_data,
    generate_plots,
)
from resstockpostproc.baseline_validation.schema.plot_spec import (
    PlotSpec,
    Metric,
    CoverageType,
    Resolution,
    ComparisonDataset,
    ViewType,
    Layout,
    FileType,
)
from resstockpostproc.shared_utils.db_column_names import DataCol


def _make_spec(**overrides):
    defaults = dict(
        comparison_dataset=ComparisonDataset.eia,
        quantity=DataCol.ELECTRICITY_TOTAL,
        resolution=Resolution.year,
        aggregation_type=Metric.total,
        coverage=CoverageType.all_units,
        group_by="state",
        view=ViewType.value_view,
    )
    defaults.update(overrides)
    return PlotSpec(**defaults)


class TestComputeDiscrepancy:
    """Tests for MAPE calculation."""

    def test_normal_case(self):
        """Verify MAPE against hand-calculated values."""
        # ref = [100, 200], rs = [110, 190]
        # terms = [10/100, 10/200]
        # MAPE = mean(0.1, 0.05) * 100 = 7.5
        data = pl.DataFrame({
            "source": ["eia_2018", "eia_2018", "resstock_2024", "resstock_2024"],
            "state": ["CA", "NY", "CA", "NY"],
            "electricity_total_value": [100.0, 200.0, 110.0, 190.0],
        })
        spec = _make_spec()
        metrics = _compute_discrepancy(data, spec)

        assert "ResStock 2024" in metrics
        mape = metrics["ResStock 2024"]
        assert mape == pytest.approx(7.5)

    def test_positive_bias(self):
        """ResStock consistently higher -> higher MAPE."""
        data = pl.DataFrame({
            "source": ["eia_2018", "resstock_2024"],
            "state": ["CA", "CA"],
            "electricity_total_value": [100.0, 120.0],
        })
        spec = _make_spec()
        metrics = _compute_discrepancy(data, spec)

        mape = metrics["ResStock 2024"]
        assert mape == pytest.approx(20.0)

    def test_multiple_sources(self):
        """Each ResStock source should get its own metric entry."""
        data = pl.DataFrame({
            "source": ["eia_2018", "resstock_2024", "resstock_2025"],
            "state": ["CA", "CA", "CA"],
            "electricity_total_value": [100.0, 120.0, 110.0],
        })
        spec = _make_spec()
        metrics = _compute_discrepancy(data, spec)

        assert set(metrics.keys()) == {"ResStock 2024", "ResStock 2025"}
        assert metrics["ResStock 2024"] == pytest.approx(20.0)
        assert metrics["ResStock 2025"] == pytest.approx(10.0)

    def test_returns_empty_for_all_quantity(self):
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            quantity=DataCol.ALL,
            aggregation_type=Metric.average,
        )
        data = pl.DataFrame({"source": ["recs"], "state": ["CA"], "electricity_total_value": [1.0]})
        assert _compute_discrepancy(data, spec) == {}

    def test_returns_empty_for_distribution_view(self):
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            aggregation_type=Metric.distribution,
            view=ViewType.value_view,
        )
        data = pl.DataFrame({"source": ["recs"], "state": ["CA"], "electricity_total_value": [1.0]})
        assert _compute_discrepancy(data, spec) == {}

    def test_returns_empty_when_no_resstock_rows(self):
        data = pl.DataFrame({
            "source": ["eia_2018", "eia_2018"],
            "state": ["CA", "NY"],
            "electricity_total_value": [100.0, 200.0],
        })
        spec = _make_spec()
        assert _compute_discrepancy(data, spec) == {}

    def test_returns_empty_when_zero_reference(self):
        data = pl.DataFrame({
            "source": ["eia_2018", "resstock_2024"],
            "state": ["CA", "CA"],
            "electricity_total_value": [0.0, 50.0],
        })
        spec = _make_spec()
        assert _compute_discrepancy(data, spec) == {}

    def test_skips_zero_reference_rows_in_mape_average(self):
        data = pl.DataFrame({
            "source": ["eia_2018", "eia_2018", "resstock_2024", "resstock_2024"],
            "state": ["CA", "NY", "CA", "NY"],
            "electricity_total_value": [0.0, 200.0, 50.0, 220.0],
        })
        spec = _make_spec()

        metrics = _compute_discrepancy(data, spec)

        # CA is excluded because the reference is zero; NY contributes 20/200 = 10%
        assert metrics["ResStock 2024"] == pytest.approx(10.0)

    def test_excludes_us_total_by_default(self):
        """US Total rows should be excluded when focus_on is not 'US Total'."""
        data = pl.DataFrame({
            "source": ["eia_2018", "eia_2018", "resstock_2024", "resstock_2024"],
            "state": ["CA", "US Total", "CA", "US Total"],
            "electricity_total_value": [100.0, 999.0, 100.0, 999.0],
        })
        spec = _make_spec()
        mape = _compute_discrepancy(data, spec)["ResStock 2024"]

        # Only CA is used (US Total excluded) → perfect match
        assert mape == pytest.approx(0.0)

    def test_includes_us_total_when_focused(self):
        """When focused on US Total, US Total rows should be included."""
        data = pl.DataFrame({
            "source": ["eia_2018", "resstock_2024"],
            "state": ["US Total", "US Total"],
            "electricity_total_value": [100.0, 120.0],
        })
        spec = _make_spec(focus_on=(("state", "US Total"),), group_by=None)
        mape = _compute_discrepancy(data, spec)["ResStock 2024"]
        assert mape == pytest.approx(20.0)

    def test_units_count_quantity(self):
        """When quantity is UNITS_COUNT, val_col should be 'units_count'."""
        data = pl.DataFrame({
            "source": ["eia_2018", "resstock_2024"],
            "state": ["CA", "CA"],
            "units_count": [1000.0, 1100.0],
        })
        spec = _make_spec(quantity=DataCol.UNITS_COUNT)
        mape = _compute_discrepancy(data, spec)["ResStock 2024"]
        assert mape == pytest.approx(10.0)

    def test_monthly_resolution_joins_on_month(self):
        """Monthly data should join on both state and month."""
        data = pl.DataFrame({
            "source": ["eia_2018", "eia_2018", "resstock_2024", "resstock_2024"],
            "state": ["CA", "CA", "CA", "CA"],
            "month": ["JAN", "FEB", "JAN", "FEB"],
            "electricity_total_value": [100.0, 200.0, 110.0, 220.0],
        })
        spec = _make_spec(resolution=Resolution.month)
        mape = _compute_discrepancy(data, spec)["ResStock 2024"]
        assert mape == pytest.approx(10.0)


class TestAllEndusesHelpers:
    def test_to_all_enduses_tall_data_renames_quantity_prefix_and_adds_enduse(self):
        spec = _make_spec(quantity=DataCol.ELECTRICITY_TOTAL)
        df = pl.DataFrame({
            "source": ["recs_2020"],
            "state": ["CA"],
            "electricity_total_value": [123.4],
            "electricity_total_percent_difference": [1.5],
        })
        out = _to_all_enduses_tall_data(df, spec)

        assert out.columns[0] == "enduse"
        assert out["enduse"].to_list() == ["Electricity"]
        assert "all_value" in out.columns
        assert "all_percent_difference" in out.columns
        assert "electricity_total_value" not in out.columns

    def test_grouped_to_stacked_title_suffix(self):
        grouped = "Annual Enduse Consumption by State (grouped view)"
        grouped_diff = "Annual Enduse Consumption by State (grouped difference view)"

        assert _stacked_title_from_grouped(grouped, ViewType.value_view).endswith("(stacked view)")
        assert _stacked_title_from_grouped(grouped_diff, ViewType.diff_view).endswith("(stacked difference view)")

    def test_all_enduses_viz_label_convention(self):
        value_spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            quantity=DataCol.ALL,
            aggregation_type=Metric.average,
            view=ViewType.value_view,
        )
        diff_spec = value_spec.model_copy(update={"view": ViewType.diff_view})

        assert _all_enduses_viz_label(value_spec, stacked=False) == "Bar Plot (grouped)"
        assert _all_enduses_viz_label(diff_spec, stacked=False) == "Bar Plot (grouped difference view)"
        assert _all_enduses_viz_label(value_spec, stacked=True) == "Bar Plot (stacked)"
        assert _all_enduses_viz_label(diff_spec, stacked=True) == "Bar Plot (stacked difference view)"

    def test_should_generate_stacked_table(self):
        assert _should_generate_stacked_table(
            "State", ComparisonDataset.recs, Resolution.year, Metric.total
        ) is True
        assert _should_generate_stacked_table(
            "", ComparisonDataset.recs, Resolution.year, Metric.total
        ) is False
        assert _should_generate_stacked_table(
            "", ComparisonDataset.recs, Resolution.month, Metric.total
        ) is True
        assert _should_generate_stacked_table(
            "", ComparisonDataset.recs, Resolution.year, Metric.distribution
        ) is True
        assert _should_generate_stacked_table(
            "", ComparisonDataset.eia, Resolution.year, Metric.total
        ) is True

    def test_should_generate_stacked_page_group_skips_lrd(self):
        lrd_spec = _make_spec(
            comparison_dataset=ComparisonDataset.lrd,
            quantity=DataCol.ELECTRICITY_TOTAL,
            aggregation_type=Metric.average,
            coverage=CoverageType.all_units,
            group_by="utility",
            view=ViewType.value_view,
        )
        qty_entries = [
            ("Electricity", [(lrd_spec, "Bar Plot (grouped)")]),
            ("Natural Gas", [(lrd_spec, "Bar Plot (grouped)")]),
        ]
        assert _should_generate_stacked_page_group(qty_entries) is False

    def test_should_generate_stacked_page_group_requires_multiple_quantities(self):
        recs_spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            quantity=DataCol.ELECTRICITY_TOTAL,
            aggregation_type=Metric.average,
            coverage=CoverageType.all_units,
            group_by="state",
            view=ViewType.value_view,
        )
        single_qty_entries = [("Electricity", [(recs_spec, "Bar Plot (grouped)")])]
        two_qty_entries = [
            ("Electricity", [(recs_spec, "Bar Plot (grouped)")]),
            ("Natural Gas", [(recs_spec, "Bar Plot (grouped)")]),
        ]
        assert _should_generate_stacked_page_group(single_qty_entries) is False
        assert _should_generate_stacked_page_group(two_qty_entries) is True

    def test_collect_stacked_notes_dedupes_shared_quantity_notes(self):
        recs_elec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            quantity=DataCol.ELECTRICITY_TOTAL,
            aggregation_type=Metric.average,
            group_by="state",
            view=ViewType.value_view,
        )
        recs_gas = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            quantity=DataCol.NATURAL_GAS_TOTAL,
            aggregation_type=Metric.average,
            group_by="state",
            view=ViewType.value_view,
        )
        qty_entries = [
            ("Electricity", [(recs_elec, "Bar Plot (grouped)")]),
            ("Natural Gas", [(recs_gas, "Bar Plot (grouped)")]),
        ]

        notes = _collect_stacked_notes(qty_entries, get_plot_notes)

        assert notes == [RECS_OCCUPIED_UNITS_NOTE, RECS_ANNUAL_CI_NOTE]


class TestRelatedSpecFamilies:
    def test_state_annual_gets_ordered_auto_and_two_column_specs(self):
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            aggregation_type=Metric.average,
            quantity=DataCol.ELECTRICITY_TOTAL,
            resolution=Resolution.year,
            group_by="state",
            view=ViewType.value_view,
        )
        family = _make_related_specs(spec)
        assert [(s.view, s.layout) for s in family] == [
            (ViewType.value_view, Layout.auto),
            (ViewType.diff_view, Layout.auto),
            (ViewType.value_view, Layout.two_column),
            (ViewType.diff_view, Layout.two_column),
        ]

    def test_ineligible_specs_do_not_get_two_column_layout(self):
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            aggregation_type=Metric.average,
            quantity=DataCol.ELECTRICITY_TOTAL,
            resolution=Resolution.month,
            group_by="state",
            view=ViewType.value_view,
        )
        family = _make_related_specs(spec)
        assert all(s.layout == Layout.auto for s in family)

    def test_distribution_family_adds_histogram_companion(self):
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            aggregation_type=Metric.distribution,
            quantity=DataCol.ELECTRICITY_TOTAL,
            resolution=Resolution.year,
            group_by="state",
            view=ViewType.value_view,
        )
        family = _make_related_specs(spec)
        assert [(s.view, s.layout) for s in family] == [
            (ViewType.value_view, Layout.auto),
            (ViewType.value_view, Layout.histogram),
        ]

    def test_histogram_layout_emits_for_any_group(self):
        hist_spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            aggregation_type=Metric.distribution,
            quantity=DataCol.ELECTRICITY_TOTAL,
            resolution=Resolution.year,
            group_by="state",
            view=ViewType.value_view,
            layout=Layout.histogram,
        )
        assert _emit_layout_for_final_group(hist_spec, None) is True
        assert _emit_layout_for_final_group(hist_spec, "state") is True

    def test_two_column_layout_emits_only_for_final_state_group(self):
        two_col_spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            aggregation_type=Metric.average,
            quantity=DataCol.ELECTRICITY_TOTAL,
            resolution=Resolution.year,
            group_by="state",
            view=ViewType.value_view,
            layout=Layout.two_column,
        )
        assert _emit_layout_for_final_group(two_col_spec, "state") is True
        assert _emit_layout_for_final_group(two_col_spec, None) is False
        assert _emit_layout_for_final_group(two_col_spec, "vintage") is False

    def test_build_spec_entries_uses_unique_viz_labels_for_layout_variants(self):
        spec = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            aggregation_type=Metric.average,
            quantity=DataCol.ELECTRICITY_TOTAL,
            resolution=Resolution.year,
            group_by="state",
            view=ViewType.value_view,
        )
        entries = _build_spec_entries(_make_related_specs(spec))
        labels = [label for _, label in entries]
        assert len(labels) == len(set(labels))
        assert "Bar Plot (two_column)" in labels
        assert "Bar Plot (two_column difference view)" in labels


class TestGenerateSpecPlotsPrimaryDataAnchor:
    def test_data_and_table_generated_once_for_primary_spec(self, tmp_path, monkeypatch):
        spec_primary = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            aggregation_type=Metric.average,
            quantity=DataCol.ELECTRICITY_TOTAL,
            resolution=Resolution.year,
            group_by="state",
            view=ViewType.value_view,
            layout=Layout.auto,
        )
        spec_two_col = spec_primary.model_copy(update={"layout": Layout.two_column})
        spec_entries = [
            (spec_primary, spec_primary.display_viz_label),
            (spec_two_col, spec_two_col.display_viz_label),
        ]

        data = pl.DataFrame({
            "source": ["recs_2020", "resstock_2024"],
            "state": ["CA", "CA"],
            "electricity_total_value": [100.0, 110.0],
        })

        table_calls = []

        monkeypatch.setattr(
            "resstockpostproc.baseline_validation.plot_generator.get_plot_data",
            lambda _spec: data,
        )
        monkeypatch.setattr(
            "resstockpostproc.baseline_validation.plot_generator.get_plotting_function",
            lambda _ds: (lambda _data, _spec: (go.Figure(), "title")),
        )
        monkeypatch.setattr(
            "resstockpostproc.baseline_validation.plot_generator.save_figure",
            lambda *_args, **_kwargs: None,
        )
        monkeypatch.setattr(
            "resstockpostproc.baseline_validation.plot_generator._compute_discrepancy",
            lambda _data, _spec: {},
        )
        table_kwargs = {}
        monkeypatch.setattr(
            "resstockpostproc.baseline_validation.plot_generator.generate_data_table_html",
            lambda **kwargs: (table_calls.append(kwargs["output_path"]), table_kwargs.update(kwargs)),
        )

        result = _generate_spec_plots(
            spec_entries=spec_entries,
            output_formats=[FileType.html],
            link_format=FileType.html,
            output_root=tmp_path,
            plotly_asset_path=tmp_path / "dashboard_data" / "assets" / "plotly-3.1.1.min.js",
        )

        assert result is not None
        viz_parts, data_rel = result
        assert data_rel is not None
        assert len(table_calls) == 1

        _, primary_title = spec_primary.file_path_and_name
        _, two_col_title = spec_two_col.file_path_and_name
        assert "||dashboard_data/" in viz_parts
        assert "data table||dashboard_data/" in data_rel
        assert "download csv" not in data_rel
        assert primary_title in data_rel
        assert two_col_title not in data_rel
        expected_table_path = _data_output_path(tmp_path, spec_primary, FileType.html)
        expected_plot_path = _plot_output_path(tmp_path, spec_primary, FileType.html)
        assert table_kwargs["plot_rel_path"] == relative_href_from_file(expected_plot_path, expected_table_path)

    def test_static_images_are_batched_once_per_work_item(self, tmp_path, monkeypatch):
        spec_primary = _make_spec(
            comparison_dataset=ComparisonDataset.recs,
            aggregation_type=Metric.average,
            quantity=DataCol.ELECTRICITY_TOTAL,
            resolution=Resolution.year,
            group_by="state",
            view=ViewType.value_view,
            layout=Layout.auto,
        )
        spec_two_col = spec_primary.model_copy(update={"layout": Layout.two_column})
        spec_entries = [
            (spec_primary, spec_primary.display_viz_label),
            (spec_two_col, spec_two_col.display_viz_label),
        ]

        data = pl.DataFrame({
            "source": ["recs_2020", "resstock_2024"],
            "state": ["CA", "CA"],
            "electricity_total_value": [100.0, 110.0],
        })

        html_save_calls = []
        static_batch_calls = []

        monkeypatch.setattr(
            "resstockpostproc.baseline_validation.plot_generator.get_plot_data",
            lambda _spec: data,
        )
        monkeypatch.setattr(
            "resstockpostproc.baseline_validation.plot_generator.get_plotting_function",
            lambda _ds: (lambda _data, _spec: (go.Figure(), "title")),
        )
        monkeypatch.setattr(
            "resstockpostproc.baseline_validation.plot_generator.save_figure",
            lambda *_args, **kwargs: html_save_calls.append(kwargs["formats"]),
        )
        monkeypatch.setattr(
            "resstockpostproc.baseline_validation.plot_generator.save_static_images_batch",
            lambda jobs, output_root=None: static_batch_calls.append((jobs, output_root)),
        )
        monkeypatch.setattr(
            "resstockpostproc.baseline_validation.plot_generator._compute_discrepancy",
            lambda _data, _spec: {},
        )
        monkeypatch.setattr(
            "resstockpostproc.baseline_validation.plot_generator.generate_data_table_html",
            lambda **_kwargs: None,
        )

        _generate_spec_plots(
            spec_entries=spec_entries,
            output_formats=[FileType.html, FileType.svg],
            link_format=FileType.html,
            output_root=tmp_path,
            plotly_asset_path=tmp_path / "dashboard_data" / "assets" / "plotly-3.1.1.min.js",
        )

        assert html_save_calls == [[FileType.html], [FileType.html]]
        assert len(static_batch_calls) == 1
        jobs, output_root = static_batch_calls[0]
        assert output_root == tmp_path
        assert len(jobs) == 2
        assert all(fmt == FileType.svg for _, _, fmt in jobs)


class TestDefaultOutputFormats:
    def test_standard_run_uses_html_and_svg(self):
        assert DEFAULT_PLOT_OUTPUT_FORMATS == [FileType.html, FileType.svg]


class TestKaleidoSyncServerLifecycle:
    @staticmethod
    def _fake_kaleido_module(start_calls, stop_calls, running=False):
        server_state = {"running": running}

        class _FakeServer:
            def is_running(self):
                return server_state["running"]

        def _start_sync_server(*, silence_warnings=False, **kwargs):
            start_calls.append((silence_warnings, kwargs))
            server_state["running"] = True

        def _stop_sync_server(*, silence_warnings=False):
            stop_calls.append(silence_warnings)
            server_state["running"] = False

        return SimpleNamespace(
            _global_server=_FakeServer(),
            start_sync_server=_start_sync_server,
            stop_sync_server=_stop_sync_server,
        )

    def test_ensure_kaleido_sync_server_starts_once_and_tracks_ownership(self, monkeypatch):
        start_calls = []
        stop_calls = []
        fake_kaleido = self._fake_kaleido_module(start_calls, stop_calls)

        monkeypatch.setitem(sys.modules, "kaleido", fake_kaleido)
        monkeypatch.setattr(plot_generator_module, "_OWNS_KALEIDO_SYNC_SERVER", False)
        monkeypatch.setattr("plotly.io.defaults.plotlyjs", "/tmp/plotly.min.js")
        monkeypatch.setattr("plotly.io.defaults.mathjax", "/tmp/mathjax.js")

        assert _ensure_kaleido_sync_server() is True
        assert start_calls == [
            (
                True,
                {"n": 1, "plotlyjs": "/tmp/plotly.min.js", "mathjax": "/tmp/mathjax.js"},
            )
        ]
        assert plot_generator_module._OWNS_KALEIDO_SYNC_SERVER is True

        assert _ensure_kaleido_sync_server() is False
        assert len(start_calls) == 1

        _stop_kaleido_sync_server_if_owned()
        assert stop_calls == [True]
        assert plot_generator_module._OWNS_KALEIDO_SYNC_SERVER is False

    def test_stop_kaleido_sync_server_if_owned_skips_external_server(self, monkeypatch):
        stop_calls = []
        fake_kaleido = self._fake_kaleido_module([], stop_calls, running=True)

        monkeypatch.setitem(sys.modules, "kaleido", fake_kaleido)
        monkeypatch.setattr(plot_generator_module, "_OWNS_KALEIDO_SYNC_SERVER", False)

        _stop_kaleido_sync_server_if_owned()

        assert stop_calls == []

    def test_has_static_image_outputs_detects_svg_and_pdf(self):
        assert _has_static_image_outputs([FileType.html, FileType.svg]) is True
        assert _has_static_image_outputs([FileType.pdf]) is True
        assert _has_static_image_outputs([FileType.html, FileType.parquet]) is False

    def test_generate_plots_sequential_starts_and_stops_persistent_kaleido_server(self, tmp_path, monkeypatch):
        lifecycle_calls = []

        monkeypatch.setattr(
            plot_generator_module,
            "workflow",
            SimpleNamespace(
                data_source_labels={},
                output=SimpleNamespace(output_dir=tmp_path, run_name="seq-kaleido"),
            ),
        )
        monkeypatch.setattr(
            "resstockpostproc.baseline_validation.plot_generator.generate_all_templates",
            lambda: [],
        )
        monkeypatch.setattr(
            "resstockpostproc.baseline_validation.plot_generator.ensure_plotly_asset",
            lambda asset_dir: asset_dir / "plotly.min.js",
        )
        monkeypatch.setattr(
            "resstockpostproc.baseline_validation.plot_generator.init_html_index",
            lambda html_path, columns, data_dir=None: {"html_path": html_path, "data_dir": data_dir, "columns": columns},
        )
        monkeypatch.setattr(
            "resstockpostproc.baseline_validation.plot_generator.finalize_html_index",
            lambda _state: None,
        )
        monkeypatch.setattr(
            "resstockpostproc.baseline_validation.plot_generator._ensure_kaleido_sync_server",
            lambda: lifecycle_calls.append("start") or True,
        )
        monkeypatch.setattr(
            "resstockpostproc.baseline_validation.plot_generator._stop_kaleido_sync_server_if_owned",
            lambda: lifecycle_calls.append("stop"),
        )
        monkeypatch.setattr(plot_generator_module.TimingStats, "start_trace", lambda _path: None)
        monkeypatch.setattr(plot_generator_module.TimingStats, "stop_trace", lambda: None)
        monkeypatch.setattr(plot_generator_module.TimingStats, "summary", lambda: "timing summary")

        generate_plots(parallel=False)

        assert lifecycle_calls == ["start", "stop"]


class TestLRDSidebarSemantics:
    @staticmethod
    def _make_lrd_spec(resolution: Resolution) -> PlotSpec:
        defaults = dict(
            comparison_dataset=ComparisonDataset.lrd,
            quantity=DataCol.ELECTRICITY_TOTAL,
            aggregation_type=Metric.average,
            coverage=CoverageType.all_units,
            view=ViewType.value_view,
        )
        if resolution == Resolution.hour_of_day_matrix:
            return PlotSpec(
                resolution=resolution,
                group_by=None,
                focus_on=(("utility", "ComEd (IL)"),),
                **defaults,
            )
        return PlotSpec(
            resolution=resolution,
            group_by="utility",
            focus_on=(),
            **defaults,
        )

    def test_non_lrd_row_unchanged(self):
        row = {"Filter 1": "State: Alaska", "Filter 2": "", "Group By": "State"}
        spec = _make_spec()
        _apply_lrd_sidebar_semantics(row, spec, ())
        assert row == {"Filter 1": "State: Alaska", "Filter 2": "", "Group By": "State"}

    def test_lrd_default_facets(self):
        row = {"Filter 1": "stale", "Filter 2": "stale", "Group By": ""}
        spec = self._make_lrd_spec(Resolution.year)
        _apply_lrd_sidebar_semantics(row, spec, ())
        assert row["Filter 1"] == ""
        assert row["Filter 2"] == ""
        assert row["Group By"] == "Utility"

    @pytest.mark.parametrize(
        "resolution,expected_filter_1",
        [
            (Resolution.hour_of_day_summer, "Season: Summer"),
            (Resolution.hour_of_day_winter, "Season: Winter"),
        ],
    )
    def test_lrd_seasonal_facets(self, resolution, expected_filter_1):
        row = {"Filter 1": "", "Filter 2": "", "Group By": ""}
        spec = self._make_lrd_spec(resolution)
        _apply_lrd_sidebar_semantics(row, spec, ())
        assert row["Filter 1"] == expected_filter_1
        assert row["Filter 2"] == ""
        assert row["Group By"] == "Utility"

    def test_lrd_matrix_facets(self):
        row = {"Filter 1": "", "Filter 2": "stale", "Group By": ""}
        spec = self._make_lrd_spec(Resolution.hour_of_day_matrix)
        focus_on = (("utility", "ComEd (IL)"),)
        _apply_lrd_sidebar_semantics(row, spec, focus_on)
        assert row["Filter 1"] == "Utility: ComEd (IL)"
        assert row["Filter 2"] == ""
        assert row["Group By"] == "Month-Day"


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
    _make_related_specs,
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
