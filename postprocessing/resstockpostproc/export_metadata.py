import datetime
import os
import polars as pl
import logging
import s3fs

from resstockpostproc.utils import col_name_to_percent_savings
from resstockpostproc.process_metadata import col_name_to_weighted, get_cached_simulation_outputs_for_upgrade, col_name_to_savings
from resstockpostproc.create_allocated_weights import get_allocated_weights_plus_util_bills_for_upgrade

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


def _export_file_name(geo_prefixes, upgrade_id, agg_suffix, data_type):
    """
    Builds an export file name (without extension) from its parts.
    e.g. CO_G0800590_upgrade0_agg for geo_prefixes=["CO", "G0800590"], agg_suffix="_agg"
    """
    file_name = f"upgrade{upgrade_id}{agg_suffix}"
    # Add geography prefix to filename
    if geo_prefixes:
        file_name = "_".join(geo_prefixes) + f"_{file_name}"
    # Add data_type suffix to filename
    if data_type == "basic":
        file_name = f"{file_name}_{data_type}"
    return file_name


def _make_partition_path_provider(partition_cols, upgrade_id, agg_suffix, data_type, ext):
    """
    Builds a callable that names each partition's output file for pl.PartitionBy.
    Produces paths like state=CO/county=G0800590/CO_G0800590_upgrade0.parquet
    relative to the PartitionBy base path.

    Args:
        partition_cols: Dict mapping partition column name to directory prefix,
            e.g. {"in.state": "state", "in.nhgis_county_gisjoin": "county"}
        upgrade_id: Integer ID for the upgrade being written
        agg_suffix: "" for full-resolution (tract) data, "_agg" for aggregates
        data_type: Data type of the export, e.g. "full" or "basic"
        ext: File extension, e.g. "parquet" or "csv.gz"
    Returns:
        Callable suitable for the file_path_provider argument of pl.PartitionBy
    """
    def provider(args):
        vals = [str(args.partition_keys[c][0]) for c in partition_cols]
        if args.index_in_partition != 0:
            raise RuntimeError(
                f"Partition {vals} was split into multiple files; expected one file per partition"
            )
        geo_level_dirs = "/".join(f"{d}={v}" for d, v in zip(partition_cols.values(), vals))
        file_name = _export_file_name(vals, upgrade_id, agg_suffix, data_type)
        return f"{geo_level_dirs}/{file_name}.{ext}"
    return provider


