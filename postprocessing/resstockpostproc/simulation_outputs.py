from collections.abc import Sequence

import datetime
import polars as pl
import pathlib
import geopandas as gpd
import logging
import s3fs
import json
import re
from collections import defaultdict


from resstockpostproc.utils import (
    col_name_to_intensity,
    col_name_to_savings,
    fix_site_energy_total,
    fix_all_fuels_emissions,
    get_col_maps,
    conversion_factor
)
from resstockpostproc.income_mapper import assign_representative_income
from resstockpostproc.allocated_weights import get_allocated_weights_plus_util_bills_for_upgrade

logger = logging.getLogger(__name__)

def get_failed_bldgs(metadata_df: pl.LazyFrame) -> set[int]:
    failed_bldgs = metadata_df.filter(pl.col("completed_status") == "Fail")
    failed_bldgs = failed_bldgs.select(pl.col("building_id"))
    return set(failed_bldgs.collect()["building_id"].to_list())


def process_simulation_outputs(
    baseline_failed_bldgs: set[int],
    base_raw_df: pl.LazyFrame,
    base_proc_df: pl.LazyFrame,
    upgrade_raw_df: pl.LazyFrame,
    upgrade_num: int,
    upgrade_renamer: dict[str, str],
    upgrade_col_schema: dict[str, str]
) -> pl.LazyFrame:
    """
    Publishes the annual results for a specific upgrade.

    Args:
        baseline_failed_bldgs: Set of failed building IDs in baseline.
        base_proc_df: LazyFrame containing baseline results already passed through process_baseline_simulation_outputs.
        upgrade_raw_df: LazyFrame containing upgrade results from raw BuildStockBatch results.
        upgrade_num: Integer representing the upgrade number.
    Returns:
        LazyFrame containing published upgrade results.
    """

    is_baseline = (upgrade_num == 0)
    col_maps = get_col_maps()

    df = upgrade_raw_df
    df = set_baseline_applicability(df, is_baseline)
    df = add_missing_cols_from_baseline_to_upgrade(df, base_raw_df, is_baseline)
    df = remove_failed_baseline_buildings(df, baseline_failed_bldgs)
    df = remove_na_or_failed_buildings(df)
    df = replace_missing_buildings_with_baseline(df, base_raw_df, is_baseline)
    df = downselect_and_rename_cols(df, col_maps)  # Per sdr_column_definitions.csv
    df = add_county_column(df)
    df = add_puma_column(df)
    df = add_baseline_upgrade_name_col(df, is_baseline)
    df = add_upgrade_id_col(df, upgrade_num)
    df = rename_upgrades(df, upgrade_renamer)
    df = fix_site_energy_total(df)
    df = add_upgrade_foo_cols(df)
    df = add_panel_contraint_cols(df)
    df = fix_all_fuels_emissions(df)
    df = downselect_fuel_emissions_cols(df)

    if is_baseline:  # noqa: SIM108
        df = add_saving_cols(df, df)  # Intentionally calculate savings = baseline - baseline = 0
    else:
        df = add_saving_cols(df, base_proc_df)

    df = add_intensity_cols(df)
    df = add_missing_upgrade_cols(df, upgrade_col_schema)
    df = adjust_col_dtypes(df)
    df = df.sort("bldg_id")
    return df


def get_schema_superset(upgrade_files: list, files_dir) -> dict:
    upgrade_col_schema = {}
    for upgrade_file in upgrade_files:
        # Add s3:// prefix for polars if using S3
        if files_dir["storage_options"] is not None:
            file_path = f"s3://{upgrade_file}"
        else:
            file_path = upgrade_file
        upgrade_df = pl.scan_parquet(file_path, storage_options=files_dir["storage_options"])
        upgrade_col_schema.update(get_upgrade_columns(upgrade_df))
    return upgrade_col_schema


def set_baseline_applicability(df: pl.LazyFrame, is_baseline: bool) -> pl.LazyFrame:
    if not is_baseline:
        # Non-baseline upgrades already have an applicability column
        return df
    print("Setting applicability to True for all baseline buildings")
    df = df.with_columns(pl.lit(True).alias("applicability"))
    return df


