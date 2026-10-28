"""End-to-end smoke test: one essential plot per reference dataset and one query per Athena table/view.

Each test exercises a distinct data path:

  Dataset  | ResStock data path                          | Athena table
  ---------|---------------------------------------------|------------------------------
  EIA ann  | annual parquet fast path (no Athena)        | —
  RECS ann | annual parquet fast path (no Athena)        | —
  EIA mon  | timeseries Athena query                     | <table>_ts_by_state
  LRD ann  | utility Athena annual query                 | <table>_md_national_parquet

Requires live AWS SSO credentials. Skip this file when credentials are unavailable:

    uv run pytest --ignore=resstockpostproc/baseline_validation/tests/test_pipeline_smoke.py
"""

from __future__ import annotations

import polars as pl
import pytest
from plotly import graph_objects as go

from resstockpostproc.baseline_validation.data_processing.gather_data import get_plot_data
from resstockpostproc.baseline_validation.plotters import lrd_plotter, main_plotter
from resstockpostproc.baseline_validation.schema.plot_spec import (
    ComparisonDataset,
    CoverageType,
    Metric,
    PlotSpec,
    Resolution,
    ViewType,
)
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow
from resstockpostproc.shared_utils.db_column_names import DataCol

# ──────────────────────────────────────────────────────────────────────────────
# Shared helpers
# ──────────────────────────────────────────────────────────────────────────────

_EXPECTED_SOURCES: set[str] = {src.name for src in workflow.data_sources}


def _assert_nonempty(df: pl.DataFrame | None, label: str) -> pl.DataFrame:
    if df is None or df.is_empty():
        pytest.fail(f"{label}: data is None or empty")
    return df


def _assert_has_all_sources(df: pl.DataFrame, label: str) -> None:
    """Every configured workflow source must appear in the merged data."""
    found = set(df["source"].unique().to_list())
    missing = _EXPECTED_SOURCES - found
    assert not missing, (
        f"{label}: sources missing from data — {sorted(missing)}.\n"
        f"Found: {sorted(found)}"
    )


def _assert_figure_has_traces(fig: go.Figure, label: str) -> None:
    assert isinstance(fig, go.Figure), f"{label}: expected go.Figure, got {type(fig)}"
    assert len(fig.data) > 0, f"{label}: figure has no traces"


# ──────────────────────────────────────────────────────────────────────────────
# Smoke tests
# ──────────────────────────────────────────────────────────────────────────────


