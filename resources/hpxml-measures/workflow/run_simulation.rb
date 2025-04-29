# frozen_string_literal: true

start_time = Time.now

require 'fileutils'
require 'optparse'
require 'pathname'
require_relative '../HPXMLtoOpenStudio/resources/constants'
require_relative '../HPXMLtoOpenStudio/resources/meta_measure'
require_relative '../HPXMLtoOpenStudio/resources/version'

basedir = File.expand_path(File.dirname(__FILE__))

$timeseries_types = ['ALL', 'total', 'fuels', 'enduses', 'systemuses', 'emissions', 'emissionfuels',
                     'emissionenduses', 'hotwater', 'loads', 'componentloads',
                     'unmethours', 'temperatures', 'conditions', 'airflows', 'weather', 'resilience']

def run_workflow(basedir, rundir, hpxml, debug, skip_validation, add_comp_loads,
                 output_format, building_id, ep_input_format, stochastic_schedules,
                 hourly_outputs, daily_outputs, monthly_outputs, timestep_outputs,
                 skip_simulation, master_seed)

  measures_dir = File.join(basedir, '..')
  measures = {}

  # Optionally add schedule file measure to workflow
  if stochastic_schedules
    measure_subdir = 'BuildResidentialScheduleFile'
    args = {}
    args['hpxml_path'] = hpxml
    args['hpxml_output_path'] = hpxml
    args['output_csv_path'] = File.join(rundir, 'stochastic.csv')
    args['debug'] = debug
    args['building_id'] = building_id
    args['schedules_random_seed'] = master_seed
    measures[measure_subdir] = [args]
  end

  # Add HPXML translator measure to workflow
  measure_subdir = 'HPXMLtoOpenStudio'
  args = {}
  args['hpxml_path'] = hpxml
  args['output_dir'] = rundir
  args['output_format'] = (output_format == 'csv_dview' ? 'csv' : output_format)
  args['add_component_loads'] = (add_comp_loads || (hourly_outputs + daily_outputs + monthly_outputs + timestep_outputs).include?('componentloads'))
  args['skip_validation'] = skip_validation
  args['building_id'] = building_id
  args['debug'] = debug
  measures[measure_subdir] = [args]

  if not skip_simulation
    n_timeseries_freqs = [hourly_outputs, daily_outputs, monthly_outputs, timestep_outputs].map { |o| !o.empty? }.count(true)

    { 'none' => [],
      'hourly' => hourly_outputs,
      'daily' => daily_outputs,
      'monthly' => monthly_outputs,
      'timestep' => timestep_outputs }.each do |timeseries_output_freq, timeseries_outputs|
      next if (timeseries_outputs.empty? && timeseries_output_freq != 'none')

      comma_output = timeseries_outputs.find { |o| o.include? ',' }
      if not comma_output.nil?
        fail "Timeseries output request '#{comma_output}' cannot include a comma."
      end

      if timeseries_outputs.include? 'ALL'
        # Replace 'ALL' with all individual timeseries types
        timeseries_outputs.delete('ALL')
        $timeseries_types.each do |timeseries_type|
          timeseries_outputs << timeseries_type
        end
      end

      # Add reporting measure to workflow
      measure_subdir = 'ReportSimulationOutput'
      args = {}
      args['output_format'] = output_format
      args['timeseries_frequency'] = timeseries_output_freq
      args['include_timeseries_total_consumptions'] = timeseries_outputs.include? 'total'
      args['include_timeseries_fuel_consumptions'] = timeseries_outputs.include? 'fuels'
      args['include_timeseries_end_use_consumptions'] = timeseries_outputs.include? 'enduses'
      args['include_timeseries_system_use_consumptions'] = timeseries_outputs.include? 'systemuses'
      args['include_timeseries_emissions'] = timeseries_outputs.include? 'emissions'
      args['include_timeseries_emission_fuels'] = timeseries_outputs.include? 'emissionfuels'
      args['include_timeseries_emission_end_uses'] = timeseries_outputs.include? 'emissionenduses'
      args['include_timeseries_hot_water_uses'] = timeseries_outputs.include? 'hotwater'
      args['include_timeseries_total_loads'] = timeseries_outputs.include? 'loads'
      args['include_timeseries_component_loads'] = timeseries_outputs.include? 'componentloads'
      args['include_timeseries_unmet_hours'] = timeseries_outputs.include? 'unmethours'
      args['include_timeseries_zone_temperatures'] = timeseries_outputs.include? 'temperatures'
      args['include_timeseries_zone_conditions'] = timeseries_outputs.include? 'conditions'
      args['include_timeseries_airflows'] = timeseries_outputs.include? 'airflows'
      args['include_timeseries_weather'] = timeseries_outputs.include? 'weather'
      args['include_timeseries_resilience'] = timeseries_outputs.include? 'resilience'
      remaining_outputs = timeseries_outputs - $timeseries_types
      output_variables = remaining_outputs.select { |o| !o.include?(':') }
      output_meters = remaining_outputs.select { |o| o.include?(':') }
      args['user_output_variables'] = output_variables.join(', ') unless output_variables.empty?
      args['user_output_meters'] = output_meters.join(', ') unless output_meters.empty?
      if n_timeseries_freqs > 1
        # Need to use different timeseries filenames
        args['timeseries_output_file_name'] = "results_timeseries_#{timeseries_output_freq}.#{output_format}"
      end
      measures[measure_subdir] = [] if not measures.has_key?(measure_subdir)
      measures[measure_subdir] << args
    end

    # Add utility bills measure to workflow
    measure_subdir = 'ReportUtilityBills'
    args = {}
    args['output_format'] = (output_format == 'csv_dview' ? 'csv' : output_format)
    measures[measure_subdir] = [args]
  end

  results = run_hpxml_workflow(rundir, measures, measures_dir, debug: debug, ep_input_format: ep_input_format, run_measures_only: skip_simulation)

  return results[:success]
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} -x building.xml [OPTIONS]"

  opts.on('-x', '--xml <FILE>', 'HPXML file') do |t|
    options[:hpxml] = t
  end

  opts.on('-o', '--output-dir <DIR>', 'Output directory') do |t|
    options[:output_dir] = t
  end

  options[:output_format] = 'csv'
  opts.on('--output-format TYPE', ['csv', 'json', 'msgpack', 'csv_dview'], 'Output file format type (csv, json, msgpack, csv_dview)') do |t|
    options[:output_format] = t
  end

  options[:hourly_outputs] = []
  opts.on('--hourly NAME', 'Request hourly output category* or EnergyPlus output variable/meter; can be called multiple times') do |t|
    options[:hourly_outputs] << t
  end

  options[:daily_outputs] = []
  opts.on('--daily NAME', 'Request daily output category* or EnergyPlus output variable/meter; can be called multiple times') do |t|
    options[:daily_outputs] << t
  end

  options[:monthly_outputs] = []
  opts.on('--monthly NAME', 'Request monthly output category* or EnergyPlus output variable/meter; can be called multiple times') do |t|
    options[:monthly_outputs] << t
  end

  options[:timestep_outputs] = []
  opts.on('--timestep NAME', 'Request timestep output category* or EnergyPlus output variable/meter; can be called multiple times') do |t|
    options[:timestep_outputs] << t
  end

  options[:skip_simulation] = false
  opts.on('--skip-simulation', 'Skip the EnergyPlus simulation') do |_t|
    options[:skip_simulation] = true
  end

  options[:skip_validation] = false
  opts.on('-s', '--skip-validation', 'Skip Schema/Schematron validation for faster performance') do |_t|
    options[:skip_validation] = true
  end

  options[:add_comp_loads] = false
  opts.on('--add-component-loads', 'Add heating/cooling component loads calculation') do |_t|
    options[:add_comp_loads] = true
  end

  options[:stochastic_schedules] = false
  opts.on('--add-stochastic-schedules', 'Add detailed stochastic occupancy schedules') do |_t|
    options[:stochastic_schedules] = true
  end

  options[:master_seed] = nil
  opts.on('--master-seed SEED', Integer, 'Master seed for stochastic occupancy schedule random number generator') do |t|
    options[:master_seed] = t
  end

  options[:ep_input_format] = 'idf'
  opts.on('--ep-input-format TYPE', 'EnergyPlus input file format (idf, epjson)') do |t|
    options[:ep_input_format] = t
  end

  opts.on('-b', '--building-id ID', 'ID of HPXML Building to simulate') do |t|
    options[:building_id] = t
  end

  options[:version] = false
  opts.on('-v', '--version', 'Reports the version') do |_t|
    options[:version] = true
  end

  options[:debug] = false
  opts.on('-d', '--debug', 'Generate additional OpenStudio and EnergyPlus files for debugging') do |_t|
    options[:debug] = true
  end

  opts.on_tail('-h', '--help', 'Display help') do
    puts opts
    exit!
  end

  opts.on_tail("* Valid output categories are: #{$timeseries_types.join(', ')}")
