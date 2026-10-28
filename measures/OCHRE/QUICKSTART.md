# Quick Start Guide: Using OCHRE as Simulation Backend

This guide will help you quickly set up and run ResStock with OCHRE as the simulation backend.

## Prerequisites Checklist

- [ ] Python 3.9 or higher installed
- [ ] OCHRE installed: `pip install ochre-nrel`
- [ ] ResStock repository cloned
- [ ] OpenStudio installed

## Step 1: Verify OCHRE Installation

```bash
# Test OCHRE installation
python -c "import ochre; print('OCHRE version:', ochre.__version__)"

# If the above fails, install OCHRE
pip install ochre-nrel
```

## Step 2: Choose Your Project

Navigate to an existing ResStock project or create a new one:

```bash
cd project_testing  # or project_national
```

## Step 3: Modify Your Project YML File

Open your baseline YML file (e.g., `testing_baseline.yml`) and locate the workflow measures section.

**Find this:**
```yaml
workflow_args:
  measures:
    - measure_dir_name: BuildExistingModel
      # ... arguments
    
    # This is the line you'll replace
    - measure_dir_name: HPXMLtoOpenStudio
      arguments:
        # ... arguments
```

**Replace with this:**
```yaml
workflow_args:
  measures:
    - measure_dir_name: BuildExistingModel
      # ... arguments (keep as-is)
    
    # NEW: Use OCHRE instead of HPXMLtoOpenStudio
    - measure_dir_name: OCHRE
      arguments:
        hpxml_path: ""  # Auto-populated by workflow
        output_dir: ""  # Auto-populated by workflow
        time_res_minutes: 10  # 10-minute resolution
        duration_days: 365    # Full year
        debug: false
```

## Step 4: Test with a Small Sample

Start with just 1-2 buildings to verify everything works:

```yaml
baseline:
  n_datapoints: 2  # Start small!
```

## Step 5: Run Your Analysis

### Using BuildStockBatch (recommended)

```bash
# From your project directory
buildstock_batch local -p . -j 1
```

### Using Manual Workflow

```bash
# Generate samples
openstudio resources/run_sampling.rb -p project_testing -n 2 -o buildstock.csv

# Run the workflow (implementation depends on your setup)
```

## Step 6: Check the Results

Look for OCHRE-specific output files in your run directory:

```
run/
├── ochre_timeseries.csv      # High-resolution OCHRE output
├── ochre_metrics.json        # Annual metrics from OCHRE
├── ochre_converted.json      # Converted to EnergyPlus format
├── eplusout.msgpack          # Compatible with reporting measures
└── results_annual.csv        # Standard ResStock output
```

## Step 7: Validate Results

Compare results with a reference EnergyPlus run:

1. Run the same building with HPXMLtoOpenStudio
2. Run with OCHRE
3. Compare key metrics (total energy, heating, cooling, etc.)
4. Investigate any significant differences

## Troubleshooting

### "OCHRE is not installed"
```bash
pip install ochre-nrel
```

### "HPXML file not found"
This usually means the workflow isn't setting paths correctly. Enable debug:
```yaml
debug: true
```

### Simulation fails with OCHRE error
Enable debug mode to see the full OCHRE output:
```yaml
debug: true
```

Check OCHRE metrics and timeseries files directly:
```bash
cat run/ochre_metrics.json
head run/ochre_timeseries.csv
```

### Output files missing
Check the measure log for errors:
```bash
cat run.log | grep -i error
```

## Advanced Usage

### Higher Time Resolution

For more detailed results (slower simulation):
```yaml
time_res_minutes: 5  # 5-minute timesteps
```

### Shorter Test Runs

For quick testing:
```yaml
duration_days: 7  # One week only
```

### Enable Verbose Output

For debugging:
```yaml
debug: true
```

## Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| Missing Python dependencies | `pip install -r requirements.txt` |
| Wrong Python version | Use Python 3.9-3.12 |
| Measure not found | Verify `measures/OCHRE` directory exists |
| Output format issues | Check `ochre_converted.json` for mapping |
| Slow simulations | Increase `time_res_minutes` or reduce `duration_days` |

## Performance Tips

1. **Start Small**: Test with 1-10 buildings before scaling up
2. **Adjust Resolution**: Higher time resolution = slower but more accurate
3. **Parallel Runs**: Use BuildStockBatch's parallel execution
4. **Monitor Resources**: OCHRE may have different memory/CPU requirements than EnergyPlus

## Next Steps

Once your test run succeeds:

1. Scale up to your full sample size
2. Review output quality and completeness
3. Validate against expected results
4. Configure timeseries outputs if needed
5. Run upgrade scenarios

## Getting Help

- **Measure Documentation**: `measures/OCHRE/README.md`
- **Example Config**: `measures/OCHRE/example_ochre_project.yml`
- **OCHRE Docs**: https://ochre-nrel.readthedocs.io/
- **ResStock Docs**: https://resstock.readthedocs.io/

## Success Checklist

- [ ] OCHRE installed and verified
- [ ] Project YML modified to use OCHRE measure
- [ ] Test run completed successfully
- [ ] Output files generated correctly
- [ ] Results validated against expectations
- [ ] Ready to scale to full sample

Good luck with your OCHRE simulations!
