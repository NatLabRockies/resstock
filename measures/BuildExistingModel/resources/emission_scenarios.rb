# frozen_string_literal: true

require 'csv'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'

class EmissionScenarios
  # Maps output fields to input arguments or derived values; include_in_outputs: false omits lookup-only fields.
  EMISSIONS_FIELDS = {
    'scenario_names' => { argument: :emissions_scenario_names },
    'types' => { argument: :emissions_types },
    'electricity_folders' => { argument: :emissions_electricity_folders, include_in_outputs: false },
    'natural_gas_values' => { argument: :emissions_natural_gas_values },
    'propane_values' => { argument: :emissions_propane_values },
    'fuel_oil_values' => { argument: :emissions_fuel_oil_values },
    'wood_values' => { argument: :emissions_wood_values },
    'electricity_units' => { derived: true },
    'electricity_filepaths' => { derived: true },
    'fossil_fuel_units' => { derived: true }
  }.freeze

  # Creates a processor for the emissions arguments and one building's data.
  # @param args [Hash] BuildExistingModel emissions arguments
  # @param bldg_data [Hash] Sampled building characteristics
  # @param resources_dir [String] Root directory for ResStock resources
  # @param characteristics_dir [String] Project housing characteristics directory
  def initialize(args, bldg_data, resources_dir, characteristics_dir)
    @args = args
    @bldg_data = bldg_data
    @resources_dir = resources_dir
    @characteristics_dir = characteristics_dir
  end

  # Expands Sampling Region scenarios and prepares measure and runner values.
  # @return [Hash] Measure arguments, registered values, warnings, or an error
  def build
    return result(error: 'Emissions scenario(s) were specified, but could not find the Generation and Emissions Assessment (GEA) region.') unless @bldg_data.key?('Generation And Emissions Assessment Region')

    args = @args.dup
    scenario_names_argument = EMISSIONS_FIELDS['scenario_names'][:argument]
    scenario_names = args[scenario_names_argument].split(',', -1).map(&:strip)
    scenario_gea_regions = Array.new(scenario_names.size)
    if scenario_names.any? { |scenario_name| scenario_name.end_with?('Sampling Region') }
      gea_regions, error = get_gearegions_for_sampling_region
      return result(error: error) unless error.nil?

      args, scenario_gea_regions = expand_scenarios(args, gea_regions)
    end

    scenarios = args[:emissions_electricity_folders].split(',')
    electricity_filepaths = []
    scenarios.each_with_index do |scenario, i|
      scenario_path = File.join(@resources_dir, scenario)
      return result(error: "Emissions scenario electricity folder '#{scenario_path}' does not exist.") unless File.exist?(scenario_path)

      gea_region = scenario_gea_regions[i] || @bldg_data['Generation And Emissions Assessment Region']
      Dir[File.join(scenario_path, '*.csv')].each do |filepath|
        electricity_filepaths << filepath if File.basename(filepath, '.csv') == gea_region
      end
    end

    if scenarios.empty?
      return result(warnings: ['Not calculating emissions because no emissions scenarios remain after Sampling Region expansion.'])
    end
    if electricity_filepaths.size != scenarios.size
      return result(warnings: ['Not calculating emissions because an electricity filepath for at least one emissions scenario could not be located.'])
    end

    electricity_filepaths = electricity_filepaths.join(',')
    output_values = {}
    EMISSIONS_FIELDS.each do |field_name, field|
      argument_name = "emissions_#{field_name}"
      next if field[:include_in_outputs] == false

      if field[:derived]
        case field_name
        when 'electricity_units'
          value = ([::HPXML::EmissionsScenario::UnitsKgPerMWh] * scenarios.size).join(',')
        when 'electricity_filepaths'
          value = electricity_filepaths
        when 'fossil_fuel_units'
          value = ([::HPXML::EmissionsScenario::UnitsLbPerMBtu] * scenarios.size).join(',')
        end
      else
        value = args[field[:argument]]
      end
      output_values[argument_name] = value
    end
    result(measure_arguments: output_values, registered_values: output_values.dup)
  end

  private

  # Packages generated values and diagnostics in the common scenario result shape.
  # @param measure_arguments [Hash] Arguments for ResStockArgumentsPostHPXML
  # @param registered_values [Hash] Values exposed to downstream measures
  # @param warnings [Array<String>] Non-fatal scenario warnings
  # @param error [String, nil] Fatal scenario error, if any
  # @return [Hash] Scenario result
  def result(measure_arguments: {}, registered_values: {}, warnings: [], error: nil)
    { measure_arguments: measure_arguments, registered_values: registered_values, warnings: warnings, error: error }
  end

  # Duplicates parallel scenario values and names each expansion by GEA region.
  # @param args [Hash] Original comma-separated emissions arguments
  # @param gea_regions [Array<String>] GEA regions represented by the sampling region
  # @return [Array] Two values: expanded arguments and per-scenario GEA regions (nil for unexpanded scenarios)
  def expand_scenarios(args, gea_regions)
    emissions_arguments = EMISSIONS_FIELDS.values.filter_map { |field| field[:argument] }
    scenario_names_argument = EMISSIONS_FIELDS['scenario_names'][:argument]
    split_args = emissions_arguments.to_h do |arg|
      [arg, args[arg].nil? ? nil : args[arg].split(',', -1).map(&:strip)]
    end
    new_args = emissions_arguments.to_h { |arg| [arg, []] }
    scenario_gea_regions = []

    split_args[scenario_names_argument].each_with_index do |scenario_name, i|
      if scenario_name.end_with?('Sampling Region')
        prefix = scenario_name.delete_suffix('Sampling Region').strip.delete_suffix('-').strip
        gea_regions.each do |gea_region|
          emissions_arguments.each do |arg|
            next if split_args[arg].nil?

            new_args[arg] << (arg == scenario_names_argument ? [prefix, gea_region].reject(&:empty?).join(' - ') : split_args[arg][i])
          end
          scenario_gea_regions << gea_region
        end
      else
        emissions_arguments.each do |arg|
          new_args[arg] << split_args[arg][i] unless split_args[arg].nil?
        end
        scenario_gea_regions << nil
      end
    end

    expanded_args = emissions_arguments.each_with_object(args.dup) do |arg, expanded|
      expanded[arg] = new_args[arg].join(',') unless split_args[arg].nil?
    end
    return expanded_args, scenario_gea_regions
  end

  # Finds sorted GEA regions among sampled counties, excluding regions without emissions data.
  # @return [Array] Two values: sorted GEA regions and nil, or an empty array and an error message
  def get_gearegions_for_sampling_region
    parameter = 'Sampling Region'
    return [[], "Emissions scenario(s) were specified, but could not find #{parameter}."] unless @bldg_data.key?(parameter)

    rows = CSV.read(File.join(@characteristics_dir, "#{parameter}.tsv"), headers: true, col_sep: "\t")
    option_col = "Option=#{@bldg_data[parameter]}"
    counties = rows.select { |row| row[option_col].to_s.strip == '1' }.map { |row| row['Dependency=County'].to_s.strip }.to_h { |county| [county, true] }

    gea_filepath = File.join(@characteristics_dir, 'Generation And Emissions Assessment Region.tsv')
    rows = CSV.read(gea_filepath, headers: true, col_sep: "\t")
    option_cols = rows.headers.select { |header| header.to_s.start_with?('Option=') }
    gea_regions = rows.each_with_object([]) do |row, regions|
      next unless counties.key?(row['Dependency=County'].to_s.strip)

      option_cols.each do |col|
        next unless row[col].to_f > 0

        gea_region = col.delete_prefix('Option=')
        regions << gea_region unless gea_region == 'None'
      end
    end
    return [gea_regions.uniq.sort, nil]
  end
end
