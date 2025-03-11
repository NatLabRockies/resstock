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
    capacity_types = []
    capacity_total_watts = []
    capacity_total_amps = []
    capacity_headroom_amps = []
    hpxml_header.service_feeders_load_calculation_types.each do |service_feeders_load_calculation_type|
      if service_feeders_load_calculation_type.include?('Load-Based')
        load_based_capacity_values = LoadValues.new
        calculate_load_based(hpxml_bldg, electric_panel, load_based_capacity_values, service_feeders_load_calculation_type)

        capacity_types << service_feeders_load_calculation_type
        capacity_total_watts << load_based_capacity_values.Load_CapacityW.round(1)
        capacity_total_amps << load_based_capacity_values.Load_CapacityA.round(1)
        capacity_headroom_amps << load_based_capacity_values.Load_HeadRoomA.round(1)
      elsif service_feeders_load_calculation_type.include?('Meter-Based')
        meter_based_capacity_values = LoadValues.new
        calculate_meter_based(hpxml_bldg, electric_panel, meter_based_capacity_values, service_feeders_load_calculation_type)

        capacity_types << service_feeders_load_calculation_type
        capacity_total_watts << meter_based_capacity_values.Load_CapacityW.round(1)
        capacity_total_amps << meter_based_capacity_values.Load_CapacityA.round(1)
        capacity_headroom_amps << meter_based_capacity_values.Load_HeadRoomA.round(1)
      end
    end
    electric_panel.capacity_types = capacity_types
    electric_panel.capacity_total_watts = capacity_total_watts
    electric_panel.capacity_total_amps = capacity_total_amps
    electric_panel.capacity_headroom_amps = capacity_headroom_amps

    breaker_spaces_values = BreakerSpacesValues.new
    calculate_breaker_spaces(electric_panel, breaker_spaces_values)

    electric_panel.breaker_spaces_total = breaker_spaces_values.BreakerSpaces_Total
    electric_panel.breaker_spaces_occupied = breaker_spaces_values.BreakerSpaces_Occupied
    electric_panel.breaker_spaces_headroom = breaker_spaces_values.BreakerSpaces_HeadRoom
  end

  # Get the heating system attached to the given service feeder.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param [HPXML::ServiceFeeder] Object that defines a single electric panel service feeder
  # @return [HPXML::HeatingSystem] The heating system referenced by the panel load
  def self.get_panel_load_heating_system(hpxml_bldg, service_feeder)
    hpxml_bldg.heating_systems.each do |heating_system|
      next if !service_feeder.component_idrefs.include?(heating_system.id)

      return heating_system
    end
    return
  end

  # Get the heat pump attached to the given service feeder.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param [HPXML::ServiceFeeder] Object that defines a single electric panel service feeder
  # @return [HPXML::HeatPump] The heat pump referenced by the panel load
  def self.get_panel_load_heat_pump(hpxml_bldg, service_feeder)
    hpxml_bldg.heat_pumps.each do |heat_pump|
      next if !service_feeder.component_idrefs.include?(heat_pump.id)

      return heat_pump
    end
    return
  end

  # Gets the electric panel's heating load.
  # The returned heating load depends on several factors:
  # - whether the backup heating system can operate simultaneous with the primary heating system (if it can, we sum; if it can't, we take the max)
  # - whether we are tabulating all heating loads, only existing heating loads, or only new heating loads
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param electric_panel [HPXML::ElectricPanel] Object that defines a single electric panel
  # @param addition [nil or Boolean] Whether we are getting all, existing, or new heating loads
  # @return [Double] The electric panel's heating load (W)
  def self.get_panel_load_heating(hpxml_bldg, electric_panel, addition: nil)
    htg = 0.0
    electric_panel.service_feeders.each do |service_feeder|
      next if service_feeder.type != HPXML::ElectricPanelLoadTypeHeating

      heating_system = get_panel_load_heating_system(hpxml_bldg, service_feeder)
      if !heating_system.nil?
        heating_system_watts = service_feeder.power
        primary_heat_pump_watts = 0
        if !heating_system.primary_heat_pump.nil?
          primary_heat_pump_watts = electric_panel.service_feeders.find { |pl| pl.component_idrefs.include?(heating_system.primary_heat_pump.id) }.power
        end

        if addition.nil? ||
           (addition && service_feeder.is_new_load) ||
           (!addition && !service_feeder.is_new_load)
          if (primary_heat_pump_watts == 0) ||
             (!heating_system.primary_heat_pump.nil? && heating_system.primary_heat_pump.simultaneous_backup) ||
             (!heating_system.primary_heat_pump.nil? && heating_system_watts >= primary_heat_pump_watts)
            htg += heating_system_watts
          end
        end
      end

      heat_pump = get_panel_load_heat_pump(hpxml_bldg, service_feeder)
      next unless !heat_pump.nil?

      heat_pump_watts = service_feeder.power
      backup_system_watts = 0
      if !heat_pump.backup_system.nil?
        backup_system_watts = electric_panel.service_feeders.find { |pl| pl.component_idrefs.include?(heat_pump.backup_system.id) }.power
      end

      next unless addition.nil? ||
                  (addition && service_feeder.is_new_load) ||
                  (!addition && !service_feeder.is_new_load)

      next unless (backup_system_watts == 0) ||
                  (!heat_pump.backup_system.nil? && heat_pump.simultaneous_backup) ||
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
      htg_existing = get_panel_load_heating(hpxml_bldg, electric_panel, addition: false)
      htg_new = get_panel_load_heating(hpxml_bldg, electric_panel, addition: true)
      clg_existing = electric_panel.service_feeders.select { |panel_load| panel_load.type == HPXML::ElectricPanelLoadTypeCooling && !panel_load.is_new_load }.map { |pl| pl.power }.sum(0.0)
      clg_new = electric_panel.service_feeders.select { |panel_load| panel_load.type == HPXML::ElectricPanelLoadTypeCooling && panel_load.is_new_load }.map { |pl| pl.power }.sum(0.0)

      hvac_load = [htg_existing + htg_new, clg_existing + clg_new].max
      other_load = 0.0
      electric_panel.service_feeders.each do |panel_load|
        next if panel_load.type == HPXML::ElectricPanelLoadTypeHeating || panel_load.type == HPXML::ElectricPanelLoadTypeCooling

        other_load += panel_load.power
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
      htg_new = get_panel_load_heating(hpxml_bldg, electric_panel, addition: true)
      clg_new = electric_panel.service_feeders.select { |service_feeder| service_feeder.type == HPXML::ElectricPanelLoadTypeCooling && service_feeder.is_new_load }.map { |pl| pl.power }.sum(0.0)

      new_loads = [htg_new, clg_new].max
      electric_panel.service_feeders.each do |service_feeder|
        next if service_feeder.type == HPXML::ElectricPanelLoadTypeHeating || service_feeder.type == HPXML::ElectricPanelLoadTypeCooling

        new_loads += service_feeder.power if service_feeder.is_new_load
      end

      extension_properties = hpxml_bldg.header.extension_properties
      peak_elec = extension_properties['PeakElectricity'].to_f

      service_feeders.Load_CapacityW = new_loads + 1.25 * peak_elec
      service_feeders.Load_CapacityA = service_feeders.Load_CapacityW / Float(electric_panel.voltage)
      service_feeders.Load_HeadRoomA = electric_panel.max_current_rating - service_feeders.Load_CapacityA
    end
  end

  # Calculate the number of panel breaker spaces corresponding to total, occupied, and headroom.
  #
  # @param electric_panel [HPXML::ElectricPanel] Object that defines a single electric panel
  # @param [Array<HPXML::ServiceFeeder>] List of service feeder objects
  # @return [nil]
  def self.calculate_breaker_spaces(electric_panel, service_feeders)
    occupied = electric_panel.branch_circuits.map { |branch_circuit| branch_circuit.occupied_spaces }.sum(0.0)
    if !electric_panel.rated_total_spaces.nil?
      total = electric_panel.rated_total_spaces
    else
      total = occupied + electric_panel.headroom
    end

    service_feeders.BreakerSpaces_Total = total
    service_feeders.BreakerSpaces_Occupied = occupied
    service_feeders.BreakerSpaces_HeadRoom = total - occupied
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

# Object with breaker spaces
class BreakerSpacesValues
  BREAKERSPACE_ATTRS = [:BreakerSpaces_Occupied,
                        :BreakerSpaces_Total,
                        :BreakerSpaces_HeadRoom]
  attr_accessor(*BREAKERSPACE_ATTRS)

  def initialize
    BREAKERSPACE_ATTRS.each do |attr|
      send("#{attr}=", 0.0)
    end
  end
end
