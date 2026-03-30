"""Baseline Validation CLI."""

import argparse
import logging
import sys
from pathlib import Path

from resstockpostproc.baseline_validation.plot_generator import generate_plots
from resstockpostproc.baseline_validation.schema.workflow_schema import PlotType, workflow

# Suppress verbose logging from image export libraries
logging.getLogger("kaleido").setLevel(logging.WARNING)
logging.getLogger("choreographer").setLevel(logging.WARNING)


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

    parser.add_argument(
        "--output",
        action="append",
        help=(
            "Output file types to generate (html, svg, json, parquet). "
            "May be specified multiple times. Defaults to [html, svg, parquet] if not specified."
        ),
    )

    parser.add_argument(
        "--plot-type",
        action="append",
        choices=["eia", "load_duration", "timeseries", "all"],
        help=(
            "Types of plots to generate. May be specified multiple times. "
            "Options: eia (EIA comparison), load_duration (load duration curves), "
            "timeseries (timeseries analysis), all (all plot types). "
            "Defaults to all plot types specified in config if not provided."
        ),
        default=['eia']
    )

    args = parser.parse_args()

    config_path = Path(args.config)
    if not config_path.exists():
        print(f"Error: Configuration file not found at {config_path}")
        return 1

    # Parse output types
    output_types = []
    if args.output:
        allowed_types = {"svg", "html", "json", "parquet"}
        for val in args.output:
            for item in val.replace(",", " ").split():
                if item in allowed_types:
                    output_types.append(item)
                else:
                    print(f"Warning: Invalid output type '{item}'. Skipping.")

    if not output_types:
        # Use defaults from config
        output_types = [fmt.value for fmt in workflow.plots.output_formats]

    print(f"Output formats: {output_types}")

    # Parse plot types
    plot_types = None
    if args.plot_type:
        if "all" in args.plot_type:
            plot_types = None  # Generate all
        else:
            plot_types = []
            for pt in args.plot_type:
                try:
                    plot_types.append(PlotType(pt))
                except ValueError:
                    print(f"Warning: Invalid plot type '{pt}'. Skipping.")

    generate_plots()
    return 0


if __name__ == "__main__":
    sys.exit(main())
