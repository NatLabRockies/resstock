======================
Continuous Integration
======================

.. contents::
   :local:
   :depth: 2

Overview
========

This document outlines the continuous integration (CI) process for the ResStock repository. CI is implemented using GitHub Actions and ensures code quality, test coverage, documentation generation, and results validation before changes are merged into main development branches.

To merge pull requests, it is highly recommended that CI passes (the green check mark on the latest branch commit) before merging a new feature or bug fix. There are some situations where a CI failure is okay (example: synching between BuildStock-Batch repository changes) temporarily while repository management accross the software stack is being changed.

Triggering Conditions
=====================

CI workflows are triggered by:
- Pushes to `main` or `develop`
- Pull requests (`opened`, `synchronize`, `reopened`)
- Manual triggers via GitHub Actions (`workflow_dispatch`)
- Workflow run completions

Concurrency Control
===================

To avoid job stacking and ensure clean CI runs:
- CI workflows cancel in-progress runs on the same PR or branch when a new one is queued

Environment Variables
=====================

Global environment variables define OpenStudio versions, dependencies, and branch targets for BuildStock and related tools.

CI Jobs
=======

Each CI job is defined in the main workflow and other supporting workflows. They are executed in a structured order (see image below), with dependencies enforced through the `needs:` keyword.

.. image:: ../images/ci_workflow.png
   :width: 1200
   :alt: The GitHub Actions workflow for ResStock's CI tests

The Main CI Workflow
--------------------

1. Format Files
~~~~~~~~~~~~~~~

Cleans and sorts the `resources/options_lookup.tsv` file:
- Removes trailing whitespace
- Sorts by the first two columns
- Uploads the cleaned file as an artifact

2. Unit Tests
~~~~~~~~~~~~~

Runs test suites in the OpenStudio container:

- Installs Ruby gems
- Executes:

  - Project integrity checks
  - Measure unit tests
  - Integrity check tests

- Uploads:

  - Code coverage
  - Feature samples
  - Buildstock CSV

3. Build Documentation
~~~~~~~~~~~~~~~~~~~~~~

Builds and commits:
- **Technical Development Guide** (Sphinx, HTML)
- **Technical Reference Guide** (LaTeX, PDF)

4. Analysis Tests
~~~~~~~~~~~~~~~~~

Performs YAML-driven analysis using `run_analysis.rb`:

- Generates and uploads:

  - Precomputed buildstocks
  - Results CSVs

5. Integration Tests
~~~~~~~~~~~~~~~~~~~~

Runs full simulations using BuildStockBatch:

- Simulates national and testing scenarios
- Extracts and processes results
- Uploads results and runs validation scripts

6. Compare Tools
~~~~~~~~~~~~~~~~

Compares outputs from `run_analysis.rb` vs. BuildStockBatch:

- Validates consistency
- Uses Ruby-based tests for analysis

7. Compare Results (Pull Request Only)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Runs on pull requests to compare:

- Baseline results (annual + timeseries)
- Differences in samples and outputs
- Generates and uploads comparisons

8. Update Results
~~~~~~~~~~~~~~~~~

Commits validated result sets to version control:

- Baseline samples and results
- Precomputed files
- Updated `options_lookup.tsv`

9. SDR Options Analysis
~~~~~~~~~~~~~~~~~~~~~~~

Large-scale analysis to determine upgrade applicability:

- Generates 550K sample
- Analyzes with `buildstock_query`
- Validates options
- Uploads results and commits artifacts on `develop` only

10. SDR Integration Tests
~~~~~~~~~~~~~~~~~~~~~~~~~

Full simulation test of SDR scenarios:

- Executes BuildStockBatch with optional AWS config
- Validates successful simulations
- Uploads raw and published results
- Commits validated outputs

Other CI Jobs
-------------

These CI Jobs are outside the main GitHub actions workflow for new feature development and bug fixes. They are used to help with the organization of the software development or assist with the new features and bug fixes.

Add Pull Request or Issue to Project
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Adds newly opened or reopened Pull requests or Issues to a GitHub project board using `actions/add-to-project@v1.0.0`

**Location of the Project Board:** https://github.com/orgs/NREL/projects/38/views/1

This project board contains issues and pull requests from `ResStock <https://github.com/NREL/resstock>`_, `ResStock-Estimation <https://github.com/NREL/resstock-estimation>`_, `BuildStock-Batch <https://github.com/NREL/buildstockbatch>`_, and `BuildStock-Query <https://github.com/NREL/buildstock-query>`_ repositories. 

Post Run: SDR Diff and Final Status
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Runs after the main CI completes successfully:

- **SDR Diff**:

  - Generates and attaches CSV diffs as PR annotations
  - Uses a custom Python script for rich diff reporting

- **Pass Checks**:

  - Manually marks required CI checks as passing
  - Updates GitHub commit status using the CLI

Artifacts Produced
==================

Artifacts produced if tests are successful:

- `options_lookup.tsv` : A sorted and formated version of `options_lookup.tsv`` that allows diffs to easily be seen.
- `feature_samples.csv`: The samples simulated in the feature branch for the analysis and integration tests
- `coverage/` : Coverage logs
- `precomputed_buildstocks/` : Precomputed `buildstock.csv` file for SDR integration tests.
- `documentation/` : A current version of the ResStock documentation in Read-the-Docs and the Technical Reference Guide PDF.
- `run_analysis_results_csvs/` : Annual results from the analysis tests
- `buildstockbatch_results_csvs/` : Annual results from the integration tests
- `comparisons/` : Plots that show the difference in the results between the base branch and feature branch. Helpful during model changes, not characteristics changes.
- `national_550ksamples.csv.gz` : The current 550,000 sample in ResStock that will be simulated. Used in the SDR integration tests.
- `sdr_options_analysis/` : Analysis of the upgrade options and their percent applicability based on the current national 550,000 sample
- `buildstockbatch_results_sdr_raw_csvs/` : The results.csv files from the ResStock SDR upgrades project file being run with BuildStock-Batch
- `buildstockbatch_results_sdr_published_csvs/` : The results.csv files from the ResStock SDR upgrades project file being run with Buildstock-Batch transformed into what is being published on OEDI.