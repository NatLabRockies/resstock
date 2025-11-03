
###### (Automatically generated documentation)

# HPXML Simulation Output Report

## Description
Reports simulation outputs for residential HPXML-based models.

Processes EnergyPlus simulation outputs in order to generate an annual output file and an optional timeseries output file.

## Arguments


**Output Format**

The file format of the annual (and timeseries, if requested) outputs. If 'csv_dview' is selected, the timeseries CSV file will include header rows that facilitate opening the file in the DView application.

- **Name:** ``output_format``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `csv`, `json`, `msgpack`, `csv_dview`

<br/>

**Generate Annual Output: Total Consumptions**

Generates annual energy consumptions for the total building.

- **Name:** ``include_annual_total_consumptions``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Annual Output: Fuel Consumptions**

Generates annual energy consumptions for each fuel type.

- **Name:** ``include_annual_fuel_consumptions``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Annual Output: End Use Consumptions**

Generates annual energy consumptions for each end use.

- **Name:** ``include_annual_end_use_consumptions``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Annual Output: System Use Consumptions**

Generates annual energy consumptions for each end use of each HVAC and water heating system.

- **Name:** ``include_annual_system_use_consumptions``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Annual Output: Emissions**

Generates annual emissions. Requires the appropriate HPXML inputs to be specified.

- **Name:** ``include_annual_emissions``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Annual Output: Emission Fuel Uses**

Generates annual emissions for each fuel type. Requires the appropriate HPXML inputs to be specified.

- **Name:** ``include_annual_emission_fuels``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Annual Output: Emission End Uses**

Generates annual emissions for each end use. Requires the appropriate HPXML inputs to be specified.

- **Name:** ``include_annual_emission_end_uses``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Annual Output: Total Loads**

Generates annual heating, cooling, and hot water loads.

- **Name:** ``include_annual_total_loads``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Annual Output: Unmet Hours**

Generates annual unmet hours for heating, cooling, and EV driving.

- **Name:** ``include_annual_unmet_hours``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Annual Output: Peak Fuels**

Generates annual/summer/winter electricity peaks.

- **Name:** ``include_annual_peak_fuels``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Annual Output: Peak Loads**

Generates annual peak loads for heating/cooling.

- **Name:** ``include_annual_peak_loads``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Annual Output: Component Loads**

Generates annual heating and cooling loads disaggregated by component type.

- **Name:** ``include_annual_component_loads``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Annual Output: Hot Water Uses**

Generates annual hot water usages for each end use.

- **Name:** ``include_annual_hot_water_uses``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Annual Output: HVAC Summary**

Generates HVAC capacities, design temperatures, and design loads.

- **Name:** ``include_annual_hvac_summary``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Annual Output: Resilience**

Generates annual resilience outputs.

- **Name:** ``include_annual_resilience``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Timeseries Reporting Frequency**

The frequency at which to report timeseries output data. Using 'none' will disable timeseries outputs.

- **Name:** ``timeseries_frequency``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `none`, `timestep`, `hourly`, `daily`, `monthly`

<br/>

**Generate Timeseries Output: Total Consumptions**

Generates timeseries energy consumptions for the total building.

- **Name:** ``include_timeseries_total_consumptions``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Timeseries Output: Fuel Consumptions**

Generates timeseries energy consumptions for each fuel type.

- **Name:** ``include_timeseries_fuel_consumptions``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Timeseries Output: End Use Consumptions**

Generates timeseries energy consumptions for each end use.

- **Name:** ``include_timeseries_end_use_consumptions``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Timeseries Output: System Use Consumptions**

Generates timeseries energy consumptions for each end use of each HVAC and water heating system.

- **Name:** ``include_timeseries_system_use_consumptions``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Timeseries Output: Emissions**

Generates timeseries emissions. Requires the appropriate HPXML inputs to be specified.

- **Name:** ``include_timeseries_emissions``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Timeseries Output: Emission Fuel Uses**

Generates timeseries emissions for each fuel type. Requires the appropriate HPXML inputs to be specified.

- **Name:** ``include_timeseries_emission_fuels``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Timeseries Output: Emission End Uses**

Generates timeseries emissions for each end use. Requires the appropriate HPXML inputs to be specified.

- **Name:** ``include_timeseries_emission_end_uses``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Timeseries Output: Hot Water Uses**

Generates timeseries hot water usages for each end use.

