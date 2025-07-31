# frozen_string_literal: true

# Collection of methods for adding vehicle-related OpenStudio objects, built on the Battery class
module Vehicle
  # Adds any HPXML Vehicles to the OpenStudio model.
  # Currently only models electric vehicles.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def self.apply(runner, model, spaces, hpxml_bldg, hpxml_header, schedules_file)
    hpxml_bldg.vehicles.each do |vehicle|
      if vehicle.vehicle_type != HPXML::VehicleTypeBEV
        # Warning issued by Schematron validator
        next
      end

      apply_electric_vehicle(runner, model, spaces, hpxml_bldg, hpxml_header, vehicle, schedules_file)
    end
  end

  # Apply an electric vehicle to the model using the battery.rb Battery class, which assigns OpenStudio ElectricLoadCenterStorageLiIonNMCBattery and ElectricLoadCenterDistribution objects.
  # An EMS program models the effect of ambient temperature on the effective power output, scales power with the fraction charged at home, and calculates the unmet driving hours.
  # Bi-directional charging is not currently implemented
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param vehicle [HPXML::Vehicle] Object that defines a single electric vehicle
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def self.apply_electric_vehicle(runner, model, spaces, hpxml_bldg, hpxml_header, vehicle, schedules_file)
    if hpxml_bldg.plug_loads.any? { |pl| pl.plug_load_type == HPXML::PlugLoadTypeElectricVehicleCharging }
      # Warning issued by Schematron validator
      return
    end

    # Assign charging and vehicle space
    ev_charger = vehicle.ev_charger
    if ev_charger.nil?
      # Warning issued by Schematron validator
      return
    end

    # We don't use the EV/charger location in the HPXML because it doesn't currently affect simulation results.
    # See https://github.com/NREL/OpenStudio-HPXML/pull/1961
    vehicle.additional_properties.location = HPXML::LocationOutside

    if vehicle.fuel_economy_units == HPXML::UnitsKwhPerMile
      kwh_per_mile = vehicle.fuel_economy_combined
    elsif vehicle.fuel_economy_units == HPXML::UnitsMilePerKwh
      kwh_per_mile = 1.0 / vehicle.fuel_economy_combined
    elsif vehicle.fuel_economy_units == HPXML::UnitsMPGe
      kwh_per_mile = 33.705 / vehicle.fuel_economy_combined # Per EPA, one gallon of gasoline is equal to 33.705 kWh
    end
    ev_annl_energy = kwh_per_mile * vehicle.miles_per_year * vehicle.ev_usage_multiplier # kWh/year

    # Create schedule
    charging_schedule, discharging_schedule = nil, nil
    charging_col_name, discharging_col_name = SchedulesFile::Columns[:ElectricVehicleCharging].name, SchedulesFile::Columns[:ElectricVehicleDischarging].name
    if not schedules_file.nil?
      charging_schedule = schedules_file.create_schedule_file(model, col_name: charging_col_name)
      discharging_schedule = schedules_file.create_schedule_file(model, col_name: discharging_col_name)
      eff_discharge_power = schedules_file.calc_design_level_from_daily_kwh(col_name: discharging_schedule.name.to_s, daily_kwh: ev_annl_energy / 365)
    end
    if charging_schedule.nil? && discharging_schedule.nil?
      charging_unavailable_periods = Schedule.get_unavailable_periods(runner, charging_col_name, hpxml_header.unavailable_periods)
      discharging_unavailable_periods = Schedule.get_unavailable_periods(runner, discharging_col_name, hpxml_header.unavailable_periods)
      charge_name, discharge_name = "#{vehicle.id} charging schedule", "#{vehicle.id} discharging schedule"
      weekday_charge, weekday_discharge = Schedule.split_signed_charging_schedule(vehicle.ev_weekday_fractions)
      weekend_charge, weekend_discharge = Schedule.split_signed_charging_schedule(vehicle.ev_weekend_fractions)
      charging_schedule_obj = MonthWeekdayWeekendSchedule.new(model, charge_name, weekday_charge, weekend_charge, vehicle.ev_monthly_multipliers, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: charging_unavailable_periods)
      discharging_schedule_obj = MonthWeekdayWeekendSchedule.new(model, discharge_name, weekday_discharge, weekend_discharge, vehicle.ev_monthly_multipliers, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: discharging_unavailable_periods)
      eff_discharge_power = discharging_schedule_obj.calc_design_level_from_daily_kwh(ev_annl_energy / 365)
      discharging_schedule = discharging_schedule_obj.schedule
      charging_schedule = charging_schedule_obj.schedule
    else
      runner.registerWarning("Both schedule file and weekday fractions provided for '#{SchedulesFile::Columns[:ElectricVehicle].name}'; weekday fractions will be ignored.") if !vehicle.ev_weekday_fractions.nil?
      runner.registerWarning("Both schedule file and weekend fractions provided for '#{SchedulesFile::Columns[:ElectricVehicle].name}'; weekend fractions will be ignored.") if !vehicle.ev_weekend_fractions.nil?
      runner.registerWarning("Both schedule file and monthly multipliers provided for '#{SchedulesFile::Columns[:ElectricVehicle].name}'; monthly multipliers will be ignored.") if !vehicle.ev_monthly_multipliers.nil?
    end

    # Scale the effective discharge power by 2.25 to assign the rated discharge power.
    # This value reflects the maximum power adjustment allowed in the EMS EV discharge program at -17.8 C.
    vehicle.additional_properties.rated_power_output = eff_discharge_power * 2.25

    # Apply vehicle battery to model
    Battery.apply_battery(runner, model, spaces, hpxml_bldg, vehicle, charging_schedule, discharging_schedule)

    # Apply EMS program to adjust discharge power based on ambient temperature.
    model.getElectricLoadCenterStorageLiIonNMCBatterys.each do |elcs|
      next unless elcs.name.to_s.include? vehicle.id

      ev_elcd = model.getElectricLoadCenterDistributions.find { |elcd| elcd.name.to_s.include?(vehicle.id) }
      eff_charge_power = ev_elcd.designStorageControlChargePower
      min_soc = ev_elcd.minimumStorageStateofChargeFraction
      discharging_schedule = ev_elcd.storageDischargePowerFractionSchedule.get
      charging_schedule = ev_elcd.storageChargePowerFractionSchedule.get

      discharge_power_act = Model.add_ems_actuator(
        name: 'battery_discharge_power_act',
        model_object: ev_elcd,
        comp_type_and_control: ['Electrical Storage', 'Power Draw Rate']
      )
      charge_power_act = Model.add_ems_actuator(
        name: 'battery_charge_power_act',
        model_object: ev_elcd,
        comp_type_and_control: ['Electrical Storage', 'Power Charge Rate']
      )
      temp_sensor = Model.add_ems_sensor(
        model,
        name: 'site_temp',
        output_var_or_meter_name: 'Site Outdoor Air Drybulb Temperature',
        key_name: 'Environment'
      )
      discharge_sch_sensor = Model.add_ems_sensor(
        model,
        name: 'discharge_sch_sensor',
        output_var_or_meter_name: 'Schedule Value',
        key_name: discharging_schedule.name.to_s
      )
      charge_sch_sensor = Model.add_ems_sensor(
        model,
        name: 'charge_sch_sensor',
        output_var_or_meter_name: 'Schedule Value',
        key_name: charging_schedule.name.to_s
      )
      soc_sensor = Model.add_ems_sensor(
        model,
        name: 'soc_sensor',
        output_var_or_meter_name: 'Electric Storage Charge Fraction',
        key_name: elcs.name.to_s
      )

      ev_discharge_program = Model.add_ems_program(
        model,
        name: 'ev_discharge_program'
      )
      ev_discharge_program.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeBEVDischargeProgram)

      unmet_hr_var = Model.add_ems_output_variable(
        model,
        name: 'unmet_driving_hours',
        ems_variable_name: 'unmet_driving_hours',
        type_of_data: 'Summed',
        update_frequency: 'SystemTimestep',
        ems_program_or_subroutine: ev_discharge_program,
        units: 'hr'
      )

      # Power adjustment vs ambient temperature curve; derived from most recent data in Figure 9 of https://www.nrel.gov/docs/fy23osti/83916.pdf
      # This adjustment scales power demand based on ambient temperature, and encompasses losses due to battery and space conditioning (i.e., discharging losses), as well as charging losses.
      coefs = [1.412768, -3.910397E-02, 9.408235E-04, 8.971560E-06, -7.699244E-07, 1.265614E-08]
      power_curve = ''
      coefs.each_with_index do |coef, i|
        power_curve += "+(#{coef}*(site_temp_adj^#{i}))"
      end
      power_curve = power_curve[1..]
      ev_discharge_program.addLine("  Set power_mult = #{power_curve}")
      ev_discharge_program.addLine("  Set site_temp_adj = #{temp_sensor.name}")
      ev_discharge_program.addLine("  If #{temp_sensor.name} < #{UnitConversions.convert(0, 'F', 'C').round(3)}")
      ev_discharge_program.addLine("    Set site_temp_adj = #{UnitConversions.convert(0, 'F', 'C').round(3)}")
      ev_discharge_program.addLine("  ElseIf #{temp_sensor.name} > #{UnitConversions.convert(100, 'F', 'C').round(3)}")
      ev_discharge_program.addLine("    Set site_temp_adj = #{UnitConversions.convert(100, 'F', 'C').round(3)}")
      ev_discharge_program.addLine('  EndIf')
      ev_discharge_program.addLine("  If #{discharge_sch_sensor.name} > 0.0")
      ev_discharge_program.addLine("    Set #{discharge_power_act.name} = #{eff_discharge_power} * #{vehicle.fraction_charged_home} * power_mult * #{discharge_sch_sensor.name}")
      ev_discharge_program.addLine("    Set #{charge_power_act.name} = #{eff_charge_power} * #{charge_sch_sensor.name}")
      ev_discharge_program.addLine("    If #{soc_sensor.name} <= #{min_soc}")
      ev_discharge_program.addLine("      Set #{unmet_hr_var.name} = #{discharge_sch_sensor.name}")
      ev_discharge_program.addLine('    Else')
      ev_discharge_program.addLine("      Set #{unmet_hr_var.name} = 0")
      ev_discharge_program.addLine('    EndIf')
      ev_discharge_program.addLine('  Else')
      ev_discharge_program.addLine("    Set #{charge_power_act.name} = #{eff_charge_power} * #{charge_sch_sensor.name}")
      ev_discharge_program.addLine("    Set #{discharge_power_act.name} = 0")
      ev_discharge_program.addLine("    Set #{unmet_hr_var.name} = 0")
      ev_discharge_program.addLine('  EndIf')

      Model.add_ems_program_calling_manager(
        model,
        name: 'ev_discharge_pcm',
        calling_point: 'BeginTimestepBeforePredictor',
        ems_programs: [ev_discharge_program]
      )
    end
  end
end
