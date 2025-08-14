import polars as pl
from resstockpostproc.utils import fix_site_energy_total, fix_all_fuels_emissions, get_col_maps
import pathlib
import geopandas as gpd
from typing import Sequence

def get_failed_bldgs(metadata_df: pl.LazyFrame) -> set[int]:
    failed_bldgs = metadata_df.filter(pl.col("completed_status") == "Fail")
    failed_bldgs = failed_bldgs.select(pl.col("building_id"))
    return set(failed_bldgs.collect()["building_id"].to_list())

def publish_baseline_annual_results(base_raw_df: pl.LazyFrame) -> pl.LazyFrame:
    """
    Publishes the annual results for the baseline.

    Args:
        base_raw_df: LazyFrame containing baseline results from raw BuildStockBatch results.
    Returns:
        LazyFrame containing published baseline results.
    """
    col_maps = get_col_maps()
    base_df = base_raw_df.filter(pl.col("completed_status") == "Success")
    base_df = get_transformed_cols(base_df, col_maps)
    base_df = base_df.with_columns(pl.lit(True).alias("applicability"))
    base_df = base_df.with_columns([pl.lit(0).alias("upgrade"), pl.lit("Baseline").alias("upgrade_name")])
    base_df = add_income_and_burden(base_df)
    base_df = add_county_column(base_df)
    base_df = add_puma_column(base_df)

    all_cols = base_df.collect_schema().names()
    print("Fixing site energy and site emission total for baseline ...")
    base_df = fix_site_energy_total(base_df, all_cols)
    base_df = fix_all_fuels_emissions(base_df, all_cols)
    base_df = add_panel_contraint_cols(base_df)
    base_df = add_upgrade_columns(base_df)
    base_df = reorder_columns(base_df, col_maps, is_baseline=True)
    return base_df

def publish_upgrade_annual_results(baseline_failed_bldgs: set[int], base_pub_df: pl.LazyFrame, upgrade_raw_df: pl.LazyFrame,
                                   upgrade_num: int) -> pl.LazyFrame:
    """
    Publishes the annual results for a specific upgrade.

    Args:
        baseline_failed_bldgs: Set of failed building IDs in baseline.
        base_pub_df: LazyFrame containing baseline results already passed through publish_baseline_annual_results.
        upgrade_raw_df: LazyFrame containing upgrade results from raw BuildStockBatch results.
        upgrade_num: Integer representing the upgrade number.
    Returns:
        LazyFrame containing published upgrade results.
    """

    col_maps = get_col_maps()
    upgrade_df = upgrade_raw_df.filter((~pl.col("building_id").is_in(baseline_failed_bldgs)) &
                              (pl.col("completed_status") == "Success"))
    failed_bldgs = (
        upgrade_raw_df.filter(
            (pl.col("completed_status") == "Fail")
            & (~pl.col("building_id").is_in(baseline_failed_bldgs))
        )
        .select(pl.col("building_id"))
        .collect()['building_id']
        .to_list()
    )
    if failed_bldgs:
        print(
            f"Replacig these {len(failed_bldgs)} buildings that only failed in "
            f"upgrade {upgrade_num} with baseline: {failed_bldgs}"
        )
    
    upgrade_df = get_transformed_cols(upgrade_df, col_maps)
    upgrade_df = upgrade_df.with_columns([pl.lit(upgrade_num).alias("upgrade")])
    base_cols = base_pub_df.collect_schema().names()
    upgrade_cols = upgrade_df.collect_schema().names()
    missing_cols = list(set(base_cols) - set(upgrade_cols)) + ["bldg_id"]
    upgrade_df = upgrade_df.join(base_pub_df.select(missing_cols), on="bldg_id", how="left")
    all_cols = upgrade_df.collect_schema().names()
    print("Fixing site energy and site emission total for upgrade ...")
    upgrade_df = fix_site_energy_total(upgrade_df, all_cols)
    upgrade_df = fix_all_fuels_emissions(upgrade_df, all_cols)
    upgrade_df = add_upgrade_columns(upgrade_df)
    upgrade_df = upgrade_df.with_columns(pl.lit(True).alias("applicability"))
    # get upgrade_name
    upgrade_name_df = upgrade_df.select(pl.col("upgrade_name").first())
    missing_bldgs_df = base_pub_df.join(
        upgrade_df,
        on="bldg_id",
        how="anti"  # Keep rows from 'base' with no match in 'upgrade'
    )
    missing_bldgs_df = missing_bldgs_df.with_columns([
        pl.lit(False).alias("applicability"),
        pl.lit(upgrade_num).alias("upgrade"),
    ]).drop("upgrade_name")
    upgrade_cols = upgrade_df.collect_schema().names()
    missing_bldgs_df = missing_bldgs_df.join(upgrade_name_df,  how="cross")
    upgrade_df = pl.concat([upgrade_df, missing_bldgs_df], how="diagonal_relaxed")
    upgrade_df = upgrade_df.sort("bldg_id")
    upgrade_df = add_saving_cols(upgrade_df, base_pub_df)
    upgrade_df = add_panel_contraint_cols(upgrade_df)
    upgrade_df = reorder_columns(upgrade_df, col_maps, is_baseline=False)
    return upgrade_df


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
    out_cols = [col for col in all_cols if 'out.' in col and not ('out.params' in col or 'out.panel' in col)]
    # Selectively include the following for panels
    out_panel_cols = [col for col in all_cols if 
        "out.panel.load.total_load." in col
        or "out.panel.load.occupied_capacity." in col
        or "out.panel.breaker_space.occupied." in col
        ]
    out_cols += out_panel_cols

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


def add_panel_contraint_cols(df: pl.LazyFrame) -> pl.LazyFrame:
    all_cols = df.collect_schema().names()
    amp_prefix = "out.panel.load.headroom_capacity."
    amp_cols = [col for col in all_cols if amp_prefix in col]
    space_col = "out.panel.breaker_space.headroom.count"

    out_space_col = "out.panel.constraint.breaker_space"
    space_constraint = pl.when(pl.col(space_col) <= 0).then(True).otherwise(False).alias(out_space_col)
    ind_constraints = [space_constraint]
    overall_constraint = None
    for amp_col in amp_cols:
        nec_method = amp_col.removeprefix(amp_prefix).removesuffix(".a")
        out_amp_col = "out.panel.constraint.capacity." + nec_method
        amp_constraint = pl.when(pl.col(amp_col) <= 0).then(True).otherwise(False).alias(out_amp_col)
        ind_constraints.append(amp_constraint)

        out_overall_col = "out.panel.constraint.overall." + nec_method
        overall_constraint = pl.coalesce(
            pl.when(pl.col(out_amp_col) & pl.col(out_space_col)).then(pl.lit("Capacity and Space Constrained")),
            pl.when(pl.col(out_amp_col) & ~pl.col(out_space_col)).then(pl.lit("Capacity Constrained Only")),
            pl.when(~pl.col(out_amp_col) & pl.col(out_space_col)).then(pl.lit("Space Constrained Only")),
            pl.lit("No Constraint"),
        ).alias(out_overall_col)

    new_df = df.with_columns(ind_constraints)
    if overall_constraint is not None:
        new_df = new_df.with_columns(overall_constraint) # needs to be sequential

    return new_df


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