- **Name:** ``include_timeseries_hot_water_uses``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Timeseries Output: Total Loads**

Generates timeseries heating, cooling, and hot water loads.

- **Name:** ``include_timeseries_total_loads``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Timeseries Output: Component Loads**

Generates timeseries heating and cooling loads disaggregated by component type.

- **Name:** ``include_timeseries_component_loads``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Timeseries Output: Unmet Hours**

Generates timeseries unmet hours for heating, cooling, and EV driving.

- **Name:** ``include_timeseries_unmet_hours``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Timeseries Output: Zone Temperatures**

Generates timeseries temperatures for each thermal zone.

- **Name:** ``include_timeseries_zone_temperatures``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Timeseries Output: Zone Conditions**

Generates timeseries temperatures and humidities for each thermal zone.

- **Name:** ``include_timeseries_zone_conditions``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Timeseries Output: Airflows**

Generates timeseries airflows.

- **Name:** ``include_timeseries_airflows``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Timeseries Output: Weather**

Generates timeseries weather data.

- **Name:** ``include_timeseries_weather``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Timeseries Output: Resilience**

Generates timeseries resilience outputs.

- **Name:** ``include_timeseries_resilience``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Timeseries Output: Timestamp Convention**

Determines whether timeseries timestamps use the start-of-period or end-of-period convention. Doesn't apply if the output format is 'csv_dview'.

- **Name:** ``timeseries_timestamp_convention``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `start`, `end`

<br/>

**Generate Timeseries Output: Number of Decimal Places**

Allows overriding the default number of decimal places for timeseries outputs.

- **Name:** ``timeseries_num_decimal_places``
- **Type:** ``Integer``

- **Required:** ``false``

<br/>

**Generate Timeseries Output: Add TimeDST Column**

Optionally add, in addition to the default local standard Time column, a local clock TimeDST column. Requires that daylight saving time is enabled.

- **Name:** ``add_timeseries_dst_column``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Timeseries Output: Add TimeUTC Column**

Optionally add, in addition to the default local standard Time column, a local clock TimeUTC column. If the time zone UTC offset is not provided in the HPXML file, the time zone in the EPW header will be used.

- **Name:** ``add_timeseries_utc_column``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Timeseries Output: EnergyPlus Output Variables**

Optionally generates timeseries EnergyPlus output variables. If multiple output variables are desired, use a comma-separated list. Do not include key values; by default all key values will be requested. Example: "Zone People Occupant Count, Zone People Total Heating Energy"

- **Name:** ``user_output_variables``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Generate Timeseries Output: EnergyPlus Output Meters**

Optionally generates timeseries EnergyPlus output meters. If multiple output meters are desired, use a comma-separated list. Example: "Electricity:Facility, HeatingCoils:EnergyTransfer"

- **Name:** ``user_output_meters``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Annual Output File Name**

If not provided, defaults to 'results_annual.csv' (or 'results_annual.json' or 'results_annual.msgpack').

- **Name:** ``annual_output_file_name``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Timeseries Output File Name**

If not provided, defaults to 'results_timeseries.csv' (or 'results_timeseries.json' or 'results_timeseries.msgpack').

- **Name:** ``timeseries_output_file_name``
- **Type:** ``String``

- **Required:** ``false``

<br/>





## Outputs
All possible measure outputs are listed below. Actual outputs depend on measure argument values provided.


- ``energy_use_total_m_btu``

- ``energy_use_net_m_btu``

- ``fuel_use_electricity_total_m_btu``

- ``fuel_use_electricity_net_m_btu``

- ``fuel_use_natural_gas_total_m_btu``

- ``fuel_use_fuel_oil_total_m_btu``

- ``fuel_use_propane_total_m_btu``

- ``fuel_use_wood_cord_total_m_btu``

- ``fuel_use_wood_pellets_total_m_btu``

- ``fuel_use_coal_total_m_btu``

- ``end_use_electricity_heating_m_btu``

- ``end_use_electricity_heating_fans_pumps_m_btu``

- ``end_use_electricity_heating_heat_pump_backup_m_btu``

- ``end_use_electricity_heating_heat_pump_backup_fans_pumps_m_btu``

- ``end_use_electricity_cooling_m_btu``

- ``end_use_electricity_cooling_fans_pumps_m_btu``

- ``end_use_electricity_hot_water_m_btu``

- ``end_use_electricity_hot_water_recirc_pump_m_btu``

