"""Top-level package exports.

Keep this module light so subpackages can be imported in test environments
without requiring optional heavy dependencies used by process_metadata.
"""

from __future__ import annotations

from typing import Any


def process_simulation_outputs(*args: Any, **kwargs: Any):
    """Lazily import process_metadata entrypoint.

    This preserves the public API while avoiding eager imports of optional
    geospatial dependencies during package import.
    """
    from .process_metadata import process_simulation_outputs as _impl

    return _impl(*args, **kwargs)


__all__ = ["process_simulation_outputs"]
