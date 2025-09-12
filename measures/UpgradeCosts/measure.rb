# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require_relative '../ApplyUpgrade/resources/constants'
require_relative '../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/meta_measure'

# start the measure
class UpgradeCosts < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Upgrade Costs'
  end

  # human readable description
  def description
    return 'Measure that calculates upgrade costs.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Multiplies cost value by cost multiplier.'
  end

  # define the arguments that the user will input
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('debug', false)
    arg.setDisplayName('Debug Mode?')
    arg.setDescription('If true, retain existing and upgraded intermediate files.')
    arg.setDefaultValue(false)
    args << arg

    return args
  end

  def num_options
    return Constants::NumApplyUpgradeOptions # Synced with ApplyUpgrade measure
  end

  def num_costs_per_option
    return Constants::NumApplyUpgradesCostsPerOption # Synced with ApplyUpgrade measure
  end

  def cost_multiplier_choices
    return Constants::CostMultiplierChoices # Synced with ApplyUpgrade measure
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking (need model)
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    debug = runner.getBoolArgumentValue('debug', user_arguments)

    hpxml_defaults_path = model.getBuilding.additionalProperties.getFeatureAsString('hpxml_defaults_path').get
    hpxml = HPXML.new(hpxml_path: hpxml_defaults_path)

    # Retrieve values from ApplyUpgrade
    values = {}
    apply_upgrade = runner.getPastStepValuesForMeasure('apply_upgrade')
    values['apply_upgrade'] = Hash[apply_upgrade.collect { |k, v| [k.to_s, v] }]

    # Report cost multipliers
    existing_hpxml = nil
    upgraded_hpxml = nil
    cost_multiplier_choices.each do |cost_mult_type|
      next if cost_mult_type.empty?
      next if cost_mult_type.include?('Fixed')

      cost_mult_type_str = OpenStudio::toUnderscoreCase(cost_mult_type)
      cost_mult = get_bldg_output(cost_mult_type, hpxml, existing_hpxml, upgraded_hpxml)
      cost_mult = cost_mult.round(2)
      register_value(runner, cost_mult_type_str, cost_mult)
    end

    # UPGRADE COSTS
    upgrade_cost_name = 'upgrade_cost_usd'

    # Get upgrade cost value/multiplier pairs and lifetimes from the upgrade measure
    has_costs = false
    option_cost_pairs = {}
    option_names = {}
    option_lifetimes = {}
    for option_num in 1..num_options # Sync with ApplyUpgrade measure
      option_cost_pairs[option_num] = []
      option_names[option_num] = nil
      option_lifetimes[option_num] = nil
      for cost_num in 1..num_costs_per_option # Sync with ApplyUpgrade measure
        cost_value = values['apply_upgrade']["option_%02d_cost_#{cost_num}_value_to_apply" % option_num]
        next if cost_value.nil?

        cost_mult_type = values['apply_upgrade']["option_%02d_cost_#{cost_num}_multiplier_to_apply" % option_num]
        next if cost_mult_type.nil?

        has_costs = true
        option_cost_pairs[option_num] << [cost_value.to_f, cost_mult_type]
      end
      name = values['apply_upgrade']['option_%02d_name_applied' % option_num]
      lifetime = values['apply_upgrade']['option_%02d_lifetime_to_apply' % option_num]

      option_names[option_num] = name
      option_lifetimes[option_num] = lifetime.to_f if !lifetime.nil?
    end

    if not has_costs
      remove_intermediate_files() if !debug
      register_value(runner, upgrade_cost_name, 0.0)
      runner.registerInfo("Registering 0.0 for #{upgrade_cost_name}.")
      return true
    end

    # Obtain cost multiplier values and calculate upgrade costs
    upgrade_cost = 0.0
    option_cost_pairs.keys.each do |option_num|
      next if option_cost_pairs[option_num].empty?

      option_cost = 0.0
      option_cost_pairs[option_num].each do |cost_value, cost_mult_type|
        cost_mult = get_bldg_output(cost_mult_type, hpxml, existing_hpxml, upgraded_hpxml)
        total_cost = cost_value * cost_mult
        next if total_cost == 0

        option_cost += total_cost
        runner.registerInfo("Upgrade cost addition: $#{cost_value} x #{cost_mult} [#{cost_mult_type}] = #{total_cost}.")
      end
      upgrade_cost += option_cost

      # Save option cost/name/lifetime to results.csv
      name = option_names[option_num]
      option_name = 'option_%02d_name' % option_num
      register_value(runner, option_name, name)
      runner.registerInfo("Registering #{name} for #{option_name}.")
      next unless option_cost != 0

      option_cost = option_cost.round(2)
      option_cost_name = 'option_%02d_cost_usd' % option_num
      register_value(runner, option_cost_name, option_cost)
      runner.registerInfo("Registering #{option_cost} for #{option_cost_name}.")
      next unless (not option_lifetimes[option_num].nil?) && (option_lifetimes[option_num] != 0)

      lifetime = option_lifetimes[option_num].round(2)
      option_lifetime_name = 'option_%02d_lifetime_yrs' % option_num
      register_value(runner, option_lifetime_name, lifetime)
      runner.registerInfo("Registering #{lifetime} for #{option_lifetime_name}.")
    end
    upgrade_cost = upgrade_cost.round(2)
    register_value(runner, upgrade_cost_name, upgrade_cost)
    runner.registerInfo("Registering #{upgrade_cost} for #{upgrade_cost_name}.")

    remove_intermediate_files() if !debug

    return true
  end

  def remove_intermediate_files()
    FileUtils.rm_rf(File.expand_path('../existing.osw'))
    FileUtils.rm_rf(File.expand_path('../existing.xml'))
    FileUtils.rm_rf(File.expand_path('../upgraded.osw'))
    FileUtils.rm_rf(File.expand_path('../upgraded.xml'))
  end

  def retrieve_hpxmls(existing_hpxml, upgraded_hpxml)
    if existing_hpxml.nil? && upgraded_hpxml.nil?
      existing_path = File.expand_path('../existing.xml')
      existing_hpxml = HPXML.new(hpxml_path: existing_path) if File.exist?(existing_path)

      upgraded_path = File.expand_path('../upgraded.xml')
      upgraded_hpxml = HPXML.new(hpxml_path: upgraded_path) if File.exist?(upgraded_path)
    end

    return existing_hpxml, upgraded_hpxml
  end

  def get_bldg_output(cost_mult_type, hpxml, existing_hpxml, upgraded_hpxml)
    systems = assign_primary_and_secondary(hpxml)

    cost_mult = 0.0

    if cost_mult_type == 'Fixed (1)'
      cost_mult += 1.0
    elsif cost_mult_type == 'Wall Area, Above-Grade, Conditioned (ft^2)'
      hpxml.buildings.each do |hpxml_bldg|
        hpxml_bldg.walls.each do |wall|
          next unless wall.is_thermal_boundary

          cost_mult += wall.area
        end
      end
    elsif cost_mult_type == 'Wall Area, Above-Grade, Exterior (ft^2)'
      hpxml.buildings.each do |hpxml_bldg|
        hpxml_bldg.walls.each do |wall|
          next unless wall.is_exterior

          cost_mult += wall.area
        end
      end
    elsif cost_mult_type == 'Wall Area, Below-Grade (ft^2)'
      hpxml.buildings.each do |hpxml_bldg|
        hpxml_bldg.foundation_walls.each do |foundation_wall|
          next unless foundation_wall.is_exterior

          cost_mult += foundation_wall.area
        end
      end
    elsif cost_mult_type == 'Floor Area, Conditioned (ft^2)'
      hpxml.buildings.each do |hpxml_bldg|
        cost_mult += hpxml_bldg.building_construction.conditioned_floor_area
      end
    elsif cost_mult_type == 'Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)'
      existing_hpxml, upgraded_hpxml = retrieve_hpxmls(existing_hpxml, upgraded_hpxml)
      if !upgraded_hpxml.nil?
        existing_hpxml.buildings.zip(upgraded_hpxml.buildings).each do |existing_bldg, upgraded_bldg|
          fail 'Found multiple air infiltration measurement values.' if existing_bldg.air_infiltration_measurements.size > 1
          fail 'Found multiple air infiltration measurement values.' if upgraded_bldg.air_infiltration_measurements.size > 1

          existing_bldg.air_infiltration_measurements.zip(upgraded_bldg.air_infiltration_measurements).each do |existing_meas, upgraded_meas|
            if !existing_meas.air_leakage.nil? && !upgraded_meas.air_leakage.nil?
              air_leakage_reduction = existing_meas.air_leakage - upgraded_meas.air_leakage
              cost_mult += air_leakage_reduction * upgraded_bldg.building_construction.conditioned_floor_area
            end
          end
        end
      end
    elsif cost_mult_type == 'Floor Area, Lighting (ft^2)'
      hpxml.buildings.each do |hpxml_bldg|
        if hpxml_bldg.lighting.interior_usage_multiplier.to_f != 0
          cost_mult += hpxml_bldg.building_construction.conditioned_floor_area
        end
        hpxml_bldg.slabs.each do |slab|
          next unless [HPXML::LocationGarage].include?(slab.interior_adjacent_to)
          next if hpxml_bldg.lighting.garage_usage_multiplier.to_f == 0

          cost_mult += slab.area
        end
      end
    elsif cost_mult_type == 'Floor Area, Foundation (ft^2)'
      hpxml.buildings.each do |hpxml_bldg|
        hpxml_bldg.slabs.each do |slab|
          next if slab.interior_adjacent_to == HPXML::LocationGarage

          cost_mult += slab.area
        end
      end
    elsif cost_mult_type == 'Floor Area, Attic (ft^2)'
      hpxml.buildings.each do |hpxml_bldg|
        hpxml_bldg.floors.each do |floor|
          next unless floor.is_thermal_boundary
          next unless floor.is_interior
          next unless floor.is_ceiling
          next unless [HPXML::LocationAtticVented,
                       HPXML::LocationAtticUnvented].include?(floor.exterior_adjacent_to)

          cost_mult += floor.area
        end
      end
    elsif cost_mult_type == 'Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)'
      existing_hpxml, upgraded_hpxml = retrieve_hpxmls(existing_hpxml, upgraded_hpxml)
      if !upgraded_hpxml.nil?
        existing_hpxml.buildings.zip(upgraded_hpxml.buildings).each do |existing_bldg, upgraded_bldg|
          next unless existing_bldg.header.extension_properties.include?('ceiling_insulation_r') && upgraded_bldg.header.extension_properties.include?('ceiling_insulation_r')

          ceiling_assembly_r_increase = upgraded_bldg.header.extension_properties['ceiling_insulation_r'].to_f - existing_bldg.header.extension_properties['ceiling_insulation_r'].to_f
          upgraded_bldg.floors.each do |floor|
            next unless floor.is_thermal_boundary
            next unless floor.is_interior
            next unless floor.is_ceiling
            next unless [HPXML::LocationAtticVented,
                         HPXML::LocationAtticUnvented].include?(floor.exterior_adjacent_to)

            cost_mult += ceiling_assembly_r_increase * floor.area
          end
        end
      end
    elsif cost_mult_type == 'Roof Area (ft^2)'
      hpxml.buildings.each do |hpxml_bldg|
        hpxml_bldg.roofs.each do |roof|
          cost_mult += roof.area
        end
      end
    elsif cost_mult_type == 'Window Area (ft^2)'
      hpxml.buildings.each do |hpxml_bldg|
        hpxml_bldg.windows.each do |window|
          cost_mult += window.area
        end
      end
    elsif cost_mult_type == 'Door Area (ft^2)'
      hpxml.buildings.each do |hpxml_bldg|
        hpxml_bldg.doors.each do |door|
          next unless door.is_thermal_boundary

          cost_mult += door.area
        end
      end
    elsif cost_mult_type == 'Duct Unconditioned Surface Area (ft^2)'
      hpxml.buildings.each do |hpxml_bldg|
        hpxml_bldg.hvac_distributions.each do |hvac_distribution|
          hvac_distribution.ducts.each do |duct|
            next if [HPXML::LocationConditionedSpace,
                     HPXML::LocationBasementConditioned].include?(duct.duct_location)

            cost_mult += duct.duct_surface_area * duct.duct_surface_area_multiplier
          end
        end
      end
    elsif cost_mult_type == 'Rim Joist Area, Above-Grade, Exterior (ft^2)'
      hpxml.buildings.each do |hpxml_bldg|
        hpxml_bldg.rim_joists.each do |rim_joist|
          cost_mult += rim_joist.area
        end
      end
    elsif cost_mult_type == 'Slab Perimeter, Exposed, Conditioned (ft)'
      hpxml.buildings.each do |hpxml_bldg|
        hpxml_bldg.slabs.each do |slab|
          next unless slab.is_exterior_thermal_boundary

          cost_mult += slab.exposed_perimeter
        end
      end
    elsif cost_mult_type == 'Size, Heating System Primary (kBtu/h)'
      cost_mult += UnitConversions.convert(systems['PrimarySystemsHeatingCapacity'], 'btu/hr', 'kbtu/hr')
    elsif cost_mult_type == 'Size, Heating System Secondary (kBtu/h)'
      cost_mult += UnitConversions.convert(systems['SecondarySystemsHeatingCapacity'], 'btu/hr', 'kbtu/hr')
    elsif cost_mult_type == 'Size, Cooling System Primary (kBtu/h)'
      cost_mult += UnitConversions.convert(systems['PrimarySystemsCoolingCapacity'], 'btu/hr', 'kbtu/hr')
    elsif cost_mult_type == 'Size, Heat Pump Backup Primary (kBtu/h)'
      cost_mult += UnitConversions.convert(systems['PrimarySystemsHeatPumpBackupCapacity'], 'btu/hr', 'kbtu/hr')
    elsif cost_mult_type == 'Size, Water Heater (gal)'
      hpxml.buildings.each do |hpxml_bldg|
        hpxml_bldg.water_heating_systems.each do |water_heating_system|
          cost_mult += water_heating_system.tank_volume.to_f
        end
      end
    elsif cost_mult_type == 'Flow Rate, Mechanical Ventilation (cfm)'
      hpxml.buildings.each do |hpxml_bldg|
        hpxml_bldg.ventilation_fans.each do |ventilation_fan|
          next unless ventilation_fan.used_for_whole_building_ventilation

          cost_mult += ventilation_fan.flow_rate.to_f
        end
      end
    end
    return cost_mult
  end # end get_cost_multiplier

  def assign_primary_and_secondary(hpxml)
    systems = { 'PrimarySystemsHeatingCapacity' => 0.0,
                'SecondarySystemsHeatingCapacity' => 0.0,
                'PrimarySystemsCoolingCapacity' => 0.0,
                'PrimarySystemsHeatPumpBackupCapacity' => 0.0 }

    hpxml.buildings.each do |hpxml_bldg|
      # Determine if we have primary/secondary systems
      has_primary_cooling_system = false
      has_secondary_cooling_system = false
      hpxml_bldg.cooling_systems.each do |cooling_system|
        has_primary_cooling_system = true if cooling_system.primary_system
        has_secondary_cooling_system = true if !cooling_system.primary_system
      end
      hpxml_bldg.heat_pumps.each do |heat_pump|
        has_primary_cooling_system = true if heat_pump.primary_cooling_system
        has_secondary_cooling_system = true if !heat_pump.primary_cooling_system
      end
      has_secondary_cooling_system = false unless has_primary_cooling_system

      has_primary_heating_system = false
      has_secondary_heating_system = false
      hpxml_bldg.heating_systems.each do |heating_system|
        next if heating_system.is_heat_pump_backup_system

        has_primary_heating_system = true if heating_system.primary_system
        has_secondary_heating_system = true if !heating_system.primary_system
      end
      hpxml_bldg.heat_pumps.each do |heat_pump|
        has_primary_heating_system = true if heat_pump.primary_heating_system
        has_secondary_heating_system = true if !heat_pump.primary_heating_system
      end
      has_secondary_heating_system = false unless has_primary_heating_system

      # Obtain values
      if has_primary_cooling_system || has_secondary_cooling_system
        hpxml_bldg.cooling_systems.each do |cooling_system|
          prefix = cooling_system.primary_system ? 'Primary' : 'Secondary'
          systems["#{prefix}SystemsCoolingCapacity"] += cooling_system.cooling_capacity
        end
        hpxml_bldg.heat_pumps.each do |heat_pump|
          prefix = heat_pump.primary_cooling_system ? 'Primary' : 'Secondary'
          systems["#{prefix}SystemsCoolingCapacity"] += heat_pump.cooling_capacity
        end
      end

      next unless has_primary_heating_system || has_secondary_heating_system

      hpxml_bldg.heating_systems.each do |heating_system|
        next if heating_system.is_heat_pump_backup_system

        prefix = heating_system.primary_system ? 'Primary' : 'Secondary'
        systems["#{prefix}SystemsHeatingCapacity"] += heating_system.heating_capacity
      end
      hpxml_bldg.heat_pumps.each do |heat_pump|
        prefix = heat_pump.primary_heating_system ? 'Primary' : 'Secondary'
        systems["#{prefix}SystemsHeatingCapacity"] += heat_pump.heating_capacity
        if not heat_pump.backup_heating_capacity.nil?
          systems["#{prefix}SystemsHeatPumpBackupCapacity"] += heat_pump.backup_heating_capacity
        elsif not heat_pump.backup_system.nil?
          systems["#{prefix}SystemsHeatPumpBackupCapacity"] += heat_pump.backup_system.heating_capacity
        end
      end
    end
    return systems
  end
end

# register the measure to be used by the application
UpgradeCosts.new.registerWithApplication
