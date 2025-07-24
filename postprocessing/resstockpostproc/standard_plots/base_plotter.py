"""Common abstract base class for all plotters.

Provides shared helpers (theme access, column guards, etc.) so concrete plotters do not have to duplicate boilerplate.
"""

from abc import ABC

import polars as pl
from plotly.graph_objects import Figure

from resstockpostproc.standard_plots.schema.plot_spec import PlotSpec
from resstockpostproc.standard_plots.theme import ThemeManager


class BasePlotter(ABC):
    """Abstract base plotter - every concrete plotter inherits this."""

    def __init__(self, theme_cfg: dict | None = None):
        # Centralized style/theme manager
        self.theme = ThemeManager(theme_cfg)

    # ------------------------------------------------------------------
    # Shared helpers
    # ------------------------------------------------------------------
    @staticmethod
    def _ensure_columns_exist(df: pl.DataFrame, cols: list[str]) -> pl.DataFrame:
        """Ensure *cols* are present in *df* (add with zeros if missing)."""
        for col in cols:
            if col not in df.columns:
                df = df.with_columns(pl.lit(0).alias(col))
        return df

    # ------------------------------------------------------------------
    # Mandatory interface
    # ------------------------------------------------------------------
    def create_plot(self, data: pl.DataFrame, plot_spec: PlotSpec) -> Figure:
        """Placeholder fallback; subclasses typically override for convenience."""
        raise NotImplementedError("Subclasses should implement `create_plot` or use specific helpers.")
