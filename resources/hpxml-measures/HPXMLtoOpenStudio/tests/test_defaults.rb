# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'
require_relative 'util.rb'

class HPXMLtoOpenStudioDefaultsTest < Minitest::Test
  ConstantDaySchedule = '0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1'
  ConstantMonthSchedule = '1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1'

  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(File.dirname(__FILE__), 'tmp.xml')
    @schema_validator = XMLValidator.get_xml_validator(File.join(File.dirname(__FILE__), '..', 'resources', 'hpxml_schema', 'HPXML.xsd'))
    @schematron_validator = XMLValidator.get_xml_validator(File.join(File.dirname(__FILE__), '..', 'resources', 'hpxml_schematron', 'EPvalidator.sch'))

    @args_hash = {}
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    @args_hash['output_dir'] = File.dirname(__FILE__)

    @default_schedules_csv_data = Defaults.get_schedules_csv_data()
  end

  def teardown
    cleanup_output_files([@tmp_hpxml_path])
  end

  def test_header
    # Test inputs not overridden by defaults
    hpxml, _hpxml_bldg = _create_hpxml('base.xml')
    hpxml.header.timestep = 30
    hpxml.header.sim_begin_month = 2
    hpxml.header.sim_begin_day = 2
    hpxml.header.sim_end_month = 11
    hpxml.header.sim_end_day = 11
    hpxml.header.sim_calendar_year = 2009
    hpxml.header.temperature_capacitance_multiplier = 1.5
    hpxml.header.unavailable_periods.add(column_name: 'Power Outage', begin_month: 1, begin_day: 1, begin_hour: 3, end_month: 12, end_day: 31, end_hour: 4, natvent_availability: HPXML::ScheduleUnavailable)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    default_hpxml, _default_hpxml_bldg = _test_measure()
    _test_default_header_values(default_hpxml, 30, 2, 2, 11, 11, 2009, 1.5, 3, 4, HPXML::ScheduleUnavailable)

    # Test defaults - calendar year override by AMY year
    hpxml, _hpxml_bldg = _create_hpxml('base-location-AMY-2012.xml')
    hpxml.header.timestep = nil
    hpxml.header.sim_begin_month = nil
    hpxml.header.sim_begin_day = nil
    hpxml.header.sim_end_month = nil
    hpxml.header.sim_end_day = nil
    hpxml.header.temperature_capacitance_multiplier = nil
    hpxml.header.sim_calendar_year = 2020
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    default_hpxml, _default_hpxml_bldg = _test_measure()
    _test_default_header_values(default_hpxml, 60, 1, 1, 12, 31, 2012, 7.0, nil, nil, nil)

    # Test defaults - southern hemisphere
    hpxml, _hpxml_bldg = _create_hpxml('base-location-capetown-zaf.xml')
    hpxml.header.timestep = nil
    hpxml.header.sim_begin_month = nil
    hpxml.header.sim_begin_day = nil
    hpxml.header.sim_end_month = nil
    hpxml.header.sim_end_day = nil
    hpxml.header.sim_calendar_year = nil
    hpxml.header.temperature_capacitance_multiplier = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    default_hpxml, _default_hpxml_bldg = _test_measure()
    _test_default_header_values(default_hpxml, 60, 1, 1, 12, 31, 2007, 7.0, nil, nil, nil)
  end

  def test_weather_station
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = 'USA_NV_Las.Vegas-McCarran.Intl.AP.723860_TMY3.epw'
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_equal('USA_NV_Las.Vegas-McCarran.Intl.AP.723860_TMY3.epw', default_hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath)

    # Test defaults w/ zipcode
    hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = nil
    hpxml_bldg.zip_code = '08202' # Testing a zip-code with a leading zero to make sure it's handled correctly
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_equal('USA_NJ_Cape.May.County.AP.745966_TMY3.epw', default_hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath)
    assert_equal('Cape May Co', default_hpxml_bldg.climate_and_risk_zones.weather_station_name)
    assert_equal('745966', default_hpxml_bldg.climate_and_risk_zones.weather_station_wmo)
  end

  def test_emissions_factors
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-misc-loads-large-uncommon.xml')
    for emissions_type in ['CO2e', 'NOx', 'SO2', 'foo']
      hpxml.header.emissions_scenarios.add(name: emissions_type,
                                           emissions_type: emissions_type,
                                           elec_units: HPXML::EmissionsScenario::UnitsLbPerMWh,
                                           elec_schedule_filepath: File.join(File.dirname(__FILE__), '..', 'resources', 'data', 'cambium', 'LRMER_MidCase.csv'),
                                           elec_schedule_number_of_header_rows: 1,
                                           elec_schedule_column_number: 9,
                                           natural_gas_units: HPXML::EmissionsScenario::UnitsLbPerMBtu,
                                           natural_gas_value: 123.0,
                                           propane_units: HPXML::EmissionsScenario::UnitsLbPerMBtu,
                                           propane_value: 234.0,
                                           fuel_oil_units: HPXML::EmissionsScenario::UnitsKgPerMBtu,
                                           fuel_oil_value: 345.0,
                                           coal_units: HPXML::EmissionsScenario::UnitsKgPerMBtu,
                                           coal_value: 456.0,
                                           wood_units: HPXML::EmissionsScenario::UnitsKgPerMBtu,
                                           wood_value: 666.0,
                                           wood_pellets_units: HPXML::EmissionsScenario::UnitsLbPerMBtu,
                                           wood_pellets_value: 999.0)
    end
    hpxml_bldg.water_heating_systems[0].fuel_type = HPXML::FuelTypePropane
    hpxml_bldg.clothes_dryers[0].fuel_type = HPXML::FuelTypeOil
    hpxml_bldg.cooking_ranges[0].fuel_type = HPXML::FuelTypeWoodCord
    hpxml_bldg.fuel_loads[0].fuel_type = HPXML::FuelTypeWoodPellets
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    default_hpxml, _default_hpxml_bldg = _test_measure()
    default_hpxml.header.emissions_scenarios.each do |scenario|
      _test_default_emissions_values(scenario, 1, 9,
                                     HPXML::EmissionsScenario::UnitsLbPerMBtu, 123.0,
                                     HPXML::EmissionsScenario::UnitsLbPerMBtu, 234.0,
                                     HPXML::EmissionsScenario::UnitsKgPerMBtu, 345.0,
                                     HPXML::EmissionsScenario::UnitsKgPerMBtu, 456.0,
                                     HPXML::EmissionsScenario::UnitsKgPerMBtu, 666.0,
                                     HPXML::EmissionsScenario::UnitsLbPerMBtu, 999.0)
    end

    # Test defaults
    hpxml.header.emissions_scenarios.each do |scenario|
      scenario.elec_schedule_column_number = nil
      scenario.natural_gas_units = nil
      scenario.natural_gas_value = nil
      scenario.propane_units = nil
      scenario.propane_value = nil
      scenario.fuel_oil_units = nil
      scenario.fuel_oil_value = nil
      scenario.coal_units = nil
      scenario.coal_value = nil
      scenario.wood_units = nil
      scenario.wood_value = nil
      scenario.wood_pellets_units = nil
      scenario.wood_pellets_value = nil
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    default_hpxml, _default_hpxml_bldg = _test_measure()
    default_hpxml.header.emissions_scenarios.each do |scenario|
      if scenario.emissions_type == 'CO2e'
        natural_gas_value, propane_value, fuel_oil_value = 147.3, 177.8, 195.9 # lb/MBtu
      elsif scenario.emissions_type == 'NOx'
        natural_gas_value, propane_value, fuel_oil_value = 0.0922, 0.1421, 0.1300 # lb/MBtu
      elsif scenario.emissions_type == 'SO2'
        natural_gas_value, propane_value, fuel_oil_value = 0.0006, 0.0002, 0.0015 # lb/MBtu
      else
        natural_gas_value, propane_value, fuel_oil_value = nil, nil, nil
      end
      _test_default_emissions_values(scenario, 1, 1,
                                     HPXML::EmissionsScenario::UnitsLbPerMBtu, natural_gas_value,
                                     HPXML::EmissionsScenario::UnitsLbPerMBtu, propane_value,
                                     HPXML::EmissionsScenario::UnitsLbPerMBtu, fuel_oil_value,
                                     nil, nil,
                                     nil, nil,
                                     nil, nil)
    end
  end

  def test_utility_bills
    # Test inputs not overridden by defaults
    hpxml, _hpxml_bldg = _create_hpxml('base-pv.xml')
    hpxml.header.utility_bill_scenarios.clear
    for pv_compensation_type in [HPXML::PVCompensationTypeNetMetering, HPXML::PVCompensationTypeFeedInTariff]
      hpxml.header.utility_bill_scenarios.add(name: pv_compensation_type,
                                              elec_fixed_charge: 8,
                                              natural_gas_fixed_charge: 9,
                                              propane_fixed_charge: 10,
                                              fuel_oil_fixed_charge: 11,
                                              coal_fixed_charge: 12,
                                              wood_fixed_charge: 13,
                                              wood_pellets_fixed_charge: 14,
                                              elec_marginal_rate: 0.2,
                                              natural_gas_marginal_rate: 0.3,
                                              propane_marginal_rate: 0.4,
                                              fuel_oil_marginal_rate: 0.5,
                                              coal_marginal_rate: 0.6,
                                              wood_marginal_rate: 0.7,
                                              wood_pellets_marginal_rate: 0.8,
                                              pv_compensation_type: pv_compensation_type,
                                              pv_net_metering_annual_excess_sellback_rate_type: HPXML::PVAnnualExcessSellbackRateTypeRetailElectricityCost,
                                              pv_net_metering_annual_excess_sellback_rate: 0.04,
                                              pv_feed_in_tariff_rate: 0.15,
                                              pv_monthly_grid_connection_fee_dollars: 3)
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    default_hpxml, _default_hpxml_bldg = _test_measure()
    scenarios = default_hpxml.header.utility_bill_scenarios
    _test_default_bills_values(scenarios[0], 8, 9, 10, 11, 12, 13, 14, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, HPXML::PVCompensationTypeNetMetering, HPXML::PVAnnualExcessSellbackRateTypeRetailElectricityCost, nil, nil, nil, 3)
    _test_default_bills_values(scenarios[1], 8, 9, 10, 11, 12, 13, 14, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, HPXML::PVCompensationTypeFeedInTariff, nil, nil, 0.15, nil, 3)

    # Test defaults
    hpxml.header.utility_bill_scenarios.each do |scenario|
      scenario.elec_fixed_charge = nil
      scenario.natural_gas_fixed_charge = nil
      scenario.propane_fixed_charge = nil
      scenario.fuel_oil_fixed_charge = nil
      scenario.coal_fixed_charge = nil
      scenario.wood_fixed_charge = nil
      scenario.wood_pellets_fixed_charge = nil
      scenario.elec_marginal_rate = nil
      scenario.natural_gas_marginal_rate = nil
      scenario.propane_marginal_rate = nil
      scenario.fuel_oil_marginal_rate = nil
      scenario.coal_marginal_rate = nil
      scenario.wood_marginal_rate = nil
      scenario.wood_pellets_marginal_rate = nil
      scenario.pv_compensation_type = nil
      scenario.pv_net_metering_annual_excess_sellback_rate_type = nil
      scenario.pv_net_metering_annual_excess_sellback_rate = nil
      scenario.pv_feed_in_tariff_rate = nil
      scenario.pv_monthly_grid_connection_fee_dollars_per_kw = nil
      scenario.pv_monthly_grid_connection_fee_dollars = nil
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    default_hpxml, _default_hpxml_bldg = _test_measure()
    default_hpxml.header.utility_bill_scenarios.each do |scenario|
      _test_default_bills_values(scenario, 12, 12, nil, nil, nil, nil, nil, 0.1253, 0.9688, nil, nil, nil, nil, nil, HPXML::PVCompensationTypeNetMetering, HPXML::PVAnnualExcessSellbackRateTypeUserSpecified, 0.03, nil, nil, 0)
    end

    # Test defaults w/ electricity JSON file
    hpxml.header.utility_bill_scenarios.each do |scenario|
      scenario.elec_tariff_filepath = File.join(File.dirname(__FILE__), '..', '..', 'ReportUtilityBills', 'resources', 'detailed_rates', 'Sample Tiered Rate.json')
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    default_hpxml, _default_hpxml_bldg = _test_measure()
    default_hpxml.header.utility_bill_scenarios.each do |scenario|
      _test_default_bills_values(scenario, nil, 12, nil, nil, nil, nil, nil, nil, 0.9688, nil, nil, nil, nil, nil, HPXML::PVCompensationTypeNetMetering, HPXML::PVAnnualExcessSellbackRateTypeUserSpecified, 0.03, nil, nil, 0)
    end
  end

  def test_building
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
    hpxml_bldg.dst_observed = false
    hpxml_bldg.dst_begin_month = 3
    hpxml_bldg.dst_begin_day = 3
    hpxml_bldg.dst_end_month = 10
    hpxml_bldg.dst_end_day = 10
    hpxml_bldg.state_code = 'CA'
    hpxml_bldg.city = 'CityName'
    hpxml_bldg.time_zone_utc_offset = -8
    hpxml_bldg.elevation = -1234
    hpxml_bldg.latitude = 12
    hpxml_bldg.longitude = -34
    hpxml_bldg.header.natvent_days_per_week = 7
    hpxml_bldg.header.heat_pump_sizing_methodology = HPXML::HeatPumpSizingMaxLoad
    hpxml_bldg.header.heat_pump_backup_sizing_methodology = HPXML::HeatPumpBackupSizingSupplemental
    hpxml_bldg.header.allow_increased_fixed_capacities = true
    hpxml_bldg.header.shading_summer_begin_month = 2
    hpxml_bldg.header.shading_summer_begin_day = 3
    hpxml_bldg.header.shading_summer_end_month = 4
    hpxml_bldg.header.shading_summer_end_day = 5
    hpxml_bldg.header.manualj_heating_design_temp = 0.0
    hpxml_bldg.header.manualj_cooling_design_temp = 100.0
    hpxml_bldg.header.manualj_daily_temp_range = HPXML::ManualJDailyTempRangeLow
    hpxml_bldg.header.manualj_heating_setpoint = 68.0
    hpxml_bldg.header.manualj_cooling_setpoint = 78.0
    hpxml_bldg.header.manualj_humidity_setpoint = 0.33
    hpxml_bldg.header.manualj_humidity_difference = 50.0
    hpxml_bldg.header.manualj_internal_loads_sensible = 1600.0
    hpxml_bldg.header.manualj_internal_loads_latent = 60.0
    hpxml_bldg.header.manualj_num_occupants = 8
    hpxml_bldg.header.manualj_infiltration_method = HPXML::ManualJInfiltrationMethodBlowerDoor
    hpxml_bldg.header.manualj_infiltration_shielding_class = 1
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_building_values(default_hpxml_bldg, false, nil, nil, nil, nil, 'CA', 'CityName', -8, -1234, 12, -34, 7, HPXML::HeatPumpSizingMaxLoad, true,
                                  2, 3, 4, 5, 0.0, 100.0, HPXML::ManualJDailyTempRangeLow, 68.0, 78.0, 0.33, 50.0, 1600.0, 60.0, 8, HPXML::HeatPumpBackupSizingSupplemental, HPXML::ManualJInfiltrationMethodBlowerDoor, 1)

    # Test defaults - DST not in weather file
    hpxml_bldg.dst_observed = nil
    hpxml_bldg.dst_begin_month = nil
    hpxml_bldg.dst_begin_day = nil
    hpxml_bldg.dst_end_month = nil
    hpxml_bldg.dst_end_day = nil
    hpxml_bldg.state_code = nil
    hpxml_bldg.city = nil
    hpxml_bldg.time_zone_utc_offset = nil
    hpxml_bldg.elevation = nil
    hpxml_bldg.latitude = nil
    hpxml_bldg.longitude = nil
    hpxml_bldg.header.natvent_days_per_week = nil
    hpxml_bldg.header.heat_pump_sizing_methodology = nil
    hpxml_bldg.header.heat_pump_backup_sizing_methodology = nil
    hpxml_bldg.header.allow_increased_fixed_capacities = nil
    hpxml_bldg.header.shading_summer_begin_month = nil
    hpxml_bldg.header.shading_summer_begin_day = nil
    hpxml_bldg.header.shading_summer_end_month = nil
    hpxml_bldg.header.shading_summer_end_day = nil
    hpxml_bldg.header.manualj_heating_design_temp = nil
    hpxml_bldg.header.manualj_cooling_design_temp = nil
    hpxml_bldg.header.manualj_daily_temp_range = nil
    hpxml_bldg.header.manualj_heating_setpoint = nil
    hpxml_bldg.header.manualj_cooling_setpoint = nil
    hpxml_bldg.header.manualj_humidity_setpoint = nil
    hpxml_bldg.header.manualj_humidity_difference = nil
    hpxml_bldg.header.manualj_internal_loads_sensible = nil
    hpxml_bldg.header.manualj_internal_loads_latent = nil
    hpxml_bldg.header.manualj_num_occupants = nil
    hpxml_bldg.header.manualj_infiltration_method = nil
    hpxml_bldg.header.manualj_infiltration_shielding_class = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_building_values(default_hpxml_bldg, true, 3, 12, 11, 5, 'CO', 'Denver Intl Ap', -7, 5413.4, 39.83, -104.65, 3, HPXML::HeatPumpSizingHERS, false,
                                  5, 1, 10, 31, 6.8, 91.76, HPXML::ManualJDailyTempRangeHigh, 70.0, 75.0, 0.45, -28.8, 2400.0, 0.0, 4, HPXML::HeatPumpBackupSizingEmergency, HPXML::ManualJInfiltrationMethodBlowerDoor, 4)

    # Test defaults w/ StateCode (defaulted based on EPW)
    hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = 'USA_AZ_Phoenix-Sky.Harbor.Intl.AP.722780_TMY3.epw'
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_equal(false, default_hpxml_bldg.dst_observed)
    assert_nil(default_hpxml_bldg.dst_begin_month)
    assert_nil(default_hpxml_bldg.dst_begin_day)
    assert_nil(default_hpxml_bldg.dst_end_month)
    assert_nil(default_hpxml_bldg.dst_end_day)

    # Test defaults w/ ZipCode (in a different state than the weather station)
    hpxml_bldg.zip_code = '86441'
    hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = 'USA_NV_Las.Vegas-McCarran.Intl.AP.723860_TMY3.epw'
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_equal('Dolan Springs', default_hpxml_bldg.city)
    assert_equal('AZ', default_hpxml_bldg.state_code)
    assert_equal(35.8897, default_hpxml_bldg.latitude)
    assert_equal(-114.599, default_hpxml_bldg.longitude)
    assert_equal(-7.0, default_hpxml_bldg.time_zone_utc_offset)

    # Test defaults w/ NumberOfResidents provided and less than Nbr+1
    hpxml_bldg.building_occupancy.number_of_residents = 1
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_equal(4, default_hpxml_bldg.header.manualj_num_occupants)

    # Test defaults w/ NumberOfResidents provided and greater than Nbr+1
    hpxml_bldg.building_occupancy.number_of_residents = 5.5
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_equal(5.5, default_hpxml_bldg.header.manualj_num_occupants)

    # Test defaults - DST in weather file
    hpxml, hpxml_bldg = _create_hpxml('base-location-AMY-2012.xml')
    hpxml_bldg.dst_observed = nil
    hpxml_bldg.dst_begin_month = nil
    hpxml_bldg.dst_begin_day = nil
    hpxml_bldg.dst_end_month = nil
    hpxml_bldg.dst_end_day = nil
    hpxml_bldg.state_code = nil
    hpxml_bldg.city = nil
    hpxml_bldg.time_zone_utc_offset = nil
    hpxml_bldg.elevation = nil
    hpxml_bldg.latitude = nil
    hpxml_bldg.longitude = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_building_values(default_hpxml_bldg, true, 3, 11, 11, 4, 'CO', 'Boulder', -7, 5300.2, 40.13, -105.22, 3, nil, false,
                                  5, 1, 9, 30, 10.22, 91.4, HPXML::ManualJDailyTempRangeHigh, 70.0, 75.0, 0.45, -38.5, 2400.0, 0.0, 4, nil, HPXML::ManualJInfiltrationMethodBlowerDoor, 4)

    # Test defaults - southern hemisphere, invalid state code
    hpxml, hpxml_bldg = _create_hpxml('base-location-capetown-zaf.xml')
    hpxml_bldg.dst_observed = nil
    hpxml_bldg.dst_begin_month = nil
    hpxml_bldg.dst_begin_day = nil
    hpxml_bldg.dst_end_month = nil
    hpxml_bldg.dst_end_day = nil
    hpxml_bldg.state_code = nil
    hpxml_bldg.city = nil
    hpxml_bldg.time_zone_utc_offset = nil
    hpxml_bldg.elevation = nil
    hpxml_bldg.latitude = nil
    hpxml_bldg.longitude = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_building_values(default_hpxml_bldg, true, 3, 12, 11, 5, '-', 'CAPE TOWN', 2, 137.8, -33.98, 18.6, 3, nil, false,
                                  12, 1, 4, 30, 41.0, 84.38, HPXML::ManualJDailyTempRangeMedium, 70.0, 75.0, 0.5, 1.6, 2400.0, 0.0, 4, nil, HPXML::ManualJInfiltrationMethodBlowerDoor, 4)

    # Test defaults - leakiness description default to HPXML::ManualJInfiltrationMethodDefaultTable
    hpxml, hpxml_bldg = _create_hpxml('base-enclosure-infil-leakiness-description.xml')
    hpxml_bldg.header.manualj_infiltration_method = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_building_values(default_hpxml_bldg, true, 3, 12, 11, 5, 'CO', 'Denver Intl Ap', -7, 5413.4, 39.83, -104.65, 3, nil, false,
                                  5, 1, 10, 31, 6.8, 91.76, HPXML::ManualJDailyTempRangeHigh, 70.0, 75.0, 0.45, -28.8, 2400.0, 0.0, 4, nil, HPXML::ManualJInfiltrationMethodDefaultTable, 4)
  end

  def test_site
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.site.site_type = HPXML::SiteTypeRural
    hpxml_bldg.site.shielding_of_home = HPXML::ShieldingExposed
    hpxml_bldg.site.ground_conductivity = 0.8
    hpxml_bldg.site.ground_diffusivity = 0.9
    hpxml_bldg.site.soil_type = HPXML::SiteSoilTypeClay
    hpxml_bldg.site.moisture_type = HPXML::SiteSoilMoistureTypeDry
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_site_values(default_hpxml_bldg, HPXML::SiteTypeRural, HPXML::ShieldingExposed, 0.8, 0.9, HPXML::SiteSoilTypeClay, HPXML::SiteSoilMoistureTypeDry)

    # Test defaults
    hpxml_bldg.site.site_type = nil
    hpxml_bldg.site.shielding_of_home = nil
    hpxml_bldg.site.ground_conductivity = nil
    hpxml_bldg.site.ground_diffusivity = nil
    hpxml_bldg.site.soil_type = nil
    hpxml_bldg.site.moisture_type = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_site_values(default_hpxml_bldg, HPXML::SiteTypeSuburban, HPXML::ShieldingNormal, 1.0, 0.0208, HPXML::SiteSoilTypeUnknown, HPXML::SiteSoilMoistureTypeMixed)

    # Test defaults w/ gravel soil type
    hpxml_bldg.site.soil_type = HPXML::SiteSoilTypeGravel
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_site_values(default_hpxml_bldg, HPXML::SiteTypeSuburban, HPXML::ShieldingNormal, 0.6355, 0.0194, HPXML::SiteSoilTypeGravel, HPXML::SiteSoilMoistureTypeMixed)

    # Test defaults w/ conductivity but no diffusivity
    hpxml_bldg.site.ground_conductivity = 2.0
    hpxml_bldg.site.ground_diffusivity = nil
    hpxml_bldg.site.soil_type = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_site_values(default_hpxml_bldg, HPXML::SiteTypeSuburban, HPXML::ShieldingNormal, 2.0, 0.0416, nil, nil)

    # Test defaults w/ diffusivity but no conductivity
    hpxml_bldg.site.ground_conductivity = nil
    hpxml_bldg.site.ground_diffusivity = 0.025
    hpxml_bldg.site.soil_type = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_site_values(default_hpxml_bldg, HPXML::SiteTypeSuburban, HPXML::ShieldingNormal, 1.202, 0.025, nil, nil)

    # Test defaults w/ apartment unit
    hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit.xml')
    hpxml_bldg.site.site_type = nil
    hpxml_bldg.site.shielding_of_home = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_site_values(default_hpxml_bldg, HPXML::SiteTypeSuburban, HPXML::ShieldingWellShielded, 1.0, 0.0208, HPXML::SiteSoilTypeUnknown, HPXML::SiteSoilMoistureTypeMixed)
  end

  def test_neighbor_buildings
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-misc-neighbor-shading.xml')
    hpxml_bldg.neighbor_buildings[-1].delete
    hpxml_bldg.neighbor_buildings[-1].delete
    hpxml_bldg.neighbor_buildings[0].azimuth = 123
    hpxml_bldg.neighbor_buildings[1].azimuth = 321
    hpxml_bldg.walls[0].azimuth = 123
    hpxml_bldg.walls[1].azimuth = 321
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_neighbor_building_values(default_hpxml_bldg, [123, 321])

    # Test defaults
    hpxml_bldg.neighbor_buildings[0].azimuth = nil
    hpxml_bldg.neighbor_buildings[1].azimuth = nil
    hpxml_bldg.neighbor_buildings[0].orientation = HPXML::OrientationEast
    hpxml_bldg.neighbor_buildings[1].orientation = HPXML::OrientationNorth
    hpxml_bldg.walls[0].azimuth = 90
    hpxml_bldg.walls[1].azimuth = 0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_neighbor_building_values(default_hpxml_bldg, [90, 0])
  end

  def test_occupancy
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.building_occupancy.weekday_fractions = ConstantDaySchedule
    hpxml_bldg.building_occupancy.weekend_fractions = ConstantDaySchedule
    hpxml_bldg.building_occupancy.monthly_multipliers = ConstantMonthSchedule
    hpxml_bldg.building_occupancy.general_water_use_usage_multiplier = 2.0
    hpxml_bldg.building_occupancy.general_water_use_weekday_fractions = ConstantDaySchedule
    hpxml_bldg.building_occupancy.general_water_use_weekend_fractions = ConstantDaySchedule
    hpxml_bldg.building_occupancy.general_water_use_monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_occupancy_values(default_hpxml_bldg, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule,
                                   ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule, 2.0)

    # Test defaults
    hpxml_bldg.building_occupancy.weekday_fractions = nil
    hpxml_bldg.building_occupancy.weekend_fractions = nil
    hpxml_bldg.building_occupancy.monthly_multipliers = nil
    hpxml_bldg.building_occupancy.general_water_use_usage_multiplier = nil
    hpxml_bldg.building_occupancy.general_water_use_weekday_fractions = nil
    hpxml_bldg.building_occupancy.general_water_use_weekend_fractions = nil
    hpxml_bldg.building_occupancy.general_water_use_monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    default_occ_sched = @default_schedules_csv_data[SchedulesFile::Columns[:Occupants].name]
    default_gwu_sched = @default_schedules_csv_data[SchedulesFile::Columns[:GeneralWaterUse].name]
    _test_default_occupancy_values(default_hpxml_bldg, default_occ_sched['WeekdayScheduleFractions'], default_occ_sched['WeekendScheduleFractions'], default_occ_sched['MonthlyScheduleMultipliers'],
                                   default_gwu_sched['GeneralWaterUseWeekdayScheduleFractions'], default_gwu_sched['GeneralWaterUseWeekendScheduleFractions'], default_gwu_sched['GeneralWaterUseMonthlyScheduleMultipliers'], 1.0)
  end

  def test_building_construction
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.building_construction.number_of_bathrooms = 4
    hpxml_bldg.building_construction.conditioned_building_volume = 20000
    hpxml_bldg.building_construction.average_ceiling_height = 7
    hpxml_bldg.building_construction.number_of_units = 3
    hpxml_bldg.building_construction.unit_height_above_grade = 1.6
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_building_construction_values(default_hpxml_bldg, 20000, 7.0, 4, 3, 1.6)

    # Test defaults
    hpxml_bldg.building_construction.conditioned_building_volume = nil
    hpxml_bldg.building_construction.average_ceiling_height = nil
    hpxml_bldg.building_construction.number_of_bathrooms = nil
    hpxml_bldg.building_construction.number_of_units = nil
    hpxml_bldg.building_construction.unit_height_above_grade = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_building_construction_values(default_hpxml_bldg, 21600, 8.0, 2, 1, -7)

    # Test defaults w/ conditioned crawlspace
    hpxml, hpxml_bldg = _create_hpxml('base-foundation-conditioned-crawlspace.xml')
    hpxml_bldg.building_construction.conditioned_building_volume = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_building_construction_values(default_hpxml_bldg, 16200, 8.0, 2, 1, 0)

    # Test defaults w/ belly-and-wing foundation
    hpxml, hpxml_bldg = _create_hpxml('base-foundation-belly-wing-skirt.xml')
    hpxml_bldg.building_construction.conditioned_building_volume = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_building_construction_values(default_hpxml_bldg, 10800, 8.0, 2, 1, 2)

    # Test defaults w/ pier & beam foundation
    hpxml, hpxml_bldg = _create_hpxml('base-foundation-ambient.xml')
    hpxml_bldg.building_construction.conditioned_building_volume = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_building_construction_values(default_hpxml_bldg, 10800, 8.0, 2, 1, 2)

    # Test defaults w/ cathedral ceiling
    hpxml, hpxml_bldg = _create_hpxml('base-atticroof-cathedral.xml')
    hpxml_bldg.building_construction.conditioned_building_volume = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_building_construction_values(default_hpxml_bldg, 32400, 12.0, 2, 1, -7)

    # Test defaults w/ conditioned attic
    hpxml, hpxml_bldg = _create_hpxml('base-atticroof-conditioned.xml')
    hpxml_bldg.building_construction.conditioned_building_volume = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_building_construction_values(default_hpxml_bldg, 28800, 8.0, 2, 1, -7)
  end

  def test_climate_and_risk_zones
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].year = 2009
    hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone = '2B'
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_climate_and_risk_zones_values(default_hpxml_bldg, 2009, '2B')

    # Test defaults
    hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].delete
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_climate_and_risk_zones_values(default_hpxml_bldg, 2006, '5B')

    # Test defaults - invalid IECC zone
    hpxml, _hpxml_bldg = _create_hpxml('base-location-capetown-zaf.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_climate_and_risk_zones_values(default_hpxml_bldg, nil, nil)
  end

  def test_infiltration
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.air_infiltration_measurements[0].infiltration_volume = 25000
    hpxml_bldg.air_infiltration.has_flue_or_chimney_in_conditioned_space = true
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_infiltration_values(default_hpxml_bldg, 25000, true)

    # Test defaults w/ conditioned basement
    hpxml_bldg.air_infiltration_measurements[0].infiltration_volume = nil
    hpxml_bldg.air_infiltration.has_flue_or_chimney_in_conditioned_space = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_infiltration_values(default_hpxml_bldg, 2700 * 8, false)

    # Test defaults w/ conditioned basement and atmospheric water heater w/ flue
    hpxml_bldg.water_heating_systems[0].fuel_type = HPXML::FuelTypeNaturalGas
    hpxml_bldg.water_heating_systems[0].uniform_energy_factor = 0.6
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_infiltration_values(default_hpxml_bldg, 2700 * 8, true)

    # Test defaults w/o conditioned basement
    hpxml, hpxml_bldg = _create_hpxml('base-foundation-slab.xml')
    hpxml_bldg.air_infiltration_measurements[0].infiltration_volume = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_infiltration_values(default_hpxml_bldg, 1350 * 8, false)

    # Test defaults w/ conditioned crawlspace
    hpxml, hpxml_bldg = _create_hpxml('base-foundation-conditioned-crawlspace.xml')
    hpxml_bldg.air_infiltration_measurements[0].infiltration_volume = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_infiltration_values(default_hpxml_bldg, 1350 * 12, false)

    # Test defaults w/ shared system
    hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit-shared-boiler-only-baseboard.xml')
    hpxml_bldg.heating_systems[0].heating_efficiency_afue = 0.8
    hpxml_bldg.air_infiltration.has_flue_or_chimney_in_conditioned_space = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_infiltration_values(default_hpxml_bldg, 900 * 8, false)
  end

  def test_infiltration_leakiness_description
    # Tests from ResDB.Infiltration.Model.v2.xlsx

    def _get_base_building(retain_cond_bsmt: false)
      hpxml, hpxml_bldg = _create_hpxml('base-enclosure-2stories.xml')
      hpxml_bldg.building_construction.year_built = 1999
      hpxml_bldg.building_construction.conditioned_floor_area = 2000.0
      hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served = 2000.0
      hpxml_bldg.hvac_distributions[0].ducts[0].duct_fraction_area = 1.0
      hpxml_bldg.hvac_distributions[0].ducts[1].duct_fraction_area = 1.0
      hpxml_bldg.hvac_distributions[0].ducts[-1].delete
      hpxml_bldg.hvac_distributions[0].ducts[-1].delete
      hpxml_bldg.building_construction.number_of_conditioned_floors_above_grade = 2
      hpxml_bldg.building_construction.average_ceiling_height = 8.0
      hpxml_bldg.building_construction.year_built = 1975
      hpxml_bldg.building_construction.conditioned_building_volume = nil
      hpxml_bldg.rim_joists[0].delete
      hpxml_bldg.air_infiltration_measurements[0].leakiness_description = HPXML::LeakinessAverage
      hpxml_bldg.air_infiltration_measurements[0].air_leakage = nil
      hpxml_bldg.air_infiltration_measurements[0].unit_of_measure = nil
      hpxml_bldg.air_infiltration_measurements[0].house_pressure = nil
      hpxml_bldg.air_infiltration_measurements[0].infiltration_volume = nil
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone = '3B'
      hpxml_bldg.slabs[0].area = 1000.0
      hpxml_bldg.floors[0].area = 1000.0
      if not retain_cond_bsmt
        hpxml_bldg.foundations[0].foundation_type = HPXML::FoundationTypeSlab
        hpxml_bldg.foundation_walls.reverse_each do |fw|
          fw.delete
        end
        hpxml_bldg.slabs[0].interior_adjacent_to = HPXML::LocationConditionedSpace
      end
      return hpxml, hpxml_bldg
    end

    # Test Base
    hpxml, _hpxml_bldg = _get_base_building()
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_infiltration_values(default_hpxml_bldg, 2000 * 8, false, 9.7)

    # Test Base w/ CFA = 1000 ft2
    hpxml, hpxml_bldg = _get_base_building()
    hpxml_bldg.building_construction.conditioned_floor_area = 1000.0
    hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served = 1000.0
    hpxml_bldg.slabs[0].area = 500.0
    hpxml_bldg.floors[0].area = 500.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_infiltration_values(default_hpxml_bldg, 1000 * 8, false, 11.8)

    # Test Base w/ 1 story
    hpxml, hpxml_bldg = _get_base_building()
    hpxml_bldg.building_construction.number_of_conditioned_floors_above_grade = 1
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_infiltration_values(default_hpxml_bldg, 2000 * 8, false, 10.2)

    # Test Base w/ 12ft ceiling height
    hpxml, hpxml_bldg = _get_base_building()
    hpxml_bldg.building_construction.average_ceiling_height = 12.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_infiltration_values(default_hpxml_bldg, 2000 * 12.0, false, 7.6)

    # Test Base w/ 2013 year built
    hpxml, hpxml_bldg = _get_base_building()
    hpxml_bldg.building_construction.year_built = 2013
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_infiltration_values(default_hpxml_bldg, 2000 * 8.0, false, 5.3)

    # Test Base w/ 4C IECC zone
    hpxml, hpxml_bldg = _get_base_building()
    hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4C'
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_infiltration_values(default_hpxml_bldg, 2000 * 8.0, false, 13.1)

    # Test Base w/ conditioned basement foundation
    hpxml, _hpxml_bldg = _get_base_building(retain_cond_bsmt: true)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_infiltration_values(default_hpxml_bldg, 2000 * 8.0, false, 11.2)

    # Test Base w/ ducts in conditioned space
    hpxml, hpxml_bldg = _get_base_building()
    hpxml_bldg.hvac_distributions[0].ducts.each do |duct|
      duct.duct_location = HPXML::LocationConditionedSpace
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_infiltration_values(default_hpxml_bldg, 2000 * 8, false, 8.0)

    # Test Base w/ tight leakiness
    hpxml, hpxml_bldg = _get_base_building()
    hpxml_bldg.air_infiltration_measurements[0].leakiness_description = HPXML::LeakinessTight
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_infiltration_values(default_hpxml_bldg, 2000 * 8, false, 9.7 * 0.686)

    # Test for ductless == conditioned ducts
    hpxml, hpxml_bldg = _get_base_building()
    hpxml_bldg.hvac_distributions[0].ducts.reverse_each do |duct|
      duct.delete
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_infiltration_values(default_hpxml_bldg, 2000 * 8, false, 8.0)

    # Test for 25% ducted + 75% ductless system
    hpxml_bldg.hvac_distributions[0].ducts.add(id: 'Ducts1',
                                               duct_type: HPXML::DuctTypeSupply,
                                               duct_insulation_r_value: 8,
                                               duct_location: HPXML::LocationAtticUnvented,
                                               duct_surface_area: 50)
    hpxml_bldg.hvac_distributions[0].ducts.add(id: 'Ducts2',
                                               duct_type: HPXML::DuctTypeReturn,
                                               duct_insulation_r_value: 8,
                                               duct_location: HPXML::LocationAtticUnvented,
                                               duct_surface_area: 50)
    hpxml_bldg.heating_systems[0].fraction_heat_load_served = 0.25 # 25% ducts in attic
    hpxml_bldg.cooling_systems[0].fraction_cool_load_served = 0.25
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_infiltration_values(default_hpxml_bldg, 2000 * 8, false, 8.0 + (9.7 - 8.0) * 0.25)
  end

  def test_infiltration_compartmentalization_test_adjustment
    # Test single-family detached
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.air_infiltration_measurements[0].infiltration_type = HPXML::InfiltrationTypeUnitTotal
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_infiltration_compartmentalization_test_values(default_hpxml_bldg.air_infiltration_measurements[0], nil)

    # Test single-family attached not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-sfa-unit.xml')
    hpxml_bldg.air_infiltration_measurements[0].infiltration_type = HPXML::InfiltrationTypeUnitTotal
    hpxml_bldg.air_infiltration_measurements[0].a_ext = 0.5
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_infiltration_compartmentalization_test_values(default_hpxml_bldg.air_infiltration_measurements[0], 0.5)

    # Test single-family attached defaults
    hpxml_bldg.air_infiltration_measurements[0].a_ext = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_infiltration_compartmentalization_test_values(default_hpxml_bldg.air_infiltration_measurements[0], 0.840)

    hpxml_bldg.attics[0].within_infiltration_volume = true
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_infiltration_compartmentalization_test_values(default_hpxml_bldg.air_infiltration_measurements[0], 0.817)

    # Test multifamily not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit.xml')
    hpxml_bldg.air_infiltration_measurements[0].infiltration_type = HPXML::InfiltrationTypeUnitTotal
    hpxml_bldg.air_infiltration_measurements[0].a_ext = 0.5
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_infiltration_compartmentalization_test_values(default_hpxml_bldg.air_infiltration_measurements[0], 0.5)

    # Test multifamily defaults
    hpxml_bldg.air_infiltration_measurements[0].a_ext = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_infiltration_compartmentalization_test_values(default_hpxml_bldg.air_infiltration_measurements[0], 0.247)
  end

  def test_infiltration_height_and_volume
    # Test conditioned basement
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.building_construction.average_ceiling_height = nil
    hpxml_bldg.building_construction.conditioned_building_volume = nil
    hpxml_bldg.air_infiltration_measurements[0].infiltration_volume = nil
    hpxml_bldg.air_infiltration_measurements[0].infiltration_height = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_in_epsilon(9.75, default_hpxml_bldg.air_infiltration_measurements[0].infiltration_height, 0.01)
    assert_in_epsilon(21600, default_hpxml_bldg.air_infiltration_measurements[0].infiltration_volume, 0.01)

    # Test w/ conditioned basement not within infiltration volume
    hpxml_bldg.foundations[0].within_infiltration_volume = false
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_in_epsilon(8, default_hpxml_bldg.air_infiltration_measurements[0].infiltration_height, 0.01)
    assert_in_epsilon(10800, default_hpxml_bldg.air_infiltration_measurements[0].infiltration_volume, 0.01)

    # Test w/ attic within infiltration volume
    hpxml_bldg.attics[0].within_infiltration_volume = true
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_in_epsilon(16.22, default_hpxml_bldg.air_infiltration_measurements[0].infiltration_height, 0.01)
    assert_in_epsilon(14500, default_hpxml_bldg.air_infiltration_measurements[0].infiltration_volume, 0.01)

    # Test conditioned crawlspace
    hpxml, hpxml_bldg = _create_hpxml('base-foundation-conditioned-crawlspace.xml')
    hpxml_bldg.building_construction.average_ceiling_height = nil
    hpxml_bldg.building_construction.conditioned_building_volume = nil
    hpxml_bldg.air_infiltration_measurements[0].infiltration_volume = nil
    hpxml_bldg.air_infiltration_measurements[0].infiltration_height = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_in_epsilon(9.75, default_hpxml_bldg.air_infiltration_measurements[0].infiltration_height, 0.01)
    assert_in_epsilon(16200, default_hpxml_bldg.air_infiltration_measurements[0].infiltration_volume, 0.01)

    # Test unconditioned basement
    hpxml, hpxml_bldg = _create_hpxml('base-foundation-unconditioned-basement.xml')
    hpxml_bldg.building_construction.average_ceiling_height = nil
    hpxml_bldg.building_construction.conditioned_building_volume = nil
    hpxml_bldg.air_infiltration_measurements[0].infiltration_volume = nil
    hpxml_bldg.air_infiltration_measurements[0].infiltration_height = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_in_epsilon(8, default_hpxml_bldg.air_infiltration_measurements[0].infiltration_height, 0.01)
    assert_in_epsilon(10800, default_hpxml_bldg.air_infiltration_measurements[0].infiltration_volume, 0.01)

    # Test walkout basement
    hpxml, hpxml_bldg = _create_hpxml('base-foundation-walkout-basement.xml')
    hpxml_bldg.building_construction.average_ceiling_height = nil
    hpxml_bldg.building_construction.conditioned_building_volume = nil
    hpxml_bldg.air_infiltration_measurements[0].infiltration_volume = nil
    hpxml_bldg.air_infiltration_measurements[0].infiltration_height = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_in_epsilon(16.5, default_hpxml_bldg.air_infiltration_measurements[0].infiltration_height, 0.01)
    assert_in_epsilon(21600, default_hpxml_bldg.air_infiltration_measurements[0].infiltration_volume, 0.01)

    # Test 2 story building
    hpxml, hpxml_bldg = _create_hpxml('base-enclosure-2stories.xml')
    hpxml_bldg.building_construction.average_ceiling_height = nil
    hpxml_bldg.building_construction.conditioned_building_volume = nil
    hpxml_bldg.air_infiltration_measurements[0].infiltration_volume = nil
    hpxml_bldg.air_infiltration_measurements[0].infiltration_height = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_in_epsilon(18.25, default_hpxml_bldg.air_infiltration_measurements[0].infiltration_height, 0.01)
    assert_in_epsilon(32400, default_hpxml_bldg.air_infiltration_measurements[0].infiltration_volume, 0.01)

    # Test cathedral ceiling
    hpxml, hpxml_bldg = _create_hpxml('base-atticroof-cathedral.xml')
    hpxml_bldg.building_construction.average_ceiling_height = nil
    hpxml_bldg.building_construction.conditioned_building_volume = nil
    hpxml_bldg.air_infiltration_measurements[0].infiltration_volume = nil
    hpxml_bldg.air_infiltration_measurements[0].infiltration_height = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_in_epsilon(11.12, default_hpxml_bldg.air_infiltration_measurements[0].infiltration_height, 0.01)
    assert_in_epsilon(25300, default_hpxml_bldg.air_infiltration_measurements[0].infiltration_volume, 0.01)

    # Test conditioned attic
    hpxml, hpxml_bldg = _create_hpxml('base-atticroof-conditioned.xml')
    hpxml_bldg.building_construction.average_ceiling_height = nil
    hpxml_bldg.building_construction.conditioned_building_volume = nil
    hpxml_bldg.air_infiltration_measurements[0].infiltration_volume = nil
    hpxml_bldg.air_infiltration_measurements[0].infiltration_height = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_in_epsilon(19.37, default_hpxml_bldg.air_infiltration_measurements[0].infiltration_height, 0.01)
    assert_in_epsilon(30816, default_hpxml_bldg.air_infiltration_measurements[0].infiltration_volume, 0.01)
  end

  def test_attics
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-atticroof-vented.xml')
    hpxml_bldg.attics[0].vented_attic_sla = 0.001
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_attic_values(default_hpxml_bldg.attics[0], 0.001)

    # Test defaults
    hpxml_bldg.attics[0].vented_attic_sla = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_attic_values(default_hpxml_bldg.attics[0], 1.0 / 300.0)

    # Test defaults w/o Attic element
    hpxml_bldg.attics[0].delete
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_attic_values(default_hpxml_bldg.attics[0], 1.0 / 300.0)
  end

  def test_foundations
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-foundation-vented-crawlspace.xml')
    hpxml_bldg.foundations[0].vented_crawlspace_sla = 0.001
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_foundation_values(default_hpxml_bldg.foundations[0], 0.001)

    # Test defaults
    hpxml_bldg.foundations[0].vented_crawlspace_sla = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_foundation_values(default_hpxml_bldg.foundations[0], 1.0 / 150.0)

    # Test defaults w/o Foundation element
    hpxml_bldg.foundations[0].delete
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_foundation_values(default_hpxml_bldg.foundations[0], 1.0 / 150.0)
  end

  def test_roofs
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-atticroof-radiant-barrier.xml')
    hpxml_bldg.roofs[0].roof_type = HPXML::RoofTypeMetal
    hpxml_bldg.roofs[0].solar_absorptance = 0.77
    hpxml_bldg.roofs[0].roof_color = HPXML::ColorDark
    hpxml_bldg.roofs[0].emittance = 0.88
    hpxml_bldg.roofs[0].interior_finish_type = HPXML::InteriorFinishPlaster
    hpxml_bldg.roofs[0].interior_finish_thickness = 0.25
    hpxml_bldg.roofs[0].azimuth = 123
    hpxml_bldg.roofs[0].radiant_barrier_grade = 3
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_roof_values(default_hpxml_bldg.roofs[0], HPXML::RoofTypeMetal, 0.77, HPXML::ColorDark, 0.88, true, 3, HPXML::InteriorFinishPlaster, 0.25, 123)

    # Test defaults w/ RoofColor
    hpxml_bldg.roofs[0].roof_type = nil
    hpxml_bldg.roofs[0].solar_absorptance = nil
    hpxml_bldg.roofs[0].roof_color = HPXML::ColorLight
    hpxml_bldg.roofs[0].emittance = nil
    hpxml_bldg.roofs[0].interior_finish_thickness = nil
    hpxml_bldg.roofs[0].orientation = HPXML::OrientationNortheast
    hpxml_bldg.roofs[0].azimuth = nil
    hpxml_bldg.roofs[0].radiant_barrier_grade = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_roof_values(default_hpxml_bldg.roofs[0], HPXML::RoofTypeAsphaltShingles, 0.75, HPXML::ColorLight, 0.90, true, 1, HPXML::InteriorFinishPlaster, 0.5, 45)

    # Test defaults w/ SolarAbsorptance
    hpxml_bldg.roofs[0].solar_absorptance = 0.99
    hpxml_bldg.roofs[0].roof_color = nil
    hpxml_bldg.roofs[0].interior_finish_type = nil
    hpxml_bldg.roofs[0].radiant_barrier = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_roof_values(default_hpxml_bldg.roofs[0], HPXML::RoofTypeAsphaltShingles, 0.99, HPXML::ColorDark, 0.90, false, nil, HPXML::InteriorFinishNotPresent, nil, 45)

    # Test defaults w/o RoofColor & SolarAbsorptance
    hpxml_bldg.roofs[0].solar_absorptance = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_roof_values(default_hpxml_bldg.roofs[0], HPXML::RoofTypeAsphaltShingles, 0.85, HPXML::ColorMedium, 0.90, false, nil, HPXML::InteriorFinishNotPresent, nil, 45)

    # Test defaults w/ conditioned space
    hpxml, hpxml_bldg = _create_hpxml('base-atticroof-cathedral.xml')
    hpxml_bldg.roofs[0].roof_type = nil
    hpxml_bldg.roofs[0].solar_absorptance = nil
    hpxml_bldg.roofs[0].roof_color = HPXML::ColorLight
    hpxml_bldg.roofs[0].emittance = nil
    hpxml_bldg.roofs[0].interior_finish_type = nil
    hpxml_bldg.roofs[0].interior_finish_thickness = nil
    hpxml_bldg.roofs[0].orientation = HPXML::OrientationNortheast
    hpxml_bldg.roofs[0].azimuth = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_roof_values(default_hpxml_bldg.roofs[0], HPXML::RoofTypeAsphaltShingles, 0.75, HPXML::ColorLight, 0.90, nil, nil, HPXML::InteriorFinishGypsumBoard, 0.5, 45)
  end

  def test_rim_joists
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.rim_joists[0].siding = HPXML::SidingTypeBrick
    hpxml_bldg.rim_joists[0].solar_absorptance = 0.55
    hpxml_bldg.rim_joists[0].color = HPXML::ColorLight
    hpxml_bldg.rim_joists[0].emittance = 0.88
    hpxml_bldg.rim_joists[0].azimuth = 123
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_rim_joist_values(default_hpxml_bldg.rim_joists[0], HPXML::SidingTypeBrick, 0.55, HPXML::ColorLight, 0.88, 123)

    # Test defaults w/ Color
    hpxml_bldg.rim_joists[0].siding = nil
    hpxml_bldg.rim_joists[0].solar_absorptance = nil
    hpxml_bldg.rim_joists[0].color = HPXML::ColorDark
    hpxml_bldg.rim_joists[0].emittance = nil
    hpxml_bldg.rim_joists[0].orientation = HPXML::OrientationNorthwest
    hpxml_bldg.rim_joists[0].azimuth = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_rim_joist_values(default_hpxml_bldg.rim_joists[0], HPXML::SidingTypeWood, 0.95, HPXML::ColorDark, 0.90, 315)

    # Test defaults w/ SolarAbsorptance
    hpxml_bldg.rim_joists[0].solar_absorptance = 0.99
    hpxml_bldg.rim_joists[0].color = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_rim_joist_values(default_hpxml_bldg.rim_joists[0], HPXML::SidingTypeWood, 0.99, HPXML::ColorDark, 0.90, 315)

    # Test defaults w/o Color & SolarAbsorptance
    hpxml_bldg.rim_joists[0].solar_absorptance = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_rim_joist_values(default_hpxml_bldg.rim_joists[0], HPXML::SidingTypeWood, 0.7, HPXML::ColorMedium, 0.90, 315)
  end

  def test_walls
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.walls[0].siding = HPXML::SidingTypeFiberCement
    hpxml_bldg.walls[0].solar_absorptance = 0.66
    hpxml_bldg.walls[0].color = HPXML::ColorDark
    hpxml_bldg.walls[0].emittance = 0.88
    hpxml_bldg.walls[0].interior_finish_type = HPXML::InteriorFinishWood
    hpxml_bldg.walls[0].interior_finish_thickness = 0.75
    hpxml_bldg.walls[0].azimuth = 123
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_wall_values(default_hpxml_bldg.walls[0], HPXML::SidingTypeFiberCement, 0.66, HPXML::ColorDark, 0.88, HPXML::InteriorFinishWood, 0.75, 123)

    # Test defaults w/ Color
    hpxml_bldg.walls[0].siding = nil
    hpxml_bldg.walls[0].solar_absorptance = nil
    hpxml_bldg.walls[0].color = HPXML::ColorLight
    hpxml_bldg.walls[0].emittance = nil
    hpxml_bldg.walls[0].interior_finish_type = HPXML::InteriorFinishWood
    hpxml_bldg.walls[0].interior_finish_thickness = nil
    hpxml_bldg.walls[0].orientation = HPXML::OrientationSouth
    hpxml_bldg.walls[0].azimuth = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_wall_values(default_hpxml_bldg.walls[0], HPXML::SidingTypeWood, 0.5, HPXML::ColorLight, 0.90, HPXML::InteriorFinishWood, 0.5, 180)

    # Test defaults w/ SolarAbsorptance
    hpxml_bldg.walls[0].solar_absorptance = 0.99
    hpxml_bldg.walls[0].color = nil
    hpxml_bldg.walls[0].interior_finish_type = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_wall_values(default_hpxml_bldg.walls[0], HPXML::SidingTypeWood, 0.99, HPXML::ColorDark, 0.90, HPXML::InteriorFinishGypsumBoard, 0.5, 180)

    # Test defaults w/o Color & SolarAbsorptance
    hpxml_bldg.walls[0].solar_absorptance = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_wall_values(default_hpxml_bldg.walls[0], HPXML::SidingTypeWood, 0.7, HPXML::ColorMedium, 0.90, HPXML::InteriorFinishGypsumBoard, 0.5, 180)

    # Test defaults w/ unconditioned space
    hpxml_bldg.walls[1].siding = nil
    hpxml_bldg.walls[1].solar_absorptance = nil
    hpxml_bldg.walls[1].color = HPXML::ColorLight
    hpxml_bldg.walls[1].emittance = nil
    hpxml_bldg.walls[1].interior_finish_type = nil
    hpxml_bldg.walls[1].interior_finish_thickness = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_wall_values(default_hpxml_bldg.walls[1], HPXML::SidingTypeWood, 0.5, HPXML::ColorLight, 0.90, HPXML::InteriorFinishNotPresent, nil, nil)
  end

  def test_foundation_walls
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.foundation_walls[0].thickness = 7.0
    hpxml_bldg.foundation_walls[0].interior_finish_type = HPXML::InteriorFinishGypsumCompositeBoard
    hpxml_bldg.foundation_walls[0].interior_finish_thickness = 0.625
    hpxml_bldg.foundation_walls[0].azimuth = 123
    hpxml_bldg.foundation_walls[0].area = 789
    hpxml_bldg.foundation_walls[0].insulation_interior_distance_to_top = 0.5
    hpxml_bldg.foundation_walls[0].insulation_interior_distance_to_bottom = 7.75
    hpxml_bldg.foundation_walls[0].insulation_exterior_distance_to_top = 0.75
    hpxml_bldg.foundation_walls[0].insulation_exterior_distance_to_bottom = 7.5
    hpxml_bldg.foundation_walls[0].type = HPXML::FoundationWallTypeConcreteBlock
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_foundation_wall_values(default_hpxml_bldg.foundation_walls[0], 7.0, HPXML::InteriorFinishGypsumCompositeBoard, 0.625, 123,
                                         789, 0.5, 7.75, 0.75, 7.5, HPXML::FoundationWallTypeConcreteBlock)

    # Test defaults
    hpxml_bldg.foundation_walls[0].thickness = nil
    hpxml_bldg.foundation_walls[0].interior_finish_type = nil
    hpxml_bldg.foundation_walls[0].interior_finish_thickness = nil
    hpxml_bldg.foundation_walls[0].orientation = HPXML::OrientationSoutheast
    hpxml_bldg.foundation_walls[0].azimuth = nil
    hpxml_bldg.foundation_walls[0].area = nil
    hpxml_bldg.foundation_walls[0].length = 100
    hpxml_bldg.foundation_walls[0].insulation_interior_distance_to_bottom = nil
    hpxml_bldg.foundation_walls[0].insulation_exterior_distance_to_bottom = nil
    hpxml_bldg.foundation_walls[0].type = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_foundation_wall_values(default_hpxml_bldg.foundation_walls[0], 8.0, HPXML::InteriorFinishGypsumBoard, 0.5, 135,
                                         800, 0.5, 8.0, 0.75, 8.0, HPXML::FoundationWallTypeSolidConcrete)

    # Test defaults w/ unconditioned surfaces
    hpxml, hpxml_bldg = _create_hpxml('base-foundation-unconditioned-basement.xml')
    hpxml_bldg.foundation_walls[0].thickness = nil
    hpxml_bldg.foundation_walls[0].interior_finish_type = nil
    hpxml_bldg.foundation_walls[0].interior_finish_thickness = nil
    hpxml_bldg.foundation_walls[0].orientation = HPXML::OrientationSoutheast
    hpxml_bldg.foundation_walls[0].azimuth = nil
    hpxml_bldg.foundation_walls[0].area = nil
    hpxml_bldg.foundation_walls[0].length = 100
    hpxml_bldg.foundation_walls[0].height = 10
    hpxml_bldg.foundation_walls[0].insulation_interior_distance_to_top = nil
    hpxml_bldg.foundation_walls[0].insulation_interior_distance_to_bottom = nil
    hpxml_bldg.foundation_walls[0].insulation_exterior_distance_to_top = nil
    hpxml_bldg.foundation_walls[0].insulation_exterior_distance_to_bottom = nil
    hpxml_bldg.foundation_walls[0].type = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_foundation_wall_values(default_hpxml_bldg.foundation_walls[0], 8.0, HPXML::InteriorFinishNotPresent, nil, 135,
                                         1000, 0.0, 10.0, 0.0, 10.0, HPXML::FoundationWallTypeSolidConcrete)
  end

  def test_floors
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.floors[0].interior_finish_type = HPXML::InteriorFinishWood
    hpxml_bldg.floors[0].interior_finish_thickness = 0.375
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_floor_values(default_hpxml_bldg.floors[0], HPXML::InteriorFinishWood, 0.375)

    # Test defaults w/ ceiling
    hpxml_bldg.floors[0].interior_finish_type = nil
    hpxml_bldg.floors[0].interior_finish_thickness = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_floor_values(default_hpxml_bldg.floors[0], HPXML::InteriorFinishGypsumBoard, 0.5)

    # Test defaults w/ floor
    hpxml, hpxml_bldg = _create_hpxml('base-foundation-vented-crawlspace.xml')
    hpxml_bldg.floors[0].interior_finish_type = nil
    hpxml_bldg.floors[0].interior_finish_thickness = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_floor_values(default_hpxml_bldg.floors[0], HPXML::InteriorFinishNotPresent, nil)
  end

  def test_slabs
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.slabs[0].thickness = 7.0
    hpxml_bldg.slabs[0].carpet_r_value = 1.1
    hpxml_bldg.slabs[0].carpet_fraction = 0.5
    hpxml_bldg.slabs[0].depth_below_grade = 2.0
    hpxml_bldg.slabs[0].gap_insulation_r_value = 10.0
    hpxml_bldg.slabs[0].exterior_horizontal_insulation_r_value = 9.9
    hpxml_bldg.slabs[0].exterior_horizontal_insulation_width = 8.8
    hpxml_bldg.slabs[0].exterior_horizontal_insulation_depth_below_grade = 7.7
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_slab_values(default_hpxml_bldg.slabs[0], 7.0, 1.1, 0.5, nil, 10.0, 9.9, 8.8, 7.7)

    # Test defaults w/ conditioned basement
    hpxml_bldg.slabs[0].thickness = nil
    hpxml_bldg.slabs[0].carpet_r_value = nil
    hpxml_bldg.slabs[0].carpet_fraction = nil
    hpxml_bldg.slabs[0].depth_below_grade = nil
    hpxml_bldg.slabs[0].gap_insulation_r_value = nil
    hpxml_bldg.slabs[0].exterior_horizontal_insulation_r_value = nil
    hpxml_bldg.slabs[0].exterior_horizontal_insulation_width = nil
    hpxml_bldg.slabs[0].exterior_horizontal_insulation_depth_below_grade = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_slab_values(default_hpxml_bldg.slabs[0], 4.0, 2.0, 0.8, nil, 0.0, 0.0, 0.0, 0.0)

    # Test defaults w/ crawlspace
    hpxml, hpxml_bldg = _create_hpxml('base-foundation-unvented-crawlspace.xml')
    hpxml_bldg.slabs[0].thickness = nil
    hpxml_bldg.slabs[0].carpet_r_value = nil
    hpxml_bldg.slabs[0].carpet_fraction = nil
    hpxml_bldg.slabs[0].depth_below_grade = nil
    hpxml_bldg.slabs[0].gap_insulation_r_value = nil
    hpxml_bldg.slabs[0].exterior_horizontal_insulation_r_value = nil
    hpxml_bldg.slabs[0].exterior_horizontal_insulation_width = nil
    hpxml_bldg.slabs[0].exterior_horizontal_insulation_depth_below_grade = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_slab_values(default_hpxml_bldg.slabs[0], 0.0, 0.0, 0.0, nil, 0.0, 0.0, 0.0, 0.0)

    # Test defaults w/ slab-on-grade
    hpxml, hpxml_bldg = _create_hpxml('base-foundation-slab.xml')
    hpxml_bldg.slabs[0].thickness = nil
    hpxml_bldg.slabs[0].carpet_r_value = nil
    hpxml_bldg.slabs[0].carpet_fraction = nil
    hpxml_bldg.slabs[0].depth_below_grade = nil
    hpxml_bldg.slabs[0].gap_insulation_r_value = nil
    hpxml_bldg.slabs[0].exterior_horizontal_insulation_r_value = nil
    hpxml_bldg.slabs[0].exterior_horizontal_insulation_width = nil
    hpxml_bldg.slabs[0].exterior_horizontal_insulation_depth_below_grade = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_slab_values(default_hpxml_bldg.slabs[0], 4.0, 2.0, 0.8, 0.0, 5.0, 0.0, 0.0, 0.0)
  end

  def test_windows
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-enclosure-windows-shading-factors.xml')
    hpxml_bldg.windows[0].fraction_operable = 0.5
    hpxml_bldg.windows[0].exterior_shading_factor_summer = 0.44
    hpxml_bldg.windows[0].exterior_shading_factor_winter = 0.55
    hpxml_bldg.windows[0].interior_shading_factor_summer = 0.66
    hpxml_bldg.windows[0].interior_shading_factor_winter = 0.77
    hpxml_bldg.windows[0].azimuth = 123
    hpxml_bldg.windows[0].insect_screen_present = true
    hpxml_bldg.windows[0].insect_screen_location = HPXML::LocationInterior
    hpxml_bldg.windows[0].insect_screen_coverage_summer = 0.19
    hpxml_bldg.windows[0].insect_screen_coverage_winter = 0.28
    hpxml_bldg.windows[0].insect_screen_factor_summer = 0.37
    hpxml_bldg.windows[0].insect_screen_factor_winter = 0.46
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_window_values(default_hpxml_bldg.windows[0], 0.44, 0.55, 0.66, 0.77, 0.5, 123, HPXML::LocationInterior, 0.19, 0.28, 0.37, 0.46)

    # Test defaults w/ 301-2022 Addendum C
    hpxml_bldg.windows[0].fraction_operable = nil
    hpxml_bldg.windows[0].exterior_shading_factor_summer = nil
    hpxml_bldg.windows[0].exterior_shading_factor_winter = nil
    hpxml_bldg.windows[0].interior_shading_factor_summer = nil
    hpxml_bldg.windows[0].interior_shading_factor_winter = nil
    hpxml_bldg.windows[0].orientation = HPXML::OrientationSouthwest
    hpxml_bldg.windows[0].azimuth = nil
    hpxml_bldg.windows[0].insect_screen_location = nil
    hpxml_bldg.windows[0].insect_screen_coverage_summer = nil
    hpxml_bldg.windows[0].insect_screen_coverage_winter = nil
    hpxml_bldg.windows[0].insect_screen_factor_summer = nil
    hpxml_bldg.windows[0].insect_screen_factor_winter = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_window_values(default_hpxml_bldg.windows[0], 1.0, 1.0, 0.8276, 0.8276, 0.67, 225, HPXML::LocationExterior, 0.67, 0.67, 0.7588, 0.7588)
  end

  def test_windows_physical_properties
    # Test defaults w/ single pane, aluminum frame
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.windows[0].ufactor = nil
    hpxml_bldg.windows[0].shgc = nil
    hpxml_bldg.windows[0].frame_type = HPXML::WindowFrameTypeAluminum
    hpxml_bldg.windows[0].glass_layers = HPXML::WindowLayersSinglePane
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()

    assert_equal(false, default_hpxml_bldg.windows[0].thermal_break)
    assert_equal(HPXML::WindowGlassTypeClear, default_hpxml_bldg.windows[0].glass_type)
    assert_nil(default_hpxml_bldg.windows[0].gas_fill)

    # Test defaults w/ double pane, metal frame
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.windows[0].ufactor = nil
    hpxml_bldg.windows[0].shgc = nil
    hpxml_bldg.windows[0].frame_type = HPXML::WindowFrameTypeMetal
    hpxml_bldg.windows[0].glass_layers = HPXML::WindowLayersDoublePane
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()

    assert_equal(true, default_hpxml_bldg.windows[0].thermal_break)
    assert_equal(HPXML::WindowGlassTypeClear, default_hpxml_bldg.windows[0].glass_type)
    assert_equal(HPXML::WindowGasAir, default_hpxml_bldg.windows[0].gas_fill)

    # Test defaults w/ single pane, wood frame
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.windows[0].ufactor = nil
    hpxml_bldg.windows[0].shgc = nil
    hpxml_bldg.windows[0].frame_type = HPXML::WindowFrameTypeWood
    hpxml_bldg.windows[0].glass_layers = HPXML::WindowLayersTriplePane
    hpxml_bldg.windows[0].glass_type = HPXML::WindowGlassTypeLowE
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()

    assert_nil(default_hpxml_bldg.windows[0].thermal_break)
    assert_equal(HPXML::WindowGlassTypeLowE, default_hpxml_bldg.windows[0].glass_type)
    assert_equal(HPXML::WindowGasArgon, default_hpxml_bldg.windows[0].gas_fill)

    # Test defaults w/ glass block
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.windows[0].ufactor = nil
    hpxml_bldg.windows[0].shgc = nil
    hpxml_bldg.windows[0].glass_layers = HPXML::WindowLayersGlassBlock
    hpxml_bldg.windows[0].interior_shading_factor_summer = nil
    hpxml_bldg.windows[0].interior_shading_factor_winter = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_nil(default_hpxml_bldg.windows[0].thermal_break)
    assert_nil(default_hpxml_bldg.windows[0].glass_type)
    assert_nil(default_hpxml_bldg.windows[0].gas_fill)

    # Test defaults w/ glass block and interior shading type
    hpxml_bldg.windows[0].interior_shading_type = HPXML::InteriorShadingTypeDarkShades
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_nil(default_hpxml_bldg.windows[0].thermal_break)
    assert_nil(default_hpxml_bldg.windows[0].glass_type)
    assert_nil(default_hpxml_bldg.windows[0].gas_fill)

    # Test U/SHGC lookups [frame_type, thermal_break, glass_layers, glass_type, gas_fill] => [ufactor, shgc]
    tests = { [HPXML::WindowFrameTypeAluminum, false, HPXML::WindowLayersSinglePane, nil, nil] => [1.27, 0.75],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersSinglePane, HPXML::WindowGlassTypeReflective, nil] => [0.89, 0.64],
              [HPXML::WindowFrameTypeAluminum, false, HPXML::WindowLayersSinglePane, HPXML::WindowGlassTypeTintedReflective, nil] => [1.27, 0.64],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersSinglePane, HPXML::WindowGlassTypeTintedReflective, nil] => [0.89, 0.54],
              [HPXML::WindowFrameTypeAluminum, false, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeClear, HPXML::WindowGasAir] => [0.81, 0.67],
              [HPXML::WindowFrameTypeAluminum, true, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeClear, HPXML::WindowGasAir] => [0.60, 0.67],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeClear, HPXML::WindowGasAir] => [0.51, 0.56],
              [HPXML::WindowFrameTypeAluminum, false, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeTintedReflective, HPXML::WindowGasAir] => [0.81, 0.55],
              [HPXML::WindowFrameTypeAluminum, true, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeTintedReflective, HPXML::WindowGasAir] => [0.60, 0.55],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeTintedReflective, HPXML::WindowGasAir] => [0.51, 0.46],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeLowE, HPXML::WindowGasAir] => [0.42, 0.52],
              [HPXML::WindowFrameTypeAluminum, true, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeLowE, HPXML::WindowGasArgon] => [0.47, 0.62],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeLowEHighSolarGain, HPXML::WindowGasArgon] => [0.39, 0.52],
              [HPXML::WindowFrameTypeAluminum, false, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeLowELowSolarGain, HPXML::WindowGasAir] => [0.67, 0.37],
              [HPXML::WindowFrameTypeAluminum, true, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeLowELowSolarGain, HPXML::WindowGasAir] => [0.47, 0.37],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeLowELowSolarGain, HPXML::WindowGasAir] => [0.39, 0.31],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeLowELowSolarGain, HPXML::WindowGasArgon] => [0.36, 0.31],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersTriplePane, HPXML::WindowGlassTypeLowE, HPXML::WindowGasArgon] => [0.27, 0.31],
              [nil, nil, HPXML::WindowLayersGlassBlock, nil, nil] => [0.60, 0.60] }
    tests.each do |k, v|
      frame_type, thermal_break, glass_layers, glass_type, gas_fill = k
      ufactor, shgc = v

      hpxml, hpxml_bldg = _create_hpxml('base.xml')
      hpxml_bldg.windows[0].ufactor = nil
      hpxml_bldg.windows[0].shgc = nil
      hpxml_bldg.windows[0].frame_type = frame_type
      hpxml_bldg.windows[0].thermal_break = thermal_break
      hpxml_bldg.windows[0].glass_layers = glass_layers
      hpxml_bldg.windows[0].glass_type = glass_type
      hpxml_bldg.windows[0].gas_fill = gas_fill
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      _default_hpxml, default_hpxml_bldg = _test_measure()

      assert_equal(ufactor, default_hpxml_bldg.windows[0].ufactor)
      assert_equal(shgc, default_hpxml_bldg.windows[0].shgc)
    end
  end

  def test_windows_interior_shading_types
    # Test defaults
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.windows[0].interior_shading_type = nil
    hpxml_bldg.windows[0].interior_shading_factor_summer = nil
    hpxml_bldg.windows[0].interior_shading_factor_winter = nil
    hpxml_bldg.windows[0].interior_shading_coverage_summer = nil
    hpxml_bldg.windows[0].interior_shading_coverage_winter = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()

    assert_equal(HPXML::InteriorShadingTypeLightCurtains, default_hpxml_bldg.windows[0].interior_shading_type)
    assert_equal(0.5, default_hpxml_bldg.windows[0].interior_shading_coverage_summer)
    assert_equal(0.5, default_hpxml_bldg.windows[0].interior_shading_coverage_winter)
    assert_equal(0.8276, default_hpxml_bldg.windows[0].interior_shading_factor_summer)
    assert_equal(0.8276, default_hpxml_bldg.windows[0].interior_shading_factor_winter)

    # Test defaults w/ none shading
    hpxml_bldg.windows[0].interior_shading_type = HPXML::InteriorShadingTypeNotPresent
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()

    assert_nil(default_hpxml_bldg.windows[0].interior_shading_coverage_summer)
    assert_nil(default_hpxml_bldg.windows[0].interior_shading_coverage_winter)
    assert_equal(1.0, default_hpxml_bldg.windows[0].interior_shading_factor_summer)
    assert_equal(1.0, default_hpxml_bldg.windows[0].interior_shading_factor_winter)

    # Test defaults w/ other shading
    hpxml_bldg.windows[0].interior_shading_type = HPXML::InteriorShadingTypeOther
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()

    assert_equal(0.5, default_hpxml_bldg.windows[0].interior_shading_coverage_summer)
    assert_equal(0.5, default_hpxml_bldg.windows[0].interior_shading_coverage_winter)
    assert_equal(0.75, default_hpxml_bldg.windows[0].interior_shading_factor_summer)
    assert_equal(0.75, default_hpxml_bldg.windows[0].interior_shading_factor_winter)

    # Test defaults w/ dark shades (fully covered summer, fully uncovered winter)
    hpxml_bldg.windows[0].interior_shading_type = HPXML::InteriorShadingTypeDarkShades
    hpxml_bldg.windows[0].interior_shading_coverage_summer = 1.0
    hpxml_bldg.windows[0].interior_shading_coverage_winter = 0.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()

    assert_equal(0.8348, default_hpxml_bldg.windows[0].interior_shading_factor_summer)
    assert_equal(1.0, default_hpxml_bldg.windows[0].interior_shading_factor_winter)

    # Test defaults w/ medium blinds (closed fully covered summer, half open half covered winter)
    hpxml_bldg.windows[0].interior_shading_type = HPXML::InteriorShadingTypeMediumBlinds
    hpxml_bldg.windows[0].interior_shading_blinds_summer_closed_or_open = HPXML::BlindsClosed
    hpxml_bldg.windows[0].interior_shading_coverage_winter = 0.5
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()

    assert_equal(HPXML::BlindsHalfOpen, default_hpxml_bldg.windows[0].interior_shading_blinds_winter_closed_or_open)
    assert_equal(1.0, default_hpxml_bldg.windows[0].interior_shading_coverage_summer)
    assert_equal(0.7196, default_hpxml_bldg.windows[0].interior_shading_factor_summer)
    assert_equal(0.9178, default_hpxml_bldg.windows[0].interior_shading_factor_winter)
  end

  def test_windows_exterior_shading_types
    # Test defaults
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.windows[0].exterior_shading_type = nil
    hpxml_bldg.windows[0].exterior_shading_factor_summer = nil
    hpxml_bldg.windows[0].exterior_shading_factor_winter = nil
    hpxml_bldg.windows[0].exterior_shading_coverage_summer = nil
    hpxml_bldg.windows[0].exterior_shading_coverage_winter = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()

    assert_equal(HPXML::InteriorShadingTypeNotPresent, default_hpxml_bldg.windows[0].exterior_shading_type)
    assert_nil(default_hpxml_bldg.windows[0].exterior_shading_coverage_summer)
    assert_nil(default_hpxml_bldg.windows[0].exterior_shading_coverage_winter)
    assert_equal(1.0, default_hpxml_bldg.windows[0].exterior_shading_factor_summer)
    assert_equal(1.0, default_hpxml_bldg.windows[0].exterior_shading_factor_winter)

    # Test defaults w/ none shading
    hpxml_bldg.windows[0].exterior_shading_type = HPXML::ExteriorShadingTypeNotPresent
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()

    assert_nil(default_hpxml_bldg.windows[0].exterior_shading_coverage_summer)
    assert_nil(default_hpxml_bldg.windows[0].exterior_shading_coverage_winter)
    assert_equal(1.0, default_hpxml_bldg.windows[0].exterior_shading_factor_summer)
    assert_equal(1.0, default_hpxml_bldg.windows[0].exterior_shading_factor_winter)

    # Test defaults w/ other shading
    hpxml_bldg.windows[0].exterior_shading_type = HPXML::ExteriorShadingTypeOther
    hpxml_bldg.windows[0].exterior_shading_coverage_summer = 0.25
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()

    assert_equal(0.25, default_hpxml_bldg.windows[0].exterior_shading_coverage_summer)
    assert_equal(0.5, default_hpxml_bldg.windows[0].exterior_shading_coverage_winter)
    assert_equal(0.875, default_hpxml_bldg.windows[0].exterior_shading_factor_summer)
    assert_equal(0.75, default_hpxml_bldg.windows[0].exterior_shading_factor_winter)

    # Test defaults w/ deciduous tree shading
    hpxml_bldg.windows[0].exterior_shading_type = HPXML::ExteriorShadingTypeDeciduousTree
    hpxml_bldg.windows[0].exterior_shading_coverage_summer = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()

    assert_equal(0.5, default_hpxml_bldg.windows[0].exterior_shading_factor_summer)
    assert_equal(0.75, default_hpxml_bldg.windows[0].exterior_shading_factor_winter)

    # Test defaults w/ overhangs not explicitly defined
    hpxml_bldg.windows[0].exterior_shading_type = HPXML::ExteriorShadingTypeExternalOverhangs
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()

    assert_equal(0.0, default_hpxml_bldg.windows[0].exterior_shading_factor_summer)
    assert_equal(0.0, default_hpxml_bldg.windows[0].exterior_shading_factor_winter)

    # Test defaults w/ overhangs explicitly defined
    hpxml_bldg.windows[0].overhangs_depth = 2.0
    hpxml_bldg.windows[0].overhangs_distance_to_top_of_window = 1.0
    hpxml_bldg.windows[0].overhangs_distance_to_bottom_of_window = 4.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()

    assert_nil(default_hpxml_bldg.windows[0].exterior_shading_factor_summer)
    assert_nil(default_hpxml_bldg.windows[0].exterior_shading_factor_winter)

    # Test defaults w/ neighbor buildings not explicitly defined
    hpxml_bldg.windows[0].exterior_shading_type = HPXML::ExteriorShadingTypeBuilding
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()

    assert_equal(0.5, default_hpxml_bldg.windows[0].exterior_shading_factor_summer)
    assert_equal(0.5, default_hpxml_bldg.windows[0].exterior_shading_factor_winter)

    # Test defaults w/ neighbor buildings explicitly defined
    hpxml_bldg.neighbor_buildings.add(azimuth: 0,
                                      distance: 10)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()

    assert_nil(default_hpxml_bldg.windows[0].exterior_shading_factor_summer)
    assert_nil(default_hpxml_bldg.windows[0].exterior_shading_factor_winter)
  end

  def test_skylights
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-enclosure-skylights.xml')
    hpxml_bldg.skylights[0].exterior_shading_factor_summer = 0.44
    hpxml_bldg.skylights[0].exterior_shading_factor_winter = 0.55
    hpxml_bldg.skylights[0].interior_shading_factor_summer = 0.66
    hpxml_bldg.skylights[0].interior_shading_factor_winter = 0.77
    hpxml_bldg.skylights[0].azimuth = 123
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_skylight_values(default_hpxml_bldg.skylights[0], 0.44, 0.55, 0.66, 0.77, 123)

    # Test defaults
    hpxml_bldg.skylights[0].exterior_shading_factor_summer = nil
    hpxml_bldg.skylights[0].exterior_shading_factor_winter = nil
    hpxml_bldg.skylights[0].interior_shading_factor_summer = nil
    hpxml_bldg.skylights[0].interior_shading_factor_winter = nil
    hpxml_bldg.skylights[0].orientation = HPXML::OrientationWest
    hpxml_bldg.skylights[0].azimuth = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_skylight_values(default_hpxml_bldg.skylights[0], 1.0, 1.0, 1.0, 1.0, 270)
  end

  def test_skylights_physical_properties
    # Test defaults w/ single pane, aluminum frame
    hpxml, hpxml_bldg = _create_hpxml('base-enclosure-skylights.xml')
    hpxml_bldg.skylights[0].ufactor = nil
    hpxml_bldg.skylights[0].shgc = nil
    hpxml_bldg.skylights[0].frame_type = HPXML::WindowFrameTypeAluminum
    hpxml_bldg.skylights[0].glass_layers = HPXML::WindowLayersSinglePane
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    default_hpxml, default_hpxml_bldg = _test_measure()

    assert_equal(false, default_hpxml_bldg.skylights[0].thermal_break)
    assert_equal(HPXML::WindowGlassTypeClear, default_hpxml_bldg.skylights[0].glass_type)
    assert_nil(default_hpxml_bldg.skylights[0].gas_fill)

    # Test defaults w/ double pane, metal frame
    hpxml, hpxml_bldg = _create_hpxml('base-enclosure-skylights.xml')
    hpxml_bldg.skylights[0].ufactor = nil
    hpxml_bldg.skylights[0].shgc = nil
    hpxml_bldg.skylights[0].frame_type = HPXML::WindowFrameTypeMetal
    hpxml_bldg.skylights[0].glass_layers = HPXML::WindowLayersDoublePane
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    default_hpxml, default_hpxml_bldg = _test_measure()

    assert_equal(true, default_hpxml_bldg.skylights[0].thermal_break)
    assert_equal(HPXML::WindowGlassTypeClear, default_hpxml_bldg.skylights[0].glass_type)
    assert_equal(HPXML::WindowGasAir, default_hpxml_bldg.skylights[0].gas_fill)

    # Test defaults w/ single pane, wood frame
    hpxml, hpxml_bldg = _create_hpxml('base-enclosure-skylights.xml')
    hpxml_bldg.skylights[0].ufactor = nil
    hpxml_bldg.skylights[0].shgc = nil
    hpxml_bldg.skylights[0].frame_type = HPXML::WindowFrameTypeWood
    hpxml_bldg.skylights[0].glass_layers = HPXML::WindowLayersTriplePane
    hpxml_bldg.skylights[0].glass_type = HPXML::WindowGlassTypeLowE
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    default_hpxml, default_hpxml_bldg = _test_measure()

    assert_nil(default_hpxml_bldg.skylights[0].thermal_break)
    assert_equal(HPXML::WindowGlassTypeLowE, default_hpxml_bldg.skylights[0].glass_type)
    assert_equal(HPXML::WindowGasArgon, default_hpxml_bldg.skylights[0].gas_fill)

    # Test defaults w/ glass block
    hpxml, hpxml_bldg = _create_hpxml('base-enclosure-skylights.xml')
    hpxml_bldg.skylights[0].ufactor = nil
    hpxml_bldg.skylights[0].shgc = nil
    hpxml_bldg.skylights[0].glass_layers = HPXML::WindowLayersGlassBlock
    hpxml_bldg.skylights[0].interior_shading_factor_summer = nil
    hpxml_bldg.skylights[0].interior_shading_factor_winter = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_nil(default_hpxml_bldg.skylights[0].thermal_break)
    assert_nil(default_hpxml_bldg.skylights[0].glass_type)
    assert_nil(default_hpxml_bldg.skylights[0].gas_fill)

    # Test defaults w/ glass block and interior shading type
    hpxml_bldg.skylights[0].interior_shading_type = HPXML::InteriorShadingTypeDarkShades
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_nil(default_hpxml_bldg.skylights[0].thermal_break)
    assert_nil(default_hpxml_bldg.skylights[0].glass_type)
    assert_nil(default_hpxml_bldg.skylights[0].gas_fill)

    # Test U/SHGC lookups [frame_type, thermal_break, glass_layers, glass_type, gas_fill] => [ufactor, shgc]
    tests = { [HPXML::WindowFrameTypeAluminum, false, HPXML::WindowLayersSinglePane, nil, nil] => [1.98, 0.75],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersSinglePane, HPXML::WindowGlassTypeReflective, nil] => [1.47, 0.64],
              [HPXML::WindowFrameTypeAluminum, false, HPXML::WindowLayersSinglePane, HPXML::WindowGlassTypeTintedReflective, nil] => [1.98, 0.64],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersSinglePane, HPXML::WindowGlassTypeTintedReflective, nil] => [1.47, 0.54],
              [HPXML::WindowFrameTypeAluminum, false, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeClear, HPXML::WindowGasAir] => [1.30, 0.67],
              [HPXML::WindowFrameTypeAluminum, true, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeClear, HPXML::WindowGasAir] => [1.10, 0.67],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeClear, HPXML::WindowGasAir] => [0.84, 0.56],
              [HPXML::WindowFrameTypeAluminum, false, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeTintedReflective, HPXML::WindowGasAir] => [1.30, 0.55],
              [HPXML::WindowFrameTypeAluminum, true, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeTintedReflective, HPXML::WindowGasAir] => [1.10, 0.55],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeTintedReflective, HPXML::WindowGasAir] => [0.84, 0.46],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeLowE, HPXML::WindowGasAir] => [0.74, 0.52],
              [HPXML::WindowFrameTypeAluminum, true, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeLowE, HPXML::WindowGasArgon] => [0.95, 0.62],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeLowEHighSolarGain, HPXML::WindowGasArgon] => [0.68, 0.52],
              [HPXML::WindowFrameTypeAluminum, false, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeLowELowSolarGain, HPXML::WindowGasAir] => [1.17, 0.37],
              [HPXML::WindowFrameTypeAluminum, true, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeLowELowSolarGain, HPXML::WindowGasAir] => [0.98, 0.37],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeLowELowSolarGain, HPXML::WindowGasAir] => [0.71, 0.31],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeLowELowSolarGain, HPXML::WindowGasArgon] => [0.65, 0.31],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersTriplePane, HPXML::WindowGlassTypeLowE, HPXML::WindowGasArgon] => [0.47, 0.31],
              [nil, nil, HPXML::WindowLayersGlassBlock, nil, nil] => [0.60, 0.60] }
    tests.each do |k, v|
      frame_type, thermal_break, glass_layers, glass_type, gas_fill = k
      ufactor, shgc = v

      hpxml, hpxml_bldg = _create_hpxml('base-enclosure-skylights.xml')
      hpxml_bldg.skylights[0].ufactor = nil
      hpxml_bldg.skylights[0].shgc = nil
      hpxml_bldg.skylights[0].frame_type = frame_type
      hpxml_bldg.skylights[0].thermal_break = thermal_break
      hpxml_bldg.skylights[0].glass_layers = glass_layers
      hpxml_bldg.skylights[0].glass_type = glass_type
      hpxml_bldg.skylights[0].gas_fill = gas_fill
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      default_hpxml, default_hpxml_bldg = _test_measure()

      assert_equal(ufactor, default_hpxml_bldg.skylights[0].ufactor)
      assert_equal(shgc, default_hpxml_bldg.skylights[0].shgc)
    end
  end

  def test_doors
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.doors.each_with_index do |door, i|
      door.azimuth = 35 * (i + 1)
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_door_values(default_hpxml_bldg, [35, 70])

    # Test defaults w/ AttachedToWall azimuth
    hpxml_bldg.walls[0].azimuth = 89
    hpxml_bldg.doors.each do |door|
      door.azimuth = nil
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_door_values(default_hpxml_bldg, [89, 89])

    # Test defaults w/o AttachedToWall azimuth
    hpxml_bldg.walls[0].azimuth = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_door_values(default_hpxml_bldg, [0, 0])

    # Test defaults w/ Orientation
    hpxml_bldg.doors.each do |door|
      door.orientation = HPXML::OrientationEast
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_door_values(default_hpxml_bldg, [90, 90])
  end

  def test_thermal_mass
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-enclosure-thermal-mass.xml')
    hpxml_bldg.partition_wall_mass.area_fraction = 0.5
    hpxml_bldg.partition_wall_mass.interior_finish_thickness = 0.75
    hpxml_bldg.partition_wall_mass.interior_finish_type = HPXML::InteriorFinishWood
    hpxml_bldg.furniture_mass.area_fraction = 0.75
    hpxml_bldg.furniture_mass.type = HPXML::FurnitureMassTypeHeavyWeight
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_partition_wall_mass_values(default_hpxml_bldg.partition_wall_mass, 0.5, HPXML::InteriorFinishWood, 0.75)
    _test_default_furniture_mass_values(default_hpxml_bldg.furniture_mass, 0.75, HPXML::FurnitureMassTypeHeavyWeight)

    # Test defaults
    hpxml_bldg.partition_wall_mass.area_fraction = nil
    hpxml_bldg.partition_wall_mass.interior_finish_thickness = nil
    hpxml_bldg.partition_wall_mass.interior_finish_type = nil
    hpxml_bldg.furniture_mass.area_fraction = nil
    hpxml_bldg.furniture_mass.type = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_partition_wall_mass_values(default_hpxml_bldg.partition_wall_mass, 1.0, HPXML::InteriorFinishGypsumBoard, 0.5)
    _test_default_furniture_mass_values(default_hpxml_bldg.furniture_mass, 0.4, HPXML::FurnitureMassTypeLightWeight)
  end

  def test_central_air_conditioners
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-central-ac-only-1-speed.xml')
    hpxml_bldg.cooling_systems[0].fan_watts_per_cfm = 0.66
    hpxml_bldg.cooling_systems[0].fan_motor_type = HPXML::HVACFanMotorTypeBPM
    hpxml_bldg.cooling_systems[0].charge_defect_ratio = -0.11
    hpxml_bldg.cooling_systems[0].airflow_defect_ratio = -0.22
    hpxml_bldg.cooling_systems[0].cooling_capacity = 12345
    hpxml_bldg.cooling_systems[0].cooling_efficiency_seer = nil
    hpxml_bldg.cooling_systems[0].cooling_efficiency_seer2 = 11.4
    hpxml_bldg.cooling_systems[0].cooling_efficiency_eer2 = 11.0
    hpxml_bldg.cooling_systems[0].crankcase_heater_watts = 40.0
    hpxml_bldg.cooling_systems[0].equipment_type = HPXML::HVACEquipmentTypeSpaceConstrained
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_central_air_conditioner_values(default_hpxml_bldg.cooling_systems[0], 0.66, HPXML::HVACFanMotorTypeBPM, nil, -0.11, -0.22, 12345, 11.4, 11.0, 40.0, 1.0, HPXML::HVACEquipmentTypeSpaceConstrained)

    # Test defaults - SEER/EER
    hpxml_bldg.cooling_systems[0].cooling_efficiency_seer2 = nil
    hpxml_bldg.cooling_systems[0].cooling_efficiency_seer = 12.0
    hpxml_bldg.cooling_systems[0].cooling_efficiency_eer2 = nil
    hpxml_bldg.cooling_systems[0].cooling_efficiency_eer = 11.58
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_central_air_conditioner_values(default_hpxml_bldg.cooling_systems[0], 0.66, HPXML::HVACFanMotorTypeBPM, nil, -0.11, -0.22, 12345, 11.64, 11.23, 40.0, 1.0, HPXML::HVACEquipmentTypeSpaceConstrained)

    # Test autosizing with factors
    hpxml_bldg.cooling_systems[0].cooling_capacity = nil
    hpxml_bldg.cooling_systems[0].cooling_autosizing_factor = 1.2
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_central_air_conditioner_values(default_hpxml_bldg.cooling_systems[0], 0.66, HPXML::HVACFanMotorTypeBPM, nil, -0.11, -0.22, nil, 11.64, 11.23, 40.0, 1.2, HPXML::HVACEquipmentTypeSpaceConstrained)

    # Test watts/cfm based on attached heating system
    hpxml_bldg.cooling_systems[0].fan_watts_per_cfm = nil
    hpxml_bldg.heating_systems.add(id: 'HeatingSystem1',
                                   distribution_system_idref: hpxml_bldg.hvac_distributions[0].id,
                                   heating_system_type: HPXML::HVACTypeFurnace,
                                   heating_system_fuel: HPXML::FuelTypeElectricity,
                                   heating_efficiency_afue: 1,
                                   fraction_heat_load_served: 1.0,
                                   fan_watts_per_cfm: 0.55,
                                   fan_motor_type: HPXML::HVACFanMotorTypeBPM)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_central_air_conditioner_values(default_hpxml_bldg.cooling_systems[0], 0.55, HPXML::HVACFanMotorTypeBPM, nil, -0.11, -0.22, nil, 11.64, 11.23, 40.0, 1.2, HPXML::HVACEquipmentTypeSpaceConstrained)

    # Test watts/cfm based on fan model type
    hpxml_bldg.heating_systems[0].delete
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_central_air_conditioner_values(default_hpxml_bldg.cooling_systems[0], 0.375, HPXML::HVACFanMotorTypeBPM, nil, -0.11, -0.22, nil, 11.64, 11.23, 40.0, 1.2, HPXML::HVACEquipmentTypeSpaceConstrained)

    # Test fan model type based on compressor type
    hpxml_bldg.cooling_systems[0].fan_watts_per_cfm = 0.3
    hpxml_bldg.cooling_systems[0].fan_motor_type = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_central_air_conditioner_values(default_hpxml_bldg.cooling_systems[0], 0.3, HPXML::HVACFanMotorTypePSC, nil, -0.11, -0.22, nil, 11.64, 11.23, 40.0, 1.2, HPXML::HVACEquipmentTypeSpaceConstrained)

    # Test defaults
    hpxml_bldg.cooling_systems[0].fan_watts_per_cfm = nil
    hpxml_bldg.cooling_systems[0].fan_motor_type = nil
    hpxml_bldg.cooling_systems[0].charge_defect_ratio = nil
    hpxml_bldg.cooling_systems[0].airflow_defect_ratio = nil
    hpxml_bldg.cooling_systems[0].cooling_capacity = nil
    hpxml_bldg.cooling_systems[0].cooling_autosizing_factor = nil
    hpxml_bldg.cooling_systems[0].cooling_autosizing_limit = nil
    hpxml_bldg.cooling_systems[0].crankcase_heater_watts = nil
    hpxml_bldg.cooling_systems[0].cooling_efficiency_eer = nil
    hpxml_bldg.cooling_systems[0].equipment_type = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_central_air_conditioner_values(default_hpxml_bldg.cooling_systems[0], 0.5, HPXML::HVACFanMotorTypePSC, nil, 0, 0, nil, 11.4, 9.79, 28.7, 1.0, HPXML::HVACEquipmentTypeSplit)
  end

  def test_room_air_conditioners
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-room-ac-only.xml')
    hpxml_bldg.cooling_systems[0].cooling_capacity = 12345
    hpxml_bldg.cooling_systems[0].crankcase_heater_watts = 40.0
    hpxml_bldg.cooling_systems[0].cooling_efficiency_eer = nil
    hpxml_bldg.cooling_systems[0].cooling_efficiency_ceer = 10.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_nil(default_hpxml_bldg.cooling_systems[0].fan_motor_type)
    assert_nil(default_hpxml_bldg.cooling_systems[0].fan_watts_per_cfm)
    _test_default_room_air_conditioner_ptac_values(default_hpxml_bldg.cooling_systems[0], nil, 12345, 40.0, 1.0, 10.0)

    # Test autosizing with factors
    hpxml_bldg.cooling_systems[0].cooling_capacity = nil
    hpxml_bldg.cooling_systems[0].cooling_autosizing_factor = 1.2
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_room_air_conditioner_ptac_values(default_hpxml_bldg.cooling_systems[0], nil, nil, 40.0, 1.2, 10.0)

    # Test defaults
    hpxml_bldg.cooling_systems[0].cooling_capacity = nil
    hpxml_bldg.cooling_systems[0].crankcase_heater_watts = nil
    hpxml_bldg.cooling_systems[0].cooling_autosizing_factor = nil
    hpxml_bldg.cooling_systems[0].cooling_autosizing_limit = nil
    hpxml_bldg.cooling_systems[0].cooling_efficiency_eer = 8.5
    hpxml_bldg.cooling_systems[0].cooling_efficiency_ceer = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_nil(default_hpxml_bldg.cooling_systems[0].fan_motor_type)
    assert_nil(default_hpxml_bldg.cooling_systems[0].fan_watts_per_cfm)
    _test_default_room_air_conditioner_ptac_values(default_hpxml_bldg.cooling_systems[0], nil, nil, 0.0, 1.0, 8.42)
  end

  def test_evaporative_coolers
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-evap-cooler-only.xml')
    hpxml_bldg.cooling_systems[0].cooling_capacity = 12345
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_nil(default_hpxml_bldg.cooling_systems[0].fan_motor_type)
    assert_nil(default_hpxml_bldg.cooling_systems[0].fan_watts_per_cfm)
    _test_default_evap_cooler_values(default_hpxml_bldg.cooling_systems[0], nil, 12345, 1.0)

    # Test autosizing with factors
    hpxml_bldg.cooling_systems[0].cooling_capacity = nil
    hpxml_bldg.cooling_systems[0].cooling_autosizing_factor = 1.2
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_evap_cooler_values(default_hpxml_bldg.cooling_systems[0], nil, nil, 1.2)

    # Test defaults
    hpxml_bldg.cooling_systems[0].cooling_capacity = nil
    hpxml_bldg.cooling_systems[0].cooling_autosizing_factor = nil
    hpxml_bldg.cooling_systems[0].cooling_autosizing_limit = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_nil(default_hpxml_bldg.cooling_systems[0].fan_motor_type)
    assert_nil(default_hpxml_bldg.cooling_systems[0].fan_watts_per_cfm)
    _test_default_evap_cooler_values(default_hpxml_bldg.cooling_systems[0], nil, nil, 1.0)
  end

  def test_mini_split_air_conditioners
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-mini-split-air-conditioner-only-ducted.xml')
    hpxml_bldg.cooling_systems[0].fan_watts_per_cfm = 0.66
    hpxml_bldg.cooling_systems[0].fan_motor_type = HPXML::HVACFanMotorTypeBPM
    hpxml_bldg.cooling_systems[0].charge_defect_ratio = -0.11
    hpxml_bldg.cooling_systems[0].airflow_defect_ratio = -0.22
    hpxml_bldg.cooling_systems[0].cooling_capacity = 12345
    hpxml_bldg.cooling_systems[0].crankcase_heater_watts = 40.0
    hpxml_bldg.cooling_systems[0].cooling_efficiency_eer2 = 11.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mini_split_air_conditioner_values(default_hpxml_bldg.cooling_systems[0], 0.66, HPXML::HVACFanMotorTypeBPM, nil, -0.11, -0.22, 12345, 18.0, 11.0, 40.0, 1.0)

    # Test autosizing with factors
    hpxml_bldg.cooling_systems[0].cooling_capacity = nil
    hpxml_bldg.cooling_systems[0].cooling_autosizing_factor = 1.2
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mini_split_air_conditioner_values(default_hpxml_bldg.cooling_systems[0], 0.66, HPXML::HVACFanMotorTypeBPM, nil, -0.11, -0.22, nil, 18.0, 11.0, 40.0, 1.2)

    # Test defaults
    hpxml_bldg.cooling_systems[0].fan_watts_per_cfm = nil
    hpxml_bldg.cooling_systems[0].fan_motor_type = nil
    hpxml_bldg.cooling_systems[0].charge_defect_ratio = nil
    hpxml_bldg.cooling_systems[0].airflow_defect_ratio = nil
    hpxml_bldg.cooling_systems[0].cooling_capacity = nil
    hpxml_bldg.cooling_systems[0].crankcase_heater_watts = nil
    hpxml_bldg.cooling_systems[0].cooling_autosizing_factor = nil
    hpxml_bldg.cooling_systems[0].cooling_autosizing_limit = nil
    hpxml_bldg.cooling_systems[0].cooling_efficiency_eer2 = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mini_split_air_conditioner_values(default_hpxml_bldg.cooling_systems[0], 0.18, HPXML::HVACFanMotorTypeBPM, nil, 0, 0, nil, 18.0, 12.03, 19.4, 1.0)

    # Test defaults w/ ductless
    hpxml_bldg.cooling_systems[0].distribution_system.delete
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mini_split_air_conditioner_values(default_hpxml_bldg.cooling_systems[0], 0.07, HPXML::HVACFanMotorTypeBPM, nil, 0, 0, nil, 18.0, 12.03, 13.1, 1.0)

    # Test defaults w/ ductless - SEER2/EER
    hpxml_bldg.cooling_systems[0].cooling_efficiency_seer2 = nil
    hpxml_bldg.cooling_systems[0].cooling_efficiency_seer = 13.3
    hpxml_bldg.cooling_systems[0].cooling_efficiency_eer2 = nil
    hpxml_bldg.cooling_systems[0].cooling_efficiency_eer = 12.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mini_split_air_conditioner_values(default_hpxml_bldg.cooling_systems[0], 0.07, HPXML::HVACFanMotorTypeBPM, nil, 0, 0, nil, 13.3, 12.0, 13.1, 1.0)
  end

  def test_ptac
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-ptac-with-heating-electricity.xml')
    hpxml_bldg.cooling_systems[0].cooling_capacity = 12345
    hpxml_bldg.cooling_systems[0].crankcase_heater_watts = 40.0
    hpxml_bldg.cooling_systems[0].cooling_efficiency_eer = nil
    hpxml_bldg.cooling_systems[0].cooling_efficiency_ceer = 12.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_room_air_conditioner_ptac_values(default_hpxml_bldg.cooling_systems[0], nil, 12345, 40.0, 1.0, 12.0)

    # Test autosizing with factors
    hpxml_bldg.cooling_systems[0].cooling_capacity = nil
    hpxml_bldg.cooling_systems[0].cooling_autosizing_factor = 1.2
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_room_air_conditioner_ptac_values(default_hpxml_bldg.cooling_systems[0], nil, nil, 40.0, 1.2, 12.0)

    # Test defaults
    hpxml_bldg.cooling_systems[0].cooling_capacity = nil
    hpxml_bldg.cooling_systems[0].crankcase_heater_watts = nil
    hpxml_bldg.cooling_systems[0].cooling_autosizing_factor = nil
    hpxml_bldg.cooling_systems[0].cooling_autosizing_limit = nil
    hpxml_bldg.cooling_systems[0].cooling_efficiency_eer = 10.7
    hpxml_bldg.cooling_systems[0].cooling_efficiency_ceer = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_room_air_conditioner_ptac_values(default_hpxml_bldg.cooling_systems[0], nil, nil, 0.0, 1.0, 10.59)
  end

  def test_furnaces
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.cooling_systems[0].fan_watts_per_cfm = 0.66
    hpxml_bldg.heating_systems[0].fan_watts_per_cfm = 0.66
    hpxml_bldg.heating_systems[0].fan_motor_type = HPXML::HVACFanMotorTypeBPM
    hpxml_bldg.heating_systems[0].airflow_defect_ratio = -0.22
    hpxml_bldg.heating_systems[0].heating_capacity = 12345
    hpxml_bldg.heating_systems[0].pilot_light = true
    hpxml_bldg.heating_systems[0].pilot_light_btuh = 999
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_furnace_values(default_hpxml_bldg.heating_systems[0], 0.66, HPXML::HVACFanMotorTypeBPM, nil, -0.22, 12345, true, 999, 1.0)

    # Test autosizing with factors
    hpxml_bldg.heating_systems[0].heating_capacity = nil
    hpxml_bldg.heating_systems[0].heating_autosizing_factor = 1.2
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_furnace_values(default_hpxml_bldg.heating_systems[0], 0.66, HPXML::HVACFanMotorTypeBPM, nil, -0.22, nil, true, 999, 1.2)

    # Test watts/cfm based on attached cooling system
    hpxml_bldg.heating_systems[0].fan_watts_per_cfm = nil
    hpxml_bldg.cooling_systems[0].fan_watts_per_cfm = 0.55
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_furnace_values(default_hpxml_bldg.heating_systems[0], 0.55, HPXML::HVACFanMotorTypeBPM, nil, -0.22, nil, true, 999, 1.2)

    # Test watts/cfm based on fan model type
    hpxml_bldg.cooling_systems[0].fan_watts_per_cfm = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_furnace_values(default_hpxml_bldg.heating_systems[0], 0.375, HPXML::HVACFanMotorTypeBPM, nil, -0.22, nil, true, 999, 1.2)

    # Test fan model type based on watts/cfm
    hpxml_bldg.heating_systems[0].fan_watts_per_cfm = 0.4
    hpxml_bldg.heating_systems[0].fan_motor_type = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_furnace_values(default_hpxml_bldg.heating_systems[0], 0.4, HPXML::HVACFanMotorTypePSC, nil, -0.22, nil, true, 999, 1.2)

    # Test defaults
    hpxml_bldg.heating_systems[0].fan_watts_per_cfm = nil
    hpxml_bldg.heating_systems[0].fan_motor_type = nil
    hpxml_bldg.heating_systems[0].airflow_defect_ratio = nil
    hpxml_bldg.heating_systems[0].heating_capacity = nil
    hpxml_bldg.heating_systems[0].pilot_light_btuh = nil
    hpxml_bldg.heating_systems[0].heating_autosizing_factor = nil
    hpxml_bldg.heating_systems[0].heating_autosizing_limit = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_furnace_values(default_hpxml_bldg.heating_systems[0], 0.5, HPXML::HVACFanMotorTypePSC, nil, 0, nil, true, 500, 1.0)

    # Test defaults w/o pilot
    hpxml_bldg.heating_systems[0].pilot_light = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_furnace_values(default_hpxml_bldg.heating_systems[0], 0.5, HPXML::HVACFanMotorTypePSC, nil, 0, nil, false, nil, 1.0)

    # Test defaults w/ gravity distribution system
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-furnace-gas-only.xml')
    hpxml_bldg.heating_systems[0].distribution_system.air_type = HPXML::AirTypeGravity
    hpxml_bldg.heating_systems[0].fan_watts_per_cfm = nil
    hpxml_bldg.heating_systems[0].airflow_defect_ratio = nil
    hpxml_bldg.heating_systems[0].heating_capacity = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_furnace_values(default_hpxml_bldg.heating_systems[0], 0.0, nil, nil, 0, nil, false, nil, 1.0)
  end

  def test_wall_furnaces
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-wall-furnace-elec-only.xml')
    hpxml_bldg.heating_systems[0].fan_watts = 22
    hpxml_bldg.heating_systems[0].heating_capacity = 12345
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_wall_furnace_values(default_hpxml_bldg.heating_systems[0], 22, nil, 12345, 1.0)

    # Test autosizing with factors
    hpxml_bldg.heating_systems[0].heating_capacity = nil
    hpxml_bldg.heating_systems[0].heating_autosizing_factor = 1.2
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_wall_furnace_values(default_hpxml_bldg.heating_systems[0], 22, nil, nil, 1.2)

    # Test defaults
    hpxml_bldg.heating_systems[0].fan_watts = nil
    hpxml_bldg.heating_systems[0].heating_capacity = nil
    hpxml_bldg.heating_systems[0].heating_autosizing_factor = nil
    hpxml_bldg.heating_systems[0].heating_autosizing_limit = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_wall_furnace_values(default_hpxml_bldg.heating_systems[0], 0, nil, nil, 1.0)

    # Test defaults w/o pilot
    hpxml_bldg.heating_systems[0].pilot_light = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_wall_furnace_values(default_hpxml_bldg.heating_systems[0], 0, nil, nil, 1.0)
  end

  def test_floor_furnaces
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-floor-furnace-propane-only.xml')
    hpxml_bldg.heating_systems[0].fan_watts = 22
    hpxml_bldg.heating_systems[0].heating_capacity = 12345
    hpxml_bldg.heating_systems[0].pilot_light = true
    hpxml_bldg.heating_systems[0].pilot_light_btuh = 999
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_floor_furnace_values(default_hpxml_bldg.heating_systems[0], 22, nil, 12345, true, 999, 1.0)

    # Test autosizing with factors
    hpxml_bldg.heating_systems[0].heating_capacity = nil
    hpxml_bldg.heating_systems[0].heating_autosizing_factor = 1.2
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_floor_furnace_values(default_hpxml_bldg.heating_systems[0], 22, nil, nil, true, 999, 1.2)

    # Test defaults
    hpxml_bldg.heating_systems[0].fan_watts = nil
    hpxml_bldg.heating_systems[0].pilot_light_btuh = nil
    hpxml_bldg.heating_systems[0].heating_autosizing_factor = nil
    hpxml_bldg.heating_systems[0].heating_autosizing_limit = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_floor_furnace_values(default_hpxml_bldg.heating_systems[0], 0, nil, nil, true, 500, 1.0)

    # Test defaults w/o pilot
    hpxml_bldg.heating_systems[0].pilot_light = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_floor_furnace_values(default_hpxml_bldg.heating_systems[0], 0, nil, nil, false, nil, 1.0)
  end

  def test_electric_resistance
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-elec-resistance-only.xml')
    hpxml_bldg.heating_systems[0].electric_resistance_distribution = HPXML::ElectricResistanceDistributionRadiantCeiling
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_electric_resistance_values(default_hpxml_bldg.heating_systems[0], HPXML::ElectricResistanceDistributionRadiantCeiling)

    # Test defaults
    hpxml_bldg.heating_systems[0].electric_resistance_distribution = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_electric_resistance_values(default_hpxml_bldg.heating_systems[0], HPXML::ElectricResistanceDistributionBaseboard)
  end

  def test_boilers
    # Test inputs not overridden by defaults (in-unit boiler)
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-boiler-gas-only.xml')
    hpxml_bldg.heating_systems[0].electric_auxiliary_energy = 99.9
    hpxml_bldg.heating_systems[0].heating_capacity = 12345
    hpxml_bldg.heating_systems[0].pilot_light = true
    hpxml_bldg.heating_systems[0].pilot_light_btuh = 999
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_boiler_values(default_hpxml_bldg.heating_systems[0], 99.9, 12345, true, 999, 1.0)

    # Test autosizing with factors
    hpxml_bldg.heating_systems[0].heating_capacity = nil
    hpxml_bldg.heating_systems[0].heating_autosizing_factor = 1.2
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_boiler_values(default_hpxml_bldg.heating_systems[0], 99.9, nil, true, 999, 1.2)

    # Test defaults w/ in-unit boiler
    hpxml_bldg.heating_systems[0].electric_auxiliary_energy = nil
    hpxml_bldg.heating_systems[0].heating_capacity = nil
    hpxml_bldg.heating_systems[0].pilot_light_btuh = nil
    hpxml_bldg.heating_systems[0].heating_autosizing_factor = nil
    hpxml_bldg.heating_systems[0].heating_autosizing_limit = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_boiler_values(default_hpxml_bldg.heating_systems[0], 170.0, nil, true, 500, 1.0)

    # Test inputs not overridden by defaults (shared boiler)
    hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit-shared-boiler-only-baseboard.xml')
    hpxml_bldg.heating_systems[0].shared_loop_watts = nil
    hpxml_bldg.heating_systems[0].electric_auxiliary_energy = 99.9
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_boiler_values(default_hpxml_bldg.heating_systems[0], 99.9, nil, false, nil, 1.0)
  end

  def test_stoves
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-stove-oil-only.xml')
    hpxml_bldg.heating_systems[0].fan_watts = 22
    hpxml_bldg.heating_systems[0].heating_capacity = 12345
    hpxml_bldg.heating_systems[0].pilot_light = true
    hpxml_bldg.heating_systems[0].pilot_light_btuh = 999
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_stove_values(default_hpxml_bldg.heating_systems[0], 22, nil, 12345, true, 999, 1.0)

    # Test autosizing with factors
    hpxml_bldg.heating_systems[0].heating_capacity = nil
    hpxml_bldg.heating_systems[0].heating_autosizing_factor = 1.2
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_stove_values(default_hpxml_bldg.heating_systems[0], 22, nil, nil, true, 999, 1.2)

    # Test defaults
    hpxml_bldg.heating_systems[0].fan_watts = nil
    hpxml_bldg.heating_systems[0].pilot_light_btuh = nil
    hpxml_bldg.heating_systems[0].heating_autosizing_factor = nil
    hpxml_bldg.heating_systems[0].heating_autosizing_limit = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_stove_values(default_hpxml_bldg.heating_systems[0], 40, nil, nil, true, 500, 1.0)

    # Test defaults w/o pilot
    hpxml_bldg.heating_systems[0].pilot_light = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_stove_values(default_hpxml_bldg.heating_systems[0], 40, nil, nil, false, nil, 1.0)
  end

  def test_space_heaters
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-space-heater-gas-only.xml')
    hpxml_bldg.heating_systems[0].fan_watts = 22
    hpxml_bldg.heating_systems[0].heating_capacity = 12345
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_space_heater_values(default_hpxml_bldg.heating_systems[0], 22, nil, 12345, 1.0)

    # Test autosizing with factors
    hpxml_bldg.heating_systems[0].heating_capacity = nil
    hpxml_bldg.heating_systems[0].heating_autosizing_factor = 1.2
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_space_heater_values(default_hpxml_bldg.heating_systems[0], 22, nil, nil, 1.2)

    # Test defaults
    hpxml_bldg.heating_systems[0].fan_watts = nil
    hpxml_bldg.heating_systems[0].heating_capacity = nil
    hpxml_bldg.heating_systems[0].heating_autosizing_factor = nil
    hpxml_bldg.heating_systems[0].heating_autosizing_limit = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_space_heater_values(default_hpxml_bldg.heating_systems[0], 0, nil, nil, 1.0)
  end

  def test_fireplaces
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-fireplace-wood-only.xml')
    hpxml_bldg.heating_systems[0].fan_watts = 22
    hpxml_bldg.heating_systems[0].heating_capacity = 12345
    hpxml_bldg.heating_systems[0].pilot_light = true
    hpxml_bldg.heating_systems[0].pilot_light_btuh = 999
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_fireplace_values(default_hpxml_bldg.heating_systems[0], 22, nil, 12345, true, 999, 1.0)

    # Test autosizing with factors
    hpxml_bldg.heating_systems[0].heating_capacity = nil
    hpxml_bldg.heating_systems[0].heating_autosizing_factor = 1.2
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_fireplace_values(default_hpxml_bldg.heating_systems[0], 22, nil, nil, true, 999, 1.2)

    # Test defaults
    hpxml_bldg.heating_systems[0].fan_watts = nil
    hpxml_bldg.heating_systems[0].heating_capacity = nil
    hpxml_bldg.heating_systems[0].pilot_light_btuh = nil
    hpxml_bldg.heating_systems[0].heating_autosizing_factor = nil
    hpxml_bldg.heating_systems[0].heating_autosizing_limit = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_fireplace_values(default_hpxml_bldg.heating_systems[0], 0, nil, nil, true, 500, 1.0)

    # Test defaults w/o pilot
    hpxml_bldg.heating_systems[0].pilot_light = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_fireplace_values(default_hpxml_bldg.heating_systems[0], 0, nil, nil, false, nil, 1.0)
  end

  def test_air_source_heat_pumps
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
    hpxml_bldg.heat_pumps[0].fan_watts_per_cfm = 0.66
    hpxml_bldg.heat_pumps[0].fan_motor_type = HPXML::HVACFanMotorTypeBPM
    hpxml_bldg.heat_pumps[0].charge_defect_ratio = -0.11
    hpxml_bldg.heat_pumps[0].airflow_defect_ratio = -0.22
    hpxml_bldg.heat_pumps[0].cooling_capacity = 12345
    hpxml_bldg.heat_pumps[0].heating_capacity = 23456
    hpxml_bldg.heat_pumps[0].backup_heating_capacity = 34567
    hpxml_bldg.heat_pumps[0].cooling_efficiency_seer = nil
    hpxml_bldg.heat_pumps[0].cooling_efficiency_seer2 = 13.3
    hpxml_bldg.heat_pumps[0].cooling_efficiency_eer = nil
    hpxml_bldg.heat_pumps[0].cooling_efficiency_eer2 = 13.0
    hpxml_bldg.heat_pumps[0].heating_efficiency_hspf = nil
    hpxml_bldg.heat_pumps[0].heating_efficiency_hspf2 = 6.8
    hpxml_bldg.heat_pumps[0].heating_capacity_17F = 11728
    hpxml_bldg.heat_pumps[0].heating_capacity_fraction_17F = nil
    hpxml_bldg.heat_pumps[0].crankcase_heater_watts = 40.0
    hpxml_bldg.heat_pumps[0].pan_heater_watts = 99.0
    hpxml_bldg.heat_pumps[0].pan_heater_control_type = HPXML::HVACPanHeaterControlTypeDefrost
    hpxml_bldg.heat_pumps[0].backup_heating_active_during_defrost = false
    hpxml_bldg.heat_pumps[0].equipment_type = HPXML::HVACEquipmentTypePackaged
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_air_to_air_heat_pump_values(default_hpxml_bldg.heat_pumps[0], 0.66, HPXML::HVACFanMotorTypeBPM, nil, nil, -0.11, -0.22, 12345, 23456, 11728, 34567, 13.3, 13.0, 6.8, 40.0, 1.0, 1.0, 1.0, 99.0, HPXML::HVACPanHeaterControlTypeDefrost, false, HPXML::HVACEquipmentTypePackaged)

    # Test w/ heating capacity fraction 17F
    hpxml_bldg.heat_pumps[0].heating_capacity_fraction_17F = 0.5
    hpxml_bldg.heat_pumps[0].heating_capacity_17F = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_air_to_air_heat_pump_values(default_hpxml_bldg.heat_pumps[0], 0.66, HPXML::HVACFanMotorTypeBPM, nil, nil, -0.11, -0.22, 12345, 23456, 11728, 34567, 13.3, 13.0, 6.8, 40.0, 1.0, 1.0, 1.0, 99.0, HPXML::HVACPanHeaterControlTypeDefrost, false, HPXML::HVACEquipmentTypePackaged)

    # Test defaults - SEER2/HSPF2/EER
    hpxml_bldg.heat_pumps[0].cooling_efficiency_seer2 = nil
    hpxml_bldg.heat_pumps[0].cooling_efficiency_seer = 14.0
    hpxml_bldg.heat_pumps[0].cooling_efficiency_eer2 = nil
    hpxml_bldg.heat_pumps[0].cooling_efficiency_eer = 13.68
    hpxml_bldg.heat_pumps[0].heating_efficiency_hspf2 = nil
    hpxml_bldg.heat_pumps[0].heating_efficiency_hspf = 8.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_air_to_air_heat_pump_values(default_hpxml_bldg.heat_pumps[0], 0.66, HPXML::HVACFanMotorTypeBPM, nil, nil, -0.11, -0.22, 12345, 23456, 11728, 34567, 13.3, 13.0, 6.72, 40.0, 1.0, 1.0, 1.0, 99.0, HPXML::HVACPanHeaterControlTypeDefrost, false, HPXML::HVACEquipmentTypePackaged)

    # Test autosizing with factors
    hpxml_bldg.heat_pumps[0].cooling_capacity = nil
    hpxml_bldg.heat_pumps[0].heating_capacity = nil
    hpxml_bldg.heat_pumps[0].heating_capacity_17F = nil
    hpxml_bldg.heat_pumps[0].backup_heating_capacity = nil
    hpxml_bldg.heat_pumps[0].heating_autosizing_factor = 1.5
    hpxml_bldg.heat_pumps[0].cooling_autosizing_factor = 1.2
    hpxml_bldg.heat_pumps[0].backup_heating_autosizing_factor = 1.1
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_air_to_air_heat_pump_values(default_hpxml_bldg.heat_pumps[0], 0.66, HPXML::HVACFanMotorTypeBPM, nil, nil, -0.11, -0.22, nil, nil, nil, nil, 13.3, 13.0, 6.72, 40.0, 1.5, 1.2, 1.1, 99.0, HPXML::HVACPanHeaterControlTypeDefrost, false, HPXML::HVACEquipmentTypePackaged)

    # Test watts/cfm based on fan model type
    hpxml_bldg.heat_pumps[0].fan_watts_per_cfm = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_air_to_air_heat_pump_values(default_hpxml_bldg.heat_pumps[0], 0.375, HPXML::HVACFanMotorTypeBPM, nil, nil, -0.11, -0.22, nil, nil, nil, nil, 13.3, 13.0, 6.72, 40.0, 1.5, 1.2, 1.1, 99.0, HPXML::HVACPanHeaterControlTypeDefrost, false, HPXML::HVACEquipmentTypePackaged)

    # Test fan model type based on watts/cfm
    hpxml_bldg.heat_pumps[0].fan_watts_per_cfm = 0.17
    hpxml_bldg.heat_pumps[0].fan_motor_type = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_air_to_air_heat_pump_values(default_hpxml_bldg.heat_pumps[0], 0.17, HPXML::HVACFanMotorTypePSC, nil, nil, -0.11, -0.22, nil, nil, nil, nil, 13.3, 13.0, 6.72, 40.0, 1.5, 1.2, 1.1, 99.0, HPXML::HVACPanHeaterControlTypeDefrost, false, HPXML::HVACEquipmentTypePackaged)

    # Test defaults
    hpxml_bldg.heat_pumps[0].fan_watts_per_cfm = nil
    hpxml_bldg.heat_pumps[0].fan_motor_type = nil
    hpxml_bldg.heat_pumps[0].charge_defect_ratio = nil
    hpxml_bldg.heat_pumps[0].airflow_defect_ratio = nil
    hpxml_bldg.heat_pumps[0].cooling_capacity = nil
    hpxml_bldg.heat_pumps[0].heating_capacity = nil
    hpxml_bldg.heat_pumps[0].heating_capacity_17F = nil
    hpxml_bldg.heat_pumps[0].backup_heating_capacity = nil
    hpxml_bldg.heat_pumps[0].crankcase_heater_watts = nil
    hpxml_bldg.heat_pumps[0].heating_autosizing_factor = nil
    hpxml_bldg.heat_pumps[0].cooling_autosizing_factor = nil
    hpxml_bldg.heat_pumps[0].backup_heating_autosizing_factor = nil
    hpxml_bldg.heat_pumps[0].heating_autosizing_limit = nil
    hpxml_bldg.heat_pumps[0].cooling_autosizing_limit = nil
    hpxml_bldg.heat_pumps[0].backup_heating_autosizing_limit = nil
    hpxml_bldg.heat_pumps[0].pan_heater_watts = nil
    hpxml_bldg.heat_pumps[0].pan_heater_control_type = nil
    hpxml_bldg.heat_pumps[0].backup_heating_active_during_defrost = nil
    hpxml_bldg.heat_pumps[0].equipment_type = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_air_to_air_heat_pump_values(default_hpxml_bldg.heat_pumps[0], 0.5, HPXML::HVACFanMotorTypePSC, nil, nil, 0, 0, nil, nil, nil, nil, 13.3, 13.0, 6.8, 32.8, 1.0, 1.0, 1.0, 150.0, HPXML::HVACPanHeaterControlTypeContinuous, true, HPXML::HVACEquipmentTypeSplit)

    # Test w/ detailed performance data
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-detailed-performance.xml')
    hpxml_bldg.heat_pumps[0].fan_watts_per_cfm = 0.66
    hpxml_bldg.heat_pumps[0].fan_motor_type = HPXML::HVACFanMotorTypeBPM
    hpxml_bldg.heat_pumps[0].charge_defect_ratio = -0.11
    hpxml_bldg.heat_pumps[0].airflow_defect_ratio = -0.22
    hpxml_bldg.heat_pumps[0].cooling_efficiency_seer = nil
    hpxml_bldg.heat_pumps[0].cooling_efficiency_seer2 = 13.3
    hpxml_bldg.heat_pumps[0].cooling_efficiency_eer2 = 13.0
    hpxml_bldg.heat_pumps[0].heating_efficiency_hspf = nil
    hpxml_bldg.heat_pumps[0].heating_efficiency_hspf2 = 6.8
    hpxml_bldg.heat_pumps[0].crankcase_heater_watts = 40.0
    nom_cap_at_47f = hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == 47.0 && dp.capacity_description == HPXML::CapacityDescriptionNominal }.capacity
    nom_cap_at_17f = hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == 17.0 && dp.capacity_description == HPXML::CapacityDescriptionNominal }.capacity
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_air_to_air_heat_pump_values(default_hpxml_bldg.heat_pumps[0], 0.66, HPXML::HVACFanMotorTypeBPM, nil, nil, -0.11, -0.22, nil, nom_cap_at_47f, nom_cap_at_17f, nil, 13.3, 13.0, 6.8, 40.0, 1.0, 1.0, 1.0, 150.0, HPXML::HVACPanHeaterControlTypeContinuous, true, HPXML::HVACEquipmentTypeSplit)

    # Test w/ detailed performance data and autosizing
    heating_capacity_fractions = [0.278, 1.0, 1.1, 0.12, 0.69, 0.7, 0.05, 0.55]
    cooling_capacity_fractions = [0.325, 1.0, 1.0, 0.37, 1.11]
    heating_capacities = []
    cooling_capacities = []
    hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.each_with_index do |dp, idx|
      dp.capacity_fraction_of_nominal = heating_capacity_fractions[idx]
      heating_capacities << dp.capacity
    end
    hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.each_with_index do |dp, idx|
      dp.capacity_fraction_of_nominal = cooling_capacity_fractions[idx]
      cooling_capacities << dp.capacity
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    # Test that fractions are not used when capacities are provided
    _test_default_detailed_performance_capacities(default_hpxml_bldg.heat_pumps[0], 35800, 36000, heating_capacities, cooling_capacities)

    heating_capacities = []
    cooling_capacities = []
    hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.each_with_index do |dp, idx|
      dp.capacity = nil
      heating_capacities << (30000 * heating_capacity_fractions[idx]).round
    end
    hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.each_with_index do |dp, idx|
      dp.capacity = nil
      cooling_capacities << (40000 * cooling_capacity_fractions[idx]).round
    end
    hpxml_bldg.heat_pumps[0].heating_capacity = 30000
    hpxml_bldg.heat_pumps[0].cooling_capacity = 40000
    # Test that fractions are used when capacities are missing
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_detailed_performance_capacities(default_hpxml_bldg.heat_pumps[0], 30000, 40000, heating_capacities, cooling_capacities)
  end

  def test_detailed_performance_data
    # Test to verify the default detailed performance data points are consistent with RESNET's NEEP-Statistical-Model.xlsm
    # Spreadsheet can be found in https://github.com/NREL/OpenStudio-HPXML/pull/1879

    tol = 0.02 # 2%, higher tolerance because expected values from spreadsheet are not rounded like they are in the RESNET Standard

    # ============== #
    # Variable Speed #
    # ============== #

    hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed.xml')
    hpxml_bldg.heat_pumps[0].cooling_capacity = 8000.0
    hpxml_bldg.heat_pumps[0].heating_capacity = 8700.0
    hpxml_bldg.heat_pumps[0].heating_capacity_17F = 7500.0
    hpxml_bldg.heat_pumps[0].cooling_efficiency_seer = nil
    hpxml_bldg.heat_pumps[0].cooling_efficiency_seer2 = 14.3
    hpxml_bldg.heat_pumps[0].cooling_efficiency_eer = nil
    hpxml_bldg.heat_pumps[0].cooling_efficiency_eer2 = 11.0
    hpxml_bldg.heat_pumps[0].heating_efficiency_hspf = nil
    hpxml_bldg.heat_pumps[0].heating_efficiency_hspf2 = 7.5
    hpxml_bldg.heat_pumps[0].heating_capacity_fraction_17F = nil
    hpxml_bldg.heat_pumps[0].fan_motor_type = HPXML::HVACFanMotorTypeBPM
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()

    # Heating
    max_dp_47f = default_hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == 47.0 && dp.capacity_description == HPXML::CapacityDescriptionMaximum }
    nom_dp_47f = default_hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == 47.0 && dp.capacity_description == HPXML::CapacityDescriptionNominal }
    min_dp_47f = default_hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == 47.0 && dp.capacity_description == HPXML::CapacityDescriptionMinimum }
    max_dp_17f = default_hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == 17.0 && dp.capacity_description == HPXML::CapacityDescriptionMaximum }
    nom_dp_17f = default_hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == 17.0 && dp.capacity_description == HPXML::CapacityDescriptionNominal }
    min_dp_17f = default_hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == 17.0 && dp.capacity_description == HPXML::CapacityDescriptionMinimum }
    max_dp_5f = default_hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == 5.0 && dp.capacity_description == HPXML::CapacityDescriptionMaximum }
    nom_dp_5f = default_hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == 5.0 && dp.capacity_description == HPXML::CapacityDescriptionNominal }
    min_dp_5f = default_hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == 5.0 && dp.capacity_description == HPXML::CapacityDescriptionMinimum }
    max_dp_lct = default_hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.outdoor_temperature < 5.0 && dp.capacity_description == HPXML::CapacityDescriptionMaximum }
    nom_dp_lct = default_hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.outdoor_temperature < 5.0 && dp.capacity_description == HPXML::CapacityDescriptionNominal }
    min_dp_lct = default_hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.outdoor_temperature < 5.0 && dp.capacity_description == HPXML::CapacityDescriptionMinimum }

    # 47F
    assert_in_epsilon(9576.6, max_dp_47f.capacity, tol)
    assert_in_epsilon(8700.0, nom_dp_47f.capacity, tol)
    assert_in_epsilon(2601.3, min_dp_47f.capacity, tol)
    assert_in_epsilon(2.46, max_dp_47f.efficiency_cop, tol)
    assert_in_epsilon(2.62, nom_dp_47f.efficiency_cop, tol)
    assert_in_epsilon(3.36, min_dp_47f.efficiency_cop, tol)

    # 17F
    assert_in_epsilon(9176.9, max_dp_17f.capacity, tol)
    assert_in_epsilon(7500.0, nom_dp_17f.capacity, tol)
    assert_in_epsilon(3127.5, min_dp_17f.capacity, tol)
    assert_in_epsilon(1.75, max_dp_17f.efficiency_cop, tol)
    assert_in_epsilon(1.94, nom_dp_17f.efficiency_cop, tol)
    assert_in_epsilon(2.19, min_dp_17f.efficiency_cop, tol)

    # 5F
    assert_in_epsilon(7950.8, max_dp_5f.capacity, tol)
    assert_in_epsilon(7857.4, nom_dp_5f.capacity, tol)
    assert_in_epsilon(2552.7, min_dp_5f.capacity, tol)
    assert_in_epsilon(1.50, max_dp_5f.efficiency_cop, tol)
    assert_in_epsilon(1.50, nom_dp_5f.efficiency_cop, tol)
    assert_in_epsilon(1.73, min_dp_5f.efficiency_cop, tol)

    # LCT
    assert_in_epsilon(4916.2, max_dp_lct.capacity, tol)
    assert_in_epsilon(4858.7, nom_dp_lct.capacity, tol)
    assert_in_epsilon(1597.4, min_dp_lct.capacity, tol)
    assert_in_epsilon(1.04, max_dp_lct.efficiency_cop, tol)
    assert_in_epsilon(1.04, nom_dp_lct.efficiency_cop, tol)
    assert_in_epsilon(1.20, min_dp_lct.efficiency_cop, tol)

    # Cooling
    max_dp_95f = default_hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.find { |dp| dp.outdoor_temperature == 95.0 && dp.capacity_description == HPXML::CapacityDescriptionMaximum }
    nom_dp_95f = default_hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.find { |dp| dp.outdoor_temperature == 95.0 && dp.capacity_description == HPXML::CapacityDescriptionNominal }
    min_dp_95f = default_hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.find { |dp| dp.outdoor_temperature == 95.0 && dp.capacity_description == HPXML::CapacityDescriptionMinimum }
    max_dp_82f = default_hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.find { |dp| dp.outdoor_temperature == 82.0 && dp.capacity_description == HPXML::CapacityDescriptionMaximum }
    nom_dp_82f = default_hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.find { |dp| dp.outdoor_temperature == 82.0 && dp.capacity_description == HPXML::CapacityDescriptionNominal }
    min_dp_82f = default_hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.find { |dp| dp.outdoor_temperature == 82.0 && dp.capacity_description == HPXML::CapacityDescriptionMinimum }

    # 95F
    assert_in_epsilon(8567.9, max_dp_95f.capacity, tol)
    assert_in_epsilon(8000.0, nom_dp_95f.capacity, tol)
    assert_in_epsilon(2750.1, min_dp_95f.capacity, tol)
    assert_in_epsilon(2.99, max_dp_95f.efficiency_cop, tol)
    assert_in_epsilon(3.22, nom_dp_95f.efficiency_cop, tol)
    assert_in_epsilon(3.80, min_dp_95f.efficiency_cop, tol)

    # 82F
    assert_in_epsilon(9111.6, max_dp_82f.capacity, tol)
    assert_in_epsilon(8505.5, nom_dp_82f.capacity, tol)
    assert_in_epsilon(2902.3, min_dp_82f.capacity, tol)
    assert_in_epsilon(3.97, max_dp_82f.efficiency_cop, tol)
    assert_in_epsilon(4.28, nom_dp_82f.efficiency_cop, tol)
    assert_in_epsilon(5.00, min_dp_82f.efficiency_cop, tol)

    # ========= #
    # Two Stage #
    # ========= #

    hpxml_bldg.heat_pumps[0].compressor_type = HPXML::HVACCompressorTypeTwoStage
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()

    # Heating
    nom_dp_47f = default_hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == 47.0 && dp.capacity_description == HPXML::CapacityDescriptionNominal }
    min_dp_47f = default_hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == 47.0 && dp.capacity_description == HPXML::CapacityDescriptionMinimum }
    nom_dp_17f = default_hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == 17.0 && dp.capacity_description == HPXML::CapacityDescriptionNominal }
    min_dp_17f = default_hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == 17.0 && dp.capacity_description == HPXML::CapacityDescriptionMinimum }
    nom_dp_5f = default_hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == 5.0 && dp.capacity_description == HPXML::CapacityDescriptionNominal }
    min_dp_5f = default_hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == 5.0 && dp.capacity_description == HPXML::CapacityDescriptionMinimum }

    # 47F
    assert_in_epsilon(8700.0, nom_dp_47f.capacity, tol)
    assert_in_epsilon(6190.9, min_dp_47f.capacity, tol)
    assert_in_epsilon(2.65, nom_dp_47f.efficiency_cop, tol)
    assert_in_epsilon(3.12, min_dp_47f.efficiency_cop, tol)

    # 17F
    assert_in_epsilon(7500.0, nom_dp_17f.capacity, tol)
    assert_in_epsilon(5337.0, min_dp_17f.capacity, tol)
    assert_in_epsilon(1.95, nom_dp_17f.efficiency_cop, tol)
    assert_in_epsilon(2.30, min_dp_17f.efficiency_cop, tol)

    # 5F
    assert_in_epsilon(7020.0, nom_dp_5f.capacity, tol)
    assert_in_epsilon(4995.4, min_dp_5f.capacity, tol)
    assert_in_epsilon(1.73, nom_dp_5f.efficiency_cop, tol)
    assert_in_epsilon(2.03, min_dp_5f.efficiency_cop, tol)

    # Cooling
    nom_dp_95f = default_hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.find { |dp| dp.outdoor_temperature == 95.0 && dp.capacity_description == HPXML::CapacityDescriptionNominal }
    min_dp_95f = default_hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.find { |dp| dp.outdoor_temperature == 95.0 && dp.capacity_description == HPXML::CapacityDescriptionMinimum }
    nom_dp_82f = default_hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.find { |dp| dp.outdoor_temperature == 82.0 && dp.capacity_description == HPXML::CapacityDescriptionNominal }
    min_dp_82f = default_hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.find { |dp| dp.outdoor_temperature == 82.0 && dp.capacity_description == HPXML::CapacityDescriptionMinimum }

    # 95F
    assert_in_epsilon(8000.0, nom_dp_95f.capacity, tol)
    assert_in_epsilon(5820.3, min_dp_95f.capacity, tol)
    assert_in_epsilon(3.22, nom_dp_95f.efficiency_cop, tol)
    assert_in_epsilon(3.54, min_dp_95f.efficiency_cop, tol)

    # 82F
    assert_in_epsilon(8548.9, nom_dp_82f.capacity, tol)
    assert_in_epsilon(6219.6, min_dp_82f.capacity, tol)
    assert_in_epsilon(4.01, nom_dp_82f.efficiency_cop, tol)
    assert_in_epsilon(4.40, min_dp_82f.efficiency_cop, tol)

    # ============ #
    # Single Stage #
    # ============ #

    hpxml_bldg.heat_pumps[0].compressor_type = HPXML::HVACCompressorTypeSingleStage
    hpxml_bldg.heat_pumps[0].fan_motor_type = HPXML::HVACFanMotorTypePSC
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()

    # Heating
    nom_dp_47f = default_hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == 47.0 && dp.capacity_description == HPXML::CapacityDescriptionNominal }
    nom_dp_17f = default_hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == 17.0 && dp.capacity_description == HPXML::CapacityDescriptionNominal }
    nom_dp_5f = default_hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == 5.0 && dp.capacity_description == HPXML::CapacityDescriptionNominal }

    # 47F
    assert_in_epsilon(8700.0, nom_dp_47f.capacity, tol)
    assert_in_epsilon(2.99, nom_dp_47f.efficiency_cop, tol)

    # 17F
    assert_in_epsilon(7500.0, nom_dp_17f.capacity, tol)
    assert_in_epsilon(2.21, nom_dp_17f.efficiency_cop, tol)

    # 5F
    assert_in_epsilon(7020.0, nom_dp_5f.capacity, tol)
    assert_in_epsilon(1.95, nom_dp_5f.efficiency_cop, tol)

    # Cooling
    nom_dp_95f = default_hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.find { |dp| dp.outdoor_temperature == 95.0 && dp.capacity_description == HPXML::CapacityDescriptionNominal }
    nom_dp_82f = default_hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.find { |dp| dp.outdoor_temperature == 82.0 && dp.capacity_description == HPXML::CapacityDescriptionNominal }

    # 95F
    assert_in_epsilon(8000.0, nom_dp_95f.capacity, tol)
    assert_in_epsilon(3.22, nom_dp_95f.efficiency_cop, tol)

    # 82F
    assert_in_epsilon(8548.9, nom_dp_82f.capacity, tol)
    assert_in_epsilon(4.37, nom_dp_82f.efficiency_cop, tol)
  end

  def test_packaged_terminal_heat_pumps
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-pthp.xml')
    hpxml_bldg.heat_pumps[0].cooling_capacity = 12345
    hpxml_bldg.heat_pumps[0].heating_capacity = 23456
    hpxml_bldg.heat_pumps[0].heating_capacity_fraction_17F = 0.1
    hpxml_bldg.heat_pumps[0].crankcase_heater_watts = 40.0
    hpxml_bldg.heat_pumps[0].backup_heating_active_during_defrost = true
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_pthp_values(default_hpxml_bldg.heat_pumps[0], nil, nil, 12345, 23456, 2346, 40.0, true, 1.0, 1.0, 1.0)

    # Test w/ heating capacity 17F
    hpxml_bldg.heat_pumps[0].heating_capacity_17F = 9876
    hpxml_bldg.heat_pumps[0].heating_capacity_fraction_17F = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_pthp_values(default_hpxml_bldg.heat_pumps[0], nil, nil, 12345, 23456, 9876, 40.0, true, 1.0, 1.0, 1.0)

    # Test autosizing with factors
    hpxml_bldg.heat_pumps[0].cooling_capacity = nil
    hpxml_bldg.heat_pumps[0].heating_capacity = nil
    hpxml_bldg.heat_pumps[0].heating_capacity_17F = nil
    hpxml_bldg.heat_pumps[0].heating_autosizing_factor = 1.5
    hpxml_bldg.heat_pumps[0].cooling_autosizing_factor = 1.2
    hpxml_bldg.heat_pumps[0].backup_heating_autosizing_factor = 1.1
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_pthp_values(default_hpxml_bldg.heat_pumps[0], nil, nil, nil, nil, nil, 40.0, true, 1.5, 1.2, 1.1)

    # Test defaults
    hpxml_bldg.heat_pumps[0].cooling_capacity = nil
    hpxml_bldg.heat_pumps[0].heating_capacity = nil
    hpxml_bldg.heat_pumps[0].backup_heating_capacity = nil
    hpxml_bldg.heat_pumps[0].heating_capacity_17F = nil
    hpxml_bldg.heat_pumps[0].crankcase_heater_watts = nil
    hpxml_bldg.heat_pumps[0].heating_autosizing_factor = nil
    hpxml_bldg.heat_pumps[0].cooling_autosizing_factor = nil
    hpxml_bldg.heat_pumps[0].backup_heating_autosizing_factor = nil
    hpxml_bldg.heat_pumps[0].heating_autosizing_limit = nil
    hpxml_bldg.heat_pumps[0].cooling_autosizing_limit = nil
    hpxml_bldg.heat_pumps[0].backup_heating_autosizing_limit = nil
    hpxml_bldg.heat_pumps[0].backup_heating_active_during_defrost = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_pthp_values(default_hpxml_bldg.heat_pumps[0], nil, nil, nil, nil, nil, 0.0, false, 1.0, 1.0, 1.0)
  end

  def test_mini_split_heat_pumps
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-mini-split-heat-pump-ducted.xml')
    hpxml_bldg.heat_pumps[0].fan_watts_per_cfm = 0.66
    hpxml_bldg.heat_pumps[0].fan_motor_type = HPXML::HVACFanMotorTypeBPM
    hpxml_bldg.heat_pumps[0].charge_defect_ratio = -0.11
    hpxml_bldg.heat_pumps[0].airflow_defect_ratio = -0.22
    hpxml_bldg.heat_pumps[0].cooling_capacity = 12345
    hpxml_bldg.heat_pumps[0].heating_capacity = 23456
    hpxml_bldg.heat_pumps[0].backup_heating_capacity = 34567
    hpxml_bldg.heat_pumps[0].heating_capacity_fraction_17F = 0.5
    hpxml_bldg.heat_pumps[0].crankcase_heater_watts = 40.0
    hpxml_bldg.heat_pumps[0].cooling_efficiency_eer2 = 11.0
    hpxml_bldg.heat_pumps[0].pan_heater_watts = 99.0
    hpxml_bldg.heat_pumps[0].pan_heater_control_type = HPXML::HVACPanHeaterControlTypeDefrost
    hpxml_bldg.heat_pumps[0].backup_heating_active_during_defrost = false
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mini_split_heat_pump_values(default_hpxml_bldg.heat_pumps[0], 0.66, HPXML::HVACFanMotorTypeBPM, nil, nil, -0.11, -0.22, 12345, 23456, 11728, 34567, 18.0, 11.0, 8.5, 40.0, 1.0, 1.0, 1.0, 99.0, HPXML::HVACPanHeaterControlTypeDefrost, false)

    # Test w/ heating capacity 17F
    hpxml_bldg.heat_pumps[0].heating_capacity_17F = 9876
    hpxml_bldg.heat_pumps[0].heating_capacity_fraction_17F = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mini_split_heat_pump_values(default_hpxml_bldg.heat_pumps[0], 0.66, HPXML::HVACFanMotorTypeBPM, nil, nil, -0.11, -0.22, 12345, 23456, 9876, 34567, 18.0, 11.0, 8.5, 40.0, 1.0, 1.0, 1.0, 99.0, HPXML::HVACPanHeaterControlTypeDefrost, false)

    # Test autosizing with factors
    hpxml_bldg.heat_pumps[0].cooling_capacity = nil
    hpxml_bldg.heat_pumps[0].heating_capacity = nil
    hpxml_bldg.heat_pumps[0].heating_capacity_17F = nil
    hpxml_bldg.heat_pumps[0].backup_heating_capacity = nil
    hpxml_bldg.heat_pumps[0].heating_autosizing_factor = 1.5
    hpxml_bldg.heat_pumps[0].cooling_autosizing_factor = 1.2
    hpxml_bldg.heat_pumps[0].backup_heating_autosizing_factor = 1.1
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mini_split_heat_pump_values(default_hpxml_bldg.heat_pumps[0], 0.66, HPXML::HVACFanMotorTypeBPM, nil, nil, -0.11, -0.22, nil, nil, nil, nil, 18.0, 11.0, 8.5, 40.0, 1.5, 1.2, 1.1, 99.0, HPXML::HVACPanHeaterControlTypeDefrost, false)

    # Test defaults
    hpxml_bldg.heat_pumps[0].fan_watts_per_cfm = nil
    hpxml_bldg.heat_pumps[0].fan_motor_type = nil
    hpxml_bldg.heat_pumps[0].charge_defect_ratio = nil
    hpxml_bldg.heat_pumps[0].airflow_defect_ratio = nil
    hpxml_bldg.heat_pumps[0].cooling_capacity = nil
    hpxml_bldg.heat_pumps[0].heating_capacity = nil
    hpxml_bldg.heat_pumps[0].heating_capacity_17F = nil
    hpxml_bldg.heat_pumps[0].backup_heating_capacity = nil
    hpxml_bldg.heat_pumps[0].crankcase_heater_watts = nil
    hpxml_bldg.heat_pumps[0].heating_autosizing_factor = nil
    hpxml_bldg.heat_pumps[0].cooling_autosizing_factor = nil
    hpxml_bldg.heat_pumps[0].backup_heating_autosizing_factor = nil
    hpxml_bldg.heat_pumps[0].heating_autosizing_limit = nil
    hpxml_bldg.heat_pumps[0].cooling_autosizing_limit = nil
    hpxml_bldg.heat_pumps[0].backup_heating_autosizing_limit = nil
    hpxml_bldg.heat_pumps[0].cooling_efficiency_eer2 = nil
    hpxml_bldg.heat_pumps[0].pan_heater_watts = nil
    hpxml_bldg.heat_pumps[0].pan_heater_control_type = nil
    hpxml_bldg.heat_pumps[0].backup_heating_active_during_defrost = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mini_split_heat_pump_values(default_hpxml_bldg.heat_pumps[0], 0.18, HPXML::HVACFanMotorTypeBPM, nil, nil, 0, 0, nil, nil, nil, nil, 18.0, 12.03, 8.5, 22.1, 1.0, 1.0, 1.0, 150.0, HPXML::HVACPanHeaterControlTypeContinuous, true)

    # Test defaults w/ ductless and no backup
    hpxml_bldg.heat_pumps[0].distribution_system.delete
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mini_split_heat_pump_values(default_hpxml_bldg.heat_pumps[0], 0.07, HPXML::HVACFanMotorTypeBPM, nil, nil, 0, 0, nil, nil, nil, nil, 18.0, 12.03, 8.5, 19.9, 1.0, 1.0, 1.0, 150.0, HPXML::HVACPanHeaterControlTypeContinuous, false)

    # Test defaults - SEER2/HSPF2/EER
    hpxml_bldg.heat_pumps[0].cooling_efficiency_seer2 = nil
    hpxml_bldg.heat_pumps[0].cooling_efficiency_seer = 14.0
    hpxml_bldg.heat_pumps[0].cooling_efficiency_eer2 = nil
    hpxml_bldg.heat_pumps[0].cooling_efficiency_eer = 12.3
    hpxml_bldg.heat_pumps[0].heating_efficiency_hspf2 = nil
    hpxml_bldg.heat_pumps[0].heating_efficiency_hspf = 8.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mini_split_heat_pump_values(default_hpxml_bldg.heat_pumps[0], 0.07, HPXML::HVACFanMotorTypeBPM, nil, nil, 0, 0, nil, nil, nil, nil, 14.0, 12.3, 7.2, 19.9, 1.0, 1.0, 1.0, 150.0, HPXML::HVACPanHeaterControlTypeContinuous, false)
  end

  def test_heat_pump_temperatures
    # Test inputs not overridden by defaults - ASHP w/ electric backup
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
    hpxml_bldg.heat_pumps[0].compressor_lockout_temp = -2.0
    hpxml_bldg.heat_pumps[0].backup_heating_lockout_temp = 44.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_heat_pump_temperature_values(default_hpxml_bldg.heat_pumps[0], -2.0, 44.0, nil)

    # Test defaults
    hpxml_bldg.heat_pumps[0].compressor_lockout_temp = nil
    hpxml_bldg.heat_pumps[0].backup_heating_lockout_temp = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_heat_pump_temperature_values(default_hpxml_bldg.heat_pumps[0], 0.0, 40.0, nil)

    # Test inputs not overridden by defaults - Var-speed ASHP w/ electric backup
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed.xml')
    hpxml_bldg.heat_pumps[0].compressor_lockout_temp = -2.0
    hpxml_bldg.heat_pumps[0].backup_heating_lockout_temp = 44.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_heat_pump_temperature_values(default_hpxml_bldg.heat_pumps[0], -2.0, 44.0, nil)

    # Test defaults
    hpxml_bldg.heat_pumps[0].compressor_lockout_temp = nil
    hpxml_bldg.heat_pumps[0].backup_heating_lockout_temp = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_heat_pump_temperature_values(default_hpxml_bldg.heat_pumps[0], -20.0, 40.0, nil)

    # Test inputs not overridden by defaults - MSHP w/o backup
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-mini-split-heat-pump-ductless.xml')
    hpxml_bldg.heat_pumps[0].compressor_lockout_temp = 33.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_heat_pump_temperature_values(default_hpxml_bldg.heat_pumps[0], 33.0, nil, nil)

    # Test defaults
    hpxml_bldg.heat_pumps[0].compressor_lockout_temp = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_heat_pump_temperature_values(default_hpxml_bldg.heat_pumps[0], -20.0, nil, nil)

    # Test inputs not overridden by defaults - MSHP w/ electric backup
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-mini-split-heat-pump-ductless-backup-baseboard.xml')
    hpxml_bldg.heat_pumps[0].compressor_lockout_temp = -2.0
    hpxml_bldg.heat_pumps[0].backup_heating_lockout_temp = 44.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_heat_pump_temperature_values(default_hpxml_bldg.heat_pumps[0], -2.0, 44.0, nil)

    # Test defaults
    hpxml_bldg.heat_pumps[0].compressor_lockout_temp = nil
    hpxml_bldg.heat_pumps[0].backup_heating_lockout_temp = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_heat_pump_temperature_values(default_hpxml_bldg.heat_pumps[0], -20.0, 40.0, nil)

    # Test inputs not overridden by defaults - HP w/ fuel backup
    ['base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml',
     'base-hvac-air-to-air-heat-pump-var-speed-backup-boiler.xml',
     'base-hvac-mini-split-heat-pump-ductless-backup-stove.xml'].each do |hpxml_name|
      hpxml, hpxml_bldg = _create_hpxml(hpxml_name)
      hpxml_bldg.heat_pumps[0].backup_heating_switchover_temp = 33.0
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      default_hpxml, default_hpxml_bldg = _test_measure()
      _test_default_heat_pump_temperature_values(default_hpxml_bldg.heat_pumps[0], nil, nil, 33.0)

      # Test inputs not overridden by defaults - HP w/ integrated/separate fuel backup, lockout temps
      hpxml_bldg.heat_pumps[0].backup_heating_switchover_temp = nil
      hpxml_bldg.heat_pumps[0].compressor_lockout_temp = 22.0
      hpxml_bldg.heat_pumps[0].backup_heating_lockout_temp = 44.0
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      default_hpxml, default_hpxml_bldg = _test_measure()
      _test_default_heat_pump_temperature_values(default_hpxml_bldg.heat_pumps[0], 22.0, 44.0, nil)

      # Test defaults
      hpxml_bldg.heat_pumps[0].compressor_lockout_temp = nil
      hpxml_bldg.heat_pumps[0].backup_heating_lockout_temp = nil
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      default_hpxml, default_hpxml_bldg = _test_measure()
      _test_default_heat_pump_temperature_values(default_hpxml_bldg.heat_pumps[0], 40.0, 50.0, nil)
    end
  end

  def test_ground_source_heat_pumps
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-ground-to-air-heat-pump-backup-integrated.xml')
    hpxml_bldg.heat_pumps[0].pump_watts_per_ton = 9.9
    hpxml_bldg.heat_pumps[0].fan_watts_per_cfm = 0.66
    hpxml_bldg.heat_pumps[0].fan_motor_type = HPXML::HVACFanMotorTypeBPM
    hpxml_bldg.heat_pumps[0].airflow_defect_ratio = -0.22
    hpxml_bldg.heat_pumps[0].cooling_capacity = 12345
    hpxml_bldg.heat_pumps[0].heating_capacity = 23456
    hpxml_bldg.heat_pumps[0].backup_heating_capacity = 34567
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_ground_to_air_heat_pump_values(default_hpxml_bldg.heat_pumps[0], 9.9, 0.66, HPXML::HVACFanMotorTypeBPM, nil, nil, -0.22, 12345, 23456, 34567)

    # Test watts/cfm based on fan model type
    hpxml_bldg.heat_pumps[0].fan_watts_per_cfm = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_ground_to_air_heat_pump_values(default_hpxml_bldg.heat_pumps[0], 9.9, 0.375, HPXML::HVACFanMotorTypeBPM, nil, nil, -0.22, 12345, 23456, 34567)

    # Test fan model type based on watts/cfm
    hpxml_bldg.heat_pumps[0].fan_watts_per_cfm = 0.17
    hpxml_bldg.heat_pumps[0].fan_motor_type = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_ground_to_air_heat_pump_values(default_hpxml_bldg.heat_pumps[0], 9.9, 0.17, HPXML::HVACFanMotorTypePSC, nil, nil, -0.22, 12345, 23456, 34567)

    # Test defaults
    hpxml_bldg.heat_pumps[0].pump_watts_per_ton = nil
    hpxml_bldg.heat_pumps[0].fan_watts_per_cfm = nil
    hpxml_bldg.heat_pumps[0].airflow_defect_ratio = nil
    hpxml_bldg.heat_pumps[0].cooling_capacity = nil
    hpxml_bldg.heat_pumps[0].heating_capacity = nil
    hpxml_bldg.heat_pumps[0].backup_heating_capacity = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_ground_to_air_heat_pump_values(default_hpxml_bldg.heat_pumps[0], 80.0, 0.5, HPXML::HVACFanMotorTypePSC, nil, nil, 0, nil, nil, nil)
  end

  def test_geothermal_loops
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-ground-to-air-heat-pump-detailed-geothermal-loop.xml')
    hpxml_bldg.geothermal_loops[0].loop_configuration = HPXML::GeothermalLoopLoopConfigurationVertical
    hpxml_bldg.geothermal_loops[0].loop_flow = 1
    hpxml_bldg.geothermal_loops[0].num_bore_holes = 2
    hpxml_bldg.geothermal_loops[0].bore_spacing = 3
    hpxml_bldg.geothermal_loops[0].bore_length = 100
    hpxml_bldg.geothermal_loops[0].bore_diameter = 5
    hpxml_bldg.geothermal_loops[0].grout_type = HPXML::GeothermalLoopGroutOrPipeTypeThermallyEnhanced
    hpxml_bldg.geothermal_loops[0].grout_conductivity = 6
    hpxml_bldg.geothermal_loops[0].pipe_type = HPXML::GeothermalLoopGroutOrPipeTypeThermallyEnhanced
    hpxml_bldg.geothermal_loops[0].pipe_conductivity = 7
    hpxml_bldg.geothermal_loops[0].pipe_diameter = 1.0
    hpxml_bldg.geothermal_loops[0].shank_spacing = 9
    hpxml_bldg.geothermal_loops[0].bore_config = HPXML::GeothermalLoopBorefieldConfigurationRectangle
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_geothermal_loop_values(default_hpxml_bldg.geothermal_loops[0], HPXML::GeothermalLoopLoopConfigurationVertical, 1, 2, 3, 100, 5, HPXML::GeothermalLoopGroutOrPipeTypeThermallyEnhanced, 6, HPXML::GeothermalLoopGroutOrPipeTypeThermallyEnhanced, 7, 1.0, 9, HPXML::GeothermalLoopBorefieldConfigurationRectangle)

    # Test defaults
    hpxml_bldg.geothermal_loops[0].loop_flow = nil # autosized
    hpxml_bldg.geothermal_loops[0].num_bore_holes = nil # autosized
    hpxml_bldg.geothermal_loops[0].bore_spacing = nil # 16.4 ft
    hpxml_bldg.geothermal_loops[0].bore_length = nil # autosized
    hpxml_bldg.geothermal_loops[0].bore_diameter = nil # 5.0 in
    hpxml_bldg.geothermal_loops[0].grout_type = nil # standard
    hpxml_bldg.geothermal_loops[0].grout_conductivity = nil # 0.75 Btu/hr-ft-F
    hpxml_bldg.geothermal_loops[0].pipe_type = nil # standard
    hpxml_bldg.geothermal_loops[0].pipe_conductivity = nil # 0.23 Btu/hr-ft-F
    hpxml_bldg.geothermal_loops[0].pipe_diameter = nil # 1.25 in
    hpxml_bldg.geothermal_loops[0].shank_spacing = nil # 2.63
    hpxml_bldg.geothermal_loops[0].bore_config = nil # rectangle
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_geothermal_loop_values(default_hpxml_bldg.geothermal_loops[0], HPXML::GeothermalLoopLoopConfigurationVertical, nil, nil, 16.4, nil, 5.0, HPXML::GeothermalLoopGroutOrPipeTypeStandard, 0.75, HPXML::GeothermalLoopGroutOrPipeTypeStandard, 0.23, 1.25, 2.63, HPXML::GeothermalLoopBorefieldConfigurationRectangle)

    # Test defaults w/ specified loop flow
    hpxml_bldg.geothermal_loops[0].loop_flow = 1
    hpxml_bldg.geothermal_loops[0].num_bore_holes = nil
    hpxml_bldg.geothermal_loops[0].bore_length = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_geothermal_loop_values(default_hpxml_bldg.geothermal_loops[0], HPXML::GeothermalLoopLoopConfigurationVertical, 1, nil, 16.4, nil, 5.0, HPXML::GeothermalLoopGroutOrPipeTypeStandard, 0.75, HPXML::GeothermalLoopGroutOrPipeTypeStandard, 0.23, 1.25, 2.63, HPXML::GeothermalLoopBorefieldConfigurationRectangle)

    # Test defaults w/ specified num bore holes
    hpxml_bldg.geothermal_loops[0].loop_flow = nil
    hpxml_bldg.geothermal_loops[0].num_bore_holes = 2
    hpxml_bldg.geothermal_loops[0].bore_length = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_geothermal_loop_values(default_hpxml_bldg.geothermal_loops[0], HPXML::GeothermalLoopLoopConfigurationVertical, nil, 2, 16.4, nil, 5.0, HPXML::GeothermalLoopGroutOrPipeTypeStandard, 0.75, HPXML::GeothermalLoopGroutOrPipeTypeStandard, 0.23, 1.25, 2.63, HPXML::GeothermalLoopBorefieldConfigurationRectangle)

    # Test defaults w/ specified bore length
    hpxml_bldg.geothermal_loops[0].loop_flow = nil
    hpxml_bldg.geothermal_loops[0].num_bore_holes = nil
    hpxml_bldg.geothermal_loops[0].bore_length = 300
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_geothermal_loop_values(default_hpxml_bldg.geothermal_loops[0], HPXML::GeothermalLoopLoopConfigurationVertical, nil, nil, 16.4, 300, 5.0, HPXML::GeothermalLoopGroutOrPipeTypeStandard, 0.75, HPXML::GeothermalLoopGroutOrPipeTypeStandard, 0.23, 1.25, 2.63, HPXML::GeothermalLoopBorefieldConfigurationRectangle)

    # Test defaults w/ specified loop flow, num bore holes
    hpxml_bldg.geothermal_loops[0].loop_flow = 2
    hpxml_bldg.geothermal_loops[0].num_bore_holes = 3
    hpxml_bldg.geothermal_loops[0].bore_length = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_geothermal_loop_values(default_hpxml_bldg.geothermal_loops[0], HPXML::GeothermalLoopLoopConfigurationVertical, 2, 3, 16.4, nil, 5.0, HPXML::GeothermalLoopGroutOrPipeTypeStandard, 0.75, HPXML::GeothermalLoopGroutOrPipeTypeStandard, 0.23, 1.25, 2.63, HPXML::GeothermalLoopBorefieldConfigurationRectangle)

    # Test defaults w/ specified num bore holes, bore length
    hpxml_bldg.geothermal_loops[0].loop_flow = nil
    hpxml_bldg.geothermal_loops[0].num_bore_holes = 4
    hpxml_bldg.geothermal_loops[0].bore_length = 400
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_geothermal_loop_values(default_hpxml_bldg.geothermal_loops[0], HPXML::GeothermalLoopLoopConfigurationVertical, nil, 4, 16.4, 400, 5.0, HPXML::GeothermalLoopGroutOrPipeTypeStandard, 0.75, HPXML::GeothermalLoopGroutOrPipeTypeStandard, 0.23, 1.25, 2.63, HPXML::GeothermalLoopBorefieldConfigurationRectangle)

    # Test defaults w/ specified loop flow, bore length
    hpxml_bldg.geothermal_loops[0].loop_flow = 5
    hpxml_bldg.geothermal_loops[0].num_bore_holes = nil
    hpxml_bldg.geothermal_loops[0].bore_length = 450
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_geothermal_loop_values(default_hpxml_bldg.geothermal_loops[0], HPXML::GeothermalLoopLoopConfigurationVertical, 5, nil, 16.4, 450, 5.0, HPXML::GeothermalLoopGroutOrPipeTypeStandard, 0.75, HPXML::GeothermalLoopGroutOrPipeTypeStandard, 0.23, 1.25, 2.63, HPXML::GeothermalLoopBorefieldConfigurationRectangle)

    # Test defaults w/ thermally enhanced grout type
    hpxml_bldg.geothermal_loops[0].grout_type = HPXML::GeothermalLoopGroutOrPipeTypeThermallyEnhanced
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_geothermal_loop_values(default_hpxml_bldg.geothermal_loops[0], HPXML::GeothermalLoopLoopConfigurationVertical, nil, nil, 16.4, nil, 5.0, HPXML::GeothermalLoopGroutOrPipeTypeThermallyEnhanced, 1.2, HPXML::GeothermalLoopGroutOrPipeTypeStandard, 0.23, 1.25, 2.63, HPXML::GeothermalLoopBorefieldConfigurationRectangle)

    # Test defaults w/ thermally enhanced pipe type
    hpxml_bldg.geothermal_loops[0].pipe_type = HPXML::GeothermalLoopGroutOrPipeTypeThermallyEnhanced
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_geothermal_loop_values(default_hpxml_bldg.geothermal_loops[0], HPXML::GeothermalLoopLoopConfigurationVertical, nil, nil, 16.4, nil, 5.0, HPXML::GeothermalLoopGroutOrPipeTypeThermallyEnhanced, 1.2, HPXML::GeothermalLoopGroutOrPipeTypeThermallyEnhanced, 0.40, 1.25, 2.63, HPXML::GeothermalLoopBorefieldConfigurationRectangle)

    # Test defaults w/ specified rectangle bore config
    hpxml_bldg.geothermal_loops[0].num_bore_holes = nil
    hpxml_bldg.geothermal_loops[0].bore_config = HPXML::GeothermalLoopBorefieldConfigurationRectangle
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_geothermal_loop_values(default_hpxml_bldg.geothermal_loops[0], HPXML::GeothermalLoopLoopConfigurationVertical, nil, nil, 16.4, nil, 5.0, HPXML::GeothermalLoopGroutOrPipeTypeThermallyEnhanced, 1.2, HPXML::GeothermalLoopGroutOrPipeTypeThermallyEnhanced, 0.40, 1.25, 2.63, HPXML::GeothermalLoopBorefieldConfigurationRectangle)
  end

  def test_hvac_location
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-foundation-unconditioned-basement.xml')
    hpxml_bldg.heating_systems[0].location = HPXML::LocationAtticUnvented
    hpxml_bldg.cooling_systems[0].delete
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_hvac_location_values(default_hpxml_bldg.heating_systems[0], HPXML::LocationAtticUnvented)

    # Test defaults
    hpxml_bldg.heating_systems[0].location = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_hvac_location_values(default_hpxml_bldg.heating_systems[0], HPXML::LocationBasementUnconditioned)

    # Test defaults -- multiple duct locations
    hpxml_bldg.heating_systems[0].distribution_system.ducts.each do |duct|
      duct.duct_fraction_area = nil
    end
    hpxml_bldg.heating_systems[0].distribution_system.ducts[0].duct_surface_area = 150.0
    hpxml_bldg.heating_systems[0].distribution_system.ducts[1].duct_surface_area = 50.0
    hpxml_bldg.heating_systems[0].distribution_system.ducts.add(id: "Ducts#{hpxml_bldg.heating_systems[0].distribution_system.ducts.size + 1}",
                                                                duct_type: HPXML::DuctTypeSupply,
                                                                duct_insulation_r_value: 0,
                                                                duct_location: HPXML::LocationAtticUnvented,
                                                                duct_surface_area: 151)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_hvac_location_values(default_hpxml_bldg.heating_systems[0], HPXML::LocationAtticUnvented)

    # Test defaults -- ducts outside
    hpxml_bldg.heating_systems[0].distribution_system.ducts.each do |d|
      d.duct_location = HPXML::LocationOutside
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_hvac_location_values(default_hpxml_bldg.heating_systems[0], HPXML::LocationOtherExterior)

    # Test defaults -- hydronic
    hpxml_bldg.heating_systems[0].heating_system_type = HPXML::HVACTypeBoiler
    hpxml_bldg.heating_systems[0].distribution_system.distribution_system_type = HPXML::HVACDistributionTypeHydronic
    hpxml_bldg.heating_systems[0].distribution_system.hydronic_type = HPXML::HydronicTypeBaseboard
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_hvac_location_values(default_hpxml_bldg.heating_systems[0], HPXML::LocationBasementUnconditioned)

    # Test defaults -- DSE = 1
    hpxml_bldg.heating_systems[0].distribution_system.distribution_system_type = HPXML::HVACDistributionTypeDSE
    hpxml_bldg.heating_systems[0].distribution_system.annual_heating_dse = 1.0
    hpxml_bldg.heating_systems[0].distribution_system.annual_cooling_dse = 0.5
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_hvac_location_values(default_hpxml_bldg.heating_systems[0], HPXML::LocationConditionedSpace)

    # Test defaults -- DSE < 1
    hpxml_bldg.heating_systems[0].distribution_system.annual_heating_dse = 0.8
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_hvac_location_values(default_hpxml_bldg.heating_systems[0], HPXML::LocationUnconditionedSpace)

    # Test defaults -- ductless
    hpxml_bldg.heating_systems[0].heating_system_type = HPXML::HVACTypeWallFurnace
    hpxml_bldg.heating_systems[0].distribution_system.delete
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_hvac_location_values(default_hpxml_bldg.heating_systems[0], HPXML::LocationConditionedSpace)

    # Test defaults -- shared system
    hpxml, _hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit-shared-boiler-only-baseboard.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_hvac_location_values(default_hpxml_bldg.heating_systems[0], HPXML::LocationOtherHeatedSpace)
  end

  def test_hvac_controls
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.hvac_controls[0].heating_setpoint_temp = 71.5
    hpxml_bldg.hvac_controls[0].cooling_setpoint_temp = 77.5
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_hvac_control_setpoint_values(default_hpxml_bldg.hvac_controls[0], 71.5, 77.5)

    # Test defaults
    hpxml_bldg.hvac_controls[0].heating_setpoint_temp = nil
    hpxml_bldg.hvac_controls[0].cooling_setpoint_temp = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_hvac_control_setpoint_values(default_hpxml_bldg.hvac_controls[0], 68, 78)

    # Test inputs not overridden by defaults (w/ setbacks)
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-setpoints-daily-setbacks.xml')
    hpxml_bldg.hvac_controls[0].heating_setback_start_hour = 12
    hpxml_bldg.hvac_controls[0].cooling_setup_start_hour = 12
    hpxml_bldg.hvac_controls[0].seasons_heating_begin_month = 1
    hpxml_bldg.hvac_controls[0].seasons_heating_begin_day = 1
    hpxml_bldg.hvac_controls[0].seasons_heating_end_month = 6
    hpxml_bldg.hvac_controls[0].seasons_heating_end_day = 30
    hpxml_bldg.hvac_controls[0].seasons_cooling_begin_month = 7
    hpxml_bldg.hvac_controls[0].seasons_cooling_begin_day = 1
    hpxml_bldg.hvac_controls[0].seasons_cooling_end_month = 12
    hpxml_bldg.hvac_controls[0].seasons_cooling_end_day = 31
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_hvac_control_setback_values(default_hpxml_bldg.hvac_controls[0], 12, 12)
    _test_default_hvac_control_season_values(default_hpxml_bldg.hvac_controls[0], 1, 1, 6, 30, 7, 1, 12, 31)

    # Test defaults w/ setbacks
    hpxml_bldg.hvac_controls[0].heating_setback_start_hour = nil
    hpxml_bldg.hvac_controls[0].cooling_setup_start_hour = nil
    hpxml_bldg.hvac_controls[0].seasons_heating_begin_month = nil
    hpxml_bldg.hvac_controls[0].seasons_heating_begin_day = nil
    hpxml_bldg.hvac_controls[0].seasons_heating_end_month = nil
    hpxml_bldg.hvac_controls[0].seasons_heating_end_day = nil
    hpxml_bldg.hvac_controls[0].seasons_cooling_begin_month = nil
    hpxml_bldg.hvac_controls[0].seasons_cooling_begin_day = nil
    hpxml_bldg.hvac_controls[0].seasons_cooling_end_month = nil
    hpxml_bldg.hvac_controls[0].seasons_cooling_end_day = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_hvac_control_setback_values(default_hpxml_bldg.hvac_controls[0], 23, 9)
    _test_default_hvac_control_season_values(default_hpxml_bldg.hvac_controls[0], 1, 1, 12, 31, 1, 1, 12, 31)
  end

  def test_hvac_distribution_air
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served = 2700.0
    hpxml_bldg.hvac_distributions[0].number_of_return_registers = 2
    hpxml_bldg.hvac_distributions[0].ducts[-1].delete
    hpxml_bldg.hvac_distributions[0].ducts[-1].delete
    hpxml_bldg.hvac_distributions[0].ducts[0].duct_surface_area = 150.0
    hpxml_bldg.hvac_distributions[0].ducts[1].duct_surface_area = 50.0
    hpxml_bldg.hvac_distributions[0].ducts[0].duct_fraction_area = nil
    hpxml_bldg.hvac_distributions[0].ducts[1].duct_fraction_area = nil
    hpxml_bldg.hvac_distributions[0].ducts[0].duct_surface_area_multiplier = 0.5
    hpxml_bldg.hvac_distributions[0].ducts[1].duct_surface_area_multiplier = 1.5
    hpxml_bldg.hvac_distributions[0].ducts[0].duct_buried_insulation_level = HPXML::DuctBuriedInsulationPartial
    hpxml_bldg.hvac_distributions[0].ducts[1].duct_buried_insulation_level = HPXML::DuctBuriedInsulationDeep
    hpxml_bldg.hvac_distributions[0].ducts[0].duct_insulation_r_value = nil
    hpxml_bldg.hvac_distributions[0].ducts[1].duct_insulation_r_value = nil
    hpxml_bldg.hvac_distributions[0].ducts[0].duct_effective_r_value = 1.23
    hpxml_bldg.hvac_distributions[0].ducts[1].duct_effective_r_value = 3.21
    hpxml_bldg.hvac_distributions[0].ducts[0].duct_fraction_rectangular = 0.33
    hpxml_bldg.hvac_distributions[0].ducts[1].duct_fraction_rectangular = 0.77
    hpxml_bldg.hvac_distributions[0].manualj_blower_fan_heat_btuh = 1234.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    expected_supply_locations = [HPXML::LocationAtticUnvented]
    expected_return_locations = [HPXML::LocationAtticUnvented]
    expected_supply_areas = [150.0]
    expected_return_areas = [50.0]
    expected_supply_fracs = [1.0]
    expected_return_fracs = [1.0]
    expected_supply_area_mults = [0.5]
    expected_return_area_mults = [1.5]
    expected_supply_effective_rvalues = [1.23]
    expected_return_effective_rvalues = [3.21]
    expected_supply_buried_levels = [HPXML::DuctBuriedInsulationPartial]
    expected_return_buried_levels = [HPXML::DuctBuriedInsulationDeep]
    expected_supply_rect_fracs = [0.33]
    expected_return_rect_fracs = [0.77]
    expected_n_return_registers = default_hpxml_bldg.building_construction.number_of_conditioned_floors
    _test_default_air_distribution_values(default_hpxml_bldg, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas,
                                          expected_supply_fracs, expected_return_fracs, expected_n_return_registers, expected_supply_area_mults, expected_return_area_mults,
                                          expected_supply_buried_levels, expected_return_buried_levels, expected_supply_effective_rvalues, expected_return_effective_rvalues,
                                          expected_supply_rect_fracs, expected_return_rect_fracs, 1234.0)

    # Test defaults w/ conditioned basement
    hpxml_bldg.hvac_distributions[0].number_of_return_registers = nil
    hpxml_bldg.hvac_distributions[0].manualj_blower_fan_heat_btuh = nil
    hpxml_bldg.hvac_distributions[0].ducts.each do |duct|
      duct.duct_location = nil
      duct.duct_surface_area = nil
      duct.duct_surface_area_multiplier = nil
      duct.duct_buried_insulation_level = nil
      duct.duct_effective_r_value = nil
      duct.duct_fraction_rectangular = nil
    end
    hpxml_bldg.hvac_distributions[0].ducts[0].duct_insulation_r_value = 4
    hpxml_bldg.hvac_distributions[0].ducts[1].duct_insulation_r_value = 8
    hpxml_bldg.hvac_distributions[0].ducts[0].duct_shape = HPXML::DuctShapeRectangular
    hpxml_bldg.hvac_distributions[0].ducts[1].duct_shape = HPXML::DuctShapeRound
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    expected_supply_locations = [HPXML::LocationBasementConditioned]
    expected_return_locations = [HPXML::LocationBasementConditioned]
    expected_supply_areas = [729.0]
    expected_return_areas = [270.0]
    expected_supply_fracs = [1.0]
    expected_return_fracs = [1.0]
    expected_supply_area_mults = [1.0]
    expected_return_area_mults = [1.0]
    expected_supply_buried_levels = [HPXML::DuctBuriedInsulationNone]
    expected_return_buried_levels = [HPXML::DuctBuriedInsulationNone]
    expected_supply_effective_rvalues = [5.0]
    expected_return_effective_rvalues = [7.8]
    expected_supply_rect_fracs = [1.0]
    expected_return_rect_fracs = [0.0]
    expected_n_return_registers = default_hpxml_bldg.building_construction.number_of_conditioned_floors
    _test_default_air_distribution_values(default_hpxml_bldg, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas,
                                          expected_supply_fracs, expected_return_fracs, expected_n_return_registers, expected_supply_area_mults, expected_return_area_mults,
                                          expected_supply_buried_levels, expected_return_buried_levels, expected_supply_effective_rvalues, expected_return_effective_rvalues,
                                          expected_supply_rect_fracs, expected_return_rect_fracs, 0.0)

    # Test defaults w/ multiple foundations
    hpxml, hpxml_bldg = _create_hpxml('base-foundation-multiple.xml')
    hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served = 1350.0
    hpxml_bldg.hvac_distributions[0].number_of_return_registers = 1
    hpxml_bldg.hvac_distributions[0].ducts.each do |duct|
      duct.duct_location = nil
      duct.duct_fraction_area = nil
      duct.duct_surface_area_multiplier = nil
      duct.duct_buried_insulation_level = nil
      duct.duct_fraction_rectangular = nil
      duct.duct_shape = nil
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    expected_supply_locations = [HPXML::LocationBasementUnconditioned]
    expected_return_locations = [HPXML::LocationBasementUnconditioned]
    expected_supply_areas = [364.5]
    expected_return_areas = [67.5]
    expected_supply_fracs = [1.0]
    expected_return_fracs = [1.0]
    expected_supply_area_mults = [1.0]
    expected_return_area_mults = [1.0]
    expected_supply_effective_rvalues = [4.4]
    expected_return_effective_rvalues = [5.0]
    expected_supply_buried_levels = [HPXML::DuctBuriedInsulationNone]
    expected_return_buried_levels = [HPXML::DuctBuriedInsulationNone]
    expected_supply_rect_fracs = [0.25]
    expected_return_rect_fracs = [1.0]
    expected_n_return_registers = default_hpxml_bldg.building_construction.number_of_conditioned_floors
    _test_default_air_distribution_values(default_hpxml_bldg, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas,
                                          expected_supply_fracs, expected_return_fracs, expected_n_return_registers, expected_supply_area_mults, expected_return_area_mults,
                                          expected_supply_buried_levels, expected_return_buried_levels, expected_supply_effective_rvalues, expected_return_effective_rvalues,
                                          expected_supply_rect_fracs, expected_return_rect_fracs, 0.0)

    # Test defaults w/ foundation exposed to ambient
    hpxml, hpxml_bldg = _create_hpxml('base-foundation-ambient.xml')
    hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served = 1350.0
    hpxml_bldg.hvac_distributions[0].number_of_return_registers = 1
    hpxml_bldg.hvac_distributions[0].ducts.each do |duct|
      duct.duct_location = nil
      duct.duct_fraction_area = nil
      duct.duct_surface_area_multiplier = nil
      duct.duct_buried_insulation_level = nil
      duct.duct_fraction_rectangular = nil
      duct.duct_shape = nil
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    expected_supply_locations = [HPXML::LocationAtticUnvented]
    expected_return_locations = [HPXML::LocationAtticUnvented]
    expected_supply_areas = [364.5]
    expected_return_areas = [67.5]
    expected_supply_fracs = [1.0]
    expected_return_fracs = [1.0]
    expected_supply_area_mults = [1.0]
    expected_return_area_mults = [1.0]
    expected_supply_effective_rvalues = [4.4]
    expected_return_effective_rvalues = [5.0]
    expected_supply_buried_levels = [HPXML::DuctBuriedInsulationNone]
    expected_return_buried_levels = [HPXML::DuctBuriedInsulationNone]
    expected_supply_rect_fracs = [0.25]
    expected_return_rect_fracs = [1.0]
    expected_n_return_registers = default_hpxml_bldg.building_construction.number_of_conditioned_floors
    _test_default_air_distribution_values(default_hpxml_bldg, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas,
                                          expected_supply_fracs, expected_return_fracs, expected_n_return_registers, expected_supply_area_mults, expected_return_area_mults,
                                          expected_supply_buried_levels, expected_return_buried_levels, expected_supply_effective_rvalues, expected_return_effective_rvalues,
                                          expected_supply_rect_fracs, expected_return_rect_fracs, 0.0)

    # Test defaults w/ building/unit adjacent to other housing unit
    hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit-adjacent-to-other-housing-unit.xml')
    hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served = 900.0
    hpxml_bldg.hvac_distributions[0].number_of_return_registers = 1
    hpxml_bldg.hvac_distributions[0].ducts.each do |duct|
      duct.duct_location = nil
      duct.duct_fraction_area = nil
      duct.duct_surface_area_multiplier = nil
      duct.duct_buried_insulation_level = nil
      duct.duct_fraction_rectangular = nil
      duct.duct_shape = nil
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    expected_supply_locations = [HPXML::LocationConditionedSpace]
    expected_return_locations = [HPXML::LocationConditionedSpace]
    expected_supply_areas = [243.0]
    expected_return_areas = [45.0]
    expected_supply_fracs = [1.0]
    expected_return_fracs = [1.0]
    expected_supply_area_mults = [1.0]
    expected_return_area_mults = [1.0]
    expected_supply_effective_rvalues = [1.7]
    expected_return_effective_rvalues = [1.7]
    expected_supply_buried_levels = [HPXML::DuctBuriedInsulationNone]
    expected_return_buried_levels = [HPXML::DuctBuriedInsulationNone]
    expected_supply_rect_fracs = [0.25]
    expected_return_rect_fracs = [1.0]
    expected_n_return_registers = default_hpxml_bldg.building_construction.number_of_conditioned_floors
    _test_default_air_distribution_values(default_hpxml_bldg, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas,
                                          expected_supply_fracs, expected_return_fracs, expected_n_return_registers, expected_supply_area_mults, expected_return_area_mults,
                                          expected_supply_buried_levels, expected_return_buried_levels, expected_supply_effective_rvalues, expected_return_effective_rvalues,
                                          expected_supply_rect_fracs, expected_return_rect_fracs, 0.0)

    # Test defaults w/ multiple HVAC systems
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-multiple.xml')
    hpxml_bldg.hvac_distributions.each do |hvac_distribution|
      next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir

      hvac_distribution.conditioned_floor_area_served = 270.0
      hvac_distribution.number_of_return_registers = 2
      hvac_distribution.ducts.each do |duct|
        duct.duct_location = nil
        duct.duct_surface_area = nil
        duct.duct_surface_area_multiplier = nil
        duct.duct_buried_insulation_level = nil
        duct.duct_fraction_rectangular = nil
        duct.duct_shape = nil
      end
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    expected_supply_locations = [HPXML::LocationBasementConditioned, HPXML::LocationBasementConditioned] * default_hpxml_bldg.hvac_distributions.size
    expected_return_locations = [HPXML::LocationBasementConditioned, HPXML::LocationBasementConditioned] * default_hpxml_bldg.hvac_distributions.size
    expected_supply_areas = [36.45, 36.45] * default_hpxml_bldg.hvac_distributions.size
    expected_return_areas = [13.5, 13.5] * default_hpxml_bldg.hvac_distributions.size
    expected_supply_fracs = [0.5, 0.5] * default_hpxml_bldg.hvac_distributions.size
    expected_return_fracs = [0.5, 0.5] * default_hpxml_bldg.hvac_distributions.size
    expected_supply_area_mults = [1.0, 1.0] * default_hpxml_bldg.hvac_distributions.size
    expected_return_area_mults = [1.0, 1.0] * default_hpxml_bldg.hvac_distributions.size
    expected_supply_buried_levels = [HPXML::DuctBuriedInsulationNone] * 2 * default_hpxml_bldg.hvac_distributions.size
    expected_return_buried_levels = [HPXML::DuctBuriedInsulationNone] * 2 * default_hpxml_bldg.hvac_distributions.size
    expected_supply_effective_rvalues = [6.9] * 2 * default_hpxml_bldg.hvac_distributions.size
    expected_return_effective_rvalues = [5.0] * 2 * default_hpxml_bldg.hvac_distributions.size
    expected_supply_rect_fracs = [0.25] * 2 * default_hpxml_bldg.hvac_distributions.size
    expected_return_rect_fracs = [1.0] * 2 * default_hpxml_bldg.hvac_distributions.size
    expected_n_return_registers = default_hpxml_bldg.building_construction.number_of_conditioned_floors
    _test_default_air_distribution_values(default_hpxml_bldg, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas,
                                          expected_supply_fracs, expected_return_fracs, expected_n_return_registers, expected_supply_area_mults, expected_return_area_mults,
                                          expected_supply_buried_levels, expected_return_buried_levels, expected_supply_effective_rvalues, expected_return_effective_rvalues,
                                          expected_supply_rect_fracs, expected_return_rect_fracs, 0.0)
  end

  def test_hvac_distribution_hydronic
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-boiler-gas-central-ac-1-speed.xml')
    hpxml_bldg.hvac_distributions[0].manualj_hot_water_piping_btuh = 1234.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_hydronic_distribution_values(default_hpxml_bldg, 1234.0)

    # Test defaults
    hpxml_bldg.hvac_distributions[0].manualj_hot_water_piping_btuh = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_hydronic_distribution_values(default_hpxml_bldg, 0.0)
  end

  def test_mech_ventilation_fans
    # Test inputs not overridden by defaults w/ shared exhaust system
    hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-sfa-unit.xml')
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation',
                                    fan_type: HPXML::MechVentTypeExhaust,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: true,
                                    fraction_recirculation: 0.0,
                                    in_unit_flow_rate: 10.0,
                                    hours_in_operation: 22.0,
                                    fan_power: 12.5,
                                    delivered_ventilation: 89)
    vent_fan = hpxml_bldg.ventilation_fans[0]
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mech_vent_values(default_hpxml_bldg, true, 22.0, 12.5, 89)

    # Test inputs w/ TestedFlowRate
    vent_fan.tested_flow_rate = 79
    vent_fan.rated_flow_rate = nil
    vent_fan.calculated_flow_rate = nil
    vent_fan.delivered_ventilation = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mech_vent_values(default_hpxml_bldg, true, 22.0, 12.5, 79)

    # Test inputs w/ RatedFlowRate
    vent_fan.tested_flow_rate = nil
    vent_fan.rated_flow_rate = 69
    vent_fan.calculated_flow_rate = nil
    vent_fan.delivered_ventilation = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mech_vent_values(default_hpxml_bldg, true, 22.0, 12.5, 69)

    # Test inputs w/ CalculatedFlowRate
    vent_fan.tested_flow_rate = nil
    vent_fan.rated_flow_rate = nil
    vent_fan.calculated_flow_rate = 59
    vent_fan.delivered_ventilation = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mech_vent_values(default_hpxml_bldg, true, 22.0, 12.5, 59)

    # Test defaults
    vent_fan.rated_flow_rate = nil
    vent_fan.start_hour = nil
    vent_fan.count = nil
    vent_fan.is_shared_system = nil
    vent_fan.fraction_recirculation = nil
    vent_fan.in_unit_flow_rate = nil
    vent_fan.hours_in_operation = nil
    vent_fan.fan_power = nil
    vent_fan.tested_flow_rate = nil
    vent_fan.rated_flow_rate = nil
    vent_fan.calculated_flow_rate = nil
    vent_fan.delivered_ventilation = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mech_vent_values(default_hpxml_bldg, false, 24.0, 27.5, 78.5)

    # Test defaults w/ SFA building, compartmentalization test
    hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-sfa-unit.xml')
    hpxml_bldg.air_infiltration_measurements[0].infiltration_type = HPXML::InfiltrationTypeUnitTotal
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation',
                                    fan_type: HPXML::MechVentTypeExhaust,
                                    used_for_whole_building_ventilation: true)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mech_vent_values(default_hpxml_bldg, false, 24.0, 28.0, 80.0)

    # Test defaults w/ SFA building, guarded test
    hpxml_bldg.air_infiltration_measurements[0].infiltration_type = HPXML::InfiltrationTypeUnitExterior
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mech_vent_values(default_hpxml_bldg, false, 24.0, 27.5, 78.5)

    # Test defaults w/ MF building, compartmentalization test
    hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit.xml')
    hpxml_bldg.air_infiltration_measurements[0].infiltration_type = HPXML::InfiltrationTypeUnitTotal
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation',
                                    fan_type: HPXML::MechVentTypeExhaust,
                                    used_for_whole_building_ventilation: true)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mech_vent_values(default_hpxml_bldg, false, 24.0, 19.9, 56.9)

    # Test defaults w/ MF building, guarded test
    hpxml_bldg.air_infiltration_measurements[0].infiltration_type = HPXML::InfiltrationTypeUnitExterior
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mech_vent_values(default_hpxml_bldg, false, 24.0, 19.3, 55.2)

    # Test defaults w/ nACH infiltration
    hpxml, hpxml_bldg = _create_hpxml('base-enclosure-infil-natural-ach.xml')
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation',
                                    fan_type: HPXML::MechVentTypeExhaust,
                                    used_for_whole_building_ventilation: true)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mech_vent_values(default_hpxml_bldg, false, 24.0, 26.6, 76.0)

    # Test defaults w/ CFM50 infiltration
    hpxml, hpxml_bldg = _create_hpxml('base-enclosure-infil-cfm50.xml')
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation',
                                    fan_type: HPXML::MechVentTypeExhaust,
                                    used_for_whole_building_ventilation: true)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mech_vent_values(default_hpxml_bldg, false, 24.0, 35.6, 101.8)

    # Test defaults w/ balanced system
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation',
                                    fan_type: HPXML::MechVentTypeBalanced,
                                    used_for_whole_building_ventilation: true)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mech_vent_values(default_hpxml_bldg, false, 24.0, 52.8, 75.4)

    # Test defaults w/ cathedral ceiling
    hpxml, hpxml_bldg = _create_hpxml('base-atticroof-cathedral.xml')
    hpxml_bldg.ventilation_fans.add(id: 'MechanicalVentilation',
                                    fan_type: HPXML::MechVentTypeExhaust,
                                    used_for_whole_building_ventilation: true)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mech_vent_values(default_hpxml_bldg, false, 24.0, 29.9, 85.5)

    # Test inputs not overridden by defaults w/ CFIS
    hpxml, hpxml_bldg = _create_hpxml('base-mechvent-cfis.xml')
    vent_fan = hpxml_bldg.ventilation_fans.find { |f| f.used_for_whole_building_ventilation }
    vent_fan.hours_in_operation = 12.0
    vent_fan.fan_power = 12.5
    vent_fan.rated_flow_rate = 222.0
    vent_fan.cfis_vent_mode_airflow_fraction = 0.5
    vent_fan.cfis_has_outdoor_air_control = false
    vent_fan.cfis_control_type = HPXML::CFISControlTypeTimer
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mech_vent_values(default_hpxml_bldg, false, 12.0, 12.5, 222.0, 0.5, HPXML::CFISModeAirHandler, false, HPXML::CFISControlTypeTimer)

    # Test defaults w/ CFIS
    vent_fan.is_shared_system = nil
    vent_fan.hours_in_operation = nil
    vent_fan.fan_power = nil
    vent_fan.rated_flow_rate = nil
    vent_fan.cfis_vent_mode_airflow_fraction = nil
    vent_fan.cfis_addtl_runtime_operating_mode = nil
    vent_fan.cfis_has_outdoor_air_control = nil
    vent_fan.cfis_control_type = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mech_vent_values(default_hpxml_bldg, false, 8.0, 360.0, 305.4, 1.0, HPXML::CFISModeAirHandler, true, HPXML::CFISControlTypeOptimized)

    # Test inputs not overridden by defaults w/ CFIS & supplemental fan
    hpxml, hpxml_bldg = _create_hpxml('base-mechvent-cfis-supplemental-fan-exhaust.xml')
    vent_fan = hpxml_bldg.ventilation_fans.find { |f| f.used_for_whole_building_ventilation && f.fan_type == HPXML::MechVentTypeCFIS }
    vent_fan.hours_in_operation = 12.0
    vent_fan.rated_flow_rate = 222.0
    vent_fan.cfis_supplemental_fan_runs_with_air_handler_fan = true
    suppl_vent_fan = vent_fan.cfis_supplemental_fan
    suppl_vent_fan.tested_flow_rate = 79.0
    suppl_vent_fan.fan_power = 9.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mech_vent_values(default_hpxml_bldg, false, 12.0, nil, 222.0, nil, HPXML::CFISModeSupplementalFan, true, HPXML::CFISControlTypeOptimized, true)
    _test_default_mech_vent_suppl_values(default_hpxml_bldg, false, nil, 9.0, 79.0)

    # Test defaults w/ CFIS & supplemental fan
    vent_fan.is_shared_system = nil
    vent_fan.hours_in_operation = nil
    vent_fan.fan_power = nil
    vent_fan.rated_flow_rate = nil
    vent_fan.cfis_vent_mode_airflow_fraction = nil
    vent_fan.cfis_has_outdoor_air_control = nil
    vent_fan.cfis_supplemental_fan_runs_with_air_handler_fan = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mech_vent_values(default_hpxml_bldg, false, 8.0, nil, 305.4, nil, HPXML::CFISModeSupplementalFan, true, HPXML::CFISControlTypeOptimized, false)

    # Test defaults w/ CFIS supplemental fan
    suppl_vent_fan.tested_flow_rate = nil
    suppl_vent_fan.is_shared_system = nil
    suppl_vent_fan.fan_power = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mech_vent_suppl_values(default_hpxml_bldg, false, nil, 35.6, 101.8)

    # Test inputs not overridden by defaults w/ ERV
    hpxml, hpxml_bldg = _create_hpxml('base-mechvent-erv.xml')
    vent_fan = hpxml_bldg.ventilation_fans.find { |f| f.used_for_whole_building_ventilation }
    vent_fan.is_shared_system = false
    vent_fan.hours_in_operation = 20.0
    vent_fan.fan_power = 45.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mech_vent_values(default_hpxml_bldg, false, 20.0, 45.0, 110)

    # Test defaults w/ ERV
    vent_fan.is_shared_system = nil
    vent_fan.hours_in_operation = nil
    vent_fan.fan_power = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_mech_vent_values(default_hpxml_bldg, false, 24.0, 110.0, 110)
  end

  def test_local_ventilation_fans
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-mechvent-bath-kitchen-fans.xml')
    kitchen_fan = hpxml_bldg.ventilation_fans.find { |f| f.used_for_local_ventilation && f.fan_location == HPXML::LocationKitchen }
    kitchen_fan.rated_flow_rate = 300
    kitchen_fan.fan_power = 20
    kitchen_fan.start_hour = 12
    kitchen_fan.count = 2
    kitchen_fan.hours_in_operation = 2
    bath_fan = hpxml_bldg.ventilation_fans.find { |f| f.used_for_local_ventilation && f.fan_location == HPXML::LocationBath }
    bath_fan.rated_flow_rate = 80
    bath_fan.fan_power = 33
    bath_fan.start_hour = 6
    bath_fan.count = 3
    bath_fan.hours_in_operation = 3
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_kitchen_fan_values(default_hpxml_bldg, 2, 300, 2, 20, 12)
    _test_default_bath_fan_values(default_hpxml_bldg, 3, 80, 3, 33, 6)

    # Test defaults
    kitchen_fan.rated_flow_rate = nil
    kitchen_fan.fan_power = nil
    kitchen_fan.start_hour = nil
    kitchen_fan.count = nil
    kitchen_fan.hours_in_operation = nil
    bath_fan.rated_flow_rate = nil
    bath_fan.fan_power = nil
    bath_fan.start_hour = nil
    bath_fan.count = nil
    bath_fan.hours_in_operation = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_kitchen_fan_values(default_hpxml_bldg, 1, 100, 1, 30, 18)
    _test_default_bath_fan_values(default_hpxml_bldg, 2, 50, 1, 15, 7)
  end

  def test_whole_house_fan
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-mechvent-whole-house-fan.xml')
    whf = hpxml_bldg.ventilation_fans.find { |f| f.used_for_seasonal_cooling_load_reduction }
    whf.rated_flow_rate = 3000
    whf.fan_power = 321
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_whole_house_fan_values(default_hpxml_bldg, 3000, 321)

    # Test defaults
    whf.rated_flow_rate = nil
    whf.fan_power = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_whole_house_fan_values(default_hpxml_bldg, 5400, 540)
  end

  def test_storage_water_heaters
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-sfa-unit.xml')
    hpxml_bldg.water_heating_systems.each do |wh|
      wh.is_shared_system = true
      wh.number_of_bedrooms_served = 6
      wh.heating_capacity = 15000.0
      wh.tank_volume = 44.0
      wh.recovery_efficiency = 0.95
      wh.location = HPXML::LocationConditionedSpace
      wh.temperature = 111
      wh.uniform_energy_factor = 0.90
      wh.tank_model_type = HPXML::WaterHeaterTankModelTypeStratified
      wh.first_hour_rating = nil
      wh.usage_bin = nil
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_storage_water_heater_values(default_hpxml_bldg,
                                              [true, 15000.0, 44.0, 0.95, HPXML::LocationConditionedSpace, 111, 0.90, HPXML::WaterHeaterTankModelTypeStratified])

    # Test inputs not overridden by defaults w/ Usage Bin
    hpxml_bldg.water_heating_systems.each do |wh|
      wh.usage_bin = HPXML::WaterHeaterUsageBinVerySmall
      wh.first_hour_rating = nil
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_nil(default_hpxml_bldg.water_heating_systems[0].first_hour_rating)
    assert_equal(HPXML::WaterHeaterUsageBinVerySmall, default_hpxml_bldg.water_heating_systems[0].usage_bin)

    # Test inputs not overridden by defaults w/ FHR
    hpxml_bldg.water_heating_systems.each do |wh|
      wh.first_hour_rating = 40
      wh.usage_bin = nil
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_equal(40, default_hpxml_bldg.water_heating_systems[0].first_hour_rating)
    assert_equal(HPXML::WaterHeaterUsageBinLow, default_hpxml_bldg.water_heating_systems[0].usage_bin)

    # Test defaults w/ 3-bedroom house & electric storage water heater
    hpxml_bldg.water_heating_systems.each do |wh|
      wh.is_shared_system = nil
      wh.heating_capacity = nil
      wh.tank_volume = nil
      wh.recovery_efficiency = nil
      wh.location = nil
      wh.temperature = nil
      wh.tank_model_type = nil
      wh.first_hour_rating = nil
      wh.usage_bin = nil
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_storage_water_heater_values(default_hpxml_bldg,
                                              [false, 18766.7, 50.0, 0.98, HPXML::LocationBasementConditioned, 125, 0.9, HPXML::WaterHeaterTankModelTypeMixed])

    # Test defaults w/ 5-bedroom house & electric storage water heater
    hpxml, hpxml_bldg = _create_hpxml('base-enclosure-beds-5.xml')
    hpxml_bldg.water_heating_systems.each do |wh|
      wh.is_shared_system = nil
      wh.heating_capacity = nil
      wh.tank_volume = nil
      wh.recovery_efficiency = nil
      wh.location = nil
      wh.temperature = nil
      wh.tank_model_type = nil
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_storage_water_heater_values(default_hpxml_bldg,
                                              [false, 18766.7, 66.0, 0.98, HPXML::LocationBasementConditioned, 125, 0.94, HPXML::WaterHeaterTankModelTypeMixed])

    # Test defaults w/ 3-bedroom house & 2 storage water heaters (1 electric and 1 natural gas)
    hpxml, hpxml_bldg = _create_hpxml('base-dhw-multiple.xml')
    hpxml_bldg.water_heating_systems.each do |wh|
      wh.is_shared_system = nil
      next unless wh.water_heater_type == HPXML::WaterHeaterTypeStorage

      wh.heating_capacity = nil
      wh.tank_volume = nil
      wh.recovery_efficiency = nil
      wh.location = nil
      wh.temperature = nil
      wh.tank_model_type = nil
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_storage_water_heater_values(default_hpxml_bldg,
                                              [false, 15354.6, 50.0, 0.98, HPXML::LocationBasementConditioned, 125, 0.94, HPXML::WaterHeaterTankModelTypeMixed],
                                              [false, 36000.0, 40.0, 0.757, HPXML::LocationBasementConditioned, 125, 0.59, HPXML::WaterHeaterTankModelTypeMixed])
  end

  def test_tankless_water_heaters
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-dhw-tankless-gas.xml')
    hpxml_bldg.water_heating_systems[0].performance_adjustment = 0.88
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_tankless_water_heater_values(default_hpxml_bldg, [0.88])

    # Test defaults w/ UEF
    hpxml_bldg.water_heating_systems[0].performance_adjustment = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_tankless_water_heater_values(default_hpxml_bldg, [0.94])

    # Test defaults w/ EF
    hpxml_bldg.water_heating_systems[0].uniform_energy_factor = nil
    hpxml_bldg.water_heating_systems[0].energy_factor = 0.93
    hpxml_bldg.water_heating_systems[0].first_hour_rating = 5.7
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_tankless_water_heater_values(default_hpxml_bldg, [0.92])
  end

  def test_heat_pump_water_heaters
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-dhw-tank-heat-pump.xml')
    hpxml_bldg.water_heating_systems[0].tank_volume = 44.0
    hpxml_bldg.water_heating_systems[0].hpwh_operating_mode = HPXML::WaterHeaterHPWHOperatingModeHeatPumpOnly
    hpxml_bldg.water_heating_systems[0].heating_capacity = 4000.0
    hpxml_bldg.water_heating_systems[0].backup_heating_capacity = 5000.0
    hpxml_bldg.water_heating_systems[0].hpwh_confined_space_without_mitigation = true
    hpxml_bldg.water_heating_systems[0].hpwh_containment_volume = 800.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_heat_pump_water_heater_values(default_hpxml_bldg, [44.0, HPXML::WaterHeaterHPWHOperatingModeHeatPumpOnly, 4000.0, 5000.0, true])

    # Test defaults
    hpxml_bldg.water_heating_systems[0].tank_volume = nil
    hpxml_bldg.water_heating_systems[0].hpwh_operating_mode = nil
    hpxml_bldg.water_heating_systems[0].heating_capacity = nil
    hpxml_bldg.water_heating_systems[0].backup_heating_capacity = nil
    hpxml_bldg.water_heating_systems[0].hpwh_confined_space_without_mitigation = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_heat_pump_water_heater_values(default_hpxml_bldg, [66.0, HPXML::WaterHeaterHPWHOperatingModeHybridAuto, 6366.0, 15355.0, false])

    # Test defaults w/ num occupants = 1, num bedrooms = 1
    hpxml_bldg.building_construction.number_of_bedrooms = 1
    hpxml_bldg.building_occupancy.number_of_residents = 1
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_heat_pump_water_heater_values(default_hpxml_bldg, [50.0, HPXML::WaterHeaterHPWHOperatingModeHybridAuto, 6366.0, 15355.0, false])

    # Test defaults w/ num occupants = 10, num bedrooms = 1
    hpxml_bldg.building_construction.number_of_bedrooms = 1
    hpxml_bldg.building_occupancy.number_of_residents = 10
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_heat_pump_water_heater_values(default_hpxml_bldg, [80.0, HPXML::WaterHeaterHPWHOperatingModeHybridAuto, 6366.0, 15355.0, false])
  end

  def test_indirect_water_heaters
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-dhw-indirect.xml')
    hpxml_bldg.water_heating_systems[0].tank_volume = 44.0
    hpxml_bldg.water_heating_systems[0].standby_loss_value = 0.99
    hpxml_bldg.water_heating_systems[0].standby_loss_units = HPXML::UnitsDegFPerHour
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_indirect_water_heater_values(default_hpxml_bldg, [44.0, HPXML::UnitsDegFPerHour, 0.99])

    # Test defaults
    hpxml_bldg.water_heating_systems[0].tank_volume = nil
    hpxml_bldg.water_heating_systems[0].standby_loss_value = nil
    hpxml_bldg.water_heating_systems[0].standby_loss_units = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_indirect_water_heater_values(default_hpxml_bldg, [40.0, HPXML::UnitsDegFPerHour, 0.975])
  end

  def test_hot_water_distribution
    # Test inputs not overridden by defaults -- standard
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.hot_water_distributions[0].pipe_r_value = 2.5
    hpxml_bldg.hot_water_distributions[0].standard_piping_length = 50.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_standard_distribution_values(default_hpxml_bldg.hot_water_distributions[0], 50.0, 2.5)

    # Test inputs not overridden by defaults -- recirculation
    hpxml, hpxml_bldg = _create_hpxml('base-dhw-recirc-demand.xml')
    hpxml_bldg.hot_water_distributions[0].recirculation_pump_power = 65.0
    hpxml_bldg.hot_water_distributions[0].pipe_r_value = 2.5
    hpxml_bldg.hot_water_distributions[0].recirculation_piping_loop_length = 50.0
    hpxml_bldg.hot_water_distributions[0].recirculation_branch_piping_length = 50.0
    hpxml_bldg.hot_water_distributions[0].recirculation_pump_weekday_fractions = ConstantDaySchedule
    hpxml_bldg.hot_water_distributions[0].recirculation_pump_weekend_fractions = ConstantDaySchedule
    hpxml_bldg.hot_water_distributions[0].recirculation_pump_monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_recirc_distribution_values(default_hpxml_bldg.hot_water_distributions[0], 50.0, 50.0, 65.0, 2.5, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test inputs not overridden by defaults -- shared recirculation
    hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit-shared-water-heater-recirc.xml')
    hpxml_bldg.hot_water_distributions[0].shared_recirculation_pump_power = 333.0
    hpxml_bldg.hot_water_distributions[0].recirculation_pump_weekday_fractions = ConstantDaySchedule
    hpxml_bldg.hot_water_distributions[0].recirculation_pump_weekend_fractions = ConstantDaySchedule
    hpxml_bldg.hot_water_distributions[0].recirculation_pump_monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_shared_recirc_distribution_values(default_hpxml_bldg.hot_water_distributions[0], 333.0, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults w/ conditioned basement
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.hot_water_distributions[0].standard_piping_length = nil
    hpxml_bldg.hot_water_distributions[0].pipe_r_value = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_standard_distribution_values(default_hpxml_bldg.hot_water_distributions[0], 93.48, 0.0)

    # Test defaults w/ unconditioned basement
    hpxml, hpxml_bldg = _create_hpxml('base-foundation-unconditioned-basement.xml')
    hpxml_bldg.hot_water_distributions[0].standard_piping_length = nil
    hpxml_bldg.hot_water_distributions[0].pipe_r_value = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_standard_distribution_values(default_hpxml_bldg.hot_water_distributions[0], 88.48, 0.0)

    # Test defaults w/ 2-story building
    hpxml, hpxml_bldg = _create_hpxml('base-enclosure-2stories.xml')
    hpxml_bldg.hot_water_distributions[0].standard_piping_length = nil
    hpxml_bldg.hot_water_distributions[0].pipe_r_value = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_standard_distribution_values(default_hpxml_bldg.hot_water_distributions[0], 103.48, 0.0)

    # Test defaults w/ recirculation & conditioned basement
    hpxml, hpxml_bldg = _create_hpxml('base-dhw-recirc-demand.xml')
    hpxml_bldg.hot_water_distributions[0].recirculation_piping_loop_length = nil
    hpxml_bldg.hot_water_distributions[0].recirculation_branch_piping_length = nil
    hpxml_bldg.hot_water_distributions[0].recirculation_pump_power = nil
    hpxml_bldg.hot_water_distributions[0].pipe_r_value = nil
    hpxml_bldg.hot_water_distributions[0].recirculation_pump_weekday_fractions = nil
    hpxml_bldg.hot_water_distributions[0].recirculation_pump_weekend_fractions = nil
    hpxml_bldg.hot_water_distributions[0].recirculation_pump_monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    default_rc_sched = @default_schedules_csv_data[SchedulesFile::Columns[:HotWaterRecirculationPump].name]
    default_dr_sched = @default_schedules_csv_data["#{SchedulesFile::Columns[:HotWaterRecirculationPump].name}_demand_control"]
    _test_default_recirc_distribution_values(default_hpxml_bldg.hot_water_distributions[0], 166.96, 10.0, 50.0, 0.0, default_dr_sched['RecirculationPumpWeekdayScheduleFractions'], default_dr_sched['RecirculationPumpWeekendScheduleFractions'], default_rc_sched['RecirculationPumpMonthlyScheduleMultipliers'])

    # Test defaults w/ recirculation & unconditioned basement
    hpxml, hpxml_bldg = _create_hpxml('base-foundation-unconditioned-basement.xml')
    hpxml_bldg.hot_water_distributions.clear
    hpxml_bldg.hot_water_distributions.add(id: 'HotWaterDistribution',
                                           system_type: HPXML::DHWDistTypeRecirc,
                                           recirculation_control_type: HPXML::DHWRecircControlTypeSensor)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_recirc_distribution_values(default_hpxml_bldg.hot_water_distributions[0], 156.96, 10.0, 50.0, 0.0, default_dr_sched['RecirculationPumpWeekdayScheduleFractions'], default_dr_sched['RecirculationPumpWeekendScheduleFractions'], default_rc_sched['RecirculationPumpMonthlyScheduleMultipliers'])

    # Test defaults w/ recirculation & 2-story building
    hpxml, hpxml_bldg = _create_hpxml('base-enclosure-2stories.xml')
    hpxml_bldg.hot_water_distributions.clear
    hpxml_bldg.hot_water_distributions.add(id: 'HotWaterDistribution',
                                           system_type: HPXML::DHWDistTypeRecirc,
                                           recirculation_control_type: HPXML::DHWRecircControlTypeSensor)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_recirc_distribution_values(default_hpxml_bldg.hot_water_distributions[0], 186.96, 10.0, 50.0, 0.0, default_dr_sched['RecirculationPumpWeekdayScheduleFractions'], default_dr_sched['RecirculationPumpWeekendScheduleFractions'], default_rc_sched['RecirculationPumpMonthlyScheduleMultipliers'])

    # Test defaults w/ shared recirculation
    hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit-shared-water-heater-recirc.xml')
    hpxml_bldg.hot_water_distributions[0].shared_recirculation_pump_power = nil
    hpxml_bldg.hot_water_distributions[0].recirculation_pump_weekday_fractions = nil
    hpxml_bldg.hot_water_distributions[0].recirculation_pump_weekend_fractions = nil
    hpxml_bldg.hot_water_distributions[0].recirculation_pump_monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    default_ncr_sched = @default_schedules_csv_data["#{SchedulesFile::Columns[:HotWaterRecirculationPump].name}_no_control"]
    _test_default_shared_recirc_distribution_values(default_hpxml_bldg.hot_water_distributions[0], 220.0, default_ncr_sched['RecirculationPumpWeekdayScheduleFractions'], default_ncr_sched['RecirculationPumpWeekendScheduleFractions'], default_rc_sched['RecirculationPumpMonthlyScheduleMultipliers'])
  end

  def test_water_fixtures
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.water_heating.water_fixtures_usage_multiplier = 2.0
    hpxml_bldg.water_heating.water_fixtures_weekday_fractions = ConstantDaySchedule
    hpxml_bldg.water_heating.water_fixtures_weekend_fractions = ConstantDaySchedule
    hpxml_bldg.water_heating.water_fixtures_monthly_multipliers = ConstantMonthSchedule
    hpxml_bldg.water_fixtures[0].low_flow = false
    hpxml_bldg.water_fixtures[0].count = 9
    hpxml_bldg.water_fixtures[1].low_flow = nil
    hpxml_bldg.water_fixtures[1].flow_rate = 99
    hpxml_bldg.water_fixtures[1].count = 8
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_water_fixture_values(default_hpxml_bldg, 2.0, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule, false, false)

    # Test defaults
    hpxml_bldg.water_heating.water_fixtures_usage_multiplier = nil
    hpxml_bldg.water_heating.water_fixtures_weekday_fractions = nil
    hpxml_bldg.water_heating.water_fixtures_weekend_fractions = nil
    hpxml_bldg.water_heating.water_fixtures_monthly_multipliers = nil
    hpxml_bldg.water_fixtures[0].low_flow = true
    hpxml_bldg.water_fixtures[1].flow_rate = 2
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    default_fx_sched = @default_schedules_csv_data[SchedulesFile::Columns[:HotWaterFixtures].name]
    _test_default_water_fixture_values(default_hpxml_bldg, 1.0, default_fx_sched['WaterFixturesWeekdayScheduleFractions'], default_fx_sched['WaterFixturesWeekendScheduleFractions'], default_fx_sched['WaterFixturesMonthlyScheduleMultipliers'], true, true)
  end

  def test_solar_thermal_systems
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-dhw-solar-direct-flat-plate.xml')
    hpxml_bldg.solar_thermal_systems[0].storage_volume = 55.0
    hpxml_bldg.solar_thermal_systems[0].collector_azimuth = 123
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_solar_thermal_values(default_hpxml_bldg.solar_thermal_systems[0], 55.0, 123)

    # Test defaults w/ collector area of 40 sqft
    hpxml_bldg.solar_thermal_systems[0].storage_volume = nil
    hpxml_bldg.solar_thermal_systems[0].collector_orientation = HPXML::OrientationNorth
    hpxml_bldg.solar_thermal_systems[0].collector_azimuth = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_solar_thermal_values(default_hpxml_bldg.solar_thermal_systems[0], 60.0, 0)

    # Test defaults w/ collector area of 100 sqft
    hpxml_bldg.solar_thermal_systems[0].collector_area = 100.0
    hpxml_bldg.solar_thermal_systems[0].storage_volume = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_solar_thermal_values(default_hpxml_bldg.solar_thermal_systems[0], 150.0, 0)
  end

  def test_pv_systems
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-sfa-unit.xml')
    hpxml_bldg.pv_systems.add(id: 'PVSystem',
                              is_shared_system: true,
                              number_of_bedrooms_served: 20,
                              system_losses_fraction: 0.20,
                              location: HPXML::LocationGround,
                              tracking: HPXML::PVTrackingType1Axis,
                              module_type: HPXML::PVModuleTypePremium,
                              array_azimuth: 123,
                              array_tilt: 0,
                              max_power_output: 1000,
                              inverter_idref: 'Inverter')
    hpxml_bldg.inverters.add(id: 'Inverter',
                             inverter_efficiency: 0.90)
    pv = hpxml_bldg.pv_systems[0]
    inv = hpxml_bldg.inverters[0]
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_pv_system_values(default_hpxml_bldg, 0.90, 0.20, true, HPXML::LocationGround, HPXML::PVTrackingType1Axis, HPXML::PVModuleTypePremium, 123)

    # Test defaults w/o year modules manufactured
    pv.is_shared_system = nil
    pv.system_losses_fraction = nil
    pv.location = nil
    pv.tracking = nil
    pv.module_type = nil
    pv.array_orientation = HPXML::OrientationSoutheast
    pv.array_azimuth = nil
    inv.inverter_efficiency = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_pv_system_values(default_hpxml_bldg, 0.96, 0.14, false, HPXML::LocationRoof, HPXML::PVTrackingTypeFixed, HPXML::PVModuleTypeStandard, 135)

    # Test defaults w/ year modules manufactured and no inverter
    pv.year_modules_manufactured = Date.today.year - 10
    inv.delete
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_pv_system_values(default_hpxml_bldg, 0.96, 0.182, false, HPXML::LocationRoof, HPXML::PVTrackingTypeFixed, HPXML::PVModuleTypeStandard, 135)
  end

  def test_electric_panels
    # Test electric panel is never added
    hpxml, _hpxml_bldg = _create_hpxml('base.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_equal(0, default_hpxml_bldg.electric_panels.size)
    hpxml, hpxml_bldg = _create_hpxml('base-detailed-electric-panel.xml')
    hpxml_bldg.electric_panels.clear
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    assert_equal(0, default_hpxml_bldg.electric_panels.size)

    # Test electric panel is not defaulted without calculation types
    hpxml, hpxml_bldg = _create_hpxml('base-detailed-electric-panel.xml')
    hpxml.header.service_feeders_load_calculation_types = []
    hpxml_bldg.electric_panels[0].voltage = nil
    hpxml_bldg.electric_panels[0].max_current_rating = nil
    hpxml_bldg.electric_panels[0].headroom_spaces = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    electric_panel = default_hpxml_bldg.electric_panels[0]
    _test_default_electric_panel_values(electric_panel, nil, nil, nil, nil, 1.0)

    # Test electric panel inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-detailed-electric-panel.xml')
    electric_panel = hpxml_bldg.electric_panels[0]
    electric_panel.voltage = HPXML::ElectricPanelVoltage240
    electric_panel.max_current_rating = 200.0
    electric_panel.headroom_spaces = 5

    # Test branch circuit inputs not overridden by defaults
    branch_circuits = electric_panel.branch_circuits
    branch_circuits.clear
    branch_circuits.add(id: "BranchCircuit#{branch_circuits.size + 1}",
                        voltage: HPXML::ElectricPanelVoltage120,
                        max_current_rating: 20.0,
                        occupied_spaces: 1)
    branch_circuits.add(id: "BranchCircuit#{branch_circuits.size + 1}",
                        voltage: HPXML::ElectricPanelVoltage240,
                        max_current_rating: 50.0,
                        occupied_spaces: 2)
    branch_circuits.add(id: "BranchCircuit#{branch_circuits.size + 1}",
                        voltage: HPXML::ElectricPanelVoltage240,
                        max_current_rating: 50.0,
                        occupied_spaces: 2,
                        component_idrefs: [hpxml_bldg.cooling_systems[0].id])

    # Test service feeder inputs not overridden by defaults
    service_feeders = electric_panel.service_feeders
    htg_load = service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeHeating }
    htg_load.power = 1000
    htg_load.is_new_load = true
    clg_load = service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeCooling }
    clg_load.power = 2000
    clg_load.is_new_load = true
    service_feeders.add(id: "DemandLoad#{service_feeders.size + 1}",
                        type: HPXML::ElectricPanelLoadTypeWaterHeater,
                        power: 3000,
                        is_new_load: true,
                        component_idrefs: [hpxml_bldg.water_heating_systems[0].id])
    service_feeders.add(id: "DemandLoad#{service_feeders.size + 1}",
                        type: HPXML::ElectricPanelLoadTypeClothesDryer,
                        power: 4000,
                        is_new_load: true,
                        component_idrefs: [hpxml_bldg.clothes_dryers[0].id])
    hpxml_bldg.dishwashers.add(id: 'Dishwasher')
    service_feeders.add(id: "DemandLoad#{service_feeders.size + 1}",
                        type: HPXML::ElectricPanelLoadTypeDishwasher,
                        power: 5000,
                        is_new_load: true,
                        component_idrefs: [hpxml_bldg.dishwashers[0].id])
    service_feeders.add(id: "DemandLoad#{service_feeders.size + 1}",
                        type: HPXML::ElectricPanelLoadTypeRangeOven,
                        power: 6000,
                        is_new_load: true,
                        component_idrefs: [hpxml_bldg.cooking_ranges[0].id])
    vf_load = service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeMechVent }
    vf_load.power = 7000
    vf_load.is_new_load = true
    service_feeders.add(id: "DemandLoad#{service_feeders.size + 1}",
                        type: HPXML::ElectricPanelLoadTypeLighting,
                        power: 8000,
                        is_new_load: true)
    service_feeders.add(id: "DemandLoad#{service_feeders.size + 1}",
                        type: HPXML::ElectricPanelLoadTypeKitchen,
                        power: 9000,
                        is_new_load: true)
    service_feeders.add(id: "DemandLoad#{service_feeders.size + 1}",
                        type: HPXML::ElectricPanelLoadTypeLaundry,
                        power: 10000,
                        is_new_load: true)
    oth_load = service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeOther }
    oth_load.power = 11000
    oth_load.is_new_load = true

    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    electric_panel = default_hpxml_bldg.electric_panels[0]
    branch_circuits = electric_panel.branch_circuits
    service_feeders = electric_panel.service_feeders
    _test_default_electric_panel_values(electric_panel, HPXML::ElectricPanelVoltage240, 200.0, 5, 14, 9.0)
    _test_default_branch_circuit_values(branch_circuits[0], HPXML::ElectricPanelVoltage120, 20.0, 1)
    _test_default_branch_circuit_values(branch_circuits[1], HPXML::ElectricPanelVoltage240, 50.0, 2)
    _test_default_branch_circuit_values(branch_circuits[2], HPXML::ElectricPanelVoltage240, 50.0, 2)
    _test_default_service_feeder_values(service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeHeating }, 1000, true)
    _test_default_service_feeder_values(service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeCooling }, 2000, true)
    _test_default_service_feeder_values(service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeWaterHeater }, 3000, true)
    _test_default_service_feeder_values(service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeClothesDryer }, 4000, true)
    _test_default_service_feeder_values(service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeDishwasher }, 5000, true)
    _test_default_service_feeder_values(service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeRangeOven }, 6000, true)
    _test_default_service_feeder_values(service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeMechVent }, 7000, true)
    _test_default_service_feeder_values(service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeLighting }, 8000, true)
    _test_default_service_feeder_values(service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeKitchen }, 9000, true)
    _test_default_service_feeder_values(service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeLaundry }, 10000, true)
    _test_default_service_feeder_values(service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeOther }, 11000, true)

    # Test w/ RatedTotalSpaces instead of HeadroomSpaces
    hpxml_bldg.electric_panels[0].headroom_spaces = nil
    hpxml_bldg.electric_panels[0].rated_total_spaces = 12
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    electric_panel = default_hpxml_bldg.electric_panels[0]
    _test_default_electric_panel_values(electric_panel, HPXML::ElectricPanelVoltage240, 200.0, 3, 12, 9.0)

    # Test defaults
    electric_panel = hpxml_bldg.electric_panels[0]
    electric_panel.voltage = nil
    electric_panel.max_current_rating = nil
    electric_panel.headroom_spaces = nil
    electric_panel.rated_total_spaces = nil
    electric_panel.branch_circuits.each do |branch_circuit|
      branch_circuit.voltage = nil
      branch_circuit.max_current_rating = nil
      branch_circuit.occupied_spaces = nil
    end
    electric_panel.service_feeders.each do |service_feeder|
      service_feeder.power = nil
      service_feeder.is_new_load = nil
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    electric_panel = default_hpxml_bldg.electric_panels[0]
    branch_circuits = electric_panel.branch_circuits
    service_feeders = electric_panel.service_feeders
    _test_default_electric_panel_values(electric_panel, HPXML::ElectricPanelVoltage240, 200.0, 3, 9, 6.0)
    _test_default_branch_circuit_values(branch_circuits[0], HPXML::ElectricPanelVoltage120, 15.0, 0)
    _test_default_branch_circuit_values(branch_circuits[1], HPXML::ElectricPanelVoltage120, 15.0, 0)
    _test_default_branch_circuit_values(branch_circuits[2], HPXML::ElectricPanelVoltage240, 50.0, 2)
    _test_default_service_feeder_values(service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeHeating }, 499.5, false)
    _test_default_service_feeder_values(service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeCooling }, 3383.5, false)
    _test_default_service_feeder_values(service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeWaterHeater }, 0.0, false)
    _test_default_service_feeder_values(service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeClothesDryer }, 0.0, false)
    _test_default_service_feeder_values(service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeDishwasher }, 1200.0, false)
    _test_default_service_feeder_values(service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeRangeOven }, 0.0, false)
    _test_default_service_feeder_values(service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeMechVent }, 30.0, false)
    _test_default_service_feeder_values(service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeLighting }, 3684.0, false)
    _test_default_service_feeder_values(service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeKitchen }, 3000.0, false)
    _test_default_service_feeder_values(service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeLaundry }, 1500.0, false)
    _test_default_service_feeder_values(service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeOther }, 0, false)
  end

  def test_batteries
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-pv-battery.xml')
    hpxml_bldg.batteries[0].nominal_capacity_kwh = 45.0
    hpxml_bldg.batteries[0].nominal_capacity_ah = nil
    hpxml_bldg.batteries[0].usable_capacity_kwh = 34.0
    hpxml_bldg.batteries[0].usable_capacity_ah = nil
    hpxml_bldg.batteries[0].rated_power_output = 1234.0
    hpxml_bldg.batteries[0].location = HPXML::LocationBasementConditioned
    hpxml_bldg.batteries[0].round_trip_efficiency = 0.9
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_battery_values(default_hpxml_bldg.batteries[0], 45.0, nil, 34.0, nil, 1234.0, HPXML::LocationBasementConditioned, 0.9)

    # Test w/ Ah instead of kWh
    hpxml_bldg.batteries[0].nominal_capacity_kwh = nil
    hpxml_bldg.batteries[0].nominal_capacity_ah = 987.0
    hpxml_bldg.batteries[0].usable_capacity_kwh = nil
    hpxml_bldg.batteries[0].usable_capacity_ah = 876.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_battery_values(default_hpxml_bldg.batteries[0], nil, 987.0, nil, 876.0, 1234.0, HPXML::LocationBasementConditioned, 0.9)

    # Test defaults
    hpxml_bldg.batteries[0].nominal_capacity_kwh = nil
    hpxml_bldg.batteries[0].nominal_capacity_ah = nil
    hpxml_bldg.batteries[0].usable_capacity_kwh = nil
    hpxml_bldg.batteries[0].usable_capacity_ah = nil
    hpxml_bldg.batteries[0].rated_power_output = nil
    hpxml_bldg.batteries[0].location = nil
    hpxml_bldg.batteries[0].round_trip_efficiency = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_battery_values(default_hpxml_bldg.batteries[0], 10.0, nil, 9.0, nil, 5000.0, HPXML::LocationOutside, 0.925)

    # Test defaults w/ nominal kWh
    hpxml_bldg.batteries[0].nominal_capacity_kwh = 14.0
    hpxml_bldg.batteries[0].nominal_capacity_ah = nil
    hpxml_bldg.batteries[0].usable_capacity_kwh = nil
    hpxml_bldg.batteries[0].usable_capacity_ah = nil
    hpxml_bldg.batteries[0].rated_power_output = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_battery_values(default_hpxml_bldg.batteries[0], 14.0, nil, 12.6, nil, 7000.0, HPXML::LocationOutside, 0.925)

    # Test defaults w/ usable kWh
    hpxml_bldg.batteries[0].nominal_capacity_kwh = nil
    hpxml_bldg.batteries[0].nominal_capacity_ah = nil
    hpxml_bldg.batteries[0].usable_capacity_kwh = 12.0
    hpxml_bldg.batteries[0].usable_capacity_ah = nil
    hpxml_bldg.batteries[0].rated_power_output = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_battery_values(default_hpxml_bldg.batteries[0], 13.33, nil, 12.0, nil, 6665.0, HPXML::LocationOutside, 0.925)

    # Test defaults w/ nominal Ah
    hpxml_bldg.batteries[0].nominal_capacity_kwh = nil
    hpxml_bldg.batteries[0].nominal_capacity_ah = 280.0
    hpxml_bldg.batteries[0].usable_capacity_kwh = nil
    hpxml_bldg.batteries[0].usable_capacity_ah = nil
    hpxml_bldg.batteries[0].rated_power_output = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_battery_values(default_hpxml_bldg.batteries[0], nil, 280.0, nil, 252.0, 7000.0, HPXML::LocationOutside, 0.925)

    # Test defaults w/ usable Ah
    hpxml_bldg.batteries[0].nominal_capacity_kwh = nil
    hpxml_bldg.batteries[0].nominal_capacity_ah = nil
    hpxml_bldg.batteries[0].usable_capacity_kwh = nil
    hpxml_bldg.batteries[0].usable_capacity_ah = 240.0
    hpxml_bldg.batteries[0].rated_power_output = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_battery_values(default_hpxml_bldg.batteries[0], nil, 266.67, nil, 240.0, 6667.0, HPXML::LocationOutside, 0.925)

    # Test defaults w/ rated power output
    hpxml_bldg.batteries[0].nominal_capacity_kwh = nil
    hpxml_bldg.batteries[0].nominal_capacity_ah = nil
    hpxml_bldg.batteries[0].usable_capacity_kwh = nil
    hpxml_bldg.batteries[0].usable_capacity_ah = nil
    hpxml_bldg.batteries[0].rated_power_output = 10000.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_battery_values(default_hpxml_bldg.batteries[0], 20.0, nil, 18.0, nil, 10000.0, HPXML::LocationOutside, 0.925)

    # Test defaults w/ garage
    hpxml, hpxml_bldg = _create_hpxml('base-pv-battery-garage.xml')
    hpxml_bldg.batteries[0].nominal_capacity_kwh = nil
    hpxml_bldg.batteries[0].nominal_capacity_ah = nil
    hpxml_bldg.batteries[0].usable_capacity_kwh = nil
    hpxml_bldg.batteries[0].usable_capacity_ah = nil
    hpxml_bldg.batteries[0].rated_power_output = nil
    hpxml_bldg.batteries[0].location = nil
    hpxml_bldg.batteries[0].round_trip_efficiency = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_battery_values(default_hpxml_bldg.batteries[0], 10.0, nil, 9.0, nil, 5000.0, HPXML::LocationGarage, 0.925)
  end

  def test_vehicles
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-vehicle-ev-charger.xml')
    hpxml_bldg.vehicles[0].battery_type = HPXML::BatteryTypeLithiumIon
    hpxml_bldg.vehicles[0].nominal_capacity_kwh = 45.0
    hpxml_bldg.vehicles[0].nominal_capacity_ah = nil
    hpxml_bldg.vehicles[0].usable_capacity_kwh = 34.0
    hpxml_bldg.vehicles[0].usable_capacity_ah = nil
    hpxml_bldg.vehicles[0].miles_per_year = 5000
    hpxml_bldg.vehicles[0].hours_per_week = 10
    hpxml_bldg.vehicles[0].fuel_economy_combined = 0.18
    hpxml_bldg.vehicles[0].fuel_economy_units = HPXML::UnitsKwhPerMile
    hpxml_bldg.vehicles[0].fraction_charged_home = 0.75
    hpxml_bldg.vehicles[0].ev_usage_multiplier = 1.5
    hpxml_bldg.vehicles[0].ev_weekday_fractions = ConstantDaySchedule
    hpxml_bldg.vehicles[0].ev_weekend_fractions = ConstantDaySchedule
    hpxml_bldg.vehicles[0].ev_monthly_multipliers = ConstantMonthSchedule
    hpxml_bldg.ev_chargers[0].charging_level = 3
    hpxml_bldg.ev_chargers[0].charging_power = 99
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_vehicle_values(default_hpxml_bldg.vehicles[0], default_hpxml_bldg.ev_chargers[0], HPXML::BatteryTypeLithiumIon, 45.0, nil, 34.0, nil, 5000, 10, 0.18, HPXML::UnitsKwhPerMile, 0.75, 1.5, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule, 3, 99)

    # Test w/ Ah instead of kWh
    hpxml_bldg.vehicles[0].nominal_capacity_kwh = nil
    hpxml_bldg.vehicles[0].nominal_capacity_ah = 987.0
    hpxml_bldg.vehicles[0].usable_capacity_kwh = nil
    hpxml_bldg.vehicles[0].usable_capacity_ah = 876.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_vehicle_values(default_hpxml_bldg.vehicles[0], default_hpxml_bldg.ev_chargers[0], HPXML::BatteryTypeLithiumIon, nil, 987.0, nil, 876.0, 5000, 10, 0.18, HPXML::UnitsKwhPerMile, 0.75, 1.5, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule, 3, 99)

    # Test w/ mile/kWh
    hpxml_bldg.vehicles[0].fuel_economy_combined = 5.55
    hpxml_bldg.vehicles[0].fuel_economy_units = HPXML::UnitsMilePerKwh
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_vehicle_values(default_hpxml_bldg.vehicles[0], default_hpxml_bldg.ev_chargers[0], HPXML::BatteryTypeLithiumIon, nil, 987.0, nil, 876.0, 5000, 10, 5.55, HPXML::UnitsMilePerKwh, 0.75, 1.5, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule, 3, 99)

    # Test w/ mpge
    hpxml_bldg.vehicles[0].fuel_economy_combined = 107.0
    hpxml_bldg.vehicles[0].fuel_economy_units = HPXML::UnitsMPGe
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_vehicle_values(default_hpxml_bldg.vehicles[0], default_hpxml_bldg.ev_chargers[0], HPXML::BatteryTypeLithiumIon, nil, 987.0, nil, 876.0, 5000, 10, 107, HPXML::UnitsMPGe, 0.75, 1.5, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule, 3, 99)

    # Test defaults
    hpxml, hpxml_bldg = _create_hpxml('base-vehicle-ev-charger.xml')
    hpxml_bldg.vehicles[0].nominal_capacity_kwh = nil
    hpxml_bldg.vehicles[0].nominal_capacity_ah = nil
    hpxml_bldg.vehicles[0].usable_capacity_kwh = nil
    hpxml_bldg.vehicles[0].usable_capacity_ah = nil
    hpxml_bldg.vehicles[0].miles_per_year = nil
    hpxml_bldg.vehicles[0].hours_per_week = nil
    hpxml_bldg.vehicles[0].fuel_economy_combined = nil
    hpxml_bldg.vehicles[0].fuel_economy_units = nil
    hpxml_bldg.vehicles[0].fraction_charged_home = nil
    hpxml_bldg.vehicles[0].ev_usage_multiplier = nil
    hpxml_bldg.vehicles[0].ev_weekday_fractions = nil
    hpxml_bldg.vehicles[0].ev_weekend_fractions = nil
    hpxml_bldg.vehicles[0].ev_monthly_multipliers = nil
    hpxml_bldg.ev_chargers[0].charging_level = nil
    hpxml_bldg.ev_chargers[0].charging_power = nil
    default_ev_sch = @default_schedules_csv_data[SchedulesFile::Columns[:ElectricVehicle].name]

    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_vehicle_values(default_hpxml_bldg.vehicles[0], default_hpxml_bldg.ev_chargers[0], HPXML::BatteryTypeLithiumIon, 63.0, nil, 50.4, nil, 11000, 9.6, 0.22, HPXML::UnitsKwhPerMile, 0.8, 1.0, default_ev_sch['WeekdayScheduleFractions'], default_ev_sch['WeekendScheduleFractions'], default_ev_sch['MonthlyScheduleMultipliers'], 2, 5690)

    # Test defaults w/ nominal kWh
    hpxml_bldg.vehicles[0].nominal_capacity_kwh = 45.0
    hpxml_bldg.vehicles[0].nominal_capacity_ah = nil
    hpxml_bldg.vehicles[0].usable_capacity_kwh = nil
    hpxml_bldg.vehicles[0].usable_capacity_ah = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_vehicle_values(default_hpxml_bldg.vehicles[0], default_hpxml_bldg.ev_chargers[0], HPXML::BatteryTypeLithiumIon, 45.0, nil, 36.0, nil, 11000, 9.6, 0.22, HPXML::UnitsKwhPerMile, 0.8, 1.0, default_ev_sch['WeekdayScheduleFractions'], default_ev_sch['WeekendScheduleFractions'], default_ev_sch['MonthlyScheduleMultipliers'], 2, 5690)

    # Test defaults w/ usable kWh
    hpxml_bldg.vehicles[0].nominal_capacity_kwh = nil
    hpxml_bldg.vehicles[0].nominal_capacity_ah = nil
    hpxml_bldg.vehicles[0].usable_capacity_kwh = 36.0
    hpxml_bldg.vehicles[0].usable_capacity_ah = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_vehicle_values(default_hpxml_bldg.vehicles[0], default_hpxml_bldg.ev_chargers[0], HPXML::BatteryTypeLithiumIon, 45.0, nil, 36.0, nil, 11000, 9.6, 0.22, HPXML::UnitsKwhPerMile, 0.8, 1.0, default_ev_sch['WeekdayScheduleFractions'], default_ev_sch['WeekendScheduleFractions'], default_ev_sch['MonthlyScheduleMultipliers'], 2, 5690)

    # Test defaults w/ nominal Ah
    hpxml_bldg.vehicles[0].nominal_capacity_kwh = nil
    hpxml_bldg.vehicles[0].nominal_capacity_ah = 280.0
    hpxml_bldg.vehicles[0].usable_capacity_kwh = nil
    hpxml_bldg.vehicles[0].usable_capacity_ah = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_vehicle_values(default_hpxml_bldg.vehicles[0], default_hpxml_bldg.ev_chargers[0], HPXML::BatteryTypeLithiumIon, nil, 280.0, nil, 224.0, 11000, 9.6, 0.22, HPXML::UnitsKwhPerMile, 0.8, 1.0, default_ev_sch['WeekdayScheduleFractions'], default_ev_sch['WeekendScheduleFractions'], default_ev_sch['MonthlyScheduleMultipliers'], 2, 5690)

    # Test defaults w/ usable Ah
    hpxml_bldg.vehicles[0].nominal_capacity_kwh = nil
    hpxml_bldg.vehicles[0].nominal_capacity_ah = nil
    hpxml_bldg.vehicles[0].usable_capacity_kwh = nil
    hpxml_bldg.vehicles[0].usable_capacity_ah = 224.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_vehicle_values(default_hpxml_bldg.vehicles[0], default_hpxml_bldg.ev_chargers[0], HPXML::BatteryTypeLithiumIon, nil, 280.0, nil, 224.0, 11000, 9.6, 0.22, HPXML::UnitsKwhPerMile, 0.8, 1.0, default_ev_sch['WeekdayScheduleFractions'], default_ev_sch['WeekendScheduleFractions'], default_ev_sch['MonthlyScheduleMultipliers'], 2, 5690)

    # Test defaults w/ miles/year
    hpxml_bldg.vehicles[0].miles_per_year = 5000
    hpxml_bldg.vehicles[0].usable_capacity_ah = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_vehicle_values(default_hpxml_bldg.vehicles[0], default_hpxml_bldg.ev_chargers[0], HPXML::BatteryTypeLithiumIon, 63.0, nil, 50.4, nil, 5000, 4.36, 0.22, HPXML::UnitsKwhPerMile, 0.8, 1.0, default_ev_sch['WeekdayScheduleFractions'], default_ev_sch['WeekendScheduleFractions'], default_ev_sch['MonthlyScheduleMultipliers'], 2, 5690)

    # Test defaults w/ hours/week
    hpxml_bldg.vehicles[0].miles_per_year = nil
    hpxml_bldg.vehicles[0].hours_per_week = 5.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_vehicle_values(default_hpxml_bldg.vehicles[0], default_hpxml_bldg.ev_chargers[0], HPXML::BatteryTypeLithiumIon, 63.0, nil, 50.4, nil, 5737.0, 5.0, 0.22, HPXML::UnitsKwhPerMile, 0.8, 1.0, default_ev_sch['WeekdayScheduleFractions'], default_ev_sch['WeekendScheduleFractions'], default_ev_sch['MonthlyScheduleMultipliers'], 2, 5690)

    # Test defaults w/ Level 1 charger
    hpxml_bldg.ev_chargers[0].charging_level = 1
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_vehicle_values(default_hpxml_bldg.vehicles[0], default_hpxml_bldg.ev_chargers[0], HPXML::BatteryTypeLithiumIon, 63.0, nil, 50.4, nil, 5737.0, 5.0, 0.22, HPXML::UnitsKwhPerMile, 0.8, 1.0, default_ev_sch['WeekdayScheduleFractions'], default_ev_sch['WeekendScheduleFractions'], default_ev_sch['MonthlyScheduleMultipliers'], 1, 1600)

    # Test defaults w/ charging power
    hpxml_bldg.ev_chargers[0].charging_level = nil
    hpxml_bldg.ev_chargers[0].charging_power = 3500
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_vehicle_values(default_hpxml_bldg.vehicles[0], default_hpxml_bldg.ev_chargers[0], HPXML::BatteryTypeLithiumIon, 63.0, nil, 50.4, nil, 5737.0, 5.0, 0.22, HPXML::UnitsKwhPerMile, 0.8, 1.0, default_ev_sch['WeekdayScheduleFractions'], default_ev_sch['WeekendScheduleFractions'], default_ev_sch['MonthlyScheduleMultipliers'], nil, 3500,)

    # Test defaults w/ schedule file
    hpxml, hpxml_bldg = _create_hpxml('base-vehicle-ev-charger-scheduled.xml')
    hpxml_bldg.vehicles[0].nominal_capacity_kwh = nil
    hpxml_bldg.vehicles[0].nominal_capacity_ah = nil
    hpxml_bldg.vehicles[0].usable_capacity_kwh = nil
    hpxml_bldg.vehicles[0].usable_capacity_ah = nil
    hpxml_bldg.vehicles[0].miles_per_year = nil
    hpxml_bldg.vehicles[0].hours_per_week = nil
    hpxml_bldg.vehicles[0].fuel_economy_combined = nil
    hpxml_bldg.vehicles[0].fuel_economy_units = nil
    hpxml_bldg.vehicles[0].fraction_charged_home = nil
    hpxml_bldg.vehicles[0].ev_weekday_fractions = nil
    hpxml_bldg.vehicles[0].ev_weekend_fractions = nil
    hpxml_bldg.vehicles[0].ev_monthly_multipliers = nil
    hpxml_bldg.ev_chargers[0].charging_level = nil
    hpxml_bldg.ev_chargers[0].charging_power = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_vehicle_values(default_hpxml_bldg.vehicles[0], default_hpxml_bldg.ev_chargers[0], HPXML::BatteryTypeLithiumIon, 63.0, nil, 50.4, nil, 11000, 9.6, 0.22, HPXML::UnitsKwhPerMile, 0.8, 1.0, nil, nil, nil, 2, 5690)
  end

  def test_generators
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-sfa-unit.xml')
    hpxml_bldg.generators.add(id: 'Generator',
                              is_shared_system: true,
                              number_of_bedrooms_served: 20,
                              fuel_type: HPXML::FuelTypeNaturalGas,
                              annual_consumption_kbtu: 8500,
                              annual_output_kwh: 500)
    generator = hpxml_bldg.generators[0]
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_generator_values(default_hpxml_bldg, true)

    # Test defaults
    generator.is_shared_system = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_generator_values(default_hpxml_bldg, false)
  end

  def test_clothes_washers
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-sfa-unit.xml')
    hpxml_bldg.water_heating_systems[0].is_shared_system = true
    hpxml_bldg.water_heating_systems[0].number_of_bedrooms_served = 18
    hpxml_bldg.clothes_washers[0].location = HPXML::LocationBasementConditioned
    hpxml_bldg.clothes_washers[0].is_shared_appliance = true
    hpxml_bldg.clothes_washers[0].usage_multiplier = 1.5
    hpxml_bldg.clothes_washers[0].water_heating_system_idref = hpxml_bldg.water_heating_systems[0].id
    hpxml_bldg.clothes_washers[0].weekday_fractions = ConstantDaySchedule
    hpxml_bldg.clothes_washers[0].weekend_fractions = ConstantDaySchedule
    hpxml_bldg.clothes_washers[0].monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_clothes_washer_values(default_hpxml_bldg.clothes_washers[0], true, HPXML::LocationBasementConditioned, 1.21, 380.0, 0.12, 1.09, 27.0, 3.2, 6.0, 1.5, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hpxml_bldg.clothes_washers[0].is_shared_appliance = nil
    hpxml_bldg.clothes_washers[0].location = nil
    hpxml_bldg.clothes_washers[0].integrated_modified_energy_factor = nil
    hpxml_bldg.clothes_washers[0].rated_annual_kwh = nil
    hpxml_bldg.clothes_washers[0].label_electric_rate = nil
    hpxml_bldg.clothes_washers[0].label_gas_rate = nil
    hpxml_bldg.clothes_washers[0].label_annual_gas_cost = nil
    hpxml_bldg.clothes_washers[0].capacity = nil
    hpxml_bldg.clothes_washers[0].label_usage = nil
    hpxml_bldg.clothes_washers[0].usage_multiplier = nil
    hpxml_bldg.clothes_washers[0].weekday_fractions = nil
    hpxml_bldg.clothes_washers[0].weekend_fractions = nil
    hpxml_bldg.clothes_washers[0].monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    default_cw_sched = @default_schedules_csv_data[SchedulesFile::Columns[:ClothesWasher].name]
    _test_default_clothes_washer_values(default_hpxml_bldg.clothes_washers[0], false, HPXML::LocationConditionedSpace, 1.0, 400.0, 0.12, 1.09, 27.0, 3.0, 6.0, 1.0, default_cw_sched['WeekdayScheduleFractions'], default_cw_sched['WeekendScheduleFractions'], default_cw_sched['MonthlyScheduleMultipliers'])

    # Test defaults before 301-2019 Addendum A
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml.header.eri_calculation_versions = ['2019']
    hpxml_bldg.clothes_washers[0].is_shared_appliance = nil
    hpxml_bldg.clothes_washers[0].location = nil
    hpxml_bldg.clothes_washers[0].integrated_modified_energy_factor = nil
    hpxml_bldg.clothes_washers[0].rated_annual_kwh = nil
    hpxml_bldg.clothes_washers[0].label_electric_rate = nil
    hpxml_bldg.clothes_washers[0].label_gas_rate = nil
    hpxml_bldg.clothes_washers[0].label_annual_gas_cost = nil
    hpxml_bldg.clothes_washers[0].capacity = nil
    hpxml_bldg.clothes_washers[0].label_usage = nil
    hpxml_bldg.clothes_washers[0].usage_multiplier = nil
    hpxml_bldg.clothes_washers[0].weekday_fractions = nil
    hpxml_bldg.clothes_washers[0].weekend_fractions = nil
    hpxml_bldg.clothes_washers[0].monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_clothes_washer_values(default_hpxml_bldg.clothes_washers[0], false, HPXML::LocationConditionedSpace, 0.331, 704.0, 0.08, 0.58, 23.0, 2.874, 999, 1.0, default_cw_sched['WeekdayScheduleFractions'], default_cw_sched['WeekendScheduleFractions'], default_cw_sched['MonthlyScheduleMultipliers'])
  end

  def test_clothes_dryers
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-sfa-unit.xml')
    hpxml_bldg.water_heating_systems[0].is_shared_system = true
    hpxml_bldg.water_heating_systems[0].number_of_bedrooms_served = 18
    hpxml_bldg.clothes_dryers[0].location = HPXML::LocationBasementConditioned
    hpxml_bldg.clothes_dryers[0].is_shared_appliance = true
    hpxml_bldg.clothes_dryers[0].combined_energy_factor = 3.33
    hpxml_bldg.clothes_dryers[0].usage_multiplier = 1.1
    hpxml_bldg.clothes_dryers[0].weekday_fractions = ConstantDaySchedule
    hpxml_bldg.clothes_dryers[0].weekend_fractions = ConstantDaySchedule
    hpxml_bldg.clothes_dryers[0].monthly_multipliers = ConstantMonthSchedule
    hpxml_bldg.clothes_dryers[0].is_vented = false
    hpxml_bldg.clothes_dryers[0].drying_method = HPXML::DryingMethodOther
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_clothes_dryer_values(default_hpxml_bldg.clothes_dryers[0], true, HPXML::LocationBasementConditioned, 3.33, 1.1, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule, HPXML::DryingMethodOther, false)

    # Test defaults w/ electric condensing clothes dryer
    hpxml_bldg.clothes_dryers[0].location = nil
    hpxml_bldg.clothes_dryers[0].is_shared_appliance = nil
    hpxml_bldg.clothes_dryers[0].combined_energy_factor = nil
    hpxml_bldg.clothes_dryers[0].usage_multiplier = nil
    hpxml_bldg.clothes_dryers[0].weekday_fractions = nil
    hpxml_bldg.clothes_dryers[0].weekend_fractions = nil
    hpxml_bldg.clothes_dryers[0].monthly_multipliers = nil
    hpxml_bldg.clothes_dryers[0].is_vented = nil
    hpxml_bldg.clothes_dryers[0].drying_method = HPXML::DryingMethodCondensing
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    default_cd_sched = @default_schedules_csv_data[SchedulesFile::Columns[:ClothesDryer].name]
    _test_default_clothes_dryer_values(default_hpxml_bldg.clothes_dryers[0], false, HPXML::LocationConditionedSpace, 3.01, 1.0, default_cd_sched['WeekdayScheduleFractions'], default_cd_sched['WeekendScheduleFractions'], default_cd_sched['MonthlyScheduleMultipliers'], HPXML::DryingMethodCondensing, false)

    # Test defaults w/ unspecified electric clothes dryer
    hpxml_bldg.clothes_dryers[0].drying_method = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_clothes_dryer_values(default_hpxml_bldg.clothes_dryers[0], false, HPXML::LocationConditionedSpace, 3.01, 1.0, default_cd_sched['WeekdayScheduleFractions'], default_cd_sched['WeekendScheduleFractions'], default_cd_sched['MonthlyScheduleMultipliers'], HPXML::DryingMethodConventional, true)

    # Test defaults w/ gas clothes dryer
    hpxml_bldg.clothes_dryers[0].fuel_type = HPXML::FuelTypeNaturalGas
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_clothes_dryer_values(default_hpxml_bldg.clothes_dryers[0], false, HPXML::LocationConditionedSpace, 3.01, 1.0, default_cd_sched['WeekdayScheduleFractions'], default_cd_sched['WeekendScheduleFractions'], default_cd_sched['MonthlyScheduleMultipliers'], HPXML::DryingMethodConventional, true)

    # Test defaults w/ electric clothes dryer before 301-2019 Addendum A
    hpxml.header.eri_calculation_versions = ['2019']
    hpxml_bldg.clothes_dryers[0].fuel_type = HPXML::FuelTypeElectricity
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_clothes_dryer_values(default_hpxml_bldg.clothes_dryers[0], false, HPXML::LocationConditionedSpace, 2.62, 1.0, default_cd_sched['WeekdayScheduleFractions'], default_cd_sched['WeekendScheduleFractions'], default_cd_sched['MonthlyScheduleMultipliers'], HPXML::DryingMethodConventional, true)

    # Test defaults w/ gas clothes dryer before 301-2019 Addendum A
    hpxml_bldg.clothes_dryers[0].fuel_type = HPXML::FuelTypeNaturalGas
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_clothes_dryer_values(default_hpxml_bldg.clothes_dryers[0], false, HPXML::LocationConditionedSpace, 2.32, 1.0, default_cd_sched['WeekdayScheduleFractions'], default_cd_sched['WeekendScheduleFractions'], default_cd_sched['MonthlyScheduleMultipliers'], HPXML::DryingMethodConventional, true)
  end

  def test_clothes_dryer_exhaust
    # Test inputs not overridden by defaults w/ vented dryer
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    clothes_dryer = hpxml_bldg.clothes_dryers[0]
    clothes_dryer.is_vented = true
    clothes_dryer.vented_flow_rate = 200
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_clothes_dryer_exhaust_values(default_hpxml_bldg.clothes_dryers[0], true, 200)

    # Test inputs not overridden by defaults w/ unvented dryer
    clothes_dryer.is_vented = false
    clothes_dryer.vented_flow_rate = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_clothes_dryer_exhaust_values(default_hpxml_bldg.clothes_dryers[0], false, nil)

    # Test defaults
    clothes_dryer.is_vented = nil
    clothes_dryer.vented_flow_rate = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_clothes_dryer_exhaust_values(default_hpxml_bldg.clothes_dryers[0], true, 100)
  end

  def test_dishwashers
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-sfa-unit.xml')
    hpxml_bldg.water_heating_systems[0].is_shared_system = true
    hpxml_bldg.water_heating_systems[0].number_of_bedrooms_served = 18
    hpxml_bldg.dishwashers[0].location = HPXML::LocationBasementConditioned
    hpxml_bldg.dishwashers[0].is_shared_appliance = true
    hpxml_bldg.dishwashers[0].usage_multiplier = 1.3
    hpxml_bldg.dishwashers[0].water_heating_system_idref = hpxml_bldg.water_heating_systems[0].id
    hpxml_bldg.dishwashers[0].weekday_fractions = ConstantDaySchedule
    hpxml_bldg.dishwashers[0].weekend_fractions = ConstantDaySchedule
    hpxml_bldg.dishwashers[0].monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_dishwasher_values(default_hpxml_bldg.dishwashers[0], true, HPXML::LocationBasementConditioned, 307.0, 0.12, 1.09, 22.32, 4.0, 12, 1.3, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hpxml_bldg.dishwashers[0].is_shared_appliance = nil
    hpxml_bldg.dishwashers[0].location = nil
    hpxml_bldg.dishwashers[0].rated_annual_kwh = nil
    hpxml_bldg.dishwashers[0].label_electric_rate = nil
    hpxml_bldg.dishwashers[0].label_gas_rate = nil
    hpxml_bldg.dishwashers[0].label_annual_gas_cost = nil
    hpxml_bldg.dishwashers[0].label_usage = nil
    hpxml_bldg.dishwashers[0].place_setting_capacity = nil
    hpxml_bldg.dishwashers[0].usage_multiplier = nil
    hpxml_bldg.dishwashers[0].weekday_fractions = nil
    hpxml_bldg.dishwashers[0].weekend_fractions = nil
    hpxml_bldg.dishwashers[0].monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    default_dw_sched = @default_schedules_csv_data[SchedulesFile::Columns[:Dishwasher].name]
    _test_default_dishwasher_values(default_hpxml_bldg.dishwashers[0], false, HPXML::LocationConditionedSpace, 467.0, 0.12, 1.09, 33.12, 4.0, 12, 1.0, default_dw_sched['WeekdayScheduleFractions'], default_dw_sched['WeekendScheduleFractions'], default_dw_sched['MonthlyScheduleMultipliers'])

    # Test defaults before 301-2019 Addendum A
    hpxml.header.eri_calculation_versions = ['2019']
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_dishwasher_values(default_hpxml_bldg.dishwashers[0], false, HPXML::LocationConditionedSpace, 467.0, 999, 999, 999, 999, 12, 1.0, default_dw_sched['WeekdayScheduleFractions'], default_dw_sched['WeekendScheduleFractions'], default_dw_sched['MonthlyScheduleMultipliers'])
  end

  def test_refrigerators
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.refrigerators[0].location = HPXML::LocationBasementConditioned
    hpxml_bldg.refrigerators[0].usage_multiplier = 1.2
    hpxml_bldg.refrigerators[0].weekday_fractions = nil
    hpxml_bldg.refrigerators[0].weekend_fractions = nil
    hpxml_bldg.refrigerators[0].monthly_multipliers = nil
    hpxml_bldg.refrigerators[0].constant_coefficients = ConstantDaySchedule
    hpxml_bldg.refrigerators[0].temperature_coefficients = ConstantDaySchedule
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_refrigerator_values(default_hpxml_bldg, HPXML::LocationBasementConditioned, 650.0, 1.2, nil, nil, nil, ConstantDaySchedule, ConstantDaySchedule)

    # Test inputs not overridden by defaults 2
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.refrigerators[0].location = HPXML::LocationBasementConditioned
    hpxml_bldg.refrigerators[0].usage_multiplier = 1.2
    hpxml_bldg.refrigerators[0].weekday_fractions = ConstantDaySchedule
    hpxml_bldg.refrigerators[0].weekend_fractions = ConstantDaySchedule
    hpxml_bldg.refrigerators[0].monthly_multipliers = ConstantMonthSchedule
    hpxml_bldg.refrigerators[0].constant_coefficients = nil
    hpxml_bldg.refrigerators[0].temperature_coefficients = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_refrigerator_values(default_hpxml_bldg, HPXML::LocationBasementConditioned, 650.0, 1.2, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule, nil, nil)

    # Test defaults
    hpxml_bldg.refrigerators[0].location = nil
    hpxml_bldg.refrigerators[0].rated_annual_kwh = nil
    hpxml_bldg.refrigerators[0].usage_multiplier = nil
    hpxml_bldg.refrigerators[0].weekday_fractions = nil
    hpxml_bldg.refrigerators[0].weekend_fractions = ConstantDaySchedule
    hpxml_bldg.refrigerators[0].monthly_multipliers = nil
    hpxml_bldg.refrigerators[0].constant_coefficients = nil
    hpxml_bldg.refrigerators[0].temperature_coefficients = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    default_rf_sched = @default_schedules_csv_data[SchedulesFile::Columns[:Refrigerator].name]
    _test_default_refrigerator_values(default_hpxml_bldg, HPXML::LocationConditionedSpace, 691.0, 1.0, default_rf_sched['WeekdayScheduleFractions'], ConstantDaySchedule, default_rf_sched['MonthlyScheduleMultipliers'], nil, nil)

    # Test defaults 2
    hpxml_bldg.refrigerators[0].location = nil
    hpxml_bldg.refrigerators[0].rated_annual_kwh = nil
    hpxml_bldg.refrigerators[0].usage_multiplier = nil
    hpxml_bldg.refrigerators[0].weekday_fractions = nil
    hpxml_bldg.refrigerators[0].weekend_fractions = nil
    hpxml_bldg.refrigerators[0].monthly_multipliers = nil
    hpxml_bldg.refrigerators[0].constant_coefficients = nil
    hpxml_bldg.refrigerators[0].temperature_coefficients = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_refrigerator_values(default_hpxml_bldg, HPXML::LocationConditionedSpace, 691.0, 1.0, nil, nil, nil, default_rf_sched['ConstantScheduleCoefficients'], default_rf_sched['TemperatureScheduleCoefficients'])

    # Test defaults w/ refrigerator in 5-bedroom house
    hpxml_bldg.building_construction.number_of_bedrooms = 5
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_refrigerator_values(default_hpxml_bldg, HPXML::LocationConditionedSpace, 727.0, 1.0, nil, nil, nil, default_rf_sched['ConstantScheduleCoefficients'], default_rf_sched['TemperatureScheduleCoefficients'])

    # Test defaults before 301-2019 Addendum A
    hpxml.header.eri_calculation_versions = ['2019']
    hpxml_bldg.building_construction.number_of_bedrooms = 3
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_refrigerator_values(default_hpxml_bldg, HPXML::LocationConditionedSpace, 691.0, 1.0, nil, nil, nil, default_rf_sched['ConstantScheduleCoefficients'], default_rf_sched['TemperatureScheduleCoefficients'])
  end

  def test_extra_refrigerators
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-misc-loads-large-uncommon.xml')
    hpxml_bldg.refrigerators.each do |refrigerator|
      refrigerator.location = HPXML::LocationConditionedSpace
      refrigerator.rated_annual_kwh = 333.0
      refrigerator.usage_multiplier = 1.5
      refrigerator.weekday_fractions = nil
      refrigerator.weekend_fractions = nil
      refrigerator.monthly_multipliers = nil
      refrigerator.constant_coefficients = ConstantDaySchedule
      refrigerator.temperature_coefficients = ConstantDaySchedule
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_extra_refrigerators_values(default_hpxml_bldg, HPXML::LocationConditionedSpace, 333.0, 1.5, nil, nil, nil, ConstantDaySchedule, ConstantDaySchedule)

    # Test inputs not overridden by defaults 2
    hpxml, hpxml_bldg = _create_hpxml('base-misc-loads-large-uncommon.xml')
    hpxml_bldg.refrigerators.each do |refrigerator|
      refrigerator.location = HPXML::LocationConditionedSpace
      refrigerator.rated_annual_kwh = 333.0
      refrigerator.usage_multiplier = 1.5
      refrigerator.weekday_fractions = ConstantDaySchedule
      refrigerator.weekend_fractions = ConstantDaySchedule
      refrigerator.monthly_multipliers = ConstantMonthSchedule
      refrigerator.constant_coefficients = nil
      refrigerator.temperature_coefficients = nil
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_extra_refrigerators_values(default_hpxml_bldg, HPXML::LocationConditionedSpace, 333.0, 1.5, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule, nil, nil)

    # Test defaults
    hpxml_bldg.refrigerators.each do |refrigerator|
      refrigerator.location = nil
      refrigerator.rated_annual_kwh = nil
      refrigerator.usage_multiplier = nil
      refrigerator.weekday_fractions = nil
      refrigerator.weekend_fractions = nil
      refrigerator.monthly_multipliers = nil
      refrigerator.constant_coefficients = nil
      refrigerator.temperature_coefficients = nil
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    default_ef_sched = @default_schedules_csv_data[SchedulesFile::Columns[:ExtraRefrigerator].name]
    _test_default_extra_refrigerators_values(default_hpxml_bldg, HPXML::LocationBasementConditioned, 244.0, 1.0, nil, nil, nil, default_ef_sched['ConstantScheduleCoefficients'], default_ef_sched['TemperatureScheduleCoefficients'])
  end

  def test_freezers
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-misc-loads-large-uncommon.xml')
    hpxml_bldg.freezers.each do |freezer|
      freezer.location = HPXML::LocationConditionedSpace
      freezer.rated_annual_kwh = 333.0
      freezer.usage_multiplier = 1.5
      freezer.weekday_fractions = ConstantDaySchedule
      freezer.weekend_fractions = ConstantDaySchedule
      freezer.monthly_multipliers = ConstantMonthSchedule
      freezer.constant_coefficients = nil
      freezer.temperature_coefficients = nil
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_freezers_values(default_hpxml_bldg, HPXML::LocationConditionedSpace, 333.0, 1.5, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule, nil, nil)

    # Test inputs not overridden by defaults 2
    hpxml, hpxml_bldg = _create_hpxml('base-misc-loads-large-uncommon.xml')
    hpxml_bldg.freezers.each do |freezer|
      freezer.location = HPXML::LocationConditionedSpace
      freezer.rated_annual_kwh = 333.0
      freezer.usage_multiplier = 1.5
      freezer.weekday_fractions = nil
      freezer.weekend_fractions = nil
      freezer.monthly_multipliers = nil
      freezer.constant_coefficients = ConstantDaySchedule
      freezer.temperature_coefficients = ConstantDaySchedule
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_freezers_values(default_hpxml_bldg, HPXML::LocationConditionedSpace, 333.0, 1.5, nil, nil, nil, ConstantDaySchedule, ConstantDaySchedule)

    # Test defaults
    hpxml_bldg.freezers.each do |freezer|
      freezer.location = nil
      freezer.rated_annual_kwh = nil
      freezer.usage_multiplier = nil
      freezer.weekday_fractions = nil
      freezer.weekend_fractions = nil
      freezer.monthly_multipliers = nil
      freezer.constant_coefficients = nil
      freezer.temperature_coefficients = nil
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    default_fz_sched = @default_schedules_csv_data[SchedulesFile::Columns[:Freezer].name]
    _test_default_freezers_values(default_hpxml_bldg, HPXML::LocationBasementConditioned, 320.0, 1.0, default_fz_sched['WeekdayScheduleFractions'], default_fz_sched['WeekendScheduleFractions'], default_fz_sched['MonthlyScheduleMultipliers'], nil, nil)
  end

  def test_cooking_ranges
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.cooking_ranges[0].location = HPXML::LocationBasementConditioned
    hpxml_bldg.cooking_ranges[0].is_induction = true
    hpxml_bldg.cooking_ranges[0].usage_multiplier = 1.1
    hpxml_bldg.cooking_ranges[0].weekday_fractions = ConstantDaySchedule
    hpxml_bldg.cooking_ranges[0].weekend_fractions = ConstantDaySchedule
    hpxml_bldg.cooking_ranges[0].monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_cooking_range_values(default_hpxml_bldg.cooking_ranges[0], HPXML::LocationBasementConditioned, true, 1.1, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hpxml_bldg.cooking_ranges[0].location = nil
    hpxml_bldg.cooking_ranges[0].is_induction = nil
    hpxml_bldg.cooking_ranges[0].usage_multiplier = nil
    hpxml_bldg.cooking_ranges[0].weekday_fractions = nil
    hpxml_bldg.cooking_ranges[0].weekend_fractions = nil
    hpxml_bldg.cooking_ranges[0].monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    defult_cr_sched = @default_schedules_csv_data[SchedulesFile::Columns[:CookingRange].name]
    _test_default_cooking_range_values(default_hpxml_bldg.cooking_ranges[0], HPXML::LocationConditionedSpace, false, 1.0, defult_cr_sched['WeekdayScheduleFractions'], defult_cr_sched['WeekendScheduleFractions'], defult_cr_sched['MonthlyScheduleMultipliers'])

    # Test defaults before 301-2019 Addendum A
    hpxml.header.eri_calculation_versions = ['2019']
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_cooking_range_values(default_hpxml_bldg.cooking_ranges[0], HPXML::LocationConditionedSpace, false, 1.0, defult_cr_sched['WeekdayScheduleFractions'], defult_cr_sched['WeekendScheduleFractions'], defult_cr_sched['MonthlyScheduleMultipliers'])
  end

  def test_ovens
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.ovens[0].is_convection = true
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_oven_values(default_hpxml_bldg.ovens[0], true)

    # Test defaults
    hpxml_bldg.ovens[0].is_convection = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_oven_values(default_hpxml_bldg.ovens[0], false)

    # Test defaults before 301-2019 Addendum A
    hpxml.header.eri_calculation_versions = ['2019']
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_oven_values(default_hpxml_bldg.ovens[0], false)
  end

  def test_lighting
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.lighting.interior_usage_multiplier = 2.0
    hpxml_bldg.lighting.garage_usage_multiplier = 2.0
    hpxml_bldg.lighting.exterior_usage_multiplier = 2.0
    hpxml_bldg.lighting.interior_weekday_fractions = ConstantDaySchedule
    hpxml_bldg.lighting.interior_weekend_fractions = ConstantDaySchedule
    hpxml_bldg.lighting.interior_monthly_multipliers = ConstantMonthSchedule
    hpxml_bldg.lighting.exterior_weekday_fractions = ConstantDaySchedule
    hpxml_bldg.lighting.exterior_weekend_fractions = ConstantDaySchedule
    hpxml_bldg.lighting.exterior_monthly_multipliers = ConstantMonthSchedule
    hpxml_bldg.lighting.garage_weekday_fractions = ConstantDaySchedule
    hpxml_bldg.lighting.garage_weekend_fractions = ConstantDaySchedule
    hpxml_bldg.lighting.garage_monthly_multipliers = ConstantMonthSchedule
    hpxml_bldg.lighting.holiday_exists = true
    hpxml_bldg.lighting.holiday_kwh_per_day = 0.7
    hpxml_bldg.lighting.holiday_period_begin_month = 10
    hpxml_bldg.lighting.holiday_period_begin_day = 19
    hpxml_bldg.lighting.holiday_period_end_month = 12
    hpxml_bldg.lighting.holiday_period_end_day = 31
    hpxml_bldg.lighting.holiday_weekday_fractions = ConstantDaySchedule
    hpxml_bldg.lighting.holiday_weekend_fractions = ConstantDaySchedule
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_lighting_values(default_hpxml_bldg, 2.0, 2.0, 2.0,
                                  { int_wk_sch: ConstantDaySchedule,
                                    int_wknd_sch: ConstantDaySchedule,
                                    int_month_mult: ConstantMonthSchedule,
                                    ext_wk_sch: ConstantDaySchedule,
                                    ext_wknd_sch: ConstantDaySchedule,
                                    ext_month_mult: ConstantMonthSchedule,
                                    grg_wk_sch: ConstantDaySchedule,
                                    grg_wknd_sch: ConstantDaySchedule,
                                    grg_month_mult: ConstantMonthSchedule,
                                    hol_kwh_per_day: 0.7,
                                    hol_begin_month: 10,
                                    hol_begin_day: 19,
                                    hol_end_month: 12,
                                    hol_end_day: 31,
                                    hol_wk_sch: ConstantDaySchedule,
                                    hol_wknd_sch: ConstantDaySchedule })

    # Test defaults
    hpxml_bldg.lighting.interior_usage_multiplier = nil
    hpxml_bldg.lighting.garage_usage_multiplier = nil
    hpxml_bldg.lighting.exterior_usage_multiplier = nil
    hpxml_bldg.lighting.interior_weekday_fractions = nil
    hpxml_bldg.lighting.interior_weekend_fractions = nil
    hpxml_bldg.lighting.interior_monthly_multipliers = nil
    hpxml_bldg.lighting.exterior_weekday_fractions = nil
    hpxml_bldg.lighting.exterior_weekend_fractions = nil
    hpxml_bldg.lighting.exterior_monthly_multipliers = nil
    hpxml_bldg.lighting.garage_weekday_fractions = nil
    hpxml_bldg.lighting.garage_weekend_fractions = nil
    hpxml_bldg.lighting.garage_monthly_multipliers = nil
    hpxml_bldg.lighting.holiday_exists = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    default_il_sched = @default_schedules_csv_data[SchedulesFile::Columns[:LightingInterior].name]
    default_el_sched = @default_schedules_csv_data[SchedulesFile::Columns[:LightingExterior].name]
    _test_default_lighting_values(default_hpxml_bldg, 1.0, 1.0, 1.0,
                                  { int_wk_sch: default_il_sched['InteriorWeekdayScheduleFractions'],
                                    int_wknd_sch: default_il_sched['InteriorWeekendScheduleFractions'],
                                    int_month_mult: default_il_sched['InteriorMonthlyScheduleMultipliers'],
                                    ext_wk_sch: default_el_sched['ExteriorWeekdayScheduleFractions'],
                                    ext_wknd_sch: default_el_sched['ExteriorWeekdayScheduleFractions'],
                                    ext_month_mult: default_el_sched['ExteriorMonthlyScheduleMultipliers'] })

    # Test defaults w/ holiday lighting
    hpxml_bldg.lighting.holiday_exists = true
    hpxml_bldg.lighting.holiday_kwh_per_day = nil
    hpxml_bldg.lighting.holiday_period_begin_month = nil
    hpxml_bldg.lighting.holiday_period_begin_day = nil
    hpxml_bldg.lighting.holiday_period_end_month = nil
    hpxml_bldg.lighting.holiday_period_end_day = nil
    hpxml_bldg.lighting.holiday_weekday_fractions = nil
    hpxml_bldg.lighting.holiday_weekend_fractions = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    default_hl_sched = @default_schedules_csv_data[SchedulesFile::Columns[:LightingExteriorHoliday].name]
    _test_default_lighting_values(default_hpxml_bldg, 1.0, 1.0, 1.0,
                                  { int_wk_sch: default_il_sched['InteriorWeekdayScheduleFractions'],
                                    int_wknd_sch: default_il_sched['InteriorWeekendScheduleFractions'],
                                    int_month_mult: default_il_sched['InteriorMonthlyScheduleMultipliers'],
                                    ext_wk_sch: default_el_sched['ExteriorWeekdayScheduleFractions'],
                                    ext_wknd_sch: default_el_sched['ExteriorWeekdayScheduleFractions'],
                                    ext_month_mult: default_el_sched['ExteriorMonthlyScheduleMultipliers'],
                                    hol_kwh_per_day: 1.1,
                                    hol_begin_month: 11,
                                    hol_begin_day: 24,
                                    hol_end_month: 1,
                                    hol_end_day: 6,
                                    hol_wk_sch: default_hl_sched['WeekdayScheduleFractions'],
                                    hol_wknd_sch: default_hl_sched['WeekendScheduleFractions'] })
    # Test defaults w/ garage
    hpxml, hpxml_bldg = _create_hpxml('base-enclosure-garage.xml')
    hpxml_bldg.lighting.interior_usage_multiplier = nil
    hpxml_bldg.lighting.garage_usage_multiplier = nil
    hpxml_bldg.lighting.exterior_usage_multiplier = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    default_gl_sched = @default_schedules_csv_data[SchedulesFile::Columns[:LightingGarage].name]
    _test_default_lighting_values(default_hpxml_bldg, 1.0, 1.0, 1.0,
                                  { int_wk_sch: default_il_sched['InteriorWeekdayScheduleFractions'],
                                    int_wknd_sch: default_il_sched['InteriorWeekendScheduleFractions'],
                                    int_month_mult: default_il_sched['InteriorMonthlyScheduleMultipliers'],
                                    ext_wk_sch: default_el_sched['ExteriorWeekdayScheduleFractions'],
                                    ext_wknd_sch: default_el_sched['ExteriorWeekdayScheduleFractions'],
                                    ext_month_mult: default_el_sched['ExteriorMonthlyScheduleMultipliers'],
                                    grg_wk_sch: default_gl_sched['GarageWeekdayScheduleFractions'],
                                    grg_wknd_sch: default_gl_sched['GarageWeekendScheduleFractions'],
                                    grg_month_mult: default_gl_sched['GarageMonthlyScheduleMultipliers'] })
  end

  def test_ceiling_fans
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-lighting-ceiling-fans.xml')
    hpxml_bldg.ceiling_fans[0].count = 2
    hpxml_bldg.ceiling_fans[0].efficiency = 100
    hpxml_bldg.ceiling_fans[0].label_energy_use = 39
    hpxml_bldg.ceiling_fans[0].weekday_fractions = ConstantDaySchedule
    hpxml_bldg.ceiling_fans[0].weekend_fractions = ConstantDaySchedule
    hpxml_bldg.ceiling_fans[0].monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_ceiling_fan_values(default_hpxml_bldg.ceiling_fans[0], 2, 100, 39, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test inputs not overridden by defaults 2
    hpxml_bldg.ceiling_fans[0].label_energy_use = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_ceiling_fan_values(default_hpxml_bldg.ceiling_fans[0], 2, 100, nil, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test inputs not overridden by defaults 3
    hpxml_bldg.ceiling_fans[0].efficiency = nil
    hpxml_bldg.ceiling_fans[0].label_energy_use = 39
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_ceiling_fan_values(default_hpxml_bldg.ceiling_fans[0], 2, nil, 39, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hpxml_bldg.ceiling_fans.each do |ceiling_fan|
      ceiling_fan.count = nil
      ceiling_fan.efficiency = nil
      ceiling_fan.label_energy_use = nil
      ceiling_fan.weekday_fractions = nil
      ceiling_fan.weekend_fractions = nil
      ceiling_fan.monthly_multipliers = nil
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    default_cf_sched = @default_schedules_csv_data[SchedulesFile::Columns[:CeilingFan].name]
    _test_default_ceiling_fan_values(default_hpxml_bldg.ceiling_fans[0], 4, nil, 42.6, default_cf_sched['WeekdayScheduleFractions'], default_cf_sched['WeekendScheduleFractions'], '0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0')
  end

  def test_pools
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-misc-loads-large-uncommon.xml')
    pool = hpxml_bldg.pools[0]
    pool.heater_load_units = HPXML::UnitsKwhPerYear
    pool.heater_load_value = 1000
    pool.heater_usage_multiplier = 1.4
    pool.heater_weekday_fractions = ConstantDaySchedule
    pool.heater_weekend_fractions = ConstantDaySchedule
    pool.heater_monthly_multipliers = ConstantMonthSchedule
    pool.pump_kwh_per_year = 3000
    pool.pump_usage_multiplier = 1.3
    pool.pump_weekday_fractions = ConstantDaySchedule
    pool.pump_weekend_fractions = ConstantDaySchedule
    pool.pump_monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_pool_heater_values(default_hpxml_bldg.pools[0], HPXML::UnitsKwhPerYear, 1000, 1.4, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)
    _test_default_pool_pump_values(default_hpxml_bldg.pools[0], 3000, 1.3, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    pool = hpxml_bldg.pools[0]
    pool.heater_load_units = nil
    pool.heater_load_value = nil
    pool.heater_usage_multiplier = nil
    pool.heater_weekday_fractions = nil
    pool.heater_weekend_fractions = nil
    pool.heater_monthly_multipliers = nil
    pool.pump_kwh_per_year = nil
    pool.pump_usage_multiplier = nil
    pool.pump_weekday_fractions = nil
    pool.pump_weekend_fractions = nil
    pool.pump_monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    default_ph_sched = @default_schedules_csv_data[SchedulesFile::Columns[:PoolHeater].name]
    default_pp_sched = @default_schedules_csv_data[SchedulesFile::Columns[:PoolPump].name]
    _test_default_pool_heater_values(default_hpxml_bldg.pools[0], HPXML::UnitsThermPerYear, 236, 1.0, default_ph_sched['WeekdayScheduleFractions'], default_ph_sched['WeekendScheduleFractions'], default_ph_sched['MonthlyScheduleMultipliers'])
    _test_default_pool_pump_values(default_hpxml_bldg.pools[0], 2496, 1.0, default_pp_sched['WeekdayScheduleFractions'], default_pp_sched['WeekendScheduleFractions'], default_pp_sched['MonthlyScheduleMultipliers'])

    # Test defaults 2
    hpxml, hpxml_bldg = _create_hpxml('base-misc-loads-large-uncommon2.xml')
    pool = hpxml_bldg.pools[0]
    pool.heater_load_units = nil
    pool.heater_load_value = nil
    pool.heater_usage_multiplier = nil
    pool.heater_weekday_fractions = nil
    pool.heater_weekend_fractions = nil
    pool.heater_monthly_multipliers = nil
    pool.pump_kwh_per_year = nil
    pool.pump_usage_multiplier = nil
    pool.pump_weekday_fractions = nil
    pool.pump_weekend_fractions = nil
    pool.pump_monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_pool_heater_values(default_hpxml_bldg.pools[0], nil, nil, nil, nil, nil, nil)
    _test_default_pool_pump_values(default_hpxml_bldg.pools[0], 2496, 1.0, default_pp_sched['WeekdayScheduleFractions'], default_pp_sched['WeekendScheduleFractions'], default_pp_sched['MonthlyScheduleMultipliers'])
  end

  def test_permanent_spas
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-misc-loads-large-uncommon.xml')
    spa = hpxml_bldg.permanent_spas[0]
    spa.heater_load_units = HPXML::UnitsThermPerYear
    spa.heater_load_value = 1000
    spa.heater_usage_multiplier = 0.8
    spa.heater_weekday_fractions = ConstantDaySchedule
    spa.heater_weekend_fractions = ConstantDaySchedule
    spa.heater_monthly_multipliers = ConstantMonthSchedule
    spa.pump_kwh_per_year = 3000
    spa.pump_usage_multiplier = 0.7
    spa.pump_weekday_fractions = ConstantDaySchedule
    spa.pump_weekend_fractions = ConstantDaySchedule
    spa.pump_monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_permanent_spa_heater_values(default_hpxml_bldg.permanent_spas[0], HPXML::UnitsThermPerYear, 1000, 0.8, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)
    _test_default_permanent_spa_pump_values(default_hpxml_bldg.permanent_spas[0], 3000, 0.7, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    spa = hpxml_bldg.permanent_spas[0]
    spa.heater_load_units = nil
    spa.heater_load_value = nil
    spa.heater_usage_multiplier = nil
    spa.heater_weekday_fractions = nil
    spa.heater_weekend_fractions = nil
    spa.heater_monthly_multipliers = nil
    spa.pump_kwh_per_year = nil
    spa.pump_usage_multiplier = nil
    spa.pump_weekday_fractions = nil
    spa.pump_weekend_fractions = nil
    spa.pump_monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    default_sh_sched = @default_schedules_csv_data[SchedulesFile::Columns[:PermanentSpaHeater].name]
    default_sp_sched = @default_schedules_csv_data[SchedulesFile::Columns[:PermanentSpaPump].name]
    _test_default_permanent_spa_heater_values(default_hpxml_bldg.permanent_spas[0], HPXML::UnitsKwhPerYear, 1125, 1.0, default_sh_sched['WeekdayScheduleFractions'], default_sh_sched['WeekendScheduleFractions'], default_sh_sched['MonthlyScheduleMultipliers'])
    _test_default_permanent_spa_pump_values(default_hpxml_bldg.permanent_spas[0], 1111, 1.0, default_sp_sched['WeekdayScheduleFractions'], default_sp_sched['WeekendScheduleFractions'], default_sp_sched['MonthlyScheduleMultipliers'])

    # Test defaults 2
    hpxml, hpxml_bldg = _create_hpxml('base-misc-loads-large-uncommon2.xml')
    spa = hpxml_bldg.permanent_spas[0]
    spa.heater_load_units = nil
    spa.heater_load_value = nil
    spa.heater_usage_multiplier = nil
    spa.heater_weekday_fractions = nil
    spa.heater_weekend_fractions = nil
    spa.heater_monthly_multipliers = nil
    spa.pump_kwh_per_year = nil
    spa.pump_usage_multiplier = nil
    spa.pump_weekday_fractions = nil
    spa.pump_weekend_fractions = nil
    spa.pump_monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_permanent_spa_heater_values(default_hpxml_bldg.permanent_spas[0], HPXML::UnitsKwhPerYear, 225, 1.0, default_sh_sched['WeekdayScheduleFractions'], default_sh_sched['WeekendScheduleFractions'], default_sh_sched['MonthlyScheduleMultipliers'])
    _test_default_permanent_spa_pump_values(default_hpxml_bldg.permanent_spas[0], 1111, 1.0, default_sp_sched['WeekdayScheduleFractions'], default_sp_sched['WeekendScheduleFractions'], default_sp_sched['MonthlyScheduleMultipliers'])
  end

  def test_plug_loads
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-misc-loads-large-uncommon.xml')
    tv_pl = hpxml_bldg.plug_loads.find { |pl| pl.plug_load_type == HPXML::PlugLoadTypeTelevision }
    tv_pl.kwh_per_year = 1000
    tv_pl.usage_multiplier = 1.1
    tv_pl.frac_sensible = 0.6
    tv_pl.frac_latent = 0.3
    tv_pl.weekday_fractions = ConstantDaySchedule
    tv_pl.weekend_fractions = ConstantDaySchedule
    tv_pl.monthly_multipliers = ConstantMonthSchedule
    other_pl = hpxml_bldg.plug_loads.find { |pl| pl.plug_load_type == HPXML::PlugLoadTypeOther }
    other_pl.kwh_per_year = 2000
    other_pl.usage_multiplier = 1.2
    other_pl.frac_sensible = 0.5
    other_pl.frac_latent = 0.4
    other_pl.weekday_fractions = ConstantDaySchedule
    other_pl.weekend_fractions = ConstantDaySchedule
    other_pl.monthly_multipliers = ConstantMonthSchedule
    veh_pl = hpxml_bldg.plug_loads.find { |pl| pl.plug_load_type == HPXML::PlugLoadTypeElectricVehicleCharging }
    veh_pl.kwh_per_year = 4000
    veh_pl.usage_multiplier = 1.3
    veh_pl.frac_sensible = 0.4
    veh_pl.frac_latent = 0.5
    veh_pl.weekday_fractions = ConstantDaySchedule
    veh_pl.weekend_fractions = ConstantDaySchedule
    veh_pl.monthly_multipliers = ConstantMonthSchedule
    wellpump_pl = hpxml_bldg.plug_loads.find { |pl| pl.plug_load_type == HPXML::PlugLoadTypeWellPump }
    wellpump_pl.kwh_per_year = 3000
    wellpump_pl.usage_multiplier = 1.4
    wellpump_pl.frac_sensible = 0.3
    wellpump_pl.frac_latent = 0.6
    wellpump_pl.weekday_fractions = ConstantDaySchedule
    wellpump_pl.weekend_fractions = ConstantDaySchedule
    wellpump_pl.monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_plug_load_values(default_hpxml_bldg, HPXML::PlugLoadTypeTelevision, 1000, 0.6, 0.3, 1.1, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)
    _test_default_plug_load_values(default_hpxml_bldg, HPXML::PlugLoadTypeOther, 2000, 0.5, 0.4, 1.2, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)
    _test_default_plug_load_values(default_hpxml_bldg, HPXML::PlugLoadTypeElectricVehicleCharging, 4000, 0.4, 0.5, 1.3, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)
    _test_default_plug_load_values(default_hpxml_bldg, HPXML::PlugLoadTypeWellPump, 3000, 0.3, 0.6, 1.4, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hpxml_bldg.plug_loads.each do |plug_load|
      plug_load.kwh_per_year = nil
      plug_load.usage_multiplier = nil
      plug_load.frac_sensible = nil
      plug_load.frac_latent = nil
      plug_load.weekday_fractions = nil
      plug_load.weekend_fractions = nil
      plug_load.monthly_multipliers = nil
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    default_tv_sched = @default_schedules_csv_data[SchedulesFile::Columns[:PlugLoadsTV].name]
    default_ot_sched = @default_schedules_csv_data[SchedulesFile::Columns[:PlugLoadsOther].name]
    default_ev_sched = @default_schedules_csv_data[SchedulesFile::Columns[:PlugLoadsVehicle].name]
    default_wp_sched = @default_schedules_csv_data[SchedulesFile::Columns[:PlugLoadsWellPump].name]
    _test_default_plug_load_values(default_hpxml_bldg, HPXML::PlugLoadTypeTelevision, 620, 1.0, 0.0, 1.0, default_tv_sched['WeekdayScheduleFractions'], default_tv_sched['WeekendScheduleFractions'], default_tv_sched['MonthlyScheduleMultipliers'])
    _test_default_plug_load_values(default_hpxml_bldg, HPXML::PlugLoadTypeOther, 2457, 0.855, 0.045, 1.0, default_ot_sched['WeekdayScheduleFractions'], default_ot_sched['WeekendScheduleFractions'], default_ot_sched['MonthlyScheduleMultipliers'])
    _test_default_plug_load_values(default_hpxml_bldg, HPXML::PlugLoadTypeElectricVehicleCharging, 2368.4, 0.0, 0.0, 1.0, default_ev_sched['WeekdayScheduleFractions'], default_ev_sched['WeekendScheduleFractions'], default_ev_sched['MonthlyScheduleMultipliers'])
    _test_default_plug_load_values(default_hpxml_bldg, HPXML::PlugLoadTypeWellPump, 441, 0.0, 0.0, 1.0, default_wp_sched['WeekdayScheduleFractions'], default_wp_sched['WeekendScheduleFractions'], default_wp_sched['MonthlyScheduleMultipliers'])
  end

  def test_fuel_loads
    # Test inputs not overridden by defaults
    hpxml, hpxml_bldg = _create_hpxml('base-misc-loads-large-uncommon.xml')
    gg_fl = hpxml_bldg.fuel_loads.find { |fl| fl.fuel_load_type == HPXML::FuelLoadTypeGrill }
    gg_fl.therm_per_year = 1000
    gg_fl.usage_multiplier = 0.9
    gg_fl.frac_sensible = 0.6
    gg_fl.frac_latent = 0.3
    gg_fl.weekday_fractions = ConstantDaySchedule
    gg_fl.weekend_fractions = ConstantDaySchedule
    gg_fl.monthly_multipliers = ConstantMonthSchedule
    gl_fl = hpxml_bldg.fuel_loads.find { |fl| fl.fuel_load_type == HPXML::FuelLoadTypeLighting }
    gl_fl.therm_per_year = 2000
    gl_fl.usage_multiplier = 0.8
    gl_fl.frac_sensible = 0.5
    gl_fl.frac_latent = 0.4
    gl_fl.weekday_fractions = ConstantDaySchedule
    gl_fl.weekend_fractions = ConstantDaySchedule
    gl_fl.monthly_multipliers = ConstantMonthSchedule
    gf_fl = hpxml_bldg.fuel_loads.find { |fl| fl.fuel_load_type == HPXML::FuelLoadTypeFireplace }
    gf_fl.therm_per_year = 3000
    gf_fl.usage_multiplier = 0.7
    gf_fl.frac_sensible = 0.4
    gf_fl.frac_latent = 0.5
    gf_fl.weekday_fractions = ConstantDaySchedule
    gf_fl.weekend_fractions = ConstantDaySchedule
    gf_fl.monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    _test_default_fuel_load_values(default_hpxml_bldg, HPXML::FuelLoadTypeGrill, 1000, 0.6, 0.3, 0.9, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)
    _test_default_fuel_load_values(default_hpxml_bldg, HPXML::FuelLoadTypeLighting, 2000, 0.5, 0.4, 0.8, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)
    _test_default_fuel_load_values(default_hpxml_bldg, HPXML::FuelLoadTypeFireplace, 3000, 0.4, 0.5, 0.7, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hpxml_bldg.fuel_loads.each do |fuel_load|
      fuel_load.therm_per_year = nil
      fuel_load.usage_multiplier = nil
      fuel_load.frac_sensible = nil
      fuel_load.frac_latent = nil
      fuel_load.weekday_fractions = nil
      fuel_load.weekend_fractions = nil
      fuel_load.monthly_multipliers = nil
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _default_hpxml, default_hpxml_bldg = _test_measure()
    default_gr_sched = @default_schedules_csv_data[SchedulesFile::Columns[:FuelLoadsGrill].name]
    default_li_sched = @default_schedules_csv_data[SchedulesFile::Columns[:FuelLoadsLighting].name]
    default_fp_sched = @default_schedules_csv_data[SchedulesFile::Columns[:FuelLoadsFireplace].name]
    _test_default_fuel_load_values(default_hpxml_bldg, HPXML::FuelLoadTypeGrill, 33, 0.0, 0.0, 1.0, default_gr_sched['WeekdayScheduleFractions'], default_gr_sched['WeekendScheduleFractions'], default_gr_sched['MonthlyScheduleMultipliers'])
    _test_default_fuel_load_values(default_hpxml_bldg, HPXML::FuelLoadTypeLighting, 20, 0.0, 0.0, 1.0, default_li_sched['WeekdayScheduleFractions'], default_li_sched['WeekendScheduleFractions'], default_li_sched['MonthlyScheduleMultipliers'])
    _test_default_fuel_load_values(default_hpxml_bldg, HPXML::FuelLoadTypeFireplace, 67, 0.5, 0.1, 1.0, default_fp_sched['WeekdayScheduleFractions'], default_fp_sched['WeekendScheduleFractions'], default_fp_sched['MonthlyScheduleMultipliers'])
  end

  def _test_measure()
    # create an instance of the measure
    measure = HPXMLtoOpenStudio.new

    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if @args_hash.has_key?(arg.name)
        assert(temp_arg_var.setValue(@args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    result.showOutput() unless result.value.valueName == 'Success'

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)

    hpxml_defaults_path = File.join(File.dirname(__FILE__), 'in.xml')
    if @args_hash['hpxml_path'] == @tmp_hpxml_path
      # Since there is a penalty to performing schema/schematron validation, we only do it for custom models
      # Sample files already have their in.xml's checked in the workflow tests
      schema_validator = @schema_validator
      schematron_validator = @schematron_validator
    else
      schema_validator = nil
      schematron_validator = nil
    end
    hpxml = HPXML.new(hpxml_path: hpxml_defaults_path, schema_validator: schema_validator, schematron_validator: schematron_validator)
    if not hpxml.errors.empty?
      puts 'ERRORS:'
      hpxml.errors.each do |error|
        puts error
      end
      flunk "Validation error(s) in #{hpxml_defaults_path}."
    end

    File.delete(hpxml_defaults_path)

    return hpxml, hpxml.buildings[0]
  end

  def _test_default_header_values(hpxml, tstep, sim_begin_month, sim_begin_day, sim_end_month, sim_end_day, sim_calendar_year, temperature_capacitance_multiplier,
                                  unavailable_period_begin_hour, unavailable_period_end_hour, unavailable_period_natvent_availability)
    assert_equal(tstep, hpxml.header.timestep)
    assert_equal(sim_begin_month, hpxml.header.sim_begin_month)
    assert_equal(sim_begin_day, hpxml.header.sim_begin_day)
    assert_equal(sim_end_month, hpxml.header.sim_end_month)
    assert_equal(sim_end_day, hpxml.header.sim_end_day)
    assert_equal(sim_calendar_year, hpxml.header.sim_calendar_year)
    assert_equal(temperature_capacitance_multiplier, hpxml.header.temperature_capacitance_multiplier)
    if unavailable_period_begin_hour.nil? && unavailable_period_end_hour.nil? && unavailable_period_natvent_availability.nil?
      assert_equal(0, hpxml.header.unavailable_periods.size)
    else
      assert_equal(unavailable_period_begin_hour, hpxml.header.unavailable_periods[-1].begin_hour)
      assert_equal(unavailable_period_end_hour, hpxml.header.unavailable_periods[-1].end_hour)
      assert_equal(unavailable_period_natvent_availability, hpxml.header.unavailable_periods[-1].natvent_availability)
    end
  end

  def _test_default_emissions_values(scenario, elec_schedule_number_of_header_rows, elec_schedule_column_number,
                                     natural_gas_units, natural_gas_value, propane_units, propane_value,
                                     fuel_oil_units, fuel_oil_value, coal_units, coal_value, wood_units, wood_value,
                                     wood_pellets_units, wood_pellets_value)
    assert_equal(elec_schedule_number_of_header_rows, scenario.elec_schedule_number_of_header_rows)
    assert_equal(elec_schedule_column_number, scenario.elec_schedule_column_number)
    if natural_gas_value.nil?
      assert_nil(scenario.natural_gas_units)
      assert_nil(scenario.natural_gas_value)
    else
      assert_equal(natural_gas_units, scenario.natural_gas_units)
      assert_equal(natural_gas_value, scenario.natural_gas_value)
    end
    if propane_value.nil?
      assert_nil(scenario.propane_units)
      assert_nil(scenario.propane_value)
    else
      assert_equal(propane_units, scenario.propane_units)
      assert_equal(propane_value, scenario.propane_value)
    end
    if fuel_oil_value.nil?
      assert_nil(scenario.fuel_oil_units)
      assert_nil(scenario.fuel_oil_value)
    else
      assert_equal(fuel_oil_units, scenario.fuel_oil_units)
      assert_equal(fuel_oil_value, scenario.fuel_oil_value)
    end
    if coal_value.nil?
      assert_nil(scenario.coal_units)
      assert_nil(scenario.coal_value)
    else
      assert_equal(coal_units, scenario.coal_units)
      assert_equal(coal_value, scenario.coal_value)
    end
    if wood_value.nil?
      assert_nil(scenario.wood_units)
      assert_nil(scenario.wood_value)
    else
      assert_equal(wood_units, scenario.wood_units)
      assert_equal(wood_value, scenario.wood_value)
    end
    if wood_pellets_value.nil?
      assert_nil(scenario.wood_pellets_units)
      assert_nil(scenario.wood_pellets_value)
    else
      assert_equal(wood_pellets_units, scenario.wood_pellets_units)
      assert_equal(wood_pellets_value, scenario.wood_pellets_value)
    end
  end

  def _test_default_bills_values(scenario,
                                 elec_fixed_charge, natural_gas_fixed_charge, propane_fixed_charge, fuel_oil_fixed_charge, coal_fixed_charge, wood_fixed_charge, wood_pellets_fixed_charge,
                                 elec_marginal_rate, natural_gas_marginal_rate, propane_marginal_rate, fuel_oil_marginal_rate, coal_marginal_rate, wood_marginal_rate, wood_pellets_marginal_rate,
                                 pv_compensation_type, pv_net_metering_annual_excess_sellback_rate_type, pv_net_metering_annual_excess_sellback_rate,
                                 pv_feed_in_tariff_rate, pv_monthly_grid_connection_fee_dollars_per_kw, pv_monthly_grid_connection_fee_dollars)
    if elec_fixed_charge.nil?
      assert_nil(scenario.elec_fixed_charge)
    else
      assert_equal(elec_fixed_charge, scenario.elec_fixed_charge)
    end
    if natural_gas_fixed_charge.nil?
      assert_nil(scenario.natural_gas_fixed_charge)
    else
      assert_equal(natural_gas_fixed_charge, scenario.natural_gas_fixed_charge)
    end
    if propane_fixed_charge.nil?
      assert_nil(scenario.propane_fixed_charge)
    else
      assert_equal(propane_fixed_charge, scenario.propane_fixed_charge)
    end
    if fuel_oil_fixed_charge.nil?
      assert_nil(scenario.fuel_oil_fixed_charge)
    else
      assert_equal(fuel_oil_fixed_charge, scenario.fuel_oil_fixed_charge)
    end
    if coal_fixed_charge.nil?
      assert_nil(scenario.coal_fixed_charge)
    else
      assert_equal(coal_fixed_charge, scenario.coal_fixed_charge)
    end
    if wood_fixed_charge.nil?
      assert_nil(scenario.wood_fixed_charge)
    else
      assert_equal(wood_fixed_charge, scenario.wood_fixed_charge)
    end
    if wood_pellets_fixed_charge.nil?
      assert_nil(scenario.wood_pellets_fixed_charge)
    else
      assert_equal(wood_pellets_fixed_charge, scenario.wood_pellets_fixed_charge)
    end
    if elec_marginal_rate.nil?
      assert_nil(scenario.elec_marginal_rate)
    else
      assert_equal(elec_marginal_rate, scenario.elec_marginal_rate)
    end
    if natural_gas_marginal_rate.nil?
      assert_nil(scenario.natural_gas_marginal_rate)
    else
      assert_equal(natural_gas_marginal_rate, scenario.natural_gas_marginal_rate)
    end
    if propane_marginal_rate.nil?
      assert_nil(scenario.propane_marginal_rate)
    else
      assert_equal(propane_marginal_rate, scenario.propane_marginal_rate)
    end
    if fuel_oil_marginal_rate.nil?
      assert_nil(scenario.fuel_oil_marginal_rate)
    else
      assert_equal(fuel_oil_marginal_rate, scenario.fuel_oil_marginal_rate)
    end
    if coal_marginal_rate.nil?
      assert_nil(scenario.coal_marginal_rate)
    else
      assert_equal(coal_marginal_rate, scenario.coal_marginal_rate)
    end
    if wood_marginal_rate.nil?
      assert_nil(scenario.wood_marginal_rate)
    else
      assert_equal(wood_marginal_rate, scenario.wood_marginal_rate)
    end
    if wood_pellets_marginal_rate.nil?
      assert_nil(scenario.wood_pellets_marginal_rate)
    else
      assert_equal(wood_pellets_marginal_rate, scenario.wood_pellets_marginal_rate)
    end
    if pv_compensation_type.nil?
      assert_nil(scenario.pv_compensation_type)
    else
      assert_equal(pv_compensation_type, scenario.pv_compensation_type)
    end
    if pv_net_metering_annual_excess_sellback_rate_type.nil?
      assert_nil(scenario.pv_net_metering_annual_excess_sellback_rate_type)
    else
      assert_equal(pv_net_metering_annual_excess_sellback_rate_type, scenario.pv_net_metering_annual_excess_sellback_rate_type)
    end
    if pv_net_metering_annual_excess_sellback_rate.nil?
      assert_nil(scenario.pv_net_metering_annual_excess_sellback_rate)
    else
      assert_equal(pv_net_metering_annual_excess_sellback_rate, scenario.pv_net_metering_annual_excess_sellback_rate)
    end
    if pv_feed_in_tariff_rate.nil?
      assert_nil(scenario.pv_feed_in_tariff_rate)
    else
      assert_equal(pv_feed_in_tariff_rate, scenario.pv_feed_in_tariff_rate)
    end
    if pv_monthly_grid_connection_fee_dollars_per_kw.nil?
      assert_nil(scenario.pv_monthly_grid_connection_fee_dollars_per_kw)
    else
      assert_equal(pv_monthly_grid_connection_fee_dollars_per_kw, scenario.pv_monthly_grid_connection_fee_dollars_per_kw)
    end
    if pv_monthly_grid_connection_fee_dollars.nil?
      assert_nil(scenario.pv_monthly_grid_connection_fee_dollars)
    else
      assert_equal(pv_monthly_grid_connection_fee_dollars, scenario.pv_monthly_grid_connection_fee_dollars)
    end
  end

  def _test_default_building_values(hpxml_bldg, dst_observed, dst_begin_month, dst_begin_day, dst_end_month, dst_end_day, state_code, city, time_zone_utc_offset,
                                    elevation, latitude, longitude, natvent_days_per_week, heat_pump_sizing_methodology, allow_increased_fixed_capacities,
                                    shading_summer_begin_month, shading_summer_begin_day, shading_summer_end_month, shading_summer_end_day,
                                    manualj_heating_design_temp, manualj_cooling_design_temp, manualj_daily_temp_range, manualj_heating_setpoint, manualj_cooling_setpoint,
                                    manualj_humidity_setpoint, manualj_humidity_difference, manualj_internal_loads_sensible, manualj_internal_loads_latent, manualj_num_occupants,
                                    heat_pump_backup_sizing_methodology, manualj_infiltration_method, manualj_infiltration_shielding_class)
    assert_equal(dst_observed, hpxml_bldg.dst_observed)
    if dst_begin_month.nil?
      assert_nil(hpxml_bldg.dst_begin_month)
    else
      assert_equal(dst_begin_month, hpxml_bldg.dst_begin_month)
    end
    if dst_begin_day.nil?
      assert_nil(hpxml_bldg.dst_begin_day)
    else
      assert_equal(dst_begin_day, hpxml_bldg.dst_begin_day)
    end
    if dst_end_month.nil?
      assert_nil(hpxml_bldg.dst_end_month)
    else
      assert_equal(dst_end_month, hpxml_bldg.dst_end_month)
    end
    if dst_end_day.nil?
      assert_nil(hpxml_bldg.dst_end_day)
    else
      assert_equal(dst_end_day, hpxml_bldg.dst_end_day)
    end
    if state_code.nil?
      assert_nil(hpxml_bldg.state_code)
    else
      assert_equal(state_code, hpxml_bldg.state_code)
    end
    if city.nil?
      assert_nil(hpxml_bldg.city)
    else
      assert_equal(city, hpxml_bldg.city)
    end
    assert_equal(time_zone_utc_offset, hpxml_bldg.time_zone_utc_offset)
    assert_equal(elevation, hpxml_bldg.elevation)
    assert_equal(latitude, hpxml_bldg.latitude)
    assert_equal(longitude, hpxml_bldg.longitude)
    assert_equal(natvent_days_per_week, hpxml_bldg.header.natvent_days_per_week)
    if heat_pump_sizing_methodology.nil?
      assert_nil(hpxml_bldg.header.heat_pump_sizing_methodology)
    else
      assert_equal(heat_pump_sizing_methodology, hpxml_bldg.header.heat_pump_sizing_methodology)
    end
    if heat_pump_backup_sizing_methodology.nil?
      assert_nil(hpxml_bldg.header.heat_pump_backup_sizing_methodology)
    else
      assert_equal(heat_pump_backup_sizing_methodology, hpxml_bldg.header.heat_pump_backup_sizing_methodology)
    end
    assert_equal(allow_increased_fixed_capacities, hpxml_bldg.header.allow_increased_fixed_capacities)
    assert_equal(shading_summer_begin_month, hpxml_bldg.header.shading_summer_begin_month)
    assert_equal(shading_summer_begin_day, hpxml_bldg.header.shading_summer_begin_day)
    assert_equal(shading_summer_end_month, hpxml_bldg.header.shading_summer_end_month)
    assert_equal(shading_summer_end_day, hpxml_bldg.header.shading_summer_end_day)
    assert_in_delta(manualj_heating_design_temp, hpxml_bldg.header.manualj_heating_design_temp, 0.01)
    assert_in_delta(manualj_cooling_design_temp, hpxml_bldg.header.manualj_cooling_design_temp, 0.01)
    assert_equal(manualj_daily_temp_range, hpxml_bldg.header.manualj_daily_temp_range)
    assert_equal(manualj_heating_setpoint, hpxml_bldg.header.manualj_heating_setpoint)
    assert_equal(manualj_cooling_setpoint, hpxml_bldg.header.manualj_cooling_setpoint)
    assert_equal(manualj_humidity_setpoint, hpxml_bldg.header.manualj_humidity_setpoint)
    assert_in_delta(manualj_humidity_difference, hpxml_bldg.header.manualj_humidity_difference, 0.1)
    assert_equal(manualj_internal_loads_sensible, hpxml_bldg.header.manualj_internal_loads_sensible)
    assert_equal(manualj_internal_loads_latent, hpxml_bldg.header.manualj_internal_loads_latent)
    assert_equal(manualj_num_occupants, hpxml_bldg.header.manualj_num_occupants)
    assert_equal(manualj_infiltration_method, hpxml_bldg.header.manualj_infiltration_method)
    assert_equal(manualj_infiltration_shielding_class, hpxml_bldg.header.manualj_infiltration_shielding_class)
  end

  def _test_default_site_values(hpxml_bldg, site_type, shielding_of_home, ground_conductivity, ground_diffusivity, soil_type, moisture_type)
    assert_equal(site_type, hpxml_bldg.site.site_type)
    assert_equal(shielding_of_home, hpxml_bldg.site.shielding_of_home)
    assert_in_epsilon(ground_conductivity, hpxml_bldg.site.ground_conductivity, 0.01)
    assert_in_epsilon(ground_diffusivity, hpxml_bldg.site.ground_diffusivity, 0.01)
    if soil_type.nil?
      assert_nil(hpxml_bldg.site.soil_type)
    else
      assert_equal(soil_type, hpxml_bldg.site.soil_type)
    end
    if moisture_type.nil?
      assert_nil(hpxml_bldg.site.moisture_type)
    else
      assert_equal(moisture_type, hpxml_bldg.site.moisture_type)
    end
  end

  def _test_default_neighbor_building_values(hpxml_bldg, azimuths)
    assert_equal(azimuths.size, hpxml_bldg.neighbor_buildings.size)
    hpxml_bldg.neighbor_buildings.each_with_index do |neighbor_building, idx|
      assert_equal(azimuths[idx], neighbor_building.azimuth)
    end
  end

  def _test_default_occupancy_values(hpxml_bldg, weekday_sch, weekend_sch, monthly_mults, water_weekday_sch, water_weekend_sch, water_monthly_mults,
                                     water_use_multiplier)
    assert_equal(weekday_sch, hpxml_bldg.building_occupancy.weekday_fractions)
    assert_equal(weekend_sch, hpxml_bldg.building_occupancy.weekend_fractions)
    assert_equal(monthly_mults, hpxml_bldg.building_occupancy.monthly_multipliers)
    assert_equal(water_weekday_sch, hpxml_bldg.building_occupancy.general_water_use_weekday_fractions)
    assert_equal(water_weekend_sch, hpxml_bldg.building_occupancy.general_water_use_weekend_fractions)
    assert_equal(water_monthly_mults, hpxml_bldg.building_occupancy.general_water_use_monthly_multipliers)
    assert_equal(water_use_multiplier, hpxml_bldg.building_occupancy.general_water_use_usage_multiplier)
  end

  def _test_default_climate_and_risk_zones_values(hpxml_bldg, iecc_year, iecc_zone)
    if iecc_year.nil?
      assert_equal(0, hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.size)
    else
      assert_equal(iecc_year, hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].year)
    end
    if iecc_zone.nil?
      assert_equal(0, hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.size)
    else
      assert_equal(iecc_zone, hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone)
    end
  end

  def _test_default_building_construction_values(hpxml_bldg, building_volume, average_ceiling_height, number_of_bathrooms,
                                                 number_of_units, unit_height_above_grade)
    assert_in_epsilon(building_volume, hpxml_bldg.building_construction.conditioned_building_volume, 0.01)
    assert_in_epsilon(average_ceiling_height, hpxml_bldg.building_construction.average_ceiling_height, 0.01)
    assert_equal(number_of_bathrooms, hpxml_bldg.building_construction.number_of_bathrooms)
    assert_equal(number_of_units, hpxml_bldg.building_construction.number_of_units)
    assert_equal(unit_height_above_grade, hpxml_bldg.building_construction.unit_height_above_grade)
  end

  def _test_default_infiltration_values(hpxml_bldg, volume, has_flue_or_chimney_in_conditioned_space, ach50 = nil)
    assert_equal(volume, hpxml_bldg.air_infiltration_measurements[0].infiltration_volume)
    assert_equal(has_flue_or_chimney_in_conditioned_space, hpxml_bldg.air_infiltration.has_flue_or_chimney_in_conditioned_space)
    if not ach50.nil?
      assert_in_epsilon(ach50, hpxml_bldg.air_infiltration_measurements[0].air_leakage, 0.01)
      assert_equal(HPXML::UnitsACH, hpxml_bldg.air_infiltration_measurements[0].unit_of_measure)
      assert_equal(50, hpxml_bldg.air_infiltration_measurements[0].house_pressure)
    end
  end

  def _test_default_infiltration_compartmentalization_test_values(air_infiltration_measurement, a_ext)
    if a_ext.nil?
      assert_nil(air_infiltration_measurement.a_ext)
    else
      assert_in_delta(a_ext, air_infiltration_measurement.a_ext, 0.001)
    end
  end

  def _test_default_attic_values(attic, sla)
    assert_in_epsilon(sla, attic.vented_attic_sla, 0.001)
  end

  def _test_default_foundation_values(foundation, sla)
    assert_in_epsilon(sla, foundation.vented_crawlspace_sla, 0.001)
  end

  def _test_default_roof_values(roof, roof_type, solar_absorptance, roof_color, emittance, radiant_barrier,
                                radiant_barrier_grade, int_finish_type, int_finish_thickness, azimuth)
    assert_equal(roof_type, roof.roof_type)
    assert_equal(solar_absorptance, roof.solar_absorptance)
    assert_equal(roof_color, roof.roof_color)
    assert_equal(emittance, roof.emittance)
    if not radiant_barrier.nil?
      assert_equal(radiant_barrier, roof.radiant_barrier)
    else
      assert_nil(roof.radiant_barrier)
    end
    if not radiant_barrier_grade.nil?
      assert_equal(radiant_barrier_grade, roof.radiant_barrier_grade)
    else
      assert_nil(roof.radiant_barrier_grade)
    end
    assert_equal(int_finish_type, roof.interior_finish_type)
    if not int_finish_thickness.nil?
      assert_equal(int_finish_thickness, roof.interior_finish_thickness)
    else
      assert_nil(roof.interior_finish_thickness)
    end
    assert_equal(azimuth, roof.azimuth)
  end

  def _test_default_rim_joist_values(rim_joist, siding, solar_absorptance, color, emittance, azimuth)
    assert_equal(siding, rim_joist.siding)
    assert_equal(solar_absorptance, rim_joist.solar_absorptance)
    assert_equal(color, rim_joist.color)
    assert_equal(emittance, rim_joist.emittance)
    assert_equal(azimuth, rim_joist.azimuth)
  end

  def _test_default_wall_values(wall, siding, solar_absorptance, color, emittance, int_finish_type, int_finish_thickness, azimuth)
    assert_equal(siding, wall.siding)
    assert_equal(solar_absorptance, wall.solar_absorptance)
    assert_equal(color, wall.color)
    assert_equal(emittance, wall.emittance)
    assert_equal(int_finish_type, wall.interior_finish_type)
    if not int_finish_thickness.nil?
      assert_equal(int_finish_thickness, wall.interior_finish_thickness)
    else
      assert_nil(wall.interior_finish_thickness)
    end
    if not azimuth.nil?
      assert_equal(azimuth, wall.azimuth)
    else
      assert_nil(wall.azimuth)
    end
  end

  def _test_default_foundation_wall_values(foundation_wall, thickness, int_finish_type, int_finish_thickness, azimuth, area,
                                           ins_int_top, ins_int_bottom, ins_ext_top, ins_ext_bottom, type)
    assert_equal(thickness, foundation_wall.thickness)
    assert_equal(int_finish_type, foundation_wall.interior_finish_type)
    if not int_finish_thickness.nil?
      assert_equal(int_finish_thickness, foundation_wall.interior_finish_thickness)
    else
      assert_nil(foundation_wall.interior_finish_thickness)
    end
    assert_equal(azimuth, foundation_wall.azimuth)
    assert_equal(area, foundation_wall.area)
    assert_equal(ins_int_top, foundation_wall.insulation_interior_distance_to_top)
    assert_equal(ins_int_bottom, foundation_wall.insulation_interior_distance_to_bottom)
    assert_equal(ins_ext_top, foundation_wall.insulation_exterior_distance_to_top)
    assert_equal(ins_ext_bottom, foundation_wall.insulation_exterior_distance_to_bottom)
    assert_equal(type, foundation_wall.type)
  end

  def _test_default_floor_values(floor, int_finish_type, int_finish_thickness)
    assert_equal(int_finish_type, floor.interior_finish_type)
    if not int_finish_thickness.nil?
      assert_equal(int_finish_thickness, floor.interior_finish_thickness)
    else
      assert_nil(floor.interior_finish_thickness)
    end
  end

  def _test_default_slab_values(slab, thickness, carpet_r_value, carpet_fraction, depth_below_grade, gap_rvalue,
                                ext_horiz_r, ext_horiz_width, ext_horiz_depth)
    assert_equal(thickness, slab.thickness)
    assert_equal(carpet_r_value, slab.carpet_r_value)
    assert_equal(carpet_fraction, slab.carpet_fraction)
    if depth_below_grade.nil?
      assert_nil(slab.depth_below_grade)
    else
      assert_equal(depth_below_grade, slab.depth_below_grade)
    end
    assert_equal(gap_rvalue, slab.gap_insulation_r_value)
    assert_equal(ext_horiz_r, slab.exterior_horizontal_insulation_r_value)
    assert_equal(ext_horiz_width, slab.exterior_horizontal_insulation_width)
    assert_equal(ext_horiz_depth, slab.exterior_horizontal_insulation_depth_below_grade)
  end

  def _test_default_window_values(window, ext_summer_sf, ext_winter_sf, int_summer_sf, int_winter_sf, fraction_operable, azimuth,
                                  is_location, is_summer_cover, is_winter_cover, is_summer_sf, is_winter_sf)
    assert_equal(ext_summer_sf, window.exterior_shading_factor_summer)
    assert_equal(ext_winter_sf, window.exterior_shading_factor_winter)
    assert_equal(int_summer_sf, window.interior_shading_factor_summer)
    assert_equal(int_winter_sf, window.interior_shading_factor_winter)
    assert_equal(fraction_operable, window.fraction_operable)
    assert_equal(azimuth, window.azimuth)
    assert_equal(is_location, window.insect_screen_location)
    assert_equal(is_summer_cover, window.insect_screen_coverage_summer)
    assert_equal(is_winter_cover, window.insect_screen_coverage_winter)
    assert_equal(is_summer_sf, window.insect_screen_factor_summer)
    assert_equal(is_winter_sf, window.insect_screen_factor_winter)
  end

  def _test_default_skylight_values(skylight, ext_summer_sf, ext_winter_sf, int_summer_sf, int_winter_sf, azimuth)
    assert_equal(ext_summer_sf, skylight.exterior_shading_factor_summer)
    assert_equal(ext_winter_sf, skylight.exterior_shading_factor_winter)
    assert_equal(int_summer_sf, skylight.interior_shading_factor_summer)
    assert_equal(int_winter_sf, skylight.interior_shading_factor_winter)
    assert_equal(azimuth, skylight.azimuth)
  end

  def _test_default_door_values(hpxml_bldg, azimuths)
    hpxml_bldg.doors.each_with_index do |door, idx|
      assert_equal(azimuths[idx], door.azimuth)
    end
  end

  def _test_default_partition_wall_mass_values(partition_wall_mass, area_fraction, int_finish_type, int_finish_thickness)
    assert_equal(area_fraction, partition_wall_mass.area_fraction)
    assert_equal(int_finish_type, partition_wall_mass.interior_finish_type)
    assert_equal(int_finish_thickness, partition_wall_mass.interior_finish_thickness)
  end

  def _test_default_furniture_mass_values(furniture_mass, area_fraction, type)
    assert_equal(area_fraction, furniture_mass.area_fraction)
    assert_equal(type, furniture_mass.type)
  end

  def _test_default_central_air_conditioner_values(cooling_system, fan_watts_per_cfm, fan_motor_type, cooling_design_airflow_cfm, charge_defect_ratio, airflow_defect_ratio,
                                                   cooling_capacity, cooling_efficiency_seer2, cooling_efficiency_eer2, crankcase_heater_watts, cooling_autosizing_factor,
                                                   equipment_type)
    assert_equal(fan_watts_per_cfm, cooling_system.fan_watts_per_cfm)
    assert_equal(fan_motor_type, cooling_system.fan_motor_type)
    if cooling_design_airflow_cfm.nil? # nil implies an autosized value
      assert(cooling_system.cooling_design_airflow_cfm > 0)
    else
      assert_in_delta(cooling_design_airflow_cfm, cooling_system.cooling_design_airflow_cfm, 1.0)
    end
    assert_equal(charge_defect_ratio, cooling_system.charge_defect_ratio)
    assert_equal(airflow_defect_ratio, cooling_system.airflow_defect_ratio)
    assert_in_delta(crankcase_heater_watts, cooling_system.crankcase_heater_watts, 0.1)
    assert_equal(cooling_autosizing_factor, cooling_system.cooling_autosizing_factor)
    if cooling_capacity.nil?
      assert(cooling_system.cooling_capacity > 0)
    else
      assert_equal(cooling_capacity, cooling_system.cooling_capacity)
    end
    if cooling_efficiency_seer2.nil?
      assert_nil(cooling_system.cooling_efficiency_seer2)
    else
      assert_equal(cooling_efficiency_seer2, cooling_system.cooling_efficiency_seer2)
    end
    if cooling_efficiency_eer2.nil?
      assert_nil(cooling_system.cooling_efficiency_eer2)
    else
      assert_equal(cooling_efficiency_eer2, cooling_system.cooling_efficiency_eer2)
    end
    assert_equal(equipment_type, cooling_system.equipment_type)
  end

  def _test_default_room_air_conditioner_ptac_values(cooling_system, cooling_design_airflow_cfm, cooling_capacity, crankcase_heater_watts, cooling_autosizing_factor, cooling_efficiency_ceer)
    if cooling_design_airflow_cfm.nil? # nil implies an autosized value
      assert(cooling_system.cooling_design_airflow_cfm > 0)
    else
      assert_in_delta(cooling_design_airflow_cfm, cooling_system.cooling_design_airflow_cfm, 1.0)
    end
    assert_equal(crankcase_heater_watts, cooling_system.crankcase_heater_watts)
    assert_equal(cooling_autosizing_factor, cooling_system.cooling_autosizing_factor)
    assert_equal(cooling_efficiency_ceer, cooling_system.cooling_efficiency_ceer)
    if cooling_capacity.nil?
      assert(cooling_system.cooling_capacity > 0)
    else
      assert_equal(cooling_capacity, cooling_system.cooling_capacity)
    end
  end

  def _test_default_evap_cooler_values(cooling_system, cooling_design_airflow_cfm, cooling_capacity, cooling_autosizing_factor)
    if cooling_design_airflow_cfm.nil? # nil implies an autosized value
      assert(cooling_system.cooling_design_airflow_cfm > 0)
    else
      assert_in_delta(cooling_design_airflow_cfm, cooling_system.cooling_design_airflow_cfm, 1.0)
    end
    assert_equal(cooling_autosizing_factor, cooling_system.cooling_autosizing_factor)
    if cooling_capacity.nil?
      assert(cooling_system.cooling_capacity > 0)
    else
      assert_equal(cooling_system.cooling_capacity, cooling_capacity)
    end
  end

  def _test_default_mini_split_air_conditioner_values(cooling_system, fan_watts_per_cfm, fan_motor_type, cooling_design_airflow_cfm, charge_defect_ratio, airflow_defect_ratio,
                                                      cooling_capacity, cooling_efficiency_seer2, cooling_efficiency_eer2, crankcase_heater_watts, cooling_autosizing_factor)
    assert_equal(fan_watts_per_cfm, cooling_system.fan_watts_per_cfm)
    assert_equal(fan_motor_type, cooling_system.fan_motor_type)
    if cooling_design_airflow_cfm.nil? # nil implies an autosized value
      assert(cooling_system.cooling_design_airflow_cfm > 0)
    else
      assert_in_delta(cooling_design_airflow_cfm, cooling_system.cooling_design_airflow_cfm, 1.0)
    end
    assert_equal(charge_defect_ratio, cooling_system.charge_defect_ratio)
    assert_equal(airflow_defect_ratio, cooling_system.airflow_defect_ratio)
    assert_in_delta(crankcase_heater_watts, cooling_system.crankcase_heater_watts, 0.1)
    assert_equal(cooling_autosizing_factor, cooling_system.cooling_autosizing_factor)
    if cooling_capacity.nil?
      assert(cooling_system.cooling_capacity > 0)
    else
      assert_equal(cooling_capacity, cooling_system.cooling_capacity)
    end
    if cooling_efficiency_seer2.nil?
      assert_nil(cooling_system.cooling_efficiency_seer2)
    else
      assert_equal(cooling_efficiency_seer2, cooling_system.cooling_efficiency_seer2)
    end
    if cooling_efficiency_eer2.nil?
      assert_nil(cooling_system.cooling_efficiency_eer2)
    else
      assert_equal(cooling_efficiency_eer2, cooling_system.cooling_efficiency_eer2)
    end
  end

  def _test_default_furnace_values(heating_system, fan_watts_per_cfm, fan_motor_type, heating_design_airflow_cfm, airflow_defect_ratio, heating_capacity,
                                   pilot_light, pilot_light_btuh, heating_autosizing_factor)
    assert_equal(fan_watts_per_cfm, heating_system.fan_watts_per_cfm)
    if fan_motor_type.nil?
      assert_nil(heating_system.fan_motor_type)
    else
      assert_equal(fan_motor_type, heating_system.fan_motor_type)
    end
    if heating_design_airflow_cfm.nil? # nil implies an autosized value
      assert(heating_system.heating_design_airflow_cfm > 0)
    else
      assert_in_delta(heating_design_airflow_cfm, heating_system.heating_design_airflow_cfm, 1.0)
    end
    assert_equal(airflow_defect_ratio, heating_system.airflow_defect_ratio)
    assert_equal(heating_autosizing_factor, heating_system.heating_autosizing_factor)
    if heating_capacity.nil?
      assert(heating_system.heating_capacity > 0)
    else
      assert_equal(heating_capacity, heating_system.heating_capacity)
    end
    assert_equal(pilot_light, heating_system.pilot_light)
    if pilot_light_btuh.nil?
      assert_nil(heating_system.pilot_light_btuh)
    else
      assert_equal(pilot_light_btuh, heating_system.pilot_light_btuh)
    end
  end

  def _test_default_wall_furnace_values(heating_system, fan_watts, heating_design_airflow_cfm, heating_capacity, heating_autosizing_factor)
    assert_equal(fan_watts, heating_system.fan_watts)
    if heating_design_airflow_cfm.nil? # nil implies an autosized value
      assert(heating_system.heating_design_airflow_cfm > 0)
    else
      assert_in_delta(heating_design_airflow_cfm, heating_system.heating_design_airflow_cfm, 1.0)
    end
    assert_equal(heating_autosizing_factor, heating_system.heating_autosizing_factor)
    if heating_capacity.nil?
      assert(heating_system.heating_capacity > 0)
    else
      assert_equal(heating_capacity, heating_system.heating_capacity)
    end
  end

  def _test_default_floor_furnace_values(heating_system, fan_watts, heating_design_airflow_cfm, heating_capacity, pilot_light, pilot_light_btuh, heating_autosizing_factor)
    assert_equal(fan_watts, heating_system.fan_watts)
    if heating_design_airflow_cfm.nil? # nil implies an autosized value
      assert(heating_system.heating_design_airflow_cfm > 0)
    else
      assert_in_delta(heating_design_airflow_cfm, heating_system.heating_design_airflow_cfm, 1.0)
    end
    assert_equal(heating_autosizing_factor, heating_system.heating_autosizing_factor)
    if heating_capacity.nil?
      assert(heating_system.heating_capacity > 0)
    else
      assert_equal(heating_capacity, heating_system.heating_capacity)
    end
    assert_equal(pilot_light, heating_system.pilot_light)
    if pilot_light_btuh.nil?
      assert_nil(heating_system.pilot_light_btuh)
    else
      assert_equal(pilot_light_btuh, heating_system.pilot_light_btuh)
    end
  end

  def _test_default_electric_resistance_values(heating_system, distribution)
    assert_equal(distribution, heating_system.electric_resistance_distribution)
  end

  def _test_default_boiler_values(heating_system, eae, heating_capacity, pilot_light, pilot_light_btuh, heating_autosizing_factor)
    assert_equal(eae, heating_system.electric_auxiliary_energy)
    assert_equal(heating_autosizing_factor, heating_system.heating_autosizing_factor)
    if heating_capacity.nil?
      assert(heating_system.heating_capacity > 0)
    else
      assert_equal(heating_capacity, heating_system.heating_capacity)
    end
    assert_equal(pilot_light, heating_system.pilot_light)
    if pilot_light_btuh.nil?
      assert_nil(heating_system.pilot_light_btuh)
    else
      assert_equal(pilot_light_btuh, heating_system.pilot_light_btuh)
    end
  end

  def _test_default_stove_values(heating_system, fan_watts, heating_design_airflow_cfm, heating_capacity, pilot_light, pilot_light_btuh, heating_autosizing_factor)
    assert_equal(fan_watts, heating_system.fan_watts)
    if heating_design_airflow_cfm.nil? # nil implies an autosized value
      assert(heating_system.heating_design_airflow_cfm > 0)
    else
      assert_in_delta(heating_design_airflow_cfm, heating_system.heating_design_airflow_cfm, 1.0)
    end
    assert_equal(heating_autosizing_factor, heating_system.heating_autosizing_factor)
    if heating_capacity.nil?
      assert(heating_system.heating_capacity > 0)
    else
      assert_equal(heating_capacity, heating_system.heating_capacity)
    end
    assert_equal(pilot_light, heating_system.pilot_light)
    if pilot_light_btuh.nil?
      assert_nil(heating_system.pilot_light_btuh)
    else
      assert_equal(pilot_light_btuh, heating_system.pilot_light_btuh)
    end
  end

  def _test_default_space_heater_values(heating_system, fan_watts, heating_design_airflow_cfm, heating_capacity, heating_autosizing_factor)
    assert_equal(fan_watts, heating_system.fan_watts)
    if heating_design_airflow_cfm.nil? # nil implies an autosized value
      assert(heating_system.heating_design_airflow_cfm > 0)
    else
      assert_in_delta(heating_design_airflow_cfm, heating_system.heating_design_airflow_cfm, 1.0)
    end
    assert_equal(heating_autosizing_factor, heating_system.heating_autosizing_factor)
    if heating_capacity.nil?
      assert(heating_system.heating_capacity > 0)
    else
      assert_equal(heating_capacity, heating_system.heating_capacity)
    end
  end

  def _test_default_fireplace_values(heating_system, fan_watts, heating_design_airflow_cfm, heating_capacity, pilot_light, pilot_light_btuh, heating_autosizing_factor)
    assert_equal(fan_watts, heating_system.fan_watts)
    if heating_design_airflow_cfm.nil? # nil implies an autosized value
      assert(heating_system.heating_design_airflow_cfm > 0)
    else
      assert_in_delta(heating_design_airflow_cfm, heating_system.heating_design_airflow_cfm, 1.0)
    end
    assert_equal(heating_autosizing_factor, heating_system.heating_autosizing_factor)
    if heating_capacity.nil?
      assert(heating_system.heating_capacity > 0)
    else
      assert_equal(heating_capacity, heating_system.heating_capacity)
    end
    assert_equal(pilot_light, heating_system.pilot_light)
    if pilot_light_btuh.nil?
      assert_nil(heating_system.pilot_light_btuh)
    else
      assert_equal(pilot_light_btuh, heating_system.pilot_light_btuh)
    end
  end

  def _test_default_air_to_air_heat_pump_values(heat_pump, fan_watts_per_cfm, fan_motor_type,
                                                cooling_design_airflow_cfm, heating_design_airflow_cfm, charge_defect_ratio, airflow_defect_ratio,
                                                cooling_capacity, heating_capacity, heating_capacity_17F, backup_heating_capacity,
                                                cooling_efficiency_seer2, cooling_efficiency_eer2, heating_efficiency_hspf2,
                                                crankcase_heater_watts, heating_autosizing_factor, cooling_autosizing_factor,
                                                backup_heating_autosizing_factor, pan_heater_watts, pan_heater_control_type,
                                                backup_heating_active_during_defrost, equipment_type)
    assert_equal(fan_watts_per_cfm, heat_pump.fan_watts_per_cfm)
    assert_equal(fan_motor_type, heat_pump.fan_motor_type)
    if cooling_design_airflow_cfm.nil? # nil implies an autosized value
      assert(heat_pump.cooling_design_airflow_cfm > 0)
    else
      assert_in_delta(cooling_design_airflow_cfm, heat_pump.cooling_design_airflow_cfm, 1.0)
    end
    if heating_design_airflow_cfm.nil? # nil implies an autosized value
      assert(heat_pump.heating_design_airflow_cfm > 0)
    else
      assert_in_delta(heating_design_airflow_cfm, heat_pump.heating_design_airflow_cfm, 1.0)
    end
    assert_equal(charge_defect_ratio, heat_pump.charge_defect_ratio)
    assert_equal(airflow_defect_ratio, heat_pump.airflow_defect_ratio)
    assert_in_delta(crankcase_heater_watts, heat_pump.crankcase_heater_watts, 0.1)
    assert_equal(heating_autosizing_factor, heat_pump.heating_autosizing_factor)
    assert_equal(cooling_autosizing_factor, heat_pump.cooling_autosizing_factor)
    assert_equal(backup_heating_autosizing_factor, heat_pump.backup_heating_autosizing_factor)
    if cooling_capacity.nil?
      assert(heat_pump.cooling_capacity > 0)
    else
      assert_equal(cooling_capacity, heat_pump.cooling_capacity)
    end
    if heating_capacity.nil?
      assert(heat_pump.heating_capacity > 0)
    else
      assert_equal(heating_capacity, heat_pump.heating_capacity)
    end
    if heating_capacity_17F.nil?
      assert(heat_pump.heating_capacity_17F > 0)
    else
      assert_equal(heating_capacity_17F, heat_pump.heating_capacity_17F)
    end
    if backup_heating_capacity.nil?
      assert(heat_pump.backup_heating_capacity > 0)
    else
      assert_equal(backup_heating_capacity, heat_pump.backup_heating_capacity)
    end
    if cooling_efficiency_seer2.nil?
      assert_nil(heat_pump.cooling_efficiency_seer2)
    else
      assert_equal(cooling_efficiency_seer2, heat_pump.cooling_efficiency_seer2)
    end
    if cooling_efficiency_eer2.nil?
      assert_nil(heat_pump.cooling_efficiency_eer2)
    else
      assert_equal(cooling_efficiency_eer2, heat_pump.cooling_efficiency_eer2)
    end
    if heating_efficiency_hspf2.nil?
      assert_nil(heat_pump.heating_efficiency_hspf2)
    else
      assert_equal(heating_efficiency_hspf2, heat_pump.heating_efficiency_hspf2)
    end
    assert_equal(pan_heater_watts, heat_pump.pan_heater_watts)
    assert_equal(pan_heater_control_type, heat_pump.pan_heater_control_type)
    assert_equal(backup_heating_active_during_defrost, heat_pump.backup_heating_active_during_defrost)
    assert_equal(equipment_type, heat_pump.equipment_type)
  end

  def _test_default_detailed_performance_capacities(heat_pump, heating_nominal_capacity, cooling_nominal_capacity, heating_capacities, cooling_capacities)
    if cooling_nominal_capacity.nil?
      assert(heat_pump.cooling_capacity > 0)
    else
      assert_equal(cooling_nominal_capacity, heat_pump.cooling_capacity)
    end
    if heating_nominal_capacity.nil?
      assert(heat_pump.heating_capacity > 0)
    else
      assert_equal(heating_nominal_capacity, heat_pump.heating_capacity)
    end
    if not heat_pump.heating_detailed_performance_data.empty?
      heat_pump.heating_detailed_performance_data.each_with_index do |dp, idx|
        assert_equal(heating_capacities[idx], dp.capacity) unless heating_capacities[idx].nil?
      end
    end
    if not heat_pump.cooling_detailed_performance_data.empty?
      heat_pump.cooling_detailed_performance_data.each_with_index do |dp, idx|
        assert_equal(cooling_capacities[idx], dp.capacity) unless cooling_capacities[idx].nil?
      end
    end
  end

  def _test_default_pthp_values(heat_pump, heating_design_airflow_cfm, cooling_design_airflow_cfm, cooling_capacity, heating_capacity, heating_capacity_17F,
                                crankcase_heater_watts, backup_heating_active_during_defrost, heating_autosizing_factor, cooling_autosizing_factor,
                                backup_heating_autosizing_factor)
    if heating_design_airflow_cfm.nil? # nil implies an autosized value
      assert(heat_pump.heating_design_airflow_cfm > 0)
    else
      assert_in_delta(heating_design_airflow_cfm, heat_pump.heating_design_airflow_cfm, 1.0)
    end
    if cooling_design_airflow_cfm.nil? # nil implies an autosized value
      assert(heat_pump.cooling_design_airflow_cfm > 0)
    else
      assert_in_delta(cooling_design_airflow_cfm, heat_pump.cooling_design_airflow_cfm, 1.0)
    end
    assert_equal(crankcase_heater_watts, heat_pump.crankcase_heater_watts)
    assert_equal(heating_autosizing_factor, heat_pump.heating_autosizing_factor)
    assert_equal(cooling_autosizing_factor, heat_pump.cooling_autosizing_factor)
    assert_equal(backup_heating_autosizing_factor, heat_pump.backup_heating_autosizing_factor)
    if cooling_capacity.nil?
      assert(heat_pump.cooling_capacity > 0)
    else
      assert_equal(cooling_capacity, heat_pump.cooling_capacity)
    end
    if heating_capacity.nil?
      assert(heat_pump.heating_capacity > 0)
    else
      assert_equal(heating_capacity, heat_pump.heating_capacity)
    end
    if heating_capacity_17F.nil?
      assert(heat_pump.heating_capacity_17F > 0)
    else
      assert_equal(heating_capacity_17F, heat_pump.heating_capacity_17F)
    end
    assert_equal(backup_heating_active_during_defrost, heat_pump.backup_heating_active_during_defrost)
  end

  def _test_default_mini_split_heat_pump_values(heat_pump, fan_watts_per_cfm, fan_motor_type, heating_design_airflow_cfm, cooling_design_airflow_cfm,
                                                charge_defect_ratio, airflow_defect_ratio, cooling_capacity, heating_capacity, heating_capacity_17F,
                                                backup_heating_capacity, cooling_efficiency_seer2, cooling_efficiency_eer2, heating_efficiency_hspf2,
                                                crankcase_heater_watts, heating_autosizing_factor, cooling_autosizing_factor,
                                                backup_heating_autosizing_factor, pan_heater_watts, pan_heater_control_type, backup_heating_active_during_defrost)
    assert_equal(fan_watts_per_cfm, heat_pump.fan_watts_per_cfm)
    assert_equal(fan_motor_type, heat_pump.fan_motor_type)
    if heating_design_airflow_cfm.nil? # nil implies an autosized value
      assert(heat_pump.heating_design_airflow_cfm > 0)
    else
      assert_in_delta(heating_design_airflow_cfm, heat_pump.heating_design_airflow_cfm, 1.0)
    end
    if cooling_design_airflow_cfm.nil? # nil implies an autosized value
      assert(heat_pump.cooling_design_airflow_cfm > 0)
    else
      assert_in_delta(cooling_design_airflow_cfm, heat_pump.cooling_design_airflow_cfm, 1.0)
    end
    assert_equal(charge_defect_ratio, heat_pump.charge_defect_ratio)
    assert_equal(airflow_defect_ratio, heat_pump.airflow_defect_ratio)
    assert_in_delta(crankcase_heater_watts, heat_pump.crankcase_heater_watts, 0.1)
    assert_equal(heating_autosizing_factor, heat_pump.heating_autosizing_factor)
    assert_equal(cooling_autosizing_factor, heat_pump.cooling_autosizing_factor)
    assert_equal(backup_heating_autosizing_factor, heat_pump.backup_heating_autosizing_factor)
    if cooling_capacity.nil?
      assert(heat_pump.cooling_capacity > 0)
    else
      assert_equal(cooling_capacity, heat_pump.cooling_capacity)
    end
    if heating_capacity.nil?
      assert(heat_pump.heating_capacity > 0)
    else
      assert_equal(heating_capacity, heat_pump.heating_capacity)
    end
    if heating_capacity_17F.nil?
      assert(heat_pump.heating_capacity_17F > 0)
    else
      assert_equal(heating_capacity_17F, heat_pump.heating_capacity_17F)
    end
    if backup_heating_capacity.nil?
      assert(heat_pump.backup_heating_capacity > 0)
    else
      assert_equal(backup_heating_capacity, heat_pump.backup_heating_capacity)
    end
    if cooling_efficiency_seer2.nil?
      assert_nil(heat_pump.cooling_efficiency_seer2)
    else
      assert_equal(cooling_efficiency_seer2, heat_pump.cooling_efficiency_seer2)
    end
    if cooling_efficiency_eer2.nil?
      assert_nil(heat_pump.cooling_efficiency_eer2)
    else
      assert_equal(cooling_efficiency_eer2, heat_pump.cooling_efficiency_eer2)
    end
    if heating_efficiency_hspf2.nil?
      assert_nil(heat_pump.heating_efficiency_hspf2)
    else
      assert_equal(heating_efficiency_hspf2, heat_pump.heating_efficiency_hspf2)
    end
    assert_equal(pan_heater_watts, heat_pump.pan_heater_watts)
    assert_equal(pan_heater_control_type, heat_pump.pan_heater_control_type)
    assert_equal(backup_heating_active_during_defrost, heat_pump.backup_heating_active_during_defrost)
  end

  def _test_default_heat_pump_temperature_values(heat_pump, compressor_lockout_temp, backup_heating_lockout_temp,
                                                 backup_heating_switchover_temp)
    if compressor_lockout_temp.nil?
      assert_nil(heat_pump.compressor_lockout_temp)
    else
      assert_equal(compressor_lockout_temp, heat_pump.compressor_lockout_temp)
    end
    if backup_heating_lockout_temp.nil?
      assert_nil(heat_pump.backup_heating_lockout_temp)
    else
      assert_equal(backup_heating_lockout_temp, heat_pump.backup_heating_lockout_temp)
    end
    if backup_heating_switchover_temp.nil?
      assert_nil(heat_pump.backup_heating_switchover_temp)
    else
      assert_equal(backup_heating_switchover_temp, heat_pump.backup_heating_switchover_temp)
    end
  end

  def _test_default_ground_to_air_heat_pump_values(heat_pump, pump_watts_per_ton, fan_watts_per_cfm, fan_motor_type, heating_design_airflow_cfm, cooling_design_airflow_cfm,
                                                   airflow_defect_ratio, cooling_capacity, heating_capacity,
                                                   backup_heating_capacity)
    assert_equal(pump_watts_per_ton, heat_pump.pump_watts_per_ton)
    assert_equal(fan_watts_per_cfm, heat_pump.fan_watts_per_cfm)
    assert_equal(fan_motor_type, heat_pump.fan_motor_type)
    if heating_design_airflow_cfm.nil? # nil implies an autosized value
      assert(heat_pump.heating_design_airflow_cfm > 0)
    else
      assert_equal(heating_design_airflow_cfm, heat_pump.heating_design_airflow_cfm)
    end
    if cooling_design_airflow_cfm.nil? # nil implies an autosized value
      assert(heat_pump.cooling_design_airflow_cfm > 0)
    else
      assert_equal(cooling_design_airflow_cfm, heat_pump.cooling_design_airflow_cfm)
    end
    assert_equal(airflow_defect_ratio, heat_pump.airflow_defect_ratio)
    if cooling_capacity.nil?
      assert(heat_pump.cooling_capacity > 0)
    else
      assert_equal(cooling_capacity, heat_pump.cooling_capacity)
    end
    if heating_capacity.nil?
      assert(heat_pump.heating_capacity > 0)
    else
      assert_equal(heating_capacity, heat_pump.heating_capacity)
    end
    if backup_heating_capacity.nil?
      assert(heat_pump.backup_heating_capacity > 0)
    else
      assert_equal(backup_heating_capacity, heat_pump.backup_heating_capacity)
    end
  end

  def _test_default_geothermal_loop_values(geothermal_loop, loop_configuration, loop_flow,
                                           num_bore_holes, bore_spacing, bore_length, bore_diameter,
                                           grout_type, grout_conductivity,
                                           pipe_type, pipe_conductivity, pipe_diameter,
                                           shank_spacing, bore_config)
    assert_equal(loop_configuration, geothermal_loop.loop_configuration)
    if loop_flow.nil? # nil implies an autosized value
      assert(geothermal_loop.loop_flow > 0)
    else
      assert_equal(loop_flow, geothermal_loop.loop_flow)
    end
    if num_bore_holes.nil? # nil implies an autosized value
      assert(geothermal_loop.num_bore_holes > 0)
    else
      assert_equal(num_bore_holes, geothermal_loop.num_bore_holes)
    end
    assert_equal(bore_spacing, geothermal_loop.bore_spacing)
    if bore_length.nil? # nil implies an autosized value
      assert(geothermal_loop.bore_length > 0)
    else
      assert_equal(bore_length, geothermal_loop.bore_length)
    end
    assert_equal(bore_diameter, geothermal_loop.bore_diameter)
    assert_equal(grout_type, geothermal_loop.grout_type)
    assert_equal(grout_conductivity, geothermal_loop.grout_conductivity)
    assert_equal(pipe_type, geothermal_loop.pipe_type)
    assert_equal(pipe_conductivity, geothermal_loop.pipe_conductivity)
    assert_equal(pipe_diameter, geothermal_loop.pipe_diameter)
    assert_equal(shank_spacing, geothermal_loop.shank_spacing)
    assert_equal(bore_config, geothermal_loop.bore_config)
  end

  def _test_default_hvac_location_values(hvac_system, location)
    assert_equal(location, hvac_system.location)
  end

  def _test_default_hvac_control_setpoint_values(hvac_control, heating_setpoint_temp, cooling_setpoint_temp)
    assert_equal(heating_setpoint_temp, hvac_control.heating_setpoint_temp)
    assert_equal(cooling_setpoint_temp, hvac_control.cooling_setpoint_temp)
  end

  def _test_default_hvac_control_setback_values(hvac_control, htg_setback_start_hr, clg_setup_start_hr)
    assert_equal(htg_setback_start_hr, hvac_control.heating_setback_start_hour)
    assert_equal(clg_setup_start_hr, hvac_control.cooling_setup_start_hour)
  end

  def _test_default_hvac_control_season_values(hvac_control, htg_season_begin_month, htg_season_begin_day, htg_season_end_month, htg_season_end_day, clg_season_begin_month, clg_season_begin_day, clg_season_end_month, clg_season_end_day)
    assert_equal(htg_season_begin_month, hvac_control.seasons_heating_begin_month)
    assert_equal(htg_season_begin_day, hvac_control.seasons_heating_begin_day)
    assert_equal(htg_season_end_month, hvac_control.seasons_heating_end_month)
    assert_equal(htg_season_end_day, hvac_control.seasons_heating_end_day)
    assert_equal(clg_season_begin_month, hvac_control.seasons_cooling_begin_month)
    assert_equal(clg_season_begin_day, hvac_control.seasons_cooling_begin_day)
    assert_equal(clg_season_end_month, hvac_control.seasons_cooling_end_month)
    assert_equal(clg_season_end_day, hvac_control.seasons_cooling_end_day)
  end

  def _test_default_air_distribution_values(hpxml_bldg, supply_locations, return_locations, supply_areas, return_areas,
                                            supply_fracs, return_fracs, n_return_registers, supply_area_mults, return_area_mults,
                                            supply_buried_levels, return_buried_levels, supply_effective_rvalues, return_effective_rvalues,
                                            supply_rect_fracs, return_rect_fracs, manualj_blower_fan_heat_btuh)
    supply_duct_idx = 0
    return_duct_idx = 0
    hpxml_bldg.hvac_distributions.each do |hvac_distribution|
      next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir

      assert_equal(n_return_registers, hvac_distribution.number_of_return_registers)
      assert_equal(manualj_blower_fan_heat_btuh, hvac_distribution.manualj_blower_fan_heat_btuh)
      hvac_distribution.ducts.each do |duct|
        if duct.duct_type == HPXML::DuctTypeSupply
          assert_equal(supply_locations[supply_duct_idx], duct.duct_location)
          assert_in_epsilon(supply_areas[supply_duct_idx], duct.duct_surface_area, 0.01)
          assert_in_epsilon(supply_fracs[supply_duct_idx], duct.duct_fraction_area, 0.01)
          assert_in_epsilon(supply_area_mults[supply_duct_idx], duct.duct_surface_area_multiplier, 0.01)
          assert_equal(supply_buried_levels[supply_duct_idx], duct.duct_buried_insulation_level)
          assert_in_epsilon(supply_effective_rvalues[supply_duct_idx], duct.duct_effective_r_value, 0.01)
          assert_equal(supply_rect_fracs[supply_duct_idx], duct.duct_fraction_rectangular)
          supply_duct_idx += 1
        elsif duct.duct_type == HPXML::DuctTypeReturn
          assert_equal(return_locations[return_duct_idx], duct.duct_location)
          assert_in_epsilon(return_areas[return_duct_idx], duct.duct_surface_area, 0.01)
          assert_in_epsilon(return_fracs[return_duct_idx], duct.duct_fraction_area, 0.01)
          assert_in_epsilon(return_area_mults[return_duct_idx], duct.duct_surface_area_multiplier, 0.01)
          assert_equal(return_buried_levels[return_duct_idx], duct.duct_buried_insulation_level)
          assert_in_epsilon(return_effective_rvalues[return_duct_idx], duct.duct_effective_r_value, 0.01)
          assert_equal(return_rect_fracs[return_duct_idx], duct.duct_fraction_rectangular)
          return_duct_idx += 1
        end
      end
    end
  end

  def _test_default_hydronic_distribution_values(hpxml_bldg, manualj_hot_water_piping_btuh)
    hpxml_bldg.hvac_distributions.each do |hvac_distribution|
      next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeHydronic

      assert_equal(manualj_hot_water_piping_btuh, hvac_distribution.manualj_hot_water_piping_btuh)
    end
  end

  def _test_default_mech_vent_values(hpxml_bldg, is_shared_system, hours_in_operation, fan_power, flow_rate,
                                     cfis_vent_mode_airflow_fraction = nil, cfis_addtl_runtime_operating_mode = nil,
                                     cfis_has_outdoor_air_control = nil, cfis_control_type = nil, cfis_suppl_fan_runs_with_air_handler = nil)
    vent_fan = hpxml_bldg.ventilation_fans.find { |f| f.used_for_whole_building_ventilation && !f.is_cfis_supplemental_fan }

    assert_equal(is_shared_system, vent_fan.is_shared_system)
    assert_equal(hours_in_operation, vent_fan.hours_in_operation)
    if fan_power.nil?
      assert_nil(vent_fan.fan_power)
    else
      assert_in_delta(fan_power, vent_fan.fan_power, 0.1)
    end
    assert_in_delta(flow_rate, vent_fan.rated_flow_rate.to_f + vent_fan.calculated_flow_rate.to_f + vent_fan.tested_flow_rate.to_f + vent_fan.delivered_ventilation.to_f, 0.1)
    if cfis_vent_mode_airflow_fraction.nil?
      assert_nil(vent_fan.cfis_vent_mode_airflow_fraction)
    else
      assert_equal(cfis_vent_mode_airflow_fraction, vent_fan.cfis_vent_mode_airflow_fraction)
    end
    if cfis_addtl_runtime_operating_mode.nil?
      assert_nil(vent_fan.cfis_addtl_runtime_operating_mode)
    else
      assert_equal(cfis_addtl_runtime_operating_mode, vent_fan.cfis_addtl_runtime_operating_mode)
    end
    if cfis_has_outdoor_air_control.nil?
      assert_nil(vent_fan.cfis_has_outdoor_air_control)
    else
      assert_equal(cfis_has_outdoor_air_control, vent_fan.cfis_has_outdoor_air_control)
    end
    if cfis_suppl_fan_runs_with_air_handler.nil?
      assert_nil(vent_fan.cfis_supplemental_fan_runs_with_air_handler_fan)
    else
      assert_equal(cfis_suppl_fan_runs_with_air_handler, vent_fan.cfis_supplemental_fan_runs_with_air_handler_fan)
    end
    if cfis_control_type.nil?
      assert_nil(vent_fan.cfis_control_type)
    else
      assert_equal(cfis_control_type, vent_fan.cfis_control_type)
    end
  end

  def _test_default_mech_vent_suppl_values(hpxml_bldg, is_shared_system, hours_in_operation, fan_power, flow_rate)
    vent_fan = hpxml_bldg.ventilation_fans.find { |f| f.used_for_whole_building_ventilation && f.is_cfis_supplemental_fan }

    assert_equal(is_shared_system, vent_fan.is_shared_system)
    if hours_in_operation.nil?
      assert_nil(hours_in_operation, vent_fan.hours_in_operation)
    else
      assert_equal(hours_in_operation, vent_fan.hours_in_operation)
    end
    assert_in_epsilon(fan_power, vent_fan.fan_power, 0.01)
    assert_in_epsilon(flow_rate, vent_fan.rated_flow_rate.to_f + vent_fan.calculated_flow_rate.to_f + vent_fan.tested_flow_rate.to_f + vent_fan.delivered_ventilation.to_f, 0.01)
  end

  def _test_default_kitchen_fan_values(hpxml_bldg, count, flow_rate, hours_in_operation, fan_power, start_hour)
    kitchen_fan = hpxml_bldg.ventilation_fans.find { |f| f.used_for_local_ventilation && f.fan_location == HPXML::LocationKitchen }

    assert_equal(count, kitchen_fan.count)
    assert_equal(flow_rate, kitchen_fan.rated_flow_rate.to_f + kitchen_fan.calculated_flow_rate.to_f + kitchen_fan.tested_flow_rate.to_f + kitchen_fan.delivered_ventilation.to_f)
    assert_equal(hours_in_operation, kitchen_fan.hours_in_operation)
    assert_equal(fan_power, kitchen_fan.fan_power)
    assert_equal(start_hour, kitchen_fan.start_hour)
  end

  def _test_default_bath_fan_values(hpxml_bldg, count, flow_rate, hours_in_operation, fan_power, start_hour)
    bath_fan = hpxml_bldg.ventilation_fans.find { |f| f.used_for_local_ventilation && f.fan_location == HPXML::LocationBath }

    assert_equal(count, bath_fan.count)
    assert_equal(flow_rate, bath_fan.rated_flow_rate.to_f + bath_fan.calculated_flow_rate.to_f + bath_fan.tested_flow_rate.to_f + bath_fan.delivered_ventilation.to_f)
    assert_equal(hours_in_operation, bath_fan.hours_in_operation)
    assert_equal(fan_power, bath_fan.fan_power)
    assert_equal(start_hour, bath_fan.start_hour)
  end

  def _test_default_whole_house_fan_values(hpxml_bldg, flow_rate, fan_power)
    whf = hpxml_bldg.ventilation_fans.find { |f| f.used_for_seasonal_cooling_load_reduction }

    assert_equal(flow_rate, whf.rated_flow_rate.to_f + whf.calculated_flow_rate.to_f + whf.tested_flow_rate.to_f + whf.delivered_ventilation.to_f)
    assert_equal(fan_power, whf.fan_power)
  end

  def _test_default_storage_water_heater_values(hpxml_bldg, *expected_wh_values)
    storage_water_heaters = hpxml_bldg.water_heating_systems.select { |w| w.water_heater_type == HPXML::WaterHeaterTypeStorage }
    assert_equal(expected_wh_values.size, storage_water_heaters.size)
    storage_water_heaters.each_with_index do |wh_system, idx|
      is_shared, heating_capacity, tank_volume, recovery_efficiency, location, temperature, efficiency, tank_model_type = expected_wh_values[idx]

      assert_equal(is_shared, wh_system.is_shared_system)
      assert_in_epsilon(heating_capacity, wh_system.heating_capacity, 0.01)
      assert_equal(tank_volume, wh_system.tank_volume)
      assert_in_epsilon(recovery_efficiency, wh_system.recovery_efficiency, 0.01)
      assert_equal(location, wh_system.location)
      assert_equal(temperature, wh_system.temperature)
      if not wh_system.uniform_energy_factor.nil?
        assert_equal(efficiency, wh_system.uniform_energy_factor)
      else
        assert_equal(efficiency, wh_system.energy_factor)
      end
      assert_equal(tank_model_type, wh_system.tank_model_type)
    end
  end

  def _test_default_tankless_water_heater_values(hpxml_bldg, *expected_wh_values)
    tankless_water_heaters = hpxml_bldg.water_heating_systems.select { |w| w.water_heater_type == HPXML::WaterHeaterTypeTankless }
    assert_equal(expected_wh_values.size, tankless_water_heaters.size)
    tankless_water_heaters.each_with_index do |wh_system, idx|
      performance_adjustment, = expected_wh_values[idx]

      assert_equal(performance_adjustment, wh_system.performance_adjustment)
    end
  end

  def _test_default_heat_pump_water_heater_values(hpxml_bldg, *expected_wh_values)
    heat_pump_water_heaters = hpxml_bldg.water_heating_systems.select { |w| w.water_heater_type == HPXML::WaterHeaterTypeHeatPump }
    assert_equal(expected_wh_values.size, heat_pump_water_heaters.size)
    heat_pump_water_heaters.each_with_index do |wh_system, idx|
      tank_volume, operating_mode, htg_cap, backup_htg_cap, hpwh_confined_space_without_mitigation = expected_wh_values[idx]

      assert_equal(tank_volume, wh_system.tank_volume)
      assert_equal(operating_mode, wh_system.hpwh_operating_mode)
      assert_in_epsilon(htg_cap, wh_system.heating_capacity, 0.01)
      assert_in_epsilon(backup_htg_cap, wh_system.backup_heating_capacity, 0.01)
      assert_equal(hpwh_confined_space_without_mitigation, wh_system.hpwh_confined_space_without_mitigation)
    end
  end

  def _test_default_indirect_water_heater_values(hpxml_bldg, *expected_wh_values)
    indirect_water_heaters = hpxml_bldg.water_heating_systems.select { |w| w.water_heater_type == HPXML::WaterHeaterTypeCombiStorage }
    assert_equal(expected_wh_values.size, indirect_water_heaters.size)
    indirect_water_heaters.each_with_index do |wh_system, idx|
      tank_volume, standby_loss_units, standby_loss_value = expected_wh_values[idx]

      assert_equal(tank_volume, wh_system.tank_volume)
      assert_equal(standby_loss_units, wh_system.standby_loss_units)
      assert_equal(standby_loss_value, wh_system.standby_loss_value)
    end
  end

  def _test_default_standard_distribution_values(hot_water_distribution, piping_length, pipe_r_value)
    assert_in_epsilon(piping_length, hot_water_distribution.standard_piping_length, 0.01)
    assert_equal(pipe_r_value, hot_water_distribution.pipe_r_value)
  end

  def _test_default_recirc_distribution_values(hot_water_distribution, piping_length, branch_piping_length, pump_power, pipe_r_value, weekday_sch, weekend_sch, monthly_mults)
    assert_equal(piping_length, hot_water_distribution.recirculation_piping_loop_length)
    assert_equal(branch_piping_length, hot_water_distribution.recirculation_branch_piping_length)
    assert_in_epsilon(pump_power, hot_water_distribution.recirculation_pump_power, 0.01)
    assert_equal(pipe_r_value, hot_water_distribution.pipe_r_value)
    if weekday_sch.nil?
      assert_nil(hot_water_distribution.recirculation_pump_weekday_fractions)
    else
      assert_equal(weekday_sch, hot_water_distribution.recirculation_pump_weekday_fractions)
    end
    if weekend_sch.nil?
      assert_nil(hot_water_distribution.recirculation_pump_weekend_fractions)
    else
      assert_equal(weekend_sch, hot_water_distribution.recirculation_pump_weekend_fractions)
    end
    if monthly_mults.nil?
      assert_nil(hot_water_distribution.recirculation_pump_monthly_multipliers)
    else
      assert_equal(monthly_mults, hot_water_distribution.recirculation_pump_monthly_multipliers)
    end
  end

  def _test_default_shared_recirc_distribution_values(hot_water_distribution, pump_power, weekday_sch, weekend_sch, monthly_mults)
    assert_in_epsilon(pump_power, hot_water_distribution.shared_recirculation_pump_power, 0.01)
    if weekday_sch.nil?
      assert_nil(hot_water_distribution.recirculation_pump_weekday_fractions)
    else
      assert_equal(weekday_sch, hot_water_distribution.recirculation_pump_weekday_fractions)
    end
    if weekend_sch.nil?
      assert_nil(hot_water_distribution.recirculation_pump_weekend_fractions)
    else
      assert_equal(weekend_sch, hot_water_distribution.recirculation_pump_weekend_fractions)
    end
    if monthly_mults.nil?
      assert_nil(hot_water_distribution.recirculation_pump_monthly_multipliers)
    else
      assert_equal(monthly_mults, hot_water_distribution.recirculation_pump_monthly_multipliers)
    end
  end

  def _test_default_water_fixture_values(hpxml_bldg, usage_multiplier, weekday_sch, weekend_sch, monthly_mults, low_flow1, low_flow2)
    assert_equal(usage_multiplier, hpxml_bldg.water_heating.water_fixtures_usage_multiplier)
    if weekday_sch.nil?
      assert_nil(hpxml_bldg.water_heating.water_fixtures_weekday_fractions)
    else
      assert_equal(weekday_sch, hpxml_bldg.water_heating.water_fixtures_weekday_fractions)
    end
    if weekend_sch.nil?
      assert_nil(hpxml_bldg.water_heating.water_fixtures_weekend_fractions)
    else
      assert_equal(weekend_sch, hpxml_bldg.water_heating.water_fixtures_weekend_fractions)
    end
    if monthly_mults.nil?
      assert_nil(hpxml_bldg.water_heating.water_fixtures_monthly_multipliers)
    else
      assert_equal(monthly_mults, hpxml_bldg.water_heating.water_fixtures_monthly_multipliers)
    end
    assert_equal(low_flow1, hpxml_bldg.water_fixtures[0].low_flow)
    assert_equal(low_flow2, hpxml_bldg.water_fixtures[1].low_flow)
  end

  def _test_default_solar_thermal_values(solar_thermal_system, storage_volume, azimuth)
    assert_equal(storage_volume, solar_thermal_system.storage_volume)
    assert_equal(azimuth, solar_thermal_system.collector_azimuth)
  end

  def _test_default_pv_system_values(hpxml_bldg, interver_efficiency, system_loss_frac, is_shared_system, location, tracking, module_type, azimuth)
    hpxml_bldg.pv_systems.each do |pv|
      assert_equal(is_shared_system, pv.is_shared_system)
      assert_in_epsilon(system_loss_frac, pv.system_losses_fraction, 0.01)
      assert_equal(location, pv.location)
      assert_equal(tracking, pv.tracking)
      assert_equal(module_type, pv.module_type)
      assert_equal(azimuth, pv.array_azimuth)
    end
    hpxml_bldg.inverters.each do |inv|
      assert_equal(interver_efficiency, inv.inverter_efficiency)
    end
  end

  def _test_default_electric_panel_values(electric_panel, voltage, max_current_rating, headroom_spaces, rated_total_spaces, occupied_spaces)
    if voltage.nil?
      assert_nil(electric_panel.voltage)
    else
      assert_equal(voltage, electric_panel.voltage)
    end
    if max_current_rating.nil?
      assert_nil(electric_panel.max_current_rating)
    else
      assert_equal(max_current_rating, electric_panel.max_current_rating)
    end
    if headroom_spaces.nil?
      assert_nil(electric_panel.headroom_spaces)
    else
      assert_equal(headroom_spaces, electric_panel.headroom_spaces)
    end
    if rated_total_spaces.nil?
      assert_nil(electric_panel.rated_total_spaces)
    else
      assert_equal(rated_total_spaces, electric_panel.rated_total_spaces)
    end
    assert_equal(occupied_spaces, electric_panel.occupied_spaces)
  end

  def _test_default_branch_circuit_values(branch_circuit, voltage, max_current_rating, occupied_spaces)
    if voltage.nil?
      assert_nil(branch_circuit.voltage)
    else
      assert_equal(voltage, branch_circuit.voltage)
    end
    if max_current_rating.nil?
      assert_nil(branch_circuit.max_current_rating)
    else
      assert_equal(max_current_rating, branch_circuit.max_current_rating)
    end
    if occupied_spaces.nil?
      assert_nil(branch_circuit.occupied_spaces)
    else
      assert_equal(occupied_spaces, branch_circuit.occupied_spaces)
    end
  end

  def _test_default_service_feeder_values(service_feeder, power, is_new_load)
    if power.nil?
      assert_nil(service_feeder.power)
    else
      assert_equal(power, service_feeder.power)
    end
    if is_new_load.nil?
      assert_nil(service_feeder.is_new_load)
    else
      assert_equal(is_new_load, service_feeder.is_new_load)
    end
  end

  def _test_default_battery_values(battery, nominal_capacity_kwh, nominal_capacity_ah, usable_capacity_kwh, usable_capacity_ah,
                                   rated_power_output, location, round_trip_efficiency)
    if nominal_capacity_kwh.nil?
      assert_nil(battery.nominal_capacity_kwh)
    else
      assert_equal(nominal_capacity_kwh, battery.nominal_capacity_kwh)
    end
    if nominal_capacity_ah.nil?
      assert_nil(battery.nominal_capacity_ah)
    else
      assert_equal(nominal_capacity_ah, battery.nominal_capacity_ah)
    end
    if usable_capacity_kwh.nil?
      assert_nil(battery.usable_capacity_kwh)
    else
      assert_equal(usable_capacity_kwh, battery.usable_capacity_kwh)
    end
    if usable_capacity_ah.nil?
      assert_nil(battery.usable_capacity_ah)
    else
      assert_equal(usable_capacity_ah, battery.usable_capacity_ah)
    end
    assert_equal(rated_power_output, battery.rated_power_output)
    assert_equal(location, battery.location)
    assert_equal(round_trip_efficiency, battery.round_trip_efficiency)
  end

  def _test_default_vehicle_values(vehicle, ev_charger, battery_type, nominal_capacity_kwh, nominal_capacity_ah, usable_capacity_kwh,
                                   usable_capacity_ah, miles_per_year, hours_per_week, fuel_economy_combined, fuel_economy_units,
                                   fraction_charged_home, usage_multiplier, weekday_sch, weekend_sch, monthly_multipliers, charging_level, charger_power)
    assert_equal(battery_type, HPXML::BatteryTypeLithiumIon)
    if nominal_capacity_kwh.nil?
      assert_nil(vehicle.nominal_capacity_kwh)
    else
      assert_equal(nominal_capacity_kwh, vehicle.nominal_capacity_kwh)
    end
    if nominal_capacity_ah.nil?
      assert_nil(vehicle.nominal_capacity_ah)
    else
      assert_equal(nominal_capacity_ah, vehicle.nominal_capacity_ah)
    end
    if usable_capacity_kwh.nil?
      assert_nil(vehicle.usable_capacity_kwh)
    else
      assert_equal(usable_capacity_kwh, vehicle.usable_capacity_kwh)
    end
    if usable_capacity_ah.nil?
      assert_nil(vehicle.usable_capacity_ah)
    else
      assert_equal(usable_capacity_ah, vehicle.usable_capacity_ah)
    end
    assert_in_epsilon(miles_per_year, vehicle.miles_per_year, 0.01)
    assert_in_epsilon(hours_per_week, vehicle.hours_per_week, 0.01)
    assert_equal(fuel_economy_combined, vehicle.fuel_economy_combined)
    assert_equal(fuel_economy_units, vehicle.fuel_economy_units)
    assert_equal(fraction_charged_home, vehicle.fraction_charged_home)
    assert_equal(usage_multiplier, vehicle.ev_usage_multiplier)
    if weekday_sch.nil?
      assert_nil(vehicle.ev_weekday_fractions)
    else
      assert_equal(weekday_sch, vehicle.ev_weekday_fractions)
    end
    if weekend_sch.nil?
      assert_nil(vehicle.ev_weekend_fractions)
    else
      assert_equal(weekend_sch, vehicle.ev_weekend_fractions)
    end
    if monthly_multipliers.nil?
      assert_nil(vehicle.ev_monthly_multipliers)
    else
      assert_equal(monthly_multipliers, vehicle.ev_monthly_multipliers)
    end
    if charging_level.nil?
      assert_nil(ev_charger.charging_level)
    else
      assert_equal(charging_level, ev_charger.charging_level)
    end
    assert_equal(charger_power, ev_charger.charging_power)
  end

  def _test_default_generator_values(hpxml_bldg, is_shared_system)
    hpxml_bldg.generators.each do |generator|
      assert_equal(is_shared_system, generator.is_shared_system)
    end
  end

  def _test_default_clothes_washer_values(clothes_washer, is_shared, location, imef, rated_annual_kwh, label_electric_rate,
                                          label_gas_rate, label_annual_gas_cost, capacity, label_usage, usage_multiplier,
                                          weekday_sch, weekend_sch, monthly_mults)
    assert_equal(is_shared, clothes_washer.is_shared_appliance)
    assert_equal(location, clothes_washer.location)
    assert_equal(imef, clothes_washer.integrated_modified_energy_factor)
    assert_equal(rated_annual_kwh, clothes_washer.rated_annual_kwh)
    assert_equal(label_electric_rate, clothes_washer.label_electric_rate)
    assert_equal(label_gas_rate, clothes_washer.label_gas_rate)
    assert_equal(label_annual_gas_cost, clothes_washer.label_annual_gas_cost)
    assert_equal(capacity, clothes_washer.capacity)
    assert_equal(label_usage, clothes_washer.label_usage)
    assert_equal(usage_multiplier, clothes_washer.usage_multiplier)
    if weekday_sch.nil?
      assert_nil(clothes_washer.weekday_fractions)
    else
      assert_equal(weekday_sch, clothes_washer.weekday_fractions)
    end
    if weekend_sch.nil?
      assert_nil(clothes_washer.weekend_fractions)
    else
      assert_equal(weekend_sch, clothes_washer.weekend_fractions)
    end
    if monthly_mults.nil?
      assert_nil(clothes_washer.monthly_multipliers)
    else
      assert_equal(monthly_mults, clothes_washer.monthly_multipliers)
    end
  end

  def _test_default_clothes_dryer_values(clothes_dryer, is_shared, location, cef, usage_multiplier,
                                         weekday_sch, weekend_sch, monthly_mults, drying_method, is_vented)
    assert_equal(is_shared, clothes_dryer.is_shared_appliance)
    assert_equal(location, clothes_dryer.location)
    assert_equal(cef, clothes_dryer.combined_energy_factor)
    assert_equal(usage_multiplier, clothes_dryer.usage_multiplier)
    if weekday_sch.nil?
      assert_nil(clothes_dryer.weekday_fractions)
    else
      assert_equal(weekday_sch, clothes_dryer.weekday_fractions)
    end
    if weekend_sch.nil?
      assert_nil(clothes_dryer.weekend_fractions)
    else
      assert_equal(weekend_sch, clothes_dryer.weekend_fractions)
    end
    if monthly_mults.nil?
      assert_nil(clothes_dryer.monthly_multipliers)
    else
      assert_equal(monthly_mults, clothes_dryer.monthly_multipliers)
    end
    assert_equal(drying_method, clothes_dryer.drying_method)
    assert_equal(is_vented, clothes_dryer.is_vented)
  end

  def _test_default_clothes_dryer_exhaust_values(clothes_dryer, is_vented, vented_flow_rate)
    assert_equal(is_vented, clothes_dryer.is_vented)
    if vented_flow_rate.nil?
      assert_nil(clothes_dryer.vented_flow_rate)
    else
      assert_equal(vented_flow_rate, clothes_dryer.vented_flow_rate)
    end
  end

  def _test_default_dishwasher_values(dishwasher, is_shared, location, rated_annual_kwh, label_electric_rate, label_gas_rate, label_annual_gas_cost, label_usage, place_setting_capacity, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    assert_equal(is_shared, dishwasher.is_shared_appliance)
    assert_equal(location, dishwasher.location)
    assert_equal(rated_annual_kwh, dishwasher.rated_annual_kwh)
    assert_equal(label_electric_rate, dishwasher.label_electric_rate)
    assert_equal(label_gas_rate, dishwasher.label_gas_rate)
    assert_equal(label_annual_gas_cost, dishwasher.label_annual_gas_cost)
    assert_equal(label_usage, dishwasher.label_usage)
    assert_equal(place_setting_capacity, dishwasher.place_setting_capacity)
    assert_equal(usage_multiplier, dishwasher.usage_multiplier)
    if weekday_sch.nil?
      assert_nil(dishwasher.weekday_fractions)
    else
      assert_equal(weekday_sch, dishwasher.weekday_fractions)
    end
    if weekend_sch.nil?
      assert_nil(dishwasher.weekend_fractions)
    else
      assert_equal(weekend_sch, dishwasher.weekend_fractions)
    end
    if monthly_mults.nil?
      assert_nil(dishwasher.monthly_multipliers)
    else
      assert_equal(monthly_mults, dishwasher.monthly_multipliers)
    end
  end

  def _test_default_refrigerator_values(hpxml_bldg, location, rated_annual_kwh, usage_multiplier, weekday_sch, weekend_sch, monthly_mults, constant_coeffs, temperature_coeffs)
    hpxml_bldg.refrigerators.each do |refrigerator|
      next unless refrigerator.primary_indicator

      assert_equal(location, refrigerator.location)
      assert_equal(rated_annual_kwh, refrigerator.rated_annual_kwh)
      assert_equal(usage_multiplier, refrigerator.usage_multiplier)
      if weekday_sch.nil?
        assert_nil(refrigerator.weekday_fractions)
      else
        assert_equal(weekday_sch, refrigerator.weekday_fractions)
      end
      if weekend_sch.nil?
        assert_nil(refrigerator.weekend_fractions)
      else
        assert_equal(weekend_sch, refrigerator.weekend_fractions)
      end
      if monthly_mults.nil?
        assert_nil(refrigerator.monthly_multipliers)
      else
        assert_equal(monthly_mults, refrigerator.monthly_multipliers)
      end
      if constant_coeffs.nil?
        assert_nil(refrigerator.constant_coefficients)
      else
        assert_equal(constant_coeffs, refrigerator.constant_coefficients)
      end
      if temperature_coeffs.nil?
        assert_nil(refrigerator.temperature_coefficients)
      else
        assert_equal(temperature_coeffs, refrigerator.temperature_coefficients)
      end
    end
  end

  def _test_default_extra_refrigerators_values(hpxml_bldg, location, rated_annual_kwh, usage_multiplier, weekday_sch, weekend_sch, monthly_mults, constant_coeffs, temperature_coeffs)
    hpxml_bldg.refrigerators.each do |refrigerator|
      next if refrigerator.primary_indicator

      assert_equal(location, refrigerator.location)
      assert_in_epsilon(rated_annual_kwh, refrigerator.rated_annual_kwh, 0.01)
      assert_equal(usage_multiplier, refrigerator.usage_multiplier)
      if weekday_sch.nil?
        assert_nil(refrigerator.weekday_fractions)
      else
        assert_equal(weekday_sch, refrigerator.weekday_fractions)
      end
      if weekend_sch.nil?
        assert_nil(refrigerator.weekend_fractions)
      else
        assert_equal(weekend_sch, refrigerator.weekend_fractions)
      end
      if monthly_mults.nil?
        assert_nil(refrigerator.monthly_multipliers)
      else
        assert_equal(monthly_mults, refrigerator.monthly_multipliers)
      end
      if constant_coeffs.nil?
        assert_nil(refrigerator.constant_coefficients)
      else
        assert_equal(constant_coeffs, refrigerator.constant_coefficients)
      end
      if temperature_coeffs.nil?
        assert_nil(refrigerator.temperature_coefficients)
      else
        assert_equal(temperature_coeffs, refrigerator.temperature_coefficients)
      end
    end
  end

  def _test_default_freezers_values(hpxml_bldg, location, rated_annual_kwh, usage_multiplier, weekday_sch, weekend_sch, monthly_mults, constant_coeffs, temperature_coeffs)
    hpxml_bldg.freezers.each do |freezer|
      assert_equal(location, freezer.location)
      assert_in_epsilon(rated_annual_kwh, freezer.rated_annual_kwh, 0.01)
      assert_equal(usage_multiplier, freezer.usage_multiplier)
      if weekday_sch.nil?
        assert_nil(freezer.weekday_fractions)
      else
        assert_equal(weekday_sch, freezer.weekday_fractions)
      end
      if weekend_sch.nil?
        assert_nil(freezer.weekend_fractions)
      else
        assert_equal(weekend_sch, freezer.weekend_fractions)
      end
      if monthly_mults.nil?
        assert_nil(freezer.monthly_multipliers)
      else
        assert_equal(monthly_mults, freezer.monthly_multipliers)
      end
      if constant_coeffs.nil?
        assert_nil(freezer.constant_coefficients)
      else
        assert_equal(constant_coeffs, freezer.constant_coefficients)
      end
      if temperature_coeffs.nil?
        assert_nil(freezer.temperature_coefficients)
      else
        assert_equal(temperature_coeffs, freezer.temperature_coefficients)
      end
    end
  end

  def _test_default_cooking_range_values(cooking_range, location, is_induction, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    assert_equal(location, cooking_range.location)
    assert_equal(is_induction, cooking_range.is_induction)
    assert_equal(usage_multiplier, cooking_range.usage_multiplier)
    if weekday_sch.nil?
      assert_nil(cooking_range.weekday_fractions)
    else
      assert_equal(weekday_sch, cooking_range.weekday_fractions)
    end
    if weekend_sch.nil?
      assert_nil(cooking_range.weekend_fractions)
    else
      assert_equal(weekend_sch, cooking_range.weekend_fractions)
    end
    if monthly_mults.nil?
      assert_nil(cooking_range.monthly_multipliers)
    else
      assert_equal(monthly_mults, cooking_range.monthly_multipliers)
    end
  end

  def _test_default_oven_values(oven, is_convection)
    assert_equal(is_convection, oven.is_convection)
  end

  def _test_default_lighting_values(hpxml_bldg, interior_usage_multiplier, garage_usage_multiplier, exterior_usage_multiplier, schedules = {})
    assert_equal(interior_usage_multiplier, hpxml_bldg.lighting.interior_usage_multiplier)
    assert_equal(garage_usage_multiplier, hpxml_bldg.lighting.garage_usage_multiplier)
    assert_equal(exterior_usage_multiplier, hpxml_bldg.lighting.exterior_usage_multiplier)
    if not schedules[:grg_wk_sch].nil?
      assert_equal(schedules[:grg_wk_sch], hpxml_bldg.lighting.garage_weekday_fractions)
    else
      assert_nil(hpxml_bldg.lighting.garage_weekday_fractions)
    end
    if not schedules[:grg_wknd_sch].nil?
      assert_equal(schedules[:grg_wknd_sch], hpxml_bldg.lighting.garage_weekend_fractions)
    else
      assert_nil(hpxml_bldg.lighting.garage_weekend_fractions)
    end
    if not schedules[:grg_month_mult].nil?
      assert_equal(schedules[:grg_month_mult], hpxml_bldg.lighting.garage_monthly_multipliers)
    else
      assert_nil(hpxml_bldg.lighting.garage_monthly_multipliers)
    end
    if not schedules[:ext_wk_sch].nil?
      assert_equal(schedules[:ext_wk_sch], hpxml_bldg.lighting.exterior_weekday_fractions)
    else
      assert_nil(hpxml_bldg.lighting.exterior_weekday_fractions)
    end
    if not schedules[:ext_wknd_sch].nil?
      assert_equal(schedules[:ext_wknd_sch], hpxml_bldg.lighting.exterior_weekend_fractions)
    else
      assert_nil(hpxml_bldg.lighting.exterior_weekday_fractions)
    end
    if not schedules[:ext_month_mult].nil?
      assert_equal(schedules[:ext_month_mult], hpxml_bldg.lighting.exterior_monthly_multipliers)
    else
      assert_nil(hpxml_bldg.lighting.exterior_monthly_multipliers)
    end
    if not schedules[:hol_kwh_per_day].nil?
      assert_equal(schedules[:hol_kwh_per_day], hpxml_bldg.lighting.holiday_kwh_per_day)
    else
      assert_nil(hpxml_bldg.lighting.holiday_kwh_per_day)
    end
    if not schedules[:hol_begin_month].nil?
      assert_equal(schedules[:hol_begin_month], hpxml_bldg.lighting.holiday_period_begin_month)
    else
      assert_nil(hpxml_bldg.lighting.holiday_period_begin_month)
    end
    if not schedules[:hol_begin_day].nil?
      assert_equal(schedules[:hol_begin_day], hpxml_bldg.lighting.holiday_period_begin_day)
    else
      assert_nil(hpxml_bldg.lighting.holiday_period_begin_day)
    end
    if not schedules[:hol_end_month].nil?
      assert_equal(schedules[:hol_end_month], hpxml_bldg.lighting.holiday_period_end_month)
    else
      assert_nil(hpxml_bldg.lighting.holiday_period_end_month)
    end
    if not schedules[:hol_end_day].nil?
      assert_equal(schedules[:hol_end_day], hpxml_bldg.lighting.holiday_period_end_day)
    else
      assert_nil(hpxml_bldg.lighting.holiday_period_end_day)
    end
    if not schedules[:hol_wk_sch].nil?
      assert_equal(schedules[:hol_wk_sch], hpxml_bldg.lighting.holiday_weekday_fractions)
    else
      assert_nil(hpxml_bldg.lighting.holiday_weekday_fractions)
    end
    if not schedules[:hol_wknd_sch].nil?
      assert_equal(schedules[:hol_wknd_sch], hpxml_bldg.lighting.holiday_weekend_fractions)
    else
      assert_nil(hpxml_bldg.lighting.holiday_weekend_fractions)
    end
  end

  def _test_default_ceiling_fan_values(ceiling_fan, count, efficiency, label_energy_use, weekday_sch, weekend_sch, monthly_mults)
    assert_equal(count, ceiling_fan.count)
    if efficiency.nil?
      assert_nil(ceiling_fan.efficiency)
    else
      assert_in_epsilon(efficiency, ceiling_fan.efficiency, 0.01)
    end
    if label_energy_use.nil?
      assert_nil(ceiling_fan.label_energy_use)
    else
      assert_in_epsilon(label_energy_use, ceiling_fan.label_energy_use, 0.01)
    end
    if weekday_sch.nil?
      assert_nil(ceiling_fan.weekday_fractions)
    else
      assert_equal(weekday_sch, ceiling_fan.weekday_fractions)
    end
    if weekend_sch.nil?
      assert_nil(ceiling_fan.weekend_fractions)
    else
      assert_equal(weekend_sch, ceiling_fan.weekend_fractions)
    end
    if monthly_mults.nil?
      assert_nil(ceiling_fan.monthly_multipliers)
    else
      assert_equal(monthly_mults, ceiling_fan.monthly_multipliers)
    end
  end

  def _test_default_pool_heater_values(pool, load_units, load_value, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    if load_units.nil?
      assert_nil(pool.heater_load_units)
    else
      assert_equal(load_units, pool.heater_load_units)
    end
    if load_value.nil?
      assert_nil(pool.heater_load_value)
    else
      assert_in_epsilon(load_value, pool.heater_load_value, 0.01)
    end
    if usage_multiplier.nil?
      assert_nil(pool.heater_usage_multiplier)
    else
      assert_equal(usage_multiplier, pool.heater_usage_multiplier)
    end
    if weekday_sch.nil?
      assert_nil(pool.heater_weekday_fractions)
    else
      assert_equal(weekday_sch, pool.heater_weekday_fractions)
    end
    if weekend_sch.nil?
      assert_nil(pool.heater_weekend_fractions)
    else
      assert_equal(weekend_sch, pool.heater_weekend_fractions)
    end
    if monthly_mults.nil?
      assert_nil(pool.heater_monthly_multipliers)
    else
      assert_equal(monthly_mults, pool.heater_monthly_multipliers)
    end
  end

  def _test_default_pool_pump_values(pool, kwh_per_year, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    assert_in_epsilon(kwh_per_year, pool.pump_kwh_per_year, 0.01)
    assert_equal(usage_multiplier, pool.pump_usage_multiplier)
    assert_equal(weekday_sch, pool.pump_weekday_fractions)
    assert_equal(weekend_sch, pool.pump_weekend_fractions)
    assert_equal(monthly_mults, pool.pump_monthly_multipliers)
  end

  def _test_default_permanent_spa_heater_values(spa, load_units, load_value, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    if load_units.nil?
      assert_nil(spa.heater_load_units)
    else
      assert_equal(load_units, spa.heater_load_units)
    end
    if load_value.nil?
      assert_nil(spa.heater_load_value)
    else
      assert_in_epsilon(load_value, spa.heater_load_value, 0.01)
    end
    if usage_multiplier.nil?
      assert_nil(spa.heater_usage_multiplier)
    else
      assert_equal(usage_multiplier, spa.heater_usage_multiplier)
    end
    if weekday_sch.nil?
      assert_nil(spa.heater_weekday_fractions)
    else
      assert_equal(weekday_sch, spa.heater_weekday_fractions)
    end
    if weekend_sch.nil?
      assert_nil(spa.heater_weekend_fractions)
    else
      assert_equal(weekend_sch, spa.heater_weekend_fractions)
    end
    if monthly_mults.nil?
      assert_nil(spa.heater_monthly_multipliers)
    else
      assert_equal(monthly_mults, spa.heater_monthly_multipliers)
    end
  end

  def _test_default_permanent_spa_pump_values(spa, kwh_per_year, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    assert_in_epsilon(kwh_per_year, spa.pump_kwh_per_year, 0.01)
    assert_equal(usage_multiplier, spa.pump_usage_multiplier)
    assert_equal(weekday_sch, spa.pump_weekday_fractions)
    assert_equal(weekend_sch, spa.pump_weekend_fractions)
    assert_equal(monthly_mults, spa.pump_monthly_multipliers)
  end

  def _test_default_plug_load_values(hpxml_bldg, load_type, kwh_per_year, frac_sensible, frac_latent, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    pl = hpxml_bldg.plug_loads.find { |pl| pl.plug_load_type == load_type }

    assert_in_epsilon(kwh_per_year, pl.kwh_per_year, 0.01)
    assert_equal(usage_multiplier, pl.usage_multiplier)
    assert_in_epsilon(frac_sensible, pl.frac_sensible, 0.01)
    assert_in_epsilon(frac_latent, pl.frac_latent, 0.01)
    assert_equal(weekday_sch, pl.weekday_fractions)
    assert_equal(weekend_sch, pl.weekend_fractions)
    assert_equal(monthly_mults, pl.monthly_multipliers)
  end

  def _test_default_fuel_load_values(hpxml_bldg, load_type, therm_per_year, frac_sensible, frac_latent, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    fl = hpxml_bldg.fuel_loads.find { |fl| fl.fuel_load_type == load_type }

    assert_in_epsilon(therm_per_year, fl.therm_per_year, 0.01)
    assert_equal(usage_multiplier, fl.usage_multiplier)
    assert_in_epsilon(frac_sensible, fl.frac_sensible, 0.01)
    assert_in_epsilon(frac_latent, fl.frac_latent, 0.01)
    assert_equal(weekday_sch, fl.weekday_fractions)
    assert_equal(weekend_sch, fl.weekend_fractions)
    assert_equal(monthly_mults, fl.monthly_multipliers)
  end

  def _create_hpxml(hpxml_name)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, hpxml_name))
    return hpxml, hpxml.buildings[0]
  end
end
