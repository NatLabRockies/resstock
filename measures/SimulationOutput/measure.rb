# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require_relative 'resources/constants'
require_relative '../../resources/buildstock'
require_relative '../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/meta_measure'

# start the measure
class SimulationOutput < OpenStudio::Measure::ReportingMeasure
  # human readable name
  def name
    return 'Simulation Output'
  end

  # human readable description
  def description
    return 'TODO'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'TODO'
  end

  # define the arguments that the user will input
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    # Allow same arguments as ReportSimulationOutput and ReportUtilityBills measures

    hpxml_measures_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../resources/hpxml-measures'))

    full_measure_path = File.join(hpxml_measures_dir, 'ReportSimulationOutput', 'measure.rb')
    measure_arguments = get_measure_instance(full_measure_path).arguments(model)
    measure_arguments.each do |arg|
      arg.setRequired(false)
      args << arg
    end

    full_measure_path = File.join(hpxml_measures_dir, 'ReportUtilityBills', 'measure.rb')
    measure_arguments = get_measure_instance(full_measure_path).arguments(model)
    measure_arguments.each do |arg|
      arg.setRequired(false)
      args << arg
    end

    return args
  end

  def modelOutputRequests(model, runner, user_arguments)
    return false if runner.halted

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Apply reporting measure output requests
    hpxml_measures_dir = File.join(File.dirname(__FILE__), '../../resources/hpxml-measures')
    args = runner.getArgumentValues(arguments(model), user_arguments)
    measures = setup_measures(args)
    apply_model_output_requests(hpxml_measures_dir, measures, runner, model)
  end

  # Set arguments for the ReportSimulationOutput and ReportUtilityBills measures
  def setup_measures(args)
    measures = {}

    measures['ReportSimulationOutput'] = [{ 'output_format' => args[:output_format],
                                            'include_annual_total_consumptions' => args[:include_annual_total_consumptions],
                                            'include_annual_fuel_consumptions' => args[:include_annual_fuel_consumptions],
                                            'include_annual_end_use_consumptions' => args[:include_annual_end_use_consumptions],
                                            'include_annual_system_use_consumptions' => args[:include_annual_system_use_consumptions],
                                            'include_annual_emissions' => args[:include_annual_emissions],
                                            'include_annual_emission_fuels' => args[:include_annual_emission_fuels],
                                            'include_annual_emission_end_uses' => args[:include_annual_emission_end_uses],
                                            'include_annual_total_loads' => args[:include_annual_total_loads],
                                            'include_annual_unmet_hours' => args[:include_annual_unmet_hours],
                                            'include_annual_peak_fuels' => args[:include_annual_peak_fuels],
                                            'include_annual_peak_loads' => args[:include_annual_peak_loads],
                                            'include_annual_component_loads' => args[:include_annual_component_loads],
                                            'include_annual_hot_water_uses' => args[:include_annual_hot_water_uses],
                                            'include_annual_hvac_summary' => args[:include_annual_hvac_summary],
                                            'include_annual_resilience' => args[:include_annual_resilience],
                                            'timeseries_frequency' => args[:timeseries_frequency],
                                            'include_timeseries_total_consumptions' => args[:include_timeseries_total_consumptions],
                                            'include_timeseries_fuel_consumptions' => args[:include_timeseries_fuel_consumptions],
                                            'include_timeseries_end_use_consumptions' => args[:include_timeseries_end_use_consumptions],
                                            'include_timeseries_system_use_consumptions' => args[:include_timeseries_system_use_consumptions],
                                            'include_timeseries_emissions' => args[:include_timeseries_emissions],
                                            'include_timeseries_emission_fuels' => args[:include_timeseries_emission_fuels],
                                            'include_timeseries_emission_end_uses' => args[:include_timeseries_emission_end_uses],
                                            'include_timeseries_hot_water_uses' => args[:include_timeseries_hot_water_uses],
                                            'include_timeseries_total_loads' => args[:include_timeseries_total_loads],
                                            'include_timeseries_component_loads' => args[:include_timeseries_component_loads],
                                            'include_timeseries_unmet_hours' => args[:include_timeseries_unmet_hours],
                                            'include_timeseries_zone_temperatures' => args[:include_timeseries_zone_temperatures],
                                            'include_timeseries_zone_conditions' => args[:include_timeseries_zone_conditions],
                                            'include_timeseries_airflows' => args[:include_timeseries_airflows],
                                            'include_timeseries_weather' => args[:include_timeseries_weather],
                                            'include_timeseries_resilience' => args[:include_timeseries_resilience],
                                            'timeseries_timestamp_convention' => args[:timeseries_timestamp_convention],
                                            'timeseries_num_decimal_places' => args[:timeseries_num_decimal_places],
                                            'add_timeseries_dst_column' => args[:add_timeseries_dst_column],
                                            'add_timeseries_utc_column' => args[:add_timeseries_utc_column],
                                            'user_output_variables' => args[:user_output_variables],
                                            'user_output_meters' => args[:user_output_meters] }]

    measures['ReportUtilityBills'] = [{ 'output_format' => args[:output_format],
                                        'include_annual_bills' => args[:include_annual_bills],
                                        'include_monthly_bills' => args[:include_monthly_bills],
                                        'register_annual_bills' => args[:register_annual_bills],
                                        'register_monthly_bills' => args[:register_monthly_bills] }]

    return measures
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find OpenStudio model.')
      return false
    end
    model = model.get

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Assign the user inputs to variables
    args = runner.getArgumentValues(arguments(model), user_arguments)

    hpxml_defaults_path = model.getBuilding.additionalProperties.getFeatureAsString('hpxml_defaults_path').get
    building_id = model.getBuilding.additionalProperties.getFeatureAsString('building_id').get
    hpxml = HPXML.new(hpxml_path: hpxml_defaults_path, building_id: building_id)

    # Get file/dir paths
    resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../resources'))
    hpxml_measures_dir = File.join(File.dirname(__FILE__), '../../resources/hpxml-measures')

    # Check file/dir paths exist
    check_dir_exists(resources_dir, runner)
    [hpxml_measures_dir].each do |dir|
      check_dir_exists(dir, runner)
    end

    measures = setup_measures(args)
    measures_hash = { 'ReportSimulationOutput' => measures['ReportSimulationOutput'],
                      'ReportUtilityBills' => measures['ReportUtilityBills'] }

    new_runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    new_runner.setLastEpwFilePath(File.join(File.dirname(__FILE__), 'in.epw'))
    if not apply_measures(hpxml_measures_dir, measures_hash, new_runner, model, true, 'OpenStudio::Measure::ReportingMeasure', nil)
      register_logs(runner, new_runner)
      return false
    end

    num_units = hpxml.buildings.collect { |hpxml_bldg| hpxml_bldg.building_construction.number_of_units }.sum

    # Write/report results
    report_runperiod_output_results(runner, new_runner, num_units)
    report_timeseries_output_results(args, num_units)

    register_logs(runner, new_runner)

    return true
  end

  def report_runperiod_output_results(runner, new_runner, num_units)
    n_digits = 3

    new_runner.result.stepValues.each do |step_value|
      value = get_value_from_workflow_step_value(step_value)
      variant_type = step_value.variantType
      if ['Double'.to_VariantType, 'Integer'.to_VariantType].include? variant_type
        value = scale_output(step_value.name, value, num_units, n_digits)
      end
      register_value(runner, step_value.name, value)
    end
  end

  def report_timeseries_output_results(args, num_units)
    return if num_units == 1

    timeseries_output_path = File.expand_path('../results_timeseries.csv')
    n_digits = args[:timeseries_num_decimal_places]

    if File.exist?(timeseries_output_path)
      rows = CSV.read(timeseries_output_path, headers: true)
      File.rename(timeseries_output_path, timeseries_output_path.gsub('.csv', '_bak.csv'))
      CSV.open(timeseries_output_path, 'wb') do |csv_out|
        csv_out << rows.headers
        csv_out << rows[0].fields
        rows[1..-1].each do |row|
          row.headers.each do |header|
            next if ['Time', 'TimeDST', 'TimeUTC'].include?(header)

            value = Float(row[header])
            row[header] = scale_output(header, value, num_units, n_digits)
          end
          csv_out << row.fields
        end
      end
      File.delete(timeseries_output_path.gsub('.csv', '_bak.csv'))
    end
  end

  def scale_output(output, value, num_units, n_digits)
    return value if num_units == 1

    Constants::ReportSimulationOutputUnchangeds.each do |unchanged_output|
      if output.start_with?(unchanged_output) || output.start_with?(OpenStudio::toUnderscoreCase(unchanged_output).chomp('_'))
        return value.round(n_digits)
      end
    end
    return (value / num_units).round(n_digits)
  end
  # FIXME: how to deal with output variables/meters (i.e., scale Electricity:Facility but not Zone People Occupant Count)?
end

# register the measure to be used by the application
SimulationOutput.new.registerWithApplication
