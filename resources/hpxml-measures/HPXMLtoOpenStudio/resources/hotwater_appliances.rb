# frozen_string_literal: true

# Collection of methods related to hot water use and appliances.
module HotWaterAndAppliances
  # Adds HPXML HotWaterDistribution, WaterFixtures, and Appliances to the OpenStudio model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param plantloop_map [Hash] Map of HPXML System ID => OpenStudio PlantLoop objects
  # @return [nil]
  def self.apply(runner, model, weather, spaces, hpxml_bldg, hpxml_header, schedules_file, plantloop_map)
    # Get appliances, etc.
    if not hpxml_bldg.clothes_washers.empty?
      clothes_washer = hpxml_bldg.clothes_washers[0]
    end
    if not hpxml_bldg.clothes_dryers.empty?
      clothes_dryer = hpxml_bldg.clothes_dryers[0]
    end
    if not hpxml_bldg.dishwashers.empty?
      dishwasher = hpxml_bldg.dishwashers[0]
    end
    if not hpxml_bldg.cooking_ranges.empty?
      cooking_range = hpxml_bldg.cooking_ranges[0]
    end
    if not hpxml_bldg.ovens.empty?
      oven = hpxml_bldg.ovens[0]
    end

    eri_version = hpxml_header.eri_calculation_versions[0]
    conditioned_space = spaces[HPXML::LocationConditionedSpace]
    unit_multiplier = hpxml_bldg.building_construction.number_of_units

    # Create WaterUseConnections object for each water heater (plant loop)
    water_use_connections = {}
    hpxml_bldg.water_heating_systems.each do |water_heating_system|
      plant_loop = plantloop_map[water_heating_system.id]
      wuc = OpenStudio::Model::WaterUseConnections.new(model)
      wuc.additionalProperties.setFeature('HPXML_ID', water_heating_system.id) # Used by reporting measure
      plant_loop.addDemandBranchForComponent(wuc)
      water_use_connections[water_heating_system.id] = wuc
    end

    # Clothes washer energy
    if not clothes_washer.nil?
      cw_space = Geometry.get_space_from_location(clothes_washer.location, spaces)
      cw_annual_kwh, cw_frac_sens, cw_frac_lat, cw_gpd = calc_clothes_washer_energy_gpd(runner, eri_version, hpxml_bldg, clothes_washer, cw_space.nil?)

      # Create schedule
      cw_power_schedule = nil
      cw_col_name = SchedulesFile::Columns[:ClothesWasher].name
      cw_object_name = Constants::ObjectTypeClothesWasher
      if not schedules_file.nil?
        cw_design_level_w = schedules_file.calc_design_level_from_daily_kwh(col_name: cw_col_name, daily_kwh: cw_annual_kwh / 365.0)
        cw_power_schedule = schedules_file.create_schedule_file(model, col_name: cw_col_name, schedule_type_limits_name: EPlus::ScheduleTypeLimitsFraction)
      end
      if cw_power_schedule.nil?
        cw_unavailable_periods = Schedule.get_unavailable_periods(runner, cw_col_name, hpxml_header.unavailable_periods)
        cw_schedule_obj = MonthWeekdayWeekendSchedule.new(model, cw_object_name + ' schedule', clothes_washer.weekday_fractions, clothes_washer.weekend_fractions, clothes_washer.monthly_multipliers, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: cw_unavailable_periods)
        cw_design_level_w = cw_schedule_obj.calc_design_level_from_daily_kwh(cw_annual_kwh / 365.0)
        cw_power_schedule = cw_schedule_obj.schedule
      else
        runner.registerWarning("Both '#{cw_col_name}' schedule file and weekday fractions provided; the latter will be ignored.") if !clothes_washer.weekday_fractions.nil?
        runner.registerWarning("Both '#{cw_col_name}' schedule file and weekend fractions provided; the latter will be ignored.") if !clothes_washer.weekend_fractions.nil?
        runner.registerWarning("Both '#{cw_col_name}' schedule file and monthly multipliers provided; the latter will be ignored.") if !clothes_washer.monthly_multipliers.nil?
      end

      cw_space = conditioned_space if cw_space.nil? # appliance is outdoors, so we need to assign the equipment to an arbitrary space

      Model.add_electric_equipment(
        model,
        name: cw_object_name,
        end_use: cw_object_name,
        space: cw_space,
        design_level: cw_design_level_w,
        frac_radiant: 0.6 * cw_frac_sens,
        frac_latent: cw_frac_lat,
        frac_lost: 1 - cw_frac_sens - cw_frac_lat,
        schedule: cw_power_schedule
      )
    end

    # Clothes dryer energy
    if not clothes_dryer.nil?
      cd_space = Geometry.get_space_from_location(clothes_dryer.location, spaces)
      cd_annual_kwh, cd_annual_therm, cd_frac_sens, cd_frac_lat = calc_clothes_dryer_energy(runner, eri_version, hpxml_bldg, clothes_dryer, clothes_washer, cd_space.nil?)

      # Create schedule
      cd_schedule = nil
      cd_col_name = SchedulesFile::Columns[:ClothesDryer].name
      cd_obj_name = Constants::ObjectTypeClothesDryer
      if not schedules_file.nil?
        cd_design_level_e = schedules_file.calc_design_level_from_annual_kwh(col_name: cd_col_name, annual_kwh: cd_annual_kwh)
        cd_design_level_f = schedules_file.calc_design_level_from_annual_therm(col_name: cd_col_name, annual_therm: cd_annual_therm)
        cd_schedule = schedules_file.create_schedule_file(model, col_name: cd_col_name, schedule_type_limits_name: EPlus::ScheduleTypeLimitsFraction)
      end
      if cd_schedule.nil?
        cd_unavailable_periods = Schedule.get_unavailable_periods(runner, cd_col_name, hpxml_header.unavailable_periods)
        cd_schedule_obj = MonthWeekdayWeekendSchedule.new(model, cd_obj_name + ' schedule', clothes_dryer.weekday_fractions, clothes_dryer.weekend_fractions, clothes_dryer.monthly_multipliers, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: cd_unavailable_periods)
        cd_design_level_e = cd_schedule_obj.calc_design_level_from_daily_kwh(cd_annual_kwh / 365.0)
        cd_design_level_f = cd_schedule_obj.calc_design_level_from_daily_therm(cd_annual_therm / 365.0)
        cd_schedule = cd_schedule_obj.schedule
      else
        runner.registerWarning("Both '#{cd_col_name}' schedule file and weekday fractions provided; the latter will be ignored.") if !clothes_dryer.weekday_fractions.nil?
        runner.registerWarning("Both '#{cd_col_name}' schedule file and weekend fractions provided; the latter will be ignored.") if !clothes_dryer.weekend_fractions.nil?
        runner.registerWarning("Both '#{cd_col_name}' schedule file and monthly multipliers provided; the latter will be ignored.") if !clothes_dryer.monthly_multipliers.nil?
      end

      cd_space = conditioned_space if cd_space.nil? # appliance is outdoors, so we need to assign the equipment to an arbitrary space

      Model.add_electric_equipment(
        model,
        name: cd_obj_name,
        end_use: cd_obj_name,
        space: cd_space,
        design_level: cd_design_level_e,
        frac_radiant: 0.6 * cd_frac_sens,
        frac_latent: cd_frac_lat,
        frac_lost: 1 - cd_frac_sens - cd_frac_lat,
        schedule: cd_schedule
      )
      Model.add_other_equipment(
        model,
        name: cd_obj_name,
        end_use: cd_obj_name,
        space: cd_space,
        design_level: cd_design_level_f,
        frac_radiant: 0.6 * cd_frac_sens,
        frac_latent: cd_frac_lat,
        frac_lost: 1 - cd_frac_sens - cd_frac_lat,
        schedule: cd_schedule,
        fuel_type: clothes_dryer.fuel_type
      )
    end

    # Dishwasher energy
    if not dishwasher.nil?
      dw_space = Geometry.get_space_from_location(dishwasher.location, spaces)
      dw_annual_kwh, dw_frac_sens, dw_frac_lat, dw_gpd = calc_dishwasher_energy_gpd(runner, eri_version, hpxml_bldg, dishwasher, dw_space.nil?)

      # Create schedule
      dw_power_schedule = nil
      dw_col_name = SchedulesFile::Columns[:Dishwasher].name
      dw_obj_name = Constants::ObjectTypeDishwasher
      if not schedules_file.nil?
        dw_design_level_w = schedules_file.calc_design_level_from_daily_kwh(col_name: dw_col_name, daily_kwh: dw_annual_kwh / 365.0)
        dw_power_schedule = schedules_file.create_schedule_file(model, col_name: dw_col_name, schedule_type_limits_name: EPlus::ScheduleTypeLimitsFraction)
      end
      if dw_power_schedule.nil?
        dw_unavailable_periods = Schedule.get_unavailable_periods(runner, dw_col_name, hpxml_header.unavailable_periods)
        dw_schedule_obj = MonthWeekdayWeekendSchedule.new(model, dw_obj_name + ' schedule', dishwasher.weekday_fractions, dishwasher.weekend_fractions, dishwasher.monthly_multipliers, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: dw_unavailable_periods)
        dw_design_level_w = dw_schedule_obj.calc_design_level_from_daily_kwh(dw_annual_kwh / 365.0)
        dw_power_schedule = dw_schedule_obj.schedule
      else
        runner.registerWarning("Both '#{dw_col_name}' schedule file and weekday fractions provided; the latter will be ignored.") if !dishwasher.weekday_fractions.nil?
        runner.registerWarning("Both '#{dw_col_name}' schedule file and weekend fractions provided; the latter will be ignored.") if !dishwasher.weekend_fractions.nil?
        runner.registerWarning("Both '#{dw_col_name}' schedule file and monthly multipliers provided; the latter will be ignored.") if !dishwasher.monthly_multipliers.nil?
      end

      dw_space = conditioned_space if dw_space.nil? # appliance is outdoors, so we need to assign the equipment to an arbitrary space

      Model.add_electric_equipment(
        model,
        name: dw_obj_name,
        end_use: dw_obj_name,
        space: dw_space,
        design_level: dw_design_level_w,
        frac_radiant: 0.6 * dw_frac_sens,
        frac_latent: dw_frac_lat,
        frac_lost: 1 - dw_frac_sens - dw_frac_lat,
        schedule: dw_power_schedule
      )
    end

    # Refrigerator(s) energy
    hpxml_bldg.refrigerators.each do |refrigerator|
      rf_space, rf_loc_schedule = Geometry.get_space_or_schedule_from_location(refrigerator.location, model, spaces)
      rf_annual_kwh, rf_frac_sens, rf_frac_lat = calc_fridge_or_freezer_energy(runner, refrigerator, rf_space.nil?)

      # Create schedule
      rf_schedule = nil
      rf_col_name = refrigerator.primary_indicator ? SchedulesFile::Columns[:Refrigerator].name : SchedulesFile::Columns[:ExtraRefrigerator].name
      rf_obj_name = Constants::ObjectTypeRefrigerator
      if not schedules_file.nil?
        rf_design_level = schedules_file.calc_design_level_from_annual_kwh(col_name: rf_col_name, annual_kwh: rf_annual_kwh)
        rf_schedule = schedules_file.create_schedule_file(model, col_name: rf_col_name, schedule_type_limits_name: EPlus::ScheduleTypeLimitsFraction)
      end
      if rf_schedule.nil?
        rf_unavailable_periods = Schedule.get_unavailable_periods(runner, rf_col_name, hpxml_header.unavailable_periods)

        # if both weekday_fractions/weekend_fractions/monthly_multipliers and constant_coefficients/temperature_coefficients provided, ignore the former
        if !refrigerator.constant_coefficients.nil? && !refrigerator.temperature_coefficients.nil?
          rf_design_level = UnitConversions.convert(rf_annual_kwh / 8760.0, 'kW', 'W')
          rf_schedule = get_fridge_or_freezer_coefficients_schedule(model, rf_col_name, rf_obj_name, refrigerator, rf_space, rf_loc_schedule, rf_unavailable_periods)
        elsif !refrigerator.weekday_fractions.nil? && !refrigerator.weekend_fractions.nil? && !refrigerator.monthly_multipliers.nil?
          rf_schedule_obj = MonthWeekdayWeekendSchedule.new(model, rf_obj_name + ' schedule', refrigerator.weekday_fractions, refrigerator.weekend_fractions, refrigerator.monthly_multipliers, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: rf_unavailable_periods)
          rf_design_level = rf_schedule_obj.calc_design_level_from_daily_kwh(rf_annual_kwh / 365.0)
          rf_schedule = rf_schedule_obj.schedule
        end
      else
        runner.registerWarning("Both '#{rf_col_name}' schedule file and weekday fractions provided; the latter will be ignored.") if !refrigerator.weekday_fractions.nil?
        runner.registerWarning("Both '#{rf_col_name}' schedule file and weekend fractions provided; the latter will be ignored.") if !refrigerator.weekend_fractions.nil?
        runner.registerWarning("Both '#{rf_col_name}' schedule file and monthly multipliers provided; the latter will be ignored.") if !refrigerator.monthly_multipliers.nil?
        runner.registerWarning("Both '#{rf_col_name}' schedule file and constant coefficients provided; the latter will be ignored.") if !refrigerator.constant_coefficients.nil?
        runner.registerWarning("Both '#{rf_col_name}' schedule file and temperature coefficients provided; the latter will be ignored.") if !refrigerator.temperature_coefficients.nil?
      end

      rf_space = conditioned_space if rf_space.nil? # appliance is outdoors, so we need to assign the equipment to an arbitrary space

      Model.add_electric_equipment(
        model,
        name: rf_obj_name,
        end_use: rf_obj_name,
        space: rf_space,
        design_level: rf_design_level,
        frac_radiant: 0.6 * rf_frac_sens,
        frac_latent: rf_frac_lat,
        frac_lost: 1 - rf_frac_sens - rf_frac_lat,
        schedule: rf_schedule
      )
    end

    # Freezer(s) energy
    hpxml_bldg.freezers.each do |freezer|
      fz_space, fz_loc_schedule = Geometry.get_space_or_schedule_from_location(freezer.location, model, spaces)
      fz_annual_kwh, fz_frac_sens, fz_frac_lat = calc_fridge_or_freezer_energy(runner, freezer, fz_space.nil?)

      # Create schedule
      fz_schedule = nil
      fz_col_name = SchedulesFile::Columns[:Freezer].name
      fz_obj_name = Constants::ObjectTypeFreezer
      if not schedules_file.nil?
        fz_design_level = schedules_file.calc_design_level_from_annual_kwh(col_name: fz_col_name, annual_kwh: fz_annual_kwh)
        fz_schedule = schedules_file.create_schedule_file(model, col_name: fz_col_name, schedule_type_limits_name: EPlus::ScheduleTypeLimitsFraction)
      end
      if fz_schedule.nil?
        fz_unavailable_periods = Schedule.get_unavailable_periods(runner, fz_col_name, hpxml_header.unavailable_periods)

        # if both weekday_fractions/weekend_fractions/monthly_multipliers and constant_coefficients/temperature_coefficients provided, ignore the former
        if !freezer.constant_coefficients.nil? && !freezer.temperature_coefficients.nil?
          fz_design_level = UnitConversions.convert(fz_annual_kwh / 8760.0, 'kW', 'W')
          fz_schedule = get_fridge_or_freezer_coefficients_schedule(model, fz_col_name, fz_obj_name, freezer, fz_space, fz_loc_schedule, fz_unavailable_periods)
        elsif !freezer.weekday_fractions.nil? && !freezer.weekend_fractions.nil? && !freezer.monthly_multipliers.nil?
          fz_schedule_obj = MonthWeekdayWeekendSchedule.new(model, fz_obj_name + ' schedule', freezer.weekday_fractions, freezer.weekend_fractions, freezer.monthly_multipliers, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: fz_unavailable_periods)
          fz_design_level = fz_schedule_obj.calc_design_level_from_daily_kwh(fz_annual_kwh / 365.0)
          fz_schedule = fz_schedule_obj.schedule
        end
      else
        runner.registerWarning("Both '#{fz_col_name}' schedule file and weekday fractions provided; the latter will be ignored.") if !freezer.weekday_fractions.nil?
        runner.registerWarning("Both '#{fz_col_name}' schedule file and weekend fractions provided; the latter will be ignored.") if !freezer.weekend_fractions.nil?
        runner.registerWarning("Both '#{fz_col_name}' schedule file and monthly multipliers provided; the latter will be ignored.") if !freezer.monthly_multipliers.nil?
        runner.registerWarning("Both '#{fz_col_name}' schedule file and constant coefficients provided; the latter will be ignored.") if !freezer.constant_coefficients.nil?
        runner.registerWarning("Both '#{fz_col_name}' schedule file and temperature coefficients provided; the latter will be ignored.") if !freezer.temperature_coefficients.nil?
      end

      fz_space = conditioned_space if fz_space.nil? # appliance is outdoors, so we need to assign the equipment to an arbitrary space

      Model.add_electric_equipment(
        model,
        name: fz_obj_name,
        end_use: fz_obj_name,
        space: fz_space,
        design_level: fz_design_level,
        frac_radiant: 0.6 * fz_frac_sens,
        frac_latent: fz_frac_lat,
        frac_lost: 1 - fz_frac_sens - fz_frac_lat,
        schedule: fz_schedule
      )
    end

    # Cooking Range energy
    if not cooking_range.nil?
      cook_space = Geometry.get_space_from_location(cooking_range.location, spaces)
      cook_annual_kwh, cook_annual_therm, cook_frac_sens, cook_frac_lat = calc_range_oven_energy(runner, hpxml_bldg, cooking_range, oven, cook_space.nil?)

      # Create schedule
      cook_schedule = nil
      cook_col_name = SchedulesFile::Columns[:CookingRange].name
      cook_obj_name = Constants::ObjectTypeCookingRange
      if not schedules_file.nil?
        cook_design_level_e = schedules_file.calc_design_level_from_annual_kwh(col_name: cook_col_name, annual_kwh: cook_annual_kwh)
        cook_design_level_f = schedules_file.calc_design_level_from_annual_therm(col_name: cook_col_name, annual_therm: cook_annual_therm)
        cook_schedule = schedules_file.create_schedule_file(model, col_name: cook_col_name, schedule_type_limits_name: EPlus::ScheduleTypeLimitsFraction)
      end
      if cook_schedule.nil?
        cook_unavailable_periods = Schedule.get_unavailable_periods(runner, cook_col_name, hpxml_header.unavailable_periods)
        cook_schedule_obj = MonthWeekdayWeekendSchedule.new(model, cook_obj_name + ' schedule', cooking_range.weekday_fractions, cooking_range.weekend_fractions, cooking_range.monthly_multipliers, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: cook_unavailable_periods)
        cook_design_level_e = cook_schedule_obj.calc_design_level_from_daily_kwh(cook_annual_kwh / 365.0)
        cook_design_level_f = cook_schedule_obj.calc_design_level_from_daily_therm(cook_annual_therm / 365.0)
        cook_schedule = cook_schedule_obj.schedule
      else
        runner.registerWarning("Both '#{cook_col_name}' schedule file and weekday fractions provided; the latter will be ignored.") if !cooking_range.weekday_fractions.nil?
        runner.registerWarning("Both '#{cook_col_name}' schedule file and weekend fractions provided; the latter will be ignored.") if !cooking_range.weekend_fractions.nil?
        runner.registerWarning("Both '#{cook_col_name}' schedule file and monthly multipliers provided; the latter will be ignored.") if !cooking_range.monthly_multipliers.nil?
      end

      cook_space = conditioned_space if cook_space.nil? # appliance is outdoors, so we need to assign the equipment to an arbitrary space

      Model.add_electric_equipment(
        model,
        name: cook_obj_name,
        end_use: cook_obj_name,
        space: cook_space,
        design_level: cook_design_level_e,
        frac_radiant: 0.6 * cook_frac_sens,
        frac_latent: cook_frac_lat,
        frac_lost: 1 - cook_frac_sens - cook_frac_lat,
        schedule: cook_schedule
      )
      Model.add_other_equipment(
        model,
        name: cook_obj_name,
        end_use: cook_obj_name,
        space: cook_space,
        design_level: cook_design_level_f,
        frac_radiant: 0.6 * cook_frac_sens,
        frac_latent: cook_frac_lat,
        frac_lost: 1 - cook_frac_sens - cook_frac_lat,
        schedule: cook_schedule,
        fuel_type: cooking_range.fuel_type
      )
    end

    if hpxml_bldg.hot_water_distributions.size > 0
      hot_water_distribution = hpxml_bldg.hot_water_distributions[0]

      # Calculate mixed water fractions
      t_mix = 105.0 # F, Temperature of mixed water at fixtures
      avg_setpoint_temp = 0.0 # WH Setpoint: Weighted average by fraction DHW load served
      hpxml_bldg.water_heating_systems.each do |water_heating_system|
        wh_setpoint = water_heating_system.temperature
        wh_setpoint = Defaults.get_water_heater_temperature(eri_version) if wh_setpoint.nil? # using detailed schedules
        avg_setpoint_temp += wh_setpoint * water_heating_system.fraction_dhw_load_served
      end
      daily_wh_inlet_temperatures = calc_water_heater_daily_inlet_temperatures(weather, hpxml_bldg)
      daily_wh_inlet_temperatures_c = daily_wh_inlet_temperatures.map { |t| UnitConversions.convert(t, 'F', 'C') }
      daily_mw_fractions = calc_mixed_water_daily_fractions(daily_wh_inlet_temperatures, avg_setpoint_temp, t_mix)

      # Schedules
      # Replace mains water temperature schedule with water heater inlet temperature schedule.
      # These are identical unless there is a DWHR.
      start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(1), 1, hpxml_header.sim_calendar_year)
      timestep_day = OpenStudio::Time.new(1, 0)
      time_series_tmains = OpenStudio::TimeSeries.new(start_date, timestep_day, OpenStudio::createVector(daily_wh_inlet_temperatures_c), 'C')
      schedule_tmains = OpenStudio::Model::ScheduleInterval.fromTimeSeries(time_series_tmains, model).get
      schedule_tmains.setName('mains temperature schedule')
      model.getSiteWaterMainsTemperature.setTemperatureSchedule(schedule_tmains)

      mw_temp_schedule = Model.add_schedule_constant(
        model,
        name: 'mixed water temperature schedule',
        value: UnitConversions.convert(t_mix, 'F', 'C'),
        limits: EPlus::ScheduleTypeLimitsTemperature
      )

      water_heating = hpxml_bldg.water_heating

      # Create schedule
      fixtures_schedule = nil
      fixtures_col_name = SchedulesFile::Columns[:HotWaterFixtures].name
      fixtures_obj_name = Constants::ObjectTypeFixtures
      if not schedules_file.nil?
        fixtures_schedule = schedules_file.create_schedule_file(model, col_name: fixtures_col_name, schedule_type_limits_name: EPlus::ScheduleTypeLimitsFraction)
      end
      if fixtures_schedule.nil?
        fixtures_unavailable_periods = Schedule.get_unavailable_periods(runner, fixtures_col_name, hpxml_header.unavailable_periods)
        fixtures_schedule_obj = MonthWeekdayWeekendSchedule.new(model, fixtures_obj_name + ' schedule', water_heating.water_fixtures_weekday_fractions, water_heating.water_fixtures_weekend_fractions, water_heating.water_fixtures_monthly_multipliers, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: fixtures_unavailable_periods)
        fixtures_schedule = fixtures_schedule_obj.schedule
      else
        runner.registerWarning("Both '#{fixtures_col_name}' schedule file and weekday fractions provided; the latter will be ignored.") if !water_heating.water_fixtures_weekday_fractions.nil?
        runner.registerWarning("Both '#{fixtures_col_name}' schedule file and weekend fractions provided; the latter will be ignored.") if !water_heating.water_fixtures_weekend_fractions.nil?
        runner.registerWarning("Both '#{fixtures_col_name}' schedule file and monthly multipliers provided; the latter will be ignored.") if !water_heating.water_fixtures_monthly_multipliers.nil?
      end
    end

    hpxml_bldg.water_heating_systems.each do |water_heating_system|
      non_solar_fraction = 1.0 - Waterheater.get_water_heater_solar_fraction(water_heating_system, hpxml_bldg)

      gpd_frac = water_heating_system.fraction_dhw_load_served # Fixtures fraction
      if gpd_frac > 0

        fx_gpd = get_fixtures_gpd(eri_version, hpxml_bldg, daily_mw_fractions)
        w_gpd = get_dist_waste_gpd(eri_version, hpxml_bldg)

        fx_peak_flow = nil
        if not schedules_file.nil?
          fx_peak_flow = schedules_file.calc_peak_flow_from_daily_gpm(col_name: SchedulesFile::Columns[:HotWaterFixtures].name, daily_water: fx_gpd)
          dist_water_peak_flow = schedules_file.calc_peak_flow_from_daily_gpm(col_name: SchedulesFile::Columns[:HotWaterFixtures].name, daily_water: w_gpd)
        end
        if fx_peak_flow.nil?
          fx_peak_flow = fixtures_schedule_obj.calc_design_level_from_daily_gpm(fx_gpd)
          dist_water_peak_flow = fixtures_schedule_obj.calc_design_level_from_daily_gpm(w_gpd)
        end

        # Fixtures (showers, sinks, baths)
        Model.add_water_use_equipment(
          model,
          name: fixtures_obj_name,
          end_use: fixtures_obj_name,
          peak_flow_rate: unit_multiplier * fx_peak_flow * gpd_frac * non_solar_fraction,
          flow_rate_schedule: fixtures_schedule,
          water_use_connections: water_use_connections[water_heating_system.id],
          target_temperature_schedule: mw_temp_schedule
        )

        # Distribution waste (primary driven by fixture draws)
        Model.add_water_use_equipment(
          model,
          name: Constants::ObjectTypeDistributionWaste,
          end_use: Constants::ObjectTypeDistributionWaste,
          peak_flow_rate: unit_multiplier * dist_water_peak_flow * gpd_frac * non_solar_fraction,
          flow_rate_schedule: fixtures_schedule,
          water_use_connections: water_use_connections[water_heating_system.id],
          target_temperature_schedule: mw_temp_schedule
        )

        # Recirculation pump
        recirc_pump_annual_kwh = get_hwdist_recirc_pump_energy(hpxml_bldg)
        if recirc_pump_annual_kwh > 0

          # Create schedule
          recirc_pump_sch = nil
          recirc_pump_col_name = SchedulesFile::Columns[:HotWaterRecirculationPump].name
          recirc_pump_obj_name = Constants::ObjectTypeHotWaterRecircPump
          if not schedules_file.nil?
            recirc_pump_design_level = schedules_file.calc_design_level_from_daily_kwh(col_name: recirc_pump_col_name, daily_kwh: recirc_pump_annual_kwh / 365.0)
            recirc_pump_sch = schedules_file.create_schedule_file(model, col_name: recirc_pump_col_name, schedule_type_limits_name: EPlus::ScheduleTypeLimitsFraction)
          end
          if recirc_pump_sch.nil?
            recirc_pump_unavailable_periods = Schedule.get_unavailable_periods(runner, recirc_pump_col_name, hpxml_header.unavailable_periods)
            recirc_pump_sch = MonthWeekdayWeekendSchedule.new(model, recirc_pump_obj_name + ' schedule', hot_water_distribution.recirculation_pump_weekday_fractions, hot_water_distribution.recirculation_pump_weekend_fractions, hot_water_distribution.recirculation_pump_monthly_multipliers, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: recirc_pump_unavailable_periods)
            recirc_pump_design_level = recirc_pump_sch.calc_design_level_from_daily_kwh(recirc_pump_annual_kwh / 365.0)
            recirc_pump_sch = recirc_pump_sch.schedule
          else
            runner.registerWarning("Both '#{recirc_pump_col_name}' schedule file and weekday fractions provided; the latter will be ignored.") if !hot_water_distribution.recirculation_pump_weekday_fractions.nil?
            runner.registerWarning("Both '#{recirc_pump_col_name}' schedule file and weekend fractions provided; the latter will be ignored.") if !hot_water_distribution.recirculation_pump_weekend_fractions.nil?
            runner.registerWarning("Both '#{recirc_pump_col_name}' schedule file and monthly multipliers provided; the latter will be ignored.") if !hot_water_distribution.recirculation_pump_monthly_multipliers.nil?
          end
          if recirc_pump_design_level * gpd_frac != 0
            cnt = model.getElectricEquipments.count { |e| e.endUseSubcategory.start_with? Constants::ObjectTypeHotWaterRecircPump } # Ensure unique meter for each water heater
            recirc_pump = Model.add_electric_equipment(
              model,
              name: "#{Constants::ObjectTypeHotWaterRecircPump}#{cnt + 1}",
              end_use: "#{Constants::ObjectTypeHotWaterRecircPump}#{cnt + 1}",
              space: conditioned_space,
              design_level: recirc_pump_design_level * gpd_frac,
              frac_radiant: 0,
              frac_latent: 0,
              frac_lost: 1,
              schedule: recirc_pump_sch
            )
            recirc_pump.additionalProperties.setFeature('HPXML_ID', water_heating_system.id) # Used by reporting measure
          end
        end
      end

      # Clothes washer
      if not clothes_washer.nil?
        gpd_frac = nil
        if clothes_washer.is_shared_appliance && (not clothes_washer.hot_water_distribution.nil?)
          gpd_frac = 1.0 / hpxml_bldg.water_heating_systems.size # Apportion load to each water heater on distribution system
        elsif clothes_washer.is_shared_appliance && clothes_washer.water_heating_system.id == water_heating_system.id
          gpd_frac = 1.0 # Shared water heater sees full appliance load
        elsif not clothes_washer.is_shared_appliance
          gpd_frac = water_heating_system.fraction_dhw_load_served
        end
        if not gpd_frac.nil?
          # Create schedule
          water_cw_schedule = nil
          if not schedules_file.nil?
            cw_peak_flow = schedules_file.calc_peak_flow_from_daily_gpm(col_name: SchedulesFile::Columns[:HotWaterClothesWasher].name, daily_water: cw_gpd)
            water_cw_schedule = schedules_file.create_schedule_file(model, col_name: SchedulesFile::Columns[:HotWaterClothesWasher].name, schedule_type_limits_name: EPlus::ScheduleTypeLimitsFraction)
          end
          if water_cw_schedule.nil?
            cw_peak_flow = cw_schedule_obj.calc_design_level_from_daily_gpm(cw_gpd)
            water_cw_schedule = cw_schedule_obj.schedule
          end

          Model.add_water_use_equipment(
            model,
            name: cw_object_name,
            end_use: cw_object_name,
            peak_flow_rate: unit_multiplier * cw_peak_flow * gpd_frac * non_solar_fraction,
            flow_rate_schedule: water_cw_schedule,
            water_use_connections: water_use_connections[water_heating_system.id],
            target_temperature_schedule: nil
          )
        end
      end

      # Dishwasher
      next if dishwasher.nil?

      gpd_frac = nil
      if dishwasher.is_shared_appliance && (not dishwasher.hot_water_distribution.nil?)
        gpd_frac = 1.0 / hpxml_bldg.water_heating_systems.size # Apportion load to each water heater on distribution system
      elsif dishwasher.is_shared_appliance && dishwasher.water_heating_system.id == water_heating_system.id
        gpd_frac = 1.0 # Shared water heater sees full appliance load
      elsif not dishwasher.is_shared_appliance
        gpd_frac = water_heating_system.fraction_dhw_load_served
      end
      next if gpd_frac.nil?

      # Create schedule
      water_dw_schedule = nil
      if not schedules_file.nil?
        dw_peak_flow = schedules_file.calc_peak_flow_from_daily_gpm(col_name: SchedulesFile::Columns[:HotWaterDishwasher].name, daily_water: dw_gpd)
        water_dw_schedule = schedules_file.create_schedule_file(model, col_name: SchedulesFile::Columns[:HotWaterDishwasher].name, schedule_type_limits_name: EPlus::ScheduleTypeLimitsFraction)
      end
      if water_dw_schedule.nil?
        dw_peak_flow = dw_schedule_obj.calc_design_level_from_daily_gpm(dw_gpd)
        water_dw_schedule = dw_schedule_obj.schedule
      end

      Model.add_water_use_equipment(
        model,
        name: dw_obj_name,
        end_use: dw_obj_name,
        peak_flow_rate: unit_multiplier * dw_peak_flow * gpd_frac * non_solar_fraction,
        flow_rate_schedule: water_dw_schedule,
        water_use_connections: water_use_connections[water_heating_system.id],
        target_temperature_schedule: nil
      )
    end
  end

  # Calculates cooking range/oven annual energy use.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param cooking_range [HPXML::CookingRange] The HPXML cooking range of interest
  # @param oven [HPXML::Oven] The HPXML oven of interest
  # @param is_outside [Boolean] Whether the appliance is located outside the dwelling unit
  # @return [Array<Double, Double, Double, Double>] Annual electricity use (kWh), annual fuel use (therm), sensible/latent fractions
  def self.calc_range_oven_energy(runner, hpxml_bldg, cooking_range, oven, is_outside = false)
    nbeds = hpxml_bldg.building_construction.number_of_bedrooms
    n_occ = hpxml_bldg.building_occupancy.number_of_residents
    unit_type = hpxml_bldg.building_construction.residential_facility_type

    if n_occ == 0
      # Operational calculation w/ zero occupants, zero out energy use
      return 0.0, 0.0, 0.0, 0.0
    end

    nbeds_eq = Defaults.get_equivalent_nbeds(nbeds, n_occ, unit_type)

    if cooking_range.is_induction
      burner_ef = 0.91
    else
      burner_ef = 1.0
    end
    if oven.is_convection
      oven_ef = 0.95
    else
      oven_ef = 1.0
    end

    if cooking_range.fuel_type != HPXML::FuelTypeElectricity
      annual_kwh = 22.6 + 2.7 * nbeds_eq
      annual_therm = oven_ef * (22.6 + 2.7 * nbeds_eq)
    else
      annual_kwh = burner_ef * oven_ef * (331 + 39.0 * nbeds_eq)
      annual_therm = 0.0
    end

    annual_kwh *= cooking_range.usage_multiplier
    annual_therm *= cooking_range.usage_multiplier

    if not is_outside
      frac_lost = 0.20
      if cooking_range.fuel_type == HPXML::FuelTypeElectricity
        frac_sens = (1.0 - frac_lost) * 0.90
      else
        frac_sens = (1.0 - frac_lost) * 0.80
      end
      frac_lat = 1.0 - frac_sens - frac_lost
    else # Internal gains outside unit
      frac_sens = 0.0
      frac_lat = 0.0
    end

    if not runner.nil?
      runner.registerWarning('Negative energy use calculated for cooking range/oven; this may indicate incorrect ENERGY GUIDE label inputs.') if (annual_kwh < 0) || (annual_therm < 0)
    end
    annual_kwh = 0.0 if annual_kwh < 0
    annual_therm = 0.0 if annual_therm < 0

    return annual_kwh, annual_therm, frac_sens, frac_lat
  end

  # Calculates dishwasher annual energy use and daily hot water use.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param dishwasher [HPXML::Dishwasher] The HPXML dishwasher of interest
  # @param is_outside [Boolean] Whether the appliance is located outside the dwelling unit
  # @return [Array<Double, Double, Double, Double>] Annual electricity use (kWh), sensible/latent fractions, hot water use (gal/day)
  def self.calc_dishwasher_energy_gpd(runner, eri_version, hpxml_bldg, dishwasher, is_outside = false)
    nbeds = hpxml_bldg.building_construction.number_of_bedrooms
    n_occ = hpxml_bldg.building_occupancy.number_of_residents
    unit_type = hpxml_bldg.building_construction.residential_facility_type

    if n_occ == 0
      # Operational calculation w/ zero occupants, zero out energy use
      return 0.0, 0.0, 0.0, 0.0
    end

    if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2019A')
      if dishwasher.rated_annual_kwh.nil?
        dishwasher.rated_annual_kwh = calc_dishwasher_annual_kwh_from_ef(dishwasher.energy_factor)
      end
      lcy = dishwasher.label_usage * 52.0
      kwh_per_cyc = ((dishwasher.label_annual_gas_cost * 0.5497 / dishwasher.label_gas_rate - dishwasher.rated_annual_kwh * dishwasher.label_electric_rate * 0.02504 / dishwasher.label_electric_rate) / (dishwasher.label_electric_rate * 0.5497 / dishwasher.label_gas_rate - 0.02504)) / lcy
      if n_occ.nil? # Asset calculation
        if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('latest') # FIXME: Change from 'latest' when incorporated in 301 standard
          # RESNET HERS Addendum 81 Eq. 4.2-36a
          if unit_type == HPXML::ResidentialTypeApartment
            scy = 135.7 + 13.5 * nbeds
          else
            scy = 123.7 + 16.2 * nbeds
          end
        else
          scy = 88.4 + 34.9 * nbeds
        end
      else # Operational calculation
        scy = 91.0 + 30.0 * n_occ # Eq. 3 from http://www.fsec.ucf.edu/en/publications/pdf/fsec-pf-464-15.pdf
      end
      dwcpy = scy * (12.0 / dishwasher.place_setting_capacity)
      annual_kwh = kwh_per_cyc * dwcpy

      gpd = (dishwasher.rated_annual_kwh - kwh_per_cyc * lcy) * 0.02504 * dwcpy / 365.0
    else
      if dishwasher.energy_factor.nil?
        dishwasher.energy_factor = calc_dishwasher_ef_from_annual_kwh(dishwasher.rated_annual_kwh)
      end
      dwcpy = (88.4 + 34.9 * nbeds) * (12.0 / dishwasher.place_setting_capacity)
      annual_kwh = ((86.3 + 47.73 / dishwasher.energy_factor) / 215.0) * dwcpy

      if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2014A')
        gpd = dwcpy * (4.6415 * (1.0 / dishwasher.energy_factor) - 1.9295) / 365.0
      else
        gpd = ((88.4 + 34.9 * nbeds) * 8.16 - (88.4 + 34.9 * nbeds) * 12.0 / dishwasher.place_setting_capacity * (4.6415 * (1.0 / dishwasher.energy_factor) - 1.9295)) / 365.0
      end
    end

    annual_kwh *= dishwasher.usage_multiplier
    gpd *= dishwasher.usage_multiplier

    if not is_outside
      frac_lost = 0.40
      frac_sens = (1.0 - frac_lost) * 0.50
      frac_lat = 1.0 - frac_sens - frac_lost
    else # Internal gains outside unit
      frac_sens = 0.0
      frac_lat = 0.0
    end

    if not runner.nil?
      runner.registerWarning('Negative energy use calculated for dishwasher; this may indicate incorrect ENERGY GUIDE label inputs.') if annual_kwh < 0
      runner.registerWarning('Negative hot water use calculated for dishwasher; this may indicate incorrect ENERGY GUIDE label inputs.') if gpd < 0
    end
    annual_kwh = 0.0 if annual_kwh < 0
    gpd = 0.0 if gpd < 0

    return annual_kwh, frac_sens, frac_lat, gpd
  end

  # Calculates dishwasher rated energy factor (EF) from annual use (kWh).
  #
  # Source: ANSI/RESNET/ICC 301
  #
  # @param annual_kwh [Double] Rated annual kWh
  # @return [Double] Energy factor
  def self.calc_dishwasher_ef_from_annual_kwh(annual_kwh)
    return 215.0 / annual_kwh
  end

  # Calculates dishwasher annual use (kWh) from rated energy factor (EF).
  #
  # Source: ANSI/RESNET/ICC 301
  #
  # @param ef [Double] Energy factor
  # @return [Double] Rated annual use (kWh)
  def self.calc_dishwasher_annual_kwh_from_ef(ef)
    return 215.0 / ef
  end

  # Calculates clothes dryer annual energy use.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param clothes_dryer [HPXML::ClothesDryer] The HPXML clothes dryer of interest
  # @param clothes_washer [HPXML::ClothesWasher] The related HPXML clothes washer, which affects dryer use
  # @param is_outside [Boolean] Whether the appliance is located outside the dwelling unit
  # @return [Array<Double, Double, Double, Double>] Annual electricity use (kWh), annual fuel use (therm), sensible/latent fractions
  def self.calc_clothes_dryer_energy(runner, eri_version, hpxml_bldg, clothes_dryer, clothes_washer, is_outside = false)
    nbeds = hpxml_bldg.building_construction.number_of_bedrooms
    n_occ = hpxml_bldg.building_occupancy.number_of_residents
    unit_type = hpxml_bldg.building_construction.residential_facility_type

    if n_occ == 0
      # Operational calculation w/ zero occupants, zero out energy use
      return 0.0, 0.0, 0.0, 0.0
    end

    if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2019A')
      if clothes_dryer.combined_energy_factor.nil?
        clothes_dryer.combined_energy_factor = calc_clothes_dryer_cef_from_ef(clothes_dryer.energy_factor)
      end
      if clothes_washer.integrated_modified_energy_factor.nil?
        clothes_washer.integrated_modified_energy_factor = calc_clothes_washer_imef_from_mef(clothes_washer.modified_energy_factor)
      end
      rmc = (0.97 * (clothes_washer.capacity / clothes_washer.integrated_modified_energy_factor) - clothes_washer.rated_annual_kwh / 312.0) / ((2.0104 * clothes_washer.capacity + 1.4242) * 0.455) + 0.04
      if n_occ.nil? # Asset calculation
        if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('latest') # FIXME: Change from 'latest' when incorporated in 301 standard
          # RESNET HERS Addendum 81 Eq. 4.2-34
          if unit_type == HPXML::ResidentialTypeApartment
            scy = 213.9 + 27.5 * nbeds
          else
            scy = 189.5 + 32.9 * nbeds
          end
        else
          scy = 164.0 + 46.5 * nbeds
        end
      else # Operational calculation
        scy = 123.0 + 61.0 * n_occ # Eq. 1 from http://www.fsec.ucf.edu/en/publications/pdf/fsec-pf-464-15.pdf
      end
      acy = scy * ((3.0 * 2.08 + 1.59) / (clothes_washer.capacity * 2.08 + 1.59))
      annual_kwh = (((rmc - 0.04) * 100) / 55.5) * (8.45 / clothes_dryer.combined_energy_factor) * acy
      if clothes_dryer.fuel_type == HPXML::FuelTypeElectricity
        annual_therm = 0.0
      else
        annual_therm = annual_kwh * 3412.0 * (1.0 - 0.07) * (3.73 / 3.30) / 100000
        annual_kwh = annual_kwh * 0.07 * (3.73 / 3.30)
      end
    else
      if clothes_dryer.energy_factor.nil?
        clothes_dryer.energy_factor = calc_clothes_dryer_ef_from_cef(clothes_dryer.combined_energy_factor)
      end
      if clothes_washer.modified_energy_factor.nil?
        clothes_washer.modified_energy_factor = calc_clothes_washer_mef_from_imef(clothes_washer.integrated_modified_energy_factor)
      end
      if clothes_dryer.control_type == HPXML::ClothesDryerControlTypeTimer
        field_util_factor = 1.18
      elsif clothes_dryer.control_type == HPXML::ClothesDryerControlTypeMoisture
        field_util_factor = 1.04
      end
      if clothes_dryer.fuel_type == HPXML::FuelTypeElectricity
        annual_kwh = 12.5 * (164.0 + 46.5 * nbeds) * (field_util_factor / clothes_dryer.energy_factor) * ((clothes_washer.capacity / clothes_washer.modified_energy_factor) - clothes_washer.rated_annual_kwh / 392.0) / (0.2184 * (clothes_washer.capacity * 4.08 + 0.24))
        annual_therm = 0.0
      else
        annual_kwh = 12.5 * (164.0 + 46.5 * nbeds) * (field_util_factor / 3.01) * ((clothes_washer.capacity / clothes_washer.modified_energy_factor) - clothes_washer.rated_annual_kwh / 392.0) / (0.2184 * (clothes_washer.capacity * 4.08 + 0.24))
        annual_therm = annual_kwh * 3412.0 * (1.0 - 0.07) * (3.01 / clothes_dryer.energy_factor) / 100000
        annual_kwh = annual_kwh * 0.07 * (3.01 / clothes_dryer.energy_factor)
      end
    end

    annual_kwh *= clothes_dryer.usage_multiplier
    annual_therm *= clothes_dryer.usage_multiplier

    if not is_outside
      frac_lost = 0.0
      if clothes_dryer.is_vented
        frac_lost = 0.85
      end
      frac_sens = (1.0 - frac_lost) * 0.90
      frac_lat = 1.0 - frac_sens - frac_lost
    else # Internal gains outside unit
      frac_sens = 0.0
      frac_lat = 0.0
    end

    if not runner.nil?
      runner.registerWarning('Negative energy use calculated for clothes dryer; this may indicate incorrect ENERGY GUIDE label inputs.') if (annual_kwh < 0) || (annual_therm < 0)
    end
    annual_kwh = 0.0 if annual_kwh < 0
    annual_therm = 0.0 if annual_therm < 0

    return annual_kwh, annual_therm, frac_sens, frac_lat
  end

  # Calculates clothes dryer combined energy factor (CEF) from energy factor (EF).
  #
  # Source: RESNET's Interpretation on Clothes Dryer CEF
  # https://www.resnet.us/wp-content/uploads/No.-301-2014-10-Section-4.2.2.5.2.8-Clothes-Dryer-CEF-Rating.pdf
  # Note that this is a regression based on products on the market, not a conversion.
  #
  # @param ef [Double] Energy factor
  # @return [Double] Combined energy factor
  def self.calc_clothes_dryer_cef_from_ef(ef)
    return ef / 1.15
  end

  # Calculates clothes dryer energy factor (EF) from combined energy factor (CEF).
  #
  # Source: RESNET's Interpretation on Clothes Dryer CEF
  # https://www.resnet.us/wp-content/uploads/No.-301-2014-10-Section-4.2.2.5.2.8-Clothes-Dryer-CEF-Rating.pdf
  # Note that this is a regression based on products on the market, not a conversion.
  #
  # @param cef [Double] Combined energy factor
  # @return [Double] Energy factor
  def self.calc_clothes_dryer_ef_from_cef(cef)
    return cef * 1.15 # Interpretation on ANSI/RESNET/ICC 301-2014 Clothes Dryer CEF
  end

  # Calculates clothes washer annual energy use and daily hot water use.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param clothes_washer [HPXML::ClothesWasher] The HPXML clothes washer of interest
  # @param is_outside [Boolean] Whether the appliance is located outside the dwelling unit
  # @return [Array<Double, Double, Double, Double>] Annual electricity use (kWh), sensible/latent fractions, hot water use (gal/day)
  def self.calc_clothes_washer_energy_gpd(runner, eri_version, hpxml_bldg, clothes_washer, is_outside = false)
    nbeds = hpxml_bldg.building_construction.number_of_bedrooms
    n_occ = hpxml_bldg.building_occupancy.number_of_residents
    unit_type = hpxml_bldg.building_construction.residential_facility_type

    if n_occ == 0
      # Operational calculation w/ zero occupants, zero out energy use
      return 0.0, 0.0, 0.0, 0.0
    end

    if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2019A')
      gas_h20 = 0.3914 # (gal/cyc) per (therm/y)
      elec_h20 = 0.0178 # (gal/cyc) per (kWh/y)
      lcy = clothes_washer.label_usage * 52.0 # label cycles per year
      if n_occ.nil? # Asset calculation
        if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('latest') # FIXME: Change from 'latest' when incorporated in 301 standard
          # RESNET HERS Addendum 81 Eq. 4.2-34
          if unit_type == HPXML::ResidentialTypeApartment
            scy = 213.9 + 27.5 * nbeds
          else
            scy = 189.5 + 32.9 * nbeds
          end
        else
          scy = 164.0 + nbeds * 46.5
        end
      else # Operational calculation
        scy = 123.0 + 61.0 * n_occ # Eq. 1 from http://www.fsec.ucf.edu/en/publications/pdf/fsec-pf-464-15.pdf
      end
      acy = scy * ((3.0 * 2.08 + 1.59) / (clothes_washer.capacity * 2.08 + 1.59)) # Annual Cycles per Year
      cw_appl = (clothes_washer.label_annual_gas_cost * gas_h20 / clothes_washer.label_gas_rate - (clothes_washer.rated_annual_kwh * clothes_washer.label_electric_rate) * elec_h20 / clothes_washer.label_electric_rate) / (clothes_washer.label_electric_rate * gas_h20 / clothes_washer.label_gas_rate - elec_h20)
      annual_kwh = cw_appl / lcy * acy

      gpd = (clothes_washer.rated_annual_kwh - cw_appl) * elec_h20 * acy / 365.0
    else
      ncy = (3.0 / 2.874) * (164 + nbeds * 46.5)
      acy = ncy * ((3.0 * 2.08 + 1.59) / (clothes_washer.capacity * 2.08 + 1.59)) # Adjusted Cycles per Year
      annual_kwh = ((clothes_washer.rated_annual_kwh / 392.0) - ((clothes_washer.rated_annual_kwh * clothes_washer.label_electric_rate - clothes_washer.label_annual_gas_cost) / (21.9825 * clothes_washer.label_electric_rate - clothes_washer.label_gas_rate) / 392.0) * 21.9825) * acy

      gpd = 60.0 * ((clothes_washer.rated_annual_kwh * clothes_washer.label_electric_rate - clothes_washer.label_annual_gas_cost) / (21.9825 * clothes_washer.label_electric_rate - clothes_washer.label_gas_rate) / 392.0) * acy / 365.0
      if Constants::ERIVersions.index(eri_version) < Constants::ERIVersions.index('2014A')
        gpd -= 3.97 # Section 4.2.2.5.2.10
      end
    end

    annual_kwh *= clothes_washer.usage_multiplier
    gpd *= clothes_washer.usage_multiplier

    if not is_outside
      frac_lost = 0.70
      frac_sens = (1.0 - frac_lost) * 0.90
      frac_lat = 1.0 - frac_sens - frac_lost
    else # Internal gains outside unit
      frac_sens = 0.0
      frac_lat = 0.0
    end

    if not runner.nil?
      runner.registerWarning('Negative energy use calculated for clothes washer; this may indicate incorrect ENERGY GUIDE label inputs.') if annual_kwh < 0
      runner.registerWarning('Negative hot water use calculated for clothes washer; this may indicate incorrect ENERGY GUIDE label inputs.') if gpd < 0
    end
    annual_kwh = 0.0 if annual_kwh < 0
    gpd = 0.0 if gpd < 0

    return annual_kwh, frac_sens, frac_lat, gpd
  end

  # Calculates clothes washer integrated modified energy factor (IMEF) from modified energy factor (MEF).
  #
  # Source: RESNET's Interpretation on Clothes Washer IMEF
  # https://www.resnet.us/wp-content/uploads/No.-301-2014-08-sECTION-4.2.2.5.2.8-Clothes-Washers-Eq-4.2-6.pdf
  # Note that this is a regression based on products on the market, not a conversion.
  #
  # @param mef [Double] Modified energy factor
  # @return [Double] Integrated modified energy factor
  def self.calc_clothes_washer_imef_from_mef(mef)
    return (mef - 0.503) / 0.95
  end

  # Calculates clothes washer modified energy factor (MEF) from integrated modified energy factor (IMEF).
  #
  # Source: RESNET's Interpretation on Clothes Washer IMEF
  # https://www.resnet.us/wp-content/uploads/No.-301-2014-08-sECTION-4.2.2.5.2.8-Clothes-Washers-Eq-4.2-6.pdf
  # Note that this is a regression based on products on the market, not a conversion.
  #
  # @param imef [Double] Integrated modified energy factor
  # @return [Double] Modified energy factor
  def self.calc_clothes_washer_mef_from_imef(imef)
    return 0.503 + 0.95 * imef # Interpretation on ANSI/RESNET/ICC 301-2014 Clothes Washer IMEF
  end

  # Calculates refrigerator annual energy use.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param fridge_or_freezer [HPXML::Refrigerator or HPXML::Freezer] The HPXML refrigerator/freezer of interest
  # @param is_outside [Boolean] Whether the appliance is located outside the dwelling unit
  # @return [Array<Double, Double, Double>] Annual electricity use (kWh), sensible/latent fractions
  def self.calc_fridge_or_freezer_energy(runner, fridge_or_freezer, is_outside = false)
    # Get values
    annual_kwh = fridge_or_freezer.rated_annual_kwh
    annual_kwh *= fridge_or_freezer.usage_multiplier
    if not is_outside
      frac_sens = 1.0
      frac_lat = 0.0
    else # Internal gains outside unit
      frac_sens = 0.0
      frac_lat = 0.0
    end

    if not runner.nil?
      runner.registerWarning('Negative energy use calculated for refrigerator; this may indicate incorrect ENERGY GUIDE label inputs.') if annual_kwh < 0
    end
    annual_kwh = 0.0 if annual_kwh < 0

    return annual_kwh, frac_sens, frac_lat
  end

  # Returns an EMS-actuated schedule in which the hourly refrigerator energy use is calculated
  # based on the temperature of the ambient space using the schedule coefficients.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param col_name [String] The column header of the detailed schedule
  # @param obj_name [String] Name for the OpenStudio object
  # @param fridge_or_freezer [HPXML::Refrigerator or HPXML::Freezer] The HPXML refrigerator/freezer of interest
  # @param loc_space [OpenStudio::Model::Space] The space where the refrigerator/freezer is located
  # @param loc_schedule [OpenStudio::Model::ScheduleConstant] The temperature schedule for where the refrigerator/freezer is located, if not in a space
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @return [OpenStudio::Model::ScheduleConstant] EMS-actuated refrigerator schedule
  def self.get_fridge_or_freezer_coefficients_schedule(model, col_name, obj_name, fridge_or_freezer, loc_space, loc_schedule, unavailable_periods)
    # Create availability sensor
    if not unavailable_periods.empty?
      avail_sch = ScheduleConstant.new(model, col_name, 1.0, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: unavailable_periods)

      availability_sensor = Model.add_ems_sensor(
        model,
        name: "#{col_name} availability s",
        output_var_or_meter_name: 'Schedule Value',
        key_name: avail_sch.schedule.name
      )
    end

    schedule = Model.add_schedule_constant(
      model,
      name: "#{obj_name} schedule",
      value: nil
    )

    if not loc_space.nil?
      temperature_sensor = Model.add_ems_sensor(
        model,
        name: "#{obj_name} tin s",
        output_var_or_meter_name: 'Zone Mean Air Temperature',
        key_name: loc_space.thermalZone.get.name
      )
    elsif not loc_schedule.nil?
      temperature_sensor = Model.add_ems_sensor(
        model,
        name: "#{obj_name} tin s",
        output_var_or_meter_name: 'Schedule Value',
        key_name: loc_schedule.name
      )
    end

    schedule_actuator = Model.add_ems_actuator(
      name: "#{schedule.name} act",
      model_object: schedule,
      comp_type_and_control: EPlus::EMSActuatorScheduleConstantValue
    )

    constant_coefficients = fridge_or_freezer.constant_coefficients.split(',').map { |i| i.to_f }
    temperature_coefficients = fridge_or_freezer.temperature_coefficients.split(',').map { |i| i.to_f }

    schedule_program = Model.add_ems_program(
      model,
      name: "#{schedule.name} program"
    )
    schedule_program.addLine("Set Tin = #{temperature_sensor.name}*(9.0/5.0)+32.0") # C to F
    schedule_program.addLine("Set #{schedule_actuator.name} = 0")
    constant_coefficients.zip(temperature_coefficients).each_with_index do |constant_temperature, i|
      a, b = constant_temperature
      if i == 0
        line = "If (Hour == #{i})"
      else
        line = "ElseIf (Hour == #{i})"
      end
      line += " && (#{availability_sensor.name} == 1)" if not availability_sensor.nil?
      schedule_program.addLine(line)
      schedule_program.addLine("  Set #{schedule_actuator.name} = (#{a}+#{b}*Tin)")
    end
    schedule_program.addLine('EndIf')

    Model.add_ems_program_calling_manager(
      model,
      name: "#{schedule.name} program calling manager",
      calling_point: 'BeginZoneTimestepAfterInitHeatBalance',
      ems_programs: [schedule_program]
    )

    return schedule
  end

  # Calculates Drain Water Heat Recovery (DWHR) factors.
  #
  # Source: ANSI/RESNET/ICC 301
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [Array<Double, Double, Double, Double, Double>] Effectiveness (frac), fraction of water impacted by DWHR, piping loss coefficient, location factor, fixture factor
  def self.get_dwhr_factors(hpxml_bldg)
    nbeds = hpxml_bldg.building_construction.number_of_bedrooms
    n_occ = hpxml_bldg.building_occupancy.number_of_residents
    unit_type = hpxml_bldg.building_construction.residential_facility_type
    hot_water_distribution = hpxml_bldg.hot_water_distributions[0]
    frac_low_flow_fixtures = calc_frac_low_flow_fixtures(hpxml_bldg)

    if n_occ == 0
      # Operational calculation w/ zero occupants
      nbeds_eq = 0
    else
      nbeds_eq = Defaults.get_equivalent_nbeds(nbeds, n_occ, unit_type)
    end

    # ANSI/RESNET/ICC 301-2022 Eq. 4.2-42

    eff_adj = 1.0 + 0.082 * frac_low_flow_fixtures

    i_frac = 0.56 + 0.015 * nbeds_eq - 0.0004 * nbeds_eq**2 # fraction of hot water use impacted by DWHR

    if hot_water_distribution.system_type == HPXML::DHWDistTypeRecirc
      pLength = hot_water_distribution.recirculation_branch_piping_length
    elsif hot_water_distribution.system_type == HPXML::DHWDistTypeStandard
      pLength = hot_water_distribution.standard_piping_length
    end
    plc = 1 - 0.0002 * pLength # piping loss coefficient

    # Location factors for DWHR placement
    if hot_water_distribution.dwhr_equal_flow
      loc_f = 1.000
    else
      loc_f = 0.777
    end

    # Fixture Factor
    if hot_water_distribution.dwhr_facilities_connected == HPXML::DWHRFacilitiesConnectedAll
      fix_f = 1.0
    elsif hot_water_distribution.dwhr_facilities_connected == HPXML::DWHRFacilitiesConnectedOne
      fix_f = 0.5
    end

    return eff_adj, i_frac, plc, loc_f, fix_f
  end

  # Calculates daily water heater inlet temperatures, which includes an adjustment if
  # there is a drain water heat recovery device.
  #
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [Array<Double>] Daily water heater inlet temperatures (F)
  def self.calc_water_heater_daily_inlet_temperatures(weather, hpxml_bldg)
    hot_water_distribution = hpxml_bldg.hot_water_distributions[0]
    wh_temps_daily = weather.data.MainsDailyTemps.dup
    if (not hot_water_distribution.dwhr_efficiency.nil?)
      # Per ANSI/RESNET/ICC 301
      dwhr_eff_adj, dwhr_iFrac, dwhr_plc, dwhr_locF, dwhr_fixF = get_dwhr_factors(hpxml_bldg)
      # Adjust inlet temperatures
      dwhr_inT = 97.0 # F
      for day in 0..wh_temps_daily.size - 1
        dwhr_WHinTadj = dwhr_iFrac * (dwhr_inT - wh_temps_daily[day]) * hot_water_distribution.dwhr_efficiency * dwhr_eff_adj * dwhr_plc * dwhr_locF * dwhr_fixF
        wh_temps_daily[day] = (wh_temps_daily[day] + dwhr_WHinTadj).round(3)
      end
    else
      for day in 0..wh_temps_daily.size - 1
        wh_temps_daily[day] = wh_temps_daily[day].round(3)
      end
    end

    return wh_temps_daily
  end

  # Calculates the daily mixed water adjustment fractions. These fractions convert from
  # gallons of mixed water to gallons of hot water that needs to be served by the water heater.
  #
  # @param daily_wh_inlet_temperatures [Array<Double>] Daily water heater inlet temperatures (F)
  # @param t_set [Double] Water heater setpoint temperature (F)
  # @param t_use [Double] Temperature of mixed water at fixtures (F)
  # @return [Array<Double>] Daily mixed water adjustment fractions
  def self.calc_mixed_water_daily_fractions(daily_wh_inlet_temperatures, t_set, t_use)
    # Per ANSI/RESNET/ICC 301
    adj_f_mix = []
    for day in 0..daily_wh_inlet_temperatures.size - 1
      adj_f_mix << (1.0 - ((t_set - t_use) / (t_set - daily_wh_inlet_temperatures[day]))).round(4)
    end

    return adj_f_mix
  end

  # Calculates annual energy use for a recirculation (or shared recirculation) hot water
  # distribution system.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [Double] Annual electricity use (kWh)
  def self.get_hwdist_recirc_pump_energy(hpxml_bldg)
    nbeds = hpxml_bldg.building_construction.number_of_bedrooms
    hot_water_distribution = hpxml_bldg.hot_water_distributions[0]
    fixtures_usage_multiplier = hpxml_bldg.water_heating.water_fixtures_usage_multiplier

    # Per ANSI/RESNET/ICC 301
    dist_pump_annual_kwh = 0.0

    # Annual electricity consumption factor for hot water recirculation system pumps
    # Assume the fixtures_usage_multiplier only applies for Sensor/Manual control type.
    if hot_water_distribution.system_type == HPXML::DHWDistTypeRecirc
      case hot_water_distribution.recirculation_control_type
      when HPXML::DHWRecircControlTypeNone, HPXML::DHWRecircControlTypeTimer
        dist_pump_annual_kwh += (8.76 * hot_water_distribution.recirculation_pump_power)
      when HPXML::DHWRecircControlTypeTemperature
        dist_pump_annual_kwh += (1.46 * hot_water_distribution.recirculation_pump_power)
      when HPXML::DHWRecircControlTypeSensor
        dist_pump_annual_kwh += (0.15 * hot_water_distribution.recirculation_pump_power * fixtures_usage_multiplier)
      when HPXML::DHWRecircControlTypeManual
        dist_pump_annual_kwh += (0.10 * hot_water_distribution.recirculation_pump_power * fixtures_usage_multiplier)
      else
        fail "Unexpected hot water distribution system recirculation type: '#{hot_water_distribution.recirculation_control_type}'."
      end
    elsif hot_water_distribution.system_type == HPXML::DHWDistTypeStandard
      # nop
    else
      fail "Unexpected hot water distribution system type: '#{hot_water_distribution.system_type}'."
    end

    # Shared recirculation system pump energy
    # Assume the fixtures_usage_multiplier only applies for Sensor/Manual control type.
    if hot_water_distribution.has_shared_recirculation
      n_bdeq = hot_water_distribution.shared_recirculation_number_of_bedrooms_served
      case hot_water_distribution.shared_recirculation_control_type
      when HPXML::DHWRecircControlTypeNone, HPXML::DHWRecircControlTypeTimer, HPXML::DHWRecircControlTypeTemperature
        op_hrs = 8760.0
      when HPXML::DHWRecircControlTypeSensor, HPXML::DHWRecircControlTypeManual
        op_hrs = 730.0 * fixtures_usage_multiplier
      else
        fail "Unexpected hot water distribution system shared recirculation type: '#{hot_water_distribution.shared_recirculation_control_type}'."
      end
      shared_pump_kw = UnitConversions.convert(hot_water_distribution.shared_recirculation_pump_power, 'W', 'kW')
      dist_pump_annual_kwh += (shared_pump_kw * op_hrs * [nbeds.to_f, 1.0].max / n_bdeq.to_f)
    end

    return dist_pump_annual_kwh
  end

  # Calculates the fixtures effectiveness due to the presence of low-flow fixtures.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [Double] Effectiveness (frac)
  def self.get_fixtures_effectiveness(hpxml_bldg)
    frac_low_flow_fixtures = calc_frac_low_flow_fixtures(hpxml_bldg)

    # ANSI/RESNET/ICC 301 specifies 0.95 if all shower/faucet fixtures are low-flow (<= 2 gal/min)
    f_eff = 1.0 - 0.05 * frac_low_flow_fixtures
    return f_eff
  end

  # Calculates water fixtures mixed (not hot) water use.
  #
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param daily_mw_fractions [Array<Double>] Daily mixed water adjustment fractions
  # @return [Double] Mixed water use (gal/day)
  def self.get_fixtures_gpd(eri_version, hpxml_bldg, daily_mw_fractions)
    nbeds = hpxml_bldg.building_construction.number_of_bedrooms
    n_occ = hpxml_bldg.building_occupancy.number_of_residents
    unit_type = hpxml_bldg.building_construction.residential_facility_type
    fixtures_usage_multiplier = hpxml_bldg.water_heating.water_fixtures_usage_multiplier

    if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2014A')
      if n_occ.nil? # Asset calculation
        if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('latest') # FIXME: Change from 'latest' when incorporated in 301 standard
          # RESNET HERS Addendum 90f Eq. 4.2-29 (refFgpd)
          if unit_type == HPXML::ResidentialTypeApartment
            ref_f_gpd = 21.75 + 8.46 * nbeds
          else
            ref_f_gpd = 14.36 + 10.17 * nbeds
          end
        else
          ref_f_gpd = 14.6 + 10.0 * nbeds
        end
      else # Operational calculation
        ref_f_gpd = [-4.84 + 18.6 * n_occ, 0.0].max # Eq. 14 from http://www.fsec.ucf.edu/en/publications/pdf/fsec-pf-464-15.pdf
      end
      f_eff = get_fixtures_effectiveness(hpxml_bldg)
      return f_eff * ref_f_gpd * fixtures_usage_multiplier
    else
      hw_gpd = 30.0 + 10.0 * nbeds # Table 4.2.2(1) Service water heating systems
      # Convert to mixed water gpd
      avg_mw_fraction = daily_mw_fractions.reduce(:+) / daily_mw_fractions.size.to_f
      return hw_gpd / avg_mw_fraction * fixtures_usage_multiplier
    end
  end

  # Calculates the equivalent daily mixed (not hot) water use associated with the distribution system.
  #
  # Source: ANSI/RESNET/ICC 301
  #
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [Double] Mixed water use (gal/day)
  def self.get_dist_waste_gpd(eri_version, hpxml_bldg)
    nbeds = hpxml_bldg.building_construction.number_of_bedrooms
    unit_type = hpxml_bldg.building_construction.residential_facility_type
    has_uncond_bsmnt = hpxml_bldg.has_location(HPXML::LocationBasementUnconditioned)
    has_cond_bsmnt = hpxml_bldg.has_location(HPXML::LocationBasementConditioned)
    cfa = hpxml_bldg.building_construction.conditioned_floor_area
    ncfl = hpxml_bldg.building_construction.number_of_conditioned_floors
    n_occ = hpxml_bldg.building_occupancy.number_of_residents
    fixtures_usage_multiplier = hpxml_bldg.water_heating.water_fixtures_usage_multiplier
    hot_water_distribution = hpxml_bldg.hot_water_distributions[0]

    if Constants::ERIVersions.index(eri_version) <= Constants::ERIVersions.index('2014')
      return 0.0
    end

    # ANSI/RESNET/ICC 301-2022 Section 4.2.2.7.1.4

    # Table 4.2.2.7.2.11(2) Hot Water Distribution System Insulation Factors
    sys_factor = nil
    case hot_water_distribution.system_type
    when HPXML::DHWDistTypeRecirc
      if hot_water_distribution.pipe_r_value < 3.0
        sys_factor = 1.11
      elsif hot_water_distribution.pipe_r_value >= 3.0
        sys_factor = 1.0
      end
    when HPXML::DHWDistTypeStandard
      if hot_water_distribution.pipe_r_value >= 3.0
        sys_factor = 0.90
      elsif hot_water_distribution.pipe_r_value < 3.0
        sys_factor = 1.0
      end
    end

    if n_occ.nil? # Asset calculation
      if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('latest') # FIXME: Change from 'latest' when incorporated in 301 standard
        # RESNET HERS Addendum 81 Eq. 4.2-29 (refWgpd)
        if unit_type == HPXML::ResidentialTypeApartment
          ref_w_gpd = 11.27 * (nbeds**0.323)
        else
          ref_w_gpd = 9.95 * (nbeds**0.399)
        end
      else
        ref_w_gpd = 9.8 * (nbeds**0.43)
      end
    else # Operational calculation
      ref_w_gpd = 7.16 * (n_occ**0.7) # Eq. 14 from http://www.fsec.ucf.edu/en/publications/pdf/fsec-pf-464-15.pdf
    end
    o_frac = 0.25
    o_cd_eff = 0.0

    case hot_water_distribution.system_type
    when HPXML::DHWDistTypeRecirc
      p_ratio = hot_water_distribution.recirculation_branch_piping_length / 10.0
    when HPXML::DHWDistTypeStandard
      ref_pipe_l = Defaults.get_std_pipe_length(has_uncond_bsmnt, has_cond_bsmnt, cfa, ncfl)
      p_ratio = hot_water_distribution.standard_piping_length / ref_pipe_l
    end

    o_w_gpd = ref_w_gpd * o_frac * (1.0 - o_cd_eff) # Eq. 4.2-12
    s_w_gpd = (ref_w_gpd - ref_w_gpd * o_frac) * p_ratio * sys_factor # Eq. 4.2-13

    # Table 4.2.2.5.2.11(3) Distribution system water use effectiveness
    case hot_water_distribution.system_type
    when HPXML::DHWDistTypeRecirc
      wd_eff = 0.1
    when HPXML::DHWDistTypeStandard
      wd_eff = 1.0
    end

    f_eff = get_fixtures_effectiveness(hpxml_bldg)

    mw_gpd = f_eff * (o_w_gpd + s_w_gpd * wd_eff) # Eq. 4.2-11

    return mw_gpd * fixtures_usage_multiplier
  end

  # Calculates the fraction of low-flow fixtures.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [Double] Fraction of fixtures that are low-flow
  def self.calc_frac_low_flow_fixtures(hpxml_bldg)
    fixtures = hpxml_bldg.water_fixtures.select { |wf| [HPXML::WaterFixtureTypeShowerhead, HPXML::WaterFixtureTypeFaucet].include? wf.water_fixture_type }

    return 0.0 if fixtures.empty?

    if fixtures.any? { |wf| wf.count.nil? }
      # We don't know how many fixtures there are; assume 40% are showerheads and 60% are faucets.
      showerheads = fixtures.select { |wf| wf.water_fixture_type == HPXML::WaterFixtureTypeShowerhead }
      if showerheads.size > 0
        frac_low_flow_showerheads = showerheads.count { |wf| wf.low_flow } / Float(showerheads.size)
      else
        frac_low_flow_showerheads = 0.0
      end
      faucets = fixtures.select { |wf| wf.water_fixture_type == HPXML::WaterFixtureTypeFaucet }
      if faucets.size > 0
        frac_low_flow_faucets = faucets.count { |wf| wf.low_flow } / Float(faucets.size)
      else
        frac_low_flow_faucets = 0.0
      end
      return 0.4 * frac_low_flow_showerheads + 0.6 * frac_low_flow_faucets
    else
      num_wfs = fixtures.map { |wf| wf.count }.sum
      num_low_flow_wfs = fixtures.select { |wf| wf.low_flow }.map { |wf| wf.count }.sum
      return num_low_flow_wfs / num_wfs
    end
  end
end
