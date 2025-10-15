from __future__ import annotations

import logging
from typing import Any

import dash
import polars as pl  # type: ignore
from dash import dcc, html
from dash.dependencies import Input, Output, State
from dash.exceptions import PreventUpdate

from ..run_context import RunContext

logger = logging.getLogger(__name__)


def register_run_info_callbacks(app, ctx: RunContext) -> None:
    @app.callback(
        Output("run-info", "children"),
        Input("run-folder", "value"),
    )
    def _update_run_info(run_folder: str):
        snapshot: dict[str, Any] | None = ctx.load_snapshot(run_folder)
        if not snapshot:
            return html.Div("RUN INFO NOT AVAILABLE", className="text-center")

        orchestrator = ctx.get_orchestrator(run_folder)
        if orchestrator is None:
            return html.Div("Run folder does not have orchestrator. Cannot give run info.")

        baseline_df = orchestrator.processor.combined_df.filter(pl.col("upgrade") == 0)
        num_data_points = baseline_df.select(pl.len()).collect().item()
        upgrades = snapshot.get("upgrades", [])
        non_baseline_upgrades = [upgrade for upgrade in upgrades if upgrade != 0]

        upgrade_tokens: list[str] = []
        baseline_token = None
        if 0 in upgrades:
            baseline_token = f"{'0(Base)':<10}"

        for upgrade in non_baseline_upgrades:
            upgrade_df = orchestrator.processor.combined_df.filter(pl.col("upgrade") == upgrade)
            num_applicable = upgrade_df.filter(pl.col("applicability")).select(pl.len()).collect().item()
            token = f"{upgrade}({num_applicable / num_data_points * 100:.1f}%)"
            upgrade_tokens.append(f"{token:<10}")

        checklist_options = []
        if baseline_token is not None:
            checklist_options.append({"label": baseline_token, "value": 0, "disabled": True})
        checklist_options.extend(
            {"label": token, "value": upg} for token, upg in zip(upgrade_tokens, non_baseline_upgrades)
        )

        checklist = dcc.Checklist(
            id="selected-upgrades",
            options=checklist_options,
            value=[option["value"] for option in checklist_options],
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
                    [html.Span("S3: ", className="fw-bold"), html.Span(snapshot.get("s3_results_dir", "N/A"))],
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

    @app.callback(
        Output("group-by", "options"),
        Output("group-by", "value"),
        Input("run-folder", "value"),
        State("group-by", "value"),
        prevent_initial_call=True,
    )
    def _update_group_by_options(run_folder: str, current_val: str | None):
        orchestrator = ctx.get_orchestrator(run_folder)
        if orchestrator is None:
            raise PreventUpdate

        workflow_group_by: tuple[str, ...] = orchestrator.workflow.group_by

        small_chars: list[str] = []
        geo_columns: list[str] = []
        try:
            base_df: pl.LazyFrame = orchestrator.processor.combined_df.filter(pl.col("upgrade") == 0)
            schema_names = base_df.collect_schema().names()
            in_cols = [col for col in schema_names if col.startswith("in.")]
            if in_cols:
                unique_df = base_df.select([pl.col(col).n_unique().alias(col) for col in in_cols]).collect()
                unique_counts = dict(zip(in_cols, unique_df.row(0)))
                small_chars = sorted([col for col, count in unique_counts.items() if 1 < count <= 20])
            geo_columns = [col for col in ("in.state", "in.county") if col in schema_names]
        except Exception as exc:  # noqa: BLE001
            logger.warning("Failed to compute additional group-by characteristics: %s", exc)

        options: list[dict[str, Any]] = [
            {"label": "None", "value": "__none__"},
            {"label": "— Workflow group-by —", "value": "__sep_wf__", "disabled": True},
            *[{"label": col, "value": col} for col in workflow_group_by],
        ]

        if geo_columns:
            options.extend(
                [
                    {"label": "— Geography —", "value": "__sep_geo__", "disabled": True},
                    *[
                        {"label": col, "value": col}
                        for col in geo_columns
                        if col not in workflow_group_by
                    ],
                ]
            )

        if small_chars:
            options.extend(
                [
                    {"label": "— Additional characteristics —", "value": "__sep_extra__", "disabled": True},
                    *[{"label": col, "value": col} for col in small_chars if col not in workflow_group_by],
                ]
            )

        valid_values = {option["value"] for option in options if not option.get("disabled")}

        if current_val is None:
            new_val = dash.no_update
        elif current_val in valid_values:
            new_val = current_val
        else:
            new_val = "__none__"

        logger.info("Updating group by options: %s", [option["label"] for option in options])
        return options, new_val

    @app.callback(
        Output("building-inclusion", "options"),
        Output("building-inclusion", "value"),
        Input("run-folder", "value"),
        Input("selected-upgrades", "value"),
        State("building-inclusion", "value"),
    )
    def _update_upgrade_inclusion_dd(run_folder: str, selected_upgrades: list[int], current_val: str):
        orchestrator = ctx.get_orchestrator(run_folder)
        if orchestrator is None:
            raise PreventUpdate

        options: list[dict[str, Any]] = [
            {"label": "All", "value": "__all__"},
            {"label": "Applied in respective upgrades", "value": "applied_all"},
        ]
        options.extend(
            {"label": f"Applied in Upgrade {upgrade}", "value": f"applied_{upgrade}"}
            for upgrade in selected_upgrades
            if upgrade != 0
        )

        valid_values = {option["value"] for option in options}
        new_val = current_val if current_val in valid_values else "__all__"
        return options, new_val

    @app.callback(
        Output("run-folder", "options"),
        Output("run-folder", "value"),
        Input("url", "href"),
        State("run-folder", "value"),
        prevent_initial_call=True,
    )
    def _refresh_run_folders(_: str, current_val: str | None):
        folders = ctx.list_run_folders()
        new_val = current_val if current_val in folders else (folders[0] if folders else None)
        return folders, new_val
