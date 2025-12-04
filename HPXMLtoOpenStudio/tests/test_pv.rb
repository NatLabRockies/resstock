# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'
require_relative 'util.rb'

class HPXMLtoOpenStudioPVTest < Minitest::Test
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
    ['base-pv.xml',
     'base-pv-inverters.xml'].each do |hpxml_name|
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, hpxml_name))
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
        if hpxml_name == 'base-pv.xml'
          assert_equal(0.96, inverter.inverterEfficiency)
        else
          assert_in_delta(0.955, inverter.inverterEfficiency, 0.001) # weighted-average efficiency
        end
      end
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
