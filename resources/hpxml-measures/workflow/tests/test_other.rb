# frozen_string_literal: true

require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'fileutils'
require 'parallel'
require_relative '../../HPXMLtoOpenStudio/measure.rb'
require_relative 'util.rb'

class WorkflowOtherTest < Minitest::Test
  def test_run_simulation_output_formats
    # Check that the simulation produces outputs in the appropriate format
    ['csv', 'json', 'msgpack', 'csv_dview'].each do |output_format|
      rb_path = File.join(File.dirname(__FILE__), '..', 'run_simulation.rb')
      xml = File.join(File.dirname(__FILE__), '..', 'sample_files', 'base.xml')
      command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{rb_path}\" -x \"#{xml}\" --debug --hourly ALL --output-format #{output_format}"
      system(command, err: File::NULL)

      output_format = 'csv' if output_format == 'csv_dview'

      # Check for output files
      run_dir = File.join(File.dirname(xml), 'run')
      assert(File.exist? File.join(run_dir, 'eplusout.msgpack')) # Produced because --debug flag if used
      assert(File.exist? File.join(run_dir, "results_annual.#{output_format}"))
      assert(File.exist? File.join(run_dir, "results_timeseries.#{output_format}"))
      assert(File.exist?(File.join(run_dir, "results_bills.#{output_format}")))
      assert(File.exist?(File.join(run_dir, "results_design_load_details.#{output_format}")))

      # Check for debug files
      osm_path = File.join(run_dir, 'in.osm')
      assert(File.exist? osm_path)
      hpxml_defaults_path = File.join(run_dir, 'in.xml')
      assert(File.exist? hpxml_defaults_path)

      next unless output_format == 'msgpack'

      # Check timeseries output isn't rounded
      require 'msgpack'
      data = MessagePack.unpack(File.read(File.join(run_dir, "results_timeseries.#{output_format}"), mode: 'rb'))
      value = data['Energy Use']['Total (kBtu)'][0]
      assert_operator((value - value.round(8)).abs, :>, 0)
    end
  end

  def test_run_simulation_epjson_input
    # Check that we can run a simulation using epJSON (instead of IDF) if requested
    rb_path = File.join(File.dirname(__FILE__), '..', 'run_simulation.rb')
    xml = File.join(File.dirname(__FILE__), '..', 'sample_files', 'base.xml')
    command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{rb_path}\" -x \"#{xml}\" --ep-input-format epjson"
    system(command, err: File::NULL)

    # Check for epjson file
    run_dir = File.join(File.dirname(xml), 'run')
    assert(File.exist? File.join(run_dir, 'in.epJSON'))

    # Check for output files
    assert(File.exist? File.join(run_dir, 'results_annual.csv'))

    # Check for no E+ msgpack files
    refute(File.exist? File.join(run_dir, 'eplusout.msgpack'))
  end

  def test_run_simulation_idf_input
    # Check that we can run a simulation using IDF (instead of epJSON) if requested
    rb_path = File.join(File.dirname(__FILE__), '..', 'run_simulation.rb')
    xml = File.join(File.dirname(__FILE__), '..', 'sample_files', 'base.xml')
    command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{rb_path}\" -x \"#{xml}\" --ep-input-format idf"
    system(command, err: File::NULL)

    # Check for idf file
    run_dir = File.join(File.dirname(xml), 'run')
    assert(File.exist? File.join(run_dir, 'in.idf'))

    # Check for output files
    assert(File.exist? File.join(run_dir, 'results_annual.csv'))

    # Check for no E+ msgpack files
    refute(File.exist? File.join(run_dir, 'eplusout.msgpack'))
  end

  def test_run_simulation_faster_performance
    # Run w/ --skip-validation and w/o --add-component-loads arguments
    rb_path = File.join(File.dirname(__FILE__), '..', 'run_simulation.rb')
    xml = File.join(File.dirname(__FILE__), '..', 'sample_files', 'base.xml')
    command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{rb_path}\" -x \"#{xml}\" --skip-validation"
    system(command, err: File::NULL)

    # Check for output files
    run_dir = File.join(File.dirname(xml), 'run')
    assert(File.exist? File.join(run_dir, 'results_annual.csv'))

    # Check for no E+ msgpack files
    refute(File.exist? File.join(run_dir, 'eplusout.msgpack'))

    # Check component loads don't exist
    component_loads = {}
    CSV.read(File.join(run_dir, 'results_annual.csv'), headers: false).each do |data|
      next unless data[0].to_s.start_with? 'Component Load'

      component_loads[data[0]] = Float(data[1])
    end
    assert_equal(0, component_loads.size)
  end

  def test_run_simulation_stochastic_occupancy_schedules
    hpxml_names = ['base-schedules-simple.xml',
                   'base-misc-loads-large-uncommon.xml',
                   'base-misc-loads-large-uncommon2.xml',
                   'base-lighting-ceiling-fans.xml']

    hpxml_names.each do |hpxml_name|
      [false, true].each do |debug|
        # Check that the simulation produces stochastic schedules if requested
        sample_files_path = File.join(File.dirname(__FILE__), '..', 'sample_files')
        tmp_hpxml_path = File.join(sample_files_path, 'tmp.xml')
        hpxml = HPXML.new(hpxml_path: File.join(sample_files_path, hpxml_name))
        XMLHelper.write_file(hpxml.to_doc, tmp_hpxml_path)

        rb_path = File.join(File.dirname(__FILE__), '..', 'run_simulation.rb')
        xml = File.absolute_path(tmp_hpxml_path)
        command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{rb_path}\" -x \"#{xml}\" --add-stochastic-schedules"
        command += ' -d' if debug
        system(command, err: File::NULL)

        # Check for output files
        run_dir = File.join(File.dirname(xml), 'run')
        assert(File.exist? File.join(run_dir, 'results_annual.csv'))
        assert(File.exist? File.join(run_dir, 'in.schedules.csv'))
        assert(File.exist? File.join(run_dir, 'stochastic.csv'))

        # Check for E+ msgpack files
        if debug
          assert(File.exist? File.join(run_dir, 'eplusout.msgpack'))
        else
          refute(File.exist? File.join(run_dir, 'eplusout.msgpack'))
        end

        # Check stochastic.csv headers
        schedules = CSV.read(File.join(run_dir, 'stochastic.csv'), headers: true)
        if debug
          assert(schedules.headers.include?(SchedulesFile::Columns[:Sleeping].name))
        else
          refute(schedules.headers.include?(SchedulesFile::Columns[:Sleeping].name))
        end

        # Check run.log has no warnings about both simple and detailed schedules
        assert(File.exist? File.join(run_dir, 'run.log'))
        log_lines = File.readlines(File.join(run_dir, 'run.log')).map(&:strip)
        refute(log_lines.any? { |log_line| log_line.include?('will be ignored') })

        # Cleanup
        File.delete(tmp_hpxml_path) if File.exist? tmp_hpxml_path
      end
    end
  end

  def test_run_simulation_timeseries_outputs
    [true, false].each do |invalid_variable_only|
      # Check that the simulation produces timeseries with requested outputs
      rb_path = File.join(File.dirname(__FILE__), '..', 'run_simulation.rb')
      xml = File.join(File.dirname(__FILE__), '..', 'sample_files', 'base.xml')
      command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{rb_path}\" -x \"#{xml}\""
      if not invalid_variable_only
        command += ' --hourly ALL'
        command += " --hourly 'Zone People Occupant Count'"
        command += " --hourly 'Zone People Total Heating Energy'"
        command += " --hourly 'MainsWater:Facility'"
      end
      command += " --hourly 'Foobar Variable'" # Test invalid output variable request
      command += " --hourly 'Foobar:Meter'" # Test invalid output variable request
      system(command, err: File::NULL)

      # Check for output files
      run_dir = File.join(File.dirname(xml), 'run')
      assert(File.exist? File.join(run_dir, 'results_annual.csv'))

      # Check for no E+ msgpack files
      refute(File.exist? File.join(run_dir, 'eplusout.msgpack'))

      timeseries_output_path = File.join(run_dir, 'results_timeseries.csv')
      if not invalid_variable_only
        assert(File.exist? timeseries_output_path)
        # Check timeseries columns exist
        timeseries_rows = CSV.read(timeseries_output_path)
        assert_equal(1, timeseries_rows[0].count { |r| r == 'Time' })
        assert_equal(1, timeseries_rows[0].count { |r| r == 'Zone People Occupant Count: Conditioned Space' })
        assert_equal(1, timeseries_rows[0].count { |r| r == 'Zone People Total Heating Energy: Conditioned Space' })
        assert_equal(1, timeseries_rows[0].count { |r| r == 'MainsWater:Facility' })
      else
        refute(File.exist? timeseries_output_path)
      end

      # Check run.log has warning about missing Foobar Variable & Meter
      assert(File.exist? File.join(run_dir, 'run.log'))
      log_lines = File.readlines(File.join(run_dir, 'run.log')).map(&:strip)
      assert(log_lines.include? "Warning: Request for output variable 'Foobar Variable' returned no results.")
      assert(log_lines.include? "Warning: Request for output meter 'Foobar:Meter' returned no results.")
    end
  end

  def test_run_simulation_timeseries_outputs_comma
    # Check that the simulation produces timeseries with requested outputs
    rb_path = File.join(File.dirname(__FILE__), '..', 'run_simulation.rb')
    xml = File.join(File.dirname(__FILE__), '..', 'sample_files', 'base.xml')
    command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{rb_path}\" -x \"#{xml}\" --hourly 'Zone People Occupant Count,MainsWater:Facility'"
    success = system(command, err: File::NULL)

    refute(success)
  end

  def test_run_simulation_mixed_timeseries_frequencies
    # Check that we can correctly skip the EnergyPlus simulation and reporting measures
    rb_path = File.join(File.dirname(__FILE__), '..', 'run_simulation.rb')
    xml = File.join(File.dirname(__FILE__), '..', 'sample_files', 'base.xml')
    command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{rb_path}\" -x \"#{xml}\" --timestep weather --hourly enduses --daily temperatures --monthly ALL --monthly 'Zone People Total Heating Energy' --daily 'MainsWater:Facility'"
    system(command, err: File::NULL)

    # Check for output files
    run_dir = File.join(File.dirname(xml), 'run')
    assert(File.exist? File.join(run_dir, 'results_annual.csv'))
    assert(File.exist? File.join(run_dir, 'results_timeseries_timestep.csv'))
    assert(File.exist? File.join(run_dir, 'results_timeseries_hourly.csv'))
    assert(File.exist? File.join(run_dir, 'results_timeseries_daily.csv'))
    assert(File.exist? File.join(run_dir, 'results_timeseries_monthly.csv'))

    # Check for no E+ msgpack files
    refute(File.exist? File.join(run_dir, 'eplusout.msgpack'))

    # Check timeseries columns exist
    { 'timestep' => ['Weather:'],
      'hourly' => ['End Use:'],
      'daily' => ['Temperature:', 'MainsWater:Facility'],
      'monthly' => ['End Use:', 'Fuel Use:', 'Zone People Total Heating Energy:'] }.each do |freq, col_names|
      timeseries_rows = CSV.read(File.join(run_dir, "results_timeseries_#{freq}.csv"))
      assert_equal(1, timeseries_rows[0].count { |r| r == 'Time' })
      col_names.each do |col_name|
        assert(timeseries_rows[0].count { |r| r.start_with? col_name } > 0)
      end
    end
  end

  def test_run_simulation_skip_simulation
    # Check that we can correctly skip the EnergyPlus simulation and reporting measures
    rb_path = File.join(File.dirname(__FILE__), '..', 'run_simulation.rb')
    xml = File.join(File.dirname(__FILE__), '..', 'sample_files', 'base.xml')
    command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{rb_path}\" -x \"#{xml}\" --skip-simulation"
    system(command, err: File::NULL)

    # Check for in.xml HPXML file
    run_dir = File.join(File.dirname(xml), 'run')
    assert(File.exist? File.join(run_dir, 'in.xml'))

    # Check for annual results (design load/capacities only)
    assert(File.exist? File.join(run_dir, 'results_annual.csv'))

    # Check for no idf or output file
    refute(File.exist? File.join(run_dir, 'in.idf'))
    refute(File.exist? File.join(run_dir, 'eplusout.msgpack'))
  end

  def test_run_simulation_electric_panel_outputs
    # Check that the simulation produces electric panel only when requested

    # Run base.xml (no panel information or calculation types)
    rb_path = File.join(File.dirname(__FILE__), '..', 'run_simulation.rb')
    xml = File.join(File.dirname(__FILE__), '..', 'sample_files', 'base.xml')
    command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{rb_path}\" -x \"#{xml}\""
    system(command, err: File::NULL)

    # Check for output files
    run_dir = File.join(File.dirname(xml), 'run')
    refute(File.exist? File.join(run_dir, 'results_panel.csv'))

    # Run base-detailed-electric-panel-no-calculation-types.xml (panel information but no calculation types)
    xml = File.join(File.dirname(__FILE__), '..', 'sample_files', 'base-detailed-electric-panel-no-calculation-types.xml')
    command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{rb_path}\" -x \"#{xml}\""
    system(command, err: File::NULL)

    # Check for output files
    refute(File.exist? File.join(run_dir, 'results_panel.csv'))

    # Run base-detailed-electric-panel.xml (both panel information and calculation types)
    xml = File.join(File.dirname(__FILE__), '..', 'sample_files', 'base-detailed-electric-panel.xml')
    command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{rb_path}\" -x \"#{xml}\""
    system(command, err: File::NULL)

    # Check for output files
    assert(File.exist? File.join(run_dir, 'results_panel.csv'))
  end

  def test_run_defaulted_in_xml_with_hvac_installation_quality
    # Check that if we simulate the in.xml file (HPXML w/ defaults), we get
    # the same results as the original HPXML for a home with HVAC installation
    # defects.

    rb_path = File.join(File.dirname(__FILE__), '..', 'run_simulation.rb')
    sample_files_path = File.join(File.dirname(__FILE__), '..', 'sample_files')

    tmp_hpxml_path = File.join(sample_files_path, 'tmp.xml')
    hpxml = HPXML.new(hpxml_path: File.join(sample_files_path, 'base-hvac-install-quality-air-to-air-heat-pump-1-speed.xml'))
    hpxml.buildings[0].header.allow_increased_fixed_capacities = true
    hpxml.buildings[0].heat_pumps[0].heating_capacity /= 10.0
    hpxml.buildings[0].heat_pumps[0].cooling_capacity /= 10.0
    hpxml.buildings[0].heat_pumps[0].backup_heating_capacity /= 10.0
    hpxml.buildings[0].heat_pumps[0].heating_design_airflow_cfm /= 10.0
    hpxml.buildings[0].heat_pumps[0].cooling_design_airflow_cfm /= 10.0
    XMLHelper.write_file(hpxml.to_doc, tmp_hpxml_path)

    command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{rb_path}\" -x \"#{tmp_hpxml_path}\""
    system(command, err: File::NULL)

    run_dir = File.join(File.dirname(tmp_hpxml_path), 'run')
    assert(File.exist? File.join(run_dir, 'results_annual.csv'))
    base_results = CSV.read(File.join(run_dir, 'results_annual.csv'))

    # Run in.xml (generated from base.xml)
    in_xml = File.join(run_dir, 'in.xml')
    command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{rb_path}\" -x \"#{in_xml}\""
    system(command, err: File::NULL)

    run_dir = File.join(File.dirname(in_xml), 'run')
    assert(File.exist? File.join(run_dir, 'results_annual.csv'))
    default_results = CSV.read(File.join(run_dir, 'results_annual.csv'))

    # Check two output files are identical
    assert_equal(base_results, default_results)

    # Cleanup
    File.delete(tmp_hpxml_path) if File.exist? tmp_hpxml_path
  end

  def test_defrost_heating_loads
    # Check that if we simulate the heat pump with or without supplemental during defrost
    # we get the same heating load results

    # Run the test file without supplemental heat during defrost
    rb_path = File.join(File.dirname(__FILE__), '..', 'run_simulation.rb')
    xml = File.join(File.dirname(__FILE__), '..', 'sample_files', 'base-hvac-mini-split-heat-pump-ductless-backup-integrated.xml')
    command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{rb_path}\" -x \"#{xml}\""
    system(command, err: File::NULL)

    # Check for output files
    run_dir = File.join(File.dirname(xml), 'run')
    annual_output_path = File.join(run_dir, 'results_annual.csv')
    assert(File.exist? annual_output_path)
    result_rows = CSV.read(annual_output_path, headers: false)
    heating_loads_no_defrost_backup = Float(result_rows.find { |r| r[0].to_s.start_with? 'Load: Heating: Delivered' }[1]).round(2)
    supp_heat_loads_no_defrost_backup = Float(result_rows.find { |r| r[0].to_s.start_with? 'Load: Heating: Heat Pump Backup' }[1]).round(2)
    supp_heat_energy_no_defrost_backup = Float(result_rows.find { |r| r[0].to_s.start_with? 'End Use: Electricity: Heating Heat Pump Backup (' }[1]).round(2)

    # Run the test file with supplemental heat during defrost
    xml = File.join(File.dirname(__FILE__), '..', 'sample_files', 'base-hvac-mini-split-heat-pump-ductless-backup-integrated-defrost-with-backup-heat-active.xml')
    command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{rb_path}\" -x \"#{xml}\""
    system(command, err: File::NULL)

    # Check for output files
    run_dir = File.join(File.dirname(xml), 'run')
    annual_output_path = File.join(run_dir, 'results_annual.csv')
    assert(File.exist? annual_output_path)
    result_rows = CSV.read(annual_output_path, headers: false)
    heating_loads_with_defrost_backup = Float(result_rows.find { |r| r[0].to_s.start_with? 'Load: Heating: Delivered' }[1]).round(2)
    supp_heat_loads_with_defrost_backup = Float(result_rows.find { |r| r[0].to_s.start_with? 'Load: Heating: Heat Pump Backup' }[1]).round(2)
    supp_heat_energy_with_defrost_backup = Float(result_rows.find { |r| r[0].to_s.start_with? 'End Use: Electricity: Heating Heat Pump Backup (' }[1]).round(2)
    assert_equal(heating_loads_no_defrost_backup, heating_loads_with_defrost_backup)
    assert_equal(supp_heat_loads_no_defrost_backup, supp_heat_loads_with_defrost_backup)
    assert_operator(supp_heat_energy_with_defrost_backup, :>, supp_heat_energy_no_defrost_backup)
  end

  def test_template_osws
    # Check that simulations work using template-*.osw files
    require 'json'

    ['template-run-hpxml.osw',
     'template-run-hpxml-with-stochastic-occupancy.osw',
     'template-run-hpxml-with-stochastic-occupancy-subset.osw',
     'template-build-and-run-hpxml-with-stochastic-occupancy.osw',
     'template-build-hpxml.osw'].each do |osw_name|
      osw_path = File.join(File.dirname(__FILE__), '..', osw_name)

      skip_simulation = (osw_name == 'template-build-hpxml.osw')

      # Create derivative OSW for testing
      osw_path_test = osw_path.gsub('.osw', '_test.osw')
      FileUtils.cp(osw_path, osw_path_test)

      # Turn on debug mode
      json = JSON.parse(File.read(osw_path_test), symbolize_names: true)
      if not skip_simulation
        measure_index = json[:steps].find_index { |m| m[:measure_dir_name] == 'HPXMLtoOpenStudio' }
        json[:steps][measure_index][:arguments][:debug] = true
      end

      if Dir.exist? File.join(File.dirname(__FILE__), '..', '..', 'project')
        # CI checks out the repo as "project", so update dir name
        json[:steps][measure_index][:measure_dir_name] = 'project'
      end

      File.open(osw_path_test, 'w') do |f|
        f.write(JSON.pretty_generate(json))
      end

      cli_arg = ''
      if skip_simulation
        cli_arg = ' -m' # Run measures only
      end

      command = "\"#{OpenStudio.getOpenStudioCLI}\" run#{cli_arg} -w \"#{osw_path_test}\""
      system(command, err: File::NULL)

      run_dir = File.join(File.dirname(osw_path_test), 'run')

      # Check for output files
      assert(File.exist? File.join(run_dir, 'eplusout.msgpack')) unless skip_simulation
      assert(File.exist? File.join(run_dir, 'results_annual.csv')) unless skip_simulation

      # Check for debug files
      assert(File.exist? File.join(run_dir, 'in.osm')) unless skip_simulation
      hpxml_defaults_path = File.join(run_dir, 'in.xml')
      assert(File.exist? hpxml_defaults_path) unless skip_simulation

      # Check for no warnings/errors in run.log
      # We still get 1 warning ("No valid weather file defined in either the osm or osw."), but why?
      # We do set the weather file in the BuildResidentialHPXML measure.
      run_log = File.join(run_dir, 'run.log')
      assert_equal(1, File.readlines(run_log).size)

      # Cleanup
      File.delete(osw_path_test)
      xml_path_test = File.join(File.dirname(__FILE__), '..', 'run', 'built.xml')
      File.delete(xml_path_test) if File.exist?(xml_path_test)
      xml_path_test = File.join(File.dirname(__FILE__), '..', 'run', 'built-stochastic-schedules.xml')
      File.delete(xml_path_test) if File.exist?(xml_path_test)
    end
  end

  def test_mf_building_simulations
    rb_path = File.join(File.dirname(__FILE__), '..', 'run_simulation.rb')
    sample_files_path = File.join(File.dirname(__FILE__), '..', 'sample_files')
    run_dir = File.join(sample_files_path, 'run')
    csv_output_path = File.join(run_dir, 'results_annual.csv')
    bills_csv_path = File.join(run_dir, 'results_bills.csv')
    run_log = File.join(run_dir, 'run.log')
    dryer_warning_msg = 'Warning: No clothes dryer specified, the model will not include clothes dryer energy use.'

    [true, false].each do |whole_sfa_or_mf_building_sim|
      tmp_hpxml_path = File.join(sample_files_path, 'tmp.xml')
      hpxml = HPXML.new(hpxml_path: File.join(sample_files_path, 'base-bldgtype-mf-whole-building.xml'))
      hpxml.header.whole_sfa_or_mf_building_sim = whole_sfa_or_mf_building_sim
      XMLHelper.write_file(hpxml.to_doc, tmp_hpxml_path)

      # Check for when building-id argument is not provided
      command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{rb_path}\" -x \"#{tmp_hpxml_path}\""
      system(command, err: File::NULL)
      if whole_sfa_or_mf_building_sim
        # Simulation should be successful
        assert_equal(true, File.exist?(csv_output_path))
        assert_equal(true, File.exist?(bills_csv_path))

        # Check that we have multiple warnings, one for each Building element
        assert_equal(6, File.readlines(run_log).count { |l| l.include? dryer_warning_msg })
      else
        # Simulation should be unsuccessful (building_id or WholeSFAorMFBuildingSimulation=true is required)
        assert_equal(false, File.exist?(csv_output_path))
        assert_equal(false, File.exist?(bills_csv_path))
        assert_equal(1, File.readlines(run_log).count { |l| l.include? 'Multiple Building elements defined in HPXML file; provide Building ID argument or set WholeSFAorMFBuildingSimulation=true.' })
      end

      # Check for when building-id argument is provided
      command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{rb_path}\" -x \"#{tmp_hpxml_path}\" --building-id MyBuilding_2"
      system(command, err: File::NULL)
      if whole_sfa_or_mf_building_sim
        # Simulation should be successful (WholeSFAorMFBuildingSimulation is true, so building-id argument is ignored)
        # Note: We don't want to override WholeSFAorMFBuildingSimulation because we may have Schematron validation based on it, and it would be wrong to
        # validate the HPXML for one use case (whole building model) while running it for a different unit case (individual dwelling unit model).
        assert_equal(true, File.exist?(csv_output_path))
        assert_equal(true, File.exist?(bills_csv_path))
        assert_equal(1, File.readlines(run_log).count { |l| l.include? 'Multiple Building elements defined in HPXML file and WholeSFAorMFBuildingSimulation=true; Building ID argument will be ignored.' })
      else
        # Simulation should be successful
        assert_equal(true, File.exist?(csv_output_path))
        assert_equal(true, File.exist?(bills_csv_path))

        # Check that we have exactly one warning (i.e., check we are only validating a single Building element against schematron)
        assert_equal(1, File.readlines(run_log).count { |l| l.include? dryer_warning_msg })
      end

      next unless not whole_sfa_or_mf_building_sim

      # Check for when building-id argument is invalid (incorrect building ID)
      # Simulation should be unsuccessful
      command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{rb_path}\" -x \"#{tmp_hpxml_path}\" --building-id MyFoo"
      system(command, err: File::NULL)
      assert_equal(false, File.exist?(csv_output_path))
      assert_equal(false, File.exist?(bills_csv_path))
      assert_equal(1, File.readlines(run_log).count { |l| l.include? "Could not find Building element with ID 'MyFoo'." })

      # Cleanup
      File.delete(tmp_hpxml_path) if File.exist? tmp_hpxml_path
    end
  end

  def test_release_zips
    # Check release zips successfully created
    top_dir = File.join(File.dirname(__FILE__), '..', '..')
    command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{File.join(top_dir, 'tasks.rb')}\" create_release_zips"
    system(command)
    assert_equal(1, Dir["#{top_dir}/*.zip"].size)

    # Check successful running of simulation from release zips
    require 'zip'
    Zip.on_exists_proc = true
    Dir["#{top_dir}/OpenStudio-HPXML*.zip"].each do |zip_path|
      Zip::File.open(zip_path) do |zip_file|
        zip_file.each do |f|
          FileUtils.mkdir_p(File.dirname(f.name)) unless File.exist?(File.dirname(f.name))
          zip_file.extract(f, f.name)
        end
      end

      # Test run_simulation.rb
      command = "\"#{OpenStudio.getOpenStudioCLI}\" OpenStudio-HPXML/workflow/run_simulation.rb -x OpenStudio-HPXML/workflow/sample_files/base.xml"
      system(command)
      assert(File.exist? 'OpenStudio-HPXML/workflow/sample_files/run/results_annual.csv')

      File.delete(zip_path)
      rm_path('OpenStudio-HPXML')
    end
  end
end
