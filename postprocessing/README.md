# ResStock Postprocessing

This package automates the common postprocessing tasks that are part of running ResStock. It is
used by BuildStockBatch to transform the results to its final format.

## Installation

To install the package, we recommend using `uv` for Python package management.

### Set up uv

1. Install `uv` if you don't have it already:

   ```bash
   # Mac
   wget -qO- https://astral.sh/uv/install.sh | sh

   # Windows Powershell
   powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
   ```

   (More info: https://docs.astral.sh/uv/getting-started/installation/)

2. Create a new virtual environment and install dependencies using the following command:
   (If it fails the first time, try running `uv sync` again)

   ```bash
   cd path/to/postprocessing
   uv sync
   ```

3. (Recommended) Install the shared `pre-commit` hooks so formatting, spelling, and lint checks
   run automatically before each commit. This is a must if you are going to contribute code:

   ```bash
   cd path/to/postprocessing
   uv run --group dev pre-commit install
   ```

4. Run the scripts as desired
   ```bash
   # Output the failure log
   cd path/to/postprocessing
   uv run resstockpostproc/get_failures.py <csv_path> --verbose

   # Export metadata and annual results from files on S3
   uv run resstockpostproc/process_bsb_results.py "s3://res-sdr/testing-sdr-fy25/a_run" "C:/path/to/bsb/output/a_run_output"

   # Export metdata and annual results from local files
   # (It is faster to download the /baseline and /upgrades directories from S3 once instead of reading from S3 each time)
   uv run resstockpostproc/process_bsb_results.py "C:/path/to/bsb/output/a_run" "C:/path/to/bsb/output/a_run_output"

   # Export metdata and annual results to OEDI
   uv run resstockpostproc/process_bsb_results.py "C:/path/to/bsb/output/a_run" "s3://oedi-data-lake/nrel-pds-building-stock/end-use-load-profiles-for-us-building-stock/2025/resstock_amy2018_release_1"
   ```

## Workflow

### Simulation Outputs

The first step is to process the **Simulation Outputs**. These are the raw results from
BuildStockBatch, which include one row per building simulation.

`process_simulation_outputs()` takes the raw baseline and upgrade results and transforms each
upgrade into a publication-ready table by:

- Setting the baseline applicability to `True` for all baseline buildings.
- Adding the building characteristic input columns that are present in the baseline but missing
  from the upgrade.
- Removing buildings that failed in the baseline, as well as buildings that failed in the current
  upgrade or where the upgrade was not applicable.
- Replacing missing (non-applicable) upgrade building rows with their baseline building rows.
- Downselecting and renaming columns per the column definitions.
- Deriving geographic columns (county and PUMA) from the building metadata.
- Adding the baseline/upgrade name and upgrade ID columns, and renaming upgrades to their
  human-readable names.
- Fixing the site energy total and correcting all-fuel emissions columns.
- Adding panel-constraint columns and downselecting the fuel/emissions columns.
- Calculating savings columns relative to the baseline (baseline savings are intentionally zero).
- Adding intensity and weighted columns.
- Filling in any missing upgrade columns so the schema matches across all upgrades, adjusting
  column data types, and ordering the final published columns.

Each processed upgrade is cached as its own parquet file so it can be reused by later steps.

### Allocated Weights

The second step is to create a table of **Allocated Weights**. Because each building is simulated
in a single representative location, this step distributes (allocates) each sampled building
across the real geographic units (tracts) it represents and assigns each allocation a weight
(each row represents one housing unit).

`create_allocated_weights()` is the top-level orchestration function that:

1. Sets up the filesystem (local or S3) for the output.
2. Loads the reference data files: the PUMS catalogue, the sampling-region mapping, and the CEC
   2010 climate zones (downloading them from S3 if they are not already cached locally).
3. Merges the geographical data with the sampling-region assignments (county-based for most of the
   US, falling back to CEC climate-zone-based regions for California tracts).
4. Loads the buildstock sample data.
5. Allocates buildings to geographical units. The geographic catalogue has one row per real
   housing unit (from the PUMS catalogue), and the simulated buildings (identified by `bldg_id`,
   read here from the cached baseline simulation outputs) are the pool that housing units are
   drawn from. The simulated buildings are first grouped into pools that share the key
   characteristics used for allocation (sampling region, tenure, vacancy status, building type,
   vintage, heating fuel, and federal poverty level). Then, for each catalogue row, the pool whose
   characteristics match that row is looked up and one of its `bldg_id`s is drawn at random — so
   "the matching pool" is the subset of simulated buildings sharing that row's characteristics,
   and "one building" is a single simulated `bldg_id` (the same ID that is later joined to the
   wide simulation outputs). Each resulting row is one housing unit and gets `weight = 1`.
6. Writes the resulting allocated-weights parquet outputs (the full allocation plus a `fkt`
   foreign-key table mapping buildings to tract and PUMA).

The resulting `cached_allocated_weights.parquet` has exactly 14 columns and one row per housing
unit (`weight` is always `1`). It carries the sampled `bldg_id` plus the catalogue's geographic
and characteristic columns. Below is the schema, shown transposed (columns down the side, one
example housing unit per value column). Rows A and B are the *same* building allocated to two
different tracts, so only the finer geographic columns differ; row C is a different building:

```text
  cached_allocated_weights.parquet — (14 columns, roughly 140M rows)
  1 row per housing unit represents the actual housing stock count per ACS
  column                          | row A           | row B           | row C
  --------------------------------+-----------------+-----------------+-----------------------
  bldg_id                         | 437723          | 437723          | 51205
  weight                          | 1               | 1               | 1
  in.state                        | AL              | AL              | CA
  in.nhgis_state_gisjoin          | G01             | G01             | G06
  in.nhgis_county_gisjoin         | G0100830        | G0100890        | G0600010
  in.nhgis_puma_gisjoin           | G01000200       | G01000200       | G06000104
  in.nhgis_tract_gisjoin          | G0100830021100  | G0100890010502  | G0600010410100
  in.sampling_region_id           | 0               | 0               | 101
  in.tenure                       | Owner           | Owner           | Renter
  in.vacancy_status               | Occupied        | Occupied        | Occupied
  in.geometry_building_type_recs  | Mobile Home     | Mobile Home     | Single-Family Detached
  in.vintage                      | 1940s           | 1940s           | 2000s
  in.heating_fuel                 | Electricity     | Electricity     | Natural Gas
  in.federal_poverty_level        | 0-100%          | 0-100%          | 0-100%
```

The six housing characteristics (`in.tenure` through `in.federal_poverty_level`) plus
`in.sampling_region_id` are the seven keys the building was matched on
when pulling a model from the simulation outputs, so they are identical for
every row that shares a `bldg_id`; the geographic columns are what vary as the building is
allocated across the tracts within its sampling region (rows A and B: same `bldg_id`, same PUMA
and state, different tract and county).

A companion function, `create_allocated_weights_plus_util_bills_for_upgrade()`, joins the
allocated weights with the per-location utility bills so that each building picks up the utility
costs for the specific location it was allocated to.

### Metadata and Annual Results

The final step joins the **Simulation Outputs** with the **Allocated Weights** and writes
the published files, subdivided by geography, to the output location (local or OEDI on S3). For
each upgrade, `export_metadata_and_annual_results()` (via
`export_metadata_and_annual_results_for_upgrade()`) produces `.parquet` and `.csv.gz` files at
several geographic partitions (e.g. national, by state, by state and county, by state and PUMA).

The export always runs as two distinct operations per geography: first the allocated weights are
**aggregated** to the requested geographic resolution, then those aggregated weights are
**joined** onto a subset of the wide simulation outputs. Keeping these two operations separate —
narrow aggregation first, wide join second — is what keeps peak memory bounded.

#### Step 1 — Aggregating allocated weights to a geography

The cached allocated weights are stored at their finest resolution: one row per housing unit (per
building/tract pair, each with `weight = 1`). `aggregate_allocated_weights_to_geography()`
collapses those per-housing-unit rows to one row per building ID **within the target geographic
aggregation level** by grouping on `(upgrade, bldg_id, <aggregation level>)` and **summing** the
weights. The resulting `weight` is therefore the count of housing units that a given simulated
building ID represents in that geography.

This aggregation is deliberately done on the **narrow** table (`weight`, `upgrade`, `bldg_id`,
plus the geography key) before any wide simulation columns are attached, so it stays cheap. It is
also run **one state at a time**: the filter is applied to the `state` hive partition of the
cached allocated weights, so each pass reads only that state's cache file. State-nested
aggregation levels (tract, county, PUMA, state) can be chunked by state without ever splitting an
aggregation group across chunks.

```text
  Allocated Weights (1 row per housing unit)        Aggregated to tract (1 row per building/tract)
  upgrade | bldg_id | in.nhgis_tract_gisjoin | wt   upgrade | bldg_id | in.nhgis_tract_gisjoin | weight
  --------+---------+------------------------+---   --------+---------+------------------------+-------
  0       | 1234    | G0100010020100         | 1     0      | 1234    | G0100010020100         | 3
  0       | 1234    | G0100010020100         | 1  →  0      | 1234    | G0600370101100         | 1
  0       | 1234    | G0100010020100         | 1     0      | 5678    | G0600370101100         | 1
  0       | 1234    | G0600370101100         | 1
  0       | 5678    | G0600370101100         | 1        group_by(upgrade, bldg_id, tract).sum(weight)
```

#### Step 2 — Joining the aggregated weights onto the simulation outputs

Each simulated building represents many real housing units spread across many geographic
locations, but it is simulated only once — so the wide (800+ column) simulation outputs contain a
single row per building. Joining the aggregated weights to the simulation outputs on
`(upgrade, bldg_id)` "fans out" each building's results to every geography it was allocated to,
carrying along that geography's summed `weight`. Because the aggregated weights are on the left of
an inner join, only the **subset** of simulation-output rows for buildings present in that
geography is materialized:

```text
  Aggregated Weights (1 row per building ID per geography)   Simulation Outputs (1 row per building)
  upgrade | bldg_id | tract          | weight         upgrade | bldg_id | site_energy | ... (800+ cols)
  --------+---------+----------------+-------         --------+---------+-------------+------------------
  0       | 1234    | G0100010020100 | 3              0       | 1234    | 42.0        | ...
  0       | 1234    | G0600370101100 | 1              0       | 5678    | 37.5        | ...
  0       | 5678    | G0600370101100 | 1

                          join on (upgrade, bldg_id)
                                  |
                                  v
  Metadata and Annual Results (1 row per building ID per geography, weighted)
  upgrade | bldg_id | tract          | weight | site_energy | ... (800+ cols)
  --------+---------+----------------+--------+-------------+----------------
  0       | 1234    | G0100010020100 | 3      | 42.0        | ...
  0       | 1234    | G0600370101100 | 1      | 42.0        | ...
  0       | 5678    | G0600370101100 | 1      | 37.5        | ...
```

After the join, per-slice the export adds the weighted energy/emissions columns (each raw column ×
`weight` × unit conversion), joins on the geospatial lookup columns (state, county, climate zone,
grid region, etc.) and — at tract resolution only — the electric-utility column, then downselects
and orders the published columns before writing.

#### Memory impact

The join fans a long, narrow table out against an 800+ column table, so the joined result is by far the
largest thing in play. Peak memory is kept bounded regardless of dataset size by the following
choices:

- **The wide simulation outputs are loaded into memory once** (~4 GB) and reused across every
  geography and every upgrade slice, rather than re-read from parquet thousands of times.
- **Only the narrow aggregated weights are processed in bulk**, and only one state at a time (via
  the `state` hive partition), so the bulk grouping never touches the wide columns.
- **Each geography's wide table is assembled in slices** of `slice_rows` buildings (default
  200,000). The aggregated weights are sorted by `bldg_id` first, so slices cover consecutive
  `bldg_id` ranges and the concatenated output is globally sorted. Each slice is joined, weighted,
  collected, and appended to the parquet file (as a row group) and to the gzipped CSV stream, so
  only a few ~1.5 GB slices are ever in flight — even for the largest single geography (Los
  Angeles county at tract resolution, whose full table is ~10 GB).
- **Streaming sinks are deliberately *not* used for the wide join.** Streaming an 800+ column join
  output holds tens of GB of in-flight morsels; explicit slicing gives tighter control over peak
  memory.
- **`write_workers` bounds concurrency**: at most that many geographies are assembled and written
  at once, each holding a few slices. Because gzip CSV compression is single-threaded per worker,
  `write_workers` is the main throughput knob for the CSV-bound portion of the export.