def remove_failed_baseline_buildings(df: pl.LazyFrame, baseline_failed_bldgs: set[int],) -> pl.LazyFrame:
    print("Removing buildings that failed in the baseline")
    df = df.filter(
        ~pl.col("building_id").is_in(baseline_failed_bldgs)
    )
    return df


def remove_na_or_failed_buildings(df: pl.LazyFrame) -> pl.LazyFrame:
    print("Removing buildings that failed in this upgrade or where the upgrade was not applicable")
    df = df.filter(pl.col("completed_status") == "Success")
    return df


def get_failed_building_list(df: pl.LazyFrame, ) -> list[int]:
    print("Getting failed building list")
    failed_bldgs = (
        df.filter(pl.col("completed_status") != "Success")
        .select(pl.col("building_id"))
        .collect()["building_id"]
        .to_list()
    )
    return failed_bldgs


def add_upgrade_id_col(df: pl.LazyFrame, upgrade_id: int) -> pl.LazyFrame:
    df = df.with_columns([pl.lit(upgrade_id).alias("upgrade")])
    return df


def add_baseline_upgrade_name_col(df: pl.LazyFrame, is_baseline: bool) -> pl.LazyFrame:
    if not is_baseline:
        # Upgrades already have an upgrade name column
        return df
    df = df.with_columns([pl.lit("Baseline").alias("in.upgrade_name")])
    return df


def add_missing_cols_from_baseline_to_upgrade(upgrade_df: pl.LazyFrame, baseline_df: pl.LazyFrame,
        is_baseline: bool) -> pl.LazyFrame:
    if is_baseline:
        # Baseline already has all the columns, no need to add
        return upgrade_df
    print("Adding missing columns from baseline to upgrade")
    base_cols = baseline_df.collect_schema().names()
    upgrade_cols = upgrade_df.collect_schema().names()
    missing_cols = [c for c in list(set(base_cols) - set(upgrade_cols)) + ["building_id"]]
    upgrade_df = upgrade_df.join(baseline_df.select(missing_cols), on="building_id", how="left")
    return upgrade_df


def replace_missing_buildings_with_baseline(upgrade_df: pl.LazyFrame, baseline_df: pl.LazyFrame,
        is_baseline: bool) -> pl.LazyFrame:
    if is_baseline:
        # Baseline determines the full set of buildings, will never be missing any by definition
        return upgrade_df
    print("Replacing buildings missing from the upgrade with baseline data")
    # All buildings present in the upgrade_df are there because the upgrade was applicable to them
    upgrade_df = upgrade_df.with_columns(pl.lit(True).alias("applicability"))
    upgrade_name_df = upgrade_df.select(pl.col("apply_upgrade.upgrade_name").first())
    # Keep only successful buildings from the baseline
    baseline_successful_df = baseline_df.filter(pl.col("completed_status") == "Success")
    missing_bldgs_df = baseline_successful_df.join(
        upgrade_df,
        on="building_id",
        how="anti",  # Keep rows from "base" with no match in "upgrade"
    )
    missing_bldgs_df = missing_bldgs_df.with_columns(
        [
            pl.lit(False).alias("applicability"),  # Missing buildings are missing b/c upgrade wasn't applicable
        ]
    ).drop("apply_upgrade.upgrade_name")
    missing_bldgs_df = missing_bldgs_df.join(upgrade_name_df, how="cross")
    upgrade_df = pl.concat([upgrade_df, missing_bldgs_df], how="diagonal_relaxed")
    base_ids = set(baseline_successful_df.select("building_id").collect().to_series().to_list())
    up_ids = set(upgrade_df.select("building_id").collect().to_series().to_list())
    assert base_ids == up_ids, f"{len(base_ids)} buildings in baseline, {len(up_ids)} in upgrade"
    print(f"{len(base_ids)} buildings in baseline, {len(up_ids)} in upgrade")
    return upgrade_df


