"""Timing instrumentation for profiling the baseline validation pipeline.

Provides a lightweight ``@timed`` decorator that records wall-clock duration
for every call and accumulates statistics into a global ``TimingStats``
registry.  At the end of a run, call ``TimingStats.summary()`` to get a
human-readable table sorted by total time.

Usage::

    from resstockpostproc.shared_utils.timing import timed, TimingStats

    @timed
    def expensive_function(...):
        ...

    # At the end of the run:
    print(TimingStats.summary())
"""

import functools
import logging
import time
from dataclasses import dataclass, field

logger = logging.getLogger(__name__)


@dataclass
class _FuncStats:
    """Accumulated timing statistics for a single function."""

    call_count: int = 0
    total_time: float = 0.0
    min_time: float = float("inf")
    max_time: float = float("-inf")


class TimingStats:
    """Global registry of per-function timing statistics.

    All state lives on the *class* (not on instances) so every ``@timed``
    decorator writes to the same shared registry without needing to pass an
    object around.
    """

    _stats: dict[str, _FuncStats] = {}

    @classmethod
    def record(cls, name: str, elapsed: float) -> None:
        if name not in cls._stats:
            cls._stats[name] = _FuncStats()
        s = cls._stats[name]
        s.call_count += 1
        s.total_time += elapsed
        s.min_time = min(s.min_time, elapsed)
        s.max_time = max(s.max_time, elapsed)

    @classmethod
    def summary(cls) -> str:
        """Return a formatted summary table sorted by total time descending."""
        if not cls._stats:
            return "(no timing data recorded)"

        header = f"{'Function':<55} {'Calls':>7} {'Total':>10} {'Avg':>10} {'Min':>10} {'Max':>10}"
        sep = "-" * len(header)
        lines = [header, sep]

        for name, s in sorted(cls._stats.items(), key=lambda x: -x[1].total_time):
            avg = s.total_time / s.call_count if s.call_count else 0
            lines.append(
                f"{name:<55} {s.call_count:>7} {s.total_time:>9.2f}s "
                f"{avg:>9.3f}s {s.min_time:>9.3f}s {s.max_time:>9.3f}s"
            )
        return "\n".join(lines)

    @classmethod
    def reset(cls) -> None:
        """Clear all recorded statistics."""
        cls._stats.clear()


def timed(func):
    """Decorator that logs per-call timing and accumulates global stats.

    Place *outside* any caching decorators so that cache hits are measured
    as near-zero and cache misses show the true computation cost::

        @timed                          # measures wall-clock (incl. cache hits)
        @cached(cache_file="foo")       # disk cache
        def load_data(...):
            ...
    """
    # Use the short module + qualname for readable output
    qualname = f"{func.__module__.rsplit('.', 1)[-1]}.{func.__qualname__}"

    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = func(*args, **kwargs)
        elapsed = time.perf_counter() - start
        TimingStats.record(qualname, elapsed)
        logger.debug("%s: %.3fs", qualname, elapsed)
        return result

    return wrapper
