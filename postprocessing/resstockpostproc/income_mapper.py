import polars as pl
from pathlib import Path

data_dir = Path(__file__).parent / "resources" / "income_maps"
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
    file = f"income_bin_representative_values_by_{ext}.parquet"

    income_lookup = pl.read_parquet(data_dir / file)
    if geography not in ["National", "National2"]:
        deps = [geography] + deps

    income_col = "weighted_median"
    income_lookup = income_lookup.select(deps + [income_col]).drop_nulls()
    income_lookup = income_lookup.rename(lambda col: f"in.{col.lower().replace(' ', '_')}")
    income_lookup = income_lookup.rename({f"in.{income_col}": "rep_income"})

    return income_lookup, deps

def assign_representative_income(df, return_map_only=False):
    non_geo_cols = [
        "in.occupants",
        "in.federal_poverty_level",
        "in.income",
        "in.tenure",
        "in.geometry_building_type_recs",
    ]
    geographies = [
        "County and PUMA",
        "PUMA",
        "State",
        "Census Division",
        "Census Region",
    ]
    geo_cols = [
        "in." + geo.lower().replace(" ", "_") for geo in geographies
    ]
    df = df.select(geo_cols + non_geo_cols)
    geographies += ["National", "National2"]

    # map rep income by increasingly large geographic resolution
    remaining_df = df
    matched_dfs = []
    for idx, geo in enumerate(geographies):
        income_lookup, deps = process_income_lookup(geo)
        if geo == "National":
            keys = non_geo_cols
        elif geo == "National2":
            keys = non_geo_cols[:3]
        else:
            keys = [geo_cols[idx]] + non_geo_cols

        # map value by County and PUMA
        join_df = remaining_df.join(
            income_lookup,
            on=keys,
            how="left",
        )
        matched_dfs.append(join_df.filter(pl.col("rep_income").is_not_null()))
        remaining_df = join_df.filter(pl.col("rep_income").is_null())
    

    cond = (df["build_existing_model.income"]!="Not Available") & (df["rep_income"].isna())
    assert len(df[cond]) == 0, f"rep_income could not be mapped for {len(df[cond])=} rows\n{df.loc[cond]}"

    df["rep_income"] = df["rep_income"].round(0)
    print("Note: rep_income is not available for vacant units, which have 'Not Available' for Income.")

    if return_map_only:
        return df[["building_id", "rep_income"]]

    return df