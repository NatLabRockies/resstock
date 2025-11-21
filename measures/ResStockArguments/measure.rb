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

      args << arg
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

    site_iecc_zone_choices = OpenStudio::StringVector.new
    Constants::IECCZones.each do |iz|
      site_iecc_zone_choices << iz
    end

    arg = OpenStudio::Measure::OSArgument.makeChoiceArgument('site_iecc_zone', site_iecc_zone_choices, false)
    arg.setDisplayName('Site: IECC Zone')
    arg.setDescription('IECC zone of the home address.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_run_period_calendar_year', false)
    arg.setDisplayName('Simulation Control: Run Period Calendar Year')
    arg.setUnits('year')
    arg.setDescription('This numeric field should contain the calendar year that determines the start day of week. If you are running simulations using AMY weather files, the value entered for calendar year will not be used; it will be overridden by the actual year found in the AMY weather file.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('schedules_vacancy_periods', false)
    arg.setDisplayName('Schedules: Vacancy Periods')
    arg.setDescription('Specifies the vacancy periods. Enter a date like "Dec 15 - Jan 15". Optionally, can enter hour of the day like "Dec 15 2 - Jan 15 20" (start hour can be 0 through 23 and end hour can be 1 through 24). If multiple periods, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('schedules_power_outage_periods', false)
    arg.setDisplayName('Schedules: Power Outage Periods')
    arg.setDescription('Specifies the power outage periods. Enter a date like "Dec 15 - Jan 15". Optionally, can enter hour of the day like "Dec 15 2 - Jan 15 20" (start hour can be 0 through 23 and end hour can be 1 through 24). If multiple periods, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('schedules_power_outage_periods_window_natvent_availability', false)
    arg.setDisplayName('Schedules: Power Outage Periods Window Natural Ventilation Availability')
    arg.setDescription("The availability of the natural ventilation schedule during the power outage periods. Valid choices are '#{[HPXML::ScheduleRegular, HPXML::ScheduleAvailable, HPXML::ScheduleUnavailable].join("', '")}'. If multiple periods, use a comma-separated list.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('schedules_space_heating_unavailable_days', false)
    arg.setDisplayName('Schedules: Space Heating Unavailability')
    arg.setDescription('Number of days space heating equipment is unavailable.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('schedules_space_cooling_unavailable_days', false)
    arg.setDisplayName('Schedules: Space Cooling Unavailability')
    arg.setDescription('Number of days space cooling equipment is unavailable.')
    args << arg

    unit_type_choices = OpenStudio::StringVector.new
    unit_type_choices << HPXML::ResidentialTypeSFD
    unit_type_choices << HPXML::ResidentialTypeSFA
    unit_type_choices << HPXML::ResidentialTypeApartment
    unit_type_choices << HPXML::ResidentialTypeManufactured

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('geometry_facility_type', unit_type_choices, true)
    arg.setDisplayName('Geometry: Facility Type')
    arg.setDescription('The facility type of the dwelling unit.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('geometry_unit_cfa_bin', true)
    arg.setDisplayName('Geometry: Unit Conditioned Floor Area Bin')
    arg.setDescription("E.g., '2000-2499'.")
    arg.setDefaultValue('2000-2499')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('geometry_building_num_units', false)
    arg.setDisplayName('Geometry: Building Number of Units')
    arg.setUnits('#')
    arg.setDescription('The number of units in the building.')
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

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('vintage', false)
    arg.setDisplayName('Building Construction: Vintage')
    arg.setDescription('The building vintage, used for informational purposes only.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('ceiling_insulation_r', true)
    arg.setDisplayName('Enclosure: Ceiling Insulation Nominal R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Nominal R-value for the ceiling (attic floor).')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('air_leakage_percent_reduction', false)
    arg.setDisplayName('Enclosure: Air Leakage Value Reduction')
    arg.setDescription('Reduction (%) on the air exchange rate value.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('dhw_water_heater_jacket_rvalue', true)
    arg.setDisplayName('Water Heater: Jacket R-value')
    arg.setDescription('The jacket R-value of the storage water heater.')
    arg.setUnits('h-ft^2-R/Btu')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_heating_weekday_setpoint_temp', true)
    arg.setDisplayName('HVAC Control: Heating Setpoint Weekday Temperature')
    arg.setDescription('Specify the weekday heating setpoint temperature.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(71)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_heating_weekend_setpoint_temp', true)
    arg.setDisplayName('HVAC Control: Heating Setpoint Weekend Temperature')
    arg.setDescription('Specify the weekend heating setpoint temperature.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(71)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_heating_weekday_setpoint_offset_magnitude', true)
    arg.setDisplayName('HVAC Control: Heating Setpoint Weekday Offset Magnitude')
    arg.setDescription('Specify the weekday heating offset magnitude.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_heating_weekend_setpoint_offset_magnitude', true)
    arg.setDisplayName('HVAC Control: Heating Setpoint Weekend Offset Magnitude')
    arg.setDescription('Specify the weekend heating offset magnitude.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('hvac_control_heating_weekday_setpoint_schedule', true)
    arg.setDisplayName('HVAC Control: Heating Setpoint Weekday Schedule')
    arg.setDescription('Specify the 24-hour comma-separated weekday heating schedule of 0s and 1s.')
    arg.setDefaultValue('0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('hvac_control_heating_weekend_setpoint_schedule', true)
    arg.setDisplayName('HVAC Control: Heating Setpoint Weekend Schedule')
    arg.setDescription('Specify the 24-hour comma-separated weekend heating schedule of 0s and 1s.')
    arg.setDefaultValue('0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_cooling_weekday_setpoint_temp', true)
    arg.setDisplayName('HVAC Control: Cooling Setpoint Weekday Temperature')
    arg.setDescription('Specify the weekday cooling setpoint temperature.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(76)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_cooling_weekend_setpoint_temp', true)
    arg.setDisplayName('HVAC Control: Cooling Setpoint Weekend Temperature')
    arg.setDescription('Specify the weekend cooling setpoint temperature.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(76)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_cooling_weekday_setpoint_offset_magnitude', true)
    arg.setDisplayName('HVAC Control: Cooling Setpoint Weekday Offset Magnitude')
    arg.setDescription('Specify the weekday cooling offset magnitude.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_cooling_weekend_setpoint_offset_magnitude', true)
    arg.setDisplayName('HVAC Control: Cooling Setpoint Weekend Offset Magnitude')
    arg.setDescription('Specify the weekend cooling offset magnitude.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('hvac_control_cooling_weekday_setpoint_schedule', true)
    arg.setDisplayName('HVAC Control: Cooling Setpoint Weekday Schedule')
    arg.setDescription('Specify the 24-hour comma-separated weekday cooling schedule of 0s and 1s.')
    arg.setDefaultValue('0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('hvac_control_cooling_weekend_setpoint_schedule', true)
    arg.setDisplayName('HVAC Control: Cooling Setpoint Weekend Schedule')
    arg.setDescription('Specify the 24-hour comma-separated weekend cooling schedule of 0s and 1s.')
    arg.setDefaultValue('0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0')
    args << arg

    hvac_heating_shared_system_choices = OpenStudio::StringVector.new
    hvac_heating_shared_system_choices << 'None'
    hvac_heating_shared_system_choices << 'Baseboard'
    hvac_heating_shared_system_choices << 'FanCoil'

    arg = OpenStudio::Measure::OSArgument.makeChoiceArgument('hvac_heating_shared_system', hvac_heating_shared_system_choices, false)
    arg.setDisplayName('HVAC: Heating Shared System Type')
    arg.setDescription('The type of shared system.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heating_system_heating_autosizing_factor', false)
    arg.setDisplayName('HVAC: Heating System Heating Autosizing Factor')
    arg.setDescription('The capacity scaling factor applied to the auto-sizing methodology. If not provided, 1.0 is used.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heating_system_rated_cfm_per_ton', false)
    arg.setDisplayName('HVAC: Heating System Rated CFM Per Ton')
    arg.setDescription('The rated cfm per ton of the heating system.')
    arg.setUnits('cfm/ton')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heating_system_actual_cfm_per_ton', false)
    arg.setDisplayName('HVAC: Heating System Actual CFM Per Ton')
    arg.setDescription('The actual cfm per ton of the heating system.')
    arg.setUnits('cfm/ton')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heating_system_2_heating_autosizing_factor', false)
    arg.setDisplayName('HVAC: Heating System 2 Heating Autosizing Factor')
    arg.setDescription('The capacity scaling factor applied to the auto-sizing methodology. If not provided, 1.0 is used.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('cooling_system_cooling_autosizing_factor', false)
    arg.setDisplayName('HVAC: Cooling System Cooling Autosizing Factor')
    arg.setDescription('The capacity scaling factor applied to the auto-sizing methodology. If not provided, 1.0 is used.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('cooling_system_rated_cfm_per_ton', false)
    arg.setDisplayName('HVAC: Cooling System Rated CFM Per Ton')
    arg.setDescription('The rated cfm per ton of the cooling system.')
    arg.setUnits('cfm/ton')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('cooling_system_actual_cfm_per_ton', false)
    arg.setDisplayName('HVAC: Cooling System Actual CFM Per Ton')
    arg.setDescription('The actual cfm per ton of the cooling system.')
    arg.setUnits('cfm/ton')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('cooling_system_frac_manufacturer_charge', false)
    arg.setDisplayName('HVAC: Cooling System Fraction of Manufacturer Recommended Charge')
    arg.setDescription('The fraction of manufacturer recommended charge of the cooling system.')
    arg.setUnits('Frac')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heat_pump_heating_autosizing_factor', false)
    arg.setDisplayName('HVAC: Heat Pump Heating Autosizing Factor')
    arg.setDescription('The capacity scaling factor applied to the auto-sizing methodology. If not provided, 1.0 is used.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heat_pump_cooling_autosizing_factor', false)
    arg.setDisplayName('HVAC: Heat Pump Cooling Autosizing Factor')
    arg.setDescription('The capacity scaling factor applied to the auto-sizing methodology. If not provided, 1.0 is used.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heat_pump_backup_heating_autosizing_factor', false)
    arg.setDisplayName('HVAC: Heat Pump Backup Heating Autosizing Factor')
    arg.setDescription('The capacity scaling factor applied to the auto-sizing methodology if Backup Type is integrated.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heat_pump_rated_cfm_per_ton', false)
    arg.setDisplayName('HVAC: Heat Pump Rated CFM Per Ton')
    arg.setDescription('The rated cfm per ton of the heat pump.')
    arg.setUnits('cfm/ton')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heat_pump_actual_cfm_per_ton', false)
    arg.setDisplayName('HVAC: Heat Pump Actual CFM Per Ton')
    arg.setDescription('The actual cfm per ton of the heat pump.')
    arg.setUnits('cfm/ton')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heat_pump_frac_manufacturer_charge', false)
    arg.setDisplayName('HVAC: Heat Pump Fraction of Manufacturer Recommended Charge')
    arg.setDescription('The fraction of manufacturer recommended charge of the heat pump.')
    arg.setUnits('Frac')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('hvac_heat_pump_backup_use_existing_system', false)
    arg.setDisplayName('HVAC: Heat Pump Backup Use Existing System')
    arg.setDescription("Whether the heat pump uses the existing heating system as backup. If true and backup type of the heat pump is '#{HPXML::HeatPumpBackupTypeIntegrated}', heat_pump_backup_xxx arguments are assigned values based on the existing heating system. If true and backup type of the heat pump is '#{HPXML::HeatPumpBackupTypeSeparate}', heating_system_2_xxx arguments are assigned values based on the existing heating system. This argument is only applicable for heat pump upgrades.")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('hvac_heat_pump_sizing_is_duct_limited', false)
    arg.setDisplayName('HVAC: Heat Pump Sizing Is Duct Limited')
    arg.setDescription('Whether the (ducted) heat pump has an upper limit for autosized heating/cooling capacity and an adjusted blower fan efficiency (W/CFM) value. This argument is only applicable for heat pump upgrades.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hvac_perf_data_heating_outdoor_temperatures', false)
    arg.setDisplayName('HVAC Detailed Performance Data: Heating Outdoor Temperatures')
    arg.setDescription('Outdoor temperatures of heating detailed performance data if available. Applies only to air-source HVAC systems (air-to-air and mini-split heat pumps). Only certain outdoor temperatures are allowed, see the OS-HPXML documentation.')
    arg.setUnits('F')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hvac_perf_data_heating_min_speed_capacities', false)
    arg.setDisplayName('HVAC Detailed Performance Data: Heating Minimum Speed Capacities')
    arg.setDescription('Minimum speed capacities of heating detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to two stage and variable speed air-source HVAC systems (air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation.')
    arg.setUnits('Btu/hr or Frac')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hvac_perf_data_heating_nom_speed_capacities', false)
    arg.setDisplayName('HVAC Detailed Performance Data: Heating Nominal Speed Capacities')
    arg.setDescription('Nominal speed capacities of heating detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to air-source HVAC systems (air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation.')
    arg.setUnits('Btu/hr or Frac')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hvac_perf_data_heating_max_speed_capacities', false)
    arg.setDisplayName('HVAC Detailed Performance Data: Heating Maximum Speed Capacities')
    arg.setDescription('Maximum speed capacities of heating detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to variable speed air-source HVAC systems (air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation.')
    arg.setUnits('Btu/hr or Frac')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hvac_perf_data_heating_min_speed_cops', false)
    arg.setDisplayName('HVAC Detailed Performance Data: Heating Minimum Speed COPs')
    arg.setDescription('Minimum speed efficiency COP values of heating detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to two stage and variable speed air-source HVAC systems (air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation.')
    arg.setUnits('W/W')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hvac_perf_data_heating_nom_speed_cops', false)
    arg.setDisplayName('HVAC Detailed Performance Data: Heating Nominal Speed COPs')
    arg.setDescription('Nominal speed efficiency COP values of heating detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to air-source HVAC systems (air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation.')
    arg.setUnits('W/W')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hvac_perf_data_heating_max_speed_cops', false)
    arg.setDisplayName('HVAC Detailed Performance Data: Heating Maximum Speed COPs')
    arg.setDescription('Maximum speed efficiency COP values of heating detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to variable speed air-source HVAC systems (air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation.')
    arg.setUnits('W/W')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hvac_perf_data_cooling_outdoor_temperatures', false)
    arg.setDisplayName('HVAC Detailed Performance Data: Cooling Outdoor Temperatures')
    arg.setDescription('Outdoor temperatures of cooling detailed performance data if available. Applies only to variable-speed air-source HVAC systems (central and mini-split air conditioners, air-to-air and mini-split heat pumps). Only certain outdoor temperatures are allowed, see the OS-HPXML documentation.')
    arg.setUnits('F')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hvac_perf_data_cooling_min_speed_capacities', false)
    arg.setDisplayName('HVAC Detailed Performance Data: Cooling Minimum Speed Capacities')
    arg.setDescription('Minimum speed capacities of cooling detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to two stage and variable speed air-source HVAC systems (central and mini-split air conditioners, air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation.')
    arg.setUnits('Btu/hr or Frac')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hvac_perf_data_cooling_nom_speed_capacities', false)
    arg.setDisplayName('HVAC Detailed Performance Data: Cooling Nominal Speed Capacities')
    arg.setDescription('Nominal speed capacities of cooling detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to air-source HVAC systems (central and mini-split air conditioners, air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation.')
    arg.setUnits('Btu/hr or Frac')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hvac_perf_data_cooling_max_speed_capacities', false)
    arg.setDisplayName('HVAC Detailed Performance Data: Cooling Maximum Speed Capacities')
    arg.setDescription('Maximum speed capacities of cooling detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to variable speed air-source HVAC systems (central and mini-split air conditioners, air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation.')
    arg.setUnits('Btu/hr or Frac')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hvac_perf_data_cooling_min_speed_cops', false)
    arg.setDisplayName('HVAC Detailed Performance Data: Cooling Minimum Speed COPs')
    arg.setDescription('Minimum speed efficiency COP values of cooling detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to two stage and variable speed air-source HVAC systems (central and mini-split air conditioners, air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation.')
    arg.setUnits('W/W')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hvac_perf_data_cooling_nom_speed_cops', false)
    arg.setDisplayName('HVAC Detailed Performance Data: Cooling Nominal Speed COPs')
    arg.setDescription('Nominal speed efficiency COP values of cooling detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to air-source HVAC systems (central and mini-split air conditioners, air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation.')
    arg.setUnits('W/W')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hvac_perf_data_cooling_max_speed_cops', false)
    arg.setDisplayName('HVAC Detailed Performance Data: Cooling Maximum Speed COPs')
    arg.setDescription('Maximum speed efficiency COP values of cooling detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to variable speed air-source HVAC systems (central and mini-split air conditioners, air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation.')
    arg.setUnits('W/W')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('hvac_flex_peak_offset', false)
    arg.setDisplayName('HVAC Load Flexibility: Peak Offset (deg F)')
    arg.setDescription('Offset of the peak period in degrees Fahrenheit.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeDoubleArgument('hvac_flex_pre_peak_duration_hours', false)
    arg.setDisplayName('HVAC Load Flexibility: Pre-Peak Duration (hours)')
    arg.setDescription('Duration of the pre-peak period in hours.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('hvac_flex_pre_peak_offset', false)
    arg.setDisplayName('HVAC Load Flexibility: Pre-Peak Offset (deg F)')
    arg.setDescription('Offset of the pre-peak period in degrees Fahrenheit.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('flex_random_shift_minutes', false)
    arg.setDisplayName('Load Flexibility: Random Shift (minutes)')
    arg.setDescription('Number of minutes to randomly shift the peak period. If minutes is less than timestep, it will be assumed to be 0.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('ev_flex_enabled', false)
    arg.setDisplayName('EV Flexibility Enabled')
    arg.setDescription('Whether to enable EV flexibility.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('vehicle_miles_driven_per_year', false)
    arg.setDisplayName('Electric Vehicle: Miles Driven Per Year')
    arg.setDescription('The annual miles the vehicle is driven.')
    arg.setUnits('miles')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('ev_fraction_charged_home', false)
    arg.setDisplayName('Electric Vehicle: Fraction Charged at Home')
    arg.setDescription('The fraction of charging energy provided by the at-home charger to the electric vehicle.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('ev_efficiency_percent_increase', false)
    arg.setDisplayName('Electric Vehicle: Efficiency Improvement')
    arg.setDescription('The increase (fraction) in efficiency of the electric vehicle.')
    arg.setUnits('Frac')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('refrigerator_usage_multiplier', false)
    arg.setDisplayName('Appliances: Refrigerator Usage Multiplier')
    arg.setDescription('Multiplier on the refrigerator energy usage that can reflect, e.g., high/low usage occupants.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothes_dryer_usage_multiplier', false)
    arg.setDisplayName('Appliances: Clothes Dryer Usage Multiplier')
    arg.setDescription('Multiplier on the clothes dryer energy usage that can reflect, e.g., high/low usage occupants.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothes_washer_usage_multiplier', false)
    arg.setDisplayName('Appliances: Clothes Washer Usage Multiplier')
    arg.setDescription('Multiplier on the clothes washer energy usage that can reflect, e.g., high/low usage occupants.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('cooking_range_oven_usage_multiplier', false)
    arg.setDisplayName('Appliances: Cooking Range/Oven Usage Multiplier')
    arg.setDescription('Multiplier on the cooking range/oven energy usage that can reflect, e.g., high/low usage occupants.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('dishwasher_usage_multiplier', false)
    arg.setDisplayName('Appliances: Dishwasher Usage Multiplier')
    arg.setDescription('Multiplier on the dishwasher energy usage that can reflect, e.g., high/low usage occupants.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('extra_refrigerator_usage_multiplier', false)
    arg.setDisplayName('Appliances: Extra Refrigerator Usage Multiplier')
    arg.setDescription('Multiplier on the extra refrigerator energy usage that can reflect, e.g., high/low usage occupants.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('freezer_usage_multiplier', false)
    arg.setDisplayName('Appliances: Freezer Usage Multiplier')
    arg.setDescription('Multiplier on the freezer energy usage that can reflect, e.g., high/low usage occupants.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('pool_pump_usage_multiplier', false)
    arg.setDisplayName('Pool: Pump Usage Multiplier')
    arg.setDescription('Multiplier on the pool pump energy usage that can reflect, e.g., high/low usage occupants.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('bathroom_fans_start_hour', false)
    arg.setDisplayName('Ventilation: Bathroom Fans Start Hour')
    arg.setDescription('The hour of the day when the bathroom fans run.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('kitchen_fans_start_hour', false)
    arg.setDisplayName('Ventilation: Kitchen Fans Start Hour')
    arg.setDescription('The hour of the day when the kitchen fans run.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('interior_lighting_usage_multiplier', false)
    arg.setDisplayName('Lighting: Interior Usage Multiplier')
    arg.setDescription('Multiplier on the lighting energy usage (interior) that can reflect, e.g., high/low usage occupants.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('exterior_lighting_usage_multiplier', false)
    arg.setDisplayName('Lighting: Exterior Usage Multiplier')
    arg.setDescription('Multiplier on the lighting energy usage (exterior) that can reflect, e.g., high/low usage occupants.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('garage_lighting_usage_multiplier', false)
    arg.setDisplayName('Lighting: Garage Usage Multiplier')
    arg.setDescription('Multiplier on the lighting energy usage (garage) that can reflect, e.g., high/low usage occupants.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('water_fixtures_usage_multiplier', false)
    arg.setDisplayName('Hot Water Fixtures: Usage Multiplier')
    arg.setDescription('Multiplier on the hot water usage that can reflect, e.g., high/low usage occupants.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('misc_plug_loads_television_usage_multiplier', false)
    arg.setDisplayName('Plug Loads: Television Usage Multiplier')
    arg.setDescription('Multiplier on the television energy usage that can reflect, e.g., high/low usage occupants.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('misc_plug_loads_other_usage_multiplier', false)
    arg.setDisplayName('Plug Loads: Other Usage Multiplier')
    arg.setDescription('Multiplier on the other energy usage that can reflect, e.g., high/low usage occupants.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('misc_has_pool', false)
    arg.setDisplayName('Misc: Has Pool')
    arg.setDescription('Whether a pool is present.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('electric_panel_load_other_power_rating', false)
    arg.setDisplayName('Electric Panel: Other Power Rating')
    arg.setDescription('Specifies the panel load other power rating. This represents the total of all other electric loads that are fastened in place, permanently connected, or located on a specific circuit. For example, garbage disposal, built-in microwave.')
    arg.setUnits('W')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_scenario_names', false)
    arg.setDisplayName('Emissions: Scenario Names')
    arg.setDescription('Names of emissions scenarios. If multiple scenarios, use a comma-separated list. If not provided, no emissions scenarios are calculated.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_types', false)
    arg.setDisplayName('Emissions: Types')
    arg.setDescription('Types of emissions (e.g., CO2e, NOx, etc.). If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_electricity_units', false)
    arg.setDisplayName('Emissions: Electricity Units')
    arg.setDescription('Electricity emissions factors units. If multiple scenarios, use a comma-separated list. Only lb/MWh and kg/MWh are allowed.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_electricity_filepaths', false)
    arg.setDisplayName('Emissions: Electricity File Paths')
    arg.setDescription('Electricity emissions factors values, specified as an absolute/relative path to a file with hourly factors. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_fossil_fuel_units', false)
    arg.setDisplayName('Emissions: Fossil Fuel Units')
    arg.setDescription('Fossil fuel emissions factors units. If multiple scenarios, use a comma-separated list. Only lb/MBtu and kg/MBtu are allowed.')
    args << arg

    resstock_fuels(include_electricity: false).each do |fuel|
      arg = OpenStudio::Measure::OSArgument.makeStringArgument("emissions_#{OpenStudio::toUnderscoreCase(fuel)}_values", false)
      arg.setDisplayName("Emissions: #{fuel.split(' ').map(&:capitalize).join(' ')} Values")
      arg.setDescription("#{fuel.capitalize} emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list.")
      args << arg
    end

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_scenario_names', false)
    arg.setDisplayName('Utility Bills: Scenario Names')
    arg.setDescription('Names of utility bill scenarios. If multiple scenarios, use a comma-separated list. If not provided, no utility bills scenarios are calculated.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_electricity_filepaths', false)
    arg.setDisplayName('Utility Bills: Electricity File Paths')
    arg.setDescription('Electricity tariff file specified as an absolute/relative path to a file with utility rate structure information. Tariff file must be formatted to OpenEI API version 7. If multiple scenarios, use a comma-separated list.')
    args << arg

    resstock_fuels(include_electricity: true).each do |fuel|
      arg = OpenStudio::Measure::OSArgument.makeStringArgument("utility_bill_#{OpenStudio::toUnderscoreCase(fuel)}_fixed_charges", false)
      arg.setDisplayName("Utility Bills: #{fuel.split(' ').map(&:capitalize).join(' ')} Fixed Charges")
      arg.setDescription("#{fuel.capitalize} utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list.")
      args << arg
    end

    resstock_fuels(include_electricity: true).each do |fuel|
      arg = OpenStudio::Measure::OSArgument.makeStringArgument("utility_bill_#{OpenStudio::toUnderscoreCase(fuel)}_marginal_rates", false)
      arg.setDisplayName("Utility Bills: #{fuel.split(' ').map(&:capitalize).join(' ')} Marginal Rates")
      arg.setDescription("#{fuel.capitalize} utility bill marginal rates. If multiple scenarios, use a comma-separated list.")
      args << arg
    end

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_pv_compensation_types', false)
    arg.setDisplayName('Utility Bills: PV Compensation Types')
    arg.setDescription('Utility bill PV compensation types. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_pv_net_metering_annual_excess_sellback_rate_types', false)
    arg.setDisplayName('Utility Bills: PV Net Metering Annual Excess Sellback Rate Types')
    arg.setDescription("Utility bill PV net metering annual excess sellback rate types. Only applies if the PV compensation type is '#{HPXML::PVCompensationTypeNetMetering}'. If multiple scenarios, use a comma-separated list.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_pv_net_metering_annual_excess_sellback_rates', false)
    arg.setDisplayName('Utility Bills: PV Net Metering Annual Excess Sellback Rates')
    arg.setDescription("Utility bill PV net metering annual excess sellback rates. Only applies if the PV compensation type is '#{HPXML::PVCompensationTypeNetMetering}' and the PV annual excess sellback rate type is '#{HPXML::PVAnnualExcessSellbackRateTypeUserSpecified}'. If multiple scenarios, use a comma-separated list.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_pv_feed_in_tariff_rates', false)
    arg.setDisplayName('Utility Bills: PV Feed-In Tariff Rates')
    arg.setDescription("Utility bill PV annual full/gross feed-in tariff rates. Only applies if the PV compensation type is '#{HPXML::PVCompensationTypeFeedInTariff}'. If multiple scenarios, use a comma-separated list.")
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
    cfa_bin = args[:geometry_unit_cfa_bin]
    unit_type = args[:geometry_facility_type]
    vintage = args[:vintage]
    n_floors = Float(args[:geometry_num_floors_above_grade])
    if [HPXML::ResidentialTypeApartment, HPXML::ResidentialTypeSFA].include? args[:geometry_facility_type]
      n_units = Float(args[:geometry_building_num_units])
      horiz_location = args[:geometry_unit_horizontal_location]
      unit_level = args[:geometry_unit_level]
    end

    # Conditioned floor area
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

    # Vintage
    args[:building_year_built] = Integer(Float(vintage.gsub(/[^0-9]/, '')))

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

    # HVAC Secondary
    if args[:hvac_heating_system_2] != 'None'
      if args[:hvac_heating_system] != 'None'
        if ((args[:hvac_heating_system_heating_load_served].to_f + args[:hvac_heating_system_2_heating_load_served].to_f) > 100)
          info_msg = "Adjusted fraction of heat load served by the primary heating system (#{args[:hvac_heating_system_heating_load_served]}"
          args[:hvac_heating_system_heating_load_served] = "#{Integer(100 - args[:hvac_heating_system_2_heating_load_served].to_f)}%"
          info_msg += " to #{args[:hvac_heating_system_heating_load_served]}) to allow for a secondary heating system (#{args[:hvac_heating_system_2_heating_load_served]})."
          runner.registerInfo(info_msg)
        end
      elsif args[:hvac_heat_pump] != 'None'
        if ((args[:hvac_heat_pump_heating_load_served].to_f + args[:hvac_heating_system_2_heating_load_served].to_f) > 100)
          info_msg = "Adjusted fraction of heat load served by the primary heating system (#{args[:hvac_heat_pump_heating_load_served]}"
          args[:hvac_heat_pump_heating_load_served] = "#{Integer(100 - args[:hvac_heating_system_2_heating_load_served].to_f)}%"
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
          fblr_walls_are_adiabatic[1] = true # back
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

    # Adiabatic Floor/Ceiling (for MF buildings w/ more than 1 story)
    if (not unit_level.nil?) && n_floors > 1
      if unit_level == 'Bottom'
        args[:geometry_attic_type] = 'Below Apartment'
      elsif unit_level == 'Middle'
        args[:geometry_foundation_type] = 'Above Apartment'
        args[:geometry_attic_type] = 'Below Apartment'
      elsif unit_level == 'Top'
        args[:geometry_foundation_type] = 'Above Apartment'
      end
    end

    # Electric Vehicle
    # This can't be done in the ResStockArgumentsPostHPXML measure because these changes are
    # needed for the BuildResidentialScheduleFile measure
    if args[:electric_vehicle] != 'None'
      args[:electric_vehicle] = args[:electric_vehicle].gsub('11000 miles/yr', "#{Integer(args[:vehicle_miles_driven_per_year])} miles/yr")
    end
    if args[:electric_vehicle_charger] != 'None'
      args[:electric_vehicle_charger] = args[:electric_vehicle_charger].gsub('100% Charging at Home', "#{Integer(100 * args[:ev_fraction_charged_home])}% Charging at Home")
    end
    args[:vehicle_miles_driven_per_year] = nil
    args[:ev_fraction_charged_home] = nil

    # Pool
    if not args[:misc_has_pool]
      args[:misc_pool] = 'None'
    end

    # Register values to runner
    args.each do |arg_name, arg_value|
      next if new_arg_keys.include?(arg_name)

      if args_to_delete.include?(arg_name) || arg_value.nil?
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

  def resstock_fuels(include_electricity:)
    fuels = []
    fuels << HPXML::FuelTypeElectricity if include_electricity
    fuels << HPXML::FuelTypeNaturalGas
    fuels << HPXML::FuelTypePropane
    fuels << HPXML::FuelTypeOil
    fuels << HPXML::FuelTypeWoodCord
    return fuels
  end

  def convert_args(args)
    measure_arguments = @build_residential_hpxml_measure_arguments
    measure_arguments.each do |arg|
      arg_name = arg.name.to_sym
      value = args[arg_name]
      next if value.nil?

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
