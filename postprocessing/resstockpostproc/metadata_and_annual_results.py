import datetime
import gzip
import os
import polars as pl
import pyarrow.parquet as papq
import logging
import s3fs

from concurrent.futures import ThreadPoolExecutor, as_completed
from functools import lru_cache

from resstockpostproc.utils import (
    col_name_to_weighted,
    conversion_factor,
    get_col_maps,
    units_from_col_name,
)
from resstockpostproc.simulation_outputs import (
    downselect_and_order_pub_cols,
    get_cached_simulation_outputs_for_upgrade,
)
from resstockpostproc.allocated_weights import (
    STATE_BILL_COL_PATTERN,
    UTILITY_BILL_COL_PREFIX,
    get_allocated_weights_plus_util_bills_for_upgrade,
)

logger = logging.getLogger(__name__)


def aggregate_allocated_weights_to_geography(alloc_wts,
                                            geography_filters={},
                                            geographic_aggregation_levels=["in.nhgis_tract_gisjoin"]) -> pl.LazyFrame:
    """
    Aggregates the allocated weights to the specified geographic levels after filtering by the given geography.
    Args:
        alloc_wts: LazyFrame containing allocated weights and utility bills
        geography_filters: Dict specifying the geographic filters to apply
        geographic_aggregation_levels: List of geographic levels to aggregate to

    Returns:
        LazyFrame with aggregated allocated weights and utility bills
    """

    logger.info(
        f"Filtering allocated weights to: {geography_filters} "
        f"and aggregating to: {geographic_aggregation_levels}"
    )

    # Filter to specified geography
    if len(geography_filters) > 0:
        geo_filter_exprs = [(pl.col(k) == v) for k, v in geography_filters.items()]
        alloc_wts = alloc_wts.filter(geo_filter_exprs)

    # Drop the housing units the fallback ladder could not match to any simulated building.
    # They carry no bldg_id, so there are no simulation outputs to publish against them, and
    # the join onto the simulation outputs would silently drop them anyway (one row per state
    # once aggregated). Dropping them here keeps the export's row-count check meaningful.
    # create_allocated_weights() reports how many there are and writes allocation_miss_report.parquet.
    alloc_wts = alloc_wts.filter(pl.col("bldg_id").is_not_null())

    # Get names of geography columns to group by
    geo_agg_cols = []
    if geographic_aggregation_levels != ["national"]:
        geo_agg_cols = [pl.col(c) for c in geographic_aggregation_levels]

    # The utility bill columns the allocated weights carry: each housing unit's bills (and bill
    # savings) for the state it was allocated to, per housing unit and unweighted. See
    # create_allocated_weights_plus_util_bills_for_upgrade. Absent for a run without the
    # "Sampling Region" bill scenario, in which case no bills are published.
    cost_cols = [col for col in alloc_wts.collect_schema().names() if col.startswith(UTILITY_BILL_COL_PREFIX)]

    # Sum the weights by building ID within each geography, and average the bills over the
    # housing units the building represents there, weighted by those housing units. Every
    # geography level published nests within states, where every housing unit of a building
    # carries the same state bill, so the average is that bill; over a geography spanning
    # states it is the housing-unit-weighted average of the state bills. The columns keep
    # their names so they publish as the per-building bills the column definitions list.
    # Rounded to cents, as the simulated bills are, so the sum-then-divide does not leave
    # floating point noise behind on what is usually an average of identical values.
    weight_sum = pl.col("weight").sum()
    wtd_agg_outs = alloc_wts.select(
        [
            pl.col("weight"),
            pl.col("upgrade"),
            pl.col("bldg_id"),
            # pl.col("in.sqft..ft2")
        ]
        + geo_agg_cols
        + cost_cols
    ).group_by(
        [
            pl.col("upgrade"),
            pl.col("bldg_id")
        ]
        + geo_agg_cols
    ).agg(
        [weight_sum]
        + [((pl.col(col) * pl.col("weight")).sum() / weight_sum).round(2).alias(col) for col in cost_cols]
        # + [pl.col(["in.sqft..ft2"]).first()]
    )

    # logger.info(f"wtd_agg_outs schema: {wtd_agg_outs.collect_schema()}\n\n")

    return wtd_agg_outs


