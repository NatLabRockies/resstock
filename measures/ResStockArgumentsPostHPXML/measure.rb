# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# Load required dependencies for HVAC flexibility processing
require_relative 'resources/hvac_flexibility/detailed_schedule_generator'
require_relative 'resources/hvac_flexibility/setpoint_modifier'
require_relative 'resources/ev_flexibility/ev_schedule_modifier'
require_relative 'resources/electrical_panel'
require_relative '../ResStockArguments/resources/constants'

# OpenStudio Measure class to process ResStock arguments after HPXML generation
class ResStockArgumentsPostHPXML < OpenStudio::Measure::ModelMeasure
  # Define human readable name
  def name
    'ResStock Arguments Post-HPXML'
  end

  # Brief human readable description of the measure
  def description
    'Measure that post-processes the output of the BuildResidentialHPXML and BuildResidentialScheduleFile measures.'
  end

  # Detailed human readable description of modeling approach
  def modeler_description
    'Passes in all ResStockArgumentsPostHPXML arguments from the options lookup, processes them, and then modifies output of other measures.'
  end

  # Define user input arguments
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    # Allow same arguments as ResStockArguments measure

    full_measure_path = File.join(File.dirname(__FILE__), '..', 'ResStockArguments', 'measure.rb')
    measure_arguments = get_measure_instance(full_measure_path).arguments(model)
    measure_arguments.each do |arg|
      # Convert to optional argument for the unit test
      # Replace all of this if https://github.com/NREL/OpenStudio/issues/5469 is addressed
      case arg.type.valueName.downcase
      when 'choice'
        new_arg = OpenStudio::Measure::OSArgument.makeChoiceArgument(arg.name, arg.choiceValues, false)
        new_arg.setDefaultValue(arg.defaultValueAsString) if arg.hasDefaultValue
      when 'boolean'
        new_arg = OpenStudio::Measure::OSArgument.makeBoolArgument(arg.name, false)
        new_arg.setDefaultValue(arg.defaultValueAsBool) if arg.hasDefaultValue
      when 'string'
        new_arg = OpenStudio::Measure::OSArgument.makeStringArgument(arg.name, false)
        new_arg.setDefaultValue(arg.defaultValueAsString) if arg.hasDefaultValue
      when 'double'
        new_arg = OpenStudio::Measure::OSArgument.makeDoubleArgument(arg.name, false)
        new_arg.setDefaultValue(arg.defaultValueAsDouble) if arg.hasDefaultValue
      when 'integer'
        new_arg = OpenStudio::Measure::OSArgument.makeIntegerArgument(arg.name, false)
        new_arg.setDefaultValue(arg.defaultValueAsInteger) if arg.hasDefaultValue
      else
        fail "Unhandled argument type: #{arg.type.valueName.downcase}"
      end
      new_arg.setDisplayName(arg.displayName.to_s)
      new_arg.setDescription(arg.description.to_s)
      new_arg.setUnits(arg.units.to_s)
      args << new_arg
    end

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hpxml_path', false)
    arg.setDisplayName('HPXML File Path')
    arg.setDescription('Absolute/relative path of the HPXML file.')
    args << arg

    return args
  end

  # Run the measure
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    @runner = runner
    # Use the built-in error checking
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    # Parse user arguments and assign to variables
    args = runner.getArgumentValues(arguments(model), user_arguments)
    args = convert_args(arguments(model), args)
    @args = args

    @hpxml_path = args[:hpxml_path]
    @hpxml_path = File.expand_path(@hpxml_path) unless (Pathname.new @hpxml_path).absolute?
    raise "'#{@hpxml_path}' does not exist or is not an .xml file." unless File.exist?(@hpxml_path) && @hpxml_path.downcase.end_with?('.xml')

    # Load HPXML
    @hpxml = HPXML.new(hpxml_path: @hpxml_path)

    # Weather
    epw_path = Location.get_epw_path(@hpxml.buildings[0], @hpxml_path)
    weather = WeatherFile.new(epw_path: epw_path, runner: nil)
    epw_file = OpenStudio::EpwFile.new(epw_path)
    register_value(runner, 'weather_file_city', epw_file.city)
    register_value(runner, 'weather_file_latitude', epw_file.latitude)
    register_value(runner, 'weather_file_longitude', epw_file.longitude)

    # Software info
    @hpxml.header.software_program_used = 'ResStock'
    @hpxml.header.software_program_version = Version::ResStock_Version

    # Simulation controls
    @hpxml.header.sim_calendar_year = Location.get_sim_calendar_year(args[:simulation_control_run_period_calendar_year], weather)

    # Emissions
    @hpxml.header.emissions_scenarios.clear
    if not args[:emissions_scenario_names].nil?
      args[:emissions_scenario_names].split(',').each_with_index do |emissions_scenario_name, i|
        @hpxml.header.emissions_scenarios.add(
          name: emissions_scenario_name,
          emissions_type: (args[:emissions_types].split(',').map(&:strip)[i] rescue nil),
          elec_units: (args[:emissions_electricity_units].split(',').map(&:strip)[i] rescue nil),
          elec_schedule_filepath: (args[:emissions_electricity_filepaths].split(',').map(&:strip)[i] rescue nil),
          natural_gas_units: (args[:emissions_fossil_fuel_units].split(',').map(&:strip)[i] rescue nil),
          natural_gas_value: (Float(args[:emissions_natural_gas_values].split(',').map(&:strip)[i]) rescue nil),
          propane_units: (args[:emissions_fossil_fuel_units].split(',').map(&:strip)[i] rescue nil),
          propane_value: (Float(args[:emissions_propane_values].split(',').map(&:strip)[i]) rescue nil),
          fuel_oil_units: (args[:emissions_fossil_fuel_units].split(',').map(&:strip)[i] rescue nil),
          fuel_oil_value: (Float(args[:emissions_fuel_oil_values].split(',').map(&:strip)[i]) rescue nil),
          wood_units: (args[:emissions_fossil_fuel_units].split(',').map(&:strip)[i] rescue nil),
          wood_value: (Float(args[:emissions_wood_values].split(',').map(&:strip)[i]) rescue nil)
        )
      end
    end

    # Utility Bills
    @hpxml.header.utility_bill_scenarios.clear
    if not args[:utility_bill_scenario_names].nil?
      args[:utility_bill_scenario_names].split(',').each_with_index do |utility_bill_scenario_name, i|
        pv_compensation_type = (args[:utility_bill_pv_compensation_types].split(',').map(&:strip)[i] rescue nil)
        pv_net_metering_annual_excess_sellback_rate_type = (args[:utility_bill_pv_net_metering_annual_excess_sellback_rate_types].split(',').map(&:strip)[i] rescue nil)
        pv_net_metering_annual_excess_sellback_rate = (Float(args[:utility_bill_pv_net_metering_annual_excess_sellback_rates].split(',').map(&:strip)[i]) rescue nil)
        pv_feed_in_tariff_rate = (Float(args[:utility_bill_pv_feed_in_tariff_rates].split(',').map(&:strip)[i]) rescue nil)
        pv_monthly_grid_connection_fee_unit = (args[:utility_bill_pv_monthly_grid_connection_fee_units].split(',').map(&:strip)[i] rescue nil)
        pv_monthly_grid_connection_fee = (Float(args[:utility_bill_pv_monthly_grid_connection_fees].split(',').map(&:strip)[i]) rescue nil)

        if pv_compensation_type == HPXML::PVCompensationTypeNetMetering
          if pv_net_metering_annual_excess_sellback_rate_type != HPXML::PVAnnualExcessSellbackRateTypeUserSpecified
            pv_net_metering_annual_excess_sellback_rate = nil
          end
          pv_feed_in_tariff_rate = nil
        elsif pv_compensation_type == HPXML::PVCompensationTypeFeedInTariff
          pv_net_metering_annual_excess_sellback_rate_type = nil
          pv_net_metering_annual_excess_sellback_rate = nil
        end

        if pv_monthly_grid_connection_fee_unit == HPXML::UnitsDollarsPerkW
          pv_monthly_grid_connection_fee_dollars_per_kw = pv_monthly_grid_connection_fee
          pv_monthly_grid_connection_fee_dollars = nil
        elsif pv_monthly_grid_connection_fee_unit == HPXML::UnitsDollars
          pv_monthly_grid_connection_fee_dollars = pv_monthly_grid_connection_fee
          pv_monthly_grid_connection_fee_dollars_per_kw = nil
        end

        elec_tariff_filepath = args[:utility_bill_electricity_filepaths].split(',').map(&:strip)[i]
        if (not elec_tariff_filepath.nil?) && elec_tariff_filepath.empty?
          elec_tariff_filepath = nil
        end

        @hpxml.header.utility_bill_scenarios.add(
          name: utility_bill_scenario_name,
          elec_tariff_filepath: elec_tariff_filepath,
          elec_fixed_charge: (Float(args[:utility_bill_electricity_fixed_charges].split(',').map(&:strip)[i]) rescue nil),
          natural_gas_fixed_charge: (Float(args[:utility_bill_natural_gas_fixed_charges].split(',').map(&:strip)[i]) rescue nil),
          propane_fixed_charge: (Float(args[:utility_bill_propane_fixed_charges].split(',').map(&:strip)[i]) rescue nil),
          fuel_oil_fixed_charge: (Float(args[:utility_bill_fuel_oil_fixed_charges].split(',').map(&:strip)[i]) rescue nil),
          wood_fixed_charge: (Float(args[:utility_bill_wood_fixed_charges].split(',').map(&:strip)[i]) rescue nil),
          elec_marginal_rate: (Float(args[:utility_bill_electricity_marginal_rates].split(',').map(&:strip)[i]) rescue nil),
          natural_gas_marginal_rate: (Float(args[:utility_bill_natural_gas_marginal_rates].split(',').map(&:strip)[i]) rescue nil),
          propane_marginal_rate: (Float(args[:utility_bill_propane_marginal_rates].split(',').map(&:strip)[i]) rescue nil),
          fuel_oil_marginal_rate: (Float(args[:utility_bill_fuel_oil_marginal_rates].split(',').map(&:strip)[i]) rescue nil),
          wood_marginal_rate: (Float(args[:utility_bill_wood_marginal_rates].split(',').map(&:strip)[i]) rescue nil),
          pv_compensation_type: pv_compensation_type,
          pv_net_metering_annual_excess_sellback_rate_type: pv_net_metering_annual_excess_sellback_rate_type,
          pv_net_metering_annual_excess_sellback_rate: pv_net_metering_annual_excess_sellback_rate,
          pv_feed_in_tariff_rate: pv_feed_in_tariff_rate,
          pv_monthly_grid_connection_fee_dollars_per_kw: pv_monthly_grid_connection_fee_dollars_per_kw,
          pv_monthly_grid_connection_fee_dollars: pv_monthly_grid_connection_fee_dollars
        )
      end
    end

    # Electric Panel calculations
    @hpxml.header.service_feeders_load_calculation_types = [HPXML::ElectricPanelLoadCalculationType2023ExistingDwellingLoadBased]

    # Vacancy
    vacancy_periods = args[:schedules_vacancy_periods].to_s.split(',').map(&:strip)
    vacancy_periods.each do |vacancy_period|
      begin_month, begin_day, begin_hour, end_month, end_day, end_hour = Calendar.parse_date_time_range(vacancy_period)
      @hpxml.header.unavailable_periods.add(
        column_name: 'Vacancy',
        begin_month: begin_month,
        begin_day: begin_day,
        begin_hour: begin_hour,
        end_month: end_month,
        end_day: end_day,
        end_hour: end_hour
      )
    end

    # Power Outage
    power_outage_periods = args[:schedules_power_outage_periods].to_s.split(',').map(&:strip)
    power_outage_natvent_availabilities = args[:schedules_power_outage_periods_window_natvent_availability].to_s.split(',').map(&:strip)
    power_outage_periods.each_with_index do |power_outage_period, i|
      begin_month, begin_day, begin_hour, end_month, end_day, end_hour = Calendar.parse_date_time_range(power_outage_period)
      @hpxml.header.unavailable_periods.add(
        column_name: 'Power Outage',
        begin_month: begin_month,
        begin_day: begin_day,
        begin_hour: begin_hour,
        end_month: end_month,
        end_day: end_day,
        end_hour: end_hour,
        natvent_availability: (power_outage_natvent_availabilities[i] rescue nil)
      )
    end

    # HVAC Unavailability
    month_names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    if (args[:schedules_space_heating_unavailable_days].to_i > 0) || (args[:schedules_space_cooling_unavailable_days].to_i > 0)
      heating_months, cooling_months, sim_calendar_year = get_heating_and_cooling_seasons(weather)
    end
    [Constants::Heating, Constants::Cooling].each do |htg_or_clg|
      unavailable_days = args["schedules_space_#{htg_or_clg}_unavailable_days".to_sym].to_i
      unavailable_output_name = "#{htg_or_clg}_unavailable_period"
      if unavailable_days <= 0
        register_value(runner, unavailable_output_name, 'Never')
        next
      end

      if unavailable_days < 365 # partial-year unavailability
        months = (htg_or_clg == Constants::Heating ? heating_months : cooling_months)

        if months.sum > 0 # has defined BA heating/cooling months
          begin_month, begin_day, end_month, end_day = Calendar.get_begin_and_end_dates_from_monthly_array(months, sim_calendar_year)
        else # no defined BA heating/cooling months
          if htg_or_clg == Constants::Heating # Dec/Jan/Feb
            begin_month, begin_day, end_month, end_day = 12, 1, 2, 28
            end_day += 1 if Date.leap?(sim_calendar_year)
          elsif htg_or_clg == Constants::Cooling # Jun/Jul/Aug
            begin_month, begin_day, end_month, end_day = 6, 1, 8, 31
          end
        end

        begin_day_num = Calendar.get_day_num_from_month_day(sim_calendar_year, begin_month, begin_day)
        end_day_num = Calendar.get_day_num_from_month_day(sim_calendar_year, end_month, end_day)

        begin_month, begin_day, end_month, end_day = get_begin_end_day_nums(args[:building_id], unavailable_days, begin_day_num, end_day_num, sim_calendar_year)
      else # year-round unavailability
        begin_month, begin_day, end_month, end_day = 1, 1, 12, 31
      end

      @hpxml.header.unavailable_periods.add(
        column_name: "No Space #{htg_or_clg.capitalize}",
        begin_month: begin_month,
        begin_day: begin_day,
        end_month: end_month,
        end_day: end_day
      )

      begin_date = OpenStudio::Date::fromDayOfYear(Calendar.get_day_num_from_month_day(sim_calendar_year, begin_month, begin_day), sim_calendar_year)
      end_date = OpenStudio::Date::fromDayOfYear(Calendar.get_day_num_from_month_day(sim_calendar_year, end_month, end_day), sim_calendar_year)
      date_range = "#{month_names[begin_date.monthOfYear.value - 1]} #{begin_date.dayOfMonth} - #{month_names[end_date.monthOfYear.value - 1]} #{end_date.dayOfMonth}"
      register_value(runner, unavailable_output_name, date_range)
    end

    @hpxml.buildings.each do |hpxml_bldg|
      # Site
      if not args[:site_iecc_zone].nil?
        hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.add(zone: args[:site_iecc_zone],
                                                                 year: 2006)
      end

      # Building Construction
      hpxml_bldg.building_construction.number_of_units_in_building = args[:geometry_building_num_units]
      if not args[:geometry_num_floors_above_grade].nil?
        avg_ceiling_height = hpxml_bldg.building_construction.average_ceiling_height
        n_floors = args[:geometry_num_floors_above_grade]
        if hpxml_bldg.site.vertical_surroundings == HPXML::VerticalSurroundingsBelow
          hpxml_bldg.building_construction.unit_height_above_grade = (n_floors - 1) * avg_ceiling_height
        elsif hpxml_bldg.site.vertical_surroundings == HPXML::VerticalSurroundingsAboveAndBelow
          hpxml_bldg.building_construction.unit_height_above_grade = (n_floors - 1) / 2.0 * avg_ceiling_height
        else
          # default
        end
      end

      # Usage Multipliers
      hpxml_bldg.plug_loads.each do |plug_load|
        if (plug_load.plug_load_type == HPXML::PlugLoadTypeTelevision) && (not args[:misc_plug_loads_television_usage_multiplier].nil?)
          plug_load.usage_multiplier = 1.0 if plug_load.usage_multiplier.nil?
          plug_load.usage_multiplier *= args[:misc_plug_loads_television_usage_multiplier]
        elsif (plug_load.plug_load_type == HPXML::PlugLoadTypeOther) && (not args[:misc_plug_loads_other_usage_multiplier].nil?)
          plug_load.usage_multiplier = 1.0 if plug_load.usage_multiplier.nil?
          plug_load.usage_multiplier *= args[:misc_plug_loads_other_usage_multiplier]
        end
      end
      hpxml_bldg.refrigerators.each do |refrigerator|
        if (refrigerator.primary_indicator || refrigerator.primary_indicator.nil?) && (not args[:refrigerator_usage_multiplier].nil?)
          refrigerator.usage_multiplier = 1.0 if refrigerator.usage_multiplier.nil?
          refrigerator.usage_multiplier *= args[:refrigerator_usage_multiplier]
        elsif (not refrigerator.primary_indicator) && (not args[:extra_refrigerator_usage_multiplier].nil?)
          refrigerator.usage_multiplier = 1.0 if refrigerator.usage_multiplier.nil?
          refrigerator.usage_multiplier *= args[:extra_refrigerator_usage_multiplier]
        end
      end
      if (not hpxml_bldg.clothes_dryers.empty?) && (not args[:clothes_dryer_usage_multiplier].nil?)
        hpxml_bldg.clothes_dryers[0].usage_multiplier = 1.0 if hpxml_bldg.clothes_dryers[0].usage_multiplier.nil?
        hpxml_bldg.clothes_dryers[0].usage_multiplier *= args[:clothes_dryer_usage_multiplier]
      end
      if (not hpxml_bldg.clothes_washers.empty?) && (not args[:clothes_washer_usage_multiplier].nil?)
        hpxml_bldg.clothes_washers[0].usage_multiplier = 1.0 if hpxml_bldg.clothes_washers[0].usage_multiplier.nil?
        hpxml_bldg.clothes_washers[0].usage_multiplier *= args[:clothes_washer_usage_multiplier]
      end
      if (not hpxml_bldg.cooking_ranges.empty?) && (not args[:cooking_range_oven_usage_multiplier].nil?)
        hpxml_bldg.cooking_ranges[0].usage_multiplier = 1.0 if hpxml_bldg.cooking_ranges[0].usage_multiplier.nil?
        hpxml_bldg.cooking_ranges[0].usage_multiplier *= args[:cooking_range_oven_usage_multiplier]
      end
      if (not hpxml_bldg.dishwashers.empty?) && (not args[:dishwasher_usage_multiplier].nil?)
        hpxml_bldg.dishwashers[0].usage_multiplier = 1.0 if hpxml_bldg.dishwashers[0].usage_multiplier.nil?
        hpxml_bldg.dishwashers[0].usage_multiplier *= args[:dishwasher_usage_multiplier]
      end
      if (not hpxml_bldg.freezers.empty?) && (not args[:freezer_usage_multiplier].nil?)
        hpxml_bldg.freezers[0].usage_multiplier = 1.0 if hpxml_bldg.freezers[0].usage_multiplier.nil?
        hpxml_bldg.freezers[0].usage_multiplier *= args[:freezer_usage_multiplier]
      end
      if not hpxml_bldg.lighting_groups.empty?
        if not args[:interior_lighting_usage_multiplier].nil?
          hpxml_bldg.lighting.interior_usage_multiplier = 1.0 if hpxml_bldg.lighting.interior_usage_multiplier.nil?
          hpxml_bldg.lighting.interior_usage_multiplier *= args[:interior_lighting_usage_multiplier]
        end
        if not args[:exterior_lighting_usage_multiplier].nil?
          hpxml_bldg.lighting.exterior_usage_multiplier = 1.0 if hpxml_bldg.lighting.exterior_usage_multiplier.nil?
          hpxml_bldg.lighting.exterior_usage_multiplier *= args[:exterior_lighting_usage_multiplier]
        end
        if (not args[:garage_lighting_usage_multiplier].nil?) && hpxml_bldg.has_location(HPXML::LocationGarage)
          hpxml_bldg.lighting.garage_usage_multiplier = 1.0 if hpxml_bldg.lighting.garage_usage_multiplier.nil?
          hpxml_bldg.lighting.garage_usage_multiplier *= args[:garage_lighting_usage_multiplier]
        end
      end
      if not args[:water_fixtures_usage_multiplier].nil?
        hpxml_bldg.water_heating.water_fixtures_usage_multiplier = 1.0 if hpxml_bldg.water_heating.water_fixtures_usage_multiplier.nil?
        hpxml_bldg.water_heating.water_fixtures_usage_multiplier *= args[:water_fixtures_usage_multiplier]
      end
      if (not args[:pool_pump_usage_multiplier].nil?) && (not hpxml_bldg.pools.empty?)
        hpxml_bldg.pools[0].pump_usage_multiplier = 1.0 if hpxml_bldg.pools[0].pump_usage_multiplier.nil?
        hpxml_bldg.pools[0].pump_usage_multiplier *= args[:pool_pump_usage_multiplier]
      end

      # Ventilation Start Hours
      hpxml_bldg.ventilation_fans.each do |ventilation_fan|
        next unless ventilation_fan.used_for_local_ventilation

        if ventilation_fan.fan_location == HPXML::LocationKitchen && (not args[:kitchen_fans_start_hour].nil?)
          ventilation_fan.start_hour = args[:kitchen_fans_start_hour]
        elsif ventilation_fan.fan_location == HPXML::LocationBath && (not args[:bathroom_fans_start_hour].nil?)
          ventilation_fan.start_hour = args[:bathroom_fans_start_hour]
        end
      end

      # EVs
      hpxml_bldg.vehicles.each do |vehicle|
        next unless vehicle.vehicle_type == HPXML::VehicleTypeBEV

        if not args[:ev_efficiency_percent_increase].nil?
          # Adjust efficiency (in kWh/mile) to reflect a percentage improvement in efficiency.
          vehicle.fuel_economy_combined /= 1 + args[:ev_efficiency_percent_increase]
        end
      end

      # Infiltration - Treat input as total (not exterior only) for attached units
      if [HPXML::ResidentialTypeSFA,
          HPXML::ResidentialTypeApartment].include? hpxml_bldg.building_construction.residential_facility_type
        hpxml_bldg.air_infiltration_measurements[0].infiltration_type = HPXML::InfiltrationTypeUnitTotal
      end

      # Infiltration Reduction
      if not args[:air_leakage_percent_reduction].nil?
        hpxml_bldg.air_infiltration_measurements[0].air_leakage *= (1.0 - args[:air_leakage_percent_reduction] / 100.0)
      end

      # HVAC systems
      hpxml_bldg.heating_systems.each do |heating_system|
        if heating_system.primary_system
          heating_system.heating_capacity = args[:heating_system_heating_capacity] unless args[:heating_system_heating_capacity].nil?
          heating_system.heating_autosizing_factor = args[:heating_system_heating_autosizing_factor] unless args[:heating_system_heating_autosizing_factor].nil?
          heating_system.heating_autosizing_limit = args[:heating_system_heating_autosizing_limit] unless args[:heating_system_heating_autosizing_limit].nil?
          # Faults
          if [HPXML::HVACTypeFurnace].include? heating_system.heating_system_type
            if (not heating_system.distribution_system.nil?) && (not args[:heating_system_rated_cfm_per_ton].nil?) && (not args[:heating_system_actual_cfm_per_ton].nil?)
              heating_system.airflow_defect_ratio = (args[:heating_system_actual_cfm_per_ton] - args[:heating_system_rated_cfm_per_ton]) / args[:heating_system_rated_cfm_per_ton]
            end
          end
          # Shared system
          if ['Baseboard', 'FanCoil'].include? args[:hvac_heating_shared_system]
            heating_system.is_shared_system = true
            heating_system.number_of_units_served = hpxml_bldg.building_construction.number_of_units_in_building
            if args[:hvac_heating_shared_system] == 'FanCoil'
              heating_system.distribution_system.distribution_system_type = HPXML::HVACDistributionTypeAir
              heating_system.distribution_system.air_type = HPXML::AirTypeFanCoil
            end
          end
        else
          # heating_system.heating_system_type = args[:heating_system_2_type] unless args[:heating_system_2_type].nil?
          # heating_system.heating_system_fuel = args[:heating_system_2_fuel] unless args[:heating_system_2_fuel].nil?
          # heating_system.heating_system_efficiency_percent = args[:heating_system_2_heating_efficiency] unless args[:heating_system_2_heating_efficiency].nil?
          heating_system.heating_capacity = args[:heating_system_2_heating_capacity] unless args[:heating_system_2_heating_capacity].nil?
          heating_system.heating_autosizing_factor = args[:heating_system_2_heating_autosizing_factor] unless args[:heating_system_2_heating_autosizing_factor].nil?
          heating_system.heating_autosizing_limit = args[:heating_system_2_heating_autosizing_limit] unless args[:heating_system_2_heating_autosizing_limit].nil?
        end
      end
      hpxml_bldg.cooling_systems.each do |cooling_system|
        cooling_system.cooling_capacity = args[:cooling_system_cooling_capacity] unless args[:cooling_system_cooling_capacity].nil?
        cooling_system.cooling_autosizing_factor = args[:cooling_system_cooling_autosizing_factor] unless args[:cooling_system_cooling_autosizing_factor].nil?
        cooling_system.cooling_autosizing_limit = args[:cooling_system_cooling_autosizing_limit] unless args[:cooling_system_cooling_autosizing_limit].nil?
        # Faults
        if [HPXML::HVACTypeCentralAirConditioner, HPXML::HVACTypeMiniSplitAirConditioner].include? cooling_system.cooling_system_type
          if (not cooling_system.distribution_system.nil?) && (not args[:cooling_system_rated_cfm_per_ton].nil?) && (not args[:cooling_system_actual_cfm_per_ton].nil?)
            cooling_system.airflow_defect_ratio = (args[:cooling_system_actual_cfm_per_ton] - args[:cooling_system_rated_cfm_per_ton]) / args[:cooling_system_rated_cfm_per_ton]
          end
          if (not args[:cooling_system_frac_manufacturer_charge].nil?)
            cooling_system.charge_defect_ratio = args[:cooling_system_frac_manufacturer_charge] - 1.0
          end
        end
        # Detailed performance
        set_hvac_detailed_performance_data('cooling',
                                           cooling_system.cooling_detailed_performance_data,
                                           args[:hvac_perf_data_cooling_outdoor_temperatures],
                                           args[:hvac_perf_data_cooling_min_speed_cops],
                                           args[:hvac_perf_data_cooling_nom_speed_cops],
                                           args[:hvac_perf_data_cooling_max_speed_cops],
                                           args[:hvac_perf_data_cooling_min_speed_capacities],
                                           args[:hvac_perf_data_cooling_nom_speed_capacities],
                                           args[:hvac_perf_data_cooling_max_speed_capacities],
                                           cooling_system.compressor_type)
      end
      hpxml_bldg.heat_pumps.each do |heat_pump|
        heat_pump.heating_capacity = args[:heat_pump_heating_capacity] unless args[:heat_pump_heating_capacity].nil?
        heat_pump.heating_autosizing_factor = args[:heat_pump_heating_autosizing_factor] unless args[:heat_pump_heating_autosizing_factor].nil?
        heat_pump.heating_autosizing_limit = args[:heat_pump_heating_autosizing_limit] unless args[:heat_pump_heating_autosizing_limit].nil?
        # heat_pump.fraction_heat_load_served = args[:heat_pump_fraction_heat_load_served] unless args[:heat_pump_fraction_heat_load_served].nil?
        heat_pump.cooling_capacity = args[:heat_pump_cooling_capacity] unless args[:heat_pump_cooling_capacity].nil?
        heat_pump.cooling_autosizing_factor = args[:heat_pump_cooling_autosizing_factor] unless args[:heat_pump_cooling_autosizing_factor].nil?
        heat_pump.cooling_autosizing_limit = args[:heat_pump_cooling_autosizing_limit] unless args[:heat_pump_cooling_autosizing_limit].nil?
        # heat_pump.backup_type = args[:heat_pump_backup_type] unless args[:heat_pump_backup_type].nil?
        # heat_pump.backup_heating_fuel = args[:heat_pump_backup_fuel] unless args[:heat_pump_backup_fuel].nil?
        # heat_pump.backup_heating_efficiency_percent = args[:heat_pump_backup_heating_efficiency] unless args[:heat_pump_backup_heating_efficiency].nil?
        heat_pump.backup_heating_capacity = args[:heat_pump_backup_heating_capacity] unless args[:heat_pump_backup_heating_capacity].nil?
        heat_pump.backup_heating_autosizing_factor = args[:heat_pump_backup_heating_autosizing_factor] unless args[:heat_pump_backup_heating_autosizing_factor].nil?
        heat_pump.backup_heating_autosizing_limit = args[:heat_pump_backup_heating_autosizing_limit] unless args[:heat_pump_backup_heating_autosizing_limit].nil?
        # Faults
        if [HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpMiniSplit, HPXML::HVACTypeHeatPumpPTHP, HPXML::HVACTypeHeatPumpRoom].include? heat_pump.heat_pump_type
          if (not heat_pump.distribution_system.nil?) && (not args[:heat_pump_rated_cfm_per_ton].nil?) && (not args[:heat_pump_actual_cfm_per_ton].nil?)
            heat_pump.airflow_defect_ratio = (args[:heat_pump_actual_cfm_per_ton] - args[:heat_pump_rated_cfm_per_ton]) / args[:heat_pump_rated_cfm_per_ton]
          end
          if (not args[:heat_pump_frac_manufacturer_charge].nil?)
            heat_pump.charge_defect_ratio = args[:heat_pump_frac_manufacturer_charge] - 1.0
          end
        end
        # Detailed performance
        set_hvac_detailed_performance_data('cooling',
                                           heat_pump.cooling_detailed_performance_data,
                                           args[:hvac_perf_data_cooling_outdoor_temperatures],
                                           args[:hvac_perf_data_cooling_min_speed_cops],
                                           args[:hvac_perf_data_cooling_nom_speed_cops],
                                           args[:hvac_perf_data_cooling_max_speed_cops],
                                           args[:hvac_perf_data_cooling_min_speed_capacities],
                                           args[:hvac_perf_data_cooling_nom_speed_capacities],
                                           args[:hvac_perf_data_cooling_max_speed_capacities],
                                           heat_pump.compressor_type)
        set_hvac_detailed_performance_data('heating',
                                           heat_pump.heating_detailed_performance_data,
                                           args[:hvac_perf_data_heating_outdoor_temperatures],
                                           args[:hvac_perf_data_heating_min_speed_cops],
                                           args[:hvac_perf_data_heating_nom_speed_cops],
                                           args[:hvac_perf_data_heating_max_speed_cops],
                                           args[:hvac_perf_data_heating_min_speed_capacities],
                                           args[:hvac_perf_data_heating_nom_speed_capacities],
                                           args[:hvac_perf_data_heating_max_speed_capacities],
                                           heat_pump.compressor_type)
      end

      # DHW systems
      hpxml_bldg.water_heating_systems.each do |water_heater|
        water_heater.jacket_r_value = args[:dhw_water_heater_jacket_rvalue] unless args[:dhw_water_heater_jacket_rvalue].to_f == 0
      end

      # Electric Panel
      set_electric_panel(runner, hpxml_bldg, args)
    end

    # Apply defaults
    @hpxml.buildings.each do |hpxml_bldg|
      # Write out the hpxml (must be before validation)
      hpxml_doc = @hpxml.to_doc()
      XMLHelper.write_file(hpxml_doc, @hpxml_path)

      # Always check for invalid HPXML file before applying defaults
      if not validate_hpxml(runner, @hpxml, hpxml_doc, @hpxml_path)
        return false
      end

      # Get a schedules_file object so that we don't end up with simple weekday/weekend/month schedules
      # when we apply defaults.
      schedules_filepaths = hpxml_bldg.header.schedules_filepaths
      schedules_filepaths.each_with_index do |schedules_filepath, i|
        next if Pathname.new(schedules_filepath).absolute?

        schedules_filepaths[i] = File.join(File.dirname(@hpxml_path), schedules_filepath)
      end
      schedules_file = SchedulesFile.new(schedules_paths: schedules_filepaths,
                                         year: @hpxml.header.sim_calendar_year,
                                         output_path: nil)
      Defaults.apply(runner, @hpxml, hpxml_bldg, weather, schedules_file: schedules_file)

      # Register additional values
      register_value(runner, 'unit_height_above_grade', hpxml_bldg.building_construction.unit_height_above_grade)
      air_leakage_measurement = hpxml_bldg.air_infiltration_measurements[0]
      a_ext = (air_leakage_measurement.a_ext.nil? ? 1.0 : air_leakage_measurement.a_ext)
      register_value(runner, 'air_leakage_to_outside_ach_50', air_leakage_measurement.air_leakage * a_ext)
    end

    # HVAC Flexibility
    output_csv_path = File.dirname(@hpxml_path)
    @prng = Random.new(args[:building_id])
    @minutes_per_step = @hpxml.header.timestep.nil? ? 60 : @hpxml.header.timestep
    max_random_shift_steps = (args[:flex_random_shift_minutes].to_f / @minutes_per_step).to_i
    @random_shift_steps = @prng.rand(-max_random_shift_steps..max_random_shift_steps)
    @hpxml.buildings.each_with_index do |hpxml_bldg, index|
      if hpxml_bldg.hvac_controls.to_a.length != 0 && !skip_hvac_flexibility?(args)
        hvac_schedule = create_hvac_schedule(hpxml_bldg, weather)
        modified_schedule = modify_hvac_schedule(hpxml_bldg, hvac_schedule, weather)
        write_schedule(modified_schedule, hpxml_bldg, index, output_csv_path)
      end
      next unless !skip_ev_flexibility?(args)

      ev_schedule = get_ev_schedule(hpxml_bldg)
      next if ev_schedule.nil?

      modified_ev_schedule = modify_ev_schedule(hpxml_bldg, ev_schedule, weather)
      write_schedule(modified_ev_schedule, hpxml_bldg, index, output_csv_path)
    end

    # Write out the hpxml (must be before validation)
    hpxml_doc = @hpxml.to_doc()
    XMLHelper.write_file(hpxml_doc, @hpxml_path)

    # Validate final HPXML
    if not validate_hpxml(runner, @hpxml, hpxml_doc, @hpxml_path)
      return false
    end

    # Write out the modified hpxml
    XMLHelper.write_file(hpxml_doc, @hpxml_path)

    return true
  end

  # Determines if HVAC flexibility modifications should be skipped
  # Skips if both peak offset and pre-peak duration are set to 0
  def skip_hvac_flexibility?(args)
    return true if args[:hvac_flex_peak_offset] == 0 && args[:hvac_flex_pre_peak_duration_hours] == 0
  end

  def skip_ev_flexibility?(args)
    return true if !args[:ev_flex_enabled]
  end

  def get_ev_schedule(hpxml_bldg)
    schedule_file = get_existing_schedule_filepath(hpxml_bldg)
    return if schedule_file.nil?

    schedule = CSV.read(schedule_file, headers: true)
    ev_schedule = {}
    ev_column = 'electric_vehicle'
    return unless schedule.headers.include?(ev_column)

    ev_schedule[ev_column.to_sym] = schedule[ev_column].map(&:to_f)
    return ev_schedule
  end

  # Generates the HVAC schedule for a given building index
  def create_hvac_schedule(hpxml_bldg, weather)
    generator = HVACScheduleGenerator.new(@hpxml, hpxml_bldg, @hpxml_path, @runner, weather)
    return generator.get_heating_cooling_setpoint_schedule
  end

  # Retrieves an appropriate schedule modifier for a given building
  def get_schedule_modifier(hpxml_bldg, modifier_class, weather)
    # Ensure the provided class is a subclass of ScheduleModifier
    raise ArgumentError, "#{modifier_class} must be a subclass of ScheduleModifier" unless modifier_class < ScheduleModifier

    state = hpxml_bldg.state_code
    sim_year = @hpxml.header.sim_calendar_year
    epw_path = Location.get_epw_path(hpxml_bldg, @hpxml_path)

    # Get daylight saving time information
    dst_info = DSTInfo.new(dst_begin_month: hpxml_bldg.dst_begin_month,
                           dst_begin_day: hpxml_bldg.dst_begin_day,
                           dst_end_month: hpxml_bldg.dst_end_month,
                           dst_end_day: hpxml_bldg.dst_end_day)

    # Create and return the modifier instance
    return modifier_class.new(state: state,
                              sim_year: sim_year,
                              weather: weather,
                              epw_path: epw_path,
                              minutes_per_step: @minutes_per_step,
                              runner: @runner,
                              dst_info: dst_info)
  end

  # Modifies the HVAC schedule based on flexibility inputs
  def modify_hvac_schedule(hpxml_bldg, schedule, weather)
    hvac_schedule_modifier = get_schedule_modifier(hpxml_bldg, HVACScheduleModifier, weather)

    # Define flexibility inputs
    hvac_flexibility_inputs = FlexibilityInputs.new(
      peak_offset: @args[:hvac_flex_peak_offset],
      pre_peak_duration_steps: (@args[:hvac_flex_pre_peak_duration_hours] * 60 / @minutes_per_step).to_i,
      pre_peak_offset: @args[:hvac_flex_pre_peak_offset],
      random_shift_steps: @random_shift_steps
    )

    # Apply modifications to the schedule
    return hvac_schedule_modifier.modify_shedule(schedule, hvac_flexibility_inputs)
  end

  def modify_ev_schedule(hpxml_bldg, schedule, weather)
    ev_schedule_modifier = get_schedule_modifier(hpxml_bldg, EVScheduleModifier, weather)
    ev_flexibility_inputs = FlexibilityInputs.new(
      peak_offset: 0,
      # Use hvac_flex_pre_peak_duration_hours so that shift/shed is the same as HVAC
      pre_peak_duration_steps: (@args[:hvac_flex_pre_peak_duration_hours] * 60 / @minutes_per_step).to_i,
      pre_peak_offset: 0,
      random_shift_steps: @random_shift_steps
    )
    return ev_schedule_modifier.modify_schedule(schedule, ev_flexibility_inputs)
  end

  # Writes the HVAC schedule to a CSV file
  def write_schedule(schedule, hpxml_bldg, index, output_csv_path)
    schedule_file = get_existing_schedule_filepath(hpxml_bldg)

    if schedule_file.nil?
      # Create a new schedule file if one does not exist
      schedule_file = File.join(output_csv_path, "schedule_#{index}.csv")
      CSV.open(schedule_file, 'w') do |csv|
        headers = schedule.keys.map(&:to_s)
        csv << headers
        row_count = schedule.values.first.length
        (0...row_count).each do |i|
          row = headers.map { |h| schedule[h.to_sym][i] }
          csv << row
        end
      end
      hpxml_bldg.header.schedules_filepaths << File.basename(schedule_file)
    else
      # Process existing schedule file and update values
      data = CSV.read(schedule_file, headers: true)
      headers = data.headers

      schedule.each do |column_name, values|
        string_column_name = column_name.to_s
        column_index = headers.index { |h| h.to_s == string_column_name }

        if column_index
          data.each_with_index do |row, i|
            row[column_index] = values[i]
          end
        else
          headers << string_column_name
          data.each_with_index do |row, i|
            row[string_column_name] = values[i]
          end
        end
      end

      # Write the updated schedule back to the CSV file
      CSV.open(schedule_file, 'w') do |csv|
        csv << headers
        data.each { |row| csv << row }
      end
    end

    return schedule_file
  end

  # Retrieves the existing schedule file path from the HPXML file
  def get_existing_schedule_filepath(hpxml_bldg)
    schedule_file = hpxml_bldg.header.schedules_filepaths.first
    return if schedule_file.nil?

    # Ensure the path is absolute
    if !Pathname.new(schedule_file).absolute?
      schedule_file = File.join(File.dirname(@hpxml_path), schedule_file)
    end
    return schedule_file
  end

  def set_electric_panel(runner, hpxml_bldg, args)
    # Assign miscellaneous permanently connected appliance loads
    panel_sampler = ElectricalPanelSampler.new(runner, hpxml_bldg, args)

    cap_value = args[:electric_panel_service_max_current_rating]
    headroom_spaces = args[:electric_panel_breaker_spaces_headroom]
    total_spaces = args[:electric_panel_breaker_spaces_rated_total]
    if cap_value.nil?
      cap_bin, cap_value = panel_sampler.assign_rated_capacity()
      register_value(runner, 'electric_panel_service_max_current_rating_bin', cap_bin)

      headroom_spaces = panel_sampler.assign_breaker_space_headroom(cap_bin)
    end
    register_value(runner, 'electric_panel_service_max_current_rating', cap_value)

    n_beds = hpxml_bldg.building_construction.number_of_bedrooms

    # Assume all homes have a microwave
    if n_beds <= 2
      microwave_power = 900 # W, small, <= 0.9 cu ft, 1-2 ppl
    elsif n_beds <= 4
      microwave_power = 1100 # W, medium, <= 1.6 cu ft, 3-4 ppl
    else
      microwave_power = 1250 # W, large, 1.7-2.2 cu ft, 5+ ppl
    end

    garbage_disposal_ownership = 0.52 # AHS 2013
    if Random.new(args[:building_id]).rand > garbage_disposal_ownership
      garbage_disposal_power = 0
    else
      # Power estimated from avg load amp not HP rating, from InSinkErators
      if n_beds <= 1
        garbage_disposal_power = 672 # W, 1/3 HP, avg load 5.6A, 1-2 ppl
      elsif n_beds <= 3
        garbage_disposal_power = 756 # W, 1/2 HP, avg load 6.3A, 2-4 ppl
      elsif n_beds <= 4
        garbage_disposal_power = 1140 # W, 3/4 HP, avg load 9.5A, 3-5 ppl
      else
        garbage_disposal_power = 1224 # W, 1 HP, avg load 10.2A, 4+ ppl
      end
    end

    if hpxml_bldg.has_location(HPXML::LocationGarage)
      # Assume one automatic door opener if has garage, regardless of no. garages
      garage_door_power = 373 # W, 1/2 HP (1 mech HP = 745.7 W)
    else
      garage_door_power = 0
    end

    electric_panel_load_other_power_rating = args[:electric_panel_load_other_power_rating].to_f
    electric_panel_load_other_power_rating += microwave_power
    electric_panel_load_other_power_rating += garbage_disposal_power
    electric_panel_load_other_power_rating += garage_door_power

    # Assign ElectricPanels objects
    hpxml_bldg.electric_panels.add(id: "ElectricPanel#{hpxml_bldg.electric_panels.size + 1}",
                                   max_current_rating: cap_value,
                                   headroom_spaces: headroom_spaces,
                                   rated_total_spaces: total_spaces)

    electric_panel = hpxml_bldg.electric_panels[0]
    branch_circuits = electric_panel.branch_circuits
    service_feeders = electric_panel.service_feeders

    hpxml_bldg.heating_systems.each do |heating_system|
      next if heating_system.is_shared_system
      next if heating_system.fraction_heat_load_served == 0

      if heating_system.primary_system
        service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                            type: HPXML::ElectricPanelLoadTypeHeating,
                            is_new_load: args[:electric_panel_load_heating_system_new_load],
                            component_idrefs: [heating_system.id])
      else
        service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                            type: HPXML::ElectricPanelLoadTypeHeating,
                            is_new_load: args[:electric_panel_load_heating_system_2_new_load],
                            component_idrefs: [heating_system.id])
      end
    end

    hpxml_bldg.cooling_systems.each do |cooling_system|
      next if cooling_system.is_shared_system
      next if cooling_system.fraction_cool_load_served == 0

      service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                          type: HPXML::ElectricPanelLoadTypeCooling,
                          is_new_load: args[:electric_panel_load_cooling_system_new_load],
                          component_idrefs: [cooling_system.id])
    end

    hpxml_bldg.heat_pumps.each do |heat_pump|
      next if heat_pump.is_shared_system

      if heat_pump.fraction_heat_load_served != 0
        service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                            type: HPXML::ElectricPanelLoadTypeHeating,
                            is_new_load: args[:electric_panel_load_heat_pump_new_load],
                            component_idrefs: [heat_pump.id])
      end
      next unless heat_pump.fraction_cool_load_served != 0

      service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                          type: HPXML::ElectricPanelLoadTypeCooling,
                          is_new_load: args[:electric_panel_load_heat_pump_new_load],
                          component_idrefs: [heat_pump.id])
    end

    hpxml_bldg.water_heating_systems.each do |water_heating_system|
      next if water_heating_system.fuel_type != HPXML::FuelTypeElectricity

      service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                          type: HPXML::ElectricPanelLoadTypeWaterHeater,
                          is_new_load: args[:electric_panel_load_electric_water_heater_new_load],
                          component_idrefs: [water_heating_system.id])
    end

    hpxml_bldg.clothes_dryers.each do |clothes_dryer|
      next if clothes_dryer.fuel_type != HPXML::FuelTypeElectricity

      service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                          type: HPXML::ElectricPanelLoadTypeClothesDryer,
                          is_new_load: args[:electric_panel_load_electric_clothes_dryer_new_load],
                          component_idrefs: [clothes_dryer.id])
    end

    hpxml_bldg.dishwashers.each do |dishwasher|
      service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                          type: HPXML::ElectricPanelLoadTypeDishwasher,
                          is_new_load: args[:electric_panel_load_dishwasher_new_load],
                          component_idrefs: [dishwasher.id])
    end

    hpxml_bldg.cooking_ranges.each do |cooking_range|
      next if cooking_range.fuel_type != HPXML::FuelTypeElectricity

      service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                          type: HPXML::ElectricPanelLoadTypeRangeOven,
                          is_new_load: args[:electric_panel_load_electric_cooking_range_new_load],
                          component_idrefs: [cooking_range.id])
    end

    hpxml_bldg.ventilation_fans.each do |ventilation_fan|
      if ventilation_fan.used_for_whole_building_ventilation
        service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                            type: HPXML::ElectricPanelLoadTypeMechVent,
                            is_new_load: args[:electric_panel_load_mech_vent_fan_new_load],
                            component_idrefs: [ventilation_fan.id])
      elsif ventilation_fan.used_for_local_ventilation # Kitchen / Bathroom Fans
        if ventilation_fan.fan_location == HPXML::LocationKitchen
          service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                              type: HPXML::ElectricPanelLoadTypeMechVent,
                              is_new_load: args[:electric_panel_load_kitchen_fans_new_load],
                              component_idrefs: [ventilation_fan.id])
        elsif ventilation_fan.fan_location == HPXML::LocationBath
          service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                              type: HPXML::ElectricPanelLoadTypeMechVent,
                              is_new_load: args[:electric_panel_load_bathroom_fans_new_load],
                              component_idrefs: [ventilation_fan.id])
        end
      elsif ventilation_fan.used_for_seasonal_cooling_load_reduction # Whole House Fan
        service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                            type: HPXML::ElectricPanelLoadTypeMechVent,
                            is_new_load: args[:electric_panel_load_whole_house_fan_new_load],
                            component_idrefs: [ventilation_fan.id])
      end
    end

    hpxml_bldg.permanent_spas.each do |permanent_spa|
      service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                          type: HPXML::ElectricPanelLoadTypePermanentSpaPump,
                          is_new_load: args[:electric_panel_load_permanent_spa_pump_new_load],
                          component_idrefs: [permanent_spa.pump_id])

      next unless [HPXML::HeaterTypeElectricResistance, HPXML::HeaterTypeHeatPump].include?(permanent_spa.heater_type)

      service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                          type: HPXML::ElectricPanelLoadTypePermanentSpaHeater,
                          is_new_load: args[:electric_panel_load_electric_permanent_spa_heater_new_load],
                          component_idrefs: [permanent_spa.heater_id])
    end

    hpxml_bldg.pools.each do |pool|
      service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                          type: HPXML::ElectricPanelLoadTypePoolPump,
                          is_new_load: args[:electric_panel_load_pool_pump_new_load],
                          component_idrefs: [pool.pump_id])

      next unless [HPXML::HeaterTypeElectricResistance, HPXML::HeaterTypeHeatPump].include?(pool.heater_type)

      service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                          type: HPXML::ElectricPanelLoadTypePoolHeater,
                          is_new_load: args[:electric_panel_load_electric_pool_heater_new_load],
                          component_idrefs: [pool.heater_id])
    end

    hpxml_bldg.plug_loads.each do |plug_load|
      if plug_load.plug_load_type == HPXML::PlugLoadTypeWellPump
        service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                            type: HPXML::ElectricPanelLoadTypeWellPump,
                            is_new_load: args[:electric_panel_load_misc_plug_loads_well_pump_new_load],
                            component_idrefs: [plug_load.id])
      elsif plug_load.plug_load_type == HPXML::PlugLoadTypeElectricVehicleCharging
        service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                            type: HPXML::ElectricPanelLoadTypeElectricVehicleCharging,
                            is_new_load: args[:electric_panel_load_misc_plug_loads_vehicle_new_load],
                            component_idrefs: [plug_load.id])
      end
    end

    hpxml_bldg.ev_chargers.each do |ev_charger|
      if not ev_charger.charging_level.nil?
        voltage = { 1 => HPXML::ElectricPanelVoltage120,
                    2 => HPXML::ElectricPanelVoltage240,
                    3 => HPXML::ElectricPanelVoltage240 }[ev_charger.charging_level]
      end

      if not ev_charger.charging_power.nil?
        power = ev_charger.charging_power
      end

      if not voltage.nil?
        branch_circuits.add(id: "BranchCircuit#{branch_circuits.size + 1}",
                            voltage: voltage,
                            component_idrefs: [ev_charger.id])
      end

      service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                          type: HPXML::ElectricPanelLoadTypeElectricVehicleCharging,
                          power: power,
                          is_new_load: args[:electric_panel_load_misc_plug_loads_vehicle_new_load],
                          component_idrefs: [ev_charger.id])
    end

    if !electric_panel_load_other_power_rating.nil? || !args[:electric_panel_load_other_new_load].nil?
      branch_circuits.add(id: "BranchCircuit#{branch_circuits.size + 1}",
                          occupied_spaces: 1,
                          component_idrefs: [])
      service_feeders.add(id: "ServiceFeeder#{service_feeders.size + 1}",
                          type: HPXML::ElectricPanelLoadTypeOther,
                          power: electric_panel_load_other_power_rating,
                          is_new_load: args[:electric_panel_load_other_new_load],
                          component_idrefs: [])
    end
  end

  def get_heating_and_cooling_seasons(weather)
    heating_months, cooling_months = HVAC.get_building_america_hvac_seasons(weather, 1) # latitude=1 ensures northern hemisphere
    sim_calendar_year = @hpxml.header.sim_calendar_year

    return heating_months, cooling_months, sim_calendar_year
  end

  def get_begin_end_day_nums(building_id, n_days, begin_day_num, end_day_num, year)
    if begin_day_num > end_day_num
      num_days = Calendar.num_days_in_year(year)
      begin_day_nums = (begin_day_num..num_days).to_a + (1..end_day_num).to_a
    else
      begin_day_nums = (begin_day_num..end_day_num).to_a
    end

    unavail_begin_day_nums = begin_day_nums.sample(1, random: Random.new(building_id))
    unavail_begin_day_num = unavail_begin_day_nums[0]
    unavail_begin_date = OpenStudio::Date::fromDayOfYear(unavail_begin_day_num, year)
    unavail_begin_month = unavail_begin_date.monthOfYear.value
    unavail_begin_day = unavail_begin_date.dayOfMonth

    unavail_end_date = unavail_begin_date + OpenStudio::Time.new(n_days - 1)
    unavail_end_month = unavail_end_date.monthOfYear.value
    unavail_end_day = unavail_end_date.dayOfMonth

    return unavail_begin_month, unavail_begin_day, unavail_end_month, unavail_end_day
  end

  def set_hvac_detailed_performance_data(perf_type, hvac_perf_data, outdoor_temperatures, min_cops, nom_cops, max_cops,
                                         min_capacities, nom_capacities, max_capacities, compressor_type)
    return if outdoor_temperatures.nil?

    speeds_map = {
      HPXML::HVACCompressorTypeSingleStage => [HPXML::CapacityDescriptionNominal],
      HPXML::HVACCompressorTypeTwoStage => [HPXML::CapacityDescriptionMinimum, HPXML::CapacityDescriptionNominal],
      HPXML::HVACCompressorTypeVariableSpeed => [HPXML::CapacityDescriptionMinimum, HPXML::CapacityDescriptionNominal, HPXML::CapacityDescriptionMaximum],
    }

    if [HPXML::HVACCompressorTypeSingleStage].include? compressor_type
      if not min_capacities.to_s.empty?
        fail "HVAC system is #{compressor_type} but minimum speed capacities for #{perf_type} provided."
      end
      if not min_cops.to_s.empty?
        fail "HVAC system is #{compressor_type} but minimum speed COPs for #{perf_type} provided."
      end
    end
    if [HPXML::HVACCompressorTypeSingleStage, HPXML::HVACCompressorTypeTwoStage].include? compressor_type
      if not max_capacities.to_s.empty?
        fail "HVAC system is #{compressor_type} but maximum speed capacities for #{perf_type} provided."
      end
      if not max_cops.to_s.empty?
        fail "HVAC system is #{compressor_type} but maximum speed COPs for #{perf_type} provided."
      end
    end

    outdoor_temperatures.split(',').map(&:strip).each_with_index do |outdoor_temperature, i|
      for speed in speeds_map[compressor_type]
        if speed == HPXML::CapacityDescriptionMinimum
          capacity = (Float(min_capacities.split(',').map(&:strip)[i]) rescue nil)
          cop = (Float(min_cops.split(',').map(&:strip)[i]) rescue nil)
        elsif speed == HPXML::CapacityDescriptionNominal
          capacity = (Float(nom_capacities.split(',').map(&:strip)[i]) rescue nil)
          cop = (Float(nom_cops.split(',').map(&:strip)[i]) rescue nil)
        elsif speed == HPXML::CapacityDescriptionMaximum
          capacity = (Float(max_capacities.split(',').map(&:strip)[i]) rescue nil)
          cop = (Float(max_cops.split(',').map(&:strip)[i]) rescue nil)
        end
        next if capacity.nil?

        hvac_perf_data.add(outdoor_temperature: Float(outdoor_temperature),
                           capacity_fraction_of_nominal: capacity,
                           capacity_description: speed,
                           efficiency_cop: cop)
      end
    end
  end

  def convert_args(measure_arguments, args)
    measure_arguments.each do |arg|
      arg_name = arg.name.to_sym
      value = args[arg_name]
      next if value.nil?

      case arg.type.valueName.downcase
      when 'double'
        args[arg_name] = Float(value)
      when 'integer'
        args[arg_name] = Integer(value)
      end
    end
    return args
  end

  # Check for errors in hpxml, and validate hpxml_doc against hpxml_path
  def validate_hpxml(runner, hpxml, hpxml_doc, hpxml_path)
    # Check for errors in the HPXML object
    errors = []
    hpxml.buildings.each do |hpxml_bldg|
      errors += hpxml_bldg.check_for_errors()
    end
    if errors.size > 0
      errors.each do |error|
        runner.registerError("#{hpxml_path}: #{error}")
      end
      return false
    end

    is_valid = true

    # Validate input HPXML against schema
    schema_path = File.join(File.dirname(__FILE__), '..', '..', 'resources', 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd')
    schema_validator = XMLValidator.get_xml_validator(schema_path)
    xsd_errors, xsd_warnings = XMLValidator.validate_against_schema(hpxml_path, schema_validator)

    # Validate input HPXML against schematron docs
    schematron_path = File.join(File.dirname(__FILE__), '..', '..', 'resources', 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schematron', 'EPvalidator.sch')
    schematron_validator = XMLValidator.get_xml_validator(schematron_path)
    sct_errors, sct_warnings = XMLValidator.validate_against_schematron(hpxml_path, schematron_validator, hpxml_doc)

    # Handle errors/warnings
    (xsd_errors + sct_errors).each do |error|
      runner.registerError("#{hpxml_path}: #{error}")
      is_valid = false
    end
    (xsd_warnings + sct_warnings).each do |warning|
      runner.registerWarning("#{hpxml_path}: #{warning}")
    end

    return is_valid
  end
end

# register the measure to be used by the application
ResStockArgumentsPostHPXML.new.registerWithApplication
