# frozen_string_literal: true

require 'csv'

def run_simulation_tests(xmls)
  # Run simulations
  puts "Running #{xmls.size} HPXML files..."
  all_annual_results = {}
  Parallel.map(xmls, in_threads: Parallel.processor_count) do |xml|
    next if xml.end_with? '-10x.xml'

    xml_name = File.basename(xml)
    results = _run_xml(xml, Parallel.worker_number)
    all_annual_results[xml_name], monthly_results = results

    next unless xml.include?('sample_files') || xml.include?('real_homes') # Exclude e.g. ASHRAE 140 files
    next if xml.include? 'base-bldgtype-mf-whole-building' # Already has multiple dwelling units

    # Also run with a 10x unit multiplier (2 identical dwelling units each with a 5x
    # unit multiplier) and check how the results compare to the original run
    _run_xml(xml, Parallel.worker_number, true, all_annual_results[xml_name], monthly_results)
  end

  return all_annual_results
end

def _run_xml(xml, worker_num, apply_unit_multiplier = false, annual_results_1x = nil, monthly_results_1x = nil)
  unit_multiplier = 1
  if apply_unit_multiplier
    hpxml = HPXML.new(hpxml_path: xml)
    hpxml.buildings.each do |hpxml_bldg|
      next unless hpxml_bldg.building_construction.number_of_units.nil?

      hpxml_bldg.building_construction.number_of_units = 1
    end
    orig_multiplier = hpxml.buildings.map { |hpxml_bldg| hpxml_bldg.building_construction.number_of_units }.sum

    # Create copy of the HPXML where the number of Building elements is doubled
    # and each Building is assigned a unit multiplier of 5 (2x5=10).
    n_bldgs = hpxml.buildings.size
    for i in 0..n_bldgs - 1
      hpxml_bldg = hpxml.buildings[i]
      if hpxml_bldg.dehumidifiers.size > 0
        # FUTURE: Dehumidifiers currently don't give desired results w/ unit multipliers
        # https://github.com/NREL/OpenStudio-HPXML/issues/1499
      elsif hpxml_bldg.heat_pumps.count { |hp| hp.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir } > 0
        # FUTURE: GSHPs currently don't give desired results w/ unit multipliers
        # https://github.com/NREL/OpenStudio-HPXML/issues/1499
      elsif hpxml_bldg.batteries.size > 0
        # FUTURE: Batteries currently don't work with whole SFA/MF buildings
        # https://github.com/NREL/OpenStudio-HPXML/issues/1499
        return
      elsif hpxml_bldg.vehicles.size > 0
        # Same as battery issue above
        return
      elsif hpxml.header.hvac_onoff_thermostat_deadband
        # On off thermostat not supported with unit multiplier yet
      elsif hpxml.header.heat_pump_backup_heating_capacity_increment
        # multi-staging backup coil not supported with unit multiplier yet
      else
        hpxml_bldg.building_construction.number_of_units *= 5
      end
      hpxml.buildings << hpxml_bldg.dup
    end
    unit_multiplier = hpxml.buildings.map { |hpxml_bldg| hpxml_bldg.building_construction.number_of_units }.sum / orig_multiplier
    if unit_multiplier > 1
      hpxml.header.whole_sfa_or_mf_building_sim = true
    end
    xml.gsub!('.xml', '-10x.xml')
    hpxml_doc = hpxml.to_doc()
    hpxml.set_unique_hpxml_ids(hpxml_doc)
    XMLHelper.write_file(hpxml_doc, xml)
  end

  print "Testing #{File.basename(xml)}...\n"

  rundir = File.join(File.dirname(__FILE__), "run#{worker_num}")
  # Uses 'monthly' to verify timeseries results match annual results via error-checking
  # inside the ReportSimulationOutput measure.
  cli_path = OpenStudio.getOpenStudioCLI
  command = "\"#{cli_path}\" \"#{File.join(File.dirname(__FILE__), '../run_simulation.rb')}\" -x \"#{xml}\" --add-component-loads -o \"#{rundir}\" --debug --monthly ALL"
  success = system(command)

  if unit_multiplier > 1
    # Clean up
    File.delete(xml)
    xml.gsub!('-10x.xml', '.xml')
  end

  rundir = File.join(rundir, 'run')

  # Check results
  print "Simulation failed: #{xml}.\n" unless success
  assert_equal(true, success)

  # Check for output files
  annual_csv_path = File.join(rundir, 'results_annual.csv')
  monthly_csv_path = File.join(rundir, 'results_timeseries.csv')
  bills_csv_path = File.join(rundir, 'results_bills.csv')
  panel_csv_path = File.join(rundir, 'results_panel.csv')
  assert(File.exist? annual_csv_path)
  assert(File.exist? monthly_csv_path)

  # Check outputs
  hpxml_defaults_path = File.join(rundir, 'in.xml')
  schema_validator = XMLValidator.get_xml_validator(File.join(File.dirname(__FILE__), '..', '..', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd'))
  schematron_validator = XMLValidator.get_xml_validator(File.join(File.dirname(__FILE__), '..', '..', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schematron', 'EPvalidator.sch'))
  hpxml = HPXML.new(hpxml_path: hpxml_defaults_path, schema_validator: schema_validator, schematron_validator: schematron_validator) # Validate in.xml to ensure it can be run back through OS-HPXML
  if not hpxml.errors.empty?
    puts 'ERRORS:'
    hpxml.errors.each do |error|
      puts error
    end
    flunk "EPvalidator.sch error in #{hpxml_defaults_path}."
  end
  annual_results = _get_simulation_annual_results(annual_csv_path, bills_csv_path, panel_csv_path)
  monthly_results = _get_simulation_monthly_results(monthly_csv_path)
  _verify_outputs(rundir, xml, annual_results, hpxml, unit_multiplier)
  if unit_multiplier > 1
    _check_unit_multiplier_results(xml, hpxml.buildings[0], annual_results_1x, annual_results, monthly_results_1x, monthly_results, unit_multiplier)
  end

  return annual_results, monthly_results
end

def _get_simulation_annual_results(annual_csv_path, bills_csv_path, panel_csv_path)
  # Grab all outputs from reporting measure CSV annual results
  results = {}
  CSV.foreach(annual_csv_path) do |row|
    next if row.nil? || (row.size < 2)

    results[row[0]] = Float(row[1])
  end

  # Grab all outputs (except monthly) from reporting measure CSV bill results
  if File.exist? bills_csv_path
    CSV.foreach(bills_csv_path) do |row|
      next if row.nil? || (row.size < 2)
      next if (1..12).to_a.any? { |month| row[0].include?(": Month #{month}:") }

      results["Utility Bills: #{row[0]}"] = Float(row[1])
    end
  end

  # Grab all outputs from reporting measure CSV panel results
  if File.exist? panel_csv_path
    CSV.foreach(panel_csv_path) do |row|
      next if row.nil? || (row.size < 2)

      results[row[0]] = Float(row[1])
    end
  end

  return results
end

def _get_simulation_monthly_results(monthly_csv_path)
  results = {}
  headers = nil
  CSV.foreach(monthly_csv_path).with_index do |row, i|
    row = row[1..-1] # Skip time column
    if i == 0 # Header row
      headers = row
      next
    elsif i == 1 # Units row
      headers = headers.zip(row).map { |header, units| "#{header} (#{units})" }
      next
    end

    for i in 0..row.size - 1
      results[headers[i]] = [] if results[headers[i]].nil?
      results[headers[i]] << Float(row[i])
    end
  end

  return results
end

def _verify_outputs(rundir, hpxml_path, results, hpxml, unit_multiplier)
  return if hpxml_path.include? 'ACCA_Examples'

  assert(File.exist? File.join(rundir, 'eplusout.msgpack'))

  hpxml_header = hpxml.header
  hpxml_bldg = hpxml.buildings[0]
  sqlFile = OpenStudio::SqlFile.new(File.join(rundir, 'eplusout.sql'), false)

  # Collapse windows further using same logic as measure.rb
  hpxml_bldg.windows.each do |window|
    window.fraction_operable = nil
  end
  hpxml_bldg.collapse_enclosure_surfaces()
  hpxml_bldg.delete_adiabatic_subsurfaces()

  # Check for unexpected run.log messages
  File.readlines(File.join(rundir, 'run.log')).each do |message|
    next if message.strip.empty?
    next if message.start_with? 'Info: '
    next if message.start_with? 'Executing command'
    next if message.include? 'Could not find state average'

    if hpxml_bldg.clothes_washers.empty?
      next if message.include? 'No clothes washer specified, the model will not include clothes washer energy use.'
    end
    if hpxml_bldg.clothes_dryers.empty?
      next if message.include? 'No clothes dryer specified, the model will not include clothes dryer energy use.'
    end
    if hpxml_bldg.dishwashers.empty?
      next if message.include? 'No dishwasher specified, the model will not include dishwasher energy use.'
    end
    if hpxml_bldg.refrigerators.empty?
      next if message.include? 'No refrigerator specified, the model will not include refrigerator energy use.'
    end
    if hpxml_bldg.cooking_ranges.empty?
      next if message.include? 'No cooking range specified, the model will not include cooking range/oven energy use.'
    end
    if hpxml_bldg.water_heating_systems.empty?
      next if message.include? 'No water heating specified, the model will not include water heating energy use.'
    end
    if (hpxml_bldg.heating_systems + hpxml_bldg.heat_pumps).select { |h| h.fraction_heat_load_served.to_f > 0 }.empty?
      next if message.include? 'No space heating specified, the model will not include space heating energy use.'
    end
    if (hpxml_bldg.cooling_systems + hpxml_bldg.heat_pumps).select { |c| c.fraction_cool_load_served.to_f > 0 }.empty?
      next if message.include? 'No space cooling specified, the model will not include space cooling energy use.'
    end
    if hpxml_bldg.plug_loads.select { |p| p.plug_load_type == HPXML::PlugLoadTypeOther }.empty?
      next if message.include? "No '#{HPXML::PlugLoadTypeOther}' plug loads specified, the model will not include misc plug load energy use."
    end
    if hpxml_bldg.plug_loads.select { |p| p.plug_load_type == HPXML::PlugLoadTypeTelevision }.empty?
      next if message.include? "No '#{HPXML::PlugLoadTypeTelevision}' plug loads specified, the model will not include television plug load energy use."
    end
    if hpxml_bldg.lighting_groups.empty?
      next if message.include? 'No interior lighting specified, the model will not include interior lighting energy use.'
      next if message.include? 'No exterior lighting specified, the model will not include exterior lighting energy use.'
      next if message.include? 'No garage lighting specified, the model will not include garage lighting energy use.'
    end
    if hpxml_bldg.windows.empty?
      next if message.include? 'No windows specified, the model will not include window heat transfer.'
    end
    if hpxml_bldg.pv_systems.empty? && !hpxml_bldg.batteries.empty? && hpxml_bldg.header.schedules_filepaths.empty?
      next if message.include? 'Battery without PV specified, and no charging/discharging schedule provided; battery is assumed to operate as backup and will not be modeled.'
    end
    if hpxml_bldg.vehicles.any? { |vehicle| vehicle.vehicle_type == HPXML::VehicleTypeBEV && vehicle.ev_charger_idref.nil? }
      next if message.include? 'Electric vehicle specified with no charger provided; home EV charging will not be modeled.'
    end
    if hpxml_bldg.vehicles.any? { |vehicle| vehicle.vehicle_type == HPXML::VehicleTypeBEV && !vehicle.ev_charger_idref.nil? && vehicle.ev_weekday_fractions.nil? } && !hpxml_bldg.header.schedules_filepaths.empty?
      next if message.include? 'driving hours could not be met'
    end
    if hpxml_bldg.vehicles.any? { |vehicle| vehicle.vehicle_type == HPXML::VehicleTypeBEV } && hpxml_bldg.plug_loads.any? { |p| p.plug_load_type == HPXML::PlugLoadTypeElectricVehicleCharging }
      next if message.include? 'Electric vehicle charging was specified as both a PlugLoad and a Vehicle, the latter will be ignored.'
    end
    if hpxml_bldg.vehicles.any? { |vehicle| vehicle.vehicle_type != HPXML::VehicleTypeBEV }
      next if message.include?('Vehicle type') && message.include?('is not currently handled, the vehicle will not be modeled')
    end
    if hpxml_path.include? 'base-location-capetown-zaf.xml'
      next if message.include? 'OS Message: Minutes field (60) on line 9 of EPW file'
      next if message.include? 'Could not find a marginal Electricity rate.'
      next if message.include? 'Could not find a marginal Natural Gas rate.'
    end
    if !hpxml_bldg.hvac_distributions.select { |d| d.distribution_system_type == HPXML::HVACDistributionTypeDSE }.empty?
      next if message.include? 'DSE is not currently supported when calculating utility bills.'
    end
    if !hpxml_header.unavailable_periods.select { |up| up.column_name == 'Power Outage' }.empty?
      next if message.include? 'It is not possible to eliminate all HVAC energy use (e.g. crankcase/defrost energy) in EnergyPlus during an unavailable period.'
      next if message.include? 'It is not possible to eliminate all DHW energy use (e.g. water heater parasitics) in EnergyPlus during an unavailable period.'
    end
    if (not hpxml_bldg.hvac_controls.empty?) && (hpxml_bldg.hvac_controls[0].seasons_heating_begin_month != 1)
      next if message.include? 'It is not possible to eliminate all HVAC energy use (e.g. crankcase/defrost energy) in EnergyPlus outside of an HVAC season.'
    end
    if !hpxml_header.unavailable_periods.select { |up| (up.column_name == 'No Space Heating') || (up.column_name == 'No Space Cooling') }.empty?
      next if message.include? 'It is not possible to eliminate all HVAC energy use (e.g. crankcase/defrost energy) in EnergyPlus during an unavailable period.'
    end
    if hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath.include? 'US_CO_Boulder_AMY_2012.epw'
      next if message.include? 'No EPW design conditions found; calculating design conditions from EPW weather data.'
    end
    if hpxml_bldg.building_construction.number_of_units > 1
      next if message.include? 'NumberofUnits is greater than 1, indicating that the HPXML Building represents multiple dwelling units; simulation outputs will reflect this unit multiplier.'
    end
    if hpxml_path.include? 'base-hvac-multiple.xml'
      next if message.include? 'Reached a minimum of 1 borehole; setting bore depth to the minimum'
    end
    if hpxml_path.include? 'base-zones'
      next if message.include? 'While multiple conditioned zones are specified, the EnergyPlus model will only include a single conditioned thermal zone.'
    end
    if hpxml_bldg.windows.any? { |w| w.exterior_shading_type == 'external overhangs' && w.overhangs_depth.to_f > 0 }
      next if message.include? "Exterior shading type is 'external overhangs', but overhangs are explicitly defined; exterior shading type will be ignored."
    end
    if hpxml_bldg.windows.any? { |w| w.exterior_shading_type == 'building' } && hpxml_bldg.neighbor_buildings.size > 0
      next if message.include? "Exterior shading type is 'building', but neighbor buildings are explicitly defined; exterior shading type will be ignored."
    end

    # FUTURE: Revert this eventually
    # https://github.com/NREL/OpenStudio-HPXML/issues/1499
    if hpxml_header.utility_bill_scenarios.has_detailed_electric_rates
      uses_unit_multipliers = hpxml.buildings.count { |hpxml_bldg| hpxml_bldg.building_construction.number_of_units > 1 } > 0
      if uses_unit_multipliers || hpxml.buildings.size > 1
        next if message.include? 'Cannot currently calculate utility bills based on detailed electric rates for an HPXML with unit multipliers.'
      end
    end

    flunk "Unexpected run.log message found for #{File.basename(hpxml_path)}: #{message}"
  end

  # Check for unexpected eplusout.err messages
  messages = []
  message = nil
  File.readlines(File.join(rundir, 'eplusout.err')).each do |err_line|
    if err_line.include?('** Warning **') || err_line.include?('** Severe  **') || err_line.include?('**  Fatal  **')
      messages << message unless message.nil?
      message = err_line
    else
      message += err_line unless message.nil?
    end
  end

  messages.each do |message|
    # General
    next if message.include? 'Schedule:Constant="ALWAYS ON CONTINUOUS", Blank Schedule Type Limits Name input'
    next if message.include? 'Schedule:Constant="ALWAYS ON DISCRETE", Blank Schedule Type Limits Name input'
    next if message.include? 'Schedule:Constant="ALWAYS OFF DISCRETE", Blank Schedule Type Limits Name input'
    next if message.include? 'Entered Zone Volumes differ from calculated zone volume'
    next if message.include? 'PerformancePrecisionTradeoffs: Carroll MRT radiant exchange method is selected.'
    next if message.include?('CalculateZoneVolume') && message.include?('not fully enclosed')
    next if message.include? 'do not define an enclosure'
    next if message.include? 'Pump nominal power or motor efficiency is set to 0'
    next if message.include? 'volume flow rate per watt of rated total cooling capacity is out of range'
    next if message.include? 'volume flow rate per watt of rated total heating capacity is out of range'
    next if message.include? 'volume flow rate per watt of rated total water heating capacity is out of range'
    next if message.include? 'The Standard Ratings is calculated for'
    next if message.include?('WetBulb not converged after') && message.include?('iterations(PsyTwbFnTdbWPb)')
    next if message.include? 'Inside surface heat balance did not converge with Max Temp Difference'
    next if message.include? 'Inside surface heat balance convergence problem continues'
    next if message.include?('Glycol') && message.include?('Temperature') && message.include?('out of range (too low) for fluid')
    next if message.include?('Glycol') && message.include?('Temperature') && message.include?('out of range (too high) for fluid')
    next if message.include? 'Plant loop exceeding upper temperature limit'
    next if message.include? 'Plant loop falling below lower temperature limit'
    next if message.include?('Foundation:Kiva') && message.include?('wall surfaces with more than four vertices') # TODO: Check alternative approach
    next if message.include? 'Temperature out of range [-100. to 200.] (PsyPsatFnTemp)'
    next if message.include? 'Enthalpy out of range (PsyTsatFnHPb)'
    next if message.include? 'Full load outlet air dry-bulb temperature < 2C. This indicates the possibility of coil frost/freeze.'
    next if message.include? 'Full load outlet temperature indicates a possibility of frost/freeze error continues.'
    next if message.include? 'Air-cooled condenser inlet dry-bulb temperature below 0 C.'
    next if message.include? 'Low condenser dry-bulb temperature error continues.'
    next if message.include? 'Coil control failed'
    next if message.include? 'sensible part-load ratio out of range error continues'
    next if message.include? 'Iteration limit exceeded in calculating sensible part-load ratio error continues'
    next if message.include?('setupIHGOutputs: Output variables=Zone Other Equipment') && message.include?('are not available.')
    next if message.include?('setupIHGOutputs: Output variables=Space Other Equipment') && message.include?('are not available')
    next if message.include? 'Multiple speed fan will be applied to this unit. The speed number is determined by load.'

    # HPWHs
    if hpxml_bldg.water_heating_systems.count { |wh| wh.water_heater_type == HPXML::WaterHeaterTypeHeatPump } > 0
      next if message.include? 'Recovery Efficiency and Energy Factor could not be calculated during the test for standard ratings'
      next if message.include? 'SimHVAC: Maximum iterations (20) exceeded for all HVAC loops'
      next if message.include? 'For object = Coil:WaterHeating:AirToWaterHeatPump:Wrapped'
      next if message.include? 'Enthalpy out of range (PsyTsatFnHPb)'
      next if message.include?('CheckWarmupConvergence: Loads Initialization') && message.include?('did not converge after 25 warmup days')
    end
    # HPWHs outside
    if hpxml_bldg.water_heating_systems.count { |wh| wh.water_heater_type == HPXML::WaterHeaterTypeHeatPump && wh.location == HPXML::LocationOtherExterior } > 0
      next if message.include? 'Water heater tank set point temperature is greater than or equal to the cut-in temperature of the heat pump water heater.'
    end
    # Stratified tank WHs
    if hpxml_bldg.water_heating_systems.count { |wh| wh.tank_model_type == HPXML::WaterHeaterTankModelTypeStratified } > 0
      next if message.include? 'Recovery Efficiency and Energy Factor could not be calculated during the test for standard ratings'
    end
    # HP defrost curves
    if hpxml_bldg.heat_pumps.count { |hp| [HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpMiniSplit, HPXML::HVACTypeHeatPumpPTHP, HPXML::HVACTypeHeatPumpRoom].include? hp.heat_pump_type } > 0
      next if message.include?('GetDXCoils: Coil:Heating:DX') && message.include?('curve values') && message.include?('Defrost Energy Input Ratio Function of Temperature Curve')
    end
    # variable system SHR adjustment
    if (hpxml_bldg.heat_pumps + hpxml_bldg.cooling_systems).count { |hp| hp.compressor_type == HPXML::HVACCompressorTypeVariableSpeed } > 0
      next if message.include?('CalcCBF: SHR adjusted to achieve valid outlet air properties and the simulation continues.')
    end
    # Evaporative coolers
    if hpxml_bldg.cooling_systems.count { |c| c.cooling_system_type == HPXML::HVACTypeEvaporativeCooler } > 0
      # "The only valid controller type for an AirLoopHVAC is Controller:WaterCoil.", evap cooler doesn't need one.
      next if message.include?('GetAirPathData: AirLoopHVAC') && message.include?('has no Controllers')
      # input "Autosize" for Fixed Minimum Air Flow Rate is added by OS translation, now set it to 0 to skip potential sizing process, though no way to prevent this warning.
      next if message.include? 'Since Zone Minimum Air Flow Input Method = CONSTANT, input for Fixed Minimum Air Flow Rate will be ignored'
    end
    # Fan coil distribution
    if hpxml_bldg.hvac_distributions.count { |d| d.air_type.to_s == HPXML::AirTypeFanCoil } > 0
      next if message.include? 'In calculating the design coil UA for Coil:Cooling:Water' # Warning for unused cooling coil for fan coil
    end
    # Boilers
    if hpxml_bldg.heating_systems.count { |h| h.heating_system_type == HPXML::HVACTypeBoiler } > 0
      next if message.include? 'Missing temperature setpoint for LeavingSetpointModulated mode' # These warnings are fine, simulation continues with assigning plant loop setpoint to boiler, which is the expected one
    end
    # GSHPs
    if hpxml_bldg.heat_pumps.count { |hp| hp.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir } > 0
      next if message.include?('CheckSimpleWAHPRatedCurvesOutputs') && message.include?('WaterToAirHeatPump:EquationFit') # FUTURE: Check these
      next if message.include? 'Actual air mass flow rate is smaller than 25% of water-to-air heat pump coil rated air flow rate.' # FUTURE: Remove this when https://github.com/NREL/EnergyPlus/issues/9125 is resolved
    end
    # GSHPs with only heating or cooling
    if hpxml_bldg.heat_pumps.count { |hp| hp.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir && (hp.fraction_heat_load_served == 0 || hp.fraction_cool_load_served == 0) } > 0
      next if message.include? 'heating capacity is disproportionate (> 20% different) to total cooling capacity' # safe to ignore
    end
    # Solar thermal systems
    if hpxml_bldg.solar_thermal_systems.size > 0
      next if message.include? 'Supply Side is storing excess heat the majority of the time.'
    end
    # Unavailability periods
    if !hpxml_header.unavailable_periods.empty?
      next if message.include? 'Target water temperature is greater than the hot water temperature'
      next if message.include? 'Target water temperature should be less than or equal to the hot water temperature'
    end
    # Simulation w/ timesteps longer than 15-minutes
    timestep = hpxml_header.timestep.nil? ? 60 : hpxml_header.timestep
    if timestep > 15
      next if message.include?('Timestep: Requested number') && message.include?('is less than the suggested minimum')
    end
    # Coil speed level EMS
    if hpxml_header.hvac_onoff_thermostat_deadband
      next if message.include?('Wrong coil speed EMS override value, for unit=') && message.include?('Exceeding maximum coil speed level.') # Speed level actuator throws this error when speed is set to 1 but no load
    end
    # TODO: Check why this house produces this warning
    if hpxml_path.include? 'house044.xml'
      next if message.include? 'FixViewFactors: View factors not complete. Check for bad surface descriptions or unenclosed zone'
    end
    # TODO: Check why this warning occurs
    if hpxml_path.include? 'base-bldgtype-mf-whole-building'
      next if message.include? 'SHR adjusted to achieve valid outlet air properties and the simulation continues.'
    end

    flunk "Unexpected eplusout.err message found for #{File.basename(hpxml_path)}: #{message}"
  end

  # Check for unused objects/schedules/constructions warnings
  num_unused_objects = 0
  num_unused_schedules = 0
  num_unused_constructions = 0
  File.readlines(File.join(rundir, 'eplusout.err')).each do |err_line|
    if err_line.include? 'unused objects in input'
      num_unused_objects = Integer(err_line.split(' ')[3])
    elsif err_line.include? 'unused schedules in input'
      num_unused_schedules = Integer(err_line.split(' ')[3])
    elsif err_line.include? 'unused constructions in input'
      num_unused_constructions = Integer(err_line.split(' ')[6])
    end
  end
  assert_equal(0, num_unused_objects)
  assert_equal(0, num_unused_schedules)
  assert_equal(0, num_unused_constructions)

  # Check for Output:Meter and Output:Variable warnings
  num_invalid_output_meters = 0
  num_invalid_output_variables = 0
  File.readlines(File.join(rundir, 'eplusout.err')).each do |err_line|
    if err_line.include? 'Output:Meter: invalid Key Name'
      num_invalid_output_meters += 1
    elsif err_line.include?('Key=') && err_line.include?('VarName=')
      num_invalid_output_variables += 1
    end
  end
  assert_equal(0, num_invalid_output_meters)
  assert_equal(0, num_invalid_output_variables)

  # Check discrepancy between total load and sum of component loads
  if not hpxml_path.include? 'ASHRAE_Standard_140'
    sum_component_htg_loads = results.select { |k, _v| k.start_with? 'Component Load: Heating:' }.values.sum(0.0)
    sum_component_clg_loads = results.select { |k, _v| k.start_with? 'Component Load: Cooling:' }.values.sum(0.0)
    total_htg_load_delivered = results['Load: Heating: Delivered (MBtu)']
    total_clg_load_delivered = results['Load: Cooling: Delivered (MBtu)']
    abs_htg_load_delta = (total_htg_load_delivered - sum_component_htg_loads).abs
    abs_clg_load_delta = (total_clg_load_delivered - sum_component_clg_loads).abs
    avg_htg_load = [total_htg_load_delivered, sum_component_htg_loads].sum / 2.0
    avg_clg_load = [total_clg_load_delivered, sum_component_clg_loads].sum / 2.0
    if avg_htg_load > 0
      abs_htg_load_frac = abs_htg_load_delta / avg_htg_load
    end
    if avg_clg_load > 0
      abs_clg_load_frac = abs_clg_load_delta / avg_clg_load
    end
    # Check that the difference is less than 1.5 MBtu or less than 10%
    assert((abs_htg_load_delta < 1.5 * unit_multiplier) || (!abs_htg_load_frac.nil? && abs_htg_load_frac < 0.1))
    assert((abs_clg_load_delta < 1.5 * unit_multiplier) || (!abs_clg_load_frac.nil? && abs_clg_load_frac < 0.1))
  end

  return if (hpxml.buildings.size > 1) || (hpxml_bldg.building_construction.number_of_units > 1)

  # Timestep
  timestep = hpxml_header.timestep.nil? ? 60 : hpxml_header.timestep
  query = 'SELECT NumTimestepsPerHour FROM Simulations'
  sql_value = sqlFile.execAndReturnFirstDouble(query).get
  assert_equal(60 / timestep, sql_value)

  # Conditioned Floor Area
  if (hpxml_bldg.total_fraction_cool_load_served > 0) || (hpxml_bldg.total_fraction_heat_load_served > 0) # EnergyPlus will only report conditioned floor area if there is an HVAC system
    hpxml_value = hpxml_bldg.building_construction.conditioned_floor_area
    if hpxml_bldg.has_location(HPXML::LocationCrawlspaceConditioned)
      hpxml_value += hpxml_bldg.slabs.select { |s| s.interior_adjacent_to == HPXML::LocationCrawlspaceConditioned }.map { |s| s.area }.sum
    end
    query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='InputVerificationandResultsSummary' AND ReportForString='Entire Facility' AND TableName='Zone Summary' AND RowName='Conditioned Total' AND ColumnName='Area' AND Units='m2'"
    sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
    assert_in_epsilon(hpxml_value, sql_value, 0.1)
  end

  # Enclosure Roofs
  hpxml_bldg.roofs.each do |roof|
    roof_id = roof.id.upcase

    # R-value
    hpxml_value = roof.insulation_assembly_r_value
    if hpxml_path.include? 'ASHRAE_Standard_140'
      # Compare R-value w/o film
      hpxml_value -= Material.AirFilmRoofASHRAE140.rvalue
      hpxml_value -= Material.AirFilmOutsideASHRAE140.rvalue
      query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{roof_id}' OR RowName LIKE '#{roof_id}:%') AND ColumnName='U-Factor no Film' AND Units='W/m2-K'"
    else
      # Compare R-value w/ film
      query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{roof_id}' OR RowName LIKE '#{roof_id}:%') AND ColumnName='U-Factor with Film' AND Units='W/m2-K'"
    end
    sql_value = 1.0 / UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)')
    assert_in_epsilon(hpxml_value, sql_value, 0.1)

    # Net area
    hpxml_value = roof.net_area
    query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{roof_id}' OR RowName LIKE '#{roof_id}:%') AND ColumnName='Net Area' AND Units='m2'"
    sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
    assert_operator(sql_value, :>, 0.01)
    assert_in_epsilon(hpxml_value, sql_value, 0.1)

    # Solar absorptance
    hpxml_value = roof.solar_absorptance
    query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{roof_id}' OR RowName LIKE '#{roof_id}:%') AND ColumnName='Reflectance'"
    sql_value = 1.0 - sqlFile.execAndReturnFirstDouble(query).get
    assert_in_epsilon(hpxml_value, sql_value, 0.01)

    # Tilt
    hpxml_value = UnitConversions.convert(Math.atan(roof.pitch / 12.0), 'rad', 'deg')
    query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{roof_id}' OR RowName LIKE '#{roof_id}:%') AND ColumnName='Tilt' AND Units='deg'"
    sql_value = sqlFile.execAndReturnFirstDouble(query).get
    assert_in_epsilon(hpxml_value, sql_value, 0.01)

    # Azimuth
    next unless (not roof.azimuth.nil?) && (Float(roof.pitch) > 0)

    hpxml_value = roof.azimuth
    query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{roof_id}' OR RowName LIKE '#{roof_id}:%') AND ColumnName='Azimuth' AND Units='deg'"
    sql_value = sqlFile.execAndReturnFirstDouble(query).get
    assert_in_epsilon(hpxml_value, sql_value, 0.01)
  end

  # Enclosure Foundations
  # Ensure Kiva instances have perimeter fraction of 1.0 as we explicitly define them to end up this way.
  num_kiva_instances = 0
  File.readlines(File.join(rundir, 'eplusout.eio')).each do |eio_line|
    next unless eio_line.downcase.start_with? 'foundation kiva'

    kiva_perim_frac = Float(eio_line.split(',')[5])
    assert_equal(1.0, kiva_perim_frac)

    num_kiva_instances += 1
  end

  # Enclosure Foundation Slabs
  num_slabs = hpxml_bldg.slabs.size
  if (num_slabs <= 1) && (num_kiva_instances <= 1) # The slab surfaces may be combined in these situations, so skip tests
    hpxml_bldg.slabs.each do |slab|
      slab_id = slab.id.upcase

      # Exposed Area
      hpxml_value = Float(slab.area)
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND RowName='#{slab_id}' AND ColumnName='Gross Area' AND Units='m2'"
      sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
      assert_operator(sql_value, :>, 0.01)
      assert_in_epsilon(hpxml_value, sql_value, 0.1)

      # Tilt
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND RowName='#{slab_id}' AND ColumnName='Tilt' AND Units='deg'"
      sql_value = sqlFile.execAndReturnFirstDouble(query).get
      assert_in_epsilon(180.0, sql_value, 0.01)
    end
  end

  # Enclosure Walls/RimJoists/FoundationWalls
  (hpxml_bldg.walls + hpxml_bldg.rim_joists + hpxml_bldg.foundation_walls).each do |wall|
    wall_id = wall.id.upcase

    if wall.is_adiabatic
      # Adiabatic surfaces have their "BaseSurfaceIndex" as their "ExtBoundCond" in "Surfaces" table in SQL simulation results
      query_base_surf_idx = "SELECT BaseSurfaceIndex FROM Surfaces WHERE SurfaceName='#{wall_id}'"
      query_ext_bound = "SELECT ExtBoundCond FROM Surfaces WHERE SurfaceName='#{wall_id}'"
      sql_value_base_surf_idx = sqlFile.execAndReturnFirstDouble(query_base_surf_idx).get
      sql_value_ext_bound_cond = sqlFile.execAndReturnFirstDouble(query_ext_bound).get
      assert_equal(sql_value_base_surf_idx, sql_value_ext_bound_cond)
    end

    if wall.is_exterior
      table_name = 'Opaque Exterior'
    else
      table_name = 'Opaque Interior'
    end

    # R-value
    if (not wall.insulation_assembly_r_value.nil?) && (not wall.is_a? HPXML::FoundationWall) # FoundationWalls use Foundation:Kiva for insulation
      hpxml_value = wall.insulation_assembly_r_value
      if hpxml_path.include? 'ASHRAE_Standard_140'
        # Compare R-value w/o film
        hpxml_value -= Material.AirFilmVerticalASHRAE140.rvalue
        if wall.is_exterior
          hpxml_value -= Material.AirFilmOutsideASHRAE140.rvalue
        else
          hpxml_value -= Material.AirFilmVerticalASHRAE140.rvalue
        end
        query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%') AND ColumnName='U-Factor no Film' AND Units='W/m2-K'"
      elsif wall.is_interior
        # Compare R-value w/o film
        hpxml_value -= Material.AirFilmVertical.rvalue
        hpxml_value -= Material.AirFilmVertical.rvalue
        query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%') AND ColumnName='U-Factor no Film' AND Units='W/m2-K'"
      else
        # Compare R-value w/ film
        query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%') AND ColumnName='U-Factor with Film' AND Units='W/m2-K'"
      end
      sql_value = 1.0 / UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)')
      assert_in_epsilon(hpxml_value, sql_value, 0.1)
    end

    # Net area
    hpxml_value = wall.net_area
    if wall.is_a? HPXML::FoundationWall
      if wall.is_exterior
        # only modeling portion of foundation wall that is exposed perimeter
        hpxml_value *= wall.exposed_fraction
      else
        # interzonal foundation walls: only above-grade portion modeled
        hpxml_value *= (wall.height - wall.depth_below_grade) / wall.height
      end
    end
    if wall.is_exterior
      query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%' OR RowName LIKE '#{wall_id} %') AND ColumnName='Net Area' AND Units='m2'"
    else
      query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%') AND ColumnName='Net Area' AND Units='m2'"
    end
    sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
    assert_operator(sql_value, :>, 0.01)
    assert_in_epsilon(hpxml_value, sql_value, 0.1)

    # Solar absorptance
    if wall.respond_to?(:solar_absorptance) && (not wall.solar_absorptance.nil?)
      hpxml_value = wall.solar_absorptance
      query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%') AND ColumnName='Reflectance'"
      sql_value = 1.0 - sqlFile.execAndReturnFirstDouble(query).get
      assert_in_epsilon(hpxml_value, sql_value, 0.01)
    end

    # Tilt
    query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%') AND ColumnName='Tilt' AND Units='deg'"
    sql_value = sqlFile.execAndReturnFirstDouble(query).get
    assert_in_epsilon(90.0, sql_value, 0.01)

    # Azimuth
    next if wall.azimuth.nil?

    hpxml_value = wall.azimuth
    query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%') AND ColumnName='Azimuth' AND Units='deg'"
    sql_value = sqlFile.execAndReturnFirstDouble(query).get
    assert_in_epsilon(hpxml_value, sql_value, 0.01)
  end

  # Enclosure Floors
  hpxml_bldg.floors.each do |floor|
    floor_id = floor.id.upcase

    if floor.is_adiabatic
      # Adiabatic surfaces have their "BaseSurfaceIndex" as their "ExtBoundCond" in "Surfaces" table in SQL simulation results
      query_base_surf_idx = "SELECT BaseSurfaceIndex FROM Surfaces WHERE SurfaceName='#{floor_id}'"
      query_ext_bound = "SELECT ExtBoundCond FROM Surfaces WHERE SurfaceName='#{floor_id}'"
      sql_value_base_surf_idx = sqlFile.execAndReturnFirstDouble(query_base_surf_idx).get
      sql_value_ext_bound_cond = sqlFile.execAndReturnFirstDouble(query_ext_bound).get
      assert_equal(sql_value_base_surf_idx, sql_value_ext_bound_cond)
    end

    if floor.is_exterior
      table_name = 'Opaque Exterior'
    else
      table_name = 'Opaque Interior'
    end

    # R-value
    hpxml_value = floor.insulation_assembly_r_value
    if hpxml_path.include? 'ASHRAE_Standard_140'
      # Compare R-value w/o film
      if floor.is_exterior # Raised floor
        hpxml_value -= Material.AirFilmFloorASHRAE140.rvalue
        hpxml_value -= Material.AirFilmFloorZeroWindASHRAE140.rvalue
      elsif floor.is_ceiling # Attic floor
        hpxml_value -= Material.AirFilmFloorASHRAE140.rvalue
        hpxml_value -= Material.AirFilmFloorASHRAE140.rvalue
      end
      query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{floor_id}' AND ColumnName='U-Factor no Film' AND Units='W/m2-K'"
    elsif floor.is_interior
      # Compare R-value w/o film
      if floor.is_ceiling
        hpxml_value -= Material.AirFilmFloorAverage.rvalue
        hpxml_value -= Material.AirFilmFloorAverage.rvalue
      else
        hpxml_value -= Material.AirFilmFloorReduced.rvalue
        hpxml_value -= Material.AirFilmFloorReduced.rvalue
      end
      query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{floor_id}' AND ColumnName='U-Factor no Film' AND Units='W/m2-K'"
    else
      # Compare R-value w/ film
      query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{floor_id}' AND ColumnName='U-Factor with Film' AND Units='W/m2-K'"
    end
    sql_value = 1.0 / UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)')
    assert_in_epsilon(hpxml_value, sql_value, 0.1)

    # Area
    hpxml_value = floor.net_area
    query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{floor_id}' AND ColumnName='Net Area' AND Units='m2'"
    sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
    assert_operator(sql_value, :>, 0.01)
    assert_in_epsilon(hpxml_value, sql_value, 0.1)

    # Tilt
    if floor.is_ceiling
      hpxml_value = 0
    else
      hpxml_value = 180
    end
    query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{floor_id}' AND ColumnName='Tilt' AND Units='deg'"
    sql_value = sqlFile.execAndReturnFirstDouble(query).get
    assert_in_epsilon(hpxml_value, sql_value, 0.01)
  end

  # Enclosure Windows
  hpxml_bldg.windows.each do |window|
    window_id = window.id.upcase

    if window.is_exterior
      table_name = 'Exterior Fenestration'
    else
      table_name = 'Interior Door'
    end

    # Area
    if window.is_exterior
      col_name = 'Area of Multiplied Openings'
    else
      col_name = 'Gross Area'
    end
    hpxml_value = window.area
    query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{window_id}' AND ColumnName='#{col_name}' AND Units='m2'"
    sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
    assert_operator(sql_value, :>, 0.01)
    assert_in_epsilon(hpxml_value, sql_value, 0.1)

    # U-Factor
    if window.is_exterior
      col_name = 'Glass U-Factor'
    else
      col_name = 'U-Factor no Film'
    end
    hpxml_value = Constructions.get_ufactor_shgc_adjusted_by_storms(window.storm_type, window.ufactor, window.shgc)[0]
    if window.is_interior
      hpxml_value = 1.0 / (1.0 / hpxml_value - Material.AirFilmVertical.rvalue)
      hpxml_value = 1.0 / (1.0 / hpxml_value - Material.AirFilmVertical.rvalue)
    end
    query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{window_id}' AND ColumnName='#{col_name}' AND Units='W/m2-K'"
    sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)')
    assert_in_epsilon(hpxml_value, sql_value, 0.02)

    next unless window.is_exterior

    # SHGC
    hpxml_value = Constructions.get_ufactor_shgc_adjusted_by_storms(window.storm_type, window.ufactor, window.shgc)[1]
    query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{window_id}' AND ColumnName='Glass SHGC'"
    sql_value = sqlFile.execAndReturnFirstDouble(query).get
    assert_in_delta(hpxml_value, sql_value, 0.01)

    # Azimuth
    hpxml_value = window.azimuth
    query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{window_id}' AND ColumnName='Azimuth' AND Units='deg'"
    sql_value = sqlFile.execAndReturnFirstDouble(query).get
    assert_in_epsilon(hpxml_value, sql_value, 0.01)

    # Tilt
    query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{window_id}' AND ColumnName='Tilt' AND Units='deg'"
    sql_value = sqlFile.execAndReturnFirstDouble(query).get
    assert_in_epsilon(90.0, sql_value, 0.01)
  end

  # Enclosure Skylights
  hpxml_bldg.skylights.each do |skylight|
    skylight_id = skylight.id.upcase

    table_name = 'Exterior Fenestration'

    # Area
    hpxml_value = skylight.area
    query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{skylight_id}' AND ColumnName='Area of Multiplied Openings' AND Units='m2'"
    sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
    assert_operator(sql_value, :>, 0.01)
    assert_in_epsilon(hpxml_value, sql_value, 0.1)

    # U-Factor
    hpxml_value = Constructions.get_ufactor_shgc_adjusted_by_storms(skylight.storm_type, skylight.ufactor, skylight.shgc)[0]
    hpxml_value /= 1.2 # converted to the 20-deg slope from the vertical position by multiplying the tested value at vertical
    query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{skylight_id}' AND ColumnName='Glass U-Factor' AND Units='W/m2-K'"
    sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)')
    assert_in_epsilon(hpxml_value, sql_value, 0.02)

    # SHGC
    hpxml_value = Constructions.get_ufactor_shgc_adjusted_by_storms(skylight.storm_type, skylight.ufactor, skylight.shgc)[1]
    query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{skylight_id}' AND ColumnName='Glass SHGC'"
    sql_value = sqlFile.execAndReturnFirstDouble(query).get
    assert_in_delta(hpxml_value, sql_value, 0.01)

    # Azimuth
    hpxml_value = skylight.azimuth
    query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{skylight_id}' AND ColumnName='Azimuth' AND Units='deg'"
    sql_value = sqlFile.execAndReturnFirstDouble(query).get
    assert_in_epsilon(hpxml_value, sql_value, 0.01)

    # Tilt
    hpxml_value = UnitConversions.convert(Math.atan(skylight.roof.pitch / 12.0), 'rad', 'deg')
    query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{skylight_id}' AND ColumnName='Tilt' AND Units='deg'"
    sql_value = sqlFile.execAndReturnFirstDouble(query).get
    assert_in_epsilon(hpxml_value, sql_value, 0.01)

    table_name = 'Opaque Exterior'
    curb_id = "SURFACE #{skylight.id.upcase}"

    # Skylight curb area
    if not skylight.curb_area.nil?
      hpxml_value = skylight.curb_area
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{curb_id}' AND ColumnName='Net Area' AND Units='m2'"
      sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
      assert_operator(sql_value, :>, 0.01)
      assert_in_epsilon(hpxml_value, sql_value, 0.1)
    end

    # Skylight curb R-value
    if not skylight.curb_assembly_r_value.nil?
      hpxml_value = skylight.curb_assembly_r_value
      query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{curb_id}' AND ColumnName='U-Factor with Film' AND Units='W/m2-K'"
      sql_value = 1.0 / UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)')
      assert_in_epsilon(hpxml_value, sql_value, 0.1)
    end

    table_name = 'Opaque Interior'
    shaft_id = "SURFACE #{skylight.id.upcase} SHAFT"

    # Skylight shaft area
    if not skylight.shaft_area.nil?
      hpxml_value = skylight.shaft_area
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{shaft_id}' AND ColumnName='Gross Area' AND Units='m2'"
      sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
      assert_operator(sql_value, :>, 0.01)
      assert_in_epsilon(hpxml_value, sql_value, 0.1)
    end

    # Skylight shaft R-value
    next unless not skylight.shaft_assembly_r_value.nil?

    # Compare R-value w/o film
    hpxml_value = skylight.shaft_assembly_r_value
    hpxml_value -= Material.AirFilmVertical.rvalue
    hpxml_value -= Material.AirFilmVertical.rvalue
    query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{shaft_id}' AND ColumnName='U-Factor no Film' AND Units='W/m2-K'"
    sql_value = 1.0 / UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)')
    assert_in_epsilon(hpxml_value, sql_value, 0.1)
  end

  # Enclosure Doors
  hpxml_bldg.doors.each do |door|
    door_id = door.id.upcase

    if door.wall.is_exterior
      table_name = 'Exterior Door'
    else
      table_name = 'Interior Door'
    end

    # Area
    if not door.area.nil?
      hpxml_value = door.area
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{door_id}' AND ColumnName='Gross Area' AND Units='m2'"
      sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
      assert_operator(sql_value, :>, 0.01)
      assert_in_delta(hpxml_value, sql_value, 0.1)
    end

    # R-Value
    next if door.r_value.nil?

    hpxml_value = door.r_value
    if door.is_exterior
      col_name = 'U-Factor with Film'
    else
      col_name = 'U-Factor no Film'
      hpxml_value -= 2 * Material.AirFilmVertical.rvalue
    end
    query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{door_id}' AND ColumnName='#{col_name}' AND Units='W/m2-K'"
    sql_value = 1.0 / UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)')
    assert_in_delta(hpxml_value, sql_value, 0.2)
  end

  is_warm_climate = false
  if ['USA_FL_Miami.Intl.AP.722020_TMY3.epw',
      'USA_HI_Honolulu.Intl.AP.911820_TMY3.epw',
      'USA_AZ_Phoenix-Sky.Harbor.Intl.AP.722780_TMY3.epw'].include? hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath
    is_warm_climate = true
  end

  # HVAC Load Fractions
  if not is_warm_climate
    htg_energy = results.select { |k, _v| (k.include?(': Heating (MBtu)') || k.include?(': Heating Fans/Pumps (MBtu)')) && !k.include?('Load') }.values.sum(0.0)
    if hpxml_bldg.total_fraction_heat_load_served > 0
      assert_operator(htg_energy, :>, 0)
    else
      assert_equal(0, htg_energy)
    end
  end
  clg_energy = results.select { |k, _v| (k.include?(': Cooling (MBtu)') || k.include?(': Cooling Fans/Pumps (MBtu)')) && !k.include?('Load') }.values.sum(0.0)
  if hpxml_bldg.total_fraction_cool_load_served > 0
    assert_operator(clg_energy, :>, 0)
  else
    assert_equal(0, clg_energy)
  end

  # Mechanical Ventilation
  whole_vent_fans = hpxml_bldg.ventilation_fans.select { |f| f.used_for_whole_building_ventilation && !f.is_cfis_supplemental_fan }
  local_vent_fans = hpxml_bldg.ventilation_fans.select { |f| f.used_for_local_ventilation }
  fan_cfis = whole_vent_fans.select { |f| f.fan_type == HPXML::MechVentTypeCFIS && f.cfis_addtl_runtime_operating_mode != HPXML::CFISModeNone }
  fan_sup = whole_vent_fans.select { |f| f.fan_type == HPXML::MechVentTypeSupply }
  fan_exh = whole_vent_fans.select { |f| f.fan_type == HPXML::MechVentTypeExhaust }
  fan_bal = whole_vent_fans.select { |f| [HPXML::MechVentTypeBalanced, HPXML::MechVentTypeERV, HPXML::MechVentTypeHRV].include?(f.fan_type) }
  vent_fan_kitchen = local_vent_fans.select { |f| f.fan_location == HPXML::LocationKitchen }
  vent_fan_bath = local_vent_fans.select { |f| f.fan_location == HPXML::LocationBath }

  mv_energy = UnitConversions.convert(results['End Use: Electricity: Mech Vent (MBtu)'], 'MBtu', 'GJ')
  if not (fan_cfis + fan_sup + fan_exh + fan_bal + vent_fan_kitchen + vent_fan_bath).empty?
    if not fan_cfis.empty?
      if (fan_sup + fan_exh + fan_bal + vent_fan_kitchen + vent_fan_bath).empty?
        # CFIS only, check for positive mech vent energy that is less than the energy if it had run 24/7
        max_fan_gj = fan_cfis.select { |f| f.cfis_addtl_runtime_operating_mode == HPXML::CFISModeAirHandler }.map { |f| UnitConversions.convert(f.unit_fan_power * f.hours_in_operation * 365.0, 'Wh', 'GJ') }.sum(0.0)
        max_fan_gj += fan_cfis.select { |f| f.cfis_addtl_runtime_operating_mode == HPXML::CFISModeSupplementalFan }.map { |f| UnitConversions.convert(f.cfis_supplemental_fan.unit_fan_power * (f.average_unit_flow_rate / f.cfis_supplemental_fan.oa_unit_flow_rate * 24) * 365.0, 'Wh', 'GJ') }.sum(0.0)
        assert_operator(mv_energy, :>, 0)
        assert_operator(mv_energy, :<, max_fan_gj)
      end
    else
      # Supply, exhaust, ERV, HRV, etc., check for appropriate mech vent energy
      fan_gj = 0
      fan_gj += (fan_sup + fan_exh + fan_bal).map { |f| UnitConversions.convert(f.unit_fan_power * f.hours_in_operation * 365.0, 'Wh', 'GJ') }.sum(0.0)
      fan_gj += vent_fan_kitchen.map { |f| UnitConversions.convert(f.unit_fan_power * f.hours_in_operation * f.count * 365.0, 'Wh', 'GJ') }.sum(0.0)
      fan_gj += vent_fan_bath.map { |f| UnitConversions.convert(f.unit_fan_power * f.hours_in_operation * f.count * 365.0, 'Wh', 'GJ') }.sum(0.0)
      # Maximum error that can be caused by rounding
      assert_in_delta(mv_energy, fan_gj, 0.006)
    end
  else
    assert_equal(0, mv_energy)
  end

  # Appliances
  tabular_map = { HPXML::ClothesWasher => Constants::ObjectTypeClothesWasher,
                  HPXML::ClothesDryer => Constants::ObjectTypeClothesDryer,
                  HPXML::Refrigerator => Constants::ObjectTypeRefrigerator,
                  HPXML::Dishwasher => Constants::ObjectTypeDishwasher,
                  HPXML::CookingRange => Constants::ObjectTypeCookingRange }

  (hpxml_bldg.clothes_washers + hpxml_bldg.clothes_dryers + hpxml_bldg.refrigerators + hpxml_bldg.dishwashers + hpxml_bldg.cooking_ranges).each do |appliance|
    next unless hpxml_bldg.water_heating_systems.size > 0

    # Location
    hpxml_value = appliance.location
    if hpxml_value.nil? || HPXML::conditioned_locations.include?(hpxml_value) || [HPXML::LocationOtherHeatedSpace, HPXML::LocationOtherMultifamilyBufferSpace, HPXML::LocationOtherNonFreezingSpace].include?(hpxml_value)
      hpxml_value = HPXML::LocationConditionedSpace
    end
    tabular_value = tabular_map[appliance.class]
    query = "SELECT Value FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Zone Name' AND RowName=(SELECT RowName FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Name' AND Value='#{tabular_value.upcase}')"
    sql_value = sqlFile.execAndReturnFirstString(query).get
    assert_equal(hpxml_value.upcase, sql_value)
  end

  # Lighting
  ltg_energy = results.select { |k, _v| k.include? 'End Use: Electricity: Lighting' }.values.sum(0.0)
  if not (hpxml_path.include?('vacancy-year-round') || hpxml_path.include?('residents-0'))
    assert_equal(hpxml_bldg.lighting_groups.size > 0, ltg_energy > 0)
  else
    assert_operator(hpxml_bldg.lighting_groups.size, :>, 0)
    assert_equal(0, ltg_energy)
  end

  # Get fuels
  htg_fuels = []
  htg_backup_fuels = []
  wh_fuels = []
  hpxml_bldg.heating_systems.each do |heating_system|
    if heating_system.is_heat_pump_backup_system
      htg_backup_fuels << heating_system.heating_system_fuel
    else
      htg_fuels << heating_system.heating_system_fuel
    end
  end
  hpxml_bldg.cooling_systems.each do |cooling_system|
    if cooling_system.has_integrated_heating
      htg_fuels << cooling_system.integrated_heating_system_fuel
    end
  end
  hpxml_bldg.heat_pumps.each do |heat_pump|
    if heat_pump.fraction_heat_load_served > 0
      htg_backup_fuels << heat_pump.backup_heating_fuel
    end
  end
  hpxml_bldg.water_heating_systems.each do |water_heating_system|
    related_hvac = water_heating_system.related_hvac_system
    if related_hvac.nil?
      wh_fuels << water_heating_system.fuel_type
    elsif related_hvac.respond_to? :heating_system_fuel
      wh_fuels << related_hvac.heating_system_fuel
    end
  end

  # Fuel consumption checks
  [HPXML::FuelTypeNaturalGas,
   HPXML::FuelTypeOil,
   HPXML::FuelTypeKerosene,
   HPXML::FuelTypePropane,
   HPXML::FuelTypeWoodCord,
   HPXML::FuelTypeWoodPellets,
   HPXML::FuelTypeCoal].each do |fuel|
    fuel_name = fuel.split.map(&:capitalize).join(' ')
    fuel_name += ' Cord' if fuel_name == 'Wood'
    energy_htg = results.fetch("End Use: #{fuel_name}: Heating (MBtu)", 0)
    energy_hp_backup = results.fetch("End Use: #{fuel_name}: Heating Heat Pump Backup (MBtu)", 0)
    energy_dhw = results.fetch("End Use: #{fuel_name}: Hot Water (MBtu)", 0)
    energy_cd = results.fetch("End Use: #{fuel_name}: Clothes Dryer (MBtu)", 0)
    energy_cr = results.fetch("End Use: #{fuel_name}: Range/Oven (MBtu)", 0)
    if htg_fuels.include? fuel
      if (not hpxml_path.include? 'autosize') && (not is_warm_climate)
        assert_operator(energy_htg, :>, 0)
      end
    else
      assert_equal(0, energy_htg)
    end
    if htg_backup_fuels.include? fuel
      has_ashp = hpxml_bldg.heat_pumps.count { |hp| hp.heat_pump_type != HPXML::HVACTypeHeatPumpGroundToAir } > 0
      if (not hpxml_path.include? 'autosize') && (not is_warm_climate) && has_ashp
        assert_operator(energy_hp_backup, :>, 0)
      end
    else
      assert_equal(0, energy_hp_backup)
    end
    if wh_fuels.include? fuel
      assert_operator(energy_dhw, :>, 0)
    else
      assert_equal(0, energy_dhw)
    end
    if (hpxml_bldg.clothes_dryers.size > 0) && (hpxml_bldg.clothes_dryers[0].fuel_type == fuel)
      assert_operator(energy_cd, :>, 0)
    else
      assert_equal(0, energy_cd)
    end
    if (hpxml_bldg.cooking_ranges.size > 0) && (hpxml_bldg.cooking_ranges[0].fuel_type == fuel)
      assert_operator(energy_cr, :>, 0)
    else
      assert_equal(0, energy_cr)
    end
  end

  # Check unmet hours
  unmet_hours_htg = results.select { |k, _v| k.include? 'Unmet Hours: Heating' }.values.sum(0.0)
  unmet_hours_clg = results.select { |k, _v| k.include? 'Unmet Hours: Cooling' }.values.sum(0.0)
  if hpxml_path.include? 'base-hvac-undersized.xml'
    assert_operator(unmet_hours_htg, :>, 1000)
    assert_operator(unmet_hours_clg, :>, 1000)
  else
    if hpxml_bldg.total_fraction_heat_load_served == 0
      assert_equal(0, unmet_hours_htg)
    else
      # for realistic backup staging, unmet hours are expected.
      assert_operator(unmet_hours_htg, :<, 500) unless hpxml_path.include? 'research-features'
    end
    if hpxml_bldg.total_fraction_cool_load_served == 0
      assert_equal(0, unmet_hours_clg)
    else
      assert_operator(unmet_hours_clg, :<, 500)
    end
  end

  sqlFile.close

  # Ensure sql file is immediately freed; otherwise we can get
  # errors on Windows when trying to delete this file.
  GC.start()
