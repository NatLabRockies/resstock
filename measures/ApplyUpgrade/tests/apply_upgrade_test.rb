# frozen_string_literal: true

require 'openstudio'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
require_relative '../measure.rb'

class ApplyUpgradeTest < Minitest::Test
  def test_SFD_1story_FB_UA_GRG_MSHP_FuelTanklessWH
    osw_file = '../../UpgradeCosts/tests/SFD_1story_FB_UA_GRG_MSHP_FuelTanklessWH.osw'
    puts "\nTesting #{File.basename(osw_file)}..."

    _test_measure(osw_file)

    args_hash = {}
    expected_capacities = {
      'heating_system_heating_capacity' => nil,
      'heating_system_2_heating_capacity' => nil,
      'cooling_system_cooling_capacity' => nil,
      'heat_pump_heating_capacity' => 60000.0,
      'heat_pump_cooling_capacity' => 60000.0,
      'heat_pump_backup_heating_capacity' => 100000.0
    }
    expected_autosizing_factors = {
      'heating_system_heating_autosizing_factor' => nil,
      'heating_system_2_heating_autosizing_factor' => nil,
      'cooling_system_cooling_autosizing_factor' => nil,
      'heat_pump_heating_autosizing_factor' => 1.0,
      'heat_pump_cooling_autosizing_factor' => 1.0,
      'heat_pump_backup_heating_autosizing_factor' => 1.0
    }

    puts 'Retaining capacities and autosizing factors:'
    _window_upgrade(args_hash)
    _test_retaining_hvac_system_values(args_hash, expected_capacities, expected_autosizing_factors)

    _heating_system_upgrade(args_hash, expected_capacities, expected_autosizing_factors)
    _test_retaining_hvac_system_values(args_hash, expected_capacities, expected_autosizing_factors)

    _heating_system_2_upgrade(args_hash, expected_capacities, expected_autosizing_factors)
    _test_retaining_hvac_system_values(args_hash, expected_capacities, expected_autosizing_factors)

    _cooling_system_upgrade(args_hash, expected_capacities, expected_autosizing_factors)
    _test_retaining_hvac_system_values(args_hash, expected_capacities, expected_autosizing_factors)

    _heat_pump_upgrade(args_hash, expected_capacities, expected_autosizing_factors)
    _test_retaining_hvac_system_values(args_hash, expected_capacities, expected_autosizing_factors)

    puts 'Retaining existing heating system:'
    expected_values = {}

    expected_values['heat_pump_backup_type'] = nil
    _test_heat_pump_backup('false', HPXML::HVACTypeHeatPumpAirToAir, nil, expected_values)

    expected_values['heat_pump_backup_type'] = nil
    _test_heat_pump_backup('true', HPXML::HVACTypeHeatPumpAirToAir, nil, expected_values)

    expected_values['heat_pump_backup_type'] = nil
    _test_heat_pump_backup('true', HPXML::HVACTypeHeatPumpMiniSplit, nil, expected_values)

    expected_values['heat_pump_backup_type'] = nil
    _test_heat_pump_backup('true', HPXML::HVACTypeHeatPumpMiniSplit, 'false', expected_values)

    expected_values['heat_pump_backup_type'] = nil
    _test_heat_pump_backup('true', HPXML::HVACTypeHeatPumpMiniSplit, 'true', expected_values)

    puts 'Duct restriction:'
    expected_values = {
      'baseline_max_airflow_cfm' => nil,
      'heat_pump_heating_autosizing_limit' => nil,
      'heat_pump_cooling_autosizing_limit' => nil,
    }

    expected_values['adjusted_fan_watts_per_cfm'] = nil
    _test_duct_restriction('true', nil, nil, expected_values)
  end

  def test_SFD_1story_UB_UA_GRG_ACV_FuelFurnace_PortableHeater_HPWH
    osw_file = '../../UpgradeCosts/tests/SFD_1story_UB_UA_GRG_ACV_FuelFurnace_PortableHeater_HPWH.osw'
    puts "\nTesting #{File.basename(osw_file)}..."

    _test_measure(osw_file)

    args_hash = {}
    expected_capacities = {
      'heating_system_heating_capacity' => 100000.0,
      'heating_system_2_heating_capacity' => 20000.0,
      'cooling_system_cooling_capacity' => 60000.0,
      'heat_pump_heating_capacity' => nil,
      'heat_pump_cooling_capacity' => nil,
      'heat_pump_backup_heating_capacity' => nil
    }
    expected_autosizing_factors = {
      'heating_system_heating_autosizing_factor' => 1.0,
      'heating_system_2_heating_autosizing_factor' => 1.0,
      'cooling_system_cooling_autosizing_factor' => 1.0,
      'heat_pump_heating_autosizing_factor' => nil,
      'heat_pump_cooling_autosizing_factor' => nil,
      'heat_pump_backup_heating_autosizing_factor' => nil
    }

    puts 'Retaining capacities and autosizing factors:'
    _window_upgrade(args_hash)
    _test_retaining_hvac_system_values(args_hash, expected_capacities, expected_autosizing_factors)

    _heating_system_upgrade(args_hash, expected_capacities, expected_autosizing_factors)
    _test_retaining_hvac_system_values(args_hash, expected_capacities, expected_autosizing_factors)

    _heating_system_2_upgrade(args_hash, expected_capacities, expected_autosizing_factors)
    _test_retaining_hvac_system_values(args_hash, expected_capacities, expected_autosizing_factors)

    _cooling_system_upgrade(args_hash, expected_capacities, expected_autosizing_factors)
    _test_retaining_hvac_system_values(args_hash, expected_capacities, expected_autosizing_factors)

    _heat_pump_upgrade(args_hash, expected_capacities, expected_autosizing_factors)
    _test_retaining_hvac_system_values(args_hash, expected_capacities, expected_autosizing_factors)

    puts 'Retaining existing heating system:'
    expected_values = {}

    expected_values['heat_pump_backup_type'] = nil
    _test_heat_pump_backup('false', HPXML::HVACTypeHeatPumpAirToAir, nil, expected_values)

    expected_values = {
      'heat_pump_backup_fuel' => HPXML::FuelTypeNaturalGas,
      'heat_pump_backup_heating_efficiency' => 0.92,
      'heat_pump_backup_heating_capacity' => 100000.0,
      'heat_pump_backup_heating_autosizing_factor' => 1.0
    }

    expected_values['heat_pump_backup_type'] = HPXML::HeatPumpBackupTypeIntegrated
    _test_heat_pump_backup('true', HPXML::HVACTypeHeatPumpAirToAir, nil, expected_values)

    expected_values = {
      'heating_system_2_type' => HPXML::HVACTypeFurnace,
      'heating_system_2_fuel' => HPXML::FuelTypeNaturalGas,
      'heating_system_2_heating_efficiency' => 0.92,
      'heating_system_2_heating_capacity' => 100000.0,
      'heating_system_2_heating_autosizing_factor' => 1.0
    }

    expected_values['heat_pump_backup_type'] = HPXML::HeatPumpBackupTypeSeparate
    _test_heat_pump_backup('true', HPXML::HVACTypeHeatPumpMiniSplit, nil, expected_values)

    expected_values['heat_pump_backup_type'] = HPXML::HeatPumpBackupTypeSeparate
    _test_heat_pump_backup('true', HPXML::HVACTypeHeatPumpMiniSplit, 'false', expected_values)

    expected_values = {
      'heat_pump_backup_fuel' => HPXML::FuelTypeNaturalGas,
      'heat_pump_backup_heating_efficiency' => 0.92,
      'heat_pump_backup_heating_capacity' => 100000.0,
      'heat_pump_backup_heating_autosizing_factor' => 1.0
    }

    expected_values['heat_pump_backup_type'] = HPXML::HeatPumpBackupTypeIntegrated
    _test_heat_pump_backup('true', HPXML::HVACTypeHeatPumpMiniSplit, 'true', expected_values)

    puts 'Duct restriction:'
    expected_values = {
      'baseline_max_airflow_cfm' => nil,
      'heat_pump_heating_autosizing_limit' => nil,
      'heat_pump_cooling_autosizing_limit' => nil
    }

    expected_values['adjusted_fan_watts_per_cfm'] = nil
    _test_duct_restriction('false', nil, nil, expected_values)

    cfm = 2000.0 / 0.75
    expected_values = {
      'baseline_max_airflow_cfm' => cfm,
      'heat_pump_heating_autosizing_limit' => cfm / 400.0 * 12000.0,
      'heat_pump_cooling_autosizing_limit' => cfm / 400.0 * 12000.0
    }

    expected_values['adjusted_fan_watts_per_cfm'] = 0.076
    _test_duct_restriction('true', 1200.0, 0.375, expected_values)

    expected_values['adjusted_fan_watts_per_cfm'] = 0.089
    _test_duct_restriction('true', 1300.0, 0.375, expected_values)

    expected_values['adjusted_fan_watts_per_cfm'] = 0.103
    _test_duct_restriction('true', 1400.0, 0.375, expected_values)

    expected_values['adjusted_fan_watts_per_cfm'] = 0.375
    _test_duct_restriction('true', cfm, 0.375, expected_values)
  end

  def test_SFD_2story_CS_UA_AC2_FuelBoiler_FuelTankWH
    osw_file = '../../UpgradeCosts/tests/SFD_2story_CS_UA_AC2_FuelBoiler_FuelTankWH.osw'
    puts "\nTesting #{File.basename(osw_file)}..."

    _test_measure(osw_file)

    args_hash = {}
    expected_capacities = {
      'heating_system_heating_capacity' => 100000.0,
      'heating_system_2_heating_capacity' => nil,
      'cooling_system_cooling_capacity' => 60000.0,
      'heat_pump_heating_capacity' => nil,
      'heat_pump_cooling_capacity' => nil,
      'heat_pump_backup_heating_capacity' => nil
    }
    expected_autosizing_factors = {
      'heating_system_heating_autosizing_factor' => 1.0,
      'heating_system_2_heating_autosizing_factor' => nil,
      'cooling_system_cooling_autosizing_factor' => 1.0,
      'heat_pump_heating_autosizing_factor' => nil,
      'heat_pump_cooling_autosizing_factor' => nil,
      'heat_pump_backup_heating_autosizing_factor' => nil
    }

    puts 'Retaining capacities and autosizing factors:'
    _window_upgrade(args_hash)
    _test_retaining_hvac_system_values(args_hash, expected_capacities, expected_autosizing_factors)

    _heating_system_upgrade(args_hash, expected_capacities, expected_autosizing_factors)
    _test_retaining_hvac_system_values(args_hash, expected_capacities, expected_autosizing_factors)

    _heating_system_2_upgrade(args_hash, expected_capacities, expected_autosizing_factors)
    _test_retaining_hvac_system_values(args_hash, expected_capacities, expected_autosizing_factors)

    _cooling_system_upgrade(args_hash, expected_capacities, expected_autosizing_factors)
    _test_retaining_hvac_system_values(args_hash, expected_capacities, expected_autosizing_factors)

    _heat_pump_upgrade(args_hash, expected_capacities, expected_autosizing_factors)
    _test_retaining_hvac_system_values(args_hash, expected_capacities, expected_autosizing_factors)

    puts 'Retaining existing heating system:'
    expected_values = {}

    expected_values['heat_pump_backup_type'] = nil
    _test_heat_pump_backup('false', HPXML::HVACTypeHeatPumpAirToAir, nil, expected_values)

    expected_values = {
      'heating_system_2_type' => HPXML::HVACTypeBoiler,
      'heating_system_2_fuel' => HPXML::FuelTypeNaturalGas,
      'heating_system_2_heating_efficiency' => 0.92,
      'heating_system_2_heating_capacity' => 100000.0,
      'heating_system_2_heating_autosizing_factor' => 1.0
    }

    expected_values['heat_pump_backup_type'] = HPXML::HeatPumpBackupTypeSeparate
    _test_heat_pump_backup('true', HPXML::HVACTypeHeatPumpAirToAir, nil, expected_values)

    expected_values['heat_pump_backup_type'] = HPXML::HeatPumpBackupTypeSeparate
    _test_heat_pump_backup('true', HPXML::HVACTypeHeatPumpMiniSplit, nil, expected_values)

    expected_values['heat_pump_backup_type'] = HPXML::HeatPumpBackupTypeSeparate
    _test_heat_pump_backup('true', HPXML::HVACTypeHeatPumpMiniSplit, 'false', expected_values)

    expected_values['heat_pump_backup_type'] = HPXML::HeatPumpBackupTypeSeparate
    _test_heat_pump_backup('true', HPXML::HVACTypeHeatPumpMiniSplit, 'true', expected_values)

    puts 'Duct restriction:'
    expected_values = {
      'baseline_max_airflow_cfm' => nil,
      'heat_pump_heating_autosizing_limit' => nil,
      'heat_pump_cooling_autosizing_limit' => nil
    }

    expected_values['adjusted_fan_watts_per_cfm'] = nil
    _test_duct_restriction('false', nil, nil, expected_values)

    cfm = 1800.0
    expected_values = {
      'baseline_max_airflow_cfm' => cfm,
      'heat_pump_heating_autosizing_limit' => cfm / 400.0 * 12000.0,
      'heat_pump_cooling_autosizing_limit' => cfm / 400.0 * 12000.0
    }

    expected_values['adjusted_fan_watts_per_cfm'] = 0.167
    _test_duct_restriction('true', 1200.0, 0.375, expected_values)

    expected_values['adjusted_fan_watts_per_cfm'] = 0.196
    _test_duct_restriction('true', 1300.0, 0.375, expected_values)

    expected_values['adjusted_fan_watts_per_cfm'] = 0.227
    _test_duct_restriction('true', 1400.0, 0.375, expected_values)

    expected_values['adjusted_fan_watts_per_cfm'] = 0.375
    _test_duct_restriction('true', cfm, 0.375, expected_values)
  end

  def test_SFD_2story_FB_UA_GRG_AC1_ElecBaseboard_FuelTankWH
    osw_file = '../../UpgradeCosts/tests/SFD_2story_FB_UA_GRG_AC1_ElecBaseboard_FuelTankWH.osw'
    puts "\nTesting #{File.basename(osw_file)}..."

    _test_measure(osw_file)

    args_hash = {}
    expected_capacities = {
      'heating_system_heating_capacity' => 100000.0,
      'heating_system_2_heating_capacity' => nil,
      'cooling_system_cooling_capacity' => 60000.0,
      'heat_pump_heating_capacity' => nil,
      'heat_pump_cooling_capacity' => nil,
      'heat_pump_backup_heating_capacity' => nil
    }
    expected_autosizing_factors = {
      'heating_system_heating_autosizing_factor' => 1.0,
      'heating_system_2_heating_autosizing_factor' => nil,
      'cooling_system_cooling_autosizing_factor' => 1.0,
      'heat_pump_heating_autosizing_factor' => nil,
      'heat_pump_cooling_autosizing_factor' => nil,
      'heat_pump_backup_heating_autosizing_factor' => nil
    }

    puts 'Retaining capacities and autosizing factors:'
    _window_upgrade(args_hash)
    _test_retaining_hvac_system_values(args_hash, expected_capacities, expected_autosizing_factors)

    _heating_system_upgrade(args_hash, expected_capacities, expected_autosizing_factors)
    _test_retaining_hvac_system_values(args_hash, expected_capacities, expected_autosizing_factors)

    _heating_system_2_upgrade(args_hash, expected_capacities, expected_autosizing_factors)
    _test_retaining_hvac_system_values(args_hash, expected_capacities, expected_autosizing_factors)

    _cooling_system_upgrade(args_hash, expected_capacities, expected_autosizing_factors)
    _test_retaining_hvac_system_values(args_hash, expected_capacities, expected_autosizing_factors)

    _heat_pump_upgrade(args_hash, expected_capacities, expected_autosizing_factors)
    _test_retaining_hvac_system_values(args_hash, expected_capacities, expected_autosizing_factors)

    puts 'Retaining existing heating system:'
    expected_values = {}

    expected_values['heat_pump_backup_type'] = nil
    _test_heat_pump_backup('false', HPXML::HVACTypeHeatPumpAirToAir, nil, expected_values)

    expected_values = {
      'heating_system_2_type' => HPXML::HVACTypeElectricResistance,
      'heating_system_2_fuel' => HPXML::FuelTypeElectricity,
      'heating_system_2_heating_efficiency' => 1.0,
      'heating_system_2_heating_capacity' => 100000.0,
      'heating_system_2_heating_autosizing_factor' => 1.0
    }

    expected_values['heat_pump_backup_type'] = HPXML::HeatPumpBackupTypeSeparate
    _test_heat_pump_backup('true', HPXML::HVACTypeHeatPumpAirToAir, nil, expected_values)

    expected_values['heat_pump_backup_type'] = HPXML::HeatPumpBackupTypeSeparate
    _test_heat_pump_backup('true', HPXML::HVACTypeHeatPumpMiniSplit, nil, expected_values)

    expected_values['heat_pump_backup_type'] = HPXML::HeatPumpBackupTypeSeparate
    _test_heat_pump_backup('true', HPXML::HVACTypeHeatPumpMiniSplit, 'false', expected_values)

    expected_values['heat_pump_backup_type'] = HPXML::HeatPumpBackupTypeSeparate
    _test_heat_pump_backup('true', HPXML::HVACTypeHeatPumpMiniSplit, 'true', expected_values)

    puts 'Duct restriction:'
    expected_values = {
      'baseline_max_airflow_cfm' => nil,
      'heat_pump_heating_autosizing_limit' => nil,
      'heat_pump_cooling_autosizing_limit' => nil
    }

    expected_values['adjusted_fan_watts_per_cfm'] = nil
    _test_duct_restriction('false', nil, nil, expected_values)

    cfm = 1800.0
    expected_values = {
      'baseline_max_airflow_cfm' => cfm,
      'heat_pump_heating_autosizing_limit' => cfm / 400.0 * 12000.0,
      'heat_pump_cooling_autosizing_limit' => cfm / 400.0 * 12000.0
    }

    expected_values['adjusted_fan_watts_per_cfm'] = 0.166
    _test_duct_restriction('true', 1200.0, 0.375, expected_values)

    expected_values['adjusted_fan_watts_per_cfm'] = 0.195
    _test_duct_restriction('true', 1300.0, 0.375, expected_values)

    expected_values['adjusted_fan_watts_per_cfm'] = 0.227
    _test_duct_restriction('true', 1400.0, 0.375, expected_values)

    expected_values['adjusted_fan_watts_per_cfm'] = 0.375
    _test_duct_restriction('true', cfm, 0.375, expected_values)
  end

  private

  def _window_upgrade(args_hash)
    puts "\twindow upgrade..."
    args_hash['window_ufactor'] = 0.29
    args_hash['window_shgc'] = 0.26
  end

  def _heating_system_upgrade(args_hash, expected_capacities, expected_autosizing_factors)
    puts "\theating system upgrade..."
    args_hash['heating_system_type'] = HPXML::HVACTypeFurnace
    args_hash['heat_pump_type'] = 'none'
    expected_capacities['heating_system_heating_capacity'] = nil
    expected_capacities['heat_pump_heating_capacity'] = nil
    expected_capacities['heat_pump_cooling_capacity'] = nil
    expected_capacities['heat_pump_backup_heating_capacity'] = nil
    expected_autosizing_factors['heating_system_heating_autosizing_factor'] = nil
    expected_autosizing_factors['heat_pump_heating_autosizing_factor'] = nil
    expected_autosizing_factors['heat_pump_cooling_autosizing_factor'] = nil
    expected_autosizing_factors['heat_pump_backup_heating_autosizing_factor'] = nil
  end

  def _heating_system_2_upgrade(args_hash, expected_capacities, expected_autosizing_factors)
    puts "\tsecondary heating system upgrade..."
    args_hash['heating_system_2_type'] = HPXML::HVACTypeFireplace
    expected_capacities['heating_system_2_heating_capacity'] = nil
    expected_autosizing_factors['heating_system_2_heating_autosizing_factor'] = nil
  end

  def _cooling_system_upgrade(args_hash, expected_capacities, expected_autosizing_factors)
    puts "\tcooling system upgrade..."
    args_hash['cooling_system_type'] = HPXML::HVACTypeCentralAirConditioner
    args_hash['heat_pump_type'] = 'none'
    expected_capacities['cooling_system_cooling_capacity'] = nil
    expected_capacities['heat_pump_heating_capacity'] = nil
    expected_capacities['heat_pump_cooling_capacity'] = nil
    expected_capacities['heat_pump_backup_heating_capacity'] = nil
    expected_autosizing_factors['cooling_system_cooling_autosizing_factor'] = nil
    expected_autosizing_factors['heat_pump_heating_autosizing_factor'] = nil
    expected_autosizing_factors['heat_pump_cooling_autosizing_factor'] = nil
    expected_autosizing_factors['heat_pump_backup_heating_autosizing_factor'] = nil
  end

  def _heat_pump_upgrade(args_hash, expected_capacities, expected_autosizing_factors)
    puts "\theat pump upgrade..."
    args_hash['heating_system_type'] = 'none'
    args_hash['cooling_system_type'] = 'none'
    args_hash['heat_pump_type'] = HPXML::HVACTypeHeatPumpAirToAir
    expected_capacities['heating_system_heating_capacity'] = nil
    expected_capacities['cooling_system_cooling_capacity'] = nil
    expected_capacities['heat_pump_heating_capacity'] = nil
    expected_capacities['heat_pump_cooling_capacity'] = nil
    expected_capacities['heat_pump_backup_heating_capacity'] = nil
    expected_autosizing_factors['heating_system_heating_autosizing_factor'] = nil
    expected_autosizing_factors['cooling_system_cooling_autosizing_factor'] = nil
    expected_autosizing_factors['heat_pump_heating_autosizing_factor'] = nil
    expected_autosizing_factors['heat_pump_cooling_autosizing_factor'] = nil
    expected_autosizing_factors['heat_pump_backup_heating_autosizing_factor'] = nil
  end

  def _test_measure(osw_file)
    require 'json'

    this_dir = File.dirname(__FILE__)
    osw = File.absolute_path("#{this_dir}/#{osw_file}")

    measures = {}

    osw_hash = JSON.parse(File.read(osw))
    measures_dir = File.join(File.dirname(__FILE__), osw_hash['measure_paths'][0])
    osw_hash['steps'].each do |step|
      measures[step['measure_dir_name']] = [step['arguments']]
    end

    model = OpenStudio::Model::Model.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # Apply measure
    success = apply_measures(measures_dir, measures, runner, model)

    # Report warnings/errors
    runner.result.stepWarnings.each do |s|
      puts "Warning: #{s}"
    end
    runner.result.stepErrors.each do |s|
      puts "Error: #{s}"
    end

    assert(success)
  end

  def _test_retaining_hvac_system_values(args_hash, expected_capacities, expected_autosizing_factors)
    this_dir = File.dirname(__FILE__)
    hpxml_path = File.join(this_dir, '../../UpgradeCosts/tests/in.xml')
    hpxml = HPXML.new(hpxml_path: hpxml_path)

    # Create instance of the measure
    measure = ApplyUpgrade.new

    hpxml.buildings.each do |hpxml_bldg|
      # Check for correct capacity values
      hvac_system_upgrades = measure.get_hvac_system_upgrades(hpxml_bldg, args_hash)
      actual_capacities, actual_autosizing_factors, _ = measure.get_hvac_system_values(hpxml_bldg, hvac_system_upgrades)

      expected_capacities.each do |str, val|
        if val.nil?
          assert_nil(actual_capacities[str])
        else
          assert_equal(val, actual_capacities[str])
        end
      end

      expected_autosizing_factors.each do |str, val|
        if val.nil?
          assert_nil(actual_autosizing_factors[str])
        else
          assert_equal(val, actual_autosizing_factors[str])
        end
      end
    end
  end

  def _test_heat_pump_backup(heat_pump_backup_use_existing_system, heat_pump_type, heat_pump_is_ducted, expected_values)
    this_dir = File.dirname(__FILE__)
    hpxml_path = File.join(this_dir, '../../UpgradeCosts/tests/in.xml')
    hpxml = HPXML.new(hpxml_path: hpxml_path)

    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    measures = { 'ResStockArguments' => [{ 'heat_pump_backup_use_existing_system' => heat_pump_backup_use_existing_system }],
                 'BuildResidentialHPXML' => [{ 'heat_pump_type' => heat_pump_type,
                                               'heat_pump_is_ducted' => heat_pump_is_ducted }] }

    # Create instance of the measure
    measure = ApplyUpgrade.new

    hpxml.buildings.each do |hpxml_bldg|
      heating_system = measure.get_heating_system(hpxml_bldg)
      if heating_system.nil?
        assert_nil(expected_values['heat_pump_backup_type'])
        puts "\thpxml.heating_systems.size=#{hpxml_bldg.heating_systems.size}..."
        return
      end

      puts "\theat_pump_type='#{heat_pump_type}', heat_pump_is_ducted='#{heat_pump_is_ducted}'..."

      measure.set_existing_system_as_heat_pump_backup(runner, measures, hpxml_bldg)
      actual_values = measures['BuildResidentialHPXML'][0]

      expected_values.each do |str, val|
        if val.nil?
          assert_nil(actual_values[str])
        else
          assert_equal(val, actual_values[str])
        end
      end
    end
  end

  def _test_duct_restriction(heat_pump_sizing_is_duct_limited, upgrade_max_airflow_cfm, fan_watts_per_cfm, expected_values)
    this_dir = File.dirname(__FILE__)
    hpxml_path = File.join(this_dir, '../../UpgradeCosts/tests/in.xml')
    hpxml = HPXML.new(hpxml_path: hpxml_path)

    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    measures = { 'ResStockArguments' => [{ 'heat_pump_sizing_is_duct_limited' => heat_pump_sizing_is_duct_limited }],
                 'BuildResidentialHPXML' => [{ 'heat_pump_type' => HPXML::HVACTypeHeatPumpAirToAir }] }

    # Create instance of the measure
    measure = ApplyUpgrade.new

    hpxml.buildings.each do |hpxml_bldg|
      baseline_max_airflow_cfm = measure.set_autosizing_limits(runner, measures, hpxml_bldg)
      actual_values = measures['BuildResidentialHPXML'][0]
      actual_values['baseline_max_airflow_cfm'] = baseline_max_airflow_cfm

      puts "\tbaseline_max_airflow_cfm='#{baseline_max_airflow_cfm}', upgrade_max_airflow_cfm='#{upgrade_max_airflow_cfm}', fan_watts_per_cfm='#{fan_watts_per_cfm}'..."

      if not baseline_max_airflow_cfm.nil?
        adjusted_fan_watts_per_cfm = measure.get_adjusted_fan_watts_per_cfm(baseline_max_airflow_cfm, upgrade_max_airflow_cfm, fan_watts_per_cfm)
        actual_values['adjusted_fan_watts_per_cfm'] = adjusted_fan_watts_per_cfm
      end

      expected_values.each do |str, val|
        if val.nil?
          assert_nil(actual_values[str])
        else
          assert_in_epsilon(val, actual_values[str], 0.01)
        end
      end
    end
  end
end
