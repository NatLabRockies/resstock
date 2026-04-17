"""Tests for baseline-validation exact histogram data loaders."""

from pathlib import Path
from types import SimpleNamespace

import polars as pl
import pytest

from resstockpostproc.baseline_validation.data_processing import histogram_data
from resstockpostproc.baseline_validation.schema.plot_spec import (
    ComparisonDataset,
    CoverageType,
    Layout,
    Metric,
    PlotSpec,
    Resolution,
    ViewType,
)
from resstockpostproc.baseline_validation.schema.workflow_schema import DataSourceConfig
from resstockpostproc.shared_utils.db_column_names import DataCol, DBSchema


def _make_histogram_spec(**overrides) -> PlotSpec:
    defaults = dict(
        comparison_dataset=ComparisonDataset.recs,
        quantity=DataCol.ELECTRICITY_TOTAL,
        resolution=Resolution.year,
        aggregation_type=Metric.distribution,
        coverage=CoverageType.all_units,
        group_by="vintage",
        focus_on=(("state", "CA"),),
        view=ViewType.value_view,
        layout=Layout.histogram,
    )
    defaults.update(overrides)
    return PlotSpec(**defaults)


class TestHistogramRawLoaders:
    def test_recs_loader_uses_nweight_and_users_only_filter(self, monkeypatch):
        recs = pl.DataFrame(
            {
                "KWH": [0.0, 25.0],
                "NWEIGHT": [2.0, 3.0],
            }
        )
        monkeypatch.setattr(histogram_data, "get_df_from_s3", lambda *_args, **_kwargs: recs)

        out_all = histogram_data._load_recs_hist_rows(
            quantity=DataCol.ELECTRICITY_TOTAL,
            coverage=CoverageType.all_units,
            group_cols=[],
        )
        assert out_all["weight"].to_list() == [2.0, 3.0]

        out_users = histogram_data._load_recs_hist_rows(
            quantity=DataCol.ELECTRICITY_TOTAL,
            coverage=CoverageType.users_only,
            group_cols=[],
        )
        assert out_users["value"].to_list() == [25.0]
        assert out_users["weight"].to_list() == [3.0]

    def test_resstock_loader_uses_weight_and_users_only_filter(self, monkeypatch):
        raw = pl.DataFrame(
            {
                "out.electricity.total.energy_consumption..kwh": [0.0, 40.0],
                "weight": [1.5, 4.5],
            }
        )
        monkeypatch.setattr(
            type(histogram_data.workflow),
            "get_resstock_data_file",
            lambda self, _name: Path("/tmp/fake_upgrade0.parquet"),
        )
        monkeypatch.setattr(histogram_data.pl, "scan_parquet", lambda _path: raw.lazy())

        source = DataSourceConfig(
            name="resstock_2025",
            db_name="buildstock",
            table_name="baseline",
            db_schema=DBSchema.OEDI_NEW,
        )

        out_all = histogram_data._load_resstock_hist_rows(
            data_source=source,
            quantity=DataCol.ELECTRICITY_TOTAL,
            coverage=CoverageType.all_units,
            group_cols=[],
        )
        assert out_all["weight"].to_list() == [1.5, 4.5]
        assert out_all["source"].unique(maintain_order=True).to_list() == ["resstock_2025"]

        out_users = histogram_data._load_resstock_hist_rows(
            data_source=source,
            quantity=DataCol.ELECTRICITY_TOTAL,
            coverage=CoverageType.users_only,
            group_cols=[],
        )
        assert out_users["value"].to_list() == [40.0]
        assert out_users["weight"].to_list() == [4.5]

    def test_resstock_quantity_resolution_handles_single_dot_kwh_suffix(self):
        available = {"out.electricity.total.energy_consumption.kwh"}
        expr = histogram_data._resstock_quantity_expr(
            quantity=DataCol.ELECTRICITY_TOTAL,
            db_schema=DBSchema.OEDI,
            available_cols=available,
        )
        assert expr.meta.output_name() == "out.electricity.total.energy_consumption.kwh"

    def test_resstock_loader_skips_source_when_optional_quantity_column_is_missing(self, monkeypatch):
        raw = pl.DataFrame(
            {
                "out.electricity.total.energy_consumption..kwh": [10.0, 40.0],
                "weight": [1.5, 4.5],
            }
        )
        monkeypatch.setattr(
            type(histogram_data.workflow),
            "get_resstock_data_file",
            lambda self, _name: Path("/tmp/fake_upgrade0.parquet"),
        )
        monkeypatch.setattr(histogram_data.pl, "scan_parquet", lambda _path: raw.lazy())

        source = DataSourceConfig(
            name="resstock_2024",
            db_name="buildstock",
            table_name="baseline",
            db_schema=DBSchema.OEDI_NEW,
        )

        out = histogram_data._load_resstock_hist_rows(
            data_source=source,
            quantity=DataCol.ELECTRICITY_TELEVISION,
            coverage=CoverageType.all_units,
            group_cols=[],
        )

        assert out.is_empty()
        assert out.columns == ["value", "weight", "source"]