end

def _check_unit_multiplier_results(xml, hpxml_bldg, annual_results_1x, annual_results_10x, monthly_results_1x, monthly_results_10x, unit_multiplier)
  # Check that results_10x are expected compared to results_1x

  def get_tolerances(key)
    if key.include?('(MBtu)') || key.include?('(kBtu)') || key.include?('(kWh)')
      # Check that the energy difference is less than 0.5 MBtu or less than 6%
      # FUTURE: Using 12% for duct component load (PR #2026); see if this can be improved.
      abs_delta_tol = 0.5 # MBtu
      if key.include?('Component Load') && key.include?('Ducts')
        abs_frac_tol = 0.12
      else
        abs_frac_tol = 0.06
      end
      if key.include?('(kBtu)')
        abs_delta_tol = UnitConversions.convert(abs_delta_tol, 'MBtu', 'kBtu')
      elsif key.include?('(kWh)')
        abs_delta_tol = UnitConversions.convert(abs_delta_tol, 'MBtu', 'kWh')
      end
    elsif key.include?('Peak Electricity:')
      # Check that the peak electricity difference is less than 500 W or less than 15%
      # Wider tolerances than others because a small change in when an event (like the
      # water heating firing) occurs can significantly impact the peak.
      abs_delta_tol = 500.0
      abs_frac_tol = 0.15
    elsif key.include?('Peak Load:')
      # Check that the peak load difference is less than 0.2 kBtu/hr or less than 5%
      abs_delta_tol = 0.2
      abs_frac_tol = 0.05
    elsif key.include?('Hot Water:')
      # Check that the hot water usage difference is less than 10 gal/yr or less than 2%
      abs_delta_tol = 10.0
      abs_frac_tol = 0.02
    elsif key.include?('Resilience: Battery')
      # Check that the battery resilience difference is less than 1 hr or less than 1%
      abs_delta_tol = 1.0
      abs_frac_tol = 0.01
    elsif key.include?('Airflow:')
      # Check that airflow rate difference is less than 0.2 cfm or less than 1.0%
      abs_delta_tol = 0.2
      abs_frac_tol = 0.01
    elsif key.include?('Unmet Hours:')
      # Check that the unmet hours difference is less than 10 hrs
      abs_delta_tol = 10
      abs_frac_tol = nil
    elsif key.include?('HVAC Capacity:') || key.include?('HVAC Design Load:') || key.include?('HVAC Design Temperature:') || key.include?('Weather:') || key.include?('HVAC Geothermal Loop:') || key.include?('Electric Panel Load:') || key.include?('Electric Panel Breaker Spaces:')
      # Check that there is no difference
      abs_delta_tol = 0
      abs_frac_tol = nil
    elsif key.include?('Emissions:')
      # Check that the emissions difference is less than 100 lb or less than 5%
      abs_delta_tol = 100
      abs_frac_tol = 0.05
    else
      fail "Unexpected results key: #{key}."
    end

    return abs_delta_tol, abs_frac_tol
  end

  # Number of systems and thermal zones change between the 1x and 10x runs,
  # so remove these from the comparison
  annual_results_1x = annual_results_1x.dup
  annual_results_10x = annual_results_10x.dup
  ['System Use:',
   'Temperature:',
   'Humidity Ratio:', 'Relative Humidity:', 'Dewpoint Temperature:', 'Radiant Temperature:', 'Operative Temperature:',
   'Utility Bills:',
   'HVAC Zone Design Load:',
   'HVAC Space Design Load:'].each do |key|
    annual_results_1x.delete_if { |k, _v| k.start_with? key }
    annual_results_10x.delete_if { |k, _v| k.start_with? key }
    monthly_results_1x.delete_if { |k, _v| k.start_with? key }
    monthly_results_10x.delete_if { |k, _v| k.start_with? key }
  end

  # Compare annual and monthly results
  { annual_results_1x => annual_results_10x,
    monthly_results_1x => monthly_results_10x }.each do |results_1x, results_10x|
    keys = (results_1x.keys + results_10x.keys).uniq

    keys.each do |key, vals_1x|
      abs_delta_tol, abs_frac_tol = get_tolerances(key)

      vals_1x = results_1x[key]
      vals_10x = results_10x[key]
      if vals_1x.is_a?(Array) || vals_10x.is_a?(Array)
        is_timeseries = true
        vals_1x = [0.0] * vals_10x.size if vals_1x.nil?
        vals_10x = [0.0] * vals_1x.size if vals_10x.nil?
      else
        is_timeseries = false
        vals_1x = 0.0 if vals_1x.nil?
        vals_10x = 0.0 if vals_10x.nil?
        vals_1x = [vals_1x]
        vals_10x = [vals_10x]
      end
      assert_equal(vals_1x.size, vals_10x.size)

      vals_1x.zip(vals_10x).each_with_index do |(val_1x, val_10x), i|
        period = is_timeseries ? Date::ABBR_MONTHNAMES[i + 1] : 'Annual'
        if not (key.include?('Unmet Hours') ||
                key.include?('HVAC Design Temperature') ||
                key.include?('Weather') ||
                key.include?('HVAC Geothermal Loop: Borehole/Trench Length'))
          # The above output types shouldn't change based on the unit multiplier
          val_1x *= unit_multiplier
        end

        abs_val_delta = (val_1x - val_10x).abs
        abs_avg_val = ([val_1x, val_10x].sum / 2.0).abs
        if abs_avg_val > 0
          abs_val_frac = abs_val_delta / abs_avg_val
        end

        # FUTURE: Address these
        if hpxml_bldg.water_heating_systems.count { |wh| wh.water_heater_type == HPXML::WaterHeaterTypeHeatPump } > 0
          next if key.include?('Airflow:')
          next if key.include?('Peak')
        end
        if hpxml_bldg.water_heating_systems.count { |wh| [HPXML::WaterHeaterTypeCombiStorage, HPXML::WaterHeaterTypeCombiTankless].include? wh.water_heater_type } > 0
          next if key.include?('Hot Water')
        end

        debug_str = "#{File.basename(xml)}: [#{key}, #{period}] 1x=#{val_1x}, 10x=#{val_10x}"
        if abs_frac_tol.nil?
          if abs_delta_tol == 0
            if val_1x != val_10x
              puts "#{debug_str}, abs_delta_tol=#{abs_delta_tol}"
            end
            assert_equal(val_1x, val_10x)
          else
            if (val_1x - val_10x).abs > abs_delta_tol
              puts "#{debug_str}, abs_delta_tol=#{abs_delta_tol}"
            end
            assert_in_delta(val_1x, val_10x, abs_delta_tol)
          end
        else
          if not ((abs_val_delta <= abs_delta_tol) || (!abs_val_frac.nil? && abs_val_frac <= abs_frac_tol))
            if abs_val_frac.nil?
              puts "#{debug_str}, abs_delta_tol=#{abs_delta_tol}"
            else
              puts "#{debug_str}, abs_delta_tol=#{abs_delta_tol}, abs_frac_tol=#{abs_frac_tol}"
            end
          end
          assert((abs_val_delta <= abs_delta_tol) || (!abs_val_frac.nil? && abs_val_frac <= abs_frac_tol))
        end
      end
    end
  end
