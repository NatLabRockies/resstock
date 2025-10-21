from __future__ import annotations

import textwrap
from typing import Any

import plotly.graph_objects as go  # type: ignore
import polars as pl  # type: ignore
from plotly.graph_objects import Figure

from resstockpostproc.standard_plots.data_processor import prepare_data_for_plot
from resstockpostproc.standard_plots.schema.plot_spec import (
    AggregationType,
    BuildingInclusion,
    PlotSpec,
    QuantityType,
    VacancyInclusion,
    VizType,
)
from resstockpostproc.standard_plots.schema.workflow_schema import QuantityGroup

from ..run_context import RunContext


def get_inclusion(building_inclusion_str: str) -> BuildingInclusion:
    """Convert building inclusion string from UI to enum."""
    if building_inclusion_str == "__all__":
        return BuildingInclusion.all
    elif building_inclusion_str == "applied_all":
        return BuildingInclusion.applied_only
    elif building_inclusion_str.startswith("applied_"):
        return BuildingInclusion.applied_only
    else:
        return BuildingInclusion.all

def get_upgrade_number(building_inclusion_str: str) -> int | None:
    """Extract upgrade number from building inclusion string from UI."""
    if building_inclusion_str == "__all__":
        return None
    elif building_inclusion_str == "applied_all":
        return None
    elif building_inclusion_str.startswith("applied_"):
        return int(building_inclusion_str.split("_")[1])
    else:
        return int(building_inclusion_str)

def build_plot_spec(
    ctx: RunContext,
    run_folder: str,
    building_incl: str,
    vacancy_incl: str,
    quantity_type: str,
    aggregation_type: str,
    viz_type_val: str,
    group_by_val: str,
    qgroup_name: str,
    quantity_val: str,
) -> PlotSpec:
    """Construct a PlotSpec instance from UI selections."""

    viz_type = VizType(viz_type_val)
    qtype_enum = QuantityType(quantity_type)
    group_by = group_by_val if group_by_val != "__none__" else None

    quantity_group_name = qgroup_name
    upg_incl_enum = get_inclusion(building_incl)
    upgrade_num = get_upgrade_number(building_incl)
    
    quantity: str | QuantityGroup
    if quantity_val == "__group_stacked__":
        if quantity_type == QuantityType.prevalence:
            assert upgrade_num is not None, "Upgrade number must be specified for prevalence plots"
            all_categories = ctx.list_quantity_categories(run_folder, upgrade_num, qgroup_name)
            quantity = QuantityGroup(
                name=qgroup_name,
                constituents=tuple(all_categories),
                sum=None,
            )
        else:
            quantity = ctx.quantity_groups[qgroup_name]
    else:
        quantity = quantity_val

    return PlotSpec(
        building_inclusion=upg_incl_enum,
        vacancy_inclusion=VacancyInclusion(vacancy_incl),
        quantity_type=qtype_enum,
        aggregation_type=AggregationType(aggregation_type),
        visualization_type=viz_type,
        group_by=group_by,
        quantity=quantity,
        quantity_group_name=quantity_group_name,
        upgrade=upgrade_num,
    )


def prepare_plot_dataframe(
    ctx: RunContext,
    run_folder: str,
    plot_spec: PlotSpec,
    *,
    selected_upgrades: list[int] | None = None,
) -> pl.DataFrame:
    """Return processed plot data for the dashboard."""
    orchestrator = ctx.get_orchestrator(run_folder)
    if orchestrator is None:
        raise ValueError(f"Run folder {run_folder} does not have a workflow snapshot.")

    load_selection: list[int] | None
    if selected_upgrades:
        load_selection = sorted({0, *selected_upgrades})
    else:
        load_selection = None

    if load_selection is None and hasattr(orchestrator, "combined_df"):
        combined_df = orchestrator.combined_df
    else:
        combined_df = orchestrator.inp_mgr.load_data(load_selection)

    return prepare_data_for_plot(
        combined_df,
        plot_spec,
        selected_upgrades=selected_upgrades,
    )


def build_error_dataframe_and_figure(error_message: str) -> tuple[pl.DataFrame, go.Figure]:
    """Return an empty dataframe and figure that displays the error message."""
    fig = go.Figure()
    wrapped_msg = textwrap.fill(error_message, width=200, break_long_words=False)
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


def apply_facet_orientation(fig: Figure, vertical: bool, wrap_width: int | None = None) -> None:
    """Rotate and wrap facet titles on the supplied figure."""
    if not fig.layout.annotations:
        return

    angle = -90 if vertical else 0
    for annotation in fig.layout.annotations:
        if annotation.name == "xtitle":
            continue
        if wrap_width and wrap_width > 0:
            wrapped = textwrap.fill(str(annotation.text).replace("<br>", " "), width=wrap_width, break_long_words=False)
            wrapped = wrapped.replace("\n", "<br>")
            annotation.update(text=wrapped)
        annotation.update(textangle=angle)

    if vertical:
        longest = max(
            (max(len(part) for part in str(annotation.text).split("<br>")) for annotation in fig.layout.annotations),
            default=0,
        )
        extra_top = min(600, max(80, longest * 9))
        current_margin = fig.layout.margin.t if fig.layout.margin and fig.layout.margin.t is not None else 0
        if extra_top > current_margin:
            existing_margin: dict[str, Any] = fig.layout.margin.to_plotly_json() if fig.layout.margin else {}
            fig.update_layout(margin={**existing_margin, "t": extra_top})
