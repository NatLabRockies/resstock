from __future__ import annotations

from ..run_context import RunContext
from .plotting import register_plotting_callbacks
from .run_info import register_run_info_callbacks
from .ui_controls import register_ui_control_callbacks


def register_callbacks(app, ctx: RunContext) -> None:
    """Register all dashboard callbacks."""
    register_run_info_callbacks(app, ctx)
    register_ui_control_callbacks(app, ctx)
    register_plotting_callbacks(app, ctx)
