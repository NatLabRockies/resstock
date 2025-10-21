"""
Orchestrator module for standard plots
--------------------------------------
Coordinates the generation of all plots based on the configuration
"""

import time
from itertools import product
from typing import Literal
from uuid import UUID


from prefect.artifacts import create_progress_artifact, update_progress_artifact
from prefect.runtime import flow_run

from resstockpostproc.standard_plots.bar_plotter import BarPlotter
from resstockpostproc.standard_plots.box_plotter import BoxPlotter
from resstockpostproc.standard_plots.choropleth_plotter import ChoroplethPlotter
from resstockpostproc.standard_plots.data_processor import prepare_data_for_plot
from resstockpostproc.standard_plots.heatmap_plotter import HeatmapPlotter
from resstockpostproc.standard_plots.histogram_plotter import HistogramPlotter
from resstockpostproc.standard_plots.input_manager import InputManager
from resstockpostproc.standard_plots.output_manager import OutputManager
from resstockpostproc.standard_plots.schema.plot_spec import PlotSpec, VizType
from resstockpostproc.standard_plots.schema.workflow_schema import QuantityGroup, WorkflowConfig
from resstockpostproc.standard_plots.theme import ThemeManager


class PlotOrchestrator:
    """
    Orchestrates the plot generation process
    """

    def __init__(
        self,
        config: str | dict | WorkflowConfig,
        output_types: list[Literal["svg", "html", "parquet", "json", "csv"]] = [],
        overwrite: bool = False,
    ):
        """
        Initialize the orchestrator

        Args:
            config: Path to the workflow configuration YAML file, or a dictionary containing the workflow configuration
            output_types: List of file types to save
        """
        if isinstance(config, str):
            self.workflow = WorkflowConfig.from_yaml(config)
        elif isinstance(config, dict):
            self.workflow = WorkflowConfig(**config)
        elif isinstance(config, WorkflowConfig):
            self.workflow = config
        else:
            raise ValueError(f"Unsupported type for config: {type(config)}")
        self.data_loading_time: float = 0
        self.data_preparing_time: float = 0
        self.figure_creation_time: float = 0
        self.saving_time: float = 0

        # Setup the data processor
        start_time = time.time()
        self.inp_mgr = InputManager(self.workflow)
        self.inp_mgr.download_data()
        self.combined_df = self.inp_mgr.load_data()
        self.data_loading_time = time.time() - start_time
        self.out_mgr = OutputManager(self.workflow, output_types=output_types, overwrite=overwrite)
        self.theme = ThemeManager(self.workflow)

        # Only create artifacts if we're running a flow
        if flow_run.id:
            self.progress_artifact_id: UUID = create_progress_artifact(  # type: ignore[assignment]
                progress=0,
                description="Percentage of plots generated",
            )

    def generate_all_plots(self, *, max_plots_to_gen: int | None = None) -> None:
        """Generate all plots declared in YAML using the new PlotDef contract."""

        # Get all configuration elements for iteration
        # Create all possible combinations of parameters
        upgrades = [None, *self.workflow.upgrades]
        all_combinations = list(
            product(
                self.workflow.quantity_types,
                self.workflow.building_inclusion,
                self.workflow.vacancy_inclusion,
                self.workflow.visualization_types,
                [None, *self.workflow.group_by],
                self.workflow.quantities,
                self.workflow.aggregation_types,
                upgrades,
            )
        )
        plots_to_gen: list[PlotSpec] = []
        for combination in all_combinations:
            quantity_type = combination[0]
            building_inclusion = combination[1]
            vacancy_inclusion = combination[2]
            visualization_type = combination[3]
            group_by = combination[4]
            quantity_group: QuantityGroup = combination[5].model_copy()
            aggregation_type = combination[6]
            upgrade = combination[7]

            # Usually, visualize each constituent quantity and the sum (if any) separately
            # Prepare a mutable list of quantities, starting with individual constituents and optional sum
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
                if not plot_spec.is_valid():
                    continue
                plots_to_gen.append(plot_spec)
        if max_plots_to_gen is None:
            total_plots = len(plots_to_gen)
            print(f"Generating all {total_plots} plots")
        else:
            total_plots = max_plots_to_gen
            print(f"Generating {total_plots} plots")
        for plots_generated, plot_spec in enumerate(plots_to_gen, 1):
            start_time = time.time()
            df = prepare_data_for_plot(self.combined_df, plot_spec)
            self.data_preparing_time += time.time() - start_time
            path_seg, name = plot_spec.get_path_and_name()
            plotter = self.get_plotter(plot_spec.visualization_type)
            start_time = time.time()
            try:
                fig = plotter.create_plot(df, plot_spec)
            except Exception as e:
                print(f"Error creating plot for {plot_spec}: {e}")
                raise
            self.figure_creation_time += time.time() - start_time
            start_time = time.time()
            self.out_mgr.save_plot(fig, path_seg, df, name)
            self.saving_time += time.time() - start_time
            print(f"{plots_generated:,}/{total_plots:,}: Saved plot for {path_seg}/{name}")
            if flow_run.id:
                update_progress_artifact(
                    artifact_id=self.progress_artifact_id,
                    description=f"Percentage of plots generated: {plots_generated:,}/{total_plots:,}",
                    progress=plots_generated / total_plots * 100,
                )
            if plots_generated >= total_plots:
                return

    def get_plotter(self, viz: VizType):
        """Return a new plotter instance for the given visualization type."""
        if viz == VizType.bar:
            return BarPlotter(theme=self.theme)
        if viz == VizType.box:
            return BoxPlotter(theme=self.theme)
        if viz == VizType.heatmap:
            return HeatmapPlotter(theme=self.theme)
        if viz == VizType.hist:
            return HistogramPlotter(theme=self.theme)
        if viz == VizType.choropleth:
            return ChoroplethPlotter(theme=self.theme)
        raise ValueError(f"Unsupported visualization type: {viz}")

    def print_time_spent(self) -> None:
        print(f"Time spent loading data: {self.data_loading_time:.2f} seconds")
        print(f"Time spent preparing data: {self.data_preparing_time:.2f} seconds")
        print(f"Time spent creating figures: {self.figure_creation_time:.2f} seconds")
        print(f"Time spent saving plots: {self.saving_time:.2f} seconds")