end

def _write_results(results, csv_out, output_groups_filter: [])
  require 'csv'

  output_groups = {
    'energy' => ['Energy Use', 'Fuel Use', 'End Use'],
    'loads' => ['Load', 'Component Load'],
    'hvac' => ['HVAC Design Temperature', 'HVAC Capacity', 'HVAC Design Load'],
    'misc' => ['Unmet Hours', 'Hot Water', 'Peak Electricity', 'Peak Load', 'Resilience'],
    'bills' => ['Utility Bills'],
    'panel' => ['Electric Panel Load', 'Electric Panel Breaker Spaces'],
  }

  output_groups.each do |output_group, key_types|
    next unless output_groups_filter.empty? || output_groups_filter.include?(output_group)

    output_keys = []
    key_types.each do |key_type|
      results.values.each do |xml_results|
        xml_results.keys.each do |key|
          next if output_keys.include? key
          next if key_type != key.split(':')[0]

          output_keys << key
        end
      end
    end

    this_csv_out = csv_out.gsub('.csv', "_#{output_group}.csv")

    CSV.open(this_csv_out, 'w') do |csv|
      csv << ['HPXML'] + output_keys
      results.sort.each do |xml, xml_results|
        csv_row = [xml]
        output_keys.each do |key|
          if xml_results[key].nil?
            csv_row << 0
          else
            csv_row << xml_results[key]
          end
        end
        csv << csv_row
      end
    end
  end

  puts "Wrote results to #{csv_out.gsub('.csv', '_*.csv')}."
