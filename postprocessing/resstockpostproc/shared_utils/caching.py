"""Disk-based caching decorator using per-key shelve files.

Each unique set of arguments gets its own shelve file under a cache
subdirectory. This avoids dbm hash table overflow when caching large
datasets while retaining shelve's serialization benefits.
"""

import shelve
import functools
import hashlib
import pickle
from pathlib import Path
from typing import Any
from collections.abc import Callable

# When True, the @cached decorator opens shelve in read-only mode.
# Worker processes set this to True at init to avoid concurrent shelve corruption.
CACHE_READ_ONLY: bool = False


def cached(cache_file: str) -> Callable:
    """
    Decorator that caches function results to disk using per-key shelve files.

    Args:
        cache_file: Name of the cache subdirectory

    Usage:
        @cached("my_cache")
        def expensive_function(arg1, arg2):
            # Heavy computation
            return result
    """
    def decorator(func: Callable) -> Callable:
        cache_dir = Path(__file__).parent.parent / ".cache" / cache_file
        cache_dir.mkdir(parents=True, exist_ok=True)

        @functools.wraps(func)
        def wrapper(*args, **kwargs) -> Any:
            # Create a unique key based on function name and arguments
            key_data = {
                "function": func.__name__,
                "args": args,
                "kwargs": kwargs
            }
            # Serialize and hash the key data
            key_bytes = pickle.dumps(key_data)
            cache_key = hashlib.sha256(key_bytes).hexdigest()
            cache_path = str(cache_dir / cache_key)

            # Try to get cached result
            flag = "r" if CACHE_READ_ONLY else "c"
            try:
                with shelve.open(cache_path, flag=flag) as cache:  # noqa: S301
                    if "result" in cache:
                        return cache["result"]
            except Exception:
                # Shelve file may not exist yet in read-only mode
                pass

            if CACHE_READ_ONLY:
                # Cache miss in read-only mode — compute without storing
                return func(*args, **kwargs)

            # Compute result and store in cache
            result = func(*args, **kwargs)
            with shelve.open(cache_path) as cache:  # noqa: S301
                cache["result"] = result
            return result

        return wrapper
    return decorator
