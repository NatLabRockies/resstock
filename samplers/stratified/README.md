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
uv sync
source .venv/bin/activate
```

## Usage

The sampler provides two main commands:

### 1. Generate Samples

```bash
# Activate the virtual environment
resstock-sampler sample -p ../project_national -n 550000 -o geo_samples.csv
```

**Parameters:**
- `-p, --project`: Path to the project directory (must contain `housing_characteristics` folder)
- `-n, --num_datapoints`: Number of datapoints to sample. It will generate approximately that many (exactly: `num_datapoints // 12` * 12) samples.
- `-o, --output`: Output filename for samples (parquet format)

### 2. Modify the sampler config file

The sampler config file is located at `sampler/sampler_config.yaml`. You can modify the config file to change the parameters used for sampling.
