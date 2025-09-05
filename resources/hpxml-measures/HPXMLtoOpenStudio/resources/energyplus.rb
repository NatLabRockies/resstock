# frozen_string_literal: true

# FUTURE: Delete this file and move code into model.rb and constants.rb

# Collection of methods related to the EnergyPlus simulation.
module EPlus
  # Constants
  BoundaryConditionAdiabatic = 'Adiabatic'
  BoundaryConditionCoefficients = 'OtherSideCoefficients'
  BoundaryConditionFoundation = 'Foundation'
  BoundaryConditionGround = 'Ground'
  BoundaryConditionOutdoors = 'Outdoors'
  BoundaryConditionSurface = 'Surface'
  EMSActuatorElectricEquipmentPower = 'ElectricEquipment', 'Electricity Rate'
  EMSActuatorOtherEquipmentPower = 'OtherEquipment', 'Power Level'
  EMSActuatorPumpMassFlowRate = 'Pump', 'Pump Mass Flow Rate'
  EMSActuatorPumpPressureRise = 'Pump', 'Pump Pressure Rise'
  EMSActuatorFanPressureRise = 'Fan', 'Fan Pressure Rise'
  EMSActuatorFanTotalEfficiency = 'Fan', 'Fan Total Efficiency'
  EMSActuatorCurveResult = 'Curve', 'Curve Result'
  EMSActuatorUnitarySystemCoilSpeedLevel = 'Coil Speed Control', 'Unitary System DX Coil Speed Value'
  EMSActuatorUnitarySystemSuppCoilSpeedLevel = 'Coil Speed Control', 'Unitary System Supplemental Coil Stage Level'
  EMSActuatorScheduleConstantValue = 'Schedule:Constant', 'Schedule Value'
  EMSActuatorScheduleYearValue = 'Schedule:Year', 'Schedule Value'
  EMSActuatorScheduleFileValue = 'Schedule:File', 'Schedule Value'
  EMSActuatorZoneInfiltrationFlowRate = 'Zone Infiltration', 'Air Exchange Flow Rate'
  EMSActuatorZoneMixingFlowRate = 'ZoneMixing', 'Air Exchange Flow Rate'
  EMSActuatorFrostHeatingCapacityMultiplierSingleSpeedDX = 'Coil:Heating:DX:SingleSpeed', 'Frost Heating Capacity Multiplier'
  EMSActuatorFrostHeatingCapacityMultiplierMultiSpeedDX = 'Coil:Heating:DX:MultiSpeed', 'Frost Heating Capacity Multiplier'
  EMSActuatorFrostHeatingInputPowerMultiplierSingleSpeedDX = 'Coil:Heating:DX:SingleSpeed', 'Frost Heating Input Power Multiplier'
  EMSActuatorFrostHeatingInputPowerMultiplierMultiSpeedDX = 'Coil:Heating:DX:MultiSpeed', 'Frost Heating Input Power Multiplier'
  EMSIntVarFanMFR = 'Fan Maximum Mass Flow Rate'
  EMSIntVarPumpMFR = 'Pump Maximum Mass Flow Rate'
  FluidPropyleneGlycol = 'PropyleneGlycol'
  FluidWater = 'Water'
  FuelTypeCoal = 'Coal'
  FuelTypeElectricity = 'Electricity'
  FuelTypeNaturalGas = 'NaturalGas'
  FuelTypeNone = 'None'
  FuelTypeOil = 'FuelOilNo2'
  FuelTypePropane = 'Propane'
  FuelTypeWoodCord = 'OtherFuel1'
  FuelTypeWoodPellets = 'OtherFuel2'
  ScheduleTypeLimitsFraction = 'Fractional'
  ScheduleTypeLimitsOnOff = 'OnOff'
  ScheduleTypeLimitsTemperature = 'Temperature'
  SubSurfaceTypeDoor = 'Door'
  SubSurfaceTypeWindow = 'FixedWindow'
  SurfaceSunExposureNo = 'NoSun'
  SurfaceSunExposureYes = 'SunExposed'
  SurfaceTypeFloor = 'Floor'
  SurfaceTypeRoofCeiling = 'RoofCeiling'
  SurfaceTypeWall = 'Wall'
  SurfaceWindExposureNo = 'NoWind'
  SurfaceWindExposureYes = 'WindExposed'
  PumpControlTypeIntermittent = 'Intermittent'
  TimeseriesFrequencyNone = 'none'
  TimeseriesFrequencyTimestep = 'timestep'
  TimeseriesFrequencyHourly = 'hourly'
  TimeseriesFrequencyDaily = 'daily'
  TimeseriesFrequencyMonthly = 'monthly'

  # Returns the fuel type used in the EnergyPlus simulation that the HPXML fuel type
  # maps to.
  #
  # @param hpxml_fuel [String] HPXML fuel type (HPXML::FuelTypeXXX)
  # @return [String] EnergyPlus fuel type (EPlus::FuelTypeXXX)
  def self.fuel_type(hpxml_fuel)
    # Name of fuel used as inputs to E+ objects
    if hpxml_fuel.nil?
      return FuelTypeNone
    end

    case hpxml_fuel
    when HPXML::FuelTypeElectricity
      return FuelTypeElectricity
    when HPXML::FuelTypeNaturalGas
      return FuelTypeNaturalGas
    when HPXML::FuelTypeOil, HPXML::FuelTypeOil1, HPXML::FuelTypeOil2,
           HPXML::FuelTypeOil4, HPXML::FuelTypeOil5or6, HPXML::FuelTypeDiesel,
           HPXML::FuelTypeKerosene
      return FuelTypeOil
    when HPXML::FuelTypePropane
      return FuelTypePropane
    when HPXML::FuelTypeWoodCord
      return FuelTypeWoodCord
    when HPXML::FuelTypeWoodPellets
      return FuelTypeWoodPellets
    when HPXML::FuelTypeCoal, HPXML::FuelTypeCoalAnthracite,
         HPXML::FuelTypeCoalBituminous, HPXML::FuelTypeCoke
      return FuelTypeCoal
    else
      fail "Unexpected HPXML fuel '#{hpxml_fuel}'."
    end
  end

  # Map of reporting timeseries frequency choices to MessagePack timeseries names.
  #
  # @param timeseries_frequency [String] Timeseries reporting frequency (TimeseriesFrequencyXXX)
  # @return [String] MessagePack timeseries name
  def self.get_msgpack_timeseries_name(timeseries_frequency)
    return { EPlus::TimeseriesFrequencyTimestep => 'TimeStep',
             EPlus::TimeseriesFrequencyHourly => 'Hourly',
             EPlus::TimeseriesFrequencyDaily => 'Daily',
             EPlus::TimeseriesFrequencyMonthly => 'Monthly' }[timeseries_frequency]
  end
end
