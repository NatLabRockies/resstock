# frozen_string_literal: true

class BO
  EnclosureWallAreaThermalBoundary = 'Enclosure: Wall Area Thermal Boundary'
  EnclosureWallAreaExterior = 'Enclosure: Wall Area Exterior'
  EnclosureFoundationWallAreaExterior = 'Enclosure: Foundation Wall Area Exterior'
  EnclosureFloorAreaConditioned = 'Enclosure: Floor Area Conditioned'
  EnclosureFloorAreaLighting = 'Enclosure: Floor Area Lighting'
  EnclosureFloorAreaFoundation = 'Enclosure: Floor Area Foundation'
  EnclosureCeilingAreaThermalBoundary = 'Enclosure: Ceiling Area Thermal Boundary'
  EnclosureRoofArea = 'Enclosure: Roof Area'
  EnclosureWindowArea = 'Enclosure: Window Area'
  EnclosureDoorArea = 'Enclosure: Door Area'
  EnclosureDuctAreaUnconditioned = 'Enclosure: Duct Area Unconditioned'
  EnclosureRimJoistAreaExterior = 'Enclosure: Rim Joist Area'
  EnclosureSlabExposedPerimeterThermalBoundary = 'Enclosure: Slab Exposed Perimeter Thermal Boundary'

  SystemsHeatingCapacity = 'Systems: Heating Capacity'
  SystemsCoolingCapacity = 'Systems: Cooling Capacity'
  SystemsHeatPumpBackupCapacity = 'Systems: Heat Pump Backup Capacity'
  SystemsWaterHeaterVolume = 'Systems: Water Heater Tank Volume'
  SystemsMechanicalVentilationFlowRate = 'Systems: Mechanical Ventilation Flow Rate'

  def self.get_units(bldg_type)
    if bldg_type.include? 'Area'
      return 'ft^2'
    elsif bldg_type.include? 'Perimeter'
      return 'ft'
    elsif bldg_type.include? 'Capacity'
      return 'Btu/h'
    elsif bldg_type.include? 'Tank Volume'
      return 'gal'
    elsif bldg_type.include? 'Flow Rate'
      return 'cfm'
    elsif bldg_type == 'Fixed'
      return '1'
    end

    fail "Unable to assign units to: #{bldg_type}"
  end
end
