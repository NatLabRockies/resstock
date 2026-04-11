
###### (Automatically generated documentation)

# Schedule File Builder

## Description
Builds a residential stochastic occupancy schedule file.

Generates a CSV of schedules at the specified file path, and inserts the CSV schedule file path into the output HPXML file (or overwrites it if one already exists). Stochastic schedules are generated using time-inhomogeneous Markov chains derived from American Time Use Survey data, and supplemented with sampling duration and power level from NEEA RBSA data as well as DHW draw duration and flow rate from Aquacraft/AWWA data. See <a href='https://www.sciencedirect.com/science/article/pii/S0306261922011540'>Stochastic simulation of occupant-driven energy use in a bottom-up residential building stock model</a> for a more complete description of the methodology.

## Arguments


**HPXML File Path**

Absolute/relative path of the HPXML file.

- **Name:** ``hpxml_path``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**Schedules: Column Names**

A comma-separated list of the column names to generate. If not provided, defaults to all columns. Possible column names are: occupants, lighting_interior, lighting_garage, cooking_range, dishwasher, clothes_washer, clothes_dryer, ceiling_fan, plug_loads_other, plug_loads_tv, hot_water_dishwasher, hot_water_clothes_washer, hot_water_fixtures.

- **Name:** ``schedules_column_names``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Schedules: Random Seed**

This numeric field is the seed for the random number generator.

- **Name:** ``schedules_random_seed``
- **Type:** ``Integer``

- **Units:** ``#``

- **Required:** ``false``

<br/>

**Schedules: Output CSV Path**

Absolute/relative path of the CSV file containing occupancy schedules. Relative paths are relative to the HPXML output path.

- **Name:** ``output_csv_path``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**HPXML Output File Path**

Absolute/relative output path of the HPXML file. This HPXML file will include the output CSV path.

- **Name:** ``hpxml_output_path``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**Append Output?**

If true and the output CSV file already exists, appends columns to the file rather than overwriting it. The existing output CSV file must have the same number of rows (i.e., timeseries frequency) as the new columns being appended.

- **Name:** ``append_output``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Debug Mode?**

If true, writes extra column(s) for informational purposes.

- **Name:** ``debug``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**BuildingID**

The ID of the HPXML Building. Only required if there are multiple Building elements in the HPXML file. Use 'ALL' to apply schedules to all the HPXML Buildings (dwelling units) of a multifamily building.

- **Name:** ``building_id``
- **Type:** ``String``

- **Required:** ``false``

<br/>





