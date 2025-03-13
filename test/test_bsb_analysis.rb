# frozen_string_literal: true

require_relative '../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../test/analysis'
require_relative '../resources/hpxml-measures/HPXMLtoOpenStudio/resources/unit_conversions.rb'

class TestBuildStockBatch < Minitest::Test
  def before_setup
    @testing_baseline = 'project_testing/testing_baseline'
    @national_baseline = 'project_national/national_baseline'
    @sdr_upgrades = 'project_national/sdr_upgrades_tmy3'
  end

  def test_testing_baseline
    assert(File.exist?(File.join(@testing_baseline, 'results_csvs', 'results_up00.csv')))
    results = CSV.read(File.join(@testing_baseline, 'results_csvs', 'results_up00.csv'), headers: true)

    _test_columns(results)

    assert(File.exist?(File.join(@testing_baseline, 'simulation_output', 'up00', 'bldg0000001', 'run')))
    contents = Dir[File.join(@testing_baseline, 'simulation_output', 'up00', 'bldg0000001', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, false, true)

    timeseries = _get_timeseries_columns(Dir[File.join(@testing_baseline, 'simulation_output/up*/bldg*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries, true))
  end

  def test_national_baseline
    assert(File.exist?(File.join(@national_baseline, 'results_csvs', 'results_up00.csv')))
    results = CSV.read(File.join(@national_baseline, 'results_csvs', 'results_up00.csv'), headers: true)

    _test_columns(results)

    assert(File.exist?(File.join(@national_baseline, 'simulation_output', 'up00', 'bldg0000001', 'run')))
    contents = Dir[File.join(@national_baseline, 'simulation_output', 'up00', 'bldg0000001', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, false, false)

    timeseries = _get_timeseries_columns(Dir[File.join(@national_baseline, 'simulation_output/up*/bldg*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries))
  end

  def test_sdr_upgrades
    assert(File.exist?(File.join(@sdr_upgrades, 'results_csvs', 'results_up00.csv')))
    results = CSV.read(File.join(@sdr_upgrades, 'results_csvs', 'results_up00.csv'), headers: true)

    _test_columns(results)

    assert(File.exist?(File.join(@sdr_upgrades, 'simulation_output', 'up00', 'bldg0000001', 'run')))
    contents = Dir[File.join(@sdr_upgrades, 'simulation_output', 'up00', 'bldg0000001', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, false, false)

    num_upgrade_scenarios = Dir[File.join(@sdr_upgrades, 'results_csvs', 'results_up*')].count - 1
    assert(File.exist?(File.join(@sdr_upgrades, 'results_csvs', "results_up#{num_upgrade_scenarios}.csv")))
    results = CSV.read(File.join(@sdr_upgrades, 'results_csvs', "results_up#{num_upgrade_scenarios}.csv"), headers: true)

    _test_columns(results, true)

    assert(File.exist?(File.join(@sdr_upgrades, 'simulation_output', "up#{num_upgrade_scenarios}", 'bldg0000001', 'run')))
    contents = Dir[File.join(@sdr_upgrades, 'simulation_output', "up#{num_upgrade_scenarios}", 'bldg0000001', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, true, false)

    timeseries = _get_timeseries_columns(Dir[File.join(@sdr_upgrades, 'simulation_output/up*/bldg*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries))
  end

  def test_testing_inputs
    expected_inputs = CSV.read(File.join('resources', 'data', 'dictionary', 'inputs.csv'), headers: true)
    expected_names = expected_inputs['Input Name']

    expected_outputs = CSV.read(File.join('resources', 'data', 'dictionary', 'outputs.csv'), headers: true)
    expected_outputs['Annual Name'] = _map_scenario_names(expected_outputs['Annual Name'], 'report_simulation_output.emissions_<type>_<scenario_name>', 'report_simulation_output.emissions_co_2_e_lrmer_mid_case_15')
    expected_outputs['Annual Name'] = _map_scenario_names(expected_outputs['Annual Name'], 'report_utility_bills.<scenario_name>', 'report_utility_bills.bills')
    expected_annual_names = expected_outputs['Annual Name'].select { |n| !n.nil? }

    actual_outputs = CSV.read(File.join(@testing_baseline, 'results_csvs', 'results_up00.csv'), headers: true)
    actual_outputs.headers.map { |x| actual_outputs.delete(x) if x.include?('report_utility_bills.bills_2_') }
    actual_outputs.headers.map { |x| actual_outputs.delete(x) if x.include?('report_utility_bills.bills_3_') }
    actual_outputs.headers.map { |x| actual_outputs.delete(x) if x.include?('server_directory_cleanup.') }
    actual_names = actual_outputs.headers - expected_annual_names

    actual_extras = actual_names - expected_names
    puts "Input Name, actual - expected: #{actual_extras}" if !actual_extras.empty?
    assert_equal(0, actual_extras.size)

    # expected_extras = expected_names - actual_names
    # puts "Input Name, expected - actual: #{expected_extras}" if !expected_extras.empty?
    # assert_equal(0, expected_extras.size) # allow
  end

  def test_national_inputs
    expected_inputs = CSV.read(File.join('resources', 'data', 'dictionary', 'inputs.csv'), headers: true)
    expected_names = expected_inputs['Input Name']

    expected_outputs = CSV.read(File.join('resources', 'data', 'dictionary', 'outputs.csv'), headers: true)
    expected_outputs['Annual Name'] = _map_scenario_names(expected_outputs['Annual Name'], 'report_simulation_output.emissions_<type>_<scenario_name>', 'report_simulation_output.emissions_co_2_e_lrmer_mid_case_15')
    expected_outputs['Annual Name'] = _map_scenario_names(expected_outputs['Annual Name'], 'report_utility_bills.<scenario_name>', 'report_utility_bills.bills')
    expected_annual_names = expected_outputs['Annual Name'].select { |n| !n.nil? }

    actual_outputs = CSV.read(File.join(@national_baseline, 'results_csvs', 'results_up00.csv'), headers: true)
    actual_names = actual_outputs.headers - expected_annual_names

    actual_extras = actual_names - expected_names
    puts "Input Name, actual - expected: #{actual_extras}" if !actual_extras.empty?
    assert_equal(0, actual_extras.size)

    expected_extras = expected_names - actual_names
    puts "Input Name, expected - actual: #{expected_extras}" if !expected_extras.empty?
    assert_equal(0, expected_extras.size)
  end

  def test_testing_annual_outputs
    expected_inputs = CSV.read(File.join('resources', 'data', 'dictionary', 'inputs.csv'), headers: true)
    expected_names = expected_inputs['Input Name']

    expected_outputs = CSV.read(File.join('resources', 'data', 'dictionary', 'outputs.csv'), headers: true)
    expected_outputs['Annual Name'] = _map_scenario_names(expected_outputs['Annual Name'], 'report_simulation_output.emissions_<type>_<scenario_name>', 'report_simulation_output.emissions_co_2_e_lrmer_mid_case_15')
    expected_outputs['Annual Name'] = _map_scenario_names(expected_outputs['Annual Name'], 'report_utility_bills.<scenario_name>', 'report_utility_bills.bills')
    expected_annual_names = expected_outputs['Annual Name'].select { |n| !n.nil? }

    actual_outputs = CSV.read(File.join(@testing_baseline, 'results_csvs', 'results_up00.csv'), headers: true)
    actual_outputs.headers.map { |x| actual_outputs.delete(x) if x.include?('report_utility_bills.bills_2_') }
    actual_outputs.headers.map { |x| actual_outputs.delete(x) if x.include?('report_utility_bills.bills_3_') }
    actual_outputs.headers.map { |x| actual_outputs.delete(x) if x.include?('server_directory_cleanup.') }
    actual_annual_names = actual_outputs.headers - expected_names

    actual_extras = actual_annual_names - expected_annual_names
    puts "Annual Name, actual - expected: #{actual_extras}" if !actual_extras.empty?
    assert_equal(0, actual_extras.size)

    # expected_extras = expected_annual_names - actual_annual_names
    # puts "Annual Name, expected - actual: #{expected_extras}" if !expected_extras.empty?
    # assert_equal(0, expected_extras.size) # allow

    tol = 0.001
    sums_to_indexes = expected_outputs['Sums To'].select { |n| !n.nil? }.uniq
    sums_to_indexes.each do |sums_to_ix|
      ix = expected_outputs['Row Index'].index(sums_to_ix)
      sums_to = expected_outputs['Annual Name'][ix]

      terms = []
      expected_outputs['Sums To'].zip(expected_outputs['Annual Name']).each do |ix, annual_name|
        terms << annual_name if ix == sums_to_ix
      end

      sums_to_val = actual_outputs[sums_to].map { |x| !x.nil? ? Float(x) : 0.0 }.sum
      terms_val = terms.collect { |t| actual_outputs[t].map { |x| !x.nil? ? Float(x) : 0.0 }.sum }.sum

      assert_in_epsilon(sums_to_val, terms_val, tol, "Summed value #{terms_val} does not equal #{sums_to} (#{sums_to_val})")
    end
  end

  def test_national_annual_outputs
    expected_inputs = CSV.read(File.join('resources', 'data', 'dictionary', 'inputs.csv'), headers: true)
    expected_names = expected_inputs['Input Name']

    expected_outputs = CSV.read(File.join('resources', 'data', 'dictionary', 'outputs.csv'), headers: true)
    expected_outputs['Annual Name'] = _map_scenario_names(expected_outputs['Annual Name'], 'report_simulation_output.emissions_<type>_<scenario_name>', 'report_simulation_output.emissions_co_2_e_lrmer_mid_case_15')
    expected_outputs['Annual Name'] = _map_scenario_names(expected_outputs['Annual Name'], 'report_utility_bills.<scenario_name>', 'report_utility_bills.bills')
    expected_annual_names = expected_outputs['Annual Name'].select { |n| !n.nil? }

    actual_outputs = CSV.read(File.join(@national_baseline, 'results_csvs', 'results_up00.csv'), headers: true)
    actual_annual_names = actual_outputs.headers - expected_names

    actual_extras = actual_annual_names - expected_annual_names
    puts "Annual Name, actual - expected: #{actual_extras}" if !actual_extras.empty?
    assert_equal(0, actual_extras.size)

    # expected_extras = expected_annual_names - actual_annual_names
    # puts "Annual Name, expected - actual: #{expected_extras}" if !expected_extras.empty?
    # assert_equal(0, expected_extras.size) # allow

    tol = 0.001
    sums_to_indexes = expected_outputs['Sums To'].select { |n| !n.nil? }.uniq
    sums_to_indexes.each do |sums_to_ix|
      ix = expected_outputs['Row Index'].index(sums_to_ix)
      sums_to = expected_outputs['Annual Name'][ix]

      terms = []
      expected_outputs['Sums To'].zip(expected_outputs['Annual Name']).each do |ix, annual_name|
        terms << annual_name if ix == sums_to_ix
      end

      sums_to_val = actual_outputs[sums_to].map { |x| !x.nil? ? Float(x) : 0.0 }.sum
      terms_val = terms.collect { |t| actual_outputs[t].map { |x| !x.nil? ? Float(x) : 0.0 }.sum }.sum

      assert_in_epsilon(sums_to_val, terms_val, tol, "Summed value #{terms_val} does not equal #{sums_to} (#{sums_to_val})")
    end
  end

  def test_timeseries_resstock_outputs
    ts_col = 'Timeseries ResStock Name'

    expected_outputs = CSV.read(File.join('resources', 'data', 'dictionary', 'outputs.csv'), headers: true)
    expected_outputs[ts_col] = _map_scenario_names(expected_outputs[ts_col], 'Emissions: <type>: <scenario_name>', 'Emissions: CO2e: LRMER_MidCase_15')
    expected_timeseries_names = expected_outputs[ts_col].select { |n| !n.nil? }

    actual_outputs = CSV.read(File.join('baseline', 'timeseries', 'results_output.csv'), headers: true)
    actual_timeseries_names = actual_outputs.headers

    actual_extras = actual_timeseries_names - expected_timeseries_names
    actual_extras -= ['PROJECT']
    puts "#{ts_col}, actual - expected: #{actual_extras}" if !actual_extras.empty?
    assert_equal(0, actual_extras.size)

    # expected_extras = expected_timeseries_names - actual_timeseries_names
    # puts "#{ts_col}, expected - actual: #{expected_extras}" if !expected_extras.empty?
    # assert_equal(0, expected_extras.size) # allow

    tol = 0.001
    sums_to_indexes = expected_outputs['Sums To'].select { |n| !n.nil? }.uniq
    sums_to_indexes.each do |sums_to_ix|
      ix = expected_outputs['Row Index'].index(sums_to_ix)
      sums_to = expected_outputs[ts_col][ix]

      terms = []
      expected_outputs['Sums To'].zip(expected_outputs[ts_col]).each do |ix, annual_name|
        terms << annual_name if ix == sums_to_ix
      end

      sums_to_val = actual_outputs.headers.include?(sums_to) ? actual_outputs[sums_to].map { |x| Float(x) }.sum : 0.0
      terms_vals = []
      terms.each do |term|
        if actual_outputs.headers.include?(term)
          terms_vals << actual_outputs[term].map { |x| term != 'Fuel Use: Electricity: Total' ? Float(x) : UnitConversions.convert(Float(x), 'kWh', 'kBtu') }.sum
        else
          terms_vals << 0.0
        end
      end
      terms_val = terms_vals.sum

      assert_in_epsilon(sums_to_val, terms_val, tol, "Summed value #{terms_val} does not equal #{sums_to} (#{sums_to_val})")
    end
  end

  def test_timeseries_buildstockbatch_outputs
    ts_col = 'Timeseries BuildStockBatch Name'

    expected_outputs = CSV.read(File.join('resources', 'data', 'dictionary', 'outputs.csv'), headers: true)
    expected_outputs[ts_col] = _map_scenario_names(expected_outputs[ts_col], 'emissions__<type>__<scenario_name>', 'emissions__co2e__lrmer_midcase_15')
    expected_timeseries_names = expected_outputs[ts_col].select { |n| !n.nil? }

    actual_outputs = CSV.read(File.join('baseline', 'timeseries', 'buildstockbatch.csv'), headers: true)
    actual_timeseries_names = actual_outputs.headers

    actual_extras = actual_timeseries_names - expected_timeseries_names
    actual_extras -= ['PROJECT']
    puts "#{ts_col}, actual - expected: #{actual_extras}" if !actual_extras.empty?
    assert_equal(0, actual_extras.size)

    tol = 0.001
    sums_to_indexes = expected_outputs['Sums To'].select { |n| !n.nil? }.uniq
    sums_to_indexes.each do |sums_to_ix|
      ix = expected_outputs['Row Index'].index(sums_to_ix)
      sums_to = expected_outputs[ts_col][ix]

      terms = []
      expected_outputs['Sums To'].zip(expected_outputs[ts_col]).each do |ix, annual_name|
        terms << annual_name if ix == sums_to_ix
      end

      sums_to_val = actual_outputs.headers.include?(sums_to) ? actual_outputs[sums_to].map { |x| Float(x) }.sum : 0.0
      terms_vals = []
      terms.each do |term|
        if actual_outputs.headers.include?(term)
          terms_vals << actual_outputs[term].map { |x| term != 'fuel_use__electricity__total__kwh' ? Float(x) : UnitConversions.convert(Float(x), 'kWh', 'kBtu') }.sum
        else
          terms_vals << 0.0
        end
      end
      terms_val = terms_vals.sum

      assert_in_epsilon(sums_to_val, terms_val, tol, "Summed value #{terms_val} does not equal #{sums_to} (#{sums_to_val})")
    end
  end

  private

  def _map_scenario_names(list, from, to)
    list = list.map { |n| n.gsub(from, to) if !n.nil? }
    return list
  end
end
