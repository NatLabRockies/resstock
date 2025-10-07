"""
For oedi-formatted resstock dataset, such as OEDI resstock: 2024.2
Get summary of upgrades:
file_name, upgrade_name, n_units, Occupied, Vacant
"""

import numpy as np
from pathlib import Path
import argparse
from typing import Optional, Literal

import pandas as pd


file_kw = {
    "oedi": "metadata_and_annual_results",
    "pub_annual": "results_up",
    "raw": "results_up",
}

baseline_kw = {
    "oedi": "baseline",
    "pub_annual": "00",
    "raw": "00",
}

vacancy_col = {
    "oedi": "in.vacancy_status",
    "pub_annual": "in.vacancy_status",
    "raw": "build_existing_model.vacancy_status",
}
applicable_col = {
    "oedi": "applicability",
    "pub_annual": "applicability",
    "raw": "apply_upgrade.applicable",
}

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
        return pd.read_csv(
            file, compression="infer", low_memory=False, keep_default_na=False
        )
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


def get_summary(
    file_dir: Path, output_file: Optional[Path] = None,
    file_type: Literal["oedi", "pub_annual", "raw"] = "raw",
    remove_vacant: bool = False,
):
    pattern = file_kw[file_type]
    file_list = sorted(file_dir.rglob("*"+pattern+"*"))
    bl_pattern = baseline_kw[file_type]
    if remove_vacant:
        print(" ** All files are to be modified by removing vacant units in place...")
        baseline_file = [x for x in file_list if bl_pattern in str(x)]
        assert (
            len(baseline_file) == 1
        ), f"Baseline file not found or ambiguous:\n{baseline_file=}"
        file_list = baseline_file + [x for x in file_list if x not in baseline_file]

    vac_col = vacancy_col[file_type]
    ref_table = []
    for file in file_list:
        df = read_file(file)
        file_name = parse_filename(file)
        if bl_pattern in file_name:
            upgrade_name = "baseline"
            cond = df.index
        else:
            upg_names = [
                x
                for x in df["upgrade_name"].dropna().unique()
                if x not in ["", None, np.nan]
            ]
            assert (
                len(upg_names) == 1
            ), f"Difficulty extracting upgrade name: {upg_names}"
            upgrade_name = upg_names[0]
            if file_type == "oedi":
                cond = df.index
            else:
                cond = df[applicable_col[file_type]]==True

        n_app = len(df.loc[cond])
        vacancy_stats = df.loc[cond].groupby([vac_col])["upgrade"].count()
        stats = pd.Series(
            {
                "filename": file_name,
                "upgrade_name": upgrade_name,
                "n_units": len(df),
                "n_applicable": n_app,
            }
        )

        ref_table.append(pd.concat([stats, vacancy_stats]))

        # modify file
        if remove_vacant:
            n1 = len(df)
            df = df.loc[df[vac_col] == "Occupied"]
            n2 = len(df)
            assert n2 > 0, "After removing vacant units, df is empty."
            print(f"   Removed {n1-n2} vacant units, n={n1} -> {n2}")

        # export file
        if remove_vacant:
            save_to_file(df, file)

        print(f"Processed: {file_name}")

    ref_table = pd.concat(ref_table, axis=1).transpose()
    print(ref_table)

    if output_file is None:
        output_file = file_dir / "summary_table.csv"
    ref_table.to_csv(output_file, index=False)

    print(f"Summary table output to: {output_file}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "file_dir",
        action="store",
        help="Path to oedi-formatted resstock results directory",
    )
    parser.add_argument(
        "-o",
        "--output_file",
        type=str,
        help="Path to save the ref_table to. Default to save file to file_dir/'summmary_table.csv'",
    )
    parser.add_argument(
        "-f",
        "--file_type",
        type=str,
        help="Type of result files. Options: 'oedi', 'pub_annual', 'raw' (default).",
    )
    parser.add_argument(
        "-v",
        "--remove_vacant",
        action="store_true",
        default=False,
        help="Whether to modify file(s) in place by removing vacant units",
    )

    args = parser.parse_args()
    file_dir = Path(args.file_dir)
    output_file = args.output_file
    if output_file is not None:
        output_file = Path(output_file)

    get_summary(file_dir, output_file=output_file, file_type=args.file_type, remove_vacant=args.remove_vacant)
