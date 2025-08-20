# frozen_string_literal: true

$weather_lookup_cache = {}

# Collection of methods related to defaulting optional inputs in the HPXML
# that were not provided.
#
# Note: Each HPXML object (e.g., HPXML::Wall) has an additional_properties
# child object that can be used to store custom information on the object without
# being written to the HPXML file. This allows the custom information to
# be used by downstream calculations/logic.
module Defaults
  # Assigns default values to the HPXML Building object for optional HPXML inputs
  # that are not provided.
  #
  # When a default value is assigned to an HPXML object property (like wall.azimuth),
  # the corresponding foo_isdefaulted (e.g., wall.azimuth_isdefaulted) should be set
  # to true so that the in.xml that is exported includes 'dataSource="software"'
  # attributes for all defaulted values. This allows the user to easily observe which
  # values were defaulted and what default values were used.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param hpxml [HPXML] HPXML object
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param convert_shared_systems [Boolean] Whether to convert shared systems to equivalent in-unit systems per ANSI/RESNET/ICC 301
  # @return [Array<Hash, Hash>] Maps of HPXML::Zones => DesignLoadValues object, HPXML::Spaces => DesignLoadValues object
  def self.apply(runner, hpxml, hpxml_bldg, weather, schedules_file: nil, convert_shared_systems: true)
    if hpxml.header.eri_calculation_versions.nil? || hpxml.header.eri_calculation_versions.empty?
      eri_version = 'latest'
    else
      eri_version = hpxml.header.eri_calculation_versions[0]
    end

    if hpxml.buildings.size > 1
      # This is helpful if we need to make unique HPXML IDs across dwelling units
      unit_num = hpxml.buildings.index(hpxml_bldg) + 1
    end

    # Check for presence of fuels once
    has_fuel = hpxml_bldg.has_fuels()

    add_zones_spaces_if_needed(hpxml_bldg, unit_num)

    @default_schedules_csv_data = get_schedules_csv_data()

    apply_header(hpxml.header, hpxml_bldg, weather)
    apply_building(hpxml_bldg, weather)
    apply_emissions_scenarios(hpxml.header, has_fuel)
    apply_utility_bill_scenarios(runner, hpxml.header, hpxml_bldg, has_fuel)
    apply_building_header(hpxml.header, hpxml_bldg, weather)
    apply_site(hpxml_bldg)
    apply_building_header_sizing(runner, hpxml_bldg, weather)
    apply_neighbor_buildings(hpxml_bldg)
    apply_building_occupancy(hpxml_bldg, schedules_file)
    apply_building_construction(hpxml.header, hpxml_bldg)
    apply_zone_spaces(hpxml_bldg)
    apply_climate_and_risk_zones(hpxml_bldg, weather, unit_num)
    apply_attics(hpxml_bldg)
    apply_foundations(hpxml_bldg)
    apply_roofs(hpxml_bldg)
    apply_rim_joists(hpxml_bldg)
    apply_walls(hpxml_bldg)
    apply_foundation_walls(hpxml_bldg)
    apply_floors(runner, hpxml_bldg)
    apply_slabs(hpxml_bldg)
    apply_windows(hpxml_bldg, eri_version)
    apply_skylights(hpxml_bldg)
    apply_doors(hpxml_bldg)
    apply_partition_wall_mass(hpxml_bldg)
    apply_furniture_mass(hpxml_bldg)
    apply_hvac(runner, hpxml_bldg, weather, convert_shared_systems, unit_num, hpxml.header)
    apply_hvac_control(hpxml_bldg, schedules_file, eri_version)
    apply_hvac_distribution(hpxml_bldg)
    apply_infiltration(hpxml_bldg)
    apply_hvac_location(hpxml_bldg)
    apply_ventilation_fans(hpxml_bldg, weather, eri_version)
    apply_water_heaters(hpxml_bldg, eri_version, schedules_file)
    apply_flue_or_chimney(hpxml_bldg)
    apply_hot_water_distribution(hpxml_bldg, schedules_file)
    apply_water_fixtures(hpxml_bldg, schedules_file)
    apply_solar_thermal_systems(hpxml_bldg)
    apply_appliances(hpxml_bldg, eri_version, schedules_file)
    apply_lighting(hpxml_bldg, schedules_file)
    apply_ceiling_fans(hpxml_bldg, weather, schedules_file)
    apply_pools_and_permanent_spas(hpxml_bldg, schedules_file)
    apply_plug_loads(hpxml_bldg, schedules_file)
    apply_fuel_loads(hpxml_bldg, schedules_file)
    apply_pv_systems(hpxml_bldg, unit_num)
    apply_generators(hpxml_bldg)
    apply_batteries(hpxml_bldg)
    apply_vehicles(hpxml_bldg, schedules_file)

    # Do HVAC sizing after all other defaults have been applied
    all_zone_loads, all_space_loads = apply_hvac_sizing(runner, hpxml_bldg, weather, hpxml.header)

    # These need to be applied after sizing HVAC capacities/airflows
    apply_detailed_performance_data(hpxml_bldg)
    apply_cfis_fan_power(hpxml_bldg)
    apply_crankcase_heating(hpxml_bldg)

    # Default electric panels has to be after sizing to have autosized capacity information
    apply_electric_panels(runner, hpxml.header, hpxml_bldg, unit_num)

    cleanup_zones_spaces(hpxml_bldg)

    return all_zone_loads, all_space_loads
  end

  # Returns a list of four azimuths (facing each direction). Determined based
  # on the primary azimuth, as defined by the azimuth with the largest surface
  # area, plus azimuths that are offset by 90/180/270 degrees. Used for
  # surfaces that may not have an azimuth defined (e.g., walls).
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [Array<Double>] Azimuths for the four sides of the home
  def self.get_azimuths(hpxml_bldg)
    # Ensures 0 <= azimuth < 360
    #
    # @param azimuth [Double] Azimuth to unspin
    # @return [Double] Resulting azimuth
    def self.unspin_azimuth(azimuth)
      while azimuth < 0
        azimuth += 360
      end
      while azimuth >= 360
        azimuth -= 360
      end
      return azimuth
    end

    azimuth_areas = {}
    (hpxml_bldg.surfaces + hpxml_bldg.subsurfaces).each do |surface|
      next unless surface.respond_to?(:azimuth)

      az = surface.azimuth
      next if az.nil?

      azimuth_areas[az] = 0 if azimuth_areas[az].nil?
      azimuth_areas[az] += surface.area
    end
    if azimuth_areas.empty?
      primary_azimuth = 0
    else
      primary_azimuth = azimuth_areas.max_by { |_k, v| v }[0]
    end
    return [primary_azimuth,
            unspin_azimuth(primary_azimuth + 90),
            unspin_azimuth(primary_azimuth + 180),
            unspin_azimuth(primary_azimuth + 270)].sort
  end

  # Automatically adds a single conditioned zone/space to the HPXML Building if not provided.
  # Simplifies the HVAC autosizing code so that it can operate on zones/spaces whether the HPXML
  # file includes them or not.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param unit_num [Integer] Dwelling unit number
  # @return [nil]
  def self.add_zones_spaces_if_needed(hpxml_bldg, unit_num)
    if hpxml_bldg.conditioned_zones.empty?
      hpxml_bldg.zones.add(id: "#{Constants::AutomaticallyAdded}Zone#{unit_num}",
                           zone_type: HPXML::ZoneTypeConditioned)
      hpxml_bldg.hvac_systems.each do |hvac_system|
        hvac_system.attached_to_zone_idref = hpxml_bldg.zones[-1].id
      end
      hpxml_bldg.zones[-1].spaces.add(id: "#{Constants::AutomaticallyAdded}Space#{unit_num}",
                                      floor_area: hpxml_bldg.building_construction.conditioned_floor_area)
      hpxml_bldg.surfaces.each do |surface|
        next unless HPXML::conditioned_locations_this_unit.include? surface.interior_adjacent_to
        next if surface.exterior_adjacent_to == HPXML::LocationOtherHousingUnit

        surface.attached_to_space_idref = hpxml_bldg.zones[-1].spaces[-1].id
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::Header object
  #
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param weather [WeatherFile] Weather object containing EPW information
  # @return [nil]
  def self.apply_header(hpxml_header, hpxml_bldg, weather)
    if hpxml_header.timestep.nil?
      hpxml_header.timestep = 60
      hpxml_header.timestep_isdefaulted = true
    end

    if hpxml_header.sim_begin_month.nil?
      hpxml_header.sim_begin_month = 1
      hpxml_header.sim_begin_month_isdefaulted = true
    end
    if hpxml_header.sim_begin_day.nil?
      hpxml_header.sim_begin_day = 1
      hpxml_header.sim_begin_day_isdefaulted = true
    end
    if hpxml_header.sim_end_month.nil?
      hpxml_header.sim_end_month = 12
      hpxml_header.sim_end_month_isdefaulted = true
    end
    if hpxml_header.sim_end_day.nil?
      hpxml_header.sim_end_day = 31
      hpxml_header.sim_end_day_isdefaulted = true
    end

    sim_calendar_year = Location.get_sim_calendar_year(hpxml_header.sim_calendar_year, weather)
    if not hpxml_header.sim_calendar_year.nil?
      if hpxml_header.sim_calendar_year != sim_calendar_year
        hpxml_header.sim_calendar_year = sim_calendar_year
        hpxml_header.sim_calendar_year_isdefaulted = true
      end
    else
      hpxml_header.sim_calendar_year = sim_calendar_year
      hpxml_header.sim_calendar_year_isdefaulted = true
    end

    if hpxml_header.temperature_capacitance_multiplier.nil?
      hpxml_header.temperature_capacitance_multiplier = 7.0
      hpxml_header.temperature_capacitance_multiplier_isdefaulted = true
    end

    if hpxml_header.ground_to_air_heat_pump_model_type.nil? && (hpxml_bldg.heat_pumps.any? { |hp| hp.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir })
      hpxml_header.ground_to_air_heat_pump_model_type = HPXML::AdvancedResearchGroundToAirHeatPumpModelTypeStandard
      hpxml_header.ground_to_air_heat_pump_model_type_isdefaulted = true
    end

    hpxml_header.unavailable_periods.each do |unavailable_period|
      if unavailable_period.begin_hour.nil?
        unavailable_period.begin_hour = 0
        unavailable_period.begin_hour_isdefaulted = true
      end
      if unavailable_period.end_hour.nil?
        unavailable_period.end_hour = 24
        unavailable_period.end_hour_isdefaulted = true
      end
      if unavailable_period.natvent_availability.nil?
        unavailable_period.natvent_availability = HPXML::ScheduleRegular
        unavailable_period.natvent_availability_isdefaulted = true
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::BuildingHeader object
  # specific to HVAC equipment sizing
  #
  # # Note: This needs to be called after we have applied defaults for the site.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param weather [WeatherFile] Weather object containing EPW information
  # @return [nil]
  def self.apply_building_header_sizing(runner, hpxml_bldg, weather)
    if hpxml_bldg.header.manualj_heating_design_temp.nil?
      hpxml_bldg.header.manualj_heating_design_temp = weather.design.HeatingDrybulb.round(2)
      hpxml_bldg.header.manualj_heating_design_temp_isdefaulted = true
    end

    if hpxml_bldg.header.manualj_cooling_design_temp.nil?
      hpxml_bldg.header.manualj_cooling_design_temp = weather.design.CoolingDrybulb.round(2)
      hpxml_bldg.header.manualj_cooling_design_temp_isdefaulted = true
    end

    if hpxml_bldg.header.manualj_daily_temp_range.nil?
      hpxml_bldg.header.manualj_daily_temp_range = HVACSizing.determine_daily_temperature_range_class(weather.design.DailyTemperatureRange)
      hpxml_bldg.header.manualj_daily_temp_range_isdefaulted = true
    end

    if hpxml_bldg.header.manualj_heating_setpoint.nil?
      hpxml_bldg.header.manualj_heating_setpoint = 70.0 # F, per Manual J
      hpxml_bldg.header.manualj_heating_setpoint_isdefaulted = true
    end

    if hpxml_bldg.header.manualj_cooling_setpoint.nil?
      hpxml_bldg.header.manualj_cooling_setpoint = 75.0 # F, per Manual J
      hpxml_bldg.header.manualj_cooling_setpoint_isdefaulted = true
    end

    if hpxml_bldg.header.manualj_humidity_setpoint.nil?
      hpxml_bldg.header.manualj_humidity_setpoint = 0.5 # 50%
      p_psi = Psychrometrics.Pstd_fZ(hpxml_bldg.elevation)
      hr_indoor_cooling = Psychrometrics.w_fT_R_P(hpxml_bldg.header.manualj_cooling_setpoint, hpxml_bldg.header.manualj_humidity_setpoint, p_psi)
      if HVACSizing.calculate_design_grains(weather.design.CoolingHumidityRatio, hr_indoor_cooling) < 0
        # Dry summer climate per Manual J 18-1 Design Grains
        hpxml_bldg.header.manualj_humidity_setpoint = 0.45 # 45%
      end
      hpxml_bldg.header.manualj_humidity_setpoint_isdefaulted = true
    end

    if hpxml_bldg.header.manualj_humidity_difference.nil?
      p_psi = Psychrometrics.Pstd_fZ(hpxml_bldg.elevation)
      hr_indoor_cooling = Psychrometrics.w_fT_R_P(hpxml_bldg.header.manualj_cooling_setpoint, hpxml_bldg.header.manualj_humidity_setpoint, p_psi)
      hpxml_bldg.header.manualj_humidity_difference = HVACSizing.calculate_design_grains(weather.design.CoolingHumidityRatio, hr_indoor_cooling).round(1)
      hpxml_bldg.header.manualj_humidity_difference_isdefaulted = true
    end

    sum_space_manualj_internal_loads_sensible = Float(hpxml_bldg.conditioned_spaces.map { |space| space.manualj_internal_loads_sensible.to_f }.sum.round)
    if hpxml_bldg.header.manualj_internal_loads_sensible.nil?
      if sum_space_manualj_internal_loads_sensible > 0
        hpxml_bldg.header.manualj_internal_loads_sensible = sum_space_manualj_internal_loads_sensible
      elsif hpxml_bldg.refrigerators.size + hpxml_bldg.freezers.size <= 1
        hpxml_bldg.header.manualj_internal_loads_sensible = 2400.0 # Btuh, per Manual J
      else
        hpxml_bldg.header.manualj_internal_loads_sensible = 3600.0 # Btuh, per Manual J
      end
      hpxml_bldg.header.manualj_internal_loads_sensible_isdefaulted = true
    end
    if sum_space_manualj_internal_loads_sensible == 0
      # Area weighted assignment
      total_floor_area = hpxml_bldg.conditioned_spaces.map { |space| space.floor_area }.sum
      hpxml_bldg.conditioned_spaces.each do |space|
        space.manualj_internal_loads_sensible = (hpxml_bldg.header.manualj_internal_loads_sensible * space.floor_area / total_floor_area).round
        space.manualj_internal_loads_sensible_isdefaulted = true
      end
    elsif (hpxml_bldg.header.manualj_internal_loads_sensible - sum_space_manualj_internal_loads_sensible).abs > 50 # Tolerance for rounding
      runner.registerWarning("ManualJInputs/InternalLoadsSensible (#{hpxml_bldg.header.manualj_internal_loads_sensible}) does not match sum of conditioned spaces (#{sum_space_manualj_internal_loads_sensible}).")
    end

    sum_space_manualj_internal_loads_latent = Float(hpxml_bldg.conditioned_spaces.map { |space| space.manualj_internal_loads_latent.to_f }.sum.round)
    if hpxml_bldg.header.manualj_internal_loads_latent.nil?
      hpxml_bldg.header.manualj_internal_loads_latent = sum_space_manualj_internal_loads_latent # Btuh
      hpxml_bldg.header.manualj_internal_loads_latent_isdefaulted = true
    end
    if sum_space_manualj_internal_loads_latent == 0
      # Area weighted assignment
      total_floor_area = hpxml_bldg.conditioned_spaces.map { |space| space.floor_area }.sum
      hpxml_bldg.conditioned_spaces.each do |space|
        space.manualj_internal_loads_latent = (hpxml_bldg.header.manualj_internal_loads_latent * space.floor_area / total_floor_area).round
        space.manualj_internal_loads_latent_isdefaulted = true
      end
    elsif (hpxml_bldg.header.manualj_internal_loads_latent - sum_space_manualj_internal_loads_latent).abs > 50 # Tolerance for rounding
      runner.registerWarning("ManualJInputs/InternalLoadsLatent (#{hpxml_bldg.header.manualj_internal_loads_latent}) does not match sum of conditioned spaces (#{sum_space_manualj_internal_loads_latent}).")
    end

    sum_space_manualj_num_occupants = hpxml_bldg.conditioned_spaces.map { |space| space.manualj_num_occupants.to_f }.sum
    if hpxml_bldg.header.manualj_num_occupants.nil?
      if sum_space_manualj_num_occupants > 0
        hpxml_bldg.header.manualj_num_occupants = sum_space_manualj_num_occupants
      else
        # Manual J default: full time occupants = 1 + number of bedrooms
        # If the actual number of full time occupants exceeds the default value, the actual occupant count is used
        # See https://github.com/NREL/OpenStudio-HPXML/issues/1841
        hpxml_bldg.header.manualj_num_occupants = [hpxml_bldg.building_construction.number_of_bedrooms + 1, hpxml_bldg.building_occupancy.number_of_residents.to_f].max
      end
      hpxml_bldg.header.manualj_num_occupants_isdefaulted = true
    end
    if sum_space_manualj_num_occupants == 0
      # Area weighted assignment
      total_floor_area = hpxml_bldg.conditioned_spaces.map { |space| space.floor_area }.sum
      hpxml_bldg.conditioned_spaces.each do |space|
        space.manualj_num_occupants = (hpxml_bldg.header.manualj_num_occupants * space.floor_area / total_floor_area).round(2)
        space.manualj_num_occupants_isdefaulted = true
      end
    elsif (hpxml_bldg.header.manualj_num_occupants - sum_space_manualj_num_occupants).abs >= 0.1
      runner.registerWarning("ManualJInputs/NumberofOccupants (#{hpxml_bldg.header.manualj_num_occupants}) does not match sum of conditioned spaces (#{sum_space_manualj_num_occupants}).")
    end

    if hpxml_bldg.header.manualj_infiltration_shielding_class.nil?
      hpxml_bldg.header.manualj_infiltration_shielding_class = 4
      if hpxml_bldg.site.shielding_of_home.nil?
        fail 'Unexpected error.' # Shouldn't happen, it should already be defaulted
      elsif hpxml_bldg.site.shielding_of_home == HPXML::ShieldingWellShielded
        hpxml_bldg.header.manualj_infiltration_shielding_class += 1
      elsif hpxml_bldg.site.shielding_of_home == HPXML::ShieldingExposed
        hpxml_bldg.header.manualj_infiltration_shielding_class -= 1
      end
      if hpxml_bldg.site.site_type.nil?
        fail 'Unexpected error.' # Shouldn't happen, it should already be defaulted
      elsif hpxml_bldg.site.site_type == HPXML::SiteTypeUrban
        hpxml_bldg.header.manualj_infiltration_shielding_class += 1
      elsif hpxml_bldg.site.site_type == HPXML::SiteTypeRural
        hpxml_bldg.header.manualj_infiltration_shielding_class -= 1
      end

      if hpxml_bldg.header.manualj_infiltration_shielding_class < 1
        hpxml_bldg.header.manualj_infiltration_shielding_class = 1
      elsif hpxml_bldg.header.manualj_infiltration_shielding_class > 5
        hpxml_bldg.header.manualj_infiltration_shielding_class = 5
      end
      hpxml_bldg.header.manualj_infiltration_shielding_class_isdefaulted = true
    end

    if hpxml_bldg.header.manualj_infiltration_method.nil?
      infil_measurement = Airflow.get_infiltration_measurement_of_interest(hpxml_bldg)
      if (not infil_measurement.air_leakage.nil?) || (not infil_measurement.effective_leakage_area.nil?)
        hpxml_bldg.header.manualj_infiltration_method = HPXML::ManualJInfiltrationMethodBlowerDoor
      else
        hpxml_bldg.header.manualj_infiltration_method = HPXML::ManualJInfiltrationMethodDefaultTable
      end
      hpxml_bldg.header.manualj_infiltration_method_isdefaulted = true
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::BuildingHeader object
  #
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param weather [WeatherFile] Weather object containing EPW information
  # @return [nil]
  def self.apply_building_header(hpxml_header, hpxml_bldg, weather)
    if hpxml_bldg.header.natvent_days_per_week.nil?
      hpxml_bldg.header.natvent_days_per_week = 3
      hpxml_bldg.header.natvent_days_per_week_isdefaulted = true
    end

    if hpxml_bldg.header.heat_pump_sizing_methodology.nil? && (hpxml_bldg.heat_pumps.size > 0)
      hpxml_bldg.header.heat_pump_sizing_methodology = HPXML::HeatPumpSizingHERS
      hpxml_bldg.header.heat_pump_sizing_methodology_isdefaulted = true
    end

    if hpxml_bldg.header.heat_pump_backup_sizing_methodology.nil? && (hpxml_bldg.heat_pumps.size > 0)
      hpxml_bldg.header.heat_pump_backup_sizing_methodology = HPXML::HeatPumpBackupSizingEmergency
      hpxml_bldg.header.heat_pump_backup_sizing_methodology_isdefaulted = true
    end

    if hpxml_bldg.header.allow_increased_fixed_capacities.nil?
      hpxml_bldg.header.allow_increased_fixed_capacities = false
      hpxml_bldg.header.allow_increased_fixed_capacities_isdefaulted = true
    end

    if hpxml_bldg.header.shading_summer_begin_month.nil? || hpxml_bldg.header.shading_summer_begin_day.nil? || hpxml_bldg.header.shading_summer_end_month.nil? || hpxml_bldg.header.shading_summer_end_day.nil?
      # Default based on Building America seasons
      _, default_cooling_months = HVAC.get_building_america_hvac_seasons(weather, hpxml_bldg.latitude)
      begin_month, begin_day, end_month, end_day = Calendar.get_begin_and_end_dates_from_monthly_array(default_cooling_months, hpxml_header.sim_calendar_year)
      if not begin_month.nil? # Check if no summer
        hpxml_bldg.header.shading_summer_begin_month = begin_month
        hpxml_bldg.header.shading_summer_begin_day = begin_day
        hpxml_bldg.header.shading_summer_end_month = end_month
        hpxml_bldg.header.shading_summer_end_day = end_day
        hpxml_bldg.header.shading_summer_begin_month_isdefaulted = true
        hpxml_bldg.header.shading_summer_begin_day_isdefaulted = true
        hpxml_bldg.header.shading_summer_end_month_isdefaulted = true
        hpxml_bldg.header.shading_summer_end_day_isdefaulted = true
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::EmissionsScenarios objects
  #
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param has_fuel [Hash] Map of HPXML fuel type => boolean of whether fuel type is used
  # @return [nil]
  def self.apply_emissions_scenarios(hpxml_header, has_fuel)
    hpxml_header.emissions_scenarios.each do |scenario|
      # Electricity
      if not scenario.elec_schedule_filepath.nil?
        if scenario.elec_schedule_number_of_header_rows.nil?
          scenario.elec_schedule_number_of_header_rows = 0
          scenario.elec_schedule_number_of_header_rows_isdefaulted = true
        end
        if scenario.elec_schedule_column_number.nil?
          scenario.elec_schedule_column_number = 1
          scenario.elec_schedule_column_number_isdefaulted = true
        end
      end

      # Fossil fuels
      default_units = HPXML::EmissionsScenario::UnitsLbPerMBtu
      if scenario.emissions_type.downcase == 'co2e'
        natural_gas, propane, fuel_oil, coal, wood, wood_pellets = 147.3, 177.8, 195.9, nil, nil, nil
      elsif scenario.emissions_type.downcase == 'nox'
        natural_gas, propane, fuel_oil, coal, wood, wood_pellets = 0.0922, 0.1421, 0.1300, nil, nil, nil
      elsif scenario.emissions_type.downcase == 'so2'
        natural_gas, propane, fuel_oil, coal, wood, wood_pellets = 0.0006, 0.0002, 0.0015, nil, nil, nil
      else
        natural_gas, propane, fuel_oil, coal, wood, wood_pellets = nil, nil, nil, nil, nil, nil
      end
      if has_fuel[HPXML::FuelTypeNaturalGas]
        if (scenario.natural_gas_units.nil? || scenario.natural_gas_value.nil?) && (not natural_gas.nil?)
          scenario.natural_gas_units = default_units
          scenario.natural_gas_units_isdefaulted = true
          scenario.natural_gas_value = natural_gas
          scenario.natural_gas_value_isdefaulted = true
        end
      end
      if has_fuel[HPXML::FuelTypePropane]
        if (scenario.propane_units.nil? || scenario.propane_value.nil?) && (not propane.nil?)
          scenario.propane_units = default_units
          scenario.propane_units_isdefaulted = true
          scenario.propane_value = propane
          scenario.propane_value_isdefaulted = true
        end
      end
      if has_fuel[HPXML::FuelTypeOil]
        if (scenario.fuel_oil_units.nil? || scenario.fuel_oil_value.nil?) && (not fuel_oil.nil?)
          scenario.fuel_oil_units = default_units
          scenario.fuel_oil_units_isdefaulted = true
          scenario.fuel_oil_value = fuel_oil
          scenario.fuel_oil_value_isdefaulted = true
        end
      end
      if has_fuel[HPXML::FuelTypeCoal]
        if (scenario.coal_units.nil? || scenario.coal_value.nil?) && (not coal.nil?)
          scenario.coal_units = default_units
          scenario.coal_units_isdefaulted = true
          scenario.coal_value = coal
          scenario.coal_value_isdefaulted = true
        end
      end
      if has_fuel[HPXML::FuelTypeWoodCord]
        if (scenario.wood_units.nil? || scenario.wood_value.nil?) && (not wood.nil?)
          scenario.wood_units = default_units
          scenario.wood_units_isdefaulted = true
          scenario.wood_value = wood
          scenario.wood_value_isdefaulted = true
        end
      end
      next unless has_fuel[HPXML::FuelTypeWoodPellets]

      next unless (scenario.wood_pellets_units.nil? || scenario.wood_pellets_value.nil?) && (not wood_pellets.nil?)

      scenario.wood_pellets_units = default_units
      scenario.wood_pellets_units_isdefaulted = true
      scenario.wood_pellets_value = wood_pellets
      scenario.wood_pellets_value_isdefaulted = true
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::UtilityBillScenarios objects
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param has_fuel [Hash] Map of HPXML fuel type => boolean of whether fuel type is used
  # @return [nil]
  def self.apply_utility_bill_scenarios(runner, hpxml_header, hpxml_bldg, has_fuel)
    hpxml_header.utility_bill_scenarios.each do |scenario|
      if scenario.elec_tariff_filepath.nil?
        if scenario.elec_fixed_charge.nil?
          scenario.elec_fixed_charge = 12.0 # https://www.nrdc.org/experts/samantha-williams/there-war-attrition-electricity-fixed-charges says $11.19/month in 2018
          scenario.elec_fixed_charge_isdefaulted = true
        end
        if scenario.elec_marginal_rate.nil?
          scenario.elec_marginal_rate, _ = UtilityBills.get_rates_from_eia_data(runner, hpxml_bldg.state_code, HPXML::FuelTypeElectricity, scenario.elec_fixed_charge)
          scenario.elec_marginal_rate_isdefaulted = true
        end
      end

      if has_fuel[HPXML::FuelTypeNaturalGas]
        if scenario.natural_gas_fixed_charge.nil?
          scenario.natural_gas_fixed_charge = 12.0 # https://www.aga.org/sites/default/files/aga_energy_analysis_-_natural_gas_utility_rate_structure.pdf says $11.25/month in 2015
          scenario.natural_gas_fixed_charge_isdefaulted = true
        end
        if scenario.natural_gas_marginal_rate.nil?
          scenario.natural_gas_marginal_rate, _ = UtilityBills.get_rates_from_eia_data(runner, hpxml_bldg.state_code, HPXML::FuelTypeNaturalGas, scenario.natural_gas_fixed_charge)
          scenario.natural_gas_marginal_rate_isdefaulted = true
        end
      end

      if has_fuel[HPXML::FuelTypePropane]
        if scenario.propane_fixed_charge.nil?
          scenario.propane_fixed_charge = 0.0
          scenario.propane_fixed_charge_isdefaulted = true
        end
        if scenario.propane_marginal_rate.nil?
          scenario.propane_marginal_rate, _ = UtilityBills.get_rates_from_eia_data(runner, hpxml_bldg.state_code, HPXML::FuelTypePropane, nil)
          scenario.propane_marginal_rate_isdefaulted = true
        end
      end

      if has_fuel[HPXML::FuelTypeOil]
        if scenario.fuel_oil_fixed_charge.nil?
          scenario.fuel_oil_fixed_charge = 0.0
          scenario.fuel_oil_fixed_charge_isdefaulted = true
        end
        if scenario.fuel_oil_marginal_rate.nil?
          scenario.fuel_oil_marginal_rate, _ = UtilityBills.get_rates_from_eia_data(runner, hpxml_bldg.state_code, HPXML::FuelTypeOil, nil)
          scenario.fuel_oil_marginal_rate_isdefaulted = true
        end
      end

      if has_fuel[HPXML::FuelTypeCoal]
        if scenario.coal_fixed_charge.nil?
          scenario.coal_fixed_charge = 0.0
          scenario.coal_fixed_charge_isdefaulted = true
        end
        if scenario.coal_marginal_rate.nil?
          scenario.coal_marginal_rate, _ = UtilityBills.get_rates_from_eia_data(runner, hpxml_bldg.state_code, HPXML::FuelTypeCoal, nil)
          scenario.coal_marginal_rate_isdefaulted = true
        end
      end

      if has_fuel[HPXML::FuelTypeWoodCord]
        if scenario.wood_fixed_charge.nil?
          scenario.wood_fixed_charge = 0.0
          scenario.wood_fixed_charge_isdefaulted = true
        end
        if scenario.wood_marginal_rate.nil?
          scenario.wood_marginal_rate, _ = UtilityBills.get_rates_from_eia_data(runner, hpxml_bldg.state_code, HPXML::FuelTypeWoodCord, nil)
          scenario.wood_marginal_rate_isdefaulted = true
        end
      end

      if has_fuel[HPXML::FuelTypeWoodPellets]
        if scenario.wood_pellets_fixed_charge.nil?
          scenario.wood_pellets_fixed_charge = 0.0
          scenario.wood_pellets_fixed_charge_isdefaulted = true
        end
        if scenario.wood_pellets_marginal_rate.nil?
          scenario.wood_pellets_marginal_rate, _ = UtilityBills.get_rates_from_eia_data(runner, hpxml_bldg.state_code, HPXML::FuelTypeWoodPellets, nil)
          scenario.wood_pellets_marginal_rate_isdefaulted = true
        end
      end

      next unless hpxml_bldg.pv_systems.size > 0

      if scenario.pv_compensation_type.nil?
        scenario.pv_compensation_type = HPXML::PVCompensationTypeNetMetering
        scenario.pv_compensation_type_isdefaulted = true
      end

      if scenario.pv_compensation_type == HPXML::PVCompensationTypeNetMetering
        if scenario.pv_net_metering_annual_excess_sellback_rate_type.nil?
          scenario.pv_net_metering_annual_excess_sellback_rate_type = HPXML::PVAnnualExcessSellbackRateTypeUserSpecified
          scenario.pv_net_metering_annual_excess_sellback_rate_type_isdefaulted = true
        end
        if scenario.pv_net_metering_annual_excess_sellback_rate_type == HPXML::PVAnnualExcessSellbackRateTypeUserSpecified
          if scenario.pv_net_metering_annual_excess_sellback_rate.nil?
            scenario.pv_net_metering_annual_excess_sellback_rate = 0.03
            scenario.pv_net_metering_annual_excess_sellback_rate_isdefaulted = true
          end
        end
      elsif scenario.pv_compensation_type == HPXML::PVCompensationTypeFeedInTariff
        if scenario.pv_feed_in_tariff_rate.nil?
          scenario.pv_feed_in_tariff_rate = 0.12
          scenario.pv_feed_in_tariff_rate_isdefaulted = true
        end
      end

      if scenario.pv_monthly_grid_connection_fee_dollars_per_kw.nil? && scenario.pv_monthly_grid_connection_fee_dollars.nil?
        scenario.pv_monthly_grid_connection_fee_dollars = 0.0
        scenario.pv_monthly_grid_connection_fee_dollars_isdefaulted = true
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::Building object
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param weather [WeatherFile] Weather object containing EPW information
  # @return [nil]
  def self.apply_building(hpxml_bldg, weather)
    if hpxml_bldg.site.soil_type.nil? && hpxml_bldg.site.ground_conductivity.nil? && hpxml_bldg.site.ground_diffusivity.nil?
      hpxml_bldg.site.soil_type = HPXML::SiteSoilTypeUnknown
      hpxml_bldg.site.soil_type_isdefaulted = true
    end

    if hpxml_bldg.site.moisture_type.nil? && hpxml_bldg.site.ground_conductivity.nil? && hpxml_bldg.site.ground_diffusivity.nil?
      hpxml_bldg.site.moisture_type = HPXML::SiteSoilMoistureTypeMixed
      hpxml_bldg.site.moisture_type_isdefaulted = true
    end

    # Conductivity/diffusivity values come from https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4813881 (with the exception of "unknown")
    if hpxml_bldg.site.ground_conductivity.nil? && hpxml_bldg.site.ground_diffusivity.nil?
      case hpxml_bldg.site.soil_type
      when HPXML::SiteSoilTypeSand
        if hpxml_bldg.site.moisture_type == HPXML::SiteSoilMoistureTypeDry
          hpxml_bldg.site.ground_conductivity = 0.2311 # Btu/hr-ft-F
          hpxml_bldg.site.ground_diffusivity = 0.0097 # ft^2/hr
        elsif hpxml_bldg.site.moisture_type == HPXML::SiteSoilMoistureTypeWet
          hpxml_bldg.site.ground_conductivity = 1.3865 # Btu/hr-ft-F
          hpxml_bldg.site.ground_diffusivity = 0.0322 # ft^2/hr
        elsif hpxml_bldg.site.moisture_type == HPXML::SiteSoilMoistureTypeMixed
          hpxml_bldg.site.ground_conductivity = ((0.2311 + 1.3865) / 2.0).round(4) # Btu/hr-ft-F
          hpxml_bldg.site.ground_diffusivity = ((0.0097 + 0.0322) / 2.0).round(4) # ft^2/hr
        end
        hpxml_bldg.site.ground_conductivity_isdefaulted = true
        hpxml_bldg.site.ground_diffusivity_isdefaulted = true
      when HPXML::SiteSoilTypeSilt, HPXML::SiteSoilTypeClay
        case hpxml_bldg.site.moisture_type
        when HPXML::SiteSoilMoistureTypeDry
          hpxml_bldg.site.ground_conductivity = 0.2889 # Btu/hr-ft-F
          hpxml_bldg.site.ground_diffusivity = 0.0120 # ft^2/hr
        when HPXML::SiteSoilMoistureTypeWet
          hpxml_bldg.site.ground_conductivity = 0.9821 # Btu/hr-ft-F
          hpxml_bldg.site.ground_diffusivity = 0.0194 # ft^2/hr
        when HPXML::SiteSoilMoistureTypeMixed
          hpxml_bldg.site.ground_conductivity = ((0.2889 + 0.9821) / 2.0).round(4) # Btu/hr-ft-F
          hpxml_bldg.site.ground_diffusivity = ((0.0120 + 0.0194) / 2.0).round(4) # ft^2/hr
        end
        hpxml_bldg.site.ground_conductivity_isdefaulted = true
        hpxml_bldg.site.ground_diffusivity_isdefaulted = true
      when HPXML::SiteSoilTypeLoam
        hpxml_bldg.site.ground_conductivity = 1.2132 # Btu/hr-ft-F
        hpxml_bldg.site.ground_diffusivity = 0.0353 # ft^2/hr
        hpxml_bldg.site.ground_conductivity_isdefaulted = true
        hpxml_bldg.site.ground_diffusivity_isdefaulted = true
      when HPXML::SiteSoilTypeGravel
        case hpxml_bldg.site.moisture_type
        when HPXML::SiteSoilMoistureTypeDry
          hpxml_bldg.site.ground_conductivity = 0.2311 # Btu/hr-ft-F
          hpxml_bldg.site.ground_diffusivity = 0.0097 # ft^2/hr
        when HPXML::SiteSoilMoistureTypeWet
          hpxml_bldg.site.ground_conductivity = 1.0399 # Btu/hr-ft-F
          hpxml_bldg.site.ground_diffusivity = 0.0291 # ft^2/hr
        when HPXML::SiteSoilMoistureTypeMixed
          hpxml_bldg.site.ground_conductivity = ((0.2311 + 1.0399) / 2.0).round(4) # Btu/hr-ft-F
          hpxml_bldg.site.ground_diffusivity = ((0.0097 + 0.0291) / 2.0).round(4) # ft^2/hr
        end
        hpxml_bldg.site.ground_conductivity_isdefaulted = true
        hpxml_bldg.site.ground_diffusivity_isdefaulted = true
      when HPXML::SiteSoilTypeUnknown
        hpxml_bldg.site.ground_conductivity = 1.0 # ANSI/RESNET/ICC 301-2022 Addendum C
        hpxml_bldg.site.ground_diffusivity = 0.0208
        hpxml_bldg.site.ground_conductivity_isdefaulted = true
        hpxml_bldg.site.ground_diffusivity_isdefaulted = true
      end
    end
    if hpxml_bldg.site.ground_conductivity.nil? && !hpxml_bldg.site.ground_diffusivity.nil?
      # Divide diffusivity by 0.0208 to maintain 1/0.0208 relationship
      hpxml_bldg.site.ground_conductivity = hpxml_bldg.site.ground_diffusivity / 0.0208 # Btu/hr-ft-F
      hpxml_bldg.site.ground_conductivity_isdefaulted = true
    elsif !hpxml_bldg.site.ground_conductivity.nil? && hpxml_bldg.site.ground_diffusivity.nil?
      # Multiply conductivity by 0.0208 to maintain 1/0.0208 relationship
      hpxml_bldg.site.ground_diffusivity = hpxml_bldg.site.ground_conductivity * 0.0208 # ft^2/hr
      hpxml_bldg.site.ground_diffusivity_isdefaulted = true
    end

    if hpxml_bldg.state_code.nil?
      hpxml_bldg.state_code = get_state_code(hpxml_bldg.state_code, weather, hpxml_bldg.zip_code)
      hpxml_bldg.state_code_isdefaulted = true
    end

    if hpxml_bldg.dst_observed.nil?
      if ['AZ', 'HI'].include? hpxml_bldg.state_code
        hpxml_bldg.dst_observed = false
      else
        hpxml_bldg.dst_observed = true
      end
      hpxml_bldg.dst_observed_isdefaulted = true
    end

    if hpxml_bldg.city.nil?
      hpxml_bldg.city = get_city(hpxml_bldg.city, weather, hpxml_bldg.zip_code)
      hpxml_bldg.city_isdefaulted = true
    end

    if hpxml_bldg.time_zone_utc_offset.nil?
      hpxml_bldg.time_zone_utc_offset = get_time_zone(hpxml_bldg.time_zone_utc_offset, weather, hpxml_bldg.zip_code)
      hpxml_bldg.time_zone_utc_offset_isdefaulted = true
    end

    if hpxml_bldg.dst_observed
      if hpxml_bldg.dst_begin_month.nil? || hpxml_bldg.dst_begin_day.nil? || hpxml_bldg.dst_end_month.nil? || hpxml_bldg.dst_end_day.nil?
        if (not weather.header.DSTStartDate.nil?) && (not weather.header.DSTEndDate.nil?)
          # Use weather file DST dates if available
          dst_start_date = weather.header.DSTStartDate
          dst_end_date = weather.header.DSTEndDate
          hpxml_bldg.dst_begin_month = dst_start_date.monthOfYear.value
          hpxml_bldg.dst_begin_day = dst_start_date.dayOfMonth
          hpxml_bldg.dst_end_month = dst_end_date.monthOfYear.value
          hpxml_bldg.dst_end_day = dst_end_date.dayOfMonth
        else
          # Roughly average US dates according to https://en.wikipedia.org/wiki/Daylight_saving_time_in_the_United_States
          hpxml_bldg.dst_begin_month = 3
          hpxml_bldg.dst_begin_day = 12
          hpxml_bldg.dst_end_month = 11
          hpxml_bldg.dst_end_day = 5
        end
        hpxml_bldg.dst_begin_month_isdefaulted = true
        hpxml_bldg.dst_begin_day_isdefaulted = true
        hpxml_bldg.dst_end_month_isdefaulted = true
        hpxml_bldg.dst_end_day_isdefaulted = true
      end
    end

    if hpxml_bldg.elevation.nil?
      hpxml_bldg.elevation = get_elevation(weather)
      hpxml_bldg.elevation_isdefaulted = true
    end

    if hpxml_bldg.latitude.nil?
      hpxml_bldg.latitude = get_latitude(hpxml_bldg.latitude, weather, hpxml_bldg.zip_code)
      hpxml_bldg.latitude_isdefaulted = true
    end

    if hpxml_bldg.longitude.nil?
      hpxml_bldg.longitude = get_longitude(hpxml_bldg.longitude, weather, hpxml_bldg.zip_code)
      hpxml_bldg.longitude_isdefaulted = true
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::Site object
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_site(hpxml_bldg)
    if hpxml_bldg.site.site_type.nil?
      hpxml_bldg.site.site_type = HPXML::SiteTypeSuburban
      hpxml_bldg.site.site_type_isdefaulted = true
    end

    if hpxml_bldg.site.shielding_of_home.nil?
      if [HPXML::ResidentialTypeApartment, HPXML::ResidentialTypeSFA].include?(hpxml_bldg.building_construction.residential_facility_type)
        # Shielding Class 5 is ACCA MJ8 default for Table 5B/5E for townhouses and condos
        hpxml_bldg.site.shielding_of_home = HPXML::ShieldingWellShielded
      else
        # Shielding Class 4 is ACCA MJ8 default for Table 5A/5D and ANSI/RESNET/ICC 301 default
        hpxml_bldg.site.shielding_of_home = HPXML::ShieldingNormal
      end
      hpxml_bldg.site.shielding_of_home_isdefaulted = true
    end

    if hpxml_bldg.site.ground_conductivity.nil?
      hpxml_bldg.site.ground_conductivity = 1.0 # Btu/hr-ft-F
      hpxml_bldg.site.ground_conductivity_isdefaulted = true
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::NeighborBuildings objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_neighbor_buildings(hpxml_bldg)
    hpxml_bldg.neighbor_buildings.each do |neighbor_building|
      if neighbor_building.azimuth.nil?
        neighbor_building.azimuth = get_azimuth_from_orientation(neighbor_building.orientation)
        neighbor_building.azimuth_isdefaulted = true
      end
      if neighbor_building.orientation.nil?
        neighbor_building.orientation = get_orientation_from_azimuth(neighbor_building.azimuth)
        neighbor_building.orientation_isdefaulted = true
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::BuildingOccupancy object
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def self.apply_building_occupancy(hpxml_bldg, schedules_file)
    schedules_file_includes_occupants = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:Occupants].name))
    if hpxml_bldg.building_occupancy.weekday_fractions.nil? && !schedules_file_includes_occupants
      hpxml_bldg.building_occupancy.weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:Occupants].name]['WeekdayScheduleFractions']
      hpxml_bldg.building_occupancy.weekday_fractions_isdefaulted = true
    end
    if hpxml_bldg.building_occupancy.weekend_fractions.nil? && !schedules_file_includes_occupants
      hpxml_bldg.building_occupancy.weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:Occupants].name]['WeekendScheduleFractions']
      hpxml_bldg.building_occupancy.weekend_fractions_isdefaulted = true
    end
    if hpxml_bldg.building_occupancy.monthly_multipliers.nil? && !schedules_file_includes_occupants
      hpxml_bldg.building_occupancy.monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:Occupants].name]['MonthlyScheduleMultipliers']
      hpxml_bldg.building_occupancy.monthly_multipliers_isdefaulted = true
    end
    if hpxml_bldg.building_occupancy.general_water_use_usage_multiplier.nil?
      hpxml_bldg.building_occupancy.general_water_use_usage_multiplier = 1.0
      hpxml_bldg.building_occupancy.general_water_use_usage_multiplier_isdefaulted = true
    end
    schedules_file_includes_water = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:GeneralWaterUse].name))
    if hpxml_bldg.building_occupancy.general_water_use_weekday_fractions.nil? && !schedules_file_includes_water
      hpxml_bldg.building_occupancy.general_water_use_weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:GeneralWaterUse].name]['GeneralWaterUseWeekdayScheduleFractions']
      hpxml_bldg.building_occupancy.general_water_use_weekday_fractions_isdefaulted = true
    end
    if hpxml_bldg.building_occupancy.general_water_use_weekend_fractions.nil? && !schedules_file_includes_water
      hpxml_bldg.building_occupancy.general_water_use_weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:GeneralWaterUse].name]['GeneralWaterUseWeekendScheduleFractions']
      hpxml_bldg.building_occupancy.general_water_use_weekend_fractions_isdefaulted = true
    end
    if hpxml_bldg.building_occupancy.general_water_use_monthly_multipliers.nil? && !schedules_file_includes_water
      hpxml_bldg.building_occupancy.general_water_use_monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:GeneralWaterUse].name]['GeneralWaterUseMonthlyScheduleMultipliers']
      hpxml_bldg.building_occupancy.general_water_use_monthly_multipliers_isdefaulted = true
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::BuildingConstruction object
  #
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_building_construction(hpxml_header, hpxml_bldg)
    cond_volume = hpxml_bldg.building_construction.conditioned_building_volume
    cond_crawl_volume = Geometry.calculate_zone_volume(hpxml_bldg, HPXML::LocationCrawlspaceConditioned)
    cfa = hpxml_bldg.building_construction.conditioned_floor_area
    nbeds = hpxml_bldg.building_construction.number_of_bedrooms
    if hpxml_bldg.building_construction.average_ceiling_height.nil?
      if not cond_volume.nil?
        hpxml_bldg.building_construction.average_ceiling_height = ((cond_volume - cond_crawl_volume) / cfa).round(2)
      else
        if hpxml_bldg.roofs.any? { |r| r.interior_adjacent_to == HPXML::LocationConditionedSpace }
          # This is a very crude estimate for cathedral ceiling and conditioned attic, but better than nothing
          roof_height, roof_footprint_area = Geometry.calculate_height_and_footprint_of_roofs(hpxml_bldg, HPXML::LocationConditionedSpace)
          roof_avg_height = roof_height / 3.0 # Assume square hip roof
          roof_cfa_frac = roof_footprint_area / cfa
          hpxml_bldg.building_construction.average_ceiling_height = ((8.0 + roof_avg_height) * roof_cfa_frac + 8.0 * (1.0 - roof_cfa_frac)).round(2)
        else
          hpxml_bldg.building_construction.average_ceiling_height = 8.0
        end
      end
      hpxml_bldg.building_construction.average_ceiling_height_isdefaulted = true
    end
    if hpxml_bldg.building_construction.conditioned_building_volume.nil?
      avg_ceiling_height = hpxml_bldg.building_construction.average_ceiling_height
      hpxml_bldg.building_construction.conditioned_building_volume = (cfa * avg_ceiling_height + cond_crawl_volume).round
      hpxml_bldg.building_construction.conditioned_building_volume_isdefaulted = true
    end
    if hpxml_bldg.building_construction.number_of_bathrooms.nil?
      hpxml_bldg.building_construction.number_of_bathrooms = Float(get_num_bathrooms(nbeds)).to_i
      hpxml_bldg.building_construction.number_of_bathrooms_isdefaulted = true
    end
    if hpxml_bldg.building_construction.number_of_units.nil?
      hpxml_bldg.building_construction.number_of_units = 1
      hpxml_bldg.building_construction.number_of_units_isdefaulted = true
    end
    if hpxml_bldg.building_construction.unit_height_above_grade.nil?
      floors = hpxml_bldg.floors.select { |floor| floor.is_floor && floor.is_thermal_boundary }
      exterior_floors = floors.select { |floor| floor.is_exterior }
      if floors.size > 0 && floors.size == exterior_floors.size && hpxml_bldg.slabs.size == 0 && (!hpxml_header.nil? && !hpxml_header.apply_ashrae140_assumptions)
        # All floors are exterior (adjacent to ambient/bellywing) and there are no slab floors
        hpxml_bldg.building_construction.unit_height_above_grade = 2.0
      elsif hpxml_bldg.has_location(HPXML::LocationBasementConditioned)
        # Homes w/ conditioned basement will have a negative value
        cond_bsmt_fnd_walls = hpxml_bldg.foundation_walls.select { |fw| fw.is_exterior && fw.interior_adjacent_to == HPXML::LocationBasementConditioned }
        if cond_bsmt_fnd_walls.any?
          max_depth_bg = cond_bsmt_fnd_walls.map { |fw| fw.depth_below_grade }.max
          hpxml_bldg.building_construction.unit_height_above_grade = -1 * max_depth_bg
        else
          hpxml_bldg.building_construction.unit_height_above_grade = 0.0
        end
      else
        hpxml_bldg.building_construction.unit_height_above_grade = 0.0
      end
      hpxml_bldg.building_construction.unit_height_above_grade_isdefaulted = true
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::Zones and HPXML::Spaces objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_zone_spaces(hpxml_bldg)
    hpxml_bldg.conditioned_spaces.each do |space|
      if space.fenestration_load_procedure.nil?
        space.fenestration_load_procedure = HPXML::SpaceFenestrationLoadProcedureStandard
        space.fenestration_load_procedure_isdefaulted = true
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::ClimateandRiskZones object
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param unit_num [Integer] Dwelling unit number
  # @return [nil]
  def self.apply_climate_and_risk_zones(hpxml_bldg, weather, unit_num)
    if hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.empty?
      weather_data = lookup_weather_data_from_wmo(weather.header.WMONumber)
      if not weather_data.empty?
        hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.add(zone: weather_data[:zipcode_iecc_zone],
                                                                 year: 2006,
                                                                 zone_isdefaulted: true,
                                                                 year_isdefaulted: true)
      end
    end
    if hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath.nil?
      hpxml_bldg.climate_and_risk_zones.weather_station_id = "WeatherStation#{unit_num}"
      weather_data = lookup_weather_data_from_zipcode(hpxml_bldg.zip_code)
      hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = weather_data[:station_filename]
      hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath_isdefaulted = true
      hpxml_bldg.climate_and_risk_zones.weather_station_name = weather_data[:station_name]
      hpxml_bldg.climate_and_risk_zones.weather_station_name_isdefaulted = true
      hpxml_bldg.climate_and_risk_zones.weather_station_wmo = weather_data[:station_wmo]
      hpxml_bldg.climate_and_risk_zones.weather_station_wmo_isdefaulted = true
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::Attic objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_attics(hpxml_bldg)
    if hpxml_bldg.has_location(HPXML::LocationAtticUnvented)
      unvented_attics = hpxml_bldg.attics.select { |a| a.attic_type == HPXML::AtticTypeUnvented }
      if unvented_attics.empty?
        hpxml_bldg.attics.add(id: 'UnventedAttic',
                              attic_type: HPXML::AtticTypeUnvented)
        unvented_attics << hpxml_bldg.attics[-1]
      end
      unvented_attics.each do |unvented_attic|
        next unless unvented_attic.within_infiltration_volume.nil?

        unvented_attic.within_infiltration_volume = false
        unvented_attic.within_infiltration_volume_isdefaulted = true
      end
      if unvented_attics.map { |a| a.within_infiltration_volume }.uniq.size != 1
        fail 'All unvented attics must have the same WithinInfiltrationVolume value.'
      end
    end

    if hpxml_bldg.has_location(HPXML::LocationAtticVented)
      vented_attics = hpxml_bldg.attics.select { |a| a.attic_type == HPXML::AtticTypeVented }
      if vented_attics.empty?
        hpxml_bldg.attics.add(id: 'VentedAttic',
                              attic_type: HPXML::AtticTypeVented)
        vented_attics << hpxml_bldg.attics[-1]
      end
      vented_attics.each do |vented_attic|
        next unless (vented_attic.vented_attic_sla.nil? && vented_attic.vented_attic_ach.nil?)

        vented_attic.vented_attic_sla = get_vented_attic_sla()
        vented_attic.vented_attic_sla_isdefaulted = true
      end
      if vented_attics.map { |a| a.vented_attic_sla }.uniq.size != 1
        fail 'All vented attics must have the same VentilationRate.'
      end
      if vented_attics.map { |a| a.vented_attic_ach }.uniq.size != 1
        fail 'All vented attics must have the same VentilationRate.'
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::Foundation objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_foundations(hpxml_bldg)
    if hpxml_bldg.has_location(HPXML::LocationCrawlspaceUnvented)
      unvented_crawls = hpxml_bldg.foundations.select { |f| f.foundation_type == HPXML::FoundationTypeCrawlspaceUnvented }
      if unvented_crawls.empty?
        hpxml_bldg.foundations.add(id: 'UnventedCrawlspace',
                                   foundation_type: HPXML::FoundationTypeCrawlspaceUnvented)
        unvented_crawls << hpxml_bldg.foundations[-1]
      end
      unvented_crawls.each do |unvented_crawl|
        next unless unvented_crawl.within_infiltration_volume.nil?

        unvented_crawl.within_infiltration_volume = false
        unvented_crawl.within_infiltration_volume_isdefaulted = true
      end
      if unvented_crawls.map { |f| f.within_infiltration_volume }.uniq.size != 1
        fail 'All unvented crawlspaces must have the same WithinInfiltrationVolume value.'
      end
    end

    if hpxml_bldg.has_location(HPXML::LocationCrawlspaceConditioned)
      cond_crawls = hpxml_bldg.foundations.select { |f| f.foundation_type == HPXML::FoundationTypeCrawlspaceConditioned }
      if cond_crawls.empty?
        hpxml_bldg.foundations.add(id: 'ConditionedCrawlspace',
                                   foundation_type: HPXML::FoundationTypeCrawlspaceConditioned)
        cond_crawls << hpxml_bldg.foundations[-1]
      end
      cond_crawls.each do |cond_crawl|
        next unless cond_crawl.within_infiltration_volume.nil?

        cond_crawl.within_infiltration_volume = true
        cond_crawl.within_infiltration_volume_isdefaulted = true
      end
      if cond_crawls.map { |f| f.within_infiltration_volume }.uniq.size != 1
        fail 'All conditioned crawlspaces must have the same WithinInfiltrationVolume value.'
      end
    end

    if hpxml_bldg.has_location(HPXML::LocationBasementUnconditioned)
      uncond_bsmts = hpxml_bldg.foundations.select { |f| f.foundation_type == HPXML::FoundationTypeBasementUnconditioned }
      if uncond_bsmts.empty?
        hpxml_bldg.foundations.add(id: 'UnconditionedBasement',
                                   foundation_type: HPXML::FoundationTypeBasementUnconditioned)
        uncond_bsmts << hpxml_bldg.foundations[-1]
      end
      uncond_bsmts.each do |uncond_bsmt|
        next unless uncond_bsmt.within_infiltration_volume.nil?

        uncond_bsmt.within_infiltration_volume = false
        uncond_bsmt.within_infiltration_volume_isdefaulted = true
      end
      if uncond_bsmts.map { |f| f.within_infiltration_volume }.uniq.size != 1
        fail 'All unconditioned basements must have the same WithinInfiltrationVolume value.'
      end
    end

    if hpxml_bldg.has_location(HPXML::LocationBasementConditioned)
      cond_bsmts = hpxml_bldg.foundations.select { |f| f.foundation_type == HPXML::FoundationTypeBasementConditioned }
      if cond_bsmts.empty?
        hpxml_bldg.foundations.add(id: 'ConditionedBasement',
                                   foundation_type: HPXML::FoundationTypeBasementConditioned)
        cond_bsmts << hpxml_bldg.foundations[-1]
      end
      cond_bsmts.each do |cond_bsmt|
        next unless cond_bsmt.within_infiltration_volume.nil?

        cond_bsmt.within_infiltration_volume = true
        cond_bsmt.within_infiltration_volume_isdefaulted = true
      end
      if cond_bsmts.map { |f| f.within_infiltration_volume }.uniq.size != 1
        fail 'All conditioned basements must have the same WithinInfiltrationVolume value.'
      end
    end

    if hpxml_bldg.has_location(HPXML::LocationCrawlspaceVented)
      vented_crawls = hpxml_bldg.foundations.select { |f| f.foundation_type == HPXML::FoundationTypeCrawlspaceVented }
      if vented_crawls.empty?
        hpxml_bldg.foundations.add(id: 'VentedCrawlspace',
                                   foundation_type: HPXML::FoundationTypeCrawlspaceVented)
        vented_crawls << hpxml_bldg.foundations[-1]
      end
      vented_crawls.each do |vented_crawl|
        next unless vented_crawl.vented_crawlspace_sla.nil?

        vented_crawl.vented_crawlspace_sla = get_vented_crawl_sla()
        vented_crawl.vented_crawlspace_sla_isdefaulted = true
      end
      if vented_crawls.map { |f| f.vented_crawlspace_sla }.uniq.size != 1
        fail 'All vented crawlspaces must have the same VentilationRate.'
      end
    end

    if hpxml_bldg.has_location(HPXML::LocationManufacturedHomeUnderBelly)
      belly_and_wing_foundations = hpxml_bldg.foundations.select { |f| f.foundation_type == HPXML::FoundationTypeBellyAndWing }
      if belly_and_wing_foundations.empty?
        hpxml_bldg.foundations.add(id: 'BellyAndWing',
                                   foundation_type: HPXML::FoundationTypeBellyAndWing)
        belly_and_wing_foundations << hpxml_bldg.foundations[-1]
      end
      belly_and_wing_foundations.each do |foundation|
        next unless foundation.belly_wing_skirt_present.nil?

        foundation.belly_wing_skirt_present = true
        foundation.belly_wing_skirt_present_isdefaulted = true
      end
      if belly_and_wing_foundations.map { |f| f.belly_wing_skirt_present }.uniq.size != 1
        fail 'All belly-and-wing foundations must have the same SkirtPresent.'
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::AirInfiltrationMeasurement object
  #
  # Note: This needs to be called after we have applied defaults for ducts.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_infiltration(hpxml_bldg)
    infil_measurement = Airflow.get_infiltration_measurement_of_interest(hpxml_bldg)
    default_infil_height, default_infil_volume = get_infiltration_height_and_volume(hpxml_bldg)
    if infil_measurement.infiltration_volume.nil?
      infil_measurement.infiltration_volume = default_infil_volume
      infil_measurement.infiltration_volume_isdefaulted = true
    end
    if infil_measurement.infiltration_height.nil?
      infil_measurement.infiltration_height = default_infil_height
      infil_measurement.infiltration_height_isdefaulted = true
    end
    if (not infil_measurement.leakiness_description.nil?) && infil_measurement.air_leakage.nil? && infil_measurement.effective_leakage_area.nil?
      cfa = hpxml_bldg.building_construction.conditioned_floor_area
      ncfl_ag = hpxml_bldg.building_construction.number_of_conditioned_floors_above_grade
      year_built = hpxml_bldg.building_construction.year_built
      avg_ceiling_height = hpxml_bldg.building_construction.average_ceiling_height
      infil_volume = infil_measurement.infiltration_volume
      iecc_cz = hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone

      # Duct location fractions
      duct_loc_fracs = {}
      hpxml_bldg.hvac_distributions.each do |hvac_distribution|
        next if hvac_distribution.ducts.empty?

        # HVAC fraction
        htg_fraction = 0.0
        clg_fraction = 0.0
        hvac_distribution.hvac_systems.each do |hvac_system|
          if hvac_system.respond_to? :fraction_heat_load_served
            htg_fraction += hvac_system.fraction_heat_load_served
          end
          if hvac_system.respond_to? :fraction_cool_load_served
            clg_fraction += hvac_system.fraction_cool_load_served
          end
        end
        hvac_frac = (htg_fraction + clg_fraction) / 2.0

        supply_ducts = hvac_distribution.ducts.select { |duct| duct.duct_type == HPXML::DuctTypeSupply }
        return_ducts = hvac_distribution.ducts.select { |duct| duct.duct_type == HPXML::DuctTypeReturn }
        total_supply_fraction = supply_ducts.map { |d| d.duct_fraction_area }.sum / hvac_distribution.ducts.map { |d| d.duct_fraction_area }.sum
        total_return_fraction = return_ducts.map { |d| d.duct_fraction_area }.sum / hvac_distribution.ducts.map { |d| d.duct_fraction_area }.sum
        hvac_distribution.ducts.each do |duct|
          supply_or_return_fraction = (duct.duct_type == HPXML::DuctTypeSupply) ? total_supply_fraction : total_return_fraction
          duct_loc_fracs[duct.duct_location] = 0.0 if duct_loc_fracs[duct.duct_location].nil?
          duct_loc_fracs[duct.duct_location] += duct.duct_fraction_area * supply_or_return_fraction * hvac_frac
        end
      end
      sum_duct_hvac_frac = duct_loc_fracs.empty? ? 0.0 : duct_loc_fracs.values.sum
      if sum_duct_hvac_frac > 1.0001 # Using 1.0001 to allow small tolerance on sum
        fail "Unexpected sum of duct fractions: #{sum_duct_hvac_frac}."
      elsif sum_duct_hvac_frac < 1.0 # i.e., there is at least one ductless system
        # Add 1.0 - sum_duct_hvac_frac as ducts in conditioned space.
        # This will ensure ductless systems have same result as ducts in conditioned space.
        duct_loc_fracs[HPXML::LocationConditionedSpace] = 0.0 if duct_loc_fracs[HPXML::LocationConditionedSpace].nil?
        duct_loc_fracs[HPXML::LocationConditionedSpace] += 1.0 - sum_duct_hvac_frac
      end

      # Foundation type fractions
      fnd_type_fracs = {}
      hpxml_bldg.foundations.each do |foundation|
        fnd_type_fracs[foundation.foundation_type] = 0.0 if fnd_type_fracs[foundation.foundation_type].nil?
        area = (hpxml_bldg.floors + hpxml_bldg.slabs).select { |surface| surface.interior_adjacent_to == foundation.to_location }.map { |surface| surface.area }.sum
        fnd_type_fracs[foundation.foundation_type] += area
      end
      sum_fnd_area = fnd_type_fracs.values.sum(0.0)
      fnd_type_fracs.keys.each do |foundation_type|
        # Convert to fractions that sum to 1
        fnd_type_fracs[foundation_type] /= sum_fnd_area unless sum_fnd_area == 0.0
      end

      ach50 = get_infiltration_ach50(cfa, ncfl_ag, year_built, avg_ceiling_height, infil_volume, iecc_cz, fnd_type_fracs, duct_loc_fracs, infil_measurement.leakiness_description)
      infil_measurement.house_pressure = 50
      infil_measurement.house_pressure_isdefaulted = true
      infil_measurement.unit_of_measure = HPXML::UnitsACH
      infil_measurement.unit_of_measure_isdefaulted = true
      infil_measurement.air_leakage = ach50
      infil_measurement.air_leakage_isdefaulted = true
      infil_measurement.infiltration_type = HPXML::InfiltrationTypeUnitTotal
      infil_measurement.infiltration_type_isdefaulted = true
    end
    if infil_measurement.a_ext.nil?
      if (infil_measurement.infiltration_type == HPXML::InfiltrationTypeUnitTotal) &&
         [HPXML::ResidentialTypeApartment, HPXML::ResidentialTypeSFA].include?(hpxml_bldg.building_construction.residential_facility_type)
        tot_cb_area, ext_cb_area = get_compartmentalization_boundary_areas(hpxml_bldg)
        infil_measurement.a_ext = (ext_cb_area / tot_cb_area).round(5)
        infil_measurement.a_ext_isdefaulted = true
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::Roof objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_roofs(hpxml_bldg)
    hpxml_bldg.roofs.each do |roof|
      if roof.azimuth.nil?
        roof.azimuth = get_azimuth_from_orientation(roof.orientation)
        roof.azimuth_isdefaulted = true
      end
      if roof.orientation.nil?
        roof.orientation = get_orientation_from_azimuth(roof.azimuth)
        roof.orientation_isdefaulted = true
      end
      if roof.roof_type.nil?
        roof.roof_type = HPXML::RoofTypeAsphaltShingles
        roof.roof_type_isdefaulted = true
      end
      if roof.emittance.nil?
        roof.emittance = 0.90
        roof.emittance_isdefaulted = true
      end
      if roof.radiant_barrier.nil?
        if [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented].include?(roof.interior_adjacent_to)
          roof.radiant_barrier = false
          roof.radiant_barrier_isdefaulted = true
        end
      end
      if roof.radiant_barrier && roof.radiant_barrier_grade.nil?
        roof.radiant_barrier_grade = 1
        roof.radiant_barrier_grade_isdefaulted = true
      end
      if roof.roof_color.nil? && roof.solar_absorptance.nil?
        roof.roof_color = HPXML::ColorMedium
        roof.roof_color_isdefaulted = true
      end
      if roof.roof_color.nil?
        roof.roof_color = get_roof_color(roof)
        roof.roof_color_isdefaulted = true
      elsif roof.solar_absorptance.nil?
        roof.solar_absorptance = get_roof_solar_absorptance(roof)
        roof.solar_absorptance_isdefaulted = true
      end
      if roof.interior_finish_type.nil?
        if HPXML::conditioned_finished_locations.include? roof.interior_adjacent_to
          roof.interior_finish_type = HPXML::InteriorFinishGypsumBoard
        else
          roof.interior_finish_type = HPXML::InteriorFinishNone
        end
        roof.interior_finish_type_isdefaulted = true
      end
      next unless roof.interior_finish_thickness.nil?

      if roof.interior_finish_type != HPXML::InteriorFinishNone
        roof.interior_finish_thickness = 0.5
        roof.interior_finish_thickness_isdefaulted = true
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::RimJoist objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_rim_joists(hpxml_bldg)
    hpxml_bldg.rim_joists.each do |rim_joist|
      if rim_joist.azimuth.nil?
        rim_joist.azimuth = get_azimuth_from_orientation(rim_joist.orientation)
        rim_joist.azimuth_isdefaulted = true
      end
      if rim_joist.orientation.nil?
        rim_joist.orientation = get_orientation_from_azimuth(rim_joist.azimuth)
        rim_joist.orientation_isdefaulted = true
      end

      next unless rim_joist.is_exterior

      if rim_joist.emittance.nil?
        rim_joist.emittance = 0.90
        rim_joist.emittance_isdefaulted = true
      end
      if rim_joist.siding.nil?
        rim_joist.siding = HPXML::SidingTypeWood
        rim_joist.siding_isdefaulted = true
      end
      if rim_joist.color.nil? && rim_joist.solar_absorptance.nil?
        rim_joist.color = HPXML::ColorMedium
        rim_joist.color_isdefaulted = true
      end
      if rim_joist.color.nil?
        rim_joist.color = get_wall_color(rim_joist)
        rim_joist.color_isdefaulted = true
      elsif rim_joist.solar_absorptance.nil?
        rim_joist.solar_absorptance = get_wall_solar_absorptance(rim_joist)
        rim_joist.solar_absorptance_isdefaulted = true
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::Wall objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_walls(hpxml_bldg)
    hpxml_bldg.walls.each do |wall|
      if wall.azimuth.nil?
        wall.azimuth = get_azimuth_from_orientation(wall.orientation)
        wall.azimuth_isdefaulted = true
      end
      if wall.orientation.nil?
        wall.orientation = get_orientation_from_azimuth(wall.azimuth)
        wall.orientation_isdefaulted = true
      end

      if wall.is_exterior
        if wall.emittance.nil?
          wall.emittance = 0.90
          wall.emittance_isdefaulted = true
        end
        if wall.siding.nil?
          wall.siding = HPXML::SidingTypeWood
          wall.siding_isdefaulted = true
        end
        if wall.color.nil? && wall.solar_absorptance.nil?
          wall.color = HPXML::ColorMedium
          wall.color_isdefaulted = true
        end
        if wall.color.nil?
          wall.color = get_wall_color(wall)
          wall.color_isdefaulted = true
        elsif wall.solar_absorptance.nil?
          wall.solar_absorptance = get_wall_solar_absorptance(wall)
          wall.solar_absorptance_isdefaulted = true
        end
      end
      if wall.interior_finish_type.nil?
        if HPXML::conditioned_finished_locations.include? wall.interior_adjacent_to
          wall.interior_finish_type = HPXML::InteriorFinishGypsumBoard
        else
          wall.interior_finish_type = HPXML::InteriorFinishNone
        end
        wall.interior_finish_type_isdefaulted = true
      end
      next unless wall.interior_finish_thickness.nil?

      if wall.interior_finish_type != HPXML::InteriorFinishNone
        wall.interior_finish_thickness = 0.5
        wall.interior_finish_thickness_isdefaulted = true
      end
      if wall.radiant_barrier.nil?
        if [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented].include?(wall.interior_adjacent_to) || [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented].include?(wall.exterior_adjacent_to)
          wall.radiant_barrier = false
          wall.radiant_barrier_isdefaulted = true
        end
      end
      if wall.radiant_barrier && wall.radiant_barrier_grade.nil?
        wall.radiant_barrier_grade = 1
        wall.radiant_barrier_grade_isdefaulted = true
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::FoundationWall objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_foundation_walls(hpxml_bldg)
    hpxml_bldg.foundation_walls.each do |foundation_wall|
      if foundation_wall.type.nil?
        foundation_wall.type = HPXML::FoundationWallTypeSolidConcrete
        foundation_wall.type_isdefaulted = true
      end
      if foundation_wall.azimuth.nil?
        foundation_wall.azimuth = get_azimuth_from_orientation(foundation_wall.orientation)
        foundation_wall.azimuth_isdefaulted = true
      end
      if foundation_wall.orientation.nil?
        foundation_wall.orientation = get_orientation_from_azimuth(foundation_wall.azimuth)
        foundation_wall.orientation_isdefaulted = true
      end
      if foundation_wall.thickness.nil?
        foundation_wall.thickness = 8.0
        foundation_wall.thickness_isdefaulted = true
      end
      if foundation_wall.area.nil?
        foundation_wall.area = foundation_wall.length * foundation_wall.height
        foundation_wall.area_isdefaulted = true
      end
      if foundation_wall.interior_finish_type.nil?
        if HPXML::conditioned_finished_locations.include? foundation_wall.interior_adjacent_to
          foundation_wall.interior_finish_type = HPXML::InteriorFinishGypsumBoard
        else
          foundation_wall.interior_finish_type = HPXML::InteriorFinishNone
        end
        foundation_wall.interior_finish_type_isdefaulted = true
      end
      if foundation_wall.insulation_interior_distance_to_top.nil?
        foundation_wall.insulation_interior_distance_to_top = 0.0
        foundation_wall.insulation_interior_distance_to_top_isdefaulted = true
      end
      if foundation_wall.insulation_interior_distance_to_bottom.nil?
        foundation_wall.insulation_interior_distance_to_bottom = foundation_wall.height
        foundation_wall.insulation_interior_distance_to_bottom_isdefaulted = true
      end
      if foundation_wall.insulation_exterior_distance_to_top.nil?
        foundation_wall.insulation_exterior_distance_to_top = 0.0
        foundation_wall.insulation_exterior_distance_to_top_isdefaulted = true
      end
      if foundation_wall.insulation_exterior_distance_to_bottom.nil?
        foundation_wall.insulation_exterior_distance_to_bottom = foundation_wall.height
        foundation_wall.insulation_exterior_distance_to_bottom_isdefaulted = true
      end
      next unless foundation_wall.interior_finish_thickness.nil?

      if foundation_wall.interior_finish_type != HPXML::InteriorFinishNone
        foundation_wall.interior_finish_thickness = 0.5
        foundation_wall.interior_finish_thickness_isdefaulted = true
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::Floor objects
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_floors(runner, hpxml_bldg)
    hpxml_bldg.floors.each do |floor|
      if floor.floor_or_ceiling.nil?
        if floor.is_ceiling
          floor.floor_or_ceiling = HPXML::FloorOrCeilingCeiling
          floor.floor_or_ceiling_isdefaulted = true
        elsif floor.is_floor
          floor.floor_or_ceiling = HPXML::FloorOrCeilingFloor
          floor.floor_or_ceiling_isdefaulted = true
        end
      else
        floor_is_ceiling = HPXML::is_floor_a_ceiling(floor, false)
        if not floor_is_ceiling.nil?
          if (floor.floor_or_ceiling == HPXML::FloorOrCeilingCeiling) && !floor_is_ceiling
            runner.registerWarning("Floor '#{floor.id}' has FloorOrCeiling=ceiling but it should be floor. The input will be overridden.")
            floor.floor_or_ceiling = HPXML::FloorOrCeilingFloor
            floor.floor_or_ceiling_isdefaulted = true
          elsif (floor.floor_or_ceiling == HPXML::FloorOrCeilingFloor) && floor_is_ceiling
            runner.registerWarning("Floor '#{floor.id}' has FloorOrCeiling=floor but it should be ceiling. The input will be overridden.")
            floor.floor_or_ceiling = HPXML::FloorOrCeilingCeiling
            floor.floor_or_ceiling_isdefaulted = true
          end
        end
      end

      if floor.interior_finish_type.nil?
        if floor.is_floor
          floor.interior_finish_type = HPXML::InteriorFinishNone
        elsif HPXML::conditioned_finished_locations.include? floor.interior_adjacent_to
          floor.interior_finish_type = HPXML::InteriorFinishGypsumBoard
        else
          floor.interior_finish_type = HPXML::InteriorFinishNone
        end
        floor.interior_finish_type_isdefaulted = true
      end
      next unless floor.interior_finish_thickness.nil?

      if floor.interior_finish_type != HPXML::InteriorFinishNone
        floor.interior_finish_thickness = 0.5
        floor.interior_finish_thickness_isdefaulted = true
      end
      if floor.radiant_barrier.nil?
        if [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented].include?(floor.interior_adjacent_to) || [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented].include?(floor.exterior_adjacent_to)
          floor.radiant_barrier = false
          floor.radiant_barrier_isdefaulted = true
        end
      end
      if floor.radiant_barrier && floor.radiant_barrier_grade.nil?
        floor.radiant_barrier_grade = 1
        floor.radiant_barrier_grade_isdefaulted = true
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::Slab objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_slabs(hpxml_bldg)
    hpxml_bldg.slabs.each do |slab|
      if slab.thickness.nil?
        crawl_slab = [HPXML::LocationCrawlspaceVented, HPXML::LocationCrawlspaceUnvented].include?(slab.interior_adjacent_to)
        slab.thickness = crawl_slab ? 0.0 : 4.0
        slab.thickness_isdefaulted = true
      end
      if slab.gap_insulation_r_value.nil?
        slab.gap_insulation_r_value = slab.under_slab_insulation_r_value > 0 ? 5.0 : 0.0
        slab.gap_insulation_r_value_isdefaulted = true
      end
      conditioned_slab = HPXML::conditioned_finished_locations.include?(slab.interior_adjacent_to)
      if slab.carpet_r_value.nil?
        slab.carpet_r_value = conditioned_slab ? 2.0 : 0.0
        slab.carpet_r_value_isdefaulted = true
      end
      if slab.carpet_fraction.nil?
        slab.carpet_fraction = conditioned_slab ? 0.8 : 0.0
        slab.carpet_fraction_isdefaulted = true
      end
      if slab.connected_foundation_walls.empty?
        if slab.depth_below_grade.nil?
          slab.depth_below_grade = 0.0
          slab.depth_below_grade_isdefaulted = true
        end
      else
        if !slab.depth_below_grade.nil?
          slab.depth_below_grade = nil # Ignore Slab/DepthBelowGrade; use values from adjacent foundation walls instead
        end
      end
      if slab.exterior_horizontal_insulation_r_value.nil?
        slab.exterior_horizontal_insulation_r_value = 0.0
        slab.exterior_horizontal_insulation_r_value_isdefaulted = true
      end
      if slab.exterior_horizontal_insulation_width.nil?
        slab.exterior_horizontal_insulation_width = 0.0
        slab.exterior_horizontal_insulation_width_isdefaulted = true
      end
      if slab.exterior_horizontal_insulation_depth_below_grade.nil?
        slab.exterior_horizontal_insulation_depth_below_grade = 0.0
        slab.exterior_horizontal_insulation_depth_below_grade_isdefaulted = true
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::Window objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @return [nil]
  def self.apply_windows(hpxml_bldg, eri_version)
    blinds_types = [HPXML::InteriorShadingTypeDarkBlinds,
                    HPXML::InteriorShadingTypeMediumBlinds,
                    HPXML::InteriorShadingTypeLightBlinds]

    hpxml_bldg.windows.each do |window|
      if window.ufactor.nil? || window.shgc.nil?
        if window.glass_layers != HPXML::WindowLayersGlassBlock
          # Frame/Glass provided instead, fill in more defaults as needed
          if window.glass_type.nil?
            window.glass_type = HPXML::WindowGlassTypeClear
            window.glass_type_isdefaulted = true
          end
          if window.thermal_break.nil? && [HPXML::WindowFrameTypeAluminum, HPXML::WindowFrameTypeMetal].include?(window.frame_type)
            if window.glass_layers == HPXML::WindowLayersSinglePane
              window.thermal_break = false
              window.thermal_break_isdefaulted = true
            elsif window.glass_layers == HPXML::WindowLayersDoublePane
              window.thermal_break = true
              window.thermal_break_isdefaulted = true
            end
          end
          if window.gas_fill.nil?
            if window.glass_layers == HPXML::WindowLayersDoublePane
              if [HPXML::WindowGlassTypeLowE,
                  HPXML::WindowGlassTypeLowEHighSolarGain,
                  HPXML::WindowGlassTypeLowELowSolarGain].include? window.glass_type
                window.gas_fill = HPXML::WindowGasArgon
                window.gas_fill_isdefaulted = true
              else
                window.gas_fill = HPXML::WindowGasAir
                window.gas_fill_isdefaulted = true
              end
            elsif window.glass_layers == HPXML::WindowLayersTriplePane
              window.gas_fill = HPXML::WindowGasArgon
              window.gas_fill_isdefaulted = true
            end
          end
        end
        # Now lookup U/SHGC based on properties
        ufactor, shgc = get_window_ufactor_shgc(window)
        if window.ufactor.nil?
          window.ufactor = ufactor
          window.ufactor_isdefaulted = true
        end
        if window.shgc.nil?
          window.shgc = shgc
          window.shgc_isdefaulted = true
        end
      end
      if window.azimuth.nil?
        window.azimuth = get_azimuth_from_orientation(window.orientation)
        window.azimuth_isdefaulted = true
      end
      if window.orientation.nil?
        window.orientation = get_orientation_from_azimuth(window.azimuth)
        window.orientation_isdefaulted = true
      end
      if window.interior_shading_factor_winter.nil? || window.interior_shading_factor_summer.nil?
        if window.interior_shading_type.nil?
          if window.glass_layers == HPXML::WindowLayersGlassBlock
            window.interior_shading_type = HPXML::InteriorShadingTypeNone
          else
            window.interior_shading_type = HPXML::InteriorShadingTypeLightCurtains # ANSI/RESNET/ICC 301-2022
          end
          window.interior_shading_type_isdefaulted = true
        end
        if window.interior_shading_coverage_summer.nil? && window.interior_shading_type != HPXML::InteriorShadingTypeNone
          if blinds_types.include? window.interior_shading_type
            window.interior_shading_coverage_summer = 1.0
          else
            window.interior_shading_coverage_summer = 0.5 # ANSI/RESNET/ICC 301-2022
          end
          window.interior_shading_coverage_summer_isdefaulted = true
        end
        if window.interior_shading_coverage_winter.nil? && window.interior_shading_type != HPXML::InteriorShadingTypeNone
          if blinds_types.include? window.interior_shading_type
            window.interior_shading_coverage_winter = 1.0
          else
            window.interior_shading_coverage_winter = 0.5 # ANSI/RESNET/ICC 301-2022
          end
          window.interior_shading_coverage_winter_isdefaulted = true
        end
        if blinds_types.include? window.interior_shading_type
          if window.interior_shading_blinds_summer_closed_or_open.nil?
            window.interior_shading_blinds_summer_closed_or_open = HPXML::BlindsHalfOpen
            window.interior_shading_blinds_summer_closed_or_open_isdefaulted = true
          end
          if window.interior_shading_blinds_winter_closed_or_open.nil?
            window.interior_shading_blinds_winter_closed_or_open = HPXML::BlindsHalfOpen
            window.interior_shading_blinds_winter_closed_or_open_isdefaulted = true
          end
        end
        default_int_sf_summer, default_int_sf_winter = get_window_interior_shading_factors(
          window.interior_shading_type,
          window.shgc,
          window.interior_shading_coverage_summer,
          window.interior_shading_coverage_winter,
          window.interior_shading_blinds_summer_closed_or_open,
          window.interior_shading_blinds_winter_closed_or_open,
          eri_version
        )
        if window.interior_shading_factor_summer.nil? && (not default_int_sf_summer.nil?)
          window.interior_shading_factor_summer = default_int_sf_summer
          window.interior_shading_factor_summer_isdefaulted = true
        end
        if window.interior_shading_factor_winter.nil? && (not default_int_sf_winter.nil?)
          window.interior_shading_factor_winter = default_int_sf_winter
          window.interior_shading_factor_winter_isdefaulted = true
        end
      end
      if window.exterior_shading_factor_winter.nil? || window.exterior_shading_factor_summer.nil?
        if window.exterior_shading_type.nil?
          window.exterior_shading_type = HPXML::ExteriorShadingTypeNone
          window.exterior_shading_type_isdefaulted = true
        end
        if window.exterior_shading_coverage_summer.nil? && window.exterior_shading_type != HPXML::ExteriorShadingTypeNone
          window.exterior_shading_coverage_summer = {
            HPXML::ExteriorShadingTypeExternalOverhangs => 1.0, # Assume window area fully shaded
            HPXML::ExteriorShadingTypeAwnings => 1.0, # Assume fully shaded
            HPXML::ExteriorShadingTypeBuilding => 0.5, # Assume half shaded
            HPXML::ExteriorShadingTypeDeciduousTree => 0.5, # Assume half shaded
            HPXML::ExteriorShadingTypeEvergreenTree => 0.5, # Assume half shaded
            HPXML::ExteriorShadingTypeOther => 0.5, # Assume half shaded
            HPXML::ExteriorShadingTypeSolarFilm => 1.0, # Assume fully shaded
            HPXML::ExteriorShadingTypeSolarScreens => 1.0 # Assume fully shaded
          }[window.exterior_shading_type]
          window.exterior_shading_coverage_summer_isdefaulted = true
        end
        if window.exterior_shading_coverage_winter.nil? && window.exterior_shading_type != HPXML::ExteriorShadingTypeNone
          window.exterior_shading_coverage_winter = {
            HPXML::ExteriorShadingTypeExternalOverhangs => 1.0, # Assume window area fully shaded
            HPXML::ExteriorShadingTypeAwnings => 1.0, # Assume window area fully shaded
            HPXML::ExteriorShadingTypeBuilding => 0.5, # Assume window area half shaded
            HPXML::ExteriorShadingTypeDeciduousTree => 0.25, # Assume window area quarter shaded
            HPXML::ExteriorShadingTypeEvergreenTree => 0.5, # Assume window area half shaded
            HPXML::ExteriorShadingTypeOther => 0.5, # Assume window area half shaded
            HPXML::ExteriorShadingTypeSolarFilm => 1.0, # Assume window area fully shaded
            HPXML::ExteriorShadingTypeSolarScreens => 1.0 # Assume window area fully shaded
          }[window.exterior_shading_type]
          window.exterior_shading_coverage_winter_isdefaulted = true
        end
        default_ext_sf_summer, default_ext_sf_winter = get_window_exterior_shading_factors(window, hpxml_bldg)
        if window.exterior_shading_factor_summer.nil? && (not default_ext_sf_summer.nil?)
          window.exterior_shading_factor_summer = default_ext_sf_summer
          window.exterior_shading_factor_summer_isdefaulted = true
        end
        if window.exterior_shading_factor_winter.nil? && (not default_ext_sf_winter.nil?)
          window.exterior_shading_factor_winter = default_ext_sf_winter
          window.exterior_shading_factor_winter_isdefaulted = true
        end
      end
      if window.fraction_operable.nil?
        window.fraction_operable = get_fraction_of_windows_operable()
        window.fraction_operable_isdefaulted = true
      end
      next unless window.insect_screen_present

      if window.insect_screen_location.nil?
        window.insect_screen_location = HPXML::LocationExterior
        window.insect_screen_location_isdefaulted = true
      end
      if window.insect_screen_coverage_summer.nil?
        window.insect_screen_coverage_summer = window.fraction_operable
        window.insect_screen_coverage_summer_isdefaulted = true
      end
      if window.insect_screen_coverage_winter.nil?
        window.insect_screen_coverage_winter = window.fraction_operable
        window.insect_screen_coverage_winter_isdefaulted = true
      end
      default_is_sf_summer, default_is_sf_winter = get_window_insect_screen_factors(window)
      if window.insect_screen_factor_summer.nil?
        window.insect_screen_factor_summer = default_is_sf_summer
        window.insect_screen_factor_summer_isdefaulted = true
      end
      if window.insect_screen_factor_winter.nil?
        window.insect_screen_factor_winter = default_is_sf_winter
        window.insect_screen_factor_winter_isdefaulted = true
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::Skylight objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_skylights(hpxml_bldg)
    hpxml_bldg.skylights.each do |skylight|
      if skylight.azimuth.nil?
        skylight.azimuth = get_azimuth_from_orientation(skylight.orientation)
        skylight.azimuth_isdefaulted = true
      end
      if skylight.orientation.nil?
        skylight.orientation = get_orientation_from_azimuth(skylight.azimuth)
        skylight.orientation_isdefaulted = true
      end
      if skylight.interior_shading_factor_summer.nil?
        skylight.interior_shading_factor_summer = 1.0
        skylight.interior_shading_factor_summer_isdefaulted = true
      end
      if skylight.interior_shading_factor_winter.nil?
        skylight.interior_shading_factor_winter = 1.0
        skylight.interior_shading_factor_winter_isdefaulted = true
      end
      if skylight.exterior_shading_factor_summer.nil?
        skylight.exterior_shading_factor_summer = 1.0
        skylight.exterior_shading_factor_summer_isdefaulted = true
      end
      if skylight.exterior_shading_factor_winter.nil?
        skylight.exterior_shading_factor_winter = 1.0
        skylight.exterior_shading_factor_winter_isdefaulted = true
      end
      next unless skylight.ufactor.nil? || skylight.shgc.nil?

      if skylight.glass_layers != HPXML::WindowLayersGlassBlock
        # Frame/Glass provided instead, fill in more defaults as needed
        if skylight.glass_type.nil?
          skylight.glass_type = HPXML::WindowGlassTypeClear
          skylight.glass_type_isdefaulted = true
        end
        if skylight.thermal_break.nil? && [HPXML::WindowFrameTypeAluminum, HPXML::WindowFrameTypeMetal].include?(skylight.frame_type)
          if skylight.glass_layers == HPXML::WindowLayersSinglePane
            skylight.thermal_break = false
            skylight.thermal_break_isdefaulted = true
          elsif skylight.glass_layers == HPXML::WindowLayersDoublePane
            skylight.thermal_break = true
            skylight.thermal_break_isdefaulted = true
          end
        end
        if skylight.gas_fill.nil?
          if skylight.glass_layers == HPXML::WindowLayersDoublePane
            if [HPXML::WindowGlassTypeLowE,
                HPXML::WindowGlassTypeLowEHighSolarGain,
                HPXML::WindowGlassTypeLowELowSolarGain].include? skylight.glass_type
              skylight.gas_fill = HPXML::WindowGasArgon
              skylight.gas_fill_isdefaulted = true
            else
              skylight.gas_fill = HPXML::WindowGasAir
              skylight.gas_fill_isdefaulted = true
            end
          elsif skylight.glass_layers == HPXML::WindowLayersTriplePane
            skylight.gas_fill = HPXML::WindowGasArgon
            skylight.gas_fill_isdefaulted = true
          end
        end
      end
      # Now lookup U/SHGC based on properties
      ufactor, shgc = get_window_ufactor_shgc(skylight)
      if skylight.ufactor.nil?
        skylight.ufactor = ufactor
        skylight.ufactor_isdefaulted = true
      end
      if skylight.shgc.nil?
        skylight.shgc = shgc
        skylight.shgc_isdefaulted = true
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::Door objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_doors(hpxml_bldg)
    hpxml_bldg.doors.each do |door|
      if door.azimuth.nil?
        door.azimuth = get_azimuth_from_orientation(door.orientation)
        door.azimuth_isdefaulted = true
      end
      if door.orientation.nil?
        door.orientation = get_orientation_from_azimuth(door.azimuth)
        door.orientation_isdefaulted = true
      end

      next unless door.azimuth.nil?

      if (not door.wall.nil?) && (not door.wall.azimuth.nil?)
        door.azimuth = door.wall.azimuth
      else
        primary_azimuth = get_azimuths(hpxml_bldg)[0]
        door.azimuth = primary_azimuth
        door.azimuth_isdefaulted = true
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::PartitionWallMass object
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_partition_wall_mass(hpxml_bldg)
    if hpxml_bldg.partition_wall_mass.area_fraction.nil?
      hpxml_bldg.partition_wall_mass.area_fraction = 1.0
      hpxml_bldg.partition_wall_mass.area_fraction_isdefaulted = true
    end
    if hpxml_bldg.partition_wall_mass.interior_finish_type.nil?
      hpxml_bldg.partition_wall_mass.interior_finish_type = HPXML::InteriorFinishGypsumBoard
      hpxml_bldg.partition_wall_mass.interior_finish_type_isdefaulted = true
    end
    if hpxml_bldg.partition_wall_mass.interior_finish_thickness.nil?
      hpxml_bldg.partition_wall_mass.interior_finish_thickness = 0.5
      hpxml_bldg.partition_wall_mass.interior_finish_thickness_isdefaulted = true
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::FurnitureMass object
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_furniture_mass(hpxml_bldg)
    if hpxml_bldg.furniture_mass.area_fraction.nil?
      hpxml_bldg.furniture_mass.area_fraction = 0.4
      hpxml_bldg.furniture_mass.area_fraction_isdefaulted = true
    end
    if hpxml_bldg.furniture_mass.type.nil?
      hpxml_bldg.furniture_mass.type = HPXML::FurnitureMassTypeLightWeight
      hpxml_bldg.furniture_mass.type_isdefaulted = true
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::HeatingSystem,
  # HPXML::CoolingSystem, and HPXML::HeatPump objects
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param convert_shared_systems [Boolean] Whether to convert shared systems to equivalent in-unit systems per ANSI/RESNET/ICC 301
  # @param unit_num [Integer] Dwelling unit number
  # @param hpxml_header [HPXML::Header] HPXML Header object
  # @return [nil]
  def self.apply_hvac(runner, hpxml_bldg, weather, convert_shared_systems, unit_num, hpxml_header)
    if convert_shared_systems
      apply_shared_systems(hpxml_bldg)
    end

    # Convert negative values (e.g., -1) to nil as appropriate
    # This is needed to support autosizing in OS-ERI, where the capacities are required inputs
    hpxml_bldg.hvac_systems.each do |hvac_system|
      if hvac_system.respond_to?(:cooling_detailed_performance_data) && (not hvac_system.cooling_detailed_performance_data.empty?) && (hvac_system.respond_to?(:cooling_capacity) && hvac_system.cooling_capacity.nil?)
        hvac_system.cooling_capacity = hvac_system.cooling_detailed_performance_data.find { |dp| (dp.outdoor_temperature == HVAC::AirSourceCoolRatedODB) && (dp.capacity_description == HPXML::CapacityDescriptionNominal) }.capacity
      end
      if hvac_system.respond_to?(:heating_detailed_performance_data) && (not hvac_system.heating_detailed_performance_data.empty?) && (hvac_system.respond_to?(:heating_capacity) && hvac_system.heating_capacity.nil?)
        hvac_system.heating_capacity = hvac_system.heating_detailed_performance_data.find { |dp| (dp.outdoor_temperature == HVAC::AirSourceHeatRatedODB) && (dp.capacity_description == HPXML::CapacityDescriptionNominal) }.capacity
      end

      if hvac_system.respond_to?(:heating_capacity) && hvac_system.heating_capacity.to_f < 0
        hvac_system.heating_capacity = nil
      end
      if hvac_system.respond_to?(:cooling_capacity) && hvac_system.cooling_capacity.to_f < 0
        hvac_system.cooling_capacity = nil
      end
      if hvac_system.respond_to?(:heating_capacity_17F) && hvac_system.heating_capacity_17F.to_f < 0
        hvac_system.heating_capacity_17F = nil
      end
      if hvac_system.respond_to?(:backup_heating_capacity) && hvac_system.backup_heating_capacity.to_f < 0
        hvac_system.backup_heating_capacity = nil
      end
    end

    # Default equipment type
    (hpxml_bldg.cooling_systems + hpxml_bldg.heat_pumps).each do |hvac_system|
      next unless hvac_system.equipment_type.nil?

      if hvac_system.is_a?(HPXML::CoolingSystem)
        next unless [HPXML::HVACTypeCentralAirConditioner,
                     HPXML::HVACTypeMiniSplitAirConditioner].include? hvac_system.cooling_system_type
      elsif hvac_system.is_a?(HPXML::HeatPump)
        next unless [HPXML::HVACTypeHeatPumpAirToAir,
                     HPXML::HVACTypeHeatPumpMiniSplit].include? hvac_system.heat_pump_type
      end

      hvac_system.equipment_type = HPXML::HVACEquipmentTypeSplit
      hvac_system.equipment_type_isdefaulted = true
    end

    # Convert SEER/EER/HSPF to SEER2/EER2/HSPF2
    (hpxml_bldg.cooling_systems + hpxml_bldg.heat_pumps).each do |hvac_system|
      if hvac_system.is_a?(HPXML::CoolingSystem)
        next unless [HPXML::HVACTypeCentralAirConditioner,
                     HPXML::HVACTypeMiniSplitAirConditioner].include? hvac_system.cooling_system_type
      elsif hvac_system.is_a?(HPXML::HeatPump)
        next unless [HPXML::HVACTypeHeatPumpAirToAir,
                     HPXML::HVACTypeHeatPumpMiniSplit].include? hvac_system.heat_pump_type
      end
      if hvac_system.cooling_efficiency_seer2.nil?
        hvac_system.cooling_efficiency_seer2 = HVAC.calc_seer2_from_seer(hvac_system).round(2)
        hvac_system.cooling_efficiency_seer2_isdefaulted = true
        hvac_system.cooling_efficiency_seer = nil
      end
      next unless hvac_system.cooling_efficiency_eer2.nil? && (not hvac_system.cooling_efficiency_eer.nil?)

      hvac_system.cooling_efficiency_eer2 = HVAC.calc_eer2_from_eer(hvac_system).round(2)
      hvac_system.cooling_efficiency_eer2_isdefaulted = true
      hvac_system.cooling_efficiency_eer = nil
    end
    hpxml_bldg.heat_pumps.each do |heat_pump|
      next unless [HPXML::HVACTypeHeatPumpAirToAir,
                   HPXML::HVACTypeHeatPumpMiniSplit].include? heat_pump.heat_pump_type
      next unless heat_pump.heating_efficiency_hspf2.nil?

      heat_pump.heating_efficiency_hspf2 = HVAC.calc_hspf2_from_hspf(heat_pump).round(2)
      heat_pump.heating_efficiency_hspf2_isdefaulted = true
      heat_pump.heating_efficiency_hspf = nil
    end

    # Convert EER to CEER
    (hpxml_bldg.cooling_systems + hpxml_bldg.heat_pumps).each do |hvac_system|
      next unless HVAC.is_room_dx_hvac_system(hvac_system)
      next unless hvac_system.cooling_efficiency_ceer.nil?

      hvac_system.cooling_efficiency_ceer = HVAC.calc_ceer_from_eer(hvac_system).round(2)
      hvac_system.cooling_efficiency_ceer_isdefaulted = true
      hvac_system.cooling_efficiency_eer = nil
    end

    # Default HVAC autosizing factors
    hpxml_bldg.cooling_systems.each do |cooling_system|
      next unless cooling_system.cooling_autosizing_factor.nil?

      cooling_system.cooling_autosizing_factor = 1.0
      cooling_system.cooling_autosizing_factor_isdefaulted = true
    end
    hpxml_bldg.heating_systems.each do |heating_system|
      next unless heating_system.heating_autosizing_factor.nil?

      heating_system.heating_autosizing_factor = 1.0
      heating_system.heating_autosizing_factor_isdefaulted = true
    end
    hpxml_bldg.heat_pumps.each do |heat_pump|
      if heat_pump.heating_autosizing_factor.nil?
        heat_pump.heating_autosizing_factor = 1.0
        heat_pump.heating_autosizing_factor_isdefaulted = true
      end
      if heat_pump.cooling_autosizing_factor.nil?
        heat_pump.cooling_autosizing_factor = 1.0
        heat_pump.cooling_autosizing_factor_isdefaulted = true
      end
      if (heat_pump.backup_type == HPXML::HeatPumpBackupTypeIntegrated) && heat_pump.backup_heating_autosizing_factor.nil?
        heat_pump.backup_heating_autosizing_factor = 1.0
        heat_pump.backup_heating_autosizing_factor_isdefaulted = true
      end
    end

    # Default AC/HP compressor type
    hpxml_bldg.cooling_systems.each do |cooling_system|
      next unless cooling_system.compressor_type.nil?

      cooling_system.compressor_type = get_hvac_compressor_type(cooling_system)
      cooling_system.compressor_type_isdefaulted = true
    end
    hpxml_bldg.heat_pumps.each do |heat_pump|
      next unless heat_pump.compressor_type.nil?

      heat_pump.compressor_type = get_hvac_compressor_type(heat_pump)
      heat_pump.compressor_type_isdefaulted = true
    end

    # Default HP compressor lockout temp
    hpxml_bldg.heat_pumps.each do |heat_pump|
      next unless heat_pump.compressor_lockout_temp.nil?
      next unless heat_pump.backup_heating_switchover_temp.nil?
      next if heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir

      if heat_pump.backup_type == HPXML::HeatPumpBackupTypeIntegrated
        hp_backup_fuel = heat_pump.backup_heating_fuel
      elsif not heat_pump.backup_system.nil?
        hp_backup_fuel = heat_pump.backup_system.heating_system_fuel
      end

      if (not hp_backup_fuel.nil?) && (hp_backup_fuel != HPXML::FuelTypeElectricity)
        # Fuel backup
        heat_pump.compressor_lockout_temp = 40.0 # F
      else
        # Electric backup or no backup
        if heat_pump.compressor_type == HPXML::HVACCompressorTypeVariableSpeed
          heat_pump.compressor_lockout_temp = -20.0 # F
        else
          heat_pump.compressor_lockout_temp = 0.0 # F
        end
      end
      heat_pump.compressor_lockout_temp_isdefaulted = true
    end

    # Default HP backup lockout temp
    hpxml_bldg.heat_pumps.each do |heat_pump|
      next if heat_pump.backup_type.nil?
      next unless heat_pump.backup_heating_lockout_temp.nil?
      next unless heat_pump.backup_heating_switchover_temp.nil?
      next if heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir

      if heat_pump.backup_type == HPXML::HeatPumpBackupTypeIntegrated
        hp_backup_fuel = heat_pump.backup_heating_fuel
      else
        hp_backup_fuel = heat_pump.backup_system.heating_system_fuel
      end

      if hp_backup_fuel == HPXML::FuelTypeElectricity
        heat_pump.backup_heating_lockout_temp = 40.0 # F
      else
        heat_pump.backup_heating_lockout_temp = 50.0 # F
      end
      heat_pump.backup_heating_lockout_temp_isdefaulted = true
    end

    # Default electric resistance distribution
    hpxml_bldg.heating_systems.each do |heating_system|
      next unless heating_system.heating_system_type == HPXML::HVACTypeElectricResistance
      next unless heating_system.electric_resistance_distribution.nil?

      heating_system.electric_resistance_distribution = HPXML::ElectricResistanceDistributionBaseboard
      heating_system.electric_resistance_distribution_isdefaulted = true
    end

    # Default boiler EAE
    hpxml_bldg.heating_systems.each do |heating_system|
      next unless heating_system.electric_auxiliary_energy.nil?

      heating_system.electric_auxiliary_energy_isdefaulted = true
      heating_system.electric_auxiliary_energy = get_boiler_eae(heating_system)
      heating_system.shared_loop_watts = nil
      heating_system.shared_loop_motor_efficiency = nil
      heating_system.fan_coil_watts = nil
    end

    # GSHP pump power
    hpxml_bldg.heat_pumps.each do |heat_pump|
      next unless heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir
      next unless heat_pump.pump_watts_per_ton.nil?

      heat_pump.pump_watts_per_ton = get_gshp_pump_power()
      heat_pump.pump_watts_per_ton_isdefaulted = true
    end

    # Charge defect ratio
    hpxml_bldg.cooling_systems.each do |cooling_system|
      next unless [HPXML::HVACTypeCentralAirConditioner,
                   HPXML::HVACTypeMiniSplitAirConditioner].include? cooling_system.cooling_system_type
      next unless cooling_system.charge_defect_ratio.nil?

      cooling_system.charge_defect_ratio = 0.0
      cooling_system.charge_defect_ratio_isdefaulted = true
    end
    hpxml_bldg.heat_pumps.each do |heat_pump|
      next unless [HPXML::HVACTypeHeatPumpAirToAir,
                   HPXML::HVACTypeHeatPumpMiniSplit,
                   HPXML::HVACTypeHeatPumpGroundToAir].include? heat_pump.heat_pump_type
      next unless heat_pump.charge_defect_ratio.nil?

      heat_pump.charge_defect_ratio = 0.0
      heat_pump.charge_defect_ratio_isdefaulted = true
    end

    # Airflow defect ratio
    hpxml_bldg.heating_systems.each do |heating_system|
      next unless [HPXML::HVACTypeFurnace].include? heating_system.heating_system_type
      next unless heating_system.airflow_defect_ratio.nil?

      heating_system.airflow_defect_ratio = 0.0
      heating_system.airflow_defect_ratio_isdefaulted = true
    end
    hpxml_bldg.cooling_systems.each do |cooling_system|
      next unless [HPXML::HVACTypeCentralAirConditioner,
                   HPXML::HVACTypeMiniSplitAirConditioner].include? cooling_system.cooling_system_type
      next unless cooling_system.airflow_defect_ratio.nil?

      cooling_system.airflow_defect_ratio = 0.0
      cooling_system.airflow_defect_ratio_isdefaulted = true
    end
    hpxml_bldg.heat_pumps.each do |heat_pump|
      next unless [HPXML::HVACTypeHeatPumpAirToAir,
                   HPXML::HVACTypeHeatPumpGroundToAir,
                   HPXML::HVACTypeHeatPumpMiniSplit].include? heat_pump.heat_pump_type
      next unless heat_pump.airflow_defect_ratio.nil?

      heat_pump.airflow_defect_ratio = 0.0
      heat_pump.airflow_defect_ratio_isdefaulted = true
    end

    # Fan model type
    # Based on RESNET DX Modeling Appendix
    hpxml_bldg.heating_systems.each do |heating_system|
      next unless heating_system.fan_motor_type.nil?
      next unless heating_system.heating_system_type == HPXML::HVACTypeFurnace
      next if (not heating_system.distribution_system.nil?) && (heating_system.distribution_system.air_type == HPXML::AirTypeGravity)

      if (not heating_system.attached_cooling_system.nil?) && (not heating_system.attached_cooling_system.compressor_type.nil?)
        heating_system.fan_motor_type = (heating_system.attached_cooling_system.compressor_type == HPXML::HVACCompressorTypeSingleStage) ? HPXML::HVACFanMotorTypePSC : HPXML::HVACFanMotorTypeBPM
      else
        # Standalone furnace, use HEScore assumption
        heating_system.fan_motor_type = (heating_system.heating_efficiency_afue > 0.9) ? HPXML::HVACFanMotorTypeBPM : HPXML::HVACFanMotorTypePSC
      end
      heating_system.fan_motor_type_isdefaulted = true
    end
    hpxml_bldg.cooling_systems.each do |cooling_system|
      next unless cooling_system.fan_motor_type.nil?
      next unless [HPXML::HVACTypeCentralAirConditioner,
                   HPXML::HVACTypeMiniSplitAirConditioner].include? cooling_system.cooling_system_type

      if (not cooling_system.attached_heating_system.nil?) && (not cooling_system.attached_heating_system.fan_motor_type.nil?)
        cooling_system.fan_motor_type = cooling_system.attached_heating_system.fan_motor_type
      else
        cooling_system.fan_motor_type = (cooling_system.compressor_type == HPXML::HVACCompressorTypeSingleStage) ? HPXML::HVACFanMotorTypePSC : HPXML::HVACFanMotorTypeBPM
      end
      cooling_system.fan_motor_type_isdefaulted = true
    end
    hpxml_bldg.heat_pumps.each do |heat_pump|
      next unless heat_pump.fan_motor_type.nil?
      next unless [HPXML::HVACTypeHeatPumpAirToAir,
                   HPXML::HVACTypeHeatPumpGroundToAir,
                   HPXML::HVACTypeHeatPumpMiniSplit].include? heat_pump.heat_pump_type

      heat_pump.fan_motor_type = (heat_pump.compressor_type == HPXML::HVACCompressorTypeSingleStage) ? HPXML::HVACFanMotorTypePSC : HPXML::HVACFanMotorTypeBPM
      heat_pump.fan_motor_type_isdefaulted = true
    end

    # Fan watts/cfm
    (hpxml_bldg.heating_systems + hpxml_bldg.cooling_systems).each do |hvac_system|
      next unless hvac_system.fan_watts_per_cfm.nil?

      if hvac_system.respond_to?(:attached_heating_system) && (not hvac_system.attached_heating_system.nil?) && (not hvac_system.attached_heating_system.fan_watts_per_cfm.nil?)
        hvac_system.fan_watts_per_cfm = hvac_system.attached_heating_system.fan_watts_per_cfm
        hvac_system.fan_watts_per_cfm_isdefaulted = true
      elsif hvac_system.respond_to?(:attached_cooling_system) && (not hvac_system.attached_cooling_system.nil?) && (not hvac_system.attached_cooling_system.fan_watts_per_cfm.nil?)
        hvac_system.fan_watts_per_cfm = hvac_system.attached_cooling_system.fan_watts_per_cfm
        hvac_system.fan_watts_per_cfm_isdefaulted = true
      end
    end

    psc_watts_per_cfm = 0.5 # W/cfm, PSC fan
    bpm_watts_per_cfm = 0.375 # W/cfm, BPM fan
    mini_split_ductless_watts_per_cfm = 0.07 # W/cfm
    mini_split_ducted_watts_per_cfm = 0.18 # W/cfm

    hpxml_bldg.heating_systems.each do |heating_system|
      case heating_system.heating_system_type
      when HPXML::HVACTypeFurnace
        next unless heating_system.fan_watts_per_cfm.nil?

        if (not heating_system.distribution_system.nil?) && (heating_system.distribution_system.air_type == HPXML::AirTypeGravity)
          heating_system.fan_watts_per_cfm = 0.0
        else
          heating_system.fan_watts_per_cfm = (heating_system.fan_motor_type == HPXML::HVACFanMotorTypePSC) ? psc_watts_per_cfm : bpm_watts_per_cfm
        end
        heating_system.fan_watts_per_cfm_isdefaulted = true
      when HPXML::HVACTypeStove
        next unless heating_system.fan_watts.nil?

        heating_system.fan_watts = 40.0
        heating_system.fan_watts_isdefaulted = true
      when HPXML::HVACTypeWallFurnace, HPXML::HVACTypeFloorFurnace,
           HPXML::HVACTypeSpaceHeater, HPXML::HVACTypeFireplace
        next unless heating_system.fan_watts.nil?

        heating_system.fan_watts = 0.0 # assume no fan power
        heating_system.fan_watts_isdefaulted = true
      end
    end

    hpxml_bldg.cooling_systems.each do |cooling_system|
      case cooling_system.cooling_system_type
      when HPXML::HVACTypeCentralAirConditioner
        next unless cooling_system.fan_watts_per_cfm.nil?

        cooling_system.fan_watts_per_cfm = (cooling_system.fan_motor_type == HPXML::HVACFanMotorTypePSC) ? psc_watts_per_cfm : bpm_watts_per_cfm
        cooling_system.fan_watts_per_cfm_isdefaulted = true
      when HPXML::HVACTypeMiniSplitAirConditioner
        next unless cooling_system.fan_watts_per_cfm.nil?

        cooling_system.fan_watts_per_cfm = cooling_system.distribution_system.nil? ? mini_split_ductless_watts_per_cfm : mini_split_ducted_watts_per_cfm
        cooling_system.fan_watts_per_cfm_isdefaulted = true
      end
    end

    hpxml_bldg.heat_pumps.each do |heat_pump|
      case heat_pump.heat_pump_type
      when HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpGroundToAir
        next unless heat_pump.fan_watts_per_cfm.nil?

        heat_pump.fan_watts_per_cfm = (heat_pump.fan_motor_type == HPXML::HVACFanMotorTypePSC) ? psc_watts_per_cfm : bpm_watts_per_cfm
        heat_pump.fan_watts_per_cfm_isdefaulted = true
      when HPXML::HVACTypeHeatPumpMiniSplit
        next unless heat_pump.fan_watts_per_cfm.nil?

        heat_pump.fan_watts_per_cfm = heat_pump.distribution_system.nil? ? mini_split_ductless_watts_per_cfm : mini_split_ducted_watts_per_cfm
        heat_pump.fan_watts_per_cfm_isdefaulted = true
      end
    end

    # Pilot Light
    hpxml_bldg.heating_systems.each do |heating_system|
      next unless [HPXML::HVACTypeFurnace,
                   HPXML::HVACTypeWallFurnace,
                   HPXML::HVACTypeFloorFurnace,
                   HPXML::HVACTypeFireplace,
                   HPXML::HVACTypeStove,
                   HPXML::HVACTypeBoiler].include? heating_system.heating_system_type

      if heating_system.pilot_light.nil?
        heating_system.pilot_light = false
        heating_system.pilot_light_isdefaulted = true
      end
      if heating_system.pilot_light && heating_system.pilot_light_btuh.nil?
        heating_system.pilot_light_btuh = 500.0
        heating_system.pilot_light_btuh_isdefaulted = true
      end
    end

    # Pan heater
    hpxml_bldg.heat_pumps.each do |heat_pump|
      case heat_pump.heat_pump_type
      when HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpMiniSplit
        if heat_pump.pan_heater_watts.nil?
          if heat_pump.fraction_heat_load_served > 0
            heat_pump.pan_heater_watts = 150.0 # W, per RESNET HERS Addendum 82
          else
            heat_pump.pan_heater_watts = 0.0
          end
          heat_pump.pan_heater_watts_isdefaulted = true
        end
        if heat_pump.pan_heater_control_type.nil? && heat_pump.pan_heater_watts > 0
          heat_pump.pan_heater_control_type = HPXML::HVACPanHeaterControlTypeContinuous # Per RESNET HERS Addendum 82
          heat_pump.pan_heater_control_type_isdefaulted = true
        end
      end
    end

    # Defrost Backup Heat
    hpxml_bldg.heat_pumps.each do |heat_pump|
      next unless heat_pump.backup_heating_active_during_defrost.nil?
      next unless [HPXML::HVACTypeHeatPumpAirToAir,
                   HPXML::HVACTypeHeatPumpMiniSplit,
                   HPXML::HVACTypeHeatPumpRoom,
                   HPXML::HVACTypeHeatPumpPTHP].include? heat_pump.heat_pump_type

      # The input is only used when there's integrated backup heat
      next unless heat_pump.backup_type == HPXML::HeatPumpBackupTypeIntegrated

      heat_pump.backup_heating_active_during_defrost = !heat_pump.distribution_system.nil?
      heat_pump.backup_heating_active_during_defrost_isdefaulted = true
    end

    # EER2
    (hpxml_bldg.cooling_systems + hpxml_bldg.heat_pumps).each do |hvac_system|
      if hvac_system.is_a?(HPXML::CoolingSystem)
        next unless [HPXML::HVACTypeCentralAirConditioner,
                     HPXML::HVACTypeMiniSplitAirConditioner].include? hvac_system.cooling_system_type
      elsif hvac_system.is_a?(HPXML::HeatPump)
        next unless [HPXML::HVACTypeHeatPumpAirToAir,
                     HPXML::HVACTypeHeatPumpMiniSplit].include? hvac_system.heat_pump_type
      end
      next unless hvac_system.cooling_efficiency_eer.nil? && hvac_system.cooling_efficiency_eer2.nil?

      hvac_system.cooling_efficiency_eer2 = get_hvac_eer2(hvac_system).round(2)
      hvac_system.cooling_efficiency_eer2_isdefaulted = true
    end

    # Detailed HVAC performance
    hpxml_bldg.cooling_systems.each do |cooling_system|
      clg_ap = cooling_system.additional_properties
      case cooling_system.cooling_system_type
      when HPXML::HVACTypeCentralAirConditioner, HPXML::HVACTypeMiniSplitAirConditioner,
           HPXML::HVACTypeRoomAirConditioner, HPXML::HVACTypePTAC
        set_hvac_fan_power_rated(cooling_system)
        set_hvac_cooling_performance(cooling_system, hpxml_header)

      when HPXML::HVACTypeEvaporativeCooler
        clg_ap.effectiveness = 0.72 # Assumption from HEScore

      end
    end
    hpxml_bldg.heating_systems.each do |heating_system|
      htg_ap = heating_system.additional_properties
      next unless [HPXML::HVACTypeStove,
                   HPXML::HVACTypeSpaceHeater,
                   HPXML::HVACTypeWallFurnace,
                   HPXML::HVACTypeFloorFurnace,
                   HPXML::HVACTypeFireplace].include? heating_system.heating_system_type

      htg_ap.heat_rated_cfm_per_ton = HVAC::RatedCFMPerTon
    end
    hpxml_bldg.heat_pumps.each do |heat_pump|
      case heat_pump.heat_pump_type
      when HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpMiniSplit,
           HPXML::HVACTypeHeatPumpPTHP, HPXML::HVACTypeHeatPumpRoom
        set_hvac_fan_power_rated(heat_pump)
        set_heat_pump_control_temperatures(heat_pump, runner)
        set_hvac_cooling_performance(heat_pump, hpxml_header)
        set_hvac_heating_performance(heat_pump, hpxml_header)

      when HPXML::HVACTypeHeatPumpGroundToAir
        set_heat_pump_control_temperatures(heat_pump, runner)
        set_hvac_cooling_performance(heat_pump, hpxml_header)
        set_hvac_heating_performance(heat_pump, hpxml_header)

        if heat_pump.geothermal_loop.nil?
          hpxml_bldg.geothermal_loops.add(id: get_id('GeothermalLoop', hpxml_bldg.geothermal_loops, unit_num),
                                          loop_configuration: HPXML::GeothermalLoopLoopConfigurationVertical)
          heat_pump.geothermal_loop_idref = hpxml_bldg.geothermal_loops[-1].id
        end

        if heat_pump.geothermal_loop.pipe_diameter.nil?
          heat_pump.geothermal_loop.pipe_diameter = 1.25 # in
          heat_pump.geothermal_loop.pipe_diameter_isdefaulted = true
        end

        set_geothermal_loop_assumptions(heat_pump, weather)

        if heat_pump.geothermal_loop.bore_spacing.nil?
          heat_pump.geothermal_loop.bore_spacing = 16.4 # ft, distance between bores
          heat_pump.geothermal_loop.bore_spacing_isdefaulted = true
        end

        if heat_pump.geothermal_loop.bore_diameter.nil?
          heat_pump.geothermal_loop.bore_diameter = 5.0 # in
          heat_pump.geothermal_loop.bore_diameter_isdefaulted = true
        end

        if heat_pump.geothermal_loop.grout_type.nil? && heat_pump.geothermal_loop.grout_conductivity.nil?
          heat_pump.geothermal_loop.grout_type = HPXML::GeothermalLoopGroutOrPipeTypeStandard
          heat_pump.geothermal_loop.grout_type_isdefaulted = true
        end

        if heat_pump.geothermal_loop.grout_conductivity.nil?
          if heat_pump.geothermal_loop.grout_type == HPXML::GeothermalLoopGroutOrPipeTypeStandard
            heat_pump.geothermal_loop.grout_conductivity = 0.75 # Btu/h-ft-R
          elsif heat_pump.geothermal_loop.grout_type == HPXML::GeothermalLoopGroutOrPipeTypeThermallyEnhanced
            heat_pump.geothermal_loop.grout_conductivity = 1.2 # Btu/h-ft-R
          end
          heat_pump.geothermal_loop.grout_conductivity_isdefaulted = true
        end

        if heat_pump.geothermal_loop.pipe_type.nil? && heat_pump.geothermal_loop.pipe_conductivity.nil?
          heat_pump.geothermal_loop.pipe_type = HPXML::GeothermalLoopGroutOrPipeTypeStandard
          heat_pump.geothermal_loop.pipe_type_isdefaulted = true
        end

        if heat_pump.geothermal_loop.pipe_conductivity.nil?
          if heat_pump.geothermal_loop.pipe_type == HPXML::GeothermalLoopGroutOrPipeTypeStandard
            heat_pump.geothermal_loop.pipe_conductivity = 0.23 # Btu/h-ft-R; Pipe thermal conductivity, default to high density polyethylene
          elsif heat_pump.geothermal_loop.pipe_type == HPXML::GeothermalLoopGroutOrPipeTypeThermallyEnhanced
            heat_pump.geothermal_loop.pipe_conductivity = 0.40 # Btu/h-ft-R; 0.7 W/m-K from https://www.dropbox.com/scl/fi/91yp8e9v34vdh1isvrfvy/GeoPerformX-Spec-Sheet.pdf?rlkey=kw7p01gs46z9lfjs78bo8aujq&dl=0
          end
          heat_pump.geothermal_loop.pipe_conductivity_isdefaulted = true
        end

        if heat_pump.geothermal_loop.shank_spacing.nil?
          hp_ap = heat_pump.additional_properties
          heat_pump.geothermal_loop.shank_spacing = (hp_ap.u_tube_spacing + hp_ap.pipe_od).round(2) # Distance from center of pipe to center of pipe
          heat_pump.geothermal_loop.shank_spacing_isdefaulted = true
        end
      when HPXML::HVACTypeHeatPumpWaterLoopToAir
        set_heat_pump_control_temperatures(heat_pump, runner)

      end
    end
  end

  # Converts shared systems to equivalent in-unit systems per ANSI/RESNET/ICC 301.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_shared_systems(hpxml_bldg)
    converted_clg = apply_shared_cooling_systems(hpxml_bldg)
    converted_htg = apply_shared_heating_systems(hpxml_bldg)
    return unless (converted_clg || converted_htg)

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

  # Converts shared cooling systems to equivalent in-unit systems per ANSI/RESNET/ICC 301.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [Boolean] True if any shared systems were converted
  def self.apply_shared_cooling_systems(hpxml_bldg)
    converted = false
    hpxml_bldg.cooling_systems.each do |cooling_system|
      next unless cooling_system.is_shared_system

      converted = true
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

    return converted
  end

  # Converts shared heating systems to equivalent in-unit systems per ANSI/RESNET/ICC 301.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [Boolean] True if any shared systems were converted
  def self.apply_shared_heating_systems(hpxml_bldg)
    converted = false
    hpxml_bldg.heating_systems.each do |heating_system|
      next unless heating_system.is_shared_system

      converted = true
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

    return converted
  end

  # Assigns default values for omitted optional inputs in the HPXML::CoolingPerformanceDataPoint
  # and HPXML::HeatingPerformanceDataPoint objects.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_detailed_performance_data(hpxml_bldg)
    (hpxml_bldg.cooling_systems + hpxml_bldg.heat_pumps).each do |hvac_system|
      is_hp = hvac_system.is_a? HPXML::HeatPump
      system_type = is_hp ? hvac_system.heat_pump_type : hvac_system.cooling_system_type
      if [HPXML::HVACTypeHeatPumpPTHP,
          HPXML::HVACTypeHeatPumpRoom].include? system_type
        set_heat_pump_heating_capacity_17F(hvac_system)
        next
      end
      next unless [HPXML::HVACTypeCentralAirConditioner,
                   HPXML::HVACTypeMiniSplitAirConditioner,
                   HPXML::HVACTypeHeatPumpAirToAir,
                   HPXML::HVACTypeHeatPumpMiniSplit].include? system_type

      # Cooling
      if hvac_system.cooling_detailed_performance_data.empty?
        set_detailed_performance_data_cooling(hvac_system)
      else
        expand_detailed_performance_data(:clg, hvac_system)
      end

      next unless is_hp

      # Heating
      if hvac_system.heating_detailed_performance_data.empty?
        set_heat_pump_heating_capacity_17F(hvac_system)
        set_detailed_performance_data_heating(hvac_system)
      else
        expand_detailed_performance_data(:htg, hvac_system)
        set_heat_pump_heating_capacity_17F(hvac_system)
      end
    end
  end

  # This method assigns default values for omitted optional inputs in detailed performance data by:
  # 1. Assigns capacities with fractions.
  # 2. Add the nominal speed capacity and cop calculated with other temperature with nominal speed data
  #
  # @param mode [Symbol] Heating (:htg) or cooling (:clg)
  # @param hvac_system [HPXML::CoolingSystem or HPXML::HeatPump] The HPXML HVAC system of interest
  # @return [nil]
  def self.expand_detailed_performance_data(mode, hvac_system)
    hvac_ap = hvac_system.additional_properties

    if mode == :clg
      detailed_performance_data = hvac_system.cooling_detailed_performance_data
      rated_odb = HVAC::AirSourceCoolRatedODB
      nominal_capacity = hvac_system.cooling_capacity
    elsif mode == :htg
      detailed_performance_data = hvac_system.heating_detailed_performance_data
      rated_odb = HVAC::AirSourceHeatRatedODB
      nominal_capacity = hvac_system.heating_capacity
    end

    # process capacity fraction of nominal
    detailed_performance_data.each do |dp|
      next unless dp.capacity.nil?

      dp.capacity = (dp.capacity_fraction_of_nominal * nominal_capacity).round
      dp.capacity_isdefaulted = true
    end

    all_outdoor_odbs = detailed_performance_data.map { |dp| dp.outdoor_temperature }.uniq.sort

    # All temperatures with nominal speed
    nom_odbs = all_outdoor_odbs.select { |odb| not detailed_performance_data.find { |dp| (dp.outdoor_temperature == odb) && (dp.capacity_description == HPXML::CapacityDescriptionNominal) }.nil? }

    all_outdoor_odbs.each do |odb|
      # no nominal speed data point
      next unless detailed_performance_data.find { |dp| (dp.outdoor_temperature == odb) && (dp.capacity_description == HPXML::CapacityDescriptionNominal) }.nil?

      neighbor_temp = nom_odbs.min_by { |x| (odb - x).abs }
      detailed_performance_data.add(capacity_description: HPXML::CapacityDescriptionNominal,
                                    outdoor_temperature: odb,
                                    isdefaulted: true)
      added_dp = detailed_performance_data[-1]
      neighbor_dps = detailed_performance_data.select { |dp| dp.outdoor_temperature == neighbor_temp }
      target_dps = detailed_performance_data.select { |dp| dp.outdoor_temperature == odb }

      neighbor_dp_max = neighbor_dps.find { |dp| dp.capacity_description == HPXML::CapacityDescriptionMaximum }
      neighbor_dp_nom = neighbor_dps.find { |dp| dp.capacity_description == HPXML::CapacityDescriptionNominal }
      neighbor_dp_min = neighbor_dps.find { |dp| dp.capacity_description == HPXML::CapacityDescriptionMinimum }
      target_dp_max = target_dps.find { |dp| dp.capacity_description == HPXML::CapacityDescriptionMaximum }
      target_dp_min = target_dps.find { |dp| dp.capacity_description == HPXML::CapacityDescriptionMinimum }

      # Net capacity
      case hvac_system.compressor_type
      when HPXML::HVACCompressorTypeTwoStage
        neighbor_nom_capacity = neighbor_dp_nom.capacity
        neighbor_min_capacity = neighbor_dp_min.capacity
        target_min_capacity = target_dp_min.capacity
        capacity = neighbor_nom_capacity * target_min_capacity / neighbor_min_capacity
      when HPXML::HVACCompressorTypeVariableSpeed
        neighbor_max_capacity = neighbor_dp_max.capacity
        neighbor_nom_capacity = neighbor_dp_nom.capacity
        neighbor_min_capacity = neighbor_dp_min.capacity
        target_max_capacity = target_dp_max.capacity
        target_min_capacity = target_dp_min.capacity
        capacity = MathTools.interp2(neighbor_nom_capacity, neighbor_min_capacity, neighbor_max_capacity, target_min_capacity, target_max_capacity)
      end
      added_dp.capacity = Float(capacity.round)

      # Net power
      case hvac_system.compressor_type
      when HPXML::HVACCompressorTypeTwoStage
        neighbor_nom_power = neighbor_dp_nom.capacity / neighbor_dp_nom.efficiency_cop
        neighbor_min_power = neighbor_dp_min.capacity / neighbor_dp_min.efficiency_cop
        target_min_power = target_dp_min.capacity / neighbor_dp_min.efficiency_cop
        input_power = neighbor_nom_power * target_min_power / neighbor_min_power
      when HPXML::HVACCompressorTypeVariableSpeed
        neighbor_max_power = neighbor_dp_max.capacity / neighbor_dp_max.efficiency_cop
        neighbor_nom_power = neighbor_dp_nom.capacity / neighbor_dp_nom.efficiency_cop
        neighbor_min_power = neighbor_dp_min.capacity / neighbor_dp_min.efficiency_cop
        target_max_power = target_dp_max.capacity / target_dp_max.efficiency_cop
        target_min_power = target_dp_min.capacity / neighbor_dp_min.efficiency_cop
        input_power = MathTools.interp2(neighbor_nom_power, neighbor_min_power, neighbor_max_power, target_min_power, target_max_power)
      end
      added_dp.efficiency_cop = (added_dp.capacity / input_power).round(4)
    end

    # override some properties based on detailed performance data
    dps = detailed_performance_data.select { |dp| dp.outdoor_temperature == rated_odb }
    capacities = []
    case hvac_system.compressor_type
    when HPXML::HVACCompressorTypeSingleStage
      capacities << [dps.find { |dp| dp.capacity_description == HPXML::CapacityDescriptionNominal }.capacity, 1.0].max
    when HPXML::HVACCompressorTypeTwoStage
      capacities << [dps.find { |dp| dp.capacity_description == HPXML::CapacityDescriptionMinimum }.capacity, 1.0].max
      capacities << [dps.find { |dp| dp.capacity_description == HPXML::CapacityDescriptionNominal }.capacity, 1.0].max
    when HPXML::HVACCompressorTypeVariableSpeed
      capacities << [dps.find { |dp| dp.capacity_description == HPXML::CapacityDescriptionMinimum }.capacity, 1.0].max
      capacities << [dps.find { |dp| dp.capacity_description == HPXML::CapacityDescriptionNominal }.capacity, 1.0].max
      capacities << [dps.find { |dp| dp.capacity_description == HPXML::CapacityDescriptionMaximum }.capacity, 1.0].max
    end
    capacity_ratios = capacities.map { |capacity| capacity / [nominal_capacity, 1.0].max }

    if mode == :clg
      hvac_ap.cool_capacity_ratios = capacity_ratios
    elsif mode == :htg
      hvac_ap.heat_capacity_ratios = capacity_ratios
    end
  end

  # Sets the default heat pump heating capacity at 17F property.
  #
  # @param heat_pump [HPXML::HeatPump] The HPXML heat pump of interest
  # @return [nil]
  def self.set_heat_pump_heating_capacity_17F(heat_pump)
    return unless heat_pump.heating_capacity_17F.nil?

    if not heat_pump.heating_detailed_performance_data.empty?
      rated_capacity_17 = heat_pump.heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == 17 && dp.capacity_description == HPXML::CapacityDescriptionNominal }.capacity
      heat_pump.heating_capacity_17F = rated_capacity_17
    else
      hp_ap = heat_pump.additional_properties
      heat_pump.heating_capacity_17F = (heat_pump.heating_capacity * hp_ap.qm17full).round
    end
    heat_pump.heating_capacity_17F_isdefaulted = true
    heat_pump.heating_capacity_fraction_17F = nil
  end

  # Assigns default values for omitted optional inputs in the HPXML::HVACControl object
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @return [nil]
  def self.apply_hvac_control(hpxml_bldg, schedules_file, eri_version)
    hpxml_bldg.hvac_controls.each do |hvac_control|
      schedules_file_includes_heating_setpoint_temp = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:HeatingSetpoint].name))
      if hvac_control.heating_setpoint_temp.nil? && hvac_control.weekday_heating_setpoints.nil? && !schedules_file_includes_heating_setpoint_temp
        # No heating setpoints; set a default heating setpoint for, e.g., natural ventilation
        htg_weekday_setpoints, htg_weekend_setpoints = get_heating_setpoint(HPXML::HVACControlTypeManual, eri_version)
        if htg_weekday_setpoints.split(', ').uniq.size == 1 && htg_weekend_setpoints.split(', ').uniq.size == 1 && htg_weekday_setpoints.split(', ').uniq == htg_weekend_setpoints.split(', ').uniq
          hvac_control.heating_setpoint_temp = htg_weekend_setpoints.split(', ').uniq[0].to_f
        else
          fail 'Unexpected heating setpoints.'
        end
        hvac_control.heating_setpoint_temp_isdefaulted = true
      end

      schedules_file_includes_cooling_setpoint_temp = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:CoolingSetpoint].name))
      if hvac_control.cooling_setpoint_temp.nil? && hvac_control.weekday_cooling_setpoints.nil? && !schedules_file_includes_cooling_setpoint_temp
        # No cooling setpoints; set a default cooling setpoint for, e.g., natural ventilation
        clg_weekday_setpoints, clg_weekend_setpoints = Defaults.get_cooling_setpoint(HPXML::HVACControlTypeManual, eri_version)
        if clg_weekday_setpoints.split(', ').uniq.size == 1 && clg_weekend_setpoints.split(', ').uniq.size == 1 && clg_weekday_setpoints.split(', ').uniq == clg_weekend_setpoints.split(', ').uniq
          hvac_control.cooling_setpoint_temp = clg_weekend_setpoints.split(', ').uniq[0].to_f
        else
          fail 'Unexpected cooling setpoints.'
        end
        hvac_control.cooling_setpoint_temp_isdefaulted = true
      end

      if hvac_control.heating_setback_start_hour.nil? && (not hvac_control.heating_setback_temp.nil?) && !schedules_file_includes_heating_setpoint_temp
        hvac_control.heating_setback_start_hour = 23 # 11 pm
        hvac_control.heating_setback_start_hour_isdefaulted = true
      end

      if hvac_control.cooling_setup_start_hour.nil? && (not hvac_control.cooling_setup_temp.nil?) && !schedules_file_includes_cooling_setpoint_temp
        hvac_control.cooling_setup_start_hour = 9 # 9 am
        hvac_control.cooling_setup_start_hour_isdefaulted = true
      end

      if hvac_control.seasons_heating_begin_month.nil? || hvac_control.seasons_heating_begin_day.nil? ||
         hvac_control.seasons_heating_end_month.nil? || hvac_control.seasons_heating_end_day.nil?
        hvac_control.seasons_heating_begin_month = 1
        hvac_control.seasons_heating_begin_day = 1
        hvac_control.seasons_heating_end_month = 12
        hvac_control.seasons_heating_end_day = 31
        hvac_control.seasons_heating_begin_month_isdefaulted = true
        hvac_control.seasons_heating_begin_day_isdefaulted = true
        hvac_control.seasons_heating_end_month_isdefaulted = true
        hvac_control.seasons_heating_end_day_isdefaulted = true
      end

      next unless hvac_control.seasons_cooling_begin_month.nil? || hvac_control.seasons_cooling_begin_day.nil? ||
                  hvac_control.seasons_cooling_end_month.nil? || hvac_control.seasons_cooling_end_day.nil?

      hvac_control.seasons_cooling_begin_month = 1
      hvac_control.seasons_cooling_begin_day = 1
      hvac_control.seasons_cooling_end_month = 12
      hvac_control.seasons_cooling_end_day = 31
      hvac_control.seasons_cooling_begin_month_isdefaulted = true
      hvac_control.seasons_cooling_begin_day_isdefaulted = true
      hvac_control.seasons_cooling_end_month_isdefaulted = true
      hvac_control.seasons_cooling_end_day_isdefaulted = true
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::HVACDistribution objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_hvac_distribution(hpxml_bldg)
    ncfl = hpxml_bldg.building_construction.number_of_conditioned_floors
    ncfl_ag = hpxml_bldg.building_construction.number_of_conditioned_floors_above_grade

    hpxml_bldg.hvac_distributions.each do |hvac_distribution|
      next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir
      next if hvac_distribution.ducts.empty?

      supply_ducts = hvac_distribution.ducts.select { |duct| duct.duct_type == HPXML::DuctTypeSupply }
      return_ducts = hvac_distribution.ducts.select { |duct| duct.duct_type == HPXML::DuctTypeReturn }

      # Default return registers
      if hvac_distribution.number_of_return_registers.nil? && (return_ducts.size > 0)
        hvac_distribution.number_of_return_registers = ncfl.ceil # Add 1 return register per conditioned floor if not provided
        hvac_distribution.number_of_return_registers_isdefaulted = true
      end

      cfa_served = hvac_distribution.conditioned_floor_area_served
      n_returns = hvac_distribution.number_of_return_registers

      if hvac_distribution.ducts[0].duct_location.nil?
        # Default both duct location(s) and duct surface area(s)
        [supply_ducts, return_ducts].each do |ducts|
          ducts.each do |duct|
            primary_duct_location, secondary_duct_location = get_duct_locations(hpxml_bldg)
            primary_duct_area, secondary_duct_area = get_duct_surface_area(duct.duct_type, primary_duct_location, ncfl, ncfl_ag, cfa_served, n_returns).map { |area| area / ducts.size }
            if primary_duct_location.nil? # If a home doesn't have any unconditioned spaces, place all ducts in conditioned space.
              duct.duct_surface_area = primary_duct_area + secondary_duct_area
              duct.duct_surface_area_isdefaulted = true
              duct.duct_location = secondary_duct_location
              duct.duct_location_isdefaulted = true
            else
              duct.duct_surface_area = primary_duct_area
              duct.duct_surface_area_isdefaulted = true
              duct.duct_location = primary_duct_location
              duct.duct_location_isdefaulted = true

              if secondary_duct_area > 0
                ins_r = (secondary_duct_location == HPXML::LocationConditionedSpace ? 0.0 : duct.duct_insulation_r_value)
                hvac_distribution.ducts.add(id: "#{duct.id}_secondary",
                                            duct_type: duct.duct_type,
                                            duct_insulation_r_value: ins_r,
                                            duct_location: secondary_duct_location,
                                            duct_location_isdefaulted: true,
                                            duct_surface_area: secondary_duct_area,
                                            duct_surface_area_isdefaulted: true)
              end
            end
          end
        end
      elsif hvac_distribution.ducts[0].duct_surface_area.nil?
        # Default duct surface area(s)
        [supply_ducts, return_ducts].each do |ducts|
          ducts.each do |duct|
            total_duct_area = get_duct_surface_area(duct.duct_type, duct.duct_location, ncfl, ncfl_ag, cfa_served, n_returns).sum()
            duct.duct_surface_area = total_duct_area * duct.duct_fraction_area
            duct.duct_surface_area_isdefaulted = true
          end
        end
      end
      supply_ducts = hvac_distribution.ducts.select { |duct| duct.duct_type == HPXML::DuctTypeSupply }
      return_ducts = hvac_distribution.ducts.select { |duct| duct.duct_type == HPXML::DuctTypeReturn }
      # Calculate FractionDuctArea from DuctSurfaceArea
      total_supply_area = supply_ducts.map { |d| d.duct_surface_area }.sum
      total_return_area = return_ducts.map { |d| d.duct_surface_area }.sum
      (supply_ducts + return_ducts).each do |duct|
        next unless duct.duct_fraction_area.nil?

        if duct.duct_type == HPXML::DuctTypeSupply
          if total_supply_area > 0
            duct.duct_fraction_area = (duct.duct_surface_area / total_supply_area).round(3)
          else
            duct.duct_fraction_area = (1.0 / supply_ducts.size).round(3) # Arbitrary
          end
          duct.duct_fraction_area_isdefaulted = true
        elsif duct.duct_type == HPXML::DuctTypeReturn
          if total_return_area > 0
            duct.duct_fraction_area = (duct.duct_surface_area / total_return_area).round(3)
          else
            duct.duct_fraction_area = (1.0 / return_ducts.size).round(3) # Arbitrary
          end
          duct.duct_fraction_area_isdefaulted = true
        end
      end

      hvac_distribution.ducts.each do |ducts|
        next unless ducts.duct_surface_area_multiplier.nil?

        ducts.duct_surface_area_multiplier = 1.0
        ducts.duct_surface_area_multiplier_isdefaulted = true
      end

      # Default buried insulation level
      hvac_distribution.ducts.each do |ducts|
        next unless ducts.duct_buried_insulation_level.nil?

        ducts.duct_buried_insulation_level = HPXML::DuctBuriedInsulationNone
        ducts.duct_buried_insulation_level_isdefaulted = true
      end

      # Default duct shape
      hvac_distribution.ducts.each do |ducts|
        next unless ducts.duct_fraction_rectangular.nil?

        if ducts.duct_shape.nil? || ducts.duct_shape == HPXML::DuctShapeOther
          if ducts.duct_type == HPXML::DuctTypeSupply
            ducts.duct_fraction_rectangular = 0.25
          elsif ducts.duct_type == HPXML::DuctTypeReturn
            ducts.duct_fraction_rectangular = 1.0
          end
        elsif ducts.duct_shape == HPXML::DuctShapeRound || ducts.duct_shape == HPXML::DuctShapeOval
          ducts.duct_fraction_rectangular = 0.0
        elsif ducts.duct_shape == HPXML::DuctShapeRectangular
          ducts.duct_fraction_rectangular = 1.0
        end
        ducts.duct_fraction_rectangular_isdefaulted = true
      end

      # Default effective R-value
      hvac_distribution.ducts.each do |ducts|
        next unless ducts.duct_effective_r_value.nil?

        ducts.duct_effective_r_value = get_duct_effective_r_value(ducts.duct_insulation_r_value,
                                                                  ducts.duct_type,
                                                                  ducts.duct_buried_insulation_level,
                                                                  ducts.duct_fraction_rectangular)
        ducts.duct_effective_r_value_isdefaulted = true
      end
    end

    # Manual J inputs
    hpxml_bldg.hvac_distributions.each do |hvac_distribution|
      if hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir
        # Blower fan heat
        if hvac_distribution.manualj_blower_fan_heat_btuh.nil?
          hvac_distribution.manualj_blower_fan_heat_btuh = 0.0
          hvac_distribution.manualj_blower_fan_heat_btuh_isdefaulted = true
        end
      elsif hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeHydronic
        # Hot water piping
        if hvac_distribution.manualj_hot_water_piping_btuh.nil?
          hvac_distribution.manualj_hot_water_piping_btuh = 0.0
          hvac_distribution.manualj_hot_water_piping_btuh_isdefaulted = true
        end
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::HeatingSystem,
  # HPXML::CoolingSystem, and HPXML::HeatPump objects related to HVAC location.
  #
  # Note: This needs to be called after we have applied defaults for ducts.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_hvac_location(hpxml_bldg)
    hpxml_bldg.hvac_systems.each do |hvac_system|
      next unless hvac_system.location.nil?

      hvac_system.location_isdefaulted = true

      if hvac_system.is_shared_system
        hvac_system.location = HPXML::LocationOtherHeatedSpace
        next
      end

      # Set default location based on distribution system
      dist_system = hvac_system.distribution_system
      if dist_system.nil?
        hvac_system.location = HPXML::LocationConditionedSpace
      else
        dist_type = dist_system.distribution_system_type
        if dist_type == HPXML::HVACDistributionTypeAir
          # Find largest unconditioned supply duct location
          uncond_duct_locations = {}
          dist_system.ducts.select { |d| d.duct_type == HPXML::DuctTypeSupply }.each do |d|
            next if HPXML::conditioned_locations_this_unit.include? d.duct_location
            next if [HPXML::LocationExteriorWall, HPXML::LocationUnderSlab].include? d.duct_location # air handler won't be here

            uncond_duct_locations[d.duct_location] = 0.0 if uncond_duct_locations[d.duct_location].nil?
            uncond_duct_locations[d.duct_location] += d.duct_surface_area
          end
          if uncond_duct_locations.empty?
            hvac_system.location = HPXML::LocationConditionedSpace
          else
            hvac_system.location = uncond_duct_locations.key(uncond_duct_locations.values.max)
            if hvac_system.location == HPXML::LocationOutside
              # DuctLocation "outside" needs to be converted to a valid UnitLocation enumeration
              hvac_system.location = HPXML::LocationOtherExterior
            end
          end
        elsif dist_type == HPXML::HVACDistributionTypeHydronic
          # Assume same default logic as a water heater
          iecc_zone = hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.empty? ? nil : hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone
          hvac_system.location = get_water_heater_location(hpxml_bldg, iecc_zone)
        elsif dist_type == HPXML::HVACDistributionTypeDSE
          # DSE=1 implies distribution system in conditioned space
          has_dse_of_one = true
          if (hvac_system.respond_to? :fraction_heat_load_served) && (dist_system.annual_heating_dse != 1)
            has_dse_of_one = false
          end
          if (hvac_system.respond_to? :fraction_cool_load_served) && (dist_system.annual_cooling_dse != 1)
            has_dse_of_one = false
          end
          if has_dse_of_one
            hvac_system.location = HPXML::LocationConditionedSpace
          else
            hvac_system.location = HPXML::LocationUnconditionedSpace
          end
        end
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::VentilationFan objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @return [nil]
  def self.apply_ventilation_fans(hpxml_bldg, weather, eri_version)
    # Default mech vent systems
    hpxml_bldg.ventilation_fans.each do |vent_fan|
      next unless vent_fan.used_for_whole_building_ventilation

      if vent_fan.is_shared_system.nil?
        vent_fan.is_shared_system = false
        vent_fan.is_shared_system_isdefaulted = true
      end

      if vent_fan.hours_in_operation.nil? && !vent_fan.is_cfis_supplemental_fan
        vent_fan.hours_in_operation = (vent_fan.fan_type == HPXML::MechVentTypeCFIS) ? 8.0 : 24.0
        vent_fan.hours_in_operation_isdefaulted = true
      end

      if vent_fan.flow_rate.nil?
        if hpxml_bldg.ventilation_fans.count { |vf| vf.used_for_whole_building_ventilation && !vf.is_cfis_supplemental_fan } > 1
          fail 'Defaulting flow rates for multiple mechanical ventilation systems is currently not supported.'
        end

        vent_fan.rated_flow_rate = get_mech_vent_flow_rate_for_vent_fan(hpxml_bldg, vent_fan, weather, eri_version).round(1)
        vent_fan.rated_flow_rate_isdefaulted = true
      end

      if vent_fan.fan_power.nil? && vent_fan.fan_type != HPXML::MechVentTypeCFIS # CFIS systems have their fan power defaulted later once we have autosized the total blower fan airflow rate
        fan_w_per_cfm = get_mech_vent_fan_efficiency(vent_fan)
        vent_fan.fan_power = (vent_fan.flow_rate * fan_w_per_cfm).round(2)
        vent_fan.fan_power_isdefaulted = true
      end
      next unless vent_fan.fan_type == HPXML::MechVentTypeCFIS

      # These apply to CFIS systems
      if vent_fan.cfis_addtl_runtime_operating_mode.nil?
        vent_fan.cfis_addtl_runtime_operating_mode = HPXML::CFISModeAirHandler
        vent_fan.cfis_addtl_runtime_operating_mode_isdefaulted = true
      end
      if vent_fan.cfis_has_outdoor_air_control.nil?
        vent_fan.cfis_has_outdoor_air_control = true
        vent_fan.cfis_has_outdoor_air_control_isdefaulted = true
      end
      if vent_fan.cfis_vent_mode_airflow_fraction.nil? && (vent_fan.cfis_addtl_runtime_operating_mode == HPXML::CFISModeAirHandler)
        vent_fan.cfis_vent_mode_airflow_fraction = 1.0
        vent_fan.cfis_vent_mode_airflow_fraction_isdefaulted = true
      end
      if vent_fan.cfis_supplemental_fan_runs_with_air_handler_fan.nil? && (vent_fan.cfis_addtl_runtime_operating_mode == HPXML::CFISModeSupplementalFan)
        vent_fan.cfis_supplemental_fan_runs_with_air_handler_fan = false
        vent_fan.cfis_supplemental_fan_runs_with_air_handler_fan_isdefaulted = true
      end
      if vent_fan.cfis_control_type.nil?
        vent_fan.cfis_control_type = HPXML::CFISControlTypeOptimized
        vent_fan.cfis_control_type_isdefaulted = true
      end
    end

    # Default kitchen fan
    hpxml_bldg.ventilation_fans.each do |vent_fan|
      next unless (vent_fan.used_for_local_ventilation && (vent_fan.fan_location == HPXML::LocationKitchen))

      if vent_fan.count.nil?
        vent_fan.count = 1
        vent_fan.count_isdefaulted = true
      end
      if vent_fan.rated_flow_rate.nil? && vent_fan.tested_flow_rate.nil? && vent_fan.calculated_flow_rate.nil? && vent_fan.delivered_ventilation.nil?
        vent_fan.rated_flow_rate = 100.0 # cfm, per BA HSP
        vent_fan.rated_flow_rate_isdefaulted = true
      end
      if vent_fan.hours_in_operation.nil?
        vent_fan.hours_in_operation = 1.0 # hrs/day, per BA HSP
        vent_fan.hours_in_operation_isdefaulted = true
      end
      if vent_fan.fan_power.nil?
        vent_fan.fan_power = 0.3 * vent_fan.flow_rate # W, per BA HSP
        vent_fan.fan_power_isdefaulted = true
      end
      if vent_fan.start_hour.nil?
        vent_fan.start_hour = 18 # 6 pm, per BA HSP
        vent_fan.start_hour_isdefaulted = true
      end
    end

    # Default bath fans
    hpxml_bldg.ventilation_fans.each do |vent_fan|
      next unless (vent_fan.used_for_local_ventilation && (vent_fan.fan_location == HPXML::LocationBath))

      if vent_fan.count.nil?
        vent_fan.count = hpxml_bldg.building_construction.number_of_bathrooms
        vent_fan.count_isdefaulted = true
      end
      if vent_fan.rated_flow_rate.nil? && vent_fan.tested_flow_rate.nil? && vent_fan.calculated_flow_rate.nil? && vent_fan.delivered_ventilation.nil?
        vent_fan.rated_flow_rate = 50.0 # cfm, per BA HSP
        vent_fan.rated_flow_rate_isdefaulted = true
      end
      if vent_fan.hours_in_operation.nil?
        vent_fan.hours_in_operation = 1.0 # hrs/day, per BA HSP
        vent_fan.hours_in_operation_isdefaulted = true
      end
      if vent_fan.fan_power.nil?
        vent_fan.fan_power = 0.3 * vent_fan.flow_rate # W, per BA HSP
        vent_fan.fan_power_isdefaulted = true
      end
      if vent_fan.start_hour.nil?
        vent_fan.start_hour = 7 # 7 am, per BA HSP
        vent_fan.start_hour_isdefaulted = true
      end
    end

    # Default whole house fan
    hpxml_bldg.ventilation_fans.each do |vent_fan|
      next unless vent_fan.used_for_seasonal_cooling_load_reduction

      if vent_fan.rated_flow_rate.nil? && vent_fan.tested_flow_rate.nil? && vent_fan.calculated_flow_rate.nil? && vent_fan.delivered_ventilation.nil?
        vent_fan.rated_flow_rate = hpxml_bldg.building_construction.conditioned_floor_area * 2.0
        vent_fan.rated_flow_rate_isdefaulted = true
      end
      if vent_fan.fan_power.nil?
        vent_fan.fan_power = 0.1 * vent_fan.flow_rate # W
        vent_fan.fan_power_isdefaulted = true
      end
    end
  end

  # Assigns the blower fan power for a CFIS system where the optional input has been omitted.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_cfis_fan_power(hpxml_bldg)
    hpxml_bldg.ventilation_fans.each do |vent_fan|
      next unless vent_fan.used_for_whole_building_ventilation
      next unless vent_fan.fan_type == HPXML::MechVentTypeCFIS
      next unless vent_fan.cfis_addtl_runtime_operating_mode == HPXML::CFISModeAirHandler
      next unless vent_fan.fan_power.nil?

      hvac_systems = vent_fan.distribution_system.hvac_systems
      fan_w_per_cfm = hvac_systems[0].fan_watts_per_cfm

      # Get max blower airflow rate
      blower_flow_rate = nil
      hvac_systems.each do |hvac_system|
        hvac_ap = hvac_system.additional_properties
        if hvac_ap.respond_to?(:heating_actual_airflow_cfm) && hvac_ap.heating_actual_airflow_cfm > blower_flow_rate.to_f
          blower_flow_rate = hvac_ap.heating_actual_airflow_cfm
        end
        if hvac_ap.respond_to?(:cooling_actual_airflow_cfm) && hvac_ap.cooling_actual_airflow_cfm > blower_flow_rate.to_f
          blower_flow_rate = hvac_ap.cooling_actual_airflow_cfm
        end
      end
      fail 'Unexpected error.' if blower_flow_rate.to_f == 0

      # Calculate blower airflow rate in vent only mode
      blower_flow_rate *= vent_fan.cfis_vent_mode_airflow_fraction

      vent_fan.fan_power = (blower_flow_rate * fan_w_per_cfm).round(2)
      vent_fan.fan_power_isdefaulted = true
    end
  end

  # Assigns the crankcase heater power for an HVAC system where the optional input has been omitted.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_crankcase_heating(hpxml_bldg)
    (hpxml_bldg.cooling_systems + hpxml_bldg.heat_pumps).each do |hvac_system|
      if hvac_system.is_a? HPXML::CoolingSystem
        next unless [HPXML::HVACTypeCentralAirConditioner, HPXML::HVACTypeMiniSplitAirConditioner, HPXML::HVACTypeRoomAirConditioner, HPXML::HVACTypePTAC].include? hvac_system.cooling_system_type
      elsif hvac_system.is_a? HPXML::HeatPump
        next unless [HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpMiniSplit, HPXML::HVACTypeHeatPumpPTHP, HPXML::HVACTypeHeatPumpRoom].include? hvac_system.heat_pump_type
      end
      next unless hvac_system.crankcase_heater_watts.nil?

      if HVAC.is_room_dx_hvac_system(hvac_system)
        hvac_system.crankcase_heater_watts = 0.0
      else
        # 10 W/ton of cooling capacity per RESNET HERS Addendum 82
        if hvac_system.is_a?(HPXML::HeatPump) && (hvac_system.fraction_cool_load_served == 0)
          # Heat pump only provides heating, use heating capacity instead
          hvac_system.crankcase_heater_watts = 10.0 * UnitConversions.convert(hvac_system.heating_capacity, 'Btu/hr', 'ton')
        else
          hvac_system.crankcase_heater_watts = 10.0 * UnitConversions.convert(hvac_system.cooling_capacity, 'Btu/hr', 'ton')
        end
      end
      hvac_system.crankcase_heater_watts_isdefaulted = true
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::WaterHeatingSystem objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def self.apply_water_heaters(hpxml_bldg, eri_version, schedules_file)
    nbeds = hpxml_bldg.building_construction.number_of_bedrooms
    nbaths = hpxml_bldg.building_construction.number_of_bathrooms
    hpxml_bldg.water_heating_systems.each do |water_heating_system|
      if water_heating_system.is_shared_system.nil?
        water_heating_system.is_shared_system = false
        water_heating_system.is_shared_system_isdefaulted = true
      end
      schedules_file_includes_water_heater_setpoint_temp = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:WaterHeaterSetpoint].name))
      if water_heating_system.temperature.nil? && !schedules_file_includes_water_heater_setpoint_temp
        water_heating_system.temperature = get_water_heater_temperature(eri_version)
        water_heating_system.temperature_isdefaulted = true
      end
      if water_heating_system.performance_adjustment.nil?
        water_heating_system.performance_adjustment = get_water_heater_performance_adjustment(water_heating_system)
        water_heating_system.performance_adjustment_isdefaulted = true
      end
      if water_heating_system.usage_bin.nil? && (not water_heating_system.uniform_energy_factor.nil?) # FHR & UsageBin only applies to UEF
        if not water_heating_system.first_hour_rating.nil?
          water_heating_system.usage_bin = get_water_heater_usage_bin(water_heating_system.first_hour_rating)
        else
          water_heating_system.usage_bin = HPXML::WaterHeaterUsageBinMedium
        end
        water_heating_system.usage_bin_isdefaulted = true
      end
      if (water_heating_system.water_heater_type == HPXML::WaterHeaterTypeCombiStorage)
        if water_heating_system.tank_volume.nil?
          water_heating_system.tank_volume = get_water_heater_tank_volume(water_heating_system.related_hvac_system.heating_system_fuel, nbeds, nbaths)
          water_heating_system.tank_volume_isdefaulted = true
        end
        if water_heating_system.standby_loss_value.nil?
          # Use equation fit from AHRI database
          # calculate independent variable SurfaceArea/vol(physically linear to standby_loss/skin_u under test condition) to fit the linear equation from AHRI database
          act_vol = Waterheater.calc_storage_tank_actual_vol(water_heating_system.tank_volume, nil)
          surface_area = Waterheater.calc_tank_areas(act_vol)[0]
          sqft_by_gal = surface_area / act_vol # sqft/gal
          water_heating_system.standby_loss_value = (2.9721 * sqft_by_gal - 0.4732).round(3) # linear equation assuming a constant u, F/hr
          water_heating_system.standby_loss_value_isdefaulted = true
          water_heating_system.standby_loss_units = HPXML::UnitsDegFPerHour
          water_heating_system.standby_loss_units_isdefaulted = true
        end
      end
      if (water_heating_system.water_heater_type == HPXML::WaterHeaterTypeStorage)
        if water_heating_system.heating_capacity.nil?
          water_heating_system.heating_capacity = (get_water_heater_heating_capacity(water_heating_system.fuel_type, nbeds, hpxml_bldg.water_heating_systems.size, nbaths) * 1000.0).round
          water_heating_system.heating_capacity_isdefaulted = true
        end
        if water_heating_system.tank_volume.nil?
          water_heating_system.tank_volume = get_water_heater_tank_volume(water_heating_system.fuel_type, nbeds, nbaths)
          water_heating_system.tank_volume_isdefaulted = true
        end
        if water_heating_system.recovery_efficiency.nil?
          water_heating_system.recovery_efficiency = get_water_heater_recovery_efficiency(water_heating_system)
          water_heating_system.recovery_efficiency_isdefaulted = true
        end
        if water_heating_system.tank_model_type.nil?
          water_heating_system.tank_model_type = HPXML::WaterHeaterTankModelTypeMixed
          water_heating_system.tank_model_type_isdefaulted = true
        end
      end
      if (water_heating_system.water_heater_type == HPXML::WaterHeaterTypeHeatPump)
        Waterheater.set_heat_pump_cop(water_heating_system)
        if water_heating_system.heating_capacity.nil?
          water_heating_system.heating_capacity = (UnitConversions.convert(0.5, 'kW', 'Btu/hr') * water_heating_system.additional_properties.cop).round
          water_heating_system.heating_capacity_isdefaulted = true
        end
        if water_heating_system.backup_heating_capacity.nil?
          water_heating_system.backup_heating_capacity = UnitConversions.convert(4.5, 'kW', 'Btu/hr').round
          water_heating_system.backup_heating_capacity_isdefaulted = true
        end
        if water_heating_system.tank_volume.nil?
          water_heating_system.tank_volume = get_water_heater_tank_volume(water_heating_system.fuel_type, nbeds, nbaths)
          water_heating_system.tank_volume_isdefaulted = true
        end
        schedules_file_includes_water_heater_operating_mode = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:WaterHeaterOperatingMode].name))
        if water_heating_system.operating_mode.nil? && !schedules_file_includes_water_heater_operating_mode
          water_heating_system.operating_mode = HPXML::WaterHeaterOperatingModeHybridAuto
          water_heating_system.operating_mode_isdefaulted = true
        end
      end
      next unless water_heating_system.location.nil?

      iecc_zone = hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.empty? ? nil : hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone
      water_heating_system.location = get_water_heater_location(hpxml_bldg, iecc_zone)
      water_heating_system.location_isdefaulted = true
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::AirInfiltration object
  # specific to the presence of a flue/chimney.
  #
  # Note: This needs to be called after we have applied defaults for HVAC/DHW systems.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_flue_or_chimney(hpxml_bldg)
    if hpxml_bldg.air_infiltration.has_flue_or_chimney_in_conditioned_space.nil?
      hpxml_bldg.air_infiltration.has_flue_or_chimney_in_conditioned_space = get_flue_or_chimney_in_conditioned_space(hpxml_bldg)
      hpxml_bldg.air_infiltration.has_flue_or_chimney_in_conditioned_space_isdefaulted = true
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::HotWaterDistribution objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def self.apply_hot_water_distribution(hpxml_bldg, schedules_file)
    return if hpxml_bldg.hot_water_distributions.size == 0

    hot_water_distribution = hpxml_bldg.hot_water_distributions[0]
    has_uncond_bsmnt = hpxml_bldg.has_location(HPXML::LocationBasementUnconditioned)
    has_cond_bsmnt = hpxml_bldg.has_location(HPXML::LocationBasementConditioned)
    cfa = hpxml_bldg.building_construction.conditioned_floor_area
    ncfl = hpxml_bldg.building_construction.number_of_conditioned_floors

    if hot_water_distribution.pipe_r_value.nil?
      hot_water_distribution.pipe_r_value = 0.0
      hot_water_distribution.pipe_r_value_isdefaulted = true
    end

    case hot_water_distribution.system_type
    when HPXML::DHWDistTypeStandard
      if hot_water_distribution.standard_piping_length.nil?
        hot_water_distribution.standard_piping_length = get_std_pipe_length(has_uncond_bsmnt, has_cond_bsmnt, cfa, ncfl)
        hot_water_distribution.standard_piping_length_isdefaulted = true
      end
    when HPXML::DHWDistTypeRecirc
      if hot_water_distribution.recirculation_piping_loop_length.nil?
        hot_water_distribution.recirculation_piping_loop_length = get_recirc_loop_length(has_uncond_bsmnt, has_cond_bsmnt, cfa, ncfl)
        hot_water_distribution.recirculation_piping_loop_length_isdefaulted = true
      end
      if hot_water_distribution.recirculation_branch_piping_length.nil?
        hot_water_distribution.recirculation_branch_piping_length = get_recirc_branch_length()
        hot_water_distribution.recirculation_branch_piping_length_isdefaulted = true
      end
      if hot_water_distribution.recirculation_pump_power.nil?
        hot_water_distribution.recirculation_pump_power = get_recirc_pump_power()
        hot_water_distribution.recirculation_pump_power_isdefaulted = true
      end
    end

    if hot_water_distribution.has_shared_recirculation
      if hot_water_distribution.shared_recirculation_pump_power.nil?
        hot_water_distribution.shared_recirculation_pump_power = get_shared_recirc_pump_power()
        hot_water_distribution.shared_recirculation_pump_power_isdefaulted = true
      end
    end

    if hot_water_distribution.system_type == HPXML::DHWDistTypeRecirc || hot_water_distribution.has_shared_recirculation
      schedules_file_includes_recirculation_pump = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:HotWaterRecirculationPump].name))
      recirc_control_type = hot_water_distribution.has_shared_recirculation ? hot_water_distribution.shared_recirculation_control_type : hot_water_distribution.recirculation_control_type
      case recirc_control_type
      when HPXML::DHWRecircControlTypeNone, HPXML::DHWRecircControlTypeTimer
        if hot_water_distribution.recirculation_pump_weekday_fractions.nil? && !schedules_file_includes_recirculation_pump
          hot_water_distribution.recirculation_pump_weekday_fractions = @default_schedules_csv_data["#{SchedulesFile::Columns[:HotWaterRecirculationPump].name}_no_control"]['RecirculationPumpWeekdayScheduleFractions']
          hot_water_distribution.recirculation_pump_weekday_fractions_isdefaulted = true
        end
        if hot_water_distribution.recirculation_pump_weekend_fractions.nil? && !schedules_file_includes_recirculation_pump
          hot_water_distribution.recirculation_pump_weekend_fractions = @default_schedules_csv_data["#{SchedulesFile::Columns[:HotWaterRecirculationPump].name}_no_control"]['RecirculationPumpWeekendScheduleFractions']
          hot_water_distribution.recirculation_pump_weekend_fractions_isdefaulted = true
        end
      when HPXML::DHWRecircControlTypeSensor, HPXML::DHWRecircControlTypeManual
        if hot_water_distribution.recirculation_pump_weekday_fractions.nil? && !schedules_file_includes_recirculation_pump
          hot_water_distribution.recirculation_pump_weekday_fractions = @default_schedules_csv_data["#{SchedulesFile::Columns[:HotWaterRecirculationPump].name}_demand_control"]['RecirculationPumpWeekdayScheduleFractions']
          hot_water_distribution.recirculation_pump_weekday_fractions_isdefaulted = true
        end
        if hot_water_distribution.recirculation_pump_weekend_fractions.nil? && !schedules_file_includes_recirculation_pump
          hot_water_distribution.recirculation_pump_weekend_fractions = @default_schedules_csv_data["#{SchedulesFile::Columns[:HotWaterRecirculationPump].name}_demand_control"]['RecirculationPumpWeekendScheduleFractions']
          hot_water_distribution.recirculation_pump_weekend_fractions_isdefaulted = true
        end
      when HPXML::DHWRecircControlTypeTemperature
        if hot_water_distribution.recirculation_pump_weekday_fractions.nil? && !schedules_file_includes_recirculation_pump
          hot_water_distribution.recirculation_pump_weekday_fractions = @default_schedules_csv_data["#{SchedulesFile::Columns[:HotWaterRecirculationPump].name}_temperature_control"]['RecirculationPumpWeekdayScheduleFractions']
          hot_water_distribution.recirculation_pump_weekday_fractions_isdefaulted = true
        end
        if hot_water_distribution.recirculation_pump_weekend_fractions.nil? && !schedules_file_includes_recirculation_pump
          hot_water_distribution.recirculation_pump_weekend_fractions = @default_schedules_csv_data["#{SchedulesFile::Columns[:HotWaterRecirculationPump].name}_temperature_control"]['RecirculationPumpWeekendScheduleFractions']
          hot_water_distribution.recirculation_pump_weekend_fractions_isdefaulted = true
        end
      end
      if hot_water_distribution.recirculation_pump_monthly_multipliers.nil? && !schedules_file_includes_recirculation_pump
        hot_water_distribution.recirculation_pump_monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:HotWaterRecirculationPump].name]['RecirculationPumpMonthlyScheduleMultipliers']
        hot_water_distribution.recirculation_pump_monthly_multipliers_isdefaulted = true
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::WaterFixture objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def self.apply_water_fixtures(hpxml_bldg, schedules_file)
    return if hpxml_bldg.hot_water_distributions.size == 0

    hpxml_bldg.water_fixtures.each do |wf|
      next unless [HPXML::WaterFixtureTypeShowerhead, HPXML::WaterFixtureTypeFaucet].include? wf.water_fixture_type

      if wf.low_flow.nil?
        wf.low_flow = (wf.flow_rate <= 2.0)
        wf.low_flow_isdefaulted = true
      end
    end

    if hpxml_bldg.water_heating.water_fixtures_usage_multiplier.nil?
      hpxml_bldg.water_heating.water_fixtures_usage_multiplier = 1.0
      hpxml_bldg.water_heating.water_fixtures_usage_multiplier_isdefaulted = true
    end
    schedules_file_includes_fixtures = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:HotWaterFixtures].name))
    if hpxml_bldg.water_heating.water_fixtures_weekday_fractions.nil? && !schedules_file_includes_fixtures
      hpxml_bldg.water_heating.water_fixtures_weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:HotWaterFixtures].name]['WaterFixturesWeekdayScheduleFractions']
      hpxml_bldg.water_heating.water_fixtures_weekday_fractions_isdefaulted = true
    end
    if hpxml_bldg.water_heating.water_fixtures_weekend_fractions.nil? && !schedules_file_includes_fixtures
      hpxml_bldg.water_heating.water_fixtures_weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:HotWaterFixtures].name]['WaterFixturesWeekendScheduleFractions']
      hpxml_bldg.water_heating.water_fixtures_weekend_fractions_isdefaulted = true
    end
    if hpxml_bldg.water_heating.water_fixtures_monthly_multipliers.nil? && !schedules_file_includes_fixtures
      hpxml_bldg.water_heating.water_fixtures_monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:HotWaterFixtures].name]['WaterFixturesMonthlyScheduleMultipliers']
      hpxml_bldg.water_heating.water_fixtures_monthly_multipliers_isdefaulted = true
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::SolarThermalSystem objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_solar_thermal_systems(hpxml_bldg)
    hpxml_bldg.solar_thermal_systems.each do |solar_thermal_system|
      if solar_thermal_system.collector_azimuth.nil?
        solar_thermal_system.collector_azimuth = get_azimuth_from_orientation(solar_thermal_system.collector_orientation)
        solar_thermal_system.collector_azimuth_isdefaulted = true
      end
      if solar_thermal_system.collector_orientation.nil?
        solar_thermal_system.collector_orientation = get_orientation_from_azimuth(solar_thermal_system.collector_azimuth)
        solar_thermal_system.collector_orientation_isdefaulted = true
      end
      if solar_thermal_system.storage_volume.nil? && (not solar_thermal_system.collector_area.nil?) # Detailed solar water heater
        solar_thermal_system.storage_volume = get_solar_thermal_system_storage_volume(solar_thermal_system.collector_area)
        solar_thermal_system.storage_volume_isdefaulted = true
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::PVSystem objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param unit_num [Integer] Dwelling unit number
  # @return [nil]
  def self.apply_pv_systems(hpxml_bldg, unit_num)
    hpxml_bldg.pv_systems.each do |pv_system|
      if pv_system.array_azimuth.nil?
        pv_system.array_azimuth = get_azimuth_from_orientation(pv_system.array_orientation)
        pv_system.array_azimuth_isdefaulted = true
      end
      if pv_system.array_orientation.nil?
        pv_system.array_orientation = get_orientation_from_azimuth(pv_system.array_azimuth)
        pv_system.array_orientation_isdefaulted = true
      end
      if pv_system.is_shared_system.nil?
        pv_system.is_shared_system = false
        pv_system.is_shared_system_isdefaulted = true
      end
      if pv_system.location.nil?
        pv_system.location = HPXML::LocationRoof
        pv_system.location_isdefaulted = true
      end
      if pv_system.tracking.nil?
        pv_system.tracking = HPXML::PVTrackingTypeFixed
        pv_system.tracking_isdefaulted = true
      end
      if pv_system.module_type.nil?
        pv_system.module_type = HPXML::PVModuleTypeStandard
        pv_system.module_type_isdefaulted = true
      end
      if pv_system.system_losses_fraction.nil?
        pv_system.system_losses_fraction = get_pv_system_losses(pv_system.year_modules_manufactured)
        pv_system.system_losses_fraction_isdefaulted = true
      end
      next unless pv_system.inverter_idref.nil?

      if hpxml_bldg.inverters.size == 0
        hpxml_bldg.inverters.add(id: get_id('Inverter', hpxml_bldg.inverters, unit_num))
      end
      pv_system.inverter_idref = hpxml_bldg.inverters[0].id
    end
    hpxml_bldg.inverters.each do |inverter|
      if inverter.inverter_efficiency.nil?
        inverter.inverter_efficiency = 0.96 # PVWatts default inverter efficiency
        inverter.inverter_efficiency_isdefaulted = true
      end
    end
  end

  # Get the id based on provided prefix, number of like HPXML objects, and dwelling unit number.
  # This is useful for HPXML objects that get added by defaults.rb.
  # Pass the dwelling unit number when adding HPXML objects across multiple HPXML buildings.
  #
  # @param prefix [String] Identifier prefix
  # @param objects [Array<HPXML::XXX>] List of HPXML objects
  # @param unit_num [Integer] Dwelling unit number
  # @return [String]
  def self.get_id(prefix, objects, unit_num)
    if not unit_num.nil?
      id = "#{prefix}#{objects.size + 1}_#{unit_num}"
    else
      id = "#{prefix}#{objects.size + 1}"
    end
    return id
  end

  # Assigns default values for omitted optional inputs in the HPXML::ElectricPanel objects.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param unit_num [Integer] Dwelling unit number
  # @return [nil]
  def self.apply_electric_panels(runner, hpxml_header, hpxml_bldg, unit_num)
    # Currently, we leave the electric panel object unchanged if no load calculation types are specified
    return if hpxml_header.service_feeders_load_calculation_types.nil? || hpxml_header.service_feeders_load_calculation_types.empty?

    default_panels_csv_data = get_panels_csv_data()

    hpxml_bldg.electric_panels.each do |electric_panel|
      branch_circuits = electric_panel.branch_circuits
      service_feeders = electric_panel.service_feeders

      hpxml_bldg.heating_systems.each do |heating_system|
        next if heating_system.is_shared_system
        next if heating_system.fraction_heat_load_served == 0
        next unless heating_system.service_feeders.empty?

        service_feeders.add(id: get_id('ServiceFeeder', service_feeders, unit_num),
                            type: HPXML::ElectricPanelLoadTypeHeating,
                            type_isdefaulted: true,
                            component_idrefs: [heating_system.id],
                            component_idrefs_isdefaulted: true)
      end

      hpxml_bldg.cooling_systems.each do |cooling_system|
        next if cooling_system.is_shared_system
        next if cooling_system.fraction_cool_load_served == 0
        next unless cooling_system.service_feeders.empty?

        service_feeders.add(id: get_id('ServiceFeeder', service_feeders, unit_num),
                            type: HPXML::ElectricPanelLoadTypeCooling,
                            type_isdefaulted: true,
                            component_idrefs: [cooling_system.id],
                            component_idrefs_isdefaulted: true)
      end

      hpxml_bldg.heat_pumps.each do |heat_pump|
        next unless heat_pump.service_feeders.empty?

        if heat_pump.fraction_heat_load_served != 0
          service_feeders.add(id: get_id('ServiceFeeder', service_feeders, unit_num),
                              type: HPXML::ElectricPanelLoadTypeHeating,
                              type_isdefaulted: true,
                              component_idrefs: [heat_pump.id],
                              component_idrefs_isdefaulted: true)
        end
        next unless heat_pump.fraction_cool_load_served != 0

        service_feeders.add(id: get_id('ServiceFeeder', service_feeders, unit_num),
                            type: HPXML::ElectricPanelLoadTypeCooling,
                            type_isdefaulted: true,
                            component_idrefs: [heat_pump.id],
                            component_idrefs_isdefaulted: true)
      end

      hpxml_bldg.water_heating_systems.each do |water_heating_system|
        next if water_heating_system.fuel_type != HPXML::FuelTypeElectricity
        next unless water_heating_system.service_feeders.empty?

        service_feeders.add(id: get_id('ServiceFeeder', service_feeders, unit_num),
                            type: HPXML::ElectricPanelLoadTypeWaterHeater,
                            type_isdefaulted: true,
                            component_idrefs: [water_heating_system.id],
                            component_idrefs_isdefaulted: true)
      end

      hpxml_bldg.clothes_dryers.each do |clothes_dryer|
        next if clothes_dryer.fuel_type != HPXML::FuelTypeElectricity
        next unless clothes_dryer.service_feeders.empty?

        service_feeders.add(id: get_id('ServiceFeeder', service_feeders, unit_num),
                            type: HPXML::ElectricPanelLoadTypeClothesDryer,
                            type_isdefaulted: true,
                            component_idrefs: [clothes_dryer.id],
                            component_idrefs_isdefaulted: true)
      end

      hpxml_bldg.dishwashers.each do |dishwasher|
        next unless dishwasher.service_feeders.empty?

        service_feeders.add(id: get_id('ServiceFeeder', service_feeders, unit_num),
                            type: HPXML::ElectricPanelLoadTypeDishwasher,
                            type_isdefaulted: true,
                            component_idrefs: [dishwasher.id],
                            component_idrefs_isdefaulted: true)
      end

      hpxml_bldg.cooking_ranges.each do |cooking_range|
        next if cooking_range.fuel_type != HPXML::FuelTypeElectricity
        next unless cooking_range.service_feeders.empty?

        service_feeders.add(id: get_id('ServiceFeeder', service_feeders, unit_num),
                            type: HPXML::ElectricPanelLoadTypeRangeOven,
                            type_isdefaulted: true,
                            component_idrefs: [cooking_range.id],
                            component_idrefs_isdefaulted: true)
      end

      hpxml_bldg.ventilation_fans.each do |ventilation_fan|
        next unless ventilation_fan.service_feeders.empty?

        service_feeders.add(id: get_id('ServiceFeeder', service_feeders, unit_num),
                            type: HPXML::ElectricPanelLoadTypeMechVent,
                            type_isdefaulted: true,
                            component_idrefs: [ventilation_fan.id],
                            component_idrefs_isdefaulted: true)
      end

      hpxml_bldg.permanent_spas.each do |permanent_spa|
        next if permanent_spa.type == HPXML::TypeNone

        if permanent_spa.pump_service_feeders.empty?
          service_feeders.add(id: get_id('ServiceFeeder', service_feeders, unit_num),
                              type: HPXML::ElectricPanelLoadTypePermanentSpaPump,
                              type_isdefaulted: true,
                              component_idrefs: [permanent_spa.pump_id],
                              component_idrefs_isdefaulted: true)
        end

        next unless [HPXML::HeaterTypeElectricResistance, HPXML::HeaterTypeHeatPump].include?(permanent_spa.heater_type)
        next unless permanent_spa.heater_service_feeders.empty?

        service_feeders.add(id: get_id('ServiceFeeder', service_feeders, unit_num),
                            type: HPXML::ElectricPanelLoadTypePermanentSpaHeater,
                            type_isdefaulted: true,
                            component_idrefs: [permanent_spa.heater_id],
                            component_idrefs_isdefaulted: true)
      end

      hpxml_bldg.pools.each do |pool|
        next if pool.type == HPXML::TypeNone

        if pool.pump_service_feeders.empty?
          service_feeders.add(id: get_id('ServiceFeeder', service_feeders, unit_num),
                              type: HPXML::ElectricPanelLoadTypePoolPump,
                              type_isdefaulted: true,
                              component_idrefs: [pool.pump_id],
                              component_idrefs_isdefaulted: true)
        end

        next unless [HPXML::HeaterTypeElectricResistance, HPXML::HeaterTypeHeatPump].include?(pool.heater_type)
        next unless pool.heater_service_feeders.empty?

        service_feeders.add(id: get_id('ServiceFeeder', service_feeders, unit_num),
                            type: HPXML::ElectricPanelLoadTypePoolHeater,
                            type_isdefaulted: true,
                            component_idrefs: [pool.heater_id],
                            component_idrefs_isdefaulted: true)
      end

      hpxml_bldg.plug_loads.each do |plug_load|
        next if plug_load.plug_load_type != HPXML::PlugLoadTypeWellPump
        next unless plug_load.service_feeders.empty?

        service_feeders.add(id: get_id('ServiceFeeder', service_feeders, unit_num),
                            type: HPXML::ElectricPanelLoadTypeWellPump,
                            type_isdefaulted: true,
                            component_idrefs: [plug_load.id],
                            component_idrefs_isdefaulted: true)
      end

      hpxml_bldg.plug_loads.each do |plug_load|
        next if plug_load.plug_load_type != HPXML::PlugLoadTypeElectricVehicleCharging
        next unless plug_load.service_feeders.empty?

        service_feeders.add(id: get_id('ServiceFeeder', service_feeders, unit_num),
                            type: HPXML::ElectricPanelLoadTypeElectricVehicleCharging,
                            type_isdefaulted: true,
                            component_idrefs: [plug_load.id],
                            component_idrefs_isdefaulted: true)
      end

      hpxml_bldg.ev_chargers.each do |ev_charger|
        next unless ev_charger.service_feeders.empty?

        service_feeders.add(id: get_id('ServiceFeeder', service_feeders, unit_num),
                            type: HPXML::ElectricPanelLoadTypeElectricVehicleCharging,
                            type_isdefaulted: true,
                            component_idrefs: [ev_charger.id],
                            component_idrefs_isdefaulted: true)
      end

      service_feeders.each do |service_feeder|
        next if service_feeder.power == 0

        service_feeder.components.each do |component|
          if component.is_a?(HPXML::Pool) || component.is_a?(HPXML::PermanentSpa)
            if component.pump_branch_circuits.empty?
              branch_circuits.add(id: get_id('BranchCircuit', branch_circuits, unit_num),
                                  component_idrefs: [component.pump_id])
            end
            if component.heater_branch_circuits.empty?
              branch_circuits.add(id: get_id('BranchCircuit', branch_circuits, unit_num),
                                  component_idrefs: [component.heater_id])
            end
          elsif component.branch_circuits.empty?
            # Skip HVAC system branch circuits; these will be added on the fly down below when we loop thru service feeders
            if !component.is_a?(HPXML::HeatingSystem) && !component.is_a?(HPXML::CoolingSystem) && !component.is_a?(HPXML::HeatPump)
              branch_circuits.add(id: get_id('BranchCircuit', branch_circuits, unit_num),
                                  component_idrefs: [component.id])
            end
          end
        end
      end

      if service_feeders.count { |pl| pl.type == HPXML::ElectricPanelLoadTypeOther } == 0
        service_feeders.add(id: get_id('ServiceFeeder', service_feeders, unit_num),
                            type: HPXML::ElectricPanelLoadTypeOther,
                            type_isdefaulted: true,
                            component_idrefs: [])
        (1..get_default_panels_value(runner, default_panels_csv_data, 'other', 'BreakerSpaces', HPXML::ElectricPanelVoltage120)).each do |_i|
          branch_circuits.add(id: get_id('BranchCircuit', branch_circuits, unit_num),
                              occupied_spaces: 1,
                              occupied_spaces_isdefaulted: true)
        end
      end

      if service_feeders.count { |pl| pl.type == HPXML::ElectricPanelLoadTypeLighting } == 0
        service_feeders.add(id: get_id('ServiceFeeder', service_feeders, unit_num),
                            type: HPXML::ElectricPanelLoadTypeLighting,
                            type_isdefaulted: true,
                            component_idrefs: [])
        (1..get_default_panels_value(runner, default_panels_csv_data, 'lighting', 'BreakerSpaces', HPXML::ElectricPanelVoltage120)).each do |_i|
          branch_circuits.add(id: get_id('BranchCircuit', branch_circuits, unit_num),
                              occupied_spaces: 1,
                              occupied_spaces_isdefaulted: true)
        end
      end

      if service_feeders.count { |pl| pl.type == HPXML::ElectricPanelLoadTypeKitchen } == 0
        service_feeders.add(id: get_id('ServiceFeeder', service_feeders, unit_num),
                            type: HPXML::ElectricPanelLoadTypeKitchen,
                            type_isdefaulted: true,
                            component_idrefs: [])
        (1..get_default_panels_value(runner, default_panels_csv_data, 'kitchen', 'BreakerSpaces', HPXML::ElectricPanelVoltage120)).each do |_i|
          branch_circuits.add(id: get_id('BranchCircuit', branch_circuits, unit_num),
                              occupied_spaces: 1,
                              occupied_spaces_isdefaulted: true)
        end
      end

      if service_feeders.count { |pl| pl.type == HPXML::ElectricPanelLoadTypeLaundry } == 0
        service_feeders.add(id: get_id('ServiceFeeder', service_feeders, unit_num),
                            type: HPXML::ElectricPanelLoadTypeLaundry,
                            type_isdefaulted: true,
                            component_idrefs: [])
        (1..get_default_panels_value(runner, default_panels_csv_data, 'laundry', 'BreakerSpaces', HPXML::ElectricPanelVoltage120)).each do |_i|
          branch_circuits.add(id: get_id('BranchCircuit', branch_circuits, unit_num),
                              occupied_spaces: 1,
                              occupied_spaces_isdefaulted: true)
        end
      end

      branch_circuits.each do |branch_circuit|
        if branch_circuit.voltage.nil?
          branch_circuit.voltage = get_branch_circuit_voltage_default_values(branch_circuit)
          branch_circuit.voltage_isdefaulted = true
        end
        if branch_circuit.max_current_rating.nil?
          branch_circuit.max_current_rating = get_branch_circuit_amps_default_values(branch_circuit)
          branch_circuit.max_current_rating_isdefaulted = true
        end
      end

      service_feeders.each do |service_feeder|
        if service_feeder.power.nil?
          service_feeder.power = get_service_feeder_power_default_values(runner, hpxml_bldg, service_feeder, default_panels_csv_data, electric_panel, unit_num)
          service_feeder.power_isdefaulted = true
        else
          if service_feeder.type == HPXML::ElectricPanelLoadTypeHeating
            hpxml_bldg.heating_systems.each do |heating_system|
              next if !service_feeder.component_idrefs.include?(heating_system.id)
              next if heating_system.is_shared_system
              next if heating_system.fraction_heat_load_served == 0

              branch_circuit = get_or_add_branch_circuit(electric_panel, heating_system, unit_num)
              if branch_circuit.occupied_spaces.nil?
                branch_circuit.occupied_spaces = get_breaker_spaces_from_power_watts_voltage_amps(service_feeder.power, branch_circuit.voltage, branch_circuit.max_current_rating)
                branch_circuit.occupied_spaces_isdefaulted = true
              end
            end

            hpxml_bldg.heat_pumps.each do |heat_pump|
              next if !service_feeder.component_idrefs.include?(heat_pump.id)
              next if heat_pump.fraction_heat_load_served == 0

              branch_circuit = get_or_add_branch_circuit(electric_panel, heat_pump, unit_num)
              if branch_circuit.occupied_spaces.nil?
                branch_circuit.occupied_spaces = get_breaker_spaces_from_power_watts_voltage_amps(service_feeder.power, branch_circuit.voltage, branch_circuit.max_current_rating)
                branch_circuit.occupied_spaces_isdefaulted = true
              end
            end
          elsif service_feeder.type == HPXML::ElectricPanelLoadTypeCooling
            hpxml_bldg.cooling_systems.each do |cooling_system|
              next if !service_feeder.component_idrefs.include?(cooling_system.id)
              next if cooling_system.is_shared_system
              next if cooling_system.fraction_cool_load_served == 0

              branch_circuit = get_or_add_branch_circuit(electric_panel, cooling_system, unit_num)
              if branch_circuit.occupied_spaces.nil?
                branch_circuit.occupied_spaces = get_breaker_spaces_from_power_watts_voltage_amps(service_feeder.power, branch_circuit.voltage, branch_circuit.max_current_rating)
                branch_circuit.occupied_spaces_isdefaulted = true
              end
            end

            hpxml_bldg.heat_pumps.each do |heat_pump|
              next if !service_feeder.component_idrefs.include?(heat_pump.id)
              next if heat_pump.fraction_cool_load_served == 0

              branch_circuit = get_or_add_branch_circuit(electric_panel, heat_pump, unit_num)
              if branch_circuit.occupied_spaces.nil?
                branch_circuit.occupied_spaces = get_breaker_spaces_from_power_watts_voltage_amps(service_feeder.power, branch_circuit.voltage, branch_circuit.max_current_rating)
                branch_circuit.occupied_spaces_isdefaulted = true
              end
            end
          end
        end
        if service_feeder.is_new_load.nil?
          service_feeder.is_new_load = false
          service_feeder.is_new_load_isdefaulted = true
        end
      end

      branch_circuits.each do |branch_circuit|
        if branch_circuit.occupied_spaces.nil?
          branch_circuit.occupied_spaces = get_branch_circuit_occupied_spaces_default_values(runner, hpxml_bldg, branch_circuit, default_panels_csv_data)
          branch_circuit.occupied_spaces_isdefaulted = true
        end

        occupied_spaces = branch_circuit.occupied_spaces
        max_breakers_per_branch_circuit = Integer(Float(branch_circuit.voltage)) / 120

        next unless occupied_spaces > max_breakers_per_branch_circuit

        branch_circuit.occupied_spaces = max_breakers_per_branch_circuit
        extra_occupied_spaces = occupied_spaces - max_breakers_per_branch_circuit
        n_branch_circuits = extra_occupied_spaces / max_breakers_per_branch_circuit

        (1..n_branch_circuits).each do |i|
          branch_circuits.add(id: "#{branch_circuit.id}_#{i + 1}",
                              voltage: branch_circuit.voltage,
                              voltage_isdefaulted: true,
                              max_current_rating: branch_circuit.max_current_rating,
                              max_current_rating_isdefaulted: true,
                              occupied_spaces: max_breakers_per_branch_circuit,
                              occupied_spaces_isdefaulted: true,
                              component_idrefs: branch_circuit.component_idrefs,
                              component_idrefs_isdefaulted: true)
        end

        next unless extra_occupied_spaces % max_breakers_per_branch_circuit != 0

        branch_circuits.add(id: "#{branch_circuit.id}_#{n_branch_circuits.ceil + 1}",
                            voltage: HPXML::ElectricPanelVoltage120,
                            voltage_isdefaulted: true,
                            max_current_rating: 20.0,
                            max_current_rating_isdefaulted: true,
                            occupied_spaces: 1,
                            occupied_spaces_isdefaulted: true,
                            component_idrefs: branch_circuit.component_idrefs,
                            component_idrefs_isdefaulted: true)
      end

      if electric_panel.voltage.nil?
        electric_panel.voltage = HPXML::ElectricPanelVoltage240
        electric_panel.voltage_isdefaulted = true
      end
      if electric_panel.max_current_rating.nil?
        electric_panel.max_current_rating = 200.0 # A
        electric_panel.max_current_rating_isdefaulted = true
      end
      if electric_panel.headroom_spaces.nil? && electric_panel.rated_total_spaces.nil?
        electric_panel.headroom_spaces = 3
        electric_panel.headroom_spaces_isdefaulted = true
      end

      ElectricPanel.calculate(hpxml_header, hpxml_bldg, electric_panel)
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::Generator objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_generators(hpxml_bldg)
    hpxml_bldg.generators.each do |generator|
      if generator.is_shared_system.nil?
        generator.is_shared_system = false
        generator.is_shared_system_isdefaulted = true
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::Vehicle objects
  # If an EV charger is found, apply_ev_charger is run to set its default values
  # Default values for the battery are first applied with the apply_battery method, then electric vehicle-specific fields are populated such as miles/year, hours/week, and fraction charged at home.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_vehicles(hpxml_bldg, schedules_file)
    default_values = get_electric_vehicle_values
    hpxml_bldg.vehicles.each do |vehicle|
      next unless vehicle.vehicle_type == HPXML::VehicleTypeBEV

      apply_battery(vehicle, default_values)
      if vehicle.battery_type.nil?
        vehicle.battery_type = default_values[:battery_type]
        vehicle.battery_type_isdefaulted = true
      end
      if vehicle.fuel_economy_combined.nil? || vehicle.fuel_economy_units.nil?
        vehicle.fuel_economy_combined = default_values[:fuel_economy_combined]
        vehicle.fuel_economy_combined_isdefaulted = true
        vehicle.fuel_economy_units = default_values[:fuel_economy_units]
        vehicle.fuel_economy_units_isdefaulted = true
      end
      miles_to_hrs_per_week = default_values[:miles_per_year] / default_values[:hours_per_week]
      if vehicle.miles_per_year.nil? && vehicle.hours_per_week.nil?
        vehicle.miles_per_year = default_values[:miles_per_year]
        vehicle.miles_per_year_isdefaulted = true
        vehicle.hours_per_week = default_values[:hours_per_week]
        vehicle.hours_per_week_isdefaulted = true
      elsif (not vehicle.hours_per_week.nil?) && vehicle.miles_per_year.nil?
        vehicle.miles_per_year = (vehicle.hours_per_week * miles_to_hrs_per_week).round
        vehicle.miles_per_year_isdefaulted = true
      elsif (not vehicle.miles_per_year.nil?) && vehicle.hours_per_week.nil?
        vehicle.hours_per_week = (vehicle.miles_per_year / miles_to_hrs_per_week).round(1)
        vehicle.hours_per_week_isdefaulted = true
      end
      if vehicle.fraction_charged_home.nil?
        vehicle.fraction_charged_home = default_values[:fraction_charged_home]
        vehicle.fraction_charged_home_isdefaulted = true
      end
      if vehicle.ev_usage_multiplier.nil?
        vehicle.ev_usage_multiplier = 1.0
        vehicle.ev_usage_multiplier_isdefaulted = true
      end
      schedules_file_includes_ev = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:ElectricVehicleCharging].name) && schedules_file.includes_col_name(SchedulesFile::Columns[:ElectricVehicleDischarging].name))
      if vehicle.ev_weekday_fractions.nil? && !schedules_file_includes_ev
        vehicle.ev_weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:ElectricVehicle].name]['WeekdayScheduleFractions']
        vehicle.ev_weekday_fractions_isdefaulted = true
      end
      if vehicle.ev_weekend_fractions.nil? && !schedules_file_includes_ev
        vehicle.ev_weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:ElectricVehicle].name]['WeekendScheduleFractions']
        vehicle.ev_weekend_fractions_isdefaulted = true
      end
      if vehicle.ev_monthly_multipliers.nil? && !schedules_file_includes_ev
        vehicle.ev_monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:ElectricVehicle].name]['MonthlyScheduleMultipliers']
        vehicle.ev_monthly_multipliers_isdefaulted = true
      end

      next if vehicle.ev_charger.nil?

      apply_ev_charger(vehicle.ev_charger)
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::ElectricVehicleCharger objects
  #
  # @param ev_charger [HPXML::ElectricVehicleCharger] Object that defines a single electric vehicle charger
  # @return [nil]
  def self.apply_ev_charger(ev_charger)
    if ev_charger.charging_level.nil? && ev_charger.charging_power.nil?
      ev_charger.charging_level = 2
      ev_charger.charging_level_isdefaulted = true
    end
    if ev_charger.charging_power.nil?
      if ev_charger.charging_level == 1
        ev_charger.charging_power = 1600.0
      elsif ev_charger.charging_level >= 2
        ev_charger.charging_power = 5690.0
      end
      ev_charger.charging_power_isdefaulted = true
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::Battery objects
  # This method assigns fields specific to home battery systems, and calls a general method (apply_battery) that defaults values for any battery system.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_batteries(hpxml_bldg)
    default_values = get_battery_values(hpxml_bldg.has_location(HPXML::LocationGarage))
    hpxml_bldg.batteries.each do |battery|
      if battery.location.nil?
        battery.location = default_values[:location]
        battery.location_isdefaulted = true
      end
      if battery.is_shared_system.nil?
        battery.is_shared_system = false
        battery.is_shared_system_isdefaulted = true
      end
      if battery.round_trip_efficiency.nil?
        battery.round_trip_efficiency = default_values[:round_trip_efficiency]
        battery.round_trip_efficiency_isdefaulted = true
      end

      apply_battery(battery, default_values)
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::Battery or HPXML::Vehicle objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param default_values [Hash] map of home battery or vehicle battery properties to default values
  # @return [nil]
  def self.apply_battery(battery, default_values)
    # if battery.lifetime_model.nil?
    #   battery.lifetime_model = default_values[:lifetime_model]
    #   battery.lifetime_model_isdefaulted = true
    # end
    if battery.nominal_voltage.nil?
      battery.nominal_voltage = default_values[:nominal_voltage] # V
      battery.nominal_voltage_isdefaulted = true
    end
    if battery.nominal_capacity_kwh.nil? && battery.nominal_capacity_ah.nil?
      # Calculate nominal capacity from usable capacity or rated power output if available
      if not battery.usable_capacity_kwh.nil?
        battery.nominal_capacity_kwh = (battery.usable_capacity_kwh / default_values[:usable_fraction]).round(2)
        battery.nominal_capacity_kwh_isdefaulted = true
      elsif not battery.usable_capacity_ah.nil?
        battery.nominal_capacity_ah = (battery.usable_capacity_ah / default_values[:usable_fraction]).round(2)
        battery.nominal_capacity_ah_isdefaulted = true
      elsif battery.respond_to?(:rated_power_output) && (not battery.rated_power_output.nil?)
        battery.nominal_capacity_kwh = (UnitConversions.convert(battery.rated_power_output, 'W', 'kW') / 0.5).round(2)
        battery.nominal_capacity_kwh_isdefaulted = true
      else
        battery.nominal_capacity_kwh = default_values[:nominal_capacity_kwh] # kWh
        battery.nominal_capacity_kwh_isdefaulted = true
      end
    end
    if battery.usable_capacity_kwh.nil? && battery.usable_capacity_ah.nil?
      # Calculate usable capacity from nominal capacity
      if not battery.nominal_capacity_kwh.nil?
        battery.usable_capacity_kwh = (battery.nominal_capacity_kwh * default_values[:usable_fraction]).round(2)
        battery.usable_capacity_kwh_isdefaulted = true
      elsif not battery.nominal_capacity_ah.nil?
        battery.usable_capacity_ah = (battery.nominal_capacity_ah * default_values[:usable_fraction]).round(2)
        battery.usable_capacity_ah_isdefaulted = true
      end
    end
    return unless battery.respond_to?(:rated_power_output) && battery.rated_power_output.nil?

    # Calculate rated power from nominal capacity
    if not battery.nominal_capacity_kwh.nil?
      battery.rated_power_output = (UnitConversions.convert(battery.nominal_capacity_kwh, 'kWh', 'Wh') * 0.5).round(0)
    elsif not battery.nominal_capacity_ah.nil?
      battery.rated_power_output = (UnitConversions.convert(Battery.get_kWh_from_Ah(battery.nominal_capacity_ah, battery.nominal_voltage), 'kWh', 'Wh') * 0.5).round(0)
    end
    battery.rated_power_output_isdefaulted = true
  end

  # Assigns default values for omitted optional inputs in the HPXML::ClothesWasher, HPXML::ClothesDryer,
  # HPXML::Dishwasher, HPXML::Refrigerator, HPXML::Freezer, HPXML::CookingRange, and HPXML::Oven objects.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def self.apply_appliances(hpxml_bldg, eri_version, schedules_file)
    nbeds = hpxml_bldg.building_construction.number_of_bedrooms

    # Default clothes washer
    if hpxml_bldg.clothes_washers.size > 0
      clothes_washer = hpxml_bldg.clothes_washers[0]
      if clothes_washer.is_shared_appliance.nil?
        clothes_washer.is_shared_appliance = false
        clothes_washer.is_shared_appliance_isdefaulted = true
      end
      if clothes_washer.location.nil?
        clothes_washer.location = HPXML::LocationConditionedSpace
        clothes_washer.location_isdefaulted = true
      end
      if clothes_washer.rated_annual_kwh.nil?
        default_values = get_clothes_washer_values(eri_version)
        clothes_washer.integrated_modified_energy_factor = default_values[:integrated_modified_energy_factor]
        clothes_washer.integrated_modified_energy_factor_isdefaulted = true
        clothes_washer.rated_annual_kwh = default_values[:rated_annual_kwh]
        clothes_washer.rated_annual_kwh_isdefaulted = true
        clothes_washer.label_electric_rate = default_values[:label_electric_rate]
        clothes_washer.label_electric_rate_isdefaulted = true
        clothes_washer.label_gas_rate = default_values[:label_gas_rate]
        clothes_washer.label_gas_rate_isdefaulted = true
        clothes_washer.label_annual_gas_cost = default_values[:label_annual_gas_cost]
        clothes_washer.label_annual_gas_cost_isdefaulted = true
        clothes_washer.capacity = default_values[:capacity]
        clothes_washer.capacity_isdefaulted = true
        clothes_washer.label_usage = default_values[:label_usage]
        clothes_washer.label_usage_isdefaulted = true
      end
      if clothes_washer.usage_multiplier.nil?
        clothes_washer.usage_multiplier = 1.0
        clothes_washer.usage_multiplier_isdefaulted = true
      end
      schedules_file_includes_cw = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:ClothesWasher].name))
      if clothes_washer.weekday_fractions.nil? && !schedules_file_includes_cw
        clothes_washer.weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:ClothesWasher].name]['WeekdayScheduleFractions']
        clothes_washer.weekday_fractions_isdefaulted = true
      end
      if clothes_washer.weekend_fractions.nil? && !schedules_file_includes_cw
        clothes_washer.weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:ClothesWasher].name]['WeekendScheduleFractions']
        clothes_washer.weekend_fractions_isdefaulted = true
      end
      if clothes_washer.monthly_multipliers.nil? && !schedules_file_includes_cw
        clothes_washer.monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:ClothesWasher].name]['MonthlyScheduleMultipliers']
        clothes_washer.monthly_multipliers_isdefaulted = true
      end
    end

    # Default clothes dryer
    if hpxml_bldg.clothes_dryers.size > 0
      clothes_dryer = hpxml_bldg.clothes_dryers[0]
      default_values = get_clothes_dryer_values(eri_version, clothes_dryer.fuel_type)
      if clothes_dryer.is_shared_appliance.nil?
        clothes_dryer.is_shared_appliance = false
        clothes_dryer.is_shared_appliance_isdefaulted = true
      end
      if clothes_dryer.location.nil?
        clothes_dryer.location = HPXML::LocationConditionedSpace
        clothes_dryer.location_isdefaulted = true
      end
      if clothes_dryer.combined_energy_factor.nil? && clothes_dryer.energy_factor.nil?
        clothes_dryer.combined_energy_factor = default_values[:combined_energy_factor]
        clothes_dryer.combined_energy_factor_isdefaulted = true
      end
      if clothes_dryer.control_type.nil?
        clothes_dryer.control_type = default_values[:control_type]
        clothes_dryer.control_type_isdefaulted = true
      end
      if clothes_dryer.usage_multiplier.nil?
        clothes_dryer.usage_multiplier = 1.0
        clothes_dryer.usage_multiplier_isdefaulted = true
      end
      if clothes_dryer.drying_method.nil?
        clothes_dryer.drying_method = HPXML::DryingMethodConventional
        clothes_dryer.drying_method_isdefaulted = true
      end
      if clothes_dryer.is_vented.nil?
        clothes_dryer.is_vented = (![HPXML::DryingMethodCondensing, HPXML::DryingMethodHeatPump].include? clothes_dryer.drying_method)
        clothes_dryer.is_vented_isdefaulted = true
      end
      if clothes_dryer.is_vented && clothes_dryer.vented_flow_rate.nil?
        clothes_dryer.vented_flow_rate = 100.0
        clothes_dryer.vented_flow_rate_isdefaulted = true
      end
      schedules_file_includes_cd = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:ClothesDryer].name))
      if clothes_dryer.weekday_fractions.nil? && !schedules_file_includes_cd
        clothes_dryer.weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:ClothesDryer].name]['WeekdayScheduleFractions']
        clothes_dryer.weekday_fractions_isdefaulted = true
      end
      if clothes_dryer.weekend_fractions.nil? && !schedules_file_includes_cd
        clothes_dryer.weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:ClothesDryer].name]['WeekendScheduleFractions']
        clothes_dryer.weekend_fractions_isdefaulted = true
      end
      if clothes_dryer.monthly_multipliers.nil? && !schedules_file_includes_cd
        clothes_dryer.monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:ClothesDryer].name]['MonthlyScheduleMultipliers']
        clothes_dryer.monthly_multipliers_isdefaulted = true
      end
    end

    # Default dishwasher
    if hpxml_bldg.dishwashers.size > 0
      dishwasher = hpxml_bldg.dishwashers[0]
      if dishwasher.is_shared_appliance.nil?
        dishwasher.is_shared_appliance = false
        dishwasher.is_shared_appliance_isdefaulted = true
      end
      if dishwasher.location.nil?
        dishwasher.location = HPXML::LocationConditionedSpace
        dishwasher.location_isdefaulted = true
      end
      if dishwasher.place_setting_capacity.nil?
        default_values = get_dishwasher_values(eri_version)
        dishwasher.rated_annual_kwh = default_values[:rated_annual_kwh]
        dishwasher.rated_annual_kwh_isdefaulted = true
        dishwasher.label_electric_rate = default_values[:label_electric_rate]
        dishwasher.label_electric_rate_isdefaulted = true
        dishwasher.label_gas_rate = default_values[:label_gas_rate]
        dishwasher.label_gas_rate_isdefaulted = true
        dishwasher.label_annual_gas_cost = default_values[:label_annual_gas_cost]
        dishwasher.label_annual_gas_cost_isdefaulted = true
        dishwasher.label_usage = default_values[:label_usage]
        dishwasher.label_usage_isdefaulted = true
        dishwasher.place_setting_capacity = default_values[:place_setting_capacity]
        dishwasher.place_setting_capacity_isdefaulted = true
      end
      if dishwasher.usage_multiplier.nil?
        dishwasher.usage_multiplier = 1.0
        dishwasher.usage_multiplier_isdefaulted = true
      end
      schedules_file_includes_dw = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:Dishwasher].name))
      if dishwasher.weekday_fractions.nil? && !schedules_file_includes_dw
        dishwasher.weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:Dishwasher].name]['WeekdayScheduleFractions']
        dishwasher.weekday_fractions_isdefaulted = true
      end
      if dishwasher.weekend_fractions.nil? && !schedules_file_includes_dw
        dishwasher.weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:Dishwasher].name]['WeekendScheduleFractions']
        dishwasher.weekend_fractions_isdefaulted = true
      end
      if dishwasher.monthly_multipliers.nil? && !schedules_file_includes_dw
        dishwasher.monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:Dishwasher].name]['MonthlyScheduleMultipliers']
        dishwasher.monthly_multipliers_isdefaulted = true
      end
    end

    # Default refrigerators
    if hpxml_bldg.refrigerators.size == 1
      hpxml_bldg.refrigerators[0].primary_indicator = true
      hpxml_bldg.refrigerators[0].primary_indicator_isdefaulted = true
    end
    hpxml_bldg.refrigerators.each do |refrigerator|
      schedules_includes_fractions_multipliers = (!refrigerator.weekday_fractions.nil? || !refrigerator.weekend_fractions.nil? || !refrigerator.monthly_multipliers.nil?)
      if not refrigerator.primary_indicator # extra refrigerator
        if refrigerator.location.nil?
          refrigerator.location = get_freezer_or_extra_fridge_location(hpxml_bldg)
          refrigerator.location_isdefaulted = true
        end
        if refrigerator.rated_annual_kwh.nil?
          default_values = get_extra_refrigerator_values()
          refrigerator.rated_annual_kwh = default_values[:rated_annual_kwh]
          refrigerator.rated_annual_kwh_isdefaulted = true
        end
        schedules_file_includes_extrafridge = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:ExtraRefrigerator].name))
        if !schedules_file_includes_extrafridge
          if schedules_includes_fractions_multipliers
            if refrigerator.weekday_fractions.nil?
              refrigerator.weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:ExtraRefrigerator].name]['WeekdayScheduleFractions']
              refrigerator.weekday_fractions_isdefaulted = true
            end
            if refrigerator.weekend_fractions.nil?
              refrigerator.weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:ExtraRefrigerator].name]['WeekendScheduleFractions']
              refrigerator.weekend_fractions_isdefaulted = true
            end
            if refrigerator.monthly_multipliers.nil?
              refrigerator.monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:ExtraRefrigerator].name]['MonthlyScheduleMultipliers']
              refrigerator.monthly_multipliers_isdefaulted = true
            end
          else
            if refrigerator.constant_coefficients.nil?
              refrigerator.constant_coefficients = @default_schedules_csv_data[SchedulesFile::Columns[:ExtraRefrigerator].name]['ConstantScheduleCoefficients']
              refrigerator.constant_coefficients_isdefaulted = true
            end
            if refrigerator.temperature_coefficients.nil?
              refrigerator.temperature_coefficients = @default_schedules_csv_data[SchedulesFile::Columns[:ExtraRefrigerator].name]['TemperatureScheduleCoefficients']
              refrigerator.temperature_coefficients_isdefaulted = true
            end
          end
        end
      else # primary refrigerator
        if refrigerator.location.nil?
          refrigerator.location = HPXML::LocationConditionedSpace
          refrigerator.location_isdefaulted = true
        end
        if refrigerator.rated_annual_kwh.nil?
          default_values = get_refrigerator_values(nbeds)
          refrigerator.rated_annual_kwh = default_values[:rated_annual_kwh]
          refrigerator.rated_annual_kwh_isdefaulted = true
        end
        schedules_file_includes_fridge = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:Refrigerator].name))
        if !schedules_file_includes_fridge
          if schedules_includes_fractions_multipliers
            if refrigerator.weekday_fractions.nil?
              refrigerator.weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:Refrigerator].name]['WeekdayScheduleFractions']
              refrigerator.weekday_fractions_isdefaulted = true
            end
            if refrigerator.weekend_fractions.nil?
              refrigerator.weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:Refrigerator].name]['WeekendScheduleFractions']
              refrigerator.weekend_fractions_isdefaulted = true
            end
            if refrigerator.monthly_multipliers.nil?
              refrigerator.monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:Refrigerator].name]['MonthlyScheduleMultipliers']
              refrigerator.monthly_multipliers_isdefaulted = true
            end
          else
            if refrigerator.constant_coefficients.nil?
              refrigerator.constant_coefficients = @default_schedules_csv_data[SchedulesFile::Columns[:Refrigerator].name]['ConstantScheduleCoefficients']
              refrigerator.constant_coefficients_isdefaulted = true
            end
            if refrigerator.temperature_coefficients.nil?
              refrigerator.temperature_coefficients = @default_schedules_csv_data[SchedulesFile::Columns[:Refrigerator].name]['TemperatureScheduleCoefficients']
              refrigerator.temperature_coefficients_isdefaulted = true
            end
          end
        end
      end
      if refrigerator.usage_multiplier.nil?
        refrigerator.usage_multiplier = 1.0
        refrigerator.usage_multiplier_isdefaulted = true
      end
    end

    # Default freezer
    hpxml_bldg.freezers.each do |freezer|
      if freezer.location.nil?
        freezer.location = get_freezer_or_extra_fridge_location(hpxml_bldg)
        freezer.location_isdefaulted = true
      end
      if freezer.rated_annual_kwh.nil?
        default_values = get_freezer_values()
        freezer.rated_annual_kwh = default_values[:rated_annual_kwh]
        freezer.rated_annual_kwh_isdefaulted = true
      end
      if freezer.usage_multiplier.nil?
        freezer.usage_multiplier = 1.0
        freezer.usage_multiplier_isdefaulted = true
      end
      schedules_includes_schedule_coefficients = (!freezer.constant_coefficients.nil? || !freezer.temperature_coefficients.nil?)
      schedules_file_includes_freezer = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:Freezer].name))
      next unless !schedules_includes_schedule_coefficients

      if freezer.weekday_fractions.nil? && !schedules_file_includes_freezer
        freezer.weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:Freezer].name]['WeekdayScheduleFractions']
        freezer.weekday_fractions_isdefaulted = true
      end
      if freezer.weekend_fractions.nil? && !schedules_file_includes_freezer
        freezer.weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:Freezer].name]['WeekendScheduleFractions']
        freezer.weekend_fractions_isdefaulted = true
      end
      if freezer.monthly_multipliers.nil? && !schedules_file_includes_freezer
        freezer.monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:Freezer].name]['MonthlyScheduleMultipliers']
        freezer.monthly_multipliers_isdefaulted = true
      end
    end

    # Default cooking range
    if hpxml_bldg.cooking_ranges.size > 0
      cooking_range = hpxml_bldg.cooking_ranges[0]
      if cooking_range.location.nil?
        cooking_range.location = HPXML::LocationConditionedSpace
        cooking_range.location_isdefaulted = true
      end
      if cooking_range.is_induction.nil?
        default_values = get_range_oven_values()
        cooking_range.is_induction = default_values[:is_induction]
        cooking_range.is_induction_isdefaulted = true
      end
      if cooking_range.usage_multiplier.nil?
        cooking_range.usage_multiplier = 1.0
        cooking_range.usage_multiplier_isdefaulted = true
      end
      schedules_file_includes_range = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:CookingRange].name))
      if cooking_range.weekday_fractions.nil? && !schedules_file_includes_range
        cooking_range.weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:CookingRange].name]['WeekdayScheduleFractions']
        cooking_range.weekday_fractions_isdefaulted = true
      end
      if cooking_range.weekend_fractions.nil? && !schedules_file_includes_range
        cooking_range.weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:CookingRange].name]['WeekendScheduleFractions']
        cooking_range.weekend_fractions_isdefaulted = true
      end
      if cooking_range.monthly_multipliers.nil? && !schedules_file_includes_range
        cooking_range.monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:CookingRange].name]['MonthlyScheduleMultipliers']
        cooking_range.monthly_multipliers_isdefaulted = true
      end
    end

    # Default oven
    if hpxml_bldg.ovens.size > 0
      oven = hpxml_bldg.ovens[0]
      if oven.is_convection.nil?
        default_values = get_range_oven_values()
        oven.is_convection = default_values[:is_convection]
        oven.is_convection_isdefaulted = true
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::Lighting and HPXML::LightingGroup objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def self.apply_lighting(hpxml_bldg, schedules_file)
    return if hpxml_bldg.lighting_groups.empty?

    if hpxml_bldg.lighting.interior_usage_multiplier.nil?
      hpxml_bldg.lighting.interior_usage_multiplier = 1.0
      hpxml_bldg.lighting.interior_usage_multiplier_isdefaulted = true
    end
    if hpxml_bldg.lighting.garage_usage_multiplier.nil?
      hpxml_bldg.lighting.garage_usage_multiplier = 1.0
      hpxml_bldg.lighting.garage_usage_multiplier_isdefaulted = true
    end
    if hpxml_bldg.lighting.exterior_usage_multiplier.nil?
      hpxml_bldg.lighting.exterior_usage_multiplier = 1.0
      hpxml_bldg.lighting.exterior_usage_multiplier_isdefaulted = true
    end
    schedules_file_includes_lighting_interior = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:LightingInterior].name))
    if hpxml_bldg.lighting.interior_weekday_fractions.nil? && !schedules_file_includes_lighting_interior
      hpxml_bldg.lighting.interior_weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:LightingInterior].name]['InteriorWeekdayScheduleFractions']
      hpxml_bldg.lighting.interior_weekday_fractions_isdefaulted = true
    end
    if hpxml_bldg.lighting.interior_weekend_fractions.nil? && !schedules_file_includes_lighting_interior
      hpxml_bldg.lighting.interior_weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:LightingInterior].name]['InteriorWeekendScheduleFractions']
      hpxml_bldg.lighting.interior_weekend_fractions_isdefaulted = true
    end
    if hpxml_bldg.lighting.interior_monthly_multipliers.nil? && !schedules_file_includes_lighting_interior
      hpxml_bldg.lighting.interior_monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:LightingInterior].name]['InteriorMonthlyScheduleMultipliers']
      hpxml_bldg.lighting.interior_monthly_multipliers_isdefaulted = true
    end
    if hpxml_bldg.has_location(HPXML::LocationGarage)
      schedules_file_includes_lighting_garage = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:LightingGarage].name))
      if hpxml_bldg.lighting.garage_weekday_fractions.nil? && !schedules_file_includes_lighting_garage
        hpxml_bldg.lighting.garage_weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:LightingGarage].name]['GarageWeekdayScheduleFractions']
        hpxml_bldg.lighting.garage_weekday_fractions_isdefaulted = true
      end
      if hpxml_bldg.lighting.garage_weekend_fractions.nil? && !schedules_file_includes_lighting_garage
        hpxml_bldg.lighting.garage_weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:LightingGarage].name]['GarageWeekendScheduleFractions']
        hpxml_bldg.lighting.garage_weekend_fractions_isdefaulted = true
      end
      if hpxml_bldg.lighting.garage_monthly_multipliers.nil? && !schedules_file_includes_lighting_garage
        hpxml_bldg.lighting.garage_monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:LightingGarage].name]['GarageMonthlyScheduleMultipliers']
        hpxml_bldg.lighting.garage_monthly_multipliers_isdefaulted = true
      end
    end
    schedules_file_includes_lighting_exterior = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:LightingExterior].name))
    if hpxml_bldg.lighting.exterior_weekday_fractions.nil? && !schedules_file_includes_lighting_exterior
      hpxml_bldg.lighting.exterior_weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:LightingExterior].name]['ExteriorWeekdayScheduleFractions']
      hpxml_bldg.lighting.exterior_weekday_fractions_isdefaulted = true
    end
    if hpxml_bldg.lighting.exterior_weekend_fractions.nil? && !schedules_file_includes_lighting_exterior
      hpxml_bldg.lighting.exterior_weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:LightingExterior].name]['ExteriorWeekendScheduleFractions']
      hpxml_bldg.lighting.exterior_weekend_fractions_isdefaulted = true
    end
    if hpxml_bldg.lighting.exterior_monthly_multipliers.nil? && !schedules_file_includes_lighting_exterior
      hpxml_bldg.lighting.exterior_monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:LightingExterior].name]['ExteriorMonthlyScheduleMultipliers']
      hpxml_bldg.lighting.exterior_monthly_multipliers_isdefaulted = true
    end
    if hpxml_bldg.lighting.holiday_exists
      if hpxml_bldg.lighting.holiday_kwh_per_day.nil?
        # From LA100 repo (2017)
        if hpxml_bldg.building_construction.residential_facility_type == HPXML::ResidentialTypeSFD
          hpxml_bldg.lighting.holiday_kwh_per_day = 1.1
        else # Multifamily and others
          hpxml_bldg.lighting.holiday_kwh_per_day = 0.55
        end
        hpxml_bldg.lighting.holiday_kwh_per_day_isdefaulted = true
      end
      if hpxml_bldg.lighting.holiday_period_begin_month.nil?
        hpxml_bldg.lighting.holiday_period_begin_month = 11
        hpxml_bldg.lighting.holiday_period_begin_month_isdefaulted = true
        hpxml_bldg.lighting.holiday_period_begin_day = 24
        hpxml_bldg.lighting.holiday_period_begin_day_isdefaulted = true
      end
      if hpxml_bldg.lighting.holiday_period_end_day.nil?
        hpxml_bldg.lighting.holiday_period_end_month = 1
        hpxml_bldg.lighting.holiday_period_end_month_isdefaulted = true
        hpxml_bldg.lighting.holiday_period_end_day = 6
        hpxml_bldg.lighting.holiday_period_end_day_isdefaulted = true
      end
      schedules_file_includes_lighting_holiday_exterior = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:LightingExteriorHoliday].name))
      if hpxml_bldg.lighting.holiday_weekday_fractions.nil? && !schedules_file_includes_lighting_holiday_exterior
        hpxml_bldg.lighting.holiday_weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:LightingExteriorHoliday].name]['WeekdayScheduleFractions']
        hpxml_bldg.lighting.holiday_weekday_fractions_isdefaulted = true
      end
      if hpxml_bldg.lighting.holiday_weekend_fractions.nil? && !schedules_file_includes_lighting_holiday_exterior
        hpxml_bldg.lighting.holiday_weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:LightingExteriorHoliday].name]['WeekendScheduleFractions']
        hpxml_bldg.lighting.holiday_weekend_fractions_isdefaulted = true
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::CeilingFan objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def self.apply_ceiling_fans(hpxml_bldg, weather, schedules_file)
    return if hpxml_bldg.ceiling_fans.size == 0

    nbeds = hpxml_bldg.building_construction.number_of_bedrooms

    ceiling_fan = hpxml_bldg.ceiling_fans[0]
    if ceiling_fan.efficiency.nil? && ceiling_fan.label_energy_use.nil?
      ceiling_fan.label_energy_use = get_ceiling_fan_power()
      ceiling_fan.label_energy_use_isdefaulted = true
    end
    if ceiling_fan.count.nil?
      ceiling_fan.count = get_ceiling_fan_count(nbeds)
      ceiling_fan.count_isdefaulted = true
    end
    schedules_file_includes_ceiling_fan = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:CeilingFan].name))
    if ceiling_fan.weekday_fractions.nil? && !schedules_file_includes_ceiling_fan
      ceiling_fan.weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:CeilingFan].name]['WeekdayScheduleFractions']
      ceiling_fan.weekday_fractions_isdefaulted = true
    end
    if ceiling_fan.weekend_fractions.nil? && !schedules_file_includes_ceiling_fan
      ceiling_fan.weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:CeilingFan].name]['WeekendScheduleFractions']
      ceiling_fan.weekend_fractions_isdefaulted = true
    end
    if ceiling_fan.monthly_multipliers.nil? && !schedules_file_includes_ceiling_fan
      ceiling_fan.monthly_multipliers = Defaults.get_ceiling_fan_months(weather).join(', ')
      ceiling_fan.monthly_multipliers_isdefaulted = true
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::Pool and HPXML::PermanentSpa objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def self.apply_pools_and_permanent_spas(hpxml_bldg, schedules_file)
    nbeds = hpxml_bldg.building_construction.number_of_bedrooms
    n_occ = hpxml_bldg.building_occupancy.number_of_residents
    unit_type = hpxml_bldg.building_construction.residential_facility_type
    cfa = hpxml_bldg.building_construction.conditioned_floor_area
    hpxml_bldg.pools.each do |pool|
      next if pool.type == HPXML::TypeNone

      if pool.pump_type != HPXML::TypeNone
        # Pump
        if pool.pump_kwh_per_year.nil?
          pool.pump_kwh_per_year = get_pool_pump_annual_energy(cfa, nbeds, n_occ, unit_type)
          pool.pump_kwh_per_year_isdefaulted = true
        end
        if pool.pump_usage_multiplier.nil?
          pool.pump_usage_multiplier = 1.0
          pool.pump_usage_multiplier_isdefaulted = true
        end
        schedules_file_includes_pool_pump = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:PoolPump].name))
        if pool.pump_weekday_fractions.nil? && !schedules_file_includes_pool_pump
          pool.pump_weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:PoolPump].name]['WeekdayScheduleFractions']
          pool.pump_weekday_fractions_isdefaulted = true
        end
        if pool.pump_weekend_fractions.nil? && !schedules_file_includes_pool_pump
          pool.pump_weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:PoolPump].name]['WeekendScheduleFractions']
          pool.pump_weekend_fractions_isdefaulted = true
        end
        if pool.pump_monthly_multipliers.nil? && !schedules_file_includes_pool_pump
          pool.pump_monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:PoolPump].name]['MonthlyScheduleMultipliers']
          pool.pump_monthly_multipliers_isdefaulted = true
        end
      end

      next unless pool.heater_type != HPXML::TypeNone

      # Heater
      if pool.heater_load_value.nil?
        default_heater_load_units, default_heater_load_value = get_pool_heater_annual_energy(cfa, nbeds, n_occ, unit_type, pool.heater_type)
        pool.heater_load_units = default_heater_load_units
        pool.heater_load_value = default_heater_load_value
        pool.heater_load_value_isdefaulted = true
      end
      if pool.heater_usage_multiplier.nil?
        pool.heater_usage_multiplier = 1.0
        pool.heater_usage_multiplier_isdefaulted = true
      end
      schedules_file_includes_pool_heater = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:PoolHeater].name))
      if pool.heater_weekday_fractions.nil? && !schedules_file_includes_pool_heater
        pool.heater_weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:PoolHeater].name]['WeekdayScheduleFractions']
        pool.heater_weekday_fractions_isdefaulted = true
      end
      if pool.heater_weekend_fractions.nil? && !schedules_file_includes_pool_heater
        pool.heater_weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:PoolHeater].name]['WeekendScheduleFractions']
        pool.heater_weekend_fractions_isdefaulted = true
      end
      if pool.heater_monthly_multipliers.nil? && !schedules_file_includes_pool_heater
        pool.heater_monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:PoolHeater].name]['MonthlyScheduleMultipliers']
        pool.heater_monthly_multipliers_isdefaulted = true
      end
    end

    hpxml_bldg.permanent_spas.each do |spa|
      next if spa.type == HPXML::TypeNone

      if spa.pump_type != HPXML::TypeNone
        # Pump
        if spa.pump_kwh_per_year.nil?
          spa.pump_kwh_per_year = get_permanent_spa_pump_annual_energy(cfa, nbeds, n_occ, unit_type)
          spa.pump_kwh_per_year_isdefaulted = true
        end
        if spa.pump_usage_multiplier.nil?
          spa.pump_usage_multiplier = 1.0
          spa.pump_usage_multiplier_isdefaulted = true
        end
        schedules_file_includes_permanent_spa_pump = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:PermanentSpaPump].name))
        if spa.pump_weekday_fractions.nil? && !schedules_file_includes_permanent_spa_pump
          spa.pump_weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:PermanentSpaPump].name]['WeekdayScheduleFractions']
          spa.pump_weekday_fractions_isdefaulted = true
        end
        if spa.pump_weekend_fractions.nil? && !schedules_file_includes_permanent_spa_pump
          spa.pump_weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:PermanentSpaPump].name]['WeekendScheduleFractions']
          spa.pump_weekend_fractions_isdefaulted = true
        end
        if spa.pump_monthly_multipliers.nil? && !schedules_file_includes_permanent_spa_pump
          spa.pump_monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:PermanentSpaPump].name]['MonthlyScheduleMultipliers']
          spa.pump_monthly_multipliers_isdefaulted = true
        end
      end

      next unless spa.heater_type != HPXML::TypeNone

      # Heater
      if spa.heater_load_value.nil?
        default_heater_load_units, default_heater_load_value = get_permanent_spa_heater_annual_energy(cfa, nbeds, n_occ, unit_type, spa.heater_type)
        spa.heater_load_units = default_heater_load_units
        spa.heater_load_value = default_heater_load_value
        spa.heater_load_value_isdefaulted = true
      end
      if spa.heater_usage_multiplier.nil?
        spa.heater_usage_multiplier = 1.0
        spa.heater_usage_multiplier_isdefaulted = true
      end
      schedules_file_includes_permanent_spa_heater = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:PermanentSpaHeater].name))
      if spa.heater_weekday_fractions.nil? && !schedules_file_includes_permanent_spa_heater
        spa.heater_weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:PermanentSpaHeater].name]['WeekdayScheduleFractions']
        spa.heater_weekday_fractions_isdefaulted = true
      end
      if spa.heater_weekend_fractions.nil? && !schedules_file_includes_permanent_spa_heater
        spa.heater_weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:PermanentSpaHeater].name]['WeekendScheduleFractions']
        spa.heater_weekend_fractions_isdefaulted = true
      end
      if spa.heater_monthly_multipliers.nil? && !schedules_file_includes_permanent_spa_heater
        spa.heater_monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:PermanentSpaHeater].name]['MonthlyScheduleMultipliers']
        spa.heater_monthly_multipliers_isdefaulted = true
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::PlugLoad objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def self.apply_plug_loads(hpxml_bldg, schedules_file)
    cfa = hpxml_bldg.building_construction.conditioned_floor_area
    nbeds = hpxml_bldg.building_construction.number_of_bedrooms
    n_occ = hpxml_bldg.building_occupancy.number_of_residents
    unit_type = hpxml_bldg.building_construction.residential_facility_type
    hpxml_bldg.plug_loads.each do |plug_load|
      case plug_load.plug_load_type
      when HPXML::PlugLoadTypeOther
        default_annual_kwh, default_sens_frac, default_lat_frac = get_residual_mels_values(cfa, n_occ, unit_type)
        if plug_load.kwh_per_year.nil?
          plug_load.kwh_per_year = default_annual_kwh
          plug_load.kwh_per_year_isdefaulted = true
        end
        if plug_load.frac_sensible.nil?
          plug_load.frac_sensible = default_sens_frac
          plug_load.frac_sensible_isdefaulted = true
        end
        if plug_load.frac_latent.nil?
          plug_load.frac_latent = default_lat_frac
          plug_load.frac_latent_isdefaulted = true
        end
        schedules_file_includes_plug_loads_other = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:PlugLoadsOther].name))
        if plug_load.weekday_fractions.nil? && !schedules_file_includes_plug_loads_other
          plug_load.weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:PlugLoadsOther].name]['WeekdayScheduleFractions']
          plug_load.weekday_fractions_isdefaulted = true
        end
        if plug_load.weekend_fractions.nil? && !schedules_file_includes_plug_loads_other
          plug_load.weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:PlugLoadsOther].name]['WeekendScheduleFractions']
          plug_load.weekend_fractions_isdefaulted = true
        end
        if plug_load.monthly_multipliers.nil? && !schedules_file_includes_plug_loads_other
          plug_load.monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:PlugLoadsOther].name]['MonthlyScheduleMultipliers']
          plug_load.monthly_multipliers_isdefaulted = true
        end
      when HPXML::PlugLoadTypeTelevision
        default_annual_kwh, default_sens_frac, default_lat_frac = get_televisions_values(cfa, nbeds, n_occ, unit_type)
        if plug_load.kwh_per_year.nil?
          plug_load.kwh_per_year = default_annual_kwh
          plug_load.kwh_per_year_isdefaulted = true
        end
        if plug_load.frac_sensible.nil?
          plug_load.frac_sensible = default_sens_frac
          plug_load.frac_sensible_isdefaulted = true
        end
        if plug_load.frac_latent.nil?
          plug_load.frac_latent = default_lat_frac
          plug_load.frac_latent_isdefaulted = true
        end
        schedules_file_includes_plug_loads_tv = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:PlugLoadsTV].name))
        if plug_load.weekday_fractions.nil? && !schedules_file_includes_plug_loads_tv
          plug_load.weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:PlugLoadsTV].name]['WeekdayScheduleFractions']
          plug_load.weekday_fractions_isdefaulted = true
        end
        if plug_load.weekend_fractions.nil? && !schedules_file_includes_plug_loads_tv
          plug_load.weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:PlugLoadsTV].name]['WeekendScheduleFractions']
          plug_load.weekend_fractions_isdefaulted = true
        end
        if plug_load.monthly_multipliers.nil? && !schedules_file_includes_plug_loads_tv
          plug_load.monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:PlugLoadsTV].name]['MonthlyScheduleMultipliers']
          plug_load.monthly_multipliers_isdefaulted = true
        end
      when HPXML::PlugLoadTypeElectricVehicleCharging
        default_annual_kwh = get_electric_vehicle_charging_annual_energy
        if plug_load.kwh_per_year.nil?
          plug_load.kwh_per_year = default_annual_kwh
          plug_load.kwh_per_year_isdefaulted = true
        end
        if plug_load.frac_sensible.nil?
          plug_load.frac_sensible = 0.0
          plug_load.frac_sensible_isdefaulted = true
        end
        if plug_load.frac_latent.nil?
          plug_load.frac_latent = 0.0
          plug_load.frac_latent_isdefaulted = true
        end
        schedules_file_includes_plug_loads_vehicle = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:PlugLoadsVehicle].name))
        if plug_load.weekday_fractions.nil? && !schedules_file_includes_plug_loads_vehicle
          plug_load.weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:PlugLoadsVehicle].name]['WeekdayScheduleFractions']
          plug_load.weekday_fractions_isdefaulted = true
        end
        if plug_load.weekend_fractions.nil? && !schedules_file_includes_plug_loads_vehicle
          plug_load.weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:PlugLoadsVehicle].name]['WeekendScheduleFractions']
          plug_load.weekend_fractions_isdefaulted = true
        end
        if plug_load.monthly_multipliers.nil? && !schedules_file_includes_plug_loads_vehicle
          plug_load.monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:PlugLoadsVehicle].name]['MonthlyScheduleMultipliers']
          plug_load.monthly_multipliers_isdefaulted = true
        end
      when HPXML::PlugLoadTypeWellPump
        default_annual_kwh = get_default_well_pump_annual_energy(cfa, nbeds, n_occ, unit_type)
        if plug_load.kwh_per_year.nil?
          plug_load.kwh_per_year = default_annual_kwh
          plug_load.kwh_per_year_isdefaulted = true
        end
        if plug_load.frac_sensible.nil?
          plug_load.frac_sensible = 0.0
          plug_load.frac_sensible_isdefaulted = true
        end
        if plug_load.frac_latent.nil?
          plug_load.frac_latent = 0.0
          plug_load.frac_latent_isdefaulted = true
        end
        schedules_file_includes_plug_loads_well_pump = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:PlugLoadsWellPump].name))
        if plug_load.weekday_fractions.nil? && !schedules_file_includes_plug_loads_well_pump
          plug_load.weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:PlugLoadsWellPump].name]['WeekdayScheduleFractions']
          plug_load.weekday_fractions_isdefaulted = true
        end
        if plug_load.weekend_fractions.nil? && !schedules_file_includes_plug_loads_well_pump
          plug_load.weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:PlugLoadsWellPump].name]['WeekendScheduleFractions']
          plug_load.weekend_fractions_isdefaulted = true
        end
        if plug_load.monthly_multipliers.nil? && !schedules_file_includes_plug_loads_well_pump
          plug_load.monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:PlugLoadsWellPump].name]['MonthlyScheduleMultipliers']
          plug_load.monthly_multipliers_isdefaulted = true
        end
      end
      if plug_load.usage_multiplier.nil?
        plug_load.usage_multiplier = 1.0
        plug_load.usage_multiplier_isdefaulted = true
      end
    end
  end

  # Assigns default values for omitted optional inputs in the HPXML::FuelLoad objects
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def self.apply_fuel_loads(hpxml_bldg, schedules_file)
    cfa = hpxml_bldg.building_construction.conditioned_floor_area
    nbeds = hpxml_bldg.building_construction.number_of_bedrooms
    n_occ = hpxml_bldg.building_occupancy.number_of_residents
    unit_type = hpxml_bldg.building_construction.residential_facility_type
    hpxml_bldg.fuel_loads.each do |fuel_load|
      case fuel_load.fuel_load_type
      when HPXML::FuelLoadTypeGrill
        if fuel_load.therm_per_year.nil?
          fuel_load.therm_per_year = get_gas_grill_annual_energy(cfa, nbeds, n_occ, unit_type)
          fuel_load.therm_per_year_isdefaulted = true
        end
        if fuel_load.frac_sensible.nil?
          fuel_load.frac_sensible = 0.0
          fuel_load.frac_sensible_isdefaulted = true
        end
        if fuel_load.frac_latent.nil?
          fuel_load.frac_latent = 0.0
          fuel_load.frac_latent_isdefaulted = true
        end
        schedules_file_includes_fuel_loads_grill = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:FuelLoadsGrill].name))
        if fuel_load.weekday_fractions.nil? && !schedules_file_includes_fuel_loads_grill
          fuel_load.weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:FuelLoadsGrill].name]['WeekdayScheduleFractions']
          fuel_load.weekday_fractions_isdefaulted = true
        end
        if fuel_load.weekend_fractions.nil? && !schedules_file_includes_fuel_loads_grill
          fuel_load.weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:FuelLoadsGrill].name]['WeekendScheduleFractions']
          fuel_load.weekend_fractions_isdefaulted = true
        end
        if fuel_load.monthly_multipliers.nil? && !schedules_file_includes_fuel_loads_grill
          fuel_load.monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:FuelLoadsGrill].name]['MonthlyScheduleMultipliers']
          fuel_load.monthly_multipliers_isdefaulted = true
        end
      when HPXML::FuelLoadTypeLighting
        if fuel_load.therm_per_year.nil?
          fuel_load.therm_per_year = get_default_gas_lighting_annual_energy(cfa, nbeds, n_occ, unit_type)
          fuel_load.therm_per_year_isdefaulted = true
        end
        if fuel_load.frac_sensible.nil?
          fuel_load.frac_sensible = 0.0
          fuel_load.frac_sensible_isdefaulted = true
        end
        if fuel_load.frac_latent.nil?
          fuel_load.frac_latent = 0.0
          fuel_load.frac_latent_isdefaulted = true
        end
        schedules_file_includes_fuel_loads_lighting = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:FuelLoadsLighting].name))
        if fuel_load.weekday_fractions.nil? && !schedules_file_includes_fuel_loads_lighting
          fuel_load.weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:FuelLoadsLighting].name]['WeekdayScheduleFractions']
          fuel_load.weekday_fractions_isdefaulted = true
        end
        if fuel_load.weekend_fractions.nil? && !schedules_file_includes_fuel_loads_lighting
          fuel_load.weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:FuelLoadsLighting].name]['WeekendScheduleFractions']
          fuel_load.weekend_fractions_isdefaulted = true
        end
        if fuel_load.monthly_multipliers.nil? && !schedules_file_includes_fuel_loads_lighting
          fuel_load.monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:FuelLoadsLighting].name]['MonthlyScheduleMultipliers']
          fuel_load.monthly_multipliers_isdefaulted = true
        end
      when HPXML::FuelLoadTypeFireplace
        if fuel_load.therm_per_year.nil?
          fuel_load.therm_per_year = get_gas_fireplace_annual_energy(cfa, nbeds, n_occ, unit_type)
          fuel_load.therm_per_year_isdefaulted = true
        end
        if fuel_load.frac_sensible.nil?
          fuel_load.frac_sensible = 0.5
          fuel_load.frac_sensible_isdefaulted = true
        end
        if fuel_load.frac_latent.nil?
          fuel_load.frac_latent = 0.1
          fuel_load.frac_latent_isdefaulted = true
        end
        schedules_file_includes_fuel_loads_fireplace = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:FuelLoadsFireplace].name))
        if fuel_load.weekday_fractions.nil? && !schedules_file_includes_fuel_loads_fireplace
          fuel_load.weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:FuelLoadsFireplace].name]['WeekdayScheduleFractions']
          fuel_load.weekday_fractions_isdefaulted = true
        end
        if fuel_load.weekend_fractions.nil? && !schedules_file_includes_fuel_loads_fireplace
          fuel_load.weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:FuelLoadsFireplace].name]['WeekendScheduleFractions']
          fuel_load.weekend_fractions_isdefaulted = true
        end
        if fuel_load.monthly_multipliers.nil? && !schedules_file_includes_fuel_loads_fireplace
          fuel_load.monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:FuelLoadsFireplace].name]['MonthlyScheduleMultipliers']
          fuel_load.monthly_multipliers_isdefaulted = true
        end
      end
      if fuel_load.usage_multiplier.nil?
        fuel_load.usage_multiplier = 1.0
        fuel_load.usage_multiplier_isdefaulted = true
      end
    end
  end

  # Assigns default capacities/airflows for autosized HPXML HVAC equipment.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param hpxml_header [HPXML::Header] HPXML Header object
  # @return [Array<Hash, Hash>] Maps of HPXML::Zones => DesignLoadValues object, HPXML::Spaces => DesignLoadValues object
  def self.apply_hvac_sizing(runner, hpxml_bldg, weather, hpxml_header)
    hvac_systems = HVAC.get_hpxml_hvac_systems(hpxml_bldg)
    _, all_zone_loads, all_space_loads = HVACSizing.calculate(runner, weather, hpxml_bldg, hvac_systems, hpxml_header)
    return all_zone_loads, all_space_loads
  end

  # Removes any zones/spaces that were automatically created in the add_zones_spaces_if_needed method.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.cleanup_zones_spaces(hpxml_bldg)
    auto_space = hpxml_bldg.conditioned_spaces.find { |space| space.id.start_with? Constants::AutomaticallyAdded }
    auto_space.delete if not auto_space.nil?
    auto_zone = hpxml_bldg.conditioned_zones.find { |zone| zone.id.start_with? Constants::AutomaticallyAdded }
    auto_zone.delete if not auto_zone.nil?
  end

  # Gets the HPXML azimuth corresponding to an HPXML orientation.
  #
  # @param orientation [String] HPXML orientation enumeration
  # @return [Integer] Azimuth (degrees)
  def self.get_azimuth_from_orientation(orientation)
    return if orientation.nil?

    case orientation
    when HPXML::OrientationNorth
      return 0
    when HPXML::OrientationNortheast
      return 45
    when HPXML::OrientationEast
      return 90
    when HPXML::OrientationSoutheast
      return 135
    when HPXML::OrientationSouth
      return 180
    when HPXML::OrientationSouthwest
      return 225
    when HPXML::OrientationWest
      return 270
    when HPXML::OrientationNorthwest
      return 315
    end

    fail "Unexpected orientation: #{orientation}."
  end

  # Gets the closest HPXML orientation corresponding to an HPXML azimuth.
  #
  # @param azimuth [Integer] (degrees)
  # @return [String] HPXML orientation enumeration
  def self.get_orientation_from_azimuth(azimuth)
    return if azimuth.nil?

    if (azimuth >= 0.0 - 22.5 + 360.0) || (azimuth < 0.0 + 22.5)
      return HPXML::OrientationNorth
    elsif (azimuth >= 45.0 - 22.5) && (azimuth < 45.0 + 22.5)
      return HPXML::OrientationNortheast
    elsif (azimuth >= 90.0 - 22.5) && (azimuth < 90.0 + 22.5)
      return HPXML::OrientationEast
    elsif (azimuth >= 135.0 - 22.5) && (azimuth < 135.0 + 22.5)
      return HPXML::OrientationSoutheast
    elsif (azimuth >= 180.0 - 22.5) && (azimuth < 180.0 + 22.5)
      return HPXML::OrientationSouth
    elsif (azimuth >= 225.0 - 22.5) && (azimuth < 225.0 + 22.5)
      return HPXML::OrientationSouthwest
    elsif (azimuth >= 270.0 - 22.5) && (azimuth < 270.0 + 22.5)
      return HPXML::OrientationWest
    elsif (azimuth >= 315.0 - 22.5) && (azimuth < 315.0 + 22.5)
      return HPXML::OrientationNorthwest
    end
  end

  # Gets the equivalent number of bedrooms for an operational calculation (i.e., when number
  # of occupants are provided in the HPXML); this is an adjustment to the ANSI/RESNET/ICC 301 or Building
  # America equations, which are based on number of bedrooms. If an asset calculation (number
  # of occupants provided), the number of bedrooms is simply returned.
  #
  # This is used to adjust occupancy-driven end uses from asset calculations (based on number
  # of bedrooms) to operational calculations (based on number of occupants).
  #
  # Source: 2020 RECS weighted regressions between NBEDS and NHSHLDMEM (sample weights = NWEIGHT)
  #
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @param n_occ [Double] Number of occupants in the dwelling unit
  # @param unit_type [String] Type of dwelling unit (HXPML::ResidentialTypeXXX)
  # @return [Double] Equivalent number of bedrooms
  def self.get_equivalent_nbeds(nbeds, n_occ, unit_type)
    if n_occ.nil?
      # No occupants specified, asset rating
      return nbeds
    end

    case unit_type
    when HPXML::ResidentialTypeApartment
      return -1.36 + 1.49 * n_occ
    when HPXML::ResidentialTypeSFA
      return -1.98 + 1.89 * n_occ
    when HPXML::ResidentialTypeSFD
      return -2.19 + 2.08 * n_occ
    when HPXML::ResidentialTypeManufactured
      return -1.26 + 1.61 * n_occ
    else
      fail "Unexpected residential facility type: #{unit_type}."
    end
  end

  # Gets the default assumption for whether there's a flue/chimney in conditioned space.
  # Determined by whether we find any systems indicating this is likely the case.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [Boolean] Default value for presence of flue/chimney in conditioned space
  def self.get_flue_or_chimney_in_conditioned_space(hpxml_bldg)
    # Check for atmospheric heating system in conditioned space
    hpxml_bldg.heating_systems.each do |heating_system|
      next if heating_system.heating_system_fuel == HPXML::FuelTypeElectricity
      next unless HPXML::conditioned_locations_this_unit.include? heating_system.location

      case heating_system.heating_system_type
      when HPXML::HVACTypeFurnace, HPXML::HVACTypeBoiler, HPXML::HVACTypeWallFurnace,
          HPXML::HVACTypeFloorFurnace, HPXML::HVACTypeStove, HPXML::HVACTypeSpaceHeater
        if not heating_system.heating_efficiency_afue.nil?
          next if heating_system.heating_efficiency_afue >= 0.89
        elsif not heating_system.heating_efficiency_percent.nil?
          next if heating_system.heating_efficiency_percent >= 0.89
        end
        return true
      when HPXML::HVACTypeFireplace
        return true
      end
    end

    # Check for atmospheric water heater in conditioned space
    hpxml_bldg.water_heating_systems.each do |water_heating_system|
      next if water_heating_system.fuel_type == HPXML::FuelTypeElectricity
      next if [HPXML::WaterHeaterTypeCombiStorage,
               HPXML::WaterHeaterTypeCombiTankless].include? water_heating_system.water_heater_type # Boiler checked above
      next unless HPXML::conditioned_locations_this_unit.include? water_heating_system.location

      if not water_heating_system.energy_factor.nil?
        next if water_heating_system.energy_factor >= 0.63
      elsif not water_heating_system.uniform_energy_factor.nil?
        next if Waterheater.calc_ef_from_uef(water_heating_system) >= 0.63
      end

      return true
    end
    return false
  end

  # Gets the default summer/winter interior shading factors for the window.
  # Note: We can't just pass the window object because OS-ERI needs to define individual arguments.
  #
  # @param type [String] Shading type (HPXML::InteriorShadingTypeXXX)
  # @param shgc [Double] Solar heat gain coefficient
  # @param coverage_summer [Double] Fraction of window area covered in summer
  # @param coverage_winter [Double] Fraction of window area covered in winter
  # @param blinds_summer [String] Blinds position in summer (HPXML::BlindsXXX)
  # @param blinds_winter [String] Blinds position in winter (HPXML::BlindsXXX)
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @return [Array<Double, Double>] The interior summer and winter shading factors
  def self.get_window_interior_shading_factors(type, shgc, coverage_summer, coverage_winter, blinds_summer, blinds_winter, eri_version)
    return 1.0, 1.0 if type == HPXML::InteriorShadingTypeNone

    if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2022C')
      # C1/C2 coefficients derived from ASHRAE 2021 Handbook of Fundamentals Chapter 15 Table 14
      # See spreadsheet in https://github.com/NREL/OpenStudio-HPXML/pull/1826 for derivation
      if [HPXML::InteriorShadingTypeDarkBlinds,
          HPXML::InteriorShadingTypeMediumBlinds,
          HPXML::InteriorShadingTypeLightBlinds].include? type
        # Shading type, blinds position => c1/c2
        c_map = {
          [HPXML::InteriorShadingTypeDarkBlinds, HPXML::BlindsClosed] => [0.98, 0.25],
          [HPXML::InteriorShadingTypeMediumBlinds, HPXML::BlindsClosed] => [0.90, 0.41],
          [HPXML::InteriorShadingTypeLightBlinds, HPXML::BlindsClosed] => [0.78, 0.47],
          [HPXML::InteriorShadingTypeDarkBlinds, HPXML::BlindsHalfOpen] => [1.0, 0.19],
          [HPXML::InteriorShadingTypeMediumBlinds, HPXML::BlindsHalfOpen] => [0.95, 0.26],
          [HPXML::InteriorShadingTypeLightBlinds, HPXML::BlindsHalfOpen] => [0.93, 0.38],
          [HPXML::InteriorShadingTypeDarkBlinds, HPXML::BlindsOpen] => [0.99, 0.0],
          [HPXML::InteriorShadingTypeMediumBlinds, HPXML::BlindsOpen] => [0.98, 0.0],
          [HPXML::InteriorShadingTypeLightBlinds, HPXML::BlindsOpen] => [0.98, 0.0],
        }
        c1_summer, c2_summer = c_map[[type, blinds_summer]]
        c1_winter, c2_winter = c_map[[type, blinds_winter]]
      else
        # Shading type => c1/c2
        c_map = {
          HPXML::InteriorShadingTypeDarkCurtains => [0.98, 0.25],
          HPXML::InteriorShadingTypeMediumCurtains => [0.94, 0.37],
          HPXML::InteriorShadingTypeLightCurtains => [0.84, 0.42],
          HPXML::InteriorShadingTypeDarkShades => [0.98, 0.33],
          HPXML::InteriorShadingTypeMediumShades => [0.9, 0.38],
          HPXML::InteriorShadingTypeLightShades => [0.82, 0.42],
          HPXML::InteriorShadingTypeOther => [0.5, 0.0],
        }
        c1_summer, c2_summer = c_map[type]
        c1_winter, c2_winter = c_map[type]
      end

      int_sf_summer = c1_summer - (c2_summer * shgc)
      int_sf_winter = c1_winter - (c2_winter * shgc)

      # Apply fraction of window area covered
      int_sf_summer = apply_shading_coverage(int_sf_summer, coverage_summer)
      int_sf_winter = apply_shading_coverage(int_sf_winter, coverage_winter)
    else
      int_sf_summer = 0.70
      int_sf_winter = 0.85
    end

    return int_sf_summer.round(4), int_sf_winter.round(4)
  end

  # Gets the default summer/winter exterior shading factors for the window.
  #
  # @param window [HPXML::Window] The window of interest
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [Array<Double, Double>] The exterior summer and winter shading factors
  def self.get_window_exterior_shading_factors(window, hpxml_bldg)
    return 1.0, 1.0 if window.exterior_shading_type == HPXML::ExteriorShadingTypeNone

    if [HPXML::ExteriorShadingTypeExternalOverhangs,
        HPXML::ExteriorShadingTypeAwnings].include?(window.exterior_shading_type) && window.overhangs_depth.to_f > 0
      # Explicitly modeling the overhangs, so don't double count the shading effect
      return nil, nil
    elsif [HPXML::ExteriorShadingTypeBuilding].include?(window.exterior_shading_type) && hpxml_bldg.neighbor_buildings.size > 0
      # Explicitly modeling neighboring building, so don't double count the shading effect
      return nil, nil
    end

    c_map = {
      HPXML::ExteriorShadingTypeExternalOverhangs => 0.0, # Assume fully opaque
      HPXML::ExteriorShadingTypeAwnings => 0.0, # Assume fully opaque
      HPXML::ExteriorShadingTypeBuilding => 0.0, # Assume fully opaque
      HPXML::ExteriorShadingTypeDeciduousTree => 0.0, # Assume fully opaque
      HPXML::ExteriorShadingTypeEvergreenTree => 0.0, # Assume fully opaque
      HPXML::ExteriorShadingTypeOther => 0.5, # Assume half opaque
      HPXML::ExteriorShadingTypeSolarFilm => 0.7, # Based on MulTEA engineering manual
      HPXML::ExteriorShadingTypeSolarScreens => 0.3, # Based on MulTEA engineering manual
    }

    ext_sf_summer = c_map[window.exterior_shading_type]
    ext_sf_winter = c_map[window.exterior_shading_type]

    # Apply fraction of window area covered
    ext_sf_summer = apply_shading_coverage(ext_sf_summer, window.exterior_shading_coverage_summer)
    ext_sf_winter = apply_shading_coverage(ext_sf_winter, window.exterior_shading_coverage_winter)

    return ext_sf_summer, ext_sf_winter
  end

  # Gets the default insect screen shading factors for the window.
  #
  # @param window [HPXML::Window] The window of interest
  # @return [Array<Double, Double>] The summer and winter shading factors
  def self.get_window_insect_screen_factors(window)
    # C1/C2 coefficients derived from ASHRAE 2021 Handbook of Fundamentals Chapter 15 Table 14
    # See spreadsheet in https://github.com/NREL/OpenStudio-HPXML/pull/1826 for derivation
    c_map = {
      HPXML::LocationExterior => [0.64, 0.0],
      HPXML::LocationInterior => [0.99, 0.1],
    }
    c1, c2 = c_map[window.insect_screen_location]

    is_sf_summer = c1 - (c2 * window.shgc)
    is_sf_winter = c1 - (c2 * window.shgc)

    # Apply fraction of window area covered
    is_sf_summer = apply_shading_coverage(is_sf_summer, window.insect_screen_coverage_summer)
    is_sf_winter = apply_shading_coverage(is_sf_winter, window.insect_screen_coverage_winter)

    return is_sf_summer.round(4), is_sf_winter.round(4)
  end

  # Incorporates a shading coverage adjustment on the shading factor.
  #
  # @param shading_factor [Double] The shading factor not taking window area coverage into account
  # @param shading_coverage [Double] The fraction of window area covered by the shade
  # @return [Double] The coverage-adjustment shading factor
  def self.apply_shading_coverage(shading_factor, shading_coverage)
    non_shading_factor = 1.0 # 1.0 (i.e., fully transparent) is the shading factor for the unshaded portion of the window
    return shading_coverage * shading_factor + (1 - shading_coverage) * non_shading_factor
  end

  # Gets the default latitude from the HPXML file, or as backup from the
  # zip code, or as backup from the weather file.
  #
  # @param latitude [Double] Latitude from the HPXML file (degrees)
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param zipcode [String] Zipcode of interest
  # @return [Double] Default value for latitude (degrees)
  def self.get_latitude(latitude, weather, zipcode)
    return latitude unless latitude.nil?

    if not zipcode.nil?
      weather_data = lookup_weather_data_from_zipcode(zipcode)
      return Float(weather_data[:zipcode_latitude]) unless weather_data[:zipcode_latitude].nil?
    end

    return weather.header.Latitude
  end

  # Gets the default longitude from the HPXML file, or as backup from the
  # zip code, or as backup from the weather file.
  #
  # @param longitude [Double] Longitude from the HPXML file (degrees)
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param zipcode [String] Zipcode of interest
  # @return [Double] Default value for longitude (degrees)
  def self.get_longitude(longitude, weather, zipcode)
    return longitude unless longitude.nil?

    if not zipcode.nil?
      weather_data = lookup_weather_data_from_zipcode(zipcode)
      return Float(weather_data[:zipcode_longitude]) unless weather_data[:zipcode_longitude].nil?
    end

    return weather.header.Longitude
  end

  # Gets the default elevation from the HPXML file, or as backup from the
  # weather file.
  #
  # @param weather [WeatherFile] Weather object containing EPW information
  # @return [Double] Default value for elevation (ft)
  def self.get_elevation(weather)
    # FUTURE: Add elevation to zipcode_weather_stations.csv and use here first.
    return weather.header.Elevation.round(1)
  end

  # Gets the default time zone from the HPXML file or, as backup, weather file.
  #
  # @param time_zone [Double] Time zone (UTC offset) from the HPXML file
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param zipcode [String] Zipcode of interest
  # @return [Double] Default value for time zone (UTC offset)
  def self.get_time_zone(time_zone, weather, zipcode)
    return time_zone unless time_zone.nil?

    if not zipcode.nil?
      weather_data = lookup_weather_data_from_zipcode(zipcode)
      return Float(weather_data[:zipcode_utc_offset]) unless weather_data[:zipcode_utc_offset].nil?
    end

    return weather.header.TimeZone
  end

  # Gets the default state code from the HPXML file, or as backup from the
  # zip code, or as backup from the weather file.
  #
  # @param state_code [String] State code from the HPXML file
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param zipcode [String] Zipcode of interest
  # @return [String] Uppercase state code
  def self.get_state_code(state_code, weather, zipcode)
    return state_code unless state_code.nil?

    if not zipcode.nil?
      weather_data = lookup_weather_data_from_zipcode(zipcode)
      return weather_data[:zipcode_state] unless weather_data[:zipcode_state].nil?
    end

    return weather.header.StateProvinceRegion.upcase
  end

  # Gets the default city from the HPXML file, or as backup from the
  # zip code, or as backup from the weather file.
  #
  # @param city [String] city from the HPXML file
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param zipcode [String] Zipcode of interest
  # @return [String] City
  def self.get_city(city, weather, zipcode)
    return city unless city.nil?

    if not zipcode.nil?
      weather_data = lookup_weather_data_from_zipcode(zipcode)
      return weather_data[:zipcode_city] unless weather_data[:zipcode_city].nil?
    end

    return weather.header.City
  end

  # Gets the default weekday/weekend schedule fractions and monthly multipliers for each end use.
  #
  # @return [Hash] { schedule_name => { element => values, ... }, ... }
  def self.get_schedules_csv_data()
    default_schedules_csv = File.join(File.dirname(__FILE__), 'data', 'default_schedules.csv')
    if not File.exist?(default_schedules_csv)
      fail 'Could not find default_schedules.csv'
    end

    require 'csv'
    default_schedules_csv_data = {}
    CSV.foreach(default_schedules_csv, headers: true) do |row|
      schedule_name = row['Schedule Name']
      element = row['Element']
      values = row['Values']

      default_schedules_csv_data[schedule_name] = {} if !default_schedules_csv_data.keys.include?(schedule_name)
      default_schedules_csv_data[schedule_name][element] = values
    end

    return default_schedules_csv_data
  end

  # Reads the data (or retrieves the cached data) from zipcode_weather_stations.csv.
  # Uses a global variable so the data is only read once.
  #
  # @return [Array<Array>] Array of arrays of data
  def self.get_weather_station_csv_data
    zipcode_csv_filepath = File.join(File.dirname(__FILE__), 'data', 'zipcode_weather_stations.csv')

    if $weather_lookup_cache[:csv_data].nil?
      # Note: We don't use the CSV library here because it's slow for large files
      $weather_lookup_cache[:csv_data] = File.readlines(zipcode_csv_filepath).map { |r| r.strip.split(',') }
    end

    return $weather_lookup_cache[:csv_data]
  end

  # Gets the default TMY3 EPW weather station for the specified zipcode. If the exact
  # zipcode is not found, we find the closest zipcode that shares the first 3 digits.
  #
  # @param zipcode [String] Zipcode of interest
  # @return [Hash] Mapping with keys for every column name in zipcode_weather_stations.csv
  def self.lookup_weather_data_from_zipcode(zipcode)
    if not $weather_lookup_cache["zipcode_#{zipcode}"].nil?
      # Use cache
      return $weather_lookup_cache["zipcode_#{zipcode}"]
    end

    begin
      zipcode3 = zipcode[0, 3]
      zipcode_int = Integer(Float(zipcode[0, 5])) # Convert to 5-digit integer
    rescue
      fail "Unexpected zip code: #{zipcode}."
    end

    zip_csv_data = get_weather_station_csv_data()

    weather_station = {}
    zip_distance = 99999 # init
    col_names = nil
    zip_csv_data.each_with_index do |row, i|
      if i == 0 # header
        col_names = row.map { |x| x.to_sym }
        next
      end
      next if row.nil? || row.empty?
      next unless row[0].start_with?(zipcode3) # Only allow match if first 3 digits are the same

      if row[0].size != 5
        fail "Zip code '#{row[0]}' in zipcode_weather_stations.csv does not have 5 digits."
      end

      distance = (Integer(Float(row[0])) - zipcode_int).abs() # Find closest zip code
      if distance < zip_distance
        zip_distance = distance
        weather_station = {}
        col_names.each_with_index do |col_name, j|
          weather_station[col_name] = row[j]
        end
      end
      next unless distance == 0

      $weather_lookup_cache["zipcode_#{zipcode}"] = weather_station
      return weather_station # Exact match
    end

    if weather_station.empty?
      fail "Zip code '#{zipcode}' could not be found in zipcode_weather_stations.csv"
    end

    $weather_lookup_cache["zipcode_#{zipcode}"] = weather_station
    return weather_station
  end

  # Gets the default TMY3 EPW weather station for the specified WMO.
  #
  # @param wmo [String] Weather station World Meteorological Organization (WMO) number
  # @return [Hash or nil] Mapping with keys for every column name in zipcode_weather_stations.csv if WMO is found, otherwise nil
  def self.lookup_weather_data_from_wmo(wmo)
    if not $weather_lookup_cache["wmo_#{wmo}"].nil?
      # Use cache
      return $weather_lookup_cache["wmo_#{wmo}"]
    end

    zip_csv_data = get_weather_station_csv_data()

    weather_station = {}
    col_names = nil
    wmo_idx = nil
    zip_csv_data.each_with_index do |row, i|
      if i == 0 # header
        col_names = row.map { |x| x.to_sym }
        wmo_idx = col_names.index(:station_wmo)
        next
      end
      next if row.nil? || row.empty?

      next unless row[wmo_idx] == wmo

      col_names.each_with_index do |col_name, j|
        weather_station[col_name] = row[j]
      end
      break
    end

    $weather_lookup_cache["wmo_#{wmo}"] = weather_station
    return weather_station
  end

  # Gets the default number of bathrooms in the dwelling unit.
  #
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @return [Double] Number of bathrooms
  def self.get_num_bathrooms(nbeds)
    nbaths = nbeds / 2.0 + 0.5 # From BA HSP
    return nbaths
  end

  # Gets the default properties for cooking ranges/ovens.
  #
  # @return [Hash] Map of property type => value
  def self.get_range_oven_values()
    return { is_induction: false,
             is_convection: false }
  end

  # Gets the default properties for dishwashers.
  #
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @return [Hash] Map of property type => value
  def self.get_dishwasher_values(eri_version)
    if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2019A')
      return { rated_annual_kwh: 467.0, # kWh/yr
               label_electric_rate: 0.12, # $/kWh
               label_gas_rate: 1.09, # $/therm
               label_annual_gas_cost: 33.12, # $
               label_usage: 4.0, # cyc/week
               place_setting_capacity: 12.0 }
    else
      return { rated_annual_kwh: 467.0, # kWh/yr
               label_electric_rate: 999, # unused
               label_gas_rate: 999, # unused
               label_annual_gas_cost: 999, # unused
               label_usage: 999, # unused
               place_setting_capacity: 12.0 }
    end
  end

  # Gets the default properties for refrigerators.
  #
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @return [Hash] Map of property type => value
  def self.get_refrigerator_values(nbeds)
    return { rated_annual_kwh: 637.0 + 18.0 * nbeds } # kWh/yr
  end

  # Gets the default properties for extra refrigerators.
  #
  # @return [Hash] Map of property type => value
  def self.get_extra_refrigerator_values()
    return { rated_annual_kwh: 243.6 } # kWh/yr
  end

  # Gets the default properties for freezers.
  #
  # @return [Hash] Map of property type => value
  def self.get_freezer_values()
    return { rated_annual_kwh: 319.8 } # kWh/yr
  end

  # Gets the default properties for clothes dryers.
  #
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @param fuel_type [String] HPXML fuel type (HPXML::FuelTypeXXX)
  # @return [Hash] Map of property type => value
  def self.get_clothes_dryer_values(eri_version, fuel_type)
    if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2019A')
      return { combined_energy_factor: 3.01 }
    else
      if fuel_type == HPXML::FuelTypeElectricity
        return { combined_energy_factor: 2.62,
                 control_type: HPXML::ClothesDryerControlTypeTimer }
      else
        return { combined_energy_factor: 2.32,
                 control_type: HPXML::ClothesDryerControlTypeTimer }
      end
    end
  end

  # Gets the default properties for clothes washers.
  #
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @return [Hash] Map of property type => value
  def self.get_clothes_washer_values(eri_version)
    if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2019A')
      return { integrated_modified_energy_factor: 1.0, # ft3/(kWh/cyc)
               rated_annual_kwh: 400.0, # kWh/yr
               label_electric_rate: 0.12, # $/kWh
               label_gas_rate: 1.09, # $/therm
               label_annual_gas_cost: 27.0, # $
               capacity: 3.0, # ft^3
               label_usage: 6.0 } # cyc/week
    else
      return { integrated_modified_energy_factor: 0.331, # ft3/(kWh/cyc)
               rated_annual_kwh: 704.0, # kWh/yr
               label_electric_rate: 0.08, # $/kWh
               label_gas_rate: 0.58, # $/therm
               label_annual_gas_cost: 23.0, # $
               capacity: 2.874, # ft^3
               label_usage: 999 } # unused
    end
  end

  # Gets the default piping length for a standard hot water distribution system.
  #
  # The length of hot water piping from the hot water heater to the farthest
  # hot water fixture, measured longitudinally from plans, assuming the hot water piping does
  # not run diagonally, plus 10 feet of piping for each floor level, plus 5 feet of piping for
  # unconditioned basements (if any).
  #
  # Source: ANSI/RESNET/ICC 301-2022
  #
  # @param has_uncond_bsmnt [Boolean] Whether the dwelling unit has an unconditioned basement
  # @param has_cond_bsmnt [Boolean] Whether the dwelling unit has a conditioned basement
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param ncfl [Double] Total number of conditioned floors in the dwelling unit
  # @return [Double] Piping length (ft)
  def self.get_std_pipe_length(has_uncond_bsmnt, has_cond_bsmnt, cfa, ncfl)
    bsmnt = 0
    if has_uncond_bsmnt && (not has_cond_bsmnt)
      bsmnt = 1
    end

    return (2.0 * (cfa / ncfl)**0.5 + 10.0 * ncfl + 5.0 * bsmnt).round(2) # PipeL in ANSI/RESNET/ICC 301
  end

  # Gets the default loop piping length for a recirculation hot water distribution system.
  #
  # The recirculation loop length including both supply and return sides,
  # measured longitudinally from plans, assuming the hot water piping does not run diagonally,
  # plus 20 feet of piping for each floor level greater than one plus 10 feet of piping for
  # unconditioned basements.
  #
  # Source: ANSI/RESNET/ICC 301-2022
  #
  # @param has_uncond_bsmnt [Boolean] Whether the dwelling unit has an unconditioned basement
  # @param has_cond_bsmnt [Boolean] Whether the dwelling unit has a conditioned basement
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param ncfl [Double] Total number of conditioned floors in the dwelling unit
  # @return [Double] Piping length (ft)
  def self.get_recirc_loop_length(has_uncond_bsmnt, has_cond_bsmnt, cfa, ncfl)
    std_pipe_length = get_std_pipe_length(has_uncond_bsmnt, has_cond_bsmnt, cfa, ncfl)
    return (2.0 * std_pipe_length - 20.0).round(2) # refLoopL in ANSI/RESNET/ICC 301
  end

  # Gets the default branch piping length for a recirculation hot water distribution system.
  #
  # The length of the branch hot water piping from the recirculation loop
  # to the farthest hot water fixture from the recirculation loop, measured longitudinally
  # from plans, assuming the branch hot water piping does not run diagonally.
  #
  # Source: ANSI/RESNET/ICC 301-2022
  #
  # @return [Double] Piping length (ft)
  def self.get_recirc_branch_length()
    return 10.0 # See pRatio in ANSI/RESNET/ICC 301
  end

  # Gets the default pump power for a recirculation system.
  #
  # @return [Double] Pump power (W)
  def self.get_recirc_pump_power()
    return 50.0 # See pumpW in ANSI/RESNET/ICC 301
  end

  # Gets the default pump power for a shared recirculation system.
  #
  # @return [Double] Pump power (W)
  def self.get_shared_recirc_pump_power()
    # From ANSI/RESNET/ICC 301-2022 Eq. 4.2-43b
    pump_horsepower = 0.25
    motor_efficiency = 0.85
    pump_kw = pump_horsepower * 0.746 / motor_efficiency
    return UnitConversions.convert(pump_kw, 'kW', 'W')
  end

  # Gets the default location for a freezer or extra refrigerator.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [String] Appliance location (HPXML::LocationXXX)
  def self.get_freezer_or_extra_fridge_location(hpxml_bldg)
    extra_refrigerator_location_hierarchy = [HPXML::LocationGarage,
                                             HPXML::LocationBasementUnconditioned,
                                             HPXML::LocationBasementConditioned,
                                             HPXML::LocationConditionedSpace]

    extra_refrigerator_location = nil
    extra_refrigerator_location_hierarchy.each do |location|
      if hpxml_bldg.has_location(location)
        extra_refrigerator_location = location
        break
      end
    end

    return extra_refrigerator_location
  end

  # Gets the default fraction of window area that is associated with operable windows.
  #
  # If a HPXML Window represents a single window, the value should be 0 or 1. If a HPXML
  # Window represents multiple windows, the value is calculated as the total window area
  # for any operable windows divided by the total window area.
  #
  # Source: ANSI/RESNET/ICC 301-2025
  #
  # @return [Double] Operable fraction (frac)
  def self.get_fraction_of_windows_operable()
    return 0.67 # 67%
  end

  # Gets the default specific leakage area (SLA) for a vented attic.
  # SLA is the effective leakage area (ELA) divided by the floor area.
  #
  # @return [Double] Specific leakage area (frac)
  def self.get_vented_attic_sla()
    return (1.0 / 300.0).round(6) # ANSI/RESNET/ICC 301, Table 4.2.2(1) - Attics
  end

  # Gets the default specific leakage area (SLA) for a vented crawlspace.
  # SLA is the effective leakage area (ELA) divided by the floor area.
  #
  # @return [Double] Specific leakage area (frac)
  def self.get_vented_crawl_sla()
    return (1.0 / 150.0).round(6) # ANSI/RESNET/ICC 301, Table 4.2.2(1) - Crawlspaces
  end

  # Gets the default whole-home mechanical ventilation fan flow rate required to
  # meet ASHRAE 62.2 for the given HPXML VentilationFan.
  #
  # The required fan flow rate, combined with an infiltration credit, will equal
  # the ASHRAE 62.2 total air exchange rate requirement.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param vent_fan [HPXML::VentilationFan] The HPXML ventilation fan of interest
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @return [Double] Fan flow rate (cfm)
  def self.get_mech_vent_flow_rate_for_vent_fan(hpxml_bldg, vent_fan, weather, eri_version)
    # Calculates Qfan cfm requirement per ASHRAE 62.2 / ANSI/RESNET/ICC 301
    cfa = hpxml_bldg.building_construction.conditioned_floor_area
    nbeds = hpxml_bldg.building_construction.number_of_bedrooms
    infil_values = Airflow.get_values_from_air_infiltration_measurements(hpxml_bldg, weather)
    unit_type = hpxml_bldg.building_construction.residential_facility_type

    nl = Airflow.get_infiltration_NL_from_SLA(infil_values[:sla], infil_values[:height])
    q_inf = Airflow.get_mech_vent_qinf_cfm(nl, weather, cfa)
    q_tot = Airflow.get_mech_vent_qtot_cfm(nbeds, cfa)
    if vent_fan.is_balanced
      is_balanced, frac_imbal = true, 0.0
    else
      is_balanced, frac_imbal = false, 1.0
    end
    q_fan = Airflow.get_mech_vent_qfan_cfm(q_tot, q_inf, is_balanced, frac_imbal, infil_values[:a_ext], unit_type, eri_version, vent_fan.hours_in_operation)
    return q_fan
  end

  # Gets the default whole-home mechanical ventilation fan efficiency.
  #
  # Source: ANSI/RESNET/ICC 301
  #
  # @param vent_fan [HPXML::VentilationFan] The HPXML ventilation fan of interest
  # @return [Double] Fan efficiency (W/cfm)
  def self.get_mech_vent_fan_efficiency(vent_fan)
    if vent_fan.is_shared_system
      return 1.00 # Table 4.2.2(1) Note (n)
    end

    case vent_fan.fan_type
    when HPXML::MechVentTypeSupply, HPXML::MechVentTypeExhaust
      return 0.35
    when HPXML::MechVentTypeBalanced
      return 0.70
    when HPXML::MechVentTypeERV, HPXML::MechVentTypeHRV
      return 1.00
    else
      fail "Unexpected fan_type: '#{vent_fan.fan_type}'."
    end
  end

  # Gets the default infiltration height/volume. Infiltration height is the vertical distance between lowest
  # and highest above-grade points within the pressure boundary. Infiltration volume is the above-grade conditioned
  # volume plus the volume of any spaces within the infiltration volume.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [Double, Double] Default infiltration height (ft) and volume (ft3)
  def self.get_infiltration_height_and_volume(hpxml_bldg)
    # Make sure AverageCeilingHeight & WithinInfiltrationVolume properties have been set
    apply_building_construction(nil, hpxml_bldg)
    apply_attics(hpxml_bldg)
    apply_foundations(hpxml_bldg)

    # Get base infiltration height, excluding foundations and attics
    avg_ceiling_height = hpxml_bldg.building_construction.average_ceiling_height
    ncfl = hpxml_bldg.building_construction.number_of_conditioned_floors
    ncfl_ag = hpxml_bldg.building_construction.number_of_conditioned_floors_above_grade
    cond_volume = hpxml_bldg.building_construction.conditioned_building_volume
    base_infil_height = avg_ceiling_height * ncfl_ag
    if ncfl_ag > 1
      # Add assumed rim joists between stories
      base_infil_height += (ncfl_ag - 1) * UnitConversions.convert(6, 'in', 'ft') # 2x6 (5.5") rim joist + 0.5" subfloor
    end

    # Get base infiltration volume, excluding foundations and attics
    base_infil_volume = cond_volume
    hpxml_bldg.foundations.each do |foundation|
      next unless HPXML::conditioned_below_grade_locations.include? foundation.to_location

      base_infil_volume -= Geometry.calculate_zone_volume(hpxml_bldg, foundation.to_location)
    end

    # For attics within infiltration volume:
    # 1. Determine max attic height
    # 2. Determine total attic volume
    attic_height = 0.0
    attic_volume = 0.0
    hpxml_bldg.attics.each do |attic|
      next unless attic.within_infiltration_volume

      this_height = Geometry.calculate_zone_height(hpxml_bldg, attic.to_location)
      attic_height = [attic_height, this_height].max

      attic_volume += Geometry.calculate_zone_volume(hpxml_bldg, attic.to_location)
    end

    # For foundations within infiltration volume:
    # 1. Determine max *above-grade* foundation height
    # 2. Determine total foundation volume
    foundation_height = 0.0
    foundation_volume = 0.0
    hpxml_bldg.foundations.each do |foundation|
      next unless foundation.within_infiltration_volume

      this_height = Geometry.calculate_zone_height(hpxml_bldg, foundation.to_location, above_grade: true)

      # Add assumed rim joist height
      this_height += UnitConversions.convert(9, 'in', 'ft') # 2x8 (7.5") rim joist + 1.5" sill plate per ASHRAE 140

      foundation_height = [foundation_height, this_height].max
      foundation_volume += Geometry.calculate_zone_volume(hpxml_bldg, foundation.to_location)
    end
    if hpxml_bldg.has_location(HPXML::LocationBasementConditioned) && (ncfl == ncfl_ag)
      # Walkout basement, basement height already included in the base infiltration height
      foundation_height = 0.0
    end

    infil_height = base_infil_height + attic_height + foundation_height
    infil_volume = base_infil_volume + attic_volume + foundation_volume

    return infil_height, infil_volume
  end

  # Gets the total and exterior compartmentalization boundary area. Used to convert between total infiltration
  # and exterior infiltration for SFA/MF dwelling units.
  #
  # Source: ANSI/RESNET/ICC 301
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [Array<Double, Double>] Total and exterior compartmentalization areas (ft2)
  def self.get_compartmentalization_boundary_areas(hpxml_bldg)
    # Make sure WithinInfiltrationVolume properties have been set
    apply_attics(hpxml_bldg)
    apply_foundations(hpxml_bldg)

    total_area = 0.0 # Total surface area that bounds the Infiltration Volume
    exterior_area = 0.0 # Same as above excluding surfaces attached to garage, other housing units, or other multifamily spaces

    # Determine which locations are within infiltration volume
    locations_within_infil_volume = [HPXML::LocationConditionedSpace]
    hpxml_bldg.attics.each do |attic|
      next unless attic.within_infiltration_volume

      locations_within_infil_volume << attic.to_location
    end
    hpxml_bldg.foundations.each do |foundation|
      next unless foundation.within_infiltration_volume

      locations_within_infil_volume << foundation.to_location
    end

    # Get surfaces bounding infiltration volume
    locations_within_infil_volume.each do |location|
      (hpxml_bldg.roofs + hpxml_bldg.rim_joists + hpxml_bldg.walls + hpxml_bldg.foundation_walls + hpxml_bldg.floors + hpxml_bldg.slabs).each do |surface|
        is_adiabatic_surface = (surface.interior_adjacent_to == surface.exterior_adjacent_to)
        next unless [surface.interior_adjacent_to,
                     surface.exterior_adjacent_to].include? location

        if not is_adiabatic_surface
          # Exclude surfaces between two different locations that are both within infiltration volume
          next if locations_within_infil_volume.include?(surface.interior_adjacent_to) && locations_within_infil_volume.include?(surface.exterior_adjacent_to)
        end

        # Update Compartmentalization Boundary areas
        total_area += surface.area
        next unless (not [HPXML::LocationGarage,
                          HPXML::LocationOtherHousingUnit,
                          HPXML::LocationOtherHeatedSpace,
                          HPXML::LocationOtherMultifamilyBufferSpace,
                          HPXML::LocationOtherNonFreezingSpace].include? surface.exterior_adjacent_to) &&
                    (not is_adiabatic_surface)

        exterior_area += surface.area
      end
    end

    return total_area, exterior_area
  end

  # Gets the default infiltration ACH50 based on the provided leakiness description.
  #
  # Uses a regression developed by LBNL using ResDB data (https://resdb.lbl.gov) that takes into
  # account IECC zone, # cfa, year built, foundation type, duct location, etc. The leakiness
  # description is then used to further adjust the default (average) infiltration rate.
  #
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param ncfl_ag [Double] Number of conditioned floors above grade
  # @param year_built [Integer] Year the dwelling unit is built
  # @param avg_ceiling_height [Double] Average floor to ceiling height within conditioned space (ft)
  # @param infil_volume [Double] Volume of space most impacted by the blower door test (ft3)
  # @param iecc_cz [String] IECC climate zone
  # @param fnd_type_fracs [Hash] Map of foundation type => area fraction
  # @param duct_loc_fracs [Hash] Map of duct location => area fraction
  # @param leakiness_description [String] Leakiness description to qualitatively describe the dwelling unit infiltration
  # @param air_sealed [Boolean] True if the dwelling unit was professionally air sealed (intended to be used by Home Energy Score)
  # @return [Double] Calculated ACH50 value
  def self.get_infiltration_ach50(cfa, ncfl_ag, year_built, avg_ceiling_height, infil_volume, iecc_cz,
                                  fnd_type_fracs, duct_loc_fracs, leakiness_description = nil, is_sealed = false)
    # Constants
    c_floor_area = -0.002078
    c_height = 0.06375
    # Multiplier summarized from Manual J 5A & 5B tables, average of all (values at certain leakiness description / average leakiness)
    leakage_multiplier_map = { HPXML::LeakinessVeryTight => 0.355,
                               HPXML::LeakinessTight => 0.686,
                               HPXML::LeakinessAverage => 1.0,
                               HPXML::LeakinessLeaky => 1.549,
                               HPXML::LeakinessVeryLeaky => 2.085 }
    leakage_multiplier = leakiness_description.nil? ? 1.0 : leakage_multiplier_map[leakiness_description]
    c_sealed = is_sealed ? -0.288 : 0.0

    # Vintage
    c_vintage = nil
    if year_built < 1960
      c_vintage = -0.2498
    elsif year_built <= 1969
      c_vintage = -0.4327
    elsif year_built <= 1979
      c_vintage = -0.4521
    elsif year_built <= 1989
      c_vintage = -0.6536
    elsif year_built <= 1999
      c_vintage = -0.9152
    elsif year_built >= 2000
      c_vintage = -1.058
    else
      fail "Unexpected vintage: #{year_built}"
    end

    # Climate zone
    c_iecc = nil
    case iecc_cz
    when '1A', '2A'
      c_iecc = 0.4727
    when '3A'
      c_iecc = 0.2529
    when '4A'
      c_iecc = 0.3261
    when '5A'
      c_iecc = 0.1118
    when '6A', '7'
      c_iecc = 0.0
    when '2B', '3B'
      c_iecc = -0.03755
    when '4B', '5B'
      c_iecc = -0.008774
    when '6B'
      c_iecc = 0.01944
    when '3C'
      c_iecc = 0.04827
    when '4C'
      c_iecc = 0.2584
    when '8'
      c_iecc = -0.5119
    else
      fail "Unexpected IECC climate zone: #{c_iecc}"
    end

    # Foundation type (weight by area)
    c_foundation = 0.0
    fnd_type_fracs.each do |foundation_type, area_fraction|
      case foundation_type
      when HPXML::FoundationTypeSlab, HPXML::FoundationTypeAboveApartment
        c_foundation -= 0.036992 * area_fraction
      when HPXML::FoundationTypeBasementConditioned, HPXML::FoundationTypeCrawlspaceUnvented, HPXML::FoundationTypeCrawlspaceConditioned
        c_foundation += 0.108713 * area_fraction
      when HPXML::FoundationTypeBasementUnconditioned, HPXML::FoundationTypeCrawlspaceVented, HPXML::FoundationTypeBellyAndWing, HPXML::FoundationTypeAmbient
        c_foundation += 0.180352 * area_fraction
      else
        fail "Unexpected foundation type: #{foundation_type}"
      end
    end

    c_duct = 0.0
    duct_loc_fracs.each do |duct_location, area_fraction|
      if (HPXML::conditioned_locations + HPXML::multifamily_common_space_locations + [HPXML::LocationUnderSlab, HPXML::LocationExteriorWall, HPXML::LocationOutside, HPXML::LocationRoofDeck, HPXML::LocationManufacturedHomeBelly]).include? duct_location
        c_duct -= 0.12381 * area_fraction
      elsif [HPXML::LocationAtticUnvented, HPXML::LocationBasementUnconditioned, HPXML::LocationGarage, HPXML::LocationCrawlspaceUnvented].include? duct_location
        c_duct += 0.07126 * area_fraction
      elsif HPXML::vented_locations.include? duct_location
        c_duct += 0.18072 * area_fraction
      else
        fail "Unexpected duct location: #{duct_location}"
      end
    end

    floor_area_m2 = UnitConversions.convert(cfa, 'ft^2', 'm^2')
    height_m = UnitConversions.convert(ncfl_ag * avg_ceiling_height, 'ft', 'm') + 0.5

    # Normalized leakage
    nl = Math.exp(floor_area_m2 * c_floor_area + height_m * c_height +
                  c_sealed + c_vintage + c_iecc + c_foundation + c_duct) * leakage_multiplier

    # Specific Leakage Area
    sla = nl / (1000.0 * ncfl_ag**0.3)

    # ACH50
    infil_avg_ceil_height = infil_volume / cfa
    ach50 = Airflow.get_infiltration_ACH50_from_SLA(sla, infil_avg_ceil_height)

    return ach50
  end

  # Gets the default effective R-value for an air distribution duct.
  #
  # The duct effective R-value is used in the actual duct heat transfer calculation. It includes all
  # effects (i.e., interior/exterior air films, adjustments for presence of round ducts, and adjustments
  # when buried in loose-fill attic insulation)
  #
  # @param r_nominal [Double] Duct nominal insulation R-value (hr-ft2-F/Btu)
  # @param side [String] Whether the duct is on the supply or return side (HPXML::DuctTypeXXX)
  # @param buried_level [String] How deeply the duct is buried in loose-fill insulation (HPXML::DuctBuriedInsulationXXX)
  # @param f_rect [Double] The fraction of duct length that is rectangular (not round)
  # @return [Double] Duct effective R-value (hr-ft2-F/Btu)
  def self.get_duct_effective_r_value(r_nominal, side, buried_level, f_rect)
    # This methodology has been proposed by NREL for ANSI/RESNET/ICC 301-2025.
    if buried_level == HPXML::DuctBuriedInsulationNone
      if r_nominal <= 0
        # Uninsulated ducts are set to R-1.7 based on ASHRAE HOF and the above paper.
        return 1.7
      else
        # Insulated duct equations based on "True R-Values of Round Residential Ductwork"
        # by Palmiter & Kruse 2006.
        if side == HPXML::DuctTypeSupply
          d_round = 6.0 # in, assumed average diameter
        elsif side == HPXML::DuctTypeReturn
          d_round = 14.0 # in, assumed average diameter
        end
        f_round = 1.0 - f_rect # Fraction of duct length for round ducts (not rectangular)
        r_ext = 0.667 # Exterior film R-value
        r_int_rect = 0.333 # Interior film R-value for rectangular ducts
        r_int_round = 0.3429 * (d_round**0.1974) # Interior film R-value for round ducts
        k_ins = 2.8 # Thermal resistivity of duct insulation (R-value per inch, assumed fiberglass)
        t = r_nominal / k_ins # Duct insulation thickness
        r_actual = r_nominal / t * (d_round / 2.0) * Math::log(1.0 + (2.0 * t) / d_round) # Actual R-value for round duct
        r_rect = r_int_rect + r_nominal + r_ext # Total R-value for rectangular ducts, including air films
        r_round = r_int_round + r_actual + r_ext * (d_round / (d_round + 2 * t)) # Total R-value for round ducts, including air films
        r_effective = 1.0 / (f_rect / r_rect + f_round / r_round) # Combined effective R-value
        return r_effective.round(2)
      end
    else
      if side == HPXML::DuctTypeSupply
        # Equations derived from Table 13 in https://www.nrel.gov/docs/fy13osti/55876.pdf
        # assuming 6-in supply diameter
        case buried_level
        when HPXML::DuctBuriedInsulationPartial
          return (4.28 + 0.65 * r_nominal).round(2)
        when HPXML::DuctBuriedInsulationFull
          return (6.22 + 0.89 * r_nominal).round(2)
        when HPXML::DuctBuriedInsulationDeep
          return (13.41 + 0.63 * r_nominal).round(2)
        end
      elsif side == HPXML::DuctTypeReturn
        # Equations derived from Table 13 in https://www.nrel.gov/docs/fy13osti/55876.pdf
        # assuming 14-in return diameter
        case buried_level
        when HPXML::DuctBuriedInsulationPartial
          return (4.62 + 1.31 * r_nominal).round(2)
        when HPXML::DuctBuriedInsulationFull
          return (8.91 + 1.29 * r_nominal).round(2)
        when HPXML::DuctBuriedInsulationDeep
          return (18.64 + 1.0 * r_nominal).round(2)
        end
      end
    end
  end

  # Gets the default location for a water heater based on the IECC climate zone (if available).
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param iecc_zone [String] IECC climate zone
  # @return [String] Water heater location (HPXML::LocationXXX)
  def self.get_water_heater_location(hpxml_bldg, iecc_zone = nil)
    # ANSI/RESNET/ICC 301-2022C
    case iecc_zone
    when '1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C'
      location_hierarchy = [HPXML::LocationGarage,
                            HPXML::LocationConditionedSpace]
    when '4A', '4B', '4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'
      location_hierarchy = [HPXML::LocationBasementUnconditioned,
                            HPXML::LocationBasementConditioned,
                            HPXML::LocationConditionedSpace]
    else
      if not iecc_zone.nil?
        fail "Unexpected IECC zone: #{iecc_zone}."
      end

      location_hierarchy = [HPXML::LocationBasementConditioned,
                            HPXML::LocationBasementUnconditioned,
                            HPXML::LocationConditionedSpace]
    end
    location_hierarchy.each do |location|
      if hpxml_bldg.has_location(location)
        return location
      end
    end
  end

  # Gets the default setpoint temperature for a water heater.
  #
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @return [Double] Water heater setpoint temperature (F)
  def self.get_water_heater_temperature(eri_version)
    if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2014A')
      # 2014 w/ Addendum A or newer
      return 125.0
    else
      return 120.0
    end
  end

  # Gets the default performance adjustment for a tankless water heater. Multiplier on efficiency
  # to account for cycling.
  #
  # @param water_heating_system [HPXML::WaterHeatingSystem] The HPXML water heating system of interest
  # @return [Double] Water heater performance adjustment (frac)
  def self.get_water_heater_performance_adjustment(water_heating_system)
    return unless water_heating_system.water_heater_type == HPXML::WaterHeaterTypeTankless
    if not water_heating_system.energy_factor.nil?
      return 0.92 # Applies to EF, ANSI/RESNET/ICC 301-2022
    elsif not water_heating_system.uniform_energy_factor.nil?
      return 0.94 # Applies to UEF, ANSI/RESNET/ICC 301-2022
    end
  end

  # Gets the default heating capacity for the water heater based on fuel type and number of bedrooms
  # and bathrooms in the home.
  #
  # Source: Table 8. Benchmark DHW Storage and Burner Capacity in 2014 BA HSP
  #
  # @param fuel [String] Water heater fuel type (HPXML::FuelTypeXXX)
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @param num_water_heaters [Integer] Number of water heaters serving the dwelling unit
  # @param nbaths [Integer] Number of bathrooms in the dwelling unit
  # @return [Double] Water heater heating capacity (kBtu/hr)
  def self.get_water_heater_heating_capacity(fuel, nbeds, num_water_heaters, nbaths = nil)
    if nbaths.nil?
      nbaths = Defaults.get_num_bathrooms(nbeds)
    end

    # Adjust the heating capacity if there are multiple water heaters in the home
    nbaths /= num_water_heaters.to_f

    if fuel != HPXML::FuelTypeElectricity
      if nbeds <= 3
        cap_kbtuh = 36.0
      elsif nbeds == 4
        cap_kbtuh = 38.0
      elsif nbeds == 5
        cap_kbtuh = 48.0
      else
        cap_kbtuh = 50.0
      end
      return cap_kbtuh
    else
      if nbeds == 1
        cap_kw = 2.5
      elsif nbeds == 2
        if nbaths <= 1.5
          cap_kw = 3.5
        else
          cap_kw = 4.5
        end
      elsif nbeds == 3
        if nbaths <= 1.5
          cap_kw = 4.5
        else
          cap_kw = 5.5
        end
      else
        cap_kw = 5.5
      end
      return UnitConversions.convert(cap_kw, 'kW', 'kBtu/hr')
    end
  end

  # Gets the default tank volume for a storage water heater based on fuel type and number of bedrooms
  # and bathrooms in the home.
  #
  # Source: Table 8. Benchmark DHW Storage and Burner Capacity in 2014 BA HSP
  #
  # @param fuel [String] Water heater fuel type (HPXML::FuelTypeXXX)
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @param nbaths [Integer] Number of bathrooms in the dwelling unit
  # @return [Double] Water heater tank volume (gal)
  def self.get_water_heater_tank_volume(fuel, nbeds, nbaths = nil)
    if nbaths.nil?
      nbaths = Defaults.get_num_bathrooms(nbeds)
    end

    if fuel != HPXML::FuelTypeElectricity # Non-electric tank WHs
      case nbeds
      when 0, 1, 2
        return 30.0
      when 3
        if nbaths <= 1.5
          return 30.0
        else
          return 40.0
        end
      when 4
        if nbaths <= 2.5
          return 40.0
        else
          return 50.0
        end
      else
        return 50.0
      end
    else
      case nbeds
      when 0, 1
        return 30.0
      when 2
        if nbaths <= 1.5
          return 30.0
        else
          return 40.0
        end
      when 3
        if nbaths <= 1.5
          return 40.0
        else
          return 50.0
        end
      when 4
        if nbaths <= 2.5
          return 50.0
        else
          return 66.0
        end
      when 5
        return 66.0
      else
        return 80.0
      end
    end
  end

  # Gets the default recovery efficiency for the water heater based on fuel type and efficiency.
  #
  # @param water_heating_system [HPXML::WaterHeatingSystem] The HPXML water heating system of interest
  # @return [Double] Water heater recovery efficiency (frac)
  def self.get_water_heater_recovery_efficiency(water_heating_system)
    if water_heating_system.fuel_type == HPXML::FuelTypeElectricity
      return 0.98
    else
      # FUTURE: Develop a separate algorithm specific to UEF.
      ef = water_heating_system.energy_factor
      if ef.nil?
        ef = Waterheater.calc_ef_from_uef(water_heating_system)
      end
      # Based on a regression of AHRI certified water heaters
      if ef >= 0.75 # Condensing water heater
        re = 0.561 * ef + 0.439
      else
        re = 0.252 * ef + 0.608
      end
      return re.round(3)
    end
  end

  # Gets the default UEF usage bin for a water heater, based on its first hour rating (FHR).
  #
  # @param first_hour_rating [Double] First hour rating (gal/hr)
  # @return [String] UEF usage bin (HPXML::WaterHeaterUsageBinXXX)
  def self.get_water_heater_usage_bin(first_hour_rating)
    if first_hour_rating < 18.0
      return HPXML::WaterHeaterUsageBinVerySmall
    elsif first_hour_rating < 51.0
      return HPXML::WaterHeaterUsageBinLow
    elsif first_hour_rating < 75.0
      return HPXML::WaterHeaterUsageBinMedium
    else
      return HPXML::WaterHeaterUsageBinHigh
    end
  end

  # Gets the default storage volume for a solar hot water system.
  #
  # @param collector_area [Double] Area of the collector (ft2)
  # @return [Double] Solar thermal storage volume (gal)
  def self.get_solar_thermal_system_storage_volume(collector_area)
    return 1.5 * collector_area # Assumption; 1.5 gal for every sqft of collector area
  end

  # Get the default system losses for a PV system.
  #
  # @param year_modules_manufactured [Integer] year of manufacture of the modules
  # @return [Double] System losses (frac)
  def self.get_pv_system_losses(year_modules_manufactured = nil)
    default_loss_fraction = 0.14 # PVWatts default system losses
    if not year_modules_manufactured.nil?
      return PV.calc_losses_fraction_from_year(year_modules_manufactured, default_loss_fraction)
    else
      return default_loss_fraction
    end
  end

  # Gets the default color for a roof.
  #
  # @param roof [HPXML::Roof] The HPXML roof of interest
  # @return [String] Roof color (HPXML::ColorXXX)
  def self.get_roof_color(roof)
    map = Constructions.get_roof_color_and_solar_absorptance_map
    color_map = {}
    map.each do |key, value|
      next unless key[1] == roof.roof_type

      color_map[key[0]] = value
    end
    color = color_map.min_by { |_k, v| (v - roof.solar_absorptance).abs }[0]
    return color
  end

  # Gets the default solar absorptance for a roof.
  #
  # @param roof [HPXML::Roof] The HPXML roof of interest
  # @return [Double] Roof solar absorptance (frac)
  def self.get_roof_solar_absorptance(roof)
    map = Constructions.get_roof_color_and_solar_absorptance_map
    return map[[roof.roof_color, roof.roof_type]]
  end

  # Gets the default color for a wall.
  #
  # @param wall [HPXML::Wall or HPXML::RimJoist] The HPXML wall of interest
  # @return [String] The wall color (HPXML::ColorXXX)
  def self.get_wall_color(wall)
    map = Constructions.get_wall_color_and_solar_absorptance_map
    color = map.min_by { |_k, v| (v - wall.solar_absorptance).abs }[0]
    return color
  end

  # Gets the default solar absorptance for a wall.
  #
  # @param wall [HPXML::Wall or HPXML::RimJoist] The HPXML wall of interest
  # @return [Double] Wall solar absorptance (frac)
  def self.get_wall_solar_absorptance(wall)
    map = Constructions.get_wall_color_and_solar_absorptance_map
    return map[wall.color]
  end

  # Gets the default U-factor and SHGC from window physical properties.
  #
  # @param window [HPXML::Window or HPXML::Skylight] The HPXML window of interest
  # @return [Array<Double, Double>] Window U-factor, SHGC
  def self.get_window_ufactor_shgc(window)
    type = window.is_a?(HPXML::Window) ? 'window' : 'skylight'

    case window.glass_layers
    when HPXML::WindowLayersSinglePane
      n_panes = 1
    when HPXML::WindowLayersDoublePane
      n_panes = 2
    when HPXML::WindowLayersTriplePane
      n_panes = 3
    when HPXML::WindowLayersGlassBlock
      return [0.6, 0.6] # From https://www.federalregister.gov/documents/2016/06/17/2016-13547/energy-conservation-standards-for-manufactured-housing
    end

    case window.frame_type
    when HPXML::WindowFrameTypeAluminum, HPXML::WindowFrameTypeMetal
      is_metal_frame = true
    when HPXML::WindowFrameTypeWood, HPXML::WindowFrameTypeVinyl, HPXML::WindowFrameTypeFiberglass
      is_metal_frame = false
    else
      fail "Unexpected #{type.downcase} frame type."
    end

    case window.glass_type
    when HPXML::WindowGlassTypeClear, HPXML::WindowGlassTypeReflective
      glass_type = 'clear'
    when HPXML::WindowGlassTypeTinted, HPXML::WindowGlassTypeTintedReflective
      glass_type = 'tinted'
    when HPXML::WindowGlassTypeLowE, HPXML::WindowGlassTypeLowEHighSolarGain
      glass_type = 'low_e_insulating'
    when HPXML::WindowGlassTypeLowELowSolarGain
      glass_type = 'low_e_solar_control'
    else
      fail "Unexpected #{type.downcase} glass type."
    end

    if window.glass_layers == HPXML::WindowLayersSinglePane
      gas_fill = 'none'
    else
      case window.gas_fill
      when HPXML::WindowGasAir
        gas_fill = 'air'
      when HPXML::WindowGasArgon,
           HPXML::WindowGasKrypton,
           HPXML::WindowGasXenon,
           HPXML::WindowGasNitrogen,
           HPXML::WindowGasOther
        gas_fill = 'gas'
      else
        fail "Unexpected #{type.downcase} gas type."
      end
    end

    # Lookup values
    # From http://hes-documentation.lbl.gov/calculation-methodology/calculation-of-energy-consumption/heating-and-cooling-calculation/building-envelope/window-skylight-construction-types
    key = [is_metal_frame, window.thermal_break, n_panes, glass_type, gas_fill]
    if type.downcase == 'window'
      vals = { [true, false, 1, 'clear', 'none'] => [1.27, 0.75], # Single-pane, clear, aluminum frame
               [false, nil, 1, 'clear', 'none'] => [0.89, 0.64], # Single-pane, clear, wood or vinyl frame
               [true, false, 1, 'tinted', 'none'] => [1.27, 0.64], # Single-pane, tinted, aluminum frame
               [false, nil, 1, 'tinted', 'none'] => [0.89, 0.54], # Single-pane, tinted, wood or vinyl frame
               [true, false, 2, 'clear', 'air'] => [0.81, 0.67], # Double-pane, clear, aluminum frame
               [true, true, 2, 'clear', 'air'] => [0.60, 0.67], # Double-pane, clear, aluminum frame w/ thermal break
               [false, nil, 2, 'clear', 'air'] => [0.51, 0.56], # Double-pane, clear, wood or vinyl frame
               [true, false, 2, 'tinted', 'air'] => [0.81, 0.55], # Double-pane, tinted, aluminum frame
               [true, true, 2, 'tinted', 'air'] => [0.60, 0.55], # Double-pane, tinted, aluminum frame w/ thermal break
               [false, nil, 2, 'tinted', 'air'] => [0.51, 0.46], # Double-pane, tinted, wood or vinyl frame
               [false, nil, 2, 'low_e_insulating', 'air'] => [0.42, 0.52], # Double-pane, insulating low-E, wood or vinyl frame
               [true, true, 2, 'low_e_insulating', 'gas'] => [0.47, 0.62], # Double-pane, insulating low-E, argon gas fill, aluminum frame w/ thermal break
               [false, nil, 2, 'low_e_insulating', 'gas'] => [0.39, 0.52], # Double-pane, insulating low-E, argon gas fill, wood or vinyl frame
               [true, false, 2, 'low_e_solar_control', 'air'] => [0.67, 0.37], # Double-pane, solar-control low-E, aluminum frame
               [true, true, 2, 'low_e_solar_control', 'air'] => [0.47, 0.37], # Double-pane, solar-control low-E, aluminum frame w/ thermal break
               [false, nil, 2, 'low_e_solar_control', 'air'] => [0.39, 0.31], # Double-pane, solar-control low-E, wood or vinyl frame
               [false, nil, 2, 'low_e_solar_control', 'gas'] => [0.36, 0.31], # Double-pane, solar-control low-E, argon gas fill, wood or vinyl frame
               [false, nil, 3, 'low_e_insulating', 'gas'] => [0.27, 0.31] }[key] # Triple-pane, insulating low-E, argon gas fill, wood or vinyl frame
    elsif type.downcase == 'skylight'
      vals = { [true, false, 1, 'clear', 'none'] => [1.98, 0.75], # Single-pane, clear, aluminum frame
               [false, nil, 1, 'clear', 'none'] => [1.47, 0.64], # Single-pane, clear, wood or vinyl frame
               [true, false, 1, 'tinted', 'none'] => [1.98, 0.64], # Single-pane, tinted, aluminum frame
               [false, nil, 1, 'tinted', 'none'] => [1.47, 0.54], # Single-pane, tinted, wood or vinyl frame
               [true, false, 2, 'clear', 'air'] => [1.30, 0.67], # Double-pane, clear, aluminum frame
               [true, true, 2, 'clear', 'air'] => [1.10, 0.67], # Double-pane, clear, aluminum frame w/ thermal break
               [false, nil, 2, 'clear', 'air'] => [0.84, 0.56], # Double-pane, clear, wood or vinyl frame
               [true, false, 2, 'tinted', 'air'] => [1.30, 0.55], # Double-pane, tinted, aluminum frame
               [true, true, 2, 'tinted', 'air'] => [1.10, 0.55], # Double-pane, tinted, aluminum frame w/ thermal break
               [false, nil, 2, 'tinted', 'air'] => [0.84, 0.46], # Double-pane, tinted, wood or vinyl frame
               [false, nil, 2, 'low_e_insulating', 'air'] => [0.74, 0.52], # Double-pane, insulating low-E, wood or vinyl frame
               [true, true, 2, 'low_e_insulating', 'gas'] => [0.95, 0.62], # Double-pane, insulating low-E, argon gas fill, aluminum frame w/ thermal break
               [false, nil, 2, 'low_e_insulating', 'gas'] => [0.68, 0.52], # Double-pane, insulating low-E, argon gas fill, wood or vinyl frame
               [true, false, 2, 'low_e_solar_control', 'air'] => [1.17, 0.37], # Double-pane, solar-control low-E, aluminum frame
               [true, true, 2, 'low_e_solar_control', 'air'] => [0.98, 0.37], # Double-pane, solar-control low-E, aluminum frame w/ thermal break
               [false, nil, 2, 'low_e_solar_control', 'air'] => [0.71, 0.31], # Double-pane, solar-control low-E, wood or vinyl frame
               [false, nil, 2, 'low_e_solar_control', 'gas'] => [0.65, 0.31], # Double-pane, solar-control low-E, argon gas fill, wood or vinyl frame
               [false, nil, 3, 'low_e_insulating', 'gas'] => [0.47, 0.31] }[key] # Triple-pane, insulating low-E, argon gas fill, wood or vinyl frame
    else
      fail 'Unexpected type.'
    end
    return vals if not vals.nil?

    fail "Could not lookup UFactor and SHGC for #{type.downcase} '#{window.id}'."
  end

  # Gets the default compressor type for a HVAC system.
  #
  # @param [HPXML::HeatingSystem or HPXML::CoolingSystem or HPXML::HeatPump]
  # @return [String] Compressor type (HPXML::HVACCompressorTypeXXX)
  def self.get_hvac_compressor_type(hvac_system)
    if HVAC.is_room_dx_hvac_system(hvac_system)
      return HPXML::HVACCompressorTypeSingleStage
    end

    return
  end

  # Gets the default EER for a HVAC system.
  #
  # @param [HPXML::CoolingSystem or HPXML::HeatPump]
  # @return [Double] Cooling EER2 (Btu/Wh)
  def self.get_hvac_eer2(hvac_system)
    seer2 = hvac_system.cooling_efficiency_seer2
    seer2 = HVAC.calc_seer2_from_seer(hvac_system) if seer2.nil?

    # Regressions based on Central ACs & HPs in ENERGY STAR product lists
    case hvac_system.compressor_type
    when HPXML::HVACCompressorTypeSingleStage
      return [0.73 * seer2 + 1.47, seer2].min
    when HPXML::HVACCompressorTypeTwoStage
      return [0.63 * seer2 + 2.34, seer2].min
    when HPXML::HVACCompressorTypeVariableSpeed
      return [0.31 * seer2 + 6.45, seer2].min
    end
  end

  # Gets the default fan power for a ceiling fan.
  #
  # Source: ANSI/RESNET/ICC 301
  #
  # @return [Double] Fan power (W)
  def self.get_ceiling_fan_power()
    return 42.6
  end

  # Gets the default number of ceiling fans.
  #
  # Source: ANSI/RESNET/ICC 301
  #
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @return [Integer] Number of ceiling fans
  def self.get_ceiling_fan_count(nbeds)
    return nbeds + 1
  end

  # Gets the default primary/secondary locations for a duct.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [Array<String, String>] Duct primary/secondary location (HPXML::LocationXXX)
  def self.get_duct_locations(hpxml_bldg)
    primary_duct_location_hierarchy = [HPXML::LocationBasementConditioned,
                                       HPXML::LocationBasementUnconditioned,
                                       HPXML::LocationCrawlspaceConditioned,
                                       HPXML::LocationCrawlspaceVented,
                                       HPXML::LocationCrawlspaceUnvented,
                                       HPXML::LocationAtticVented,
                                       HPXML::LocationAtticUnvented,
                                       HPXML::LocationGarage]

    primary_duct_location = nil
    primary_duct_location_hierarchy.each do |location|
      if hpxml_bldg.has_location(location)
        primary_duct_location = location
        break
      end
    end
    secondary_duct_location = HPXML::LocationConditionedSpace

    return primary_duct_location, secondary_duct_location
  end

  # Gets the default supply/return surface areas for a duct.
  #
  # @param duct_type [String] Whether the duct is on the supply or return side (HPXML::DuctTypeXXX)
  # @param duct_location [String] Location of the ducts (HPXML::LocationXXX)
  # @param ncfl [Double] Number of conditioned floors in the dwelling unit
  # @param ncfl_ag [Double] Number of conditioned floors above grade in the dwelling unit
  # @param cfa_served [Double] Dwelling unit conditioned floor area served by this distribution system (ft^2)
  # @param n_returns [Integer] Number of return registers
  # @return [Array<Double, Double>] Primary/secondary duct surface areas (ft^2)
  def self.get_duct_surface_area(duct_type, duct_location, ncfl, ncfl_ag, cfa_served, n_returns)
    # Equations based on ASHRAE 152
    # https://www.energy.gov/eere/buildings/downloads/ashrae-standard-152-spreadsheet

    # Fraction of ducts in primary location (ducts outside secondary location, i.e., conditioned space)
    f_primary = get_duct_primary_fraction(duct_location, ncfl, ncfl_ag)

    if duct_type == HPXML::DuctTypeSupply
      primary_duct_area = 0.27 * cfa_served * f_primary
      secondary_duct_area = 0.27 * cfa_served * (1.0 - f_primary)
    elsif duct_type == HPXML::DuctTypeReturn
      b_r = (n_returns < 6) ? (0.05 * n_returns) : 0.25
      primary_duct_area = b_r * cfa_served * f_primary
      secondary_duct_area = b_r * cfa_served * (1.0 - f_primary)
    end

    return primary_duct_area, secondary_duct_area
  end

  # Gets the default fraction of duct surface area in the primary location.
  #
  # @param duct_location [String] Location of the ducts (HPXML::LocationXXX)
  # @param ncfl [Double] Number of conditioned floors in the dwelling unit
  # @param ncfl_ag [Double] Number of conditioned floors above grade in the dwelling unit
  # @return [Double] Fraction in primary location
  def self.get_duct_primary_fraction(duct_location, ncfl, ncfl_ag)
    # Equation based on ASHRAE 152
    # https://www.energy.gov/eere/buildings/downloads/ashrae-standard-152-spreadsheet

    # Example logic:
    #
    # =========================    ==============    =========
    # Bldg Type                    Duct Location     f_primary
    # =========================    ==============    =========
    # 1-story, crawl, attic        crawl or attic    1.0
    # 1-story, cond bsmt, attic    cond bsmt         1.0
    # 1-story, cond bsmt, attic    attic             0.75 (some ducts must run from attic to cond bsmt)
    # 2-story, crawl, attic	       crawl        	   0.75 (some ducts must run from crawl to 2nd story)
    # 2-story, crawl, attic	       attic        	   0.75 (some ducts must run from attic to 1st story)
    # =========================    ==============    =========

    if [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented].include? duct_location
      f_primary = (ncfl <= 1) ? 1.0 : 0.75
    else
      f_primary = (ncfl_ag <= 1) ? 1.0 : 0.75
    end
    return f_primary
  end

  # Gets the default pump power for a closed loop ground-source heat pump.
  #
  # @return [Double] Pump power (W/ton)
  def self.get_gshp_pump_power()
    return 80.0 # Rough estimate based on a literature review of different studies/websites
  end

  # Gets the default Electric Auxiliary Energy (EAE) for a boiler.
  #
  # @param heating_system [HPXML::HeatingSystem] The HPXML heating system of interest
  # @return [Double or nil] EAE annual consumption if applicable (kWh/yr)
  def self.get_boiler_eae(heating_system)
    if heating_system.heating_system_type != HPXML::HVACTypeBoiler
      return
    end
    if not heating_system.electric_auxiliary_energy.nil?
      return heating_system.electric_auxiliary_energy
    end

    # From ANSI/RESNET/ICC 301-2019 Standard
    fuel = heating_system.heating_system_fuel

    if heating_system.is_shared_system
      distribution_system = heating_system.distribution_system
      distribution_type = distribution_system.distribution_system_type

      if not heating_system.shared_loop_watts.nil?
        sp_kw = UnitConversions.convert(heating_system.shared_loop_watts, 'W', 'kW')
        n_dweq = heating_system.number_of_units_served.to_f
        if distribution_system.air_type == HPXML::AirTypeFanCoil
          aux_in = UnitConversions.convert(heating_system.fan_coil_watts, 'W', 'kW')
        else
          aux_in = 0.0 # ANSI/RESNET/ICC 301-2019 Section 4.4.7.2
        end
        # ANSI/RESNET/ICC 301-2019 Equation 4.4-5
        return (((sp_kw / n_dweq) + aux_in) * 2080.0).round(2) # kWh/yr
      elsif distribution_type == HPXML::HVACDistributionTypeHydronic
        # kWh/yr, per ANSI/RESNET/ICC 301-2019 Table 4.5.2(5)
        if distribution_system.hydronic_type == HPXML::HydronicTypeWaterLoop # Shared boiler w/ WLHP
          return 265.0
        else # Shared boiler w/ baseboard/radiators/etc
          return 220.0
        end
      elsif distribution_type == HPXML::HVACDistributionTypeAir
        if distribution_system.air_type == HPXML::AirTypeFanCoil # Shared boiler w/ fan coil
          return 438.0
        end
      end

    else # In-unit boilers

      if [HPXML::FuelTypeNaturalGas,
          HPXML::FuelTypePropane,
          HPXML::FuelTypeElectricity,
          HPXML::FuelTypeWoodCord,
          HPXML::FuelTypeWoodPellets].include? fuel
        return 170.0 # kWh/yr
      elsif [HPXML::FuelTypeOil,
             HPXML::FuelTypeOil1,
             HPXML::FuelTypeOil2,
             HPXML::FuelTypeOil4,
             HPXML::FuelTypeOil5or6,
             HPXML::FuelTypeDiesel,
             HPXML::FuelTypeKerosene,
             HPXML::FuelTypeCoal,
             HPXML::FuelTypeCoalAnthracite,
             HPXML::FuelTypeCoalBituminous,
             HPXML::FuelTypeCoke].include? fuel
        return 330.0 # kWh/yr
      end
    end
  end

  # Gets the default interior/garage/exterior lighting fractions. Used by OS-ERI, OS-HEScore, etc.
  #
  # Source: ANSI/RESNET/ICC 301
  #
  # @return [Hash] Map of [HPXML::LocationXXX, HPXML::LightingTypeXXX] => lighting fraction
  def self.get_lighting_fractions()
    ltg_fracs = {}
    [HPXML::LocationInterior, HPXML::LocationExterior, HPXML::LocationGarage].each do |location|
      [HPXML::LightingTypeCFL, HPXML::LightingTypeLFL, HPXML::LightingTypeLED].each do |lighting_type|
        if (location == HPXML::LocationInterior) && (lighting_type == HPXML::LightingTypeCFL)
          ltg_fracs[[location, lighting_type]] = 0.1
        else
          ltg_fracs[[location, lighting_type]] = 0
        end
      end
    end
    return ltg_fracs
  end

  # Gets the default heating setpoints.
  #
  # Source: ANSI/RESNET/ICC 301
  #
  # @param control_type [String] Thermostat control type (HPXML::HVACControlTypeXXX)
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @return [Array<String, String>] 24 hourly comma-separated weekday and weekend setpoints
  def self.get_heating_setpoint(control_type, eri_version)
    htg_wd_setpoints = '68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68'
    htg_we_setpoints = '68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68'
    if control_type == HPXML::HVACControlTypeProgrammable
      if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2022')
        htg_wd_setpoints = '66, 66, 66, 66, 66, 67, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 66'
        htg_we_setpoints = '66, 66, 66, 66, 66, 67, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 66'
      else
        htg_wd_setpoints = '66, 66, 66, 66, 66, 66, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 66'
        htg_we_setpoints = '66, 66, 66, 66, 66, 66, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 66'
      end
    elsif control_type != HPXML::HVACControlTypeManual
      fail "Unexpected control type #{control_type}."
    end
    return htg_wd_setpoints, htg_we_setpoints
  end

  # Gets the default cooling setpoints.
  #
  # Source: ANSI/RESNET/ICC 301
  #
  # @param control_type [String] Thermostat control type (HPXML::HVACControlTypeXXX)
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @return [Array<String, String>] 24 hourly comma-separated weekday and weekend setpoints
  def self.get_cooling_setpoint(control_type, eri_version)
    clg_wd_setpoints = '78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78'
    clg_we_setpoints = '78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78'
    if control_type == HPXML::HVACControlTypeProgrammable
      if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2022')
        clg_wd_setpoints = '78, 78, 78, 78, 78, 78, 78, 78, 78, 80, 80, 80, 80, 80, 79, 78, 78, 78, 78, 78, 78, 78, 78, 78'
        clg_we_setpoints = '78, 78, 78, 78, 78, 78, 78, 78, 78, 80, 80, 80, 80, 80, 79, 78, 78, 78, 78, 78, 78, 78, 78, 78'
      else
        clg_wd_setpoints = '78, 78, 78, 78, 78, 78, 78, 78, 78, 80, 80, 80, 80, 80, 80, 78, 78, 78, 78, 78, 78, 78, 78, 78'
        clg_we_setpoints = '78, 78, 78, 78, 78, 78, 78, 78, 78, 80, 80, 80, 80, 80, 80, 78, 78, 78, 78, 78, 78, 78, 78, 78'
      end
    elsif control_type != HPXML::HVACControlTypeManual
      fail "Unexpected control type #{control_type}."
    end
    return clg_wd_setpoints, clg_we_setpoints
  end

  # Gets the monthly ceiling fan operation schedule.
  #
  # Source: ANSI/RESNET/ICC 301
  #
  # @param weather [WeatherFile] Weather object containing EPW information
  # @return [Array<Integer>] monthly array of 1s and 0s
  def self.get_ceiling_fan_months(weather)
    months = [0] * 12
    weather.data.MonthlyAvgDrybulbs.each_with_index do |val, m|
      next unless val > 63.0 # Ceiling fan operates when average drybulb temperature is greater than 63F

      months[m] = 1
    end
    return months
  end

  # Returns the number of breaker spaces based on rated power and voltage.
  #
  # @param watts [Double] power rating (W)
  # @param voltage [String] '120' or '240'
  # @param max_amps [Double] maximum amperage (A)
  # @return [Integer] the number of breaker spaces
  def self.get_breaker_spaces_from_power_watts_voltage_amps(watts, voltage, max_amps)
    return 0 if watts == 0

    # Note that default_panels.csv has a Breaker Spaces column manually populated based on the following calculation.
    # If max_amps were to change, for example, the value in Breaker Spaces may change.
    required_amperage = watts / Float(voltage)
    num_branches = (required_amperage / max_amps).ceil
    num_breakers = num_branches * Integer(Float(voltage) / 120)
    return num_breakers
  end

  # Gets the default voltage for a branch circuit based on attached component.
  #
  # @param branch_circuit [HPXML::BranchCircuit] Object that defines a single electric panel branch circuit
  # @return [String] '120' or '240'
  def self.get_branch_circuit_voltage_default_values(branch_circuit)
    voltages = []
    branch_circuit.components.each do |component|
      if component.is_a?(HPXML::HeatingSystem)
        if component.heating_system_fuel == HPXML::FuelTypeElectricity
          voltages << HPXML::ElectricPanelVoltage240
        end
      elsif component.is_a?(HPXML::CoolingSystem)
        if component.cooling_system_type != HPXML::HVACTypeRoomAirConditioner
          voltages << HPXML::ElectricPanelVoltage240
        end
      elsif component.is_a?(HPXML::HeatPump)
        if component.heat_pump_fuel == HPXML::FuelTypeElectricity
          voltages << HPXML::ElectricPanelVoltage240
        end
      elsif component.is_a?(HPXML::PVSystem)
        voltages << HPXML::ElectricPanelVoltage240
      elsif component.is_a?(HPXML::WaterHeatingSystem) ||
            component.is_a?(HPXML::ClothesDryer) ||
            component.is_a?(HPXML::CookingRange)
        if component.fuel_type == HPXML::FuelTypeElectricity
          voltages << HPXML::ElectricPanelVoltage240
        end
      elsif component.is_a?(HPXML::PermanentSpa) ||
            component.is_a?(HPXML::Pool)
        if branch_circuit.component_idrefs.include?(component.pump_id)
          voltages << HPXML::ElectricPanelVoltage240
        elsif branch_circuit.component_idrefs.include?(component.heater_id)
          if [HPXML::HeaterTypeElectricResistance, HPXML::HeaterTypeHeatPump].include?(component.heater_type)
            voltages << HPXML::ElectricPanelVoltage240
          end
        end
      elsif component.is_a?(HPXML::PlugLoad)
        if component.plug_load_type == HPXML::PlugLoadTypeWellPump
          voltages << HPXML::ElectricPanelVoltage240
        end
      end
    end
    if voltages.include?(HPXML::ElectricPanelVoltage240)
      return HPXML::ElectricPanelVoltage240
    end

    return HPXML::ElectricPanelVoltage120
  end

  # Gets the default max amps for a branch circuit based on voltage.
  #
  # @param branch_circuit [HPXML::BranchCircuit] Object that defines a single electric panel branch circuit
  # @return [Double] maximum amperage
  def self.get_branch_circuit_amps_default_values(branch_circuit)
    if branch_circuit.voltage == HPXML::ElectricPanelVoltage120
      return 15.0 # shared circuit
    end

    return 50.0
  end

  # Gets the default power rating capacity for each panel load.
  #
  # @return [Hash] { load_name => { voltage => power_rating, ... }, ... }
  def self.get_panels_csv_data()
    default_panels_csv = File.join(File.dirname(__FILE__), 'data', 'default_panels.csv')
    if not File.exist?(default_panels_csv)
      fail 'Could not find default_panels.csv'
    end

    require 'csv'
    default_panels_csv_data = {}
    CSV.foreach(default_panels_csv, headers: true) do |row|
      load_name = row['Load Name']
      voltage = row['Voltage']
      power_rating = row['Power Rating']
      breaker_spaces = row['Breaker Spaces']

      power_rating = 0 if power_rating == 'auto'
      breaker_spaces = 0 if breaker_spaces == 'auto'

      default_panels_csv_data[load_name] = {} if !default_panels_csv_data.keys.include?(load_name)
      default_panels_csv_data[load_name][voltage] = {}
      default_panels_csv_data[load_name][voltage]['PowerRating'] = Float(power_rating)
      default_panels_csv_data[load_name][voltage]['BreakerSpaces'] = Integer(breaker_spaces)
    end

    return default_panels_csv_data
  end

  # Get the Power Rating or Breaker Spaces from the default_panels.csv file.
  # If Voltage does not exist in the table, then either:
  #  - Power Rating: default per the other Voltage classification
  #  - Breaker Spaces: recalculate using the specified Voltage classification
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param default_panels_csv_data [Hash] { load_name => { voltage => power_rating, ... }, ... }
  # @param load_name [String] load name specified in default_panels.csv
  # @param column [String] 'PowerRating' or 'BreakerSpaces'
  # @param voltage [String] '120' or '240'
  # @param watts [Double or nil] power rating (W)
  # @param max_current_rating [Double or nil] maximum amperage
  # @return [Double or Integer] power rating or number of breaker spaces
  def self.get_default_panels_value(runner, default_panels_csv_data, load_name, column, voltage, watts = nil, max_current_rating = nil)
    if not default_panels_csv_data[load_name].keys.include?(voltage)
      warning = "Voltage (#{voltage}) for '#{load_name}' is not specified in default_panels.csv; "
      if column == 'PowerRating'
        if voltage == HPXML::ElectricPanelVoltage120
          new_voltage = HPXML::ElectricPanelVoltage240
        elsif voltage == HPXML::ElectricPanelVoltage240
          new_voltage = HPXML::ElectricPanelVoltage120
        end
        warning += "PowerRating will be assigned according to Voltage=#{new_voltage}."
        value = default_panels_csv_data[load_name][new_voltage][column]
      elsif column == 'BreakerSpaces'
        warning += "BreakerSpaces will be recalculated using Voltage=#{voltage}."
        value = get_breaker_spaces_from_power_watts_voltage_amps(watts, voltage, max_current_rating)
      end
      runner.registerWarning(warning)
      return value
    else
      value = default_panels_csv_data[load_name][voltage][column]
      value = 0 if watts == 0
      return value
    end
  end

  # Get or add a branch circuit based on whether one already exists for a given component.
  # If add is true, and the component already has a branch circuit, we add another branch circuit (this is useful for adding air handler unit information).
  #
  # @param electric_panel [HPXML::ElectricPanel] Object that defines a single electric panel
  # @param component [HPXML::XXX] a component
  # @param add [Boolean] whether to add a branch circuit even if one already exists
  # @return [HPXML::BranchCircuit] Object that defines a single electric panel branch circuit
  def self.get_or_add_branch_circuit(electric_panel, component, unit_num, add = false)
    branch_circuits = electric_panel.branch_circuits
    if component.branch_circuits.empty? || add
      branch_circuits.add(id: get_id('BranchCircuit', branch_circuits, unit_num),
                          component_idrefs: [component.id])
      branch_circuit = branch_circuits[-1]
    else
      branch_circuit = component.branch_circuits[0]
    end

    if branch_circuit.voltage.nil?
      branch_circuit.voltage = get_branch_circuit_voltage_default_values(branch_circuit)
      branch_circuit.voltage_isdefaulted = true
    end
    if branch_circuit.max_current_rating.nil?
      branch_circuit.max_current_rating = get_branch_circuit_amps_default_values(branch_circuit)
      branch_circuit.max_current_rating_isdefaulted = true
    end

    return branch_circuit
  end

  # Gets the default power rating for a service feeder based on load type, voltage, amps, and attached components.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param service_feeder [HPXML::ServiceFeeder] Object that defines a single electric panel service feeder
  # @param default_panels_csv_data [Hash] { load_name => { voltage => power_rating, ... }, ... }
  # @param electric_panel [HPXML::ElectricPanel] Object that defines a single electric panel
  # @return [Double] power rating (W)
  def self.get_service_feeder_power_default_values(runner, hpxml_bldg, service_feeder, default_panels_csv_data, electric_panel, unit_num)
    type = service_feeder.type
    component_ids = service_feeder.component_idrefs
    watts = 0

    if type == HPXML::ElectricPanelLoadTypeHeating
      hpxml_bldg.heating_systems.each do |heating_system|
        next if !component_ids.include?(heating_system.id)
        next if heating_system.is_shared_system
        next if heating_system.fraction_heat_load_served == 0

        branch_circuit = get_or_add_branch_circuit(electric_panel, heating_system, unit_num)

        if heating_system.heating_system_fuel == HPXML::FuelTypeElectricity
          watts += UnitConversions.convert(HVAC.get_heating_input_capacity(heating_system.heating_capacity, heating_system.heating_efficiency_afue, heating_system.heating_efficiency_percent), 'btu/hr', 'w')
        end

        watts += HVAC.get_blower_fan_power_watts(heating_system.fan_watts_per_cfm, heating_system.additional_properties.heating_actual_airflow_cfm)
        watts += HVAC.get_pump_power_watts(heating_system)

        if branch_circuit.occupied_spaces.nil?
          branch_circuit.occupied_spaces = get_breaker_spaces_from_power_watts_voltage_amps(watts, branch_circuit.voltage, branch_circuit.max_current_rating)
          branch_circuit.occupied_spaces_isdefaulted = true
        end
      end

      hpxml_bldg.heat_pumps.each do |heat_pump|
        next if !component_ids.include?(heat_pump.id)
        next if heat_pump.fraction_heat_load_served == 0

        branch_circuit_odu = get_or_add_branch_circuit(electric_panel, heat_pump, unit_num)
        branch_circuit_ahu = get_or_add_branch_circuit(electric_panel, heat_pump, unit_num, true)

        watts_ahu = HVAC.get_blower_fan_power_watts(heat_pump.fan_watts_per_cfm, heat_pump.additional_properties.heating_actual_airflow_cfm)
        watts_ahu += HVAC.get_pump_power_watts(heat_pump)
        watts_odu = HVAC.get_dx_coil_power_watts_from_capacity(UnitConversions.convert(heat_pump.heating_capacity, 'btu/hr', 'kbtu/hr'), branch_circuit_odu.voltage)

        if heat_pump.backup_type == HPXML::HeatPumpBackupTypeIntegrated

          if heat_pump.overlapping_compressor_and_backup_operation # sum; backup > compressor

            if heat_pump.backup_heating_fuel == HPXML::FuelTypeElectricity
              watts_ahu += UnitConversions.convert(HVAC.get_heating_input_capacity(heat_pump.backup_heating_capacity, heat_pump.backup_heating_efficiency_afue, heat_pump.backup_heating_efficiency_percent), 'btu/hr', 'w')
            end

          else # max; switchover (only be used for a heat pump with fossil fuel backup)

            branch_circuit_ahu.voltage = HPXML::ElectricPanelVoltage120
            branch_circuit_ahu.max_current_rating = get_branch_circuit_amps_default_values(branch_circuit_ahu)

          end
        end

        if branch_circuit_ahu.occupied_spaces.nil?
          if ((heat_pump.backup_type.nil? || (heat_pump.backup_type == HPXML::HeatPumpBackupTypeSeparate)) &&
             (heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpMiniSplit))
            branch_circuit_ahu.occupied_spaces = 0
          else
            branch_circuit_ahu.occupied_spaces = get_breaker_spaces_from_power_watts_voltage_amps(watts_ahu, branch_circuit_ahu.voltage, branch_circuit_ahu.max_current_rating)
          end
          branch_circuit_ahu.occupied_spaces_isdefaulted = true
        end

        if branch_circuit_odu.occupied_spaces.nil?
          branch_circuit_odu.occupied_spaces = get_breaker_spaces_from_power_watts_voltage_amps(watts_odu, branch_circuit_odu.voltage, branch_circuit_odu.max_current_rating)
          branch_circuit_odu.occupied_spaces_isdefaulted = true
        end

        watts += watts_ahu + watts_odu
      end

    elsif type == HPXML::ElectricPanelLoadTypeCooling
      hpxml_bldg.cooling_systems.each do |cooling_system|
        next if !component_ids.include?(cooling_system.id)
        next if cooling_system.is_shared_system
        next if cooling_system.fraction_cool_load_served == 0

        branch_circuit_odu = get_or_add_branch_circuit(electric_panel, cooling_system, unit_num)
        branch_circuit_ahu = get_or_add_branch_circuit(electric_panel, cooling_system, unit_num, true)

        watts_ahu = HVAC.get_blower_fan_power_watts(cooling_system.fan_watts_per_cfm, cooling_system.additional_properties.cooling_actual_airflow_cfm)
        watts_odu = HVAC.get_dx_coil_power_watts_from_capacity(UnitConversions.convert(cooling_system.cooling_capacity, 'btu/hr', 'kbtu/hr'), branch_circuit_odu.voltage)

        if branch_circuit_ahu.occupied_spaces.nil?
          if (not cooling_system.distribution_system.nil?) && (cooling_system.attached_heating_system.nil? || cooling_system.attached_heating_system.distribution_system.nil?)
            branch_circuit_ahu.voltage = HPXML::ElectricPanelVoltage120
            branch_circuit_ahu.max_current_rating = get_branch_circuit_amps_default_values(branch_circuit_ahu)
            branch_circuit_ahu.occupied_spaces = get_breaker_spaces_from_power_watts_voltage_amps(watts_ahu, branch_circuit_ahu.voltage, branch_circuit_ahu.max_current_rating)
          else
            branch_circuit_ahu.occupied_spaces = 0
          end
          branch_circuit_ahu.occupied_spaces_isdefaulted = true
        end

        if branch_circuit_odu.occupied_spaces.nil?
          if (cooling_system.cooling_system_type != HPXML::HVACTypeRoomAirConditioner) || (branch_circuit_odu.voltage == HPXML::ElectricPanelVoltage240)
            branch_circuit_odu.occupied_spaces = get_breaker_spaces_from_power_watts_voltage_amps(watts_odu, branch_circuit_odu.voltage, branch_circuit_odu.max_current_rating)
          else
            branch_circuit_odu.occupied_spaces = 0
          end
          branch_circuit_odu.occupied_spaces_isdefaulted = true
        end

        watts += watts_ahu + watts_odu
      end

      hpxml_bldg.heat_pumps.each do |heat_pump|
        next if !component_ids.include?(heat_pump.id)
        next if heat_pump.fraction_cool_load_served == 0

        watts_ahu = HVAC.get_blower_fan_power_watts(heat_pump.fan_watts_per_cfm, heat_pump.additional_properties.cooling_actual_airflow_cfm)
        watts_ahu += HVAC.get_pump_power_watts(heat_pump)
        watts_odu = HVAC.get_dx_coil_power_watts_from_capacity(UnitConversions.convert(heat_pump.cooling_capacity, 'btu/hr', 'kbtu/hr'), HPXML::ElectricPanelVoltage240)

        if heat_pump.fraction_heat_load_served == 0
          branch_circuit_odu = get_or_add_branch_circuit(electric_panel, heat_pump, unit_num)
          branch_circuit_ahu = get_or_add_branch_circuit(electric_panel, heat_pump, unit_num, true)

          if branch_circuit_ahu.occupied_spaces.nil?
            branch_circuit_ahu.occupied_spaces = get_breaker_spaces_from_power_watts_voltage_amps(watts_ahu, branch_circuit_ahu.voltage, branch_circuit_ahu.max_current_rating)
            branch_circuit_ahu.occupied_spaces_isdefaulted = true
          end

          if branch_circuit_odu.occupied_spaces.nil?
            branch_circuit_odu.occupied_spaces = get_breaker_spaces_from_power_watts_voltage_amps(watts_odu, branch_circuit_odu.voltage, branch_circuit_odu.max_current_rating)
            branch_circuit_odu.occupied_spaces_isdefaulted = true
          end
        end

        watts += watts_ahu + watts_odu
      end

    elsif type == HPXML::ElectricPanelLoadTypeWaterHeater
      hpxml_bldg.water_heating_systems.each do |water_heating_system|
        next if !component_ids.include?(water_heating_system.id)
        next if water_heating_system.fuel_type != HPXML::FuelTypeElectricity
        next if water_heating_system.is_shared_system

        if water_heating_system.water_heater_type == HPXML::WaterHeaterTypeStorage
          watts += UnitConversions.convert(water_heating_system.heating_capacity, 'btu/hr', 'w')
        elsif water_heating_system.water_heater_type == HPXML::WaterHeaterTypeHeatPump
          watts += [UnitConversions.convert(Waterheater.get_heating_input_capacity(water_heating_system.heating_capacity, water_heating_system.additional_properties.cop), 'btu/hr', 'w'),
                    UnitConversions.convert(water_heating_system.backup_heating_capacity, 'btu/hr', 'w')].max
        elsif water_heating_system.water_heater_type == HPXML::WaterHeaterTypeTankless
          if hpxml_bldg.building_construction.number_of_bathrooms == 1
            load_name = 'wh_tankless1'
          elsif hpxml_bldg.building_construction.number_of_bathrooms == 2
            load_name = 'wh_tankless2'
          else # 3+
            load_name = 'wh_tankless3'
          end
          water_heating_system.branch_circuits.each do |branch_circuit|
            watts += get_default_panels_value(runner, default_panels_csv_data, load_name, 'PowerRating', branch_circuit.voltage)
          end
        end
      end
    elsif type == HPXML::ElectricPanelLoadTypeClothesDryer
      hpxml_bldg.clothes_dryers.each do |clothes_dryer|
        next if !component_ids.include?(clothes_dryer.id)
        next if clothes_dryer.fuel_type != HPXML::FuelTypeElectricity

        if clothes_dryer.drying_method == HPXML::DryingMethodHeatPump
          clothes_dryer.branch_circuits.each do |branch_circuit|
            watts += get_default_panels_value(runner, default_panels_csv_data, 'dryer_hp', 'PowerRating', branch_circuit.voltage)
          end
        else
          clothes_dryer.branch_circuits.each do |branch_circuit|
            watts += get_default_panels_value(runner, default_panels_csv_data, 'dryer', 'PowerRating', branch_circuit.voltage)
          end
        end
      end
    elsif type == HPXML::ElectricPanelLoadTypeDishwasher
      hpxml_bldg.dishwashers.each do |dishwasher|
        next if !component_ids.include?(dishwasher.id)

        dishwasher.branch_circuits.each do |branch_circuit|
          watts += get_default_panels_value(runner, default_panels_csv_data, 'dishwasher', 'PowerRating', branch_circuit.voltage)
        end
      end
    elsif type == HPXML::ElectricPanelLoadTypeRangeOven
      hpxml_bldg.cooking_ranges.each do |cooking_range|
        next if !component_ids.include?(cooking_range.id)
        next if cooking_range.fuel_type != HPXML::FuelTypeElectricity

        if cooking_range.is_induction
          cooking_range.branch_circuits.each do |branch_circuit|
            watts += get_default_panels_value(runner, default_panels_csv_data, 'rangeoven_induction', 'PowerRating', branch_circuit.voltage)
          end
        else # resistance
          cooking_range.branch_circuits.each do |branch_circuit|
            watts += get_default_panels_value(runner, default_panels_csv_data, 'rangeoven', 'PowerRating', branch_circuit.voltage)
          end
        end
      end
    elsif type == HPXML::ElectricPanelLoadTypeMechVent
      hpxml_bldg.ventilation_fans.each do |ventilation_fan|
        next if !component_ids.include?(ventilation_fan.id)
        next if ventilation_fan.is_shared_system

        if [HPXML::LocationKitchen, HPXML::LocationBath].include?(ventilation_fan.fan_location)
          watts += ventilation_fan.count * ventilation_fan.fan_power
        elsif not ventilation_fan.fan_power.nil?
          watts += ventilation_fan.fan_power
        else
          ventilation_fan.branch_circuits.each do |branch_circuit|
            watts += get_default_panels_value(runner, default_panels_csv_data, 'mechvent', 'PowerRating', branch_circuit.voltage) # base-mechvent-cfis-no-additional-runtime.xml, e.g., has no FanPower defaulted
          end
        end
      end
    elsif type == HPXML::ElectricPanelLoadTypePermanentSpaHeater
      hpxml_bldg.permanent_spas.each do |permanent_spa|
        next if !component_ids.include?(permanent_spa.heater_id)
        next if ![HPXML::HeaterTypeElectricResistance, HPXML::HeaterTypeHeatPump].include?(permanent_spa.heater_type)

        if permanent_spa.heater_type == HPXML::HeaterTypeElectricResistance
          permanent_spa.heater_branch_circuits.each do |branch_circuit|
            watts += get_default_panels_value(runner, default_panels_csv_data, 'spaheater', 'PowerRating', branch_circuit.voltage)
          end
        elsif permanent_spa.heater_type == HPXML::HeaterTypeHeatPump
          permanent_spa.heater_branch_circuits.each do |branch_circuit|
            watts += get_default_panels_value(runner, default_panels_csv_data, 'spaheater_hp', 'PowerRating', branch_circuit.voltage)
          end
        end
      end
    elsif type == HPXML::ElectricPanelLoadTypePermanentSpaPump
      hpxml_bldg.permanent_spas.each do |permanent_spa|
        next if !component_ids.include?(permanent_spa.pump_id)

        permanent_spa.pump_branch_circuits.each do |branch_circuit|
          watts += get_default_panels_value(runner, default_panels_csv_data, 'spapump', 'PowerRating', branch_circuit.voltage)
        end
      end
    elsif type == HPXML::ElectricPanelLoadTypePoolHeater
      hpxml_bldg.pools.each do |pool|
        next if !component_ids.include?(pool.heater_id)
        next if ![HPXML::HeaterTypeElectricResistance, HPXML::HeaterTypeHeatPump].include?(pool.heater_type)

        if pool.heater_type == HPXML::HeaterTypeElectricResistance
          pool.heater_branch_circuits.each do |branch_circuit|
            watts += get_default_panels_value(runner, default_panels_csv_data, 'poolheater', 'PowerRating', branch_circuit.voltage)
          end
        elsif pool.heater_type == HPXML::HeaterTypeHeatPump
          pool.heater_branch_circuits.each do |branch_circuit|
            watts += get_default_panels_value(runner, default_panels_csv_data, 'poolheater_hp', 'PowerRating', branch_circuit.voltage)
          end
        end
      end
    elsif type == HPXML::ElectricPanelLoadTypePoolPump
      hpxml_bldg.pools.each do |pool|
        next if !component_ids.include?(pool.pump_id)

        pool.pump_branch_circuits.each do |branch_circuit|
          watts += get_default_panels_value(runner, default_panels_csv_data, 'poolpump', 'PowerRating', branch_circuit.voltage)
        end
      end
    elsif type == HPXML::ElectricPanelLoadTypeWellPump
      hpxml_bldg.plug_loads.each do |plug_load|
        next if plug_load.plug_load_type != HPXML::PlugLoadTypeWellPump
        next if !component_ids.include?(plug_load.id)

        if hpxml_bldg.building_construction.number_of_bedrooms <= 3
          plug_load.branch_circuits.each do |branch_circuit|
            watts += get_default_panels_value(runner, default_panels_csv_data, 'wellpump_small', 'PowerRating', branch_circuit.voltage)
          end
        else
          plug_load.branch_circuits.each do |branch_circuit|
            watts += get_default_panels_value(runner, default_panels_csv_data, 'wellpump_large', 'PowerRating', branch_circuit.voltage)
          end
        end
      end
    elsif type == HPXML::ElectricPanelLoadTypeElectricVehicleCharging
      hpxml_bldg.plug_loads.each do |plug_load|
        next if plug_load.plug_load_type != HPXML::PlugLoadTypeElectricVehicleCharging
        next if !component_ids.include?(plug_load.id)

        plug_load.branch_circuits.each do |branch_circuit|
          watts += get_default_panels_value(runner, default_panels_csv_data, 'ev_level', 'PowerRating', branch_circuit.voltage)
        end
      end

      hpxml_bldg.ev_chargers.each do |ev_charger|
        next if !component_ids.include?(ev_charger.id)

        ev_charger.branch_circuits.each do |branch_circuit|
          watts += get_default_panels_value(runner, default_panels_csv_data, 'ev_level', 'PowerRating', branch_circuit.voltage)
        end
      end
    elsif type == HPXML::ElectricPanelLoadTypeLighting
      watts += get_default_panels_value(runner, default_panels_csv_data, 'lighting', 'PowerRating', HPXML::ElectricPanelVoltage120) * hpxml_bldg.building_construction.conditioned_floor_area
    elsif type == HPXML::ElectricPanelLoadTypeKitchen
      watts += get_default_panels_value(runner, default_panels_csv_data, 'kitchen', 'PowerRating', HPXML::ElectricPanelVoltage120)
    elsif type == HPXML::ElectricPanelLoadTypeLaundry
      watts += get_default_panels_value(runner, default_panels_csv_data, 'laundry', 'PowerRating', HPXML::ElectricPanelVoltage120)
    elsif type == HPXML::ElectricPanelLoadTypeOther
      if hpxml_bldg.has_location(HPXML::LocationGarage)
        watts += get_default_panels_value(runner, default_panels_csv_data, 'other', 'PowerRating', HPXML::ElectricPanelVoltage120) # Garage door opener
      end
    end

    return watts.round(1)
  end

  # Gets the default breaker spaces for a branch circuit based on power rating, voltage, amps, and attached components.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param branch_circuit [HPXML::BranchCircuit] Object that defines a single electric panel branch circuit
  # @param default_panels_csv_data [Hash] { load_name => { voltage => power_rating, ... }, ... }
  # @return [Integer] number of breaker spaces
  def self.get_branch_circuit_occupied_spaces_default_values(runner, hpxml_bldg, branch_circuit, default_panels_csv_data)
    voltage = branch_circuit.voltage
    max_current_rating = branch_circuit.max_current_rating
    component_ids = branch_circuit.component_idrefs
    breaker_spaces = 0

    hpxml_bldg.water_heating_systems.each do |water_heating_system|
      next if !component_ids.include?(water_heating_system.id)
      next if water_heating_system.fuel_type != HPXML::FuelTypeElectricity
      next if water_heating_system.is_shared_system

      watts = water_heating_system.service_feeders.select { |sf| sf.type == HPXML::ElectricPanelLoadTypeWaterHeater }.map { |sf| sf.power }.sum(0.0)
      if water_heating_system.water_heater_type == HPXML::WaterHeaterTypeStorage
        breaker_spaces += get_breaker_spaces_from_power_watts_voltage_amps(watts, voltage, max_current_rating)
      elsif water_heating_system.water_heater_type == HPXML::WaterHeaterTypeHeatPump
        breaker_spaces += get_breaker_spaces_from_power_watts_voltage_amps(watts, voltage, max_current_rating)
      elsif water_heating_system.water_heater_type == HPXML::WaterHeaterTypeTankless
        if hpxml_bldg.building_construction.number_of_bathrooms == 1
          load_name = 'wh_tankless1'
        elsif hpxml_bldg.building_construction.number_of_bathrooms == 2
          load_name = 'wh_tankless2'
        else # 3+
          load_name = 'wh_tankless3'
        end
        breaker_spaces += get_default_panels_value(runner, default_panels_csv_data, load_name, 'BreakerSpaces', voltage, watts, max_current_rating)
      end
    end

    hpxml_bldg.clothes_dryers.each do |clothes_dryer|
      next if !component_ids.include?(clothes_dryer.id)
      next if clothes_dryer.fuel_type != HPXML::FuelTypeElectricity

      if clothes_dryer.is_vented
        load_name = 'dryer'
      else # HP
        load_name = 'dryer_hp'
      end
      watts = clothes_dryer.service_feeders.select { |sf| sf.type == HPXML::ElectricPanelLoadTypeClothesDryer }.map { |sf| sf.power }.sum(0.0)
      breaker_spaces += get_default_panels_value(runner, default_panels_csv_data, load_name, 'BreakerSpaces', voltage, watts, max_current_rating)
    end

    hpxml_bldg.dishwashers.each do |dishwasher|
      next if !component_ids.include?(dishwasher.id)

      watts = dishwasher.service_feeders.select { |sf| sf.type == HPXML::ElectricPanelLoadTypeDishwasher }.map { |sf| sf.power }.sum(0.0)
      breaker_spaces += get_default_panels_value(runner, default_panels_csv_data, 'dishwasher', 'BreakerSpaces', voltage, watts, max_current_rating)
    end

    hpxml_bldg.cooking_ranges.each do |cooking_range|
      next if !component_ids.include?(cooking_range.id)
      next if cooking_range.fuel_type != HPXML::FuelTypeElectricity

      if cooking_range.is_induction
        load_name = 'rangeoven_induction'
      else # resistance
        load_name = 'rangeoven'
      end
      watts = cooking_range.service_feeders.select { |sf| sf.type == HPXML::ElectricPanelLoadTypeRangeOven }.map { |sf| sf.power }.sum(0.0)
      breaker_spaces += get_default_panels_value(runner, default_panels_csv_data, load_name, 'BreakerSpaces', voltage, watts, max_current_rating)
    end

    hpxml_bldg.ventilation_fans.each do |ventilation_fan|
      next if !component_ids.include?(ventilation_fan.id)

      watts = ventilation_fan.service_feeders.select { |sf| sf.type == HPXML::ElectricPanelLoadTypeMechVent }.map { |sf| sf.power }.sum(0.0)
      breaker_spaces += get_default_panels_value(runner, default_panels_csv_data, 'mechvent', 'BreakerSpaces', voltage, watts, max_current_rating)
    end

    hpxml_bldg.permanent_spas.each do |permanent_spa|
      next if !component_ids.include?(permanent_spa.heater_id)
      next if ![HPXML::HeaterTypeElectricResistance, HPXML::HeaterTypeHeatPump].include?(permanent_spa.heater_type)

      watts = permanent_spa.heater_service_feeders.select { |sf| sf.type == HPXML::ElectricPanelLoadTypePermanentSpaHeater }.map { |sf| sf.power }.sum(0.0)
      if permanent_spa.heater_type == HPXML::HeaterTypeElectricResistance
        breaker_spaces += get_default_panels_value(runner, default_panels_csv_data, 'spaheater', 'BreakerSpaces', voltage, watts, max_current_rating)
      elsif permanent_spa.heater_type == HPXML::HeaterTypeHeatPump
        breaker_spaces += get_default_panels_value(runner, default_panels_csv_data, 'spaheater_hp', 'BreakerSpaces', voltage, watts, max_current_rating)
      end
    end

    hpxml_bldg.permanent_spas.each do |permanent_spa|
      next if !component_ids.include?(permanent_spa.pump_id)

      watts = permanent_spa.pump_service_feeders.select { |sf| sf.type == HPXML::ElectricPanelLoadTypePermanentSpaPump }.map { |sf| sf.power }.sum(0.0)
      breaker_spaces += get_default_panels_value(runner, default_panels_csv_data, 'spapump', 'BreakerSpaces', voltage, watts, max_current_rating)
    end

    hpxml_bldg.pools.each do |pool|
      next if !component_ids.include?(pool.heater_id)
      next if ![HPXML::HeaterTypeElectricResistance, HPXML::HeaterTypeHeatPump].include?(pool.heater_type)

      watts = pool.heater_service_feeders.select { |sf| sf.type == HPXML::ElectricPanelLoadTypePoolHeater }.map { |sf| sf.power }.sum(0.0)
      if pool.heater_type == HPXML::HeaterTypeElectricResistance
        breaker_spaces += get_default_panels_value(runner, default_panels_csv_data, 'poolheater', 'BreakerSpaces', voltage, watts, max_current_rating)
      elsif pool.heater_type == HPXML::HeaterTypeHeatPump
        breaker_spaces += get_default_panels_value(runner, default_panels_csv_data, 'poolheater_hp', 'BreakerSpaces', voltage, watts, max_current_rating)
      end
    end

    hpxml_bldg.pools.each do |pool|
      next if !component_ids.include?(pool.pump_id)

      watts = pool.pump_service_feeders.select { |sf| sf.type == HPXML::ElectricPanelLoadTypePoolPump }.map { |sf| sf.power }.sum(0.0)
      breaker_spaces += get_default_panels_value(runner, default_panels_csv_data, 'poolpump', 'BreakerSpaces', voltage, watts, max_current_rating)
    end

    hpxml_bldg.plug_loads.each do |plug_load|
      next if plug_load.plug_load_type != HPXML::PlugLoadTypeWellPump
      next if !component_ids.include?(plug_load.id)

      watts = plug_load.service_feeders.select { |sf| sf.type == HPXML::ElectricPanelLoadTypeWellPump }.map { |sf| sf.power }.sum(0.0)
      if hpxml_bldg.building_construction.number_of_bedrooms <= 3
        breaker_spaces += get_default_panels_value(runner, default_panels_csv_data, 'wellpump_small', 'BreakerSpaces', voltage, watts, max_current_rating)
      else
        breaker_spaces += get_default_panels_value(runner, default_panels_csv_data, 'wellpump_large', 'BreakerSpaces', voltage, watts, max_current_rating)
      end
    end

    hpxml_bldg.plug_loads.each do |plug_load|
      next if plug_load.plug_load_type != HPXML::PlugLoadTypeElectricVehicleCharging
      next if !component_ids.include?(plug_load.id)

      watts = plug_load.service_feeders.select { |sf| sf.type == HPXML::ElectricPanelLoadTypeElectricVehicleCharging }.map { |sf| sf.power }.sum(0.0)
      breaker_spaces += get_default_panels_value(runner, default_panels_csv_data, 'ev_level', 'BreakerSpaces', voltage, watts, max_current_rating)
    end

    hpxml_bldg.ev_chargers.each do |ev_charger|
      next if !component_ids.include?(ev_charger.id)

      watts = ev_charger.service_feeders.select { |sf| sf.type == HPXML::ElectricPanelLoadTypeElectricVehicleCharging }.map { |sf| sf.power }.sum(0.0)
      breaker_spaces += get_default_panels_value(runner, default_panels_csv_data, 'ev_level', 'BreakerSpaces', voltage, watts, max_current_rating)
    end

    return breaker_spaces
  end

  # Get default location, lifetime model, nominal capacity/voltage, round trip efficiency, and usable fraction for a battery.
  #
  # @param has_garage [Boolean] Whether the dwelling unit has a garage
  # @return [Hash] Map of battery properties to default values
  def self.get_battery_values(has_garage)
    if has_garage
      location = HPXML::LocationGarage
    else
      location = HPXML::LocationOutside
    end
    return { location: location,
             lifetime_model: HPXML::BatteryLifetimeModelNone,
             nominal_capacity_kwh: 10.0,
             nominal_voltage: 50.0,
             round_trip_efficiency: 0.925, # Based on Tesla Powerwall round trip efficiency (new)
             usable_fraction: 0.9 } # Fraction of usable capacity to nominal capacity
  end

  # Get default lifetime model, miles/year, hours/week, nominal capacity/voltage, round trip efficiency, fraction charged at home,
  # and usable fraction for an electric vehicle and its battery.
  #
  # @return [Hash] map of EV properties to default values
  def self.get_electric_vehicle_values()
    return { battery_type: HPXML::BatteryTypeLithiumIon,
             lifetime_model: HPXML::BatteryLifetimeModelNone,
             miles_per_year: 11000,
             hours_per_week: 9.6,
             nominal_capacity_kwh: 63,
             nominal_voltage: 50.0,
             fuel_economy_combined: 0.22,
             fuel_economy_units: HPXML::UnitsKwhPerMile,
             fraction_charged_home: 0.8,
             usable_fraction: 0.8 } # Fraction of usable capacity to nominal capacity
  end

  # Gets the default values for a dehumidifier
  # Used by OS-ERI. FUTURE: Change OS-HPXML inputs to be optional and use these.
  #
  # @param capacity [Double] Capacity (pints/day)
  # @return [Hash] Relative humidity, Integrated Energy Factor (IEF)
  def self.get_dehumidifier_values(capacity)
    rh_setpoint = 0.6
    if capacity <= 25.0
      ief = 0.79
    elsif capacity <= 35.0
      ief = 0.95
    elsif capacity <= 54.0
      ief = 1.04
    elsif capacity < 75.0
      ief = 1.20
    else
      ief = 1.82
    end

    return { rh_setpoint: rh_setpoint, ief: ief }
  end

  # Gets the default values associated with occupant internal gains.
  #
  # @return [Array<Double, Double, Double, Double>] Heat gain (Btu/person/hr), Hours per day, sensible/latent fractions
  def self.get_occupancy_values()
    # ANSI/RESNET/ICC 301 - Table 4.2.2(3). Internal Gains for Reference Homes
    hrs_per_day = 16.5 # hrs/day
    sens_gains = 3716.0 # Btu/person/day
    lat_gains = 2884.0 # Btu/person/day
    tot_gains = sens_gains + lat_gains
    heat_gain = tot_gains / hrs_per_day # Btu/person/hr
    sens_frac = sens_gains / tot_gains
    lat_frac = lat_gains / tot_gains
    return heat_gain, hrs_per_day, sens_frac, lat_frac
  end

  # Gets the default residual miscellaneous electric (plug) load energy use
  # and sensible/latent fractions.
  #
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param n_occ [Double] Number of occupants in the dwelling unit
  # @param unit_type [String] Type of dwelling unit (HXPML::ResidentialTypeXXX)
  # @return [Array<Double, Double, Double>] Plug loads annual use (kWh), sensible/latent fractions
  def self.get_residual_mels_values(cfa, n_occ = nil, unit_type = nil)
    if n_occ.nil? # Asset calculation
      # ANSI/RESNET/ICC 301
      annual_kwh = 0.91 * cfa
    else # Operational calculation
      # RECS 2020
      if unit_type == HPXML::ResidentialTypeSFD
        annual_kwh = 786.9 + 241.8 * n_occ + 0.33 * cfa
      elsif unit_type == HPXML::ResidentialTypeSFA
        annual_kwh = 654.9 + 206.5 * n_occ + 0.21 * cfa
      elsif unit_type == HPXML::ResidentialTypeApartment
        annual_kwh = 706.6 + 149.3 * n_occ + 0.10 * cfa
      elsif unit_type == HPXML::ResidentialTypeManufactured
        annual_kwh = 1795.1 # No good relationship found in RECS, so just using a constant value
      end
    end
    frac_lost = 0.10
    frac_sens = (1.0 - frac_lost) * 0.95
    frac_lat = 1.0 - frac_sens - frac_lost
    return annual_kwh, frac_sens, frac_lat
  end

  # Gets the default television energy use and sensible/latent fractions.
  #
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @param n_occ [Double] Number of occupants in the dwelling unit
  # @param unit_type [String] Type of dwelling unit (HXPML::ResidentialTypeXXX)
  # @return [Array<Double, Double, Double>] Television annual use (kWh), sensible/latent fractions
  def self.get_televisions_values(cfa, nbeds, n_occ = nil, unit_type = nil)
    if n_occ.nil? # Asset calculation
      # ANSI/RESNET/ICC 301
      annual_kwh = 413.0 + 69.0 * nbeds
    else # Operational calculation
      # RECS 2020
      # Note: If we know # of televisions, we could use these better relationships instead:
      # - SFD: 67.7 + 243.4 * num_tv
      # - SFA: 13.3 + 251.3 * num_tv
      # - MF:  11.4 + 250.7 * num_tv
      # - MH:  12.6 + 287.5 * num_tv
      case unit_type
      when HPXML::ResidentialTypeSFD
        annual_kwh = 334.0 + 92.2 * n_occ + 0.06 * cfa
      when HPXML::ResidentialTypeSFA
        annual_kwh = 283.9 + 80.1 * n_occ + 0.07 * cfa
      when HPXML::ResidentialTypeApartment
        annual_kwh = 190.3 + 81.0 * n_occ + 0.11 * cfa
      when HPXML::ResidentialTypeManufactured
        annual_kwh = 99.9 + 129.6 * n_occ + 0.21 * cfa
      end
    end
    frac_lost = 0.0
    frac_sens = (1.0 - frac_lost) * 1.0
    frac_lat = 1.0 - frac_sens - frac_lost
    return annual_kwh, frac_sens, frac_lat
  end

  # Gets the default pool pump annual energy use.
  #
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @param n_occ [Double] Number of occupants in the dwelling unit
  # @param unit_type [String] Type of dwelling unit (HXPML::ResidentialTypeXXX)
  # @return [Double] Annual energy use (kWh/yr)
  def self.get_pool_pump_annual_energy(cfa, nbeds, n_occ, unit_type)
    nbeds_eq = Defaults.get_equivalent_nbeds(nbeds, n_occ, unit_type)

    return 158.6 / 0.070 * (0.5 + 0.25 * nbeds_eq / 3.0 + 0.25 * cfa / 1920.0)
  end

  # Gets the default pool heater annual energy use.
  #
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @param n_occ [Double] Number of occupants in the dwelling unit
  # @param unit_type [String] Type of dwelling unit (HXPML::ResidentialTypeXXX)
  # @param type [String] Type of heater (HPXML::HeaterTypeXXX)
  # @return [Array<String, Double>] Energy units (HPXML::UnitsXXX), annual energy use (kWh/yr or therm/yr)
  def self.get_pool_heater_annual_energy(cfa, nbeds, n_occ, unit_type, type)
    nbeds_eq = Defaults.get_equivalent_nbeds(nbeds, n_occ, unit_type)

    load_units = nil
    load_value = nil
    if [HPXML::HeaterTypeElectricResistance, HPXML::HeaterTypeHeatPump].include? type
      load_units = HPXML::UnitsKwhPerYear
      load_value = 8.3 / 0.004 * (0.5 + 0.25 * nbeds_eq / 3.0 + 0.25 * cfa / 1920.0) # kWh/yr
      if type == HPXML::HeaterTypeHeatPump
        load_value /= 5.0 # Assume seasonal COP of 5.0 per https://www.energy.gov/energysaver/heat-pump-swimming-pool-heaters
      end
    elsif type == HPXML::HeaterTypeGas
      load_units = HPXML::UnitsThermPerYear
      load_value = 3.0 / 0.014 * (0.5 + 0.25 * nbeds_eq / 3.0 + 0.25 * cfa / 1920.0) # therm/yr
    end
    return load_units, load_value
  end

  # Gets the default permanent spa pump annual energy use.
  #
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @param n_occ [Double] Number of occupants in the dwelling unit
  # @param unit_type [String] Type of dwelling unit (HXPML::ResidentialTypeXXX)
  # @return [Double] Annual energy use (kWh/yr)
  def self.get_permanent_spa_pump_annual_energy(cfa, nbeds, n_occ, unit_type)
    nbeds_eq = Defaults.get_equivalent_nbeds(nbeds, n_occ, unit_type)

    return 59.5 / 0.059 * (0.5 + 0.25 * nbeds_eq / 3.0 + 0.25 * cfa / 1920.0) # kWh/yr
  end

  # Gets the default permanent spa heater annual energy use.
  #
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @param n_occ [Double] Number of occupants in the dwelling unit
  # @param unit_type [String] Type of dwelling unit (HXPML::ResidentialTypeXXX)
  # @param type [String] Type of heater (HPXML::HeaterTypeXXX)
  # @return [Array<String, Double>] Energy units (HPXML::UnitsXXX), annual energy use (kWh/yr or therm/yr)
  def self.get_permanent_spa_heater_annual_energy(cfa, nbeds, n_occ, unit_type, type)
    nbeds_eq = Defaults.get_equivalent_nbeds(nbeds, n_occ, unit_type)

    load_units = nil
    load_value = nil
    if [HPXML::HeaterTypeElectricResistance, HPXML::HeaterTypeHeatPump].include? type
      load_units = HPXML::UnitsKwhPerYear
      load_value = 49.0 / 0.048 * (0.5 + 0.25 * nbeds_eq / 3.0 + 0.25 * cfa / 1920.0) # kWh/yr
      if type == HPXML::HeaterTypeHeatPump
        load_value /= 5.0 # Assume seasonal COP of 5.0 per https://www.energy.gov/energysaver/heat-pump-swimming-pool-heaters
      end
    elsif type == HPXML::HeaterTypeGas
      load_units = HPXML::UnitsThermPerYear
      load_value = 0.87 / 0.011 * (0.5 + 0.25 * nbeds_eq / 3.0 + 0.25 * cfa / 1920.0) # therm/yr
    end
    return load_units, load_value
  end

  # Gets the default electric vehicle charging annual energy use.
  #
  # @return [Double] Annual energy use (kWh/yr)
  def self.get_electric_vehicle_charging_annual_energy()
    ev_charger_efficiency = 0.9
    ev_battery_efficiency = 0.9

    # Use detailed vehicle model defaults
    vehicle_defaults = get_electric_vehicle_values
    kwh_per_year = vehicle_defaults[:miles_per_year] * vehicle_defaults[:fuel_economy_combined] * vehicle_defaults[:fraction_charged_home] / (ev_charger_efficiency * ev_battery_efficiency)

    return kwh_per_year.round(1)
  end

  # Gets the default well pump annual energy use.
  #
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @param n_occ [Double] Number of occupants in the dwelling unit
  # @param unit_type [String] Type of dwelling unit (HXPML::ResidentialTypeXXX)
  # @return [Double] Annual energy use (kWh/yr)
  def self.get_default_well_pump_annual_energy(cfa, nbeds, n_occ, unit_type)
    if n_occ == 0
      # Operational calculation w/ zero occupants, zero out energy use
      return 0.0
    end

    nbeds_eq = Defaults.get_equivalent_nbeds(nbeds, n_occ, unit_type)

    return 50.8 / 0.127 * (0.5 + 0.25 * nbeds_eq / 3.0 + 0.25 * cfa / 1920.0)
  end

  # Gets the default gas grill annual energy use.
  #
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @param n_occ [Double] Number of occupants in the dwelling unit
  # @param unit_type [String] Type of dwelling unit (HXPML::ResidentialTypeXXX)
  # @return [Double] Annual energy use (therm/yr)
  def self.get_gas_grill_annual_energy(cfa, nbeds, n_occ, unit_type)
    if n_occ == 0
      # Operational calculation w/ zero occupants, zero out energy use
      return 0.0
    end

    nbeds_eq = Defaults.get_equivalent_nbeds(nbeds, n_occ, unit_type)

    return 0.87 / 0.029 * (0.5 + 0.25 * nbeds_eq / 3.0 + 0.25 * cfa / 1920.0)
  end

  # Gets the default gas lighting annual energy use.
  #
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @param n_occ [Double] Number of occupants in the dwelling unit
  # @param unit_type [String] Type of dwelling unit (HXPML::ResidentialTypeXXX)
  # @return [Double] Annual energy use (therm/yr)
  def self.get_default_gas_lighting_annual_energy(cfa, nbeds, n_occ, unit_type)
    if n_occ == 0
      # Operational calculation w/ zero occupants, zero out energy use
      return 0.0
    end

    nbeds_eq = Defaults.get_equivalent_nbeds(nbeds, n_occ, unit_type)

    return 0.22 / 0.012 * (0.5 + 0.25 * nbeds_eq / 3.0 + 0.25 * cfa / 1920.0)
  end

  # Gets the default gas fireplace annual energy use.
  #
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @param n_occ [Double] Number of occupants in the dwelling unit
  # @param unit_type [String] Type of dwelling unit (HXPML::ResidentialTypeXXX)
  # @return [Double] Annual energy use (therm/yr)
  def self.get_gas_fireplace_annual_energy(cfa, nbeds, n_occ, unit_type)
    if n_occ == 0
      # Operational calculation w/ zero occupants, zero out energy use
      return 0.0
    end

    nbeds_eq = Defaults.get_equivalent_nbeds(nbeds, n_occ, unit_type)

    return 1.95 / 0.032 * (0.5 + 0.25 * nbeds_eq / 3.0 + 0.25 * cfa / 1920.0)
  end

  # Gets the default values associated with general water use internal gains.
  #
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @param n_occ [Double] Number of occupants in the dwelling unit
  # @param unit_type [String] Type of dwelling unit (HXPML::ResidentialTypeXXX)
  # @param general_water_use_usage_multiplier [Double] Usage multiplier on internal gains
  # @return [Array<Double, Double>] Sensible/latent internal gains (Btu/yr)
  def self.get_water_use_internal_gains(nbeds, n_occ, unit_type, general_water_use_usage_multiplier = 1.0)
    if n_occ == 0
      # Operational calculation w/ zero occupants, zero out internal gains
      return 0.0, 0.0
    end

    nbeds_eq = Defaults.get_equivalent_nbeds(nbeds, n_occ, unit_type)

    # ANSI/RESNET/ICC 301 - Table 4.2.2(3). Internal Gains for Reference Homes
    sens_gains = (-1227.0 - 409.0 * nbeds_eq) * general_water_use_usage_multiplier # Btu/day
    lat_gains = (1245.0 + 415.0 * nbeds_eq) * general_water_use_usage_multiplier # Btu/day
    return sens_gains * 365.0, lat_gains * 365.0
  end

  # Sets the default assumed rated ran power (W/cfm) for the HVAC system.
  #
  # @param hvac_system [HPXML::HeatingSystem or HPXML::CoolingSystem or HPXML::HeatPump] The HPXML HVAC system of interest
  # @return [nil]
  def self.set_hvac_fan_power_rated(hvac_system)
    hvac_ap = hvac_system.additional_properties
    if HVAC.is_room_dx_hvac_system(hvac_system)
      # Fan not separately modeled
      hvac_ap.fan_power_rated = 0.0
    else
      # Based on RESNET HERS Addendum 82
      psc_ducted_watts_per_cfm = 0.414 # W/cfm, PSC fan
      psc_ductless_watts_per_cfm = 0.414 # W/cfm, PSC fan
      bpm_ducted_watts_per_cfm = 0.281 # W/cfm, BPM fan
      bpm_ductless_watts_per_cfm = 0.171 # W/cfm, BPM fan
      if hvac_system.distribution_system.nil?
        hvac_ap.fan_power_rated = (hvac_system.fan_motor_type == HPXML::HVACFanMotorTypePSC) ? psc_ductless_watts_per_cfm : bpm_ductless_watts_per_cfm
      else
        hvac_ap.fan_power_rated = (hvac_system.fan_motor_type == HPXML::HVACFanMotorTypePSC) ? psc_ducted_watts_per_cfm : bpm_ducted_watts_per_cfm
      end
    end
  end

  # Sets the default control temperatures (min compressor and max backup heating
  # temperatures) for the heat pump.
  #
  # @param heat_pump [HPXML::HeatPump] The HPXML heat pump of interest
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @return [nil]
  def self.set_heat_pump_control_temperatures(heat_pump, runner)
    hp_ap = heat_pump.additional_properties

    # Gets:
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
    if hp_backup_fuel == HPXML::FuelTypeElectricity
      if (not hp_ap.hp_min_temp.nil?) && (not hp_ap.supp_max_temp.nil?) && ((hp_ap.hp_min_temp - hp_ap.supp_max_temp).abs < 5)
        if not heat_pump.backup_heating_switchover_temp.nil?
          runner.registerError('Switchover temperature should only be used for a heat pump with fossil fuel backup; use compressor lockout temperature instead.')
        else
          runner.registerError('Similar compressor/backup lockout temperatures should only be used for a heat pump with fossil fuel backup.')
        end
      end
    end
  end

  # Sets the degradation coefficient and Part Load Factor (PLF) curve for the HVAC system.
  #
  # @param hvac_system [HPXML::HeatingSystem or HPXML::CoolingSystem or HPXML::HeatPump] The HPXML HVAC system of interest
  # @return [nil]
  def self.set_hvac_degradation_coefficient(hvac_system)
    hvac_ap = hvac_system.additional_properties

    # Degradation coefficient
    if HVAC.is_room_dx_hvac_system(hvac_system)
      hvac_ap.c_d = 0.22
    else
      # Per RESNET HERS Addendum 82
      case hvac_system.compressor_type
      when HPXML::HVACCompressorTypeSingleStage, HPXML::HVACCompressorTypeTwoStage
        hvac_ap.c_d = 0.08
      when HPXML::HVACCompressorTypeVariableSpeed
        hvac_ap.c_d = 0.40
      end
    end

    # PLF curve (linear part load model)
    hvac_ap.plf_fplr_spec = [(1.0 - hvac_ap.c_d), hvac_ap.c_d, 0.0]
  end

  # Sets the ground-to-air heat pump gross rated heating/cooling cops based on COP ratios from spec sheets.
  #
  # @param heat_pump [HPXML::HeatPump] The HPXML heat pump of interest
  # @param cop_ratios [Array<Double>] Heating or cooling COP ratios for each speed
  # @param mode [Symbol] Heating or cooling
  # @return [nil]
  def self.set_ground_to_air_heat_pump_cops(heat_pump, cop_ratios, mode)
    hp_ap = heat_pump.additional_properties
    # Fan/pump adjustments calculations
    # Fan power to overcome the static pressure adjustment
    rated_fan_watts_per_cfm = 0.5 * heat_pump.fan_watts_per_cfm # Calculate rated fan power by assuming the power to overcome the ductwork is approximately 50% of the total fan power (ANSI/RESNET/ICC 301 says 0.2 W/cfm is the fan power associated with ductwork, but we don't know if that was a PSC or BPM fan)
    power_f = rated_fan_watts_per_cfm * HVAC::RatedCFMPerTon / UnitConversions.convert(1.0, 'ton', 'Btu/hr') # W per Btu/hr of capacity
    rated_pump_watts_per_ton = 30.0 # ANSI/RESNET/ICC 301, estimated pump power required to overcome the internal resistance of the ground-water heat exchanger under AHRI test conditions for a closed loop system
    power_p = rated_pump_watts_per_ton / UnitConversions.convert(1.0, 'ton', 'Btu/hr') # result is in W per Btu/hr of capacity
    if mode == :clg
      eir_rated = UnitConversions.convert(((1 - UnitConversions.convert(power_f, 'Wh', 'Btu')) / heat_pump.cooling_efficiency_eer - power_f - power_p), 'Wh', 'Btu')
      hp_ap.cool_rated_cops = []
      for i in 0..(cop_ratios.size - 1)
        hp_ap.cool_rated_cops << 1.0 / eir_rated * cop_ratios[i]
      end
    elsif mode == :htg
      eir_rated = (1 + UnitConversions.convert(power_f, 'Wh', 'Btu')) / heat_pump.heating_efficiency_cop - UnitConversions.convert(power_f + power_p, 'Wh', 'Btu')
      hp_ap.heat_rated_cops = []
      for i in 0..(cop_ratios.size - 1)
        hp_ap.heat_rated_cops << 1.0 / eir_rated * cop_ratios[i]
      end
    end
  end

  # Sets default HVAC cooling performance values.
  #
  # @param cooling_system [HPXML::CoolingSystem or HPXML::HeatPump] The HPXML cooling system or heat pump of interest
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return nil
  def self.set_hvac_cooling_performance(cooling_system, hpxml_header)
    # Calculates COP82min from SEER2 using bi-linear interpolation per RESNET MINERS Addendum 82
    def self.interpolate_seer2(seer2, eer2, seer2_array, seer2_eer2_ratio_array, cop82min_array)
      seer2_eer2_ratio = seer2 / eer2
      x1, x2 = MathTools.find_array_neighbor_values(seer2_array, seer2)
      y1, y2 = MathTools.find_array_neighbor_values(seer2_eer2_ratio_array, seer2_eer2_ratio)
      x_indexes = [x1, x2].map { |x| seer2_array.find_index(x) }
      y_indexes = [y1, y2].map { |y| seer2_eer2_ratio_array.find_index(y) }
      fx1y1 = cop82min_array[x_indexes[0]][y_indexes[0]]
      fx1y2 = cop82min_array[x_indexes[0]][y_indexes[1]]
      fx2y1 = cop82min_array[x_indexes[1]][y_indexes[0]]
      fx2y2 = cop82min_array[x_indexes[1]][y_indexes[1]]
      return MathTools.interp4(seer2, seer2_eer2_ratio, x1, x2, y1, y2, fx1y1, fx1y2, fx2y1, fx2y2)
    end

    clg_ap = cooling_system.additional_properties

    # Refrigerant charge fault coefficients per ANSI/RESNET 301-2022 Tables 4.2.2.4(1) and 4.2.2.4(5)
    if cooling_system.charge_defect_ratio.to_f <= 0
      clg_ap.cool_qgr_values = [-9.46E-01, 4.93E-02, -1.18E-03, -1.15E+00]
      clg_ap.cool_p_values = [-3.13E-01, 1.15E-02, 2.66E-03, -1.16E-01]
    else
      clg_ap.cool_qgr_values = [-1.63E-01, 1.14E-02, -2.10E-04, -1.40E-01]
      clg_ap.cool_p_values = [2.19E-01, -5.01E-03, 9.89E-04, 2.84E-01]
    end
    clg_ap.cool_ff_chg_values = [26.67, 35.0]

    # Coefficients for HVAC installation quality per RESNET HERS Addendum 82
    clg_ap.cool_cap_fflow_spec_iq = [0.718664047, 0.41797409, -0.136638137]
    clg_ap.cool_eir_fflow_spec_iq = [1.143487507, -0.13943972, -0.004047787]

    if cooling_system.is_a?(HPXML::HeatPump) && cooling_system.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir
      # Based on RESNET HERS Addendum 82
      clg_ap.cool_rated_shr_gross = 0.708
      clg_ap.cool_rated_cfm_per_ton = HVAC::RatedCFMPerTon

      case hpxml_header.ground_to_air_heat_pump_model_type
      when HPXML::AdvancedResearchGroundToAirHeatPumpModelTypeStandard
        clg_ap.cool_capacity_ratios = [1.0]

        # E+ equation fit coil coefficients generated following approach in Tang's thesis:
        # See Appendix B of  https://shareok.org/bitstream/handle/11244/10075/Tang_okstate_0664M_1318.pdf?sequence=1&isAllowed=y
        # Coefficients generated by catalog data: https://files.climatemaster.com/Genesis-GS-Series-Product-Catalog.pdf, p180
        # Data point taken as rated condition:
        # EWT: 80F EAT:80/67F, AFR: 1200cfm, WFR: 4.5gpm

        # Cooling Curves
        clg_ap.cool_cap_curve_spec = [[-5.45013866666657, 7.42301402824225, -1.43760846638838, 0.249103937703341, 0.0378875477019811]]
        clg_ap.cool_power_curve_spec = [[-4.21572180554818, 0.322682268675807, 4.56870615863483, 0.154605773589744, -0.167531037948482]]
        clg_ap.cool_sh_curve_spec = [[0.56143829895505, 18.7079597251858, -19.1482655264078, -0.138154731772664, 0.4823357726442, -0.00164644360129174]]

        cool_cop_ratios = [1.0]

      when HPXML::AdvancedResearchGroundToAirHeatPumpModelTypeExperimental
        case cooling_system.compressor_type
        when HPXML::HVACCompressorTypeSingleStage
          clg_ap.cool_capacity_ratios = [1.0]
          # Cooling Curves
          # E+ Capacity and EIR as function of temperature curves(bi-quadratic) generated using E+ HVACCurveFitTool
          # See: https://bigladdersoftware.com/epx/docs/24-2/auxiliary-programs/hvac-performance-curve-fit-tool.html#hvac-performance-curve-fit-tool
          # Catalog data from : https://files.climatemaster.com/Genesis-GS-Series-Product-Catalog.pdf, p180
          # Using E+ rated conditions:
          # Cooling: Indoor air at 67F WB, 80F DB; Entering water temperature: 85F
          clg_ap.cool_cap_ft_spec = [[0.3926140238, 0.0297981297, 0.0000000582, 0.0123906803, -0.0003014284, -0.0001113698]]
          clg_ap.cool_eir_ft_spec = [[1.1828664909, -0.0450835550, 0.0009273315, 0.0056194113, 0.0006683467, -0.0007256237]]
          clg_ap.cool_cap_fflow_spec = [[0.5068, 0.8099, -0.3165]]
          clg_ap.cool_eir_fflow_spec = [[2.0184, -1.6182, 0.5789]]
          clg_ap.cool_cap_fwf_spec = [[1.0, 0.0, 0.0]]
          clg_ap.cool_eir_fwf_spec = [[1.0, 0.0, 0.0]]
          cool_cop_ratios = [1.0]
        when HPXML::HVACCompressorTypeTwoStage
          clg_ap.cool_capacity_ratios = [0.7353, 1.0]
          # Cooling Curves
          # E+ Capacity and EIR as function of temperature curves(bi-quadratic) generated using E+ HVACCurveFitTool
          # See: https://bigladdersoftware.com/epx/docs/24-2/auxiliary-programs/hvac-performance-curve-fit-tool.html#hvac-performance-curve-fit-tool
          # Catalog data from ClimateMaster residential tranquility 30 premier two-stage series Model SE036: https://files.climatemaster.com/RP3001-Residential-SE-Product-Catalog.pdf
          # Using E+ rated conditions:
          # Cooling: Indoor air at 67F WB, 80F DB; Entering water temperature: 85F
          clg_ap.cool_cap_ft_spec = [[0.4091067504, 0.0387481208, -0.0000003491, 0.0039166842, -0.0001299475, -0.0002883229],
                                     [0.4423161030, 0.0346534683, 0.0000043691, 0.0046060534, -0.0001393465, -0.0002316000]]
          clg_ap.cool_eir_ft_spec = [[1.0242580586, -0.0549907581, 0.0017735749, 0.0186562274, 0.0008900852, -0.0016973518],
                                     [1.0763155558, -0.0396246303, 0.0010677382, 0.0074160145, 0.0006781567, -0.0009009811]]
          clg_ap.cool_cap_fflow_spec = [[0.9064, 0.0793, 0.0143],
                                        [0.8551, 0.1688, -0.0238]]
          clg_ap.cool_eir_fflow_spec = [[0.7931, 0.2623, -0.0552],
                                        [0.8241, 0.1523, 0.0234]]
          clg_ap.cool_cap_fwf_spec = [[0.8387, 0.2903, -0.129],
                                      [0.815, 0.325, -0.14]]
          clg_ap.cool_eir_fwf_spec = [[1.7131, -1.3055, 0.5924],
                                      [1.5872, -1.055, 0.4678]]

          # Catalog data from ClimateMaster residential tranquility 30 premier two-stage series Model SE036: https://files.climatemaster.com/RP3001-Residential-SE-Product-Catalog.pdf
          cool_cop_ratios = [1.102827763, 1.0]
        when HPXML::HVACCompressorTypeVariableSpeed
          clg_ap.cool_capacity_ratios = [0.4802, 1.0]
          # Cooling Curves
          # E+ Capacity and EIR as function of temperature curves(bi-quadratic) generated using E+ HVACCurveFitTool
          # See: https://bigladdersoftware.com/epx/docs/24-2/auxiliary-programs/hvac-performance-curve-fit-tool.html#hvac-performance-curve-fit-tool
          # Catalog data from WaterFurnace 7 Series 700A11: https://www.waterfurnace.com/literature/7series/SDW7-0018W.pdf
          # Using E+ rated conditions:
          # Cooling: Indoor air at 67F WB, 80F DB; Entering water temperature: 85F
          clg_ap.cool_cap_ft_spec = [[1.3397293008, -0.0474800765, 0.0021636831, 0.0055773535, -0.0002350114, -0.0002458509],
                                     [1.2143128834, -0.0459226877, 0.0020331628, 0.0086998093, -0.0002669140, -0.0001763187]]
          clg_ap.cool_eir_ft_spec = [[-0.0049682877, 0.0554193005, -0.0015790347, -0.0010670650, 0.0011493038, -0.0008236210],
                                     [0.0569949694, 0.0527820535, -0.0015763180, 0.0077339260, 0.0008175629, -0.0007157989]]
          clg_ap.cool_cap_fflow_spec = [[1.1092, -0.5299, 0.4312],
                                        [0.9216, -0.1021, 0.1874]]
          clg_ap.cool_eir_fflow_spec = [[2.2938, -2.2648, 0.9631],
                                        [1.9175, -1.374, 0.4646]]
          clg_ap.cool_cap_fwf_spec = [[1.0386, -0.2037, 0.1651],
                                      [0.8606, 0.2687, -0.1293]]
          clg_ap.cool_eir_fwf_spec = [[1.066, 0.052, -0.118],
                                      [1.2961, -0.4762, 0.18]]

          # Catalog data from WaterFurnace 7 Series 700A11: https://www.waterfurnace.com/literature/7series/SDW7-0018W.pdf
          cool_cop_ratios = [1.059467645, 1.0]
        end
      end

      set_ground_to_air_heat_pump_cops(cooling_system, cool_cop_ratios, :clg)
      return
    end

    # Based on RESNET HERS Addendum 82
    clg_ap.cool_cap_fflow_spec = clg_ap.cool_cap_fflow_spec_iq
    clg_ap.cool_eir_fflow_spec = clg_ap.cool_eir_fflow_spec_iq
    set_hvac_degradation_coefficient(cooling_system)

    if HVAC.is_room_dx_hvac_system(cooling_system)
      clg_ap.cool_capacity_ratios = [1.0]
      clg_ap.cool_cap_ft_spec = [3.68637657, -0.098352478, 0.000956357, 0.005838141, -0.0000127, -0.000131702]
      clg_ap.cool_eir_ft_spec = [-3.437356399, 0.136656369, -0.001049231, -0.0079378, 0.000185435, -0.0001441]
      clg_ap.cool_rated_cfm_per_ton = 312.0 # medium speed
      clg_ap.cool_cap_fflow_spec = [1.0, 0.0, 0.0]
      clg_ap.cool_eir_fflow_spec = [1.0, 0.0, 0.0]
      clg_ap.cool_rated_cops = [UnitConversions.convert(cooling_system.cooling_efficiency_ceer, 'Btu/hr', 'W')]
      clg_ap.cool_rated_shr_gross = 0.65
      return
    end

    seer2 = cooling_system.cooling_efficiency_seer2
    eer2 = cooling_system.cooling_efficiency_eer2
    compressor_type = cooling_system.compressor_type

    clg_ap.cop95full = UnitConversions.convert(cooling_system.cooling_efficiency_eer2, 'Btu/hr', 'W')

    # Based on RESNET HERS Addendum 82
    case compressor_type
    when HPXML::HVACCompressorTypeSingleStage
      clg_ap.qm95full = 0.936 # Q95full/Q82full

      clg_ap.cop82full = UnitConversions.convert(seer2 / (1.0 - 0.5 * clg_ap.c_d), 'Btu/hr', 'W')

      clg_ap.cool_capacity_ratios = [1.0]

    when HPXML::HVACCompressorTypeTwoStage
      clg_ap.qm95full = 0.936 # Q95full/Q82full
      clg_ap.eirm95full = 1.244 # (P95full/Q95full)/(P82full/Q82full)
      clg_ap.qrcmin = 0.728 # Qmin/Qfull for all temperatures

      seer2_array = [6.0, 22.0]
      seer2_eer2_ratio_array = [1.000, 2.400]
      cop82min_array = [[1.777, 2.105],
                        [6.517, 7.717]]
      clg_ap.cop82min = interpolate_seer2(seer2, eer2, seer2_array, seer2_eer2_ratio_array, cop82min_array)

      clg_ap.cop95min = clg_ap.cop82min / clg_ap.eirm95full
      clg_ap.cop82full = clg_ap.cop95full * clg_ap.eirm95full

      clg_ap.cool_capacity_ratios = [clg_ap.qrcmin, 1.0]

    when HPXML::HVACCompressorTypeVariableSpeed
      clg_ap.qr95full = 0.934 # Q95full/Q95max
      clg_ap.qm95max = 0.940 # Q95max/Q82max
      clg_ap.qm95min = 0.948 # Q95min/Q82min
      clg_ap.eirr95full = 0.928 # (P95full/Q95full)/(P95max/Q95max)
      clg_ap.eirm95max = 1.326 # (P95max/Q95max)/(P82max/Q82max)
      clg_ap.eirm95min = 1.315 # (P95min/Q95min)/(P82min/Q82min)

      seer2_array = [14.0, 24.5, 35.0]
      seer2_eer2_ratio_array = [1.000, 1.747, 2.120, 2.307, 2.400]
      cop82min_array = [[4.047, 6.175, 14.240, 19.508, 23.029],
                        [7.061, 10.289, 23.262, 31.842, 37.513],
                        [10.058, 14.053, 30.962, 42.388, 49.863]]
      clg_ap.cop82min = interpolate_seer2(seer2, eer2, seer2_array, seer2_eer2_ratio_array, cop82min_array)

      clg_ap.cop95max = clg_ap.cop95full * clg_ap.eirr95full
      clg_ap.cop95min = clg_ap.cop82min / clg_ap.eirm95min
      clg_ap.cop82max = clg_ap.cop95max * clg_ap.eirm95max
      clg_ap.cop82full = MathTools.interp2(clg_ap.cop95full, clg_ap.cop95min, clg_ap.cop95max, clg_ap.cop82min, clg_ap.cop82max)
      clg_ap.qr95min = 1.0 / clg_ap.qr95full * (0.029 + 0.369 * clg_ap.cop82max / clg_ap.cop82min) # Q95min/Q95max

      clg_ap.cool_capacity_ratios = [clg_ap.qr95min, 1.0, 1.0 / clg_ap.qr95full]
    end

    clg_ap.cool_rated_cfm_per_ton = HVAC::RatedCFMPerTon
    clg_ap.cool_cap_ft_spec = [3.717717741, -0.09918866, 0.000964488, 0.005887776, -0.000012808, -0.000132822]
    clg_ap.cool_eir_ft_spec = [-3.400341169, 0.135184783, -0.001037932, -0.007852322, 0.000183438, -0.000142548]
    clg_ap.cool_rated_shr_gross = 0.708
  end

  # Sets heating performance factors based on RESNET HERS Addendum 82.
  #
  #
  # @param heating_system [HPXML::HeatingSystem or HPXML::HeatPump] The HPXML heating system or heat pump of interest
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return nil
  def self.set_hvac_heating_performance(heating_system, hpxml_header)
    # Calculates COP47full from HSPF2 using bi-linear interpolation per RESNET MINERS Addendum 82
    def self.interpolate_hspf2(hspf2, qm17full, hspf2_array, qm17full_array, cop47full_array)
      x1, x2 = MathTools.find_array_neighbor_values(hspf2_array, hspf2)
      y1, y2 = MathTools.find_array_neighbor_values(qm17full_array, qm17full)
      x_indexes = [x1, x2].map { |x| hspf2_array.find_index(x) }
      y_indexes = [y1, y2].map { |y| qm17full_array.find_index(y) }
      fx1y1 = cop47full_array[x_indexes[0]][y_indexes[0]]
      fx1y2 = cop47full_array[x_indexes[0]][y_indexes[1]]
      fx2y1 = cop47full_array[x_indexes[1]][y_indexes[0]]
      fx2y2 = cop47full_array[x_indexes[1]][y_indexes[1]]
      return MathTools.interp4(hspf2, qm17full, x1, x2, y1, y2, fx1y1, fx1y2, fx2y1, fx2y2)
    end

    htg_ap = heating_system.additional_properties

    # Refrigerant charge fault coefficients per ANSI/RESNET 301-2022 Tables 4.2.2.4(2) and 4.2.2.4(6)
    # Note: We added a zero term to make cooling and heating calculations consistent
    if heating_system.charge_defect_ratio.to_f <= 0
      htg_ap.heat_qgr_values = [-3.39E-02, 0.0, 2.03E-02, -2.62E+00]
      htg_ap.heat_p_values = [6.16E-02, 0.0, 4.46E-03, -2.60E-01]
    else
      htg_ap.heat_qgr_values = [-2.95E-03, 0.0, 7.38E-04, -6.41E-03]
      htg_ap.heat_p_values = [-5.94E-01, 0.0, 1.59E-02, 1.89E+00]
    end
    htg_ap.heat_ff_chg_values = [0.0, 8.33] # Add a zero term to combine cooling and heating calculation

    # Coefficients for HVAC installation quality per RESNET HERS Addendum 82
    htg_ap.heat_cap_fflow_spec_iq = [0.694045465, 0.474207981, -0.168253446]
    htg_ap.heat_eir_fflow_spec_iq = [2.185418751, -1.942827919, 0.757409168]

    if heating_system.is_a?(HPXML::HeatPump) && heating_system.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir
      # Based on RESNET HERS Addendum 82
      htg_ap.heat_rated_cfm_per_ton = HVAC::RatedCFMPerTon

      case hpxml_header.ground_to_air_heat_pump_model_type
      when HPXML::AdvancedResearchGroundToAirHeatPumpModelTypeStandard
        htg_ap.heat_capacity_ratios = [1.0]
        # E+ equation fit coil coefficients following approach from Tang's thesis:
        # See Appendix B Figure B.3 of  https://shareok.org/bitstream/handle/11244/10075/Tang_okstate_0664M_1318.pdf?sequence=1&isAllowed=y
        # Coefficients generated by catalog data: https://www.climatemaster.com/download/18.274be999165850ccd5b5b73/1535543867815/lc377-climatemaster-commercial-tranquility-20-single-stage-ts-series-water-source-heat-pump-submittal-set.pdf
        # Data point taken as rated condition:
        # EWT: 60F EAT: 70F AFR: 1200 cfm, WFR: 4.5 gpm

        # Heating Curves
        htg_ap.heat_cap_curve_spec = [[-3.75031847962047, -2.18062040443483, 6.8363364819032, 0.188376814356582, 0.0869274802923634]]
        htg_ap.heat_power_curve_spec = [[-8.4754723813072, 8.10952801956388, 1.38771494628738, -0.33766445915032, 0.0223085217874051]]
        heat_cop_ratios = [1.0]
      when HPXML::AdvancedResearchGroundToAirHeatPumpModelTypeExperimental
        case heating_system.compressor_type
        when HPXML::HVACCompressorTypeSingleStage
          htg_ap.heat_capacity_ratios = [1.0]
          # Heating Curves
          # E+ Capacity and EIR as function of temperature curves(bi-quadratic) generated using E+ HVACCurveFitTool
          # See: https://bigladdersoftware.com/epx/docs/24-2/auxiliary-programs/hvac-performance-curve-fit-tool.html#hvac-performance-curve-fit-tool
          # Catalog data from : https://files.climatemaster.com/Genesis-GS-Series-Product-Catalog.pdf, p180
          # Using E+ rated conditions:
          # Heating: Indoor air at 70F DB; Entering water temperature: 70F
          htg_ap.heat_cap_ft_spec = [[0.7353127278, -0.0035056759, -0.0000439615, 0.0204411095, -0.0000320781, -0.0001322685]]
          htg_ap.heat_eir_ft_spec = [[0.6273820540, 0.0124891750, 0.0012720188, -0.0151581268, 0.0004164343, -0.0007259611]]
          htg_ap.heat_cap_fflow_spec = [[0.7594, 0.3642, -0.1234]]
          htg_ap.heat_eir_fflow_spec = [[2.796, -3.0886, 1.3858]]
          htg_ap.heat_cap_fwf_spec = [[1.0, 0.0, 0.0]]
          htg_ap.heat_eir_fwf_spec = [[1.0, 0.0, 0.0]]
          heat_cop_ratios = [1.0]
        when HPXML::HVACCompressorTypeTwoStage
          htg_ap.heat_capacity_ratios = [0.7374, 1.0]
          # Heating Curves
          # E+ Capacity and EIR as function of temperature curves(bi-quadratic) generated using E+ HVACCurveFitTool
          # See: https://bigladdersoftware.com/epx/docs/24-2/auxiliary-programs/hvac-performance-curve-fit-tool.html#hvac-performance-curve-fit-tool
          # Catalog data from ClimateMaster residential tranquility 30 premier two-stage series Model SE036: https://files.climatemaster.com/RP3001-Residential-SE-Product-Catalog.pdf
          # Using E+ rated conditions:
          # Heating: Indoor air at 70F DB; Entering water temperature: 70F
          htg_ap.heat_cap_ft_spec = [[0.6523957849, -0.0011387222, 0.0000000000, 0.0191295958, -0.0000411533, -0.0000311030],
                                     [0.6668920089, -0.0015817909, 0.0000027692, 0.0189198107, -0.0000372655, -0.0000393615]]
          htg_ap.heat_eir_ft_spec = [[0.8057698794, 0.0316014252, 0.0000380531, -0.0228123504, 0.0004336379, -0.0004522084],
                                     [0.8046419585, 0.0233384227, 0.0000376912, -0.0170224134, 0.0003382804, -0.0002368130]]
          htg_ap.heat_cap_fflow_spec = [[0.8649, 0.1112, 0.0238],
                                        [0.8264, 0.1593, 0.0143]]
          htg_ap.heat_eir_fflow_spec = [[1.2006, -0.1943, -0.0062],
                                        [1.2568, -0.2856, 0.0288]]
          htg_ap.heat_cap_fwf_spec = [[0.7112, 0.5027, -0.2139],
                                      [0.769, 0.399, -0.168]]
          htg_ap.heat_eir_fwf_spec = [[1.3457, -0.6658, 0.3201],
                                      [1.1679, -0.3215, 0.1535]]
          # Catalog data from ClimateMaster residential tranquility 30 premier two-stage series Model SE036: https://files.climatemaster.com/RP3001-Residential-SE-Product-Catalog.pdf
          heat_cop_ratios = [1.161791639, 1.0]
        when HPXML::HVACCompressorTypeVariableSpeed
          htg_ap.heat_capacity_ratios = [0.4473, 1.0]
          # Heating Curves
          # E+ Capacity and EIR as function of temperature curves(bi-quadratic) generated using E+ HVACCurveFitTool
          # See: https://bigladdersoftware.com/epx/docs/24-2/auxiliary-programs/hvac-performance-curve-fit-tool.html#hvac-performance-curve-fit-tool
          # Catalog data from WaterFurnace 7 Series 700A11: https://www.waterfurnace.com/literature/7series/SDW7-0018W.pdf
          # Using E+ rated conditions:
          # Heating: Indoor air at 70F DB; Entering water temperature: 70F
          htg_ap.heat_cap_ft_spec = [[0.6955336002, -0.0028528869, -0.0000005012, 0.0201138223, -0.0000590002, -0.0000749701],
                                     [0.6975737864, -0.0028810803, -0.0000005015, 0.0206468583, -0.0000891526, -0.0000733087]]
          htg_ap.heat_eir_ft_spec = [[0.8755777079, 0.0309984461, 0.0001099592, -0.0174543325, 0.0001819203, -0.0004948405],
                                     [0.7627294076, 0.0273612308, 0.0001023412, -0.0145638547, 0.0001886431, -0.0003647958]]
          htg_ap.heat_cap_fflow_spec = [[0.8676, 0.1122, 0.0195],
                                        [0.9498, -0.0298, 0.0812]]
          htg_ap.heat_eir_fflow_spec = [[1.4426, -0.4465, 0.0064],
                                        [1.1158, 0.282, -0.4071]]
          htg_ap.heat_cap_fwf_spec = [[0.8364, 0.197, -0.0333],
                                      [0.727, 0.55, -0.277]]
          htg_ap.heat_eir_fwf_spec = [[1.3491, -0.7744, 0.4253],
                                      [1.0833, -0.1351, 0.0517]]
          # Catalog data from WaterFurnace 7 Series 700A11: https://www.waterfurnace.com/literature/7series/SDW7-0018W.pdf
          heat_cop_ratios = [1.15012987, 1.0]
        end
      end

      set_ground_to_air_heat_pump_cops(heating_system, heat_cop_ratios, :htg)
      return
    end

    htg_ap.heat_cap_fflow_spec = htg_ap.heat_cap_fflow_spec_iq
    htg_ap.heat_eir_fflow_spec = htg_ap.heat_eir_fflow_spec_iq

    set_hvac_degradation_coefficient(heating_system)

    # Default heating capacity maintenance from 17F to 47F
    htg_ap.qm17full = nil
    if (heating_system.heating_capacity_17F.to_f > 0) && (heating_system.heating_capacity > 0)
      htg_ap.qm17full = heating_system.heating_capacity_17F / heating_system.heating_capacity
    elsif not heating_system.heating_capacity_fraction_17F.nil?
      htg_ap.qm17full = heating_system.heating_capacity_fraction_17F
    elsif not heating_system.heating_detailed_performance_data.empty?
      nom_dp_47f = heating_system.heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == 47 && dp.capacity_description == HPXML::CapacityDescriptionNominal }
      nom_dp_17f = heating_system.heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == 17 && dp.capacity_description == HPXML::CapacityDescriptionNominal }
      if (not nom_dp_47f.nil?) && (not nom_dp_17f.nil?)
        if (nom_dp_17f.capacity.to_f > 0) && (nom_dp_47f.capacity.to_f > 0)
          htg_ap.qm17full = nom_dp_17f.capacity / nom_dp_47f.capacity
        elsif nom_dp_17f.capacity_fraction_of_nominal.to_f > 0
          htg_ap.qm17full = nom_dp_17f.capacity_fraction_of_nominal
        end
      end
    end
    if htg_ap.qm17full.nil?
      case heating_system.compressor_type
      when HPXML::HVACCompressorTypeSingleStage, HPXML::HVACCompressorTypeTwoStage
        htg_ap.qm17full = 0.59 # Approximately based on Cutler curves
      when HPXML::HVACCompressorTypeVariableSpeed
        # Default maximum capacity maintenance based on NEEP data for all var speed heat pump types, if not provided
        htg_ap.qm17full = (0.0329 * HVAC.calc_hspf_from_hspf2(heating_system) + 0.3996).round(4)
      end
    end

    if HVAC.is_room_dx_hvac_system(heating_system)
      htg_ap.heat_capacity_ratios = [1.0]

      # Calculate cap ft curve
      # Biquadratic: capacity multiplier = a + b*IAT + c*IAT^2 + d*OAT + e*OAT^2 + f*IAT*OAT
      # Derive coefficients from user input for capacity fraction at 17F.
      x_A = 17.0
      y_A = htg_ap.qm17full
      x_B = HVAC::AirSourceHeatRatedODB
      y_B = 1.0
      iat_slope = -0.002303414
      iat_intercept = 0.18417308
      oat_slope = (y_B - y_A) / (x_B - x_A)
      oat_intercept = y_A - (x_A * oat_slope)
      htg_ap.heat_cap_ft_spec = oat_intercept + iat_intercept, iat_slope, 0, oat_slope, 0, 0

      htg_ap.heat_eir_ft_spec = [0.718398423, 0.003498178, 0.000142202, -0.005724331, 0.00014085, -0.000215321]
      htg_ap.heat_rated_cfm_per_ton = HVAC::RatedCFMPerTon
      return
    end

    hspf2 = heating_system.heating_efficiency_hspf2
    compressor_type = heating_system.compressor_type

    # Based on RESNET HERS Addendum 82
    case compressor_type
    when HPXML::HVACCompressorTypeSingleStage
      htg_ap.eirm17full = 1.356 # (P17full/Q17full)/(P47full/Q47full)

      hspf2_array = [5.0, 6.5, 8.0, 9.5, 11.0]
      qm17full_array = [0.5, 0.533, 0.6, 0.7333, 1.0]
      cop47full_array = [[1.971, 1.963, 1.946, 1.915, 1.904],
                         [2.844, 2.801, 2.720, 2.589, 2.498],
                         [3.933, 3.819, 3.622, 3.318, 3.102],
                         [5.327, 5.085, 4.683, 4.111, 3.718],
                         [7.178, 6.699, 5.951, 4.975, 4.345]]
      htg_ap.cop47full = interpolate_hspf2(hspf2, htg_ap.qm17full, hspf2_array, qm17full_array, cop47full_array)

      htg_ap.heat_capacity_ratios = [1.0]

    when HPXML::HVACCompressorTypeTwoStage
      htg_ap.eirm17full = 1.356 # (P17full/Q17full)/(P47full/Q47full)
      htg_ap.qrhmin = 0.712 # Qmin/Qfull
      htg_ap.eirrhmin = 0.850 # (Pmin/Qmin)/(Pfull/Qfull)

      hspf2_array = [5.0, 6.5, 8.0, 9.5, 11.0]
      qm17full_array = [0.5, 0.533, 0.6, 0.7333, 1.0]
      cop47full_array = [[1.794, 1.779, 1.757, 1.720, 1.659],
                         [2.592, 2.540, 2.456, 2.325, 2.176],
                         [3.583, 3.464, 3.270, 2.980, 2.703],
                         [4.852, 4.611, 4.227, 3.691, 3.239],
                         [6.536, 6.073, 5.371, 4.467, 3.785]]
      htg_ap.cop47full = interpolate_hspf2(hspf2, htg_ap.qm17full, hspf2_array, qm17full_array, cop47full_array)

      htg_ap.heat_capacity_ratios = [htg_ap.qrhmin, 1.0]

    when HPXML::HVACCompressorTypeVariableSpeed
      htg_ap.qr47full = 0.908 # Q47full/Q47max
      htg_ap.qr47min = 0.272 # Q47min/Q47max
      htg_ap.qr17full = 0.817 # Q17full/Q17max
      htg_ap.qr17min = 0.341 # Q17min/Q17max
      htg_ap.qm5max = 0.866 # Q5max/Q17max
      htg_ap.qr5full = 0.988 # Q5full/Q5max
      htg_ap.qr5min = 0.321 # Q5min/Q5max
      htg_ap.qmslopeLCTmax = -0.025 # (1.0 - Q5max/QLCTmax)/(5 - LCT)
      htg_ap.qmslopeLCTmin = -0.024 # (1.0 - Q5min/QLCTmin)/(5 - LCT)
      htg_ap.eirr47full = 0.939 # (P47full/Q47full)/(P47max/Q47max)
      htg_ap.eirr47min = 0.730 # (P47min/Q47min)/(P47max/Q47max)
      htg_ap.eirm17full = 1.351 # (P17full/Q17full)/(P47full/Q47full)
      htg_ap.eirr17full = 0.902 # (P17full/Q17full)/(P17max/Q17max)
      htg_ap.eirr17min = 0.798 # (P17min/Q17min)/(P17max/Q17max)
      htg_ap.eirm5max = 1.164 # (P5max/Q5max)/(P17max/Q17max)
      htg_ap.eirr5full = 1.000 # (P5full/Q5full)/(P5max/Q5max)
      htg_ap.eirr5min = 0.866 # (P5min/Q5min)/(P5max/Q5max)
      htg_ap.eirmslopeLCTmax = 0.012 # (1.0 - (PLCTmax/QLCTmax)/(P5max/Q5max))/(5 - LCT)
      htg_ap.eirmslopeLCTmin = 0.012 # (1.0 - (PLCTmin/QLCTmin)/(P5min/Q5min))/(5 - LCT)

      hspf2_array = [7.0, 9.25, 11.5, 13.75, 16.0]
      qm17full_array = [0.5, 0.54, 0.62, 0.78, 1.10]
      cop47full_array = [[2.762, 2.696, 2.579, 2.467, 2.345],
                         [4.149, 3.941, 3.627, 3.305, 3.091],
                         [5.934, 5.490, 4.821, 4.167, 3.834],
                         [8.392, 7.463, 6.190, 5.054, 4.573],
                         [11.948, 10.060, 7.779, 5.967, 5.307]]
      htg_ap.cop47full = interpolate_hspf2(hspf2, htg_ap.qm17full, hspf2_array, qm17full_array, cop47full_array)

      htg_ap.heat_capacity_ratios = [htg_ap.qr47min / htg_ap.qr47full, 1.0, 1.0 / htg_ap.qr47full]
    end

    htg_ap.heat_rated_cfm_per_ton = HVAC::RatedCFMPerTon
    htg_ap.heat_cap_ft_spec = [0.568706266, -0.000747282, -0.0000103432, 0.00945408, 0.000050812, -0.00000677828]
    htg_ap.heat_eir_ft_spec = [0.722917608, 0.003520184, 0.000143097, -0.005760341, 0.000141736, -0.000216676]
  end

  # Adds default heat pump detailed performance datapoints based on RESNET HERS Addendum 82.
  #
  # @param heat_pump [HPXML::HeatPump] The HPXML heat pump of interest
  # @return [nil]
  def self.set_detailed_performance_data_heating(heat_pump)
    hp_ap = heat_pump.additional_properties

    capacity47full = heat_pump.heating_capacity
    capacity17full = heat_pump.heating_capacity_17F
    lct = hp_ap.hp_min_temp

    case heat_pump.compressor_type
    when HPXML::HVACCompressorTypeSingleStage
      # COPs @ 17F
      cop17full = hp_ap.cop47full / hp_ap.eirm17full

      # Capacities @ 5F
      if capacity47full > 0
        capacity5full = MathTools.interp2(5.0, 17.0, 47.0, capacity17full, capacity47full)
      else
        capacity5full = 0.0
      end

      # COPs @ 5F
      if capacity5full > 0
        cop5full = capacity5full / MathTools.interp2(5.0, 17.0, 47.0, capacity17full / cop17full, capacity47full / hp_ap.cop47full)
      else
        cop5full = MathTools.interp2(5.0, 17.0, 47.0, cop17full, hp_ap.cop47full) # Arbitrary
      end

    when HPXML::HVACCompressorTypeTwoStage
      # Capacities @ 47F
      capacity47min = capacity47full * hp_ap.heat_capacity_ratios[0]

      # COPs @ 47F
      cop47min = hp_ap.cop47full / hp_ap.eirrhmin

      # Capacities @ 17F
      capacity17min = capacity17full * hp_ap.qrhmin

      # COPs @ 17F
      cop17full = hp_ap.cop47full / hp_ap.eirm17full
      cop17min = cop17full / hp_ap.eirrhmin

      # Capacities @ 5F
      if capacity47full > 0
        capacity5full = MathTools.interp2(5.0, 17.0, 47.0, capacity17full, capacity47full)
        capacity5min = MathTools.interp2(5.0, 17.0, 47.0, capacity17min, capacity47min)
      else
        capacity5full = 0.0
        capacity5min = 0.0
      end

      # COPs @ 5F
      if capacity5full > 0
        cop5full = capacity5full / MathTools.interp2(5.0, 17.0, 47.0, capacity17full / cop17full, capacity47full / hp_ap.cop47full)
      else
        cop5full = MathTools.interp2(5.0, 17.0, 47.0, cop17full, hp_ap.cop47full) # Arbitrary
      end
      if capacity5min > 0
        cop5min = capacity5min / MathTools.interp2(5.0, 17.0, 47.0, capacity17min / cop17min, capacity47min / cop47min)
      else
        cop5min = MathTools.interp2(5.0, 17.0, 47.0, cop17min, cop47min) # Arbitrary
      end

    when HPXML::HVACCompressorTypeVariableSpeed
      # Capacities @ 47F
      capacity47max = capacity47full * hp_ap.heat_capacity_ratios[-1]
      capacity47min = capacity47full * hp_ap.heat_capacity_ratios[0]

      # COPs @ 47F
      cop47max = hp_ap.cop47full * hp_ap.eirr47full
      cop47min = cop47max / hp_ap.eirr47min

      # Capacities @ 17F
      capacity17max = capacity17full / hp_ap.qr17full
      capacity17min = capacity17full * hp_ap.qr17min / hp_ap.qr17full

      # COPs @ 17F
      cop17full = hp_ap.cop47full / hp_ap.eirm17full
      cop17max = cop17full * hp_ap.eirr17full
      cop17min = cop17max / hp_ap.eirr17min

      # Capacities @ 5F
      capacity5max = capacity17max * hp_ap.qm5max
      capacity5full = capacity5max * hp_ap.qr5full
      capacity5min = capacity5full * hp_ap.qr5min / hp_ap.qr5full

      # COPs @ 5F
      cop5max = cop17max / hp_ap.eirm5max
      cop5full = cop5max / hp_ap.eirr5full
      cop5min = cop5max / hp_ap.eirr5min

      if lct < 5
        # Capacities @ LCT
        capacityLCTmax = capacity5max * (1.0 / (1.0 - hp_ap.qmslopeLCTmax * (5.0 - lct)))
        capacityLCTmin = capacity5min * (1.0 / (1.0 - hp_ap.qmslopeLCTmin * (5.0 - lct)))
        if capacityLCTmin > 0
          capacityLCTfull = MathTools.interp2(capacity5full, capacity5min, capacity5max, capacityLCTmin, capacityLCTmax)
        else
          capacityLCTfull = 0.0
        end

        # COPs @ LCT
        copLCTmin = cop5min * (1.0 - hp_ap.eirmslopeLCTmin * (5.0 - lct))
        copLCTmax = cop5max * (1.0 - hp_ap.eirmslopeLCTmax * (5.0 - lct))
        if capacityLCTfull > 0
          copLCTfull = capacityLCTfull / MathTools.interp2(capacity5full / cop5full, capacity5min / cop5min, capacity5max / cop5max, capacityLCTmin / copLCTmin, capacityLCTmax / copLCTmax)
        else
          copLCTfull = MathTools.interp2(lct, 5.0, 17.0, cop5min, cop17min) # Arbitrary
        end
      end
    end

    # Add detailed performance data
    detailed_performance_data = heat_pump.heating_detailed_performance_data

    # 47F, maximum speed
    detailed_performance_data.add(capacity: Float(capacity47max.round),
                                  efficiency_cop: cop47max.round(4),
                                  capacity_description: HPXML::CapacityDescriptionMaximum,
                                  outdoor_temperature: 47,
                                  isdefaulted: true) unless capacity47max.nil?
    # 47F, nominal speed
    detailed_performance_data.add(capacity: Float(capacity47full.round),
                                  efficiency_cop: hp_ap.cop47full.round(4),
                                  capacity_description: HPXML::CapacityDescriptionNominal,
                                  outdoor_temperature: 47,
                                  isdefaulted: true)
    # 47F, minimum speed
    detailed_performance_data.add(capacity: Float(capacity47min.round),
                                  efficiency_cop: cop47min.round(4),
                                  capacity_description: HPXML::CapacityDescriptionMinimum,
                                  outdoor_temperature: 47,
                                  isdefaulted: true) unless capacity47min.nil?
    # 17F, maximum speed
    detailed_performance_data.add(capacity: Float(capacity17max.round),
                                  efficiency_cop: cop17max.round(4),
                                  capacity_description: HPXML::CapacityDescriptionMaximum,
                                  outdoor_temperature: 17,
                                  isdefaulted: true) unless capacity17max.nil?
    # 17F, nominal speed
    detailed_performance_data.add(capacity: Float(capacity17full.round),
                                  efficiency_cop: cop17full.round(4),
                                  capacity_description: HPXML::CapacityDescriptionNominal,
                                  outdoor_temperature: 17,
                                  isdefaulted: true)
    # 17F, minimum speed
    detailed_performance_data.add(capacity: Float(capacity17min.round),
                                  efficiency_cop: cop17min.round(4),
                                  capacity_description: HPXML::CapacityDescriptionMinimum,
                                  outdoor_temperature: 17,
                                  isdefaulted: true) unless capacity17min.nil?
    # 5F, maximum speed
    detailed_performance_data.add(capacity: Float(capacity5max.round),
                                  efficiency_cop: cop5max.round(4),
                                  capacity_description: HPXML::CapacityDescriptionMaximum,
                                  outdoor_temperature: 5,
                                  isdefaulted: true) unless capacity5max.nil?
    # 5F, nominal speed
    detailed_performance_data.add(capacity: Float(capacity5full.round),
                                  efficiency_cop: cop5full.round(4),
                                  capacity_description: HPXML::CapacityDescriptionNominal,
                                  outdoor_temperature: 5,
                                  isdefaulted: true) unless capacity5full.nil?
    # 5F, minimum speed
    detailed_performance_data.add(capacity: Float(capacity5min.round),
                                  efficiency_cop: cop5min.round(4),
                                  capacity_description: HPXML::CapacityDescriptionMinimum,
                                  outdoor_temperature: 5,
                                  isdefaulted: true) unless capacity5min.nil?
    # LCT, maximum speed
    detailed_performance_data.add(capacity: Float(capacityLCTmax.round),
                                  efficiency_cop: copLCTmax.round(4),
                                  capacity_description: HPXML::CapacityDescriptionMaximum,
                                  outdoor_temperature: lct,
                                  isdefaulted: true) unless capacityLCTmax.nil?
    # LCT, nominal speed
    detailed_performance_data.add(capacity: Float(capacityLCTfull.round),
                                  efficiency_cop: copLCTfull.round(4),
                                  capacity_description: HPXML::CapacityDescriptionNominal,
                                  outdoor_temperature: lct,
                                  isdefaulted: true) unless capacityLCTfull.nil?
    # LCT, minimum speed
    detailed_performance_data.add(capacity: Float(capacityLCTmin.round),
                                  efficiency_cop: copLCTmin.round(4),
                                  capacity_description: HPXML::CapacityDescriptionMinimum,
                                  outdoor_temperature: lct,
                                  isdefaulted: true) unless capacityLCTmin.nil?
  end

  # Adds default heat pump or air conditioner detailed performance datapoints based on RESNET HERS Addendum 82.
  #
  # @param cooling_system [HPXML::CoolingSystem or HPXML::HeatPump] The HPXML cooling system or heat pump of interest
  # @return [nil]
  def self.set_detailed_performance_data_cooling(cooling_system)
    clg_ap = cooling_system.additional_properties

    capacity95full = cooling_system.cooling_capacity

    case cooling_system.compressor_type
    when HPXML::HVACCompressorTypeSingleStage
      # Capacity @ 82F
      capacity82full = capacity95full / clg_ap.qm95full

    when HPXML::HVACCompressorTypeTwoStage
      # Capacities @ 95F
      capacity95min = capacity95full * clg_ap.cool_capacity_ratios[0]

      # Capacities @ 82F
      capacity82full = capacity95full / clg_ap.qm95full
      capacity82min = capacity82full * clg_ap.cool_capacity_ratios[0]

    when HPXML::HVACCompressorTypeVariableSpeed
      # Capacities @ 95F
      capacity95max = capacity95full * clg_ap.cool_capacity_ratios[-1]
      capacity95min = capacity95full * clg_ap.cool_capacity_ratios[0]

      # Capacities @ 82F
      capacity82max = capacity95max / clg_ap.qm95max
      capacity82min = capacity95min / clg_ap.qm95min
      if capacity95full > 0
        capacity82full = MathTools.interp2(capacity95full, capacity95min, capacity95max, capacity82min, capacity82max)
      else
        capacity82full = 0.0
      end
    end

    # Add detailed performance data
    detailed_performance_data = cooling_system.cooling_detailed_performance_data

    # 95F, maximum speed
    detailed_performance_data.add(capacity: Float(capacity95max.round),
                                  efficiency_cop: clg_ap.cop95max.round(4),
                                  capacity_description: HPXML::CapacityDescriptionMaximum,
                                  outdoor_temperature: 95,
                                  isdefaulted: true) unless capacity95max.nil?
    # 95F, nominal speed
    detailed_performance_data.add(capacity: Float(capacity95full.round),
                                  efficiency_cop: clg_ap.cop95full.round(4),
                                  capacity_description: HPXML::CapacityDescriptionNominal,
                                  outdoor_temperature: 95,
                                  isdefaulted: true)
    # 95F, minimum speed
    detailed_performance_data.add(capacity: Float(capacity95min.round),
                                  efficiency_cop: clg_ap.cop95min.round(4),
                                  capacity_description: HPXML::CapacityDescriptionMinimum,
                                  outdoor_temperature: 95,
                                  isdefaulted: true) unless capacity95min.nil?
    # 82F, maximum speed
    detailed_performance_data.add(capacity: Float(capacity82max.round),
                                  efficiency_cop: clg_ap.cop82max.round(4),
                                  capacity_description: HPXML::CapacityDescriptionMaximum,
                                  outdoor_temperature: 82,
                                  isdefaulted: true) unless capacity82max.nil?
    # 82F, nominal speed
    detailed_performance_data.add(capacity: Float(capacity82full.round),
                                  efficiency_cop: clg_ap.cop82full.round(4),
                                  capacity_description: HPXML::CapacityDescriptionNominal,
                                  outdoor_temperature: 82,
                                  isdefaulted: true)
    # 82F, minimum speed
    detailed_performance_data.add(capacity: Float(capacity82min.round),
                                  efficiency_cop: clg_ap.cop82min.round(4),
                                  capacity_description: HPXML::CapacityDescriptionMinimum,
                                  outdoor_temperature: 82,
                                  isdefaulted: true) unless capacity82min.nil?
  end

  # Sets default geothermal loop properties when there's a ground-to-air heat pump.
  #
  # @param heat_pump [HPXML::HeatPump] The HPXML heat pump of interest
  # @param weather [WeatherFile] Weather object containing EPW information
  # @return [nil]
  def self.set_geothermal_loop_assumptions(heat_pump, weather)
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

    # Pipe nominal size conversion to pipe outside diameter and inside diameter,
    # only pipe sizes <= 2" are used here with DR11 (dimension ratio)
    case geothermal_loop.pipe_diameter
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
      fail "Unexpected pipe size: #{geothermal_loop.pipe_diameter}"
    end

    # Calculate distance between pipes
    hp_ap.u_tube_spacing_type = 'b' # Currently not exposed to the user
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
end
