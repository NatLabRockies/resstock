import polars as pl
from pathlib import Path

data_dir = Path(__file__).parent / "resources" / "income_maps"
bldg_id = "bldg_id"
rep_inc = "in.representative_income"


def process_income_lookup(geography: str, lazy: bool = False) -> tuple[pl.DataFrame, list[str]]:

    deps = [
        "Occupants",
        "Federal Poverty Level",
        "Tenure",
        "Geometry Building Type RECS",
        "Income",
    ]
    match geography:
        case "County and PUMA":
            ext = "CountyandPUMA_Occupants_FederalPovertyLevel_Tenure_GeometryBuildingTypeRECS"
        case "PUMA":
            ext = "PUMA_Occupants_FederalPovertyLevel_Tenure_GeometryBuildingTypeRECS"
        case "State":
            ext = "State_Occupants_FederalPovertyLevel_Tenure_GeometryBuildingTypeRECS"
        case "Census Division":
            ext = "CensusDivision_Occupants_FederalPovertyLevel_Tenure_GeometryBuildingTypeRECS"
        case "Census Region":
            ext = "CensusRegion_Occupants_FederalPovertyLevel_Tenure_GeometryBuildingTypeRECS"
        case "National":
            ext = "Occupants_FederalPovertyLevel_Tenure_GeometryBuildingTypeRECS"
        case "National2":
            ext = "Occupants_FederalPovertyLevel"
            deps = ["Occupants", "Federal Poverty Level", "Income"]
        case _:
            raise ValueError(f"{geography=} not supported")
    file = f"income_bin_representative_values_by_{ext}.parquet"

    if lazy:
        income_lookup = pl.scan_parquet(data_dir / file)
    else:
        income_lookup = pl.read_parquet(data_dir / file)

    if geography not in ["National", "National2"]:
        deps = [geography] + deps

    income_col = "weighted_median"
    income_lookup = income_lookup.select(deps + [pl.col(income_col).round(0)]).drop_nulls()
    income_lookup = income_lookup.rename(lambda col: f"in.{col.lower().replace(' ', '_')}")
    income_lookup = income_lookup.rename({f"in.{income_col}": rep_inc})

    return income_lookup, deps


def assign_representative_income(df: pl.LazyFrame | pl.DataFrame, return_map_only: bool = False) -> pl.LazyFrame:

    lazy = isinstance(df, pl.LazyFrame)

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
    geo_cols = ["in." + geo.lower().replace(" ", "_") for geo in geographies]
    geographies += ["National", "National2"]

    # map rep income by increasingly large geographic resolution
    remaining_df = df.select([bldg_id] + geo_cols + non_geo_cols)
    matched_dfs = []
    for idx, geo in enumerate(geographies):
        income_lookup, deps = process_income_lookup(geo, lazy=lazy)
        match geo:
            case "National":
                keys = non_geo_cols
            case "National2":
                keys = non_geo_cols[:3]
            case _:
                keys = [geo_cols[idx]] + non_geo_cols

        if rep_inc in remaining_df.collect_schema().names():
            remaining_df = remaining_df.drop(rep_inc)

        join_df = remaining_df.join(
            income_lookup,
            on=keys,
            how="left",
        )
        matched_dfs.append(join_df.filter(pl.col(rep_inc).is_not_null()))
        remaining_df = join_df.filter(pl.col(rep_inc).is_null())

        if not lazy:
            if len(remaining_df) == 0:
                print(f"Mapping completed, highest resolution used: {geo}")
                break

    df2 = pl.concat(matched_dfs + [remaining_df])

    # QC
    check_df = df2.filter((pl.col("in.income") != "Not Available") & (pl.col(rep_inc).is_null()))
    check_df = check_df.collect() if lazy else check_df
    assert len(check_df) == 0, f"rep_income could not be mapped for {len(check_df)} rows\n{check_df}"

    print(f"Note: {rep_inc} is not available for vacant units, which have 'Not Available' for in.income")

    df3 = df2.select([bldg_id, rep_inc])
    if return_map_only:
        return df3

    return df.join(df3, on=bldg_id, how="left")