end

# NOTE: Methods below are used by both OS-HPXML & OS-ERI

def _write_ashrae_140_results(all_results, test_results_csv)
  # Write results to csv
  all_results = all_results.sort_by { |k, _v| k.downcase }.to_h
  htg_loads = {}
  clg_loads = {}
  CSV.open(test_results_csv, 'w') do |csv|
    csv << ['Test Case', 'Annual Heating Load [MMBtu]', 'Annual Cooling Load [MMBtu]']
    all_results.each do |xml, results|
      next unless xml.include? 'C.xml'

      csv << [xml] + results
      test_name = File.basename(xml, File.extname(xml))
      htg_loads[test_name] = results[0]
    end
    all_results.each do |xml, results|
      next unless xml.include? 'L.xml'

      csv << [xml] + results
      test_name = File.basename(xml, File.extname(xml))
      clg_loads[test_name] = results[1]
    end
  end
  puts "Wrote results to #{test_results_csv}."

  return htg_loads, clg_loads
end

def _write_hers_hvac_results(all_results, test_results_csv)
  # Write results to csv
  all_results = all_results.sort_by { |k, _v| k.downcase }.to_h
  hvac_energy = {}
  CSV.open(test_results_csv, 'w') do |csv|
    csv << ['Test Case', 'Heat/Cool Energy (MBtu)', 'Fan Energy (MBtu)']
    all_results.each do |xml, results|
      csv << [xml, results[0], results[1]]
      test_name = File.basename(xml, File.extname(xml))
      hvac_energy[test_name] = results[0] + results[1]
    end
  end
  puts "Wrote results to #{test_results_csv}."

  return hvac_energy
