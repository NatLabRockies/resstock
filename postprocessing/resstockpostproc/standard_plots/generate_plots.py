"""
Standard Plot Generator
-----------------------
Generates standard QC plots for ResStock simulation results based on YAML configuration.
"""

import argparse
import os
import re
import sys
from pathlib import Path

# Import dependencies that might be needed
# Import our components
from resstockpostproc.standard_plots.orchestrator import PlotOrchestrator
from resstockpostproc.standard_plots.schema.workflow_schema import WorkflowConfig


def main():
    """
    Main entry point for the plot generator
    """
    parser = argparse.ArgumentParser(description="Generate standard QC plots for ResStock simulation results")
    parser.add_argument(
        "--config",
        type=str,
        help="Path to plot configuration YAML file",
        default=str(Path(__file__).parent / "workflow.yaml"),
    )
    parser.add_argument(
        "--output",
        action="append",
        help=(
            "Output file types to generate (svg, html, parquet, json, csv). "
            "May be specified multiple times or as a comma-separated list."
            "Defaults to [json, parquet, html] if not specified."
        ),
    )
    parser.add_argument(
        "--quantity_group",
        action="append",
        help=(
            "Name of a quantity group to include in plot generation. "
            "May be specified multiple times. If omitted, all quantity groups in the workflow are processed."
        ),
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite existing output files",
    )
    parser.add_argument(
        "--max-plots",
        type=int,
        help="Maximum number of plots to generate",
    )
    args = parser.parse_args()
    config_path = args.config

    # Parse and validate output types
    allowed_types = {"svg", "html", "parquet", "json", "csv"}
    output_types = []
    output = args.output or []
    for val in output:
        for item in re.split(r"[,\s]+", val.strip()):
            if item and item in allowed_types:
                output_types.append(str(item))
            else:
                print(f"Warning: Invalid output file type: {item}. Skipping.")
    if output_types:
        print(f"Outputting: {output_types}")

    # Verify the config file exists
    if not os.path.exists(config_path):
        print(f"Error: Configuration file not found at {config_path}")
        sys.exit(1)

    # Load workflow configuration so we can optionally filter quantity groups
    workflow = WorkflowConfig.from_yaml(config_path)

    # Apply quantity group filter if provided
    if args.quantity_group:
        selected_set = set(args.quantity_group)
        print(f"Selected quantity groups: {selected_set}")
        filtered_qs = tuple(q for q in workflow.quantities if q.name in selected_set)
        if not filtered_qs:
            print(
                "Error: None of the specified --quantity_group values match the quantities defined in the workflow."
                f"Available quantity groups: {', '.join(q.name for q in workflow.quantities)}"
            )
            sys.exit(1)
        workflow.set_quantities(filtered_qs)
        missing = selected_set - {q.name for q in filtered_qs}
        if missing:
            print(f"Warning: The following quantity groups were not found and will be ignored: {', '.join(missing)}")

    # Create the orchestrator and generate plots
    orchestrator = PlotOrchestrator(workflow, output_types=output_types, overwrite=args.overwrite)
    orchestrator.generate_all_plots(max_plots_to_gen=args.max_plots)
    orchestrator.print_time_spent()
    orchestrator.out_mgr.print_time_spent()
    return 0


if __name__ == "__main__":
    sys.exit(main())
