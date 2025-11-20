# frozen_string_literal: true

require 'openstudio'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
require_relative '../measure'
require_relative '../../ResStockArgumentsPostHPXML/measure'

class ApplyUpgradeTest < Minitest::Test
  def test_SFD_1story_FB_UA_GRG_MSHP_FuelTanklessWH
    osw_file = '../../UpgradeCosts/tests/SFD_1story_FB_UA_GRG_MSHP_FuelTanklessWH.osw'
    puts "\nTesting #{File.basename(osw_file)}..."

    _test_measure(osw_file)

    puts 'Retaining capacities and autosizing factors:'

    expected_values = {
      'heating_system_heating_capacity' => nil,
      'heating_system_2_heating_capacity' => nil,
      'cooling_system_cooling_capacity' => nil,
      'heat_pump_heating_capacity' => 60000.0,
      'heat_pump_cooling_capacity' => 60000.0,
      'heat_pump_backup_heating_capacity' => 100000.0,
      'heating_system_heating_autosizing_factor' => nil,
      'heating_system_2_heating_autosizing_factor' => nil,
      'cooling_system_cooling_autosizing_factor' => nil,
      'heat_pump_heating_autosizing_factor' => 1.0,
      'heat_pump_cooling_autosizing_factor' => 1.0,
      'heat_pump_backup_heating_autosizing_factor' => 1.0
    }
    _test_retaining_hvac_system_values('Windows', expected_values)

    expected_values['heat_pump_heating_capacity'] = nil
    expected_values['heat_pump_cooling_capacity'] = nil
    expected_values['heat_pump_backup_heating_capacity'] = nil
    expected_values['heat_pump_heating_autosizing_factor'] = nil
    expected_values['heat_pump_cooling_autosizing_factor'] = nil
    expected_values['heat_pump_backup_heating_autosizing_factor'] = nil
    _test_retaining_hvac_system_values('Primary Heating System', expected_values)

    expected_values['heat_pump_heating_capacity'] = 60000.0
    expected_values['heat_pump_cooling_capacity'] = 60000.0
    expected_values['heat_pump_backup_heating_capacity'] = 100000.0
    expected_values['heat_pump_heating_autosizing_factor'] = 1.0
    expected_values['heat_pump_cooling_autosizing_factor'] = 1.0
    expected_values['heat_pump_backup_heating_autosizing_factor'] = 1.0
    _test_retaining_hvac_system_values('Secondary Heating System', expected_values)

    expected_values['heat_pump_heating_capacity'] = nil
    expected_values['heat_pump_cooling_capacity'] = nil
    expected_values['heat_pump_backup_heating_capacity'] = nil
    expected_values['heat_pump_heating_autosizing_factor'] = nil
    expected_values['heat_pump_cooling_autosizing_factor'] = nil
    expected_values['heat_pump_backup_heating_autosizing_factor'] = nil
    _test_retaining_hvac_system_values('Cooling System', expected_values)

    _test_retaining_hvac_system_values('Heat Pump', expected_values)

    puts 'Retaining existing heating system:'
    expected_values = {}

    expected_values['heat_pump_backup_type'] = nil
    _test_heat_pump_backup(false, 'Central HP, SEER2 12.4, HSPF2 6.6', expected_values)

    expected_values['heat_pump_backup_type'] = nil
    _test_heat_pump_backup(true, 'Central HP, SEER2 12.4, HSPF2 6.6', expected_values)

    expected_values['heat_pump_backup_type'] = nil
    _test_heat_pump_backup(true, 'Ductless Mini-Split HP, SEER2 19.0, HSPF2 9.0', expected_values)

    puts 'Duct restriction:'
    expected_values = {
      'max_airflow_cfm' => nil,
      'autosizing_limit' => nil,
      'baseline_max_airflow_cfm' => nil,
      'heat_pump_heating_autosizing_limit' => nil,
      'heat_pump_cooling_autosizing_limit' => nil,
    }

    expected_values['adjusted_fan_watts_per_cfm'] = nil
    _test_duct_restriction(true, nil, nil, expected_values)
  end

  def test_SFD_1story_UB_UA_GRG_ACV_FuelFurnace_PortableHeater_HPWH
    osw_file = '../../UpgradeCosts/tests/SFD_1story_UB_UA_GRG_ACV_FuelFurnace_PortableHeater_HPWH.osw'
    puts "\nTesting #{File.basename(osw_file)}..."

    _test_measure(osw_file)

    puts 'Retaining capacities and autosizing factors:'

    expected_values = {
      'heating_system_heating_capacity' => 100000.0,
      'heating_system_2_heating_capacity' => 20000.0,
      'cooling_system_cooling_capacity' => 60000.0,
      'heat_pump_heating_capacity' => nil,
      'heat_pump_cooling_capacity' => nil,
      'heat_pump_backup_heating_capacity' => nil,
      'heating_system_heating_autosizing_factor' => 1.0,
      'heating_system_2_heating_autosizing_factor' => 1.0,
      'cooling_system_cooling_autosizing_factor' => 1.0,
      'heat_pump_heating_autosizing_factor' => nil,
      'heat_pump_cooling_autosizing_factor' => nil,
      'heat_pump_backup_heating_autosizing_factor' => nil
    }
    _test_retaining_hvac_system_values('Windows', expected_values)

    expected_values['heating_system_heating_capacity'] = nil
    expected_values['heating_system_heating_autosizing_factor'] = nil
    _test_retaining_hvac_system_values('Primary Heating System', expected_values)

    expected_values['heating_system_heating_capacity'] = 100000.0
    expected_values['heating_system_heating_autosizing_factor'] = 1.0
    expected_values['heating_system_2_heating_capacity'] = nil
    expected_values['heating_system_2_heating_autosizing_factor'] = nil
    _test_retaining_hvac_system_values('Secondary Heating System', expected_values)

    expected_values['heating_system_2_heating_capacity'] = 20000.0
    expected_values['heating_system_2_heating_autosizing_factor'] = 1.0
    expected_values['cooling_system_cooling_capacity'] = nil
    expected_values['cooling_system_cooling_autosizing_factor'] = nil
    _test_retaining_hvac_system_values('Cooling System', expected_values)

    expected_values['heating_system_heating_capacity'] = nil
    expected_values['heating_system_heating_autosizing_factor'] = nil
    _test_retaining_hvac_system_values('Heat Pump', expected_values)

    puts 'Retaining existing heating system:'
    expected_values = {}

    expected_values['heat_pump_backup_type'] = nil
    _test_heat_pump_backup(false, 'Central HP, SEER2 12.4, HSPF2 6.6', expected_values)

    expected_values = {
      'heat_pump_backup_fuel' => HPXML::FuelTypeNaturalGas,
      'heat_pump_backup_heating_efficiency' => 0.925,
      'heat_pump_backup_heating_capacity' => 100000.0,
      'heat_pump_backup_heating_autosizing_factor' => 1.0
    }

    expected_values['heat_pump_backup_type'] = HPXML::HeatPumpBackupTypeIntegrated
    _test_heat_pump_backup(true, 'Central HP, SEER2 12.4, HSPF2 6.6', expected_values)

    expected_values = {
      'heat_pump_heating_load_served' => 1.0,
      'heating_system_2_type' => HPXML::HVACTypeFurnace,
      'heating_system_2_fuel' => HPXML::FuelTypeNaturalGas,
      'heating_system_2_efficiency' => 0.925,
      'heating_system_2_heating_capacity' => 100000.0,
      'heating_system_2_heating_autosizing_factor' => 1.0
    }

    expected_values['heat_pump_backup_type'] = HPXML::HeatPumpBackupTypeSeparate
    _test_heat_pump_backup(true, 'Ductless Mini-Split HP, SEER2 19.0, HSPF2 9.0', expected_values)

    puts 'Duct restriction:'
    expected_values = {
      'baseline_max_airflow_cfm' => nil,
      'heat_pump_heating_autosizing_limit' => nil,
      'heat_pump_cooling_autosizing_limit' => nil
    }

    expected_values['adjusted_fan_watts_per_cfm'] = nil
    _test_duct_restriction(false, nil, nil, expected_values)

    cfm = 2000.0 / 0.75
    expected_values = {
      'baseline_max_airflow_cfm' => cfm,
      'heat_pump_heating_autosizing_limit' => cfm / 400.0 * 12000.0,
      'heat_pump_cooling_autosizing_limit' => cfm / 400.0 * 12000.0
    }

    expected_values['adjusted_fan_watts_per_cfm'] = 0.076
    _test_duct_restriction(true, 1200.0, 0.375, expected_values)

    expected_values['adjusted_fan_watts_per_cfm'] = 0.089
    _test_duct_restriction(true, 1300.0, 0.375, expected_values)

    expected_values['adjusted_fan_watts_per_cfm'] = 0.103
    _test_duct_restriction(true, 1400.0, 0.375, expected_values)

    expected_values['adjusted_fan_watts_per_cfm'] = 0.375
    _test_duct_restriction(true, cfm, 0.375, expected_values)
  end

  def test_SFD_2story_CS_UA_AC2_FuelBoiler_FuelTankWH
    osw_file = '../../UpgradeCosts/tests/SFD_2story_CS_UA_AC2_FuelBoiler_FuelTankWH.osw'
    puts "\nTesting #{File.basename(osw_file)}..."

    _test_measure(osw_file)

    puts 'Retaining capacities and autosizing factors:'

    expected_values = {
      'heating_system_heating_capacity' => 100000.0,
      'heating_system_2_heating_capacity' => nil,
      'cooling_system_cooling_capacity' => 60000.0,
      'heat_pump_heating_capacity' => nil,
      'heat_pump_cooling_capacity' => nil,
      'heat_pump_backup_heating_capacity' => nil,
      'heating_system_heating_autosizing_factor' => 1.0,
      'heating_system_2_heating_autosizing_factor' => nil,
      'cooling_system_cooling_autosizing_factor' => 1.0,
      'heat_pump_heating_autosizing_factor' => nil,
      'heat_pump_cooling_autosizing_factor' => nil,
      'heat_pump_backup_heating_autosizing_factor' => nil
    }
    _test_retaining_hvac_system_values('Windows', expected_values)

    expected_values['heating_system_heating_capacity'] = nil
    expected_values['heating_system_heating_autosizing_factor'] = nil
    _test_retaining_hvac_system_values('Primary Heating System', expected_values)

    expected_values['heating_system_heating_capacity'] = 100000.0
    expected_values['heating_system_heating_autosizing_factor'] = 1.0
    _test_retaining_hvac_system_values('Secondary Heating System', expected_values)

    expected_values['cooling_system_cooling_capacity'] = nil
    expected_values['cooling_system_cooling_autosizing_factor'] = nil
    _test_retaining_hvac_system_values('Cooling System', expected_values)

    expected_values['heating_system_heating_capacity'] = nil
    expected_values['heating_system_heating_autosizing_factor'] = nil
    _test_retaining_hvac_system_values('Heat Pump', expected_values)

    puts 'Retaining existing heating system:'
    expected_values = {}

    expected_values['heat_pump_backup_type'] = nil
    _test_heat_pump_backup(false, 'Central HP, SEER2 12.4, HSPF2 6.6', expected_values)

    expected_values = {
      'heat_pump_heating_load_served' => 1.0,
      'heating_system_2_type' => HPXML::HVACTypeBoiler,
      'heating_system_2_fuel' => HPXML::FuelTypeNaturalGas,
      'heating_system_2_efficiency' => 0.9,
      'heating_system_2_heating_capacity' => 100000.0,
      'heating_system_2_heating_autosizing_factor' => 1.0
    }

    expected_values['heat_pump_backup_type'] = HPXML::HeatPumpBackupTypeSeparate
    _test_heat_pump_backup(true, 'Central HP, SEER2 12.4, HSPF2 6.6', expected_values)

    expected_values['heat_pump_backup_type'] = HPXML::HeatPumpBackupTypeSeparate
    _test_heat_pump_backup(true, 'Ductless Mini-Split HP, SEER2 19.0, HSPF2 9.0', expected_values)

    puts 'Duct restriction:'
    expected_values = {
      'baseline_max_airflow_cfm' => nil,
      'heat_pump_heating_autosizing_limit' => nil,
      'heat_pump_cooling_autosizing_limit' => nil
    }

    expected_values['adjusted_fan_watts_per_cfm'] = nil
    _test_duct_restriction(false, nil, nil, expected_values)

    cfm = 1800.0
    expected_values = {
      'baseline_max_airflow_cfm' => cfm,
      'heat_pump_heating_autosizing_limit' => cfm / 400.0 * 12000.0,
      'heat_pump_cooling_autosizing_limit' => cfm / 400.0 * 12000.0
    }

    expected_values['adjusted_fan_watts_per_cfm'] = 0.167
    _test_duct_restriction(true, 1200.0, 0.375, expected_values)

    expected_values['adjusted_fan_watts_per_cfm'] = 0.196
    _test_duct_restriction(true, 1300.0, 0.375, expected_values)

    expected_values['adjusted_fan_watts_per_cfm'] = 0.227
    _test_duct_restriction(true, 1400.0, 0.375, expected_values)

    expected_values['adjusted_fan_watts_per_cfm'] = 0.375
    _test_duct_restriction(true, cfm, 0.375, expected_values)
  end

  def test_SFD_2story_FB_UA_GRG_AC1_ElecBaseboard_FuelTankWH
    osw_file = '../../UpgradeCosts/tests/SFD_2story_FB_UA_GRG_AC1_ElecBaseboard_FuelTankWH.osw'
    puts "\nTesting #{File.basename(osw_file)}..."

    _test_measure(osw_file)

    puts 'Retaining capacities and autosizing factors:'

    expected_values = {
      'heating_system_heating_capacity' => 100000.0,
      'heating_system_2_heating_capacity' => nil,
      'cooling_system_cooling_capacity' => 60000.0,
      'heat_pump_heating_capacity' => nil,
      'heat_pump_cooling_capacity' => nil,
      'heat_pump_backup_heating_capacity' => nil,
      'heating_system_heating_autosizing_factor' => 1.0,
      'heating_system_2_heating_autosizing_factor' => nil,
      'cooling_system_cooling_autosizing_factor' => 1.0,
      'heat_pump_heating_autosizing_factor' => nil,
      'heat_pump_cooling_autosizing_factor' => nil,
      'heat_pump_backup_heating_autosizing_factor' => nil
    }
    _test_retaining_hvac_system_values('Windows', expected_values)

    expected_values['heating_system_heating_capacity'] = nil
    expected_values['heating_system_heating_autosizing_factor'] = nil
    _test_retaining_hvac_system_values('Primary Heating System', expected_values)

    expected_values['heating_system_heating_capacity'] = 100000.0
    expected_values['heating_system_heating_autosizing_factor'] = 1.0
    _test_retaining_hvac_system_values('Secondary Heating System', expected_values)

    expected_values['cooling_system_cooling_capacity'] = nil
    expected_values['cooling_system_cooling_autosizing_factor'] = nil
    _test_retaining_hvac_system_values('Cooling System', expected_values)

    expected_values['heating_system_heating_capacity'] = nil
    expected_values['heating_system_heating_autosizing_factor'] = nil
    _test_retaining_hvac_system_values('Heat Pump', expected_values)

    puts 'Retaining existing heating system:'
    expected_values = {}

    expected_values['heat_pump_backup_type'] = nil
    _test_heat_pump_backup(false, 'Central HP, SEER2 12.4, HSPF2 6.6', expected_values)

    expected_values = {
      'heat_pump_heating_load_served' => 1.0,
      'heating_system_2_type' => HPXML::HVACTypeElectricResistance,
      'heating_system_2_fuel' => HPXML::FuelTypeElectricity,
      'heating_system_2_efficiency' => 1.0,
      'heating_system_2_heating_capacity' => 100000.0,
      'heating_system_2_heating_autosizing_factor' => 1.0
    }

    expected_values['heat_pump_backup_type'] = HPXML::HeatPumpBackupTypeSeparate
    _test_heat_pump_backup(true, 'Central HP, SEER2 12.4, HSPF2 6.6', expected_values)

    expected_values['heat_pump_backup_type'] = HPXML::HeatPumpBackupTypeSeparate
    _test_heat_pump_backup(true, 'Ductless Mini-Split HP, SEER2 19.0, HSPF2 9.0', expected_values)

    puts 'Duct restriction:'
    expected_values = {
      'baseline_max_airflow_cfm' => nil,
      'heat_pump_heating_autosizing_limit' => nil,
      'heat_pump_cooling_autosizing_limit' => nil
    }

    expected_values['adjusted_fan_watts_per_cfm'] = nil
    _test_duct_restriction(false, nil, nil, expected_values)

    cfm = 1800.0
    expected_values = {
      'baseline_max_airflow_cfm' => cfm,
      'heat_pump_heating_autosizing_limit' => cfm / 400.0 * 12000.0,
      'heat_pump_cooling_autosizing_limit' => cfm / 400.0 * 12000.0
    }

    expected_values['adjusted_fan_watts_per_cfm'] = 0.166
    _test_duct_restriction(true, 1200.0, 0.375, expected_values)

    expected_values['adjusted_fan_watts_per_cfm'] = 0.195
    _test_duct_restriction(true, 1300.0, 0.375, expected_values)

    expected_values['adjusted_fan_watts_per_cfm'] = 0.227
    _test_duct_restriction(true, 1400.0, 0.375, expected_values)

    expected_values['adjusted_fan_watts_per_cfm'] = 0.375
    _test_duct_restriction(true, cfm, 0.375, expected_values)
  end

  private

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

  def _test_retaining_hvac_system_values(upgrade, expected_values)
    puts "\t#{upgrade} upgrade..."

    this_dir = File.dirname(__FILE__)
    hpxml_path = File.join(this_dir, '../../UpgradeCosts/tests/in.xml')
    hpxml_existing = HPXML.new(hpxml_path: hpxml_path)
    hpxml = HPXML.new
    hpxml.buildings.add(building_id: 'MyBuilding')
    hpxml_bldg = hpxml.buildings[-1]

    hpxml_bldg_existing = hpxml_existing.buildings[0]
    hpxml_bldg_existing.heating_systems.each do |heating_system|
      hpxml_bldg.heating_systems.add(**heating_system.to_h)
      hpxml_bldg.heating_systems[-1].heating_capacity = nil
      hpxml_bldg.heating_systems[-1].heating_autosizing_factor = nil
    end
    hpxml_bldg_existing.cooling_systems.each do |cooling_system|
      hpxml_bldg.cooling_systems.add(**cooling_system.to_h)
      hpxml_bldg.cooling_systems[-1].cooling_capacity = nil
      hpxml_bldg.cooling_systems[-1].cooling_autosizing_factor = nil
    end
    hpxml_bldg_existing.heat_pumps.each do |heat_pump|
      hpxml_bldg.heat_pumps.add(**heat_pump.to_h)
      hpxml_bldg.heat_pumps[-1].heating_capacity = nil
      hpxml_bldg.heat_pumps[-1].cooling_capacity = nil
      hpxml_bldg.heat_pumps[-1].backup_heating_capacity = nil
      hpxml_bldg.heat_pumps[-1].heating_autosizing_factor = nil
      hpxml_bldg.heat_pumps[-1].cooling_autosizing_factor = nil
      hpxml_bldg.heat_pumps[-1].backup_heating_autosizing_factor = nil
    end

    if upgrade == 'Windows'
      hpxml_bldg.windows.add(id: "Window#{hpxml_bldg.windows.size + 1}",
                             ufactor: 0.49,
                             shgc: 0.56)
    elsif upgrade == 'Primary Heating System'
      hpxml_bldg.heating_systems.reverse_each do |heating_system|
        next unless heating_system.primary_system

        heating_system.delete
      end
      hpxml_bldg.heat_pumps.clear
      hpxml_bldg.heating_systems.add(id: "HeatingSystem#{hpxml_bldg.heating_systems.size + 1}",
                                     heating_system_type: HPXML::HVACTypeFurnace,
                                     heating_efficiency_afue: 0.8,
                                     primary_system: true)
    elsif upgrade == 'Secondary Heating System'
      hpxml_bldg.heating_systems.reverse_each do |heating_system|
        next if heating_system.primary_system

        heating_system.delete
      end
      hpxml_bldg.heating_systems.add(id: "HeatingSystem#{hpxml_bldg.heating_systems.size + 1}",
                                     heating_system_type: HPXML::HVACTypeFireplace,
                                     heating_efficiency_percent: 0.7)
    elsif upgrade == 'Cooling System'
      hpxml_bldg.cooling_systems.clear
      hpxml_bldg.heat_pumps.clear
      hpxml_bldg.cooling_systems.add(id: "CoolingSystem#{hpxml_bldg.cooling_systems.size + 1}",
                                     cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                                     cooling_efficiency_seer2: 12.4,
                                     compressor_type: HPXML::HVACCompressorTypeSingleStage,
                                     primary_system: true)
    elsif upgrade == 'Heat Pump'
      hpxml_bldg.heating_systems.reverse_each do |heating_system|
        next unless heating_system.primary_system

        heating_system.delete
      end
      hpxml_bldg.cooling_systems.clear
      hpxml_bldg.heat_pumps.clear
      hpxml_bldg.heat_pumps.add(id: "HeatPump#{hpxml_bldg.heat_pumps.size + 1}",
                                heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                                cooling_efficiency_seer2: 12.4,
                                heating_efficiency_hspf2: 6.6,
                                compressor_type: HPXML::HVACCompressorTypeSingleStage,
                                primary_heating_system: true,
                                primary_cooling_system: true)
    end

    hpxml_existing.buildings.each do |hpxml_bldg_existing|
      # Check for correct capacity and autosizing factor values
      ResStockArgumentsPostHPXML.set_hvac_systems(hpxml_bldg_existing, hpxml_bldg)

      actual_values = {}
      if hpxml_bldg.heating_systems.count { |hs| hs.primary_system } > 0
        heating_system = hpxml_bldg.heating_systems.find { |hs| hs.primary_system }
        actual_values['heating_system_heating_capacity'] = heating_system.heating_capacity
        actual_values['heating_system_heating_autosizing_factor'] = heating_system.heating_autosizing_factor
      end
      if hpxml_bldg.heating_systems.count { |hs| !hs.primary_system } > 0
        heating_system_2 = hpxml_bldg.heating_systems.find { |hs| !hs.primary_system }
        actual_values['heating_system_2_heating_capacity'] = heating_system_2.heating_capacity
        actual_values['heating_system_2_heating_autosizing_factor'] = heating_system_2.heating_autosizing_factor
      end
      if hpxml_bldg.cooling_systems.count { |cs| cs.primary_system } > 0
        cooling_system = hpxml_bldg.cooling_systems.find { |cs| cs.primary_system }
        actual_values['cooling_system_cooling_capacity'] = cooling_system.cooling_capacity
        actual_values['cooling_system_cooling_autosizing_factor'] = cooling_system.cooling_autosizing_factor
      end
      if hpxml_bldg.heat_pumps.count { |hp| hp.primary_heating_system && hp.primary_cooling_system } > 0
        heat_pump = hpxml_bldg.heat_pumps.find { |hp| hp.primary_heating_system && hp.primary_cooling_system }
        actual_values['heat_pump_heating_capacity'] = heat_pump.cooling_capacity
        actual_values['heat_pump_cooling_capacity'] = heat_pump.cooling_capacity
        actual_values['heat_pump_backup_heating_capacity'] = heat_pump.backup_heating_capacity
        actual_values['heat_pump_heating_autosizing_factor'] = heat_pump.heating_autosizing_factor
        actual_values['heat_pump_cooling_autosizing_factor'] = heat_pump.cooling_autosizing_factor
        actual_values['heat_pump_backup_heating_autosizing_factor'] = heat_pump.backup_heating_autosizing_factor
      end

      expected_values.each do |str, val|
        if val.nil?
          assert_nil(actual_values[str])
        else
          assert_equal(val, actual_values[str])
        end
      end
    end
  end

  def _test_heat_pump_backup(heat_pump_backup_use_existing_system, hvac_heat_pump, expected_values)
    this_dir = File.dirname(__FILE__)
    hpxml_path = File.join(this_dir, '../../UpgradeCosts/tests/in.xml')
    hpxml_existing = HPXML.new(hpxml_path: hpxml_path)
    hpxml = HPXML.new
    hpxml.buildings.add(building_id: 'MyBuilding')
    hpxml_bldg = hpxml.buildings[-1]

    if hvac_heat_pump.include?('Ductless')
      _add_ductless_heat_pump(hpxml_bldg)
    else
      _add_ducted_heat_pump(hpxml_bldg)
    end

    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    args = { :hvac_heat_pump_backup_use_existing_system => heat_pump_backup_use_existing_system }

    # Create instance of the measure
    measure = ResStockArgumentsPostHPXML.new

    hpxml_existing.buildings.each do |hpxml_bldg_existing|
      puts "\thvac_heat_pump='#{hvac_heat_pump}'..."

      measure.set_existing_system_as_heat_pump_backup(runner, hpxml_bldg_existing, hpxml_bldg, args)

      if expected_values['heat_pump_backup_type'].nil?
        assert_nil(hpxml_bldg.heat_pumps[0].backup_type)
        return
      end

      actual_values = { 'heat_pump_backup_type' => hpxml_bldg.heat_pumps[0].backup_type,
                        'heat_pump_backup_fuel' => hpxml_bldg.heat_pumps[0].backup_heating_fuel,
                        'heat_pump_backup_heating_efficiency' => hpxml_bldg.heat_pumps[0].backup_heating_efficiency_afue,
                        'heat_pump_backup_heating_capacity' => hpxml_bldg.heat_pumps[0].backup_heating_capacity,
                        'heat_pump_backup_heating_autosizing_factor' => hpxml_bldg.heat_pumps[0].backup_heating_autosizing_factor,
                        'heat_pump_heating_load_served' => hpxml_bldg.heat_pumps[0].fraction_heat_load_served }

      if hpxml_bldg.heating_systems.size > 0
        actual_values['heating_system_2_type'] = hpxml_bldg.heating_systems[0].heating_system_type
        actual_values['heating_system_2_fuel'] = hpxml_bldg.heating_systems[0].heating_system_fuel
        actual_values['heating_system_2_efficiency'] = !hpxml_bldg.heating_systems[0].heating_efficiency_afue.nil? ? hpxml_bldg.heating_systems[0].heating_efficiency_afue : hpxml_bldg.heating_systems[0].heating_efficiency_percent
        actual_values['heating_system_2_heating_capacity'] = hpxml_bldg.heating_systems[0].heating_capacity
        actual_values['heating_system_2_heating_autosizing_factor'] = hpxml_bldg.heating_systems[0].heating_autosizing_factor
      end

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
    hpxml_existing = HPXML.new(hpxml_path: hpxml_path)
    hpxml = HPXML.new
    hpxml.buildings.add(building_id: 'MyBuilding')
    hpxml_bldg = hpxml.buildings[-1]

    _add_ducted_heat_pump(hpxml_bldg)

    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    args = { :hvac_heat_pump_sizing_is_duct_limited => heat_pump_sizing_is_duct_limited }

    # Create instance of the measure
    measure = ResStockArgumentsPostHPXML.new

    hpxml_existing.buildings.each do |hpxml_bldg_existing|
      baseline_max_airflow_cfm = measure.set_autosizing_limits(runner, hpxml_bldg_existing, hpxml_bldg, args)

      actual_values = { 'baseline_max_airflow_cfm' => baseline_max_airflow_cfm,
                        'heat_pump_heating_autosizing_limit' => hpxml_bldg.heat_pumps[0].heating_autosizing_limit,
                        'heat_pump_cooling_autosizing_limit' => hpxml_bldg.heat_pumps[0].cooling_autosizing_limit }

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

  def _add_ducted_heat_pump(hpxml_bldg)
    hpxml_bldg.heat_pumps.add(id: "HeatPump#{hpxml_bldg.heat_pumps.size + 1}",
                              heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                              primary_heating_system: true,
                              primary_cooling_system: true)
    hpxml_bldg.hvac_distributions.add(id: "HVACDistribution#{hpxml_bldg.hvac_distributions.size + 1}")
    hpxml_bldg.heat_pumps[-1].distribution_system_idref = hpxml_bldg.hvac_distributions[-1].id
    hpxml_bldg.hvac_distributions[-1].ducts.add(id: "Ducts#{hpxml_bldg.hvac_distributions[-1].ducts.size + 1}")
  end

  def _add_ductless_heat_pump(hpxml_bldg)
    hpxml_bldg.heat_pumps.add(id: "HeatPump#{hpxml_bldg.heat_pumps.size + 1}",
                              heat_pump_type: HPXML::HVACTypeHeatPumpMiniSplit,
                              primary_heating_system: true,
                              primary_cooling_system: true)
  end

  def get_detailed_hvac_arguments(measures)
    # Returns a hash of detailed option properties (from the option TSV) for the given HVAC systems
    args = {}
    ['hvac_heating_system',
     'hvac_heating_system_2',
     'hvac_cooling_system',
     'hvac_heat_pump'].each do |parameter_name|
      tsv_filename = "#{parameter_name}.tsv"
      get_option_properties(args, tsv_filename, measures['ResStockArguments'][0][parameter_name])
    end
    return args
  end
end
