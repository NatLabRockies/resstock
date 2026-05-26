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
import polars as pl
from pathlib import Path
import s3fs
from resstockpostproc.process_metadata import (
    get_schema_superset,
    get_upgrade_rename_dict,
    get_failed_building_list,
    process_simulation_outputs,
    export_metadata_and_annual_results_for_upgrade,
    cache_simulation_outputs_file
)
from resstockpostproc.utils import (
    setup_fsspec_filesystem
)

def export_metadata_and_annual_results(raw_results_dir: str,
                                       output_dir: str,
                                       aws_profile_name = None) -> None:
    # Set up filesystem objects for raw results and output directories
    raw_results_dir = setup_fsspec_filesystem(raw_results_dir, aws_profile_name)
    output_dir = setup_fsspec_filesystem(output_dir, aws_profile_name)

    # Find the raw results files
    baseline_pqt_glob = f'{raw_results_dir["fs_path"]}/baseline/*.parquet'
    baseline_result_files = list(raw_results_dir['fs'].glob(baseline_pqt_glob))
    upgrade_pqt_glob = f'{raw_results_dir["fs_path"]}/upgrades/**/*.parquet'
    upgrade_result_files = list(raw_results_dir['fs'].glob(upgrade_pqt_glob))
    result_files = baseline_result_files + upgrade_result_files
    print(f"Found results files for {len(result_files)} upgrades (including baseline)")
    # Prepend s3:// to paths for Polars compatibility
    if isinstance(raw_results_dir['fs'], s3fs.S3FileSystem):
        result_files = [f"s3://{f}" for f in result_files]

    baseline_file = [f for f in result_files if "up00" in Path(f).name.lower()][0]
    upgrade_ids = [int(re.search(r'up(\d+)', p).group(1)) for p in result_files]
    upgrade_ids.sort()

    # Information used across upgrades
    upgrade_renamer = get_upgrade_rename_dict(raw_results_dir)
    col_schema = get_schema_superset(result_files, raw_results_dir)
    sim_out_cache_dir = Path(f"{output_dir['fs_path']}/cached_simulation_outputs")

    # Process and cache the simulation outputs, starting with the baseline
    baseline_df = pl.scan_parquet(baseline_file, storage_options=raw_results_dir['storage_options'])
    failed_bldgs = get_failed_building_list(baseline_df)
    processed_baseline_df = None

    # Determine if we need to prepend s3:// prefix for Polars compatibility
    use_s3_prefix = isinstance(raw_results_dir['fs'], s3fs.S3FileSystem)

    for upgrade_id in upgrade_ids:
        upgrade_file = f'{raw_results_dir["fs_path"]}/upgrades/upgrade={upgrade_id}/results_up{upgrade_id:02d}.parquet'
        if upgrade_id == 0:
            upgrade_file = f'{raw_results_dir["fs_path"]}/baseline/results_up{upgrade_id:02d}.parquet'

        # Prepend s3:// prefix for Polars compatibility when using S3
        if use_s3_prefix:
            upgrade_file = f's3://{upgrade_file}'

        print(f"Processing upgrade file: {upgrade_file}, upgrade number: {upgrade_id} {'*'*100}")
        raw_upgrade_df = pl.scan_parquet(upgrade_file, storage_options=raw_results_dir['storage_options'])
        processed_upgrade_df = process_simulation_outputs(
            failed_bldgs,
            baseline_df,
            processed_baseline_df,
            raw_upgrade_df,
            upgrade_id,
            upgrade_renamer,
            col_schema
        )
        cache_simulation_outputs_file(output_dir, sim_out_cache_dir, upgrade_id, processed_upgrade_df)
        up_cols = set(sorted(processed_upgrade_df.collect_schema().names()))

        if upgrade_id == 0:
            processed_baseline_df = processed_upgrade_df
            base_cols = set(sorted(processed_baseline_df.collect_schema().names()))

        if not base_cols == up_cols:
            raise ValueError("Column set in baseline and upgrade don't match")

    # Export files to specified geographic partitions
    geo_exports = [
    {
        'geo_top_dir': 'national',
        'partition_cols': {},
        'data_types': ['full'],  # TODO add basic
        'file_types': [ 'csv', 'parquet'],
    },
    {
        'geo_top_dir': 'by_state',
        'partition_cols': {
            'in.state': 'state'
        },
        'data_types': ['full'],  # TODO add basic
        'file_types': ['csv', 'parquet'],
    }
    ]
    for upgrade_id in upgrade_ids:
        export_metadata_and_annual_results_for_upgrade(
            output_dir,
            upgrade_id,
            geo_exports)


if __name__ == "__main__":
    import argparse

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
