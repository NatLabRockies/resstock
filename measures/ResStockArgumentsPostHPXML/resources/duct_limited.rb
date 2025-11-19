# frozen_string_literal: true

def set_autosizing_limits(runner, measures, hpxml_bldg)
  # Use Autosizing Limits and Maintain Duct System Curve (Part 1)
  # Set the autosizing limit based on the baseline airflow.
  if measures['ResStockArguments'][0]['hvac_heat_pump_sizing_is_duct_limited'].to_s.downcase == 'true'
    duct_restriction_values = get_duct_restriction_values(hpxml_bldg)
    baseline_max_airflow_cfm = duct_restriction_values['max_airflow_cfm']
    autosizing_limit = duct_restriction_values['autosizing_limit']

    # Only limit HVAC system types with ducted air distribution.
    if not autosizing_limit.nil?
      args = get_detailed_hvac_arguments(measures)

      # Heating system
      heating_system_type = args[:hvac_heating_system_type]
      if [HPXML::HVACTypeFurnace].include?(heating_system_type)
        measures['ResStockArgumentsPostHPXML'][0]['heating_system_heating_autosizing_limit'] = autosizing_limit
        runner.registerInfo("The capacity of the upgraded heating system is limited to 'heating_system_heating_autosizing_limit=#{autosizing_limit}', based on a baseline maximum airflow rate of #{baseline_max_airflow_cfm} cfm and an assumed #{Constants::DuctRestrictionAssumedAirflow} cfm/ton.")
      end

      # Cooling system
      cooling_system_type = args[:hvac_cooling_system_type]
      cooling_system_is_ducted = args[:hvac_cooling_system_is_ducted]
      if ([HPXML::HVACTypeCentralAirConditioner].include?(cooling_system_type) ||
         ([HPXML::HVACTypeMiniSplitAirConditioner].include?(cooling_system_type) && cooling_system_is_ducted))
        measures['ResStockArgumentsPostHPXML'][0]['cooling_system_cooling_autosizing_limit'] = autosizing_limit
        runner.registerInfo("The capacity of the upgraded cooling system is limited to 'cooling_system_cooling_autosizing_limit=#{autosizing_limit}', based on a baseline maximum airflow rate of #{baseline_max_airflow_cfm} cfm and an assumed #{Constants::DuctRestrictionAssumedAirflow} cfm/ton.")
      end

      # Heat pump
      heat_pump_type = args[:hvac_heat_pump_type]
      heat_pump_is_ducted = args[:hvac_heat_pump_is_ducted]
      if ([HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpGroundToAir].include?(heat_pump_type) ||
         ([HPXML::HVACTypeHeatPumpMiniSplit].include?(heat_pump_type) && heat_pump_is_ducted))
        measures['ResStockArgumentsPostHPXML'][0]['heat_pump_heating_autosizing_limit'] = autosizing_limit
        measures['ResStockArgumentsPostHPXML'][0]['heat_pump_cooling_autosizing_limit'] = autosizing_limit
        # We intentionally do not limit the heat pump backup heating autosized value.
        runner.registerInfo("The heating capacity of the upgraded heat pump is limited to 'heat_pump_heating_autosizing_limit=#{autosizing_limit}', based on a baseline maximum airflow rate of #{baseline_max_airflow_cfm} cfm and an assumed #{Constants::DuctRestrictionAssumedAirflow} cfm/ton.")
        runner.registerInfo("The cooling capacity of the upgraded heat pump is limited to 'heat_pump_cooling_autosizing_limit=#{autosizing_limit}', based on a baseline maximum airflow rate of #{baseline_max_airflow_cfm} cfm and an assumed #{Constants::DuctRestrictionAssumedAirflow} cfm/ton.")
      end

      # Heating system 2
      heating_system_2_type = args[:hvac_heating_system_2_type]
      if [HPXML::HVACTypeFurnace].include?(heating_system_2_type)
        measures['ResStockArgumentsPostHPXML'][0]['heating_system_2_heating_autosizing_limit'] = autosizing_limit
        runner.registerInfo("The capacity of the upgraded second heating system is limited to 'heating_system_2_heating_autosizing_limit=#{autosizing_limit}', based on a baseline maximum airflow rate of #{baseline_max_airflow_cfm} cfm and an assumed #{Constants::DuctRestrictionAssumedAirflow} cfm/ton.")
      end
    end

    measures['ResStockArgumentsPostHPXML'][0]['baseline_max_airflow_cfm'] = baseline_max_airflow_cfm
  end
  return
end

