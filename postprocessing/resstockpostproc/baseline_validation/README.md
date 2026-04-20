# Baseline Validation

The baseline validation tool generates quality-control visualizations comparing BuildStock baseline results with reference data from EIA, RECS, and LRD. This tool validates that the baseline simulation accurately represents real-world energy consumption patterns.

## Overview

Baseline validation is organized around three comparison families that answer different questions about the quality of a BuildStock baseline.

### EIA Comparison

Compares modeled annual and monthly consumption against published EIA reference data:
- **EIA 861** for electricity sales
- **EIA 176** for natural gas sales
- supporting checks such as dwelling-unit counts and state-level rollups

This is the broad system-level validation layer. It answers whether the modeled housing stock matches real-world aggregate energy consumption at state and national scales.

### RECS Comparison

Compares modeled residential behavior against **RECS 2020** survey-based household data:
- end-use consumption comparisons
- end-use penetration comparisons
- annual consumption distribution comparisons
- cross-filtered views by state, census division, building type, climate zone, vintage, and heating fuel

This is the household- and end-use-level validation layer. It answers whether the baseline looks realistic for individual homes and occupant-facing end uses, not just in aggregate totals.

### LRD Comparison

Compares modeled hourly load shapes against **Load Research Data (LRD)** from utilities:
- load duration curves
- hourly and seasonal shape comparisons
- time-series views for utility-level consumption patterns

This is the temporal validation layer. It answers whether the baseline captures realistic timing and shape of load, not just annual or monthly totals.

## Architecture

The tool is organized as a small orchestration layer on top of schema definitions, data loaders, data-processing helpers, plot renderers, and dashboard packaging utilities.

```
baseline_validation/
├── workflow.yaml                  # User-facing run configuration
├── main.py                        # CLI entry point
├── plot_generator.py              # Main orchestration and parallel generation
├── create_html.py                 # Dashboard shell and sharded index generation
├── dashboard_paths.py             # Shared output-path conventions
├── footnotes.py                   # Reference/source footnote helpers
├── resstock_raw.py                # Raw-column resolution helpers for ResStock
├── utils.py                       # Shared utility helpers
├── theme.py                       # Plot styling
├── schema/
│   ├── workflow_schema.py         # Workflow config validation
│   ├── plot_definitions.py        # Code-defined comparison catalog
│   ├── plot_spec.py               # Plot specification model
│   ├── recs_chars_mapping.py      # RECS characteristic mappings
│   └── recs_enduse_mapping.py     # RECS end-use mappings
├── data_processing/
│   ├── gather_data.py             # Core comparison-data assembly
│   ├── histogram_data.py          # Histogram/distribution preparation
│   ├── recs_mapping.py            # RECS label and grouping helpers
│   └── recs_rse.py                # RECS relative standard error handling
├── io_managers/
│   ├── get_eia_data.py            # EIA reference data loading
│   ├── get_recs_data.py           # RECS reference data loading
│   ├── get_lrd_data.py            # LRD reference data loading
│   ├── get_resstock_data.py       # BuildStock result loading
│   ├── comparison_data_paths.py   # Comparison-specific output locations
│   ├── data_table.py              # HTML/CSV data table generation
│   ├── html_utils.py              # Plot HTML post-processing and packaging
│   └── output_manager.py          # Figure and static asset persistence
├── plotters/
│   ├── main_plotter.py            # Shared plot rendering entry points
│   ├── lrd_plotter.py             # Load-shape and LRD plots
│   ├── stacked_plotter.py         # Stacked and split plot generation
│   └── plot_config.py             # Plot styling/config helpers
└── tests/                         # Regression coverage for data, plots, HTML, and CLI
```

### Key Design Principles

1. **Separation of concerns**
   - `main.py` starts a standard run
   - `plot_generator.py` coordinates the workflow
   - `io_managers/` owns loading and persistence
   - `data_processing/` prepares comparison-ready tables
   - `plotters/` turns prepared data into figures
   - `create_html.py` packages the dashboard entrypoint and sharded index

2. **Code-defined comparison catalog**
   - The standard run path is fixed in code
   - `schema/plot_definitions.py` enumerates the comparison templates the tool generates
   - `workflow.yaml` stays small and focused on data sources, reference years, and output location

3. **Reusable packaging pipeline**
   - Interactive plot pages are generated as HTML
   - SVG backups are emitted for the same plots
   - `create_html.py` assembles `comparison_dashboard.html` plus `dashboard_data/`
   - vendored assets keep the dashboard usable offline as a directory bundle


## Input / Output

### Input

**`workflow.yaml` (main configuration)**

This is the primary configuration file. Key settings:

```yaml
workgroup: rescore

data_sources:
  - name: resstock_2025
    db_name: buildstock_sdr
    table_name: resstock_amy2018_r1_2025
    db_schema: resstock_oedi_new

reference_years:
  eia: [2018]
  recs: [2020]

output:
  output_dir: ~/Documents/baseline_validation_outputs
  run_name: baseline_2023_03_16

data_source_labels:
  eia_2018:
    label: "EIA 2018"
    entries: []
```

### Output

All outputs are written to `<output_dir>/<run_name>/`.
Open `comparison_dashboard.html` in that run directory to browse the generated dashboard.

