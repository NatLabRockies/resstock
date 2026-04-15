# Baseline Validation

The baseline validation tool generates quality-control visualizations comparing BuildStock baseline results with reference data from EIA (Energy Information Administration) and other authoritative sources. This tool validates that the baseline simulation accurately represents real-world energy consumption patterns.

## Overview

This tool compares BuildStock baseline simulation results against:
- **EIA 861** - Annual and monthly electricity sales data
- **EIA 176** - Natural gas sales data
- **LRD (Load Research Data)** - Hourly load profiles from utilities

It produces three types of validation analyses:
1. **EIA Comparison** - Annual and monthly sales comparisons at state and utility levels
2. **Load Duration Curves** - Hourly load shape validation against utility data
3. **Timeseries Analysis** - Temporal patterns and profiles

## Architecture

This tool follows a **functional programming** approach with clear separation of concerns:

```
baseline_validation/
├── workflow.yaml              # Configuration file
├── main.py                    # CLI entry point
├── plot_generator.py          # Orchestration layer
├── schema/                    # Pydantic configuration schemas
│   └── workflow_schema.py
├── io_managers/               # I/O operations
│   ├── input_manager.py       # BuildStockQuery setup
│   └── output_manager.py      # Save plots and data
├── data_processing/           # Pure transformation functions
│   └── data_processor.py      # Aggregation and scaling logic
├── reference_data/            # Reference data loaders
│   └── eia_data_loader.py     # EIA and LRD data loading
├── plotters/                  # Plotting functions
│   ├── eia_plotter.py         # EIA comparison plots
│   ├── lrd_plotter.py         # Load duration curves
│   └── timeseries_plotter.py  # Timeseries visualizations
├── utils.py                   # Shared constants and utilities
└── theme.py                   # Plot styling
```

### Key Design Principles

1. **Functional Approach**: Pure functions with no side effects
   - Data in → Data out
   - No class state or memoization
   - Testable with mock data

2. **Separation of Concerns**:
   - I/O (`io_managers`) - Loading and saving
   - Transformation (`data_processing`) - Pure data operations
   - Visualization (`plotters`) - Plot generation
   - Orchestration (`plot_generator`) - Workflow coordination

3. **Configuration over Code**:
   - YAML configuration instead of Python config
   - Pydantic schema validation
   - Declarative plot specifications

4. **Modern Python**:
   - Uses **Polars** for data processing (fast, expressive)
   - Type hints throughout
   - Consistent with `upgrade_comparison` patterns

## Input / Output

### Input

**`workflow.yaml` (main configuration)**

This is the primary configuration file. Key settings:

```yaml
# BuildStock data source
data_source:
  db_name: resstock-core
  table_name: 2023-03-16-national-baseline-full
  workgroup: rescore
  buildstock_type: resstock

# Reference data settings
reference_data:
  comparison_data_year: 2018
  eia_mapping_version: 3

# Plot specifications
plots:
  plot_types:
    - eia
    - load_duration
    - timeseries
  group_by_levels:
    - state
    - utility
  output_formats:
    - html
    - svg
    - parquet

# Output configuration
output:
  output_dir: ~/Documents/baseline_validation_outputs
  run_name: baseline_2023_03_16
  overwrite: false
```

### Output

All outputs are written to `<output_dir>/plots/<run_name>/`:

```
plots/
└── baseline_2023_03_16/
    ├── eia/
    │   ├── annual_state/
    │   │   ├── html/
    │   │   ├── svg/
    │   │   └── data/
    │   ├── annual_eiaid/
    │   └── monthly_state/
    ├── lrd/
    │   ├── html/
    │   ├── svg/
    │   └── data/
    └── timeseries/
        └── {state}/
            ├── html/
            └── svg/
```

**Output formats:**
- `html/` - Interactive Plotly visualizations
- `svg/` - Vector graphics for reports
- `data/` - Parquet files with plot data for further analysis
- `figure_json/` - Serialized Plotly JSON (optional)

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

# Generate specific plot types only
uv run resstockpostproc/baseline_validation/main.py --plot-type eia

# Generate multiple specific types
uv run resstockpostproc/baseline_validation/main.py --plot-type eia --plot-type timeseries

# Specify output formats
uv run resstockpostproc/baseline_validation/main.py --output html --output svg

