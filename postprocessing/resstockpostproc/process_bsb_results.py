#!/usr/bin/env python3
"""
Script to take in raw BuildStockBatch results_csvs / parquet and convert them to pub_annual version.

Example usage:
uv run resstockpostproc/process_bsb_results.py /path/to/bsb_raw_results /path/to/output_dir
uv run resstockpostproc/process_bsb_results.py "C:/Scratch/ResStock/efforts/full_550k_run" "s3://oedi-data-lake/nrel-pds-building-stock/end-use-load-profiles-for-us-building-stock/2025/resstock_amy2018_release_1"

Note: bsb_raw_results folder must contain both baseline and upgrade files. Baseline file should be named
results_up00.parquet and upgrade files should be named results_upXX.parquet where XX is the upgrade number. The can
either be in their own folders (baseline and upgrades) or all be in the same folder.
"""

import re
import logging
import polars as pl
from pathlib import Path
from resstockpostproc.simulation_outputs import (
    get_failed_building_list,
    get_schema_superset,
    get_upgrade_rename_dict,
    process_simulation_outputs,
    cache_simulation_outputs_file,
    get_cached_simulation_outputs_file
)
from resstockpostproc.metadata_and_annual_results import export_metadata_and_annual_results_for_upgrade
from resstockpostproc.utils import (
    setup_fsspec_filesystem
)
from resstockpostproc.allocated_weights import (
    create_allocated_weights,
    create_allocated_weights_for_quota_sampler,
    create_allocated_weights_plus_util_bills_for_upgrade
)