```
baseline_2023_03_16/
├── comparison_dashboard.html
└── dashboard_data/
    ├── assets/
    │   └── plotly-<version>.min.js
    ├── comparisons_index/
    │   ├── combinations.js
    │   └── data-*.js
    ├── comparisons_index.tsv
    ├── trace.json
    ├── eia plots (html)/
    ├── eia plots (svg)/
    ├── eia data (html)/
    ├── eia data (csv)/
    ├── recs plots (html)/
    └── ...
```

**Output formats:**
- `comparison_dashboard.html` - standalone dashboard entrypoint
- `dashboard_data/* plots (html)/` - interactive Plotly visualizations
- `dashboard_data/* plots (svg)/` - SVG backups for HTML plots
- `dashboard_data/* data (html)/` - interactive table views
- `dashboard_data/* data (csv)/` - exported table data

## Prerequisites

1. Follow installation steps in `postprocessing/README.md` to set up the Python environment
2. AWS credentials configured for Athena access (if using cloud data)
3. BuildStockQuery installed: `pip install git+https://github.com/NREL/buildstock-query.git`

## Running the Generator

Execute from the `postprocessing` directory:

```bash
# Basic usage (uses workflow.yaml in baseline_validation/)
uv run resstockpostproc/baseline_validation/main.py

# Specify custom config
uv run resstockpostproc/baseline_validation/main.py --config /path/to/config.yaml
```

### CLI Options

```bash
uv run resstockpostproc/baseline_validation/main.py --help
```

```
usage: main.py [-h] [--config CONFIG]

Generate baseline validation plots comparing BuildStock results with reference data

options:
  -h, --help            show this help message and exit
  --config CONFIG       Path to workflow configuration YAML file
```

## Plot Types

### EIA Comparison Plots

Validates annual and monthly energy consumption against EIA reported data:

- **Annual sales scatter plots** - State and utility level comparisons
- **Customer counts comparison** - BuildStock unit counts vs EIA customer counts
- **Monthly profiles** - Seasonal patterns for electricity and natural gas
- **Fuel-specific validation** - Separate electricity and natural gas analysis

### RECS Comparison Plots

Validates residential end-use and household-level distributions against RECS microdata:

- **Annual end-use comparisons** - Average and total consumption by end use
- **Penetration comparisons** - Share of occupied units using each end use
- **Distribution plots** - Survey-based consumption distributions for household end uses
- **Cross-filtered views** - Breakdowns by state, census division, building type, climate zone, vintage, and heating fuel

### Load Duration Curves

Validates hourly load shapes against utility load research data:

- **Multi-utility LDC** - Comparison across multiple utilities
- **Individual utility curves** - Detailed per-utility validation
- **Seasonal LDC** - Summer, winter, shoulder season patterns
- **Per-customer normalization** - Removes scale effects to focus on shapes

### Timeseries Plots

Validates temporal patterns and profiles:

- **Hourly profiles by month** - Average hourly consumption patterns
- **Daily aggregates** - Daily consumption over the year
- **Stacked end-use profiles** - End-use breakdowns over time
- **State-level analysis** - Focus on high-population states

## Configuration Details

### Data Source Configuration

```yaml
workgroup: rescore

data_sources:
  - name: resstock_2025
    db_name: buildstock_sdr
    table_name: resstock_amy2018_r1_2025
    db_schema: resstock_oedi_new
    baseline_metadata_and_annual_results_parquet_url: s3://...
```

### Reference Data Configuration

```yaml
reference_years:
  eia: [2018]
  recs: [2020]
```

### Output Configuration

```yaml
output:
  output_dir: ~/validation_outputs  # Base output directory
  run_name: baseline_2024           # Run identifier
```

### Data Source Labels

```yaml
data_source_labels:
  eia_2018:
    label: "EIA 2018"
    entries:
      - description: "EIA-861 Annual Electric Utility Data (2018)"
        url: "https://www.eia.gov/electricity/data/eia861/"
```

## Developing and Testing

Run tests (when test suite is created):
```bash
uv run pytest resstockpostproc/baseline_validation/tests
```

Run pre-commit checks:
```bash
pre-commit run --all-files --show-diff-on-failure
```

## Troubleshooting

**BuildStockQuery connection issues:**
- Ensure AWS credentials are configured
- Check Athena workgroup permissions
- Verify table and database names

**Missing reference data:**
- Reference data is downloaded from S3 on first use
- Check internet connectivity
- Data cached in `~/.buildstock_cache`

**Stale local cache after query-layer fixes:**
- BuildStockQuery result caches live in `postprocessing/.bsq_cache`
- Baseline-validation disk caches live in `postprocessing/.cache`
- If an upstream `buildstock_query` fix changes the expected raw query result, clear both locations before rerunning so stale cached DataFrames are not reused

**Memory issues with large runs:**
- Polars is memory-efficient, but large timeseries can be demanding
- Make sure not other CPU/Memory intensive application is running

## Future Enhancements

- Plot generation is already parallel, but data loading/querying is sequential.
  While the polars engine already makes use of multiple cores there is room for speeding
  things up by making both step parallel.