def drop_state_utility_bill_columns(sim_outs: pl.LazyFrame) -> pl.LazyFrame:
    """Drop the per-state utility bill columns (out.utility_bills.ak_total_bill..usd, ...) from the
    simulation outputs. They exist to be unpivoted into the allocated weights plus bills, which
    carry each housing unit's allocated-state bills under the generic names; the published
    outputs must carry only those. Dropping them here also takes some 1,000 columns out of the
    wide join.

    Args:
        sim_outs: Cached simulation outputs for one upgrade

    Returns:
        The outputs without their per-state bill columns
    """

    state_bill_cols = [col for col in sim_outs.collect_schema().names() if STATE_BILL_COL_PATTERN.match(col)]
    if state_bill_cols:
        logger.info(f"Dropping {len(state_bill_cols)} per-state utility bill columns from the simulation outputs")
        sim_outs = sim_outs.drop(state_bill_cols)
    return sim_outs


def _create_export_file_name(geo_prefixes, upgrade_id, agg_suffix, data_type) -> str:
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


def _process_and_write_geo_data(output_dir, geog_agg_alloc_wts, sim_outs, geo_key, is_tract_level,
                                 pqt_path, csv_path, write_parquet, write_csv,
                                 slice_rows=200_000) -> None:
    """
    Builds and writes the full-width export table for one geography (e.g. one county).
    The simulation outputs (wide, many columns) are joined to the
    aggregated allocated weights (long, many rows),
    then the geospatial columns are added based on the most informative geographic resolution.

    The simulation outputs (800+ column) table is assembled in slices of `slice_rows` rows,
    appending each slice to the parquet file (as a row group) and to the gzipped
    CSV stream. This bounds peak memory to a few slices (~1.5 GB each) even for
    the largest geographies (e.g. Los Angeles county at tract resolution, whose
    full table is ~10 GB). Streaming sinks are deliberately NOT used here:
    streaming an 800+ column join output holds tens of GB of in-flight morsels.

    The aggregated allocated weights are sorted by bldg_id before slicing, so the slices cover
    consecutive bldg_id ranges and the concatenated output is globally sorted.
    """
    fs = output_dir["fs"]

    geog_agg_alloc_wts = geog_agg_alloc_wts.sort(by="bldg_id")
    n_rows = geog_agg_alloc_wts.height

    # Create the parent directories (local filesystems only; S3 has no dirs)
    if not isinstance(fs, s3fs.S3FileSystem):
        for path, requested in ((pqt_path, write_parquet), (csv_path, write_csv)):
            if requested:
                fs.mkdirs(path.rsplit("/", 1)[0], exist_ok=True)

    pqt_writer = None
    pqt_f = csv_f = gz_f = None
    try:
        if write_parquet:
            pqt_f = fs.open(pqt_path, "wb")
        if write_csv:
            csv_f = fs.open(csv_path, "wb")
            # compresslevel 6 (the standard gzip default) is ~2x faster than the
            # GzipFile default of 9, for only a few percent larger files
            gz_f = gzip.GzipFile(fileobj=csv_f, mode="wb", compresslevel=6)

        # Slice the geography into manageable slices of buildings
        for offset in range(0, n_rows, slice_rows):
            # Every slice of a geography is assembled the same way, so only the first
            # slice logs; otherwise each message repeats once per slice per geography.
            first_slice = offset == 0
            geog_agg_alloc_wts_slice = geog_agg_alloc_wts.slice(offset, slice_rows).lazy()

            # Join the aggregated allocated weights to the simulation outputs by building ID and upgrade ID
            geog_results = geog_agg_alloc_wts_slice.join(sim_outs, on=[pl.col("upgrade"), pl.col("bldg_id")])

            # Calculate the weighted columns
            geog_results = add_weighted_cols(geog_results, log=first_slice)

            # Add geospatial data columns based on most informative geography column
            geog_results = add_geospatial_columns(geog_results, geo_key)

            # Add other columns that can only be added based on census tract
            if is_tract_level:
                geog_results = add_electric_utility_column(geog_results, geo_key)
                # TODO wide = add_cejst_columns(wide)
                # TODO wide = add_ejscreen_columns(wide)

            # Add income and burden columns based on the assigned geography
            # TODO Calculate the income and burden columns based on the assigned geography
            # geog_results = add_income_and_burden(geog_results)

            # Collect the results for this slice of this geography
            geog_results = geog_results.collect().sort(by="bldg_id")

            # Every allocated (bldg_id, geography) row must survive the joins exactly once.
            # Fail loudly rather than writing a file with missing (or duplicated) buildings.
            n_slice_rows = min(slice_rows, n_rows - offset)
            if geog_results.height != n_slice_rows:
                raise ValueError(
                    f"Row count changed while assembling {pqt_path if write_parquet else csv_path}: "
                    f"expected {n_slice_rows:,} rows in slice at offset {offset:,} but got "
                    f"{geog_results.height:,}. Rows were dropped or duplicated by a join "
                    f"(simulation outputs, geospatial lookup, or electric utility lookup)."
                )

            # Downselect and order columns based on the export's data_type
            col_maps = get_col_maps()
            geog_results = downselect_and_order_pub_cols(  # Per sdr_column_definitions.csv
                geog_results, col_maps, log=first_slice
            )

            # Write the files
            if write_parquet:
                table = geog_results.to_arrow()
                if pqt_writer is None:
                    pqt_writer = papq.ParquetWriter(pqt_f, table.schema, compression="zstd")
                pqt_writer.write_table(table)
            if write_csv:
                geog_results.write_csv(gz_f, include_header=(offset == 0))
    finally:
        if pqt_writer is not None:
            pqt_writer.close()
        if pqt_f is not None:
            pqt_f.close()
        if gz_f is not None:
            gz_f.close()
        if csv_f is not None:
            csv_f.close()