end

def _write_hers_dse_results(all_results, test_results_csv)
  # Write results to csv
  all_results = all_results.sort_by { |k, _v| k.downcase }.to_h
  dhw_energy = {}
  CSV.open(test_results_csv, 'w') do |csv|
    csv << ['Test Case', 'Heat/Cool Energy (MBtu)', 'Fan Energy (MBtu)']
    all_results.each do |xml, results|
      csv << [xml, results[0], results[1]]
      test_name = File.basename(xml, File.extname(xml))
      dhw_energy[test_name] = results[0] + results[1]
    end
  end
  puts "Wrote results to #{test_results_csv}."

  return dhw_energy
end

def _write_hers_hot_water_results(all_results, test_results_csv)
  # Write results to csv
  all_results = all_results.sort_by { |k, _v| k.downcase }.to_h
  dhw_energy = {}
  CSV.open(test_results_csv, 'w') do |csv|
    csv << ['Test Case', 'DHW Energy (MBtu)', 'Pump Energy (MBtu)']
    all_results.each do |xml, result|
      wh_energy, recirc_energy = result
      csv << [xml, wh_energy, recirc_energy]
      test_name = File.basename(xml, File.extname(xml))
      dhw_energy[test_name] = wh_energy + recirc_energy
    end
  end
  puts "Wrote results to #{test_results_csv}."

  return dhw_energy
