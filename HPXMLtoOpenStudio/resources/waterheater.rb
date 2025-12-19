# frozen_string_literal: true

# Collection of methods related to water heating systems.
module Waterheater
  DefaultTankHeight = 4.0 # ft, assumption from BEopt

  # Adds any water heaters and appliances to the OpenStudio Model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def self.apply_dhw_appliances(runner, model, weather, spaces, hpxml_bldg, hpxml_header, schedules_file)
    unavailable_periods = Schedule.get_unavailable_periods(runner, SchedulesFile::Columns[:WaterHeater].name, hpxml_header.unavailable_periods)

    plantloop_map = {}
    hpxml_bldg.water_heating_systems.each do |dhw_system|
      case dhw_system.water_heater_type
      when HPXML::WaterHeaterTypeStorage
        apply_tank(runner, model, spaces, hpxml_bldg, hpxml_header, dhw_system, schedules_file, unavailable_periods, plantloop_map)
      when HPXML::WaterHeaterTypeTankless
        apply_tankless(runner, model, spaces, hpxml_bldg, hpxml_header, dhw_system, schedules_file, unavailable_periods, plantloop_map)
      when HPXML::WaterHeaterTypeHeatPump
        apply_hpwh(runner, model, spaces, hpxml_bldg, hpxml_header, dhw_system, schedules_file, unavailable_periods, plantloop_map)
      when HPXML::WaterHeaterTypeCombiStorage, HPXML::WaterHeaterTypeCombiTankless
        apply_combi(runner, model, spaces, hpxml_bldg, hpxml_header, dhw_system, schedules_file, unavailable_periods, plantloop_map)
      else
        fail "Unhandled water heater (#{dhw_system.water_heater_type})."
      end
    end

    HotWaterAndAppliances.apply(runner, model, weather, spaces, hpxml_bldg, hpxml_header, schedules_file, plantloop_map)

    apply_solar_thermal(model, spaces, hpxml_bldg, plantloop_map)
    apply_combi_system_EMS(model, hpxml_bldg.water_heating_systems, plantloop_map)
  end

  # Adds a conventional storage tank water heater to the OpenStudio model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param water_heating_system [HPXML::WaterHeatingSystem] The HPXML water heating system of interest
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @param plantloop_map [Hash] Map of HPXML System ID => OpenStudio PlantLoop objects
  # @return [nil]
  def self.apply_tank(runner, model, spaces, hpxml_bldg, hpxml_header, water_heating_system, schedules_file, unavailable_periods, plantloop_map)
    loc_space, loc_schedule = Geometry.get_space_or_schedule_from_location(water_heating_system.location, model, spaces)
    unit_multiplier = hpxml_bldg.building_construction.number_of_units
    solar_fraction = get_water_heater_solar_fraction(water_heating_system, hpxml_bldg)
    t_set_c = get_t_set_c(water_heating_system.temperature, water_heating_system.water_heater_type)
    plant_loop = add_plant_loop(model, t_set_c, hpxml_header.eri_calculation_versions[0], unit_multiplier)

    act_vol = calc_storage_tank_actual_vol(water_heating_system.tank_volume, water_heating_system.fuel_type)
    tank_u, tank_ua, tank_eta_c = disaggregate_tank_losses_and_burner_efficiency(act_vol, water_heating_system, solar_fraction, hpxml_bldg.building_construction.number_of_bedrooms)
    water_heater = apply_water_heater(runner, model,
                                      name: Constants::ObjectTypeWaterHeater,
                                      water_heating_system: water_heating_system,
                                      act_vol: act_vol,
                                      t_set_c: t_set_c,
                                      loc_space: loc_space,
                                      loc_schedule: loc_schedule,
                                      tank_u: tank_u,
                                      tank_ua: tank_ua,
                                      tank_eta_c: tank_eta_c,
                                      schedules_file: schedules_file,
                                      unavailable_periods: unavailable_periods,
                                      unit_multiplier: unit_multiplier)
    plant_loop.addSupplyBranchForComponent(water_heater)

    apply_ec_adj_program(model, hpxml_bldg, water_heater, loc_space, water_heating_system, unit_multiplier)
    apply_desuperheater(runner, model, water_heating_system, water_heater, loc_space, loc_schedule, plant_loop, unit_multiplier)

    plantloop_map[water_heating_system.id] = plant_loop
  end

  # Adds a tankless water heater to the OpenStudio model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param water_heating_system [HPXML::WaterHeatingSystem] The HPXML water heating system of interest
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @param plantloop_map [Hash] Map of HPXML System ID => OpenStudio PlantLoop objects
  # @return [nil]
  def self.apply_tankless(runner, model, spaces, hpxml_bldg, hpxml_header, water_heating_system, schedules_file, unavailable_periods, plantloop_map)
    loc_space, loc_schedule = Geometry.get_space_or_schedule_from_location(water_heating_system.location, model, spaces)
    unit_multiplier = hpxml_bldg.building_construction.number_of_units
    water_heating_system.heating_capacity = 100000000000.0 * unit_multiplier
    solar_fraction = get_water_heater_solar_fraction(water_heating_system, hpxml_bldg)
    t_set_c = get_t_set_c(water_heating_system.temperature, water_heating_system.water_heater_type)
    plant_loop = add_plant_loop(model, t_set_c, hpxml_header.eri_calculation_versions[0], unit_multiplier)

    act_vol = 1.0 * unit_multiplier
    _tank_u, tank_ua, tank_eta_c = disaggregate_tank_losses_and_burner_efficiency(act_vol, water_heating_system, solar_fraction, hpxml_bldg.building_construction.number_of_bedrooms)
    water_heater = apply_water_heater(runner, model,
                                      name: Constants::ObjectTypeWaterHeater,
                                      water_heating_system: water_heating_system,
                                      act_vol: act_vol,
                                      t_set_c: t_set_c,
                                      loc_space: loc_space,
                                      loc_schedule: loc_schedule,
                                      tank_ua: tank_ua,
                                      tank_eta_c: tank_eta_c,
                                      schedules_file: schedules_file,
                                      unavailable_periods: unavailable_periods,
                                      unit_multiplier: unit_multiplier)

    plant_loop.addSupplyBranchForComponent(water_heater)

    apply_ec_adj_program(model, hpxml_bldg, water_heater, loc_space, water_heating_system, unit_multiplier)
    apply_desuperheater(runner, model, water_heating_system, water_heater, loc_space, loc_schedule, plant_loop, unit_multiplier)

    plantloop_map[water_heating_system.id] = plant_loop
  end

  # Adds a heat pump water heater to the OpenStudio model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param water_heating_system [HPXML::WaterHeatingSystem] The HPXML water heating system of interest
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @param plantloop_map [Hash] Map of HPXML System ID => OpenStudio PlantLoop objects
  # @return [nil]
  def self.apply_hpwh(runner, model, spaces, hpxml_bldg, hpxml_header, water_heating_system, schedules_file, unavailable_periods, plantloop_map)
    loc_space, loc_schedule = Geometry.get_space_or_schedule_from_location(water_heating_system.location, model, spaces)
    unit_multiplier = hpxml_bldg.building_construction.number_of_units
    obj_name = Constants::ObjectTypeWaterHeater
    solar_fraction = get_water_heater_solar_fraction(water_heating_system, hpxml_bldg)
    t_set_c = get_t_set_c(water_heating_system.temperature, water_heating_system.water_heater_type)
    plant_loop = add_plant_loop(model, t_set_c, hpxml_header.eri_calculation_versions[0], unit_multiplier)

    # Add in schedules for Tamb, RHamb, and the compressor
    hpwh_tamb = Model.add_schedule_constant(
      model,
      name: "#{obj_name} Tamb act",
      value: 23,
      limits: EPlus::ScheduleTypeLimitsTemperature
    )

    hpwh_rhamb = Model.add_schedule_constant(
      model,
      name: "#{obj_name} RHamb act",
      value: 0.5,
      limits: EPlus::ScheduleTypeLimitsFraction
    )

    # Note: These get overwritten by EMS later, see HPWH Control program
    top_element_sp = Model.add_schedule_constant(
      model,
      name: "#{obj_name} TopElementSetpoint",
      value: nil,
      limits: EPlus::ScheduleTypeLimitsTemperature
    )
    bottom_element_sp = Model.add_schedule_constant(
      model,
      name: "#{obj_name} BottomElementSetpoint",
      value: nil,
      limits: EPlus::ScheduleTypeLimitsTemperature
    )

    # To handle variable setpoints, need one schedule that gets sensed and a new schedule that gets actuated
    sensed_setpoint_schedule = nil
    if not schedules_file.nil?
      # Sensed schedule
      sensed_setpoint_schedule = schedules_file.create_schedule_file(model, col_name: SchedulesFile::Columns[:WaterHeaterSetpoint].name, schedule_type_limits_name: EPlus::ScheduleTypeLimitsTemperature)
      if not sensed_setpoint_schedule.nil?
        # Actuated schedule
        control_setpoint_schedule = ScheduleConstant.new(model, "#{obj_name} ControlSetpoint", 0.0, EPlus::ScheduleTypeLimitsTemperature, unavailable_periods: unavailable_periods)
        control_setpoint_schedule = control_setpoint_schedule.schedule
      end
    end
    if sensed_setpoint_schedule.nil?
      sensed_setpoint_schedule = ScheduleConstant.new(model, Constants::ObjectTypeWaterHeaterSetpoint, t_set_c, EPlus::ScheduleTypeLimitsTemperature, unavailable_periods: unavailable_periods)
      sensed_setpoint_schedule = sensed_setpoint_schedule.schedule

      control_setpoint_schedule = sensed_setpoint_schedule
    else
      runner.registerWarning("Both '#{SchedulesFile::Columns[:WaterHeaterSetpoint].name}' schedule file and setpoint temperature provided; the latter will be ignored.") if !t_set_c.nil?
    end

    airflow_rate = 181.0 # cfm
    min_temp = 42.0 # F
    max_temp = 120.0 # F

    # Coil:WaterHeating:AirToWaterHeatPump:Wrapped
    coil = apply_hpwh_dxcoil(runner, model, water_heating_system, hpxml_bldg.elevation, obj_name, airflow_rate, unit_multiplier)

    # WaterHeater:Stratified
    tank = apply_hpwh_stratified_tank(model, water_heating_system, obj_name, solar_fraction, hpwh_tamb, top_element_sp, bottom_element_sp, unit_multiplier, hpxml_bldg.building_construction.number_of_bedrooms)
    plant_loop.addSupplyBranchForComponent(tank)

    apply_desuperheater(runner, model, water_heating_system, tank, loc_space, loc_schedule, plant_loop, unit_multiplier)

    # Fan:SystemModel
    fan_power = 0.0462 # W/cfm, Based on 1st gen AO Smith HPWH, could be updated but pretty minor impact
    fan = Model.add_fan_system_model(
      model,
      name: "#{obj_name} fan",
      end_use: 'Domestic Hot Water',
      power_per_flow: fan_power / UnitConversions.convert(1.0, 'cfm', 'm^3/s'),
      max_flow_rate: UnitConversions.convert(airflow_rate * unit_multiplier, 'ft^3/min', 'm^3/s')
    )
    fan.additionalProperties.setFeature('HPXML_ID', water_heating_system.id) # Used by reporting measure
    fan.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeWaterHeater) # Used by reporting measure

    # WaterHeater:HeatPump:WrappedCondenser
    hpwh = apply_hpwh_wrapped_condenser(model, obj_name, coil, tank, fan, airflow_rate, hpwh_tamb, hpwh_rhamb, min_temp, max_temp, control_setpoint_schedule, unit_multiplier)

    # Amb temp & RH sensors, temp sensor shared across programs
    amb_temp_sensor, amb_rh_sensors = apply_hpwh_loc_temp_rh_sensors(model, obj_name, loc_space, loc_schedule, spaces)
    hpwh_zone_heat_gain_program = apply_hpwh_zone_heat_gain_program(model, obj_name, loc_space, hpwh_tamb, hpwh_rhamb, tank, coil, fan, amb_temp_sensor, amb_rh_sensors, unit_multiplier)

    # EMS for the HPWH control logic
    hpwh_ctrl_program = apply_hpwh_control_program(runner, model, obj_name, water_heating_system, amb_temp_sensor, top_element_sp, bottom_element_sp, min_temp, max_temp, sensed_setpoint_schedule, control_setpoint_schedule, schedules_file)

    # ProgramCallingManagers
    Model.add_ems_program_calling_manager(
      model,
      name: "#{obj_name} ProgramManager",
      calling_point: 'InsideHVACSystemIterationLoop',
      ems_programs: [hpwh_ctrl_program, hpwh_zone_heat_gain_program]
    )

    apply_ec_adj_program(model, hpxml_bldg, hpwh, loc_space, water_heating_system, unit_multiplier)

    plantloop_map[water_heating_system.id] = plant_loop
  end

  # Adds a combination boiler water heater to the OpenStudio model.
  #
  # Note that we model two separate boilers (one for just space heating and one for just water heating).
  # This makes the code much simpler and makes the EnergyPlus results more robust.
  #
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param water_heating_system [HPXML::WaterHeatingSystem] The HPXML water heating system of interest
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @param plantloop_map [Hash] Map of HPXML System ID => OpenStudio PlantLoop objects
  # @return [nil]
  def self.apply_combi(runner, model, spaces, hpxml_bldg, hpxml_header, water_heating_system, schedules_file, unavailable_periods, plantloop_map)
    loc_space, loc_schedule = Geometry.get_space_or_schedule_from_location(water_heating_system.location, model, spaces)
    unit_multiplier = hpxml_bldg.building_construction.number_of_units
    solar_fraction = get_water_heater_solar_fraction(water_heating_system, hpxml_bldg)

    boiler, boiler_plant_loop = get_combi_boiler_and_plant_loop(model, water_heating_system.related_hvac_idref)
    boiler.setName('combi boiler')
    boiler.additionalProperties.setFeature('HPXML_ID', water_heating_system.id) # Used by reporting measure
    boiler.additionalProperties.setFeature('IsCombiBoiler', true) # Used by reporting measure

    obj_name_combi = Constants::ObjectTypeWaterHeater

    if water_heating_system.water_heater_type == HPXML::WaterHeaterTypeCombiStorage
      if water_heating_system.standby_loss_value <= 0
        fail 'A negative indirect water heater standby loss was calculated, double check water heater inputs.'
      end

      act_vol = calc_storage_tank_actual_vol(water_heating_system.tank_volume, nil)
      _tank_a, side_a = calc_tank_areas(act_vol)
      tank_ua = calc_combi_tank_losses(act_vol, water_heating_system, side_a, solar_fraction, hpxml_bldg.building_construction.number_of_bedrooms)
    else
      tank_ua = 0.0
      act_vol = 1.0
    end

    t_set_c = get_t_set_c(water_heating_system.temperature, water_heating_system.water_heater_type)
    plant_loop = add_plant_loop(model, t_set_c, hpxml_header.eri_calculation_versions[0], unit_multiplier)

    # Create water heater
    water_heater = apply_water_heater(runner, model,
                                      name: obj_name_combi,
                                      water_heating_system: water_heating_system,
                                      act_vol: act_vol,
                                      t_set_c: t_set_c,
                                      loc_space: loc_space,
                                      loc_schedule: loc_schedule,
                                      tank_ua: tank_ua,
                                      is_combi: true,
                                      schedules_file: schedules_file,
                                      unavailable_periods: unavailable_periods,
                                      unit_multiplier: unit_multiplier)
    water_heater.setSourceSideDesignFlowRate(100 * unit_multiplier) # set one large number, override by EMS

    # Create alternate setpoint schedule for source side flow request
    alternate_stp_sch = water_heater.setpointTemperatureSchedule.get.clone(model).to_Schedule.get
    alternate_stp_sch.setName("#{obj_name_combi} Alt Spt")
    water_heater.setIndirectAlternateSetpointTemperatureSchedule(alternate_stp_sch)

    # Create setpoint schedule to specify source side temperature
    # tank source side inlet temperature, degree C
    boiler_spt_mngr = model.getSetpointManagerScheduleds.find { |spt_mngr| spt_mngr.setpointNode.get == boiler_plant_loop.loopTemperatureSetpointNode }
    boiler_heating_spt = boiler_spt_mngr.to_SetpointManagerScheduled.get.schedule.to_ScheduleConstant.get.value
    source_stp_sch = Model.add_schedule_constant(
      model,
      name: "#{obj_name_combi} Source Spt",
      value: boiler_heating_spt,
      limits: EPlus::ScheduleTypeLimitsTemperature
    )
    # reset dhw boiler setpoint
    boiler_spt_mngr.to_SetpointManagerScheduled.get.setSchedule(source_stp_sch)
    boiler_plant_loop.autosizeMaximumLoopFlowRate()

    # change loop equipment operation scheme to heating load
    scheme_dhw = OpenStudio::Model::PlantEquipmentOperationHeatingLoad.new(model)
    scheme_dhw.addEquipment(1000000000, water_heater)
    plant_loop.setPrimaryPlantEquipmentOperationScheme(scheme_dhw)

    # Add dhw boiler to the load distribution scheme
    scheme = OpenStudio::Model::PlantEquipmentOperationHeatingLoad.new(model)
    scheme.addEquipment(1000000000, boiler)
    boiler_plant_loop.setPrimaryPlantEquipmentOperationScheme(scheme)
    boiler_plant_loop.addDemandBranchForComponent(water_heater)
    boiler_plant_loop.setPlantLoopVolume(0.001 * unit_multiplier) # Cannot be auto-calculated because of large default tank source side mfr(set to be overwritten by EMS)

    plant_loop.addSupplyBranchForComponent(water_heater)

    apply_ec_adj_program(model, hpxml_bldg, water_heater, loc_space, water_heating_system, unit_multiplier, boiler)

    plantloop_map[water_heating_system.id] = plant_loop
  end

  # Calculates the water heating energy consumption adjustment factor (EC_adj) due to the effectiveness of
  # the hot water distribution system.
  #
  # Source: ANSI/RESNET/ICC 301
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param water_heating_system [HPXML::WaterHeatingSystem] The HPXML water heating system of interest
  # @return [Double] Hot water energy consumption multiplier
  def self.get_dist_energy_consumption_adjustment(hpxml_bldg, water_heating_system)
    if water_heating_system.fraction_dhw_load_served <= 0
      # No fixtures; not accounting for distribution system
      return 1.0
    end

    hot_water_distribution = hpxml_bldg.hot_water_distributions[0]

    has_uncond_bsmnt = hpxml_bldg.has_location(HPXML::LocationBasementUnconditioned)
    has_cond_bsmnt = hpxml_bldg.has_location(HPXML::LocationBasementConditioned)
    cfa = hpxml_bldg.building_construction.conditioned_floor_area
    ncfl = hpxml_bldg.building_construction.number_of_conditioned_floors

    # ANSI/RESNET/ICC 301-2022 Eq. 4.2-44
    ew_fact = get_dist_energy_waste_factor(hot_water_distribution)
    o_frac = 0.25 # fraction of hot water waste from standard operating conditions
    oew_fact = ew_fact * o_frac # standard operating condition portion of hot water energy waste
    ocd_eff = 0.0
    sew_fact = ew_fact - oew_fact
    if hot_water_distribution.system_type == HPXML::DHWDistTypeStandard
      ref_pipe_l = Defaults.get_std_pipe_length(has_uncond_bsmnt, has_cond_bsmnt, cfa, ncfl)
      pe_ratio = hot_water_distribution.standard_piping_length / ref_pipe_l
    elsif hot_water_distribution.system_type == HPXML::DHWDistTypeRecirc
      ref_loop_l = Defaults.get_recirc_loop_length(has_uncond_bsmnt, has_cond_bsmnt, cfa, ncfl)
      pe_ratio = hot_water_distribution.recirculation_piping_loop_length / ref_loop_l
    end
    e_waste = oew_fact * (1.0 - ocd_eff) + sew_fact * pe_ratio
    return (e_waste + 128.0) / 160.0
  end

  # Retrieves the hot water distribution system relative annual energy waste factors.
  #
  # Source: ANSI/RESNET/ICC 301
  #
  # @param hot_water_distribution [HPXML::HotWaterDistribution] The HPXML hot water distribution system of interest
  # @return [Double] Energy waste factor
  def self.get_dist_energy_waste_factor(hot_water_distribution)
    # ANSI/RESNET/ICC 301-2022 Table 4.2.2.7.2.11(6)
    if hot_water_distribution.system_type == HPXML::DHWDistTypeRecirc
      case hot_water_distribution.recirculation_control_type
      when HPXML::DHWRecircControlTypeNone, HPXML::DHWRecircControlTypeTimer
        if hot_water_distribution.pipe_r_value < 3.0
          return 500.0
        else
          return 250.0
        end
      when HPXML::DHWRecircControlTypeTemperature
        if hot_water_distribution.pipe_r_value < 3.0
          return 375.0
        else
          return 187.5
        end
      when HPXML::DHWRecircControlTypeSensor
        if hot_water_distribution.pipe_r_value < 3.0
          return 64.8
        else
          return 43.2
        end
      when HPXML::DHWRecircControlTypeManual
        if hot_water_distribution.pipe_r_value < 3.0
          return 43.2
        else
          return 28.8
        end
      end
    elsif hot_water_distribution.system_type == HPXML::DHWDistTypeStandard
      if hot_water_distribution.pipe_r_value < 3.0
        return 32.0
      else
        return 28.8
      end
    end
    fail 'Unexpected hot water distribution system.'
  end

  # Adds an EMS program to control the boiler operation based on domestic hot water demand.
  # The program modulates the source side mass flow rate to achieve better control and accuracy
  # compared to not having the EMS program. See https://github.com/NREL/OpenStudio-HPXML/pull/225.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param water_heating_systems [Array<HPXML::WaterHeatingSystem>] The HPXML water heaters of interest
  # @param plantloop_map [Hash] Map of HPXML System ID => OpenStudio PlantLoop objects
  # @return [nil]
  def self.apply_combi_system_EMS(model, water_heating_systems, plantloop_map)
    water_heating_systems.select { |wh|
      [HPXML::WaterHeaterTypeCombiStorage,
       HPXML::WaterHeaterTypeCombiTankless].include? wh.water_heater_type
    }.each do |water_heating_system|
      combi_sys_id = water_heating_system.id

      # EMS for modulate source side mass flow rate
      # Initialization
      equipment_peaks = {}
      equipment_sch_sensors = {}
      equipment_target_temp_sensors = {}
      tank_volume, deadband, tank_source_temp = 0.0, 0.0, 0.0
      alt_spt_sch = nil
      tank_temp_sensor, tank_spt_sensor, tank_loss_energy_sensor = nil, nil, nil
      altsch_actuator, pump_actuator = nil, nil
      water_heater = nil

      # Create sensors and actuators
      plant_loop = plantloop_map[combi_sys_id]
      plant_loop.components.each do |c|
        next unless c.to_WaterHeaterMixed.is_initialized

        water_heater = c.to_WaterHeaterMixed.get
        tank_volume = water_heater.tankVolume.get
        deadband = water_heater.deadbandTemperatureDifference

        # Sensors and actuators related to OS water heater object
        tank_temp_sensor = Model.add_ems_sensor(
          model,
          name: "#{combi_sys_id} Tank Temp",
          output_var_or_meter_name: 'Water Heater Tank Temperature',
          key_name: water_heater.name
        )

        tank_loss_energy_sensor = Model.add_ems_sensor(
          model,
          name: "#{combi_sys_id} Tank Loss Energy",
          output_var_or_meter_name: 'Water Heater Heat Loss Energy',
          key_name: water_heater.name
        )

        tank_spt_sensor = Model.add_ems_sensor(
          model,
          name: "#{combi_sys_id} Setpoint Temperature",
          output_var_or_meter_name: 'Schedule Value',
          key_name: water_heater.setpointTemperatureSchedule.get.name
        )

        alt_spt_sch = water_heater.indirectAlternateSetpointTemperatureSchedule.get
        if alt_spt_sch.to_ScheduleConstant.is_initialized
          comp_type_and_control = EPlus::EMSActuatorScheduleConstantValue
        elsif alt_spt_sch.to_ScheduleRuleset.is_initialized
          comp_type_and_control = EPlus::EMSActuatorScheduleYearValue
        else
          comp_type_and_control = EPlus::EMSActuatorScheduleFileValue
        end
        altsch_actuator = Model.add_ems_actuator(
          name: "#{combi_sys_id} AltSchedOverride",
          model_object: alt_spt_sch,
          comp_type_and_control: comp_type_and_control
        )
      end
      plant_loop.components.each do |c|
        next unless c.to_WaterUseConnections.is_initialized

        wuc = c.to_WaterUseConnections.get
        wuc.waterUseEquipment.each do |wu|
          # water use equipment peak mass flow rate
          wu_peak = wu.waterUseEquipmentDefinition.peakFlowRate
          equipment_peaks[wu.name.to_s] = wu_peak

          # mfr fraction schedule sensors
          equipment_sch_sensors[wu.name.to_s] = Model.add_ems_sensor(
            model,
            name: "#{wu.name} sch value",
            output_var_or_meter_name: 'Schedule Value',
            key_name: wu.flowRateFractionSchedule.get.name
          )

          # water use equipment target temperature schedule sensors
          if wu.waterUseEquipmentDefinition.targetTemperatureSchedule.is_initialized
            target_temp_sch = wu.waterUseEquipmentDefinition.targetTemperatureSchedule.get
          else
            target_temp_sch = water_heater.setpointTemperatureSchedule.get
          end

          equipment_target_temp_sensors[wu.name.to_s] = Model.add_ems_sensor(
            model,
            name: "#{wu.name} target temp",
            output_var_or_meter_name: 'Schedule Value',
            key_name: target_temp_sch.name
          )
        end
      end
      dhw_source_loop = model.getPlantLoops.find { |l| l.demandComponents.include? water_heater }
      dhw_source_loop.components.each do |c|
        next unless c.to_PumpVariableSpeed.is_initialized

        pump = c.to_PumpVariableSpeed.get
        pump_actuator = Model.add_ems_actuator(
          name: "#{combi_sys_id} Pump MFR",
          model_object: pump,
          comp_type_and_control: EPlus::EMSActuatorPumpMassFlowRate
        )
      end
      dhw_source_loop.supplyOutletNode.setpointManagers.each do |setpoint_manager|
        if setpoint_manager.to_SetpointManagerScheduled.is_initialized
          tank_source_temp = setpoint_manager.to_SetpointManagerScheduled.get.schedule.to_ScheduleConstant.get.value
        end
      end

      mains_temp_sensor = Model.add_ems_sensor(
        model,
        name: 'Mains Temperature',
        output_var_or_meter_name: 'Site Mains Water Temperature',
        key_name: 'Environment'
      )

      # Program
      combi_ctrl_program = Model.add_ems_program(
        model,
        name: "#{combi_sys_id} Source MFR Control"
      )
      combi_ctrl_program.addLine("Set Rho = @RhoH2O #{tank_temp_sensor.name}")
      combi_ctrl_program.addLine("Set Cp = @CpHW #{tank_temp_sensor.name}")
      combi_ctrl_program.addLine("Set Tank_Water_Mass = #{tank_volume} * Rho")
      combi_ctrl_program.addLine("Set DeltaT = #{tank_source_temp} - #{tank_spt_sensor.name}")
      combi_ctrl_program.addLine("Set WU_Hot_Temp = #{tank_temp_sensor.name}")
      combi_ctrl_program.addLine("Set WU_Cold_Temp = #{mains_temp_sensor.name}")
      combi_ctrl_program.addLine('Set Tank_Use_Total_MFR = 0.0')
      equipment_peaks.each do |wu_name, peak|
        wu_id = Model.ems_friendly_name(wu_name)
        combi_ctrl_program.addLine("Set #{wu_id}_Peak = #{peak}")
        combi_ctrl_program.addLine("Set #{wu_id}_MFR_Total = #{wu_id}_Peak * #{equipment_sch_sensors[wu_name].name} * Rho")
        combi_ctrl_program.addLine("If #{equipment_target_temp_sensors[wu_name].name} > WU_Hot_Temp")
        combi_ctrl_program.addLine("Set #{wu_id}_MFR_Hot = #{wu_id}_MFR_Total")
        combi_ctrl_program.addLine('Else')
        combi_ctrl_program.addLine("Set #{wu_id}_MFR_Hot = #{wu_id}_MFR_Total * (#{equipment_target_temp_sensors[wu_name].name} - WU_Cold_Temp)/(WU_Hot_Temp - WU_Cold_Temp)")
        combi_ctrl_program.addLine('EndIf')
        combi_ctrl_program.addLine("Set Tank_Use_Total_MFR = Tank_Use_Total_MFR + #{wu_id}_MFR_Hot")
      end
      combi_ctrl_program.addLine("Set WH_Loss = - #{tank_loss_energy_sensor.name}")
      combi_ctrl_program.addLine("Set WH_Use = Tank_Use_Total_MFR * Cp * (#{tank_temp_sensor.name} - #{mains_temp_sensor.name}) * ZoneTimeStep * 3600")
      combi_ctrl_program.addLine("Set WH_HeatToLowSetpoint = Tank_Water_Mass * Cp * (#{tank_temp_sensor.name} - #{tank_spt_sensor.name} + #{deadband})")
      combi_ctrl_program.addLine("Set WH_HeatToHighSetpoint = Tank_Water_Mass * Cp * (#{tank_temp_sensor.name} - #{tank_spt_sensor.name})")
      combi_ctrl_program.addLine('Set WH_Energy_Demand = WH_Use + WH_Loss - WH_HeatToLowSetpoint')
      combi_ctrl_program.addLine('Set WH_Energy_Heat = WH_Use + WH_Loss - WH_HeatToHighSetpoint')
      combi_ctrl_program.addLine('If WH_Energy_Demand > 0')
      combi_ctrl_program.addLine("Set #{pump_actuator.name} = WH_Energy_Heat / (Cp * DeltaT * 3600 * ZoneTimeStep)")
      combi_ctrl_program.addLine("Set #{altsch_actuator.name} = 100") # Set the alternate setpoint temperature to highest level to ensure maximum source side flow rate
      combi_ctrl_program.addLine('Else')
      combi_ctrl_program.addLine("Set #{pump_actuator.name} = 0")
      combi_ctrl_program.addLine("Set #{altsch_actuator.name} = NULL")
      combi_ctrl_program.addLine('EndIf')

      # ProgramCallingManagers
      Model.add_ems_program_calling_manager(
        model,
        name: "#{combi_sys_id} ProgramManager",
        calling_point: 'BeginZoneTimestepAfterInitHeatBalance',
        ems_programs: [combi_ctrl_program]
      )
    end
  end

  # Adds an HPXML Solar Thermal System to the OpenStudio model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param plantloop_map [Hash] Map of HPXML System ID => OpenStudio PlantLoop objects
  # @return [nil]
  def self.apply_solar_thermal(model, spaces, hpxml_bldg, plantloop_map)
    return if hpxml_bldg.solar_thermal_systems.size == 0

    solar_thermal_system = hpxml_bldg.solar_thermal_systems[0]
    return if solar_thermal_system.collector_area.nil? # Return if simple (not detailed) solar water heater type

    if [HPXML::WaterHeaterTypeCombiStorage, HPXML::WaterHeaterTypeCombiTankless].include? solar_thermal_system.water_heating_system.water_heater_type
      fail "Water heating system '#{solar_thermal_system.water_heating_system.id}' connected to solar thermal system '#{solar_thermal_system.id}' cannot be a space-heating boiler."
    end
    if solar_thermal_system.water_heating_system.uses_desuperheater
      fail "Water heating system '#{solar_thermal_system.water_heating_system.id}' connected to solar thermal system '#{solar_thermal_system.id}' cannot be attached to a desuperheater."
    end

    loc_space, loc_schedule = Geometry.get_space_or_schedule_from_location(solar_thermal_system.water_heating_system.location, model, spaces)
    dhw_loop = plantloop_map[solar_thermal_system.water_heating_system.id]
    unit_multiplier = hpxml_bldg.building_construction.number_of_units

    obj_name = Constants::ObjectTypeSolarHotWater

    case solar_thermal_system.collector_type
    when HPXML::SolarThermalCollectorTypeEvacuatedTube
      iam_coeff2 = 0.3023 # IAM coeff1=1 by definition, values based on a system listed by SRCC with values close to the average
      iam_coeff3 = -0.3057
    when HPXML::SolarThermalCollectorTypeSingleGlazing, HPXML::SolarThermalCollectorTypeDoubleGlazing
      iam_coeff2 = 0.1
      iam_coeff3 = 0
    when HPXML::SolarThermalCollectorTypeICS
      iam_coeff2 = 0.1
      iam_coeff3 = 0
    end

    case solar_thermal_system.collector_loop_type
    when HPXML::SolarThermalLoopTypeIndirect
      fluid_type = EPlus::FluidPropyleneGlycol
      heat_ex_eff = 0.7
    when HPXML::SolarThermalLoopTypeDirect, HPXML::SolarThermalLoopTypeThermosyphon
      fluid_type = EPlus::FluidWater
      heat_ex_eff = 1.0
    end

    collector_area = solar_thermal_system.collector_area * unit_multiplier
    storage_volume = solar_thermal_system.storage_volume * unit_multiplier

    if solar_thermal_system.collector_loop_type == HPXML::SolarThermalLoopTypeThermosyphon
      pump_power = 0.0
    else
      pump_power = 0.8 * collector_area
    end

    test_flow = 55.0 / UnitConversions.convert(1.0, 'lbm/min', 'kg/hr') / Liquid.H2O_l.rho * UnitConversions.convert(1.0, 'ft^2', 'm^2') # cfm/ft^2
    coll_flow = test_flow * collector_area # cfm
    if fluid_type == EPlus::FluidWater # Direct, make the storage tank a dummy tank with 0 tank losses
      tank_u = 0.0
    else
      tank_r = 10.0 # F-ft2-hr/Btu
      tank_u = 1.0 / tank_r # Btu/hr-ft^2-F
    end

    # Get water heater and setpoint temperature schedules from loop
    water_heater = nil
    setpoint_schedule_one = nil
    setpoint_schedule_two = nil
    dhw_loop.supplyComponents.each do |supply_component|
      if supply_component.to_WaterHeaterMixed.is_initialized
        water_heater = supply_component.to_WaterHeaterMixed.get
        setpoint_schedule_one = water_heater.setpointTemperatureSchedule.get
        setpoint_schedule_two = water_heater.setpointTemperatureSchedule.get
      elsif supply_component.to_WaterHeaterStratified.is_initialized
        water_heater = supply_component.to_WaterHeaterStratified.get
        setpoint_schedule_one = water_heater.heater1SetpointTemperatureSchedule
        setpoint_schedule_two = water_heater.heater2SetpointTemperatureSchedule
      end
    end

    dhw_setpoint_manager = nil
    dhw_loop.supplyOutletNode.setpointManagers.each do |setpoint_manager|
      if setpoint_manager.to_SetpointManagerScheduled.is_initialized
        dhw_setpoint_manager = setpoint_manager.to_SetpointManagerScheduled.get
      end
    end

    plant_loop = Model.add_plant_loop(
      model,
      name: 'solar hot water loop',
      fluid_type: fluid_type
    )

    sizing_plant = plant_loop.sizingPlant
    sizing_plant.setLoopType('Heating')
    sizing_plant.setDesignLoopExitTemperature(dhw_loop.sizingPlant.designLoopExitTemperature)
    sizing_plant.setLoopDesignTemperatureDifference(UnitConversions.convert(10.0, 'deltaF', 'deltaC'))

    setpoint_manager = OpenStudio::Model::SetpointManagerScheduled.new(model, dhw_setpoint_manager.schedule)
    setpoint_manager.setName(obj_name + ' setpoint mgr')
    setpoint_manager.setControlVariable('Temperature')

    pump = OpenStudio::Model::PumpConstantSpeed.new(model)
    pump.setName(obj_name + ' pump')
    pump.setRatedPumpHead(90000)
    pump.setRatedPowerConsumption(pump_power)
    pump.setMotorEfficiency(0.3)
    pump.setFractionofMotorInefficienciestoFluidStream(0.2)
    pump.setPumpControlType(EPlus::PumpControlTypeIntermittent)
    pump.setRatedFlowRate(UnitConversions.convert(coll_flow, 'cfm', 'm^3/s'))
    pump.addToNode(plant_loop.supplyInletNode)
    pump.additionalProperties.setFeature('HPXML_ID', solar_thermal_system.water_heating_system.id) # Used by reporting measure
    pump.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeSolarHotWater) # Used by reporting measure

    panel_length = UnitConversions.convert(collector_area, 'ft^2', 'm^2')**0.5
    run = Math::cos(solar_thermal_system.collector_tilt * Math::PI / 180) * panel_length

    offset = 1000.0 # prevent shading

    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new(offset, offset, 0)
    vertices << OpenStudio::Point3d.new(offset + panel_length, offset, 0)
    vertices << OpenStudio::Point3d.new(offset + panel_length, offset + run, (panel_length**2 - run**2)**0.5)
    vertices << OpenStudio::Point3d.new(offset, offset + run, (panel_length**2 - run**2)**0.5)

    m = OpenStudio::Matrix.new(4, 4, 0)
    azimuth = Float(solar_thermal_system.collector_azimuth)
    m[0, 0] = Math::cos((180 - azimuth) * Math::PI / 180)
    m[1, 1] = Math::cos((180 - azimuth) * Math::PI / 180)
    m[0, 1] = -Math::sin((180 - azimuth) * Math::PI / 180)
    m[1, 0] = Math::sin((180 - azimuth) * Math::PI / 180)
    m[2, 2] = 1
    m[3, 3] = 1
    transformation = OpenStudio::Transformation.new(m)
    vertices = transformation * vertices

    shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
    shading_surface_group.setName(obj_name + ' shading group')

    shading_surface = OpenStudio::Model::ShadingSurface.new(vertices, model)
    shading_surface.setName(obj_name + ' shading surface')
    shading_surface.setShadingSurfaceGroup(shading_surface_group)

    if solar_thermal_system.collector_type == HPXML::SolarThermalCollectorTypeICS
      collector_plate = OpenStudio::Model::SolarCollectorIntegralCollectorStorage.new(model)
      collector_plate.setName(obj_name + ' coll plate')
      collector_plate.setSurface(shading_surface)
      collector_plate.setMaximumFlowRate(UnitConversions.convert(coll_flow, 'cfm', 'm^3/s'))

      ics_performance = collector_plate.solarCollectorPerformance
      # Values are based on spec sheet + OG-100 listing for Solarheart ICS collectors
      ics_performance.setName(obj_name + ' coll perf')
      ics_performance.setGrossArea(UnitConversions.convert(collector_area, 'ft^2', 'm^2'))
      ics_performance.setCollectorWaterVolume(UnitConversions.convert(storage_volume, 'gal', 'm^3'))
      ics_performance.setBottomHeatLossConductance(1.902) # Spec sheet
      ics_performance.setSideHeatLossConductance(1.268)
      ics_performance.setAspectRatio(0.721)
      ics_performance.setCollectorSideHeight(0.17272)
      ics_performance.setNumberOfCovers(1)
      ics_performance.setAbsorptanceOfAbsorberPlate(0.94)
      ics_performance.setEmissivityOfAbsorberPlate(0.56)
      collector_plate.setSolarCollectorPerformance(ics_performance)

    else
      collector_plate = OpenStudio::Model::SolarCollectorFlatPlateWater.new(model)
      collector_plate.setName(obj_name + ' coll plate')
      collector_plate.setSurface(shading_surface)
      collector_plate.setMaximumFlowRate(UnitConversions.convert(coll_flow, 'cfm', 'm^3/s'))
      collector_performance = collector_plate.solarCollectorPerformance
      collector_performance.setName(obj_name + ' coll perf')
      collector_performance.setGrossArea(UnitConversions.convert(collector_area, 'ft^2', 'm^2'))
      collector_performance.setTestFluid(EPlus::FluidWater)
      collector_performance.setTestFlowRate(UnitConversions.convert(coll_flow, 'cfm', 'm^3/s'))
      collector_performance.setTestCorrelationType('Inlet')
      collector_performance.setCoefficient1ofEfficiencyEquation(solar_thermal_system.collector_rated_optical_efficiency)
      collector_performance.setCoefficient2ofEfficiencyEquation(-UnitConversions.convert(solar_thermal_system.collector_rated_thermal_losses, 'Btu/(hr*ft^2*F)', 'W/(m^2*K)'))
      collector_performance.setCoefficient2ofIncidentAngleModifier(-iam_coeff2)
      collector_performance.setCoefficient3ofIncidentAngleModifier(iam_coeff3)

    end

    plant_loop.addSupplyBranchForComponent(collector_plate)

    pipe_supply_bypass = Model.add_pipe_adiabatic(model)
    pipe_supply_outlet = Model.add_pipe_adiabatic(model)
    pipe_demand_bypass = Model.add_pipe_adiabatic(model)
    pipe_demand_inlet = Model.add_pipe_adiabatic(model)
    pipe_demand_outlet = Model.add_pipe_adiabatic(model)

    plant_loop.addSupplyBranchForComponent(pipe_supply_bypass)
    pump.addToNode(plant_loop.supplyInletNode)
    pipe_supply_outlet.addToNode(plant_loop.supplyOutletNode)
    setpoint_manager.addToNode(plant_loop.supplyOutletNode)
    plant_loop.addDemandBranchForComponent(pipe_demand_bypass)
    pipe_demand_inlet.addToNode(plant_loop.demandInletNode)
    pipe_demand_outlet.addToNode(plant_loop.demandOutletNode)

    storage_tank = OpenStudio::Model::WaterHeaterStratified.new(model)
    storage_tank.setName(obj_name + ' storage tank')
    storage_tank.setSourceSideEffectiveness(heat_ex_eff)
    storage_tank.setTankShape('VerticalCylinder')
    if (solar_thermal_system.collector_type == HPXML::SolarThermalCollectorTypeICS) || (fluid_type == EPlus::FluidWater) # Use a 60 gal tank dummy tank for direct systems, storage volume for ICS is assumed to be collector volume
      tank_volume = UnitConversions.convert(60 * unit_multiplier, 'gal', 'm^3')
    else
      tank_volume = UnitConversions.convert(storage_volume, 'gal', 'm^3')
    end
    tank_height = UnitConversions.convert(4.5, 'ft', 'm')
    storage_tank.setTankVolume(tank_volume)
    storage_tank.setTankHeight(tank_height)
    storage_tank.setUseSideOutletHeight(tank_height)
    storage_tank.setSourceSideInletHeight(tank_height / 3.0)
    storage_tank.setMaximumTemperatureLimit(99)
    storage_tank.heater1SetpointTemperatureSchedule.remove
    storage_tank.setHeater1SetpointTemperatureSchedule(setpoint_schedule_one)
    storage_tank.setHeater1Capacity(0)
    storage_tank.setHeater1Height(0)
    storage_tank.heater2SetpointTemperatureSchedule.remove
    storage_tank.setHeater2SetpointTemperatureSchedule(setpoint_schedule_two)
    storage_tank.setHeater2Capacity(0)
    storage_tank.setHeater2Height(0)
    storage_tank.setHeaterFuelType(EPlus::FuelTypeElectricity)
    storage_tank.setHeaterThermalEfficiency(1)
    storage_tank.ambientTemperatureSchedule.get.remove
    apply_ambient_temperature(loc_space, loc_schedule, storage_tank)
    storage_tank.setSkinLossFractiontoZone(1.0 / unit_multiplier) # Tank losses are multiplied by E+ zone multiplier, so need to compensate here
    storage_tank.setOffCycleFlueLossFractiontoZone(1.0 / unit_multiplier)
    storage_tank.setUseSideEffectiveness(1)
    storage_tank.setUseSideInletHeight(0)
    storage_tank.setSourceSideOutletHeight(0)
    storage_tank.setInletMode('Fixed')
    storage_tank.setIndirectWaterHeatingRecoveryTime(1.5)
    storage_tank.setNumberofNodes(8)
    storage_tank.setAdditionalDestratificationConductivity(0)
    storage_tank.setSourceSideDesignFlowRate(UnitConversions.convert(coll_flow, 'cfm', 'm^3/s'))
    storage_tank.setOnCycleParasiticFuelConsumptionRate(0)
    storage_tank.setOffCycleParasiticFuelConsumptionRate(0)
    storage_tank.setUseSideDesignFlowRate(UnitConversions.convert(storage_volume, 'gal', 'm^3') / 60.1) # Sized to ensure that E+ never autosizes the design flow rate to be larger than the tank volume getting drawn out in a hour (60 minutes)
    apply_stratified_tank_losses(storage_tank, tank_u, unit_multiplier)
    storage_tank.additionalProperties.setFeature('HPXML_ID', solar_thermal_system.water_heating_system.id) # Used by reporting measure
    storage_tank.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeSolarHotWater) # Used by reporting measure

    plant_loop.addDemandBranchForComponent(storage_tank)
    dhw_loop.addSupplyBranchForComponent(storage_tank)
    water_heater.addToNode(storage_tank.supplyOutletModelObject.get.to_Node.get)

    availability_manager = OpenStudio::Model::AvailabilityManagerDifferentialThermostat.new(model)
    availability_manager.setName(obj_name + ' useful energy')
    availability_manager.setHotNode(collector_plate.outletModelObject.get.to_Node.get)
    availability_manager.setColdNode(storage_tank.demandOutletModelObject.get.to_Node.get)
    availability_manager.setTemperatureDifferenceOnLimit(0)
    availability_manager.setTemperatureDifferenceOffLimit(0)
    plant_loop.addAvailabilityManager(availability_manager)

    # Add EMS code for SWH control (keeps the WH for the last hour if there's useful energy that can be delivered, E+ wouldn't always do this by default)
    # Sensors
    coll_sensor = Model.add_ems_sensor(
      model,
      name: "#{obj_name} Collector Outlet",
      output_var_or_meter_name: 'System Node Temperature',
      key_name: collector_plate.outletModelObject.get.to_Node.get.name
    )

    tank_source_sensor = Model.add_ems_sensor(
      model,
      name: "#{obj_name} Tank Source Inlet",
      output_var_or_meter_name: 'System Node Temperature',
      key_name: storage_tank.demandOutletModelObject.get.to_Node.get.name
    )

    # Actuators
    swh_pump_actuator = Model.add_ems_actuator(
      name: "#{obj_name}_pump",
      model_object: pump,
      comp_type_and_control: EPlus::EMSActuatorPumpMassFlowRate
    )

    # Program
    swh_program = Model.add_ems_program(
      model,
      name: "#{obj_name} Controller"
    )
    swh_program.addLine("If #{coll_sensor.name} > #{tank_source_sensor.name}")
    swh_program.addLine("Set #{swh_pump_actuator.name} = 100 * #{unit_multiplier}")
    swh_program.addLine('Else')
    swh_program.addLine("Set #{swh_pump_actuator.name} = 0")
    swh_program.addLine('EndIf')

    # ProgramCallingManager
    Model.add_ems_program_calling_manager(
      model,
      name: "#{obj_name} Control",
      calling_point: 'InsideHVACSystemIterationLoop',
      ems_programs: [swh_program]
    )
  end

  # Adds a WaterHeaterHeatPumpWrappedCondenser object for the HPWH to the OpenStudio model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param obj_name [String] Name for the OpenStudio object
  # @param coil [OpenStudio::Model::CoilWaterHeatingAirToWaterHeatPumpWrapped] The HPWH DX coil
  # @param tank [OpenStudio::Model::WaterHeaterStratified] The HPWH storage tank
  # @param fan [OpenStudio::Model::FanSystemModel] The HPWH fan
  # @param airflow_rate [Double] HPWH fan airflow rate (cfm)
  # @param hpwh_tamb [OpenStudio::Model::ScheduleConstant] HPWH ambient temperature (C)
  # @param hpwh_rhamb [OpenStudio::Model::ScheduleConstant] HPWH ambient relative humidity
  # @param min_temp [Double] Minimum temperature for compressor operation (F)
  # @param max_temp [Double] Maximum temperature for compressor operation (F)
  # @param control_setpoint_schedule [OpenStudio::Model::ScheduleConstant or OpenStudio::Model::ScheduleRuleset] Setpoint temperature schedule (controlled)
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @return [OpenStudio::Model::WaterHeaterHeatPumpWrappedCondenser] The HPWH object
  def self.apply_hpwh_wrapped_condenser(model, obj_name, coil, tank, fan, airflow_rate, hpwh_tamb, hpwh_rhamb, min_temp, max_temp, control_setpoint_schedule, unit_multiplier)
    hpwh = OpenStudio::Model::WaterHeaterHeatPumpWrappedCondenser.new(model, coil, tank, fan, control_setpoint_schedule, model.alwaysOnDiscreteSchedule)
    hpwh.setName("#{obj_name} hpwh")
    hpwh.setDeadBandTemperatureDifference(3.89)
    hpwh.setCondenserBottomLocation((1.0 - (12 - 0.5) / 12.0) * tank.tankHeight.get) # in the 12th node of a 12-node tank (counting from top)
    hpwh.setCondenserTopLocation((1.0 - (6 - 0.5) / 12.0) * tank.tankHeight.get) # in the 6th node of a 12-node tank (counting from top)
    hpwh.setEvaporatorAirFlowRate(UnitConversions.convert(airflow_rate * unit_multiplier, 'ft^3/min', 'm^3/s'))
    hpwh.setInletAirConfiguration('Schedule')
    hpwh.setInletAirTemperatureSchedule(hpwh_tamb)
    hpwh.setInletAirHumiditySchedule(hpwh_rhamb)
    hpwh.setMinimumInletAirTemperatureforCompressorOperation(UnitConversions.convert(min_temp, 'F', 'C'))
    hpwh.setMaximumInletAirTemperatureforCompressorOperation(UnitConversions.convert(max_temp, 'F', 'C'))
    hpwh.setCompressorLocation('Schedule')
    hpwh.setCompressorAmbientTemperatureSchedule(hpwh_tamb)
    hpwh.setFanPlacement('DrawThrough')
    hpwh.setOnCycleParasiticElectricLoad(0)
    hpwh.setOffCycleParasiticElectricLoad(0)
    hpwh.setParasiticHeatRejectionLocation('Outdoors')
    hpwh.setTankElementControlLogic('MutuallyExclusive')
    hpwh.setControlSensor1HeightInStratifiedTank((1.0 - (3 - 0.5) / 12.0) * tank.tankHeight.get) # in the 3rd node of a 12-node tank (counting from top)
    hpwh.setControlSensor1Weight(0.75)
    hpwh.setControlSensor2HeightInStratifiedTank((1.0 - (9 - 0.5) / 12.0) * tank.tankHeight.get) # in the 9th node of a 12-node tank (counting from top)

    return hpwh
  end

  # Adds a CoilWaterHeatingAirToWaterHeatPumpWrapped object for the HPWH to the OpenStudio model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param water_heating_system [HPXML::WaterHeatingSystem] The HPXML water heating system of interest
  # @param elevation [Double] Elevation of the building site (ft)
  # @param obj_name [String] Name for the OpenStudio object
  # @param airflow_rate [Double] HPWH fan airflow rate (cfm)
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @return [OpenStudio::Model::CoilWaterHeatingAirToWaterHeatPumpWrapped] The HPWH DX coil
  def self.apply_hpwh_dxcoil(runner, model, water_heating_system, elevation, obj_name, airflow_rate, unit_multiplier)
    # Curves
    hpwh_cap = Model.add_curve_biquadratic(
      model,
      name: 'HPWH-Cap-fT',
      coeff: [0.563, 0.0437, 0.000039, 0.0055, -0.000148, -0.000145],
      min_x: 0, max_x: 100, min_y: 0, max_y: 100
    )

    hpwh_cop = Model.add_curve_biquadratic(
      model,
      name: 'HPWH-COP-fT',
      coeff: [1.1332, 0.063, -0.0000979, -0.00972, -0.0000214, -0.000686],
      min_x: 0, max_x: 100, min_y: 0, max_y: 100
    )

    # Assumptions and values
    cap = UnitConversions.convert(water_heating_system.heating_capacity, 'Btu/hr', 'W') * unit_multiplier # kW
    shr = 0.88 # unitless

    # Calculate an altitude adjusted rated evaporator wetbulb temperature
    rated_ewb_F = 56.4
    rated_edb_F = 67.5
    p_atm = UnitConversions.convert(1.0, 'atm', 'psi')
    rated_edb = UnitConversions.convert(rated_edb_F, 'F', 'C')
    w_rated = Psychrometrics.w_fT_Twb_P(rated_edb_F, rated_ewb_F, p_atm)
    dp_rated = Psychrometrics.Tdp_fP_w(p_atm, w_rated)
    p_atm = Psychrometrics.Pstd_fZ(elevation)
    w_adj = Psychrometrics.w_fT_Twb_P(dp_rated, dp_rated, p_atm)
    twb_adj = Psychrometrics.Twb_fT_w_P(runner, rated_edb_F, w_adj, p_atm)

    cop = water_heating_system.additional_properties.cop

    # Adjust COP based on RESNET HERS Addendum 77
    if not water_heating_system.hpwh_containment_volume.nil?
      if not water_heating_system.hpwh_confined_space_without_mitigation
        if water_heating_system.hpwh_containment_volume < 1000.0
          runner.registerWarning("HPWH COP adjustment based on HPWHContainmentVolume will not be applied to #{water_heating_system.id} because HPWHInConfinedSpaceWithoutMitigation is not 'true'.")
        end
      else
        # FUTURE: apply for 120V HPWH and other system types that the correction may not be accurate for
        if water_heating_system.hpwh_containment_volume < 450.0 && (water_heating_system.backup_heating_capacity == 0.0)
          runner.registerWarning("Heat pump water heater: #{water_heating_system.id} has no backup electric resistance element, COP adjustment for confined space may not be accurate when the containment space volume is below 450 cubic feet.")
        end
        rv = [water_heating_system.hpwh_containment_volume / 1500.0, 1.0].min
        cop = (cop - 0.92) * (1 - (1.009 * Math.exp(-5.492 * rv))) + 0.92
      end
    end

    coil = OpenStudio::Model::CoilWaterHeatingAirToWaterHeatPumpWrapped.new(model)
    coil.setName("#{obj_name} coil")
    coil.setRatedHeatingCapacity(cap)
    coil.setRatedCOP(cop)
    coil.setRatedSensibleHeatRatio(shr)
    coil.setRatedEvaporatorInletAirDryBulbTemperature(rated_edb)
    coil.setRatedEvaporatorInletAirWetBulbTemperature(UnitConversions.convert(twb_adj, 'F', 'C'))
    coil.setRatedCondenserWaterTemperature(48.89)
    coil.setRatedEvaporatorAirFlowRate(UnitConversions.convert(airflow_rate * unit_multiplier, 'ft^3/min', 'm^3/s'))
    coil.setEvaporatorFanPowerIncludedinRatedCOP(true)
    coil.setEvaporatorAirTemperatureTypeforCurveObjects('WetBulbTemperature')
    coil.setHeatingCapacityFunctionofTemperatureCurve(hpwh_cap)
    coil.setHeatingCOPFunctionofTemperatureCurve(hpwh_cop)
    coil.setMaximumAmbientTemperatureforCrankcaseHeaterOperation(0)
    coil.additionalProperties.setFeature('HPXML_ID', water_heating_system.id) # Used by reporting measure

    return coil
  end

  # Returns the heating input capacity, calculated as the heating rated (output) capacity divided by the rated efficiency.
  #
  # @param heating_capacity [Double]
  # @param heating_efficiency_cop [Double] Rated efficiency [COP]
  # @return [Double] The heating input capacity [Btu/hr]
  def self.get_heating_input_capacity(heating_capacity, heating_efficiency_cop)
    return heating_capacity / UnitConversions.convert(heating_efficiency_cop, 'btu/hr', 'w')
  end

  # Adds a WaterHeaterStratified object for the HPWH to the OpenStudio model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param water_heating_system [HPXML::WaterHeatingSystem] The HPXML water heating system of interest
  # @param obj_name [String] Name for the OpenStudio object
  # @param solar_fraction [Double] Portion of hot water load served by an attached solar thermal system
  # @param hpwh_tamb [OpenStudio::Model::ScheduleConstant] HPWH ambient temperature (C)
  # @param hpwh_top_element_sp [OpenStudio::Model::ScheduleConstant] HPWH top element setpoint schedule
  # @param hpwh_bottom_element_sp [OpenStudio::Model::ScheduleConstant] HPWH bottom element setpoint schedule
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @return [OpenStudio::Model::WaterHeaterStratified] The HPWH storage tank
  def self.apply_hpwh_stratified_tank(model, water_heating_system, obj_name, solar_fraction, hpwh_tamb, hpwh_top_element_sp, hpwh_bottom_element_sp, unit_multiplier, nbeds)
    h_tank = 0.0188 * water_heating_system.tank_volume + 0.0935 # m; Linear relationship that gets GE height at 50 gal and AO Smith height at 80 gal

    # Calculate some geometry parameters for UA, the location of sensors and heat sources in the tank
    v_actual = calc_storage_tank_actual_vol(water_heating_system.tank_volume, water_heating_system.fuel_type) # gal
    tank_a, side_a = calc_tank_areas(v_actual, UnitConversions.convert(h_tank, 'm', 'ft')) # sqft

    e_cap = UnitConversions.convert(water_heating_system.backup_heating_capacity, 'Btu/hr', 'W') # W
    parasitics = 3.0 # W
    # Based on Ecotope lab testing of AO Smith HPWHs (series HPTU), see 2015 report:
    # https://neea.org/img/documents/hpwh-lab-report_ao-smith_hptu_12-09-2015.pdf.
    # More recent products do not show much change to UA values, see 2021 report:
    # https://neea.org/img/documents/Laboratory-Assessment-of-Rheem-Generation-5-Series-HPWH.pdf.
    if water_heating_system.tank_volume <= 58.0
      tank_ua = 3.6 # Btu/hr-F
    elsif water_heating_system.tank_volume <= 73.0
      tank_ua = 4.0 # Btu/hr-F
    else
      tank_ua = 4.7 # Btu/hr-F
    end
    tank_ua = apply_tank_jacket(water_heating_system, tank_ua, side_a)
    tank_ua = apply_shared_adjustment(water_heating_system, tank_ua, nbeds) # shared losses
    tank_u = tank_ua / tank_a # Btu/hr-ft^2-F
    tank_u *= (1.0 - solar_fraction)

    v_actual *= unit_multiplier
    e_cap *= unit_multiplier
    parasitics *= unit_multiplier

    tank = OpenStudio::Model::WaterHeaterStratified.new(model)
    tank.setName("#{obj_name} tank")
    tank.setEndUseSubcategory('Domestic Hot Water')
    tank.setTankVolume(UnitConversions.convert(v_actual, 'gal', 'm^3'))
    tank.setTankHeight(h_tank)
    tank.setMaximumTemperatureLimit(90)
    tank.setHeaterPriorityControl('MasterSlave')
    tank.heater1SetpointTemperatureSchedule.remove
    tank.setHeater1SetpointTemperatureSchedule(hpwh_top_element_sp)
    tank.setHeater1Capacity(e_cap)
    tank.setHeater1Height((1.0 - (3 - 0.5) / 12.0) * h_tank) # in the 3rd node of a 12-node tank (counting from top)
    tank.setHeater1DeadbandTemperatureDifference(18.5)
    tank.heater2SetpointTemperatureSchedule.remove
    tank.setHeater2SetpointTemperatureSchedule(hpwh_bottom_element_sp)
    tank.setHeater2Capacity(e_cap)
    tank.setHeater2Height((1.0 - (10 - 0.5) / 12.0) * h_tank) # in the 10th node of a 12-node tank (counting from top)
    tank.setHeater2DeadbandTemperatureDifference(3.89)
    tank.setHeaterFuelType(EPlus::FuelTypeElectricity)
    tank.setHeaterThermalEfficiency(1.0)
    tank.setOffCycleParasiticFuelConsumptionRate(parasitics)
    tank.setOffCycleParasiticFuelType(EPlus::FuelTypeElectricity)
    tank.setOnCycleParasiticFuelConsumptionRate(parasitics)
    tank.setOnCycleParasiticFuelType(EPlus::FuelTypeElectricity)
    tank.ambientTemperatureSchedule.get.remove
    tank.setAmbientTemperatureSchedule(hpwh_tamb)
    tank.setNumberofNodes(6)
    tank.setAdditionalDestratificationConductivity(0)
    tank.setUseSideDesignFlowRate(UnitConversions.convert(v_actual, 'gal', 'm^3') / 60.1) # Sized to ensure that E+ never autosizes the design flow rate to be larger than the tank volume getting drawn out in a hour (60 minutes)
    tank.setSourceSideDesignFlowRate(0)
    tank.setSourceSideFlowControlMode('')
    tank.setSourceSideInletHeight(0)
    tank.setSourceSideOutletHeight(0)
    tank.setSkinLossFractiontoZone(1.0 / unit_multiplier) # Tank losses are multiplied by E+ zone multiplier, so need to compensate here
    tank.setOffCycleFlueLossFractiontoZone(1.0 / unit_multiplier)
    apply_stratified_tank_losses(tank, tank_u, unit_multiplier)
    tank.additionalProperties.setFeature('HPXML_ID', water_heating_system.id) # Used by reporting measure

    return tank
  end

  # Adds EMS sensors for the HPWH ambient temperature and ambient relative humidity.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param obj_name [String] Name for the OpenStudio object
  # @param loc_space [OpenStudio::Model::Space] The space where the water heater is located
  # @param loc_schedule [OpenStudio::Model::ScheduleConstant] The temperature schedule, if not located in a space
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @return [Array<OpenStudio::Model::EnergyManagementSystemSensor, Array<OpenStudio::Model::EnergyManagementSystemSensor>>] HPWH ambient temperature sensor, One or more HPWH ambient RH sensors
  def self.apply_hpwh_loc_temp_rh_sensors(model, obj_name, loc_space, loc_schedule, spaces)
    conditioned_zone = spaces[HPXML::LocationConditionedSpace].thermalZone.get

    rh_sensors = []
    if not loc_schedule.nil?
      amb_temp_sensor = Model.add_ems_sensor(
        model,
        name: "#{obj_name} amb temp",
        output_var_or_meter_name: 'Schedule Value',
        key_name: loc_schedule.name
      )

      if loc_schedule.name.get == HPXML::LocationOtherNonFreezingSpace
        rh_sensors << Model.add_ems_sensor(
          model,
          name: "#{obj_name} amb rh",
          output_var_or_meter_name: 'Site Outdoor Air Relative Humidity',
          key_name: 'Environment'
        )
      elsif loc_schedule.name.get == HPXML::LocationOtherHousingUnit
        rh_sensors << Model.add_ems_sensor(
          model,
          name: "#{obj_name} amb rh",
          output_var_or_meter_name: 'Zone Air Relative Humidity',
          key_name: conditioned_zone.name
        )
      else
        rh_sensors << Model.add_ems_sensor(
          model,
          name: "#{obj_name} amb1 rh",
          output_var_or_meter_name: 'Site Outdoor Air Relative Humidity',
          key_name: 'Environment'
        )
        rh_sensors << Model.add_ems_sensor(
          model,
          name: "#{obj_name} amb2 rh",
          output_var_or_meter_name: 'Zone Air Relative Humidity',
          key_name: conditioned_zone.name
        )
      end
    elsif not loc_space.nil?
      amb_temp_sensor = Model.add_ems_sensor(
        model,
        name: "#{obj_name} amb temp",
        output_var_or_meter_name: 'Zone Mean Air Temperature',
        key_name: loc_space.thermalZone.get.name
      )

      rh_sensors << Model.add_ems_sensor(
        model,
        name: "#{obj_name} amb rh",
        output_var_or_meter_name: 'Zone Air Relative Humidity',
        key_name: loc_space.thermalZone.get.name
      )
    else # Located outside
      amb_temp_sensor = Model.add_ems_sensor(
        model,
        name: "#{obj_name} amb temp",
        output_var_or_meter_name: 'Site Outdoor Air Drybulb Temperature',
        key_name: 'Environment'
      )

      rh_sensors << Model.add_ems_sensor(
        model,
        name: "#{obj_name} amb rh",
        output_var_or_meter_name: 'Site Outdoor Air Relative Humidity',
        key_name: 'Environment'
      )
    end
    return amb_temp_sensor, rh_sensors
  end

  # Adds an EMS program to add sensible/latent gains to the thermal zone where the HPWH is located.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param obj_name [String] Name for the OpenStudio object
  # @param loc_space [OpenStudio::Model::Space] The space where the water heater is located
  # @param hpwh_tamb [OpenStudio::Model::ScheduleConstant] HPWH ambient temperature (C)
  # @param hpwh_rhamb [OpenStudio::Model::ScheduleConstant] HPWH ambient relative humidity
  # @param tank [OpenStudio::Model::WaterHeaterStratified] The HPWH storage tank
  # @param coil [OpenStudio::Model::CoilWaterHeatingAirToWaterHeatPumpWrapped] The HPWH DX coil
  # @param fan [OpenStudio::Model::FanSystemModel] The HPWH fan
  # @param amb_temp_sensor [OpenStudio::Model::EnergyManagementSystemSensor] HPWH ambient temperature sensor
  # @param amb_rh_sensors [Array<OpenStudio::Model::EnergyManagementSystemSensor>] One or more HPWH ambient RH sensors
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @return [OpenStudio::Model::EnergyManagementSystemProgram] The HPWH heat gain program
  def self.apply_hpwh_zone_heat_gain_program(model, obj_name, loc_space, hpwh_tamb, hpwh_rhamb, tank, coil, fan, amb_temp_sensor, amb_rh_sensors, unit_multiplier)
    # EMS Actuators: Inlet T & RH, sensible and latent gains to the space
    tamb_act_actuator = Model.add_ems_actuator(
      name: "#{obj_name} Tamb act",
      model_object: hpwh_tamb,
      comp_type_and_control: EPlus::EMSActuatorScheduleConstantValue
    )

    rhamb_act_actuator = Model.add_ems_actuator(
      name: "#{obj_name} RHamb act",
      model_object: hpwh_rhamb,
      comp_type_and_control: EPlus::EMSActuatorScheduleConstantValue
    )

    if not loc_space.nil? # If located in space
      # Add in other equipment objects for sensible/latent gains
      hpwh_sens = Model.add_other_equipment(
        model,
        name: "#{obj_name} sens",
        end_use: nil,
        space: loc_space,
        design_level: 0,
        frac_radiant: 0,
        frac_latent: 0,
        frac_lost: 0,
        schedule: model.alwaysOnDiscreteSchedule,
        fuel_type: nil
      )
      sens_act_actuator = Model.add_ems_actuator(
        name: "#{hpwh_sens.name} act",
        model_object: hpwh_sens,
        comp_type_and_control: EPlus::EMSActuatorOtherEquipmentPower
      )

      hpwh_lat = Model.add_other_equipment(
        model,
        name: "#{obj_name} lat",
        end_use: nil,
        space: loc_space,
        design_level: 0,
        frac_radiant: 0,
        frac_latent: 1,
        frac_lost: 0,
        schedule: model.alwaysOnDiscreteSchedule,
        fuel_type: nil
      )
      lat_act_actuator = Model.add_ems_actuator(
        name: "#{hpwh_lat.name} act",
        model_object: hpwh_lat,
        comp_type_and_control: EPlus::EMSActuatorOtherEquipmentPower
      )
    end

    # EMS Sensors: HP sens and latent loads, tank losses, fan power
    tl_sensor = Model.add_ems_sensor(
      model,
      name: "#{obj_name} tl",
      output_var_or_meter_name: 'Water Heater Heat Loss Rate',
      key_name: tank.name
    )

    sens_cool_sensor = Model.add_ems_sensor(
      model,
      name: "#{obj_name} sens cool",
      output_var_or_meter_name: 'Cooling Coil Sensible Cooling Rate',
      key_name: coil.name
    )

    lat_cool_sensor = Model.add_ems_sensor(
      model,
      name: "#{obj_name} lat cool",
      output_var_or_meter_name: 'Cooling Coil Latent Cooling Rate',
      key_name: coil.name
    )

    fan_power_sensor = Model.add_ems_sensor(
      model,
      name: "#{obj_name} fan pwr",
      output_var_or_meter_name: 'Fan Electricity Rate',
      key_name: fan.name
    )

    hpwh_zone_heat_gain_program = Model.add_ems_program(
      model,
      name: "#{obj_name} InletAir"
    )
    hpwh_zone_heat_gain_program.addLine("Set #{tamb_act_actuator.name} = #{amb_temp_sensor.name}")
    # Average relative humidity for mf spaces: other multifamily buffer space & other heated space
    hpwh_zone_heat_gain_program.addLine("Set #{rhamb_act_actuator.name} = 0")
    amb_rh_sensors.each do |amb_rh_sensor|
      hpwh_zone_heat_gain_program.addLine("Set #{rhamb_act_actuator.name} = #{rhamb_act_actuator.name} + (#{amb_rh_sensor.name} / 100) / #{amb_rh_sensors.size}")
    end
    if not loc_space.nil?
      # Sensible/latent heat gain to the space
      # Tank losses are multiplied by E+ zone multiplier, so need to compensate here
      hpwh_zone_heat_gain_program.addLine("Set #{sens_act_actuator.name} = (0 - #{sens_cool_sensor.name} - (#{tl_sensor.name} + #{fan_power_sensor.name})) / #{unit_multiplier}")
      hpwh_zone_heat_gain_program.addLine("Set #{lat_act_actuator.name} = (0 - #{lat_cool_sensor.name}) / #{unit_multiplier}")
    end
    return hpwh_zone_heat_gain_program
  end

  # Adds an EMS program to control the HPWH upper and lower elements.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param obj_name [String] Name for the OpenStudio object
  # @param water_heating_system [HPXML::WaterHeatingSystem] The HPXML water heating system of interest
  # @param amb_temp_sensor [OpenStudio::Model::EnergyManagementSystemSensor] HPWH ambient temperature sensor
  # @param hpwh_top_element_sp [OpenStudio::Model::ScheduleConstant] HPWH top element setpoint schedule
  # @param hpwh_bottom_element_sp [OpenStudio::Model::ScheduleConstant] HPWH bottom element setpoint schedule
  # @param min_temp [Double] Minimum temperature for compressor operation (F)
  # @param max_temp [Double] Maximum temperature for compressor operation (F)
  # @param sensted_setpoint_schedule [OpenStudio::Model::ScheduleConstant or OpenStudio::Model::ScheduleRuleset] Setpoint temperature schedule (sensed)
  # @param control_setpoint_schedule [OpenStudio::Model::ScheduleConstant or OpenStudio::Model::ScheduleRuleset] Setpoint temperature schedule (controlled)
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [OpenStudio::Model::EnergyManagementSystemProgram] The HPWH control program
  def self.apply_hpwh_control_program(runner, model, obj_name, water_heating_system, amb_temp_sensor, hpwh_top_element_sp, hpwh_bottom_element_sp, min_temp, max_temp, sensted_setpoint_schedule, control_setpoint_schedule, schedules_file)
    # Lower element is enabled if the ambient air temperature prevents the HP from running
    leschedoverride_actuator = Model.add_ems_actuator(
      name: "#{obj_name} LESchedOverride",
      model_object: hpwh_bottom_element_sp,
      comp_type_and_control: EPlus::EMSActuatorScheduleConstantValue
    )

    # Upper element is enabled unless mode is HP_only
    ueschedoverride_actuator = Model.add_ems_actuator(
      name: "#{obj_name} UESchedOverride",
      model_object: hpwh_top_element_sp,
      comp_type_and_control: EPlus::EMSActuatorScheduleConstantValue
    )

    # Actuator for setpoint schedule
    if control_setpoint_schedule.to_ScheduleConstant.is_initialized
      comp_type_and_control = EPlus::EMSActuatorScheduleConstantValue
    elsif control_setpoint_schedule.to_ScheduleRuleset.is_initialized
      comp_type_and_control = EPlus::EMSActuatorScheduleYearValue
    end
    hpwhschedoverride_actuator = Model.add_ems_actuator(
      name: "#{obj_name} HPWHSchedOverride",
      model_object: control_setpoint_schedule,
      comp_type_and_control: comp_type_and_control
    )

    # EMS for the HPWH control logic
    t_set_sensor = Model.add_ems_sensor(
      model,
      name: "#{obj_name} T_set",
      output_var_or_meter_name: 'Schedule Value',
      key_name: sensted_setpoint_schedule.name
    )

    op_mode_schedule = nil
    if not schedules_file.nil?
      op_mode_schedule = schedules_file.create_schedule_file(model, col_name: SchedulesFile::Columns[:WaterHeaterOperatingMode].name, schedule_type_limits_name: EPlus::ScheduleTypeLimitsFraction)
    end

    # Sensor on op_mode_schedule
    if not op_mode_schedule.nil?
      op_mode_sensor = Model.add_ems_sensor(
        model,
        name: "#{obj_name} op_mode",
        output_var_or_meter_name: 'Schedule Value',
        key_name: op_mode_schedule.name
      )

      if not water_heating_system.operating_mode.nil?
        runner.registerWarning("Both '#{SchedulesFile::Columns[:WaterHeaterOperatingMode].name}' schedule file and operating mode provided; the latter will be ignored.")
      end
    end

    t_offset = 9.0 # C
    min_temp_c = UnitConversions.convert(min_temp, 'F', 'C').round(2)
    max_temp_c = UnitConversions.convert(max_temp, 'F', 'C').round(2)

    hpwh_ctrl_program = Model.add_ems_program(
      model,
      name: "#{obj_name} Control"
    )
    hpwh_ctrl_program.addLine("Set #{hpwhschedoverride_actuator.name} = #{t_set_sensor.name}")
    # If in HP only mode: still enable elements if ambient temperature is out of bounds, otherwise disable elements
    if water_heating_system.operating_mode == HPXML::WaterHeaterOperatingModeHeatPumpOnly
      hpwh_ctrl_program.addLine("If (#{amb_temp_sensor.name}<#{min_temp_c}) || (#{amb_temp_sensor.name}>#{max_temp_c})")
      hpwh_ctrl_program.addLine("  Set #{leschedoverride_actuator.name} = #{t_set_sensor.name}")
      hpwh_ctrl_program.addLine("  Set #{ueschedoverride_actuator.name} = #{t_set_sensor.name}")
      hpwh_ctrl_program.addLine('Else')
      hpwh_ctrl_program.addLine("  Set #{leschedoverride_actuator.name} = 0")
      hpwh_ctrl_program.addLine("  Set #{ueschedoverride_actuator.name} = 0")
      hpwh_ctrl_program.addLine('EndIf')
    else
      # First, check if ambient temperature is out of bounds for HP operation, if so enable lower element
      hpwh_ctrl_program.addLine("If (#{amb_temp_sensor.name}<#{min_temp_c}) || (#{amb_temp_sensor.name}>#{max_temp_c})")
      hpwh_ctrl_program.addLine("  Set #{ueschedoverride_actuator.name} = #{t_set_sensor.name}")
      hpwh_ctrl_program.addLine("  Set #{leschedoverride_actuator.name} = #{t_set_sensor.name}")
      hpwh_ctrl_program.addLine('Else')
      hpwh_ctrl_program.addLine("  Set #{ueschedoverride_actuator.name} = #{t_set_sensor.name} - #{t_offset}")
      hpwh_ctrl_program.addLine("  Set #{leschedoverride_actuator.name} = 0")
      hpwh_ctrl_program.addLine('EndIf')
      # Scheduled operating mode: if in HP only mode, disable both elements (this will override prior logic)
      if not op_mode_schedule.nil?
        hpwh_ctrl_program.addLine("If #{op_mode_sensor.name} == 1")
        hpwh_ctrl_program.addLine("  Set #{ueschedoverride_actuator.name} = 0")
        hpwh_ctrl_program.addLine('Else')
        hpwh_ctrl_program.addLine("  Set #{ueschedoverride_actuator.name} = #{t_set_sensor.name} - #{t_offset}")
        hpwh_ctrl_program.addLine('EndIf')
      end
    end
    return hpwh_ctrl_program
  end

  # Sets the tank losses for a stratified water heater tank.
  #
  # @param tank [OpenStudio::Model::WaterHeaterStratified] The stratified tank
  # @param tank_u [Double] The heat loss U-factor (Btu/hr-ft^2-F)
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @return [nil]
  def self.apply_stratified_tank_losses(tank, tank_u, unit_multiplier)
    node_ua = [0] * 12 # Max number of nodes in E+ stratified tank model
    if unit_multiplier == 1
      tank.setUniformSkinLossCoefficientperUnitAreatoAmbientTemperature(UnitConversions.convert(tank_u, 'Btu/(hr*ft^2*F)', 'W/(m^2*K)'))
    else
      tank.setUniformSkinLossCoefficientperUnitAreatoAmbientTemperature(0)

      # Calculate UA for each node; this is needed to accommodate unit multipliers where
      # the surface area for each node is not scaled proportionally.
      vol_tank = UnitConversions.convert(tank.tankVolume.get, 'm^3', 'gal')
      h_tank = UnitConversions.convert(tank.tankHeight.get, 'm', 'ft')

      # Calculate areas for tank w/o unit multiplier
      tank_a, side_a = calc_tank_areas(vol_tank / unit_multiplier, h_tank)
      top_a = (tank_a - side_a) / 2.0
      num_nodes = tank.numberofNodes

      # Calculate desired UA for each node
      for node_num in 0..num_nodes - 1
        # These node area calculations are based on the E+ WaterThermalTankData::SetupStratifiedNodes() method
        node_a = side_a / num_nodes
        if (node_num == 0) || (node_num == num_nodes - 1) # Top or bottom node
          node_a += top_a
        end
        node_ua[node_num] = UnitConversions.convert(tank_u.to_f, 'Btu/(hr*ft^2*F)', 'W/(m^2*K)') * UnitConversions.convert(node_a, 'ft^2', 'm^2') * unit_multiplier
      end
    end

    tank.setNode1AdditionalLossCoefficient(node_ua[0])
    tank.setNode2AdditionalLossCoefficient(node_ua[1])
    tank.setNode3AdditionalLossCoefficient(node_ua[2])
    tank.setNode4AdditionalLossCoefficient(node_ua[3])
    tank.setNode5AdditionalLossCoefficient(node_ua[4])
    tank.setNode6AdditionalLossCoefficient(node_ua[5])
    tank.setNode7AdditionalLossCoefficient(node_ua[6])
    tank.setNode8AdditionalLossCoefficient(node_ua[7])
    tank.setNode9AdditionalLossCoefficient(node_ua[8])
    tank.setNode10AdditionalLossCoefficient(node_ua[9])
    tank.setNode11AdditionalLossCoefficient(node_ua[10])
    tank.setNode12AdditionalLossCoefficient(node_ua[11])
  end

  # Gets the combination boiler and plant loop OpenStudio objects associated with the HPXML water heating system.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param heating_source_id [String] ID of the HPXML water heating system
  # @return [Array<OpenStudio::Model::BoilerHotWater, OpenStudio::Model::PlantLoop>] Boiler object, PlantLoop object
  def self.get_combi_boiler_and_plant_loop(model, heating_source_id)
    # Search for the right boiler OS object
    boiler_hw = nil
    plant_loop_hw = nil
    model.getBoilerHotWaters.each do |bhw|
      sys_id = bhw.additionalProperties.getFeatureAsString('HPXML_ID')
      next unless sys_id.is_initialized && sys_id.get == heating_source_id

      plant_loop = bhw.plantLoop.get
      plant_loop_hw = plant_loop.clone(model).to_PlantLoop.get

      # set pump power for water heating to zero
      plant_loop_hw.supplyComponents.each do |comp|
        if comp.to_BoilerHotWater.is_initialized
          boiler_hw = comp.to_BoilerHotWater.get
        end
        next unless comp.to_PumpVariableSpeed.is_initialized

        pump_hw = comp.to_PumpVariableSpeed.get
        pump_hw.setRatedPowerConsumption(0.0)
      end
    end
    return boiler_hw, plant_loop_hw
  end

  # Adds a desuperheater for the given HPXML water heating system to the OpenStudio model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param water_heating_system [HPXML::WaterHeatingSystem] The HPXML water heating system of interest
  # @param tank [OpenStudio::Model::WaterHeaterMixed or OpenStudio::Model::WaterHeaterStratified] The water heater tank
  # @param loc_space [OpenStudio::Model::Space] The space where the water heater is located
  # @param loc_schedule [OpenStudio::Model::ScheduleConstant] The temperature schedule, if not located in a space
  # @param plant_loop [OpenStudio::Model::PlantLoop] The DHW plant loop
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @return [nil]
  def self.apply_desuperheater(runner, model, water_heating_system, tank, loc_space, loc_schedule, plant_loop, unit_multiplier)
    return unless water_heating_system.uses_desuperheater

    # Get the HVAC cooling coil for the desuperheater
    desuperheater_clg_coil = nil
    (model.getCoilCoolingDXSingleSpeeds +
     model.getCoilCoolingDXMultiSpeeds +
     model.getCoilCoolingWaterToAirHeatPumpEquationFits +
     model.getCoilCoolingWaterToAirHeatPumpVariableSpeedEquationFits).each do |clg_coil|
      sys_id = clg_coil.additionalProperties.getFeatureAsString('HPXML_ID')
      if sys_id.is_initialized && sys_id.get == water_heating_system.related_hvac_idref
        desuperheater_clg_coil = clg_coil
      end
    end
    if desuperheater_clg_coil.nil?
      fail "RelatedHVACSystem '#{water_heating_system.related_hvac_idref}' for water heating system '#{water_heating_system.id}' is not currently supported for desuperheaters."
    end

    reclaimed_efficiency = 0.25 # default
    desuperheater_name = "#{tank.name} desuperheater"

    # create a storage tank
    vol = 50.0
    storage_vol_actual = calc_storage_tank_actual_vol(vol, nil)
    tank_ua = 6.0 # Btu/hr-F, tank ua calculated based on 1.0 standby_loss and 50gal nominal vol
    storage_tank_name = "#{tank.name} storage tank"

    if water_heating_system.temperature.nil?
      fail "Detailed setpoints for water heating system '#{water_heating_system.id}' is not currently supported for desuperheaters."
    else
      # reduce tank setpoint to enable desuperheater setpoint at t_set
      t_set_c = get_t_set_c(water_heating_system.temperature - 5.0, HPXML::WaterHeaterTypeStorage)
    end

    storage_tank = apply_water_heater(runner, model,
                                      name: storage_tank_name,
                                      act_vol: storage_vol_actual,
                                      t_set_c: t_set_c,
                                      loc_space: loc_space,
                                      loc_schedule: loc_schedule,
                                      tank_ua: tank_ua,
                                      is_dsh_storage: true,
                                      unit_multiplier: unit_multiplier)

    plant_loop.addSupplyBranchForComponent(storage_tank)
    tank.addToNode(storage_tank.supplyOutletModelObject.get.to_Node.get)

    # Create a schedule for desuperheater
    # Preheat tank desuperheater setpoint set to be the same as main water heater
    dsh_setpoint = get_t_set_c(water_heating_system.temperature, HPXML::WaterHeaterTypeStorage)
    new_schedule = Model.add_schedule_constant(
      model,
      name: "#{desuperheater_name} setpoint schedule",
      value: dsh_setpoint,
      limits: EPlus::ScheduleTypeLimitsTemperature
    )

    # Create desuperheater object
    desuperheater = OpenStudio::Model::CoilWaterHeatingDesuperheater.new(model, new_schedule)
    desuperheater.setName(desuperheater_name)
    desuperheater.setMaximumInletWaterTemperatureforHeatReclaim(100)
    desuperheater.setDeadBandTemperatureDifference(0.2)
    desuperheater.setRatedHeatReclaimRecoveryEfficiency(reclaimed_efficiency)
    desuperheater.addToHeatRejectionTarget(storage_tank)
    desuperheater.setWaterPumpPower(0) # FUTURE: Desuperheater pump power?
    desuperheater.setHeatingSource(desuperheater_clg_coil)
    desuperheater.setWaterFlowRate(0.0001 * unit_multiplier)
    desuperheater.additionalProperties.setFeature('HPXML_ID', water_heating_system.id) # Used by reporting measure
  end

  # Calculates an Energy Factor (EF) from a Uniform Energy Factor (UEF).
  #
  # Source: RESNET's Interpretation on Water Heater UEF
  # https://www.resnet.us/wp-content/uploads/Interpretation-301-2014-012-Water-Heater-UEF.pdf
  # Note that this is a regression based on products on the market, not a conversion.
  #
  # @param water_heating_system [HPXML::WaterHeatingSystem] The HPXML water heating system of interest
  # @return [Double] The Energy Factor
  def self.calc_ef_from_uef(water_heating_system)
    if water_heating_system.fuel_type == HPXML::FuelTypeElectricity
      case water_heating_system.water_heater_type
      when HPXML::WaterHeaterTypeStorage
        return [2.4029 * water_heating_system.uniform_energy_factor - 1.2844, 0.96].min
      when HPXML::WaterHeaterTypeTankless
        return water_heating_system.uniform_energy_factor
      when HPXML::WaterHeaterTypeHeatPump
        return 1.2101 * water_heating_system.uniform_energy_factor - 0.6052
      end
    else # Fuel
      case water_heating_system.water_heater_type
      when HPXML::WaterHeaterTypeStorage
        return 0.9066 * water_heating_system.uniform_energy_factor + 0.0711
      when HPXML::WaterHeaterTypeTankless
        return water_heating_system.uniform_energy_factor
      end
    end
    fail 'Unexpected water heater.'
  end

  # Calculates water heater storage tank surface areas.
  #
  # @param act_vol [Double] Actual tank volume (gal)
  # @param height [Double] Tank height (ft)
  # @return [Array<Double, Double>] Tank total surface area (ft), Tank side surface area (ft)
  def self.calc_tank_areas(act_vol, height = nil)
    if height.nil?
      height = DefaultTankHeight
    end
    diameter = 2.0 * (UnitConversions.convert(act_vol, 'gal', 'ft^3') / (height * Math::PI))**0.5 # feet
    top_a = Math::PI * diameter**2.0 / 4.0 # sqft
    side_a = Math::PI * diameter * height # sqft
    tank_a = 2.0 * top_a + side_a # sqft

    return tank_a, side_a
  end

  # Calculates tank losses for the combination boiler given its standby loss value.
  #
  # @param act_vol [Double] Actual tank volume (gal)
  # @param water_heating_system [HPXML::WaterHeatingSystem] The HPXML water heating system of interest
  # @param side_a [Double] Tank side surface area (ft^3)
  # @param solar_fraction [Double] Portion of hot water load served by an attached solar thermal system
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @return [Double] Tank loss UA factor (Btu/hr-F)
  def self.calc_combi_tank_losses(act_vol, water_heating_system, side_a, solar_fraction, nbeds = nil)
    standby_loss_units = water_heating_system.standby_loss_units
    standby_loss_value = water_heating_system.standby_loss_value

    if not [HPXML::UnitsDegFPerHour].include? standby_loss_units
      fail "Unexpected standby loss units '#{standby_loss_units}' for indirect water heater. Should be '#{HPXML::UnitsDegFPerHour}'."
    end

    # Test conditions
    cp = 0.999 # Btu/lb-F
    rho = 8.216 # lb/gal
    t_amb = 70.0 # F
    t_tank_avg = 135.0 # F, Test begins at 137-138F stop at 133F

    # UA calculation
    q = standby_loss_value * cp * act_vol * rho # Btu/hr
    ua = q / (t_tank_avg - t_amb) # Btu/hr-F

    # jacket
    ua = apply_tank_jacket(water_heating_system, ua, side_a)

    # shared losses
    ua = apply_shared_adjustment(water_heating_system, ua, nbeds) if !nbeds.nil?

    ua *= (1.0 - solar_fraction)
    return ua
  end

  # Adds an EMS program to increase/decrease the energy consumption of the water heater based on
  # the energy consumption adjustment factor (EC_adj).
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param water_heater [OpenStudio::Model::WaterHeaterMixed or OpenStudio::Model::WaterHeaterStratified or OpenStudio::Model::WaterHeaterHeatPumpWrappedCondenser] The water heater object
  # @param loc_space [OpenStudio::Model::Space] The space where the water heater is located
  # @param water_heating_system [HPXML::WaterHeatingSystem] The HPXML water heating system of interest
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @param combi_boiler [OpenStudio::Model::BoilerHotWater] The boiler object if the HPXML water heating system is a combi boiler
  # @return [nil]
  def self.apply_ec_adj_program(model, hpxml_bldg, water_heater, loc_space, water_heating_system, unit_multiplier, combi_boiler = nil)
    ec_adj = get_dist_energy_consumption_adjustment(hpxml_bldg, water_heating_system)
    adjustment = ec_adj - 1.0

    if loc_space.nil? # WH is not in a zone, set the other equipment to be in a random space
      loc_space = model.getSpaces[0]
    end

    if water_heating_system.water_heater_type == HPXML::WaterHeaterTypeHeatPump
      tank = water_heater.tank
    else
      tank = water_heater
    end
    if [HPXML::WaterHeaterTypeCombiStorage, HPXML::WaterHeaterTypeCombiTankless].include? water_heating_system.water_heater_type
      fuel_type = water_heating_system.related_hvac_system.heating_system_fuel
    else
      fuel_type = water_heating_system.fuel_type
    end

    # Add an other equipment object for water heating that will get actuated, has a small initial load but gets overwritten by EMS
    cnt = model.getOtherEquipments.count { |e| e.endUseSubcategory.start_with? Constants::ObjectTypeWaterHeaterAdjustment } # Ensure unique meter for each water heater
    ec_adj_object = Model.add_other_equipment(
      model,
      name: "#{Constants::ObjectTypeWaterHeaterAdjustment}#{cnt + 1}",
      end_use: "#{Constants::ObjectTypeWaterHeaterAdjustment}#{cnt + 1}",
      space: loc_space,
      design_level: 0.01,
      frac_radiant: 0,
      frac_latent: 0,
      frac_lost: 1,
      schedule: model.alwaysOnDiscreteSchedule,
      fuel_type: fuel_type
    )
    ec_adj_object.additionalProperties.setFeature('HPXML_ID', water_heating_system.id) # Used by reporting measure

    # EMS for calculating the EC_adj

    # Sensors
    if [HPXML::WaterHeaterTypeCombiStorage, HPXML::WaterHeaterTypeCombiTankless].include? water_heating_system.water_heater_type
      ec_adj_sensor_boiler = Model.add_ems_sensor(
        model,
        name: "#{combi_boiler.name} energy",
        output_var_or_meter_name: "Boiler #{EPlus.fuel_type(fuel_type)} Rate",
        key_name: combi_boiler.name
      )
    else
      ec_adj_sensor = Model.add_ems_sensor(
        model,
        name: "#{tank.name} energy",
        output_var_or_meter_name: "Water Heater #{EPlus.fuel_type(fuel_type)} Rate",
        key_name: tank.name
      )
      if water_heating_system.water_heater_type == HPXML::WaterHeaterTypeHeatPump
        ec_adj_hp_sensor = Model.add_ems_sensor(
          model,
          name: "#{water_heater.dXCoil.name} energy",
          output_var_or_meter_name: 'Cooling Coil Water Heating Electricity Rate',
          key_name: water_heater.dXCoil.name
        )
        ec_adj_fan_sensor = Model.add_ems_sensor(
          model,
          name: "#{water_heater.fan.name} energy",
          output_var_or_meter_name: 'Fan Electricity Rate',
          key_name: water_heater.fan.name
        )
      end
    end

    ec_adj_oncyc_sensor = Model.add_ems_sensor(
      model,
      name: "#{tank.name} on cycle parasitic",
      output_var_or_meter_name: 'Water Heater On Cycle Parasitic Electricity Rate',
      key_name: tank.name
    )
    ec_adj_offcyc_sensor = Model.add_ems_sensor(
      model,
      name: "#{tank.name} off cycle parasitic",
      output_var_or_meter_name: 'Water Heater Off Cycle Parasitic Electricity Rate',
      key_name: tank.name
    )

    # Actuators
    ec_adj_actuator = Model.add_ems_actuator(
      name: "#{water_heater.name} ec adj act",
      model_object: ec_adj_object,
      comp_type_and_control: EPlus::EMSActuatorOtherEquipmentPower
    )

    # Program
    ec_adj_program = Model.add_ems_program(
      model,
      name: "#{water_heater.name} EC_adj"
    )
    ec_adj_program.addLine('If WarmupFlag == 0') # Prevent a non-zero adjustment in the first hour because of the warmup period
    if [HPXML::WaterHeaterTypeCombiStorage, HPXML::WaterHeaterTypeCombiTankless].include? water_heating_system.water_heater_type
      ec_adj_program.addLine("Set dhw_e_cons = #{ec_adj_oncyc_sensor.name} + #{ec_adj_offcyc_sensor.name}")
      ec_adj_program.addLine("If #{ec_adj_sensor_boiler.name} > 0")
      ec_adj_program.addLine("  Set dhw_e_cons = dhw_e_cons + #{ec_adj_sensor_boiler.name}")
      ec_adj_program.addLine('EndIf')
    elsif water_heating_system.water_heater_type == HPXML::WaterHeaterTypeHeatPump
      ec_adj_program.addLine("Set dhw_e_cons = #{ec_adj_sensor.name} + #{ec_adj_oncyc_sensor.name} + #{ec_adj_offcyc_sensor.name} + #{ec_adj_hp_sensor.name} + #{ec_adj_fan_sensor.name}")
    else
      ec_adj_program.addLine("Set dhw_e_cons = #{ec_adj_sensor.name} + #{ec_adj_oncyc_sensor.name} + #{ec_adj_offcyc_sensor.name}")
    end
    # Since the water heater has been multiplied by the unit_multiplier, and this OtherEquipment object will be adding
    # load to a thermal zone with an E+ multiplier, we would double-count the multiplier if we didn't divide by it here.
    ec_adj_program.addLine("Set #{ec_adj_actuator.name} = #{adjustment} * dhw_e_cons / #{unit_multiplier}")
    ec_adj_program.addLine('EndIf')

    # Program Calling Manager
    Model.add_ems_program_calling_manager(
      model,
      name: "#{water_heater.name} EC_adj ProgramManager",
      calling_point: 'EndOfSystemTimestepBeforeHVACReporting',
      ems_programs: [ec_adj_program]
    )
  end

  # Gets the water heater setpoint temperature deadband.
  #
  # @param wh_type [String] Type of water heater (HPXML::WaterHeaterTypeXXX)
  # @return [Double] Temperature deadband (C)
  def self.get_deadband(wh_type)
    if [HPXML::WaterHeaterTypeStorage, HPXML::WaterHeaterTypeCombiStorage].include? wh_type
      return 2.0
    else
      return 0.0
    end
  end

  # Calculates the water heater actual volume from its nominal/rated volume.
  #
  # @param vol [Double] Nominal tank volume (gal)
  # @param fuel [String] Water heater fuel type (HPXML::FuelTypeXXX)
  # @return [Double] Actual tank volume (gal)
  def self.calc_storage_tank_actual_vol(vol, fuel)
    if fuel.nil?
      act_vol = 0.95 * vol # indirect tank
    else
      if fuel == HPXML::FuelTypeElectricity
        act_vol = 0.9 * vol
      else
        act_vol = 0.95 * vol
      end
    end
    return act_vol
  end

  # Disaggregates the water heater's (uniform) energy factor into tank losses and burner efficiency.
  #
  # IF using UEF:
  #   Calculations based on the Uniform Energy Factor, First Hour Rating, and Recovery Efficiency of the tank
  #   Source: Maguire and Roberts 2020 - https://www.nrel.gov/docs/fy21osti/71633.pdf
  # If using EF:
  #   Calculations based on the Energy Factor and Recovery Efficiency of the tank
  #   Using the same approach as in Maguire and Roberts 2020, but with EF specific load and temperatures
  #
  # @param act_vol [Double] Actual tank volume (gal)
  # @param water_heating_system [HPXML::WaterHeatingSystem] The HPXML water heating system of interest
  # @param solar_fraction [Double] Portion of hot water load served by an attached solar thermal system
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @return [Array<Double, Double, Double>] Tank loss U-factor (Btu/hr-ft^2-F), tank loss UA factor (Btu/hr-F), burner efficiency (frac)
  def self.disaggregate_tank_losses_and_burner_efficiency(act_vol, water_heating_system, solar_fraction, nbeds)
    if water_heating_system.water_heater_type == HPXML::WaterHeaterTypeTankless
      if not water_heating_system.energy_factor.nil?
        eta_c = water_heating_system.energy_factor * water_heating_system.performance_adjustment
      elsif not water_heating_system.uniform_energy_factor.nil?
        eta_c = water_heating_system.uniform_energy_factor * water_heating_system.performance_adjustment
      end
      ua = 0.0
      tank_a = 1.0
    else
      density = 8.2938 # lb/gal
      cp = 1.0007 # Btu/lb-F
      t_in = 58.0 # F
      t_env = 67.5 # F

      if not water_heating_system.energy_factor.nil?
        t = 135.0 # F
        volume_drawn = 64.3 # gal/day
      elsif not water_heating_system.uniform_energy_factor.nil?
        t = 125.0 # F
        case water_heating_system.usage_bin
        when HPXML::WaterHeaterUsageBinVerySmall
          volume_drawn = 10.0 # gal
        when HPXML::WaterHeaterUsageBinLow
          volume_drawn = 38.0 # gal
        when HPXML::WaterHeaterUsageBinMedium
          volume_drawn = 55.0 # gal
        when HPXML::WaterHeaterUsageBinHigh
          volume_drawn = 84.0 # gal
        end
      end

      draw_mass = volume_drawn * density # lb
      q_load = draw_mass * cp * (t - t_in) # Btu/day
      pow = water_heating_system.heating_capacity # Btu/h
      tank_a, side_a = calc_tank_areas(act_vol)
      if water_heating_system.fuel_type != HPXML::FuelTypeElectricity
        if not water_heating_system.energy_factor.nil?
          ua = (water_heating_system.recovery_efficiency / water_heating_system.energy_factor - 1.0) / ((t - t_env) * (24.0 / q_load - 1.0 / (pow * water_heating_system.energy_factor))) # Btu/hr-F
          eta_c = (water_heating_system.recovery_efficiency + ua * (t - t_env) / pow) # conversion efficiency is supposed to be calculated with initial tank ua
        elsif not water_heating_system.uniform_energy_factor.nil?
          ua = ((water_heating_system.recovery_efficiency / water_heating_system.uniform_energy_factor) - 1.0) / ((t - t_env) * (24.0 / q_load) - ((t - t_env) / (pow * water_heating_system.uniform_energy_factor))) # Btu/hr-F
          eta_c = water_heating_system.recovery_efficiency + ((ua * (t - t_env)) / pow) # conversion efficiency is slightly larger than recovery efficiency
        end
      else # is Electric
        f_low = 0.2 # Assumed fraction of water volume below lower element, assumed to be unheated
        f_high = 1.0 - f_low # Fraction of water volume above lower element
        if not water_heating_system.energy_factor.nil?
          ua = q_load * (1.0 / water_heating_system.energy_factor - 1.0) / ((24.0 * (t - t_env)) * (f_high + f_low * ((t_in - t_env) / (t - t_env)))) # Btu/hr-F
        elsif not water_heating_system.uniform_energy_factor.nil?
          ua = q_load * (1.0 / water_heating_system.uniform_energy_factor - 1.0) / ((24.0 * (t - t_env)) * (f_high + f_low * ((t_in - t_env) / (t - t_env)))) # Btu/hr-F
        end
        eta_c = 1.0
      end
      ua = apply_tank_jacket(water_heating_system, ua, side_a)
    end
    ua *= (1.0 - solar_fraction)
    ua = apply_shared_adjustment(water_heating_system, ua, nbeds) # shared losses
    u = ua / tank_a # Btu/hr-ft^2-F
    if eta_c > 1.0
      fail 'A water heater heat source (either burner or element) efficiency of > 1 has been calculated, double check water heater inputs.'
    end
    if ua < 0.0
      fail 'A negative water heater standby loss coefficient (UA) was calculated, double check water heater inputs.'
    end

    return u, ua, eta_c
  end

  # Calculates an adjustment to the tank loss UA factor to account for the presence
  # of a water heater jacket (insulation).
  #
  # @param water_heating_system [HPXML::WaterHeatingSystem] The HPXML water heating system of interest
  # @param ua [Double] Tank loss UA factor (Btu/hr-F)
  # @param side_a [Double] Tank side surface area (ft^3)
  # @return [Double] Adjusted tank loss UA factor (Btu/hr-F)
  def self.apply_tank_jacket(water_heating_system, ua, side_a)
    if not water_heating_system.jacket_r_value.nil?
      skin_insulation_R = 5.0 # R5
      if water_heating_system.fuel_type.nil? # indirect water heater, etc. Assume 2 inch skin insulation
        skin_insulation_t = 2.0 # inch
      elsif water_heating_system.fuel_type != HPXML::FuelTypeElectricity
        ef = water_heating_system.energy_factor
        if ef.nil?
          ef = calc_ef_from_uef(water_heating_system)
        end
        if ef < 0.7
          skin_insulation_t = 1.0 # inch, assumed
        else
          skin_insulation_t = 2.0 # inch, assumed
        end
      else # electric
        skin_insulation_t = 2.0 # inch, assumed
      end
      # water heater wrap calculation based on:
      # Modeling Water Heat Wraps in BEopt DRAFT Technical Note
      # Authors:  Ben Polly and Jay Burch (NREL)
      u_pre_skin = 1.0 / (skin_insulation_t * skin_insulation_R + 1.0 / 1.3 + 1.0 / 52.8) # Btu/hr-ft^2-F = (1 / hout + kins / tins + t / hin)^-1
      ua_adj = ua - water_heating_system.jacket_r_value / (1.0 / u_pre_skin + water_heating_system.jacket_r_value) * u_pre_skin * side_a
    else
      ua_adj = ua
    end
    return ua_adj
  end

  # Calculates an adjustment to the tank loss UA factor for a shared water heater, in which we
  # apportion the tank losses to the dwelling unit.
  #
  # @param water_heating_system [HPXML::WaterHeatingSystem] The HPXML water heating system of interest
  # @param ua [Double] Tank loss UA factor (Btu/hr-F)
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @return [Double] Adjusted tank loss UA factor (Btu/hr-F)
  def self.apply_shared_adjustment(water_heating_system, ua, nbeds)
    if water_heating_system.is_shared_system
      return ua * [nbeds.to_f, 1.0].max / water_heating_system.number_of_bedrooms_served.to_f
    else
      return ua
    end
  end

  # Adds a water heater object to the OpenStudio model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param water_heating_system [HPXML::WaterHeatingSystem] The HPXML water heating system of interest
  # @param act_vol [Double] Actual tank volume (gal)
  # @param t_set_c [Double] Water heater setpoint including deadband (C)
  # @param loc_space [OpenStudio::Model::Space] The space where the water heater is located
  # @param loc_schedule [OpenStudio::Model::ScheduleConstant] The temperature schedule, if not located in a space
  # @param tank_u [Double] Tank loss coefficient (Btu/hr-ft^2-F)
  # @param tank_ua [Double] Tank loss UA factor (Btu/hr-F)
  # @param tank_eta_c [Double] Tank burner efficiency (frac)
  # @param is_dsh_storage [Boolean] True if this is a desuperheater storage tank
  # @param is_combi [Boolean] True if this is a combination boiler
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @return [OpenStudio::Model::WaterHeaterMixed or OpenStudio::Model::WaterHeaterStratified] Water heater object
  def self.apply_water_heater(runner, model, name:, water_heating_system: nil, act_vol:, t_set_c: nil, loc_space:, loc_schedule: nil, tank_u: nil, tank_ua:, tank_eta_c: nil, is_dsh_storage: false, is_combi: false, schedules_file: nil, unavailable_periods: [], unit_multiplier: 1.0)
    # storage tank doesn't require water_heating_system class argument being passed
    if is_dsh_storage || is_combi
      fuel = nil
      cap = 0.0
      if is_dsh_storage
        tank_type = HPXML::WaterHeaterTypeStorage
      else
        tank_type = water_heating_system.water_heater_type
      end
    else
      fuel = water_heating_system.fuel_type
      tank_type = water_heating_system.water_heater_type
      cap = water_heating_system.heating_capacity / 1000.0
      tank_model_type = water_heating_system.tank_model_type
    end

    tank_ua *= unit_multiplier
    cap *= unit_multiplier
    act_vol *= unit_multiplier

    if tank_model_type == HPXML::WaterHeaterTankModelTypeStratified
      h_tank = UnitConversions.convert(DefaultTankHeight, 'ft', 'm')

      # Add a WaterHeater:Stratified to the model
      water_heater = OpenStudio::Model::WaterHeaterStratified.new(model)
      water_heater.setEndUseSubcategory('Domestic Hot Water')
      water_heater.setTankVolume(UnitConversions.convert(act_vol, 'gal', 'm^3'))
      water_heater.setTankHeight(h_tank)
      water_heater.setMaximumTemperatureLimit(90)
      water_heater.setHeaterPriorityControl('MasterSlave')
      water_heater.setHeater1Capacity(UnitConversions.convert(cap, 'kBtu/hr', 'W'))
      water_heater.setHeater1Height((1.0 - (4 - 0.5) / 15) * h_tank) # in the 4th node of a 15-node tank (counting from top); height of upper element based on TRNSYS assumptions for an ERWH
      water_heater.setHeater1DeadbandTemperatureDifference(5.556)
      water_heater.setHeater2Capacity(UnitConversions.convert(cap, 'kBtu/hr', 'W'))
      water_heater.setHeater2Height((1.0 - (13 - 0.5) / 15) * h_tank) # in the 13th node of a 15-node tank (counting from top); height of upper element based on TRNSYS assumptions for an ERWH
      water_heater.setHeater2DeadbandTemperatureDifference(5.556)
      water_heater.setHeaterThermalEfficiency(1.0)
      water_heater.setNumberofNodes(12)
      water_heater.setAdditionalDestratificationConductivity(0)
      water_heater.setUseSideDesignFlowRate(UnitConversions.convert(act_vol, 'gal', 'm^3') / 60.1)
      water_heater.setSourceSideDesignFlowRate(0)
      water_heater.setSourceSideFlowControlMode('')
      water_heater.setSourceSideInletHeight((1.0 - (1 - 0.5) / 15) * h_tank) # in the 1st node of a 15-node tank (counting from top)
      water_heater.setSourceSideOutletHeight((1.0 - (15 - 0.5) / 15) * h_tank) # in the 15th node of a 15-node tank (counting from top)
      water_heater.setSkinLossFractiontoZone(1.0 / unit_multiplier) # Tank losses are multiplied by E+ zone multiplier, so need to compensate here
      water_heater.setOffCycleFlueLossFractiontoZone(1.0 / unit_multiplier)
      apply_stratified_tank_losses(water_heater, tank_u, unit_multiplier)
    else
      water_heater = OpenStudio::Model::WaterHeaterMixed.new(model)
      water_heater.setTankVolume(UnitConversions.convert(act_vol, 'gal', 'm^3'))
      water_heater.setHeaterThermalEfficiency(tank_eta_c) unless tank_eta_c.nil?
      water_heater.setMaximumTemperatureLimit(99.0)
      if [HPXML::WaterHeaterTypeTankless, HPXML::WaterHeaterTypeCombiTankless].include? tank_type
        water_heater.setHeaterControlType('Modulate')
      else
        water_heater.setHeaterControlType('Cycle')
      end
      water_heater.setDeadbandTemperatureDifference(get_deadband(tank_type))

      # Capacity, storage tank to be 0
      water_heater.setHeaterMaximumCapacity(UnitConversions.convert(cap, 'kBtu/hr', 'W'))
      water_heater.setHeaterMinimumCapacity(0.0)

      # Set fraction of heat loss from tank to ambient (vs out flue)
      # Based on lab testing done by LBNL
      skinlossfrac = 1.0
      if (not is_dsh_storage) && (water_heating_system.fuel_type != HPXML::FuelTypeElectricity) && (water_heating_system.water_heater_type == HPXML::WaterHeaterTypeStorage)
        # Fuel storage water heater
        # EF cutoffs derived from Figure 2 of http://title24stakeholders.com/wp-content/uploads/2017/10/2013_CASE-Report_High-efficiency-Water-Heater-Ready.pdf
        # FUTURE: Add an optional HPXML input for water heater type for a user to specify this (and default based on EF as below)
        ef = water_heating_system.energy_factor
        if ef.nil?
          ef = calc_ef_from_uef(water_heating_system)
        end
        if ef < 0.64
          skinlossfrac = 0.64 # Natural draft
        elsif ef < 0.77
          skinlossfrac = 0.91 # Power vent
        else
          skinlossfrac = 0.96 # Condensing
        end
      end
      water_heater.setOffCycleLossFractiontoThermalZone(skinlossfrac / unit_multiplier) # Tank losses are multiplied by E+ zone multiplier, so need to compensate here
      water_heater.setOnCycleLossFractiontoThermalZone(1.0 / unit_multiplier) # Tank losses are multiplied by E+ zone multiplier, so need to compensate here

      water_heater.setOnCycleLossCoefficienttoAmbientTemperature(UnitConversions.convert(tank_ua, 'Btu/(hr*F)', 'W/K'))
      water_heater.setOffCycleLossCoefficienttoAmbientTemperature(UnitConversions.convert(tank_ua, 'Btu/(hr*F)', 'W/K'))
    end

    apply_setpoint(runner, model, water_heater, schedules_file, t_set_c, unavailable_periods)

    if not water_heating_system.nil?
      water_heater.additionalProperties.setFeature('HPXML_ID', water_heating_system.id) # Used by reporting measure
    end
    if is_combi
      water_heater.additionalProperties.setFeature('IsCombiBoiler', true) # Used by reporting measure
    end

    water_heater.setName(name)
    water_heater.setHeaterFuelType(EPlus.fuel_type(fuel)) unless fuel.nil?
    apply_ambient_temperature(loc_space, loc_schedule, water_heater)

    # FUTURE: These are always zero right now; develop smart defaults.
    water_heater.setOffCycleParasiticFuelType(EPlus::FuelTypeElectricity)
    water_heater.setOffCycleParasiticFuelConsumptionRate(0.0)
    water_heater.setOffCycleParasiticHeatFractiontoTank(0)
    water_heater.setOnCycleParasiticFuelType(EPlus::FuelTypeElectricity)
    water_heater.setOnCycleParasiticFuelConsumptionRate(0.0)
    water_heater.setOnCycleParasiticHeatFractiontoTank(0)

    return water_heater
  end

  # Applies the ambient temperature conditions to the water heater.
  #
  # @param loc_space [OpenStudio::Model::Space] The space where the water heater is located
  # @param loc_schedule [OpenStudio::Model::ScheduleConstant] The temperature schedule, if not located in a space
  # @param water_heater [OpenStudio::Model::WaterHeaterMixed or OpenStudio::Model::WaterHeaterStratified] Water heater object
  # @return [nil]
  def self.apply_ambient_temperature(loc_space, loc_schedule, water_heater)
    if water_heater.ambientTemperatureSchedule.is_initialized
      water_heater.ambientTemperatureSchedule.get.remove
    end
    if not loc_schedule.nil? # Temperature schedule indicator
      water_heater.setAmbientTemperatureSchedule(loc_schedule)
    elsif not loc_space.nil?
      water_heater.setAmbientTemperatureIndicator('ThermalZone')
      water_heater.setAmbientTemperatureThermalZone(loc_space.thermalZone.get)
    else # Located outside
      water_heater.setAmbientTemperatureIndicator('Outdoors')
    end
  end

  # Applies the temperature setpoint to the water heater.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param water_heater [OpenStudio::Model::WaterHeaterMixed or OpenStudio::Model::WaterHeaterStratified] Water heater object
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param t_set_c [Double] Water heater setpoint including deadband (C)
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @return [nil]
  def self.apply_setpoint(runner, model, water_heater, schedules_file, t_set_c, unavailable_periods)
    setpoint_sch = nil
    if not schedules_file.nil?
      setpoint_sch = schedules_file.create_schedule_file(model, col_name: SchedulesFile::Columns[:WaterHeaterSetpoint].name)
    end
    if setpoint_sch.nil? # constant
      setpoint_sch = ScheduleConstant.new(model, Constants::ObjectTypeWaterHeaterSetpoint, t_set_c, EPlus::ScheduleTypeLimitsTemperature, unavailable_periods: unavailable_periods)
      setpoint_sch = setpoint_sch.schedule
    else
      runner.registerWarning("Both '#{SchedulesFile::Columns[:WaterHeaterSetpoint].name}' schedule file and setpoint temperature provided; the latter will be ignored.") if !t_set_c.nil?
    end
    if water_heater.is_a? OpenStudio::Model::WaterHeaterStratified
      water_heater.heater1SetpointTemperatureSchedule.remove
      water_heater.heater2SetpointTemperatureSchedule.remove
      water_heater.setHeater1SetpointTemperatureSchedule(setpoint_sch)
      water_heater.setHeater2SetpointTemperatureSchedule(setpoint_sch)
    elsif water_heater.is_a? OpenStudio::Model::WaterHeaterMixed
      if water_heater.setpointTemperatureSchedule.is_initialized
        water_heater.setpointTemperatureSchedule.get.remove
      end
      water_heater.setSetpointTemperatureSchedule(setpoint_sch)
    end
  end

  # Returns the water heater setpoint, accounting for any deadband, in deg-C. The deadband is currently
  # centered, not single-sided; see https://github.com/NREL/OpenStudio-HPXML/issues/642.
  #
  # @param t_set [Double] Water heater setpoint (F)
  # @param wh_type [String] Type of water heater (HPXML::WaterHeaterTypeXXX)
  # @return [Double] Water heater setpoint including deadband (C)
  def self.get_t_set_c(t_set, wh_type)
    return if t_set.nil?

    return UnitConversions.convert(t_set, 'F', 'C') + get_deadband(wh_type) / 2.0 # Half the deadband to account for E+ deadband
  end

  # Adds a plant loop for the water heater to the OpenStudio model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param t_set_c [Double] Water heater setpoint including deadband (C)
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @return [OpenStudio::Model::PlantLoop] The plant loop
  def self.add_plant_loop(model, t_set_c, eri_version, unit_multiplier)
    name = 'dhw loop'

    if t_set_c.nil?
      t_set_c = UnitConversions.convert(Defaults.get_water_heater_temperature(eri_version), 'F', 'C')
    end

    plant_loop = Model.add_plant_loop(
      model,
      name: name,
      volume: 0.003 * unit_multiplier, # ~1 gal
      max_flow_rate: 0.01 * unit_multiplier # This size represents the physical limitations to flow due to losses in the piping system. We assume that the pipes are always adequately sized.
    )

    sizing_plant = plant_loop.sizingPlant
    sizing_plant.setDesignLoopExitTemperature(t_set_c)
    sizing_plant.setLoopDesignTemperatureDifference(UnitConversions.convert(10.0, 'deltaF', 'deltaC'))

    bypass_pipe = Model.add_pipe_adiabatic(model)
    out_pipe = Model.add_pipe_adiabatic(model)

    plant_loop.addSupplyBranchForComponent(bypass_pipe)
    out_pipe.addToNode(plant_loop.supplyOutletNode)

    pump = Model.add_pump_variable_speed(
      model,
      name: "#{name} pump",
      rated_power: 0
    )
    pump.addToNode(plant_loop.supplyInletNode)

    temp_schedule = Model.add_schedule_constant(
      model,
      name: 'dhw temp',
      value: t_set_c
    )
    setpoint_manager = OpenStudio::Model::SetpointManagerScheduled.new(model, temp_schedule)
    setpoint_manager.addToNode(plant_loop.supplyOutletNode)

    return plant_loop
  end

  # Gets the solar fraction, which is defined as the portion of total conventional hot water heating
  # load (delivered energy plus tank standby losses) served by the solar thermal system.
  #
  # A value of zero will be returned unless all of these conditions are met:
  #   1. There is a solar thermal system
  #   2. The solar thermal system is attached to this water heater
  #   3. The solar thermal system has simple inputs (i.e., solar fraction), as opposed to detailed
  #      inputs that would result in the solar thermal system being modeled explicitly in EnergyPlus.
  #
  # @param water_heating_system [HPXML::WaterHeatingSystem] The HPXML water heating system of interest
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [Double] Solar fraction or zero
  def self.get_water_heater_solar_fraction(water_heating_system, hpxml_bldg)
    return 0.0 if hpxml_bldg.solar_thermal_systems.size == 0

    solar_thermal_system = hpxml_bldg.solar_thermal_systems[0]

    if (solar_thermal_system.water_heating_system.nil? || (solar_thermal_system.water_heating_system.id == water_heating_system.id))
      solar_fraction = solar_thermal_system.solar_fraction
    end
    return solar_fraction.to_f
  end
end
