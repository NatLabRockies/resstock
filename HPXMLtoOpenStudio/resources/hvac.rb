# frozen_string_literal: true

# Collection of methods related to HVAC systems.
module HVAC
  AirSourceHeatRatedODB = 47.0 # degF, Rated outdoor drybulb for air-source systems, heating
  AirSourceHeatRatedIDB = 70.0 # degF, Rated indoor drybulb for air-source systems, heating
  AirSourceCoolRatedODB = 95.0 # degF, Rated outdoor drybulb for air-source systems, cooling
  AirSourceCoolRatedOWB = 75.0 # degF, Rated outdoor wetbulb for air-source systems, cooling
  AirSourceCoolRatedIDB = 80.0 # degF, Rated indoor drybulb for air-source systems, cooling
  AirSourceCoolRatedIWB = 67.0 # degF, Rated indoor wetbulb for air-source systems, cooling
  GroundSourceHeatRatedWET = 70.0 # degF, Rated water entering temperature for ground-source systems, heating
  GroundSourceHeatRatedIDB = 70.0 # degF, Rated indoor drybulb for ground-source systems, heating
  GroundSourceCoolRatedWET = 85.0 # degF, Rated water entering temperature for ground-source systems, cooling
  GroundSourceCoolRatedIDB = 80.0 # degF, Rated indoor drybulb for ground-source systems, cooling
  GroundSourceCoolRatedIWB = 67.0 # degF, Rated indoor wetbulb for ground-source systems, cooling
  CrankcaseHeaterTemp = 50.0 # degF

  # Adds any HVAC Systems to the OpenStudio model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param hvac_season_days [Hash] Map of htg/clg => Array of 365 days with 1s during the heating/cooling season and 0s otherwise
  # @return [Hash] Map of HPXML System ID -> AirLoopHVAC (or ZoneHVACFourPipeFanCoil)
  def self.apply_hvac_systems(runner, model, weather, spaces, hpxml_bldg, hpxml_header, schedules_file, hvac_season_days)
    # Init
    hvac_remaining_load_fracs = { htg: 1.0, clg: 1.0 }
    airloop_map = {}

    if hpxml_bldg.hvac_controls.size == 0
      return airloop_map
    end

    hvac_unavailable_periods = { htg: Schedule.get_unavailable_periods(runner, SchedulesFile::Columns[:SpaceHeating].name, hpxml_header.unavailable_periods),
                                 clg: Schedule.get_unavailable_periods(runner, SchedulesFile::Columns[:SpaceCooling].name, hpxml_header.unavailable_periods) }

    apply_unit_multiplier(hpxml_bldg, hpxml_header)
    ensure_nonzero_sizing_values(hpxml_bldg)
    apply_ideal_air_system(model, weather, spaces, hpxml_bldg, hpxml_header, hvac_season_days, hvac_unavailable_periods, hvac_remaining_load_fracs)
    apply_cooling_system(runner, model, weather, spaces, hpxml_bldg, hpxml_header, schedules_file, airloop_map, hvac_season_days, hvac_unavailable_periods, hvac_remaining_load_fracs)
    hp_backup_obj = apply_heating_system(runner, model, weather, spaces, hpxml_bldg, hpxml_header, schedules_file, airloop_map, hvac_season_days, hvac_unavailable_periods, hvac_remaining_load_fracs)
    apply_heat_pump(runner, model, weather, spaces, hpxml_bldg, hpxml_header, schedules_file, airloop_map, hvac_season_days, hvac_unavailable_periods, hvac_remaining_load_fracs, hp_backup_obj)

    return airloop_map
  end

  # Adds any HPXML Cooling Systems to the OpenStudio model.
  # TODO for adding more description (e.g., around sequential load fractions)
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param airloop_map [Hash] Map of HPXML System ID => OpenStudio AirLoopHVAC (or ZoneHVACFourPipeFanCoil or ZoneHVACBaseboardConvectiveWater) objects
  # @param hvac_season_days [Hash] Map of htg/clg => Array of 365 days with 1s during the heating/cooling season and 0s otherwise
  # @param hvac_unavailable_periods [Hash] Map of htg/clg => HPXML::UnavailablePeriods for heating/cooling
  # @param hvac_remaining_load_fracs [Hash] Map of htg/clg => Fraction of heating/cooling load that has not yet been met
  # @return [nil]
  def self.apply_cooling_system(runner, model, weather, spaces, hpxml_bldg, hpxml_header, schedules_file, airloop_map,
                                hvac_season_days, hvac_unavailable_periods, hvac_remaining_load_fracs)
    conditioned_zone = spaces[HPXML::LocationConditionedSpace].thermalZone.get

    get_hpxml_hvac_systems(hpxml_bldg).each do |hvac_system|
      next if hvac_system[:cooling].nil?
      next unless hvac_system[:cooling].is_a? HPXML::CoolingSystem

      cooling_system = hvac_system[:cooling]
      heating_system = hvac_system[:heating]

      check_distribution_system(cooling_system.distribution_system, cooling_system.cooling_system_type)

      hvac_sequential_load_fracs = {}

      # Calculate cooling sequential load fractions
      hvac_sequential_load_fracs[:clg] = calc_sequential_load_fractions(cooling_system.fraction_cool_load_served.to_f, hvac_remaining_load_fracs[:clg], hvac_season_days[:clg])
      hvac_remaining_load_fracs[:clg] -= cooling_system.fraction_cool_load_served.to_f

      # Calculate heating sequential load fractions
      if not heating_system.nil?
        hvac_sequential_load_fracs[:htg] = calc_sequential_load_fractions(heating_system.fraction_heat_load_served, hvac_remaining_load_fracs[:htg], hvac_season_days[:htg])
        hvac_remaining_load_fracs[:htg] -= heating_system.fraction_heat_load_served
      elsif cooling_system.has_integrated_heating
        hvac_sequential_load_fracs[:htg] = calc_sequential_load_fractions(cooling_system.integrated_heating_system_fraction_heat_load_served, hvac_remaining_load_fracs[:htg], hvac_season_days[:htg])
        hvac_remaining_load_fracs[:htg] -= cooling_system.integrated_heating_system_fraction_heat_load_served
      else
        hvac_sequential_load_fracs[:htg] = [0]
      end

      sys_id = cooling_system.id
      case cooling_system.cooling_system_type
      when HPXML::HVACTypeCentralAirConditioner, HPXML::HVACTypeRoomAirConditioner,
           HPXML::HVACTypeMiniSplitAirConditioner, HPXML::HVACTypePTAC
        airloop_map[sys_id] = apply_air_source_hvac_systems(runner, model, weather, cooling_system, heating_system, hvac_sequential_load_fracs,
                                                            conditioned_zone, hvac_unavailable_periods, schedules_file, hpxml_bldg, hpxml_header)
      when HPXML::HVACTypeEvaporativeCooler
        airloop_map[sys_id] = apply_evaporative_cooler(model, cooling_system, hvac_sequential_load_fracs, conditioned_zone, hvac_unavailable_periods,
                                                       hpxml_bldg.building_construction.number_of_units)
      end
    end
  end

  # Adds any HPXML Heating Systems to the OpenStudio model.
  # TODO for adding more description (e.g., around sequential load fractions)
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param airloop_map [Hash] Map of HPXML System ID => OpenStudio AirLoopHVAC (or ZoneHVACFourPipeFanCoil or ZoneHVACBaseboardConvectiveWater) objects
  # @param hvac_season_days [Hash] Map of htg/clg => Array of 365 days with 1s during the heating/cooling season and 0s otherwise
  # @param hvac_unavailable_periods [Hash] Map of htg/clg => HPXML::UnavailablePeriods for heating/cooling
  # @param hvac_remaining_load_fracs [Hash] Map of htg/clg => Fraction of heating/cooling load that has not yet been met
  # @return [TODO] TODO
  def self.apply_heating_system(runner, model, weather, spaces, hpxml_bldg, hpxml_header, schedules_file, airloop_map,
                                hvac_season_days, hvac_unavailable_periods, hvac_remaining_load_fracs)
    conditioned_zone = spaces[HPXML::LocationConditionedSpace].thermalZone.get
    hp_backup_obj = nil

    get_hpxml_hvac_systems(hpxml_bldg).each do |hvac_system|
      next if hvac_system[:heating].nil?
      next unless hvac_system[:heating].is_a? HPXML::HeatingSystem

      cooling_system = hvac_system[:cooling]
      heating_system = hvac_system[:heating]

      check_distribution_system(heating_system.distribution_system, heating_system.heating_system_type)

      if (heating_system.heating_system_type == HPXML::HVACTypeFurnace) && (not cooling_system.nil?)
        next # Already processed combined AC+furnace
      end

      hvac_sequential_load_fracs = {}

      # Calculate heating sequential load fractions
      if heating_system.is_heat_pump_backup_system
        # Heating system will be last in the EquipmentList and should meet entirety of
        # remaining load during the heating season.
        hvac_sequential_load_fracs[:htg] = hvac_season_days[:htg].map(&:to_f)
        if not heating_system.fraction_heat_load_served.nil?
          fail 'Heat pump backup system cannot have a fraction heat load served specified.'
        end
      else
        hvac_sequential_load_fracs[:htg] = calc_sequential_load_fractions(heating_system.fraction_heat_load_served, hvac_remaining_load_fracs[:htg], hvac_season_days[:htg])
        hvac_remaining_load_fracs[:htg] -= heating_system.fraction_heat_load_served
      end

      sys_id = heating_system.id
      case heating_system.heating_system_type
      when HPXML::HVACTypeFurnace
        airloop_map[sys_id] = apply_air_source_hvac_systems(runner, model, weather, nil, heating_system, hvac_sequential_load_fracs,
                                                            conditioned_zone, hvac_unavailable_periods, schedules_file, hpxml_bldg, hpxml_header)
      when HPXML::HVACTypeBoiler
        airloop_map[sys_id] = apply_boiler(runner, model, heating_system, hvac_sequential_load_fracs, conditioned_zone, hvac_unavailable_periods)
      when HPXML::HVACTypeElectricResistance
        apply_electric_baseboard(model, heating_system, hvac_sequential_load_fracs, conditioned_zone, hvac_unavailable_periods)
      when HPXML::HVACTypeStove, HPXML::HVACTypeSpaceHeater, HPXML::HVACTypeWallFurnace,
           HPXML::HVACTypeFloorFurnace, HPXML::HVACTypeFireplace
        apply_unit_heater(model, heating_system, hvac_sequential_load_fracs, conditioned_zone, hvac_unavailable_periods)
      end

      next unless heating_system.is_heat_pump_backup_system

      # Store OS object for later use
      hp_backup_obj = model.getZoneHVACEquipmentLists.find { |el| el.thermalZone == conditioned_zone }.equipment[-1]
    end
    return hp_backup_obj
  end

  # Adds any HPXML Heat Pumps to the OpenStudio model.
  # TODO for adding more description (e.g., around sequential load fractions)
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param airloop_map [Hash] Map of HPXML System ID => OpenStudio AirLoopHVAC (or ZoneHVACFourPipeFanCoil or ZoneHVACBaseboardConvectiveWater) objects
  # @param hvac_season_days [Hash] Map of htg/clg => Array of 365 days with 1s during the heating/cooling season and 0s otherwise
  # @param hvac_unavailable_periods [Hash] Map of htg/clg => HPXML::UnavailablePeriods for heating/cooling
  # @param hvac_remaining_load_fracs [Hash] Map of htg/clg => Fraction of heating/cooling load that has not yet been met
  # @param hp_backup_obj [TODO] TODO
  # @return [nil]
  def self.apply_heat_pump(runner, model, weather, spaces, hpxml_bldg, hpxml_header, schedules_file, airloop_map,
                           hvac_season_days, hvac_unavailable_periods, hvac_remaining_load_fracs, hp_backup_obj)
    conditioned_zone = spaces[HPXML::LocationConditionedSpace].thermalZone.get

    get_hpxml_hvac_systems(hpxml_bldg).each do |hvac_system|
      next if hvac_system[:cooling].nil?
      next unless hvac_system[:cooling].is_a? HPXML::HeatPump

      heat_pump = hvac_system[:cooling]

      check_distribution_system(heat_pump.distribution_system, heat_pump.heat_pump_type)

      hvac_sequential_load_fracs = {}

      # Calculate heating sequential load fractions
      hvac_sequential_load_fracs[:htg] = calc_sequential_load_fractions(heat_pump.fraction_heat_load_served, hvac_remaining_load_fracs[:htg], hvac_season_days[:htg])
      hvac_remaining_load_fracs[:htg] -= heat_pump.fraction_heat_load_served

      # Calculate cooling sequential load fractions
      hvac_sequential_load_fracs[:clg] = calc_sequential_load_fractions(heat_pump.fraction_cool_load_served, hvac_remaining_load_fracs[:clg], hvac_season_days[:clg])
      hvac_remaining_load_fracs[:clg] -= heat_pump.fraction_cool_load_served

      sys_id = heat_pump.id
      case heat_pump.heat_pump_type
      when HPXML::HVACTypeHeatPumpWaterLoopToAir
        airloop_map[sys_id] = apply_water_loop_to_air_heat_pump(model, heat_pump, hvac_sequential_load_fracs, conditioned_zone, hvac_unavailable_periods)
      when HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpMiniSplit,
           HPXML::HVACTypeHeatPumpPTHP, HPXML::HVACTypeHeatPumpRoom
        airloop_map[sys_id] = apply_air_source_hvac_systems(runner, model, weather, heat_pump, heat_pump, hvac_sequential_load_fracs,
                                                            conditioned_zone, hvac_unavailable_periods, schedules_file, hpxml_bldg, hpxml_header)
      when HPXML::HVACTypeHeatPumpGroundToAir
        airloop_map[sys_id] = apply_ground_to_air_heat_pump(runner, model, weather, heat_pump, hvac_sequential_load_fracs,
                                                            conditioned_zone, hpxml_bldg.site.ground_conductivity, hpxml_bldg.site.ground_diffusivity,
                                                            hvac_unavailable_periods, hpxml_bldg.building_construction.number_of_units, hpxml_header)
      end

      next if heat_pump.backup_system.nil?

      equipment_list = model.getZoneHVACEquipmentLists.find { |el| el.thermalZone == conditioned_zone }

      # Set priority to be last (i.e., after the heat pump that it is backup for)
      equipment_list.setHeatingPriority(hp_backup_obj, 99)
      equipment_list.setCoolingPriority(hp_backup_obj, 99)
    end
  end

  # TODO
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param cooling_system [TODO] TODO
  # @param heating_system [TODO] TODO
  # @param hvac_sequential_load_fracs [Array<Double>] Array of daily fractions of remaining heating/cooling load to bet met by the HVAC system
  # @param control_zone [OpenStudio::Model::ThermalZone] Conditioned space thermal zone
  # @param hvac_unavailable_periods [Hash] Map of htg/clg => HPXML::UnavailablePeriods for heating/cooling
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [OpenStudio::Model::AirLoopHVAC] The newly created air loop hvac object
  def self.apply_air_source_hvac_systems(runner, model, weather, cooling_system, heating_system, hvac_sequential_load_fracs,
                                         control_zone, hvac_unavailable_periods, schedules_file, hpxml_bldg, hpxml_header)
    is_heatpump = false

    if (not cooling_system.nil?)
      is_onoff_thermostat_ddb = hpxml_header.hvac_onoff_thermostat_deadband.to_f > 0.0
      # Error-checking
      if is_onoff_thermostat_ddb
        if not [HPXML::HVACCompressorTypeSingleStage, HPXML::HVACCompressorTypeTwoStage].include? cooling_system.compressor_type
          # Throw error and stop simulation, because the setpoint schedule is already shifted, user will get wrong results otherwise.
          runner.registerError('On-off thermostat deadband currently is only supported for single speed or two speed air source systems.')
        end
        if hpxml_bldg.building_construction.number_of_units > 1
          # Throw error and stop simulation
          runner.registerError('NumberofUnits greater than 1 is not supported for on-off thermostat deadband.')
        end
      end
    else
      is_onoff_thermostat_ddb = false
    end

    if not cooling_system.nil?
      if cooling_system.is_a? HPXML::HeatPump
        is_heatpump = true
        case cooling_system.heat_pump_type
        when HPXML::HVACTypeHeatPumpAirToAir
          obj_name = Constants::ObjectTypeAirSourceHeatPump
        when HPXML::HVACTypeHeatPumpMiniSplit
          obj_name = Constants::ObjectTypeMiniSplitHeatPump
        when HPXML::HVACTypeHeatPumpPTHP
          obj_name = Constants::ObjectTypePTHP
          fan_watts_per_cfm = 0.0
        when HPXML::HVACTypeHeatPumpRoom
          obj_name = Constants::ObjectTypeRoomHP
          fan_watts_per_cfm = 0.0
        else
          fail "Unexpected heat pump type: #{cooling_system.heat_pump_type}."
        end
      elsif cooling_system.is_a? HPXML::CoolingSystem
        case cooling_system.cooling_system_type
        when HPXML::HVACTypeCentralAirConditioner
          if heating_system.nil?
            obj_name = Constants::ObjectTypeCentralAirConditioner
          else
            obj_name = Constants::ObjectTypeCentralAirConditionerAndFurnace
            # error checking for fan power
            if (cooling_system.fan_watts_per_cfm.to_f != heating_system.fan_watts_per_cfm.to_f)
              fail "Fan powers for heating system '#{heating_system.id}' and cooling system '#{cooling_system.id}' are attached to a single distribution system and therefore must be the same."
            end
          end
        when HPXML::HVACTypeRoomAirConditioner, HPXML::HVACTypePTAC
          fan_watts_per_cfm = 0.0
          if cooling_system.cooling_system_type == HPXML::HVACTypeRoomAirConditioner
            obj_name = Constants::ObjectTypeRoomAC
          else
            obj_name = Constants::ObjectTypePTAC
          end
        when HPXML::HVACTypeMiniSplitAirConditioner
          obj_name = Constants::ObjectTypeMiniSplitAirConditioner
        else
          fail "Unexpected cooling system type: #{cooling_system.cooling_system_type}."
        end
      end
    elsif (heating_system.is_a? HPXML::HeatingSystem) && (heating_system.heating_system_type == HPXML::HVACTypeFurnace)
      obj_name = Constants::ObjectTypeFurnace
    else
      fail "Unexpected heating system type: #{heating_system.heating_system_type}, expect central air source hvac systems."
    end
    if fan_watts_per_cfm.nil?
      if (not cooling_system.nil?) && (not cooling_system.fan_watts_per_cfm.nil?)
        fan_watts_per_cfm = cooling_system.fan_watts_per_cfm
      else
        fan_watts_per_cfm = heating_system.fan_watts_per_cfm
      end
    end

    # Calculate max rated cfm
    max_rated_fan_cfm = -9999
    if not cooling_system.nil?
      clg_ap = cooling_system.additional_properties
      if not cooling_system.cooling_detailed_performance_data.empty?
        cooling_system.cooling_detailed_performance_data.select { |dp| dp.capacity_description == HPXML::CapacityDescriptionMaximum }.each do |dp|
          rated_fan_cfm = UnitConversions.convert(dp.capacity, 'Btu/hr', 'ton') * clg_ap.cool_rated_cfm_per_ton[-1]
          max_rated_fan_cfm = rated_fan_cfm if rated_fan_cfm > max_rated_fan_cfm
        end
      else
        rated_fan_cfm = UnitConversions.convert(cooling_system.cooling_capacity * clg_ap.cool_capacity_ratios[-1], 'Btu/hr', 'ton') * clg_ap.cool_rated_cfm_per_ton[-1]
        max_rated_fan_cfm = rated_fan_cfm if rated_fan_cfm > max_rated_fan_cfm
      end
    end
    if not heating_system.nil?
      htg_ap = heating_system.additional_properties
      if not heating_system.heating_detailed_performance_data.empty?
        heating_system.heating_detailed_performance_data.select { |dp| dp.capacity_description == HPXML::CapacityDescriptionMaximum }.each do |dp|
          rated_fan_cfm = UnitConversions.convert(dp.capacity, 'Btu/hr', 'ton') * htg_ap.heat_rated_cfm_per_ton[-1]
          max_rated_fan_cfm = rated_fan_cfm if rated_fan_cfm > max_rated_fan_cfm
        end
      elsif is_heatpump
        rated_fan_cfm = UnitConversions.convert(heating_system.heating_capacity * htg_ap.heat_capacity_ratios[-1], 'Btu/hr', 'ton') * htg_ap.heat_rated_cfm_per_ton[-1]
        max_rated_fan_cfm = rated_fan_cfm if rated_fan_cfm > max_rated_fan_cfm
      end
    end

    fan_cfms = []
    if not cooling_system.nil?
      # Cooling Coil
      clg_coil = create_dx_cooling_coil(model, obj_name, cooling_system, max_rated_fan_cfm, weather.data.AnnualMaxDrybulb, is_onoff_thermostat_ddb)

      clg_cfm = cooling_system.cooling_airflow_cfm
      clg_ap.cool_fan_speed_ratios.each do |r|
        fan_cfms << clg_cfm * r
      end
      if (cooling_system.is_a? HPXML::CoolingSystem) && cooling_system.has_integrated_heating
        htg_coil = Model.add_coil_heating(
          model,
          name: "#{obj_name} htg coil",
          efficiency: cooling_system.integrated_heating_system_efficiency_percent,
          capacity: UnitConversions.convert(cooling_system.integrated_heating_system_capacity, 'Btu/hr', 'W'),
          fuel_type: cooling_system.integrated_heating_system_fuel
        )
        htg_coil.additionalProperties.setFeature('HPXML_ID', cooling_system.id) # Used by reporting measure
        htg_cfm = cooling_system.integrated_heating_system_airflow_cfm
        fan_cfms << htg_cfm
      end
    end

    if not heating_system.nil?
      htg_cfm = heating_system.heating_airflow_cfm
      if is_heatpump
        supp_max_temp = htg_ap.supp_max_temp

        htg_ap.heat_fan_speed_ratios.each do |r|
          fan_cfms << htg_cfm * r
        end
        # Defrost calculations
        if hpxml_header.defrost_model_type == HPXML::AdvancedResearchDefrostModelTypeAdvanced
          q_dot_defrost, p_dot_defrost = calculate_heat_pump_defrost_load_power_watts(heating_system, hpxml_bldg.building_construction.number_of_units,
                                                                                      fan_cfms.max, htg_cfm * htg_ap.heat_fan_speed_ratios[-1],
                                                                                      fan_watts_per_cfm)
        elsif hpxml_header.defrost_model_type != HPXML::AdvancedResearchDefrostModelTypeStandard
          fail 'unknown defrost model type.'
        end

        # Heating Coil
        htg_coil = create_dx_heating_coil(model, obj_name, heating_system, max_rated_fan_cfm, weather.data.AnnualMinDrybulb, hpxml_header.defrost_model_type, p_dot_defrost, is_onoff_thermostat_ddb)

        # Supplemental Heating Coil
        htg_supp_coil = create_supp_heating_coil(model, obj_name, heating_system, hpxml_header, runner, hpxml_bldg)
      else
        # Heating Coil
        fan_cfms << htg_cfm
        htg_coil = Model.add_coil_heating(
          model,
          name: "#{obj_name} htg coil",
          efficiency: heating_system.heating_efficiency_afue,
          capacity: UnitConversions.convert(heating_system.heating_capacity, 'Btu/hr', 'W'),
          fuel_type: heating_system.heating_system_fuel,
          off_cycle_gas_load: UnitConversions.convert(heating_system.pilot_light_btuh.to_f, 'Btu/hr', 'W')
        )
        htg_coil.additionalProperties.setFeature('HPXML_ID', heating_system.id) # Used by reporting measure
        htg_coil.additionalProperties.setFeature('IsHeatPumpBackup', heating_system.is_heat_pump_backup_system) # Used by reporting measure
      end
    end

    # Fan
    fan = create_supply_fan(model, obj_name, fan_watts_per_cfm, fan_cfms)
    if heating_system.is_a?(HPXML::HeatPump) && (not heating_system.backup_system.nil?) && (not htg_ap.hp_min_temp.nil?)
      # Disable blower fan power below compressor lockout temperature if separate backup heating system
      add_fan_power_ems_program(model, fan, htg_ap.hp_min_temp)
    end
    if (not cooling_system.nil?) && (not heating_system.nil?) && (cooling_system == heating_system)
      add_fan_pump_disaggregation_ems_program(model, fan, htg_coil, clg_coil, htg_supp_coil, cooling_system)
    else
      if not cooling_system.nil?
        if cooling_system.has_integrated_heating
          add_fan_pump_disaggregation_ems_program(model, fan, htg_coil, clg_coil, nil, cooling_system)
        else
          add_fan_pump_disaggregation_ems_program(model, fan, nil, clg_coil, nil, cooling_system)
        end
      end
      if not heating_system.nil?
        if heating_system.is_heat_pump_backup_system
          add_fan_pump_disaggregation_ems_program(model, fan, nil, nil, htg_coil, heating_system)
        else
          add_fan_pump_disaggregation_ems_program(model, fan, htg_coil, nil, htg_supp_coil, heating_system)
        end
      end
    end

    # Unitary System
    air_loop_unitary = create_air_loop_unitary_system(model, obj_name, fan, htg_coil, clg_coil, htg_supp_coil, htg_cfm, clg_cfm, supp_max_temp)

    # Unitary System Performance
    if (not clg_ap.nil?) && (clg_ap.cool_fan_speed_ratios.size > 1)
      perf = OpenStudio::Model::UnitarySystemPerformanceMultispeed.new(model)
      perf.setSingleModeOperation(false)
      for speed in 1..clg_ap.cool_fan_speed_ratios.size
        if is_heatpump
          f = OpenStudio::Model::SupplyAirflowRatioField.new(htg_ap.heat_fan_speed_ratios[speed - 1], clg_ap.cool_fan_speed_ratios[speed - 1])
        else
          f = OpenStudio::Model::SupplyAirflowRatioField.fromCoolingRatio(clg_ap.cool_fan_speed_ratios[speed - 1])
        end
        perf.addSupplyAirflowRatioField(f)
      end
      air_loop_unitary.setDesignSpecificationMultispeedObject(perf)
    end

    # Air Loop
    air_loop = create_air_loop(model, obj_name, air_loop_unitary, control_zone, hvac_sequential_load_fracs, [htg_cfm.to_f, clg_cfm.to_f].max, heating_system, hvac_unavailable_periods)

    add_backup_staging_ems_program(model, air_loop_unitary, htg_supp_coil, control_zone, htg_coil)
    apply_installation_quality(model, heating_system, cooling_system, air_loop_unitary, htg_coil, clg_coil, control_zone)

    # supp coil control in staging EMS
    add_two_speed_staging_ems_program(model, air_loop_unitary, htg_supp_coil, control_zone, is_onoff_thermostat_ddb, cooling_system)

    add_supplemental_coil_ems_program(model, htg_supp_coil, control_zone, htg_coil, is_onoff_thermostat_ddb, cooling_system)

    add_variable_speed_power_ems_program(runner, model, air_loop_unitary, control_zone, heating_system, cooling_system, htg_supp_coil, clg_coil, htg_coil, schedules_file)

    if is_heatpump && hpxml_header.defrost_model_type == HPXML::AdvancedResearchDefrostModelTypeAdvanced
      apply_advanced_defrost(model, htg_coil, air_loop_unitary, control_zone.spaces[0], htg_supp_coil, cooling_system, q_dot_defrost)
    end

    return air_loop
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param cooling_system [TODO] TODO
  # @param hvac_sequential_load_fracs [Array<Double>] Array of daily fractions of remaining heating/cooling load to bet met by the HVAC system
  # @param control_zone [OpenStudio::Model::ThermalZone] Conditioned space thermal zone
  # @param hvac_unavailable_periods [Hash] Map of htg/clg => HPXML::UnavailablePeriods for heating/cooling
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @return [OpenStudio::Model::AirLoopHVAC] The newly created air loop hvac object
  def self.apply_evaporative_cooler(model, cooling_system, hvac_sequential_load_fracs, control_zone,
                                    hvac_unavailable_periods, unit_multiplier)

    obj_name = Constants::ObjectTypeEvaporativeCooler

    clg_ap = cooling_system.additional_properties
    clg_cfm = cooling_system.cooling_airflow_cfm

    # Evap Cooler
    evap_cooler = OpenStudio::Model::EvaporativeCoolerDirectResearchSpecial.new(model, model.alwaysOnDiscreteSchedule)
    evap_cooler.setName(obj_name)
    evap_cooler.setCoolerEffectiveness(clg_ap.effectiveness)
    evap_cooler.setEvaporativeOperationMinimumDrybulbTemperature(0) # relax limitation to open evap cooler for any potential cooling
    evap_cooler.setEvaporativeOperationMaximumLimitWetbulbTemperature(50) # relax limitation to open evap cooler for any potential cooling
    evap_cooler.setEvaporativeOperationMaximumLimitDrybulbTemperature(50) # relax limitation to open evap cooler for any potential cooling
    evap_cooler.setPrimaryAirDesignFlowRate(UnitConversions.convert(clg_cfm, 'cfm', 'm^3/s'))
    evap_cooler.additionalProperties.setFeature('HPXML_ID', cooling_system.id) # Used by reporting measure

    # Air Loop
    air_loop = create_air_loop(model, obj_name, evap_cooler, control_zone, hvac_sequential_load_fracs, clg_cfm, nil, hvac_unavailable_periods)

    # Fan
    fan_watts_per_cfm = [2.79 * (clg_cfm / unit_multiplier)**-0.29, 0.6].min # W/cfm; fit of efficacy to air flow from the CEC listed equipment
    fan = create_supply_fan(model, obj_name, fan_watts_per_cfm, [clg_cfm])
    fan.addToNode(air_loop.supplyInletNode)
    add_fan_pump_disaggregation_ems_program(model, fan, nil, evap_cooler, nil, cooling_system)

    # Outdoor air intake system
    oa_intake_controller = OpenStudio::Model::ControllerOutdoorAir.new(model)
    oa_intake_controller.setName("#{air_loop.name} OA Controller")
    oa_intake_controller.setMinimumLimitType('FixedMinimum')
    oa_intake_controller.resetEconomizerMinimumLimitDryBulbTemperature
    oa_intake_controller.setMinimumFractionofOutdoorAirSchedule(model.alwaysOnDiscreteSchedule)
    oa_intake_controller.setMaximumOutdoorAirFlowRate(UnitConversions.convert(clg_cfm, 'cfm', 'm^3/s'))

    oa_intake = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model, oa_intake_controller)
    oa_intake.setName("#{air_loop.name} OA System")
    oa_intake.addToNode(air_loop.supplyInletNode)

    # air handler controls
    # setpoint follows OAT WetBulb
    evap_stpt_manager = OpenStudio::Model::SetpointManagerFollowOutdoorAirTemperature.new(model)
    evap_stpt_manager.setName('Follow OATwb')
    evap_stpt_manager.setReferenceTemperatureType('OutdoorAirWetBulb')
    evap_stpt_manager.setOffsetTemperatureDifference(0.0)
    evap_stpt_manager.addToNode(air_loop.supplyOutletNode)

    return air_loop
  end

  # TODO
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param heat_pump [HPXML::HeatPump] HPXML Heat Pump object
  # @param hvac_sequential_load_fracs [Array<Double>] Array of daily fractions of remaining heating/cooling load to bet met by the HVAC system
  # @param control_zone [OpenStudio::Model::ThermalZone] Conditioned space thermal zone
  # @param ground_conductivity [TODO] TODO
  # @param ground_diffusivity [TODO] TODO
  # @param hvac_unavailable_periods [Hash] Map of htg/clg => HPXML::UnavailablePeriods for heating/cooling
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [OpenStudio::Model::AirLoopHVAC] The newly created air loop hvac object
  def self.apply_ground_to_air_heat_pump(runner, model, weather, heat_pump, hvac_sequential_load_fracs,
                                         control_zone, ground_conductivity, ground_diffusivity,
                                         hvac_unavailable_periods, unit_multiplier, hpxml_header)

    if unit_multiplier > 1
      # FUTURE: Figure out how to allow this. If we allow it, update docs and hpxml_translator_test.rb too.
      # https://github.com/NREL/OpenStudio-HPXML/issues/1499
      fail 'NumberofUnits greater than 1 is not supported for ground-to-air heat pumps.'
    end

    obj_name = Constants::ObjectTypeGroundSourceHeatPump

    geothermal_loop = heat_pump.geothermal_loop
    hp_ap = heat_pump.additional_properties

    htg_cfm = heat_pump.heating_airflow_cfm
    clg_cfm = heat_pump.cooling_airflow_cfm
    htg_air_flow_rated = calc_rated_airflow(heat_pump.heating_capacity, hp_ap.heat_rated_cfm_per_ton[-1])
    clg_air_flow_rated = calc_rated_airflow(heat_pump.cooling_capacity, hp_ap.cool_rated_cfm_per_ton[-1])

    if hp_ap.frac_glycol == 0
      hp_ap.fluid_type = EPlus::FluidWater
      runner.registerWarning("Specified #{hp_ap.fluid_type} fluid type and 0 fraction of glycol, so assuming #{EPlus::FluidWater} fluid type.")
    end

    # Apply unit multiplier
    geothermal_loop.loop_flow *= unit_multiplier
    geothermal_loop.num_bore_holes *= unit_multiplier

    # Cooling Coil
    if [HPXML::AdvancedResearchGroundToAirHeatPumpModelTypeStandard].include? hpxml_header.ground_to_air_heat_pump_model_type
      clg_total_cap_curve = Model.add_curve_quad_linear(
        model,
        name: "#{obj_name} clg total cap curve",
        coeff: hp_ap.cool_cap_curve_spec[0]
      )
      clg_sens_cap_curve = Model.add_curve_quint_linear(
        model,
        name: "#{obj_name} clg sens cap curve",
        coeff: hp_ap.cool_sh_curve_spec[0]
      )
      clg_power_curve = Model.add_curve_quad_linear(
        model,
        name: "#{obj_name} clg power curve",
        coeff: hp_ap.cool_power_curve_spec[0]
      )
      clg_coil = OpenStudio::Model::CoilCoolingWaterToAirHeatPumpEquationFit.new(model, clg_total_cap_curve, clg_sens_cap_curve, clg_power_curve)
      clg_coil.setName(obj_name + ' clg coil')
      clg_coil.setRatedCoolingCoefficientofPerformance(hp_ap.cool_rated_cops[0])
      clg_coil.setNominalTimeforCondensateRemovaltoBegin(1000)
      clg_coil.setRatioofInitialMoistureEvaporationRateandSteadyStateLatentCapacity(1.5)
      clg_coil.setRatedAirFlowRate(clg_air_flow_rated)
      clg_coil.setRatedWaterFlowRate(UnitConversions.convert(geothermal_loop.loop_flow, 'gal/min', 'm^3/s'))
      clg_coil.setRatedEnteringWaterTemperature(UnitConversions.convert(80, 'F', 'C'))
      clg_coil.setRatedEnteringAirDryBulbTemperature(UnitConversions.convert(80, 'F', 'C'))
      clg_coil.setRatedEnteringAirWetBulbTemperature(UnitConversions.convert(67, 'F', 'C'))
      # TODO: Add net to gross conversion after RESNET PR: https://github.com/NREL/OpenStudio-HPXML/pull/1879
      clg_coil.setRatedTotalCoolingCapacity(UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'W'))
      clg_coil.setRatedSensibleCoolingCapacity(UnitConversions.convert(hp_ap.cooling_capacity_sensible, 'Btu/hr', 'W'))
      # Heating Coil
      htg_cap_curve = Model.add_curve_quad_linear(
        model,
        name: "#{obj_name} htg cap curve",
        coeff: hp_ap.heat_cap_curve_spec[0]
      )
      htg_power_curve = Model.add_curve_quad_linear(
        model,
        name: "#{obj_name} htg power curve",
        coeff: hp_ap.heat_power_curve_spec[0]
      )
      htg_coil = OpenStudio::Model::CoilHeatingWaterToAirHeatPumpEquationFit.new(model, htg_cap_curve, htg_power_curve)
      htg_coil.setName(obj_name + ' htg coil')
      htg_coil.setRatedHeatingCoefficientofPerformance(hp_ap.heat_rated_cops[0])
      htg_coil.setRatedAirFlowRate(htg_air_flow_rated)
      htg_coil.setRatedWaterFlowRate(UnitConversions.convert(geothermal_loop.loop_flow, 'gal/min', 'm^3/s'))
      htg_coil.setRatedEnteringWaterTemperature(UnitConversions.convert(60, 'F', 'C'))
      htg_coil.setRatedEnteringAirDryBulbTemperature(UnitConversions.convert(70, 'F', 'C'))
      # TODO: Add net to gross conversion after RESNET PR: https://github.com/NREL/OpenStudio-HPXML/pull/1879
      htg_coil.setRatedHeatingCapacity(UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'W'))
    elsif [HPXML::AdvancedResearchGroundToAirHeatPumpModelTypeExperimental].include? hpxml_header.ground_to_air_heat_pump_model_type
      num_speeds = hp_ap.cool_capacity_ratios.size
      if heat_pump.compressor_type == HPXML::HVACCompressorTypeVariableSpeed
        plf_fplr_curve = Model.add_curve_quadratic(
          model,
          name: 'Cool-PLF-fPLR',
          coeff: [1.0, 0.0, 0.0],
          min_x: 0, max_x: 1, min_y: 0.7, max_y: 1
        )
      else
        # Derived from: https://www.e3s-conferences.org/articles/e3sconf/pdf/2018/19/e3sconf_eko-dok2018_00139.pdf
        plf_fplr_curve = Model.add_curve_cubic(
          model,
          name: 'Cool-PLF-fPLR',
          coeff: [0.4603, 1.6416, -1.8588, 0.7605],
          min_x: 0, max_x: 1, min_y: 0.7, max_y: 1
        )
      end
      clg_coil = OpenStudio::Model::CoilCoolingWaterToAirHeatPumpVariableSpeedEquationFit.new(model, plf_fplr_curve)
      clg_coil.setName(obj_name + ' clg coil')
      clg_coil.setNominalTimeforCondensatetoBeginLeavingtheCoil(1000)
      clg_coil.setInitialMoistureEvaporationRateDividedbySteadyStateACLatentCapacity(1.5)
      clg_coil.setNominalSpeedLevel(num_speeds)
      clg_coil.setRatedAirFlowRateAtSelectedNominalSpeedLevel(clg_air_flow_rated)
      clg_coil.setRatedWaterFlowRateAtSelectedNominalSpeedLevel(UnitConversions.convert(geothermal_loop.loop_flow, 'gal/min', 'm^3/s'))
      # TODO: Add net to gross conversion after RESNET PR: https://github.com/NREL/OpenStudio-HPXML/pull/1879
      clg_coil.setGrossRatedTotalCoolingCapacityAtSelectedNominalSpeedLevel(UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'W'))
      for i in 0..(num_speeds - 1)
        cap_ft_curve = Model.add_curve_biquadratic(
          model,
          name: "Cool-CAP-fT#{i + 1}",
          coeff: hp_ap.cool_cap_ft_spec[i],
          min_x: -100, max_x: 100, min_y: -100, max_y: 100
        )
        cap_faf_curve = Model.add_curve_quadratic(
          model,
          name: "Cool-CAP-fAF#{i + 1}",
          coeff: hp_ap.cool_cap_fflow_spec[i],
          min_x: 0, max_x: 2, min_y: 0, max_y: 2
        )
        cap_fwf_curve = Model.add_curve_quadratic(
          model,
          name: "Cool-CAP-fWF#{i + 1}",
          coeff: hp_ap.cool_cap_fwf_spec[i],
          min_x: 0.45, max_x: 2, min_y: 0, max_y: 2
        )
        eir_ft_curve = Model.add_curve_biquadratic(
          model,
          name: "Cool-EIR-fT#{i + 1}",
          coeff: hp_ap.cool_eir_ft_spec[i],
          min_x: -100, max_x: 100, min_y: -100, max_y: 100
        )
        eir_faf_curve = Model.add_curve_quadratic(
          model,
          name: "Cool-EIR-fAF#{i + 1}",
          coeff: hp_ap.cool_eir_fflow_spec[i],
          min_x: 0, max_x: 2, min_y: 0, max_y: 2
        )
        eir_fwf_curve = Model.add_curve_quadratic(
          model,
          name: "Cool-EIR-fWF#{i + 1}",
          coeff: hp_ap.cool_eir_fwf_spec[i],
          min_x: 0.45, max_x: 2, min_y: 0, max_y: 2
        )
        # Recoverable heat modifier as a function of indoor wet-bulb and water entering temperatures.
        waste_heat_ft = Model.add_curve_biquadratic(
          model,
          name: "WasteHeat-FT#{i + 1}",
          coeff: [1, 0, 0, 0, 0, 0]
        )
        speed = OpenStudio::Model::CoilCoolingWaterToAirHeatPumpVariableSpeedEquationFitSpeedData.new(model, cap_ft_curve, cap_faf_curve, cap_fwf_curve, eir_ft_curve, eir_faf_curve, eir_fwf_curve, waste_heat_ft)
        # TODO: Add net to gross conversion after RESNET PR: https://github.com/NREL/OpenStudio-HPXML/pull/1879
        speed.setReferenceUnitGrossRatedTotalCoolingCapacity(UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'W') * hp_ap.cool_capacity_ratios[i])
        speed.setReferenceUnitGrossRatedSensibleHeatRatio(hp_ap.cool_rated_shrs_gross[i])
        speed.setReferenceUnitGrossRatedCoolingCOP(hp_ap.cool_rated_cops[i])
        speed.setReferenceUnitRatedAirFlowRate(UnitConversions.convert(UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'ton') * hp_ap.cool_capacity_ratios[i] * hp_ap.cool_rated_cfm_per_ton[i], 'cfm', 'm^3/s'))
        speed.setReferenceUnitRatedWaterFlowRate(UnitConversions.convert(geothermal_loop.loop_flow, 'gal/min', 'm^3/s') * hp_ap.cool_capacity_ratios[i])
        speed.setReferenceUnitWasteHeatFractionofInputPowerAtRatedConditions(0.0)
        clg_coil.addSpeed(speed)
      end
      if heat_pump.compressor_type == HPXML::HVACCompressorTypeVariableSpeed
        plf_fplr_curve = Model.add_curve_quadratic(
          model,
          name: 'Heat-PLF-fPLR',
          coeff: [1.0, 0.0, 0.0],
          min_x: 0, max_x: 1, min_y: 0.7, max_y: 1
        )
      else
        # Derived from: https://www.e3s-conferences.org/articles/e3sconf/pdf/2018/19/e3sconf_eko-dok2018_00139.pdf
        plf_fplr_curve = Model.add_curve_cubic(
          model,
          name: 'Heat-PLF-fPLR',
          coeff: [0.4603, 1.6416, -1.8588, 0.7605],
          min_x: 0, max_x: 1, min_y: 0.7, max_y: 1
        )
      end
      htg_coil = OpenStudio::Model::CoilHeatingWaterToAirHeatPumpVariableSpeedEquationFit.new(model, plf_fplr_curve)
      htg_coil.setName(obj_name + ' htg coil')
      htg_coil.setNominalSpeedLevel(num_speeds)
      htg_coil.setRatedAirFlowRateAtSelectedNominalSpeedLevel(htg_air_flow_rated)
      htg_coil.setRatedWaterFlowRateAtSelectedNominalSpeedLevel(UnitConversions.convert(geothermal_loop.loop_flow, 'gal/min', 'm^3/s'))
      # TODO: Add net to gross conversion after RESNET PR: https://github.com/NREL/OpenStudio-HPXML/pull/1879
      htg_coil.setRatedHeatingCapacityAtSelectedNominalSpeedLevel(UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'W'))
      for i in 0..(num_speeds - 1)
        cap_ft_curve = Model.add_curve_biquadratic(
          model,
          name: "Heat-CAP-fT#{i + 1}",
          coeff: hp_ap.heat_cap_ft_spec[i],
          min_x: -100, max_x: 100, min_y: -100, max_y: 100
        )
        cap_faf_curve = Model.add_curve_quadratic(
          model,
          name: "Heat-CAP-fAF#{i + 1}",
          coeff: hp_ap.heat_cap_fflow_spec[i],
          min_x: 0, max_x: 2, min_y: 0, max_y: 2
        )
        cap_fwf_curve = Model.add_curve_quadratic(
          model,
          name: "Heat-CAP-fWF#{i + 1}",
          coeff: hp_ap.heat_cap_fwf_spec[i],
          min_x: 0.45, max_x: 2, min_y: 0, max_y: 2
        )
        eir_ft_curve = Model.add_curve_biquadratic(
          model,
          name: "Heat-EIR-fT#{i + 1}",
          coeff: hp_ap.heat_eir_ft_spec[i],
          min_x: -100, max_x: 100, min_y: -100, max_y: 100
        )
        eir_faf_curve = Model.add_curve_quadratic(
          model,
          name: "Heat-EIR-fAF#{i + 1}",
          coeff: hp_ap.heat_eir_fflow_spec[i],
          min_x: 0, max_x: 2, min_y: 0, max_y: 2
        )
        eir_fwf_curve = Model.add_curve_quadratic(
          model,
          name: "Heat-EIR-fWF#{i + 1}",
          coeff: hp_ap.heat_eir_fwf_spec[i],
          min_x: 0.45, max_x: 2, min_y: 0, max_y: 2
        )
        # Recoverable heat modifier as a function of indoor wet-bulb and water entering temperatures.
        waste_heat_ft = Model.add_curve_biquadratic(
          model,
          name: "WasteHeat-FT#{i + 1}",
          coeff: [1, 0, 0, 0, 0, 0]
        )
        speed = OpenStudio::Model::CoilHeatingWaterToAirHeatPumpVariableSpeedEquationFitSpeedData.new(model, cap_ft_curve, cap_faf_curve, cap_fwf_curve, eir_ft_curve, eir_faf_curve, eir_fwf_curve, waste_heat_ft)
        # TODO: Add net to gross conversion after RESNET PR: https://github.com/NREL/OpenStudio-HPXML/pull/1879
        speed.setReferenceUnitGrossRatedHeatingCapacity(UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'W') * hp_ap.heat_capacity_ratios[i])
        speed.setReferenceUnitGrossRatedHeatingCOP(hp_ap.heat_rated_cops[i])
        speed.setReferenceUnitRatedAirFlow(UnitConversions.convert(UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'ton') * hp_ap.heat_capacity_ratios[i] * hp_ap.heat_rated_cfm_per_ton[i], 'cfm', 'm^3/s'))
        speed.setReferenceUnitRatedWaterFlowRate(UnitConversions.convert(geothermal_loop.loop_flow, 'gal/min', 'm^3/s') * hp_ap.heat_capacity_ratios[i])
        speed.setReferenceUnitWasteHeatFractionofInputPowerAtRatedConditions(0.0)
        htg_coil.addSpeed(speed)
      end
    end
    clg_coil.additionalProperties.setFeature('HPXML_ID', heat_pump.id) # Used by reporting measure
    htg_coil.additionalProperties.setFeature('HPXML_ID', heat_pump.id) # Used by reporting measure

    # Supplemental Heating Coil
    htg_supp_coil = create_supp_heating_coil(model, obj_name, heat_pump)

    # Site Ground Temperature Undisturbed
    xing = OpenStudio::Model::SiteGroundTemperatureUndisturbedXing.new(model)
    xing.setSoilSurfaceTemperatureAmplitude1(UnitConversions.convert(weather.data.DeepGroundSurfTempAmp1, 'deltaf', 'deltac'))
    xing.setSoilSurfaceTemperatureAmplitude2(UnitConversions.convert(weather.data.DeepGroundSurfTempAmp2, 'deltaf', 'deltac'))
    xing.setPhaseShiftofTemperatureAmplitude1(weather.data.DeepGroundPhaseShiftTempAmp1)
    xing.setPhaseShiftofTemperatureAmplitude2(weather.data.DeepGroundPhaseShiftTempAmp2)

    # Ground Heat Exchanger
    ground_heat_exch_vert = OpenStudio::Model::GroundHeatExchangerVertical.new(model, xing)
    ground_heat_exch_vert.setName(obj_name + ' exchanger')
    ground_heat_exch_vert.setBoreHoleRadius(UnitConversions.convert(geothermal_loop.bore_diameter / 2.0, 'in', 'm'))
    ground_heat_exch_vert.setGroundThermalConductivity(UnitConversions.convert(ground_conductivity, 'Btu/(hr*ft*R)', 'W/(m*K)'))
    ground_heat_exch_vert.setGroundThermalHeatCapacity(UnitConversions.convert(ground_conductivity / ground_diffusivity, 'Btu/(ft^3*F)', 'J/(m^3*K)'))
    ground_heat_exch_vert.setGroundTemperature(UnitConversions.convert(weather.data.DeepGroundAnnualTemp, 'F', 'C'))
    ground_heat_exch_vert.setGroutThermalConductivity(UnitConversions.convert(geothermal_loop.grout_conductivity, 'Btu/(hr*ft*R)', 'W/(m*K)'))
    ground_heat_exch_vert.setPipeThermalConductivity(UnitConversions.convert(geothermal_loop.pipe_conductivity, 'Btu/(hr*ft*R)', 'W/(m*K)'))
    ground_heat_exch_vert.setPipeOutDiameter(UnitConversions.convert(hp_ap.pipe_od, 'in', 'm'))
    ground_heat_exch_vert.setUTubeDistance(UnitConversions.convert(geothermal_loop.shank_spacing, 'in', 'm'))
    ground_heat_exch_vert.setPipeThickness(UnitConversions.convert((hp_ap.pipe_od - hp_ap.pipe_id) / 2.0, 'in', 'm'))
    ground_heat_exch_vert.setMaximumLengthofSimulation(1)
    ground_heat_exch_vert.setDesignFlowRate(UnitConversions.convert(geothermal_loop.loop_flow, 'gal/min', 'm^3/s'))
    ground_heat_exch_vert.setNumberofBoreHoles(geothermal_loop.num_bore_holes)
    ground_heat_exch_vert.setBoreHoleLength(UnitConversions.convert(geothermal_loop.bore_length, 'ft', 'm'))
    ground_heat_exch_vert.setBoreHoleTopDepth(2) # Consistent with G-function library
    ground_heat_exch_vert.setGFunctionReferenceRatio(ground_heat_exch_vert.boreHoleRadius.get / ground_heat_exch_vert.boreHoleLength.get) # ensure this ratio is consistent with rb/H so that g values will be taken as-is
    ground_heat_exch_vert.removeAllGFunctions
    for i in 0..(hp_ap.GSHP_G_Functions[0].size - 1)
      ground_heat_exch_vert.addGFunction(hp_ap.GSHP_G_Functions[0][i], hp_ap.GSHP_G_Functions[1][i])
    end
    xing = ground_heat_exch_vert.undisturbedGroundTemperatureModel.to_SiteGroundTemperatureUndisturbedXing.get
    xing.setSoilThermalConductivity(ground_heat_exch_vert.groundThermalConductivity.get)
    xing.setSoilSpecificHeat(ground_heat_exch_vert.groundThermalHeatCapacity.get / xing.soilDensity)
    xing.setAverageSoilSurfaceTemperature(ground_heat_exch_vert.groundTemperature.get)

    # Plant Loop
    plant_loop = Model.add_plant_loop(
      model,
      name: "#{obj_name} condenser loop",
      fluid_type: hp_ap.fluid_type,
      glycol_concentration: (hp_ap.frac_glycol * 100).to_i,
      min_temp: UnitConversions.convert(hp_ap.design_hw, 'F', 'C'),
      max_temp: 48.88889,
      max_flow_rate: UnitConversions.convert(geothermal_loop.loop_flow, 'gal/min', 'm^3/s')
    )

    plant_loop.addSupplyBranchForComponent(ground_heat_exch_vert)
    plant_loop.addDemandBranchForComponent(htg_coil)
    plant_loop.addDemandBranchForComponent(clg_coil)

    sizing_plant = plant_loop.sizingPlant
    sizing_plant.setLoopType('Condenser')
    sizing_plant.setDesignLoopExitTemperature(UnitConversions.convert(hp_ap.design_chw, 'F', 'C'))
    sizing_plant.setLoopDesignTemperatureDifference(UnitConversions.convert(hp_ap.design_delta_t, 'deltaF', 'deltaC'))

    setpoint_mgr_follow_ground_temp = OpenStudio::Model::SetpointManagerFollowGroundTemperature.new(model)
    setpoint_mgr_follow_ground_temp.setName(obj_name + ' condenser loop temp')
    setpoint_mgr_follow_ground_temp.setControlVariable('Temperature')
    setpoint_mgr_follow_ground_temp.setMaximumSetpointTemperature(48.88889)
    setpoint_mgr_follow_ground_temp.setMinimumSetpointTemperature(UnitConversions.convert(hp_ap.design_hw, 'F', 'C'))
    setpoint_mgr_follow_ground_temp.setReferenceGroundTemperatureObjectType('Site:GroundTemperature:Deep')
    setpoint_mgr_follow_ground_temp.addToNode(plant_loop.supplyOutletNode)

    # Pump
    if heat_pump.cooling_capacity > 1.0
      pump_w = heat_pump.pump_watts_per_ton * UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'ton')
    else
      pump_w = heat_pump.pump_watts_per_ton * UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'ton')
    end
    pump_w = [pump_w, 1.0].max # prevent error if zero
    pump = Model.add_pump_variable_speed(
      model,
      name: "#{obj_name} pump",
      rated_power: pump_w
    )
    pump.addToNode(plant_loop.supplyInletNode)
    add_fan_pump_disaggregation_ems_program(model, pump, htg_coil, clg_coil, htg_supp_coil, heat_pump)

    # Pipes
    chiller_bypass_pipe = Model.add_pipe_adiabatic(model)
    plant_loop.addSupplyBranchForComponent(chiller_bypass_pipe)
    coil_bypass_pipe = Model.add_pipe_adiabatic(model)
    plant_loop.addDemandBranchForComponent(coil_bypass_pipe)
    supply_outlet_pipe = Model.add_pipe_adiabatic(model)
    supply_outlet_pipe.addToNode(plant_loop.supplyOutletNode)
    demand_inlet_pipe = Model.add_pipe_adiabatic(model)
    demand_inlet_pipe.addToNode(plant_loop.demandInletNode)
    demand_outlet_pipe = Model.add_pipe_adiabatic(model)
    demand_outlet_pipe.addToNode(plant_loop.demandOutletNode)

    # Fan
    fan_cfms = []
    hp_ap.cool_fan_speed_ratios.each do |r|
      fan_cfms << clg_cfm * r
    end
    hp_ap.heat_fan_speed_ratios.each do |r|
      fan_cfms << htg_cfm * r
    end
    fan = create_supply_fan(model, obj_name, heat_pump.fan_watts_per_cfm, fan_cfms)
    add_fan_pump_disaggregation_ems_program(model, fan, htg_coil, clg_coil, htg_supp_coil, heat_pump)

    # Unitary System
    air_loop_unitary = create_air_loop_unitary_system(model, obj_name, fan, htg_coil, clg_coil, htg_supp_coil, htg_cfm, clg_cfm, 40.0)
    add_pump_power_ems_program(model, pump, air_loop_unitary, heat_pump)
    if (heat_pump.compressor_type == HPXML::HVACCompressorTypeVariableSpeed) && (hpxml_header.ground_to_air_heat_pump_model_type == HPXML::AdvancedResearchGroundToAirHeatPumpModelTypeExperimental)
      add_ghp_pump_mass_flow_rate_ems_program(model, pump, control_zone, htg_coil, clg_coil)
    end

    if heat_pump.is_shared_system
      # Shared pump power per ANSI/RESNET/ICC 301-2022 Section 4.4.5.1 (pump runs 8760)
      design_level = heat_pump.shared_loop_watts / heat_pump.number_of_units_served.to_f

      equip = Model.add_electric_equipment(
        model,
        name: Constants::ObjectTypeGSHPSharedPump,
        end_use: Constants::ObjectTypeGSHPSharedPump,
        space: control_zone.spaces[0], # no heat gain, so assign the equipment to an arbitrary space
        design_level: design_level,
        frac_radiant: 0,
        frac_latent: 0,
        frac_lost: 1,
        schedule: model.alwaysOnDiscreteSchedule
      )
      equip.additionalProperties.setFeature('HPXML_ID', heat_pump.id) # Used by reporting measure
    end

    # Air Loop
    air_loop = create_air_loop(model, obj_name, air_loop_unitary, control_zone, hvac_sequential_load_fracs, [htg_cfm, clg_cfm].max, heat_pump, hvac_unavailable_periods)

    # HVAC Installation Quality
    apply_installation_quality(model, heat_pump, heat_pump, air_loop_unitary, htg_coil, clg_coil, control_zone)

    return air_loop
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param heat_pump [HPXML::HeatPump] HPXML Heat Pump object
  # @param hvac_sequential_load_fracs [Array<Double>] Array of daily fractions of remaining heating/cooling load to bet met by the HVAC system
  # @param control_zone [OpenStudio::Model::ThermalZone] Conditioned space thermal zone
  # @param hvac_unavailable_periods [Hash] Map of htg/clg => HPXML::UnavailablePeriods for heating/cooling
  # @return [OpenStudio::Model::AirLoopHVAC] The newly created air loop hvac object
  def self.apply_water_loop_to_air_heat_pump(model, heat_pump, hvac_sequential_load_fracs, control_zone, hvac_unavailable_periods)
    if heat_pump.fraction_cool_load_served > 0
      # WLHPs connected to chillers or cooling towers should have already been converted to
      # central air conditioners
      fail 'WLHP model should only be called for central boilers.'
    end

    obj_name = Constants::ObjectTypeWaterLoopHeatPump

    htg_cfm = heat_pump.heating_airflow_cfm

    # Cooling Coil (none)
    clg_coil = nil

    # Heating Coil (model w/ constant efficiency)
    constant_biquadratic = Model.add_curve_biquadratic(
      model,
      name: 'ConstantBiquadratic',
      coeff: [1, 0, 0, 0, 0, 0]
    )
    constant_quadratic = Model.add_curve_quadratic(
      model,
      name: 'ConstantQuadratic',
      coeff: [1, 0, 0]
    )
    htg_coil = OpenStudio::Model::CoilHeatingDXSingleSpeed.new(model, model.alwaysOnDiscreteSchedule, constant_biquadratic, constant_quadratic, constant_biquadratic, constant_quadratic, constant_quadratic)
    htg_coil.setName(obj_name + ' htg coil')
    htg_coil.setRatedCOP(heat_pump.heating_efficiency_cop)
    htg_coil.setDefrostTimePeriodFraction(0.00001) # Disable defrost; avoid E+ warning w/ value of zero
    htg_coil.setMinimumOutdoorDryBulbTemperatureforCompressorOperation(-40)
    htg_coil.setRatedTotalHeatingCapacity(UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'W'))
    htg_coil.setRatedAirFlowRate(htg_cfm)
    htg_coil.additionalProperties.setFeature('HPXML_ID', heat_pump.id) # Used by reporting measure

    # Supplemental Heating Coil
    htg_supp_coil = create_supp_heating_coil(model, obj_name, heat_pump)

    # Fan
    fan_power_installed = 0.0 # Use provided net COP
    fan = create_supply_fan(model, obj_name, fan_power_installed, [htg_cfm])
    add_fan_pump_disaggregation_ems_program(model, fan, htg_coil, clg_coil, htg_supp_coil, heat_pump)

    # Unitary System
    air_loop_unitary = create_air_loop_unitary_system(model, obj_name, fan, htg_coil, clg_coil, htg_supp_coil, htg_cfm, nil)

    # Air Loop
    air_loop = create_air_loop(model, obj_name, air_loop_unitary, control_zone, hvac_sequential_load_fracs, htg_cfm, heat_pump, hvac_unavailable_periods)

    return air_loop
  end

  # Get the outdoor unit (compressor) power (W) using regression based on (output) capacity.
  # The equation is a derived regression for the minimum circuit amp (MCA) of direct expansion compressor from 201 product datapoints (including central ACs, room ACs, and ASHPs) collected between 2023-2024.
  #
  # @param capacity [Double] Direct expansion coil rated (output) capacity [kBtu/hr].
  # @param voltage [String] '120' or '240'
  # @return [Double] Direct expansion coil rated (input) capacity (W)
  def self.get_dx_coil_power_watts_from_capacity(capacity, voltage)
    required_amperage = 0.631 * capacity + 1.615
    power = required_amperage * Float(voltage)
    return power
  end

  # Get the indoor unit (air handler) power (W).
  #
  # @param fan_watts_per_cfm [Double] Blower fan watts per cfm [W/cfm]
  # @param airflow_cfm [Double] HVAC system airflow rate [cfm]
  # @return [Double] Blower fan power [W]
  def self.get_blower_fan_power_watts(fan_watts_per_cfm, airflow_cfm)
    return 0.0 if fan_watts_per_cfm.nil? || airflow_cfm.nil?

    return fan_watts_per_cfm * airflow_cfm
  end

  # Get the boiler pump power (W).
  #
  # @param electric_auxiliary_energy [Double] Boiler electric auxiliary energy [kWh/yr]
  # @return [Double] Boiler pump power [W]
  def self.get_pump_power_watts(electric_auxiliary_energy)
    return 0.0 if electric_auxiliary_energy.nil?

    return electric_auxiliary_energy / 2.08
  end

  # Returns the heating input capacity, calculated as the heating rated (output) capacity divided by the rated efficiency.
  #
  # @param heating_capacity [Double] Heating output capacity [Btu/hr]
  # @param heating_efficiency_afue [Double] Rated efficiency [AFUE]
  # @param heating_efficiency_percent [Double] Rated efficiency [Percent]
  # @return [Double] The heating input capacity [Btu/hr]
  def self.get_heating_input_capacity(heating_capacity, heating_efficiency_afue, heating_efficiency_percent)
    if not heating_efficiency_afue.nil?
      return heating_capacity / heating_efficiency_afue
    elsif not heating_efficiency_percent.nil?
      return heating_capacity / heating_efficiency_percent
    else
      return
    end
  end

  # TODO
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param heating_system [TODO] TODO
  # @param hvac_sequential_load_fracs [Array<Double>] Array of daily fractions of remaining heating/cooling load to bet met by the HVAC system
  # @param control_zone [OpenStudio::Model::ThermalZone] Conditioned space thermal zone
  # @param hvac_unavailable_periods [Hash] Map of htg/clg => HPXML::UnavailablePeriods for heating/cooling
  # @return [OpenStudio::Model::ZoneHVACFourPipeFanCoil or OpenStudio::Model::ZoneHVACBaseboardConvectiveWater] The newly created zone hvac object
  def self.apply_boiler(runner, model, heating_system, hvac_sequential_load_fracs, control_zone, hvac_unavailable_periods)
    obj_name = Constants::ObjectTypeBoiler
    is_condensing = false # FUTURE: Expose as input; default based on AFUE
    oat_reset_enabled = false
    oat_high = nil
    oat_low = nil
    oat_hwst_high = nil
    oat_hwst_low = nil
    design_temp = 180.0 # F

    if oat_reset_enabled
      if oat_high.nil? || oat_low.nil? || oat_hwst_low.nil? || oat_hwst_high.nil?
        runner.registerWarning('Boiler outdoor air temperature (OAT) reset is enabled but no setpoints were specified so OAT reset is being disabled.')
        oat_reset_enabled = false
      end
    end

    # Plant Loop
    plant_loop = Model.add_plant_loop(
      model,
      name: "#{obj_name} hydronic heat loop"
    )

    loop_sizing = plant_loop.sizingPlant
    loop_sizing.setLoopType('Heating')
    loop_sizing.setDesignLoopExitTemperature(UnitConversions.convert(design_temp, 'F', 'C'))
    loop_sizing.setLoopDesignTemperatureDifference(UnitConversions.convert(20.0, 'deltaF', 'deltaC'))

    # Pump
    pump_w = get_pump_power_watts(heating_system.electric_auxiliary_energy)
    pump_w = [pump_w, 1.0].max # prevent error if zero
    pump = Model.add_pump_variable_speed(
      model,
      name: "#{obj_name} hydronic pump",
      rated_power: pump_w
    )
    pump.addToNode(plant_loop.supplyInletNode)

    # Boiler
    boiler = OpenStudio::Model::BoilerHotWater.new(model)
    boiler.setName(obj_name)
    boiler.setFuelType(EPlus.fuel_type(heating_system.heating_system_fuel))
    if is_condensing
      # Convert Rated Efficiency at 80F and 1.0PLR where the performance curves are derived from to Design condition as input
      boiler_RatedHWRT = UnitConversions.convert(80.0, 'F', 'C')
      plr_Rated = 1.0
      plr_Design = 1.0
      boiler_DesignHWRT = UnitConversions.convert(design_temp - 20.0, 'F', 'C')
      # Efficiency curves are normalized using 80F return water temperature, at 0.254PLR
      condBlr_TE_Coeff = [1.058343061, 0.052650153, 0.0087272, 0.001742217, 0.00000333715, 0.000513723]
      boilerEff_Norm = heating_system.heating_efficiency_afue / (condBlr_TE_Coeff[0] - condBlr_TE_Coeff[1] * plr_Rated - condBlr_TE_Coeff[2] * plr_Rated**2 - condBlr_TE_Coeff[3] * boiler_RatedHWRT + condBlr_TE_Coeff[4] * boiler_RatedHWRT**2 + condBlr_TE_Coeff[5] * boiler_RatedHWRT * plr_Rated)
      boilerEff_Design = boilerEff_Norm * (condBlr_TE_Coeff[0] - condBlr_TE_Coeff[1] * plr_Design - condBlr_TE_Coeff[2] * plr_Design**2 - condBlr_TE_Coeff[3] * boiler_DesignHWRT + condBlr_TE_Coeff[4] * boiler_DesignHWRT**2 + condBlr_TE_Coeff[5] * boiler_DesignHWRT * plr_Design)
      boiler.setNominalThermalEfficiency(boilerEff_Design)
      boiler.setEfficiencyCurveTemperatureEvaluationVariable('EnteringBoiler')
      boiler_eff_curve = Model.add_curve_biquadratic(
        model,
        name: 'CondensingBoilerEff',
        coeff: [1.058343061, -0.052650153, -0.0087272, -0.001742217, 0.00000333715, 0.000513723],
        min_x: 0.2, max_x: 1.0, min_y: 30.0, max_y: 85.0
      )
    else
      boiler.setNominalThermalEfficiency(heating_system.heating_efficiency_afue)
      boiler.setEfficiencyCurveTemperatureEvaluationVariable('LeavingBoiler')
      boiler_eff_curve = Model.add_curve_bicubic(
        model,
        name: 'NonCondensingBoilerEff',
        coeff: [1.111720116, 0.078614078, -0.400425756, 0.0, -0.000156783, 0.009384599, 0.234257955, 1.32927e-06, -0.004446701, -1.22498e-05],
        min_x: 0.1, max_x: 1.0, min_y: 20.0, max_y: 80.0
      )
    end
    boiler.setNormalizedBoilerEfficiencyCurve(boiler_eff_curve)
    boiler.setMinimumPartLoadRatio(0.0)
    boiler.setMaximumPartLoadRatio(1.0)
    boiler.setBoilerFlowMode('LeavingSetpointModulated')
    boiler.setOptimumPartLoadRatio(1.0)
    boiler.setWaterOutletUpperTemperatureLimit(99.9)
    boiler.setOnCycleParasiticElectricLoad(0)
    boiler.setNominalCapacity(UnitConversions.convert(heating_system.heating_capacity, 'Btu/hr', 'W'))
    boiler.setOffCycleParasiticFuelLoad(UnitConversions.convert(heating_system.pilot_light_btuh.to_f, 'Btu/hr', 'W'))
    plant_loop.addSupplyBranchForComponent(boiler)
    boiler.additionalProperties.setFeature('HPXML_ID', heating_system.id) # Used by reporting measure
    boiler.additionalProperties.setFeature('IsHeatPumpBackup', heating_system.is_heat_pump_backup_system) # Used by reporting measure
    add_pump_power_ems_program(model, pump, boiler, heating_system)

    if is_condensing && oat_reset_enabled
      setpoint_manager_oar = OpenStudio::Model::SetpointManagerOutdoorAirReset.new(model)
      setpoint_manager_oar.setName(obj_name + ' outdoor reset')
      setpoint_manager_oar.setControlVariable('Temperature')
      setpoint_manager_oar.setSetpointatOutdoorLowTemperature(UnitConversions.convert(oat_hwst_low, 'F', 'C'))
      setpoint_manager_oar.setOutdoorLowTemperature(UnitConversions.convert(oat_low, 'F', 'C'))
      setpoint_manager_oar.setSetpointatOutdoorHighTemperature(UnitConversions.convert(oat_hwst_high, 'F', 'C'))
      setpoint_manager_oar.setOutdoorHighTemperature(UnitConversions.convert(oat_high, 'F', 'C'))
      setpoint_manager_oar.addToNode(plant_loop.supplyOutletNode)
    end

    supply_setpoint = Model.add_schedule_constant(
      model,
      name: "#{obj_name} hydronic heat supply setpoint",
      value: UnitConversions.convert(design_temp, 'F', 'C'),
      limits: EPlus::ScheduleTypeLimitsTemperature
    )

    setpoint_manager = OpenStudio::Model::SetpointManagerScheduled.new(model, supply_setpoint)
    setpoint_manager.setName(obj_name + ' hydronic heat loop setpoint manager')
    setpoint_manager.setControlVariable('Temperature')
    setpoint_manager.addToNode(plant_loop.supplyOutletNode)

    pipe_supply_bypass = Model.add_pipe_adiabatic(model)
    plant_loop.addSupplyBranchForComponent(pipe_supply_bypass)
    pipe_supply_outlet = Model.add_pipe_adiabatic(model)
    pipe_supply_outlet.addToNode(plant_loop.supplyOutletNode)
    pipe_demand_bypass = Model.add_pipe_adiabatic(model)
    plant_loop.addDemandBranchForComponent(pipe_demand_bypass)
    pipe_demand_inlet = Model.add_pipe_adiabatic(model)
    pipe_demand_inlet.addToNode(plant_loop.demandInletNode)
    pipe_demand_outlet = Model.add_pipe_adiabatic(model)
    pipe_demand_outlet.addToNode(plant_loop.demandOutletNode)

    bb_ua = UnitConversions.convert(heating_system.heating_capacity, 'Btu/hr', 'W') / UnitConversions.convert(UnitConversions.convert(loop_sizing.designLoopExitTemperature, 'C', 'F') - 10.0 - 95.0, 'deltaF', 'deltaC') * 3.0 # W/K
    max_water_flow = UnitConversions.convert(heating_system.heating_capacity, 'Btu/hr', 'W') / UnitConversions.convert(20.0, 'deltaF', 'deltaC') / 4.186 / 998.2 / 1000.0 * 2.0 # m^3/s
    fan_cfm = 400.0 * UnitConversions.convert(heating_system.heating_capacity, 'Btu/hr', 'ton') # CFM; assumes 400 cfm/ton

    if heating_system.distribution_system.air_type.to_s == HPXML::AirTypeFanCoil
      # Fan
      fan = create_supply_fan(model, obj_name, 0.0, [fan_cfm]) # fan energy included in above pump via Electric Auxiliary Energy (EAE)

      # Heating Coil
      htg_coil = OpenStudio::Model::CoilHeatingWater.new(model, model.alwaysOnDiscreteSchedule)
      htg_coil.setRatedCapacity(UnitConversions.convert(heating_system.heating_capacity, 'Btu/hr', 'W'))
      htg_coil.setUFactorTimesAreaValue(bb_ua)
      htg_coil.setMaximumWaterFlowRate(max_water_flow)
      htg_coil.setPerformanceInputMethod('NominalCapacity')
      htg_coil.setName(obj_name + ' htg coil')
      plant_loop.addDemandBranchForComponent(htg_coil)

      # Cooling Coil (always off)
      clg_coil = OpenStudio::Model::CoilCoolingWater.new(model, model.alwaysOffDiscreteSchedule)
      clg_coil.setName(obj_name + ' clg coil')
      clg_coil.setDesignWaterFlowRate(0.0022)
      clg_coil.setDesignAirFlowRate(1.45)
      clg_coil.setDesignInletWaterTemperature(6.1)
      clg_coil.setDesignInletAirTemperature(25.0)
      clg_coil.setDesignOutletAirTemperature(10.0)
      clg_coil.setDesignInletAirHumidityRatio(0.012)
      clg_coil.setDesignOutletAirHumidityRatio(0.008)
      plant_loop.addDemandBranchForComponent(clg_coil)

      # Fan Coil
      zone_hvac = OpenStudio::Model::ZoneHVACFourPipeFanCoil.new(model, model.alwaysOnDiscreteSchedule, fan, clg_coil, htg_coil)
      zone_hvac.setCapacityControlMethod('CyclingFan')
      zone_hvac.setName(obj_name + ' fan coil')
      zone_hvac.setMaximumSupplyAirTemperatureInHeatingMode(UnitConversions.convert(120.0, 'F', 'C'))
      zone_hvac.setHeatingConvergenceTolerance(0.001)
      zone_hvac.setMinimumSupplyAirTemperatureInCoolingMode(UnitConversions.convert(55.0, 'F', 'C'))
      zone_hvac.setMaximumColdWaterFlowRate(0.0)
      zone_hvac.setCoolingConvergenceTolerance(0.001)
      zone_hvac.setMaximumOutdoorAirFlowRate(0.0)
      zone_hvac.setMaximumSupplyAirFlowRate(UnitConversions.convert(fan_cfm, 'cfm', 'm^3/s'))
      zone_hvac.setMaximumHotWaterFlowRate(max_water_flow)
      zone_hvac.addToThermalZone(control_zone)
      add_fan_pump_disaggregation_ems_program(model, pump, zone_hvac, nil, nil, heating_system)
    else
      # Heating Coil
      htg_coil = OpenStudio::Model::CoilHeatingWaterBaseboard.new(model)
      htg_coil.setName(obj_name + ' htg coil')
      htg_coil.setConvergenceTolerance(0.001)
      htg_coil.setHeatingDesignCapacity(UnitConversions.convert(heating_system.heating_capacity, 'Btu/hr', 'W'))
      htg_coil.setUFactorTimesAreaValue(bb_ua)
      htg_coil.setMaximumWaterFlowRate(max_water_flow)
      htg_coil.setHeatingDesignCapacityMethod('HeatingDesignCapacity')
      plant_loop.addDemandBranchForComponent(htg_coil)

      # Baseboard
      zone_hvac = OpenStudio::Model::ZoneHVACBaseboardConvectiveWater.new(model, model.alwaysOnDiscreteSchedule, htg_coil)
      zone_hvac.setName(obj_name + ' baseboard')
      zone_hvac.addToThermalZone(control_zone)
      zone_hvac.additionalProperties.setFeature('IsHeatPumpBackup', heating_system.is_heat_pump_backup_system) # Used by reporting measure
      if heating_system.is_heat_pump_backup_system
        add_fan_pump_disaggregation_ems_program(model, pump, nil, nil, zone_hvac, heating_system)
      else
        add_fan_pump_disaggregation_ems_program(model, pump, zone_hvac, nil, nil, heating_system)
      end
    end

    set_sequential_load_fractions(model, control_zone, zone_hvac, hvac_sequential_load_fracs, hvac_unavailable_periods, heating_system)

    return zone_hvac
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param heating_system [TODO] TODO
  # @param hvac_sequential_load_fracs [Array<Double>] Array of daily fractions of remaining heating/cooling load to bet met by the HVAC system
  # @param control_zone [OpenStudio::Model::ThermalZone] Conditioned space thermal zone
  # @param hvac_unavailable_periods [Hash] Map of htg/clg => HPXML::UnavailablePeriods for heating/cooling
  # @return [nil]
  def self.apply_electric_baseboard(model, heating_system, hvac_sequential_load_fracs, control_zone, hvac_unavailable_periods)
    obj_name = Constants::ObjectTypeElectricBaseboard

    # Baseboard
    zone_hvac = OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(model)
    zone_hvac.setName(obj_name)
    zone_hvac.setEfficiency(heating_system.heating_efficiency_percent)
    zone_hvac.setNominalCapacity(UnitConversions.convert(heating_system.heating_capacity, 'Btu/hr', 'W'))
    zone_hvac.addToThermalZone(control_zone)
    zone_hvac.additionalProperties.setFeature('HPXML_ID', heating_system.id) # Used by reporting measure
    zone_hvac.additionalProperties.setFeature('IsHeatPumpBackup', heating_system.is_heat_pump_backup_system) # Used by reporting measure

    set_sequential_load_fractions(model, control_zone, zone_hvac, hvac_sequential_load_fracs, hvac_unavailable_periods, heating_system)
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param heating_system [TODO] TODO
  # @param hvac_sequential_load_fracs [Array<Double>] Array of daily fractions of remaining heating/cooling load to bet met by the HVAC system
  # @param control_zone [OpenStudio::Model::ThermalZone] Conditioned space thermal zone
  # @param hvac_unavailable_periods [Hash] Map of htg/clg => HPXML::UnavailablePeriods for heating/cooling
  # @return [nil]
  def self.apply_unit_heater(model, heating_system, hvac_sequential_load_fracs, control_zone, hvac_unavailable_periods)
    obj_name = Constants::ObjectTypeUnitHeater

    # Heating Coil
    efficiency = heating_system.heating_efficiency_afue
    efficiency = heating_system.heating_efficiency_percent if efficiency.nil?
    htg_coil = Model.add_coil_heating(
      model,
      name: "#{obj_name} htg coil",
      efficiency: efficiency,
      capacity: UnitConversions.convert(heating_system.heating_capacity, 'Btu/hr', 'W'),
      fuel_type: heating_system.heating_system_fuel,
      off_cycle_gas_load: UnitConversions.convert(heating_system.pilot_light_btuh.to_f, 'Btu/hr', 'W')
    )
    htg_coil.additionalProperties.setFeature('HPXML_ID', heating_system.id) # Used by reporting measure
    htg_coil.additionalProperties.setFeature('IsHeatPumpBackup', heating_system.is_heat_pump_backup_system) # Used by reporting measure

    # Fan
    htg_cfm = heating_system.heating_airflow_cfm
    fan_watts_per_cfm = heating_system.fan_watts / htg_cfm
    fan = create_supply_fan(model, obj_name, fan_watts_per_cfm, [htg_cfm])
    add_fan_pump_disaggregation_ems_program(model, fan, htg_coil, nil, nil, heating_system)

    # Unitary System
    unitary_system = create_air_loop_unitary_system(model, obj_name, fan, htg_coil, nil, nil, htg_cfm, nil)
    unitary_system.setControllingZoneorThermostatLocation(control_zone)
    unitary_system.addToThermalZone(control_zone)

    set_sequential_load_fractions(model, control_zone, unitary_system, hvac_sequential_load_fracs, hvac_unavailable_periods, heating_system)
  end

  # Adds an ideal air system as needed to meet the load under certain circumstances:
  # 1. the sum of fractions load served is less than 1 and greater than 0 (e.g., room ACs serving a portion of the home's load),
  #    in which case we need the ideal system to help fully condition the thermal zone to prevent incorrect heat transfers, or
  # 2. ASHRAE 140 tests where we need heating/cooling loads.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param hvac_season_days [Hash] Map of htg/clg => Array of 365 days with 1s during the heating/cooling season and 0s otherwise
  # @param hvac_unavailable_periods [Hash] Map of htg/clg => HPXML::UnavailablePeriods for heating/cooling
  # @param hvac_remaining_load_fracs [Hash] Map of htg/clg => Fraction of heating/cooling load that has not yet been met
  # @return [nil]
  def self.apply_ideal_air_system(model, weather, spaces, hpxml_bldg, hpxml_header, hvac_season_days,
                                  hvac_unavailable_periods, hvac_remaining_load_fracs)
    conditioned_zone = spaces[HPXML::LocationConditionedSpace].thermalZone.get

    if hpxml_header.apply_ashrae140_assumptions && (hpxml_bldg.total_fraction_heat_load_served + hpxml_bldg.total_fraction_heat_load_served == 0.0)
      cooling_load_frac = 1.0
      heating_load_frac = 1.0
      if hpxml_header.apply_ashrae140_assumptions
        if weather.header.StateProvinceRegion.downcase == 'co'
          cooling_load_frac = 0.0
        elsif weather.header.StateProvinceRegion.downcase == 'nv'
          heating_load_frac = 0.0
        else
          fail 'Unexpected weather file for ASHRAE 140 run.'
        end
      end
      hvac_sequential_load_fracs = { htg: [heating_load_frac],
                                     clg: [cooling_load_frac] }
      apply_ideal_air_loads(model, hvac_sequential_load_fracs, conditioned_zone, hvac_unavailable_periods)
      return
    end

    hvac_sequential_load_fracs = {}

    if (hpxml_bldg.total_fraction_heat_load_served < 1.0) && (hpxml_bldg.total_fraction_heat_load_served > 0.0)
      hvac_sequential_load_fracs[:htg] = calc_sequential_load_fractions(hvac_remaining_load_fracs[:htg] - hpxml_bldg.total_fraction_heat_load_served, hvac_remaining_load_fracs[:htg], hvac_season_days[:htg])
      hvac_remaining_load_fracs[:htg] -= (1.0 - hpxml_bldg.total_fraction_heat_load_served)
    else
      hvac_sequential_load_fracs[:htg] = [0.0]
    end

    if (hpxml_bldg.total_fraction_cool_load_served < 1.0) && (hpxml_bldg.total_fraction_cool_load_served > 0.0)
      hvac_sequential_load_fracs[:clg] = calc_sequential_load_fractions(hvac_remaining_load_fracs[:clg] - hpxml_bldg.total_fraction_cool_load_served, hvac_remaining_load_fracs[:clg], hvac_season_days[:clg])
      hvac_remaining_load_fracs[:clg] -= (1.0 - hpxml_bldg.total_fraction_cool_load_served)
    else
      hvac_sequential_load_fracs[:clg] = [0.0]
    end

    if (hvac_sequential_load_fracs[:htg].sum > 0.0) || (hvac_sequential_load_fracs[:clg].sum > 0.0)
      apply_ideal_air_loads(model, hvac_sequential_load_fracs, conditioned_zone, hvac_unavailable_periods)
    end
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hvac_sequential_load_fracs [Array<Double>] Array of daily fractions of remaining heating/cooling load to bet met by the HVAC system
  # @param control_zone [OpenStudio::Model::ThermalZone] Conditioned space thermal zone
  # @param hvac_unavailable_periods [Hash] Map of htg/clg => HPXML::UnavailablePeriods for heating/cooling
  # @return [nil]
  def self.apply_ideal_air_loads(model, hvac_sequential_load_fracs, control_zone, hvac_unavailable_periods)
    obj_name = Constants::ObjectTypeIdealAirSystem

    # Ideal Air System
    ideal_air = OpenStudio::Model::ZoneHVACIdealLoadsAirSystem.new(model)
    ideal_air.setName(obj_name)
    ideal_air.setMaximumHeatingSupplyAirTemperature(50)
    ideal_air.setMinimumCoolingSupplyAirTemperature(10)
    ideal_air.setMaximumHeatingSupplyAirHumidityRatio(0.015)
    ideal_air.setMinimumCoolingSupplyAirHumidityRatio(0.01)
    if hvac_sequential_load_fracs[:htg].sum > 0
      ideal_air.setHeatingLimit('NoLimit')
    else
      ideal_air.setHeatingLimit('LimitCapacity')
      ideal_air.setMaximumSensibleHeatingCapacity(0)
    end
    if hvac_sequential_load_fracs[:clg].sum > 0
      ideal_air.setCoolingLimit('NoLimit')
    else
      ideal_air.setCoolingLimit('LimitCapacity')
      ideal_air.setMaximumTotalCoolingCapacity(0)
    end
    ideal_air.setDehumidificationControlType('None')
    ideal_air.setHumidificationControlType('None')
    ideal_air.addToThermalZone(control_zone)

    set_sequential_load_fractions(model, control_zone, ideal_air, hvac_sequential_load_fracs, hvac_unavailable_periods)
  end

  # Adds any HPXML Dehumidifiers to the OpenStudio model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [nil]
  def self.apply_dehumidifiers(runner, model, spaces, hpxml_bldg, hpxml_header)
    dehumidifiers = hpxml_bldg.dehumidifiers
    return if dehumidifiers.size == 0

    conditioned_space = spaces[HPXML::LocationConditionedSpace]
    unit_multiplier = hpxml_bldg.building_construction.number_of_units

    dehumidifier_id = dehumidifiers[0].id # Syncs with the ReportSimulationOutput measure, which only looks at first dehumidifier ID

    if dehumidifiers.map { |d| d.rh_setpoint }.uniq.size > 1
      fail 'All dehumidifiers must have the same setpoint but multiple setpoints were specified.'
    end

    if unit_multiplier > 1
      # FUTURE: Figure out how to allow this. If we allow it, update docs and hpxml_translator_test.rb too.
      # https://github.com/NREL/OpenStudio-HPXML/issues/1499
      fail 'NumberofUnits greater than 1 is not supported for dehumidifiers.'
    end

    # Dehumidifier coefficients
    # Generic model coefficients from Winkler, Christensen, and Tomerlin (2011)
    w_coeff = [-1.162525707, 0.02271469, -0.000113208, 0.021110538, -0.0000693034, 0.000378843]
    ef_coeff = [-1.902154518, 0.063466565, -0.000622839, 0.039540407, -0.000125637, -0.000176722]
    pl_coeff = [0.90, 0.10, 0.0]

    dehumidifiers.each do |d|
      next unless d.energy_factor.nil?

      # shift inputs tested under IEF test conditions to those under EF test conditions with performance curves
      d.energy_factor, d.capacity = apply_dehumidifier_ief_to_ef_inputs(d.type, w_coeff, ef_coeff, d.integrated_energy_factor, d.capacity)
    end

    # Combine HPXML dehumidifiers into a single EnergyPlus dehumidifier
    total_capacity = dehumidifiers.map { |d| d.capacity }.sum
    avg_energy_factor = dehumidifiers.map { |d| d.energy_factor * d.capacity }.sum / total_capacity
    total_fraction_served = dehumidifiers.map { |d| d.fraction_served }.sum

    # Apply unit multiplier
    total_capacity *= unit_multiplier

    control_zone = conditioned_space.thermalZone.get
    obj_name = Constants::ObjectTypeDehumidifier

    rh_setpoint = dehumidifiers[0].rh_setpoint * 100.0 # (EnergyPlus uses 60 for 60% RH)
    rh_setpoint_sch = Model.add_schedule_constant(
      model,
      name: "#{obj_name} rh setpoint",
      value: rh_setpoint
    )

    capacity_curve = Model.add_curve_biquadratic(
      model,
      name: 'DXDH-CAP-fT',
      coeff: w_coeff,
      min_x: -100, max_x: 100, min_y: -100, max_y: 100
    )
    energy_factor_curve = Model.add_curve_biquadratic(
      model,
      name: 'DXDH-EF-fT',
      coeff: ef_coeff,
      min_x: -100, max_x: 100, min_y: -100, max_y: 100
    )
    part_load_frac_curve = Model.add_curve_quadratic(
      model,
      name: 'DXDH-PLF-fPLR',
      coeff: pl_coeff,
      min_x: 0, max_x: 1, min_y: 0.7, max_y: 1
    )

    # Calculate air flow rate by assuming 2.75 cfm/pint/day (based on experimental test data)
    air_flow_rate = 2.75 * total_capacity

    # Humidity Setpoint
    humidistat = OpenStudio::Model::ZoneControlHumidistat.new(model)
    humidistat.setName(obj_name + ' humidistat')
    humidistat.setHumidifyingRelativeHumiditySetpointSchedule(rh_setpoint_sch)
    humidistat.setDehumidifyingRelativeHumiditySetpointSchedule(rh_setpoint_sch)
    control_zone.setZoneControlHumidistat(humidistat)

    # Availability Schedule
    dehum_unavailable_periods = Schedule.get_unavailable_periods(runner, SchedulesFile::Columns[:Dehumidifier].name, hpxml_header.unavailable_periods)
    avail_sch = ScheduleConstant.new(model, obj_name + ' schedule', 1.0, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: dehum_unavailable_periods)
    avail_sch = avail_sch.schedule

    # Dehumidifier
    zone_hvac = OpenStudio::Model::ZoneHVACDehumidifierDX.new(model, capacity_curve, energy_factor_curve, part_load_frac_curve)
    zone_hvac.setName(obj_name)
    zone_hvac.setAvailabilitySchedule(avail_sch)
    zone_hvac.setRatedWaterRemoval(UnitConversions.convert(total_capacity, 'pint', 'L'))
    zone_hvac.setRatedEnergyFactor(avg_energy_factor / total_fraction_served)
    zone_hvac.setRatedAirFlowRate(UnitConversions.convert(air_flow_rate, 'cfm', 'm^3/s'))
    zone_hvac.setMinimumDryBulbTemperatureforDehumidifierOperation(10)
    zone_hvac.setMaximumDryBulbTemperatureforDehumidifierOperation(40)
    zone_hvac.addToThermalZone(control_zone)
    zone_hvac.additionalProperties.setFeature('HPXML_ID', dehumidifier_id) # Used by reporting measure

    if total_fraction_served < 1.0
      add_dehumidifier_load_adjustment_ems_program(total_fraction_served, zone_hvac, model, conditioned_space)
    end
  end

  # Adds an HPXML Ceiling Fan to the OpenStudio model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def self.apply_ceiling_fans(runner, model, spaces, weather, hpxml_bldg, hpxml_header, schedules_file)
    if hpxml_bldg.building_occupancy.number_of_residents == 0
      # Operational calculation w/ zero occupants, zero out energy use
      return
    end
    return if hpxml_bldg.ceiling_fans.size == 0

    ceiling_fan = hpxml_bldg.ceiling_fans[0]

    obj_name = Constants::ObjectTypeCeilingFan
    hrs_per_day = 10.5 # From ANSI/RESNET/ICC 301-2022
    cfm_per_w = ceiling_fan.efficiency
    label_energy_use = ceiling_fan.label_energy_use
    count = ceiling_fan.count
    if !label_energy_use.nil? # priority if both provided
      annual_kwh = UnitConversions.convert(count * label_energy_use * hrs_per_day * 365.0, 'Wh', 'kWh')
    elsif !cfm_per_w.nil?
      medium_cfm = 3000.0 # cfm, per ANSI/RESNET/ICC 301-2019
      annual_kwh = UnitConversions.convert(count * medium_cfm / cfm_per_w * hrs_per_day * 365.0, 'Wh', 'kWh')
    end

    # Create schedule
    ceiling_fan_sch = nil
    ceiling_fan_col_name = SchedulesFile::Columns[:CeilingFan].name
    if not schedules_file.nil?
      annual_kwh *= Defaults.get_ceiling_fan_months(weather).map(&:to_f).sum(0.0) / 12.0
      ceiling_fan_design_level = schedules_file.calc_design_level_from_annual_kwh(col_name: ceiling_fan_col_name, annual_kwh: annual_kwh)
      ceiling_fan_sch = schedules_file.create_schedule_file(model, col_name: ceiling_fan_col_name)
    end
    if ceiling_fan_sch.nil?
      ceiling_fan_unavailable_periods = Schedule.get_unavailable_periods(runner, ceiling_fan_col_name, hpxml_header.unavailable_periods)
      annual_kwh *= ceiling_fan.monthly_multipliers.split(',').map(&:to_f).sum(0.0) / 12.0
      ceiling_fan_sch_obj = MonthWeekdayWeekendSchedule.new(model, obj_name + ' schedule', ceiling_fan.weekday_fractions, ceiling_fan.weekend_fractions, ceiling_fan.monthly_multipliers, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: ceiling_fan_unavailable_periods)
      ceiling_fan_design_level = ceiling_fan_sch_obj.calc_design_level_from_daily_kwh(annual_kwh / 365.0)
      ceiling_fan_sch = ceiling_fan_sch_obj.schedule
    else
      runner.registerWarning("Both '#{ceiling_fan_col_name}' schedule file and weekday fractions provided; the latter will be ignored.") if !ceiling_fan.weekday_fractions.nil?
      runner.registerWarning("Both '#{ceiling_fan_col_name}' schedule file and weekend fractions provided; the latter will be ignored.") if !ceiling_fan.weekend_fractions.nil?
      runner.registerWarning("Both '#{ceiling_fan_col_name}' schedule file and monthly multipliers provided; the latter will be ignored.") if !ceiling_fan.monthly_multipliers.nil?
    end

    Model.add_electric_equipment(
      model,
      name: obj_name,
      end_use: obj_name,
      space: spaces[HPXML::LocationConditionedSpace],
      design_level: ceiling_fan_design_level,
      frac_radiant: 0.558,
      frac_latent: 0,
      frac_lost: 0,
      schedule: ceiling_fan_sch
    )
  end

  # Adds an HPXML HVAC Control to the OpenStudio model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [Hash] Map of htg/clg => Array of 365 days with 1s during the heating/cooling season and 0s otherwise
  def self.apply_setpoints(runner, model, weather, spaces, hpxml_bldg, hpxml_header, schedules_file)
    return {} if hpxml_bldg.hvac_controls.size == 0

    hvac_control = hpxml_bldg.hvac_controls[0]
    conditioned_zone = spaces[HPXML::LocationConditionedSpace].thermalZone.get
    has_ceiling_fan = (hpxml_bldg.ceiling_fans.size > 0)

    # Set 365 (or 366 for a leap year) heating/cooling day arrays based on heating/cooling seasons.
    hvac_season_days = {}
    hvac_season_days[:htg] = Calendar.get_daily_season(hpxml_header.sim_calendar_year, hvac_control.seasons_heating_begin_month, hvac_control.seasons_heating_begin_day,
                                                       hvac_control.seasons_heating_end_month, hvac_control.seasons_heating_end_day)
    hvac_season_days[:clg] = Calendar.get_daily_season(hpxml_header.sim_calendar_year, hvac_control.seasons_cooling_begin_month, hvac_control.seasons_cooling_begin_day,
                                                       hvac_control.seasons_cooling_end_month, hvac_control.seasons_cooling_end_day)
    if hvac_season_days[:htg].include?(0) || hvac_season_days[:clg].include?(0)
      runner.registerWarning('It is not possible to eliminate all HVAC energy use (e.g. crankcase/defrost energy) in EnergyPlus outside of an HVAC season.')
    end

    heating_sch = nil
    cooling_sch = nil
    year = hpxml_header.sim_calendar_year
    onoff_thermostat_ddb = hpxml_header.hvac_onoff_thermostat_deadband.to_f
    if not schedules_file.nil?
      heating_sch = schedules_file.create_schedule_file(model, col_name: SchedulesFile::Columns[:HeatingSetpoint].name)
    end
    if not schedules_file.nil?
      cooling_sch = schedules_file.create_schedule_file(model, col_name: SchedulesFile::Columns[:CoolingSetpoint].name)
    end

    # permit mixing detailed schedules with simple schedules
    if heating_sch.nil?
      htg_wd_setpoints, htg_we_setpoints = get_heating_setpoints(hvac_control, year, onoff_thermostat_ddb)
    else
      runner.registerWarning("Both '#{SchedulesFile::Columns[:HeatingSetpoint].name}' schedule file and heating setpoint temperature provided; the latter will be ignored.") if !hvac_control.heating_setpoint_temp.nil?
    end

    if cooling_sch.nil?
      clg_wd_setpoints, clg_we_setpoints = get_cooling_setpoints(hpxml_bldg, hvac_control, has_ceiling_fan, year, weather, onoff_thermostat_ddb)
    else
      runner.registerWarning("Both '#{SchedulesFile::Columns[:CoolingSetpoint].name}' schedule file and cooling setpoint temperature provided; the latter will be ignored.") if !hvac_control.cooling_setpoint_temp.nil?
    end

    # only deal with deadband issue if both schedules are simple
    if heating_sch.nil? && cooling_sch.nil?
      htg_wd_setpoints, htg_we_setpoints, clg_wd_setpoints, clg_we_setpoints = create_setpoint_schedules(runner, htg_wd_setpoints, htg_we_setpoints, clg_wd_setpoints, clg_we_setpoints, year, hvac_season_days)
    end

    if heating_sch.nil?
      heating_setpoint = HourlyByDaySchedule.new(model, 'heating setpoint', htg_wd_setpoints, htg_we_setpoints, nil, false)
      heating_sch = heating_setpoint.schedule
    end

    if cooling_sch.nil?
      cooling_setpoint = HourlyByDaySchedule.new(model, 'cooling setpoint', clg_wd_setpoints, clg_we_setpoints, nil, false)
      cooling_sch = cooling_setpoint.schedule
    end

    # Set the setpoint schedules
    thermostat_setpoint = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(model)
    thermostat_setpoint.setName("#{conditioned_zone.name} temperature setpoint")
    thermostat_setpoint.setHeatingSetpointTemperatureSchedule(heating_sch)
    thermostat_setpoint.setCoolingSetpointTemperatureSchedule(cooling_sch)
    thermostat_setpoint.setTemperatureDifferenceBetweenCutoutAndSetpoint(UnitConversions.convert(onoff_thermostat_ddb, 'deltaF', 'deltaC'))
    conditioned_zone.setThermostatSetpointDualSetpoint(thermostat_setpoint)

    return hvac_season_days
  end

  # Creates setpoint schedules.
  # This method ensures that we don't construct a setpoint schedule where the cooling setpoint
  # is less than the heating setpoint, which would result in an E+ error.
  #
  # Note: It's tempting to adjust the setpoints, e.g., outside of the heating/cooling seasons,
  # to prevent unmet hours being reported. This is a dangerous idea. These setpoints are used
  # by natural ventilation, Kiva initialization, and probably other things.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param htg_wd_setpoints [TODO] TODO
  # @param htg_we_setpoints [TODO] TODO
  # @param clg_wd_setpoints [TODO] TODO
  # @param clg_we_setpoints [TODO] TODO
  # @param year [Integer] the calendar year
  # @param hvac_season_days [Hash] Map of htg/clg => Array of 365 days with 1s during the heating/cooling season and 0s otherwise
  # @return [TODO] TODO
  def self.create_setpoint_schedules(runner, htg_wd_setpoints, htg_we_setpoints, clg_wd_setpoints, clg_we_setpoints, year,
                                     hvac_season_days)
    warning = false
    for i in 0..(Calendar.num_days_in_year(year) - 1)
      if (hvac_season_days[:htg][i] == hvac_season_days[:clg][i]) # both (or neither) heating/cooling seasons
        htg_wkdy = htg_wd_setpoints[i].zip(clg_wd_setpoints[i]).map { |h, c| c < h ? (h + c) / 2.0 : h }
        htg_wked = htg_we_setpoints[i].zip(clg_we_setpoints[i]).map { |h, c| c < h ? (h + c) / 2.0 : h }
        clg_wkdy = htg_wd_setpoints[i].zip(clg_wd_setpoints[i]).map { |h, c| c < h ? (h + c) / 2.0 : c }
        clg_wked = htg_we_setpoints[i].zip(clg_we_setpoints[i]).map { |h, c| c < h ? (h + c) / 2.0 : c }
      elsif hvac_season_days[:htg][i] == 1 # heating only seasons; cooling has minimum of heating
        htg_wkdy = htg_wd_setpoints[i]
        htg_wked = htg_we_setpoints[i]
        clg_wkdy = htg_wd_setpoints[i].zip(clg_wd_setpoints[i]).map { |h, c| c < h ? h : c }
        clg_wked = htg_we_setpoints[i].zip(clg_we_setpoints[i]).map { |h, c| c < h ? h : c }
      elsif hvac_season_days[:clg][i] == 1 # cooling only seasons; heating has maximum of cooling
        htg_wkdy = clg_wd_setpoints[i].zip(htg_wd_setpoints[i]).map { |c, h| c < h ? c : h }
        htg_wked = clg_we_setpoints[i].zip(htg_we_setpoints[i]).map { |c, h| c < h ? c : h }
        clg_wkdy = clg_wd_setpoints[i]
        clg_wked = clg_we_setpoints[i]
      else
        fail 'HeatingSeason and CoolingSeason, when combined, must span the entire year.'
      end
      if (htg_wkdy != htg_wd_setpoints[i]) || (htg_wked != htg_we_setpoints[i]) || (clg_wkdy != clg_wd_setpoints[i]) || (clg_wked != clg_we_setpoints[i])
        warning = true
      end
      htg_wd_setpoints[i] = htg_wkdy
      htg_we_setpoints[i] = htg_wked
      clg_wd_setpoints[i] = clg_wkdy
      clg_we_setpoints[i] = clg_wked
    end

    if warning
      runner.registerWarning('HVAC setpoints have been automatically adjusted to prevent periods where the heating setpoint is greater than the cooling setpoint.')
    end

    return htg_wd_setpoints, htg_we_setpoints, clg_wd_setpoints, clg_we_setpoints
  end

  # TODO
  #
  # @param hvac_control [HPXML::HVACControl] The HPXML HVAC control of interest
  # @param year [Integer] the calendar year
  # @param offset_db [Double] On-off thermostat deadband (F)
  # @return [TODO] TODO
  def self.get_heating_setpoints(hvac_control, year, offset_db)
    num_days = Calendar.num_days_in_year(year)

    if hvac_control.weekday_heating_setpoints.nil? || hvac_control.weekend_heating_setpoints.nil?
      # Base heating setpoint
      htg_setpoint = hvac_control.heating_setpoint_temp
      htg_wd_setpoints = [[htg_setpoint] * 24] * num_days
      # Apply heating setback?
      htg_setback = hvac_control.heating_setback_temp
      if not htg_setback.nil?
        htg_setback_hrs_per_week = hvac_control.heating_setback_hours_per_week
        htg_setback_start_hr = hvac_control.heating_setback_start_hour
        for d in 1..num_days
          for hr in htg_setback_start_hr..htg_setback_start_hr + Integer(htg_setback_hrs_per_week / 7.0) - 1
            htg_wd_setpoints[d - 1][hr % 24] = htg_setback
          end
        end
      end
      htg_we_setpoints = htg_wd_setpoints.dup
    else
      # 24-hr weekday/weekend heating setpoint schedules
      htg_wd_setpoints = hvac_control.weekday_heating_setpoints.split(',').map { |i| Float(i) }
      htg_wd_setpoints = [htg_wd_setpoints] * num_days
      htg_we_setpoints = hvac_control.weekend_heating_setpoints.split(',').map { |i| Float(i) }
      htg_we_setpoints = [htg_we_setpoints] * num_days
    end
    # Apply thermostat offset due to onoff control
    htg_wd_setpoints = htg_wd_setpoints.map { |i| i.map { |j| j - offset_db / 2.0 } }
    htg_we_setpoints = htg_we_setpoints.map { |i| i.map { |j| j - offset_db / 2.0 } }

    htg_wd_setpoints = htg_wd_setpoints.map { |i| i.map { |j| UnitConversions.convert(j, 'F', 'C') } }
    htg_we_setpoints = htg_we_setpoints.map { |i| i.map { |j| UnitConversions.convert(j, 'F', 'C') } }

    return htg_wd_setpoints, htg_we_setpoints
  end

  # TODO
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param [HPXML::HVACControl] The HPXML HVAC control of interest
  # @param has_ceiling_fan [TODO] TODO
  # @param year [Integer] the calendar year
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param offset_db [Double] On-off thermostat deadband (F)
  # @return [TODO] TODO
  def self.get_cooling_setpoints(hpxml_bldg, hvac_control, has_ceiling_fan, year, weather, offset_db)
    num_days = Calendar.num_days_in_year(year)

    if hvac_control.weekday_cooling_setpoints.nil? || hvac_control.weekend_cooling_setpoints.nil?
      # Base cooling setpoint
      clg_setpoint = hvac_control.cooling_setpoint_temp
      clg_wd_setpoints = [[clg_setpoint] * 24] * num_days
      # Apply cooling setup?
      clg_setup = hvac_control.cooling_setup_temp
      if not clg_setup.nil?
        clg_setup_hrs_per_week = hvac_control.cooling_setup_hours_per_week
        clg_setup_start_hr = hvac_control.cooling_setup_start_hour
        for d in 1..num_days
          for hr in clg_setup_start_hr..clg_setup_start_hr + Integer(clg_setup_hrs_per_week / 7.0) - 1
            clg_wd_setpoints[d - 1][hr % 24] = clg_setup
          end
        end
      end
      clg_we_setpoints = clg_wd_setpoints.dup
    else
      # 24-hr weekday/weekend cooling setpoint schedules
      clg_wd_setpoints = hvac_control.weekday_cooling_setpoints.split(',').map { |i| Float(i) }
      clg_wd_setpoints = [clg_wd_setpoints] * num_days
      clg_we_setpoints = hvac_control.weekend_cooling_setpoints.split(',').map { |i| Float(i) }
      clg_we_setpoints = [clg_we_setpoints] * num_days
    end

    # Apply cooling setpoint offset due to ceiling fan?
    if has_ceiling_fan && hpxml_bldg.building_occupancy.number_of_residents != 0 # If operational calculation w/ zero occupants, exclude ceiling fan setpoint adjustment
      clg_ceiling_fan_offset = hvac_control.ceiling_fan_cooling_setpoint_temp_offset
      if not clg_ceiling_fan_offset.nil?
        months = Defaults.get_ceiling_fan_months(weather)
        Calendar.months_to_days(year, months).each_with_index do |operation, d|
          next if operation != 1

          clg_wd_setpoints[d] = [clg_wd_setpoints[d], Array.new(24, clg_ceiling_fan_offset)].transpose.map { |i| i.sum }
          clg_we_setpoints[d] = [clg_we_setpoints[d], Array.new(24, clg_ceiling_fan_offset)].transpose.map { |i| i.sum }
        end
      end
    end

    # Apply thermostat offset due to onoff control
    clg_wd_setpoints = clg_wd_setpoints.map { |i| i.map { |j| j + offset_db / 2.0 } }
    clg_we_setpoints = clg_we_setpoints.map { |i| i.map { |j| j + offset_db / 2.0 } }
    clg_wd_setpoints = clg_wd_setpoints.map { |i| i.map { |j| UnitConversions.convert(j, 'F', 'C') } }
    clg_we_setpoints = clg_we_setpoints.map { |i| i.map { |j| UnitConversions.convert(j, 'F', 'C') } }

    return clg_wd_setpoints, clg_we_setpoints
  end

  # TODO
  #
  # @param compressor_type [TODO] TODO
  # @return [TODO] TODO
  def self.get_cool_cap_eir_ft_spec(compressor_type)
    case compressor_type
    when HPXML::HVACCompressorTypeSingleStage
      cap_ft_spec = [[3.68637657, -0.098352478, 0.000956357, 0.005838141, -0.0000127, -0.000131702]]
      eir_ft_spec = [[-3.437356399, 0.136656369, -0.001049231, -0.0079378, 0.000185435, -0.0001441]]
    when HPXML::HVACCompressorTypeTwoStage
      cap_ft_spec = [[3.998418659, -0.108728222, 0.001056818, 0.007512314, -0.0000139, -0.000164716],
                     [3.466810106, -0.091476056, 0.000901205, 0.004163355, -0.00000919, -0.000110829]]
      eir_ft_spec = [[-4.282911381, 0.181023691, -0.001357391, -0.026310378, 0.000333282, -0.000197405],
                     [-3.557757517, 0.112737397, -0.000731381, 0.013184877, 0.000132645, -0.000338716]]
    end
    return cap_ft_spec, eir_ft_spec
  end

  # TODO
  #
  # @param compressor_type [TODO] TODO
  # @return [TODO] TODO
  def self.get_cool_cap_eir_fflow_spec(compressor_type)
    case compressor_type
    when HPXML::HVACCompressorTypeSingleStage
      # Single stage systems have PSC or constant torque ECM blowers, so the airflow rate is affected by the static pressure losses.
      cap_fflow_spec = [[0.718664047, 0.41797409, -0.136638137]]
      eir_fflow_spec = [[1.143487507, -0.13943972, -0.004047787]]
    when HPXML::HVACCompressorTypeTwoStage
      # Most two stage systems have PSC or constant torque ECM blowers, so the airflow rate is affected by the static pressure losses.
      cap_fflow_spec = [[0.655239515, 0.511655216, -0.166894731],
                        [0.618281092, 0.569060264, -0.187341356]]
      eir_fflow_spec = [[1.639108268, -0.998953996, 0.359845728],
                        [1.570774717, -0.914152018, 0.343377302]]
    when HPXML::HVACCompressorTypeVariableSpeed
      # Variable speed systems have constant flow ECM blowers, so the air handler can always achieve the design airflow rate by sacrificing blower power.
      # So we assume that there is only one corresponding airflow rate for each compressor speed.
      eir_fflow_spec = [[1, 0, 0]] * 2
      cap_fflow_spec = [[1, 0, 0]] * 2
    end
    return cap_fflow_spec, eir_fflow_spec
  end

  # TODO
  #
  # @param compressor_type [TODO] TODO
  # @param heating_capacity_retention_temp [TODO] TODO
  # @param heating_capacity_retention_fraction [TODO] TODO
  # @return [TODO] TODO
  def self.get_heat_cap_eir_ft_spec(compressor_type, heating_capacity_retention_temp, heating_capacity_retention_fraction)
    cap_ft_spec = calc_heat_cap_ft_spec(compressor_type, heating_capacity_retention_temp, heating_capacity_retention_fraction)
    if compressor_type == HPXML::HVACCompressorTypeSingleStage
      # From "Improved Modeling of Residential Air Conditioners and Heat Pumps for Energy Calculations", Cutler et al
      # https://www.nrel.gov/docs/fy13osti/56354.pdf
      eir_ft_spec = [[0.718398423, 0.003498178, 0.000142202, -0.005724331, 0.00014085, -0.000215321]]
    elsif compressor_type == HPXML::HVACCompressorTypeTwoStage
      # From "Improved Modeling of Residential Air Conditioners and Heat Pumps for Energy Calculations", Cutler et al
      # https://www.nrel.gov/docs/fy13osti/56354.pdf
      eir_ft_spec = [[0.36338171, 0.013523725, 0.000258872, -0.009450269, 0.000439519, -0.000653723],
                     [0.981100941, -0.005158493, 0.000243416, -0.005274352, 0.000230742, -0.000336954]]
    end
    return cap_ft_spec, eir_ft_spec
  end

  # TODO
  #
  # @param compressor_type [TODO] TODO
  # @return [TODO] TODO
  def self.get_heat_cap_eir_fflow_spec(compressor_type)
    case compressor_type
    when HPXML::HVACCompressorTypeSingleStage
      # Single stage systems have PSC or constant torque ECM blowers, so the airflow rate is affected by the static pressure losses.
      cap_fflow_spec = [[0.694045465, 0.474207981, -0.168253446]]
      eir_fflow_spec = [[2.185418751, -1.942827919, 0.757409168]]
    when HPXML::HVACCompressorTypeTwoStage
      # Most two stage systems have PSC or constant torque ECM blowers, so the airflow rate is affected by the static pressure losses.
      cap_fflow_spec = [[0.741466907, 0.378645444, -0.119754733],
                        [0.76634609, 0.32840943, -0.094701495]]
      eir_fflow_spec = [[2.153618211, -1.737190609, 0.584269478],
                        [2.001041353, -1.58869128, 0.587593517]]
    when HPXML::HVACCompressorTypeVariableSpeed
      # Variable speed systems have constant flow ECM blowers, so the air handler can always achieve the design airflow rate by sacrificing blower power.
      # So we assume that there is only one corresponding airflow rate for each compressor speed.
      cap_fflow_spec = [[1, 0, 0]] * 3
      eir_fflow_spec = [[1, 0, 0]] * 3
    end
    return cap_fflow_spec, eir_fflow_spec
  end

  # TODO
  #
  # @param cooling_system [TODO] TODO
  # @param use_eer [TODO] TODO
  # @return [nil]
  def self.set_cool_curves_central_air_source(cooling_system, use_eer = false)
    clg_ap = cooling_system.additional_properties
    clg_ap.cool_rated_cfm_per_ton = get_cool_cfm_per_ton(cooling_system.compressor_type, use_eer)
    clg_ap.cool_capacity_ratios = get_cool_capacity_ratios(cooling_system)
    set_cool_c_d(cooling_system)

    seer = cooling_system.cooling_efficiency_seer
    case cooling_system.compressor_type
    when HPXML::HVACCompressorTypeSingleStage
      clg_ap.cool_cap_ft_spec, clg_ap.cool_eir_ft_spec = get_cool_cap_eir_ft_spec(cooling_system.compressor_type)
      if not use_eer
        clg_ap.cool_rated_airflow_rate = clg_ap.cool_rated_cfm_per_ton[0]
        clg_ap.cool_fan_speed_ratios = calc_fan_speed_ratios(clg_ap.cool_capacity_ratios, clg_ap.cool_rated_cfm_per_ton, clg_ap.cool_rated_airflow_rate)
        clg_ap.cool_cap_fflow_spec, clg_ap.cool_eir_fflow_spec = get_cool_cap_eir_fflow_spec(cooling_system.compressor_type)
        clg_ap.cool_rated_cops = [0.2692 * seer + 0.2706] # Regression based on inverse model
      else
        clg_ap.cool_fan_speed_ratios = [1.0]
        clg_ap.cool_cap_fflow_spec = [[1.0, 0.0, 0.0]]
        clg_ap.cool_eir_fflow_spec = [[1.0, 0.0, 0.0]]
      end

    when HPXML::HVACCompressorTypeTwoStage
      clg_ap.cool_rated_airflow_rate = clg_ap.cool_rated_cfm_per_ton[-1]
      clg_ap.cool_fan_speed_ratios = calc_fan_speed_ratios(clg_ap.cool_capacity_ratios, clg_ap.cool_rated_cfm_per_ton, clg_ap.cool_rated_airflow_rate)
      clg_ap.cool_cap_ft_spec, clg_ap.cool_eir_ft_spec = get_cool_cap_eir_ft_spec(cooling_system.compressor_type)
      clg_ap.cool_cap_fflow_spec, clg_ap.cool_eir_fflow_spec = get_cool_cap_eir_fflow_spec(cooling_system.compressor_type)
      clg_ap.cool_rated_cops = [0.2773 * seer - 0.0018] # Regression based on inverse model
      clg_ap.cool_rated_cops << clg_ap.cool_rated_cops[0] * 0.91 # COP ratio based on Dylan's data as seen in BEopt 2.8 options

    when HPXML::HVACCompressorTypeVariableSpeed
      clg_ap.cooling_capacity_retention_temperature = 82.0
      clg_ap.cooling_capacity_retention_fraction = 1.033 # From NEEP data
      clg_ap.cool_rated_airflow_rate = clg_ap.cool_rated_cfm_per_ton[-1]
      clg_ap.cool_fan_speed_ratios = calc_fan_speed_ratios(clg_ap.cool_capacity_ratios, clg_ap.cool_rated_cfm_per_ton, clg_ap.cool_rated_airflow_rate)
      clg_ap.cool_cap_fflow_spec, clg_ap.cool_eir_fflow_spec = get_cool_cap_eir_fflow_spec(cooling_system.compressor_type)
    end

    set_cool_rated_shrs_gross(cooling_system)
  end

  # TODO
  #
  # @param hvac_system [TODO] TODO
  # @return [TODO] TODO
  def self.get_cool_capacity_ratios(hvac_system)
    # For each speed, ratio of capacity to nominal capacity
    case hvac_system.compressor_type
    when HPXML::HVACCompressorTypeSingleStage
      return [1.0]
    when HPXML::HVACCompressorTypeTwoStage
      return [0.72, 1.0]
    when HPXML::HVACCompressorTypeVariableSpeed
      is_ducted = !hvac_system.distribution_system_idref.nil?
      if is_ducted
        return [0.394, 1.0]
      else
        return [0.255, 1.0]
      end
    end

    fail 'Unable to get cooling capacity ratios.'
  end

  # Geothermal heat pump cooling capacity ratios for advanced model (variable-speed coils)
  #
  # @param heat_pump [HPXML::HeatPump] HPXML Heat Pump object
  # @return [Array<Double, Double>] Cooling apacity ratios at each speed
  def self.get_cool_capacity_ratios_gshp(heat_pump)
    # For each speed, ratio of capacity to nominal capacity
    case heat_pump.compressor_type
    when HPXML::HVACCompressorTypeSingleStage
      return [1.0]
    when HPXML::HVACCompressorTypeTwoStage
      return [0.7353, 1.0]
    when HPXML::HVACCompressorTypeVariableSpeed
      return [0.4802, 1.0]
    end

    fail 'Unable to get cooling capacity ratios.'
  end

  # TODO
  #
  # @param heating_system [TODO] TODO
  # @param use_cop [TODO] TODO
  # @return [nil]
  def self.set_heat_curves_central_air_source(heating_system, use_cop = false)
    htg_ap = heating_system.additional_properties
    htg_ap.heat_rated_cfm_per_ton = get_heat_cfm_per_ton(heating_system.compressor_type, use_cop)
    htg_ap.heat_cap_fflow_spec, htg_ap.heat_eir_fflow_spec = get_heat_cap_eir_fflow_spec(heating_system.compressor_type)
    htg_ap.heat_capacity_ratios = get_heat_capacity_ratios(heating_system)
    set_heat_c_d(heating_system)

    hspf = heating_system.heating_efficiency_hspf
    case heating_system.compressor_type
    when HPXML::HVACCompressorTypeSingleStage
      heating_capacity_retention_temp, heating_capacity_retention_fraction = get_heating_capacity_retention(heating_system)
      htg_ap.heat_cap_ft_spec, htg_ap.heat_eir_ft_spec = get_heat_cap_eir_ft_spec(heating_system.compressor_type, heating_capacity_retention_temp, heating_capacity_retention_fraction)
      if not use_cop
        htg_ap.heat_rated_cops = [0.0353 * hspf**2 + 0.0331 * hspf + 0.9447] # Regression based on inverse model
        htg_ap.heat_rated_airflow_rate = htg_ap.heat_rated_cfm_per_ton[0]
        htg_ap.heat_fan_speed_ratios = calc_fan_speed_ratios(htg_ap.heat_capacity_ratios, htg_ap.heat_rated_cfm_per_ton, htg_ap.heat_rated_airflow_rate)
      else
        htg_ap.heat_fan_speed_ratios = [1.0]
      end

    when HPXML::HVACCompressorTypeTwoStage
      heating_capacity_retention_temp, heating_capacity_retention_fraction = get_heating_capacity_retention(heating_system)
      htg_ap.heat_cap_ft_spec, htg_ap.heat_eir_ft_spec = get_heat_cap_eir_ft_spec(heating_system.compressor_type, heating_capacity_retention_temp, heating_capacity_retention_fraction)
      htg_ap.heat_rated_airflow_rate = htg_ap.heat_rated_cfm_per_ton[-1]
      htg_ap.heat_fan_speed_ratios = calc_fan_speed_ratios(htg_ap.heat_capacity_ratios, htg_ap.heat_rated_cfm_per_ton, htg_ap.heat_rated_airflow_rate)
      htg_ap.heat_rated_cops = [0.0426 * hspf**2 - 0.0747 * hspf + 1.5374] # Regression based on inverse model
      htg_ap.heat_rated_cops << htg_ap.heat_rated_cops[0] * 0.87 # COP ratio based on Dylan's data as seen in BEopt 2.8 options

    when HPXML::HVACCompressorTypeVariableSpeed
      htg_ap.heat_rated_airflow_rate = htg_ap.heat_rated_cfm_per_ton[-1]
      htg_ap.heat_capacity_ratios = get_heat_capacity_ratios(heating_system)
      htg_ap.heat_fan_speed_ratios = calc_fan_speed_ratios(htg_ap.heat_capacity_ratios, htg_ap.heat_rated_cfm_per_ton, htg_ap.heat_rated_airflow_rate)
    end
  end

  # TODO
  #
  # @param heat_pump [TODO] TODO
  # @return [nil]
  def self.set_heat_detailed_performance_data(heat_pump)
    hp_ap = heat_pump.additional_properties
    is_ducted = !heat_pump.distribution_system_idref.nil?
    hspf = heat_pump.heating_efficiency_hspf

    # Default data inputs based on NEEP data
    detailed_performance_data = heat_pump.heating_detailed_performance_data
    heating_capacity_retention_temp, heating_capacity_retention_fraction = get_heating_capacity_retention(heat_pump)
    max_cap_maint_5 = 1.0 - (1.0 - heating_capacity_retention_fraction) * (HVAC::AirSourceHeatRatedODB - 5.0) /
                            (HVAC::AirSourceHeatRatedODB - heating_capacity_retention_temp)

    if is_ducted
      a, b, c, d, e = 0.4348, 0.008923, 1.090, -0.1861, -0.07564
    else
      a, b, c, d, e = 0.1914, -1.822, 1.364, -0.07783, 2.221
    end
    max_cop_47 = a * hspf + b * max_cap_maint_5 + c * max_cap_maint_5**2 + d * max_cap_maint_5 * hspf + e
    max_capacity_47 = heat_pump.heating_capacity * hp_ap.heat_capacity_ratios[-1]
    min_capacity_47 = max_capacity_47 / hp_ap.heat_capacity_ratios[-1] * hp_ap.heat_capacity_ratios[0]
    min_cop_47 = is_ducted ? max_cop_47 * (-0.0306 * hspf + 1.5385) : max_cop_47 * (-0.01698 * hspf + 1.5907)
    max_capacity_5 = max_capacity_47 * max_cap_maint_5
    max_cop_5 = is_ducted ? max_cop_47 * 0.587 : max_cop_47 * 0.671
    min_capacity_5 = is_ducted ? min_capacity_47 * 1.106 : min_capacity_47 * 0.611
    min_cop_5 = is_ducted ? min_cop_47 * 0.502 : min_cop_47 * 0.538

    # performance data at 47F, maximum speed
    detailed_performance_data.add(capacity: max_capacity_47.round(1),
                                  efficiency_cop: max_cop_47.round(4),
                                  capacity_description: HPXML::CapacityDescriptionMaximum,
                                  outdoor_temperature: 47,
                                  isdefaulted: true)
    # performance data at 47F, minimum speed
    detailed_performance_data.add(capacity: min_capacity_47.round(1),
                                  efficiency_cop: min_cop_47.round(4),
                                  capacity_description: HPXML::CapacityDescriptionMinimum,
                                  outdoor_temperature: 47,
                                  isdefaulted: true)
    # performance data at 5F, maximum speed
    detailed_performance_data.add(capacity: max_capacity_5.round(1),
                                  efficiency_cop: max_cop_5.round(4),
                                  capacity_description: HPXML::CapacityDescriptionMaximum,
                                  outdoor_temperature: 5,
                                  isdefaulted: true)
    # performance data at 5F, minimum speed
    detailed_performance_data.add(capacity: min_capacity_5.round(1),
                                  efficiency_cop: min_cop_5.round(4),
                                  capacity_description: HPXML::CapacityDescriptionMinimum,
                                  outdoor_temperature: 5,
                                  isdefaulted: true)
  end

  # TODO
  #
  # @param heat_pump [TODO] TODO
  # @return [nil]
  def self.set_cool_detailed_performance_data(heat_pump)
    hp_ap = heat_pump.additional_properties
    is_ducted = !heat_pump.distribution_system_idref.nil?
    seer = heat_pump.cooling_efficiency_seer

    # Default data inputs based on NEEP data
    detailed_performance_data = heat_pump.cooling_detailed_performance_data
    max_cap_maint_82 = 1.0 - (1.0 - hp_ap.cooling_capacity_retention_fraction) * (HVAC::AirSourceCoolRatedODB - 82.0) /
                             (HVAC::AirSourceCoolRatedODB - hp_ap.cooling_capacity_retention_temperature)

    max_cop_95 = is_ducted ? 0.1953 * seer : 0.06635 * seer + 1.8707
    max_capacity_95 = heat_pump.cooling_capacity * hp_ap.cool_capacity_ratios[-1]
    min_capacity_95 = max_capacity_95 / hp_ap.cool_capacity_ratios[-1] * hp_ap.cool_capacity_ratios[0]
    min_cop_95 = is_ducted ? max_cop_95 * 1.231 : max_cop_95 * (0.01377 * seer + 1.13948)
    max_capacity_82 = max_capacity_95 * max_cap_maint_82
    max_cop_82 = is_ducted ? (1.297 * max_cop_95) : (1.300 * max_cop_95)
    min_capacity_82 = min_capacity_95 * 1.099
    min_cop_82 = is_ducted ? (1.402 * min_cop_95) : (1.333 * min_cop_95)

    # performance data at 95F, maximum speed
    detailed_performance_data.add(capacity: max_capacity_95.round(1),
                                  efficiency_cop: max_cop_95.round(4),
                                  capacity_description: HPXML::CapacityDescriptionMaximum,
                                  outdoor_temperature: 95,
                                  isdefaulted: true)
    # performance data at 95F, minimum speed
    detailed_performance_data.add(capacity: min_capacity_95.round(1),
                                  efficiency_cop: min_cop_95.round(4),
                                  capacity_description: HPXML::CapacityDescriptionMinimum,
                                  outdoor_temperature: 95,
                                  isdefaulted: true)
    # performance data at 82F, maximum speed
    detailed_performance_data.add(capacity: max_capacity_82.round(1),
                                  efficiency_cop: max_cop_82.round(4),
                                  capacity_description: HPXML::CapacityDescriptionMaximum,
                                  outdoor_temperature: 82,
                                  isdefaulted: true)
    # performance data at 82F, minimum speed
    detailed_performance_data.add(capacity: min_capacity_82.round(1),
                                  efficiency_cop: min_cop_82.round(4),
                                  capacity_description: HPXML::CapacityDescriptionMinimum,
                                  outdoor_temperature: 82,
                                  isdefaulted: true)
  end

  # TODO
  #
  # @param heat_pump [TODO] TODO
  # @return [TODO] TODO
  def self.get_heat_capacity_ratios(heat_pump)
    # For each speed, ratio of capacity to nominal capacity
    case heat_pump.compressor_type
    when HPXML::HVACCompressorTypeSingleStage
      return [1.0]
    when HPXML::HVACCompressorTypeTwoStage
      return [0.72, 1.0]
    when HPXML::HVACCompressorTypeVariableSpeed
      is_ducted = !heat_pump.distribution_system_idref.nil?
      if is_ducted
        nominal_to_max_ratio = 0.972
      else
        nominal_to_max_ratio = 0.812
      end
      if is_ducted && heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpAirToAir
        # central ducted
        return [0.358 / nominal_to_max_ratio, 1.0, 1.0 / nominal_to_max_ratio]
      elsif !is_ducted
        # wall placement
        return [0.252 / nominal_to_max_ratio, 1.0, 1.0 / nominal_to_max_ratio]
      else
        # ducted minisplit
        return [0.305 / nominal_to_max_ratio, 1.0, 1.0 / nominal_to_max_ratio]
      end
    end

    fail 'Unable to get heating capacity ratios.'
  end

  # Geothermal heat pump heating capacity ratios for advanced model (variable-speed coils)
  #
  # @param heat_pump [HPXML::HeatPump] HPXML Heat Pump object
  # @return [Array<Double, Double>] Heating capacity ratios at each speed
  def self.get_heat_capacity_ratios_gshp(heat_pump)
    # For each speed, ratio of capacity to nominal capacity
    case heat_pump.compressor_type
    when HPXML::HVACCompressorTypeSingleStage
      return [1.0]
    when HPXML::HVACCompressorTypeTwoStage
      return [0.7374, 1.0]
    when HPXML::HVACCompressorTypeVariableSpeed
      return [0.4473, 1.0]
    end

    fail 'Unable to get cooling capacity ratios.'
  end

  # TODO
  #
  # @param hvac_system [TODO] TODO
  # @return [nil]
  def self.drop_intermediate_speeds(hvac_system)
    # For variable-speed systems, we only want to model min/max speeds in E+.
    # Here we drop any intermediate speeds that we may have added for other purposes (e.g. hvac sizing).
    return unless hvac_system.compressor_type == HPXML::HVACCompressorTypeVariableSpeed

    hvac_ap = hvac_system.additional_properties

    while hvac_ap.cool_capacity_ratios.size > 2
      hvac_ap.cool_cap_fflow_spec.delete_at(1)
      hvac_ap.cool_eir_fflow_spec.delete_at(1)
      hvac_ap.cool_plf_fplr_spec.delete_at(1)
      hvac_ap.cool_rated_cfm_per_ton.delete_at(1)
      hvac_ap.cool_capacity_ratios.delete_at(1)
      hvac_ap.cool_fan_speed_ratios.delete_at(1)
    end
    if hvac_system.is_a? HPXML::HeatPump
      while hvac_ap.heat_capacity_ratios.size > 2
        hvac_ap.heat_cap_fflow_spec.delete_at(1)
        hvac_ap.heat_eir_fflow_spec.delete_at(1)
        hvac_ap.heat_plf_fplr_spec.delete_at(1)
        hvac_ap.heat_rated_cfm_per_ton.delete_at(1)
        hvac_ap.heat_capacity_ratios.delete_at(1)
        hvac_ap.heat_fan_speed_ratios.delete_at(1)
      end
    end
  end

  # TODO
  #
  # @param compressor_type [TODO] TODO
  # @param use_eer [TODO] TODO
  # @return [TODO] TODO
  def self.get_cool_cfm_per_ton(compressor_type, use_eer = false)
    # cfm/ton of rated capacity
    if compressor_type == HPXML::HVACCompressorTypeSingleStage
      if not use_eer
        return [394.2]
      else
        return [312] # medium speed
      end
    elsif compressor_type == HPXML::HVACCompressorTypeTwoStage
      return [411.0083, 344.1]
    elsif compressor_type == HPXML::HVACCompressorTypeVariableSpeed
      return [400.0, 400.0]
    else
      fail 'Compressor type not supported.'
    end
  end

  # TODO
  #
  # @param compressor_type [TODO] TODO
  # @param use_cop_or_htg_sys [TODO] TODO
  # @return [TODO] TODO
  def self.get_heat_cfm_per_ton(compressor_type, use_cop_or_htg_sys = false)
    # cfm/ton of rated capacity
    case compressor_type
    when HPXML::HVACCompressorTypeSingleStage
      if not use_cop_or_htg_sys
        return [384.1]
      else
        return [350]
      end
    when HPXML::HVACCompressorTypeTwoStage
      return [391.3333, 352.2]
    when HPXML::HVACCompressorTypeVariableSpeed
      return [400.0, 400.0, 400.0]
    else
      fail 'Compressor type not supported.'
    end
  end

  # Set geothermal heat pump additional properties for modeling
  #
  # @param heat_pump [HPXML::HeatPump] HPXML Heat Pump object
  # @param hpxml_header [HPXML::Header] HPXML Header object
  # @return [nil]
  def self.set_curves_gshp(heat_pump, hpxml_header)
    hp_ap = heat_pump.additional_properties

    case hpxml_header.ground_to_air_heat_pump_model_type
    when HPXML::AdvancedResearchGroundToAirHeatPumpModelTypeStandard
      hp_ap.cool_capacity_ratios = [1.0]
      hp_ap.heat_capacity_ratios = [1.0]
      hp_ap.cool_rated_cfm_per_ton = [400.0]
      hp_ap.heat_rated_cfm_per_ton = [400.0]
      hp_ap.cool_rated_airflow_rate = hp_ap.cool_rated_cfm_per_ton[-1]
      hp_ap.cool_fan_speed_ratios = calc_fan_speed_ratios(hp_ap.cool_capacity_ratios, hp_ap.cool_rated_cfm_per_ton, hp_ap.cool_rated_airflow_rate)
      hp_ap.heat_rated_airflow_rate = hp_ap.heat_rated_cfm_per_ton[-1]
      hp_ap.heat_fan_speed_ratios = calc_fan_speed_ratios(hp_ap.heat_capacity_ratios, hp_ap.heat_rated_cfm_per_ton, hp_ap.heat_rated_airflow_rate)

      # E+ equation fit coil coefficients generated following approach in Tang's thesis:
      # See Appendix B of  https://shareok.org/bitstream/handle/11244/10075/Tang_okstate_0664M_1318.pdf?sequence=1&isAllowed=y
      # Coefficients generated by catalog data: https://files.climatemaster.com/Genesis-GS-Series-Product-Catalog.pdf, p180
      # Data point taken as rated condition:
      # EWT: 80F EAT:80/67F, AFR: 1200cfm, WFR: 4.5gpm

      # Cooling Curves
      hp_ap.cool_cap_curve_spec = [[-5.45013866666657, 7.42301402824225, -1.43760846638838, 0.249103937703341, 0.0378875477019811]]
      hp_ap.cool_power_curve_spec = [[-4.21572180554818, 0.322682268675807, 4.56870615863483, 0.154605773589744, -0.167531037948482]]
      hp_ap.cool_sh_curve_spec = [[0.56143829895505, 18.7079597251858, -19.1482655264078, -0.138154731772664, 0.4823357726442, -0.00164644360129174]]

      # TODO: Use default gross SHR after RESNET PR: https://github.com/NREL/OpenStudio-HPXML/pull/1879
      hp_ap.cool_rated_shrs_gross = [heat_pump.cooling_shr]

      # E+ equation fit coil coefficients following approach from Tang's thesis:
      # See Appendix B Figure B.3 of  https://shareok.org/bitstream/handle/11244/10075/Tang_okstate_0664M_1318.pdf?sequence=1&isAllowed=y
      # Coefficients generated by catalog data: https://www.climatemaster.com/download/18.274be999165850ccd5b5b73/1535543867815/lc377-climatemaster-commercial-tranquility-20-single-stage-ts-series-water-source-heat-pump-submittal-set.pdf
      # Data point taken as rated condition:
      # EWT: 60F EAT: 70F AFR: 1200 cfm, WFR: 4.5 gpm

      # Heating Curves
      hp_ap.heat_cap_curve_spec = [[-3.75031847962047, -2.18062040443483, 6.8363364819032, 0.188376814356582, 0.0869274802923634]]
      hp_ap.heat_power_curve_spec = [[-8.4754723813072, 8.10952801956388, 1.38771494628738, -0.33766445915032, 0.0223085217874051]]
      cool_cop_ratios = [1.0]
      heat_cop_ratios = [1.0]

    when HPXML::AdvancedResearchGroundToAirHeatPumpModelTypeExperimental
      hp_ap.cool_capacity_ratios = get_cool_capacity_ratios_gshp(heat_pump)
      hp_ap.heat_capacity_ratios = get_heat_capacity_ratios_gshp(heat_pump)
      hp_ap.cool_rated_cfm_per_ton = [400.0] * hp_ap.cool_capacity_ratios.size
      hp_ap.heat_rated_cfm_per_ton = [400.0] * hp_ap.heat_capacity_ratios.size
      hp_ap.cool_rated_airflow_rate = hp_ap.cool_rated_cfm_per_ton[-1]
      hp_ap.cool_fan_speed_ratios = calc_fan_speed_ratios(hp_ap.cool_capacity_ratios, hp_ap.cool_rated_cfm_per_ton, hp_ap.cool_rated_airflow_rate)
      hp_ap.heat_rated_airflow_rate = hp_ap.heat_rated_cfm_per_ton[-1]
      hp_ap.heat_fan_speed_ratios = calc_fan_speed_ratios(hp_ap.heat_capacity_ratios, hp_ap.heat_rated_cfm_per_ton, hp_ap.heat_rated_airflow_rate)
      case heat_pump.compressor_type
      when HPXML::HVACCompressorTypeSingleStage
        # Cooling Curves
        # E+ Capacity and EIR as function of temperature curves(bi-quadratic) generated using E+ HVACCurveFitTool
        # See: https://bigladdersoftware.com/epx/docs/24-2/auxiliary-programs/hvac-performance-curve-fit-tool.html#hvac-performance-curve-fit-tool
        # Catalog data from : https://files.climatemaster.com/Genesis-GS-Series-Product-Catalog.pdf, p180
        # Using E+ rated conditions:
        # Cooling: Indoor air at 67F WB, 80F DB; Entering water temperature: 85F
        hp_ap.cool_cap_ft_spec = [[0.3926140238, 0.0297981297, 0.0000000582, 0.0123906803, -0.0003014284, -0.0001113698]]
        hp_ap.cool_eir_ft_spec = [[1.1828664909, -0.0450835550, 0.0009273315, 0.0056194113, 0.0006683467, -0.0007256237]]
        hp_ap.cool_cap_fflow_spec = [[0.5068, 0.8099, -0.3165]]
        hp_ap.cool_eir_fflow_spec = [[2.0184, -1.6182, 0.5789]]
        hp_ap.cool_cap_fwf_spec = [[1.0, 0.0, 0.0]]
        hp_ap.cool_eir_fwf_spec = [[1.0, 0.0, 0.0]]

        # Heating Curves
        # E+ Capacity and EIR as function of temperature curves(bi-quadratic) generated using E+ HVACCurveFitTool
        # See: https://bigladdersoftware.com/epx/docs/24-2/auxiliary-programs/hvac-performance-curve-fit-tool.html#hvac-performance-curve-fit-tool
        # Catalog data from : https://files.climatemaster.com/Genesis-GS-Series-Product-Catalog.pdf, p180
        # Using E+ rated conditions:
        # Heating: Indoor air at 70F DB; Entering water temperature: 70F
        hp_ap.heat_cap_ft_spec = [[0.7353127278, -0.0035056759, -0.0000439615, 0.0204411095, -0.0000320781, -0.0001322685]]
        hp_ap.heat_eir_ft_spec = [[0.6273820540, 0.0124891750, 0.0012720188, -0.0151581268, 0.0004164343, -0.0007259611]]
        hp_ap.heat_cap_fflow_spec = [[0.7594, 0.3642, -0.1234]]
        hp_ap.heat_eir_fflow_spec = [[2.796, -3.0886, 1.3858]]
        hp_ap.heat_cap_fwf_spec = [[1.0, 0.0, 0.0]]
        hp_ap.heat_eir_fwf_spec = [[1.0, 0.0, 0.0]]
        # TODO: Use default gross SHR after RESNET PR: https://github.com/NREL/OpenStudio-HPXML/pull/1879
        hp_ap.cool_rated_shrs_gross = [heat_pump.cooling_shr]
        cool_cop_ratios = [1.0]
        heat_cop_ratios = [1.0]
      when HPXML::HVACCompressorTypeTwoStage
        # Cooling Curves
        # E+ Capacity and EIR as function of temperature curves(bi-quadratic) generated using E+ HVACCurveFitTool
        # See: https://bigladdersoftware.com/epx/docs/24-2/auxiliary-programs/hvac-performance-curve-fit-tool.html#hvac-performance-curve-fit-tool
        # Catalog data from ClimateMaster residential tranquility 30 premier two-stage series Model SE036: https://files.climatemaster.com/RP3001-Residential-SE-Product-Catalog.pdf
        # Using E+ rated conditions:
        # Cooling: Indoor air at 67F WB, 80F DB; Entering water temperature: 85F
        hp_ap.cool_cap_ft_spec = [[0.4091067504, 0.0387481208, -0.0000003491, 0.0039166842, -0.0001299475, -0.0002883229],
                                  [0.4423161030, 0.0346534683, 0.0000043691, 0.0046060534, -0.0001393465, -0.0002316000]]
        hp_ap.cool_eir_ft_spec = [[1.0242580586, -0.0549907581, 0.0017735749, 0.0186562274, 0.0008900852, -0.0016973518],
                                  [1.0763155558, -0.0396246303, 0.0010677382, 0.0074160145, 0.0006781567, -0.0009009811]]
        hp_ap.cool_cap_fflow_spec = [[0.9064, 0.0793, 0.0143],
                                     [0.8551, 0.1688, -0.0238]]
        hp_ap.cool_eir_fflow_spec = [[0.7931, 0.2623, -0.0552],
                                     [0.8241, 0.1523, 0.0234]]
        hp_ap.cool_cap_fwf_spec = [[0.8387, 0.2903, -0.129],
                                   [0.815, 0.325, -0.14]]
        hp_ap.cool_eir_fwf_spec = [[1.7131, -1.3055, 0.5924],
                                   [1.5872, -1.055, 0.4678]]

        # Heating Curves
        # E+ Capacity and EIR as function of temperature curves(bi-quadratic) generated using E+ HVACCurveFitTool
        # See: https://bigladdersoftware.com/epx/docs/24-2/auxiliary-programs/hvac-performance-curve-fit-tool.html#hvac-performance-curve-fit-tool
        # Catalog data from ClimateMaster residential tranquility 30 premier two-stage series Model SE036: https://files.climatemaster.com/RP3001-Residential-SE-Product-Catalog.pdf
        # Using E+ rated conditions:
        # Heating: Indoor air at 70F DB; Entering water temperature: 70F
        hp_ap.heat_cap_ft_spec = [[0.6523957849, -0.0011387222, 0.0000000000, 0.0191295958, -0.0000411533, -0.0000311030],
                                  [0.6668920089, -0.0015817909, 0.0000027692, 0.0189198107, -0.0000372655, -0.0000393615]]
        hp_ap.heat_eir_ft_spec = [[0.8057698794, 0.0316014252, 0.0000380531, -0.0228123504, 0.0004336379, -0.0004522084],
                                  [0.8046419585, 0.0233384227, 0.0000376912, -0.0170224134, 0.0003382804, -0.0002368130]]
        hp_ap.heat_cap_fflow_spec = [[0.8649, 0.1112, 0.0238],
                                     [0.8264, 0.1593, 0.0143]]
        hp_ap.heat_eir_fflow_spec = [[1.2006, -0.1943, -0.0062],
                                     [1.2568, -0.2856, 0.0288]]
        hp_ap.heat_cap_fwf_spec = [[0.7112, 0.5027, -0.2139],
                                   [0.769, 0.399, -0.168]]
        hp_ap.heat_eir_fwf_spec = [[1.3457, -0.6658, 0.3201],
                                   [1.1679, -0.3215, 0.1535]]
        # TODO: Use default gross SHR after RESNET PR: https://github.com/NREL/OpenStudio-HPXML/pull/1879
        hp_ap.cool_rated_shrs_gross = [heat_pump.cooling_shr] * 2
        # Catalog data from ClimateMaster residential tranquility 30 premier two-stage series Model SE036: https://files.climatemaster.com/RP3001-Residential-SE-Product-Catalog.pdf
        cool_cop_ratios = [1.102827763, 1.0]
        heat_cop_ratios = [1.161791639, 1.0]
      when HPXML::HVACCompressorTypeVariableSpeed
        # Cooling Curves
        # E+ Capacity and EIR as function of temperature curves(bi-quadratic) generated using E+ HVACCurveFitTool
        # See: https://bigladdersoftware.com/epx/docs/24-2/auxiliary-programs/hvac-performance-curve-fit-tool.html#hvac-performance-curve-fit-tool
        # Catalog data from WaterFurnace 7 Series 700A11: https://www.waterfurnace.com/literature/7series/SDW7-0018W.pdf
        # Using E+ rated conditions:
        # Cooling: Indoor air at 67F WB, 80F DB; Entering water temperature: 85F
        hp_ap.cool_cap_ft_spec = [[1.3397293008, -0.0474800765, 0.0021636831, 0.0055773535, -0.0002350114, -0.0002458509],
                                  [1.2143128834, -0.0459226877, 0.0020331628, 0.0086998093, -0.0002669140, -0.0001763187]]
        hp_ap.cool_eir_ft_spec = [[-0.0049682877, 0.0554193005, -0.0015790347, -0.0010670650, 0.0011493038, -0.0008236210],
                                  [0.0569949694, 0.0527820535, -0.0015763180, 0.0077339260, 0.0008175629, -0.0007157989]]
        hp_ap.cool_cap_fflow_spec = [[1.1092, -0.5299, 0.4312],
                                     [0.9216, -0.1021, 0.1874]]
        hp_ap.cool_eir_fflow_spec = [[2.2938, -2.2648, 0.9631],
                                     [1.9175, -1.374, 0.4646]]
        hp_ap.cool_cap_fwf_spec = [[1.0386, -0.2037, 0.1651],
                                   [0.8606, 0.2687, -0.1293]]
        hp_ap.cool_eir_fwf_spec = [[1.066, 0.052, -0.118],
                                   [1.2961, -0.4762, 0.18]]

        # Heating Curves
        # E+ Capacity and EIR as function of temperature curves(bi-quadratic) generated using E+ HVACCurveFitTool
        # See: https://bigladdersoftware.com/epx/docs/24-2/auxiliary-programs/hvac-performance-curve-fit-tool.html#hvac-performance-curve-fit-tool
        # Catalog data from WaterFurnace 7 Series 700A11: https://www.waterfurnace.com/literature/7series/SDW7-0018W.pdf
        # Using E+ rated conditions:
        # Heating: Indoor air at 70F DB; Entering water temperature: 70F
        hp_ap.heat_cap_ft_spec = [[0.6955336002, -0.0028528869, -0.0000005012, 0.0201138223, -0.0000590002, -0.0000749701],
                                  [0.6975737864, -0.0028810803, -0.0000005015, 0.0206468583, -0.0000891526, -0.0000733087]]
        hp_ap.heat_eir_ft_spec = [[0.8755777079, 0.0309984461, 0.0001099592, -0.0174543325, 0.0001819203, -0.0004948405],
                                  [0.7627294076, 0.0273612308, 0.0001023412, -0.0145638547, 0.0001886431, -0.0003647958]]
        hp_ap.heat_cap_fflow_spec = [[0.8676, 0.1122, 0.0195],
                                     [0.9498, -0.0298, 0.0812]]
        hp_ap.heat_eir_fflow_spec = [[1.4426, -0.4465, 0.0064],
                                     [1.1158, 0.282, -0.4071]]
        hp_ap.heat_cap_fwf_spec = [[0.8364, 0.197, -0.0333],
                                   [0.727, 0.55, -0.277]]
        hp_ap.heat_eir_fwf_spec = [[1.3491, -0.7744, 0.4253],
                                   [1.0833, -0.1351, 0.0517]]
        # TODO: Use default gross SHR after RESNET PR: https://github.com/NREL/OpenStudio-HPXML/pull/1879
        hp_ap.cool_rated_shrs_gross = [heat_pump.cooling_shr] * 2
        # Catalog data from WaterFurnace 7 Series 700A11: https://www.waterfurnace.com/literature/7series/SDW7-0018W.pdf
        cool_cop_ratios = [1.059467645, 1.0]
        heat_cop_ratios = [1.15012987, 1.0]
      end
    end

    # Fan/pump adjustments calculations
    # Fan power to overcome the static pressure adjustment
    rated_fan_watts_per_cfm = 0.5 * heat_pump.fan_watts_per_cfm # Calculate rated fan power by assuming the power to overcome the ductwork is approximately 50% of the total fan power (ANSI/RESNET/ICC 301 says 0.2 W/cfm is the fan power associated with ductwork, but we don't know if that was a PSC or BPM fan)
    rated_pump_watts_per_ton = 30.0 # ANSI/RESNET/ICC 301, estimated pump power required to overcome the internal resistance of the ground-water heat exchanger under AHRI test conditions for a closed loop system
    power_f = rated_fan_watts_per_cfm * hp_ap.cool_rated_cfm_per_ton[-1] / UnitConversions.convert(1.0, 'ton', 'Btu/hr') # result is in W per Btu/hr of capacity
    power_p = rated_pump_watts_per_ton / UnitConversions.convert(1.0, 'ton', 'Btu/hr') # result is in W per Btu/hr of capacity
    cool_eir_rated = UnitConversions.convert(((1 - UnitConversions.convert(power_f, 'Wh', 'Btu')) / heat_pump.cooling_efficiency_eer - power_f - power_p), 'Wh', 'Btu')
    heat_eir_rated = (1 + UnitConversions.convert(power_f, 'Wh', 'Btu')) / heat_pump.heating_efficiency_cop - UnitConversions.convert(power_f + power_p, 'Wh', 'Btu')
    hp_ap.cool_rated_cops = []
    hp_ap.heat_rated_cops = []
    for i in 0..(cool_cop_ratios.size - 1)
      hp_ap.cool_rated_cops << 1.0 / cool_eir_rated * cool_cop_ratios[i]
      hp_ap.heat_rated_cops << 1.0 / heat_eir_rated * heat_cop_ratios[i]
    end
  end

  # TODO
  #
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param latitude [TODO] TODO
  # @return [TODO] TODO
  def self.get_building_america_hvac_seasons(weather, latitude)
    # Calculates heating/cooling seasons from BAHSP definition

    monthly_temps = weather.data.MonthlyAvgDrybulbs
    heat_design_db = weather.design.HeatingDrybulb
    is_southern_hemisphere = (latitude < 0)

    # create basis lists with zero for every month
    cooling_season_temp_basis = Array.new(monthly_temps.length, 0.0)
    heating_season_temp_basis = Array.new(monthly_temps.length, 0.0)

    if is_southern_hemisphere
      override_heating_months = [6, 7] # July, August
      override_cooling_months = [0, 11] # December, January
    else
      override_heating_months = [0, 11] # December, January
      override_cooling_months = [6, 7] # July, August
    end

    monthly_temps.each_with_index do |temp, i|
      if temp < 66.0
        heating_season_temp_basis[i] = 1.0
      elsif temp >= 66.0
        cooling_season_temp_basis[i] = 1.0
      end

      if (override_heating_months.include? i) && (heat_design_db < 59.0)
        heating_season_temp_basis[i] = 1.0
      elsif override_cooling_months.include? i
        cooling_season_temp_basis[i] = 1.0
      end
    end

    cooling_season = Array.new(monthly_temps.length, 0.0)
    heating_season = Array.new(monthly_temps.length, 0.0)

    for i in 0..11
      # Heating overlaps with cooling at beginning of summer
      prevmonth = i - 1

      if ((heating_season_temp_basis[i] == 1.0) || ((cooling_season_temp_basis[prevmonth] == 0.0) && (cooling_season_temp_basis[i] == 1.0)))
        heating_season[i] = 1.0
      else
        heating_season[i] = 0.0
      end

      if ((cooling_season_temp_basis[i] == 1.0) || ((heating_season_temp_basis[prevmonth] == 0.0) && (heating_season_temp_basis[i] == 1.0)))
        cooling_season[i] = 1.0
      else
        cooling_season[i] = 0.0
      end
    end

    # Find the first month of cooling and add one month
    for i in 0..11
      if cooling_season[i] == 1.0
        cooling_season[i - 1] = 1.0
        break
      end
    end

    return heating_season, cooling_season
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param fan [TODO] TODO
  # @param hp_min_temp [TODO] TODO
  # @return [nil]
  def self.add_fan_power_ems_program(model, fan, hp_min_temp)
    # EMS is used to disable the fan power below the hp_min_temp; the backup heating
    # system will be operating instead.

    # Sensors
    tout_db_sensor = Model.add_ems_sensor(
      model,
      name: 'tout_db',
      output_var_or_meter_name: 'Site Outdoor Air Drybulb Temperature',
      key_name: 'Environment'
    )

    # Actuators
    fan_pressure_rise_act = Model.add_ems_actuator(
      name: "#{fan.name} pressure rise act",
      model_object: fan,
      comp_type_and_control: EPlus::EMSActuatorFanPressureRise
    )

    fan_total_efficiency_act = Model.add_ems_actuator(
      name: "#{fan.name} total efficiency act",
      model_object: fan,
      comp_type_and_control: EPlus::EMSActuatorFanTotalEfficiency
    )

    # Program
    fan_program = Model.add_ems_program(
      model,
      name: "#{fan.name} power program"
    )
    fan_program.addLine("If #{tout_db_sensor.name} < #{UnitConversions.convert(hp_min_temp, 'F', 'C').round(2)}")
    fan_program.addLine("  Set #{fan_pressure_rise_act.name} = 0")
    fan_program.addLine("  Set #{fan_total_efficiency_act.name} = 1")
    fan_program.addLine('Else')
    fan_program.addLine("  Set #{fan_pressure_rise_act.name} = NULL")
    fan_program.addLine("  Set #{fan_total_efficiency_act.name} = NULL")
    fan_program.addLine('EndIf')

    # Calling Point
    Model.add_ems_program_calling_manager(
      model,
      name: "#{fan_program.name} calling manager",
      calling_point: 'AfterPredictorBeforeHVACManagers',
      ems_programs: [fan_program]
    )
  end

  # Create EMS program to correctly account for pump power consumption based on heating object part load ratio
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param pump [OpenStudio::Model::PumpVariableSpeed] OpenStudio variable-speed pump object
  # @param heating_object [OpenStudio::Model::AirLoopHVACUnitarySystem or OpenStudio::Model::BoilerHotWater] OpenStudio unitary system object or boiler object
  # @param hvac_system [HPXML::HeatPump or HPXML::HeatingSystem] HPXML heat pump or heating system object
  # @return [nil]
  def self.add_pump_power_ems_program(model, pump, heating_object, hvac_system)
    # EMS is used to set the pump power.
    # Without EMS, the pump power will vary according to the plant loop part load ratio
    # (based on flow rate) rather than the boiler part load ratio (based on load).

    # Sensors
    if heating_object.is_a? OpenStudio::Model::BoilerHotWater
      heating_plr_sensor = Model.add_ems_sensor(
        model,
        name: "#{heating_object.name} plr s",
        output_var_or_meter_name: 'Boiler Part Load Ratio',
        key_name: heating_object.name
      )
    elsif heating_object.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem
      htg_coil = heating_object.heatingCoil.get
      clg_coil = heating_object.coolingCoil.get
      # GHP model, variable speed coils
      if htg_coil.to_CoilHeatingWaterToAirHeatPumpVariableSpeedEquationFit.is_initialized
        htg_coil = htg_coil.to_CoilHeatingWaterToAirHeatPumpVariableSpeedEquationFit.get
        clg_coil = clg_coil.to_CoilCoolingWaterToAirHeatPumpVariableSpeedEquationFit.get
        heating_plr_sensor = Model.add_ems_sensor(
          model,
          name: "#{htg_coil.name} plr s",
          output_var_or_meter_name: 'Heating Coil Part Load Ratio',
          key_name: htg_coil.name
        )
        heating_nsl_sensor = Model.add_ems_sensor(
          model,
          name: "#{htg_coil.name} nsl s",
          output_var_or_meter_name: 'Heating Coil Neighboring Speed Levels Ratio',
          key_name: htg_coil.name
        )
        heating_usl_sensor = Model.add_ems_sensor(
          model,
          name: "#{htg_coil.name} usl s",
          output_var_or_meter_name: 'Heating Coil Upper Speed Level',
          key_name: htg_coil.name
        )
        cooling_plr_sensor = Model.add_ems_sensor(
          model,
          name: "#{clg_coil.name} plr s",
          output_var_or_meter_name: 'Cooling Coil Part Load Ratio',
          key_name: clg_coil.name
        )
        cooling_nsl_sensor = Model.add_ems_sensor(
          model,
          name: "#{clg_coil.name} nsl s",
          output_var_or_meter_name: 'Cooling Coil Neighboring Speed Levels Ratio',
          key_name: clg_coil.name
        )
        cooling_usl_sensor = Model.add_ems_sensor(
          model,
          name: "#{clg_coil.name} usl s",
          output_var_or_meter_name: 'Cooling Coil Upper Speed Level',
          key_name: clg_coil.name
        )
      # GHP model, single speed coils
      else
        heating_plr_sensor = Model.add_ems_sensor(
          model,
          name: "#{heating_object.name} plr s",
          output_var_or_meter_name: 'Unitary System Part Load Ratio',
          key_name: heating_object.name
        )
      end
    end

    pump_mfr_sensor = Model.add_ems_sensor(
      model,
      name: "#{pump.name} mfr s",
      output_var_or_meter_name: 'Pump Mass Flow Rate',
      key_name: pump.name
    )

    # Internal variable
    pump_rated_mfr_var = Model.add_ems_internal_var(
      model,
      name: "#{pump.name} rated mfr",
      model_object: pump,
      type: EPlus::EMSIntVarPumpMFR
    )

    # Actuator
    pump_pressure_rise_act = Model.add_ems_actuator(
      name: "#{pump.name} pressure rise act",
      model_object: pump,
      comp_type_and_control: EPlus::EMSActuatorPumpPressureRise
    )

    # Program
    # See https://bigladdersoftware.com/epx/docs/9-3/ems-application-guide/hvac-systems-001.html#pump
    pump_program = Model.add_ems_program(
      model,
      name: "#{pump.name} power program"
    )
    if cooling_plr_sensor.nil?
      pump_program.addLine("Set hvac_plr = #{heating_plr_sensor.name}")
    else
      hvac_ap = hvac_system.additional_properties
      pump_program.addLine("Set heating_pump_vfr_max = #{htg_coil.speeds[-1].referenceUnitRatedWaterFlowRate}")
      pump_program.addLine("Set cooling_pump_vfr_max = #{clg_coil.speeds[-1].referenceUnitRatedWaterFlowRate}")
      pump_program.addLine('Set htg_flow_rate = 0.0')
      pump_program.addLine('Set clg_flow_rate = 0.0')
      (1..htg_coil.speeds.size).each do |i|
        # Initialization
        pump_program.addLine("Set heating_pump_vfr_#{i} = heating_pump_vfr_max * #{hvac_ap.heat_capacity_ratios[i - 1]}")
        pump_program.addLine("Set heating_fraction_time_#{i} = 0.0")
      end
      pump_program.addLine("If #{heating_usl_sensor.name} == 1")
      pump_program.addLine("  Set heating_fraction_time_1 = #{heating_plr_sensor.name}")
      (1..(htg_coil.speeds.size - 1)).each do |i|
        pump_program.addLine("ElseIf #{heating_usl_sensor.name} == #{i + 1}")
        pump_program.addLine("  Set heating_fraction_time_#{i} = 1.0 - #{heating_nsl_sensor.name}")
        pump_program.addLine("  Set heating_fraction_time_#{i + 1} = #{heating_nsl_sensor.name}")
      end
      pump_program.addLine('EndIf')
      # sum up to get the actual flow rate
      (1..htg_coil.speeds.size).each do |i|
        pump_program.addLine("Set htg_flow_rate = htg_flow_rate + heating_fraction_time_#{i} * heating_pump_vfr_#{i}")
      end
      pump_program.addLine('Set heating_plr = htg_flow_rate / heating_pump_vfr_max')

      # Cooling
      (1..clg_coil.speeds.size).each do |i|
        # Initialization
        pump_program.addLine("Set cooling_pump_vfr_#{i} = cooling_pump_vfr_max * #{hvac_ap.cool_capacity_ratios[i - 1]}")
        pump_program.addLine("Set cooling_fraction_time_#{i} = 0.0")
      end
      pump_program.addLine("If #{cooling_usl_sensor.name} == 1")
      pump_program.addLine("  Set cooling_fraction_time_1 = #{cooling_plr_sensor.name}")
      (1..(clg_coil.speeds.size - 1)).each do |i|
        pump_program.addLine("ElseIf (#{cooling_usl_sensor.name}) == #{i + 1}")
        pump_program.addLine("  Set cooling_fraction_time_#{i} = 1.0 - #{cooling_nsl_sensor.name}")
        pump_program.addLine("  Set cooling_fraction_time_#{i + 1} = #{cooling_nsl_sensor.name}")
      end
      pump_program.addLine('EndIf')
      # sum up to get the actual flow rate
      (1..clg_coil.speeds.size).each do |i|
        pump_program.addLine("Set clg_flow_rate = clg_flow_rate + cooling_fraction_time_#{i} * heating_pump_vfr_#{i}")
      end
      pump_program.addLine('Set cooling_plr = clg_flow_rate / cooling_pump_vfr_max')
      pump_program.addLine('Set hvac_plr = @Max cooling_plr heating_plr')
    end
    pump_program.addLine("Set pump_total_eff = #{pump_rated_mfr_var.name} / 1000 * #{pump.ratedPumpHead} / #{pump.ratedPowerConsumption.get}")
    pump_program.addLine("Set pump_vfr = #{pump_mfr_sensor.name} / 1000")
    pump_program.addLine('If pump_vfr > 0')
    pump_program.addLine("  Set #{pump_pressure_rise_act.name} = #{pump.ratedPowerConsumption.get} * hvac_plr * pump_total_eff / pump_vfr")
    pump_program.addLine('Else')
    pump_program.addLine("  Set #{pump_pressure_rise_act.name} = 0")
    pump_program.addLine('EndIf')

    # Calling Point
    Model.add_ems_program_calling_manager(
      model,
      name: "#{pump_program.name} calling manager",
      calling_point: 'EndOfSystemTimestepBeforeHVACReporting',
      ems_programs: [pump_program]
    )
  end

  # Add EMS program to actuate pump mass flow rate, to work around an E+ bug: https://github.com/NREL/EnergyPlus/issues/10936
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param pump [OpenStudio::Model::PumpVariableSpeed] OpenStudio variable speed pump object
  # @param control_zone [OpenStudio::Model::ThermalZone] Conditioned space thermal zone
  # @param htg_coil [OpenStudio::Model::CoilHeatingWaterToAirHeatPumpEquationFit or OpenStudio::Model::CoilHeatingWaterToAirHeatPumpVariableSpeedEquationFit]  OpenStudio Heating Coil object
  # @param clg_coil [OpenStudio::Model::CoilCoolingWaterToAirHeatPumpEquationFit or OpenStudio::Model::CoilCoolingWaterToAirHeatPumpVariableSpeedEquationFit]  OpenStudio Cooling Coil object
  # @return [nil]
  def self.add_ghp_pump_mass_flow_rate_ems_program(model, pump, control_zone, htg_coil, clg_coil)
    # Sensors
    htg_load_sensor = Model.add_ems_sensor(
      model,
      name: "#{control_zone.name} predicted heating loads",
      output_var_or_meter_name: 'Zone Predicted Sensible Load to Heating Setpoint Heat Transfer Rate',
      key_name: control_zone.name
    )

    clg_load_sensor = Model.add_ems_sensor(
      model,
      name: "#{control_zone.name} predicted cooling loads",
      output_var_or_meter_name: 'Zone Predicted Sensible Load to Cooling Setpoint Heat Transfer Rate',
      key_name: control_zone.name
    )

    # Actuator
    pump_mfr_act = Model.add_ems_actuator(
      name: "#{pump.name} mfr act",
      model_object: pump,
      comp_type_and_control: EPlus::EMSActuatorPumpMassFlowRate
    )

    # Program
    # See https://bigladdersoftware.com/epx/docs/9-3/ems-application-guide/hvac-systems-001.html#pump
    pump_program = Model.add_ems_program(
      model,
      name: "#{pump.name} mfr program"
    )
    pump_program.addLine("If #{htg_load_sensor.name} > 0.0 && #{clg_load_sensor.name} > 0.0") # Heating loads
    pump_program.addLine("  Set estimated_plr = (@ABS #{htg_load_sensor.name}) / #{htg_coil.ratedHeatingCapacityAtSelectedNominalSpeedLevel}") # Use nominal capacity for estimation
    pump_program.addLine("  Set max_vfr_htg = #{htg_coil.ratedWaterFlowRateAtSelectedNominalSpeedLevel}")
    pump_program.addLine('  Set estimated_vfr = estimated_plr * max_vfr_htg')
    pump_program.addLine("  If estimated_vfr < #{htg_coil.speeds[0].referenceUnitRatedWaterFlowRate}") # Actuate the water flow rate below first stage
    pump_program.addLine("    Set #{pump_mfr_act.name} = estimated_vfr * 1000.0")
    pump_program.addLine('  Else')
    pump_program.addLine("    Set #{pump_mfr_act.name} = NULL")
    pump_program.addLine('  EndIf')
    pump_program.addLine("ElseIf #{htg_load_sensor.name} < 0.0 && #{clg_load_sensor.name} < 0.0") # Cooling loads
    pump_program.addLine("  Set estimated_plr = (@ABS #{clg_load_sensor.name}) / #{clg_coil.grossRatedTotalCoolingCapacityAtSelectedNominalSpeedLevel}") # Use nominal capacity for estimation
    pump_program.addLine("  Set max_vfr_clg = #{clg_coil.ratedWaterFlowRateAtSelectedNominalSpeedLevel}")
    pump_program.addLine('  Set estimated_vfr = estimated_plr * max_vfr_clg')
    pump_program.addLine("  If estimated_vfr < #{clg_coil.speeds[0].referenceUnitRatedWaterFlowRate}") # Actuate the water flow rate below first stage
    pump_program.addLine("    Set #{pump_mfr_act.name} = estimated_vfr * 1000.0")
    pump_program.addLine('  Else')
    pump_program.addLine("    Set #{pump_mfr_act.name} = NULL")
    pump_program.addLine('  EndIf')
    pump_program.addLine('Else')
    pump_program.addLine("  Set #{pump_mfr_act.name} = NULL")
    pump_program.addLine('EndIf')

    # Calling Point
    Model.add_ems_program_calling_manager(
      model,
      name: "#{pump_program.name} calling manager",
      calling_point: 'AfterPredictorBeforeHVACManagers',
      ems_programs: [pump_program]
    )
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param fan_or_pump [TODO] TODO
  # @param htg_object [TODO] TODO
  # @param clg_object [TODO] TODO
  # @param backup_htg_object [TODO] TODO
  # @param hpxml_object [TODO] TODO
  # @return [nil]
  def self.add_fan_pump_disaggregation_ems_program(model, fan_or_pump, htg_object, clg_object, backup_htg_object, hpxml_object)
    # Disaggregate into heating/cooling output energy use.

    sys_id = hpxml_object.id

    if fan_or_pump.is_a? OpenStudio::Model::FanSystemModel
      var = "Fan #{EPlus::FuelTypeElectricity} Energy"
    elsif fan_or_pump.is_a? OpenStudio::Model::PumpVariableSpeed
      var = "Pump #{EPlus::FuelTypeElectricity} Energy"
    elsif fan_or_pump.is_a? OpenStudio::Model::ElectricEquipment
      var = "Electric Equipment #{EPlus::FuelTypeElectricity} Energy"
    else
      fail "Unexpected fan/pump object '#{fan_or_pump.name}'."
    end
    fan_or_pump_sensor = Model.add_ems_sensor(
      model,
      name: "#{fan_or_pump.name} s",
      output_var_or_meter_name: var,
      key_name: fan_or_pump.name
    )

    fan_or_pump_var = Model.ems_friendly_name(fan_or_pump.name)

    if clg_object.nil?
      clg_object_sensor = nil
    else
      if clg_object.is_a? OpenStudio::Model::EvaporativeCoolerDirectResearchSpecial
        var = 'Evaporative Cooler Water Volume'
      else
        var = 'Cooling Coil Total Cooling Energy'
      end

      clg_object_sensor = Model.add_ems_sensor(
        model,
        name: "#{clg_object.name} s",
        output_var_or_meter_name: var,
        key_name: clg_object.name
      )
    end

    if htg_object.nil?
      htg_object_sensor = nil
    else
      if htg_object.is_a? OpenStudio::Model::ZoneHVACBaseboardConvectiveWater
        var = 'Baseboard Total Heating Energy'
      elsif htg_object.is_a? OpenStudio::Model::ZoneHVACFourPipeFanCoil
        var = 'Fan Coil Heating Energy'
      else
        var = 'Heating Coil Heating Energy'
      end

      htg_object_sensor = Model.add_ems_sensor(
        model,
        name: "#{htg_object.name} s",
        output_var_or_meter_name: var,
        key_name: htg_object.name
      )
    end

    if backup_htg_object.nil?
      backup_htg_object_sensor = nil
    else
      if backup_htg_object.is_a? OpenStudio::Model::ZoneHVACBaseboardConvectiveWater
        var = 'Baseboard Total Heating Energy'
      else
        var = 'Heating Coil Heating Energy'
      end

      backup_htg_object_sensor = Model.add_ems_sensor(
        model,
        name: "#{backup_htg_object.name} s",
        output_var_or_meter_name: var,
        key_name: backup_htg_object.name
      )
    end

    sensors = { 'clg' => clg_object_sensor,
                'primary_htg' => htg_object_sensor,
                'backup_htg' => backup_htg_object_sensor }
    sensors = sensors.select { |_m, s| !s.nil? }

    # Disaggregate electric fan/pump energy
    fan_or_pump_program = Model.add_ems_program(
      model,
      name: "#{fan_or_pump_var} disaggregate program"
    )

    if htg_object.is_a?(OpenStudio::Model::ZoneHVACBaseboardConvectiveWater) || htg_object.is_a?(OpenStudio::Model::ZoneHVACFourPipeFanCoil)
      # Pump may occasionally run when baseboard isn't, so just assign all pump energy here
      mode, _sensor = sensors.first
      if (sensors.size != 1) || (mode != 'primary_htg')
        fail 'Unexpected situation.'
      end

      fan_or_pump_program.addLine("  Set #{fan_or_pump_var}_#{mode} = #{fan_or_pump_sensor.name}")
    else
      sensors.keys.each do |mode|
        fan_or_pump_program.addLine("Set #{fan_or_pump_var}_#{mode} = 0")
      end
      sensors.each_with_index do |(mode, sensor), i|
        if i == 0
          if_else_str = "If #{sensor.name} > 0"
        elsif i == sensors.size - 1
          # Use else for last mode to make sure we don't miss any energy use
          # See https://github.com/NREL/OpenStudio-HPXML/issues/1424
          if_else_str = 'Else'
        else
          if_else_str = "ElseIf #{sensor.name} > 0"
        end
        if mode == 'primary_htg' && sensors.keys[i + 1] == 'backup_htg'
          # HP with both primary and backup heating
          # If both are operating, apportion energy use
          fan_or_pump_program.addLine("#{if_else_str} && (#{sensors.values[i + 1].name} > 0)")
          fan_or_pump_program.addLine("  Set #{fan_or_pump_var}_#{mode} = #{fan_or_pump_sensor.name} * #{sensor.name} / (#{sensor.name} + #{sensors.values[i + 1].name})")
          fan_or_pump_program.addLine("  Set #{fan_or_pump_var}_#{sensors.keys[i + 1]} = #{fan_or_pump_sensor.name} * #{sensors.values[i + 1].name} / (#{sensor.name} + #{sensors.values[i + 1].name})")
          if_else_str = if_else_str.gsub('If', 'ElseIf') if if_else_str.start_with?('If')
        end
        fan_or_pump_program.addLine(if_else_str)
        fan_or_pump_program.addLine("  Set #{fan_or_pump_var}_#{mode} = #{fan_or_pump_sensor.name}")
      end
      fan_or_pump_program.addLine('EndIf')
    end

    Model.add_ems_program_calling_manager(
      model,
      name: "#{fan_or_pump.name} disaggregate program calling manager",
      calling_point: 'EndOfSystemTimestepBeforeHVACReporting',
      ems_programs: [fan_or_pump_program]
    )

    sensors.each do |mode, sensor|
      next if sensor.nil?

      # TODO: Create Model.add_ems_output_var() method
      fan_or_pump_ems_output_var = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, "#{fan_or_pump_var}_#{mode}")
      object_type = { 'clg' => Constants::ObjectTypeFanPumpDisaggregateCool,
                      'primary_htg' => Constants::ObjectTypeFanPumpDisaggregatePrimaryHeat,
                      'backup_htg' => Constants::ObjectTypeFanPumpDisaggregateBackupHeat }[mode]
      fan_or_pump_ems_output_var.setName("#{fan_or_pump.name} #{object_type}")
      fan_or_pump_ems_output_var.setTypeOfDataInVariable('Summed')
      fan_or_pump_ems_output_var.setUpdateFrequency('SystemTimestep')
      fan_or_pump_ems_output_var.setEMSProgramOrSubroutineName(fan_or_pump_program)
      fan_or_pump_ems_output_var.setUnits('J')
      fan_or_pump_ems_output_var.additionalProperties.setFeature('HPXML_ID', sys_id) # Used by reporting measure
      fan_or_pump_ems_output_var.additionalProperties.setFeature('ObjectType', object_type) # Used by reporting measure
    end
  end

  # Adjusts the HVAC load to the space when a dehumidifier serves less than 100% dehumidification load, since
  # the EnergyPlus dehumidifier object can only model 100% dehumidification.
  #
  # @param fraction_served [TODO] TODO
  # @param zone_hvac [TODO] TODO
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param conditioned_space [TODO] TODO
  # @return [nil]
  def self.add_dehumidifier_load_adjustment_ems_program(fraction_served, zone_hvac, model, conditioned_space)
    # sensor
    dehumidifier_sens_htg = Model.add_ems_sensor(
      model,
      name: "#{zone_hvac.name} sens htg",
      output_var_or_meter_name: 'Zone Dehumidifier Sensible Heating Rate',
      key_name: zone_hvac.name
    )

    dehumidifier_power = Model.add_ems_sensor(
      model,
      name: "#{zone_hvac.name} power htg",
      output_var_or_meter_name: "Zone Dehumidifier #{EPlus::FuelTypeElectricity} Rate",
      key_name: zone_hvac.name
    )

    # actuator
    dehumidifier_load_adj = Model.add_other_equipment(
      model,
      name: "#{zone_hvac.name} sens htg adj",
      end_use: nil,
      space: conditioned_space,
      design_level: 0,
      frac_radiant: 0,
      frac_latent: 0,
      frac_lost: 0,
      schedule: model.alwaysOnDiscreteSchedule,
      fuel_type: nil
    )
    dehumidifier_load_adj_act = Model.add_ems_actuator(
      name: "#{zone_hvac.name} sens htg adj act",
      model_object: dehumidifier_load_adj,
      comp_type_and_control: EPlus::EMSActuatorOtherEquipmentPower
    )

    # EMS program
    program = Model.add_ems_program(
      model,
      name: "#{zone_hvac.name} load adj program"
    )
    program.addLine("If #{dehumidifier_sens_htg.name} > 0")
    program.addLine("  Set #{dehumidifier_load_adj_act.name} = - (#{dehumidifier_sens_htg.name} - #{dehumidifier_power.name}) * (1 - #{fraction_served})")
    program.addLine('Else')
    program.addLine("  Set #{dehumidifier_load_adj_act.name} = 0")
    program.addLine('EndIf')

    Model.add_ems_program_calling_manager(
      model,
      name: "#{program.name} calling manager",
      calling_point: 'BeginZoneTimestepAfterInitHeatBalance',
      ems_programs: [program]
    )
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param obj_name [String] Name for the OpenStudio object
  # @param heat_pump [TODO] TODO
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [TODO] TODO
  def self.create_supp_heating_coil(model, obj_name, heat_pump, hpxml_header = nil, runner = nil, hpxml_bldg = nil)
    fuel = heat_pump.backup_heating_fuel
    capacity = heat_pump.backup_heating_capacity
    efficiency = heat_pump.backup_heating_efficiency_percent
    efficiency = heat_pump.backup_heating_efficiency_afue if efficiency.nil?

    if fuel.nil?
      return
    end

    backup_heating_capacity_increment = hpxml_header.heat_pump_backup_heating_capacity_increment unless hpxml_header.nil?
    backup_heating_capacity_increment = nil unless fuel == HPXML::FuelTypeElectricity
    if not backup_heating_capacity_increment.nil?
      if hpxml_bldg.building_construction.number_of_units > 1
        # Throw error and stop simulation
        runner.registerError('NumberofUnits greater than 1 is not supported for multi-staging backup coil.')
      end
      max_num_stages = 4

      num_stages = [(capacity / backup_heating_capacity_increment).ceil(), max_num_stages].min
      # OpenStudio only supports 4 stages for now
      runner.registerWarning("EnergyPlus only supports #{max_num_stages} stages for multi-stage electric backup coil. Combined the remaining capacities in the last stage.") if (capacity / backup_heating_capacity_increment).ceil() > 4

      htg_supp_coil = OpenStudio::Model::CoilHeatingElectricMultiStage.new(model)
      htg_supp_coil.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
      htg_supp_coil.setName(obj_name + ' backup htg coil')
      stage_capacity = 0.0

      (1..num_stages).each do |stage_i|
        stage = OpenStudio::Model::CoilHeatingElectricMultiStageStageData.new(model)
        if stage_i == max_num_stages
          increment = (capacity - stage_capacity) # Model remaining capacity anyways
        else
          increment = backup_heating_capacity_increment
        end
        next if increment <= 5 # Tolerance to avoid modeling small capacity stage

        # There're two cases to throw this warning: 1. More stages are needed so that the remaining capacities are combined in last stage. 2. Total capacity is not able to be perfectly divided by increment.
        # For the first case, the above warning of num_stages has already thrown
        runner.registerWarning("Calculated multi-stage backup coil capacity increment for last stage is not equal to user input, actual capacity increment is #{increment} Btu/hr.") if (increment - backup_heating_capacity_increment).abs > 1
        stage_capacity += increment

        stage.setNominalCapacity(UnitConversions.convert(stage_capacity, 'Btu/hr', 'W'))
        stage.setEfficiency(efficiency)
        htg_supp_coil.addStage(stage)
      end
    else
      htg_supp_coil = Model.add_coil_heating(
        model,
        name: "#{obj_name} backup htg coil",
        efficiency: efficiency,
        capacity: UnitConversions.convert(capacity, 'Btu/hr', 'W'),
        fuel_type: fuel
      )
    end
    htg_supp_coil.additionalProperties.setFeature('HPXML_ID', heat_pump.id) # Used by reporting measure
    htg_supp_coil.additionalProperties.setFeature('IsHeatPumpBackup', true) # Used by reporting measure

    return htg_supp_coil
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param obj_name [String] Name for the OpenStudio object
  # @param fan_watts_per_cfm [TODO] TODO
  # @param fan_cfms [TODO] TODO
  # @return [TODO] TODO
  def self.create_supply_fan(model, obj_name, fan_watts_per_cfm, fan_cfms)
    # Note: fan_cfms should include all unique airflow rates (both heating and cooling, at all speeds)
    max_fan_cfm = Float(fan_cfms.max) # Convert to float to prevent integer division below
    fan = Model.add_fan_system_model(
      model,
      name: "#{obj_name} supply fan",
      end_use: 'supply fan',
      power_per_flow: fan_watts_per_cfm / UnitConversions.convert(1.0, 'cfm', 'm^3/s'),
      max_flow_rate: UnitConversions.convert(max_fan_cfm, 'cfm', 'm^3/s')
    )

    fan_cfms.sort.each do |fan_cfm|
      fan_ratio = fan_cfm / max_fan_cfm
      power_fraction = calculate_fan_power_from_curve(1.0, fan_ratio)
      fan.addSpeed(fan_ratio.round(5), power_fraction.round(5))
    end

    return fan
  end

  # TODO
  #
  # @param max_fan_power [TODO] TODO
  # @param fan_ratio [TODO] TODO
  # @return [TODO] TODO
  def self.calculate_fan_power_from_curve(max_fan_power, fan_ratio)
    # Cubic relationship fan power curve
    return max_fan_power * (fan_ratio**3)
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param obj_name [String] Name for the OpenStudio object
  # @param fan [TODO] TODO
  # @param htg_coil [TODO] TODO
  # @param clg_coil [TODO] TODO
  # @param htg_supp_coil [TODO] TODO
  # @param htg_cfm [TODO] TODO
  # @param clg_cfm [TODO] TODO
  # @param supp_max_temp [TODO] TODO
  # @return [OpenStudio::Model::AirLoopHVACUnitarySystem] OpenStudio Air Loop HVAC Unitary System object
  def self.create_air_loop_unitary_system(model, obj_name, fan, htg_coil, clg_coil, htg_supp_coil, htg_cfm, clg_cfm, supp_max_temp = nil)
    cycle_fan_sch = Model.add_schedule_constant(
      model,
      name: "#{obj_name} auto fan schedule",
      value: 0, # 0 denotes that fan cycles on and off to meet the load (i.e., AUTO fan) as opposed to continuous operation
      limits: EPlus::ScheduleTypeLimitsOnOff
    )

    air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
    air_loop_unitary.setName(obj_name + ' unitary system')
    air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
    air_loop_unitary.setSupplyFan(fan)
    air_loop_unitary.setFanPlacement('BlowThrough')
    air_loop_unitary.setSupplyAirFanOperatingModeSchedule(cycle_fan_sch)
    if htg_coil.nil?
      air_loop_unitary.setSupplyAirFlowRateDuringHeatingOperation(0.0)
    else
      air_loop_unitary.setHeatingCoil(htg_coil)
      air_loop_unitary.setSupplyAirFlowRateDuringHeatingOperation(UnitConversions.convert(htg_cfm, 'cfm', 'm^3/s'))
    end
    if clg_coil.nil?
      air_loop_unitary.setSupplyAirFlowRateDuringCoolingOperation(0.0)
    else
      air_loop_unitary.setCoolingCoil(clg_coil)
      air_loop_unitary.setSupplyAirFlowRateDuringCoolingOperation(UnitConversions.convert(clg_cfm, 'cfm', 'm^3/s'))
    end
    if htg_supp_coil.nil?
      air_loop_unitary.setMaximumSupplyAirTemperature(UnitConversions.convert(120.0, 'F', 'C'))
    else
      air_loop_unitary.setSupplementalHeatingCoil(htg_supp_coil)
      air_loop_unitary.setMaximumSupplyAirTemperature(UnitConversions.convert(200.0, 'F', 'C')) # higher temp for supplemental heat as to not severely limit its use, resulting in unmet hours.
      if not supp_max_temp.nil?
        air_loop_unitary.setMaximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation(UnitConversions.convert(supp_max_temp, 'F', 'C'))
      end
    end
    air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)
    return air_loop_unitary
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param obj_name [String] Name for the OpenStudio object
  # @param system [TODO] TODO
  # @param control_zone [OpenStudio::Model::ThermalZone] Conditioned space thermal zone
  # @param hvac_sequential_load_fracs [Array<Double>] Array of daily fractions of remaining heating/cooling load to bet met by the HVAC system
  # @param airflow_cfm [TODO] TODO
  # @param heating_system [TODO] TODO
  # @param hvac_unavailable_periods [Hash] Map of htg/clg => HPXML::UnavailablePeriods for heating/cooling
  # @return [OpenStudio::Model::AirLoopHVAC] OpenStudio Air Loop HVAC object
  def self.create_air_loop(model, obj_name, system, control_zone, hvac_sequential_load_fracs, airflow_cfm, heating_system, hvac_unavailable_periods)
    air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
    air_loop.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
    air_loop.setName(obj_name + ' airloop')
    air_loop.zoneSplitter.setName(obj_name + ' zone splitter')
    air_loop.zoneMixer.setName(obj_name + ' zone mixer')
    air_loop.setDesignSupplyAirFlowRate(UnitConversions.convert(airflow_cfm, 'cfm', 'm^3/s'))
    system.addToNode(air_loop.supplyInletNode)

    if system.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem
      air_terminal = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
      system.setControllingZoneorThermostatLocation(control_zone)
    else
      air_terminal = OpenStudio::Model::AirTerminalSingleDuctVAVNoReheat.new(model, model.alwaysOnDiscreteSchedule)
      air_terminal.setConstantMinimumAirFlowFraction(0)
      air_terminal.setFixedMinimumAirFlowRate(0)
    end
    air_terminal.setMaximumAirFlowRate(UnitConversions.convert(airflow_cfm, 'cfm', 'm^3/s'))
    air_terminal.setName(obj_name + ' terminal')
    air_loop.multiAddBranchForZone(control_zone, air_terminal)

    set_sequential_load_fractions(model, control_zone, air_terminal, hvac_sequential_load_fracs, hvac_unavailable_periods, heating_system)

    return air_loop
  end

  # TODO
  #
  # @param dh_type [TODO] TODO
  # @param w_coeff [TODO] TODO
  # @param ef_coeff [TODO] TODO
  # @param ief [TODO] TODO
  # @param water_removal_rate [TODO] TODO
  # @return [TODO] TODO
  def self.apply_dehumidifier_ief_to_ef_inputs(dh_type, w_coeff, ef_coeff, ief, water_removal_rate)
    # Shift inputs under IEF test conditions to E+ supported EF test conditions
    # test conditions
    if dh_type == HPXML::DehumidifierTypePortable
      ief_db = UnitConversions.convert(65.0, 'F', 'C') # degree C
    elsif dh_type == HPXML::DehumidifierTypeWholeHome
      ief_db = UnitConversions.convert(73.0, 'F', 'C') # degree C
    end
    rh = 60.0 # for both EF and IEF test conditions, %

    # Independent variables applied to curve equations
    var_array_ief = [1, ief_db, ief_db * ief_db, rh, rh * rh, ief_db * rh]

    # Curved values under EF test conditions
    curve_value_ef = 1 # Curves are normalized to 1.0 under EF test conditions, 80F, 60%
    # Curve values under IEF test conditions
    ef_curve_value_ief = var_array_ief.zip(ef_coeff).map { |var, coeff| var * coeff }.sum(0.0)
    water_removal_curve_value_ief = var_array_ief.zip(w_coeff).map { |var, coeff| var * coeff }.sum(0.0)

    # E+ inputs under EF test conditions
    ef_input = ief / ef_curve_value_ief * curve_value_ef
    water_removal_rate_input = water_removal_rate / water_removal_curve_value_ief * curve_value_ef

    return ef_input, water_removal_rate_input
  end

  # TODO
  #
  # @param compressor_type [TODO] TODO
  # @param heating_capacity_retention_temp [TODO] TODO
  # @param heating_capacity_retention_fraction [TODO] TODO
  # @return [TODO] TODO
  def self.calc_heat_cap_ft_spec(compressor_type, heating_capacity_retention_temp, heating_capacity_retention_fraction)
    if compressor_type == HPXML::HVACCompressorTypeSingleStage
      iat_slope = -0.002303414
      iat_intercept = 0.18417308
      num_speeds = 1
    elsif compressor_type == HPXML::HVACCompressorTypeTwoStage
      iat_slope = -0.002947013
      iat_intercept = 0.23168251
      num_speeds = 2
    end

    # Biquadratic: capacity multiplier = a + b*IAT + c*IAT^2 + d*OAT + e*OAT^2 + f*IAT*OAT
    # Derive coefficients from user input for capacity retention at outdoor drybulb temperature X [C].
    x_A = heating_capacity_retention_temp
    y_A = heating_capacity_retention_fraction
    x_B = HVAC::AirSourceHeatRatedODB
    y_B = 1.0

    oat_slope = (y_B - y_A) / (x_B - x_A)
    oat_intercept = y_A - (x_A * oat_slope)

    return [[oat_intercept + iat_intercept, iat_slope, 0, oat_slope, 0, 0]] * num_speeds
  end

  # TODO
  #
  # @param heat_pump [TODO] TODO
  # @return [TODO] TODO
  def self.get_heating_capacity_retention(heat_pump)
    if not heat_pump.heating_capacity_17F.nil?
      heating_capacity_retention_temp = 17.0
      heating_capacity_retention_fraction = heat_pump.heating_capacity == 0.0 ? 0.0 : heat_pump.heating_capacity_17F / heat_pump.heating_capacity
    elsif not heat_pump.heating_capacity_retention_fraction.nil?
      heating_capacity_retention_temp = heat_pump.heating_capacity_retention_temp
      heating_capacity_retention_fraction = heat_pump.heating_capacity_retention_fraction
    else
      fail 'Missing heating capacity retention or 17F heating capacity.'
    end
    return heating_capacity_retention_temp, heating_capacity_retention_fraction
  end

  # TODO
  #
  # @param capacity_ratios [TODO] TODO
  # @param rated_cfm_per_tons [TODO] TODO
  # @param rated_airflow_rate [TODO] TODO
  # @return [TODO] TODO
  def self.calc_fan_speed_ratios(capacity_ratios, rated_cfm_per_tons, rated_airflow_rate)
    fan_speed_ratios = []
    capacity_ratios.each_with_index do |capacity_ratio, i|
      fan_speed_ratios << rated_cfm_per_tons[i] * capacity_ratio / rated_airflow_rate
    end
    return fan_speed_ratios
  end

  # TODO
  #
  # @param coeff [TODO] TODO
  # @return [TODO] TODO
  def self.convert_biquadratic_coeff_to_si(coeff)
    # Convert IP curves to SI curves
    si_coeff = []
    si_coeff << coeff[0] + 32.0 * (coeff[1] + coeff[3]) + 1024.0 * (coeff[2] + coeff[4] + coeff[5])
    si_coeff << 9.0 / 5.0 * coeff[1] + 576.0 / 5.0 * coeff[2] + 288.0 / 5.0 * coeff[5]
    si_coeff << 81.0 / 25.0 * coeff[2]
    si_coeff << 9.0 / 5.0 * coeff[3] + 576.0 / 5.0 * coeff[4] + 288.0 / 5.0 * coeff[5]
    si_coeff << 81.0 / 25.0 * coeff[4]
    si_coeff << 81.0 / 25.0 * coeff[5]
    return si_coeff
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [TODO] TODO
  # @param independent_vars [TODO] TODO
  # @param output_values [TODO] TODO
  # @param output_min [TODO] TODO
  # @param output_max [TODO] TODO
  # @return [TODO] TODO
  def self.create_table_lookup(model, name, independent_vars, output_values, output_min = nil, output_max = nil)
    if (not output_min.nil?) && (output_values.min < output_min)
      fail "Minimum table lookup output value (#{output_values.min}) is less than #{output_min} for #{name}."
    end
    if (not output_max.nil?) && (output_values.max > output_max)
      fail "Maximum table lookup output value (#{output_values.max}) is greater than #{output_max} for #{name}."
    end

    table = OpenStudio::Model::TableLookup.new(model)
    table.setName(name)
    independent_vars.each do |var|
      ind_var = OpenStudio::Model::TableIndependentVariable.new(model)
      ind_var.setName(var[:name])
      ind_var.setMinimumValue(var[:min])
      ind_var.setMaximumValue(var[:max])
      ind_var.setExtrapolationMethod('Constant')
      ind_var.setValues(var[:values])
      table.addIndependentVariable(ind_var)
    end
    table.setMinimumOutput(output_min) unless output_min.nil?
    table.setMaximumOutput(output_max) unless output_max.nil?
    table.setOutputValues(output_values)
    return table
  end

  # TODO
  #
  # @param net_cap [TODO] TODO
  # @param fan_power [TODO] TODO
  # @param mode [TODO] TODO
  # @param net_cop [TODO] TODO
  # @return [TODO] TODO
  def self.convert_net_to_gross_capacity_cop(net_cap, fan_power, mode, net_cop = nil)
    net_cap_watts = UnitConversions.convert(net_cap, 'Btu/hr', 'w')
    if mode == :clg
      gross_cap_watts = net_cap_watts + fan_power
    else
      gross_cap_watts = net_cap_watts - fan_power
    end
    if not net_cop.nil?
      net_power = net_cap_watts / net_cop
      gross_power = net_power - fan_power
      gross_cop = gross_cap_watts / gross_power
    end
    gross_cap_btu_hr = UnitConversions.convert(gross_cap_watts, 'w', 'Btu/hr')
    return gross_cap_btu_hr, gross_cop
  end

  # TODO
  #
  # @param detailed_performance_data [TODO] TODO
  # @param hvac_ap [TODO] TODO
  # @param mode [TODO] TODO
  # @param max_rated_fan_cfm [TODO] TODO
  # @param weather_temp [TODO] TODO
  # @param compressor_lockout_temp [TODO] TODO
  # @return [nil]
  def self.process_neep_detailed_performance(detailed_performance_data, hvac_ap, mode, max_rated_fan_cfm, weather_temp, compressor_lockout_temp = nil)
    data_array = Array.new(2) { Array.new }
    detailed_performance_data.sort_by { |dp| dp.outdoor_temperature }.each do |data_point|
      # Only process min and max capacities at each outdoor drybulb
      next unless [HPXML::CapacityDescriptionMinimum, HPXML::CapacityDescriptionMaximum].include? data_point.capacity_description

      if data_point.capacity_description == HPXML::CapacityDescriptionMinimum
        data_array[0] << data_point
      elsif data_point.capacity_description == HPXML::CapacityDescriptionMaximum
        data_array[1] << data_point
      end
    end

    # convert net to gross, adds more data points for table lookup, etc.
    if mode == :clg
      cfm_per_ton = hvac_ap.cool_rated_cfm_per_ton
      hvac_ap.cooling_performance_data_array = data_array
      hvac_ap.cool_rated_capacities_gross = []
      hvac_ap.cool_rated_capacities_net = []
      hvac_ap.cool_rated_cops = []
    elsif mode == :htg
      cfm_per_ton = hvac_ap.heat_rated_cfm_per_ton
      hvac_ap.heating_performance_data_array = data_array
      hvac_ap.heat_rated_capacities_gross = []
      hvac_ap.heat_rated_capacities_net = []
      hvac_ap.heat_rated_cops = []
    end
    # convert net to gross
    data_array.each_with_index do |data, speed|
      data.each do |dp|
        this_cfm = UnitConversions.convert(dp.capacity, 'Btu/hr', 'ton') * cfm_per_ton[speed]
        fan_ratio = this_cfm / max_rated_fan_cfm
        fan_power = calculate_fan_power_from_curve(hvac_ap.fan_power_rated * max_rated_fan_cfm, fan_ratio)
        dp.gross_capacity, dp.gross_efficiency_cop = convert_net_to_gross_capacity_cop(dp.capacity, fan_power, mode, dp.efficiency_cop)
      end
    end
    # convert to table lookup data
    interpolate_to_odb_table_points(data_array, mode, compressor_lockout_temp, weather_temp)
    add_data_point_adaptive_step_size(data_array, mode)
    correct_ft_cap_eir(data_array, mode)
  end

  # TODO
  #
  # @param data_array [TODO] TODO
  # @param mode [TODO] TODO
  # @param compressor_lockout_temp [TODO] TODO
  # @param weather_temp [TODO] TODO
  # @return [nil]
  def self.interpolate_to_odb_table_points(data_array, mode, compressor_lockout_temp, weather_temp)
    # Set of data used for table lookup
    data_array.each do |data|
      user_odbs = data.map { |dp| dp.outdoor_temperature }
      # Determine min/max ODB temperatures to cover full range of heat pump operation
      if mode == :clg
        outdoor_dry_bulbs = []
        # Calculate ODB temperature at which COP or capacity is zero
        high_odb_at_zero_cop = calculate_odb_at_zero_cop_or_capacity(data, mode, user_odbs, :gross_efficiency_cop, true)
        high_odb_at_zero_capacity = calculate_odb_at_zero_cop_or_capacity(data, mode, user_odbs, :gross_capacity, true)
        low_odb_at_zero_cop = calculate_odb_at_zero_cop_or_capacity(data, mode, user_odbs, :gross_efficiency_cop, false)
        low_odb_at_zero_capacity = calculate_odb_at_zero_cop_or_capacity(data, mode, user_odbs, :gross_capacity, false)
        outdoor_dry_bulbs << [low_odb_at_zero_cop, low_odb_at_zero_capacity, 55.0].max # Min cooling ODB
        outdoor_dry_bulbs << [high_odb_at_zero_cop, high_odb_at_zero_capacity, weather_temp].min # Max cooling ODB
      else
        outdoor_dry_bulbs = []
        # Calculate ODB temperature at which COP or capacity is zero
        low_odb_at_zero_cop = calculate_odb_at_zero_cop_or_capacity(data, mode, user_odbs, :gross_efficiency_cop, false)
        low_odb_at_zero_capacity = calculate_odb_at_zero_cop_or_capacity(data, mode, user_odbs, :gross_capacity, false)
        high_odb_at_zero_cop = calculate_odb_at_zero_cop_or_capacity(data, mode, user_odbs, :gross_efficiency_cop, true)
        high_odb_at_zero_capacity = calculate_odb_at_zero_cop_or_capacity(data, mode, user_odbs, :gross_capacity, true)
        outdoor_dry_bulbs << [low_odb_at_zero_cop, low_odb_at_zero_capacity, compressor_lockout_temp, weather_temp].max # Min heating ODB
        outdoor_dry_bulbs << [high_odb_at_zero_cop, high_odb_at_zero_capacity, 60.0].min # Max heating ODB
      end
      capacity_description = data[0].capacity_description
      outdoor_dry_bulbs.each do |target_odb|
        next if user_odbs.include? target_odb

        if mode == :clg
          new_dp = HPXML::CoolingPerformanceDataPoint.new(nil)
        else
          new_dp = HPXML::HeatingPerformanceDataPoint.new(nil)
        end
        new_dp.outdoor_temperature = target_odb
        new_dp.gross_capacity = interpolate_to_odb_table_point(data, capacity_description, target_odb, :gross_capacity)
        new_dp.gross_efficiency_cop = interpolate_to_odb_table_point(data, capacity_description, target_odb, :gross_efficiency_cop)
        data << new_dp
      end
    end
  end

  # TODO
  #
  # @param data [TODO] TODO
  # @param _mode [TODO] TODO
  # @param user_odbs [TODO] TODO
  # @param property [TODO] TODO
  # @param find_high [TODO] TODO
  # @return [TODO] TODO
  def self.calculate_odb_at_zero_cop_or_capacity(data, _mode, user_odbs, property, find_high)
    if find_high
      odb_dp1 = data.find { |dp| dp.outdoor_temperature == user_odbs[-1] }
      odb_dp2 = data.find { |dp| dp.outdoor_temperature == user_odbs[-2] }
    else
      odb_dp1 = data.find { |dp| dp.outdoor_temperature == user_odbs[0] }
      odb_dp2 = data.find { |dp| dp.outdoor_temperature == user_odbs[1] }
    end

    slope = (odb_dp1.send(property) - odb_dp2.send(property)) / (odb_dp1.outdoor_temperature - odb_dp2.outdoor_temperature)

    # Datapoints don't trend toward zero COP?
    if (find_high && slope >= 0)
      return 999999.0
    elsif (!find_high && slope <= 0)
      return -999999.0
    end

    intercept = odb_dp2.send(property) - (slope * odb_dp2.outdoor_temperature)
    target_odb = -intercept / slope

    # Return a slightly larger (or smaller, for cooling) ODB so things don't blow up
    delta_odb = 1.0
    if find_high
      return target_odb - delta_odb
    else
      return target_odb + delta_odb
    end
  end

  # TODO
  #
  # @param detailed_performance_data [TODO] TODO
  # @param capacity_description [TODO] TODO
  # @param target_odb [TODO] TODO
  # @param property [TODO] TODO
  # @return [TODO] TODO
  def self.interpolate_to_odb_table_point(detailed_performance_data, capacity_description, target_odb, property)
    data = detailed_performance_data.select { |dp| dp.capacity_description == capacity_description }

    target_dp = data.find { |dp| dp.outdoor_temperature == target_odb }
    if not target_dp.nil?
      return target_dp.send(property)
    end

    # Property can be :capacity, :efficiency_cop, etc.
    user_odbs = data.map { |dp| dp.outdoor_temperature }.uniq.sort

    right_odb = user_odbs.find { |e| e > target_odb }
    left_odb = user_odbs.reverse.find { |e| e < target_odb }
    if right_odb.nil?
      # extrapolation
      right_odb = user_odbs[-1]
      left_odb = user_odbs[-2]
    elsif left_odb.nil?
      # extrapolation
      right_odb = user_odbs[1]
      left_odb = user_odbs[0]
    end
    right_dp = data.find { |dp| dp.outdoor_temperature == right_odb }
    left_dp = data.find { |dp| dp.outdoor_temperature == left_odb }

    slope = (right_dp.send(property) - left_dp.send(property)) / (right_odb - left_odb)
    val = (target_odb - left_odb) * slope + left_dp.send(property)
    return val
  end

  # TODO
  #
  # @param data_array [TODO] TODO
  # @param mode [TODO] TODO
  # @param tol [TODO] TODO
  # @return [nil]
  def self.add_data_point_adaptive_step_size(data_array, mode, tol = 0.1)
    data_array.each do |data|
      data_sorted = data.sort_by { |dp| dp.outdoor_temperature }
      data_sorted.each_with_index do |dp, i|
        next unless i < (data_sorted.size - 1)

        cap_diff = data_sorted[i + 1].gross_capacity - dp.gross_capacity
        odb_diff = data_sorted[i + 1].outdoor_temperature - dp.outdoor_temperature
        cop_diff = data_sorted[i + 1].gross_efficiency_cop - dp.gross_efficiency_cop
        if mode == :clg
          eir_rated = 1 / data_sorted.find { |dp| dp.outdoor_temperature == HVAC::AirSourceCoolRatedODB }.gross_efficiency_cop
        else
          eir_rated = 1 / data_sorted.find { |dp| dp.outdoor_temperature == HVAC::AirSourceHeatRatedODB }.gross_efficiency_cop
        end
        eir_diff = ((1 / data_sorted[i + 1].gross_efficiency_cop) / eir_rated) - ((1 / dp.gross_efficiency_cop) / eir_rated)
        n_pt = (eir_diff.abs / tol).ceil() - 1
        eir_interval = eir_diff / (n_pt + 1)
        next if n_pt < 1

        for i in 1..n_pt
          if mode == :clg
            new_dp = HPXML::CoolingPerformanceDataPoint.new(nil)
          else
            new_dp = HPXML::HeatingPerformanceDataPoint.new(nil)
          end
          new_eir_normalized = (1 / dp.gross_efficiency_cop) / eir_rated + eir_interval * i
          new_dp.gross_efficiency_cop = (1 / (new_eir_normalized * eir_rated))
          new_dp.outdoor_temperature = odb_diff / cop_diff * (new_dp.gross_efficiency_cop - dp.gross_efficiency_cop) + dp.outdoor_temperature
          new_dp.gross_capacity = cap_diff / odb_diff * (new_dp.outdoor_temperature - dp.outdoor_temperature) + dp.gross_capacity
          data << new_dp
        end
      end
    end
  end

  # TODO
  #
  # @param data_array [TODO] TODO
  # @param mode [TODO] TODO
  # @return [nil]
  def self.correct_ft_cap_eir(data_array, mode)
    # Add sensitivity to indoor conditions
    # single speed cutler curve coefficients
    if mode == :clg
      cap_ft_spec_ss, eir_ft_spec_ss = get_cool_cap_eir_ft_spec(HPXML::HVACCompressorTypeSingleStage)
      rated_t_i = HVAC::AirSourceCoolRatedIWB
      indoor_t = [50.0, rated_t_i, 80.0]
    else
      # default capacity retention for single speed
      retention_temp, retention_fraction = Defaults.get_heating_capacity_retention(HPXML::HVACCompressorTypeSingleStage)
      cap_ft_spec_ss, eir_ft_spec_ss = get_heat_cap_eir_ft_spec(HPXML::HVACCompressorTypeSingleStage, retention_temp, retention_fraction)
      rated_t_i = HVAC::AirSourceHeatRatedIDB
      indoor_t = [60.0, rated_t_i, 80.0]
    end
    data_array.each do |data|
      data.each do |dp|
        if mode == :clg
          dp.indoor_wetbulb = rated_t_i
        else
          dp.indoor_temperature = rated_t_i
        end
      end
    end
    # table lookup output values
    data_array.each do |data|
      # create a new array to temporarily store expanded data points, to concat after the existing data loop
      array_tmp = Array.new
      indoor_t.each do |t_i|
        # introduce indoor conditions other than rated, expand to rated data points
        next if t_i == rated_t_i

        data_tmp = Array.new
        data.each do |dp|
          dp_new = dp.dup
          data_tmp << dp_new
          if mode == :clg
            dp_new.indoor_wetbulb = t_i
          else
            dp_new.indoor_temperature = t_i
          end
          # capacity FT curve output
          cap_ft_curve_output = MathTools.biquadratic(t_i, dp_new.outdoor_temperature, cap_ft_spec_ss[0])
          cap_ft_curve_output_rated = MathTools.biquadratic(rated_t_i, dp_new.outdoor_temperature, cap_ft_spec_ss[0])
          cap_correction_factor = cap_ft_curve_output / cap_ft_curve_output_rated
          # corrected capacity hash, with two temperature independent variables
          dp_new.gross_capacity *= cap_correction_factor

          # eir FT curve output
          eir_ft_curve_output = MathTools.biquadratic(t_i, dp_new.outdoor_temperature, eir_ft_spec_ss[0])
          eir_ft_curve_output_rated = MathTools.biquadratic(rated_t_i, dp_new.outdoor_temperature, eir_ft_spec_ss[0])
          eir_correction_factor = eir_ft_curve_output / eir_ft_curve_output_rated
          dp_new.gross_efficiency_cop /= eir_correction_factor
        end
        array_tmp << data_tmp
      end
      array_tmp.each do |new_data|
        data.concat(new_data)
      end
    end
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param obj_name [String] Name for the OpenStudio object
  # @param cooling_system [TODO] TODO
  # @param max_rated_fan_cfm [TODO] TODO
  # @param weather_max_drybulb [TODO] TODO
  # @param has_deadband_control [Boolean] Whether to apply on off thermostat deadband
  # @return [TODO] TODO
  def self.create_dx_cooling_coil(model, obj_name, cooling_system, max_rated_fan_cfm, weather_max_drybulb, has_deadband_control = false)
    clg_ap = cooling_system.additional_properties

    if cooling_system.is_a? HPXML::CoolingSystem
      clg_type = cooling_system.cooling_system_type
    elsif cooling_system.is_a? HPXML::HeatPump
      clg_type = cooling_system.heat_pump_type
    end

    if cooling_system.cooling_detailed_performance_data.empty?
      max_clg_cfm = UnitConversions.convert(cooling_system.cooling_capacity * clg_ap.cool_capacity_ratios[-1], 'Btu/hr', 'ton') * clg_ap.cool_rated_cfm_per_ton[-1]
      clg_ap.cool_rated_capacities_gross = []
      clg_ap.cool_rated_capacities_net = []
      clg_ap.cool_capacity_ratios.each_with_index do |capacity_ratio, speed|
        fan_ratio = clg_ap.cool_fan_speed_ratios[speed] * max_clg_cfm / max_rated_fan_cfm
        fan_power = calculate_fan_power_from_curve(clg_ap.fan_power_rated * max_rated_fan_cfm, fan_ratio)
        net_capacity = capacity_ratio * cooling_system.cooling_capacity
        clg_ap.cool_rated_capacities_net << net_capacity
        gross_capacity = convert_net_to_gross_capacity_cop(net_capacity, fan_power, :clg)[0]
        clg_ap.cool_rated_capacities_gross << gross_capacity
      end
    else
      process_neep_detailed_performance(cooling_system.cooling_detailed_performance_data, clg_ap, :clg, max_rated_fan_cfm, weather_max_drybulb)
    end

    clg_coil = nil
    coil_name = obj_name + ' clg coil'
    num_speeds = clg_ap.cool_rated_cfm_per_ton.size
    for i in 0..(num_speeds - 1)
      if not cooling_system.cooling_detailed_performance_data.empty?
        speed_performance_data = clg_ap.cooling_performance_data_array[i].sort_by { |dp| [dp.indoor_wetbulb, dp.outdoor_temperature] }
        var_wb = { name: 'wet_bulb_temp_in', min: -100, max: 100, values: speed_performance_data.map { |dp| UnitConversions.convert(dp.indoor_wetbulb, 'F', 'C') }.uniq }
        var_db = { name: 'dry_bulb_temp_out', min: -100, max: 100, values: speed_performance_data.map { |dp| UnitConversions.convert(dp.outdoor_temperature, 'F', 'C') }.uniq }
        cap_ft_independent_vars = [var_wb, var_db]
        eir_ft_independent_vars = [var_wb, var_db]

        rate_dp = speed_performance_data.find { |dp| (dp.indoor_wetbulb == HVAC::AirSourceCoolRatedIWB) && (dp.outdoor_temperature == HVAC::AirSourceCoolRatedODB) }
        clg_ap.cool_rated_cops << rate_dp.gross_efficiency_cop
        clg_ap.cool_rated_capacities_gross << rate_dp.gross_capacity
        clg_ap.cool_rated_capacities_net << rate_dp.capacity
        cap_ft_output_values = speed_performance_data.map { |dp| dp.gross_capacity / rate_dp.gross_capacity }
        eir_ft_output_values = speed_performance_data.map { |dp| (1.0 / dp.gross_efficiency_cop) / (1.0 / rate_dp.gross_efficiency_cop) }
        cap_ft_curve = create_table_lookup(model, "Cool-CAP-fT#{i + 1}", cap_ft_independent_vars, cap_ft_output_values, 0.0)
        eir_ft_curve = create_table_lookup(model, "Cool-EIR-fT#{i + 1}", eir_ft_independent_vars, eir_ft_output_values, 0.0)
      else
        cap_ft_curve = Model.add_curve_biquadratic(
          model,
          name: "Cool-CAP-fT#{i + 1}",
          coeff: convert_biquadratic_coeff_to_si(clg_ap.cool_cap_ft_spec[i]),
          min_x: -100, max_x: 100, min_y: -100, max_y: 100
        )
        eir_ft_curve = Model.add_curve_biquadratic(
          model,
          name: "Cool-EIR-fT#{i + 1}",
          coeff: convert_biquadratic_coeff_to_si(clg_ap.cool_eir_ft_spec[i]),
          min_x: -100, max_x: 100, min_y: -100, max_y: 100
        )
      end
      cap_fff_curve = Model.add_curve_quadratic(
        model,
        name: "Cool-CAP-fFF#{i + 1}",
        coeff: clg_ap.cool_cap_fflow_spec[i],
        min_x: 0, max_x: 2, min_y: 0, max_y: 2
      )
      eir_fff_curve = Model.add_curve_quadratic(
        model,
        name: "Cool-EIR-fFF#{i + 1}",
        coeff: clg_ap.cool_eir_fflow_spec[i],
        min_x: 0, max_x: 2, min_y: 0, max_y: 2
      )
      if i == 0
        cap_fff_curve_0 = cap_fff_curve
        eir_fff_curve_0 = eir_fff_curve
      end
      if has_deadband_control
        # Zero out impact of part load ratio
        plf_fplr_curve = Model.add_curve_quadratic(
          model,
          name: "Cool-PLF-fPLR#{i + 1}",
          coeff: [1.0, 0.0, 0.0],
          min_x: 0, max_x: 1, min_y: 0.7, max_y: 1
        )
      else
        plf_fplr_curve = Model.add_curve_quadratic(
          model,
          name: "Cool-PLF-fPLR#{i + 1}",
          coeff: clg_ap.cool_plf_fplr_spec[i],
          min_x: 0, max_x: 1, min_y: 0.7, max_y: 1
        )
      end

      if num_speeds == 1
        clg_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model, model.alwaysOnDiscreteSchedule, cap_ft_curve, cap_fff_curve, eir_ft_curve, eir_fff_curve, plf_fplr_curve)
        # Coil COP calculation based on system type
        if [HPXML::HVACTypeRoomAirConditioner, HPXML::HVACTypePTAC, HPXML::HVACTypeHeatPumpPTHP, HPXML::HVACTypeHeatPumpRoom].include? clg_type
          if cooling_system.cooling_efficiency_ceer.nil?
            ceer = calc_ceer_from_eer(cooling_system)
          else
            ceer = cooling_system.cooling_efficiency_ceer
          end
          clg_coil.setRatedCOP(UnitConversions.convert(ceer, 'Btu/hr', 'W'))
        else
          clg_coil.setRatedCOP(clg_ap.cool_rated_cops[i])
        end
        clg_coil.setMaximumOutdoorDryBulbTemperatureForCrankcaseHeaterOperation(UnitConversions.convert(CrankcaseHeaterTemp, 'F', 'C')) if cooling_system.crankcase_heater_watts.to_f > 0.0 # From RESNET Publication No. 002-2017
        clg_coil.setRatedSensibleHeatRatio(clg_ap.cool_rated_shrs_gross[i])
        clg_coil.setNominalTimeForCondensateRemovalToBegin(1000.0)
        clg_coil.setRatioOfInitialMoistureEvaporationRateAndSteadyStateLatentCapacity(1.5)
        clg_coil.setMaximumCyclingRate(3.0)
        clg_coil.setLatentCapacityTimeConstant(45.0)
        clg_coil.setRatedTotalCoolingCapacity(UnitConversions.convert(clg_ap.cool_rated_capacities_gross[i], 'Btu/hr', 'W'))
        clg_coil.setRatedAirFlowRate(calc_rated_airflow(clg_ap.cool_rated_capacities_net[i], clg_ap.cool_rated_cfm_per_ton[0]))
      else
        if clg_coil.nil?
          clg_coil = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
          clg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
          clg_coil.setApplyLatentDegradationtoSpeedsGreaterthan1(false)
          clg_coil.setFuelType(EPlus::FuelTypeElectricity)
          clg_coil.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
          clg_coil.setMaximumOutdoorDryBulbTemperatureforCrankcaseHeaterOperation(UnitConversions.convert(CrankcaseHeaterTemp, 'F', 'C')) if cooling_system.crankcase_heater_watts.to_f > 0.0 # From RESNET Publication No. 002-2017
          constant_biquadratic = Model.add_curve_biquadratic(
            model,
            name: 'ConstantBiquadratic',
            coeff: [1, 0, 0, 0, 0, 0]
          )
        end
        stage = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model, cap_ft_curve, cap_fff_curve, eir_ft_curve, eir_fff_curve, plf_fplr_curve, constant_biquadratic)
        stage.setGrossRatedCoolingCOP(clg_ap.cool_rated_cops[i])
        stage.setGrossRatedSensibleHeatRatio(clg_ap.cool_rated_shrs_gross[i])
        stage.setNominalTimeforCondensateRemovaltoBegin(1000)
        stage.setRatioofInitialMoistureEvaporationRateandSteadyStateLatentCapacity(1.5)
        stage.setRatedWasteHeatFractionofPowerInput(0.2)
        stage.setMaximumCyclingRate(3.0)
        stage.setLatentCapacityTimeConstant(45.0)
        stage.setGrossRatedTotalCoolingCapacity(UnitConversions.convert(clg_ap.cool_rated_capacities_gross[i], 'Btu/hr', 'W'))
        stage.setRatedAirFlowRate(calc_rated_airflow(clg_ap.cool_rated_capacities_net[i], clg_ap.cool_rated_cfm_per_ton[i]))
        clg_coil.addStage(stage)
      end
    end

    clg_coil.setName(coil_name)
    clg_coil.setCondenserType('AirCooled')
    clg_coil.setCrankcaseHeaterCapacity(cooling_system.crankcase_heater_watts)
    clg_coil.additionalProperties.setFeature('HPXML_ID', cooling_system.id) # Used by reporting measure
    if has_deadband_control
      # Apply startup capacity degradation
      add_capacity_degradation_ems_proram(model, clg_ap, clg_coil.name.get, true, cap_fff_curve_0, eir_fff_curve_0)
    end

    return clg_coil
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param obj_name [String] Name for the OpenStudio object
  # @param heating_system [TODO] TODO
  # @param max_rated_fan_cfm [TODO] TODO
  # @param weather_min_drybulb [TODO] TODO
  # @param defrost_model_type [TODO] TODO
  # @param p_dot_defrost [TODO] TODO
  # @param has_deadband_control [Boolean] Whether to apply on off thermostat deadband
  # @return [TODO] TODO
  def self.create_dx_heating_coil(model, obj_name, heating_system, max_rated_fan_cfm, weather_min_drybulb, defrost_model_type, p_dot_defrost, has_deadband_control = false)
    htg_ap = heating_system.additional_properties

    if heating_system.heating_detailed_performance_data.empty?
      max_htg_cfm = UnitConversions.convert(heating_system.heating_capacity * htg_ap.heat_capacity_ratios[-1], 'Btu/hr', 'ton') * htg_ap.heat_rated_cfm_per_ton[-1]
      htg_ap.heat_rated_capacities_gross = []
      htg_ap.heat_rated_capacities_net = []
      htg_ap.heat_capacity_ratios.each_with_index do |capacity_ratio, speed|
        fan_ratio = htg_ap.heat_fan_speed_ratios[speed] * max_htg_cfm / max_rated_fan_cfm
        fan_power = calculate_fan_power_from_curve(htg_ap.fan_power_rated * max_rated_fan_cfm, fan_ratio)
        net_capacity = capacity_ratio * heating_system.heating_capacity
        htg_ap.heat_rated_capacities_net << net_capacity
        gross_capacity = convert_net_to_gross_capacity_cop(net_capacity, fan_power, :htg)[0]
        htg_ap.heat_rated_capacities_gross << gross_capacity
      end
    else
      process_neep_detailed_performance(heating_system.heating_detailed_performance_data, htg_ap, :htg, max_rated_fan_cfm, weather_min_drybulb, htg_ap.hp_min_temp)
    end

    htg_coil = nil
    coil_name = obj_name + ' htg coil'

    num_speeds = htg_ap.heat_rated_cfm_per_ton.size
    for i in 0..(num_speeds - 1)
      if not heating_system.heating_detailed_performance_data.empty?
        speed_performance_data = htg_ap.heating_performance_data_array[i].sort_by { |dp| [dp.indoor_temperature, dp.outdoor_temperature] }
        var_idb = { name: 'dry_bulb_temp_in', min: -100, max: 100, values: speed_performance_data.map { |dp| UnitConversions.convert(dp.indoor_temperature, 'F', 'C') }.uniq }
        var_odb = { name: 'dry_bulb_temp_out', min: -100, max: 100, values: speed_performance_data.map { |dp| UnitConversions.convert(dp.outdoor_temperature, 'F', 'C') }.uniq }
        cap_ft_independent_vars = [var_idb, var_odb]
        eir_ft_independent_vars = [var_idb, var_odb]

        rate_dp = speed_performance_data.find { |dp| (dp.indoor_temperature == HVAC::AirSourceHeatRatedIDB) && (dp.outdoor_temperature == HVAC::AirSourceHeatRatedODB) }
        htg_ap.heat_rated_cops << rate_dp.gross_efficiency_cop
        htg_ap.heat_rated_capacities_net << rate_dp.capacity
        htg_ap.heat_rated_capacities_gross << rate_dp.gross_capacity
        cap_ft_output_values = speed_performance_data.map { |dp| dp.gross_capacity / rate_dp.gross_capacity }
        eir_ft_output_values = speed_performance_data.map { |dp| (1.0 / dp.gross_efficiency_cop) / (1.0 / rate_dp.gross_efficiency_cop) }
        cap_ft_curve = create_table_lookup(model, "Heat-CAP-fT#{i + 1}", cap_ft_independent_vars, cap_ft_output_values, 0)
        eir_ft_curve = create_table_lookup(model, "Heat-EIR-fT#{i + 1}", eir_ft_independent_vars, eir_ft_output_values, 0)
      else
        cap_ft_curve = Model.add_curve_biquadratic(
          model,
          name: "Heat-CAP-fT#{i + 1}",
          coeff: convert_biquadratic_coeff_to_si(htg_ap.heat_cap_ft_spec[i]),
          min_x: -100, max_x: 100, min_y: -100, max_y: 100
        )
        eir_ft_curve = Model.add_curve_biquadratic(
          model,
          name: "Heat-EIR-fT#{i + 1}",
          coeff: convert_biquadratic_coeff_to_si(htg_ap.heat_eir_ft_spec[i]),
          min_x: -100, max_x: 100, min_y: -100, max_y: 100
        )
      end
      cap_fff_curve = Model.add_curve_quadratic(
        model,
        name: "Heat-CAP-fFF#{i + 1}",
        coeff: htg_ap.heat_cap_fflow_spec[i],
        min_x: 0, max_x: 2, min_y: 0, max_y: 2
      )
      eir_fff_curve = Model.add_curve_quadratic(
        model,
        name: "Heat-EIR-fFF#{i + 1}",
        coeff: htg_ap.heat_eir_fflow_spec[i],
        min_x: 0, max_x: 2, min_y: 0, max_y: 2
      )
      if i == 0
        cap_fff_curve_0 = cap_fff_curve
        eir_fff_curve_0 = eir_fff_curve
      end
      if has_deadband_control
        # Zero out impact of part load ratio
        plf_fplr_curve = Model.add_curve_quadratic(
          model,
          name: "Heat-PLF-fPLR#{i + 1}",
          coeff: [1.0, 0.0, 0.0],
          min_x: 0, max_x: 1, min_y: 0.7, max_y: 1
        )
      else
        plf_fplr_curve = Model.add_curve_quadratic(
          model,
          name: "Heat-PLF-fPLR#{i + 1}",
          coeff: htg_ap.heat_plf_fplr_spec[i],
          min_x: 0, max_x: 1, min_y: 0.7, max_y: 1
        )
      end

      if num_speeds == 1
        htg_coil = OpenStudio::Model::CoilHeatingDXSingleSpeed.new(model, model.alwaysOnDiscreteSchedule, cap_ft_curve, cap_fff_curve, eir_ft_curve, eir_fff_curve, plf_fplr_curve)
        if heating_system.heating_efficiency_cop.nil?
          htg_coil.setRatedCOP(htg_ap.heat_rated_cops[i])
        else # PTHP or room heat pump
          htg_coil.setRatedCOP(heating_system.heating_efficiency_cop)
        end
        htg_coil.setRatedTotalHeatingCapacity(UnitConversions.convert(htg_ap.heat_rated_capacities_gross[i], 'Btu/hr', 'W'))
        htg_coil.setRatedAirFlowRate(calc_rated_airflow(htg_ap.heat_rated_capacities_net[i], htg_ap.heat_rated_cfm_per_ton[0]))
        defrost_time_fraction = 0.1 if defrost_model_type == HPXML::AdvancedResearchDefrostModelTypeAdvanced # 6min/hr
      else
        if htg_coil.nil?
          htg_coil = OpenStudio::Model::CoilHeatingDXMultiSpeed.new(model)
          htg_coil.setFuelType(EPlus::FuelTypeElectricity)
          htg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
          htg_coil.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
          constant_biquadratic = Model.add_curve_biquadratic(
            model,
            name: 'ConstantBiquadratic',
            coeff: [1, 0, 0, 0, 0, 0]
          )
        end
        stage = OpenStudio::Model::CoilHeatingDXMultiSpeedStageData.new(model, cap_ft_curve, cap_fff_curve, eir_ft_curve, eir_fff_curve, plf_fplr_curve, constant_biquadratic)
        stage.setGrossRatedHeatingCOP(htg_ap.heat_rated_cops[i])
        stage.setRatedWasteHeatFractionofPowerInput(0.2)
        stage.setGrossRatedHeatingCapacity(UnitConversions.convert(htg_ap.heat_rated_capacities_gross[i], 'Btu/hr', 'W'))
        stage.setRatedAirFlowRate(calc_rated_airflow(htg_ap.heat_rated_capacities_net[i], htg_ap.heat_rated_cfm_per_ton[i]))
        htg_coil.addStage(stage)
        defrost_time_fraction = 0.06667 if defrost_model_type == HPXML::AdvancedResearchDefrostModelTypeAdvanced # 4min/hr
      end
    end

    htg_coil.setName(coil_name)
    htg_coil.setMinimumOutdoorDryBulbTemperatureforCompressorOperation(UnitConversions.convert(htg_ap.hp_min_temp, 'F', 'C'))
    htg_coil.setMaximumOutdoorDryBulbTemperatureforDefrostOperation(UnitConversions.convert(40.0, 'F', 'C'))
    htg_coil.setDefrostControl('Timed')
    if defrost_model_type == HPXML::AdvancedResearchDefrostModelTypeAdvanced
      htg_coil.setDefrostStrategy('Resistive')
      htg_coil.setDefrostTimePeriodFraction(defrost_time_fraction)
      htg_coil.setResistiveDefrostHeaterCapacity(p_dot_defrost)
    elsif defrost_model_type == HPXML::AdvancedResearchDefrostModelTypeStandard

      # Heating defrost curve for reverse cycle
      defrost_eir_curve = Model.add_curve_biquadratic(
        model,
        name: 'Defrosteir',
        coeff: [0.1528, 0, 0, 0, 0, 0],
        min_x: -100, max_x: 100, min_y: -100, max_y: 100
      )

      htg_coil.setDefrostEnergyInputRatioFunctionofTemperatureCurve(defrost_eir_curve)
      htg_coil.setDefrostStrategy('ReverseCycle')
    else
      fail 'unknown defrost model type.'
    end
    if heating_system.fraction_heat_load_served == 0
      htg_coil.setResistiveDefrostHeaterCapacity(0)
    end
    htg_coil.setMaximumOutdoorDryBulbTemperatureforCrankcaseHeaterOperation(UnitConversions.convert(CrankcaseHeaterTemp, 'F', 'C')) if heating_system.crankcase_heater_watts.to_f > 0.0 # From RESNET Publication No. 002-2017
    htg_coil.setCrankcaseHeaterCapacity(heating_system.crankcase_heater_watts)
    htg_coil.additionalProperties.setFeature('HPXML_ID', heating_system.id) # Used by reporting measure
    if has_deadband_control
      # Apply startup capacity degradation
      add_capacity_degradation_ems_proram(model, htg_ap, htg_coil.name.get, false, cap_fff_curve_0, eir_fff_curve_0)
    end

    return htg_coil
  end

  # TODO
  #
  # @param cooling_system [TODO] TODO
  # @return [nil]
  def self.set_cool_rated_shrs_gross(cooling_system)
    clg_ap = cooling_system.additional_properties

    if ((cooling_system.is_a? HPXML::CoolingSystem) && ([HPXML::HVACTypeRoomAirConditioner, HPXML::HVACTypePTAC].include? cooling_system.cooling_system_type)) ||
       ((cooling_system.is_a? HPXML::HeatPump) && ([HPXML::HVACTypeHeatPumpPTHP, HPXML::HVACTypeHeatPumpRoom].include? cooling_system.heat_pump_type))
      clg_ap.cool_rated_shrs_gross = [cooling_system.cooling_shr] # We don't model the fan separately, so set gross == net
    else
      # rated shr gross and fan speed ratios
      dB_rated = HVAC::AirSourceCoolRatedIDB
      win = 0.01118470 # Humidity ratio corresponding to 80F dry bulb/67F wet bulb (from EnergyPlus)

      if cooling_system.compressor_type == HPXML::HVACCompressorTypeSingleStage
        cool_nominal_cfm_per_ton = clg_ap.cool_rated_cfm_per_ton[0]
      else
        cool_nominal_cfm_per_ton = (clg_ap.cool_rated_airflow_rate - clg_ap.cool_rated_cfm_per_ton[0] * clg_ap.cool_capacity_ratios[0]) / (clg_ap.cool_capacity_ratios[-1] - clg_ap.cool_capacity_ratios[0]) * (1.0 - clg_ap.cool_capacity_ratios[0]) + clg_ap.cool_rated_cfm_per_ton[0] * clg_ap.cool_capacity_ratios[0]
      end

      p_atm = UnitConversions.convert(1, 'atm', 'psi')

      ao = Psychrometrics.CoilAoFactor(dB_rated, p_atm, UnitConversions.convert(1, 'ton', 'kBtu/hr'), cool_nominal_cfm_per_ton, cooling_system.cooling_shr, win)

      clg_ap.cool_rated_shrs_gross = []
      clg_ap.cool_capacity_ratios.each_with_index do |capacity_ratio, i|
        # Calculate the SHR for each speed. Use maximum value of 0.98 to prevent E+ bypass factor calculation errors
        clg_ap.cool_rated_shrs_gross << [Psychrometrics.CalculateSHR(dB_rated, p_atm, UnitConversions.convert(capacity_ratio, 'ton', 'kBtu/hr'), clg_ap.cool_rated_cfm_per_ton[i] * capacity_ratio, ao, win), 0.98].min
      end
    end
  end

  # Return the time needed to reach full capacity based on c_d assumption, used for degradation EMS program.
  #
  # @param c_d [Double] Degradation coefficient
  # @return [Double] Time to reach full capacity (minutes)
  def self.calc_time_to_full_cap(c_d)
    # assuming a linear relationship between points we have data for: 2 minutes at 0.08 and 5 minutes at 0.23
    time = (20.0 * c_d + 0.4).round
    time = [time, get_time_to_full_cap_limits[0]].max
    time = [time, get_time_to_full_cap_limits[1]].min
    return time
  end

  # Return min and max limit to time needed to reach full capacity
  #
  # @return [Array<Integer, Integer>] Minimum and maximum time to reach full capacity (minutes)
  def self.get_time_to_full_cap_limits()
    return [2, 5]
  end

  # Return the EMS actuator and EMS global variable for backup coil availability schedule.
  # This is called every time EMS uses this actuator to avoid conflicts across different EMS programs.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param htg_supp_coil [OpenStudio::Model::CoilHeatingElectric or OpenStudio::Model::CoilHeatingElectricMultiStage] OpenStudio Supplemental Heating Coil object
  # @return [Array<OpenStudio::Model::EnergyManagementSystemActuator, OpenStudio::Model::EnergyManagementSystemGlobalVariable>] OpenStudio EMS Actuator and Global Variable objects for supplemental coil availability schedule
  def self.get_supp_coil_avail_sch_actuator(model, htg_supp_coil)
    actuator = model.getEnergyManagementSystemActuators.find { |act| act.name.get.include? Model.ems_friendly_name(htg_supp_coil.availabilitySchedule.name) }
    global_var_supp_avail = model.getEnergyManagementSystemGlobalVariables.find { |var| var.name.get.include? Model.ems_friendly_name(htg_supp_coil.name) }

    return actuator, global_var_supp_avail unless actuator.nil?

    # No actuator for current backup coil availability schedule
    # Create a new schedule for supp availability
    # Make sure only being called once in case of multiple cloning
    supp_avail_sch = htg_supp_coil.availabilitySchedule.clone.to_ScheduleConstant.get
    supp_avail_sch.setName("#{htg_supp_coil.name} avail sch")
    htg_supp_coil.setAvailabilitySchedule(supp_avail_sch)

    supp_coil_avail_act = Model.add_ems_actuator(
      name: "#{htg_supp_coil.availabilitySchedule.name} act",
      model_object: htg_supp_coil.availabilitySchedule,
      comp_type_and_control: EPlus::EMSActuatorScheduleConstantValue
    )

    # global variable to integrate different EMS program actuating the same schedule
    global_var_supp_avail = Model.add_ems_global_var(
      model,
      var_name: "#{htg_supp_coil.name} avail global"
    )

    global_var_supp_avail_program = Model.add_ems_program(
      model,
      name: "#{global_var_supp_avail.name} init program"
    )
    global_var_supp_avail_program.addLine("Set #{global_var_supp_avail.name} = 1")

    Model.add_ems_program_calling_manager(
      model,
      name: "#{global_var_supp_avail_program.name} calling manager",
      calling_point: 'BeginZoneTimestepBeforeInitHeatBalance',
      ems_programs: [global_var_supp_avail_program]
    )
    return supp_coil_avail_act, global_var_supp_avail
  end

  # Apply EMS program to control back up coil behavior when single speed system is modeled with on-off thermostat feature.
  # Back up coil is turned on after 5 mins that heat pump is not able to maintain setpoints.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param htg_supp_coil [OpenStudio::Model::CoilHeatingElectric or OpenStudio::Model::CoilHeatingElectricMultiStage] OpenStudio Supplemental Heating Coil object
  # @param control_zone [OpenStudio::Model::ThermalZone] Conditioned space thermal zone
  # @param htg_coil [OpenStudio::Model::CoilHeatingDXSingleSpeed or OpenStudio::Model::CoilHeatingDXMultiSpeed] OpenStudio Heating Coil object
  # @param is_onoff_thermostat_ddb [Boolean] Whether to apply on off thermostat deadband
  # @param cooling_system [HPXML::CoolingSystem or HPXML::HeatPump] The HPXML cooling system or heat pump of interest
  # @return [nil]
  def self.add_supplemental_coil_ems_program(model, htg_supp_coil, control_zone, htg_coil, is_onoff_thermostat_ddb, cooling_system)
    return if htg_supp_coil.nil?
    return unless cooling_system.compressor_type == HPXML::HVACCompressorTypeSingleStage
    return unless is_onoff_thermostat_ddb
    return if htg_supp_coil.is_a? OpenStudio::Model::CoilHeatingElectricMultiStage

    # Sensors
    tin_sensor = Model.add_ems_sensor(
      model,
      name: 'zone air temp',
      output_var_or_meter_name: 'Zone Mean Air Temperature',
      key_name: control_zone.name
    )

    htg_sch = control_zone.thermostatSetpointDualSetpoint.get.heatingSetpointTemperatureSchedule.get
    htg_sp_ss = Model.add_ems_sensor(
      model,
      name: 'htg_setpoint',
      output_var_or_meter_name: 'Schedule Value',
      key_name: htg_sch.name
    )

    supp_coil_energy = Model.add_ems_sensor(
      model,
      name: 'supp coil electric energy',
      output_var_or_meter_name: 'Heating Coil Electricity Energy',
      key_name: htg_supp_coil.name
    )

    htg_coil_energy = Model.add_ems_sensor(
      model,
      name: 'hp htg coil electric energy',
      output_var_or_meter_name: 'Heating Coil Electricity Energy',
      key_name: htg_coil.name
    )

    # Trend variables
    supp_energy_trend = Model.add_ems_trend_var(
      model,
      ems_object: supp_coil_energy,
      num_timesteps_logged: 1
    )

    htg_energy_trend = Model.add_ems_trend_var(
      model,
      ems_object: htg_coil_energy,
      num_timesteps_logged: 5
    )

    # Actuators
    supp_coil_avail_act, global_var_supp_avail = get_supp_coil_avail_sch_actuator(model, htg_supp_coil)

    ddb = model.getThermostatSetpointDualSetpoints[0].temperatureDifferenceBetweenCutoutAndSetpoint

    # Program
    supp_coil_avail_program = Model.add_ems_program(
      model,
      name: "#{htg_supp_coil.name} control program"
    )
    supp_coil_avail_program.addLine("If #{global_var_supp_avail.name} == 0") # Other EMS set it to be 0.0, keep the logic
    supp_coil_avail_program.addLine("  Set #{supp_coil_avail_act.name} = 0")
    supp_coil_avail_program.addLine('Else') # global variable = 1
    supp_coil_avail_program.addLine("  Set living_t = #{tin_sensor.name}")
    supp_coil_avail_program.addLine("  Set htg_sp_l = #{htg_sp_ss.name}")
    supp_coil_avail_program.addLine("  Set htg_sp_h = #{htg_sp_ss.name} + #{ddb}")
    supp_coil_avail_program.addLine("  If (@TRENDVALUE #{supp_energy_trend.name} 1) > 0") # backup coil is turned on, keep it on until reaching upper end of ddb in case of high frequency oscillations
    supp_coil_avail_program.addLine('    If living_t > htg_sp_h')
    supp_coil_avail_program.addLine("      Set #{global_var_supp_avail.name} = 0")
    supp_coil_avail_program.addLine("      Set #{supp_coil_avail_act.name} = 0")
    supp_coil_avail_program.addLine('    Else')
    supp_coil_avail_program.addLine("      Set #{supp_coil_avail_act.name} = 1")
    supp_coil_avail_program.addLine('    EndIf')
    supp_coil_avail_program.addLine('  Else') # Only turn on the backup coil when temperature is below lower end of ddb.
    r_s_a = ["#{htg_energy_trend.name} > 0"]
    # Observe 5 mins before turning on supp coil
    for t_i in 1..4
      r_s_a << "(@TrendValue #{htg_energy_trend.name} #{t_i}) > 0"
    end
    supp_coil_avail_program.addLine("    If #{r_s_a.join(' && ')}")
    supp_coil_avail_program.addLine('      If living_t > htg_sp_l')
    supp_coil_avail_program.addLine("        Set #{global_var_supp_avail.name} = 0")
    supp_coil_avail_program.addLine("        Set #{supp_coil_avail_act.name} = 0")
    supp_coil_avail_program.addLine('      Else')
    supp_coil_avail_program.addLine("        Set #{supp_coil_avail_act.name} = 1")
    supp_coil_avail_program.addLine('      EndIf')
    supp_coil_avail_program.addLine('    Else')
    supp_coil_avail_program.addLine("      Set #{global_var_supp_avail.name} = 0")
    supp_coil_avail_program.addLine("      Set #{supp_coil_avail_act.name} = 0")
    supp_coil_avail_program.addLine('    EndIf')
    supp_coil_avail_program.addLine('  EndIf')
    supp_coil_avail_program.addLine('EndIf')

    # ProgramCallingManagers
    Model.add_ems_program_calling_manager(
      model,
      name: "#{supp_coil_avail_program.name} calling manager",
      calling_point: 'InsideHVACSystemIterationLoop',
      ems_programs: [supp_coil_avail_program]
    )
  end

  # Apply capacity degradation EMS to account for realistic start-up losses.
  # Capacity function of airflow rate curve and EIR function of airflow rate curve are actuated to
  # capture the impact of start-up losses.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param system_ap [HPXML::AdditionalProperties] HPXML Cooling System or HPXML Heating System Additional Properties
  # @param coil_name [String] Cooling or heating coil name
  # @param is_cooling [Boolean] True if apply to cooling system
  # @param cap_fff_curve [OpenStudio::Model::CurveQuadratic] OpenStudio CurveQuadratic object for heat pump capacity function of air flow rates
  # @param eir_fff_curve [OpenStudio::Model::CurveQuadratic] OpenStudio CurveQuadratic object for heat pump eir function of air flow rates
  # @return [nil]
  def self.add_capacity_degradation_ems_proram(model, system_ap, coil_name, is_cooling, cap_fff_curve, eir_fff_curve)
    # Note: Currently only available in 1 min time step
    if is_cooling
      c_d = system_ap.cool_c_d
      cap_fflow_spec = system_ap.cool_cap_fflow_spec[0]
      eir_fflow_spec = system_ap.cool_eir_fflow_spec[0]
      ss_var_name = 'Cooling Coil Electricity Energy'
    else
      c_d = system_ap.heat_c_d
      cap_fflow_spec = system_ap.heat_cap_fflow_spec[0]
      eir_fflow_spec = system_ap.heat_eir_fflow_spec[0]
      ss_var_name = 'Heating Coil Electricity Energy'
    end
    number_of_timestep_logged = calc_time_to_full_cap(c_d)

    # Sensors
    cap_curve_var_in = Model.add_ems_sensor(
      model,
      name: "#{cap_fff_curve.name.get.gsub('-', '_')} Var",
      output_var_or_meter_name: 'Performance Curve Input Variable 1 Value',
      key_name: cap_fff_curve.name
    )

    eir_curve_var_in = Model.add_ems_sensor(
      model,
      name: "#{eir_fff_curve.name.get.gsub('-', '_')} Var",
      output_var_or_meter_name: 'Performance Curve Input Variable 1 Value',
      key_name: eir_fff_curve.name
    )

    coil_power_ss = Model.add_ems_sensor(
      model,
      name: "#{coil_name} electric energy",
      output_var_or_meter_name: ss_var_name,
      key_name: coil_name
    )

    # Trend variable
    coil_power_ss_trend = Model.add_ems_trend_var(
      model,
      ems_object: coil_power_ss,
      num_timesteps_logged: number_of_timestep_logged
    )

    # Actuators
    cc_actuator = Model.add_ems_actuator(
      name: "#{cap_fff_curve.name} value",
      model_object: cap_fff_curve,
      comp_type_and_control: EPlus::EMSActuatorCurveResult
    )

    ec_actuator = Model.add_ems_actuator(
      name: "#{eir_fff_curve.name} value",
      model_object: eir_fff_curve,
      comp_type_and_control: EPlus::EMSActuatorCurveResult
    )

    # Program
    cycling_degrad_program = Model.add_ems_program(
      model,
      name: "#{coil_name} cycling degradation program"
    )

    # Check values within min/max limits
    cycling_degrad_program.addLine("If #{cap_curve_var_in.name} < #{cap_fff_curve.minimumValueofx}")
    cycling_degrad_program.addLine("  Set #{cap_curve_var_in.name} = #{cap_fff_curve.minimumValueofx}")
    cycling_degrad_program.addLine("ElseIf #{cap_curve_var_in.name} > #{cap_fff_curve.maximumValueofx}")
    cycling_degrad_program.addLine("  Set #{cap_curve_var_in.name} = #{cap_fff_curve.maximumValueofx}")
    cycling_degrad_program.addLine('EndIf')
    cycling_degrad_program.addLine("If #{eir_curve_var_in.name} < #{eir_fff_curve.minimumValueofx}")
    cycling_degrad_program.addLine("  Set #{eir_curve_var_in.name} = #{eir_fff_curve.minimumValueofx}")
    cycling_degrad_program.addLine("ElseIf #{eir_curve_var_in.name} > #{eir_fff_curve.maximumValueofx}")
    cycling_degrad_program.addLine("  Set #{eir_curve_var_in.name} = #{eir_fff_curve.maximumValueofx}")
    cycling_degrad_program.addLine('EndIf')
    cc_out_calc = []
    ec_out_calc = []
    cap_fflow_spec.each_with_index do |coeff, i|
      c_name = "c_#{i + 1}_cap"
      cycling_degrad_program.addLine("Set #{c_name} = #{coeff}")
      cc_out_calc << c_name + " * (#{cap_curve_var_in.name}^#{i})"
    end
    eir_fflow_spec.each_with_index do |coeff, i|
      c_name = "c_#{i + 1}_eir"
      cycling_degrad_program.addLine("Set #{c_name} = #{coeff}")
      ec_out_calc << c_name + " * (#{eir_curve_var_in.name}^#{i})"
    end
    cycling_degrad_program.addLine("Set cc_out = #{cc_out_calc.join(' + ')}")
    cycling_degrad_program.addLine("Set ec_out = #{ec_out_calc.join(' + ')}")
    (0..number_of_timestep_logged).each do |t_i|
      if t_i == 0
        cycling_degrad_program.addLine("Set cc_now = #{coil_power_ss_trend.name}")
      else
        cycling_degrad_program.addLine("Set cc_#{t_i}_ago = @TrendValue #{coil_power_ss_trend.name} #{t_i}")
      end
    end
    (1..number_of_timestep_logged).each do |t_i|
      if t_i == 1
        cycling_degrad_program.addLine("If cc_#{t_i}_ago == 0 && cc_now > 0") # Coil just turned on
      else
        r_s_a = ['cc_now > 0']
        for i in 1..t_i - 1
          r_s_a << "cc_#{i}_ago > 0"
        end
        r_s = r_s_a.join(' && ')
        cycling_degrad_program.addLine("ElseIf cc_#{t_i}_ago == 0 && #{r_s}")
      end
      # Curve fit from Winkler's thesis, page 200: https://drum.lib.umd.edu/bitstream/handle/1903/9493/Winkler_umd_0117E_10504.pdf?sequence=1&isAllowed=y
      # use average curve value ( ~ at 0.5 min).
      # This curve reached steady state in 2 mins, assume shape for high efficiency units, scale it down based on number_of_timestep_logged
      cycling_degrad_program.addLine("  Set exp = @Exp((-2.19722) * #{get_time_to_full_cap_limits[0]} / #{number_of_timestep_logged} * #{t_i - 0.5})")
      cycling_degrad_program.addLine('  Set cc_mult = (-1.0125 * exp + 1.0125)')
      cycling_degrad_program.addLine('  Set cc_mult = @Min cc_mult 1.0')
    end
    cycling_degrad_program.addLine('Else')
    cycling_degrad_program.addLine('  Set cc_mult = 1.0')
    cycling_degrad_program.addLine('EndIf')
    cycling_degrad_program.addLine("Set #{cc_actuator.name} = cc_mult * cc_out")
    # power is ramped up in less than 1 min, only second level simulation can capture power startup behavior
    cycling_degrad_program.addLine("Set #{ec_actuator.name} = ec_out / cc_mult")

    # ProgramCallingManagers
    Model.add_ems_program_calling_manager(
      model,
      name: "#{cycling_degrad_program.name} calling manager",
      calling_point: 'InsideHVACSystemIterationLoop',
      ems_programs: [cycling_degrad_program]
    )
  end

  # Apply time-based realistic staging EMS program for two speed system.
  # Observe 5 mins before ramping up the speed level, or enable the backup coil.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param unitary_system [OpenStudio::Model::AirLoopHVACUnitarySystem] OpenStudio Air Loop HVAC Unitary System object
  # @param htg_supp_coil [OpenStudio::Model::CoilHeatingElectric or OpenStudio::Model::CoilHeatingElectricMultiStage] OpenStudio Supplemental Heating Coil object
  # @param control_zone [OpenStudio::Model::ThermalZone] Conditioned space thermal zone
  # @param is_onoff_thermostat_ddb [Boolean] Whether to apply on off thermostat deadband
  # @param cooling_system [HPXML::CoolingSystem or HPXML::HeatPump] The HPXML cooling system or heat pump of interest
  # @return [nil]
  def self.add_two_speed_staging_ems_program(model, unitary_system, htg_supp_coil, control_zone, is_onoff_thermostat_ddb, cooling_system)
    # Note: Currently only available in 1 min time step
    return unless is_onoff_thermostat_ddb
    return unless cooling_system.compressor_type == HPXML::HVACCompressorTypeTwoStage

    number_of_timestep_logged = 5 # wait 5 mins to check demand

    is_heatpump = cooling_system.is_a? HPXML::HeatPump

    # Sensors
    if not htg_supp_coil.nil?
      backup_coil_energy = Model.add_ems_sensor(
        model,
        name: "#{htg_supp_coil.name} heating energy",
        output_var_or_meter_name: 'Heating Coil Heating Energy',
        key_name: htg_supp_coil.name
      )

      # Trend variable
      backup_energy_trend = Model.add_ems_trend_var(
        model,
        ems_object: backup_coil_energy,
        num_timesteps_logged: 1
      )

      supp_coil_avail_act, global_var_supp_avail = get_supp_coil_avail_sch_actuator(model, htg_supp_coil)
    end
    # Sensors
    living_temp_ss = Model.add_ems_sensor(
      model,
      name: "#{control_zone.name} temp",
      output_var_or_meter_name: 'Zone Air Temperature',
      key_name: control_zone.name
    )

    htg_sch = control_zone.thermostatSetpointDualSetpoint.get.heatingSetpointTemperatureSchedule.get
    clg_sch = control_zone.thermostatSetpointDualSetpoint.get.coolingSetpointTemperatureSchedule.get

    htg_sp_ss = Model.add_ems_sensor(
      model,
      name: "#{control_zone.name} htg setpoint",
      output_var_or_meter_name: 'Schedule Value',
      key_name: htg_sch.name
    )

    clg_sp_ss = Model.add_ems_sensor(
      model,
      name: "#{control_zone.name} clg setpoint",
      output_var_or_meter_name: 'Schedule Value',
      key_name: clg_sch.name
    )

    unitary_var = Model.add_ems_sensor(
      model,
      name: "#{unitary_system.name}  speed level",
      output_var_or_meter_name: 'Unitary System DX Coil Speed Level',
      key_name: unitary_system.name
    )

    # Actuators
    unitary_actuator = Model.add_ems_actuator(
      name: "#{unitary_system.name} speed override",
      model_object: unitary_system,
      comp_type_and_control: EPlus::EMSActuatorUnitarySystemCoilSpeedLevel
    )

    # Trend variable
    unitary_speed_var_trend = Model.add_ems_trend_var(
      model,
      ems_object: unitary_var,
      num_timesteps_logged: number_of_timestep_logged
    )

    ddb = model.getThermostatSetpointDualSetpoints[0].temperatureDifferenceBetweenCutoutAndSetpoint

    # Program
    realistic_cycling_program = Model.add_ems_program(
      model,
      name: "#{unitary_system.name} realistic cycling"
    )

    # Check values within min/max limits
    realistic_cycling_program.addLine("Set living_t = #{living_temp_ss.name}")
    realistic_cycling_program.addLine("Set htg_sp_l = #{htg_sp_ss.name}")
    realistic_cycling_program.addLine("Set htg_sp_h = #{htg_sp_ss.name} + #{ddb}")
    realistic_cycling_program.addLine("Set clg_sp_l = #{clg_sp_ss.name} - #{ddb}")
    realistic_cycling_program.addLine("Set clg_sp_h = #{clg_sp_ss.name}")

    (1..number_of_timestep_logged).each do |t_i|
      realistic_cycling_program.addLine("Set unitary_var_#{t_i}_ago = @TrendValue #{unitary_speed_var_trend.name} #{t_i}")
    end
    s_trend_low = []
    s_trend_high = []
    (1..number_of_timestep_logged).each do |t_i|
      s_trend_low << "(unitary_var_#{t_i}_ago == 1)"
      s_trend_high << "(unitary_var_#{t_i}_ago == 2)"
    end
    # Cooling
    # Setpoint not met and low speed is on for 5 time steps
    realistic_cycling_program.addLine("If (living_t - clg_sp_h > 0.0) && (#{s_trend_low.join(' && ')})")
    # Enable high speed unitary system
    realistic_cycling_program.addLine("  Set #{unitary_actuator.name} = 2")
    # Keep high speed unitary on until setpoint +- deadband is met
    realistic_cycling_program.addLine('ElseIf (unitary_var_1_ago == 2) && ((living_t - clg_sp_l > 0.0))')
    realistic_cycling_program.addLine("  Set #{unitary_actuator.name} = 2")
    realistic_cycling_program.addLine('Else')
    realistic_cycling_program.addLine("  Set #{unitary_actuator.name} = 1")
    realistic_cycling_program.addLine('EndIf')
    if is_heatpump
      # Heating
      realistic_cycling_program.addLine("If (htg_sp_l - living_t > 0.0) && (#{s_trend_low.join(' && ')})")
      # Enable high speed unitary system
      realistic_cycling_program.addLine("  Set #{unitary_actuator.name} = 2")
      # Keep high speed unitary on until setpoint +- deadband is met
      realistic_cycling_program.addLine('ElseIf (unitary_var_1_ago == 2) && (htg_sp_h - living_t > 0.0)')
      realistic_cycling_program.addLine("  Set #{unitary_actuator.name} = 2")
      realistic_cycling_program.addLine('Else')
      realistic_cycling_program.addLine("  Set #{unitary_actuator.name} = 1")
      realistic_cycling_program.addLine('EndIf')
      if (not htg_supp_coil.nil?) && (not (htg_supp_coil.is_a? OpenStudio::Model::CoilHeatingElectricMultiStage))
        realistic_cycling_program.addLine("If #{global_var_supp_avail.name} == 0") # Other EMS set it to be 0.0, keep the logic
        realistic_cycling_program.addLine("  Set #{supp_coil_avail_act.name} = 0")
        realistic_cycling_program.addLine('Else') # global variable = 1
        realistic_cycling_program.addLine("  Set #{supp_coil_avail_act.name} = 1")
        realistic_cycling_program.addLine("  If (htg_sp_l - living_t > 0.0) && (#{s_trend_high.join(' && ')})")
        realistic_cycling_program.addLine("    Set #{supp_coil_avail_act.name} = 1")
        realistic_cycling_program.addLine("  ElseIf ((@TRENDVALUE #{backup_energy_trend.name} 1) > 0) && (htg_sp_h - living_t > 0.0)") # backup coil is turned on, keep it on until reaching upper end of ddb in case of high frequency oscillations
        realistic_cycling_program.addLine("    Set #{supp_coil_avail_act.name} = 1")
        realistic_cycling_program.addLine('  Else')
        realistic_cycling_program.addLine("    Set #{global_var_supp_avail.name} = 0")
        realistic_cycling_program.addLine("    Set #{supp_coil_avail_act.name} = 0")
        realistic_cycling_program.addLine('  EndIf')
        realistic_cycling_program.addLine('EndIf')
      end
    end

    # ProgramCallingManagers
    Model.add_ems_program_calling_manager(
      model,
      name: "#{realistic_cycling_program.name} Program Manager",
      calling_point: 'InsideHVACSystemIterationLoop',
      ems_programs: [realistic_cycling_program]
    )
  end

  # Apply maximum power ratio schedule for variable speed system.
  # Creates EMS program to determine and control the stage that can reach the maximum power constraint.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param air_loop_unitary [OpenStudio::Model::AirLoopHVACUnitarySystem] Air loop for the HVAC system
  # @param control_zone [OpenStudio::Model::ThermalZone] Conditioned space thermal zone
  # @param heating_system [HPXML::HeatingSystem or HPXML::HeatPump] The HPXML heating system or heat pump of interest
  # @param cooling_system [HPXML::CoolingSystem or HPXML::HeatPump] The HPXML cooling system or heat pump of interest
  # @param htg_supp_coil [OpenStudio::Model::CoilHeatingElectric or CoilHeatingElectricMultiStage] OpenStudio Supplemental Heating Coil object
  # @param clg_coil [OpenStudio::Model::CoilCoolingDXMultiSpeed] OpenStudio MultiStage Cooling Coil object
  # @param htg_coil [OpenStudio::Model::CoilHeatingDXMultiSpeed] OpenStudio MultiStage Heating Coil object
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def self.add_variable_speed_power_ems_program(runner, model, air_loop_unitary, control_zone, heating_system, cooling_system, htg_supp_coil, clg_coil, htg_coil, schedules_file)
    return if schedules_file.nil?
    return if clg_coil.nil? && htg_coil.nil?

    max_pow_ratio_sch = schedules_file.create_schedule_file(model, col_name: SchedulesFile::Columns[:HVACMaximumPowerRatio].name, schedule_type_limits_name: EPlus::ScheduleTypeLimitsFraction)
    return if max_pow_ratio_sch.nil?

    # Check maximum power ratio schedules only used in var speed systems,
    clg_coil = nil unless (cooling_system.compressor_type == HPXML::HVACCompressorTypeVariableSpeed)
    htg_coil = nil unless ((heating_system.is_a? HPXML::HeatPump) && heating_system.compressor_type == HPXML::HVACCompressorTypeVariableSpeed)
    htg_supp_coil = nil unless ((heating_system.is_a? HPXML::HeatPump) && heating_system.compressor_type == HPXML::HVACCompressorTypeVariableSpeed)
    # No variable speed coil
    if clg_coil.nil? && htg_coil.nil?
      runner.registerWarning('Maximum power ratio schedule is only supported for variable speed systems.')
    end

    if (htg_coil.is_a? OpenStudio::Model::CoilHeatingDXMultiSpeed) && (heating_system.backup_type != HPXML::HeatPumpBackupTypeIntegrated)
      htg_coil = nil
      htg_supp_coil = nil
      runner.registerWarning('Maximum power ratio schedule is only supported for integrated backup system. Schedule is ignored for heating.')
    end

    return if (clg_coil.nil? && htg_coil.nil?)

    # sensors
    pow_ratio_sensor = Model.add_ems_sensor(
      model,
      name: "#{air_loop_unitary.name} power_ratio",
      output_var_or_meter_name: 'Schedule Value',
      key_name: max_pow_ratio_sch.name
    )

    indoor_temp_sensor = Model.add_ems_sensor(
      model,
      name: "#{control_zone.name} indoor_temp",
      output_var_or_meter_name: 'Zone Air Temperature',
      key_name: control_zone.name
    )

    htg_spt_sensor = Model.add_ems_sensor(
      model,
      name: "#{control_zone.name} htg_spt_temp",
      output_var_or_meter_name: 'Zone Thermostat Heating Setpoint Temperature',
      key_name: control_zone.name
    )

    clg_spt_sensor = Model.add_ems_sensor(
      model,
      name: "#{control_zone.name} clg_spt_temp",
      output_var_or_meter_name: 'Zone Thermostat Cooling Setpoint Temperature',
      key_name: control_zone.name
    )

    load_sensor = Model.add_ems_sensor(
      model,
      name: "#{air_loop_unitary.name} sens load",
      output_var_or_meter_name: 'Unitary System Predicted Sensible Load to Setpoint Heat Transfer Rate',
      key_name: air_loop_unitary.name
    )

    # global variable
    temp_offset_signal = Model.add_ems_global_var(
      model,
      var_name: "#{air_loop_unitary.name} temp offset"
    )

    # Temp offset Initialization Program
    # Temperature offset signal used to see if the hvac is recovering temperature to setpoint.
    # If abs (indoor temperature - setpoint) > offset, then hvac and backup is allowed to operate without cap to recover temperature until it reaches setpoint
    temp_offset_program = Model.add_ems_program(
      model,
      name: "#{air_loop_unitary.name} temp offset init program"
    )
    temp_offset_program.addLine("Set #{temp_offset_signal.name} = 0")

    # calling managers
    Model.add_ems_program_calling_manager(
      model,
      name: "#{temp_offset_program.name} calling manager",
      calling_point: 'BeginNewEnvironment',
      ems_programs: [temp_offset_program]
    )

    Model.add_ems_program_calling_manager(
      model,
      name: "#{temp_offset_program.name} calling manager2",
      calling_point: 'AfterNewEnvironmentWarmUpIsComplete',
      ems_programs: [temp_offset_program]
    )

    # actuator
    coil_speed_act = Model.add_ems_actuator(
      name: "#{air_loop_unitary.name} coil speed level",
      model_object: air_loop_unitary,
      comp_type_and_control: EPlus::EMSActuatorUnitarySystemCoilSpeedLevel
    )
    if not htg_supp_coil.nil?
      supp_coil_avail_act, global_var_supp_avail = get_supp_coil_avail_sch_actuator(model, htg_supp_coil)
    end

    # EMS program
    program = Model.add_ems_program(
      model,
      name: "#{air_loop_unitary.name} max power ratio program"
    )
    program.addLine('Set clg_mode = 0')
    program.addLine('Set htg_mode = 0')
    program.addLine("If #{load_sensor.name} > 0")
    program.addLine('  Set htg_mode = 1')
    program.addLine("  Set setpoint = #{htg_spt_sensor.name}")
    program.addLine("ElseIf #{load_sensor.name} < 0")
    program.addLine('  Set clg_mode = 1')
    program.addLine("  Set setpoint = #{clg_spt_sensor.name}")
    program.addLine('EndIf')
    program.addLine("Set sens_load = @Abs #{load_sensor.name}")
    program.addLine('Set clg_mode = 0') if clg_coil.nil?
    program.addLine('Set htg_mode = 0') if htg_coil.nil?

    [htg_coil, clg_coil].each do |coil|
      next if coil.nil?

      coil_cap_stage_fff_sensors = []
      coil_cap_stage_ft_sensors = []
      coil_eir_stage_fff_sensors = []
      coil_eir_stage_ft_sensors = []
      coil_eir_stage_plf_sensors = []
      # Heating/Cooling specific calculations and names
      if coil.is_a? OpenStudio::Model::CoilHeatingDXMultiSpeed
        cap_fff_curve_name = 'heatingCapacityFunctionofFlowFractionCurve'
        cap_ft_curve_name = 'heatingCapacityFunctionofTemperatureCurve'
        capacity_name = 'grossRatedHeatingCapacity'
        cop_name = 'grossRatedHeatingCOP'
        cap_multiplier = 'htg_frost_multiplier_cap'
        pow_multiplier = 'htg_frost_multiplier_pow'
        mode_s = 'If htg_mode > 0'

        # Outdoor sensors added to calculate defrost adjustment for heating
        outdoor_db_sensor = Model.add_ems_sensor(
          model,
          name: 'outdoor_db',
          output_var_or_meter_name: 'Site Outdoor Air Drybulb Temperature',
          key_name: nil
        )

        outdoor_w_sensor = Model.add_ems_sensor(
          model,
          name: 'outdoor_w',
          output_var_or_meter_name: 'Site Outdoor Air Humidity Ratio',
          key_name: nil
        )

        outdoor_bp_sensor = Model.add_ems_sensor(
          model,
          name: 'outdoor_bp',
          output_var_or_meter_name: 'Site Outdoor Air Barometric Pressure',
          key_name: nil
        )

        # Calculate capacity and eirs for later use of full-load power calculations at each stage
        # Equations from E+ source code
        program.addLine('If htg_mode > 0')
        program.addLine("  If #{outdoor_db_sensor.name} < 4.444444,")
        program.addLine("    Set T_coil_out = 0.82 * #{outdoor_db_sensor.name} - 8.589")
        program.addLine("    Set delta_humidity_ratio = @MAX 0 (#{outdoor_w_sensor.name} - (@WFnTdbRhPb T_coil_out 1.0 #{outdoor_bp_sensor.name}))")
        program.addLine("    Set #{cap_multiplier} = 0.909 - 107.33 * delta_humidity_ratio")
        program.addLine("    Set #{pow_multiplier} = 0.90 - 36.45 * delta_humidity_ratio")
        program.addLine('  Else')
        program.addLine("    Set #{cap_multiplier} = 1.0")
        program.addLine("    Set #{pow_multiplier} = 1.0")
        program.addLine('  EndIf')
        program.addLine('EndIf')
      elsif coil.is_a? OpenStudio::Model::CoilCoolingDXMultiSpeed
        cap_fff_curve_name = 'totalCoolingCapacityFunctionofFlowFractionCurve'
        cap_ft_curve_name = 'totalCoolingCapacityFunctionofTemperatureCurve'
        capacity_name = 'grossRatedTotalCoolingCapacity'
        cop_name = 'grossRatedCoolingCOP'
        cap_multiplier = 'shr'
        pow_multiplier = '1.0'
        mode_s = 'If clg_mode > 0'

        # cooling coil cooling rate sensors to calculate real time SHR
        clg_tot_sensor = Model.add_ems_sensor(
          model,
          name: "#{coil.name} total cooling rate",
          output_var_or_meter_name: 'Cooling Coil Total Cooling Rate',
          key_name: coil.name
        )

        clg_sens_sensor = Model.add_ems_sensor(
          model,
          name: "#{coil.name} sens cooling rate",
          output_var_or_meter_name: 'Cooling Coil Sensible Cooling Rate',
          key_name: coil.name
        )

        program.addLine('If clg_mode > 0')
        program.addLine("  If #{clg_tot_sensor.name} > 0")
        program.addLine("    Set #{cap_multiplier} = #{clg_sens_sensor.name} / #{clg_tot_sensor.name}")
        program.addLine('  Else')
        # Missing dynamic SHR, set rated instead
        program.addLine("    Set #{cap_multiplier} = #{coil.stages[-1].grossRatedSensibleHeatRatio}")
        program.addLine('  EndIf')
        program.addLine('EndIf')
      end
      # Heating and cooling performance curve sensors that need to be added
      coil.stages.each_with_index do |stage, i|
        coil_cap_stage_fff_sensors << Model.add_ems_sensor(
          model,
          name: "#{coil.name} cap stage #{i} fff",
          output_var_or_meter_name: 'Performance Curve Output Value',
          key_name: stage.send(cap_fff_curve_name).name
        )

        coil_cap_stage_ft_sensors << Model.add_ems_sensor(
          model,
          name: "#{coil.name} cap stage #{i} ft",
          output_var_or_meter_name: 'Performance Curve Output Value',
          key_name: stage.send(cap_ft_curve_name).name
        )

        coil_eir_stage_fff_sensors << Model.add_ems_sensor(
          model,
          name: "#{coil.name} eir stage #{i} fff",
          output_var_or_meter_name: 'Performance Curve Output Value',
          key_name: stage.energyInputRatioFunctionofFlowFractionCurve.name
        )

        coil_eir_stage_ft_sensors << Model.add_ems_sensor(
          model,
          name: "#{coil.name} eir stage #{i} ft",
          output_var_or_meter_name: 'Performance Curve Output Value',
          key_name: stage.energyInputRatioFunctionofTemperatureCurve.name
        )

        coil_eir_stage_plf_sensors << Model.add_ems_sensor(
          model,
          name: "#{coil.name} eir stage #{i} fplr",
          output_var_or_meter_name: 'Performance Curve Output Value',
          key_name: stage.partLoadFractionCorrelationCurve.name
        )
      end
      # Calculate the target speed ratio that operates at the target power output
      program.addLine(mode_s)
      coil.stages.each_with_index do |stage, i|
        program.addLine("  Set rt_capacity_#{i} = #{stage.send(capacity_name)} * #{coil_cap_stage_fff_sensors[i].name} * #{coil_cap_stage_ft_sensors[i].name}")
        program.addLine("  Set rt_capacity_#{i}_adj = rt_capacity_#{i} * #{cap_multiplier}")
        program.addLine("  Set rated_eir_#{i} = 1 / #{stage.send(cop_name)}")
        program.addLine("  Set plf = #{coil_eir_stage_plf_sensors[i].name}")
        program.addLine("  If #{coil_eir_stage_plf_sensors[i].name} > 0.0")
        program.addLine("    Set rt_eir_#{i} = rated_eir_#{i} * #{coil_eir_stage_ft_sensors[i].name} * #{coil_eir_stage_fff_sensors[i].name} / #{coil_eir_stage_plf_sensors[i].name}")
        program.addLine('  Else')
        program.addLine("    Set rt_eir_#{i} = 0")
        program.addLine('  EndIf')
        program.addLine("  Set rt_power_#{i} = rt_eir_#{i} * rt_capacity_#{i} * #{pow_multiplier}") # use unadjusted capacity value in pow calculations
      end
      program.addLine("  Set target_power = #{coil.stages[-1].send(capacity_name)} * rated_eir_#{coil.stages.size - 1} * #{pow_ratio_sensor.name}")
      (0..coil.stages.size - 1).each do |i|
        if i == 0
          program.addLine("  If target_power < rt_power_#{i}")
          program.addLine("    Set target_speed_ratio = target_power / rt_power_#{i}")
        else
          program.addLine("  ElseIf target_power < rt_power_#{i}")
          program.addLine("    Set target_speed_ratio = (target_power - rt_power_#{i - 1}) / (rt_power_#{i} - rt_power_#{i - 1}) + #{i}")
        end
      end
      program.addLine('  Else')
      program.addLine("    Set target_speed_ratio = #{coil.stages.size}")
      program.addLine('  EndIf')

      # Calculate the current power that needs to meet zone loads
      (0..coil.stages.size - 1).each do |i|
        if i == 0
          program.addLine("  If sens_load <= rt_capacity_#{i}_adj")
          program.addLine("    Set current_power = sens_load / rt_capacity_#{i}_adj * rt_power_#{i}")
        else
          program.addLine("  ElseIf sens_load <= rt_capacity_#{i}_adj")
          program.addLine("    Set hs_speed_ratio = (sens_load - rt_capacity_#{i - 1}_adj) / (rt_capacity_#{i}_adj - rt_capacity_#{i - 1}_adj)")
          program.addLine('    Set ls_speed_ratio = 1 - hs_speed_ratio')
          program.addLine("    Set current_power = hs_speed_ratio * rt_power_#{i} + ls_speed_ratio * rt_power_#{i - 1}")
        end
      end
      program.addLine('  Else')
      program.addLine("    Set current_power = rt_power_#{coil.stages.size - 1}")
      program.addLine('  EndIf')
      program.addLine('EndIf')
    end

    program.addLine("Set #{supp_coil_avail_act.name} = #{global_var_supp_avail.name}") unless htg_supp_coil.nil?
    program.addLine('If htg_mode > 0 || clg_mode > 0')
    program.addLine("  If (#{pow_ratio_sensor.name} == 1) || ((@Abs (#{indoor_temp_sensor.name} - setpoint)) > #{UnitConversions.convert(4, 'deltaF', 'deltaC')}) || #{temp_offset_signal.name} == 1")
    program.addLine("    Set #{coil_speed_act.name} = NULL")
    program.addLine("    If ((@Abs (#{indoor_temp_sensor.name} - setpoint)) > #{UnitConversions.convert(4, 'deltaF', 'deltaC')})")
    program.addLine("      Set #{temp_offset_signal.name} = 1")
    program.addLine("    ElseIf (@Abs (#{indoor_temp_sensor.name} - setpoint)) < 0.001") # Temperature recovered
    program.addLine("      Set #{temp_offset_signal.name} = 0")
    program.addLine('    EndIf')
    program.addLine('  Else')
    # general & critical curtailment, operation refers to AHRI Standard 1380 2019
    program.addLine('    If current_power >= target_power')
    program.addLine("      Set #{coil_speed_act.name} = target_speed_ratio")
    if not htg_supp_coil.nil?
      program.addLine("      Set #{global_var_supp_avail.name} = 0")
      program.addLine("      Set #{supp_coil_avail_act.name} = 0")
    end
    program.addLine('    Else')
    program.addLine("      Set #{coil_speed_act.name} = NULL")
    program.addLine('    EndIf')
    program.addLine('  EndIf')
    program.addLine('EndIf')

    # calling manager
    Model.add_ems_program_calling_manager(
      model,
      name: "#{program.name} calling manager",
      calling_point: 'InsideHVACSystemIterationLoop',
      ems_programs: [program]
    )
  end

  # Apply time-based realistic staging EMS program for integrated multi-stage backup system.
  # Observe 5 mins before ramping up the speed level.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param unitary_system [OpenStudio::Model::AirLoopHVACUnitarySystem] OpenStudio Air Loop HVAC Unitary System object
  # @param htg_supp_coil [OpenStudio::Model::CoilHeatingElectric or CoilHeatingElectricMultiStage] OpenStudio Supplemental Heating Coil object
  # @param control_zone [OpenStudio::Model::ThermalZone] Conditioned space thermal zone
  # @param htg_coil [OpenStudio::Model::CoilHeatingDXSingleSpeed or OpenStudio::Model::CoilHeatingDXMultiSpeed] OpenStudio Heating Coil object
  # @return [nil]
  def self.add_backup_staging_ems_program(model, unitary_system, htg_supp_coil, control_zone, htg_coil)
    return unless htg_supp_coil.is_a? OpenStudio::Model::CoilHeatingElectricMultiStage

    # Note: Currently only available in 1 min time step
    number_of_timestep_logged = 5 # wait 5 mins to check demand
    max_htg_coil_stage = (htg_coil.is_a? OpenStudio::Model::CoilHeatingDXSingleSpeed) ? 1 : htg_coil.stages.size
    ddb = model.getThermostatSetpointDualSetpoints[0].temperatureDifferenceBetweenCutoutAndSetpoint

    # Sensors
    living_temp_ss = Model.add_ems_sensor(
      model,
      name: 'living temp',
      output_var_or_meter_name: 'Zone Mean Air Temperature',
      key_name: control_zone.name
    )

    htg_sp_ss = Model.add_ems_sensor(
      model,
      name: 'htg_setpoint',
      output_var_or_meter_name: 'Zone Thermostat Heating Setpoint Temperature',
      key_name: control_zone.name
    )

    backup_coil_htg_rate = Model.add_ems_sensor(
      model,
      name: 'supp coil heating rate',
      output_var_or_meter_name: 'Heating Coil Heating Rate',
      key_name: htg_supp_coil.name
    )

    # Need to use availability actuator because there's a bug in E+ that didn't handle the speed level = 0 correctly.See: https://github.com/NREL/EnergyPlus/pull/9392#discussion_r1578624175
    supp_coil_avail_act, global_var_supp_avail = get_supp_coil_avail_sch_actuator(model, htg_supp_coil)

    # Trend variables
    zone_temp_trend = Model.add_ems_trend_var(
      model,
      ems_object: living_temp_ss,
      num_timesteps_logged: number_of_timestep_logged
    )

    setpoint_temp_trend = Model.add_ems_trend_var(
      model,
      ems_object: htg_sp_ss,
      num_timesteps_logged: number_of_timestep_logged
    )

    backup_coil_htg_rate_trend = Model.add_ems_trend_var(
      model,
      ems_object: backup_coil_htg_rate,
      num_timesteps_logged: number_of_timestep_logged
    )

    if max_htg_coil_stage > 1
      unitary_var = Model.add_ems_sensor(
        model,
        name: "#{unitary_system.name} speed level",
        output_var_or_meter_name: 'Unitary System DX Coil Speed Level',
        key_name: unitary_system.name
      )

      unitary_speed_var_trend = Model.add_ems_trend_var(
        model,
        ems_object: unitary_var,
        num_timesteps_logged: number_of_timestep_logged
      )
    end

    # Actuators
    supp_stage_act = Model.add_ems_actuator(
      name: "#{unitary_system.name} backup stage level",
      model_object: unitary_system,
      comp_type_and_control: EPlus::EMSActuatorUnitarySystemSuppCoilSpeedLevel
    )

    # Staging Program
    supp_staging_program = Model.add_ems_program(
      model,
      name: "#{unitary_system.name} backup staging"
    )

    # Check values within min/max limits

    s_trend = []
    (1..number_of_timestep_logged).each do |t_i|
      supp_staging_program.addLine("Set zone_temp_#{t_i}_ago = @TrendValue #{zone_temp_trend.name} #{t_i}")
      supp_staging_program.addLine("Set htg_spt_temp_#{t_i}_ago = @TrendValue #{setpoint_temp_trend.name} #{t_i}")
      supp_staging_program.addLine("Set supp_htg_rate_#{t_i}_ago = @TrendValue #{backup_coil_htg_rate_trend.name} #{t_i}")
      if max_htg_coil_stage > 1
        supp_staging_program.addLine("Set unitary_var_#{t_i}_ago = @TrendValue #{unitary_speed_var_trend.name} #{t_i}")
        s_trend << "((htg_spt_temp_#{t_i}_ago - zone_temp_#{t_i}_ago > 0.01) && (unitary_var_#{t_i}_ago == #{max_htg_coil_stage}))"
      else
        s_trend << "(htg_spt_temp_#{t_i}_ago - zone_temp_#{t_i}_ago > 0.01)"
      end
    end
    # Logic to determine whether to enable backup coil
    supp_staging_program.addLine("If #{global_var_supp_avail.name} == 0") # Other EMS set it to be 0.0, keep the logic
    supp_staging_program.addLine("  Set #{supp_coil_avail_act.name} = 0")
    supp_staging_program.addLine('Else') # global variable = 1
    supp_staging_program.addLine("  Set #{supp_coil_avail_act.name} = 1")
    supp_staging_program.addLine("  If (supp_htg_rate_1_ago > 0) && (#{htg_sp_ss.name} + #{living_temp_ss.name} > 0.01)")
    supp_staging_program.addLine("    Set #{supp_coil_avail_act.name} = 1") # Keep backup coil on until reaching setpoint
    supp_staging_program.addLine("  ElseIf (#{s_trend.join(' && ')})")
    if ddb > 0.0
      supp_staging_program.addLine("    If (#{living_temp_ss.name} >= #{htg_sp_ss.name} - #{ddb})")
      supp_staging_program.addLine("      Set #{global_var_supp_avail.name} = 0")
      supp_staging_program.addLine("      Set #{supp_coil_avail_act.name} = 0")
      supp_staging_program.addLine('    EndIf')
    end
    supp_staging_program.addLine('  Else')
    supp_staging_program.addLine("    Set #{global_var_supp_avail.name} = 0")
    supp_staging_program.addLine("    Set #{supp_coil_avail_act.name} = 0")
    supp_staging_program.addLine('  EndIf')
    supp_staging_program.addLine('EndIf')
    supp_staging_program.addLine("If #{supp_coil_avail_act.name} == 1")
    # Determine the stage
    for i in (1..htg_supp_coil.stages.size)
      s = []
      for t_i in (1..number_of_timestep_logged)
        if i == 1
          # stays at stage 0 for 5 mins
          s << "(supp_htg_rate_#{t_i}_ago < #{htg_supp_coil.stages[i - 1].nominalCapacity.get})"
        else
          # stays at stage i-1 for 5 mins
          s << "(supp_htg_rate_#{t_i}_ago < #{htg_supp_coil.stages[i - 1].nominalCapacity.get}) && (supp_htg_rate_#{t_i}_ago >= #{htg_supp_coil.stages[i - 2].nominalCapacity.get})"
        end
      end
      if i == 1
        supp_staging_program.addLine("  If #{s.join(' && ')}")
      else
        supp_staging_program.addLine("  ElseIf #{s.join(' && ')}")
      end
      supp_staging_program.addLine("    Set #{supp_stage_act.name} = #{i}")
    end
    supp_staging_program.addLine('  EndIf')
    supp_staging_program.addLine('EndIf')

    # ProgramCallingManagers
    Model.add_ems_program_calling_manager(
      model,
      name: "#{supp_staging_program.name} Program Manager",
      calling_point: 'InsideHVACSystemIterationLoop',
      ems_programs: [supp_staging_program]
    )
  end

  # TODO
  #
  # @param c_d [TODO] TODO
  # @return [TODO] TODO
  def self.calc_plr_coefficients(c_d)
    return [(1.0 - c_d), c_d, 0.0] # Linear part load model
  end

  # TODO
  #
  # @param cooling_system [TODO] TODO
  # @return [nil]
  def self.set_cool_c_d(cooling_system)
    clg_ap = cooling_system.additional_properties

    # Degradation coefficient for cooling
    if ((cooling_system.is_a? HPXML::CoolingSystem) && ([HPXML::HVACTypeRoomAirConditioner, HPXML::HVACTypePTAC].include? cooling_system.cooling_system_type)) ||
       ((cooling_system.is_a? HPXML::HeatPump) && ([HPXML::HVACTypeHeatPumpPTHP, HPXML::HVACTypeHeatPumpRoom].include? cooling_system.heat_pump_type))
      clg_ap.cool_c_d = 0.22
    else
      case cooling_system.compressor_type
      when HPXML::HVACCompressorTypeSingleStage
        if cooling_system.cooling_efficiency_seer < 13.0
          clg_ap.cool_c_d = 0.20
        else
          clg_ap.cool_c_d = 0.07
        end
      when HPXML::HVACCompressorTypeTwoStage
        clg_ap.cool_c_d = 0.11
      when HPXML::HVACCompressorTypeVariableSpeed
        clg_ap.cool_c_d = 0.25
      end
    end

    # PLF curve
    num_speeds = clg_ap.cool_capacity_ratios.size
    clg_ap.cool_plf_fplr_spec = [calc_plr_coefficients(clg_ap.cool_c_d)] * num_speeds
  end

  # TODO
  #
  # @param heating_system [TODO] TODO
  # @return [nil]
  def self.set_heat_c_d(heating_system)
    htg_ap = heating_system.additional_properties

    # Degradation coefficient for heating
    if (heating_system.is_a? HPXML::HeatPump) && ([HPXML::HVACTypeHeatPumpPTHP, HPXML::HVACTypeHeatPumpRoom].include? heating_system.heat_pump_type)
      htg_ap.heat_c_d = 0.22
    else
      case heating_system.compressor_type
      when HPXML::HVACCompressorTypeSingleStage
        if heating_system.heating_efficiency_hspf < 7.0
          htg_ap.heat_c_d =  0.20
        else
          htg_ap.heat_c_d =  0.11
        end
      when HPXML::HVACCompressorTypeTwoStage
        htg_ap.heat_c_d =  0.11
      when HPXML::HVACCompressorTypeVariableSpeed
        htg_ap.heat_c_d =  0.25
      end
    end

    # PLF curve
    num_speeds = htg_ap.heat_capacity_ratios.size
    htg_ap.heat_plf_fplr_spec = [calc_plr_coefficients(htg_ap.heat_c_d)] * num_speeds
  end

  # Calculates rated CEER (newer metric) from rated EER (older metric).
  #
  # Source: http://documents.dps.ny.gov/public/Common/ViewDoc.aspx?DocRefId=%7BB6A57FC0-6376-4401-92BD-D66EC1930DCF%7D
  #
  # @param cooling_system [HPXML::CoolingSystem or HPXML::HeatPump] The HPXML cooling system or heat pump of interest
  # @return [Double] The CEER value (Btu/Wh)
  def self.calc_ceer_from_eer(cooling_system)
    return cooling_system.cooling_efficiency_eer / 1.01
  end

  # TODO
  #
  # @param hvac_system [TODO] TODO
  # @param use_eer_cop [TODO] TODO
  # @return [nil]
  def self.set_fan_power_rated(hvac_system, use_eer_cop)
    hvac_ap = hvac_system.additional_properties

    if use_eer_cop
      # Fan not separately modeled
      hvac_ap.fan_power_rated = 0.0
    elsif hvac_system.distribution_system.nil?
      # Ductless, installed and rated value should be equal
      hvac_ap.fan_power_rated = hvac_system.fan_watts_per_cfm # W/cfm
    else
      # Based on ASHRAE 1449-RP and recommended by Hugh Henderson
      if hvac_system.cooling_efficiency_seer <= 14
        hvac_ap.fan_power_rated = 0.25 # W/cfm
      elsif hvac_system.cooling_efficiency_seer >= 16
        hvac_ap.fan_power_rated = 0.18 # W/cfm
      else
        hvac_ap.fan_power_rated = 0.25 + (0.18 - 0.25) * (hvac_system.cooling_efficiency_seer - 14.0) / 2.0 # W/cfm
      end
    end
  end

  # TODO
  #
  # @param air_loop [TODO] TODO
  # @return [TODO] TODO
  def self.get_unitary_system_from_air_loop_hvac(air_loop)
    # Returns the unitary system or nil
    air_loop.supplyComponents.each do |comp|
      next unless comp.to_AirLoopHVACUnitarySystem.is_initialized

      return comp.to_AirLoopHVACUnitarySystem.get
    end
    return
  end

  # TODO
  #
  # @param heat_pump [TODO] TODO
  # @param weather [WeatherFile] Weather object containing EPW information
  # @return [nil]
  def self.set_gshp_assumptions(heat_pump, weather)
    hp_ap = heat_pump.additional_properties
    geothermal_loop = heat_pump.geothermal_loop

    hp_ap.design_chw = [85.0, weather.design.CoolingDrybulb - 15.0, weather.data.DeepGroundAnnualTemp + 10.0].max # Temperature of water entering indoor coil, use 85F as lower bound
    hp_ap.design_delta_t = 10.0
    hp_ap.fluid_type = EPlus::FluidPropyleneGlycol
    hp_ap.frac_glycol = 0.2 # This was changed from 0.3 to 0.2 -- more typical based on experts/spec sheets
    if hp_ap.fluid_type == EPlus::FluidWater
      hp_ap.design_hw = [45.0, weather.design.HeatingDrybulb + 35.0, weather.data.DeepGroundAnnualTemp - 10.0].max # Temperature of fluid entering indoor coil, use 45F as lower bound for water
    else
      hp_ap.design_hw = [35.0, weather.design.HeatingDrybulb + 35.0, weather.data.DeepGroundAnnualTemp - 10.0].min # Temperature of fluid entering indoor coil, use 35F as upper bound
    end
    pipe_diameter = geothermal_loop.pipe_diameter
    # Pipe nominal size conversion to pipe outside diameter and inside diameter,
    # only pipe sizes <= 2" are used here with DR11 (dimension ratio)
    case pipe_diameter
    when 0.75 # 3/4" pipe
      hp_ap.pipe_od = 1.050 # in
      hp_ap.pipe_id = 0.859 # in
    when 1.0 # 1" pipe
      hp_ap.pipe_od = 1.315 # in
      hp_ap.pipe_id = 1.076 # in
    when 1.25 # 1-1/4" pipe
      hp_ap.pipe_od = 1.660 # in
      hp_ap.pipe_id = 1.358 # in
    else
      fail "Unexpected pipe size: #{pipe_diameter}"
    end
    hp_ap.u_tube_spacing_type = 'b'
    # Calculate distance between pipes
    case hp_ap.u_tube_spacing_type
    when 'as'
      # Two tubes, spaced 1/8” apart at the center of the borehole
      hp_ap.u_tube_spacing = 0.125
    when 'b'
      # Two tubes equally spaced between the borehole edges
      hp_ap.u_tube_spacing = 0.9661
    when 'c'
      # Both tubes placed against outer edge of borehole
      hp_ap.u_tube_spacing = geothermal_loop.bore_diameter - 2 * hp_ap.pipe_od
    end
  end

  # Returns the EnergyPlus sequential load fractions for every day of the year.
  #
  # @param load_frac [Double] Fraction of heating or cooling load served by this HVAC system
  # @param remaining_load_frac [Double] Fraction of heating (or cooling) load remaining prior to this HVAC system
  # @param availability_days [TODO] TODO
  # @return [Array<Double>] Array of daily fractions of remaining heating/cooling load to bet met by the HVAC system
  def self.calc_sequential_load_fractions(load_frac, remaining_load_frac, availability_days)
    if remaining_load_frac > 0
      sequential_load_frac = load_frac / remaining_load_frac
    else
      sequential_load_frac = 0.0
    end
    sequential_load_fracs = availability_days.map { |d| d * sequential_load_frac }

    return sequential_load_fracs
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param fractions [TODO] TODO
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @return [TODO] TODO
  def self.get_sequential_load_schedule(model, fractions, unavailable_periods)
    if fractions.nil?
      fractions = [0]
      unavailable_periods = []
    end

    values = fractions.map { |f| f > 1 ? 1.0 : f.round(5) }

    sch_name = 'Sequential Fraction Schedule'
    if values.uniq.length == 1
      s = ScheduleConstant.new(model, sch_name, values[0], EPlus::ScheduleTypeLimitsFraction, unavailable_periods: unavailable_periods)
      s = s.schedule
    else
      s = Schedule.create_ruleset_from_daily_season(model, sch_name, values)
      Schedule.set_unavailable_periods(model, s, sch_name, unavailable_periods)
    end

    return s
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param control_zone [OpenStudio::Model::ThermalZone] Conditioned space thermal zone
  # @param hvac_object [TODO] TODO
  # @param hvac_sequential_load_fracs [Array<Double>] Array of daily fractions of remaining heating/cooling load to bet met by the HVAC system
  # @param hvac_unavailable_periods [Hash] Map of htg/clg => HPXML::UnavailablePeriods for heating/cooling
  # @param heating_system [TODO] TODO
  # @return [nil]
  def self.set_sequential_load_fractions(model, control_zone, hvac_object, hvac_sequential_load_fracs, hvac_unavailable_periods, heating_system = nil)
    heating_sch = get_sequential_load_schedule(model, hvac_sequential_load_fracs[:htg], hvac_unavailable_periods[:htg])
    cooling_sch = get_sequential_load_schedule(model, hvac_sequential_load_fracs[:clg], hvac_unavailable_periods[:clg])
    control_zone.setSequentialHeatingFractionSchedule(hvac_object, heating_sch)
    control_zone.setSequentialCoolingFractionSchedule(hvac_object, cooling_sch)

    if (not heating_system.nil?) && (heating_system.is_a? HPXML::HeatingSystem) && heating_system.is_heat_pump_backup_system
      max_heating_temp = heating_system.primary_heat_pump.additional_properties.supp_max_temp
      if max_heating_temp.nil?
        return
      end

      # Backup system for a heat pump, and heat pump has been set with
      # backup heating switchover temperature or backup heating lockout temperature.
      # Use EMS to prevent operation of this system above the specified temperature.

      # Sensor
      tout_db_sensor = Model.add_ems_sensor(
        model,
        name: 'tout db',
        output_var_or_meter_name: 'Site Outdoor Air Drybulb Temperature',
        key_name: 'Environment'
      )

      # Actuator
      if heating_sch.is_a? OpenStudio::Model::ScheduleConstant
        comp_type_and_control = EPlus::EMSActuatorScheduleConstantValue
      elsif heating_sch.is_a? OpenStudio::Model::ScheduleRuleset
        comp_type_and_control = EPlus::EMSActuatorScheduleYearValue
      else
        fail "Unexpected heating schedule type: #{heating_sch.class}."
      end
      actuator = Model.add_ems_actuator(
        name: "#{heating_sch.name} act",
        model_object: heating_sch,
        comp_type_and_control: comp_type_and_control
      )

      # Program
      temp_override_program = Model.add_ems_program(
        model,
        name: "#{heating_sch.name} program"
      )
      temp_override_program.addLine("If #{tout_db_sensor.name} > #{UnitConversions.convert(max_heating_temp, 'F', 'C')}")
      temp_override_program.addLine("  Set #{actuator.name} = 0")
      temp_override_program.addLine('Else')
      temp_override_program.addLine("  Set #{actuator.name} = NULL") # Allow normal operation
      temp_override_program.addLine('EndIf')

      Model.add_ems_program_calling_manager(
        model,
        name: "#{heating_sch.name} program manager",
        calling_point: 'BeginZoneTimestepAfterInitHeatBalance',
        ems_programs: [temp_override_program]
      )
    end
  end

  # TODO
  #
  # @param heat_pump [TODO] TODO
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @return [nil]
  def self.set_heat_pump_temperatures(heat_pump, runner = nil)
    hp_ap = heat_pump.additional_properties

    # Sets:
    # 1. Minimum temperature (F) for HP compressor operation
    # 2. Maximum temperature (F) for HP supplemental heating operation
    if not heat_pump.backup_heating_switchover_temp.nil?
      hp_ap.hp_min_temp = heat_pump.backup_heating_switchover_temp
      hp_ap.supp_max_temp = heat_pump.backup_heating_switchover_temp
    else
      hp_ap.hp_min_temp = heat_pump.compressor_lockout_temp
      hp_ap.supp_max_temp = heat_pump.backup_heating_lockout_temp
    end

    # Error-checking
    # Can't do this in Schematron because temperatures can be defaulted
    if heat_pump.backup_type == HPXML::HeatPumpBackupTypeIntegrated
      hp_backup_fuel = heat_pump.backup_heating_fuel
    elsif not heat_pump.backup_system.nil?
      hp_backup_fuel = heat_pump.backup_system.heating_system_fuel
    end
    if (hp_backup_fuel == HPXML::FuelTypeElectricity) && (not runner.nil?)
      if (not hp_ap.hp_min_temp.nil?) && (not hp_ap.supp_max_temp.nil?) && ((hp_ap.hp_min_temp - hp_ap.supp_max_temp).abs < 5)
        if not heat_pump.backup_heating_switchover_temp.nil?
          runner.registerError('Switchover temperature should only be used for a heat pump with fossil fuel backup; use compressor lockout temperature instead.')
        else
          runner.registerError('Similar compressor/backup lockout temperatures should only be used for a heat pump with fossil fuel backup.')
        end
      end
    end
  end

  # TODO
  #
  # @param f_chg [TODO] TODO
  # @return [TODO] TODO
  def self.get_charge_fault_cooling_coeff(f_chg)
    if f_chg <= 0
      qgr_values = [-9.46E-01, 4.93E-02, -1.18E-03, -1.15E+00]
      p_values = [-3.13E-01, 1.15E-02, 2.66E-03, -1.16E-01]
    else
      qgr_values = [-1.63E-01, 1.14E-02, -2.10E-04, -1.40E-01]
      p_values = [2.19E-01, -5.01E-03, 9.89E-04, 2.84E-01]
    end
    ff_chg_values = [26.67, 35.0]
    return qgr_values, p_values, ff_chg_values
  end

  # TODO
  #
  # @param f_chg [TODO] TODO
  # @return [TODO] TODO
  def self.get_charge_fault_heating_coeff(f_chg)
    if f_chg <= 0
      qgr_values = [-0.0338595, 0.0, 0.0202827, -2.6226343] # Add a zero term to combine cooling and heating calculation
      p_values = [0.0615649, 0.0, 0.0044554, -0.2598507] # Add a zero term to combine cooling and heating calculation
    else
      qgr_values = [-0.0029514, 0.0, 0.0007379, -0.0064112] # Add a zero term to combine cooling and heating calculation
      p_values = [-0.0594134, 0.0, 0.0159205, 1.8872153] # Add a zero term to combine cooling and heating calculation
    end
    ff_chg_values = [0.0, 8.33] # Add a zero term to combine cooling and heating calculation
    return qgr_values, p_values, ff_chg_values
  end

  # TODO
  #
  # @param fault_program [TODO] TODO
  # @param tin_sensor [TODO] TODO
  # @param tout_sensor [TODO] TODO
  # @param airflow_rated_defect_ratio [TODO] TODO
  # @param clg_or_htg_coil [TODO] TODO
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param f_chg [TODO] TODO
  # @param obj_name [String] Name for the OpenStudio object
  # @param mode [TODO] TODO
  # @param defect_ratio [TODO] TODO
  # @param hvac_ap [TODO] TODO
  # @return [nil]
  def self.add_installation_quality_program(fault_program, tin_sensor, tout_sensor, airflow_rated_defect_ratio, clg_or_htg_coil, model, f_chg, obj_name, mode, defect_ratio, hvac_ap)
    if mode == :clg
      if clg_or_htg_coil.is_a? OpenStudio::Model::CoilCoolingDXSingleSpeed
        num_speeds = 1
        cap_fff_curves = [clg_or_htg_coil.totalCoolingCapacityFunctionOfFlowFractionCurve.to_CurveQuadratic.get]
        eir_pow_fff_curves = [clg_or_htg_coil.energyInputRatioFunctionOfFlowFractionCurve.to_CurveQuadratic.get]
      elsif clg_or_htg_coil.is_a? OpenStudio::Model::CoilCoolingDXMultiSpeed
        num_speeds = clg_or_htg_coil.stages.size
        if clg_or_htg_coil.stages[0].totalCoolingCapacityFunctionofFlowFractionCurve.to_CurveQuadratic.is_initialized
          cap_fff_curves = clg_or_htg_coil.stages.map { |stage| stage.totalCoolingCapacityFunctionofFlowFractionCurve.to_CurveQuadratic.get }
          eir_pow_fff_curves = clg_or_htg_coil.stages.map { |stage| stage.energyInputRatioFunctionofFlowFractionCurve.to_CurveQuadratic.get }
        else
          cap_fff_curves = clg_or_htg_coil.stages.map { |stage| stage.totalCoolingCapacityFunctionofFlowFractionCurve.to_TableLookup.get }
          eir_pow_fff_curves = clg_or_htg_coil.stages.map { |stage| stage.energyInputRatioFunctionofFlowFractionCurve.to_TableLookup.get }
        end
      elsif clg_or_htg_coil.is_a? OpenStudio::Model::CoilCoolingWaterToAirHeatPumpVariableSpeedEquationFit
        num_speeds = clg_or_htg_coil.speeds.size
        cap_fff_curves = clg_or_htg_coil.speeds.map { |speed| speed.totalCoolingCapacityFunctionofAirFlowFractionCurve.to_CurveQuadratic.get }
        eir_pow_fff_curves = clg_or_htg_coil.speeds.map { |speed| speed.energyInputRatioFunctionofAirFlowFractionCurve.to_CurveQuadratic.get }
      elsif clg_or_htg_coil.is_a? OpenStudio::Model::CoilCoolingWaterToAirHeatPumpEquationFit
        num_speeds = 1
        cap_fff_curves = [clg_or_htg_coil.totalCoolingCapacityCurve.to_CurveQuadLinear.get] # quadlinear curve, only forth term is for airflow
        eir_pow_fff_curves = [clg_or_htg_coil.coolingPowerConsumptionCurve.to_CurveQuadLinear.get] # quadlinear curve, only forth term is for airflow

        # variables are the same for eir and cap curve
        var1_sensor = Model.add_ems_sensor(
          model,
          name: 'Cool Cap Curve Var 1',
          output_var_or_meter_name: 'Performance Curve Input Variable 1 Value',
          key_name: cap_fff_curves[0].name
        )

        var2_sensor = Model.add_ems_sensor(
          model,
          name: 'Cool Cap Curve Var 2',
          output_var_or_meter_name: 'Performance Curve Input Variable 2 Value',
          key_name: cap_fff_curves[0].name
        )

        var4_sensor = Model.add_ems_sensor(
          model,
          name: 'Cool Cap Curve Var 4',
          output_var_or_meter_name: 'Performance Curve Input Variable 4 Value',
          key_name: cap_fff_curves[0].name
        )
      else
        fail 'cooling coil not supported'
      end
    elsif mode == :htg
      if clg_or_htg_coil.is_a? OpenStudio::Model::CoilHeatingDXSingleSpeed
        num_speeds = 1
        cap_fff_curves = [clg_or_htg_coil.totalHeatingCapacityFunctionofFlowFractionCurve.to_CurveQuadratic.get]
        eir_pow_fff_curves = [clg_or_htg_coil.energyInputRatioFunctionofFlowFractionCurve.to_CurveQuadratic.get]
      elsif clg_or_htg_coil.is_a? OpenStudio::Model::CoilHeatingDXMultiSpeed
        num_speeds = clg_or_htg_coil.stages.size
        if clg_or_htg_coil.stages[0].heatingCapacityFunctionofFlowFractionCurve.to_CurveQuadratic.is_initialized
          cap_fff_curves = clg_or_htg_coil.stages.map { |stage| stage.heatingCapacityFunctionofFlowFractionCurve.to_CurveQuadratic.get }
          eir_pow_fff_curves = clg_or_htg_coil.stages.map { |stage| stage.energyInputRatioFunctionofFlowFractionCurve.to_CurveQuadratic.get }
        else
          cap_fff_curves = clg_or_htg_coil.stages.map { |stage| stage.heatingCapacityFunctionofFlowFractionCurve.to_TableLookup.get }
          eir_pow_fff_curves = clg_or_htg_coil.stages.map { |stage| stage.energyInputRatioFunctionofFlowFractionCurve.to_TableLookup.get }
        end
      elsif clg_or_htg_coil.is_a? OpenStudio::Model::CoilHeatingWaterToAirHeatPumpVariableSpeedEquationFit
        num_speeds = clg_or_htg_coil.speeds.size
        cap_fff_curves = clg_or_htg_coil.speeds.map { |speed| speed.totalHeatingCapacityFunctionofAirFlowFractionCurve.to_CurveQuadratic.get }
        eir_pow_fff_curves = clg_or_htg_coil.speeds.map { |speed| speed.energyInputRatioFunctionofAirFlowFractionCurve.to_CurveQuadratic.get }
      elsif clg_or_htg_coil.is_a? OpenStudio::Model::CoilHeatingWaterToAirHeatPumpEquationFit
        num_speeds = 1
        cap_fff_curves = [clg_or_htg_coil.heatingCapacityCurve.to_CurveQuadLinear.get] # quadlinear curve, only forth term is for airflow
        eir_pow_fff_curves = [clg_or_htg_coil.heatingPowerConsumptionCurve.to_CurveQuadLinear.get] # quadlinear curve, only forth term is for airflow

        # variables are the same for eir and cap curve
        var1_sensor = Model.add_ems_sensor(
          model,
          name: 'Heat Cap Curve Var 1',
          output_var_or_meter_name: 'Performance Curve Input Variable 1 Value',
          key_name: cap_fff_curves[0].name
        )

        var2_sensor = Model.add_ems_sensor(
          model,
          name: 'Heat Cap Curve Var 2',
          output_var_or_meter_name: 'Performance Curve Input Variable 2 Value',
          key_name: cap_fff_curves[0].name
        )

        var4_sensor = Model.add_ems_sensor(
          model,
          name: 'Heat Cap Curve Var 4',
          output_var_or_meter_name: 'Performance Curve Input Variable 4 Value',
          key_name: cap_fff_curves[0].name
        )
      else
        fail 'heating coil not supported'
      end
    end

    # Apply Cutler curve airflow coefficients to later equations
    if mode == :clg
      cap_fflow_spec, eir_fflow_spec = get_cool_cap_eir_fflow_spec(HPXML::HVACCompressorTypeSingleStage)
      qgr_values, p_values, ff_chg_values = get_charge_fault_cooling_coeff(f_chg)
      suffix = 'clg'
    elsif mode == :htg
      cap_fflow_spec, eir_fflow_spec = get_heat_cap_eir_fflow_spec(HPXML::HVACCompressorTypeSingleStage)
      qgr_values, p_values, ff_chg_values = get_charge_fault_heating_coeff(f_chg)
      suffix = 'htg'
    end
    fault_program.addLine("Set a1_AF_Qgr_#{suffix} = #{cap_fflow_spec[0][0]}")
    fault_program.addLine("Set a2_AF_Qgr_#{suffix} = #{cap_fflow_spec[0][1]}")
    fault_program.addLine("Set a3_AF_Qgr_#{suffix} = #{cap_fflow_spec[0][2]}")
    fault_program.addLine("Set a1_AF_EIR_#{suffix} = #{eir_fflow_spec[0][0]}")
    fault_program.addLine("Set a2_AF_EIR_#{suffix} = #{eir_fflow_spec[0][1]}")
    fault_program.addLine("Set a3_AF_EIR_#{suffix} = #{eir_fflow_spec[0][2]}")

    # charge fault coefficients
    fault_program.addLine("Set a1_CH_Qgr_#{suffix} = #{qgr_values[0]}")
    fault_program.addLine("Set a2_CH_Qgr_#{suffix} = #{qgr_values[1]}")
    fault_program.addLine("Set a3_CH_Qgr_#{suffix} = #{qgr_values[2]}")
    fault_program.addLine("Set a4_CH_Qgr_#{suffix} = #{qgr_values[3]}")

    fault_program.addLine("Set a1_CH_P_#{suffix} = #{p_values[0]}")
    fault_program.addLine("Set a2_CH_P_#{suffix} = #{p_values[1]}")
    fault_program.addLine("Set a3_CH_P_#{suffix} = #{p_values[2]}")
    fault_program.addLine("Set a4_CH_P_#{suffix} = #{p_values[3]}")

    fault_program.addLine("Set q0_CH_#{suffix} = a1_CH_Qgr_#{suffix}")
    fault_program.addLine("Set q1_CH_#{suffix} = a2_CH_Qgr_#{suffix}*#{tin_sensor.name}")
    fault_program.addLine("Set q2_CH_#{suffix} = a3_CH_Qgr_#{suffix}*#{tout_sensor.name}")
    fault_program.addLine("Set q3_CH_#{suffix} = a4_CH_Qgr_#{suffix}*F_CH")
    fault_program.addLine("Set Y_CH_Q_#{suffix} = 1 + ((q0_CH_#{suffix}+(q1_CH_#{suffix})+(q2_CH_#{suffix})+(q3_CH_#{suffix}))*F_CH)")

    fault_program.addLine("Set p1_CH_#{suffix} = a1_CH_P_#{suffix}")
    fault_program.addLine("Set p2_CH_#{suffix} = a2_CH_P_#{suffix}*#{tin_sensor.name}")
    fault_program.addLine("Set p3_CH_#{suffix} = a3_CH_P_#{suffix}*#{tout_sensor.name}")
    fault_program.addLine("Set p4_CH_#{suffix} = a4_CH_P_#{suffix}*F_CH")
    fault_program.addLine("Set Y_CH_COP_#{suffix} = Y_CH_Q_#{suffix}/(1 + (p1_CH_#{suffix}+(p2_CH_#{suffix})+(p3_CH_#{suffix})+(p4_CH_#{suffix}))*F_CH)")

    # air flow defect and charge defect combined to modify airflow curve output
    ff_ch = 1.0 / (1.0 + (qgr_values[0] + (qgr_values[1] * ff_chg_values[0]) + (qgr_values[2] * ff_chg_values[1]) + (qgr_values[3] * f_chg)) * f_chg)
    fault_program.addLine("Set FF_CH = #{ff_ch.round(3)}")

    for speed in 0..(num_speeds - 1)
      cap_fff_curve = cap_fff_curves[speed]
      cap_fff_act = Model.add_ems_actuator(
        name: "#{obj_name} cap act #{suffix}",
        model_object: cap_fff_curve,
        comp_type_and_control: EPlus::EMSActuatorCurveResult
      )

      eir_pow_fff_curve = eir_pow_fff_curves[speed]
      eir_pow_act = Model.add_ems_actuator(
        name: "#{obj_name} eir pow act #{suffix}",
        model_object: eir_pow_fff_curve,
        comp_type_and_control: EPlus::EMSActuatorCurveResult
      )

      fault_program.addLine("Set FF_AF_#{suffix} = 1.0 + (#{airflow_rated_defect_ratio[speed].round(3)})")
      fault_program.addLine("Set q_AF_CH_#{suffix} = (a1_AF_Qgr_#{suffix}) + ((a2_AF_Qgr_#{suffix})*FF_CH) + ((a3_AF_Qgr_#{suffix})*FF_CH*FF_CH)")
      fault_program.addLine("Set eir_AF_CH_#{suffix} = (a1_AF_EIR_#{suffix}) + ((a2_AF_EIR_#{suffix})*FF_CH) + ((a3_AF_EIR_#{suffix})*FF_CH*FF_CH)")
      fault_program.addLine("Set p_CH_Q_#{suffix} = Y_CH_Q_#{suffix}/q_AF_CH_#{suffix}")
      fault_program.addLine("Set p_CH_COP_#{suffix} = Y_CH_COP_#{suffix}*eir_AF_CH_#{suffix}")
      fault_program.addLine("Set FF_AF_comb_#{suffix} = FF_CH * FF_AF_#{suffix}")
      fault_program.addLine("Set p_AF_Q_#{suffix} = (a1_AF_Qgr_#{suffix}) + ((a2_AF_Qgr_#{suffix})*FF_AF_comb_#{suffix}) + ((a3_AF_Qgr_#{suffix})*FF_AF_comb_#{suffix}*FF_AF_comb_#{suffix})")
      fault_program.addLine("Set p_AF_COP_#{suffix} = 1.0 / ((a1_AF_EIR_#{suffix}) + ((a2_AF_EIR_#{suffix})*FF_AF_comb_#{suffix}) + ((a3_AF_EIR_#{suffix})*FF_AF_comb_#{suffix}*FF_AF_comb_#{suffix}))")
      fault_program.addLine("Set FF_AF_nodef_#{suffix} = FF_AF_#{suffix} / (1 + (#{defect_ratio.round(3)}))")
      fault_program.addLine("Set CAP_Cutler_Curve_Pre_#{suffix} = (a1_AF_Qgr_#{suffix}) + ((a2_AF_Qgr_#{suffix})*FF_AF_nodef_#{suffix}) + ((a3_AF_Qgr_#{suffix})*FF_AF_nodef_#{suffix}*FF_AF_nodef_#{suffix})")
      fault_program.addLine("Set EIR_Cutler_Curve_Pre_#{suffix} = (a1_AF_EIR_#{suffix}) + ((a2_AF_EIR_#{suffix})*FF_AF_nodef_#{suffix}) + ((a3_AF_EIR_#{suffix})*FF_AF_nodef_#{suffix}*FF_AF_nodef_#{suffix})")
      fault_program.addLine("Set CAP_Cutler_Curve_After_#{suffix} = p_CH_Q_#{suffix} * p_AF_Q_#{suffix}")
      fault_program.addLine("Set EIR_Cutler_Curve_After_#{suffix} = (1.0 / (p_CH_COP_#{suffix} * p_AF_COP_#{suffix}))")
      fault_program.addLine("Set CAP_IQ_adj_#{suffix} = CAP_Cutler_Curve_After_#{suffix} / CAP_Cutler_Curve_Pre_#{suffix}")
      fault_program.addLine("Set EIR_IQ_adj_#{suffix} = EIR_Cutler_Curve_After_#{suffix} / EIR_Cutler_Curve_Pre_#{suffix}")
      # NOTE: heat pump (cooling) curves don't exhibit expected trends at extreme faults;
      if (not clg_or_htg_coil.is_a? OpenStudio::Model::CoilCoolingWaterToAirHeatPumpEquationFit) && (not clg_or_htg_coil.is_a? OpenStudio::Model::CoilHeatingWaterToAirHeatPumpEquationFit)
        cap_fff_specs_coeff = (mode == :clg) ? hvac_ap.cool_cap_fflow_spec[speed] : hvac_ap.heat_cap_fflow_spec[speed]
        eir_fff_specs_coeff = (mode == :clg) ? hvac_ap.cool_eir_fflow_spec[speed] : hvac_ap.heat_eir_fflow_spec[speed]
        fault_program.addLine("Set CAP_c1_#{suffix} = #{cap_fff_specs_coeff[0]}")
        fault_program.addLine("Set CAP_c2_#{suffix} = #{cap_fff_specs_coeff[1]}")
        fault_program.addLine("Set CAP_c3_#{suffix} = #{cap_fff_specs_coeff[2]}")
        fault_program.addLine("Set EIR_c1_#{suffix} = #{eir_fff_specs_coeff[0]}")
        fault_program.addLine("Set EIR_c2_#{suffix} = #{eir_fff_specs_coeff[1]}")
        fault_program.addLine("Set EIR_c3_#{suffix} = #{eir_fff_specs_coeff[2]}")
        fault_program.addLine("Set cap_curve_v_pre_#{suffix} = (CAP_c1_#{suffix}) + ((CAP_c2_#{suffix})*FF_AF_nodef_#{suffix}) + ((CAP_c3_#{suffix})*FF_AF_nodef_#{suffix}*FF_AF_nodef_#{suffix})")
        fault_program.addLine("Set eir_curve_v_pre_#{suffix} = (EIR_c1_#{suffix}) + ((EIR_c2_#{suffix})*FF_AF_nodef_#{suffix}) + ((EIR_c3_#{suffix})*FF_AF_nodef_#{suffix}*FF_AF_nodef_#{suffix})")
        fault_program.addLine("Set #{cap_fff_act.name} = cap_curve_v_pre_#{suffix} * CAP_IQ_adj_#{suffix}")
        fault_program.addLine("Set #{eir_pow_act.name} = eir_curve_v_pre_#{suffix} * EIR_IQ_adj_#{suffix}")
      else
        fault_program.addLine("Set CAP_c1_#{suffix} = #{cap_fff_curve.coefficient1Constant}")
        fault_program.addLine("Set CAP_c2_#{suffix} = #{cap_fff_curve.coefficient2w}")
        fault_program.addLine("Set CAP_c3_#{suffix} = #{cap_fff_curve.coefficient3x}")
        fault_program.addLine("Set CAP_c4_#{suffix} = #{cap_fff_curve.coefficient4y}")
        fault_program.addLine("Set CAP_c5_#{suffix} = #{cap_fff_curve.coefficient5z}")
        fault_program.addLine("Set Pow_c1_#{suffix} = #{eir_pow_fff_curve.coefficient1Constant}")
        fault_program.addLine("Set Pow_c2_#{suffix} = #{eir_pow_fff_curve.coefficient2w}")
        fault_program.addLine("Set Pow_c3_#{suffix} = #{eir_pow_fff_curve.coefficient3x}")
        fault_program.addLine("Set Pow_c4_#{suffix} = #{eir_pow_fff_curve.coefficient4y}")
        fault_program.addLine("Set Pow_c5_#{suffix} = #{eir_pow_fff_curve.coefficient5z}")
        fault_program.addLine("Set cap_curve_v_pre_#{suffix} = CAP_c1_#{suffix} + ((CAP_c2_#{suffix})*#{var1_sensor.name}) + (CAP_c3_#{suffix}*#{var2_sensor.name}) + (CAP_c4_#{suffix}*FF_AF_nodef_#{suffix}) + (CAP_c5_#{suffix}*#{var4_sensor.name})")
        fault_program.addLine("Set pow_curve_v_pre_#{suffix} = Pow_c1_#{suffix} + ((Pow_c2_#{suffix})*#{var1_sensor.name}) + (Pow_c3_#{suffix}*#{var2_sensor.name}) + (Pow_c4_#{suffix}*FF_AF_nodef_#{suffix})+ (Pow_c5_#{suffix}*#{var4_sensor.name})")
        fault_program.addLine("Set #{cap_fff_act.name} = cap_curve_v_pre_#{suffix} * CAP_IQ_adj_#{suffix}")
        fault_program.addLine("Set #{eir_pow_act.name} = pow_curve_v_pre_#{suffix} * EIR_IQ_adj_#{suffix} * CAP_IQ_adj_#{suffix}") # equationfit power curve modifies power instead of cop/eir, should also multiply capacity adjustment
      end
      fault_program.addLine("If #{cap_fff_act.name} < 0.0")
      fault_program.addLine("  Set #{cap_fff_act.name} = 1.0")
      fault_program.addLine('EndIf')
      fault_program.addLine("If #{eir_pow_act.name} < 0.0")
      fault_program.addLine("  Set #{eir_pow_act.name} = 1.0")
      fault_program.addLine('EndIf')
    end
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param heating_system [TODO] TODO
  # @param cooling_system [TODO] TODO
  # @param unitary_system [TODO] TODO
  # @param htg_coil [TODO] TODO
  # @param clg_coil [TODO] TODO
  # @param control_zone [OpenStudio::Model::ThermalZone] Conditioned space thermal zone
  # @return [nil]
  def self.apply_installation_quality(model, heating_system, cooling_system, unitary_system, htg_coil, clg_coil, control_zone)
    if not cooling_system.nil?
      charge_defect_ratio = cooling_system.charge_defect_ratio
      cool_airflow_defect_ratio = cooling_system.airflow_defect_ratio
      clg_ap = cooling_system.additional_properties
    end
    if not heating_system.nil?
      heat_airflow_defect_ratio = heating_system.airflow_defect_ratio
      htg_ap = heating_system.additional_properties
    end
    return if (charge_defect_ratio.to_f.abs < 0.001) && (cool_airflow_defect_ratio.to_f.abs < 0.001) && (heat_airflow_defect_ratio.to_f.abs < 0.001)

    cool_airflow_rated_defect_ratio = []
    if (not clg_coil.nil?) && (cooling_system.fraction_cool_load_served > 0)
      clg_ap = cooling_system.additional_properties
      clg_cfm = cooling_system.cooling_airflow_cfm
      if clg_coil.to_CoilCoolingDXSingleSpeed.is_initialized || clg_coil.to_CoilCoolingWaterToAirHeatPumpEquationFit.is_initialized
        cool_airflow_rated_defect_ratio = [UnitConversions.convert(clg_cfm, 'cfm', 'm^3/s') / clg_coil.ratedAirFlowRate.get - 1.0]
      elsif clg_coil.to_CoilCoolingWaterToAirHeatPumpVariableSpeedEquationFit.is_initialized
        cool_airflow_rated_defect_ratio = clg_coil.speeds.zip(clg_ap.cool_fan_speed_ratios).map { |speed, speed_ratio| UnitConversions.convert(clg_cfm * speed_ratio, 'cfm', 'm^3/s') / speed.referenceUnitRatedAirFlowRate - 1.0 }
      elsif clg_coil.to_CoilCoolingDXMultiSpeed.is_initialized
        cool_airflow_rated_defect_ratio = clg_coil.stages.zip(clg_ap.cool_fan_speed_ratios).map { |stage, speed_ratio| UnitConversions.convert(clg_cfm * speed_ratio, 'cfm', 'm^3/s') / stage.ratedAirFlowRate.get - 1.0 }
      end
    end

    heat_airflow_rated_defect_ratio = []
    if (not htg_coil.nil?) && (heating_system.fraction_heat_load_served > 0)
      htg_ap = heating_system.additional_properties
      htg_cfm = heating_system.heating_airflow_cfm
      if htg_coil.to_CoilHeatingDXSingleSpeed.is_initialized || htg_coil.to_CoilHeatingWaterToAirHeatPumpEquationFit.is_initialized
        heat_airflow_rated_defect_ratio = [UnitConversions.convert(htg_cfm, 'cfm', 'm^3/s') / htg_coil.ratedAirFlowRate.get - 1.0]
      elsif htg_coil.to_CoilHeatingWaterToAirHeatPumpVariableSpeedEquationFit.is_initialized
        heat_airflow_rated_defect_ratio = htg_coil.speeds.zip(htg_ap.heat_fan_speed_ratios).map { |speed, speed_ratio| UnitConversions.convert(htg_cfm * speed_ratio, 'cfm', 'm^3/s') / speed.referenceUnitRatedAirFlow - 1.0 }
      elsif htg_coil.to_CoilHeatingDXMultiSpeed.is_initialized
        heat_airflow_rated_defect_ratio = htg_coil.stages.zip(htg_ap.heat_fan_speed_ratios).map { |stage, speed_ratio| UnitConversions.convert(htg_cfm * speed_ratio, 'cfm', 'm^3/s') / stage.ratedAirFlowRate.get - 1.0 }
      end
    end

    return if cool_airflow_rated_defect_ratio.empty? && heat_airflow_rated_defect_ratio.empty?

    obj_name = "#{unitary_system.name} IQ"

    tin_sensor = Model.add_ems_sensor(
      model,
      name: "#{obj_name} tin s",
      output_var_or_meter_name: 'Zone Mean Air Temperature',
      key_name: control_zone.name
    )

    tout_sensor = Model.add_ems_sensor(
      model,
      name: "#{obj_name} tt s",
      output_var_or_meter_name: 'Zone Outdoor Air Drybulb Temperature',
      key_name: control_zone.name
    )

    fault_program = Model.add_ems_program(
      model,
      name: "#{obj_name} program"
    )

    f_chg = charge_defect_ratio.to_f
    fault_program.addLine("Set F_CH = #{f_chg.round(3)}")

    if not cool_airflow_rated_defect_ratio.empty?
      add_installation_quality_program(fault_program, tin_sensor, tout_sensor, cool_airflow_rated_defect_ratio, clg_coil, model, f_chg, obj_name, :clg, cool_airflow_defect_ratio, clg_ap)
    end

    if not heat_airflow_rated_defect_ratio.empty?
      add_installation_quality_program(fault_program, tin_sensor, tout_sensor, heat_airflow_rated_defect_ratio, htg_coil, model, f_chg, obj_name, :htg, heat_airflow_defect_ratio, htg_ap)
    end

    Model.add_ems_program_calling_manager(
      model,
      name: "#{obj_name} program manager",
      calling_point: 'BeginZoneTimestepAfterInitHeatBalance',
      ems_programs: [fault_program]
    )
  end

  # Calculate delivered cooling load and compressor power during defrost when using
  # the advanced defrost model.
  #
  # @param heat_pump [HPXML::HeatPump] HPXML Heat Pump object
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @param design_airflow [Double] Heat pump design air flow rate [cfm]
  # @param max_heating_airflow [Double] Maximum heat pump heating air flow rate [cfm]
  # @param fan_watts_per_cfm [Double] Heat pump watts per cfm [W/cfm]
  # @return [Array<Double, Double>] Calculated delivered cooling q_dot and compressor power p_dot [W]
  def self.calculate_heat_pump_defrost_load_power_watts(heat_pump, unit_multiplier, design_airflow, max_heating_airflow, fan_watts_per_cfm)
    # Calculate q_dot and p_dot
    # q_dot is used for EMS program to account for introduced cooling load and supp coil power consumption by actuating other equipment objects
    # p_dot is used for calculating coil defrost compressor power consumption
    is_ducted = !heat_pump.distribution_system_idref.nil?
    # determine defrost cooling rate and defrost cooling cop based on whether ducted
    if is_ducted
      # 0.45 is from Jon's lab and field data analysis, defrost is too short to reach steady state so using cutler curve is not correct
      # 1.0 is from Jon's lab and field data analysis, defrost is too short to reach steady state so using cutler curve is not correct
      # Transient effect already accounted
      capacity_defrost_multiplier = 0.45
      cop_defrost_multiplier = 1.0
    else
      capacity_defrost_multiplier = 0.1
      cop_defrost_multiplier = 0.08
    end
    # cooling capacity and airflow are already with unit multiplier, calculate the capacity w/o multiplier
    nominal_cooling_capacity = heat_pump.cooling_capacity / unit_multiplier
    defrost_power_fraction = (max_heating_airflow / design_airflow)**3
    power_design = fan_watts_per_cfm * design_airflow / unit_multiplier
    p_dot_blower = power_design * defrost_power_fraction
    # Based on manufacturer data for ~70 systems ranging from 1.5 to 5 tons with varying efficiency levels
    if nominal_cooling_capacity > 18000.0 # > 1.5 tons
      p_dot_odu_fan = 44.348 * UnitConversions.convert(nominal_cooling_capacity, 'Btu/hr', 'ton') + 62.452
    else # < 1.5 tons, scale fan power to avoid negative p_dot_defrost
      # Use p_dot_odu_fan at 1.5 ton to scale down
      p_dot_odu_fan = 128.974 * (nominal_cooling_capacity / 18000.0)
    end
    q_dot_defrost = UnitConversions.convert(nominal_cooling_capacity, 'Btu/hr', 'W') * capacity_defrost_multiplier
    cop_defrost = heat_pump.additional_properties.cool_rated_cops[-1] * cop_defrost_multiplier
    p_dot_defrost = (q_dot_defrost / cop_defrost - p_dot_odu_fan + p_dot_blower) * unit_multiplier # p_dot_defrost is used in coil object, which needs to be scaled up for unit multiplier

    return q_dot_defrost, p_dot_defrost
  end

  # Create EMS program and Other equipment objects to account for delivered cooling load and supplemental heating energy during defrost
  # when using the advanced defrost model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param htg_coil [OpenStudio::Model::CoilHeatingDXSingleSpeed or OpenStudio::Model::CoilHeatingDXMultiSpeed]  OpenStudio Heating Coil object
  # @param air_loop_unitary [OpenStudio::Model::AirLoopHVACUnitarySystem] Air loop for the HVAC system
  # @param conditioned_space [OpenStudio::Model::Space]  OpenStudio Space object for conditioned zone
  # @param htg_supp_coil [OpenStudio::Model::CoilHeatingElectric or CoilHeatingElectricMultiStage] OpenStudio Supplemental Heating Coil object
  # @param heat_pump [HPXML::HeatPump] HPXML Heat Pump object
  # @param q_dot_defrost [Double] Calculated delivered cooling q_dot [W]
  # @return [nil]
  def self.apply_advanced_defrost(model, htg_coil, air_loop_unitary, conditioned_space, htg_supp_coil, heat_pump, q_dot_defrost)
    if htg_supp_coil.nil?
      backup_system = heat_pump.backup_system
      if backup_system.nil?
        supp_sys_capacity = 0.0
        supp_sys_power_level = 0.0
        supp_sys_fuel = HPXML::FuelTypeElectricity
      else
        supp_sys_fuel = backup_system.heating_system_fuel
        supp_sys_capacity = UnitConversions.convert(backup_system.heating_capacity, 'Btu/hr', 'W')
        supp_sys_efficiency = backup_system.heating_efficiency_percent
        supp_sys_efficiency = backup_system.heating_efficiency_afue if supp_sys_efficiency.nil?
        supp_sys_power_level = [supp_sys_capacity, q_dot_defrost].min / supp_sys_efficiency # Assume perfect tempering
      end
    else
      supp_sys_fuel = heat_pump.backup_heating_fuel
      is_ducted = !heat_pump.distribution_system_idref.nil?
      if is_ducted
        supp_sys_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')
        supp_sys_efficiency = heat_pump.backup_heating_efficiency_percent
        supp_sys_efficiency = heat_pump.backup_heating_efficiency_afue if supp_sys_efficiency.nil?
        supp_sys_power_level = [supp_sys_capacity, q_dot_defrost].min / supp_sys_efficiency # Assume perfect tempering
      else
        # Practically no integrated supplemental system for ductless
        # Sometimes integrated backup systems are added to ductless to avoid unmet loads, so it shouldn't count here to avoid overestimating backup system energy use
        supp_sys_capacity = 0.0
        supp_sys_power_level = 0.0
      end
    end
    # other equipment actuator

    defrost_heat_load_oe = Model.add_other_equipment(
      model,
      name: "#{air_loop_unitary.name} defrost heat load",
      end_use: nil,
      space: conditioned_space,
      design_level: 0,
      frac_radiant: 0,
      frac_latent: 0,
      frac_lost: 0,
      schedule: model.alwaysOnDiscreteSchedule,
      fuel_type: nil
    )
    defrost_heat_load_oe_act = Model.add_ems_actuator(
      name: "#{defrost_heat_load_oe.name} act",
      model_object: defrost_heat_load_oe,
      comp_type_and_control: EPlus::EMSActuatorOtherEquipmentPower
    )

    defrost_supp_heat_energy_oe = Model.add_other_equipment(
      model,
      name: "#{air_loop_unitary.name} defrost supp heat energy",
      end_use: Constants::ObjectTypeBackupSuppHeat,
      space: conditioned_space,
      design_level: 0,
      frac_radiant: 0,
      frac_latent: 0,
      frac_lost: 1,
      schedule: model.alwaysOnDiscreteSchedule,
      fuel_type: supp_sys_fuel
    )
    defrost_supp_heat_energy_oe.additionalProperties.setFeature('HPXML_ID', heat_pump.id) # Used by reporting measure
    defrost_supp_heat_energy_oe.additionalProperties.setFeature('IsHeatPumpBackup', true) # Used by reporting measure

    defrost_supp_heat_energy_oe_act = Model.add_ems_actuator(
      name: "#{defrost_supp_heat_energy_oe.name} act",
      model_object: defrost_supp_heat_energy_oe,
      comp_type_and_control: EPlus::EMSActuatorOtherEquipmentPower
    )

    # Sensors
    tout_db_sensor = Model.add_ems_sensor(
      model,
      name: "#{air_loop_unitary.name} tout s",
      output_var_or_meter_name: 'Site Outdoor Air Drybulb Temperature',
      key_name: 'Environment'
    )

    htg_coil_rtf_sensor = Model.add_ems_sensor(
      model,
      name: "#{htg_coil.name} rtf s",
      output_var_or_meter_name: 'Heating Coil Runtime Fraction',
      key_name: htg_coil.name
    )

    # EMS program
    max_oat_defrost = htg_coil.maximumOutdoorDryBulbTemperatureforDefrostOperation
    program = Model.add_ems_program(
      model,
      name: "#{air_loop_unitary.name} defrost program"
    )
    program.addLine("If #{tout_db_sensor.name} <= #{max_oat_defrost}")
    program.addLine("  Set hp_defrost_time_fraction = #{htg_coil.defrostTimePeriodFraction}")
    program.addLine("  Set supp_design_level = #{supp_sys_power_level}")
    program.addLine("  Set q_dot_defrost = #{q_dot_defrost}")
    program.addLine("  Set supp_delivered_htg = #{[supp_sys_capacity, q_dot_defrost].min}")
    program.addLine('  Set defrost_load_design_level = supp_delivered_htg - q_dot_defrost')
    program.addLine("  Set fraction_defrost = hp_defrost_time_fraction * #{htg_coil_rtf_sensor.name}")
    program.addLine("  Set #{defrost_heat_load_oe_act.name} = fraction_defrost * defrost_load_design_level")
    program.addLine("  Set #{defrost_supp_heat_energy_oe_act.name} = fraction_defrost * supp_design_level")
    program.addLine('Else')
    program.addLine("  Set #{defrost_heat_load_oe_act.name} = 0")
    program.addLine("  Set #{defrost_supp_heat_energy_oe_act.name} = 0")
    program.addLine('EndIf')

    Model.add_ems_program_calling_manager(
      model,
      name: "#{program.name} calling manager",
      calling_point: 'InsideHVACSystemIterationLoop',
      ems_programs: [program]
    )
  end

  # TODO
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_shared_systems(hpxml_bldg)
    applied_clg = apply_shared_cooling_systems(hpxml_bldg)
    applied_htg = apply_shared_heating_systems(hpxml_bldg)
    return unless (applied_clg || applied_htg)

    # Remove WLHP if not serving heating nor cooling
    hpxml_bldg.heat_pumps.each do |hp|
      next unless hp.heat_pump_type == HPXML::HVACTypeHeatPumpWaterLoopToAir
      next if hp.fraction_heat_load_served > 0
      next if hp.fraction_cool_load_served > 0

      hp.delete
    end

    # Remove any orphaned HVAC distributions
    hpxml_bldg.hvac_distributions.each do |hvac_distribution|
      hvac_systems = []
      hpxml_bldg.hvac_systems.each do |hvac_system|
        next if hvac_system.distribution_system_idref.nil?
        next unless hvac_system.distribution_system_idref == hvac_distribution.id

        hvac_systems << hvac_system
      end
      next unless hvac_systems.empty?

      hvac_distribution.delete
    end
  end

  # TODO
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [TODO] TODO
  def self.apply_shared_cooling_systems(hpxml_bldg)
    applied = false
    hpxml_bldg.cooling_systems.each do |cooling_system|
      next unless cooling_system.is_shared_system

      applied = true
      wlhp = nil
      distribution_system = cooling_system.distribution_system
      distribution_type = distribution_system.distribution_system_type

      # Calculate air conditioner SEER equivalent
      n_dweq = cooling_system.number_of_units_served.to_f
      aux = cooling_system.shared_loop_watts

      if cooling_system.cooling_system_type == HPXML::HVACTypeChiller

        # Chiller w/ baseboard or fan coil or water loop heat pump
        cap = cooling_system.cooling_capacity
        chiller_input = UnitConversions.convert(cooling_system.cooling_efficiency_kw_per_ton * UnitConversions.convert(cap, 'Btu/hr', 'ton'), 'kW', 'W')
        if distribution_type == HPXML::HVACDistributionTypeHydronic
          if distribution_system.hydronic_type == HPXML::HydronicTypeWaterLoop
            wlhp = hpxml_bldg.heat_pumps.find { |hp| hp.heat_pump_type == HPXML::HVACTypeHeatPumpWaterLoopToAir }
            aux_dweq = wlhp.cooling_capacity / wlhp.cooling_efficiency_eer
          else
            aux_dweq = 0.0
          end
        elsif distribution_type == HPXML::HVACDistributionTypeAir
          if distribution_system.air_type == HPXML::AirTypeFanCoil
            aux_dweq = cooling_system.fan_coil_watts
          end
        end
        # ANSI/RESNET/ICC 301-2022 Equation 4.4-2
        seer_eq = (cap - 3.41 * aux - 3.41 * aux_dweq * n_dweq) / (chiller_input + aux + aux_dweq * n_dweq)

      elsif cooling_system.cooling_system_type == HPXML::HVACTypeCoolingTower

        # Cooling tower w/ water loop heat pump
        if distribution_type == HPXML::HVACDistributionTypeHydronic
          if distribution_system.hydronic_type == HPXML::HydronicTypeWaterLoop
            wlhp = hpxml_bldg.heat_pumps.find { |hp| hp.heat_pump_type == HPXML::HVACTypeHeatPumpWaterLoopToAir }
            wlhp_cap = wlhp.cooling_capacity
            wlhp_input = wlhp_cap / wlhp.cooling_efficiency_eer
          end
        end
        # ANSI/RESNET/ICC 301-2022 Equation 4.4-3
        seer_eq = (wlhp_cap - 3.41 * aux / n_dweq) / (wlhp_input + aux / n_dweq)

      else
        fail "Unexpected cooling system type '#{cooling_system.cooling_system_type}'."
      end

      if seer_eq <= 0
        fail "Negative SEER equivalent calculated for cooling system '#{cooling_system.id}', double-check inputs."
      end

      cooling_system.cooling_system_type = HPXML::HVACTypeCentralAirConditioner
      cooling_system.cooling_efficiency_seer = seer_eq.round(2)
      cooling_system.cooling_efficiency_kw_per_ton = nil
      cooling_system.cooling_capacity = nil # Autosize the equipment
      cooling_system.compressor_type = HPXML::HVACCompressorTypeSingleStage
      cooling_system.is_shared_system = false
      cooling_system.number_of_units_served = nil
      cooling_system.shared_loop_watts = nil
      cooling_system.shared_loop_motor_efficiency = nil
      cooling_system.fan_coil_watts = nil

      # Assign new distribution system to air conditioner
      if distribution_type == HPXML::HVACDistributionTypeHydronic
        if distribution_system.hydronic_type == HPXML::HydronicTypeWaterLoop
          # Assign WLHP air distribution
          cooling_system.distribution_system_idref = wlhp.distribution_system_idref
          wlhp.fraction_cool_load_served = 0.0
          wlhp.fraction_heat_load_served = 0.0
        else
          # Assign DSE=1
          hpxml_bldg.hvac_distributions.add(id: "#{cooling_system.id}AirDistributionSystem",
                                            distribution_system_type: HPXML::HVACDistributionTypeDSE,
                                            annual_cooling_dse: 1.0,
                                            annual_heating_dse: 1.0)
          cooling_system.distribution_system_idref = hpxml_bldg.hvac_distributions[-1].id
        end
      elsif (distribution_type == HPXML::HVACDistributionTypeAir) && (distribution_system.air_type == HPXML::AirTypeFanCoil)
        # Convert "fan coil" air distribution system to "regular velocity"
        if distribution_system.hvac_systems.size > 1
          # Has attached heating system, so create a copy specifically for the cooling system
          hpxml_bldg.hvac_distributions.add(id: "#{distribution_system.id}_#{cooling_system.id}",
                                            distribution_system_type: distribution_system.distribution_system_type,
                                            air_type: distribution_system.air_type,
                                            number_of_return_registers: distribution_system.number_of_return_registers,
                                            conditioned_floor_area_served: distribution_system.conditioned_floor_area_served)
          distribution_system.duct_leakage_measurements.each do |lm|
            hpxml_bldg.hvac_distributions[-1].duct_leakage_measurements << lm.dup
          end
          distribution_system.ducts.each do |d|
            hpxml_bldg.hvac_distributions[-1].ducts << d.dup
          end
          cooling_system.distribution_system_idref = hpxml_bldg.hvac_distributions[-1].id
        end
        hpxml_bldg.hvac_distributions[-1].air_type = HPXML::AirTypeRegularVelocity
        if hpxml_bldg.hvac_distributions[-1].duct_leakage_measurements.count { |lm| (lm.duct_type == HPXML::DuctTypeSupply) && (lm.duct_leakage_total_or_to_outside == HPXML::DuctLeakageToOutside) } == 0
          # Assign zero supply leakage
          hpxml_bldg.hvac_distributions[-1].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeSupply,
                                                                          duct_leakage_units: HPXML::UnitsCFM25,
                                                                          duct_leakage_value: 0,
                                                                          duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
        end
        if hpxml_bldg.hvac_distributions[-1].duct_leakage_measurements.count { |lm| (lm.duct_type == HPXML::DuctTypeReturn) && (lm.duct_leakage_total_or_to_outside == HPXML::DuctLeakageToOutside) } == 0
          # Assign zero return leakage
          hpxml_bldg.hvac_distributions[-1].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                                          duct_leakage_units: HPXML::UnitsCFM25,
                                                                          duct_leakage_value: 0,
                                                                          duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
        end
        hpxml_bldg.hvac_distributions[-1].ducts.each do |d|
          d.id = "#{d.id}_#{cooling_system.id}"
        end
      end
    end

    return applied
  end

  # TODO
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [TODO] TODO
  def self.apply_shared_heating_systems(hpxml_bldg)
    applied = false
    hpxml_bldg.heating_systems.each do |heating_system|
      next unless heating_system.is_shared_system

      applied = true
      distribution_system = heating_system.distribution_system
      hydronic_type = distribution_system.hydronic_type

      if heating_system.heating_system_type == HPXML::HVACTypeBoiler && hydronic_type.to_s == HPXML::HydronicTypeWaterLoop

        # Shared boiler w/ water loop heat pump
        # Per ANSI/RESNET/ICC 301-2022 Section 4.4.7.2, model as:
        # A) heat pump with constant efficiency and duct losses, fraction heat load served = 1/COP
        # B) boiler, fraction heat load served = 1-1/COP
        fraction_heat_load_served = heating_system.fraction_heat_load_served

        # Heat pump
        # If this approach is ever removed, also remove code in HVACSizing.apply_hvac_loads()
        wlhp = hpxml_bldg.heat_pumps.find { |hp| hp.heat_pump_type == HPXML::HVACTypeHeatPumpWaterLoopToAir }
        wlhp.fraction_heat_load_served = fraction_heat_load_served * (1.0 / wlhp.heating_efficiency_cop)
        wlhp.fraction_cool_load_served = 0.0

        # Boiler
        heating_system.fraction_heat_load_served = fraction_heat_load_served * (1.0 - 1.0 / wlhp.heating_efficiency_cop)
      end

      heating_system.heating_capacity = nil # Autosize the equipment
    end

    return applied
  end

  # TODO
  #
  # @param capacity [TODO] TODO
  # @param rated_cfm_per_ton [TODO] TODO
  # @return [TODO] TODO
  def self.calc_rated_airflow(capacity, rated_cfm_per_ton)
    return UnitConversions.convert(capacity, 'Btu/hr', 'ton') * UnitConversions.convert(rated_cfm_per_ton, 'cfm', 'm^3/s')
  end

  # TODO
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param heating_system [TODO] TODO
  # @param cooling_system [TODO] TODO
  # @return [TODO] TODO
  def self.is_attached_heating_and_cooling_systems(hpxml_bldg, heating_system, cooling_system)
    # Now only allows furnace+AC
    if not ((hpxml_bldg.heating_systems.include? heating_system) && (hpxml_bldg.cooling_systems.include? cooling_system))
      return false
    end
    if not (heating_system.heating_system_type == HPXML::HVACTypeFurnace && cooling_system.cooling_system_type == HPXML::HVACTypeCentralAirConditioner)
      return false
    end

    return true
  end

  # Returns a list of HPXML HVAC (heating/cooling) systems, incorporating whether multiple systems are
  # connected to the same distribution system (e.g., a furnace + central air conditioner w/ the same ducts).
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [Array<Hash>] List of HPXML HVAC (heating and/or cooling) systems
  def self.get_hpxml_hvac_systems(hpxml_bldg)
    hvac_systems = []

    hpxml_bldg.cooling_systems.each do |cooling_system|
      heating_system = nil
      if is_attached_heating_and_cooling_systems(hpxml_bldg, cooling_system.attached_heating_system, cooling_system)
        heating_system = cooling_system.attached_heating_system
      end
      hvac_systems << { cooling: cooling_system,
                        heating: heating_system }
    end

    hpxml_bldg.heating_systems.each do |heating_system|
      next if heating_system.is_heat_pump_backup_system # Will be processed later
      if is_attached_heating_and_cooling_systems(hpxml_bldg, heating_system, heating_system.attached_cooling_system)
        next # Already processed with cooling
      end

      hvac_systems << { cooling: nil,
                        heating: heating_system }
    end

    # Heat pump with backup system must be sorted last so that the last two
    # HVAC systems in the EnergyPlus EquipmentList are 1) the heat pump and
    # 2) the heat pump backup system.
    hpxml_bldg.heat_pumps.sort_by { |hp| hp.backup_system_idref.to_s }.each do |heat_pump|
      hvac_systems << { cooling: heat_pump,
                        heating: heat_pump }
    end

    hpxml_bldg.heating_systems.each do |heating_system|
      next unless heating_system.is_heat_pump_backup_system

      hvac_systems << { cooling: nil,
                        heating: heating_system }
    end

    return hvac_systems
  end

  # Ensure that no capacities/airflows are zero in order to prevent potential E+ errors.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.ensure_nonzero_sizing_values(hpxml_bldg)
    min_capacity = 1.0 # Btuh
    min_airflow = 3.0 # cfm; E+ min airflow is 0.001 m3/s
    hpxml_bldg.heating_systems.each do |htg_sys|
      htg_sys.heating_capacity = [htg_sys.heating_capacity, min_capacity].max
      htg_sys.heating_airflow_cfm = [htg_sys.heating_airflow_cfm, min_airflow].max unless htg_sys.heating_airflow_cfm.nil?
    end
    hpxml_bldg.cooling_systems.each do |clg_sys|
      clg_sys.cooling_capacity = [clg_sys.cooling_capacity, min_capacity].max
      clg_sys.cooling_airflow_cfm = [clg_sys.cooling_airflow_cfm, min_airflow].max
      next unless not clg_sys.cooling_detailed_performance_data.empty?

      clg_sys.cooling_detailed_performance_data.each do |dp|
        speed = dp.capacity_description == HPXML::CapacityDescriptionMinimum ? 1 : 2
        dp.capacity = [dp.capacity, min_capacity * speed].max
      end
    end
    hpxml_bldg.heat_pumps.each do |hp_sys|
      hp_sys.cooling_capacity = [hp_sys.cooling_capacity, min_capacity].max
      hp_sys.cooling_airflow_cfm = [hp_sys.cooling_airflow_cfm, min_airflow].max
      hp_sys.additional_properties.cooling_capacity_sensible = [hp_sys.additional_properties.cooling_capacity_sensible, min_capacity].max
      hp_sys.heating_capacity = [hp_sys.heating_capacity, min_capacity].max
      hp_sys.heating_airflow_cfm = [hp_sys.heating_airflow_cfm, min_airflow].max
      hp_sys.heating_capacity_17F = [hp_sys.heating_capacity_17F, min_capacity].max unless hp_sys.heating_capacity_17F.nil?
      hp_sys.backup_heating_capacity = [hp_sys.backup_heating_capacity, min_capacity].max unless hp_sys.backup_heating_capacity.nil?
      if not hp_sys.heating_detailed_performance_data.empty?
        hp_sys.heating_detailed_performance_data.each do |dp|
          next if dp.capacity.nil?

          speed = dp.capacity_description == HPXML::CapacityDescriptionMinimum ? 1 : 2
          dp.capacity = [dp.capacity, min_capacity * speed].max
        end
      end
      next if hp_sys.cooling_detailed_performance_data.empty?

      hp_sys.cooling_detailed_performance_data.each do |dp|
        next if dp.capacity.nil?

        speed = dp.capacity_description == HPXML::CapacityDescriptionMinimum ? 1 : 2
        dp.capacity = [dp.capacity, min_capacity * speed].max
      end
    end
  end

  # Apply unit multiplier (E+ thermal zone multiplier) to HVAC systems; E+ sends the
  # multiplied thermal zone load to the HVAC system, so the HVAC system needs to be
  # sized to meet the entire multiplied zone load.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [nil]
  def self.apply_unit_multiplier(hpxml_bldg, hpxml_header)
    unit_multiplier = hpxml_bldg.building_construction.number_of_units
    hpxml_bldg.heating_systems.each do |htg_sys|
      htg_sys.heating_capacity *= unit_multiplier
      htg_sys.heating_airflow_cfm *= unit_multiplier unless htg_sys.heating_airflow_cfm.nil?
      htg_sys.pilot_light_btuh *= unit_multiplier unless htg_sys.pilot_light_btuh.nil?
      htg_sys.electric_auxiliary_energy *= unit_multiplier unless htg_sys.electric_auxiliary_energy.nil?
      htg_sys.fan_watts *= unit_multiplier unless htg_sys.fan_watts.nil?
      htg_sys.heating_detailed_performance_data.each do |dp|
        dp.capacity *= unit_multiplier unless dp.capacity.nil?
      end
    end
    hpxml_bldg.cooling_systems.each do |clg_sys|
      clg_sys.cooling_capacity *= unit_multiplier
      clg_sys.cooling_airflow_cfm *= unit_multiplier
      clg_sys.crankcase_heater_watts *= unit_multiplier unless clg_sys.crankcase_heater_watts.nil?
      clg_sys.integrated_heating_system_capacity *= unit_multiplier unless clg_sys.integrated_heating_system_capacity.nil?
      clg_sys.integrated_heating_system_airflow_cfm *= unit_multiplier unless clg_sys.integrated_heating_system_airflow_cfm.nil?
      clg_sys.cooling_detailed_performance_data.each do |dp|
        dp.capacity *= unit_multiplier unless dp.capacity.nil?
      end
    end
    hpxml_bldg.heat_pumps.each do |hp_sys|
      hp_sys.cooling_capacity *= unit_multiplier
      hp_sys.cooling_airflow_cfm *= unit_multiplier
      hp_sys.additional_properties.cooling_capacity_sensible *= unit_multiplier
      hp_sys.heating_capacity *= unit_multiplier
      hp_sys.heating_airflow_cfm *= unit_multiplier
      hp_sys.heating_capacity_17F *= unit_multiplier unless hp_sys.heating_capacity_17F.nil?
      hp_sys.backup_heating_capacity *= unit_multiplier unless hp_sys.backup_heating_capacity.nil?
      hp_sys.crankcase_heater_watts *= unit_multiplier unless hp_sys.crankcase_heater_watts.nil?
      hpxml_header.heat_pump_backup_heating_capacity_increment *= unit_multiplier unless hpxml_header.heat_pump_backup_heating_capacity_increment.nil?
      hp_sys.heating_detailed_performance_data.each do |dp|
        dp.capacity *= unit_multiplier unless dp.capacity.nil?
      end
      hp_sys.cooling_detailed_performance_data.each do |dp|
        dp.capacity *= unit_multiplier unless dp.capacity.nil?
      end
    end
  end

  # Calculates rated SEER (older metric) from rated SEER2 (newer metric).
  #
  # Source: ANSI/RESNET/ICC 301 Table 4.4.4.1(1) SEER2/HSPF2 Conversion Factors
  # Note that this is a regression based on products on the market, not a conversion.
  #
  # @param seer2 [Double] Cooling efficiency (Btu/Wh)
  # @param is_ducted [Boolean] True if a ducted HVAC system
  # @return [Double] SEER value (Btu/Wh)
  def self.calc_seer_from_seer2(seer2, is_ducted)
    # Note: There are less common system types (packaged, small duct high velocity,
    # and space-constrained) that we don't handle here.
    if is_ducted # Ducted split system
      return seer2 / 0.95
    else # Ductless systems
      return seer2 / 1.00
    end
  end

  # Calculates rated HSPF (older metric) from rated HSPF2 (newer metric).
  #
  # Source: ANSI/RESNET/ICC 301 Table 4.4.4.1(1) SEER2/HSPF2 Conversion Factors
  # This is based on a regression of products, not a translation.
  #
  # @param hspf2 [Double] Heating efficiency (Btu/Wh)
  # @param is_ducted [Boolean] True if a ducted HVAC system
  # @return [Double] HSPF value (Btu/Wh)
  def self.calc_hspf_from_hspf2(hspf2, is_ducted)
    # Note: There are less common system types (packaged, small duct high velocity,
    # and space-constrained) that we don't handle here.
    if is_ducted # Ducted split system
      return hspf2 / 0.85
    else # Ductless system
      return hspf2 / 0.90
    end
  end

  # Check provided HVAC system and distribution types against what is allowed.
  #
  # @param hvac_distribution [HPXML::HVACDistribution] HPXML HVAC Distribution object
  # @param system_type [String] the HVAC system type of interest
  # @return [nil]
  def self.check_distribution_system(hvac_distribution, system_type)
    return if hvac_distribution.nil?

    hvac_distribution_type_map = {
      HPXML::HVACTypeFurnace => [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE],
      HPXML::HVACTypeBoiler => [HPXML::HVACDistributionTypeHydronic, HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE],
      HPXML::HVACTypeCentralAirConditioner => [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE],
      HPXML::HVACTypeEvaporativeCooler => [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE],
      HPXML::HVACTypeMiniSplitAirConditioner => [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE],
      HPXML::HVACTypeRoomAirConditioner => [HPXML::HVACDistributionTypeDSE],
      HPXML::HVACTypePTAC => [HPXML::HVACDistributionTypeDSE],
      HPXML::HVACTypeHeatPumpAirToAir => [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE],
      HPXML::HVACTypeHeatPumpMiniSplit => [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE],
      HPXML::HVACTypeHeatPumpGroundToAir => [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE],
      HPXML::HVACTypeHeatPumpWaterLoopToAir => [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE],
      HPXML::HVACTypeHeatPumpPTHP => [HPXML::HVACDistributionTypeDSE],
      HPXML::HVACTypeHeatPumpRoom => [HPXML::HVACDistributionTypeDSE],
    }

    if not hvac_distribution_type_map[system_type].include? hvac_distribution.distribution_system_type
      fail "Incorrect HVAC distribution system type for HVAC type: '#{system_type}'. Should be one of: #{hvac_distribution_type_map[system_type]}"
    end

    # Also check that DSE=1 if PTAC/PTHP/RoomAC/RoomHP, since it is only used to attach a CFIS system
    if [HPXML::HVACTypePTAC, HPXML::HVACTypeHeatPumpPTHP, HPXML::HVACTypeRoomAirConditioner, HPXML::HVACTypeHeatPumpRoom].include? system_type
      if ((not hvac_distribution.annual_cooling_dse.nil?) && (hvac_distribution.annual_cooling_dse != 1)) ||
         ((not hvac_distribution.annual_heating_dse.nil?) && (hvac_distribution.annual_heating_dse != 1))
        fail "HVAC type '#{system_type}' must have a heating and/or cooling DSE of 1."
      end
    end
  end
end
