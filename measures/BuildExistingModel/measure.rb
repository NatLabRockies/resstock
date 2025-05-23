# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require 'pathname'
require_relative '../../resources/buildstock'
require_relative '../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/meta_measure'
# start the measure
class BuildExistingModel < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'Build Existing Model'
  end

  # human readable description
  def description
    return 'Builds the OpenStudio Model for an existing building.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Builds the OpenStudio Model using the sampling csv file, which contains the specified parameters for each existing building. Based on the supplied building number, those parameters are used to run the OpenStudio measures with appropriate arguments and build up the OpenStudio model.'
  end

  # define the arguments that the user will input
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('buildstock_csv_path', false)
    arg.setDefaultValue('buildstock.csv')
    arg.setDisplayName('Buildstock CSV File Path')
    arg.setDescription("Absolute/relative path of the buildstock CSV file. Relative is compared to the 'lib/housing_characteristics' directory.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('project_directory', true)
    arg.setDisplayName('Project Directory')
    arg.setDescription('The directory containing the housing characteristics folder (e.g., project_national).')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('building_id', true)
    arg.setDisplayName('Building Unit ID')
    arg.setDescription('The building unit number (between 1 and the number of samples).')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeDoubleArgument('sample_weight', false)
    arg.setDisplayName('Sample Weight of Simulation')
    arg.setDescription('Number of buildings this simulation represents.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('downselect_logic', false)
    arg.setDisplayName('Downselect Logic')
    arg.setDescription("Logic that specifies the subset of the building stock to be considered in the analysis. Specify one or more parameter|option as found in resources\\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_timestep', false)
    arg.setDisplayName('Simulation Control: Timestep')
    arg.setUnits('min')
    arg.setDescription('Value must be a divisor of 60.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_run_period_begin_month', false)
    arg.setDisplayName('Simulation Control: Run Period Begin Month')
    arg.setUnits('month')
    arg.setDescription('This numeric field should contain the starting month number (1 = January, 2 = February, etc.) for the annual run period desired.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_run_period_begin_day_of_month', false)
    arg.setDisplayName('Simulation Control: Run Period Begin Day of Month')
    arg.setUnits('day')
    arg.setDescription('This numeric field should contain the starting day of the starting month (must be valid for month) for the annual run period desired.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_run_period_end_month', false)
    arg.setDisplayName('Simulation Control: Run Period End Month')
    arg.setUnits('month')
    arg.setDescription('This numeric field should contain the end month number (1 = January, 2 = February, etc.) for the annual run period desired.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_run_period_end_day_of_month', false)
    arg.setDisplayName('Simulation Control: Run Period End Day of Month')
    arg.setUnits('day')
    arg.setDescription('This numeric field should contain the ending day of the ending month (must be valid for month) for the annual run period desired.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_run_period_calendar_year', false)
    arg.setDisplayName('Simulation Control: Run Period Calendar Year')
    arg.setUnits('year')
    arg.setDescription('This numeric field should contain the calendar year that determines the start day of week. If you are running simulations using AMY weather files, the value entered for calendar year will not be used; it will be overridden by the actual year found in the AMY weather file.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('os_hescore_directory', false)
    arg.setDisplayName('HEScore Workflow: OpenStudio-HEScore directory path')
    arg.setDescription('Path to the OpenStudio-HEScore directory. If specified, the HEScore workflow will run.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_scenario_names', false)
    arg.setDisplayName('Emissions: Scenario Names')
    arg.setDescription('Names of emissions scenarios. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_types', false)
    arg.setDisplayName('Emissions: Types')
    arg.setDescription('Types of emissions (e.g., CO2e, NOx, etc.). If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_electricity_folders', false)
    arg.setDisplayName('Emissions: Electricity Folders')
    arg.setDescription('Relative paths of electricity emissions factor schedule files with hourly values. Paths are relative to the resources folder. If multiple scenarios, use a comma-separated list. File names must contain GEA region names.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_natural_gas_values', false)
    arg.setDisplayName('Emissions: Natural Gas Values')
    arg.setDescription('Natural gas emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_propane_values', false)
    arg.setDisplayName('Emissions: Propane Values')
    arg.setDescription('Propane emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_fuel_oil_values', false)
    arg.setDisplayName('Emissions: Fuel Oil Values')
    arg.setDescription('Fuel oil emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_wood_values', false)
    arg.setDisplayName('Emissions: Wood Values')
    arg.setDescription('Wood emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_scenario_names', false)
    arg.setDisplayName('Utility Bills: Scenario Names')
    arg.setDescription('Names of utility bill scenarios. If multiple scenarios, use a comma-separated list. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_simple_filepaths', false)
    arg.setDisplayName('Utility Bills: Simple Filepaths')
    arg.setDescription('Relative paths of simple utility rates. Paths are relative to the resources folder. If multiple scenarios, use a comma-separated list. Files must contain the name of the Parameter as the column header.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_detailed_filepaths', false)
    arg.setDisplayName('Utility Bills: Detailed Filepaths')
    arg.setDescription('Relative paths of detailed utility rates. Paths are relative to the resources folder. If multiple scenarios, use a comma-separated list. Files must contain the name of the Parameter as the column header.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_electricity_fixed_charges', false)
    arg.setDisplayName('Utility Bills: Electricity Fixed Charges')
    arg.setDescription('Electricity utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_electricity_marginal_rates', false)
    arg.setDisplayName('Utility Bills: Electricity Marginal Rates')
    arg.setDescription('Electricity utility bill marginal rates. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_natural_gas_fixed_charges', false)
    arg.setDisplayName('Utility Bills: Natural Gas Fixed Charges')
    arg.setDescription('Natural gas utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_natural_gas_marginal_rates', false)
    arg.setDisplayName('Utility Bills: Natural Gas Marginal Rates')
    arg.setDescription('Natural gas utility bill marginal rates. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_propane_fixed_charges', false)
    arg.setDisplayName('Utility Bills: Propane Fixed Charges')
    arg.setDescription('Propane utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_propane_marginal_rates', false)
    arg.setDisplayName('Utility Bills: Propane Marginal Rates')
    arg.setDescription('Propane utility bill marginal rates. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_fuel_oil_fixed_charges', false)
    arg.setDisplayName('Utility Bills: Fuel Oil Fixed Charges')
    arg.setDescription('Fuel oil utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_fuel_oil_marginal_rates', false)
    arg.setDisplayName('Utility Bills: Fuel Oil Marginal Rates')
    arg.setDescription('Fuel oil utility bill marginal rates. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_wood_fixed_charges', false)
    arg.setDisplayName('Utility Bills: Wood Fixed Charges')
    arg.setDescription('Wood utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_wood_marginal_rates', false)
    arg.setDisplayName('Utility Bills: Wood Marginal Rates')
    arg.setDescription('Wood utility bill marginal rates. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_pv_compensation_types', false)
    arg.setDisplayName('Utility Bills: PV Compensation Types')
    arg.setDescription('Utility bill PV compensation types. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_pv_net_metering_annual_excess_sellback_rate_types', false)
    arg.setDisplayName('Utility Bills: PV Net Metering Annual Excess Sellback Rate Types')
    arg.setDescription("Utility bill PV net metering annual excess sellback rate types. Only applies if the PV compensation type is 'NetMetering'. If multiple scenarios, use a comma-separated list.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_pv_net_metering_annual_excess_sellback_rates', false)
    arg.setDisplayName('Utility Bills: PV Net Metering Annual Excess Sellback Rates')
    arg.setDescription("Utility bill PV net metering annual excess sellback rates. Only applies if the PV compensation type is 'NetMetering' and the PV annual excess sellback rate type is 'User-Specified'. If multiple scenarios, use a comma-separated list.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_pv_feed_in_tariff_rates', false)
    arg.setDisplayName('Utility Bills: PV Feed-In Tariff Rates')
    arg.setDescription("Utility bill PV annual full/gross feed-in tariff rates. Only applies if the PV compensation type is 'FeedInTariff'. If multiple scenarios, use a comma-separated list.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_pv_monthly_grid_connection_fee_units', false)
    arg.setDisplayName('Utility Bills: PV Monthly Grid Connection Fee Units')
    arg.setDescription('Utility bill PV monthly grid connection fee units. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_pv_monthly_grid_connection_fees', false)
    arg.setDisplayName('Utility Bills: PV Monthly Grid Connection Fees')
    arg.setDescription('Utility bill PV monthly grid connection fees. If multiple scenarios, use a comma-separated list.')
    args << arg

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    Version.check_buildstockbatch_version()

    # Assign the user inputs to variables
    args = runner.getArgumentValues(arguments(model), user_arguments)

    # Get file/dir paths
    resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../resources'))
    characteristics_dir = File.absolute_path(File.join(File.dirname(__FILE__), "../../#{args[:project_directory]}/housing_characteristics"))
    measures_dir = File.join(File.dirname(__FILE__), '../../measures')
    hpxml_measures_dir = File.join(File.dirname(__FILE__), '../../resources/hpxml-measures')
    lookup_file = File.join(resources_dir, 'options_lookup.tsv')

    buildstock_csv_path = args[:buildstock_csv_path]
    unless (Pathname.new buildstock_csv_path).absolute?
      buildstock_csv_path = File.absolute_path(File.join(characteristics_dir, buildstock_csv_path))
    end

    if not args[:os_hescore_directory].nil?
      os_hescore_directory = args[:os_hescore_directory]
      hes_ruleset_measures_dir = File.join(os_hescore_directory, 'rulesets')
      run_hescore_workflow = true
    end

    # Check file/dir paths exist
    check_dir_exists(resources_dir, runner)
    [measures_dir, hpxml_measures_dir].each do |dir|
      check_dir_exists(dir, runner)
    end
    check_dir_exists(characteristics_dir, runner)
    check_file_exists(lookup_file, runner)
    check_file_exists(buildstock_csv_path, runner)

    lookup_csv_data = CSV.open(lookup_file, col_sep: "\t").each.to_a

    # Retrieve all data associated with sample number
    bldg_data = get_data_for_sample(buildstock_csv_path, args[:building_id], runner)

    # Retrieve order of parameters to run
    parameters_ordered = get_parameters_ordered_from_options_lookup_tsv(lookup_csv_data, characteristics_dir)

    # Check buildstock.csv has all parameters
    missings = parameters_ordered - bldg_data.keys
    if !missings.empty?
      runner.registerError("Mismatch between buildstock.csv and options_lookup.tsv. Missing parameters: #{missings.join(', ')}.")
      return false
    end

    # Check buildstock.csv doesn't have extra parameters
    extras = bldg_data.keys - parameters_ordered - ['Building', 'sample_weight']
    if !extras.empty?
      runner.registerError("Mismatch between buildstock.csv and options_lookup.tsv. Extra parameters: #{extras.join(', ')}.")
      return false
    end

    # Retrieve options that have been selected for this building_id
    parameters_ordered.each do |parameter_name|
      # Register the option chosen for parameter_name with the runner
      option_name = bldg_data[parameter_name]
      register_value(runner, parameter_name, option_name)
    end

    # Determine whether this building_id has been downselected based on the
    # {parameter_name: option_name} pairs
    if not args[:downselect_logic].nil?

      downselect_logic = args[:downselect_logic]
      downselect_logic = downselect_logic.strip
      downselected = evaluate_logic(downselect_logic, runner, false)

      if downselected.nil?
        # unable to evaluate logic
        return false
      end

      unless downselected
        # Not in downselection; don't run existing home simulation
        runner.registerInfo('Sample is not in downselected parameters; will be registered as invalid.')
        runner.haltWorkflow('Invalid')
        return false
      end

    end

    # Obtain measures and arguments to be called
    measures = {}
    parameters_ordered.each do |parameter_name|
      option_name = bldg_data[parameter_name]
      print_option_assignment(parameter_name, option_name, runner)
      options_measure_args, _errors = get_measure_args_from_option_names(lookup_csv_data, [option_name], parameter_name, lookup_file, runner)
      options_measure_args[option_name].each do |measure_subdir, args_hash|
        update_args_hash(measures, measure_subdir, args_hash)
      end
    end

    # Run the ResStockArguments measure
    resstock_arguments_runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new) # we want only ResStockArguments registered argument values
    measures['ResStockArguments'][0]['building_id'] = args[:building_id]
    if not apply_measures(measures_dir, { 'ResStockArguments' => measures['ResStockArguments'] }, resstock_arguments_runner, model, true, 'OpenStudio::Measure::ModelMeasure', 'existing.osw')
      register_logs(runner, resstock_arguments_runner)
      return false
    end

    # Optional whole SFA/MF building simulation
    whole_sfa_or_mf_building_sim = false
    geometry_building_num_units = 1
    if whole_sfa_or_mf_building_sim
      resstock_arguments_runner.result.stepValues.each do |step_value|
        if step_value.name == 'geometry_building_num_units'
          geometry_building_num_units = Integer(get_value_from_workflow_step_value(step_value))
        end
      end
    end

    num_units_modeled = 1
    max_num_units_modeled = 5
    unit_multipliers = []
    if whole_sfa_or_mf_building_sim && geometry_building_num_units > 1
      num_units_modeled = [geometry_building_num_units, max_num_units_modeled].min
      unit_multipliers = split_into(geometry_building_num_units, num_units_modeled)
    end

    # Set arguments for the BuildResidentialHPXML measure
    hpxml_path = File.expand_path('../existing.xml')
    measures['BuildResidentialHPXML'] = [{ 'hpxml_path' => hpxml_path }]
    measures['BuildResidentialHPXML'][0]['apply_defaults'] = true # for apply_hvac_sizing since ApplyUpgrade sets HVAC capacities
    measures['BuildResidentialHPXML'][0]['apply_validation'] = true

    set_header(runner, measures, args, whole_sfa_or_mf_building_sim, bldg_data, resources_dir)
    set_building_header(measures)
    set_battery(measures, whole_sfa_or_mf_building_sim, num_units_modeled)

    new_runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    (1..num_units_modeled).each do |unit_number|
      if unit_number > 1
        measures['BuildResidentialHPXML'][0]['existing_hpxml_path'] = hpxml_path
      end

      set_resstock_arguments(measures, runner, resstock_arguments_runner)
      if not unit_multipliers.empty?
        unit_multiplier = unit_multipliers[unit_number]
      end
      set_building_construction(measures, unit_multiplier)
      set_dehumidifier(measures, unit_multiplier)

      # Specify measures to run
      measures_hash = { 'BuildResidentialHPXML' => measures['BuildResidentialHPXML'] }
      if not apply_measures(hpxml_measures_dir, measures_hash, new_runner, model, true, 'OpenStudio::Measure::ModelMeasure', nil)
        register_logs(runner, new_runner)
        return false
      end
    end

    if not run_hescore_workflow
      # Set arguments for the BuildResidentialScheduleFile measure
      measures['BuildResidentialScheduleFile'] = [{ 'hpxml_path' => hpxml_path,
                                                    'hpxml_output_path' => hpxml_path,
                                                    'schedules_random_seed' => args[:building_id],
                                                    'output_csv_path' => File.expand_path('../schedules.csv'),
                                                    'building_id' => 'ALL' }]

      # Specify measures to run
      measures_hash = { 'BuildResidentialScheduleFile' => measures['BuildResidentialScheduleFile'] }
      if not apply_measures(hpxml_measures_dir, measures_hash, new_runner, model, true, 'OpenStudio::Measure::ModelMeasure', nil)
        register_logs(runner, new_runner)
        return false
      end
    end

    # Set arguments for the ResStockArgumentsPostHPXML measure
    measures['ResStockArgumentsPostHPXML'] = [{}] if !measures.keys.include?('ResStockArgumentsPostHPXML')
    measures['ResStockArgumentsPostHPXML'][0]['hpxml_path'] = hpxml_path
    measures['ResStockArgumentsPostHPXML'][0]['building_id'] = args[:building_id]
    measures_hash = { 'ResStockArgumentsPostHPXML' => measures['ResStockArgumentsPostHPXML'] }
    if not apply_measures(measures_dir, measures_hash, new_runner, model, true, 'OpenStudio::Measure::ModelMeasure', nil)
      register_logs(runner, new_runner)
      return false
    end

    # Copy existing.xml to home.xml for downstream HPXMLtoOpenStudio
    # We need existing.xml (and not just home.xml) for UpgradeCosts
    in_path = File.expand_path('../home.xml')
    FileUtils.cp(hpxml_path, in_path)

    # Run HEScore Measures
    if run_hescore_workflow
      hes_json_path = File.expand_path('../hes.json')
      measures['HPXMLtoHEScore'] = [{ 'hpxml_path' => in_path, 'output_path' => hes_json_path }]
      measures['HEScoreRuleset'] = [{ 'json_path' => hes_json_path, 'hpxml_output_path' => in_path }]

      # HPXMLtoHEScore and HEScoreRuleset
      measures_hash = { 'HPXMLtoHEScore' => measures['HPXMLtoHEScore'], 'HEScoreRuleset' => measures['HEScoreRuleset'] }

      if not apply_measures(hes_ruleset_measures_dir, measures_hash, new_runner, model, true, 'OpenStudio::Measure::ModelMeasure')
        register_logs(runner, new_runner)
        return false
      end
    end

    # Report additional characteristics
    if File.exist?(hpxml_path)
      hpxml = HPXML.new(hpxml_path: hpxml_path)
    else
      runner.registerWarning("BuildExistingModel measure could not find '#{hpxml_path}'.")
      return true
    end

    hpxml_bldg = hpxml.buildings[0]

    # height above grade
    unit_height_above_grade = hpxml_bldg.building_construction.unit_height_above_grade
    register_value(runner, 'unit_height_above_grade', unit_height_above_grade)

    # infiltration
    air_infiltration_measurement = hpxml_bldg.air_infiltration_measurements[0]
    a_ext = 1.0
    a_ext = air_infiltration_measurement.a_ext if !air_infiltration_measurement.a_ext.nil?
    register_value(runner, 'air_leakage_to_outside_ach_50', air_infiltration_measurement.air_leakage * a_ext)

    # weather file
    epw_path = Location.get_epw_path(hpxml_bldg, hpxml_path)
    epw_file = OpenStudio::EpwFile.new(epw_path)
    register_value(runner, 'weather_file_city', epw_file.city)
    register_value(runner, 'weather_file_latitude', epw_file.latitude)
    register_value(runner, 'weather_file_longitude', epw_file.longitude)

    # sample weight
    if bldg_data.keys.include?('sample_weight')
      sample_weight = bldg_data['sample_weight']
      register_value(runner, 'sample_weight', sample_weight.to_s)
    end

    register_logs(runner, resstock_arguments_runner)
    register_logs(runner, new_runner)

    return true
  end

  def set_header(runner, measures, args, whole_sfa_or_mf_building_sim, bldg_data, resources_dir)
    # Whole SFA/MF Building Simulation?
    measures['BuildResidentialHPXML'][0]['whole_sfa_or_mf_building_sim'] = whole_sfa_or_mf_building_sim

    # Software Info
    measures['BuildResidentialHPXML'][0]['software_info_program_used'] = 'ResStock'
    measures['BuildResidentialHPXML'][0]['software_info_program_version'] = Version::ResStock_Version

    # Simulation Control
    measures['BuildResidentialHPXML'][0]['simulation_control_timestep'] = args[:simulation_control_timestep] if !args[:simulation_control_timestep].nil?
    if !args[:simulation_control_run_period_begin_month].nil? && !args[:simulation_control_run_period_begin_day_of_month].nil? && !args[:simulation_control_run_period_end_month].nil? && !args[:simulation_control_run_period_end_day_of_month].nil?
      begin_month = "#{Date::ABBR_MONTHNAMES[args[:simulation_control_run_period_begin_month]]}"
      begin_day = args[:simulation_control_run_period_begin_day_of_month]
      end_month = "#{Date::ABBR_MONTHNAMES[args[:simulation_control_run_period_end_month]]}"
      end_day = args[:simulation_control_run_period_end_day_of_month]
      measures['BuildResidentialHPXML'][0]['simulation_control_run_period'] = "#{begin_month} #{begin_day} - #{end_month} #{end_day}"
    end
    measures['BuildResidentialHPXML'][0]['simulation_control_run_period_calendar_year'] = args[:simulation_control_run_period_calendar_year] if args[:simulation_control_run_period_calendar_year]

    # Emissions
    if not args[:emissions_scenario_names].nil?
      if !bldg_data.keys.include?('Generation And Emissions Assessment Region')
        runner.registerError('Emissions scenario(s) were specified, but could not find the Generation and Emissions Assessment (GEA) region.')
        return false
      end

      emissions_electricity_filepaths = []
      scenarios = args[:emissions_electricity_folders].split(',')
      scenarios.each do |scenario|
        scenario = File.join(resources_dir, scenario)
        if !File.exist?(scenario)
          runner.registerError("Emissions scenario electricity folder '#{scenario}' does not exist.")
          return false
        end

        Dir["#{scenario}/*.csv"].each do |filepath|
          emissions_electricity_filepaths << filepath if filepath.include?(bldg_data['Generation And Emissions Assessment Region'])
        end
      end

      if emissions_electricity_filepaths.size != scenarios.size
        runner.registerWarning('Not calculating emissions because an electricity filepath for at least one emissions scenario could not be located.')
      else
        emissions_scenario_names = args[:emissions_scenario_names]
        measures['BuildResidentialHPXML'][0]['emissions_scenario_names'] = emissions_scenario_names

        emissions_types = args[:emissions_types]
        measures['BuildResidentialHPXML'][0]['emissions_types'] = emissions_types

        emissions_electricity_units = ([HPXML::EmissionsScenario::UnitsKgPerMWh] * scenarios.size).join(',')
        measures['BuildResidentialHPXML'][0]['emissions_electricity_units'] = emissions_electricity_units
        register_value(runner, 'emissions_electricity_units', emissions_electricity_units)

        emissions_electricity_filepaths = emissions_electricity_filepaths.join(',')
        measures['BuildResidentialHPXML'][0]['emissions_electricity_values_or_filepaths'] = emissions_electricity_filepaths
        register_value(runner, 'emissions_electricity_values_or_filepaths', emissions_electricity_filepaths)

        emissions_fossil_fuel_units = ([HPXML::EmissionsScenario::UnitsLbPerMBtu] * scenarios.size).join(',')
        measures['BuildResidentialHPXML'][0]['emissions_fossil_fuel_units'] = emissions_fossil_fuel_units
        register_value(runner, 'emissions_fossil_fuel_units', emissions_fossil_fuel_units)

        emissions_natural_gas_values = args[:emissions_natural_gas_values]
        measures['BuildResidentialHPXML'][0]['emissions_natural_gas_values'] = emissions_natural_gas_values

        emissions_propane_values = args[:emissions_propane_values]
        measures['BuildResidentialHPXML'][0]['emissions_propane_values'] = emissions_propane_values

        emissions_fuel_oil_values = args[:emissions_fuel_oil_values]
        measures['BuildResidentialHPXML'][0]['emissions_fuel_oil_values'] = emissions_fuel_oil_values

        emissions_wood_values = args[:emissions_wood_values]
        measures['BuildResidentialHPXML'][0]['emissions_wood_values'] = emissions_wood_values
      end
    end

    # Utility Bills
    if not args[:utility_bill_scenario_names].nil?

      utility_bill_scenario_names = args[:utility_bill_scenario_names].split(',').map(&:strip)

      utility_bill_simple_filepaths = args[:utility_bill_simple_filepaths].split(',').map(&:strip)
      if utility_bill_simple_filepaths.empty?
        utility_bill_simple_filepaths = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_detailed_filepaths = args[:utility_bill_detailed_filepaths].split(',').map(&:strip)
      if utility_bill_detailed_filepaths.empty?
        utility_bill_detailed_filepaths = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_electricity_fixed_charges = args[:utility_bill_electricity_fixed_charges].split(',').map(&:strip)
      if utility_bill_electricity_fixed_charges.empty?
        utility_bill_electricity_fixed_charges = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_electricity_marginal_rates = args[:utility_bill_electricity_marginal_rates].split(',').map(&:strip)
      if utility_bill_electricity_marginal_rates.empty?
        utility_bill_electricity_marginal_rates = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_natural_gas_fixed_charges = args[:utility_bill_natural_gas_fixed_charges].split(',').map(&:strip)
      if utility_bill_natural_gas_fixed_charges.empty?
        utility_bill_natural_gas_fixed_charges = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_natural_gas_marginal_rates = args[:utility_bill_natural_gas_marginal_rates].split(',').map(&:strip)
      if utility_bill_natural_gas_marginal_rates.empty?
        utility_bill_natural_gas_marginal_rates = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_propane_fixed_charges = args[:utility_bill_propane_fixed_charges].split(',').map(&:strip)
      if utility_bill_propane_fixed_charges.empty?
        utility_bill_propane_fixed_charges = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_propane_marginal_rates = args[:utility_bill_propane_marginal_rates].split(',').map(&:strip)
      if utility_bill_propane_marginal_rates.empty?
        utility_bill_propane_marginal_rates = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_fuel_oil_fixed_charges = args[:utility_bill_fuel_oil_fixed_charges].split(',').map(&:strip)
      if utility_bill_fuel_oil_fixed_charges.empty?
        utility_bill_fuel_oil_fixed_charges = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_fuel_oil_marginal_rates = args[:utility_bill_fuel_oil_marginal_rates].split(',').map(&:strip)
      if utility_bill_fuel_oil_marginal_rates.empty?
        utility_bill_fuel_oil_marginal_rates = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_wood_fixed_charges = args[:utility_bill_wood_fixed_charges].split(',').map(&:strip)
      if utility_bill_wood_fixed_charges.empty?
        utility_bill_wood_fixed_charges = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_wood_marginal_rates = args[:utility_bill_wood_marginal_rates].split(',').map(&:strip)
      if utility_bill_wood_marginal_rates.empty?
        utility_bill_wood_marginal_rates = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_pv_compensation_types = args[:utility_bill_pv_compensation_types].split(',').map(&:strip)
      if utility_bill_pv_compensation_types.empty?
        utility_bill_pv_compensation_types = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_pv_net_metering_annual_excess_sellback_rate_types = args[:utility_bill_pv_net_metering_annual_excess_sellback_rate_types].split(',').map(&:strip)
      if utility_bill_pv_net_metering_annual_excess_sellback_rate_types.empty?
        utility_bill_pv_net_metering_annual_excess_sellback_rate_types = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_pv_net_metering_annual_excess_sellback_rates = args[:utility_bill_pv_net_metering_annual_excess_sellback_rates].split(',').map(&:strip)
      if utility_bill_pv_net_metering_annual_excess_sellback_rates.empty?
        utility_bill_pv_net_metering_annual_excess_sellback_rates = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_pv_feed_in_tariff_rates = args[:utility_bill_pv_feed_in_tariff_rates].split(',').map(&:strip)
      if utility_bill_pv_feed_in_tariff_rates.empty?
        utility_bill_pv_feed_in_tariff_rates = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_pv_monthly_grid_connection_fee_units = args[:utility_bill_pv_monthly_grid_connection_fee_units].split(',').map(&:strip)
      if utility_bill_pv_monthly_grid_connection_fee_units.empty?
        utility_bill_pv_monthly_grid_connection_fee_units = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_pv_monthly_grid_connection_fees = args[:utility_bill_pv_monthly_grid_connection_fees].split(',').map(&:strip)
      if utility_bill_pv_monthly_grid_connection_fees.empty?
        utility_bill_pv_monthly_grid_connection_fees = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_scenarios = utility_bill_scenario_names.zip(utility_bill_simple_filepaths,
                                                               utility_bill_detailed_filepaths,
                                                               utility_bill_electricity_fixed_charges,
                                                               utility_bill_electricity_marginal_rates,
                                                               utility_bill_natural_gas_fixed_charges,
                                                               utility_bill_natural_gas_marginal_rates,
                                                               utility_bill_propane_fixed_charges,
                                                               utility_bill_propane_marginal_rates,
                                                               utility_bill_fuel_oil_fixed_charges,
                                                               utility_bill_fuel_oil_marginal_rates,
                                                               utility_bill_wood_fixed_charges,
                                                               utility_bill_wood_marginal_rates,
                                                               utility_bill_pv_compensation_types,
                                                               utility_bill_pv_net_metering_annual_excess_sellback_rate_types,
                                                               utility_bill_pv_net_metering_annual_excess_sellback_rates,
                                                               utility_bill_pv_feed_in_tariff_rates,
                                                               utility_bill_pv_monthly_grid_connection_fee_units,
                                                               utility_bill_pv_monthly_grid_connection_fees)

      utility_bill_electricity_filepaths = []
      utility_bill_electricity_fixed_charges = []
      utility_bill_electricity_marginal_rates = []
      utility_bill_natural_gas_fixed_charges = []
      utility_bill_natural_gas_marginal_rates = []
      utility_bill_propane_fixed_charges = []
      utility_bill_propane_marginal_rates = []
      utility_bill_fuel_oil_fixed_charges = []
      utility_bill_fuel_oil_marginal_rates = []
      utility_bill_wood_fixed_charges = []
      utility_bill_wood_marginal_rates = []
      utility_bill_pv_compensation_types = []
      utility_bill_pv_net_metering_annual_excess_sellback_rate_types = []
      utility_bill_pv_net_metering_annual_excess_sellback_rates = []
      utility_bill_pv_feed_in_tariff_rates = []
      utility_bill_pv_monthly_grid_connection_fee_units = []
      utility_bill_pv_monthly_grid_connection_fees = []
      utility_bill_scenarios.each do |utility_bill_scenario|
        _name, simple_filepath, detailed_filepath, elec_fixed_charge, elec_marginal_rate, natural_gas_fixed_charge, natural_gas_marginal_rate, propane_fixed_charge, propane_marginal_rate, fuel_oil_fixed_charge, fuel_oil_marginal_rate, wood_fixed_charge, wood_marginal_rate, pv_compensation_type, pv_net_metering_annual_excess_sellback_rate_type, pv_net_metering_annual_excess_sellback_rate, pv_feed_in_tariff_rate, pv_monthly_grid_connection_fee_units, pv_monthly_grid_connection_fee = utility_bill_scenario

        if (!simple_filepath.nil? && !simple_filepath.empty?) || (!detailed_filepath.nil? && !detailed_filepath.empty?)

          if !simple_filepath.nil? && !simple_filepath.empty?
            simple_filepath = File.join(resources_dir, simple_filepath)
            utility_rate = get_utility_rate(runner, simple_filepath, bldg_data)

          elsif !detailed_filepath.nil? && !detailed_filepath.empty?
            detailed_filepath = File.join(resources_dir, detailed_filepath)
            utility_rate = get_utility_rate(runner, detailed_filepath, bldg_data)
            utility_rate['elec_filepath'] = File.join(File.dirname(detailed_filepath), utility_rate['elec_filepath']) if !utility_rate['elec_filepath'].nil?

          end

          utility_bill_electricity_filepaths << utility_rate['elec_filepath']
          utility_bill_electricity_fixed_charges << utility_rate['elec_fixed_charge']
          utility_bill_electricity_marginal_rates << utility_rate['elec_marginal_rate']
          utility_bill_natural_gas_fixed_charges << utility_rate['natural_gas_fixed_charge']
          utility_bill_natural_gas_marginal_rates << utility_rate['natural_gas_marginal_rate']
          utility_bill_propane_fixed_charges << utility_rate['propane_fixed_charge']
          utility_bill_propane_marginal_rates << utility_rate['propane_marginal_rate']
          utility_bill_fuel_oil_fixed_charges << utility_rate['fuel_oil_fixed_charge']
          utility_bill_fuel_oil_marginal_rates << utility_rate['fuel_oil_marginal_rate']
          utility_bill_wood_fixed_charges << utility_rate['wood_fixed_charge']
          utility_bill_wood_marginal_rates << utility_rate['wood_marginal_rate']
          utility_bill_pv_compensation_types << utility_rate['pv_compensation_type']
          utility_bill_pv_net_metering_annual_excess_sellback_rate_types << utility_rate['pv_net_metering_annual_excess_sellback_rate_type']
          utility_bill_pv_net_metering_annual_excess_sellback_rates << utility_rate['pv_net_metering_annual_excess_sellback_rate']
          utility_bill_pv_feed_in_tariff_rates << utility_rate['pv_feed_in_tariff_rate']
          utility_bill_pv_monthly_grid_connection_fee_units << utility_rate['pv_monthly_grid_connection_fee_units']
          utility_bill_pv_monthly_grid_connection_fees << utility_rate['pv_monthly_grid_connection_fee']
        else # if simple or detailed filepath not assigned, use what's populated in the yml
          utility_bill_electricity_filepaths << nil # support detailed tariff assignment only through the lookup file
          utility_bill_electricity_fixed_charges << elec_fixed_charge
          utility_bill_electricity_marginal_rates << elec_marginal_rate
          utility_bill_natural_gas_fixed_charges << natural_gas_fixed_charge
          utility_bill_natural_gas_marginal_rates << natural_gas_marginal_rate
          utility_bill_propane_fixed_charges << propane_fixed_charge
          utility_bill_propane_marginal_rates << propane_marginal_rate
          utility_bill_fuel_oil_fixed_charges << fuel_oil_fixed_charge
          utility_bill_fuel_oil_marginal_rates << fuel_oil_marginal_rate
          utility_bill_wood_fixed_charges << wood_fixed_charge
          utility_bill_wood_marginal_rates << wood_marginal_rate
          utility_bill_pv_compensation_types << pv_compensation_type
          utility_bill_pv_net_metering_annual_excess_sellback_rate_types << pv_net_metering_annual_excess_sellback_rate_type
          utility_bill_pv_net_metering_annual_excess_sellback_rates << pv_net_metering_annual_excess_sellback_rate
          utility_bill_pv_feed_in_tariff_rates << pv_feed_in_tariff_rate
          utility_bill_pv_monthly_grid_connection_fee_units << pv_monthly_grid_connection_fee_units
          utility_bill_pv_monthly_grid_connection_fees << pv_monthly_grid_connection_fee
        end
      end

      utility_bill_scenario_names = utility_bill_scenario_names.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_scenario_names'] = utility_bill_scenario_names

      utility_bill_electricity_filepaths = utility_bill_electricity_filepaths.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_electricity_filepaths'] = utility_bill_electricity_filepaths
      register_value(runner, 'utility_bill_electricity_filepaths', utility_bill_electricity_filepaths)

      utility_bill_electricity_fixed_charges = utility_bill_electricity_fixed_charges.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_electricity_fixed_charges'] = utility_bill_electricity_fixed_charges
      register_value(runner, 'utility_bill_electricity_fixed_charges', utility_bill_electricity_fixed_charges)

      utility_bill_electricity_marginal_rates = utility_bill_electricity_marginal_rates.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_electricity_marginal_rates'] = utility_bill_electricity_marginal_rates
      register_value(runner, 'utility_bill_electricity_marginal_rates', utility_bill_electricity_marginal_rates)

      utility_bill_natural_gas_fixed_charges = utility_bill_natural_gas_fixed_charges.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_natural_gas_fixed_charges'] = utility_bill_natural_gas_fixed_charges
      register_value(runner, 'utility_bill_natural_gas_fixed_charges', utility_bill_natural_gas_fixed_charges)

      utility_bill_natural_gas_marginal_rates = utility_bill_natural_gas_marginal_rates.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_natural_gas_marginal_rates'] = utility_bill_natural_gas_marginal_rates
      register_value(runner, 'utility_bill_natural_gas_marginal_rates', utility_bill_natural_gas_marginal_rates)

      utility_bill_propane_fixed_charges = utility_bill_propane_fixed_charges.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_propane_fixed_charges'] = utility_bill_propane_fixed_charges
      register_value(runner, 'utility_bill_propane_fixed_charges', utility_bill_propane_fixed_charges)

      utility_bill_propane_marginal_rates = utility_bill_propane_marginal_rates.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_propane_marginal_rates'] = utility_bill_propane_marginal_rates
      register_value(runner, 'utility_bill_propane_marginal_rates', utility_bill_propane_marginal_rates)

      utility_bill_fuel_oil_fixed_charges = utility_bill_fuel_oil_fixed_charges.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_fuel_oil_fixed_charges'] = utility_bill_fuel_oil_fixed_charges
      register_value(runner, 'utility_bill_fuel_oil_fixed_charges', utility_bill_fuel_oil_fixed_charges)

      utility_bill_fuel_oil_marginal_rates = utility_bill_fuel_oil_marginal_rates.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_fuel_oil_marginal_rates'] = utility_bill_fuel_oil_marginal_rates
      register_value(runner, 'utility_bill_fuel_oil_marginal_rates', utility_bill_fuel_oil_marginal_rates)

      utility_bill_wood_fixed_charges = utility_bill_wood_fixed_charges.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_wood_fixed_charges'] = utility_bill_wood_fixed_charges
      register_value(runner, 'utility_bill_wood_fixed_charges', utility_bill_wood_fixed_charges)

      utility_bill_wood_marginal_rates = utility_bill_wood_marginal_rates.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_wood_marginal_rates'] = utility_bill_wood_marginal_rates
      register_value(runner, 'utility_bill_wood_marginal_rates', utility_bill_wood_marginal_rates)

      utility_bill_pv_compensation_types = utility_bill_pv_compensation_types.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_pv_compensation_types'] = utility_bill_pv_compensation_types
      register_value(runner, 'utility_bill_pv_compensation_types', utility_bill_pv_compensation_types)

      utility_bill_pv_net_metering_annual_excess_sellback_rate_types = utility_bill_pv_net_metering_annual_excess_sellback_rate_types.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_pv_net_metering_annual_excess_sellback_rate_types'] = utility_bill_pv_net_metering_annual_excess_sellback_rate_types
      register_value(runner, 'utility_bill_pv_net_metering_annual_excess_sellback_rate_types', utility_bill_pv_net_metering_annual_excess_sellback_rate_types)

      utility_bill_pv_net_metering_annual_excess_sellback_rates = utility_bill_pv_net_metering_annual_excess_sellback_rates.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_pv_net_metering_annual_excess_sellback_rates'] = utility_bill_pv_net_metering_annual_excess_sellback_rates
      register_value(runner, 'utility_bill_pv_net_metering_annual_excess_sellback_rates', utility_bill_pv_net_metering_annual_excess_sellback_rates)

      utility_bill_pv_feed_in_tariff_rates = utility_bill_pv_feed_in_tariff_rates.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_pv_feed_in_tariff_rates'] = utility_bill_pv_feed_in_tariff_rates
      register_value(runner, 'utility_bill_pv_feed_in_tariff_rates', utility_bill_pv_feed_in_tariff_rates)

      utility_bill_pv_monthly_grid_connection_fee_units = utility_bill_pv_monthly_grid_connection_fee_units.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_pv_monthly_grid_connection_fee_units'] = utility_bill_pv_monthly_grid_connection_fee_units
      register_value(runner, 'utility_bill_pv_monthly_grid_connection_fee_units', utility_bill_pv_monthly_grid_connection_fee_units)

      utility_bill_pv_monthly_grid_connection_fees = utility_bill_pv_monthly_grid_connection_fees.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_pv_monthly_grid_connection_fees'] = utility_bill_pv_monthly_grid_connection_fees
      register_value(runner, 'utility_bill_pv_monthly_grid_connection_fees', utility_bill_pv_monthly_grid_connection_fees)
    end
  end

  def set_resstock_arguments(measures, runner, child_runner)
    # Assign ResStockArgument's runner arguments to BuildResidentialHPXML
    child_runner.result.stepValues.each do |step_value|
      value = get_value_from_workflow_step_value(step_value)
      register_value(runner, step_value.name, value) if Constants::ArgumentsToRegister.include?(step_value.name)
      next if value == '' || Constants::ArgumentsToExclude.include?(step_value.name)

      measures['BuildResidentialHPXML'][0][step_value.name] = value
    end
  end

  def set_building_header(measures)
    # Set additional properties
    additional_properties = []

    ['ceiling_insulation_r'].each do |arg_name|
      arg_value = measures['ResStockArguments'][0][arg_name]
      additional_properties << "#{arg_name}=#{arg_value}"
    end
    measures['BuildResidentialHPXML'][0]['additional_properties'] = additional_properties.join('|') unless additional_properties.empty?
  end

  def set_building_construction(measures, unit_multiplier)
    if not unit_multiplier.nil?
      measures['BuildResidentialHPXML'][0]['unit_multiplier'] = unit_multiplier
    end
  end

  def set_dehumidifier(measures, unit_multiplier)
    if not unit_multiplier.nil?
      if unit_multiplier > 1
        measures['BuildResidentialHPXML'][0]['dehumidifier_type'] = 'none' # limitation of OS-HPXML
      end
    end
  end

  def set_battery(measures, whole_sfa_or_mf_building_sim, num_units_modeled)
    if whole_sfa_or_mf_building_sim && num_units_modeled > 1
      measures['BuildResidentialHPXML'][0]['battery_present'] = 'false' # limitation of OS-HPXML
    end
  end

  def split_into(n, p)
    return [n / p + 1] * (n % p) + [n / p] * (p - n % p)
  end

  def get_utility_rate(runner, filepath, bldg_data)
    if !File.exist?(filepath)
      runner.registerError("Utility bill scenario file '#{filepath}' does not exist.")
      return false
    end

    rows = CSV.read(filepath, headers: true, col_sep: "\t")
    utility_rates = rows.map { |d| d.to_hash }
    parameter = utility_rates[0].keys[0]

    if !bldg_data.keys.include?(parameter)
      runner.registerError("Utility bill scenario(s) were specified, but could not find #{parameter}.")
      return false
    end

    utility_rates = utility_rates.select { |r| r[parameter] == bldg_data[parameter] }

    if utility_rates.size != 1
      runner.registerWarning("Could not find #{parameter}=#{bldg_data[parameter]} in #{filepath}.")
      utility_rate = Hash[rows.headers.map { |x| [x, nil] }]
    else
      utility_rate = utility_rates[0]
    end
    return utility_rate
  end
end

# register the measure to be used by the application
BuildExistingModel.new.registerWithApplication
