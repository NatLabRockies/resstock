"""Compatibility wrapper for the relocated dashboard module."""

from __future__ import annotations

from resstockpostproc.standard_plots.dashboard.dynamic_dashboard import get_app, run_dashboard

__all__ = ["get_app", "run_dashboard"]


if __name__ == "__main__":
    run_dashboard()