def downselect_and_rename_cols(df: pl.LazyFrame, col_maps: Sequence[dict]) -> pl.LazyFrame:
    print("Downselecting and renaming columns from raw simulation outputs per sdr_column_definitions.csv")
    transformed_cols = ["applicability"]  # Special case
    all_cols = df.collect_schema().names()
    for col_map in col_maps:
        if col_map["column_type"] not in ["Input", "Output"]:
            continue
        if col_map["import_from_raw"] != "yes":
            continue
        assert col_map["column_name"] is not None, "ResStock column name must be provided for Input or Output columns"
        if col_map["column_name"] not in all_cols:
            continue
        if col_map["conversion_factor"]:
            new_col = (pl.col(col_map["column_name"]).cast(pl.Float64) * float(col_map["conversion_factor"])).alias(
                col_map["published_name"]
            )
        else:
            new_col = pl.col(col_map["column_name"]).alias(col_map["published_name"])
        transformed_cols.append(new_col)

    upgrade_cols = [col for col in all_cols if col.startswith("upgrade_costs.") and col.endswith("_name")]
    transformed_cols.extend([pl.col(col).alias(col) for col in upgrade_cols])
    return df.select(transformed_cols)


def get_upgrade_rename_dict(raw_results_dir):
    # Use string concatenation with forward slashes for S3 paths instead of pathlib
    fs_path = raw_results_dir["fs_path"]
    if isinstance(fs_path, pathlib.Path):
        file_path = fs_path / "rename_upgrades.json"
    else:
        # For S3 paths, use forward slashes
        file_path = f"{fs_path}/rename_upgrades.json"
    if not raw_results_dir["fs"].exists(file_path):
        return dict()
    with raw_results_dir["fs"].open(file_path, "r") as f:
        upgrade_renamer = json.load(f)
    return upgrade_renamer


def rename_upgrades(df: pl.LazyFrame, upgrade_renamer: dict) -> pl.LazyFrame:
    """
    Renames the upgrades in the in.upgrade_name column from values used in the YML file
    to new values more appropriate for publication. If an empty dict is supplied, no
    renaming is performed.

    Args:
        base_raw_df: LazyFrame containing the results.
        upgrade_renamer: Map of upgrade names from YML to new names for publication.
    Returns:
        LazyFrame containing results with modified in.upgrade_name column values.
    """
    if not upgrade_renamer:
        print("No upgrade renamer was supplied, upgrades not renamed.")
        return df
    else:
        print("Renaming upgrades")
        # for old, new in upgrade_renamer.items():
        #     print(f"{old} -> {new}")

    # Check that each upgrade name is present in the upgrade renamer dict
    up_names = df.select(pl.col("in.upgrade_name")).unique().collect().to_series().to_list()
    for up_name in up_names:
        if up_name not in upgrade_renamer:
            raise ValueError(f"No upgrade rename supplied for: {up_name}")

    df = df.with_columns((pl.col("in.upgrade_name").replace(upgrade_renamer)).alias("in.upgrade_name"))
    return df


def add_income_and_burden(df: pl.LazyFrame) -> pl.LazyFrame:
    df = assign_representative_income(df)
    income_col = "in.representative_income"

    # With multiple bill scenarios, this column is comma-separated; retain just the first entry
    df = df.with_columns(
        pl.col("in.utility_bill_electricity_marginal_rates").str.split(",").list.first().str.strip_chars()
    )

    # Reassign negative or zero dollar income to 1 dollar
    adj_income = pl.when(pl.col(income_col) <= 0).then(pl.lit(1)).otherwise(pl.col(income_col)).alias(income_col)

    # Calculate burden only when income is not null and positive
    # Subtract out the EV portion of the utility bill, otherwise this skews the
    # energy burden values for all EV-owning households.
    # Removing transportation aligns with the DOE definition
    # https://www.energy.gov/scep/low-income-energy-affordability-data-lead-tool
    dol_per_kwh = "in.utility_bill_electricity_marginal_rates"
    ev_kwh = "out.electricity.ev_charging.energy_consumption..kwh"
    burden = (
        pl.when(adj_income.is_not_null())
        .then(
            (
            pl.col("out.utility_bills.total_bill..usd") -
            ((pl.col(dol_per_kwh).cast(pl.Float64))*pl.col(ev_kwh))
            )
            / adj_income * 100)
        .otherwise(None)
        .alias("out.energy_burden..percentage")
    )

    return df.with_columns([adj_income, burden])