def export_metadata_and_annual_results(raw_results_dir: str,
                                       output_dir: str,
                                       aws_profile_name = None,
                                       write_workers=4,
                                       slice_rows=200_000,
                                       sampler_type="stratified"
                                       ) -> None:
    """
    Export metadata and annual results for the given raw BuildStockBatch results.

    Args:
        raw_results_dir: Directory containing raw BuildStockBatch results (baseline and upgrades)
        output_dir: Directory to write transformed results
        aws_profile_name: Optional AWS profile name for S3 access
        write_workers: Number of parallel workers for writing output files
        slice_rows: Number of rows per slice when writing output files
        sampler_type: Type of sampler used for allocation (e.g., "TODO_new_sampler", "quota")
    """    
    # Set up filesystem objects for raw results and output directories
    raw_results_dir = setup_fsspec_filesystem(raw_results_dir, aws_profile_name)
    output_dir = setup_fsspec_filesystem(output_dir, aws_profile_name)

    # Find the raw results files
    pqt_glob = f'{raw_results_dir["fs_path"]}/**/*.parquet'
    result_files = raw_results_dir["fs"].glob(pqt_glob)
    baseline_files = [f for f in result_files if "up00" in Path(f).name.lower()]
    upgrade_files = [f for f in result_files if "up00" not in Path(f).name.lower()]

    # Information used across upgrades
    upgrade_renamer = get_upgrade_rename_dict(raw_results_dir)
    col_schema  = get_schema_superset(upgrade_files, raw_results_dir)
    sim_out_cache_dir = Path(f"{output_dir['fs_path']}/cached_simulation_outputs")

    # Process and cache the baseline simulation outputs
    upgrade_id = 0
    baseline_file = baseline_files[0]
    print(f"Processing baseline file: {baseline_file}")
    # Add s3:// prefix for polars if using S3
    baseline_path = f"s3://{baseline_file}" if raw_results_dir["storage_options"] is not None else baseline_file
    baseline_df = pl.scan_parquet(baseline_path, storage_options=raw_results_dir["storage_options"])
    failed_bldgs = get_failed_building_list(baseline_df)
    bs_pub_df = process_simulation_outputs(
            failed_bldgs,
            baseline_df,
            None,
            baseline_df,
            upgrade_id,
            upgrade_renamer,
            col_schema ,
            # skip_if_cached # Add some argument here to skip if cached files already exist
        )
    cache_simulation_outputs_file(output_dir, sim_out_cache_dir, upgrade_id, bs_pub_df)
    base_cols = set(bs_pub_df.collect_schema().names())

    # Process and cache the upgrade simulation outputs
    upgrade_ids = [0]
    for upgrade_file in upgrade_files:
        up_info = re.search(r"up(\d+)", Path(upgrade_file).name)
        if up_info is None:
            continue
        upgrade_id = int(up_info.group(1))
        upgrade_ids.append(upgrade_id)
        print(f"Processing upgrade file: {upgrade_file}, upgrade number: {upgrade_id} {'*'*100}")
        # Add s3:// prefix for polars if using S3
        upgrade_path = f"s3://{upgrade_file}" if raw_results_dir["storage_options"] is not None else upgrade_file
        upgrade_df = pl.scan_parquet(upgrade_path, storage_options=raw_results_dir["storage_options"])
        up_df = process_simulation_outputs(
            failed_bldgs,
            baseline_df,
            bs_pub_df,
            upgrade_df,
            upgrade_id,
            upgrade_renamer,
            col_schema ,
            # skip_if_cached # Add some argument here to skip if cached files already exist
        )
        cache_simulation_outputs_file(output_dir, sim_out_cache_dir, upgrade_id, up_df)
        up_cols = set(up_df.collect_schema().names())
        if not base_cols == up_cols:
            raise ValueError("Column set in baseline and upgrade don't match")
    upgrade_ids.sort()

    # Process and cache allocated weights
    bs_pub_df_path = get_cached_simulation_outputs_file(output_dir, sim_out_cache_dir, 0)
    if sampler_type == "stratified":
        create_allocated_weights(bs_pub_df_path, Path(f"{output_dir['fs_path']}"))
    elif sampler_type == "quota":
        create_allocated_weights_for_quota_sampler(bs_pub_df_path, Path(f"{output_dir['fs_path']}"))

    # Process and cache allocated weights plus utility bills
    for upgrade_id in upgrade_ids:
        create_allocated_weights_plus_util_bills_for_upgrade(output_dir, upgrade_id)

    # Define the geographic partitions to export
    # This is an example from ComStock SDR
    geo_exports = [
    {"geo_top_dir": "national",
        "partition_cols": {},
        "aggregation_levels": ["in.state"],
        "data_types": ["full"],  # TODO add basic downselect method
        "file_types": ["csv", "parquet"],
    },
    {"geo_top_dir": "by_state_and_county",
        "partition_cols": {
            "in.state": "state",
            "in.nhgis_county_gisjoin": "county",
        },
        "aggregation_levels": ["in.nhgis_tract_gisjoin"],  # The only one by at full resolution (tract)
        "data_types": ["full"],  # TODO add basic downselect method
        "file_types": ["csv", "parquet"],
    },
    {
        "geo_top_dir": "by_state",
        "partition_cols": {
            "in.state": "state"
        },
        "aggregation_levels": ["in.state"],
        "data_types": ["full"],  # TODO add basic downselect method
        "file_types": ["csv", "parquet"],
    },
    {"geo_top_dir": "by_state_and_puma",
        "partition_cols": {
            "in.state": "state",
            "in.nhgis_puma_gisjoin": "puma",
        },
        "aggregation_levels": ["in.nhgis_puma_gisjoin"],
        "data_types": ["full"],  # TODO add basic downselect method
        "file_types": ["csv", "parquet"],
    }
    ]

    for upgrade_id in upgrade_ids:
        export_metadata_and_annual_results_for_upgrade(
            output_dir,
            upgrade_id,
            geo_exports,
            write_workers=write_workers,
            slice_rows=slice_rows)


if __name__ == "__main__":
    import argparse

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(name)s %(levelname)s: %(message)s",
    )

    parser = argparse.ArgumentParser(
        description="Process raw BuildStock results and write transformed data"
    )
    parser.add_argument(
        "raw_results_dir",
        default="Users/radhikar/Documents/buildstock2025/resstock/postprocessing/resstockpostproc/upgrade_comparison/sdr_plots/s3_data/res-sdr/testing-sdr-fy25/ghp_envelope_0807_30k/raw_results",
        help="Directory containing raw BuildStock results",
    )
    parser.add_argument(
        "output_dir",
        default="Users/radhikar/Documents/buildstock2025/resstock/postprocessing/resstockpostproc/upgrade_comparison/sdr_plots/s3_data/res-sdr/testing-sdr-fy25/ghp_envelope_0807_30k/annual_results",
        help="Directory to write transformed results",
    )
    args = parser.parse_args()
    export_metadata_and_annual_results(args.raw_results_dir, args.output_dir)
