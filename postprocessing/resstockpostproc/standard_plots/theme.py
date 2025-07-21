"""Theme management for Plotly plots.
Centralizes style configuration so all plotters share a consistent look & feel.
"""

import plotly.graph_objects as go

from resstockpostproc.standard_plots.schema.end_use_dicts import EnduseToColor, EnduseToPattern


class ThemeManager:
    """Holds reusable Plotly layout & palette configuration."""

    def __init__(self, config: dict | None = None):
        cfg: dict = config or {}
        # Base template - can be changed via config
        self.template: str = cfg.get("template", "plotly_white")
        # Color palette used across plots
        self.color_palette: dict[str, str] = cfg.get("color_palette", {})
        self.end_use_to_color = EnduseToColor
        self.end_use_to_pattern = EnduseToPattern
        # Default color palette if not specified in config
        if not self.color_palette:
            self.color_palette = {
                "Baseline": "#1f77b4",  # Dark blue
                "DF Plug": "#5aa1cf",  # Light blue
            }
        # Default figure size
        self.fig_width: int = cfg.get("fig_width", 1000)
        self.facet_width: int = cfg.get("facet_width", 200)
        self.fig_height: int = cfg.get("fig_height", 600)
        self.facet_title_width = cfg.get("facet_title_width", 15)

    # ---------------------------------------------------------------------
    # Helper methods
    # ---------------------------------------------------------------------
    def apply_layout(self, fig: go.Figure) -> go.Figure:
        """Apply the theme's common layout to *fig* and return it for chaining."""
        fig.update_layout(
            template=self.template,
            font={"family": "Arial", "size": 12},
            margin={"l": 50, "r": 150, "t": 80, "b": 50},
            plot_bgcolor="white",
            width=self.fig_width,
            height=self.fig_height,
        )
        return fig