- ``end_use_electricity_hot_water_solar_thermal_pump_m_btu``

- ``end_use_electricity_lighting_interior_m_btu``

- ``end_use_electricity_lighting_garage_m_btu``

- ``end_use_electricity_lighting_exterior_m_btu``

- ``end_use_electricity_mech_vent_m_btu``

- ``end_use_electricity_mech_vent_preheating_m_btu``

- ``end_use_electricity_mech_vent_precooling_m_btu``

- ``end_use_electricity_whole_house_fan_m_btu``

- ``end_use_electricity_refrigerator_m_btu``

- ``end_use_electricity_freezer_m_btu``

- ``end_use_electricity_dehumidifier_m_btu``

- ``end_use_electricity_dishwasher_m_btu``

- ``end_use_electricity_clothes_washer_m_btu``

- ``end_use_electricity_clothes_dryer_m_btu``

- ``end_use_electricity_range_oven_m_btu``

- ``end_use_electricity_ceiling_fan_m_btu``

- ``end_use_electricity_television_m_btu``

- ``end_use_electricity_plug_loads_m_btu``

- ``end_use_electricity_well_pump_m_btu``

- ``end_use_electricity_pool_heater_m_btu``

- ``end_use_electricity_pool_pump_m_btu``

- ``end_use_electricity_permanent_spa_heater_m_btu``

- ``end_use_electricity_permanent_spa_pump_m_btu``

- ``end_use_electricity_pv_m_btu``

- ``end_use_electricity_generator_m_btu``

- ``end_use_electricity_battery_m_btu``

- ``end_use_electricity_electric_vehicle_charging_m_btu``

- ``end_use_natural_gas_heating_m_btu``

- ``end_use_natural_gas_heating_heat_pump_backup_m_btu``

- ``end_use_natural_gas_hot_water_m_btu``

- ``end_use_natural_gas_clothes_dryer_m_btu``

- ``end_use_natural_gas_range_oven_m_btu``

- ``end_use_natural_gas_mech_vent_preheating_m_btu``

- ``end_use_natural_gas_pool_heater_m_btu``

- ``end_use_natural_gas_permanent_spa_heater_m_btu``

- ``end_use_natural_gas_grill_m_btu``

- ``end_use_natural_gas_lighting_m_btu``

- ``end_use_natural_gas_fireplace_m_btu``

- ``end_use_natural_gas_generator_m_btu``

- ``end_use_fuel_oil_heating_m_btu``

- ``end_use_fuel_oil_heating_heat_pump_backup_m_btu``

- ``end_use_fuel_oil_hot_water_m_btu``

- ``end_use_fuel_oil_clothes_dryer_m_btu``

- ``end_use_fuel_oil_range_oven_m_btu``

- ``end_use_fuel_oil_mech_vent_preheating_m_btu``

- ``end_use_fuel_oil_grill_m_btu``

- ``end_use_fuel_oil_lighting_m_btu``

- ``end_use_fuel_oil_fireplace_m_btu``

- ``end_use_fuel_oil_generator_m_btu``

- ``end_use_propane_heating_m_btu``

- ``end_use_propane_heating_heat_pump_backup_m_btu``

- ``end_use_propane_hot_water_m_btu``

- ``end_use_propane_clothes_dryer_m_btu``

- ``end_use_propane_range_oven_m_btu``

- ``end_use_propane_mech_vent_preheating_m_btu``

- ``end_use_propane_grill_m_btu``

- ``end_use_propane_lighting_m_btu``

- ``end_use_propane_fireplace_m_btu``

- ``end_use_propane_generator_m_btu``

- ``end_use_wood_cord_heating_m_btu``

- ``end_use_wood_cord_heating_heat_pump_backup_m_btu``

- ``end_use_wood_cord_hot_water_m_btu``

- ``end_use_wood_cord_clothes_dryer_m_btu``

- ``end_use_wood_cord_range_oven_m_btu``

- ``end_use_wood_cord_mech_vent_preheating_m_btu``

- ``end_use_wood_cord_grill_m_btu``

- ``end_use_wood_cord_lighting_m_btu``

- ``end_use_wood_cord_fireplace_m_btu``

- ``end_use_wood_cord_generator_m_btu``

- ``end_use_wood_pellets_heating_m_btu``

- ``end_use_wood_pellets_heating_heat_pump_backup_m_btu``

- ``end_use_wood_pellets_hot_water_m_btu``

