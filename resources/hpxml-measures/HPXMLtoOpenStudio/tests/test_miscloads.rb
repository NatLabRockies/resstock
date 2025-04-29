# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'

class HPXMLtoOpenStudioMiscLoadsTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    File.delete(File.join(File.dirname(__FILE__), 'in.schedules.csv')) if File.exist? File.join(File.dirname(__FILE__), 'in.schedules.csv')
    File.delete(File.join(File.dirname(__FILE__), 'results_annual.csv')) if File.exist? File.join(File.dirname(__FILE__), 'results_annual.csv')
    File.delete(File.join(File.dirname(__FILE__), 'results_design_load_details.csv')) if File.exist? File.join(File.dirname(__FILE__), 'results_design_load_details.csv')
  end

  def get_kwh_therm_per_year(model, name)
    kwh_yr = 0.0
    therm_yr = 0.0
    model.getElectricEquipments.each do |ee|
      next unless ee.name.to_s.include?(name)

      hrs = Schedule.annual_equivalent_full_load_hrs(model.yearDescription.get.assumedYear, ee.schedule.get)
      kwh_yr += UnitConversions.convert(hrs * ee.designLevel.get * ee.multiplier * ee.space.get.multiplier, 'Wh', 'kWh')
    end
    model.getGasEquipments.each do |ge|
      next unless ge.name.to_s.include?(name)

      hrs = Schedule.annual_equivalent_full_load_hrs(model.yearDescription.get.assumedYear, ge.schedule.get)
      therm_yr += UnitConversions.convert(hrs * ge.definition.to_GasEquipmentDefinition.get.designLevel.get * ge.multiplier * ge.space.get.multiplier, 'Wh', 'therm')
    end
    model.getOtherEquipments.each do |oe|
      next unless oe.name.to_s.include?(name)

      hrs = Schedule.annual_equivalent_full_load_hrs(model.yearDescription.get.assumedYear, oe.schedule.get)
      therm_yr += UnitConversions.convert(hrs * oe.definition.to_OtherEquipmentDefinition.get.designLevel.get * oe.multiplier * oe.space.get.multiplier, 'Wh', 'therm')
    end
    return kwh_yr, therm_yr
  end

  def test_misc_loads
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check misc plug loads
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPlugLoads)
    assert_in_delta(2457, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check television
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscTelevision)
    assert_in_delta(620, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check others
    objects = [Constants::ObjectTypeMiscElectricVehicleCharging,
               Constants::ObjectTypeMiscWellPump,
               Constants::ObjectTypeMiscPoolPump,
               Constants::ObjectTypeMiscPoolHeater,
               Constants::ObjectTypeMiscPermanentSpaPump,
               Constants::ObjectTypeMiscPermanentSpaHeater,
               Constants::ObjectTypeMiscGrill,
               Constants::ObjectTypeMiscLighting,
               Constants::ObjectTypeMiscFireplace]
    objects.each do |object_name|
      kwh_yr, therm_yr = get_kwh_therm_per_year(model, object_name)
      assert_equal(0, kwh_yr)
      assert_equal(0, therm_yr)
    end
  end

  def test_large_uncommon_loads
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-misc-loads-large-uncommon.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check misc plug loads
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPlugLoads)
    assert_in_delta(2457, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check television
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscTelevision)
    assert_in_delta(620, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check vehicle
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscElectricVehicleCharging)
    assert_in_delta(1500, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check well pump
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscWellPump)
    assert_in_delta(475, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check pool pump
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPoolPump)
    assert_in_delta(2698, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check pool heater
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPoolHeater)
    assert_equal(0, kwh_yr)
    assert_in_delta(500, therm_yr, 1.0)

    # Check permanent spa pump
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPermanentSpaPump)
    assert_in_delta(1000, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check permanent spa heater
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPermanentSpaHeater)
    assert_in_delta(1300, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check grill
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscGrill)
    assert_equal(0, kwh_yr)
    assert_in_delta(25, therm_yr, 1.0)

    # Check lighting
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscLighting)
    assert_equal(0, kwh_yr)
    assert_in_delta(28, therm_yr, 1.0)

    # Check fireplace
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscFireplace)
    assert_equal(0, kwh_yr)
    assert_in_delta(55, therm_yr, 1.0)
  end

  def test_large_uncommon_loads2
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-misc-loads-large-uncommon2.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check misc plug loads
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPlugLoads)
    assert_in_delta(2457, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check television
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscTelevision)
    assert_in_delta(620, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check vehicle
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscElectricVehicleCharging)
    assert_in_delta(1500, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check well pump
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscWellPump)
    assert_in_delta(475, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check pool pump
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPoolPump)
    assert_in_delta(2698, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check pool heater
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPoolHeater)
    assert_equal(0, kwh_yr)
    assert_equal(0, therm_yr)

    # Check permanent spa pump
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPermanentSpaPump)
    assert_in_delta(1000, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check permanent spa heater
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPermanentSpaHeater)
    assert_in_delta(260, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check grill
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscGrill)
    assert_equal(0, kwh_yr)
    assert_in_delta(25, therm_yr, 1.0)

    # Check lighting
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscLighting)
    assert_equal(0, kwh_yr)
    assert_in_delta(28, therm_yr, 1.0)

    # Check fireplace
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscFireplace)
    assert_equal(0, kwh_yr)
    assert_in_delta(55, therm_yr, 1.0)
  end

  def test_operational_0_occupants
    args_hash = {}
    args_hash['hpxml_path'] = @tmp_hpxml_path
    hpxml, hpxml_bldg = _create_hpxml('base-residents-0.xml')
    [HPXML::PlugLoadTypeElectricVehicleCharging,
     HPXML::PlugLoadTypeWellPump].each do |plug_load_type|
      hpxml_bldg.plug_loads.add(id: "PlugLoad#{hpxml_bldg.plug_loads.size + 1}",
                                plug_load_type: plug_load_type)
    end
    [HPXML::FuelLoadTypeFireplace,
     HPXML::FuelLoadTypeGrill,
     HPXML::FuelLoadTypeLighting].each do |fuel_load_type|
      hpxml_bldg.fuel_loads.add(id: "FuelLoad#{hpxml_bldg.fuel_loads.size + 1}",
                                fuel_type: HPXML::FuelTypeNaturalGas,
                                fuel_load_type: fuel_load_type,
                                therm_per_year: 100)
    end
    hpxml_bldg.pools.add(id: "Pool#{hpxml_bldg.pools.size + 1}",
                         type: HPXML::TypeUnknown,
                         pump_type: HPXML::TypeUnknown,
                         heater_type: HPXML::HeaterTypeGas,
                         heater_load_units: HPXML::UnitsThermPerYear)
    hpxml_bldg.permanent_spas.add(id: "PermanentSpa#{hpxml_bldg.permanent_spas.size + 1}",
                                  type: HPXML::TypeUnknown,
                                  pump_type: HPXML::TypeUnknown,
                                  pump_kwh_per_year: 100,
                                  heater_type: HPXML::HeaterTypeElectricResistance,
                                  heater_load_units: HPXML::UnitsKwhPerYear,
                                  heater_load_value: 100)

    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check misc plug loads
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPlugLoads)
    assert_equal(0, kwh_yr)
    assert_equal(0, therm_yr)

    # Check television
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscTelevision)
    assert_equal(0, kwh_yr)
    assert_equal(0, therm_yr)

    # Check vehicle
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscElectricVehicleCharging)
    assert_equal(0, kwh_yr)
    assert_equal(0, therm_yr)

    # Check well pump
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscWellPump)
    assert_equal(0, kwh_yr)
    assert_equal(0, therm_yr)

    # Check pool pump
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPoolPump)
    refute_equal(0, kwh_yr)
    assert_equal(0, therm_yr)

    # Check pool heater
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPoolHeater)
    assert_equal(0, kwh_yr)
    refute_equal(0, therm_yr)

    # Check permanent spa pump
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPermanentSpaPump)
    refute_equal(0, kwh_yr)
    assert_equal(0, therm_yr)

    # Check permanent spa heater
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPermanentSpaHeater)
    refute_equal(0, kwh_yr)
    assert_equal(0, therm_yr)

    # Check grill
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscGrill)
    assert_equal(0, kwh_yr)
    assert_equal(0, therm_yr)

    # Check lighting
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscLighting)
    assert_equal(0, kwh_yr)
    assert_equal(0, therm_yr)

    # Check fireplace
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscFireplace)
    assert_equal(0, kwh_yr)
    assert_equal(0, therm_yr)
  end

  def test_operational_5point5_occupants
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-residents-5-5.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check misc plug loads
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPlugLoads)
    assert_in_delta(3008, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check television
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscTelevision)
    assert_in_delta(1003, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check vehicle
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscElectricVehicleCharging)
    assert_equal(0, kwh_yr)
    assert_equal(0, therm_yr)

    # Check well pump
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscWellPump)
    assert_equal(0, kwh_yr)
    assert_equal(0, therm_yr)

    # Check pool pump
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPoolPump)
    assert_equal(0, kwh_yr)
    assert_equal(0, therm_yr)

    # Check pool heater
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPoolHeater)
    assert_equal(0, kwh_yr)
    assert_equal(0, therm_yr)

    # Check permanent spa pump
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPermanentSpaPump)
    assert_equal(0, kwh_yr)
    assert_equal(0, therm_yr)

    # Check permanent spa heater
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPermanentSpaHeater)
    assert_equal(0, kwh_yr)
    assert_equal(0, therm_yr)

    # Check grill
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscGrill)
    assert_equal(0, kwh_yr)
    assert_equal(0, therm_yr)

    # Check lighting
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscLighting)
    assert_equal(0, kwh_yr)
    assert_equal(0, therm_yr)

    # Check fireplace
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscFireplace)
    assert_equal(0, kwh_yr)
    assert_equal(0, therm_yr)
  end

  def test_operational_large_uncommon_loads
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-residents-1-misc-loads-large-uncommon.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check misc plug loads
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPlugLoads)
    assert_in_delta(1920, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check television
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscTelevision)
    assert_in_delta(588, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check vehicle
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscElectricVehicleCharging)
    assert_in_delta(2368, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check well pump
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscWellPump)
    assert_in_delta(337, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check pool pump
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPoolPump)
    assert_in_delta(1907, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check pool heater
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPoolHeater)
    assert_equal(0, kwh_yr)
    assert_in_delta(181, therm_yr, 1.0)

    # Check permanent spa pump
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPermanentSpaPump)
    assert_in_delta(850, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check permanent spa heater
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPermanentSpaHeater)
    assert_in_delta(861, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check grill
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscGrill)
    assert_equal(0, kwh_yr)
    assert_in_delta(25, therm_yr, 1.0)

    # Check lighting
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscLighting)
    assert_equal(0, kwh_yr)
    assert_in_delta(15, therm_yr, 1.0)

    # Check fireplace
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscFireplace)
    assert_equal(0, kwh_yr)
    assert_in_delta(51, therm_yr, 1.0)
  end

  def test_operational_large_uncommon_loads2
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-residents-1-misc-loads-large-uncommon2.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check misc plug loads
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPlugLoads)
    assert_in_delta(1920, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check television
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscTelevision)
    assert_in_delta(588, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check vehicle
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscElectricVehicleCharging)
    assert_in_delta(2368, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check well pump
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscWellPump)
    assert_in_delta(337, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check pool pump
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPoolPump)
    assert_in_delta(1907, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check pool heater
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPoolHeater)
    assert_equal(0, kwh_yr)
    assert_equal(0, therm_yr)

    # Check permanent spa pump
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPermanentSpaPump)
    assert_in_delta(850, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check permanent spa heater
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscPermanentSpaHeater)
    assert_in_delta(172, kwh_yr, 1.0)
    assert_equal(0, therm_yr)

    # Check grill
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscGrill)
    assert_equal(0, kwh_yr)
    assert_in_delta(25, therm_yr, 1.0)

    # Check lighting
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscLighting)
    assert_equal(0, kwh_yr)
    assert_in_delta(15, therm_yr, 1.0)

    # Check fireplace
    kwh_yr, therm_yr = get_kwh_therm_per_year(model, Constants::ObjectTypeMiscFireplace)
    assert_equal(0, kwh_yr)
    assert_in_delta(51, therm_yr, 1.0)
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

    hpxml = HPXML.new(hpxml_path: args_hash['hpxml_path'])

    File.delete(File.join(File.dirname(__FILE__), 'in.xml'))

    return model, hpxml, hpxml.buildings[0]
  end

  def _create_hpxml(hpxml_name)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, hpxml_name))
    return hpxml, hpxml.buildings[0]
  end
end
