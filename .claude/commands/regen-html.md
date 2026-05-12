Regenerate the baseline validation dashboard HTML and shards from an existing run's TSV:

1. Read `postprocessing/resstockpostproc/baseline_validation/workflow.yaml` and extract `output.output_dir` and `output.run_name`.
2. Construct the paths:
   - TSV: `{output_dir}/{run_name}/dashboard_data/comparisons_index.tsv`
   - HTML: `{output_dir}/{run_name}/comparison_dashboard.html`
3. Run using the postprocessing venv:
   ```
   cd postprocessing && .venv/bin/python -m resstockpostproc.baseline_validation.dashboard.create_html {tsv_path} {html_path}
   ```
4. Confirm the regenerator wrote shards to `{output_dir}/{run_name}/dashboard_data/comparisons_index/` (matching the full pipeline's layout). The about page is written to `{output_dir}/{run_name}/about.html`.
5. Report the row count and shard count from the script's stdout line.
