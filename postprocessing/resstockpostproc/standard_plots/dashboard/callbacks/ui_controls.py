from __future__ import annotations

from typing import Any
from dash.dependencies import Input, Output, State
from dash.exceptions import PreventUpdate

from resstockpostproc.standard_plots.schema.plot_spec import AggregationType, PlotSpec, QuantityType, VizType

from ..run_context import RunContext


def register_ui_control_callbacks(app, ctx: RunContext) -> None:
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

    @app.callback(
        Output("aggregation-type", "options"),
        Output("aggregation-type", "value"),
        Input("quantity-type", "value"),
        State("aggregation-type", "value"),
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
        Output("viz-type", "options"),
        Output("viz-type", "value"),
        Input("aggregation-type", "value"),
        Input("quantity-type", "value"),
        State("viz-type", "value"),
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
        Output("choropleth-labels-container", "style"),
        Input("viz-type", "value"),
    )
    def _toggle_choropleth_label_toggle(viz_type_val: str):
        try:
            viz = VizType(viz_type_val)
        except ValueError:
            raise PreventUpdate
        return {} if viz == VizType.choropleth else {"display": "none"}


    @app.callback(
        Output("facet-title-orientation-div", "style"),
        Input("plot-graph", "figure"),
    )
    def _toggle_facet_toggle_visibility(fig_dict: dict[str, Any]):
        if not fig_dict:
            raise PreventUpdate
        layout = fig_dict.get("layout", {})
        has_facet = any(key.startswith("xaxis") and key != "xaxis" for key in layout)
        return {} if has_facet else {"display": "none"}

    @app.callback(
        Output("facet-wrap-width-div", "style"),
        Input("plot-graph", "figure"),
    )
    def _toggle_facet_wrap_width_visibility(fig_dict: dict[str, Any]):
        if not fig_dict:
            raise PreventUpdate
        layout = fig_dict.get("layout", {})
        has_facet = any(key.startswith("xaxis") and key != "xaxis" for key in layout)
        return {} if has_facet else {"display": "none"}

    @app.callback(
        Output("facet-adjustment-box", "style"),
        Input("plot-graph", "figure"),
    )
    def _toggle_facet_adjustment_visibility(fig_dict: dict[str, Any]):
        if not fig_dict:
            raise PreventUpdate
        layout = fig_dict.get("layout", {})
        has_facet = any(key.startswith("xaxis") and key != "xaxis" for key in layout)
        return {} if has_facet else {"display": "none"}
