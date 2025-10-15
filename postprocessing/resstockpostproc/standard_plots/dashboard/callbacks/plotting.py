from __future__ import annotations

import base64
import io
import logging
import time
import traceback
from pathlib import Path
from typing import Any

import dash
import plotly.graph_objects as go  # type: ignore
import plotly.io as pio  # type: ignore
import polars as pl  # type: ignore
from dash import dcc
from dash.dependencies import Input, Output, State
from dash.exceptions import PreventUpdate
from plotly.graph_objects import Figure

from resstockpostproc.standard_plots.schema.plot_spec import AggregationType, PlotSpec, QuantityType, VizType

from ..run_context import RunContext
from ..services.plot_helpers import apply_facet_orientation, build_error_dataframe_and_figure, build_plot_spec

logger = logging.getLogger(__name__)


def register_plotting_callbacks(app, ctx: RunContext) -> None:
    quantity_groups = ctx.quantity_groups
    workflow = ctx.workflow

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

        qg = quantity_groups[qgroup_name]
        viz_type = VizType(viz_type_val)

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
        Input("choropleth-labels", "value"),
        Input("choropleth-boundaries", "value"),
        Input("facet-vertical", "value"),
        Input("facet-wrap-width", "value"),
        Input("dynamic-toggle", "value"),
        Input("run-folder", "value"),
        Input("selected-upgrades", "value"),
    )
    def _generate_figure(  # noqa: PLR0913
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
        choropleth_labels: list[str],
        choropleth_boundaries: list[str],
        facet_orientation: list[str],
        wrap_width: int,
        dynamic_mode: bool,
        run_folder_val: str,
        selected_upgrades: list[int],
    ):
        plot_spec = build_plot_spec(
            ctx,
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
            return dash.no_update, dash.no_update, dash.no_update, dash.no_update, True, warning

        logger.info("Generating figure for plot spec: %s", plot_spec)
        try:
            df, fig, cached = _prepare_df_fig(
                plot_spec=plot_spec,
                fig_w=fig_w,
                fig_h=fig_h,
                legend_show=legend_show,
                legend_pos=legend_pos,
                facet_orientation=facet_orientation,
                wrap_width=wrap_width,
                dynamic_mode=dynamic_mode,
                run_folder_val=run_folder_val,
                selected_upgrades=selected_upgrades,
                choropleth_labels=choropleth_labels,
                choropleth_boundaries=choropleth_boundaries,
            )
        except Exception:
            error = f"Failed to generate figure for plot spec: {plot_spec}. Error: {traceback.format_exc()}"
            logger.error(error)
            df, fig = build_error_dataframe_and_figure(error)
            cached = False

        df = df.drop([col for col in df.columns if df[col].dtype == pl.List])
        csv_str = df.write_csv(file=None)
        fig.update_layout(width=fig_w, height=fig_h)
        buffer = io.BytesIO()
        df.write_parquet(buffer)
        parquet_b64 = base64.b64encode(buffer.getvalue()).decode("ascii")

        cache_text = "(loaded from cache)" if cached else "(generated dynamically)"
        return fig, cache_text, parquet_b64, csv_str, False, dash.no_update

    def _prepare_df_fig(
        plot_spec: PlotSpec,
        fig_w: int,
        fig_h: int,
        legend_show: list[str],
        legend_pos: str,
        facet_orientation: list[str],
        wrap_width: int,
        dynamic_mode: bool,
        run_folder_val: str,
        selected_upgrades: list[int] | None,
        choropleth_labels: list[str],
        choropleth_boundaries: list[str],
    ) -> tuple[pl.DataFrame, go.Figure, bool]:
        if not run_folder_val:
            raise PreventUpdate

        orchestrator = ctx.get_orchestrator(run_folder_val)
        loaded_from_file = False

        if orchestrator is not None and selected_upgrades is not None:
            if sorted(selected_upgrades) != sorted(orchestrator.workflow.upgrades):
                dynamic_mode = True
            else:
                selected_upgrades = None

        df = pl.DataFrame()
        fig = go.Figure()

        if not dynamic_mode:
            path_seg, name = plot_spec.get_path_and_name()
            base_dir = Path(workflow.output_dir).expanduser().resolve() / "plots" / str(run_folder_val)
            fig_path = base_dir / path_seg / "figure_json" / f"{name}.json"
            parquet_path = base_dir / path_seg / "data" / f"{name}.parquet"
            if fig_path.exists() and parquet_path.exists():
                try:
                    fig_dict = pio.read_json(str(fig_path))
                    fig = go.Figure(fig_dict)
                    df = pl.read_parquet(str(parquet_path), glob=False)
                    logger.info("Loaded plot from %s", fig_path)
                    loaded_from_file = True
                except Exception:
                    logger.warning(
                        "Failed to load data/figure from %s or %s due to error:\n%s\nGenerating on the fly.",
                        fig_path,
                        parquet_path,
                        traceback.format_exc(),
                    )
                    dynamic_mode = True
            else:
                logger.warning("Missing %s or %s. Generating on the fly.", fig_path, parquet_path)
                dynamic_mode = True

        if dynamic_mode:
            if orchestrator is None:
                warning = f"{run_folder_val} folder does not have workflow_snapshot.json.\nCannot dynamically generate plots."
                user_warning = (
                    "This old run cannot be viewed in the new dashboard\nPlease view it in the old dashboard or re-run the flow."
                )
                logger.warning(warning)
                df, fig = build_error_dataframe_and_figure(user_warning)
                return df, fig, False
            start_time = time.time()
            print("Preparing data for plot...")
            df = orchestrator.processor.prepare_data_for_plot(plot_spec, selected_upgrades=selected_upgrades)
            print(f"Data prepared in {time.time() - start_time:.1f} seconds. Generating data ...")
            plotter = orchestrator.get_plotter(plot_spec.visualization_type)
            start_time = time.time()
            orchestrator.theme.update_upgrade_palette(
                tuple(selected_upgrades) if selected_upgrades is not None else None
            )
            show_labels = "labels" in (choropleth_labels or [])
            show_boundaries = "boundaries" in (choropleth_boundaries or [])
            if plot_spec.visualization_type == VizType.choropleth:
                fig = plotter.create_plot(
                    df,
                    plot_spec,
                    show_labels=show_labels,
                    show_boundaries=show_boundaries,
                )
            else:
                fig = plotter.create_plot(df, plot_spec)
            print(f"Figure generated in {time.time() - start_time:.1f} seconds.")

        fig.layout.title.subtitle.text = ""
        if not fig.layout.title.text:
            fig.layout.title.text = " "

        show_legend = "show" in legend_show
        legend_cfg: dict[str, Any] = _build_legend_config(legend_pos)

        vertical = bool(facet_orientation and "vertical" in facet_orientation)
        wrap_val = wrap_width if wrap_width and wrap_width > 0 else None
        apply_facet_orientation(fig, vertical=vertical, wrap_width=wrap_val)

        fig.update_layout(width=fig_w, height=fig_h, showlegend=show_legend, legend=legend_cfg)
        return df, fig, loaded_from_file

    def _build_legend_config(position: str) -> dict[str, Any]:
        if position == "right":
            return {"orientation": "v", "x": 1.12, "y": 1, "xanchor": "left", "yanchor": "top"}
        if position == "bottom":
            return {"orientation": "h", "x": 0, "y": -0.2, "xanchor": "left", "yanchor": "top"}
        if position == "tr":
            return {"x": 1.12, "y": 1, "xanchor": "right", "yanchor": "top"}
        if position == "br":
            return {"x": 1.12, "y": 0, "xanchor": "right", "yanchor": "bottom"}
        if position == "tl":
            return {"x": 0, "y": 1, "xanchor": "left", "yanchor": "top"}
        if position == "bl":
            return {"x": 0, "y": 0, "xanchor": "left", "yanchor": "bottom"}
        return {}

    @app.callback(
        Output("plot-graph", "config"),
        Input("fig-editable", "value"),
    )
    def _update_graph_config(editable_vals: list[str]):
        base_cfg = {
            "autosizable": True,
            "responsive": True,
            "displaylogo": False,
            "modeBarButtons": [
                ["toImage"],
                ["zoom2d", "zoomIn2d", "zoomOut2d", "autoScale2d", "resetScale2d"],
            ],
            "toImageButtonOptions": {"format": "svg"},
        }
        if "editable" in editable_vals:
            base_cfg["editable"] = True
        return base_cfg

    @app.callback(
        Output("download-pdf", "data"),
        Input("btn-download-pdf", "n_clicks"),
        State("plot-graph", "figure"),
        prevent_initial_call=True,
    )
    def _download_pdf(_: int, fig_dict: dict[str, Any]):
        fig_obj = Figure(fig_dict)
        pdf_bytes = fig_obj.to_image(format="pdf")
        return dcc.send_bytes(pdf_bytes, "resstock_plot.pdf")

    app.clientside_callback(
        """
        function(n_clicks, csvStr) {
            if (!n_clicks || !csvStr) { return window.dash_clientside.no_update; }
            const blob = new Blob([csvStr], {type: 'text/csv'});
            const url = URL.createObjectURL(blob);
            const anchor = document.createElement('a');
            anchor.href = url;
            anchor.download = 'resstock_data.csv';
            document.body.appendChild(anchor);
            anchor.click();
            setTimeout(function(){ URL.revokeObjectURL(url); anchor.remove(); }, 0);
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
            const anchor = document.createElement('a');
            anchor.href = url;
            anchor.download = 'resstock_data.parquet';
            document.body.appendChild(anchor);
            anchor.click();
            setTimeout(function(){ URL.revokeObjectURL(url); anchor.remove(); }, 0);
            return '';
        }
        """,
        Output("download-dummy", "children"),
        Input("btn-download-parquet", "n_clicks"),
        State("df-parquet", "data"),
        prevent_initial_call=True,
    )
