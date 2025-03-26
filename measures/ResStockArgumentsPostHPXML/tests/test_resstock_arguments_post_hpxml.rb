# frozen_string_literal: true

require 'openstudio'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../../../resources/buildstock'
require_relative '../measure'
require 'byebug'

class ResStockArgumentsPostHPXMLTest < Minitest::Test
  def test_hvac_load_flexibility_measure
    puts 'Testing Load Flexibility'
    curdir = File.dirname(__FILE__)
    osw_hash = JSON.parse(File.read(File.join(curdir, 'test_template.osw')))
    _run_osw(osw_hash)
    schedule = _get_schedule(curdir)
    _verify_peak_period(dst_enabled: false, schedule: schedule)
    _verify_hvac_schedule(dst_enabled: false, schedule: schedule)
  end

  def test_hvac_load_flexibility_measure_dst_impacted
    puts 'Testing Load Flexibility with DST Impacted'
    curdir = File.dirname(__FILE__)
    osw_hash = JSON.parse(File.read(File.join(curdir, 'test_template.osw')))
    osw_hash['steps'][0]['arguments']['simulation_control_daylight_saving_enabled'] = true
    _run_osw(osw_hash)
    schedule = _get_schedule(curdir)
    _verify_hvac_schedule(dst_enabled: true, schedule: schedule)
  end

  private

  def _run_osw(osw_hash)
    require 'json'
    require 'csv'
    model = OpenStudio::Model::Model.new
    measures = {}
    measures_dirs = osw_hash['measure_paths'].map { |path| File.join(File.dirname(__FILE__), path) }
    osw_hash['steps'].each do |step|
      measures[step['measure_dir_name']] = [step['arguments']]
    end
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    success = apply_measures(measures_dirs, measures, runner, model)
    runner.result.stepWarnings.each do |s|
      puts "Warning: #{s}"
    end
    runner.result.stepErrors.each do |s|
      puts "Error: #{s}"
    end
    assert(success)
  end

  def _get_schedule(dir)
    schedule_file_path = File.join(dir, 'run', 'in.schedules.csv')
    rows_by_index = {}
    CSV.foreach(schedule_file_path, headers: true).with_index do |row, index|
      rows_by_index[index] = row.to_h
    end
    rows_by_index
  end

  def _winter_test_indices
    # indices for setpint 01-01 14:00:00-15:00:00, 15:00:00-16:00:00, 16:00:00-17:00:00, 17:00:00-18:00:00
    # the on-peak hour in CO in winter starts from 17:00:00
    # before pre_peak, pre_peak, pre_peak, peak, peak, peak, peak, none
    indices = [14, 15, 16, 17, 18, 19, 20, 21]
    {
      indices[0] => 'none',
      indices[1] => 'pre_peak',
      indices[2] => 'pre_peak',
      indices[3] => 'peak',
      indices[4] => 'peak',
      indices[5] => 'peak',
      indices[6] => 'peak',
      indices[7] => 'none'
    }
  end

  def _summer_test_indices(dst_enabled:)
    # indices for 05-09 13:00:00-14:00:00, 14:00:00-15:00:00, 15:00:00-16:00:00, 16:00:00-17:00:00,
    # the on-peak hour in CO in summer starts from 16:00:00
    # before pre_peak, pre_peak, pre_peak, peak, peak, peak, peak, none
    indices = [3085, 3086, 3087, 3088, 3089, 3090, 3091, 3092]
    indices = indices.map { |num| num + 1 } if dst_enabled
    {
      indices[0] => 'none',
      indices[1] => 'pre_peak',
      indices[2] => 'pre_peak',
      indices[3] => 'peak',
      indices[4] => 'peak',
      indices[5] => 'peak',
      indices[6] => 'peak',
      indices[7] => 'none'
    }
  end

  def _verify_peak_period(dst_enabled:, schedule:)
    winter_indices = _winter_test_indices
    summer_indices = _summer_test_indices(dst_enabled: dst_enabled)
    # Check winter indices
    winter_indices.each do |index, value|
      if value == 'none'
        assert_equal(0, schedule[index]['peak_period'].to_f)
        assert_equal(0, schedule[index]['pre_peak_period'].to_f) if schedule[index].key?('pre_peak_period')
      elsif value == 'pre_peak'
        assert_equal(0, schedule[index]['peak_period'].to_f)
        assert_equal(1, schedule[index]['pre_peak_period'].to_f) if schedule[index].key?('pre_peak_period')
      elsif value == 'peak'
        assert_equal(1, schedule[index]['peak_period'].to_f)
        assert_equal(0, schedule[index]['pre_peak_period'].to_f) if schedule[index].key?('pre_peak_period')
      end
    end

    # Check summer indices
    summer_indices.each do |index, value|
      if value == 'none'
        assert_equal(0, schedule[index]['peak_period'].to_f)
        assert_equal(0, schedule[index]['pre_peak_period'].to_f) if schedule[index].key?('pre_peak_period')
      elsif value == 'pre_peak'
        assert_equal(0, schedule[index]['peak_period'].to_f)
        assert_equal(1, schedule[index]['pre_peak_period'].to_f) if schedule[index].key?('pre_peak_period')
      elsif value == 'peak'
        assert_equal(1, schedule[index]['peak_period'].to_f)
        assert_equal(0, schedule[index]['pre_peak_period'].to_f) if schedule[index].key?('pre_peak_period')
      end
    end
  end

  def _verify_hvac_schedule(dst_enabled:, schedule:)
    winter_indices = _winter_test_indices
    summer_indices = _summer_test_indices(dst_enabled: dst_enabled)

    # Get base setpoints for winter
    winter_base_index = winter_indices.find { |_index, value| value == 'none' }[0]
    winter_heating_setpoint_base = _celsius_to_fahrenheit(schedule[winter_base_index]['heating_setpoint'].to_f)
    winter_cooling_setpoint_base = _celsius_to_fahrenheit(schedule[winter_base_index]['cooling_setpoint'].to_f)

    # Get base setpoints for summer
    summer_base_index = summer_indices.find { |_index, value| value == 'none' }[0]
    summer_heating_setpoint_base = _celsius_to_fahrenheit(schedule[summer_base_index]['heating_setpoint'].to_f)
    summer_cooling_setpoint_base = _celsius_to_fahrenheit(schedule[summer_base_index]['cooling_setpoint'].to_f)

    # Check winter indices
    winter_indices.each do |index, value|
      heating_setpoint = _celsius_to_fahrenheit(schedule[index]['heating_setpoint'].to_f)
      cooling_setpoint = _celsius_to_fahrenheit(schedule[index]['cooling_setpoint'].to_f)

      if value == 'none'
        assert_equal(winter_heating_setpoint_base, heating_setpoint)
        assert_equal(winter_cooling_setpoint_base, cooling_setpoint)
      elsif value == 'pre_peak'
        assert_equal(winter_heating_setpoint_base + 3, heating_setpoint)
        assert_equal(winter_cooling_setpoint_base, cooling_setpoint)
      elsif value == 'peak'
        assert_equal(winter_heating_setpoint_base - 2, heating_setpoint)
        assert_equal(winter_cooling_setpoint_base + 2, cooling_setpoint)
      end
    end

    # Check summer indices
    summer_indices.each do |index, value|
      cooling_setpoint = _celsius_to_fahrenheit(schedule[index]['cooling_setpoint'].to_f)
      heating_setpoint = _celsius_to_fahrenheit(schedule[index]['heating_setpoint'].to_f)
      if value == 'none'
        assert_equal(summer_cooling_setpoint_base, cooling_setpoint)
        assert_equal(summer_heating_setpoint_base, heating_setpoint)
      elsif value == 'pre_peak'
        assert_equal(summer_cooling_setpoint_base - 3, cooling_setpoint)
        assert_equal(summer_heating_setpoint_base, heating_setpoint)
      elsif value == 'peak'
        assert_equal(summer_cooling_setpoint_base + 2, cooling_setpoint)
        assert_equal(summer_heating_setpoint_base - 2, heating_setpoint)
      end
    end
  end

  def _celsius_to_fahrenheit(celsius)
    fahrenheit = (celsius * 9.0 / 5.0) + 32
    fahrenheit.round
  end
end
