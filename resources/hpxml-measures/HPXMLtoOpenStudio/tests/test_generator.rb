# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'

class HPXMLtoOpenStudioGeneratorTest < Minitest::Test
  def teardown
    File.delete(File.join(File.dirname(__FILE__), 'in.schedules.csv')) if File.exist? File.join(File.dirname(__FILE__), 'in.schedules.csv')
    File.delete(File.join(File.dirname(__FILE__), 'results_annual.csv')) if File.exist? File.join(File.dirname(__FILE__), 'results_annual.csv')
    File.delete(File.join(File.dirname(__FILE__), 'results_design_load_details.csv')) if File.exist? File.join(File.dirname(__FILE__), 'results_design_load_details.csv')
  end

  def sample_files_dir
    return File.join(File.dirname(__FILE__), '..', '..', 'workflow', 'sample_files')
  end

  def get_generator(model, name)
    model.getGeneratorMicroTurbines.each do |g|
      next unless g.name.to_s.start_with? "#{name} "

      return g
    end
  end

  def test_generator
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-misc-generators.xml'))
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-bldgtype-mf-unit-shared-generator.xml'))
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
    show_output(result) unless result.value.valueName == 'Success'

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)

    hpxml = HPXML.new(hpxml_path: args_hash['hpxml_path'])

    File.delete(File.join(File.dirname(__FILE__), 'in.xml'))

    return model, hpxml, hpxml.buildings[0]
  end
end