def add_saving_cols(df: pl.LazyFrame, baseline_df: pl.LazyFrame) -> pl.LazyFrame:
    print("Adding savings columns")
    savings_cols = []
    all_cols = df.collect_schema().names()
    out_cols = [col for col in all_cols if "out." in col and not (
        "out.params" in col or
        "out.panel" in col or
        "out.capacity" in col or
        "out.unmet_hours.ev" in col
        )]
    # Selectively include the following for params
    out_panel_cols = [col for col in all_cols if
        "out.params.panel_load_total_load" in col
        or "out.params.panel_load_occupied_capacity" in col
        or "out.params.panel_breaker_space_occupied" in col
    ]
    out_cols += out_panel_cols
    # print("Columns to calculate savings for (from up_df):")
    # for c in sorted(out_cols):
    #     print(c)
    all_base_cols = baseline_df.collect_schema().names()
    for c in out_cols:
        if c not in all_base_cols:
            print(f"ERROR: {c} is in upgrade but not baseline df, cannot calc savings for this column")
    baseline_df_with_renamed = baseline_df.select(
        [pl.col(col).alias(f"baseline_{col}") for col in out_cols] + ["bldg_id"]
    )
    df_with_baseline = df.join(baseline_df_with_renamed, on="bldg_id", how="left")
    for col in out_cols:
        new_col = col_name_to_savings(col)
        saving_col = (pl.col(f"baseline_{col}") - pl.col(col)).alias(new_col)
        savings_cols.append(saving_col)
    df = df_with_baseline.with_columns(savings_cols).drop([f"baseline_{col}" for col in out_cols])

    return df


def add_intensity_cols(df: pl.LazyFrame) -> pl.LazyFrame:
    print("Adding intensity columns")
    all_cols = df.collect_schema().names()
    int_cols = [col for col in all_cols if "out." in col and (
        ".energy_consumption" in col or
        ".energy_savings" in col
        )]

    for col in int_cols:
        new_units = "kwh_per_ft2"
        wtd_col_name = col_name_to_intensity(col, new_units)
        df = df.with_columns(
            pl.col(col)
            .truediv(pl.col("in.sqft..ft2"))
            .alias(wtd_col_name)
        )

    return df


def add_panel_contraint_cols(df: pl.LazyFrame) -> pl.LazyFrame:
    print("Adding panel constraint columns")
    all_cols = df.collect_schema().names()
    amp_prefix = "out.params.panel_load_headroom_capacity."
    amp_cols = [col for col in all_cols if amp_prefix in col]
    space_col = "out.params.panel_breaker_space_headroom_count"

    out_space_col = "out.params.panel_constraint_breaker_space"
    space_constraint = pl.when(pl.col(space_col) < 0).then(True).otherwise(False).alias(out_space_col)
    ind_constraints = [space_constraint]
    overall_constraint = None
    for amp_col in amp_cols:
        nec_method = amp_col.removeprefix(amp_prefix).removesuffix("..a")
        out_amp_col = "out.params.panel_constraint_capacity." + nec_method
        amp_constraint = pl.when(pl.col(amp_col) < 0).then(True).otherwise(False).alias(out_amp_col)
        ind_constraints.append(amp_constraint)

        out_overall_col = "out.params.panel_constraint_overall." + nec_method
        overall_constraint = pl.coalesce(
            pl.when(pl.col(out_amp_col) & pl.col(out_space_col)).then(pl.lit("Capacity and Space Constrained")),
            pl.when(pl.col(out_amp_col) & ~pl.col(out_space_col)).then(pl.lit("Capacity Constrained Only")),
            pl.when(~pl.col(out_amp_col) & pl.col(out_space_col)).then(pl.lit("Space Constrained Only")),
            pl.lit("No Constraint"),
        ).alias(out_overall_col)

    new_df = df.with_columns(ind_constraints)
    if overall_constraint is not None:
        new_df = new_df.with_columns(overall_constraint)  # needs to be sequential

    return new_df


