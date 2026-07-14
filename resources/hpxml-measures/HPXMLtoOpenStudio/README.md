
###### (Automatically generated documentation)

# HPXML to OpenStudio Translator

## Description
Translates HPXML file to OpenStudio Model



## Arguments


**HPXML File Path**

Absolute/relative path of the HPXML file.

- **Name:** ``hpxml_path``
- **Type:** ``String``

- **Required:** ``true``



**Directory for Output Files**

Absolute/relative path for the output files directory.

- **Name:** ``output_dir``
- **Type:** ``String``

- **Required:** ``true``



**Output Format**

The file format of the HVAC design load details output.

- **Name:** ``output_format``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `csv`<br/>  - `json`<br/>  - `msgpack`


- **Default:** `csv`


**Annual Output File Name**

The name of the file w/ HVAC design loads and capacities. If not provided, defaults to 'results_annual.csv' (or '.json' or '.msgpack').

- **Name:** ``annual_output_file_name``
- **Type:** ``String``

- **Required:** ``false``


- **Default:** `results_annual`


**Electric Panel Output File Name**

The name of the file w/ electric panel outputs. If not provided, defaults to 'results_panel.csv' (or '.json' or '.msgpack').

- **Name:** ``electric_panel_output_file_name``
- **Type:** ``String``

- **Required:** ``false``


- **Default:** `results_panel`


**Design Load Details Output File Name**

The name of the file w/ additional HVAC design load details. If not provided, defaults to 'results_design_load_details.csv' (or '.json' or '.msgpack').

- **Name:** ``design_load_details_output_file_name``
- **Type:** ``String``

- **Required:** ``false``


- **Default:** `results_design_load_details`


**Add component loads?**

If true, adds the calculation of heating/cooling component loads (not enabled by default for faster performance).

- **Name:** ``add_component_loads``
- **Type:** ``Boolean``

- **Required:** ``false``


- **Default:** `false`


**BuildingID**

The ID of the HPXML Building. Only required if the HPXML has multiple Building elements and WholeSFAorMFBuildingSimulation is not true.

- **Name:** ``building_id``
- **Type:** ``String``

- **Required:** ``false``



**Skip Validation?**

If true, bypasses HPXML input validation for faster performance. WARNING: This should only be used if the supplied HPXML file has already been validated against the Schema & Schematron documents.

- **Name:** ``skip_validation``
- **Type:** ``Boolean``

- **Required:** ``false``


- **Default:** `false`


**Debug Mode?**

If true: 1) Writes in.osm file, 2) Generates additional log output, and 3) Creates all EnergyPlus output files.

- **Name:** ``debug``
- **Type:** ``Boolean``

- **Required:** ``false``


- **Default:** `false`


**EMS Debug Mode?**

If true, writes the EnergyPlus EDD file with timeseries debug output for each EMS program. Note that this file can be VERY large.

- **Name:** ``ems_debug``
- **Type:** ``Boolean``

- **Required:** ``false``


- **Default:** `false`






