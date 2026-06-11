# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'
require_relative 'util.rb'

class HPXMLtoOpenStudioLightingTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(File.dirname(__FILE__), 'tmp.xml')
    @schema_validator = XMLValidator.get_xml_validator(File.join(File.dirname(__FILE__), '..', 'resources', 'hpxml_schema', 'HPXML.xsd'))
    @schematron_validator = XMLValidator.get_xml_validator(File.join(File.dirname(__FILE__), '..', 'resources', 'hpxml_schematron', 'EPvalidator.sch'))
  end

  def teardown
    cleanup_output_files([@tmp_hpxml_path])
  end

  def get_kwh_per_year(model, name)
    model.getLightss.each do |ltg|
      next unless ltg.name.to_s == name

      hrs = Schedule.annual_equivalent_full_load_hrs(model.yearDescription.get.assumedYear, ltg.schedule.get)
      kwh_yr = UnitConversions.convert(hrs * ltg.lightingLevel.get * ltg.multiplier * ltg.space.get.multiplier, 'Wh', 'kWh')
      return kwh_yr
    end
    model.getExteriorLightss.each do |ltg|
      next unless ltg.name.to_s == name

      hrs = Schedule.annual_equivalent_full_load_hrs(model.yearDescription.get.assumedYear, ltg.schedule.get)
      kwh_yr = UnitConversions.convert(hrs * ltg.exteriorLightsDefinition.designLevel * ltg.multiplier, 'Wh', 'kWh')
      return kwh_yr
    end
    model.getElectricEquipments.each do |ee|
      next unless ee.name.to_s.include?(name)

      hrs = Schedule.annual_equivalent_full_load_hrs(model.yearDescription.get.assumedYear, ee.schedule.get)
      kwh_yr = UnitConversions.convert(hrs * ee.designLevel.get * ee.multiplier * ee.space.get.multiplier, 'Wh', 'kWh')
      return kwh_yr
    end
    return 0.0
  end

  def test_lighting
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check interior lighting
    assert_in_delta(1322, get_kwh_per_year(model, Constants::ObjectTypeLightingInterior).round, 1.0)

    # Check exterior lighting
    assert_in_delta(98, get_kwh_per_year(model, Constants::ObjectTypeLightingExterior), 1.0)
  end

  def test_lighting_garage
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-enclosure-2stories-garage.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check interior lighting
    assert_in_delta(1544, get_kwh_per_year(model, Constants::ObjectTypeLightingInterior), 1.0)

    # Check garage lighting
    assert_in_delta(42, get_kwh_per_year(model, Constants::ObjectTypeLightingGarage), 1.0)

    # Check exterior lighting
    assert_in_delta(109, get_kwh_per_year(model, Constants::ObjectTypeLightingExterior), 1.0)
  end

  def test_exterior_holiday_lighting
    ['base.xml',
     'base-misc-defaults.xml',
     'base-lighting-holiday.xml'].each do |hpxml_name|
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, hpxml_name))
      model, _hpxml, hpxml_bldg = _test_measure(args_hash)

      if hpxml_name == 'base-lighting-holiday.xml'
        # Check exterior holiday lighting
        assert_in_delta(58.3, get_kwh_per_year(model, Constants::ObjectTypeLightingExteriorHoliday), 1.0)
      else
        assert_equal(false, hpxml_bldg.lighting.holiday_exists)
      end
    end
  end

  def test_lighting_kwh_per_year
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-lighting-kwh-per-year.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Check interior lighting
    int_kwh_yr = hpxml_bldg.lighting_groups.find { |lg| lg.location == HPXML::LocationInterior }.kwh_per_year
    int_kwh_yr *= hpxml_bldg.lighting.interior_usage_multiplier unless hpxml_bldg.lighting.interior_usage_multiplier.nil?
    assert_in_delta(int_kwh_yr, get_kwh_per_year(model, Constants::ObjectTypeLightingInterior).round, 1.0)

    # Check exterior lighting
    ext_kwh_yr = hpxml_bldg.lighting_groups.find { |lg| lg.location == HPXML::LocationExterior }.kwh_per_year
    ext_kwh_yr *= hpxml_bldg.lighting.exterior_usage_multiplier unless hpxml_bldg.lighting.exterior_usage_multiplier.nil?
    assert_in_delta(ext_kwh_yr, get_kwh_per_year(model, Constants::ObjectTypeLightingExterior), 1.0)
  end

  def test_lighting_none
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-lighting-none.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check interior lighting
    assert_equal(0.0, get_kwh_per_year(model, Constants::ObjectTypeLightingInterior))

    # Check garage lighting
    assert_equal(0.0, get_kwh_per_year(model, Constants::ObjectTypeLightingGarage))

    # Check exterior lighting
    assert_equal(0.0, get_kwh_per_year(model, Constants::ObjectTypeLightingExterior))
  end

  def test_ceiling_fan
    # Efficiency
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-lighting-ceiling-fans.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    assert_in_delta(154, get_kwh_per_year(model, Constants::ObjectTypeCeilingFan), 1.0)

    # Label energy use
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-lighting-ceiling-fans-label-energy-use.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    assert_in_delta(200, get_kwh_per_year(model, Constants::ObjectTypeCeilingFan), 1.0)
  end

  def test_operational_0_occupants
    args_hash = {}
    args_hash['hpxml_path'] = @tmp_hpxml_path
    hpxml, hpxml_bldg = _create_hpxml('base-residents-0.xml')
    hpxml_bldg.ceiling_fans.add(id: "CeilingFan#{hpxml_bldg.ceiling_fans.size + 1}")
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check interior lighting
    assert_equal(0.0, get_kwh_per_year(model, Constants::ObjectTypeLightingInterior))

    # Check garage lighting
    assert_equal(0.0, get_kwh_per_year(model, Constants::ObjectTypeLightingGarage))

    # Check exterior lighting
    assert_equal(0.0, get_kwh_per_year(model, Constants::ObjectTypeLightingExterior))

    # Check ceiling fan
    assert_equal(0.0, get_kwh_per_year(model, Constants::ObjectTypeCeilingFan))
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
    result.showOutput() unless result.value.valueName == 'Success'

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)

    hpxml_defaults_path = File.join(File.dirname(__FILE__), 'in.xml')
    if args_hash['hpxml_path'] == @tmp_hpxml_path
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

    return model, hpxml, hpxml.buildings[0]
  end

  def _create_hpxml(hpxml_name)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, hpxml_name))
    return hpxml, hpxml.buildings[0]
  end
end
