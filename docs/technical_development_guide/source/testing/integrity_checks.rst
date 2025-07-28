.. _integrity_checks:

Integrity Checks
================

This file contains various integrity checks for ensuring the consistency and validity of `housing_characteristics` data and related files used in a project directory. It verifies the structure and dependencies of `.tsv` files and ensures that parameters and options conform to expected formats. The main goal of the file is to prevent errors in simulations due to improperly formatted or inconsistent data.

Specifically this is documentation for the `test/integrity_checks.rb` file.

**Dependencies**

- `buildstock.rb`
- `run_sampling_lib.rb`
- `CSV` library

These dependencies are required for reading `.tsv` files, validating options, and performing sampling.

`integrity_check` Function
--------------------------

The `integrity_check` function ensures that the `.tsv` files in the project directory are formatted correctly, all dependencies are accounted for, and parameters are valid. It checks for multiple types of issues and validates the integrity of files before they are used in further processing.

Key Steps:

- **Loading Helper Files:** The function begins by loading helper files like `buildstock.rb` and `run_sampling_lib.rb` from the `resources` directory. It also checks if a `lookup_file` (defaulting to `options_lookup.tsv`) exists.
  
- **Parameter Processing:** The function reads through each parameter defined in the `options_lookup.tsv` and checks if corresponding `.tsv` files exist in the `housing_characteristics` directory. 

- **Dependency Checks:** It validates that all parameters' dependencies are properly handled. If any parameters depend on others that are not processed yet, it waits until the dependencies are resolved.

- **Option Validation:** For each parameter, it ensures that the option names are valid by cross-referencing with `options_lookup.tsv`. The function tests for all possible combinations of dependency values and checks that they correspond to valid options.

- **File Format Validation:** Each `.tsv` file is checked for consistency in format, ensuring that line endings and other aspects follow expected standards.

- **Unprocessed Parameters:** If a parameter cannot be processed due to missing dependencies or invalid formats, an error is raised detailing which parameters are problematic.

- **Final Sampling:** After the integrity checks, the function runs a sampling process to generate the output file, which is then validated against `lookup_file` (by default `options_lookup.tsv`).

Example of Execution Flow:

- The function loops over all parameters and processes them.
- If a dependency file is missing or invalid, an error message is raised.
- If all checks pass, the function performs the sampling and validation steps.

`integrity_check_options_lookup_tsv` Function
---------------------------------------------

This function checks the integrity of the `options_lookup.tsv` file, ensuring that all parameters and options defined in the file are valid. It also checks that each option has associated measure arguments and that these measures do not conflict with others.

Key Steps:

- **Option Validation:** It iterates over each parameter defined in the `options_lookup.tsv` file and checks if the options related to each parameter are defined properly.
  
- **Illegal Character Check:** It ensures that no illegal characters (e.g., `(`, `)`, `|`, `&`) appear in the parameter or option names.
  
- **Measure Arguments Validation:** The function checks the measure arguments associated with each option, ensuring that there are no duplicate assignments across parameters.

- **Error Handling:** If any errors are encountered, such as missing measure definitions or illegal characters, an error is raised.

`check_buildstock` Function
---------------------------

This function is responsible for validating the `output_file` generated during the sampling process. It ensures that all parameters and options defined in the file are valid and conform to the structure defined in `options_lookup.tsv`.

Key Steps:

- **Opening Files:** The function opens the `output_file` and `lookup_file` to check for consistency in the data.
  
- **Parameter and Option Validation:** It verifies that all parameters in the `output_file` correspond to options defined in `options_lookup.tsv`. If a parameter is missing, an error is raised.
  
- **Argument Duplication Check:** The function ensures that there are no duplicate measure arguments across different parameters.
  
- **Error Handling:** If issues are detected in the `output_file`, such as missing options or incorrect argument assignments, an error message is generated.

`check_for_illegal_chars` Function
----------------------------------

This helper function checks for illegal characters in parameter or option names. The illegal characters `(`, `)`, `|`, and `&` are reserved for specific logic and should not appear in parameter or option names.

`check_parameter_file_format` Function
--------------------------------------

This helper function checks the file format of `.tsv` files, ensuring that each file adheres to the required newline format (`\r\n`). If an incorrect newline character is found, an error is raised.