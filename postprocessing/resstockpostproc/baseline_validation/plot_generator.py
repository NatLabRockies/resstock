import argparse
import logging
import sys
from pathlib import Path
import sys
import polars as pl
from itertools import product
from plotly.graph_objects import Figure
from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.baseline_validation.io_managers.get_lrd_data import get_lrd_data
import resstockpostproc.shared_utils.db_column_names as db_cols
from resstockpostproc.baseline_validation.io_managers import get_resstock_data as res_data
from resstockpostproc.baseline_validation.io_managers import get_eia_data as eia_data
from resstockpostproc.baseline_validation.schema.workflow_schema import PlotType, workflow
from resstockpostproc.baseline_validation.utils import get_buildstock_query
from resstockpostproc.baseline_validation.io_managers.output_manager import save_dataframe, save_figure
from resstockpostproc.baseline_validation.plotters import eia_plotter, lrd_plotter, timeseries_plotter, recs_plotter
from resstockpostproc.baseline_validation.schema.workflow_schema import PlotType, WorkflowConfig
from resstockpostproc.baseline_validation.schema.plot_spec import PlotSpec, FileType, AggregationType, TruthSource, ViewType, Resolution
from resstockpostproc.baseline_validation.utils import ensure_directory
from resstockpostproc.baseline_validation.data_processing.gather_data import get_plot_data
from resstockpostproc.baseline_validation.schema.recs_enduse_mapping import RECS_ENDUSE_MAP

def generate_eia_plots() -> None:
    """Generate EIA validation plots."""
    print("Generating EIA validation plots...")
    quantities = [None, DataCol.ELECTRICITY_TOTAL, DataCol.NATURAL_GAS_TOTAL]
    agg_levels = ["state"] # eia_data.get_available_aggregation_levels()
    quantity_types = [AggregationType.per_unit, AggregationType.stock_total]
    resolutions = (Resolution.month, Resolution.year)
    quantities = [DataCol.NATURAL_GAS_TOTAL]

    for quantity, agg_level, quantity_type, resolution in product(quantities, agg_levels, quantity_types, resolutions):
        print(f"  Processing {agg_level} level...")
        plot_spec = PlotSpec(
            truth_source=TruthSource.eia,
            resolution=resolution,
            aggregation_level=agg_level,
            quantity=quantity,
            focus_on=None,
            aggregation_type=quantity_type,
            view=ViewType.value_view,
        )
        _show_figure(plot_spec)

    print("EIA plots complete!")

def generate_recs_plots() -> None:
    """Generate RECS validation plots."""
    print("Generating RECS validation plots...")
    monthly_quantities = [DataCol.ELECTRICITY_TOTAL,
                  DataCol.ELECTRICITY_WATER_HEATING,
                  DataCol.NATURAL_GAS_WATER_HEATING,
                  DataCol.NATURAL_GAS_TOTAL,
                  DataCol.NATURAL_GAS_SPACE_HEATING,
                  DataCol.ELECTRICITY_SPACE_HEATING,
                  DataCol.ELECTRICITY_SPACE_COOLING,
                  ]
    quantities = monthly_quantities
    quantities.extend(q for q in RECS_ENDUSE_MAP if q not in monthly_quantities)
    quantities = [None]
    agg_levels = [DataCol.VINTAGE]
    agg_types = [AggregationType.stock_total, AggregationType.per_unit_distribution,
                      AggregationType.per_unit, AggregationType.percent_users,
                      AggregationType.monthly_per_user, AggregationType.per_user_distribution,
                      AggregationType.per_user, AggregationType.customers
                      ]
    agg_types = [AggregationType.stock_total]
    resolutions = (Resolution.year,)
    quantities = [DataCol.NATURAL_GAS_WATER_HEATING]
    for quantity, agg_level, resolution, agg_type in product(quantities, agg_levels, resolutions, agg_types):
        if resolution == "month" and agg_type == AggregationType.per_unit_distribution:
            continue
        plot_spec = PlotSpec(
            truth_source=TruthSource.recs,
            resolution=resolution,
            aggregation_level=agg_level,
            quantity=quantity,
            focus_on="CO",
            aggregation_type=agg_type,
            view=ViewType.value_view
        )
        _show_figure(plot_spec)

def generate_lrd_plots() -> None:
    print("Generating LRD validation plots...")
    agg_levels = ["eiaid"] # eia_data.get_available_aggregation_levels()
    agg_types = [AggregationType.stock_total]
    resolutions = ("month", "year")

    quantities = [DataCol.ELECTRICITY_TOTAL]
    agg_levels = ["eiaid"]
    agg_types = [AggregationType.per_unit]
    resolutions = (Resolution.year, Resolution.month, Resolution.day_of_year, Resolution.hour_of_day,
                   Resolution.hour_of_day_summer, Resolution.hour_of_day_winter, Resolution.hour_of_year,
                   Resolution.top_100_hours)
    for quantity, agg_level, resolution, agg_type in product(quantities, agg_levels, resolutions, agg_types):
        plot_spec = PlotSpec(
            truth_source=TruthSource.lrd,
            resolution=resolution,
            aggregation_level=agg_level,
            quantity=quantity,
            focus_on="US Total",
            aggregation_type=agg_type,
            view=ViewType.value_view,
        )
    

        _show_figure(plot_spec)

def _show_figure(plot_spec: PlotSpec) -> None:
    """Generate and show a plot based on the plot specification."""
    fig = _create_plot(plot_spec)
    #fig.show(renderer="browser")

