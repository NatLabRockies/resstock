# frozen_string_literal: true

require 'csv'

def expected_baseline_columns
  return [
    'building_id',
    'job_id',
    'completed_status',
    'report_simulation_output.add_timeseries_dst_column',
    'report_simulation_output.add_timeseries_utc_column',
    'report_simulation_output.energy_use_total_m_btu',
    'report_simulation_output.energy_use_net_m_btu',
    'report_simulation_output.fuel_use_electricity_total_m_btu',
    'report_simulation_output.end_use_natural_gas_heating_m_btu',
    'report_simulation_output.emissions_co_2_e_lrmer_mid_case_15_total_lb',
    'upgrade_costs.door_area_ft_2',
    'qoi_report.qoi_average_maximum_daily_timing_cooling_hour'
  ]
end

def expected_baseline_nonnull_columns
  return [
    'report_simulation_output.energy_use_net_m_btu',
    'upgrade_costs.door_area_ft_2'
  ]
end

def expected_baseline_nonzero_columns
  return [
    'report_simulation_output.energy_use_total_m_btu'
  ]
end

def expected_baseline_contents(testing)
  contents = [
    'data_point_out.json',
    'home.xml',
    'results_timeseries.csv'
  ]
  contents += [
    'existing.osw',
    'existing.xml',
    'in.osm',
    'in.idf'
  ] if testing
  return contents
end

def expected_timeseries_columns(testing)
  contents = [
    'TimeDST',
    'TimeUTC',
    'Energy Use: Total',
    'Fuel Use: Electricity: Total',
    'Emissions: CO2e: LRMER_MidCase_15: Total'
  ]
  contents += [
    'Energy Use: Net',
  ] if testing
  return contents
end

def _test_columns(results)
  assert(!results.empty?)
  assert(_test_baseline_columns(results))
  assert(_test_nonnull_columns(results))
  assert(_test_nonzero_columns(results))
end

def _test_contents(contents, testing = false)
  assert(_test_baseline_contents(contents, testing))
end

def _test_baseline_columns(results)
  expected_columns = expected_baseline_columns

  return true if (expected_columns - results.headers).empty?

  return false
end

def _test_nonnull_columns(results)
  expected_columns = expected_baseline_nonnull_columns

  result = true
  expected_columns.each do |col|
    next if !results.headers.include?(col)

    result = false if results[col].all? { |i| i.nil? }
  end
  return result
end

def _test_nonzero_columns(results)
  expected_columns = expected_baseline_nonzero_columns

  result = true
  expected_columns.each do |col|
    next if !results.headers.include?(col)

    result = false if results[col].all? { |i| i == 0 }
  end
  return result
end

def _test_baseline_contents(actual_contents, testing = false)
  expected_contents = expected_baseline_contents(testing)

  expected_extras = expected_contents - actual_contents
  return true if expected_extras.empty?

  puts "Baseline Contents, expected - actual: #{expected_extras}"
  return false
end

def _test_timeseries_columns(actual_columns, testing = false)
  expected_columns = expected_timeseries_columns(testing)

  expected_extras = expected_columns - actual_columns
  return true if expected_extras.empty?

  puts "Timeseries Name, expected - actual: #{expected_extras}"
  return false
end

def _get_timeseries_columns(paths)
  timeseries = []
  paths.each do |path|
    headers = CSV.foreach(path).first
    headers.each do |column|
      timeseries << column if !timeseries.include?(column)
    end
  end
  return timeseries
end
