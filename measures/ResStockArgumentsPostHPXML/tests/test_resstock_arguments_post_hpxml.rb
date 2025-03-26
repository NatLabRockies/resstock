# frozen_string_literal: true

require 'openstudio'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../../../resources/buildstock.rb'
require_relative '../measure.rb'

class ResStockArgumentsPostHPXMLTest < Minitest::Test
  def test_load_flexibility_measure
    # daylight_saving is false
    osw_file = 'baseline.osw'
    puts "\nTesting #{File.basename(osw_file)}..."
    _test_measure(osw_file)
  end

  def test_load_flexibility_measure_dst_impacted
    # daylight_saving is true
    osw_file = 'baseline_dst_impacted.osw'
    puts "\nTesting #{File.basename(osw_file)}..."
    _test_measure(osw_file)
  end

  private

  def _run_osw(model, osw)
    measures = {}

    osw_hash = JSON.parse(File.read(osw))
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

  def _test_measure(osw_file)
    require 'json'
    require 'csv'

    puts "\nTesting #{osw_file}..."
    this_dir = File.dirname(__FILE__)

    # Existing
    model = OpenStudio::Model::Model.new
    osw = File.absolute_path("#{this_dir}/#{osw_file}")
    _run_osw(model, osw)

    # validate setpoint temperature is modified according to measure
    schedule_file_path = File.join(this_dir, 'run', 'in.schedules.csv')
    # indices for setpint 01-01 14:00:00-15:00:00, 15:00:00-16:00:00, 17:00:00-18:00:00
    # the on-peak hour in CO in winter starts from 17:00:00
    heating_indices = [14, 15, 16, 17]
    # indices for 05-09 13:00:00-14:00:00, 14:00:00-15:00:00, 16:00:00-17:00:00,
    # the on-peak hour in CO in summer starts from 16:00:00
    cooling_indices = [3085, 3086, 3087, 3088]

    # if daylight savings is impacted, add 1 hour to on-peak start and end time
    # the on-peak hour in CO in summer starts from 16:00:00, but it should start from 17:00:00 due to daylight savings
    if osw_file.include?('dst_impacted')
      cooling_indices = cooling_indices.map { |num| num + 1 }
    end

    heating_rows = []
    cooling_rows = []

    CSV.foreach(schedule_file_path, headers: true).with_index do |row, index|
      if heating_indices.include?(index)
        heating_rows << row.to_h
      end
    end
    CSV.foreach(schedule_file_path, headers: true).with_index do |row, index|
      if cooling_indices.include?(index)
        cooling_rows << row.to_h
      end
    end

    assert_equal(0, heating_rows[0]['peak_period'].to_f)
    assert_equal(0, heating_rows[0]['pre_peak_period'].to_f)
    heating_setpoint_base = celsius_to_fahrenheit(heating_rows[0]['heating_setpoint'].to_f)
    assert_equal(1, heating_rows[1]['pre_peak_period'].to_f)
    assert_equal(0, heating_rows[1]['peak_period'].to_f)
    heating_setpoint_pre_peak = celsius_to_fahrenheit(heating_rows[1]['heating_setpoint'].to_f)
    assert_equal(0, heating_rows[3]['pre_peak_period'].to_f)
    assert_equal(1, heating_rows[3]['peak_period'].to_f)
    heating_setpoint_on_peak = celsius_to_fahrenheit(heating_rows[3]['heating_setpoint'].to_f)

    assert_equal(0, cooling_rows[0]['pre_peak_period'].to_f)
    assert_equal(0, cooling_rows[0]['peak_period'].to_f)
    cooling_setpoint_base = celsius_to_fahrenheit(cooling_rows[0]['cooling_setpoint'].to_f)
    assert_equal(1, cooling_rows[1]['pre_peak_period'].to_f)
    assert_equal(0, cooling_rows[1]['peak_period'].to_f)
    cooling_setpoint_pre_peak = celsius_to_fahrenheit(cooling_rows[1]['cooling_setpoint'].to_f)
    assert_equal(0, cooling_rows[3]['pre_peak_period'].to_f)
    assert_equal(1, cooling_rows[3]['peak_period'].to_f)
    cooling_setpoint_on_peak = celsius_to_fahrenheit(cooling_rows[3]['cooling_setpoint'].to_f)

    puts 'Testing heating pre peak setpoint offset'
    assert_equal(3, heating_setpoint_pre_peak - heating_setpoint_base)
    puts 'Testing heating on peak setpoint offset'
    assert_equal(2, heating_setpoint_base - heating_setpoint_on_peak)

    puts 'Testing cooling pre peak setpoint offset'
    assert_equal(3, cooling_setpoint_base - cooling_setpoint_pre_peak)
    puts 'Testing cooling on peak setpoint offset'
    assert_equal(2, cooling_setpoint_on_peak - cooling_setpoint_base)

    FileUtils.rm_rf(File.join(this_dir, 'run'))
  end

  def celsius_to_fahrenheit(celsius)
    fahrenheit = (celsius * 9.0 / 5.0) + 32
    return fahrenheit.round
  end
end
