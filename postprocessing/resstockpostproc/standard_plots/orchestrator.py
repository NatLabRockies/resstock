"""
Orchestrator module for standard plots
--------------------------------------
Coordinates the generation of all plots based on the configuration
"""

from itertools import product

from resstockpostproc.standard_plots.bar_plotter import BarPlotter
from resstockpostproc.standard_plots.box_plotter import BoxPlotter
from resstockpostproc.standard_plots.data_processor import DataProcessor
from resstockpostproc.standard_plots.output_manager import OutputManager
from resstockpostproc.standard_plots.schema.plot_spec import ComparisonTypes, PlotSpec, VizType
from resstockpostproc.standard_plots.schema.workflow_schema import QuantityGroup, WorkflowConfig


class PlotOrchestrator:
    """
    Orchestrates the plot generation process
    """

    def __init__(self, config_path: str, should_save_image: bool = False, should_save_data: bool = False):
        """
        Initialize the orchestrator

        Args:
            config_path: Path to the workflow configuration YAML file
            should_save_image: Whether to save the image of the plot
            should_save_data: Whether to save the data used to generate the plot
        """
        self.workflow = WorkflowConfig.from_yaml(config_path)

        # Setup the data processor
        self.processor = DataProcessor(self.workflow.annual_results_dir, self.workflow.upgrades)
        self.out_mgr = OutputManager(
            self.workflow.output_dir, should_save_image=should_save_image, should_save_data=should_save_data
        )

    def generate_all_plots(self, *, max_plots_to_gen: int | None = None) -> None:
        """Generate all plots declared in YAML using the new PlotDef contract."""

        # Get all configuration elements for iteration
        # Create all possible combinations of parameters
        all_combinations = list(
            product(
                self.workflow.comparison_types,
                self.workflow.upgrade_inclusion,
                self.workflow.vacancy_inclusion,
                self.workflow.visualization_types,
                [None, *self.workflow.group_by],
                self.workflow.quantities,
            )
        )
        plots_to_gen = []
        for combination in all_combinations:
            comparison_type = combination[0]
            visualization_type = combination[3]
            quantity_group: QuantityGroup = combination[5].model_copy()
            if comparison_type == ComparisonTypes.savings:
                quantity_group.constituents = [f"{col}.savings" for col in quantity_group.constituents]
                quantity_group.sum = f"{quantity_group.sum}.savings" if quantity_group.sum else None

            # Usually, visualize each constituent quantity and the sum (if any) separately
            # Prepare a mutable list of quantities, starting with individual constituents and optional sum
            quantities: list[str | QuantityGroup] = []
            quantities.extend(quantity_group.constituents)
            if quantity_group.sum:
                quantities.append(quantity_group.sum)
            if visualization_type == VizType.bar:
                # For bar plots, additionally visualize all together as a group in stacked bar plot
                quantities.append(quantity_group)
            for quantity in quantities:
                plot_spec = PlotSpec(
                    comparison_type=combination[0],
                    upgrade_inclusion=combination[1],
                    vacancy_inclusion=combination[2],
                    visualization_type=combination[3],
                    group_by=combination[4],
                    quantity=quantity,
                    quantity_group_name=quantity_group.name,
                )
                plots_to_gen.append(plot_spec)
        plots_generated = 0
        if max_plots_to_gen is None:
            print(f"Generating all {len(plots_to_gen)} plots")
        else:
            print(f"Generating {max_plots_to_gen} plots")
        for plots_generated, plot_spec in enumerate(plots_to_gen, 1):
            df = self.processor.prepare_data_for_plot(plot_spec)
            path_seg = plot_spec.path_segments()
            plotter = self._get_plotter(plot_spec.visualization_type)
            fig = plotter.create_plot(df, plot_spec)
            self.out_mgr.save_plot(fig, path_seg, df)
            print(f"Saved plot for {path_seg}")
            if max_plots_to_gen is not None and plots_generated >= max_plots_to_gen:
                return

    # Simple factory for plotter instances (no caching) -------------------
    def _get_plotter(self, viz: VizType):
        """Return a new plotter instance for the given visualization type."""
        if viz == VizType.bar:
            return BarPlotter()
        if viz == VizType.box:
            return BoxPlotter()
        raise ValueError(f"Unsupported visualization type: {viz}")
