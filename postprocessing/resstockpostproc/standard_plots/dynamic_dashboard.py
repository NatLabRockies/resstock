"""Dynamic Dash dashboard for ResStock plots.

This dashboard exposes a fixed set of controls ("knobs") at the top so the
user can choose what they would like to visualize. The figure is generated on
-the-fly using the new PlotSpec + PlotOrchestrator data pipeline.

This file does **NOT** rely on any pre-generated HTML files - it simply loads
the annual results CSV/parquet files once (via `PlotOrchestrator`) and then
creates the requested plot in real-time.
"""

import base64
import io
import json
import logging
import os
import textwrap
import traceback
from pathlib import Path
import time
from typing import Any

import dash
import dash_bootstrap_components as dbc  # type: ignore
import plotly.graph_objects as go  # type: ignore
import plotly.io as pio  # type: ignore
import polars as pl  # type: ignore
from dash import dcc, html
from dash.dependencies import Input, Output, State
from dash.exceptions import PreventUpdate
from dash_extensions.enrich import DashProxy, MultiplexerTransform  # type: ignore
from plotly.graph_objects import Figure

# Local imports - all heavy lifting is done by these modules
from resstockpostproc.standard_plots.orchestrator import PlotOrchestrator
from resstockpostproc.standard_plots.schema.plot_spec import (
    QuantityType,
    PlotSpec,
    BuildingInclusion,
    VacancyInclusion,
    AggregationType,
    VizType,
)
from resstockpostproc.standard_plots.schema.workflow_schema import QuantityGroup, WorkflowConfig

logger = logging.getLogger(__name__)


