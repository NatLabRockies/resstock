"""Dash entry point for the ResStock dashboard."""

from __future__ import annotations

import logging
import os
from pathlib import Path

import dash_bootstrap_components as dbc  # type: ignore
from dash_extensions.enrich import DashProxy, MultiplexerTransform  # type: ignore

from resstockpostproc.upgrade_comparison.dashboard.callbacks import register_callbacks
from resstockpostproc.upgrade_comparison.dashboard.layout import build_layout
from resstockpostproc.upgrade_comparison.dashboard.run_context import RunContext

logger = logging.getLogger(__name__)


def get_app() -> DashProxy:
    """Instantiate and configure the Dash application."""
    workflow_yaml = Path(__file__).resolve().parent.parent / "workflow.yaml"
    plots_root_folder = os.environ.get("PLOTS_ROOT_FOLDER")

    context = RunContext.from_environment(workflow_yaml, plots_root_folder)
    print(f"Output dir: {context.workflow.output_dir}")

    app = DashProxy(
        __name__,
        external_stylesheets=[dbc.themes.BOOTSTRAP],
        transforms=[MultiplexerTransform()],
        external_scripts=["https://cdn.tailwindcss.com"],
        suppress_callback_exceptions=True,
    )
    app.layout = build_layout(context)
    register_callbacks(app, context)

    return app


def run_dashboard(port: int = 8051) -> None:
    """Launch the dashboard server."""
    try:
        print(f"Running dashboard on port {port}")
        app = get_app()
        app.run(debug=True, port=port, host="0.0.0.0")  # noqa: S104
    except Exception:
        logger.error("Failed to run dashboard", exc_info=True)


if __name__ == "__main__":
    run_dashboard()
