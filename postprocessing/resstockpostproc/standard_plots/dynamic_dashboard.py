"""Dynamic Dash dashboard for ResStock plots.

This dashboard exposes a fixed set of controls ("knobs") at the top so the
user can choose what they would like to visualise.  The figure is generated on
-the-fly using the new PlotSpec + PlotOrchestrator data pipeline.

This file does **NOT** rely on any pre-generated HTML files - it simply loads
the annual results CSV/parquet files once (via `PlotOrchestrator`) and then
creates the requested plot in real-time.
"""

import base64
import io
import json
import traceback
from pathlib import Path
from typing import Any

import dash_bootstrap_components as dbc  # type: ignore
import plotly.graph_objects as go  # type: ignore
import plotly.io as pio  # type: ignore
import polars as pl  # type: ignore
from dash import dcc, html
from dash.dependencies import Input, Output, State
from dash.exceptions import PreventUpdate
from dash_extensions.enrich import DashProxy, MultiplexerTransform  # type: ignore
from plotly.graph_objects import Figure
from prefect import flow, get_run_logger
import textwrap

# Local imports - all heavy lifting is done by these modules
from resstockpostproc.standard_plots.orchestrator import PlotOrchestrator
from resstockpostproc.standard_plots.schema.plot_spec import (
    ComparisonTypes,
    PlotSpec,
    UpgradeInclusion,
    VacancyInclusion,
    ValueTypes,
    VizType,
)
from resstockpostproc.standard_plots.schema.workflow_schema import QuantityGroup, WorkflowConfig


