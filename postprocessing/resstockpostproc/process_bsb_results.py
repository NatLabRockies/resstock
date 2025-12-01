#!/usr/bin/env python3
"""
Script to take in raw BuildStockBatch results_csvs / parquet and convert them to pub_annual version.

Example usage:
uv run resstockpostproc/process_bsb_results.py /path/to/bsb_raw_results /path/to/output_dir
uv run resstockpostproc/process_bsb_results.py "C:/Users/pwhite2/Documents/sdr_2025_final_run_data/AMY2012" "C:/Users/pwhite2/Documents/sdr_2025_final_run_data/AMY2012_output"
uv run resstockpostproc/process_bsb_results.py "C:/Scratch/ResStock/efforts/full_550k_run" "s3://oedi-data-lake/nrel-pds-building-stock/end-use-load-profiles-for-us-building-stock/2025/resstock_amy2018_release_1"




Note: bsb_raw_results folder must contain both baseline and upgrade files. Baseline file should be named
results_up00.parquet and upgrade files should be named results_upXX.parquet where XX is the upgrade number. The can
either be in their own folders (baseline and upgrades) or all be in the same folder.
"""

import re
import sys
import s3fs
import polars as pl
from pathlib import Path
from resstockpostproc.process_metadata import (
    get_upgrade_foo_col_schema,
    get_upgrade_rename_dict,
    get_failed_building_list,
    process_simulation_outputs,
    export_metadata_and_annual_results_for_upgrade
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
    pqt_glob = f'{raw_results_dir["fs_path"]}/**/*.parquet'
    result_files = raw_results_dir['fs'].glob(pqt_glob)
    baseline_files = [f for f in result_files if "up00" in Path(f).name.lower()]
    upgrade_files = [f for f in result_files if "up00" not in Path(f).name.lower()]

    # Information used across upgrades
    upgrade_renamer = get_upgrade_rename_dict(raw_results_dir)
    upgrade_foo_col_schema = get_upgrade_foo_col_schema(upgrade_files, raw_results_dir)
    sim_out_cache_dir = Path(f"{output_dir['fs_path']}/cached_simulation_outputs")

    # Process and cache the baseline simulation outputs
    upgrade_id = 0
    baseline_file = baseline_files[0]
    print(f"Processing baseline file: {baseline_file}")
    baseline_df = pl.scan_parquet(baseline_file, storage_options=raw_results_dir['storage_options'])
    failed_bldgs = get_failed_building_list(baseline_df)
    bs_pub_df = process_simulation_outputs(
            failed_bldgs,
            baseline_df,
            None,
            baseline_df,
            upgrade_id,
            upgrade_renamer,
            upgrade_foo_col_schema
        )
    cache_simulation_outputs_file(output_dir, sim_out_cache_dir, upgrade_id, bs_pub_df)
    base_cols = set(sorted(bs_pub_df.collect_schema().names()))

    # Process and cache the upgrade simulation outputs
    upgrade_ids = [0]
    for upgrade_file in upgrade_files:
        up_info = re.search(r"up(\d+)", Path(upgrade_file).name)
        if up_info is None:
            continue
        upgrade_id = int(up_info.group(1))
        upgrade_ids.append(upgrade_id)
        print(f"Processing upgrade file: {upgrade_file}, upgrade number: {upgrade_id} {'*'*100}")
        upgrade_df = pl.scan_parquet(upgrade_file, storage_options=raw_results_dir['storage_options'])
        up_df = process_simulation_outputs(
            failed_bldgs,
            baseline_df,
            bs_pub_df,
            upgrade_df,
            upgrade_id,
            upgrade_renamer,
            upgrade_foo_col_schema
        )
        cache_simulation_outputs_file(output_dir, sim_out_cache_dir, upgrade_id, up_df)
        up_cols = set(sorted(up_df.collect_schema().names()))
        if not base_cols == up_cols:
            raise ValueError(f"Column set in baseline and upgrade don't match")
    upgrade_ids.sort()

    # Define the geographic partitions to export
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


def cache_simulation_outputs_file(output_dir, sim_out_cache_dir: Path, upgrade_id: int, df: pl.LazyFrame):
    file_name = f"cached_simulation_outputs_upgrade{upgrade_id}.parquet"
    upgrade_cache_dir = Path(f"{sim_out_cache_dir}/upgrade={upgrade_id}")
    file_path = upgrade_cache_dir / file_name
    if isinstance(output_dir['fs'], s3fs.S3FileSystem):
        file_path = f's3://{file_path.as_posix()}'
    else:
        upgrade_cache_dir.mkdir(parents=True, exist_ok=True)
    with output_dir['fs'].open(str(file_path), "wb") as f:
        df.sink_parquet(f)
    print(f"Cached simulation outputs for upgrade {upgrade_id} to {file_path}")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Process raw BuildStock results and write transformed data"
    )
    parser.add_argument(
        "raw_results_dir",
        default="Users/radhikar/Documents/buildstock2025/resstock/postprocessing/resstockpostproc/standard_plots/sdr_plots/s3_data/res-sdr/testing-sdr-fy25/ghp_envelope_0807_30k/raw_results",
        help="Directory containing raw BuildStock results",
    )
    parser.add_argument(
        "output_dir",
        default="Users/radhikar/Documents/buildstock2025/resstock/postprocessing/resstockpostproc/standard_plots/sdr_plots/s3_data/res-sdr/testing-sdr-fy25/ghp_envelope_0807_30k/annual_results",
        help="Directory to write transformed results",
    )
    args = parser.parse_args()
    export_metadata_and_annual_results(args.raw_results_dir, args.output_dir)
