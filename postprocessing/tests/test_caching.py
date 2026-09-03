from pathlib import Path
from types import SimpleNamespace

from resstockpostproc.shared_utils import caching
from resstockpostproc.baseline_validation.schema import workflow_schema
from resstockpostproc.baseline_validation.schema.workflow_schema import DataSourceConfig


def test_cache_root_lives_under_postprocessing():
    expected_root = Path(__file__).resolve().parents[1] / ".cache"
    assert caching.CACHE_ROOT == expected_root


def test_cached_decorator_creates_cache_under_postprocessing():
    cache_name = "unit_test_cache_location"

    @caching.cached(cache_name)
    def cached_value(x: int) -> int:
        return x + 1

    assert cached_value(1) == 2
    assert (caching.CACHE_ROOT / cache_name).is_dir()


def test_workflow_state_hash_changes_with_data_sources(monkeypatch):
    first_source = DataSourceConfig(
        name="resstock_2025",
        db_name="buildstock_sdr",
        table_name="resstock_amy2018_r1_2025",
        db_schema="resstock_oedi_new",
    )
    second_source = first_source.model_copy(update={"table_name": "resstock_amy2018_r2_2025"})

    monkeypatch.setattr(workflow_schema, "workflow", SimpleNamespace(data_sources=[first_source]))
    first_hash = caching._get_workflow_state_hash()

    monkeypatch.setattr(workflow_schema, "workflow", SimpleNamespace(data_sources=[second_source]))
    second_hash = caching._get_workflow_state_hash()

    assert first_hash is not None
    assert second_hash is not None
    assert first_hash != second_hash
