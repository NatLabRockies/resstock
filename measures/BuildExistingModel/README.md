
###### (Automatically generated documentation)

# Build Existing Model

## Description
Builds the OpenStudio Model for an existing building.

Builds the OpenStudio Model using the sampling csv file, which contains the specified parameters for each existing building. Based on the supplied building number, those parameters are used to run the OpenStudio measures with appropriate arguments and build up the OpenStudio model.

## Arguments


**Buildstock CSV File Path**

Absolute/relative path of the buildstock CSV file. Relative is compared to the 'lib/housing_characteristics' directory.

- **Name:** ``buildstock_csv_path``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Project Directory**

The directory containing the housing characteristics folder (e.g., project_national).

- **Name:** ``project_directory``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**Building Unit ID**

The building unit number (between 1 and the number of samples).

- **Name:** ``building_id``
- **Type:** ``Integer``

- **Required:** ``true``

<br/>

**Sample Weight of Simulation**

Number of buildings this simulation represents.

- **Name:** ``sample_weight``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Downselect Logic**

Logic that specifies the subset of the building stock to be considered in the analysis. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``downselect_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Simulation Control: Timestep**

Value must be a divisor of 60.

- **Name:** ``simulation_control_timestep``
- **Type:** ``Integer``

- **Units:** ``min``

- **Required:** ``false``

<br/>

**Simulation Control: Run Period Begin Month**

This numeric field should contain the starting month number (1 = January, 2 = February, etc.) for the annual run period desired.

- **Name:** ``simulation_control_run_period_begin_month``
- **Type:** ``Integer``

- **Units:** ``month``

- **Required:** ``false``

<br/>

**Simulation Control: Run Period Begin Day of Month**

This numeric field should contain the starting day of the starting month (must be valid for month) for the annual run period desired.

- **Name:** ``simulation_control_run_period_begin_day_of_month``
- **Type:** ``Integer``

- **Units:** ``day``

- **Required:** ``false``

<br/>

**Simulation Control: Run Period End Month**

This numeric field should contain the end month number (1 = January, 2 = February, etc.) for the annual run period desired.

- **Name:** ``simulation_control_run_period_end_month``
- **Type:** ``Integer``

- **Units:** ``month``

- **Required:** ``false``

<br/>

**Simulation Control: Run Period End Day of Month**

This numeric field should contain the ending day of the ending month (must be valid for month) for the annual run period desired.

- **Name:** ``simulation_control_run_period_end_day_of_month``
- **Type:** ``Integer``

- **Units:** ``day``

- **Required:** ``false``

<br/>

**Simulation Control: Run Period Calendar Year**

This numeric field should contain the calendar year that determines the start day of week. If you are running simulations using AMY weather files, the value entered for calendar year will not be used; it will be overridden by the actual year found in the AMY weather file.

- **Name:** ``simulation_control_run_period_calendar_year``
- **Type:** ``Integer``

- **Units:** ``year``

- **Required:** ``false``

<br/>

**HEScore Workflow: OpenStudio-HEScore directory path**

Path to the OpenStudio-HEScore directory. If specified, the HEScore workflow will run.

- **Name:** ``os_hescore_directory``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Emissions: Scenario Names**

Names of emissions scenarios. If multiple scenarios, use a comma-separated list.

- **Name:** ``emissions_scenario_names``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Emissions: Types**

Types of emissions (e.g., CO2e, NOx, etc.). If multiple scenarios, use a comma-separated list.

- **Name:** ``emissions_types``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Emissions: Electricity Folders**

Relative paths of electricity emissions factor schedule files with hourly values. Paths are relative to the resources folder. If multiple scenarios, use a comma-separated list. File names must contain GEA region names.

- **Name:** ``emissions_electricity_folders``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Emissions: Natural Gas Values**

Natural gas emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list.

- **Name:** ``emissions_natural_gas_values``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Emissions: Propane Values**

Propane emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list.

- **Name:** ``emissions_propane_values``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Emissions: Fuel Oil Values**

Fuel oil emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list.

- **Name:** ``emissions_fuel_oil_values``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Emissions: Wood Values**

Wood emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list.

- **Name:** ``emissions_wood_values``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Scenario Names**

Names of utility bill scenarios. If multiple scenarios, use a comma-separated list. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_scenario_names``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Simple Filepaths**

Relative paths of simple utility rates. Paths are relative to the resources folder. If multiple scenarios, use a comma-separated list. Files must contain the name of the Parameter as the column header.

- **Name:** ``utility_bill_simple_filepaths``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Detailed Filepaths**

Relative paths of detailed utility rates. Paths are relative to the resources folder. If multiple scenarios, use a comma-separated list. Files must contain the name of the Parameter as the column header.

- **Name:** ``utility_bill_detailed_filepaths``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Electricity Fixed Charges**

Electricity utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_electricity_fixed_charges``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Electricity Marginal Rates**

Electricity utility bill marginal rates. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_electricity_marginal_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Natural Gas Fixed Charges**

Natural gas utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_natural_gas_fixed_charges``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Natural Gas Marginal Rates**

Natural gas utility bill marginal rates. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_natural_gas_marginal_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Propane Fixed Charges**

Propane utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_propane_fixed_charges``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Propane Marginal Rates**

Propane utility bill marginal rates. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_propane_marginal_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Fuel Oil Fixed Charges**

Fuel oil utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_fuel_oil_fixed_charges``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Fuel Oil Marginal Rates**

Fuel oil utility bill marginal rates. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_fuel_oil_marginal_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Wood Fixed Charges**

Wood utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_wood_fixed_charges``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Wood Marginal Rates**

Wood utility bill marginal rates. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_wood_marginal_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: PV Compensation Types**

Utility bill PV compensation types. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_pv_compensation_types``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: PV Net Metering Annual Excess Sellback Rate Types**

Utility bill PV net metering annual excess sellback rate types. Only applies if the PV compensation type is 'NetMetering'. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_pv_net_metering_annual_excess_sellback_rate_types``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: PV Net Metering Annual Excess Sellback Rates**

Utility bill PV net metering annual excess sellback rates. Only applies if the PV compensation type is 'NetMetering' and the PV annual excess sellback rate type is 'User-Specified'. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_pv_net_metering_annual_excess_sellback_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: PV Feed-In Tariff Rates**

Utility bill PV annual full/gross feed-in tariff rates. Only applies if the PV compensation type is 'FeedInTariff'. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_pv_feed_in_tariff_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: PV Monthly Grid Connection Fee Units**

Utility bill PV monthly grid connection fee units. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_pv_monthly_grid_connection_fee_units``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: PV Monthly Grid Connection Fees**

Utility bill PV monthly grid connection fees. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_pv_monthly_grid_connection_fees``
- **Type:** ``String``

- **Required:** ``false``

<br/>





