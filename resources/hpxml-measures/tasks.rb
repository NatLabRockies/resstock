# frozen_string_literal: true

OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)

Dir["#{File.dirname(__FILE__)}/HPXMLtoOpenStudio/resources/*.rb"].each do |resource_file|
  next if resource_file.include? 'minitest_helper.rb'

  require resource_file
end

def create_hpxmls
  this_dir = File.dirname(__FILE__)
  workflow_dir = File.join(this_dir, 'workflow')
  hpxml_inputs_tsv_path = File.join(workflow_dir, 'hpxml_inputs.json')

  require 'json'
  json_inputs = JSON.parse(File.read(hpxml_inputs_tsv_path))
  abs_hpxml_files = []
  dirs = json_inputs.keys.map { |file_path| File.dirname(file_path) }.uniq

  schema_path = File.join(File.dirname(__FILE__), 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd')
  schema_validator = XMLValidator.get_xml_validator(schema_path)

  # Delete all stochastic schedule files (they will be regenerated below)
  stochastic_sched_basename = 'occupancy-stochastic'
  stochastic_csvs = File.join(File.dirname(__FILE__), 'HPXMLtoOpenStudio', 'resources', 'schedule_files', "#{stochastic_sched_basename}*.csv")
  Dir.glob(stochastic_csvs).each { |file| File.delete(file) }

  # Specify list of sample files that should not regenerate schedule CSVs. These files test simulation timesteps
  # that differ from the stochastic schedule timestep. If we were to call the BuildResidentialScheduleFile
  # measure, it will generate a stochastic schedule that matches the simulation timestep; so we skip it and just
  # use the stochastic schedule generated from another HPXML file.
  schedule_skip_list = [
    'base-schedules-detailed-occupancy-stochastic-10-mins.xml',
    'base-simcontrol-timestep-10-mins-occupancy-stochastic-60-mins.xml'
  ]

  puts "Generating #{json_inputs.size} HPXML files..."

  json_inputs.keys.each_with_index do |hpxml_filename, hpxml_i|
    # Uncomment following line to debug single file
    # next unless hpxml_filename.include? 'base-mechvent-cfis-evap-cooler-only-ducted.xml'

    puts "[#{hpxml_i + 1}/#{json_inputs.size}] Generating #{hpxml_filename}..."
    hpxml_path = File.join(workflow_dir, hpxml_filename)
    abs_hpxml_files << File.absolute_path(hpxml_path)

    # Build up json_input from parent_hpxml(s)
    parent_hpxml_filenames = []
    parent_hpxml_filename = json_inputs[hpxml_filename]['parent_hpxml']
    while not parent_hpxml_filename.nil?
      if not json_inputs.keys.include? parent_hpxml_filename
        fail "Could not find parent_hpxml: #{parent_hpxml_filename}."
      end

      parent_hpxml_filenames << parent_hpxml_filename
      parent_hpxml_filename = json_inputs[parent_hpxml_filename]['parent_hpxml']
    end
    json_input = { 'hpxml_path' => hpxml_path }
    for parent_hpxml_filename in parent_hpxml_filenames.reverse
      json_input.merge!(json_inputs[parent_hpxml_filename])
    end
    json_input.merge!(json_inputs[hpxml_filename])
    json_input.delete('parent_hpxml')

    File.delete(hpxml_path) if File.exist?(hpxml_path)

    measures = {}
    measures['BuildResidentialHPXML'] = [json_input]

    measures_dir = File.dirname(__FILE__)
    model = OpenStudio::Model::Model.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    num_apply_measures = 1
    if hpxml_path.include?('base-bldgtype-mf-whole-building.xml') || hpxml_path.include?('base-bldgtype-mf-whole-building-detailed-electric-panel.xml')
      num_apply_measures = 6
    end

    for i in 1..num_apply_measures
      build_residential_hpxml = measures['BuildResidentialHPXML'][0]
      if hpxml_path.include?('base-bldgtype-mf-whole-building.xml') || hpxml_path.include?('base-bldgtype-mf-whole-building-detailed-electric-panel.xml')
        suffix = "_#{i}" if i > 1
        build_residential_hpxml['schedules_paths'] = "../../HPXMLtoOpenStudio/resources/schedule_files/#{stochastic_sched_basename}-mf-unit#{suffix}.csv"
        build_residential_hpxml['geometry_foundation_type'] = (i <= 2 ? 'Basement, Unconditioned' : 'Above Apartment')
        build_residential_hpxml['geometry_attic_type'] = (i >= 5 ? 'Attic, Vented, Gable' : 'Below Apartment')
      end

      # Re-generate stochastic schedule CSV?
      prev_csv_path = nil
      csv_path = json_input['schedules_paths'].to_s.split(',').map(&:strip).find { |fp| fp.include? stochastic_sched_basename }
      if (not csv_path.nil?) && !schedule_skip_list.include?(File.basename(hpxml_path))
        sch_args = { 'hpxml_path' => hpxml_path,
                     'output_csv_path' => csv_path,
                     'hpxml_output_path' => hpxml_path,
                     'building_id' => "MyBuilding#{suffix}" }
        measures['BuildResidentialScheduleFile'] = [sch_args]

        # Rename existing file (if found) for later comparison
        csv_path = File.expand_path(File.join(File.dirname(hpxml_path), csv_path))
        if File.exist? csv_path
          prev_csv_path = csv_path + '.prev'
          File.rename(csv_path, prev_csv_path)
        end
      end

      # Apply measure
      success = apply_measures(measures_dir, measures, runner, model)

      # Report errors
      runner.result.stepErrors.each do |s|
        puts "Error: #{s}"
      end

      if not success
        puts "\nError: Did not successfully generate #{hpxml_filename}."
        exit!
      end

      # Make sure newly generated schedule CSV matches previously generated schedule CSV
      next if prev_csv_path.nil?

      csv_data = File.read(csv_path)
      prev_csv_data = File.read(prev_csv_path)
      if csv_data != prev_csv_data
        puts "Error: Two different schedule CSVs (see #{File.basename(csv_path)} vs #{File.basename(prev_csv_path)}) were generated for the same filename."
        exit!
      end
      File.delete(prev_csv_path)
    end

    hpxml = HPXML.new(hpxml_path: hpxml_path)
    hpxml.header.software_program_used = nil
    hpxml.header.software_program_version = nil
    if hpxml_path.include?('ASHRAE_Standard_140') || hpxml_path.include?('HERS_HVAC') || hpxml_path.include?('HERS_DSE')
      apply_hpxml_modification_ashrae_140(hpxml)
      if hpxml_path.include?('HERS_HVAC') || hpxml_path.include?('HERS_DSE')
        apply_hpxml_modification_hers_hvac_dse(hpxml_path, hpxml)
      end
    elsif hpxml_path.include?('HERS_Hot_Water')
      apply_hpxml_modification_hers_hot_water(hpxml)
    else
      apply_hpxml_modification_sample_files(hpxml_path, hpxml)
    end
    hpxml_doc = hpxml.to_doc()

    XMLHelper.write_file(hpxml_doc, hpxml_path)

    errors, _warnings = XMLValidator.validate_against_schema(hpxml_path, schema_validator)
    next unless errors.size > 0

    errors.each do |s|
      puts "Error: #{s}"
    end
    puts "\nError: Did not successfully validate #{hpxml_filename}."
    exit!
  end

  puts "\n"

  # Print warnings about extra files
  if abs_hpxml_files.size > 1 # Suppress warning if we're debugging a single file
    dirs.each do |dir|
      Dir["#{workflow_dir}/#{dir}/*.xml"].each do |hpxml|
        next if abs_hpxml_files.include? File.absolute_path(hpxml)

        puts "Warning: Extra HPXML file found at #{File.absolute_path(hpxml)}"
      end
    end
  end
end

def apply_hpxml_modification_ashrae_140(hpxml)
  # Set detailed HPXML values for ASHRAE 140 test files
  hpxml_bldg = hpxml.buildings[0]

  # ------------ #
  # HPXML Header #
  # ------------ #

  hpxml.header.xml_generated_by = 'tasks.rb'
  hpxml.header.created_date_and_time = Time.new(2000, 1, 1, 0, 0, 0, '-07:00').strftime('%Y-%m-%dT%H:%M:%S%:z') # Hard-code to prevent diffs
  hpxml.header.apply_ashrae140_assumptions = true

  # --------------------- #
  # HPXML BuildingSummary #
  # --------------------- #

  hpxml_bldg.site.azimuth_of_front_of_home = nil

  # --------------- #
  # HPXML Enclosure #
  # --------------- #

  hpxml_bldg.attics[0].vented_attic_ach = 2.4
  hpxml_bldg.foundations.reverse_each do |foundation|
    foundation.delete
  end
  (hpxml_bldg.walls + hpxml_bldg.rim_joists).each do |wall|
    if wall.is_a?(HPXML::Wall)
      if wall.attic_wall_type == HPXML::AtticWallTypeGable
        wall.insulation_assembly_r_value = 2.15
      else
        wall.interior_finish_type = HPXML::InteriorFinishGypsumBoard
        wall.interior_finish_thickness = 0.5
      end
    end
  end
  hpxml_bldg.floors.each do |floor|
    next unless floor.is_ceiling

    floor.interior_finish_type = HPXML::InteriorFinishGypsumBoard
    floor.interior_finish_thickness = 0.5
  end
  hpxml_bldg.foundation_walls.each do |fwall|
    fwall.thickness = 6.0
    if fwall.insulation_interior_r_value == 0
      fwall.interior_finish_type = HPXML::InteriorFinishNone
    else
      fwall.interior_finish_type = HPXML::InteriorFinishGypsumBoard
      fwall.interior_finish_thickness = 0.5
    end
  end
  if hpxml_bldg.doors.size == 1
    hpxml_bldg.doors[0].area /= 2.0
    hpxml_bldg.doors << hpxml_bldg.doors[0].dup
    hpxml_bldg.doors[1].azimuth = 0
    hpxml_bldg.doors[1].id = 'Door2'
  end
  hpxml_bldg.windows.each do |window|
    next if window.overhangs_depth.nil?

    window.overhangs_distance_to_bottom_of_window = 6.0
  end
  hpxml_bldg.slabs.each do |slab|
    if slab.perimeter_insulation_r_value == 5
      slab.perimeter_insulation_r_value = 5.4
      slab.perimeter_insulation_depth = 2.5
    end
  end

  # ---------- #
  # HPXML HVAC #
  # ---------- #

  if hpxml_bldg.hvac_controls.empty?
    hpxml_bldg.hvac_controls.add(id: "HVACControl#{hpxml_bldg.hvac_controls.size + 1}",
                                 heating_setpoint_temp: 68.0,
                                 cooling_setpoint_temp: 78.0)
  end

  # --------------- #
  # HPXML MiscLoads #
  # --------------- #

  return unless hpxml_bldg.plug_loads[0].kwh_per_year > 0

  hpxml_bldg.plug_loads[0].weekday_fractions = '0.0203, 0.0203, 0.0203, 0.0203, 0.0203, 0.0339, 0.0426, 0.0852, 0.0497, 0.0304, 0.0304, 0.0406, 0.0304, 0.0254, 0.0264, 0.0264, 0.0386, 0.0416, 0.0447, 0.0700, 0.0700, 0.0731, 0.0731, 0.0660'
  hpxml_bldg.plug_loads[0].weekend_fractions = '0.0203, 0.0203, 0.0203, 0.0203, 0.0203, 0.0339, 0.0426, 0.0852, 0.0497, 0.0304, 0.0304, 0.0406, 0.0304, 0.0254, 0.0264, 0.0264, 0.0386, 0.0416, 0.0447, 0.0700, 0.0700, 0.0731, 0.0731, 0.0660'
  hpxml_bldg.plug_loads[0].monthly_multipliers = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
end

def apply_hpxml_modification_hers_hvac_dse(hpxml_path, hpxml)
  # Set detailed HPXML values for HERS HVAC/DSE test files
  hpxml.header.eri_calculation_versions = ['2022CE']
  hpxml_bldg = hpxml.buildings[0]

  hpxml_bldg.hvac_systems.each do |hvac_system|
    hvac_system.fan_watts_per_cfm = 0.5
  end

  if hpxml_path.include? 'HERS_HVAC'
    hpxml_bldg.hvac_distributions.clear
    hpxml_bldg.hvac_distributions.add(id: 'HVACDistribution1',
                                      distribution_system_type: HPXML::HVACDistributionTypeDSE,
                                      annual_heating_dse: 1.0,
                                      annual_cooling_dse: 1.0)
    if ['HVAC1a.xml', 'HVAC1b.xml', 'HVAC2a.xml', 'HVAC2b.xml', 'HVAC2e.xml'].include? File.basename(hpxml_path)
      hpxml_bldg.heating_systems[0].heating_capacity = 56100
      hpxml_bldg.cooling_systems[0].cooling_capacity = 38300
    elsif ['HVAC2c.xml', 'HVAC2d.xml'].include? File.basename(hpxml_path)
      hpxml_bldg.heat_pumps[0].heating_capacity = 56100
      hpxml_bldg.heat_pumps[0].cooling_capacity = 56100
    end
  end

  if hpxml_path.include? 'HERS_DSE'
    if ['HVAC3a.xml', 'HVAC3e.xml'].include? File.basename(hpxml_path)
      hpxml_bldg.heating_systems[0].heating_capacity = 46600
      hpxml_bldg.cooling_systems[0].cooling_capacity = 38400
    elsif ['HVAC3b.xml'].include? File.basename(hpxml_path)
      hpxml_bldg.heating_systems[0].heating_capacity = 56000
      hpxml_bldg.cooling_systems[0].cooling_capacity = 38400
    elsif ['HVAC3c.xml'].include? File.basename(hpxml_path)
      hpxml_bldg.heating_systems[0].heating_capacity = 49000
      hpxml_bldg.cooling_systems[0].cooling_capacity = 38400
    elsif ['HVAC3d.xml'].include? File.basename(hpxml_path)
      hpxml_bldg.heating_systems[0].heating_capacity = 61000
      hpxml_bldg.cooling_systems[0].cooling_capacity = 38400
    elsif ['HVAC3f.xml'].include? File.basename(hpxml_path)
      hpxml_bldg.heating_systems[0].heating_capacity = 46600
      hpxml_bldg.cooling_systems[0].cooling_capacity = 49900
    elsif ['HVAC3g.xml'].include? File.basename(hpxml_path)
      hpxml_bldg.heating_systems[0].heating_capacity = 46600
      hpxml_bldg.cooling_systems[0].cooling_capacity = 42200
    elsif ['HVAC3h.xml'].include? File.basename(hpxml_path)
      hpxml_bldg.heating_systems[0].heating_capacity = 46600
      hpxml_bldg.cooling_systems[0].cooling_capacity = 55000
    end

    # Assign duct surface area
    hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served = nil
    hpxml_bldg.hvac_distributions[0].ducts[0].duct_fraction_area = nil
    hpxml_bldg.hvac_distributions[0].ducts[1].duct_fraction_area = nil
    hpxml_bldg.hvac_distributions[0].ducts[0].duct_surface_area = 308.0
    hpxml_bldg.hvac_distributions[0].ducts[1].duct_surface_area = 77.0

    # Temporarily use effective R-values instead of nominal R-values to match the test specs.
    hpxml_bldg.hvac_distributions[0].ducts.each do |duct|
      next if duct.duct_insulation_r_value.nil?

      if duct.duct_insulation_r_value == 0
        duct.duct_insulation_r_value = nil
        duct.duct_effective_r_value = 1.5
      elsif duct.duct_insulation_r_value == 6
        duct.duct_insulation_r_value = nil
        duct.duct_effective_r_value = 7
      else
        fail 'Unexpected error.'
      end
    end
  end
end

def apply_hpxml_modification_hers_hot_water(hpxml)
  # Set detailed HPXML values for HERS Hot Water test files
  hpxml.header.eri_calculation_versions = ['2022CE']
  hpxml_bldg = hpxml.buildings[0]

  hpxml.header.xml_generated_by = 'tasks.rb'
  hpxml.header.created_date_and_time = Time.new(2000, 1, 1, 0, 0, 0, '-07:00').strftime('%Y-%m-%dT%H:%M:%S%:z') # Hard-code to prevent diffs

  hpxml_bldg.hvac_distributions.clear
  hpxml_bldg.hvac_distributions.add(id: 'HVACDistribution1',
                                    distribution_system_type: HPXML::HVACDistributionTypeDSE,
                                    annual_heating_dse: 1.0,
                                    annual_cooling_dse: 1.0)
end

def apply_hpxml_modification_sample_files(hpxml_path, hpxml)
  # Set detailed HPXML values for sample files
  hpxml_file = File.basename(hpxml_path)
  default_schedules_csv_data = Defaults.get_schedules_csv_data()

  # ------------ #
  # HPXML Header #
  # ------------ #

  hpxml.header.xml_generated_by = 'tasks.rb'
  hpxml.header.created_date_and_time = Time.new(2000, 1, 1, 0, 0, 0, '-07:00').strftime('%Y-%m-%dT%H:%M:%S%:z') # Hard-code to prevent diffs

  if ['base-simcontrol-calendar-year-custom.xml'].include? hpxml_file
    hpxml.header.sim_calendar_year = 2010
  end
  if ['base-misc-emissions.xml',
      'base-simcontrol-runperiod-1-month.xml'].include? hpxml_file
    hpxml.header.emissions_scenarios.add(name: 'Cambium Hourly MidCase LRMER RMPA',
                                         emissions_type: 'CO2e',
                                         elec_units: 'kg/MWh',
                                         elec_schedule_filepath: '../../HPXMLtoOpenStudio/resources/data/cambium/LRMER_MidCase.csv',
                                         elec_schedule_number_of_header_rows: 1,
                                         elec_schedule_column_number: 17)
    hpxml.header.emissions_scenarios.add(name: 'Cambium Hourly LowRECosts LRMER RMPA',
                                         emissions_type: 'CO2e',
                                         elec_units: 'kg/MWh',
                                         elec_schedule_filepath: '../../HPXMLtoOpenStudio/resources/data/cambium/LRMER_LowRECosts.csv',
                                         elec_schedule_number_of_header_rows: 1,
                                         elec_schedule_column_number: 17)
    hpxml.header.emissions_scenarios.add(name: 'Cambium Annual MidCase AER National',
                                         emissions_type: 'CO2e',
                                         elec_units: 'kg/MWh',
                                         elec_value: 392.6)
    hpxml.header.emissions_scenarios.add(name: 'eGRID RMPA',
                                         emissions_type: 'SO2',
                                         elec_units: 'lb/MWh',
                                         elec_value: 0.384)
    hpxml.header.emissions_scenarios.add(name: 'eGRID RMPA',
                                         emissions_type: 'NOx',
                                         elec_units: 'lb/MWh',
                                         elec_value: 0.67)
  end
  if ['base-battery-scheduled-power-outage.xml',
      'base-schedules-simple-power-outage.xml'].include? hpxml_file
    hpxml.header.unavailable_periods.add(column_name: 'Power Outage', begin_month: 7, begin_day: 1, begin_hour: 5, end_month: 7, end_day: 31, end_hour: 14)
  elsif ['base-schedules-simple-vacancy.xml',
         'base-schedules-detailed-occupancy-stochastic-vacancy.xml'].include? hpxml_file
    hpxml.header.unavailable_periods.add(column_name: 'Vacancy', begin_month: 12, begin_day: 1, end_month: 1, end_day: 31, natvent_availability: HPXML::ScheduleUnavailable)
  elsif ['base-schedules-detailed-mixed-timesteps-power-outage.xml',
         'base-schedules-detailed-occupancy-stochastic-power-outage.xml'].include? hpxml_file
    hpxml.header.unavailable_periods.add(column_name: 'Power Outage', begin_month: 12, begin_day: 1, begin_hour: 5, end_month: 1, end_day: 31, end_hour: 14)
  elsif ['base-schedules-simple-no-space-heating.xml'].include? hpxml_file
    hpxml.header.unavailable_periods.add(column_name: 'No Space Heating', begin_month: 12, begin_day: 5, begin_hour: 0, end_month: 12, end_day: 31, end_hour: 23)
  elsif ['base-schedules-detailed-occupancy-stochastic-no-space-heating.xml'].include? hpxml_file
    hpxml.header.unavailable_periods.add(column_name: 'No Space Heating', begin_month: 12, begin_day: 11, begin_hour: 5, end_month: 1, end_day: 2, end_hour: 14)
  elsif ['base-schedules-simple-no-space-cooling.xml'].include? hpxml_file
    hpxml.header.unavailable_periods.add(column_name: 'No Space Cooling', begin_month: 7, begin_day: 1, begin_hour: 22, end_month: 8, end_day: 3, end_hour: 14)
  elsif ['base-schedules-detailed-occupancy-stochastic-no-space-cooling.xml'].include? hpxml_file
    hpxml.header.unavailable_periods.add(column_name: 'No Space Cooling', begin_month: 6, begin_day: 15, begin_hour: 5, end_month: 7, end_day: 30, end_hour: 14)
  end

  hpxml.buildings.each_with_index do |hpxml_bldg, hpxml_bldg_index|
    # ------------ #
    # HPXML Header #
    # ------------ #

    if ['base-misc-emissions.xml'].include? hpxml_file
      hpxml_bldg.egrid_region = 'Western'
      hpxml_bldg.egrid_subregion = 'RMPA'
      hpxml_bldg.cambium_region_gea = 'RMPAc'
    end
    if ['base-simcontrol-daylight-saving-custom.xml'].include? hpxml_file
      hpxml_bldg.dst_observed = true
      hpxml_bldg.dst_begin_month = 3
      hpxml_bldg.dst_begin_day = 10
      hpxml_bldg.dst_end_month = 11
      hpxml_bldg.dst_end_day = 6
    elsif ['base-simcontrol-daylight-saving-disabled.xml'].include? hpxml_file
      hpxml_bldg.dst_observed = false
    end
    if ['base-hvac-autosize-sizing-controls.xml'].include? hpxml_file
      hpxml_bldg.header.manualj_heating_design_temp = 0
      hpxml_bldg.header.manualj_cooling_design_temp = 100
      hpxml_bldg.header.manualj_heating_setpoint = 60
      hpxml_bldg.header.manualj_cooling_setpoint = 80
      hpxml_bldg.header.manualj_humidity_setpoint = 0.55
      hpxml_bldg.header.manualj_internal_loads_sensible = 4000
      hpxml_bldg.header.manualj_internal_loads_latent = 200
      hpxml_bldg.header.manualj_num_occupants = 5
      hpxml_bldg.header.manualj_daily_temp_range = HPXML::ManualJDailyTempRangeLow
      hpxml_bldg.header.manualj_humidity_difference = 30
    end
    epw_filepath = hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath
    if not epw_filepath.nil?
      if epw_filepath.start_with? 'USA_'
        hpxml_bldg.state_code = epw_filepath[4..5]
      elsif epw_filepath.start_with? 'US_'
        hpxml_bldg.state_code = epw_filepath[3..4]
      end
    end
    if ['base-location-detailed.xml'].include? hpxml_file
      hpxml_bldg.time_zone_utc_offset = -6
      hpxml_bldg.latitude = 39.77
      hpxml_bldg.longitude = -104.73
      hpxml_bldg.elevation = 5548
      hpxml_bldg.state_code = 'CO'
      hpxml_bldg.city = 'Aurora'
      iecc_zone = '5B'
    else
      iecc_zone = {
        'USA_HI_Honolulu.Intl.AP.911820_TMY3.epw' => '1A',
        'USA_FL_Miami.Intl.AP.722020_TMY3.epw' => '1A',
        'USA_AZ_Phoenix-Sky.Harbor.Intl.AP.722780_TMY3.epw' => '2B',
        'USA_TX_Dallas-Fort.Worth.Intl.AP.722590_TMY3.epw' => '3A',
        'USA_MD_Baltimore-Washington.Intl.AP.724060_TMY3.epw' => '4A',
        'USA_OR_Portland.Intl.AP.726980_TMY3.epw' => '4C',
        'US_CO_Boulder_AMY_2012.epw' => '5B',
        'USA_CO_Denver.Intl.AP.725650_TMY3.epw' => '5B',
        'USA_MT_Helena.Rgnl.AP.727720_TMY3.epw' => '6B',
        'USA_MN_Duluth.Intl.AP.727450_TMY3.epw' => '7',
      }[epw_filepath]
    end
    if not iecc_zone.nil?
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.clear
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.add(zone: iecc_zone,
                                                               year: 2006)
    elsif not hpxml_bldg.state_code.nil?
      fail 'Unhandled EPW filepath in tasks.rb'
    end
    if ['base-misc-defaults.xml',
        'base-residents-5-5.xml'].include? hpxml_file
      hpxml_bldg.state_code = nil
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.clear
    end

    # --------------------- #
    # HPXML BuildingSummary #
    # --------------------- #

    hpxml_bldg.site.available_fuels = [HPXML::FuelTypeElectricity, HPXML::FuelTypeNaturalGas]

    if ['base-schedules-simple.xml',
        'base-schedules-simple-vacancy.xml',
        'base-schedules-simple-power-outage.xml',
        'base-misc-loads-large-uncommon.xml',
        'base-misc-loads-large-uncommon2.xml'].include? hpxml_file
      hpxml_bldg.building_occupancy.weekday_fractions = '0.061, 0.061, 0.061, 0.061, 0.061, 0.061, 0.061, 0.053, 0.025, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.018, 0.033, 0.054, 0.054, 0.054, 0.061, 0.061, 0.061'
      hpxml_bldg.building_occupancy.weekend_fractions = '0.061, 0.061, 0.061, 0.061, 0.061, 0.061, 0.061, 0.053, 0.025, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.018, 0.033, 0.054, 0.054, 0.054, 0.061, 0.061, 0.061'
      hpxml_bldg.building_occupancy.monthly_multipliers = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
      hpxml_bldg.building_occupancy.general_water_use_weekday_fractions = '0.023, 0.021, 0.021, 0.025, 0.027, 0.038, 0.044, 0.039, 0.037, 0.037, 0.034, 0.035, 0.035, 0.035, 0.039, 0.043, 0.051, 0.064, 0.065, 0.072, 0.073, 0.063, 0.045, 0.034'
      hpxml_bldg.building_occupancy.general_water_use_weekend_fractions = '0.023, 0.021, 0.021, 0.025, 0.027, 0.038, 0.044, 0.039, 0.037, 0.037, 0.034, 0.035, 0.035, 0.035, 0.039, 0.043, 0.051, 0.064, 0.065, 0.072, 0.073, 0.063, 0.045, 0.034'
      hpxml_bldg.building_occupancy.general_water_use_monthly_multipliers = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
    elsif ['base-misc-defaults.xml'].include? hpxml_file
      hpxml_bldg.building_construction.average_ceiling_height = nil
      hpxml_bldg.building_construction.conditioned_building_volume = nil
      hpxml_bldg.site.site_type = nil
      hpxml_bldg.site.shielding_of_home = nil
    elsif ['base-atticroof-cathedral.xml'].include? hpxml_file
      hpxml_bldg.building_construction.number_of_conditioned_floors = 2
      hpxml_bldg.building_construction.number_of_conditioned_floors_above_grade = 1
      hpxml_bldg.building_construction.average_ceiling_height = hpxml_bldg.building_construction.conditioned_building_volume / 2700
      hpxml_bldg.building_construction.conditioned_floor_area = 2700
      hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served = 2700
      hpxml_bldg.attics[0].attic_type = HPXML::AtticTypeCathedral
    elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
      hpxml_bldg.building_construction.conditioned_building_volume = 23850
      hpxml_bldg.air_infiltration_measurements[0].infiltration_volume = hpxml_bldg.building_construction.conditioned_building_volume
      hpxml_bldg.air_infiltration_measurements[0].infiltration_height = 15.0
    elsif ['base-enclosure-split-level.xml'].include? hpxml_file
      hpxml_bldg.building_construction.number_of_conditioned_floors = 1.5
      hpxml_bldg.building_construction.number_of_conditioned_floors_above_grade = 1.5
    elsif ['base-foundation-walkout-basement.xml'].include? hpxml_file
      hpxml_bldg.building_construction.number_of_conditioned_floors_above_grade = 2
    elsif ['base-foundation-basement-garage.xml'].include? hpxml_file
      hpxml_bldg.building_construction.conditioned_floor_area -= 400 * 2
      hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served -= 400 * 2
      hpxml_bldg.building_construction.conditioned_building_volume -= 400 * 2 * 8
      hpxml_bldg.air_infiltration_measurements[0].infiltration_volume = hpxml_bldg.building_construction.conditioned_building_volume
    elsif ['base-residents-5-5.xml'].include? hpxml_file
      hpxml_bldg.building_occupancy.number_of_residents = 5.5
    end
    if hpxml_file.include? 'base-bldgtype-mf-unit'
      hpxml_bldg.building_construction.unit_height_above_grade = 10
    elsif hpxml_file.include? 'base-bldgtype-mf-whole-building'
      hpxml_bldg.building_construction.unit_height_above_grade = { 1 => 0.0, 2 => 0.0, 3 => 10.0, 4 => 10.0, 5 => 20.0, 6 => 20.0 }[hpxml_bldg_index + 1]
    end
    if hpxml_file.include? 'compartmentalization-test'
      hpxml_bldg.air_infiltration_measurements[0].infiltration_type = HPXML::InfiltrationTypeUnitTotal
      if ['base-bldgtype-mf-unit-infil-compartmentalization-test.xml'].include? hpxml_file
        hpxml_bldg.air_infiltration_measurements[0].a_ext = 0.2
      end
    end
    if hpxml_file.include? 'unit-multiplier'
      hpxml_bldg.building_construction.number_of_units = 10
    end

    # ------------------ #
    # HPXML Zones/Spaces #
    # ------------------ #

    if ['base-zones-spaces.xml',
        'base-zones-spaces-multiple.xml'].include? hpxml_file
      # Add zones
      if hpxml_file == 'base-zones-spaces.xml'
        hpxml_bldg.zones.add(id: 'ConditionedZone',
                             zone_type: HPXML::ZoneTypeConditioned)
        ag_cond_zone = hpxml_bldg.zones[-1]
        bg_cond_zone = hpxml_bldg.zones[-1]
      elsif hpxml_file == 'base-zones-spaces-multiple.xml'
        hpxml_bldg.zones.add(id: 'AGConditionedZone',
                             zone_type: HPXML::ZoneTypeConditioned)
        ag_cond_zone = hpxml_bldg.zones[-1]
        hpxml_bldg.zones.add(id: 'BGConditionedZone',
                             zone_type: HPXML::ZoneTypeConditioned)
        bg_cond_zone = hpxml_bldg.zones[-1]
      end
      hpxml_bldg.zones.add(id: 'GarageZone',
                           zone_type: HPXML::ZoneTypeUnconditioned)
      grg_zone = hpxml_bldg.zones[-1]

      # Attach HVAC
      hpxml_bldg.heating_systems[0].attached_to_zone_idref = hpxml_bldg.zones[0].id
      hpxml_bldg.cooling_systems[0].attached_to_zone_idref = hpxml_bldg.zones[0].id
      if hpxml_file == 'base-zones-spaces-multiple.xml'
        hpxml_bldg.heating_systems << hpxml_bldg.heating_systems[0].dup
        hpxml_bldg.heating_systems[-1].id = 'HeatingSystem2'
        hpxml_bldg.heating_systems[-1].attached_to_zone_idref = hpxml_bldg.zones[1].id
        hpxml_bldg.heating_systems[-1].primary_system = false
        hpxml_bldg.cooling_systems << hpxml_bldg.cooling_systems[0].dup
        hpxml_bldg.cooling_systems[-1].id = 'CoolingSystem2'
        hpxml_bldg.cooling_systems[-1].attached_to_zone_idref = hpxml_bldg.zones[1].id
        hpxml_bldg.cooling_systems[-1].primary_system = false
        hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served /= 2.0
        hpxml_bldg.hvac_distributions.add(id: "HVACDistribution#{hpxml_bldg.hvac_distributions.size + 1}",
                                          distribution_system_type: HPXML::HVACDistributionTypeAir,
                                          air_type: HPXML::AirTypeRegularVelocity,
                                          conditioned_floor_area_served: hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served)
        hpxml_bldg.hvac_distributions[-1].duct_leakage_measurements << hpxml_bldg.hvac_distributions[0].duct_leakage_measurements[0].dup
        hpxml_bldg.hvac_distributions[-1].duct_leakage_measurements << hpxml_bldg.hvac_distributions[0].duct_leakage_measurements[1].dup
        hpxml_bldg.hvac_distributions[0].ducts.each do |duct|
          hpxml_bldg.hvac_distributions[-1].ducts << duct.dup
          hpxml_bldg.hvac_distributions[-1].ducts[-1].id = "Ducts#{hpxml_bldg.hvac_distributions[0].ducts.size + hpxml_bldg.hvac_distributions[1].ducts.size}"
        end
        hpxml_bldg.heating_systems[-1].distribution_system_idref = hpxml_bldg.hvac_distributions[-1].id
        hpxml_bldg.cooling_systems[-1].distribution_system_idref = hpxml_bldg.hvac_distributions[-1].id
      end
      hpxml_bldg.hvac_distributions.each do |hvac_distribution|
        hvac_distribution.ducts.each do |duct|
          duct.duct_fraction_area = nil
          duct.duct_surface_area = (duct.duct_type == HPXML::DuctTypeSupply ? 150.0 : 50.0)
          duct.duct_surface_area /= hpxml_bldg.hvac_distributions.size
        end
      end

      # Add spaces
      ag_cond_zone.spaces.add(id: 'Space1',
                              floor_area: 850,
                              manualj_num_occupants: 2,
                              manualj_internal_loads_sensible: 1000,
                              manualj_internal_loads_latent: 100)
      ag_cond_zone.spaces.add(id: 'Space2',
                              floor_area: 500,
                              manualj_num_occupants: 0,
                              manualj_internal_loads_sensible: 0,
                              manualj_internal_loads_latent: 0)
      bg_cond_zone.spaces.add(id: 'Space3',
                              floor_area: 1000,
                              manualj_num_occupants: 1,
                              manualj_internal_loads_sensible: 1400,
                              manualj_internal_loads_latent: 200)
      bg_cond_zone.spaces.add(id: 'Space4',
                              floor_area: 350,
                              manualj_num_occupants: 1,
                              manualj_internal_loads_sensible: 600,
                              manualj_internal_loads_latent: 0)
      grg_zone.spaces.add(id: 'GarageSpace',
                          floor_area: 600)

      # Attach surfaces
      ag_surfaces = hpxml_bldg.surfaces.select { |w| w.interior_adjacent_to == HPXML::LocationConditionedSpace }
      ag_spaces = hpxml_bldg.conditioned_spaces[0..1]
      ag_cfa = ag_spaces.map { |space| space.floor_area }.sum
      ag_surfaces.reverse_each do |ag_surface|
        ag_spaces.each do |ag_space|
          if ag_surface.is_a? HPXML::Wall
            hpxml_bldg.walls << ag_surface.dup
            new_ag_surface = hpxml_bldg.walls[-1]
          elsif ag_surface.is_a? HPXML::Floor
            hpxml_bldg.floors << ag_surface.dup
            new_ag_surface = hpxml_bldg.floors[-1]
          else
            fail "Unexpected surface type: #{ag_surface.class}"
          end
          new_ag_surface.id = "#{ag_surface.id}#{ag_space.id}"
          new_ag_surface.insulation_id = "#{ag_surface.insulation_id}#{ag_space.id}"
          new_ag_surface.area = (new_ag_surface.area * ag_space.floor_area / ag_cfa).round(1)
          new_ag_surface.attached_to_space_idref = ag_space.id
          if ag_surface.is_a? HPXML::Floor
            hpxml_bldg.attics[0].attached_to_floor_idrefs << new_ag_surface.id
          end
          next unless ag_surface.is_a? HPXML::Wall

          ag_surface.windows.each do |window|
            hpxml_bldg.windows << window.dup
            hpxml_bldg.windows[-1].id = "#{hpxml_bldg.windows[-1].id}#{ag_space.id}"
            hpxml_bldg.windows[-1].area = (hpxml_bldg.windows[-1].area * ag_space.floor_area / ag_cfa).round(1)
            hpxml_bldg.windows[-1].interior_shading_id = "#{hpxml_bldg.windows[-1].interior_shading_id}#{ag_space.id}"
            hpxml_bldg.windows[-1].attached_to_wall_idref = new_ag_surface.id
          end
          ag_surface.doors.each do |door|
            hpxml_bldg.doors << door.dup
            hpxml_bldg.doors[-1].id = "#{hpxml_bldg.doors[-1].id}#{ag_space.id}"
            hpxml_bldg.doors[-1].area = (hpxml_bldg.doors[-1].area / ag_surface.doors.size).round(1)
            hpxml_bldg.doors[-1].attached_to_wall_idref = new_ag_surface.id
          end
        end
        ag_surface.delete
      end

      bg_surfaces = hpxml_bldg.surfaces.select { |w| w.interior_adjacent_to == HPXML::LocationBasementConditioned }
      bg_spaces = hpxml_bldg.conditioned_spaces[2..3]
      bg_cfa = bg_spaces.map { |space| space.floor_area }.sum
      bg_surfaces.reverse_each do |bg_surface|
        hpxml_bldg.conditioned_spaces[2..3].each do |bg_space|
          if bg_surface.is_a? HPXML::FoundationWall
            hpxml_bldg.foundation_walls << bg_surface.dup
            new_bg_surface = hpxml_bldg.foundation_walls[-1]
          elsif bg_surface.is_a? HPXML::RimJoist
            hpxml_bldg.rim_joists << bg_surface.dup
            new_bg_surface = hpxml_bldg.rim_joists[-1]
          elsif bg_surface.is_a? HPXML::Slab
            hpxml_bldg.slabs << bg_surface.dup
            new_bg_surface = hpxml_bldg.slabs[-1]
          else
            fail "Unexpected surface type: #{bg_surface.class}"
          end
          new_bg_surface.id = "#{bg_surface.id}#{bg_space.id}"
          if bg_surface.is_a? HPXML::Slab
            new_bg_surface.perimeter_insulation_id = "#{bg_surface.perimeter_insulation_id}#{bg_space.id}"
            new_bg_surface.under_slab_insulation_id = "#{bg_surface.under_slab_insulation_id}#{bg_space.id}"
            if not new_bg_surface.exterior_horizontal_insulation_id.nil?
              new_bg_surface.exterior_horizontal_insulation_id = "#{bg_surface.exterior_horizontal_insulation_id}#{bg_space.id}"
            end
          else
            new_bg_surface.insulation_id = "#{bg_space.id}#{bg_surface.insulation_id}"
          end
          new_bg_surface.area = (new_bg_surface.area * bg_space.floor_area / bg_cfa).round(1)
          if bg_surface.is_a? HPXML::Slab
            new_bg_surface.exposed_perimeter = (new_bg_surface.exposed_perimeter * bg_space.floor_area / bg_cfa).round(1)
          end
          new_bg_surface.attached_to_space_idref = bg_space.id
          if bg_surface.is_a? HPXML::RimJoist
            hpxml_bldg.foundations[0].attached_to_rim_joist_idrefs << new_bg_surface.id
          elsif bg_surface.is_a? HPXML::FoundationWall
            hpxml_bldg.foundations[0].attached_to_foundation_wall_idrefs << new_bg_surface.id
          elsif bg_surface.is_a? HPXML::Slab
            hpxml_bldg.foundations[0].attached_to_slab_idrefs << new_bg_surface.id
          end
        end
        bg_surface.delete
      end
      hpxml_bldg.surfaces.each do |s|
        next unless s.interior_adjacent_to == HPXML::LocationGarage

        s.attached_to_space_idref = hpxml_bldg.zones[-1].spaces[0].id
      end
    end

    # --------------- #
    # HPXML Enclosure #
    # --------------- #

    (hpxml_bldg.roofs + hpxml_bldg.walls + hpxml_bldg.rim_joists).each do |surface|
      surface.solar_absorptance = 0.7
      surface.emittance = 0.92
      if surface.is_a? HPXML::Roof
        surface.roof_color = nil
      else
        surface.color = nil
      end
    end
    hpxml_bldg.roofs.each do |roof|
      next unless roof.interior_adjacent_to == HPXML::LocationConditionedSpace

      roof.interior_finish_type = HPXML::InteriorFinishGypsumBoard
    end
    (hpxml_bldg.walls + hpxml_bldg.foundation_walls + hpxml_bldg.floors).each do |surface|
      if surface.is_a?(HPXML::FoundationWall) && surface.interior_adjacent_to != HPXML::LocationBasementConditioned
        surface.interior_finish_type = HPXML::InteriorFinishNone
      end
      next unless [HPXML::LocationConditionedSpace,
                   HPXML::LocationBasementConditioned].include?(surface.interior_adjacent_to) &&
                  [HPXML::LocationOutside,
                   HPXML::LocationGround,
                   HPXML::LocationGarage,
                   HPXML::LocationAtticUnvented,
                   HPXML::LocationAtticVented,
                   HPXML::LocationOtherHousingUnit,
                   HPXML::LocationBasementConditioned].include?(surface.exterior_adjacent_to)
      next if surface.is_a?(HPXML::Floor) && surface.is_floor

      surface.interior_finish_type = HPXML::InteriorFinishGypsumBoard
    end
    hpxml_bldg.attics.each do |attic|
      if attic.attic_type == HPXML::AtticTypeUnvented
        attic.within_infiltration_volume = false
      elsif attic.attic_type == HPXML::AtticTypeVented
        attic.vented_attic_sla = 0.003
      end
    end
    hpxml_bldg.foundations.each do |foundation|
      if foundation.foundation_type == HPXML::FoundationTypeCrawlspaceUnvented
        foundation.within_infiltration_volume = false
      elsif foundation.foundation_type == HPXML::FoundationTypeCrawlspaceVented
        foundation.vented_crawlspace_sla = 0.00667
      end
    end
    hpxml_bldg.skylights.each do |skylight|
      skylight.interior_shading_factor_summer = 1.0
      skylight.interior_shading_factor_winter = 1.0
    end

    if ['base-bldgtype-mf-unit-adjacent-to-multifamily-buffer-space.xml',
        'base-bldgtype-mf-unit-adjacent-to-non-freezing-space.xml',
        'base-bldgtype-mf-unit-adjacent-to-other-heated-space.xml',
        'base-bldgtype-mf-unit-adjacent-to-other-housing-unit.xml',
        'base-bldgtype-mf-unit-adjacent-to-other-housing-unit-basement.xml'].include? hpxml_file
      if hpxml_file.include? 'multifamily-buffer-space'
        adjacent_to = HPXML::LocationOtherMultifamilyBufferSpace
      elsif hpxml_file.include? 'non-freezing-space'
        adjacent_to = HPXML::LocationOtherNonFreezingSpace
      elsif hpxml_file.include? 'other-heated-space'
        adjacent_to = HPXML::LocationOtherHeatedSpace
      elsif hpxml_file.include? 'other-housing-unit'
        adjacent_to = HPXML::LocationOtherHousingUnit
      end
      wall = hpxml_bldg.walls.select { |w|
               w.interior_adjacent_to == HPXML::LocationConditionedSpace &&
                 w.exterior_adjacent_to == HPXML::LocationOtherHousingUnit
             }[0]
      wall.exterior_adjacent_to = adjacent_to
      hpxml_bldg.floors[1].exterior_adjacent_to = adjacent_to
      if hpxml_file.include? 'basement'
        hpxml_bldg.rim_joists[1].exterior_adjacent_to = adjacent_to
        hpxml_bldg.foundation_walls[1].exterior_adjacent_to = adjacent_to
      elsif !hpxml_file.include? 'other-housing-unit'
        wall.insulation_assembly_r_value = 23
        hpxml_bldg.floors[0].exterior_adjacent_to = adjacent_to
        hpxml_bldg.floors[0].insulation_assembly_r_value = 18.7
        hpxml_bldg.floors[1].insulation_assembly_r_value = 18.7
      end
      hpxml_bldg.windows.each do |window|
        window.area = (window.area * 0.35).round(1)
      end
      hpxml_bldg.doors.add(id: "Door#{hpxml_bldg.doors.size + 1}",
                           attached_to_wall_idref: wall.id,
                           area: 20,
                           azimuth: 0,
                           r_value: 4.4)
      hpxml_bldg.hvac_distributions[0].ducts[0].duct_location = adjacent_to
      hpxml_bldg.hvac_distributions[0].ducts[1].duct_location = adjacent_to
      hpxml_bldg.water_heating_systems[0].location = adjacent_to
      hpxml_bldg.clothes_washers[0].location = adjacent_to
      hpxml_bldg.clothes_dryers[0].location = adjacent_to
      hpxml_bldg.dishwashers[0].location = adjacent_to
      hpxml_bldg.refrigerators[0].location = adjacent_to
      hpxml_bldg.cooking_ranges[0].location = adjacent_to
    elsif ['base-bldgtype-mf-unit-adjacent-to-multiple.xml',
           'base-bldgtype-mf-unit-adjacent-to-multiple-hvac-none.xml'].include? hpxml_file
      wall = hpxml_bldg.walls.select { |w|
               w.interior_adjacent_to == HPXML::LocationConditionedSpace &&
                 w.exterior_adjacent_to == HPXML::LocationOtherHousingUnit
             }[0]
      wall.delete
      hpxml_bldg.walls.add(id: "Wall#{hpxml_bldg.walls.size + 1}",
                           exterior_adjacent_to: HPXML::LocationOtherHeatedSpace,
                           interior_adjacent_to: HPXML::LocationConditionedSpace,
                           wall_type: HPXML::WallTypeWoodStud,
                           area: 100,
                           solar_absorptance: 0.7,
                           emittance: 0.92,
                           interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                           insulation_assembly_r_value: 23.0)
      hpxml_bldg.walls.add(id: "Wall#{hpxml_bldg.walls.size + 1}",
                           exterior_adjacent_to: HPXML::LocationOtherMultifamilyBufferSpace,
                           interior_adjacent_to: HPXML::LocationConditionedSpace,
                           wall_type: HPXML::WallTypeWoodStud,
                           area: 100,
                           solar_absorptance: 0.7,
                           emittance: 0.92,
                           interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                           insulation_assembly_r_value: 23.0)
      hpxml_bldg.walls.add(id: "Wall#{hpxml_bldg.walls.size + 1}",
                           exterior_adjacent_to: HPXML::LocationOtherNonFreezingSpace,
                           interior_adjacent_to: HPXML::LocationConditionedSpace,
                           wall_type: HPXML::WallTypeWoodStud,
                           area: 100,
                           solar_absorptance: 0.7,
                           emittance: 0.92,
                           interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                           insulation_assembly_r_value: 23.0)
      hpxml_bldg.walls.add(id: "Wall#{hpxml_bldg.walls.size + 1}",
                           exterior_adjacent_to: HPXML::LocationOtherHousingUnit,
                           interior_adjacent_to: HPXML::LocationConditionedSpace,
                           wall_type: HPXML::WallTypeWoodStud,
                           area: 100,
                           solar_absorptance: 0.7,
                           emittance: 0.92,
                           interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                           insulation_assembly_r_value: 4.0)
      hpxml_bldg.floors[0].delete
      hpxml_bldg.floors[0].id = 'Floor1'
      hpxml_bldg.floors[0].insulation_id = 'Floor1Insulation'
      hpxml_bldg.floors.add(id: "Floor#{hpxml_bldg.floors.size + 1}",
                            exterior_adjacent_to: HPXML::LocationOtherNonFreezingSpace,
                            interior_adjacent_to: HPXML::LocationConditionedSpace,
                            floor_type: HPXML::FloorTypeWoodFrame,
                            area: 550,
                            insulation_assembly_r_value: 18.7,
                            floor_or_ceiling: HPXML::FloorOrCeilingFloor)
      hpxml_bldg.floors.add(id: "Floor#{hpxml_bldg.floors.size + 1}",
                            exterior_adjacent_to: HPXML::LocationOtherMultifamilyBufferSpace,
                            interior_adjacent_to: HPXML::LocationConditionedSpace,
                            floor_type: HPXML::FloorTypeWoodFrame,
                            area: 200,
                            insulation_assembly_r_value: 18.7,
                            floor_or_ceiling: HPXML::FloorOrCeilingFloor)
      hpxml_bldg.floors.add(id: "Floor#{hpxml_bldg.floors.size + 1}",
                            exterior_adjacent_to: HPXML::LocationOtherHeatedSpace,
                            interior_adjacent_to: HPXML::LocationConditionedSpace,
                            floor_type: HPXML::FloorTypeWoodFrame,
                            area: 150,
                            insulation_assembly_r_value: 5.3,
                            floor_or_ceiling: HPXML::FloorOrCeilingFloor)
      wall = hpxml_bldg.walls.select { |w|
               w.interior_adjacent_to == HPXML::LocationConditionedSpace &&
                 w.exterior_adjacent_to == HPXML::LocationOtherMultifamilyBufferSpace
             }[0]
      hpxml_bldg.windows.add(id: "Window#{hpxml_bldg.windows.size + 1}",
                             area: 50,
                             azimuth: 270,
                             ufactor: 0.33,
                             shgc: 0.45,
                             fraction_operable: 0.67,
                             attached_to_wall_idref: wall.id)
      wall = hpxml_bldg.walls.select { |w|
               w.interior_adjacent_to == HPXML::LocationConditionedSpace &&
                 w.exterior_adjacent_to == HPXML::LocationOtherHeatedSpace
             }[0]
      hpxml_bldg.doors.add(id: "Door#{hpxml_bldg.doors.size + 1}",
                           attached_to_wall_idref: wall.id,
                           area: 20,
                           azimuth: 0,
                           r_value: 4.4)
      wall = hpxml_bldg.walls.select { |w|
               w.interior_adjacent_to == HPXML::LocationConditionedSpace &&
                 w.exterior_adjacent_to == HPXML::LocationOtherHousingUnit
             }[0]
      hpxml_bldg.doors.add(id: "Door#{hpxml_bldg.doors.size + 1}",
                           attached_to_wall_idref: wall.id,
                           area: 20,
                           azimuth: 0,
                           r_value: 4.4)
    elsif ['base-enclosure-orientations.xml'].include? hpxml_file
      hpxml_bldg.windows.each do |window|
        window.orientation = { 0 => 'north', 90 => 'east', 180 => 'south', 270 => 'west' }[window.azimuth]
        window.azimuth = nil
      end
      hpxml_bldg.doors[0].delete
      hpxml_bldg.doors.add(id: "Door#{hpxml_bldg.doors.size + 1}",
                           attached_to_wall_idref: 'Wall1',
                           area: 20,
                           orientation: HPXML::OrientationNorth,
                           r_value: 4.4)
      hpxml_bldg.doors.add(id: "Door#{hpxml_bldg.doors.size + 1}",
                           attached_to_wall_idref: 'Wall1',
                           area: 20,
                           orientation: HPXML::OrientationSouth,
                           r_value: 4.4)
    elsif ['base-foundation-unconditioned-basement.xml'].include? hpxml_file
      hpxml_bldg.foundations[0].within_infiltration_volume = false
    elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
      hpxml_bldg.attics.add(id: "Attic#{hpxml_bldg.attics.size + 1}",
                            attic_type: HPXML::AtticTypeUnvented,
                            within_infiltration_volume: false)
      hpxml_bldg.roofs.each do |roof|
        roof.area = 1006.0 / hpxml_bldg.roofs.size
        roof.insulation_assembly_r_value = 25.8
      end
      hpxml_bldg.roofs.add(id: "Roof#{hpxml_bldg.roofs.size + 1}",
                           interior_adjacent_to: HPXML::LocationAtticUnvented,
                           area: 504,
                           roof_type: HPXML::RoofTypeAsphaltShingles,
                           solar_absorptance: 0.7,
                           emittance: 0.92,
                           pitch: 6,
                           radiant_barrier: false,
                           insulation_assembly_r_value: 2.3)
      hpxml_bldg.rim_joists.each do |rim_joist|
        rim_joist.area = 116.0 / hpxml_bldg.rim_joists.size
      end
      hpxml_bldg.walls.each do |wall|
        wall.area = 1200.0 / hpxml_bldg.walls.size
      end
      hpxml_bldg.walls.add(id: "Wall#{hpxml_bldg.walls.size + 1}",
                           exterior_adjacent_to: HPXML::LocationAtticUnvented,
                           interior_adjacent_to: HPXML::LocationConditionedSpace,
                           wall_type: HPXML::WallTypeWoodStud,
                           area: 316,
                           solar_absorptance: 0.7,
                           emittance: 0.92,
                           interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                           insulation_assembly_r_value: 23.0)
      hpxml_bldg.walls.add(id: "Wall#{hpxml_bldg.walls.size + 1}",
                           exterior_adjacent_to: HPXML::LocationOutside,
                           interior_adjacent_to: HPXML::LocationConditionedSpace,
                           wall_type: HPXML::WallTypeWoodStud,
                           siding: HPXML::SidingTypeWood,
                           area: 240,
                           solar_absorptance: 0.7,
                           emittance: 0.92,
                           interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                           insulation_assembly_r_value: 22.3)
      hpxml_bldg.walls.add(id: "Wall#{hpxml_bldg.walls.size + 1}",
                           exterior_adjacent_to: HPXML::LocationOutside,
                           interior_adjacent_to: HPXML::LocationAtticUnvented,
                           attic_wall_type: HPXML::AtticWallTypeGable,
                           wall_type: HPXML::WallTypeWoodStud,
                           siding: HPXML::SidingTypeWood,
                           area: 50,
                           solar_absorptance: 0.7,
                           emittance: 0.92,
                           insulation_assembly_r_value: 4.0)
      hpxml_bldg.foundation_walls.each do |foundation_wall|
        foundation_wall.area = 1200.0 / hpxml_bldg.foundation_walls.size
      end
      hpxml_bldg.floors.add(id: "Floor#{hpxml_bldg.floors.size + 1}",
                            exterior_adjacent_to: HPXML::LocationAtticUnvented,
                            interior_adjacent_to: HPXML::LocationConditionedSpace,
                            floor_type: HPXML::FloorTypeWoodFrame,
                            area: 450,
                            interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                            insulation_assembly_r_value: 39.3,
                            floor_or_ceiling: HPXML::FloorOrCeilingCeiling)
      hpxml_bldg.slabs[0].area = 1350
      hpxml_bldg.slabs[0].exposed_perimeter = 150
      hpxml_bldg.windows[1].area = 108
      hpxml_bldg.windows[3].area = 108
      hpxml_bldg.windows.add(id: "Window#{hpxml_bldg.windows.size + 1}",
                             area: 12,
                             azimuth: 90,
                             ufactor: 0.33,
                             shgc: 0.45,
                             fraction_operable: 0,
                             attached_to_wall_idref: hpxml_bldg.walls[-2].id)
      hpxml_bldg.windows.add(id: "Window#{hpxml_bldg.windows.size + 1}",
                             area: 62,
                             azimuth: 270,
                             ufactor: 0.3,
                             shgc: 0.45,
                             fraction_operable: 0,
                             attached_to_wall_idref: hpxml_bldg.walls[-2].id)
    elsif ['base-foundation-unconditioned-basement-above-grade.xml'].include? hpxml_file
      hpxml_bldg.windows.add(id: "Window#{hpxml_bldg.windows.size + 1}",
                             area: 20,
                             azimuth: 0,
                             ufactor: 0.33,
                             shgc: 0.45,
                             fraction_operable: 0.0,
                             attached_to_wall_idref: hpxml_bldg.foundation_walls[0].id)
      hpxml_bldg.windows.add(id: "Window#{hpxml_bldg.windows.size + 1}",
                             area: 10,
                             azimuth: 90,
                             ufactor: 0.33,
                             shgc: 0.45,
                             fraction_operable: 0.0,
                             attached_to_wall_idref: hpxml_bldg.foundation_walls[0].id)
      hpxml_bldg.windows.add(id: "Window#{hpxml_bldg.windows.size + 1}",
                             area: 20,
                             azimuth: 180,
                             ufactor: 0.33,
                             shgc: 0.45,
                             fraction_operable: 0.0,
                             attached_to_wall_idref: hpxml_bldg.foundation_walls[0].id)
      hpxml_bldg.windows.add(id: "Window#{hpxml_bldg.windows.size + 1}",
                             area: 10,
                             azimuth: 270,
                             ufactor: 0.33,
                             shgc: 0.45,
                             fraction_operable: 0.0,
                             attached_to_wall_idref: hpxml_bldg.foundation_walls[0].id)
    elsif ['base-enclosure-skylights-cathedral.xml'].include? hpxml_file
      hpxml_bldg.skylights.each do |skylight|
        skylight.curb_area = 5.25
        skylight.curb_assembly_r_value = 1.96
      end
    elsif hpxml_file.include? 'base-enclosure-skylights'
      hpxml_bldg.skylights.each do |skylight|
        skylight.shaft_area = 60.0
        skylight.shaft_assembly_r_value = 6.25
      end
      if ['base-enclosure-skylights-physical-properties.xml'].include? hpxml_file
        hpxml_bldg.skylights[0].ufactor = nil
        hpxml_bldg.skylights[0].shgc = nil
        hpxml_bldg.skylights[0].glass_layers = HPXML::WindowLayersSinglePane
        hpxml_bldg.skylights[0].frame_type = HPXML::WindowFrameTypeWood
        hpxml_bldg.skylights[0].glass_type = HPXML::WindowGlassTypeTinted
        hpxml_bldg.skylights[1].ufactor = nil
        hpxml_bldg.skylights[1].shgc = nil
        hpxml_bldg.skylights[1].glass_layers = HPXML::WindowLayersDoublePane
        hpxml_bldg.skylights[1].frame_type = HPXML::WindowFrameTypeMetal
        hpxml_bldg.skylights[1].thermal_break = true
        hpxml_bldg.skylights[1].glass_type = HPXML::WindowGlassTypeLowE
        hpxml_bldg.skylights[1].gas_fill = HPXML::WindowGasKrypton
      elsif ['base-enclosure-skylights-shading.xml'].include? hpxml_file
        hpxml_bldg.skylights[0].exterior_shading_factor_summer = 0.1
        hpxml_bldg.skylights[0].exterior_shading_factor_winter = 0.9
        hpxml_bldg.skylights[0].interior_shading_factor_summer = 0.01
        hpxml_bldg.skylights[0].interior_shading_factor_winter = 0.99
        hpxml_bldg.skylights[1].exterior_shading_factor_summer = 0.5
        hpxml_bldg.skylights[1].exterior_shading_factor_winter = 0.0
        hpxml_bldg.skylights[1].interior_shading_factor_summer = 0.5
        hpxml_bldg.skylights[1].interior_shading_factor_winter = 1.0
      elsif ['base-enclosure-skylights-storms.xml'].include? hpxml_file
        hpxml_bldg.skylights.each do |skylight|
          skylight.storm_type = HPXML::WindowGlassTypeClear
        end
      end
    elsif ['base-enclosure-windows-physical-properties.xml'].include? hpxml_file
      hpxml_bldg.windows[0].ufactor = nil
      hpxml_bldg.windows[0].shgc = nil
      hpxml_bldg.windows[0].glass_layers = HPXML::WindowLayersSinglePane
      hpxml_bldg.windows[0].frame_type = HPXML::WindowFrameTypeWood
      hpxml_bldg.windows[0].glass_type = HPXML::WindowGlassTypeTinted
      hpxml_bldg.windows[1].ufactor = nil
      hpxml_bldg.windows[1].shgc = nil
      hpxml_bldg.windows[1].glass_layers = HPXML::WindowLayersDoublePane
      hpxml_bldg.windows[1].frame_type = HPXML::WindowFrameTypeVinyl
      hpxml_bldg.windows[1].glass_type = HPXML::WindowGlassTypeLowELowSolarGain
      hpxml_bldg.windows[1].gas_fill = HPXML::WindowGasAir
      hpxml_bldg.windows[2].ufactor = nil
      hpxml_bldg.windows[2].shgc = nil
      hpxml_bldg.windows[2].glass_layers = HPXML::WindowLayersDoublePane
      hpxml_bldg.windows[2].frame_type = HPXML::WindowFrameTypeMetal
      hpxml_bldg.windows[2].thermal_break = true
      hpxml_bldg.windows[2].glass_type = HPXML::WindowGlassTypeLowE
      hpxml_bldg.windows[2].gas_fill = HPXML::WindowGasArgon
      hpxml_bldg.windows[3].ufactor = nil
      hpxml_bldg.windows[3].shgc = nil
      hpxml_bldg.windows[3].glass_layers = HPXML::WindowLayersGlassBlock
    elsif ['base-enclosure-windows-shading-factors.xml'].include? hpxml_file
      hpxml_bldg.windows.each do |window|
        window.interior_shading_type = nil
      end
      hpxml_bldg.windows[0].interior_shading_factor_summer = 0.7
      hpxml_bldg.windows[0].interior_shading_factor_winter = 0.85
      hpxml_bldg.windows[1].exterior_shading_factor_summer = 0.5
      hpxml_bldg.windows[1].exterior_shading_factor_winter = 0.5
      hpxml_bldg.windows[1].interior_shading_factor_summer = 0.5
      hpxml_bldg.windows[1].interior_shading_factor_winter = 0.5
      hpxml_bldg.windows[2].exterior_shading_factor_summer = 0.1
      hpxml_bldg.windows[2].exterior_shading_factor_winter = 0.9
      hpxml_bldg.windows[2].interior_shading_factor_summer = 0.01
      hpxml_bldg.windows[2].interior_shading_factor_winter = 0.99
      hpxml_bldg.windows[3].exterior_shading_factor_summer = 0.0
      hpxml_bldg.windows[3].exterior_shading_factor_winter = 1.0
      hpxml_bldg.windows[3].interior_shading_factor_summer = 0.0
      hpxml_bldg.windows[3].interior_shading_factor_winter = 1.0
    elsif ['base-enclosure-windows-shading-types-detailed.xml'].include? hpxml_file
      hpxml_bldg.windows.each do |window|
        window.interior_shading_factor_summer = nil
        window.interior_shading_factor_winter = nil
        window.exterior_shading_factor_summer = nil
        window.exterior_shading_factor_winter = nil
      end
      # Interior shading
      hpxml_bldg.windows[0].interior_shading_type = HPXML::InteriorShadingTypeNone
      hpxml_bldg.windows[1].interior_shading_type = HPXML::InteriorShadingTypeOther
      hpxml_bldg.windows[2].interior_shading_type = HPXML::InteriorShadingTypeMediumCurtains
      hpxml_bldg.windows[2].interior_shading_coverage_summer = 0.5
      hpxml_bldg.windows[2].interior_shading_coverage_winter = 0.0
      hpxml_bldg.windows[3].interior_shading_type = HPXML::InteriorShadingTypeLightBlinds
      hpxml_bldg.windows[3].interior_shading_blinds_summer_closed_or_open = HPXML::BlindsClosed
      hpxml_bldg.windows[3].interior_shading_blinds_winter_closed_or_open = HPXML::BlindsHalfOpen
      hpxml_bldg.windows[3].interior_shading_coverage_summer = 0.5
      hpxml_bldg.windows[3].interior_shading_coverage_winter = 1.0
      # Exterior shading
      hpxml_bldg.windows[0].exterior_shading_type = HPXML::ExteriorShadingTypeDeciduousTree
      hpxml_bldg.windows[1].exterior_shading_type = HPXML::ExteriorShadingTypeSolarScreens
      hpxml_bldg.windows[2].exterior_shading_type = HPXML::ExteriorShadingTypeExternalOverhangs
      hpxml_bldg.windows[2].overhangs_depth = 2.0
      hpxml_bldg.windows[2].overhangs_distance_to_top_of_window = 1.0
      hpxml_bldg.windows[2].overhangs_distance_to_bottom_of_window = 4.0
      hpxml_bldg.windows[3].exterior_shading_type = HPXML::ExteriorShadingTypeBuilding
      # Insect screens
      hpxml_bldg.windows[0].insect_screen_present = true
      hpxml_bldg.windows[0].insect_screen_location = HPXML::LocationInterior
      hpxml_bldg.windows[0].insect_screen_coverage_summer = 1.0
      hpxml_bldg.windows[0].insect_screen_coverage_winter = 0.0
      hpxml_bldg.windows[1].insect_screen_present = true
      hpxml_bldg.windows[1].insect_screen_location = HPXML::LocationExterior
      hpxml_bldg.windows[1].insect_screen_coverage_summer = 1.0
      hpxml_bldg.windows[1].insect_screen_coverage_winter = 1.0
      hpxml_bldg.windows[2].insect_screen_present = true
      hpxml_bldg.windows[2].insect_screen_location = HPXML::LocationExterior
      hpxml_bldg.windows[3].insect_screen_present = true
    elsif ['base-enclosure-thermal-mass.xml'].include? hpxml_file
      hpxml_bldg.partition_wall_mass.area_fraction = 0.8
      hpxml_bldg.partition_wall_mass.interior_finish_type = HPXML::InteriorFinishGypsumBoard
      hpxml_bldg.partition_wall_mass.interior_finish_thickness = 0.25
      hpxml_bldg.furniture_mass.area_fraction = 0.8
      hpxml_bldg.furniture_mass.type = HPXML::FurnitureMassTypeHeavyWeight
    elsif ['base-misc-defaults.xml'].include? hpxml_file
      hpxml_bldg.attics.reverse_each do |attic|
        attic.delete
      end
      hpxml_bldg.foundations.reverse_each do |foundation|
        foundation.delete
      end
      hpxml_bldg.air_infiltration_measurements[0].infiltration_volume = nil
      (hpxml_bldg.roofs + hpxml_bldg.walls + hpxml_bldg.rim_joists).each do |surface|
        surface.solar_absorptance = nil
        surface.emittance = nil
        if surface.is_a? HPXML::Roof
          surface.radiant_barrier = nil
          surface.roof_type = nil
        end
        if surface.is_a?(HPXML::Wall) || surface.is_a?(HPXML::RimJoist)
          surface.siding = nil
        end
      end
      (hpxml_bldg.walls + hpxml_bldg.foundation_walls).each do |wall|
        wall.interior_finish_type = nil
      end
      hpxml_bldg.foundation_walls.each do |fwall|
        fwall.length = fwall.area / fwall.height
        fwall.area = nil
      end
      hpxml_bldg.slabs.each do |slab|
        slab.carpet_fraction = nil
      end
      hpxml_bldg.doors[0].azimuth = nil
      hpxml_bldg.windows.each do |window|
        window.fraction_operable = nil
        window.interior_shading_type = nil
        window.exterior_shading_type = nil
      end
    elsif ['base-enclosure-2stories.xml',
           'base-enclosure-2stories-garage.xml'].include? hpxml_file
      hpxml_bldg.rim_joists << hpxml_bldg.rim_joists[-1].dup
      hpxml_bldg.rim_joists[-1].id = "RimJoist#{hpxml_bldg.rim_joists.size}"
      hpxml_bldg.rim_joists[-1].insulation_id = "RimJoist#{hpxml_bldg.rim_joists.size}Insulation"
      hpxml_bldg.rim_joists[-1].interior_adjacent_to = HPXML::LocationConditionedSpace
      hpxml_bldg.rim_joists[-1].area = 116
    elsif ['base-foundation-conditioned-basement-wall-insulation.xml'].include? hpxml_file
      hpxml_bldg.foundation_walls.each do |foundation_wall|
        foundation_wall.insulation_interior_r_value = 10
        foundation_wall.insulation_interior_distance_to_top = 1
        foundation_wall.insulation_interior_distance_to_bottom = 8
        foundation_wall.insulation_exterior_r_value = 8.9
        foundation_wall.insulation_exterior_distance_to_top = 1
        foundation_wall.insulation_exterior_distance_to_bottom = 8
      end
    elsif ['base-foundation-walkout-basement.xml'].include? hpxml_file
      hpxml_bldg.foundation_walls.reverse_each do |foundation_wall|
        foundation_wall.delete
      end
      hpxml_bldg.foundation_walls.add(id: "FoundationWall#{hpxml_bldg.foundation_walls.size + 1}",
                                      exterior_adjacent_to: HPXML::LocationGround,
                                      interior_adjacent_to: HPXML::LocationBasementConditioned,
                                      height: 8,
                                      area: 480,
                                      thickness: 8,
                                      depth_below_grade: 7,
                                      interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                                      insulation_interior_r_value: 0,
                                      insulation_exterior_distance_to_top: 0,
                                      insulation_exterior_distance_to_bottom: 8,
                                      insulation_exterior_r_value: 8.9)
      hpxml_bldg.foundation_walls.add(id: "FoundationWall#{hpxml_bldg.foundation_walls.size + 1}",
                                      exterior_adjacent_to: HPXML::LocationGround,
                                      interior_adjacent_to: HPXML::LocationBasementConditioned,
                                      height: 8,
                                      area: 240,
                                      thickness: 8,
                                      depth_below_grade: 3,
                                      interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                                      insulation_interior_r_value: 0,
                                      insulation_exterior_distance_to_top: 0,
                                      insulation_exterior_distance_to_bottom: 8,
                                      insulation_exterior_r_value: 8.9)
      hpxml_bldg.foundation_walls.add(id: "FoundationWall#{hpxml_bldg.foundation_walls.size + 1}",
                                      exterior_adjacent_to: HPXML::LocationGround,
                                      interior_adjacent_to: HPXML::LocationBasementConditioned,
                                      height: 8,
                                      area: 240,
                                      thickness: 8,
                                      depth_below_grade: 1,
                                      interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                                      insulation_interior_r_value: 0,
                                      insulation_exterior_distance_to_top: 0,
                                      insulation_exterior_distance_to_bottom: 8,
                                      insulation_exterior_r_value: 8.9)
      hpxml_bldg.foundation_walls.each do |foundation_wall|
        hpxml_bldg.foundations[0].attached_to_foundation_wall_idrefs << foundation_wall.id
      end
      hpxml_bldg.windows.add(id: "Window#{hpxml_bldg.windows.size + 1}",
                             area: 20,
                             azimuth: 0,
                             ufactor: 0.33,
                             shgc: 0.45,
                             fraction_operable: 0.0,
                             attached_to_wall_idref: hpxml_bldg.foundation_walls[-1].id)
    elsif ['base-foundation-multiple.xml'].include? hpxml_file
      hpxml_bldg.foundations.add(id: "Foundation#{hpxml_bldg.foundations.size + 1}",
                                 foundation_type: HPXML::FoundationTypeCrawlspaceUnvented,
                                 within_infiltration_volume: false)
      hpxml_bldg.rim_joists.each do |rim_joist|
        next unless rim_joist.exterior_adjacent_to == HPXML::LocationOutside

        rim_joist.exterior_adjacent_to = HPXML::LocationCrawlspaceUnvented
        rim_joist.siding = nil
        rim_joist.insulation_assembly_r_value = 4.0
      end
      hpxml_bldg.rim_joists.add(id: "RimJoist#{hpxml_bldg.rim_joists.size + 1}",
                                exterior_adjacent_to: HPXML::LocationOutside,
                                interior_adjacent_to: HPXML::LocationCrawlspaceUnvented,
                                siding: HPXML::SidingTypeWood,
                                area: 81,
                                solar_absorptance: 0.7,
                                emittance: 0.92,
                                insulation_assembly_r_value: 4.0)
      hpxml_bldg.foundation_walls.each do |foundation_wall|
        foundation_wall.area /= 2.0
      end
      hpxml_bldg.foundation_walls.add(id: "FoundationWall#{hpxml_bldg.foundation_walls.size + 1}",
                                      exterior_adjacent_to: HPXML::LocationCrawlspaceUnvented,
                                      interior_adjacent_to: HPXML::LocationBasementUnconditioned,
                                      height: 8,
                                      area: 360,
                                      thickness: 8,
                                      depth_below_grade: 4,
                                      insulation_interior_r_value: 0,
                                      insulation_exterior_r_value: 0)
      hpxml_bldg.foundation_walls.add(id: "FoundationWall#{hpxml_bldg.foundation_walls.size + 1}",
                                      exterior_adjacent_to: HPXML::LocationGround,
                                      interior_adjacent_to: HPXML::LocationCrawlspaceUnvented,
                                      height: 4,
                                      area: 600,
                                      thickness: 8,
                                      depth_below_grade: 3,
                                      insulation_interior_r_value: 0,
                                      insulation_exterior_r_value: 0)
      hpxml_bldg.floors[0].area = 675
      hpxml_bldg.floors.add(id: "Floor#{hpxml_bldg.floors.size + 1}",
                            exterior_adjacent_to: HPXML::LocationCrawlspaceUnvented,
                            interior_adjacent_to: HPXML::LocationConditionedSpace,
                            floor_type: HPXML::FloorTypeWoodFrame,
                            area: 675,
                            insulation_assembly_r_value: 18.7,
                            floor_or_ceiling: HPXML::FloorOrCeilingFloor)
      hpxml_bldg.slabs[0].area = 675
      hpxml_bldg.slabs[0].exposed_perimeter = 75
      hpxml_bldg.slabs.add(id: "Slab#{hpxml_bldg.slabs.size + 1}",
                           interior_adjacent_to: HPXML::LocationCrawlspaceUnvented,
                           area: 675,
                           thickness: 0,
                           exposed_perimeter: 75,
                           perimeter_insulation_depth: 0,
                           under_slab_insulation_width: 0,
                           perimeter_insulation_r_value: 0,
                           under_slab_insulation_r_value: 0,
                           carpet_fraction: 0,
                           carpet_r_value: 0)
    elsif ['base-foundation-complex.xml'].include? hpxml_file
      hpxml_bldg.foundation_walls.reverse_each do |foundation_wall|
        foundation_wall.delete
      end
      hpxml_bldg.foundation_walls.add(id: "FoundationWall#{hpxml_bldg.foundation_walls.size + 1}",
                                      exterior_adjacent_to: HPXML::LocationGround,
                                      interior_adjacent_to: HPXML::LocationBasementConditioned,
                                      height: 8,
                                      area: 160,
                                      thickness: 8,
                                      depth_below_grade: 7,
                                      interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                                      insulation_interior_r_value: 0,
                                      insulation_exterior_r_value: 0.0)
      hpxml_bldg.foundation_walls.add(id: "FoundationWall#{hpxml_bldg.foundation_walls.size + 1}",
                                      exterior_adjacent_to: HPXML::LocationGround,
                                      interior_adjacent_to: HPXML::LocationBasementConditioned,
                                      height: 8,
                                      area: 240,
                                      thickness: 8,
                                      depth_below_grade: 7,
                                      interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                                      insulation_interior_r_value: 0,
                                      insulation_exterior_distance_to_top: 0,
                                      insulation_exterior_distance_to_bottom: 8,
                                      insulation_exterior_r_value: 8.9)
      hpxml_bldg.foundation_walls.add(id: "FoundationWall#{hpxml_bldg.foundation_walls.size + 1}",
                                      exterior_adjacent_to: HPXML::LocationGround,
                                      interior_adjacent_to: HPXML::LocationBasementConditioned,
                                      height: 8,
                                      area: 320,
                                      thickness: 8,
                                      depth_below_grade: 3,
                                      interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                                      insulation_interior_r_value: 0,
                                      insulation_exterior_r_value: 0.0)
      hpxml_bldg.foundation_walls.add(id: "FoundationWall#{hpxml_bldg.foundation_walls.size + 1}",
                                      exterior_adjacent_to: HPXML::LocationGround,
                                      interior_adjacent_to: HPXML::LocationBasementConditioned,
                                      height: 8,
                                      area: 400,
                                      thickness: 8,
                                      depth_below_grade: 3,
                                      interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                                      insulation_interior_r_value: 0,
                                      insulation_exterior_distance_to_top: 0,
                                      insulation_exterior_distance_to_bottom: 8,
                                      insulation_exterior_r_value: 8.9)
      hpxml_bldg.foundation_walls.each do |foundation_wall|
        hpxml_bldg.foundations[0].attached_to_foundation_wall_idrefs << foundation_wall.id
      end
      hpxml_bldg.slabs.reverse_each do |slab|
        slab.delete
      end
      hpxml_bldg.slabs.add(id: "Slab#{hpxml_bldg.slabs.size + 1}",
                           interior_adjacent_to: HPXML::LocationBasementConditioned,
                           area: 1150,
                           thickness: 4,
                           exposed_perimeter: 120,
                           perimeter_insulation_depth: 0,
                           under_slab_insulation_width: 0,
                           perimeter_insulation_r_value: 0,
                           under_slab_insulation_r_value: 0,
                           carpet_fraction: 0,
                           carpet_r_value: 0)
      hpxml_bldg.slabs.add(id: "Slab#{hpxml_bldg.slabs.size + 1}",
                           interior_adjacent_to: HPXML::LocationBasementConditioned,
                           area: 200,
                           thickness: 4,
                           exposed_perimeter: 30,
                           perimeter_insulation_depth: 1,
                           under_slab_insulation_width: 0,
                           perimeter_insulation_r_value: 5,
                           under_slab_insulation_r_value: 0,
                           carpet_fraction: 0,
                           carpet_r_value: 0)
      hpxml_bldg.slabs.each do |slab|
        hpxml_bldg.foundations[0].attached_to_slab_idrefs << slab.id
      end
    elsif ['base-foundation-basement-garage.xml'].include? hpxml_file
      hpxml_bldg.roofs[0].area += 670
      hpxml_bldg.walls.add(id: "Wall#{hpxml_bldg.walls.size + 1}",
                           exterior_adjacent_to: HPXML::LocationGarage,
                           interior_adjacent_to: HPXML::LocationBasementConditioned,
                           wall_type: HPXML::WallTypeWoodStud,
                           area: 320,
                           solar_absorptance: 0.7,
                           emittance: 0.92,
                           interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                           insulation_assembly_r_value: 23)
      hpxml_bldg.foundations[0].attached_to_wall_idrefs << hpxml_bldg.walls[-1].id
      hpxml_bldg.walls.add(id: "Wall#{hpxml_bldg.walls.size + 1}",
                           exterior_adjacent_to: HPXML::LocationOutside,
                           interior_adjacent_to: HPXML::LocationGarage,
                           wall_type: HPXML::WallTypeWoodStud,
                           siding: HPXML::SidingTypeWood,
                           area: 320,
                           solar_absorptance: 0.7,
                           emittance: 0.92,
                           insulation_assembly_r_value: 4)
      hpxml_bldg.floors.add(id: "Floor#{hpxml_bldg.floors.size + 1}",
                            exterior_adjacent_to: HPXML::LocationGarage,
                            interior_adjacent_to: HPXML::LocationConditionedSpace,
                            floor_type: HPXML::FloorTypeWoodFrame,
                            area: 400,
                            insulation_assembly_r_value: 39.3,
                            floor_or_ceiling: HPXML::FloorOrCeilingFloor)
      hpxml_bldg.slabs[0].area -= 400
      hpxml_bldg.slabs[0].exposed_perimeter -= 40
      hpxml_bldg.slabs.add(id: "Slab#{hpxml_bldg.slabs.size + 1}",
                           interior_adjacent_to: HPXML::LocationGarage,
                           area: 400,
                           thickness: 4,
                           exposed_perimeter: 40,
                           perimeter_insulation_depth: 0,
                           under_slab_insulation_width: 0,
                           perimeter_insulation_r_value: 0,
                           under_slab_insulation_r_value: 0,
                           carpet_fraction: 0,
                           carpet_r_value: 0)
      hpxml_bldg.doors.add(id: "Door#{hpxml_bldg.doors.size + 1}",
                           attached_to_wall_idref: hpxml_bldg.walls[-3].id,
                           area: 70,
                           azimuth: 180,
                           r_value: 4.4)
      hpxml_bldg.doors.add(id: "Door#{hpxml_bldg.doors.size + 1}",
                           attached_to_wall_idref: hpxml_bldg.walls[-2].id,
                           area: 4,
                           azimuth: 0,
                           r_value: 4.4)
    elsif ['base-enclosure-ceilingtypes.xml'].include? hpxml_file
      exterior_adjacent_to = hpxml_bldg.floors[0].exterior_adjacent_to
      area = hpxml_bldg.floors[0].area
      hpxml_bldg.floors.reverse_each do |floor|
        floor.delete
      end
      floors_map = { HPXML::FloorTypeSIP => 16.1,
                     HPXML::FloorTypeConcrete => 3.2,
                     HPXML::FloorTypeSteelFrame => 8.1 }
      floors_map.each_with_index do |(floor_type, assembly_r), _i|
        hpxml_bldg.floors.add(id: "Floor#{hpxml_bldg.floors.size + 1}",
                              exterior_adjacent_to: exterior_adjacent_to,
                              interior_adjacent_to: HPXML::LocationConditionedSpace,
                              floor_type: floor_type,
                              area: area / floors_map.size,
                              insulation_assembly_r_value: assembly_r,
                              floor_or_ceiling: HPXML::FloorOrCeilingCeiling)
      end
    elsif ['base-enclosure-floortypes.xml'].include? hpxml_file
      exterior_adjacent_to = hpxml_bldg.floors[0].exterior_adjacent_to
      area = hpxml_bldg.floors[0].area
      ceiling = hpxml_bldg.floors[1].dup
      hpxml_bldg.floors.reverse_each do |floor|
        floor.delete
      end
      floors_map = { HPXML::FloorTypeSIP => 16.1,
                     HPXML::FloorTypeConcrete => 3.2,
                     HPXML::FloorTypeSteelFrame => 8.1 }
      floors_map.each_with_index do |(floor_type, assembly_r), _i|
        hpxml_bldg.floors.add(id: "Floor#{hpxml_bldg.floors.size + 1}",
                              exterior_adjacent_to: exterior_adjacent_to,
                              interior_adjacent_to: HPXML::LocationConditionedSpace,
                              floor_type: floor_type,
                              area: area / floors_map.size,
                              insulation_assembly_r_value: assembly_r,
                              floor_or_ceiling: HPXML::FloorOrCeilingFloor)
      end
      hpxml_bldg.floors << ceiling
      hpxml_bldg.floors[-1].id = "Floor#{hpxml_bldg.floors.size}"
      hpxml_bldg.floors[-1].insulation_id = "Floor#{hpxml_bldg.floors.size}Insulation"
    elsif ['base-enclosure-walltypes.xml'].include? hpxml_file
      hpxml_bldg.rim_joists.reverse_each do |rim_joist|
        rim_joist.delete
      end
      siding_types = [[HPXML::SidingTypeAluminum, HPXML::ColorDark],
                      [HPXML::SidingTypeAsbestos, HPXML::ColorMedium],
                      [HPXML::SidingTypeBrick, HPXML::ColorReflective],
                      [HPXML::SidingTypeCompositeShingle, HPXML::ColorDark],
                      [HPXML::SidingTypeFiberCement, HPXML::ColorMediumDark],
                      [HPXML::SidingTypeMasonite, HPXML::ColorLight],
                      [HPXML::SidingTypeStucco, HPXML::ColorMedium],
                      [HPXML::SidingTypeSyntheticStucco, HPXML::ColorMediumDark],
                      [HPXML::SidingTypeVinyl, HPXML::ColorLight],
                      [HPXML::SidingTypeNone, HPXML::ColorMedium]]
      siding_types.each do |siding_type|
        hpxml_bldg.rim_joists.add(id: "RimJoist#{hpxml_bldg.rim_joists.size + 1}",
                                  exterior_adjacent_to: HPXML::LocationOutside,
                                  interior_adjacent_to: HPXML::LocationBasementConditioned,
                                  siding: siding_type[0],
                                  color: siding_type[1],
                                  area: 116 / siding_types.size,
                                  emittance: 0.92,
                                  insulation_assembly_r_value: 23.0)
        hpxml_bldg.foundations[0].attached_to_rim_joist_idrefs << hpxml_bldg.rim_joists[-1].id
      end
      gable_walls = hpxml_bldg.walls.select { |w| w.interior_adjacent_to == HPXML::LocationAtticUnvented }
      hpxml_bldg.walls.reverse_each do |wall|
        wall.delete
      end
      walls_map = { HPXML::WallTypeCMU => 12,
                    HPXML::WallTypeDoubleWoodStud => 28.7,
                    HPXML::WallTypeICF => 21,
                    HPXML::WallTypeLog => 7.1,
                    HPXML::WallTypeSIP => 16.1,
                    HPXML::WallTypeConcrete => 1.35,
                    HPXML::WallTypeSteelStud => 8.1,
                    HPXML::WallTypeStone => 5.4,
                    HPXML::WallTypeStrawBale => 58.8,
                    HPXML::WallTypeBrick => 7.9,
                    HPXML::WallTypeAdobe => 5.0 }
      siding_types = [[HPXML::SidingTypeAluminum, HPXML::ColorReflective],
                      [HPXML::SidingTypeAsbestos, HPXML::ColorLight],
                      [HPXML::SidingTypeBrick, HPXML::ColorMediumDark],
                      [HPXML::SidingTypeCompositeShingle, HPXML::ColorReflective],
                      [HPXML::SidingTypeFiberCement, HPXML::ColorMedium],
                      [HPXML::SidingTypeMasonite, HPXML::ColorDark],
                      [HPXML::SidingTypeStucco, HPXML::ColorLight],
                      [HPXML::SidingTypeSyntheticStucco, HPXML::ColorMedium],
                      [HPXML::SidingTypeVinyl, HPXML::ColorDark],
                      [HPXML::SidingTypeNone, HPXML::ColorMedium]]
      int_finish_types = [[HPXML::InteriorFinishGypsumBoard, 0.5],
                          [HPXML::InteriorFinishGypsumBoard, 1.0],
                          [HPXML::InteriorFinishGypsumCompositeBoard, 0.5],
                          [HPXML::InteriorFinishPlaster, 0.5],
                          [HPXML::InteriorFinishWood, 0.5],
                          [HPXML::InteriorFinishNone, nil]]
      walls_map.each_with_index do |(wall_type, assembly_r), i|
        hpxml_bldg.walls.add(id: "Wall#{hpxml_bldg.walls.size + 1}",
                             exterior_adjacent_to: HPXML::LocationOutside,
                             interior_adjacent_to: HPXML::LocationConditionedSpace,
                             wall_type: wall_type,
                             siding: siding_types[i % siding_types.size][0],
                             color: siding_types[i % siding_types.size][1],
                             area: 1200 / walls_map.size,
                             emittance: 0.92,
                             interior_finish_type: int_finish_types[i % int_finish_types.size][0],
                             interior_finish_thickness: int_finish_types[i % int_finish_types.size][1],
                             insulation_assembly_r_value: assembly_r)
      end
      gable_walls.each do |gable_wall|
        hpxml_bldg.walls << gable_wall
        hpxml_bldg.walls[-1].id = "Wall#{hpxml_bldg.walls.size}"
        hpxml_bldg.walls[-1].insulation_id = "Wall#{hpxml_bldg.walls.size}Insulation"
        hpxml_bldg.attics[0].attached_to_wall_idrefs << hpxml_bldg.walls[-1].id
      end
      hpxml_bldg.windows.reverse_each do |window|
        window.delete
      end
      hpxml_bldg.windows.add(id: "Window#{hpxml_bldg.windows.size + 1}",
                             area: 108 / 8,
                             azimuth: 0,
                             ufactor: 0.33,
                             shgc: 0.45,
                             fraction_operable: 0.67,
                             attached_to_wall_idref: 'Wall1')
      hpxml_bldg.windows.add(id: "Window#{hpxml_bldg.windows.size + 1}",
                             area: 72 / 8,
                             azimuth: 90,
                             ufactor: 0.33,
                             shgc: 0.45,
                             fraction_operable: 0.67,
                             attached_to_wall_idref: 'Wall2')
      hpxml_bldg.windows.add(id: "Window#{hpxml_bldg.windows.size + 1}",
                             area: 108 / 8,
                             azimuth: 180,
                             ufactor: 0.33,
                             shgc: 0.45,
                             fraction_operable: 0.67,
                             attached_to_wall_idref: 'Wall3')
      hpxml_bldg.windows.add(id: "Window#{hpxml_bldg.windows.size + 1}",
                             area: 72 / 8,
                             azimuth: 270,
                             ufactor: 0.33,
                             shgc: 0.45,
                             fraction_operable: 0.67,
                             attached_to_wall_idref: 'Wall4')
      hpxml_bldg.doors.reverse_each do |door|
        door.delete
      end
      hpxml_bldg.doors.add(id: "Door#{hpxml_bldg.doors.size + 1}",
                           attached_to_wall_idref: 'Wall9',
                           area: 20,
                           azimuth: 0,
                           r_value: 4.4)
      hpxml_bldg.doors.add(id: "Door#{hpxml_bldg.doors.size + 1}",
                           attached_to_wall_idref: 'Wall10',
                           area: 20,
                           azimuth: 180,
                           r_value: 4.4)
    elsif ['base-enclosure-rooftypes.xml'].include? hpxml_file
      hpxml_bldg.roofs.reverse_each do |roof|
        roof.delete
      end
      roof_types = [[HPXML::RoofTypeClayTile, HPXML::ColorLight],
                    [HPXML::RoofTypeMetal, HPXML::ColorReflective],
                    [HPXML::RoofTypeWoodShingles, HPXML::ColorDark],
                    [HPXML::RoofTypeShingles, HPXML::ColorMediumDark],
                    [HPXML::RoofTypePlasticRubber, HPXML::ColorLight],
                    [HPXML::RoofTypeEPS, HPXML::ColorMedium],
                    [HPXML::RoofTypeConcrete, HPXML::ColorLight],
                    [HPXML::RoofTypeCool, HPXML::ColorReflective]]
      int_finish_types = [[HPXML::InteriorFinishGypsumBoard, 0.5],
                          [HPXML::InteriorFinishPlaster, 0.5],
                          [HPXML::InteriorFinishWood, 0.5]]
      roof_types.each_with_index do |roof_type, i|
        hpxml_bldg.roofs.add(id: "Roof#{hpxml_bldg.roofs.size + 1}",
                             interior_adjacent_to: HPXML::LocationAtticUnvented,
                             area: 1509.3 / roof_types.size,
                             roof_type: roof_type[0],
                             roof_color: roof_type[1],
                             emittance: 0.92,
                             pitch: 6,
                             radiant_barrier: false,
                             interior_finish_type: int_finish_types[i % int_finish_types.size][0],
                             interior_finish_thickness: int_finish_types[i % int_finish_types.size][1],
                             insulation_assembly_r_value: roof_type[0] == HPXML::RoofTypeEPS ? 7.0 : 2.3)
        hpxml_bldg.attics[0].attached_to_roof_idrefs << hpxml_bldg.roofs[-1].id
      end
    elsif ['base-enclosure-overhangs.xml'].include? hpxml_file
      # Test relaxed overhangs validation; https://github.com/NREL/OpenStudio-HPXML/issues/866
      hpxml_bldg.windows.each do |window|
        next unless window.overhangs_depth.nil?

        window.overhangs_depth = 0.0
        window.overhangs_distance_to_top_of_window = 0.0
        window.overhangs_distance_to_bottom_of_window = 0.0
      end
    end
    if hpxml_bldg.has_location(HPXML::LocationGarage)
      grg_wall = hpxml_bldg.walls.select { |w|
                   w.interior_adjacent_to == HPXML::LocationGarage &&
                     w.exterior_adjacent_to == HPXML::LocationOutside
                 }[0]
      hpxml_bldg.doors.add(id: "Door#{hpxml_bldg.doors.size + 1}",
                           attached_to_wall_idref: grg_wall.id,
                           area: 70,
                           azimuth: 180,
                           r_value: 4.4)
    end
    if ['base-misc-neighbor-shading-bldgtype-multifamily.xml'].include? hpxml_file
      wall = hpxml_bldg.walls.select { |w| w.azimuth == hpxml_bldg.neighbor_buildings[0].azimuth }[0]
      wall.exterior_adjacent_to = HPXML::LocationOtherHeatedSpace
    end
    if ['base-foundation-vented-crawlspace-above-grade2.xml'].include? hpxml_file
      # Convert FoundationWall to Wall to test a foundation with only Wall elements
      fwall = hpxml_bldg.foundation_walls[0]
      hpxml_bldg.walls.add(id: "Wall#{hpxml_bldg.walls.size + 1}",
                           exterior_adjacent_to: HPXML::LocationOutside,
                           interior_adjacent_to: fwall.interior_adjacent_to,
                           wall_type: HPXML::WallTypeConcrete,
                           area: fwall.area,
                           insulation_assembly_r_value: 10.1)
      hpxml_bldg.foundations[0].attached_to_wall_idrefs << hpxml_bldg.walls[-1].id
      hpxml_bldg.foundation_walls[0].delete
    end
    if ['base-foundation-slab.xml'].include? hpxml_file
      hpxml_bldg.slabs[0].gap_insulation_r_value = 0.0
    end
    if ['base-foundation-slab-exterior-horizontal-insulation.xml'].include? hpxml_file
      hpxml_bldg.slabs[0].exterior_horizontal_insulation_r_value = 5.0
      hpxml_bldg.slabs[0].exterior_horizontal_insulation_width = 2.5
      hpxml_bldg.slabs[0].exterior_horizontal_insulation_depth_below_grade = 2.0
    end
    if ['base-enclosure-windows-shading-seasons.xml'].include? hpxml_file
      hpxml_bldg.header.shading_summer_begin_month = 5
      hpxml_bldg.header.shading_summer_begin_day = 1
      hpxml_bldg.header.shading_summer_end_month = 9
      hpxml_bldg.header.shading_summer_end_day = 30
    end
    if ['base-enclosure-infil-flue.xml'].include? hpxml_file
      hpxml_bldg.air_infiltration.has_flue_or_chimney_in_conditioned_space = true
    end

    # ---------- #
    # HPXML HVAC #
    # ---------- #

    hpxml_bldg.heat_pumps.each do |heat_pump|
      if heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir
        heat_pump.pump_watts_per_ton = 100.0
      end
    end
    if ['base-misc-defaults.xml'].include? hpxml_file
      hpxml_bldg.hvac_distributions[0].ducts.each do |duct|
        duct.duct_surface_area = nil # removes surface area from both supply and return
      end
    end
    if hpxml_file.include? 'shared-boiler'
      hpxml_bldg.heating_systems[0].is_shared_system = true
      hpxml_bldg.heating_systems[0].number_of_units_served = 6
      hpxml_bldg.heating_systems[0].heating_capacity = nil
    end
    if hpxml_file.include?('chiller') || hpxml_file.include?('cooling-tower')
      # Handle chiller/cooling tower
      if hpxml_file.include? 'chiller'
        hpxml_bldg.cooling_systems.add(id: "CoolingSystem#{hpxml_bldg.cooling_systems.size + 1}",
                                       cooling_system_type: HPXML::HVACTypeChiller,
                                       cooling_system_fuel: HPXML::FuelTypeElectricity,
                                       is_shared_system: true,
                                       number_of_units_served: 6,
                                       cooling_capacity: 24000 * 6,
                                       cooling_efficiency_kw_per_ton: 0.9,
                                       fraction_cool_load_served: 1.0,
                                       primary_system: true)
      elsif hpxml_file.include? 'cooling-tower'
        hpxml_bldg.cooling_systems.add(id: "CoolingSystem#{hpxml_bldg.cooling_systems.size + 1}",
                                       cooling_system_type: HPXML::HVACTypeCoolingTower,
                                       cooling_system_fuel: HPXML::FuelTypeElectricity,
                                       is_shared_system: true,
                                       number_of_units_served: 6,
                                       fraction_cool_load_served: 1.0,
                                       primary_system: true)
      end
      if hpxml_file.include? 'boiler'
        hpxml_bldg.hvac_controls[0].cooling_setpoint_temp = 78.0
        hpxml_bldg.cooling_systems[-1].distribution_system_idref = hpxml_bldg.hvac_distributions[-1].id
      else
        hpxml_bldg.hvac_controls.add(id: "HVACControl#{hpxml_bldg.hvac_controls.size + 1}",
                                     control_type: HPXML::HVACControlTypeManual,
                                     cooling_setpoint_temp: 78.0)
        if hpxml_file.include? 'baseboard'
          hpxml_bldg.hvac_distributions.add(id: "HVACDistribution#{hpxml_bldg.hvac_distributions.size + 1}",
                                            distribution_system_type: HPXML::HVACDistributionTypeHydronic,
                                            hydronic_type: HPXML::HydronicTypeBaseboard)
          hpxml_bldg.cooling_systems[-1].distribution_system_idref = hpxml_bldg.hvac_distributions[-1].id
        end
      end
    end
    if hpxml_file.include?('water-loop-heat-pump') || hpxml_file.include?('fan-coil')
      # Handle WLHP/ducted fan coil
      hpxml_bldg.hvac_distributions.reverse_each do |hvac_distribution|
        hvac_distribution.delete
      end
      if hpxml_file.include? 'water-loop-heat-pump'
        hpxml_bldg.hvac_distributions.add(id: "HVACDistribution#{hpxml_bldg.hvac_distributions.size + 1}",
                                          distribution_system_type: HPXML::HVACDistributionTypeHydronic,
                                          hydronic_type: HPXML::HydronicTypeWaterLoop)
        hpxml_bldg.heat_pumps.add(id: "HeatPump#{hpxml_bldg.heat_pumps.size + 1}",
                                  heat_pump_type: HPXML::HVACTypeHeatPumpWaterLoopToAir,
                                  heat_pump_fuel: HPXML::FuelTypeElectricity)
        if hpxml_file.include? 'boiler'
          hpxml_bldg.heat_pumps[-1].heating_capacity = 24000
          hpxml_bldg.heat_pumps[-1].heating_efficiency_cop = 4.4
          hpxml_bldg.heating_systems[-1].distribution_system_idref = hpxml_bldg.hvac_distributions[-1].id
        end
        if hpxml_file.include?('chiller') || hpxml_file.include?('cooling-tower')
          hpxml_bldg.heat_pumps[-1].cooling_capacity = 24000
          hpxml_bldg.heat_pumps[-1].cooling_efficiency_eer = 12.8
          hpxml_bldg.cooling_systems[-1].distribution_system_idref = hpxml_bldg.hvac_distributions[-1].id
        end
        hpxml_bldg.hvac_distributions.add(id: "HVACDistribution#{hpxml_bldg.hvac_distributions.size + 1}",
                                          distribution_system_type: HPXML::HVACDistributionTypeAir,
                                          air_type: HPXML::AirTypeRegularVelocity)
        hpxml_bldg.heat_pumps[-1].distribution_system_idref = hpxml_bldg.hvac_distributions[-1].id
      elsif hpxml_file.include? 'fan-coil'
        hpxml_bldg.hvac_distributions.add(id: "HVACDistribution#{hpxml_bldg.hvac_distributions.size + 1}",
                                          distribution_system_type: HPXML::HVACDistributionTypeAir,
                                          air_type: HPXML::AirTypeFanCoil)

        if hpxml_file.include? 'boiler'
          shared_heating_system = hpxml_bldg.heating_systems.find { |h| h.is_shared_system }
          shared_heating_system.distribution_system_idref = hpxml_bldg.hvac_distributions[-1].id
        end
        if hpxml_file.include?('chiller') || hpxml_file.include?('cooling-tower')
          shared_cooling_system = hpxml_bldg.cooling_systems.find { |c| c.is_shared_system }
          shared_cooling_system.distribution_system_idref = hpxml_bldg.hvac_distributions[-1].id
        end
      end
      if hpxml_file.include?('water-loop-heat-pump') || hpxml_file.include?('fan-coil-ducted')
        hpxml_bldg.hvac_distributions[-1].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeSupply,
                                                                        duct_leakage_units: HPXML::UnitsCFM25,
                                                                        duct_leakage_value: 15,
                                                                        duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
        hpxml_bldg.hvac_distributions[-1].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                                        duct_leakage_units: HPXML::UnitsCFM25,
                                                                        duct_leakage_value: 10,
                                                                        duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
        hpxml_bldg.hvac_distributions[-1].ducts.add(id: "Ducts#{hpxml_bldg.hvac_distributions[-1].ducts.size + 1}",
                                                    duct_type: HPXML::DuctTypeSupply,
                                                    duct_insulation_r_value: 0,
                                                    duct_location: HPXML::LocationOtherMultifamilyBufferSpace,
                                                    duct_surface_area: 50)
        hpxml_bldg.hvac_distributions[-1].ducts.add(id: "Ducts#{hpxml_bldg.hvac_distributions[-1].ducts.size + 1}",
                                                    duct_type: HPXML::DuctTypeReturn,
                                                    duct_insulation_r_value: 0,
                                                    duct_location: HPXML::LocationOtherMultifamilyBufferSpace,
                                                    duct_surface_area: 20)
      end
    end
    if hpxml_file.include? 'shared-ground-loop'
      hpxml_bldg.heat_pumps[0].is_shared_system = true
      hpxml_bldg.heat_pumps[0].number_of_units_served = 6
      hpxml_bldg.heat_pumps[0].pump_watts_per_ton = 0.0
    end
    if !hpxml_file.include? 'eae'
      if hpxml_file.include? 'shared-boiler'
        hpxml_bldg.heating_systems[0].shared_loop_watts = 600
      end
      if hpxml_file.include?('chiller') || hpxml_file.include?('cooling-tower')
        hpxml_bldg.cooling_systems[0].shared_loop_watts = 600
      end
      if hpxml_file.include? 'shared-ground-loop'
        hpxml_bldg.heat_pumps[0].shared_loop_watts = 600
      end
      if hpxml_file.include? 'fan-coil'
        if hpxml_file.include? 'boiler'
          hpxml_bldg.heating_systems[0].fan_coil_watts = 150
        end
        if hpxml_file.include? 'chiller'
          hpxml_bldg.cooling_systems[0].fan_coil_watts = 150
        end
      end
    end
    if ['base-hvac-setpoints-daily-setbacks.xml'].include? hpxml_file
      hpxml_bldg.hvac_controls[0].heating_setback_temp = 66
      hpxml_bldg.hvac_controls[0].heating_setback_hours_per_week = 7 * 7
      hpxml_bldg.hvac_controls[0].heating_setback_start_hour = 23 # 11pm
      hpxml_bldg.hvac_controls[0].cooling_setup_temp = 80
      hpxml_bldg.hvac_controls[0].cooling_setup_hours_per_week = 6 * 7
      hpxml_bldg.hvac_controls[0].cooling_setup_start_hour = 9 # 9am
    elsif ['base-hvac-dse.xml',
           'base-dhw-indirect-dse.xml',
           'base-mechvent-cfis-dse.xml'].include? hpxml_file
      hpxml_bldg.hvac_distributions[0].distribution_system_type = HPXML::HVACDistributionTypeDSE
      hpxml_bldg.hvac_distributions[0].annual_heating_dse = 0.8
      hpxml_bldg.hvac_distributions[0].annual_cooling_dse = 0.7
    elsif ['base-hvac-furnace-x3-dse.xml'].include? hpxml_file
      hpxml_bldg.hvac_distributions[0].distribution_system_type = HPXML::HVACDistributionTypeDSE
      hpxml_bldg.hvac_distributions[0].annual_heating_dse = 0.8
      hpxml_bldg.hvac_distributions[0].annual_cooling_dse = 0.7
      hpxml_bldg.hvac_distributions << hpxml_bldg.hvac_distributions[0].dup
      hpxml_bldg.hvac_distributions[1].id = "HVACDistribution#{hpxml_bldg.hvac_distributions.size}"
      hpxml_bldg.hvac_distributions[1].annual_cooling_dse = 1.0
      hpxml_bldg.hvac_distributions << hpxml_bldg.hvac_distributions[0].dup
      hpxml_bldg.hvac_distributions[2].id = "HVACDistribution#{hpxml_bldg.hvac_distributions.size}"
      hpxml_bldg.hvac_distributions[2].annual_cooling_dse = 1.0
      hpxml_bldg.heating_systems[0].primary_system = false
      hpxml_bldg.heating_systems << hpxml_bldg.heating_systems[0].dup
      hpxml_bldg.heating_systems[1].id = "HeatingSystem#{hpxml_bldg.heating_systems.size}"
      hpxml_bldg.heating_systems[1].distribution_system_idref = hpxml_bldg.hvac_distributions[1].id
      hpxml_bldg.heating_systems << hpxml_bldg.heating_systems[0].dup
      hpxml_bldg.heating_systems[2].id = "HeatingSystem#{hpxml_bldg.heating_systems.size}"
      hpxml_bldg.heating_systems[2].distribution_system_idref = hpxml_bldg.hvac_distributions[2].id
      hpxml_bldg.heating_systems[2].primary_system = true
      for i in 0..2
        hpxml_bldg.heating_systems[i].heating_capacity /= 3.0
        # Test a file where sum is slightly greater than 1
        if i < 2
          hpxml_bldg.heating_systems[i].fraction_heat_load_served = 0.33
        else
          hpxml_bldg.heating_systems[i].fraction_heat_load_served = 0.35
        end
      end
    elsif ['base-residents-5-5.xml'].include? hpxml_file
      hpxml_bldg.slabs.each do |slab|
        slab.carpet_fraction = nil
      end
    elsif ['base-enclosure-2stories.xml',
           'base-enclosure-2stories-garage.xml'].include? hpxml_file
      hpxml_bldg.hvac_distributions[0].ducts[2].duct_location = HPXML::LocationExteriorWall
      hpxml_bldg.hvac_distributions[0].ducts[2].duct_insulation_r_value = 4.0
      hpxml_bldg.hvac_distributions[0].ducts[3].duct_location = HPXML::LocationConditionedSpace
      hpxml_bldg.hvac_distributions[0].ducts[3].duct_insulation_r_value = 0
    elsif ['base-hvac-ducts-effective-rvalue.xml'].include? hpxml_file
      hpxml_bldg.hvac_distributions[0].ducts[0].duct_insulation_r_value = nil
      hpxml_bldg.hvac_distributions[0].ducts[1].duct_insulation_r_value = nil
      hpxml_bldg.hvac_distributions[0].ducts[0].duct_effective_r_value = 4.38
      hpxml_bldg.hvac_distributions[0].ducts[1].duct_effective_r_value = 5.0
    elsif ['base-hvac-multiple.xml'].include? hpxml_file
      hpxml_bldg.hvac_distributions.reverse_each do |hvac_distribution|
        hvac_distribution.delete
      end
      hpxml_bldg.hvac_distributions.add(id: "HVACDistribution#{hpxml_bldg.hvac_distributions.size + 1}",
                                        distribution_system_type: HPXML::HVACDistributionTypeAir,
                                        air_type: HPXML::AirTypeRegularVelocity)
      hpxml_bldg.hvac_distributions[0].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeSupply,
                                                                     duct_leakage_units: HPXML::UnitsCFM25,
                                                                     duct_leakage_value: 75,
                                                                     duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
      hpxml_bldg.hvac_distributions[0].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                                     duct_leakage_units: HPXML::UnitsCFM25,
                                                                     duct_leakage_value: 25,
                                                                     duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
      hpxml_bldg.hvac_distributions[0].ducts.add(id: "Ducts#{hpxml_bldg.hvac_distributions[0].ducts.size + 1}",
                                                 duct_type: HPXML::DuctTypeSupply,
                                                 duct_insulation_r_value: 8,
                                                 duct_location: HPXML::LocationAtticUnvented,
                                                 duct_surface_area: 75)
      hpxml_bldg.hvac_distributions[0].ducts.add(id: "Ducts#{hpxml_bldg.hvac_distributions[0].ducts.size + 1}",
                                                 duct_type: HPXML::DuctTypeSupply,
                                                 duct_insulation_r_value: 8,
                                                 duct_location: HPXML::LocationOutside,
                                                 duct_surface_area: 75)
      hpxml_bldg.hvac_distributions[0].ducts.add(id: "Ducts#{hpxml_bldg.hvac_distributions[0].ducts.size + 1}",
                                                 duct_type: HPXML::DuctTypeReturn,
                                                 duct_insulation_r_value: 4,
                                                 duct_location: HPXML::LocationAtticUnvented,
                                                 duct_surface_area: 25)
      hpxml_bldg.hvac_distributions[0].ducts.add(id: "Ducts#{hpxml_bldg.hvac_distributions[0].ducts.size + 1}",
                                                 duct_type: HPXML::DuctTypeReturn,
                                                 duct_insulation_r_value: 4,
                                                 duct_location: HPXML::LocationOutside,
                                                 duct_surface_area: 25)
      hpxml_bldg.hvac_distributions.add(id: "HVACDistribution#{hpxml_bldg.hvac_distributions.size + 1}",
                                        distribution_system_type: HPXML::HVACDistributionTypeAir,
                                        air_type: HPXML::AirTypeRegularVelocity)
      hpxml_bldg.hvac_distributions[-1].duct_leakage_measurements << hpxml_bldg.hvac_distributions[0].duct_leakage_measurements[0].dup
      hpxml_bldg.hvac_distributions[-1].duct_leakage_measurements << hpxml_bldg.hvac_distributions[0].duct_leakage_measurements[1].dup
      for i in 0..3
        hpxml_bldg.hvac_distributions[-1].ducts << hpxml_bldg.hvac_distributions[0].ducts[i].dup
        hpxml_bldg.hvac_distributions[-1].ducts[-1].id = "Ducts#{hpxml_bldg.hvac_distributions[0].ducts.size + i + 1}"
      end
      hpxml_bldg.hvac_distributions.add(id: "HVACDistribution#{hpxml_bldg.hvac_distributions.size + 1}",
                                        distribution_system_type: HPXML::HVACDistributionTypeHydronic,
                                        hydronic_type: HPXML::HydronicTypeBaseboard)
      hpxml_bldg.hvac_distributions.add(id: "HVACDistribution#{hpxml_bldg.hvac_distributions.size + 1}",
                                        distribution_system_type: HPXML::HVACDistributionTypeHydronic,
                                        hydronic_type: HPXML::HydronicTypeBaseboard)
      hpxml_bldg.hvac_distributions.add(id: "HVACDistribution#{hpxml_bldg.hvac_distributions.size + 1}",
                                        distribution_system_type: HPXML::HVACDistributionTypeAir,
                                        air_type: HPXML::AirTypeRegularVelocity)
      hpxml_bldg.hvac_distributions[-1].duct_leakage_measurements << hpxml_bldg.hvac_distributions[0].duct_leakage_measurements[0].dup
      hpxml_bldg.hvac_distributions[-1].duct_leakage_measurements << hpxml_bldg.hvac_distributions[0].duct_leakage_measurements[1].dup
      for i in 0..3
        hpxml_bldg.hvac_distributions[-1].ducts << hpxml_bldg.hvac_distributions[0].ducts[i].dup
        hpxml_bldg.hvac_distributions[-1].ducts[-1].id = "Ducts#{hpxml_bldg.hvac_distributions[0].ducts.size * 2 + i + 1}"
      end
      hpxml_bldg.hvac_distributions.add(id: "HVACDistribution#{hpxml_bldg.hvac_distributions.size + 1}",
                                        distribution_system_type: HPXML::HVACDistributionTypeAir,
                                        air_type: HPXML::AirTypeRegularVelocity)
      hpxml_bldg.hvac_distributions[-1].duct_leakage_measurements << hpxml_bldg.hvac_distributions[0].duct_leakage_measurements[0].dup
      hpxml_bldg.hvac_distributions[-1].duct_leakage_measurements << hpxml_bldg.hvac_distributions[0].duct_leakage_measurements[1].dup
      for i in 0..3
        hpxml_bldg.hvac_distributions[-1].ducts << hpxml_bldg.hvac_distributions[0].ducts[i].dup
        hpxml_bldg.hvac_distributions[-1].ducts[-1].id = "Ducts#{hpxml_bldg.hvac_distributions[0].ducts.size * 3 + i + 1}"
      end
      hpxml_bldg.heating_systems.reverse_each do |heating_system|
        heating_system.delete
      end
      hpxml_bldg.heating_systems.add(id: "HeatingSystem#{hpxml_bldg.heating_systems.size + 1}",
                                     distribution_system_idref: hpxml_bldg.hvac_distributions[0].id,
                                     heating_system_type: HPXML::HVACTypeFurnace,
                                     heating_system_fuel: HPXML::FuelTypeElectricity,
                                     heating_capacity: 6400,
                                     heating_efficiency_afue: 1,
                                     fraction_heat_load_served: 0.1)
      hpxml_bldg.heating_systems.add(id: "HeatingSystem#{hpxml_bldg.heating_systems.size + 1}",
                                     distribution_system_idref: hpxml_bldg.hvac_distributions[1].id,
                                     heating_system_type: HPXML::HVACTypeFurnace,
                                     heating_system_fuel: HPXML::FuelTypeNaturalGas,
                                     heating_capacity: 6400,
                                     heating_efficiency_afue: 0.92,
                                     fraction_heat_load_served: 0.1)
      hpxml_bldg.heating_systems.add(id: "HeatingSystem#{hpxml_bldg.heating_systems.size + 1}",
                                     distribution_system_idref: hpxml_bldg.hvac_distributions[2].id,
                                     heating_system_type: HPXML::HVACTypeBoiler,
                                     heating_system_fuel: HPXML::FuelTypeElectricity,
                                     heating_capacity: 6400,
                                     heating_efficiency_afue: 1,
                                     fraction_heat_load_served: 0.1)
      hpxml_bldg.heating_systems.add(id: "HeatingSystem#{hpxml_bldg.heating_systems.size + 1}",
                                     distribution_system_idref: hpxml_bldg.hvac_distributions[3].id,
                                     heating_system_type: HPXML::HVACTypeBoiler,
                                     heating_system_fuel: HPXML::FuelTypeNaturalGas,
                                     heating_capacity: 6400,
                                     heating_efficiency_afue: 0.92,
                                     fraction_heat_load_served: 0.1,
                                     electric_auxiliary_energy: 200)
      hpxml_bldg.heating_systems.add(id: "HeatingSystem#{hpxml_bldg.heating_systems.size + 1}",
                                     heating_system_type: HPXML::HVACTypeElectricResistance,
                                     heating_system_fuel: HPXML::FuelTypeElectricity,
                                     heating_capacity: 6400,
                                     heating_efficiency_percent: 1,
                                     fraction_heat_load_served: 0.1)
      hpxml_bldg.heating_systems.add(id: "HeatingSystem#{hpxml_bldg.heating_systems.size + 1}",
                                     heating_system_type: HPXML::HVACTypeStove,
                                     heating_system_fuel: HPXML::FuelTypeOil,
                                     heating_capacity: 6400,
                                     heating_efficiency_percent: 0.8,
                                     fraction_heat_load_served: 0.1,
                                     fan_watts: 40.0)
      hpxml_bldg.heating_systems.add(id: "HeatingSystem#{hpxml_bldg.heating_systems.size + 1}",
                                     heating_system_type: HPXML::HVACTypeWallFurnace,
                                     heating_system_fuel: HPXML::FuelTypePropane,
                                     heating_capacity: 6400,
                                     heating_efficiency_afue: 0.8,
                                     fraction_heat_load_served: 0.1,
                                     fan_watts: 0.0)
      hpxml_bldg.cooling_systems[0].distribution_system_idref = hpxml_bldg.hvac_distributions[1].id
      hpxml_bldg.cooling_systems[0].fraction_cool_load_served = 0.1333
      hpxml_bldg.cooling_systems[0].cooling_capacity *= 0.1333
      hpxml_bldg.cooling_systems[0].primary_system = false
      hpxml_bldg.cooling_systems.add(id: "CoolingSystem#{hpxml_bldg.cooling_systems.size + 1}",
                                     cooling_system_type: HPXML::HVACTypeRoomAirConditioner,
                                     cooling_system_fuel: HPXML::FuelTypeElectricity,
                                     cooling_capacity: 9600,
                                     fraction_cool_load_served: 0.1333,
                                     cooling_efficiency_ceer: 8.4)
      hpxml_bldg.cooling_systems.add(id: "CoolingSystem#{hpxml_bldg.cooling_systems.size + 1}",
                                     cooling_system_type: HPXML::HVACTypePTAC,
                                     cooling_system_fuel: HPXML::FuelTypeElectricity,
                                     cooling_capacity: 9600,
                                     fraction_cool_load_served: 0.1333,
                                     cooling_efficiency_eer: 10.7)
      hpxml_bldg.heat_pumps.add(id: "HeatPump#{hpxml_bldg.heat_pumps.size + 1}",
                                distribution_system_idref: hpxml_bldg.hvac_distributions[4].id,
                                heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                                heat_pump_fuel: HPXML::FuelTypeElectricity,
                                heating_capacity: 4800,
                                cooling_capacity: 4800,
                                backup_type: HPXML::HeatPumpBackupTypeIntegrated,
                                backup_heating_fuel: HPXML::FuelTypeElectricity,
                                backup_heating_capacity: 3412,
                                backup_heating_efficiency_percent: 1.0,
                                fraction_heat_load_served: 0.1,
                                fraction_cool_load_served: 0.2,
                                heating_efficiency_hspf2: 7.0,
                                cooling_efficiency_seer2: 13.4,
                                heating_capacity_17F: 4800 * 0.6,
                                compressor_type: HPXML::HVACCompressorTypeSingleStage)
      hpxml_bldg.heat_pumps.add(id: "HeatPump#{hpxml_bldg.heat_pumps.size + 1}",
                                distribution_system_idref: hpxml_bldg.hvac_distributions[5].id,
                                heat_pump_type: HPXML::HVACTypeHeatPumpGroundToAir,
                                heat_pump_fuel: HPXML::FuelTypeElectricity,
                                heating_capacity: 4800,
                                cooling_capacity: 4800,
                                compressor_type: HPXML::HVACCompressorTypeSingleStage,
                                backup_type: HPXML::HeatPumpBackupTypeIntegrated,
                                backup_heating_fuel: HPXML::FuelTypeElectricity,
                                backup_heating_capacity: 3412,
                                backup_heating_efficiency_percent: 1.0,
                                fraction_heat_load_served: 0.1,
                                fraction_cool_load_served: 0.2,
                                heating_efficiency_cop: 3.6,
                                cooling_efficiency_eer: 16.6,
                                pump_watts_per_ton: 100.0)
      hpxml_bldg.heat_pumps.add(id: "HeatPump#{hpxml_bldg.heat_pumps.size + 1}",
                                heat_pump_type: HPXML::HVACTypeHeatPumpMiniSplit,
                                heat_pump_fuel: HPXML::FuelTypeElectricity,
                                heating_capacity: 4800,
                                cooling_capacity: 4800,
                                backup_type: HPXML::HeatPumpBackupTypeIntegrated,
                                backup_heating_fuel: HPXML::FuelTypeElectricity,
                                backup_heating_capacity: 3412,
                                backup_heating_efficiency_percent: 1.0,
                                fraction_heat_load_served: 0.1,
                                fraction_cool_load_served: 0.2,
                                heating_efficiency_hspf2: 9,
                                cooling_efficiency_seer2: 19,
                                heating_capacity_17F: 4800 * 0.6,
                                compressor_type: HPXML::HVACCompressorTypeVariableSpeed,
                                primary_cooling_system: true,
                                primary_heating_system: true)
    elsif ['base-hvac-air-to-air-heat-pump-var-speed-max-power-ratio-schedule-two-systems.xml'].include? hpxml_file
      hpxml_bldg.heat_pumps << hpxml_bldg.heat_pumps[0].dup
      hpxml_bldg.heat_pumps[-1].id += "#{hpxml_bldg.hvac_distributions.size}"
      hpxml_bldg.heat_pumps[-1].primary_cooling_system = false
      hpxml_bldg.heat_pumps[-1].primary_heating_system = false
      hpxml_bldg.heat_pumps[0].fraction_heat_load_served = 0.7
      hpxml_bldg.heat_pumps[0].fraction_cool_load_served = 0.7
      hpxml_bldg.heat_pumps[-1].fraction_heat_load_served = 0.3
      hpxml_bldg.heat_pumps[-1].fraction_cool_load_served = 0.3
      hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served /= 2.0
      hpxml_bldg.hvac_distributions.add(id: "HVACDistribution#{hpxml_bldg.hvac_distributions.size + 1}",
                                        distribution_system_type: HPXML::HVACDistributionTypeAir,
                                        air_type: HPXML::AirTypeRegularVelocity,
                                        conditioned_floor_area_served: hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served)
      hpxml_bldg.hvac_distributions[-1].duct_leakage_measurements << hpxml_bldg.hvac_distributions[0].duct_leakage_measurements[0].dup
      hpxml_bldg.hvac_distributions[-1].duct_leakage_measurements << hpxml_bldg.hvac_distributions[0].duct_leakage_measurements[1].dup
      hpxml_bldg.hvac_distributions[0].ducts.each do |duct|
        hpxml_bldg.hvac_distributions[-1].ducts << duct.dup
        hpxml_bldg.hvac_distributions[-1].ducts[-1].id = "Ducts#{hpxml_bldg.hvac_distributions[0].ducts.size + hpxml_bldg.hvac_distributions[1].ducts.size}"
      end
      hpxml_bldg.heat_pumps[-1].distribution_system_idref = hpxml_bldg.hvac_distributions[-1].id
    elsif ['base-mechvent-multiple.xml',
           'base-bldgtype-mf-unit-shared-mechvent-multiple.xml'].include? hpxml_file
      hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served /= 2.0
      hpxml_bldg.hvac_distributions.add(id: "HVACDistribution#{hpxml_bldg.hvac_distributions.size + 1}",
                                        distribution_system_type: HPXML::HVACDistributionTypeAir,
                                        air_type: HPXML::AirTypeRegularVelocity,
                                        conditioned_floor_area_served: hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served)
      hpxml_bldg.hvac_distributions[1].duct_leakage_measurements << hpxml_bldg.hvac_distributions[0].duct_leakage_measurements[0].dup
      hpxml_bldg.hvac_distributions[1].duct_leakage_measurements << hpxml_bldg.hvac_distributions[0].duct_leakage_measurements[1].dup
      hpxml_bldg.hvac_distributions[0].ducts.each do |duct|
        hpxml_bldg.hvac_distributions[1].ducts << duct.dup
        hpxml_bldg.hvac_distributions[1].ducts[-1].id = "Ducts#{hpxml_bldg.hvac_distributions[0].ducts.size + hpxml_bldg.hvac_distributions[1].ducts.size}"
      end
      hpxml_bldg.heating_systems[0].heating_capacity /= 2.0
      hpxml_bldg.heating_systems[0].fraction_heat_load_served /= 2.0
      hpxml_bldg.heating_systems[0].primary_system = false
      hpxml_bldg.heating_systems << hpxml_bldg.heating_systems[0].dup
      hpxml_bldg.heating_systems[1].id = "HeatingSystem#{hpxml_bldg.heating_systems.size}"
      hpxml_bldg.heating_systems[1].distribution_system_idref = hpxml_bldg.hvac_distributions[1].id
      hpxml_bldg.heating_systems[1].primary_system = true
      hpxml_bldg.cooling_systems[0].fraction_cool_load_served /= 2.0
      hpxml_bldg.cooling_systems[0].cooling_capacity /= 2.0
      hpxml_bldg.cooling_systems[0].primary_system = false
      hpxml_bldg.cooling_systems << hpxml_bldg.cooling_systems[0].dup
      hpxml_bldg.cooling_systems[1].id = "CoolingSystem#{hpxml_bldg.cooling_systems.size}"
      hpxml_bldg.cooling_systems[1].distribution_system_idref = hpxml_bldg.hvac_distributions[1].id
      hpxml_bldg.cooling_systems[1].primary_system = true
    elsif ['base-bldgtype-mf-unit-adjacent-to-multiple.xml'].include? hpxml_file
      hpxml_bldg.hvac_distributions[0].ducts[0].duct_fraction_area = 0.5
      hpxml_bldg.hvac_distributions[0].ducts[1].duct_location = HPXML::LocationOtherHousingUnit
      hpxml_bldg.hvac_distributions[0].ducts[1].duct_fraction_area = 0.5
      hpxml_bldg.hvac_distributions[0].ducts.add(id: "Ducts#{hpxml_bldg.hvac_distributions[0].ducts.size + 1}",
                                                 duct_type: HPXML::DuctTypeSupply,
                                                 duct_insulation_r_value: 4,
                                                 duct_location: HPXML::LocationRoofDeck,
                                                 duct_fraction_area: 0.5)
      hpxml_bldg.hvac_distributions[0].ducts.add(id: "Ducts#{hpxml_bldg.hvac_distributions[0].ducts.size + 1}",
                                                 duct_type: HPXML::DuctTypeReturn,
                                                 duct_insulation_r_value: 0,
                                                 duct_location: HPXML::LocationRoofDeck,
                                                 duct_fraction_area: 0.5)
    elsif ['base-appliances-dehumidifier-multiple.xml'].include? hpxml_file
      hpxml_bldg.dehumidifiers[0].fraction_served = 0.5
      hpxml_bldg.dehumidifiers.add(id: 'Dehumidifier2',
                                   type: HPXML::DehumidifierTypePortable,
                                   capacity: 30,
                                   integrated_energy_factor: 1.9,
                                   rh_setpoint: 0.5,
                                   fraction_served: 0.25,
                                   location: HPXML::LocationConditionedSpace)
    end
    if ['base-hvac-air-to-air-heat-pump-var-speed-backup-furnace.xml',
        'base-hvac-air-to-air-heat-pump-var-speed-backup-furnace-airflow.xml',
        'base-hvac-air-to-air-heat-pump-var-speed-backup-furnace-autosize-factor.xml'].include? hpxml_file
      # Switch backup boiler with hydronic distribution to backup furnace with air distribution
      hpxml_bldg.heating_systems[0].heating_system_type = HPXML::HVACTypeFurnace
      hpxml_bldg.hvac_distributions[0].distribution_system_type = HPXML::HVACDistributionTypeAir
      hpxml_bldg.hvac_distributions[0].air_type = HPXML::AirTypeRegularVelocity
      hpxml_bldg.hvac_distributions[0].duct_leakage_measurements << hpxml_bldg.hvac_distributions[1].duct_leakage_measurements[0].dup
      hpxml_bldg.hvac_distributions[0].duct_leakage_measurements << hpxml_bldg.hvac_distributions[1].duct_leakage_measurements[1].dup
      hpxml_bldg.hvac_distributions[1].ducts.each do |duct|
        hpxml_bldg.hvac_distributions[0].ducts << duct.dup
      end
      (hpxml_bldg.hvac_distributions[0].ducts + hpxml_bldg.hvac_distributions[1].ducts).each_with_index do |duct, i|
        duct.id = "Ducts#{i + 1}"
      end
      hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served = hpxml_bldg.building_construction.conditioned_floor_area
    end
    if ['base-hvac-ducts-areas.xml'].include? hpxml_file
      hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served = nil
      hpxml_bldg.hvac_distributions[0].ducts[0].duct_fraction_area = nil
      hpxml_bldg.hvac_distributions[0].ducts[1].duct_fraction_area = nil
      hpxml_bldg.hvac_distributions[0].ducts[0].duct_surface_area = 150.0
      hpxml_bldg.hvac_distributions[0].ducts[1].duct_surface_area = 50.0
      hpxml_bldg.hvac_distributions[0].ducts[-1].delete
      hpxml_bldg.hvac_distributions[0].ducts[-1].delete
    end
    if ['base-hvac-ducts-area-multipliers.xml'].include? hpxml_file
      hpxml_bldg.hvac_distributions[0].ducts[0].duct_surface_area_multiplier = 0.5
      hpxml_bldg.hvac_distributions[0].ducts[1].duct_surface_area_multiplier = 1.5
    end
    if hpxml_file.include? 'heating-capacity-17f'
      hpxml_bldg.heat_pumps[0].heating_capacity_17F = hpxml_bldg.heat_pumps[0].heating_capacity * 0.6
      hpxml_bldg.heat_pumps[0].heating_capacity_fraction_17F = nil
    end
    if hpxml_file.include?('mini-split-air-conditioner-only-ducted') || hpxml_file.include?('mini-split-heat-pump-ducted')
      hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served = nil
      hpxml_bldg.hvac_distributions[0].duct_leakage_measurements[0].duct_leakage_value = 15.0
      hpxml_bldg.hvac_distributions[0].duct_leakage_measurements[1].duct_leakage_value = 5.0
      hpxml_bldg.hvac_distributions[0].ducts[0].duct_fraction_area = nil
      hpxml_bldg.hvac_distributions[0].ducts[1].duct_fraction_area = nil
      hpxml_bldg.hvac_distributions[0].ducts[0].duct_surface_area = 30.0
      hpxml_bldg.hvac_distributions[0].ducts[1].duct_surface_area = 10.0
      hpxml_bldg.hvac_distributions[0].ducts[0].duct_insulation_r_value = 0.0
      hpxml_bldg.hvac_distributions[0].ducts[1].duct_insulation_r_value = 0.0
      hpxml_bldg.hvac_distributions[0].ducts[-1].delete
      hpxml_bldg.hvac_distributions[0].ducts[-1].delete
    end
    hpxml_bldg.heating_systems.each do |heating_system|
      if heating_system.heating_system_type == HPXML::HVACTypeBoiler &&
         heating_system.heating_system_fuel == HPXML::FuelTypeNaturalGas &&
         !heating_system.is_shared_system
        heating_system.electric_auxiliary_energy = 200
      elsif hpxml_file.include? 'eae'
        heating_system.electric_auxiliary_energy = 500
      else
        heating_system.electric_auxiliary_energy = nil
      end
      if [HPXML::HVACTypeFloorFurnace,
          HPXML::HVACTypeWallFurnace,
          HPXML::HVACTypeFireplace,
          HPXML::HVACTypeSpaceHeater].include? heating_system.heating_system_type
        heating_system.fan_watts = 0
      elsif [HPXML::HVACTypeStove].include? heating_system.heating_system_type
        heating_system.fan_watts = 40
      end
    end
    if hpxml_file.include? 'heat-pump'
      if hpxml_file.include? 'cooling-only'
        hpxml_bldg.heat_pumps[0].heating_capacity = 0
      elsif hpxml_file.include? 'heating-only'
        hpxml_bldg.heat_pumps[0].cooling_capacity = 0
      end
    end
    if hpxml_file.include? 'base-hvac-install-quality'
      hpxml_bldg.hvac_systems.each do |hvac_system|
        hvac_system.fan_watts_per_cfm = 0.365
        hvac_system.airflow_defect_ratio = -0.25
        if hvac_system.respond_to? :charge_defect_ratio
          hvac_system.charge_defect_ratio = -0.25
        end
        if hvac_system.respond_to? :heating_design_airflow_cfm
          if not hvac_system.heating_capacity.nil?
            heating_capacity_tons = UnitConversions.convert(hvac_system.heating_capacity, 'Btu/hr', 'ton')
          else
            nom_dp_47F = hvac_system.heating_detailed_performance_data.find { |dp| dp.capacity_description == HPXML::CapacityDescriptionNominal && dp.outdoor_temperature == 47.0 }
            heating_capacity_tons = UnitConversions.convert(nom_dp_47F.capacity, 'Btu/hr', 'ton')
          end
          if hvac_system.is_a?(HPXML::HeatingSystem) && hvac_system.heating_system_type == HPXML::HVACTypeFurnace
            hvac_system.heating_design_airflow_cfm = (240 * heating_capacity_tons).round
          else
            hvac_system.heating_design_airflow_cfm = (360 * heating_capacity_tons).round
          end
        end
        next unless hvac_system.respond_to? :cooling_design_airflow_cfm

        if not hvac_system.cooling_capacity.nil?
          cooling_capacity_tons = UnitConversions.convert(hvac_system.cooling_capacity, 'Btu/hr', 'ton')
        else
          nom_dp_95F = hvac_system.cooling_detailed_performance_data.find { |dp| dp.capacity_description == HPXML::CapacityDescriptionNominal && dp.outdoor_temperature == 95.0 }
          cooling_capacity_tons = UnitConversions.convert(nom_dp_95F.capacity, 'Btu/hr', 'ton')
        end
        hvac_system.cooling_design_airflow_cfm = (360 * cooling_capacity_tons).round
      end
    end
    if hpxml_file.include? 'defrost-with-backup-heat-active'
      hpxml_bldg.heat_pumps.each do |heat_pump|
        heat_pump.backup_heating_active_during_defrost = true
      end
    end
    if hpxml_file.include? 'pan-heater'
      if hpxml_file.include? 'pan-heater-none'
        hpxml_bldg.heat_pumps[0].pan_heater_watts = 0.0
      else
        hpxml_bldg.heat_pumps[0].pan_heater_watts = 100.0
        if hpxml_file.include? 'pan-heater-continuous-mode'
          hpxml_bldg.heat_pumps[0].pan_heater_control_type = HPXML::HVACPanHeaterControlTypeContinuous
        elsif hpxml_file.include? 'pan-heater-defrost-mode'
          hpxml_bldg.heat_pumps[0].pan_heater_control_type = HPXML::HVACPanHeaterControlTypeDefrost
        end
      end
    end
    if ['base-hvac-fan-motor-type.xml'].include? hpxml_file
      hpxml_bldg.heating_systems[0].fan_motor_type = HPXML::HVACFanMotorTypeBPM
      hpxml_bldg.cooling_systems[0].fan_motor_type = HPXML::HVACFanMotorTypeBPM
    end
    if ['base-hvac-ducts-shape-round.xml'].include? hpxml_file
      hpxml_bldg.hvac_distributions[0].ducts.each do |duct|
        next if duct.duct_location == HPXML::LocationConditionedSpace

        duct.duct_shape = HPXML::DuctShapeRound
      end
    elsif ['base-hvac-ducts-shape-rectangular.xml'].include? hpxml_file
      hpxml_bldg.hvac_distributions[0].ducts.each do |duct|
        next if duct.duct_location == HPXML::LocationConditionedSpace

        duct.duct_shape = HPXML::DuctShapeRectangular
      end
    end
    if ['base-hvac-ducts-buried.xml'].include? hpxml_file
      hpxml_bldg.hvac_distributions[0].ducts.each do |duct|
        next if duct.duct_location == HPXML::LocationConditionedSpace

        duct.duct_buried_insulation_level = HPXML::DuctBuriedInsulationDeep
      end
    end
    if hpxml_file.include?('mini-split') && hpxml_file.include?('ducted')
      hpxml_bldg.cooling_systems.each do |cooling_system|
        cooling_system.cooling_system_type = HPXML::HVACTypeMiniSplitAirConditioner
        cooling_system.compressor_type = HPXML::HVACCompressorTypeVariableSpeed
      end
      hpxml_bldg.heat_pumps.each do |heat_pump|
        heat_pump.heat_pump_type = HPXML::HVACTypeHeatPumpMiniSplit
        heat_pump.compressor_type = HPXML::HVACCompressorTypeVariableSpeed
      end
    end
    if ['base-hvac-ptac-with-heating-electricity.xml',
        'base-hvac-ptac-with-heating-natural-gas.xml',
        'base-hvac-room-ac-with-heating.xml'].include? hpxml_file
      if hpxml_file == 'base-hvac-ptac-with-heating-natural-gas.xml'
        hpxml_bldg.cooling_systems[0].integrated_heating_system_fuel = HPXML::FuelTypeNaturalGas
        hpxml_bldg.cooling_systems[0].integrated_heating_system_efficiency_percent = 0.8
      else
        hpxml_bldg.cooling_systems[0].integrated_heating_system_fuel = HPXML::FuelTypeElectricity
        hpxml_bldg.cooling_systems[0].integrated_heating_system_efficiency_percent = 1.0
      end
      hpxml_bldg.cooling_systems[0].integrated_heating_system_capacity = 40000.0
      hpxml_bldg.cooling_systems[0].integrated_heating_system_fraction_heat_load_served = 1.0
      hpxml_bldg.hvac_controls[0].heating_setpoint_temp = 68.0
    end
    if hpxml_file.include? 'evap-cooler-only-ducted'
      hpxml_bldg.cooling_systems[0].cooling_system_type = HPXML::HVACTypeEvaporativeCooler
      hpxml_bldg.cooling_systems[0].compressor_type = nil
      hpxml_bldg.cooling_systems[0].cooling_efficiency_seer2 = nil
      hpxml_bldg.hvac_distributions[0].duct_leakage_measurements[1].duct_leakage_value = 0.0
      hpxml_bldg.hvac_distributions[0].ducts[3].delete
      hpxml_bldg.hvac_distributions[0].ducts[1].delete
      hpxml_bldg.hvac_distributions[0].ducts[1].id = "Ducts#{hpxml_bldg.hvac_distributions[0].ducts.size}"
    end
    if ['base-hvac-room-ac-only-eer.xml'].include? hpxml_file
      hpxml_bldg.cooling_systems[0].cooling_efficiency_ceer = nil
      hpxml_bldg.cooling_systems[0].cooling_efficiency_eer = 8.5
    end
    if ['base-hvac-central-ac-only-1-speed-seer.xml'].include? hpxml_file
      hpxml_bldg.cooling_systems[0].cooling_efficiency_seer2 = nil
      hpxml_bldg.cooling_systems[0].cooling_efficiency_seer = 13.0
    end
    if ['base-hvac-air-to-air-heat-pump-1-speed-seer-hspf.xml'].include? hpxml_file
      hpxml_bldg.heat_pumps[0].cooling_efficiency_seer2 = nil
      hpxml_bldg.heat_pumps[0].cooling_efficiency_seer = 13.0
      hpxml_bldg.heat_pumps[0].heating_efficiency_hspf2 = nil
      hpxml_bldg.heat_pumps[0].heating_efficiency_hspf = 7.7
    end

    # ------------------ #
    # HPXML WaterHeating #
    # ------------------ #

    if ['base-misc-defaults.xml'].include? hpxml_file
      hpxml_bldg.hot_water_distributions[0].pipe_r_value = nil
      hpxml_bldg.solar_thermal_systems[0].storage_volume = nil
    elsif ['base-schedules-simple.xml',
           'base-schedules-simple-vacancy.xml',
           'base-schedules-simple-power-outage.xml',
           'base-misc-loads-large-uncommon.xml',
           'base-misc-loads-large-uncommon2.xml'].include? hpxml_file
      hpxml_bldg.water_heating.water_fixtures_weekday_fractions = '0.012, 0.006, 0.004, 0.005, 0.010, 0.034, 0.078, 0.087, 0.080, 0.067, 0.056, 0.047, 0.040, 0.035, 0.033, 0.031, 0.039, 0.051, 0.060, 0.060, 0.055, 0.048, 0.038, 0.026'
      hpxml_bldg.water_heating.water_fixtures_weekend_fractions = '0.012, 0.006, 0.004, 0.005, 0.010, 0.034, 0.078, 0.087, 0.080, 0.067, 0.056, 0.047, 0.040, 0.035, 0.033, 0.031, 0.039, 0.051, 0.060, 0.060, 0.055, 0.048, 0.038, 0.026'
      hpxml_bldg.water_heating.water_fixtures_monthly_multipliers = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
    elsif ['base-bldgtype-mf-unit-shared-water-heater-recirc.xml',
           'base-bldgtype-mf-unit-shared-water-heater-recirc-beds-0.xml',
           'base-bldgtype-mf-unit-shared-water-heater-recirc-scheduled.xml'].include? hpxml_file
      hpxml_bldg.hot_water_distributions[0].has_shared_recirculation = true
      hpxml_bldg.hot_water_distributions[0].shared_recirculation_number_of_bedrooms_served = 18
      hpxml_bldg.hot_water_distributions[0].shared_recirculation_pump_power = 220
      hpxml_bldg.hot_water_distributions[0].shared_recirculation_control_type = HPXML::DHWRecircControlTypeTimer
      if hpxml_file == 'base-bldgtype-mf-unit-shared-water-heater-recirc-beds-0.xml'
        hpxml_bldg.hot_water_distributions[0].shared_recirculation_number_of_bedrooms_served = 6
      end
    elsif ['base-bldgtype-mf-unit-shared-laundry-room.xml',
           'base-bldgtype-mf-unit-shared-laundry-room-multiple-water-heaters.xml'].include? hpxml_file
      hpxml_bldg.water_heating_systems.reverse_each do |water_heating_system|
        water_heating_system.delete
      end
      hpxml_bldg.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml_bldg.water_heating_systems.size + 1}",
                                           is_shared_system: true,
                                           number_of_bedrooms_served: 18,
                                           fuel_type: HPXML::FuelTypeNaturalGas,
                                           water_heater_type: HPXML::WaterHeaterTypeStorage,
                                           location: HPXML::LocationConditionedSpace,
                                           tank_volume: 120,
                                           fraction_dhw_load_served: 1.0,
                                           heating_capacity: 40000,
                                           energy_factor: 0.59,
                                           recovery_efficiency: 0.76,
                                           temperature: 125.0)
      if hpxml_file == 'base-bldgtype-mf-unit-shared-laundry-room-multiple-water-heaters.xml'
        hpxml_bldg.water_heating_systems[0].fraction_dhw_load_served /= 2.0
        hpxml_bldg.water_heating_systems[0].tank_volume /= 2.0
        hpxml_bldg.water_heating_systems[0].number_of_bedrooms_served /= 2.0
        hpxml_bldg.water_heating_systems << hpxml_bldg.water_heating_systems[0].dup
        hpxml_bldg.water_heating_systems[1].id = "WaterHeatingSystem#{hpxml_bldg.water_heating_systems.size}"
      end
    elsif ['base-dhw-tank-gas-fhr.xml'].include? hpxml_file
      hpxml_bldg.water_heating_systems[0].first_hour_rating = 56.0
      hpxml_bldg.water_heating_systems[0].usage_bin = nil
    elsif ['base-dhw-tank-heat-pump-confined-space.xml'].include? hpxml_file
      hpxml_bldg.water_heating_systems[0].hpwh_confined_space_without_mitigation = true
      hpxml_bldg.water_heating_systems[0].hpwh_containment_volume = 453
    elsif ['base-dhw-tankless-electric-outside.xml'].include? hpxml_file
      hpxml_bldg.water_heating_systems[0].performance_adjustment = 0.92
    elsif ['base-dhw-multiple.xml'].include? hpxml_file
      hpxml_bldg.water_heating_systems[0].fraction_dhw_load_served = 0.2
      hpxml_bldg.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml_bldg.water_heating_systems.size + 1}",
                                           fuel_type: HPXML::FuelTypeNaturalGas,
                                           water_heater_type: HPXML::WaterHeaterTypeStorage,
                                           location: HPXML::LocationConditionedSpace,
                                           tank_volume: 50,
                                           fraction_dhw_load_served: 0.2,
                                           heating_capacity: 40000,
                                           energy_factor: 0.59,
                                           recovery_efficiency: 0.76,
                                           temperature: 125.0)
      hpxml_bldg.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml_bldg.water_heating_systems.size + 1}",
                                           fuel_type: HPXML::FuelTypeElectricity,
                                           water_heater_type: HPXML::WaterHeaterTypeHeatPump,
                                           location: HPXML::LocationConditionedSpace,
                                           tank_volume: 80,
                                           fraction_dhw_load_served: 0.2,
                                           energy_factor: 2.3,
                                           temperature: 125.0)
      hpxml_bldg.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml_bldg.water_heating_systems.size + 1}",
                                           fuel_type: HPXML::FuelTypeElectricity,
                                           water_heater_type: HPXML::WaterHeaterTypeTankless,
                                           location: HPXML::LocationConditionedSpace,
                                           fraction_dhw_load_served: 0.2,
                                           energy_factor: 0.99,
                                           temperature: 125.0)
      hpxml_bldg.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml_bldg.water_heating_systems.size + 1}",
                                           fuel_type: HPXML::FuelTypeNaturalGas,
                                           water_heater_type: HPXML::WaterHeaterTypeTankless,
                                           location: HPXML::LocationConditionedSpace,
                                           fraction_dhw_load_served: 0.1,
                                           energy_factor: 0.82,
                                           temperature: 125.0)
      hpxml_bldg.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml_bldg.water_heating_systems.size + 1}",
                                           water_heater_type: HPXML::WaterHeaterTypeCombiStorage,
                                           location: HPXML::LocationConditionedSpace,
                                           tank_volume: 50,
                                           fraction_dhw_load_served: 0.1,
                                           related_hvac_idref: 'HeatingSystem1',
                                           temperature: 125.0)
      hpxml_bldg.solar_thermal_systems.add(id: "SolarThermalSystem#{hpxml_bldg.solar_thermal_systems.size + 1}",
                                           system_type: HPXML::SolarThermalSystemTypeHotWater,
                                           water_heating_system_idref: nil, # Apply to all water heaters
                                           solar_fraction: 0.65)
    end
    if ['base-dhw-low-flow-fixtures.xml'].include? hpxml_file
      hpxml_bldg.water_fixtures[0].count = 2
      hpxml_bldg.water_fixtures[1].low_flow = nil
      hpxml_bldg.water_fixtures[1].flow_rate = 2.0
      hpxml_bldg.water_fixtures[1].count = 3
    end
    if ['base-dhw-recirc-demand-scheduled.xml',
        'base-schedules-simple.xml',
        'base-schedules-simple-vacancy.xml',
        'base-schedules-simple-power-outage.xml'].include? hpxml_file
      hpxml_bldg.hot_water_distributions[0].recirculation_pump_weekday_fractions = default_schedules_csv_data["#{SchedulesFile::Columns[:HotWaterRecirculationPump].name}_demand_control"]['RecirculationPumpWeekdayScheduleFractions']
      hpxml_bldg.hot_water_distributions[0].recirculation_pump_weekend_fractions = default_schedules_csv_data["#{SchedulesFile::Columns[:HotWaterRecirculationPump].name}_demand_control"]['RecirculationPumpWeekendScheduleFractions']
      hpxml_bldg.hot_water_distributions[0].recirculation_pump_monthly_multipliers = default_schedules_csv_data[SchedulesFile::Columns[:HotWaterRecirculationPump].name]['RecirculationPumpMonthlyScheduleMultipliers']
    elsif ['base-bldgtype-mf-unit-shared-water-heater-recirc-scheduled.xml'].include? hpxml_file
      hpxml_bldg.hot_water_distributions[0].recirculation_pump_weekday_fractions = default_schedules_csv_data["#{SchedulesFile::Columns[:HotWaterRecirculationPump].name}_no_control"]['RecirculationPumpWeekdayScheduleFractions']
      hpxml_bldg.hot_water_distributions[0].recirculation_pump_weekend_fractions = default_schedules_csv_data["#{SchedulesFile::Columns[:HotWaterRecirculationPump].name}_no_control"]['RecirculationPumpWeekendScheduleFractions']
      hpxml_bldg.hot_water_distributions[0].recirculation_pump_monthly_multipliers = default_schedules_csv_data[SchedulesFile::Columns[:HotWaterRecirculationPump].name]['RecirculationPumpMonthlyScheduleMultipliers']
    end
    if hpxml_file.include? 'shared-water-heater'
      hpxml_bldg.water_heating_systems[0].is_shared_system = true
      hpxml_bldg.water_heating_systems[0].tank_volume = 120
      hpxml_bldg.water_heating_systems[0].number_of_bedrooms_served = 18
    end
    if ['base-bldgtype-mf-unit-shared-water-heater-recirc-beds-0.xml'].include? hpxml_file
      hpxml_bldg.water_heating_systems[0].number_of_bedrooms_served = 6
    end
    if ['base-dhw-indirect-standbyloss.xml'].include? hpxml_file
      hpxml_bldg.water_heating_systems[0].standby_loss_units = HPXML::UnitsDegFPerHour
      hpxml_bldg.water_heating_systems[0].standby_loss_value = 1.0
    end
    if ['base-dhw-tank-heat-pump-capacities.xml'].include? hpxml_file
      hpxml_bldg.water_heating_systems[0].heating_capacity = 3000
      hpxml_bldg.water_heating_systems[0].backup_heating_capacity = 0
    end
    if ['base-dhw-tank-heat-pump-operating-mode-heat-pump-only.xml'].include? hpxml_file
      hpxml_bldg.water_heating_systems[0].operating_mode = HPXML::WaterHeaterOperatingModeHeatPumpOnly
    end
    if hpxml_file.include? 'base-dhw-tank-model-type-stratified'
      hpxml_bldg.water_heating_systems[0].tank_model_type = HPXML::WaterHeaterTankModelTypeStratified
    end
    if hpxml_file.include? 'dhw-jacket'
      hpxml_bldg.water_heating_systems[0].jacket_r_value = 10.0
    end
    if hpxml_file.include? 'dhw-desuperheater'
      hpxml_bldg.water_heating_systems[0].uses_desuperheater = true
      hpxml_bldg.cooling_systems.each do |cooling_system|
        next unless [HPXML::HVACTypeCentralAirConditioner,
                     HPXML::HVACTypeMiniSplitAirConditioner].include? cooling_system.cooling_system_type

        hpxml_bldg.water_heating_systems[0].related_hvac_idref = cooling_system.id
      end
      hpxml_bldg.heat_pumps.each do |heat_pump|
        next unless [HPXML::HVACTypeHeatPumpAirToAir,
                     HPXML::HVACTypeHeatPumpMiniSplit,
                     HPXML::HVACTypeHeatPumpGroundToAir].include? heat_pump.heat_pump_type

        hpxml_bldg.water_heating_systems[0].related_hvac_idref = heat_pump.id
      end
    end

    # -------------------- #
    # HPXML VentilationFan #
    # -------------------- #

    if ['base-misc-defaults.xml',
        'base-residents-5-5.xml'].include? hpxml_file
      vent_fan = hpxml_bldg.ventilation_fans.select { |f| f.used_for_seasonal_cooling_load_reduction }[0]
      vent_fan.fan_power = nil
      vent_fan.rated_flow_rate = nil
    end
    if ['base-mechvent-balanced.xml',
        'base-mechvent-erv.xml',
        'base-mechvent-erv-atre-asre.xml',
        'base-mechvent-hrv.xml',
        'base-mechvent-hrv-asre.xml',
        'base-mechvent-supply.xml',
        'base-mechvent-exhaust.xml'].include? hpxml_file
      hpxml_bldg.ventilation_fans[0].rated_flow_rate = 110.0
      hpxml_bldg.ventilation_fans[0].hours_in_operation = 24
      if hpxml_bldg.ventilation_fans[0].is_balanced
        hpxml_bldg.ventilation_fans[0].fan_power = 60.0
      else
        hpxml_bldg.ventilation_fans[0].fan_power = 30.0
      end
      if hpxml_file.include? 'atre'
        hpxml_bldg.ventilation_fans[0].total_recovery_efficiency_adjusted = 1.1 * hpxml_bldg.ventilation_fans[0].total_recovery_efficiency
        hpxml_bldg.ventilation_fans[0].total_recovery_efficiency = nil
      end
      if hpxml_file.include? 'asre'
        hpxml_bldg.ventilation_fans[0].sensible_recovery_efficiency_adjusted = 1.1 * hpxml_bldg.ventilation_fans[0].sensible_recovery_efficiency
        hpxml_bldg.ventilation_fans[0].sensible_recovery_efficiency = nil
      end
    elsif hpxml_file.include? 'base-mechvent-cfis'
      if not hpxml_bldg.ventilation_fans.empty? # FIXME: Temporary
        hpxml_bldg.ventilation_fans[0].rated_flow_rate = 330.0
        hpxml_bldg.ventilation_fans[0].hours_in_operation = 8
        hpxml_bldg.ventilation_fans[0].fan_power = 300.0
      end
    elsif ['base-hvac-ptac-cfis.xml',
           'base-hvac-pthp-cfis.xml'].include? hpxml_file
      hpxml_bldg.ventilation_fans[0].rated_flow_rate = 100.0
      hpxml_bldg.ventilation_fans[0].hours_in_operation = 8
      hpxml_bldg.ventilation_fans[0].fan_power = 100.0
    end
    if ['base-bldgtype-mf-unit-shared-mechvent.xml',
        'base-bldgtype-mf-unit-shared-mechvent-preconditioning.xml'].include? hpxml_file
      hpxml_bldg.ventilation_fans[0].is_shared_system = true
      hpxml_bldg.ventilation_fans[0].in_unit_flow_rate = 80.0
      hpxml_bldg.ventilation_fans[0].rated_flow_rate = 800.0
      hpxml_bldg.ventilation_fans[0].hours_in_operation = 24
      hpxml_bldg.ventilation_fans[0].fan_power = 240.0
      hpxml_bldg.ventilation_fans[0].fraction_recirculation = 0.5
      if hpxml_file == 'base-bldgtype-mf-unit-shared-mechvent-preconditioning.xml'
        hpxml_bldg.ventilation_fans[0].preheating_fuel = HPXML::FuelTypeNaturalGas
        hpxml_bldg.ventilation_fans[0].preheating_efficiency_cop = 0.92
        hpxml_bldg.ventilation_fans[0].preheating_fraction_load_served = 0.7
        hpxml_bldg.ventilation_fans[0].precooling_fuel = HPXML::FuelTypeElectricity
        hpxml_bldg.ventilation_fans[0].precooling_efficiency_cop = 4.0
        hpxml_bldg.ventilation_fans[0].precooling_fraction_load_served = 0.8
      end
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      fan_type: HPXML::MechVentTypeExhaust,
                                      rated_flow_rate: 72.0,
                                      hours_in_operation: 24,
                                      fan_power: 26.0,
                                      used_for_whole_building_ventilation: true)
    elsif ['base-bldgtype-mf-unit-shared-mechvent-multiple.xml'].include? hpxml_file
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      fan_type: HPXML::MechVentTypeSupply,
                                      is_shared_system: true,
                                      in_unit_flow_rate: 100,
                                      calculated_flow_rate: 1000,
                                      hours_in_operation: 24,
                                      fan_power: 300,
                                      used_for_whole_building_ventilation: true,
                                      fraction_recirculation: 0.0,
                                      preheating_fuel: HPXML::FuelTypeNaturalGas,
                                      preheating_efficiency_cop: 0.92,
                                      preheating_fraction_load_served: 0.8,
                                      precooling_fuel: HPXML::FuelTypeElectricity,
                                      precooling_efficiency_cop: 4.0,
                                      precooling_fraction_load_served: 0.8)
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      fan_type: HPXML::MechVentTypeERV,
                                      is_shared_system: true,
                                      in_unit_flow_rate: 50,
                                      delivered_ventilation: 500,
                                      hours_in_operation: 24,
                                      total_recovery_efficiency: 0.48,
                                      sensible_recovery_efficiency: 0.72,
                                      fan_power: 150,
                                      used_for_whole_building_ventilation: true,
                                      fraction_recirculation: 0.4,
                                      preheating_fuel: HPXML::FuelTypeNaturalGas,
                                      preheating_efficiency_cop: 0.87,
                                      preheating_fraction_load_served: 1.0,
                                      precooling_fuel: HPXML::FuelTypeElectricity,
                                      precooling_efficiency_cop: 3.5,
                                      precooling_fraction_load_served: 1.0)
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      fan_type: HPXML::MechVentTypeHRV,
                                      is_shared_system: true,
                                      in_unit_flow_rate: 50,
                                      rated_flow_rate: 500,
                                      hours_in_operation: 24,
                                      sensible_recovery_efficiency: 0.72,
                                      fan_power: 150,
                                      used_for_whole_building_ventilation: true,
                                      fraction_recirculation: 0.3,
                                      preheating_fuel: HPXML::FuelTypeElectricity,
                                      preheating_efficiency_cop: 4.0,
                                      precooling_fuel: HPXML::FuelTypeElectricity,
                                      precooling_efficiency_cop: 4.5,
                                      preheating_fraction_load_served: 1.0,
                                      precooling_fraction_load_served: 1.0)
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      fan_type: HPXML::MechVentTypeBalanced,
                                      is_shared_system: true,
                                      in_unit_flow_rate: 30,
                                      tested_flow_rate: 300,
                                      hours_in_operation: 24,
                                      fan_power: 150,
                                      used_for_whole_building_ventilation: true,
                                      fraction_recirculation: 0.3,
                                      preheating_fuel: HPXML::FuelTypeElectricity,
                                      preheating_efficiency_cop: 3.5,
                                      precooling_fuel: HPXML::FuelTypeElectricity,
                                      precooling_efficiency_cop: 4.0,
                                      preheating_fraction_load_served: 0.9,
                                      precooling_fraction_load_served: 1.0)
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      fan_type: HPXML::MechVentTypeExhaust,
                                      is_shared_system: true,
                                      in_unit_flow_rate: 70,
                                      rated_flow_rate: 700,
                                      hours_in_operation: 8,
                                      fan_power: 300,
                                      used_for_whole_building_ventilation: true,
                                      fraction_recirculation: 0.0)
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      fan_type: HPXML::MechVentTypeExhaust,
                                      tested_flow_rate: 50,
                                      hours_in_operation: 14,
                                      fan_power: 10,
                                      used_for_whole_building_ventilation: true)
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      fan_type: HPXML::MechVentTypeCFIS,
                                      tested_flow_rate: 160,
                                      hours_in_operation: 8,
                                      fan_power: 150,
                                      used_for_whole_building_ventilation: true,
                                      cfis_addtl_runtime_operating_mode: HPXML::CFISModeAirHandler,
                                      distribution_system_idref: 'HVACDistribution1')
    elsif ['base-mechvent-multiple.xml'].include? hpxml_file
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      rated_flow_rate: 2000,
                                      fan_power: 150,
                                      used_for_seasonal_cooling_load_reduction: true)
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      fan_type: HPXML::MechVentTypeSupply,
                                      tested_flow_rate: 12.5,
                                      hours_in_operation: 14,
                                      fan_power: 2.5,
                                      used_for_whole_building_ventilation: true)
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      fan_type: HPXML::MechVentTypeExhaust,
                                      tested_flow_rate: 30.0,
                                      fan_power: 7.5,
                                      used_for_whole_building_ventilation: true)
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      fan_type: HPXML::MechVentTypeBalanced,
                                      tested_flow_rate: 27.5,
                                      hours_in_operation: 24,
                                      fan_power: 15,
                                      used_for_whole_building_ventilation: true)
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      fan_type: HPXML::MechVentTypeERV,
                                      tested_flow_rate: 12.5,
                                      hours_in_operation: 24,
                                      total_recovery_efficiency: 0.48,
                                      sensible_recovery_efficiency: 0.72,
                                      fan_power: 6.25,
                                      used_for_whole_building_ventilation: true)
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      fan_type: HPXML::MechVentTypeHRV,
                                      tested_flow_rate: 15,
                                      hours_in_operation: 24,
                                      sensible_recovery_efficiency: 0.72,
                                      fan_power: 7.5,
                                      used_for_whole_building_ventilation: true)
      hpxml_bldg.ventilation_fans.reverse_each do |vent_fan|
        vent_fan.fan_power /= 2.0
        vent_fan.rated_flow_rate /= 2.0 unless vent_fan.rated_flow_rate.nil?
        vent_fan.tested_flow_rate /= 2.0 unless vent_fan.tested_flow_rate.nil?
        hpxml_bldg.ventilation_fans << vent_fan.dup
        hpxml_bldg.ventilation_fans[-1].id = "VentilationFan#{hpxml_bldg.ventilation_fans.size}"
        hpxml_bldg.ventilation_fans[-1].start_hour = vent_fan.start_hour - 1 unless vent_fan.start_hour.nil?
        hpxml_bldg.ventilation_fans[-1].hours_in_operation = vent_fan.hours_in_operation - 1 unless vent_fan.hours_in_operation.nil?
      end
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      fan_type: HPXML::MechVentTypeCFIS,
                                      tested_flow_rate: 40,
                                      hours_in_operation: 8,
                                      fan_power: 37.5,
                                      used_for_whole_building_ventilation: true,
                                      cfis_addtl_runtime_operating_mode: HPXML::CFISModeAirHandler,
                                      distribution_system_idref: 'HVACDistribution1')
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      fan_type: HPXML::MechVentTypeCFIS,
                                      tested_flow_rate: 42.5,
                                      hours_in_operation: 8,
                                      used_for_whole_building_ventilation: true,
                                      cfis_addtl_runtime_operating_mode: HPXML::CFISModeSupplementalFan,
                                      cfis_supplemental_fan_idref: hpxml_bldg.ventilation_fans.find { |f| f.fan_type == HPXML::MechVentTypeExhaust }.id,
                                      distribution_system_idref: 'HVACDistribution2')
      # Test ventilation system w/ zero airflow and hours
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      fan_type: HPXML::MechVentTypeHRV,
                                      tested_flow_rate: 0,
                                      hours_in_operation: 24,
                                      sensible_recovery_efficiency: 0.72,
                                      fan_power: 7.5,
                                      used_for_whole_building_ventilation: true)
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      fan_type: HPXML::MechVentTypeHRV,
                                      tested_flow_rate: 15,
                                      hours_in_operation: 0,
                                      sensible_recovery_efficiency: 0.72,
                                      fan_power: 7.5,
                                      used_for_whole_building_ventilation: true)
    elsif ['base-mechvent-cfis-airflow-fraction-zero.xml'].include? hpxml_file
      hpxml_bldg.ventilation_fans[0].cfis_vent_mode_airflow_fraction = 0.0
    elsif ['base-mechvent-cfis-control-type-timer.xml'].include? hpxml_file
      hpxml_bldg.ventilation_fans[0].cfis_control_type = HPXML::CFISControlTypeTimer
    elsif ['base-mechvent-cfis-no-additional-runtime.xml'].include? hpxml_file
      hpxml_bldg.ventilation_fans[0].cfis_addtl_runtime_operating_mode = HPXML::CFISModeNone
      hpxml_bldg.ventilation_fans[0].fan_power = nil
    elsif ['base-mechvent-cfis-no-outdoor-air-control.xml'].include? hpxml_file
      hpxml_bldg.ventilation_fans[0].cfis_has_outdoor_air_control = false
    elsif ['base-mechvent-cfis-supplemental-fan-exhaust.xml',
           'base-mechvent-cfis-supplemental-fan-exhaust-15-mins.xml',
           'base-mechvent-cfis-supplemental-fan-supply.xml',
           'base-mechvent-cfis-supplemental-fan-exhaust-synchronized.xml'].include? hpxml_file
      hpxml_bldg.ventilation_fans[0].fan_power = nil
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      tested_flow_rate: 120,
                                      fan_power: 30,
                                      used_for_whole_building_ventilation: true)
      if hpxml_file.include? 'exhaust'
        hpxml_bldg.ventilation_fans[-1].fan_type = HPXML::MechVentTypeExhaust
      elsif hpxml_file.include? 'supply'
        hpxml_bldg.ventilation_fans[-1].fan_type = HPXML::MechVentTypeSupply
      end
      hpxml_bldg.ventilation_fans[0].cfis_addtl_runtime_operating_mode = HPXML::CFISModeSupplementalFan
      hpxml_bldg.ventilation_fans[0].cfis_supplemental_fan_idref = hpxml_bldg.ventilation_fans[1].id
      if hpxml_file == 'base-mechvent-cfis-supplemental-fan-exhaust-synchronized.xml'
        hpxml_bldg.ventilation_fans[0].cfis_supplemental_fan_runs_with_air_handler_fan = true
      end
    end

    # ---------------- #
    # HPXML Generation #
    # ---------------- #

    if ['base-misc-defaults.xml'].include? hpxml_file
      hpxml_bldg.pv_systems[0].year_modules_manufactured = 2015
      hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served = 2700.0
    elsif ['base-pv-inverters.xml'].include? hpxml_file
      hpxml_bldg.inverters.add(id: "Inverter#{hpxml_bldg.inverters.size + 1}",
                               inverter_efficiency: 0.96)
      hpxml_bldg.inverters.add(id: "Inverter#{hpxml_bldg.inverters.size + 1}",
                               inverter_efficiency: 0.94)
      hpxml_bldg.pv_systems[0].inverter_idref = hpxml_bldg.inverters[0].id
      hpxml_bldg.pv_systems[1].inverter_idref = hpxml_bldg.inverters[1].id
    elsif ['base-misc-generators.xml',
           'base-misc-generators-battery.xml',
           'base-misc-generators-battery-scheduled.xml',
           'base-pv-generators.xml',
           'base-pv-generators-battery.xml',
           'base-pv-generators-battery-scheduled.xml'].include? hpxml_file
      hpxml_bldg.generators.add(id: "Generator#{hpxml_bldg.generators.size + 1}",
                                fuel_type: HPXML::FuelTypeNaturalGas,
                                annual_consumption_kbtu: 8500,
                                annual_output_kwh: 1200)
      hpxml_bldg.generators.add(id: "Generator#{hpxml_bldg.generators.size + 1}",
                                fuel_type: HPXML::FuelTypeOil,
                                annual_consumption_kbtu: 8500,
                                annual_output_kwh: 1200)
    elsif ['base-bldgtype-mf-unit-shared-generator.xml'].include? hpxml_file
      hpxml_bldg.generators.add(id: "Generator#{hpxml_bldg.generators.size + 1}",
                                is_shared_system: true,
                                fuel_type: HPXML::FuelTypePropane,
                                annual_consumption_kbtu: 85000,
                                annual_output_kwh: 12000,
                                number_of_bedrooms_served: 18)
    elsif ['base-bldgtype-mf-unit-shared-pv.xml',
           'base-bldgtype-mf-unit-shared-pv-battery.xml'].include? hpxml_file
      hpxml_bldg.pv_systems[0].is_shared_system = true
      hpxml_bldg.pv_systems[0].location = HPXML::LocationGround
      hpxml_bldg.pv_systems[0].tracking = HPXML::PVTrackingTypeFixed
      hpxml_bldg.pv_systems[0].max_power_output = 30000
      hpxml_bldg.pv_systems[0].number_of_bedrooms_served = 18
    end

    # -------------------- #
    # HPXML Electric Panel #
    # -------------------- #
    if hpxml_file.include? 'detailed-electric-panel'
      if ['base-detailed-electric-panel-no-calculation-types.xml'].include? hpxml_file
        hpxml.header.service_feeders_load_calculation_types = nil
      else
        hpxml.header.service_feeders_load_calculation_types = [HPXML::ElectricPanelLoadCalculationType2023ExistingDwellingLoadBased,
                                                               HPXML::ElectricPanelLoadCalculationType2023ExistingDwellingMeterBased]
      end
      hpxml_bldg.header.electric_panel_baseline_peak_power = 4500

      hpxml_bldg.electric_panels.add(id: "ElectricPanel#{hpxml_bldg.electric_panels.size + 1}")
      electric_panel = hpxml_bldg.electric_panels[-1]

      if not ['base-misc-unit-multiplier-detailed-electric-panel.xml',
              'base-bldgtype-mf-whole-building-detailed-electric-panel.xml'].include? hpxml_file
        electric_panel.voltage = HPXML::ElectricPanelVoltage240
        electric_panel.max_current_rating = 100
        electric_panel.headroom_spaces = 5

        branch_circuits = electric_panel.branch_circuits
        branch_circuits.add(id: "BranchCircuit#{branch_circuits.size + 1}",
                            occupied_spaces: 1)
      end

      service_feeders = electric_panel.service_feeders
      if hpxml_bldg.heating_systems.size > 0 && hpxml_bldg.cooling_systems.size > 0
        service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                            type: HPXML::ElectricPanelLoadTypeHeating,
                            component_idrefs: [hpxml_bldg.heating_systems[0].id])
        service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                            type: HPXML::ElectricPanelLoadTypeCooling,
                            component_idrefs: [hpxml_bldg.cooling_systems[0].id])
      else
        service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                            type: HPXML::ElectricPanelLoadTypeHeating,
                            power: 3542,
                            component_idrefs: [hpxml_bldg.heat_pumps[0].id])
        service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                            type: HPXML::ElectricPanelLoadTypeCooling,
                            power: 3542,
                            component_idrefs: [hpxml_bldg.heat_pumps[0].id])
      end
      hpxml_bldg.ventilation_fans.each do |ventilation_fan|
        service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                            type: HPXML::ElectricPanelLoadTypeMechVent,
                            component_idrefs: [ventilation_fan.id])
      end
      hpxml_bldg.water_heating_systems.each do |water_heater|
        next unless water_heater.fuel_type == HPXML::FuelTypeElectricity

        service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                            type: HPXML::ElectricPanelLoadTypeWaterHeater,
                            component_idrefs: [water_heater.id])
      end
      hpxml_bldg.clothes_dryers.each do |clothes_dryer|
        next unless clothes_dryer.fuel_type == HPXML::FuelTypeElectricity

        service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                            type: HPXML::ElectricPanelLoadTypeClothesDryer,
                            component_idrefs: [clothes_dryer.id])
      end
      hpxml_bldg.dishwashers.each do |dishwasher|
        service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                            type: HPXML::ElectricPanelLoadTypeDishwasher,
                            component_idrefs: [dishwasher.id])
      end
      hpxml_bldg.cooking_ranges.each do |cooking_range|
        next unless cooking_range.fuel_type == HPXML::FuelTypeElectricity

        service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                            type: HPXML::ElectricPanelLoadTypeRangeOven,
                            component_idrefs: [cooking_range.id])
      end
      if not ['base-misc-unit-multiplier-detailed-electric-panel.xml',
              'base-bldgtype-mf-whole-building-detailed-electric-panel.xml'].include? hpxml_file
        service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                            type: HPXML::ElectricPanelLoadTypeOther,
                            power: 559)
      end

      if hpxml_bldg_index > 0
        electric_panel.id += "_#{hpxml_bldg_index + 1}"
        if not branch_circuits.nil?
          branch_circuits.each do |branch_circuit|
            branch_circuit.id += "_#{hpxml_bldg_index + 1}"
          end
        end
        service_feeders.each do |service_feeder|
          service_feeder.id += "_#{hpxml_bldg_index + 1}"
        end
      end
    end
    if ['house051.xml'].include? hpxml_file
      branch_circuits = hpxml_bldg.electric_panels[0].branch_circuits
      branch_circuits.add(id: "BranchCircuit#{branch_circuits.size + 1}",
                          occupied_spaces: 1,
                          component_idrefs: [hpxml_bldg.refrigerators[0].id,
                                             hpxml_bldg.plug_loads[1].id])
    end

    # ------------- #
    # HPXML Battery #
    # ------------- #

    if ['base-pv-battery-lifetime-model.xml'].include? hpxml_file
      hpxml_bldg.batteries[0].lifetime_model = HPXML::BatteryLifetimeModelKandlerSmith
    elsif ['base-pv-battery-ah.xml'].include? hpxml_file
      default_values = Defaults.get_battery_values(false)
      hpxml_bldg.batteries[0].nominal_capacity_ah = Battery.get_Ah_from_kWh(hpxml_bldg.batteries[0].nominal_capacity_kwh,
                                                                            default_values[:nominal_voltage])
      hpxml_bldg.batteries[0].usable_capacity_ah = hpxml_bldg.batteries[0].nominal_capacity_ah * default_values[:usable_fraction]
      hpxml_bldg.batteries[0].nominal_capacity_kwh = nil
      hpxml_bldg.batteries[0].usable_capacity_kwh = nil
    elsif ['base-bldgtype-mf-unit-shared-pv-battery.xml'].include? hpxml_file
      hpxml_bldg.batteries[0].is_shared_system = true
      hpxml_bldg.batteries[0].nominal_capacity_kwh = 120.0
      hpxml_bldg.batteries[0].usable_capacity_kwh = 108.0
      hpxml_bldg.batteries[0].rated_power_output = 36000
      hpxml_bldg.batteries[0].number_of_bedrooms_served = 18
    elsif ['base-misc-defaults.xml',
           'base-residents-5-5.xml'].include? hpxml_file
      hpxml_bldg.batteries[0].nominal_capacity_kwh = nil
    end

    # ------------- #
    # HPXML Vehicle #
    # ------------- #

    if ['base-misc-defaults.xml',
        'base-residents-5-5.xml'].include? hpxml_file
      hpxml_bldg.vehicles[0].miles_per_year = nil
      hpxml_bldg.vehicles[0].hours_per_week = nil
      hpxml_bldg.vehicles[0].fuel_economy_combined = nil
      hpxml_bldg.vehicles[0].fuel_economy_units = nil
      hpxml_bldg.vehicles[0].fraction_charged_home = nil
      hpxml_bldg.vehicles[0].nominal_capacity_kwh = nil
      hpxml_bldg.vehicles[0].usable_capacity_kwh = nil
      hpxml_bldg.ev_chargers[0].charging_level = nil
      hpxml_bldg.ev_chargers[0].charging_power = nil
    end
    if ['base-vehicle-multiple.xml'].include? hpxml_file
      hpxml_bldg.vehicles.add(id: "Vehicle#{hpxml_bldg.vehicles.size + 1}",
                              vehicle_type: HPXML::VehicleTypeHybrid,
                              fuel_economy_units: HPXML::UnitsMPG,
                              fuel_economy_combined: 44.0,
                              miles_per_year: 15000.0,
                              hours_per_week: 10.0)
    end
    if ['base-schedules-simple.xml'].include? hpxml_file
      hpxml_bldg.vehicles[0].ev_weekday_fractions = '0.0714, 0.0714, 0.0714, 0.0714, 0.0714, 0.0714, 0.0714, -0.3535, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.3221, -0.3244, 0.0714, 0.0714, 0.0714, 0.0714, 0.0714, 0.0714, 0.0714'
      hpxml_bldg.vehicles[0].ev_weekend_fractions = '0.0588, 0.0588, 0.0588, 0.0588, 0.0588, 0.0588, 0.0588, 0.0588, 0.0588, -0.3334, 0, 0, 0, 0, -0.3293, -0.3372, 0.0588, 0.0588, 0.0588, 0.0588, 0.0588, 0.0588, 0.0588, 0.0588'
      hpxml_bldg.vehicles[0].ev_monthly_multipliers = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
    end
    if ['base-vehicle-ev-charger-occupancy-stochastic.xml'].include? hpxml_file
      hpxml_bldg.vehicles[0].hours_per_week = 14.0
    end
    if ['base-misc-usage-multiplier.xml'].include? hpxml_file
      hpxml_bldg.vehicles[0].miles_per_year = nil
      hpxml_bldg.vehicles[0].ev_usage_multiplier = 0.75
    end

    # ---------------- #
    # HPXML Appliances #
    # ---------------- #

    if ['base-misc-defaults.xml',
        'base-residents-5-5.xml'].include? hpxml_file
      hpxml_bldg.clothes_washers[0].modified_energy_factor = nil
      hpxml_bldg.clothes_washers[0].integrated_modified_energy_factor = nil
      hpxml_bldg.clothes_washers[0].rated_annual_kwh = nil
      hpxml_bldg.clothes_washers[0].label_electric_rate = nil
      hpxml_bldg.clothes_washers[0].label_gas_rate = nil
      hpxml_bldg.clothes_washers[0].label_annual_gas_cost = nil
      hpxml_bldg.clothes_washers[0].label_usage = nil
      hpxml_bldg.clothes_washers[0].capacity = nil
      hpxml_bldg.clothes_dryers[0].drying_method = nil
      hpxml_bldg.clothes_dryers[0].energy_factor = nil
      hpxml_bldg.clothes_dryers[0].combined_energy_factor = nil
      hpxml_bldg.dishwashers[0].rated_annual_kwh = nil
      hpxml_bldg.dishwashers[0].energy_factor = nil
      hpxml_bldg.dishwashers[0].place_setting_capacity = nil
      hpxml_bldg.dishwashers[0].label_electric_rate = nil
      hpxml_bldg.dishwashers[0].label_gas_rate = nil
      hpxml_bldg.dishwashers[0].label_annual_gas_cost = nil
      hpxml_bldg.dishwashers[0].label_usage = nil
      hpxml_bldg.refrigerators[0].rated_annual_kwh = nil
      hpxml_bldg.refrigerators[0].primary_indicator = nil
      hpxml_bldg.cooking_ranges[0].is_induction = nil
      hpxml_bldg.ovens[0].is_convection = nil
    end
    if ['base-appliances-coal.xml'].include? hpxml_file
      hpxml_bldg.clothes_dryers[0].fuel_type = HPXML::FuelTypeCoal
      hpxml_bldg.cooking_ranges[0].fuel_type = HPXML::FuelTypeCoal
    end
    if ['base-appliances-oil.xml'].include? hpxml_file
      hpxml_bldg.clothes_dryers[0].fuel_type = HPXML::FuelTypeOil
      hpxml_bldg.cooking_ranges[0].fuel_type = HPXML::FuelTypeOil
    end
    if ['base-appliances-wood.xml'].include? hpxml_file
      hpxml_bldg.clothes_dryers[0].fuel_type = HPXML::FuelTypeWoodCord
      hpxml_bldg.cooking_ranges[0].fuel_type = HPXML::FuelTypeWoodCord
    end
    if ['base-schedules-simple.xml',
        'base-schedules-simple-vacancy.xml',
        'base-schedules-simple-power-outage.xml',
        'base-misc-loads-large-uncommon.xml',
        'base-misc-loads-large-uncommon2.xml'].include? hpxml_file
      hpxml_bldg.clothes_washers[0].weekday_fractions = '0.009, 0.007, 0.004, 0.004, 0.007, 0.011, 0.022, 0.049, 0.073, 0.086, 0.084, 0.075, 0.067, 0.060, 0.049, 0.052, 0.050, 0.049, 0.049, 0.049, 0.049, 0.047, 0.032, 0.017'
      hpxml_bldg.clothes_washers[0].weekend_fractions = '0.009, 0.007, 0.004, 0.004, 0.007, 0.011, 0.022, 0.049, 0.073, 0.086, 0.084, 0.075, 0.067, 0.060, 0.049, 0.052, 0.050, 0.049, 0.049, 0.049, 0.049, 0.047, 0.032, 0.017'
      hpxml_bldg.clothes_washers[0].monthly_multipliers = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
      hpxml_bldg.clothes_dryers[0].weekday_fractions = '0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024'
      hpxml_bldg.clothes_dryers[0].weekend_fractions = '0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024'
      hpxml_bldg.clothes_dryers[0].monthly_multipliers = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
      hpxml_bldg.dishwashers[0].weekday_fractions = '0.015, 0.007, 0.005, 0.003, 0.003, 0.010, 0.020, 0.031, 0.058, 0.065, 0.056, 0.048, 0.041, 0.046, 0.036, 0.038, 0.038, 0.049, 0.087, 0.111, 0.090, 0.067, 0.044, 0.031'
      hpxml_bldg.dishwashers[0].weekend_fractions = '0.015, 0.007, 0.005, 0.003, 0.003, 0.010, 0.020, 0.031, 0.058, 0.065, 0.056, 0.048, 0.041, 0.046, 0.036, 0.038, 0.038, 0.049, 0.087, 0.111, 0.090, 0.067, 0.044, 0.031'
      hpxml_bldg.dishwashers[0].monthly_multipliers = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
      hpxml_bldg.refrigerators[0].weekday_fractions = '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041'
      hpxml_bldg.refrigerators[0].weekend_fractions = '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041'
      hpxml_bldg.refrigerators[0].monthly_multipliers = '0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837'
      hpxml_bldg.cooking_ranges[0].weekday_fractions = '0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011'
      hpxml_bldg.cooking_ranges[0].weekend_fractions = '0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011'
      hpxml_bldg.cooking_ranges[0].monthly_multipliers = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
    end
    if ['base-misc-loads-large-uncommon.xml',
        'base-misc-loads-large-uncommon2.xml',
        'base-misc-usage-multiplier.xml'].include? hpxml_file
      if hpxml_file != 'base-misc-usage-multiplier.xml'
        hpxml_bldg.refrigerators.add(id: "Refrigerator#{hpxml_bldg.refrigerators.size + 1}",
                                     rated_annual_kwh: 800,
                                     primary_indicator: false)
      end
      hpxml_bldg.freezers.add(id: "Freezer#{hpxml_bldg.freezers.size + 1}",
                              location: HPXML::LocationConditionedSpace,
                              rated_annual_kwh: 400)
      if hpxml_file == 'base-misc-usage-multiplier.xml'
        hpxml_bldg.freezers[-1].usage_multiplier = 0.9
        hpxml_bldg.building_occupancy.general_water_use_usage_multiplier = 0.9
      end
      (hpxml_bldg.refrigerators + hpxml_bldg.freezers).each do |appliance|
        next if appliance.is_a?(HPXML::Refrigerator) && hpxml_file == 'base-misc-usage-multiplier.xml'

        appliance.weekday_fractions = '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041'
        appliance.weekend_fractions = '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041'
        appliance.monthly_multipliers = '0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837'
      end
      hpxml_bldg.pools[0].pump_weekday_fractions = '0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003'
      hpxml_bldg.pools[0].pump_weekend_fractions = '0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003'
      hpxml_bldg.pools[0].pump_monthly_multipliers = '1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154'
      hpxml_bldg.pools[0].heater_weekday_fractions = '0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003'
      hpxml_bldg.pools[0].heater_weekend_fractions = '0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003'
      hpxml_bldg.pools[0].heater_monthly_multipliers = '1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154'
      hpxml_bldg.permanent_spas[0].pump_weekday_fractions = '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024'
      hpxml_bldg.permanent_spas[0].pump_weekend_fractions = '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024'
      hpxml_bldg.permanent_spas[0].pump_monthly_multipliers = '0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837'
      hpxml_bldg.permanent_spas[0].heater_weekday_fractions = '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024'
      hpxml_bldg.permanent_spas[0].heater_weekend_fractions = '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024'
      hpxml_bldg.permanent_spas[0].heater_monthly_multipliers = '0.921, 0.928, 0.921, 0.915, 0.921, 1.160, 1.158, 1.158, 1.160, 0.921, 0.915, 0.921'
    end
    if ['base-bldgtype-mf-unit-shared-laundry-room.xml',
        'base-bldgtype-mf-unit-shared-laundry-room-multiple-water-heaters.xml'].include? hpxml_file
      hpxml_bldg.clothes_washers[0].is_shared_appliance = true
      hpxml_bldg.clothes_washers[0].location = HPXML::LocationOtherHeatedSpace
      hpxml_bldg.clothes_dryers[0].location = HPXML::LocationOtherHeatedSpace
      hpxml_bldg.clothes_dryers[0].is_shared_appliance = true
      hpxml_bldg.dishwashers[0].is_shared_appliance = true
      hpxml_bldg.dishwashers[0].location = HPXML::LocationOtherHeatedSpace
      if hpxml_file == 'base-bldgtype-mf-unit-shared-laundry-room.xml'
        hpxml_bldg.clothes_washers[0].water_heating_system_idref = hpxml_bldg.water_heating_systems[0].id
        hpxml_bldg.dishwashers[0].water_heating_system_idref = hpxml_bldg.water_heating_systems[0].id
      elsif hpxml_file == 'base-bldgtype-mf-unit-shared-laundry-room-multiple-water-heaters.xml'
        hpxml_bldg.clothes_washers[0].hot_water_distribution_idref = hpxml_bldg.hot_water_distributions[0].id
        hpxml_bldg.dishwashers[0].hot_water_distribution_idref = hpxml_bldg.hot_water_distributions[0].id
      end
    end
    if ['base-appliances-refrigerator-temperature-dependent-schedule.xml'].include? hpxml_file
      hpxml_bldg.refrigerators[0].constant_coefficients = '-0.487, -0.340, -0.370, -0.361, -0.515, -0.684, -0.471, -0.159, -0.079, -0.417, -0.411, -0.386, -0.240, -0.314, -0.160, -0.121, -0.469, -0.412, -0.091, 0.077, -0.118, -0.247, -0.445, -0.544'
      hpxml_bldg.refrigerators[0].temperature_coefficients = '0.019, 0.016, 0.017, 0.016, 0.018, 0.021, 0.019, 0.015, 0.015, 0.019, 0.018, 0.018, 0.016, 0.017, 0.015, 0.015, 0.020, 0.020, 0.017, 0.014, 0.016, 0.017, 0.019, 0.020'
    end
    if ['base-appliances-freezer-temperature-dependent-schedule.xml'].include? hpxml_file
      hpxml_bldg.freezers.add(id: "Freezer#{hpxml_bldg.freezers.size + 1}",
                              location: HPXML::LocationConditionedSpace,
                              rated_annual_kwh: 400,
                              constant_coefficients: '-0.487, -0.340, -0.370, -0.361, -0.515, -0.684, -0.471, -0.159, -0.079, -0.417, -0.411, -0.386, -0.240, -0.314, -0.160, -0.121, -0.469, -0.412, -0.091, 0.077, -0.118, -0.247, -0.445, -0.544',
                              temperature_coefficients: '0.019, 0.016, 0.017, 0.016, 0.018, 0.021, 0.019, 0.015, 0.015, 0.019, 0.018, 0.018, 0.016, 0.017, 0.015, 0.015, 0.020, 0.020, 0.017, 0.014, 0.016, 0.017, 0.019, 0.020')
    end

    # -------------- #
    # HPXML Lighting #
    # -------------- #

    if ['base-misc-defaults.xml',
        'base-residents-5-5.xml'].include? hpxml_file
      hpxml_bldg.ceiling_fans[0].label_energy_use = nil
    end
    if ['base-lighting-ceiling-fans.xml',
        'base-lighting-ceiling-fans-label-energy-use.xml'].include? hpxml_file
      hpxml_bldg.ceiling_fans[0].weekday_fractions = '0.057, 0.057, 0.057, 0.057, 0.057, 0.057, 0.057, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.057, 0.057, 0.057, 0.057, 0.057, 0.057'
      hpxml_bldg.ceiling_fans[0].weekend_fractions = '0.057, 0.057, 0.057, 0.057, 0.057, 0.057, 0.057, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.057, 0.057, 0.057, 0.057, 0.057, 0.057'
      hpxml_bldg.ceiling_fans[0].monthly_multipliers = '0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0'
    elsif ['base-lighting-holiday.xml'].include? hpxml_file
      hpxml_bldg.lighting.holiday_exists = true
      hpxml_bldg.lighting.holiday_kwh_per_day = 1.1
      hpxml_bldg.lighting.holiday_period_begin_month = 11
      hpxml_bldg.lighting.holiday_period_begin_day = 24
      hpxml_bldg.lighting.holiday_period_end_month = 1
      hpxml_bldg.lighting.holiday_period_end_day = 6
      hpxml_bldg.lighting.holiday_weekday_fractions = '0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.008, 0.098, 0.168, 0.194, 0.284, 0.192, 0.037, 0.019'
      hpxml_bldg.lighting.holiday_weekend_fractions = '0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.008, 0.098, 0.168, 0.194, 0.284, 0.192, 0.037, 0.019'
    elsif ['base-schedules-simple.xml',
           'base-schedules-simple-vacancy.xml',
           'base-schedules-simple-power-outage.xml',
           'base-misc-loads-large-uncommon.xml',
           'base-misc-loads-large-uncommon2.xml'].include? hpxml_file
      hpxml_bldg.lighting.interior_weekday_fractions = '0.124, 0.074, 0.050, 0.050, 0.053, 0.140, 0.330, 0.420, 0.430, 0.424, 0.411, 0.394, 0.382, 0.378, 0.378, 0.379, 0.386, 0.412, 0.484, 0.619, 0.783, 0.880, 0.597, 0.249'
      hpxml_bldg.lighting.interior_weekend_fractions = '0.124, 0.074, 0.050, 0.050, 0.053, 0.140, 0.330, 0.420, 0.430, 0.424, 0.411, 0.394, 0.382, 0.378, 0.378, 0.379, 0.386, 0.412, 0.484, 0.619, 0.783, 0.880, 0.597, 0.249'
      hpxml_bldg.lighting.interior_monthly_multipliers = '1.19, 1.11, 1.02, 0.93, 0.84, 0.80, 0.82, 0.88, 0.98, 1.07, 1.16, 1.20'
      hpxml_bldg.lighting.exterior_weekday_fractions = '0.046, 0.046, 0.046, 0.046, 0.046, 0.037, 0.035, 0.034, 0.033, 0.028, 0.022, 0.015, 0.012, 0.011, 0.011, 0.012, 0.019, 0.037, 0.049, 0.065, 0.091, 0.105, 0.091, 0.063'
      hpxml_bldg.lighting.exterior_weekend_fractions = '0.046, 0.046, 0.045, 0.045, 0.046, 0.045, 0.044, 0.041, 0.036, 0.03, 0.024, 0.016, 0.012, 0.011, 0.011, 0.012, 0.019, 0.038, 0.048, 0.06, 0.083, 0.098, 0.085, 0.059'
      hpxml_bldg.lighting.exterior_monthly_multipliers = '1.19, 1.11, 1.02, 0.93, 0.84, 0.80, 0.82, 0.88, 0.98, 1.07, 1.16, 1.20'
      hpxml_bldg.lighting.garage_weekday_fractions = '0.046, 0.046, 0.046, 0.046, 0.046, 0.037, 0.035, 0.034, 0.033, 0.028, 0.022, 0.015, 0.012, 0.011, 0.011, 0.012, 0.019, 0.037, 0.049, 0.065, 0.091, 0.105, 0.091, 0.063'
      hpxml_bldg.lighting.garage_weekend_fractions = '0.046, 0.046, 0.045, 0.045, 0.046, 0.045, 0.044, 0.041, 0.036, 0.03, 0.024, 0.016, 0.012, 0.011, 0.011, 0.012, 0.019, 0.038, 0.048, 0.06, 0.083, 0.098, 0.085, 0.059'
      hpxml_bldg.lighting.garage_monthly_multipliers = '1.19, 1.11, 1.02, 0.93, 0.84, 0.80, 0.82, 0.88, 0.98, 1.07, 1.16, 1.20'
    elsif ['base-lighting-kwh-per-year.xml'].include? hpxml_file
      ltg_kwhs_per_year = { HPXML::LocationInterior => 1500,
                            HPXML::LocationExterior => 150,
                            HPXML::LocationGarage => 0 }
      hpxml_bldg.lighting_groups.clear
      ltg_kwhs_per_year.each do |location, kwh_per_year|
        hpxml_bldg.lighting_groups.add(id: "LightingGroup#{hpxml_bldg.lighting_groups.size + 1}",
                                       location: location,
                                       kwh_per_year: kwh_per_year)
      end
    elsif ['base-lighting-mixed.xml'].include? hpxml_file
      hpxml_bldg.lighting_groups.reverse_each do |lg|
        next unless lg.location == HPXML::LocationExterior

        lg.delete
      end
      hpxml_bldg.lighting_groups.each_with_index do |lg, i|
        lg.id = "LightingGroup#{i + 1}"
      end
      hpxml_bldg.lighting_groups.add(id: "LightingGroup#{hpxml_bldg.lighting_groups.size + 1}",
                                     location: HPXML::LocationExterior,
                                     kwh_per_year: 150)
    elsif ['base-foundation-basement-garage.xml'].include? hpxml_file
      int_lighting_groups = hpxml_bldg.lighting_groups.select { |lg| lg.location == HPXML::LocationInterior }
      int_lighting_groups.each do |lg|
        hpxml_bldg.lighting_groups << lg.dup
        hpxml_bldg.lighting_groups[-1].location = HPXML::LocationGarage
        hpxml_bldg.lighting_groups[-1].id = "LightingGroup#{hpxml_bldg.lighting_groups.size}"
      end
    end

    # --------------- #
    # HPXML MiscLoads #
    # --------------- #

    if ['base-schedules-simple.xml',
        'base-schedules-simple-vacancy.xml',
        'base-schedules-simple-power-outage.xml',
        'base-misc-loads-large-uncommon.xml',
        'base-misc-loads-large-uncommon2.xml'].include? hpxml_file
      hpxml_bldg.plug_loads[0].weekday_fractions = '0.045, 0.019, 0.01, 0.001, 0.001, 0.001, 0.005, 0.009, 0.018, 0.026, 0.032, 0.038, 0.04, 0.041, 0.043, 0.045, 0.05, 0.055, 0.07, 0.085, 0.097, 0.108, 0.089, 0.07'
      hpxml_bldg.plug_loads[0].weekend_fractions = '0.045, 0.019, 0.01, 0.001, 0.001, 0.001, 0.005, 0.009, 0.018, 0.026, 0.032, 0.038, 0.04, 0.041, 0.043, 0.045, 0.05, 0.055, 0.07, 0.085, 0.097, 0.108, 0.089, 0.07'
      hpxml_bldg.plug_loads[0].monthly_multipliers = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
      hpxml_bldg.plug_loads[1].weekday_fractions = '0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036'
      hpxml_bldg.plug_loads[1].weekend_fractions = '0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036'
      hpxml_bldg.plug_loads[1].monthly_multipliers = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
    end
    next unless ['base-misc-loads-large-uncommon.xml',
                 'base-misc-loads-large-uncommon2.xml',
                 'base-misc-usage-multiplier.xml'].include? hpxml_file

    if hpxml_file != 'base-misc-usage-multiplier.xml'
      hpxml_bldg.plug_loads[2].weekday_fractions = '0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042'
      hpxml_bldg.plug_loads[2].weekend_fractions = '0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042'
      hpxml_bldg.plug_loads[2].monthly_multipliers = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
      hpxml_bldg.plug_loads[3].weekday_fractions = '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065'
      hpxml_bldg.plug_loads[3].weekend_fractions = '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065'
      hpxml_bldg.plug_loads[3].monthly_multipliers = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
    end
    hpxml_bldg.fuel_loads[0].weekday_fractions = '0.004, 0.001, 0.001, 0.002, 0.007, 0.012, 0.029, 0.046, 0.044, 0.041, 0.044, 0.046, 0.042, 0.038, 0.049, 0.059, 0.110, 0.161, 0.115, 0.070, 0.044, 0.019, 0.013, 0.007'
    hpxml_bldg.fuel_loads[0].weekend_fractions = '0.004, 0.001, 0.001, 0.002, 0.007, 0.012, 0.029, 0.046, 0.044, 0.041, 0.044, 0.046, 0.042, 0.038, 0.049, 0.059, 0.110, 0.161, 0.115, 0.070, 0.044, 0.019, 0.013, 0.007'
    hpxml_bldg.fuel_loads[0].monthly_multipliers = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
    hpxml_bldg.fuel_loads[1].weekday_fractions = '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065'
    hpxml_bldg.fuel_loads[1].weekend_fractions = '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065'
    hpxml_bldg.fuel_loads[1].monthly_multipliers = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
    hpxml_bldg.fuel_loads[2].weekday_fractions = '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065'
    hpxml_bldg.fuel_loads[2].weekend_fractions = '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065'
    hpxml_bldg.fuel_loads[2].monthly_multipliers = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
  end
