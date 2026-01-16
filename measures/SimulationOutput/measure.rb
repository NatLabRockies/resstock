# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require_relative 'resources/constants'
require_relative '../../resources/buildstock'
require_relative '../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/constants'
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

    @model = model

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Apply reporting measure output requests
    hpxml_measures_dir = File.join(File.dirname(__FILE__), '../../resources/hpxml-measures')
    args = runner.getArgumentValues(arguments(model), user_arguments)
    measures = setup_measures(args)
    apply_model_output_requests(hpxml_measures_dir, measures, runner, model)

    setup_outputs()

    # End Use outputs
    { @end_uses => args[:include_timeseries_end_use_consumptions] }.each do |uses, include_timeseries|
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

    return true
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

  def get_outputs(_runner, args)
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

    # Calculate aggregated values from per-system values as needed
    @end_uses.values.each do |obj|
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
  end

  def setup_outputs()
    # Returns the timeseries units associated with energy use
    # for the given fuel.
    #
    # @param fuel_type [String] The given fuel type (FT::XXX)
    # @return [String] The units
    def get_timeseries_units_from_fuel_type(fuel_type)
      return (fuel_type == FT::Elec ? 'kWh' : 'kBtu')
    end

    # End Uses

    create_all_object_outputs_by_key()

    @end_uses = {}
    @end_uses[[FT::Elec, EUT::RangeOven]] = EndUse.new(outputs: get_object_outputs(EUT, [FT::Elec, EUT::RangeOven]))
    @end_uses.each do |key, end_use|
      fuel_type, end_use_type = key
      end_use.name = "End Use: #{fuel_type}: #{end_use_type}"
      end_use.annual_units = 'MBtu'
      end_use.timeseries_units = get_timeseries_units_from_fuel_type(fuel_type)
    end
  end

  # define what happens when the measure is run
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

    # Assign the user inputs to variables
    args = runner.getArgumentValues(arguments(@model), user_arguments)

    hpxml_defaults_path = @model.getBuilding.additionalProperties.getFeatureAsString('hpxml_defaults_path').get
    output_dir = File.dirname(hpxml_defaults_path)
    building_id = @model.getBuilding.additionalProperties.getFeatureAsString('building_id').get
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
    if not apply_measures(hpxml_measures_dir, measures_hash, new_runner, @model, true, 'OpenStudio::Measure::ReportingMeasure', nil)
      register_logs(runner, new_runner)
      return false
    end

    @msgpackData = MessagePack.unpack(File.read(File.join(output_dir, 'eplusout.msgpack'), mode: 'rb'))
    setup_outputs()
    get_outputs(runner, args)
    combine_results(new_runner)

    if not check_for_errors(runner)
      return false
    end

    num_units = hpxml.buildings.collect { |hpxml_bldg| hpxml_bldg.building_construction.number_of_units }.sum

    # Write/report results
    report_runperiod_output_results(runner, num_units)
    report_timeseries_output_results(args, num_units)

    register_logs(runner, new_runner)

    return true
  end

  def combine_results(new_runner)
    # Annual
    @new_results = {}
    new_runner.result.stepValues.each do |step_value|
      variant_type = step_value.variantType
      next unless ['Double'.to_VariantType, 'Integer'.to_VariantType].include? variant_type

      name = step_value.name
      @new_results[name] = get_value_from_workflow_step_value(step_value)
      next unless name == 'end_use_electricity_range_oven_m_btu'

      @new_results[name] += @end_uses[[FT::Elec, EUT::RangeOven]].annual_output
    end

    # Timeseries
    # TODO

    return @new_results
  end

  def check_for_errors(runner)
    tol = 0.1 # 0.1%

    # Check sum of end use outputs match fuel outputs from meters
    unique_fuel_types = [[FT::Elec, TE::Total], [FT::Elec, TE::Net], [FT::Gas, TE::Total], [FT::Oil, TE::Total], [FT::Propane, TE::Total], [FT::WoodCord, TE::Total], [FT::WoodPellets, TE::Total], [FT::Coal, TE::Total]]
    unique_fuel_types.each do |fuel_type, total_or_net|
      total_or_net = (fuel_type == FT::Elec ? TE::Net : TE::Total)
      ft = OpenStudio::toUnderscoreCase(fuel_type)

      sum_categories = @new_results.select { |k, _v| k.start_with?('end_use') && k.include?(ft) }.map { |_k, v| v }.sum(0.0)
      if total_or_net == TE::Total
        meter_fuel_total = @new_results["fuel_use_#{ft}_total_m_btu"]
      elsif total_or_net == TE::Net
        meter_fuel_total = @new_results["fuel_use_#{ft}_net_m_btu"]
      end

      avg_value = (sum_categories + meter_fuel_total) / 2.0
      next unless (sum_categories - meter_fuel_total).abs / avg_value > tol

      runner.registerError("#{fuel_type} category end uses (#{sum_categories.round(3)}) do not sum to total (#{meter_fuel_total.round(3)}).")
      return false
    end
  end

  def report_runperiod_output_results(runner, num_units)
    n_digits = 3

    @new_results.each do |name, value|
      value = scale_output(name, value, num_units, n_digits)
      register_value(runner, name, value)
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
    # FIXME: how to deal with output variables/meters (i.e., scale Electricity:Facility but not Zone People Occupant Count)?
    return value if num_units == 1

    Constants::ReportSimulationOutputUnchangeds.each do |unchanged_output|
      if output.start_with?(unchanged_output) || output.start_with?(OpenStudio::toUnderscoreCase(unchanged_output).chomp('_'))
        return value.round(n_digits)
      end
    end
    return (value / num_units).round(n_digits)
  end

  # Retrieves the total annual value for the specified output meters from the EnergyPlus msgpack output file.
  #
  # @param meter_names [Array<String>] List of EnergyPlus output meter names
  # @param unit_conv [Double] Unit conversion to apply to the EnergyPlus output
  # @return [Double] Sum of output meter annual outputs
  def get_report_meter_data_annual(meter_names, unit_conv = UnitConversions.convert(1.0, 'J', 'MBtu'))
    return 0.0 if meter_names.empty?

    cols = @msgpackData['MeterData']['RunPeriod']['Cols']
    timestamp = @msgpackData['MeterData']['RunPeriod']['Rows'][0].keys[0]
    row = @msgpackData['MeterData']['RunPeriod']['Rows'][0][timestamp]
    indexes = cols.each_index.select { |i| meter_names.include? cols[i]['Variable'] }
    val = row.each_index.select { |i| indexes.include? i }.map { |i| row[i] }.sum(0.0) * unit_conv

    return val
  end

  # Retrieves the total timeseries values for the specified output meters from the EnergyPlus msgpack output file.
  #
  # @param meter_names [Array<String>] List of EnergyPlus output meter names
  # @param unit_conv unit_conv [Double] Unit conversion to apply to the EnergyPlus output
  # @param unit_adder [Double] Adder value to apply to the EnergyPlus output
  # @param timeseries_frequency [String] Timeseries reporting frequency (TimeseriesFrequencyXXX)
  # @return [Array<Double>] Sum of output meter timeseries outputs
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

  # Returns whether we should shift the EMS outputs or not. Only shift if we reporting timestep values
  # (i.e., not daily, monthly, or hourly w/ a sub-hourly timestep).
  #
  # @param timeseries_frequency [String] Timeseries reporting frequency (TimeseriesFrequencyXXX)
  # @return [Boolean] True if the output should be shifted
  def apply_ems_shift(timeseries_frequency)
    if (timeseries_frequency == EPlus::TimeseriesFrequencyTimestep)
      return true
    elsif (timeseries_frequency == EPlus::TimeseriesFrequencyHourly) && (@model.getTimestep.numberOfTimestepsPerHour == 1)
      return true
    end

    return false
  end

  # Returns the list of outputs associated with the given output class type and key.
  #
  # @param class_type [Module] The output class type
  # @param key [String] The particular key for the output class, e.g. HWT::ClothesWasher
  # @return [Array<Array<String, String, String>>] Sets of outputs with: HPXML ID, EnergyPlus output variable key, EnergyPlus output variable/meter name
  def get_object_outputs(class_type, key)
    hash_key = [class_type, key]
    vars = @object_variables_by_key[hash_key]
    vars = [] if vars.nil?
    return vars
  end

  # Base structure to store EnergyPlus annual/timeseries outputs; structures for end uses, loads,
  # etc., will inherit from this class and include additional properties/logic as needed.
  class BaseOutput
    def initialize()
      @timeseries_output = []
    end
    attr_accessor(:name, :annual_output, :timeseries_output, :annual_units, :timeseries_units)
  end

  # Structure to store EnergyPlus outputs by end use and fuel type.
  class EndUse < BaseOutput
    # @param outputs [Array<Array<String, String, String>>] Sets of outputs with: HPXML ID, EnergyPlus output variable key, EnergyPlus output variable/meter name
    # @param is_negative [Boolean] Whether the EnergyPlus outputs are negative
    # @param is_storage [Boolean] Whether the EnergyPlus outputs are associated with battery storage
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

  # Creates a global hash that maps output classes/keys (e.g., [HWT, HWT::ClothesWasher])
  # with its associated data (HPXML ID, EnergyPlus output variable name/key value). This
  # will be used later to look up the EnergyPlus annual or timeseries value(s) for this
  # particular output.
  #
  # @return [nil]
  def create_all_object_outputs_by_key
    @object_variables_by_key = {}
    return if @model.nil?

    @model.getModelObjects.sort.each do |object|
      next if object.to_AdditionalProperties.is_initialized

      [EUT, HWT, LT, RT].each do |class_type|
        vars_by_key = get_object_outputs_by_key(@model, object, class_type)
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
            hash_key = [class_type, key]
            @object_variables_by_key[hash_key] = [] if @object_variables_by_key[hash_key].nil?
            next if @object_variables_by_key[hash_key].include? [sys_id, varkey, output_var]

            @object_variables_by_key[hash_key] << [sys_id, varkey, output_var]
          end
        end
      end
    end
  end

  # For a given object, returns the Output:Variables or Output:Meters to be requested,
  # and associates them with the appropriate keys (e.g., [FT::Elec, EUT::Heating]).
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param object [OpenStudio::Model::Foo] A given object in the OpenStudio Model
  # @param class_type [Module] The output class type
  # @return [Hash] Map of output key => array of EnergyPlus output variable/meter names
  def get_object_outputs_by_key(_model, object, class_type)
    if class_type == EUT
      if object.to_ElectricEquipment.is_initialized
        object = object.to_ElectricEquipment.get
        subcategory = object.endUseSubcategory
        end_use = nil
        { 'AddSharedSystem' => EUT::RangeOven }.each do |obj_name, eut|
          next unless subcategory.start_with? obj_name
          fail 'Unexpected error: multiple matches.' unless end_use.nil?

          end_use = eut
        end

        if not end_use.nil?
          # Use Output:Meter instead of Output:Variable because they incorporate thermal zone multipliers
          if object.space.is_initialized
            zone_name = object.space.get.thermalZone.get.name.to_s.upcase
            return { [FT::Elec, end_use] => ["#{subcategory}:InteriorEquipment:Electricity:Zone:#{zone_name}"] }
          else
            return { [FT::Elec, end_use] => ["#{subcategory}:InteriorEquipment:Electricity"] }
          end
        end
      end
    end

    return {}
  end
end

# register the measure to be used by the application
SimulationOutput.new.registerWithApplication
