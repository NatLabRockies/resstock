"""
Postprocess representative income to results_up00 csv or parquet file.
The default output is a map containing columns: buiding_id and rep_income
building_ids with failed simulations are excluded in the output map, building_id without a rep_income value is vacant.

A discrete income value is assigned to each income bin based on the cross section of 
occupants, FPL, tenure, building type, and geography, starting from County and PUMA.
Where the lookup is not available, a lower resolution geography is used until all income bins are converted.
The income lookup is weighted median income of the same cross sections derived from 2019-5years ACS PUMS.

This script can be run with resstock-estimation env
To run this script, download data_ami folder from: https://nrel.sharepoint.com/sites/CBldgStock-ResStockC-LEAP/Shared%20Documents/Forms/AllItems.aspx?id=%2Fsites%2FCBldgStock%2DResStockC%2DLEAP%2FShared%20Documents%2FCommunity%20Factsheets%2FDashboards%20and%20Data%2Fdata%5Fami%2Ezip&parent=%2Fsites%2FCBldgStock%2DResStockC%2DLEAP%2FShared%20Documents%2FCommunity%20Factsheets%2FDashboards%20and%20Data
Unzip the folder and place it in line with this script.


Author: lixi.liu@nrel.gov 
Date: 2022-10-06
Updated: 2023-02-20
"""
from pathlib import Path
import sys
import numpy as np
import pandas as pd
from functools import cache
import argparse
from pyarrow import parquet
import csv
import os


data_dir = Path(__file__).resolve().parent / "data_ami"

### Add AMI tags to EUSS
def process_income_lookup(geography):
    """
    geography option: PUMA, State, Census Division

    """
    deps = ["Occupants", "Federal Poverty Level", "Tenure", "Geometry Building Type RECS", "Income"]
    if geography == "County and PUMA":
        ext = "CountyandPUMA_Occupants_FederalPovertyLevel_Tenure_GeometryBuildingTypeRECS"
    elif geography == "PUMA":
        ext = "PUMA_Occupants_FederalPovertyLevel_Tenure_GeometryBuildingTypeRECS"
    elif geography == "State":
        ext = "State_Occupants_FederalPovertyLevel_Tenure_GeometryBuildingTypeRECS"
    elif geography == "Census Division":
        ext = "CensusDivision_Occupants_FederalPovertyLevel_Tenure_GeometryBuildingTypeRECS"
    elif geography == "Census Region":
        ext = "CensusRegion_Occupants_FederalPovertyLevel_Tenure_GeometryBuildingTypeRECS"
    elif geography == "National":
        ext = "Occupants_FederalPovertyLevel_Tenure_GeometryBuildingTypeRECS"
    elif geography == "National2":
        ext = "Occupants_FederalPovertyLevel"
        deps = ["Occupants", "Federal Poverty Level", "Income"]
    else:
        raise ValueError(f"geography={geography} not supported")
    file = f"income_bin_representative_values_by_{ext}.csv"

    income_lookup = pd.read_csv(data_dir / file)
    if geography not in ["National", "National2"]:
        deps = [geography] + deps

    income_col = "weighted_median"
    income_lookup = income_lookup[
        ~income_lookup[deps + [income_col]].isna().any(axis=1)
    ].reset_index(drop=True)[deps + [income_col]]

    income_lookup = income_lookup.rename(columns={income_col: "rep_income"})

    return income_lookup, deps


def assign_representative_income(df, return_map_only=False):
    non_geo_cols = [
        "build_existing_model.occupants",
        "build_existing_model.federal_poverty_level",
        "build_existing_model.income",
        "build_existing_model.tenure",
        "build_existing_model.geometry_building_type_recs",
    ]
    geographies = [
        "County and PUMA",
        "PUMA",
        "State",
        "Census Division",
        "Census Region",
    ]
    geo_cols = [
        "build_existing_model." + geo.lower().replace(" ", "_") for geo in geographies
    ]
    df_section = df[geo_cols + non_geo_cols].copy()
    geographies += ["National", "National2"]

    # map rep income by increasingly large geographic resolution
    for idx, geo in enumerate(geographies):
        income_lookup, deps = process_income_lookup(geo)
        if geo == "National":
            keys = non_geo_cols
        elif geo == "National2":
            keys = non_geo_cols[:3]
        else:
            keys = [geo_cols[idx]] + non_geo_cols

        if idx == 0:
            # map value by County and PUMA
            df_section = df_section.join(
                income_lookup.set_index(deps),
                on=keys,
            )
        else:
            # map remaining value
            df_section.loc[df_section["rep_income"].isna(), "rep_income"] = (
                df_section[keys]
                .astype(str)
                .agg("-".join, axis=1)
                .map(
                    income_lookup.assign(
                        key=income_lookup[deps].astype(str).agg("-".join, axis=1)
                    ).set_index("key")["rep_income"]
                )
            )
            if len(df_section[df_section["rep_income"].isna()]) == 0:
                print(
                    f"Highest resolution used for mapping representative income: {geography}"
                )
                break

    cond = (df_section["build_existing_model.income"]!="Not Available") & (df_section["rep_income"].isna())
    assert len(df_section[cond]) == 0, f"rep_income could not be mapped for {len(df_section[cond])=} rows\n{df_section.loc[cond]}"

    df["rep_income"] = df_section["rep_income"].round(0)
    print("Note: rep_income is not available for vacant units, which have 'Not Available' for Income.")

    if return_map_only:
        return df[["building_id", "rep_income"]]

    return df