end

def download_utility_rates
  require_relative 'HPXMLtoOpenStudio/resources/util'
  require_relative 'ReportUtilityBills/resources/util'

  rates_dir = File.join(File.dirname(__FILE__), 'ReportUtilityBills/resources/detailed_rates')
  FileUtils.mkdir(rates_dir) if !File.exist?(rates_dir)
  filepath = File.join(rates_dir, 'usurdb.csv')

  if !File.exist?(filepath)
    require 'tempfile'
    tmpfile = Tempfile.new('rates')

    UrlResolver.fetch('https://openei.org/apps/USURDB/download/usurdb.csv.gz', tmpfile)

    puts 'Extracting utility rates...'
    require 'zlib'
    Zlib::GzipReader.open(tmpfile.path.to_s) do |input_stream|
      File.open(filepath, 'w') do |output_stream|
        IO.copy_stream(input_stream, output_stream)
      end
    end
  end

  num_rates_actual = process_usurdb(filepath)

  puts "#{num_rates_actual} rate files are available in openei_rates.zip."
  puts 'Completed.'
  exit!
end

def download_g_functions
  require_relative 'HPXMLtoOpenStudio/resources/data/g_functions/util'

  g_functions_dir = File.join(File.dirname(__FILE__), 'HPXMLtoOpenStudio/resources/data/g_functions')
  FileUtils.mkdir(g_functions_dir) if !File.exist?(g_functions_dir)
  filepath = File.join(g_functions_dir, 'g-function_library_1.0')

  if !File.exist?(filepath) # presence of 'g-function_library_1.0' folder will skip re-downloading
    require 'tempfile'
    tmpfile = Tempfile.new('functions')

    UrlResolver.fetch('https://gdr.openei.org/files/1325/g-function_library_1.0.zip', tmpfile)

    puts 'Extracting g-functions...'
    require 'zip'
    Zip::File.open(tmpfile.path.to_s) do |zipfile|
      zipfile.each do |file|
        fpath = File.join(g_functions_dir, file.name)
        FileUtils.mkdir_p(File.dirname(fpath))
        zipfile.extract(file, fpath) unless File.exist?(fpath)
      end
    end
  end

  num_configs_actual = process_g_functions(filepath)

  puts "#{num_configs_actual} config files are available in #{g_functions_dir}."
  puts 'Completed.'
  exit!
