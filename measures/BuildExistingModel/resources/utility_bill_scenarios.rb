# frozen_string_literal: true

require 'csv'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/constants'

class UtilityBillScenarios
  # Maps output fields to input arguments or rate-file fields; include_in_outputs: false omits lookup-only fields.
  BILL_FIELDS = {
    'scenario_names' => { argument: :utility_bill_scenario_names },
    'simple_filepaths' => { argument: :utility_bill_simple_filepaths, include_in_outputs: false },
    'detailed_filepaths' => { argument: :utility_bill_detailed_filepaths, include_in_outputs: false },
    'electricity_filepaths' => { argument: nil, rate_field: 'elec_filepath' },
    'electricity_fixed_charges' => { argument: :utility_bill_electricity_fixed_charges, rate_field: 'elec_fixed_charge' },
    'electricity_marginal_rates' => { argument: :utility_bill_electricity_marginal_rates, rate_field: 'elec_marginal_rate' },
    'natural_gas_fixed_charges' => { argument: :utility_bill_natural_gas_fixed_charges, rate_field: 'natural_gas_fixed_charge' },
    'natural_gas_marginal_rates' => { argument: :utility_bill_natural_gas_marginal_rates, rate_field: 'natural_gas_marginal_rate' },
    'propane_fixed_charges' => { argument: :utility_bill_propane_fixed_charges, rate_field: 'propane_fixed_charge' },
    'propane_marginal_rates' => { argument: :utility_bill_propane_marginal_rates, rate_field: 'propane_marginal_rate' },
    'fuel_oil_fixed_charges' => { argument: :utility_bill_fuel_oil_fixed_charges, rate_field: 'fuel_oil_fixed_charge' },
    'fuel_oil_marginal_rates' => { argument: :utility_bill_fuel_oil_marginal_rates, rate_field: 'fuel_oil_marginal_rate' },
    'wood_fixed_charges' => { argument: :utility_bill_wood_fixed_charges, rate_field: 'wood_fixed_charge' },
    'wood_marginal_rates' => { argument: :utility_bill_wood_marginal_rates, rate_field: 'wood_marginal_rate' },
    'pv_compensation_types' => { argument: :utility_bill_pv_compensation_types, rate_field: 'pv_compensation_type' },
    'pv_net_metering_annual_excess_sellback_rate_types' => { argument: :utility_bill_pv_net_metering_annual_excess_sellback_rate_types, rate_field: 'pv_net_metering_annual_excess_sellback_rate_type' },
    'pv_net_metering_annual_excess_sellback_rates' => { argument: :utility_bill_pv_net_metering_annual_excess_sellback_rates, rate_field: 'pv_net_metering_annual_excess_sellback_rate' },
    'pv_feed_in_tariff_rates' => { argument: :utility_bill_pv_feed_in_tariff_rates, rate_field: 'pv_feed_in_tariff_rate' },
    'pv_monthly_grid_connection_fee_units' => { argument: :utility_bill_pv_monthly_grid_connection_fee_units, rate_field: 'pv_monthly_grid_connection_fee_units' },
    'pv_monthly_grid_connection_fees' => { argument: :utility_bill_pv_monthly_grid_connection_fees, rate_field: 'pv_monthly_grid_connection_fee' }
  }.freeze

  # Creates a processor for utility-bill arguments and one building's data.
  # @param args [Hash] BuildExistingModel utility-bill arguments
  # @param bldg_data [Hash] Sampled building characteristics
  # @param resources_dir [String] Root directory for ResStock resources
  # @param characteristics_dir [String] Project housing characteristics directory
  def initialize(args, bldg_data, resources_dir, characteristics_dir)
    @args = args
    @bldg_data = bldg_data
    @resources_dir = resources_dir
    @characteristics_dir = characteristics_dir
  end

  # Expands sampled states, resolves rates, and prepares measure and runner values.
  # @return [Hash] Measure arguments, registered values, warnings, or an error
  def build
    args = @args.dup
    scenario_names_argument = BILL_FIELDS['scenario_names'][:argument]
    sampling_region = args[scenario_names_argument].include?('Sampling Region')
    if sampling_region
      expansion = expand_sampling_region(args)
      return result(error: expansion[:error]) unless expansion[:error].nil?

      args = expansion[:args]
    end

    scenario_names = args[scenario_names_argument].split(',').map(&:strip)
    simple_filepaths = split_argument(args[BILL_FIELDS['simple_filepaths'][:argument]])
    detailed_filepaths = split_argument(args[BILL_FIELDS['detailed_filepaths'][:argument]])
    num_scenarios = scenario_names.size
    utility_bill = {}
    BILL_FIELDS.each do |field_name, field|
      next unless field.key?(:rate_field)

      if field[:argument].nil?
        utility_bill[field_name] = [nil] * num_scenarios
      else
        utility_bill[field_name] = args[field[:argument]].split(',').map(&:strip)
      end
    end

    warnings = []
    num_scenarios.times do |index|
      simple_filepath = simple_filepaths[index]
      detailed_filepath = detailed_filepaths[index]
      next unless present?(simple_filepath) || present?(detailed_filepath)

      if present?(simple_filepath)
        full_filepath = File.join(@resources_dir, simple_filepath)
        lookup_data = @bldg_data
        if sampling_region && Constants::StateCodesMap.key?(scenario_names[index])
          lookup_data = @bldg_data.merge('State' => scenario_names[index])
        end
      else
        full_filepath = File.join(@resources_dir, detailed_filepath)
        lookup_data = @bldg_data
      end

      rate, error, rate_warnings = get_utility_rate(full_filepath, lookup_data)
      return result(error: error) unless error.nil?

      warnings.concat(rate_warnings)
      if present?(detailed_filepath) && !present?(simple_filepath) && !rate['elec_filepath'].nil?
        rate['elec_filepath'] = File.join(File.dirname(full_filepath), rate['elec_filepath'])
      end

      BILL_FIELDS.each do |field_name, field|
        next unless field.key?(:rate_field)

        utility_bill[field_name][index] = rate[field[:rate_field]]
      end
    end

    output_values = {}
    BILL_FIELDS.each do |field_name, field|
      full_argument_name = "utility_bill_#{field_name}"
      next if field[:include_in_outputs] == false

      if field.key?(:rate_field)
        value = utility_bill[field_name].join(',')
      else
        value = args[field[:argument]]
      end

      output_values[full_argument_name] = value
    end
    result(measure_arguments: output_values, registered_values: output_values.dup, warnings: warnings)
  end

  private

  # Packages generated values and diagnostics in the common scenario result shape.
  # @param measure_arguments [Hash] Arguments for ResStockArgumentsPostHPXML
  # @param registered_values [Hash] Values exposed to downstream measures
  # @param warnings [Array<String>] Non-fatal rate lookup warnings
  # @param error [String, nil] Fatal scenario error, if any
  # @return [Hash] Scenario result
  def result(measure_arguments: {}, registered_values: {}, warnings: [], error: nil)
    { measure_arguments: measure_arguments, registered_values: registered_values, warnings: warnings, error: error }
  end

  # Splits a comma-separated argument while preserving blank entries.
  # @param value [String, nil] Argument value
  # @return [Array<String>] Stripped argument entries
  def split_argument(value)
    return [] if value.nil?

    value.split(',').map(&:strip)
  end

  # Returns whether a filepath was supplied.
  # @param value [String, nil] Filepath value
  # @return [Boolean] Whether the value is non-empty
  def present?(value)
    !value.nil? && !value.empty?
  end

  # Replaces the Sampling Region bill scenario with one scenario per included state.
  # @param args [Hash] Original utility-bill arguments
  # @return [Hash] { args: expanded_args, error: nil } on success, or { error: message } on failure
  def expand_sampling_region(args)
    scenario_names_argument = BILL_FIELDS['scenario_names'][:argument]
    simple_filepaths_argument = BILL_FIELDS['simple_filepaths'][:argument]
    scenario_names = args[scenario_names_argument].split(',').map(&:strip)
    simple_filepaths = split_argument(args[simple_filepaths_argument])
    index = scenario_names.index('Sampling Region')
    unless !index.nil? && File.basename(simple_filepaths[index].to_s) == 'State.tsv'
      return { error: "Using 'Sampling Region' bill calculation approach, but specified filepath is not /path/to/State.tsv." }
    end

    simple_filepath = simple_filepaths.delete_at(index)
    scenario_names.delete_at(index)
    statecodes, error = get_statecodes_for_sampling_region
    return { error: error } unless error.nil?

    args = args.dup
    args[scenario_names_argument] = (scenario_names + statecodes).join(',')
    args[simple_filepaths_argument] = (simple_filepaths + [simple_filepath] * statecodes.size).join(',')
    { args: args, error: nil }
  end

  # Returns the sorted state codes represented by the sampled region.
  # @return [Array] Two values: sorted state codes and nil, or an empty array and an error message
  def get_statecodes_for_sampling_region
    parameter = 'Sampling Region'
    return [[], "Utility bill scenario(s) were specified, but could not find #{parameter}."] unless @bldg_data.key?(parameter)

    filepath = File.join(@characteristics_dir, "#{parameter}.tsv")
    rows = CSV.read(filepath, headers: true, col_sep: "\t")
    option_col = "Option=#{@bldg_data[parameter]}"
    statecodes = rows.each_with_object([]) do |row, codes|
      next unless row[option_col].to_s.strip == '1'

      statecode = row['Dependency=County'].to_s.split(',', 2).first.to_s.strip
      codes << statecode if statecode.match?(/\A[A-Z]{2}\z/)
    end
    return [statecodes.uniq.sort, nil]
  end

  # Selects the row matching the building data from a simple or detailed rate file.
  # @param filepath [String] Rate TSV path
  # @param bldg_data [Hash] Building characteristics used to select a row
  # @return [Array] Rate row, error message, and any lookup warnings
  def get_utility_rate(filepath, bldg_data)
    return [{}, "Utility bill scenario file '#{filepath}' does not exist.", []] unless File.exist?(filepath)

    rows = CSV.read(filepath, headers: true, col_sep: "\t")
    parameter = rows.headers.first
    return [{}, "Utility bill scenario(s) were specified, but could not find #{parameter}.", []] unless bldg_data.key?(parameter)

    rates = rows.select { |row| row[parameter] == bldg_data[parameter] }
    unless rates.size == 1
      warning = "Could not find #{parameter}=#{bldg_data[parameter]} in #{filepath}."
      empty_rate = rows.headers.to_h { |header| [header, nil] }
      return [empty_rate, nil, [warning]]
    end
    return [rates.first.to_h, nil, []]
  end
end
