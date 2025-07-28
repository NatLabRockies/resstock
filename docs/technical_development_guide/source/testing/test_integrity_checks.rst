Test Integrity Checks
=====================

**Overview**

The `test_integrity_check.rb` test suite verifies the correctness and robustness of housing characteristics and buildstock configuration files in the ResStock workflow. It ensures that input files used for modeling are valid, consistent, and aligned with their corresponding lookup definitions.

These tests help catch user or developer errors in `.tsv` configuration files before a ResStock simulation is run.

This suite ensures the robustness of ResStock’s configuration validation logic. Developers adding new parameters, lookup files, or changing validation logic should:

- Add corresponding test cases.
- Run this suite before merging changes.
- Ensure expected errors are descriptive for debugging.

The test suite also confirms the CLI script (`check_buildstock.rb`) works properly, verifying integration between Ruby script execution and OpenStudio.

- **Test File:** `test/test_integrity_check.rb`
- **Resources:** `resources/test_options_lookup.tsv`, `test/tests_housing_characteristics/*`, `test/tests_buildstock_csvs/*`

Test Class: `TestResStockErrors`
--------------------------------

This class uses `Minitest::Test` and defines multiple test cases, each targeting a specific type of integrity error. Each test simulates a specific failure condition using example input folders containing malformed data.

Initialization
~~~~~~~~~~~~~~

The `before_setup` method:

- Sets the project directory name.
- Loads a test lookup file: `resources/test_options_lookup.tsv`.

Test Cases
----------

1. **`test_housing_characteristics_newline_character`**

   - **Error Checked:** Extra newline characters in the TSV input.
   - **Expected Output:**  
     `"ERROR: Incorrect newline character found in 'Location', line '1'."`

2. **`test_housing_characteristics_sum_not_one`**

   - **Error Checked:** Probabilities in the `Vintage.tsv` file do not sum to 1.
   - **Expected Output:**  
     `"ERROR: Values in Vintage.tsv incorrectly sum to 1.09."`

3. **`test_housing_characteristics_duplicate_rows`**

   - **Error Checked:** Duplicate rows with the same dependency values.
   - **Expected Output:**  
     `"ERROR: Multiple rows found in Vintage.tsv with dependencies: Location=AL_Huntsville..."`

4. **`test_housing_characteristics_missing_row`**

   - **Error Checked:** Missing row for a valid sampling value.
   - **Expected Output:**  
     `"ERROR: Could not determine appropriate option in Vintage.tsv for sample value 1.0..."`

5. **`test_housing_characteristics_bad_value`**

   - **Error Checked:** Non-numeric value in a numeric field.
   - **Expected Output:**  
     `"ERROR: Field 'hello' in Vintage.tsv must be numeric."`

6. **`test_housing_characteristics_missing_parent`**

   - **Error Checked:** Missing parent dependency file (e.g., `Location.tsv`).
   - **Expected Output:**  
     `"ERROR: Unable to process these parameters: Vintage. Perhaps one of these dependency files is missing? Location."`

7. **`test_housing_characteristics_unused_tsv`**

   - **Error Checked:** Extra/unreferenced TSV file.
   - **Expected Output:**  
     `"ERROR: TSV file .../Parameter.tsv not used in options_lookup.tsv."`

8. **`test_housing_characteristics_measure_missing_argument`**

   - **Error Checked:** Required measure argument not specified.
   - **Expected Output:**  
     `"ERROR: Required argument 'ext_surf_cat' not provided in test_options_lookup.tsv..."`

9. **`test_housing_characteristics_measure_extra_argument`**

   - **Error Checked:** Extra/undefined argument specified.
   - **Expected Output:**  
     `"ERROR: Extra argument 'extra_arg' specified in ..."`

10. **`test_housing_characteristics_measure_bad_argument_value`**

    - **Error Checked:** Invalid value for a measure argument.
    - **Expected Output:**  
      `"ERROR: Value of 'foo' for argument 'ext_surf_cat' must be one of: [\"ExteriorArea\", \"ExteriorWallArea\"]"`

11. **`test_housing_characteristics_measure_missing`**

    - **Error Checked:** Referenced measure does not exist.
    - **Expected Output:**  
      `"ERROR: Cannot find file .../ResidentialMissingMeasure/measure.rb"`

12. **`test_housing_characteristics_nonexistent_dependency_option`**

    - **Error Checked:** Reference to a nonexistent dependency value.
    - **Expected Output:**  
      `"ERROR: Location=AL_Mobile-Rgnl.AP.722230 not a valid dependency option for Vintage."`

13. **`test_options_lookup_multiple_measure_argument_assignments`**

    - **Error Checked:** Duplicate measure argument assignments across parameters.
    - **Expected Output:**  
      Error messages indicating which argument is duplicated and in which parameters.

14. **`test_housing_characteristics_missing_lookup_option`**

    - **Error Checked:** Reference to a missing option in the lookup file.
    - **Expected Output:**  
      `"ERROR: Could not find parameter 'Location' and option 'MissingOption' in ..."`

15. **`test_housing_characteristics_bad_option_spelling`**

    - **Error Checked:** Misspelled option name.
    - **Expected Output:**  
      `"ERROR: Could not find parameter 'Location' and option 'AL_birmingham.Muni.AP.722280'"`

16. **`test_buildstock_csv_valid`**

    - **Purpose:** Validates a correct `buildstock.csv` file using:

      - Method 1: Direct Ruby method call.
      - Method 2: Command line execution using `OpenStudio CLI`.

    - **Expected Output:**  
      Output message that includes `"Checking took:"`.

17. **`test_buildstock_csv_bad_parameters`**

    - **Error Checked:** Invalid parameter names in `buildstock.csv`.
    - **Expected Output:**  
      Multiple error messages such as: `"ERROR: Could not find parameter 'Location2' and option 'AL_Birmingham.Muni.AP.722280'"`

18. **`test_buildstock_csv_bad_options`**

    - **Error Checked:** Invalid option names for a valid parameter.
    - **Expected Output:**  
      Messages like: `"ERROR: Could not find parameter 'Vintage' and option '<1940s'"`