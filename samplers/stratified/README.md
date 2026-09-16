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

# Alternatively, install via pip
cd samplers/stratified/
uv pip install -e . --group dev
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
- `-n, --num_datapoints`: Number of datapoints to sample. It will generate approximately that many: the run keeps `num_datapoints // num_samples_per_segment` segments and takes up to `num_samples_per_segment` buildings from each, so the total is at most `num_datapoints // num_samples_per_segment * num_samples_per_segment` and falls below that when a segment holds fewer buildings than the take.
- `-o, --output`: Output filename for samples (parquet format)

### 2. Modify the sampler config file

The sampler config file is located at `sampler/sampler_config.yaml`. You can modify the config file to change the parameters used for sampling.

- `segment_vars`: The characteristics whose combination defines a segment. Each is a characteristic the allocator later joins on, so a characteristic that only flows downhill through the TSVs does not belong here.
- `segment_selection_sample_size`: Size of the initial sample used to rank segments by how much stock they cover.
- `num_samples_per_segment`: Buildings kept per segment. This single value sets both how many segments are kept and how many buildings are taken from each. The take is a random draw within the segment, seeded from `RANDOM_SEED` in `sampler.py` so a rerun reproduces it.
