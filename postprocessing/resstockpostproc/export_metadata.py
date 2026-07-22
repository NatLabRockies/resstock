import datetime
import os
import boto3
import polars as pl
import logging

from joblib import Parallel, delayed

from resstockpostproc.utils import write_geo_data, col_name_to_percent_savings
from resstockpostproc.process_metadata import col_name_to_weighted, get_cached_simulation_outputs_for_upgrade, col_name_to_savings
from resstockpostproc.create_allocated_weights import get_cached_allocated_weights, get_allocated_weights_plus_util_bills_for_upgrade

logger = logging.getLogger(__name__)


def aggregate_allocated_weights_to_geography(alloc_wts,
                                            geography_filters={},
                                            geographic_aggregation_levels=["in.nhgis_tract_gisjoin"]):
    logger.info(f"Filtering allocated weights to: {geography_filters} and aggregating to: {geographic_aggregation_levels}")
    # print(f"geography_filters: {geography_filters}")
    # print(f"geographic_aggregation_levels: {geographic_aggregation_levels}")
    # print(f"alloc_wts.schema inside aggregate_allocated_weights_to_geography: {alloc_wts.collect_schema()}\n\n")
    # Filter to specified geography
    if len(geography_filters) > 0:
        geo_filter_exprs = [(pl.col(k) == v) for k, v in geography_filters.items()]
        alloc_wts = alloc_wts.filter(geo_filter_exprs)

    # Get names of geography columns to group by
    geo_agg_cols = []
    if geographic_aggregation_levels != ["national"]:
        geo_agg_cols = [pl.col(c) for c in geographic_aggregation_levels]

    # Get utility bill columns to aggregate
    cost_cols = []  # TODO fill out the utility bill column names

    # Sum the weights and weighted utility bills by building IDs within each geography
    wtd_agg_outs = alloc_wts.select(
        [
            pl.col("weight"),
            pl.col("upgrade"),
            pl.col("bldg_id"),
            # pl.col("in.sqft..ft2")
        ]
        + geo_agg_cols
        # + weighted_util_cols
        + cost_cols
    ).group_by(
        [
            pl.col("upgrade"),
            pl.col("bldg_id")
        ]
        + geo_agg_cols
    ).agg(
        [
            pl.col(["weight"] + cost_cols).sum(),
            # pl.col(["in.sqft..ft2"]).first()
        ]
    )

    # print(f"wtd_agg_outs schema: {wtd_agg_outs.collect_schema()}\n\n")

    return wtd_agg_outs


def add_weighted_utility_cost_savings_columns(input_lf, baseline_lf, geo_agg_cols):
    # the data contains the weighted extracted utility bills for the apportioned tract
    # This method will calculate the weighted utility cost savings by each metric - min, median_low, median_high, mean, max, and state average

    logger.debug("Adding weighted utility cost savings")

    assert isinstance(input_lf, pl.LazyFrame)

    weighted_utility_units = "billion_usd"

    result_cols = [] # TODO fill out the utility bill column names
    abs_svgs_cols = {}
    pct_svgs_cols = {}

    val_cols = []

    for col in result_cols:
        weighted_col = col_name_to_weighted(col, weighted_utility_units)
        val_cols.append(weighted_col)
        abs_svgs_cols[weighted_col] = col_name_to_savings(weighted_col, None)
        pct_svgs_cols[weighted_col] = col_name_to_percent_savings(weighted_col, "percent")
        # mapping for column name to intensity savings column name  # TODO do we need intensity savings for utility bills?
        # intensity_col = col_name_to_area_intensity(col)
        # val_cols.append(intensity_col)
        # abs_svgs_cols[intensity_col] = col_name_to_savings(intensity_col, None)
        # pct_svgs_cols[intensity_col] = col_name_to_percent_savings(intensity_col, "percent")

    if baseline_lf is None:
        # this is baseline data, add empty savings cols and return
        for weighted_col in (list(abs_svgs_cols.values()) + list(pct_svgs_cols.values())):
            input_lf = input_lf.with_columns(pl.lit(0.0).alias(weighted_col))
        return input_lf

    val_and_id_cols = val_cols + geo_agg_cols + ["bldg_id"]

    base_vals = baseline_lf.select(val_and_id_cols).sort(["bldg_id"] + geo_agg_cols).clone()
    base_vals = base_vals.rename(lambda col_name: col_name + "_base")

    up_vals = input_lf.select(val_and_id_cols).sort(["bldg_id"] + geo_agg_cols).clone()

    # absolute savings
    abs_svgs = pl.concat([up_vals, base_vals], how="horizontal").with_columns(
        [(pl.col(f"{col}_base") - pl.col(col)).alias(abs_svgs_cols[col]) for col in val_cols]
    ).select(list(abs_svgs_cols.values()) + geo_agg_cols + ["bldg_id"])

    # percent savings
    pct_svgs = pl.concat([up_vals, base_vals], how="horizontal").with_columns(
        [((pl.col(f"{col}_base") - pl.col(col)) / pl.col(f"{col}_base") * 100).alias(pct_svgs_cols[col]) for col in val_cols]
    ).select(list(pct_svgs_cols.values()) + geo_agg_cols + ["bldg_id"])

    pct_svgs = pct_svgs.fill_null(0.0)
    pct_svgs = pct_svgs.fill_nan(0.0)

    abs_svgs = abs_svgs.cast({"bldg_id": pl.Int64})
    pct_svgs = pct_svgs.cast({"bldg_id": pl.Int64})

    input_lf = input_lf.join(abs_svgs, how="left", on=["bldg_id"] + geo_agg_cols)
    input_lf = input_lf.join(pct_svgs, how="left", on=["bldg_id"] + geo_agg_cols)

    return input_lf


