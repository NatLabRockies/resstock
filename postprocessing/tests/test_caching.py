from pathlib import Path

from resstockpostproc.shared_utils import caching


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
