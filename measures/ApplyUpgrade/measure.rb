# frozen_string_literal: true

require 'openstudio'
require_relative 'resources/constants'
require_relative '../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/meta_measure'
require_relative '../../resources/hpxml-measures/BuildResidentialHPXML/resources/options'

# start the measure
class ApplyUpgrade < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'Apply Upgrade'
  end

  # human readable description
  def description
    return 'Measure that applies an upgrade (one or more child measures) to a building model based on the specified logic.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Determines if the upgrade should apply to a given building model. If so, calls one or more child measures with the appropriate arguments.'
  end

  def num_options
    return Constants::NumApplyUpgradeOptions # Synced with UpgradeCosts measure
  end

  def num_costs_per_option
    return Constants::NumApplyUpgradesCostsPerOption # Synced with UpgradeCosts measure
  end

  def cost_multiplier_choices
    return Constants::CostMultiplierChoices # Synced with UpgradeCosts measure
  end

  # define the arguments that the user will input
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    # Make string arg for upgrade name
    upgrade_name = OpenStudio::Measure::OSArgument::makeStringArgument('upgrade_name', true)
    upgrade_name.setDisplayName('Upgrade Name')
    upgrade_name.setDescription('User-specificed name that describes the upgrade.')
    upgrade_name.setDefaultValue('My Upgrade')
    args << upgrade_name

    project_directory = OpenStudio::Measure::OSArgument::makeStringArgument('project_directory', true)
    project_directory.setDisplayName('Project Directory')
    project_directory.setDescription('The directory containing the housing characteristics folder (e.g., project_national).')
    args << project_directory

    for option_num in 1..num_options

      # Option name argument
      option = OpenStudio::Measure::OSArgument.makeStringArgument("option_#{option_num}", (option_num == 1))
      option.setDisplayName("Option #{option_num}")
      option.setDescription('Specify the parameter|option as found in resources\\options_lookup.tsv.')
      args << option

      # Option Apply Logic argument
      option_apply_logic = OpenStudio::Measure::OSArgument.makeStringArgument("option_#{option_num}_apply_logic", false)
      option_apply_logic.setDisplayName("Option #{option_num} Apply Logic")
      option_apply_logic.setDescription("Logic that specifies if the Option #{option_num} upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.")
      args << option_apply_logic

      for cost_num in 1..num_costs_per_option

        # Option Cost Value argument
        cost_value = OpenStudio::Measure::OSArgument.makeDoubleArgument("option_#{option_num}_cost_#{cost_num}_value", false)
        cost_value.setDisplayName("Option #{option_num} Cost #{cost_num} Value")
        cost_value.setDescription("Total option #{option_num} cost is the sum of all: (Cost N Value) x (Cost N Multiplier).")
        cost_value.setUnits('$')
        args << cost_value

        # Option Cost Multiplier argument
        cost_multiplier = OpenStudio::Measure::OSArgument.makeChoiceArgument("option_#{option_num}_cost_#{cost_num}_multiplier", cost_multiplier_choices, false)
        cost_multiplier.setDisplayName("Option #{option_num} Cost #{cost_num} Multiplier")
        cost_multiplier.setDescription("Total option #{option_num} cost is the sum of all: (Cost N Value) x (Cost N Multiplier).")
        cost_multiplier.setDefaultValue(cost_multiplier_choices[0])
        args << cost_multiplier

      end

      # Option Lifetime argument
      option_lifetime = OpenStudio::Measure::OSArgument.makeDoubleArgument("option_#{option_num}_lifetime", false)
      option_lifetime.setDisplayName("Option #{option_num} Lifetime")
      option_lifetime.setDescription('The option lifetime.')
      option_lifetime.setUnits('years')
      args << option_lifetime

    end

    # Package Apply Logic argument
    package_apply_logic = OpenStudio::Measure::OSArgument.makeStringArgument('package_apply_logic', false)
    package_apply_logic.setDisplayName('Package Apply Logic')
    package_apply_logic.setDescription("Logic that specifies if the entire package upgrade (all options) will apply based on the existing building's options. Specify one or more parameter|option as found in resources\\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.")
    args << package_apply_logic

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Assign the user inputs to variables
    args = runner.getArgumentValues(arguments(model), user_arguments)

    # Retrieve Option X argument values
    options = {}
    for option_num in 1..num_options
      if option_num == 1
        arg = runner.getStringArgumentValue("option_#{option_num}", user_arguments)
      else
        arg = runner.getOptionalStringArgumentValue("option_#{option_num}", user_arguments)
        next if not arg.is_initialized

        arg = arg.get
      end
      next if arg.strip.size == 0

      if not arg.include?('|')
        runner.registerError("Option #{option_num} is missing the '|' delimiter.")
        return false
      end
      options[option_num] = arg.strip
    end

    # Retrieve Option X Apply Logic argument values
    options_apply_logic = {}
    for option_num in 1..num_options
      arg = runner.getOptionalStringArgumentValue("option_#{option_num}_apply_logic", user_arguments)
      next if not arg.is_initialized

      arg = arg.get
      next if arg.strip.size == 0

      if not arg.include?('|')
        runner.registerError("Option #{option_num} Apply Logic is missing the '|' delimiter.")
        return false
      end
      if not options.keys.include?(option_num)
        runner.registerError("Option #{option_num} Apply Logic was provided, but a corresponding Option #{option_num} was not provided.")
        return false
      end
      options_apply_logic[option_num] = arg.strip
    end

    # Retrieve Package Apply Logic argument value
    arg = runner.getOptionalStringArgumentValue('package_apply_logic', user_arguments)
    if not arg.is_initialized
      package_apply_logic = nil
    else
      arg = arg.get
      if arg.strip.size == 0
        package_apply_logic = nil
      else
        if not arg.include?('|')
          runner.registerError("Package Apply Logic is missing the '|' delimiter.")
          return false
        end
        package_apply_logic = arg.strip
      end
    end

    # Get file/dir paths
    resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../resources'))
    characteristics_dir = File.absolute_path(File.join(File.dirname(__FILE__), "../../#{args[:project_directory]}/housing_characteristics"))
    measures_dir = File.join(File.dirname(__FILE__), '../../measures')
    hpxml_measures_dir = File.join(File.dirname(__FILE__), '../../resources/hpxml-measures')
    lookup_file = File.join(resources_dir, 'options_lookup.tsv')

    # Check file/dir paths exist
    check_dir_exists(resources_dir, runner)
    [measures_dir, hpxml_measures_dir].each do |dir|
      check_dir_exists(dir, runner)
    end
    check_dir_exists(characteristics_dir, runner)
    check_file_exists(lookup_file, runner)

    lookup_csv_data = CSV.open(lookup_file, col_sep: "\t").each.to_a

    # Retrieve values from BuildExistingModel
    values = Hash[runner.getPastStepValuesForMeasure('build_existing_model').collect { |k, v| [k.to_s, v] }]

    # Process package apply logic if provided
    apply_package_upgrade = true
    if not package_apply_logic.nil?
      # Apply this package?
      apply_package_upgrade = evaluate_logic(package_apply_logic, runner)
      if apply_package_upgrade.nil?
        return false
      end
    end

    # Get defaulted hpxml
    hpxml_path = File.expand_path('../existing.xml') # this is the defaulted hpxml
    if File.exist?(hpxml_path)
      hpxml = HPXML.new(hpxml_path: hpxml_path)
    else
      runner.registerWarning("ApplyUpgrade measure could not find '#{hpxml_path}'.")
      return true
    end

    measures = {}
    existing_options_measure_args = {}
    resstock_arguments_runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new) # we want only ResStockArguments registered argument values
    if apply_package_upgrade
      # Obtain measures and arguments to be called
      # Process options apply logic if provided
      options.each do |option_num, option|
        parameter_name, option_name = option.split('|')

        # Apply this option?
        apply_option_upgrade = true
        if options_apply_logic.include?(option_num)
          apply_option_upgrade = evaluate_logic(options_apply_logic[option_num], runner)
          if apply_option_upgrade.nil?
            return false
          end
        end

        if not apply_option_upgrade
          runner.registerInfo("Parameter #{parameter_name}, Option #{option_name} will not be applied.")
          next
        end

        # Print this option assignment
        print_option_assignment(parameter_name, option_name, runner)

        # Register cost names/values/multipliers/lifetime for applied options; used by the UpgradeCosts measure
        register_value(runner, 'option_%02d_name_applied' % option_num, option)
        for cost_num in 1..num_costs_per_option
          cost_value = runner.getOptionalDoubleArgumentValue("option_#{option_num}_cost_#{cost_num}_value", user_arguments)
          if cost_value.nil?
            cost_value = 0.0
          end
          cost_mult_type = runner.getStringArgumentValue("option_#{option_num}_cost_#{cost_num}_multiplier", user_arguments)
          register_value(runner, "option_%02d_cost_#{cost_num}_value_to_apply" % option_num, cost_value.to_s)
          register_value(runner, "option_%02d_cost_#{cost_num}_multiplier_to_apply" % option_num, cost_mult_type)
        end
        lifetime = runner.getOptionalDoubleArgumentValue("option_#{option_num}_lifetime", user_arguments)
        if lifetime.nil?
          lifetime = 0.0
        end
        register_value(runner, 'option_%02d_lifetime_to_apply' % option_num, lifetime.to_s)

        # Get measure name and arguments associated with the option
        options_measure_args, _errors = get_measure_args_from_option_names(lookup_csv_data, [option_name], parameter_name, lookup_file, runner)
        options_measure_args[option_name].each do |measure_subdir, args_hash|
          update_args_hash(measures, measure_subdir, args_hash)
          update_args_hash(measures, 'ResStockArgumentsPostHPXML', args_hash) if measure_subdir == 'ResStockArguments'
        end
      end

      # Check the size of the measures hash at this point, and halt the workflow if it's empty
      if halt_workflow(model, runner, measures)
        return false
      end

      # Check if upgrade is via another measure
      if !measures.keys.include?('ResStockArguments')
        measures['ResStockArguments'] = [{}]
      end
      if !measures.keys.include?('ResStockArgumentsPostHPXML')
        measures['ResStockArgumentsPostHPXML'] = [{}]
      end

      # Add measure arguments from existing building if needed
      parameters = get_parameters_ordered_from_options_lookup_tsv(lookup_csv_data, characteristics_dir)
      measures.keys.each do |measure_subdir|
        parameters.each do |parameter_name|
          existing_option_name = values[OpenStudio::toUnderscoreCase(parameter_name)]

          options_measure_args, _errors = get_measure_args_from_option_names(lookup_csv_data, [existing_option_name], parameter_name, lookup_file, runner)
          existing_options_measure_args[parameter_name] = options_measure_args[existing_option_name]
          existing_options_measure_args[parameter_name].each do |measure_subdir2, args_hash|
            next if measure_subdir != measure_subdir2

            # Append any new arguments
            new_args_hash = {}
            args_hash.each do |k, v|
              next if measures[measure_subdir][0].has_key?(k)

              new_args_hash[k] = v
            end
            update_args_hash(measures, measure_subdir, new_args_hash)
            update_args_hash(measures, 'ResStockArgumentsPostHPXML', new_args_hash) if measure_subdir == 'ResStockArguments'
          end
        end
      end

      # Run the ResStockArguments measure
      measures['ResStockArguments'][0]['building_id'] = values['building_id']
      if not apply_measures(measures_dir, { 'ResStockArguments' => measures['ResStockArguments'] }, resstock_arguments_runner, model, true, 'OpenStudio::Measure::ModelMeasure', 'upgraded.osw')
        register_logs(runner, resstock_arguments_runner)
        return false
      end
    end # apply_package_upgrade

    # Register the upgrade name
    register_value(runner, 'upgrade_name', args[:upgrade_name])

    if halt_workflow(model, runner, measures)
      return false
    end

    # Set arguments for the BuildResidentialHPXML measure
    hpxml_path = File.expand_path('../upgraded.xml')
    measures['BuildResidentialHPXML'] = [{ 'hpxml_path' => hpxml_path }]

    set_header(measures, hpxml, values)
    set_building_header(measures)
    set_battery(measures, hpxml)

    new_runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    hpxml.buildings.each_with_index do |hpxml_bldg, unit_number|
      if unit_number > 0
        measures['BuildResidentialHPXML'][0]['existing_hpxml_path'] = hpxml_path
      end

      set_resstock_arguments(measures, resstock_arguments_runner)
      set_building_construction(measures, hpxml_bldg)
      set_dehumidifier(measures, hpxml_bldg)
      get_hvac_systems(measures, existing_options_measure_args)

      # Specify measures to run
      measures_hash = { 'BuildResidentialHPXML' => measures['BuildResidentialHPXML'] }
      if not apply_measures(hpxml_measures_dir, measures_hash, new_runner, model, true, 'OpenStudio::Measure::ModelMeasure', nil)
        register_logs(runner, new_runner)
        return false
      end
    end

    # Set arguments for the BuildResidentialScheduleFile measure
    measures['BuildResidentialScheduleFile'] = [{ 'hpxml_path' => hpxml_path,
                                                  'hpxml_output_path' => hpxml_path,
                                                  'schedules_random_seed' => values['building_id'],
                                                  'output_csv_path' => File.expand_path('../schedules.csv'),
                                                  'building_id' => 'ALL' }]

    # Specify measures to run
    measures_hash = { 'BuildResidentialScheduleFile' => measures['BuildResidentialScheduleFile'] }
    if not apply_measures(hpxml_measures_dir, measures_hash, new_runner, model, true, 'OpenStudio::Measure::ModelMeasure', nil)
      register_logs(runner, new_runner)
      return false
    end

    # Set arguments for the ResStockArgumentsPostHPXML measure
    measures['ResStockArgumentsPostHPXML'][0]['hpxml_path'] = hpxml_path
    measures['ResStockArgumentsPostHPXML'][0]['building_id'] = values['building_id']
    measures_hash = { 'ResStockArgumentsPostHPXML' => measures['ResStockArgumentsPostHPXML'] }
    if not apply_measures(measures_dir, measures_hash, new_runner, model, true, 'OpenStudio::Measure::ModelMeasure', nil)
      register_logs(runner, new_runner)
      return false
    end

    # Specify measures to run
    measures_to_apply_hash = { measures_dir => {} }

    upgrade_measures = measures.keys - ['ResStockArguments', 'BuildResidentialHPXML', 'BuildResidentialScheduleFile', 'ResStockArgumentsPostHPXML']
    upgrade_measures.each do |upgrade_measure|
      measures_to_apply_hash[measures_dir][upgrade_measure] = measures[upgrade_measure]
    end
    measures_to_apply_hash.each_with_index do |(dir, measures_to_apply), i|
      next if measures_to_apply.empty?

      osw_out = 'upgraded.osw'
      osw_out = "upgraded#{i + 1}.osw" if i > 0
      next if apply_measures(dir, measures_to_apply, new_runner, model, true, 'OpenStudio::Measure::ModelMeasure', osw_out)

      register_logs(runner, new_runner)
      return false
    end

    # Copy upgraded.xml to home.xml for downstream HPXMLtoOpenStudio
    # This will overwrite home.xml from BuildExistingModel
    # We need upgraded.xml (and not just home.xml) for UpgradeCosts
    in_path = File.expand_path('../home.xml')
    FileUtils.cp(hpxml_path, in_path)

    register_logs(runner, resstock_arguments_runner)
    register_logs(runner, new_runner)

    return true
  end

  def halt_workflow(model, runner, measures)
    if measures.size == 0
      # Upgrade not applied; don't re-run existing home simulation
      FileUtils.rm_rf(File.expand_path('../existing.osw'))
      FileUtils.rm_rf(File.expand_path('../existing.xml'))
      runner.haltWorkflow('Invalid')
      # If we made it here, HPXMLtoOpenStudio will be skipped.
      # Therefore, neither in.osm nor home.xml will reflect the upgraded home.
      # So we may as well strip/delete them.
      # The workflow gem prevents us from removing in.osm/in.idf entirely.
      Model.reset(runner, model)
      FileUtils.rm_rf(File.expand_path('../home.xml'))
      return true
    end

    return false
  end

  def set_header(measures, hpxml, values)
    # Whole SFA/MF Building Simulation?
    measures['BuildResidentialHPXML'][0]['whole_sfa_or_mf_building_sim'] = hpxml.header.whole_sfa_or_mf_building_sim

    # Simulation Control
    measures['BuildResidentialHPXML'][0]['simulation_control_timestep'] = values['simulation_control_timestep']
    if !values['simulation_control_run_period_begin_month'].nil? && !values['simulation_control_run_period_begin_day_of_month'].nil? && !values['simulation_control_run_period_end_month'].nil? && !values['simulation_control_run_period_end_day_of_month'].nil?
      begin_month = "#{Date::ABBR_MONTHNAMES[values['simulation_control_run_period_begin_month']]}"
      begin_day = values['simulation_control_run_period_begin_day_of_month']
      end_month = "#{Date::ABBR_MONTHNAMES[values['simulation_control_run_period_end_month']]}"
      end_day = values['simulation_control_run_period_end_day_of_month']
      measures['BuildResidentialHPXML'][0]['simulation_control_run_period'] = "#{begin_month} #{begin_day} - #{end_month} #{end_day}"
    end
    measures['ResStockArgumentsPostHPXML'][0]['simulation_control_run_period_calendar_year'] = values['simulation_control_run_period_calendar_year']

    # Emissions
    if values.keys.include?('emissions_electricity_filepaths')
      values.each do |arg, value|
        next unless arg.start_with? 'emissions'
        next if arg == 'emissions_electricity_folders'

        measures['ResStockArgumentsPostHPXML'][0][arg] = value
      end
    end

    # Utility Bills
    values.each do |arg, value|
      next unless arg.start_with? 'utility_bill'
      next if ['utility_bill_simple_filepaths', 'utility_bill_detailed_filepaths'].include? arg

      measures['ResStockArgumentsPostHPXML'][0][arg] = value
    end
  end

  def set_resstock_arguments(measures, child_runner)
    # Assign ResStockArgument's runner arguments to BuildResidentialHPXML
    child_runner.result.stepValues.each do |step_value|
      next unless measures['BuildResidentialHPXML'][0][step_value.name].nil?

      value = get_value_from_workflow_step_value(step_value)
      next if value == ''

      measures['BuildResidentialHPXML'][0][step_value.name] = value
    end
  end

  def set_building_construction(measures, hpxml_bldg)
    if hpxml_bldg.building_construction.number_of_units > 1
      measures['BuildResidentialHPXML'][0]['unit_multiplier'] = hpxml_bldg.building_construction.number_of_units
    end
  end

  def set_building_header(measures)
    additional_properties = []
    ['ceiling_insulation_r'].each do |arg_name|
      arg_value = measures['ResStockArguments'][0][arg_name]
      additional_properties << "#{arg_name}=#{arg_value}"
    end
    measures['BuildResidentialHPXML'][0]['additional_properties'] = additional_properties.join('|') unless additional_properties.empty?
  end

  def set_dehumidifier(measures, hpxml_bldg)
    if hpxml_bldg.building_construction.number_of_units > 1
      measures['BuildResidentialHPXML'][0]['appliance_dehumidifier'] = 'None' # limitation of OS-HPXML
    end
  end

  def set_battery(measures, hpxml)
    if hpxml.header.whole_sfa_or_mf_building_sim && hpxml.buildings.size > 1
      measures['BuildResidentialHPXML'][0]['battery'] = 'None' # limitation of OS-HPXML
    end
  end

  def get_detailed_hvac_arguments(measures)
    # Returns a hash of detailed option properties (from the option TSV) for the given HVAC systems
    args = {}
    ['hvac_heating_system',
     'hvac_heating_system_2',
     'hvac_cooling_system',
     'hvac_heat_pump'].each do |parameter_name|
      tsv_filename = "#{parameter_name}.tsv"
      get_option_properties(args, tsv_filename, measures['ResStockArguments'][0][parameter_name])
    end
    return args
  end

  def get_hvac_systems(measures, existing_options_measure_args)
    # Record the existing HVAC system(s) so that downstream we can determine whether
    # to retain capacities and autosizing factors.
    #
    # This information is on runner but not new_runner; so recording these are necessary.
    existing_options_measure_args.each do |_parameter_name, measure_args|
      next if measure_args.empty?

      measure_args['ResStockArguments'].each do |arg, value|
        if arg == 'hvac_heating_system'
          measures['ResStockArgumentsPostHPXML'][0]['hvac_heating_system_existing'] = value
        elsif arg == 'hvac_cooling_system'
          measures['ResStockArgumentsPostHPXML'][0]['hvac_cooling_system_existing'] = value
        elsif arg == 'hvac_heat_pump'
          measures['ResStockArgumentsPostHPXML'][0]['hvac_heat_pump_existing'] = value
        elsif arg == 'hvac_heating_system_2'
          measures['ResStockArgumentsPostHPXML'][0]['hvac_heating_system_2_existing'] = value
        end
      end
    end
  end
end

# register the measure to be used by the application
ApplyUpgrade.new.registerWithApplication
