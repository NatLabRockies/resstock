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
- `coverage_floor_vars`: The characteristics whose combination defines a floor cell. Leave the key out and the selection is the rank cut alone, which is what every run so far has used. Set it and the selection keeps everything the rank cut kept and then adds, for each floor cell the pilot reached but the cut left with no selected segment, the most populous segment holding a pilot row in that cell. Each name must be a characteristic the pilot samples, so a `segment_vars` entry or an ancestor of one; `Tenure` and `Vacancy Status` qualify even though they do not split a segment.

  The floor is additive: it displaces nothing, so every building the rank cut alone would have produced is still produced and the run builds more than `num_datapoints`. That extra build is what it costs, and it buys back stock the allocator would otherwise find no building for — the fallback ladder releases only vintage and federal poverty level, so a floor cell the cut drops has nothing to stand in for it.

  Both are measured over 40 replicates of the run-3 pilot, against a rank cut that leaves 278,645 catalogue rows unmatched at `segment_selection_sample_size: 10000000` and 321,364 at `50000000`:

  | `coverage_floor_vars` | extra build, 10M | rows recovered, 10M | extra build, 50M | rows recovered, 50M |
  |---|---|---|---|---|
  | Sampling Region, Geometry Building Type RECS, Heating Fuel | +0.48% | −64% | +1.34% | −63% |
  | the above plus Tenure, Vacancy Status | +1.00% | −88% | +2.87% | −94% |

  The tenure and vacancy status columns carry most of the recovery because the allocator joins on them: a segment can be selected and still put none of its take into one tenure of its own cell.
