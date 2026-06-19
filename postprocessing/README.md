# ResStock Postprocessing

This package automates the common postprocessing tasks that are part of running ResStock. It is used by BuildStockBatch to transform the results to its final format.

## Installation

To install the package, we recommend using `uv` for Python package management.

### Set up uv

1. Install `uv` if you don't have it already:

   ```bash
   # Mac
   wget -qO- https://astral.sh/uv/install.sh | sh

   # Windows Powershell
   powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
   ```

   (More info: https://docs.astral.sh/uv/getting-started/installation/)

2. Create a new virtual environment and install dependencies using the following command:
   (If it fails the first time, try running `uv sync` again)

   ```bash
   cd path/to/postprocessing
   uv sync
   ```

3. (Recommended) Install the shared `pre-commit` hooks so formatting, spelling, and lint checks run automatically before each commit. This is a must if you are going to contribute code:

   ```bash
   cd path/to/postprocessing
   uv run --group dev pre-commit install
   ```

### Updating Dependencies with Branch References

Some dependencies may point to development branches (e.g., `buildstock-query @ git+https://github.com/NREL/buildstock-query.git@branch_name`) rather than stable releases. When changes are pushed to these branches, you need to refresh your environment to pick up the updates:

```bash
cd path/to/postprocessing
rm -f uv.lock && uv sync
```

This will:
- Delete the lock file (which caches the commit hash)
- Re-fetch the latest commit from the branch and reinstall all dependencies

If that doesn't work, consider deleting the virtual environment too to removes old installed packages before resyncing with `rm -rf .venv`

If you want to pin to a specific commit instead of tracking a branch, you can use:

```toml
"buildstock-query @ git+https://github.com/NREL/buildstock-query.git@<commit-sha>"
```

4. Run the scripts as desired
   ```bash
   # Output the failure log
   cd path/to/postprocessing
   uv run resstockpostproc/get_failures.py <csv_path> --verbose

   # Export metadata and annual results from files on S3
   uv run resstockpostproc/process_bsb_results.py "s3://res-sdr/testing-sdr-fy25/a_run" "C:/path/to/bsb/output/a_run_output"

   # Export metdata and annual results from local files
   # (It is faster to download the /baseline and /upgrades directories from S3 once instead of reading from S3 each time)
   uv run resstockpostproc/process_bsb_results.py "C:/path/to/bsb/output/a_run" "C:/path/to/bsb/output/a_run_output"

   # Export metdata and annual results to OEDI
   uv run resstockpostproc/process_bsb_results.py "C:/path/to/bsb/output/a_run" "s3://oedi-data-lake/nrel-pds-building-stock/end-use-load-profiles-for-us-building-stock/2025/resstock_amy2018_release_1"
   ```
