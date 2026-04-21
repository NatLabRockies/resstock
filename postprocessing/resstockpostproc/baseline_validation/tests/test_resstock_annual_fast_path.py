from pathlib import Path

import polars as pl
import pytest

from resstockpostproc.baseline_validation.plot_helpers import resstock_raw
from resstockpostproc.baseline_validation.io_managers import get_resstock_data
from resstockpostproc.baseline_validation.schema.workflow_schema import DataSourceConfig
from resstockpostproc.shared_utils.db_column_names import DataCol, DBSchema


def _make_source(name: str) -> DataSourceConfig:
    return DataSourceConfig(
        name=name,
        db_name="buildstock",
        table_name="baseline",
        db_schema=DBSchema.OEDI_NEW,
    )


def _patch_minimal_raw(monkeypatch, raw: pl.DataFrame) -> None:
    minimal_map = {
        DataCol.ELECTRICITY_TOTAL: "out.electricity.total.energy_consumption..kwh",
    }
    monkeypatch.setattr(
        type(get_resstock_data.workflow),
        "get_resstock_data_file",
        lambda _self, _name: Path("/tmp/fake_upgrade0.parquet"),  # noqa: S108 — mock path, never hits disk
    )
    monkeypatch.setattr(get_resstock_data.pl, "scan_parquet", lambda _path: raw.lazy())
    monkeypatch.setattr(get_resstock_data, "get_db_enduse_colnames_map", lambda _schema: minimal_map)
    monkeypatch.setattr(resstock_raw, "get_db_enduse_colnames_map", lambda _schema: minimal_map)


@pytest.fixture(autouse=True)
def _clear_annual_caches():
    get_resstock_data.get_annual.__wrapped__.cache_clear()
    get_resstock_data._get_annual_two_char_cached.cache_clear()


class TestResStockAnnualFastPath:
    def test_get_annual_uses_raw_parquet_for_state(self, monkeypatch):
        raw = pl.DataFrame(
            {
                "in.state": ["CA", "CA", "NY"],
                "in.vacancy_status": ["Occupied", "Vacant", "Occupied"],
                "weight": [2.0, 1.0, 3.0],
                "out.electricity.total.energy_consumption..kwh": [10.0, 40.0, 20.0],
            }
        )
        _patch_minimal_raw(monkeypatch, raw)
        monkeypatch.setattr(
            get_resstock_data,
            "get_buildstock_query",
            lambda *_args, **_kwargs: (_ for _ in ()).throw(AssertionError("Athena should not be used")),
        )

        out = get_resstock_data.get_annual(_make_source("raw_state"), by="state", occupied_only=True)

        ca = out.filter(pl.col("state") == "CA").row(0, named=True)
        ny = out.filter(pl.col("state") == "NY").row(0, named=True)
        us_total = out.filter(pl.col("state") == "US Total").row(0, named=True)

        assert ca["units_count"] == pytest.approx(2.0)
        assert ca["electricity_total_value"] == pytest.approx(20.0)
        assert ca["electricity_total_percent_users"] == pytest.approx(100.0)
        assert ca["electricity_total_quartiles"] == pytest.approx([10.0] * 9)

        assert ny["units_count"] == pytest.approx(3.0)
        assert ny["electricity_total_value"] == pytest.approx(60.0)
        assert ny["electricity_total_percent_users"] == pytest.approx(100.0)
        assert ny["electricity_total_quartiles"] == pytest.approx([20.0] * 9)

        assert us_total["units_count"] == pytest.approx(5.0)
        assert us_total["electricity_total_value"] == pytest.approx(80.0)
        assert us_total["electricity_total_percent_users"] == pytest.approx(100.0)

    def test_get_annual_two_char_uses_raw_parquet_and_adds_us_total(self, monkeypatch):
        raw = pl.DataFrame(
            {
                "in.state": ["CA", "NY", "CA"],
                "in.vintage": ["1990s", "1990s", "2000s"],
                "in.vacancy_status": ["Occupied", "Occupied", "Occupied"],
                "weight": [2.0, 1.0, 3.0],
                "out.electricity.total.energy_consumption..kwh": [10.0, 20.0, 0.0],
            }
        )
        _patch_minimal_raw(monkeypatch, raw)
        monkeypatch.setattr(
            get_resstock_data,
            "get_buildstock_query",
            lambda *_args, **_kwargs: (_ for _ in ()).throw(AssertionError("Athena should not be used")),
        )

        out = get_resstock_data._get_annual_two_char_cached(
            _make_source("raw_state_vintage"),
            by="state",
            filter_char="vintage",
            occupied_only=False,
        )

        us_1990s = out.filter((pl.col("state") == "US Total") & (pl.col("vintage") == "1990s")).row(0, named=True)
        us_2000s = out.filter((pl.col("state") == "US Total") & (pl.col("vintage") == "2000s")).row(0, named=True)

        assert us_1990s["units_count"] == pytest.approx(3.0)
        assert us_1990s["electricity_total_value"] == pytest.approx(40.0)
        assert us_1990s["electricity_total_percent_users"] == pytest.approx(100.0)

        assert us_2000s["units_count"] == pytest.approx(3.0)
        assert us_2000s["electricity_total_value"] == pytest.approx(0.0)
        assert us_2000s["electricity_total_percent_users"] == pytest.approx(0.0)
        assert us_2000s["electricity_total_nonzero_quartiles"] == pytest.approx([0.0] * 9)

    def test_get_annual_eiaid_falls_back_to_athena_path(self, monkeypatch):
        expected = pl.DataFrame({"eiaid": [12345], "units_count": [1.0]})
        sentinel_bsq = object()

        monkeypatch.setattr(
            get_resstock_data.pl,
            "scan_parquet",
            lambda _path: (_ for _ in ()).throw(AssertionError("raw parquet should not be scanned for eiaid")),
        )
        monkeypatch.setattr(get_resstock_data, "get_buildstock_query", lambda *_args, **_kwargs: sentinel_bsq)
        monkeypatch.setattr(
            get_resstock_data,
            "_get_annual_by_eiaid",
            lambda bsq, _data_source: expected if bsq is sentinel_bsq else None,
        )

        out = get_resstock_data.get_annual(_make_source("athena_eiaid"), by="eiaid", occupied_only=False)
        assert out.equals(expected)
