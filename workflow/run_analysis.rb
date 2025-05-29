# frozen_string_literal: true

require 'json'
require 'optparse'
require 'parallel'
require 'pathname'
require 'time'
require 'yaml'
require 'zlib'

require_relative '../resources/buildstock'
require_relative '../resources/run_sampling_lib'
require_relative '../resources/hpxml-measures/HPXMLtoOpenStudio/resources/util'

$start_time = Time.now

def run_workflow(yml, in_threads, measures_only, debug_arg, overwrite, building_ids, upgrade_names, keep_run_folders, samplingonly)
  if !File.exist?(yml)
    puts "Error: YML file does not exist at '#{yml}'."
    return false
  end

  cfg = YAML.load_file(yml, aliases: true)

  if !cfg['workflow_generator']['args'].keys.include?('build_existing_model') || !cfg['workflow_generator']['args'].keys.include?('simulation_output_report')
    puts "Error: Both 'build_existing_model' and 'simulation_output_report' must be included in yml."
    return false
  end

  if !['residential_quota', 'residential_quota_downselect', 'precomputed'].include?(cfg['sampler']['type'])
    puts "Error: Sampler type '#{cfg['sampler']['type']}' is invalid or not supported."
    return false
  end

  if cfg['sampler']['type'] == 'residential_quota_downselect' && cfg['sampler']['args']['resample']
    puts "Error: Not supporting residential_quota_downselect's 'resample' at this time."
    return false
  end

  cfg_upgrade_names = ['Baseline']
  cfg_upgrade_names += cfg['upgrades'].collect { |u| u['upgrade_name'] } if cfg.keys.include?('upgrades')

  invalid_upgrade_names = upgrade_names - cfg_upgrade_names
  if !invalid_upgrade_names.empty?
    puts "Error: At least one invalid upgrade_name was specified: #{invalid_upgrade_names.join(', ')}. Valid choices are: #{cfg_upgrade_names.join(', ')}."
    return false
  end

  if upgrade_names.empty?
    upgrades = cfg_upgrade_names
  else
    upgrades = upgrade_names
  end
  upgrades = upgrades.map { |u| u.gsub(/[^0-9A-Za-z]/, '') }

  thisdir = File.dirname(__FILE__)

  project_directory = cfg['project_directory']
  output_directory = cfg['output_directory']
  n_datapoints = cfg['sampler']['args']['n_datapoints']

  if (Pathname.new output_directory).absolute?
    results_dir = output_directory
  else
    results_dir = File.absolute_path(output_directory)
  end
  FileUtils.rm_rf(results_dir) if overwrite
  if File.exist?(results_dir)
    puts "Error: Output directory '#{output_directory}' already exists."
    return false
  end

  Dir.mkdir(results_dir)

  # Create or read buildstock.csv
  if !['precomputed'].include?(cfg['sampler']['type'])
    buildstock_csv_path = File.join(results_dir, 'buildstock.csv')
    create_buildstock_csv(project_directory, n_datapoints, buildstock_csv_path)
    return if samplingonly

    datapoints = (1..n_datapoints).to_a
  else
    buildstock_csv_path = cfg['sampler']['args']['sample_file']
    unless (Pathname.new buildstock_csv_path).absolute?
      buildstock_csv_path = File.expand_path(File.join(File.dirname(yml), buildstock_csv_path))
    end

    buildstock_csv = CSV.read(buildstock_csv_path, headers: true)
    datapoints = buildstock_csv['Building'].map { |x| Integer(x) }
    n_datapoints = datapoints.size
  end

  osw_dir = File.join(results_dir, 'osw')
  Dir.mkdir(osw_dir)

  xml_dir = File.join(results_dir, 'xml')
  Dir.mkdir(xml_dir)

  workflow_args = { 'build_existing_model' => {},
                    'measures' => [],
                    'simulation_output_report' => {},
                    'server_directory_cleanup' => {} }
  workflow_args.update(cfg['workflow_generator']['args'])

  sim_ctl_args = {
    'simulation_control_timestep' => 60,
    'simulation_control_run_period_begin_month' => 1,
    'simulation_control_run_period_begin_day_of_month' => 1,
    'simulation_control_run_period_end_month' => 12,
    'simulation_control_run_period_end_day_of_month' => 31,
    'simulation_control_run_period_calendar_year' => 2007,
    'add_component_loads' => false
  }

  bld_exist_model_args = {
    'buildstock_csv_path': buildstock_csv_path,
    'building_id': '',
    'project_directory': project_directory,
    'sample_weight': Float(cfg['baseline']['n_buildings_represented']) / n_datapoints # aligns with buildstockbatch
  }

  bld_exist_model_args.update(sim_ctl_args)
  bld_exist_model_args.update(workflow_args['build_existing_model'])

  add_component_loads = false
  if bld_exist_model_args.keys.include?('add_component_loads')
    add_component_loads = bld_exist_model_args['add_component_loads']
    bld_exist_model_args.delete('add_component_loads')
  end

  if workflow_args.keys.include?('emissions')
    emissions = workflow_args['emissions']
    bld_exist_model_args['emissions_scenario_names'] = emissions.collect { |s| s['scenario_name'] }.join(',')
    bld_exist_model_args['emissions_types'] = emissions.collect { |s| s['type'] }.join(',')
    bld_exist_model_args['emissions_electricity_folders'] = emissions.collect { |s| s['elec_folder'] }.join(',')
    bld_exist_model_args['emissions_natural_gas_values'] = emissions.collect { |s| s['gas_value'] }.join(',')
    bld_exist_model_args['emissions_propane_values'] = emissions.collect { |s| s['propane_value'] }.join(',')
    bld_exist_model_args['emissions_fuel_oil_values'] = emissions.collect { |s| s['oil_value'] }.join(',')
    bld_exist_model_args['emissions_wood_values'] = emissions.collect { |s| s['wood_value'] }.join(',')
  end

  if workflow_args.keys.include?('utility_bills')
    utility_bills = workflow_args['utility_bills']
    bld_exist_model_args['utility_bill_scenario_names'] = utility_bills.collect { |s| s['scenario_name'] }.join(',')
    bld_exist_model_args['utility_bill_simple_filepaths'] = utility_bills.collect { |s| s['simple_filepath'] }.join(',')
    bld_exist_model_args['utility_bill_detailed_filepaths'] = utility_bills.collect { |s| s['detailed_filepath'] }.join(',')
    bld_exist_model_args['utility_bill_electricity_fixed_charges'] = utility_bills.collect { |s| s['elec_fixed_charge'] }.join(',')
    bld_exist_model_args['utility_bill_electricity_marginal_rates'] = utility_bills.collect { |s| s['elec_marginal_rate'] }.join(',')
    bld_exist_model_args['utility_bill_natural_gas_fixed_charges'] = utility_bills.collect { |s| s['gas_fixed_charge'] }.join(',')
    bld_exist_model_args['utility_bill_natural_gas_marginal_rates'] = utility_bills.collect { |s| s['gas_marginal_rate'] }.join(',')
    bld_exist_model_args['utility_bill_propane_fixed_charges'] = utility_bills.collect { |s| s['propane_fixed_charge'] }.join(',')
    bld_exist_model_args['utility_bill_propane_marginal_rates'] = utility_bills.collect { |s| s['propane_marginal_rate'] }.join(',')
    bld_exist_model_args['utility_bill_fuel_oil_fixed_charges'] = utility_bills.collect { |s| s['oil_fixed_charge'] }.join(',')
    bld_exist_model_args['utility_bill_fuel_oil_marginal_rates'] = utility_bills.collect { |s| s['oil_marginal_rate'] }.join(',')
    bld_exist_model_args['utility_bill_wood_fixed_charges'] = utility_bills.collect { |s| s['wood_fixed_charge'] }.join(',')
    bld_exist_model_args['utility_bill_wood_marginal_rates'] = utility_bills.collect { |s| s['wood_marginal_rate'] }.join(',')
    bld_exist_model_args['utility_bill_pv_compensation_types'] = utility_bills.collect { |s| s['pv_compensation_type'] }.join(',')
    bld_exist_model_args['utility_bill_pv_net_metering_annual_excess_sellback_rate_types'] = utility_bills.collect { |s| s['pv_net_metering_annual_excess_sellback_rate_type'] }.join(',')
    bld_exist_model_args['utility_bill_pv_net_metering_annual_excess_sellback_rates'] = utility_bills.collect { |s| s['pv_net_metering_annual_excess_sellback_rate'] }.join(',')
    bld_exist_model_args['utility_bill_pv_feed_in_tariff_rates'] = utility_bills.collect { |s| s['pv_feed_in_tariff_rate'] }.join(',')
    bld_exist_model_args['utility_bill_pv_monthly_grid_connection_fee_units'] = utility_bills.collect { |s| s['pv_monthly_grid_connection_fee_units'] }.join(',')
    bld_exist_model_args['utility_bill_pv_monthly_grid_connection_fees'] = utility_bills.collect { |s| s['pv_monthly_grid_connection_fee'] }.join(',')
  end

  if cfg['sampler']['type'] == 'residential_quota_downselect'
    bld_exist_model_args['downselect_logic'] = make_apply_logic_arg(cfg['sampler']['args']['logic'])
  end

  sim_out_rep_args = {
    'output_format' => 'csv',
    'include_annual_total_consumptions' => true,
    'include_annual_fuel_consumptions' => true,
    'include_annual_end_use_consumptions' => true,
    'include_annual_system_use_consumptions' => false,
    'include_annual_emissions' => true,
    'include_annual_emission_fuels' => true,
    'include_annual_emission_end_uses' => true,
    'include_annual_total_loads' => true,
    'include_annual_unmet_hours' => true,
    'include_annual_peak_fuels' => true,
    'include_annual_peak_loads' => true,
    'include_annual_component_loads' => true,
    'include_annual_hot_water_uses' => true,
    'include_annual_hvac_summary' => true,
    'include_annual_resilience' => true,
    'timeseries_frequency' => 'none',
    'include_timeseries_total_consumptions' => false,
    'include_timeseries_fuel_consumptions' => false,
    'include_timeseries_end_use_consumptions' => true,
    'include_timeseries_system_use_consumptions' => false,
    'include_timeseries_emissions' => false,
    'include_timeseries_emission_fuels' => false,
    'include_timeseries_emission_end_uses' => false,
    'include_timeseries_hot_water_uses' => false,
    'include_timeseries_total_loads' => true,
    'include_timeseries_component_loads' => false,
    'include_timeseries_unmet_hours' => false,
    'include_timeseries_zone_temperatures' => false,
    'include_timeseries_zone_conditions' => false,
    'include_timeseries_airflows' => false,
    'include_timeseries_weather' => false,
    'include_timeseries_resilience' => false,
    'timeseries_timestamp_convention' => 'end',
    'timeseries_num_decimal_places' => 3,
    'add_timeseries_dst_column' => true,
    'add_timeseries_utc_column' => true,
    'user_output_variables' => '',
    'user_output_meters' => ''
  }
  sim_out_rep_args.update(workflow_args['simulation_output_report'])

  if sim_out_rep_args.keys.include?('output_variables')
    output_variables = sim_out_rep_args['output_variables']
    sim_out_rep_args['user_output_variables'] = output_variables.collect { |o| o['name'] }.join(',')
    sim_out_rep_args.delete('output_variables')
  end

  if sim_out_rep_args.keys.include?('output_meters')
    output_meters = sim_out_rep_args['output_meters']
    sim_out_rep_args['user_output_meters'] = output_meters.collect { |o| o['name'] }.join(',')
    sim_out_rep_args.delete('output_meters')
  end

  include_annual_bills = false
  include_monthly_bills = false
  register_annual_bills = true
  register_monthly_bills = false
  if sim_out_rep_args.keys.include?('include_annual_bills')
    register_annual_bills = sim_out_rep_args['include_annual_bills']
    sim_out_rep_args.delete('include_annual_bills')
  end
  if sim_out_rep_args.keys.include?('include_monthly_bills')
    register_monthly_bills = sim_out_rep_args['include_monthly_bills']
    sim_out_rep_args.delete('include_monthly_bills')
  end

  osw_paths = {}
  upgrades.each do |upgrade_name|
    scenario_osw_dir = File.join(results_dir, 'osw', upgrade_name)
    Dir.mkdir(scenario_osw_dir)

    scenario_xml_dir = File.join(results_dir, 'xml', upgrade_name)
    Dir.mkdir(scenario_xml_dir)

    osw = {
      'steps' => [
        {
          'measure_dir_name' => 'BuildExistingModel',
          'arguments' => bld_exist_model_args
        }
      ],
      'created_at' => Time.now.strftime('%Y-%m-%dT%H:%M:%S'),
      'measure_paths' => [
        File.absolute_path(File.join(File.dirname(__FILE__), '../measures')),
        File.absolute_path(File.join(File.dirname(__FILE__), '../resources/hpxml-measures'))
      ],
      'run_options' => {
        'skip_zip_results' => true
      }
    }

    debug = false
    if workflow_args.keys.include?('debug')
      debug = workflow_args['debug']
    end

    server_dir_cleanup_args = {
      'retain_in_osm' => false,
      'retain_in_idf' => true,
      'retain_pre_process_idf' => false,
      'retain_eplusout_audit' => false,
      'retain_eplusout_bnd' => false,
      'retain_eplusout_eio' => false,
      'retain_eplusout_end' => false,
      'retain_eplusout_err' => false,
      'retain_eplusout_eso' => false,
      'retain_eplusout_mdd' => false,
      'retain_eplusout_mtd' => false,
      'retain_eplusout_rdd' => false,
      'retain_eplusout_shd' => false,
      'retain_eplusout_msgpack' => false,
      'retain_eplustbl_htm' => false,
      'retain_stdout_energyplus' => false,
      'retain_stdout_expandobject' => false,
      'retain_schedules_csv' => true,
      'debug' => debug
    }
    server_dir_cleanup_args.update(workflow_args['server_directory_cleanup'])

    osw['steps'] += [
      {
        'measure_dir_name' => 'HPXMLtoOpenStudio',
        'arguments' => {
          'hpxml_path' => '',
          'output_dir' => '',
          'debug' => debug,
          'add_component_loads' => add_component_loads,
          'skip_validation' => true
        }
      },
      {
        'measure_dir_name' => 'UpgradeCosts',
        'arguments' => { 'debug' => debug }
      }
    ]

    osw['steps'] += workflow_args['measures']

    osw['steps'] += [
      {
        'measure_dir_name' => 'ReportSimulationOutput',
        'arguments' => sim_out_rep_args
      },
      {
        'measure_dir_name' => 'ReportUtilityBills',
        'arguments' => { 'output_format' => 'csv',
                         'include_annual_bills' => include_annual_bills,
                         'include_monthly_bills' => include_monthly_bills,
                         'register_annual_bills' => register_annual_bills,
                         'register_monthly_bills' => register_monthly_bills }
      },
      {
        'measure_dir_name' => 'ServerDirectoryCleanup',
        'arguments' => server_dir_cleanup_args
      }
    ]

    if upgrade_name != 'Baseline'
      apply_upgrade_measure = { 'measure_dir_name' => 'ApplyUpgrade',
                                'arguments' => { 'run_measure' => 1,
                                                 'project_directory': project_directory } }
      measure_d = cfg['upgrades'].find { |u| u['upgrade_name'].gsub(/[^0-9A-Za-z]/, '') == upgrade_name }
      apply_upgrade_measure['arguments']['upgrade_name'] = measure_d['upgrade_name']
      measure_d['options'].each_with_index do |option, opt_num|
        opt_num += 1
        apply_upgrade_measure['arguments']["option_#{opt_num}"] = option['option']
        if option.include?('lifetime')
          apply_upgrade_measure['arguments']["option_#{opt_num}_lifetime"] = option['lifetime']
        end
        if option.include?('apply_logic')
          apply_upgrade_measure['arguments']["option_#{opt_num}_apply_logic"] = make_apply_logic_arg(option['apply_logic'])
        end
        next unless option.keys.include?('costs')

        option['costs'].each_with_index do |cost, cost_num|
          cost_num += 1
          ['value', 'multiplier'].each do |arg|
            next if !cost.include?(arg)

            apply_upgrade_measure['arguments']["option_#{opt_num}_cost_#{cost_num}_#{arg}"] = cost[arg]
          end
        end
      end
      if measure_d.keys.include?('package_apply_logic')
        apply_upgrade_measure['arguments']['package_apply_logic'] = make_apply_logic_arg(measure_d['package_apply_logic'])
      end

      build_existing_model_idx = osw['steps'].index { |s| s['measure_dir_name'] == 'BuildExistingModel' }
      osw['steps'].insert(build_existing_model_idx + 1, apply_upgrade_measure)
    end

    if workflow_args.keys.include?('reporting_measures')
      workflow_args['reporting_measures'].each do |reporting_measure|
        if !reporting_measure.keys.include?('arguments')
          reporting_measure['arguments'] = {}
        end
        reporting_measure['measure_type'] = 'ReportingMeasure'
        osw['steps'].insert(-2, reporting_measure) # right before ServerDirectoryCleanup
      end
    end

    base, _ext = File.basename(yml).split('.')

    osw_paths[upgrade_name] = File.join(results_dir, "#{base}-#{upgrade_name}.osw")
    File.open(osw_paths[upgrade_name], 'w') do |f|
      f.write(JSON.pretty_generate(osw))
    end
  end # end upgrades.each do |upgrade_name|

  measures = []
  cfg['workflow_generator']['args'].keys.each do |wfg_arg|
    next unless ['measures'].include?(wfg_arg)

    cfg['workflow_generator']['args']['measures'].each do |k|
      measures << k['measure_dir_name']
    end
  end

  reporting_measures = []
  cfg['workflow_generator']['args'].keys.each do |wfg_arg|
    next unless ['reporting_measures'].include?(wfg_arg)

    cfg['workflow_generator']['args']['reporting_measures'].each do |k|
      reporting_measures << k['measure_dir_name']
    end
  end

  # Create weather folder
  weather_dir = File.join(thisdir, '../weather')

  if File.exist?(weather_dir) && Dir[File.join(weather_dir, '*.epw')].empty?
    FileUtils.rm_rf(weather_dir)
  end

  if !File.exist?(weather_dir)
    if cfg.keys.include?('weather_files_url')
      Dir.mkdir(weather_dir)

      require 'tempfile'
      tmpfile = Tempfile.new('epw')

      weather_files_url = cfg['weather_files_url']
      UrlResolver.fetch(weather_files_url, tmpfile)

      weather_files_path = tmpfile.path.to_s
    elsif cfg.keys.include?('weather_files_path')
      Dir.mkdir(weather_dir)

      weather_files_path = cfg['weather_files_path']

      if !(Pathname.new weather_files_path).absolute?
        weather_files_path = File.absolute_path(File.join(File.dirname(yml), weather_files_path))
      end
    else
      puts "Error: Must include 'weather_files_url' or 'weather_files_path' in yml."
      return false
    end

    puts 'Extracting weather files...'
    require 'zip'
    Zip.on_exists_proc = true
    Zip::File.open(weather_files_path) do |zip_file|
      zip_file.each do |f|
        fpath = File.join(weather_dir, f.name)
        zip_file.extract(f, fpath) unless File.exist?(fpath)
      end
    end
  end

  building_ids = datapoints if building_ids.empty?

  workflow_and_building_ids = []
  osw_paths.each do |upgrade_name, osw_path|
    datapoints.each do |building_id|
      next if !building_ids.include?(building_id)

      workflow_and_building_ids << [upgrade_name, osw_path, building_id]
    end
  end

  all_results_output = {}
  all_cli_output = []

  Parallel.map(workflow_and_building_ids, in_threads: in_threads) do |upgrade_name, workflow, building_id|
    job_id = Parallel.worker_number + 1
    if keep_run_folders
      folder_id = workflow_and_building_ids.index([upgrade_name, workflow, building_id]) + 1
    else
      folder_id = job_id
    end

    all_results_output[upgrade_name] = [] if !all_results_output.keys.include?(upgrade_name)
    samples_osw(results_dir, upgrade_name, workflow, building_id, job_id, folder_id, all_results_output, all_cli_output, measures, reporting_measures, measures_only, debug_arg, keep_run_folders)

    info = "[Parallel(n_jobs=#{in_threads})]: "
    max_size = "#{workflow_and_building_ids.size}".size
    info += "%#{max_size}s" % "#{all_results_output.values.flatten.size}"
    info += " / #{workflow_and_building_ids.size}"
    info += ' | elapsed: '
    info += '%8s' % "#{get_elapsed_time(Time.now, $start_time)}"
    puts info
  end

  puts
  failures = []
  all_results_output.each do |upgrade_name, results_output|
    RunOSWs.write_summary_results(results_dir, "results-#{upgrade_name}.csv", results_output)

    results_output.each do |results|
      failures << results['building_id'] if results['completed_status'] == 'Fail'
    end
  end
  puts "\nFailures detected for: #{failures.uniq.sort.join(', ')}.\nSee #{File.join(results_dir, 'cli_output.log')}." if !failures.empty?

  File.open(File.join(results_dir, 'cli_output.log'), 'a') do |f|
    all_cli_output.each do |cli_output|
      f.puts(cli_output)
      f.puts
    end
  end

  return true