def _create_plot(plot_spec: PlotSpec) -> Figure:
    """Create a plot based on the plot specification."""
    data = get_plot_data(plot_spec)
    plot_func = get_plotting_function(plot_spec.truth_source)
    fig, title = plot_func(data, plot_spec)
    fig.show(renderer="browser")
    return fig

    print("RECS plots complete!")

# def generate_lrd_plots(
#     workflow: WorkflowConfig,
#     output_dir: Path,
#     output_formats: tuple = ("html", "svg", "parquet"),
# ) -> None:
#     """Generate load duration curve plots."""
#     print("Generating load duration curve plots...")

#     bsq = get_buildstock_query(
#         workgroup=workflow.workgroup,
#         workflow.data_sources,
#         truth_data_year=workflow.reference_data.truth_data_year,
#         eia_mapping_version=workflow.reference_data.eia_mapping_version,
#     )

#     lrd_ref = get_lrd_data(year=workflow.reference_data.truth_data_year)
#     utilities = lrd_ref.filter(pl.col("eiaid") > 0)["eiaid"].unique().to_list()

#     buildstock_ts = get_timeseries(
#         bsq,
#         enduses=["fuel_use__electricity__total__kwh"],
#         by="eiaid",
#         restrict_list=utilities[:10],
#     )

#     buildstock_ldc = lrd_plotter.prepare_buildstock_ldc_data(buildstock_ts, per_unit=True, group_col="eiaid")
#     lrd_ldc = lrd_plotter.calculate_load_duration_curve(lrd_ref, value_col="kwh_per_meter", group_col="eiaid")

#     fig = lrd_plotter.plot_multi_utility_ldc(buildstock_ldc, lrd_ldc, group_col="eiaid", max_utilities=5)
#     plot_dir = output_dir / "lrd"
#     save_figure(fig, plot_dir, "multi_utility_ldc", formats=tuple(output_formats))
#     save_dataframe(buildstock_ldc, plot_dir, "buildstock_ldc_data", formats=("parquet",))

#     for utility in utilities[:5]:
#         bs_util = buildstock_ldc.filter(pl.col("eiaid") == utility)
#         lrd_util = lrd_ldc.filter(pl.col("eiaid") == utility)

#         if bs_util.height > 0:
#             fig = lrd_plotter.plot_load_duration_curve(
#                 bs_util, lrd_util, value_col="kwh_per_unit", entity_name=f"Utility {utility}"
#             )
#             save_figure(fig, plot_dir / "by_utility", f"ldc_utility_{utility}", formats=tuple(output_formats))

#     print("  LRD plots complete!")


# def generate_timeseries_plots(
#     workflow: WorkflowConfig,
#     output_dir: Path,
#     output_formats: tuple = ("html", "svg", "parquet"),
# ) -> None:
#     """Generate timeseries validation plots."""
#     print("Generating timeseries plots...")

#     bsq = get_buildstock_query(
#         workgroup=workflow.workgroup,
#         config=workflow.data_source,
#         truth_data_year=workflow.reference_data.truth_data_year,
#         eia_mapping_version=workflow.reference_data.eia_mapping_version,
#     )

#     eia_annual = _get_eia_annual_electricity(year=workflow.reference_data.truth_data_year)
#     top_states = eia_annual.group_by("state").agg(pl.col("customers").sum()).sort("customers", descending=True).head(5)["state"].to_list()

#     for state in top_states:
#         print(f"  Processing {state}...")

#         buildstock_ts = get_timeseries(
#             bsq, enduses=["fuel_use__electricity__total__kwh"], by="state", restrict_list=[state]
#         )

#         if buildstock_ts.height == 0:
#             continue

#         state_ts = buildstock_ts.filter(pl.col("state") == state)

#         fig = timeseries_plotter.plot_hourly_profiles(state_ts, by_month=True)
#         plot_dir = output_dir / "timeseries" / state
#         save_figure(fig, plot_dir, "hourly_profiles_by_month", formats=tuple(output_formats))

#         fig = timeseries_plotter.plot_daily_aggregate(state_ts)
#         save_figure(fig, plot_dir, "daily_aggregate", formats=tuple(output_formats))

#     print("  Timeseries plots complete!")

def get_plotting_function(truth_source: TruthSource):
    """Return a plotting function for the given visualization type."""
    match truth_source:
        case TruthSource.eia:
            return recs_plotter.create_plot
        case TruthSource.lrd:
            return lrd_plotter.create_plot
        case TruthSource.recs:
            return recs_plotter.create_plot
        case _:
            raise ValueError(f"Unsupported truth source: {truth_source}")

def generate_all_plots(
    workflow: WorkflowConfig,
    output_formats: tuple = ("html", "svg", "parquet"),
    plot_types: list[PlotType] | None = None,
) -> None:
    """Generate all validation plots according to workflow configuration."""
    if plot_types is None:
        plot_types = list(workflow.plots.plot_types)

    generate_lrd_plots()
    return
    print(f"Generating baseline validation plots.")
    print(f"Plot types: {[pt.value for pt in plot_types]}")

    if PlotType.lrd in plot_types:
        generate_lrd_plots()
    if PlotType.recs in plot_types:
        generate_recs_plots()
    if PlotType.eia in plot_types:
        generate_eia_plots()


    # if PlotType.lrd in plot_types:
    #     generate_lrd_plots(workflow, output_base, output_formats)

    # if PlotType.timeseries in plot_types:
    #     generate_timeseries_plots(workflow, output_base, output_formats)

    print(f"\nAll plots generated successfully!")
    print(f"Output location: {workflow.output.output_dir / workflow.output.run_name}")

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
        default=["lrd"]
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

    generate_all_plots(
        workflow=workflow,
        output_formats=tuple(output_types),
        plot_types=plot_types,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
