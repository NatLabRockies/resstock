"""Plot theme and styling for baseline validation."""

import plotly.graph_objects as go
import plotly.io as pio

BUILDSTOCK_COLOR = "#0071BD"
REFERENCE_COLOR = "#EF1C21"
HIGHLIGHT_COLOR = "#FFB239"
NEUTRAL_COLOR = "#4A4D4A"

CATEGORICAL_COLORS = [
    "#0071BD", "#EF1C21", "#FFB239", "#51e889", "#29AAE7",
    "#F7DF10", "#FF79AD", "#632C94", "#4A4D4A", "#D3D3D3",
]

DEFAULT_LAYOUT = dict(
    font=dict(family="Arial, sans-serif", size=14, color="#333"),
    plot_bgcolor="white",
    paper_bgcolor="white",
    hovermode="closest",
    hoverlabel=dict(bgcolor="white", font_size=14, font_family="Arial"),
    margin=dict(l=80, r=40, t=80, b=80),
    autosize=True,
)

DEFAULT_XAXIS = dict(
    showgrid=True,
    gridcolor="#E1E1E1",
    gridwidth=1,
    zeroline=True,
    zerolinecolor="#E1E1E1",
    zerolinewidth=1,
    showline=True,
    linecolor="#333",
    linewidth=1,
    mirror=False,
)

DEFAULT_YAXIS = dict(
    showgrid=True,
    gridcolor="#E1E1E1",
    gridwidth=1,
    zeroline=True,
    zerolinecolor="#E1E1E1",
    zerolinewidth=1,
    showline=True,
    linecolor="#333",
    linewidth=1,
    mirror=False,
)


def apply_theme(fig: go.Figure, title: str | None = None, **kwargs) -> go.Figure:
    """Apply consistent theme to a Plotly figure."""
    layout_updates = DEFAULT_LAYOUT.copy()
    layout_updates.update(kwargs)

    if title:
        layout_updates["title"] = dict(text=title, font=dict(size=16, color="#333"), x=0.5, xanchor="center")

    layout_updates["xaxis"] = {**DEFAULT_XAXIS, **layout_updates.get("xaxis", {})}
    layout_updates["yaxis"] = {**DEFAULT_YAXIS, **layout_updates.get("yaxis", {})}

    fig.update_layout(**layout_updates)
    return fig


custom_template = go.layout.Template()
custom_template.layout = DEFAULT_LAYOUT
custom_template.layout.xaxis = DEFAULT_XAXIS
custom_template.layout.yaxis = DEFAULT_YAXIS
custom_template.layout.colorway = CATEGORICAL_COLORS

pio.templates["buildstock_validation"] = custom_template
pio.templates.default = "buildstock_validation"