end

command_list = [:update_measures, :update_hpxmls, :create_release_zips, :download_utility_rates, :download_g_functions]

def display_usage(command_list)
  puts "Usage: openstudio #{File.basename(__FILE__)} [COMMAND]\nCommands:\n  " + command_list.join("\n  ")
end

if ARGV.size == 0
  puts 'ERROR: Missing command.'
  display_usage(command_list)
  exit!
elsif ARGV.size > 1
  puts 'ERROR: Too many commands.'
  display_usage(command_list)
  exit!
elsif not command_list.include? ARGV[0].to_sym
  puts "ERROR: Invalid command '#{ARGV[0]}'."
  display_usage(command_list)
  exit!
end

if ARGV[0].to_sym == :update_measures
  # Prevent NREL error regarding U: drive when not VPNed in
  ENV['HOME'] = 'C:' if !ENV['HOME'].nil? && ENV['HOME'].start_with?('U:')
  ENV['HOMEDRIVE'] = 'C:\\' if !ENV['HOMEDRIVE'].nil? && ENV['HOMEDRIVE'].start_with?('U:')

  # Apply rubocop (uses .rubocop.yml)
  commands = ["\"require 'rubocop/rake_task' \"",
              "\"require 'stringio' \"",
              "\"RuboCop::RakeTask.new(:rubocop) do |t| t.options = ['--autocorrect-all', '--format', 'simple'] end\"",
              '"Rake.application[:rubocop].invoke"']
  command = "#{OpenStudio.getOpenStudioCLI} -e #{commands.join(' -e ')}"
  puts 'Applying rubocop auto-correct to measures...'
  system(command)

  # Update measures XMLs
  puts 'Updating measure.xmls...'
  Dir['**/measure.xml'].each do |measure_xml|
    measure_dir = File.dirname(measure_xml)
    command = "#{OpenStudio.getOpenStudioCLI} measure -u '#{measure_dir}'"
    system(command, [:out, :err] => File::NULL)
  end

  puts 'Done.'
