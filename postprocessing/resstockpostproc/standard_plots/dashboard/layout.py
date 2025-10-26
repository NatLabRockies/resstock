from __future__ import annotations

from typing import Any
from collections.abc import Sequence

import dash_bootstrap_components as dbc  # type: ignore
from dash import dcc, html

from .run_context import RunContext


def build_layout(ctx: RunContext) -> dbc.Container:
    """Return the root Dash layout for the dashboard."""
    quantity_group_options = list(ctx.quantity_groups.keys())
    default_quantity_group = _get_default_quantity_group(quantity_group_options)

    return dbc.Container(
        [
            dcc.Location(id="url", refresh=False),
            _build_alert_modal(),
            build_header_section(),
            build_control_section(ctx, quantity_group_options, default_quantity_group),
            build_main_content_section(),
            html.Div(
                id="cache-indicator",
                className="text-muted",
                style={"fontSize": "0.75rem", "position": "fixed", "left": "10px", "bottom": "5px"},
            ),
            dcc.Store(id="df-parquet", storage_type="memory"),
            dcc.Store(id="df-csv", storage_type="memory"),
            # Persist group-by selection in local storage to avoid hydration races
            # dcc.Store(id="group-by-store", storage_type="local"),
            html.Div(id="download-dummy", style={"display": "none"}),
        ],
        fluid=True,
    )


def build_header_section() -> dbc.Row:
    """Render the dashboard title, run selection, and dynamic toggle."""
    return dbc.Row(
        [
            dbc.Col(html.H2("ResStock Dashboard"), width="auto"),
            dbc.Col(build_run_folder_control(), md=3),
            dbc.Col(build_run_info_section(), width="auto"),
            dbc.Col(
                html.Div(
                    [
                        dbc.Switch(
                            id="dynamic-toggle",
                            label="Always Dynamic",
                            value=False,
                            className="me-2",
                            persistence=True,
                            persistence_type="local",
                        ),
                        html.Small(
                            "Enable Dynamic mode to always generate figures on the fly",
                            className="d-block text-muted",
                        ),
                    ],
                    className="text-end",
                ),
                width="auto",
                className="ms-auto",
            ),
        ],
        align="center",
        className="my-3",
    )


def build_run_info_section() -> html.Div:
    """Render the run info placeholder content."""
    checklist = dcc.Checklist(
        id="selected-upgrades",
        options=[],
        value=[],
        inline=True,
        inputStyle={"marginRight": "2px"},
        labelStyle={
            "display": "inline-block",
            "width": "12ch",
            "fontFamily": "ui-monospace",
            "whiteSpace": "pre",
            "marginRight": "8px",
            "verticalAlign": "top",
        },
        style={"display": "inline-block"},
        persistence=True,
        persistence_type="local",
        persisted_props=["value"],
    )

    return html.Div(
        [
            html.Small("Run Info", className="d-block fw-bold mb-1"),
            html.Div(
                id="run-info-message",
                className="text-center text-muted",
                style={"fontSize": "0.75rem"},
            ),
            html.Div(
                [
                    html.Div(
                        [html.Span("S3: ", className="fw-bold"), html.Span("—", id="run-info-s3")],
                        style={"fontSize": "0.75rem", "wordBreak": "break-all"},
                    ),
                    html.Div(
                        [
                            html.Span("Upgrades (applied %): ", className="fw-bold me-1"),
                            checklist,
                        ],
                        style={
                            "fontSize": "0.75rem",
                            "maxWidth": "480px",
                            "whiteSpace": "normal",
                            "wordWrap": "break-word",
                            "lineHeight": "1.1rem",
                        },
                        id="run-info-upgrades",
                    ),
                    html.Div(
                        [
                            html.Span("Number of data points: ", className="fw-bold"),
                            html.Span("—", id="run-info-num-points"),
                        ],
                        style={"fontSize": "0.75rem"},
                    ),
                ],
                id="run-info-details",
            ),
        ],
        id="run-info",
    )


