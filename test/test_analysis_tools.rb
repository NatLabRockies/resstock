# frozen_string_literal: true

require_relative '../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'csv'

class TestTools < Minitest::Test
  def before_setup
    @buildstock_directory = File.join(File.dirname(__FILE__), '..')
  end

  def test_baseline_columns
    ['national', 'testing'].each do |project|
      buildstockbatch_path = File.join(@buildstock_directory, "buildstockbatch/project_#{project}/#{project}_baseline/results_csvs/results_up00.csv")
      buildstockbatch = CSV.read(buildstockbatch_path, headers: true)

      run_analysis_path = File.join(@buildstock_directory, "run_analysis/project_#{project}/#{project}_baseline/results-Baseline.csv")
      run_analysis = CSV.read(run_analysis_path, headers: true)

      buildstockbatch_extras = buildstockbatch.headers - run_analysis.headers
      buildstockbatch_extras -= ['apply_upgrade.applicable']
      buildstockbatch_extras -= ['apply_upgrade.upgrade_name']
      buildstockbatch_extras -= ['apply_upgrade.reference_scenario']
      puts "#{project}_baseline, buildstockbatch - run_analysis: #{buildstockbatch_extras}" if !buildstockbatch_extras.empty?

      run_analysis_extras = run_analysis.headers - buildstockbatch.headers
      puts "#{project}_baseline, run_analysis - buildstockbatch: #{run_analysis_extras}" if !run_analysis_extras.empty?

      assert_equal(0, buildstockbatch_extras.size)
      assert_equal(0, run_analysis_extras.size)
    end
  end

  def test_baseline_results
    columns = ['report_simulation_output.energy_use_total_m_btu']

    ['national', 'testing'].each do |project|
      buildstockbatch_path = File.join(@buildstock_directory, "buildstockbatch/project_#{project}/#{project}_baseline/results_csvs/results_up00.csv")
      buildstockbatch = CSV.read(buildstockbatch_path, headers: true)

      run_analysis_path = File.join(@buildstock_directory, "run_analysis/project_#{project}/#{project}_baseline/results-Baseline.csv")
      run_analysis = CSV.read(run_analysis_path, headers: true)

      columns.each do |col|
        buildstockbatch_sum = buildstockbatch[col].map { |v| Float(v) }.sum
        run_analysis_sum = run_analysis[col].map { |v| Float(v) }.sum

        assert_equal(buildstockbatch[col].size, run_analysis[col].size)
        assert_in_epsilon(buildstockbatch_sum, run_analysis_sum, 0.01)
      end
    end
  end
end