def _fix_dtypes(df):
    df["building_id"] = df["building_id"].astype(int)
    for col in df.columns:
        if col.startswith("build_existing_model."):
            x = df[col].astype(str)
            try:
                df[col] = x.astype(int).astype(str)
            except ValueError:
                try:
                    df[col] = x.astype(float)
                except ValueError:
                    df[col] = x
    return df


def _retain_valid_only(df):
    print("Retaining successfully simulated building_id only.")
    return df.loc[df["completed_status"] == "Success"].reset_index(drop=True)


def read_file(file_path: Path, headers_only=False, valid_only=False, fix_dtypes=False, columns=None):
    file_type = file_path.suffix
    if file_type == ".csv":
        if headers_only:
            with open(file_path, 'r') as f:
                reader = csv.DictReader(f)
                return reader.fieldnames

        df = pd.read_csv(file_path, low_memory=False, keep_default_na=False, usecols=columns)
        if fix_dtypes:
            df = _fix_dtypes(df)
        if valid_only:
            df = _retain_valid_only(df)
        return df

    if file_type == ".parquet":
        if headers_only:
            return parquet.read_schema(file_path).names

        df = pd.read_parquet(file_path, columns=columns)
        if fix_dtypes:
            df = _fix_dtypes(df)
        if valid_only:
            df = _retain_valid_only(df)
        return df

    raise TypeError(f"file_type={file_type} not supported")


def get_columns():
    return [
        "building_id",
        "completed_status",
        "build_existing_model.occupants",
        "build_existing_model.federal_poverty_level",
        "build_existing_model.tenure",
        "build_existing_model.geometry_building_type_recs",
        "build_existing_model.income",
        "build_existing_model.county_and_puma",
        "build_existing_model.puma",
        "build_existing_model.state",
        "build_existing_model.census_division",
        "build_existing_model.census_region",
    ]


def write_to_file(df, file_path: Path):
    file_type = file_path.suffix
    if file_type == ".csv":
        df.to_csv(file_path, index=False)
    elif file_type == ".parquet":
        df.to_parquet(file_path)
    else:
        raise TypeError(f"file_type={file_type} not supported")
    print(f"File saved to: {file_path}")


def generate_rep_income(file_path, add_to_file=False):

    if add_to_file:
        return_map_only = False
        msg = "Adding rep_income to result file..."
    else:
        return_map_only = True
        msg = "Creating map of rep_income by building_id..."

    print(
        "=============================================================================="
    )
    print(
        "This script adds representative income to ResStock annual summary file using \n"
        "a weighted median income lookup derived from 2019 5yrs ACS PUMS data. The \n"
        "lookup provides income diversity based on Occupants, Federal Poverty Level, \n"
        "Tenure, Geometry Building Type RECS, and geography. Geographic resolution \n"
        "starts at County and PUMA. Where the lookup is not availble, the next smallest \n"
        "geographic resolution is used. "
    )
    print(
        f"""
        {file_path}
        """
    )
    print(msg)
    print(
        "=============================================================================="
    )

    file_path = Path(file_path)
    columns = read_file(file_path, headers_only=True)
    if len([col for col in columns if "build_existing_model." in col]) == 0:
        print(f"file={file_path} is not a results_up00 file, exiting")
        sys.exit(1)

    columns = get_columns()
    df = read_file(file_path, valid_only=True, fix_dtypes=False, columns=columns)
    df = assign_representative_income(df, return_map_only=return_map_only)

    df = df.sort_values(by=["building_id"])
    if add_to_file:
        output_file_path = file_path
    else:
        output_file_path = file_path.parent / (file_path.stem+"__rep_income_map.csv")
    write_to_file(df, output_file_path)


def main():
    """
    Usage: python add_rep_income_to_annual_summary.py path_to_annual_result_file
    """
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "result_file",
        help=f"path to ResStock annual result summary file (csv or parquet)",
    )
    parser.add_argument(
        "-a",
        "--add_to_file",
        action="store_true",
        default=False,
        help="Add rep_income column to result file and save in place. Default to false, where a map of rep_income by building_id is exported",
    )
    args = parser.parse_args()
    generate_rep_income(args.result_file, add_to_file=args.add_to_file)


if __name__ == "__main__":
    main()