end

def _get_simulation_load_results(results)
  htg_load = results['Load: Heating: Delivered (MBtu)'].round(2)
  clg_load = results['Load: Cooling: Delivered (MBtu)'].round(2)

  return htg_load, clg_load
end

def _get_simulation_hvac_energy_results(results, is_heat, is_electric_heat)
  if not is_heat
    hvac = results["End Use: #{FT::Elec}: #{EUT::Cooling} (MBtu)"].round(2)
    hvac_fan = results["End Use: #{FT::Elec}: #{EUT::CoolingFanPump} (MBtu)"].round(2)
  else
    if is_electric_heat
      hvac = results["End Use: #{FT::Elec}: #{EUT::Heating} (MBtu)"].round(2)
    else
      hvac = results["End Use: #{FT::Gas}: #{EUT::Heating} (MBtu)"].round(2)
    end
    hvac_fan = results["End Use: #{FT::Elec}: #{EUT::HeatingFanPump} (MBtu)"].round(2)
  end

  assert_operator(hvac, :>, 0)
  assert_operator(hvac_fan, :>, 0)

  return hvac.round(2), hvac_fan.round(2)
end

def _get_simulation_hot_water_results(results)
  dhw_energy = (results["End Use: #{FT::Gas}: #{EUT::HotWater} (MBtu)"] +
                results["End Use: #{FT::Elec}: #{EUT::HotWater} (MBtu)"]).round(2)
  recirc_energy = results["End Use: #{FT::Elec}: #{EUT::HotWaterRecircPump} (MBtu)"].round(2)
  return dhw_energy, recirc_energy
