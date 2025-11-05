"""Orchestrates the generation of all baseline validation plots."""

from pathlib import Path

import polars as pl

from resstockpostproc.baseline_validation.io_managers.get_lrd_data import get_lrd_data
import resstockpostproc.shared_utils.db_column_names as db_cols
from resstockpostproc.baseline_validation.io_managers import get_resstock_data as res_data
from resstockpostproc.baseline_validation.io_managers import get_eia_data as eia_data

from resstockpostproc.baseline_validation.utils import get_buildstock_query
from resstockpostproc.baseline_validation.io_managers.output_manager import save_dataframe, save_figure
from resstockpostproc.baseline_validation.plotters import eia_plotter, lrd_plotter, timeseries_plotter
from resstockpostproc.baseline_validation.reference_data.eia_data_loader import (
    _get_eia_annual_electricity,
    _get_eia_monthly_electricity,
    _get_eia_monthly_gas,
)
from resstockpostproc.baseline_validation.schema.workflow_schema import PlotType, WorkflowConfig
from resstockpostproc.baseline_validation.utils import ensure_directory


def generate_eia_plots(
    workflow: WorkflowConfig,
    output_dir: Path,
    output_formats: tuple = ("html", "svg", "parquet"),
) -> None:
    """Generate EIA validation plots."""
    print("Generating EIA validation plots...")
    year = workflow.reference_data.truth_data_year

    for agg_level in workflow.plots.aggregation_levels:
        print(f"  Processing {agg_level.value} level...")
        eia_annual = eia_data.get_annual_all(year=year, by=agg_level.value)
        eia_monthly = eia_data.get_monthly_all(year=year, by=agg_level.value)
        resstock_annual = res_data.get_annual_all(by=agg_level.value)
        resstock_monthly = res_data.get_monthly_all(by=agg_level.value)
       
        fig1 = eia_plotter.plot_annual_sales_comparison(resstock_annual, eia_annual, by=agg_level.value)
        fig2 = eia_plotter.plot_annual_sales_comparison_electricity(resstock_annual, eia_annual, by=agg_level.value)
        fig3 = eia_plotter.plot_annual_sales_comparison_natural_gas(resstock_annual, eia_annual, by=agg_level.value)
        fig4 = eia_plotter.plot_annual_sales_comparison_percent_diff(resstock_annual, eia_annual, by=agg_level.value)
        fig5 = eia_plotter.plot_monthly_sales_comparison_electricity(resstock_monthly, eia_monthly, by=agg_level.value)
        fig6 = eia_plotter.plot_monthly_sales_comparison_natural_gas(resstock_monthly, eia_monthly, by=agg_level.value)
        for i, fig in enumerate([fig1, fig2, fig3, fig4, fig5, fig6]):
            fig.write_html(output_dir / f"eia/{agg_level.value}/comparison_{i}.html")  # Temporary save to ensure directory exists

    print("EIA plots complete!")


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


def generate_all_plots(
    workflow: WorkflowConfig,
    output_formats: tuple = ("html", "svg", "parquet"),
    plot_types: list[PlotType] | None = None,
) -> None:
    """Generate all validation plots according to workflow configuration."""
    if plot_types is None:
        plot_types = list(workflow.plots.plot_types)

    output_base = Path(workflow.output.output_dir) / "plots" / workflow.output.run_name
    ensure_directory(output_base)

    print(f"Generating baseline validation plots to: {output_base}")
    print(f"Plot types: {[pt.value for pt in plot_types]}")

    if PlotType.eia in plot_types:
        generate_eia_plots(workflow, output_base, output_formats)

    # if PlotType.lrd in plot_types:
    #     generate_lrd_plots(workflow, output_base, output_formats)

    # if PlotType.timeseries in plot_types:
    #     generate_timeseries_plots(workflow, output_base, output_formats)

    print(f"\nAll plots generated successfully!")
    print(f"Output location: {output_base}")
