# ResStock Sampler

Python module for sampling building stock characteristics for ResStock projects. This tool generates representative samples of building characteristics based on probability distributions defined in TSV files.

## Installation

### Prerequisites

First, install `uv` - a fast Python package manager:

```bash
# On macOS/Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# On Windows
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"

# Alternatively, install via pip
pip install uv
```

### Install the Sampler

```bash
uv init
uv pip install -e .
source .venv/bin/activate
```

## Usage

The sampler provides two main commands:

### 1. Generate Samples

```bash
# Activate the virtual environment
resstock-sampler sample -p tests/project_sampling_test -n 10 -o samples.csv
```

**Parameters:**
- `-p, --project`: Path to the project directory (must contain `housing_characteristics` folder)
- `-n, --num_datapoints`: Number of datapoints to sample
- `-o, --output`: Output filename for samples (parquet format)

### 2. Verify Existing Samples

```bash
uv run resstock-sampler verify buildstock.csv -p /path/to/project -o errors.csv
```

**Parameters:**
- `buildstock_file`: Path to the buildstock CSV file to verify
- `-p, --project`: Path to the project directory
- `-o, --output`: Output filename for error report (default: 'errors.csv')

## Project Structure

Your project directory should have the following structure:

```
project/
├── housing_characteristics/
│   ├── Bedrooms.tsv
│   ├── Ceiling Fan.tsv
│   ├── Uses AC.tsv
│   └── ... (other characteristic TSV files)
```

## TSV File Format

Characteristic TSV files should follow this format:

```tsv
Dependency=Bedrooms	Option=None	Option=Standard	Option=Premium	sampling_probability
1	0.35	0.35	0.3	0.2
2	0.35	0.35	0.3	0.2
3	0.35	0.35	0.3	0.2
```

- `Dependency=`: Columns that this characteristic depends on
- `Option=`: Available options for this characteristic
- `sampling_probability`: Probability weight for sampling this group

## Programming API

You can also use the sampler programmatically:

```python
import pathlib
from sampler import sample_all

# Generate samples
project_path = pathlib.Path("path/to/project")
samples_df = sample_all(project_path, num_samples=1000)

# Save to parquet
samples_df.to_parquet("output.parquet")
```

## Development

### Running Tests

```bash
# Run the test suite
uv run python -m pytest test_sampling.py -v
```

### Dependencies

- pandas: Data manipulation and analysis
- networkx: Graph operations for dependency handling
- click: Command-line interface
- joblib: Parallel processing
- numpy: Numerical operations

## How It Works

1. **Dependency Resolution**: Builds a dependency graph from TSV files and processes them in topological order
2. **Quota Sampling**: Uses probability-based quota sampling to ensure representative distributions
3. **Parallel Processing**: Utilizes multiprocessing for efficient sampling of large datasets
4. **Verification**: Validates that generated samples match expected probability distributions

## Error Handling

The verify command checks for:
- Correct probability distributions
- Valid dependency relationships  
- Sampling errors and provides detailed error reports

## License

This module is part of the ResStock project and follows the same licensing terms.