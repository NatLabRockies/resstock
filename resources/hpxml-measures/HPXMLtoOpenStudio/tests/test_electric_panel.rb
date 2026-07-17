# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'
require_relative 'util.rb'

class HPXMLtoOpenStudioElectricPanelTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    cleanup_results_files
  end

  def test_ashp_upgrade
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path) }
    hpxml, _hpxml_bldg = _create_hpxml('base-detailed-electric-panel.xml')
    XMLHelper.write_file(hpxml.to_doc(), @tmp_hpxml_path)
    _model, hpxml, hpxml_bldg = _test_measure(args_hash)
    electric_panel = hpxml_bldg.electric_panels[0]

    # Baseline
    assert_equal(16, electric_panel.breaker_spaces_total)
    assert_equal(11, electric_panel.breaker_spaces_occupied)
    assert_equal(16 - 11, electric_panel.breaker_spaces_headroom)
    assert_in_epsilon(9656.6, electric_panel.capacity_total_watts[0], 0.01)
    assert_in_epsilon(9656.6 / Float(HPXML::ElectricPanelVoltage240), electric_panel.capacity_total_amps[0], 0.01)
    assert_in_epsilon(electric_panel.max_current_rating - 9656.6 / Float(HPXML::ElectricPanelVoltage240), electric_panel.capacity_headroom_amps[0], 0.01)
    assert_in_epsilon(1.25 * 4500.0, electric_panel.capacity_total_watts[1], 0.01)
    assert_in_epsilon(1.25 * 4500.0 / Float(HPXML::ElectricPanelVoltage240), electric_panel.capacity_total_amps[1], 0.01)
    assert_in_epsilon(electric_panel.max_current_rating - (1.25 * 4500.0) / Float(HPXML::ElectricPanelVoltage240), electric_panel.capacity_headroom_amps[1], 0.01)

    # Upgrade
    # Not adding new HVAC
    electric_panel.headroom_spaces = nil
    electric_panel.rated_total_spaces = 16
    branch_circuits = electric_panel.branch_circuits
    service_feeders = electric_panel.service_feeders
    sf = service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeHeating }
    sf.power = 16942
    sf = service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeCooling }
    sf.power = 16942
    service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                        type: HPXML::ElectricPanelLoadTypeWaterHeater,
                        power: 4500,
                        is_new_load: true,
                        component_idrefs: [hpxml_bldg.water_heating_systems[0].id])
    branch_circuits.add(id: "BranchCircuit#{branch_circuits.size + 1}",
                        voltage: HPXML::ElectricPanelVoltage240,
                        occupied_spaces: 2,
                        component_idrefs: [hpxml_bldg.clothes_dryers[0].id])
    service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                        type: HPXML::ElectricPanelLoadTypeClothesDryer,
                        power: 5760,
                        is_new_load: true,
                        component_idrefs: [hpxml_bldg.clothes_dryers[0].id])
    branch_circuits.add(id: "BranchCircuit#{branch_circuits.size + 1}",
                        voltage: HPXML::ElectricPanelVoltage120,
                        occupied_spaces: 2,
                        component_idrefs: [hpxml_bldg.cooking_ranges[0].id])
    service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                        type: HPXML::ElectricPanelLoadTypeRangeOven,
                        power: 12000,
                        is_new_load: true,
                        component_idrefs: [hpxml_bldg.cooking_ranges[0].id])
    hpxml_bldg.plug_loads.add(id: "PlugLoad#{hpxml_bldg.plug_loads.size + 1}",
                              plug_load_type: HPXML::PlugLoadTypeElectricVehicleCharging)
    branch_circuits.add(id: "BranchCircuit#{branch_circuits.size + 1}",
                        voltage: HPXML::ElectricPanelVoltage240,
                        occupied_spaces: 2,
                        component_idrefs: [hpxml_bldg.plug_loads[-1].id])
    service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                        type: HPXML::ElectricPanelLoadTypeElectricVehicleCharging,
                        power: 1650,
                        is_new_load: true,
                        component_idrefs: [hpxml_bldg.plug_loads[-1].id])
    XMLHelper.write_file(hpxml.to_doc(), @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    electric_panel = hpxml_bldg.electric_panels[0]

    assert_equal(16, electric_panel.breaker_spaces_total)
    assert_equal(17, electric_panel.breaker_spaces_occupied)
    assert_equal(16 - 17, electric_panel.breaker_spaces_headroom)

    # Load-Based Part A
    assert_in_epsilon(24662.0, electric_panel.capacity_total_watts[0], 0.001)
    assert_in_epsilon(24662.0 / Float(HPXML::ElectricPanelVoltage240), electric_panel.capacity_total_amps[0], 0.01)
    assert_in_epsilon((electric_panel.max_current_rating - 24662.0 / Float(HPXML::ElectricPanelVoltage240)).round(1), electric_panel.capacity_headroom_amps[0], 0.01)

    # Meter-Based
    assert_in_epsilon(29535.0, electric_panel.capacity_total_watts[1], 0.001)
    assert_in_epsilon((29535.0 / Float(HPXML::ElectricPanelVoltage240)).round(1), electric_panel.capacity_total_amps[1], 0.01)
    assert_in_epsilon((electric_panel.max_current_rating - 29535.0 / Float(HPXML::ElectricPanelVoltage240)).round(1), electric_panel.capacity_headroom_amps[1], 0.01)

    # Adding new HVAC
    sf = service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeHeating }
    sf.is_new_load = true
    sf = service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeCooling }
    sf.is_new_load = true
    XMLHelper.write_file(hpxml.to_doc(), @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    electric_panel = hpxml_bldg.electric_panels[0]

    assert_equal(16, electric_panel.breaker_spaces_total)
    assert_equal(17, electric_panel.breaker_spaces_occupied)
    assert_equal(16 - 17, electric_panel.breaker_spaces_headroom)

    # Load-Based Part B
    assert_in_epsilon(34827.2, electric_panel.capacity_total_watts[0], 0.001)
    assert_in_epsilon((34827.2 / Float(HPXML::ElectricPanelVoltage240)).round(1), electric_panel.capacity_total_amps[0], 0.01)
    assert_in_epsilon((electric_panel.max_current_rating - 34827.2 / Float(HPXML::ElectricPanelVoltage240)).round(1), electric_panel.capacity_headroom_amps[0], 0.01)

    # Meter-Based
    assert_in_epsilon(46477.0, electric_panel.capacity_total_watts[1], 0.001)
    assert_in_epsilon((46477.0 / Float(HPXML::ElectricPanelVoltage240)).round(1), electric_panel.capacity_total_amps[1], 0.01)
    assert_in_epsilon((electric_panel.max_current_rating - 46477.0 / Float(HPXML::ElectricPanelVoltage240)).round(1), electric_panel.capacity_headroom_amps[1], 0.01)
  end

  def test_low_load
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path) }
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml.header.service_feeders_load_calculation_types = [HPXML::ElectricPanelLoadCalculationType2023ExistingDwellingLoadBased,
                                                           HPXML::ElectricPanelLoadCalculationType2023ExistingDwellingMeterBased]

    branch_circuits = hpxml_bldg.electric_panels[0].branch_circuits
    branch_circuits.add(id: 'Kitchen', occupied_spaces: 2)
    branch_circuits.add(id: 'Laundry', occupied_spaces: 1)
    branch_circuits.add(id: 'Other', occupied_spaces: 1)

    service_feeders = hpxml_bldg.electric_panels[0].service_feeders
    service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}", type: HPXML::ElectricPanelLoadTypeHeating, power: 0, component_idrefs: [hpxml_bldg.heating_systems[0].id])
    service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}", type: HPXML::ElectricPanelLoadTypeCooling, power: 0, component_idrefs: [hpxml_bldg.cooling_systems[0].id])
    service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}", type: HPXML::ElectricPanelLoadTypeWaterHeater, power: 0, component_idrefs: [hpxml_bldg.water_heating_systems[0].id])
    service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}", type: HPXML::ElectricPanelLoadTypeClothesDryer, power: 0, component_idrefs: [hpxml_bldg.clothes_dryers[0].id])
    service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}", type: HPXML::ElectricPanelLoadTypeDishwasher, power: 0, component_idrefs: [hpxml_bldg.dishwashers[0].id])
    service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}", type: HPXML::ElectricPanelLoadTypeRangeOven, power: 0, component_idrefs: [hpxml_bldg.cooking_ranges[0].id])
    service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}", type: HPXML::ElectricPanelLoadTypeLighting, power: 500) # 0
    service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}", type: HPXML::ElectricPanelLoadTypeKitchen, power: 1000) # 2
    service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}", type: HPXML::ElectricPanelLoadTypeLaundry, power: 1500) # 1
    service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}", type: HPXML::ElectricPanelLoadTypeOther, power: 2000) # 1

    XMLHelper.write_file(hpxml.to_doc(), @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    electric_panel = hpxml_bldg.electric_panels[0]

    assert_equal(7, electric_panel.breaker_spaces_total)
    assert_equal(4, electric_panel.breaker_spaces_occupied)
    assert_equal(3, electric_panel.breaker_spaces_headroom)
    assert_in_epsilon(5000.0, electric_panel.capacity_total_watts[0], 0.001)
    assert_in_epsilon(5000.0 / Float(HPXML::ElectricPanelVoltage240), electric_panel.capacity_total_amps[0], 0.01)
    assert_in_epsilon(electric_panel.max_current_rating - 5000.0 / Float(HPXML::ElectricPanelVoltage240), electric_panel.capacity_headroom_amps[0], 0.01)
    assert_in_epsilon(1.25 * 4500.0, electric_panel.capacity_total_watts[1], 0.001)
    assert_in_epsilon(1.25 * 4500.0 / Float(HPXML::ElectricPanelVoltage240), electric_panel.capacity_total_amps[1], 0.01)
    assert_in_epsilon(electric_panel.max_current_rating - (1.25 * 4500.0) / Float(HPXML::ElectricPanelVoltage240), electric_panel.capacity_headroom_amps[1], 0.01)
  end

  def test_hvac_120v_room_air_conditioner_only
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-room-ac-only.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 0)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 2011)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 0)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 0)
  end

  def test_hvac_240v_room_air_conditioner_only
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, hpxml_bldg = _create_hpxml('base-hvac-room-ac-only.xml')
    branch_circuits = hpxml_bldg.electric_panels[0].branch_circuits
    service_feeders = hpxml_bldg.electric_panels[0].service_feeders
    branch_circuits.add(id: "BranchCircuit#{branch_circuits.size + 1}",
                        voltage: HPXML::ElectricPanelVoltage240,
                        component_idrefs: [hpxml_bldg.cooling_systems[0].id])
    service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                        type: HPXML::ElectricPanelLoadTypeCooling,
                        component_idrefs: [hpxml_bldg.cooling_systems[0].id])

    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 0)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 4022)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 0)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 2)
  end

  def test_hvac_gas_furnace_only
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-furnace-gas-only.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 262.5)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 0)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 1)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 0)
  end

  def test_hvac_electric_furnace_only
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-furnace-elec-only.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 10729)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 0)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 2)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 0)
  end

  def test_hvac_large_electric_furnace_only
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, hpxml_bldg = _create_hpxml('base-hvac-furnace-elec-only.xml')
    hpxml_bldg.heating_systems[0].heating_capacity = 48000
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 14715)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 0)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 4)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 0)
  end

  def test_hvac_gas_furnace_and_central_air_conditioner
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 350)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 4382)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 1)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 2)
  end

  def test_hvac_electric_furnace_and_central_air_conditioner
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-furnace-elec-central-ac-1-speed.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 10608)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 4382)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 2)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 2)
  end

  def test_hvac_larger_electric_furnace_and_central_air_conditioner
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, hpxml_bldg = _create_hpxml('base-hvac-furnace-elec-central-ac-1-speed.xml')
    hpxml_bldg.heating_systems[0].heating_capacity = 48000
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 14547)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 4382)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 4)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 2)
  end

  def test_hvac_central_air_conditioner_only
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-central-ac-only-1-speed.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 0)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 4382)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 0)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 3)
  end

  def test_hvac_large_central_air_conditioner_only
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, hpxml_bldg = _create_hpxml('base-hvac-central-ac-only-1-speed.xml')
    hpxml_bldg.cooling_systems[0].cooling_capacity = 48000
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 0)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 8377)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 0)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 3)
  end

  def test_hvac_gas_boiler_only
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-boiler-gas-only.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 96)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 0)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 1)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 0)
  end

  def test_hvac_electric_boiler_only
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-boiler-elec-only.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 10549)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 0)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 2)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 0)
  end

  def test_hvac_large_electric_boiler_only
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, hpxml_bldg = _create_hpxml('base-hvac-boiler-elec-only.xml')
    hpxml_bldg.heating_systems[0].heating_capacity = 48000
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 14437)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 0)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 4)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 0)
  end

  def test_hvac_gas_boiler_and_central_air_conditioner
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-boiler-gas-central-ac-1-speed.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 96)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 4382)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 1)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 3)
  end

  def test_hvac_electric_boiler_and_central_air_conditioner
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, hpxml_bldg = _create_hpxml('base-hvac-boiler-gas-central-ac-1-speed.xml')
    hpxml_bldg.heating_systems[0].heating_system_fuel = HPXML::FuelTypeElectricity
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 11246)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 4382)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 2)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 3)
  end

  def test_hvac_large_electric_boiler_and_central_air_conditioner
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, hpxml_bldg = _create_hpxml('base-hvac-boiler-gas-central-ac-1-speed.xml')
    hpxml_bldg.heating_systems[0].heating_capacity = 48000
    hpxml_bldg.heating_systems[0].heating_system_fuel = HPXML::FuelTypeElectricity
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 15387)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 4382)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 4)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 3)
  end

  def test_hvac_ashp_without_backup
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
    hpxml_bldg.heat_pumps[0].backup_type = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 6379)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 6379)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 4)
  end

  def test_hvac_ashp_with_integrated_electric_backup
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 16379)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 6379)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 4)
  end

  def test_hvac_ashp_with_integrated_gas_backup_switchover
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 6379)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 6379)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 3)
  end

  def test_hvac_ashp_with_separate_gas_backup
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-backup-boiler.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 3412)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 3316)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 5)
  end

  def test_hvac_ashp_with_separate_gas_backup_switchover
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-backup-boiler-switchover-temperature.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 4388)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 4292)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 5)
  end

  def test_hvac_ashp_heating_only_with_integrated_electric_backup
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed-heating-only.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 16379)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 0)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 4)
  end

  def test_hvac_ashp_cooling_only_without_backup
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed-cooling-only.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 0)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 6379)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 4)
  end

  def test_hvac_gshp_without_backup
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-ground-to-air-heat-pump-1-speed.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 6679)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 6679)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 4)
  end

  def test_hvac_ducted_mshp_without_backup
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, hpxml_bldg = _create_hpxml('base-hvac-mini-split-heat-pump-ducted.xml')
    hpxml_bldg.heat_pumps[0].backup_type = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 6034)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 6034)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 2)
  end

  def test_hvac_ducted_mshp_with_integrated_electric_backup
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-mini-split-heat-pump-ducted.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 16034)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 6034)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 4)
  end

  def test_hvac_ducted_mshp_with_integrated_gas_backup_switchover
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-dual-fuel-mini-split-heat-pump-ducted.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 6034)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 6034)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 3)
  end

  def test_hvac_ductless_mshp_without_backup
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-mini-split-heat-pump-ductless.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 5915)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 5915)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 2)
  end

  def test_hvac_ductless_mshp_with_separate_electric_backup
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-mini-split-heat-pump-ductless-backup-baseboard.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 20736)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 3151)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 6)
  end

  def test_hvac_ductless_mshp_with_separate_gas_backup
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-mini-split-heat-pump-ductless-backup-furnace.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 3751)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 3151)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 3)
  end

  def test_water_heater_electric_storage
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeWaterHeater, 5500)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeWaterHeater], 2)
  end

  def test_water_heater_electric_tankless
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-dhw-tankless-electric.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeWaterHeater, 24000)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeWaterHeater], 4)
  end

  def test_water_heater_hpwh_with_backup
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-dhw-tank-heat-pump.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeWaterHeater, 4500)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeWaterHeater], 2)
  end

  def test_water_heater_hpwh_without_backup
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-dhw-tank-heat-pump-capacities.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeWaterHeater, 804)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeWaterHeater], 2)
  end

  def test_clothes_dryer_conventional
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeClothesDryer, 5760)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeClothesDryer], 2)
  end

  def test_clothes_dryer_120v_conventional
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    branch_circuits = hpxml_bldg.electric_panels[0].branch_circuits
    service_feeders = hpxml_bldg.electric_panels[0].service_feeders
    branch_circuits.add(id: "BranchCircuit#{branch_circuits.size + 1}",
                        voltage: HPXML::ElectricPanelVoltage120,
                        component_idrefs: [hpxml_bldg.clothes_dryers[0].id])
    service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                        type: HPXML::ElectricPanelLoadTypeClothesDryer,
                        component_idrefs: [hpxml_bldg.clothes_dryers[0].id])

    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeClothesDryer, 5760)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeClothesDryer], 4)
  end

  def test_clothes_dryer_condensing
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-appliances-modified.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeClothesDryer, 5760)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeClothesDryer], 2)
  end

  def test_clothes_dryer_120v_condensing
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, hpxml_bldg = _create_hpxml('base-appliances-modified.xml')
    branch_circuits = hpxml_bldg.electric_panels[0].branch_circuits
    service_feeders = hpxml_bldg.electric_panels[0].service_feeders
    branch_circuits.add(id: "BranchCircuit#{branch_circuits.size + 1}",
                        voltage: HPXML::ElectricPanelVoltage120,
                        component_idrefs: [hpxml_bldg.clothes_dryers[0].id])
    service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                        type: HPXML::ElectricPanelLoadTypeClothesDryer,
                        component_idrefs: [hpxml_bldg.clothes_dryers[0].id])

    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeClothesDryer, 5760)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeClothesDryer], 1)
  end

  def test_clothes_dryer_heat_pump
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, hpxml_bldg = _create_hpxml('base-appliances-modified.xml')
    hpxml_bldg.clothes_dryers[0].drying_method = HPXML::DryingMethodHeatPump
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeClothesDryer, 860)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeClothesDryer], 2)
  end

  def test_clothes_dryer_120v_heat_pump
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, hpxml_bldg = _create_hpxml('base-appliances-modified.xml')
    hpxml_bldg.clothes_dryers[0].drying_method = HPXML::DryingMethodHeatPump
    branch_circuits = hpxml_bldg.electric_panels[0].branch_circuits
    service_feeders = hpxml_bldg.electric_panels[0].service_feeders
    branch_circuits.add(id: "BranchCircuit#{branch_circuits.size + 1}",
                        voltage: HPXML::ElectricPanelVoltage120,
                        component_idrefs: [hpxml_bldg.clothes_dryers[0].id])
    service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                        type: HPXML::ElectricPanelLoadTypeClothesDryer,
                        component_idrefs: [hpxml_bldg.clothes_dryers[0].id])

    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeClothesDryer, 996)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeClothesDryer], 1)
  end

  def test_cooking_range_resistance
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeRangeOven, 12000)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeRangeOven], 2)
  end

  def test_cooking_range_120v_resistance
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    branch_circuits = hpxml_bldg.electric_panels[0].branch_circuits
    service_feeders = hpxml_bldg.electric_panels[0].service_feeders
    branch_circuits.add(id: "BranchCircuit#{branch_circuits.size + 1}",
                        voltage: HPXML::ElectricPanelVoltage120,
                        component_idrefs: [hpxml_bldg.cooking_ranges[0].id])
    service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                        type: HPXML::ElectricPanelLoadTypeRangeOven,
                        component_idrefs: [hpxml_bldg.cooking_ranges[0].id])

    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeRangeOven, 1800)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeRangeOven], 1)
  end

  def test_cooking_range_induction
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.cooking_ranges[0].is_induction = true
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeRangeOven, 10000)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeRangeOven], 2)
  end

  def test_cooking_range_120v_induction
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.cooking_ranges[0].is_induction = true
    branch_circuits = hpxml_bldg.electric_panels[0].branch_circuits
    service_feeders = hpxml_bldg.electric_panels[0].service_feeders
    branch_circuits.add(id: "BranchCircuit#{branch_circuits.size + 1}",
                        voltage: HPXML::ElectricPanelVoltage120,
                        component_idrefs: [hpxml_bldg.cooking_ranges[0].id])
    service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                        type: HPXML::ElectricPanelLoadTypeRangeOven,
                        component_idrefs: [hpxml_bldg.cooking_ranges[0].id])

    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeRangeOven, 10000)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeRangeOven], 6)
  end

  def test_ventilation_fans_kitchen_and_bath
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-mechvent-bath-kitchen-fans.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeMechVent, 60)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeMechVent], 2)
  end

  def test_ventilation_fans_mech_vent_exhaust
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    hpxml, _hpxml_bldg = _create_hpxml('base-mechvent-exhaust.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeMechVent, 30)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeMechVent], 1)
  end

  def test_sample_files
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    epw_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'weather', 'USA_CO_Denver.Intl.AP.725650_TMY3.epw'))
    weather = WeatherFile.new(epw_path: epw_path, runner: nil)

    Dir["#{@sample_files_path}/*.xml"].each do |hpxml|
      hpxml_name = File.basename(hpxml)
      hpxml, hpxml_bldg = _create_hpxml(hpxml_name, hpxml_name)
      hpxml.header.service_feeders_load_calculation_types = [HPXML::ElectricPanelLoadCalculationType2023ExistingDwellingLoadBased,
                                                             HPXML::ElectricPanelLoadCalculationType2023ExistingDwellingMeterBased]

      Defaults.apply(runner, hpxml, hpxml_bldg, weather)
      electric_panel = hpxml_bldg.electric_panels[0]

      assert_operator(electric_panel.capacity_total_watts[0], :>, 0.0)
      assert_operator(electric_panel.capacity_total_amps[0], :>, 0.0)
      assert(electric_panel.capacity_headroom_amps[0] != 0.0)
      assert_operator(electric_panel.capacity_total_watts[1], :>, 0.0)
      assert_operator(electric_panel.capacity_total_amps[1], :>, 0.0)
      assert(electric_panel.capacity_headroom_amps[1] != 0.0)
    end
  end

  def test_electric_panel_output_file
    args_hash = { 'output_format' => 'json',
                  'hpxml_path' => File.absolute_path(File.join(@sample_files_path, 'base-detailed-electric-panel.xml')) }
    _model, hpxml, _hpxml_bldg = _test_measure(args_hash)
    electric_panel_path = File.absolute_path(File.join(File.dirname(__FILE__), 'results_panel.json'))
    json = JSON.parse(File.read(electric_panel_path))

    assert_equal(16, json['Electric Panel Breaker Spaces']['Total Count'])
    assert_equal(11, json['Electric Panel Breaker Spaces']['Occupied Count'])
    assert_equal(16 - 11, json['Electric Panel Breaker Spaces']['Headroom Count'])
    assert_equal(9674.6, json['Electric Panel Load']['2023 Existing Dwelling Load-Based: Total Load (W)'])
    assert_equal(40.3, json['Electric Panel Load']['2023 Existing Dwelling Load-Based: Total Capacity (A)'])
    assert_in_epsilon(100.0 - 40.2, json['Electric Panel Load']['2023 Existing Dwelling Load-Based: Headroom Capacity (A)'], 0.01)
    assert_equal(5625.0, json['Electric Panel Load']['2023 Existing Dwelling Meter-Based: Total Load (W)'])
    assert_equal(23.4, json['Electric Panel Load']['2023 Existing Dwelling Meter-Based: Total Capacity (A)'])
    assert_in_epsilon(100.0 - 23.4, json['Electric Panel Load']['2023 Existing Dwelling Meter-Based: Headroom Capacity (A)'], 0.01)

    # Upgrade
    hpxml_bldg = hpxml.buildings[0]
    electric_panel = hpxml_bldg.electric_panels[0]
    electric_panel.rated_total_spaces = 16
    branch_circuits = electric_panel.branch_circuits
    service_feeders = electric_panel.service_feeders
    sf = service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeHeating }
    sf.power = 16942
    sf.is_new_load = true
    branch_circuits.add(id: "BranchCircuit#{branch_circuits.size + 1}",
                        voltage: HPXML::ElectricPanelVoltage240,
                        occupied_spaces: 5,
                        component_idrefs: [hpxml_bldg.heating_systems[0].id])
    sf = service_feeders.find { |sf| sf.type == HPXML::ElectricPanelLoadTypeCooling }
    sf.power = 16942
    sf.is_new_load = true
    branch_circuits.add(id: "BranchCircuit#{branch_circuits.size + 1}",
                        voltage: HPXML::ElectricPanelVoltage240,
                        occupied_spaces: 0,
                        component_idrefs: [hpxml_bldg.cooling_systems[0].id])
    service_feeders.add(type: HPXML::ElectricPanelLoadTypeWaterHeater,
                        power: 4500,
                        is_new_load: true,
                        component_idrefs: [hpxml_bldg.water_heating_systems[0].id])
    branch_circuits.add(id: "BranchCircuit#{branch_circuits.size + 1}",
                        voltage: HPXML::ElectricPanelVoltage240,
                        occupied_spaces: 2,
                        component_idrefs: [hpxml_bldg.water_heating_systems[0].id])
    service_feeders.add(type: HPXML::ElectricPanelLoadTypeClothesDryer,
                        power: 5760,
                        is_new_load: true,
                        component_idrefs: [hpxml_bldg.clothes_dryers[0].id])
    branch_circuits.add(id: "BranchCircuit#{branch_circuits.size + 1}",
                        voltage: HPXML::ElectricPanelVoltage240,
                        occupied_spaces: 2,
                        component_idrefs: [hpxml_bldg.clothes_dryers[0].id])
    service_feeders.add(type: HPXML::ElectricPanelLoadTypeRangeOven,
                        power: 12000,
                        is_new_load: true,
                        component_idrefs: [hpxml_bldg.cooking_ranges[0].id])
    branch_circuits.add(id: "BranchCircuit#{branch_circuits.size + 1}",
                        voltage: HPXML::ElectricPanelVoltage240,
                        occupied_spaces: 2,
                        component_idrefs: [hpxml_bldg.cooking_ranges[0].id])
    hpxml_bldg.plug_loads.add(id: "PlugLoad#{hpxml_bldg.plug_loads.size + 1}",
                              plug_load_type: HPXML::PlugLoadTypeElectricVehicleCharging)
    service_feeders.add(type: HPXML::ElectricPanelLoadTypeElectricVehicleCharging,
                        power: 1650,
                        is_new_load: true,
                        component_idrefs: [hpxml_bldg.plug_loads[-1].id])
    XMLHelper.write_file(hpxml.to_doc(), @tmp_hpxml_path)

    args_hash['hpxml_path'] = @tmp_hpxml_path
    args_hash['skip_validation'] = true
    _model, _hpxml, _hpxml_bldg = _test_measure(args_hash)
    electric_panel_path = File.absolute_path(File.join(File.dirname(__FILE__), 'results_panel.json'))
    json = JSON.parse(File.read(electric_panel_path))

    assert_equal(16, json['Electric Panel Breaker Spaces']['Total Count'])
    assert_equal(23, json['Electric Panel Breaker Spaces']['Occupied Count'])
    assert_equal(-7, json['Electric Panel Breaker Spaces']['Headroom Count'])
    assert_equal(34827.2, json['Electric Panel Load']['2023 Existing Dwelling Load-Based: Total Load (W)'])
    assert_equal(145.1, json['Electric Panel Load']['2023 Existing Dwelling Load-Based: Total Capacity (A)'])
    assert_in_epsilon(100.0 - 145.1, json['Electric Panel Load']['2023 Existing Dwelling Load-Based: Headroom Capacity (A)'], 0.01)
    assert_equal(46477.0, json['Electric Panel Load']['2023 Existing Dwelling Meter-Based: Total Load (W)'])
    assert_equal(193.7, json['Electric Panel Load']['2023 Existing Dwelling Meter-Based: Total Capacity (A)'])
    assert_in_epsilon(100.0 - 193.7, json['Electric Panel Load']['2023 Existing Dwelling Meter-Based: Headroom Capacity (A)'], 0.01)
  end

  private

  def _test_service_feeder_power(hpxml_bldg, type, power)
    service_feeders = hpxml_bldg.electric_panels[0].service_feeders
    sfs = service_feeders.select { |sf| sf.type == type }

    pw = 0
    sfs.each do |sf|
      pw += sf.power
    end
    assert_in_delta(power, pw, 1.0)
  end

  def _test_occupied_spaces(hpxml_bldg, types, occupied_spaces)
    branch_circuits = hpxml_bldg.electric_panels[0].branch_circuits
    service_feeders = hpxml_bldg.electric_panels[0].service_feeders

    components = []
    service_feeders.each do |service_feeder|
      next if !types.include?(service_feeder.type)

      components += service_feeder.components
    end

    os = 0
    branch_circuits.each do |branch_circuit|
      next if (branch_circuit.components & components).empty?

      os += branch_circuit.occupied_spaces
    end
    assert_equal(occupied_spaces, os)
  end

  def _create_hpxml(hpxml_name, test_name = nil)
    puts "Testing #{test_name}..." if !test_name.nil?
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, hpxml_name))
    if hpxml.header.service_feeders_load_calculation_types.empty?
      hpxml.header.service_feeders_load_calculation_types = [HPXML::ElectricPanelLoadCalculationType2023ExistingDwellingLoadBased]
    end
    hpxml_bldg = hpxml.buildings[0]
    if hpxml_bldg.electric_panels.size == 0
      hpxml_bldg.electric_panels.add(id: 'ElectricPanel')
    end
    hpxml_bldg.header.electric_panel_baseline_peak_power = 4500
    return hpxml, hpxml_bldg
  end

  def _test_measure(args_hash)
    # create an instance of the measure
    measure = HPXMLtoOpenStudio.new

    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new

    # get arguments
    args_hash['output_dir'] = File.dirname(__FILE__)
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.has_key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result) unless result.value.valueName == 'Success'

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)

    hpxml = HPXML.new(hpxml_path: File.join(File.dirname(__FILE__), 'in.xml'))

    File.delete(File.join(File.dirname(__FILE__), 'in.xml'))

    return model, hpxml, hpxml.buildings[0]
  end
end