def add_county_column(df: pl.LazyFrame):
    """
    Changes the county column to the FIPS code and adds a county name column.
    """
    print("Adding county column")
    here = pathlib.Path(__file__).resolve().parent
    county_map_df = pl.read_csv(
        here / "resources" / "gisdata" / "county_lookup_table.csv",
        columns=["long_name", "original_FIP"],
    ).select(pl.col("long_name"), pl.col("original_FIP").alias("county_fip"))
    county_map = dict(county_map_df.iter_rows())

    df = df.with_columns(
        [
            pl.col("in.as_simulated_county").str.split(",").list.get(1).str.replace(r"^\s+|\s+$", "").alias("in.as_simulated_county_name"),
            pl.col("in.as_simulated_county").replace(county_map).alias("in.as_simulated_county"),
        ]
    )
    return df


def add_puma_column(df: pl.LazyFrame):
    """
    Changes the puma column to the GISJOIN code.
    """
    print("Adding PUMA column")
    here = pathlib.Path(__file__).resolve().parent
    pumas = gpd.read_file(here / "resources" / "gisdata" / "ipums_pums_2010_simple_t100_area_us_puma.geojson")
    puma_map = pumas[["GISJOIN", "puma_tsv"]].set_index("puma_tsv")["GISJOIN"].to_dict()
    df = df.with_columns([pl.col("in.as_simulated_puma").replace(puma_map).alias("in.as_simulated_puma")])
    return df


# def remove_unused_as_simulated_geog_cols(df: pl.LazyFrame):
#     """
#     Removes all as-simulated geography columns 
#     """
#     print("Renaming geography columns as simulated")

#     # as-simulated columns in ComStock that are imported
#     # in.as_simulated_census_division_name
#     # in.as_simulated_ashrae_iecc_climate_zone_2006
#     # in.as_simulated_nhgis_county_gisjoin
#     # in.as_simulated_nhgis_puma_gisjoin
#     # in.as_simulated_nhgis_tract_gisjoin
#     # in.as_simulated_state_name
#     # in.as_simulated_weather_file_2018
#     # in.as_simulated_weather_file_tmy3
#     # in.as_simulated_nhgis_state_gisjoin



#     # Variables needed by the apportionment sampling regime
#     SAMPLING_REGION = 'in.sampling_region_id'

# Geography columns in resstock
# ahs_region
# aiannh_area
# ashrae_iecc_climate_zone_2004
# ashrae_iecc_climate_zone_2004_sub_cz_split
# building_america_climate_zone
# cec_climate_zone
# census_division
# census_division_recs
# census_region
# city
# county
# county_and_puma
# county_metro_status
# custom_state
# energystar_climate_zone_2023
# federal_poverty_level
# iso_rto_region
# location_region
# metropolitan_and_micropolitan_statistical_area
# puma
# puma_metro_status
# state
# state_metro_median_income
# weather_file_city
# weather_file_latitude
# weather_file_longitude

