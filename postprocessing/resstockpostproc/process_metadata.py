import polars as pl
from resstockpostproc.utils import fix_site_energy_total, fix_all_fuels_emissions, get_col_maps
import pathlib
import geopandas as gpd
from typing import Sequence

def get_failed_bldgs(metadata_df: pl.LazyFrame) -> set[int]:
    failed_bldgs = metadata_df.filter(pl.col("completed_status") == "Fail")
    failed_bldgs = failed_bldgs.select(pl.col("building_id"))
    return set(failed_bldgs.collect()["building_id"].to_list())

def publish_baseline_annual_results(failed_bldgs: set[int], base: pl.LazyFrame) -> pl.LazyFrame:
    col_maps = get_col_maps()
    base = base.filter(~pl.col("building_id").is_in(failed_bldgs))
    base = get_transformed_cols(base, col_maps)
    base = base.with_columns(pl.lit(True).alias("applicability"))
    base = base.with_columns([pl.lit(0).alias("upgrade"), pl.lit("Baseline").alias("upgrade_name")])
    base = add_income_and_burden(base)
    base = add_county_column(base)
    base = add_puma_column(base)

    all_cols = base.collect_schema().names()
    print("Fixing site energy and site emission total for baseline ...")
    base = fix_site_energy_total(base, all_cols)
    base = fix_all_fuels_emissions(base, all_cols)
    base = add_upgrade_columns(base)
    base = reorder_columns(base, col_maps, is_baseline=True)
    return base

def publish_upgrade_annual_results(failed_bldgs: set[int], base: pl.LazyFrame, upgrade: pl.LazyFrame,
                                   upgrade_num: int) -> pl.LazyFrame:
    col_maps = get_col_maps()
    upgrade = upgrade.filter((~pl.col("building_id").is_in(failed_bldgs)) &
                              (pl.col("completed_status") == "Success"))
    
    upgrade = get_transformed_cols(upgrade, col_maps)
    upgrade = upgrade.with_columns([pl.lit(upgrade_num).alias("upgrade")])
    base_cols = base.collect_schema().names()
    upgrade_cols = upgrade.collect_schema().names()
    missing_cols = list(set(base_cols) - set(upgrade_cols)) + ["bldg_id"]
    upgrade = upgrade.join(base.select(missing_cols), on="bldg_id", how="left")
    all_cols = upgrade.collect_schema().names()
    print("Fixing site energy and site emission total for upgrade ...")
    upgrade = fix_site_energy_total(upgrade, all_cols)
    upgrade = fix_all_fuels_emissions(upgrade, all_cols)
    upgrade = add_upgrade_columns(upgrade)
    upgrade = upgrade.with_columns(pl.lit("True").alias("applicability"))
    # get upgrade_name
    upgrade_name_df = upgrade.select(pl.col("upgrade_name").first())
    missing_bldgs_df = base.join(
        upgrade,
        on="bldg_id",
        how="anti"  # Keep rows from 'base' with no match in 'upgrade'
    )
    missing_bldgs_df = missing_bldgs_df.with_columns([
        pl.lit("False").alias("applicability"),
        pl.lit(upgrade_num).alias("upgrade"),
    ]).drop("upgrade_name")
    upgrade_cols = upgrade.collect_schema().names()
    missing_bldgs_df = missing_bldgs_df.join(upgrade_name_df,  how="cross")
    upgrade = pl.concat([upgrade, missing_bldgs_df], how="diagonal_relaxed")
    upgrade = upgrade.sort("bldg_id")
    upgrade = add_saving_cols(upgrade, base)
    upgrade = reorder_columns(upgrade, col_maps, is_baseline=False)
    return upgrade


def get_transformed_cols(df: pl.LazyFrame, col_maps: Sequence[dict]) -> pl.LazyFrame:
    transformed_cols = []
    all_cols = df.collect_schema().names()
    for col_map in col_maps:
        if col_map['column_type'] not in ['Input', 'Output']:
            continue
        assert col_map['column_name'] is not None, "ResStock column name must be provided for Input or Output columns"
        if col_map['column_name'] not in all_cols:
            continue
        if col_map['conversion_factor']:
            new_col = (pl.col(col_map['column_name']).cast(pl.Float64) * float(col_map['conversion_factor'])).alias(col_map['published_name'])
        else:
            new_col = pl.col(col_map['column_name']).alias(col_map['published_name'])
        transformed_cols.append(new_col)
    
    upgrade_cols = [col for col in all_cols if col.startswith("upgrade_costs.") and col.endswith("_name")]
    transformed_cols.extend([pl.col(col).alias(col) for col in upgrade_cols])
    return df.select(transformed_cols)

def add_income_and_burden(df: pl.LazyFrame) -> pl.LazyFrame:
    new_cols = []
    
    # Handle income parsing with better error handling
    income_expr = pl.when(pl.col("in.income").is_in(["Not Available", ""]))
    income_expr = income_expr.then(None)
    
    # Handle range case like "10000-20000"
    income_expr = income_expr.when(pl.col("in.income").str.contains("-"))
    income_expr = income_expr.then(
        (pl.col("in.income").str.extract(r"(\d+)-(\d+)", 1).cast(pl.Float64, strict=False) +
         pl.col("in.income").str.extract(r"(\d+)-(\d+)", 2).cast(pl.Float64, strict=False)) / 2
    )
    
    # Handle plus case like "200000+"
    income_expr = income_expr.when(pl.col("in.income").str.contains("\+"))
    income_expr = income_expr.then(
        pl.col("in.income").str.extract(r"(\d+)\+", 1).cast(pl.Float64, strict=False)
    )
    
    # Handle less than case like "<10000"
    income_expr = income_expr.when(pl.col("in.income").str.contains("<"))
    income_expr = income_expr.then(
        pl.col("in.income").str.extract(r"<(\d+)", 1).cast(pl.Float64, strict=False) / 2
    )
    
    # Otherwise try direct conversion
    income_expr = income_expr.otherwise(pl.col("in.income").cast(pl.Float64, strict=False))
    
    rep_income_col = income_expr.alias("in.representative_income")
    new_cols.append(rep_income_col)
    
    # Calculate burden only when income is not null
    burden_col = (
        pl.when(income_expr.is_not_null() & (income_expr > 0))
        .then(pl.col("out.bills.all_fuels.usd") / income_expr * 100)
        .otherwise(None)
        .alias("out.energy_burden.percentage")
    )
    new_cols.append(burden_col)
    
    return df.with_columns(new_cols)