def build_control_section(
    ctx: RunContext,
    quantity_group_options: list[str],
    default_quantity_group: str | None,
) -> dbc.Card:
    """Render the control card."""
    workflow = ctx.workflow

    return dbc.Card(
        dbc.CardBody(
            [
                dbc.Row(
                    [
                        dbc.Col(build_building_inclusion_control(), md=2),
                        dbc.Col(build_vacancy_inclusion_control(workflow), md=2),
                        dbc.Col(build_quantity_type_control(workflow), md=2),
                        dbc.Col(build_aggregation_type_control(workflow), md=2),
                        dbc.Col(build_visualization_type_control(workflow), md=2),
                    ]
                ),
                html.Hr(className="my-2"),
                dbc.Row(
                    [
                        dbc.Col(build_group_by_control(), md=4),
                        dbc.Col(build_quantity_group_control(quantity_group_options, default_quantity_group), md=4),
                        dbc.Col(build_quantity_control(), md=4),
                    ]
                ),
            ]
        ),
        className="my-3",
    )


def build_main_content_section() -> dbc.Row:
    """Render the two-column layout with sidebar controls and figure display."""
    return dbc.Row(
        [
            dbc.Col(build_sidebar_card(), md=3),
            dbc.Col(build_figure_loading_wrapper(), md=9),
        ]
    )


def build_sidebar_card() -> dbc.Card:
    """Render the sidebar containing figure, legend, and facet controls."""
    return dbc.Card(
        dbc.CardBody(
            [
                build_figure_adjustment_section(),
                build_legend_adjustment_section(),
                build_facet_adjustment_section(),
                build_download_section(),
                html.Br(),
                dbc.Button("Generate Plot", id="generate-btn", color="primary", className="mt-2 w-100"),
            ]
        ),
        className="my-3",
    )


def build_figure_loading_wrapper() -> dcc.Loading:
    """Render the right-hand figure container."""
    return dcc.Loading(
        dcc.Graph(
            id="plot-graph",
            config={
                "autosizable": True,
                "responsive": True,
                "displaylogo": False,
                "modeBarButtons": [
                    ["toImage"],
                    ["zoom2d", "zoomIn2d", "zoomOut2d", "autoScale2d", "resetScale2d"],
                ],
                "toImageButtonOptions": {"format": "svg"},
            },
        ),
        type="cube",
    )


def make_dropdown(
    dropdown_id: str,
    *,
    options: Sequence[Any] | dict[str, Any],
    value: Any,
    clearable: bool = False,
    style: dict[str, Any] | None = None,
    **extra: Any,
) -> dcc.Dropdown:
    """Create a dropdown with common persistence defaults applied."""
    kwargs: dict[str, Any] = {
        "id": dropdown_id,
        "options": options,
        "value": value,
        "clearable": clearable,
        "persistence": True,
        "persistence_type": "local",
        "persisted_props": ["value"],
        **extra,
    }
    if style:
        kwargs["style"] = style
    return dcc.Dropdown(**kwargs)


def make_slider(
    slider_id: str,
    *,
    min_val: int | float,
    max_val: int | float,
    step: int | float,
    value: int | float,
    marks: dict[int | float, str] | None = None,
    **extra: Any,
) -> dcc.Slider:
    """Create a slider with persistence defaults."""
    return dcc.Slider(
        id=slider_id,
        min=min_val,
        max=max_val,
        step=step,
        value=value,
        marks=marks,
        persistence=True,
        persistence_type="local",
        persisted_props=["value"],
        **extra,
    )


def make_radio_items(
    component_id: str,
    *,
    options: Sequence[Any],
    value: Any,
    inline: bool = True,
    **extra: Any,
) -> dcc.RadioItems:
    """Create a radio button group with consistent persistence defaults."""
    return dcc.RadioItems(
        id=component_id,
        options=options,
        value=value,
        inline=inline,
        persistence=True,
        persistence_type="local",
        persisted_props=["value"],
        **extra,
    )


