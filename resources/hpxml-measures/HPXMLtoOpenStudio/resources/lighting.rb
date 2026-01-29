# frozen_string_literal: true

# Collection of methods related to lighting.
module Lighting
  # Adds any HPXML Lighting Groups and Lighting to the OpenStudio model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def self.apply(runner, model, spaces, hpxml_bldg, hpxml_header, schedules_file)
    lighting_groups = hpxml_bldg.lighting_groups
    lighting = hpxml_bldg.lighting
    unit_multiplier = hpxml_bldg.building_construction.number_of_units
    cfa = hpxml_bldg.building_construction.conditioned_floor_area
    eri_version = hpxml_header.eri_calculation_versions[0]
    n_occ = hpxml_bldg.building_occupancy.number_of_residents

    ltg_locns = [HPXML::LocationInterior, HPXML::LocationExterior, HPXML::LocationGarage]
    ltg_types = [HPXML::LightingTypeCFL, HPXML::LightingTypeLFL, HPXML::LightingTypeLED]

    kwhs_per_year = {}
    fractions = {}
    lighting_groups.each do |lg|
      if ltg_locns.include?(lg.location) && (not lg.kwh_per_year.nil?)
        kwhs_per_year[lg.location] = lg.kwh_per_year
      elsif ltg_locns.include?(lg.location) && ltg_types.include?(lg.lighting_type) && (not lg.fraction_of_units_in_location.nil?)
        fractions[[lg.location, lg.lighting_type]] = lg.fraction_of_units_in_location
      end
    end

    # Calculate interior lighting kWh/yr
    int_kwh = kwhs_per_year[HPXML::LocationInterior]
    if int_kwh.nil?
      int_kwh = calc_interior_energy(eri_version, cfa,
                                     fractions[[HPXML::LocationInterior, HPXML::LightingTypeCFL]],
                                     fractions[[HPXML::LocationInterior, HPXML::LightingTypeLFL]],
                                     fractions[[HPXML::LocationInterior, HPXML::LightingTypeLED]])
    end
    int_kwh = 0.0 if int_kwh.nil? || n_occ == 0
    int_kwh *= lighting.interior_usage_multiplier unless lighting.interior_usage_multiplier.nil?

    # Calculate exterior lighting kWh/yr
    ext_kwh = kwhs_per_year[HPXML::LocationExterior]
    if ext_kwh.nil?
      ext_kwh = calc_exterior_energy(eri_version, cfa,
                                     fractions[[HPXML::LocationExterior, HPXML::LightingTypeCFL]],
                                     fractions[[HPXML::LocationExterior, HPXML::LightingTypeLFL]],
                                     fractions[[HPXML::LocationExterior, HPXML::LightingTypeLED]])
    end
    ext_kwh = 0.0 if ext_kwh.nil? || n_occ == 0
    ext_kwh *= lighting.exterior_usage_multiplier unless lighting.exterior_usage_multiplier.nil?
    ext_kwh *= unit_multiplier # Not in a thermal zone, so needs to be explicitly multiplied

    # Calculate garage lighting kWh/yr
    gfa = 0 # Garage floor area
    if spaces.keys.include? HPXML::LocationGarage
      gfa = UnitConversions.convert(spaces[HPXML::LocationGarage].floorArea, 'm^2', 'ft^2')
    end
    if gfa > 0
      grg_kwh = kwhs_per_year[HPXML::LocationGarage]
      if grg_kwh.nil?

        grg_kwh = calc_garage_energy(eri_version, gfa,
                                     fractions[[HPXML::LocationGarage, HPXML::LightingTypeCFL]],
                                     fractions[[HPXML::LocationGarage, HPXML::LightingTypeLFL]],
                                     fractions[[HPXML::LocationGarage, HPXML::LightingTypeLED]])
      end
    end
    grg_kwh = 0.0 if grg_kwh.nil? || n_occ == 0
    grg_kwh *= lighting.garage_usage_multiplier unless lighting.garage_usage_multiplier.nil?

    # Add lighting to conditioned space
    if int_kwh > 0

      # Create schedule
      interior_sch = nil
      interior_col_name = SchedulesFile::Columns[:LightingInterior].name
      interior_obj_name = Constants::ObjectTypeLightingInterior
      if not schedules_file.nil?
        design_level = schedules_file.calc_design_level_from_annual_kwh(col_name: interior_col_name, annual_kwh: int_kwh)
        interior_sch = schedules_file.create_schedule_file(model, col_name: interior_col_name)
      end
      if interior_sch.nil?
        interior_unavailable_periods = Schedule.get_unavailable_periods(runner, interior_col_name, hpxml_header.unavailable_periods)
        interior_sch = MonthWeekdayWeekendSchedule.new(model, interior_obj_name + ' schedule', lighting.interior_weekday_fractions, lighting.interior_weekend_fractions, lighting.interior_monthly_multipliers, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: interior_unavailable_periods)
        design_level = interior_sch.calc_design_level_from_daily_kwh(int_kwh / 365.0)
        interior_sch = interior_sch.schedule
      else
        runner.registerWarning("Both '#{interior_col_name}' schedule file and weekday fractions provided; the latter will be ignored.") if !lighting.interior_weekday_fractions.nil?
        runner.registerWarning("Both '#{interior_col_name}' schedule file and weekend fractions provided; the latter will be ignored.") if !lighting.interior_weekend_fractions.nil?
        runner.registerWarning("Both '#{interior_col_name}' schedule file and monthly multipliers provided; the latter will be ignored.") if !lighting.interior_monthly_multipliers.nil?
      end

      Model.add_lights(
        model,
        name: interior_obj_name,
        end_use: interior_obj_name,
        space: spaces[HPXML::LocationConditionedSpace],
        design_level: design_level,
        schedule: interior_sch
      )
    end

    # Add lighting to garage space
    if grg_kwh > 0

      # Create schedule
      garage_sch = nil
      garage_col_name = SchedulesFile::Columns[:LightingGarage].name
      garage_obj_name = Constants::ObjectTypeLightingGarage
      if not schedules_file.nil?
        design_level = schedules_file.calc_design_level_from_annual_kwh(col_name: garage_col_name, annual_kwh: grg_kwh)
        garage_sch = schedules_file.create_schedule_file(model, col_name: garage_col_name)
      end
      if garage_sch.nil?
        garage_unavailable_periods = Schedule.get_unavailable_periods(runner, garage_col_name, hpxml_header.unavailable_periods)
        garage_sch = MonthWeekdayWeekendSchedule.new(model, garage_obj_name + ' schedule', lighting.garage_weekday_fractions, lighting.garage_weekend_fractions, lighting.garage_monthly_multipliers, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: garage_unavailable_periods)
        design_level = garage_sch.calc_design_level_from_daily_kwh(grg_kwh / 365.0)
        garage_sch = garage_sch.schedule
      else
        runner.registerWarning("Both '#{garage_col_name}' schedule file and weekday fractions provided; the latter will be ignored.") if !lighting.garage_weekday_fractions.nil?
        runner.registerWarning("Both '#{garage_col_name}' schedule file and weekend fractions provided; the latter will be ignored.") if !lighting.garage_weekend_fractions.nil?
        runner.registerWarning("Both '#{garage_col_name}' schedule file and monthly multipliers provided; the latter will be ignored.") if !lighting.garage_monthly_multipliers.nil?
      end

      Model.add_lights(
        model,
        name: garage_obj_name,
        end_use: garage_obj_name,
        space: spaces[HPXML::LocationGarage],
        design_level: design_level,
        schedule: garage_sch
      )
    end

    # Add exterior lighting
    if ext_kwh > 0

      # Create schedule
      exterior_sch = nil
      exterior_col_name = SchedulesFile::Columns[:LightingExterior].name
      exterior_obj_name = Constants::ObjectTypeLightingExterior
      if not schedules_file.nil?
        design_level = schedules_file.calc_design_level_from_annual_kwh(col_name: exterior_col_name, annual_kwh: ext_kwh)
        exterior_sch = schedules_file.create_schedule_file(model, col_name: exterior_col_name)
      end
      if exterior_sch.nil?
        exterior_unavailable_periods = Schedule.get_unavailable_periods(runner, exterior_col_name, hpxml_header.unavailable_periods)
        exterior_sch = MonthWeekdayWeekendSchedule.new(model, exterior_obj_name + ' schedule', lighting.exterior_weekday_fractions, lighting.exterior_weekend_fractions, lighting.exterior_monthly_multipliers, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: exterior_unavailable_periods)
        design_level = exterior_sch.calc_design_level_from_daily_kwh(ext_kwh / 365.0)
        exterior_sch = exterior_sch.schedule
      else
        runner.registerWarning("Both '#{exterior_col_name}' schedule file and weekday fractions provided; the latter will be ignored.") if !lighting.exterior_weekday_fractions.nil?
        runner.registerWarning("Both '#{exterior_col_name}' schedule file and weekend fractions provided; the latter will be ignored.") if !lighting.exterior_weekend_fractions.nil?
        runner.registerWarning("Both '#{exterior_col_name}' schedule file and monthly multipliers provided; the latter will be ignored.") if !lighting.exterior_monthly_multipliers.nil?
      end

      Model.add_lights(
        model,
        name: exterior_obj_name,
        end_use: exterior_obj_name,
        space: nil,
        design_level: design_level,
        schedule: exterior_sch
      )
    end

    # Add exterior holiday lighting
    if not lighting.holiday_kwh_per_day.nil?

      # Create schedule
      exterior_holiday_sch = nil
      exterior_holiday_col_name = SchedulesFile::Columns[:LightingExteriorHoliday].name
      exterior_holiday_obj_name = Constants::ObjectTypeLightingExteriorHoliday
      exterior_holiday_kwh_per_day = lighting.holiday_kwh_per_day * unit_multiplier
      if not schedules_file.nil?
        design_level = schedules_file.calc_design_level_from_daily_kwh(col_name: exterior_holiday_col_name, daily_kwh: exterior_holiday_kwh_per_day)
        exterior_holiday_sch = schedules_file.create_schedule_file(model, col_name: exterior_holiday_col_name)
      end
      if exterior_holiday_sch.nil?
        exterior_holiday_unavailable_periods = Schedule.get_unavailable_periods(runner, exterior_holiday_col_name, hpxml_header.unavailable_periods)
        exterior_holiday_sch = MonthWeekdayWeekendSchedule.new(model, exterior_holiday_obj_name + ' schedule', lighting.holiday_weekday_fractions, lighting.holiday_weekend_fractions, lighting.exterior_monthly_multipliers, EPlus::ScheduleTypeLimitsFraction, true, lighting.holiday_period_begin_month, lighting.holiday_period_begin_day, lighting.holiday_period_end_month, lighting.holiday_period_end_day, unavailable_periods: exterior_holiday_unavailable_periods)
        design_level = exterior_holiday_sch.calc_design_level_from_daily_kwh(exterior_holiday_kwh_per_day)
        exterior_holiday_sch = exterior_holiday_sch.schedule
      else
        runner.registerWarning("Both '#{exterior_holiday_col_name}' schedule file and weekday fractions provided; the latter will be ignored.") if !lighting.holiday_weekday_fractions.nil?
        runner.registerWarning("Both '#{exterior_holiday_col_name}' schedule file and weekend fractions provided; the latter will be ignored.") if !lighting.holiday_weekend_fractions.nil?
        runner.registerWarning("Both '#{exterior_holiday_col_name}' schedule file and monthly multipliers provided; the latter will be ignored.") if !lighting.exterior_monthly_multipliers.nil?
      end

      Model.add_lights(
        model,
        name: exterior_holiday_obj_name,
        end_use: exterior_holiday_obj_name,
        space: nil,
        design_level: design_level,
        schedule: exterior_holiday_sch
      )
    end
  end

  # Calculates the annual interior lighting energy use based on the conditioned floor area and types of lamps.
  #
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param f_int_cfl [Double] Fraction of interior lighting that is compact fluorescent (CFL)
  # @param f_int_lfl [Double] Fraction of interior lighting that is linear fluorescent (LFL)
  # @param f_int_led [Double] Fraction of interior lighting that is light-emitting diode (LED)
  # @return [Double or nil] Annual interior lighting energy use (kWh/yr)
  def self.calc_interior_energy(eri_version, cfa, f_int_cfl, f_int_lfl, f_int_led)
    return if f_int_cfl.nil? || f_int_lfl.nil? || f_int_led.nil?

    if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2014AEG')
      # Calculate fluorescent (CFL + LFL) fraction
      f_int_fl = f_int_cfl + f_int_lfl

      # Calculate incandescent fraction
      f_int_inc = 1.0 - f_int_fl - f_int_led

      # Efficacies (lm/W)
      eff_inc = 15.0
      eff_fl = 60.0
      eff_led = 90.0

      # Efficacy ratios
      eff_ratio_inc = eff_inc / eff_inc
      eff_ratio_fl = eff_inc / eff_fl
      eff_ratio_led = eff_inc / eff_led

      # Efficiency lighting adjustment
      int_adj = (f_int_inc * eff_ratio_inc) + (f_int_fl * eff_ratio_fl) + (f_int_led * eff_ratio_led)

      # Calculate energy use
      int_kwh = (0.9 / 0.925 * (455.0 + 0.8 * cfa) * int_adj) + (0.1 * (455.0 + 0.8 * cfa))
    else
      # Calculate efficient lighting fraction
      fF_int = f_int_cfl + f_int_lfl + f_int_led

      # Calculate energy use
      int_kwh = 0.8 * ((4.0 - 3.0 * fF_int) / 3.7) * (455.0 + 0.8 * cfa) + 0.2 * (455.0 + 0.8 * cfa)
    end

    return int_kwh
  end

  # Calculates the annual exterior lighting energy use based on the conditioned floor area and types of lamps.
  #
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param f_ext_cfl [Double] Fraction of exterior lighting that is compact fluorescent (CFL)
  # @param f_ext_lfl [Double] Fraction of exterior lighting that is linear fluorescent (LFL)
  # @param f_ext_led [Double] Fraction of exterior lighting that is light-emitting diode (LED)
  # @return [Double or nil] Annual exterior lighting energy use (kWh/yr)
  def self.calc_exterior_energy(eri_version, cfa, f_ext_cfl, f_ext_lfl, f_ext_led)
    return if f_ext_cfl.nil? || f_ext_lfl.nil? || f_ext_led.nil?

    if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2014AEG')
      # Calculate fluorescent (CFL + LFL) fraction
      f_ext_fl = f_ext_cfl + f_ext_lfl

      # Calculate incandescent fraction
      f_ext_inc = 1.0 - f_ext_fl - f_ext_led

      # Efficacies (lm/W)
      eff_inc = 15.0
      eff_fl = 60.0
      eff_led = 90.0

      # Efficacy ratios
      eff_ratio_inc = eff_inc / eff_inc
      eff_ratio_fl = eff_inc / eff_fl
      eff_ratio_led = eff_inc / eff_led

      # Efficiency lighting adjustment
      ext_adj = (f_ext_inc * eff_ratio_inc) + (f_ext_fl * eff_ratio_fl) + (f_ext_led * eff_ratio_led)

      # Calculate energy use
      ext_kwh = (100.0 + 0.05 * cfa) * ext_adj
    else
      # Calculate efficient lighting fraction
      fF_ext = f_ext_cfl + f_ext_lfl + f_ext_led

      # Calculate energy use
      ext_kwh = (100.0 + 0.05 * cfa) * (1.0 - fF_ext) + 0.25 * (100.0 + 0.05 * cfa) * fF_ext
    end

    return ext_kwh
  end

  # Calculates the annual garage lighting energy use based on the garage area and types of lamps.
  #
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @param gfa [Double] Garage floor area (ft2)
  # @param f_grg_cfl [Double] Fraction of garage lighting that is compact fluorescent (CFL)
  # @param f_grg_lfl [Double] Fraction of garage lighting that is linear fluorescent (LFL)
  # @param f_grg_led [Double] Fraction of garage lighting that is light-emitting diode (LED)
  # @return [Double or nil] Annual garage lighting energy use (kWh/yr)
  def self.calc_garage_energy(eri_version, gfa, f_grg_cfl, f_grg_lfl, f_grg_led)
    return if f_grg_cfl.nil? || f_grg_lfl.nil? || f_grg_led.nil?

    if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2014AEG')
      # Calculate fluorescent (CFL + LFL) fraction
      f_grg_fl = f_grg_cfl + f_grg_lfl

      # Calculate incandescent fraction
      f_grg_inc = 1.0 - f_grg_fl - f_grg_led

      # Efficacies (lm/W)
      eff_inc = 15.0
      eff_fl = 60.0
      eff_led = 90.0

      # Efficacy ratios
      eff_ratio_inc = eff_inc / eff_inc
      eff_ratio_fl = eff_inc / eff_fl
      eff_ratio_led = eff_inc / eff_led

      # Efficiency lighting adjustment
      grg_adj = (f_grg_inc * eff_ratio_inc) + (f_grg_fl * eff_ratio_fl) + (f_grg_led * eff_ratio_led)

      # Calculate energy use
      grg_kwh = 0.0
      if gfa > 0
        grg_kwh = 100.0 * grg_adj
      end
    else
      # Calculate efficient lighting fraction
      fF_grg = f_grg_cfl + f_grg_lfl + f_grg_led

      # Calculate energy use
      grg_kwh = 0.0
      if gfa > 0
        grg_kwh = 100.0 * (1.0 - fF_grg) + 25.0 * fF_grg
      end
    end

    return grg_kwh
  end
end
