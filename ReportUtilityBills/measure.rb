# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'msgpack'
require 'time'
require_relative 'resources/util.rb'
require_relative '../HPXMLtoOpenStudio/resources/constants.rb'
require_relative '../HPXMLtoOpenStudio/resources/location.rb'
require_relative '../HPXMLtoOpenStudio/resources/meta_measure.rb'
require_relative '../HPXMLtoOpenStudio/resources/output.rb'
require_relative '../HPXMLtoOpenStudio/resources/util'

# start the measure
class ReportUtilityBills < OpenStudio::Measure::ReportingMeasure
  # human readable name
  def name
    return 'Utility Bills Report'
  end

  # human readable description
  def description
    return 'Calculates and reports utility bills for residential HPXML-based models.'
  end

  # human readable description of modeling approach
  def modeler_description
    return "Calculate electric/gas utility bills based on monthly fixed charges and marginal rates. Calculate other utility bills based on marginal rates for oil, propane, wood cord, wood pellets, and coal. User can specify PV compensation types of 'Net-Metering' or 'Feed-In Tariff', along with corresponding rates and connection fees."
  end

  # Define the arguments that the user will input.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @return [OpenStudio::Measure::OSArgumentVector] an OpenStudio::Measure::OSArgumentVector object
  def arguments(model = nil) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    format_chs = OpenStudio::StringVector.new
    format_chs << 'csv'
    format_chs << 'json'
    format_chs << 'msgpack'
    # format_chs << 'csv_dview': # TODO: support this
    arg = OpenStudio::Measure::OSArgument.makeChoiceArgument('output_format', format_chs, false)
    arg.setDisplayName('Output Format')
    arg.setDescription('The file format of the annual (and timeseries, if requested) outputs.')
    arg.setDefaultValue('csv')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('include_annual_bills', false)
    arg.setDisplayName('Generate Annual Utility Bills')
    arg.setDescription('Generates output file containing annual utility bills.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('include_monthly_bills', false)
    arg.setDisplayName('Generate Monthly Utility Bills')
    arg.setDescription('Generates output file containing monthly utility bills.')
    arg.setDefaultValue(true)
    args << arg

    timestamp_chs = OpenStudio::StringVector.new
    timestamp_chs << 'start'
    timestamp_chs << 'end'
    arg = OpenStudio::Measure::OSArgument.makeChoiceArgument('monthly_timestamp_convention', timestamp_chs, false)
    arg.setDisplayName('Generate Monthly Output: Timestamp Convention')
    arg.setDescription('Determines whether monthly timestamps use the start-of-period or end-of-period convention.')
    arg.setDefaultValue('start')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('annual_output_file_name', false)
    arg.setDisplayName('Annual Output File Name')
    arg.setDescription("If not provided, defaults to 'results_bills.csv' (or 'results_bills.json' or 'results_bills.msgpack').")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('monthly_output_file_name', false)
    arg.setDisplayName('Monthly Output File Name')
    arg.setDescription("If not provided, defaults to 'results_bills_monthly.csv' (or 'results_bills_monthly.json' or 'results_bills_monthly.msgpack').")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('register_annual_bills', false)
    arg.setDisplayName('Register Annual Utility Bills')
    arg.setDescription('Registers annual utility bills with the OpenStudio runner for downstream processing.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('register_monthly_bills', false)
    arg.setDisplayName('Register Monthly Utility Bills')
    arg.setDescription('Registers monthly utility bills with the OpenStudio runner for downstream processing.')
    arg.setDefaultValue(false)
    args << arg

    return args
  end

  # Check for situations that are currently not supported when calculating any type of utility bill scenario.
  #
  # @return [Array<String>] array of warnings
  def check_for_return_type_warnings()
    warnings = []

    # Require full annual simulation if PV
    if !(@hpxml_header.sim_begin_month == 1 && @hpxml_header.sim_begin_day == 1 && @hpxml_header.sim_end_month == 12 && @hpxml_header.sim_end_day == 31)
      if @hpxml_buildings.count { |hpxml_bldg| !hpxml_bldg.pv_systems.empty? } > 0
        warnings << 'A full annual simulation is required for calculating utility bills for homes with PV.'
      end
    end

    # Require not DSE
    @hpxml_buildings.each do |hpxml_bldg|
      (hpxml_bldg.heating_systems + hpxml_bldg.heat_pumps).each do |htg_system|
        next unless (htg_system.is_a?(HPXML::HeatingSystem) && htg_system.is_heat_pump_backup_system) || htg_system.fraction_heat_load_served > 0
        next if htg_system.distribution_system_idref.nil?
        next unless htg_system.distribution_system.distribution_system_type == HPXML::HVACDistributionTypeDSE
        next if htg_system.distribution_system.annual_heating_dse.nil?
        next if htg_system.distribution_system.annual_heating_dse == 1

        warnings << 'DSE is not currently supported when calculating utility bills.'
      end
      (hpxml_bldg.cooling_systems + hpxml_bldg.heat_pumps).each do |clg_system|
        next unless clg_system.fraction_cool_load_served > 0
        next if clg_system.distribution_system_idref.nil?
        next unless clg_system.distribution_system.distribution_system_type == HPXML::HVACDistributionTypeDSE
        next if clg_system.distribution_system.annual_cooling_dse.nil?
        next if clg_system.distribution_system.annual_cooling_dse == 1

        warnings << 'DSE is not currently supported when calculating utility bills.'
      end
    end

    return warnings.uniq
  end

  # Check for situations that are currently not supported for certain types of utility bill scenarios.
  #
  # @param utility_bill_scenario [HPXML::UtilityBillScenario] HPXML Utility Bill Scenario object
  # @return [Array<String>] array of warnings
  def check_for_next_type_warnings(utility_bill_scenario)
    warnings = []

    # Require full annual simulation if 'Detailed'
    if !(@hpxml_header.sim_begin_month == 1 && @hpxml_header.sim_begin_day == 1 && @hpxml_header.sim_end_month == 12 && @hpxml_header.sim_end_day == 31)
      if !utility_bill_scenario.elec_tariff_filepath.nil?
        warnings << 'A full annual simulation is required for calculating detailed utility bills.'
      end
    end

    return warnings.uniq
  end

  # Adds OpenStudio model objects to requests desired outputs.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param user_arguments [OpenStudio::Measure::OSArgumentMap] OpenStudio measure arguments
  # @return [Boolean] Success
  def modelOutputRequests(model, runner, user_arguments)
    return false if runner.halted

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    hpxml_defaults_path = model.getBuilding.additionalProperties.getFeatureAsString('hpxml_defaults_path').get
    building_id = model.getBuilding.additionalProperties.getFeatureAsString('building_id').get
    hpxml = HPXML.new(hpxml_path: hpxml_defaults_path, building_id: building_id)

    @hpxml_header = hpxml.header
    @hpxml_buildings = hpxml.buildings
    if @hpxml_header.utility_bill_scenarios.has_detailed_electric_rates
      uses_unit_multipliers = @hpxml_buildings.count { |hpxml_bldg| hpxml_bldg.building_construction.number_of_units > 1 } > 0
      if uses_unit_multipliers || (@hpxml_buildings.size > 1 && hpxml.header.whole_sfa_or_mf_building_sim)
        return false
      end
    end

    warnings = check_for_return_type_warnings()
    return false if !warnings.empty?

    fuels = setup_fuel_outputs()

    # Check for presence of fuels once
    has_fuel = hpxml.has_fuels()

    # Has production
    has_pv = @hpxml_buildings.count { |hpxml_bldg| !hpxml_bldg.pv_systems.empty? } > 0

    # Fuel outputs
    fuels.each do |(fuel_type, is_production), fuel|
      next unless has_fuel[get_hpxml_fuel(fuel_type)]
      next if is_production && !has_pv # we don't need to request this meter if there isn't pv

      Model.add_output_meter(model, meter_name: fuel.meter, reporting_frequency: 'monthly')
      if fuel_type == FT::Elec && @hpxml_header.utility_bill_scenarios.has_detailed_electric_rates
        Model.add_output_meter(model, meter_name: fuel.meter, reporting_frequency: 'hourly')
      end
    end

    return true
  end

  # Register to the runner each warning.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param warnings [Array<String>] array of warnings
  # @return [Boolean] true if any warnings were registered
  def register_warnings(runner, warnings)
    return false if warnings.empty?

    warnings.each do |warning|
      runner.registerWarning(warning)
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
    model = model.get

    # use the built-in error checking (need model)
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    args = runner.getArgumentValues(arguments(model), user_arguments)

    hpxml_path = model.getBuilding.additionalProperties.getFeatureAsString('hpxml_path').get
    hpxml_defaults_path = model.getBuilding.additionalProperties.getFeatureAsString('hpxml_defaults_path').get
    output_dir = File.dirname(hpxml_defaults_path)
    building_id = model.getBuilding.additionalProperties.getFeatureAsString('building_id').get
    hpxml = HPXML.new(hpxml_path: hpxml_defaults_path, building_id: building_id)

    @hpxml_header = hpxml.header
    @hpxml_buildings = hpxml.buildings
    if @hpxml_header.utility_bill_scenarios.has_detailed_electric_rates
      uses_unit_multipliers = @hpxml_buildings.count { |hpxml_bldg| hpxml_bldg.building_construction.number_of_units > 1 } > 0
      if uses_unit_multipliers
        runner.registerWarning('Cannot currently calculate utility bills based on detailed electric rates for an HPXML with unit multipliers.')
        return false
      elsif @hpxml_buildings.size > 1 && hpxml.header.whole_sfa_or_mf_building_sim
        runner.registerWarning('Cannot currently calculate utility bills based on detailed electric rates for a whole SFA/MF building simulation.')
        return false
      end
    end

    return true if @hpxml_header.utility_bill_scenarios.empty?

    if not File.exist? File.join(output_dir, 'eplusout.msgpack')
      runner.registerError('Cannot find eplusout.msgpack.')
      return false
    end
    @msgpackData = MessagePack.unpack(File.read(File.join(output_dir, 'eplusout.msgpack'), mode: 'rb'))

    warnings = check_for_return_type_warnings()
    if register_warnings(runner, warnings)
      return true
    end

    # Set paths
    if not args[:annual_output_file_name].nil?
      annual_output_path = File.join(output_dir, args[:annual_output_file_name])
    else
      annual_output_path = File.join(output_dir, "results_bills.#{args[:output_format]}")
    end
    if not args[:monthly_output_file_name].nil?
      monthly_output_path = File.join(output_dir, args[:monthly_output_file_name])
    else
      monthly_output_path = File.join(output_dir, "results_bills_monthly.#{args[:output_format]}")
    end

    if args[:include_monthly_bills] || args[:register_monthly_bills]
      @timestamps = get_timestamps(args)
    end

    num_units = @hpxml_buildings.collect { |hpxml_bldg| hpxml_bldg.building_construction.number_of_units }.sum

    # Setup fuel outputs once
    fuels = setup_fuel_outputs()

    # Check for presence of fuels once
    has_fuel = hpxml.has_fuels()

    monthly_data = []
    @hpxml_header.utility_bill_scenarios.each do |utility_bill_scenario|
      warnings = check_for_next_type_warnings(utility_bill_scenario)
      if register_warnings(runner, warnings)
        next
      end

      # Get outputs
      get_outputs(fuels, utility_bill_scenario)

      # Setup utility outputs
      utility_rates, utility_bills = setup_utility_outputs()

      # Get PV monthly fee
      pv_monthly_fee = get_pv_monthly_fee(utility_bill_scenario, @hpxml_buildings)

      # Get utility rates
      warnings = get_utility_rates(hpxml_path, has_fuel, utility_rates, utility_bill_scenario, pv_monthly_fee, num_units)
      if register_warnings(runner, warnings)
        next
      end

      # Calculate utility bills
      get_utility_bills(fuels, utility_rates, utility_bills, utility_bill_scenario, @hpxml_header)

      # Write/report runperiod results
      report_runperiod_output_results(runner, args, utility_bills, annual_output_path, utility_bill_scenario.name)

      # Get monthly results
      get_monthly_output_results(args, utility_bills, utility_bill_scenario.name, monthly_data, @hpxml_header)
    end

    # Write/report monthly results
    report_monthly_output_results(runner, args, @timestamps, monthly_data, monthly_output_path)

    return true
  end

  # Get the PV monthly grid connection fee.
  #
  # @param bill_scenario [HPXML::UtilityBillScenario] HPXML Utility Bill Scenario object
  # @param hpxml_buildings [HPXML::Buildings] HPXML Buildings object
  # @return [Double] the sum of the monthly grid connection fees ($) across HPXML Buildings
  def get_pv_monthly_fee(bill_scenario, hpxml_buildings)
    pv_monthly_fee = 0.0
    if not bill_scenario.pv_monthly_grid_connection_fee_dollars_per_kw.nil?
      hpxml_buildings.each do |hpxml_bldg|
        hpxml_bldg.pv_systems.each do |pv_system|
          max_power_output_kW = UnitConversions.convert(pv_system.max_power_output, 'W', 'kW')
          pv_monthly_fee += bill_scenario.pv_monthly_grid_connection_fee_dollars_per_kw * max_power_output_kW
          pv_monthly_fee *= hpxml_bldg.building_construction.number_of_units if !hpxml_bldg.building_construction.number_of_units.nil?
        end
      end
    elsif not bill_scenario.pv_monthly_grid_connection_fee_dollars.nil?
      pv_monthly_fee = bill_scenario.pv_monthly_grid_connection_fee_dollars
    end

    return pv_monthly_fee
  end

  # Get monthly timestamps for reporting.
  #
  # @param args [Hash] Map of :argument_name => value
  # @return [Array<String>] array of monthly timestamps (e.g., 2007-01-01T00:00:00)
  def get_timestamps(args)
    msgpack_monthly_name = EPlus::get_msgpack_timeseries_name(EPlus::TimeseriesFrequencyMonthly)
    ep_timestamps = @msgpackData['MeterData'][msgpack_monthly_name]['Rows'].map { |r| r.keys[0] }

    timestamps = []
    year = @hpxml_header.sim_calendar_year
    ep_timestamps.each do |ep_timestamp|
      month_day, hour_minute = ep_timestamp.split(' ')
      month, day = month_day.split('/').map(&:to_i)
      hour, minute, _ = hour_minute.split(':').map(&:to_i)

      # Convert from EnergyPlus default (end-of-timestep) to start-of-timestep convention
      if args[:monthly_timestamp_convention] == 'start'
        ts_offset = Calendar.num_days_in_months(year)[month - 1] * 60 * 60 * 24 # seconds
      end

      ts = Time.utc(year, month, day, hour, minute)
      ts -= ts_offset unless ts_offset.nil?

      timestamps << ts.iso8601.delete('Z')
    end

    return timestamps
  end

  # Write and/or register to the runner the calculated runperiod utility bills.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param args [Hash] Map of :argument_name => value
  # @param utility_bills [Hash] Fuel type => UtilityRate object
  # @param annual_output_path [String] the file path containing annual utility bills
  # @param bill_scenario_name [String] the name of the HPXML Utility Bill Scenario
  def report_runperiod_output_results(runner, args, utility_bills, annual_output_path, bill_scenario_name)
    return unless (args[:include_annual_bills] || args[:register_annual_bills])

    results_out = []
    results_out << ["#{bill_scenario_name}: Total (USD)", utility_bills.values.sum { |bill| bill.annual_total.round(2) }.round(2)]

    utility_bills.each do |fuel_type, bill|
      results_out << ["#{bill_scenario_name}: #{fuel_type}: Fixed (USD)", bill.annual_fixed_charge.round(2)]
      results_out << ["#{bill_scenario_name}: #{fuel_type}: Energy (USD)", bill.annual_energy_charge.round(2)]
      results_out << ["#{bill_scenario_name}: #{fuel_type}: PV Credit (USD)", bill.annual_production_credit.round(2)] if [FT::Elec].include?(fuel_type)
      results_out << ["#{bill_scenario_name}: #{fuel_type}: Total (USD)", bill.annual_total.round(2)]
    end

    line_break = nil
    results_out << [line_break]

    if args[:include_annual_bills]
      Outputs.write_results_out_to_file(results_out, args[:output_format], annual_output_path, 'a')
      runner.registerInfo("Wrote annual bills output to #{annual_output_path}.")
    end

    return unless args[:register_annual_bills]

    Outputs.register_results_out_to_runner(runner, results_out)
  end

  # Get monthly utility bill data from the utility_bills Hash.
  #
  # @param args [Hash] Map of :argument_name => value
  # @param utility_bills [Hash] Fuel type => UtilityBill object
  # @param bill_scenario_name [String] the name of the HPXML Utility Bill Scenario
  # @param monthly_data [Array<String>] lines of monthly utility bill data
  # @param header [HPXML::Header] HPXML Header object (one per HPXML file)
  def get_monthly_output_results(args, utility_bills, bill_scenario_name, monthly_data, header)
    run_period = (header.sim_begin_month - 1)..(header.sim_end_month - 1)
    monthly_data << ["#{bill_scenario_name}: Total", 'USD'] + ([0.0] * run_period.size)
    total_ix = monthly_data.size - 1

    if args[:include_monthly_bills] || args[:register_monthly_bills]
      utility_bills.each do |fuel_type, bill|
        monthly_data[total_ix][2..-1] = monthly_data[total_ix][2..-1].zip(bill.monthly_total[run_period].map { |v| v.round(2) }).map { |x, y| x + y }
        monthly_data << ["#{bill_scenario_name}: #{fuel_type}: Fixed", 'USD'] + bill.monthly_fixed_charge[run_period].map { |v| v.round(2) }
        monthly_data << ["#{bill_scenario_name}: #{fuel_type}: Energy", 'USD'] + bill.monthly_energy_charge[run_period].map { |v| v.round(2) }
        monthly_data << ["#{bill_scenario_name}: #{fuel_type}: PV Credit", 'USD'] + bill.monthly_production_credit[run_period].map { |v| v.round(2) } if [FT::Elec].include?(fuel_type)
        monthly_data << ["#{bill_scenario_name}: #{fuel_type}: Total", 'USD'] + bill.monthly_total[run_period].map { |v| v.round(2) }
      end
    end
  end

  # Write and/or register to the runner the calculated monthly utility bills.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param args [Hash] Map of :argument_name => value
  # @param timestamps [Array<String>] array of monthly timestamps (e.g., 2007-01-01T00:00:00)
  # @param monthly_data [Array<String>] lines of monthly utility bill data
  # @param monthly_output_path [String] the file path containing monthly utility bills
  def report_monthly_output_results(runner, args, timestamps, monthly_data, monthly_output_path)
    return unless (args[:include_monthly_bills] || args[:register_monthly_bills])

    # Initial output data w/ Time column(s)
    data = ['Time', nil] + timestamps

    return if monthly_data.size == 0

    fail 'Unable to obtain timestamps.' if timestamps.empty?

    if args[:include_monthly_bills]
      if ['csv'].include? args[:output_format]
        # Assemble data
        data = data.zip(*monthly_data)

        # Write file
        # Note: We don't use the CSV library here because it's slow for large files
        File.open(monthly_output_path, 'wb') { |csv| data.to_a.each { |elem| csv << "#{elem.join(',')}\n" } }
      elsif ['json', 'msgpack'].include? args[:output_format]
        h = {}
        h['Time'] = data[2..-1]

        [monthly_data].each do |d|
          d.each do |o|
            grp, name = o[0].split(':', 2)
            h[grp] = {} if h[grp].nil?
            h[grp]["#{name.strip} (#{o[1]})"] = o[2..-1]
          end
        end

        if args[:output_format] == 'json'
          require 'json'
          File.open(monthly_output_path, 'w') { |json| json.write(JSON.pretty_generate(h)) }
        elsif args[:output_format] == 'msgpack'
          File.open(monthly_output_path, 'wb') { |json| h.to_msgpack(json) }
        end
      end
      runner.registerInfo("Wrote monthly bills output to #{monthly_output_path}.")
    end

    return unless args[:register_monthly_bills]

    monthly_data.each do |col|
      next unless col[0].include?('Total')

      timestamps.zip(col[2..-1]).each do |ts, value|
        t = ts
        t, _ = t.split('T') if t.is_a?(String) && t.include?('T')

        name = OpenStudio::toUnderscoreCase("#{col[0]} #{col[1]} #{t}").chomp('_')

        runner.registerValue(name, value)
        runner.registerInfo("Registering #{value} for #{name}.")
      end
    end
  end

  # Fill each UtilityRate object based on simple or detailed utility rate information.
  #
  # @param hpxml_path [String] Path to the HPXML file
  # @param has_fuel [Hash] Map of HPXML fuel type => boolean of whether fuel type is used
  # @param utility_rates [Hash] Fuel Type => UtilityRate object
  # @param bill_scenario [HPXML::UtilityBillScenario] HPXML Utility Bill Scenario object
  # @param pv_monthly_fee [Double] the sum of the monthly grid connection fees ($) across HPXML Buildings
  # @param num_units [Integer] total number of units represented by the HPXML file
  # @return [Array<String>] array of warnings
  def get_utility_rates(hpxml_path, has_fuel, utility_rates, bill_scenario, pv_monthly_fee, num_units = 1)
    warnings = []
    utility_rates.each do |fuel_type, rate|
      next unless has_fuel[get_hpxml_fuel(fuel_type)]

      case fuel_type
      when FT::Elec
        if bill_scenario.elec_tariff_filepath.nil?
          rate.fixed_charge_monthly = bill_scenario.elec_fixed_charge
          rate.flat_rate = bill_scenario.elec_marginal_rate
        else
          require 'json'

          tariff_name = File.basename(bill_scenario.elec_tariff_filepath)

          filepath = FilePath.check_path(bill_scenario.elec_tariff_filepath,
                                         File.dirname(hpxml_path),
                                         'Tariff File')

          tariff = JSON.parse(File.read(filepath), symbolize_names: true)
          tariff = tariff[:items][0]
          fields = tariff.keys

          rate.fixed_charge_monthly = 0.0
          rate.fixed_charge_daily = 0.0
          if fields.include?(:fixedchargeunits) && tariff[:fixedchargefirstmeter].to_f > 0
            if tariff[:fixedchargeunits] == '$/month'
              rate.fixed_charge_monthly += tariff[:fixedchargefirstmeter].to_f
            elsif tariff[:fixedchargeunits] == '$/day'
              rate.fixed_charge_daily += tariff[:fixedchargefirstmeter].to_f
            else
              warnings << "#{tariff_name}: Unsupported fixed charge units (#{tariff[:fixedchargeunits]}); utility bills will not be calculated."
            end
          end

          if fields.include?(:minchargeunits) && tariff[:mincharge].to_f > 0
            if tariff[:minchargeunits] == '$/month'
              rate.min_charge_monthly = tariff[:mincharge].to_f
            elsif tariff[:minchargeunits] == '$/year'
              rate.min_charge_annual = tariff[:mincharge].to_f
            else
              warnings << "#{tariff_name}: Unsupported min charge units (#{tariff[:minchargeunits]}); utility bills will not be calculated."
            end
          end

          if fields.include?(:realtimepricing)
            rate.real_time_prices = tariff[:realtimepricing]

          else
            if !fields.include?(:energyweekdayschedule) || !fields.include?(:energyweekendschedule) || !fields.include?(:energyratestructure)
              warnings << "#{tariff_name}: Tariff file must contain energyweekdayschedule, energyweekendschedule, and energyratestructure fields; utility bills will not be calculated."
            end

            if fields.include?(:demandweekdayschedule) || fields.include?(:demandweekendschedule) || fields.include?(:demandratestructure) || fields.include?(:flatdemandstructure)
              warnings << "#{tariff_name}: Demand charges are not currently supported; utility bills will not be calculated."
            end

            rate.energy_rate_structure = tariff[:energyratestructure]
            rate.energy_weekday_schedule = tariff[:energyweekdayschedule]
            rate.energy_weekend_schedule = tariff[:energyweekendschedule]

            if rate.energy_rate_structure.collect { |r| r.collect { |s| !s.keys.include?(:rate) } }.flatten.any?
              warnings << "#{tariff_name}: Every tier must contain a rate; utility bills will not be calculated."
            end

            if rate.energy_rate_structure.collect { |r| r.collect { |s| s.keys } }.flatten.uniq.include?(:sell)
              warnings << "#{tariff_name}: Tariffs with sell rates are not currently supported; utility bills will not be calculated."
            end

            if rate.energy_rate_structure.collect { |r| r.collect { |s| s[:unit] != 'kWh' && s.keys.include?(:max) } }.flatten.any?
              warnings << "#{tariff_name}: Only max usage units of kWh are currently supported; utility bills will not be calculated."
            end
          end
        end

        # Net Metering
        rate.net_metering_excess_sellback_type = bill_scenario.pv_net_metering_annual_excess_sellback_rate_type if bill_scenario.pv_compensation_type == HPXML::PVCompensationTypeNetMetering
        rate.net_metering_user_excess_sellback_rate = bill_scenario.pv_net_metering_annual_excess_sellback_rate if rate.net_metering_excess_sellback_type == HPXML::PVAnnualExcessSellbackRateTypeUserSpecified

        # Feed-In Tariff
        rate.feed_in_tariff_rate = bill_scenario.pv_feed_in_tariff_rate if bill_scenario.pv_compensation_type == HPXML::PVCompensationTypeFeedInTariff
      when FT::Gas
        rate.fixed_charge_monthly = bill_scenario.natural_gas_fixed_charge
        rate.flat_rate = bill_scenario.natural_gas_marginal_rate
      when FT::Oil
        rate.fixed_charge_monthly = bill_scenario.fuel_oil_fixed_charge
        rate.flat_rate = bill_scenario.fuel_oil_marginal_rate
      when FT::Propane
        rate.fixed_charge_monthly = bill_scenario.propane_fixed_charge
        rate.flat_rate = bill_scenario.propane_marginal_rate
      when FT::WoodCord
        rate.fixed_charge_monthly = bill_scenario.wood_fixed_charge
        rate.flat_rate = bill_scenario.wood_marginal_rate
      when FT::WoodPellets
        rate.fixed_charge_monthly = bill_scenario.wood_pellets_fixed_charge
        rate.flat_rate = bill_scenario.wood_pellets_marginal_rate
      when FT::Coal
        rate.fixed_charge_monthly = bill_scenario.coal_fixed_charge
        rate.flat_rate = bill_scenario.coal_marginal_rate
      end
      rate.fixed_charge_monthly *= num_units if !rate.fixed_charge_monthly.nil?
      rate.fixed_charge_daily *= num_units if !rate.fixed_charge_daily.nil?

      warnings << "Could not find a marginal #{fuel_type} rate." if rate.flat_rate.nil?

      # Grid connection fee
      next unless fuel_type == FT::Elec

      rate.fixed_charge_monthly += pv_monthly_fee
    end
    return warnings
  end

  # Fill each UtilityBill object based on both fuel and utility rate information.
  #
  # @param fuels [Hash] Fuel type, is_production => Fuel object
  # @param utility_rates [Hash] Fuel Type => UtilityRate object
  # @param utility_bills [Hash] Fuel type => UtilityBill object
  # @param utility_bill_scenario [HPXML::UtilityBillScenario] HPXML Utility Bill Scenario object
  # @param header [HPXML::Header] HPXML Header object (one per HPXML file)
  def get_utility_bills(fuels, utility_rates, utility_bills, utility_bill_scenario, header)
    net_elec = 0

    # Simple
    fuels.each do |(fuel_type, is_production), fuel|
      rate = utility_rates[fuel_type]
      bill = utility_bills[fuel_type]

      if fuel_type == FT::Elec
        if utility_bill_scenario.elec_tariff_filepath.nil?
          net_elec = CalculateUtilityBill.simple(fuel_type, header, fuel.timeseries, is_production, rate, bill, net_elec)
        end
      else
        net_elec = CalculateUtilityBill.simple(fuel_type, header, fuel.timeseries, is_production, rate, bill, net_elec)
      end
    end

    # Detailed
    if !utility_bill_scenario.elec_tariff_filepath.nil?
      rate = utility_rates[FT::Elec]
      bill = utility_bills[FT::Elec]

      CalculateUtilityBill.detailed_electric(header, fuels, rate, bill)
    end

    # Calculate totals
    utility_bills.values.each do |bill|
      if bill.annual_production_credit != 0
        bill.annual_production_credit *= -1

        # Report the PV credit at the end of the year for all scenarios.
        for month in 0..10
          bill.monthly_production_credit[month] = 0.0
        end
        bill.monthly_production_credit[11] = bill.annual_production_credit
      end

      bill.annual_total = bill.annual_fixed_charge + bill.annual_energy_charge + bill.annual_production_credit
      bill.monthly_total = [bill.monthly_fixed_charge, bill.monthly_energy_charge, bill.monthly_production_credit].transpose.map { |x| x.sum }
    end
  end

  # Initialize the Fuel objects with meter and fuel units.
  #
  # @return [Hash] Fuel type, is_production => Fuel object
  def setup_fuel_outputs()
    fuels = {}
    fuels[[FT::Elec, false]] = Fuel.new(meter: Outputs::MeterCustomElectricityTotal.upcase, fuel: HPXML::FuelTypeElectricity)
    fuels[[FT::Elec, true]] = Fuel.new(meter: Outputs::MeterCustomElectricityPV.upcase, fuel: HPXML::FuelTypeElectricity)
    fuels[[FT::Gas, false]] = Fuel.new(meter: "#{EPlus::FuelTypeNaturalGas}:Facility", fuel: HPXML::FuelTypeNaturalGas)
    fuels[[FT::Oil, false]] = Fuel.new(meter: "#{EPlus::FuelTypeOil}:Facility", fuel: HPXML::FuelTypeOil)
    fuels[[FT::Propane, false]] = Fuel.new(meter: "#{EPlus::FuelTypePropane}:Facility", fuel: HPXML::FuelTypePropane)
    fuels[[FT::WoodCord, false]] = Fuel.new(meter: "#{EPlus::FuelTypeWoodCord}:Facility", fuel: HPXML::FuelTypeWoodCord)
    fuels[[FT::WoodPellets, false]] = Fuel.new(meter: "#{EPlus::FuelTypeWoodPellets}:Facility", fuel: HPXML::FuelTypeWoodPellets)
    fuels[[FT::Coal, false]] = Fuel.new(meter: "#{EPlus::FuelTypeCoal}:Facility", fuel: HPXML::FuelTypeCoal)
    return fuels
  end

  # Initialize both the UtilityRate and UtilityBill objects.
  #
  # @return [Array<Hash, Hash>] Fuel Type => UtilityRate object, Fuel type => UtilityBill object
  def setup_utility_outputs()
    utility_rates = {}
    utility_rates[FT::Elec] = UtilityRate.new
    utility_rates[FT::Gas] = UtilityRate.new
    utility_rates[FT::Oil] = UtilityRate.new
    utility_rates[FT::Propane] = UtilityRate.new
    utility_rates[FT::WoodCord] = UtilityRate.new
    utility_rates[FT::WoodPellets] = UtilityRate.new
    utility_rates[FT::Coal] = UtilityRate.new

    utility_bills = {}
    utility_bills[FT::Elec] = UtilityBill.new
    utility_bills[FT::Gas] = UtilityBill.new
    utility_bills[FT::Oil] = UtilityBill.new
    utility_bills[FT::Propane] = UtilityBill.new
    utility_bills[FT::WoodCord] = UtilityBill.new
    utility_bills[FT::WoodPellets] = UtilityBill.new
    utility_bills[FT::Coal] = UtilityBill.new

    return utility_rates, utility_bills
  end

  # Fill each Fuel object with timeseries data.
  #
  # @param fuels [Hash] Fuel type, is_production => Fuel object
  # @param utility_bill_scenario [HPXML::UtilityBillScenario] HPXML Utility Bill Scenario object
  def get_outputs(fuels, utility_bill_scenario)
    fuels.each do |(fuel_type, _is_production), fuel|
      unit_conv = UnitConversions.convert(1.0, 'J', fuel.units)

      timeseries_freq = EPlus::TimeseriesFrequencyMonthly
      if fuel_type == FT::Elec && !utility_bill_scenario.elec_tariff_filepath.nil?
        timeseries_freq = EPlus::TimeseriesFrequencyHourly
      end
      fuel.timeseries = get_report_meter_data_timeseries(fuel.meter, unit_conv, timeseries_freq)
    end
  end

  # Get the reported timeseries data from the fuel meter.
  #
  # @param meter_name [String] EnergyPlus meter name
  # @param unit_conv [Double] the scalar that converts 1 Joule into units of the fuel meter
  # @param timeseries_freq [String] the frequency of the requested timeseries data
  # @return [Array<Double>] array of timeseries data
  def get_report_meter_data_timeseries(meter_name, unit_conv, timeseries_freq)
    msgpack_timeseries_name = EPlus::get_msgpack_timeseries_name(timeseries_freq)
    data = @msgpackData['MeterData'][msgpack_timeseries_name]
    cols = data['Cols']
    rows = data['Rows']

    index = cols.each_index.find { |i| meter_name == cols[i]['Variable'] }
    return [0.0] * rows.size if index.nil?

    vals = []
    rows.each do |row|
      vals << row[row.keys[0]][index] * unit_conv
    end
    return vals
  end

  # Get HPXML fuel type according to output reporting fuel type constant.
  #
  # @param fuel_type [String] Constant fuel type for output reporting
  # @return [String] HPXML fuel type
  def get_hpxml_fuel(fuel_type)
    return { FT::Elec => HPXML::FuelTypeElectricity,
             FT::Gas => HPXML::FuelTypeNaturalGas,
             FT::Oil => HPXML::FuelTypeOil,
             FT::Propane => HPXML::FuelTypePropane,
             FT::WoodCord => HPXML::FuelTypeWoodCord,
             FT::WoodPellets => HPXML::FuelTypeWoodPellets,
             FT::Coal => HPXML::FuelTypeCoal }[fuel_type]
  end
end

# register the measure to be used by the application
ReportUtilityBills.new.registerWithApplication
