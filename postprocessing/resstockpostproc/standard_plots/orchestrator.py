"""
Functional orchestration utilities for generating standard plots.
"""

from __future__ import annotations

import time
from itertools import product
from typing import Literal, Sequence
from uuid import UUID

from prefect.artifacts import create_progress_artifact, update_progress_artifact
from prefect.runtime import flow_run

from resstockpostproc.standard_plots.bar_plotter import BarPlotter
from resstockpostproc.standard_plots.box_plotter import BoxPlotter
from resstockpostproc.standard_plots.choropleth_plotter import ChoroplethPlotter
from resstockpostproc.standard_plots.data_processor import prepare_data_for_plot
from resstockpostproc.standard_plots.heatmap_plotter import HeatmapPlotter
from resstockpostproc.standard_plots.histogram_plotter import HistogramPlotter
from resstockpostproc.standard_plots.input_manager import download_data, load_data
from resstockpostproc.standard_plots.output_manager import OutputManager
from resstockpostproc.standard_plots.schema.plot_spec import PlotSpec, VizType
from resstockpostproc.standard_plots.schema.workflow_schema import QuantityGroup, WorkflowConfig

__all__ = [
    "generate_all_plots",
    "get_plotter",
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
    workflow = _coerce_workflow(config)

    start_time = time.time()
    download_data(workflow)
    combined_df = load_data(workflow)
    data_loading_time = time.time() - start_time

    out_mgr = OutputManager(workflow, output_types=list(output_types), overwrite=overwrite)

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
        start_time = time.time()
        df = prepare_data_for_plot(combined_df, plot_spec)
        data_preparing_time += time.time() - start_time

        path_seg, name = plot_spec.get_path_and_name()
        plotter = get_plotter(plot_spec.visualization_type)

        start_time = time.time()
        try:
            fig = plotter.create_plot(df, plot_spec)
        except Exception as exc:  # noqa: BLE001
            print(f"Error creating plot for {plot_spec}: {exc}")
            raise
        figure_creation_time += time.time() - start_time

        start_time = time.time()
        out_mgr.save_plot(fig, path_seg, df, name)
        saving_time += time.time() - start_time

        print(f"{plots_generated:,}/{total_plots:,}: Saved plot for {path_seg}/{name}")
        if progress_artifact_id:
            update_progress_artifact(
                artifact_id=progress_artifact_id,
                description=f"Percentage of plots generated: {plots_generated:,}/{total_plots:,}",
                progress=plots_generated / total_plots * 100,
            )

    if print_stats:
        _print_time_spent(
            data_loading_time=data_loading_time,
            data_preparing_time=data_preparing_time,
            figure_creation_time=figure_creation_time,
            saving_time=saving_time,
            output_manager=out_mgr,
        )


def get_plotter(viz: VizType):
    """Return a plotter instance for the given visualization type."""
    if viz == VizType.bar:
        return BarPlotter()
    if viz == VizType.box:
        return BoxPlotter()
    if viz == VizType.heatmap:
        return HeatmapPlotter()
    if viz == VizType.hist:
        return HistogramPlotter()
    if viz == VizType.choropleth:
        return ChoroplethPlotter()
    raise ValueError(f"Unsupported visualization type: {viz}")


def _print_time_spent(
    *,
    data_loading_time: float,
    data_preparing_time: float,
    figure_creation_time: float,
    saving_time: float,
    output_manager: OutputManager,
) -> None:
    """Print timing information for a generation run."""
    print(f"Time spent loading data: {data_loading_time:.2f} seconds")
    print(f"Time spent preparing data: {data_preparing_time:.2f} seconds")
    print(f"Time spent creating figures: {figure_creation_time:.2f} seconds")
    print(f"Time spent saving plots: {saving_time:.2f} seconds")
    output_manager.print_time_spent()


def _coerce_workflow(config: str | dict | WorkflowConfig) -> WorkflowConfig:
    if isinstance(config, WorkflowConfig):
        return config
    if isinstance(config, str):
        return WorkflowConfig.from_yaml(config)
    if isinstance(config, dict):
        return WorkflowConfig(**config)
    raise ValueError(f"Unsupported type for config: {type(config)}")


def _build_plot_specs(workflow: WorkflowConfig) -> Sequence[PlotSpec]:
    upgrades = [None, *workflow.upgrades]
    specs: list[PlotSpec] = []
    for combination in product(
        workflow.quantity_types,
        workflow.building_inclusion,
        workflow.vacancy_inclusion,
        workflow.visualization_types,
        [None, *workflow.group_by],
        workflow.quantities,
        workflow.aggregation_types,
        upgrades,
    ):
        quantity_type = combination[0]
        building_inclusion = combination[1]
        vacancy_inclusion = combination[2]
        visualization_type = combination[3]
        group_by = combination[4]
        quantity_group: QuantityGroup = combination[5].model_copy()
        aggregation_type = combination[6]
        upgrade = combination[7]

        quantities: list[str | QuantityGroup] = []
        quantities.extend(quantity_group.constituents)
        if quantity_group.sum:
            quantities.append(quantity_group.sum)

        for quantity in quantities:
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