class TestHistogramDataGeometryScope:
    def test_focus_slice_uses_recs_geometry_across_grouped_facets(self, monkeypatch):
        histogram_data._get_distribution_histogram_base.cache_clear()

        recs = pl.DataFrame(
            {
                "state": ["CA"] * 4 + ["TX"] * 4,
                "vintage": ["old", "old", "new", "new"] * 2,
                "value": [
                    10.0, 20.0, 10.0, 30.0,
                    100.0, 200.0, 100.0, 300.0,
                ],
                "weight": [49.0, 1.0, 49.0, 1.0] * 2,
                "source": ["recs_2020"] * 8,
            }
        )
        resstock = pl.DataFrame(
            {
                "state": ["CA"] * 4 + ["TX"] * 4,
                "vintage": ["old", "old", "new", "new"] * 2,
                "value": [
                    10.0, 500.0, 10.0, 600.0,
                    100.0, 5000.0, 100.0, 7000.0,
                ],
                "weight": [1.0] * 8,
                "source": ["resstock_2025"] * 8,
            }
        )

        source = DataSourceConfig(
            name="resstock_2025",
            db_name="buildstock",
            table_name="baseline",
            db_schema=DBSchema.OEDI_NEW,
        )

        monkeypatch.setattr(histogram_data, "_load_recs_hist_rows", lambda *_args, **_kwargs: recs)
        monkeypatch.setattr(
            histogram_data,
            "_load_resstock_hist_rows",
            lambda *_args, **_kwargs: resstock,
        )
        monkeypatch.setattr(
            histogram_data,
            "workflow",
            SimpleNamespace(data_sources=[source], data_source_labels={}),
        )

        ca = histogram_data.get_distribution_histogram_data(_make_histogram_spec(focus_on=(("state", "CA"),)))
        tx = histogram_data.get_distribution_histogram_data(_make_histogram_spec(focus_on=(("state", "TX"),)))

        assert "state" not in ca.columns
        assert "vintage" in ca.columns

        ca_overflow_left = ca.filter(pl.col("bin") == 49)["bin_left"].unique()
        tx_overflow_left = tx.filter(pl.col("bin") == 49)["bin_left"].unique()
        assert ca_overflow_left.len() == 1
        assert tx_overflow_left.len() == 1
        assert ca_overflow_left.item() == pytest.approx(10.0)
        assert tx_overflow_left.item() == pytest.approx(100.0)

        for out in (ca, tx):
            overflow = out.filter(pl.col("bin") == 49)
            assert overflow["bin_left"].n_unique() == 1

            width_min, width_max = (
                out.filter(pl.col("bin") != 49)
                .select(
                    (pl.col("bin_right") - pl.col("bin_left")).min().alias("min_width"),
                    (pl.col("bin_right") - pl.col("bin_left")).max().alias("max_width"),
                )
                .row(0)
            )
            assert width_min == pytest.approx(width_max)

    def test_recs_anchor_keeps_recs_overflow_near_two_percent(self, monkeypatch):
        histogram_data._get_distribution_histogram_base.cache_clear()

        recs_values = list(range(100))
        recs = pl.DataFrame(
            {
                "state": ["CA"] * len(recs_values),
                "value": recs_values,
                "weight": [1.0] * len(recs_values),
                "source": ["recs_2020"] * len(recs_values),
            }
        )
        resstock_values = list(range(50)) * 20
        resstock = pl.DataFrame(
            {
                "state": ["CA"] * len(resstock_values),
                "value": resstock_values,
                "weight": [1.0] * len(resstock_values),
                "source": ["resstock_2025"] * len(resstock_values),
            }
        )

        source = DataSourceConfig(
            name="resstock_2025",
            db_name="buildstock",
            table_name="baseline",
            db_schema=DBSchema.OEDI_NEW,
        )

        monkeypatch.setattr(histogram_data, "_load_recs_hist_rows", lambda *_args, **_kwargs: recs)
        monkeypatch.setattr(
            histogram_data,
            "_load_resstock_hist_rows",
            lambda *_args, **_kwargs: resstock,
        )
        monkeypatch.setattr(
            histogram_data,
            "workflow",
            SimpleNamespace(data_sources=[source], data_source_labels={}),
        )

        out = histogram_data.get_distribution_histogram_data(
            _make_histogram_spec(group_by=None, focus_on=(("state", "CA"),))
        )

        recs_overflow = out.filter(
            (pl.col("source") == "recs_2020") & (pl.col("bin") == 49)
        )["count_pct"].item()
        assert recs_overflow == pytest.approx(2.0)

    def test_public_histogram_pipeline_caps_recs_overflow_below_top_jump(self, monkeypatch):
        histogram_data._get_distribution_histogram_base.cache_clear()

        recs = pl.DataFrame(
            {
                "state": ["CA"] * 3,
                "value": [0.0, 100.0, 200.0],
                "weight": [97.66, 1.0, 1.34],
                "source": ["recs_2020"] * 3,
            }
        )
        resstock = pl.DataFrame(
            {
                "state": ["CA"] * 3,
                "value": [0.0, 100.0, 500.0],
                "weight": [1.0, 1.0, 1.0],
                "source": ["resstock_2025"] * 3,
            }
        )

        source = DataSourceConfig(
            name="resstock_2025",
            db_name="buildstock",
            table_name="baseline",
            db_schema=DBSchema.OEDI_NEW,
        )

        monkeypatch.setattr(histogram_data, "_load_recs_hist_rows", lambda *_args, **_kwargs: recs)
        monkeypatch.setattr(
            histogram_data,
            "_load_resstock_hist_rows",
            lambda *_args, **_kwargs: resstock,
        )
        monkeypatch.setattr(
            histogram_data,
            "workflow",
            SimpleNamespace(data_sources=[source], data_source_labels={}),
        )

        out = histogram_data.get_distribution_histogram_data(
            _make_histogram_spec(group_by=None, focus_on=(("state", "CA"),))
        )

        recs_overflow = out.filter(
            (pl.col("source") == "recs_2020") & (pl.col("bin") == 49)
        )["count_pct"].item()
        assert recs_overflow == pytest.approx(1.34)
