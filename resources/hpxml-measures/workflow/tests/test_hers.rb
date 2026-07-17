# frozen_string_literal: true

require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'fileutils'
require 'parallel'
require 'csv'
require_relative '../../HPXMLtoOpenStudio/measure.rb'
require_relative 'util.rb'

class WorkflowHERSTest < Minitest::Test
  def test_hers_hvac
    results_dir = File.join(File.dirname(__FILE__), 'test_results')
    FileUtils.mkdir_p results_dir

    test_results_csv = File.join(results_dir, 'results_hers_hvac.csv')
    File.delete(test_results_csv) if File.exist? test_results_csv

    xmls = []
    hers_hvac_dir = File.absolute_path(File.join(File.dirname(__FILE__), 'HERS_HVAC'))
    Dir["#{hers_hvac_dir}/*.xml"].sort.each do |xml|
      xmls << File.absolute_path(xml)
    end
    all_results = run_simulation_tests(xmls)

    hvac_results = {}
    all_results.each do |xml, results|
      is_heat = false
      if xml.include? 'HVAC2'
        is_heat = true
      end
      is_electric_heat = true
      if xml.include?('HVAC2a') || xml.include?('HVAC2b')
        is_electric_heat = false
      end
      hvac_results[xml] = _get_simulation_hvac_energy_results(results, is_heat, is_electric_heat)
    end

    hvac_energy = _write_hers_hvac_results(hvac_results, test_results_csv)

    # Check results
    _check_hvac_test_results(hvac_energy)
  end

  def test_hers_dse
    results_dir = File.join(File.dirname(__FILE__), 'test_results')
    FileUtils.mkdir_p results_dir

    test_results_csv = File.join(results_dir, 'results_hers_dse.csv')
    File.delete(test_results_csv) if File.exist? test_results_csv

    xmls = []
    hers_dse_dir = File.absolute_path(File.join(File.dirname(__FILE__), 'HERS_DSE'))
    Dir["#{hers_dse_dir}/*.xml"].sort.each do |xml|
      xmls << File.absolute_path(xml)
    end
    all_results = run_simulation_tests(xmls)

    dse_results = {}
    all_results.each do |xml, results|
      is_heat = false
      if ['HVAC3a.xml', 'HVAC3b.xml', 'HVAC3c.xml', 'HVAC3d.xml'].include? File.basename(xml)
        is_heat = true
      end
      is_electric_heat = false
      dse_results[xml] = _get_simulation_hvac_energy_results(results, is_heat, is_electric_heat)
    end

    dse_energy = _write_hers_dse_results(dse_results, test_results_csv)

    # Check results
    _check_dse_test_results(dse_energy)
  end

  def test_hers_hot_water
    results_dir = File.join(File.dirname(__FILE__), 'test_results')
    FileUtils.mkdir_p results_dir

    test_results_csv = File.join(results_dir, 'results_hers_hot_water.csv')
    File.delete(test_results_csv) if File.exist? test_results_csv

    xmls = []
    hers_hot_water_dir = File.absolute_path(File.join(File.dirname(__FILE__), 'HERS_Hot_Water'))
    Dir["#{hers_hot_water_dir}/*.xml"].sort.each do |xml|
      xmls << File.absolute_path(xml)
    end
    all_results = run_simulation_tests(xmls)

    dhw_results = {}
    all_results.each do |xml, results|
      dhw_results[xml] = _get_simulation_hot_water_results(results)
    end

    dhw_energy = _write_hers_hot_water_results(dhw_results, test_results_csv)

    # Check results
    _check_hot_water(dhw_energy)
  end
end