# Overwrite existing outputs
uv run resstockpostproc/baseline_validation/main.py --overwrite
```

### CLI Options

```bash
uv run resstockpostproc/baseline_validation/main.py --help
```

```
usage: main.py [-h] [--config CONFIG] [--output OUTPUT]
               [--plot-type {eia,load_duration,timeseries,all}]
               [--overwrite]

Generate baseline validation plots comparing BuildStock results with reference data

options:
  -h, --help            show this help message and exit
  --config CONFIG       Path to workflow configuration YAML file
  --output OUTPUT       Output file types to generate (html, svg, json,
                        parquet). May be specified multiple times.
  --plot-type {eia,load_duration,timeseries,all}
                        Types of plots to generate. May be specified multiple
                        times.
  --overwrite           Overwrite existing output files
```

## Plot Types

### EIA Comparison Plots

Validates annual and monthly energy consumption against EIA reported data:

- **Annual sales scatter plots** - State and utility level comparisons
- **Customer counts comparison** - BuildStock unit counts vs EIA customer counts
- **Monthly profiles** - Seasonal patterns for electricity and natural gas
- **Fuel-specific validation** - Separate electricity and natural gas analysis

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
data_source:
  db_name: resstock-core          # Athena database
  table_name: baseline-2024-v3    # Athena table
  workgroup: rescore              # Athena workgroup
  buildstock_type: resstock       # resstock or comstock
```

### Reference Data Configuration

```yaml
reference_data:
  comparison_data_year: 2018           # Year of EIA/LRD data
  eia_mapping_version: 3          # EIA utility mapping version
```

### Plot Specifications

```yaml
plots:
  plot_types:                     # Which plot categories to generate
    - eia
    - load_duration
    - timeseries

  group_by_levels:             # Geographic grouping
    - state
    - utility

  output_formats:                 # File formats to save
    - html                        # Interactive plots
    - svg                         # Static vector graphics
    - parquet                     # Data tables
```

### Output Configuration

```yaml
output:
  output_dir: ~/validation_outputs  # Base output directory
  run_name: baseline_2024           # Run identifier
  overwrite: false                  # Whether to overwrite existing
```

## Comparison with upgrade_comparison

Both tools share similar architectural patterns:

**Similarities:**
- Functional programming approach
- YAML configuration with Pydantic validation
- Separated I/O, processing, and plotting layers
- Polars for data processing
- CLI with argparse

**Differences:**
- **Purpose**: Baseline validation vs upgrade comparison
- **Reference data**: EIA/LRD vs baseline-to-upgrade deltas
- **Aggregation**: State/utility vs upgrade groups
- **Plot types**: Validation scatter plots vs savings distributions

## Migrating from buildstock_viz

If you previously used `buildstock_viz`, here's how to migrate:

**Old approach (buildstock_viz):**
```python
from buildstock_viz.visualizers import EIAViz

viz = EIAViz(
    db_name="resstock-core",
    table_name="baseline-2024",
    workgroup="rescore"
)
viz.generate_all_plots(root_path="/path/to/output")
```

**New approach (baseline_validation):**
```yaml
# workflow.yaml
data_source:
  db_name: resstock-core
  table_name: baseline-2024
  workgroup: rescore

output:
  output_dir: /path/to/output
  run_name: my_validation
```

```bash
uv run resstockpostproc/baseline_validation/main.py --config workflow.yaml
```

**Key migration steps:**
1. Convert `config.py` settings to `workflow.yaml`
2. Use CLI instead of Python scripts
3. Reference data automatically downloaded and cached
4. Outputs organized by plot type instead of flat structure

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
- Consider processing states/utilities in batches
- Increase available memory or use compute instance

## Future Enhancements

Potential additions (not yet implemented):
- Dashboard interface (similar to upgrade_comparison)
- Parallel plot generation
- Statistical validation metrics (R², RMSE, etc.)
- Automated QC pass/fail criteria
- Integration with CI/CD pipelines
- ComStock validation support

## Reference

- **BuildStockQuery**: https://github.com/NREL/buildstock-query
- **Polars**: https://pola.rs/
- **Plotly**: https://plotly.com/python/
- **EIA 861**: https://www.eia.gov/electricity/data/eia861/