def export_metadata_and_annual_results_for_upgrade(
    output_dir, upgrade_id, geo_exports, write_workers=4, slice_rows=200_000
) -> None:
    """
    Subdivides the annual results by geography and writes to OEDI.
    Creates .parquet and .csv.gz files.

    Peak memory is kept bounded regardless of dataset size:
    - Only the narrow (few-column) aggregated allocated weights are ever processed in bulk,
      one state at a time (via the 'state' hive column of the cached allocated
      weights, so only that state's cache file is read per pass).
    - The wide (800+ column) simulation outputs are loaded into memory once and
      joined per output geography: each output file's table is assembled in
      memory one geography at a time, sorted, and written. The largest single
      geography (Los Angeles county at tract resolution) is ~10 GB.

    Args:
        output_dir: Dict of filesystem object information
        upgrade_id: Integer ID for the upgrade to process
        geo_exports: List of Dicts of export definitions
        write_workers: Number of geography combos to assemble and write
            concurrently. Each worker holds a few ~1.5 GB slices in memory, and
            the gzip CSV compression is single-threaded per worker, so this is
            the main throughput knob for the CSV-bound portion of the export.
    Returns:
        None

    """

    logger.info(f"Exporting metadata and annual results for upgrade {upgrade_id}")
    logger.info(f"Using {write_workers} workers")
    logger.info(f"Processing geographies in slices of {slice_rows} buildings each.")

    # Read the cached simulation results fully into memory (~4 GB). They are joined
    # against every geography combo, so keeping them resident avoids re-reading
    # the parquet file thousands of times.
    sim_tstart = datetime.datetime.now()
    up_sim_outs_df = get_cached_simulation_outputs_for_upgrade(output_dir, upgrade_id).collect(engine="streaming")
    logger.info(f"Loaded simulation outputs: {up_sim_outs_df.height:,} rows x {up_sim_outs_df.width} cols, "
                f"{up_sim_outs_df.estimated_size()/1e9:.1f} GB in memory, "
                f"{(datetime.datetime.now() - sim_tstart).total_seconds():.0f} seconds")
    up_sim_outs = up_sim_outs_df.lazy()

    # CRITICAL to drop the weight column from the simulation outputs
    # if buildstockbatch didn't already do this,
    # otherwise the weight column from the allocated weights would be ignored.
    if "weight" in up_sim_outs_df:
        logger.info("Removing weight column from simulation outputs, using weight column from allocated weights.")
        up_sim_outs = up_sim_outs.drop("weight")

    # The per-state bill columns have done their job in the allocated weights plus bills;
    # only the allocated state's bills are published, and they arrive with the weights.
    up_sim_outs = drop_state_utility_bill_columns(up_sim_outs)

    # Get the allocated weights plus utility bills for the upgrade
    up_alloc_wts_plus_bills = get_allocated_weights_plus_util_bills_for_upgrade(output_dir, upgrade_id)

    # Pre-warm the cached lookup tables from the main thread. lru_cache doesn't
    # lock during computation, so without this the first batch of worker threads
    # would all read the files simultaneously (harmless, but redundant and noisy).
    _get_elec_util_lookup()
    for geog in ["in.nhgis_tract_gisjoin", "in.nhgis_county_gisjoin", "in.nhgis_puma_gisjoin", "in.state"]:
        _get_geospatial_lookup(geog)
    get_col_maps()

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

            # TODO Determine the starting column downselection from data_types
            # once column downselection is implemented

            # Tract is the least-aggregated level published; it goes to
            # /metadata_and_annual_results and everything else goes to
            # /metadata_and_annual_results_aggregates
            is_full_resolution = aggregation_level == "in.nhgis_tract_gisjoin"
            agg_level_dir = full_geo_dir if is_full_resolution else full_geo_agg_dir
            agg_suffix = "" if is_full_resolution else "_agg"

            agg_lvl_list = [aggregation_level]
            if isinstance(aggregation_level, list):
                agg_lvl_list = aggregation_level  # Pass list if a list is already supplied
            geo_key = agg_lvl_list[0]
            is_tract_level = agg_lvl_list == ["in.nhgis_tract_gisjoin"]

            # Aggregation levels that nest within states. Passes for these levels can be
            # chunked state-by-state without splitting any aggregation group across chunks.
            state_nested_agg_levels = {
                "in.nhgis_tract_gisjoin",
                "in.nhgis_county_gisjoin",
                "in.nhgis_puma_gisjoin",
                "in.nhgis_state_gisjoin",
                "in.state",
            }

            # Process one state at a time when possible to bound peak memory.
            # The chunk filter is on the 'state' hive column of the cached allocated
            # weights, so each pass only reads that state's cache file.
            chunk_by_state = bool(geo_col_names) and all(lvl in state_nested_agg_levels for lvl in agg_lvl_list)
            if chunk_by_state:
                state_chunks = (up_alloc_wts_plus_bills
                                .select(pl.col("state").unique())
                                .collect(engine="streaming")
                                .to_series().sort().to_list())
            else:
                state_chunks = [None]  # Single pass with no chunk filter

            for data_type in data_types:

                # TODO Downselect columns based on the data type

                pqt_dir = f"{agg_level_dir}/{data_type}/parquet"
                csv_dir = f"{agg_level_dir}/{data_type}/csv"
                write_parquet = "parquet" in file_types
                write_csv = "csv" in file_types
                n_files = 0

                for state_chunk in state_chunks:
                    chunk_tstart = datetime.datetime.now()
                    chunk_filter = {} if state_chunk is None else {"state": state_chunk}

                    # Aggregate the allocated weights for this state chunk
                    # so there is one row per unique bldg_id
                    agg_alloc_wts = (aggregate_allocated_weights_to_geography(
                                    up_alloc_wts_plus_bills, chunk_filter, agg_lvl_list)
                                 .collect(engine="streaming"))

                    # Determine the partition column values (e.g. state/county) for each
                    # row via the geospatial lookup, joining only the unique geography
                    # keys. These columns are only used to split the rows into files and
                    # are dropped again so each dataframe keeps the original column set.
                    added_part_cols = [c for c in geo_col_names if c not in agg_alloc_wts.columns]
                    if added_part_cols:
                        assignments = (
                            add_geospatial_columns(agg_alloc_wts.select(pl.col(geo_key)).unique().lazy(), geo_key)
                            .select([geo_key] + added_part_cols)
                            .unique()
                            .collect()
                        )
                        agg_alloc_wts = agg_alloc_wts.join(assignments, on=geo_key, how="inner")

                    # Split the aggregated allocated weights into one per geography
                    if geo_col_names:
                        per_geog_agg_alloc_wts = agg_alloc_wts.partition_by(geo_col_names, as_dict=True)
                    else:
                        per_geog_agg_alloc_wts = {(): agg_alloc_wts}

                    # Log the size of this chunk and of its largest single geography
                    # (the largest geography bounds each worker's peak memory)
                    max_geog_rows = max((df.height for df in per_geog_agg_alloc_wts.values()), default=0)
                    chunk_desc = f"state {state_chunk}" if state_chunk is not None else "single chunk"
                    logger.info(f"Aggregated allocated weights for {chunk_desc}: {agg_alloc_wts.height:,} rows across "
                                f"{len(per_geog_agg_alloc_wts)} geographies, "
                                f"max rows in one geography: {max_geog_rows:,}")

                    # Assemble each greography's full-width table in memory and write it.
                    # Concurrency is limited so at most `write_workers` greographies are
                    # held in memory at once.
                    with ThreadPoolExecutor(max_workers=write_workers) as executor:
                        futures = []
                        for geog_vals, geog_agg_alloc_wts in per_geog_agg_alloc_wts.items():
                            vals = [str(v) for v in geog_vals]
                            geo_level_dirs = "/".join(
                                f"{partition_cols[c]}={v}" for c, v in zip(geo_col_names, vals))
                            file_dir = f"{geo_level_dirs}/" if geo_level_dirs else ""
                            file_name = _create_export_file_name(vals, upgrade_id, agg_suffix, data_type)
                            pqt_path = f"{pqt_dir}/{file_dir}{file_name}.parquet"
                            csv_path = f"{csv_dir}/{file_dir}{file_name}.csv.gz"
                            geog_agg_alloc_wts_cols_remvd = geog_agg_alloc_wts.drop(added_part_cols)
                            futures.append(executor.submit(
                                _process_and_write_geo_data, output_dir, geog_agg_alloc_wts_cols_remvd, up_sim_outs,
                                geo_key, is_tract_level, pqt_path, csv_path, write_parquet, write_csv, slice_rows))
                        for future in as_completed(futures):
                            future.result()  # Surface any exception from the worker

                    n_files += len(per_geog_agg_alloc_wts)
                    if state_chunk is not None:
                        logger.info(f"Wrote {len(per_geog_agg_alloc_wts)} geographies for state {state_chunk} in "
                                    f"{(datetime.datetime.now() - chunk_tstart).total_seconds():.0f} seconds")

                logger.info(f"Wrote {n_files} geographies for {aggregation_level} {data_type}")

            logger.info(f"Total time for {aggregation_level}: "
                        f"{(datetime.datetime.now() - agg_lvl_tstart).total_seconds()} seconds")

        ge_tend = datetime.datetime.now()
        logger.info(f"Finished exporting: {geo_top_dir}. ")
        logger.info(f"Partitioned by: {geo_col_names}")
        logger.info(f"Geographic aggregation levels: {aggregation_levels}")
        logger.info(f"Time elapsed: {(ge_tend - ge_tstart).total_seconds()} seconds")

    return (
        f"Finished {len(geo_exports)} geo exports for upgrade {upgrade_id} in "
        f"{(datetime.datetime.now() - tstart).total_seconds()} seconds."
    )


