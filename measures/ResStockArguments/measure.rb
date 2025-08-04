# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require_relative 'resources/constants'
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

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('vintage', false)
    arg.setDisplayName('Building Construction: Vintage')
    arg.setDescription('The building vintage, used for informational purposes only.')
    args << arg

    unit_type_choices = OpenStudio::StringVector.new
    unit_type_choices << HPXML::ResidentialTypeSFD
    unit_type_choices << HPXML::ResidentialTypeSFA
    unit_type_choices << HPXML::ResidentialTypeApartment
    unit_type_choices << HPXML::ResidentialTypeManufactured

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('geometry_facility_type', unit_type_choices, true)
    arg.setDisplayName('Facility Type')
    arg.setDescription('The facility type of the dwelling unit.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('geometry_building_num_units', false)
    arg.setDisplayName('Building Number of Units')
    arg.setUnits('#')
    arg.setDescription('The number of units in the building.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('ceiling_insulation_r', true)
    arg.setDisplayName('Ceiling: Insulation Nominal R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Nominal R-value for the ceiling (attic floor).')
    arg.setDefaultValue(0)
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
    corridor_position_choices << 'Single Exterior Front'
    corridor_position_choices << 'None'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('geometry_corridor_position', corridor_position_choices, true)
    arg.setDisplayName('Geometry: Corridor Position')
    arg.setDescription("The position of the corridor. Only applies to #{HPXML::ResidentialTypeSFA} and #{HPXML::ResidentialTypeApartment}s. Exterior corridors are shaded, but not enclosed. Interior corridors are enclosed and conditioned.")
    arg.setDefaultValue('Inside')
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

    # Make all the detailed properties in the option TSVs available to this measure too
    new_arg_keys = update_args_hash_with_detailed_properties(args: args)

    # Get inputs
    cfa = args[:geometry_unit_cfa]
    cfa_bin = args[:geometry_unit_cfa_bin]
    unit_type = args[:geometry_facility_type]
    vintage = args[:vintage]
    year_built = args[:building_year_built]
    n_floors = Float(args[:geometry_num_floors_above_grade])
    # avg_ceiling_height = Float(args[:geometry_ceiling_height_height])
    if [HPXML::ResidentialTypeApartment, HPXML::ResidentialTypeSFA].include? args[:geometry_facility_type]
      n_units = Float(args[:geometry_building_num_units])
      horiz_location = args[:geometry_unit_horizontal_location]
      unit_level = args[:geometry_unit_level]
    end

    # Conditioned floor area
    if cfa == Constants::Auto
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
      cfa = cfas[[cfa_bin, unit_type]]
      if cfa.nil?
        runner.registerError("ResStockArguments: Could not look up conditioned floor area for '#{cfa_bin}' and '#{unit_type}'.")
        return false
      end
      args[:geometry_unit_conditioned_floor_area] = Float(cfa)
    else
      args[:geometry_unit_conditioned_floor_area] = cfa
    end

    # Vintage
    if !vintage.nil? && year_built == Constants::Auto
      year_built = Integer(Float(vintage.gsub(/[^0-9]/, ''))) # strip non-numeric
      args[:building_year_built] = year_built
    end

    # HVAC Setpoints
    # FIXME Move to ResStockArgumentsPostHPXML?
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
    # FIXME Move to ResStockArgumentsPostHPXML?
    [Constants::Heating, Constants::Cooling].each do |htg_or_clg|
      use_auto_season = "use_auto_#{htg_or_clg}_season".to_sym
      hvac_control_season_period = "hvac_control_#{htg_or_clg}_season_period".to_sym
      if args[use_auto_season] && (args[hvac_control_season_period] == Constants::Auto)
        args[hvac_control_season_period] = Constants::BuildingAmerica
      end
    end

    # HVAC Secondary
    # FIXME Move to ResStockArgumentsPostHPXML?
    if args[:hvac_heating_system_2] != 'None'
      if args[:hvac_heating_system] != 'None'
        if ((args[:hvac_heating_system_heating_load_served].to_f + args[:hvac_heating_system_2_heating_load_served].to_f) > 1.0)
          info_msg = "Adjusted fraction of heat load served by the primary heating system (#{args[:hvac_heating_system_heating_load_served]}"
          args[:hvac_heating_system_heating_load_served] = "#{1.0 - args[:hvac_heating_system_2_heating_load_served].to_f}%"
          info_msg += " to #{args[:hvac_heating_system_heating_load_served]}) to allow for a secondary heating system (#{args[:hvac_heating_system_2_heating_load_served]})."
          runner.registerInfo(info_msg)
        end
      elsif args[:hvac_heat_pump] != 'none'
        if ((args[:hvac_heat_pump_heating_load_served].to_f + args[:hvac_heating_system_2_heating_load_served].to_f) > 1.0)
          info_msg = "Adjusted fraction of heat load served by the primary heating system (#{args[:hvac_heat_pump_heating_load_served]}"
          args[:hvac_heat_pump_heating_load_served] = "#{1.0 - args[:hvac_heating_system_2_heating_load_served].to_f}%"
          info_msg += " to #{args[:hvac_heat_pump_heating_load_served]}) to allow for a secondary heating system (#{args[:hvac_heating_system_2_heating_load_served]})."
          runner.registerInfo(info_msg)
        end
      end
    end

    # Adiabatic Walls
    fblr_walls_are_adiabatic = [false, false, false, false]

    # Map corridor arguments to adiabatic walls and shading
    corridor_position = args[:geometry_corridor_position]
    if [HPXML::ResidentialTypeApartment, HPXML::ResidentialTypeSFA].include? unit_type
      if unit_type == HPXML::ResidentialTypeApartment
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
          corridor_position = 'Single Exterior Front'
          runner.registerWarning("Specified incompatible corridor; setting corridor position to '#{corridor_position}'.")
        end

        # Model exterior corridors as overhangs
        if corridor_position.include? 'Exterior'
          args[:enclosure_overhangs] = '10ft, Front Windows'
        end

      elsif unit_type == HPXML::ResidentialTypeSFA
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
    stories_str = (unit_type == HPXML::ResidentialTypeApartment || n_floors == 1 ? '1 Story' : "#{Integer(n_floors)} Stories")
    unit_str = { HPXML::ResidentialTypeSFD => 'Single-Family Detached',
                 HPXML::ResidentialTypeSFA => 'Single-Family Attached',
                 HPXML::ResidentialTypeApartment => 'Apartment Unit',
                 HPXML::ResidentialTypeManufactured => 'Manufactured Home' }[unit_type]
    args[:geometry_unit_type] = "#{unit_str}, #{stories_str}"

    # Adiabatic Floor/Ceiling
    if not unit_level.nil? && n_floors > 1
      if unit_level == 'Bottom'
        args[:geometry_attic_type] = 'Below Apartment'
      elsif unit_level == 'Middle'
        args[:geometry_foundation_type] = 'Above Apartment'
        args[:geometry_attic_type] = 'Below Apartment'
      elsif unit_level == 'Top'
        args[:geometry_foundation_type] = 'Above Apartment'
      end
    end

    # Height Above Grade
    # FIXME
    # if unit_type == HPXML::ResidentialTypeApartment
    # if unit_level == 'Top'
    # args[:geometry_unit_height_above_grade] = (n_floors - 1) * avg_ceiling_height
    # elsif unit_level == 'Middle'
    # args[:geometry_unit_height_above_grade] = (n_floors - 1) / 2.0 * avg_ceiling_height
    # elsif unit_level == 'Bottom'
    # args[:geometry_unit_height_above_grade] = Constants::Auto
    # end
    # else
    # args[:geometry_unit_height_above_grade] = Constants::Auto
    # end

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

    Dir["#{File.dirname(__FILE__)}/../../resources/hpxml-measures/BuildResidentialHPXML/resources/options/*.tsv"].each do |tsv_filepath|
      tsv_filename = File.basename(tsv_filepath)
      arg_name = File.basename(tsv_filename, File.extname(tsv_filename)).to_sym
      get_option_properties(args, tsv_filename, args[arg_name])
    end

    new_arg_keys = args.keys - orig_args.keys
    return new_arg_keys
  end
end

# register the measure to be used by the application
ResStockArguments.new.registerWithApplication