#     # Geography-defining columns
#     COLS_GEOG = [
#         'in.as_simulated_nhgis_tract_gisjoin',
#         'in.as_simulated_nhgis_county_gisjoin',
#         'in.as_simulated_nhgis_state_gisjoin',
#         'in.as_simulated_census_division_name',
#         'in.as_simulated_ashrae_iecc_climate_zone_2006',
#         'in.as_simulated_weather_file_2018',
#         'in.as_simulated_weather_file_tmy3',
#         'in.ashrae_iecc_climate_zone_2006',
#         'in.ashrae_or_cec_climate_zone',
#         'in.cec_climate_zone',
#         'in.building_america_climate_zone',
#         'in.cambium_grid_region',
#         'in.census_division_name',
#         'in.census_region_name',
#         'in.iso_rto_region',
#         'in.nhgis_county_gisjoin',
#         'in.nhgis_puma_gisjoin',
#         'in.nhgis_tract_gisjoin',
#         'in.reeds_balancing_area',
#         'in.county_name',
#         'in.nhgis_state_gisjoin',
#         'in.state',
#         'in.state_name',
#         'in.cluster_id',
#         'in.cluster_name',
#         'in.weather_file_2018',
#         'in.weather_file_tmy3',
#         'in.ejscreen_census_tract_percentile_for_demographic_index',
#         'in.ejscreen_census_tract_percentile_for_people_of_color',
#         'in.cejst_is_disadvantaged',
#         'in.ejscreen_census_tract_percentile_percent_people_under_5',
#         'in.ejscreen_census_tract_percentile_for_less_than_hs_educ',
#         'in.ejscreen_census_tract_percentile_for_low_income',
#         'in.ejscreen_census_tract_percentile_for_people_over_64',
#         'in.ejscreen_census_tract_percentile_for_people_in_ling_isol',
#     ]
#     as_sim_geog_cols_to_keep = [
#         'in.as_simulated_nhgis_county_gisjoin',
#         'in.as_simulated_nhgis_tract_gisjoin',
#         'in.as_simulated_nhgis_state_gisjoin',
#         'in.as_simulated_census_division_name',
#         'in.as_simulated_ashrae_iecc_climate_zone_2006',
#         'in.as_simulated_weather_file_2018',
#         'in.as_simulated_weather_file_tmy3'
#     ]
#     geog_cols_to_remove = []
#     for geog_col in COLS_GEOG:
#         if geog_col not in data.columns:
#             continue
#         if geog_col not in as_sim_geog_cols_to_keep:
#             geog_cols_to_remove.append(geog_col)
#     logger.debug('geog_cols_to_remove')
#     logger.debug(geog_cols_to_remove)
#     data = data.drop(geog_cols_to_remove)


def get_upgrade_columns(lf: pl.LazyFrame) -> list:
    upgrade_cols = [c for c in lf.collect_schema().names() if c.startswith("upgrade_costs.") and c.endswith("_name")]
    if not upgrade_cols:
        return []
    upgrade_lf = lf.select(["building_id"] + upgrade_cols)
    upgrade_df = (
        upgrade_lf.unpivot(
            index="building_id",
            on=upgrade_cols,
            variable_name="in.upgrade_name",
            value_name="upgrade_value",
        )
        .drop_nulls("upgrade_value")
        .filter(pl.col("upgrade_value") != "")
        .with_columns(
            pl.col("upgrade_value").str.split_exact("|", 1).struct.rename_fields(["upgrade_key", "upgrade_value"])
        )
        .unnest("upgrade_value")
        .collect()
        .group_by(["building_id", "upgrade_key"])
        .agg(pl.col("upgrade_value").first())
        .pivot(index="building_id", columns="upgrade_key", values="upgrade_value")
    )
    upgrade_df = upgrade_df.rename(
        {c: f"upgrade.{c.lower().replace(" ", "_")}" for c in upgrade_df.columns if c != "building_id"}
    )
    return upgrade_df.drop("building_id").schema