@lru_cache(maxsize=1)
def _read_geospatial_lookup_file() -> pl.DataFrame:
    """Reads the geospatial lookup table file. Cached so the file is read only once."""
    geospatial_file = "spatial_tract_lookup_table_publish_v11.csv"
    geospatial_file_path = os.path.abspath(os.path.join(__file__, "..", "resources", "gisdata", geospatial_file))
    logger.info(f"Reading geospatial data file from {geospatial_file_path}")
    return pl.read_csv(geospatial_file_path, infer_schema_length=None)


@lru_cache(maxsize=8)
def _get_geospatial_lookup(geography_to_join_on) -> pl.DataFrame:
    """
    Downselects/dedupes the geospatial lookup table for the given geography
    column. Cached because this is called for every geography
    (and every slice within a geography) during an export.
    """

    geospatial_data = _read_geospatial_lookup_file()

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

    return geospatial_data


def add_geospatial_columns(input_lf: pl.LazyFrame, geography_to_join_on) -> pl.LazyFrame:
    supported_geogs = ["in.nhgis_tract_gisjoin", "in.nhgis_county_gisjoin", "in.nhgis_puma_gisjoin", "in.state"]
    if geography_to_join_on not in supported_geogs:
        logger.debug(f"Cannot add more geospatial columns based on {geography_to_join_on}")
        return input_lf
    logger.debug(f"Adding geospatial columns based on {geography_to_join_on}")

    # Join on the (cached) geospatial data. A left join so that a geography missing from
    # the lookup keeps its rows (with null geospatial columns) rather than silently
    # dropping every building in it.
    input_lf = input_lf.join(_get_geospatial_lookup(geography_to_join_on).lazy(), on=geography_to_join_on, how="left")

    return input_lf


