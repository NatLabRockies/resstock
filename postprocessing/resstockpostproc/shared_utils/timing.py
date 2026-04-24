"""Timing instrumentation for profiling the baseline validation pipeline.

Provides a lightweight ``@timed`` decorator that records wall-clock duration
for every call and accumulates statistics into a global ``TimingStats``
registry.  At the end of a run, call ``TimingStats.summary()`` to get a
human-readable table sorted by total time.

Optionally streams events in **Chrome Trace Event Format** to a JSON file
for visualization in `Perfetto UI <https://ui.perfetto.dev>`_.  Call
``TimingStats.start_trace(path)`` before the run and ``stop_trace()`` after.
Events are flushed on every call so the file is always viewable, even if the
pipeline is interrupted.

Usage::

    from resstockpostproc.shared_utils.timing import timed, TimingStats

    @timed
    def expensive_function(...):
        ...

    # At the end of the run:
    print(TimingStats.summary())
"""

import functools
import json
import logging
import os
import time
from dataclasses import dataclass
from pathlib import Path
from typing import IO, ClassVar

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

    _stats: ClassVar[dict[str, _FuncStats]] = {}
    _trace_file: IO | None = None
    _epoch: float = 0.0
    _wall_epoch: float = 0.0  # wall-clock epoch for aligning worker trace events
    _event_count: int = 0
    _flush_interval: int = 100  # flush trace file every N events
    # Worker-process mode: collect events in memory instead of writing to file
    _is_worker: bool = False
    _pending_events: ClassVar[list[dict]] = []

    @classmethod
    def start_trace(cls, path: Path) -> None:
        """Open a Chrome Trace Event Format file for streaming writes."""
        cls._trace_file = open(path, "w")  # noqa: SIM115 — long-lived; closed by stop_trace
        cls._trace_file.write("[\n")
        cls._epoch = 0.0
        cls._event_count = 0

    @classmethod
    def stop_trace(cls) -> None:
        """Close the trace file with a valid JSON array terminator."""
        if cls._trace_file:
            cls._trace_file.write("\n]\n")
            cls._trace_file.close()
            cls._trace_file = None

    @classmethod
    def enable_worker_mode(cls) -> None:
        """Call in worker process initializer to collect events in memory."""
        cls._is_worker = True
        cls._stats.clear()
        cls._pending_events.clear()

    @classmethod
    def harvest_worker_stats(cls) -> tuple[dict[str, tuple], list[dict]]:
        """Return accumulated (stats, trace_events) and reset. Called in worker before returning."""
        stats = {
            name: (s.call_count, s.total_time, s.min_time, s.max_time)
            for name, s in cls._stats.items()
        }
        events = cls._pending_events.copy()
        cls._stats.clear()
        cls._pending_events.clear()
        return stats, events

    @classmethod
    def merge_worker_stats(cls, worker_stats: dict[str, tuple], worker_events: list[dict]) -> None:
        """Merge a worker's stats into the main process registry and write its trace events."""
        for name, (count, total, mn, mx) in worker_stats.items():
            if name not in cls._stats:
                cls._stats[name] = _FuncStats()
            s = cls._stats[name]
            s.call_count += count
            s.total_time += total
            s.min_time = min(s.min_time, mn)
            s.max_time = max(s.max_time, mx)
        if cls._trace_file and worker_events:
            for event in worker_events:
                # Convert worker wall-clock timestamps to main-process relative timestamps
                event["ts"] = event["ts"] - cls._wall_epoch * 1_000_000
                prefix = "," if cls._event_count > 0 else ""
                cls._trace_file.write(f"{prefix}\n{json.dumps(event)}")
                cls._event_count += 1
            cls._trace_file.flush()

    @classmethod
    def record(cls, name: str, start: float, elapsed: float, trace_args: dict | None = None) -> None:
        if name not in cls._stats:
            cls._stats[name] = _FuncStats()
        s = cls._stats[name]
        s.call_count += 1
        s.total_time += elapsed
        s.min_time = min(s.min_time, elapsed)
        s.max_time = max(s.max_time, elapsed)

        if cls._is_worker:
            # Use wall-clock time for cross-process trace alignment
            wall_start = time.time() - elapsed
            event = {
                "name": name,
                "ph": "X",
                "ts": wall_start * 1_000_000,
                "dur": elapsed * 1_000_000,
                "pid": os.getpid(),
                "tid": 1,
            }
            if trace_args:
                event["args"] = trace_args
            cls._pending_events.append(event)
        elif cls._trace_file:
            if not cls._epoch:
                cls._epoch = start
                cls._wall_epoch = time.time() - elapsed
            prefix = "," if cls._event_count > 0 else ""
            event = {
                "name": name,
                "ph": "X",
                "ts": (start - cls._epoch) * 1_000_000,
                "dur": elapsed * 1_000_000,
                "pid": 1,
                "tid": 1,
            }
            if trace_args:
                event["args"] = trace_args
            cls._trace_file.write(f"{prefix}\n{json.dumps(event)}")
            cls._event_count += 1
            if cls._event_count % cls._flush_interval == 0:
                cls._trace_file.flush()

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
        """Clear all recorded statistics and close any open trace file."""
        cls.stop_trace()
        cls._stats.clear()
        cls._epoch = 0.0
        cls._wall_epoch = 0.0
        cls._event_count = 0
        cls._is_worker = False
        cls._pending_events.clear()


def _extract_args(args, kwargs) -> dict:
    """Extract structured argument info from function arguments for trace events.

    Uses Pydantic model_dump() for PlotSpec, _asdict() for DataKey (NamedTuple).
    Converts all values to strings for JSON safety.
    """
    for arg in list(args) + list(kwargs.values()):
        if hasattr(arg, "model_dump"):
            return {k: str(v) for k, v in arg.model_dump().items()}
        if hasattr(arg, "_asdict"):
            return {k: str(v) for k, v in arg._asdict().items()}
    return {}


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
        trace_args = _extract_args(args, kwargs)
        TimingStats.record(qualname, start, elapsed, trace_args=trace_args)
        if trace_args:
            ctx = "/".join(trace_args.values())
            logger.debug("%s(%s): %.3fs", qualname, ctx, elapsed)
        else:
            logger.debug("%s: %.3fs", qualname, elapsed)
        return result

    return wrapper
