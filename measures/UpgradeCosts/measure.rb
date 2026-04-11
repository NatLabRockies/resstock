# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require_relative 'resources/constants'
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

    # Initialize
    bldg_outputs = {}
    bldg_outputs[BO::EnclosureWallAreaThermalBoundary] = BaseOutput.new
    bldg_outputs[BO::EnclosureWallAreaExterior] = BaseOutput.new
    bldg_outputs[BO::EnclosureFoundationWallAreaExterior] = BaseOutput.new
    bldg_outputs[BO::EnclosureFloorAreaConditioned] = BaseOutput.new
    bldg_outputs[BO::EnclosureFloorAreaLighting] = BaseOutput.new
    bldg_outputs[BO::EnclosureFloorAreaFoundation] = BaseOutput.new
    bldg_outputs[BO::EnclosureCeilingAreaThermalBoundary] = BaseOutput.new
    bldg_outputs[BO::EnclosureRoofArea] = BaseOutput.new
    bldg_outputs[BO::EnclosureWindowArea] = BaseOutput.new
    bldg_outputs[BO::EnclosureDoorArea] = BaseOutput.new
    bldg_outputs[BO::EnclosureDuctAreaUnconditioned] = BaseOutput.new
    bldg_outputs[BO::EnclosureRimJoistAreaExterior] = BaseOutput.new
    bldg_outputs[BO::EnclosureSlabExposedPerimeterThermalBoundary] = BaseOutput.new
    bldg_outputs[BO::SystemsCoolingCapacity] = BaseOutput.new
    bldg_outputs[BO::SystemsHeatingCapacity] = BaseOutput.new
    bldg_outputs[BO::SystemsHeatPumpBackupCapacity] = BaseOutput.new
    bldg_outputs[BO::SystemsWaterHeaterVolume] = BaseOutput.new
    bldg_outputs[BO::SystemsMechanicalVentilationFlowRate] = BaseOutput.new

    hpxml.buildings.each do |hpxml_bldg|
      # Building outputs
      bldg_outputs.each do |bldg_type, bldg_output|
        bldg_output.output += get_hpxml_output(hpxml_bldg, bldg_type)
      end

      # Primary and Secondary
      if hpxml_bldg.primary_hvac_systems.size > 0
        assign_primary_and_secondary(hpxml_bldg, bldg_outputs)
      end
    end

    # Units
    bldg_outputs.each do |bldg_type, bldg_output|
      bldg_output.units = BO.get_units(bldg_type)
    end

    # Retrieve values from ApplyUpgrade
    values = {}
    apply_upgrade = runner.getPastStepValuesForMeasure('apply_upgrade')
    values['apply_upgrade'] = Hash[apply_upgrade.collect { |k, v| [k.to_s, v] }]

    # Modify bldg_outputs hash
    values['hpxml_output'] = {}
    bldg_outputs.each do |key, bldg_output|
      name = OpenStudio::toUnderscoreCase("#{key} (#{bldg_output.units})").chomp('_')
      value = bldg_output.output.round(2)
      values['hpxml_output'][name] = value
    end

    # Report cost multipliers
    existing_hpxml = nil
    upgraded_hpxml = nil
    cost_multiplier_choices.each do |cost_mult_type|
      next if cost_mult_type.empty?
      next if cost_mult_type.include?('Fixed')

      cost_mult_type_str = OpenStudio::toUnderscoreCase(cost_mult_type)
      cost_mult = get_bldg_output(cost_mult_type, values, existing_hpxml, upgraded_hpxml)
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
        cost_mult = get_bldg_output(cost_mult_type, values, existing_hpxml, upgraded_hpxml)
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

  def get_bldg_output(cost_mult_type, values, existing_hpxml, upgraded_hpxml)
    hpxml = values['hpxml_output']

    cost_mult = 0.0
    if cost_mult_type == 'Fixed (1)'
      cost_mult += 1.0
    elsif cost_mult_type == 'Wall Area, Above-Grade, Conditioned (ft^2)'
      cost_mult += hpxml['enclosure_wall_area_thermal_boundary_ft_2']
    elsif cost_mult_type == 'Wall Area, Above-Grade, Exterior (ft^2)'
      cost_mult += hpxml['enclosure_wall_area_exterior_ft_2']
    elsif cost_mult_type == 'Wall Area, Below-Grade (ft^2)'
      cost_mult += hpxml['enclosure_foundation_wall_area_exterior_ft_2']
    elsif cost_mult_type == 'Floor Area, Conditioned (ft^2)'
      cost_mult += hpxml['enclosure_floor_area_conditioned_ft_2']
    elsif cost_mult_type == 'Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)'
      existing_hpxml, upgraded_hpxml = retrieve_hpxmls(existing_hpxml, upgraded_hpxml)
      if !upgraded_hpxml.nil?
        air_leakage_value = { existing_hpxml => [], upgraded_hpxml => [] }
        [existing_hpxml, upgraded_hpxml].each do |hpxml_obj|
          hpxml_obj.buildings[0].air_infiltration_measurements.each do |air_infiltration_measurement|
            air_leakage_value[hpxml_obj] << air_infiltration_measurement.air_leakage unless air_infiltration_measurement.air_leakage.nil?
          end
        end
        fail 'Found multiple air infiltration measurement values.' if air_leakage_value[existing_hpxml].uniq.size > 1 || air_leakage_value[upgraded_hpxml].uniq.size > 1

        if !air_leakage_value[existing_hpxml].empty? && !air_leakage_value[upgraded_hpxml].empty?
          air_leakage_value_reduction = air_leakage_value[existing_hpxml][0] - air_leakage_value[upgraded_hpxml][0]
          cost_mult += air_leakage_value_reduction * hpxml['enclosure_floor_area_conditioned_ft_2']
        end
      end
    elsif cost_mult_type == 'Floor Area, Lighting (ft^2)'
      cost_mult += hpxml['enclosure_floor_area_lighting_ft_2']
    elsif cost_mult_type == 'Floor Area, Foundation (ft^2)'
      cost_mult += hpxml['enclosure_floor_area_foundation_ft_2']
    elsif cost_mult_type == 'Floor Area, Attic (ft^2)'
      cost_mult += hpxml['enclosure_ceiling_area_thermal_boundary_ft_2']
    elsif cost_mult_type == 'Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)'
      existing_hpxml, upgraded_hpxml = retrieve_hpxmls(existing_hpxml, upgraded_hpxml)
      if !upgraded_hpxml.nil?
        ceiling_assembly_r = { existing_hpxml => [], upgraded_hpxml => [] }
        [existing_hpxml, upgraded_hpxml].each do |hpxml_obj|
          hpxml_obj.buildings[0].floors.each do |floor|
            next unless floor.is_thermal_boundary
            next unless floor.is_interior
            next unless floor.is_ceiling
            next unless [HPXML::LocationAtticVented,
                         HPXML::LocationAtticUnvented].include?(floor.exterior_adjacent_to)

            ceiling_assembly_r[hpxml_obj] << floor.insulation_assembly_r_value unless floor.insulation_assembly_r_value.nil?
          end
        end
        fail 'Found multiple ceiling assembly R-values.' if ceiling_assembly_r[existing_hpxml].uniq.size > 1 || ceiling_assembly_r[upgraded_hpxml].uniq.size > 1

        if !ceiling_assembly_r[existing_hpxml].empty? && !ceiling_assembly_r[upgraded_hpxml].empty?
          ceiling_insulation_r_upgraded = upgraded_hpxml.buildings[0].header.extension_properties['ceiling_insulation_r'].to_f
          ceiling_insulation_r_existing = existing_hpxml.buildings[0].header.extension_properties['ceiling_insulation_r'].to_f
          ceiling_assembly_r_increase = ceiling_insulation_r_upgraded - ceiling_insulation_r_existing
          cost_mult += ceiling_assembly_r_increase * hpxml['enclosure_ceiling_area_thermal_boundary_ft_2']
        end
      end
    elsif cost_mult_type == 'Roof Area (ft^2)'
      cost_mult += hpxml['enclosure_roof_area_ft_2']
    elsif cost_mult_type == 'Window Area (ft^2)'
      cost_mult += hpxml['enclosure_window_area_ft_2']
    elsif cost_mult_type == 'Door Area (ft^2)'
      cost_mult += hpxml['enclosure_door_area_ft_2']
    elsif cost_mult_type == 'Duct Unconditioned Surface Area (ft^2)'
      cost_mult += hpxml['enclosure_duct_area_unconditioned_ft_2']
    elsif cost_mult_type == 'Rim Joist Area, Above-Grade, Exterior (ft^2)'
      cost_mult += hpxml['enclosure_rim_joist_area_ft_2']
    elsif cost_mult_type == 'Slab Perimeter, Exposed, Conditioned (ft)'
      cost_mult += hpxml['enclosure_slab_exposed_perimeter_thermal_boundary_ft']
    elsif cost_mult_type == 'Size, Heating System Primary (kBtu/h)'
      if hpxml.keys.include?('primary_systems_heating_capacity_btu_h')
        cost_mult += UnitConversions.convert(hpxml['primary_systems_heating_capacity_btu_h'], 'btu/hr', 'kbtu/hr')
      end
    elsif cost_mult_type == 'Size, Heating System Secondary (kBtu/h)'
      if hpxml.keys.include?('secondary_systems_heating_capacity_btu_h')
        cost_mult += UnitConversions.convert(hpxml['secondary_systems_heating_capacity_btu_h'], 'btu/hr', 'kbtu/hr')
      end
    elsif cost_mult_type == 'Size, Cooling System Primary (kBtu/h)'
      if hpxml.keys.include?('primary_systems_cooling_capacity_btu_h')
        cost_mult += UnitConversions.convert(hpxml['primary_systems_cooling_capacity_btu_h'], 'btu/hr', 'kbtu/hr')
      end
    elsif cost_mult_type == 'Size, Heat Pump Backup Primary (kBtu/h)'
      if hpxml.keys.include?('primary_systems_heat_pump_backup_capacity_btu_h')
        cost_mult += UnitConversions.convert(hpxml['primary_systems_heat_pump_backup_capacity_btu_h'], 'btu/hr', 'kbtu/hr')
      end
    elsif cost_mult_type == 'Size, Water Heater (gal)'
      cost_mult += hpxml['systems_water_heater_tank_volume_gal']
    elsif cost_mult_type == 'Flow Rate, Mechanical Ventilation (cfm)'
      cost_mult += hpxml['systems_mechanical_ventilation_flow_rate_cfm']
    end
    return cost_mult
  end # end get_cost_multiplier

  class BaseOutput
    def initialize()
      @output = 0.0
    end
    attr_accessor(:output, :units)
  end

  def get_hpxml_output(hpxml_bldg, bldg_type)
    bldg_output = 0.0
    if bldg_type == BO::EnclosureWallAreaThermalBoundary
      hpxml_bldg.walls.each do |wall|
        next unless wall.is_thermal_boundary

        bldg_output += wall.area
      end
    elsif bldg_type == BO::EnclosureWallAreaExterior
      hpxml_bldg.walls.each do |wall|
        next unless wall.is_exterior

        bldg_output += wall.area
      end
    elsif bldg_type == BO::EnclosureFoundationWallAreaExterior
      hpxml_bldg.foundation_walls.each do |foundation_wall|
        next unless foundation_wall.is_exterior

        bldg_output += foundation_wall.area
      end
    elsif bldg_type == BO::EnclosureFloorAreaConditioned
      bldg_output += hpxml_bldg.building_construction.conditioned_floor_area
    elsif bldg_type == BO::EnclosureFloorAreaLighting
      if hpxml_bldg.lighting.interior_usage_multiplier.to_f != 0
        bldg_output += hpxml_bldg.building_construction.conditioned_floor_area
      end
      hpxml_bldg.slabs.each do |slab|
        next unless [HPXML::LocationGarage].include?(slab.interior_adjacent_to)
        next if hpxml_bldg.lighting.garage_usage_multiplier.to_f == 0

        bldg_output += slab.area
      end
    elsif bldg_type == BO::EnclosureFloorAreaFoundation
      hpxml_bldg.slabs.each do |slab|
        next if slab.interior_adjacent_to == HPXML::LocationGarage

        bldg_output += slab.area
      end
    elsif bldg_type == BO::EnclosureCeilingAreaThermalBoundary
      hpxml_bldg.floors.each do |floor|
        next unless floor.is_thermal_boundary
        next unless floor.is_interior
        next unless floor.is_ceiling
        next unless [HPXML::LocationAtticVented,
                     HPXML::LocationAtticUnvented].include?(floor.exterior_adjacent_to)

        bldg_output += floor.area
      end
    elsif bldg_type == BO::EnclosureRoofArea
      hpxml_bldg.roofs.each do |roof|
        bldg_output += roof.area
      end
    elsif bldg_type == BO::EnclosureWindowArea
      hpxml_bldg.windows.each do |window|
        bldg_output += window.area
      end
    elsif bldg_type == BO::EnclosureDoorArea
      hpxml_bldg.doors.each do |door|
        next unless door.is_thermal_boundary

        bldg_output += door.area
      end
    elsif bldg_type == BO::EnclosureDuctAreaUnconditioned
      hpxml_bldg.hvac_distributions.each do |hvac_distribution|
        hvac_distribution.ducts.each do |duct|
          next if [HPXML::LocationConditionedSpace,
                   HPXML::LocationBasementConditioned].include?(duct.duct_location)

          bldg_output += duct.duct_surface_area * duct.duct_surface_area_multiplier
        end
      end
    elsif bldg_type == BO::EnclosureRimJoistAreaExterior
      hpxml_bldg.rim_joists.each do |rim_joist|
        bldg_output += rim_joist.area
      end
    elsif bldg_type == BO::EnclosureSlabExposedPerimeterThermalBoundary
      hpxml_bldg.slabs.each do |slab|
        next unless slab.is_exterior_thermal_boundary

        bldg_output += slab.exposed_perimeter
      end
    elsif bldg_type == BO::SystemsHeatingCapacity
      hpxml_bldg.heating_systems.each do |heating_system|
        next if heating_system.is_heat_pump_backup_system

        bldg_output += heating_system.heating_capacity
      end

      hpxml_bldg.heat_pumps.each do |heat_pump|
        bldg_output += heat_pump.heating_capacity
      end
    elsif bldg_type == BO::SystemsCoolingCapacity
      hpxml_bldg.cooling_systems.each do |cooling_system|
        bldg_output += cooling_system.cooling_capacity
      end

      hpxml_bldg.heat_pumps.each do |heat_pump|
        bldg_output += heat_pump.cooling_capacity
      end
    elsif bldg_type == BO::SystemsHeatPumpBackupCapacity
      hpxml_bldg.heat_pumps.each do |heat_pump|
        if not heat_pump.backup_heating_capacity.nil?
          bldg_output += heat_pump.backup_heating_capacity
        elsif not heat_pump.backup_system.nil?
          bldg_output += heat_pump.backup_system.heating_capacity
        end
      end
    elsif bldg_type == BO::SystemsWaterHeaterVolume
      hpxml_bldg.water_heating_systems.each do |water_heating_system|
        bldg_output += water_heating_system.tank_volume.to_f
      end
    elsif bldg_type == BO::SystemsMechanicalVentilationFlowRate
      hpxml_bldg.ventilation_fans.each do |ventilation_fan|
        next unless ventilation_fan.used_for_whole_building_ventilation

        bldg_output += ventilation_fan.flow_rate.to_f
      end
    end
    return bldg_output
  end

  def assign_primary_and_secondary(hpxml_bldg, bldg_outputs)
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

    # Set up order of outputs
    if has_primary_cooling_system && !bldg_outputs.keys.include?("Primary #{BO::SystemsCoolingCapacity}")
      bldg_outputs["Primary #{BO::SystemsCoolingCapacity}"] = BaseOutput.new
    end

    if has_primary_heating_system && !bldg_outputs.keys.include?("Primary #{BO::SystemsHeatingCapacity}") && !bldg_outputs.keys.include?("Primary #{BO::SystemsHeatPumpBackupCapacity}")
      bldg_outputs["Primary #{BO::SystemsHeatingCapacity}"] = BaseOutput.new
      bldg_outputs["Primary #{BO::SystemsHeatPumpBackupCapacity}"] = BaseOutput.new
    end

    if has_secondary_cooling_system && !bldg_outputs.keys.include?("Secondary #{BO::SystemsCoolingCapacity}")
      bldg_outputs["Secondary #{BO::SystemsCoolingCapacity}"] = BaseOutput.new
    end

    if has_secondary_heating_system && !bldg_outputs.keys.include?("Secondary #{BO::SystemsHeatingCapacity}") && !bldg_outputs.keys.include?("Secondary #{BO::SystemsHeatPumpBackupCapacity}")
      bldg_outputs["Secondary #{BO::SystemsHeatingCapacity}"] = BaseOutput.new
      bldg_outputs["Secondary #{BO::SystemsHeatPumpBackupCapacity}"] = BaseOutput.new
    end

    # Obtain values
    if has_primary_cooling_system || has_secondary_cooling_system
      hpxml_bldg.cooling_systems.each do |cooling_system|
        prefix = cooling_system.primary_system ? 'Primary' : 'Secondary'
        bldg_outputs["#{prefix} #{BO::SystemsCoolingCapacity}"].output += cooling_system.cooling_capacity
      end
      hpxml_bldg.heat_pumps.each do |heat_pump|
        prefix = heat_pump.primary_cooling_system ? 'Primary' : 'Secondary'
        bldg_outputs["#{prefix} #{BO::SystemsCoolingCapacity}"].output += heat_pump.cooling_capacity
      end
    end

    if has_primary_heating_system || has_secondary_heating_system
      hpxml_bldg.heating_systems.each do |heating_system|
        next if heating_system.is_heat_pump_backup_system

        prefix = heating_system.primary_system ? 'Primary' : 'Secondary'
        bldg_outputs["#{prefix} #{BO::SystemsHeatingCapacity}"].output += heating_system.heating_capacity
      end
      hpxml_bldg.heat_pumps.each do |heat_pump|
        prefix = heat_pump.primary_heating_system ? 'Primary' : 'Secondary'
        bldg_outputs["#{prefix} #{BO::SystemsHeatingCapacity}"].output += heat_pump.heating_capacity
        if not heat_pump.backup_heating_capacity.nil?
          bldg_outputs["#{prefix} #{BO::SystemsHeatPumpBackupCapacity}"].output += heat_pump.backup_heating_capacity
        elsif not heat_pump.backup_system.nil?
          bldg_outputs["#{prefix} #{BO::SystemsHeatPumpBackupCapacity}"].output += heat_pump.backup_system.heating_capacity
        end
      end
    end
  end
end

# register the measure to be used by the application
UpgradeCosts.new.registerWithApplication
