# frozen_string_literal: true

# Collection of methods related to output reporting or writing output files.
module Outputs
  MeterCustomElectricityTotal = 'Electricity:Total'
  MeterCustomElectricityNet = 'Electricity:Net'
  MeterCustomElectricityPV = 'Electricity:PV'

  # Add EMS programs for output reporting. In the case where a whole SFA/MF building is
  # being simulated, these programs are added to the whole building (merged) model, not
  # the individual dwelling unit models.
  #
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_osm_map [Hash] Map of HPXML::Building objects => OpenStudio Model objects for each dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param add_component_loads [Boolean] Whether to calculate component loads (since it incurs a runtime speed penalty)
  # @return [nil]
  def self.apply_ems_programs(model, hpxml_osm_map, hpxml_header, add_component_loads)
    season_day_nums = Outputs.apply_unmet_hours_ems_program(model, hpxml_osm_map, hpxml_header)
    loads_data = Outputs.apply_total_loads_ems_program(model, hpxml_osm_map, hpxml_header)
    if add_component_loads
      Outputs.apply_component_loads_ems_program(model, hpxml_osm_map, loads_data, season_day_nums)
    end
    Outputs.apply_total_airflows_ems_program(model, hpxml_osm_map)
  end

  # Creates an EMS program that calculates heating and cooling unmet hours (number
  # of hours where the heating or cooling setpoint is not maintained).
  #
  # Note: We do our own unmet hours calculation via EMS so that we can incorporate,
  # e.g., heating/cooling seasons into the logic. The calculation layers on top
  # of the built-in EnergyPlus unmet hours output.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_osm_map [Hash] Map of HPXML::Building objects => OpenStudio Model objects for each dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [Hash] Mapping of unit index => heating/cooling season begin and end dates for use by subsequent programs
  def self.apply_unmet_hours_ems_program(model, hpxml_osm_map, hpxml_header)
    # Create sensors and gather data
    htg_sensors, clg_sensors = {}, {}
    zone_air_temp_sensors, htg_spt_sensors, clg_spt_sensors = {}, {}, {}
    total_heat_load_serveds, total_cool_load_serveds = {}, {}
    season_day_nums = {}
    onoff_deadbands = hpxml_header.hvac_onoff_thermostat_deadband.to_f
    hpxml_osm_map.each_with_index do |(hpxml_bldg, unit_model), unit|
      conditioned_zone = unit_model.getThermalZones.find { |z| z.additionalProperties.getFeatureAsString('ObjectType').to_s == HPXML::LocationConditionedSpace }
      conditioned_zone_name = conditioned_zone.name.to_s

      # EMS sensors
      htg_sensors[unit] = Model.add_ems_sensor(
        model,
        name: "#{conditioned_zone_name} htg unmet s",
        output_var_or_meter_name: 'Zone Heating Setpoint Not Met Time',
        key_name: conditioned_zone_name
      )

      clg_sensors[unit] = Model.add_ems_sensor(
        model,
        name: "#{conditioned_zone_name} clg unmet s",
        output_var_or_meter_name: 'Zone Cooling Setpoint Not Met Time',
        key_name: conditioned_zone_name
      )

      total_heat_load_serveds[unit] = hpxml_bldg.total_fraction_heat_load_served
      total_cool_load_serveds[unit] = hpxml_bldg.total_fraction_cool_load_served

      hvac_control = hpxml_bldg.hvac_controls[0]
      next if hvac_control.nil?

      if (onoff_deadbands > 0)
        zone_air_temp_sensors[unit] = Model.add_ems_sensor(
          model,
          name: "#{conditioned_zone_name} space temp",
          output_var_or_meter_name: 'Zone Air Temperature',
          key_name: conditioned_zone_name
        )

        htg_sch = conditioned_zone.thermostatSetpointDualSetpoint.get.heatingSetpointTemperatureSchedule.get
        htg_spt_sensors[unit] = Model.add_ems_sensor(
          model,
          name: "#{htg_sch.name} sch value",
          output_var_or_meter_name: 'Schedule Value',
          key_name: htg_sch.name
        )

        clg_sch = conditioned_zone.thermostatSetpointDualSetpoint.get.coolingSetpointTemperatureSchedule.get
        clg_spt_sensors[unit] = Model.add_ems_sensor(
          model,
          name: "#{clg_sch.name} sch value",
          output_var_or_meter_name: 'Schedule Value',
          key_name: clg_sch.name
        )
      end

      sim_year = hpxml_header.sim_calendar_year
      season_day_nums[unit] = {
        htg_start: Calendar.get_day_num_from_month_day(sim_year, hvac_control.seasons_heating_begin_month, hvac_control.seasons_heating_begin_day),
        htg_end: Calendar.get_day_num_from_month_day(sim_year, hvac_control.seasons_heating_end_month, hvac_control.seasons_heating_end_day),
        clg_start: Calendar.get_day_num_from_month_day(sim_year, hvac_control.seasons_cooling_begin_month, hvac_control.seasons_cooling_begin_day),
        clg_end: Calendar.get_day_num_from_month_day(sim_year, hvac_control.seasons_cooling_end_month, hvac_control.seasons_cooling_end_day)
      }
    end

    hvac_availability_sensor = model.getEnergyManagementSystemSensors.find { |s| s.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants::ObjectTypeHVACAvailabilitySensor }

    # EMS program
    clg_hrs = 'clg_unmet_hours'
    htg_hrs = 'htg_unmet_hours'
    unit_clg_hrs = 'unit_clg_unmet_hours'
    unit_htg_hrs = 'unit_htg_unmet_hours'
    program = Model.add_ems_program(
      model,
      name: 'unmet hours program'
    )
    program.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeUnmetHoursProgram)
    program.addLine("Set #{htg_hrs} = 0")
    program.addLine("Set #{clg_hrs} = 0")
    for unit in 0..hpxml_osm_map.size - 1
      if total_heat_load_serveds[unit] > 0
        program.addLine("Set #{unit_htg_hrs} = 0")
        if season_day_nums[unit][:htg_end] >= season_day_nums[unit][:htg_start]
          line = "If ((DayOfYear >= #{season_day_nums[unit][:htg_start]}) && (DayOfYear <= #{season_day_nums[unit][:htg_end]}))"
        else
          line = "If ((DayOfYear >= #{season_day_nums[unit][:htg_start]}) || (DayOfYear <= #{season_day_nums[unit][:htg_end]}))"
        end
        line += " && (#{hvac_availability_sensor.name} == 1)" if not hvac_availability_sensor.nil?
        program.addLine(line)
        if zone_air_temp_sensors.keys.include? unit # on off deadband
          program.addLine("  If #{zone_air_temp_sensors[unit].name} < (#{htg_spt_sensors[unit].name} - #{UnitConversions.convert(onoff_deadbands, 'deltaF', 'deltaC')})")
          program.addLine("    Set #{unit_htg_hrs} = #{unit_htg_hrs} + #{htg_sensors[unit].name}")
          program.addLine('  EndIf')
        else
          program.addLine("  Set #{unit_htg_hrs} = #{unit_htg_hrs} + #{htg_sensors[unit].name}")
        end
        program.addLine("  If #{unit_htg_hrs} > #{htg_hrs}") # Use max hourly value across all units
        program.addLine("    Set #{htg_hrs} = #{unit_htg_hrs}")
        program.addLine('  EndIf')
        program.addLine('EndIf')
      end
      next unless total_cool_load_serveds[unit] > 0

      program.addLine("Set #{unit_clg_hrs} = 0")
      if season_day_nums[unit][:clg_end] >= season_day_nums[unit][:clg_start]
        line = "If ((DayOfYear >= #{season_day_nums[unit][:clg_start]}) && (DayOfYear <= #{season_day_nums[unit][:clg_end]}))"
      else
        line = "If ((DayOfYear >= #{season_day_nums[unit][:clg_start]}) || (DayOfYear <= #{season_day_nums[unit][:clg_end]}))"
      end
      line += " && (#{hvac_availability_sensor.name} == 1)" if not hvac_availability_sensor.nil?
      program.addLine(line)
      if zone_air_temp_sensors.keys.include? unit # on off deadband
        program.addLine("  If #{zone_air_temp_sensors[unit].name} > (#{clg_spt_sensors[unit].name} + #{UnitConversions.convert(onoff_deadbands, 'deltaF', 'deltaC')})")
        program.addLine("    Set #{unit_clg_hrs} = #{unit_clg_hrs} + #{clg_sensors[unit].name}")
        program.addLine('  EndIf')
      else
        program.addLine("  Set #{unit_clg_hrs} = #{unit_clg_hrs} + #{clg_sensors[unit].name}")
      end
      program.addLine("  If #{unit_clg_hrs} > #{clg_hrs}") # Use max hourly value across all units
      program.addLine("    Set #{clg_hrs} = #{unit_clg_hrs}")
      program.addLine('  EndIf')
      program.addLine('EndIf')
    end

    # EMS calling manager
    Model.add_ems_program_calling_manager(
      model,
      name: "#{program.name} calling manager",
      calling_point: 'EndOfZoneTimestepBeforeZoneReporting',
      ems_programs: [program]
    )

    return season_day_nums
  end

  # Creates an EMS program that calculates total heating and cooling loads delivered
  # by the HVAC system(s).
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_osm_map [Hash] Map of HPXML::Building objects => OpenStudio Model objects for each dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [Array] Misc collection of things for use in the component loads EMS program
  def self.apply_total_loads_ems_program(model, hpxml_osm_map, hpxml_header)
    # Create sensors and gather data
    htg_cond_load_sensors, clg_cond_load_sensors = {}, {}
    htg_duct_load_sensors, clg_duct_load_sensors = {}, {}
    total_heat_load_serveds, total_cool_load_serveds = {}, {}
    dehumidifier_global_vars, dehumidifier_sensors = {}, {}

    hpxml_osm_map.each_with_index do |(hpxml_bldg, unit_model), unit|
      # Retrieve objects
      conditioned_zone_name = unit_model.getThermalZones.find { |z| z.additionalProperties.getFeatureAsString('ObjectType').to_s == HPXML::LocationConditionedSpace }.name.to_s
      duct_zone_names = unit_model.getThermalZones.select { |z| z.isPlenum }.map { |z| z.name.to_s }
      dehumidifier = unit_model.getZoneHVACDehumidifierDXs
      dehumidifier_name = dehumidifier[0].name.to_s unless dehumidifier.empty?

      # Fraction heat/cool load served
      if hpxml_header.apply_ashrae140_assumptions
        total_heat_load_serveds[unit] = 1.0
        total_cool_load_serveds[unit] = 1.0
      else
        total_heat_load_serveds[unit] = hpxml_bldg.total_fraction_heat_load_served
        total_cool_load_serveds[unit] = hpxml_bldg.total_fraction_cool_load_served
      end

      # Energy transferred in conditioned zone, used for determining heating (winter) vs cooling (summer)
      htg_cond_load_sensors[unit] = Model.add_ems_sensor(
        model,
        name: 'htg_load_cond',
        output_var_or_meter_name: "Heating:EnergyTransfer:Zone:#{conditioned_zone_name.upcase}",
        key_name: nil
      )

      clg_cond_load_sensors[unit] = Model.add_ems_sensor(
        model,
        name: 'clg_load_cond',
        output_var_or_meter_name: "Cooling:EnergyTransfer:Zone:#{conditioned_zone_name.upcase}",
        key_name: nil
      )

      # Energy transferred in duct zone(s)
      htg_duct_load_sensors[unit] = []
      clg_duct_load_sensors[unit] = []
      duct_zone_names.each do |duct_zone_name|
        htg_duct_load_sensors[unit] << Model.add_ems_sensor(
          model,
          name: 'htg_load_duct',
          output_var_or_meter_name: "Heating:EnergyTransfer:Zone:#{duct_zone_name.upcase}",
          key_name: nil
        )

        clg_duct_load_sensors[unit] << Model.add_ems_sensor(
          model,
          name: 'clg_load_duct',
          output_var_or_meter_name: "Cooling:EnergyTransfer:Zone:#{duct_zone_name.upcase}",
          key_name: nil
        )
      end

      next if dehumidifier_name.nil?

      # Need to adjust E+ EnergyTransfer meters for dehumidifier internal gains.
      # We also offset the dehumidifier load by one timestep so that it aligns with the EnergyTransfer meters.

      # Global Variable
      dehumidifier_global_vars[unit] = Model.add_ems_global_var(
        model,
        var_name: "prev #{dehumidifier_name}"
      )

      # Initialization Program
      timestep_offset_program = Model.add_ems_program(
        model,
        name: "#{dehumidifier_name} timestep offset init program"
      )
      timestep_offset_program.addLine("Set #{dehumidifier_global_vars[unit].name} = 0")

      # calling managers
      Model.add_ems_program_calling_manager(
        model,
        name: "#{timestep_offset_program.name} calling manager",
        calling_point: 'BeginNewEnvironment',
        ems_programs: [timestep_offset_program]
      )

      Model.add_ems_program_calling_manager(
        model,
        name: "#{timestep_offset_program.name} calling manager2",
        calling_point: 'AfterNewEnvironmentWarmUpIsComplete',
        ems_programs: [timestep_offset_program]
      )

      dehumidifier_sensors[unit] = Model.add_ems_sensor(
        model,
        name: 'ig_dehumidifier',
        output_var_or_meter_name: 'Zone Dehumidifier Sensible Heating Energy',
        key_name: dehumidifier_name
      )
    end

    # EMS program
    program = Model.add_ems_program(
      model,
      name: 'total loads program'
    )
    program.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeTotalLoadsProgram)
    program.addLine('Set loads_htg_tot = 0')
    program.addLine('Set loads_clg_tot = 0')
    for unit in 0..hpxml_osm_map.size - 1
      program.addLine("If #{htg_cond_load_sensors[unit].name} > 0")
      program.addLine("  Set loads_htg_tot = loads_htg_tot + (#{htg_cond_load_sensors[unit].name} - #{clg_cond_load_sensors[unit].name}) * #{total_heat_load_serveds[unit]}")
      for i in 0..htg_duct_load_sensors[unit].size - 1
        program.addLine("  Set loads_htg_tot = loads_htg_tot + (#{htg_duct_load_sensors[unit][i].name} - #{clg_duct_load_sensors[unit][i].name}) * #{total_heat_load_serveds[unit]}")
      end
      if not dehumidifier_global_vars[unit].nil?
        program.addLine("  Set loads_htg_tot = loads_htg_tot - #{dehumidifier_global_vars[unit].name}")
      end
      program.addLine('EndIf')
    end
    program.addLine('Set loads_htg_tot = (@Max loads_htg_tot 0)')
    for unit in 0..hpxml_osm_map.size - 1
      program.addLine("If #{clg_cond_load_sensors[unit].name} > 0")
      program.addLine("  Set loads_clg_tot = loads_clg_tot + (#{clg_cond_load_sensors[unit].name} - #{htg_cond_load_sensors[unit].name}) * #{total_cool_load_serveds[unit]}")
      for i in 0..clg_duct_load_sensors[unit].size - 1
        program.addLine("  Set loads_clg_tot = loads_clg_tot + (#{clg_duct_load_sensors[unit][i].name} - #{htg_duct_load_sensors[unit][i].name}) * #{total_cool_load_serveds[unit]}")
      end
      if not dehumidifier_global_vars[unit].nil?
        program.addLine("  Set loads_clg_tot = loads_clg_tot + #{dehumidifier_global_vars[unit].name}")
      end
      program.addLine('EndIf')
    end
    program.addLine('Set loads_clg_tot = (@Max loads_clg_tot 0)')
    for unit in 0..hpxml_osm_map.size - 1
      if not dehumidifier_global_vars[unit].nil?
        # Store dehumidifier internal gain, will be used in EMS program next timestep
        program.addLine("Set #{dehumidifier_global_vars[unit].name} = #{dehumidifier_sensors[unit].name}")
      end
    end

    # EMS calling manager
    Model.add_ems_program_calling_manager(
      model,
      name: "#{program.name} calling manager",
      calling_point: 'EndOfZoneTimestepAfterZoneReporting',
      ems_programs: [program]
    )

    loads_data = [htg_cond_load_sensors, clg_cond_load_sensors, total_heat_load_serveds, total_cool_load_serveds, dehumidifier_sensors]
    return loads_data
  end

  # Creates an EMS program that calculates component heating and cooling loads (e.g., loads
  # attributes to walls, windows, infiltration, ducts, internal gains, etc.).
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_osm_map [Hash] Map of HPXML::Building objects => OpenStudio Model objects for each dwelling unit
  # @param loads_data [Array] Misc collection of things from the total loads EMS program
  # @param season_day_nums [Hash] Mapping of unit index => heating/cooling season begin and end dates
  # @return [nil]
  def self.apply_component_loads_ems_program(model, hpxml_osm_map, loads_data, season_day_nums)
    htg_cond_load_sensors, clg_cond_load_sensors, total_heat_load_serveds, total_cool_load_serveds, dehumidifier_sensors = loads_data

    # Output diagnostics needed for some output variables used below
    output_diagnostics = model.getOutputDiagnostics
    output_diagnostics.addKey('DisplayAdvancedReportVariables')

    area_tolerance = UnitConversions.convert(1.0, 'ft^2', 'm^2')

    nonsurf_names = ['intgains', 'lighting', 'infil', 'mechvent', 'natvent', 'whf', 'ducts']
    surf_names = ['walls', 'rim_joists', 'foundation_walls', 'floors', 'slabs', 'ceilings',
                  'roofs', 'windows_conduction', 'windows_solar', 'doors', 'skylights_conduction',
                  'skylights_solar', 'internal_mass']

    # EMS program
    program = Model.add_ems_program(
      model,
      name: 'component loads program'
    )
    program.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeComponentLoadsProgram)

    # Initialize
    [:htg, :clg].each do |mode|
      surf_names.each do |surf_name|
        program.addLine("Set loads_#{mode}_#{surf_name} = 0")
      end
      nonsurf_names.each do |nonsurf_name|
        program.addLine("Set loads_#{mode}_#{nonsurf_name} = 0")
      end
    end

    hpxml_osm_map.each_with_index do |(hpxml_bldg, unit_model), unit|
      conditioned_zone = unit_model.getThermalZones.find { |z| z.additionalProperties.getFeatureAsString('ObjectType').to_s == HPXML::LocationConditionedSpace }

      # Prevent certain objects (e.g., OtherEquipment) from being counted towards both, e.g., ducts and internal gains
      objects_already_processed = []

      # EMS Sensors: Surfaces, SubSurfaces, InternalMass
      surfaces_sensors = {}
      surf_names.each do |surf_name|
        surfaces_sensors[surf_name.to_sym] = []
      end

      unit_model.getSurfaces.sort.each do |s|
        next unless s.space.get.thermalZone.get.name.to_s == conditioned_zone.name.to_s

        surface_type = s.additionalProperties.getFeatureAsString('SurfaceType')
        if not surface_type.is_initialized
          fail "Could not identify surface type for surface: '#{s.name}'."
        end

        surface_type = surface_type.get

        s.subSurfaces.each do |ss|
          # Conduction (windows, skylights, doors)
          key = { 'Window' => :windows_conduction,
                  'Door' => :doors,
                  'Skylight' => :skylights_conduction }[surface_type]
          fail "Unexpected subsurface for component loads: '#{ss.name}'." if key.nil?

          if (surface_type == 'Window') || (surface_type == 'Skylight')
            vars = { 'Surface Inside Face Convection Heat Gain Energy' => 'ss_conv',
                     'Surface Inside Face Internal Gains Radiation Heat Gain Energy' => 'ss_ig',
                     'Surface Inside Face Net Surface Thermal Radiation Heat Gain Energy' => 'ss_surf' }
          else
            vars = { 'Surface Inside Face Solar Radiation Heat Gain Energy' => 'ss_sol',
                     'Surface Inside Face Lights Radiation Heat Gain Energy' => 'ss_lgt',
                     'Surface Inside Face Convection Heat Gain Energy' => 'ss_conv',
                     'Surface Inside Face Internal Gains Radiation Heat Gain Energy' => 'ss_ig',
                     'Surface Inside Face Net Surface Thermal Radiation Heat Gain Energy' => 'ss_surf' }
          end

          vars.each do |var, name|
            surfaces_sensors[key] << []
            surfaces_sensors[key][-1] << Model.add_ems_sensor(
              model,
              name: name,
              output_var_or_meter_name: var,
              key_name: ss.name
            )
          end

          # Solar (windows, skylights)
          next unless (surface_type == 'Window') || (surface_type == 'Skylight')

          key = { 'Window' => :windows_solar,
                  'Skylight' => :skylights_solar }[surface_type]
          vars = { 'Surface Window Transmitted Solar Radiation Rate' => 'ss_trans_in',
                   'Surface Window Shortwave from Zone Back Out Window Heat Transfer Rate' => 'ss_back_out',
                   'Surface Inside Face Initial Transmitted Diffuse Transmitted Out Window Solar Radiation Rate' => 'ss_trans_out' }

          surfaces_sensors[key] << []
          vars.each do |var, name|
            surfaces_sensors[key][-1] << Model.add_ems_sensor(
              model,
              name: name,
              output_var_or_meter_name: var,
              key_name: ss.name
            )
          end
        end

        next if s.netArea < area_tolerance # Skip parent surfaces (of subsurfaces) that have near zero net area

        key = { 'FoundationWall' => :foundation_walls,
                'RimJoist' => :rim_joists,
                'Wall' => :walls,
                'Slab' => :slabs,
                'Floor' => :floors,
                'Ceiling' => :ceilings,
                'Roof' => :roofs,
                'Skylight' => :skylights_conduction, # Skylight curb/shaft
                'InferredCeiling' => :internal_mass,
                'InferredFloor' => :internal_mass }[surface_type]
        fail "Unexpected surface for component loads: '#{s.name}'." if key.nil?

        surfaces_sensors[key] << []
        { 'Surface Inside Face Convection Heat Gain Energy' => 's_conv',
          'Surface Inside Face Internal Gains Radiation Heat Gain Energy' => 's_ig',
          'Surface Inside Face Solar Radiation Heat Gain Energy' => 's_sol',
          'Surface Inside Face Lights Radiation Heat Gain Energy' => 's_lgt',
          'Surface Inside Face Net Surface Thermal Radiation Heat Gain Energy' => 's_surf' }.each do |var, name|
          surfaces_sensors[key][-1] << Model.add_ems_sensor(
            model,
            name: name,
            output_var_or_meter_name: var,
            key_name: s.name
          )
        end
      end

      unit_model.getInternalMasss.sort.each do |m|
        next unless m.space.get.thermalZone.get.name.to_s == conditioned_zone.name.to_s

        surfaces_sensors[:internal_mass] << []
        { 'Surface Inside Face Convection Heat Gain Energy' => 'im_conv',
          'Surface Inside Face Internal Gains Radiation Heat Gain Energy' => 'im_ig',
          'Surface Inside Face Solar Radiation Heat Gain Energy' => 'im_sol',
          'Surface Inside Face Lights Radiation Heat Gain Energy' => 'im_lgt',
          'Surface Inside Face Net Surface Thermal Radiation Heat Gain Energy' => 'im_surf' }.each do |var, name|
          surfaces_sensors[:internal_mass][-1] << Model.add_ems_sensor(
            model,
            name: name,
            output_var_or_meter_name: var,
            key_name: m.name
          )
        end
      end

      # EMS Sensors: Infiltration, Natural Ventilation, Whole House Fan
      infil_sensors, natvent_sensors, whf_sensors = [], [], []
      unit_model.getSpaceInfiltrationDesignFlowRates.sort.each do |i|
        next unless i.space.get.thermalZone.get.name.to_s == conditioned_zone.name.to_s

        object_type = i.additionalProperties.getFeatureAsString('ObjectType').get

        { 'Infiltration Sensible Heat Gain Energy' => 'airflow_gain',
          'Infiltration Sensible Heat Loss Energy' => 'airflow_loss' }.each do |var, name|
          airflow_sensor = Model.add_ems_sensor(
            model,
            name: name,
            output_var_or_meter_name: var,
            key_name: i.name
          )

          if object_type == Constants::ObjectTypeInfiltration
            infil_sensors << airflow_sensor
          elsif object_type == Constants::ObjectTypeNaturalVentilation
            natvent_sensors << airflow_sensor
          elsif object_type == Constants::ObjectTypeWholeHouseFan
            whf_sensors << airflow_sensor
          end
        end
      end

      # EMS Sensors: Mechanical Ventilation
      mechvents_sensors = []
      unit_model.getElectricEquipments.sort.each do |o|
        next unless o.endUseSubcategory == Constants::ObjectTypeMechanicalVentilation

        objects_already_processed << o
        { 'Electric Equipment Convective Heating Energy' => 'mv_conv',
          'Electric Equipment Radiant Heating Energy' => 'mv_rad' }.each do |var, name|
          mechvents_sensors << Model.add_ems_sensor(
            model,
            name: name,
            output_var_or_meter_name: var,
            key_name: o.name
          )
        end
      end
      unit_model.getOtherEquipments.sort.each do |o|
        next unless o.endUseSubcategory == Constants::ObjectTypeMechanicalVentilationHouseFan

        objects_already_processed << o
        { 'Other Equipment Convective Heating Energy' => 'mv_conv',
          'Other Equipment Radiant Heating Energy' => 'mv_rad' }.each do |var, name|
          mechvents_sensors << Model.add_ems_sensor(
            model,
            name: name,
            output_var_or_meter_name: var,
            key_name: o.name
          )
        end
      end

      # EMS Sensors: Ducts
      ducts_sensors = []
      ducts_mix_gain_sensor = nil
      ducts_mix_loss_sensor = nil
      conditioned_zone.zoneMixing.each do |zone_mix|
        object_type = zone_mix.additionalProperties.getFeatureAsString('ObjectType').to_s
        next unless object_type == Constants::ObjectTypeDuctLoad

        ducts_mix_gain_sensor = Model.add_ems_sensor(
          model,
          name: 'duct_mix_gain',
          output_var_or_meter_name: 'Zone Mixing Sensible Heat Gain Energy',
          key_name: conditioned_zone.name
        )

        ducts_mix_loss_sensor = Model.add_ems_sensor(
          model,
          name: 'duct_mix_loss',
          output_var_or_meter_name: 'Zone Mixing Sensible Heat Loss Energy',
          key_name: conditioned_zone.name
        )
      end
      unit_model.getOtherEquipments.sort.each do |o|
        next if objects_already_processed.include? o
        next unless o.endUseSubcategory == Constants::ObjectTypeDuctLoad

        objects_already_processed << o
        { 'Other Equipment Convective Heating Energy' => 'ducts_conv',
          'Other Equipment Radiant Heating Energy' => 'ducts_rad' }.each do |var, name|
          ducts_sensors << Model.add_ems_sensor(
            model,
            name: name,
            output_var_or_meter_name: var,
            key_name: o.name
          )
        end
      end

      # EMS Sensors: Lighting
      lightings_sensors = []
      unit_model.getLightss.sort.each do |e|
        next unless e.space.get.thermalZone.get.name.to_s == conditioned_zone.name.to_s

        { 'Lights Convective Heating Energy' => 'ig_lgt_conv',
          'Lights Radiant Heating Energy' => 'ig_lgt_rad',
          'Lights Visible Radiation Heating Energy' => 'ig_lgt_vis' }.each do |var, name|
          lightings_sensors << Model.add_ems_sensor(
            model,
            name: name,
            output_var_or_meter_name: var,
            key_name: e.name
          )
        end
      end

      # EMS Sensors: Internal Gains
      intgains_sensors = []
      unit_model.getElectricEquipments.sort.each do |o|
        next if objects_already_processed.include? o
        next unless o.space.get.thermalZone.get.name.to_s == conditioned_zone.name.to_s

        { 'Electric Equipment Convective Heating Energy' => 'ig_ee_conv',
          'Electric Equipment Radiant Heating Energy' => 'ig_ee_rad' }.each do |var, name|
          intgains_sensors << Model.add_ems_sensor(
            model,
            name: name,
            output_var_or_meter_name: var,
            key_name: o.name
          )
        end
      end

      unit_model.getOtherEquipments.sort.each do |o|
        next if objects_already_processed.include? o
        next unless o.space.get.thermalZone.get.name.to_s == conditioned_zone.name.to_s

        { 'Other Equipment Convective Heating Energy' => 'ig_oe_conv',
          'Other Equipment Radiant Heating Energy' => 'ig_oe_rad' }.each do |var, name|
          intgains_sensors << Model.add_ems_sensor(
            model,
            name: name,
            output_var_or_meter_name: var,
            key_name: o.name
          )
        end
      end

      unit_model.getPeoples.sort.each do |e|
        next unless e.space.get.thermalZone.get.name.to_s == conditioned_zone.name.to_s

        { 'People Convective Heating Energy' => 'ig_ppl_conv',
          'People Radiant Heating Energy' => 'ig_ppl_rad' }.each do |var, name|
          intgains_sensors << Model.add_ems_sensor(
            model,
            name: name,
            output_var_or_meter_name: var,
            key_name: e.name
          )
        end
      end

      if not dehumidifier_sensors[unit].nil?
        intgains_sensors << dehumidifier_sensors[unit]
      end

      intgains_dhw_sensors = {}

      (unit_model.getWaterHeaterMixeds + unit_model.getWaterHeaterStratifieds).sort.each do |wh|
        next unless wh.ambientTemperatureThermalZone.is_initialized
        next unless wh.ambientTemperatureThermalZone.get.name.to_s == conditioned_zone.name.to_s

        dhw_sensor = Model.add_ems_sensor(
          model,
          name: 'dhw_loss',
          output_var_or_meter_name: 'Water Heater Heat Loss Energy',
          key_name: wh.name
        )

        if wh.is_a? OpenStudio::Model::WaterHeaterMixed
          oncycle_loss = wh.onCycleLossFractiontoThermalZone
          offcycle_loss = wh.offCycleLossFractiontoThermalZone
        else
          oncycle_loss = wh.skinLossFractiontoZone
          offcycle_loss = wh.offCycleFlueLossFractiontoZone
        end

        dhw_rtf_sensor = Model.add_ems_sensor(
          model,
          name: 'dhw_rtf',
          output_var_or_meter_name: 'Water Heater Runtime Fraction',
          key_name: wh.name
        )

        intgains_dhw_sensors[dhw_sensor] = [offcycle_loss, oncycle_loss, dhw_rtf_sensor]
      end

      # EMS program: Surfaces
      surfaces_sensors.each do |k, surface_sensors|
        program.addLine("Set hr_#{k} = 0")
        surface_sensors.each do |sensors|
          s = "Set hr_#{k} = hr_#{k}"
          sensors.each do |sensor|
            if sensor.name.to_s.start_with?('ss_trans_in', 'ss_infra', 'ss_glaz')
              s += " - #{sensor.name} * ZoneTimestep * 3600"
            elsif sensor.name.to_s.start_with?('ss_trans_out', 'ss_back_out')
              s += " + #{sensor.name} * ZoneTimestep * 3600"
            else
              s += " + #{sensor.name}"
            end
          end
          program.addLine(s) if sensors.size > 0
        end
      end

      # EMS program: Internal Gains, Lighting, Infiltration, Natural Ventilation, Mechanical Ventilation, Ducts
      { 'intgains' => intgains_sensors,
        'lighting' => lightings_sensors,
        'infil' => infil_sensors,
        'natvent' => natvent_sensors,
        'whf' => whf_sensors,
        'mechvent' => mechvents_sensors,
        'ducts' => ducts_sensors }.each do |loadtype, sensors|
        program.addLine("Set hr_#{loadtype} = 0")
        next if sensors.empty?

        s = "Set hr_#{loadtype} = hr_#{loadtype}"
        sensors.each do |sensor|
          if ['intgains', 'lighting', 'mechvent', 'ducts'].include? loadtype
            s += " - #{sensor.name}"
          elsif sensor.name.to_s.include? 'gain'
            s += " - #{sensor.name}"
          elsif sensor.name.to_s.include? 'loss'
            s += " + #{sensor.name}"
          end
        end
        program.addLine(s)
      end
      intgains_dhw_sensors.each do |sensor, vals|
        off_loss, on_loss, rtf_sensor = vals
        program.addLine("Set hr_intgains = hr_intgains + #{sensor.name} * (#{off_loss}*(1-#{rtf_sensor.name}) + #{on_loss}*#{rtf_sensor.name})") # Water heater tank losses to zone
      end
      if (not ducts_mix_loss_sensor.nil?) && (not ducts_mix_gain_sensor.nil?)
        program.addLine("Set hr_ducts = hr_ducts + (#{ducts_mix_loss_sensor.name} - #{ducts_mix_gain_sensor.name})")
      end

      # EMS Sensors: Indoor temperature, setpoints
      tin_sensor = Model.add_ems_sensor(
        model,
        name: 'tin s',
        output_var_or_meter_name: 'Zone Mean Air Temperature',
        key_name: conditioned_zone.name
      )

      thermostat = nil
      if conditioned_zone.thermostatSetpointDualSetpoint.is_initialized
        thermostat = conditioned_zone.thermostatSetpointDualSetpoint.get

        htg_sp_sensor = Model.add_ems_sensor(
          model,
          name: 'htg sp s',
          output_var_or_meter_name: 'Schedule Value',
          key_name: thermostat.heatingSetpointTemperatureSchedule.get.name
        )

        clg_sp_sensor = Model.add_ems_sensor(
          model,
          name: 'clg sp s',
          output_var_or_meter_name: 'Schedule Value',
          key_name: thermostat.coolingSetpointTemperatureSchedule.get.name
        )
      end

      # EMS program: Heating vs Cooling logic
      program.addLine('Set htg_mode = 0')
      program.addLine('Set clg_mode = 0')
      program.addLine("If (#{htg_cond_load_sensors[unit].name} > 0)") # Assign hour to heating if heating load
      program.addLine("  Set htg_mode = #{total_heat_load_serveds[unit]}")
      program.addLine("ElseIf (#{clg_cond_load_sensors[unit].name} > 0)") # Assign hour to cooling if cooling load
      program.addLine("  Set clg_mode = #{total_cool_load_serveds[unit]}")
      program.addLine('Else')
      program.addLine('  Set htg_season = 0')
      program.addLine('  Set clg_season = 0')
      if not season_day_nums[unit].nil?
        # Determine whether we're in the heating and/or cooling season
        if season_day_nums[unit][:clg_end] >= season_day_nums[unit][:clg_start]
          program.addLine("  If ((DayOfYear >= #{season_day_nums[unit][:clg_start]}) && (DayOfYear <= #{season_day_nums[unit][:clg_end]}))")
        else
          program.addLine("  If ((DayOfYear >= #{season_day_nums[unit][:clg_start]}) || (DayOfYear <= #{season_day_nums[unit][:clg_end]}))")
        end
        program.addLine('    Set clg_season = 1')
        program.addLine('  EndIf')
        if season_day_nums[unit][:htg_end] >= season_day_nums[unit][:htg_start]
          program.addLine("  If ((DayOfYear >= #{season_day_nums[unit][:htg_start]}) && (DayOfYear <= #{season_day_nums[unit][:htg_end]}))")
        else
          program.addLine("  If ((DayOfYear >= #{season_day_nums[unit][:htg_start]}) || (DayOfYear <= #{season_day_nums[unit][:htg_end]}))")
        end
        program.addLine('    Set htg_season = 1')
        program.addLine('  EndIf')
      end
      program.addLine("  If ((#{natvent_sensors[0].name} <> 0) || (#{natvent_sensors[1].name} <> 0)) && (clg_season == 1)") # Assign hour to cooling if natural ventilation is operating
      program.addLine("    Set clg_mode = #{total_cool_load_serveds[unit]}")
      program.addLine("  ElseIf ((#{whf_sensors[0].name} <> 0) || (#{whf_sensors[1].name} <> 0)) && (clg_season == 1)") # Assign hour to cooling if whole house fan is operating
      program.addLine("    Set clg_mode = #{total_cool_load_serveds[unit]}")
      if not thermostat.nil?
        program.addLine('  Else') # Indoor temperature floating between setpoints; determine assignment by comparing to average of heating/cooling setpoints
        program.addLine("    Set Tmid_setpoint = (#{htg_sp_sensor.name} + #{clg_sp_sensor.name}) / 2")
        program.addLine("    If (#{tin_sensor.name} > Tmid_setpoint) && (clg_season == 1)")
        program.addLine("      Set clg_mode = #{total_cool_load_serveds[unit]}")
        program.addLine("    ElseIf (#{tin_sensor.name} < Tmid_setpoint) && (htg_season == 1)")
        program.addLine("      Set htg_mode = #{total_heat_load_serveds[unit]}")
        program.addLine('    EndIf')
      end
      program.addLine('  EndIf')
      program.addLine('EndIf')

      unit_multiplier = hpxml_bldg.building_construction.number_of_units
      [:htg, :clg].each do |mode|
        if mode == :htg
          sign = ''
        else
          sign = '-'
        end
        surf_names.each do |surf_name|
          program.addLine("Set loads_#{mode}_#{surf_name} = loads_#{mode}_#{surf_name} + (#{sign}hr_#{surf_name} * #{mode}_mode * #{unit_multiplier})")
        end
        nonsurf_names.each do |nonsurf_name|
          program.addLine("Set loads_#{mode}_#{nonsurf_name} = loads_#{mode}_#{nonsurf_name} + (#{sign}hr_#{nonsurf_name} * #{mode}_mode * #{unit_multiplier})")
        end
      end
    end

    # EMS calling manager
    Model.add_ems_program_calling_manager(
      model,
      name: "#{program.name} calling manager",
      calling_point: 'EndOfZoneTimestepAfterZoneReporting',
      ems_programs: [program]
    )
  end

  # Creates airflow outputs (for infiltration, ventilation, etc.) that sum across all individual dwelling
  # units for output reporting.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_osm_map [Hash] Map of HPXML::Building objects => OpenStudio Model objects for each dwelling unit
  # @return [nil]
  def self.apply_total_airflows_ems_program(model, hpxml_osm_map)
    # Retrieve objects
    infil_vars = []
    mechvent_vars = []
    natvent_vars = []
    whf_vars = []
    unit_multipliers = []
    hpxml_osm_map.each do |hpxml_bldg, unit_model|
      infil_vars << unit_model.getEnergyManagementSystemGlobalVariables.find { |v| v.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants::ObjectTypeInfiltration }
      mechvent_vars << unit_model.getEnergyManagementSystemGlobalVariables.find { |v| v.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants::ObjectTypeMechanicalVentilation }
      natvent_vars << unit_model.getEnergyManagementSystemGlobalVariables.find { |v| v.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants::ObjectTypeNaturalVentilation }
      whf_vars << unit_model.getEnergyManagementSystemGlobalVariables.find { |v| v.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants::ObjectTypeWholeHouseFan }
      unit_multipliers << hpxml_bldg.building_construction.number_of_units
    end

    # EMS program
    program = Model.add_ems_program(
      model,
      name: 'total airflows program'
    )
    program.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeTotalAirflowsProgram)
    program.addLine('Set total_infil_flow_rate = 0')
    program.addLine('Set total_mechvent_flow_rate = 0')
    program.addLine('Set total_natvent_flow_rate = 0')
    program.addLine('Set total_whf_flow_rate = 0')
    infil_vars.each_with_index do |infil_var, i|
      program.addLine("Set total_infil_flow_rate = total_infil_flow_rate + (#{infil_var.name} * #{unit_multipliers[i]})")
    end
    mechvent_vars.each_with_index do |mechvent_var, i|
      program.addLine("Set total_mechvent_flow_rate = total_mechvent_flow_rate + (#{mechvent_var.name} * #{unit_multipliers[i]})")
    end
    natvent_vars.each_with_index do |natvent_var, i|
      program.addLine("Set total_natvent_flow_rate = total_natvent_flow_rate + (#{natvent_var.name} * #{unit_multipliers[i]})")
    end
    whf_vars.each_with_index do |whf_var, i|
      program.addLine("Set total_whf_flow_rate = total_whf_flow_rate + (#{whf_var.name} * #{unit_multipliers[i]})")
    end

    # EMS calling manager
    Model.add_ems_program_calling_manager(
      model,
      name: "#{program.name} calling manager",
      calling_point: 'EndOfZoneTimestepAfterZoneReporting',
      ems_programs: [program]
    )
  end

  # Populate fields of both unique OpenStudio objects OutputJSON and OutputControlFiles based on the debug argument.
  # Always request MessagePack output.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param debug [Boolean] If true,  writes in.osm, generates additional log output, and creates all E+ output files
  # @return [nil]
  def self.apply_output_file_controls(model, debug)
    oj = model.getOutputJSON
    oj.setOptionType('TimeSeriesAndTabular')
    oj.setOutputJSON(debug)
    oj.setOutputMessagePack(true) # Used by ReportSimulationOutput reporting measure

    ocf = model.getOutputControlFiles
    ocf.setOutputAUDIT(debug)
    ocf.setOutputCSV(debug)
    ocf.setOutputBND(debug)
    ocf.setOutputEIO(debug)
    ocf.setOutputESO(debug)
    ocf.setOutputMDD(debug)
    ocf.setOutputMTD(debug)
    ocf.setOutputMTR(debug)
    ocf.setOutputRDD(debug)
    ocf.setOutputSHD(debug)
    ocf.setOutputCSV(debug)
    ocf.setOutputSQLite(debug)
    ocf.setOutputPerfLog(debug)
    ocf.setOutputTabular(debug)
  end

  # Store some data for use in reporting measure.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml [HPXML] HPXML object
  # @param hpxml_osm_map [Hash] Map of HPXML::Building objects => OpenStudio Model objects for each dwelling unit
  # @param hpxml_path [String] Path to the HPXML file
  # @param building_id [String] HPXML Building ID
  # @param hpxml_defaults_path [String] Path to the HPXML defaults (in.xml) file
  # @return [nil]
  def self.apply_additional_properties(model, hpxml, hpxml_osm_map, hpxml_path, building_id, hpxml_defaults_path)
    additionalProperties = model.getBuilding.additionalProperties
    additionalProperties.setFeature('hpxml_path', hpxml_path)
    additionalProperties.setFeature('hpxml_defaults_path', hpxml_defaults_path)
    additionalProperties.setFeature('building_id', building_id.to_s)
    additionalProperties.setFeature('emissions_scenario_names', hpxml.header.emissions_scenarios.map { |s| s.name }.to_s)
    additionalProperties.setFeature('emissions_scenario_types', hpxml.header.emissions_scenarios.map { |s| s.emissions_type }.to_s)
    heated_zones, cooled_zones = [], []
    hpxml_osm_map.each do |hpxml_bldg, unit_model|
      conditioned_zone_name = unit_model.getThermalZones.find { |z| z.additionalProperties.getFeatureAsString('ObjectType').to_s == HPXML::LocationConditionedSpace }.name.to_s

      heated_zones << conditioned_zone_name if hpxml_bldg.total_fraction_heat_load_served > 0
      cooled_zones << conditioned_zone_name if hpxml_bldg.total_fraction_cool_load_served > 0
    end
    additionalProperties.setFeature('heated_zones', heated_zones.to_s)
    additionalProperties.setFeature('cooled_zones', cooled_zones.to_s)
    additionalProperties.setFeature('is_southern_hemisphere', hpxml_osm_map.keys[0].latitude < 0)
  end

  # Requests very detailed EMS output files to help debug EMS programs line-by-line.
  #
  # Note: The call to this method is commented out by default as this is slow and produces
  # huge output files. It should only be enabled temporarily for debugging purposes.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @return [nil]
  def self.apply_ems_debug_output(model)
    oems = model.getOutputEnergyManagementSystem
    oems.setActuatorAvailabilityDictionaryReporting('Verbose')
    oems.setInternalVariableAvailabilityDictionaryReporting('Verbose')
    oems.setEMSRuntimeLanguageDebugOutputLevel('Verbose')
  end

  # Writes OSM & EPW files to the output directory when in debug mode.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param debug [Boolean] If true, writes the OSM/EPW files to the output dir
  # @param output_dir [String] Path of the output files directory
  # @return [nil]
  def self.write_debug_files(runner, model, weather, debug, output_dir)
    return unless debug

    # Write OSM file to run dir
    osm_output_path = File.join(output_dir, 'in.osm')
    File.write(osm_output_path, model.to_s)
    runner.registerInfo("Wrote file: #{osm_output_path}")

    # Copy EPW file to run dir
    epw_output_path = File.join(output_dir, 'in.epw')
    FileUtils.cp(weather.epw_path, epw_output_path)
  end

  # Calculates total HVAC capacities (across all HVAC systems) for a given HPXML Building.
  # These capacities will be reported in the annual output file.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [Array<Double, Double, Double>] Total heating capacity, total cooling capacity, total heat pump backup capacity (Btu/hr)
  def self.get_total_hvac_capacities(hpxml_bldg)
    htg_cap, clg_cap, hp_backup_cap = 0.0, 0.0, 0.0
    unit_multiplier = hpxml_bldg.building_construction.number_of_units
    hpxml_bldg.hvac_systems.each do |hvac_system|
      if hvac_system.is_a? HPXML::HeatingSystem
        next if hvac_system.is_heat_pump_backup_system

        htg_cap += hvac_system.heating_capacity.to_f * unit_multiplier
      elsif hvac_system.is_a? HPXML::CoolingSystem
        clg_cap += hvac_system.cooling_capacity.to_f * unit_multiplier
        if hvac_system.has_integrated_heating
          htg_cap += hvac_system.integrated_heating_system_capacity.to_f * unit_multiplier
        end
      elsif hvac_system.is_a? HPXML::HeatPump
        htg_cap += hvac_system.heating_capacity.to_f * unit_multiplier
        clg_cap += hvac_system.cooling_capacity.to_f * unit_multiplier
        if hvac_system.backup_type == HPXML::HeatPumpBackupTypeIntegrated
          hp_backup_cap += hvac_system.backup_heating_capacity.to_f * unit_multiplier
        elsif hvac_system.backup_type == HPXML::HeatPumpBackupTypeSeparate
          hp_backup_cap += hvac_system.backup_system.heating_capacity.to_f * unit_multiplier
        end
      end
    end
    return htg_cap, clg_cap, hp_backup_cap
  end

  # Calculates total panel loads (across all service feeders for a given service feeder load type) for a given HPXML Building.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [Array<Double * 14>] Total panel load for each service feeder load type (W)
  def self.get_total_panel_loads(hpxml_bldg)
    htg, clg, hw, cd, dw, ov, vf, sh, sp, ph, pp, wp, ev, oth = 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
    unit_multiplier = hpxml_bldg.building_construction.number_of_units
    hpxml_bldg.electric_panels.each do |electric_panel|
      htg += ElectricPanel.get_service_feeder_heating(hpxml_bldg, electric_panel) * unit_multiplier
      electric_panel.service_feeders.each do |service_feeder|
        if service_feeder.type == HPXML::ElectricPanelLoadTypeCooling
          clg += service_feeder.power * unit_multiplier
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypeWaterHeater
          hw += service_feeder.power * unit_multiplier
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypeClothesDryer
          cd += service_feeder.power * unit_multiplier
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypeDishwasher
          dw += service_feeder.power * unit_multiplier
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypeRangeOven
          ov += service_feeder.power * unit_multiplier
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypeMechVent
          vf += service_feeder.power * unit_multiplier
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypePermanentSpaHeater
          sh += service_feeder.power * unit_multiplier
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypePermanentSpaPump
          sp += service_feeder.power * unit_multiplier
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypePoolHeater
          ph += service_feeder.power * unit_multiplier
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypePoolPump
          pp += service_feeder.power * unit_multiplier
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypeWellPump
          wp += service_feeder.power * unit_multiplier
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypeElectricVehicleCharging
          ev += service_feeder.power * unit_multiplier
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypeLighting ||
              service_feeder.type == HPXML::ElectricPanelLoadTypeKitchen ||
              service_feeder.type == HPXML::ElectricPanelLoadTypeLaundry ||
              service_feeder.type == HPXML::ElectricPanelLoadTypeOther
          oth += service_feeder.power * unit_multiplier
        end
      end
    end
    return htg, clg, hw, cd, dw, ov, vf, sh, sp, ph, pp, wp, ev, oth
  end

  # Calculates total breaker spaces (across all service feeders for a given service feeder load type) for a given HPXML Building.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [Array<Double * 14>] Total breaker spaces for each service feeder load type (W)
  def self.get_total_breaker_spaces(hpxml_bldg)
    htg, clg, hw, cd, dw, ov, vf, sh, sp, ph, pp, wp, ev, oth = 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
    unit_multiplier = hpxml_bldg.building_construction.number_of_units
    hpxml_bldg.electric_panels.each do |electric_panel|
      electric_panel.service_feeders.each do |service_feeder|
        if service_feeder.type == HPXML::ElectricPanelLoadTypeHeating
          service_feeder.components.each do |component|
            component.branch_circuits.each do |branch_circuit|
              htg += branch_circuit.occupied_spaces * unit_multiplier
            end
          end
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypeCooling
          service_feeder.components.each do |component|
            # So we don't double-count, e.g., heat pump breaker spaces since it is shared across two service feeder types
            next unless component.service_feeders.select { |sf| sf.type == HPXML::ElectricPanelLoadTypeHeating }.empty?

            component.branch_circuits.each do |branch_circuit|
              clg += branch_circuit.occupied_spaces * unit_multiplier
            end
          end
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypeWaterHeater
          service_feeder.components.each do |component|
            component.branch_circuits.each do |branch_circuit|
              hw += branch_circuit.occupied_spaces * unit_multiplier
            end
          end
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypeClothesDryer
          service_feeder.components.each do |component|
            component.branch_circuits.each do |branch_circuit|
              cd += branch_circuit.occupied_spaces * unit_multiplier
            end
          end
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypeDishwasher
          service_feeder.components.each do |component|
            component.branch_circuits.each do |branch_circuit|
              dw += branch_circuit.occupied_spaces * unit_multiplier
            end
          end
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypeRangeOven
          service_feeder.components.each do |component|
            component.branch_circuits.each do |branch_circuit|
              ov += branch_circuit.occupied_spaces * unit_multiplier
            end
          end
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypeMechVent
          service_feeder.components.each do |component|
            component.branch_circuits.each do |branch_circuit|
              vf += branch_circuit.occupied_spaces * unit_multiplier
            end
          end
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypePermanentSpaHeater
          service_feeder.components.each do |component|
            component.heater_branch_circuits.each do |branch_circuit|
              sh += branch_circuit.occupied_spaces * unit_multiplier
            end
          end
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypePermanentSpaPump
          service_feeder.components.each do |component|
            component.pump_branch_circuits.each do |branch_circuit|
              sp += branch_circuit.occupied_spaces * unit_multiplier
            end
          end
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypePoolHeater
          service_feeder.components.each do |component|
            component.heater_branch_circuits.each do |branch_circuit|
              ph += branch_circuit.occupied_spaces * unit_multiplier
            end
          end
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypePoolPump
          service_feeder.components.each do |component|
            component.pump_branch_circuits.each do |branch_circuit|
              pp += branch_circuit.occupied_spaces * unit_multiplier
            end
          end
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypeWellPump
          service_feeder.components.each do |component|
            component.branch_circuits.each do |branch_circuit|
              wp += branch_circuit.occupied_spaces * unit_multiplier
            end
          end
        elsif service_feeder.type == HPXML::ElectricPanelLoadTypeElectricVehicleCharging
          service_feeder.components.each do |component|
            component.branch_circuits.each do |branch_circuit|
              ev += branch_circuit.occupied_spaces * unit_multiplier
            end
          end
        end
      end
      electric_panel.branch_circuits.each do |branch_circuit|
        if branch_circuit.components.empty?
          oth += branch_circuit.occupied_spaces * unit_multiplier
        end
      end
    end
    return htg, clg, hw, cd, dw, ov, vf, sh, sp, ph, pp, wp, ev, oth
  end

  # Calculates total HVAC airflow rates (across all HVAC systems) for a given HPXML Building.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [Array<Double, Double>] Total heating airflow rate, total cooling airflow rate (cfm)
  def self.get_total_hvac_airflows(hpxml_bldg)
    htg_cfm, clg_cfm = 0.0, 0.0
    unit_multiplier = hpxml_bldg.building_construction.number_of_units
    hpxml_bldg.hvac_systems.each do |hvac_system|
      if hvac_system.is_a? HPXML::HeatingSystem
        htg_cfm += hvac_system.heating_airflow_cfm.to_f * unit_multiplier
      elsif hvac_system.is_a? HPXML::CoolingSystem
        clg_cfm += hvac_system.cooling_airflow_cfm.to_f * unit_multiplier
        if hvac_system.has_integrated_heating
          htg_cfm += hvac_system.integrated_heating_system_airflow_cfm.to_f * unit_multiplier
        end
      elsif hvac_system.is_a? HPXML::HeatPump
        htg_cfm += hvac_system.heating_airflow_cfm.to_f * unit_multiplier
        clg_cfm += hvac_system.cooling_airflow_cfm.to_f * unit_multiplier
      end
    end
    return htg_cfm, clg_cfm
  end

  # Appends HVAC sizing results to the provided array for use in writing output files.
  #
  # @param hpxml_bldgs [Array<HPXML::Building>] List of HPXML Building objects representing an individual dwelling unit
  # @param results_out [Array] Rows of output data
  # @return [Array] Rows of output data, with HVAC sizing results appended
  def self.append_sizing_results(hpxml_bldgs, results_out)
    line_break = nil

    # Summary HVAC capacities
    results_out << ['HVAC Capacity: Heating (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_hvac_capacities(hpxml_bldg)[0] }.sum(0.0).round(1)]
    results_out << ['HVAC Capacity: Cooling (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_hvac_capacities(hpxml_bldg)[1] }.sum(0.0).round(1)]
    results_out << ['HVAC Capacity: Heat Pump Backup (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_hvac_capacities(hpxml_bldg)[2] }.sum(0.0).round(1)]

    # HVAC design temperatures
    results_out << [line_break]
    results_out << ['HVAC Design Temperature: Heating (F)', (hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.header.manualj_heating_design_temp }.sum(0.0) / hpxml_bldgs.size).round(2)]
    results_out << ['HVAC Design Temperature: Cooling (F)', (hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.header.manualj_cooling_design_temp }.sum(0.0) / hpxml_bldgs.size).round(2)]

    # HVAC Building design loads
    results_out << [line_break]
    results_out << ['HVAC Design Load: Heating: Total (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_total * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Ducts (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_ducts * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Windows (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_windows * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Skylights (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_skylights * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Doors (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_doors * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Walls (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_walls * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Roofs (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_roofs * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Floors (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_floors * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Slabs (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_slabs * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Ceilings (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_ceilings * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Infiltration (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_infil * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Ventilation (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_vent * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Piping (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_piping * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Total (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_total * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Ducts (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_ducts * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Windows (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_windows * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Skylights (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_skylights * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Doors (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_doors * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Walls (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_walls * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Roofs (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_roofs * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Floors (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_floors * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Slabs (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_slabs * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Ceilings (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_ceilings * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Infiltration (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_infil * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Ventilation (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_vent * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Internal Gains (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_intgains * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Blower Heat (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_blowerheat * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: AED Excursion (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_aedexcursion * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Latent: Total (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_lat_total * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Latent: Ducts (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_lat_ducts * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Latent: Infiltration (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_lat_infil * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Latent: Ventilation (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_lat_vent * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Latent: Internal Gains (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_lat_intgains * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]

    # HVAC Zone design loads
    hpxml_bldgs.each do |hpxml_bldg|
      hpxml_bldg.conditioned_zones.each do |zone|
        next if zone.id.start_with? Constants::AutomaticallyAdded

        results_out << [line_break]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Total (Btu/h)", zone.hdl_total.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Ducts (Btu/h)", zone.hdl_ducts.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Windows (Btu/h)", zone.hdl_windows.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Skylights (Btu/h)", zone.hdl_skylights.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Doors (Btu/h)", zone.hdl_doors.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Walls (Btu/h)", zone.hdl_walls.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Roofs (Btu/h)", zone.hdl_roofs.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Floors (Btu/h)", zone.hdl_floors.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Slabs (Btu/h)", zone.hdl_slabs.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Ceilings (Btu/h)", zone.hdl_ceilings.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Infiltration (Btu/h)", zone.hdl_infil.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Ventilation (Btu/h)", zone.hdl_vent.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Piping (Btu/h)", zone.hdl_piping.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Total (Btu/h)", zone.cdl_sens_total.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Ducts (Btu/h)", zone.cdl_sens_ducts.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Windows (Btu/h)", zone.cdl_sens_windows.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Skylights (Btu/h)", zone.cdl_sens_skylights.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Doors (Btu/h)", zone.cdl_sens_doors.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Walls (Btu/h)", zone.cdl_sens_walls.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Roofs (Btu/h)", zone.cdl_sens_roofs.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Floors (Btu/h)", zone.cdl_sens_floors.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Slabs (Btu/h)", zone.cdl_sens_slabs.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Ceilings (Btu/h)", zone.cdl_sens_ceilings.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Infiltration (Btu/h)", zone.cdl_sens_infil.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Ventilation (Btu/h)", zone.cdl_sens_vent.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Internal Gains (Btu/h)", zone.cdl_sens_intgains.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Blower Heat (Btu/h)", zone.cdl_sens_blowerheat.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: AED Excursion (Btu/h)", zone.cdl_sens_aedexcursion.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Latent: Total (Btu/h)", zone.cdl_lat_total.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Latent: Ducts (Btu/h)", zone.cdl_lat_ducts.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Latent: Infiltration (Btu/h)", zone.cdl_lat_infil.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Latent: Ventilation (Btu/h)", zone.cdl_lat_vent.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Latent: Internal Gains (Btu/h)", zone.cdl_lat_intgains.round(1)]
      end
    end

    # HVAC Space design loads
    hpxml_bldgs.each do |hpxml_bldg|
      hpxml_bldg.conditioned_spaces.each do |space|
        results_out << [line_break]
        # Note: Latent loads are not calculated for spaces
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Total (Btu/h)", space.hdl_total.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Ducts (Btu/h)", space.hdl_ducts.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Windows (Btu/h)", space.hdl_windows.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Skylights (Btu/h)", space.hdl_skylights.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Doors (Btu/h)", space.hdl_doors.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Walls (Btu/h)", space.hdl_walls.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Roofs (Btu/h)", space.hdl_roofs.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Floors (Btu/h)", space.hdl_floors.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Slabs (Btu/h)", space.hdl_slabs.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Ceilings (Btu/h)", space.hdl_ceilings.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Infiltration (Btu/h)", space.hdl_infil.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Total (Btu/h)", space.cdl_sens_total.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Ducts (Btu/h)", space.cdl_sens_ducts.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Windows (Btu/h)", space.cdl_sens_windows.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Skylights (Btu/h)", space.cdl_sens_skylights.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Doors (Btu/h)", space.cdl_sens_doors.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Walls (Btu/h)", space.cdl_sens_walls.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Roofs (Btu/h)", space.cdl_sens_roofs.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Floors (Btu/h)", space.cdl_sens_floors.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Slabs (Btu/h)", space.cdl_sens_slabs.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Ceilings (Btu/h)", space.cdl_sens_ceilings.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Infiltration (Btu/h)", space.cdl_sens_infil.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Internal Gains (Btu/h)", space.cdl_sens_intgains.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: AED Excursion (Btu/h)", space.cdl_sens_aedexcursion.round(1)]
      end
    end

    # Geothermal loop
    results_out << [line_break]
    geothermal_loops = hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.geothermal_loops }.flatten
    num_boreholes = geothermal_loops.map { |loop| loop.num_bore_holes }.sum(0)
    total_length = geothermal_loops.map { |loop| loop.bore_length * loop.num_bore_holes }.sum(0.0)
    results_out << ['HVAC Geothermal Loop: Borehole/Trench Count', num_boreholes]
    results_out << ['HVAC Geothermal Loop: Borehole/Trench Length (ft)', (total_length / [num_boreholes, 1].max).round(1)] # [num_boreholes, 1].max to prevent divide by zero

    return results_out
  end

  # Returns electric panel results for use in writing output files.
  #
  # @param hpxml_bldgs [Array<HPXML::Building>] List of HPXML Building objects representing an individual dwelling unit
  # @return [Array] Rows of output data, with electric panel results appended
  def self.get_panel_results(hpxml_header, hpxml_bldgs)
    results_out = []

    # Currently, we only write this file if:
    # (1) at least one load calculation type is specified
    # (2) an electric panel is specified
    if hpxml_header.service_feeders_load_calculation_types.empty?
      return results_out
    elsif hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.electric_panels.size }.sum == 0
      return results_out
    end

    line_break = nil

    # Summary breaker spaces
    results_out << ['Electric Panel Breaker Spaces: Heating Count', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_breaker_spaces(hpxml_bldg)[0] }.sum(0)]
    results_out << ['Electric Panel Breaker Spaces: Cooling Count', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_breaker_spaces(hpxml_bldg)[1] }.sum(0)]
    results_out << ['Electric Panel Breaker Spaces: Hot Water Count', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_breaker_spaces(hpxml_bldg)[2] }.sum(0)]
    results_out << ['Electric Panel Breaker Spaces: Clothes Dryer Count', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_breaker_spaces(hpxml_bldg)[3] }.sum(0)]
    results_out << ['Electric Panel Breaker Spaces: Dishwasher Count', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_breaker_spaces(hpxml_bldg)[4] }.sum(0)]
    results_out << ['Electric Panel Breaker Spaces: Range/Oven Count', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_breaker_spaces(hpxml_bldg)[5] }.sum(0)]
    results_out << ['Electric Panel Breaker Spaces: Mech Vent Count', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_breaker_spaces(hpxml_bldg)[6] }.sum(0)]
    results_out << ['Electric Panel Breaker Spaces: Permanent Spa Heater Count', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_breaker_spaces(hpxml_bldg)[7] }.sum(0)]
    results_out << ['Electric Panel Breaker Spaces: Permanent Spa Pump Count', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_breaker_spaces(hpxml_bldg)[8] }.sum(0)]
    results_out << ['Electric Panel Breaker Spaces: Pool Heater Count', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_breaker_spaces(hpxml_bldg)[9] }.sum(0)]
    results_out << ['Electric Panel Breaker Spaces: Pool Pump Count', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_breaker_spaces(hpxml_bldg)[10] }.sum(0)]
    results_out << ['Electric Panel Breaker Spaces: Well Pump Count', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_breaker_spaces(hpxml_bldg)[11] }.sum(0)]
    results_out << ['Electric Panel Breaker Spaces: Electric Vehicle Charging Count', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_breaker_spaces(hpxml_bldg)[12] }.sum(0)]
    results_out << ['Electric Panel Breaker Spaces: Other Count', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_breaker_spaces(hpxml_bldg)[13] }.sum(0)]

    # Total breaker spaces
    results_out << [line_break]
    results_out << ['Electric Panel Breaker Spaces: Total Count', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.electric_panels.map { |electric_panel| electric_panel.breaker_spaces_total }.sum(0.0) * hpxml_bldg.building_construction.number_of_units }.sum(0.0)]
    results_out << ['Electric Panel Breaker Spaces: Occupied Count', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.electric_panels.map { |electric_panel| electric_panel.breaker_spaces_occupied }.sum(0.0) * hpxml_bldg.building_construction.number_of_units }.sum(0.0)]
    results_out << ['Electric Panel Breaker Spaces: Headroom Count', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.electric_panels.map { |electric_panel| electric_panel.breaker_spaces_headroom }.sum(0.0) * hpxml_bldg.building_construction.number_of_units }.sum(0.0)]

    # Summary panel loads
    results_out << [line_break]
    results_out << ['Electric Panel Load: Heating (W)', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_panel_loads(hpxml_bldg)[0] }.sum(0.0).round(1)]
    results_out << ['Electric Panel Load: Cooling (W)', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_panel_loads(hpxml_bldg)[1] }.sum(0.0).round(1)]
    results_out << ['Electric Panel Load: Hot Water (W)', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_panel_loads(hpxml_bldg)[2] }.sum(0.0).round(1)]
    results_out << ['Electric Panel Load: Clothes Dryer (W)', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_panel_loads(hpxml_bldg)[3] }.sum(0.0).round(1)]
    results_out << ['Electric Panel Load: Dishwasher (W)', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_panel_loads(hpxml_bldg)[4] }.sum(0.0).round(1)]
    results_out << ['Electric Panel Load: Range/Oven (W)', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_panel_loads(hpxml_bldg)[5] }.sum(0.0).round(1)]
    results_out << ['Electric Panel Load: Mech Vent (W)', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_panel_loads(hpxml_bldg)[6] }.sum(0.0).round(1)]
    results_out << ['Electric Panel Load: Permanent Spa Heater (W)', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_panel_loads(hpxml_bldg)[7] }.sum(0.0).round(1)]
    results_out << ['Electric Panel Load: Permanent Spa Pump (W)', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_panel_loads(hpxml_bldg)[8] }.sum(0.0).round(1)]
    results_out << ['Electric Panel Load: Pool Heater (W)', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_panel_loads(hpxml_bldg)[9] }.sum(0.0).round(1)]
    results_out << ['Electric Panel Load: Pool Pump (W)', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_panel_loads(hpxml_bldg)[10] }.sum(0.0).round(1)]
    results_out << ['Electric Panel Load: Well Pump (W)', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_panel_loads(hpxml_bldg)[11] }.sum(0.0).round(1)]
    results_out << ['Electric Panel Load: Electric Vehicle Charging (W)', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_panel_loads(hpxml_bldg)[12] }.sum(0.0).round(1)]
    results_out << ['Electric Panel Load: Other (W)', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_panel_loads(hpxml_bldg)[13] }.sum(0.0).round(1)]

    # Load calculations
    hpxml_header.service_feeders_load_calculation_types.each do |service_feeders_load_calculation_type|
      capacity_total_watt = 0.0
      capacity_total_amp = 0.0
      capacity_headroom_amp = 0.0
      hpxml_bldgs.each do |hpxml_bldg|
        hpxml_bldg.electric_panels.each do |electric_panel|
          capacity_types = electric_panel.capacity_types
          capacity_total_watts = electric_panel.capacity_total_watts
          capacity_total_amps = electric_panel.capacity_total_amps
          capacity_headroom_amps = electric_panel.capacity_headroom_amps
          capacities = capacity_types.zip(capacity_total_watts, capacity_total_amps, capacity_headroom_amps)
          capacities.each do |capacity|
            ct, ctw, cta, cha = capacity
            next if ct != service_feeders_load_calculation_type

            capacity_total_watt += ctw * hpxml_bldg.building_construction.number_of_units
            capacity_total_amp += cta * hpxml_bldg.building_construction.number_of_units
            capacity_headroom_amp += cha * hpxml_bldg.building_construction.number_of_units
          end
        end
      end
      results_out << [line_break]
      results_out << ["Electric Panel Load: #{service_feeders_load_calculation_type}: Total Load (W)", capacity_total_watt.round(1)]
      results_out << ["Electric Panel Load: #{service_feeders_load_calculation_type}: Total Capacity (A)", capacity_total_amp.round(1)]
      results_out << ["Electric Panel Load: #{service_feeders_load_calculation_type}: Headroom Capacity (A)", capacity_headroom_amp.round(1)]
    end

    return results_out
  end

  # Writes an output file for the given rows of output data.
  #
  # @param results_out [Array] Rows of output data
  # @param output_format [String] Type of output file (csv, json, or msgpack)
  # @param output_file_path [String] Path for the output file
  # @param mode [String] File opening mode (e.g., write or append)
  # @return [nil]
  def self.write_results_out_to_file(results_out, output_format, output_file_path, mode = 'w')
    line_break = nil
    if ['csv'].include? output_format
      CSV.open(output_file_path, mode) { |csv| results_out.to_a.each { |elem| csv << elem } }
    elsif ['json', 'msgpack'].include? output_format
      h = {}
      results_out.each do |out|
        next if out == [line_break]

        if out[0].include? ':'
          grp, name = out[0].split(':', 2)
          h[grp] = {} if h[grp].nil?
          h[grp][name.strip] = out[1]
        else
          h[out[0]] = out[1]
        end
      end

      if output_format == 'json'
        require 'json'
        File.open(output_file_path, mode) { |json| json.write(JSON.pretty_generate(h)) }
      elsif output_format == 'msgpack'
        require 'msgpack'
        File.open(output_file_path, "#{mode}b") { |json| h.to_msgpack(json) }
      end
    end
  end

  # Register to the runner for the given rows of output data.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param results_out [Array] Rows of output data
  # @return [nil]
  def self.register_results_out_to_runner(runner, results_out)
    results_out.each do |name, value|
      next if name.nil? || value.nil?

      name = OpenStudio::toUnderscoreCase(name).chomp('_')

      runner.registerValue(name, value)
      runner.registerInfo("Registering #{value} for #{name}.")
    end
  end

  # Creates custom output meters that are used across reporting measures.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @return [nil]
  def self.create_custom_meters(model)
    # Create custom meters:
    # - Total Electricity (Electricity:Facility plus EV charging, batteries, generators)
    # - Net Electricity (above plus PV)
    # - PV Electricity

    total_key_vars = []
    net_key_vars = []
    pv_key_vars = []
    model.getElectricLoadCenterDistributions.each do |elcd|
      # Batteries & EV charging output variables
      if elcd.electricalStorage.is_initialized
        elcs = elcd.electricalStorage.get
        if elcs.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants::ObjectTypeVehicle
          net_key_vars << [elcs.name.to_s.upcase, 'Electric Storage Production Decrement Energy']
          total_key_vars << net_key_vars[-1]
        elsif elcs.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants::ObjectTypeBattery
          net_key_vars << [elcs.name.to_s.upcase, 'Electric Storage Production Decrement Energy']
          total_key_vars << net_key_vars[-1]
          net_key_vars << [elcs.name.to_s.upcase, 'Electric Storage Discharge Energy']
          total_key_vars << net_key_vars[-1]
        end
      end

      # PV output meters
      elcd.generators.each do |generator|
        next unless generator.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants::ObjectTypePhotovoltaics

        net_key_vars << ['', 'Photovoltaic:ElectricityProduced']
        pv_key_vars << net_key_vars[-1]
        net_key_vars << ['', 'PowerConversion:ElectricityProduced']
        pv_key_vars << net_key_vars[-1]
      end

      # Generator output meter
      elcd.generators.each do |generator|
        next unless generator.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants::ObjectTypeGenerator

        net_key_vars << ['', 'Cogeneration:ElectricityProduced']
        total_key_vars << net_key_vars[-1]
      end
    end

    # Create Total/Net meters
    { MeterCustomElectricityTotal => total_key_vars,
      MeterCustomElectricityNet => net_key_vars }.each do |meter_name, key_vars|
      if key_vars.empty?
        # Avoid OpenStudio warnings if nothing to decrement
        meter = OpenStudio::Model::MeterCustom.new(model)
        key_vars << ['', 'Electricity:Facility']
      else
        meter = OpenStudio::Model::MeterCustomDecrement.new(model, 'Electricity:Facility')
      end
      meter.setName(meter_name)
      meter.setFuelType(EPlus::FuelTypeElectricity)
      key_vars.uniq.each do |key_var|
        meter.addKeyVarGroup(key_var[0], key_var[1])
      end
    end

    # Create PV meter
    if not pv_key_vars.empty?
      meter = OpenStudio::Model::MeterCustom.new(model)
      meter.setName(MeterCustomElectricityPV)
      meter.setFuelType(EPlus::FuelTypeElectricity)
      pv_key_vars.uniq.each do |key_var|
        meter.addKeyVarGroup(key_var[0], key_var[1])
      end
    end
  end
end
