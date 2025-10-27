# ResStock Postprocessing

This package automates the common postprocessing tasks that are part of running ResStock. It is used by BuildStockBatch to transform the results to its final format.

## Installation

To install the package, we recommend using `uv` for Python package management.

### Set up uv

1. Install `uv` if you don't have it already:

   ```bash
   wget -qO- https://astral.sh/uv/install.sh | sh
   ```

   (More info: https://docs.astral.sh/uv/getting-started/installation/)

2. Create a new virtual environment and install dependencies using the following command:
   (If it fails the first time, try running `uv sync` again)

   ```bash
   uv sync
   ```

3. (Recommended) Install the shared `pre-commit` hooks so formatting, spelling, and lint checks run automatically before each commit. This is a must if you are going to contribute code:

   ```bash
   uv run --group dev pre-commit install
   ```

# Usage


4. Run the scripts as desired
   ```bash
   uv run resstockpostproc/get_failures.py <csv_path> --verbose
   ```
