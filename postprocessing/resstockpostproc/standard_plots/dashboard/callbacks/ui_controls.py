from __future__ import annotations

from typing import Any
from dash.dependencies import Input, Output, State
from dash.exceptions import PreventUpdate
import dash
from resstockpostproc.standard_plots.schema.plot_spec import AggregationType, PlotSpec, QuantityType, VizType

from ..run_context import RunContext
from ..layout import _get_default_quantity_group
import logging
import polars as pl

logger = logging.getLogger(__name__)

def register_ui_control_callbacks(app, ctx: RunContext) -> None:
    quantity_groups = list(ctx.quantity_groups.keys())

    @app.callback(
        Output("quantity-type", "value"),
        Input("building-inclusion", "value"),
        State("quantity-type", "value"),
        prevent_initial_call=True,
    )
    def _update_quantity_type_dd(bldg_inclusion, current_value: str | None):
        # dummy callback to join trigger dependencies from building-inclusion
        # to quantity-type so that rest of the chain works correctly
        return current_value

    @app.callback(
        Output("aggregation-type", "options"),
        Output("aggregation-type", "value"),
        Input("quantity-type", "value"),
        State("aggregation-type", "value"),
        prevent_initial_call=True,
    )
    def _update_aggregation_type_dd(quantity_type_val: str, current_val: str):
        try:
            qtype = QuantityType(quantity_type_val)
        except ValueError:
            raise PreventUpdate

        allowed = PlotSpec.get_valid_aggregation_types(qtype)
        options = [{"label": agg_type.name, "value": agg_type.value} for agg_type in allowed]
        valid_values = {opt["value"] for opt in options}
        new_val = current_val if current_val in valid_values else options[0]["value"]
        return options, new_val

    @app.callback(
        Output("quantity-group", "disabled"),
        Output("quantity", "disabled"),
        Input("quantity-type", "value"),
        prevent_initial_call=True,
    )
    def _toggle_quantity_controls(quantity_type_val: str):
        try:
            qtype = QuantityType(quantity_type_val)
        except ValueError:
            raise PreventUpdate
        disabled = qtype == QuantityType.model_count
        return disabled, disabled

    @app.callback(
        Output("viz-type", "options"),
        Output("viz-type", "value"),
        Input("aggregation-type", "value"),
        State("quantity-type", "value"),
        State("viz-type", "value"),
        prevent_initial_call=True,
    )
    def _update_viz_type_dd(aggregation_type_val: str, quantity_type_val: str, current_val: str):
        try:
            agg_type = AggregationType(aggregation_type_val)
        except ValueError:
            raise PreventUpdate

        try:
            qtype = QuantityType(quantity_type_val)
        except ValueError:
            raise PreventUpdate

        valid_viz_types = PlotSpec.get_valid_visualization_types(qtype, agg_type)
        options = [{"label": vt.name, "value": vt.value} for vt in valid_viz_types]
        valid_values = {opt["value"] for opt in options}
        new_val = current_val if current_val in valid_values else options[0]["value"]
        return options, new_val

    @app.callback(
        Output("group-by", "options"),
        Output("group-by", "value"),
        Input('viz-type', 'value'),
        State("run-folder", "value"),
        State("group-by", "value"),
        prevent_initial_call=True,
    )
    def _update_group_by_options(viz_type_val: str,
                                 run_folder: str, current_val: str | None):
        if viz_type_val == "choropleth":
            valid_options = ['in.state', 'in.county']
            new_val = current_val if current_val in valid_options else valid_options[0]
            return valid_options, new_val

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

        # Prefer the dropdown's current value if valid; otherwise try the
        # persisted store; otherwise fall back to "__none__".
        if current_val in valid_values:
            new_val = current_val
        else:
            new_val = "__none__"

        logger.info("Updating group by options: %s", [option["label"] for option in options])
        return options, new_val

    @app.callback(
        Output("quantity-group", "options"),
        Output("quantity-group", "value"),
        Input("group-by", "value"),  # needed to chain the dependency
        State("quantity-type", "value"),
        State("quantity-group", "value"),
        State("run-folder", "value"),
        State("selected-upgrades", "value"),
        prevent_initial_call=True,
    )
    def _update_quantity_group_dd(group_by_val: str, quantity_type_val: str, current_val: str, run_folder_val: str, selected_upgrades: list[int]):
        print(f"update quantity group triggered by: {dash.callback_context.triggered}")
        qtype = QuantityType(quantity_type_val)
        if qtype == QuantityType.prevalence:
            upgrade = sorted(selected_upgrades)[-1] if selected_upgrades else 0
            categorical_cols = ctx.list_categorical_quantities(run_folder_val, upgrade)
            if not categorical_cols:
                return [], None
            options = [{"label": col, "value": col} for col in categorical_cols]
            valid_values = {opt["value"] for opt in options}
            default_value = current_val if current_val in valid_values else options[0]["value"]
            return options, default_value

        default_value = current_val if current_val in quantity_groups else _get_default_quantity_group(quantity_groups)
        return quantity_groups, default_value

    @app.callback(
        Output("quantity", "options"),
        Output("quantity", "value"),
        Input("quantity-group", "value"),
        State("viz-type", "value"),
        State("group-by", "value"),
        State("quantity-type", "value"),
        State("run-folder", "value"),
        State("selected-upgrades", "value"),
        State("quantity", "value"),
        prevent_initial_call=True,
    )
    def _update_quantity_dd(
        qgroup_name: str,
        viz_type_val: str,
        group_by_val: str,
        quantity_type_val: str,
        run_folder_val: str,
        selected_upgrades: list[int],
        current_val: str | None,
    ):
        if not qgroup_name:
            raise PreventUpdate
        print(f"update quantity trigged by: {dash.callback_context.triggered}")
        qtype = QuantityType(quantity_type_val)
        viz_type = VizType(viz_type_val)
        if qtype == QuantityType.prevalence:
            upgrade = sorted(selected_upgrades)[-1] if selected_upgrades else 0
            categories = ctx.list_quantity_categories(run_folder_val, upgrade, qgroup_name)
            if not categories:
                return [], None
            options = [{"label": col, "value": col} for col in categories]
            valid_values = {opt["value"] for opt in options}
            default_value = current_val if current_val in categories else categories[0]
            options.append({"label": "ALL - stacked", "value": "__group_stacked__"})
            return options, default_value

        qg = ctx.quantity_groups[qgroup_name]

        options: list[dict[str, Any]] = []
        options.extend({"label": c, "value": c} for c in qg.constituents)
        if qg.sum:
            options.append({"label": qg.sum, "value": qg.sum})

        if viz_type in [VizType.bar] or (viz_type == VizType.box and group_by_val in (None, "__none__")):
            options.append({"label": "ALL - stacked", "value": "__group_stacked__"})

        if viz_type in [VizType.heatmap]:
            options = [{"label": "ALL - stacked", "value": "__group_stacked__"}]

        valid_values = {opt["value"] for opt in options}
        default_value = current_val if current_val in valid_values else options[0]["value"]
        return options, default_value