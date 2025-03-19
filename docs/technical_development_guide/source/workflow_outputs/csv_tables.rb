# frozen_string_literal: true

require 'csv'

inputs = CSV.read(File.join(File.dirname(__FILE__), '../../../../resources/data/dictionary/inputs.csv'), headers: true)
outputs = CSV.read(File.join(File.dirname(__FILE__), '../../../../resources/data/dictionary/outputs.csv'), headers: true)

csv_tables = {
  'characteristics.csv' => { 'annual' => false, 'timeseries' => false, 'kws' => ['build_existing_model.'], 'usecols' => ['Input Name', 'Input Description'] },
  'other_outputs.csv' => { 'annual' => false, 'timeseries' => false, 'kws' => ['build_existing_model.'], 'usecols' => ['Input Name', 'Input Description'] },
  'simulation_outputs.csv' => { 'annual' => true, 'timeseries' => true, 'kws' => ['.end_use_', '.energy_use_', 'fuel_use_', '.hot_water_', '.hvac_capacity_', '.hvac_design_', '.load_', '.peak_', '.resilience_', '.unmet_hours_'], 'usecols' => ['Annual Name', 'Annual Units', 'Timeseries ResStock Name', 'Timeseries BuildStockBatch Name', 'Timeseries Units', 'Notes'] },
  'panel_outputs.csv' => { 'annual' => true, 'timeseries' => true, 'kws' => ['.electric_panel_'], 'usecols' => ['Annual Name', 'Annual Units', 'Notes'] },
  'cost_multipliers.csv' => { 'annual' => true, 'timeseries' => false, 'kws' => ['upgrade_costs.'], 'usecols' => ['Annual Name', 'Annual Units', 'Notes'] },
  'component_loads.csv' => { 'annual' => true, 'timeseries' => true, 'kws' => ['.component_load_'], 'usecols' => ['Annual Name', 'Annual Units', 'Timeseries ResStock Name', 'Timeseries BuildStockBatch Name', 'Timeseries Units', 'Notes'] },
  'emissions.csv' => { 'annual' => true, 'timeseries' => true, 'kws' => ['.emissions_'], 'usecols' => ['Annual Name', 'Annual Units', 'Timeseries ResStock Name', 'Timeseries BuildStockBatch Name', 'Timeseries Units', 'Notes'] },
  'utility_bills.csv' => { 'annual' => true, 'timeseries' => false, 'kws' => ['report_utility_bills.'], 'usecols' => ['Annual Name', 'Annual Units', 'Notes'] },
  'qoi_report.csv' => { 'annual' => true, 'timeseries' => false, 'kws' => ['qoi_report.'], 'usecols' => ['Annual Name', 'Annual Units', 'Notes'] },
  'other_timeseries.csv' => { 'annual' => false, 'timeseries' => true, 'kws' => [nil], 'usecols' => ['Timeseries ResStock Name', 'Timeseries BuildStockBatch Name', 'Timeseries Units', 'Notes'] }
}

csv_tables_dir = File.join(File.dirname(__FILE__), 'csv_tables')
Dir.mkdir(csv_tables_dir) if !File.exist?(csv_tables_dir)
csv_tables.each do |csv_file, table_info|
  annual = table_info['annual']
  timeseries = table_info['timeseries']
  kws = table_info['kws']
  usecols = table_info['usecols']

  csv_path = File.join(csv_tables_dir, csv_file)
  CSV.open(csv_path, 'wb') do |csv|
    csv << usecols
    rows = inputs
    rows = outputs if annual || timeseries
    rows.each do |row|
      if row['Annual Name'].nil?
        if row['Input Name'].nil?
          next if !kws.include?(nil)
        else
          next if row['Input Description'].include?(':ref:') && csv_file == 'other_outputs.csv'
          next if !row['Input Description'].include?(':ref:') && csv_file == 'characteristics.csv'
        end
      else
        next if kws.include?(nil)
        next if !kws.any? { |kw| row['Annual Name'].include?(kw) }
      end

      new_row = []
      usecols.each do |usecol|
        new_row << row[usecol]
      end
      csv << new_row
    end
  end
end