- ``end_use_wood_pellets_clothes_dryer_m_btu``

- ``end_use_wood_pellets_range_oven_m_btu``

- ``end_use_wood_pellets_mech_vent_preheating_m_btu``

- ``end_use_wood_pellets_grill_m_btu``

- ``end_use_wood_pellets_lighting_m_btu``

- ``end_use_wood_pellets_fireplace_m_btu``

- ``end_use_wood_pellets_generator_m_btu``

- ``end_use_coal_heating_m_btu``

- ``end_use_coal_heating_heat_pump_backup_m_btu``

- ``end_use_coal_hot_water_m_btu``

- ``end_use_coal_clothes_dryer_m_btu``

- ``end_use_coal_range_oven_m_btu``

- ``end_use_coal_mech_vent_preheating_m_btu``

- ``end_use_coal_grill_m_btu``

- ``end_use_coal_lighting_m_btu``

- ``end_use_coal_fireplace_m_btu``

- ``end_use_coal_generator_m_btu``

- ``load_heating_delivered_m_btu``

- ``load_heating_heat_pump_backup_m_btu``

- ``load_cooling_delivered_m_btu``

- ``load_hot_water_delivered_m_btu``

- ``load_hot_water_tank_losses_m_btu``

- ``load_hot_water_desuperheater_m_btu``

- ``load_hot_water_solar_thermal_m_btu``

- ``unmet_hours_heating_hr``

- ``unmet_hours_cooling_hr``

- ``unmet_hours_ev_driving_hr``

- ``peak_electricity_winter_total_w``

- ``peak_electricity_summer_total_w``

- ``peak_electricity_annual_total_w``

- ``peak_electricity_winter_net_w``

- ``peak_electricity_summer_net_w``

- ``peak_electricity_annual_net_w``

- ``peak_load_heating_delivered_k_btu_hr``

- ``peak_load_cooling_delivered_k_btu_hr``

- ``component_load_heating_roofs_m_btu``

- ``component_load_heating_ceilings_m_btu``

- ``component_load_heating_walls_m_btu``

- ``component_load_heating_rim_joists_m_btu``

- ``component_load_heating_foundation_walls_m_btu``

- ``component_load_heating_doors_m_btu``

- ``component_load_heating_windows_conduction_m_btu``

- ``component_load_heating_windows_solar_m_btu``

- ``component_load_heating_skylights_conduction_m_btu``

- ``component_load_heating_skylights_solar_m_btu``

- ``component_load_heating_floors_m_btu``

- ``component_load_heating_slabs_m_btu``

- ``component_load_heating_internal_mass_m_btu``

- ``component_load_heating_infiltration_m_btu``

- ``component_load_heating_natural_ventilation_m_btu``

- ``component_load_heating_mechanical_ventilation_m_btu``

- ``component_load_heating_whole_house_fan_m_btu``

- ``component_load_heating_ducts_m_btu``

- ``component_load_heating_internal_gains_m_btu``

- ``component_load_heating_lighting_m_btu``

- ``component_load_cooling_roofs_m_btu``

- ``component_load_cooling_ceilings_m_btu``

- ``component_load_cooling_walls_m_btu``

- ``component_load_cooling_rim_joists_m_btu``

- ``component_load_cooling_foundation_walls_m_btu``

- ``component_load_cooling_doors_m_btu``

- ``component_load_cooling_windows_conduction_m_btu``

- ``component_load_cooling_windows_solar_m_btu``

- ``component_load_cooling_skylights_conduction_m_btu``

- ``component_load_cooling_skylights_solar_m_btu``

- ``component_load_cooling_floors_m_btu``

- ``component_load_cooling_slabs_m_btu``

- ``component_load_cooling_internal_mass_m_btu``

- ``component_load_cooling_infiltration_m_btu``

- ``component_load_cooling_natural_ventilation_m_btu``

- ``component_load_cooling_mechanical_ventilation_m_btu``

- ``component_load_cooling_whole_house_fan_m_btu``

- ``component_load_cooling_ducts_m_btu``

- ``component_load_cooling_internal_gains_m_btu``

- ``component_load_cooling_lighting_m_btu``

- ``hot_water_clothes_washer_gal``

- ``hot_water_dishwasher_gal``

- ``hot_water_fixtures_gal``

- ``hot_water_distribution_waste_gal``

- ``resilience_battery_hr``


