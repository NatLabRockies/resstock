"""Theme management for Plotly plots.
Centralizes style configuration so all plotters share a consistent look & feel.
"""

import plotly.graph_objects as go

from resstockpostproc.standard_plots.schema.end_use_dicts import column2color, column2pattern
from resstockpostproc.standard_plots.schema.workflow_schema import WorkflowConfig

nrel_color_series = [  # from https://www.nrel.gov/comm-standards/web/typography
    [  # blue series
        "#0B5E90",
        "#0079C2",
        "#00A3E4",
        "#5DD2FF",
    ],
    [  # orange series
        "#A16911",
        "#EE9521",
        "#FFC423",
        "#FFD200",
    ],
    [  # green series
        "#3D6321",
        "#7DA544",
        "#9ECE42",
        "#C1EE86",
    ],
    [  # gray series
        "#4B545A",
        "#626D72",
        "#D1D5D8",
        "#DEE2E5",
    ],
    [  # black series
        "#000000#212121",
        "#00A3E4",
        "#3A4246",
    ],
]

fuel_colors = {
    "electricity": nrel_color_series[1][1],  # EE9521 orange
    "natural gas": nrel_color_series[0][2],  # 0079C2 blue
    "propane": nrel_color_series[2][0],  # A16911  # brown
    "fuel oil": nrel_color_series[3][0],  # 626D72 gray
}


def get_fuel_color(fuel: str) -> str:
    return fuel_colors.get(fuel.lower(), "#3A4246")


class ThemeManager:
    """Holds reusable Plotly layout & palette configuration."""

    def __init__(self, workflow: WorkflowConfig):
        # Base template - can be changed via config
        self.template: str = "plotly_white"
        # Color palette used across plots
        self.primary_color_sequence = nrel_color_series[0]
        self.end_use_to_color = column2color
        self.end_use_to_pattern = column2pattern
        self.upgrade_palette = dict(zip(workflow.upgrade_names, nrel_color_series[0]))

        self.fig_width: int = 1000
        self.facet_width: int = 200
        self.fig_height: int = 600
        self.facet_title_width = 15

    def apply_layout(self, fig: go.Figure) -> go.Figure:
        """Apply the theme's common layout to *fig* and return it for chaining."""
        fig.update_layout(
            template=self.template,
            font={"family": "Arial", "size": 12},
            margin={"l": 50, "r": 150, "t": 80, "b": 50},
            plot_bgcolor="white",
            width=self.fig_width,
            height=self.fig_height,
            hoverlabel_namelength=-1,  # show full hover labels
        )
        return fig