def create_weighted_aggregate_output(up_alloc_wts,
                                    sim_outs,
                                    base_alloc_wts,
                                    geography_filters={},
                                    geographic_aggregation_levels=[],
                                    column_downselection=None) -> pl.LazyFrame:

    # Aggregate the upgrade's allocated weights for this geographic resolution
    up_agg_alloc_wts = aggregate_allocated_weights_to_geography(
                                            up_alloc_wts,
                                            geography_filters,
                                            geographic_aggregation_levels
    )

    # Aggregate the baseline's allocated weights for this geographic resolution
    # base_agg_alloc_wts = aggregate_allocated_weights_to_geography(
    #                                         base_alloc_wts,
    #                                         geography_filters,
    #                                         geographic_aggregation_levels
    # )

    # Get names of geography columns to group by
    geo_agg_cols = []
    if geographic_aggregation_levels != ["national"]:
        geo_agg_cols = [pl.col(c) for c in geographic_aggregation_levels]

    # TODO Calculate utility bill savings columns on the aggregate data
    # up_agg_alloc_wts = add_utility_cost_savings_columns(up_agg_alloc_wts, base_agg_alloc_wts, geo_agg_cols)

    # Join the aggregate allocated weights to the simulation outputs by building ID and upgrade ID
    logger.info("Joining the aggregated weights to simulation results")

    # print(f"up_agg_alloc_wts schema: {up_agg_alloc_wts.collect_schema()}\n\n")
    # print(f"sim_outs schema: {sim_outs.collect_schema()}\n\n")

    wtd_agg_outs = up_agg_alloc_wts.join(sim_outs, on=[pl.col("upgrade"), pl.col("bldg_id")])

    logger.info("Calculating weighted energy savings columns")
    # TODO Calculate the weighted columns
    # wtd_agg_outs = add_weighted_area_energy_savings_columns(wtd_agg_outs)

    # # Cast geography column from Categorical to String for joining
    # wtd_agg_outs = wtd_agg_outs.with_columns(
    #     pl.col(geographic_aggregation_levels[0]).cast(pl.String)
    # )

    # Add geospatial data columns based on most informative geography column
    wtd_agg_outs = add_geospatial_columns(wtd_agg_outs, geographic_aggregation_levels[0])

    # Add other columns that can only be added based on census tract
    if geographic_aggregation_levels == ["in.nhgis_tract_gisjoin"]:
        wtd_agg_outs = add_electric_utility_column(wtd_agg_outs, geographic_aggregation_levels[0])
    #     wtd_agg_outs = add_cejst_columns(wtd_agg_outs)
    #     wtd_agg_outs = add_ejscreen_columns(wtd_agg_outs)

    # # TODO Downselect and order columns
    # logger.info(f"Downselecting columns using option: {column_downselection}")
    # ordered_cols = reorder_columns(columns_for_export(wtd_agg_outs, column_downselection))
    # wtd_agg_outs = wtd_agg_outs.select(ordered_cols)

    # List the final set of columns
    # logger.info('Final columns from create_geospatial_slice_of_metadata:')
    # for c in geo_data.columns:
    #     logger.info(c)

    return wtd_agg_outs


