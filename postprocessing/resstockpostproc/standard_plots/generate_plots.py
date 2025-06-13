#!/usr/bin/env python

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
import plotly.io as pio

# Import our components
from resstockpostproc.standard_plots.orchestrator import PlotOrchestrator

# Make sure plotly can write images
try:
    import kaleido  # type: ignore

    pio.kaleido.scope.mathjax = None  # Disable MathJax for better performance
except ImportError:
    print("Warning: kaleido not installed. Cannot save static images.")
    print("Install with: pip install -U kaleido")


def main():
    """
    Main entry point for the plot generator
    """
    parser = argparse.ArgumentParser(description="Generate standard QC plots for ResStock simulation results")
    parser.add_argument("--config", type=str, help="Path to plot configuration YAML file", default=str(Path(__file__).parent / "workflow.yaml"))

    args = parser.parse_args()
    config_path = args.config

    # Verify the config file exists
    if not os.path.exists(config_path):
        print(f"Error: Configuration file not found at {config_path}")
        sys.exit(1)

    # Create the orchestrator and generate plots
    orchestrator = PlotOrchestrator(config_path)
    orchestrator.generate_all_plots()
    return 0


if __name__ == "__main__":
    sys.exit(main())
