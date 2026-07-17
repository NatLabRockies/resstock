# Upgrade Comparison

The upgrade comparison tool generates quality-control and summary visualizations between multiple upgrades and baseline from a ResStock simulation run. The tool for comparison of baseline results with data from EIA and other sources are found in baseline_validation folder.

## Input / Output

This tool takes the s3 results folder and list of upgrades to compares as an input and produces folders full of upgrade comparison plots as an output.

### Input

**`workflow.yaml` (main input)**
Most users only need to edit this file. Make sure the required keys are set for every run:

- `s3_results_dir` – S3 prefix (or filesystem path) where the parquet outputs for each upgrade live; upgrade `0` is the baseline.
- `output_dir` – Local directory that will receive downloaded parquet data, generated plots, and other artifacts.
- `run_name` – Namespaces the outputs so multiple comparison runs can share the same `output_dir`.
- `upgrades` – List of upgrade indexes to include in the comparison.
- `upgrade_names` – Human-readable labels aligned with the `upgrades` list; these appear in legends and table headers.

Optional keys (pre-populated defaults)
Tweak these only when you need to customize quantities, plots, or filtering beyond the standard setup:

- `numerical_quantities` – Definitions for energy, bills, and panel metrics that are summed or aggregated when computing deltas.
- `categorical_quantities` – Buckets for yes/no or enumerated metrics that drive categorical comparisons.
- `visualization_types` – Allowed plot styles to render for each quantity/grouping combination.
- `group_by` – Dimensions (vintage, fuel, geography, etc.) used to pivot the comparisons.
- `quantity_types` – Metrics to calculate (absolute values, savings, percent savings, model counts, prevalence).
- `aggregation_types` – How to aggregate each quantity (totals, averages, distributions).
- `building_inclusion` – Whether to analyze all simulated homes or only those where an upgrade applied.
- `vacancy_inclusion` – Controls whether vacant homes remain in the comparison set.

**`highlights.yaml` (optional highlights)**
This file seeds a short list of “headline” comparisons that are generated before the full plot grid. Most users can keep the stock configuration, but you can curate the combinations you care about most (for example, a specific quantity and grouping). Highlight outputs land in the `Highlights (html)` and `Highlights (svg)` folders so they are easy to spot alongside the comprehensive plot matrix.

### Output

The parquet files downloaded from s3 are placed inside `<output_dir>/s3_data/<s3_path>`. All plot artifacts land under `<output_dir>/plots/<run_name>/` and are organized by product type:

- `Highlights (html)` / `Highlights (svg)`: Focused comparisons rendered as interactive htmls and static SVGs. These typically showcase upgrade deltas for energy and bills and their distribution.
- `All combinations/<quantity>/<aggregation>/<viz>/html`: Interactive Plotly figures for every requested combination. Available visualizations include stacked bar comparisons, grouped box plots, histograms of upgrade deltas, heatmaps for geographic rollups, and choropleths when spatial data is present.
- `All combinations/.../svg`: Vector exports suitable for embedding in reports or slide decks.
- `All combinations/.../data`: Parquet (and optional CSV) snapshots of the prepared data that feeds each figure—handy for ad-hoc analysis outside the dashboard.
- `All combinations/.../figure_json`: Serialized Plotly JSON for embedding or further customization. This is also
  loaded by dynamic_dashboard to avoid re-computing the figure everytime.
- `workflow_snapshot.json`: Frozen copy of the validated workflow configuration, ensuring provenance for every chart set.

## Prerequisites

- Start by following the installation and environment setup steps in `postprocessing/README.md`. That configures `uv` and installs the Python dependencies shared by every postprocessing tool.
- You should have AWS credentials setup so that the parquet files can be downloaded from s3. This typically means you have logged in to AWS using SSO.

## Running the Generator

Execute the CLI from the postprocessing folder (after completing the shared setup):

```bash
resstock/postprocessing> uv run resstockpostproc/upgrade_comparison/main.py
```

Inspect the available flags at any time with `--help`:

```bash
resstock/postprocessing> uv run resstockpostproc/upgrade_comparison/main.py --help
```

```
usage: main.py [-h] [--config CONFIG] [--output OUTPUT]
               [--quantity_group QUANTITY_GROUP] [--overwrite]
               [--max-plots MAX_PLOTS] [--highlights_only]

Generate standard QC plots for ResStock simulation results

options:
  -h, --help            show this help message and exit
  --config CONFIG       Path to plot configuration YAML file
  --output OUTPUT       Output file types to generate (svg, html, parquet,
                        json, csv). May be specified multiple times or as a
                        comma-separated list. Defaults to [json, parquet,
                        html] if not specified.
  --quantity_group QUANTITY_GROUP
                        Name of a quantity group to include in plot
                        generation. May be specified multiple times. If
                        omitted, all quantity groups in the workflow are
                        processed.
  --overwrite           Overwrite existing output files
  --max-plots MAX_PLOTS Maximum number of plots to generate
  --highlights_only     Generate highlights and exit without producing the
                        full plot grid of all combinations.
```

The tool will download parquet files from s3, prepares data for each visualization, and writes both data and the plots to the specified output directory. It will first generate the highlights followed by the full combinations specified in the workflow.yaml.

## Dashboard (Optional)

The generator produces static directories of HTML plots, SVGs, JSON, and parquet tables. Two optional Dash front ends make those artifacts easier to consume (or generate):

**Basic dashboard**
`basic_dashboard.py` is a lightweight file browser built on Dash. It walks the plot directory tree (including the Highlights folders) and renders any HTML file you select in an embedded iframe. Think of it as a specialized Finder/Explorer that understands the BuildStock output layout, so you can flip through plots rapidly without opening them one by one in a browser window. Because it only reads what is already on disk, it cannot create new plots or change the configuration.

```bash
resstock/postprocessing> uv run resstockpostproc/upgrade_comparison/dashboard/basic_dashboard.py
```

Then go to http://127.0.0.1:8050 to view the dashboard.

**Dynamic dashboard**
`dynamic_dashboard.py` layers on the same plotting definitions, data-processing pipeline, and Plotly engines used by the CLI, but wraps them in a richer browsing UI. You can page through the plots generated by the CLI using a polished layout, or pivot into new combinations on demand. Change group-bys, quantities, aggregations, and filters to explore scenarios that were not part of the original `All combinations` export—ideal when you need deeper analysis without re-running the generator.

```bash
resstock/postprocessing> uv run python resstockpostproc/upgrade_comparison/dashboard/dynamic_dashboard.py
```

Then go to http://127.0.0.1:8051 to view the dashboard.

Both dashboards surface the Plotly download menu (hover in the top-right corner of the figure) so you can grab an SVG for reports or presentations. Launch them only after the comparison workflow has populated `<output_dir>/plots/<run_name>/`.

## Developing and Testing

- Run pytests:

```bash
resstock/postprocessing> uv run pytest resstockpostproc/upgrade_comparison/tests
```

- Run the pre-commit tests

```bash
resstock/postprocessing> pre-commit run --all-files --show-diff-on-failure
```