def export_metadata_and_annual_results_for_upgrade(output_dir, upgrade_id, geo_exports, n_parallel=-1):
    """
    Subdivides the annual results by geography and writes to OEDI.
    Creates .parquet and .csv.gz files.

    Args:
        output_dir: Dict of filesystem object information
        upgrade_id: Integer ID for the upgrade to process
        geo_exports: List of Dicts of export definitions
    Returns:
        None

    """

    logger.info(f"Exporting metadata and annual results for upgrade {upgrade_id}")

    # Read the cached simulation results
    up_sim_outs = get_cached_simulation_outputs_for_upgrade(output_dir, upgrade_id)

    # Export to all geographies
    logger.info("Exporting /metadata_and_annual_results and /metadata_and_annual_results_aggregates")
    tstart = datetime.datetime.now()
    for ge in geo_exports:
        ge_tstart = datetime.datetime.now()
        geo_top_dir = ge["geo_top_dir"]
        partition_cols = ge["partition_cols"]
        aggregation_levels = ge["aggregation_levels"]
        data_types = ge["data_types"]
        file_types = ge["file_types"]
        geo_col_names = list(partition_cols.keys())
        logger.info(f"Exporting: {geo_top_dir} partitioned by: {geo_col_names}, aggregated to: {aggregation_levels}")

        # Get the unique set of combinations of all geography column partitions
        logger.debug("Get the unique set of combinations of all geography column partitions")
        if len(geo_col_names) == 0:
            geo_combos = pl.DataFrame({"geography": ["national"]})
            first_geo_combos = pl.DataFrame({"geography": ["national"]})
        else:
            alloc_wts = get_allocated_weights_plus_util_bills_for_upgrade(output_dir, 0)
            geo_combos = alloc_wts.select(geo_col_names).unique().collect()
            geo_combos = geo_combos.sort(by=geo_col_names)
            alloc_wts = get_allocated_weights_plus_util_bills_for_upgrade(output_dir, 0)
            first_geo_combos = alloc_wts.select(geo_col_names[0]).unique().collect()
            first_geo_combos = first_geo_combos.sort(by=geo_col_names[0])

        # Make a directory for the geography type
        full_geo_dir = f"{output_dir['fs_path']}/metadata_and_annual_results/{geo_top_dir}"
        output_dir["fs"].mkdirs(full_geo_dir, exist_ok=True)

        # Make a directory for each data type X file type combo
        if None in aggregation_levels:
            for data_type in data_types:
                for file_type in file_types:
                    output_dir["fs"].mkdirs(f"{full_geo_dir}/{data_type}/{file_type}", exist_ok=True)

        # Make an aggregates directory for the geography type
        full_geo_agg_dir = f"{output_dir['fs_path']}/metadata_and_annual_results_aggregates/{geo_top_dir}"
        output_dir["fs"].mkdirs(full_geo_agg_dir, exist_ok=True)

        # Make a directory for each data type X file type combo
        for data_type in data_types:
            for file_type in file_types:
                output_dir["fs"].mkdirs(f"{full_geo_agg_dir}/{data_type}/{file_type}", exist_ok=True)

        # Builds a file path for each aggregate based on name, file type, and aggregation level
        def get_file_path(full_geo_agg_dir, full_geo_dir, geo_prefixes, geo_levels, file_type, aggregation_level):
            # Start with either /metadata_and_annual_results or /metadata_and_annual_results_aggregates
            agg_level_dir = full_geo_agg_dir
            if aggregation_level == "in.nhgis_tract_gisjoin":
                agg_level_dir = full_geo_dir
            geo_level_dir = f"{agg_level_dir}/{data_type}/{file_type}"
            if len(geo_levels) > 0:
                geo_level_dir = f"{geo_level_dir}/" + "/".join(geo_levels)
            output_dir["fs"].mkdirs(geo_level_dir, exist_ok=True)
            file_name = f"upgrade{upgrade_id}"
            # Add geography prefix to filename
            if len(geo_prefixes) > 0:
                geo_prefix = "_".join(geo_prefixes)
                file_name = f"{geo_prefix}_{file_name}"
            # Add aggregate suffix to filename
            if aggregation_level != "in.nhgis_tract_gisjoin":
                file_name = f"{file_name}_agg"
            # Add data_type suffix to filename
            if data_type == "basic":
                file_name = f"{file_name}_{data_type}"
            # Add the filetype extension to filename
            file_name = f"{file_name}.{file_type}"
            # Write the file, depending on filetype
            file_path = f"{geo_level_dir}/{file_name}"

            return file_path

        # Get the allocated weights plus utility bills for the baseline
        base_alloc_wts_plus_bills = get_allocated_weights_plus_util_bills_for_upgrade(output_dir, 0)

        # Get the allocated weights plus utility bills for the upgrade
        up_alloc_wts_plus_bills = get_allocated_weights_plus_util_bills_for_upgrade(output_dir, upgrade_id)

        # print(f"up_alloc_wts_plus_bills schema: {up_alloc_wts_plus_bills.collect_schema()}\n\n")

        # Write raw data and all aggregation levels
        for aggregation_level in aggregation_levels:
            logger.info(f"Starting aggregation_level: {aggregation_level}")

            # Start with the most expansive set of columns, the downselect later as-needed.
            if "detailed" in data_types:
                starting_downselect = "detailed"
            elif "full" in data_types:
                starting_downselect = "full"
            elif "basic" in data_types:
                starting_downselect = "basic"
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
            # Handle census tract vs. larger geography aggregation differently because of memory usage
            if aggregation_level is None:
                # "No aggregation" for ResStock means that the data is at the census tract level.
                aggregation_level = "in.nhgis_tract_gisjoin"  # noqa: PLW2901

                # Iterate by first level of geographic partitioning, collecting the DataFrame
                # for this geography then writing files for all the sub-geographies within it.
                for first_geo_combo in first_geo_combos.iter_rows(named=True):
                    fgc_tstart = datetime.datetime.now()
                    print("")
                    logger.info(f"Creating aggregates for: {first_geo_combo}")

                    # Get the filters for the first level geography
                    first_geo_filters = {}
                    for k, v in first_geo_combo.items():
                        if k == "geography" and v == "national":
                            continue
                        first_geo_filters[k] = v

                    # Collect the dataframe for the first level geography
                    agg_lvl_list = [aggregation_level]
                    if isinstance(aggregation_level, list):
                        agg_lvl_list = aggregation_level  # Pass list if a list is already supplied
                    wtd_agg_tstart = datetime.datetime.now()
                    wtd_agg_outs = create_weighted_aggregate_output(up_alloc_wts_plus_bills,
                                                                        up_sim_outs,
                                                                        base_alloc_wts_plus_bills,
                                                                        first_geo_filters,
                                                                        agg_lvl_list,
                                                                        starting_downselect)
                    logger.info(f"Weighted agg time for {first_geo_combo}: {(datetime.datetime.now() - wtd_agg_tstart).total_seconds()} seconds")
                    collect_tstart = datetime.datetime.now()
                    wtd_agg_outs = wtd_agg_outs.collect()
                    logger.info(f"Collect time for {first_geo_combo}: {(datetime.datetime.now() - collect_tstart).total_seconds()} seconds")

                    # Determine the column subset and order for each data type
                    # TODO ordered_cols = {data_type: reorder_columns(columns_for_export(wtd_agg_outs, data_type)) for data_type in data_types}

                    # Queue writes for each geography
                    combos_to_write = []
                    for geo_combo in geo_combos.iter_rows(named=True):
                        # print(f'geo_combo: {geo_combo}')

                        # Get the filters for the geography
                        geo_filters = {}
                        geo_levels = []
                        geo_prefixes = []
                        for k, v in geo_combo.items():
                            if k == "geography" and v == "national":
                                continue
                            geo_filters[k] = v
                            geo_levels.append(f"{partition_cols[k]}={v}")
                            geo_prefixes.append(v)

                        # Skip geo_combos that aren't in this first-level partitioning. e.g. counties not in a state
                        first_level_geo_combo_val = next(iter(first_geo_filters.values()))
                        geo_combo_val = next(iter(geo_filters.values()))
                        if geo_combo_val != first_level_geo_combo_val:
                            # logger.info(f'Skipping {geo_combo} because not in this partition ({geo_combo_val} != {first_level_geo_combo_val})')
                            continue

                        # Filter already-collected dataframe to specified geography
                        if len(geo_filters) > 0:
                            geo_filter_exprs = [(pl.col(k) == v) for k, v in geo_filters.items()]
                            geo_data = wtd_agg_outs.filter(geo_filter_exprs)
                        else:
                            geo_data = wtd_agg_outs

                        # Sort by building ID
                        geo_data = geo_data.sort(by="bldg_id")

                        # Queue write for each data type
                        for data_type in data_types:

                            # Downselect columns based on the data type
                            geo_data_for_data_type = geo_data  # TODO .clone().select(ordered_cols[data_type])

                            # Queue write for all selected filetypes
                            for file_type in file_types:
                                file_path = get_file_path(full_geo_agg_dir, full_geo_dir, geo_prefixes, geo_levels, file_type, aggregation_level)
                                logger.debug(f"Queuing {file_path}")
                                combo = (geo_data_for_data_type, output_dir, file_type, file_path)
                                combos_to_write.append(combo)

                    # Write files in parallel
                    logger.info(f"Writing {len(combos_to_write)} files in parallel")
                    write_tstart = datetime.datetime.now()
                    with Parallel(n_jobs=n_parallel) as parallel:
                        parallel(delayed(write_geo_data)(combo) for combo in combos_to_write)
                    logger.info(f"Write time for {first_geo_combo}: {(datetime.datetime.now() - write_tstart).total_seconds()} seconds")
                    # # Attempting to avoid crashes
                    # wtd_agg_outs.clear()
                    # del to_write
                    # time.sleep(2)
                    # gc.collect()
                    logger.info(f"Total time for {first_geo_combo}: {(datetime.datetime.now() - fgc_tstart).total_seconds()} seconds")
            else:
                # If there is any aggregation, collect a single dataframe with all geographies and savings columns
                # Memory usage should work on most laptops
                no_geo_filters = {}
                agg_lvl_list = [aggregation_level]
                if isinstance(aggregation_level, list):
                    agg_lvl_list = aggregation_level  # Pass list if a list is already supplied
                wtd_agg_outs = create_weighted_aggregate_output(up_alloc_wts_plus_bills,
                                                                    up_sim_outs,
                                                                    base_alloc_wts_plus_bills,
                                                                    no_geo_filters,
                                                                    agg_lvl_list,
                                                                    starting_downselect)
                collect_tstart = datetime.datetime.now()
                wtd_agg_outs = wtd_agg_outs.collect()
                logger.info(f"Collect time for {aggregation_level}: {(datetime.datetime.now() - collect_tstart).total_seconds()} seconds")
                logger.info(f"There are {wtd_agg_outs.shape[0]:,} total rows at the aggregation level {aggregation_level}")

                # Determine the column subset and order for each data type
                # ordered_cols = {data_type: reorder_columns(columns_for_export(wtd_agg_outs, data_type)) for data_type in data_types} # TODO

                # Process each geography and downselect columns
                combos_to_write = []
                for geo_combo in geo_combos.iter_rows(named=True):
                    # print(f'geo_combo: {geo_combo}')

                    geo_filters = {}
                    geo_levels = []
                    geo_prefixes = []
                    for k, v in geo_combo.items():
                        if k == "geography" and v == "national":
                            continue
                        geo_filters[k] = v
                        geo_levels.append(f"{partition_cols[k]}={v}")
                        geo_prefixes.append(v)

                    # Filter already-collected dataframe to specified geography
                    if len(geo_filters) > 0:
                        geo_filter_exprs = [(pl.col(k) == v) for k, v in geo_filters.items()]
                        geo_data = wtd_agg_outs.filter(geo_filter_exprs)
                    else:
                        geo_data = wtd_agg_outs

                    # Sort by building ID
                    geo_data = geo_data.sort(by="bldg_id")

                    # Queue write for each data type
                    for data_type in data_types:

                        # Downselect columns further if appropriate
                        # data_type_df = geo_data.clone().select(ordered_cols[data_type])  # TODO

                        # Queue write for all selected filetypes
                        n_rows, n_cols = geo_data.shape
                        for file_type in file_types:
                            file_path = get_file_path(full_geo_agg_dir, full_geo_dir, geo_prefixes, geo_levels, file_type, aggregation_level)
                            logger.debug(f"Queuing {file_path}: n_cols = {n_cols:,}, n_rows = {n_rows:,}")
                            combo = (geo_data, output_dir, file_type, file_path)
                            combos_to_write.append(combo)

                # Write files in parallel
                logger.info(f"Writing {len(combos_to_write)} files in parallel")
                write_tstart = datetime.datetime.now()
                with Parallel(n_jobs=n_parallel) as parallel:
                    parallel(delayed(write_geo_data)(combo) for combo in combos_to_write)
                logger.info(f"Write time for {aggregation_level}: {(datetime.datetime.now() - write_tstart).total_seconds()} seconds")

        ge_tend = datetime.datetime.now()
        logger.info(f"Finished exporting: {geo_top_dir}. ")
        logger.info(f"Partitioned by: {geo_col_names}")
        logger.info(f"Geographic aggregation levels: {aggregation_levels}")
        logger.info(f"Time elapsed: {(ge_tend - ge_tstart).total_seconds()} seconds")

    return f"Finished {geo_exports} for upgrade {"upgrade"} in {(datetime.datetime.now() - tstart).total_seconds()} seconds."


