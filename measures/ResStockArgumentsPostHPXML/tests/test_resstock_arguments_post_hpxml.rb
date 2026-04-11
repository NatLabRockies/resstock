# frozen_string_literal: true

require 'openstudio'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../../../resources/buildstock'
require_relative '../measure'

class ResStockArgumentsPostHPXMLTest < Minitest::Test
  def test_hvac_load_flexibility_measure
    puts 'Testing HVAC Load Flexibility'

    # Define test parameters
    test_cases = [
      { dst_enabled: false, existing_schedule: false, name: 'HVAC without DST' },
      { dst_enabled: true, existing_schedule: false, name: 'HVAC with DST enabled' },
      { dst_enabled: false, existing_schedule: true, name: 'HVAC without DST with existing schedule' },
      { dst_enabled: true, existing_schedule: true, name: 'HVAC with DST enabled with existing schedule' }
    ]

    curdir = File.dirname(__FILE__)
    osw_hash_orgi = JSON.parse(File.read(File.join(curdir, 'test_template.osw')))

    # Find the index of the ResStockArgumentsPostHPXML measure in the steps and set ev_flex_enabled to false
    resstock_measure_index = osw_hash_orgi['steps'].find_index { |step| step['measure_dir_name'] == 'ResStockArgumentsPostHPXML' }
    osw_hash_orgi['steps'][resstock_measure_index]['arguments']['ev_flex_enabled'] = false
    osw_hash_orgi['steps'][0]['arguments']['ev_charger_present'] = false

    # Check behavior with and without DST
    test_cases.each do |params|
      puts "Testing #{params[:name]}"
      osw_hash = Marshal.load(Marshal.dump(osw_hash_orgi))
      # Set DST parameter if needed
      osw_hash['steps'][0]['arguments']['simulation_control_daylight_saving_enabled'] = true if params[:dst_enabled]

      # remove BuildResidentialScheduleFile from the steps if existing_schedule is false
      osw_hash['steps'].reject! { |step| step['measure_dir_name'] == 'BuildResidentialScheduleFile' } unless params[:existing_schedule]

      _run_osw(osw_hash)
      schedule = _get_schedule(curdir)
      _verify_peak_period(dst_enabled: params[:dst_enabled], peak_type: 'shift', schedule: schedule) unless params[:dst_enabled]
      _verify_hvac_schedule(dst_enabled: params[:dst_enabled], peak_type: 'shift', schedule: schedule)
      # remove the run folder
      FileUtils.rm_rf(File.join(curdir, 'run'))
    end
  end

  def test_ev_load_flexibility_measure
    puts 'Testing EV Load Flexibility'
    # Define test parameters
    test_cases = [
      { dst_enabled: false, name: 'EV without DST' },
      { dst_enabled: true, name: 'EV with DST enabled' }
    ]

    curdir = File.dirname(__FILE__)
    osw_hash_orgi = JSON.parse(File.read(File.join(curdir, 'test_template.osw')))

    # Locate the ResStockArgumentsPostHPXML measure in the workflow steps and disable HVAC flexibility
    # by setting both the peak offset and pre-peak duration arguments to 0
    measure_index = osw_hash_orgi['steps'].find_index { |step| step['measure_dir_name'] == 'ResStockArgumentsPostHPXML' }
    osw_hash_orgi['steps'][measure_index]['arguments']['hvac_flex_peak_offset'] = 0
    osw_hash_orgi['steps'][measure_index]['arguments']['hvac_flex_pre_peak_duration_hours'] = 0

    # Check behavior with and without DST
    test_cases.each do |params|
      puts "Testing #{params[:name]}"
      osw_hash = Marshal.load(Marshal.dump(osw_hash_orgi))
      # Set DST parameter if needed
      osw_hash['steps'][0]['arguments']['simulation_control_daylight_saving_enabled'] = true if params[:dst_enabled]

      _run_osw(osw_hash)
      schedule = _get_schedule(curdir)
      _verify_peak_period(dst_enabled: params[:dst_enabled], peak_type: 'shed', schedule: schedule) unless params[:dst_enabled]
      _verify_ev_schedule(dst_enabled: params[:dst_enabled], peak_type: 'shed', schedule: schedule)
      FileUtils.rm_rf(File.join(curdir, 'run'))
    end
  end

  def test_combined_hvac_and_ev_flexibility
    puts 'Testing Combined HVAC and EV Load Flexibility'

    test_cases = [
      { dst_enabled: false, name: 'HVAC and EV without DST' },
      { dst_enabled: true, name: 'HVAC and EV with DST enabled' }
    ]

    curdir = File.dirname(__FILE__)
    osw_hash_orgi = JSON.parse(File.read(File.join(curdir, 'test_template.osw')))

    # The template has both HVAC and EV flexibility enabled by default

    # Check behavior with and without DST
    test_cases.each do |params|
      puts "Testing #{params[:name]}"
      osw_hash = Marshal.load(Marshal.dump(osw_hash_orgi))

      # Set DST if applicable
      osw_hash['steps'][0]['arguments']['simulation_control_daylight_saving_enabled'] = true if params[:dst_enabled]

      # Run the osw
      _run_osw(osw_hash)
      schedule = _get_schedule(curdir)

      # Verify a shift with HVAC and shed with EV
      _verify_peak_period(dst_enabled: params[:dst_enabled], peak_type: 'shift', schedule: schedule) unless params[:dst_enabled]
      _verify_hvac_schedule(dst_enabled: params[:dst_enabled], peak_type: 'shift', schedule: schedule)
      _verify_ev_schedule(dst_enabled: params[:dst_enabled], peak_type: 'shift', schedule: schedule)

      FileUtils.rm_rf(File.join(curdir, 'run'))
    end
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

  def _winter_test_indices(peak_type:)
    # indices for setpoint 01-01 14:00:00-15:00:00, 15:00:00-16:00:00, 16:00:00-17:00:00, 17:00:00-18:00:00
    # the on-peak hour in CO in winter starts from 17:00:00 for shift and 18:00 for shed
    # before pre_peak, pre_peak, pre_peak, peak, peak, peak, peak, none
    #           n  pp  pp  pk  pk  pk  pk   n
    indices = [14, 15, 16, 17, 18, 19, 20, 21]
    indices = indices.map { |num| num + 1 } if peak_type == 'shed'
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

  def _summer_test_indices(dst_enabled:, peak_type:)
    # indices for 06-09 (day 159) 13:00:00-14:00:00, 14:00:00-15:00:00, 15:00:00-16:00:00, 16:00:00-17:00:00,
    # The daily avg temp for this day in CO is 63.4F, so, there is no precooling or preheating
    # the on-peak hour in CO in summer starts from 16:00:00 for shift and 18:00 for shed
    # before pre_peak, pre_peak, pre_peak, peak, peak, peak, peak, none
    #           n     pp    pp    pk    pk    pk    pk    n
    indices = [3829, 3830, 3831, 3832, 3833, 3834, 3835, 3836]
    indices = indices.map { |num| num + 1 } if dst_enabled
    indices = indices.map { |num| num + 2 } if peak_type == 'shed'
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

  def _verify_peak_period(dst_enabled:, peak_type:, schedule:)
    winter_indices = _winter_test_indices(peak_type: peak_type)
    summer_indices = _summer_test_indices(dst_enabled: dst_enabled, peak_type: peak_type)
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

  def _verify_hvac_schedule(dst_enabled:, peak_type:, schedule:)
    winter_indices = _winter_test_indices(peak_type: peak_type)
    summer_indices = _summer_test_indices(peak_type: peak_type, dst_enabled: dst_enabled)

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
        assert_equal(summer_cooling_setpoint_base, cooling_setpoint) # No precooling because daily avg temp is 63.4F
        assert_equal(summer_heating_setpoint_base, heating_setpoint)
      elsif value == 'peak'
        assert_equal(summer_cooling_setpoint_base + 2, cooling_setpoint)
        assert_equal(summer_heating_setpoint_base - 2, heating_setpoint)
      end
    end
  end

  def _verify_ev_schedule(dst_enabled:, peak_type:, schedule:)
    winter_indices = _winter_test_indices(peak_type: peak_type)
    summer_indices = _summer_test_indices(peak_type: peak_type, dst_enabled: dst_enabled)
    # EV cannot be charging during peak period. It could be discharging.
    winter_indices.each do |index, value|
      assert schedule[index]['electric_vehicle'].to_f <= 0 if value == 'peak'
    end
    summer_indices.each do |index, value|
      assert schedule[index]['electric_vehicle'].to_f <= 0 if value == 'peak'
    end
  end

  def _celsius_to_fahrenheit(celsius)
    fahrenheit = (celsius * 9.0 / 5.0) + 32
    fahrenheit.round
  end
end
