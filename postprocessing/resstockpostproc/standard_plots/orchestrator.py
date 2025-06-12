"""
Orchestrator module for standard plots
--------------------------------------
Coordinates the generation of all plots based on the configuration
"""
from pathlib import Path
from typing import Dict, List, Optional, Any, Sequence
from resstockpostproc.standard_plots.data_processor import DataProcessor
from resstockpostproc.standard_plots.bar_plotter import BarPlotter
from resstockpostproc.standard_plots.box_plotter import BoxPlotter
from resstockpostproc.standard_plots.schema.workflow_schema import WorkflowConfig, QuantityGroup
from resstockpostproc.standard_plots.schema.plot_spec import PlotSpec, ComparisonTypes, VizType
from resstockpostproc.standard_plots.output_manager import OutputManager
from itertools import product
import re

class PlotOrchestrator:
    """
    Orchestrates the plot generation process
    """
    def __init__(self, config_path: str):
        """
        Initialize the orchestrator
        
        Args:
            config_path: Path to the workflow configuration YAML file
        """
        self.workflow = WorkflowConfig.from_yaml(config_path)
        
        # Setup the data processor
        self.processor = DataProcessor(
            self.workflow.results_csvs_folder, 
            self.workflow.upgrades
        )
        self.out_mgr = OutputManager(self.workflow.output_dir)

    def generate_all_plots(self) -> None:
        """Generate all plots declared in YAML using the new PlotDef contract."""

        gen: dict[str, str] = {}

        # Get all configuration elements for iteration
        group_by_list = self.workflow.group_by
        # Create all possible combinations of parameters
        all_combinations = product(
            self.workflow.comparison_types,
            self.workflow.upgrade_inclusion,
            self.workflow.vacancy_inclusion,
            self.workflow.visualization_types,
            [None] + self.workflow.group_by,
            self.workflow.quantities
        )
        for combination in all_combinations:
            comparison_type = combination[0]
            visualization_type = combination[3]
            quantity = combination[5].copy()
            if comparison_type == ComparisonTypes.savings:
                quantity.constituents = [f"{col}.savings" for col in quantity.constituents]
                quantity.sum = f"{quantity.sum}.savings" if quantity.sum else None

            # Usually, visualize each constituent quantity and the sum (if any) separately
            quantities: Sequence[str | QuantityGroup] = quantity.constituents + ([quantity.sum] if quantity.sum else [])
            if visualization_type == VizType.bar:
                # For bar plots, additionally visualize all together as a group in stacked bar plot
                quantities.append(quantity)
            quantity_group = quantity.name
            for quantity in quantities:
                plot_spec = PlotSpec(
                    comparison_type=combination[0],
                    upgrade_inclusion=combination[1],
                    vacancy_inclusion=combination[2],
                    visualization_type=combination[3],
                    group_by=combination[4],
                    quantity=quantity
                )
                if not isinstance(quantity, str) or not plot_spec.group_by:
                    continue
                df = self.processor.prepare_data_for_plot(plot_spec)
                path_seg = plot_spec.path_segments(quantity_group)
                def safe_sqlite_name(path: Path) -> str:
                    return re.sub(r"[^0-9A-Za-z_]", "_", path.as_posix())
                table_name = safe_sqlite_name(path_seg)
                df.write_database(table_name, f"sqlite:///{self.workflow.output_dir}/plot_data.db", if_table_exists="replace")
                plotter = self._get_plotter(plot_spec.visualization_type)
                fig = plotter.create_plot(df, plot_spec)
                self.out_mgr.save_plot(fig, path_seg)
                print(f"Saved plot for {path_seg}")

    # Simple factory for plotter instances (no caching) -------------------
    def _get_plotter(self, viz: VizType):
        """Return a new plotter instance for the given visualization type."""
        if viz == VizType.bar:
            return BarPlotter()
        if viz == VizType.box:
            return BoxPlotter()
        raise ValueError(f"Unsupported visualization type: {viz}")