end

def create_buildstock_csv(project_dir, num_samples, outfile)
  r = RunSampling.new
  r.run(project_dir, num_samples, outfile)
  puts "Sampling took: #{get_elapsed_time(Time.now, $start_time)}."
end

def get_elapsed_time(t1, t0)
  s = t1 - t0
  if s > 60 # min
    t = "#{(s / 60).round(1)}min"
  elsif s > 3600 # hr
    t = "#{(s / 3600).round(1)}hr"
  else # sec
    t = "#{s.round(1)}s"
  end
  return t
end

def samples_osw(results_dir, upgrade_name, workflow, building_id, job_id, folder_id, all_results_output, all_cli_output, measures, reporting_measures, measures_only, debug, keep_run_folders)
  scenario_osw_dir = File.join(results_dir, 'osw', upgrade_name)
  scenario_xml_dir = File.join(results_dir, 'xml', upgrade_name)

  worker_folder = "run#{folder_id}"
  worker_dir = File.join(results_dir, worker_folder)
  FileUtils.rm_rf(worker_dir)
  Dir.mkdir(worker_dir)
  FileUtils.cp(workflow, worker_dir)
  osw = File.join(worker_dir, File.basename(workflow))

  output_dir = File.join(worker_dir, 'run')
  hpxml_path = File.join(output_dir, 'home.xml')
  change_arguments(osw, building_id, hpxml_path, output_dir)

  worker_folder_ = job_id
  worker_folder_ = worker_folder if keep_run_folders
  run_output = "Building ID: #{building_id}. Upgrade Name: #{upgrade_name}. Job ID: #{worker_folder_}\n"
  upgrade = upgrade_name != 'Baseline'
  started_at, completed_at, completed_status, result_output, run_output = RunOSWs.run(osw, worker_dir, run_output, upgrade, measures, reporting_measures, measures_only)

  started_at = create_timestamp(started_at)
  completed_at = create_timestamp(completed_at)

  result_output['building_id'] = building_id
  result_output['job_id'] = worker_folder_
  result_output['started_at'] = started_at
  result_output['completed_at'] = completed_at
  result_output['completed_status'] = completed_status

  clean_up_result_output(result_output, upgrade)

  all_results_output[upgrade_name] << result_output
  all_cli_output << run_output

  run_dir = File.join(worker_dir, 'run')
  if debug
    FileUtils.cp(File.join(run_dir, 'existing.xml'), File.join(scenario_xml_dir, "#{building_id}-existing.xml")) if File.exist?(File.join(run_dir, 'existing.xml'))
    FileUtils.cp(File.join(run_dir, 'upgraded.xml'), File.join(scenario_xml_dir, "#{building_id}-upgraded.xml")) if File.exist?(File.join(run_dir, 'upgraded.xml'))
    FileUtils.cp(File.join(run_dir, 'existing.osw'), File.join(scenario_osw_dir, "#{building_id}-existing.osw")) if File.exist?(File.join(run_dir, 'existing.osw'))
    FileUtils.cp(File.join(run_dir, 'upgraded.osw'), File.join(scenario_osw_dir, "#{building_id}-upgraded.osw")) if File.exist?(File.join(run_dir, 'upgraded.osw'))
  else
    FileUtils.cp(File.join(run_dir, 'in.xml'), File.join(scenario_xml_dir, "#{building_id}.xml")) if File.exist?(File.join(run_dir, 'in.xml'))
    FileUtils.cp(File.join(run_dir, 'existing.osw'), File.join(scenario_osw_dir, "#{building_id}.osw")) if File.exist?(File.join(run_dir, 'existing.osw')) && !File.exist?(File.join(run_dir, 'upgraded.osw'))
    FileUtils.cp(File.join(run_dir, 'upgraded.osw'), File.join(scenario_osw_dir, "#{building_id}.osw")) if File.exist?(File.join(run_dir, 'upgraded.osw'))
  end
