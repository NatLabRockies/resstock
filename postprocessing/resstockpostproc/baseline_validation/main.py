"""User-facing CLI for baseline_validation.

Thin wrapper over generation.plot_generator.generate_plots. Configuration
is picked up from ``workflow.yaml`` next to this file — edit that file
to change inputs/outputs. For the developer fast-path entry point
(``--test``, ``--no-svg``, ``--index``, etc.), run
``generation/plot_generator.py`` directly.
"""

import argparse
import sys

from resstockpostproc.baseline_validation.generation.plot_generator import generate_plots
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow


def main() -> int:
    """Main entry point for ResStock comparison plot generation."""
    argparse.ArgumentParser(
        description=(
            "Generate comparison graphics and data between a ResStock baseline and other data sources (EIA, RECS, LRD)."
            " Edit workflow.yaml next to this script to change inputs and output location."
        ),
    ).parse_args()

    workflow.ensure_resstock_data_files()
    generate_plots()
    return 0


if __name__ == "__main__":
    sys.exit(main())
