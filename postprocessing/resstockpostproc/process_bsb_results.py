#!/usr/bin/env python3
"""
Script to take in raw BuildStockBatch results_csvs / parquet and convert them to pub_annual version.

Example usage:
uv run resstockpostproc/process_bsb_results.py /path/to/bsb_raw_results /path/to/output_dir

Note: bsb_raw_results folder must contain both baseline and upgrade files. Baseline file should be named
results_up00.parquet and upgrade files should be named results_upXX.parquet where XX is the upgrade number. The can
either be in their own folders (baseline and upgrades) or all be in the same folder.
"""

import sys
import polars as pl
from pathlib import Path
from resstockpostproc.process_metadata import (
    publish_baseline_annual_results,
    publish_upgrade_annual_results,
)
import re


def process_results(raw_results_dir: str, output_dir: str) -> None:
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    result_files = list(Path(raw_results_dir).rglob("*"))
    baseline_files = [f for f in result_files if "up00" in f.name.lower()]
    upgrade_files = [f for f in result_files if "up00" not in f.name.lower()]

    if not baseline_files:
        print("Error: No baseline or upgrade files found")
        sys.exit(1)
    if len(baseline_files) > 1:
        print("Error: More than one baseline file found")
        sys.exit(1)

    baseline_file = baseline_files[0]
    print(f"Processing baseline file: {baseline_file}")
    baseline_df = read_file(baseline_file)

    failed_bldgs = (
        baseline_df.filter(pl.col("completed_status") == "Fail")
        .select(pl.col("building_id"))
        .collect()["building_id"]
        .to_list()
    )
    print(f"Removing {len(failed_bldgs)} buildings that failed in baseline")
    bs_pub_df = publish_baseline_annual_results(baseline_df)
    write_file(bs_pub_df, output_path, upgrade=0)

    for upgrade_file in upgrade_files:
        up_info = re.search(r"up(\d+)", upgrade_file.name)
        if up_info is None:
            continue
        upgrade_num = int(up_info.group(1))

        print(f"Processing upgrade file: {upgrade_file}, upgrade number: {upgrade_num}")
        upgrade_df = read_file(upgrade_file)
        up_up_df = publish_upgrade_annual_results(
            failed_bldgs, bs_pub_df, upgrade_df, upgrade_num
        )
        write_file(up_up_df, output_path, upgrade_num)


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
    csv_file_dir = output_path / "results_csvs_pub"
    csv_file_dir.mkdir(parents=True, exist_ok=True)
    csv_file = csv_file_dir / f"results_up{upgrade:02d}.csv"
    parquet_file = parquet_file_dir / f"results_up{upgrade:02d}.parquet"
    df.sink_parquet(parquet_file)
    df.sink_csv(csv_file)
    print(f"Wrote {upgrade} to {parquet_file} and {csv_file}")


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
    process_results(args.raw_results_dir, args.output_dir)
