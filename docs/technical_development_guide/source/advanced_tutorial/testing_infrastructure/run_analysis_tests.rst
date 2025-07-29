Run Analysis Tests
==================

Overview
--------

The `test_run_analysis.rb` file provides a full integration test suite for the ResStock `workflow/run_analysis.rb` script. It is responsible for verifying the correct behavior of the ResStock analysis pipeline under a variety of configurations and inputs, ensuring that:

- Valid YAML configurations execute as expected and generate proper output artifacts.
- Common misconfigurations are caught and return helpful error messages.
- The measure execution order, file outputs, and CLI behavior conform to expectations.
- Corner cases such as invalid upgrade names, unsupported sampling modes, and incorrect weather file paths are handled gracefully.

The tests are implemented using Ruby's `Minitest::Test` framework and are located in the `resstock/test/` directory. This test file is a key component in maintaining the integrity of the analysis pipeline across code changes and configuration updates.

**Dependencies**

- `Minitest`
- `OpenStudio CLI`
- Local YAML configuration files
- `HPXMLtoOpenStudio`, `buildstock.rb`, and associated resources

Functions
---------

The class defines a number of helper and test methods that serve distinct purposes:

**Setup Method**

- ``before_setup``:
  Initializes variables such as CLI path, command string, and buildstock output paths. Also ensures output directories from prior runs are cleared.

**Helper Methods**

- ``_test_measure_order(osw)``:
  Verifies that the sequence of OpenStudio measures in an OSW file matches the expected order.
- ``_assert_and_puts(output, msg, expect = true)``:
  Asserts that expected messages appear (or do not appear) in stdout or logs, and prints output on failure.
- ``_verify_outputs(cli_output_log)``:
  Validates `cli_output.log` for known, expected warning messages and fails on any unexpected warnings.
- ``_expected_warning_message(message, txt)``:
  Returns true if a given message is an expected warning.

Test Scenarios
--------------

The file covers a wide range of test scenarios including error conditions, configuration variants, and output verification.

**Version Check**

- ``test_version``: Confirms that ResStock, OpenStudio, and HPXML version strings are reported correctly.

**Invalid or Missing YAML Configurations**

- ``test_no_yml_argument``: No `-y` argument results in a helpful usage error.
- ``test_errors_wrong_path``: YAML path does not exist.
- ``test_errors_bad_value``: Malformed input values in YAML cause errors.
- ``test_errors_missing_key``: YAML is missing required sections like `build_existing_model`.
- ``test_errors_weather_files``: Missing weather files directory triggers configuration error.
- ``test_errors_invalid_upgrade_name``: Upgrade name misspelled or not found in valid list.
- ``test_errors_precomputed_outdated_missing_parameter``: Parameter mismatch between `buildstock.csv` and `options_lookup.tsv`.
- ``test_errors_precomputed_outdated_extra_parameter``: Additional unexpected parameter detected in project files.

**Unsupported Sampling Modes**

- ``test_errors_downselect_resample``: `resample` sampling type is not yet supported.
- ``test_errors_downsampler``: Invalid or unknown sampler type.
- ``test_errors_already_exists``: Output directory already exists before test execution.

**Selective Pipeline Execution**

- ``test_measures_only``: Executes only the measure portion of the pipeline (`-m`).
- ``test_sampling_only``: Executes only the sampling portion (`-s`).
- ``test_building_id``: Runs analysis for a specific building ID (`-i`).
- ``test_upgrade_name``: Runs analysis for multiple specified upgrades.
- ``test_threads_and_keep_run_folders``: Uses threading and preserves run directories (`-n`, `-k`).

**Precomputed and Sample Weights**

- ``test_precomputed``: Uses precomputed `buildstock.csv` with sample weights.
- ``test_precomputed_sample_weight``: Confirms weight values are correctly applied and balanced.

**Full End-to-End Runs**

- ``test_testing_baseline``: Executes the ResStock workflow using the `project_testing/testing_baseline.yml` file. Confirms expected outputs including `.osw`, `.csv`, `.xml`, and timeseries results.
- ``test_national_baseline``: Same as above, but for `project_national/national_baseline.yml`.

**Relative Paths**

- ``test_relative_weather_files_path``: Ensures weather files can be pulled using relative paths.