end.parse!

if options[:version]
  puts "OpenStudio-HPXML v#{Version::OS_HPXML_Version}"
  puts "HPXML v#{Version::HPXML_Version}"
  puts "OpenStudio v#{OpenStudio.openStudioLongVersion}"
  puts "EnergyPlus v#{OpenStudio.energyPlusVersion}.#{OpenStudio.energyPlusBuildSHA}"
else
  if not options[:hpxml]
    fail "HPXML argument is required. Call #{File.basename(__FILE__)} -h for usage."
  end

  unless (Pathname.new options[:hpxml]).absolute?
    options[:hpxml] = File.expand_path(options[:hpxml])
  end
  unless File.exist?(options[:hpxml]) && options[:hpxml].downcase.end_with?('.xml')
    fail "'#{options[:hpxml]}' does not exist or is not an .xml file."
  end

  if options[:output_dir].nil?
    options[:output_dir] = File.dirname(options[:hpxml]) # default
  end
  options[:output_dir] = File.expand_path(options[:output_dir])

  unless Dir.exist?(options[:output_dir])
    FileUtils.mkdir_p(options[:output_dir])
  end

  # Create run dir
  rundir = File.join(options[:output_dir], 'run')

  # Run design
  puts "HPXML: #{options[:hpxml]}"
  if not options[:building_id].nil?
    puts "BuildingID: #{options[:building_id]}"
  end
  success = run_workflow(basedir, rundir, options[:hpxml], options[:debug], options[:skip_validation], options[:add_comp_loads],
                         options[:output_format], options[:building_id], options[:ep_input_format], options[:stochastic_schedules],
                         options[:hourly_outputs], options[:daily_outputs], options[:monthly_outputs], options[:timestep_outputs],
                         options[:skip_simulation], options[:master_seed])

  if not success
    exit! 1
  end

  puts "Completed in #{(Time.now - start_time).round(1)}s."
end
