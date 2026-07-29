# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'
require_relative 'util.rb'

class HPXMLtoOpenStudioSimControlsTest < Minitest::Test
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

  def get_run_period_month_and_days(model)
    run_period = model.getRunPeriod
    begin_month = run_period.getBeginMonth
    begin_day = run_period.getBeginDayOfMonth
    end_month = run_period.getEndMonth
    end_day = run_period.getEndDayOfMonth
    return begin_month, begin_day, end_month, end_day
  end

  def test_run_period_year
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    begin_month, begin_day, end_month, end_day = get_run_period_month_and_days(model)
    assert_equal(1, begin_month)
    assert_equal(1, begin_day)
    assert_equal(12, end_month)
    assert_equal(31, end_day)
  end

  def test_run_period_1month
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-simcontrol-runperiod-1-month.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    begin_month, begin_day, end_month, end_day = get_run_period_month_and_days(model)
    assert_equal(2, begin_month)
    assert_equal(15, begin_day)
    assert_equal(3, end_month)
    assert_equal(15, end_day)
  end

  def test_timestep_1hour
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    assert_equal(1, model.getTimestep.numberOfTimestepsPerHour)
  end

  def test_timestep_10min
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-simcontrol-timestep-10-mins.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    assert_equal(6, model.getTimestep.numberOfTimestepsPerHour)
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
