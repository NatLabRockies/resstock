"""Disk-based caching decorator using shelve module."""

import shelve
import functools
import hashlib
import pickle
from pathlib import Path
from typing import Any
from collections.abc import Callable


def cached(cache_file: str) -> Callable:
    """
    Decorator that caches function results to disk using shelve.
    
    Args:
        cache_file: Name of the cache file (without extension)
        
    Usage:
        @cached("my_cache")
        def expensive_function(arg1, arg2):
            # Heavy computation
            return result
    """
    def decorator(func: Callable) -> Callable:
        cache_dir = Path(__file__).parent.parent / ".cache"
        cache_dir.mkdir(parents=True, exist_ok=True)
        cache_path = str(cache_dir / cache_file)
        
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
            
            # Try to get cached result
            # Note: shelve uses pickle internally, which is needed for arbitrary object caching
            with shelve.open(cache_path) as cache:  # noqa: S301
                if cache_key in cache:
                    return cache[cache_key]
                
                # Compute result if not cached
                result = func(*args, **kwargs)
                
                # Store result in cache
                cache[cache_key] = result
                
            return result
        
        return wrapper
    return decorator
