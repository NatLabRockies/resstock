from __future__ import annotations

import logging
from typing import Any

import polars as pl  # type: ignore
from dash.dependencies import Input, Output, State
from dash.exceptions import PreventUpdate
import time
from ..run_context import RunContext
from resstockpostproc.standard_plots.input_manager import load_data
from resstockpostproc.standard_plots.schema.workflow_schema import QuantityType

logger = logging.getLogger(__name__)


def register_run_info_callbacks(app, ctx: RunContext) -> None:
    @app.callback(
        Output("run-info-message", "children"),
        Output("run-info-s3", "children"),
        Output("selected-upgrades", "options"),
        Output("selected-upgrades", "value"),
        Output("run-info-num-points", "children"),
        Input("run-folder", "value"),
        State("selected-upgrades", "value"),
        prevent_initial_call=True,
    )
    def _update_run_info(run_folder: str, current_selection: list[int] | None):
        current_selection = current_selection or []
        if not run_folder:
            return "", "—", [], [], "—"

        snapshot: dict[str, Any] | None = ctx.load_snapshot(run_folder)
        if not snapshot:
            return "RUN INFO NOT AVAILABLE", "—", [], [], "—"

        workflow_for_run = ctx.ensure_data_ready(run_folder)
        if workflow_for_run is None:
            return "Run folder does not have workflow snapshot. Cannot give run info.", "—", [], [], "—"

        baseline_df = load_data(workflow_for_run, selected_upgrades=[0])
        num_data_points = baseline_df.select(pl.len()).collect().item()
        upgrades = snapshot.get("upgrades", [])
        non_baseline_upgrades = [upgrade for upgrade in upgrades if upgrade != 0]

        upgrade_tokens: list[str] = []
        baseline_token = None
        if 0 in upgrades:
            baseline_token = f"{'0(Base)':<10}"
        start_time = time.time()
        for upgrade in non_baseline_upgrades:
            upgrade_df = load_data(workflow_for_run, selected_upgrades=[upgrade])
            num_applicable = upgrade_df.filter(pl.col("applicability")).select(pl.len()).collect().item()
            token = f"{upgrade}({num_applicable / num_data_points * 100:.1f}%)"
            upgrade_tokens.append(f"{token:<10}")
            print(f"Computed applicability for upgrade {upgrade} in {time.time() - start_time:.2f} seconds")
            start_time = time.time()

        checklist_options = []
        if baseline_token is not None:
            checklist_options.append({"label": baseline_token, "value": 0, "disabled": True})
        checklist_options.extend(
            {"label": token, "value": upg} for token, upg in zip(upgrade_tokens, non_baseline_upgrades)
        )

        selected_values = [option["value"] for option in checklist_options]
        valid_values = {option["value"] for option in checklist_options}
        persisted_selection = [val for val in current_selection if val in valid_values]
        if persisted_selection:
            selected_values = persisted_selection

        return (
            "",
            snapshot.get("s3_results_dir", "N/A"),
            checklist_options,
            selected_values,
            num_data_points,
        )

    @app.callback(
        Output("building-inclusion", "options"),
        Output("building-inclusion", "value"),
        State("run-folder", "value"),
        State("selected-upgrades", "value"),
        Input("quantity-type", "value"),
        State("building-inclusion", "value"),
        prevent_initial_call=True,
    )
    def _update_upgrade_inclusion_dd(run_folder: str, selected_upgrades: list[int],
                                     quantity_type_val: str, current_val: str):
        run_workflow = ctx.get_workflow(run_folder)
        if run_workflow is None:
            raise PreventUpdate
        quantity_type = QuantityType(quantity_type_val)
        selected_upgrades = sorted(selected_upgrades)
        options: list[dict[str, Any]] = []
        if quantity_type != QuantityType.prevalence:
            options = [
                {"label": "All", "value": "__all__"},
                {"label": "Applied in respective upgrades", "value": "applied_all"},
            ]

        options.extend(
            {"label": f"Upgrade {upgrade}" if upgrade != 0 else "Baseline", "value": str(upgrade)}
            for upgrade in selected_upgrades
        )
        options.extend(
            {"label": f"Applied in Upgrade {upgrade}", "value": f"applied_{upgrade}"}
            for upgrade in selected_upgrades
            if upgrade != 0
        )

        valid_values = {option["value"] for option in options}
        new_val = current_val if str(current_val) in valid_values else options[0]['value']
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
