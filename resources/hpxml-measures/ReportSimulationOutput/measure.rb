# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'msgpack'
require 'time'
require_relative '../HPXMLtoOpenStudio/resources/calendar.rb'
require_relative '../HPXMLtoOpenStudio/resources/constants.rb'
require_relative '../HPXMLtoOpenStudio/resources/energyplus.rb'
require_relative '../HPXMLtoOpenStudio/resources/hpxml.rb'
require_relative '../HPXMLtoOpenStudio/resources/output.rb'
require_relative '../HPXMLtoOpenStudio/resources/unit_conversions.rb'

# start the measure
class ReportSimulationOutput < OpenStudio::Measure::ReportingMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'HPXML Simulation Output Report'
  end

  # human readable description
  def description
    return 'Reports simulation outputs for residential HPXML-based models.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Processes EnergyPlus simulation outputs in order to generate an annual output file and an optional timeseries output file.'
  end

  # Define the arguments that the user will input.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @return [OpenStudio::Measure::OSArgumentVector] an OpenStudio::Measure::OSArgumentVector object
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    format_chs = OpenStudio::StringVector.new
    format_chs << 'csv'
    format_chs << 'json'
    format_chs << 'msgpack'
    format_chs << 'csv_dview'
    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('output_format', format_chs, false)
    arg.setDisplayName('Output Format')
    arg.setDescription("The file format of the annual (and timeseries, if requested) outputs. If 'csv_dview' is selected, the timeseries CSV file will include header rows that facilitate opening the file in the DView application.")
    arg.setDefaultValue('csv')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_annual_total_consumptions', false)
    arg.setDisplayName('Generate Annual Output: Total Consumptions')
    arg.setDescription('Generates annual energy consumptions for the total building.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_annual_fuel_consumptions', false)
    arg.setDisplayName('Generate Annual Output: Fuel Consumptions')
    arg.setDescription('Generates annual energy consumptions for each fuel type.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_annual_end_use_consumptions', false)
    arg.setDisplayName('Generate Annual Output: End Use Consumptions')
    arg.setDescription('Generates annual energy consumptions for each end use.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_annual_system_use_consumptions', false)
    arg.setDisplayName('Generate Annual Output: System Use Consumptions')
    arg.setDescription('Generates annual energy consumptions for each end use of each HVAC and water heating system.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_annual_emissions', false)
    arg.setDisplayName('Generate Annual Output: Emissions')
    arg.setDescription('Generates annual emissions. Requires the appropriate HPXML inputs to be specified.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_annual_emission_fuels', false)
    arg.setDisplayName('Generate Annual Output: Emission Fuel Uses')
    arg.setDescription('Generates annual emissions for each fuel type. Requires the appropriate HPXML inputs to be specified.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_annual_emission_end_uses', false)
    arg.setDisplayName('Generate Annual Output: Emission End Uses')
    arg.setDescription('Generates annual emissions for each end use. Requires the appropriate HPXML inputs to be specified.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_annual_total_loads', false)
    arg.setDisplayName('Generate Annual Output: Total Loads')
    arg.setDescription('Generates annual heating, cooling, and hot water loads.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_annual_unmet_hours', false)
    arg.setDisplayName('Generate Annual Output: Unmet Hours')
    arg.setDescription('Generates annual unmet hours for heating, cooling, and EV driving.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_annual_peak_fuels', false)
    arg.setDisplayName('Generate Annual Output: Peak Fuels')
    arg.setDescription('Generates annual/summer/winter electricity peaks.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_annual_peak_loads', false)
    arg.setDisplayName('Generate Annual Output: Peak Loads')
    arg.setDescription('Generates annual peak loads for heating/cooling.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_annual_component_loads', false)
    arg.setDisplayName('Generate Annual Output: Component Loads')
    arg.setDescription('Generates annual heating and cooling loads disaggregated by component type.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_annual_hot_water_uses', false)
    arg.setDisplayName('Generate Annual Output: Hot Water Uses')
    arg.setDescription('Generates annual hot water usages for each end use.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_annual_hvac_summary', false)
    arg.setDisplayName('Generate Annual Output: HVAC Summary')
    arg.setDescription('Generates HVAC capacities, design temperatures, and design loads.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_annual_resilience', false)
    arg.setDisplayName('Generate Annual Output: Resilience')
    arg.setDescription('Generates annual resilience outputs.')
    arg.setDefaultValue(true)
    args << arg

    timeseries_frequency_chs = OpenStudio::StringVector.new
    timeseries_frequency_chs << EPlus::TimeseriesFrequencyNone
    timeseries_frequency_chs << EPlus::TimeseriesFrequencyTimestep
    timeseries_frequency_chs << EPlus::TimeseriesFrequencyHourly
    timeseries_frequency_chs << EPlus::TimeseriesFrequencyDaily
    timeseries_frequency_chs << EPlus::TimeseriesFrequencyMonthly
    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('timeseries_frequency', timeseries_frequency_chs, false)
    arg.setDisplayName('Timeseries Reporting Frequency')
    arg.setDescription("The frequency at which to report timeseries output data. Using '#{EPlus::TimeseriesFrequencyNone}' will disable timeseries outputs.")
    arg.setDefaultValue(EPlus::TimeseriesFrequencyNone)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_total_consumptions', false)
    arg.setDisplayName('Generate Timeseries Output: Total Consumptions')
    arg.setDescription('Generates timeseries energy consumptions for the total building.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_fuel_consumptions', false)
    arg.setDisplayName('Generate Timeseries Output: Fuel Consumptions')
    arg.setDescription('Generates timeseries energy consumptions for each fuel type.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_end_use_consumptions', false)
    arg.setDisplayName('Generate Timeseries Output: End Use Consumptions')
    arg.setDescription('Generates timeseries energy consumptions for each end use.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_system_use_consumptions', false)
    arg.setDisplayName('Generate Timeseries Output: System Use Consumptions')
    arg.setDescription('Generates timeseries energy consumptions for each end use of each HVAC and water heating system.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_emissions', false)
    arg.setDisplayName('Generate Timeseries Output: Emissions')
    arg.setDescription('Generates timeseries emissions. Requires the appropriate HPXML inputs to be specified.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_emission_fuels', false)
    arg.setDisplayName('Generate Timeseries Output: Emission Fuel Uses')
    arg.setDescription('Generates timeseries emissions for each fuel type. Requires the appropriate HPXML inputs to be specified.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_emission_end_uses', false)
    arg.setDisplayName('Generate Timeseries Output: Emission End Uses')
    arg.setDescription('Generates timeseries emissions for each end use. Requires the appropriate HPXML inputs to be specified.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_hot_water_uses', false)
    arg.setDisplayName('Generate Timeseries Output: Hot Water Uses')
    arg.setDescription('Generates timeseries hot water usages for each end use.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_total_loads', false)
    arg.setDisplayName('Generate Timeseries Output: Total Loads')
    arg.setDescription('Generates timeseries heating, cooling, and hot water loads.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_component_loads', false)
    arg.setDisplayName('Generate Timeseries Output: Component Loads')
    arg.setDescription('Generates timeseries heating and cooling loads disaggregated by component type.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_unmet_hours', false)
    arg.setDisplayName('Generate Timeseries Output: Unmet Hours')
    arg.setDescription('Generates timeseries unmet hours for heating, cooling, and EV driving.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_zone_temperatures', false)
    arg.setDisplayName('Generate Timeseries Output: Zone Temperatures')
    arg.setDescription('Generates timeseries temperatures for each thermal zone.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_zone_conditions', false)
    arg.setDisplayName('Generate Timeseries Output: Zone Conditions')
    arg.setDescription('Generates timeseries temperatures and humidities for each thermal zone.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_airflows', false)
    arg.setDisplayName('Generate Timeseries Output: Airflows')
    arg.setDescription('Generates timeseries airflows.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_weather', false)
    arg.setDisplayName('Generate Timeseries Output: Weather')
    arg.setDescription('Generates timeseries weather data.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_resilience', false)
    arg.setDisplayName('Generate Timeseries Output: Resilience')
    arg.setDescription('Generates timeseries resilience outputs.')
    arg.setDefaultValue(false)
    args << arg

    timestamp_chs = OpenStudio::StringVector.new
    timestamp_chs << 'start'
    timestamp_chs << 'end'
    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('timeseries_timestamp_convention', timestamp_chs, false)
    arg.setDisplayName('Generate Timeseries Output: Timestamp Convention')
    arg.setDescription("Determines whether timeseries timestamps use the start-of-period or end-of-period convention. Doesn't apply if the output format is 'csv_dview'.")
    arg.setDefaultValue('start')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('timeseries_num_decimal_places', false)
    arg.setDisplayName('Generate Timeseries Output: Number of Decimal Places')
    arg.setDescription('Allows overriding the default number of decimal places for timeseries outputs.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('add_timeseries_dst_column', false)
    arg.setDisplayName('Generate Timeseries Output: Add TimeDST Column')
    arg.setDescription('Optionally add, in addition to the default local standard Time column, a local clock TimeDST column. Requires that daylight saving time is enabled.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('add_timeseries_utc_column', false)
    arg.setDisplayName('Generate Timeseries Output: Add TimeUTC Column')
    arg.setDescription('Optionally add, in addition to the default local standard Time column, a local clock TimeUTC column. If the time zone UTC offset is not provided in the HPXML file, the time zone in the EPW header will be used.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('user_output_variables', false)
    arg.setDisplayName('Generate Timeseries Output: EnergyPlus Output Variables')
    arg.setDescription('Optionally generates timeseries EnergyPlus output variables. If multiple output variables are desired, use a comma-separated list. Do not include key values; by default all key values will be requested. Example: "Zone People Occupant Count, Zone People Total Heating Energy"')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('user_output_meters', false)
    arg.setDisplayName('Generate Timeseries Output: EnergyPlus Output Meters')
    arg.setDescription('Optionally generates timeseries EnergyPlus output meters. If multiple output meters are desired, use a comma-separated list. Example: "Electricity:Facility, HeatingCoils:EnergyTransfer"')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('annual_output_file_name', false)
    arg.setDisplayName('Annual Output File Name')
    arg.setDescription("If not provided, defaults to 'results_annual.csv' (or 'results_annual.json' or 'results_annual.msgpack').")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('timeseries_output_file_name', false)
    arg.setDisplayName('Timeseries Output File Name')
    arg.setDescription("If not provided, defaults to 'results_timeseries.csv' (or 'results_timeseries.json' or 'results_timeseries.msgpack').")
    args << arg

    return args
  end

  # Define the outputs that the measure will create.
  #
  # @return [OpenStudio::Measure::OSOutputVector] List of outputs
  def outputs
    result = OpenStudio::Measure::OSOutputVector.new

    setup_outputs(true)

    [@totals,
     @fuels,
     @end_uses,
     @loads,
     @unmet_hours,
     @peak_fuels,
     @peak_loads,
     @component_loads,
     @hot_water_uses,
     @resilience].each do |outputs|
      outputs.values.each do |obj|
        output_name = OpenStudio::toUnderscoreCase("#{obj.name} #{obj.annual_units}")
        result << OpenStudio::Measure::OSOutput.makeDoubleOutput(output_name.chomp('_'))
      end
    end

    return result
  end

  # TODO
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param arguments [TODO] TODO
  # @param user_arguments [OpenStudio::Measure::OSArgumentMap] OpenStudio measure arguments
  # @return [TODO] TODO
  def get_arguments(runner, arguments, user_arguments)
    args = runner.getArgumentValues(arguments, user_arguments)
    if args[:timeseries_frequency] == EPlus::TimeseriesFrequencyNone
      # Override all timeseries arguments
      args.keys.each do |key|
        next unless key.start_with?('include_timeseries')

        args[key] = false
      end
      args[:user_output_variables] = nil
      args[:user_output_meters] = nil
    end
    return args
  end

  # Adds OpenStudio model objects to requests desired outputs.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param user_arguments [OpenStudio::Measure::OSArgumentMap] OpenStudio measure arguments
  # @return [Boolean] Success
  def modelOutputRequests(model, runner, user_arguments)
    return false if runner.halted

    @model = model

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    unmet_hours_program = model.getEnergyManagementSystemPrograms.find { |p| p.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants::ObjectTypeUnmetHoursProgram }
    total_loads_program = model.getEnergyManagementSystemPrograms.find { |p| p.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants::ObjectTypeTotalLoadsProgram }
    comp_loads_program = model.getEnergyManagementSystemPrograms.find { |p| p.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants::ObjectTypeComponentLoadsProgram }
    total_airflows_program = model.getEnergyManagementSystemPrograms.find { |p| p.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants::ObjectTypeTotalAirflowsProgram }
    unmet_driving_hrs_program = model.getEnergyManagementSystemPrograms.find { |p| p.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants::ObjectTypeBEVDischargeProgram }
    heated_zones = eval(model.getBuilding.additionalProperties.getFeatureAsString('heated_zones').get)
    cooled_zones = eval(model.getBuilding.additionalProperties.getFeatureAsString('cooled_zones').get)

    args = get_arguments(runner, arguments(model), user_arguments)

    setup_outputs(false, args)
    args = setup_timeseries_includes(@emissions, args)

    has_electricity_production = false
    if @end_uses.count { |_key, end_use| end_use.is_negative && end_use.variables.size > 0 } > 0
      has_electricity_production = true
    end

    has_electricity_storage = false
    if @end_uses.count { |key, end_use| (end_use.is_storage && end_use.variables.size > 0) || (key == [FT::Elec, EUT::Vehicle] && end_use.variables.size > 0) } > 0
      has_electricity_storage = true
    end

    # Fuel outputs
    @fuels.each do |(_fuel_type, _total_or_net), fuel|
      next if fuel.meter.nil?

      Model.add_output_meter(model, meter_name: fuel.meter, reporting_frequency: 'runperiod')
      if args[:include_timeseries_fuel_consumptions]
        Model.add_output_meter(model, meter_name: fuel.meter, reporting_frequency: args[:timeseries_frequency])
      end
    end

    if has_electricity_production || has_electricity_storage
      Model.add_output_meter(model, meter_name: 'ElectricityProduced:Facility', reporting_frequency: 'runperiod') # Used for error checking
    end
    if has_electricity_storage
      Model.add_output_meter(model, meter_name: 'ElectricStorage:ElectricityProduced', reporting_frequency: 'runperiod') # Used for error checking
      if args[:include_timeseries_fuel_consumptions]
        Model.add_output_meter(model, meter_name: 'ElectricStorage:ElectricityProduced', reporting_frequency: args[:timeseries_frequency])
      end

      # Resilience
      if args[:include_annual_resilience] || args[:include_timeseries_resilience]
        resilience_frequency = EPlus::TimeseriesFrequencyTimestep
        if args[:timeseries_frequency] != EPlus::TimeseriesFrequencyTimestep
          resilience_frequency = EPlus::TimeseriesFrequencyHourly
        end
        Model.add_output_meter(model, meter_name: 'Electricity:Facility', reporting_frequency: resilience_frequency)
        Model.add_output_meter(model, meter_name: 'ElectricityProduced:Facility', reporting_frequency: resilience_frequency)
        Model.add_output_meter(model, meter_name: 'ElectricStorage:ElectricityProduced', reporting_frequency: resilience_frequency)
        @resilience.values.each do |resilience|
          resilience.variables.each do |_sys_id, varkey, var|
            Model.add_output_variable(model, key_value: varkey, variable_name: var, reporting_frequency: resilience_frequency)
          end
        end
      end
    end

    # End Use/Hot Water Use/Ideal Load outputs
    { @end_uses => args[:include_timeseries_end_use_consumptions],
      @hot_water_uses => args[:include_timeseries_hot_water_uses] }.each do |uses, include_timeseries|
      uses.each do |key, use|
        use.variables.each do |_sys_id, varkey, var|
          Model.add_output_variable(model, key_value: varkey, variable_name: var, reporting_frequency: 'runperiod')
          if include_timeseries
            Model.add_output_variable(model, key_value: varkey, variable_name: var, reporting_frequency: args[:timeseries_frequency])
          end
          next unless use.is_a?(EndUse)

          fuel_type, _end_use = key
          if fuel_type == FT::Elec && args[:include_hourly_electric_end_use_consumptions]
            Model.add_output_variable(model, key_value: varkey, variable_name: var, reporting_frequency: 'hourly')
          end
        end
        use.meters.each do |_, _, meter|
          Model.add_output_meter(model, meter_name: meter, reporting_frequency: 'runperiod')
          if include_timeseries
            Model.add_output_meter(model, meter_name: meter, reporting_frequency: args[:timeseries_frequency])
          end
          next unless use.is_a?(EndUse)

          fuel_type, _end_use = key
          if fuel_type == FT::Elec && args[:include_hourly_electric_end_use_consumptions]
            Model.add_output_meter(model, meter_name: meter, reporting_frequency: 'hourly')
          end
        end
      end
    end

    # Peak Fuel outputs (annual only)
    @peak_fuels.values.each do |peak_fuel|
      Model.add_output_table_monthly(model, name: peak_fuel.report, output_var_or_meter_name: peak_fuel.meter, aggregation_type: 'Maximum')
    end

    # Peak Load outputs (annual only)
    @peak_loads.values.each do |peak_load|
      ems_ov = Model.add_ems_output_variable(model, name: "#{peak_load.ems_variable}_peakload_outvar", ems_variable_name: peak_load.ems_variable, type_of_data: 'Summed', update_frequency: 'ZoneTimestep', ems_program_or_subroutine: total_loads_program, units: 'J')
      Model.add_output_table_monthly(model, name: peak_load.report, output_var_or_meter_name: ems_ov.name.to_s, aggregation_type: 'Maximum')
    end

    # Unmet Hours (annual only)
    @unmet_hours.each do |key, unmet_hour|
      next if key == UHT::Driving && unmet_driving_hrs_program.nil?

      ems_program = key == UHT::Driving ? unmet_driving_hrs_program : unmet_hours_program

      ems_ov = Model.add_ems_output_variable(model, name: "#{unmet_hour.ems_variable}_annual_outvar", ems_variable_name: unmet_hour.ems_variable, type_of_data: 'Summed', update_frequency: 'ZoneTimestep', ems_program_or_subroutine: ems_program, units: 'hr')
      Model.add_output_variable(model, key_value: '*', variable_name: ems_ov.name.to_s, reporting_frequency: 'runperiod')
      if args[:include_timeseries_unmet_hours]
        ems_ov = Model.add_ems_output_variable(model, name: "#{unmet_hour.ems_variable}_timeseries_outvar", ems_variable_name: unmet_hour.ems_variable, type_of_data: 'Summed', update_frequency: 'ZoneTimestep', ems_program_or_subroutine: ems_program, units: 'hr')
        Model.add_output_variable(model, key_value: '*', variable_name: ems_ov.name.to_s, reporting_frequency: args[:timeseries_frequency])
      end
    end

    # Component Load outputs
    @component_loads.values.each do |comp_load|
      next if comp_loads_program.nil?

      ems_ov = Model.add_ems_output_variable(model, name: "#{comp_load.ems_variable}_annual_outvar", ems_variable_name: comp_load.ems_variable, type_of_data: 'Summed', update_frequency: 'ZoneTimestep', ems_program_or_subroutine: comp_loads_program, units: 'J')
      Model.add_output_variable(model, key_value: '*', variable_name: ems_ov.name.to_s, reporting_frequency: 'runperiod')
      if args[:include_timeseries_component_loads]
        ems_ov = Model.add_ems_output_variable(model, name: "#{comp_load.ems_variable}_timeseries_outvar", ems_variable_name: comp_load.ems_variable, type_of_data: 'Summed', update_frequency: 'ZoneTimestep', ems_program_or_subroutine: comp_loads_program, units: 'J')
        Model.add_output_variable(model, key_value: '*', variable_name: ems_ov.name.to_s, reporting_frequency: args[:timeseries_frequency])
      end
    end

    # Total Load outputs
    @loads.values.each do |load|
      if not load.ems_variable.nil?
        ems_ov = Model.add_ems_output_variable(model, name: "#{load.ems_variable}_annual_outvar", ems_variable_name: load.ems_variable, type_of_data: 'Summed', update_frequency: 'ZoneTimestep', ems_program_or_subroutine: total_loads_program, units: 'J')
        Model.add_output_variable(model, key_value: '*', variable_name: ems_ov.name.to_s, reporting_frequency: 'runperiod')
        if args[:include_timeseries_total_loads]
          ems_ov = Model.add_ems_output_variable(model, name: "#{load.ems_variable}_timeseries_outvar", ems_variable_name: load.ems_variable, type_of_data: 'Summed', update_frequency: 'ZoneTimestep', ems_program_or_subroutine: total_loads_program, units: 'J')
          Model.add_output_variable(model, key_value: '*', variable_name: ems_ov.name.to_s, reporting_frequency: args[:timeseries_frequency])
        end
      end
      load.variables.each do |_sys_id, varkey, var|
        Model.add_output_variable(model, key_value: varkey, variable_name: var, reporting_frequency: 'runperiod')
        if args[:include_timeseries_total_loads]
          Model.add_output_variable(model, key_value: varkey, variable_name: var, reporting_frequency: args[:timeseries_frequency])
        end
      end
    end

    # Temperature outputs (timeseries only)
    if args[:include_timeseries_zone_temperatures]
      Model.add_output_variable(model, key_value: '*', variable_name: 'Zone Mean Air Temperature', reporting_frequency: args[:timeseries_frequency])

      # For reporting temperature-scheduled spaces timeseries temperatures.
      keys = [HPXML::LocationOtherHeatedSpace,
              HPXML::LocationOtherMultifamilyBufferSpace,
              HPXML::LocationOtherNonFreezingSpace,
              HPXML::LocationOtherHousingUnit,
              HPXML::LocationExteriorWall,
              HPXML::LocationUnderSlab]
      keys.each do |key|
        schedules = @model.getScheduleConstants.select { |sch| sch.additionalProperties.getFeatureAsString('ObjectType').to_s == key }
        next if schedules.empty?

        Model.add_output_variable(model, key_value: schedules[0].name.to_s.upcase, variable_name: 'Schedule Value', reporting_frequency: args[:timeseries_frequency])
      end

      # Also report thermostat setpoints
      heated_zones.each do |heated_zone|
        Model.add_output_variable(model, key_value: heated_zone.upcase, variable_name: 'Zone Thermostat Heating Setpoint Temperature', reporting_frequency: args[:timeseries_frequency])
      end
      cooled_zones.each do |cooled_zone|
        Model.add_output_variable(model, key_value: cooled_zone.upcase, variable_name: 'Zone Thermostat Cooling Setpoint Temperature', reporting_frequency: args[:timeseries_frequency])
      end
    end

    # Detailed air condition outputs (timeseries only)
    if args[:include_timeseries_zone_conditions]
      Model.add_output_variable(model, key_value: '*', variable_name: 'Zone Air Humidity Ratio', reporting_frequency: args[:timeseries_frequency])
      Model.add_output_variable(model, key_value: '*', variable_name: 'Zone Air Relative Humidity', reporting_frequency: args[:timeseries_frequency])
      Model.add_output_variable(model, key_value: '*', variable_name: 'Zone Mean Air Dewpoint Temperature', reporting_frequency: args[:timeseries_frequency])
      Model.add_output_variable(model, key_value: '*', variable_name: 'Zone Mean Radiant Temperature', reporting_frequency: args[:timeseries_frequency])
      Model.add_output_variable(model, key_value: '*', variable_name: 'Zone Operative Temperature', reporting_frequency: args[:timeseries_frequency])
    end

    # Airflow outputs (timeseries only)
    if args[:include_timeseries_airflows]
      @airflows.each do |_airflow_type, airflow|
        ems_ov = Model.add_ems_output_variable(model, name: "#{airflow.ems_variable}_timeseries_outvar", ems_variable_name: airflow.ems_variable, type_of_data: 'Averaged', update_frequency: 'ZoneTimestep', ems_program_or_subroutine: total_airflows_program, units: 'm^3/s')
        Model.add_output_variable(model, key_value: '*', variable_name: ems_ov.name.to_s, reporting_frequency: args[:timeseries_frequency])
      end
    end

    # Weather outputs (timeseries only)
    if args[:include_timeseries_weather]
      @weather.values.each do |weather_data|
        Model.add_output_variable(model, key_value: '*', variable_name: weather_data.variable, reporting_frequency: args[:timeseries_frequency])
      end
    end

    # Output variables (timeseries only)
    @output_variables_requests.each do |output_variable_name|
      Model.add_output_variable(model, key_value: '*', variable_name: output_variable_name, reporting_frequency: args[:timeseries_frequency])
    end

    # Output meters (timeseries only)
    @output_meters_requests.each do |output_meter_name|
      Model.add_output_meter(model, meter_name: output_meter_name, reporting_frequency: args[:timeseries_frequency])
    end

    return true
  end

  # Define what happens when the measure is run.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param user_arguments [OpenStudio::Measure::OSArgumentMap] OpenStudio measure arguments
  # @return [Boolean] true if successful
  def run(runner, user_arguments)
    super(runner, user_arguments)

    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find OpenStudio model.')
      return false
    end
    @model = model.get

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(@model), user_arguments)
      return false
    end

    args = get_arguments(runner, arguments(model), user_arguments)

    if args[:output_format] == 'csv_dview'
      args[:output_format] = 'csv'
      args[:use_dview_format] = true
    else
      args[:use_dview_format] = false
    end

    hpxml_defaults_path = @model.getBuilding.additionalProperties.getFeatureAsString('hpxml_defaults_path').get
    output_dir = File.dirname(hpxml_defaults_path)
    building_id = @model.getBuilding.additionalProperties.getFeatureAsString('building_id').get
    hpxml = HPXML.new(hpxml_path: hpxml_defaults_path, building_id: building_id)

    @hpxml_header = hpxml.header
    @hpxml_bldgs = hpxml.buildings

    setup_outputs(false, args)

    if not File.exist? File.join(output_dir, 'eplusout.msgpack')
      runner.registerError('Cannot find eplusout.msgpack.')
      return false
    end
    @msgpackData = MessagePack.unpack(File.read(File.join(output_dir, 'eplusout.msgpack'), mode: 'rb'))
    @msgpackDataRunPeriod = MessagePack.unpack(File.read(File.join(output_dir, 'eplusout_runperiod.msgpack'), mode: 'rb'))
    msgpack_timeseries_path = File.join(output_dir, "eplusout_#{args[:timeseries_frequency]}.msgpack")
    if File.exist? msgpack_timeseries_path
      @msgpackDataTimeseries = MessagePack.unpack(File.read(msgpack_timeseries_path, mode: 'rb'))
    end
    if args[:timeseries_frequency] != EPlus::TimeseriesFrequencyHourly
      msgpack_hourly_path = File.join(output_dir, 'eplusout_hourly.msgpack')
      if File.exist? msgpack_hourly_path
        @msgpackDataHourly = MessagePack.unpack(File.read(msgpack_hourly_path, mode: 'rb'))
      end
    end

    # Set paths
    if not args[:annual_output_file_name].nil?
      annual_output_path = File.join(output_dir, args[:annual_output_file_name])
    else
      annual_output_path = File.join(output_dir, "results_annual.#{args[:output_format]}")
    end
    if not args[:timeseries_output_file_name].nil?
      timeseries_output_path = File.join(output_dir, args[:timeseries_output_file_name])
    else
      timeseries_output_path = File.join(output_dir, "results_timeseries.#{args[:output_format]}")
    end

    if args[:timeseries_frequency] != EPlus::TimeseriesFrequencyNone
      @timestamps, @timestamps_dst, @timestamps_utc = get_timestamps(@msgpackDataTimeseries, @msgpackData, @hpxml_header, @hpxml_bldgs, args)
    end

    # Retrieve outputs
    get_outputs(runner, args)

    if not check_for_errors(runner)
      return false
    end

    # Write/report results
    report_runperiod_output_results(runner, args, annual_output_path)
    report_timeseries_output_results(runner, timeseries_output_path, args)

    return true
  end

  # Returns timestamp strings to be used in the timeseries output file.
  #
  # @param msgpackDataTimeseries [Hash] Raw E+ MessagePack timeseries output
  # @param msgpackData [Hash] Raw E+ MessagePack output
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param hpxml_bldgs [Array<HPXML::Building>] List of HPXML Building objects representing individual dwelling units
  # @param args [Hash] Map of :argument_name => value
  # @return [Array<String>, Array<String>, Array<String>] List of timestamps, list of timestamps in DST, list of timestamps in UTC
  def get_timestamps(msgpackDataTimeseries, msgpackData, hpxml_header, hpxml_bldgs, args)
    if not msgpackDataTimeseries.nil?
      ep_timestamps = msgpackDataTimeseries['Rows'].map { |r| r.keys[0] }
    elsif not msgpackData.nil?
      msgpack_timeseries_name = EPlus::get_msgpack_timeseries_name(args[:timeseries_frequency])
      timeseries_data = msgpackData['MeterData'][msgpack_timeseries_name]
      if not timeseries_data.nil?
        ep_timestamps = timeseries_data['Rows'].map { |r| r.keys[0] }
      end
    end

    return if ep_timestamps.nil?

    if args[:add_timeseries_dst_column] || args[:use_dview_format]
      dst_start_ts = Time.utc(hpxml_header.sim_calendar_year, hpxml_bldgs[0].dst_begin_month, hpxml_bldgs[0].dst_begin_day, 2)
      dst_end_ts = Time.utc(hpxml_header.sim_calendar_year, hpxml_bldgs[0].dst_end_month, hpxml_bldgs[0].dst_end_day, 1)
    end
    if args[:add_timeseries_utc_column]
      utc_offset = hpxml_bldgs[0].time_zone_utc_offset
      utc_offset *= 3600 # seconds
    end

    timestamps = []
    timestamps_dst = [] if args[:add_timeseries_dst_column] || args[:use_dview_format]
    timestamps_utc = [] if args[:add_timeseries_utc_column]
    year = hpxml_header.sim_calendar_year
    ep_timestamps.each do |ep_timestamp|
      month_day, hour_minute = ep_timestamp.split(' ')
      month, day = month_day.split('/').map(&:to_i)
      hour, minute, _ = hour_minute.split(':').map(&:to_i)

      # Convert from EnergyPlus default (end-of-timestep) to start-of-timestep convention
      if args[:timeseries_timestamp_convention] == 'start'
        case args[:timeseries_frequency]
        when EPlus::TimeseriesFrequencyTimestep
          ts_offset = hpxml_header.timestep * 60 # seconds
        when EPlus::TimeseriesFrequencyHourly
          ts_offset = 60 * 60 # seconds
        when EPlus::TimeseriesFrequencyDaily
          ts_offset = 60 * 60 * 24 # seconds
        when EPlus::TimeseriesFrequencyMonthly
          ts_offset = Calendar.num_days_in_months(year)[month - 1] * 60 * 60 * 24 # seconds
        else
          fail "Unexpected timeseries_frequency: #{args[:timeseries_frequency]}."
        end
      end

      ts = Time.utc(year, month, day, hour, minute)
      ts -= ts_offset unless ts_offset.nil?

      timestamps << ts.iso8601.delete('Z')

      if args[:add_timeseries_dst_column] || args[:use_dview_format]
        if (ts >= dst_start_ts) && (ts < dst_end_ts)
          ts_dst = ts + 3600 # 1 hr shift forward
        else
          ts_dst = ts
        end
        timestamps_dst << ts_dst.iso8601.delete('Z')
      end

      if args[:add_timeseries_utc_column]
        ts_utc = ts - utc_offset
        timestamps_utc << ts_utc.iso8601
      end
    end

    return timestamps, timestamps_dst, timestamps_utc
  end

  # Returns the number of hours in the run period.
  #
  # @param timeseries_frequency [String] Timeseries reporting frequency (TimeseriesFrequencyXXX)
  # @param sim_start_day [TODO] TODO
  # @param sim_end_day [TODO] TODO
  # @param year [Integer] the calendar year
  # @return [Integer] Number of hours in the run period
  def get_n_hours_per_period(timeseries_frequency, sim_start_day, sim_end_day, year)
    if timeseries_frequency == EPlus::TimeseriesFrequencyDaily
      n_hours_per_period = [24] * (sim_end_day - sim_start_day + 1)
    elsif timeseries_frequency == EPlus::TimeseriesFrequencyMonthly
      n_days_per_month = Calendar.num_days_in_months(year)
      n_days_per_period = n_days_per_month[@hpxml_header.sim_begin_month - 1..@hpxml_header.sim_end_month - 1]
      n_days_per_period[0] -= @hpxml_header.sim_begin_day - 1
      n_days_per_period[-1] = @hpxml_header.sim_end_day
      n_hours_per_period = n_days_per_period.map { |x| x * 24 }
    end
    return n_hours_per_period
  end

  # TODO
  #
  # @param timeseries_output [TODO] TODO
  # @param timeseries_frequency [String] Timeseries reporting frequency (TimeseriesFrequencyXXX)
  # @param average [Boolean] TODO
  # @return [TODO] TODO
  def rollup_timeseries_output_to_daily_or_monthly(timeseries_output, timeseries_frequency, average = false)
    year = @hpxml_header.sim_calendar_year
    sim_start_day, sim_end_day = get_sim_days_of_year(year)
    n_hours_per_period = get_n_hours_per_period(timeseries_frequency, sim_start_day, sim_end_day, year)
    fail 'Unexpected failure for n_hours_per_period calculations.' if n_hours_per_period.sum != timeseries_output.size

    ts_output = []
    start_hour = 0
    n_hours_per_period.each do |n_hours|
      timeseries = timeseries_output[start_hour..start_hour + n_hours - 1].sum()
      timeseries /= timeseries_output[start_hour..start_hour + n_hours - 1].size if average
      ts_output << timeseries
      start_hour += n_hours
    end
    return ts_output
  end

  # TODO
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def get_outputs(runner, args)
    args = setup_timeseries_includes(@emissions, args)

    # Fuel Uses
    @fuels.each do |(_fuel_type, _total_or_net), fuel|
      fuel.annual_output = get_report_meter_data_annual([fuel.meter])
      next unless args[:include_timeseries_fuel_consumptions]

      fuel.timeseries_output = get_report_meter_data_timeseries([fuel.meter], UnitConversions.convert(1.0, 'J', fuel.timeseries_units), 0, args[:timeseries_frequency])
    end

    # Peak Electricity Consumption
    is_southern_hemisphere = @model.getBuilding.additionalProperties.getFeatureAsBoolean('is_southern_hemisphere').get
    is_northern_hemisphere = !is_southern_hemisphere
    @peak_fuels.each do |key, peak_fuel|
      _fuel, _total_or_net, season = key
      if (season == PFT::Summer && is_northern_hemisphere) || (season == PFT::Winter && is_southern_hemisphere)
        months = ['June', 'July', 'August']
      elsif (season == PFT::Winter && is_northern_hemisphere) || (season == PFT::Summer && is_southern_hemisphere)
        months = ['December', 'January', 'February']
      elsif season == PFT::Annual
        months = ['Maximum of Months']
      end
      for month in months
        val = get_tabular_data_value(peak_fuel.report.upcase, 'Meter', 'Custom Monthly Report', [month], "#{peak_fuel.meter.upcase} {Maximum}", peak_fuel.annual_units)
        peak_fuel.annual_output = [peak_fuel.annual_output.to_f, val].max
      end
    end

    # Total loads
    @loads.each do |_load_type, load|
      if not load.ems_variable.nil?
        # Obtain from EMS output variable
        load.annual_output = get_report_variable_data_annual(['EMS'], ["#{load.ems_variable}_annual_outvar"])
        if args[:include_timeseries_total_loads]
          load.timeseries_output = get_report_variable_data_timeseries(['EMS'], ["#{load.ems_variable}_timeseries_outvar"], UnitConversions.convert(1.0, 'J', load.timeseries_units), 0, args[:timeseries_frequency], ems_shift: true)
        end
      elsif load.variables.size > 0
        # Obtain from output variable
        load.variables.map { |v| v[0] }.uniq.each do |sys_id|
          keys = load.variables.select { |v| v[0] == sys_id }.map { |v| v[1] }
          vars = load.variables.select { |v| v[0] == sys_id }.map { |v| v[2] }

          load.annual_output_by_system[sys_id] = get_report_variable_data_annual(keys, vars, is_negative: load.is_negative)
          if args[:include_timeseries_total_loads]
            load.timeseries_output_by_system[sys_id] = get_report_variable_data_timeseries(keys, vars, UnitConversions.convert(1.0, 'J', load.timeseries_units), 0, args[:timeseries_frequency], is_negative: load.is_negative, ems_shift: true)
          end
        end
      end
    end

    # Component Loads
    @component_loads.each do |_key, comp_load|
      comp_load.annual_output = get_report_variable_data_annual(['EMS'], ["#{comp_load.ems_variable}_annual_outvar"])
      if args[:include_timeseries_component_loads]
        comp_load.timeseries_output = get_report_variable_data_timeseries(['EMS'], ["#{comp_load.ems_variable}_timeseries_outvar"], UnitConversions.convert(1.0, 'J', comp_load.timeseries_units), 0, args[:timeseries_frequency], ems_shift: true)
      end
    end

    # Unmet Hours
    @unmet_hours.each do |key, unmet_hour|
      unmet_hour.annual_output = get_report_variable_data_annual(['EMS'], ["#{unmet_hour.ems_variable}_annual_outvar"], 1.0)
      if args[:include_timeseries_unmet_hours]
        unmet_hour.timeseries_output = get_report_variable_data_timeseries(['EMS'], ["#{unmet_hour.ems_variable}_timeseries_outvar"], 1.0, 0, args[:timeseries_frequency])
      end

      if key == UHT::Driving && unmet_hour.annual_output > 0.0
        runner.registerWarning("A total of #{unmet_hour.annual_output} driving hours could not be met due to insufficient vehicle charge. This issue may result from a combination EV battery parameters, charging power, and driving or discharging schedules.")
      end
    end

    # Peak Building Space Heating/Cooling Loads (total heating/cooling energy delivered including backup ideal air system)
    @peak_loads.each do |_load_type, peak_load|
      peak_load.annual_output = UnitConversions.convert(get_tabular_data_value(peak_load.report.upcase, 'EMS', 'Custom Monthly Report', ['Maximum of Months'], "#{peak_load.ems_variable.upcase}_PEAKLOAD_OUTVAR {Maximum}", 'W'), 'W', peak_load.annual_units)
    end

    # End Uses
    @end_uses.each do |key, end_use|
      fuel_type, _end_use_type = key

      end_use.variables.map { |v| v[0] }.uniq.each do |sys_id|
        keys = end_use.variables.select { |v| v[0] == sys_id }.map { |v| v[1] }
        vars = end_use.variables.select { |v| v[0] == sys_id }.map { |v| v[2] }

        end_use.annual_output_by_system[sys_id] = get_report_variable_data_annual(keys, vars, is_negative: (end_use.is_negative || end_use.is_storage))

        if args[:include_timeseries_end_use_consumptions]
          end_use.timeseries_output_by_system[sys_id] = get_report_variable_data_timeseries(keys, vars, UnitConversions.convert(1.0, 'J', end_use.timeseries_units), 0, args[:timeseries_frequency], is_negative: (end_use.is_negative || end_use.is_storage))
        end
        if args[:include_hourly_electric_end_use_consumptions] && fuel_type == FT::Elec
          end_use.hourly_output_by_system[sys_id] = get_report_variable_data_timeseries(keys, vars, UnitConversions.convert(1.0, 'J', end_use.timeseries_units), 0, EPlus::TimeseriesFrequencyHourly, is_negative: (end_use.is_negative || end_use.is_storage))
        end
      end
      end_use.meters.map { |v| v[0] }.uniq.each do |sys_id|
        vars = end_use.meters.select { |v| v[0] == sys_id }.map { |v| v[2] }

        end_use.annual_output_by_system[sys_id] = 0.0 if end_use.annual_output_by_system[sys_id].nil?
        end_use.annual_output_by_system[sys_id] += get_report_meter_data_annual(vars, UnitConversions.convert(1.0, 'J', end_use.annual_units))

        if args[:include_timeseries_end_use_consumptions]
          values = get_report_meter_data_timeseries(vars, UnitConversions.convert(1.0, 'J', end_use.timeseries_units), 0, args[:timeseries_frequency])
          if end_use.timeseries_output_by_system[sys_id].nil?
            end_use.timeseries_output_by_system[sys_id] = values
          else
            end_use.timeseries_output_by_system[sys_id] = end_use.timeseries_output_by_system[sys_id].zip(values).map { |x, y| x + y }
          end
        end
        next unless args[:include_hourly_electric_end_use_consumptions] && fuel_type == FT::Elec

        values = get_report_meter_data_timeseries(vars, UnitConversions.convert(1.0, 'J', end_use.timeseries_units), 0, EPlus::TimeseriesFrequencyHourly)
        if end_use.hourly_output_by_system[sys_id].nil?
          end_use.hourly_output_by_system[sys_id] = values
        else
          end_use.hourly_output_by_system[sys_id] = end_use.hourly_output_by_system[sys_id].zip(values).map { |x, y| x + y }
        end
      end
    end

    # Disaggregate 8760 GSHP shared pump energy into heating vs cooling by
    # applying proportionally to the GSHP heating & cooling fan/pump energy use.
    gshp_shared_loop_end_use = @end_uses[[FT::Elec, 'TempGSHPSharedPump']]
    htg_fan_pump_end_use = @end_uses[[FT::Elec, EUT::HeatingFanPump]]
    backup_htg_fan_pump_end_use = @end_uses[[FT::Elec, EUT::HeatingHeatPumpBackupFanPump]]
    clg_fan_pump_end_use = @end_uses[[FT::Elec, EUT::CoolingFanPump]]
    gshp_shared_loop_end_use.annual_output_by_system.keys.each do |sys_id|
      # Calculate heating & cooling fan/pump end use multiplier
      htg_energy = htg_fan_pump_end_use.annual_output_by_system[sys_id].to_f + backup_htg_fan_pump_end_use.annual_output_by_system[sys_id].to_f
      clg_energy = clg_fan_pump_end_use.annual_output_by_system[sys_id].to_f
      shared_pump_energy = gshp_shared_loop_end_use.annual_output_by_system[sys_id]
      energy_multiplier = (htg_energy + clg_energy + shared_pump_energy) / (htg_energy + clg_energy)
      # Apply multiplier
      [htg_fan_pump_end_use, backup_htg_fan_pump_end_use, clg_fan_pump_end_use].each do |end_use|
        next if end_use.annual_output_by_system[sys_id].nil?

        apply_multiplier_to_output(end_use, [], sys_id, energy_multiplier)
      end
    end
    @end_uses.delete([FT::Elec, 'TempGSHPSharedPump'])

    # Hot Water Uses
    @hot_water_uses.each do |_hot_water_type, hot_water|
      hot_water.variables.map { |v| v[0] }.uniq.each do |sys_id|
        keys = hot_water.variables.select { |v| v[0] == sys_id }.map { |v| v[1] }
        vars = hot_water.variables.select { |v| v[0] == sys_id }.map { |v| v[2] }

        hot_water.annual_output_by_system[sys_id] = get_report_variable_data_annual(keys, vars, UnitConversions.convert(1.0, 'm^3', hot_water.annual_units))
        if args[:include_timeseries_hot_water_uses]
          hot_water.timeseries_output_by_system[sys_id] = get_report_variable_data_timeseries(keys, vars, UnitConversions.convert(1.0, 'm^3', hot_water.timeseries_units), 0, args[:timeseries_frequency])
        end
      end
    end

    @hpxml_bldgs.each do |hpxml_bldg|
      # Apply Heating/Cooling DSEs
      (hpxml_bldg.heating_systems + hpxml_bldg.heat_pumps).each do |htg_system|
        next unless (htg_system.is_a?(HPXML::HeatingSystem) && htg_system.is_heat_pump_backup_system) || htg_system.fraction_heat_load_served > 0
        next if htg_system.distribution_system_idref.nil?
        next unless htg_system.distribution_system.distribution_system_type == HPXML::HVACDistributionTypeDSE
        next if htg_system.distribution_system.annual_heating_dse.nil?

        dse = htg_system.distribution_system.annual_heating_dse
        @unique_fuel_types.each do |fuel_type|
          [EUT::Heating, EUT::HeatingHeatPumpBackup, EUT::HeatingFanPump, EUT::HeatingHeatPumpBackupFanPump].each do |end_use_type|
            end_use = @end_uses[[fuel_type, end_use_type]]
            next if end_use.nil?
            next if end_use.annual_output_by_system[htg_system.id].nil?

            fuels = @fuels.select { |k, _v| k[0] == fuel_type }.values
            apply_multiplier_to_output(end_use, fuels, htg_system.id, 1.0 / dse)
          end
        end
      end
      (hpxml_bldg.cooling_systems + hpxml_bldg.heat_pumps).each do |clg_system|
        next unless clg_system.fraction_cool_load_served > 0
        next if clg_system.distribution_system_idref.nil?
        next unless clg_system.distribution_system.distribution_system_type == HPXML::HVACDistributionTypeDSE
        next if clg_system.distribution_system.annual_cooling_dse.nil?

        dse = clg_system.distribution_system.annual_cooling_dse
        @unique_fuel_types.each do |fuel_type|
          [EUT::Cooling, EUT::CoolingFanPump].each do |end_use_type|
            end_use = @end_uses[[fuel_type, end_use_type]]
            next if end_use.nil?
            next if end_use.annual_output_by_system[clg_system.id].nil?

            fuels = @fuels.select { |k, _v| k[0] == fuel_type }.values
            apply_multiplier_to_output(end_use, fuels, clg_system.id, 1.0 / dse)
          end
        end
      end

      # Apply solar fraction to load for simple solar water heating systems
      hpxml_bldg.solar_thermal_systems.each do |solar_system|
        next if solar_system.solar_fraction.nil?

        @loads[LT::HotWaterSolarThermal].annual_output = 0.0 if @loads[LT::HotWaterSolarThermal].annual_output.nil?
        @loads[LT::HotWaterSolarThermal].timeseries_output = [0.0] * @timestamps.size if @loads[LT::HotWaterSolarThermal].timeseries_output.nil?

        if not solar_system.water_heating_system.nil?
          dhw_ids = [solar_system.water_heating_system.id]
        else # Apply to all water heating systems
          dhw_ids = hpxml_bldg.water_heating_systems.map { |dhw| dhw.id }
        end
        dhw_ids.each do |dhw_id|
          apply_multiplier_to_output(@loads[LT::HotWaterDelivered], [@loads[LT::HotWaterSolarThermal]], dhw_id, 1.0 / (1.0 - solar_system.solar_fraction))
        end
      end
    end

    # Calculate System Uses from End Uses (by HPXML System)
    @system_uses = {}
    get_hpxml_system_ids.each do |sys_id|
      @end_uses.each do |eu_key, end_use|
        annual_output = end_use.annual_output_by_system[sys_id].to_f
        next if annual_output <= 0

        system_use_output = BaseOutput.new
        @system_uses[[sys_id, eu_key]] = system_use_output
        fuel_type, end_use_type = eu_key
        system_use_output.name = "System Use: #{sys_id}: #{fuel_type}: #{end_use_type}"

        # Annual
        system_use_output.annual_output = annual_output
        system_use_output.annual_units = end_use.annual_units

        next unless args[:include_timeseries_system_use_consumptions]

        # Timeseries
        system_use_output.timeseries_output = end_use.timeseries_output_by_system[sys_id]
        system_use_output.timeseries_units = end_use.timeseries_units
      end
    end

    # Calculate aggregated values from per-system values as needed
    (@end_uses.values + @loads.values + @hot_water_uses.values).each do |obj|
      # Annual
      if obj.annual_output.nil?
        if not obj.annual_output_by_system.empty?
          obj.annual_output = obj.annual_output_by_system.values.sum(0.0)
        else
          obj.annual_output = 0.0
        end
      end

      # Timeseries
      if obj.timeseries_output.empty? && (not obj.timeseries_output_by_system.empty?)
        obj.timeseries_output = obj.timeseries_output_by_system.values.transpose.map(&:sum)
      end

      # Hourly Electricity (for Cambium)
      next unless obj.is_a?(EndUse) && obj.hourly_output.empty? && (not obj.hourly_output_by_system.empty?)

      obj.hourly_output = obj.hourly_output_by_system.values.transpose.map(&:sum)
    end

    # Total/Net Energy
    @totals[TE::Total].annual_output = 0.0
    @totals[TE::Net].annual_output = 0.0
    @fuels.each do |(fuel_type, total_or_net), fuel|
      if fuel_type == FT::Elec
        te_types = [total_or_net]
      else
        te_types = [TE::Total, TE::Net]
      end

      te_types.each do |te_type|
        @totals[te_type].annual_output += fuel.annual_output
      end
      next unless args[:include_timeseries_total_consumptions] && fuel.timeseries_output.sum != 0.0

      te_types.each do |te_type|
        @totals[te_type].timeseries_output = [0.0] * @timestamps.size if @totals[te_type].timeseries_output.empty?
        unit_conv = UnitConversions.convert(1.0, fuel.timeseries_units, @totals[te_type].timeseries_units)
        @totals[te_type].timeseries_output = @totals[te_type].timeseries_output.zip(fuel.timeseries_output).map { |x, y| x + y * unit_conv }
      end
    end

    # Resilience
    @resilience.each do |key, resilience|
      next unless key == RT::Battery
      next unless (args[:include_annual_resilience] || args[:include_timeseries_resilience])
      next if resilience.variables.empty?

      batteries = []
      @hpxml_bldgs.each do |hpxml_bldg|
        hpxml_bldg.batteries.each do |battery|
          batteries << battery
        end
      end
      next if batteries.empty?

      if batteries.size > 1
        # When modeling individual dwelling units, OS-HPXML only allows a single battery
        # When modeling whole SFA/MF buildings, OS-HPXML does not currently allow batteries
        fail 'Unexpected error.'
      end

      battery = batteries[0]

      elcd = @model.getElectricLoadCenterDistributions.find { |elcd| elcd.additionalProperties.getFeatureAsString('HPXML_ID').to_s == battery.id }
      next if elcd.nil?

      elcs = @model.getElectricLoadCenterStorageLiIonNMCBatterys.find { |elcs| elcs.additionalProperties.getFeatureAsString('HPXML_ID').to_s == battery.id }

      resilience_frequency = EPlus::TimeseriesFrequencyTimestep
      ts_per_hr = @model.getTimestep.numberOfTimestepsPerHour
      if args[:timeseries_frequency] != EPlus::TimeseriesFrequencyTimestep
        resilience_frequency = EPlus::TimeseriesFrequencyHourly
        ts_per_hr = 1
      end

      vars = ['Electric Storage Charge Fraction']
      keys = resilience.variables.select { |v| v[2] == vars[0] }.map { |v| v[1] }
      batt_soc = get_report_variable_data_timeseries(keys, vars, 1, 0, resilience_frequency)

      vars = ['Other Equipment Electricity Energy']
      keys = resilience.variables.select { |v| v[2] == vars[0] }.map { |v| v[1] }
      batt_loss = get_report_variable_data_timeseries(keys, vars, UnitConversions.convert(1.0, 'J', 'kWh'), 0, resilience_frequency)

      min_soc = elcd.minimumStorageStateofChargeFraction
      batt_kw = elcd.designStorageControlDischargePower.get / 1000.0
      batt_roundtrip_eff = elcs.dctoDCChargingEfficiency
      batt_kwh = elcs.additionalProperties.getFeatureAsDouble('UsableCapacity_kWh').get

      batt_soc_kwh = batt_soc.map { |soc| soc - min_soc }.map { |soc| soc * batt_kwh }
      elec_prod = get_report_meter_data_timeseries(['ElectricityProduced:Facility'], UnitConversions.convert(1.0, 'J', 'kWh'), 0, resilience_frequency)
      elec_stor = get_report_meter_data_timeseries(['ElectricStorage:ElectricityProduced'], UnitConversions.convert(1.0, 'J', 'kWh'), 0, resilience_frequency)
      elec_prod = elec_prod.zip(elec_stor).map { |x, y| -1 * (x - y) }
      elec = get_report_meter_data_timeseries(['Electricity:Facility'], UnitConversions.convert(1.0, 'J', 'kWh'), 0, resilience_frequency)
      crit_load = elec.zip(elec_prod, batt_loss).map { |x, y, z| x + y + z }

      resilience_timeseries = []
      n_timesteps = crit_load.size
      (0...n_timesteps).each do |init_time_step|
        resilience_timeseries << get_resilience_timeseries(init_time_step, batt_kwh, batt_kw, batt_soc_kwh[init_time_step], crit_load, batt_roundtrip_eff, n_timesteps, ts_per_hr)
      end

      resilience.annual_output = resilience_timeseries.sum(0.0) / resilience_timeseries.size

      next unless args[:include_timeseries_resilience]

      resilience.timeseries_output = resilience_timeseries

      # Aggregate up from hourly to the desired timeseries frequency
      if [EPlus::TimeseriesFrequencyDaily, EPlus::TimeseriesFrequencyMonthly].include? args[:timeseries_frequency]
        resilience.timeseries_output = rollup_timeseries_output_to_daily_or_monthly(resilience.timeseries_output, args[:timeseries_frequency], true)
      end
    end

    # Get zones of interest
    zone_names = []
    @model.getThermalZones.each do |zone|
      next unless zone.floorArea > 1 # Skip e.g. plenum zone for duct model

      zone_names << zone.name.to_s.upcase
    end
    zone_names.sort!

    # Returns a user-friendly version of the object name for output.
    #
    # @param object_name [String] OpenStudio object name
    # @return [String] Output name
    def sanitize_name(object_name)
      return object_name.gsub('_', ' ').split.map(&:capitalize).join(' ')
    end

    # Zone temperatures
    if args[:include_timeseries_zone_temperatures]

      zone_names.each do |zone_name|
        @zone_temps[zone_name] = ZoneTemp.new
        @zone_temps[zone_name].name = "Temperature: #{sanitize_name(zone_name)}"
        @zone_temps[zone_name].timeseries_units = 'F'
        @zone_temps[zone_name].timeseries_output = get_report_variable_data_timeseries([zone_name], ['Zone Mean Air Temperature'], 9.0 / 5.0, 32.0, args[:timeseries_frequency])
      end

      # Scheduled temperatures
      [HPXML::LocationOtherHeatedSpace, HPXML::LocationOtherMultifamilyBufferSpace,
       HPXML::LocationOtherNonFreezingSpace, HPXML::LocationOtherHousingUnit,
       HPXML::LocationExteriorWall, HPXML::LocationUnderSlab].each do |sch_location|
        @model.getScheduleConstants.each do |schedule|
          next unless schedule.additionalProperties.getFeatureAsString('ObjectType').to_s == sch_location

          sch_name = schedule.name.to_s.upcase
          @zone_temps[sch_name] = ZoneTemp.new
          @zone_temps[sch_name].name = "Temperature: #{sanitize_name(sch_name)}"
          @zone_temps[sch_name].timeseries_units = 'F'
          @zone_temps[sch_name].timeseries_output = get_report_variable_data_timeseries([sch_name], ['Schedule Value'], 9.0 / 5.0, 32.0, args[:timeseries_frequency])

          break
        end
      end

      # Heating Setpoints
      heated_zones = eval(@model.getBuilding.additionalProperties.getFeatureAsString('heated_zones').get)
      heated_zones.each do |heated_zone|
        var_name = 'Temperature: Heating Setpoint'
        if @hpxml_header.whole_sfa_or_mf_building_sim
          unit_num = @model.getThermalZones.find { |z| z.name.to_s == heated_zone }.spaces[0].buildingUnit.get.additionalProperties.getFeatureAsInteger('unit_num').get
          var_name = "Temperature: Unit#{unit_num} Heating Setpoint"
        end
        @zone_temps["#{heated_zone} Heating Setpoint"] = ZoneTemp.new
        @zone_temps["#{heated_zone} Heating Setpoint"].name = var_name
        @zone_temps["#{heated_zone} Heating Setpoint"].timeseries_units = 'F'
        @zone_temps["#{heated_zone} Heating Setpoint"].timeseries_output = get_report_variable_data_timeseries([heated_zone.upcase], ['Zone Thermostat Heating Setpoint Temperature'], 9.0 / 5.0, 32.0, args[:timeseries_frequency])
      end

      # Cooling Setpoints
      cooled_zones = eval(@model.getBuilding.additionalProperties.getFeatureAsString('cooled_zones').get)
      cooled_zones.each do |cooled_zone|
        var_name = 'Temperature: Cooling Setpoint'
        if @hpxml_header.whole_sfa_or_mf_building_sim
          unit_num = @model.getThermalZones.find { |z| z.name.to_s == cooled_zone }.spaces[0].buildingUnit.get.additionalProperties.getFeatureAsInteger('unit_num').get
          var_name = "Temperature: Unit#{unit_num} Cooling Setpoint"
        end
        @zone_temps["#{cooled_zone} Cooling Setpoint"] = ZoneTemp.new
        @zone_temps["#{cooled_zone} Cooling Setpoint"].name = var_name
        @zone_temps["#{cooled_zone} Cooling Setpoint"].timeseries_units = 'F'
        @zone_temps["#{cooled_zone} Cooling Setpoint"].timeseries_output = get_report_variable_data_timeseries([cooled_zone.upcase], ['Zone Thermostat Cooling Setpoint Temperature'], 9.0 / 5.0, 32.0, args[:timeseries_frequency])
      end
    end

    # Zone detailed conditions
    if args[:include_timeseries_zone_conditions]

      # Zone humidity ratios
      zone_names.each do |zone_name|
        @zone_conds["#{zone_name} Humidity Ratio"] = ZoneCond.new
        @zone_conds["#{zone_name} Humidity Ratio"].name = "Humidity Ratio: #{sanitize_name(zone_name)}"
        @zone_conds["#{zone_name} Humidity Ratio"].timeseries_units = 'fraction'
        @zone_conds["#{zone_name} Humidity Ratio"].timeseries_output = get_report_variable_data_timeseries([zone_name], ['Zone Air Humidity Ratio'], 1, 0, args[:timeseries_frequency])
      end

      # Zone relative humidities
      zone_names.each do |zone_name|
        @zone_conds["#{zone_name} Relative Humidity"] = ZoneCond.new
        @zone_conds["#{zone_name} Relative Humidity"].name = "Relative Humidity: #{sanitize_name(zone_name)}"
        @zone_conds["#{zone_name} Relative Humidity"].timeseries_units = '%'
        @zone_conds["#{zone_name} Relative Humidity"].timeseries_output = get_report_variable_data_timeseries([zone_name], ['Zone Air Relative Humidity'], 1, 0, args[:timeseries_frequency])
      end

      # Zone dewpoint temperatures
      zone_names.each do |zone_name|
        @zone_conds["#{zone_name} Dewpoint Temperature"] = ZoneCond.new
        @zone_conds["#{zone_name} Dewpoint Temperature"].name = "Dewpoint Temperature: #{sanitize_name(zone_name)}"
        @zone_conds["#{zone_name} Dewpoint Temperature"].timeseries_units = 'F'
        @zone_conds["#{zone_name} Dewpoint Temperature"].timeseries_output = get_report_variable_data_timeseries([zone_name], ['Zone Mean Air Dewpoint Temperature'], 9.0 / 5.0, 32.0, args[:timeseries_frequency])
      end

      # Zone mean radiant temperatures
      zone_names.each do |zone_name|
        @zone_conds["#{zone_name} Radiant Temperature"] = ZoneCond.new
        @zone_conds["#{zone_name} Radiant Temperature"].name = "Radiant Temperature: #{sanitize_name(zone_name)}"
        @zone_conds["#{zone_name} Radiant Temperature"].timeseries_units = 'F'
        @zone_conds["#{zone_name} Radiant Temperature"].timeseries_output = get_report_variable_data_timeseries([zone_name], ['Zone Mean Radiant Temperature'], 9.0 / 5.0, 32.0, args[:timeseries_frequency])
      end

      # Zone operative temperatures
      zone_names.each do |zone_name|
        @zone_conds["#{zone_name} Operative Temperature"] = ZoneCond.new
        @zone_conds["#{zone_name} Operative Temperature"].name = "Operative Temperature: #{sanitize_name(zone_name)}"
        @zone_conds["#{zone_name} Operative Temperature"].timeseries_units = 'F'
        @zone_conds["#{zone_name} Operative Temperature"].timeseries_output = get_report_variable_data_timeseries([zone_name], ['Zone Operative Temperature'], 9.0 / 5.0, 32.0, args[:timeseries_frequency])
      end
    end

    # Airflows
    if args[:include_timeseries_airflows]
      @airflows.each do |_airflow_type, airflow|
        airflow.timeseries_output = get_report_variable_data_timeseries(['EMS'], ["#{airflow.ems_variable}_timeseries_outvar"], UnitConversions.convert(1, 'm^3/s', 'cfm'), 0, args[:timeseries_frequency], ems_shift: true)
      end
    end

    # Weather
    if args[:include_timeseries_weather]
      @weather.each do |_weather_type, weather_data|
        if weather_data.timeseries_units == 'F'
          unit_conv = 9.0 / 5.0
          unit_adder = 32.0
        else
          unit_conv = UnitConversions.convert(1.0, weather_data.variable_units, weather_data.timeseries_units)
          unit_adder = 0
        end
        weather_data.timeseries_output = get_report_variable_data_timeseries(['Environment'], [weather_data.variable], unit_conv, unit_adder, args[:timeseries_frequency])
      end
    end

    # Output Variables
    @output_variables = {}
    @output_variables_requests.each do |output_variable_name|
      key_values, units = get_report_variable_data_timeseries_key_values_and_units(output_variable_name)
      if key_values.empty?
        runner.registerWarning("Request for output variable '#{output_variable_name}' returned no results.")
        next
      end

      key_values.each do |key_value|
        @output_variables[[output_variable_name, key_value]] = OutputVariableOrMeter.new
        @output_variables[[output_variable_name, key_value]].name = "#{output_variable_name}: #{key_value.split.map(&:capitalize).join(' ')}"
        @output_variables[[output_variable_name, key_value]].timeseries_units = units
        @output_variables[[output_variable_name, key_value]].timeseries_output = get_report_variable_data_timeseries([key_value], [output_variable_name], 1, 0, args[:timeseries_frequency])
      end
    end

    # Output Meters
    @output_meters = {}
    @output_meters_requests.each do |output_meter_name|
      units = get_report_meter_data_timeseries_units(output_meter_name, args[:timeseries_frequency])
      if units.nil?
        runner.registerWarning("Request for output meter '#{output_meter_name}' returned no results.")
        next
      end

      @output_meters[output_meter_name] = OutputVariableOrMeter.new
      @output_meters[output_meter_name].name = output_meter_name
      @output_meters[output_meter_name].timeseries_units = units
      @output_meters[output_meter_name].timeseries_output = get_report_meter_data_timeseries([output_meter_name], 1, 0, args[:timeseries_frequency])
    end

    # Emissions
    if not @emissions.empty?
      kwh_to_mwh = UnitConversions.convert(1.0, 'kWh', 'MWh')

      # Calculate for each scenario
      @hpxml_header.emissions_scenarios.each do |scenario|
        key = [scenario.emissions_type, scenario.name]

        # Get hourly electricity factors
        if not scenario.elec_schedule_filepath.nil?
          # Obtain Cambium hourly factors for the simulation run period
          num_header_rows = scenario.elec_schedule_number_of_header_rows
          col_index = scenario.elec_schedule_column_number - 1
          data = File.readlines(scenario.elec_schedule_filepath)[num_header_rows, 8760]
          hourly_elec_factors = data.map { |x| x.split(',')[col_index].strip }
          begin
            hourly_elec_factors = hourly_elec_factors.map { |x| Float(x) }
          rescue
            fail 'Emissions File has non-numeric values.'
          end
        elsif not scenario.elec_value.nil?
          # Use annual value for all hours
          hourly_elec_factors = [scenario.elec_value] * 8760
        end

        # Calculate annual/timeseries emissions for each end use
        do_trim = true
        @end_uses.each do |eu_key, end_use|
          fuel_type, _end_use_type = eu_key
          next unless fuel_type == FT::Elec
          next unless end_use.hourly_output.size > 0

          hourly_elec = end_use.hourly_output

          # Trim hourly electricity factors to the run period; do once.
          if do_trim
            do_trim = false

            year = 1999 # Try non-leap year for calculations
            sim_start_hour, sim_end_hour = get_sim_hours_of_year(year)
            if hourly_elec.size == hourly_elec_factors[sim_start_hour..sim_end_hour].size + 24
              # Duplicate Feb 28 Cambium values for Feb 29
              hourly_elec_factors = hourly_elec_factors[0..1415] + hourly_elec_factors[1392..1415] + hourly_elec_factors[1416..8759]
              # Use leap-year for calculations
              year = 2000
              sim_start_hour, sim_end_hour = get_sim_hours_of_year(year)
            end
            hourly_elec_factors = hourly_elec_factors[sim_start_hour..sim_end_hour]
          end

          fail 'Unexpected failure for emissions calculations.' if hourly_elec_factors.size != hourly_elec.size

          # Calculate annual emissions for end use
          if scenario.elec_units == HPXML::EmissionsScenario::UnitsKgPerMWh
            elec_units_mult = UnitConversions.convert(1.0, 'kg', 'lbm')
          elsif scenario.elec_units == HPXML::EmissionsScenario::UnitsLbPerMWh
            elec_units_mult = 1.0
          end
          @emissions[key].annual_output_by_end_use[eu_key] = hourly_elec.zip(hourly_elec_factors).map { |x, y| x * y * kwh_to_mwh * elec_units_mult }.sum

          next unless args[:include_timeseries_emissions] || args[:include_timeseries_emission_end_uses] || args[:include_timeseries_emission_fuels]

          # Calculate timeseries emissions for end use

          if args[:timeseries_frequency] == EPlus::TimeseriesFrequencyTimestep && @hpxml_header.timestep != 60
            timeseries_elec = end_use.timeseries_output_by_system.values.transpose.map(&:sum).map { |x| x * kwh_to_mwh }
          else
            # Need to perform calculations hourly at a minimum
            timeseries_elec = end_use.hourly_output.map { |x| x * kwh_to_mwh }
          end

          if args[:timeseries_frequency] == EPlus::TimeseriesFrequencyTimestep
            n_timesteps_per_hour = Integer(60.0 / @hpxml_header.timestep)
            timeseries_elec_factors = hourly_elec_factors.flat_map { |y| [y] * n_timesteps_per_hour }
          else
            timeseries_elec_factors = hourly_elec_factors.dup
          end
          fail 'Unexpected failure for emissions calculations.' if timeseries_elec_factors.size != timeseries_elec.size

          @emissions[key].timeseries_output_by_end_use[eu_key] = timeseries_elec.zip(timeseries_elec_factors).map { |n, f| n * f * elec_units_mult }

          # Aggregate up from hourly to the desired timeseries frequency
          if [EPlus::TimeseriesFrequencyDaily, EPlus::TimeseriesFrequencyMonthly].include? args[:timeseries_frequency]
            @emissions[key].timeseries_output_by_end_use[eu_key] = rollup_timeseries_output_to_daily_or_monthly(@emissions[key].timeseries_output_by_end_use[eu_key], args[:timeseries_frequency])
          end
        end

        # Calculate emissions for fossil fuels
        @end_uses.each do |eu_key, end_use|
          fuel_type, _end_use_type = eu_key
          next if fuel_type == FT::Elec

          fuel_map = { FT::Gas => [scenario.natural_gas_units, scenario.natural_gas_value],
                       FT::Propane => [scenario.propane_units, scenario.propane_value],
                       FT::Oil => [scenario.fuel_oil_units, scenario.fuel_oil_value],
                       FT::Coal => [scenario.coal_units, scenario.coal_value],
                       FT::WoodCord => [scenario.wood_units, scenario.wood_value],
                       FT::WoodPellets => [scenario.wood_pellets_units, scenario.wood_pellets_value] }
          fuel_units, fuel_factor = fuel_map[fuel_type]
          if fuel_factor.nil?
            if end_use.annual_output != 0
              runner.registerWarning("No emissions factor found for Scenario=#{scenario.name}, Type=#{scenario.emissions_type}, Fuel=#{fuel_type}.")
            end
            fuel_factor = 0.0
            fuel_units_mult = 0.0
          elsif fuel_units == HPXML::EmissionsScenario::UnitsKgPerMBtu
            fuel_units_mult = UnitConversions.convert(1.0, 'kg', 'lbm')
          elsif fuel_units == HPXML::EmissionsScenario::UnitsLbPerMBtu
            fuel_units_mult = 1.0
          end

          @emissions[key].annual_output_by_end_use[eu_key] = UnitConversions.convert(end_use.annual_output, end_use.annual_units, 'MBtu') * fuel_factor * fuel_units_mult
          next unless args[:include_timeseries_emissions] || args[:include_timeseries_emission_end_uses] || args[:include_timeseries_emission_fuels]

          fuel_to_mbtu = UnitConversions.convert(1.0, end_use.timeseries_units, 'MBtu')
          @emissions[key].timeseries_output_by_end_use[eu_key] = end_use.timeseries_output_by_system.values.transpose.map(&:sum).map { |f| f * fuel_to_mbtu * fuel_factor * fuel_units_mult }
        end

        # Roll up end use emissions to fuel emissions
        @fuels.each do |(fuel_type, total_or_net), _fuel|
          fuel_key = [fuel_type, total_or_net]
          @emissions[key].annual_output_by_fuel[fuel_key] = 0.0
          @emissions[key].annual_output_by_end_use.keys.each do |eu_key|
            next unless eu_key[0] == fuel_type
            next if total_or_net == TE::Total && @end_uses[eu_key].is_negative # Generation not included in total
            next if @emissions[key].annual_output_by_end_use[eu_key] == 0

            @emissions[key].annual_output_by_fuel[fuel_key] += @emissions[key].annual_output_by_end_use[eu_key]

            next unless args[:include_timeseries_emissions] || args[:include_timeseries_emission_fuels]

            @emissions[key].timeseries_output_by_fuel[fuel_key] = [0.0] * @emissions[key].timeseries_output_by_end_use[eu_key].size if @emissions[key].timeseries_output_by_fuel[fuel_key].nil?
            @emissions[key].timeseries_output_by_fuel[fuel_key] = @emissions[key].timeseries_output_by_fuel[fuel_key].zip(@emissions[key].timeseries_output_by_end_use[eu_key]).map { |x, y| x + y }
          end
        end

        # Sum individual fuel results for total/net
        total_keys = @emissions[key].annual_output_by_fuel.keys.select { |k| k[0] != FT::Elec || (k[0] == FT::Elec && k[1] == TE::Total) }
        net_keys = @emissions[key].annual_output_by_fuel.keys.select { |k| k[0] != FT::Elec || (k[0] == FT::Elec && k[1] == TE::Net) }
        @emissions[key].annual_output = @emissions[key].annual_output_by_fuel.select { |k, _v| total_keys.include? k }.values.sum()
        @emissions[key].net_annual_output = @emissions[key].annual_output_by_fuel.select { |k, _v| net_keys.include? k }.values.sum()
        if args[:include_timeseries_emissions]
          @emissions[key].timeseries_output = @emissions[key].timeseries_output_by_fuel.select { |k, _v| total_keys.include? k }.values.transpose.map(&:sum)
          @emissions[key].net_timeseries_output = @emissions[key].timeseries_output_by_fuel.select { |k, _v| net_keys.include? k }.values.transpose.map(&:sum)
        end
      end
    end
  end

  # TODO
  #
  # @param year [Integer] the calendar year
  # @return [TODO] TODO
  def get_sim_days_of_year(year)
    sim_start_day = Calendar.get_day_num_from_month_day(year, @hpxml_header.sim_begin_month, @hpxml_header.sim_begin_day)
    sim_end_day = Calendar.get_day_num_from_month_day(year, @hpxml_header.sim_end_month, @hpxml_header.sim_end_day)
    return sim_start_day, sim_end_day
  end

  # TODO
  #
  # @param year [Integer] the calendar year
  # @return [TODO] TODO
  def get_sim_hours_of_year(year)
    sim_start_day, sim_end_day = get_sim_days_of_year(year)
    sim_start_hour = (sim_start_day - 1) * 24
    sim_end_hour = sim_end_day * 24 - 1
    return sim_start_hour, sim_end_hour
  end

  # Checks for inconsistencies in outputs -- e.g., timeseries outputs don't sum to annual values,
  # end use outputs don't sum to totals, etc.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @return [Boolean] True if no errors
  def check_for_errors(runner)
    tol = 0.1 # 0.1%

    # ElectricityProduced:Facility contains:
    # - Generator Produced DC Electricity Energy
    # - Inverter Conversion Loss Decrement Energy
    # - Electric Storage Production Decrement Energy
    # - Electric Storage Discharge Energy
    # - Converter Electricity Loss Decrement Energy (should always be zero since efficiency=1.0)
    # ElectricStorage:ElectricityProduced contains:
    # - Electric Storage Production Decrement Energy
    # - Electric Storage Discharge Energy
    # So, we need to subtract ElectricStorage:ElectricityProduced from ElectricityProduced:Facility
    meter_elec_produced = -1 * get_report_meter_data_annual(['ElectricityProduced:Facility'])
    meter_elec_produced += get_report_meter_data_annual(['ElectricStorage:ElectricityProduced'])

    # Check if simulation successful
    all_total = @fuels.values.map { |x| x.annual_output.to_f }.sum(0.0)
    total_fraction_cool_load_served = @hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.total_fraction_cool_load_served }.sum(0.0)
    total_fraction_heat_load_served = @hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.total_fraction_heat_load_served }.sum(0.0)
    if (all_total == 0) && (total_fraction_cool_load_served + total_fraction_heat_load_served > 0)
      runner.registerError('Simulation unsuccessful.')
      return false
    elsif all_total.infinite?
      runner.registerError('Simulation used infinite energy; double-check inputs.')
      return false
    end

    # Check sum of electricity produced end use outputs match total output from meter
    sum_elec_prod_annual = @end_uses.select { |k, eu| k[0] == FT::Elec && eu.is_negative }.map { |_k, eu| eu.annual_output.to_f }.sum(0.0) # Negative value
    avg_value = (sum_elec_prod_annual + meter_elec_produced) / 2.0
    if (sum_elec_prod_annual - meter_elec_produced).abs / avg_value > tol
      runner.registerError("#{FT::Elec} produced category end uses (#{sum_elec_prod_annual.round(3)}) do not sum to total (#{meter_elec_produced.round(3)}).")
      return false
    end

    # Check sum of end use outputs match fuel outputs from meters
    @unique_fuel_types.each do |fuel_type|
      total_or_net = (fuel_type == FT::Elec ? TE::Net : TE::Total)
      sum_categories = @end_uses.select { |k, _eu| k[0] == fuel_type }.map { |_k, eu| eu.annual_output.to_f }.sum(0.0)
      meter_fuel_total = @fuels[[fuel_type, total_or_net]].annual_output.to_f

      avg_value = (sum_categories + meter_fuel_total) / 2.0
      next unless (sum_categories - meter_fuel_total).abs / avg_value > tol

      runner.registerError("#{fuel_type} category end uses (#{sum_categories.round(3)}) do not sum to total (#{meter_fuel_total.round(3)}).")
      return false
    end

    # Check sum of system use outputs match end use outputs
    system_use_sums = {}
    @system_uses.each do |key, system_use|
      _sys_id, eu_key = key
      system_use_sums[eu_key] = 0 if system_use_sums[eu_key].nil?
      system_use_sums[eu_key] += system_use.annual_output
    end
    system_use_sums.each do |eu_key, sum_systems|
      end_use_total = @end_uses[eu_key].annual_output.to_f
      avg_value = (sum_systems + end_use_total) / 2.0
      next unless (sum_systems - end_use_total).abs / avg_value > tol

      runner.registerError("System uses (#{sum_systems.round(3)}) do not sum to total (#{end_use_total.round(3)}) for End Use: #{eu_key.join(': ')}.")
      return false
    end

    # Check sum of timeseries outputs match annual outputs
    { @totals => 'Total',
      @end_uses => 'End Use',
      @system_uses => 'System Use',
      @fuels => 'Fuel',
      @emissions => 'Emissions',
      @loads => 'Load',
      @component_loads => 'Component Load' }.each do |outputs, output_type|
      outputs.each do |key, obj|
        next if obj.timeseries_output.empty?

        sum_timeseries = UnitConversions.convert(obj.timeseries_output.sum(0.0), obj.timeseries_units, obj.annual_units)
        annual_total = obj.annual_output.to_f
        avg_value = (annual_total + sum_timeseries) / 2.0
        if (annual_total - sum_timeseries).abs / avg_value > tol
          runner.registerError("Timeseries outputs (#{sum_timeseries.round(3)}) do not sum to annual output (#{annual_total.round(3)}) for #{output_type}: #{key}.")
          return false
        end
      end
    end

    return true
  end

  # Writes out results for the entire run period to an output file (CSV, JSON, etc.).
  # Also reports results to the OpenStudio runner).
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param args [Hash] Map of :argument_name => value
  # @param annual_output_path [String] Path for the output file
  # @return [nil]
  def report_runperiod_output_results(runner, args, annual_output_path)
    # Set rounding precision for run period (e.g., annual) outputs.
    if args[:output_format] == 'msgpack'
      # No need to round; no file size penalty to storing full precision
      n_digits = 100
    else
      # Note: Make sure to round outputs with sufficient resolution for the worst case -- i.e., 1 day instead of a full year.
      n_digits = 3 # Default for annual (or near-annual) data
      sim_n_days = (Calendar.get_day_num_from_month_day(2000, @hpxml_header.sim_end_month, @hpxml_header.sim_end_day) -
                    Calendar.get_day_num_from_month_day(2000, @hpxml_header.sim_begin_month, @hpxml_header.sim_begin_day))
      if sim_n_days <= 10 # 10 days or less; add two decimal places
        n_digits += 2
      elsif sim_n_days <= 100 # 100 days or less; add one decimal place
        n_digits += 1
      end
    end

    line_break = nil

    results_out = []

    # Totals
    if args[:include_annual_total_consumptions]
      @totals.each do |_energy_type, total_energy|
        results_out << ["#{total_energy.name} (#{total_energy.annual_units})", total_energy.annual_output.to_f.round(n_digits)]
      end
      results_out << [line_break]
    end

    # Fuels
    if args[:include_annual_fuel_consumptions]
      @fuels.each do |(_fuel_type, _total_or_net), fuel|
        results_out << ["#{fuel.name} (#{fuel.annual_units})", fuel.annual_output.to_f.round(n_digits)]
      end
      results_out << [line_break]
    end

    # End uses
    if args[:include_annual_end_use_consumptions]
      @end_uses.each do |_key, end_use|
        results_out << ["#{end_use.name} (#{end_use.annual_units})", end_use.annual_output.to_f.round(n_digits)]
      end
      results_out << [line_break]
    end

    # System uses
    if args[:include_annual_system_use_consumptions]
      @system_uses.each do |_key, system_use|
        results_out << ["#{system_use.name} (#{system_use.annual_units})", system_use.annual_output.round(n_digits)]
      end
      results_out << [line_break]
    end

    # Total Emissions
    if args[:include_annual_emissions] && (not @emissions.empty?)
      @emissions.each do |_scenario_key, emission|
        results_out << ["#{emission.name}: Total (#{emission.annual_units})", emission.annual_output.to_f.round(n_digits - 1)]
        results_out << ["#{emission.name}: Net (#{emission.annual_units})", emission.net_annual_output.to_f.round(n_digits - 1)]
      end
      results_out << [line_break]
    end

    # Fuel Emissions
    if args[:include_annual_emission_fuels] && (not @emissions.empty?)
      @emissions.each do |_scenario_key, emission|
        emission.annual_output_by_fuel.keys.each do |fuel_key|
          fuel, emission_type = fuel_key
          results_out << ["#{emission.name}: #{fuel}: #{emission_type} (#{emission.annual_units})", emission.annual_output_by_fuel[fuel_key].to_f.round(n_digits - 1)]
        end
      end
      results_out << [line_break]
    end

    # End Use Emissions
    if args[:include_annual_emission_end_uses] && (not @emissions.empty?)
      @emissions.each do |_scenario_key, emission|
        @unique_fuel_types.each do |fuel_type|
          @end_uses.keys.select { |k| k[0] == fuel_type }.each do |key|
            end_use_fuel_type, end_use_type = key
            results_out << ["#{emission.name}: #{end_use_fuel_type}: #{end_use_type} (#{emission.annual_units})", emission.annual_output_by_end_use[key].to_f.round(n_digits - 1)]
          end
        end
      end
      results_out << [line_break]
    end

    # Loads
    if args[:include_annual_total_loads]
      @loads.each do |_load_type, load|
        results_out << ["#{load.name} (#{load.annual_units})", load.annual_output.to_f.round(n_digits)]
      end
      results_out << [line_break]
    end

    # Unmet hours
    if args[:include_annual_unmet_hours]
      @unmet_hours.each do |_load_type, unmet_hour|
        results_out << ["#{unmet_hour.name} (#{unmet_hour.annual_units})", unmet_hour.annual_output.to_f.round(3)]
      end
      results_out << [line_break]
    end

    # Peak fuels
    if args[:include_annual_peak_fuels]
      @peak_fuels.each do |_key, peak_fuel|
        results_out << ["#{peak_fuel.name} (#{peak_fuel.annual_units})", peak_fuel.annual_output.to_f.round(n_digits - 2)]
      end
      results_out << [line_break]
    end

    # Peak loads
    if args[:include_annual_peak_loads]
      @peak_loads.each do |_load_type, peak_load|
        results_out << ["#{peak_load.name} (#{peak_load.annual_units})", peak_load.annual_output.to_f.round(n_digits)]
      end
      results_out << [line_break]
    end

    # Component loads
    if args[:include_annual_component_loads] && @component_loads.values.map { |load| load.annual_output.to_f }.sum != 0 # Skip if component loads not calculated
      @component_loads.each do |_load_type, load|
        results_out << ["#{load.name} (#{load.annual_units})", load.annual_output.to_f.round(n_digits)]
      end
      results_out << [line_break]
    end

    # Hot water uses
    if args[:include_annual_hot_water_uses]
      @hot_water_uses.each do |_hot_water_type, hot_water|
        results_out << ["#{hot_water.name} (#{hot_water.annual_units})", hot_water.annual_output.to_f.round(n_digits - 2)]
      end
      results_out << [line_break]
    end

    # Resilience
    if args[:include_annual_resilience]
      @resilience.each do |_type, resilience|
        results_out << ["#{resilience.name} (#{resilience.annual_units})", resilience.annual_output.to_f.round(3)]
      end
      results_out << [line_break]
    end

    # Sizing data
    if args[:include_annual_hvac_summary]
      results_out = Outputs.append_sizing_results(@hpxml_bldgs, results_out)
    end

    # Check for duplicate results
    results_data = results_out.select { |e| e != [line_break] }
    if results_data.size != results_data.uniq.size
      fail "Duplicate results found: #{results_data.select { |e| results_data.count(e) > 1 }.uniq}"
    end

    Outputs.write_results_out_to_file(results_out, args[:output_format], annual_output_path)
    runner.registerInfo("Wrote annual output results to #{annual_output_path}.")

    # Electric panel
    results_out += Outputs.get_panel_results(@hpxml_header, @hpxml_bldgs)

    Outputs.register_results_out_to_runner(runner, results_out)
  end

  # Writes out timeseries results to an output file (CSV, JSON, etc.).
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param timeseries_output_path [String] Path for the output file
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def report_timeseries_output_results(runner, timeseries_output_path, args)
    return if @timestamps.nil?

    if not [EPlus::TimeseriesFrequencyTimestep, EPlus::TimeseriesFrequencyHourly, EPlus::TimeseriesFrequencyDaily, EPlus::TimeseriesFrequencyMonthly].include? args[:timeseries_frequency]
      fail "Unexpected timeseries_frequency: #{args[:timeseries_frequency]}."
    end

    if not args[:timeseries_num_decimal_places].nil?
      n_digits = args[:timeseries_num_decimal_places]
    elsif args[:output_format] == 'msgpack'
      # No need to round; no file size penalty to storing full precision
      n_digits = 100
    else
      # Set rounding precision for timeseries (e.g., hourly) outputs.
      # Note: Make sure to round outputs with sufficient resolution for the worst case -- i.e., 1 minute date instead of hourly data.
      n_digits = 3 # Default for hourly (or longer) data
      if args[:timeseries_frequency] == EPlus::TimeseriesFrequencyTimestep
        if @hpxml_header.timestep <= 2 # 2-minute timesteps or shorter; add two decimal places
          n_digits += 2
        elsif @hpxml_header.timestep <= 15 # 15-minute timesteps or shorter; add one decimal place
          n_digits += 1
        end
      end
    end

    # Initial output data w/ Time column(s)
    data = ['Time', nil] + @timestamps
    timestamps2 = args[:add_timeseries_dst_column] ? [['TimeDST', nil] + @timestamps_dst] : []
    timestamps3 = args[:add_timeseries_utc_column] ? [['TimeUTC', nil] + @timestamps_utc] : []

    # Gather timeseries outputs
    total_energy_data, fuel_data, end_use_data, system_use_data = [], [], [], []
    emissions_data, emission_fuel_data, emission_end_use_data = [], [], []
    hot_water_use_data, total_loads_data, comp_loads_data, unmet_hours_data = [], [], [], []
    zone_temps_data, zone_conds_data, airflows_data, weather_data, resilience_data = [], [], [], [], []
    output_variables_data, output_meters_data = [], []

    # Totals
    if args[:include_timeseries_total_consumptions]
      total_energy_data = []
      [TE::Total, TE::Net].each do |energy_type|
        next if @totals[energy_type].timeseries_output.empty?

        total_energy_data << [@totals[energy_type].name, @totals[energy_type].timeseries_units] + @totals[energy_type].timeseries_output.map { |v| v.round(n_digits) }
      end
    end

    # Fuels
    if args[:include_timeseries_fuel_consumptions]
      fuel_data = @fuels.values.select { |x| x.timeseries_output.sum(0.0) != 0 }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(n_digits) } }
    end

    # End uses
    if args[:include_timeseries_end_use_consumptions]
      end_use_data = @end_uses.values.select { |x| x.timeseries_output.sum(0.0) != 0 }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(n_digits) } }
    end

    # System uses
    if args[:include_timeseries_system_use_consumptions]
      system_use_data = @system_uses.values.select { |x| x.timeseries_output.sum(0.0) != 0 }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(n_digits) } }
    end

    # Total Emissions
    if args[:include_timeseries_emissions]
      @emissions.values.each do |emission|
        next if emission.timeseries_output.sum(0.0) == 0

        emissions_data << ["#{emission.name}: Total", emission.timeseries_units] + emission.timeseries_output.map { |v| v.round(n_digits + 2) }
        emissions_data << ["#{emission.name}: Net", emission.timeseries_units] + emission.net_timeseries_output.map { |v| v.round(n_digits + 2) }
      end
    end

    # Fuel Emissions
    if args[:include_timeseries_emission_fuels]
      @emissions.values.each do |emission|
        emission.timeseries_output_by_fuel.each do |fuel_key, timeseries_output|
          fuel, emission_type = fuel_key
          next if timeseries_output.sum(0.0) == 0

          emission_fuel_data << ["#{emission.name}: #{fuel}: #{emission_type}", emission.timeseries_units] + timeseries_output.map { |v| v.round(n_digits + 2) }
        end
      end
    end

    # End Use Emissions
    if args[:include_timeseries_emission_end_uses]
      @emissions.values.each do |emission|
        emission.timeseries_output_by_end_use.each do |key, timeseries_output|
          next if timeseries_output.sum(0.0) == 0

          fuel_type, end_use_type = key
          emission_end_use_data << ["#{emission.name}: #{fuel_type}: #{end_use_type}", emission.timeseries_units] + timeseries_output.map { |v| v.round(n_digits + 2) }
        end
      end
    end

    # Hot water uses
    if args[:include_timeseries_hot_water_uses]
      hot_water_use_data = @hot_water_uses.values.select { |x| x.timeseries_output.sum(0.0) != 0 }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(n_digits) } }
    end

    # Loads
    if args[:include_timeseries_total_loads]
      total_loads_data = @loads.values.select { |x| x.timeseries_output.sum(0.0) != 0 }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(n_digits) } }
    end

    # Component loads
    if args[:include_timeseries_component_loads]
      comp_loads_data = @component_loads.values.select { |x| x.timeseries_output.sum(0.0) != 0 }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(n_digits) } }
    end

    # Unmet hours
    if args[:include_timeseries_unmet_hours]
      unmet_hours_data = @unmet_hours.values.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(3) } }
    end

    # Zone temperatures
    if args[:include_timeseries_zone_temperatures]
      zone_temps_data = @zone_temps.values.select { |x| x.timeseries_output.sum(0.0) != 0 }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(3) } }
    end

    # Zone conditions (detailed)
    if args[:include_timeseries_zone_conditions]
      zone_conds_data = @zone_conds.values.select { |x| x.timeseries_output.sum(0.0) != 0 }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(4) } }
    end

    # Airflows
    if args[:include_timeseries_airflows]
      airflows_data = @airflows.values.select { |x| x.timeseries_output.sum(0.0) != 0 }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(3) } }
    end

    # Weather
    if args[:include_timeseries_weather]
      weather_data = @weather.values.select { |x| x.timeseries_output.sum(0.0) != 0 }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(3) } }
    end

    # Resilience
    if args[:include_timeseries_resilience]
      resilience_data = @resilience.values.select { |x| x.timeseries_output.sum(0.0) != 0 }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(3) } }
    end

    # EnergyPlus output variables
    if not @output_variables.empty?
      output_variables_data = @output_variables.values.map { |x| [x.name, x.timeseries_units] + x.timeseries_output }
    end

    # EnergyPlus output meters
    if not @output_meters.empty?
      output_meters_data = @output_meters.values.map { |x| [x.name, x.timeseries_units] + x.timeseries_output }
    end

    return if (total_energy_data.size + fuel_data.size + end_use_data.size + system_use_data.size + emissions_data.size + emission_fuel_data.size +
               emission_end_use_data.size + hot_water_use_data.size + total_loads_data.size + comp_loads_data.size + unmet_hours_data.size +
               zone_temps_data.size + zone_conds_data.size + airflows_data.size + weather_data.size + resilience_data.size + output_variables_data.size + output_meters_data.size) == 0

    fail 'Unable to obtain timestamps.' if @timestamps.empty?

    if ['csv'].include? args[:output_format]
      # Assemble data
      data = data.zip(*timestamps2, *timestamps3, *total_energy_data, *fuel_data, *end_use_data, *system_use_data, *emissions_data,
                      *emission_fuel_data, *emission_end_use_data, *hot_water_use_data, *total_loads_data, *comp_loads_data, *unmet_hours_data,
                      *zone_temps_data, *zone_conds_data, *airflows_data, *weather_data, *resilience_data, *output_variables_data, *output_meters_data)

      # Error-check
      n_elements = []
      data.each do |data_array|
        n_elements << data_array.size
      end
      if n_elements.uniq.size > 1
        fail "Inconsistent number of array elements: #{n_elements.uniq}."
      end

      if args[:use_dview_format]
        # Remove Time column(s)
        while data[0][0].include? 'Time'
          data = data.map { |a| a[1..-1] }
        end

        # Add header per DataFileTemplate.pdf; see https://github.com/NREL/wex/wiki/DView
        year = @hpxml_header.sim_calendar_year
        start_day = Calendar.get_day_num_from_month_day(year, @hpxml_header.sim_begin_month, @hpxml_header.sim_begin_day)
        start_hr = (start_day - 1) * 24
        case args[:timeseries_frequency]
        when EPlus::TimeseriesFrequencyTimestep
          interval_hrs = @hpxml_header.timestep / 60.0
        when EPlus::TimeseriesFrequencyHourly
          interval_hrs = 1.0
        when EPlus::TimeseriesFrequencyDaily
          interval_hrs = 24.0
        when EPlus::TimeseriesFrequencyMonthly
          interval_hrs = Calendar.num_days_in_year(year) * 24.0 / 12
        end
        header_data = [['wxDVFileHeaderVer.1'],
                       data[0].map { |d| d.sub(':', '|') }, # Series name (series can be organized into groups by entering Group Name|Series Name)
                       data[0].map { |_d| start_hr + interval_hrs / 2.0 }, # Start time of the first data point; 0.5 implies average over the first hour
                       data[0].map { |_d| interval_hrs }, # Time interval in hours
                       data[1]] # Units
        data.delete_at(1) # Remove units, added to header data above
        data.delete_at(0) # Remove series name, added to header data above

        # Apply daylight savings
        if args[:timeseries_frequency] == EPlus::TimeseriesFrequencyTimestep || args[:timeseries_frequency] == EPlus::TimeseriesFrequencyHourly
          if @hpxml_bldgs[0].dst_observed
            dst_start_ix, dst_end_ix = get_dst_start_end_indexes()
            if !dst_start_ix.nil? && !dst_end_ix.nil?
              dst_end_ix.downto(dst_start_ix + 1) do |i|
                data[i + 1] = data[i]
              end
            end
          end
        end

        data.insert(0, *header_data) # Add header data to beginning
      end

      # Write file
      # Note: We don't use the CSV library here because it's slow for large files
      File.open(timeseries_output_path, 'wb') { |csv| data.to_a.each { |elem| csv << "#{elem.join(',')}\n" } }
    elsif ['json', 'msgpack'].include? args[:output_format]
      # Assemble data
      h = {}
      h['Time'] = data[2..-1]
      h['TimeDST'] = timestamps2[0][2..-1] unless @timestamps_dst.nil?
      h['TimeUTC'] = timestamps3[0][2..-1] unless @timestamps_utc.nil?

      [total_energy_data, fuel_data, end_use_data, system_use_data, emissions_data, emission_fuel_data,
       emission_end_use_data, hot_water_use_data, total_loads_data, comp_loads_data, unmet_hours_data,
       zone_temps_data, zone_conds_data, airflows_data, weather_data, resilience_data, output_variables_data, output_meters_data].each do |d|
        d.each do |o|
          grp, name = o[0].split(':', 2)
          h[grp] = {} if h[grp].nil?
          h[grp]["#{name.strip} (#{o[1]})"] = o[2..-1]
        end
      end

      # Write file
      if args[:output_format] == 'json'
        require 'json'
        File.open(timeseries_output_path, 'w') { |json| json.write(JSON.pretty_generate(h)) }
      elsif args[:output_format] == 'msgpack'
        File.open(timeseries_output_path, 'wb') { |json| h.to_msgpack(json) }
      end
    end
    runner.registerInfo("Wrote timeseries output results to #{timeseries_output_path}.")
  end

  # TODO
  #
  # @return [TODO] TODO
  def get_dst_start_end_indexes()
    dst_start_ix = nil
    dst_end_ix = nil
    @timestamps.zip(@timestamps_dst).each_with_index do |ts, i|
      dst_start_ix = i if ts[0] != ts[1] && dst_start_ix.nil?
      dst_end_ix = i if ts[0] == ts[1] && dst_end_ix.nil? && !dst_start_ix.nil?
    end

    dst_end_ix = @timestamps.size - 1 if dst_end_ix.nil? && !dst_start_ix.nil? # run period ends before DST ends

    return dst_start_ix, dst_end_ix
  end

  # TODO
  #
  # @param meter_names [TODO] TODO
  # @param unit_conv [TODO] TODO
  # @return [TODO] TODO
  def get_report_meter_data_annual(meter_names, unit_conv = UnitConversions.convert(1.0, 'J', 'MBtu'))
    return 0.0 if meter_names.empty?

    cols = @msgpackData['MeterData']['RunPeriod']['Cols']
    timestamp = @msgpackData['MeterData']['RunPeriod']['Rows'][0].keys[0]
    row = @msgpackData['MeterData']['RunPeriod']['Rows'][0][timestamp]
    indexes = cols.each_index.select { |i| meter_names.include? cols[i]['Variable'] }
    val = row.each_index.select { |i| indexes.include? i }.map { |i| row[i] }.sum(0.0) * unit_conv

    return val
  end

  # TODO
  #
  # @param key_values [TODO] TODO
  # @param variables [TODO] TODO
  # @param unit_conv [TODO] TODO
  # @param is_negative [TODO] TODO
  # @return [TODO] TODO
  def get_report_variable_data_annual(key_values, variables, unit_conv = UnitConversions.convert(1.0, 'J', 'MBtu'), is_negative: false)
    return 0.0 if variables.empty?

    neg = is_negative ? -1.0 : 1.0
    keys_vars = key_values.zip(variables).map { |k, v| "#{k}:#{v}" }
    cols = @msgpackDataRunPeriod['Cols']
    timestamp = @msgpackDataRunPeriod['Rows'][0].keys[0]
    row = @msgpackDataRunPeriod['Rows'][0][timestamp]
    indexes = cols.each_index.select { |i| keys_vars.include? cols[i]['Variable'] }
    val = row.each_index.select { |i| indexes.include? i }.map { |i| row[i] }.sum(0.0) * unit_conv * neg

    return val
  end

  # TODO
  #
  # @param init_time_step [TODO] TODO
  # @param batt_kwh [TODO] TODO
  # @param batt_kw [TODO] TODO
  # @param batt_soc_kwh [TODO] TODO
  # @param crit_load [TODO] TODO
  # @param batt_roundtrip_eff [TODO] TODO
  # @param n_timesteps [TODO] TODO
  # @param ts_per_hr [TODO] TODO
  # @return [TODO] TODO
  def get_resilience_timeseries(init_time_step, batt_kwh, batt_kw, batt_soc_kwh, crit_load, batt_roundtrip_eff, n_timesteps, ts_per_hr)
    for i in 0...n_timesteps
      t = (init_time_step + i) % n_timesteps # for wrapping around end of year
      load_kw = crit_load[t]

      # even if load_kw is negative, we return if batt_soc_kwh isn't charged at all
      return i / Float(ts_per_hr) if batt_soc_kwh <= 0

      if load_kw < 0 # load is met with PV
        if batt_soc_kwh < batt_kwh # charge battery if there's room in the battery
          batt_soc_kwh += [
            batt_kwh - batt_soc_kwh, # room available
            batt_kw / batt_roundtrip_eff, # inverter capacity
            -load_kw * batt_roundtrip_eff, # excess energy
          ].min
        end

      else # check if we can meet load with generator then storage
        if [batt_kw, batt_soc_kwh].min >= load_kw # battery can carry balance
          # prevent battery charge from going negative
          batt_soc_kwh = [0, batt_soc_kwh - load_kw / batt_roundtrip_eff].max
          load_kw = 0
        end
      end

      if load_kw > 0 # failed to meet load in this time step
        return i / Float(ts_per_hr)
      end
    end

    return n_timesteps / Float(ts_per_hr)
  end

  # TODO
  #
  # @param meter_names [TODO] TODO
  # @param unit_conv [TODO] TODO
  # @param unit_adder [TODO] TODO
  # @param timeseries_frequency [String] Timeseries reporting frequency (TimeseriesFrequencyXXX)
  # @return [TODO] TODO
  def get_report_meter_data_timeseries(meter_names, unit_conv, unit_adder, timeseries_frequency)
    return [0.0] * @timestamps.size if meter_names.empty?

    msgpack_timeseries_name = EPlus::get_msgpack_timeseries_name(timeseries_frequency)
    timeseries_data = @msgpackData['MeterData'][msgpack_timeseries_name]
    cols = timeseries_data['Cols']
    rows = timeseries_data['Rows']
    indexes = cols.each_index.select { |i| meter_names.include? cols[i]['Variable'] }
    vals = [0.0] * rows.size

    # Calculate whether we need to shift values once up front
    shift_values = {}
    indexes.each_with_index do |_i, idx|
      shift_values[idx] = false
      if apply_ems_shift(timeseries_frequency)
        if meter_names[idx].include? Constants::ObjectTypeWaterHeaterAdjustment
          # Shift energy use adjustment to align with hot water energy use
          shift_values[idx] = true
        elsif meter_names[idx].include? Constants::ObjectTypePanHeater
          # Shift energy use adjustment to align with HVAC operation and weather
          shift_values[idx] = true
        elsif meter_names[idx].include? Constants::ObjectTypeHPDefrostSupplHeat
          # Shift energy use adjustment to align with HVAC operation and weather
          shift_values[idx] = true
        end
      end
    end

    rows.each_with_index do |row, row_idx|
      row = row[row.keys[0]]
      indexes.each_with_index do |i, idx|
        if shift_values[idx]
          vals[row_idx - 1] += row[i] * unit_conv + unit_adder
        else
          vals[row_idx] += row[i] * unit_conv + unit_adder
        end
      end
    end
    return vals
  end

  # TODO
  #
  # @param key_values [TODO] TODO
  # @param variables [TODO] TODO
  # @param unit_conv [TODO] TODO
  # @param unit_adder [TODO] TODO
  # @param timeseries_frequency [String] Timeseries reporting frequency (TimeseriesFrequencyXXX)
  # @param is_negative [TODO] TODO
  # @param ems_shift [TODO] TODO
  # @return [TODO] TODO
  def get_report_variable_data_timeseries(key_values, variables, unit_conv, unit_adder, timeseries_frequency, is_negative: false, ems_shift: false)
    return [0.0] * @timestamps.size if variables.empty?

    if key_values.uniq.size > 1 && key_values.include?('EMS') && ems_shift
      # Split into EMS and non-EMS queries so that the EMS values shift occurs for just the EMS query
      # Remove this code if we ever figure out a better way to handle when EMS output should shift
      ems_indices = key_values.each_index.select { |i| key_values[i] == 'EMS' }
      ems_key_values = key_values.select.with_index { |_kv, i| ems_indices.include? i }
      ems_variables = variables.select.with_index { |_kv, i| ems_indices.include? i }
      non_ems_key_values = key_values.select.with_index { |_kv, i| !ems_indices.include? i }
      non_ems_variables = variables.select.with_index { |_kv, i| !ems_indices.include? i }
      values = get_report_variable_data_timeseries(ems_key_values, ems_variables, unit_conv, unit_adder, timeseries_frequency, is_negative: is_negative, ems_shift: ems_shift)
      non_ems_values = get_report_variable_data_timeseries(non_ems_key_values, non_ems_variables, unit_conv, unit_adder, timeseries_frequency, is_negative: is_negative, ems_shift: ems_shift)
      sum_values = [values, non_ems_values].transpose.map(&:sum)
      return sum_values
    end

    if (timeseries_frequency == EPlus::TimeseriesFrequencyHourly) && (not @msgpackDataHourly.nil?)
      msgpack_data = @msgpackDataHourly
    else
      msgpack_data = @msgpackDataTimeseries
    end
    neg = is_negative ? -1.0 : 1.0
    keys_vars = key_values.zip(variables).map { |k, v| "#{k}:#{v}" }
    cols = msgpack_data['Cols']
    rows = msgpack_data['Rows']
    indexes = cols.each_index.select { |i| keys_vars.include? cols[i]['Variable'] }
    vals = [0.0] * rows.size
    rows.each_with_index do |row, row_idx|
      row = row[row.keys[0]]
      indexes.each do |i|
        vals[row_idx] += (row[i] * unit_conv + unit_adder) * neg
      end
    end

    return vals unless ems_shift

    # Remove this code if we ever figure out a better way to handle when EMS output should shift
    if (key_values.size == 1) && (key_values[0] == 'EMS') && (@timestamps.size > 0) && apply_ems_shift(timeseries_frequency)
      # Shift all values by 1 timestep due to EMS reporting lag
      return vals[1..-1] + [vals[0]]
    end

    return vals
  end

  # TODO
  #
  # @param timeseries_frequency [String] Timeseries reporting frequency (TimeseriesFrequencyXXX)
  # @return [TODO] TODO
  def apply_ems_shift(timeseries_frequency)
    # Only shift if we reporting timestep values (i.e., not daily, monthly, or hourly w/ a sub-hourly timestep)
    if (timeseries_frequency == EPlus::TimeseriesFrequencyTimestep)
      return true
    elsif (timeseries_frequency == EPlus::TimeseriesFrequencyHourly) && (@model.getTimestep.numberOfTimestepsPerHour == 1)
      return true
    end

    return false
  end

  # TODO
  #
  # @param var_name [TODO] TODO
  # @return [TODO] TODO
  def get_report_variable_data_timeseries_key_values_and_units(var_name)
    keys = []
    units = ''
    return keys, units if @msgpackDataTimeseries.nil?

    @msgpackDataTimeseries['Cols'].each do |col|
      next unless col['Variable'].end_with? ":#{var_name}"

      keys << col['Variable'].split(':')[0..-2].join(':')
      units = col['Units']
    end

    return keys, units
  end

  # TODO
  #
  # @param meter_name [TODO] TODO
  # @param timeseries_frequency [String] Timeseries reporting frequency (TimeseriesFrequencyXXX)
  # @return [TODO] TODO
  def get_report_meter_data_timeseries_units(meter_name, timeseries_frequency)
    return if @msgpackData.nil?

    msgpack_timeseries_name = EPlus::get_msgpack_timeseries_name(timeseries_frequency)
    timeseries_data = @msgpackData['MeterData'][msgpack_timeseries_name]
    return if timeseries_data.nil?

    timeseries_data['Cols'].each do |col|
      next unless col['Variable'] == meter_name

      return col['Units']
    end

    return
  end

  # TODO
  #
  # @param report_name [TODO] TODO
  # @param report_for_string [TODO] TODO
  # @param table_name [TODO] TODO
  # @param row_names [TODO] TODO
  # @param col_name [TODO] TODO
  # @param units [TODO] TODO
  # @return [TODO] TODO
  def get_tabular_data_value(report_name, report_for_string, table_name, row_names, col_name, units)
    vals = []
    @msgpackData['TabularReports'].each do |tabular_report|
      next if tabular_report['ReportName'] != report_name
      next if tabular_report['For'] != report_for_string

      tabular_report['Tables'].each do |table|
        next if table['TableName'] != table_name

        cols = table['Cols']
        index = cols.each_index.find { |i| cols[i] == "#{col_name} [#{units}]" }
        row_names.each do |row_name|
          vals << table['Rows'][row_name][index].to_f
        end
      end
    end

    return vals.sum(0.0)
  end

  # TODO
  #
  # @param obj [TODO] TODO
  # @param sync_objs [TODO] TODO
  # @param sys_id [TODO] TODO
  # @param mult [TODO] TODO
  # @return [TODO] TODO
  def apply_multiplier_to_output(obj, sync_objs, sys_id, mult)
    # Annual
    orig_value = obj.annual_output_by_system[sys_id]
    obj.annual_output_by_system[sys_id] = orig_value * mult
    sync_objs.each do |sync_obj|
      sync_obj.annual_output += (orig_value * mult - orig_value)
    end

    # Timeseries
    if not obj.timeseries_output_by_system.empty?
      orig_values = obj.timeseries_output_by_system[sys_id]
      obj.timeseries_output_by_system[sys_id] = obj.timeseries_output_by_system[sys_id].map { |x| x * mult }
      diffs = obj.timeseries_output_by_system[sys_id].zip(orig_values).map { |x, y| x - y }
      sync_objs.each do |sync_obj|
        sync_obj.timeseries_output = sync_obj.timeseries_output.zip(diffs).map { |x, y| x + y }
      end
    end

    # Hourly Electricity (for Cambium)
    if obj.is_a?(EndUse) && (not obj.hourly_output_by_system.empty?)
      obj.hourly_output_by_system[sys_id] = obj.hourly_output_by_system[sys_id].map { |x| x * mult }
    end
  end

  # TODO
  #
  # @return [TODO] TODO
  def create_all_object_outputs_by_key
    @object_variables_by_key = {}
    return if @model.nil?

    @model.getModelObjects.sort.each do |object|
      next if object.to_AdditionalProperties.is_initialized

      [EUT, HWT, LT, RT].each do |class_name|
        vars_by_key = get_object_outputs_by_key(@model, object, class_name)
        next if vars_by_key.size == 0

        sys_id = object.additionalProperties.getFeatureAsString('HPXML_ID')
        sys_id = sys_id.is_initialized ? sys_id.get : nil

        vars_by_key.each do |key, output_vars|
          output_vars.each do |output_var|
            if object.to_EnergyManagementSystemOutputVariable.is_initialized
              varkey = 'EMS'
            else
              varkey = object.name.to_s.upcase
            end
            hash_key = [class_name, key]
            @object_variables_by_key[hash_key] = [] if @object_variables_by_key[hash_key].nil?
            next if @object_variables_by_key[hash_key].include? [sys_id, varkey, output_var]

            @object_variables_by_key[hash_key] << [sys_id, varkey, output_var]
          end
        end
      end
    end
  end

  # TODO
  #
  # @param class_name [TODO] TODO
  # @param key [TODO] TODO
  # @return [TODO] TODO
  def get_object_outputs(class_name, key)
    hash_key = [class_name, key]
    vars = @object_variables_by_key[hash_key]
    vars = [] if vars.nil?
    return vars
  end

  # TODO
  class BaseOutput
    def initialize()
      @timeseries_output = []
    end
    attr_accessor(:name, :annual_output, :timeseries_output, :annual_units, :timeseries_units)
  end

  # TODO
  class TotalEnergy < BaseOutput
    def initialize
      super()
    end
    attr_accessor()
  end

  # TODO
  class Fuel < BaseOutput
    # @param meter [TODO] TODO
    def initialize(meter:)
      super()
      @meter = meter
      @timeseries_output_by_system = {}
    end
    attr_accessor(:meter, :timeseries_output_by_system)
  end

  # TODO
  class EndUse < BaseOutput
    # @param outputs [TODO] TODO
    # @param is_negative [TODO] TODO
    # @param is_storage [TODO] TODO
    def initialize(outputs:, is_negative: false, is_storage: false)
      super()
      @variables = outputs.select { |o| !o[2].include?(':') }
      @meters = outputs.select { |o| o[2].include?(':') }
      @is_negative = is_negative
      @is_storage = is_storage
      @timeseries_output_by_system = {}
      @annual_output_by_system = {}
      # These outputs used to apply Cambium hourly electricity factors
      @hourly_output = []
      @hourly_output_by_system = {}
    end
    attr_accessor(:variables, :meters, :is_negative, :is_storage, :annual_output_by_system, :timeseries_output_by_system,
                  :hourly_output, :hourly_output_by_system)
  end

  # TODO
  class Emission < BaseOutput
    def initialize()
      super()
      @timeseries_output_by_end_use = {}
      @timeseries_output_by_fuel = {}
      @annual_output_by_fuel = {}
      @annual_output_by_end_use = {}
      @net_annual_output = 0.0
      @net_timeseries_output = []
    end
    attr_accessor(:annual_output_by_fuel, :annual_output_by_end_use, :timeseries_output_by_fuel, :timeseries_output_by_end_use,
                  :net_annual_output, :net_timeseries_output)
  end

  # TODO
  class HotWater < BaseOutput
    # @param outputs [TODO] TODO
    def initialize(outputs:)
      super()
      @variables = outputs.select { |o| !o[2].include?(':') }
      @meters = outputs.select { |o| o[2].include?(':') }
      @timeseries_output_by_system = {}
      @annual_output_by_system = {}
    end
    attr_accessor(:variables, :meters, :annual_output_by_system, :timeseries_output_by_system)
  end

  # TODO
  class Resilience < BaseOutput
    # @param variables [TODO] TODO
    def initialize(variables:)
      super()
      @variables = variables
    end
    attr_accessor(:variables)
  end

  # TODO
  class PeakFuel < BaseOutput
    # @param report [TODO] TODO
    # @param meter [TODO] TODO
    def initialize(report:, meter:)
      super()
      @report = report
      @meter = meter
    end
    attr_accessor(:report, :meter)
  end

  # TODO
  class Load < BaseOutput
    # @param variables [TODO] TODO
    # @param ems_variable [TODO] TODO
    # @param is_negative [TODO] TODO
    def initialize(variables: [], ems_variable: nil, is_negative: false)
      super()
      @variables = variables
      @ems_variable = ems_variable
      @is_negative = is_negative
      @timeseries_output_by_system = {}
      @annual_output_by_system = {}
    end
    attr_accessor(:variables, :ems_variable, :is_negative, :annual_output_by_system, :timeseries_output_by_system)
  end

  # TODO
  class ComponentLoad < BaseOutput
    # @param ems_variable [TODO] TODO
    def initialize(ems_variable:)
      super()
      @ems_variable = ems_variable
    end
    attr_accessor(:ems_variable)
  end

  # TODO
  class UnmetHours < BaseOutput
    # @param ems_variable [TODO] TODO
    def initialize(ems_variable:)
      super()
      @ems_variable = ems_variable
    end
    attr_accessor(:ems_variable)
  end

  # TODO
  class PeakLoad < BaseOutput
    # @param ems_variable [TODO] TODO
    # @param report [TODO] TODO
    def initialize(ems_variable:, report:)
      super()
      @ems_variable = ems_variable
      @report = report
    end
    attr_accessor(:ems_variable, :report)
  end

  # TODO
  class ZoneTemp < BaseOutput
    def initialize
      super()
    end
    attr_accessor()
  end

  # TODO
  class ZoneCond < BaseOutput
    def initialize
      super()
    end
    attr_accessor
  end

  # TODO
  class Airflow < BaseOutput
    # @param ems_variable [TODO] TODO
    def initialize(ems_variable:)
      super()
      @ems_variable = ems_variable
    end
    attr_accessor(:ems_variable)
  end

  # TODO
  class Weather < BaseOutput
    # @param variable [TODO] TODO
    # @param variable_units [TODO] TODO
    # @param timeseries_units [TODO] TODO
    def initialize(variable:, variable_units:, timeseries_units:)
      super()
      @variable = variable
      @variable_units = variable_units
      @timeseries_units = timeseries_units
    end
    attr_accessor(:variable, :variable_units)
  end

  # TODO
  class OutputVariableOrMeter < BaseOutput
    def initialize
      super()
    end
    attr_accessor()
  end

  # TODO
  #
  # @param called_from_outputs_method [TODO] TODO
  # @param args [TODO] TODO
  # @return [TODO] TODO
  def setup_outputs(called_from_outputs_method, args = {})
    # TODO
    #
    # @param fuel_type [TODO] TODO
    # @return [TODO] TODO
    def get_timeseries_units_from_fuel_type(fuel_type)
      if fuel_type == FT::Elec
        return 'kWh'
      end

      return 'kBtu'
    end

    # End Uses

    create_all_object_outputs_by_key()

    @end_uses = {}
    @end_uses[[FT::Elec, EUT::Heating]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::Heating]))
    @end_uses[[FT::Elec, EUT::HeatingFanPump]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::HeatingFanPump]))
    @end_uses[[FT::Elec, EUT::HeatingHeatPumpBackup]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::HeatingHeatPumpBackup]))
    @end_uses[[FT::Elec, EUT::HeatingHeatPumpBackupFanPump]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::HeatingHeatPumpBackupFanPump]))
    @end_uses[[FT::Elec, EUT::Cooling]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::Cooling]))
    @end_uses[[FT::Elec, EUT::CoolingFanPump]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::CoolingFanPump]))
    @end_uses[[FT::Elec, EUT::HotWater]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::HotWater]))
    @end_uses[[FT::Elec, EUT::HotWaterRecircPump]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::HotWaterRecircPump]))
    @end_uses[[FT::Elec, EUT::HotWaterSolarThermalPump]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::HotWaterSolarThermalPump]))
    @end_uses[[FT::Elec, EUT::LightsInterior]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::LightsInterior]))
    @end_uses[[FT::Elec, EUT::LightsGarage]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::LightsGarage]))
    @end_uses[[FT::Elec, EUT::LightsExterior]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::LightsExterior]))
    @end_uses[[FT::Elec, EUT::MechVent]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::MechVent]))
    @end_uses[[FT::Elec, EUT::MechVentPreheat]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::MechVentPreheat]))
    @end_uses[[FT::Elec, EUT::MechVentPrecool]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::MechVentPrecool]))
    @end_uses[[FT::Elec, EUT::WholeHouseFan]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::WholeHouseFan]))
    @end_uses[[FT::Elec, EUT::Refrigerator]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::Refrigerator]))
    @end_uses[[FT::Elec, EUT::Freezer]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::Freezer]))
    @end_uses[[FT::Elec, EUT::Dehumidifier]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::Dehumidifier]))
    @end_uses[[FT::Elec, EUT::Dishwasher]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::Dishwasher]))
    @end_uses[[FT::Elec, EUT::ClothesWasher]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::ClothesWasher]))
    @end_uses[[FT::Elec, EUT::ClothesDryer]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::ClothesDryer]))
    @end_uses[[FT::Elec, EUT::RangeOven]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::RangeOven]))
    @end_uses[[FT::Elec, EUT::CeilingFan]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::CeilingFan]))
    @end_uses[[FT::Elec, EUT::Television]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::Television]))
    @end_uses[[FT::Elec, EUT::PlugLoads]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::PlugLoads]))
    @end_uses[[FT::Elec, EUT::WellPump]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::WellPump]))
    @end_uses[[FT::Elec, EUT::PoolHeater]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::PoolHeater]))
    @end_uses[[FT::Elec, EUT::PoolPump]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::PoolPump]))
    @end_uses[[FT::Elec, EUT::PermanentSpaHeater]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::PermanentSpaHeater]))
    @end_uses[[FT::Elec, EUT::PermanentSpaPump]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::PermanentSpaPump]))
    @end_uses[[FT::Elec, EUT::PV]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::PV]),
                                                is_negative: true)
    @end_uses[[FT::Elec, EUT::Generator]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::Generator]),
                                                       is_negative: true)
    @end_uses[[FT::Elec, EUT::Battery]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::Battery]),
                                                     is_storage: true)
    @end_uses[[FT::Elec, EUT::Vehicle]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::Vehicle]))
    @end_uses[[FT::Gas, EUT::Heating]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Gas, EUT::Heating]))
    @end_uses[[FT::Gas, EUT::HeatingHeatPumpBackup]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Gas, EUT::HeatingHeatPumpBackup]))
    @end_uses[[FT::Gas, EUT::HotWater]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Gas, EUT::HotWater]))
    @end_uses[[FT::Gas, EUT::ClothesDryer]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Gas, EUT::ClothesDryer]))
    @end_uses[[FT::Gas, EUT::RangeOven]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Gas, EUT::RangeOven]))
    @end_uses[[FT::Gas, EUT::MechVentPreheat]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Gas, EUT::MechVentPreheat]))
    @end_uses[[FT::Gas, EUT::PoolHeater]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Gas, EUT::PoolHeater]))
    @end_uses[[FT::Gas, EUT::PermanentSpaHeater]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Gas, EUT::PermanentSpaHeater]))
    @end_uses[[FT::Gas, EUT::Grill]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Gas, EUT::Grill]))
    @end_uses[[FT::Gas, EUT::Lighting]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Gas, EUT::Lighting]))
    @end_uses[[FT::Gas, EUT::Fireplace]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Gas, EUT::Fireplace]))
    @end_uses[[FT::Gas, EUT::Generator]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Gas, EUT::Generator]))
    @end_uses[[FT::Oil, EUT::Heating]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Oil, EUT::Heating]))
    @end_uses[[FT::Oil, EUT::HeatingHeatPumpBackup]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Oil, EUT::HeatingHeatPumpBackup]))
    @end_uses[[FT::Oil, EUT::HotWater]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Oil, EUT::HotWater]))
    @end_uses[[FT::Oil, EUT::ClothesDryer]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Oil, EUT::ClothesDryer]))
    @end_uses[[FT::Oil, EUT::RangeOven]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Oil, EUT::RangeOven]))
    @end_uses[[FT::Oil, EUT::MechVentPreheat]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Oil, EUT::MechVentPreheat]))
    @end_uses[[FT::Oil, EUT::Grill]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Oil, EUT::Grill]))
    @end_uses[[FT::Oil, EUT::Lighting]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Oil, EUT::Lighting]))
    @end_uses[[FT::Oil, EUT::Fireplace]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Oil, EUT::Fireplace]))
    @end_uses[[FT::Oil, EUT::Generator]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Oil, EUT::Generator]))
    @end_uses[[FT::Propane, EUT::Heating]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Propane, EUT::Heating]))
    @end_uses[[FT::Propane, EUT::HeatingHeatPumpBackup]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Propane, EUT::HeatingHeatPumpBackup]))
    @end_uses[[FT::Propane, EUT::HotWater]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Propane, EUT::HotWater]))
    @end_uses[[FT::Propane, EUT::ClothesDryer]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Propane, EUT::ClothesDryer]))
    @end_uses[[FT::Propane, EUT::RangeOven]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Propane, EUT::RangeOven]))
    @end_uses[[FT::Propane, EUT::MechVentPreheat]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Propane, EUT::MechVentPreheat]))
    @end_uses[[FT::Propane, EUT::Grill]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Propane, EUT::Grill]))
    @end_uses[[FT::Propane, EUT::Lighting]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Propane, EUT::Lighting]))
    @end_uses[[FT::Propane, EUT::Fireplace]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Propane, EUT::Fireplace]))
    @end_uses[[FT::Propane, EUT::Generator]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Propane, EUT::Generator]))
    @end_uses[[FT::WoodCord, EUT::Heating]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::WoodCord, EUT::Heating]))
    @end_uses[[FT::WoodCord, EUT::HeatingHeatPumpBackup]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::WoodCord, EUT::HeatingHeatPumpBackup]))
    @end_uses[[FT::WoodCord, EUT::HotWater]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::WoodCord, EUT::HotWater]))
    @end_uses[[FT::WoodCord, EUT::ClothesDryer]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::WoodCord, EUT::ClothesDryer]))
    @end_uses[[FT::WoodCord, EUT::RangeOven]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::WoodCord, EUT::RangeOven]))
    @end_uses[[FT::WoodCord, EUT::MechVentPreheat]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::WoodCord, EUT::MechVentPreheat]))
    @end_uses[[FT::WoodCord, EUT::Grill]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::WoodCord, EUT::Grill]))
    @end_uses[[FT::WoodCord, EUT::Lighting]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::WoodCord, EUT::Lighting]))
    @end_uses[[FT::WoodCord, EUT::Fireplace]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::WoodCord, EUT::Fireplace]))
    @end_uses[[FT::WoodCord, EUT::Generator]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::WoodCord, EUT::Generator]))
    @end_uses[[FT::WoodPellets, EUT::Heating]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::WoodPellets, EUT::Heating]))
    @end_uses[[FT::WoodPellets, EUT::HeatingHeatPumpBackup]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::WoodPellets, EUT::HeatingHeatPumpBackup]))
    @end_uses[[FT::WoodPellets, EUT::HotWater]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::WoodPellets, EUT::HotWater]))
    @end_uses[[FT::WoodPellets, EUT::ClothesDryer]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::WoodPellets, EUT::ClothesDryer]))
    @end_uses[[FT::WoodPellets, EUT::RangeOven]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::WoodPellets, EUT::RangeOven]))
    @end_uses[[FT::WoodPellets, EUT::MechVentPreheat]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::WoodPellets, EUT::MechVentPreheat]))
    @end_uses[[FT::WoodPellets, EUT::Grill]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::WoodPellets, EUT::Grill]))
    @end_uses[[FT::WoodPellets, EUT::Lighting]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::WoodPellets, EUT::Lighting]))
    @end_uses[[FT::WoodPellets, EUT::Fireplace]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::WoodPellets, EUT::Fireplace]))
    @end_uses[[FT::WoodPellets, EUT::Generator]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::WoodPellets, EUT::Generator]))
    @end_uses[[FT::Coal, EUT::Heating]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Coal, EUT::Heating]))
    @end_uses[[FT::Coal, EUT::HeatingHeatPumpBackup]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Coal, EUT::HeatingHeatPumpBackup]))
    @end_uses[[FT::Coal, EUT::HotWater]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Coal, EUT::HotWater]))
    @end_uses[[FT::Coal, EUT::ClothesDryer]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Coal, EUT::ClothesDryer]))
    @end_uses[[FT::Coal, EUT::RangeOven]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Coal, EUT::RangeOven]))
    @end_uses[[FT::Coal, EUT::MechVentPreheat]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Coal, EUT::MechVentPreheat]))
    @end_uses[[FT::Coal, EUT::Grill]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Coal, EUT::Grill]))
    @end_uses[[FT::Coal, EUT::Lighting]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Coal, EUT::Lighting]))
    @end_uses[[FT::Coal, EUT::Fireplace]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Coal, EUT::Fireplace]))
    @end_uses[[FT::Coal, EUT::Generator]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Coal, EUT::Generator]))
    if not called_from_outputs_method
      # Temporary end use to disaggregate 8760 GSHP shared loop pump energy into heating vs cooling.
      # This end use will not appear in output data/files.
      @end_uses[[FT::Elec, 'TempGSHPSharedPump']] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, 'TempGSHPSharedPump']))
    end
    @end_uses.each do |key, end_use|
      fuel_type, end_use_type = key
      end_use.name = "End Use: #{fuel_type}: #{end_use_type}"
      end_use.annual_units = 'MBtu'
      end_use.timeseries_units = get_timeseries_units_from_fuel_type(fuel_type)
    end

    # Fuels

    @fuels = {}
    @fuels[[FT::Elec, TE::Total]] = Fuel.new(meter: Outputs::MeterCustomElectricityTotal.upcase)
    @fuels[[FT::Elec, TE::Net]] = Fuel.new(meter: Outputs::MeterCustomElectricityNet.upcase)
    @fuels[[FT::Gas, TE::Total]] = Fuel.new(meter: "#{EPlus::FuelTypeNaturalGas}:Facility")
    @fuels[[FT::Oil, TE::Total]] = Fuel.new(meter: "#{EPlus::FuelTypeOil}:Facility")
    @fuels[[FT::Propane, TE::Total]] = Fuel.new(meter: "#{EPlus::FuelTypePropane}:Facility")
    @fuels[[FT::WoodCord, TE::Total]] = Fuel.new(meter: "#{EPlus::FuelTypeWoodCord}:Facility")
    @fuels[[FT::WoodPellets, TE::Total]] = Fuel.new(meter: "#{EPlus::FuelTypeWoodPellets}:Facility")
    @fuels[[FT::Coal, TE::Total]] = Fuel.new(meter: "#{EPlus::FuelTypeCoal}:Facility")
    @unique_fuel_types = @fuels.keys.map { |k| k[0] }.uniq

    @fuels.each do |(fuel_type, total_or_net), fuel|
      if total_or_net == TE::Net
        fuel.name = "Fuel Use: #{fuel_type}: Net"
      elsif total_or_net == TE::Total
        fuel.name = "Fuel Use: #{fuel_type}: Total"
      end
      fuel.annual_units = 'MBtu'
      fuel.timeseries_units = get_timeseries_units_from_fuel_type(fuel_type)
      if @end_uses.count { |key, end_use| key[0] == fuel_type && end_use.variables.size + end_use.meters.size > 0 } == 0
        fuel.meter = nil
      end
    end

    # Total Energy
    @totals = {}
    [TE::Total, TE::Net].each do |energy_type|
      @totals[energy_type] = TotalEnergy.new
      @totals[energy_type].name = "Energy Use: #{energy_type}"
      @totals[energy_type].annual_units = 'MBtu'
      @totals[energy_type].timeseries_units = get_timeseries_units_from_fuel_type(FT::Gas)
    end

    # Emissions
    @emissions = {}
    if not @model.nil?
      emissions_scenario_names = eval(@model.getBuilding.additionalProperties.getFeatureAsString('emissions_scenario_names').get)
      emissions_scenario_types = eval(@model.getBuilding.additionalProperties.getFeatureAsString('emissions_scenario_types').get)
      emissions_scenario_names.each_with_index do |scenario_name, i|
        scenario_type = emissions_scenario_types[i]
        @emissions[[scenario_type, scenario_name]] = Emission.new()
        @emissions[[scenario_type, scenario_name]].name = "Emissions: #{scenario_type}: #{scenario_name}"
        @emissions[[scenario_type, scenario_name]].annual_units = 'lb'
        @emissions[[scenario_type, scenario_name]].timeseries_units = 'lb'
      end
    end

    # Hot Water Uses
    @hot_water_uses = {}
    @hot_water_uses[HWT::ClothesWasher] = HotWater.new(outputs: get_object_outputs(HWT, HWT::ClothesWasher))
    @hot_water_uses[HWT::Dishwasher] = HotWater.new(outputs: get_object_outputs(HWT, HWT::Dishwasher))
    @hot_water_uses[HWT::Fixtures] = HotWater.new(outputs: get_object_outputs(HWT, HWT::Fixtures))
    @hot_water_uses[HWT::DistributionWaste] = HotWater.new(outputs: get_object_outputs(HWT, HWT::DistributionWaste))

    @hot_water_uses.each do |hot_water_type, hot_water|
      hot_water.name = "Hot Water: #{hot_water_type}"
      hot_water.annual_units = 'gal'
      hot_water.timeseries_units = 'gal'
    end

    # Resilience
    @resilience = {}
    @resilience[RT::Battery] = Resilience.new(variables: get_object_outputs(RT, RT::Battery))

    @resilience.each do |resilience_type, resilience|
      next unless resilience_type == RT::Battery

      resilience.name = "Resilience: #{resilience_type}"
      resilience.annual_units = 'hr'
      resilience.timeseries_units = 'hr'
    end

    # Peak Fuels
    @peak_fuels = {}
    @peak_fuels[[FT::Elec, TE::Total, PFT::Winter]] = PeakFuel.new(report: 'Peak Electricity Total', meter: Outputs::MeterCustomElectricityTotal)
    @peak_fuels[[FT::Elec, TE::Total, PFT::Summer]] = PeakFuel.new(report: 'Peak Electricity Total', meter: Outputs::MeterCustomElectricityTotal)
    @peak_fuels[[FT::Elec, TE::Total, PFT::Annual]] = PeakFuel.new(report: 'Peak Electricity Total', meter: Outputs::MeterCustomElectricityTotal)
    @peak_fuels[[FT::Elec, TE::Net, PFT::Winter]] = PeakFuel.new(report: 'Peak Electricity Net', meter: Outputs::MeterCustomElectricityNet)
    @peak_fuels[[FT::Elec, TE::Net, PFT::Summer]] = PeakFuel.new(report: 'Peak Electricity Net', meter: Outputs::MeterCustomElectricityNet)
    @peak_fuels[[FT::Elec, TE::Net, PFT::Annual]] = PeakFuel.new(report: 'Peak Electricity Net', meter: Outputs::MeterCustomElectricityNet)

    @peak_fuels.each do |key, peak_fuel|
      fuel_type, total_or_net, peak_fuel_type = key
      if total_or_net == TE::Net
        peak_fuel.name = "Peak #{fuel_type}: #{peak_fuel_type} Net"
      elsif total_or_net == TE::Total
        peak_fuel.name = "Peak #{fuel_type}: #{peak_fuel_type} Total"
      end
      peak_fuel.annual_units = 'W'
    end

    # Loads

    @loads = {}
    @loads[LT::Heating] = Load.new(ems_variable: 'loads_htg_tot')
    @loads[LT::HeatingHeatPumpBackup] = Load.new(variables: get_object_outputs(LT, LT::HeatingHeatPumpBackup))
    @loads[LT::Cooling] = Load.new(ems_variable: 'loads_clg_tot')
    @loads[LT::HotWaterDelivered] = Load.new(variables: get_object_outputs(LT, LT::HotWaterDelivered))
    @loads[LT::HotWaterTankLosses] = Load.new(variables: get_object_outputs(LT, LT::HotWaterTankLosses),
                                              is_negative: true)
    @loads[LT::HotWaterDesuperheater] = Load.new(variables: get_object_outputs(LT, LT::HotWaterDesuperheater))
    @loads[LT::HotWaterSolarThermal] = Load.new(variables: get_object_outputs(LT, LT::HotWaterSolarThermal),
                                                is_negative: true)

    @loads.each do |load_type, load|
      load.name = "Load: #{load_type}"
      load.annual_units = 'MBtu'
      load.timeseries_units = 'kBtu'
    end

    # Component Loads

    @component_loads = {}
    @component_loads[[LT::Heating, CLT::Roofs]] = ComponentLoad.new(ems_variable: 'loads_htg_roofs')
    @component_loads[[LT::Heating, CLT::Ceilings]] = ComponentLoad.new(ems_variable: 'loads_htg_ceilings')
    @component_loads[[LT::Heating, CLT::Walls]] = ComponentLoad.new(ems_variable: 'loads_htg_walls')
    @component_loads[[LT::Heating, CLT::RimJoists]] = ComponentLoad.new(ems_variable: 'loads_htg_rim_joists')
    @component_loads[[LT::Heating, CLT::FoundationWalls]] = ComponentLoad.new(ems_variable: 'loads_htg_foundation_walls')
    @component_loads[[LT::Heating, CLT::Doors]] = ComponentLoad.new(ems_variable: 'loads_htg_doors')
    @component_loads[[LT::Heating, CLT::WindowsConduction]] = ComponentLoad.new(ems_variable: 'loads_htg_windows_conduction')
    @component_loads[[LT::Heating, CLT::WindowsSolar]] = ComponentLoad.new(ems_variable: 'loads_htg_windows_solar')
    @component_loads[[LT::Heating, CLT::SkylightsConduction]] = ComponentLoad.new(ems_variable: 'loads_htg_skylights_conduction')
    @component_loads[[LT::Heating, CLT::SkylightsSolar]] = ComponentLoad.new(ems_variable: 'loads_htg_skylights_solar')
    @component_loads[[LT::Heating, CLT::Floors]] = ComponentLoad.new(ems_variable: 'loads_htg_floors')
    @component_loads[[LT::Heating, CLT::Slabs]] = ComponentLoad.new(ems_variable: 'loads_htg_slabs')
    @component_loads[[LT::Heating, CLT::InternalMass]] = ComponentLoad.new(ems_variable: 'loads_htg_internal_mass')
    @component_loads[[LT::Heating, CLT::Infiltration]] = ComponentLoad.new(ems_variable: 'loads_htg_infil')
    @component_loads[[LT::Heating, CLT::NaturalVentilation]] = ComponentLoad.new(ems_variable: 'loads_htg_natvent')
    @component_loads[[LT::Heating, CLT::MechanicalVentilation]] = ComponentLoad.new(ems_variable: 'loads_htg_mechvent')
    @component_loads[[LT::Heating, CLT::WholeHouseFan]] = ComponentLoad.new(ems_variable: 'loads_htg_whf')
    @component_loads[[LT::Heating, CLT::Ducts]] = ComponentLoad.new(ems_variable: 'loads_htg_ducts')
    @component_loads[[LT::Heating, CLT::InternalGains]] = ComponentLoad.new(ems_variable: 'loads_htg_intgains')
    @component_loads[[LT::Heating, CLT::Lighting]] = ComponentLoad.new(ems_variable: 'loads_htg_lighting')
    @component_loads[[LT::Cooling, CLT::Roofs]] = ComponentLoad.new(ems_variable: 'loads_clg_roofs')
    @component_loads[[LT::Cooling, CLT::Ceilings]] = ComponentLoad.new(ems_variable: 'loads_clg_ceilings')
    @component_loads[[LT::Cooling, CLT::Walls]] = ComponentLoad.new(ems_variable: 'loads_clg_walls')
    @component_loads[[LT::Cooling, CLT::RimJoists]] = ComponentLoad.new(ems_variable: 'loads_clg_rim_joists')
    @component_loads[[LT::Cooling, CLT::FoundationWalls]] = ComponentLoad.new(ems_variable: 'loads_clg_foundation_walls')
    @component_loads[[LT::Cooling, CLT::Doors]] = ComponentLoad.new(ems_variable: 'loads_clg_doors')
    @component_loads[[LT::Cooling, CLT::WindowsConduction]] = ComponentLoad.new(ems_variable: 'loads_clg_windows_conduction')
    @component_loads[[LT::Cooling, CLT::WindowsSolar]] = ComponentLoad.new(ems_variable: 'loads_clg_windows_solar')
    @component_loads[[LT::Cooling, CLT::SkylightsConduction]] = ComponentLoad.new(ems_variable: 'loads_clg_skylights_conduction')
    @component_loads[[LT::Cooling, CLT::SkylightsSolar]] = ComponentLoad.new(ems_variable: 'loads_clg_skylights_solar')
    @component_loads[[LT::Cooling, CLT::Floors]] = ComponentLoad.new(ems_variable: 'loads_clg_floors')
    @component_loads[[LT::Cooling, CLT::Slabs]] = ComponentLoad.new(ems_variable: 'loads_clg_slabs')
    @component_loads[[LT::Cooling, CLT::InternalMass]] = ComponentLoad.new(ems_variable: 'loads_clg_internal_mass')
    @component_loads[[LT::Cooling, CLT::Infiltration]] = ComponentLoad.new(ems_variable: 'loads_clg_infil')
    @component_loads[[LT::Cooling, CLT::NaturalVentilation]] = ComponentLoad.new(ems_variable: 'loads_clg_natvent')
    @component_loads[[LT::Cooling, CLT::MechanicalVentilation]] = ComponentLoad.new(ems_variable: 'loads_clg_mechvent')
    @component_loads[[LT::Cooling, CLT::WholeHouseFan]] = ComponentLoad.new(ems_variable: 'loads_clg_whf')
    @component_loads[[LT::Cooling, CLT::Ducts]] = ComponentLoad.new(ems_variable: 'loads_clg_ducts')
    @component_loads[[LT::Cooling, CLT::InternalGains]] = ComponentLoad.new(ems_variable: 'loads_clg_intgains')
    @component_loads[[LT::Cooling, CLT::Lighting]] = ComponentLoad.new(ems_variable: 'loads_clg_lighting')

    @component_loads.each do |key, comp_load|
      load_type, comp_load_type = key
      comp_load.name = "Component Load: #{load_type.gsub(': Delivered', '')}: #{comp_load_type}"
      comp_load.annual_units = 'MBtu'
      comp_load.timeseries_units = 'kBtu'
    end

    # Unmet Hours
    @unmet_hours = {}
    @unmet_hours[UHT::Heating] = UnmetHours.new(ems_variable: 'htg_unmet_hours')
    @unmet_hours[UHT::Cooling] = UnmetHours.new(ems_variable: 'clg_unmet_hours')
    @unmet_hours[UHT::Driving] = UnmetHours.new(ems_variable: 'unmet_driving_hours')

    @unmet_hours.each do |load_type, unmet_hour|
      unmet_hour.name = "Unmet Hours: #{load_type}"
      unmet_hour.annual_units = 'hr'
      unmet_hour.timeseries_units = 'hr'
    end

    # Peak Loads
    @peak_loads = {}
    @peak_loads[PLT::Heating] = PeakLoad.new(ems_variable: 'loads_htg_tot', report: 'Peak Heating Load')
    @peak_loads[PLT::Cooling] = PeakLoad.new(ems_variable: 'loads_clg_tot', report: 'Peak Cooling Load')

    @peak_loads.each do |load_type, peak_load|
      peak_load.name = "Peak Load: #{load_type}"
      peak_load.annual_units = 'kBtu/hr'
    end

    # Zone Temperatures
    @zone_temps = {}

    # Zone Conditions
    @zone_conds = {}

    # Airflows
    @airflows = {}
    @airflows[AFT::Infiltration] = Airflow.new(ems_variable: 'total_infil_flow_rate')
    @airflows[AFT::MechanicalVentilation] = Airflow.new(ems_variable: 'total_mechvent_flow_rate')
    @airflows[AFT::NaturalVentilation] = Airflow.new(ems_variable: 'total_natvent_flow_rate')
    @airflows[AFT::WholeHouseFan] = Airflow.new(ems_variable: 'total_whf_flow_rate')

    @airflows.each do |airflow_type, airflow|
      airflow.name = "Airflow: #{airflow_type}"
      airflow.timeseries_units = 'cfm'
    end

    # Weather
    @weather = {}
    @weather[WT::DrybulbTemp] = Weather.new(variable: 'Site Outdoor Air Drybulb Temperature', variable_units: 'C', timeseries_units: 'F')
    @weather[WT::WetbulbTemp] = Weather.new(variable: 'Site Outdoor Air Wetbulb Temperature', variable_units: 'C', timeseries_units: 'F')
    @weather[WT::RelativeHumidity] = Weather.new(variable: 'Site Outdoor Air Relative Humidity', variable_units: '%', timeseries_units: '%')
    @weather[WT::WindSpeed] = Weather.new(variable: 'Site Wind Speed', variable_units: 'm/s', timeseries_units: 'mph')
    @weather[WT::DiffuseSolar] = Weather.new(variable: 'Site Diffuse Solar Radiation Rate per Area', variable_units: 'W/m^2', timeseries_units: 'Btu/(hr*ft^2)')
    @weather[WT::DirectSolar] = Weather.new(variable: 'Site Direct Solar Radiation Rate per Area', variable_units: 'W/m^2', timeseries_units: 'Btu/(hr*ft^2)')

    @weather.each do |weather_type, weather_data|
      weather_data.name = "Weather: #{weather_type}"
    end

    # Output Variables
    @output_variables_requests = args[:user_output_variables].to_s.split(',').map(&:strip)

    # Output Meters
    @output_meters_requests = args[:user_output_meters].to_s.split(',').map(&:strip)
  end

  # TODO
  #
  # @param emissions [TODO] TODO
  # @param args [Hash] Map of :argument_name => value
  # @return [TODO] TODO
  def setup_timeseries_includes(emissions, args)
    # To calculate timeseries emissions or timeseries fuel consumption, we also need to select timeseries
    # end use consumption because EnergyPlus results may be post-processed due to HVAC DSE.
    # TODO: This could be removed if we could account for DSE inside EnergyPlus.
    args = args.dup # We don't want to modify the original arguments
    args[:include_hourly_electric_end_use_consumptions] = false
    if not emissions.empty?
      args[:include_hourly_electric_end_use_consumptions] = true # Need hourly electricity values for Cambium
      if args[:include_timeseries_emissions] || args[:include_timeseries_emission_end_uses] || args[:include_timeseries_emission_fuels]
        args[:include_timeseries_fuel_consumptions] = true
      end
    end
    if args[:include_timeseries_total_consumptions] || args[:include_timeseries_resilience]
      args[:include_timeseries_fuel_consumptions] = true
    end
    if args[:include_timeseries_fuel_consumptions]
      args[:include_timeseries_end_use_consumptions] = true
    end
    if args[:include_timeseries_system_use_consumptions]
      args[:include_timeseries_end_use_consumptions] = true
    end
    return args
  end

  # TODO
  #
  # @return [TODO] TODO
  def get_hpxml_system_ids
    # Returns a list of HPXML IDs corresponds to HVAC or water heating systems
    return [] if @hpxml_bldgs.empty?

    system_ids = []
    @hpxml_bldgs.each do |hpxml_bldg|
      (hpxml_bldg.hvac_systems + hpxml_bldg.water_heating_systems + hpxml_bldg.ventilation_fans).each do |system|
        system_ids << system.id
      end
    end
    return system_ids
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param object [TODO] TODO
  # @param class_name [TODO] TODO
  # @return [TODO] TODO
  def get_object_outputs_by_key(model, object, class_name)
    # For a given object, returns the Output:Variables or Output:Meters to be requested,
    # and associates them with the appropriate keys (e.g., [FT::Elec, EUT::Heating]).

    object_type = object.additionalProperties.getFeatureAsString('ObjectType')
    object_type = object_type.get if object_type.is_initialized

    to_ft = { EPlus::FuelTypeElectricity => FT::Elec,
              EPlus::FuelTypeNaturalGas => FT::Gas,
              EPlus::FuelTypeOil => FT::Oil,
              EPlus::FuelTypePropane => FT::Propane,
              EPlus::FuelTypeWoodCord => FT::WoodCord,
              EPlus::FuelTypeWoodPellets => FT::WoodPellets,
              EPlus::FuelTypeCoal => FT::Coal }

    if class_name == EUT

      # End uses

      if object.to_CoilHeatingDXSingleSpeed.is_initialized || object.to_CoilHeatingDXMultiSpeed.is_initialized
        vars = { [FT::Elec, EUT::Heating] => ["Heating Coil #{EPlus::FuelTypeElectricity} Energy", "Heating Coil Defrost #{EPlus::FuelTypeElectricity} Energy"] }
        if object.additionalProperties.getFeatureAsDouble('FractionHeatLoadServed').is_initialized && object.additionalProperties.getFeatureAsDouble('FractionHeatLoadServed').get <= 0
          # HP only provides cooling, allocate crankcase to cooling end use
          vars[[FT::Elec, EUT::Cooling]] = ["Heating Coil Crankcase Heater #{EPlus::FuelTypeElectricity} Energy"]
        else
          # Allocate crankcase to heating end use
          vars[[FT::Elec, EUT::Heating]] << "Heating Coil Crankcase Heater #{EPlus::FuelTypeElectricity} Energy"
        end
        return vars

      elsif object.to_CoilHeatingElectric.is_initialized || object.to_CoilHeatingElectricMultiStage.is_initialized
        if object.additionalProperties.getFeatureAsBoolean('IsHeatPumpBackup').is_initialized && object.additionalProperties.getFeatureAsBoolean('IsHeatPumpBackup').get
          return { [FT::Elec, EUT::HeatingHeatPumpBackup] => ["Heating Coil #{EPlus::FuelTypeElectricity} Energy"] }
        else
          return { [FT::Elec, EUT::Heating] => ["Heating Coil #{EPlus::FuelTypeElectricity} Energy"] }
        end

      elsif object.to_CoilHeatingGas.is_initialized
        fuel = object.to_CoilHeatingGas.get.fuelType
        if object.additionalProperties.getFeatureAsBoolean('IsHeatPumpBackup').is_initialized && object.additionalProperties.getFeatureAsBoolean('IsHeatPumpBackup').get
          return { [to_ft[fuel], EUT::HeatingHeatPumpBackup] => ["Heating Coil #{fuel} Energy", "Heating Coil Ancillary #{fuel} Energy"] }
        else
          return { [to_ft[fuel], EUT::Heating] => ["Heating Coil #{fuel} Energy", "Heating Coil Ancillary #{fuel} Energy"] }
        end

      elsif object.to_CoilHeatingWaterToAirHeatPumpEquationFit.is_initialized || object.to_CoilHeatingWaterToAirHeatPumpVariableSpeedEquationFit.is_initialized
        return { [FT::Elec, EUT::Heating] => ["Heating Coil #{EPlus::FuelTypeElectricity} Energy"] }

      elsif object.to_ZoneHVACBaseboardConvectiveElectric.is_initialized
        if object.additionalProperties.getFeatureAsBoolean('IsHeatPumpBackup').is_initialized && object.additionalProperties.getFeatureAsBoolean('IsHeatPumpBackup').get
          return { [FT::Elec, EUT::HeatingHeatPumpBackup] => ["Baseboard #{EPlus::FuelTypeElectricity} Energy"] }
        else
          return { [FT::Elec, EUT::Heating] => ["Baseboard #{EPlus::FuelTypeElectricity} Energy"] }
        end

      elsif object.to_BoilerHotWater.is_initialized
        is_combi_boiler = false
        if object.additionalProperties.getFeatureAsBoolean('IsCombiBoiler').is_initialized
          is_combi_boiler = object.additionalProperties.getFeatureAsBoolean('IsCombiBoiler').get
        end
        if not is_combi_boiler # Exclude combi boiler, whose heating & dhw energy is handled separately via EMS
          fuel = object.to_BoilerHotWater.get.fuelType
          if object.additionalProperties.getFeatureAsBoolean('IsHeatPumpBackup').is_initialized && object.additionalProperties.getFeatureAsBoolean('IsHeatPumpBackup').get
            return { [to_ft[fuel], EUT::HeatingHeatPumpBackup] => ["Boiler #{fuel} Energy", "Boiler Ancillary #{fuel} Energy"] }
          else
            return { [to_ft[fuel], EUT::Heating] => ["Boiler #{fuel} Energy", "Boiler Ancillary #{fuel} Energy"] }
          end
        else
          fuel = object.to_BoilerHotWater.get.fuelType
          return { [to_ft[fuel], EUT::HotWater] => ["Boiler #{fuel} Energy", "Boiler Ancillary #{fuel} Energy"] }
        end

      elsif object.to_CoilCoolingDXSingleSpeed.is_initialized || object.to_CoilCoolingDXMultiSpeed.is_initialized
        vars = { [FT::Elec, EUT::Cooling] => ["Cooling Coil #{EPlus::FuelTypeElectricity} Energy"] }
        parent = model.getAirLoopHVACUnitarySystems.select { |u| u.coolingCoil.is_initialized && u.coolingCoil.get.handle.to_s == object.handle.to_s }
        if (not parent.empty?) && parent[0].heatingCoil.is_initialized
          htg_coil = parent[0].heatingCoil.get
        end
        if parent.empty?
          parent = model.getZoneHVACPackagedTerminalAirConditioners.select { |u| u.coolingCoil.handle.to_s == object.handle.to_s }
          if not parent.empty?
            htg_coil = parent[0].heatingCoil
          end
        end
        if parent.empty?
          fail 'Could not find parent object.'
        end

        if htg_coil.nil? || (not (htg_coil.to_CoilHeatingDXSingleSpeed.is_initialized || htg_coil.to_CoilHeatingDXMultiSpeed.is_initialized))
          # Crankcase variable only available if no DX heating coil on parent
          vars[[FT::Elec, EUT::Cooling]] << "Cooling Coil Crankcase Heater #{EPlus::FuelTypeElectricity} Energy"
        end
        return vars

      elsif object.to_CoilCoolingWaterToAirHeatPumpEquationFit.is_initialized || object.to_CoilCoolingWaterToAirHeatPumpVariableSpeedEquationFit.is_initialized
        return { [FT::Elec, EUT::Cooling] => ["Cooling Coil #{EPlus::FuelTypeElectricity} Energy"] }

      elsif object.to_EvaporativeCoolerDirectResearchSpecial.is_initialized
        return { [FT::Elec, EUT::Cooling] => ["Evaporative Cooler #{EPlus::FuelTypeElectricity} Energy"] }

      elsif object.to_CoilWaterHeatingAirToWaterHeatPumpWrapped.is_initialized
        return { [FT::Elec, EUT::HotWater] => ["Cooling Coil Water Heating #{EPlus::FuelTypeElectricity} Energy"] }

      elsif object.to_FanSystemModel.is_initialized
        if object_type == Constants::ObjectTypeWaterHeater
          return { [FT::Elec, EUT::HotWater] => ["Fan #{EPlus::FuelTypeElectricity} Energy"] }
        end

      elsif object.to_PumpConstantSpeed.is_initialized
        if object_type == Constants::ObjectTypeSolarHotWater
          return { [FT::Elec, EUT::HotWaterSolarThermalPump] => ["Pump #{EPlus::FuelTypeElectricity} Energy"] }
        end

      elsif object.to_WaterHeaterMixed.is_initialized
        fuel = object.to_WaterHeaterMixed.get.heaterFuelType
        return { [to_ft[fuel], EUT::HotWater] => ["Water Heater #{fuel} Energy", "Water Heater Off Cycle Parasitic #{EPlus::FuelTypeElectricity} Energy", "Water Heater On Cycle Parasitic #{EPlus::FuelTypeElectricity} Energy"] }

      elsif object.to_WaterHeaterStratified.is_initialized
        fuel = object.to_WaterHeaterStratified.get.heaterFuelType
        return { [to_ft[fuel], EUT::HotWater] => ["Water Heater #{fuel} Energy", "Water Heater Off Cycle Parasitic #{EPlus::FuelTypeElectricity} Energy", "Water Heater On Cycle Parasitic #{EPlus::FuelTypeElectricity} Energy"] }

      elsif object.to_ExteriorLights.is_initialized
        subcategory = object.to_ExteriorLights.get.endUseSubcategory
        return { [FT::Elec, EUT::LightsExterior] => ["#{subcategory}:ExteriorLights:#{EPlus::FuelTypeElectricity}"] }

      elsif object.to_Lights.is_initialized
        subcategory = object.to_Lights.get.endUseSubcategory
        end_use = { Constants::ObjectTypeLightingInterior => EUT::LightsInterior,
                    Constants::ObjectTypeLightingGarage => EUT::LightsGarage }[subcategory]
        return { [FT::Elec, end_use] => ["#{subcategory}:InteriorLights:#{EPlus::FuelTypeElectricity}"] }

      elsif object.to_ElectricLoadCenterInverterPVWatts.is_initialized
        return { [FT::Elec, EUT::PV] => ['Inverter Conversion Loss Decrement Energy'] }

      elsif object.to_GeneratorPVWatts.is_initialized
        return { [FT::Elec, EUT::PV] => ["Generator Produced DC #{EPlus::FuelTypeElectricity} Energy"] }

      elsif object.to_GeneratorMicroTurbine.is_initialized
        fuel = object.to_GeneratorMicroTurbine.get.fuelType
        return { [FT::Elec, EUT::Generator] => ["Generator Produced AC #{EPlus::FuelTypeElectricity} Energy"],
                 [to_ft[fuel], EUT::Generator] => ["Generator #{fuel} HHV Basis Energy"] }

      elsif object.to_ElectricLoadCenterStorageLiIonNMCBattery.is_initialized
        if object.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants::ObjectTypeVehicle
          return { [FT::Elec, EUT::Vehicle] => ['Electric Storage Charge Energy'] }
        elsif object.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants::ObjectTypeBattery
          return { [FT::Elec, EUT::Battery] => ['Electric Storage Production Decrement Energy', 'Electric Storage Discharge Energy'] }
        else
          fail "Unexpected elcs: #{object.name}"
        end

      elsif object.to_ElectricEquipment.is_initialized
        object = object.to_ElectricEquipment.get
        subcategory = object.endUseSubcategory
        end_use = nil
        { Constants::ObjectTypeHotWaterRecircPump => EUT::HotWaterRecircPump,
          Constants::ObjectTypeGSHPSharedPump => 'TempGSHPSharedPump',
          Constants::ObjectTypeClothesWasher => EUT::ClothesWasher,
          Constants::ObjectTypeClothesDryer => EUT::ClothesDryer,
          Constants::ObjectTypeDishwasher => EUT::Dishwasher,
          Constants::ObjectTypeRefrigerator => EUT::Refrigerator,
          Constants::ObjectTypeFreezer => EUT::Freezer,
          Constants::ObjectTypeCookingRange => EUT::RangeOven,
          Constants::ObjectTypeCeilingFan => EUT::CeilingFan,
          Constants::ObjectTypeWholeHouseFan => EUT::WholeHouseFan,
          Constants::ObjectTypeMechanicalVentilation => EUT::MechVent,
          Constants::ObjectTypeMiscPlugLoads => EUT::PlugLoads,
          Constants::ObjectTypeMiscTelevision => EUT::Television,
          Constants::ObjectTypeMiscPoolHeater => EUT::PoolHeater,
          Constants::ObjectTypeMiscPoolPump => EUT::PoolPump,
          Constants::ObjectTypeMiscPermanentSpaHeater => EUT::PermanentSpaHeater,
          Constants::ObjectTypeMiscPermanentSpaPump => EUT::PermanentSpaPump,
          Constants::ObjectTypeMiscElectricVehicleCharging => EUT::Vehicle,
          Constants::ObjectTypeMiscWellPump => EUT::WellPump }.each do |obj_name, eut|
          next unless subcategory.start_with? obj_name
          fail 'Unexpected error: multiple matches.' unless end_use.nil?

          end_use = eut
        end

        if not end_use.nil?
          # Use Output:Meter instead of Output:Variable because they incorporate thermal zone multipliers
          if object.space.is_initialized
            zone_name = object.space.get.thermalZone.get.name.to_s.upcase
            return { [FT::Elec, end_use] => ["#{subcategory}:InteriorEquipment:#{EPlus::FuelTypeElectricity}:Zone:#{zone_name}"] }
          else
            return { [FT::Elec, end_use] => ["#{subcategory}:InteriorEquipment:#{EPlus::FuelTypeElectricity}"] }
          end
        end

      elsif object.to_OtherEquipment.is_initialized
        object = object.to_OtherEquipment.get
        subcategory = object.endUseSubcategory
        fuel = object.fuelType
        end_use = nil
        { Constants::ObjectTypeClothesDryer => EUT::ClothesDryer,
          Constants::ObjectTypeCookingRange => EUT::RangeOven,
          Constants::ObjectTypeMiscGrill => EUT::Grill,
          Constants::ObjectTypeMiscLighting => EUT::Lighting,
          Constants::ObjectTypeMiscFireplace => EUT::Fireplace,
          Constants::ObjectTypeMiscPoolHeater => EUT::PoolHeater,
          Constants::ObjectTypeMiscPermanentSpaHeater => EUT::PermanentSpaHeater,
          Constants::ObjectTypeMechanicalVentilationPreheating => EUT::MechVentPreheat,
          Constants::ObjectTypeMechanicalVentilationPrecooling => EUT::MechVentPrecool,
          Constants::ObjectTypeHPDefrostSupplHeat => EUT::HeatingHeatPumpBackup,
          Constants::ObjectTypePanHeater => EUT::Heating,
          Constants::ObjectTypeWaterHeaterAdjustment => EUT::HotWater,
          Constants::ObjectTypeBatteryLossesAdjustment => EUT::Battery }.each do |obj_name, eut|
          next unless subcategory.start_with? obj_name
          fail 'Unexpected error: multiple matches.' unless end_use.nil?

          end_use = eut
        end

        if not end_use.nil?
          # Use Output:Meter instead of Output:Variable because they incorporate thermal zone multipliers
          if object.space.is_initialized
            zone_name = object.space.get.thermalZone.get.name.to_s.upcase
            return { [to_ft[fuel], end_use] => ["#{subcategory}:InteriorEquipment:#{fuel}:Zone:#{zone_name}"] }
          else
            return { [to_ft[fuel], end_use] => ["#{subcategory}:InteriorEquipment:#{fuel}"] }
          end
        end

      elsif object.to_ZoneHVACDehumidifierDX.is_initialized
        return { [FT::Elec, EUT::Dehumidifier] => ["Zone Dehumidifier #{EPlus::FuelTypeElectricity} Energy"] }

      elsif object.to_EnergyManagementSystemOutputVariable.is_initialized
        if object_type == Constants::ObjectTypeFanPumpDisaggregatePrimaryHeat
          return { [FT::Elec, EUT::HeatingFanPump] => [object.name.to_s] }
        elsif object_type == Constants::ObjectTypeFanPumpDisaggregateBackupHeat
          return { [FT::Elec, EUT::HeatingHeatPumpBackupFanPump] => [object.name.to_s] }
        elsif object_type == Constants::ObjectTypeFanPumpDisaggregateCool
          return { [FT::Elec, EUT::CoolingFanPump] => [object.name.to_s] }
        else
          return { ems: [object.name.to_s] }
        end

      end

    elsif class_name == HWT

      # Hot Water Use

      if object.to_WaterUseEquipment.is_initialized
        hot_water_use = { Constants::ObjectTypeFixtures => HWT::Fixtures,
                          Constants::ObjectTypeDistributionWaste => HWT::DistributionWaste,
                          Constants::ObjectTypeClothesWasher => HWT::ClothesWasher,
                          Constants::ObjectTypeDishwasher => HWT::Dishwasher }[object.to_WaterUseEquipment.get.waterUseEquipmentDefinition.endUseSubcategory]
        return { hot_water_use => ['Water Use Equipment Hot Water Volume'] }

      end

    elsif class_name == LT

      # Load

      if object.to_WaterHeaterMixed.is_initialized || object.to_WaterHeaterStratified.is_initialized
        if object.to_WaterHeaterMixed.is_initialized
          capacity = object.to_WaterHeaterMixed.get.heaterMaximumCapacity.get
        else
          capacity = object.to_WaterHeaterStratified.get.heater1Capacity.get
        end
        is_combi_boiler = false
        if object.additionalProperties.getFeatureAsBoolean('IsCombiBoiler').is_initialized
          is_combi_boiler = object.additionalProperties.getFeatureAsBoolean('IsCombiBoiler').get
        end
        if capacity == 0 && object_type == Constants::ObjectTypeSolarHotWater
          return { LT::HotWaterSolarThermal => ['Water Heater Use Side Heat Transfer Energy'] }
        elsif capacity > 0 || is_combi_boiler # Active water heater only (e.g., exclude desuperheater and solar thermal storage tanks)
          return { LT::HotWaterTankLosses => ['Water Heater Heat Loss Energy'] }
        end

      elsif object.to_WaterUseConnections.is_initialized
        return { LT::HotWaterDelivered => ['Water Use Connections Plant Hot Water Energy'] }

      elsif object.to_CoilWaterHeatingDesuperheater.is_initialized
        return { LT::HotWaterDesuperheater => ['Water Heater Heating Energy'] }

      elsif object.to_CoilHeatingGas.is_initialized || object.to_CoilHeatingElectric.is_initialized
        if object.additionalProperties.getFeatureAsBoolean('IsHeatPumpBackup').is_initialized && object.additionalProperties.getFeatureAsBoolean('IsHeatPumpBackup').get
          return { LT::HeatingHeatPumpBackup => ['Heating Coil Heating Energy'] }
        end

      elsif object.to_ZoneHVACBaseboardConvectiveElectric.is_initialized || object.to_ZoneHVACBaseboardConvectiveWater.is_initialized
        if object.additionalProperties.getFeatureAsBoolean('IsHeatPumpBackup').is_initialized && object.additionalProperties.getFeatureAsBoolean('IsHeatPumpBackup').get
          return { LT::HeatingHeatPumpBackup => ['Baseboard Total Heating Energy'] }
        end

      elsif object.to_EnergyManagementSystemOutputVariable.is_initialized
        if object_type == Constants::ObjectTypeFanPumpDisaggregateBackupHeat
          # Fan/pump energy is contributing to the load
          return { LT::HeatingHeatPumpBackup => [object.name.to_s] }
        end

      end

    elsif class_name == RT

      # Resilience

      if object.to_ElectricLoadCenterStorageLiIonNMCBattery.is_initialized
        if object.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants::ObjectTypeBattery
          return { RT::Battery => ['Electric Storage Charge Fraction'] }
        end

      elsif object.to_OtherEquipment.is_initialized
        if object_type == Constants::ObjectTypeBatteryLossesAdjustment
          return { RT::Battery => ["Other Equipment #{EPlus::FuelTypeElectricity} Energy"] }
        end

      end
    end

    return {}
  end
end

# register the measure to be used by the application
ReportSimulationOutput.new.registerWithApplication
