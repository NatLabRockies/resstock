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

    # Create the orchestrator and generate plots
    orchestrator = PlotOrchestrator(config_path, output_types=output_types, overwrite=args.overwrite)
    orchestrator.generate_all_plots(max_plots_to_gen=args.max_plots)
    orchestrator.print_time_spent()
    orchestrator.out_mgr.print_time_spent()
    return 0


if __name__ == "__main__":
    sys.exit(main())
