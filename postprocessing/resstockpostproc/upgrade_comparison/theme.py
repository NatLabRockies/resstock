"""Functional helpers for plot styling."""

from __future__ import annotations

import itertools as it
from collections.abc import Sequence

import plotly.graph_objects as go

from resstockpostproc.shared_utils.colors import QUALITATIVE_SERIES
from resstockpostproc.shared_utils.colors import FUEL_COLORS
from resstockpostproc.upgrade_comparison.schema.end_use_dicts import column2color, column2pattern

DEFAULT_TEMPLATE = "plotly_white"
DEFAULT_FONT_FAMILY = "Arial"
DEFAULT_FONT_SIZE = 12
DEFAULT_FIG_WIDTH = 816  # 8.5 inches at 96 dpi
DEFAULT_FIG_HEIGHT = 500
DEFAULT_FACET_WIDTH = 200
DEFAULT_FACET_TITLE_WIDTH = 15

END_USE_TO_COLOR = column2color
END_USE_TO_PATTERN = column2pattern


def build_upgrade_palette(upgrade_names: Sequence[str]) -> dict[str, str]:
    """Return a mapping from upgrade name to color."""
    unique_names = list(dict.fromkeys(upgrade_names))
    if not unique_names:
        return {}
    if len(unique_names) > len(QUALITATIVE_SERIES):
        palette = {unique_names[0]: QUALITATIVE_SERIES[0]}
        for name in unique_names[1:]:
            palette[name] = QUALITATIVE_SERIES[1]
        return palette
    return dict(zip(unique_names, QUALITATIVE_SERIES))


def apply_layout(fig: go.Figure, *, width: int | None = None, height: int | None = None) -> go.Figure:
    """Apply the common layout updates to *fig* and return the figure."""
    fig.update_layout(
        template=DEFAULT_TEMPLATE,
        font={"family": DEFAULT_FONT_FAMILY, "size": DEFAULT_FONT_SIZE},
        margin={"l": 80, "r": 80, "t": 80, "b": 50},
        plot_bgcolor="white",
        width=width or DEFAULT_FIG_WIDTH,
        height=height or DEFAULT_FIG_HEIGHT,
        hoverlabel_namelength=-1,
    )
    return fig


def get_fuel_color(fuel: str) -> str:
    return FUEL_COLORS.get(fuel.lower(), "#3A4246")


def cycling_colors() -> it.cycle:
    """Return a reusable color cycle."""
    return it.cycle(QUALITATIVE_SERIES)
