#!/usr/bin/env python3
"""
Script to take in raw BuildStockBatch results_csvs / parquet and convert them to pub_annual version.

Example usage:
uv run resstockpostproc/process_bsb_results.py /path/to/bsb_raw_results /path/to/output_dir
uv run resstockpostproc/process_bsb_results.py "C:/Scratch/ResStock/efforts/full_550k_run" "C:/Scratch/ResStock/efforts/full_550k_run_output"
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
    process_baseline_simulation_outputs,
    get_upgrade_columns,
    get_col_maps,
    add_weighted_cols,
    add_saving_cols,
    add_missing_upgrade_cols,
    reorder_columns,
    process_upgrade_simulation_outputs,
    get_upgrade_rename_dict,
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

    # output_path = Path(output_dir)
    # output_path.mkdir(parents=True, exist_ok=True)
    pqt_glob = f'{raw_results_dir["fs_path"]}/**/*.parquet'
    result_files = raw_results_dir['fs'].glob(pqt_glob)
    baseline_files = [f for f in result_files if "up00" in Path(f).name.lower()]
    upgrade_files = [f for f in result_files if "up00" not in Path(f).name.lower()]
    upgrade_renamer = get_upgrade_rename_dict(raw_results_dir)

    upgrade_files = upgrade_files[0:1] # TODO ANDREW WUZ HERE remove this

    # Process the baseline simulation outputs
    if not baseline_files:
        print("Error: No baseline files found")
        sys.exit(1)
    if len(baseline_files) > 1:
        print("Error: More than one baseline file found")
        sys.exit(1)

    baseline_file = baseline_files[0]
    print(f"Processing baseline file: {baseline_file}")
    baseline_df = pl.scan_parquet(baseline_file, storage_options=raw_results_dir['storage_options'])

    failed_bldgs = (
        baseline_df.filter(pl.col("completed_status") == "Fail")
        .select(pl.col("building_id"))
        .collect()["building_id"]
        .to_list()
    )
    print(f"Removing {len(failed_bldgs)} buildings that failed in baseline")
    bs_pub_df = process_baseline_simulation_outputs(baseline_df, upgrade_renamer)

    # Find the superset of upgrade.foo columns across all upgrades
    upgrade_col_schema = {}
    for upgrade_file in upgrade_files:
        upgrade_df = pl.scan_parquet(upgrade_file, storage_options=raw_results_dir['storage_options'])
        upgrade_col_schema.update(get_upgrade_columns(upgrade_df))

    # Process and cache the upgrade simulation outputs
    upgrade_ids = [0]
    sim_out_cache_dir = f"{output_dir['fs_path']}/cached_simulation_outputs"
    for upgrade_file in upgrade_files:
        up_info = re.search(r"up(\d+)", Path(upgrade_file).name)
        if up_info is None:
            continue
        upgrade_id = int(up_info.group(1))
        upgrade_ids.append(upgrade_id)
        print(f"Processing upgrade file: {upgrade_file}, upgrade number: {upgrade_id}")
        upgrade_df = pl.scan_parquet(upgrade_file, storage_options=raw_results_dir['storage_options'])
        up_df = process_upgrade_simulation_outputs(
            failed_bldgs, bs_pub_df, upgrade_df, upgrade_id, upgrade_renamer, upgrade_col_schema
        )
        parquet_file_dir = Path(f"{sim_out_cache_dir}/upgrade={upgrade_id}")
        parquet_file = parquet_file_dir / f"cached_simulation_outputs_upgrade{upgrade_id}.parquet"
        if isinstance(output_dir['fs'], s3fs.S3FileSystem):
            parquet_file = f's3://{parquet_file.as_posix()}'
        else:
            Path(parquet_file_dir).mkdir(parents=True, exist_ok=True)
        with output_dir['fs'].open(str(parquet_file), "wb") as f:
            up_df.sink_parquet(f)

        print(f"Cached simulation outputs for upgrade {upgrade_id} to {parquet_file}")
    upgrade_ids.sort()

    # Add savings and weighted columns to baseline and cache
    col_maps = get_col_maps()
    bs_pub_df = add_saving_cols(bs_pub_df, bs_pub_df)  # Intentionally passing base columns twice - zero savings in baseline
    bs_pub_df = add_weighted_cols(bs_pub_df)
    bs_pub_df = add_missing_upgrade_cols(bs_pub_df, upgrade_col_schema)
    bs_pub_df = reorder_columns(bs_pub_df, col_maps)

    upgrade_id = 0
    parquet_file_dir = Path(f"{sim_out_cache_dir}/upgrade={upgrade_id}")
    parquet_file = parquet_file_dir / f"cached_simulation_outputs_upgrade{upgrade_id}.parquet"
    if isinstance(output_dir['fs'], s3fs.S3FileSystem):
        parquet_file = f's3://{parquet_file.as_posix()}'
    else:
        Path(parquet_file_dir).mkdir(parents=True, exist_ok=True)
    with output_dir['fs'].open(str(parquet_file), "wb") as f:
        bs_pub_df.sink_parquet(f)
    print(f"Cached simulation outputs for upgrade {upgrade_id} to {parquet_file}")

    # Define the geographic partitions to export
    geo_exports = [
    {
        'geo_top_dir': 'national',
        'partition_cols': {},
        'data_types': ['full'],  # TODO add basic
        'file_types': ['parquet'], # 'csv',
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


def read_file(file: Path) -> pl.LazyFrame:
    match file.suffix:
        case ".parquet":
            return pl.scan_parquet(file)
        case ".csv":
            return pl.scan_csv(file)
        case ".gz":
            assert file.stem.endswith(".csv"), f"gz file is not a csv: {file}"
            return pl.scan_csv(file)
        case _:
            raise ValueError(f"Unsupported file type: {file}")


def write_file(df: pl.LazyFrame, output_path: Path, upgrade: int):
    parquet_file_dir = output_path / "parquet" / f"upgrade={upgrade}"
    parquet_file_dir.mkdir(parents=True, exist_ok=True)
    parquet_file = parquet_file_dir / f"cached_simulation_outputs_upgrade{upgrade}.parquet"
    df.sink_parquet(parquet_file)
    print(f"Cached simulation outputs for upgrade {upgrade} to {parquet_file}")


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
