# frozen_string_literal: true

def set_existing_system_as_heat_pump_backup(runner, hpxml_bldg_existing, hpxml_bldg, args)
  # Retain Existing Heating System as Heat Pump Backup
  if args[:hvac_heat_pump_backup_use_existing_system]

    # Only set the backup if the heat pump is applied and there is an existing heating system
    heat_pump = get_heat_pump(hpxml_bldg)

    if not heat_pump.nil?

      heating_system = get_heating_system(hpxml_bldg_existing)
      if not heating_system.nil?

        heat_pump_type = heat_pump.heat_pump_type
        heat_pump_is_ducted = !heat_pump.distribution_system.nil? && !heat_pump.distribution_system.ducts.empty?
        heat_pump_backup_type = get_heat_pump_backup_type(heating_system.distribution_system, heat_pump_type, heat_pump_is_ducted)

        # Integrated; heat pump's distribution system and blower fan power applies to the backup heating
        # e.g., ducted heat pump (e.g., ashp, gshp, ducted minisplit) with ducted (e.g., furnace) backup
        if heat_pump_backup_type == HPXML::HeatPumpBackupTypeIntegrated

          # Likely only fuel-fired furnace as integrated backup
          if heating_system.heating_system_fuel != HPXML::FuelTypeElectricity
            heat_pump.backup_heating_fuel = heating_system.heating_system_fuel
            heat_pump.backup_heating_efficiency_afue = heating_system.heating_efficiency_afue
            heat_pump.backup_heating_efficiency_percent = heating_system.heating_efficiency_percent
            heat_pump.backup_heating_capacity = heating_system.heating_capacity
            heat_pump.backup_heating_autosizing_factor = heating_system.heating_autosizing_factor
            heat_pump.backup_type = heat_pump_backup_type

            runner.registerInfo("Found '#{heating_system.heating_system_type}' heating system type; setting it as 'heat_pump_backup_type=#{heat_pump_backup_type}'.")
          else # Likely would not have electric furnace as integrated backup
            runner.registerInfo("Found '#{heating_system.heating_system_type}' heating system type with '#{heating_system.heating_system_fuel}' fuel type; not setting it as integrated backup.")
          end

        # Separate; backup system has its own distribution system
        # e.g., ductless heat pump (e.g., ductless minisplit) with ducted (e.g., furnace) or ductless (e.g., boiler) backup
        # e.g., ducted heat pump (e.g., ashp, gshp) with ductless (e.g., boiler) backup
        elsif heat_pump_backup_type == HPXML::HeatPumpBackupTypeSeparate

          hpxml_bldg.heating_systems.add(**heating_system.to_h)

          if not heating_system.distribution_system.nil?
            hpxml_bldg.hvac_distributions.add(**heating_system.distribution_system.to_h)
            hvac_distribution = hpxml_bldg.hvac_distributions[-1]

            heating_system.distribution_system.duct_leakage_measurements.each do |duct_leakage_measurement|
              hvac_distribution.duct_leakage_measurements.add(**duct_leakage_measurement.to_h)
            end

            heating_system.distribution_system.ducts.each do |duct|
              hvac_distribution.ducts.add(**duct.to_h)
            end
          end

          heating_system = hpxml_bldg.heating_systems[-1]
          heating_system.id = "HeatingSystem#{hpxml_bldg.heating_systems.size}"
          heating_system.primary_system = nil
          heating_system.fraction_heat_load_served = nil

          if not hvac_distribution.nil?
            hvac_distribution.id = "HVACDistribution#{hpxml_bldg.hvac_distributions.size}"
            heating_system.distribution_system_idref = hvac_distribution.id
          end

          heat_pump.fraction_heat_load_served = 1.0 # It's possible this was < 1.0 due to adjustment for secondary heating system
          heat_pump.backup_heating_fuel = nil
          heat_pump.backup_heating_efficiency_afue = nil
          heat_pump.backup_heating_efficiency_percent = nil
          heat_pump.backup_heating_capacity = nil
          heat_pump.backup_heating_autosizing_factor = nil
          heat_pump.backup_type = heat_pump_backup_type
          heat_pump.backup_system_idref = heating_system.id

          runner.registerInfo("Found '#{heating_system.heating_system_type}' heating system type; setting it as 'heat_pump_backup_type=#{heat_pump_backup_type}'.")
        end
      else
        runner.registerWarning('Either a primary heating system was not found, or it was found but is a shared system; not setting it as heat pump backup.')
      end
    end
  end
end

def get_heating_system(hpxml_bldg)
  return hpxml_bldg.heating_systems.find { |h| h.primary_system && !h.is_shared_system }
end

def get_heat_pump(hpxml_bldg)
  return hpxml_bldg.heat_pumps.find { |h| h.primary_heating_system && h.primary_cooling_system && !h.is_shared_system }
end

def get_heat_pump_backup_type(heating_distribution_system, heat_pump_type, heat_pump_is_ducted)
  ducted_backup = (!heating_distribution_system.nil? && heating_distribution_system.distribution_system_type == HPXML::HVACDistributionTypeAir)
  if ducted_backup
    if ([HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpGroundToAir].include?(heat_pump_type) ||
       ([HPXML::HVACTypeHeatPumpMiniSplit].include?(heat_pump_type) && heat_pump_is_ducted))
      return HPXML::HeatPumpBackupTypeIntegrated
    end
  end

  return HPXML::HeatPumpBackupTypeSeparate
end

def get_heat_pump_backup_values(heating_system)
  heating_system_type = heating_system.heating_system_type
  heat_pump_backup_fuel = heating_system.heating_system_fuel
  if not heating_system.heating_efficiency_afue.nil?
    heat_pump_backup_heating_efficiency = heating_system.heating_efficiency_afue
  elsif not heating_system.heating_efficiency_percent.nil?
    heat_pump_backup_heating_efficiency = heating_system.heating_efficiency_percent
  end
  heat_pump_backup_heating_capacity = heating_system.heating_capacity
  heat_pump_backup_heating_autosizing_factor = heating_system.heating_autosizing_factor
  values = {
    'heating_system_type' => heating_system_type,
    'heat_pump_backup_fuel' => heat_pump_backup_fuel,
    'heat_pump_backup_heating_efficiency' => heat_pump_backup_heating_efficiency,
    'heat_pump_backup_heating_capacity' => heat_pump_backup_heating_capacity,
    'heat_pump_backup_heating_autosizing_factor' => heat_pump_backup_heating_autosizing_factor
  }
  return values
end
