"""Common abstract base class for all plotters.

Provides shared helpers (theme access, column guards, etc.) so concrete
plotters don’t have to duplicate boilerplate.
"""
from __future__ import annotations

from abc import ABC
from typing import Dict, List, Optional

import polars as pl

from .theme import ThemeManager
from .schema.plot_spec import PlotSpec


class BasePlotter(ABC):
    """Abstract base plotter – every concrete plotter inherits this."""

    def __init__(self, theme_cfg: Optional[Dict] = None):
        # Centralised style/theme manager
        self.theme = ThemeManager(theme_cfg)

    # ------------------------------------------------------------------
    # Shared helpers
    # ------------------------------------------------------------------
    @staticmethod
    def _ensure_columns_exist(df: pl.DataFrame, cols: List[str]) -> pl.DataFrame:
        """Ensure *cols* are present in *df* (add with zeros if missing)."""
        for col in cols:
            if col not in df.columns:
                df = df.with_columns(pl.lit(0).alias(col))
        return df

    # ------------------------------------------------------------------
    # Mandatory interface
    # ------------------------------------------------------------------
    def create_plot(self, data: pl.DataFrame, plot_spec: PlotSpec):  # pragma: no cover – optional override
        """Placeholder fallback; subclasses typically override for convenience."""
        raise NotImplementedError("Subclasses should implement `create_plot` or use specific helpers.")
