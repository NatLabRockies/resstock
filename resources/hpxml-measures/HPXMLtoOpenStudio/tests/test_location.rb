# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'

class HPXMLtoOpenStudioLocationTest < Minitest::Test
  def teardown
    File.delete(File.join(File.dirname(__FILE__), 'in.schedules.csv')) if File.exist? File.join(File.dirname(__FILE__), 'in.schedules.csv')
    File.delete(File.join(File.dirname(__FILE__), 'results_annual.csv')) if File.exist? File.join(File.dirname(__FILE__), 'results_annual.csv')
    File.delete(File.join(File.dirname(__FILE__), 'results_design_load_details.csv')) if File.exist? File.join(File.dirname(__FILE__), 'results_design_load_details.csv')
  end

  def sample_files_dir
    return File.join(File.dirname(__FILE__), '..', '..', 'workflow', 'sample_files')
  end

  def get_daylight_saving_month_and_days(model)
    run_period_control_daylight_saving_time = model.getRunPeriodControlDaylightSavingTime
    start_date = run_period_control_daylight_saving_time.startDate
    end_date = run_period_control_daylight_saving_time.endDate
    begin_month = start_date.monthOfYear.value
    begin_day = start_date.dayOfMonth
    end_month = end_date.monthOfYear.value
    end_day = end_date.dayOfMonth
    return begin_month, begin_day, end_month, end_day
  end

  def test_dst_default
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    assert_equal(1, model.getObjectsByType('OS:RunPeriodControl:DaylightSavingTime'.to_IddObjectType).size)
    begin_month, begin_day, end_month, end_day = get_daylight_saving_month_and_days(model)
    assert_equal(3, begin_month)
    assert_equal(12, begin_day)
    assert_equal(11, end_month)
    assert_equal(5, end_day)
  end

  def test_dst_custom
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-simcontrol-daylight-saving-custom.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    assert_equal(1, model.getObjectsByType('OS:RunPeriodControl:DaylightSavingTime'.to_IddObjectType).size)
    begin_month, begin_day, end_month, end_day = get_daylight_saving_month_and_days(model)
    assert_equal(3, begin_month)
    assert_equal(10, begin_day)
    assert_equal(11, end_month)
    assert_equal(6, end_day)
  end

  def test_dst_disabled
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-simcontrol-daylight-saving-disabled.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    assert_equal(0, model.getObjectsByType('OS:RunPeriodControl:DaylightSavingTime'.to_IddObjectType).size)
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