class TestPipelineSmoke:
    """One representative plot per reference dataset + one query per Athena table.

    All tests require live AWS credentials.  If a source has no timeseries
    table (ts_table is None), the timeseries test will flag it via the missing-
    source assertion rather than silently pass.
    """

    # ------------------------------------------------------------------
    # EIA annual electricity by state
    # Exercises: EIA static parquet + ResStock annual parquet fast path.
    # No Athena query fired for state grouping.
    # ------------------------------------------------------------------
    def test_eia_annual_electricity_by_state(self):
        label = "EIA annual electricity by state"
        spec = PlotSpec(
            comparison_dataset=ComparisonDataset.eia,
            quantity=DataCol.ELECTRICITY_TOTAL,
            resolution=Resolution.year,
            aggregation_type=Metric.total,
            coverage=CoverageType.all_units,
            group_by="state",
            view=ViewType.value_view,
        )
        data = _assert_nonempty(get_plot_data(spec), label)
        _assert_has_all_sources(data, label)
        assert "electricity_total_value" in data.columns, f"{label}: missing value column"
        assert "state" in data.columns, f"{label}: missing state column"

        fig, _title = main_plotter.create_plot(data, spec)
        _assert_figure_has_traces(fig, label)

    # ------------------------------------------------------------------
    # RECS annual electricity average by state
    # Exercises: RECS microdata parquet + ResStock annual parquet fast path.
    # No Athena query fired.
    # ------------------------------------------------------------------
    def test_recs_annual_electricity_avg_by_state(self):
        label = "RECS annual electricity average by state"
        spec = PlotSpec(
            comparison_dataset=ComparisonDataset.recs,
            quantity=DataCol.ELECTRICITY_TOTAL,
            resolution=Resolution.year,
            aggregation_type=Metric.average,
            coverage=CoverageType.all_units,
            group_by="state",
            view=ViewType.value_view,
        )
        data = _assert_nonempty(get_plot_data(spec), label)
        _assert_has_all_sources(data, label)
        assert "electricity_total_value" in data.columns, f"{label}: missing value column"

        fig, _title = main_plotter.create_plot(data, spec)
        _assert_figure_has_traces(fig, label)

    # ------------------------------------------------------------------
    # EIA monthly electricity by state
    # Exercises: EIA monthly parquet + ResStock Athena timeseries table
    # (_ts_by_state view).  This is the query that fails silently when the
    # timeseries view is missing or has schema issues.
    # ------------------------------------------------------------------
    def test_eia_monthly_electricity_by_state(self):
        label = "EIA monthly electricity by state (timeseries Athena query)"
        spec = PlotSpec(
            comparison_dataset=ComparisonDataset.eia,
            quantity=DataCol.ELECTRICITY_TOTAL,
            resolution=Resolution.month,
            aggregation_type=Metric.total,
            coverage=CoverageType.all_units,
            group_by="state",
            view=ViewType.value_view,
        )
        data = _assert_nonempty(get_plot_data(spec), label)
        _assert_has_all_sources(data, label)
        assert "month" in data.columns, f"{label}: missing month column"
        assert "state" in data.columns, f"{label}: missing state column"

        fig, _title = main_plotter.create_plot(data, spec)
        _assert_figure_has_traces(fig, label)

    # ------------------------------------------------------------------
    # LRD annual electricity by utility (eiaid)
    # Exercises: LRD static parquet + ResStock Athena baseline table
    # (_md_national_parquet view) via utility.aggregate_annual_by_eiaid.
    # ------------------------------------------------------------------
    def test_lrd_annual_electricity_by_eiaid(self):
        label = "LRD annual electricity by utility (Athena baseline table query)"
        spec = PlotSpec(
            comparison_dataset=ComparisonDataset.lrd,
            quantity=DataCol.ELECTRICITY_TOTAL,
            resolution=Resolution.year,
            aggregation_type=Metric.average,
            coverage=CoverageType.all_units,
            group_by="eiaid",
            view=ViewType.value_view,
        )
        data = _assert_nonempty(get_plot_data(spec), label)
        # LRD only provides data for utilities it has records for, so we only
        # check that at least one ResStock source appears (not necessarily all).
        found = set(data["source"].unique().to_list())
        resstock_found = _EXPECTED_SOURCES & found
        assert resstock_found, (
            f"{label}: no ResStock sources found in data.\n"
            f"Found sources: {sorted(found)}"
        )
        assert "eiaid" in data.columns, f"{label}: missing eiaid column"

        fig, _title = lrd_plotter.create_plot(data, spec)
        _assert_figure_has_traces(fig, label)

    # ------------------------------------------------------------------
    # ResStock annual data: verify the parquet file is present and readable
    # for every configured data source.
    # ------------------------------------------------------------------
    def test_resstock_annual_parquet_accessible_for_all_sources(self):
        """The local cached parquet for every data source can be scanned."""
        for src in workflow.data_sources:
            path = workflow.get_resstock_data_file(src.name)
            assert path.exists(), (
                f"ResStock parquet not found for source '{src.name}': {path}\n"
                "Run workflow.ensure_resstock_data_files() or check S3 credentials."
            )
            lf = pl.scan_parquet(path)
            schema = lf.collect_schema()
            assert len(schema) > 0, f"Parquet schema empty for source '{src.name}'"
            assert "weight" in schema.names(), (
                f"Missing 'weight' column in parquet for source '{src.name}'"
            )

    # ------------------------------------------------------------------
    # Natural gas monthly (second fuel type, different timeseries columns)
    # Exercises: EIA monthly gas parquet + ResStock Athena timeseries table
    # for a second end-use to catch column-name or schema mismatches.
    # ------------------------------------------------------------------
    def test_eia_monthly_natural_gas_by_state(self):
        label = "EIA monthly natural gas by state (timeseries Athena query, second fuel)"
        spec = PlotSpec(
            comparison_dataset=ComparisonDataset.eia,
            quantity=DataCol.NATURAL_GAS_TOTAL,
            resolution=Resolution.month,
            aggregation_type=Metric.total,
            coverage=CoverageType.all_units,
            group_by="state",
            view=ViewType.value_view,
        )
        data = _assert_nonempty(get_plot_data(spec), label)
        _assert_has_all_sources(data, label)
        assert "month" in data.columns, f"{label}: missing month column"
        assert "natural_gas_total_value" in data.columns, f"{label}: missing nat-gas column"

        fig, _title = main_plotter.create_plot(data, spec)
        _assert_figure_has_traces(fig, label)
