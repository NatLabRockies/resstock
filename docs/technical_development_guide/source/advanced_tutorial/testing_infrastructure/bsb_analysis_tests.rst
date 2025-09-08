BuildStockBatch Analysis Tests
==============================

Overview
--------

The `test_bsb_analysis.rb` file provides a suite of integration tests designed to validate the output of BuildStockBatch runs against expected results.
These tests verify that input/output CSVs and timeseries data match the canonical structure and expected values described in a ResStock outputs dictionary.

This test ensures:

- Input and output columns conform to the expected schema
- Annual metrics group correctly (e.g., cooling loads summing to total usage)
- Timeseries results include the appropriate columns and follow aggregation rules
- Both "testing_baseline" and "national_baseline" datasets are structurally sound

The file is structured using `Minitest::Test` and uses helper functions to map expected scenario names, parse dictionaries, and perform numerical validation.

Functions
---------

``before_setup``

- Sets up the test environment by initializing instance variables pointing to testing and national baselines.

``_map_scenario_names(list, from, to)``

- Maps placeholder scenario names in the outputs dictionary to real scenario identifiers.
- Used for matching expected outputs with actual CSV fields.

Test Scenarios
--------------

``test_testing_baseline``

- Verifies existence of results file (`results_up00.csv`) in the testing baseline.
- Checks for required directories and timeseries files.
- Confirms required CSV columns and timeseries structure are present.

``test_national_baseline``

- Performs the same checks as ``test_testing_baseline`` but on the national baseline directory.

``test_testing_inputs``

- Validates that the input columns in `results_up00.csv` match the expected input names in the outputs dictionary.
- Excludes known ignorable fields like `bills_2`, `bills_3`, and `server_directory_cleanup`.

``test_national_inputs``

- Verifies that national inputs match the expected schema defined in the outputs dictionary.
- Fails on both missing or unexpected columns.

``test_testing_annual_outputs``

- Checks for presence of expected output metrics in the testing baseline.
- Validates that grouped outputs (defined by "Sums To") aggregate numerically within tolerance (0.001).

``test_national_annual_outputs``

- Same as ``test_testing_annual_outputs``, but validates the national dataset.

``test_timeseries_resstock_outputs``

- Validates presence of expected timeseries columns in `baseline/timeseries/results_output.csv`.
- Uses the outputs dictionary to match against expected "Timeseries ResStock Name" values.
- Verifies summation logic for grouped outputs and includes unit conversion (e.g., from kWh to kBtu).

``test_timeseries_buildstockbatch_outputs``

- Same as ``test_timeseries_resstock_outputs`` but validates `buildstockbatch.csv`.
- Compares field names using "Timeseries BuildStockBatch Name" mapping.