def add_geospatial_columns(input_lf: pl.LazyFrame, geography_to_join_on) -> pl.LazyFrame:
    supported_geogs = ["in.nhgis_tract_gisjoin", "in.nhgis_county_gisjoin", "in.nhgis_puma_gisjoin", "in.state"]
    if geography_to_join_on not in supported_geogs:
        logger.info(f"Cannot add more geospatial columns based on {geography_to_join_on}")
        return input_lf
    logger.info(f"Adding geospatial columns based on {geography_to_join_on}")

    # Read the geospatial data file into a Polars LazyFrame
    geospatial_file = "spatial_tract_lookup_table_publish_v11.csv"
    geospatial_file_path = os.path.abspath(os.path.join(__file__, "..", "resources", "gisdata", geospatial_file))
    logger.info(f"Reading geospatial data file from {geospatial_file_path}")
    geospatial_data = pl.scan_csv(geospatial_file_path, infer_schema_length=None)

    # Columns mappable from in.nhgis_county_gisjoin:
    county_mappings = [
        "in.nhgis_county_gisjoin",  # include the column itself
        "in.state",
        "in.state_name",
        "in.nhgis_state_gisjoin",
        "in.census_division_name",
        "in.census_region_name",
        "in.ashrae_iecc_climate_zone_2006",
        "in.building_america_climate_zone",
        "in.iso_rto_region",
        "in.reeds_balancing_area",
        "in.cambium_grid_region",
    ]

    # Columns mappable from in.nhgis_puma_gisjoin:
    puma_mappings = [
        "in.nhgis_puma_gisjoin",  # include the column itself
        "in.state",
        "in.state_name",
        "in.nhgis_state_gisjoin",
        "in.census_division_name",
        "in.census_region_name",
    ]

    # Columns mappable from in.state:
    state_mappings = [
        "in.state", # include the column itself
        "in.state_name",
        "in.nhgis_state_gisjoin",
        "in.census_division_name",
        "in.census_region_name",
    ]

    # Downselect to mappable columns before joining
    if geography_to_join_on == "in.nhgis_tract_gisjoin":
        pass  # No column downselection needed
    elif geography_to_join_on == "in.nhgis_county_gisjoin":
        geospatial_data = geospatial_data.select(county_mappings).unique()
    elif geography_to_join_on == "in.nhgis_puma_gisjoin":
        geospatial_data = geospatial_data.select(puma_mappings).unique()
    elif geography_to_join_on == "in.state":
        geospatial_data = geospatial_data.select(state_mappings).unique()

    # Join on the geospatial data
    input_lf = input_lf.join(geospatial_data, on=geography_to_join_on)

    return input_lf


def add_electric_utility_column(input_lf: pl.LazyFrame, geography_to_join_on) -> pl.LazyFrame:
    supported_geogs = ["in.nhgis_tract_gisjoin"]
    if geography_to_join_on not in supported_geogs:
        logger.info(f"Cannot add electric utility column based on {geography_to_join_on}")
        return input_lf
    logger.info(f"Adding electric utility column based on {geography_to_join_on}")

    # Read the geospatial data file into a Polars LazyFrame
    elec_util_file = "tract_to_elec_util_v2.csv"
    elec_util_file_path = os.path.abspath(os.path.join(__file__, "..", "resources", "gisdata", elec_util_file))
    logger.info(f"Reading electric utility data file from {elec_util_file_path}")
    elec_util_data = pl.scan_csv(elec_util_file_path, infer_schema_length=None)

    # Join on the geospatial data
    input_lf = input_lf.join(elec_util_data, on=geography_to_join_on)

    return input_lf