end

def clean_up_result_output(result_output, upgrade)
  # aligns with buildstockbatch
  result_output['build_existing_model.units_represented'] = 1 if !upgrade
  result_output.keys.each do |col|
    if col == 'build_existing_model.weight'
      result_output.delete(col)
    elsif col.include?('apply_upgrade')
      if !['apply_upgrade.applicable', 'apply_upgrade.upgrade_name', 'apply_upgrade.reference_scenario'].include?(col)
        result_output.delete(col)
      end
    end
  end
end

def create_timestamp(time_str)
  return Time.parse(time_str).iso8601.delete('Z')
end

def change_arguments(osw, building_id, hpxml_path, output_dir)
  json = JSON.parse(File.read(osw), symbolize_names: true)
  json[:steps].each do |measure|
    if measure[:measure_dir_name] == 'BuildExistingModel'
      measure[:arguments][:building_id] = "#{building_id}"
    elsif measure[:measure_dir_name] == 'HPXMLtoOpenStudio'
      measure[:arguments][:hpxml_path] = hpxml_path
      measure[:arguments][:output_dir] = output_dir
    end
  end
  File.open(osw, 'w') do |f|
    f.write(JSON.pretty_generate(json))
  end
end

def check_finished_job(result, finished_job)
  result['completed_status'] = 'Fail'
  if File.exist?(finished_job)
    result['completed_status'] = 'Success'
  end

  return result