def add_saving_cols(df: pl.LazyFrame, baseline_df: pl.LazyFrame) -> pl.LazyFrame:
    savings_cols = []
    all_cols = df.collect_schema().names()
    out_cols = [col for col in all_cols if 'out.' in col and not 'out.params' in col]
    
    baseline_df_with_renamed = baseline_df.select([
        pl.col(col).alias(f"baseline_{col}") for col in out_cols
    ] + ['bldg_id'])
    df_with_baseline = df.join(baseline_df_with_renamed, on="bldg_id", how="left")
    for col in out_cols:
        if col.startswith("out.emissions"):
            saving_col = (pl.col(f"baseline_{col}") - pl.col(col)).alias(col.replace("out.emissions", "out.emissions_reduction"))
        else:
            saving_col = (pl.col(f"baseline_{col}") - pl.col(col)).alias(f"{col}.savings")
        savings_cols.append(saving_col)
    return df_with_baseline.with_columns(savings_cols).drop([f"baseline_{col}" for col in out_cols])


def add_county_column(df: pl.LazyFrame):
    """
    Changes the county column to the FIPS code and adds a county name column.
    """
    here = pathlib.Path(__file__).resolve().parent
    county_map_df = pl.read_csv(
        here / "resources" / "gisdata" / "county_lookup_table.csv",
        columns=["long_name", "original_FIP"]
    ).select(
        pl.col("long_name"),
        pl.col("original_FIP").alias("county_fip")
    )
    county_map = dict(county_map_df.iter_rows())

    df = df.with_columns([
        pl.col("in.county").str.split(",").list.get(1).str.replace(r'^\s+|\s+$', '').alias("in.county_name"),
        pl.col("in.county").replace(county_map).alias("in.county"),
    ])
    return df


def add_puma_column(df: pl.LazyFrame):
    """
    Changes the puma column to the GISJOIN code.
    """
    here = pathlib.Path(__file__).resolve().parent
    pumas = gpd.read_file(
        here / "resources" / "gisdata" / "ipums_pums_2010_simple_t100_area_us_puma.geojson"
    )
    puma_map = pumas[["GISJOIN", "puma_tsv"]].set_index("puma_tsv")["GISJOIN"].to_dict()
    df = df.with_columns([
        pl.col("in.puma").replace(puma_map).alias("in.puma")
    ])
    return df

def add_upgrade_columns(lf: pl.LazyFrame) -> pl.LazyFrame:
    upgrade_cols = [
        c for c in lf.collect_schema().names()
        if c.startswith("upgrade_costs.") and c.endswith("_name")
    ]
    if not upgrade_cols:
        return lf
    upgrade_lf = lf.select(["bldg_id"] + upgrade_cols)
    upgrade_df = (upgrade_lf
                  .unpivot(index="bldg_id",
                           on=upgrade_cols,
                           variable_name="upgrade_name",
                           value_name="upgrade_value")
                  .drop_nulls("upgrade_value")
                  .filter(pl.col("upgrade_value") != "")
                  .with_columns(
                    pl.col("upgrade_value")
                      .str.split_exact("|", 1)
                      .struct.rename_fields(["upgrade_key", "upgrade_value"])
                  )
                  .unnest("upgrade_value")
                  .collect()
                  .group_by(["bldg_id", "upgrade_key"])
                  .agg(pl.col("upgrade_value").first())
                  .pivot(index="bldg_id", columns="upgrade_key", values="upgrade_value")
    )
    print("Done adding upgrade columns")
    upgrade_df = upgrade_df.rename({
                    c: f"upgrade.{c.lower().replace(' ', '_')}"
                    for c in upgrade_df.columns
                    if c != "bldg_id"
                   })
    return lf.drop(upgrade_cols).join(upgrade_df.lazy(), on="bldg_id", how="left")

def reorder_columns(lf: pl.LazyFrame, col_maps: Sequence[dict], is_baseline: bool):
    # verify that all the columns in lf are one published_name in col_maps
    all_df_cols = set(lf.collect_schema().names())
    all_defined_cols = [col_map['published_name'] for col_map in col_maps]
    extra_cols = all_df_cols - set(all_defined_cols)
    if extra_cols:
        print(f"Extra columns in output data not defined in publication column definition: {extra_cols}")
    missing_cols = [col for col in set(all_defined_cols) - all_df_cols if not col.startswith("upgrade.")]
    if is_baseline:
        missing_cols = [col for col in missing_cols if not ("savings" in col or "reduction" in col)]
    if missing_cols:
        print(f"Missing columns in output data that is defined in publication column definition: {missing_cols}")
    available_cols = [col for col in all_defined_cols if col in all_df_cols]
    return lf.select(available_cols)