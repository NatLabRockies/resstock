"""
Standard Plot Generator
-----------------------
Generates standard QC plots for ResStock simulation results based on YAML configuration.
"""

import argparse
import os
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
        "--save-data",
        action="store_true",
        help="Save the data used to generate the plots",
    )
    args = parser.parse_args()
    config_path = args.config
    save_data = args.save_data or False

    # Verify the config file exists
    if not os.path.exists(config_path):
        print(f"Error: Configuration file not found at {config_path}")
        sys.exit(1)

    # Create the orchestrator and generate plots
    orchestrator = PlotOrchestrator(config_path)
    orchestrator.generate_all_plots(save_data=save_data)
    return 0


if __name__ == "__main__":
    sys.exit(main())