def make_checklist(
    component_id: str,
    *,
    options: Sequence[Any],
    value: Any,
    switch: bool = False,
    **extra: Any,
) -> dbc.Checklist:
    """Create a checklist with persistence defaults."""
    return dbc.Checklist(
        id=component_id,
        options=options,
        value=value,
        switch=switch,
        persistence=True,
        persistence_type="local",
        persisted_props=["value"],
        **extra,
    )


def make_labeled_control(
    label: str,
    control: Any,
    *,
    container_class: str | None = None,
    container_style: dict[str, Any] | None = None,
    label_class: str = "d-block fw-bold mb-1",
) -> html.Div:
    """Wrap a control with a consistent label layout."""
    kwargs: dict[str, Any] = {}
    if container_class:
        kwargs["className"] = container_class
    if container_style:
        kwargs["style"] = container_style
    return html.Div(
        [
            html.Small(label, className=label_class),
            control,
        ],
        **kwargs,
    )


def build_run_folder_control() -> html.Div:
    return make_labeled_control(
        "Run folder",
        make_dropdown("run-folder", options=[], value="", style={"minWidth": "250px"}),
    )


def build_building_inclusion_control() -> html.Div:
    return make_labeled_control(
        "Building Inclusion",
        make_dropdown(
            "building-inclusion",
            options=[
                {"label": "All", "value": "__all__"},
                {"label": "Applied in respective upgrades", "value": "applied_all"},
            ],
            value="applied_all",
        ),
    )


def build_vacancy_inclusion_control(workflow) -> html.Div:
    options = [vi.value for vi in workflow.vacancy_inclusion]
    default_value = options[0] if options else None
    return make_labeled_control(
        "Vacancy inclusion",
        make_radio_items("vacancy-inclusion", options=options, value=default_value),
    )


def build_quantity_type_control(workflow) -> html.Div:
    options = [ct.value for ct in workflow.quantity_types]
    return make_labeled_control(
        "Quantity type",
        make_dropdown(
            "quantity-type",
            options=options,
            value="savings" if "savings" in options else (options[0] if options else None),
            style={"minWidth": "180px"},
        ),
    )


def build_aggregation_type_control(workflow) -> html.Div:
    options = [vt.value for vt in workflow.aggregation_types]
    default_value = "average" if "average" in options else (options[0] if options else None)
    return make_labeled_control(
        "Aggregation Type",
        make_radio_items("aggregation-type", options=options, value=default_value),
    )


def build_visualization_type_control(workflow) -> html.Div:
    options = [vt.value for vt in workflow.visualization_types]
    default_value = "box" if "box" in options else (options[0] if options else None)
    return make_labeled_control(
        "Visualization type",
        make_radio_items("viz-type", options=options, value=default_value),
    )


def build_group_by_control() -> html.Div:
    return make_labeled_control(
        "Group by",
        make_dropdown(
            "group-by",
            options=[{"label": "None", "value": "__none__"}],
            value="__none__",
        ),
    )


def build_quantity_group_control(options: list[str], default_value: str | None) -> html.Div:
    dropdown_options: Sequence[Any] = options if options else []
    return make_labeled_control(
        "Quantity group",
        make_dropdown("quantity-group", options=dropdown_options, value=default_value),
    )


def build_quantity_control() -> html.Div:
    return make_labeled_control(
        "Quantity",
        make_dropdown("quantity", options=[], value="out.bills.all_fuels.usd"),
    )


def build_legend_position_control() -> html.Div:
    return make_labeled_control(
        "Legend position",
        make_dropdown(
            "legend-position",
            options={
                "right": "Right (outside)",
                "bottom": "Bottom (outside)",
                "tr": "Top-right (inside)",
                "br": "Bottom-right (inside)",
                "tl": "Top-left (inside)",
                "bl": "Bottom-left (inside)",
            },
            value="right",
            className="mb-2",
        ),
    )


