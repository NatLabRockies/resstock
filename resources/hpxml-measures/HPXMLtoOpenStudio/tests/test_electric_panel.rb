# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'

class HPXMLtoOpenStudioElectricPanelTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    File.delete(File.join(File.dirname(__FILE__), 'results_annual.csv')) if File.exist? File.join(File.dirname(__FILE__), 'results_annual.csv')
    File.delete(File.join(File.dirname(__FILE__), 'results_panel.csv')) if File.exist? File.join(File.dirname(__FILE__), 'results_panel.csv')
    File.delete(File.join(File.dirname(__FILE__), 'results_design_load_details.csv')) if File.exist? File.join(File.dirname(__FILE__), 'results_design_load_details.csv')
  end

  def sample_files_dir
    return File.join(File.dirname(__FILE__), '..', '..', 'workflow', 'sample_files')
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
    assert_in_epsilon(9444.2, electric_panel.capacity_total_watts[0], 0.01)
    assert_in_epsilon(9444.2 / Float(HPXML::ElectricPanelVoltage240), electric_panel.capacity_total_amps[0], 0.01)
    assert_in_epsilon(electric_panel.max_current_rating - 9444.2 / Float(HPXML::ElectricPanelVoltage240), electric_panel.capacity_headroom_amps[0], 0.01)
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

    assert_equal(4 + 3, electric_panel.breaker_spaces_total)
    assert_equal(4, electric_panel.breaker_spaces_occupied)
    assert_equal(3, electric_panel.breaker_spaces_headroom)
    assert_in_epsilon(5000.0, electric_panel.capacity_total_watts[0], 0.001)
    assert_in_epsilon(5000.0 / Float(HPXML::ElectricPanelVoltage240), electric_panel.capacity_total_amps[0], 0.01)
    assert_in_epsilon(electric_panel.max_current_rating - 5000.0 / Float(HPXML::ElectricPanelVoltage240), electric_panel.capacity_headroom_amps[0], 0.01)
    assert_in_epsilon(1.25 * 4500.0, electric_panel.capacity_total_watts[1], 0.001)
    assert_in_epsilon(1.25 * 4500.0 / Float(HPXML::ElectricPanelVoltage240), electric_panel.capacity_total_amps[1], 0.01)
    assert_in_epsilon(electric_panel.max_current_rating - (1.25 * 4500.0) / Float(HPXML::ElectricPanelVoltage240), electric_panel.capacity_headroom_amps[1], 0.01)
  end

  def test_hvac_configurations
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    test_name = '120v room air conditioner only'
    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-room-ac-only.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 0)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 2011)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 0)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 0)

    test_name = '240v room air conditioner only'
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-room-ac-only.xml', test_name)
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

    test_name = 'Gas furnace only'
    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-furnace-gas-only.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 295)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 0)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 1)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 0)

    test_name = 'Electric furnace only'
    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-furnace-elec-only.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 295 + 10766)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 0)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 2)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 0)

    test_name = 'Large electric furnace only'
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-furnace-elec-only.xml', test_name)
    hpxml_bldg.heating_systems[0].heating_capacity = 48000
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 393 + 14355)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 0)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 4)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 0)

    test_name = 'Gas furnace + central air conditioner'
    hpxml, _hpxml_bldg = _create_hpxml('base.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 295)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 300 + 4022)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 1)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 2)

    test_name = 'Electric furnace + central air conditioner'
    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-furnace-elec-central-ac-1-speed.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 295 + 10551)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 300 + 4022)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 2)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 2)

    test_name = 'Large electric furnace + central air conditioner'
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-furnace-elec-central-ac-1-speed.xml', test_name)
    hpxml_bldg.heating_systems[0].heating_capacity = 48000
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 393 + 14067)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 300 + 4022)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 4)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 2)

    test_name = 'Central air conditioner only'
    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-central-ac-only-1-speed.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 0)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 400 + 4022)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 0)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 3)

    test_name = 'Large central air conditioner only'
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-central-ac-only-1-speed.xml', test_name)
    hpxml_bldg.cooling_systems[0].cooling_capacity = 48000
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 0)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 800 + 7657)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 0)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 3)

    test_name = 'Gas boiler only'
    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-boiler-gas-only.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 96.2)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 0)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 1)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 0)

    test_name = 'Electric boiler only'
    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-boiler-elec-only.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 82 + 10766)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 0)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 2)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 0)

    test_name = 'Large electric boiler only'
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-boiler-elec-only.xml', test_name)
    hpxml_bldg.heating_systems[0].heating_capacity = 48000
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 82 + 14355)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 0)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 4)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 0)

    test_name = 'Gas boiler + central air conditioner'
    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-boiler-gas-central-ac-1-speed.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 96.2)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 400 + 4022)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 1)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 3)

    test_name = 'Electric boiler + central air conditioner'
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-boiler-gas-central-ac-1-speed.xml', test_name)
    hpxml_bldg.heating_systems[0].heating_system_fuel = HPXML::FuelTypeElectricity
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 96.2 + 11468)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 400 + 4022)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 2)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 3)

    test_name = 'Large electric boiler + central air conditioner'
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-boiler-gas-central-ac-1-speed.xml', test_name)
    hpxml_bldg.heating_systems[0].heating_capacity = 48000
    hpxml_bldg.heating_systems[0].heating_system_fuel = HPXML::FuelTypeElectricity
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 96.2 + 15291)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 400 + 4022)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating], 4)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeCooling], 3)

    test_name = 'ASHP w/out backup'
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml', test_name)
    hpxml_bldg.heat_pumps[0].backup_type = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 561 + 5839)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 600 + 5839)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 4)

    test_name = 'ASHP w/integrated electric backup'
    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 561 + 5839 + 10551)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 600 + 5839)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 4)

    # Switchover temperature should only be used for a heat pump with fossil fuel backup; use compressor lockout temperature instead.
    # test_name = 'ASHP w/integrated electric backup switchover'
    # test_name = 'ASHP w/separate electric backup switchover'

    test_name = 'ASHP w/integrated gas backup switchover'
    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 561 + 5839)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 600 + 5839)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 3)

    test_name = 'ASHP w/separate gas backup'
    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-backup-boiler.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 210 + 3114 + 96)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 225 + 3114)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 5)

    test_name = 'ASHP w/separate gas backup switchover'
    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-backup-boiler-switchover-temperature.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 210 + 3114 + 96)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 225 + 3114)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 5)

    test_name = 'ASHP heating only w/integrated electric backup'
    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed-heating-only.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 561 + 5839 + 10551)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 0)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 4)

    test_name = 'ASHP cooling only w/out backup'
    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed-cooling-only.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 0)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 600 + 5839)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 4)

    test_name = 'Ducted MSHP w/out backup'
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-mini-split-heat-pump-ducted.xml', test_name)
    hpxml_bldg.heat_pumps[0].backup_type = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 202 + 5839)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 216 + 5839)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 2)

    test_name = 'Ducted MSHP w/integrated electric backup'
    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-mini-split-heat-pump-ducted.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 202 + 5839 + 10551)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 216 + 5839)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 4)

    test_name = 'Ducted MSHP w/integrated gas backup switchover'
    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-dual-fuel-mini-split-heat-pump-ducted.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 202 + 5839)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 216 + 5839)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 3)

    test_name = 'Ductless MSHP w/out backup'
    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-mini-split-heat-pump-ductless.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 84 + 5839)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 84 + 5839)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 2)

    test_name = 'Ductless MSHP w/separate electric backup'
    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-mini-split-heat-pump-ductless-backup-baseboard.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 42 + 3114 + 17584)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 42 + 3114)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 6)

    test_name = 'Ductless MSHP w/separate gas backup'
    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-mini-split-heat-pump-ductless-backup-furnace.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeHeating, 42 + 3114 + 655)
    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeCooling, 42 + 3114)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling], 3)
  end

  def test_water_heater_configurations
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    test_name = 'Electric storage'
    hpxml, _hpxml_bldg = _create_hpxml('base.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeWaterHeater, 5500)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeWaterHeater], 2)

    test_name = 'Electric tankless'
    hpxml, _hpxml_bldg = _create_hpxml('base-dhw-tankless-electric.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeWaterHeater, 24000)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeWaterHeater], 4)

    test_name = 'HPWH w/backup'
    hpxml, _hpxml_bldg = _create_hpxml('base-dhw-tank-heat-pump.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeWaterHeater, 4500)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeWaterHeater], 2)

    test_name = 'HPWH w/out backup'
    hpxml, _hpxml_bldg = _create_hpxml('base-dhw-tank-heat-pump-capacities.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeWaterHeater, 1064)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeWaterHeater], 2)
  end

  def test_clothes_dryer_configurations
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    test_name = 'Vented clothes dryer'
    hpxml, _hpxml_bldg = _create_hpxml('base.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeClothesDryer, 5760)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeClothesDryer], 2)

    test_name = '120v vented clothes dryer'
    hpxml, hpxml_bldg = _create_hpxml('base.xml', test_name)
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
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeClothesDryer], 3)

    test_name = 'HP clothes dryer'
    hpxml, _hpxml_bldg = _create_hpxml('base-appliances-modified.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeClothesDryer, 860)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeClothesDryer], 2)

    test_name = '120v HP clothes dryer'
    hpxml, hpxml_bldg = _create_hpxml('base-appliances-modified.xml', test_name)
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

  def test_cooking_range_configurations
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    test_name = 'Resistance cooking range'
    hpxml, _hpxml_bldg = _create_hpxml('base.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeRangeOven, 12000)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeRangeOven], 2)

    test_name = '120v resistance cooking range'
    hpxml, hpxml_bldg = _create_hpxml('base.xml', test_name)
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

    test_name = 'Induction cooking range'
    hpxml, hpxml_bldg = _create_hpxml('base.xml', test_name)
    hpxml_bldg.cooking_ranges[0].is_induction = true
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeRangeOven, 10000)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeRangeOven], 2)

    test_name = '120v induction cooking range'
    hpxml, hpxml_bldg = _create_hpxml('base.xml', test_name)
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
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeRangeOven], 5)
  end

  def test_ventilation_fans_configurations
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }

    test_name = 'Kitchen and bath fans'
    hpxml, _hpxml_bldg = _create_hpxml('base-mechvent-bath-kitchen-fans.xml', test_name)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    _test_service_feeder_power(hpxml_bldg, HPXML::ElectricPanelLoadTypeMechVent, 60)
    _test_occupied_spaces(hpxml_bldg, [HPXML::ElectricPanelLoadTypeMechVent], 2)

    test_name = 'Exhaust fan'
    hpxml, _hpxml_bldg = _create_hpxml('base-mechvent-exhaust.xml', test_name)
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

  private

  def _test_service_feeder_power(hpxml_bldg, type, power)
    service_feeders = hpxml_bldg.electric_panels[0].service_feeders
    sfs = service_feeders.select { |sf| sf.type == type }

    pw = 0
    sfs.each do |sf|
      pw += sf.power
    end
    assert_in_epsilon(power, pw, 0.001)
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
    hpxml_bldg.header.extension_properties['PeakElectricity'] = 4500
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
