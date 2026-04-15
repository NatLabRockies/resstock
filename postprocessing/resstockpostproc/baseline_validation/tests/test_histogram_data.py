"""Tests for baseline-validation exact histogram data loaders."""

from pathlib import Path

import polars as pl

from resstockpostproc.baseline_validation.data_processing import histogram_data
from resstockpostproc.baseline_validation.schema.plot_spec import CoverageType
from resstockpostproc.baseline_validation.schema.workflow_schema import DataSourceConfig
from resstockpostproc.shared_utils.db_column_names import DataCol, DBSchema


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