end

def make_apply_logic_arg(logic)
  if logic.is_a?(Hash)
    key = logic.keys[0]
    val = logic[key]
    if key == 'and'
      return make_apply_logic_arg(val)
    elsif key == 'or'
      return "(#{val.map { |v| make_apply_logic_arg(v) }.join('||')})"
    elsif key == 'not'
      return "!#{make_apply_logic_arg(val)}"
    end
  elsif logic.is_a?(Array)
    return "(#{logic.map { |l| make_apply_logic_arg(l) }.join('&&')})"
  elsif logic.is_a?(String)
    return logic
  end
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} -y buildstockbatch.yml\n e.g., #{File.basename(__FILE__)} -y national_baseline.yml\n"

  opts.on('-y', '--yml <FILE>', 'YML file') do |t|
    options[:yml] = t
  end

  options[:threads] = Parallel.processor_count
  opts.on('-n', '--threads N', Integer, 'Number of parallel simulations (defaults to processor count)') do |t|
    options[:threads] = t
  end

  options[:measures_only] = false
  opts.on('-m', '--measures_only', 'Only run the OpenStudio and EnergyPlus measures') do |_t|
    options[:measures_only] = true
  end

  options[:building_ids] = []
  opts.on('-i', '--building_id ID', Integer, 'Only run this building ID; can be called multiple times') do |t|
    options[:building_ids] << t
  end

  options[:upgrade_names] = []
  opts.on('-u', '--upgrade_name NAME', 'Only run this upgrade; can be called multiple times') do |t|
    options[:upgrade_names] << t
  end

  options[:keep_run_folders] = false
  opts.on('-k', '--keep_run_folders', 'Preserve run folder for all datapoints; also populates run folder in cli_output.log and results-xxx.csv files') do |_t|
    options[:keep_run_folders] = true
  end

  options[:samplingonly] = false
  opts.on('-s', '--samplingonly', 'Run the sampling only') do |_t|
    options[:samplingonly] = true
  end

  options[:version] = false
  opts.on_tail('-v', '--version', 'Display version') do
    options[:version] = true
  end

  options[:debug] = false
  opts.on('-d', '--debug', 'Preserve xml/osw files for existing building') do |_t|
    options[:debug] = true
  end

  options[:overwrite] = false
  opts.on('-o', '--overwrite', 'Overwrite existing project directory') do |_t|
    options[:overwrite] = true
  end

  opts.on_tail('-h', '--help', 'Display help') do
    puts opts
    exit!
  end
end.parse!

if options[:version]
  puts "ResStock v#{Version::ResStock_Version}"
  cli_path = OpenStudio.getOpenStudioCLI
  command = "\"#{cli_path}\" #{File.dirname(__FILE__)}/../resources/hpxml-measures/workflow/run_simulation.rb -v"
  system(command)
else
  if not options[:yml]
    puts "Error: YML argument is required. Call #{File.basename(__FILE__)} -h for usage."
    return
  end

  # Run analysis
  puts "YML: #{options[:yml]}"
  success = run_workflow(options[:yml], options[:threads], options[:measures_only], options[:debug], options[:overwrite],
                         options[:building_ids], options[:upgrade_names], options[:keep_run_folders], options[:samplingonly])

  puts "\nCompleted in #{get_elapsed_time(Time.now, $start_time)}." if success
end
