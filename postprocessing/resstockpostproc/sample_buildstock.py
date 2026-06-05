"""
This script downselect from an existing buildstock.csv based on a list of criteria.

Instructions:
In the configurable parameters section, modify:
1. the `downselect_criteria` function to define the criteria for downselecting the buildstock DataFrame. This function should return a boolean Series indicating which rows meet the criteria.
2. the `MAX_UNITS` parameter to set the maximum number of buildings to include in the downselected buildstock.
3. the `MAINTAIN_PARAMS` parameter. The sampling quota maintains the distribution of the specified columns.

"""

from pathlib import Path
import pandas as pd
import numpy as np

import argparse

from typing import Optional

# --- configurable parameters ---
MAX_UNITS = 10000
MAINTAIN_PARAMS = [
    "ASHRAE IECC Climate Zone 2004",
    # "Gemetry Building Type RECS",
    "Heating Fuel",
    "Geometry Floor Area",
    "Vintage",
]


def downselect_criteria(df: pd.DataFrame) -> pd.Series:
    """
    Define criteria for downselecting the buildstock DataFrame.
    This is a placeholder function and should be modified to include actual criteria.

    Parameters:
        df (pd.DataFrame): The input buildstock DataFrame.

    Returns:
        pd.Series: A boolean Series indicating which rows meet the criteria.
    """
    cond = df["Geometry Building Type RECS"] == "Single-Family Detached"
    cond &= df["HVAC Has Ducts"] == "Yes"
    cond &= df["HVAC Shared Efficiencies"] == "None"

    return cond


# --- end of configurable parameters ---


def calculate_sample_size(
    df2: pd.DataFrame, maintain_params: list[str], max_units: int
) -> pd.Series:
    """Calculate the sample size for each category in the specified columns to ensure a representative sample.
    Parameters:
        df2 (pd.DataFrame): The downselected DataFrame after applying criteria.
        maintain_params (list[str]): Column names to base the sampling on.
        max_units (int): Maximum number of buildings to include in the downselected buildstock.

    Returns:
        pd.Series: A Series with the sample size for each group in the specified columns.
    """
    sample_size = (
        (df2.groupby(maintain_params).size() / len(df2) * max_units)
        .round()
        .astype(int)
        .sort_values(ascending=False)
    )
    delta_samples = sample_size.sum() - max_units

    for i in range(len(sample_size)):
        if delta_samples == 0:
            break
        if delta_samples < 0:
            # add to the smallest category first to meet the max_units target
            j = len(sample_size) - 1 - i
            sample_size.iloc[j] += 1
            delta_samples += 1
        else:
            # remove from the largest category first to meet the max_units target
            sample_size.iloc[i] -= 1
            delta_samples -= 1

    return sample_size


def downselect_buildstock(
    input_path: str,
    output_path: Optional[str] = None,
    max_units: Optional[int] = 10000,
    maintain_params: Optional[list[str]] = None,
    random_state: Optional[int] = 42,
) -> None:
    """Main function to downselect the buildstock DataFrame.
    Parameters:
        input_path (str): Path to the input buildstock.csv file.
        output_path (Optional[str]): Path for the downselected buildstock.csv file.
            If None, it will be saved in the same directory as the input file with a default name.
        max_units (Optional[int]): Maximum number of buildings to include in the downselected buildstock.
        maintain_params (Optional[list[str]]): Column names to base the sampling on to ensure a representative sample.
        random_state (Optional[int]): Random state for reproducibility when sampling.

    Returns:
        None
    """
    if maintain_params is None:
        maintain_params = MAINTAIN_PARAMS

    # Read the existing buildstock.csv into a DataFrame
    df = pd.read_csv(input_path, keep_default_na=False, low_memory=False)

    # Define criteria for downselecting (example: only single-family homes built before 2000)
    criteria = downselect_criteria(df)

    # Apply the criteria to filter the DataFrame
    df2 = df[criteria]

    # Check downselected DataFrame size and limit to max_units if necessary
    msg = f"Downselected buildstock contains {len(df2)} buildings, "
    if len(df2) > max_units:
        print(f"{msg}sampling to meet {max_units=} while maintaining distributions of ")
        print(maintain_params)
        sample_size = calculate_sample_size(df2, maintain_params, max_units)

        df3 = (
            df2.groupby(maintain_params)[df2.columns.difference(maintain_params)]
            .apply(lambda x: x.sample(n=sample_size[x.name], random_state=random_state))
            .reset_index(level=maintain_params)
            .reset_index(drop=True)
        )

        # QC  - check final sample size matches the target sample size for each group
        final_sample_size = (
            df3.groupby(maintain_params)
            .size()
            .sort_values(ascending=False)
            .reindex(sample_size.index)
            .fillna(0)
        )
        diff = sample_size.compare(final_sample_size)
        if not diff.empty:
            print(
                "WARNING: sample_size and final_sample_size differ at the following groups:"
            )
            print(diff)

    else:
        print(f"{msg}which is less than the specified max of {max_units}.")
        df3 = df2

    # Define the path for the new downselected buildstock.csv file
    if output_path is None:
        output_path = Path(input_path).parent / "downselected_buildstock.csv"

    # Save the filtered DataFrame to a new CSV file
    df3.to_csv(output_path, index=False)
    print(f"\n>> Downselected buildstock saved to {output_path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Downselect from an existing buildstock.csv based on a list of criteria."
    )
    parser.add_argument("input", type=str, help="Path to input buildstock.csv file")
    parser.add_argument(
        "--output",
        type=str,
        required=False,
        default=None,
        help="Path for downselected buildstock.csv file",
    )
    parser.add_argument(
        "--max_units",
        type=int,
        required=False,
        default=10000,
        help="Maximum number of buildings to include in the downselected buildstock",
    )
    args = parser.parse_args()

    downselect_buildstock(args.input, output_path=args.output, max_units=args.max_units)
