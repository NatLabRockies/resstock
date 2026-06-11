# frozen_string_literal: true

# Collection of methods related to airflow modeling (e.g., infiltration, natural ventilation,
# mechanical ventilation, ducts, etc.).
module Airflow
  # Constants
  InfilPressureExponent = 0.65
  AssumedInsideTemp = 73.5 # (F)
  Gravity = 32.174 # acceleration of gravity (ft/s2)
  UnventedSpaceACH = 0.1 # natural air changes per hour, assumption
  ReferenceHeight = 8.202 # reference height per ASHRAE 62.2 (ft)

  # Adds HPXML Air Infiltration and HPXML HVAC Distribution to the OpenStudio model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param airloop_map [Hash] Map of HPXML System ID => OpenStudio AirLoopHVAC (or ZoneHVACFourPipeFanCoil or ZoneHVACBaseboardConvectiveWater) objects
  # @return [nil]
  def self.apply(runner, model, weather, spaces, hpxml_bldg, hpxml_header, schedules_file, airloop_map)
    sensors = create_sensors(runner, model, weather, spaces, hpxml_bldg, hpxml_header)

    # Ventilation fans
    vent_fans = { mech: [], cfis_suppl: [], whf: [], kitchen: [], bath: [] }
    hpxml_bldg.ventilation_fans.each do |f|
      next unless f.hours_in_operation.nil? || f.hours_in_operation > 0

      if f.used_for_whole_building_ventilation
        if not f.is_cfis_supplemental_fan
          vent_fans[:mech] << f
        else
          vent_fans[:cfis_suppl] << f
        end
      elsif f.used_for_seasonal_cooling_load_reduction
        vent_fans[:whf] << f
      elsif f.used_for_local_ventilation
        next if hpxml_bldg.building_occupancy.number_of_residents == 0 # Operational calculation w/ zero occupants, zero out energy use

        if f.fan_location == HPXML::LocationKitchen
          vent_fans[:kitchen] << f
        elsif f.fan_location == HPXML::LocationBath
          vent_fans[:bath] << f
        end
      end
    end

    # Initialization
    cfis_data = initialize_cfis(model, vent_fans, airloop_map, hpxml_header.unavailable_periods)
    fan_data = { rtf_var: {}, mfr_max_var: {}, rtf_sensor: {} }
    model.getAirLoopHVACs.each do |air_loop|
      initialize_fan_objects(model, air_loop, fan_data)
    end
    model.getZoneHVACFourPipeFanCoils.each do |fan_coil|
      initialize_fan_objects(model, fan_coil, fan_data)
    end

    # Apply ducts
    duct_lk_imbals = []
    apply_ducts(runner, model, spaces, hpxml_bldg, airloop_map, vent_fans, cfis_data, fan_data, duct_lk_imbals, sensors)

    # Apply infiltration/ventilation
    set_wind_speed_correction(model, hpxml_bldg)

    infil_values = get_values_from_air_infiltration_measurements(hpxml_bldg, weather)

    # Natural ventilation and whole house fans
    apply_natural_ventilation_and_whole_house_fan(runner, model, spaces, hpxml_bldg, hpxml_header, vent_fans, infil_values, sensors)

    # Infiltration/ventilation
    apply_infiltration_to_garage(model, spaces, hpxml_bldg, infil_values, duct_lk_imbals)
    apply_infiltration_to_unconditioned_basement(model, spaces, duct_lk_imbals)
    apply_infiltration_to_vented_crawlspace(model, spaces, weather, hpxml_bldg, duct_lk_imbals)
    apply_infiltration_to_unvented_crawlspace(model, spaces, duct_lk_imbals)
    apply_infiltration_to_vented_attic(model, spaces, weather, hpxml_bldg, hpxml_header, duct_lk_imbals)
    apply_infiltration_to_unvented_attic(model, spaces, duct_lk_imbals)
    apply_infiltration_ventilation_to_conditioned(runner, model, spaces, weather, hpxml_bldg, hpxml_header, vent_fans, infil_values,
                                                  schedules_file, duct_lk_imbals, cfis_data, fan_data, sensors)
  end

  # Creates a variety of EMS sensors used in airflow calculations.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [Hash] Map of :sensor_types => OpenStudio::Model::EnergyManagementSystemSensor objects
  def self.create_sensors(runner, model, weather, spaces, hpxml_bldg, hpxml_header)
    conditioned_space = spaces[HPXML::LocationConditionedSpace]
    conditioned_zone = conditioned_space.thermalZone.get

    sensors = {}

    sensors[:pbar] = Model.add_ems_sensor(
      model,
      name: 'out pb s',
      output_var_or_meter_name: 'Site Outdoor Air Barometric Pressure',
      key_name: nil
    )

    sensors[:w_out] = Model.add_ems_sensor(
      model,
      name: 'out wt s',
      output_var_or_meter_name: 'Site Outdoor Air Humidity Ratio',
      key_name: nil
    )

    sensors[:w_in] = Model.add_ems_sensor(
      model,
      name: 'win s',
      output_var_or_meter_name: 'Zone Air Humidity Ratio',
      key_name: conditioned_zone.name
    )

    sensors[:v_wind] = Model.add_ems_sensor(
      model,
      name: 'site vw s',
      output_var_or_meter_name: 'Site Wind Speed',
      key_name: nil
    )

    sensors[:t_in] = Model.add_ems_sensor(
      model,
      name: 'tin s',
      output_var_or_meter_name: 'Zone Mean Air Temperature',
      key_name: conditioned_zone.name
    )

    sensors[:t_out] = Model.add_ems_sensor(
      model,
      name: 'tout s',
      output_var_or_meter_name: 'Zone Outdoor Air Drybulb Temperature',
      key_name: conditioned_zone.name
    )

    # Create HVAC availability sensor
    sensors[:hvac_avail] = nil
    heating_unavailable_periods = Schedule.get_unavailable_periods(runner, SchedulesFile::Columns[:SpaceHeating].name, hpxml_header.unavailable_periods)
    cooling_unavailable_periods = Schedule.get_unavailable_periods(runner, SchedulesFile::Columns[:SpaceCooling].name, hpxml_header.unavailable_periods)
    if (not heating_unavailable_periods.empty?) || (not cooling_unavailable_periods.empty?)
      avail_sch = ScheduleConstant.new(model, 'hvac availability schedule', 1.0, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: heating_unavailable_periods + cooling_unavailable_periods)

      sensors[:hvac_avail] = Model.add_ems_sensor(
        model,
        name: "#{avail_sch.schedule.name} s",
        output_var_or_meter_name: 'Schedule Value',
        key_name: avail_sch.schedule.name
      )
      sensors[:hvac_avail].additionalProperties.setFeature('ObjectType', Constants::ObjectTypeHVACAvailabilitySensor)
    end

    # Create cooling season schedule sensor (applies only to natural ventilation, not HVAC equipment).
    # Uses BAHSP cooling season, not user-specified cooling season (which may be, e.g., year-round).
    _, default_cooling_months = HVAC.get_building_america_hvac_seasons(weather, hpxml_bldg.latitude)
    clg_season_sch = MonthWeekdayWeekendSchedule.new(model, 'cooling season schedule', Array.new(24, 1), Array.new(24, 1), default_cooling_months, EPlus::ScheduleTypeLimitsFraction)
    sensors[:clg_ssn] = Model.add_ems_sensor(
      model,
      name: 'cool_season',
      output_var_or_meter_name: 'Schedule Value',
      key_name: clg_season_sch.schedule.name
    )

    return sensors
  end

  # Returns the single infiltration measurement object of interest, from all possible infiltration measurements
  # in the HPXML file, that has the sufficient inputs. For EnergyPlus, we return a measurement with a quantitative
  # value (e.g., ACH50) if available, otherwise fallback to the qualitative input. For Manual J design loads, the
  # returned measurement is controlled by the manualj_infiltration_method argument.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param manualj_infiltration_method [String] Type of infiltration to retrieve for Manual J calculations
  # @return measurement [HPXML::AirInfiltrationMeasurement] Air infiltration measurement of interest
  def self.get_infiltration_measurement_of_interest(hpxml_bldg, manualj_infiltration_method: nil)
    if manualj_infiltration_method.nil? || (manualj_infiltration_method == HPXML::ManualJInfiltrationMethodBlowerDoor)
      hpxml_bldg.air_infiltration_measurements.each do |measurement|
        # Returns the infiltration measurement that has the minimum information needed for simulation
        if not measurement.air_leakage.nil?
          if [HPXML::UnitsACH, HPXML::UnitsCFM].include?(measurement.unit_of_measure) && !measurement.house_pressure.nil?
            return measurement
          elsif [HPXML::UnitsACHNatural, HPXML::UnitsCFMNatural].include? measurement.unit_of_measure
            return measurement
          end
        elsif (not measurement.effective_leakage_area.nil?) || (not measurement.specific_leakage_area.nil?)
          return measurement
        end
      end
    end

    if manualj_infiltration_method.nil? || (manualj_infiltration_method == HPXML::ManualJInfiltrationMethodDefaultTable)
      hpxml_bldg.air_infiltration_measurements.each do |measurement|
        return measurement if measurement.leakiness_description
      end
    end

    fail 'Could not find air infiltration measurement.'
  end

  # Returns a standard set of infiltration values for the HPXML Building.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param weather [WeatherFile] Weather object containing EPW information
  # @return [Hash] Map with various infiltration key-value pairs (SLA, infiltration volume & height, etc.)
  def self.get_values_from_air_infiltration_measurements(hpxml_bldg, weather)
    cfa = hpxml_bldg.building_construction.conditioned_floor_area
    measurement = get_infiltration_measurement_of_interest(hpxml_bldg)

    default_infil_height, default_infil_volume = Defaults.get_infiltration_height_and_volume(hpxml_bldg, nil)
    infil_volume = measurement.infiltration_volume
    infil_volume = default_infil_volume if infil_volume.nil?
    infil_height = measurement.infiltration_height
    infil_height = default_infil_height if infil_height.nil?
    infil_avg_ceil_height = infil_volume / cfa # Per ANSI/RESNET/ICC 380

    sla, ach50, nach = nil
    if [HPXML::UnitsACH, HPXML::UnitsCFM].include?(measurement.unit_of_measure)
      if measurement.unit_of_measure == HPXML::UnitsACH
        ach50 = calc_infiltration_at_diff_pressure(measurement.air_leakage, measurement.house_pressure, 50.0)
      elsif measurement.unit_of_measure == HPXML::UnitsCFM
        achXX = measurement.air_leakage * 60.0 / infil_volume # Convert CFM to ACH
        ach50 = calc_infiltration_at_diff_pressure(achXX, measurement.house_pressure, 50.0)
      end
      sla = get_infiltration_SLA_from_ACH50(ach50, infil_avg_ceil_height)
      nach = get_infiltration_ACH_from_SLA(sla, infil_height, infil_avg_ceil_height, weather)
    elsif [HPXML::UnitsACHNatural, HPXML::UnitsCFMNatural].include? measurement.unit_of_measure
      if measurement.unit_of_measure == HPXML::UnitsACHNatural
        nach = measurement.air_leakage
      elsif measurement.unit_of_measure == HPXML::UnitsCFMNatural
        nach = measurement.air_leakage * 60.0 / infil_volume # Convert CFM to ACH
      end
      sla = get_infiltration_SLA_from_ACH(nach, infil_height, infil_avg_ceil_height, weather)
      ach50 = get_infiltration_ACH50_from_SLA(sla, infil_avg_ceil_height)
    elsif (not measurement.effective_leakage_area.nil?) || (not measurement.specific_leakage_area.nil?)
      if not measurement.effective_leakage_area.nil?
        sla = UnitConversions.convert(measurement.effective_leakage_area, 'in^2', 'ft^2') / cfa
      else
        sla = measurement.specific_leakage_area
      end
      ach50 = get_infiltration_ACH50_from_SLA(sla, infil_avg_ceil_height)
      nach = get_infiltration_ACH_from_SLA(sla, infil_height, infil_avg_ceil_height, weather)
    else
      fail 'Unexpected error.'
    end

    if measurement.infiltration_type == HPXML::InfiltrationTypeUnitTotal
      a_ext = measurement.a_ext # Ratio of exterior envelope area to total envelope area for SFA/MF units
    end
    a_ext = 1.0 if a_ext.nil?

    return { sla: sla,
             ach50: ach50,
             nach: nach,
             volume: infil_volume,
             height: infil_height,
             avg_ceil_height: infil_avg_ceil_height,
             a_ext: a_ext }
  end

  # Sets terrain/shielding coefficients to the HPXML Site object for the AIM-2 infiltration algorithm.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.set_wind_speed_correction(model, hpxml_bldg)
    site = hpxml_bldg.site
    site_ap = site.additional_properties

    site_map = { HPXML::SiteTypeRural => 'Country',    # Flat, open country
                 HPXML::SiteTypeSuburban => 'Suburbs', # Rough, wooded country, suburbs
                 HPXML::SiteTypeUrban => 'City' }      # Towns, city outskirts, center of large cities
    model.getSite.setTerrain(site_map[site.site_type])

    site_ap.height = 32.8 # ft (Standard weather station height)

    # Open, Unrestricted at Weather Station
    site_ap.terrain_multiplier = 1.0
    site_ap.terrain_exponent = 0.15
    site_ap.ashrae_terrain_thickness = 270
    site_ap.ashrae_terrain_exponent = 0.14

    case site.site_type
    when HPXML::SiteTypeRural
      site_ap.site_terrain_multiplier = 0.85
      site_ap.site_terrain_exponent = 0.20
      site_ap.ashrae_site_terrain_thickness = 270 # Flat, open country
      site_ap.ashrae_site_terrain_exponent = 0.14 # Flat, open country
    when HPXML::SiteTypeSuburban
      site_ap.site_terrain_multiplier = 0.67
      site_ap.site_terrain_exponent = 0.25
      site_ap.ashrae_site_terrain_thickness = 370 # Rough, wooded country, suburbs
      site_ap.ashrae_site_terrain_exponent = 0.22 # Rough, wooded country, suburbs
    when HPXML::SiteTypeUrban
      site_ap.site_terrain_multiplier = 0.47
      site_ap.site_terrain_exponent = 0.35
      site_ap.ashrae_site_terrain_thickness = 460 # Towns, city outskirts, center of large cities
      site_ap.ashrae_site_terrain_exponent = 0.33 # Towns, city outskirts, center of large cities
    end

    # Mapping based on AIM-2 Model by Walker/Wilson
    # Table 2: Estimates of Shelter Coefficient S_wo for No Flue (flue effect is handled later)
    case site.shielding_of_home
    when HPXML::ShieldingNormal
      site_ap.aim2_shelter_coeff = 0.50 # Class 4: "Very heavy shielding, many large obstructions within one house height"
    when HPXML::ShieldingExposed
      site_ap.aim2_shelter_coeff = 0.90 # Class 2: "Light local shielding with few obstructions within two house heights"
    when HPXML::ShieldingWellShielded
      site_ap.aim2_shelter_coeff = 0.30 # Class 5: "Complete shielding, with large buildings immediately adjacent"
    end

    # S-G Shielding Coefficients are roughly 1/3 of AIM2 Shelter Coefficients
    site_ap.s_g_shielding_coef = site_ap.aim2_shelter_coeff / 3.0
  end

  # Adds infiltration/ventilation to the OpenStudio unconditioned space; the infiltration may be characterized
  # using either nACH or ELA. Also adds any duct leakage induced infiltration (when there are ducts in the
  # unconditioned space and the ducts have supply leakage != return leakage).
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param space [OpenStudio::Model::Space] an OpenStudio::Model::Space object
  # @param ach [Double] Annual average air changes per hour
  # @param ela [Double] Effective Leakage Area (sq. in.)
  # @param c_w_SG [Double] Sherman-Grimsrud (ASHRAE Basic Model) wind coefficient
  # @param c_s_SG [Double] Sherman-Grimsrud (ASHRAE Basic Model) stack coefficient
  # @param duct_lk_imbals [Array] List of duct leakage imbalance information
  # @return [nil]
  def self.apply_infiltration_to_unconditioned_space(model, space, ach, ela, c_w_SG, c_s_SG, duct_lk_imbals)
    # Infiltration/Ventilation

    if ach.to_f > 0
      # Model ACH as constant for below-grade spaces, where wind speed is near zero
      Model.add_infiltration_flow_rate(
        model,
        name: "#{Constants::ObjectTypeInfiltration} #{space.name}",
        space: space,
        ach: ach
      )
    elsif ela.to_f > 0
      # Model ELA with stack/wind coefficients
      Model.add_infiltration_ela(
        model,
        name: "#{Constants::ObjectTypeInfiltration} #{space.name}",
        space: space,
        ela: UnitConversions.convert(ela, 'ft^2', 'cm^2'),
        stack_coeff: UnitConversions.convert(c_s_SG, 'ft^2/(s^2*R)', 'L^2/(s^2*cm^4*K)'),
        wind_coeff: c_w_SG * 0.01
      )
    end

    # Duct leakage imbalance induced infiltration

    # Technically the duct leakage imbalance interacts with the infiltration/ventilation,
    # but the interaction is not that important to capture for an unconditioned space.
    if duct_lk_imbals.any? { |values| values[0] == space.thermalZone.get.name.to_s }
      space_name = space.name.to_s.gsub(' - ', '_')

      uncond_infil = Model.add_infiltration_flow_rate(
        model,
        name: "#{space_name} duct leakage imbalance infil flow",
        space: space,
        ach: nil
      )

      uncond_infil_actuator = Model.add_ems_actuator(
        name: "#{uncond_infil.name} act",
        model_object: uncond_infil,
        comp_type_and_control: EPlus::EMSActuatorZoneInfiltrationFlowRate
      )

      # Unconditioned Space Duct Leakage Imbalance Induced Infiltration Program
      uncond_infil_program = Model.add_ems_program(
        model,
        name: "#{space_name} duct leakage imbalance infil program"
      )
      uncond_infil_program.addLine('Set Qducts = 0')
      duct_lk_imbals.each do |values|
        duct_location, duct_lk_supply_fan_equiv_var, duct_lk_exhaust_fan_equiv_var = values
        next if duct_location != space.thermalZone.get.name.to_s

        uncond_infil_program.addLine("Set Qducts = Qducts - #{duct_lk_supply_fan_equiv_var.name}")
        uncond_infil_program.addLine("Set Qducts = Qducts + #{duct_lk_exhaust_fan_equiv_var.name}")
      end
      uncond_infil_program.addLine("Set #{uncond_infil_actuator.name} = (@Abs(Qducts))")

      Model.add_ems_program_calling_manager(
        model,
        name: "#{uncond_infil_program.name} calling manager",
        calling_point: 'BeginZoneTimestepAfterInitHeatBalance',
        ems_programs: [uncond_infil_program]
      )
    end
  end

  # Adds an EMS program to introduce airflow due to natural ventilation (ventilation through open operable
  # windows) and, if present, the whole house fan.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param vent_fans [Hash] Map of vent fan types => list of HPXML VentilationFans
  # @param infil_values [Hash] Map with various infiltration key-value pairs (SLA, infiltration volume & height, etc.)
  # @param sensors [Hash] Map of :sensor_types => OpenStudio::Model::EnergyManagementSystemSensor objects
  # @return [nil]
  def self.apply_natural_ventilation_and_whole_house_fan(runner, model, spaces, hpxml_bldg, hpxml_header, vent_fans, infil_values, sensors)
    conditioned_space = spaces[HPXML::LocationConditionedSpace]
    conditioned_zone = conditioned_space.thermalZone.get

    # Natural Ventilation availability schedule and sensor
    nv_avail_sch = create_sched_from_num_days_per_week(model, Constants::ObjectTypeNaturalVentilation, hpxml_bldg.header.natvent_days_per_week, hpxml_header.unavailable_periods)

    nv_avail_sensor = Model.add_ems_sensor(
      model,
      name: "#{Constants::ObjectTypeNaturalVentilation} s",
      output_var_or_meter_name: 'Schedule Value',
      key_name: nv_avail_sch.name
    )

    # Whole House Fan availability schedule(s) and sensor(s)
    # If whf_num_days_per_week is exposed, can handle multiple fans with different days of operation
    whf_avail_sensors = {}
    vent_fans[:whf].each_with_index do |vent_whf, index|
      whf_num_days_per_week = 7 # FUTURE: Expose via HPXML?
      obj_name = "#{Constants::ObjectTypeWholeHouseFan} #{index}"
      whf_unavailable_periods = Schedule.get_unavailable_periods(runner, SchedulesFile::Columns[:WholeHouseFan].name, hpxml_header.unavailable_periods)
      whf_avail_sch = create_sched_from_num_days_per_week(model, obj_name, whf_num_days_per_week, whf_unavailable_periods)

      whf_avail_sensors[vent_whf.id] = Model.add_ems_sensor(
        model,
        name: "#{obj_name} s",
        output_var_or_meter_name: 'Schedule Value',
        key_name: whf_avail_sch.name
      )
    end

    # Sensors
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

    # Actuators
    nv_flow = Model.add_infiltration_flow_rate(
      model,
      name: "#{Constants::ObjectTypeNaturalVentilation} flow",
      space: conditioned_space,
      ach: nil
    )
    nv_flow.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeNaturalVentilation)

    nv_flow_actuator = Model.add_ems_actuator(
      name: "#{nv_flow.name} act",
      model_object: nv_flow,
      comp_type_and_control: EPlus::EMSActuatorZoneInfiltrationFlowRate
    )

    whf_flow = Model.add_infiltration_flow_rate(
      model,
      name: "#{Constants::ObjectTypeWholeHouseFan} flow",
      space: conditioned_space,
      ach: nil
    )
    whf_flow.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeWholeHouseFan)

    whf_flow_actuator = Model.add_ems_actuator(
      name: "#{whf_flow.name} act",
      model_object: whf_flow,
      comp_type_and_control: EPlus::EMSActuatorZoneInfiltrationFlowRate
    )

    # Whole house fan electricity consumption
    whf_equip = Model.add_electric_equipment(
      model,
      name: Constants::ObjectTypeWholeHouseFan,
      end_use: Constants::ObjectTypeWholeHouseFan,
      space: conditioned_space, # no heat gain, so assign the equipment to an arbitrary space
      design_level: nil, # will be EMS-actuated
      frac_radiant: 0,
      frac_latent: 0,
      frac_lost: 1,
      schedule: model.alwaysOnDiscreteSchedule
    )

    whf_elec_actuator = Model.add_ems_actuator(
      name: "#{whf_equip.name} act",
      model_object: whf_equip,
      comp_type_and_control: EPlus::EMSActuatorElectricEquipmentPower
    )

    # Assume located in attic floor if attic zone exists; otherwise assume it's through roof/wall.
    whf_zone = nil
    if not spaces[HPXML::LocationAtticVented].nil?
      whf_zone = spaces[HPXML::LocationAtticVented].thermalZone.get
    elsif not spaces[HPXML::LocationAtticUnvented].nil?
      whf_zone = spaces[HPXML::LocationAtticUnvented].thermalZone.get
    end
    if not whf_zone.nil?
      # Air from conditioned space to WHF zone (attic)
      zone_mixing = OpenStudio::Model::ZoneMixing.new(whf_zone)
      zone_mixing.setName("#{Constants::ObjectTypeWholeHouseFan} mix")
      zone_mixing.setSourceZone(conditioned_zone)

      cond_to_zone_flow_rate_actuator = Model.add_ems_actuator(
        name: "#{zone_mixing.name} act",
        model_object: zone_mixing,
        comp_type_and_control: EPlus::EMSActuatorZoneMixingFlowRate
      )
    end

    # Assume A) 50% of the area of an operable window can be open, and B) 20% of openable window area is actually open
    window_area = hpxml_bldg.windows.map { |w| w.area }.sum(0.0)
    open_window_area = window_area * hpxml_bldg.additional_properties.initial_frac_windows_operable * 0.5 * 0.2

    area = 0.6 * open_window_area # ft^2, for Sherman-Grimsrud (ASHRAE Basic Model)
    max_rate = 20.0 # Air Changes per hour
    max_flow_rate = max_rate * infil_values[:volume] / UnitConversions.convert(1.0, 'hr', 'min')
    neutral_level = 0.5
    hor_lk_frac = 0.0
    c_w, c_s = calc_wind_stack_coeffs(hpxml_bldg, hor_lk_frac, neutral_level, HPXML::LocationConditionedSpace, infil_values[:height])
    max_oa_hr = 0.0115 # From ANSI/RESNET/ICC 301-2022

    # Program
    vent_program = Model.add_ems_program(
      model,
      name: "#{Constants::ObjectTypeNaturalVentilation} program"
    )
    vent_program.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeNaturalVentilation)
    vent_program.addLine("Set Tin = #{sensors[:t_in].name}")
    vent_program.addLine("Set Tout = #{sensors[:t_out].name}")
    vent_program.addLine("Set Wout = #{sensors[:w_out].name}")
    vent_program.addLine("Set Pbar = #{sensors[:pbar].name}")
    vent_program.addLine('Set Phiout = (@RhFnTdbWPb Tout Wout Pbar)')
    vent_program.addLine("Set MaxHR = #{max_oa_hr}")
    if not thermostat.nil?
      # Home has HVAC system (though setpoints may be defaulted); use the average of heating/cooling setpoints to minimize incurring additional heating energy.
      vent_program.addLine("Set Tnvsp = (#{htg_sp_sensor.name} + #{clg_sp_sensor.name}) / 2")
    else
      # No HVAC system; use the average of defaulted heating/cooling setpoints.
      htg_weekday_setpoints, htg_weekend_setpoints = Defaults.get_heating_setpoint(HPXML::HVACControlTypeManual, hpxml_header.eri_calculation_versions[0])
      clg_weekday_setpoints, clg_weekend_setpoints = Defaults.get_cooling_setpoint(HPXML::HVACControlTypeManual, hpxml_header.eri_calculation_versions[0])
      if htg_weekday_setpoints.split(', ').uniq.size == 1 && htg_weekend_setpoints.split(', ').uniq.size == 1 && htg_weekday_setpoints.split(', ').uniq == htg_weekend_setpoints.split(', ').uniq
        default_htg_sp = UnitConversions.convert(htg_weekend_setpoints.split(', ').uniq[0].to_f, 'F', 'C')
      else
        fail 'Unexpected heating setpoints.'
      end
      if clg_weekday_setpoints.split(', ').uniq.size == 1 && clg_weekend_setpoints.split(', ').uniq.size == 1 && clg_weekday_setpoints.split(', ').uniq == clg_weekend_setpoints.split(', ').uniq
        default_clg_sp = UnitConversions.convert(clg_weekend_setpoints.split(', ').uniq[0].to_f, 'F', 'C')
      else
        fail 'Unexpected cooling setpoints.'
      end
      vent_program.addLine("Set Tnvsp = (#{default_htg_sp} + #{default_clg_sp}) / 2")
    end
    vent_program.addLine("Set NVavail = #{nv_avail_sensor.name}")
    vent_program.addLine("Set ClgSsnAvail = #{sensors[:clg_ssn].name}")
    vent_program.addLine('Set Qnv = 0') # Init
    vent_program.addLine('Set Qwhf = 0') # Init
    vent_program.addLine("Set #{cond_to_zone_flow_rate_actuator.name} = 0") unless whf_zone.nil? # Init
    vent_program.addLine("Set #{whf_elec_actuator.name} = 0") # Init
    infil_constraints = 'If ((Wout < MaxHR) && (Tin > Tout) && (Tin > Tnvsp) && (ClgSsnAvail > 0))'
    if not sensors[:hvac_avail].nil?
      # We are using the availability schedule, but we also constrain the window opening based on temperatures and humidity.
      # We're assuming that if the HVAC is not available, you'd ignore the humidity constraints we normally put on window opening per the old HSP guidance (RH < 70% and w < 0.015).
      # Without, the humidity constraints prevent the window from opening during the entire period even though the sensible cooling would have really helped.
      infil_constraints += "|| ((Tin > Tout) && (Tin > Tnvsp) && (#{sensors[:hvac_avail].name} == 0))"
    end
    vent_program.addLine(infil_constraints)
    vent_program.addLine('  Set WHF_Flow = 0')
    vent_fans[:whf].each do |vent_whf|
      vent_program.addLine("  Set WHF_Flow = WHF_Flow + #{UnitConversions.convert(vent_whf.flow_rate, 'cfm', 'm^3/s')} * #{whf_avail_sensors[vent_whf.id].name}")
    end
    vent_program.addLine('  Set Adj = (Tin-Tnvsp)/(Tin-Tout)')
    vent_program.addLine('  Set Adj = (@Min Adj 1)')
    vent_program.addLine('  Set Adj = (@Max Adj 0)')
    vent_program.addLine('  If (WHF_Flow > 0)') # If available, prioritize whole house fan
    vent_program.addLine('    Set Qwhf = WHF_Flow*Adj')
    vent_program.addLine("    Set #{cond_to_zone_flow_rate_actuator.name} = WHF_Flow*Adj") unless whf_zone.nil?
    vent_program.addLine('    Set WHF_W = 0')
    if hpxml_bldg.building_occupancy.number_of_residents != 0 # If operational calculation w/ zero occupants, zero out whole house fan
      vent_fans[:whf].each do |vent_whf|
        vent_program.addLine("    Set WHF_W = WHF_W + #{vent_whf.fan_power} * #{whf_avail_sensors[vent_whf.id].name}")
      end
    end
    vent_program.addLine("    Set #{whf_elec_actuator.name} = WHF_W*Adj")
    vent_program.addLine('  ElseIf (NVavail > 0)') # Natural ventilation
    if hpxml_bldg.building_occupancy.number_of_residents == 0
      # Operational calculation w/ zero occupants, zero out natural ventilation
      vent_program.addLine('    Set NVArea = 0')
    else
      vent_program.addLine("    Set NVArea = #{UnitConversions.convert(area, 'ft^2', 'cm^2')}")
    end
    vent_program.addLine("    Set Cs = #{UnitConversions.convert(c_s, 'ft^2/(s^2*R)', 'L^2/(s^2*cm^4*K)')}")
    vent_program.addLine("    Set Cw = #{c_w * 0.01}")
    vent_program.addLine('    Set Tdiff = Tin-Tout')
    vent_program.addLine('    Set dT = (@Abs Tdiff)')
    vent_program.addLine("    Set Vwind = #{sensors[:v_wind].name}")
    vent_program.addLine('    Set SGNV = NVArea*Adj*((((Cs*dT)+(Cw*(Vwind^2)))^0.5)/1000)')
    vent_program.addLine("    Set MaxNV = #{UnitConversions.convert(max_flow_rate, 'cfm', 'm^3/s')}")
    vent_program.addLine('    Set Qnv = (@Min SGNV MaxNV)')
    vent_program.addLine('  EndIf')
    vent_program.addLine('EndIf')
    vent_program.addLine("Set #{nv_flow_actuator.name} = Qnv")
    vent_program.addLine("Set #{whf_flow_actuator.name} = Qwhf")

    Model.add_ems_program_calling_manager(
      model,
      name: "#{vent_program.name} calling manager",
      calling_point: 'BeginZoneTimestepAfterInitHeatBalance',
      ems_programs: [vent_program]
    )

    # EMS global variables for output reporting
    q_nv_var = Model.add_ems_global_var(
      model,
      var_name: "#{vent_program.name} Qnv"
    )
    q_whf_var = Model.add_ems_global_var(
      model,
      var_name: "#{vent_program.name} Qwhf"
    )
    q_nv_var.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeNaturalVentilation)
    q_whf_var.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeWholeHouseFan)
    vent_program.addLine("Set #{q_nv_var.name} = Qnv")
    vent_program.addLine("Set #{q_whf_var.name} = Qwhf")
  end

  # Returns an OpenStudio schedule w/ the specified number of days per week that the schedule is active.
  # The active days of the week are arbitrary and currently hard-coded. Used for natural ventilation and
  # whole house fan schedules.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param obj_name [String] Name for the OpenStudio object
  # @param num_days_per_week [Integer] Number of days per week that the schedule should be active (0-7)
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @return [OpenStudio::Model::ScheduleRuleset] The newly created schedule
  def self.create_sched_from_num_days_per_week(model, obj_name, num_days_per_week, unavailable_periods)
    sch_name = "#{obj_name} schedule"
    avail_sch = Model.add_schedule_ruleset(
      model,
      name: sch_name,
      limits: EPlus::ScheduleTypeLimitsOnOff
    )

    # Apply to days in this order: Mon, Wed, Fri, Sat, Tues, Thurs, Sun
    apply_to_days = [0] * 7
    apply_to_days[0] = 1 if num_days_per_week >= 7
    apply_to_days[1] = 1 if num_days_per_week >= 1
    apply_to_days[2] = 1 if num_days_per_week >= 5
    apply_to_days[3] = 1 if num_days_per_week >= 2
    apply_to_days[4] = 1 if num_days_per_week >= 6
    apply_to_days[5] = 1 if num_days_per_week >= 3
    apply_to_days[6] = 1 if num_days_per_week >= 4

    Model.add_schedule_ruleset_rule(
      avail_sch,
      start_date: OpenStudio::Date::fromDayOfYear(1),
      end_date: OpenStudio::Date::fromDayOfYear(365),
      apply_to_days: apply_to_days,
      hourly_values: [1] * 24
    )

    Schedule.set_unavailable_periods(model, avail_sch, sch_name, unavailable_periods)
    return avail_sch
  end

  # Creates a return plenum thermal zone for use in the EMS duct model calculations.
  # The zone is meant to have essentially zero heat transfer other than what the
  # duct calculations add/remove.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param loop_name [String] OpenStudio AirLoopHVAC name
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @return [OpenStudio::Model::ThermalZone] The newly created return plenum zone
  def self.create_return_air_duct_zone(model, loop_name, unit_multiplier)
    ra_duct_zone = OpenStudio::Model::ThermalZone.new(model)
    ra_duct_zone.setMultiplier(unit_multiplier)
    ra_duct_zone.setName(loop_name + ' ret air zone')
    ra_duct_zone.setVolume(1.0)

    ra_duct_polygon = OpenStudio::Point3dVector.new
    ra_duct_polygon << OpenStudio::Point3d.new(0, 0, 0)
    ra_duct_polygon << OpenStudio::Point3d.new(0, 1.0, 0)
    ra_duct_polygon << OpenStudio::Point3d.new(1.0, 1.0, 0)
    ra_duct_polygon << OpenStudio::Point3d.new(1.0, 0, 0)

    ra_space = OpenStudio::Model::Space::fromFloorPrint(ra_duct_polygon, 1, model)
    ra_space = ra_space.get
    ra_space.setName(loop_name + ' ret air space')
    ra_space.setThermalZone(ra_duct_zone)

    adiabatic_mat = model.getMaterials.find { |m| m.name.to_s == 'Adiabatic' }
    if adiabatic_mat.nil?
      adiabatic_mat = Model.add_massless_material(
        model,
        name: 'Adiabatic',
        rvalue: 176.1
      )
    end

    adiabatic_const = model.getConstructions.find { |c| c.name.to_s == 'AdiabaticConst' }
    if adiabatic_const.nil?
      adiabatic_const = Model.add_construction(
        model,
        name: 'AdiabaticConst',
        layers: [adiabatic_mat]
      )
    end

    ra_space.surfaces.each do |surface|
      surface.setConstruction(adiabatic_const)
      surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionAdiabatic)
      surface.setSunExposure(EPlus::SurfaceSunExposureNo)
      surface.setWindExposure(EPlus::SurfaceWindExposureNo)
      surface_property_convection_coefficients = OpenStudio::Model::SurfacePropertyConvectionCoefficients.new(surface)
      surface_property_convection_coefficients.setConvectionCoefficient1Location('Inside')
      surface_property_convection_coefficients.setConvectionCoefficient1Type('Value')
      surface_property_convection_coefficients.setConvectionCoefficient1(30)
    end

    return ra_duct_zone
  end

  # Initializes the EMS program if there is a CFIS mechanical ventilation system.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param vent_fans [Hash] Map of vent fan types => list of HPXML VentilationFans
  # @param airloop_map [Hash] Map of HPXML System ID => OpenStudio AirLoopHVAC (or ZoneHVACFourPipeFanCoil or ZoneHVACBaseboardConvectiveWater) objects
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @return [Hash] Map with various CFIS-relative OpenStudio model objects
  def self.initialize_cfis(model, vent_fans, airloop_map, unavailable_periods)
    cfis_data = { airloop: {}, sum_oa_cfm_var: {}, f_vent_only_mode_var: {} }
    return cfis_data if vent_fans[:mech].empty?

    index = 0

    vent_fans[:mech].each do |vent_mech|
      next if vent_mech.fan_type != HPXML::MechVentTypeCFIS

      fail 'Cannot apply unavailable period(s) to CFIS systems.' if !unavailable_periods.empty?

      # Get AirLoop associated with CFIS
      vent_mech.distribution_system.hvac_systems.map { |system| system.id }.each do |cfis_id|
        next if airloop_map[cfis_id].nil?

        cfis_data[:airloop][vent_mech.id] = airloop_map[cfis_id]
      end

      cfis_data[:sum_oa_cfm_var][vent_mech.id] = Model.add_ems_global_var(
        model,
        var_name: "#{Constants::ObjectTypeMechanicalVentilation} cfis sum oa cfm #{index}"
      )
      cfis_data[:f_vent_only_mode_var][vent_mech.id] = Model.add_ems_global_var(
        model,
        var_name: "#{Constants::ObjectTypeMechanicalVentilation} cfis f vent only mode #{index}"
      )

      # CFIS Initialization Program
      cfis_program = Model.add_ems_program(
        model,
        name: "#{Constants::ObjectTypeMechanicalVentilation} cfis init program #{index}"
      )
      cfis_program.addLine("Set #{cfis_data[:sum_oa_cfm_var][vent_mech.id].name} = 0")
      cfis_program.addLine("Set #{cfis_data[:f_vent_only_mode_var][vent_mech.id].name} = 0")

      Model.add_ems_program_calling_manager(
        model,
        name: "#{cfis_program.name} calling manager",
        calling_point: 'BeginNewEnvironment',
        ems_programs: [cfis_program]
      )

      Model.add_ems_program_calling_manager(
        model,
        name: "#{cfis_program.name} calling manager2",
        calling_point: 'AfterNewEnvironmentWarmUpIsComplete',
        ems_programs: [cfis_program]
      )

      index += 1
    end

    return cfis_data
  end

  # Updates the fan_data hash with various EMS objects associated with the given AirLoopHVAC (or
  # ZoneHVACFourPipeFanCoil) object.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param object [OpenStudio::Model::XXX] OpenStudio AirLoopHVAC (or ZoneHVACFourPipeFanCoil) object
  # @param fan_data [Hash] Map of HVAC blower fan properties => values
  # @return [nil]
  def self.initialize_fan_objects(model, object, fan_data)
    # Get the supply fan
    if object.is_a? OpenStudio::Model::ZoneHVACFourPipeFanCoil
      supply_fan = object.supplyAirFan
    elsif object.is_a? OpenStudio::Model::AirLoopHVAC
      supply_fan = nil
      if object.supplyFan.is_initialized
        # Evaporative cooler supply fan directly on air loop
        supply_fan = object.supplyFan.get
      else
        # Supply fan associated with AirLoopHVACUnitarySystem
        object.supplyComponents.each do |comp|
          next unless comp.to_AirLoopHVACUnitarySystem.is_initialized

          supply_fan = comp.to_AirLoopHVACUnitarySystem.get.supplyFan.get
        end
      end
    else
      fail 'Unexpected object type.'
    end

    fan_data[:rtf_var][object] = Model.add_ems_global_var(
      model,
      var_name: "#{object.name} Fan RTF"
    )

    # Supply fan maximum mass flow rate
    fan_data[:mfr_max_var][object] = Model.add_ems_internal_var(
      model,
      name: "#{object.name} max sup fan mfr",
      model_object: supply_fan,
      type: EPlus::EMSIntVarFanMFR
    )

    if supply_fan.to_FanSystemModel.is_initialized
      fan_data[:rtf_sensor][object] = []
      num_speeds = supply_fan.to_FanSystemModel.get.numberofSpeeds
      for i in 1..num_speeds
        if num_speeds == 1
          var_name = 'Fan Runtime Fraction'
        else
          var_name = "Fan Runtime Fraction Speed #{i}"
        end
        fan_data[:rtf_sensor][object] << Model.add_ems_sensor(
          model,
          name: "#{fan_data[:rtf_var][object].name} s",
          output_var_or_meter_name: var_name,
          key_name: supply_fan.name
        )
      end
    else
      fail "Unexpected fan: #{supply_fan.name}"
    end
  end

  # Issues warnings/errors if duct leakage to outside is detected to be suspiciously high. We check here
  # instead of in the Schematron validator in case duct locations are defaulted.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.check_duct_leakage(runner, hpxml_bldg)
    cfa = hpxml_bldg.building_construction.conditioned_floor_area
    hpxml_bldg.hvac_distributions.each do |hvac_distribution|
      next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir
      next if hvac_distribution.duct_leakage_measurements.empty?

      units = hvac_distribution.duct_leakage_measurements[0].duct_leakage_units
      lto_measurements = hvac_distribution.duct_leakage_measurements.select { |dlm| dlm.duct_leakage_total_or_to_outside == HPXML::DuctLeakageToOutside }
      sum_lto = lto_measurements.map { |dlm| dlm.duct_leakage_value }.sum(0.0)

      issue_warning = false
      issue_error = false

      if hvac_distribution.ducts.count { |d| !HPXML::conditioned_locations_this_unit.include?(d.duct_location) } == 0
        # If ducts completely in conditioned space, issue warning/error if duct leakage to outside above a certain threshold
        case units
        when HPXML::UnitsCFM25
          issue_warning = true if sum_lto > 0.04 * cfa
          issue_error = true if sum_lto > 0.04 * 2.5 * cfa
        when HPXML::UnitsCFM50
          issue_warning = true if sum_lto > 0.06 * cfa
          issue_error = true if sum_lto > 0.06 * 2.5 * cfa
        when HPXML::UnitsPercent
          issue_warning = true if sum_lto > 0.05
          issue_error = true if sum_lto > 0.05 * 2.5
        end

        if issue_error
          fail 'Duct leakage to outside is too high; double-check inputs.'
        elsif issue_warning
          runner.registerWarning('Ducts are entirely within conditioned space but there is moderate leakage to the outside. Leakage to the outside is typically zero or near-zero in these situations, consider revising leakage values. Leakage will be modeled as heat lost to the ambient environment.')
        end
      else
        # If ducts in unconditioned space, issue warning/error if duct leakage to outside above a certain threshold
        case units
        when HPXML::UnitsCFM25
          issue_warning = true if sum_lto >= 0.32 * cfa
          issue_error = true if sum_lto >= 0.32 * 2.5 * cfa
        when HPXML::UnitsCFM50
          issue_warning = true if sum_lto >= 0.48 * cfa
          issue_error = true if sum_lto >= 0.48 * 2.5 * cfa
        when HPXML::UnitsPercent
          issue_warning = true if sum_lto >= 0.4
          issue_error = true if sum_lto >= 0.4 * 2.5
        end

        if issue_error
          fail 'Duct leakage to outside is too high; double-check inputs.'
        elsif issue_warning
          runner.registerWarning('Very high sum of supply + return duct leakage to the outside; double-check inputs.')
        end
      end
    end
  end

  # Applies all air distribution systems' ducts to the OpenStudio model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param airloop_map [Hash] Map of HPXML System ID => OpenStudio AirLoopHVAC (or ZoneHVACFourPipeFanCoil or ZoneHVACBaseboardConvectiveWater) objects
  # @param vent_fans [Hash] Map of vent fan types => list of HPXML VentilationFans
  # @param cfis_data [Hash] Map with various CFIS-relative OpenStudio model objects
  # @param fan_data [Hash] Map of HVAC blower fan properties => values
  # @param duct_lk_imbals [Array] List of duct leakage imbalance information
  # @param sensors [Hash] Map of :sensor_types => OpenStudio::Model::EnergyManagementSystemSensor objects
  # @return [OpenStudio::Model::Construction] Adiabatic construction used by the duct model
  def self.apply_ducts(runner, model, spaces, hpxml_bldg, airloop_map, vent_fans, cfis_data, fan_data, duct_lk_imbals, sensors)
    check_duct_leakage(runner, hpxml_bldg)

    # Apply ducts for each air distribution system
    hpxml_bldg.hvac_distributions.each do |hvac_distribution|
      next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir

      duct_infos = create_duct_infos(model, hvac_distribution, spaces)
      next if duct_infos.empty?

      objects = hvac_distribution.hvac_systems.map { |hvac_system| airloop_map[hvac_system.id] }.select { |o| !o.nil? }.uniq
      objects.each do |object|
        apply_ducts_for_distribution_system(model, spaces, hpxml_bldg, duct_infos, object, vent_fans, cfis_data, fan_data, duct_lk_imbals, sensors)
      end
    end
  end

  # Creates an EMS program to calculate duct losses for a given air distribution system.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param duct_infos [Array<Hash>] List of duct info Hashes
  # @param object [OpenStudio::Model::XXX] OpenStudio AirLoopHVAC (or ZoneHVACFourPipeFanCoil or ZoneHVACBaseboardConvectiveWater) object
  # @param vent_fans [Hash] Map of vent fan types => list of HPXML VentilationFans
  # @param cfis_data [Hash] Map with various CFIS-relative OpenStudio model objects
  # @param fan_data [Hash] Map of HVAC blower fan properties => values
  # @param duct_lk_imbals [Array] List of duct leakage imbalance information
  # @param sensors [Hash] Map of :sensor_types => OpenStudio::Model::EnergyManagementSystemSensor objects
  # @return [nil]
  def self.apply_ducts_for_distribution_system(model, spaces, hpxml_bldg, duct_infos, object, vent_fans, cfis_data, fan_data, duct_lk_imbals, sensors)
    conditioned_space = spaces[HPXML::LocationConditionedSpace]
    conditioned_zone = conditioned_space.thermalZone.get
    unit_multiplier = hpxml_bldg.building_construction.number_of_units

    duct_infos.each do |duct_info|
      if not duct_info[:loc_schedule].nil?
        # MF space temperature schedule name
        duct_info[:location] = duct_info[:loc_schedule].name.to_s
        duct_info[:zone] = nil
      elsif not duct_info[:loc_space].nil?
        # Thermal zone
        duct_info[:location] = duct_info[:loc_space].name.to_s
        duct_info[:zone] = duct_info[:loc_space].thermalZone.get
      else
        # Outside/RoofDeck
        duct_info[:location] = HPXML::LocationOutside
        duct_info[:zone] = nil
      end
    end

    return if duct_infos.size == 0 # No ducts

    if object.is_a? OpenStudio::Model::AirLoopHVAC
      # Most system types

      # Set the return plenum
      ra_duct_zone = create_return_air_duct_zone(model, object.name.to_s, unit_multiplier)
      ra_duct_space = ra_duct_zone.spaces[0]
      conditioned_zone.setReturnPlenum(ra_duct_zone, object)

      inlet_node = object.demandInletNode
    elsif object.is_a? OpenStudio::Model::ZoneHVACFourPipeFanCoil
      # Ducted fan coil

      # No return plenum
      ra_duct_space = conditioned_space

      inlet_node = object.inletNode.get
    end

    # -- Sensors --
    duct_sensors = {}

    # Air handler mass flow rate
    ah_mfr_var = Model.add_ems_global_var(
      model,
      var_name: "#{object.name} AH MFR"
    )
    ah_mfr_sensor = Model.add_ems_sensor(
      model,
      name: "#{ah_mfr_var.name} s",
      output_var_or_meter_name: 'System Node Mass Flow Rate',
      key_name: inlet_node.name
    )
    duct_sensors[:ah_mfr] = [ah_mfr_var, ah_mfr_sensor]

    # Air handler volume flow rate
    ah_vfr_var = Model.add_ems_global_var(
      model,
      var_name: "#{object.name} AH VFR"
    )
    ah_vfr_sensor = Model.add_ems_sensor(
      model,
      name: "#{ah_vfr_var.name} s",
      output_var_or_meter_name: 'System Node Current Density Volume Flow Rate',
      key_name: inlet_node.name
    )
    duct_sensors[:ah_vfr] = [ah_vfr_var, ah_vfr_sensor]

    # Air handler outlet temperature
    ah_tout_var = Model.add_ems_global_var(
      model,
      var_name: "#{object.name} AH Tout"
    )
    ah_tout_sensor = Model.add_ems_sensor(
      model,
      name: "#{ah_tout_var.name} s",
      output_var_or_meter_name: 'System Node Temperature',
      key_name: inlet_node.name
    )
    duct_sensors[:ah_tout] = [ah_tout_var, ah_tout_sensor]

    # Air handler outlet humidity ratio
    ah_wout_var = Model.add_ems_global_var(
      model,
      var_name: "#{object.name} AH Wout"
    )
    ah_wout_sensor = Model.add_ems_sensor(
      model,
      name: "#{ah_wout_var.name} s",
      output_var_or_meter_name: 'System Node Humidity Ratio',
      key_name: inlet_node.name
    )
    duct_sensors[:ah_wout] = [ah_wout_var, ah_wout_sensor]

    conditioned_zone_return_air_node = nil
    conditioned_zone.returnAirModelObjects.each do |return_air_model_obj|
      next if return_air_model_obj.to_Node.get.airLoopHVAC.get != object

      conditioned_zone_return_air_node = return_air_model_obj
    end

    # Return air temperature
    ra_t_var = Model.add_ems_global_var(
      model,
      var_name: "#{object.name} RA T"
    )
    if not conditioned_zone_return_air_node.nil?
      ra_t_sensor = Model.add_ems_sensor(
        model,
        name: "#{ra_t_var.name} s",
        output_var_or_meter_name: 'System Node Temperature',
        key_name: conditioned_zone_return_air_node.name
      )
    else
      ra_t_sensor = sensors[:t_in]
    end
    duct_sensors[:ra_t] = [ra_t_var, ra_t_sensor]

    # Return air humidity ratio
    ra_w_var = Model.add_ems_global_var(
      model,
      var_name: "#{object.name} Ra W"
    )
    if not conditioned_zone_return_air_node.nil?
      ra_w_sensor = Model.add_ems_sensor(
        model,
        name: "#{ra_w_var.name} s",
        output_var_or_meter_name: 'System Node Humidity Ratio',
        key_name: conditioned_zone_return_air_node.name
      )
    else
      ra_w_sensor = Model.add_ems_sensor(
        model,
        name: "#{ra_w_var.name} s",
        output_var_or_meter_name: 'Zone Mean Air Humidity Ratio',
        key_name: conditioned_zone.name
      )
    end
    duct_sensors[:ra_w] = [ra_w_var, ra_w_sensor]

    # Get unique set of duct locations
    duct_locations = duct_infos.map { |duct_info| if duct_info[:zone].nil? then duct_info[:loc_schedule] else duct_info[:zone] end }.uniq

    # Assign ducts to each duct location
    duct_locations_infos = {}
    duct_locations.each do |duct_location|
      duct_locations_infos[duct_location] = []
      duct_infos.each do |duct_info|
        next unless (duct_location.nil? && duct_info[:zone].nil?) ||
                    (!duct_location.nil? && !duct_info[:zone].nil? && (duct_info[:zone].name.to_s == duct_location.name.to_s)) ||
                    (!duct_location.nil? && !duct_info[:loc_schedule].nil? && (duct_info[:loc_schedule].name.to_s == duct_location.name.to_s))

        duct_locations_infos[duct_location] << duct_info
      end
    end

    # Create one duct program for each duct location zone (plus an extra one for CFIS ducts from outside, if appropriate)
    duct_locations_infos.each_with_index do |(duct_location, duct_location_info), index|
      next if (not duct_location.nil?) && (duct_location.name.to_s == conditioned_zone.name.to_s)

      apply_ducts_for_distribution_system_location(model, spaces, hpxml_bldg, duct_location_info, object, index, duct_location, vent_fans, cfis_data, fan_data, duct_lk_imbals, sensors, duct_sensors, ra_duct_space)
    end
  end

  # Creates an EMS program to calculate duct losses for a given location (e.g., vented
  # crawlspace) of a given air distribution system.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param duct_infos [Array<Hash>] List of duct info Hashes
  # @param object [OpenStudio::Model::XXX] OpenStudio AirLoopHVAC (or ZoneHVACFourPipeFanCoil or ZoneHVACBaseboardConvectiveWater) object
  # @param index [Integer] Index number of the current duct location
  # @param duct_location [OpenStudio::Model::ScheduleConstant or OpenStudio::Model::ThermalZone or nil] Location of the ducts
  # @param vent_fans [Hash] Map of vent fan types => list of HPXML VentilationFans
  # @param cfis_data [Hash] Map with various CFIS-relative OpenStudio model objects
  # @param fan_data [Hash] Map of HVAC blower fan properties => values
  # @param duct_lk_imbals [Array] List of duct leakage imbalance information
  # @param sensors [Hash] Map of :sensor_type => OpenStudio::Model::EnergyManagementSystemSensor objects
  # @param duct_sensors [Hash] Map of :sensor_type => (EMS global var, EMS sensor)
  # @param ra_duct_space [OpenStudio::Model::Space] Return air duct space used in the EMS calculations
  # @return [nil]
  def self.apply_ducts_for_distribution_system_location(model, spaces, hpxml_bldg, duct_infos, object, index, duct_location, vent_fans, cfis_data, fan_data, duct_lk_imbals, sensors, duct_sensors, ra_duct_space)
    conditioned_space = spaces[HPXML::LocationConditionedSpace]
    conditioned_zone = conditioned_space.thermalZone.get
    unit_multiplier = hpxml_bldg.building_construction.number_of_units

    object_name_idx = "#{object.name}_#{index}"

    ah_mfr_var, ah_mfr_sensor = duct_sensors[:ah_mfr]
    ah_vfr_var, ah_vfr_sensor = duct_sensors[:ah_vfr]
    ah_tout_var, ah_tout_sensor = duct_sensors[:ah_tout]
    ah_wout_var, ah_wout_sensor = duct_sensors[:ah_wout]
    ra_t_var, ra_t_sensor = duct_sensors[:ra_t]
    ra_w_var, ra_w_sensor = duct_sensors[:ra_w]

    # -- Sensors --

    # Duct zone temperature
    dz_t_var = Model.add_ems_global_var(
      model,
      var_name: "#{object_name_idx} DZ T"
    )
    if duct_location.is_a? OpenStudio::Model::ThermalZone
      dz_t_sensor = Model.add_ems_sensor(
        model,
        name: "#{dz_t_var.name} s",
        output_var_or_meter_name: 'Zone Air Temperature',
        key_name: duct_location.name
      )
    elsif duct_location.is_a? OpenStudio::Model::ScheduleConstant
      dz_t_sensor = Model.add_ems_sensor(
        model,
        name: "#{dz_t_var.name} s",
        output_var_or_meter_name: 'Schedule Value',
        key_name: duct_location.name
      )
    elsif duct_location.nil? # Outside
      dz_t_sensor = Model.add_ems_sensor(
        model,
        name: "#{dz_t_var.name} s",
        output_var_or_meter_name: 'Site Outdoor Air Drybulb Temperature',
        key_name: 'Environment'
      )
    else # shouldn't get here, should only have schedule/thermal zone/nil assigned
      fail 'Unexpected duct zone type passed'
    end

    # Duct zone humidity ratio
    dz_w_var = Model.add_ems_global_var(
      model,
      var_name: "#{object_name_idx} DZ W"
    )
    if duct_location.is_a? OpenStudio::Model::ThermalZone
      dz_w_sensor = Model.add_ems_sensor(
        model,
        name: "#{dz_w_var.name} s",
        output_var_or_meter_name: 'Zone Mean Air Humidity Ratio',
        key_name: duct_location.name
      )
      dz_w = "#{dz_w_sensor.name}"
    elsif duct_location.is_a? OpenStudio::Model::ScheduleConstant # Outside or scheduled temperature
      if duct_location.name.to_s == HPXML::LocationOtherNonFreezingSpace
        dz_w_sensor = Model.add_ems_sensor(
          model,
          name: "#{dz_w_var.name} s",
          output_var_or_meter_name: 'Site Outdoor Air Humidity Ratio',
          key_name: nil
        )
        dz_w = "#{dz_w_sensor.name}"
      elsif duct_location.name.to_s == HPXML::LocationOtherHousingUnit
        dz_w_sensor = Model.add_ems_sensor(
          model,
          name: "#{dz_w_var.name} s",
          output_var_or_meter_name: 'Zone Mean Air Humidity Ratio',
          key_name: conditioned_zone.name
        )
        dz_w = "#{dz_w_sensor.name}"
      else
        dz_w_sensor1 = Model.add_ems_sensor(
          model,
          name: "#{dz_w_var.name} s 1",
          output_var_or_meter_name: 'Site Outdoor Air Humidity Ratio',
          key_name: nil
        )

        dz_w_sensor2 = Model.add_ems_sensor(
          model,
          name: "#{dz_w_var.name} s 2",
          output_var_or_meter_name: 'Zone Mean Air Humidity Ratio',
          key_name: conditioned_zone.name
        )
        dz_w = "(#{dz_w_sensor1.name} + #{dz_w_sensor2.name}) / 2"
      end
    else
      dz_w_sensor = Model.add_ems_sensor(
        model,
        name: "#{dz_w_var.name} s",
        output_var_or_meter_name: 'Site Outdoor Air Humidity Ratio',
        key_name: nil
      )
      dz_w = "#{dz_w_sensor.name}"
    end

    # -- Actuators --

    # List of: [Var name, object name, space, end use, frac load latent, frac load outside]
    equip_act_infos = []

    if duct_location.is_a? OpenStudio::Model::ScheduleConstant
      space_values = Geometry.get_temperature_scheduled_space_values(duct_location.name.to_s)
      f_regain = space_values[:f_regain]
    else
      f_regain = 0.0
    end

    # Other equipment objects to cancel out the supply air leakage directly into the return plenum
    equip_act_infos << ['supply_sens_lk_to_cond', 'SupSensLkToCond', Constants::ObjectTypeDuctLoad, conditioned_space, 0.0, f_regain]
    equip_act_infos << ['supply_lat_lk_to_cond', 'SupLatLkToCond', Constants::ObjectTypeDuctLoad, conditioned_space, 1 - f_regain, f_regain]

    # Supply duct conduction load added to the conditioned space
    equip_act_infos << ['supply_cond_to_cond', 'SupCondToLv', Constants::ObjectTypeDuctLoad, conditioned_space, 0.0, f_regain]

    # Return duct conduction load added to the return plenum zone
    equip_act_infos << ['return_cond_to_rp', 'RetCondToRP', Constants::ObjectTypeDuctLoad, ra_duct_space, 0.0, f_regain]

    # Return duct sensible leakage impact on the return plenum
    equip_act_infos << ['return_sens_lk_to_rp', 'RetSensLkToRP', Constants::ObjectTypeDuctLoad, ra_duct_space, 0.0, f_regain]

    # Return duct latent leakage impact on the return plenum
    equip_act_infos << ['return_lat_lk_to_rp', 'RetLatLkToRP', Constants::ObjectTypeDuctLoad, ra_duct_space, 1 - f_regain, f_regain]

    # Supply duct conduction impact on the duct zone
    if not duct_location.is_a? OpenStudio::Model::ThermalZone # Outside or scheduled temperature
      equip_act_infos << ['supply_cond_to_dz', 'SupCondToDZ', nil, conditioned_space, 0.0, 1.0] # Arbitrary space, all heat lost
    else
      equip_act_infos << ['supply_cond_to_dz', 'SupCondToDZ', nil, duct_location.spaces[0], 0.0, 0.0]
    end

    # Return duct conduction impact on the duct zone
    if not duct_location.is_a? OpenStudio::Model::ThermalZone # Outside or scheduled temperature
      equip_act_infos << ['return_cond_to_dz', 'RetCondToDZ', nil, conditioned_space, 0.0, 1.0] # Arbitrary space, all heat lost
    else
      equip_act_infos << ['return_cond_to_dz', 'RetCondToDZ', nil, duct_location.spaces[0], 0.0, 0.0]
    end

    # Supply duct sensible leakage impact on the duct zone
    if not duct_location.is_a? OpenStudio::Model::ThermalZone # Outside or scheduled temperature
      equip_act_infos << ['supply_sens_lk_to_dz', 'SupSensLkToDZ', nil, conditioned_space, 0.0, 1.0] # Arbitrary space, all heat lost
    else
      equip_act_infos << ['supply_sens_lk_to_dz', 'SupSensLkToDZ', nil, duct_location.spaces[0], 0.0, 0.0]
    end

    # Supply duct latent leakage impact on the duct zone
    if not duct_location.is_a? OpenStudio::Model::ThermalZone # Outside or scheduled temperature
      equip_act_infos << ['supply_lat_lk_to_dz', 'SupLatLkToDZ', nil, conditioned_space, 0.0, 1.0] # Arbitrary space, all heat lost
    else
      equip_act_infos << ['supply_lat_lk_to_dz', 'SupLatLkToDZ', nil, duct_location.spaces[0], 1.0, 0.0]
    end

    duct_vars = {}
    duct_actuators = {}
    [false, true].each do |is_cfis|
      if is_cfis
        next unless cfis_data[:airloop].values.include? object

        prefix = 'cfis_'
      else
        prefix = ''
      end
      equip_act_infos.each do |act_info|
        var_name = "#{prefix}#{act_info[0]}"
        object_name = "#{object_name_idx} #{prefix}#{act_info[1]}"
        end_use = act_info[2]
        space = act_info[3]
        if is_cfis && (space == ra_duct_space)
          # Move all CFIS return duct losses to the conditioned space so as to avoid extreme plenum temperatures
          # due to mismatch between return plenum duct loads and airloop airflow rate (which does not actually
          # increase due to the presence of CFIS).
          space = conditioned_space
        end
        frac_lat = act_info[4]
        frac_lost = act_info[5]
        if not is_cfis
          duct_vars[var_name] = Model.add_ems_global_var(
            model,
            var_name: object_name
          )
        end
        other_equip = Model.add_other_equipment(
          model,
          name: object_name,
          end_use: end_use,
          space: space,
          design_level: nil,
          frac_radiant: 0,
          frac_latent: frac_lat,
          frac_lost: frac_lost,
          schedule: model.alwaysOnDiscreteSchedule,
          fuel_type: nil
        )

        duct_actuators[var_name] = Model.add_ems_actuator(
          name: "#{other_equip.name} act",
          model_object: other_equip,
          comp_type_and_control: EPlus::EMSActuatorOtherEquipmentPower
        )
      end
    end

    # Two objects are required to model the air exchange between the duct zone and the conditioned space since
    # ZoneMixing objects can not account for direction of air flow (both are controlled by EMS)

    # List of: [Var name, object name, destination zone, source zone]
    mix_act_infos = []

    if duct_location.is_a? OpenStudio::Model::ThermalZone
      # Accounts for leaks from the duct zone to the conditioned zone
      mix_act_infos << ['dz_to_cond_flow_rate', 'ZoneMixDZToCond', conditioned_zone, duct_location]
      # Accounts for leaks from the conditioned zone to the duct zone
      mix_act_infos << ['cond_to_dz_flow_rate', 'ZoneMixCondToDZ', duct_location, conditioned_zone]
    end

    [false, true].each do |is_cfis|
      if is_cfis
        next unless cfis_data[:airloop].values.include? object

        prefix = 'cfis_'
      else
        prefix = ''
      end
      mix_act_infos.each do |act_info|
        var_name = "#{prefix}#{act_info[0]}"
        object_name = "#{object_name_idx} #{prefix}#{act_info[1]}"
        dest_zone = act_info[2]
        source_zone = act_info[3]

        if not is_cfis
          duct_vars[var_name] = Model.add_ems_global_var(
            model,
            var_name: object_name
          )
        end
        zone_mixing = OpenStudio::Model::ZoneMixing.new(dest_zone)
        zone_mixing.setName("#{object_name} mix")
        zone_mixing.setSourceZone(source_zone)
        zone_mixing.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeDuctLoad)

        duct_actuators[var_name] = Model.add_ems_actuator(
          name: "#{zone_mixing.name} act",
          model_object: zone_mixing,
          comp_type_and_control: EPlus::EMSActuatorZoneMixingFlowRate
        )
      end
    end

    # -- Global Variables --
    duct_lk_supply_fan_equiv_cond_var = Model.add_ems_global_var(
      model,
      var_name: "#{object_name_idx} DuctImbalLkSupFanEquivCond"
    )
    duct_lk_exhaust_fan_equiv_cond_var = Model.add_ems_global_var(
      model,
      var_name: "#{object_name_idx} DuctImbalLkExhFanEquivCond"
    )
    duct_lk_imbals << [conditioned_zone.name.to_s, duct_lk_supply_fan_equiv_cond_var, duct_lk_exhaust_fan_equiv_cond_var]
    if not duct_location.nil?
      duct_lk_supply_fan_equiv_dz_var = Model.add_ems_global_var(
        model,
        var_name: "#{object_name_idx} DuctImbalLkSupFanEquivDZ"
      )
      duct_lk_exhaust_fan_equiv_dz_var = Model.add_ems_global_var(
        model,
        var_name: "#{object_name_idx} DuctImbalLkExhFanEquivDZ"
      )
      duct_lk_imbals << [duct_location.name.to_s, duct_lk_supply_fan_equiv_dz_var, duct_lk_exhaust_fan_equiv_dz_var]
    end

    # Obtain aggregate values for all ducts in the current duct location
    leakage_fracs = { HPXML::DuctTypeSupply => nil, HPXML::DuctTypeReturn => nil }
    leakage_cfm25s = { HPXML::DuctTypeSupply => nil, HPXML::DuctTypeReturn => nil }
    ua_values = { HPXML::DuctTypeSupply => 0, HPXML::DuctTypeReturn => 0 }
    duct_infos.each do |duct_info|
      side = duct_info[:side]
      if not duct_info[:leakage_frac].nil?
        leakage_fracs[side] = 0 if leakage_fracs[side].nil?
        leakage_fracs[side] += duct_info[:leakage_frac]
      elsif not duct_info[:leakage_cfm25].nil?
        leakage_cfm25s[side] = 0 if leakage_cfm25s[side].nil?
        leakage_cfm25s[side] += duct_info[:leakage_cfm25]
      elsif not duct_info[:leakage_cfm50].nil?
        leakage_cfm25s[side] = 0 if leakage_cfm25s[side].nil?
        leakage_cfm25s[side] += calc_infiltration_at_diff_pressure(duct_info[:leakage_cfm50], 50.0, 25.0)
      end
      ua_values[side] += duct_info[:area] / duct_info[:effective_rvalue]
    end

    # Check if the duct location is a vented space
    duct_location_is_vented = false
    if duct_location.nil? # Outside
      duct_location_is_vented = true
    else
      if duct_location.is_a? OpenStudio::Model::ThermalZone
        HPXML::vented_locations.each do |vented_location|
          if (not spaces[vented_location].nil?) && (spaces[vented_location].thermalZone.get.name.to_s == duct_location.name.to_s)
            duct_location_is_vented = true
          end
        end
      end
    end

    # Duct Subroutine
    duct_subroutine = Model.add_ems_subroutine(
      model,
      name: "#{object_name_idx} duct subroutine"
    )
    duct_subroutine.addLine("Set AH_MFR = #{ah_mfr_var.name} / #{unit_multiplier}")
    duct_subroutine.addLine('If AH_MFR > 0')
    duct_subroutine.addLine("  Set AH_Tout = #{ah_tout_var.name}")
    duct_subroutine.addLine("  Set AH_Wout = #{ah_wout_var.name}")
    duct_subroutine.addLine("  Set RA_T = #{ra_t_var.name}")
    duct_subroutine.addLine("  Set RA_W = #{ra_w_var.name}")
    duct_subroutine.addLine("  Set Fan_RTF = #{fan_data[:rtf_var][object].name}")
    duct_subroutine.addLine("  Set DZ_T = #{dz_t_var.name}")
    duct_subroutine.addLine("  Set DZ_W = #{dz_w_var.name}")
    duct_subroutine.addLine("  Set AH_VFR = #{ah_vfr_var.name} / #{unit_multiplier}")
    duct_subroutine.addLine('  Set h_SA = (@HFnTdbW AH_Tout AH_Wout)') # J/kg
    duct_subroutine.addLine('  Set h_RA = (@HFnTdbW RA_T RA_W)') # J/kg
    duct_subroutine.addLine('  Set h_fg = (@HfgAirFnWTdb AH_Wout AH_Tout)') # J/kg
    duct_subroutine.addLine('  Set h_DZ = (@HFnTdbW DZ_T DZ_W)') # J/kg
    duct_subroutine.addLine('  Set air_cp = 1006.0') # J/kg-C

    if not leakage_fracs[HPXML::DuctTypeSupply].nil?
      duct_subroutine.addLine("  Set f_sup = #{leakage_fracs[HPXML::DuctTypeSupply]}") # frac
    elsif not leakage_cfm25s[HPXML::DuctTypeSupply].nil?
      duct_subroutine.addLine("  Set f_sup = #{UnitConversions.convert(leakage_cfm25s[HPXML::DuctTypeSupply], 'cfm', 'm^3/s').round(6)} / (#{fan_data[:mfr_max_var][object].name}/#{unit_multiplier} * 1.0135)") # frac
    else
      duct_subroutine.addLine('  Set f_sup = 0.0') # frac
    end
    if not leakage_fracs[HPXML::DuctTypeReturn].nil?
      duct_subroutine.addLine("  Set f_ret = #{leakage_fracs[HPXML::DuctTypeReturn]}") # frac
    elsif not leakage_cfm25s[HPXML::DuctTypeReturn].nil?
      duct_subroutine.addLine("  Set f_ret = #{UnitConversions.convert(leakage_cfm25s[HPXML::DuctTypeReturn], 'cfm', 'm^3/s').round(6)} / (#{fan_data[:mfr_max_var][object].name}/#{unit_multiplier} * 1.0135)") # frac
    else
      duct_subroutine.addLine('  Set f_ret = 0.0') # frac
    end
    duct_subroutine.addLine('  Set sup_lk_mfr = f_sup * AH_MFR') # kg/s
    duct_subroutine.addLine('  Set ret_lk_mfr = f_ret * AH_MFR') # kg/s

    # Supply leakage to conditioned space
    duct_subroutine.addLine('  Set SupTotLkToCond = sup_lk_mfr*(h_RA - h_SA)') # W
    duct_subroutine.addLine('  Set SupLatLkToCond = sup_lk_mfr*h_fg*(RA_W-AH_Wout)') # W
    duct_subroutine.addLine('  Set SupSensLkToCond = SupTotLkToCond-SupLatLkToCond') # W

    # Supply conduction
    duct_subroutine.addLine("  Set supply_ua = #{UnitConversions.convert(ua_values[HPXML::DuctTypeSupply], 'Btu/(hr*F)', 'W/K').round(3)}")
    duct_subroutine.addLine('  Set eTm = 0-((Fan_RTF/(AH_MFR*air_cp))*supply_ua)')
    duct_subroutine.addLine('  Set t_sup = DZ_T+((AH_Tout-DZ_T)*(@Exp eTm))') # C
    duct_subroutine.addLine('  Set SupCondToCond = AH_MFR*air_cp*(t_sup-AH_Tout)') # W
    duct_subroutine.addLine('  Set SupCondToDZ = 0-SupCondToCond') # W

    # Return conduction
    duct_subroutine.addLine("  Set return_ua = #{UnitConversions.convert(ua_values[HPXML::DuctTypeReturn], 'Btu/(hr*F)', 'W/K').round(3)}")
    duct_subroutine.addLine('  Set eTm = 0-((Fan_RTF/(AH_MFR*air_cp))*return_ua)')
    duct_subroutine.addLine('  Set t_ret = DZ_T+((RA_T-DZ_T)*(@Exp eTm))') # C
    duct_subroutine.addLine('  Set RetCondToRP = AH_MFR*air_cp*(t_ret-RA_T)') # W
    duct_subroutine.addLine('  Set RetCondToDZ = 0-RetCondToRP') # W

    # Return leakage to return plenum
    duct_subroutine.addLine('  Set RetLatLkToRP = 0') # W
    duct_subroutine.addLine('  Set RetSensLkToRP = ret_lk_mfr*air_cp*(DZ_T-RA_T)') # W

    # Supply leakage to duct zone
    # The below terms are not the same as SupLatLkToCond and SupSensLkToCond.
    # To understand why, suppose the AHzone temperature equals the supply air temperature. In this case, the terms below
    # should be zero while SupLatLkToCond and SupSensLkToCond should still be non-zero.
    duct_subroutine.addLine('  Set SupTotLkToDZ = sup_lk_mfr*(h_SA-h_DZ)') # W
    duct_subroutine.addLine('  Set SupLatLkToDZ = sup_lk_mfr*h_fg*(AH_Wout-DZ_W)') # W
    duct_subroutine.addLine('  Set SupSensLkToDZ = SupTotLkToDZ-SupLatLkToDZ') # W

    # Handle duct leakage imbalance induced infiltration (ANSI/RESNET/ICC 301-2022 Addendum C Table 4.2.2(1c)
    leakage_supply = leakage_fracs[HPXML::DuctTypeSupply].to_f + leakage_cfm25s[HPXML::DuctTypeSupply].to_f
    leakage_return = leakage_fracs[HPXML::DuctTypeReturn].to_f + leakage_cfm25s[HPXML::DuctTypeReturn].to_f
    if leakage_supply == leakage_return
      duct_subroutine.addLine('  Set FracOutsideToCond = 0.0')
      duct_subroutine.addLine('  Set FracOutsideToDZ = 0.0')
      duct_subroutine.addLine('  Set FracCondToOutside = 0.0')
      duct_subroutine.addLine('  Set FracDZToOutside = 0.0')
      duct_subroutine.addLine('  Set FracDZToCond = 0.0')
      duct_subroutine.addLine('  Set FracCondToDZ = 0.0')
    elsif leakage_supply > leakage_return # Supply > Return (conditioned space is depressurized)
      if duct_location_is_vented # Duct location vented
        duct_subroutine.addLine('  Set FracOutsideToCond = 1.0')
        duct_subroutine.addLine('  Set FracOutsideToDZ = 0.0')
        duct_subroutine.addLine('  Set FracCondToOutside = 0.0')
        duct_subroutine.addLine('  Set FracDZToOutside = 1.0')
        duct_subroutine.addLine('  Set FracDZToCond = 0.0')
        duct_subroutine.addLine('  Set FracCondToDZ = 0.0')
      else # Duct location unvented
        duct_subroutine.addLine('  Set FracOutsideToCond = 0.5')
        duct_subroutine.addLine('  Set FracOutsideToDZ = 0.0')
        duct_subroutine.addLine('  Set FracCondToOutside = 0.0')
        duct_subroutine.addLine('  Set FracDZToOutside = 0.5')
        duct_subroutine.addLine('  Set FracDZToCond = 0.5')
        duct_subroutine.addLine('  Set FracCondToDZ = 0.0')
      end
    else # Supply < Return (conditioned space is pressurized)
      if duct_location_is_vented # Duct location vented
        duct_subroutine.addLine('  Set FracOutsideToCond = 0.0')
        duct_subroutine.addLine('  Set FracOutsideToDZ = 1.0')
        duct_subroutine.addLine('  Set FracCondToOutside = 1.0')
        duct_subroutine.addLine('  Set FracDZToOutside = 0.0')
        duct_subroutine.addLine('  Set FracDZToCond = 0.0')
        duct_subroutine.addLine('  Set FracCondToDZ = 0.0')
      else # Duct location unvented
        duct_subroutine.addLine('  Set FracOutsideToCond = 0.0')
        duct_subroutine.addLine('  Set FracOutsideToDZ = 0.5')
        duct_subroutine.addLine('  Set FracCondToOutside = 0.5')
        duct_subroutine.addLine('  Set FracDZToOutside = 0.0')
        duct_subroutine.addLine('  Set FracDZToCond = 0.0')
        duct_subroutine.addLine('  Set FracCondToDZ = 0.5')
      end
    end
    duct_subroutine.addLine('  Set lk_imbal_vfr = @ABS(f_sup - f_ret) * AH_VFR') # m3/s
    duct_subroutine.addLine('  Set ImbalLkCondToDZ = lk_imbal_vfr * FracCondToDZ') # m3/s
    duct_subroutine.addLine('  Set ImbalLkDZToCond = lk_imbal_vfr * FracDZToCond') # m3/s
    duct_subroutine.addLine('  Set ImbalLkOutsideToCond = lk_imbal_vfr * FracOutsideToCond') # m3/s
    duct_subroutine.addLine('  Set ImbalLkOutsideToDZ = lk_imbal_vfr * FracOutsideToDZ') # m3/s
    duct_subroutine.addLine('  Set ImbalLkCondToOutside = lk_imbal_vfr * FracCondToOutside') # m3/s
    duct_subroutine.addLine('  Set ImbalLkDZToOutside = lk_imbal_vfr * FracDZToOutside') # m3/s
    duct_subroutine.addLine('Else') # No air handler flow rate
    duct_subroutine.addLine('  Set SupLatLkToCond = 0')
    duct_subroutine.addLine('  Set SupSensLkToCond = 0')
    duct_subroutine.addLine('  Set SupCondToCond = 0')
    duct_subroutine.addLine('  Set RetCondToRP = 0')
    duct_subroutine.addLine('  Set RetLatLkToRP = 0')
    duct_subroutine.addLine('  Set RetSensLkToRP = 0')
    duct_subroutine.addLine('  Set RetCondToDZ = 0')
    duct_subroutine.addLine('  Set SupCondToDZ = 0')
    duct_subroutine.addLine('  Set SupLatLkToDZ = 0')
    duct_subroutine.addLine('  Set SupSensLkToDZ = 0')
    duct_subroutine.addLine('  Set ImbalLkCondToDZ = 0')
    duct_subroutine.addLine('  Set ImbalLkDZToCond = 0')
    duct_subroutine.addLine('  Set ImbalLkOutsideToCond = 0')
    duct_subroutine.addLine('  Set ImbalLkOutsideToDZ = 0')
    duct_subroutine.addLine('  Set ImbalLkCondToOutside = 0')
    duct_subroutine.addLine('  Set ImbalLkDZToOutside = 0')
    duct_subroutine.addLine('EndIf')
    duct_subroutine.addLine("Set #{duct_vars['supply_lat_lk_to_cond'].name} = SupLatLkToCond")
    duct_subroutine.addLine("Set #{duct_vars['supply_sens_lk_to_cond'].name} = SupSensLkToCond")
    duct_subroutine.addLine("Set #{duct_vars['supply_cond_to_cond'].name} = SupCondToCond")
    duct_subroutine.addLine("Set #{duct_vars['return_cond_to_rp'].name} = RetCondToRP")
    duct_subroutine.addLine("Set #{duct_vars['return_lat_lk_to_rp'].name} = RetLatLkToRP")
    duct_subroutine.addLine("Set #{duct_vars['return_sens_lk_to_rp'].name} = RetSensLkToRP")
    duct_subroutine.addLine("Set #{duct_vars['return_cond_to_dz'].name} = RetCondToDZ")
    duct_subroutine.addLine("Set #{duct_vars['supply_cond_to_dz'].name} = SupCondToDZ")
    duct_subroutine.addLine("Set #{duct_vars['supply_lat_lk_to_dz'].name} = SupLatLkToDZ")
    duct_subroutine.addLine("Set #{duct_vars['supply_sens_lk_to_dz'].name} = SupSensLkToDZ")
    if duct_location.is_a? OpenStudio::Model::ThermalZone
      duct_subroutine.addLine("Set #{duct_vars['cond_to_dz_flow_rate'].name} = ImbalLkCondToDZ")
      duct_subroutine.addLine("Set #{duct_vars['dz_to_cond_flow_rate'].name} = ImbalLkDZToCond")
    end
    duct_subroutine.addLine("Set #{duct_lk_supply_fan_equiv_cond_var.name} = ImbalLkCondToOutside")
    duct_subroutine.addLine("Set #{duct_lk_exhaust_fan_equiv_cond_var.name} = ImbalLkOutsideToCond")
    if not duct_location.nil?
      duct_subroutine.addLine("Set #{duct_lk_supply_fan_equiv_dz_var.name} = ImbalLkDZToOutside")
      duct_subroutine.addLine("Set #{duct_lk_exhaust_fan_equiv_dz_var.name} = ImbalLkOutsideToDZ")
    end

    # Duct Program

    duct_program = Model.add_ems_program(
      model,
      name: "#{object_name_idx} duct program"
    )
    duct_program.addLine("Set #{ah_mfr_var.name} = #{ah_mfr_sensor.name}")
    duct_program.addLine("Set #{fan_data[:rtf_var][object].name} = 0")
    fan_data[:rtf_sensor][object].each do |rtf_sensor|
      duct_program.addLine("Set #{fan_data[:rtf_var][object].name} = #{fan_data[:rtf_var][object].name} + #{rtf_sensor.name}")
    end
    duct_program.addLine("Set #{ah_vfr_var.name} = #{ah_vfr_sensor.name}")
    duct_program.addLine("Set #{ah_tout_var.name} = #{ah_tout_sensor.name}")
    duct_program.addLine("Set #{ah_wout_var.name} = #{ah_wout_sensor.name}")
    duct_program.addLine("Set #{ra_t_var.name} = #{ra_t_sensor.name}")
    duct_program.addLine("Set #{ra_w_var.name} = #{ra_w_sensor.name}")
    duct_program.addLine("Set #{dz_t_var.name} = #{dz_t_sensor.name}")
    duct_program.addLine("Set #{dz_w_var.name} = #{dz_w}")
    duct_program.addLine("Run #{duct_subroutine.name}")
    duct_program.addLine("Set #{duct_actuators['supply_sens_lk_to_cond'].name} = #{duct_vars['supply_sens_lk_to_cond'].name}")
    duct_program.addLine("Set #{duct_actuators['supply_lat_lk_to_cond'].name} = #{duct_vars['supply_lat_lk_to_cond'].name}")
    duct_program.addLine("Set #{duct_actuators['supply_cond_to_cond'].name} = #{duct_vars['supply_cond_to_cond'].name}")
    duct_program.addLine("Set #{duct_actuators['return_sens_lk_to_rp'].name} = #{duct_vars['return_sens_lk_to_rp'].name}")
    duct_program.addLine("Set #{duct_actuators['return_lat_lk_to_rp'].name} = #{duct_vars['return_lat_lk_to_rp'].name}")
    duct_program.addLine("Set #{duct_actuators['return_cond_to_rp'].name} = #{duct_vars['return_cond_to_rp'].name}")
    duct_program.addLine("Set #{duct_actuators['return_cond_to_dz'].name} = #{duct_vars['return_cond_to_dz'].name}")
    duct_program.addLine("Set #{duct_actuators['supply_cond_to_dz'].name} = #{duct_vars['supply_cond_to_dz'].name}")
    duct_program.addLine("Set #{duct_actuators['supply_sens_lk_to_dz'].name} = #{duct_vars['supply_sens_lk_to_dz'].name}")
    duct_program.addLine("Set #{duct_actuators['supply_lat_lk_to_dz'].name} = #{duct_vars['supply_lat_lk_to_dz'].name}")
    if duct_location.is_a? OpenStudio::Model::ThermalZone
      duct_program.addLine("Set #{duct_actuators['dz_to_cond_flow_rate'].name} = #{duct_vars['dz_to_cond_flow_rate'].name}")
      duct_program.addLine("Set #{duct_actuators['cond_to_dz_flow_rate'].name} = #{duct_vars['cond_to_dz_flow_rate'].name}")
    end

    if cfis_data[:airloop].values.include? object

      cfis_id = cfis_data[:airloop].key(object)
      cfis_fan = vent_fans[:mech].find { |vfm| vfm.id == cfis_id }

      add_cfis_duct_losses = (cfis_fan.cfis_addtl_runtime_operating_mode == HPXML::CFISModeAirHandler)
      if add_cfis_duct_losses
        # Calculate additional CFIS duct losses when the air handler is in ventilation only mode
        f_vent_only_mode_var = cfis_data[:f_vent_only_mode_var][cfis_id]

        duct_program.addLine("If #{f_vent_only_mode_var.name} > 0")
        duct_program.addLine("  Set cfis_m3s = (#{fan_data[:mfr_max_var][object].name} * #{cfis_fan.cfis_vent_mode_airflow_fraction} / 1.16097654)") # Density of 1.16097654 was back calculated using E+ results
        duct_program.addLine("  Set #{fan_data[:rtf_var][object].name} = #{f_vent_only_mode_var.name}") # Need to use global vars to sync duct_program and infiltration program of different calling points
        duct_program.addLine("  Set #{ah_vfr_var.name} = #{fan_data[:rtf_var][object].name}*cfis_m3s")
        duct_program.addLine("  Set rho_in = (@RhoAirFnPbTdbW #{sensors[:pbar].name} #{sensors[:t_in].name} #{sensors[:w_in].name})")
        duct_program.addLine("  Set #{ah_mfr_var.name} = #{ah_vfr_var.name} * rho_in")
        duct_program.addLine("  Set #{ah_tout_var.name} = #{ra_t_sensor.name}")
        duct_program.addLine("  Set #{ah_wout_var.name} = #{ra_w_sensor.name}")
        duct_program.addLine("  Set #{ra_t_var.name} = #{ra_t_sensor.name}")
        duct_program.addLine("  Set #{ra_w_var.name} = #{ra_w_sensor.name}")
        duct_program.addLine("  Run #{duct_subroutine.name}")
        duct_program.addLine("  Set #{duct_actuators['cfis_supply_sens_lk_to_cond'].name} = #{duct_vars['supply_sens_lk_to_cond'].name}")
        duct_program.addLine("  Set #{duct_actuators['cfis_supply_lat_lk_to_cond'].name} = #{duct_vars['supply_lat_lk_to_cond'].name}")
        duct_program.addLine("  Set #{duct_actuators['cfis_supply_cond_to_cond'].name} = #{duct_vars['supply_cond_to_cond'].name}")
        duct_program.addLine("  Set #{duct_actuators['cfis_return_sens_lk_to_rp'].name} = #{duct_vars['return_sens_lk_to_rp'].name}")
        duct_program.addLine("  Set #{duct_actuators['cfis_return_lat_lk_to_rp'].name} = #{duct_vars['return_lat_lk_to_rp'].name}")
        duct_program.addLine("  Set #{duct_actuators['cfis_return_cond_to_rp'].name} = #{duct_vars['return_cond_to_rp'].name}")
        duct_program.addLine("  Set #{duct_actuators['cfis_return_cond_to_dz'].name} = #{duct_vars['return_cond_to_dz'].name}")
        duct_program.addLine("  Set #{duct_actuators['cfis_supply_cond_to_dz'].name} = #{duct_vars['supply_cond_to_dz'].name}")
        duct_program.addLine("  Set #{duct_actuators['cfis_supply_sens_lk_to_dz'].name} = #{duct_vars['supply_sens_lk_to_dz'].name}")
        duct_program.addLine("  Set #{duct_actuators['cfis_supply_lat_lk_to_dz'].name} = #{duct_vars['supply_lat_lk_to_dz'].name}")
        if duct_location.is_a? OpenStudio::Model::ThermalZone
          duct_program.addLine("  Set #{duct_actuators['cfis_dz_to_cond_flow_rate'].name} = #{duct_vars['dz_to_cond_flow_rate'].name}")
          duct_program.addLine("  Set #{duct_actuators['cfis_cond_to_dz_flow_rate'].name} = #{duct_vars['cond_to_dz_flow_rate'].name}")
        end
        duct_program.addLine('Else')
      end
      duct_program.addLine("  Set #{duct_actuators['cfis_supply_sens_lk_to_cond'].name} = 0")
      duct_program.addLine("  Set #{duct_actuators['cfis_supply_lat_lk_to_cond'].name} = 0")
      duct_program.addLine("  Set #{duct_actuators['cfis_supply_cond_to_cond'].name} = 0")
      duct_program.addLine("  Set #{duct_actuators['cfis_return_sens_lk_to_rp'].name} = 0")
      duct_program.addLine("  Set #{duct_actuators['cfis_return_lat_lk_to_rp'].name} = 0")
      duct_program.addLine("  Set #{duct_actuators['cfis_return_cond_to_rp'].name} = 0")
      duct_program.addLine("  Set #{duct_actuators['cfis_return_cond_to_dz'].name} = 0")
      duct_program.addLine("  Set #{duct_actuators['cfis_supply_cond_to_dz'].name} = 0")
      duct_program.addLine("  Set #{duct_actuators['cfis_supply_sens_lk_to_dz'].name} = 0")
      duct_program.addLine("  Set #{duct_actuators['cfis_supply_lat_lk_to_dz'].name} = 0")
      if duct_location.is_a? OpenStudio::Model::ThermalZone
        duct_program.addLine("  Set #{duct_actuators['cfis_dz_to_cond_flow_rate'].name} = 0")
        duct_program.addLine("  Set #{duct_actuators['cfis_cond_to_dz_flow_rate'].name} = 0")
      end
      if add_cfis_duct_losses
        duct_program.addLine('EndIf')
      end

    end

    Model.add_ems_program_calling_manager(
      model,
      name: "#{duct_program.name} calling manager",
      calling_point: 'EndOfSystemTimestepAfterHVACReporting',
      ems_programs: [duct_program]
    )
  end

  # Adds infiltration to the OpenStudio garage space.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param infil_values [Hash] Map with various infiltration key-value pairs (SLA, infiltration volume & height, etc.)
  # @param duct_lk_imbals [Array] List of duct leakage imbalance information
  # @return [nil]
  def self.apply_infiltration_to_garage(model, spaces, hpxml_bldg, infil_values, duct_lk_imbals)
    return if spaces[HPXML::LocationGarage].nil?

    ach50 = infil_values[:ach50] * infil_values[:a_ext]

    space = spaces[HPXML::LocationGarage]
    area = UnitConversions.convert(space.floorArea, 'm^2', 'ft^2')
    volume = UnitConversions.convert(space.volume, 'm^3', 'ft^3')
    hor_lk_frac = 0.4 # DOE-2 Default
    neutral_level = 0.5 # DOE-2 Default
    sla = get_infiltration_SLA_from_ACH50(ach50, volume / area)
    ela = sla * area
    c_w_SG, c_s_SG = calc_wind_stack_coeffs(hpxml_bldg, hor_lk_frac, neutral_level, HPXML::LocationGarage)
    apply_infiltration_to_unconditioned_space(model, space, nil, ela, c_w_SG, c_s_SG, duct_lk_imbals)
  end

  # Adds infiltration to the OpenStudio unconditioned basement space.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param duct_lk_imbals [Array] List of duct leakage imbalance information
  # @return [nil]
  def self.apply_infiltration_to_unconditioned_basement(model, spaces, duct_lk_imbals)
    return if spaces[HPXML::LocationBasementUnconditioned].nil?

    space = spaces[HPXML::LocationBasementUnconditioned]
    ach = UnventedSpaceACH
    apply_infiltration_to_unconditioned_space(model, space, ach, nil, nil, nil, duct_lk_imbals)
  end

  # Adds infiltration to the OpenStudio vented crawlspace space.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param duct_lk_imbals [Array] List of duct leakage imbalance information
  # @return [nil]
  def self.apply_infiltration_to_vented_crawlspace(model, spaces, weather, hpxml_bldg, duct_lk_imbals)
    return if spaces[HPXML::LocationCrawlspaceVented].nil?

    vented_crawl = hpxml_bldg.foundations.find { |foundation| foundation.foundation_type == HPXML::FoundationTypeCrawlspaceVented }
    space = spaces[HPXML::LocationCrawlspaceVented]
    height = Geometry.calculate_zone_height(hpxml_bldg, HPXML::LocationCrawlspaceVented)
    sla = vented_crawl.vented_crawlspace_sla
    ach = get_infiltration_ACH_from_SLA(sla, height, ReferenceHeight, weather)
    apply_infiltration_to_unconditioned_space(model, space, ach, nil, nil, nil, duct_lk_imbals)
  end

  # Adds infiltration to the OpenStudio unvented crawlspace space.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param duct_lk_imbals [Array] List of duct leakage imbalance information
  # @return [nil]
  def self.apply_infiltration_to_unvented_crawlspace(model, spaces, duct_lk_imbals)
    return if spaces[HPXML::LocationCrawlspaceUnvented].nil?

    space = spaces[HPXML::LocationCrawlspaceUnvented]
    ach = UnventedSpaceACH
    apply_infiltration_to_unconditioned_space(model, space, ach, nil, nil, nil, duct_lk_imbals)
  end

  # Adds infiltration to the OpenStudio vented attic space.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param duct_lk_imbals [Array] List of duct leakage imbalance information
  # @return [nil]
  def self.apply_infiltration_to_vented_attic(model, spaces, weather, hpxml_bldg, hpxml_header, duct_lk_imbals)
    return if spaces[HPXML::LocationAtticVented].nil?

    vented_attic = hpxml_bldg.attics.find { |attic| attic.attic_type == HPXML::AtticTypeVented }
    if not vented_attic.vented_attic_sla.nil?
      if hpxml_header.apply_ashrae140_assumptions
        vented_attic_const_ach = get_infiltration_ACH_from_SLA(vented_attic.vented_attic_sla, ReferenceHeight, ReferenceHeight, weather)
      else
        vented_attic_sla = vented_attic.vented_attic_sla
      end
    elsif not vented_attic.vented_attic_ach.nil?
      if hpxml_header.apply_ashrae140_assumptions
        vented_attic_const_ach = vented_attic.vented_attic_ach
      else
        vented_attic_sla = get_infiltration_SLA_from_ACH(vented_attic.vented_attic_ach, ReferenceHeight, ReferenceHeight, weather)
      end
    end

    space = spaces[HPXML::LocationAtticVented]
    if not vented_attic_sla.nil?
      vented_attic_area = UnitConversions.convert(space.floorArea, 'm^2', 'ft^2')
      hor_lk_frac = 0.75 # Same as Energy Gauge USA Attic Model
      neutral_level = 0.5 # DOE-2 Default
      sla = vented_attic_sla
      ela = sla * vented_attic_area
      c_w_SG, c_s_SG = calc_wind_stack_coeffs(hpxml_bldg, hor_lk_frac, neutral_level, HPXML::LocationAtticVented)
      apply_infiltration_to_unconditioned_space(model, space, nil, ela, c_w_SG, c_s_SG, duct_lk_imbals)
    elsif not vented_attic_const_ach.nil?
      ach = vented_attic_const_ach
      apply_infiltration_to_unconditioned_space(model, space, ach, nil, nil, nil, duct_lk_imbals)
    end
  end

  # Adds infiltration to the OpenStudio unvented attic space.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param duct_lk_imbals [Array] List of duct leakage imbalance information
  # @return [nil]
  def self.apply_infiltration_to_unvented_attic(model, spaces, duct_lk_imbals)
    return if spaces[HPXML::LocationAtticUnvented].nil?

    space = spaces[HPXML::LocationAtticUnvented]
    ach = UnventedSpaceACH
    apply_infiltration_to_unconditioned_space(model, space, ach, nil, nil, nil, duct_lk_imbals)
  end

  # Adds fan energy associated with the HPXML Local VentilationFan to an OpenStudio ElectricEquipment object.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param vent_fan [HPXML::VentilationFan] The HPXML VentilationFan of interest
  # @param obj_type [String] The type of ventilation fan
  # @param index [Integer] Index number of the current local ventilation fan
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @return [OpenStudio::Model::EnergyManagementSystemSensor] An EMS sensor for the newly created ventilation fan's schedule
  def self.apply_local_vent_fan_power(model, spaces, vent_fan, obj_type, index, unavailable_periods)
    daily_sch = [0.0] * 24
    obj_name = "#{obj_type} #{index}"
    remaining_hrs = vent_fan.hours_in_operation
    for hr in 1..(vent_fan.hours_in_operation.ceil)
      if remaining_hrs >= 1
        daily_sch[(vent_fan.start_hour + hr - 1) % 24] = 1.0
      else
        daily_sch[(vent_fan.start_hour + hr - 1) % 24] = remaining_hrs
      end
      remaining_hrs -= 1
    end
    obj_sch = HourlyByMonthSchedule.new(model, "#{obj_name} schedule", [daily_sch] * 12, [daily_sch] * 12, EPlus::ScheduleTypeLimitsFraction, false, unavailable_periods: unavailable_periods)
    obj_sch_sensor = Model.add_ems_sensor(
      model,
      name: "#{obj_name} sch s",
      output_var_or_meter_name: 'Schedule Value',
      key_name: obj_sch.schedule.name
    )

    Model.add_electric_equipment(
      model,
      name: obj_name,
      end_use: Constants::ObjectTypeMechanicalVentilation,
      space: spaces[HPXML::LocationConditionedSpace], # no heat gain, so assign the equipment to an arbitrary space
      design_level: vent_fan.fan_power * vent_fan.count,
      frac_radiant: 0,
      frac_latent: 0,
      frac_lost: 1,
      schedule: obj_sch.schedule
    )

    return obj_sch_sensor
  end

  # Adds the clothes dryer exhaust schedule to the OpenStudio model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param vented_dryer [HPXML::ClothesDryer] The HPXML Clothes Dryer of interest
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param index [Integer] Index number of the current vented clothes dryer
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @return [Array<OpenStudio::Model::EnergyManagementSystemSensor, Double>] Vented dryer schedule sensor, airflow multiplier
  def self.apply_dryer_exhaust(model, hpxml_header, vented_dryer, schedules_file, index, unavailable_periods)
    obj_name = "#{Constants::ObjectTypeClothesDryer} exhaust #{index}"

    # Create schedule
    obj_sch = nil
    if not schedules_file.nil?
      obj_sch_name = SchedulesFile::Columns[:ClothesDryer].name
      obj_sch = schedules_file.create_schedule_file(model, col_name: obj_sch_name)
      full_load_hrs = schedules_file.annual_equivalent_full_load_hrs(col_name: obj_sch_name)
    end
    if obj_sch.nil?
      cd_weekday_sch = vented_dryer.weekday_fractions
      cd_weekend_sch = vented_dryer.weekend_fractions
      cd_monthly_sch = vented_dryer.monthly_multipliers
      obj_sch = MonthWeekdayWeekendSchedule.new(model, obj_name + ' schedule', cd_weekday_sch, cd_weekend_sch, cd_monthly_sch, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: unavailable_periods)
      obj_sch = obj_sch.schedule
      obj_sch_name = obj_sch.name.to_s
      full_load_hrs = Schedule.annual_equivalent_full_load_hrs(hpxml_header.sim_calendar_year, obj_sch)
    end

    obj_sch_sensor = Model.add_ems_sensor(
      model,
      name: "#{obj_name} sch s",
      output_var_or_meter_name: 'Schedule Value',
      key_name: obj_sch_name
    )

    return obj_sch_sensor, 0 if full_load_hrs == 0

    # Assume standard dryer exhaust runs 1 hr/day per BA HSP
    cfm_mult = Calendar.num_days_in_year(hpxml_header.sim_calendar_year) * vented_dryer.usage_multiplier / full_load_hrs

    return obj_sch_sensor, cfm_mult
  end

  # Returns the sensible, latent, and apparent sensible effectiveness for each ERV/HRV.
  #
  # @param vent_mech_fans [Array<HPXML::VentilationFan>] List of HPXML Mechanical VentilationFans of type ERV/HRV
  # @return [Hash] Map of HPXML VentilationFan => Hash of effectiveness values
  def self.calc_hrv_erv_effectiveness(vent_mech_fans)
    hrv_erv_effectiveness_map = {}
    p_atm = UnitConversions.convert(1.0, 'atm', 'psi')
    vent_mech_fans.each do |vent_mech|
      hrv_erv_effectiveness_map[vent_mech] = {}

      vent_mech_cfm = vent_mech.average_oa_unit_flow_rate
      if (vent_mech_cfm > 0)
        # Must assume an operating condition (HVI seems to use CSA 439)
        t_sup_in = 0.0
        w_sup_in = 0.0028
        t_exh_in = 22.0
        # w_exh_in = 0.0065
        cp_a = 1006.0
        p_fan = vent_mech.average_unit_fan_power # Watts

        m_fan = UnitConversions.convert(vent_mech_cfm, 'cfm', 'm^3/s') * UnitConversions.convert(Psychrometrics.rhoD_fT_w_P(UnitConversions.convert(t_sup_in, 'C', 'F'), w_sup_in, p_atm), 'lbm/ft^3', 'kg/m^3') # kg/s

        if not vent_mech.sensible_recovery_efficiency.nil?
          # The following is derived from CSA 439, Clause 9.3.3.1, Eq. 12:
          #    E_SHR = (m_sup,fan * Cp * (Tsup,out - Tsup,in) - P_sup,fan) / (m_exh,fan * Cp * (Texh,in - Tsup,in) + P_exh,fan)
          t_sup_out = t_sup_in + (vent_mech.sensible_recovery_efficiency * (m_fan * cp_a * (t_exh_in - t_sup_in) + p_fan) + p_fan) / (m_fan * cp_a)

          # Calculate the apparent sensible effectiveness
          vent_mech_apparent_sens_eff = (t_sup_out - t_sup_in) / (t_exh_in - t_sup_in)

        else
          # The following is derived from (taken from CSA 439, Clause 9.2.1, Eq. 7):
          t_sup_out = t_sup_in + (vent_mech.sensible_recovery_efficiency_adjusted * (t_exh_in - t_sup_in))

          vent_mech_apparent_sens_eff = vent_mech.sensible_recovery_efficiency_adjusted

        end

        # Calculate the supply temperature before the fan
        t_sup_out_gross = t_sup_out - p_fan / (m_fan * cp_a)

        # Sensible effectiveness of the HX only
        vent_mech_sens_eff = (t_sup_out_gross - t_sup_in) / (t_exh_in - t_sup_in)

        if (vent_mech_sens_eff < 0.0) || (vent_mech_sens_eff > 1.0)
          fail "The calculated ERV/HRV sensible effectiveness is #{vent_mech_sens_eff} but should be between 0 and 1. Please revise ERV/HRV efficiency values."
        end

        # Use summer test condition to determine the latent effectiveness since TRE is generally specified under the summer condition
        if (not vent_mech.total_recovery_efficiency.nil?) || (not vent_mech.total_recovery_efficiency_adjusted.nil?)

          t_sup_in = 35.0
          w_sup_in = 0.0178
          t_exh_in = 24.0
          w_exh_in = 0.0092

          m_fan = UnitConversions.convert(vent_mech_cfm, 'cfm', 'm^3/s') * UnitConversions.convert(Psychrometrics.rhoD_fT_w_P(UnitConversions.convert(t_sup_in, 'C', 'F'), w_sup_in, p_atm), 'lbm/ft^3', 'kg/m^3') # kg/s

          t_sup_out_gross = t_sup_in - vent_mech_sens_eff * (t_sup_in - t_exh_in)
          t_sup_out = t_sup_out_gross + p_fan / (m_fan * cp_a)

          h_sup_in = Psychrometrics.h_fT_w_SI(t_sup_in, w_sup_in)
          h_exh_in = Psychrometrics.h_fT_w_SI(t_exh_in, w_exh_in)

          if not vent_mech.total_recovery_efficiency.nil?
            # The following is derived from CSA 439, Clause 9.3.3.2, Eq. 13:
            #    E_THR = (m_sup,fan * Cp * (h_sup,out - h_sup,in) - P_sup,fan) / (m_exh,fan * Cp * (h_exh,in - h_sup,in) + P_exh,fan)
            h_sup_out = h_sup_in - (vent_mech.total_recovery_efficiency * (m_fan * (h_sup_in - h_exh_in) + p_fan) + p_fan) / m_fan
          else
            # The following is derived from (taken from CSA 439, Clause 9.2.1, Eq. 7):
            h_sup_out = h_sup_in - (vent_mech.total_recovery_efficiency_adjusted * (h_sup_in - h_exh_in))
          end

          w_sup_out = Psychrometrics.w_fT_h_SI(t_sup_out, h_sup_out)
          vent_mech_lat_eff = [0.0, (w_sup_out - w_sup_in) / (w_exh_in - w_sup_in)].max

          if (vent_mech_lat_eff < 0.0) || (vent_mech_lat_eff > 1.0)
            fail "The calculated ERV/HRV latent effectiveness is #{vent_mech_lat_eff} but should be between 0 and 1. Please revise ERV/HRV efficiency values."
          end

        else
          vent_mech_lat_eff = 0.0
        end
      else
        vent_mech_apparent_sens_eff = 0.0
        vent_mech_sens_eff = 0.0
        vent_mech_lat_eff = 0.0
      end

      hrv_erv_effectiveness_map[vent_mech][:vent_mech_sens_eff] = vent_mech_sens_eff
      hrv_erv_effectiveness_map[vent_mech][:vent_mech_lat_eff] = vent_mech_lat_eff
      hrv_erv_effectiveness_map[vent_mech][:vent_mech_apparent_sens_eff] = vent_mech_apparent_sens_eff
    end
    return hrv_erv_effectiveness_map
  end

  # Updates the EMS program to add CFIS airflow and fan energy calculations.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param infil_program [OpenStudio::Model::EnergyManagementSystemProgram] EMS program for the infiltration calculations
  # @param vent_mech_fans [Array<HPXML::VentilationFan>] List of HPXML Mechanical VentilationFans
  # @param cfis_data [Hash] Map with various CFIS-relative OpenStudio model objects
  # @param cfis_fan_actuator [OpenStudio::Model::EnergyManagementSystemActuator] EMS actuator to the CFIS's ElectricEquipment object
  # @param cfis_suppl_fan_actuator [OpenStudio::Model::EnergyManagementSystemActuator] EMS actuator to the CFIS supplemental fan's ElectricEquipment object
  # @param fan_data [Hash] Map of HVAC blower fan properties => values
  # @return [nil]
  def self.apply_cfis(runner, infil_program, vent_mech_fans, cfis_data, cfis_fan_actuator, cfis_suppl_fan_actuator, fan_data)
    infil_program.addLine("Set #{cfis_fan_actuator.name} = 0.0")
    infil_program.addLine("Set #{cfis_suppl_fan_actuator.name} = 0.0") unless cfis_suppl_fan_actuator.nil?
    infil_program.addLine('Set QWHV_cfis_sup = 0.0') # CFIS supply outdoor airflow rate
    infil_program.addLine('Set QWHV_cfis_suppl_sup = 0.0') # CFIS supplemental fan supply outdoor airflow rate
    infil_program.addLine('Set QWHV_cfis_suppl_exh = 0.0') # CFIS supplemental fan exhaust outdoor airflow rate

    vent_mech_fans.each do |vent_mech|
      infil_program.addLine('Set fan_rtf_hvac = 0')
      object = cfis_data[:airloop][vent_mech.id]
      fan_data[:rtf_sensor][object].each do |rtf_sensor|
        infil_program.addLine("Set fan_rtf_hvac = fan_rtf_hvac + #{rtf_sensor.name}")
      end

      sum_oa_cfm_var = cfis_data[:sum_oa_cfm_var][vent_mech.id]
      f_vent_only_mode_var = cfis_data[:f_vent_only_mode_var][vent_mech.id]

      infil_program.addLine("Set f_operation = #{[vent_mech.hours_in_operation / 24.0, 0.0001].max}") # Operation, fraction of hour
      infil_program.addLine("Set oa_cfm_ah = #{UnitConversions.convert(vent_mech.oa_unit_flow_rate, 'cfm', 'm^3/s')}")
      infil_program.addLine('Set oa_cfm_ah = @Max oa_cfm_ah 0.00001') # Fix for https://github.com/NREL/OpenStudio-HPXML/issues/2072

      case vent_mech.cfis_addtl_runtime_operating_mode
      when HPXML::CFISModeSupplementalFan
        if vent_mech.cfis_supplemental_fan.oa_unit_flow_rate < vent_mech.average_unit_flow_rate
          runner.registerWarning("CFIS supplemental fan '#{vent_mech.cfis_supplemental_fan.id}' is undersized (#{vent_mech.cfis_supplemental_fan.oa_unit_flow_rate} cfm) compared to the target hourly ventilation rate (#{vent_mech.average_unit_flow_rate} cfm).")
        end
        infil_program.addLine("Set suppl_fan_w = #{vent_mech.cfis_supplemental_fan.unit_fan_power}") # W, supplemental fan power
        infil_program.addLine("Set oa_cfm_suppl = #{UnitConversions.convert(vent_mech.cfis_supplemental_fan.oa_unit_flow_rate, 'cfm', 'm^3/s')}")
      when HPXML::CFISModeAirHandler
        infil_program.addLine("Set ah_fan_w = #{vent_mech.unit_fan_power}") # W, air handler fan power
      end
      infil_program.addLine("Set has_outdoor_air_control = #{vent_mech.cfis_has_outdoor_air_control ? 1 : 0}")

      case vent_mech.cfis_control_type
      when HPXML::CFISControlTypeTimer
        # Ventilation occurs at fixed intervals regardless of HVAC operation

        # Calculate outdoor air ventilation
        infil_program.addLine('Set QWHV_cfis_sup = QWHV_cfis_sup + (oa_cfm_ah * f_operation)')

        # Calculate fraction of the timestep with ventilation only mode runtime per ANSI/RESNET/ICC 301-2022 Addendum E
        infil_program.addLine("Set #{f_vent_only_mode_var.name} = f_operation * (1 - fan_rtf_hvac)")

        # Calculate additional fan energy
        infil_program.addLine("Set #{cfis_fan_actuator.name} = #{cfis_fan_actuator.name} + (ah_fan_w * #{f_vent_only_mode_var.name})")

      when HPXML::CFISControlTypeOptimized
        # Ventilation optimized to make use of HVAC operation

        infil_program.addLine("Set #{f_vent_only_mode_var.name} = 0")
        infil_program.addLine('If @ABS(Minute - ZoneTimeStep*60) < 0.1')
        infil_program.addLine("  Set #{sum_oa_cfm_var.name} = 0") # New hour, re-initialize to 0
        infil_program.addLine('EndIf')

        # Calculate hourly-average target outdoor air ventilation
        infil_program.addLine('Set hr_oa_cfm_target = f_operation * oa_cfm_ah')

        # Calculate hourly-average outdoor air ventilation still needed for the hour
        infil_program.addLine("Set hr_oa_cfm_needed = hr_oa_cfm_target - #{sum_oa_cfm_var.name}")

        # Calculate hourly-average available outdoor air ventilation during HVAC runtime
        infil_program.addLine('Set hr_oa_cfm_during_hvac_avail = fan_rtf_hvac * oa_cfm_ah * ZoneTimestep')

        # Calculate hourly-average actual outdoor air ventilation brought in during HVAC runtime
        if vent_mech.cfis_has_outdoor_air_control
          infil_program.addLine('Set hr_oa_cfm_during_hvac = @Min hr_oa_cfm_during_hvac_avail hr_oa_cfm_needed')
        else
          # Outdoor air is introduced for the entire time the HVAC system is running
          infil_program.addLine('Set hr_oa_cfm_during_hvac = hr_oa_cfm_during_hvac_avail')
        end
        infil_program.addLine('Set QWHV_cfis_sup = QWHV_cfis_sup + (hr_oa_cfm_during_hvac / ZoneTimestep)')
        infil_program.addLine("Set #{sum_oa_cfm_var.name} = #{sum_oa_cfm_var.name} + hr_oa_cfm_during_hvac")

        # If specified, additionally run supplemental fan when ventilating during HVAC runtime
        if vent_mech.cfis_addtl_runtime_operating_mode == HPXML::CFISModeSupplementalFan && vent_mech.cfis_supplemental_fan_runs_with_air_handler_fan
          infil_program.addLine('If hr_oa_cfm_during_hvac > 0')
          infil_program.addLine('  Set f_open_damper_ah = (hr_oa_cfm_during_hvac / hr_oa_cfm_during_hvac_avail) * fan_rtf_hvac')
          infil_program.addLine("  Set #{cfis_suppl_fan_actuator.name} = #{cfis_suppl_fan_actuator.name} + (suppl_fan_w * f_open_damper_ah)")
          case vent_mech.cfis_supplemental_fan.fan_type
          when HPXML::MechVentTypeSupply
            infil_program.addLine('  Set QWHV_cfis_suppl_sup = QWHV_cfis_suppl_sup + (f_open_damper_ah * oa_cfm_suppl)')
          when HPXML::MechVentTypeExhaust
            infil_program.addLine('  Set QWHV_cfis_suppl_exh = QWHV_cfis_suppl_exh + (f_open_damper_ah * oa_cfm_suppl)')
          end
          infil_program.addLine('EndIf')
        end

        # Calculate hourly-average additional outdoor air ventilation still needed for the hour after HVAC runtime
        infil_program.addLine('Set hr_oa_cfm_addtl_needed = hr_oa_cfm_needed - hr_oa_cfm_during_hvac')

        # Calculate hourly-average outdoor air ventilation that can be brought in during subsequent timesteps of the hour if needed
        case vent_mech.cfis_addtl_runtime_operating_mode
        when HPXML::CFISModeAirHandler
          infil_program.addLine('Set hr_oa_cfm_addtl_needed = hr_oa_cfm_addtl_needed - (((60 - Minute) / 60) * oa_cfm_ah)')
        when HPXML::CFISModeSupplementalFan
          infil_program.addLine('Set hr_oa_cfm_addtl_needed = hr_oa_cfm_addtl_needed - (((60 - Minute) / 60) * oa_cfm_suppl)')
        when HPXML::CFISModeNone
          infil_program.addLine('Set hr_oa_cfm_addtl_needed = 0')
        end
        infil_program.addLine('If hr_oa_cfm_addtl_needed > 0')

        case vent_mech.cfis_addtl_runtime_operating_mode
        when HPXML::CFISModeAirHandler
          # Air handler meets additional runtime requirement

          # Calculate hourly-average available outdoor air ventilation during non-HVAC runtime
          infil_program.addLine('  Set hr_oa_cfm_during_non_hvac_avail = (1.0 - fan_rtf_hvac) * oa_cfm_ah * ZoneTimestep')

          # Calculate hourly-average actual outdoor air ventilation brought in during non-HVAC runtime
          infil_program.addLine('  Set hr_oa_cfm_during_non_hvac = @Min hr_oa_cfm_during_non_hvac_avail hr_oa_cfm_addtl_needed')
          infil_program.addLine('  Set QWHV_cfis_sup = QWHV_cfis_sup + (hr_oa_cfm_during_non_hvac / ZoneTimestep)')
          infil_program.addLine("  Set #{sum_oa_cfm_var.name} = #{sum_oa_cfm_var.name} + hr_oa_cfm_during_non_hvac")

          # Calculate fraction of the timestep with ventilation only mode runtime and additional fan energy
          infil_program.addLine('  If hr_oa_cfm_during_non_hvac > 0')
          infil_program.addLine("    Set #{f_vent_only_mode_var.name} = (hr_oa_cfm_during_non_hvac / hr_oa_cfm_during_non_hvac_avail) * (1.0 - fan_rtf_hvac)")
          infil_program.addLine("    Set #{cfis_fan_actuator.name} = #{cfis_fan_actuator.name} + (ah_fan_w * #{f_vent_only_mode_var.name})")
          infil_program.addLine('  EndIf')

        when HPXML::CFISModeSupplementalFan
          # Supplemental fan meets additional runtime requirement

          # Calculate hourly-average available outdoor air ventilation during non-HVAC runtime
          infil_program.addLine('  Set hr_oa_cfm_during_non_hvac_avail = (1.0 - fan_rtf_hvac) * oa_cfm_suppl * ZoneTimestep')

          # Calculate hourly-average actual outdoor air ventilation brought in during non-HVAC runtime
          infil_program.addLine('  Set hr_oa_cfm_during_non_hvac = @Min hr_oa_cfm_during_non_hvac_avail hr_oa_cfm_addtl_needed')
          case vent_mech.cfis_supplemental_fan.fan_type
          when HPXML::MechVentTypeSupply
            infil_program.addLine('  Set QWHV_cfis_suppl_sup = QWHV_cfis_suppl_sup + (hr_oa_cfm_during_non_hvac / ZoneTimestep)')
          when HPXML::MechVentTypeExhaust
            infil_program.addLine('  Set QWHV_cfis_suppl_exh = QWHV_cfis_suppl_exh + (hr_oa_cfm_during_non_hvac / ZoneTimestep)')
          end
          infil_program.addLine("  Set #{sum_oa_cfm_var.name} = #{sum_oa_cfm_var.name} + hr_oa_cfm_during_non_hvac")

          # Calculate fraction of the timestep with ventilation only mode runtime and additional fan energy
          infil_program.addLine('  If hr_oa_cfm_during_non_hvac > 0')
          infil_program.addLine("    Set #{f_vent_only_mode_var.name} = (hr_oa_cfm_during_non_hvac / hr_oa_cfm_during_non_hvac_avail) * (1.0 - fan_rtf_hvac)")
          infil_program.addLine("    Set #{cfis_suppl_fan_actuator.name} = #{cfis_suppl_fan_actuator.name} + (suppl_fan_w * #{f_vent_only_mode_var.name})")
          infil_program.addLine('  EndIf')
        end

        infil_program.addLine('EndIf')
      end
    end
  end

  # Adds fan power associated with the HPXML Mechanical VentilationFan to an OpenStudio ElectricEquipment object.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param obj_name [String] Name for the OpenStudio object
  # @param sup_fans [Array<HPXML::VentilationFan>] List of supply-only HPXML Mechanical VentilationFans
  # @param exh_fans [Array<HPXML::VentilationFan>] List of exhaust-only HPXML MechanicalVentilationFans
  # @param bal_fans [Array<HPXML::VentilationFan>] List of balanced HPXML MechanicalVentilationFans without heat/energy recovery
  # @param erv_hrv_fans [Array<HPXML::VentilationFan>] List of balanced HPXML MechanicalVentilationFans with heat/energy recovery
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @return [OpenStudio::Model::EnergyManagementSystemActuator] EMS actuator for the newly created ElectricEquipment object
  def self.add_mech_vent_fan_power(model, spaces, obj_name, sup_fans = [], exh_fans = [], bal_fans = [], erv_hrv_fans = [], unavailable_periods = [])
    # Calculate fan heat fraction
    # 1.0: Fan heat does not enter space (e.g., exhaust)
    # 0.0: Fan heat does enter space (e.g., supply)
    if obj_name == Constants::ObjectTypeMechanicalVentilationHouseFanCFIS
      fan_heat_lost_fraction = 0.0
    else
      # Calculate total fan power
      if obj_name == Constants::ObjectTypeMechanicalVentilationHouseFanCFISSupplFan
        sup_fans_w = sup_fans.map { |f| f.unit_fan_power }.sum(0.0)
        exh_fans_w = exh_fans.map { |f| f.unit_fan_power }.sum(0.0)
        bal_fans_w = (bal_fans + erv_hrv_fans).map { |f| f.unit_fan_power }.sum(0.0)
      else
        sup_fans_w = sup_fans.map { |f| f.average_unit_fan_power }.sum(0.0)
        exh_fans_w = exh_fans.map { |f| f.average_unit_fan_power }.sum(0.0)
        bal_fans_w = (bal_fans + erv_hrv_fans).map { |f| f.average_unit_fan_power }.sum(0.0)
      end
      tot_fans_w = sup_fans_w + exh_fans_w + bal_fans_w

      # Calculate weighted-average value
      if tot_fans_w > 0.0
        fan_heat_lost_fraction = (1.0 * exh_fans_w + 0.0 * sup_fans_w + 0.5 * bal_fans_w) / tot_fans_w
      else
        fan_heat_lost_fraction = 1.0
      end
    end

    # Availability Schedule
    avail_sch = ScheduleConstant.new(model, obj_name + ' schedule', 1.0, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: unavailable_periods)

    equip = Model.add_electric_equipment(
      model,
      name: obj_name,
      end_use: Constants::ObjectTypeMechanicalVentilation,
      space: spaces[HPXML::LocationConditionedSpace],
      design_level: tot_fans_w,
      frac_radiant: 0,
      frac_latent: 0,
      frac_lost: fan_heat_lost_fraction,
      schedule: avail_sch.schedule
    )

    equip_actuator = nil
    if [Constants::ObjectTypeMechanicalVentilationHouseFanCFIS,
        Constants::ObjectTypeMechanicalVentilationHouseFanCFISSupplFan].include? obj_name # actuate its power level in EMS
      equip_actuator = Model.add_ems_actuator(
        name: "#{equip.name} act",
        model_object: equip,
        comp_type_and_control: EPlus::EMSActuatorElectricEquipmentPower
      )
    end

    return equip_actuator
  end

  # Initialize EMS program and actuators for mechanical ventilation calculations.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param infil_program [OpenStudio::Model::EnergyManagementSystemProgram] EMS program for the infiltration calculations
  # @param sensors [Hash] Map of :sensor_types => OpenStudio::Model::EnergyManagementSystemSensor objects
  # @return [Array<OpenStudio::Model::EnergyManagementSystemActuator, OpenStudio::Model::EnergyManagementSystemActuator>] EMS actuators for sensible and latent loads
  def self.initialize_mech_vent(model, spaces, infil_program, sensors)
    conditioned_space = spaces[HPXML::LocationConditionedSpace]

    # Actuators for mech vent fan
    sens_equip = Model.add_other_equipment(
      model,
      name: "#{Constants::ObjectTypeMechanicalVentilationHouseFan} sensible load",
      end_use: Constants::ObjectTypeMechanicalVentilationHouseFan,
      space: conditioned_space,
      design_level: nil,
      frac_radiant: 0,
      frac_latent: 0,
      frac_lost: 0,
      schedule: model.alwaysOnDiscreteSchedule,
      fuel_type: nil
    )

    fan_sens_load_actuator = Model.add_ems_actuator(
      name: "#{sens_equip.name} act",
      model_object: sens_equip,
      comp_type_and_control: EPlus::EMSActuatorOtherEquipmentPower
    )

    lat_equip = Model.add_other_equipment(
      model,
      name: "#{Constants::ObjectTypeMechanicalVentilationHouseFan} latent load",
      end_use: Constants::ObjectTypeMechanicalVentilationHouseFan,
      space: conditioned_space,
      design_level: nil,
      frac_radiant: 0,
      frac_latent: 1,
      frac_lost: 0,
      schedule: model.alwaysOnDiscreteSchedule,
      fuel_type: nil
    )

    fan_lat_load_actuator = Model.add_ems_actuator(
      name: "#{lat_equip.name} act",
      model_object: lat_equip,
      comp_type_and_control: EPlus::EMSActuatorOtherEquipmentPower
    )

    infil_program.addLine("Set #{fan_sens_load_actuator.name} = 0.0")
    infil_program.addLine("Set #{fan_lat_load_actuator.name} = 0.0")

    # Air property at inlet nodes on both sides
    infil_program.addLine("Set OASupInPb = #{sensors[:pbar].name}") # oa barometric pressure
    infil_program.addLine("Set OASupInTemp = #{sensors[:t_out].name}") # oa db temperature
    infil_program.addLine("Set OASupInW = #{sensors[:w_out].name}") # oa humidity ratio
    infil_program.addLine('Set OASupRho = (@RhoAirFnPbTdbW OASupInPb OASupInTemp OASupInW)')
    infil_program.addLine('Set OASupCp = (@CpAirFnW OASupInW)')
    infil_program.addLine('Set OASupInEnth = (@HFnTdbW OASupInTemp OASupInW)')

    infil_program.addLine("Set ZoneTemp = #{sensors[:t_in].name}") # zone air temperature
    infil_program.addLine("Set ZoneW = #{sensors[:w_in].name}") # zone air humidity ratio
    infil_program.addLine('Set ZoneCp = (@CpAirFnW ZoneW)')
    infil_program.addLine('Set ZoneAirEnth = (@HFnTdbW ZoneTemp ZoneW)')

    return fan_sens_load_actuator, fan_lat_load_actuator
  end

  # Updates the infiltration EMS program to calculate the adjusted infiltration (total air exchange minus
  # ventilation airflow), which is assigned to the OpenStudio model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param infil_program [OpenStudio::Model::EnergyManagementSystemProgram] EMS program for the infiltration calculations
  # @param vent_fans [Hash] Map of vent fan types => list of HPXML VentilationFans
  # @param duct_lk_imbals [Array] List of duct leakage imbalance information
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def self.apply_infiltration_adjustment_to_conditioned(runner, model, spaces, hpxml_bldg, hpxml_header, infil_program, vent_fans, duct_lk_imbals, schedules_file)
    conditioned_space = spaces[HPXML::LocationConditionedSpace]
    conditioned_zone = conditioned_space.thermalZone.get
    unit_multiplier = hpxml_bldg.building_construction.number_of_units

    infil_flow = Model.add_infiltration_flow_rate(
      model,
      name: "#{Constants::ObjectTypeInfiltration} flow",
      space: spaces[HPXML::LocationConditionedSpace],
      ach: nil
    )

    infil_flow_actuator = Model.add_ems_actuator(
      name: "#{infil_flow.name} act",
      model_object: infil_flow,
      comp_type_and_control: EPlus::EMSActuatorZoneInfiltrationFlowRate
    )
    infil_flow.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeInfiltration)

    # Average in-unit CFMs (include recirculation from in unit CFMs for shared systems)
    sup_cfm_tot = vent_fans[:mech_supply].map { |vent_mech| vent_mech.average_unit_flow_rate }.sum(0.0)
    exh_cfm_tot = vent_fans[:mech_exhaust].map { |vent_mech| vent_mech.average_unit_flow_rate }.sum(0.0)
    bal_cfm_tot = vent_fans[:mech_balanced].map { |vent_mech| vent_mech.average_unit_flow_rate }.sum(0.0)
    erv_hrv_cfm_tot = vent_fans[:mech_erv_hrv].map { |vent_mech| vent_mech.average_unit_flow_rate }.sum(0.0)

    # Handle any cooking range hood ventilation
    infil_program.addLine('Set Qrange = 0')
    cooking_range_in_cond_space = hpxml_bldg.cooking_ranges.empty? ? true : HPXML::conditioned_locations_this_unit.include?(hpxml_bldg.cooking_ranges[0].location)
    vent_fans[:kitchen].each_with_index do |vent_kitchen, index|
      # Electricity impact
      vent_kitchen_unavailable_periods = Schedule.get_unavailable_periods(runner, SchedulesFile::Columns[:KitchenFan].name, hpxml_header.unavailable_periods)
      obj_sch_sensor = apply_local_vent_fan_power(model, spaces, vent_kitchen, Constants::ObjectTypeMechanicalVentilationRangeFan, index, vent_kitchen_unavailable_periods)
      next unless cooking_range_in_cond_space

      # Infiltration impact
      infil_program.addLine("Set Qrange = Qrange + #{UnitConversions.convert(vent_kitchen.flow_rate * vent_kitchen.count, 'cfm', 'm^3/s').round(5)} * #{obj_sch_sensor.name}")
    end

    # Handle any bathroom fan ventilation
    infil_program.addLine('Set Qbath = 0')
    vent_fans[:bath].each_with_index do |vent_bath, index|
      # Electricity impact
      vent_bath_unavailable_periods = Schedule.get_unavailable_periods(runner, SchedulesFile::Columns[:BathFan].name, hpxml_header.unavailable_periods)
      obj_sch_sensor = apply_local_vent_fan_power(model, spaces, vent_bath, Constants::ObjectTypeMechanicalVentilationBathFan, index, vent_bath_unavailable_periods)

      # Infiltration impact
      infil_program.addLine("Set Qbath = Qbath + #{UnitConversions.convert(vent_bath.flow_rate * vent_bath.count, 'cfm', 'm^3/s').round(5)} * #{obj_sch_sensor.name}")
    end

    # Handle any clothes dryer venting
    infil_program.addLine('Set Qdryer = 0')
    vented_dryers_in_cond_space = hpxml_bldg.clothes_dryers.select { |cd| cd.is_vented && cd.vented_flow_rate.to_f > 0 && HPXML::conditioned_locations_this_unit.include?(cd.location) }
    vented_dryers_in_cond_space.each_with_index do |vented_dryer, index|
      next if hpxml_bldg.building_occupancy.number_of_residents == 0 # Operational calculation w/ zero occupants, zero out energy use

      # Infiltration impact
      vented_dryer_unavailable_periods = Schedule.get_unavailable_periods(runner, SchedulesFile::Columns[:ClothesDryer].name, hpxml_header.unavailable_periods)
      obj_sch_sensor, cfm_mult = apply_dryer_exhaust(model, hpxml_header, vented_dryer, schedules_file, index, vented_dryer_unavailable_periods)
      infil_program.addLine("Set Qdryer = Qdryer + #{UnitConversions.convert(vented_dryer.vented_flow_rate * cfm_mult, 'cfm', 'm^3/s').round(5)} * #{obj_sch_sensor.name}")
    end

    # Handle any HPWHs
    infil_program.addLine('Set Qhpwh = 0')
    ducted_hpwhs_in_cond_space = hpxml_bldg.water_heating_systems.select { |wh| wh.water_heater_type == HPXML::WaterHeaterTypeHeatPump && wh.hpwh_ducting_exhaust == HPXML::LocationOutside && HPXML::conditioned_locations_this_unit.include?(wh.location) }
    ducted_hpwhs_in_cond_space.each_with_index do |ducted_hpwh, i|
      # Create sensor to get HPWH airflow rate
      hpwh = model.getWaterHeaterHeatPumpWrappedCondensers.find { |h| h.additionalProperties.getFeatureAsString('HPXML_ID').to_s == ducted_hpwh.id }
      hpwh_flow_rate = Model.add_ems_sensor(
        model,
        name: "hpwh_flow_rate_#{i}",
        output_var_or_meter_name: 'System Node Current Density Volume Flow Rate',
        key_name: hpwh.airOutletNodeName
      )

      infil_program.addLine("Set Qhpwh = Qhpwh + #{hpwh_flow_rate.name} / #{unit_multiplier}")
    end

    infil_program.addLine("Set QWHV_sup = #{UnitConversions.convert(sup_cfm_tot + bal_cfm_tot + erv_hrv_cfm_tot, 'cfm', 'm^3/s').round(5)}")
    infil_program.addLine("Set QWHV_exh = #{UnitConversions.convert(exh_cfm_tot + bal_cfm_tot + erv_hrv_cfm_tot, 'cfm', 'm^3/s').round(5)}")

    # Ventilation fans
    infil_program.addLine('Set Qsupply = QWHV_sup + QWHV_cfis_sup + QWHV_cfis_suppl_sup')
    infil_program.addLine('Set Qexhaust = Qrange + Qbath + Qdryer + Qhpwh + QWHV_exh + QWHV_cfis_suppl_exh')
    infil_program.addLine('Set Qfan = (@Max Qexhaust Qsupply)')

    # Duct leakage imbalance induced infiltration
    infil_program.addLine('Set Qducts = 0')
    duct_lk_imbals.each do |values|
      duct_location, duct_lk_supply_fan_equiv_var, duct_lk_exhaust_fan_equiv_var = values
      next if duct_location != conditioned_zone.name.to_s

      infil_program.addLine("Set Qducts = Qducts - #{duct_lk_supply_fan_equiv_var.name}")
      infil_program.addLine("Set Qducts = Qducts + #{duct_lk_exhaust_fan_equiv_var.name}")
    end
    infil_program.addLine('If Qducts < 0')
    infil_program.addLine('  Set Qsupply = Qsupply - Qducts')
    infil_program.addLine('Else')
    infil_program.addLine('  Set Qexhaust = Qexhaust + Qducts')
    infil_program.addLine('EndIf')
    infil_program.addLine('Set Qfan_with_ducts = (@Max Qexhaust Qsupply)')

    # Total combined air exchange
    if Constants::ERIVersions.index(hpxml_header.eri_calculation_versions[0]) >= Constants::ERIVersions.index('2022')
      infil_program.addLine('Set Qimb = (@Abs (Qsupply - Qexhaust))')
      infil_program.addLine('If Qinf + Qimb > 0')
      infil_program.addLine('  Set Qtot = Qfan_with_ducts + (Qinf^2) / (Qinf + Qimb)')
      infil_program.addLine('Else')
      infil_program.addLine('  Set Qtot = Qfan_with_ducts')
      infil_program.addLine('EndIf')
    elsif Constants::ERIVersions.index(hpxml_header.eri_calculation_versions[0]) >= Constants::ERIVersions.index('2019')
      # Follow ASHRAE 62.2-2016, Normative Appendix C equations for time-varying total airflow
      infil_program.addLine('If Qfan_with_ducts > 0')
      # Balanced system if the total supply airflow and total exhaust airflow are within 10% of their average.
      infil_program.addLine('  Set Qavg = ((Qexhaust + Qsupply) / 2.0)')
      infil_program.addLine('  If ((@Abs (Qexhaust - Qavg)) / Qavg) <= 0.1') # Only need to check Qexhaust, Qsupply will give same result
      infil_program.addLine('    Set phi = 1')
      infil_program.addLine('  Else')
      infil_program.addLine('    Set phi = (Qinf / (Qinf + Qfan_with_ducts))')
      infil_program.addLine('  EndIf')
      infil_program.addLine('  Set Qtot = Qfan_with_ducts + (phi * Qinf)')
      infil_program.addLine('Else')
      infil_program.addLine('  Set Qtot = Qfan_with_ducts + Qinf')
      infil_program.addLine('EndIf')
    else
      infil_program.addLine('Set Qimb = (@Abs (Qexhaust - Qsupply))') # Unbalanced flow
      infil_program.addLine('Set Qbal = Qfan_with_ducts - Qimb') # Balanced flow
      infil_program.addLine('Set Qtot = (((Qimb^2) + (Qinf^2)) ^ 0.5) + Qbal')
    end

    # Natural infiltration and duct leakage imbalance induced infiltration
    infil_program.addLine('Set Qinf_adj = Qtot - Qfan')
    infil_program.addLine("Set #{infil_flow_actuator.name} = Qinf_adj")

    # EMS global variables for output reporting
    q_inf_var = Model.add_ems_global_var(
      model,
      var_name: "#{infil_program.name} Qinf"
    )
    q_fan_var = Model.add_ems_global_var(
      model,
      var_name: "#{infil_program.name} Qfan"
    )
    q_inf_var.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeInfiltration)
    q_fan_var.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeMechanicalVentilation)
    infil_program.addLine("Set #{q_inf_var.name} = Qinf_adj")
    infil_program.addLine("Set #{q_fan_var.name} = Qfan")
  end

  # Updates the infiltration EMS program to calculate the mechanical ventilation sensible/latent loads.
  #
  # @param infil_program [OpenStudio::Model::EnergyManagementSystemProgram] EMS program for the infiltration calculations
  # @param vent_mech_fans [Array<HPXML::VentilationFan>] List of HPXML Mechanical VentilationFans of type ERV/HRV
  # @param hrv_erv_effectiveness_map [Hash] Map of HPXML VentilationFan => Hash of effectiveness values
  # @param fan_sens_load_actuator [OpenStudio::Model::EnergyManagementSystemActuator] EMS actuators for sensible load
  # @param fan_lat_load_actuator [OpenStudio::Model::EnergyManagementSystemActuator] EMS actuators for latent load
  # @param q_var [String] Name of the EMS variable with the mechanical ventilation airflow rate
  # @param preconditioned [Boolean] Whether loads are being calculated for a pre-heating/pre-cooling ventilation system
  # @return [nil]
  def self.calculate_fan_loads(infil_program, vent_mech_fans, hrv_erv_effectiveness_map, fan_sens_load_actuator, fan_lat_load_actuator, q_var, preconditioned = false)
    # Variables for combined effectiveness
    infil_program.addLine('Set Effectiveness_Sens = 0.0')
    infil_program.addLine('Set Effectiveness_Lat = 0.0')

    # Calculate mass flow rate based on outdoor air density
    # Address load with flow-weighted combined effectiveness
    infil_program.addLine("Set Fan_MFR = #{q_var} * OASupRho")
    infil_program.addLine('Set ZoneInEnth = OASupInEnth')
    infil_program.addLine('Set ZoneInTemp = OASupInTemp')
    if not vent_mech_fans.empty?
      # ERV/HRV EMS load model
      # E+ ERV model is using standard density for MFR calculation, caused discrepancy with other system types.
      # Therefore ERV is modeled within EMS infiltration program
      infil_program.addLine("If #{q_var} > 0")
      vent_mech_fans.each do |vent_fan|
        sens_eff = hrv_erv_effectiveness_map[vent_fan][:vent_mech_sens_eff]
        lat_eff = hrv_erv_effectiveness_map[vent_fan][:vent_mech_lat_eff]
        avg_oa_m3s = UnitConversions.convert(vent_fan.average_oa_unit_flow_rate, 'cfm', 'm^3/s').round(4)
        infil_program.addLine("  Set Effectiveness_Sens = Effectiveness_Sens + #{avg_oa_m3s} / #{q_var} * #{sens_eff}")
        infil_program.addLine("  Set Effectiveness_Lat = Effectiveness_Lat + #{avg_oa_m3s} / #{q_var} * #{lat_eff}")
      end
      infil_program.addLine('EndIf')
      infil_program.addLine('Set ERVCpMin = (@Min OASupCp ZoneCp)')
      infil_program.addLine('Set ERVSupOutTemp = OASupInTemp + ERVCpMin/OASupCp * Effectiveness_Sens * (ZoneTemp - OASupInTemp)')
      infil_program.addLine('Set ERVSupOutW = OASupInW + ERVCpMin/OASupCp * Effectiveness_Lat * (ZoneW - OASupInW)')
      infil_program.addLine('Set ERVSupOutEnth = (@HFnTdbW ERVSupOutTemp ERVSupOutW)')
      infil_program.addLine('Set ERVSensHeatTrans = Fan_MFR * OASupCp * (ERVSupOutTemp - OASupInTemp)')
      infil_program.addLine('Set ERVTotalHeatTrans = Fan_MFR * (ERVSupOutEnth - OASupInEnth)')
      infil_program.addLine('Set ERVLatHeatTrans = ERVTotalHeatTrans - ERVSensHeatTrans')
      # ERV/HRV Load calculation
      infil_program.addLine('Set ZoneInEnth = ERVSupOutEnth')
      infil_program.addLine('Set ZoneInTemp = ERVSupOutTemp')
    end
    infil_program.addLine('Set FanTotalToCond = Fan_MFR * (ZoneInEnth - ZoneAirEnth)')
    infil_program.addLine('Set FanSensToCond = Fan_MFR * ZoneCp * (ZoneInTemp - ZoneTemp)')
    infil_program.addLine('Set FanLatToCond = FanTotalToCond - FanSensToCond')

    # Actuator,
    # If preconditioned, handle actuators later in calculate_precond_loads
    if not preconditioned
      infil_program.addLine("Set #{fan_sens_load_actuator.name} = #{fan_sens_load_actuator.name} + FanSensToCond")
      infil_program.addLine("Set #{fan_lat_load_actuator.name} = #{fan_lat_load_actuator.name} + FanLatToCond")
    end
  end

  # Updates the infiltration EMS program to calculate the mechanical ventilation preconditioning sensible/
  # latent loads and energy consumption.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param infil_program [OpenStudio::Model::EnergyManagementSystemProgram] EMS program for the infiltration calculations
  # @param vent_fans [Hash] Map of vent fan types => list of HPXML VentilationFans
  # @param hrv_erv_effectiveness_map [Hash] Map of HPXML VentilationFan => Hash of effectiveness values
  # @param fan_sens_load_actuator [OpenStudio::Model::EnergyManagementSystemActuator] EMS actuators for sensible load
  # @param fan_lat_load_actuator [OpenStudio::Model::EnergyManagementSystemActuator] EMS actuators for latent load
  # @param sensors [Hash] Map of :sensor_types => OpenStudio::Model::EnergyManagementSystemSensor objects
  # @return [nil]
  def self.calculate_precond_loads(model, spaces, infil_program, vent_fans, hrv_erv_effectiveness_map, fan_sens_load_actuator, fan_lat_load_actuator, sensors)
    conditioned_space = spaces[HPXML::LocationConditionedSpace]
    conditioned_zone = conditioned_space.thermalZone.get

    # Preconditioning
    # Assume introducing no sensible loads to zone if preconditioned
    if not vent_fans[:mech_preheat].empty?
      htg_stp_sensor = Model.add_ems_sensor(
        model,
        name: 'htg stp s',
        output_var_or_meter_name: 'Zone Thermostat Heating Setpoint Temperature',
        key_name: conditioned_zone.name
      )
      infil_program.addLine("Set HtgStp = #{htg_stp_sensor.name}") # heating thermostat setpoint
    end
    if not vent_fans[:mech_precool].empty?
      clg_stp_sensor = Model.add_ems_sensor(
        model,
        name: 'clg stp s',
        output_var_or_meter_name: 'Zone Thermostat Cooling Setpoint Temperature',
        key_name: conditioned_zone.name
      )
      infil_program.addLine("Set ClgStp = #{clg_stp_sensor.name}") # cooling thermostat setpoint
    end
    vent_fans[:mech_preheat].each_with_index do |f_preheat, i|
      infil_program.addLine("If (OASupInTemp < HtgStp) && (#{sensors[:clg_ssn].name} < 1)")

      cnt = model.getOtherEquipments.count { |e| e.endUseSubcategory.start_with? Constants::ObjectTypeMechanicalVentilationPreheating } # Ensure unique meter for each preheating system
      other_equip = Model.add_other_equipment(
        model,
        name: "shared mech vent preheating energy #{i}",
        end_use: "#{Constants::ObjectTypeMechanicalVentilationPreheating}#{cnt + 1}",
        space: conditioned_space,
        design_level: nil,
        frac_radiant: 0,
        frac_latent: 0,
        frac_lost: 1,
        schedule: model.alwaysOnDiscreteSchedule,
        fuel_type: f_preheat.preheating_fuel
      )

      htg_energy_actuator = Model.add_ems_actuator(
        name: "#{other_equip.name} act",
        model_object: other_equip,
        comp_type_and_control: EPlus::EMSActuatorOtherEquipmentPower
      )
      htg_energy_actuator.actuatedComponent.get.additionalProperties.setFeature('HPXML_ID', f_preheat.id) # Used by reporting measure

      infil_program.addLine("  Set Qpreheat = #{UnitConversions.convert(f_preheat.average_oa_unit_flow_rate, 'cfm', 'm^3/s').round(4)}")
      if [HPXML::MechVentTypeERV, HPXML::MechVentTypeHRV].include? f_preheat.fan_type
        vent_mech_fans = [f_preheat]
      else
        vent_mech_fans = []
      end
      calculate_fan_loads(infil_program, vent_mech_fans, hrv_erv_effectiveness_map, fan_sens_load_actuator, fan_lat_load_actuator, 'Qpreheat', true)

      infil_program.addLine('  If ZoneInTemp < HtgStp')
      infil_program.addLine('    Set FanSensToSpt = Fan_MFR * ZoneCp * (ZoneInTemp - HtgStp)')
      infil_program.addLine("    Set PreHeatingWatt = (-FanSensToSpt) * #{f_preheat.preheating_fraction_load_served}")
      infil_program.addLine("    Set #{fan_sens_load_actuator.name} = #{fan_sens_load_actuator.name} + PreHeatingWatt")
      infil_program.addLine("    Set #{fan_lat_load_actuator.name} = #{fan_lat_load_actuator.name} - FanLatToCond")
      infil_program.addLine('  Else')
      infil_program.addLine('    Set PreHeatingWatt = 0.0')
      infil_program.addLine('  EndIf')
      infil_program.addLine('Else')
      infil_program.addLine('  Set PreHeatingWatt = 0.0')
      infil_program.addLine('EndIf')
      infil_program.addLine("Set #{htg_energy_actuator.name} = PreHeatingWatt / #{f_preheat.preheating_efficiency_cop}")
    end
    vent_fans[:mech_precool].each_with_index do |f_precool, i|
      infil_program.addLine("If (OASupInTemp > ClgStp) && (#{sensors[:clg_ssn].name} > 0)")

      cnt = model.getOtherEquipments.count { |e| e.endUseSubcategory.start_with? Constants::ObjectTypeMechanicalVentilationPrecooling } # Ensure unique meter for each precooling system
      other_equip = Model.add_other_equipment(
        model,
        name: "shared mech vent precooling energy #{i}",
        end_use: "#{Constants::ObjectTypeMechanicalVentilationPrecooling}#{cnt + 1}",
        space: conditioned_space,
        design_level: nil,
        frac_radiant: 0,
        frac_latent: 0,
        frac_lost: 1,
        schedule: model.alwaysOnDiscreteSchedule,
        fuel_type: f_precool.precooling_fuel
      )

      clg_energy_actuator = Model.add_ems_actuator(
        name: "#{other_equip.name} act",
        model_object: other_equip,
        comp_type_and_control: EPlus::EMSActuatorOtherEquipmentPower
      )
      clg_energy_actuator.actuatedComponent.get.additionalProperties.setFeature('HPXML_ID', f_precool.id) # Used by reporting measure

      infil_program.addLine("  Set Qprecool = #{UnitConversions.convert(f_precool.average_oa_unit_flow_rate, 'cfm', 'm^3/s').round(4)}")
      if [HPXML::MechVentTypeERV, HPXML::MechVentTypeHRV].include? f_precool.fan_type
        vent_mech_fans = [f_precool]
      else
        vent_mech_fans = []
      end
      calculate_fan_loads(infil_program, vent_mech_fans, hrv_erv_effectiveness_map, fan_sens_load_actuator, fan_lat_load_actuator, 'Qprecool', true)

      infil_program.addLine('  If ZoneInTemp > ClgStp')
      infil_program.addLine('    Set FanSensToSpt = Fan_MFR * ZoneCp * (ZoneInTemp - ClgStp)')
      infil_program.addLine("    Set PreCoolingWatt = FanSensToSpt * #{f_precool.precooling_fraction_load_served}")
      infil_program.addLine("    Set #{fan_sens_load_actuator.name} = #{fan_sens_load_actuator.name}  - PreCoolingWatt")
      infil_program.addLine("    Set #{fan_lat_load_actuator.name} = #{fan_lat_load_actuator.name} - FanLatToCond") # Fixme:Does this assumption still apply?
      infil_program.addLine('  Else')
      infil_program.addLine('    Set PreCoolingWatt = 0.0')
      infil_program.addLine('  EndIf')
      infil_program.addLine('Else')
      infil_program.addLine('  Set PreCoolingWatt = 0.0')
      infil_program.addLine('EndIf')
      infil_program.addLine("Set #{clg_energy_actuator.name} = PreCoolingWatt / #{f_precool.precooling_efficiency_cop}")
    end
  end

  #  Adds infiltration and ventilation fans to the OpenStudio conditioned space.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param vent_fans [Hash] Map of vent fan types => list of HPXML VentilationFans
  # @param infil_values [Hash] Map with various infiltration key-value pairs (SLA, infiltration volume & height, etc.)
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param duct_lk_imbals [Array] List of duct leakage imbalance information
  # @param cfis_data [Hash] Map with various CFIS-relative OpenStudio model objects
  # @param fan_data [Hash] Map of HVAC blower fan properties => values
  # @param sensors [Hash] Map of :sensor_types => OpenStudio::Model::EnergyManagementSystemSensor objects
  # @return [nil]
  def self.apply_infiltration_ventilation_to_conditioned(runner, model, spaces, weather, hpxml_bldg, hpxml_header, vent_fans, infil_values,
                                                         schedules_file, duct_lk_imbals, cfis_data, fan_data, sensors)
    # Categorize fans into different types
    vent_fans[:mech_preheat] = vent_fans[:mech].select { |vent_mech| (not vent_mech.preheating_efficiency_cop.nil?) }
    vent_fans[:mech_precool] = vent_fans[:mech].select { |vent_mech| (not vent_mech.precooling_efficiency_cop.nil?) }
    vent_fans[:mech_supply] = vent_fans[:mech].select { |vent_mech| vent_mech.fan_type == HPXML::MechVentTypeSupply }
    vent_fans[:mech_exhaust] = vent_fans[:mech].select { |vent_mech| vent_mech.fan_type == HPXML::MechVentTypeExhaust }
    vent_fans[:mech_cfis] = vent_fans[:mech].select { |vent_mech| vent_mech.fan_type == HPXML::MechVentTypeCFIS }
    vent_fans[:mech_balanced] = vent_fans[:mech].select { |vent_mech| vent_mech.fan_type == HPXML::MechVentTypeBalanced }
    vent_fans[:mech_erv_hrv] = vent_fans[:mech].select { |vent_mech| [HPXML::MechVentTypeERV, HPXML::MechVentTypeHRV].include? vent_mech.fan_type }

    # Non-CFIS fan power
    house_fan_unavailable_periods = Schedule.get_unavailable_periods(runner, SchedulesFile::Columns[:HouseFan].name, hpxml_header.unavailable_periods)
    add_mech_vent_fan_power(model, spaces, Constants::ObjectTypeMechanicalVentilationHouseFan,
                            vent_fans[:mech_supply], vent_fans[:mech_exhaust], vent_fans[:mech_balanced], vent_fans[:mech_erv_hrv], house_fan_unavailable_periods)

    # CFIS ventilation mode fan power
    cfis_fan_actuator = add_mech_vent_fan_power(model, spaces, Constants::ObjectTypeMechanicalVentilationHouseFanCFIS) # Fan heat enters space

    # CFIS ventilation mode supplemental fan power
    if not vent_fans[:cfis_suppl].empty?
      vent_mech_cfis_suppl_sup_tot = vent_fans[:cfis_suppl].select { |vent_mech| vent_mech.fan_type == HPXML::MechVentTypeSupply }
      vent_mech_cfis_suppl_exh_tot = vent_fans[:cfis_suppl].select { |vent_mech| vent_mech.fan_type == HPXML::MechVentTypeExhaust }
      cfis_suppl_fan_actuator = add_mech_vent_fan_power(model, spaces, Constants::ObjectTypeMechanicalVentilationHouseFanCFISSupplFan,
                                                        vent_mech_cfis_suppl_sup_tot, vent_mech_cfis_suppl_exh_tot)
    else
      cfis_suppl_fan_actuator = nil
    end

    # Conditioned Space Infiltration Calculation/Program
    infil_program = Model.add_ems_program(
      model,
      name: "#{Constants::ObjectTypeInfiltration} program"
    )
    infil_program.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeInfiltration)

    # Calculate infiltration without adjustment by ventilation
    apply_infiltration_to_conditioned(spaces, hpxml_bldg, hpxml_header, infil_program, weather, infil_values, sensors)

    # Common variable and load actuators across multiple mech vent calculations, create only once
    fan_sens_load_actuator, fan_lat_load_actuator = initialize_mech_vent(model, spaces, infil_program, sensors)

    # Apply CFIS
    apply_cfis(runner, infil_program, vent_fans[:mech_cfis], cfis_data, cfis_fan_actuator, cfis_suppl_fan_actuator, fan_data)

    # Calculate adjusted infiltration (infiltration adjusted by mechanical ventilation)
    apply_infiltration_adjustment_to_conditioned(runner, model, spaces, hpxml_bldg, hpxml_header, infil_program, vent_fans, duct_lk_imbals, schedules_file)

    # Address load of Qfan (Qload)
    # Qload as variable for tracking outdoor air flow rate, excluding recirculation
    infil_program.addLine('Set Qload = Qfan')
    vent_fans[:mech].each do |f|
      recirc_flow_rate = f.average_unit_flow_rate - f.average_oa_unit_flow_rate
      next unless recirc_flow_rate > 0

      # Subtract recirculation air flow rate from Qfan, only come from supply side as exhaust is not allowed to have recirculation
      infil_program.addLine("Set Qload = Qload - #{UnitConversions.convert(recirc_flow_rate, 'cfm', 'm^3/s').round(4)}")
    end

    # Calculate effectiveness for all ERV/HRV and store results in a hash
    hrv_erv_effectiveness_map = calc_hrv_erv_effectiveness(vent_fans[:mech_erv_hrv])

    calculate_fan_loads(infil_program, vent_fans[:mech_erv_hrv], hrv_erv_effectiveness_map, fan_sens_load_actuator, fan_lat_load_actuator, 'Qload')
    calculate_precond_loads(model, spaces, infil_program, vent_fans, hrv_erv_effectiveness_map, fan_sens_load_actuator, fan_lat_load_actuator, sensors)

    Model.add_ems_program_calling_manager(
      model,
      name: "#{infil_program.name} calling manager",
      calling_point: 'BeginZoneTimestepAfterInitHeatBalance',
      ems_programs: [infil_program]
    )
  end

  # Updates the infiltration EMS program with calculations for the conditioned space. Uses the Alberta Air
  # Infiltration Model version 2 (AIM-2), also known as the ASHRAE Enhanced model.
  #
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param infil_program [OpenStudio::Model::EnergyManagementSystemProgram] EMS program for the infiltration calculations
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param infil_values [Hash] Map with various infiltration key-value pairs (SLA, infiltration volume & height, etc.)
  # @param sensors [Hash] Map of :sensor_types => OpenStudio::Model::EnergyManagementSystemSensor objects
  # @param n_i [Double] Infiltration test flow exponent
  # @return [nil]
  def self.apply_infiltration_to_conditioned(spaces, hpxml_bldg, hpxml_header, infil_program, weather, infil_values, sensors, n_i = InfilPressureExponent)
    site_ap = hpxml_bldg.site.additional_properties

    if hpxml_header.apply_ashrae140_assumptions
      const_ach = infil_values[:nach] * infil_values[:a_ext]
    else
      ach50 = infil_values[:ach50] * infil_values[:a_ext]
    end

    if ach50.to_f > 0
      # Based on "Field Validation of Algebraic Equations for Stack and
      # Wind Driven Air Infiltration Calculations" by Walker and Wilson (1998)

      p_atm = UnitConversions.convert(Psychrometrics.Pstd_fZ(hpxml_bldg.elevation), 'psi', 'atm')
      outside_air_density = UnitConversions.convert(p_atm, 'atm', 'Btu/ft^3') / (Gas.Air.r * UnitConversions.convert(weather.data.AnnualAvgDrybulb, 'F', 'R'))

      sla = get_infiltration_SLA_from_ACH50(ach50, infil_values[:avg_ceil_height])

      cfa = hpxml_bldg.building_construction.conditioned_floor_area
      a_o = sla * cfa # Effective Leakage Area (ft2)

      # Flow Coefficient (cfm/inH2O^n) (based on ASHRAE HoF)
      inf_conv_factor = 776.25 # [ft/min]/[inH2O^(1/2)*ft^(3/2)/lbm^(1/2)]
      delta_pref = 0.016 # inH2O
      c_i = a_o * (2.0 / outside_air_density)**0.5 * delta_pref**(0.5 - n_i) * inf_conv_factor

      if hpxml_bldg.air_infiltration.has_flue_or_chimney_in_conditioned_space
        y_i = 0.2 # Fraction of leakage through the flue; 0.2 is a "typical" value according to THE ALBERTA AIR INFIL1RATION MODEL, Walker and Wilson, 1990
        s_wflue = 1.0 # Flue Shelter Coefficient
      else
        y_i = 0.0 # Fraction of leakage through the flue
        s_wflue = 0.0 # Flue Shelter Coefficient
      end

      # Leakage distributions per Iain Walker (LBL) recommendations
      if not spaces[HPXML::LocationCrawlspaceVented].nil?
        # 15% ceiling, 35% walls, 50% floor leakage distribution for vented crawl
        leakage_ceiling = 0.15
        leakage_floor = 0.50
      else
        # 25% ceiling, 50% walls, 25% floor leakage distribution for slab/basement/unvented crawl
        leakage_ceiling = 0.25
        leakage_floor = 0.25
      end

      r_i = (leakage_ceiling + leakage_floor)
      x_i = (leakage_ceiling - leakage_floor)
      r_i *= (1 - y_i)
      x_i *= (1 - y_i)

      # Calculate Stack Coefficient
      m_o = (x_i + (2.0 * n_i + 1.0) * y_i)**2.0 / (2 - r_i)
      if m_o <=  1.0
        m_i = m_o # eq. 10
      else
        m_i = 1.0 # eq. 11
      end
      if hpxml_bldg.air_infiltration.has_flue_or_chimney_in_conditioned_space
        ncfl_ag = hpxml_bldg.building_construction.number_of_conditioned_floors_above_grade
        if ncfl_ag <= 0
          z_f = 1.0
        else
          z_f = (ncfl_ag + 0.5) / ncfl_ag # Typical value is 1.5 according to THE ALBERTA AIR INFIL1RATION MODEL, Walker and Wilson, 1990, presumably for a single story home
        end
        x_c = r_i + (2.0 * (1.0 - r_i - y_i)) / (n_i + 1.0) - 2.0 * y_i * (z_f - 1.0)**n_i # Critical value of ceiling-floor leakage difference where the neutral level is located at the ceiling (eq. 13)
        f_i = n_i * y_i * (z_f - 1.0)**((3.0 * n_i - 1.0) / 3.0) * (1.0 - (3.0 * (x_c - x_i)**2.0 * r_i**(1 - n_i)) / (2.0 * (z_f + 1.0))) # Additive flue function, Eq. 12
      else
        f_i = 0.0 # Additive flue function (eq. 12)
      end
      f_s = ((1.0 + n_i * r_i) / (n_i + 1.0)) * (0.5 - 0.5 * m_i**1.2)**(n_i + 1.0) + f_i
      stack_coef = f_s * (UnitConversions.convert(outside_air_density * Gravity * infil_values[:height], 'lbm/(ft*s^2)', 'inH2O') / UnitConversions.convert(AssumedInsideTemp, 'F', 'R'))**n_i # inH2O^n/R^n

      # Calculate wind coefficient
      if not spaces[HPXML::LocationCrawlspaceVented].nil?
        if x_i > 1.0 - 2.0 * y_i
          # Critical floor to ceiling difference above which f_w does not change (eq. 25)
          x_i = 1.0 - 2.0 * y_i
        end
        r_x = 1.0 - r_i * (n_i / 2.0 + 0.2) # Redefined R for wind calculations for houses with crawlspaces (eq. 21)
        y_x = 1.0 - y_i / 4.0 # Redefined Y for wind calculations for houses with crawlspaces (eq. 22)
        x_s = (1.0 - r_i) / 5.0 - 1.5 * y_i # Used to calculate X_x (eq.24)
        x_x = 1.0 - (((x_i - x_s) / (2.0 - r_i))**2.0)**0.75 # Redefined X for wind calculations for houses with crawlspaces (eq. 23)
        f_w = 0.19 * (2.0 - n_i) * x_x * r_x * y_x # Wind factor (eq. 20)
      else
        j_i = (x_i + r_i + 2.0 * y_i) / 2.0
        f_w = 0.19 * (2.0 - n_i) * (1.0 - ((x_i + r_i) / 2.0)**(1.5 - y_i)) - y_i / 4.0 * (j_i - 2.0 * y_i * j_i**4.0)
      end
      wind_coef = f_w * UnitConversions.convert(outside_air_density / 2.0, 'lbm/ft^3', 'inH2O/mph^2')**n_i # inH2O^n/mph^2n

      infil_program.addLine("Set p_m = #{site_ap.ashrae_terrain_exponent}")
      infil_program.addLine("Set p_s = #{site_ap.ashrae_site_terrain_exponent}")
      infil_program.addLine("Set s_m = #{site_ap.ashrae_terrain_thickness}")
      infil_program.addLine("Set s_s = #{site_ap.ashrae_site_terrain_thickness}")
      infil_program.addLine("Set z_m = #{UnitConversions.convert(site_ap.height, 'ft', 'm')}")
      infil_program.addLine("Set z_s = #{UnitConversions.convert(infil_values[:height] + [hpxml_bldg.building_construction.unit_height_above_grade, 0].max, 'ft', 'm')}")
      infil_program.addLine('Set f_t = (((s_m/z_m)^p_m)*((z_s/s_s)^p_s))')
      infil_program.addLine("Set Tdiff = #{sensors[:t_in].name}-#{sensors[:t_out].name}")
      infil_program.addLine('Set dT = @Abs Tdiff')
      infil_program.addLine("Set c = #{((UnitConversions.convert(c_i, 'cfm', 'm^3/s') / (UnitConversions.convert(1.0, 'inH2O', 'Pa')**n_i))).round(4)}")
      infil_program.addLine("Set Cs = #{(stack_coef * (UnitConversions.convert(1.0, 'inH2O/R', 'Pa/K')**n_i)).round(4)}")
      infil_program.addLine("Set Cw = #{(wind_coef * (UnitConversions.convert(1.0, 'inH2O/mph^2', 'Pa*s^2/m^2')**n_i)).round(4)}")
      infil_program.addLine("Set n = #{n_i}")
      infil_program.addLine("Set sft = (f_t*#{(site_ap.aim2_shelter_coeff * (1.0 - y_i)) + (s_wflue * (1.5 * y_i))})")
      infil_program.addLine("Set temp1 = ((c*Cw)*((sft*#{sensors[:v_wind].name})^(2*n)))^2")
      infil_program.addLine('Set Qinf = (((c*Cs*(dT^n))^2)+temp1)^0.5')
      infil_program.addLine('Set Qinf = (@Max Qinf 0)')

    elsif const_ach.to_f > 0
      infil_program.addLine("Set Qinf = #{const_ach * UnitConversions.convert(infil_values[:volume], 'ft^3', 'm^3') / UnitConversions.convert(1.0, 'hr', 's')}")
    else
      infil_program.addLine('Set Qinf = 0')
    end
  end

  # Returns wind and stack coefficients for the Sherman-Grimsrud (ASHRAE Basic Model) infiltration algorithm.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hor_lk_frac [Double] Fraction of leakage that is in the floor and ceiling
  # @param neutral_level [Double] Fraction of space height at which the indoor-outdoor pressure difference due to stack effect is zero
  # @param location [String] The location of interest (HPXML::LocationXXX)
  # @param space_height [Double] Height of the space (ft)
  # @return [Array<Double, Double>] Wind and stack coefficients
  def self.calc_wind_stack_coeffs(hpxml_bldg, hor_lk_frac, neutral_level, location, space_height = nil)
    site_ap = hpxml_bldg.site.additional_properties
    if space_height.nil?
      space_height = Geometry.calculate_zone_height(hpxml_bldg, location)
    end

    # Get distance above ground for the space
    walls_top = hpxml_bldg.building_construction.additional_properties.walls_height_above_grade
    foundation_top = hpxml_bldg.building_construction.additional_properties.foundation_height_above_grade
    if [HPXML::LocationConditionedSpace, HPXML::LocationGarage].include? location
      space_height_ag = foundation_top
    elsif [HPXML::LocationAtticVented].include? location
      space_height_ag = walls_top
    else
      fail "Unexpected location: #{location}"
    end

    f_t_SG = site_ap.site_terrain_multiplier * ((space_height + space_height_ag) / 32.8)**site_ap.site_terrain_exponent / (site_ap.terrain_multiplier * (site_ap.height / 32.8)**site_ap.terrain_exponent)
    f_s_SG = 2.0 / 3.0 * (1 + hor_lk_frac / 2.0) * (2.0 * neutral_level * (1.0 - neutral_level))**0.5 / (neutral_level**0.5 + (1.0 - neutral_level)**0.5)
    f_w_SG = site_ap.s_g_shielding_coef * (1.0 - hor_lk_frac)**(1.0 / 3.0) * f_t_SG
    c_s_SG = f_s_SG**2.0 * Gravity * space_height / UnitConversions.convert(AssumedInsideTemp, 'F', 'R')
    c_w_SG = f_w_SG**2.0
    return c_w_SG, c_s_SG
  end

  # Returns infiltration normalized leakage given SLA.
  #
  # Source: ANSI/RESNET/ICC 301-2022 Addendum C Appendix C2.2 Eq. 1
  #
  # @param sla [Double] Specific leakage area
  # @param infil_height [Double] Vertical distance between the lowest and highest above-grade points within the pressure boundary, per ASHRAE 62.2 (ft)
  # @return [Double] Normalized leakage
  def self.get_infiltration_NL_from_SLA(sla, infil_height)
    return 1000.0 * sla * (infil_height / ReferenceHeight)**0.4
  end

  # Returns the infiltration annual average ACH given a SLA.
  #
  # Source: ANSI/RESNET/ICC 301-2022 Addendum C Appendix C2.2 Eq. 6
  #
  # @param sla [Double] Specific leakage area
  # @param infil_height [Double] Vertical distance between the lowest and highest above-grade points within the pressure boundary, per ASHRAE 62.2 (ft)
  # @param infil_avg_ceil_height [Double] Average floor to ceiling height (ft)
  # @param weather [WeatherFile] Weather object containing EPW information
  # @return [Double] Annual average air changes per hour
  def self.get_infiltration_ACH_from_SLA(sla, infil_height, infil_avg_ceil_height, weather)
    norm_leakage = get_infiltration_NL_from_SLA(sla, infil_height)
    return norm_leakage * weather.data.WSF * ReferenceHeight / infil_avg_ceil_height
  end

  # Returns the infiltration SLA given an annual average ACH.
  #
  # Source: ANSI/RESNET/ICC 301-2022 Addendum C Appendix C2.2 Eq. 5
  #
  # @param ach [Double] Annual average air changes per hour
  # @param infil_height [Double] Vertical distance between the lowest and highest above-grade points within the pressure boundary, per ASHRAE 62.2 (ft)
  # @param infil_avg_ceil_height [Double] Average floor to ceiling height (ft)
  # @param weather [WeatherFile] Weather object containing EPW information
  # @return [Double] Specific leakage area
  def self.get_infiltration_SLA_from_ACH(ach, infil_height, infil_avg_ceil_height, weather)
    return ach * (infil_avg_ceil_height / ReferenceHeight) / (1000.0 * weather.data.WSF * (infil_height / ReferenceHeight)**0.4)
  end

  # Returns the infiltration SLA given a ACH50.
  #
  # Source: ANSI/RESNET/ICC 301-2022 Addendum C Appendix C2.2 Eq. 16
  #
  # @param ach50 [Double] Air changes per hour at 50 Pa
  # @param infil_avg_ceil_height [Double] Average floor to ceiling height (ft)
  # @param n_i [Double] Infiltration test flow exponent
  # @return [Double] Specific leakage area
  def self.get_infiltration_SLA_from_ACH50(ach50, infil_avg_ceil_height, n_i = InfilPressureExponent)
    return ((ach50 * 0.283316 * 4.0**n_i) / (50.0**n_i * 60.0 * UnitConversions.convert(1.0, 'ft^2', 'in^2') / infil_avg_ceil_height))
  end

  # Returns the infiltration ACH50 given a SLA.
  #
  # Source: ANSI/RESNET/ICC 301-2022 Addendum C Appendix C2.2 Eq. 15
  #
  # @param sla [Double] Specific leakage area
  # @param infil_avg_ceil_height [Double] Average floor to ceiling height (ft)
  # @param n_i [Double] Infiltration test flow exponent
  # @return [Double] Air changes per hour at 50 Pa
  def self.get_infiltration_ACH50_from_SLA(sla, infil_avg_ceil_height, n_i = InfilPressureExponent)
    return sla / (0.283316 * 4.0**n_i) * (50.0**n_i * 60.0 * UnitConversions.convert(1.0, 'ft^2', 'in^2') / infil_avg_ceil_height)
  end

  # Returns the building infiltration at a different pressure (e.g., CFM50 -> CFM25).
  #
  # @param q_old [Double] Original infiltration value
  # @param p_old [Double] Original infiltration pressure
  # @param p_new [Double] Desired infiltration pressure
  # @param n_i [Double] Infiltration test flow exponent
  # @return [Double] Infiltration value at the desired pressure
  def self.calc_infiltration_at_diff_pressure(q_old, p_old, p_new, n_i = InfilPressureExponent)
    return q_old * (p_new / p_old)**n_i
  end

  # Returns Qinf, the effective annual average infiltration rate, used to calculate
  # the mechanical ventilation fan airflow rate (Qfan) needed to meet the ASHRAE 62.2
  # total air exchange rate (Qtot).
  #
  # @param nl [Double] Normalized leakage
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @return [Double] Infiltration airflow rate (cfm)
  def self.get_mech_vent_qinf_cfm(nl, weather, cfa)
    return nl * weather.data.WSF * cfa * ReferenceHeight / 60.0
  end

  # Returns Qtot, the total required air exchange rate, per ASHRAE 62.2.
  #
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @return [Double] Total airflow rate (cfm)
  def self.get_mech_vent_qtot_cfm(nbeds, cfa)
    return (nbeds + 1.0) * 7.5 + 0.03 * cfa
  end

  # Returns Qfan, the mechanical ventilation fan airflow rate needed in conjunction with
  # the infiltration rate (Qinf) to meet the ASHRAE 62.2 total air exchange rate (Qtot).
  #
  # @param q_tot [Double] Total airflow rate (cfm)
  # @param q_inf [Double] Infiltration airflow rate (cfm)
  # @param is_balanced [Double] Whether the mechanical ventilation fan is balanced (supply airflow equal to exhaust airflow)
  # @param frac_imbal [Double] The fraction of total mechanical ventilation airflow that is imbalanced
  # @param a_ext [Double] Ratio of exterior envelope area to total envelope area for SFA/MF units
  # @param unit_type [String] Type of dwelling unit (HXPML::ResidentialTypeXXX)
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @param hours_in_operation [Double] Hours/day that the fan is operating
  # @return [Double] Mechanical ventilation fan airflow rate (cfm)
  def self.get_mech_vent_qfan_cfm(q_tot, q_inf, is_balanced, frac_imbal, a_ext, unit_type, eri_version, hours_in_operation)
    q_inf_eff = q_inf * a_ext
    if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2022')
      if frac_imbal == 0
        q_fan = q_tot - q_inf_eff
      else
        q_inf_eff = q_inf * a_ext
        if q_inf_eff >= q_tot
          q_fan = 0.0
        else
          q_fan = ((frac_imbal**2.0 * q_tot**2.0 - 4.0 * frac_imbal * q_inf_eff**2.0 + 2.0 * frac_imbal * q_inf_eff * q_tot + q_inf_eff**2.0)**0.5 + frac_imbal * q_tot - q_inf_eff) / (2.0 * frac_imbal)
        end
      end
    elsif Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2019')
      if is_balanced
        phi = 1.0
      else
        phi = q_inf / q_tot
      end
      q_fan = q_tot - phi * q_inf_eff
    else
      if [HPXML::ResidentialTypeApartment, HPXML::ResidentialTypeSFA].include? unit_type
        # No infiltration credit for attached/multifamily
        return q_tot
      end

      if q_inf > 2.0 / 3.0 * q_tot
        q_fan = q_tot - 2.0 / 3.0 * q_tot
      else
        q_fan = q_tot - q_inf
      end
    end

    # Convert from hourly average requirement to actual fan flow rate
    if not hours_in_operation.nil?
      q_fan *= 24.0 / hours_in_operation
    end

    return [q_fan, 0.0].max
  end

  # Creates an array of duct info hashes for the given HPXML HVAC Distribution system.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hvac_distribution [HPXML::HVACDistribution] HPXML HVAC Distribution object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @return [Array<Hash>] List of duct info Hashes
  def self.create_duct_infos(model, hvac_distribution, spaces)
    duct_infos = []

    # Duct leakage (supply/return => [value, units])
    leakage_to_outside = { HPXML::DuctTypeSupply => [0.0, nil],
                           HPXML::DuctTypeReturn => [0.0, nil] }
    hvac_distribution.duct_leakage_measurements.each do |duct_leakage_measurement|
      next unless [HPXML::UnitsCFM25, HPXML::UnitsCFM50, HPXML::UnitsPercent].include?(duct_leakage_measurement.duct_leakage_units) && (duct_leakage_measurement.duct_leakage_total_or_to_outside == HPXML::DuctLeakageToOutside)
      next if duct_leakage_measurement.duct_type.nil?

      leakage_to_outside[duct_leakage_measurement.duct_type] = [duct_leakage_measurement.duct_leakage_value, duct_leakage_measurement.duct_leakage_units]
    end

    # Duct location, R-value, Area
    total_unconditioned_duct_area = { HPXML::DuctTypeSupply => 0.0,
                                      HPXML::DuctTypeReturn => 0.0 }
    hvac_distribution.ducts.each do |ducts|
      next if HPXML::conditioned_locations_this_unit.include? ducts.duct_location
      next if ducts.duct_type.nil?

      # Calculate total duct area in unconditioned spaces
      total_unconditioned_duct_area[ducts.duct_type] += ducts.duct_surface_area * ducts.duct_surface_area_multiplier
    end

    # Create duct hashes
    hvac_distribution.ducts.each do |ducts|
      next if HPXML::conditioned_locations_this_unit.include? ducts.duct_location
      next if ducts.duct_type.nil?
      next if total_unconditioned_duct_area[ducts.duct_type] <= 0

      duct_loc_space, duct_loc_schedule = Geometry.get_space_or_schedule_from_location(ducts.duct_location, model, spaces)

      # Apportion leakage to individual ducts by surface area
      duct_leakage_value = leakage_to_outside[ducts.duct_type][0] * ducts.duct_surface_area * ducts.duct_surface_area_multiplier / total_unconditioned_duct_area[ducts.duct_type]
      duct_leakage_units = leakage_to_outside[ducts.duct_type][1]

      duct_leakage_frac = nil
      if duct_leakage_units == HPXML::UnitsCFM25
        duct_leakage_cfm25 = duct_leakage_value
      elsif duct_leakage_units == HPXML::UnitsCFM50
        duct_leakage_cfm50 = duct_leakage_value
      elsif duct_leakage_units == HPXML::UnitsPercent
        duct_leakage_frac = duct_leakage_value
      else
        fail "#{ducts.duct_type.capitalize} ducts exist but leakage was not specified for distribution system '#{hvac_distribution.id}'."
      end

      duct_infos << { side: ducts.duct_type,
                      loc_space: duct_loc_space,
                      loc_schedule: duct_loc_schedule,
                      leakage_frac: duct_leakage_frac,
                      leakage_cfm25: duct_leakage_cfm25,
                      leakage_cfm50: duct_leakage_cfm50,
                      area: ducts.duct_surface_area * ducts.duct_surface_area_multiplier,
                      effective_rvalue: ducts.duct_effective_r_value,
                      buried_level: ducts.duct_buried_insulation_level }
    end

    # If all ducts are in conditioned space, model leakage as going to outside
    [HPXML::DuctTypeSupply, HPXML::DuctTypeReturn].each do |duct_side|
      next unless (leakage_to_outside[duct_side][0] > 0) && (total_unconditioned_duct_area[duct_side] == 0)

      duct_leakage_value = leakage_to_outside[duct_side][0]
      duct_leakage_units = leakage_to_outside[duct_side][1]

      case duct_leakage_units
      when HPXML::UnitsCFM25
        duct_leakage_cfm25 = duct_leakage_value
      when HPXML::UnitsCFM50
        duct_leakage_cfm50 = duct_leakage_value
      when HPXML::UnitsPercent
        duct_leakage_frac = duct_leakage_value
      else
        fail "#{duct_side.capitalize} ducts exist but leakage was not specified for distribution system '#{hvac_distribution.id}'."
      end

      duct_infos << { side: duct_side,
                      loc_space: nil, # outside
                      loc_schedule: nil, # outside
                      leakage_frac: duct_leakage_frac,
                      leakage_cfm25: duct_leakage_cfm25,
                      leakage_cfm50: duct_leakage_cfm50,
                      area: 0.0,
                      effective_rvalue: 99, # Arbitrary
                      buried_level: HPXML::DuctBuriedInsulationNone }
    end

    return duct_infos
  end
end
