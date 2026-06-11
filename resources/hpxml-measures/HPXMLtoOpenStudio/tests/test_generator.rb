# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'
require_relative 'util.rb'

class HPXMLtoOpenStudioGeneratorTest < Minitest::Test
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

  def get_generator(model, name)
    model.getGeneratorMicroTurbines.each do |g|
      next unless g.name.to_s.start_with? "#{name} "

      return g
    end
  end

  def test_generator
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-misc-generators.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    hpxml_bldg.generators.each do |hpxml_generator|
      generator = get_generator(model, hpxml_generator.id)

      # Check object
      assert_equal(EPlus.fuel_type(hpxml_generator.fuel_type), generator.fuelType)
      assert_in_epsilon(137.0, generator.referenceElectricalPowerOutput, 0.01)
      assert_in_epsilon(137.0, generator.minimumFullLoadElectricalPowerOutput, 0.01)
      assert_in_epsilon(137.0, generator.maximumFullLoadElectricalPowerOutput, 0.01)
      assert_in_epsilon(0.48, generator.referenceElectricalEfficiencyUsingLowerHeatingValue, 0.01)
      assert_equal(generator.fuelHigherHeatingValue, generator.fuelLowerHeatingValue)
      assert_equal(0, generator.standbyPower)
      assert_equal(0, generator.ancillaryPower)
    end
  end

  def test_generator_shared
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-generator.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    hpxml_bldg.generators.each do |hpxml_generator|
      generator = get_generator(model, hpxml_generator.id)

      # Check object
      assert_equal(EPlus.fuel_type(hpxml_generator.fuel_type), generator.fuelType)
      assert_in_epsilon(228.3, generator.referenceElectricalPowerOutput, 0.01)
      assert_in_epsilon(228.3, generator.minimumFullLoadElectricalPowerOutput, 0.01)
      assert_in_epsilon(228.3, generator.maximumFullLoadElectricalPowerOutput, 0.01)
      assert_in_epsilon(0.48, generator.referenceElectricalEfficiencyUsingLowerHeatingValue, 0.01)
      assert_equal(generator.fuelHigherHeatingValue, generator.fuelLowerHeatingValue)
      assert_equal(0, generator.standbyPower)
      assert_equal(0, generator.ancillaryPower)
    end
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
end
