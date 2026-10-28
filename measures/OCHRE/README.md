# OCHRE Measure

This measure enables the use of OCHRE (Object-oriented Controllable High-resolution Residential Energy Model) as an alternative simulation backend to HPXMLtoOpenStudio + EnergyPlus in the ResStock workflow.

## Description

OCHRE is a Python-based building energy modeling tool designed to model flexible loads in residential buildings with high temporal resolution. This measure acts as a bridge between the ResStock workflow and OCHRE, allowing users to leverage OCHRE's advanced modeling capabilities for residential buildings.

## How It Works

1. **Input**: Takes an HPXML file (and optionally a schedule file and weather file) as input
2. **OCHRE Execution**: Runs OCHRE directly via command line using `ochre single` command
3. **Output Conversion**: Converts OCHRE outputs to a format compatible with downstream ResStock reporting measures (ReportSimulationOutput, etc.)

## Workflow Integration

In the ResStock workflow, this measure replaces HPXMLtoOpenStudio in step 3:

```
Standard ResStock Workflow:
1. BuildExistingModel
2. ApplyUpgrade (optional)
3. HPXMLtoOpenStudio  ← This measure replaces this step
4. UpgradeCosts
5. ReportSimulationOutput
6. ReportUtilityBills
7. ServerDirectoryCleanup
```

## Prerequisites

- **Python**: Python 3.9 or higher must be installed
- **OCHRE**: Install OCHRE using: `pip install ochre-nrel`
- **Ruby gems**: The measure uses standard Ruby libraries (json, csv)

## Arguments

| Argument | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `hpxml_path` | String | Yes | - | Path to the HPXML input file |
| `output_dir` | String | Yes | - | Directory for output files |
| `time_res_minutes` | Integer | No | 60 | Time resolution in minutes |
| `duration_days` | Integer | No | 365 | Simulation duration in days |
| `start_year` | Integer | No | 2018 | Year to start the OCHRE simulation |
| `start_month` | Integer | No | 1 | Month to start the OCHRE simulation (1-12) |
| `start_day` | Integer | No | 1 | Day to start the OCHRE simulation (1-31) |
| `debug` | Boolean | No | false | Enable debug output |

## Usage Example

### In a ResStock Project YML File

To use OCHRE as the simulation backend, modify your project's YML file to replace the HPXMLtoOpenStudio measure with OCHRE:

```yaml
workflow_args:
  measures:
    - measure_dir_name: BuildExistingModel
      arguments:
        # ... your arguments
    
    # Replace HPXMLtoOpenStudio with OCHRE
    - measure_dir_name: OCHRE
      arguments:
        hpxml_path: ""  # Will be set automatically
        output_dir: ""  # Will be set automatically
        time_res_minutes: 10
        duration_days: 365
        start_year: 2018
        start_month: 1
        start_day: 1
        debug: false
    
    - measure_dir_name: UpgradeCosts
      arguments:
        # ... your arguments
    
    # Reporting measures continue as normal
    - measure_dir_name: ReportSimulationOutput
      arguments:
        # ... your arguments
```

### Standalone Usage

```ruby
require 'openstudio'

# Create measure instance
measure = OCHRE.new

# Create model and runner
model = OpenStudio::Model::Model.new
runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

# Set arguments
arguments = measure.arguments(model)
argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

# Configure arguments
argument_map['hpxml_path'].setValue('/path/to/input.xml')
argument_map['output_dir'].setValue('/path/to/output')
argument_map['time_res_minutes'].setValue(10)
argument_map['duration_days'].setValue(365)
argument_map['start_year'].setValue(2018)
argument_map['start_month'].setValue(1)
argument_map['start_day'].setValue(1)

# Run measure
result = measure.run(model, runner, argument_map)
```

## Output Files

The measure generates several output files in the specified output directory:

### OCHRE Native Outputs
- `ochre_timeseries.csv`: High-resolution timeseries data from OCHRE
- `ochre_metrics.json`: Annual energy metrics from OCHRE
- `ochre_hourly.csv`: Hourly aggregated data (if available)

### Converted Outputs (for ResStock compatibility)
- `eplusout.msgpack`: EnergyPlus-like output in MessagePack format
- `ochre_converted.json`: Converted outputs in JSON format
- `eplusout_timeseries.csv`: Converted timeseries data
- `results_annual.csv`: Annual results in CSV format

## Output Mapping

The measure maps OCHRE outputs to EnergyPlus-like output variables for compatibility with reporting measures:

| OCHRE Metric | EnergyPlus Variable |
|--------------|---------------------|
| Total Energy (kWh) | Total Energy |
| Electricity (kWh) | Electricity:Facility |
| Natural Gas (kWh) | NaturalGas:Facility |
| Heating (kWh) | Heating:EnergyTransfer |
| Cooling (kWh) | Cooling:EnergyTransfer |
| Water Heating (kWh) | WaterSystems:EnergyTransfer |
| PV (kWh) | Photovoltaic:ElectricityProduced |

See `resources/ochre_output_converter.rb` for the complete mapping.

## Limitations and Considerations

1. **Output Compatibility**: While the measure attempts to match EnergyPlus output format, some outputs may differ in structure or granularity
2. **OCHRE Installation**: OCHRE must be installed in the Python environment
3. **Performance**: OCHRE simulation performance characteristics differ from EnergyPlus
4. **Validation**: Carefully validate results when switching from EnergyPlus to OCHRE
5. **Feature Parity**: Not all EnergyPlus features may be available in OCHRE and vice versa

## Troubleshooting

### "OCHRE is not installed" Error
```bash
pip install ochre-nrel
```

### Output Conversion Issues
Enable debug mode to see detailed output:
```yaml
debug: true
```

Check the OCHRE output files directly:
```bash
cat ochre_metrics.json
```

## Development

### Running Tests
```bash
cd measures/OCHRE/tests
ruby test_ochre.rb
```

### Extending Output Mapping

To add new output variable mappings, edit `resources/ochre_output_converter.rb` and add entries to the `METRIC_MAPPINGS` hash.

## References

- [OCHRE GitHub Repository](https://github.com/NREL/OCHRE)
- [OCHRE Documentation](https://ochre-nrel.readthedocs.io/)
- [ResStock Documentation](https://resstock.readthedocs.io/)
- [OpenStudio-HPXML](https://github.com/NREL/OpenStudio-HPXML)

## License

This measure is distributed under the same license as ResStock.

## Support

For issues specific to:
- **This measure**: Open an issue in the ResStock repository
- **OCHRE**: Open an issue in the [OCHRE repository](https://github.com/NREL/OCHRE/issues)
- **ResStock workflow**: See [ResStock documentation](https://resstock.readthedocs.io/)