@lru_cache(maxsize=1)
def _get_elec_util_lookup() -> pl.DataFrame:
    """
    Reads the tract-to-electric-utility lookup table. Cached because this is
    called for every geography combo (and every slice) during an export.
    """
    elec_util_file = "tract_to_elec_util_v2.csv"
    elec_util_file_path = os.path.abspath(os.path.join(__file__, "..", "resources", "gisdata", elec_util_file))
    logger.info(f"Reading electric utility data file from {elec_util_file_path}")
    return pl.read_csv(elec_util_file_path, infer_schema_length=None)


def add_electric_utility_column(input_lf: pl.LazyFrame, geography_to_join_on) -> pl.LazyFrame:
    supported_geogs = ["in.nhgis_tract_gisjoin"]
    if geography_to_join_on not in supported_geogs:
        logger.debug(f"Cannot add electric utility column based on {geography_to_join_on}")
        return input_lf
    logger.debug(f"Adding electric utility column based on {geography_to_join_on}")

    # Join on the (cached) electric utility data. A left join so that a tract missing from
    # the lookup keeps its rows (with a null utility code) rather than silently dropping
    # every building in it. Some AK, HI, AZ, and SD tracts are absent from the v2 lookup.
    input_lf = input_lf.join(_get_elec_util_lookup().lazy(), on=geography_to_join_on, how="left")

    return input_lf


def add_weighted_cols(df: pl.LazyFrame, log: bool = True) -> pl.LazyFrame:
    if log:
        logger.info("Adding weighted columns")
    all_cols = df.collect_schema().names()
    wtd_cols = [col for col in all_cols if "out." in col and (
        ".energy_consumption." in col or
        ".energy_savings." in col or
        ".emissions." in col or
        ".emissions_reduction." in col or
        ".utility_bills." in col
        )]

    wtd_col_unit_convs = {
        "kwh": "tbtu",
        "co2e_kg": "co2e_mmt",
        "usd": "billion_usd",
    }

    for col in wtd_cols:
        old_units = units_from_col_name(col)
        new_units = wtd_col_unit_convs[old_units]
        conv_fact = conversion_factor(old_units, new_units)
        wtd_col_name = col_name_to_weighted(col, new_units)
        df = df.with_columns(
            pl.col(col)
            .mul(pl.col("weight"))
            .mul(conv_fact)
            .alias(wtd_col_name)
        )

    return df
