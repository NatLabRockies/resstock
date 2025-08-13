# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'
require_relative 'util.rb'

class HPXMLtoOpenStudioPVTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
  end

  def teardown
    cleanup_results_files
  end

  def get_generator_inverter(model, name)
    generator = nil
    inverter = nil
    model.getGeneratorPVWattss.each do |g|
      next unless g.name.to_s.start_with? "#{name} "

      generator = g
    end
    model.getElectricLoadCenterInverterPVWattss.each do |i|
      inverter = i
    end
    return generator, inverter
  end

  def test_pv
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-pv.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    hpxml_bldg.pv_systems.each_with_index do |pv_system, i|
      generator, inverter = get_generator_inverter(model, pv_system.id)

      # Check PV
      assert_equal(pv_system.array_tilt, generator.tiltAngle)
      assert_equal(pv_system.array_azimuth, generator.azimuthAngle)
      assert_equal(pv_system.max_power_output, generator.dcSystemCapacity)
      assert_equal(0.14, generator.systemLosses)
      if i == 0
        assert_equal('standard', generator.moduleType.downcase)
      else
        assert_equal('premium', generator.moduleType.downcase)
      end
      assert_equal('FixedRoofMounted', generator.arrayType)

      # Check inverter
      assert_equal(0.96, inverter.inverterEfficiency)
    end
  end

  def test_pv_shared
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-pv.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    hpxml_bldg.pv_systems.each do |pv_system|
      generator, inverter = get_generator_inverter(model, pv_system.id)

      # Check PV
      max_power = pv_system.max_power_output * hpxml_bldg.building_construction.number_of_bedrooms.to_f / pv_system.number_of_bedrooms_served.to_f
      assert_equal(pv_system.array_tilt, generator.tiltAngle)
      assert_equal(pv_system.array_azimuth, generator.azimuthAngle)
      assert_equal(max_power, generator.dcSystemCapacity)
      assert_equal(pv_system.system_losses_fraction, generator.systemLosses)
      assert_equal(pv_system.module_type, generator.moduleType.downcase)
      assert_equal('FixedOpenRack', generator.arrayType)

      # Check inverter
      assert_equal(pv_system.inverter.inverter_efficiency, inverter.inverterEfficiency)
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

    hpxml = HPXML.new(hpxml_path: File.join(File.dirname(__FILE__), 'in.xml'))

    File.delete(File.join(File.dirname(__FILE__), 'in.xml'))

    return model, hpxml, hpxml.buildings[0]
  end
end
