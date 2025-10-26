"""
Functional orchestration utilities for generating standard plots.
"""

from __future__ import annotations

import time
from itertools import product
from pathlib import Path
from typing import Literal
from collections.abc import Sequence
from uuid import UUID

from prefect.artifacts import create_progress_artifact, update_progress_artifact
from prefect.runtime import flow_run

from resstockpostproc.upgrade_comparison.plotters import bar_plotter, box_plotter, choropleth_plotter, heatmap_plotter
from resstockpostproc.upgrade_comparison.plotters import (
    histogram_plotter,
)
from resstockpostproc.upgrade_comparison.data_processing.data_processor import prepare_data_for_plot
from resstockpostproc.upgrade_comparison.io_managers.input_manager import download_data, load_data
from resstockpostproc.upgrade_comparison.io_managers.output_manager import (
    get_plot_base_dir,
    save_plot,
    write_workflow_snapshot,
    remove_lock_files,
)
from resstockpostproc.upgrade_comparison.schema.plot_spec import PlotSpec, VizType
from resstockpostproc.upgrade_comparison.schema.workflow_schema import QuantityGroup, WorkflowConfig
from resstockpostproc.upgrade_comparison.utils import load_workflow_config

__all__ = [
    "generate_all_plots",
    "get_plotting_function",
]


def generate_all_plots(
    config: str | dict | WorkflowConfig,
    *,
    output_types: Sequence[Literal["svg", "html", "parquet", "json", "csv"]] = (),
    overwrite: bool = False,
    max_plots_to_gen: int | None = None,
    print_stats: bool = False,
) -> None:
    """Generate all plots defined by the supplied workflow configuration."""
    workflow = load_workflow_config(config)

    start_time = time.time()
    download_data(workflow)
    combined_df = load_data(workflow)
    data_loading_time = time.time() - start_time

    base_dir = get_plot_base_dir(workflow)
    base_dir.mkdir(parents=True, exist_ok=True)
    write_workflow_snapshot(workflow, base_dir)
    output_types_list = list(output_types) if output_types else None

    progress_artifact_id: UUID | None = None
    if flow_run.id:
        progress_artifact_id = create_progress_artifact(  # type: ignore[assignment]
            progress=0,
            description="Percentage of plots generated",
        )

    data_preparing_time = 0.0
    figure_creation_time = 0.0
    saving_time = 0.0

    plot_specs = list(_build_plot_specs(workflow))
    if max_plots_to_gen is None:
        total_plots = len(plot_specs)
        print(f"Generating all {total_plots} plots")
    else:
        total_plots = min(max_plots_to_gen, len(plot_specs))
        print(f"Generating {total_plots} plots")
        plot_specs = plot_specs[:total_plots]

    for plots_generated, plot_spec in enumerate(plot_specs, 1):
        path_seg, name = plot_spec.get_path_and_name()
        path_seg = Path("All combinations") / path_seg
        plotting_function = get_plotting_function(plot_spec.visualization_type)
        print(f"{plots_generated:,}/{total_plots:,}: Generating plot for {path_seg}/{name}")
        if progress_artifact_id:
            update_progress_artifact(
                artifact_id=progress_artifact_id,
                description=f"Percentage of plots generated: {plots_generated:,}/{total_plots:,}",
                progress=plots_generated / total_plots * 100,
            )

        start_time = time.time()
        try:
            df = prepare_data_for_plot(combined_df, plot_spec)
        except Exception as exc:
            print(f"Error preparing data for plot {plot_spec}: {exc}")
            raise
        data_preparing_time += time.time() - start_time
        if len(df) == 0:
            print(f"{plots_generated:,}/{total_plots:,}: No data for plot {plot_spec}, skipping")
            continue

        start_time = time.time()
        try:
            fig = plotting_function(df, plot_spec)
        except Exception as exc:
            print(f"Error creating plot for {plot_spec}: {exc}")
            raise
        figure_creation_time += time.time() - start_time

        start_time = time.time()
        save_plot(
            base_dir=base_dir,
            path_seg=path_seg,
            file_name=name,
            fig=fig,
            df=df,
            output_types=output_types_list,
            overwrite=overwrite,
        )
        saving_time += time.time() - start_time

    if print_stats:
        _print_time_spent(
            data_loading_time=data_loading_time,
            data_preparing_time=data_preparing_time,
            figure_creation_time=figure_creation_time,
            saving_time=saving_time,
        )

    remove_lock_files(workflow.output_dir)


def get_plotting_function(viz: VizType):
    """Return a plotting function for the given visualization type."""
    if viz == VizType.bar:
        return bar_plotter.create_plot
    if viz == VizType.box:
        return box_plotter.create_plot
    if viz == VizType.heatmap:
        return heatmap_plotter.create_plot
    if viz == VizType.hist:
        return histogram_plotter.create_plot
    if viz == VizType.choropleth:
        return choropleth_plotter.create_plot
    raise ValueError(f"Unsupported visualization type: {viz}")


def _print_time_spent(
    *,
    data_loading_time: float,
    data_preparing_time: float,
    figure_creation_time: float,
    saving_time: float,
) -> None:
    """Print timing information for a generation run."""
    print(f"Time spent loading data: {data_loading_time:.2f} seconds")
    print(f"Time spent preparing data: {data_preparing_time:.2f} seconds")
    print(f"Time spent creating figures: {figure_creation_time:.2f} seconds")
    print(f"Time spent saving plots: {saving_time:.2f} seconds")


def _build_plot_specs(workflow: WorkflowConfig) -> Sequence[PlotSpec]:
    upgrades = [None, *workflow.upgrades]
    specs: list[PlotSpec] = []
    for combination in product(
        workflow.quantity_types,
        workflow.building_inclusion,
        workflow.vacancy_inclusion,
        workflow.visualization_types,
        [None, *workflow.group_by],
        workflow.aggregation_types,
        upgrades,
    ):
        quantity_type = combination[0]
        building_inclusion = combination[1]
        vacancy_inclusion = combination[2]
        visualization_type = combination[3]
        group_by = combination[4]
        aggregation_type = combination[5]
        upgrade = combination[6]
        workflow_quantities = (
            workflow.categorical_quantities if quantity_type == "prevalence" else workflow.numerical_quantities
        )
        for quantity_group in workflow_quantities:
            quantities: list[str | QuantityGroup] = []
            quantities.extend(quantity_group.constituents)
            if quantity_group.sum:
                quantities.append(quantity_group.sum)

            for quantity in [*quantities, quantity_group]:
                plot_spec = PlotSpec(
                    quantity_type=quantity_type,
                    building_inclusion=building_inclusion,
                    vacancy_inclusion=vacancy_inclusion,
                    visualization_type=visualization_type,
                    aggregation_type=aggregation_type,
                    group_by=group_by,
                    quantity=quantity,
                    quantity_group_name=quantity_group.name,
                    upgrade=upgrade,
                )
                if plot_spec.is_valid():
                    specs.append(plot_spec)
    return specs