end

def _check_ashrae_140_results(htg_loads, clg_loads)
  # Pub 002-2024
  htg_min = [48.07, 74.30, 35.98, 39.74, 45.72, 39.13, 42.17, 48.30, 58.15, 121.76, 126.71, 24.59, 27.72, 57.57, 48.33]
  htg_max = [61.35, 82.96, 48.09, 49.95, 51.97, 55.54, 58.15, 63.40, 74.24, 137.68, 146.84, 81.73, 70.27, 91.66, 56.47]
  htg_dt_min = [17.53, -16.08, -12.92, -12.14, -10.90, -0.56, -1.96, 8.15, 71.16, 3.20, -25.78, -3.14, 7.79, 5.49]
  htg_dt_max = [29.62, -9.44, -5.89, 0.24, -3.37, 6.42, 4.54, 15.14, 79.06, 11.26, 22.68, 11.47, 32.01, 38.95]
  clg_min = [42.50, 47.72, 41.15, 31.54, 21.03, 50.55, 36.63, 52.26, 34.16, 57.07, 50.19]
  clg_max = [58.66, 61.33, 51.69, 41.85, 29.35, 73.48, 59.72, 68.60, 47.58, 73.51, 60.72]
  clg_dt_min = [0.69, -8.24, -18.53, -30.58, 7.51, -16.52, 6.75, -12.95, 11.62, 5.12]
  clg_dt_max = [6.91, -0.22, -9.74, -20.48, 15.77, -11.15, 12.76, -6.58, 17.59, 14.14]

  # Annual Heating Loads
  assert_operator(htg_loads['L100AC'], :<=, htg_max[0])
  assert_operator(htg_loads['L100AC'], :>=, htg_min[0])
  assert_operator(htg_loads['L110AC'], :<=, htg_max[1])
  assert_operator(htg_loads['L110AC'], :>=, htg_min[1])
  assert_operator(htg_loads['L120AC'], :<=, htg_max[2])
  assert_operator(htg_loads['L120AC'], :>=, htg_min[2])
  assert_operator(htg_loads['L130AC'], :<=, htg_max[3])
  assert_operator(htg_loads['L130AC'], :>=, htg_min[3])
  assert_operator(htg_loads['L140AC'], :<=, htg_max[4])
  assert_operator(htg_loads['L140AC'], :>=, htg_min[4])
  assert_operator(htg_loads['L150AC'], :<=, htg_max[5])
  assert_operator(htg_loads['L150AC'], :>=, htg_min[5])
  assert_operator(htg_loads['L155AC'], :<=, htg_max[6])
  assert_operator(htg_loads['L155AC'], :>=, htg_min[6])
  assert_operator(htg_loads['L160AC'], :<=, htg_max[7])
  assert_operator(htg_loads['L160AC'], :>=, htg_min[7])
  assert_operator(htg_loads['L170AC'], :<=, htg_max[8])
  assert_operator(htg_loads['L170AC'], :>=, htg_min[8])
  assert_operator(htg_loads['L200AC'], :<=, htg_max[9])
  assert_operator(htg_loads['L200AC'], :>=, htg_min[9])
  assert_operator(htg_loads['L202AC'], :<=, htg_max[10])
  assert_operator(htg_loads['L202AC'], :>=, htg_min[10])
  assert_operator(htg_loads['L302XC'], :<=, htg_max[11])
  assert_operator(htg_loads['L302XC'], :>=, htg_min[11])
  assert_operator(htg_loads['L304XC'], :<=, htg_max[12])
  assert_operator(htg_loads['L304XC'], :>=, htg_min[12])
  assert_operator(htg_loads['L322XC'], :<=, htg_max[13])
  assert_operator(htg_loads['L322XC'], :>=, htg_min[13])
  assert_operator(htg_loads['L324XC'], :<=, htg_max[14])
  assert_operator(htg_loads['L324XC'], :>=, htg_min[14])

  # Annual Heating Load Deltas
  assert_operator(htg_loads['L110AC'] - htg_loads['L100AC'], :<=, htg_dt_max[0])
  assert_operator(htg_loads['L110AC'] - htg_loads['L100AC'], :>=, htg_dt_min[0])
  assert_operator(htg_loads['L120AC'] - htg_loads['L100AC'], :<=, htg_dt_max[1])
  assert_operator(htg_loads['L120AC'] - htg_loads['L100AC'], :>=, htg_dt_min[1])
  assert_operator(htg_loads['L130AC'] - htg_loads['L100AC'], :<=, htg_dt_max[2])
  assert_operator(htg_loads['L130AC'] - htg_loads['L100AC'], :>=, htg_dt_min[2])
  assert_operator(htg_loads['L140AC'] - htg_loads['L100AC'], :<=, htg_dt_max[3])
  assert_operator(htg_loads['L140AC'] - htg_loads['L100AC'], :>=, htg_dt_min[3])
  assert_operator(htg_loads['L150AC'] - htg_loads['L100AC'], :<=, htg_dt_max[4])
  assert_operator(htg_loads['L150AC'] - htg_loads['L100AC'], :>=, htg_dt_min[4])
  assert_operator(htg_loads['L155AC'] - htg_loads['L150AC'], :<=, htg_dt_max[5])
  assert_operator(htg_loads['L155AC'] - htg_loads['L150AC'], :>=, htg_dt_min[5])
  assert_operator(htg_loads['L160AC'] - htg_loads['L100AC'], :<=, htg_dt_max[6])
  assert_operator(htg_loads['L160AC'] - htg_loads['L100AC'], :>=, htg_dt_min[6])
  assert_operator(htg_loads['L170AC'] - htg_loads['L100AC'], :<=, htg_dt_max[7])
  assert_operator(htg_loads['L170AC'] - htg_loads['L100AC'], :>=, htg_dt_min[7])
  assert_operator(htg_loads['L200AC'] - htg_loads['L100AC'], :<=, htg_dt_max[8])
  assert_operator(htg_loads['L200AC'] - htg_loads['L100AC'], :>=, htg_dt_min[8])
  assert_operator(htg_loads['L202AC'] - htg_loads['L200AC'], :<=, htg_dt_max[9])
  assert_operator(htg_loads['L202AC'] - htg_loads['L200AC'], :>=, htg_dt_min[9])
  assert_operator(htg_loads['L302XC'] - htg_loads['L100AC'], :<=, htg_dt_max[10])
  assert_operator(htg_loads['L302XC'] - htg_loads['L100AC'], :>=, htg_dt_min[10])
  assert_operator(htg_loads['L302XC'] - htg_loads['L304XC'], :<=, htg_dt_max[11])
  assert_operator(htg_loads['L302XC'] - htg_loads['L304XC'], :>=, htg_dt_min[11])
  assert_operator(htg_loads['L322XC'] - htg_loads['L100AC'], :<=, htg_dt_max[12])
  assert_operator(htg_loads['L322XC'] - htg_loads['L100AC'], :>=, htg_dt_min[12])
  assert_operator(htg_loads['L322XC'] - htg_loads['L324XC'], :<=, htg_dt_max[13])
  assert_operator(htg_loads['L322XC'] - htg_loads['L324XC'], :>=, htg_dt_min[13])

  # Annual Cooling Loads
  assert_operator(clg_loads['L100AL'], :<=, clg_max[0])
  assert_operator(clg_loads['L100AL'], :>=, clg_min[0])
  assert_operator(clg_loads['L110AL'], :<=, clg_max[1])
  assert_operator(clg_loads['L110AL'], :>=, clg_min[1])
  assert_operator(clg_loads['L120AL'], :<=, clg_max[2])
  assert_operator(clg_loads['L120AL'], :>=, clg_min[2])
  assert_operator(clg_loads['L130AL'], :<=, clg_max[3])
  assert_operator(clg_loads['L130AL'], :>=, clg_min[3])
  assert_operator(clg_loads['L140AL'], :<=, clg_max[4])
  assert_operator(clg_loads['L140AL'], :>=, clg_min[4])
  assert_operator(clg_loads['L150AL'], :<=, clg_max[5])
  assert_operator(clg_loads['L150AL'], :>=, clg_min[5])
  assert_operator(clg_loads['L155AL'], :<=, clg_max[6])
  assert_operator(clg_loads['L155AL'], :>=, clg_min[6])
  assert_operator(clg_loads['L160AL'], :<=, clg_max[7])
  assert_operator(clg_loads['L160AL'], :>=, clg_min[7])
  assert_operator(clg_loads['L170AL'], :<=, clg_max[8])
  assert_operator(clg_loads['L170AL'], :>=, clg_min[8])
  assert_operator(clg_loads['L200AL'], :<=, clg_max[9])
  assert_operator(clg_loads['L200AL'], :>=, clg_min[9])
  assert_operator(clg_loads['L202AL'], :<=, clg_max[10])
  assert_operator(clg_loads['L202AL'], :>=, clg_min[10])

  # Annual Cooling Load Deltas
  assert_operator(clg_loads['L110AL'] - clg_loads['L100AL'], :<=, clg_dt_max[0])
  assert_operator(clg_loads['L110AL'] - clg_loads['L100AL'], :>=, clg_dt_min[0])
  assert_operator(clg_loads['L120AL'] - clg_loads['L100AL'], :<=, clg_dt_max[1])
  assert_operator(clg_loads['L120AL'] - clg_loads['L100AL'], :>=, clg_dt_min[1])
  assert_operator(clg_loads['L130AL'] - clg_loads['L100AL'], :<=, clg_dt_max[2])
  assert_operator(clg_loads['L130AL'] - clg_loads['L100AL'], :>=, clg_dt_min[2])
  assert_operator(clg_loads['L140AL'] - clg_loads['L100AL'], :<=, clg_dt_max[3])
  assert_operator(clg_loads['L140AL'] - clg_loads['L100AL'], :>=, clg_dt_min[3])
  assert_operator(clg_loads['L150AL'] - clg_loads['L100AL'], :<=, clg_dt_max[4])
  assert_operator(clg_loads['L150AL'] - clg_loads['L100AL'], :>=, clg_dt_min[4])
  assert_operator(clg_loads['L155AL'] - clg_loads['L150AL'], :<=, clg_dt_max[5])
  assert_operator(clg_loads['L155AL'] - clg_loads['L150AL'], :>=, clg_dt_min[5])
  assert_operator(clg_loads['L160AL'] - clg_loads['L100AL'], :<=, clg_dt_max[6])
  assert_operator(clg_loads['L160AL'] - clg_loads['L100AL'], :>=, clg_dt_min[6])
  assert_operator(clg_loads['L170AL'] - clg_loads['L100AL'], :<=, clg_dt_max[7])
  assert_operator(clg_loads['L170AL'] - clg_loads['L100AL'], :>=, clg_dt_min[7])
  assert_operator(clg_loads['L200AL'] - clg_loads['L100AL'], :<=, clg_dt_max[8])
  assert_operator(clg_loads['L200AL'] - clg_loads['L100AL'], :>=, clg_dt_min[8])
  assert_operator(clg_loads['L200AL'] - clg_loads['L202AL'], :<=, clg_dt_max[9])
  assert_operator(clg_loads['L200AL'] - clg_loads['L202AL'], :>=, clg_dt_min[9])