def get_app(logger) -> DashProxy:
    # ----------------------------------------------------------------------------
    #   INITIALISE THE ORCHESTRATOR (loads data only once!)
    # ----------------------------------------------------------------------------
    workflow_yaml = str(Path(__file__).with_name("workflow.yaml"))
    workflow: WorkflowConfig = WorkflowConfig.from_yaml(workflow_yaml)  # convenience alias
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

            snapshot["run_name"] = run_folder  # override run_name to allow folder rename
            new_workflow = WorkflowConfig.from_yaml(workflow_yaml)
            new_workflow.s3_results_dir = snapshot["s3_results_dir"]
            new_workflow.run_name = snapshot["run_name"]
            new_workflow.upgrades = snapshot["upgrades"]
            new_workflow.upgrade_names = snapshot["upgrade_names"]
            # Replace default group_by with the list from the snapshot so the UI matches the run configuration
            new_workflow.group_by.extend([g for g in snapshot["group_by"] if g not in new_workflow.group_by])
            _orchestrators[run_folder] = PlotOrchestrator(new_workflow)

        return _orchestrators[run_folder]

    # ----------------------------------------------------------------------------
    #   DASH APP INITIALISATION
    # ----------------------------------------------------------------------------
    external_scripts = [
        "https://cdn.tailwindcss.com",  # provides Tailwind classes (optional)
    ]
    transforms = [MultiplexerTransform()]  # allows multiple callbacks to update same Output

    app = DashProxy(
        __name__, external_stylesheets=[dbc.themes.BOOTSTRAP], transforms=transforms, external_scripts=external_scripts
    )

    # ----------------------------------------------------------------------------
    #   LAYOUT - CONTROLS + GRAPH
    # ----------------------------------------------------------------------------
    app.layout = dbc.Container(
        [
            dcc.Location(id="url", refresh=False),
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
                        # Row 1 - main controls (upgrade/vacancy/comparison/viz)
                        dbc.Row(
                            [
                                dbc.Col(
                                    html.Div(
                                        [
                                            html.Small("Upgrade inclusion", className="d-block fw-bold mb-1"),
                                            dcc.RadioItems(
                                                id="upgrade-inclusion",
                                                options=[ui.value for ui in workflow.upgrade_inclusion],
                                                value=workflow.upgrade_inclusion[0].value,
                                                inline=True,
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
                                            ),
                                        ]
                                    ),
                                    md=2,
                                ),
                                dbc.Col(
                                    html.Div(
                                        [
                                            html.Small("Comparison type", className="d-block fw-bold mb-1"),
                                            dcc.RadioItems(
                                                id="comparison-type",
                                                options=[ct.value for ct in workflow.comparison_types],
                                                value=workflow.comparison_types[0].value,
                                                inline=True,
                                            ),
                                        ]
                                    ),
                                    md=2,
                                ),
                                dbc.Col(
                                    html.Div(
                                        [
                                            html.Small("Visualization type", className="d-block fw-bold mb-1"),
                                            dcc.RadioItems(
                                                id="viz-type",
                                                options=[vt.value for vt in workflow.visualization_types],
                                                value=workflow.visualization_types[0].value,
                                                inline=True,
                                            ),
                                        ]
                                    ),
                                    md=2,
                                ),
                                dbc.Col(
                                    html.Div(
                                        [
                                            html.Small("Value type", className="d-block fw-bold mb-1"),
                                            dcc.RadioItems(
                                                id="value-type",
                                                options=[vt.value for vt in workflow.value_types],
                                                value=workflow.value_types[0].value,
                                                inline=True,
                                            ),
                                        ]
                                    ),
                                    md=2,
                                    id="value-type-col",
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
                                                options={"__none__": "None", **{col: col for col in workflow.group_by}},
                                                value="__none__",
                                                clearable=False,
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
                                                value=next(iter(qg_by_name.keys())),
                                                clearable=False,
                                            ),
                                        ]
                                    ),
                                    md=4,
                                ),
                                dbc.Col(
                                    html.Div(
                                        [
                                            html.Small("Quantity", className="d-block fw-bold mb-1"),
                                            dcc.Dropdown(id="quantity", clearable=False),
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
                                    html.Small("Figure width (px)", className="d-block fw-bold mb-1"),
                                    dcc.Slider(
                                        id="fig-width",
                                        min=400,
                                        max=2000,
                                        step=100,
                                        value=1000,
                                        marks={i: str(i) for i in range(400, 2001, 400)},
                                    ),
                                    html.Br(),
                                    html.Small("Figure height (px)", className="d-block fw-bold mb-1"),
                                    dcc.Slider(
                                        id="fig-height",
                                        min=300,
                                        max=1200,
                                        step=50,
                                        value=700,
                                        marks={i: str(i) for i in range(300, 1201, 300)},
                                    ),
                                    dbc.Checklist(
                                        id="legend-show",
                                        options=[{"label": "Show legend", "value": "show"}],
                                        value=["show"],
                                        switch=True,
                                        className="mb-2",
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
                                    ),
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
                                    "editable": True,
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
        # calculate the % of buildigns with applicability = True for each upgrade in the combined_df
        upgrade_text = ""
        for upgrade in upgrades:
            upgrade_df = orchestrator.processor.combined_df.filter(pl.col("upgrade") == upgrade)
            num_applicable = upgrade_df.filter(pl.col("applicability")).select(pl.len()).collect().item()
            upgrade_text += f"{upgrade}({num_applicable / num_data_points * 100:.1f}%), "

        return html.Div(
            [
                html.Small("Run Info", className="d-block fw-bold mb-1"),
                html.Div(
                    [html.Span("S3: ", className="fw-bold"), html.Span(s3_dir)],
                    style={"fontSize": "0.75rem", "wordBreak": "break-all"},
                ),
                html.Div(
                    [html.Span("Upgrades (applied %): ", className="fw-bold"), html.Span(upgrade_text)],
                    style={"fontSize": "0.75rem"},
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
        State("quantity", "value"),
    )
    def _update_quantity_dd(qgroup_name: str, viz_type_val: str, current_val: str | None):
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
        # Group stacked option only for bar plots - send special token
        if viz_type in [VizType.bar]:
            opts.append({"label": "ALL - stacked", "value": "__group_stacked__"})
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
        Output("df-parquet", "data"),
        Output("df-csv", "data"),
        Input("generate-btn", "n_clicks"),
        Input("upgrade-inclusion", "value"),
        Input("vacancy-inclusion", "value"),
        Input("comparison-type", "value"),
        Input("value-type", "value"),
        Input("viz-type", "value"),
        Input("group-by", "value"),
        Input("quantity-group", "value"),
        Input("quantity", "value"),
        Input("fig-width", "value"),
        Input("fig-height", "value"),
        Input("legend-show", "value"),
        Input("legend-position", "value"),
        Input("dynamic-toggle", "value"),  # NE dynamic on/off
        Input("run-folder", "value"),  # NEW - selected run folder
    )
    def _generate_figure(
        _: int | None,
        upgrade_incl: str,
        vacancy_incl: str,
        comp_type: str,
        value_type: str,
        viz_type_val: str,
        group_by_val: str,
        qgroup_name: str,
        quantity_val: str,
        fig_w: int,
        fig_h: int,
        legend_show: list[str],
        legend_pos: str,
        dynamic_mode: bool,  # receives value from dynamic-toggle
        run_folder_val: str,  # receives selected run folder
    ):
        # if not n_clicks:
        #     return go.Figure(), dash.no_update, dash.no_update

        # Build the PlotSpec from current UI selections
        plot_spec = _build_plot_spec(
            upgrade_incl,
            vacancy_incl,
            comp_type,
            value_type,
            viz_type_val,
            group_by_val,
            qgroup_name,
            quantity_val,
        )
        logger.info(f"Generating figure for plot spec: {plot_spec}")
        try:
            df, fig = _prepare_df_fig(plot_spec, fig_w, fig_h, legend_show, legend_pos, dynamic_mode, run_folder_val)
        except Exception:  # noqa: BLE001 catch blind exception
            error = f"Failed to generate figure for plot spec: {plot_spec}. Error: {traceback.format_exc()}"
            logger.error(error)
            df, fig = _get_dummy_df_fig(error)

        csv_str = df.write_csv(file=None)
        buf = io.BytesIO()
        df.write_parquet(buf)
        parquet_b64 = base64.b64encode(buf.getvalue()).decode("ascii")
        return fig, parquet_b64, csv_str

    # ----------------------------------------------------------------------------
    #   CALLBACK - dynamically restrict *Value type* options based on comparison-type
    # ----------------------------------------------------------------------------
    @app.callback(
        Output("value-type", "options"),
        Output("value-type", "value"),
        Input("comparison-type", "value"),
        State("value-type", "value"),
    )
    def _update_value_type_dd(comp_type_val: str, current_val: str):
        """When *percent_savings* is selected allow only *average* value-type."""
        if comp_type_val == ComparisonTypes.percent_savings.value:
            opts = [{"label": ValueTypes.average.value, "value": ValueTypes.average.value}]
            return opts, ValueTypes.average.value

        # All value-types are available for other comparison types
        all_opts = [{"label": vt.value, "value": vt.value} for vt in workflow.value_types]
        new_val = current_val if current_val in {o["value"] for o in all_opts} else all_opts[0]["value"]
        return all_opts, new_val

    # ----------------------------------------------------------------------------
    #   CALLBACK - toggle value-type column visibility
    # ----------------------------------------------------------------------------
    @app.callback(
        Output("value-type-col", "style"),
        Input("viz-type", "value"),
    )
    def _toggle_value_type_visibility(viz_type_val: str):
        """Show *Value type* only for bar plots."""
        if VizType(viz_type_val) in [VizType.box, VizType.hist]:
            return {"display": "none"}
        return {}

    # ----------------------------------------------------------------------------
    #   CALLBACK - update Group By dropdown when run folder changes
    # ----------------------------------------------------------------------------
    @app.callback(
        Output("group-by", "options"),
        Output("group-by", "value"),
        Input("run-folder", "value"),
        State("group-by", "value"),
    )
    def _update_group_by_options(run_folder: str, current_val: str | None):  # type: ignore[override]
        """Refresh the Group By dropdown to reflect the selected run's workflow configuration."""

        orchestrator = get_orchestrator_for_run(run_folder)
        if orchestrator is None:
            raise PreventUpdate

        group_by_list = orchestrator.workflow.group_by
        options = {"__none__": "None", **{col: col for col in group_by_list}}

        # Preserve the currently selected value if still valid, else default to "None"
        value = current_val if current_val in options else "__none__"
        logger.info(f"Updating group by options: {options}")
        return options, value

    # ----------------------------------------------------------------------------
    #   CALLBACKS - DOWNLOAD DATA & FIGURE
    # ----------------------------------------------------------------------------
    def _get_dummy_df_fig(error_msg: str):
        fig = go.Figure()
        # Wrap the error message so it does not overflow the figure.  ``textwrap.fill``
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
        upgrade_incl: str,
        vacancy_incl: str,
        comp_type: str,
        value_type: str,
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

        # Force value-type to *average* when comparison-type is percent_savings
        if ComparisonTypes(comp_type) == ComparisonTypes.percent_savings:
            vtype_enum = ValueTypes.average
        else:
            vtype_enum = ValueTypes(value_type)

        return PlotSpec(
            upgrade_inclusion=UpgradeInclusion(upgrade_incl),
            vacancy_inclusion=VacancyInclusion(vacancy_incl),
            comparison_type=ComparisonTypes(comp_type),
            value_type=vtype_enum,
            visualization_type=viz_type,
            group_by=group_by,
            quantity=quantity,
            quantity_group_name=qgroup_name,
        )

    def _prepare_df_fig(
        spec: PlotSpec,
        fig_w: int,
        fig_h: int,
        legend_show: list[str],
        legend_pos: str,
        dynamic_mode: bool,
        run_folder_val: str,
    ):
        """Return dataframe and fully styled figure for given PlotSpec and layout inputs."""
        df = pl.DataFrame()
        fig = go.Figure()
        if not run_folder_val:
            raise PreventUpdate
        orchestrator = get_orchestrator_for_run(run_folder_val)
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
                return df, fig
            df = orchestrator.processor.prepare_data_for_plot(spec)
            plotter = PlotOrchestrator.get_plotter(spec.visualization_type)
            fig = plotter.create_plot(df, spec)

        # styling tweaks similar to original implementation
        fig.layout.title.subtitle.text = ""
        if not fig.layout.title.text:
            fig.layout.title.text = " "

        show_legend = "show" in legend_show
        legend_cfg: dict[str, Any] = {}
        if legend_pos == "right":
            legend_cfg = {"orientation": "v", "x": 1.02, "y": 1, "xanchor": "left", "yanchor": "top"}
        elif legend_pos == "bottom":
            legend_cfg = {"orientation": "h", "x": 0, "y": -0.2, "xanchor": "left", "yanchor": "top"}
        elif legend_pos == "tr":
            legend_cfg = {"x": 1, "y": 1, "xanchor": "right", "yanchor": "top"}
        elif legend_pos == "br":
            legend_cfg = {"x": 1, "y": 0, "xanchor": "right", "yanchor": "bottom"}
        elif legend_pos == "tl":
            legend_cfg = {"x": 0, "y": 1, "xanchor": "left", "yanchor": "top"}
        elif legend_pos == "bl":
            legend_cfg = {"x": 0, "y": 0, "xanchor": "left", "yanchor": "bottom"}

        fig.update_layout(width=fig_w, height=fig_h, showlegend=show_legend, legend=legend_cfg)
        path_seg, name = spec.get_path_and_name()
        if orchestrator is not None:
            orchestrator.out_mgr.save_plot(fig, path_seg, df, name)
        return df, fig

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


@flow(log_prints=True)
def run_dashboard(port: int = 8051):
    logger = get_run_logger()
    try:
        app = get_app(logger)
        app.run(debug=False, port=port, host="0.0.0.0")  # noqa: S104
    except Exception:  # noqa: BLE001 catch blind exception
        logger.error(f"Failed to run dashboard: {traceback.format_exc()}")


if __name__ == "__main__":
    run_dashboard(port=8053)