def get_app() -> DashProxy:
    # ----------------------------------------------------------------------------
    #   INITIALISE THE ORCHESTRATOR (loads data only once!)
    # ----------------------------------------------------------------------------
    workflow_yaml = str(Path(__file__).with_name("workflow.yaml"))
    workflow: WorkflowConfig = WorkflowConfig.from_yaml(workflow_yaml)  # convenience alias
    workflow.add_everything_group()

    if plots_root_folder := os.environ.get("PLOTS_ROOT_FOLDER"):
        workflow.set_output_dir(plots_root_folder)
        workflow.set_storage_backend("minio")

    print(f"Output dir: {workflow.output_dir}")

    # Build look-up dict for QuantityGroup by its name so we can easily instantiate
    # a PlotSpec from UI selections later.
    qg_by_name: dict[str, QuantityGroup] = {qg.name: qg for qg in workflow.quantities}
    plots_dir = Path(workflow.output_dir).expanduser().resolve() / "plots"

    # ---------------------------------------------------------------------------
    #   Helpers for run folders / snapshots
    # ---------------------------------------------------------------------------

    def _scan_run_folders() -> list[str]:
        """Return sorted list of available run-folder names."""
        return sorted([p.name for p in plots_dir.iterdir() if p.is_dir()])

    def _load_snapshot(run_folder: str) -> dict[str, Any] | None:
        """Load workflow_snapshot.json for the given folder, if it exists."""
        path = plots_dir / run_folder / "workflow_snapshot.json"
        if path.exists():
            with open(path) as f:
                return json.load(f)
        return None

    _orchestrators: dict[str, PlotOrchestrator] = {}

    def get_orchestrator_for_run(run_folder: str) -> PlotOrchestrator | None:
        if run_folder not in _orchestrators:
            snapshot = _load_snapshot(run_folder)
            if snapshot is None:
                return None

            new_workflow = WorkflowConfig.from_yaml(workflow_yaml)
            new_workflow.set_run_name(run_folder)
            new_workflow.add_everything_group()
            new_workflow.set_s3_results_dir(snapshot["s3_results_dir"])
            new_workflow.set_upgrades(snapshot["upgrades"])
            new_workflow.set_upgrade_names(snapshot["upgrade_names"])
            if plots_root_folder:
                new_workflow.set_output_dir(plots_root_folder)
                new_workflow.set_storage_backend("minio")

            # will never overwrite existing files but can save new files/plots
            _orchestrators[run_folder] = PlotOrchestrator(new_workflow, overwrite=False)

        return _orchestrators[run_folder]

    # ----------------------------------------------------------------------------
    #   DASH APP INITIALIZATION
    # ----------------------------------------------------------------------------
    external_scripts = [
        "https://cdn.tailwindcss.com",  # provides Tailwind classes (optional)
    ]
    transforms = [MultiplexerTransform()]  # allows multiple callbacks to update same Output

    app = DashProxy(
        __name__,
        external_stylesheets=[dbc.themes.BOOTSTRAP],
        transforms=transforms,
        external_scripts=external_scripts,
        suppress_callback_exceptions=True,
    )

    # ----------------------------------------------------------------------------
    #   LAYOUT - CONTROLS + GRAPH
    # ----------------------------------------------------------------------------
    app.layout = dbc.Container(
        [
            dcc.Location(id="url", refresh=False),
            # Modal to display invalid plot-spec errors
            dbc.Modal(
                [
                    dbc.ModalHeader(dbc.ModalTitle("Alert")),
                    dbc.ModalBody(id="invalid-spec-msg"),
                ],
                id="invalid-spec-modal",
                is_open=False,
            ),
            dbc.Row(
                [
                    dbc.Col(html.H2("ResStock Dashboard"), width="auto"),
                    dbc.Col(
                        html.Div(
                            [
                                html.Small("Run folder", className="d-block fw-bold mb-1"),
                                dcc.Dropdown(
                                    id="run-folder",
                                    options=[],
                                    value="",
                                    clearable=False,
                                    style={"minWidth": "250px"},
                                    persistence=True,
                                    persistence_type="local",
                                    persisted_props=["value"],
                                ),
                            ],
                        ),
                        md=3,
                    ),
                    dbc.Col(
                        html.Div(id="run-info"),
                        width="auto",
                    ),
                    dbc.Col(
                        html.Div(
                            [
                                dbc.Switch(
                                    id="dynamic-toggle",
                                    label="Always Dynamic",
                                    value=False,  # default OFF
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
            ),
            dbc.Card(
                dbc.CardBody(
                    [
                        # Row 1 - main controls (upgrade/vacancy/quantity_type/viz)
                        dbc.Row(
                            [
                                dbc.Col(
                                    html.Div(
                                        [
                                            html.Small("Building Inclusion", className="d-block fw-bold mb-1"),
                                            dcc.Dropdown(
                                                id="building-inclusion",
                                                options={
                                                    "__all__": "All",
                                                    "applied_all": "Applied in respective upgrades",
                                                },
                                                value="applied_all",
                                                clearable=False,
                                                persistence=True,
                                                persistence_type="local",
                                                persisted_props=["value"],
                                            ),
                                        ]
                                    ),
                                    md=2,
                                ),
                                dbc.Col(
                                    html.Div(
                                        [
                                            html.Small("Vacancy inclusion", className="d-block fw-bold mb-1"),
                                            dcc.RadioItems(
                                                id="vacancy-inclusion",
                                                options=[vi.value for vi in workflow.vacancy_inclusion],
                                                value=workflow.vacancy_inclusion[0].value,
                                                inline=True,
                                                persistence=True,
                                                persistence_type="local",
                                                persisted_props=["value"],
                                            ),
                                        ]
                                    ),
                                    md=2,
                                ),
                                dbc.Col(
                                    html.Div(
                                        [
                                            html.Small("Quantity type", className="d-block fw-bold mb-1"),
                                            dcc.Dropdown(
                                                id="quantity-type",
                                                options=[ct.value for ct in workflow.quantity_types],
                                                value="savings",
                                                clearable=False,
                                                style={"minWidth": "180px"},
                                                persistence=True,
                                                persistence_type="local",
                                                persisted_props=["value"],
                                            ),
                                        ]
                                    ),
                                    md=2,
                                ),
                                dbc.Col(
                                    html.Div(
                                        [
                                            html.Small("Aggregation Type", className="d-block fw-bold mb-1"),
                                            dcc.RadioItems(
                                                id="aggregation-type",
                                                options=[vt.value for vt in workflow.aggregation_types],
                                                value="average",
                                                inline=True,
                                                persistence=True,
                                                persistence_type="local",
                                                persisted_props=["value"],
                                            ),
                                        ]
                                    ),
                                    md=2,
                                    id="aggregation-type-col",
                                ),
                                dbc.Col(
                                    html.Div(
                                        [
                                            html.Small("Visualization type", className="d-block fw-bold mb-1"),
                                            dcc.RadioItems(
                                                id="viz-type",
                                                options=[vt.value for vt in workflow.visualization_types],
                                                value="box",
                                                inline=True,
                                                persistence=True,
                                                persistence_type="local",
                                                persisted_props=["value"],
                                            ),
                                        ]
                                    ),
                                    md=2,
                                ),
                            ]
                        ),
                        html.Hr(className="my-2"),
                        # Row 2 - grouping & quantity controls
                        dbc.Row(
                            [
                                dbc.Col(
                                    html.Div(
                                        [
                                            html.Small("Group by", className="d-block fw-bold mb-1"),
                                            dcc.Dropdown(
                                                id="group-by",
                                                options=[],
                                                value="__none__",
                                                clearable=False,
                                                persistence=True,
                                                persistence_type="local",
                                                persisted_props=["value"],
                                            ),
                                        ]
                                    ),
                                    md=4,
                                ),
                                dbc.Col(
                                    html.Div(
                                        [
                                            html.Small("Quantity group", className="d-block fw-bold mb-1"),
                                            dcc.Dropdown(
                                                id="quantity-group",
                                                options=list(qg_by_name.keys()),
                                                value="Bills",
                                                clearable=False,
                                                persistence=True,
                                                persistence_type="local",
                                                persisted_props=["value"],
                                            ),
                                        ]
                                    ),
                                    md=4,
                                ),
                                dbc.Col(
                                    html.Div(
                                        [
                                            html.Small("Quantity", className="d-block fw-bold mb-1"),
                                            dcc.Dropdown(
                                                id="quantity",
                                                clearable=False,
                                                value="out.bills.all_fuels.usd",
                                                persistence=True,
                                                persistence_type="local",
                                                persisted_props=["value"],
                                            ),
                                        ]
                                    ),
                                    md=4,
                                ),
                            ]
                        ),
                    ]
                ),
                className="my-3",
            ),
            # Sidebar + Figure
            dbc.Row(
                [
                    dbc.Col(
                        dbc.Card(
                            dbc.CardBody(
                                [
                                    # ---------------- FIGURE ADJUSTMENT BLOCK ----------------
                                    html.Div(
                                        [
                                            html.Small("Figure adjustment", className="d-block fw-bold mb-1"),
                                            dbc.Checklist(
                                                id="fig-editable",
                                                options=[{"label": "Edit text", "value": "editable"}],
                                                value=[],
                                                switch=True,
                                                persistence=True,
                                                persistence_type="local",
                                                persisted_props=["value"],
                                                className="mb-2",
                                            ),
                                            html.Small("Width (px)", className="d-block fw-bold mb-1"),
                                            dcc.Slider(
                                                id="fig-width",
                                                min=400,
                                                max=2500,
                                                step=100,
                                                value=1000,
                                                persistence=True,
                                                persistence_type="local",
                                                persisted_props=["value"],
                                                marks={i: str(i) for i in range(400, 2501, 400)},
                                            ),
                                            html.Small("Height (px)", className="d-block fw-bold mb-1"),
                                            dcc.Slider(
                                                id="fig-height",
                                                min=300,
                                                max=1800,
                                                step=50,
                                                value=700,
                                                persistence=True,
                                                persistence_type="local",
                                                persisted_props=["value"],
                                                marks={i: str(i) for i in range(300, 1801, 300)},
                                            ),
                                        ],
                                        id="figure-adjustment-box",
                                        className="border rounded p-2 mb-2",
                                    ),
                                    # ---------------- LEGEND ADJUSTMENT BLOCK ----------------
                                    html.Div(
                                        [
                                            html.Small("Legend adjustment", className="d-block fw-bold mb-1"),
                                            dbc.Checklist(
                                                id="legend-show",
                                                options=[{"label": "Show legend", "value": "show"}],
                                                value=["show"],
                                                switch=True,
                                                className="mb-2",
                                                persistence=True,
                                                persistence_type="local",
                                            ),
                                            html.Small("Legend position", className="d-block fw-bold mb-1"),
                                            dcc.Dropdown(
                                                id="legend-position",
                                                options={
                                                    "right": "Right (outside)",
                                                    "bottom": "Bottom (outside)",
                                                    "tr": "Top-right (inside)",
                                                    "br": "Bottom-right (inside)",
                                                    "tl": "Top-left (inside)",
                                                    "bl": "Bottom-left (inside)",
                                                },
                                                value="right",
                                                clearable=False,
                                                className="mb-2",
                                                persistence=True,
                                                persistence_type="local",
                                                persisted_props=["value"],
                                            ),
                                        ],
                                        id="legend-adjustment-box",
                                        className="border rounded p-2 mb-2",
                                    ),
                                    # ---------------- FACET ADJUSTMENT BLOCK ----------------
                                    html.Div(
                                        [
                                            html.Small(
                                                "Facet adjustment",
                                                className="d-block fw-bold mb-1",
                                            ),
                                            html.Div(
                                                dbc.Checklist(
                                                    id="facet-vertical",
                                                    options=[{"label": "Orientation", "value": "vertical"}],
                                                    value=[],
                                                    switch=True,
                                                    persistence=True,
                                                    persistence_type="local",
                                                ),
                                                id="facet-title-orientation-div",
                                                className="mb-2",
                                                style={"display": "none"},
                                            ),
                                            html.Div(
                                                [
                                                    html.Small(
                                                        "Text wrap width",
                                                        className="d-block fw-bold mb-1",
                                                    ),
                                                    dcc.Slider(
                                                        id="facet-wrap-width",
                                                        min=5,
                                                        max=80,
                                                        step=5,
                                                        value=20,
                                                        marks={i: str(i) for i in range(5, 81, 5)},
                                                        tooltip={
                                                            "placement": "bottom",
                                                            "always_visible": False,
                                                        },
                                                        className="mt-2",
                                                        persistence=True,
                                                        persistence_type="local",
                                                        persisted_props=["value"],
                                                    ),
                                                ],
                                                id="facet-wrap-width-div",
                                                className="mb-2",
                                                style={"display": "none"},
                                            ),
                                        ],
                                        id="facet-adjustment-box",
                                        className="border rounded p-2 mb-2",
                                        style={"display": "none"},
                                    ),
                                    # Title adjustment feature removed (was causing issues)
                                    # Download buttons row
                                    dbc.Row(
                                        [
                                            dbc.Col(
                                                dbc.Button(
                                                    "Download CSV",
                                                    id="btn-download-csv",
                                                    color="secondary",
                                                    className="w-100",
                                                ),
                                                width=4,
                                            ),
                                            dbc.Col(
                                                dbc.Button(
                                                    "Download Parquet",
                                                    id="btn-download-parquet",
                                                    color="secondary",
                                                    className="w-100",
                                                ),
                                                width=4,
                                            ),
                                            dbc.Col(
                                                dbc.Button(
                                                    "Download PDF",
                                                    id="btn-download-pdf",
                                                    color="secondary",
                                                    className="w-100",
                                                ),
                                                width=4,
                                            ),
                                        ],
                                        className="mt-2",
                                    ),
                                    # Hidden download components
                                    dcc.Download(id="download-csv"),
                                    dcc.Download(id="download-parquet"),
                                    dcc.Download(id="download-pdf"),
                                    html.Br(),
                                    dbc.Button(
                                        "Generate Plot", id="generate-btn", color="primary", className="mt-2 w-100"
                                    ),
                                ]
                            ),
                            className="my-3",
                        ),
                        md=3,
                    ),
                    dbc.Col(
                        dcc.Loading(
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
                                },
                            ),
                            type="cube",
                        ),
                        md=9,
                    ),
                ],
            ),
            # Cached plot indicator anchored bottom-left
            html.Div(
                id="cache-indicator",
                className="text-muted",
                style={
                    "fontSize": "0.75rem",
                    "position": "fixed",
                    "left": "10px",
                    "bottom": "5px",
                },
            ),
            # Stores for clientside downloads
            dcc.Store(id="df-parquet", storage_type="memory"),
            dcc.Store(id="df-csv", storage_type="memory"),
            html.Div(id="download-dummy", style={"display": "none"}),
        ],
        fluid=True,
    )

    # ----------------------------------------------------------------------------
    #   CALLBACK - display Run Info
    # ----------------------------------------------------------------------------
    @app.callback(
        Output("run-info", "children"),
        Input("run-folder", "value"),
    )
    def _update_run_info(run_folder: str):  # type: ignore[override]
        """Display S3 results directory and a summary of upgrades for the selected run folder."""

        wf: dict[str, Any] | None = _load_snapshot(run_folder)
        if not wf:
            return html.Div("RUN INFO NOT AVAILABLE", className="text-center")

        s3_dir = wf.get("s3_results_dir", "N/A")
        upgrades = wf.get("upgrades", [])
        orchestrator = get_orchestrator_for_run(run_folder)
        if orchestrator is None:
            return html.Div("Run folder does not have orchestrator. Cannot give run info.")
        baseline_df = orchestrator.processor.combined_df.filter(pl.col("upgrade") == 0)
        num_data_points = baseline_df.select(pl.len()).collect().item()
        upgrade_tokens: list[str] = []
        # Keep baseline (0) but make it disabled in the checklist so it stays always selected.
        non_baseline_upgrades = [u for u in upgrades if u != 0]
        baseline_token = None
        if 0 in upgrades:
            baseline_token = f"{'0(Base)':<10}"
        for upgrade in non_baseline_upgrades:
            upgrade_df = orchestrator.processor.combined_df.filter(pl.col("upgrade") == upgrade)
            num_applicable = upgrade_df.filter(pl.col("applicability")).select(pl.len()).collect().item()
            token = f"{upgrade}({num_applicable / num_data_points * 100:.1f}%)"
            upgrade_tokens.append(f"{token:<10}")

        # Build a checklist so user can filter upgrades visually. All selected by default.
        # We keep tokens short (e.g., "3(75.2%)") and rely on wrapping to avoid layout breakage.
        checklist_options = []
        if baseline_token is not None:
            checklist_options.append({"label": baseline_token, "value": 0, "disabled": True})
        checklist_options.extend(
            {"label": tok, "value": upg} for tok, upg in zip(upgrade_tokens, non_baseline_upgrades)
        )
        checklist = dcc.Checklist(
            id="selected-upgrades",
            options=checklist_options,
            value=[opt["value"] for opt in checklist_options],  # all selected including baseline
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

        upgrade_children: list[Any] = [
            html.Span("Upgrades (applied %): ", className="fw-bold me-1"),
            checklist,
        ]

        return html.Div(
            [
                html.Small("Run Info", className="d-block fw-bold mb-1"),
                html.Div(
                    [html.Span("S3: ", className="fw-bold"), html.Span(s3_dir)],
                    style={"fontSize": "0.75rem", "wordBreak": "break-all"},
                ),
                html.Div(
                    upgrade_children,
                    style={
                        "fontSize": "0.75rem",
                        "maxWidth": "480px",
                        "whiteSpace": "normal",
                        "wordWrap": "break-word",
                        "lineHeight": "1.1rem",
                    },
                ),
                html.Div(
                    [html.Span("Number of data points: ", className="fw-bold"), html.Span(num_data_points)],
                    style={"fontSize": "0.75rem"},
                ),
            ]
        )

    # ----------------------------------------------------------------------------
    #   CALLBACK - populate `quantity` options whenever quantity-group or viz-type changes
    # ----------------------------------------------------------------------------
    @app.callback(
        Output("quantity", "options"),
        Output("quantity", "value"),
        Input("quantity-group", "value"),
        Input("viz-type", "value"),
        Input("group-by", "value"),
        State("quantity", "value"),
    )
    def _update_quantity_dd(
        qgroup_name: str,
        viz_type_val: str,
        group_by_val: str,
        current_val: str | None,
    ):
        if not qgroup_name:
            raise PreventUpdate

        qg = qg_by_name[qgroup_name]
        viz_type = VizType(viz_type_val)

        opts: list[dict[str, Any]] = []
        # Individual constituents
        opts.extend({"label": c, "value": c} for c in qg.constituents)
        # Sum column if any
        if qg.sum:
            opts.append({"label": qg.sum, "value": qg.sum})
        # Stacked option logic --------------------------------------------------
        if viz_type in [VizType.bar] or (viz_type == VizType.box and group_by_val in (None, "__none__")):
            opts.append({"label": "ALL - stacked", "value": "__group_stacked__"})

        # Heatmap forces stacked only
        if viz_type in [VizType.heatmap]:
            opts = [{"label": "ALL - stacked", "value": "__group_stacked__"}]

        # Preserve current selection if still valid, else fall back to first option
        default_val = current_val if current_val in {o["value"] for o in opts} else opts[0]["value"]
        return opts, default_val

    # ----------------------------------------------------------------------------
    #   CALLBACK - generate figure
    # ----------------------------------------------------------------------------
    @app.callback(
        Output("plot-graph", "figure"),
        Output("cache-indicator", "children"),
        Output("df-parquet", "data"),
        Output("df-csv", "data"),
        Output("invalid-spec-modal", "is_open"),
        Output("invalid-spec-msg", "children"),
        Input("generate-btn", "n_clicks"),
        Input("building-inclusion", "value"),
        Input("vacancy-inclusion", "value"),
        Input("quantity-type", "value"),
        Input("aggregation-type", "value"),
        Input("viz-type", "value"),
        Input("group-by", "value"),
        Input("quantity-group", "value"),
        Input("quantity", "value"),
        Input("fig-width", "value"),
        Input("fig-height", "value"),
        Input("legend-show", "value"),
        Input("legend-position", "value"),
        Input("facet-vertical", "value"),
        Input("facet-wrap-width", "value"),
        Input("dynamic-toggle", "value"),  # NE dynamic on/off
        Input("run-folder", "value"),  # NEW - selected run folder
        Input("selected-upgrades", "value"),  # selected upgrades from checklist
    )
    def _generate_figure(
        _: int | None,
        building_incl: str,
        vacancy_incl: str,
        comp_type: str,
        aggregation_type: str,
        viz_type_val: str,
        group_by_val: str,
        qgroup_name: str,
        quantity_val: str,
        fig_w: int,
        fig_h: int,
        legend_show: list[str],
        legend_pos: str,
        facet_orientation: list[str],
        wrap_width: int,
        dynamic_mode: bool,  # receives value from dynamic-toggle
        run_folder_val: str,  # receives selected run folder
        selected_upgrades: list[int],
    ):
        # if not n_clicks:
        #     return go.Figure(), dash.no_update, dash.no_update

        # Build the PlotSpec from current UI selections
        plot_spec = _build_plot_spec(
            building_incl,
            vacancy_incl,
            comp_type,
            aggregation_type,
            viz_type_val,
            group_by_val,
            qgroup_name,
            quantity_val,
        )
        if not plot_spec.is_valid():
            warning = f"Invalid plot spec: {plot_spec.get_error()}"
            logger.warning(warning)
            _df, fig = _get_dummy_df_fig(warning)
            # Open modal with message and return empty data strings
            return dash.no_update, dash.no_update, dash.no_update, dash.no_update, True, warning

        logger.info(f"Generating figure for plot spec: {plot_spec}")
        try:
            df, fig, cached = _prepare_df_fig(
                plot_spec,
                fig_w,
                fig_h,
                legend_show,
                legend_pos,
                facet_orientation,
                wrap_width,
                dynamic_mode,
                run_folder_val,
                selected_upgrades,
            )
        except Exception:  # noqa: BLE001 catch blind exception
            error = f"Failed to generate figure for plot spec: {plot_spec}. Error: {traceback.format_exc()}"
            logger.error(error)
            df, fig = _get_dummy_df_fig(error)
            cached = False
        # drop any columns that are list dtypes
        df = df.drop([col for col in df.columns if df[col].dtype == pl.List])
        csv_str = df.write_csv(file=None)
        # Note: Plotly Layout does not support "editable"; this was causing a validation error.
        #       We omit this call for now - figure interactivity can be controlled via the Graph config.
        fig.update_layout(width=fig_w, height=fig_h)
        buf = io.BytesIO()
        df.write_parquet(buf)
        parquet_b64 = base64.b64encode(buf.getvalue()).decode("ascii")

        # Close modal (if open) and leave its message unchanged
        cache_text = "(loaded from cache)" if cached else "(generated dynamically)"
        return fig, cache_text, parquet_b64, csv_str, False, dash.no_update

    # ----------------------------------------------------------------------------
    #   CALLBACK - update Graph config editable flag
    # ----------------------------------------------------------------------------
    @app.callback(
        Output("plot-graph", "config"),
        Input("fig-editable", "value"),
    )
    def _update_graph_config(editable_vals: list[str]):  # type: ignore[override]
        """Toggle graph text-editing based on switch."""
        base_cfg = {
            "autosizable": True,
            "responsive": True,
            "displaylogo": False,
            "modeBarButtons": [
                ["toImage"],
                ["zoom2d", "zoomIn2d", "zoomOut2d", "autoScale2d", "resetScale2d"],
            ],
            "toImageButtonOptions": {
                "format": "svg",  # one of png, svg, jpeg, webp
            },
        }
        if "editable" in editable_vals:
            base_cfg["editable"] = True
        return base_cfg

    # ----------------------------------------------------------------------------
    #   CALLBACK - disable Quantity Group & Quantity dropdowns for Model Count
    # ----------------------------------------------------------------------------
    @app.callback(
        Output("quantity-group", "disabled"),
        Output("quantity", "disabled"),
        Input("quantity-type", "value"),
    )
    def _toggle_quantity_controls(quantity_type_val: str):
        try:
            qtype = QuantityType(quantity_type_val)
        except ValueError:
            raise PreventUpdate
        disabled = qtype == QuantityType.model_count
        return disabled, disabled

    # ----------------------------------------------------------------------------
    #   CALLBACK - dynamically restrict *Aggregation type* options based on quantity-type
    # ----------------------------------------------------------------------------
    @app.callback(
        Output("aggregation-type", "options"),
        Output("aggregation-type", "value"),
        Input("quantity-type", "value"),
        State("aggregation-type", "value"),
    )
    def _update_aggregation_type_dd(quantity_type_val: str, current_val: str):
        """Update Aggregation type options whenever Quantity type changes."""
        try:
            qtype = QuantityType(quantity_type_val)
        except ValueError:
            raise PreventUpdate

        allowed = PlotSpec.get_valid_aggregation_types(qtype)
        opts = [{"label": at.name, "value": at.value} for at in allowed]
        new_val = current_val if current_val in {o["value"] for o in opts} else opts[0]["value"]
        return opts, new_val

    # ----------------------------------------------------------------------------
    #   CALLBACK - dynamically restrict *Visualization type* options based on aggregation-type
    # ----------------------------------------------------------------------------
    @app.callback(
        Output("viz-type", "options"),
        Output("viz-type", "value"),
        Input("aggregation-type", "value"),
        Input("quantity-type", "value"),
        State("viz-type", "value"),
    )
    def _update_viz_type_dd(aggregation_type_val: str, quantity_type_val: str, current_val: str):
        """Update Visualization type options whenever Aggregation type changes."""
        try:
            agg_type = AggregationType(aggregation_type_val)
        except ValueError:
            raise PreventUpdate

        try:
            qtype = QuantityType(quantity_type_val)
        except ValueError:
            raise PreventUpdate

        valid_viz_types = PlotSpec.get_valid_visualization_types(qtype, agg_type)
        opts = [{"label": vt.name, "value": vt.value} for vt in valid_viz_types]
        new_val = current_val if current_val in {o["value"] for o in opts} else opts[0]["value"]
        return opts, new_val

    # ----------------------------------------------------------------------------
    #   CALLBACK - update Group By dropdown when run folder changes
    # ----------------------------------------------------------------------------
    @app.callback(
        Output("group-by", "options"),
        Output("group-by", "value"),
        Input("run-folder", "value"),
        State("group-by", "value"),
    )
    def _update_group_by_options(run_folder: str, current_val: str | None):
        """Refresh the Group By dropdown to reflect the selected run's workflow configuration.

        In addition to the *group_by* list defined in the workflow YAML, we now also
        surface **additional building characteristics** (columns whose names start
        with ``in.`` and whose baseline records have between 2 and 20 distinct
        values).  These are shown in a separate section underneath the original
        items, separated by a disabled label row so the UI is easy to navigate.
        """

        orchestrator = get_orchestrator_for_run(run_folder)
        if orchestrator is None:
            raise PreventUpdate

        # ---------------------------------------------------------------------
        #   Original workflow-defined group_by columns
        # ---------------------------------------------------------------------
        workflow_group_by: tuple[str, ...] = orchestrator.workflow.group_by

        # ---------------------------------------------------------------------
        #   Dynamically discover low-cardinality input columns
        # ---------------------------------------------------------------------
        small_chars: list[str] = []
        try:
            # Only baseline (upgrade == 0) records are considered when counting uniques
            base_df: pl.LazyFrame = orchestrator.processor.combined_df.filter(pl.col("upgrade") == 0)
            in_cols = [c for c in base_df.collect_schema().names() if c.startswith("in.")]
            if in_cols:
                # Compute unique counts in a single pass
                unique_df = base_df.select([pl.col(c).n_unique().alias(c) for c in in_cols]).collect()
                unique_counts = dict(zip(in_cols, unique_df.row(0)))  # type: ignore[arg-type]
                small_chars = sorted([c for c, n in unique_counts.items() if 1 < n <= 20])  # noqa: PLR2004
        except Exception as exc:  # noqa: BLE001
            logger.warning(f"Failed to compute additional group-by characteristics: {exc}")

        # ---------------------------------------------------------------------
        #   Build Dropdown options with separators
        # ---------------------------------------------------------------------
        opts: list[dict] = [
            {"label": "None", "value": "__none__"},
            {"label": "— Workflow group-by —", "value": "__sep_wf__", "disabled": True},
            *[{"label": col, "value": col} for col in workflow_group_by],
        ]

        if small_chars:
            opts.extend(
                [
                    {"label": "— Additional characteristics —", "value": "__sep_extra__", "disabled": True},
                    *[{"label": col, "value": col} for col in small_chars if col not in workflow_group_by],
                ]
            )

        # Determine the new selected value, ignoring separator rows
        valid_values = {o["value"] for o in opts if not o.get("disabled", False)}
        new_val = current_val if current_val in valid_values else "__none__"

        logger.info("Updating group by options: %s", [o["label"] for o in opts])
        return opts, new_val

    # ----------------------------------------------------------------------------
    #   CALLBACK - update Upgrade Inclusion dropdown when run folder changes
    # ----------------------------------------------------------------------------
    @app.callback(
        Output("building-inclusion", "options"),
        Output("building-inclusion", "value"),
        Input("run-folder", "value"),
        Input("selected-upgrades", "value"),
        State("building-inclusion", "value"),
    )
    def _update_upgrade_inclusion_dd(run_folder: str, selected_upgrades: list[int], current_val: str):
        """Refresh Upgrade Inclusion dropdown based on selected upgrades.

        If user deselects some upgrades in the checklist, only those remain as
        explicit "Applied in Upgrade N" options. Baseline (0) is never shown
        as a selectable single-upgrade option here.
        """
        orchestrator = get_orchestrator_for_run(run_folder)
        if orchestrator is None:
            raise PreventUpdate

        opts: list[dict[str, str]] = [
            {"label": "All", "value": "__all__"},
            {"label": "Applied in respective upgrades", "value": "applied_all"},
        ]
        opts.extend({"label": f"Applied in Upgrade {u}", "value": f"applied_{u}"}
                    for u in selected_upgrades if u != 0)

        valid_vals = {o["value"] for o in opts}
        new_val = current_val if current_val in valid_vals else "__all__"
        return opts, new_val

    # ----------------------------------------------------------------------------
    #   CALLBACKS - DOWNLOAD DATA & FIGURE
    # ----------------------------------------------------------------------------
    def _get_dummy_df_fig(error_msg: str):
        fig = go.Figure()
        # Wrap the error message so it does not overflow the figure. ``textwrap.fill``
        # inserts ``\n`` line-breaks which Plotly ignores, so convert them to ``<br>``.
        wrapped_msg = textwrap.fill(error_msg, width=200, break_long_words=False)
        wrapped_msg = wrapped_msg.replace("\n", "<br>")
        fig.add_annotation(
            text=wrapped_msg,
            xref="paper",
            yref="paper",
            x=0.5,
            y=0.5,
            showarrow=False,
            font={"size": 10, "color": "red"},
        )
        fig.update_layout(
            title="Error Occurred",
            title_subtitle_text="",
            xaxis={"showgrid": False, "showticklabels": False, "title": ""},
            yaxis={"showgrid": False, "showticklabels": False, "title": ""},
        )
        return pl.DataFrame(), fig

    def _build_plot_spec(
        building_incl: str,
        vacancy_incl: str,
        quantity_type: str,
        aggregation_type: str,
        viz_type_val: str,
        group_by_val: str,
        qgroup_name: str,
        quantity_val: str,
    ) -> PlotSpec:
        """Helper to build PlotSpec from control values (shared by callbacks)."""
        viz_type = VizType(viz_type_val)
        group_by = group_by_val if group_by_val != "__none__" else None

        if quantity_val == "__group_stacked__":
            quantity: str | QuantityGroup = qg_by_name[qgroup_name]
        else:
            quantity = quantity_val

        if building_incl == "__all__":
            upg_incl_enum = BuildingInclusion.all
            upgrade_num = None

        elif building_incl == "applied_all":
            upg_incl_enum = BuildingInclusion.applied_only
            upgrade_num = None
        elif building_incl.startswith("applied_"):
            upg_incl_enum = BuildingInclusion.applied_only
            upgrade_num = int(building_incl.split("_")[1])
        # Baseline only ("0") or Upgrade N only ("1", "2", ...)
        else:
            upg_incl_enum = BuildingInclusion.all
            upgrade_num = int(building_incl)

        return PlotSpec(
            building_inclusion=upg_incl_enum,
            vacancy_inclusion=VacancyInclusion(vacancy_incl),
            quantity_type=QuantityType(quantity_type),
            aggregation_type=AggregationType(aggregation_type),
            visualization_type=viz_type,
            group_by=group_by,
            quantity=quantity,
            quantity_group_name=qgroup_name,
            upgrade=upgrade_num,
        )

    def _prepare_df_fig(
        spec: PlotSpec,
        fig_w: int,
        fig_h: int,
        legend_show: list[str],
        legend_pos: str,
        facet_orientation: list[str],
        wrap_width: int,
        dynamic_mode: bool,
        run_folder_val: str,
        selected_upgrades: list[int] | None,
    ):
        """Return dataframe and fully styled figure for given PlotSpec and layout inputs."""
        df = pl.DataFrame()
        fig = go.Figure()
        if not run_folder_val:
            raise PreventUpdate
        orchestrator = get_orchestrator_for_run(run_folder_val)
        loaded_from_file = False  # Track if we used cached artefacts
        # If a subset of non-baseline upgrades is selected, force dynamic mode (cache stores full set).
        if orchestrator is not None and selected_upgrades is not None:
            if sorted(selected_upgrades) != sorted(orchestrator.workflow.upgrades):
                dynamic_mode = True
            else:
                selected_upgrades = None  # pass None to use all upgrades in workflow
        if not dynamic_mode:
            # Construct expected file locations using the OutputManager schema
            path_seg, name = spec.get_path_and_name()
            base_dir = Path(workflow.output_dir).expanduser().resolve() / "plots" / str(run_folder_val)
            fig_path = base_dir / path_seg / "figure_json" / f"{name}.json"
            parquet_path = base_dir / path_seg / "data" / f"{name}.parquet"
            if fig_path.exists() and parquet_path.exists():
                try:
                    fig_dict = pio.read_json(str(fig_path))
                    fig = go.Figure(fig_dict)
                    df = pl.read_parquet(str(parquet_path), glob=False)
                    logger.info(f"Loaded plot from {fig_path}")
                    loaded_from_file = True  # mark that we loaded cached plot
                except Exception:  # noqa: BLE001 catch blind exception
                    logger.warning(
                        f"Failed to load data/figure from {fig_path} or {parquet_path} "
                        f"due to error:\n{traceback.format_exc()}\nGenerating them on the fly."
                    )
                    dynamic_mode = True
            else:
                logger.warning(f"Missing {fig_path} or {parquet_path}. Generating them on the fly.")
                dynamic_mode = True

        if dynamic_mode:
            if orchestrator is None:
                warning = f"{run_folder_val} folder does not have workflow_snapshot.json."
                warning += "\nCannot dynamically generate plots."
                logger.warning(warning)
                user_warning = "This old run cannot be viewed in the new dashboard"
                user_warning += "\nPlease view it in the old dashboard or re-run the flow."
                df, fig = _get_dummy_df_fig(user_warning)
                return df, fig, False
            start_time = time.time()
            print("Preparing data for plot...")
            df = orchestrator.processor.prepare_data_for_plot(spec, selected_upgrades=selected_upgrades)
            print(f"Data prepared in {time.time() - start_time:.1f} seconds. Generating data ...")
            plotter = orchestrator.get_plotter(spec.visualization_type)
            start_time = time.time()
            orchestrator.theme.update_upgrade_palette(
                tuple(selected_upgrades) if selected_upgrades is not None else None
            )
            fig = plotter.create_plot(df, spec)
            print(f"Figure generated in {time.time() - start_time:.1f} seconds.")

        # styling tweaks similar to original implementation
        fig.layout.title.subtitle.text = ""
        if not fig.layout.title.text:
            fig.layout.title.text = " "

        show_legend = "show" in legend_show
        legend_cfg: dict[str, Any] = {}
        if legend_pos == "right":
            legend_cfg = {"orientation": "v", "x": 1.12, "y": 1, "xanchor": "left", "yanchor": "top"}
        elif legend_pos == "bottom":
            legend_cfg = {"orientation": "h", "x": 0, "y": -0.2, "xanchor": "left", "yanchor": "top"}
        elif legend_pos == "tr":
            legend_cfg = {"x": 1.12, "y": 1, "xanchor": "right", "yanchor": "top"}
        elif legend_pos == "br":
            legend_cfg = {"x": 1.12, "y": 0, "xanchor": "right", "yanchor": "bottom"}
        elif legend_pos == "tl":
            legend_cfg = {"x": 0, "y": 1, "xanchor": "left", "yanchor": "top"}
        elif legend_pos == "bl":
            legend_cfg = {"x": 0, "y": 0, "xanchor": "left", "yanchor": "bottom"}

        # Apply facet orientation and text wrapping requested via UI controls
        vertical = bool(facet_orientation and "vertical" in facet_orientation)
        wrap_val = wrap_width if wrap_width and wrap_width > 0 else None
        _apply_facet_orientation(fig, vertical=vertical, wrap_width=wrap_val)

        fig.update_layout(width=fig_w, height=fig_h, showlegend=show_legend, legend=legend_cfg)
        path_seg, name = spec.get_path_and_name()
        # if orchestrator is not None:
            # orchestrator.out_mgr.save_plot(fig, path_seg, df, name)
        return df, fig, loaded_from_file

    def _apply_facet_orientation(fig: Figure, vertical: bool, wrap_width: int | None = None):
        """Rotate facet titles and wrap text."""
        if not fig.layout.annotations:
            return
        angle = -90 if vertical else 0
        for ann in fig.layout.annotations:
            if ann.name == "xtitle":
                continue
            # Wrap text if width specified
            if wrap_width and wrap_width > 0:
                wrapped = textwrap.fill(str(ann.text).replace("<br>", " "), width=wrap_width, break_long_words=False)
                wrapped = wrapped.replace("\n", "<br>")
                ann.update(text=wrapped)
            ann.update(textangle=angle)

        # Increase top margin if vertical titles might overflow
        if vertical:
            # estimate longest title length (without <br>)
            longest = max(
                (max(len(part) for part in str(a.text).split("<br>")) for a in fig.layout.annotations), default=0
            )
            # heuristic: 6 px per character capped between 80 and 300
            extra_top = min(600, max(80, longest * 9))
            cur_margin = fig.layout.margin.t if fig.layout.margin and fig.layout.margin.t is not None else 0
            if extra_top > cur_margin:
                existing_margin = fig.layout.margin.to_plotly_json() if fig.layout.margin else {}
                fig.update_layout(margin={**existing_margin, "t": extra_top})

    @app.callback(
        Output("download-pdf", "data"),
        Input("btn-download-pdf", "n_clicks"),
        State("plot-graph", "figure"),
        prevent_initial_call=True,
    )
    def _download_pdf(_: int, fig: Figure):  # type: ignore[override]
        fig_obj = Figure(fig)
        pdf_bytes = fig_obj.to_image(format="pdf")
        return dcc.send_bytes(pdf_bytes, "resstock_plot.pdf")

    # ------------------------ CLIENTSIDE DOWNLOADS -----------------------------
    app.clientside_callback(
        """
        function(n_clicks, csvStr) {
            if (!n_clicks || !csvStr) { return window.dash_clientside.no_update; }
            const blob = new Blob([csvStr], {type: 'text/csv'});
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'resstock_data.csv';
            document.body.appendChild(a);
            a.click();
            setTimeout(function(){ URL.revokeObjectURL(url); a.remove(); }, 0);
            return '';
        }
        """,
        Output("download-dummy", "children"),
        Input("btn-download-csv", "n_clicks"),
        State("df-csv", "data"),
        prevent_initial_call=True,
    )

    app.clientside_callback(
        """
        function(n_clicks, b64) {
            if (!n_clicks || !b64) { return window.dash_clientside.no_update; }
            const byteChars = atob(b64);
            const len = byteChars.length;
            const bytes = new Uint8Array(len);
            for (let i = 0; i < len; i++) { bytes[i] = byteChars.charCodeAt(i); }
            const blob = new Blob([bytes], {type: 'application/octet-stream'});
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'resstock_data.parquet';
            document.body.appendChild(a);
            a.click();
            setTimeout(function(){ URL.revokeObjectURL(url); a.remove(); }, 0);
            return '';
        }
        """,
        Output("download-dummy", "children"),
        Input("btn-download-parquet", "n_clicks"),
        State("df-parquet", "data"),
        prevent_initial_call=True,
    )

    @app.callback(
        Output("facet-title-orientation-div", "style"),
        Input("plot-graph", "figure"),
    )
    def _toggle_facet_toggle_visibility(fig_dict: dict):  # type: ignore[override]
        if not fig_dict:
            raise PreventUpdate
        layout = fig_dict.get("layout", {})
        has_facet = any(k.startswith("xaxis") and k != "xaxis" for k in layout)
        return {} if has_facet else {"display": "none"}

    @app.callback(
        Output("facet-wrap-width-div", "style"),
        Input("plot-graph", "figure"),
    )
    def _toggle_facet_wrap_width_visibility(fig_dict: dict):  # type: ignore[override]
        if not fig_dict:
            raise PreventUpdate
        layout = fig_dict.get("layout", {})
        has_facet = any(k.startswith("xaxis") and k != "xaxis" for k in layout)
        return {} if has_facet else {"display": "none"}

    # Show/hide the entire facet-adjustment box depending on whether
    # the current figure uses faceting.
    @app.callback(
        Output("facet-adjustment-box", "style"),
        Input("plot-graph", "figure"),
    )
    def _toggle_facet_adjustment_visibility(fig_dict: dict):  # type: ignore[override]
        if not fig_dict:
            raise PreventUpdate
        layout = fig_dict.get("layout", {})
        has_facet = any(k.startswith("xaxis") and k != "xaxis" for k in layout)
        return {} if has_facet else {"display": "none"}

    # ----------------------------------------------------------------------------
    #   CALLBACK - refresh run-folder dropdown on page load
    # ----------------------------------------------------------------------------
    @app.callback(
        Output("run-folder", "options"),
        Output("run-folder", "value"),
        Input("url", "href"),  # fires on every hard refresh
        State("run-folder", "value"),
        prevent_initial_call=True,
    )
    def _refresh_run_folders(_: str, current_val: str | None):
        """Rescan directory on page load and update run-folder dropdown."""
        folders = _scan_run_folders()
        new_val = current_val if current_val in folders else (folders[0] if folders else None)
        return folders, new_val

    return app


def run_dashboard(port: int = 8051):
    try:
        print(f"Running dashboard on port {port}")
        app = get_app()
        app.run(debug=False, port=port, host="0.0.0.0")  # noqa: S104
    except Exception:  # noqa: BLE001 catch blind exception
        logger.error(f"Failed to run dashboard: {traceback.format_exc()}")


if __name__ == "__main__":
    run_dashboard()
