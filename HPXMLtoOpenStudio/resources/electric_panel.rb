# frozen_string_literal: true

# Collection of methods related to electric panel load calculations.
module ElectricPanel
  # Calculates load-based capacity and breaker spaces for an electric panel.
  #
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param electric_panel [HPXML::ElectricPanel] Object that defines a single electric panel
  # @return [nil]
  def self.calculate(hpxml_header, hpxml_bldg, electric_panel)
    electric_panel.capacity_types = []
    electric_panel.capacity_total_watts = []
    electric_panel.capacity_total_amps = []
    electric_panel.capacity_headroom_amps = []
    hpxml_header.service_feeders_load_calculation_types.each do |service_feeders_load_calculation_type|
      if service_feeders_load_calculation_type == HPXML::ElectricPanelLoadCalculationType2023ExistingDwellingLoadBased
        load_based_capacity_values = LoadValues.new
        calculate_load_based(hpxml_bldg, electric_panel, load_based_capacity_values, service_feeders_load_calculation_type)

        electric_panel.capacity_types << service_feeders_load_calculation_type
        electric_panel.capacity_total_watts << load_based_capacity_values.Load_CapacityW.round(1)
        electric_panel.capacity_total_amps << load_based_capacity_values.Load_CapacityA.round(1)
        electric_panel.capacity_headroom_amps << load_based_capacity_values.Load_HeadRoomA.round(1)
      elsif service_feeders_load_calculation_type == HPXML::ElectricPanelLoadCalculationType2023ExistingDwellingMeterBased
        meter_based_capacity_values = LoadValues.new
        calculate_meter_based(hpxml_bldg, electric_panel, meter_based_capacity_values, service_feeders_load_calculation_type)

        electric_panel.capacity_types << service_feeders_load_calculation_type
        electric_panel.capacity_total_watts << meter_based_capacity_values.Load_CapacityW.round(1)
        electric_panel.capacity_total_amps << meter_based_capacity_values.Load_CapacityA.round(1)
        electric_panel.capacity_headroom_amps << meter_based_capacity_values.Load_HeadRoomA.round(1)
      end
    end

    calculate_breaker_spaces(electric_panel)
  end

  # Get the component attached to the given service feeder.
  #
  # @param components [Array<HPXML::XXX>] List of HPXML objects
  # @param [HPXML::ServiceFeeder] Object that defines a single electric panel service feeder
  # @return [HPXML::XXX] The component referenced by the service_feeder
  def self.get_service_feeder_component(components, service_feeder)
    components.each do |component|
      next if !service_feeder.component_idrefs.include?(component.id)

      return component
    end
    return
  end

  # Gets the electric panel's heating load.
  # The returned heating load depends on the following factors:
  # - whether the backup heating system can operate simultaneous with the primary heating system (if it can, we sum; if it can't, we take the max)
  # - whether we are tabulating all heating loads, only existing heating loads, or only new heating loads
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param electric_panel [HPXML::ElectricPanel] Object that defines a single electric panel
  # @param addition [nil or Boolean] Whether we are getting all, existing, or new heating loads
  # @return [Double] The electric panel's heating load (W)
  def self.get_service_feeder_heating(hpxml_bldg, electric_panel, addition: nil)
    htg = 0.0
    electric_panel.service_feeders.each do |service_feeder|
      next if service_feeder.type != HPXML::ElectricPanelLoadTypeHeating

      heating_system = get_service_feeder_component(hpxml_bldg.heating_systems, service_feeder)
      if !heating_system.nil?
        heating_system_watts = service_feeder.power
        primary_heat_pump_watts = 0
        if !heating_system.primary_heat_pump.nil?
          primary_heat_pump_watts = electric_panel.service_feeders.find { |sf| sf.component_idrefs.include?(heating_system.primary_heat_pump.id) }.power
        end

        if addition.nil? ||
           (addition && service_feeder.is_new_load) ||
           (!addition && !service_feeder.is_new_load)
          if (primary_heat_pump_watts == 0) ||
             (!heating_system.primary_heat_pump.nil? && heating_system.primary_heat_pump.overlapping_compressor_and_backup_operation) ||
             (!heating_system.primary_heat_pump.nil? && heating_system_watts >= primary_heat_pump_watts)
            htg += heating_system_watts
          end
        end
      end

      heat_pump = get_service_feeder_component(hpxml_bldg.heat_pumps, service_feeder)
      next unless !heat_pump.nil?

      heat_pump_watts = service_feeder.power
      backup_system_watts = 0
      if !heat_pump.backup_system.nil?
        backup_system_watts = electric_panel.service_feeders.find { |sf| sf.component_idrefs.include?(heat_pump.backup_system.id) }.power
      end

      next unless addition.nil? ||
                  (addition && service_feeder.is_new_load) ||
                  (!addition && !service_feeder.is_new_load)

      next unless (backup_system_watts == 0) ||
                  (!heat_pump.backup_system.nil? && heat_pump.overlapping_compressor_and_backup_operation) ||
                  (!heat_pump.backup_system.nil? && heat_pump_watts >= backup_system_watts)

      htg += heat_pump_watts
    end
    return htg
  end

  # Calculate the load-based capacity for the given electric panel and panel loads according to NEC 220.83.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param electric_panel [HPXML::ElectricPanel] Object that defines a single electric panel
  # @param service_feeders [LoadValues] Object with calculated load
  # @param service_feeders_load_calculation_type [String] the load calculation type
  # @return [nil]
  def self.calculate_load_based(hpxml_bldg, electric_panel, service_feeders, service_feeders_load_calculation_type)
    if service_feeders_load_calculation_type == HPXML::ElectricPanelLoadCalculationType2023ExistingDwellingLoadBased
      htg_existing = get_service_feeder_heating(hpxml_bldg, electric_panel, addition: false)
      htg_new = get_service_feeder_heating(hpxml_bldg, electric_panel, addition: true)
      clg_existing = electric_panel.service_feeders.select { |sf| sf.type == HPXML::ElectricPanelLoadTypeCooling && !sf.is_new_load }.map { |sf| sf.power }.sum(0.0)
      clg_new = electric_panel.service_feeders.select { |sf| sf.type == HPXML::ElectricPanelLoadTypeCooling && sf.is_new_load }.map { |sf| sf.power }.sum(0.0)

      hvac_load = [htg_existing + htg_new, clg_existing + clg_new].max
      other_load = 0.0
      electric_panel.service_feeders.each do |service_feeder|
        next if service_feeder.type == HPXML::ElectricPanelLoadTypeHeating || service_feeder.type == HPXML::ElectricPanelLoadTypeCooling

        other_load += service_feeder.power
      end

      if htg_new + clg_new == 0 # not adding new HVAC
        # Part A
        total_load = hvac_load + other_load
        total_load = discount_load(total_load, 8000.0, 0.4)
        service_feeders.Load_CapacityW = total_load
      else # adding new HVAC
        # Part B
        other_load = discount_load(other_load, 8000.0, 0.4)
        service_feeders.Load_CapacityW = hvac_load + other_load
      end

      service_feeders.Load_CapacityA = service_feeders.Load_CapacityW / Float(electric_panel.voltage)
      service_feeders.Load_HeadRoomA = electric_panel.max_current_rating - service_feeders.Load_CapacityA
    end
  end

  # Get the discounted load given the total load, threshold, and demand factor.
  #
  # @param [Double] load (W)
  # @param [Double] threshold (W)
  # @param [Double] demand factor (frac)
  # @return [Double] the discounted load (W)
  def self.discount_load(load, threshold, demand_factor)
    return 1.0 * [threshold, load].min + demand_factor * [0, load - threshold].max
  end

  # Calculate the meter-based capacity and headroom for the given electric panel and panel loads according to NEC 220.87.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param electric_panel [HPXML::ElectricPanel] Object that defines a single electric panel
  # @param service_feeders [LoadValues] Object with calculated load
  # @param service_feeders_load_calculation_type [String] the load calculation type
  # @return [Array<Double, Double, Double>] The capacity (W), the capacity (A), and headroom (A)
  def self.calculate_meter_based(hpxml_bldg, electric_panel, service_feeders, service_feeders_load_calculation_type)
    if service_feeders_load_calculation_type == HPXML::ElectricPanelLoadCalculationType2023ExistingDwellingMeterBased
      htg_new = get_service_feeder_heating(hpxml_bldg, electric_panel, addition: true)
      clg_new = electric_panel.service_feeders.select { |sf| sf.type == HPXML::ElectricPanelLoadTypeCooling && sf.is_new_load }.map { |sf| sf.power }.sum(0.0)

      new_loads = [htg_new, clg_new].max
      electric_panel.service_feeders.each do |service_feeder|
        next if service_feeder.type == HPXML::ElectricPanelLoadTypeHeating || service_feeder.type == HPXML::ElectricPanelLoadTypeCooling

        new_loads += service_feeder.power if service_feeder.is_new_load
      end

      peak_elec = hpxml_bldg.header.electric_panel_baseline_peak_power.to_f
      fail 'Expected ElectricPanelBaselinePeakPower to be greater than 0.' if peak_elec == 0 # EPvalidator.sch should prevent this

      service_feeders.Load_CapacityW = new_loads + 1.25 * peak_elec
      service_feeders.Load_CapacityA = service_feeders.Load_CapacityW / Float(electric_panel.voltage)
      service_feeders.Load_HeadRoomA = electric_panel.max_current_rating - service_feeders.Load_CapacityA
    end
  end

  # Calculate the number of panel breaker spaces corresponding to rated total spaces, occupied spaces, and headroom spaces.
  #
  # @param electric_panel [HPXML::ElectricPanel] Object that defines a single electric panel
  # @return [nil]
  def self.calculate_breaker_spaces(electric_panel)
    occupied_spaces = electric_panel.occupied_spaces

    if not electric_panel.rated_total_spaces.nil?
      rated_total_spaces = electric_panel.rated_total_spaces
    else
      rated_total_spaces = occupied_spaces + electric_panel.headroom_spaces # headroom_spaces is either specified or 3

      electric_panel.rated_total_spaces = rated_total_spaces
      electric_panel.rated_total_spaces_isdefaulted = true
    end

    if electric_panel.headroom_spaces.nil? # only nil if rated_total_spaces is specified
      electric_panel.headroom_spaces = rated_total_spaces - occupied_spaces
      electric_panel.headroom_spaces_isdefaulted = true
    end
  end

  # Returns the list of all possible electric panel load types
  #
  # @return [Array<String>] List of load types
  def self.all_panel_load_types
    return [HPXML::ElectricPanelLoadTypeHeating,
            HPXML::ElectricPanelLoadTypeCooling,
            HPXML::ElectricPanelLoadTypeWaterHeater,
            HPXML::ElectricPanelLoadTypeClothesDryer,
            HPXML::ElectricPanelLoadTypeDishwasher,
            HPXML::ElectricPanelLoadTypeRangeOven,
            HPXML::ElectricPanelLoadTypeMechVent,
            HPXML::ElectricPanelLoadTypePermanentSpaHeater,
            HPXML::ElectricPanelLoadTypePermanentSpaPump,
            HPXML::ElectricPanelLoadTypePoolHeater,
            HPXML::ElectricPanelLoadTypePoolPump,
            HPXML::ElectricPanelLoadTypeWellPump,
            HPXML::ElectricPanelLoadTypeElectricVehicleCharging,
            HPXML::ElectricPanelLoadTypeLighting,
            HPXML::ElectricPanelLoadTypeKitchen,
            HPXML::ElectricPanelLoadTypeLaundry,
            HPXML::ElectricPanelLoadTypeOther]
  end
end

# Object with calculated load
class LoadValues
  LOAD_ATTRS = [:Load_CapacityW,
                :Load_CapacityA,
                :Load_HeadRoomA]
  attr_accessor(*LOAD_ATTRS)

  def initialize
    LOAD_ATTRS.each do |attr|
      send("#{attr}=", 0.0)
    end
  end
end
