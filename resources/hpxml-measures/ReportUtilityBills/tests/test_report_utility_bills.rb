# frozen_string_literal: true

require 'oga'
require_relative '../../HPXMLtoOpenStudio/resources/calendar'
require_relative '../../HPXMLtoOpenStudio/resources/constants'
require_relative '../../HPXMLtoOpenStudio/resources/energyplus'
require_relative '../../HPXMLtoOpenStudio/resources/hpxml'
require_relative '../../HPXMLtoOpenStudio/resources/defaults'
require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../../HPXMLtoOpenStudio/resources/schedules'
require_relative '../../HPXMLtoOpenStudio/resources/unit_conversions'
require_relative '../../HPXMLtoOpenStudio/resources/utility_bills'
require_relative '../../HPXMLtoOpenStudio/resources/xmlhelper'
require_relative '../../HPXMLtoOpenStudio/resources/version'
require_relative '../resources/util.rb'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require_relative '../measure.rb'
require 'csv'

class ReportUtilityBillsTest < Minitest::Test
  # BEopt 2.9.0.0:
  # - Standard, New Construction, Single-Family Detached
  # - 600 sq ft (30 x 20)
  # - EPW Location: USA_CO_Denver.Intl.AP.725650_TMY3.epw
  # - Cooking Range: Propane
  # - Water Heater: Oil Standard
  # - PV System: None, 1.0 kW, 10.0 kW
  # - Timestep: 60 min
  # - User-Specified rates:
  #   - Electricity: 0.1195179675994109 USD/kWh
  #   - Natural Gas: 0.7734017611590879 USD/therm
  #   - Fuel Oil: 3.495346153846154 USD/gal
  #   - Propane: 2.4532692307692305 USD/gal
  # - Sample Tiered Rate
  #   - Tier 1: 150 Max kWh
  #   - Tier 2: 300 Max kWh
  # - Sample Tiered Time-of-Use Rate
  #   - Tier 1: 150 Max kWh (Period 1 and 2)
  #   - Tier 2: 300 Max kWh (Period 2)
  # - All other options left at default values
  # Then retrieve 1.csv from output folder

  def setup
    @args_hash = {}

    # From BEopt Output screen (Utility Bills USD/yr)
    @expected_bills = {
      'Test: Electricity: Fixed (USD)' => 96,
      'Test: Electricity: Energy (USD)' => 632,
      'Test: Electricity: PV Credit (USD)' => 0,
      'Test: Natural Gas: Fixed (USD)' => 96,
      'Test: Natural Gas: Energy (USD)' => 149,
      'Test: Fuel Oil: Fixed (USD)' => 0,
      'Test: Fuel Oil: Energy (USD)' => 462,
      'Test: Propane: Fixed (USD)' => 0,
      'Test: Propane: Energy (USD)' => 76,
      'Test: Coal: Fixed (USD)' => 0,
      'Test: Coal: Energy (USD)' => 0,
      'Test: Wood Cord: Fixed (USD)' => 0,
      'Test: Wood Cord: Energy (USD)' => 0,
      'Test: Wood Pellets: Fixed (USD)' => 0,
      'Test: Wood Pellets: Energy (USD)' => 0
    }

    @measure = ReportUtilityBills.new
    @hpxml_path = File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-pv.xml')
    @hpxml = HPXML.new(hpxml_path: @hpxml_path)
    @hpxml_bldg = @hpxml.buildings[0]

    @hpxml_header = @hpxml.header
    @hpxml_header.utility_bill_scenarios.clear
    @hpxml_header.utility_bill_scenarios.add(name: 'Test',
                                             elec_fixed_charge: 8.0,
                                             elec_marginal_rate: 0.1195179675994109,
                                             natural_gas_fixed_charge: 8.0,
                                             natural_gas_marginal_rate: 0.7734017611590879,
                                             propane_marginal_rate: 2.4532692307692305,
                                             fuel_oil_marginal_rate: 3.495346153846154)

    # Check for presence of fuels once
    has_fuel = @hpxml_bldg.has_fuels()
    Defaults.apply_header(@hpxml_header, @hpxml_bldg, nil)
    Defaults.apply_utility_bill_scenarios(nil, @hpxml_header, @hpxml_bldg, has_fuel)

    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
    @bills_csv = File.join(File.dirname(__FILE__), 'results_bills.csv')
    @bills_monthly_csv = File.join(File.dirname(__FILE__), 'results_bills_monthly.csv')

    @fuels_pv_none_simple = _load_timeseries(0, false)
    @fuels_pv_1kw_simple = _load_timeseries(1, false)
    @fuels_pv_10kw_simple = _load_timeseries(10, false)
    @fuels_pv_none_detailed = _load_timeseries(0, true)
    @fuels_pv_1kw_detailed = _load_timeseries(1, true)
    @fuels_pv_10kw_detailed = _load_timeseries(10, true)

    @monthly_data = []
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    File.delete(@bills_csv) if File.exist? @bills_csv
    File.delete(@bills_monthly_csv) if File.exist? @bills_monthly_csv
  end

  # Simple (non-JSON) Calculations

  def test_simple_pv_none
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_none_simple, @hpxml_header, [], utility_bill_scenario)
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_simple_pv_1kW_net_metering_user_excess_rate
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 1000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_1kw_simple, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -177
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_simple_pv_10kW_net_metering_user_excess_rate
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_simple, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -920
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_simple_pv_10kW_net_metering_retail_excess_rate
    @hpxml_header.utility_bill_scenarios[-1].pv_net_metering_annual_excess_sellback_rate_type = HPXML::PVAnnualExcessSellbackRateTypeRetailElectricityCost
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_simple, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -1777
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_simple_pv_10kW_net_metering_zero_excess_rate
    @hpxml_header.utility_bill_scenarios[-1].pv_net_metering_annual_excess_sellback_rate = 0.0
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_simple, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -632
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_simple_pv_1kW_feed_in_tariff
    @hpxml_header.utility_bill_scenarios[-1].pv_compensation_type = HPXML::PVCompensationTypeFeedInTariff
    @hpxml_header.utility_bill_scenarios[-1].pv_feed_in_tariff_rate = 0.12
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 1000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_1kw_simple, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -178
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_simple_pv_10kW_feed_in_tariff
    @hpxml_header.utility_bill_scenarios[-1].pv_compensation_type = HPXML::PVCompensationTypeFeedInTariff
    @hpxml_header.utility_bill_scenarios[-1].pv_feed_in_tariff_rate = 0.12
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_simple, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -1785
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_workflow_wood_cord
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-furnace-wood-only.xml'))
    hpxml.header.utility_bill_scenarios.add(name: 'Test 1', wood_marginal_rate: 0.015)
    hpxml.header.utility_bill_scenarios.add(name: 'Test 2', wood_marginal_rate: 0.03)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    actual_bills, actual_monthly_bills = _test_measure()
    expected_val = actual_bills['Test 1: Wood Cord: Total (USD)']
    assert_in_delta(expected_val * 2, actual_bills['Test 2: Wood Cord: Total (USD)'], 1)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_workflow_wood_pellets
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-stove-wood-pellets-only.xml'))
    hpxml.header.utility_bill_scenarios.add(name: 'Test 1', wood_pellets_marginal_rate: 0.02)
    hpxml.header.utility_bill_scenarios.add(name: 'Test 2', wood_pellets_marginal_rate: 0.01)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    actual_bills, actual_monthly_bills = _test_measure()
    expected_val = actual_bills['Test 1: Wood Pellets: Total (USD)']
    assert_in_delta(expected_val / 2, actual_bills['Test 2: Wood Pellets: Total (USD)'], 1)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_workflow_coal
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-furnace-coal-only.xml'))
    hpxml.header.utility_bill_scenarios.add(name: 'Test 1', coal_marginal_rate: 0.05)
    hpxml.header.utility_bill_scenarios.add(name: 'Test 2', coal_marginal_rate: 0.1)
    hpxml.header.utility_bill_scenarios.add(name: 'Test 3', coal_marginal_rate: 0.025)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    actual_bills, actual_monthly_bills = _test_measure()
    expected_val = actual_bills['Test 1: Coal: Total (USD)']
    assert_in_delta(expected_val * 2, actual_bills['Test 2: Coal: Total (USD)'], 1)
    assert_in_delta(expected_val / 2, actual_bills['Test 3: Coal: Total (USD)'], 1)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_workflow_leap_year
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-location-AMY-2012.xml'))
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    actual_bills, actual_monthly_bills = _test_measure()
    assert_operator(actual_bills['Bills: Total (USD)'], :>, 0)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_workflow_semi_annual_run_period
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-simcontrol-runperiod-1-month.xml'))
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    actual_bills, actual_monthly_bills = _test_measure()
    assert_operator(actual_bills['Bills: Total (USD)'], :>, 0)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_workflow_no_bill_scenarios
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
    hpxml.header.utility_bill_scenarios.clear
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    actual_bills, _actual_monthly_bills = _test_measure(hpxml: hpxml)
    assert_nil(actual_bills)
  end

  def test_workflow_detailed_calculations
    # Detailed Rate.json was renamed from Jackson Electric Member Corp - A Residential Service Senior Citizen Low Income Assistance (Effective 2017-01-01).json
    # See https://github.com/NREL/OpenStudio-HPXML/issues/1444
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
    hpxml.header.utility_bill_scenarios.add(name: 'Test 1', elec_tariff_filepath: '../../ReportUtilityBills/tests/Detailed Rate.json')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    actual_bills, actual_monthly_bills = _test_measure()
    assert_operator(actual_bills['Test 1: Total (USD)'], :>, 0)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_workflow_detailed_calculations_scheduled_battery
    # Detailed Rate.json was renamed from Jackson Electric Member Corp - A Residential Service Senior Citizen Low Income Assistance (Effective 2017-01-01).json
    # See https://github.com/NREL/OpenStudio-HPXML/issues/1444
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-battery-scheduled.xml'))
    hpxml.header.utility_bill_scenarios.add(name: 'Test 1', elec_tariff_filepath: '../../ReportUtilityBills/tests/Detailed Rate.json')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    actual_bills, actual_monthly_bills = _test_measure()
    assert_operator(actual_bills['Test 1: Total (USD)'], :>, 0)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_workflow_detailed_calculations_all_electric
    # Detailed Rate.json was renamed from Jackson Electric Member Corp - A Residential Service Senior Citizen Low Income Assistance (Effective 2017-01-01).json
    # See https://github.com/NREL/OpenStudio-HPXML/issues/1444
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-1-speed.xml'))
    hpxml.header.utility_bill_scenarios.add(name: 'Test 1', elec_tariff_filepath: '../../ReportUtilityBills/tests/Detailed Rate.json')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    actual_bills, actual_monthly_bills = _test_measure()
    assert_operator(actual_bills['Test 1: Total (USD)'], :>, 0)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_auto_marginal_rate
    fuel_types = [HPXML::FuelTypeElectricity, HPXML::FuelTypeNaturalGas, HPXML::FuelTypeOil, HPXML::FuelTypeCoal, HPXML::FuelTypePropane, HPXML::FuelTypeWoodCord, HPXML::FuelTypeWoodPellets]

    # Check that we can successfully look up "auto" rates for every state and every fuel type.
    Constants::StateCodesMap.keys.each do |state_code|
      fuel_types.each do |fuel_type|
        marginal_rate, average_rate = UtilityBills.get_rates_from_eia_data(nil, state_code, fuel_type, 1) # fixed_charge > 0 ensures marginal_rate != average_rate
        refute_nil(marginal_rate)
        if [HPXML::FuelTypeElectricity, HPXML::FuelTypeNaturalGas].include? fuel_type
          assert_operator(marginal_rate, :<, average_rate)
        else
          assert_nil(average_rate)
        end
      end
    end

    # Check that we can successfully look up "auto" rates for the US too.
    fuel_types.each do |fuel_type|
      marginal_rate, average_rate = UtilityBills.get_rates_from_eia_data(nil, 'US', fuel_type, 1) # fixed_charge > 0 ensures marginal_rate != average_rate
      refute_nil(marginal_rate)
      if [HPXML::FuelTypeElectricity, HPXML::FuelTypeNaturalGas].include? fuel_type
        assert_operator(marginal_rate, :<, average_rate)
      else
        assert_nil(average_rate)
      end
    end

    # Check that any other state code is gracefully handled (no error)
    fuel_types.each do |fuel_type|
      UtilityBills.get_rates_from_eia_data(nil, 'XX', fuel_type, 0)
    end
  end

  def test_specified_marginal_rate
    fuel_types = [HPXML::FuelTypeElectricity, HPXML::FuelTypeNaturalGas, HPXML::FuelTypeOil, HPXML::FuelTypeCoal, HPXML::FuelTypePropane, HPXML::FuelTypeWoodCord, HPXML::FuelTypeWoodPellets]
    marginal_rate = 0.1

    # Check that we can successfully provide rates for every state and every fuel type.
    Constants::StateCodesMap.keys.each do |state_code|
      fuel_types.each do |fuel_type|
        marginal_rate, average_rate = UtilityBills.get_rates_from_eia_data(nil, state_code, fuel_type, 1, marginal_rate) # fixed_charge > 0 ensures marginal_rate != average_rate
        assert_equal(marginal_rate, marginal_rate)
        if [HPXML::FuelTypeElectricity, HPXML::FuelTypeNaturalGas].include? fuel_type
          assert_operator(marginal_rate, :<, average_rate)
        else
          assert_nil(average_rate)
        end
      end
    end

    # Check that we can successfully provide rates for the US too.
    fuel_types.each do |fuel_type|
      marginal_rate, average_rate = UtilityBills.get_rates_from_eia_data(nil, 'US', fuel_type, 1, marginal_rate) # fixed_charge > 0 ensures marginal_rate != average_rate
      assert_equal(marginal_rate, marginal_rate)
      if [HPXML::FuelTypeElectricity, HPXML::FuelTypeNaturalGas].include? fuel_type
        assert_operator(marginal_rate, :<, average_rate)
      else
        assert_nil(average_rate)
      end
    end
  end

  def test_warning_dse
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-dse.xml'))
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    expected_warnings = ['DSE is not currently supported when calculating utility bills.']
    actual_bills, _actual_monthly_bills = _test_measure(expected_warnings: expected_warnings)
    assert_nil(actual_bills)
  end

  def test_warning_no_rates
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-location-capetown-zaf.xml'))
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    expected_warnings = ['Could not find a marginal Electricity rate.', 'Could not find a marginal Natural Gas rate.']
    actual_bills, _actual_monthly_bills = _test_measure(expected_warnings: expected_warnings)
    assert_nil(actual_bills)
  end

  def test_warning_no_rates_for_coal_in_HI
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-appliances-coal.xml'))
    hpxml.buildings[0].state_code = 'HI'
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    expected_warnings = ['No EIA SEDS rate for coal was found for the state of HI.']
    actual_bills, _actual_monthly_bills = _test_measure(expected_warnings: expected_warnings)
    assert_nil(actual_bills)
  end

  def test_warning_invalid_fixed_charge_units
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
    hpxml.header.utility_bill_scenarios.add(name: 'Test 1', elec_tariff_filepath: '../../ReportUtilityBills/tests/Invalid Fixed Charge Units.json')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    expected_warnings = ['Unsupported fixed charge units ($/year)']
    actual_bills, _actual_monthly_bills = _test_measure(expected_warnings: expected_warnings)
    assert_nil(actual_bills)
  end

  def test_warning_invalid_min_charge_units
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
    hpxml.header.utility_bill_scenarios.add(name: 'Test 1', elec_tariff_filepath: '../../ReportUtilityBills/tests/Invalid Min Charge Units.json')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    expected_warnings = ['Unsupported min charge units ($/day)']
    actual_bills, _actual_monthly_bills = _test_measure(expected_warnings: expected_warnings)
    assert_nil(actual_bills)
  end

  def test_warning_demand_charges
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
    hpxml.header.utility_bill_scenarios.add(name: 'Test 1', elec_tariff_filepath: '../../ReportUtilityBills/tests/Contains Demand Charges.json')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    expected_warnings = ['Demand charges are not currently supported']
    actual_bills, _actual_monthly_bills = _test_measure(expected_warnings: expected_warnings)
    assert_nil(actual_bills)
  end

  def test_warning_missing_required_fields
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
    hpxml.header.utility_bill_scenarios.add(name: 'Test 1', elec_tariff_filepath: '../../ReportUtilityBills/tests/Missing Required Fields.json')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    expected_warnings = ['Tariff file must contain energyweekdayschedule, energyweekendschedule, and energyratestructure fields']
    actual_bills, _actual_monthly_bills = _test_measure(expected_warnings: expected_warnings)
    assert_nil(actual_bills)
  end

  def test_warning_detailed_rates_unit_multipliers
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-misc-unit-multiplier.xml'))
    hpxml.header.utility_bill_scenarios.add(name: 'Test 1', elec_tariff_filepath: '../../ReportUtilityBills/resources/detailed_rates/Sample Tiered Rate.json')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    expected_warnings = ['Cannot currently calculate utility bills based on detailed electric rates for an HPXML with unit multipliers.']
    actual_bills, _actual_monthly_bills = _test_measure(expected_warnings: expected_warnings)
    assert_nil(actual_bills)
  end

  def test_warning_detailed_rates_whole_sfa_mf_building
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-bldgtype-mf-whole-building.xml'))
    hpxml.header.utility_bill_scenarios.add(name: 'Test 1', elec_tariff_filepath: '../../ReportUtilityBills/resources/detailed_rates/Sample Tiered Rate.json')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    expected_warnings = ['Cannot currently calculate utility bills based on detailed electric rates for a whole SFA/MF building simulation.']
    actual_bills, _actual_monthly_bills = _test_measure(expected_warnings: expected_warnings)
    assert_nil(actual_bills)
  end

  def test_monthly_prorate
    # Test begin_month == end_month
    header = HPXML::Header.new(nil)
    header.sim_begin_month = 3
    header.sim_begin_day = 5
    header.sim_end_month = 3
    header.sim_end_day = 20
    header.sim_calendar_year = 2002
    assert_equal(0.0, CalculateUtilityBill.calculate_monthly_prorate(header, 2))
    assert_equal((20 - 5 + 1) / 31.0, CalculateUtilityBill.calculate_monthly_prorate(header, 3))
    assert_equal(0.0, CalculateUtilityBill.calculate_monthly_prorate(header, 4))

    # Test begin_month != end_month
    header = HPXML::Header.new(nil)
    header.sim_begin_month = 2
    header.sim_begin_day = 10
    header.sim_end_month = 4
    header.sim_end_day = 10
    header.sim_calendar_year = 2002
    assert_equal(0.0, CalculateUtilityBill.calculate_monthly_prorate(header, 1))
    assert_equal((28 - 10 + 1) / 28.0, CalculateUtilityBill.calculate_monthly_prorate(header, 2))
    assert_equal(1.0, CalculateUtilityBill.calculate_monthly_prorate(header, 3))
    assert_equal(10 / 30.0, CalculateUtilityBill.calculate_monthly_prorate(header, 4))
    assert_equal(0.0, CalculateUtilityBill.calculate_monthly_prorate(header, 5))
  end

  # Detailed (JSON) Calculations

  # Flat (Same as simple tests above)

  def test_detailed_flat_pv_none
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Flat Rate.json'
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_none_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_flat_pv_none_fixed_daily_charge
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Flat Rate Fixed Daily Charge.json'
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_none_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 91.25
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_flat_pv_1kW_net_metering_user_excess_rate
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Flat Rate.json'
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 1000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_1kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -177
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_flat_pv_10kW_net_metering_user_excess_rate
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Flat Rate.json'
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -920
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_flat_pv_10kW_net_metering_retail_excess_rate
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Flat Rate.json'
    @hpxml_header.utility_bill_scenarios[-1].pv_net_metering_annual_excess_sellback_rate_type = HPXML::PVAnnualExcessSellbackRateTypeRetailElectricityCost
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -1777
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_flat_pv_10kW_net_metering_zero_excess_rate
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Flat Rate.json'
    @hpxml_header.utility_bill_scenarios[-1].pv_net_metering_annual_excess_sellback_rate = 0.0
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -632
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_flat_pv_1kW_feed_in_tariff
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Flat Rate.json'
    @hpxml_header.utility_bill_scenarios[-1].pv_compensation_type = HPXML::PVCompensationTypeFeedInTariff
    @hpxml_header.utility_bill_scenarios[-1].pv_feed_in_tariff_rate = 0.12
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 1000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_1kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -178
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_flat_pv_10kW_feed_in_tariff
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Flat Rate.json'
    @hpxml_header.utility_bill_scenarios[-1].pv_compensation_type = HPXML::PVCompensationTypeFeedInTariff
    @hpxml_header.utility_bill_scenarios[-1].pv_feed_in_tariff_rate = 0.12
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -1785
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  # Tiered

  def test_detailed_tiered_pv_none
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Tiered Rate.json'
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_none_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 580
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_tiered_pv_1kW_net_metering_user_excess_rate
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Tiered Rate.json'
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 1000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_1kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 580
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -190
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_tiered_pv_10kW_net_metering_user_excess_rate
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Tiered Rate.json'
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 580
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -867
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_tiered_pv_10kW_net_metering_retail_excess_rate
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Tiered Rate.json'
    @hpxml_header.utility_bill_scenarios[-1].pv_net_metering_annual_excess_sellback_rate_type = HPXML::PVAnnualExcessSellbackRateTypeRetailElectricityCost
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 580
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -1443
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_tiered_pv_10kW_net_metering_zero_excess_rate
    @hpxml_header.utility_bill_scenarios[-1].pv_net_metering_annual_excess_sellback_rate = 0.0
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Tiered Rate.json'
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 580
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -580
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_tiered_pv_1kW_feed_in_tariff
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Tiered Rate.json'
    @hpxml_header.utility_bill_scenarios[-1].pv_compensation_type = HPXML::PVCompensationTypeFeedInTariff
    @hpxml_header.utility_bill_scenarios[-1].pv_feed_in_tariff_rate = 0.12
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 1000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_1kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 580
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -178
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_tiered_pv_10kW_feed_in_tariff
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Tiered Rate.json'
    @hpxml_header.utility_bill_scenarios[-1].pv_compensation_type = HPXML::PVCompensationTypeFeedInTariff
    @hpxml_header.utility_bill_scenarios[-1].pv_feed_in_tariff_rate = 0.12
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 580
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -1785
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  # Time-of-Use

  def test_detailed_tou_pv_none
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Time-of-Use Rate.json'
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_none_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 393
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_tou_pv_1kW_net_metering_user_excess_rate
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Time-of-Use Rate.json'
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 1000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_1kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 393
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -112
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_tou_pv_10kW_net_metering_user_excess_rate
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Time-of-Use Rate.json'
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 393
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -681
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_tou_pv_10kW_net_metering_retail_excess_rate
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Time-of-Use Rate.json'
    @hpxml_header.utility_bill_scenarios[-1].pv_net_metering_annual_excess_sellback_rate_type = HPXML::PVAnnualExcessSellbackRateTypeRetailElectricityCost
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 393
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -1127
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_tou_pv_10kW_net_metering_zero_excess_rate
    @hpxml_header.utility_bill_scenarios[-1].pv_net_metering_annual_excess_sellback_rate = 0.0
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Time-of-Use Rate.json'
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 393
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -393
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_tou_pv_1kW_feed_in_tariff
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Time-of-Use Rate.json'
    @hpxml_header.utility_bill_scenarios[-1].pv_compensation_type = HPXML::PVCompensationTypeFeedInTariff
    @hpxml_header.utility_bill_scenarios[-1].pv_feed_in_tariff_rate = 0.12
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 1000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_1kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 393
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -178
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_tou_pv_10kW_feed_in_tariff
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Time-of-Use Rate.json'
    @hpxml_header.utility_bill_scenarios[-1].pv_compensation_type = HPXML::PVCompensationTypeFeedInTariff
    @hpxml_header.utility_bill_scenarios[-1].pv_feed_in_tariff_rate = 0.12
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 393
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -1785
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  # Tiered and Time-of-Use

  def test_detailed_tiered_tou_pv_none
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Tiered Time-of-Use Rate.json'
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_none_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 377
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_tiered_tou_pv_1kW_net_metering_user_excess_rate
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Tiered Time-of-Use Rate.json'
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 1000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_1kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 377
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -108
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_tiered_tou_pv_10kW_net_metering_user_excess_rate
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Tiered Time-of-Use Rate.json'
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 377
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -665
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_tiered_tou_pv_10kW_net_metering_retail_excess_rate
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Tiered Time-of-Use Rate.json'
    @hpxml_header.utility_bill_scenarios[-1].pv_net_metering_annual_excess_sellback_rate_type = HPXML::PVAnnualExcessSellbackRateTypeRetailElectricityCost
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 377
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -1000
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_tiered_tou_pv_10kW_net_metering_zero_excess_rate
    @hpxml_header.utility_bill_scenarios[-1].pv_net_metering_annual_excess_sellback_rate = 0.0
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Tiered Time-of-Use Rate.json'
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 377
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -377
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_tiered_tou_pv_1kW_feed_in_tariff
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Tiered Time-of-Use Rate.json'
    @hpxml_header.utility_bill_scenarios[-1].pv_compensation_type = HPXML::PVCompensationTypeFeedInTariff
    @hpxml_header.utility_bill_scenarios[-1].pv_feed_in_tariff_rate = 0.12
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 1000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_1kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 377
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -178
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_tiered_tou_pv_10kW_feed_in_tariff
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Tiered Time-of-Use Rate.json'
    @hpxml_header.utility_bill_scenarios[-1].pv_compensation_type = HPXML::PVCompensationTypeFeedInTariff
    @hpxml_header.utility_bill_scenarios[-1].pv_feed_in_tariff_rate = 0.12
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 377
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -1785
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  # Real-time Pricing

  def test_detailed_rtp_pv_none
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Real-Time Pricing Rate.json'
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_none_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 354
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_rtp_pv_1kW_net_metering_user_excess_rate
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Real-Time Pricing Rate.json'
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 1000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_1kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 354
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -106
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_rtp_pv_10kW_net_metering_user_excess_rate
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Real-Time Pricing Rate.json'
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 354
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -641
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_rtp_pv_10kW_net_metering_retail_excess_rate
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Real-Time Pricing Rate.json'
    @hpxml_header.utility_bill_scenarios[-1].pv_net_metering_annual_excess_sellback_rate_type = HPXML::PVAnnualExcessSellbackRateTypeRetailElectricityCost
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 354
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -1060
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_rtp_pv_10kW_net_metering_zero_excess_rate
    @hpxml_header.utility_bill_scenarios[-1].pv_net_metering_annual_excess_sellback_rate = 0.0
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Real-Time Pricing Rate.json'
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 354
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -354
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_rtp_pv_1kW_feed_in_tariff
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Real-Time Pricing Rate.json'
    @hpxml_header.utility_bill_scenarios[-1].pv_compensation_type = HPXML::PVCompensationTypeFeedInTariff
    @hpxml_header.utility_bill_scenarios[-1].pv_feed_in_tariff_rate = 0.12
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 1000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_1kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 354
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -178
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_rtp_pv_10kW_feed_in_tariff
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Real-Time Pricing Rate.json'
    @hpxml_header.utility_bill_scenarios[-1].pv_compensation_type = HPXML::PVCompensationTypeFeedInTariff
    @hpxml_header.utility_bill_scenarios[-1].pv_feed_in_tariff_rate = 0.12
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 108
    @expected_bills['Test: Electricity: Energy (USD)'] = 354
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -1785
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  # Extra Fees & Charges

  def test_simple_pv_1kW_grid_fee_dollars_per_kW
    @hpxml_header.utility_bill_scenarios[-1].pv_monthly_grid_connection_fee_dollars_per_kw = 2.50
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 1000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_1kw_simple, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 126
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -177
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_simple_pv_1kW_grid_fee_dollars
    @hpxml_header.utility_bill_scenarios[-1].pv_monthly_grid_connection_fee_dollars = 7.50
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 1000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_1kw_simple, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 186
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -177
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_pv_1kW_grid_fee_dollars_per_kW
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Flat Rate.json'
    @hpxml_header.utility_bill_scenarios[-1].pv_monthly_grid_connection_fee_dollars_per_kw = 2.50
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 1000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_1kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 126
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -177
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_pv_1kW_grid_fee_dollars
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Flat Rate.json'
    @hpxml_header.utility_bill_scenarios[-1].pv_monthly_grid_connection_fee_dollars = 7.50
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 1000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_1kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 186
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -177
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_pv_none_min_monthly_charge
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Flat Rate Min Monthly Charge.json'
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_none_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 96
    @expected_bills['Test: Electricity: Energy (USD)'] = 632
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_pv_none_min_annual_charge
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Flat Rate Min Annual Charge.json'
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_none_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 96
    @expected_bills['Test: Electricity: Energy (USD)'] = 632
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_pv_1kW_net_metering_user_excess_rate_min_monthly_charge
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Flat Rate Min Monthly Charge.json'
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 1000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_1kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 96
    @expected_bills['Test: Electricity: Energy (USD)'] = 632
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -177
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_pv_1kW_net_metering_user_excess_rate_min_annual_charge
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Flat Rate Min Annual Charge.json'
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 1000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_1kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 96
    @expected_bills['Test: Electricity: Energy (USD)'] = 632
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -177
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_pv_10kW_net_metering_user_excess_rate_min_monthly_charge
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Flat Rate Min Monthly Charge.json'
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 180
    @expected_bills['Test: Electricity: Energy (USD)'] = 632
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -920
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_pv_10kW_net_metering_user_excess_rate_min_annual_charge
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Flat Rate Min Annual Charge.json'
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 200
    @expected_bills['Test: Electricity: Energy (USD)'] = 632
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -920
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_pv_10kW_net_metering_retail_excess_rate_min_monthly_charge
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Flat Rate Min Monthly Charge.json'
    @hpxml_header.utility_bill_scenarios[-1].pv_net_metering_annual_excess_sellback_rate_type = HPXML::PVAnnualExcessSellbackRateTypeRetailElectricityCost
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 180
    @expected_bills['Test: Electricity: Energy (USD)'] = 632
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -1777
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_detailed_pv_10kW_net_metering_retail_excess_rate_min_annual_charge
    @hpxml_header.utility_bill_scenarios[-1].elec_tariff_filepath = '../../ReportUtilityBills/resources/detailed_rates/Sample Flat Rate Min Annual Charge.json'
    @hpxml_header.utility_bill_scenarios[-1].pv_net_metering_annual_excess_sellback_rate_type = HPXML::PVAnnualExcessSellbackRateTypeRetailElectricityCost
    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_10kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
    @expected_bills['Test: Electricity: Fixed (USD)'] = 200
    @expected_bills['Test: Electricity: Energy (USD)'] = 632
    @expected_bills['Test: Electricity: PV Credit (USD)'] = -1777
    expected_bills = _get_expected_bills(@expected_bills)
    _check_bills(expected_bills, actual_bills)
    _check_monthly_bills(actual_bills, actual_monthly_bills)
  end

  def test_downloaded_utility_rates
    require 'rubygems/package'
    require 'zip'
    require 'tempfile'

    @hpxml_bldg.pv_systems.each { |pv_system| pv_system.max_power_output = 1000.0 / @hpxml_bldg.pv_systems.size }
    utility_bill_scenario = @hpxml_header.utility_bill_scenarios[0]
    Zip.on_exists_proc = true
    Zip::File.open(File.join(File.dirname(__FILE__), '../resources/detailed_rates/openei_rates.zip')) do |zip_file|
      zip_file.each_with_index do |entry, i|
        break if i >= 1000 # No need to run *every* file, that will take a while
        next unless entry.file?

        tmpdir = Dir.tmpdir
        tmpfile = Tempfile.new(['rate', '.json'], tmpdir)
        tmp_path = tmpfile.path.to_s

        File.open(tmp_path, 'wb') do |f|
          f.print entry.get_input_stream.read

          utility_bill_scenario.elec_tariff_filepath = tmp_path
          File.delete(@bills_csv) if File.exist? @bills_csv
          File.delete(@bills_monthly_csv) if File.exist? @bills_monthly_csv
          actual_bills, actual_monthly_bills = _bill_calcs(@fuels_pv_1kw_detailed, @hpxml_header, @hpxml.buildings, utility_bill_scenario)
          if !File.exist?(@bills_csv)
            flunk "#{entry.name} was not successful."
          end
          if entry.name.include? 'North Slope Borough Power Light - Aged or Handicappedseniors over 60'
            # No cost if < 600 kWh/month, which is the case for PV_None.csv
            assert_equal(0, actual_bills['Test: Electricity: Total (USD)'])
          else
            assert_operator(actual_bills['Test: Electricity: Total (USD)'], :>, 0)
          end
          _check_monthly_bills(actual_bills, actual_monthly_bills)
        end
      end
    end
  end

  private

  def _get_expected_bills(expected_bills)
    expected_bills['Test: Electricity: Total (USD)'] = expected_bills['Test: Electricity: Fixed (USD)'] + expected_bills['Test: Electricity: Energy (USD)'] + expected_bills['Test: Electricity: PV Credit (USD)']
    expected_bills['Test: Natural Gas: Total (USD)'] = expected_bills['Test: Natural Gas: Fixed (USD)'] + expected_bills['Test: Natural Gas: Energy (USD)']
    expected_bills['Test: Fuel Oil: Total (USD)'] = expected_bills['Test: Fuel Oil: Fixed (USD)'] + expected_bills['Test: Fuel Oil: Energy (USD)']
    expected_bills['Test: Propane: Total (USD)'] = expected_bills['Test: Propane: Fixed (USD)'] + expected_bills['Test: Propane: Energy (USD)']
    expected_bills['Test: Coal: Total (USD)'] = expected_bills['Test: Coal: Fixed (USD)'] + expected_bills['Test: Coal: Energy (USD)']
    expected_bills['Test: Wood Cord: Total (USD)'] = expected_bills['Test: Wood Cord: Fixed (USD)'] + expected_bills['Test: Wood Cord: Energy (USD)']
    expected_bills['Test: Wood Pellets: Total (USD)'] = expected_bills['Test: Wood Pellets: Fixed (USD)'] + expected_bills['Test: Wood Pellets: Energy (USD)']
    expected_bills['Test: Total (USD)'] = expected_bills['Test: Electricity: Total (USD)'] + expected_bills['Test: Natural Gas: Total (USD)'] + expected_bills['Test: Fuel Oil: Total (USD)'] + expected_bills['Test: Propane: Total (USD)'] + expected_bills['Test: Wood Cord: Total (USD)'] + expected_bills['Test: Wood Pellets: Total (USD)'] + expected_bills['Test: Coal: Total (USD)']
    return expected_bills
  end

  def _check_bills(expected_bills, actual_bills)
    bills = expected_bills.keys | actual_bills.keys
    bills.each do |bill|
      assert(expected_bills.keys.include?(bill))
      if expected_bills[bill] != 0
        assert(actual_bills.keys.include?(bill))
        assert_in_delta(expected_bills[bill], actual_bills[bill], 1) # within a dollar
      end
    end
  end

  def _check_monthly_bills(actual_bills, actual_monthly_bills)
    # Check sum of monthly equal to annual
    actual_bills.keys.each do |bill|
      assert(actual_monthly_bills.keys.include?(bill))
      assert_in_delta(actual_bills[bill], actual_monthly_bills[bill].sum, 0.1) # within 10 cents
    end
  end

  def _load_timeseries(pv_size_kw, use_hourly_electricity)
    fuels = @measure.setup_fuel_outputs()
    columns = CSV.read(File.join(File.dirname(__FILE__), 'data.csv')).transpose
    columns.each do |col|
      col_name = col[0]
      next if col_name == 'Date/Time'

      values = col[1..-1].map { |v| Float(v) }

      case col_name
      when 'Electricity [kWh]'
        fuels[[FT::Elec, false]].timeseries = values
      when 'Gas [therm]'
        fuels[[FT::Gas, false]].timeseries = values
      when 'Propane [gal]'
        fuels[[FT::Propane, false]].timeseries = values
      when 'Oil [gal]'
        fuels[[FT::Oil, false]].timeseries = values
      when "PV_#{pv_size_kw}kW [kWh]"
        fuels[[FT::Elec, true]].timeseries = values
      end
    end

    fuels.values.each do |fuel|
      fuel.timeseries = [0] * fuels[[FT::Elec, false]].timeseries.size if fuel.timeseries.empty?
    end

    # Convert hourly data to monthly data as appropriate
    num_days_in_month = Calendar.num_days_in_months(2002) # Arbitrary non-leap year
    fuels.each do |(fuel_type, _is_production), fuel|
      next unless fuel_type != FT::Elec || (fuel_type == FT::Elec && !use_hourly_electricity)

      ts_data = fuel.timeseries.dup
      fuel.timeseries = []
      start_day = 0
      num_days_in_month.each do |num_days|
        fuel.timeseries << ts_data[start_day * 24..(start_day + num_days) * 24 - 1].sum
        start_day += num_days
      end
    end

    return fuels
  end

  def _bill_calcs(fuels, header, hpxml_buildings, utility_bill_scenario)
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    args = { output_format: 'csv', include_annual_bills: true, include_monthly_bills: true, register_annual_bills: true, register_monthly_bills: true }

    utility_rates, utility_bills = @measure.setup_utility_outputs()
    pv_monthly_fee = @measure.get_pv_monthly_fee(utility_bill_scenario, hpxml_buildings)
    @measure.get_utility_rates(@hpxml_path, fuels, utility_rates, utility_bill_scenario, pv_monthly_fee)
    @measure.get_utility_bills(fuels, utility_rates, utility_bills, utility_bill_scenario, header)

    # Annual
    output_path = File.join(File.dirname(__FILE__), "results_bills.#{args[:output_format]}")
    @measure.report_runperiod_output_results(runner, args, utility_bills, output_path, utility_bill_scenario.name)

    # Check written values exist and are registered
    assert(File.exist?(@bills_csv))
    actual_bills = _get_actual_bills(@bills_csv)

    # Monthly
    timestamps = (1..12).to_a
    monthly_data = []
    monthly_output_path = File.join(File.dirname(__FILE__), "results_bills_monthly.#{args[:output_format]}")
    @measure.get_monthly_output_results(args, utility_bills, utility_bill_scenario.name, monthly_data, header)
    @measure.report_monthly_output_results(runner, args, timestamps, monthly_data, monthly_output_path)

    # Check written values exist
    assert(File.exist?(@bills_monthly_csv))
    actual_monthly_bills = _get_actual_monthly_bills(@bills_monthly_csv)

    _check_for_runner_registered_values(runner, nil, actual_bills, actual_monthly_bills)

    return actual_bills, actual_monthly_bills
  end

  def _test_measure(hpxml: nil, expected_errors: [], expected_warnings: [])
    # Run measure via OSW
    require 'json'
    template_osw = File.join(File.dirname(__FILE__), '..', '..', 'workflow', 'template-run-hpxml.osw')
    workflow = OpenStudio::WorkflowJSON.new(template_osw)
    json = JSON.parse(workflow.to_s)

    # Update measure args
    steps = OpenStudio::WorkflowStepVector.new
    found_args = []
    json['steps'].each do |json_step|
      step = OpenStudio::MeasureStep.new(json_step['measure_dir_name'])
      json_step['arguments'].each do |json_arg_name, json_arg_val|
        if @args_hash.keys.include? json_arg_name
          # Override value
          found_args << json_arg_name
          json_arg_val = @args_hash[json_arg_name]
        end
        step.setArgument(json_arg_name, json_arg_val)
      end
      steps.push(step)
    end
    workflow.setWorkflowSteps(steps)
    osw_path = File.join(File.dirname(template_osw), 'test.osw')
    workflow.saveAs(osw_path)
    assert_equal(@args_hash.size, found_args.size)

    # Run OSW
    command = "#{OpenStudio.getOpenStudioCLI} run -w #{osw_path}"
    success = system(command)
    assert(success)

    # Cleanup
    File.delete(osw_path)

    bills_csv = File.join(File.dirname(template_osw), 'run', 'results_bills.csv')
    bills_monthly_csv = File.join(File.dirname(template_osw), 'run', 'results_bills_monthly.csv')

    # Check warnings/errors
    log_lines = File.readlines(File.join(File.dirname(template_osw), 'run', 'run.log')).map(&:strip)
    expected_errors.each do |expected_error|
      assert(log_lines.any? { |line| line.include?(' ERROR]') && line.include?(expected_error) })
    end
    expected_warnings.each do |expected_warning|
      assert(log_lines.any? { |line| line.include?(' WARN]') && line.include?(expected_warning) })
    end

    if !hpxml.nil?
      return if hpxml.header.utility_bill_scenarios.empty?
    elsif (not expected_errors.empty?) || (not expected_warnings.empty?)
      return
    end

    # Check written values exist and are registered
    assert(File.exist?(bills_csv))
    actual_bills = _get_actual_bills(bills_csv)

    _check_for_runner_registered_values(nil, File.join(File.dirname(bills_csv), 'results.json'), actual_bills)

    assert(File.exist?(bills_monthly_csv))
    actual_monthly_bills = _get_actual_monthly_bills(bills_monthly_csv)

    return actual_bills, actual_monthly_bills
  end

  def _get_actual_bills(bills_csv)
    actual_bills = {}
    File.readlines(bills_csv).each do |line|
      next if line.strip.empty?

      key, value = line.split(',').map { |x| x.strip }
      actual_bills[key] = Float(value)
    end

    return actual_bills
  end

  def _get_actual_monthly_bills(bills_monthly_csv)
    lines = File.readlines(bills_monthly_csv)
    cols = lines[0].strip.split(',')
    units = lines[1].strip.split(',')[1]

    actual_monthly_bills = {}
    cols.each do |col|
      col += " (#{units})"
      actual_monthly_bills[col] = []
    end

    lines[2..-1].each do |row|
      row.strip.split(',').each_with_index do |v, i|
        col = cols[i] + " (#{units})"
        actual_monthly_bills[col] << Float(v) if !col.include?('Time')
      end
    end
    actual_monthly_bills.delete('Time' + " (#{units})")

    return actual_monthly_bills
  end

  def _check_for_runner_registered_values(runner, results_json, actual_bills, actual_monthly_bills = [])
    if !runner.nil?
      runner_bills = {}
      runner.result.stepValues.each do |step_value|
        runner_bills[step_value.name] = get_value_from_workflow_step_value(step_value)
      end
    elsif !results_json.nil?
      require 'json'
      runner_bills = JSON.parse(File.read(results_json))
      runner_bills = runner_bills['ReportUtilityBills']
    end

    actual_bills.each do |name, value|
      name = OpenStudio::toUnderscoreCase(name).chomp('_')

      assert_includes(runner_bills.keys, name)
      assert_equal(value, runner_bills[name])
    end

    return if actual_monthly_bills.empty?

    actual_monthly_bills.each do |name, values|
      name = OpenStudio::toUnderscoreCase(name).chomp('_')

      assert_includes(runner_bills.keys, name)
      assert_in_delta(values.sum, runner_bills[name], 0.1) # within 10 cents
    end
  end
end