def get_air_distribution_airflows(hpxml_bldg)
  # Assume at most one ducted system with a single heating and/or cooling system.
  # We divide airflow by fraction of load served to account for partial conditioning adjustments.

  fraction_heat_load_served = nil
  fraction_cool_load_served = nil

  air_distribution_airflows = []
  hpxml_bldg.hvac_distributions.each do |hvac_distribution|
    next if hvac_distribution.ducts.empty?

    hvac_distribution.hvac_systems.each do |hvac_system|
      if hvac_system.is_a?(HPXML::HeatingSystem)
        heating_airflow_cfm = hvac_system.heating_design_airflow_cfm
        if !heating_airflow_cfm.nil?
          fraction_heat_load_served = hvac_system.fraction_heat_load_served
          air_distribution_airflows << heating_airflow_cfm / fraction_heat_load_served
        end
      elsif hvac_system.is_a?(HPXML::CoolingSystem)
        cooling_airflow_cfm = hvac_system.cooling_design_airflow_cfm
        if !cooling_airflow_cfm.nil?
          fraction_cool_load_served = hvac_system.fraction_cool_load_served
          air_distribution_airflows << cooling_airflow_cfm / fraction_cool_load_served
        end
      elsif hvac_system.is_a?(HPXML::HeatPump)
        heating_airflow_cfm = hvac_system.heating_design_airflow_cfm
        if !heating_airflow_cfm.nil?
          fraction_heat_load_served = hvac_system.fraction_heat_load_served
          air_distribution_airflows << heating_airflow_cfm / fraction_heat_load_served
        end

        cooling_airflow_cfm = hvac_system.cooling_design_airflow_cfm
        if !cooling_airflow_cfm.nil?
          fraction_cool_load_served = hvac_system.fraction_cool_load_served
          air_distribution_airflows << cooling_airflow_cfm / fraction_cool_load_served
        end
      end
    end
  end

  # The following assumes we will be expanding (i.e., rebuilding) the existing ducts.
  # So we avoid setting a heating/cooling autosizing limit.
  if fraction_heat_load_served.nil? && !fraction_cool_load_served.nil? && fraction_cool_load_served < 1.0
    air_distribution_airflows = []
  end

  return air_distribution_airflows
end

def get_duct_restriction_values(hpxml_bldg)
  duct_restriction_values = {
    'max_airflow_cfm' => nil,
    'autosizing_limit' => nil
  }

  air_distribution_airflows = get_air_distribution_airflows(hpxml_bldg)
  if !air_distribution_airflows.empty?
    duct_restriction_values['max_airflow_cfm'] = air_distribution_airflows.max
    # TODO:
    # Currently we are assuming a constant value for upgrade cfm/ton, regardless of the upgraded equipment type (furnace, heat pump, etc).
    # This value should more appropriately vary based on the type of upgraded equipment.
    cfm_per_ton = Constants::DuctRestrictionAssumedAirflow
    duct_restriction_values['autosizing_limit'] = UnitConversions.convert(duct_restriction_values['max_airflow_cfm'] / cfm_per_ton, 'ton', 'Btu/hr')
  end

  return duct_restriction_values
end

def set_adjusted_fan_efficiency(runner, args, hpxml_bldg)
  # Use Autosizing Limits and Maintain Duct System Curve (Part 2)
  # - Get the upgrade airflow cfm.
  # - Use it along with the baseline airflow cfm and upgrade blower fan W/cfm.
  # - Set the adjustment to the upgrade blower fan W/cfm.

  baseline_max_airflow_cfm = args[:baseline_max_airflow_cfm]
  if args[:hvac_heat_pump_sizing_is_duct_limited]
    duct_restriction_values = get_duct_restriction_values(hpxml_bldg)
    upgrade_max_airflow_cfm = duct_restriction_values['max_airflow_cfm']

    if (not baseline_max_airflow_cfm.nil?) && (not upgrade_max_airflow_cfm.nil?) # ducted -> ducted
      fan_watts_per_cfm = get_fan_watts_per_cfm(hpxml_bldg)
      adjusted_fan_watts_per_cfm = get_adjusted_fan_watts_per_cfm(baseline_max_airflow_cfm, upgrade_max_airflow_cfm, fan_watts_per_cfm)

      hpxml_bldg.heat_pumps.each do |heat_pump|
        heat_pump.fan_watts_per_cfm = adjusted_fan_watts_per_cfm
      end

      runner.registerInfo("The blower fan efficiency of #{fan_watts_per_cfm} was adjusted to 'hvac_blower_fan_watts_per_cfm=#{adjusted_fan_watts_per_cfm}', based on a baseline maximum airflow rate of #{baseline_max_airflow_cfm} cfm and an upgrade maximum airflow rate of #{upgrade_max_airflow_cfm} cfm.")
    end
  end
end

def get_fan_watts_per_cfm(hpxml_bldg)
  # Assume at most one ducted system with a single blower fan.

  fan_watts_per_cfm = nil
  hpxml_bldg.hvac_distributions.each do |hvac_distribution|
    next if hvac_distribution.ducts.empty?

    hvac_distribution.hvac_systems.each do |hvac_system|
      fan_watts_per_cfm = hvac_system.fan_watts_per_cfm
    end
  end
  return fan_watts_per_cfm
end

def get_adjusted_fan_watts_per_cfm(baseline_max_airflow_cfm, upgrade_max_airflow_cfm, fan_watts_per_cfm)
  # Adjust the blower fan efficiency based on baseline/upgrade maximum airflow cfm values.
  # FIXME: Source?

  v_baseline = baseline_max_airflow_cfm
  v_upgrade = upgrade_max_airflow_cfm

  p_int = v_baseline * fan_watts_per_cfm
  p_upgrade = p_int * (v_upgrade / v_baseline)**3
  adjusted_fan_watts_per_cfm = p_upgrade / v_upgrade

  return adjusted_fan_watts_per_cfm.round(3)
end