def build_figure_adjustment_section() -> html.Div:
    """Controls for figure sizing and editability."""
    return html.Div(
        [
            html.Small("Figure adjustment", className="d-block fw-bold mb-1"),
            make_checklist(
                "fig-editable",
                options=[{"label": "Edit text", "value": "editable"}],
                value=[],
                switch=True,
                className="mb-2",
            ),
            make_labeled_control(
                "Width (px)",
                make_slider(
                    "fig-width",
                    min_val=400,
                    max_val=2500,
                    step=100,
                    value=1000,
                    marks={i: str(i) for i in range(400, 2501, 400)},
                ),
            ),
            make_labeled_control(
                "Height (px)",
                make_slider(
                    "fig-height",
                    min_val=300,
                    max_val=1800,
                    step=50,
                    value=700,
                    marks={i: str(i) for i in range(300, 1801, 300)},
                ),
            ),
        ],
        id="figure-adjustment-box",
        className="border rounded p-2 mb-2",
    )


def build_legend_adjustment_section() -> html.Div:
    """Controls for legend visibility and placement."""
    return html.Div(
        [
            html.Small("Legend adjustment", className="d-block fw-bold mb-1"),
            make_checklist(
                "legend-show",
                options=[{"label": "Show legend", "value": "show"}],
                value=["show"],
                switch=True,
                className="mb-2",
            ),
            build_legend_position_control(),
        ],
        id="legend-adjustment-box",
        className="border rounded p-2 mb-2",
    )


def build_facet_adjustment_section() -> html.Div:
    """Controls for facet orientation and label wrapping."""
    return html.Div(
        [
            html.Small("Facet adjustment", className="d-block fw-bold mb-1"),
            html.Div(
                make_checklist(
                    "facet-vertical",
                    options=[{"label": "Orientation", "value": "vertical"}],
                    value=[],
                    switch=True,
                ),
                id="facet-title-orientation-div",
                className="mb-2",
                style={"display": "none"},
            ),
            html.Div(
                make_labeled_control(
                    "Text wrap width",
                    make_slider(
                        "facet-wrap-width",
                        min_val=5,
                        max_val=80,
                        step=5,
                        value=20,
                        marks={i: str(i) for i in range(5, 81, 5)},
                        tooltip={"placement": "bottom", "always_visible": False},
                        className="mt-2",
                    ),
                ),
                id="facet-wrap-width-div",
                className="mb-2",
                style={"display": "none"},
            ),
        ],
        id="facet-adjustment-box",
        className="border rounded p-2 mb-2",
        style={"display": "none"},
    )


def build_download_section() -> html.Div:
    """Download buttons and associated hidden targets."""
    return html.Div(
        [
            dbc.Row(
                [
                    dbc.Col(
                        dbc.Button("Download CSV", id="btn-download-csv", color="secondary", className="w-100"),
                        width=4,
                    ),
                    dbc.Col(
                        dbc.Button("Download Parquet", id="btn-download-parquet", color="secondary", className="w-100"),
                        width=4,
                    ),
                    dbc.Col(
                        dbc.Button("Download PDF", id="btn-download-pdf", color="secondary", className="w-100"),
                        width=4,
                    ),
                ],
                className="mt-2",
            ),
            dcc.Download(id="download-csv"),
            dcc.Download(id="download-parquet"),
            dcc.Download(id="download-pdf"),
        ]
    )


def _build_alert_modal() -> dbc.Modal:
    """Create the alert modal used for invalid plot specs."""
    return dbc.Modal(
        [
            dbc.ModalHeader(dbc.ModalTitle("Alert")),
            dbc.ModalBody(id="invalid-spec-msg"),
        ],
        id="invalid-spec-modal",
        is_open=False,
    )


def _get_default_quantity_group(quantity_group_options: list[str]) -> str | None:
    """Determine the default quantity group selection."""
    if not quantity_group_options:
        return None
    if "Bills" in quantity_group_options:
        return "Bills"
    return quantity_group_options[0]
