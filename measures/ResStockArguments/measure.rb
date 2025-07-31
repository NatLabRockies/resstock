# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require_relative 'resources/constants'
require_relative 'resources/electrical_panel'
require_relative '../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/meta_measure'
require_relative '../../resources/hpxml-measures/BuildResidentialHPXML/resources/options'

# start the measure
class ResStockArguments < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'ResStock Arguments'
  end

  # human readable description
  def description
    return 'Measure that pre-processes the arguments passed to the BuildResidentialHPXML and BuildResidentialScheduleFile measures.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Passes in all ResStockArguments arguments from the options lookup, processes them, and then registers values to the runner to be used by other measures.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # BuildResidentialHPXML

    measures_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../resources/hpxml-measures'))
    full_measure_path = File.join(measures_dir, 'BuildResidentialHPXML', 'measure.rb')
    @build_residential_hpxml_measure_arguments = get_measure_instance(full_measure_path).arguments(model)

    @build_residential_hpxml_measure_arguments.each do |arg|
      next if Constants::BuildResidentialHPXMLExcludes.include? arg.name

      # Convert optional arguments to string arguments that allow Constants::Auto for defaulting
      if !arg.required
        case arg.type.valueName.downcase
        when 'choice'
          choices = arg.choiceValues.map(&:to_s)
          choices.unshift(Constants::Auto)
          new_arg = OpenStudio::Measure::OSArgument.makeChoiceArgument(arg.name, choices, false)
        when 'boolean'
          choices = [Constants::Auto, 'true', 'false']
          new_arg = OpenStudio::Measure::OSArgument.makeChoiceArgument(arg.name, choices, false)
        else
          new_arg = OpenStudio::Measure::OSArgument.makeStringArgument(arg.name, false)
        end
        new_arg.setDisplayName(arg.displayName.to_s)
        new_arg.setDescription(arg.description.to_s)
        new_arg.setUnits(arg.units.to_s)
        args << new_arg
      else
        args << arg
      end
    end

    # BuildResidentialScheduleFile

    full_measure_path = File.join(measures_dir, 'BuildResidentialScheduleFile', 'measure.rb')
    @build_residential_schedule_file_measure_arguments = get_measure_instance(full_measure_path).arguments(model)

    @build_residential_schedule_file_measure_arguments.each do |arg|
      next if Constants::BuildResidentialScheduleFileExcludes.include? arg.name

      args << arg
    end

    # Additional arguments

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('building_id', false)
    arg.setDisplayName('Building Unit ID')
    arg.setDescription('The building unit number (between 1 and the number of samples).')
    args << arg

    unit_type_choices = OpenStudio::StringVector.new
    unit_type_choices << HPXML::ResidentialTypeSFD
    unit_type_choices << HPXML::ResidentialTypeSFA
    unit_type_choices << HPXML::ResidentialTypeApartment
    unit_type_choices << HPXML::ResidentialTypeManufactured

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('geometry_unit_type', unit_type_choices, true)
    arg.setDisplayName('Unit Type')
    arg.setDescription('The type of dwelling unit.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('geometry_building_num_units', false)
    arg.setDisplayName('Building Number of Units')
    arg.setUnits('#')
    arg.setDescription('The number of units in the building.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('schedules_space_heating_unavailable_days', false)
    arg.setDisplayName('Schedules: Space Heating Unavailability')
    arg.setDescription('Number of days space heating equipment is unavailable.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('schedules_space_cooling_unavailable_days', false)
    arg.setDisplayName('Schedules: Space Cooling Unavailability')
    arg.setDescription('Number of days space cooling equipment is unavailable.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('geometry_unit_cfa_bin', true)
    arg.setDisplayName('Geometry: Unit Conditioned Floor Area Bin')
    arg.setDescription("E.g., '2000-2499'.")
    arg.setDefaultValue('2000-2499')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('geometry_unit_cfa', true)
    arg.setDisplayName('Geometry: Unit Conditioned Floor Area')
    arg.setDescription("The total floor area of the unit's conditioned space (including any conditioned basement floor area). E.g., '2000' or '#{Constants::Auto}'.")
    arg.setUnits('ft^2')
    arg.setDefaultValue('2000')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('vintage', false)
    arg.setDisplayName('Building Construction: Vintage')
    arg.setDescription('The building vintage, used for informational purposes only.')
    args << arg

    level_choices = OpenStudio::StringVector.new
    level_choices << 'Bottom'
    level_choices << 'Middle'
    level_choices << 'Top'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('geometry_unit_level', level_choices, false)
    arg.setDisplayName('Geometry: Unit Level')
    arg.setDescription("The level of the unit. This is required for #{HPXML::ResidentialTypeApartment}s.")
    args << arg

    horizontal_location_choices = OpenStudio::StringVector.new
    horizontal_location_choices << 'None'
    horizontal_location_choices << 'Left'
    horizontal_location_choices << 'Middle'
    horizontal_location_choices << 'Right'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('geometry_unit_horizontal_location', horizontal_location_choices, false)
    arg.setDisplayName('Geometry: Unit Horizontal Location')
    arg.setDescription("The horizontal location of the unit when viewing the front of the building. This is required for #{HPXML::ResidentialTypeSFA} and #{HPXML::ResidentialTypeApartment}s.")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('geometry_num_floors_above_grade', true)
    arg.setDisplayName('Geometry: Number of Floors Above Grade')
    arg.setUnits('#')
    arg.setDescription("The number of floors above grade (in the unit if #{HPXML::ResidentialTypeSFD} or #{HPXML::ResidentialTypeSFA}, and in the building if #{HPXML::ResidentialTypeApartment}). Conditioned attics are included.")
    arg.setDefaultValue(2)
    args << arg

    corridor_position_choices = OpenStudio::StringVector.new
    corridor_position_choices << 'Double-Loaded Interior'
    corridor_position_choices << 'Double Exterior'
    corridor_position_choices << 'Single Exterior (Front)'
    corridor_position_choices << 'None'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('geometry_corridor_position', corridor_position_choices, true)
    arg.setDisplayName('Geometry: Corridor Position')
    arg.setDescription("The position of the corridor. Only applies to #{HPXML::ResidentialTypeSFA} and #{HPXML::ResidentialTypeApartment}s. Exterior corridors are shaded, but not enclosed. Interior corridors are enclosed and conditioned.")
    arg.setDefaultValue('Inside')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('geometry_corridor_width', true)
    arg.setDisplayName('Geometry: Corridor Width')
    arg.setUnits('ft')
    arg.setDescription("The width of the corridor. Only applies to #{HPXML::ResidentialTypeApartment}s.")
    arg.setDefaultValue(10.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_heating_weekday_setpoint_temp', true)
    arg.setDisplayName('Heating Setpoint: Weekday Temperature')
    arg.setDescription('Specify the weekday heating setpoint temperature.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(71)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_heating_weekend_setpoint_temp', true)
    arg.setDisplayName('Heating Setpoint: Weekend Temperature')
    arg.setDescription('Specify the weekend heating setpoint temperature.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(71)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_heating_weekday_setpoint_offset_magnitude', true)
    arg.setDisplayName('Heating Setpoint: Weekday Offset Magnitude')
    arg.setDescription('Specify the weekday heating offset magnitude.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_heating_weekend_setpoint_offset_magnitude', true)
    arg.setDisplayName('Heating Setpoint: Weekend Offset Magnitude')
    arg.setDescription('Specify the weekend heating offset magnitude.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('hvac_control_heating_weekday_setpoint_schedule', true)
    arg.setDisplayName('Heating Setpoint: Weekday Schedule')
    arg.setDescription('Specify the 24-hour comma-separated weekday heating schedule of 0s and 1s.')
    arg.setDefaultValue('0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('hvac_control_heating_weekend_setpoint_schedule', true)
    arg.setDisplayName('Heating Setpoint: Weekend Schedule')
    arg.setDescription('Specify the 24-hour comma-separated weekend heating schedule of 0s and 1s.')
    arg.setDefaultValue('0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('use_auto_heating_season', true)
    arg.setDisplayName('Use Auto Heating Season')
    arg.setDescription('Specifies whether to automatically define the heating season based on the weather file.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_cooling_weekday_setpoint_temp', true)
    arg.setDisplayName('Cooling Setpoint: Weekday Temperature')
    arg.setDescription('Specify the weekday cooling setpoint temperature.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(76)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_cooling_weekend_setpoint_temp', true)
    arg.setDisplayName('Cooling Setpoint: Weekend Temperature')
    arg.setDescription('Specify the weekend cooling setpoint temperature.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(76)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_cooling_weekday_setpoint_offset_magnitude', true)
    arg.setDisplayName('Cooling Setpoint: Weekday Offset Magnitude')
    arg.setDescription('Specify the weekday cooling offset magnitude.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_cooling_weekend_setpoint_offset_magnitude', true)
    arg.setDisplayName('Cooling Setpoint: Weekend Offset Magnitude')
    arg.setDescription('Specify the weekend cooling offset magnitude.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('hvac_control_cooling_weekday_setpoint_schedule', true)
    arg.setDisplayName('Cooling Setpoint: Weekday Schedule')
    arg.setDescription('Specify the 24-hour comma-separated weekday cooling schedule of 0s and 1s.')
    arg.setDefaultValue('0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('hvac_control_cooling_weekend_setpoint_schedule', true)
    arg.setDisplayName('Cooling Setpoint: Weekend Schedule')
    arg.setDescription('Specify the 24-hour comma-separated weekend cooling schedule of 0s and 1s.')
    arg.setDefaultValue('0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('use_auto_cooling_season', true)
    arg.setDisplayName('Use Auto Cooling Season')
    arg.setDescription('Specifies whether to automatically define the cooling season based on the weather file.')
    arg.setDefaultValue(false)
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

    # assign the user inputs to variables
    args = runner.getArgumentValues(arguments(model), user_arguments)
    args = convert_args(args)

    # collect arguments for deletion
    arg_names = []
    { @build_residential_hpxml_measure_arguments => Constants::BuildResidentialHPXMLExcludes,
      @build_residential_schedule_file_measure_arguments => Constants::BuildResidentialScheduleFileExcludes }.each do |measure_arguments, measure_excludes|
      measure_arguments.each do |arg|
        next if measure_excludes.include? arg.name

        arg_names << arg.name.to_sym
      end
    end

    args_to_delete = args.keys - arg_names # these are the extra ones added in the arguments section

    new_arg_keys = update_args_hash_with_detailed_properties(args: args)

    # Conditioned floor area
    if args[:geometry_unit_cfa] == Constants::Auto
      # TODO: Disaggregate detached and mobile home
      cfas = { ['0-499', HPXML::ResidentialTypeSFD] => 298, # AHS 2021, 1 detached and mobile home weighted average
               ['0-499', HPXML::ResidentialTypeSFA] => 273, # AHS 2021, 1 attached
               ['0-499', HPXML::ResidentialTypeApartment] => 322, # AHS 2021, multi-family weighted average
               ['0-499', HPXML::ResidentialTypeManufactured] => 298, # AHS 2021, 1 detached and mobile home weighted average
               ['500-749', HPXML::ResidentialTypeSFD] => 634, # AHS 2021, 1 detached and mobile home weighted average
               ['500-749', HPXML::ResidentialTypeSFA] => 625, # AHS 2021, 1 attached
               ['500-749', HPXML::ResidentialTypeApartment] => 623, # AHS 2021, multi-family weighted average
               ['500-749', HPXML::ResidentialTypeManufactured] => 634, # AHS 2021, 1 detached and mobile home weighted average
               ['750-999', HPXML::ResidentialTypeSFD] => 881, # AHS 2021, 1 detached and mobile home weighted average
               ['750-999', HPXML::ResidentialTypeSFA] => 872, # AHS 2021, 1 attached
               ['750-999', HPXML::ResidentialTypeApartment] => 854, # AHS 2021, multi-family weighted average
               ['750-999', HPXML::ResidentialTypeManufactured] => 881, # AHS 2021, 1 detached and mobile home weighted average
               ['1000-1499', HPXML::ResidentialTypeSFD] => 1228, # AHS 2021, 1 detached and mobile home weighted average
               ['1000-1499', HPXML::ResidentialTypeSFA] => 1207, # AHS 2021, 1 attached
               ['1000-1499', HPXML::ResidentialTypeApartment] => 1138, # AHS 2021, multi-family weighted average
               ['1000-1499', HPXML::ResidentialTypeManufactured] => 1228, # AHS 2021, 1 detached and mobile home weighted average
               ['1500-1999', HPXML::ResidentialTypeSFD] => 1698, # AHS 2021, 1 detached and mobile home weighted average
               ['1500-1999', HPXML::ResidentialTypeSFA] => 1678, # AHS 2021, 1 attached
               ['1500-1999', HPXML::ResidentialTypeApartment] => 1682, # AHS 2021, multi-family weighted average
               ['1500-1999', HPXML::ResidentialTypeManufactured] => 1698, # AHS 2021, 1 detached and mobile home weighted average
               ['2000-2499', HPXML::ResidentialTypeSFD] => 2179, # AHS 2021, 1 detached and mobile home weighted average
               ['2000-2499', HPXML::ResidentialTypeSFA] => 2152, # AHS 2021, 1 attached
               ['2000-2499', HPXML::ResidentialTypeApartment] => 2115, # AHS 2021, multi-family weighted average
               ['2000-2499', HPXML::ResidentialTypeManufactured] => 2179, # AHS 2021, 1 detached and mobile home weighted average
               ['2500-2999', HPXML::ResidentialTypeSFD] => 2678, # AHS 2021, 1 detached and mobile home weighted average
               ['2500-2999', HPXML::ResidentialTypeSFA] => 2663, # AHS 2021, 1 attached
               ['2500-2999', HPXML::ResidentialTypeApartment] => 2648, # AHS 2021, multi-family weighted average
               ['2500-2999', HPXML::ResidentialTypeManufactured] => 2678, # AHS 2021, 1 detached and mobile home weighted average
               ['3000-3999', HPXML::ResidentialTypeSFD] => 3310, # AHS 2021, 1 detached and mobile home weighted average
               ['3000-3999', HPXML::ResidentialTypeSFA] => 3228, # AHS 2021, 1 attached
               ['3000-3999', HPXML::ResidentialTypeApartment] => 3171, # AHS 2021, multi-family weighted average
               ['3000-3999', HPXML::ResidentialTypeManufactured] => 3310, # AHS 2021, 1 detached and mobile home weighted average
               ['4000+', HPXML::ResidentialTypeSFD] => 5587, # AHS 2021, 1 detached and mobile home weighted average
               ['4000+', HPXML::ResidentialTypeSFA] => 7414, # AHS 2019, 1 attached
               ['4000+', HPXML::ResidentialTypeApartment] => 6348, # AHS 2021, 4,000 or more all unit average
               ['4000+', HPXML::ResidentialTypeManufactured] => 5587 } # AHS 2021, 1 detached and mobile home weighted average
      cfa = cfas[[args[:geometry_unit_cfa_bin], args[:geometry_unit_type]]]
      if cfa.nil?
        runner.registerError("ResStockArguments: Could not look up conditioned floor area for '#{args[:geometry_unit_cfa_bin]}' and '#{args[:geometry_unit_type]}'.")
        return false
      end
      args[:geometry_unit_conditioned_floor_area] = Float(cfa)
    else
      args[:geometry_unit_conditioned_floor_area] = args[:geometry_unit_cfa]
    end

    # Vintage
    if !args[:vintage].nil? && args[:building_year_built] == Constants::Auto
      args[:building_year_built] = Integer(Float(args[:vintage].gsub(/[^0-9]/, ''))) # strip non-numeric
    end

    # Num Occupants
    if args[:geometry_unit_num_occupants] == Constants::Auto
      args[:geometry_unit_num_occupants] = Geometry.get_occupancy_default_num(args[:geometry_unit_num_bedrooms])
    end

    # Plug Loads
    args[:misc_plug_loads_television_usage_multiplier] = args[:misc_plug_loads_television_usage_multiplier]
    args[:misc_plug_loads_other_usage_multiplier] = args[:misc_plug_loads_other_usage_multiplier]
    args[:misc_plug_loads_well_pump_usage_multiplier] = args[:misc_plug_loads_well_pump_usage_multiplier]
    args[:misc_plug_loads_vehicle_present] = false

    # HVAC Setpoints
    [Constants::Heating, Constants::Cooling].each do |htg_or_clg|
      [Constants::Weekday, Constants::Weekend].each do |wkdy_or_wked|
        schedule = [args["hvac_control_#{htg_or_clg}_#{wkdy_or_wked}_setpoint_temp".to_sym]] * 24

        hvac_control_setpoint_offset_magnitude = args["hvac_control_#{htg_or_clg}_#{wkdy_or_wked}_setpoint_offset_magnitude".to_sym]
        hvac_control_setpoint_schedule = args["hvac_control_#{htg_or_clg}_#{wkdy_or_wked}_setpoint_schedule".to_sym].split(',').map { |i| Float(i) }
        schedule = modify_setpoint_schedule(schedule, hvac_control_setpoint_offset_magnitude, hvac_control_setpoint_schedule)

        args["hvac_control_#{htg_or_clg}_#{wkdy_or_wked}_setpoint".to_sym] = schedule.join(', ')
      end
    end

    # HVAC Seasons
    [Constants::Heating, Constants::Cooling].each do |htg_or_clg|
      use_auto_season = "use_auto_#{htg_or_clg}_season".to_sym
      hvac_control_season_period = "hvac_control_#{htg_or_clg}_season_period".to_sym
      if args[use_auto_season] && (args[hvac_control_season_period] == Constants::Auto)
        args[hvac_control_season_period] = Constants::BuildingAmerica
      end
    end

    # HVAC Unavailability
    if (args[:schedules_space_heating_unavailable_days] > 0) || (args[:schedules_space_cooling_unavailable_days] > 0)
      epw_path = File.absolute_path(File.join(File.dirname(__FILE__), '../../weather', File.basename(args[:weather_station_epw_filepath])))
      if not File.exist? epw_path
        runner.registerError("ResStockArguments: Could not find EPW file at '#{epw_path}'.")
        return false
      end
      weather = WeatherFile.new(epw_path: epw_path, runner: nil)

      heating_months, cooling_months, sim_calendar_year = get_heating_and_cooling_seasons(args, weather)
    end

    [Constants::Heating, Constants::Cooling].each do |htg_or_clg|
      unavailable_days = args["schedules_space_#{htg_or_clg}_unavailable_days".to_sym]
      unavailable_period = "#{htg_or_clg}_unavailable_period"
      args[unavailable_period] = 'Never'

      next unless unavailable_days > 0

      if unavailable_days < 365 # partial-year unavailability
        if htg_or_clg == Constants::Heating
          months = heating_months
        elsif htg_or_clg == Constants::Cooling
          months = cooling_months
        end

        if months.sum > 0 # has defined BA heating/cooling months
          begin_month, begin_day, end_month, end_day = Calendar.get_begin_and_end_dates_from_monthly_array(months, sim_calendar_year)
        else # no defined BA heating/cooling months
          if htg_or_clg == Constants::Heating # Dec/Jan/Feb
            begin_month, begin_day, end_month, end_day = 12, 1, 2, 28
            end_day += 1 if Date.leap?(sim_calendar_year)
          elsif htg_or_clg == Constants::Cooling # Jun/Jul/Aug
            begin_month, begin_day, end_month, end_day = 6, 1, 8, 31
          end
        end

        begin_day_num = Calendar.get_day_num_from_month_day(sim_calendar_year, begin_month, begin_day)
        end_day_num = Calendar.get_day_num_from_month_day(sim_calendar_year, end_month, end_day)

        unavail_begin_day_num, unavail_end_day_num = get_begin_end_day_nums(args[:building_id], unavailable_days, begin_day_num, end_day_num, sim_calendar_year)
      else # year-round unavailability
        unavail_begin_day_num, unavail_end_day_num = 1, 365
        unavail_end_day_num += 1 if Date.leap?(sim_calendar_year)
      end

      unavail_begin_date = get_month_day_from_day_num(unavail_begin_day_num, sim_calendar_year)
      unavail_end_date = get_month_day_from_day_num(unavail_end_day_num, sim_calendar_year)
      unavailable_period_dates = "#{unavail_begin_date} - #{unavail_end_date}"
      args[unavailable_period] = unavailable_period_dates

      schedules_unavailable_period_types << "No Space #{htg_or_clg.capitalize}"
      schedules_unavailable_period_dates << unavailable_period_dates
      schedules_unavailable_period_window_natvent_availabilities << ''
    end

    args[:schedules_unavailable_period_types] = schedules_unavailable_period_types.join(', ')
    args[:schedules_unavailable_period_dates] = schedules_unavailable_period_dates.join(', ')
    args[:schedules_unavailable_period_window_natvent_availabilities] = schedules_unavailable_period_window_natvent_availabilities.join(', ')

    # HVAC Secondary
    if args[:heating_system_2_type] != 'none'
      if args[:heating_system_type] != 'none'
        if ((args[:heating_system_fraction_heat_load_served] + args[:heating_system_2_fraction_heat_load_served]) > 1.0)
          info_msg = "Adjusted fraction of heat load served by the primary heating system (#{args[:heating_system_fraction_heat_load_served]}"
          args[:heating_system_fraction_heat_load_served] = 1.0 - args[:heating_system_2_fraction_heat_load_served]
          info_msg += " to #{args[:heating_system_fraction_heat_load_served]}) to allow for a secondary heating system (#{args[:heating_system_2_fraction_heat_load_served]})."
          runner.registerInfo(info_msg)
        end
      elsif args[:heat_pump_type] != 'none'
        if ((args[:heat_pump_fraction_heat_load_served] + args[:heating_system_2_fraction_heat_load_served]) > 1.0)
          info_msg = "Adjusted fraction of heat load served by the primary heating system (#{args[:heat_pump_fraction_heat_load_served]}"
          args[:heat_pump_fraction_heat_load_served] = 1.0 - args[:heating_system_2_fraction_heat_load_served]
          info_msg += " to #{args[:heat_pump_fraction_heat_load_served]}) to allow for a secondary heating system (#{args[:heating_system_2_fraction_heat_load_served]})."
          runner.registerInfo(info_msg)
        end
      end
    end

    # Error check geometry inputs
    corridor_width = args[:geometry_corridor_width]
    corridor_position = args[:geometry_corridor_position]

    if (corridor_width == 0) && (corridor_position != 'None')
      corridor_position = 'None'
    end
    if corridor_position == 'None'
      corridor_width = 0
    end
    if corridor_width < 0
      runner.registerError('ResStockArguments: Invalid corridor width entered.')
      return false
    end

    # Adiabatic Walls
    fblr_walls_are_adiabatic = [false, false, false, false]

    # Map corridor arguments to adiabatic walls and shading
    if [HPXML::ResidentialTypeApartment, HPXML::ResidentialTypeSFA].include? args[:geometry_unit_type]
      n_floors = Float(args[:geometry_num_floors_above_grade])
      n_units = Float(args[:geometry_building_num_units])
      horiz_location = args[:geometry_unit_horizontal_location]

      if args[:geometry_unit_type] == HPXML::ResidentialTypeApartment
        n_units_per_floor = n_units / n_floors
        has_rear_units = false
        if n_units_per_floor >= 4 && (corridor_position == 'Double Exterior' || corridor_position == 'None')
          has_rear_units = true
          fblr_walls_are_adiabatic[0] = true # front
        elsif n_units_per_floor >= 4 && (corridor_position == 'Double-Loaded Interior')
          has_rear_units = true
          fblr_walls_are_adiabatic[0] = true # front
        elsif (n_units_per_floor == 2) && (horiz_location == 'None') && (corridor_position == 'Double Exterior' || corridor_position == 'None')
          has_rear_units = true
          fblr_walls_are_adiabatic[1] = true # back
        elsif (n_units_per_floor == 2) && (horiz_location == 'None') && (corridor_position == 'Double-Loaded Interior')
          has_rear_units = true
          fblr_walls_are_adiabatic[0] = true # front
        end

        # Error check MF & SFA geometry
        if !has_rear_units && ((corridor_position == 'Double-Loaded Interior') || (corridor_position == 'Double Exterior'))
          corridor_position = 'Single Exterior (Front)'
          runner.registerWarning("Specified incompatible corridor; setting corridor position to '#{corridor_position}'.")
        end

        # Model exterior corridors as overhangs
        if (corridor_position.include? 'Exterior') && corridor_width > 0
          args[:overhangs_front_depth] = corridor_width
          args[:overhangs_front_distance_to_top_of_window] = 1
        end

      elsif args[:geometry_unit_type] == HPXML::ResidentialTypeSFA
        n_units_per_floor = n_units
        has_rear_units = false
      end

      if has_rear_units
        unit_width = n_units_per_floor / 2
      else
        unit_width = n_units_per_floor
      end
      if (unit_width <= 1) && (horiz_location != 'None')
        runner.registerWarning("No #{horiz_location} location exists, setting horizontal location to 'None'")
        horiz_location = 'None'
      end
      if (unit_width > 1) && (horiz_location == 'None')
        runner.registerError('ResStockArguments: Specified incompatible horizontal location for the corridor and unit configuration.')
        return false
      end
      if (unit_width <= 2) && (horiz_location == 'Middle')
        runner.registerError('ResStockArguments: Invalid horizontal location entered, no middle location exists.')
        return false
      end

      if horiz_location == 'Left'
        fblr_walls_are_adiabatic[3] = true # right
      elsif horiz_location == 'Middle'
        fblr_walls_are_adiabatic[2] = true # left
        fblr_walls_are_adiabatic[3] = true # right
      elsif horiz_location == 'Right'
        fblr_walls_are_adiabatic[2] = true # left
      end
    end

    args[:geometry_attached_walls] = {
      [false, false, false, false] => 'None',
      [true, false, false, false] => '1 Side: Front',
      [false, true, false, false] => '1 Side: Back',
      [false, false, true, false] => '1 Side: Left',
      [false, false, false, true] => '1 Side: Right',
      [true, false, true, false] => '2 Sides: Front, Left',
      [true, false, false, true] => '2 Sides: Front, Right',
      [false, true, true, false] => '2 Sides: Back, Left',
      [false, true, false, true] => '2 Sides: Back, Right',
      [true, true, false, false] => '2 Sides: Front, Back',
      [false, false, true, true] => '2 Sides: Left, Right',
      [true, true, true, false] => '3 Sides: Front, Back, Left',
      [true, true, false, true] => '3 Sides: Front, Back, Right',
      [true, false, true, true] => '3 Sides: Front, Left, Right',
      [false, true, true, true] => '3 Sides: Back, Left, Right',
    }[fblr_walls_are_adiabatic]

    # Unit Type
    if args[:geometry_unit_type] == HPXML::ResidentialTypeApartment
      args[:geometry_num_floors_above_grade] = 1
    end
    stories_str = (args[:geometry_num_floors_above_grade] == 1 ? '1 Story' : "#{args[:geometry_num_floors_above_grade]} Stories")
    args[:geometry_unit_type] = "#{geometry_unit_type}, #{stories_str}"

    # Adiabatic Floor/Ceiling
    if not args[:geometry_unit_level].nil?
      if args[:geometry_unit_level] == 'Bottom'
        if args[:geometry_num_floors_above_grade] > 1 # this could be "bottom" of a 1-story building
          args[:geometry_attic_type] = HPXML::AtticTypeBelowApartment
        end
      elsif args[:geometry_unit_level] == 'Middle'
        args[:geometry_foundation_type] = HPXML::FoundationTypeAboveApartment
        args[:geometry_attic_type] = HPXML::AtticTypeBelowApartment
      elsif args[:geometry_unit_level] == 'Top'
        args[:geometry_foundation_type] = HPXML::FoundationTypeAboveApartment
      end
    end

    # Height Above Grade
    if args[:geometry_unit_type] == HPXML::ResidentialTypeApartment
      n_floors = Float(args[:geometry_num_floors_above_grade])
      avg_ceiling_height = args[:geometry_average_ceiling_height]

      if args[:geometry_unit_level] == 'Top'
        args[:geometry_unit_height_above_grade] = (n_floors - 1) * avg_ceiling_height
      elsif args[:geometry_unit_level] == 'Middle'
        args[:geometry_unit_height_above_grade] = (n_floors - 1) / 2.0 * avg_ceiling_height
      elsif args[:geometry_unit_level] == 'Bottom'
        args[:geometry_unit_height_above_grade] = Constants::Auto
      end
    else
      args[:geometry_unit_height_above_grade] = Constants::Auto
    end

    # Electric Panel
    args[:electric_panel_service_feeders_load_calculation_types] = "#{HPXML::ElectricPanelLoadCalculationType2023ExistingDwellingLoadBased}"
    # FIXME Ideas for supporting meter-based calculations in upgrades:
    # - populate the electric_panel_baseline_peak_electricity_power argument from ApplyUpgrade with values from (pre-run) baseline simulations
    # - record an additional, e.g., report_simulation_output.electric_panel_load_new, output so that we can post-process the meter-based calculation
    # args[:electric_panel_service_feeders_load_calculation_types] += ", #{HPXML::ElectricPanelLoadCalculationType2023ExistingDwellingMeterBased}"

    panel_sampler = ElectricalPanelSampler.new(runner: runner, **args)
    cap_bin, cap_val = panel_sampler.assign_rated_capacity(args: args)

    args[:electric_panel_service_max_current_rating_bin] = cap_bin
    args[:electric_panel_service_max_current_rating] = cap_val

    breaker_spaces_headroom = panel_sampler.assign_breaker_space_headroom(args: args)
    args[:electric_panel_breaker_spaces_headroom] = breaker_spaces_headroom

    # Assign miscellaneous permanently connected appliance loads
    if args[:electric_panel_load_other_power_rating].nil?
      args[:electric_panel_load_other_power_rating] = 0
    end
    # Assume all homes have a microwave
    if args[:geometry_unit_num_bedrooms] <= 2
      microwave_power = 900 # W, small, <= 0.9 cu ft, 1-2 ppl
    elsif args[:geometry_unit_num_bedrooms] <= 4
      microwave_power = 1100 # W, medium, <= 1.6 cu ft, 3-4 ppl
    else
      microwave_power = 1250 # W, large, 1.7-2.2 cu ft, 5+ ppl
    end

    garbage_disposal_ownership = 0.52 # AHS 2013
    if Random.new(args[:building_id]).rand > garbage_disposal_ownership
      garbage_disposal_power = 0
    else
      # Power estimated from avg load amp not HP rating, from InSinkErators
      if args[:geometry_unit_num_bedrooms] <= 1
        garbage_disposal_power = 672 # W, 1/3 HP, avg load 5.6A, 1-2 ppl
      elsif args[:geometry_unit_num_bedrooms] <= 3
        garbage_disposal_power = 756 # W, 1/2 HP, avg load 6.3A, 2-4 ppl
      elsif args[:geometry_unit_num_bedrooms] <= 4
        garbage_disposal_power = 1140 # W, 3/4 HP, avg load 9.5A, 3-5 ppl
      else
        garbage_disposal_power = 1224 # W, 1 HP, avg load 10.2A, 4+ ppl
      end
    end

    if args[:geometry_garage_width] == 0 && args[:geometry_garage_depth] == 0
      garage_door_power = 0
    else
      # Assume one automatic door opener if has garage, regardless of no. garages
      garage_door_power = 373 # W, 1/2 HP (1 mech HP = 745.7 W)
    end

    args[:electric_panel_load_other_power_rating] += microwave_power
    args[:electric_panel_load_other_power_rating] += garbage_disposal_power
    args[:electric_panel_load_other_power_rating] += garage_door_power

    # Register values to runner
    args.each do |arg_name, arg_value|
      next if new_arg_keys.include?(arg_name)

      if args_to_delete.include?(arg_name) || (arg_value == Constants::Auto)
        arg_value = '' # don't assign these to BuildResidentialHPXML or BuildResidentialScheduleFile
      end

      register_value(runner, arg_name.to_s, arg_value)
    end

    return true
  end

  def modify_setpoint_schedule(schedule, offset_magnitude, offset_schedule)
    offset_schedule.each_with_index do |direction, i|
      schedule[i] += offset_magnitude * direction
    end
    return schedule
  end

  def get_heating_and_cooling_seasons(args, weather)
    latitude = args[:site_latitude]
    latitude = nil if latitude == Constants::Auto
    latitude = Defaults.get_latitude(latitude, weather)

    heating_months, cooling_months = HVAC.get_building_america_hvac_seasons(weather, latitude)
    sim_calendar_year = Location.get_sim_calendar_year(nil, weather)

    return heating_months, cooling_months, sim_calendar_year
  end

  def get_begin_end_day_nums(building_id, n_days, begin_day_num, end_day_num, year)
    if begin_day_num > end_day_num
      num_days = Calendar.num_days_in_year(year)
      begin_day_nums = (begin_day_num..num_days).to_a + (1..end_day_num).to_a
    else
      begin_day_nums = (begin_day_num..end_day_num).to_a
    end

    unavail_begin_day_nums = begin_day_nums.sample(1, random: Random.new(building_id))
    unavail_begin_day_num = unavail_begin_day_nums[0]
    unavail_begin_date = OpenStudio::Date::fromDayOfYear(unavail_begin_day_num, year)
    unavail_end_date = unavail_begin_date + OpenStudio::Time.new(n_days - 1)
    unavail_end_month = unavail_end_date.monthOfYear.value
    unavail_end_day = unavail_end_date.dayOfMonth
    unavail_end_day_num = Calendar.get_day_num_from_month_day(year, unavail_end_month, unavail_end_day)

    return unavail_begin_day_num, unavail_end_day_num
  end

  def get_month_day_from_day_num(day_num, year)
    date = OpenStudio::Date::fromDayOfYear(day_num, year)
    month_names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    month_day = "#{month_names[date.monthOfYear.value - 1]} #{date.dayOfMonth}"
    return month_day
  end

  def convert_args(args)
    measure_arguments = @build_residential_hpxml_measure_arguments
    measure_arguments.each do |arg|
      arg_name = arg.name.to_sym
      value = args[arg_name]
      next if value.nil? || (value == Constants::Auto)

      case arg.type.valueName.downcase
      when 'double'
        args[arg_name] = Float(value)
      when 'integer'
        args[arg_name] = Integer(value)
      end
    end
    return args
  end

  def update_args_hash_with_detailed_properties(args:)
    # update ResStockArguments args hash w/ OS-HPXML detailed properties based on choice dropdown for options based arguments
    # makes detailed properties available in the args hash
    orig_args = args.dup

    Dir["#{File.dirname(__FILE__)}../../resources/hpxml-measures/BuildResidentialHPXML/resources/options/*.tsv"].each do |tsv_filepath|
      tsv_filename = File.basename(tsv_filepath)
      arg_name = File.basename(tsv_filename, File.extname(tsv_filename)).to_sym
      get_option_properties(args, tsv_filename, args[arg_name])
    end

    get_option_properties(args, 'heating_system.tsv', args[:heating_system])
    get_option_properties(args, 'cooling_system.tsv', args[:cooling_system])
    get_option_properties(args, 'heat_pump.tsv', args[:heat_pump])
    get_option_properties(args, 'heat_pump_backup.tsv', args[:heat_pump_backup])
    get_option_properties(args, 'heating_system_2.tsv', args[:heating_system_2])

    new_arg_keys = args.keys - orig_args.keys
    return new_arg_keys
  end
end

# register the measure to be used by the application
ResStockArguments.new.registerWithApplication