def add_upgrade_foo_cols(lf: pl.LazyFrame) -> pl.LazyFrame:
    upgrade_cols = [c for c in lf.collect_schema().names() if c.startswith("upgrade_costs.") and c.endswith("_name")]
    if not upgrade_cols:
        return lf
    print("Adding upgrade columns from this upgrade")
    upgrade_lf = lf.select(["bldg_id"] + upgrade_cols)
    upgrade_df = (
        upgrade_lf.unpivot(
            index="bldg_id",
            on=upgrade_cols,
            variable_name="in.upgrade_name",
            value_name="upgrade_value",
        )
        .drop_nulls("upgrade_value")
        .filter(pl.col("upgrade_value") != "")
        .with_columns(
            pl.col("upgrade_value").str.split_exact("|", 1).struct.rename_fields(["upgrade_key", "upgrade_value"])
        )
        .unnest("upgrade_value")
        .collect()
        .group_by(["bldg_id", "upgrade_key"])
        .agg(pl.col("upgrade_value").first())
        .pivot(index="bldg_id", columns="upgrade_key", values="upgrade_value")
    )
    upgrade_df = upgrade_df.rename(
        {c: f"upgrade.{c.lower().replace(" ", "_")}" for c in upgrade_df.columns if c != "bldg_id"}
    )
    return lf.drop(upgrade_cols).join(upgrade_df.lazy(), on="bldg_id", how="left")


def add_missing_upgrade_cols(df: pl.LazyFrame, upgrade_col_schema: dict) -> pl.LazyFrame:
    print("Adding upgrade columns from superset across all upgrades")
    all_cols = df.collect_schema().names()
    for col_name, col_dtype in upgrade_col_schema.items():
        if not col_name.startswith("upgrade."):
            continue
        if col_name in all_cols:
            continue
        df = df.with_columns(
            pl.lit(None).cast(col_dtype).alias(col_name)
        )
    return df


def adjust_col_dtypes(df: pl.LazyFrame) -> pl.LazyFrame:
    print("Adjusting column dtypes")
    # Upgrade ID must be Athena bigint (np.int64)
    df = df.with_columns(pl.col("upgrade").cast(pl.Int64))
    return df


def downselect_fuel_emissions_cols(df: pl.LazyFrame):
    """

    for each scenario
        out.emissions.electricity.total.lrmer_lowrecost_15..co2e_kg (This actually uses the net column from the raw result)
        out.emissions.electricity.total.aer_lowrecosthighngprice_avg..co2e_kg

    Downselect to just one column for natural gas, propane, and fuel oil emissions
    because
    out.emissions.natural_gas.lrmer_low_re_cost_high_ng_price_25..co2e_kg --> out.emissions.natural_gas.total..co2e_kg
    out.emissions.fuel_oil.lrmer_low_re_cost_high_ng_price_25..co2e_kg --> out.emissions.fuel_oil.total..co2e_kg
    out.emissions.propane.lrmer_low_re_cost_high_ng_price_25..co2e_kg --> out.emissions.propane.total..co2e_kg

    out.emissions.total.lrmer_midcase_15..co2e_kg (total for a scenario)
    """
    print("Downselecting fuel emissions to one scenario")
    all_cols = df.collect_schema().names()

    fuel_emissions_re = re.compile(r"^out\.emissions\.(natural_gas|fuel_oil|propane).(\w+)..co2e_kg")
    scenario2cols = defaultdict(list)
    for col in all_cols:
        if (match := re.search(fuel_emissions_re, col)):
            scenario2cols[match[2]].append(col)

    for i, s2c in enumerate(scenario2cols.items()):
        scenario, cols = s2c
        if i == 0:  # noqa: SIM108
            # Keep the first scenario's columns and rename them
            df = df.rename({col: col.replace(scenario, "total") for col in cols})
            # for col in cols:
            #     print(f"Renaming {col} to {col.replace(scenario, "total")}")
        else:
            # Delete the fuel emissions columns for all other scenarios
            df = df.drop(cols)
            # print(f"Dropping: {cols}")
    return df


def downselect_and_order_pub_cols(lf: pl.LazyFrame, col_maps: Sequence[dict]):
    print("Reordering columns and checking for missing/extra columns")
    # verify that all the columns in lf are one published_name in col_maps
    all_df_cols = set(lf.collect_schema().names())
    all_defined_cols = [col_map["published_name"] for col_map in col_maps if "yes" in col_map["publish_in_full"]]
    extra_cols = all_df_cols - set(all_defined_cols)
    if extra_cols:
        print("Extra columns in output data not defined in publication column definition:")
        for c in sorted(extra_cols):
            print(f"Extra column: {c}")
    missing_cols = [col for col in set(all_defined_cols) - all_df_cols if not col.startswith("upgrade.")]
    if missing_cols:
        print("Missing columns in output data that are defined in publication column definition:")
        for c in sorted(missing_cols):
            print(f"Missing column: {c}")
    available_cols = [col for col in all_defined_cols if col in all_df_cols]
    return lf.select(available_cols)