end

def _check_hvac_test_results(energy)
  # Pub 002-2024
  min = [-24.59, -13.13, -42.73, 59.35]
  max = [-18.18, -12.60, -15.88, 110.25]

  # Cooling cases
  assert_operator((energy['HVAC1b'] - energy['HVAC1a']) / energy['HVAC1a'] * 100, :>, min[0])
  assert_operator((energy['HVAC1b'] - energy['HVAC1a']) / energy['HVAC1a'] * 100, :<, max[0])

  # Gas heating cases
  assert_operator((energy['HVAC2b'] - energy['HVAC2a']) / energy['HVAC2a'] * 100, :>, min[1])
  assert_operator((energy['HVAC2b'] - energy['HVAC2a']) / energy['HVAC2a'] * 100, :<, max[1])

  # Electric heating cases
  assert_operator((energy['HVAC2d'] - energy['HVAC2c']) / energy['HVAC2c'] * 100, :>, min[2])
  assert_operator((energy['HVAC2d'] - energy['HVAC2c']) / energy['HVAC2c'] * 100, :<, max[2])
  assert_operator((energy['HVAC2e'] - energy['HVAC2c']) / energy['HVAC2c'] * 100, :>, min[3])
  assert_operator((energy['HVAC2e'] - energy['HVAC2c']) / energy['HVAC2c'] * 100, :<, max[3])
end

def _check_dse_test_results(energy)
  # Pub 002-2024
  htg_min = [9.45, 3.11, 7.40]
  htg_max = [25.72, 6.53, 19.77]
  clg_min = [18.69, 5.23, 16.32]
  clg_max = [29.39, 8.79, 27.47]

  # Heating cases
  assert_operator((energy['HVAC3b'] - energy['HVAC3a']) / energy['HVAC3a'] * 100, :>, htg_min[0])
  assert_operator((energy['HVAC3b'] - energy['HVAC3a']) / energy['HVAC3a'] * 100, :<, htg_max[0])
  assert_operator((energy['HVAC3c'] - energy['HVAC3a']) / energy['HVAC3a'] * 100, :>, htg_min[1])
  assert_operator((energy['HVAC3c'] - energy['HVAC3a']) / energy['HVAC3a'] * 100, :<, htg_max[1])
  assert_operator((energy['HVAC3d'] - energy['HVAC3a']) / energy['HVAC3a'] * 100, :>, htg_min[2])
  assert_operator((energy['HVAC3d'] - energy['HVAC3a']) / energy['HVAC3a'] * 100, :<, htg_max[2])

  # Cooling cases
  assert_operator((energy['HVAC3f'] - energy['HVAC3e']) / energy['HVAC3e'] * 100, :>, clg_min[0])
  assert_operator((energy['HVAC3f'] - energy['HVAC3e']) / energy['HVAC3e'] * 100, :<, clg_max[0])
  assert_operator((energy['HVAC3g'] - energy['HVAC3e']) / energy['HVAC3e'] * 100, :>, clg_min[1])
  assert_operator((energy['HVAC3g'] - energy['HVAC3e']) / energy['HVAC3e'] * 100, :<, clg_max[1])
  assert_operator((energy['HVAC3h'] - energy['HVAC3e']) / energy['HVAC3e'] * 100, :>, clg_min[2])
  assert_operator((energy['HVAC3h'] - energy['HVAC3e']) / energy['HVAC3e'] * 100, :<, clg_max[2])
end

def _check_hot_water(energy)
  # Pub 002-2024
  mn_min = [19.34, 25.76, 17.20, 24.94, 55.93, 22.61, 20.51]
  mn_max = [19.88, 26.55, 17.70, 25.71, 57.58, 23.28, 21.09]
  fl_min = [10.74, 13.37, 8.83, 13.06, 30.84, 12.09, 11.84]
  fl_max = [11.24, 13.87, 9.33, 13.56, 31.55, 12.59, 12.34]
  mn_dt_min = [-6.77, 1.92, 0.58, -31.03, 2.95, 5.09]
  mn_dt_max = [-6.27, 2.42, 1.08, -30.17, 3.45, 5.59]
  fl_dt_min = [-2.88, 1.67, 0.07, -17.82, 1.04, 1.28]
  fl_dt_max = [-2.38, 2.17, 0.57, -17.32, 1.54, 1.78]
  mn_fl_dt_min = [8.37, 12.26, 8.13, 11.75, 25.05, 10.35, 8.46]
  mn_fl_dt_max = [8.87, 12.77, 8.63, 12.25, 26.04, 10.85, 8.96]

  # Duluth MN cases
  assert_operator(energy['L100AD-HW-01'], :>, mn_min[0])
  assert_operator(energy['L100AD-HW-01'], :<, mn_max[0])
  assert_operator(energy['L100AD-HW-02'], :>, mn_min[1])
  assert_operator(energy['L100AD-HW-02'], :<, mn_max[1])
  assert_operator(energy['L100AD-HW-03'], :>, mn_min[2])
  assert_operator(energy['L100AD-HW-03'], :<, mn_max[2])
  assert_operator(energy['L100AD-HW-04'], :>, mn_min[3])
  assert_operator(energy['L100AD-HW-04'], :<, mn_max[3])
  assert_operator(energy['L100AD-HW-05'], :>, mn_min[4])
  assert_operator(energy['L100AD-HW-05'], :<, mn_max[4])
  assert_operator(energy['L100AD-HW-06'], :>, mn_min[5])
  assert_operator(energy['L100AD-HW-06'], :<, mn_max[5])
  assert_operator(energy['L100AD-HW-07'], :>, mn_min[6])
  assert_operator(energy['L100AD-HW-07'], :<, mn_max[6])

  # Miami FL cases
  assert_operator(energy['L100AM-HW-01'], :>, fl_min[0])
  assert_operator(energy['L100AM-HW-01'], :<, fl_max[0])
  assert_operator(energy['L100AM-HW-02'], :>, fl_min[1])
  assert_operator(energy['L100AM-HW-02'], :<, fl_max[1])
  assert_operator(energy['L100AM-HW-03'], :>, fl_min[2])
  assert_operator(energy['L100AM-HW-03'], :<, fl_max[2])
  assert_operator(energy['L100AM-HW-04'], :>, fl_min[3])
  assert_operator(energy['L100AM-HW-04'], :<, fl_max[3])
  assert_operator(energy['L100AM-HW-05'], :>, fl_min[4])
  assert_operator(energy['L100AM-HW-05'], :<, fl_max[4])
  assert_operator(energy['L100AM-HW-06'], :>, fl_min[5])
  assert_operator(energy['L100AM-HW-06'], :<, fl_max[5])
  assert_operator(energy['L100AM-HW-07'], :>, fl_min[6])
  assert_operator(energy['L100AM-HW-07'], :<, fl_max[6])

  # MN Delta cases
  assert_operator(energy['L100AD-HW-01'] - energy['L100AD-HW-02'], :>, mn_dt_min[0])
  assert_operator(energy['L100AD-HW-01'] - energy['L100AD-HW-02'], :<, mn_dt_max[0])
  assert_operator(energy['L100AD-HW-01'] - energy['L100AD-HW-03'], :>, mn_dt_min[1])
  assert_operator(energy['L100AD-HW-01'] - energy['L100AD-HW-03'], :<, mn_dt_max[1])
  assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-04'], :>, mn_dt_min[2])
  assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-04'], :<, mn_dt_max[2])
  assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-05'], :>, mn_dt_min[3])
  assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-05'], :<, mn_dt_max[3])
  assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-06'], :>, mn_dt_min[4])
  assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-06'], :<, mn_dt_max[4])
  assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-07'], :>, mn_dt_min[5])
  assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-07'], :<, mn_dt_max[5])

  # FL Delta cases
  assert_operator(energy['L100AM-HW-01'] - energy['L100AM-HW-02'], :>, fl_dt_min[0])
  assert_operator(energy['L100AM-HW-01'] - energy['L100AM-HW-02'], :<, fl_dt_max[0])
  assert_operator(energy['L100AM-HW-01'] - energy['L100AM-HW-03'], :>, fl_dt_min[1])
  assert_operator(energy['L100AM-HW-01'] - energy['L100AM-HW-03'], :<, fl_dt_max[1])
  assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-04'], :>, fl_dt_min[2])
  assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-04'], :<, fl_dt_max[2])
  assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-05'], :>, fl_dt_min[3])
  assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-05'], :<, fl_dt_max[3])
  assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-06'], :>, fl_dt_min[4])
  assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-06'], :<, fl_dt_max[4])
  assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-07'], :>, fl_dt_min[5])
  assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-07'], :<, fl_dt_max[5])

  # MN-FL Delta cases
  assert_operator(energy['L100AD-HW-01'] - energy['L100AM-HW-01'], :>, mn_fl_dt_min[0])
  assert_operator(energy['L100AD-HW-01'] - energy['L100AM-HW-01'], :<, mn_fl_dt_max[0])
  assert_operator(energy['L100AD-HW-02'] - energy['L100AM-HW-02'], :>, mn_fl_dt_min[1])
  assert_operator(energy['L100AD-HW-02'] - energy['L100AM-HW-02'], :<, mn_fl_dt_max[1])
  assert_operator(energy['L100AD-HW-03'] - energy['L100AM-HW-03'], :>, mn_fl_dt_min[2])
  assert_operator(energy['L100AD-HW-03'] - energy['L100AM-HW-03'], :<, mn_fl_dt_max[2])
  assert_operator(energy['L100AD-HW-04'] - energy['L100AM-HW-04'], :>, mn_fl_dt_min[3])
  assert_operator(energy['L100AD-HW-04'] - energy['L100AM-HW-04'], :<, mn_fl_dt_max[3])
  assert_operator(energy['L100AD-HW-05'] - energy['L100AM-HW-05'], :>, mn_fl_dt_min[4])
  assert_operator(energy['L100AD-HW-05'] - energy['L100AM-HW-05'], :<, mn_fl_dt_max[4])
  assert_operator(energy['L100AD-HW-06'] - energy['L100AM-HW-06'], :>, mn_fl_dt_min[5])
  assert_operator(energy['L100AD-HW-06'] - energy['L100AM-HW-06'], :<, mn_fl_dt_max[5])
  assert_operator(energy['L100AD-HW-07'] - energy['L100AM-HW-07'], :>, mn_fl_dt_min[6])
  assert_operator(energy['L100AD-HW-07'] - energy['L100AM-HW-07'], :<, mn_fl_dt_max[6])
end
