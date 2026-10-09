# frozen_string_literal: true

require 'csv'
require 'openstudio'
require 'tmpdir'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../measure'

class BuildExistingModelTest < Minitest::Test
  def setup
    @measure = BuildExistingModel.new
  end

  # Verifies multi-GEA expansion, alignment of mixed scenarios, and registered emissions values.
  def test_emissions_sampling_region
    require_relative '../../ApplyUpgrade/measure'

    Dir.mktmpdir do |root|
      resources_dir = File.join(root, 'resources')
      characteristics_dir = File.join(root, 'housing_characteristics')
      create_emissions_resources(resources_dir)
      create_sampling_region_characteristics(characteristics_dir)
      create_gea_region_characteristics(characteristics_dir)

      args = {
        emissions_scenario_names: 'LRMER_MidCase_15 - Sampling Region,Baseline,Peak - Sampling Region',
        emissions_types: 'CO2e,CO2e,NOx',
        emissions_electricity_folders: 'data/lrmer,data/baseline,data/peak',
        emissions_natural_gas_values: '1,2,3',
        emissions_propane_values: '',
        emissions_fuel_oil_values: '',
        emissions_wood_values: ''
      }
      bldg_data = {
        'Sampling Region' => '1',
        'Generation And Emissions Assessment Region' => 'MISO Central'
      }

      result = EmissionScenarios.new(args, bldg_data, resources_dir, characteristics_dir).build

      assert_nil result[:error]
      assert_empty result[:warnings]
      assert_equal 'LRMER_MidCase_15 - MISO Central,LRMER_MidCase_15 - MISO South,Baseline,Peak - MISO Central,Peak - MISO South',
                   result[:measure_arguments]['emissions_scenario_names']
      assert_equal 'CO2e,CO2e,CO2e,NOx,NOx', result[:measure_arguments]['emissions_types']
      assert_equal '1,1,2,3,3', result[:measure_arguments]['emissions_natural_gas_values']
      refute_includes result[:registered_values].keys, 'emissions_electricity_folders'
      assert_equal ['MISO Central.csv', 'MISO South.csv', 'MISO Central.csv', 'MISO Central.csv', 'MISO South.csv'],
                   result[:measure_arguments]['emissions_electricity_filepaths'].split(',').map { |filepath| File.basename(filepath) }

      runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
      measure_arguments = {}
      assert(@measure.apply_scenario_result(result, runner, measure_arguments))
      registered_values = runner.result.stepValues.to_h do |step_value|
        [step_value.name, get_value_from_workflow_step_value(step_value)]
      end
      assert_equal result[:registered_values]['emissions_scenario_names'], registered_values['emissions_scenario_names']
      assert_equal result[:registered_values]['emissions_electricity_filepaths'], registered_values['emissions_electricity_filepaths']
      assert_equal result[:measure_arguments], measure_arguments

      values = args.transform_keys(&:to_s).merge(registered_values)
      upgrade_measures = { 'BuildResidentialHPXML' => [{}], 'ResStockArgumentsPostHPXML' => [{}] }
      ApplyUpgrade.new.set_header(upgrade_measures, HPXML.new, values)
      upgrade_arguments = upgrade_measures['ResStockArgumentsPostHPXML'][0]
      refute upgrade_arguments.key?('emissions_electricity_folders')
      result[:measure_arguments].each do |argument, value|
        next if value.nil?

        assert_equal value, upgrade_arguments[argument]
      end
    end
  end

  def test_emissions_sampling_region_electricity_values
    Dir.mktmpdir do |root|
      resources_dir = File.join(root, 'resources')
      characteristics_dir = File.join(root, 'housing_characteristics')
      create_emissions_resources(resources_dir)
      create_sampling_region_characteristics(characteristics_dir)
      create_gea_region_characteristics(characteristics_dir)
      FileUtils.rm(File.join(resources_dir, 'data', 'lrmer', 'MISO South.csv'))

      args = {
        emissions_scenario_names: 'Fixed - Sampling Region,Schedule - Sampling Region,Zero',
        emissions_types: 'CO2e,NOx,CO2e',
        emissions_electricity_folders: ',data/lrmer,',
        emissions_electricity_values: '392.6,,0.0',
        emissions_natural_gas_values: '1,2,3'
      }
      result = EmissionScenarios.new(args, { 'Sampling Region' => '1' }, resources_dir, characteristics_dir).build

      assert_nil result[:error]
      assert_equal ["Not calculating emissions for scenario 'Schedule - MISO South' because an electricity filepath could not be located."], result[:warnings]
      output = result[:measure_arguments]
      assert_equal 'Fixed - MISO Central,Fixed - MISO South,Schedule - MISO Central,Zero', output['emissions_scenario_names']
      assert_equal 'CO2e,CO2e,NOx,CO2e', output['emissions_types']
      assert_equal '392.6,392.6,,0.0', output['emissions_electricity_values']
      assert_equal '1,1,2,3', output['emissions_natural_gas_values']
      assert_equal 'kg/MWh,kg/MWh,kg/MWh,kg/MWh', output['emissions_electricity_units']
      assert_equal ['', '', File.join(resources_dir, 'data', 'lrmer', 'MISO Central.csv'), ''], output['emissions_electricity_filepaths'].split(',', -1)
      assert_equal output, result[:registered_values]
      assert_equal '392.6,,0.0', args[:emissions_electricity_values]
    end
  end

  # Verifies state expansion, state-specific rate lookup, and registration of resolved values only.
  def test_utility_bill_sampling_region
    require_relative '../../ApplyUpgrade/measure'

    Dir.mktmpdir do |root|
      resources_dir = File.join(root, 'resources')
      characteristics_dir = File.join(root, 'housing_characteristics')
      rates_dir = File.join(resources_dir, 'rates')
      FileUtils.mkdir_p(rates_dir)
      create_sampling_region_characteristics(characteristics_dir)
      create_utility_rate_file(File.join(rates_dir, 'State.tsv'), [
                                 ['CA', 'CA.csv', 'CA fixed'],
                                 ['HI', 'HI.csv', 'HI fixed'],
                                 ['NV', 'NV.csv', 'NV fixed']
                               ])
      create_utility_rate_file(File.join(rates_dir, 'Flat.tsv'), [['CA', 'Flat.csv', 'Flat fixed']])

      args = {
        utility_bill_scenario_names: 'Sampling Region,Flat,Inline',
        utility_bill_simple_filepaths: 'rates/State.tsv,rates/Flat.tsv,',
        utility_bill_detailed_filepaths: ''
      }
      UtilityBillScenarios::BILL_FIELDS.each_value do |field|
        args[field[:argument]] = '0,0,0' if field.key?(:rate_field) && !field[:argument].nil?
      end
      args[:utility_bill_electricity_fixed_charges] = '10,20,30'

      result = UtilityBillScenarios.new(args, { 'State' => 'CA', 'Sampling Region' => '1' }, resources_dir, characteristics_dir).build

      assert_nil result[:error]
      assert_empty result[:warnings]
      assert_equal 'Flat,Inline,CA,HI,NV', result[:measure_arguments]['utility_bill_scenario_names']
      refute_includes result[:registered_values].keys, 'utility_bill_simple_filepaths'
      refute_includes result[:registered_values].keys, 'utility_bill_detailed_filepaths'
      assert_equal 'Flat fixed,30,CA fixed,HI fixed,NV fixed', result[:measure_arguments]['utility_bill_electricity_fixed_charges']
      assert_equal 'Flat.csv,,CA.csv,HI.csv,NV.csv', result[:measure_arguments]['utility_bill_electricity_filepaths']

      runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
      measure_arguments = {}
      assert(@measure.apply_scenario_result(result, runner, measure_arguments))
      registered_values = runner.result.stepValues.to_h do |step_value|
        [step_value.name, get_value_from_workflow_step_value(step_value)]
      end
      assert_equal result[:registered_values]['utility_bill_scenario_names'], registered_values['utility_bill_scenario_names']
      assert_equal result[:registered_values]['utility_bill_electricity_filepaths'], registered_values['utility_bill_electricity_filepaths']
      assert_equal result[:registered_values]['utility_bill_electricity_fixed_charges'], registered_values['utility_bill_electricity_fixed_charges']
      assert_equal result[:measure_arguments], measure_arguments
      refute_includes registered_values.keys, 'utility_bill_simple_filepaths'
      refute_includes registered_values.keys, 'utility_bill_detailed_filepaths'

      values = args.transform_keys(&:to_s).merge(registered_values)
      upgrade_measures = { 'BuildResidentialHPXML' => [{}], 'ResStockArgumentsPostHPXML' => [{}] }
      ApplyUpgrade.new.set_header(upgrade_measures, HPXML.new, values)
      upgrade_arguments = upgrade_measures['ResStockArgumentsPostHPXML'][0]
      refute upgrade_arguments.key?('utility_bill_simple_filepaths')
      refute upgrade_arguments.key?('utility_bill_detailed_filepaths')
      result[:measure_arguments].each do |argument, value|
        assert_equal value, upgrade_arguments[argument]
      end
    end
  end

  private

  def create_emissions_resources(resources_dir)
    %w[lrmer baseline peak].each do |scenario|
      scenario_dir = File.join(resources_dir, 'data', scenario)
      FileUtils.mkdir_p(scenario_dir)
      ['MISO Central', 'MISO South'].each do |region|
        File.write(File.join(scenario_dir, "#{region}.csv"), '')
      end
    end
  end

  def create_sampling_region_characteristics(characteristics_dir)
    FileUtils.mkdir_p(characteristics_dir)
    CSV.open(File.join(characteristics_dir, 'Sampling Region.tsv'), 'w', col_sep: "\t") do |csv|
      csv << ['Dependency=County', 'Option=1']
      csv << ['CA, Alpha County', '1']
      csv << ['NV, Beta County', '1']
      csv << ['HI, Honolulu County', '1']
      csv << ['OR, Not Selected County', '0']
    end
  end

  def create_gea_region_characteristics(characteristics_dir)
    CSV.open(File.join(characteristics_dir, 'Generation And Emissions Assessment Region.tsv'), 'w', col_sep: "\t") do |csv|
      csv << ['Dependency=County', 'Option=MISO Central', 'Option=MISO South', 'Option=None']
      csv << ['CA, Alpha County', '1', '0', '0']
      csv << ['NV, Beta County', '0', '1', '0']
      csv << ['HI, Honolulu County', '0', '0', '1']
      csv << ['OR, Not Selected County', '1', '0', '0']
    end
  end

  def create_utility_rate_file(filepath, rate_rows)
    CSV.open(filepath, 'w', col_sep: "\t") do |csv|
      csv << ['State', 'elec_filepath', 'elec_fixed_charge']
      rate_rows.each { |row| csv << row }
    end
  end
end