def get_file_path(output_dir, full_geo_dir, geo_prefixes, geo_levels, file_type, data_type, upgrade_id):
    """
    Builds a file path for each aggregate based on name, file type, and aggregation level
    """
    geo_level_dir = f"{full_geo_dir}/{data_type}/{file_type}"
    if len(geo_levels) > 0:
        geo_level_dir = f"{geo_level_dir}/" + "/".join(geo_levels)
    if not isinstance(output_dir["fs"], s3fs.S3FileSystem):
        output_dir["fs"].mkdirs(geo_level_dir, exist_ok=True)
    file_name = f"upgrade{upgrade_id}"
    # Add geography prefix to filename
    if len(geo_prefixes) > 0:
        geo_prefix = "_".join(geo_prefixes)
        file_name = f"{geo_prefix}_{file_name}"
    # Add data_type suffix to filename
    if data_type == "basic":
        file_name = f"{file_name}_{data_type}"
    # Add the filetype extension to filename
    file_name = f"{file_name}.{file_type}"
    # Write the file, depending on filetype
    file_path = f"{geo_level_dir}/{file_name}"

    return file_path


def cache_simulation_outputs_file(output_dir, sim_out_cache_dir: pathlib.Path, upgrade_id: int, df: pl.LazyFrame):
    file_name = f"cached_simulation_outputs_upgrade{upgrade_id}.parquet"
    upgrade_cache_dir = pathlib.Path(f"{sim_out_cache_dir}/upgrade={upgrade_id}")
    file_path = upgrade_cache_dir / file_name
    if isinstance(output_dir["fs"], s3fs.S3FileSystem):
        file_path = f"s3://{file_path.as_posix()}"
    else:
        upgrade_cache_dir.mkdir(parents=True, exist_ok=True)
    with output_dir["fs"].open(str(file_path), "wb") as f:
        df.sink_parquet(f)
    print(f"Cached simulation outputs for upgrade {upgrade_id} to {file_path}")


def get_cached_simulation_outputs_file(output_dir, sim_out_cache_dir: pathlib.Path, upgrade_id: int):
    file_name = f"cached_simulation_outputs_upgrade{upgrade_id}.parquet"
    upgrade_cache_dir = pathlib.Path(f"{sim_out_cache_dir}/upgrade={upgrade_id}")
    file_path = upgrade_cache_dir / file_name
    if isinstance(output_dir["fs"], s3fs.S3FileSystem):
        file_path = f"s3://{file_path.as_posix()}"
    if not upgrade_cache_dir.exists():
        raise Exception(f"{file_path} does not exist. Ensure cache_simulation_outputs_file has been called previously.")
    return file_path


def get_cached_simulation_outputs_for_upgrade(output_dir, upgrade_id: int) -> pl.LazyFrame:
    sim_out_cache_dir = f"{output_dir['fs_path']}/cached_simulation_outputs"
    parquet_file_dir = pathlib.Path(f"{sim_out_cache_dir}/upgrade={upgrade_id}")
    parquet_file = parquet_file_dir / f"cached_simulation_outputs_upgrade{upgrade_id}.parquet"
    if isinstance(output_dir["fs"], s3fs.S3FileSystem):
        parquet_file = f"s3://{parquet_file.as_posix()}"
    if not output_dir["fs"].exists(parquet_file):
        raise FileNotFoundError(
        f"Cannot load upgrade data from {parquet_file}, call process_upgrade_simulation_outputs() first.")
    up_sim_outs = pl.scan_parquet(parquet_file, storage_options=output_dir["storage_options"] )

    return up_sim_outs