end

if ARGV[0].to_sym == :update_hpxmls
  # Prevent NREL error regarding U: drive when not VPNed in
  ENV['HOME'] = 'C:' if !ENV['HOME'].nil? && ENV['HOME'].start_with?('U:')
  ENV['HOMEDRIVE'] = 'C:\\' if !ENV['HOMEDRIVE'].nil? && ENV['HOMEDRIVE'].start_with?('U:')

  # Create sample/test HPXMLs
  t = Time.now
  create_hpxmls()
  puts "Completed in #{(Time.now - t).round(1)}s"

  # Reformat real_homes HPXMLs
  puts 'Reformatting real_homes HPXMLs...'
  Dir['workflow/real_homes/*.xml'].each do |hpxml_path|
    hpxml = HPXML.new(hpxml_path: hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, hpxml_path)
  end

  # Reformat ACCA_Examples HPXMLs
  puts 'Reformatting ACCA_Examples HPXMLs...'
  Dir['workflow/tests/ACCA_Examples/*.xml'].each do |hpxml_path|
    hpxml = HPXML.new(hpxml_path: hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, hpxml_path)
  end
end

if ARGV[0].to_sym == :download_utility_rates
  download_utility_rates
end

if ARGV[0].to_sym == :download_g_functions
  download_g_functions
