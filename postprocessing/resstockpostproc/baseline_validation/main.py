"""Baseline Validation user-facing CLI.

Thin wrapper over plot_generator.generate_plots for end users. For the
developer/refactor fast-path entry point (--test, --no-svg, --index, etc.),
run plot_generator.py directly.
"""

import argparse
import sys
from pathlib import Path

from resstockpostproc.baseline_validation.plot_generator import generate_plots
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow


def main() -> int:
    """Main entry point for baseline validation plot generation."""
    parser = argparse.ArgumentParser(
        description="Generate baseline validation plots comparing BuildStock results with reference data (EIA, LRD)"
    )

    parser.add_argument(
        "--config",
        type=str,
        default=str(Path(__file__).parent / "workflow.yaml"),
        help="Path to workflow configuration YAML file (default: workflow.yaml in script directory)",
    )

    args = parser.parse_args()

    config_path = Path(args.config)
    if not config_path.exists():
        print(f"Error: Configuration file not found at {config_path}")
        return 1

    workflow.ensure_resstock_data_files()
    generate_plots()
    return 0


if __name__ == "__main__":
    sys.exit(main())
