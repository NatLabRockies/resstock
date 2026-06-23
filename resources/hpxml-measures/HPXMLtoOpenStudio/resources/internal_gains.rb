# frozen_string_literal: true

# Collection of methods related to internal gains.
module InternalGains
  # Create an OpenStudio People object using number of occupants and people/activity schedules.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def self.apply_building_occupants(runner, model, hpxml_bldg, hpxml_header, spaces, schedules_file)
    building_occupancy = hpxml_bldg.building_occupancy
    if building_occupancy.number_of_residents.nil? # Asset calculation
      n_occ = Geometry.get_occupancy_default_num(hpxml_bldg.building_construction.number_of_bedrooms)
    else # Operational calculation
      n_occ = building_occupancy.number_of_residents
    end
    return if n_occ <= 0

    occ_gain, _hrs_per_day, sens_frac, _lat_frac = Defaults.get_occupancy_values()
    activity_per_person = UnitConversions.convert(occ_gain, 'Btu/hr', 'W')

    # Hard-coded convective, radiative, latent, and lost fractions
    occ_sens = sens_frac
    occ_rad = 0.558 * occ_sens

    # Create schedule
    people_sch = nil
    people_col_name = SchedulesFile::Columns[:Occupants].name
    if not schedules_file.nil?
      people_sch = schedules_file.create_schedule_file(model, col_name: people_col_name)
    end
    if people_sch.nil?
      people_unavailable_periods = Schedule.get_unavailable_periods(runner, people_col_name, hpxml_header.unavailable_periods)
      weekday_sch = building_occupancy.weekday_fractions.split(',').map(&:to_f)
      weekday_sch = weekday_sch.map { |v| v / weekday_sch.max }.join(',')
      weekend_sch = building_occupancy.weekend_fractions.split(',').map(&:to_f)
      weekend_sch = weekend_sch.map { |v| v / weekend_sch.max }.join(',')
      monthly_sch = building_occupancy.monthly_multipliers
      people_sch = MonthWeekdayWeekendSchedule.new(model, Constants::ObjectTypeOccupants + ' schedule', weekday_sch, weekend_sch, monthly_sch, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: people_unavailable_periods)
      people_sch = people_sch.schedule
    else
      runner.registerWarning("Both '#{people_col_name}' schedule file and weekday fractions provided; the latter will be ignored.") if !building_occupancy.weekday_fractions.nil?
      runner.registerWarning("Both '#{people_col_name}' schedule file and weekend fractions provided; the latter will be ignored.") if !building_occupancy.weekend_fractions.nil?
      runner.registerWarning("Both '#{people_col_name}' schedule file and monthly multipliers provided; the latter will be ignored.") if !building_occupancy.monthly_multipliers.nil?
    end

    # Create schedule
    activity_sch = Model.add_schedule_constant(
      model,
      name: "#{Constants::ObjectTypeOccupants} activity schedule",
      value: activity_per_person
    )

    # Add people definition for the occ
    occ_def = OpenStudio::Model::PeopleDefinition.new(model)
    occ = OpenStudio::Model::People.new(occ_def)
    occ.setName(Constants::ObjectTypeOccupants)
    occ.setSpace(spaces[HPXML::LocationConditionedSpace])
    occ_def.setName(Constants::ObjectTypeOccupants)
    occ_def.setNumberofPeople(n_occ)
    occ_def.setFractionRadiant(occ_rad)
    occ_def.setSensibleHeatFraction(occ_sens)
    occ_def.setMeanRadiantTemperatureCalculationType('ZoneAveraged')
    occ_def.setCarbonDioxideGenerationRate(0)
    occ_def.setEnableASHRAE55ComfortWarnings(false)
    occ.setActivityLevelSchedule(activity_sch)
    occ.setNumberofPeopleSchedule(people_sch)
  end

  # Adds general water use internal gains (floor mopping, shower evaporation, water films
  # on showers, tubs & sinks surfaces, plant watering, etc.) to the OpenStudio Model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def self.apply_general_water_use(runner, model, hpxml_bldg, hpxml_header, spaces, schedules_file)
    nbeds = hpxml_bldg.building_construction.number_of_bedrooms
    unit_type = hpxml_bldg.building_construction.residential_facility_type

    building_occupancy = hpxml_bldg.building_occupancy
    n_occ = hpxml_bldg.building_occupancy.number_of_residents

    if not hpxml_header.apply_ashrae140_assumptions
      water_sens_btu, water_lat_btu = Defaults.get_water_use_internal_gains(nbeds, n_occ, unit_type, building_occupancy.general_water_use_usage_multiplier)

      # Create schedule
      water_schedule = nil
      water_col_name = SchedulesFile::Columns[:GeneralWaterUse].name
      water_obj_name = Constants::ObjectTypeGeneralWaterUse
      if not schedules_file.nil?
        water_design_level_sens = schedules_file.calc_design_level_from_daily_kwh(col_name: SchedulesFile::Columns[:GeneralWaterUse].name, daily_kwh: UnitConversions.convert(water_sens_btu, 'Btu', 'kWh') / 365.0)
        water_design_level_lat = schedules_file.calc_design_level_from_daily_kwh(col_name: SchedulesFile::Columns[:GeneralWaterUse].name, daily_kwh: UnitConversions.convert(water_lat_btu, 'Btu', 'kWh') / 365.0)
        water_schedule = schedules_file.create_schedule_file(model, col_name: water_col_name, schedule_type_limits_name: EPlus::ScheduleTypeLimitsFraction)
      end
      if water_schedule.nil?
        water_unavailable_periods = Schedule.get_unavailable_periods(runner, water_col_name, hpxml_header.unavailable_periods)
        water_schedule_obj = MonthWeekdayWeekendSchedule.new(model, water_obj_name + ' schedule', building_occupancy.general_water_use_weekday_fractions, building_occupancy.general_water_use_weekend_fractions, building_occupancy.general_water_use_monthly_multipliers, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: water_unavailable_periods)
        water_design_level_sens = water_schedule_obj.calc_design_level_from_daily_kwh(UnitConversions.convert(water_sens_btu, 'Btu', 'kWh') / 365.0)
        water_design_level_lat = water_schedule_obj.calc_design_level_from_daily_kwh(UnitConversions.convert(water_lat_btu, 'Btu', 'kWh') / 365.0)
        water_schedule = water_schedule_obj.schedule
      else
        runner.registerWarning("Both '#{water_col_name}' schedule file and weekday fractions provided; the latter will be ignored.") if !building_occupancy.general_water_use_weekday_fractions.nil?
        runner.registerWarning("Both '#{water_col_name}' schedule file and weekend fractions provided; the latter will be ignored.") if !building_occupancy.general_water_use_weekend_fractions.nil?
        runner.registerWarning("Both '#{water_col_name}' schedule file and monthly multipliers provided; the latter will be ignored.") if !building_occupancy.general_water_use_monthly_multipliers.nil?
      end

      Model.add_other_equipment(
        model,
        name: Constants::ObjectTypeGeneralWaterUseSensible,
        end_use: Constants::ObjectTypeGeneralWaterUseSensible,
        space: spaces[HPXML::LocationConditionedSpace],
        design_level: water_design_level_sens,
        frac_radiant: 0.6,
        frac_latent: 0,
        frac_lost: 0,
        schedule: water_schedule,
        fuel_type: nil
      )

      Model.add_other_equipment(
        model,
        name: Constants::ObjectTypeGeneralWaterUseLatent,
        end_use: Constants::ObjectTypeGeneralWaterUseLatent,
        space: spaces[HPXML::LocationConditionedSpace],
        design_level: water_design_level_lat,
        frac_radiant: 0,
        frac_latent: 1,
        frac_lost: 0,
        schedule: water_schedule,
        fuel_type: nil
      )
    end
  end
end