end

if ARGV[0].to_sym == :create_release_zips
  if ENV['CI']
    # CI doesn't have git, so default to everything
    git_files = Dir['**/*.*']
  else
    # Only include files under git version control
    command = 'git ls-files'
    begin
      git_files = `#{command}`
    rescue
      puts "Command failed: '#{command}'. Perhaps git needs to be installed?"
      exit!
    end
  end

  files = ['Changelog.md',
           'LICENSE.md',
           'BuildResidentialHPXML/*.*',
           'BuildResidentialHPXML/resources/**/*.*',
           'BuildResidentialScheduleFile/*.*',
           'BuildResidentialScheduleFile/resources/**/*.*',
           'HPXMLtoOpenStudio/*.*',
           'HPXMLtoOpenStudio/resources/**/*.*',
           'ReportSimulationOutput/*.*',
           'ReportSimulationOutput/resources/**/*.*',
           'ReportUtilityBills/*.*',
           'ReportUtilityBills/resources/**/*.*',
           'weather/*.*',
           'workflow/*.*',
           'workflow/real_homes/*.xml',
           'workflow/sample_files/*.xml',
           'workflow/tests/*.rb',
           'workflow/tests/**/*.xml',
           'workflow/tests/**/*.csv',
           'documentation/index.html',
           'documentation/_static/**/*.*']

  if not ENV['CI']
    # Generate documentation
    puts 'Generating documentation...'
    command = 'sphinx-build -b singlehtml docs/source documentation'
    begin
      `#{command}`
      if not File.exist? File.join(File.dirname(__FILE__), 'documentation', 'index.html')
        puts 'Documentation was not successfully generated. Aborting...'
        exit!
      end
    rescue
      puts "Command failed: '#{command}'. Perhaps sphinx needs to be installed?"
      exit!
    end

    # Remove large fonts dir to keep package smaller
    fonts_dir = File.join(File.dirname(__FILE__), 'documentation', '_static', 'css', 'fonts')
    if Dir.exist? fonts_dir
      FileUtils.rm_r(fonts_dir)
    end
  end

  # Create zip files
  require 'zip'
  zip_path = File.join(File.dirname(__FILE__), "OpenStudio-HPXML-v#{Version::OS_HPXML_Version}.zip")
  File.delete(zip_path) if File.exist? zip_path
  puts "Creating #{zip_path}..."
  Zip::File.open(zip_path, create: true) do |zipfile|
    files.each do |f|
      Dir[f].each do |file|
        if file.start_with? 'documentation'
          # always include
        else
          if not git_files.include? file
            next
          end
        end
        zipfile.add(File.join('OpenStudio-HPXML', file), file)
      end
    end
  end
  puts "Wrote file at #{zip_path}."

  # Cleanup
  if not ENV['CI']
    FileUtils.rm_r(File.join(File.dirname(__FILE__), 'documentation'))
  end

  puts 'Done.'
end
