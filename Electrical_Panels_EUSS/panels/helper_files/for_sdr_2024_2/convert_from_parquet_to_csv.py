"""
For oedi-formatted resstock dataset, such as OEDI resstock: 2024.2
Convert parquet files to csvs and save to a new directory with suffix "_csv"
"""
import numpy as np
from pathlib import Path
import argparse
from typing import Optional

import pandas as pd

def parse_filename(file):
    suffixes = file.suffixes
    assert suffixes != [], f"{file=} has no suffixes."
    suffix = "".join(suffixes)
    file_name = file.stem.removesuffix(suffix)
    return file_name

def parse_suffix(file):
    suffixes = file.suffixes
    assert suffixes != [], f"{file=} has no suffixes."
    suffix = "".join(suffixes)
    return suffix

def read_file(file):
    suffix = parse_suffix(file)
    if suffix == ".csv" or suffix == ".csv.gz":
        return pd.read_csv(file, compression="infer", low_memory=False, keep_default_na=False)
    if suffix == ".parquet":
        return pd.read_parquet(file)
    raise ValueError(f"Unsupported {suffix=}")

def save_to_file(df, file):
    suffix = parse_suffix(file)
    if suffix == ".csv" or suffix == ".csv.gz":
        df.to_csv(file, compression="infer", index=False)
        return
    if suffix == ".parquet":
        df.to_parquet(file)
        return
    raise ValueError(f"Unsupported {suffix=}")

def convert_files(file_dir: Path):
    out_dir = file_dir.parent / (file_dir.stem + "_csv")
    out_dir.mkdir(parents=True, exist_ok=True)
    file_list = sorted(file_dir.glob("*.parquet"))
    for file in file_list:
        df = read_file(file)
        file_name = parse_filename(file)
        df.to_csv(out_dir / (file_name+".csv"))
        print(f" - Converted: {file_name}")

    print(f"Files saved to: {out_dir}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "file_dir",
        action="store",
        help="Path to oedi-formatted resstock results directory"
        )

    args = parser.parse_args()
    file_dir = Path(args.file_dir)

    convert_files(file_dir)
