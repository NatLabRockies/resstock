# frozen_string_literal: true

require_relative '../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../test/analysis'
require_relative '../resources/hpxml-measures/HPXMLtoOpenStudio/resources/unit_conversions.rb'

class TestBuildStockBatch < Minitest::Test
  def before_setup
    @testing_baseline = 'project_testing/testing_baseline'
    @national_baseline = 'project_national/national_baseline'

    @expected_inputs = CSV.read(File.join('resources', 'data', 'dictionary', 'inputs.csv'), headers: true)

    @expected_outputs = CSV.read(File.join('resources', 'data', 'dictionary', 'outputs.csv'), headers: true)
    @expected_outputs['Annual Name'] = _map_scenario_names(@expected_outputs['Annual Name'], 'report_simulation_output.emissions_<type>_<scenario_name>', 'report_simulation_output.emissions_co_2_e_lrmer_mid_case_15')
    @expected_outputs['Annual Name'] = _map_scenario_names(@expected_outputs['Annual Name'], 'report_simulation_output.electric_panel_load_<type>', 'report_simulation_output.electric_panel_load_2023_existing_dwelling_load_based')
    @expected_outputs['Annual Name'] = _map_scenario_names(@expected_outputs['Annual Name'], 'report_utility_bills.<scenario_name>', 'report_utility_bills.bills')
  end

  def test_testing_baseline
    assert(File.exist?(File.join(@testing_baseline, 'results_csvs', 'results_up00.csv')))
    results = CSV.read(File.join(@testing_baseline, 'results_csvs', 'results_up00.csv'), headers: true)

    _test_columns(results)

    assert(File.exist?(File.join(@testing_baseline, 'simulation_output', 'up00', 'bldg0000001', 'run')))
    contents = Dir[File.join(@testing_baseline, 'simulation_output', 'up00', 'bldg0000001', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, true)

    timeseries = _get_timeseries_columns(Dir[File.join(@testing_baseline, 'simulation_output/up*/bldg*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries, true))
  end

  def test_national_baseline
    assert(File.exist?(File.join(@national_baseline, 'results_csvs', 'results_up00.csv')))
    results = CSV.read(File.join(@national_baseline, 'results_csvs', 'results_up00.csv'), headers: true)

    _test_columns(results)

    assert(File.exist?(File.join(@national_baseline, 'simulation_output', 'up00', 'bldg0000001', 'run')))
    contents = Dir[File.join(@national_baseline, 'simulation_output', 'up00', 'bldg0000001', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, false)

    timeseries = _get_timeseries_columns(Dir[File.join(@national_baseline, 'simulation_output/up*/bldg*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries))
  end

  def test_testing_inputs
    expected_input_names = @expected_inputs['Input Name']
    expected_annual_names = @expected_outputs['Annual Name'].select { |n| !n.nil? }

    actual_outputs = CSV.read(File.join(@testing_baseline, 'results_csvs', 'results_up00.csv'), headers: true)
    actual_outputs.headers.map { |x| actual_outputs.delete(x) if x.include?('report_utility_bills.bills_2_') }
    actual_outputs.headers.map { |x| actual_outputs.delete(x) if x.include?('report_utility_bills.bills_3_') }
    actual_outputs.headers.map { |x| actual_outputs.delete(x) if x.include?('server_directory_cleanup.') }
    actual_input_names = actual_outputs.headers - expected_annual_names

    extra_input_arguments = actual_input_names - expected_input_names
    if !extra_input_arguments.empty?
      puts 'extra input arguments:'
      extra_input_arguments.sort.each do |extra_input_argument|
        puts "\t- #{extra_input_argument}"
      end
    end
    assert_equal(0, extra_input_arguments.size)

    missing_input_arguments = expected_input_names - actual_input_names
    if !missing_input_arguments.empty?
      puts 'missing input arguments:'
      missing_input_arguments.sort.each do |missing_input_argument|
        puts "\t- #{missing_input_argument}"
      end
    end
    # assert_equal(0, missing_input_arguments.size) # Allow missing input arguments for the testing project (e.g., build_existing_model.ahs_region, build_existing_model.aiannh_area).
  end

  def test_national_inputs
    expected_input_names = @expected_inputs['Input Name']
    expected_annual_names = @expected_outputs['Annual Name'].select { |n| !n.nil? }

    actual_outputs = CSV.read(File.join(@national_baseline, 'results_csvs', 'results_up00.csv'), headers: true)
    actual_input_names = actual_outputs.headers - expected_annual_names

    extra_input_arguments = actual_input_names - expected_input_names
    if !extra_input_arguments.empty?
      puts 'extra input arguments:'
      extra_input_arguments.sort.each do |extra_input_argument|
        puts "\t- #{extra_input_argument}"
      end
    end
    assert_equal(0, extra_input_arguments.size)

    missing_input_arguments = expected_input_names - actual_input_names
    if !missing_input_arguments.empty?
      puts 'missing input arguments:'
      missing_input_arguments.sort.each do |missing_input_argument|
        puts "\t- #{missing_input_argument}"
      end
    end
    assert_equal(0, missing_input_arguments.size)
  end

  def test_testing_annual_outputs
    expected_input_names = @expected_inputs['Input Name']
    expected_annual_names = @expected_outputs['Annual Name'].select { |n| !n.nil? }

    actual_outputs = CSV.read(File.join(@testing_baseline, 'results_csvs', 'results_up00.csv'), headers: true)
    actual_outputs.headers.map { |x| actual_outputs.delete(x) if x.include?('report_utility_bills.bills_2_') }
    actual_outputs.headers.map { |x| actual_outputs.delete(x) if x.include?('report_utility_bills.bills_3_') }
    actual_outputs.headers.map { |x| actual_outputs.delete(x) if x.include?('server_directory_cleanup.') }
    actual_annual_names = actual_outputs.headers - expected_input_names

    extra_annual_outputs = actual_annual_names - expected_annual_names
    if !extra_annual_outputs.empty?
      puts 'extra annual outputs:'
      extra_annual_outputs.sort.each do |extra_annual_output|
        puts "\t- #{extra_annual_output}"
      end
    end
    assert_equal(0, extra_annual_outputs.size)

    missing_annual_outputs = expected_annual_names - actual_annual_names
    if !missing_annual_outputs.empty?
      puts 'missing annual outputs:'
      missing_annual_outputs.sort.each do |missing_annual_output|
        puts "\t- #{missing_annual_output}"
      end
    end
    assert_equal(0, missing_annual_outputs.size)

    tol = 0.001
    sums_to_indexes = @expected_outputs['Sums To'].select { |n| !n.nil? }.uniq
    sums_to_indexes.each do |sums_to_ix|
      ix = @expected_outputs['Row Index'].index(sums_to_ix)
      sums_to = @expected_outputs['Annual Name'][ix]

      terms = []
      @expected_outputs['Sums To'].zip(@expected_outputs['Annual Name']).each do |ix, annual_name|
        terms << annual_name if ix == sums_to_ix
      end

      sums_to_val = actual_outputs[sums_to].map { |x| !x.nil? ? Float(x) : 0.0 }.sum
      terms_val = terms.collect { |t| actual_outputs[t].map { |x| !x.nil? ? Float(x) : 0.0 }.sum }.sum

      assert_in_epsilon(sums_to_val, terms_val, tol, "Summed value #{terms_val} does not equal #{sums_to} (#{sums_to_val})")
    end
  end

  def test_national_annual_outputs
    expected_input_names = @expected_inputs['Input Name']
    expected_annual_names = @expected_outputs['Annual Name'].select { |n| !n.nil? }

    actual_outputs = CSV.read(File.join(@national_baseline, 'results_csvs', 'results_up00.csv'), headers: true)
    actual_annual_names = actual_outputs.headers - expected_input_names

    extra_annual_outputs = actual_annual_names - expected_annual_names
    if !extra_annual_outputs.empty?
      puts 'extra annual outputs:'
      extra_annual_outputs.sort.each do |extra_annual_output|
        puts "\t- #{extra_annual_output}"
      end
    end
    assert_equal(0, extra_annual_outputs.size)

    missing_annual_outputs = expected_annual_names - actual_annual_names
    if !missing_annual_outputs.empty?
      puts 'missing annual outputs:'
      missing_annual_outputs.sort.each do |missing_annual_output|
        puts "\t- #{missing_annual_output}"
      end
    end
    # assert_equal(0, missing_annual_outputs.size) # Allow missing annual outputs for the national project (e.g., component loads, monthly bills).

    tol = 0.001
    sums_to_indexes = @expected_outputs['Sums To'].select { |n| !n.nil? }.uniq
    sums_to_indexes.each do |sums_to_ix|
      ix = @expected_outputs['Row Index'].index(sums_to_ix)
      sums_to = @expected_outputs['Annual Name'][ix]

      terms = []
      @expected_outputs['Sums To'].zip(@expected_outputs['Annual Name']).each do |ix, annual_name|
        terms << annual_name if ix == sums_to_ix
      end

      sums_to_val = actual_outputs[sums_to].map { |x| !x.nil? ? Float(x) : 0.0 }.sum
      terms_val = terms.collect { |t| actual_outputs[t].map { |x| !x.nil? ? Float(x) : 0.0 }.sum }.sum

      assert_in_epsilon(sums_to_val, terms_val, tol, "Summed value #{terms_val} does not equal #{sums_to} (#{sums_to_val})")
    end
  end

  def test_timeseries_resstock_outputs
    ts_col = 'Timeseries ResStock Name'

    @expected_outputs[ts_col] = _map_scenario_names(@expected_outputs[ts_col], 'Emissions: <type>: <scenario_name>', 'Emissions: CO2e: LRMER_MidCase_15')
    expected_timeseries_names = @expected_outputs[ts_col].select { |n| !n.nil? }

    actual_outputs = CSV.read(File.join('baseline', 'timeseries', 'results_output.csv'), headers: true)
    actual_timeseries_names = actual_outputs.headers

    extra_timeseries_outputs = actual_timeseries_names - expected_timeseries_names
    extra_timeseries_outputs -= ['PROJECT']
    if !extra_timeseries_outputs.empty?
      puts 'extra timeseries outputs:'
      extra_timeseries_outputs.sort.each do |extra_timeseries_output|
        puts "\t- #{extra_timeseries_output}"
      end
    end
    assert_equal(0, extra_timeseries_outputs.size)

    missing_timeseries_outputs = expected_timeseries_names - actual_timeseries_names
    if !missing_timeseries_outputs.empty?
      puts 'missing timeseries outputs:'
      missing_timeseries_outputs.sort.each do |missing_timeseries_output|
        puts "\t- #{missing_timeseries_output}"
      end
    end
    # assert_equal(0, missing_timeseries_outputs.size) # Allow missing timeseries outputs for the national project (e.g., Component Load: Cooling: Skylights Conduction, Fuel Use: Wood Pellets: Total).

    tol = 0.001
    sums_to_indexes = @expected_outputs['Sums To'].select { |n| !n.nil? }.uniq
    sums_to_indexes.each do |sums_to_ix|
      ix = @expected_outputs['Row Index'].index(sums_to_ix)
      sums_to = @expected_outputs[ts_col][ix]

      terms = []
      @expected_outputs['Sums To'].zip(@expected_outputs[ts_col]).each do |ix, annual_name|
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

    @expected_outputs[ts_col] = _map_scenario_names(@expected_outputs[ts_col], 'emissions__<type>__<scenario_name>', 'emissions__co2e__lrmer_midcase_15')
    expected_timeseries_names = @expected_outputs[ts_col].select { |n| !n.nil? }

    actual_outputs = CSV.read(File.join('baseline', 'timeseries', 'buildstockbatch.csv'), headers: true)
    actual_timeseries_names = actual_outputs.headers

    extra_timeseries_outputs = actual_timeseries_names - expected_timeseries_names
    extra_timeseries_outputs -= ['PROJECT']
    if !extra_timeseries_outputs.empty?
      puts 'extra timeseries outputs:'
      extra_timeseries_outputs.sort.each do |extra_timeseries_output|
        puts "\t- #{extra_timeseries_output}"
      end
    end
    assert_equal(0, extra_timeseries_outputs.size)

    missing_timeseries_outputs = expected_timeseries_names - actual_timeseries_names
    if !missing_timeseries_outputs.empty?
      puts 'missing timeseries outputs:'
      missing_timeseries_outputs.sort.each do |missing_timeseries_output|
        puts "\t- #{missing_timeseries_output}"
      end
    end
    # assert_equal(0, missing_timeseries_outputs.size) # Allow missing timeseries outputs for the national project (e.g., component_load__cooling__skylights_conduction__kbtu, fuel_use__wood_pellets__total__kbtu).

    tol = 0.001
    sums_to_indexes = @expected_outputs['Sums To'].select { |n| !n.nil? }.uniq
    sums_to_indexes.each do |sums_to_ix|
      ix = @expected_outputs['Row Index'].index(sums_to_ix)
      sums_to = @expected_outputs[ts_col][ix]

      terms = []
      @expected_outputs['Sums To'].zip(@expected_outputs[ts_col]).each do |ix, annual_name|
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
