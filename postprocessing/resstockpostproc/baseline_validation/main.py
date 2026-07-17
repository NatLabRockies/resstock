"""User-facing CLI for baseline_validation.

Thin wrapper over generation.plot_generator.generate_plots. Configuration
is picked up from ``workflow.yaml`` next to this file — edit that file
to change inputs/outputs. For developer-only fast-path options
(``--no-svg``, ``--index``, etc.), run ``generation/plot_generator.py``
directly.
"""

import argparse
import sys

from resstockpostproc.baseline_validation.generation.plot_generator import generate_plots
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow


def main() -> int:
    """Main entry point for ResStock comparison plot generation."""
    parser = argparse.ArgumentParser(
        description=(
            "Generate comparison graphics and data between a ResStock baseline and other data sources (EIA, RECS, LRD)."
            " Edit workflow.yaml next to this script to change inputs and output location."
        ),
    )
    parser.add_argument(
        "--test",
        action="store_true",
        default=False,
        help="Generate only test subset plots (limited focus expansion)",
    )
    parser.add_argument(
        "--no-parallel",
        action="store_true",
        default=False,
        help="Disable parallel plot generation (run sequentially; useful for memory-constrained CI)",
    )
    args = parser.parse_args()

    workflow.ensure_resstock_data_files()
    generate_plots(test_only=args.test, parallel=not args.no_parallel)
    return 0


if __name__ == "__main__":
    sys.exit(main())