def export_metadata_and_annual_results_for_upgrade(output_dir, upgrade_id, geo_exports):
    """
    Subdivides the annual results by geography and writes to OEDI.
    Creates .parquet and .csv.gz files.

    The data is written with partitioned streaming sinks so that the full dataset
    is never materialized in memory: the parquet files are written in one streaming
    pass, then re-scanned (cheap, already aggregated/joined/sorted) to produce the
    gzipped CSVs.

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

    # Get the allocated weights plus utility bills for the baseline and the upgrade
    base_alloc_wts_plus_bills = get_allocated_weights_plus_util_bills_for_upgrade(output_dir, 0)
    up_alloc_wts_plus_bills = get_allocated_weights_plus_util_bills_for_upgrade(output_dir, upgrade_id)

    storage_options = output_dir["storage_options"]

    # Add the s3:// prefix for polars paths when writing to S3
    def to_polars_path(path):
        if isinstance(output_dir["fs"], s3fs.S3FileSystem):
            return f"s3://{path}"
        return path

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

        # Full-resolution (tract) and aggregate exports go to different top-level directories
        full_geo_dir = f"{output_dir['fs_path']}/metadata_and_annual_results/{geo_top_dir}"
        full_geo_agg_dir = f"{output_dir['fs_path']}/metadata_and_annual_results_aggregates/{geo_top_dir}"

        # Write all aggregation levels
        for aggregation_level in aggregation_levels:
            agg_lvl_tstart = datetime.datetime.now()
            logger.info(f"Starting aggregation_level: {aggregation_level}")

            # Start with the most expansive set of columns, the downselect later as-needed.
            if "detailed" in data_types:
                starting_downselect = "detailed"
            elif "full" in data_types:
                starting_downselect = "full"
            elif "basic" in data_types:
                starting_downselect = "basic"
            # Tract is the least-aggregated level published; it goes to
            # /metadata_and_annual_results and everything else goes to
            # /metadata_and_annual_results_aggregates
            is_full_resolution = aggregation_level == "in.nhgis_tract_gisjoin"
            agg_level_dir = full_geo_dir if is_full_resolution else full_geo_agg_dir
            agg_suffix = "" if is_full_resolution else "_agg"

            # Build the lazy query for the entire aggregation level, with no geography filters.
            # This query is never collected; the partitioned sinks below stream it to disk,
            # so memory usage stays bounded regardless of the number of output rows.
            agg_lvl_list = [aggregation_level]
            if isinstance(aggregation_level, list):
                agg_lvl_list = aggregation_level  # Pass list if a list is already supplied
            wtd_agg_outs = create_weighted_aggregate_output(up_alloc_wts_plus_bills,
                                                                up_sim_outs,
                                                                base_alloc_wts_plus_bills,
                                                                {},
                                                                agg_lvl_list,
                                                                starting_downselect)

            # Sort by building ID; the sinks maintain order, so each output file is sorted
            wtd_agg_outs = wtd_agg_outs.sort(by="bldg_id")

            for data_type in data_types:

                # Downselect columns based on the data type
                wtd_agg_outs_for_data_type = wtd_agg_outs  # TODO .select(ordered_cols[data_type])

                pqt_dir = f"{agg_level_dir}/{data_type}/parquet"
                csv_dir = f"{agg_level_dir}/{data_type}/csv"

                # Write the parquet files in one streaming pass, one file per geography combo
                pqt_tstart = datetime.datetime.now()
                if geo_col_names:
                    pqt_target = pl.PartitionBy(
                        to_polars_path(pqt_dir),
                        key=geo_col_names,
                        file_path_provider=_make_partition_path_provider(
                            partition_cols, upgrade_id, agg_suffix, data_type, "parquet"),
                        include_key=True,
                    )
                    pqt_scan_path = f"{pqt_dir}/**/*.parquet"
                else:
                    # No partition columns (e.g. national): write a single file
                    pqt_scan_path = f"{pqt_dir}/{_export_file_name([], upgrade_id, agg_suffix, data_type)}.parquet"
                    pqt_target = to_polars_path(pqt_scan_path)
                logger.info(f"Sinking parquet files to {pqt_dir}")
                wtd_agg_outs_for_data_type.sink_parquet(pqt_target, mkdir=True, engine="streaming",
                                                        storage_options=storage_options)
                logger.info(f"Parquet sink time for {aggregation_level} {data_type}: "
                            f"{(datetime.datetime.now() - pqt_tstart).total_seconds()} seconds")

                # Re-scan the parquet files just written (already aggregated, joined, and
                # sorted) and write the CSVs from them instead of re-executing the query above
                if "csv" in file_types:
                    csv_tstart = datetime.datetime.now()
                    pqt_written = pl.scan_parquet(to_polars_path(pqt_scan_path),
                                                  hive_partitioning=False,
                                                  storage_options=storage_options)
                    if geo_col_names:
                        csv_target = pl.PartitionBy(
                            to_polars_path(csv_dir),
                            key=geo_col_names,
                            file_path_provider=_make_partition_path_provider(
                                partition_cols, upgrade_id, agg_suffix, data_type, "csv.gz"),
                            include_key=True,
                        )
                    else:
                        csv_target = to_polars_path(
                            f"{csv_dir}/{_export_file_name([], upgrade_id, agg_suffix, data_type)}.csv.gz")
                    logger.info(f"Sinking csv.gz files to {csv_dir}")
                    pqt_written.sink_csv(csv_target, compression="gzip", check_extension=False,
                                         mkdir=True, engine="streaming", storage_options=storage_options)
                    logger.info(f"CSV sink time for {aggregation_level} {data_type}: "
                                f"{(datetime.datetime.now() - csv_tstart).total_seconds()} seconds")

                # The parquet files are the source for the CSVs, so they are always written;
                # remove them afterward if parquet wasn't a requested file type
                if "parquet" not in file_types:
                    logger.info(f"Removing parquet files from {pqt_dir}: parquet not in file_types")
                    output_dir["fs"].rm(pqt_dir, recursive=True)

            logger.info(f"Total time for {aggregation_level}: "
                        f"{(datetime.datetime.now() - agg_lvl_tstart).total_seconds()} seconds")

        ge_tend = datetime.datetime.now()
        logger.info(f"Finished exporting: {geo_top_dir}. ")
        logger.info(f"Partitioned by: {geo_col_names}")
        logger.info(f"Geographic aggregation levels: {aggregation_levels}")
        logger.info(f"Time elapsed: {(ge_tend - ge_tstart).total_seconds()} seconds")

    return f"Finished {len(geo_exports)} geo exports for upgrade {upgrade_id} in {(datetime.datetime.now() - tstart).total_seconds()} seconds."


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
